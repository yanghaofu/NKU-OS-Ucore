# Lab0.5

## 练习一

> 为了熟悉使用qemu和gdb进行调试工作,使用gdb调试QEMU模拟的RISC-V计算机加电开始运行到执行应用程序的第一条指令（即跳转到0x80200000）这个阶段的执行过程，说明RISC-V硬件加电后的几条指令在哪里？完成了哪些功能？

### 实验过程

#### QEMU源代码

我们找了QEMU的源代码，在 QEMU 源码中可以找到“上电”的时候刚执行的几条指令，如下：

```assembly
uint32_t reset_vec[10] = {
    0x00000297,                   /* 1:  auipc  t0, %pcrel_hi(fw_dyn) */
    0x02828613,                   /*     addi   a2, t0, %pcrel_lo(1b) */
    0xf1402573,                   /*     csrr   a0, mhartid  */
#if defined(TARGET_RISCV32)
    0x0202a583,                   /*     lw     a1, 32(t0) */
    0x0182a283,                   /*     lw     t0, 24(t0) */
#elif defined(TARGET_RISCV64)
    0x0202b583,                   /*     ld     a1, 32(t0) */
    0x0182b283,                   /*     ld     t0, 24(t0) */
#endif
    0x00028067,                   /*     jr     t0 */
    start_addr,                   /* start: .dword */
    start_addr_hi32,
    fdt_load_addr,                /* fdt_laddr: .dword */
    0x00000000,
                                  /* fw_dyn: */
};
```

