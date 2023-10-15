#include <pmm.h>
#include <list.h>
#include <string.h>
#include <stdio.h>
#include <buddy_system_pmm.h>

free_buddy_t buddy_s;
#define buddy_array (buddy_s.free_array)
#define max_order (buddy_s.max_order)
#define nr_free (buddy_s.nr_free)
#define mem_begin 0xffffffffc020f318

static int IS_POWER_OF_2(size_t n)//检查给定的数 n 是否是2的幂
{
    if (n & (n - 1))
    {
        return 0;
    }
    else
    {
        return 1;
    }
}

static unsigned int getOrderOf2(size_t n)//计算给定数 n 最接近的2的幂的幂次
{
    unsigned int order = 0;
    while (n >> 1)
    {
        n >>= 1;
        order++;
    }
    return order;
}

static size_t ROUNDDOWN2(size_t n)//将 n 向下舍入到最接近的2的幂
{
    size_t res = 1;
    if (!IS_POWER_OF_2(n))
    {
        while (n)
        {
            n = n >> 1;
            res = res << 1;
        }
        return res >> 1;
    }
    else
    {
        return n;
    }
}

static size_t ROUNDUP2(size_t n)//向上取
{
    size_t res = 1;
    if (!IS_POWER_OF_2(n))
    {
        while (n)
        {
            n = n >> 1;
            res = res << 1;
        }
        return res;
    }
    else
    {
        return n;
    }
}

static void buddy_split(size_t n)//分割
{
    assert(n > 0 && n <= max_order);
    assert(!list_empty(&(buddy_array[n])));
    struct Page *page_a;
    struct Page *page_b;

    page_a = le2page(list_next(&(buddy_array[n])), page_link);
    page_b = page_a + (1 << (n - 1)); // 找到a的伙伴块b
    page_a->property = n - 1;
    page_b->property = n - 1;

    list_del(list_next(&(buddy_array[n])));
    list_add(&(buddy_array[n - 1]), &(page_a->page_link));
    list_add(&(page_a->page_link), &(page_b->page_link));

    return;
}

static void show_buddy_array(int left, int right) {
    assert(left >= 0 && left <= max_order && right >= 0 && right <= max_order);
    cprintf("空闲块大小   |");

    for (int i = left; i <= right; i++) {
        list_entry_t *le = &buddy_array[i];
        bool empty = 1; // 用于标记链表是否为空

        // 检查链表是否为空
        if (list_next(le) != &buddy_array[i]) {
            empty = 0;

            // 用于记录当前块的大小
            size_t current_block_size = 1 << i;

            // 遍历链表并显示每个空闲块的大小（十六进制）
            while ((le = list_next(le)) != &buddy_array[i]) {
                cprintf("%d: ", i);
                struct Page *p = le2page(le, page_link);
                size_t block_size = 1 << p->property;
                cprintf("%d|", 1 << (p->property));
                current_block_size -= block_size;
            }
        }

        // 如果链表为空，添加相应信息
        if (empty) {
            cprintf("%d: 空 |");
        }
    }

    cprintf("\n对应的页地址 |");

    // 用于显示对应的页
    for (int i = left; i <= right; i++) {
        list_entry_t *le = &buddy_array[i];
        bool empty = 1; // 用于标记链表是否为空

        // 检查链表是否为空
        if (list_next(le) != &buddy_array[i]) {
            empty = 0;

            // 遍历链表并显示每个空闲块的页
            while ((le = list_next(le)) != &buddy_array[i]) {
                struct Page *p = le2page(le, page_link);
                cprintf("%p|", p);
            }
            if (i != right) {
                cprintf("空|");
            }
        }

        // 如果链表为空，添加相应信息
        if (empty) {
            cprintf("空|");
        }
    }

    cprintf("\n");
}



static void
buddy_system_init(void)
{
    // 初始化伙伴堆链表数组中的每个free_list头
    for (int i = 0; i < MAX_BUDDY_ORDER + 1; i++)
    {
        list_init(buddy_array + i);
    }
    max_order = 0;
    nr_free = 0;
    return;
}

// 空闲链表初始化的部分
static void
buddy_system_init_memmap(struct Page *base, size_t n) // base是第一个页的地址，n是页的数量
{
    assert(n > 0);
    size_t pnum;
    unsigned int order;
    pnum = ROUNDDOWN2(n);      // 将页数向下取整为2的幂，不到2的15幂，向下取，变成14
    order = getOrderOf2(pnum); // 求出页数对应的2的幂
    struct Page *p = base;
    // 初始化pages数组中范围内的每个Page
    for (; p != base + pnum; p++)
    {
        assert(PageReserved(p));
        p->flags = 0;
        p->property = -1; // 全部初始化为非头页
        set_page_ref(p, 0);
    }
    max_order = order;
    nr_free = pnum;
    list_add(&(buddy_array[max_order]), &(base->page_link)); // 将第一页base插入数组的最后一个链表，作为初始化的最大块的头页
    base->property = max_order; // 将第一页base的property设为最大块的2幂

    return;
}

