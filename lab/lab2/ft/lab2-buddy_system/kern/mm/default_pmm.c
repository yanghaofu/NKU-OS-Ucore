#include <pmm.h>
#include <list.h>
#include <string.h>
#include <default_pmm.h>
#include<stdio.h>


/* In the first fit algorithm, the allocator keeps a list of free blocks (known as the free list) and,
   on receiving a request for memory, scans along the list for the first block that is large enough to
   satisfy the request. If the chosen block is significantly larger than that requested, then it is 
   usually split, and the remainder added to the list as another free block.
   Please see Page 196~198, Section 8.2 of Yan Wei Min's chinese book "Data Structure -- C programming language"
*/
// you should rewrite functions: default_init,default_init_memmap,default_alloc_pages, default_free_pages.
/*
 * Details of FFMA
 * (1) Prepare: In order to implement the First-Fit Mem Alloc (FFMA), we should manage the free mem block use some list.
 *              The struct free_area_t is used for the management of free mem blocks. At first you should
 *              be familiar to the struct list in list.h. struct list is a simple doubly linked list implementation.
 *              You should know howto USE: list_init, list_add(list_add_after), list_add_before, list_del, list_next, list_prev
 *              Another tricky method is to transform a general list struct to a special struct (such as struct page):
 *              you can find some MACRO: le2page (in memlayout.h), (in future labs: le2vma (in vmm.h), le2proc (in proc.h),etc.)
 * (2) default_init: you can reuse the  demo default_init fun to init the free_list and set nr_free to 0.
 *              free_list is used to record the free mem blocks. nr_free is the total number for free mem blocks.
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
 * (5) default_free_pages: relink the pages into  free list, maybe merge small free blocks into big free blocks.
 *               (5.1) according the base addr of withdrawed blocks, search free list, find the correct position
 *                     (from low to high addr), and insert the pages. (may use list_next, le2page, list_add_before)
 *               (5.2) reset the fields of pages, such as p->ref, p->flags (PageProperty)
 *               (5.3) try to merge low addr or high addr blocks. Notice: should change some pages's p->property correctly.
 */
