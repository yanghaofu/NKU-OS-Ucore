# Lab2实验报告

## 练习1：理解first-fit 连续物理内存分配算法（思考题）
first-fit 连续物理内存分配算法作为物理内存分配一个很基础的方法，需要同学们理解它的实现过程。请大家仔细阅读实验手册的教程并结合kern/mm/default_pmm.c中的相关代码，认真分析default_init，default_init_memmap，default_alloc_pages， default_free_pages等相关函数，并描述程序在进行物理内存分配的过程以及各个函数的作用。 请在实验报告中简要说明你的设计实现过程。请回答如下问题：

你的first fit算法是否有进一步的改进空间？

答：First Fit（最先匹配）是一种常见的内存分配算法，用于管理内存中的空闲块。它的基本思想是在内存中找到第一个足够大的空闲块来满足请求。其中空闲块被组织成一个链表，每个空闲块包含空闲区域的起始地址和大小。当一个新的内存请求到达时，这个算法从空闲分区链首开始查找，寻找第一个能够容纳该请求的空闲块。一旦找到合适的空闲块，就会按照作业的大小，从该块中划出一块内存分配给请求者用于满足请求，余下的空闲分区保留为新的空闲块，仍留在空闲分区链中。

这种算法的优点是简单和高效。由于它直接使用第一个满足条件的空闲块，因此不需要遍历整个空闲块列表，从而节省了时间。另外，First Fit可以比较快地找到一个合适的空闲块，尤其是当内存中存在大量小的空闲块时。

缺点是会导致内存碎片化，即剩余的小块无法满足大块的请求。以及如果较大的空闲块位于链表或数组的末尾，那么查找合适的空闲块可能需要较长的时间。

### 预备分析
在分析First Fit算法前，首先要熟悉以下物理页的属性结构。

```c
struct Page {
    int ref;                        // page frame's reference counter
    uint64_t flags;                 // array of flags that describe the status of the page frame
    unsigned int property;          // the num of free block, used in first fit pm manager
    list_entry_t page_link;         // free list link
    list_entry_t pra_page_link;     // used for pra (page replace algorithm)
    uintptr_t pra_vaddr;            // used for pra (page replace algorithm)
};
```

该结构成员变量意义如下:

int ref: 页帧的引用计数器，用于跟踪该页帧被引用的次数。

uint64_t flags: 一个表示页帧状态的标志数组。通常，每个位（bit）对应于不同的状态，比如是否已经分配、是否脏页等。

unsigned int property: 用于最先匹配（first fit）页管理器中的空闲块数量。在内存分配过程中，该字段会记录当前空闲块的数量，以便进行最先匹配算法选择。

list_entry_t page_link: 在链表数据结构中使用的指针，用于将页帧链接到空闲列表中。这个链表可能用于记录空闲页帧的列表，以便于内存分配和释放。

list_entry_t pra_page_link: 用于页面置换算法（page replace algorithm）的链表链接，用于将页帧链接到相应的置换算法中。

uintptr_t pra_vaddr: 页面置换算法使用的虚拟地址，用于与特定的置换算法相关联。

我们还需要关注记录空闲信息的双向链表，它和以下结构体相关：

```c
typedef struct {
    list_entry_t free_list;         // the list header
    unsigned int nr_free;           // # of free pages in this free list
} free_area_t;
```

free_list: 该成员变量是是一个 list_entry 结构的双向链表指针，用于表示空闲页面的双向链表。通过该链表，可以按照第一个空闲页面到最后一个空闲页面的顺序，链接和访问所有空闲页面。

unsigned int nr_free: 该成员变量是一个无符号整数，用于记录当前空闲列表中的空闲页面数量。通过该变量，可以追踪和更新空闲页面的数量，以便快速获取可用的空闲页面数量。

通过定义包含这些成员变量的free_area_t结构体，可以创建并管理用于记录空闲页面的双向链表。该链表可以用于跟踪和管理可用的空闲页面，以便在需要时分配给需要内存的进程或线程。

### `default_init` 函数分析

`default_init` 函数代码如下：

```c
// 初始化空闲页块链表
static void 
default_init(void) {
    list_init(&free_list);
    nr_free = 0;// 空闲页块一开始是0个
}
```
文件开头的注释中对它描述如下：
```
* (2) default_init: you can reuse the  demo default_init fun to init the free_list and set nr_free to 0.
 *              free_list is used to record the free mem blocks. nr_free is the total number for free mem blocks.
```
也就是说，函数default_init的作用是将空闲内存块列表初始化为空链表，并将空闲内存块的数量nr_free设置为0。

其中：

