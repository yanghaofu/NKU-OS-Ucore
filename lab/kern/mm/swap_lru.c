// #include <defs.h>
// #include <riscv.h>
// #include <stdio.h>
// #include <string.h>
// #include <swap.h>
// #include <swap_lru.h>
// #include <list.h>

// list_entry_t lru_list_head, *lru_curr_ptr, *lru_tail_ptr;

// /**
//  * _lru_init_mm - 为进程的内存管理初始化LRU页面替换算法。
//  *
//  * 此函数通过设置名为lru_list_head的双向链表作为页面队列来初始化特定进程内存管理的LRU页面替换算法，并将进程的sm_priv（交换管理器私有数据）更新为指向该队列。
//  *
//  * @mm: 指向进程内存管理结构（mm_struct）的指针。
//  *
//  * 返回：成功时返回0。
//  */
// static int
// _lru_init_mm(struct mm_struct *mm)
// {
//     /* 初始化lru_list_head为一个空的双向链表 */
//     list_init(&lru_list_head);
//     lru_curr_ptr = &lru_list_head;
//     lru_tail_ptr = &lru_list_head;
//     mm->sm_priv = &lru_list_head;
//     return 0;
// }


// /**
//  * _lru_map_swappable - 使用LRU页面替换算法映射页面到页面队列的最前端。
//  *
//  * 此函数使用LRU页面替换算法，将给定页面添加到页面队列的最前端，以表示它是最近访问的页面。同时，它将更新进程内存管理结构中的相关信息。
//  *
//  * @mm: 指向进程内存管理结构（mm_struct）的指针。
//  * @addr: 页面的虚拟地址。
//  * @page: 指向要映射的页面的结构指针。
//  * @swap_in: 指示页面是否被交换入物理内存的标志。
//  *
//  * 返回：成功时返回0。
//  */
// static int
// _lru_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
// {
//     list_entry_t *entry = &(page->lru_page_link);
//     assert(entry != NULL && lru_curr_ptr != NULL);

//     /* 将最近访问的页面添加到lru_list_head队列的最前端 */
//     list_add_after(lru_curr_ptr, entry);
//     lru_curr_ptr = entry;

//     page->visited = 1;
//     return 0;
// }


// /**
//  * _lru_swap_out_victim - 使用LRU页面替换算法选择一个牺牲页面并返回。
//  *
//  * 此函数使用LRU页面替换算法选择一个要牺牲的页面，将其从页面队列的尾部删除，并返回指向该页面的指针。它还更新了进程内存管理结构中的相关信息。
//  *
//  * @mm: 指向进程内存管理结构（mm_struct）的指针。
//  * @ptr_page: 用于存储被选中的牺牲页面的指针。
//  * @in_tick: 指示是否处于时钟中断的标志。
//  *
//  * 返回：成功时返回0。
//  */
// static int
// _lru_swap_out_victim(struct mm_struct *mm, struct Page **ptr_page, int in_tick)
// {
//     list_entry_t *head = (list_entry_t*)mm->sm_priv;
//     assert(head != NULL);
//     assert(in_tick == 0);

//     /* 选择一个牺牲页面 - 从尾部解除链接最近未使用的页面 */
//     list_entry_t *victim_entry = list_prev(lru_tail_ptr);
//     assert(victim_entry != head);

//     struct Page *victim_page = le2page(victim_entry, lru_page_link);

//     /* 从页面队列中解除链接牺牲页面 */
//     list_del(victim_entry);
    
//     *ptr_page = victim_page;
//     return 0;
// }


// /* ... */