free_area_t free_area;

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)
#define buddy (free_area.buddy)
#define begin_page (free_area.begin_page)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
}
//
//static void
//default_init_memmap(struct Page *base, size_t n) {
//    assert(n > 0);
//    struct Page *p = base;
//    for (; p != base + n; p ++) {
//        assert(PageReserved(p));
//        p->flags = p->property = 0;
//        set_page_ref(p, 0);
//    }
//    base->property = n;
//    SetPageProperty(base);
//    nr_free += n;
//    if (list_empty(&free_list)) {
//        list_add(&free_list, &(base->page_link));
//    } else {
//        list_entry_t* le = &free_list;
//        while ((le = list_next(le)) != &free_list) {
//            struct Page* page = le2page(le, page_link);
//            if (base < page) {
//                list_add_before(le, &(base->page_link));
//                break;
//            } else if (list_next(le) == &free_list) {
//                list_add(le, &(base->page_link));
//            }
//        }
//    }
//}
//
//static struct Page *
//default_alloc_pages(size_t n) {
//    assert(n > 0);
//    if (n > nr_free) {
//        return NULL;
//    }
//    struct Page *page = NULL;
//    list_entry_t *le = &free_list;
//    while ((le = list_next(le)) != &free_list) {
//        struct Page *p = le2page(le, page_link);
//        if (p->property >= n) {
//            page = p;
//            break;
//        }
//    }
//    if (page != NULL) {
//        list_entry_t* prev = list_prev(&(page->page_link));
//        list_del(&(page->page_link));
//        if (page->property > n) {
//            struct Page *p = page + n;
//            p->property = page->property - n;
//            SetPageProperty(p);
//            list_add(prev, &(p->page_link));
//        }
//        nr_free -= n;
//        ClearPageProperty(page);
//    }
//    return page;
//}
//
//static void
//default_free_pages(struct Page *base, size_t n) {
//    assert(n > 0);
//    struct Page *p = base;
//    for (; p != base + n; p ++) {
//        assert(!PageReserved(p) && !PageProperty(p));
//        p->flags = 0;
//        set_page_ref(p, 0);
//    }
//    base->property = n;
//    SetPageProperty(base);
//    nr_free += n;
//
//    if (list_empty(&free_list)) {
//        list_add(&free_list, &(base->page_link));
//    } else {
//        list_entry_t* le = &free_list;
//        while ((le = list_next(le)) != &free_list) {
//            struct Page* page = le2page(le, page_link);
//            if (base < page) {
//                list_add_before(le, &(base->page_link));
//                break;
//            } else if (list_next(le) == &free_list) {
//                list_add(le, &(base->page_link));
//            }
//        }
//    }
//
//    list_entry_t* le = list_prev(&(base->page_link));
//    if (le != &free_list) {
//        p = le2page(le, page_link);
//        if (p + p->property == base) {
//            p->property += base->property;
//            ClearPageProperty(base);
//            list_del(&(base->page_link));
//            base = p;
//        }
//    }
//
//    le = list_next(&(base->page_link));
//    if (le != &free_list) {
//        p = le2page(le, page_link);
//        if (base + base->property == p) {
//            base->property += p->property;
//            ClearPageProperty(p);
//            list_del(&(p->page_link));
//        }
//    }
//}
//
//static size_t
//default_nr_free_pages(void) {
//    return nr_free;
//}
//
//static void
//basic_check(void) {
//    struct Page *p0, *p1, *p2;
//    p0 = p1 = p2 = NULL;
//    assert((p0 = alloc_page()) != NULL);
//    assert((p1 = alloc_page()) != NULL);
//    assert((p2 = alloc_page()) != NULL);
//
//    assert(p0 != p1 && p0 != p2 && p1 != p2);
//    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
//
//    assert(page2pa(p0) < npage * PGSIZE);
//    assert(page2pa(p1) < npage * PGSIZE);
//    assert(page2pa(p2) < npage * PGSIZE);
//
//    list_entry_t free_list_store = free_list;
//    list_init(&free_list);
//    assert(list_empty(&free_list));
//
//    unsigned int nr_free_store = nr_free;
//    nr_free = 0;
//
//    assert(alloc_page() == NULL);
//
//    free_page(p0);
//    free_page(p1);
//    free_page(p2);
//    assert(nr_free == 3);
//
//    assert((p0 = alloc_page()) != NULL);
//    assert((p1 = alloc_page()) != NULL);
//    assert((p2 = alloc_page()) != NULL);
//
//    assert(alloc_page() == NULL);
//
//    free_page(p0);
//    assert(!list_empty(&free_list));
//
//    struct Page *p;
//    assert((p = alloc_page()) == p0);
//    assert(alloc_page() == NULL);
//
//    assert(nr_free == 0);
//    free_list = free_list_store;
//    nr_free = nr_free_store;
//
//    free_page(p);
//    free_page(p1);
//    free_page(p2);
//}
//
//// LAB2: below code is used to check the first fit allocation algorithm
//// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
//static void
//default_check(void) {
//    int count = 0, total = 0;
//    list_entry_t *le = &free_list;
//    while ((le = list_next(le)) != &free_list) {
//        struct Page *p = le2page(le, page_link);
//        assert(PageProperty(p));
//        count ++, total += p->property;
//    }
//    assert(total == nr_free_pages());
//
//    basic_check();
//
//    struct Page *p0 = alloc_pages(5), *p1, *p2;
//    assert(p0 != NULL);
//    assert(!PageProperty(p0));
//
//    list_entry_t free_list_store = free_list;
//    list_init(&free_list);
//    assert(list_empty(&free_list));
//    assert(alloc_page() == NULL);
//
//    unsigned int nr_free_store = nr_free;
//    nr_free = 0;
//
//    free_pages(p0 + 2, 3);
//    assert(alloc_pages(4) == NULL);
//    assert(PageProperty(p0 + 2) && p0[2].property == 3);
//    assert((p1 = alloc_pages(3)) != NULL);
//    assert(alloc_page() == NULL);
//    assert(p0 + 2 == p1);
//
//    p2 = p0 + 1;
//    free_page(p0);
//    free_pages(p1, 3);
//    assert(PageProperty(p0) && p0->property == 1);
//    assert(PageProperty(p1) && p1->property == 3);
//
//    assert((p0 = alloc_page()) == p2 - 1);
//    free_page(p0);
//    assert((p0 = alloc_pages(2)) == p2 + 1);
//
//    free_pages(p0, 2);
//    free_page(p2);
//
//    assert((p0 = alloc_pages(5)) != NULL);
//    assert(alloc_page() == NULL);
//
//    assert(nr_free == 0);
//    nr_free = nr_free_store;
//
//    free_list = free_list_store;
//    free_pages(p0, 5);
//
//    le = &free_list;
//    while ((le = list_next(le)) != &free_list) {
//        struct Page *p = le2page(le, page_link);
//        count --, total -= p->property;
//    }
//    assert(count == 0);
//    assert(total == 0);
//}
////这个结构体在
//const struct pmm_manager default_pmm_manager = {
//    .name = "default_pmm_manager",
//    .init = default_init,
//    .init_memmap = default_init_memmap,
//    .alloc_pages = default_alloc_pages,
//    .free_pages = default_free_pages,
//    .nr_free_pages = default_nr_free_pages,
//    .check = default_check,
//};