指令是用于启动RISC-V处理器，并进行一些初始化工作，如设置寄存器、加载地址等。这个代码片段还包括条件编译指令，根据RISC-V架构是32位还是64位来选择不同的指令(if语句）。根据注释可知，这些指令还涉及到启动和初始化RISC-V处理器的一些重要步骤。

#### GDB实验

查阅资料我们知道，在 Qemu 开始执行任何指令之前，首先把两个文件加载到 Qemu 的物理内存中：即作为 bootloader 的 OpenSBI.bin 被加载到物理内存以物理地址 0x80000000 开头的区域上，同时内核镜像 os.bin 被加载到以物理地址 0x80200000 开头的区域上。

Qemu 模拟的启动流程则可以分为三个阶段：

- 第一个阶段由固化在 Qemu 内的一小段汇编程序负责；
- 第二个阶段由 bootloader 负责；
- 第三个阶段则由内核镜像负责。

接下来我们将依次观察三个阶段。

##### 第一阶段

```assembly
(gdb) x/10i 0x1000
=> 0x1000:      auipc   t0,0x0 
   0x1004:      addi    a1,t0,32
   0x1008:      csrr    a0,mhartid
   0x100c:      ld      t0,24(t0)
   0x1010:      jr      t0
   0x1014:      unimp
   0x1016:      unimp
   0x1018:      unimp
   0x101a:      0x8000
   0x101c:      unimp
```

- `auipc t0,0x0`：将当前 PC 的高 20 位与立即数 0 左移 12 位相加，得到地址 0x1000，并存入寄存器 t0。
- `addi a1,t0,32`：将寄存器 t0 的值与立即数 32 相加，得到地址 0x1020，并存入寄存器 a1。
- `csrr a0,mhartid`：将 CSR（控制和状态寄存器）mhartid 的值读出，并存入寄存器 a0。mhartid 是一个只读的 CSR，它表示当前 hart（硬件线程）的 ID。
- `ld t0,24(t0)`：将地址为 t0+24 的 64 位字加载到寄存器 t0 中。这里的地址是 0x1018，对应的字是 0x8000。
- `jr t0`：无条件跳转到寄存器 t0 中的地址，即 0x8000，并将 PC+4 存入寄存器 ra。这里的 ra 是 x1，也就是返回地址寄存器。
- `unimp`：未实现的指令，表示该位置没有有效的指令。执行该指令会导致非法指令异常。

我们可以验证：将必要的文件载入到 Qemu 物理内存之后，Qemu CPU 的程序计数器（PC, Program Counter）会被初始化为 0x1000 ，因此 Qemu 实际执行的第一条指令位于物理地址 0x1000 ，接下来它将执行寥寥数条指令并跳转到物理地址 0x80000000 对应的指令处并进入第二阶段。

##### 第二阶段

先来查看bootloader加载到物理内存后的指令：

```assembly
(gdb) x/10i 0x80000000
   0x80000000:  csrr    a6,mhartid
   0x80000004:  bgtz    a6,0x80000108
   0x80000008:  auipc   t0,0x0
   0x8000000c:  addi    t0,t0,1032
   0x80000010:  auipc   t1,0x0
   0x80000014:  addi    t1,t1,-16
   0x80000018:  sd      t1,0(t0)
   0x8000001c:  auipc   t0,0x0
   0x80000020:  addi    t0,t0,1020
   0x80000024:  ld      t0,0(t0)
```

对比上面展示的QEMU 源码，我们发现二者执行了相同的功能，所以可知这段代码就是“上电”的时候刚执行的几条指令。这些指令包括加载启动代码的地址、设置寄存器、获取处理器信息等。在启动阶段，这些指令会被处理器执行，从而使处理器进入正确的状态以启动操作系统或其他应用程序。这是启动RISC-V处理器的非常重要的部分。

 OpenSBI 将下一阶段的入口地址预先约定为固定的 0x80200000 ，在 OpenSBI 的初始化工作完成之后，它会跳转到该地址并将计算机控制权移交给下一阶段的软件。

##### 第三阶段

为了正确地和上一阶段的OpenSBI 对接，我们需要保证内核的第一条指令位于物理地址 0x80200000 处。为此，我们需要将内核镜像预先加载到 Qemu 物理内存以地址 0x80200000 开头的区域上。

```assembly
(gdb) break *0x80200000
Breakpoint 1 at 0x80200000: file kern/init/entry.S, line 7.
(gdb) continue
Continuing.

Breakpoint 1, kern_entry () at kern/init/entry.S:7
7           la sp, bootstacktop
(gdb) x/10i $pc
=> 0x80200000 <kern_entry>:     auipc   sp,0x3
   0x80200004 <kern_entry+4>:   mv      sp,sp
   0x80200008 <kern_entry+8>:   j       0x8020000a <kern_init>
   0x8020000a <kern_init>:      auipc   a0,0x3
   0x8020000e <kern_init+4>:    addi    a0,a0,-2
   0x80200012 <kern_init+8>:    auipc   a2,0x3
   0x80200016 <kern_init+12>:   addi    a2,a2,-10
   0x8020001a <kern_init+16>:   addi    sp,sp,-16
   0x8020001c <kern_init+18>:   li      a1,0
   0x8020001e <kern_init+20>:   sub     a2,a2,a0
```

以下是对这段代码的逐条解释：

1. auipc sp,0x3：将全局指针寄存器（sp，栈指针）设置为一个相对于当前PC（程序计数器）的偏移量，这个偏移量是0x3左移12位（即0x3000）。这个指令用于初始化栈指针。
2. j 0x8020000a：无条件跳转到地址0x8020000a，这是跳转到 kern_init 函数的入口点。
3. auipc a0,0x3：将寄存器a0设置为一个相对于当前PC的偏移量，偏移量是0x3左移12位。
4. addi a0,a0,-2：将a0寄存器的值减去2。
5. auipc a2,0x3：将寄存器a2设置为一个相对于当前PC的偏移量，偏移量是0x3左移12位。
6. addi a2,a2,-10：将a2寄存器的值减去10。
7. addi sp,sp,-16：将栈指针sp减去16，分配一块新的栈空间。
8. li a1,0：将寄存器a1设置为0。
9. sub a2,a2,a0：将a2寄存器的值减去a0的值，将结果存储在a2中。

总的来说，这段代码的功能初始化了一些寄存器、分配栈空间、并设置参数，然后跳转到 kern_init 函数的入口点。

### 实验总结

通过上面的实验，我们总体了解了RISC-V计算机在从“加电”到内核运行运行的全过程。在实验的过程中我们也巩固了课堂知识，学习了新的知识。

#### 本实验中重要的知识点

- **RISC-V**：一种开放的指令集架构（ISA），它支持多种处理器设计和实现。RISC-V 的名称表示它是第五代精简指令集（RISC）计算机。其具有完全开放、可移植、模块化、高效的特点。
- 引导加载程序（bootloader）：一段存储在 ROM（只读存储器）或者其他非易失性存储器中的程序，它的作用是在处理器加电后执行一些初始化操作，然后加载操作系统内核到内存中，并将控制权交给内核。引导加载程序通常分为两个阶段：第一阶段负责初始化硬件设备，如 CPU、内存、外设等；第二阶段负责从磁盘或者网络上读取操作系统内核文件，并将其复制到内存中。
- 进程管理（内核接管控制权后）：通电后，操作系统会创建一个特殊的进程，称为初始进程，它是所有其他进程的祖先进程，它负责启动其他的系统服务和用户程序。然后为每个进程分配一个进程控制块（PCB），操作系统通过维护一组状态队列来管理不同状态的进程。之后操作系统通过使用 MMU 来实现虚拟内存和地址转换机制，使得每个进程都有自己独立的地址空间，并且可以动态地调整大小和位置。然后操作系统会为每个进程初始化一些寄存器，最后会根据一定的策略分配处理器给就绪状态的进程。
- 学习了使用GDB调试工具、固件Bootloader的加载过程、QEMU硬件模拟器的使用。GDB调试工具可以帮助程序员定位代码中的错误，快速解决问题。固件Bootloader的加载过程是操作系统启动的重要阶段，类似于BIOS的作用，用来加载操作系统内核。QEMU硬件模拟器则为操作系统的开发和测试提供了便利平台。在对应的OS原理中，系统的调试和错误定位是系统开发调试的重要课题之一，固件Bootloader的加载过程也是操作系统启动流程中不可或缺的环节，QEMU硬件模拟器则为系统软件开发和测试提供了方便和安全的环境。

#### 实验指导书未提到知识点

- 经查阅，我们发现**QEMU 有两种模式**：用户模式和系统模式。用户模式可以在主机操作系统上运行单个目标架构的程序；系统模式可以模拟整个目标架构的硬件系统，包括 CPU、内存、外设等。在 QEMU 的系统模式下，RISC-V 架构的加电开机流程与上述的略有不同，主要是因为 QEMU 提供了一些虚拟化的特性和设备，以方便用户使用和配置。
- **OpenSBI 的启动流程**，它主要分为两个阶段：第一阶段是 fw_base.S，它是一个汇编文件，它负责进行底层初始化；第二阶段是 fw_jump.S 或者 fw_dynamic.S，它们是两种不同的固件类型，它们负责加载操作系统内核并跳转到内核入口地址。

# Lab1 

## 练习1：理解内核启动中的程序入口操作

> 阅读 kern/init/entry.S内容代码，结合操作系统内核启动流程，说明指令 la sp, bootstacktop 完成了什么操作，目的是什么？ tail kern_init 完成了什么操作，目的是什么？

```c#
#kern/init/entry.S代码
#include <mmu.h>
#include <memlayout.h>

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    la sp, bootstacktop
    //la,load address，即将返回地址保存在sp寄存器中

    tail kern_init
    //tail是tail call的缩写是RISC-V的一条伪指令，相当于函数调用

.section .data
    # .align 2^12
    .align PGSHIFT
    .global bootstack
bootstack:
    .space KSTACKSIZE 
     //为 bootstack 预留 KSTACKSIZE 字节的空间，为内核栈分配一定的大小
    .global bootstacktop
bootstacktop:
```

kern/init/entry.S中的指令 `la sp, bootstacktop` 完成的操作是将 `bootstacktop` 的地址加载到寄存器 `sp`，其中 `sp` 是栈指针寄存器。使当前的栈指针（sp）被设置为内核栈顶（bootstacktop），即将栈指针初始化为内核栈的顶部。目的是目的是初始化栈，为栈分配内存空间，以便操作系统可以使用这个栈空间进行内核代码的执行，比如中断处理和调度等。

`tail` 指令是一个尾递归调用的指令，它会将当前的函数调用栈帧替换为新的函数调用栈帧，从而实现函数调用的跳转。指令 `tail kern_init` 是在内核的入口点处尾调用了/kern/init.c中的函数`kern_init`——操作系统内核的初始化函数，即将程序的执行流程跳转到 `kern_init` 函数的起始地址（这是操作系统内核的入口点）。这个操作的目的是启动操作系统内核的初始化过程，让系统开始执行内核的一系列初始化代码和其他的引导流程。

```c#
int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);//将 edata 到 end 之间的内存区域清零,确保这段内存在初始化之前处于一个确定的状态

    cons_init();  // init the console初始化控制台是为了确保操作系统能够与用户进行交互，并输出必要的信息

    const char *message = "(THU.CST) os is loading ...\n";
    cprintf("%s\n\n", message);

    print_kerninfo();//打印内核信息。这是为了输出操作系统内核的相关信息，如版本号、编译时间等

    // grade_backtrace();

    idt_init();  // init interrupt descriptor table中断描述符表是操作系统中用于处理中断和异常的数据结构

    // rdtime in mbare mode crashes
    clock_init();  // init clock interrupt时钟中断是操作系统中一个重要的定时机制，用于控制任务切换、时间片轮转等

    intr_enable();  // enable irq interrupt允许处理器响应外部中断请求
    
    while (1)//死循环，OS常驻内存
        ;
}
//这个函数打印了一个字符串"(THU.CST) os is loading …\n"之后就进入了循环阶段，等待外部中断的发生。打印这个字符串的函数是cprintf，之所以不选择直接使用printf函数输出，是因为C语言的标准库函数依赖glibc提供的运行时环境。
```

如上边代码所示，总控函数一方面负责初始化与各种硬件的交互(例如与显卡、中断控制器、定时器等)，另一方面初始化各种内核功能(比如初始化物理内存管理器、中断描述符表IDT等)，之后便通过一个自旋死循环令操作系统常驻内存，通过监听各种中断提供操作系统服务。

## 练习2：完善中断处理 （需要编程）

> 请编程完善trap.c中的中断处理函数trap，在对时钟中断进行处理的部分填写kern/trap/trap.c函数中处理时钟中断的部分，使操作系统每遇到100次时钟中断后，调用print_ticks子程序，向屏幕上打印一行文字”100 ticks”，在打印完10行后调用sbi.h中的shut_down()函数关机。
>
> 要求完成问题1提出的相关函数实现，提交改进后的源代码包（可以编译执行），并在实验报告中简要说明实现过程和定时器中断处理的流程。实现要求的部分代码后，运行整个系统，大约每1秒会输出一次”100 ticks”，输出10行

- 中断处理函数实现过程

  代码添加如下：

  ~~~ c
  case IRQ_S_TIMER:
              //时钟中断
  			//1.设置下一次时钟中断
              clock_set_next_event();
              //2.计数器（ticks）加一
              //3.1.当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断
              if (++ticks % TICK_NUM == 0) {
                     print_ticks();
                      //3.2.同时打印次数（num）加一
                      num++;//上面定义的打印次数
              }
                     //4. 判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
                     if(num % 10 ==0)
                          sbi_shutdown();//调用sbi中的shutdown（）函数
              break;
  ~~~

  在中断函数的内部首先调用clock_set_next_event（）在本次中断的时候设置下一次中断事件；然后中断计数器ticks加一，记录中断次数；随后通过if语句判断，当计数器加到100的时候，嗲用print_ticks（）函数打印输出100ticks表示触发了100次时钟中断，与此同时打印次数num加一，记录打印次数；最后利用if语句判断，当打印次数num加到10的时候调用调用中的关机函数sbi_shutdown（）函数关机。

- 定时器中断的中断处理流程

  计算机监测到定时器出发的中断，首先cpu的特权集从用户态切换为内核态，PC指向stevc中断处理函数地址并继续执行，中断处理函数保存上下文，即分配内核虚拟地址空间给中断桢保存寄存器状态，然后执行实际的中断处理函数，根据终端原因分配处理函数，由于这里为定时器中断，因此分配给了interupt_handler函数，在函数内部进一步根据终端原因将中断的处理分配给了IRQ_S_TIMER，在其内部首先设置下一次定时器中断事件，然后根据题目的要求打印100ticks以及最终触发shutdown函数关机。

* 运行结果展示

  <img src="C:\Users\lenovo\AppData\Roaming\Typora\typora-user-images\image-20230924094226258.png" alt="image-20230924094226258" style="zoom:120%;" />

## 扩展练习 Challenge1：描述与理解中断流程

> 描述ucore中处理中断异常的流程（从异常的产生开始），其中mov a0，sp的目的是什么？SAVE_ALL中寄寄存器保存在栈中的位置是什么确定的？对于任何中断，__alltraps 中都需要保存所有寄存器吗？请说明理由。

中断和异常事件都会打断正在执行的程序，并引发相应的处理过程。
中断是指来自外部设备或软件的信号，用于通知操作系统某个事件已发生。常见的硬件中断包括时钟中断、键盘中断、磁盘中断等;而软件中断则是由程序主动触发的，例如系统调用。当中断发生时，CPU会立即暂停当前执行的程序，并跳转到相应的中断处理程序进行处理；异常则是指程序执行过程中出现的意外情况或错误。例如，除零异常、内存访问异常等。与中断不同，异常是由程序内部产生的，并且可能导致程序的非正常终止。

处理中断异常的流程如下：

- 异常产生：当中断发生时，SEPC寄存器存放需要跳转的PC值。由于内核初始化时将SEPC寄存器设置为了`__alltraps`，所以会跳转到该处执行。保存寄存器后跳转到`trap`函数继续执行。这里需要利用`stvec`提供中断向量表的基地址。（SEPC寄存器的值是在32位下是4字节对齐的）
- 处理程序的执行:处理程序是由操作系统提供的，用于响应特定中断事件的代码逻辑。即在判断异常是中断还是异常后可跳转到对应的处理函数`interrupt_handler`或`interrupt_handler`处根据`cause`的值执行相应的处理程序。
- 中断处理程序的返回:中断处理程序执行完毕后，需要恢复之前的执行现场。这包括恢复寄存器的值、返回到原来的程序位置继续执行等操作。

中断异常产生时，指令`mov a0, sp`将当前的栈指针保存到寄存器`a0`中（`a0~a7`寄存器用于存储函数参数）。这个操作的目的是为了把`trap`函数的参数——指向一个结构体的指针保存在寄存器`a0`中，以便后续在异常处理程序中可以访问到栈空间，以及保存被中断的上下文信息。换句话说，sp现在指向的是中断桢的栈顶，保存的是trapframe这一个数据结构，将sp赋值给a0这个参数寄存器是为了在后续跳转到trap（）函数时默认将a0寄存器中的值作为参数进行处理。

```
    #define SAVE_ALL
   .macro SAVE_ALL

    csrw sscratch, sp

    addi sp, sp, -36 * REGBYTES
    # save x registers
    STORE x0, 0*REGBYTES(sp)
    STORE x1, 1*REGBYTES(sp)
    STORE x3, 3*REGBYTES(sp)
    STORE x4, 4*REGBYTES(sp)
    STORE x5, 5*REGBYTES(sp)
    STORE x6, 6*REGBYTES(sp)
    STORE x7, 7*REGBYTES(sp)
    STORE x8, 8*REGBYTES(sp)
    STORE x9, 9*REGBYTES(sp)
    STORE x10, 10*REGBYTES(sp)
    STORE x11, 11*REGBYTES(sp)
    STORE x12, 12*REGBYTES(sp)
    STORE x13, 13*REGBYTES(sp)
    STORE x14, 14*REGBYTES(sp)
    STORE x15, 15*REGBYTES(sp)
    STORE x16, 16*REGBYTES(sp)
    STORE x17, 17*REGBYTES(sp)
    STORE x18, 18*REGBYTES(sp)
    STORE x19, 19*REGBYTES(sp)
    STORE x20, 20*REGBYTES(sp)
    STORE x21, 21*REGBYTES(sp)
    STORE x22, 22*REGBYTES(sp)
    STORE x23, 23*REGBYTES(sp)
    STORE x24, 24*REGBYTES(sp)
    STORE x25, 25*REGBYTES(sp)
    STORE x26, 26*REGBYTES(sp)
    STORE x27, 27*REGBYTES(sp)
    STORE x28, 28*REGBYTES(sp)
    STORE x29, 29*REGBYTES(sp)
    STORE x30, 30*REGBYTES(sp)
    STORE x31, 31*REGBYTES(sp)

    # get sr, epc, badvaddr, cause
    # Set sscratch register to 0, so that if a recursive exception
    # occurs, the exception vector knows it came from the kernel
    csrrw s0, sscratch, x0
    csrr s1, sstatus
    csrr s2, sepc
    csrr s3, sbadaddr
    csrr s4, scause

    STORE s0, 2*REGBYTES(sp)
    STORE s1, 32*REGBYTES(sp)
    STORE s2, 33*REGBYTES(sp)
    STORE s3, 34*REGBYTES(sp)
    STORE s4, 35*REGBYTES(sp)
    .endm
```

在中断发生前，要把所有相关寄存器的内容都保存在堆栈中,这是通过SAVE_ALL宏完成的。在上述汇编中，首先将sp寄存器的值保存在sscratch中。然后使sp寄存器向低地址生长了36个寄存器长度，用于分别保存32个通用寄存器和4个CSR。寄存器保存的位置由在结构体`trapframe`以及`pushregs`中的定义顺序决定，因为这些寄存器是函数`trap`的参数的具体内容。在 `SAVE_ALL` 之后，我们将一整个 `TrapFrame` 存在了内核栈上，且在地址区间[sp,sp+36*8]。

对于任何中断，`__alltraps` 中都需要保存所有寄存器。这是因为中断可能会在任何时刻发生，处理器的状态可能会被修改。同时这些寄存器也都作为函数`trap`的参数，我们需要保证函数参数的完整性。而且不同的中断类型需要保存的寄存器不同，因此在 `__alltraps` 中保存所有寄存器可以确保在处理完成后可以正确地恢复上下文和继续执行原来的进程。

## 扩增练习 Challenge2：理解上下文切换机制

> 回答：在trapentry.S中汇编代码csrw sscratch, sp；csrrw s0, sscratch, x0实现了什么操作，目的是什么？save all里面保存了stval scause这些csr，而在restore all里面却不还原它们？那这样store的意义何在呢？

- csrw sscratch, sp；csrrw s0, sscratch, x0分析

  - 实现的操作: 对于csrw sscratch, sp而言，sscratch寄存器是一个特权寄存器，用于保存一些临时的上下文信息。在中断处理的初期，保存上下文的时候会将一部分寄存器的值保存到中断帧中，因此栈指针会发生变化。为了恢复中断发生前的内核栈空间栈指针的原始状态，将原先的栈顶指针 sp保存到sscratch寄存器。对于csrrw s0, sscratch, x0而言，是将sscratch的值赋值给s0寄存器，我们通过sscratch的数值判断是内核态产生的中断还是用户态产生的中断（若中断前处于S态，sscratch为0，若中断前处于U态，sscratch存储内核栈地址）
  - 实现的目的:csrw sscratch, sp为了确保在恢复上下文时能够正确地恢复栈顶指针。csrrw s0, sscratch, x0为了判断中断时所处的特权级。

- save all、restore all及csr分析

  - 为什么不在restore all里面还原它们?

    save_all和restore_all分别起到上下文保存和恢复的功能。在save_all中在内核的虚拟地址中开辟了一块空间用于存储32个通用寄存器的状态，同时也保存status保存中断或异常发生时的状态寄存器的值（如中断使能状态、特权级等），sepc保存中断或异常发生时的指令地址。对于具有变长指令的RISC-V系统上的指令读取访问错误，使用sbadaddr
     保存指向导致故障的指令部分。scause保存导致中断或异常的原因。以上都被封装在trapframe这个结构体中。

    其中scause在实际的中断处理函数中作为判断中断类型的依据被使用。

    在恢复上下文的时候，需要将status恢复以协助判断CPU特权级等信息，而且需要恢复sepc中断或异常发生时的指令地址以便继续执行中断后的进程指令。但是由于不需要在判断中断类型因此也不需要scause。sbadvaddr被用来定位错误发生的位置，以便进行错误处理或记录异常信息。因此当异常处理结束后就不再需要它了。当然所有寄存器的状态也是需要恢复的

  - store的意义

    save scause和sbadvaddr的意义在上面也有回答。scause保存导致中断或异常的原因，在实际的中断处理函数中作为判断中断类型的依据被使用，帮助中断处理函数能将特定的中断指令正确分配到对应的中断处理子函数中。sbadaddr 保存指向导致故障的指令部分，被用来定位错误发生的位置，以便进行错误处理或记录异常信息。因此在保存上下文的时候保存这两个指令也是有意义的。

## 扩展练习Challenge3：完善异常中断

> 编程完善在触发一条非法指令异常 mret和ebreak，在 kern/trap/trap.c的异常处理函数中捕获，并对其进行处理，简单输出异常类型和异常指令触发地址，即“Illegal instruction caught at 0x(地址)”，“ebreak caught at 0x（地址）”与“Exception type:Illegal instruction"，“Exception type: breakpoint”。

### 触发异常

我们在在init.c中使用内联汇编来触发异常函数。

```assembly
    asm volatile("ebreak");
    asm volatile("mret");
```

我们查看汇编代码：

```assembly
(gdb)  x/10i 0x80200040
   0x80200040 <kern_init+52>:   jal ra,0x802000a6 <print_kerninfo>
   0x80200044 <kern_init+56>:   jal ra,0x8020018a <idt_init>
   0x80200048 <kern_init+60>:   jal ra,0x80200136 <clock_init>
   0x8020004c <kern_init+64>:   jal ra,0x80200184 <intr_enable>
   0x80200050 <kern_init+68>:   ebreak
   0x80200052 <kern_init+70>:   mret
   0x80200056 <kern_init+74>:   j   0x80200056 <kern_init+74>
   0x80200058 <cputch>: addi    sp,sp,-16
   0x8020005a <cputch+2>:       sd      s0,0(sp)
   0x8020005c <cputch+4>:       sd      ra,8(sp)
```

其他部分仍然是初始化的部分，我们主要关注`ebreak`和`mret`命令：

1. ebreak：这是一个断点指令，通常用于调试。它会触发一个异常，暂停程序执行，允许调试器捕获程序状态。
2. mret：这是 RISC-V 中的特权指令，用于从机器模式（M-mode）返回到先前的模式。通常在内核初始化后，从 M-mode 返回到 S-mode 或 U-mode（用户模式）。

除此之外，我们还得到一个重要的信息：**`ebreak`指令占用2个字节，所以在执行断点异常处理后异常程序计数器（EPC）需要增加2**。

### 异常处理

设置好断点后，我们还需要设置异常处理：

```c
        case CAUSE_ILLEGAL_INSTRUCTION:
             // 非法指令异常处理
            cprintf("Exception type: Illegal instruction\n");
            cprintf("Illegal instruction caught at 0x%x\n",tf->epc);
            tf->epc+=4;
            break;
        case CAUSE_BREAKPOINT:
            //断点异常处理
            cprintf("Exception type: breakpoint\n");
            cprintf("ebreak caught at 0x%x\n",tf->epc);
            tf->epc+=2;
            break;
```


我们来详细解释这两个异常的处理过程：

1. 非法指令异常（Illegal Instruction Exception）处理：
   - 当发生非法指令异常时，首先会输出异常类型信息，指示这是一个非法指令异常。
   - 接着，输出触发异常的指令地址，即 `tf->epc`，以便在调试时能够追踪到异常发生的位置。
   - 然后，通过 `tf->epc += 4`，将异常程序计数器（EPC）增加4，这是因为通常异常发生后需要跳过当前的异常指令，以便继续执行下一条指令。
2. 断点异常（Breakpoint Exception）处理：
   - 当发生断点异常时，同样首先输出异常类型信息，指示这是一个断点异常。
   - 接着，输出触发异常的指令地址，即 `tf->epc`，以便在调试时能够追踪到异常发生的位置。
   - 然后，通过 `tf->epc += 2`，将异常程序计数器（EPC）增加2，这是因为通常断点异常是由 `ebreak` 指令触发的，它只占用2个字节。

### 运行结果

<img src="C:\Users\lenovo\AppData\Roaming\Typora\typora-user-images\image-20230924094143791.png" alt="image-20230924094143791" style="zoom:100%;" />

通过异常触发和异常处理，我们成功输出了异常类型并追踪到异常发生的位置。完成了Challenge3。

## 实验总结

### 得分情况

<img src="C:\Users\lenovo\AppData\Roaming\Typora\typora-user-images\image-20230924094631512.png" alt="image-20230924094631512" style="zoom:80%;" />

### 本实验中重要的知识点

- 主要通过实验了解了上下文切换、中断描述符表、异常向量表以及中断的启用。

  其中，上下文切换是指在切换进程时需要保存和恢复寄存器的过程，这是操作系统中进程管理的关键操作之一；中断描述符表和异常向量表则是用于管理和处理异常和中断的数据结构；最后，中断的启用是指通过设置系统状态寄存器来允许中断请求进入处理器。

  在操作系统的原理中，上下文切换、中断和异常等都是操作系统中进程管理和系统调用等核心模块的重要支撑，其核心思想是为了实现系统的高效和安全性；中断描述符表和异常向量表也都是操作系统中异常处理的重要数据结构，其核心作用是为了确保异常和中断的处理流程能够正确和高效地执行；最后，中断的启用也是操作系统中控制中断流程的重要手段，其核心目标是确保系统的可靠性和高性能。

* 加深对慢操作触发识别的理解。

   如何知道一个进程被“慢操作”（需要调用硬件资源的操作）触发是处理进程调度问题的2个要点之一。理论课上讲到所有的慢操作必须通过操作系统才能获得系统资源。也就是说慢操作必须在内核态下执行才可以获得更高的权限，才能够可以执行一些受限制的操作，如直接访问底层硬件设备或操作系统资源。在实验中的kern/init.c代码中我们看到了内核初始化函数中进行的硬件交互(例如与显卡、中断控制器、定时器等)的初始化。因此验证了由于慢操作必须通过操作系统才能获取系统资源从而慢操作一定会被操作系统识别这个实现逻辑。

* 加深对中断和异常的理解

  本实验通过展现出interrupt_handler(tf)和exception_handler(tf)两个函数的内部代码，让我们思考如何区分中断和异常。中断来源于CPU之外的中断事件，即与当前运行指令无关的中断事件，如I/O中断、时钟中断、外部信号中断等。异常，来源于CPU内部的中断事件，如地址异常、算术异常、处理器硬件故障等。

### 实验指导书未提到知识点

* 本实验对于关中断和开中断的设计不是很多，仅给出了最基本的代码如下：

  ~~~ c
  /* intr_enable - enable irq interrupt, 设置sstatus的Supervisor中断使能位 */
  void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
  /* intr_disable - disable irq interrupt */
  void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
  ~~~

  经过查阅了解到intr_disable是为了让CPU在一段时间内执行指令时不被打扰而设计的，例如当CPU在进行恢复现场的操作时，往往CPU是不允许被其他的程序打扰的，此时就要启动intr_disable，不再相应其他的请求。当现场恢复完毕后，CPU就启动intr_enable，代表可以进行进程切换。
  
* **ebreak 指令**：一种同步异常指令，它的作用是触发一个断点异常，使得处理器进入调试模式。ebreak 指令通常用于程序开发和测试的过程中，它可以让程序员在**指定的位置暂停程序的执行**，检查和修改寄存器和内存的值，或者执行其他的调试操作。当处理器执行到 ebreak 指令时，它会做以下几件事：

  - 处理器会停止执行当前的程序流，转而跳转到 mtvec 寄存器定义的异常入口地址开始执行。mtvec 寄存器是一个机器模式下的控制和状态寄存器（CSR），它用来存储异常处理程序的基地址。
  - 处理器会切换到机器模式（M-Mode），这是 RISC-V 中最高权限的特权模式。在机器模式下，处理器可以访问所有的指令和寄存器，以及一些特定于平台的硬件设备。
  - 处理器会将异常原因记录到 mcause 寄存器中，这是另一个机器模式下的 CSR，它用来存储异常或中断发生的原因。对于 ebreak 指令，mcause 寄存器的值为 3，表示断点异常。
  - 处理器会将发生异常的指令地址写入 mepc 寄存器中，这是第三个机器模式下的 CSR，它用来存储异常发生时的程序计数器（PC）值。对于 ebreak 指令，mepc 寄存器的值就是 ebreak 指令所在的地址。
  - 处理器会将发生异常时的指令编码保存到 mtval 寄存器中，这是第四个机器模式下的 CSR，它用来存储异常发生时的附加信息。对于 ebreak 指令，mtval 寄存器的值就是 ebreak 指令的编码。

  当处理器进入异常处理程序后，它可以根据 mcause、mepc 和 mtval 等寄存器的值来判断异常发生的原因和位置，并进行相应的处理。例如，如果处理器检测到 mcause 寄存器的值为 3，表示断点异常，那么它可以通过 JTAG 或者其他调试接口与外部调试工具进行通信，并等待调试工具发送命令或者数据。