list_init(&free_list)：这行代码调用了一个名为list_init的函数，并传入了指向free_list的指针作为参数。list_init函数的作用是将free_list初始化为空链表，即将链表头的前后指针都指向自身，表示链表中没有任何节点。

nr_free = 0：这行代码将变量nr_free的值设置为0，表示初始时空闲内存块的数量为0。

通过这两行代码的执行，就实现了将空闲内存块列表初始化为空链表，并且将空闲内存块的数量设置为0的效果。这样，在进行内存分配操作之前，就可以确保空闲内存块列表的初始状态是正确的。

### `default_init_memmap`函数分析
 `default_init_memmap`函数是用来初始化空闲页链表的，初始化每一个空闲页，然后计算空闲页的总数。 

初始化每个物理页面记录，然后将全部的可分配物理页视为一大块空闲块加入空闲表。

 `default_init_memmap` 函数代码如下：
```c
static void
default_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;
    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }
}
```
文件开头的注释中对它描述如下：
``` 
 * (3) default_init_memmap:  CALL GRAPH: kern_init --> pmm_init-->page_init-->init_memmap--> pmm_manager->init_memmap
 *              This fun is used to init a free block (with parameter: addr_base, page_number).
 *              First you should init each page (in memlayout.h) in this free block, include:
 *                  p->flags should be set bit PG_property (means this page is valid. In pmm_init fun (in pmm.c),
 *                  the bit PG_reserved is setted in p->flags)
 *                  if this page  is free and is not the first page of free block, p->property should be set to 0.
 *                  if this page  is free and is the first page of free block, p->property should be set to total num of block.
 *                  p->ref should be 0, because now p is free and no reference.
 *                  We can use p->page_link to link this page to free_list, (such as: list_add_before(&free_list, &(p->page_link)); )
 *              Finally, we should sum the number of free mem block: nr_free+=n
```

结合函数和注释可以看出，这个函数的作用是初始化一段物理内存页表，并将这些页表按照一定的规则插入到空闲页链表中。

具体解释如下：

- 首先，通过assert(n > 0)断言参数n大于0，确保要初始化的页数是有效的。

- 然后，使用一个循环遍历从base开始的n个页表，将这些页表的属性进行初始化。每次迭代时，首先检查当前页表是否为保留页（通过PageReserved(p)判断）。如果不是保留页，会触发断言错误，确保不会对保留页进行初始化。

- 对于非保留页，将其flags和property属性设置为0，表示没有特殊标记和属性。通过set_page_ref(p, 0)将页表的引用计数设置为0，即还没有被引用。

- 在循环结束后，将第一个页表的property属性设置为n，表示这一段物理内存的连续页数。使用SetPageProperty(base)函数将base页表的property标志位置为1，表示这是一个有属性的页表。

- 更新全局变量nr_free，增加n个空闲页的数量。

- 接下来是将这些初始化的页表插入到空闲页链表中。首先判断链表是否为空，如果为空，则直接使用list_add函数将base页表插入作为链表的第一个节点。

- 如果链表不为空，需要遍历链表找到合适的位置进行插入。初始化一个指针le，指向空闲页链表的头部节点。然后开始循环遍历链表。

- 在每次循环中，通过list_next函数将le指针指向下一个节点。如果le指向的节点不是空闲页链表（即还没有遍历完整个链表），则执行以下操作：

- - 通过le2page宏将le转换为struct Page类型的指针page，方便访问节点的属性。

  - 比较base和page的大小。如果base < page，说明找到了一个合适的位置将base插入到链表中。使用list_add_before(le, &(base->page_link))将base->page_link插入到le节点之前，并跳出循环。

  - 如果base >= page，说明还没有找到合适的位置，继续遍历。检查le的下一个节点是否为空闲页链表，如果是，则说明已经遍历到了链表的尾部，将base插入到链表的尾部。使用list_add(le, &(base->page_link))将base->page_link插入到le节点之后。

- 循环结束后，所有的页表都被插入到合适的位置，完成了物理内存页表的初始化，并将其按照一定的顺序连接到空闲页链表中。
###  `default_alloc_memmap`函数分析
 `default_alloc_memmap`函数主要就是从空闲页块的链表中去遍历，找到第一块大小大于 `n` 的块，然后分配出来，把它从空闲页链表中除去，然后如果有多余的，把分完剩下的部分再次加入会空闲页链表中即可。

