在做好了buddy system后，我们可以更进一步的搞slub了。其实这个做出来了，也相当于是对buddy的检查了。因为这个slub完全是自己照着网上意义不明的各种连线图和奇怪的不说人话的比喻以及极其晦涩的定义凭空捏造出来的，所以实际上可能有点偏差……老实说光是照这个东西的概念就已经找的我心力憔悴了。

		⭐因为对头文件包含过于烦躁，我把buddy和slub都放在default.c里了。
		在我学习到的slub结构中，分为几个部分。
		buddy system就相当于是批发商，我的slub从buddy那里获取到一个或好几个页。
		kmem_cache是零售商。我们有好几个零售商，它们分别负责售卖8字节、16字节、32字节……大小的内存。
		kmem_cache_cpu是售货员小姐姐。它手头上有一个页，这里面放着好多已经划分成它老板负责的大小的内存，然后把这些内存按需分给顾客。
		kmem_cache_node是仓管小哥哥。它手头有两个Page*的链表，partial_heads（有剩空余的page）和full_heads（全满了的page）。售货员小姐姐卖光了的page就放到它的full_heads里面，当有顾客用完object（分出去的内存）还回来之后，如果这个object所在的page是在full_heads里面，那么把这个page移动到partial_heads里面。
		售货员小姐姐需要售卖内存，当它手上的内存发完了后，它会优先检查仓管小哥哥的partial_heads。如果里头有空闲的内存，那么优先拿过来。如果啥都没了，那么老板会向buddy system再进一次货。
		首先我们来看看slub需要的结构：
这是主要的结构。我们会造一个kmem_cache[9]的数组。比如说kmem_cache[1],它就负责零售16字节的内存。object_size就是 用来记录这个大小：16的。base是当前在使用的page。node_storage是仓管小哥哥，object_seller是售货员小姐姐。

		struct kmem_cache
		{
			unsigned object_size;   
			struct Page* base;
			struct kmem_cache_node node_storage;
			struct kmem_cache_cpu object_seller;
		};

这是仓管和售货员的结构：partial_num和full_num是记录当前partial_heads和full_heads节点数，方便遍历的。object_list_head是售货员当前在用的page里的object的链表的表头，用来索引这个链表，我们要售卖内存时，就是从它管理的链表上取下内存然后分配。

		struct kmem_cache_node
		{
			struct Page* partial_heads;    //就是装了一半的
			struct Page* full_heads;       //这是装满了的
			unsigned partial_num;
			unsigned full_num;

		};
		struct kmem_cache_cpu
		{
			struct block_head object_list_head;   
		};

这是object，也就是我们具体分配的内存。我们分配内存（假设需求大小为n）时会返回一个block_head结构体的指针，这个指针开始后面的n个字节都归申请者所有了。size是记录这个代表的是多大的内存，用于在后面释放内存的时候找到这个object属于哪个尺寸的kmem_cache。

		struct block_head {
			short size;
			struct block_head* next, * prev;
		};

我对Page结构体做出了一些改变。我添加了storage_head指针，这是用来索引在仓库的时候partial_heads或full_heads含有的object（block_head）链表。因为仓库里会有很多页，所以需要每个页都有自己的block_head链表。


		struct Page {
			int ref;                        
			uint64_t flags;                 
			unsigned int property;          
			list_entry_t page_link;        
			
			struct block_head* storage_head;
		};


首先来看看slub初始化。这里没什么好说的，首先把buddy初始化，然后把kmem_cache_list里的9个kmem_cache初始化。

		void slub_init_memmap(struct Page* base, unsigned n)
		{
			//先把buddy初始化了
			buddy_init_memmap(base, n);
			//整个进程中只有一个slub分配器。
			//kmem_cache_list这里有12个kmem_cache。我们要把他们初始化。
			unsigned size = 8;
			for (int i = 0; i < 9; i++)
			{
				//我这个object是2^(i+3)字节.
				kmem_cache_list[i].object_size = size;
				initialize_block_head(&kmem_cache_list[i].object_seller.object_list_head);
				kmem_cache_list[i].node_storage.partial_heads = NULL;
				kmem_cache_list[i].node_storage.full_heads = NULL;
				size *= 2;
			}

		}