static void show_capacity(unsigned total_mem)
{
    for (int i = 0; i < total_mem * 2 - 1; i++)
    {
        cprintf("%u ", buddy.node_capacity[i]);
    }
    cprintf("\n\n");
}

unsigned convert_2_pow_of_2(unsigned size)//这里干脆俩函数合一起得了。如果返回值和size不一样说明它不是2的幂
{

    unsigned temp = 0;
    unsigned back_up_size = size;
    //酱紫，我们分别假设进来的是8和9.我们知道8的话，这个应该返回8，9应该返回16.如果返回值不等于输入值的话那么说明不是2的幂
    while (back_up_size)
    {
        temp++;
        back_up_size /= 2;//就这里事实上多除一次。
    }
    unsigned convert_2_pow = 1;
    for (int i = 0; i < temp - 1; i++)
        convert_2_pow *= 2;
    //举栗子证明：
    /*
    * 8:当size=0的时候temp=4。所以convert_2_pow要*3次2，返回8
    * 9：当size=0时，temp也是4.convert_2_pow还是*3次2，得到8.所以：
    *
    */



    if (convert_2_pow != size)
        convert_2_pow *= 2;
    /*
    * 这即使是15也一样。temp=1,size=7;temp=2,size=3;temp=3,size=1;temp=4,size=0;
    */
    return convert_2_pow;
}

unsigned left_child(unsigned index)
{
    //这是找到左孩子的函数，传入一个index找到其对应的左孩子的index。
    //因为是满二叉树所以是十分甚至九分的有规律。
    /*
    依然请出这个图（画了好久捏
                    | 4 |
                 | 2 | | 2 |
                |1| |1||1| |1|
    放到node_capacity里是这样：
        4   2   2   1   1   1   1
        [0] [1] [2] [3] [4] [5] [6]
    比如说我想找第二个2的左孩子，也就是[2]的左孩子。根据以前学过的（现在现找的）二叉树的规律，这个式子应该是
    left_child = index * 2 + 1;
    家人们要注意这里是下标从0开始的规律。
    */
    return index * 2 + 1;
}
unsigned right_child(unsigned index)
{
    //由瞪眼法知右孩子在左孩子右边。而且这里不用像小根堆一样担心不存在结点的情况，直接+1
    return index * 2 + 2;
}
unsigned parent(unsigned index)
{
    return (index - 1) / 2;//和之前一样总结出来
}

void buddy_init_memmap(struct Page* base, unsigned n)
{
    //老样子，这里的n是我们一共有的总内存大小。

    unsigned pow_n = convert_2_pow_of_2(n);

    cprintf("开始初始化\n");
    if (n < 1 || pow_n != n)
        return ;//就是这玩意申请得大小不符合规范

    nr_free = n;

    //struct buddy_system* self = (struct buddy_system*)calloc(2 * n * sizeof(unsigned));
    buddy.total_size = n;//我们的内存只有n。但是因为是满二叉树，所以节点有2n - 1个
    unsigned node_size = 2 * n;

    for (int i = 1; i < 2 * n; i++)
    {
        if (convert_2_pow_of_2(i) == i)
            node_size /= 2;

        buddy.node_capacity[i - 1] = node_size;
    }



    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    begin_page = base;
    cprintf("已经初始化了\n");
 
    //这里是这样的结构：
    /*
    *  我们设有4个单位的内存，那么node_size是8.因为1是2的0次幂，所以上来先/2（这也是为什么要*2的原因，这样就不用额外的if语句了
     我们想要的树是这样的：
                    | 4 | 
                 | 2 | | 2 |
                |1| |1||1| |1|
    放到node_capacity里是这样：
        4   2   2   1   1   1   1   
        [0] [1] [2] [3] [4] [5] [6]
    */

}