`default_alloc_memmap`函数代码如下：
```c
static struct Page *
default_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free) {
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n) {
            page = p;
            break;
        }
    }
    if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        if (page->property > n) {
            struct Page *p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));
        }
        nr_free -= n;
        ClearPageProperty(page);
    }
    return page;
}
```
文件开头的注释中对它描述如下：
```
 * (4) default_alloc_pages: search find a first free block (block size >=n) in free list and reszie the free block, return the addr
 *              of malloced block.
 *              (4.1) So you should search freelist like this:
 *                       list_entry_t le = &free_list;
 *                       while((le=list_next(le)) != &free_list) {
 *                       ....
 *                 (4.1.1) In while loop, get the struct page and check the p->property (record the num of free block) >=n?
 *                       struct Page *p = le2page(le, page_link);
 *                       if(p->property >= n){ ...
 *                 (4.1.2) If we find this p, then it' means we find a free block(block size >=n), and the first n pages can be malloced.
 *                     Some flag bits of this page should be setted: PG_reserved =1, PG_property =0
 *                     unlink the pages from free_list
 *                     (4.1.2.1) If (p->property >n), we should re-caluclate number of the the rest of this free block,
 *                           (such as: le2page(le,page_link))->property = p->property - n;)
 *                 (4.1.3)  re-caluclate nr_free (number of the the rest of all free block)
 *                 (4.1.4)  return p
 *               (4.2) If we can not find a free block (block size >=n), then return NULL
```
可以看出，函数中对分配空闲块的情况分了以下三种：

第一种情况是找不到满足需求的可供分配的空闲块，即所有的空闲块大小都小于需要分配的大小 n。

第二种情况是刚好有满足大小的空闲块。在执行分配前，存在以下三种类型的空闲块：大小小于 n、大小等于 n、大小大于 n。执行分配后，只剩下大小小于 n 和大小大于 n 的空闲块。

第三种情况是不存在刚好满足大小的空闲块，但存在比所需大小更大的空闲块。在执行分配前，存在以下三种类型的空闲块：大小小于 n、大小大于 n、大小大于 n1（其中 n1 > n）。执行分配后，将原本大小大于 n 的空闲块分割成大小为 size - n 的空闲块，留下了大小小于 n 和大小大于 n1 的空闲块。

    1.第一种情况(找不到满足需求的可供分配的空闲块(所有的size均 < n))
    2.第二种情况(刚好有满足大小的空闲块)
        执行分配前
        --------------          --------------         -------------
        | size < n   |  <--->   | size = n   |  <--->  | size > n  |
        --------------          --------------         -------------
        执行分配后
        --------------           -------------
        | size < n   |  <--->    | size > n  |
        --------------           -------------
    3.第三种情况(不存在刚好满足大小的空闲块，但存在比其大的空闲块)   
        执行分配前
        --------------          ------------         --------------
        | size < n   |  <--->   | size > n |  <--->  | size > n1  |
        --------------          ------------         --------------
        执行分配后
        --------------          ---------------------         --------------
        | size < n   |  <--->   | size = size - n   |  <--->  | size > n1  |
        --------------          ---------------------         --------------
### `default_free_pages`函数分析
 `default_free_pages`函数将需要释放的空间标记为空之后，需要找到空闲表中合适的位置。由于空闲表中的记录都是按照物理页地址排序的，所以如果插入位置的前驱或者后继刚好和释放后的空间邻接，那么需要将新的空间与前后邻接的空间合并形成更大的空间。

实现过程如下：

```c
static void
default_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;

    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }

    list_entry_t* le = list_prev(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (p + p->property == base) {
            p->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = p;
        }
    }

    le = list_next(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (base + base->property == p) {
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
        }
    }
}

```

文件开头的注释中对它描述如下：
```
* (5) default_free_pages: relink the pages into  free list, maybe merge small free blocks into big free blocks.
 *               (5.1) according the base addr of withdrawed blocks, search free list, find the correct position
 *                     (from low to high addr), and insert the pages. (may use list_next, le2page, list_add_before)
 *               (5.2) reset the fields of pages, such as p->ref, p->flags (PageProperty)
 *               (5.3) try to merge low addr or high addr blocks. Notice: should change some pages's p->property correctly.
 
```

可以看出，代码流程大致如下:
```
    1.寻找插入位置(插入到地址 > base的空闲块链表节点前)
    2.进行地址比对，已确定插入位置及处理方式
    循环结束情况及处理方式分为如下3种：
        (1).空闲链表为空(只有头结点)，直接添加到头结点后面就可以
        (2).查到链表尾均未发现比即将插入到空闲连表地址大的空闲块。
            a.先插入到链表尾部
            b.尝试与前一个节点进行合并
        (3).找到比需要插入空闲块地址大的空闲块节点而跳出循环
            a.先插入到找到的节点前面
            b.尝试与后一个节点进行合并
            c.如果前一个节点不为头结点，则尝试与前一个节点进行合并
    3.更新空闲链表可用空闲块数量
        nr_free += n;
```