然后是slub_alloc_pages。这个实在是太长了没法完全放进来，只能用文字讲一讲了。

		在alloc这里，首先要对输入进行处理。我们的输入是具体多少个字节，首先要把它转化成2的幂次。接下来，因为buddy的分配输入是页数，所以要根据字节数和PGSIZE=4096的数学关系转化为申请多少页（不过这里简单的情况，我不会申请太大的字节，所以一般一页就能搞定）。然后根据2的幂次和kmem_cache_list的下标关系找到对应的下标index，接下来的分配工作就是操作kmem_cache_list[index]这个kmem_cache。
		接下来，判断是否当前的销售员object_seller手里是否有可用的block_head。由于我们每次拿的时候都是拿的object_seller的object_list_head索引的下一个block_head，所以只需要判断object_list_head的下一个是否为NULL。
		·如果不是NULL，那我们就把object_list_head的下一个取出来，在函数结束时返回。当然，取出来后我们还要进行一系列判断。如果取出来之后object_list_head后面还有可用的block_head，那么就直接返回刚刚取出来的block_head即可。如果取出来之后后面没有可用的block_head了，那么我们要把当前的kmem_cache手里的page放到仓管node_storage的full_heads里面。（我知道这非常绕，这也是为什么我差点写哭了的原因）
		·如果是NULL，那我们进入下面的步骤：
		
		接下来我们要看看仓管node_storage的partial_storage里面有没有空闲的block_head。如果有的话，老样子给他分配出去，并且判断当前的partial_storage是不是又变回full_heads了。如果变回去了，那和上面的差不多。
		
		那么现在就该进入下一个可能性了，partial_storage里啥都没有，kmem_cache手头的page页分完了，接下来就是最关键的向buddy要page了（事实上这一步应该是第一个看，但是我们要尽量少出现的情况放在ifelse语句的靠后的位置，减少判断的开销）。在这里，我们要把object_seller初始化，要根据申请的字节数pow_n的对应关系得到页数，据此向buddy申请page，把kmem_cache_list[index]手头的page设为函数传进来的base，
		❤然后！我们要每隔pow_n个字节建立一个block_head结构体的指针，再把他们串起来（相当于是把这个page均分了，而且我们可以根据block_head结构体的地址找到具体位置。这个很关键，后面释放的时候就靠它了）这个地方因为是相当于手动安排某个数据的地址，所以非！常！容！易！出！问！题！这个在后面介绍遇到的问题的时候会统一讲。总之这里完事之后，把这个block_head串接到object_seller里面就可以了。

		在我们返回block_head指针后，这个指针地址往后的申请者申请的大小就可以自由使用了。

接下来是slub_free_pages。这个部分代码也很长，只能文字描述了。

		在这里我们在block_head中花费宝贵的空间开的一个short型的size就有用了。这个index可以用于索引kmem_cache_list[index]来找到这个block_head是来自哪个kmem_cache的，我们从哪里alloc的就要往哪里free。
		
		这个传入的block_head指针记为object。我们知道，对于每个block_head，因为它来自某个page的均分的结果，所以我们要找到它属于哪个page，只需要判断它的地址是否比某个page的地址大，但是差距又小于PGSIZE。
		我们首先要看看它是不是在销售员object_seller手上。如果object的地址减去kmem_cache_list[index]持有的page的地址，结果在0到PGSIZE之间，那么好了，object是来自object_seller的。要做的只是按照地址大小把它插回object_list_head索引的链表里。
		接下来检查有余量的仓库partial_heads的page表。如果是来自partial_heads的某个page里，那也非常简单。这里就用上了安排在page里面的storage_head指针。我们直接拿它当作页的头部指针，进来的object如果比它小，那么object变成新的storage_head。如果比它大，那么就普通的按照地址大小插到链表里。
		复杂的来了。对于盛满的仓库full_heads，我们知道一旦某个page有了一个空余的block_head，那么这个page就得从full_heads搬家到partial_heads里了。这里说着可能不是很多，但是实际写起来在面对表头的处理时还是导致了不少bug，费了我不少功夫。