static void
buddy_init(void) {
    //list_init(&free_list);
    nr_free = 0;
}

//static void
//buddy_init_memmap_discarded(struct Page* base, size_t n) {
//    /*//assert(n > 0);
//    //struct Page* p = base;
//    //for (; p != base + n; p++) {
//    //    assert(PageReserved(p));
//    //    p->flags = p->property = 0;
//    //    set_page_ref(p, 0);
//    //    p->is_leaf = 1;
//    //}
//    //base->property = n;
//    //SetPageProperty(base);
//    //nr_free += n;
//
//    ////前面这里清空基本上都一样。这里因为是要做成二叉树，我们就默认n是2的幂次方的数了。
//    ////在这里，叶子节点是实际上的内存块，而它们的父亲结点是表示它们联合起来能有多大的抽象的概念。
//
//    ////这里我们把free_list当作根节点。我们有n个页，设为n = 2 ^ m，也就是m = log2 n，
//    ////也就是我们只需要合并m - 1次，最后一次交给free_list根节点连接上就行了。（为了防止出错，
//    ////举个例子，假如n是4，那么m=2. 4个页合并一次，得到两个抽象结点，然后结束，由根节点将它们连接起来。所以一共是2-1=1次。
//
//    ////准确来说，这里的东西似乎不能叫做页了，但是因为这个Page的结构体有我们需要的东西，所以姑且拿来用。
//
//    //list_entry_t temp_list;//这个是用来当队列使得。就是我每合并完两个结点，就往里面塞。下次的结点就从这里面拿
//    //if (list_empty(&temp_list)) {
//    //    list_add(&temp_list, &(base->page_link));
//    //}
//    //else {
//    //    list_entry_t* le = &temp_list;
//    //    while ((le = list_next(le)) != &temp_list) {
//    //        struct Page* page = le2page(le, page_link);
//    //        if (base < page) {
//    //            list_add_before(le, &(base->page_link));
//    //            break;
//    //        }
//    //        else if (list_next(le) == &temp_list) {
//    //            list_add(le, &(base->page_link));
//    //        }
//    //    }
//    //}
//    ////这样子之前形成的一条链表可以暂时利用。
//
//
//    //for (int m = 2; m <= n; m *= 2)//为了防止出错再来一次。假设n是8，那么要做2次。第一次结束m=4，第二次结束m=8，break。（后来还是觉得干脆再多做一次，然后直接那表头即可
//    //{
//    //    for (int i = n / m; i > 0; i--)//第一轮要做4次，也就是8/2，第二轮两次，也就是8/4
//    //    {
//    //        list_entry_t* left = &temp_list;//左节点等于表头
//    //        list_del(left);//拆下来
//    //        left->next = NULL;
//    //        left->prev = NULL;
//
//
//    //        list_entry_t* right = &temp_list;
//    //        list_del(right);//拆下来
//    //        right->next = NULL;
//    //        right->prev = NULL;
//
//    //        struct Page* father = (struct Page*)malloc(sizeof(struct Page));
//    //        father->page_link.next = right;
//    //        father->page_link.prev = left;
//    //        father->property = le2page(left, page_link)->property + le2page(right, page_link)->property;
//    //        father->is_leaf = 0;
//    //    }
//    //}*/
//    //free_list = temp_list;
//    //好吧混蛋，这些都白写了，我们重新开始。这个我实在是舍不得删
//
//    
//}
//
////这个没用咧
//void node_property_reduce(struct Page* node, size_t n)
//{
//    node->property -= n;
//    if (node->is_leaf) 
//        return;
//    node_property_reduce(le2page(node->page_link.prev, page_link), le2page(node->page_link.prev, page_link)->property);
//    if (n - le2page(node->page_link.prev, page_link)->property > 0)
//        node_property_reduce(le2page(node->page_link.next, page_link), n - le2page(node->page_link.prev, page_link)->property);
//}

