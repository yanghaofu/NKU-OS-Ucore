#ifndef __KERN_MM_SWAP_LRU_H__
#define __KERN_MM_SWAP_LRU_H__

#include <swap.h>
extern struct swap_manager swap_manager_lru;

//好吧，真讨厌，让我们看看，可以接着利用那个链表，表头依然是最老的，表尾依然是最新的，但是我们需要在某个page被用到之后，
//把它从链表里取下来，然后插回链表的屁股里面。但是现在就是page被access的时候我不太能自动发现然后触发更新……先想想办法吧，如果实在不行
//就只能手动触发更新了……

#endif