然后就可以编写测试例了。我使用一个循环先分配了20个大小为512字节的object。

		struct block_head *all_512s[25];
		for (int i = 0; i < 20; i++)
		{
			all_512s[i] = slub_alloc_pages(512);
			cprintf("%x\n", all_512s[i]);
		}

我得到的结果是：

		no more space, asking buddy
		base_page:c0213980   alloced_address:c0213f80
		c0213f80
		alloced address:c0214180
		c0214180
		alloced address:c0214380
		c0214380
		alloced address:c0214580
		c0214580
		alloced address:c0214780
		c0214780
		alloced address:c0214980
		c0214980

		no more space, asking buddy
		base_page:c0214980   alloced_address:c0214f80
		c0214f80
		alloced address:c0215180
		c0215180
		alloced address:c0215380
		c0215380
		alloced address:c0215580
		c0215580
		alloced address:c0215780
		c0215780
		alloced address:c0215980
		c0215980

		no more space, asking buddy
		base_page:c0215980   alloced_address:c0215f80
		c0215f80
		alloced address:c0216180
		c0216180
		alloced address:c0216380
		c0216380
		alloced address:c0216580
		c0216580
		alloced address:c0216780
		c0216780
		alloced address:c0216980
		c0216980

		no more space, asking buddy
		base_page:c0216980   alloced_address:c0216f80
		c0216f80
		alloced address:c0217180
		c0217180
		above are the alloced mem

看到我们分配的页是c0213980、c0214980、c0215980以及c0216980。其中显然c0213980、c0214980、c0215980是已经满了的，此时它们应该在full_heads里。而c0216980在当前的base中，它是正在被使用，而且没分配完的。还可以看到分配出来的object是每隔512字节一个的。

接下来我遍历一边full_heads链表，看看里面都有谁：

		struct Page* full_test_head;
		list_entry_t* le = &kmem_cache_list[kmalloc_caches_index(512)].node_storage.full_heads->page_link;
		for (int i = 0; i < kmem_cache_list[kmalloc_caches_index(512)].node_storage.full_num; i++)
		{
			full_test_head = le2page(le, page_link);
			cprintf("%x\n", full_test_head);
			le = list_next(le);
		}
		cprintf("above are the full pages' address\n\n");

kmalloc_caches_index的作用是把字节转化为对应的kmem_cache_list的下标。这里我们得到的输出是：

		c0213980
		c0214980
		c0215980
		above are the full pages' address

这三个page就是之前我们提到的三个满了的page。

接下来我们free几个object。最好跳着free，手动导致几个partial_heads的产生。

		cprintf("%x\n", all_512s[0]);
		slub_free_pages(all_512s[0]);
		cprintf("free all_512s[0]\n\n");

		cprintf("%x\n", all_512s[4]);
		slub_free_pages(all_512s[4]);
		cprintf("free all_512s[4]\n\n");

		cprintf("%x\n", all_512s[5]);
		slub_free_pages(all_512s[5]);
		cprintf("free all_512s[5]\n\n");

		cprintf("%x\n", all_512s[7]);
		slub_free_pages(all_512s[7]);
		cprintf("free all_512s[7]\n\n");

		cprintf("%x\n", all_512s[10]);
		slub_free_pages(all_512s[10]);
		cprintf("free all_512s[10]\n\n");
		
我们得到的输出是

		c0213f80
		storage_full:c0213980
		c0213f80
		free all_512s[0]

		c0214780
		storage_partial:c0213980
		c0214780
		free all_512s[4]

		c0214980
		c0214980
		free all_512s[5]

		c0215180
		storage_full:c0214980
		c0215180
		free all_512s[7]

		c0215780
		storage_partial:c0214980
		c0215780
		free all_512s[10]