### 进一步改进的空间
对于上面的 `First Fit` 算法，我还能想到如下优化：

- 建立多个`free_list`，存储不同大小的空闲块。由于First-Fit算法容易造成低地址碎片，而每次分配需要重新开始扫描浪费时间，因此如果有大空闲块的`free_list`，就可以进一步加快算法。
- 对于有序链表插入，在特殊情况下是可以优化的。当一个刚被释放的内存块来说，如果它的邻接空间都是空闲的，那么就不需要进行线性时间复杂度的链表插入操作，而是直接并入邻接空间，时间复杂度为常数。为了判断邻接空间是否为空闲状态，空闲块的信息除了保存在第一个页面之外，还需要在最后一页保存信息，这样新的空闲块只需要检查邻接的两个页面就能判断邻接空间块的状态。


## 练习2：实现 Best-Fit 连续物理内存分配算法（需要编程）
在完成练习一后，参考kern/mm/default_pmm.c对First Fit算法的实现，编程实现Best Fit页面分配算法，算法的时空复杂度不做要求，能通过测试即可。 请在实验报告中简要说明你的设计实现过程，阐述代码是如何对物理内存进行分配和释放，并回答如下问题：

你的 Best-Fit 算法是否有进一步的改进空间？


### 基本实现
在内存分配器初始化方面，best-fit与之前的first-fit并无区别。

在内存分配方面，best-fit算法不再是简单的取用遍历列表时遇到的第一个满足需求的页。我们知道这样做会因为内存分配的粒度的不确定性导致大量的内存碎片。现在我们需要一个方法，要求它能尽可能减少内存碎片，那么我们便需要在分配的方式上下手。在总体框架不变的基础下，我们只需要在能够满足需求的页中挑选剩余内存最小的页即可。

编写代码如下：
~~~
static struct Page *
best_fit_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free) {
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    size_t min_size = nr_free + 1;
     /*LAB2 EXERCISE 2: YOUR CODE*/ 
    // 下面的代码是first-fit的部分代码，请修改下面的代码改为best-fit
    // 遍历空闲链表，查找满足需求的空闲页框
    // 如果找到满足需求的页面，记录该页面以及当前找到的最小连续空闲页框数量
    unsigned int min_property = 1145141919;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n && p->property < min_property) {
            page = p;
            min_property = p->property;
        }
    }

    if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        if (page->property > n) {
            struct Page *p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));
        }
        nr_free -= n;
        ClearPageProperty(page);
    }
    return page;
}
~~~
老生常谈的，判断如果请求内存大小为负数或者是甚至已经超过了总的剩余内存了，那么直接拒绝。否则，我们将要找到满足需求的最小解：

使用min_property来记录当前最小的页内存，page来记录对应的页。我们遍历空闲页链表，每找到一个满足需求的页，便将其剩余内存与min_property比较。如果比min_property小，那么min_property置为当前页内存，page置为当前页。

遍历完毕后，page为满足需求的且剩余内存最小的页。此后的操作就是将这页满足的部分分配出去，剩下的内容再次接入空闲链表中。

在回收空间时，best-fit的操作与first-fit的并无太大区别。因为是连表是按地址排序的，所以回收的时候，在分配时被拆开的页可以合并。

### 改进

无论是best-fit还是first-fit，都有着相对较高的时间复杂度，但是同时取得的效果又十分的有限。对于best-fit来说，它在每一次内存分配时需要完整的遍历一次空闲页表，时间复杂度为O(n)，在释放内存时又需要遍历一次，也是O(n)。在数据结构上的优化在理论上是不可行的。比如按剩余内存大小排序而非按地址大小排序的顺序空闲页表。这么建表的代价是，需要给每个表安排一些额外的成员变量才能简单的实现表的合并，否则光是在释放阶段，花费在找到可以合并的页表（这是必须的步骤，不然会导致存在大量极其细小的碎片）以及根据大小为合并的页表重新找到位置上的时间就是两个常数项时间。然而，花费了高昂的代价得到的效果似乎并不明显。首先由于链表无法随机访问，我们无法使用二分查找。所以即使是顺序的，我们最差的情况还是得遍历整个链表。其次，在分配完毕产生小内存块儿后，为了维护链表有序性，插入的过程也是要进行遍历。也就是说简单的顺序链表没有意义。于是小根堆等数据结构也无法被纳入考虑范围。

这本质上还是一种比较消极的分配方式，没有主动的改变划分的方法，没有真正意义上改变划分的粒度。因此，我们应该采取更加严谨合理的算法来解决内存分配的问题。