static
unsigned layer(unsigned index)
{
    unsigned temp = 1;
    unsigned layer = 0;
    while (temp - 1 <= index)
    {
        layer++;
        temp *= 2;
    }
    return layer - 1;
}
static
unsigned buddy_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > buddy.node_capacity[0]) {
        //有了这个操作，以后所有能放进来的n都是可以找到地方插的。
        return 0;
    }

    unsigned index = 0;
    unsigned offset = 0;
    unsigned pow_2_n = convert_2_pow_of_2(n);


    int lor = 0;
    unsigned min = 0;
    for (int i = buddy.total_size; i != pow_2_n; i /= 2)//在找到正好可以容纳目标的快之前不要停下来啊
    {
        if (buddy.node_capacity[left_child(index)] <= buddy.node_capacity[right_child(index)])
        {
            lor = 0;
            min = buddy.node_capacity[left_child(index)];
        }
        else
        {
            lor = 1;
            min = buddy.node_capacity[right_child(index)];
        }

        if (min >= pow_2_n)
        {
            index = lor ? right_child(index) : left_child(index);
        }
        else
        {
            index = !lor ? right_child(index) : left_child(index);
        }
        //if (buddy.node_capacity[left_child(index)] >= pow_2_n)//如果现在结点的左孩子的容量装得下
        //    index = left_child(index);
        //else
        //    index = right_child(index);
    }

    buddy.node_capacity[index] = 0;//找到了就给全占了。
    nr_free -= pow_2_n;

    /*
        4   2   2   1   1   1   1   
        [0] [1] [2] [3] [4] [5] [6]
        来看看这个offset是什么玩意。比如说我找到的是[5]的这个1，
                    | 4 |
                 | 2 | | 2 |
                |1| |1||1| |1|
        那么我的offset事实上是对于最底下那一拍叶子（也就是实际存在的内存块。除叶子节点外都是抽象的结点，不实际存在）
        我的[5]对应的offset实际上是[2]。为此需要一直寻找左节点直到找到叶子：
        do(index = index * 2 + 1) while(index <= n)
        事实上，我们知道[2]是在第二层，第二层有 2 ^ (2 - 1) 个结点，那么它的offset应该从n / 2 ^ (2 - 1) * (2 - 1)
        也就是：
        (现在改变标准了，最顶上的是0层)
        offset = n / 2 ^ layer * (index - (2 ^ layer - 1))
        带入得4 / 2 * (2 - (2 - 1)) = 2, 也就是从叶子的第三个1开始往后2个都贵它了。
    */

    unsigned n_layer = layer(index);
    unsigned n_layer_pow = 1;
    for (int i = 0; i < n_layer; i++)
        n_layer_pow *= 2;
    offset = buddy.total_size / n_layer_pow * (index - n_layer_pow + 1);

    

    //然后反向回溯，把所有的经过的结点都整一边
    while (index)
    {
        index = parent(index);
        //取两个孩子较大的一个作为容量。这里取max而不是sum是可以避免判断错误导致后续有奇怪的大小进入了不该进入的地方。
        buddy.node_capacity[index] = buddy.node_capacity[left_child(index)] > buddy.node_capacity[right_child(index)] ? buddy.node_capacity[left_child(index)] : buddy.node_capacity[right_child(index)];
    }
    return offset;


    /*
    struct Page* page = NULL;
    list_entry_t* le = &free_list;//这里拿到了树根

    //然后从根开始找。
    struct Page* node = NULL;
    struct Page* left = NULL;
    struct Page* right = NULL;

    while (1)
    {
        node = le2page(le, page_link);
        if (node->is_leaf)
        {
            node->property -= n;
            page = node;
            break;
        }
        if (n < node->property / 2)//这意味着把这整个部分都划给它就太浪费了。
        {
            left = le2page(le->prev, page_link);
            if (left->property >= n)
            {
                node = left;
                node->property -= n;
                continue;
            }
            else
            {

            }
        }
        else//如果这个需求在当前结点的1/2 ~ 1区间内，那么可以划给它。
        {
            page = node;
            node_property_reduce(node, n);
            break;
        }
    }


    while ((le = list_next(le)) != &free_list) {
        struct Page* p = le2page(le, page_link);
        if (p->property >= n) {
            page = p;
            break;
        }
    }
    if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        if (page->property > n) {
            struct Page* p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));
        }
        nr_free -= n;
        ClearPageProperty(page);
    }
    return page;*/

    //全部木大（悲
}