我自己反正是照着上面数着对了一遍没什么大问题。

我们来看看此时partial_heads里面有什么：

		*****************************************************
		below are the c0213980 slab
		c0213f80
		c0214780
		c0214980
		*****************************************************



		*****************************************************
		below are the c0214980 slab
		c0215180
		c0215780
		c0215980
		*****************************************************

就是刚刚释放的那些object，并且它们找到了自己的page。

最后，我们再看看当手头的object_head满了之后它怎么从partial_heads里面拿object：
		
		//这里是先把手头的object_head占满。
		for (int i = 20; i < 24; i++)
		{
			all_512s[i] = slub_alloc_pages(512);
			cprintf("%x\n", all_512s[i]);
		}

		//在手头都满了的情况下，他会从哪里拿呢？
		all_512s[24] = slub_alloc_pages(512);
		cprintf("%x\n", all_512s[24]);

我们得到的输出是：

		alloced address:c0217380
		c0217380
		alloced address:c0217580
		c0217580
		alloced address:c0217780
		c0217780
		alloced address:c0217980
		c0217980
		上面是占满用的
		这里是新拿的。对比一下，它确实是刚刚partial_heads表里第一个page的第一个object。
		c0213f80

遇到的问题：

		虽然在我的描述里看起来很轻松，但是实现过程非常痛苦而且遇到了很多棘手无比的问题。
		我以前没有直接手动的把某个变量、标识安排在某个地址的经历，因为这些是操作系统和编译器帮我干的。但是现在我就是操作系统，操作系统就是我！所以这个过程就非常痛苦了。这遇到的最大的一个问题就是，没有经验，导致我对整个程序的内存布局不是很清晰，每个数据结构的大小并没有再留意，只知道个大概。
		这有什么问题呢？这问题非常大。比如一开始我的block_head链表（也就是要分配出去的object）。我一开始遇到了某个链表结点的next指向了它自己。这非常诡异，我最初甚至以为我居然在链表数据结构上出了问题！耻辱的反复检查后发现问题肯定不是出在链表上。最终发现，在一次请求内存过小的情况下（如8字节），而我的block_head结点这个结构体本身就已经比8字节大了，这导致在均分page的时候，出现了很搞笑的一幕：所有结点都和临近的结点有内存上的重合，这就导致了结点的next是上一个节点的next，然后指向了自己，最终导致遍历的时候整个程序卡住。为解决它，我只好限制每次分配内存不能太小，然后尽可能地精简block_head结构体，一些没用的成员直接丢弃。
		然后是buddy_system索引的叶子page链表。在我尝试连续分配很多内存，也就是slub需要反复向buddy请求page的时候，又出现了卡死。初步排查发现遍历buddy_system的容量数组时出现卡死，然后我就以为是我的buddy_system写错了。但是反复检查确认buddy无误。接着通过反复打印发现在第4次请求时，buddy_system的总容量从一开始请求的正常数据变成了-1.当我没有对buddy的总容量进行修改，它却变了，直觉和之前排查的经验告诉我，绝对是分配内存的时候有啥玩意正好被分配到这个位置，然后正好把它给覆写了。果不其然，经过排查又发现我的一众分配器、记录器等重要数据居然都存放在buddy的page数组中的第一个page管辖的内存中。于是我只好在初始化的时候将0号page给保留下来不予分配。
		其它的bug还好说，第一次遇到这种在手动内存分配时冲突、覆写原来数据的问题。初次见到确实手忙脚乱，而且犯了经验主义错误，根本没往这方面想，浪费了很多时间才灵机一动发现。但是就像免疫系统记住某个病原体一样，以后再出现这种没有征兆的，没有逻辑错误但就是出错了的诡异情况，我也能有所应对了。
		还有个比较低级的是，我后面很多数据结构使用了自己写的链表，但是把结点从链表上卸下来的时候没有把它的next和prev置为NULL，导致再把它接上新的链表的时候除了bug，又指向奇怪的地方了。