static struct Page *
buddy_system_alloc_pages(size_t requested_pages)
{
    assert(requested_pages > 0);

    if (requested_pages > nr_free)
    {
        return NULL;
    }

    struct Page *allocated_page = NULL;
    size_t adjusted_pages = ROUNDUP2(requested_pages); // 如：求7个页，给8个页
    size_t order_of_2 = getOrderOf2(adjusted_pages);   // 求出所需页数对应的2的幂,为数组下标

    // 先找有没有合适的空闲块，没有的话得分割大块
    bool found = 0;
    while (!found)
    {
        if (!list_empty(&(buddy_array[order_of_2])))
        {
            allocated_page = le2page(list_next(&(buddy_array[order_of_2])), page_link);
            list_del(list_next(&(buddy_array[order_of_2]))); // 删除空闲链表中找到的空闲块
            SetPageProperty(allocated_page);                 // 头页设置flags的第二位为1
            found = 1;
        }
        else
        {
            int i;
            for (i = order_of_2 + 1; i <= max_order; ++i)
            {
                if (!list_empty(&(buddy_array[i])))
                {
                    // cprintf("空闲链表数组NO.%d将被分裂\n", i);
                    buddy_split(i);
                    break;
                }
            }
            // 找了一圈啥也没找见，只能分配失败了
            if (i > max_order)
            {
                break;
            }
        }
    }

    if (allocated_page != NULL)
    {
        nr_free -= adjusted_pages;
    }
    return allocated_page;
}

struct Page *get_buddy(struct Page *block_addr, unsigned int block_size)
{
    size_t real_block_size = 1 << block_size;                    // 幂次转换成数
    size_t relative_block_addr = (size_t)block_addr - mem_begin; // 计算相对于初始化的第一个页的偏移量

    size_t sizeOfPage = real_block_size * sizeof(struct Page);                  // sizeof(struct Page)是0x28
    size_t buddy_relative_addr = (size_t)relative_block_addr ^ sizeOfPage;      // 异或得到伙伴块的相对地址
    struct Page *buddy_page = (struct Page *)(buddy_relative_addr + mem_begin); // 返回伙伴块指针
    return buddy_page;
}

static void
buddy_system_free_pages(struct Page *base, size_t n)
{
    assert(n > 0);
    unsigned int pnum = 1 << (base->property); // 块中页的数目
    assert(ROUNDUP2(n) == pnum);
    struct Page *left_block = base; // 放块的头页
    struct Page *buddy = NULL;
    struct Page *tmp = NULL;

    list_add(&(buddy_array[left_block->property]), &(left_block->page_link)); // 将当前块先插入对应链表中

    buddy = get_buddy(left_block, left_block->property);
    while (!PageProperty(buddy) && left_block->property < max_order)
    {
        if (left_block > buddy)
        {                                  // 若当前左块为更大块的右块
            left_block->property = -1;     // 将左块幂次置为无效
            ClearPageProperty(left_block); // 设置其空闲
            // 交换左右使得位置正确
            tmp = left_block;
            left_block = buddy;
            buddy = tmp;
        }
        // 删掉原来链表里的两个小块
        list_del(&(left_block->page_link));
        list_del(&(buddy->page_link));
        left_block->property += 1; // 左快头页设置幂次加一
        // cprintf("left_block->property=%d\n", left_block->property); //test point
        list_add(&(buddy_array[left_block->property]), &(left_block->page_link)); // 头插入相应链表
        buddy = get_buddy(left_block, left_block->property);
    }
    ClearPageProperty(left_block); // 将回收块的头页设置为空闲
    nr_free += pnum;

    return;
}

static size_t
buddy_system_nr_free_pages(void)
{
    return nr_free;
}

// LAB2: below code is used to check the first fit allocation algorithm
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
buddy_system_check(void)
{
    //basic_check();
    
    //buddy_system_init();
    cprintf("====================开始测试========================\n");
    cprintf("总空闲块数目为：%d\n", nr_free);
    cprintf("=====================申请空闲块=======================\n");


    cprintf("首先申请 p0 p1 p2 p3\n");
    cprintf("其大小为 70 35 257 63\n");

    // 申请 p0, p1, p2, p3
    struct Page *p0 = buddy_system_alloc_pages(70);
    struct Page *p1 = buddy_system_alloc_pages(35);
    struct Page *p2 = buddy_system_alloc_pages(257);
    struct Page *p3 = buddy_system_alloc_pages(63);

    show_buddy_array(0, MAX_BUDDY_ORDER);
    cprintf("\n");
    cprintf("======================释放 p1\\p3======================\n");

    // 释放 p1 和 p3
    buddy_system_free_pages(p1, 35);
    buddy_system_free_pages(p3, 63);

    cprintf("这时候 p1 和 p3 的块应该合并\n");

    show_buddy_array(0, MAX_BUDDY_ORDER);
    cprintf("\n");
    cprintf("===================再释放P0=========================\n");

    // 释放 p0
    buddy_system_free_pages(p0, 70);

    cprintf("这时候 p0 的块与伙伴块合并\n");

    show_buddy_array(0, MAX_BUDDY_ORDER);
    cprintf("\n");
    cprintf("====================再次申请========================\n");

    // 申请 p4 和 p5
    struct Page *p4 = buddy_system_alloc_pages(255);
    struct Page *p5 = buddy_system_alloc_pages(255);

    cprintf("最后我们申请 p4 p5\n");
    cprintf("其大小为 255 255\n");

    show_buddy_array(0, MAX_BUDDY_ORDER);
    cprintf("\n");
    cprintf("===================释放所有块=========================\n");

    // 释放所有页面
    buddy_system_free_pages(p2, 257);
    buddy_system_free_pages(p4, 255);
    buddy_system_free_pages(p5, 255);

    show_buddy_array(0, MAX_BUDDY_ORDER);
    cprintf("====================测试结束========================\n");

}

// 这个结构体在
const struct pmm_manager buddy_system_pmm_manager = {
    .name = "buddy_system_pmm_manager",
    .init = buddy_system_init,
    .init_memmap = buddy_system_init_memmap,
    .alloc_pages = buddy_system_alloc_pages,
    .free_pages = buddy_system_free_pages,
    .nr_free_pages = buddy_system_nr_free_pages,
    .check = buddy_system_check,
};
