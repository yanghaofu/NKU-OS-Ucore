#include <pmm.h>
#include <list.h>
#include <string.h>
#include <default_pmm.h>

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

/*首次适应算法是一种内存分配算法，其原理是维护一个空闲块列表，当接收到内存请求时，它会沿着列表扫描，寻找第一个足够大以满足请求的块。

如果所选块的大小明显大于请求的大小，通常会将其拆分，并将剩余部分作为另一个空闲块添加到列表中。

以下是关于每个函数的总结：

default_init: 该函数用于初始化空闲块列表（free_list）并将空闲页面的数量（nr_free）设置为0。

default_init_memmap: 该函数用于初始化一个空闲块，其中包括初始化每个页面的标志、属性、引用计数以及将页面链接到空闲块列表中。

default_alloc_pages: 该函数用于搜索并返回第一个足够大以满足请求的空闲块，如果找到，它将重新调整块的大小并返回分配的页面地址。

default_free_pages: 该函数用于重新链接页面到空闲块列表中，可能会将小的空闲块合并为大的空闲块。

注释还提供了对如何使用struct list（双向链表）的一些提示，以及如何使用le2page宏来将通用列表结构转换为特定的结构（例如struct page）。

它还强调了操作每个页面的标志和属性，以确保它们的状态正确。此外，注释还提供了一些关于搜索空闲块和调整块大小的说明。

最后，注释强调了对空闲块列表的正确管理，以确保内存分配和释放的正确性和性能。*/

free_area_t free_area;

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
}

static void
default_init_memmap(struct Page *base, size_t n) {//初始化页面
    // 确保需要初始化的页面数量大于零
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p++) {
        // 断言页面已被标记为保留
        assert(PageReserved(p));
        
        // 清零页面的标志位和属性
        p->flags = p->property = 0;
        
        // 设置页面的引用计数为零
        set_page_ref(p, 0);
    }
    
    // 将第一个页面的 property 属性设置为 n，表示该块内存包含 n 个页面
    base->property = n;
    
    // 标记该页面为具有属性
    SetPageProperty(base);
    
    // 更新可用的页面数量
    nr_free += n;
    
    // 检查 free_list 是否为空，如果为空，则将当前初始化的页面添加到链表中
    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        // 如果链表不为空，遍历链表找到适当的位置将当前页面插入(按大小插入)
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


static struct Page *
default_alloc_pages(size_t n) {//分配n个页面
    assert(n > 0); // 断言确保请求的页面数量大于0

    if (n > nr_free) {
        return NULL; // 如果可用的空闲页面数量小于请求的数量，返回 NULL
    }

    struct Page *page = NULL; // 初始化页面指针为 NULL
    list_entry_t *le = &free_list; // 初始化链表元素指针为链表头

    while ((le = list_next(le)) != &free_list) {
        // 遍历空闲页面链表
        struct Page *p = le2page(le, page_link); // 将链表元素转换为页面结构体指针

        if (p->property >= n) {
            page = p; // 找到满足请求的页面
            break;
        }
    }

    if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link)); // 从空闲页面链表中移除找到的页面

        if (page->property > n) {
            struct Page *p = page + n; // 计算剩余的页面
            p->property = page->property - n; // 更新剩余页面的属性
            SetPageProperty(p);
            list_add(prev, &(p->page_link)); // 将剩余页面插入到链表中
        }

        nr_free -= n; // 减少可用空闲页面数量
        ClearPageProperty(page); // 清除页面属性
    }

    return page; // 返回找到的页面或 NULL
}


static void
default_free_pages(struct Page *base, size_t n) {//释放页面，根据页面的属性和相邻页面的情况来管理空闲页面链表。
    assert(n > 0); // 断言确保释放页面的数量大于0

    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(!PageReserved(p) && !PageProperty(p));
        // 断言确保页面既不是保留页面也不是属性页面
        p->flags = 0; // 清除页面的标志位
        set_page_ref(p, 0); // 将页面的引用计数设为0
    }
    base->property = n; // 更新基础页面的属性为n
    SetPageProperty(base); // 设置基础页面的属性
    nr_free += n; // 增加可用空闲页面数量

    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
        // 如果空闲页面链表为空，将基础页面添加到链表中
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                // 如果基础页面位于当前页面之前，将基础页面插入到当前页面之前
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
                // 如果基础页面需要插入到链表末尾，将其添加到末尾
            }
        }
    }

    list_entry_t* le = list_prev(&(base->page_link));//找到前一个页面块
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (p + p->property == base) {
            // 如果前一个页面与基础页面相邻
            p->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = p;
            // 合并基础页面和前一个页面
        }
    }

    le = list_next(&(base->page_link));//找到下一个
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (base + base->property == p) {
            // 如果基础页面与后一个页面相邻
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
            // 合并基础页面和后一个页面
        }
    }
}


// 这个函数返回当前空闲页面的数量
static size_t
default_nr_free_pages(void) {
    return nr_free;
}

// 这个函数执行了一系列的测试来验证页面分配和释放的功能
static void
basic_check(void) {
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;

    // 分配三个页面并验证分配是否成功
    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    // 确保三个页面都不相同，没有重复分配
    assert(p0 != p1 && p0 != p2 && p1 != p2);

    // 确保三个页面的引用计数都为0
    assert(page_ref(p0) == 0);
    assert(page_ref(p1) == 0);
    assert(page_ref(p2) == 0);

    // 验证分配的页面的物理地址是否在合理的范围内
    assert(page2pa(p0) < npage * PGSIZE);
    assert(page2pa(p1) < npage * PGSIZE);
    assert(page2pa(p2) < npage * PGSIZE);

    // 保存空闲页面链表的状态，然后将其初始化为空链表，并验证链表是否为空
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));

    // 保存当前的可用空闲页面数量，将其设置为0，然后验证无法再次分配新页面
    unsigned int nr_free_store = nr_free;
    nr_free = 0;
    assert(alloc_page() == NULL);

    // 释放三个页面并确保可用空闲页面数量为3
    free_page(p0);
    free_page(p1);
    free_page(p2);
    assert(nr_free == 3);

    // 再次分配三个页面
    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    // 验证再次分配页面后不能再分配新页面
    assert(alloc_page() == NULL);//？

    // 释放一个页面并验证空闲页面链表不为空
    free_page(p0);
    assert(!list_empty(&free_list));

    struct Page *p;
    
    // 再次分配页面并确保返回的页面与之前释放的页面相同
    assert((p = alloc_page()) == p0);
    assert(alloc_page() == NULL);

    // 还原空闲页面链表的状态和可用空闲页面数量，并释放剩余的页面
    assert(nr_free == 0);
    free_list = free_list_store;
    nr_free = nr_free_store;
    free_page(p);
    free_page(p1);
    free_page(p2);
}


// LAB2: below code is used to check the first fit allocation algorithm
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
        count ++, total += p->property;
    }
    assert(total == nr_free_pages());

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
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
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
    }
    assert(count == 0);
    assert(total == 0);
}
//这个结构体在
const struct pmm_manager default_pmm_manager = {
    .name = "default_pmm_manager",
    .init = default_init,
    .init_memmap = default_init_memmap,
    .alloc_pages = default_alloc_pages,
    .free_pages = default_free_pages,
    .nr_free_pages = default_nr_free_pages,
    .check = default_check,
};