static void
buddy_free_pages(size_t offset) {
    assert(offset >= 0);
    

    //现在我们只能拿到offset，也就是是叶子的索引。
    //于是要往上找，找到capacity为0的索引就说明我们找到刚刚的爹地了。
    unsigned pow_2_n = 1;
    unsigned index = offset + buddy.total_size - 1;

    unsigned left, right;
    while (buddy.node_capacity[index])
    {
        index = parent(index);
        pow_2_n *= 2;
        if (!index)
            break;
    }
    buddy.node_capacity[index] = pow_2_n;
    nr_free += pow_2_n;
    //现在我们已经找到了爹地，把它置为了初始值，然后把nr_free也加回来惹

    //现在把爹地的爹地们也重置为初始值捏
    while (index)//好处是如果在上一步index已经成为爹中爹，万爹之王，就不会进这里了。
    {
        index = parent(index);
        pow_2_n *= 2;

        left = left_child(index);
        right = right_child(index);

        if (buddy.node_capacity[left] + buddy.node_capacity[right] == pow_2_n)//就当这玩意左右孩子都已经是unused了的
            buddy.node_capacity[index] = pow_2_n;
        else//否则就和之前一样用超长的单目运算符搞一搞
            buddy.node_capacity[index] = buddy.node_capacity[left_child(index)] > buddy.node_capacity[right_child(index)] ? buddy.node_capacity[left_child(index)] : buddy.node_capacity[right_child(index)];

    }

}

static size_t
buddy_nr_free_pages(void) {
    return nr_free;
}


// LAB2: below code is used to check the first fit allocation algorithm
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!

struct Page* get_page(unsigned offset)
{
    struct Page* p = begin_page;
    for (; p != begin_page + offset; p++) {
    }
    return p;
}


static void
buddy_basic_check(void) {

    unsigned total_mem = 16;


    show_capacity(total_mem);

    //测试内存分配.
    unsigned alloc_4 = buddy_alloc_pages(4);
    cprintf("分配了4,offset = %u\n", alloc_4);
    show_capacity(total_mem);
    struct Page* page_4 = get_page(alloc_4);
    //然后从page_4开始后面4个页就归你了。

    unsigned alloc_2 = buddy_alloc_pages(2);
    cprintf("分配了2,offset = %u\n", alloc_2);
    show_capacity(total_mem);
    struct Page* page_2 = get_page(alloc_2);


    unsigned alloc_8 = buddy_alloc_pages(8);
    cprintf("分配了8,offset = %u\n", alloc_8);
    show_capacity(total_mem);
    struct Page* page_8 = get_page(alloc_8);


    //测试内存释放。可以分配释放交叉测试。

    cprintf("释放了alloc_8");
    buddy_free_pages(alloc_8);


    unsigned alloc_1 = buddy_alloc_pages(1);
    cprintf("分配了1,offset = %u\n", alloc_1);
    show_capacity(total_mem);


    alloc_8 = buddy_alloc_pages(8);
    cprintf("分配了8,offset = %u\n", alloc_8);
    show_capacity(total_mem);

    cprintf("释放了alloc_4");
    buddy_free_pages(alloc_4);



    /*int count = 0, total = 0;
    list_entry_t* le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page* p = le2page(le, page_link);
        assert(PageProperty(p));
        count++, total += p->property;
    }
    assert(total == nr_free_pages());


    struct Page* p0 = alloc_pages(5), * p1, * p2;
    assert(p0 != NULL);
    assert(!PageProperty(p0));

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
    assert(alloc_pages(4) == NULL);
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
    assert((p1 = alloc_pages(3)) != NULL);
    assert(alloc_page() == NULL);
    assert(p0 + 2 == p1);

    p2 = p0 + 1;
    free_page(p0);
    free_pages(p1, 3);
    assert(PageProperty(p0) && p0->property == 1);
    assert(PageProperty(p1) && p1->property == 3);

    assert((p0 = alloc_page()) == p2 - 1);
    free_page(p0);
    assert((p0 = alloc_pages(2)) == p2 + 1);

    free_pages(p0, 2);
    free_page(p2);

    assert((p0 = alloc_pages(5)) != NULL);
    assert(alloc_page() == NULL);

    assert(nr_free == 0);
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page* p = le2page(le, page_link);
        count--, total -= p->property;
    }
    assert(count == 0);
    assert(total == 0);*/
}



const struct pmm_manager buddy_system_pmm_manager = {
    .name = "buddy_system_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_basic_check,
};