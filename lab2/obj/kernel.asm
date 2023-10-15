
bin/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址，lui加载高20位进入t0，低12位为页内偏移量我们不需要
    # boot_page_table_sv39 是一个全局符号，它指向系统启动时使用的页表的开始位置
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c02052b7          	lui	t0,0xc0205
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	01e31313          	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000c:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号（**物理地址右移12位得到物理页号**）
    srli    t0, t0, 12
ffffffffc0200010:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc0200014:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200018:	03f31313          	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc020001c:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200020:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200024:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc0200028:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc020002c:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200030:	03628293          	addi	t0,t0,54 # ffffffffc0200036 <kern_init>
    jr t0
ffffffffc0200034:	8282                	jr	t0

ffffffffc0200036 <kern_init>:
void grade_backtrace(void);


int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200036:	00006517          	auipc	a0,0x6
ffffffffc020003a:	fe250513          	addi	a0,a0,-30 # ffffffffc0206018 <edata>
ffffffffc020003e:	00006617          	auipc	a2,0x6
ffffffffc0200042:	52a60613          	addi	a2,a2,1322 # ffffffffc0206568 <end>
int kern_init(void) {
ffffffffc0200046:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200048:	8e09                	sub	a2,a2,a0
ffffffffc020004a:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020004c:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004e:	7f0010ef          	jal	ra,ffffffffc020183e <memset>
    cons_init();  // init the console
ffffffffc0200052:	3fe000ef          	jal	ra,ffffffffc0200450 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200056:	00001517          	auipc	a0,0x1
ffffffffc020005a:	7fa50513          	addi	a0,a0,2042 # ffffffffc0201850 <etext>
ffffffffc020005e:	090000ef          	jal	ra,ffffffffc02000ee <cputs>

    print_kerninfo();
ffffffffc0200062:	0dc000ef          	jal	ra,ffffffffc020013e <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200066:	404000ef          	jal	ra,ffffffffc020046a <idt_init>

    pmm_init();  // init physical memory management
ffffffffc020006a:	731000ef          	jal	ra,ffffffffc0200f9a <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc020006e:	3fc000ef          	jal	ra,ffffffffc020046a <idt_init>

    clock_init();   // init clock interrupt
ffffffffc0200072:	39a000ef          	jal	ra,ffffffffc020040c <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200076:	3e8000ef          	jal	ra,ffffffffc020045e <intr_enable>



    /* do nothing */
    while (1)
        ;
ffffffffc020007a:	a001                	j	ffffffffc020007a <kern_init+0x44>

ffffffffc020007c <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc020007c:	1141                	addi	sp,sp,-16
ffffffffc020007e:	e022                	sd	s0,0(sp)
ffffffffc0200080:	e406                	sd	ra,8(sp)
ffffffffc0200082:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200084:	3ce000ef          	jal	ra,ffffffffc0200452 <cons_putc>
    (*cnt) ++;
ffffffffc0200088:	401c                	lw	a5,0(s0)
}
ffffffffc020008a:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc020008c:	2785                	addiw	a5,a5,1
ffffffffc020008e:	c01c                	sw	a5,0(s0)
}
ffffffffc0200090:	6402                	ld	s0,0(sp)
ffffffffc0200092:	0141                	addi	sp,sp,16
ffffffffc0200094:	8082                	ret

ffffffffc0200096 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200096:	1101                	addi	sp,sp,-32
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200098:	86ae                	mv	a3,a1
ffffffffc020009a:	862a                	mv	a2,a0
ffffffffc020009c:	006c                	addi	a1,sp,12
ffffffffc020009e:	00000517          	auipc	a0,0x0
ffffffffc02000a2:	fde50513          	addi	a0,a0,-34 # ffffffffc020007c <cputch>
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000a6:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000a8:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000aa:	26a010ef          	jal	ra,ffffffffc0201314 <vprintfmt>
    return cnt;
}
ffffffffc02000ae:	60e2                	ld	ra,24(sp)
ffffffffc02000b0:	4532                	lw	a0,12(sp)
ffffffffc02000b2:	6105                	addi	sp,sp,32
ffffffffc02000b4:	8082                	ret

ffffffffc02000b6 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000b6:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000b8:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000bc:	f42e                	sd	a1,40(sp)
ffffffffc02000be:	f832                	sd	a2,48(sp)
ffffffffc02000c0:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000c2:	862a                	mv	a2,a0
ffffffffc02000c4:	004c                	addi	a1,sp,4
ffffffffc02000c6:	00000517          	auipc	a0,0x0
ffffffffc02000ca:	fb650513          	addi	a0,a0,-74 # ffffffffc020007c <cputch>
ffffffffc02000ce:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02000d0:	ec06                	sd	ra,24(sp)
ffffffffc02000d2:	e0ba                	sd	a4,64(sp)
ffffffffc02000d4:	e4be                	sd	a5,72(sp)
ffffffffc02000d6:	e8c2                	sd	a6,80(sp)
ffffffffc02000d8:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000da:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000dc:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000de:	236010ef          	jal	ra,ffffffffc0201314 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000e2:	60e2                	ld	ra,24(sp)
ffffffffc02000e4:	4512                	lw	a0,4(sp)
ffffffffc02000e6:	6125                	addi	sp,sp,96
ffffffffc02000e8:	8082                	ret

ffffffffc02000ea <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02000ea:	3680006f          	j	ffffffffc0200452 <cons_putc>

ffffffffc02000ee <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc02000ee:	1101                	addi	sp,sp,-32
ffffffffc02000f0:	e822                	sd	s0,16(sp)
ffffffffc02000f2:	ec06                	sd	ra,24(sp)
ffffffffc02000f4:	e426                	sd	s1,8(sp)
ffffffffc02000f6:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc02000f8:	00054503          	lbu	a0,0(a0)
ffffffffc02000fc:	c51d                	beqz	a0,ffffffffc020012a <cputs+0x3c>
ffffffffc02000fe:	0405                	addi	s0,s0,1
ffffffffc0200100:	4485                	li	s1,1
ffffffffc0200102:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200104:	34e000ef          	jal	ra,ffffffffc0200452 <cons_putc>
    (*cnt) ++;
ffffffffc0200108:	008487bb          	addw	a5,s1,s0
    while ((c = *str ++) != '\0') {
ffffffffc020010c:	0405                	addi	s0,s0,1
ffffffffc020010e:	fff44503          	lbu	a0,-1(s0)
ffffffffc0200112:	f96d                	bnez	a0,ffffffffc0200104 <cputs+0x16>
ffffffffc0200114:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc0200118:	4529                	li	a0,10
ffffffffc020011a:	338000ef          	jal	ra,ffffffffc0200452 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc020011e:	8522                	mv	a0,s0
ffffffffc0200120:	60e2                	ld	ra,24(sp)
ffffffffc0200122:	6442                	ld	s0,16(sp)
ffffffffc0200124:	64a2                	ld	s1,8(sp)
ffffffffc0200126:	6105                	addi	sp,sp,32
ffffffffc0200128:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc020012a:	4405                	li	s0,1
ffffffffc020012c:	b7f5                	j	ffffffffc0200118 <cputs+0x2a>

ffffffffc020012e <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc020012e:	1141                	addi	sp,sp,-16
ffffffffc0200130:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200132:	328000ef          	jal	ra,ffffffffc020045a <cons_getc>
ffffffffc0200136:	dd75                	beqz	a0,ffffffffc0200132 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200138:	60a2                	ld	ra,8(sp)
ffffffffc020013a:	0141                	addi	sp,sp,16
ffffffffc020013c:	8082                	ret

ffffffffc020013e <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020013e:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200140:	00001517          	auipc	a0,0x1
ffffffffc0200144:	76050513          	addi	a0,a0,1888 # ffffffffc02018a0 <etext+0x50>
void print_kerninfo(void) {
ffffffffc0200148:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020014a:	f6dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc020014e:	00000597          	auipc	a1,0x0
ffffffffc0200152:	ee858593          	addi	a1,a1,-280 # ffffffffc0200036 <kern_init>
ffffffffc0200156:	00001517          	auipc	a0,0x1
ffffffffc020015a:	76a50513          	addi	a0,a0,1898 # ffffffffc02018c0 <etext+0x70>
ffffffffc020015e:	f59ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc0200162:	00001597          	auipc	a1,0x1
ffffffffc0200166:	6ee58593          	addi	a1,a1,1774 # ffffffffc0201850 <etext>
ffffffffc020016a:	00001517          	auipc	a0,0x1
ffffffffc020016e:	77650513          	addi	a0,a0,1910 # ffffffffc02018e0 <etext+0x90>
ffffffffc0200172:	f45ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200176:	00006597          	auipc	a1,0x6
ffffffffc020017a:	ea258593          	addi	a1,a1,-350 # ffffffffc0206018 <edata>
ffffffffc020017e:	00001517          	auipc	a0,0x1
ffffffffc0200182:	78250513          	addi	a0,a0,1922 # ffffffffc0201900 <etext+0xb0>
ffffffffc0200186:	f31ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc020018a:	00006597          	auipc	a1,0x6
ffffffffc020018e:	3de58593          	addi	a1,a1,990 # ffffffffc0206568 <end>
ffffffffc0200192:	00001517          	auipc	a0,0x1
ffffffffc0200196:	78e50513          	addi	a0,a0,1934 # ffffffffc0201920 <etext+0xd0>
ffffffffc020019a:	f1dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020019e:	00006597          	auipc	a1,0x6
ffffffffc02001a2:	7c958593          	addi	a1,a1,1993 # ffffffffc0206967 <end+0x3ff>
ffffffffc02001a6:	00000797          	auipc	a5,0x0
ffffffffc02001aa:	e9078793          	addi	a5,a5,-368 # ffffffffc0200036 <kern_init>
ffffffffc02001ae:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001b2:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001b6:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001b8:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001bc:	95be                	add	a1,a1,a5
ffffffffc02001be:	85a9                	srai	a1,a1,0xa
ffffffffc02001c0:	00001517          	auipc	a0,0x1
ffffffffc02001c4:	78050513          	addi	a0,a0,1920 # ffffffffc0201940 <etext+0xf0>
}
ffffffffc02001c8:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001ca:	eedff06f          	j	ffffffffc02000b6 <cprintf>

ffffffffc02001ce <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001ce:	1141                	addi	sp,sp,-16

    panic("Not Implemented!");
ffffffffc02001d0:	00001617          	auipc	a2,0x1
ffffffffc02001d4:	6a060613          	addi	a2,a2,1696 # ffffffffc0201870 <etext+0x20>
ffffffffc02001d8:	04e00593          	li	a1,78
ffffffffc02001dc:	00001517          	auipc	a0,0x1
ffffffffc02001e0:	6ac50513          	addi	a0,a0,1708 # ffffffffc0201888 <etext+0x38>
void print_stackframe(void) {
ffffffffc02001e4:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02001e6:	1c6000ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc02001ea <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001ea:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02001ec:	00002617          	auipc	a2,0x2
ffffffffc02001f0:	86460613          	addi	a2,a2,-1948 # ffffffffc0201a50 <commands+0xe0>
ffffffffc02001f4:	00002597          	auipc	a1,0x2
ffffffffc02001f8:	87c58593          	addi	a1,a1,-1924 # ffffffffc0201a70 <commands+0x100>
ffffffffc02001fc:	00002517          	auipc	a0,0x2
ffffffffc0200200:	87c50513          	addi	a0,a0,-1924 # ffffffffc0201a78 <commands+0x108>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200204:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200206:	eb1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc020020a:	00002617          	auipc	a2,0x2
ffffffffc020020e:	87e60613          	addi	a2,a2,-1922 # ffffffffc0201a88 <commands+0x118>
ffffffffc0200212:	00002597          	auipc	a1,0x2
ffffffffc0200216:	89e58593          	addi	a1,a1,-1890 # ffffffffc0201ab0 <commands+0x140>
ffffffffc020021a:	00002517          	auipc	a0,0x2
ffffffffc020021e:	85e50513          	addi	a0,a0,-1954 # ffffffffc0201a78 <commands+0x108>
ffffffffc0200222:	e95ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc0200226:	00002617          	auipc	a2,0x2
ffffffffc020022a:	89a60613          	addi	a2,a2,-1894 # ffffffffc0201ac0 <commands+0x150>
ffffffffc020022e:	00002597          	auipc	a1,0x2
ffffffffc0200232:	8b258593          	addi	a1,a1,-1870 # ffffffffc0201ae0 <commands+0x170>
ffffffffc0200236:	00002517          	auipc	a0,0x2
ffffffffc020023a:	84250513          	addi	a0,a0,-1982 # ffffffffc0201a78 <commands+0x108>
ffffffffc020023e:	e79ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    }
    return 0;
}
ffffffffc0200242:	60a2                	ld	ra,8(sp)
ffffffffc0200244:	4501                	li	a0,0
ffffffffc0200246:	0141                	addi	sp,sp,16
ffffffffc0200248:	8082                	ret

ffffffffc020024a <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020024a:	1141                	addi	sp,sp,-16
ffffffffc020024c:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020024e:	ef1ff0ef          	jal	ra,ffffffffc020013e <print_kerninfo>
    return 0;
}
ffffffffc0200252:	60a2                	ld	ra,8(sp)
ffffffffc0200254:	4501                	li	a0,0
ffffffffc0200256:	0141                	addi	sp,sp,16
ffffffffc0200258:	8082                	ret

ffffffffc020025a <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020025a:	1141                	addi	sp,sp,-16
ffffffffc020025c:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020025e:	f71ff0ef          	jal	ra,ffffffffc02001ce <print_stackframe>
    return 0;
}
ffffffffc0200262:	60a2                	ld	ra,8(sp)
ffffffffc0200264:	4501                	li	a0,0
ffffffffc0200266:	0141                	addi	sp,sp,16
ffffffffc0200268:	8082                	ret

ffffffffc020026a <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020026a:	7115                	addi	sp,sp,-224
ffffffffc020026c:	e962                	sd	s8,144(sp)
ffffffffc020026e:	8c2a                	mv	s8,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200270:	00001517          	auipc	a0,0x1
ffffffffc0200274:	74850513          	addi	a0,a0,1864 # ffffffffc02019b8 <commands+0x48>
kmonitor(struct trapframe *tf) {
ffffffffc0200278:	ed86                	sd	ra,216(sp)
ffffffffc020027a:	e9a2                	sd	s0,208(sp)
ffffffffc020027c:	e5a6                	sd	s1,200(sp)
ffffffffc020027e:	e1ca                	sd	s2,192(sp)
ffffffffc0200280:	fd4e                	sd	s3,184(sp)
ffffffffc0200282:	f952                	sd	s4,176(sp)
ffffffffc0200284:	f556                	sd	s5,168(sp)
ffffffffc0200286:	f15a                	sd	s6,160(sp)
ffffffffc0200288:	ed5e                	sd	s7,152(sp)
ffffffffc020028a:	e566                	sd	s9,136(sp)
ffffffffc020028c:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020028e:	e29ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200292:	00001517          	auipc	a0,0x1
ffffffffc0200296:	74e50513          	addi	a0,a0,1870 # ffffffffc02019e0 <commands+0x70>
ffffffffc020029a:	e1dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    if (tf != NULL) {
ffffffffc020029e:	000c0563          	beqz	s8,ffffffffc02002a8 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002a2:	8562                	mv	a0,s8
ffffffffc02002a4:	3a6000ef          	jal	ra,ffffffffc020064a <print_trapframe>
ffffffffc02002a8:	00001c97          	auipc	s9,0x1
ffffffffc02002ac:	6c8c8c93          	addi	s9,s9,1736 # ffffffffc0201970 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002b0:	00001997          	auipc	s3,0x1
ffffffffc02002b4:	75898993          	addi	s3,s3,1880 # ffffffffc0201a08 <commands+0x98>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002b8:	00001917          	auipc	s2,0x1
ffffffffc02002bc:	75890913          	addi	s2,s2,1880 # ffffffffc0201a10 <commands+0xa0>
        if (argc == MAXARGS - 1) {
ffffffffc02002c0:	4a3d                	li	s4,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002c2:	00001b17          	auipc	s6,0x1
ffffffffc02002c6:	756b0b13          	addi	s6,s6,1878 # ffffffffc0201a18 <commands+0xa8>
    if (argc == 0) {
ffffffffc02002ca:	00001a97          	auipc	s5,0x1
ffffffffc02002ce:	7a6a8a93          	addi	s5,s5,1958 # ffffffffc0201a70 <commands+0x100>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002d2:	4b8d                	li	s7,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002d4:	854e                	mv	a0,s3
ffffffffc02002d6:	3ca010ef          	jal	ra,ffffffffc02016a0 <readline>
ffffffffc02002da:	842a                	mv	s0,a0
ffffffffc02002dc:	dd65                	beqz	a0,ffffffffc02002d4 <kmonitor+0x6a>
ffffffffc02002de:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02002e2:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002e4:	c999                	beqz	a1,ffffffffc02002fa <kmonitor+0x90>
ffffffffc02002e6:	854a                	mv	a0,s2
ffffffffc02002e8:	538010ef          	jal	ra,ffffffffc0201820 <strchr>
ffffffffc02002ec:	c925                	beqz	a0,ffffffffc020035c <kmonitor+0xf2>
            *buf ++ = '\0';
ffffffffc02002ee:	00144583          	lbu	a1,1(s0)
ffffffffc02002f2:	00040023          	sb	zero,0(s0)
ffffffffc02002f6:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002f8:	f5fd                	bnez	a1,ffffffffc02002e6 <kmonitor+0x7c>
    if (argc == 0) {
ffffffffc02002fa:	dce9                	beqz	s1,ffffffffc02002d4 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002fc:	6582                	ld	a1,0(sp)
ffffffffc02002fe:	00001d17          	auipc	s10,0x1
ffffffffc0200302:	672d0d13          	addi	s10,s10,1650 # ffffffffc0201970 <commands>
    if (argc == 0) {
ffffffffc0200306:	8556                	mv	a0,s5
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200308:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020030a:	0d61                	addi	s10,s10,24
ffffffffc020030c:	4ea010ef          	jal	ra,ffffffffc02017f6 <strcmp>
ffffffffc0200310:	c919                	beqz	a0,ffffffffc0200326 <kmonitor+0xbc>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200312:	2405                	addiw	s0,s0,1
ffffffffc0200314:	09740463          	beq	s0,s7,ffffffffc020039c <kmonitor+0x132>
ffffffffc0200318:	000d3503          	ld	a0,0(s10)
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020031c:	6582                	ld	a1,0(sp)
ffffffffc020031e:	0d61                	addi	s10,s10,24
ffffffffc0200320:	4d6010ef          	jal	ra,ffffffffc02017f6 <strcmp>
ffffffffc0200324:	f57d                	bnez	a0,ffffffffc0200312 <kmonitor+0xa8>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200326:	00141793          	slli	a5,s0,0x1
ffffffffc020032a:	97a2                	add	a5,a5,s0
ffffffffc020032c:	078e                	slli	a5,a5,0x3
ffffffffc020032e:	97e6                	add	a5,a5,s9
ffffffffc0200330:	6b9c                	ld	a5,16(a5)
ffffffffc0200332:	8662                	mv	a2,s8
ffffffffc0200334:	002c                	addi	a1,sp,8
ffffffffc0200336:	fff4851b          	addiw	a0,s1,-1
ffffffffc020033a:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc020033c:	f8055ce3          	bgez	a0,ffffffffc02002d4 <kmonitor+0x6a>
}
ffffffffc0200340:	60ee                	ld	ra,216(sp)
ffffffffc0200342:	644e                	ld	s0,208(sp)
ffffffffc0200344:	64ae                	ld	s1,200(sp)
ffffffffc0200346:	690e                	ld	s2,192(sp)
ffffffffc0200348:	79ea                	ld	s3,184(sp)
ffffffffc020034a:	7a4a                	ld	s4,176(sp)
ffffffffc020034c:	7aaa                	ld	s5,168(sp)
ffffffffc020034e:	7b0a                	ld	s6,160(sp)
ffffffffc0200350:	6bea                	ld	s7,152(sp)
ffffffffc0200352:	6c4a                	ld	s8,144(sp)
ffffffffc0200354:	6caa                	ld	s9,136(sp)
ffffffffc0200356:	6d0a                	ld	s10,128(sp)
ffffffffc0200358:	612d                	addi	sp,sp,224
ffffffffc020035a:	8082                	ret
        if (*buf == '\0') {
ffffffffc020035c:	00044783          	lbu	a5,0(s0)
ffffffffc0200360:	dfc9                	beqz	a5,ffffffffc02002fa <kmonitor+0x90>
        if (argc == MAXARGS - 1) {
ffffffffc0200362:	03448863          	beq	s1,s4,ffffffffc0200392 <kmonitor+0x128>
        argv[argc ++] = buf;
ffffffffc0200366:	00349793          	slli	a5,s1,0x3
ffffffffc020036a:	0118                	addi	a4,sp,128
ffffffffc020036c:	97ba                	add	a5,a5,a4
ffffffffc020036e:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200372:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200376:	2485                	addiw	s1,s1,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200378:	e591                	bnez	a1,ffffffffc0200384 <kmonitor+0x11a>
ffffffffc020037a:	b749                	j	ffffffffc02002fc <kmonitor+0x92>
            buf ++;
ffffffffc020037c:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020037e:	00044583          	lbu	a1,0(s0)
ffffffffc0200382:	ddad                	beqz	a1,ffffffffc02002fc <kmonitor+0x92>
ffffffffc0200384:	854a                	mv	a0,s2
ffffffffc0200386:	49a010ef          	jal	ra,ffffffffc0201820 <strchr>
ffffffffc020038a:	d96d                	beqz	a0,ffffffffc020037c <kmonitor+0x112>
ffffffffc020038c:	00044583          	lbu	a1,0(s0)
ffffffffc0200390:	bf91                	j	ffffffffc02002e4 <kmonitor+0x7a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200392:	45c1                	li	a1,16
ffffffffc0200394:	855a                	mv	a0,s6
ffffffffc0200396:	d21ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc020039a:	b7f1                	j	ffffffffc0200366 <kmonitor+0xfc>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020039c:	6582                	ld	a1,0(sp)
ffffffffc020039e:	00001517          	auipc	a0,0x1
ffffffffc02003a2:	69a50513          	addi	a0,a0,1690 # ffffffffc0201a38 <commands+0xc8>
ffffffffc02003a6:	d11ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    return 0;
ffffffffc02003aa:	b72d                	j	ffffffffc02002d4 <kmonitor+0x6a>

ffffffffc02003ac <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003ac:	00006317          	auipc	t1,0x6
ffffffffc02003b0:	06c30313          	addi	t1,t1,108 # ffffffffc0206418 <is_panic>
ffffffffc02003b4:	00032303          	lw	t1,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003b8:	715d                	addi	sp,sp,-80
ffffffffc02003ba:	ec06                	sd	ra,24(sp)
ffffffffc02003bc:	e822                	sd	s0,16(sp)
ffffffffc02003be:	f436                	sd	a3,40(sp)
ffffffffc02003c0:	f83a                	sd	a4,48(sp)
ffffffffc02003c2:	fc3e                	sd	a5,56(sp)
ffffffffc02003c4:	e0c2                	sd	a6,64(sp)
ffffffffc02003c6:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003c8:	02031c63          	bnez	t1,ffffffffc0200400 <__panic+0x54>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003cc:	4785                	li	a5,1
ffffffffc02003ce:	8432                	mv	s0,a2
ffffffffc02003d0:	00006717          	auipc	a4,0x6
ffffffffc02003d4:	04f72423          	sw	a5,72(a4) # ffffffffc0206418 <is_panic>

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003d8:	862e                	mv	a2,a1
    va_start(ap, fmt);
ffffffffc02003da:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003dc:	85aa                	mv	a1,a0
ffffffffc02003de:	00001517          	auipc	a0,0x1
ffffffffc02003e2:	71250513          	addi	a0,a0,1810 # ffffffffc0201af0 <commands+0x180>
    va_start(ap, fmt);
ffffffffc02003e6:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003e8:	ccfff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02003ec:	65a2                	ld	a1,8(sp)
ffffffffc02003ee:	8522                	mv	a0,s0
ffffffffc02003f0:	ca7ff0ef          	jal	ra,ffffffffc0200096 <vcprintf>
    cprintf("\n");
ffffffffc02003f4:	00002517          	auipc	a0,0x2
ffffffffc02003f8:	cb450513          	addi	a0,a0,-844 # ffffffffc02020a8 <commands+0x738>
ffffffffc02003fc:	cbbff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200400:	064000ef          	jal	ra,ffffffffc0200464 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200404:	4501                	li	a0,0
ffffffffc0200406:	e65ff0ef          	jal	ra,ffffffffc020026a <kmonitor>
ffffffffc020040a:	bfed                	j	ffffffffc0200404 <__panic+0x58>

ffffffffc020040c <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc020040c:	1141                	addi	sp,sp,-16
ffffffffc020040e:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc0200410:	02000793          	li	a5,32
ffffffffc0200414:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200418:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020041c:	67e1                	lui	a5,0x18
ffffffffc020041e:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0xffffffffc01e7960>
ffffffffc0200422:	953e                	add	a0,a0,a5
ffffffffc0200424:	356010ef          	jal	ra,ffffffffc020177a <sbi_set_timer>
}
ffffffffc0200428:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc020042a:	00006797          	auipc	a5,0x6
ffffffffc020042e:	0007bb23          	sd	zero,22(a5) # ffffffffc0206440 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200432:	00001517          	auipc	a0,0x1
ffffffffc0200436:	6de50513          	addi	a0,a0,1758 # ffffffffc0201b10 <commands+0x1a0>
}
ffffffffc020043a:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc020043c:	c7bff06f          	j	ffffffffc02000b6 <cprintf>

ffffffffc0200440 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200440:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200444:	67e1                	lui	a5,0x18
ffffffffc0200446:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0xffffffffc01e7960>
ffffffffc020044a:	953e                	add	a0,a0,a5
ffffffffc020044c:	32e0106f          	j	ffffffffc020177a <sbi_set_timer>

ffffffffc0200450 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200450:	8082                	ret

ffffffffc0200452 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200452:	0ff57513          	andi	a0,a0,255
ffffffffc0200456:	3080106f          	j	ffffffffc020175e <sbi_console_putchar>

ffffffffc020045a <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc020045a:	33c0106f          	j	ffffffffc0201796 <sbi_console_getchar>

ffffffffc020045e <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc020045e:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200462:	8082                	ret

ffffffffc0200464 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200464:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200468:	8082                	ret

ffffffffc020046a <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020046a:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc020046e:	00000797          	auipc	a5,0x0
ffffffffc0200472:	33278793          	addi	a5,a5,818 # ffffffffc02007a0 <__alltraps>
ffffffffc0200476:	10579073          	csrw	stvec,a5
}
ffffffffc020047a:	8082                	ret

ffffffffc020047c <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020047c:	610c                	ld	a1,0(a0)
{
ffffffffc020047e:	1141                	addi	sp,sp,-16
ffffffffc0200480:	e022                	sd	s0,0(sp)
ffffffffc0200482:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200484:	00001517          	auipc	a0,0x1
ffffffffc0200488:	7a450513          	addi	a0,a0,1956 # ffffffffc0201c28 <commands+0x2b8>
{
ffffffffc020048c:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020048e:	c29ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200492:	640c                	ld	a1,8(s0)
ffffffffc0200494:	00001517          	auipc	a0,0x1
ffffffffc0200498:	7ac50513          	addi	a0,a0,1964 # ffffffffc0201c40 <commands+0x2d0>
ffffffffc020049c:	c1bff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02004a0:	680c                	ld	a1,16(s0)
ffffffffc02004a2:	00001517          	auipc	a0,0x1
ffffffffc02004a6:	7b650513          	addi	a0,a0,1974 # ffffffffc0201c58 <commands+0x2e8>
ffffffffc02004aa:	c0dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02004ae:	6c0c                	ld	a1,24(s0)
ffffffffc02004b0:	00001517          	auipc	a0,0x1
ffffffffc02004b4:	7c050513          	addi	a0,a0,1984 # ffffffffc0201c70 <commands+0x300>
ffffffffc02004b8:	bffff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02004bc:	700c                	ld	a1,32(s0)
ffffffffc02004be:	00001517          	auipc	a0,0x1
ffffffffc02004c2:	7ca50513          	addi	a0,a0,1994 # ffffffffc0201c88 <commands+0x318>
ffffffffc02004c6:	bf1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02004ca:	740c                	ld	a1,40(s0)
ffffffffc02004cc:	00001517          	auipc	a0,0x1
ffffffffc02004d0:	7d450513          	addi	a0,a0,2004 # ffffffffc0201ca0 <commands+0x330>
ffffffffc02004d4:	be3ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02004d8:	780c                	ld	a1,48(s0)
ffffffffc02004da:	00001517          	auipc	a0,0x1
ffffffffc02004de:	7de50513          	addi	a0,a0,2014 # ffffffffc0201cb8 <commands+0x348>
ffffffffc02004e2:	bd5ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02004e6:	7c0c                	ld	a1,56(s0)
ffffffffc02004e8:	00001517          	auipc	a0,0x1
ffffffffc02004ec:	7e850513          	addi	a0,a0,2024 # ffffffffc0201cd0 <commands+0x360>
ffffffffc02004f0:	bc7ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02004f4:	602c                	ld	a1,64(s0)
ffffffffc02004f6:	00001517          	auipc	a0,0x1
ffffffffc02004fa:	7f250513          	addi	a0,a0,2034 # ffffffffc0201ce8 <commands+0x378>
ffffffffc02004fe:	bb9ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200502:	642c                	ld	a1,72(s0)
ffffffffc0200504:	00001517          	auipc	a0,0x1
ffffffffc0200508:	7fc50513          	addi	a0,a0,2044 # ffffffffc0201d00 <commands+0x390>
ffffffffc020050c:	babff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200510:	682c                	ld	a1,80(s0)
ffffffffc0200512:	00002517          	auipc	a0,0x2
ffffffffc0200516:	80650513          	addi	a0,a0,-2042 # ffffffffc0201d18 <commands+0x3a8>
ffffffffc020051a:	b9dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc020051e:	6c2c                	ld	a1,88(s0)
ffffffffc0200520:	00002517          	auipc	a0,0x2
ffffffffc0200524:	81050513          	addi	a0,a0,-2032 # ffffffffc0201d30 <commands+0x3c0>
ffffffffc0200528:	b8fff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc020052c:	702c                	ld	a1,96(s0)
ffffffffc020052e:	00002517          	auipc	a0,0x2
ffffffffc0200532:	81a50513          	addi	a0,a0,-2022 # ffffffffc0201d48 <commands+0x3d8>
ffffffffc0200536:	b81ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020053a:	742c                	ld	a1,104(s0)
ffffffffc020053c:	00002517          	auipc	a0,0x2
ffffffffc0200540:	82450513          	addi	a0,a0,-2012 # ffffffffc0201d60 <commands+0x3f0>
ffffffffc0200544:	b73ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200548:	782c                	ld	a1,112(s0)
ffffffffc020054a:	00002517          	auipc	a0,0x2
ffffffffc020054e:	82e50513          	addi	a0,a0,-2002 # ffffffffc0201d78 <commands+0x408>
ffffffffc0200552:	b65ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200556:	7c2c                	ld	a1,120(s0)
ffffffffc0200558:	00002517          	auipc	a0,0x2
ffffffffc020055c:	83850513          	addi	a0,a0,-1992 # ffffffffc0201d90 <commands+0x420>
ffffffffc0200560:	b57ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200564:	604c                	ld	a1,128(s0)
ffffffffc0200566:	00002517          	auipc	a0,0x2
ffffffffc020056a:	84250513          	addi	a0,a0,-1982 # ffffffffc0201da8 <commands+0x438>
ffffffffc020056e:	b49ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200572:	644c                	ld	a1,136(s0)
ffffffffc0200574:	00002517          	auipc	a0,0x2
ffffffffc0200578:	84c50513          	addi	a0,a0,-1972 # ffffffffc0201dc0 <commands+0x450>
ffffffffc020057c:	b3bff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200580:	684c                	ld	a1,144(s0)
ffffffffc0200582:	00002517          	auipc	a0,0x2
ffffffffc0200586:	85650513          	addi	a0,a0,-1962 # ffffffffc0201dd8 <commands+0x468>
ffffffffc020058a:	b2dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020058e:	6c4c                	ld	a1,152(s0)
ffffffffc0200590:	00002517          	auipc	a0,0x2
ffffffffc0200594:	86050513          	addi	a0,a0,-1952 # ffffffffc0201df0 <commands+0x480>
ffffffffc0200598:	b1fff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020059c:	704c                	ld	a1,160(s0)
ffffffffc020059e:	00002517          	auipc	a0,0x2
ffffffffc02005a2:	86a50513          	addi	a0,a0,-1942 # ffffffffc0201e08 <commands+0x498>
ffffffffc02005a6:	b11ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02005aa:	744c                	ld	a1,168(s0)
ffffffffc02005ac:	00002517          	auipc	a0,0x2
ffffffffc02005b0:	87450513          	addi	a0,a0,-1932 # ffffffffc0201e20 <commands+0x4b0>
ffffffffc02005b4:	b03ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02005b8:	784c                	ld	a1,176(s0)
ffffffffc02005ba:	00002517          	auipc	a0,0x2
ffffffffc02005be:	87e50513          	addi	a0,a0,-1922 # ffffffffc0201e38 <commands+0x4c8>
ffffffffc02005c2:	af5ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02005c6:	7c4c                	ld	a1,184(s0)
ffffffffc02005c8:	00002517          	auipc	a0,0x2
ffffffffc02005cc:	88850513          	addi	a0,a0,-1912 # ffffffffc0201e50 <commands+0x4e0>
ffffffffc02005d0:	ae7ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02005d4:	606c                	ld	a1,192(s0)
ffffffffc02005d6:	00002517          	auipc	a0,0x2
ffffffffc02005da:	89250513          	addi	a0,a0,-1902 # ffffffffc0201e68 <commands+0x4f8>
ffffffffc02005de:	ad9ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02005e2:	646c                	ld	a1,200(s0)
ffffffffc02005e4:	00002517          	auipc	a0,0x2
ffffffffc02005e8:	89c50513          	addi	a0,a0,-1892 # ffffffffc0201e80 <commands+0x510>
ffffffffc02005ec:	acbff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02005f0:	686c                	ld	a1,208(s0)
ffffffffc02005f2:	00002517          	auipc	a0,0x2
ffffffffc02005f6:	8a650513          	addi	a0,a0,-1882 # ffffffffc0201e98 <commands+0x528>
ffffffffc02005fa:	abdff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02005fe:	6c6c                	ld	a1,216(s0)
ffffffffc0200600:	00002517          	auipc	a0,0x2
ffffffffc0200604:	8b050513          	addi	a0,a0,-1872 # ffffffffc0201eb0 <commands+0x540>
ffffffffc0200608:	aafff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc020060c:	706c                	ld	a1,224(s0)
ffffffffc020060e:	00002517          	auipc	a0,0x2
ffffffffc0200612:	8ba50513          	addi	a0,a0,-1862 # ffffffffc0201ec8 <commands+0x558>
ffffffffc0200616:	aa1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc020061a:	746c                	ld	a1,232(s0)
ffffffffc020061c:	00002517          	auipc	a0,0x2
ffffffffc0200620:	8c450513          	addi	a0,a0,-1852 # ffffffffc0201ee0 <commands+0x570>
ffffffffc0200624:	a93ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200628:	786c                	ld	a1,240(s0)
ffffffffc020062a:	00002517          	auipc	a0,0x2
ffffffffc020062e:	8ce50513          	addi	a0,a0,-1842 # ffffffffc0201ef8 <commands+0x588>
ffffffffc0200632:	a85ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200636:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200638:	6402                	ld	s0,0(sp)
ffffffffc020063a:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020063c:	00002517          	auipc	a0,0x2
ffffffffc0200640:	8d450513          	addi	a0,a0,-1836 # ffffffffc0201f10 <commands+0x5a0>
}
ffffffffc0200644:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200646:	a71ff06f          	j	ffffffffc02000b6 <cprintf>

ffffffffc020064a <print_trapframe>:
{
ffffffffc020064a:	1141                	addi	sp,sp,-16
ffffffffc020064c:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020064e:	85aa                	mv	a1,a0
{
ffffffffc0200650:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200652:	00002517          	auipc	a0,0x2
ffffffffc0200656:	8d650513          	addi	a0,a0,-1834 # ffffffffc0201f28 <commands+0x5b8>
{
ffffffffc020065a:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020065c:	a5bff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200660:	8522                	mv	a0,s0
ffffffffc0200662:	e1bff0ef          	jal	ra,ffffffffc020047c <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200666:	10043583          	ld	a1,256(s0)
ffffffffc020066a:	00002517          	auipc	a0,0x2
ffffffffc020066e:	8d650513          	addi	a0,a0,-1834 # ffffffffc0201f40 <commands+0x5d0>
ffffffffc0200672:	a45ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200676:	10843583          	ld	a1,264(s0)
ffffffffc020067a:	00002517          	auipc	a0,0x2
ffffffffc020067e:	8de50513          	addi	a0,a0,-1826 # ffffffffc0201f58 <commands+0x5e8>
ffffffffc0200682:	a35ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200686:	11043583          	ld	a1,272(s0)
ffffffffc020068a:	00002517          	auipc	a0,0x2
ffffffffc020068e:	8e650513          	addi	a0,a0,-1818 # ffffffffc0201f70 <commands+0x600>
ffffffffc0200692:	a25ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200696:	11843583          	ld	a1,280(s0)
}
ffffffffc020069a:	6402                	ld	s0,0(sp)
ffffffffc020069c:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020069e:	00002517          	auipc	a0,0x2
ffffffffc02006a2:	8ea50513          	addi	a0,a0,-1814 # ffffffffc0201f88 <commands+0x618>
}
ffffffffc02006a6:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02006a8:	a0fff06f          	j	ffffffffc02000b6 <cprintf>

ffffffffc02006ac <interrupt_handler>:

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02006ac:	11853783          	ld	a5,280(a0)
ffffffffc02006b0:	577d                	li	a4,-1
ffffffffc02006b2:	8305                	srli	a4,a4,0x1
ffffffffc02006b4:	8ff9                	and	a5,a5,a4
    switch (cause)
ffffffffc02006b6:	472d                	li	a4,11
ffffffffc02006b8:	08f76763          	bltu	a4,a5,ffffffffc0200746 <interrupt_handler+0x9a>
ffffffffc02006bc:	00001717          	auipc	a4,0x1
ffffffffc02006c0:	47070713          	addi	a4,a4,1136 # ffffffffc0201b2c <commands+0x1bc>
ffffffffc02006c4:	078a                	slli	a5,a5,0x2
ffffffffc02006c6:	97ba                	add	a5,a5,a4
ffffffffc02006c8:	439c                	lw	a5,0(a5)
ffffffffc02006ca:	97ba                	add	a5,a5,a4
ffffffffc02006cc:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc02006ce:	00001517          	auipc	a0,0x1
ffffffffc02006d2:	4f250513          	addi	a0,a0,1266 # ffffffffc0201bc0 <commands+0x250>
ffffffffc02006d6:	9e1ff06f          	j	ffffffffc02000b6 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc02006da:	00001517          	auipc	a0,0x1
ffffffffc02006de:	4c650513          	addi	a0,a0,1222 # ffffffffc0201ba0 <commands+0x230>
ffffffffc02006e2:	9d5ff06f          	j	ffffffffc02000b6 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc02006e6:	00001517          	auipc	a0,0x1
ffffffffc02006ea:	47a50513          	addi	a0,a0,1146 # ffffffffc0201b60 <commands+0x1f0>
ffffffffc02006ee:	9c9ff06f          	j	ffffffffc02000b6 <cprintf>
        break;
    case IRQ_U_TIMER:
        cprintf("User Timer interrupt\n");
ffffffffc02006f2:	00001517          	auipc	a0,0x1
ffffffffc02006f6:	4ee50513          	addi	a0,a0,1262 # ffffffffc0201be0 <commands+0x270>
ffffffffc02006fa:	9bdff06f          	j	ffffffffc02000b6 <cprintf>
{
ffffffffc02006fe:	1141                	addi	sp,sp,-16
ffffffffc0200700:	e406                	sd	ra,8(sp)
ffffffffc0200702:	e022                	sd	s0,0(sp)
        // read-only." -- privileged spec1.9.1, 4.1.4, p59
        // In fact, Call sbi_set_timer will clear STIP, or you can clear it
        // directly.
        // cprintf("Supervisor timer interrupt\n");
        // clear_csr(sip, SIP_STIP);
        clock_set_next_event();
ffffffffc0200704:	d3dff0ef          	jal	ra,ffffffffc0200440 <clock_set_next_event>
        ticks++;
ffffffffc0200708:	00006717          	auipc	a4,0x6
ffffffffc020070c:	d3870713          	addi	a4,a4,-712 # ffffffffc0206440 <ticks>
ffffffffc0200710:	631c                	ld	a5,0(a4)
        if (ticks == 100)
ffffffffc0200712:	06400693          	li	a3,100
        ticks++;
ffffffffc0200716:	0785                	addi	a5,a5,1
ffffffffc0200718:	00006617          	auipc	a2,0x6
ffffffffc020071c:	d2f63423          	sd	a5,-728(a2) # ffffffffc0206440 <ticks>
        if (ticks == 100)
ffffffffc0200720:	631c                	ld	a5,0(a4)
ffffffffc0200722:	02d78463          	beq	a5,a3,ffffffffc020074a <interrupt_handler+0x9e>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200726:	60a2                	ld	ra,8(sp)
ffffffffc0200728:	6402                	ld	s0,0(sp)
ffffffffc020072a:	0141                	addi	sp,sp,16
ffffffffc020072c:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc020072e:	00001517          	auipc	a0,0x1
ffffffffc0200732:	4da50513          	addi	a0,a0,1242 # ffffffffc0201c08 <commands+0x298>
ffffffffc0200736:	981ff06f          	j	ffffffffc02000b6 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc020073a:	00001517          	auipc	a0,0x1
ffffffffc020073e:	44650513          	addi	a0,a0,1094 # ffffffffc0201b80 <commands+0x210>
ffffffffc0200742:	975ff06f          	j	ffffffffc02000b6 <cprintf>
        print_trapframe(tf);
ffffffffc0200746:	f05ff06f          	j	ffffffffc020064a <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc020074a:	06400593          	li	a1,100
ffffffffc020074e:	00001517          	auipc	a0,0x1
ffffffffc0200752:	4aa50513          	addi	a0,a0,1194 # ffffffffc0201bf8 <commands+0x288>
            ticks = 0;
ffffffffc0200756:	00006797          	auipc	a5,0x6
ffffffffc020075a:	ce07b523          	sd	zero,-790(a5) # ffffffffc0206440 <ticks>
            if (num == 10)
ffffffffc020075e:	00006417          	auipc	s0,0x6
ffffffffc0200762:	cc240413          	addi	s0,s0,-830 # ffffffffc0206420 <num>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200766:	951ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
            if (num == 10)
ffffffffc020076a:	6018                	ld	a4,0(s0)
ffffffffc020076c:	47a9                	li	a5,10
ffffffffc020076e:	00f70963          	beq	a4,a5,ffffffffc0200780 <interrupt_handler+0xd4>
            num++;
ffffffffc0200772:	601c                	ld	a5,0(s0)
ffffffffc0200774:	0785                	addi	a5,a5,1
ffffffffc0200776:	00006717          	auipc	a4,0x6
ffffffffc020077a:	caf73523          	sd	a5,-854(a4) # ffffffffc0206420 <num>
ffffffffc020077e:	b765                	j	ffffffffc0200726 <interrupt_handler+0x7a>
                sbi_shutdown();
ffffffffc0200780:	034010ef          	jal	ra,ffffffffc02017b4 <sbi_shutdown>
ffffffffc0200784:	b7fd                	j	ffffffffc0200772 <interrupt_handler+0xc6>

ffffffffc0200786 <trap>:
    }
}

static inline void trap_dispatch(struct trapframe *tf)
{
    if ((intptr_t)tf->cause < 0)
ffffffffc0200786:	11853783          	ld	a5,280(a0)
ffffffffc020078a:	0007c863          	bltz	a5,ffffffffc020079a <trap+0x14>
    switch (tf->cause)
ffffffffc020078e:	472d                	li	a4,11
ffffffffc0200790:	00f76363          	bltu	a4,a5,ffffffffc0200796 <trap+0x10>
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
}
ffffffffc0200794:	8082                	ret
        print_trapframe(tf);
ffffffffc0200796:	eb5ff06f          	j	ffffffffc020064a <print_trapframe>
        interrupt_handler(tf);
ffffffffc020079a:	f13ff06f          	j	ffffffffc02006ac <interrupt_handler>
	...

ffffffffc02007a0 <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc02007a0:	14011073          	csrw	sscratch,sp
ffffffffc02007a4:	712d                	addi	sp,sp,-288
ffffffffc02007a6:	e002                	sd	zero,0(sp)
ffffffffc02007a8:	e406                	sd	ra,8(sp)
ffffffffc02007aa:	ec0e                	sd	gp,24(sp)
ffffffffc02007ac:	f012                	sd	tp,32(sp)
ffffffffc02007ae:	f416                	sd	t0,40(sp)
ffffffffc02007b0:	f81a                	sd	t1,48(sp)
ffffffffc02007b2:	fc1e                	sd	t2,56(sp)
ffffffffc02007b4:	e0a2                	sd	s0,64(sp)
ffffffffc02007b6:	e4a6                	sd	s1,72(sp)
ffffffffc02007b8:	e8aa                	sd	a0,80(sp)
ffffffffc02007ba:	ecae                	sd	a1,88(sp)
ffffffffc02007bc:	f0b2                	sd	a2,96(sp)
ffffffffc02007be:	f4b6                	sd	a3,104(sp)
ffffffffc02007c0:	f8ba                	sd	a4,112(sp)
ffffffffc02007c2:	fcbe                	sd	a5,120(sp)
ffffffffc02007c4:	e142                	sd	a6,128(sp)
ffffffffc02007c6:	e546                	sd	a7,136(sp)
ffffffffc02007c8:	e94a                	sd	s2,144(sp)
ffffffffc02007ca:	ed4e                	sd	s3,152(sp)
ffffffffc02007cc:	f152                	sd	s4,160(sp)
ffffffffc02007ce:	f556                	sd	s5,168(sp)
ffffffffc02007d0:	f95a                	sd	s6,176(sp)
ffffffffc02007d2:	fd5e                	sd	s7,184(sp)
ffffffffc02007d4:	e1e2                	sd	s8,192(sp)
ffffffffc02007d6:	e5e6                	sd	s9,200(sp)
ffffffffc02007d8:	e9ea                	sd	s10,208(sp)
ffffffffc02007da:	edee                	sd	s11,216(sp)
ffffffffc02007dc:	f1f2                	sd	t3,224(sp)
ffffffffc02007de:	f5f6                	sd	t4,232(sp)
ffffffffc02007e0:	f9fa                	sd	t5,240(sp)
ffffffffc02007e2:	fdfe                	sd	t6,248(sp)
ffffffffc02007e4:	14001473          	csrrw	s0,sscratch,zero
ffffffffc02007e8:	100024f3          	csrr	s1,sstatus
ffffffffc02007ec:	14102973          	csrr	s2,sepc
ffffffffc02007f0:	143029f3          	csrr	s3,stval
ffffffffc02007f4:	14202a73          	csrr	s4,scause
ffffffffc02007f8:	e822                	sd	s0,16(sp)
ffffffffc02007fa:	e226                	sd	s1,256(sp)
ffffffffc02007fc:	e64a                	sd	s2,264(sp)
ffffffffc02007fe:	ea4e                	sd	s3,272(sp)
ffffffffc0200800:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200802:	850a                	mv	a0,sp
    jal trap
ffffffffc0200804:	f83ff0ef          	jal	ra,ffffffffc0200786 <trap>

ffffffffc0200808 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200808:	6492                	ld	s1,256(sp)
ffffffffc020080a:	6932                	ld	s2,264(sp)
ffffffffc020080c:	10049073          	csrw	sstatus,s1
ffffffffc0200810:	14191073          	csrw	sepc,s2
ffffffffc0200814:	60a2                	ld	ra,8(sp)
ffffffffc0200816:	61e2                	ld	gp,24(sp)
ffffffffc0200818:	7202                	ld	tp,32(sp)
ffffffffc020081a:	72a2                	ld	t0,40(sp)
ffffffffc020081c:	7342                	ld	t1,48(sp)
ffffffffc020081e:	73e2                	ld	t2,56(sp)
ffffffffc0200820:	6406                	ld	s0,64(sp)
ffffffffc0200822:	64a6                	ld	s1,72(sp)
ffffffffc0200824:	6546                	ld	a0,80(sp)
ffffffffc0200826:	65e6                	ld	a1,88(sp)
ffffffffc0200828:	7606                	ld	a2,96(sp)
ffffffffc020082a:	76a6                	ld	a3,104(sp)
ffffffffc020082c:	7746                	ld	a4,112(sp)
ffffffffc020082e:	77e6                	ld	a5,120(sp)
ffffffffc0200830:	680a                	ld	a6,128(sp)
ffffffffc0200832:	68aa                	ld	a7,136(sp)
ffffffffc0200834:	694a                	ld	s2,144(sp)
ffffffffc0200836:	69ea                	ld	s3,152(sp)
ffffffffc0200838:	7a0a                	ld	s4,160(sp)
ffffffffc020083a:	7aaa                	ld	s5,168(sp)
ffffffffc020083c:	7b4a                	ld	s6,176(sp)
ffffffffc020083e:	7bea                	ld	s7,184(sp)
ffffffffc0200840:	6c0e                	ld	s8,192(sp)
ffffffffc0200842:	6cae                	ld	s9,200(sp)
ffffffffc0200844:	6d4e                	ld	s10,208(sp)
ffffffffc0200846:	6dee                	ld	s11,216(sp)
ffffffffc0200848:	7e0e                	ld	t3,224(sp)
ffffffffc020084a:	7eae                	ld	t4,232(sp)
ffffffffc020084c:	7f4e                	ld	t5,240(sp)
ffffffffc020084e:	7fee                	ld	t6,248(sp)
ffffffffc0200850:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200852:	10200073          	sret

ffffffffc0200856 <buddy_system_init>:

static void
buddy_system_init(void)
{
    // 初始化伙伴堆链表数组中的每个free_list头
    for (int i = 0; i < MAX_BUDDY_ORDER + 1; i++)
ffffffffc0200856:	00006797          	auipc	a5,0x6
ffffffffc020085a:	bfa78793          	addi	a5,a5,-1030 # ffffffffc0206450 <buddy_s+0x8>
ffffffffc020085e:	00006717          	auipc	a4,0x6
ffffffffc0200862:	ce270713          	addi	a4,a4,-798 # ffffffffc0206540 <buddy_s+0xf8>
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm)
{
    elm->prev = elm->next = elm;
ffffffffc0200866:	e79c                	sd	a5,8(a5)
ffffffffc0200868:	e39c                	sd	a5,0(a5)
ffffffffc020086a:	07c1                	addi	a5,a5,16
ffffffffc020086c:	fee79de3          	bne	a5,a4,ffffffffc0200866 <buddy_system_init+0x10>
    {
        list_init(buddy_array + i);
    }
    max_order = 0;
ffffffffc0200870:	00006797          	auipc	a5,0x6
ffffffffc0200874:	bc07ac23          	sw	zero,-1064(a5) # ffffffffc0206448 <buddy_s>
    nr_free = 0;
ffffffffc0200878:	00006797          	auipc	a5,0x6
ffffffffc020087c:	cc07a423          	sw	zero,-824(a5) # ffffffffc0206540 <buddy_s+0xf8>
    return;
}
ffffffffc0200880:	8082                	ret

ffffffffc0200882 <buddy_system_nr_free_pages>:

static size_t
buddy_system_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0200882:	00006517          	auipc	a0,0x6
ffffffffc0200886:	cbe56503          	lwu	a0,-834(a0) # ffffffffc0206540 <buddy_s+0xf8>
ffffffffc020088a:	8082                	ret

ffffffffc020088c <buddy_system_init_memmap>:
{
ffffffffc020088c:	1141                	addi	sp,sp,-16
ffffffffc020088e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200890:	c1e9                	beqz	a1,ffffffffc0200952 <buddy_system_init_memmap+0xc6>
    if (n & (n - 1))
ffffffffc0200892:	fff58793          	addi	a5,a1,-1
ffffffffc0200896:	8fed                	and	a5,a5,a1
ffffffffc0200898:	cb99                	beqz	a5,ffffffffc02008ae <buddy_system_init_memmap+0x22>
    size_t res = 1;
ffffffffc020089a:	4785                	li	a5,1
ffffffffc020089c:	a011                	j	ffffffffc02008a0 <buddy_system_init_memmap+0x14>
            res = res << 1;
ffffffffc020089e:	87ba                	mv	a5,a4
            n = n >> 1;
ffffffffc02008a0:	8185                	srli	a1,a1,0x1
            res = res << 1;
ffffffffc02008a2:	00179713          	slli	a4,a5,0x1
        while (n)
ffffffffc02008a6:	fde5                	bnez	a1,ffffffffc020089e <buddy_system_init_memmap+0x12>
        return res >> 1;
ffffffffc02008a8:	55fd                	li	a1,-1
ffffffffc02008aa:	8185                	srli	a1,a1,0x1
ffffffffc02008ac:	8dfd                	and	a1,a1,a5
    while (n >> 1)
ffffffffc02008ae:	0015d793          	srli	a5,a1,0x1
    unsigned int order = 0;
ffffffffc02008b2:	4601                	li	a2,0
    while (n >> 1)
ffffffffc02008b4:	c781                	beqz	a5,ffffffffc02008bc <buddy_system_init_memmap+0x30>
ffffffffc02008b6:	8385                	srli	a5,a5,0x1
        order++;
ffffffffc02008b8:	2605                	addiw	a2,a2,1
    while (n >> 1)
ffffffffc02008ba:	fff5                	bnez	a5,ffffffffc02008b6 <buddy_system_init_memmap+0x2a>
    for (; p != base + pnum; p++)
ffffffffc02008bc:	00259693          	slli	a3,a1,0x2
ffffffffc02008c0:	96ae                	add	a3,a3,a1
ffffffffc02008c2:	068e                	slli	a3,a3,0x3
ffffffffc02008c4:	96aa                	add	a3,a3,a0
ffffffffc02008c6:	02d50563          	beq	a0,a3,ffffffffc02008f0 <buddy_system_init_memmap+0x64>
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr)
{
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02008ca:	651c                	ld	a5,8(a0)
        assert(PageReserved(p));
ffffffffc02008cc:	8b85                	andi	a5,a5,1
ffffffffc02008ce:	c3b5                	beqz	a5,ffffffffc0200932 <buddy_system_init_memmap+0xa6>
ffffffffc02008d0:	87aa                	mv	a5,a0
        p->property = -1; // 全部初始化为非头页
ffffffffc02008d2:	587d                	li	a6,-1
ffffffffc02008d4:	a021                	j	ffffffffc02008dc <buddy_system_init_memmap+0x50>
ffffffffc02008d6:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc02008d8:	8b05                	andi	a4,a4,1
ffffffffc02008da:	cf21                	beqz	a4,ffffffffc0200932 <buddy_system_init_memmap+0xa6>
        p->flags = 0;
ffffffffc02008dc:	0007b423          	sd	zero,8(a5)
        p->property = -1; // 全部初始化为非头页
ffffffffc02008e0:	0107a823          	sw	a6,16(a5)
    return page2ppn(page) << PGSHIFT;
}

static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02008e4:	0007a023          	sw	zero,0(a5)
    for (; p != base + pnum; p++)
ffffffffc02008e8:	02878793          	addi	a5,a5,40
ffffffffc02008ec:	fed795e3          	bne	a5,a3,ffffffffc02008d6 <buddy_system_init_memmap+0x4a>
 * is already in the list.
 * */
static inline void
list_add_after(list_entry_t *listelm, list_entry_t *elm)
{
    __list_add(elm, listelm, listelm->next);
ffffffffc02008f0:	02061793          	slli	a5,a2,0x20
ffffffffc02008f4:	9381                	srli	a5,a5,0x20
    max_order = order;
ffffffffc02008f6:	00006697          	auipc	a3,0x6
ffffffffc02008fa:	b5268693          	addi	a3,a3,-1198 # ffffffffc0206448 <buddy_s>
ffffffffc02008fe:	0792                	slli	a5,a5,0x4
ffffffffc0200900:	00f68833          	add	a6,a3,a5
ffffffffc0200904:	01083703          	ld	a4,16(a6)
    nr_free = pnum;
ffffffffc0200908:	00006897          	auipc	a7,0x6
ffffffffc020090c:	c2b8ac23          	sw	a1,-968(a7) # ffffffffc0206540 <buddy_s+0xf8>
    max_order = order;
ffffffffc0200910:	00006897          	auipc	a7,0x6
ffffffffc0200914:	b2c8ac23          	sw	a2,-1224(a7) # ffffffffc0206448 <buddy_s>
    list_add(&(buddy_array[max_order]), &(base->page_link)); // 将第一页base插入数组的最后一个链表，作为初始化的最大块的头页
ffffffffc0200918:	01850593          	addi	a1,a0,24
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next)
{
    // prev: 新节点 elm 的前一个节点。
    // next: 新节点 elm 的后一个节点。
    prev->next = next->prev = elm;
ffffffffc020091c:	e30c                	sd	a1,0(a4)
}
ffffffffc020091e:	60a2                	ld	ra,8(sp)
    list_add(&(buddy_array[max_order]), &(base->page_link)); // 将第一页base插入数组的最后一个链表，作为初始化的最大块的头页
ffffffffc0200920:	07a1                	addi	a5,a5,8
ffffffffc0200922:	00b83823          	sd	a1,16(a6)
ffffffffc0200926:	97b6                	add	a5,a5,a3
    elm->next = next;
ffffffffc0200928:	f118                	sd	a4,32(a0)
    elm->prev = prev;
ffffffffc020092a:	ed1c                	sd	a5,24(a0)
    base->property = max_order; // 将第一页base的property设为最大块的2幂
ffffffffc020092c:	c910                	sw	a2,16(a0)
}
ffffffffc020092e:	0141                	addi	sp,sp,16
ffffffffc0200930:	8082                	ret
        assert(PageReserved(p));
ffffffffc0200932:	00002697          	auipc	a3,0x2
ffffffffc0200936:	9be68693          	addi	a3,a3,-1602 # ffffffffc02022f0 <commands+0x980>
ffffffffc020093a:	00002617          	auipc	a2,0x2
ffffffffc020093e:	97e60613          	addi	a2,a2,-1666 # ffffffffc02022b8 <commands+0x948>
ffffffffc0200942:	0d600593          	li	a1,214
ffffffffc0200946:	00002517          	auipc	a0,0x2
ffffffffc020094a:	98a50513          	addi	a0,a0,-1654 # ffffffffc02022d0 <commands+0x960>
ffffffffc020094e:	a5fff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(n > 0);
ffffffffc0200952:	00002697          	auipc	a3,0x2
ffffffffc0200956:	95e68693          	addi	a3,a3,-1698 # ffffffffc02022b0 <commands+0x940>
ffffffffc020095a:	00002617          	auipc	a2,0x2
ffffffffc020095e:	95e60613          	addi	a2,a2,-1698 # ffffffffc02022b8 <commands+0x948>
ffffffffc0200962:	0cd00593          	li	a1,205
ffffffffc0200966:	00002517          	auipc	a0,0x2
ffffffffc020096a:	96a50513          	addi	a0,a0,-1686 # ffffffffc02022d0 <commands+0x960>
ffffffffc020096e:	a3fff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200972 <buddy_system_alloc_pages>:
{
ffffffffc0200972:	7139                	addi	sp,sp,-64
ffffffffc0200974:	fc06                	sd	ra,56(sp)
ffffffffc0200976:	f822                	sd	s0,48(sp)
ffffffffc0200978:	f426                	sd	s1,40(sp)
ffffffffc020097a:	f04a                	sd	s2,32(sp)
ffffffffc020097c:	ec4e                	sd	s3,24(sp)
ffffffffc020097e:	e852                	sd	s4,16(sp)
ffffffffc0200980:	e456                	sd	s5,8(sp)
    assert(requested_pages > 0);
ffffffffc0200982:	18050663          	beqz	a0,ffffffffc0200b0e <buddy_system_alloc_pages+0x19c>
    if (requested_pages > nr_free)
ffffffffc0200986:	00006797          	auipc	a5,0x6
ffffffffc020098a:	bba7e783          	lwu	a5,-1094(a5) # ffffffffc0206540 <buddy_s+0xf8>
ffffffffc020098e:	08a7ed63          	bltu	a5,a0,ffffffffc0200a28 <buddy_system_alloc_pages+0xb6>
    if (n & (n - 1))
ffffffffc0200992:	fff50793          	addi	a5,a0,-1
ffffffffc0200996:	8fe9                	and	a5,a5,a0
ffffffffc0200998:	12079e63          	bnez	a5,ffffffffc0200ad4 <buddy_system_alloc_pages+0x162>
    while (n >> 1)
ffffffffc020099c:	00155793          	srli	a5,a0,0x1
ffffffffc02009a0:	14078063          	beqz	a5,ffffffffc0200ae0 <buddy_system_alloc_pages+0x16e>
    unsigned int order = 0;
ffffffffc02009a4:	4e81                	li	t4,0
ffffffffc02009a6:	a011                	j	ffffffffc02009aa <buddy_system_alloc_pages+0x38>
        order++;
ffffffffc02009a8:	8eba                	mv	t4,a4
    while (n >> 1)
ffffffffc02009aa:	8385                	srli	a5,a5,0x1
        order++;
ffffffffc02009ac:	001e871b          	addiw	a4,t4,1
    while (n >> 1)
ffffffffc02009b0:	ffe5                	bnez	a5,ffffffffc02009a8 <buddy_system_alloc_pages+0x36>
ffffffffc02009b2:	2e89                	addiw	t4,t4,2
ffffffffc02009b4:	02071793          	slli	a5,a4,0x20
ffffffffc02009b8:	83f1                	srli	a5,a5,0x1c
ffffffffc02009ba:	004e9f93          	slli	t6,t4,0x4
ffffffffc02009be:	82f6                	mv	t0,t4
ffffffffc02009c0:	89f6                	mv	s3,t4
ffffffffc02009c2:	00878393          	addi	t2,a5,8
ffffffffc02009c6:	0fa1                	addi	t6,t6,8
        if (!list_empty(&(buddy_array[order_of_2])))
ffffffffc02009c8:	00006e17          	auipc	t3,0x6
ffffffffc02009cc:	a80e0e13          	addi	t3,t3,-1408 # ffffffffc0206448 <buddy_s>
            for (i = order_of_2 + 1; i <= max_order; ++i)
ffffffffc02009d0:	000e2883          	lw	a7,0(t3)
    return list->next == list;
ffffffffc02009d4:	00fe0333          	add	t1,t3,a5
ffffffffc02009d8:	01033783          	ld	a5,16(t1)
ffffffffc02009dc:	00228f13          	addi	t5,t0,2
ffffffffc02009e0:	00429413          	slli	s0,t0,0x4
ffffffffc02009e4:	0f12                	slli	t5,t5,0x4
    assert(n > 0 && n <= max_order);
ffffffffc02009e6:	02089913          	slli	s2,a7,0x20
        if (!list_empty(&(buddy_array[order_of_2])))
ffffffffc02009ea:	93f2                	add	t2,t2,t3
                if (!list_empty(&(buddy_array[i])))
ffffffffc02009ec:	9ff2                	add	t6,t6,t3
    assert(n > 0 && n <= max_order);
ffffffffc02009ee:	02095913          	srli	s2,s2,0x20
ffffffffc02009f2:	9f72                	add	t5,t5,t3
ffffffffc02009f4:	9472                	add	s0,s0,t3
ffffffffc02009f6:	2285                	addiw	t0,t0,1
    page_b = page_a + (1 << (n - 1)); // 找到a的伙伴块b
ffffffffc02009f8:	4485                	li	s1,1
        if (!list_empty(&(buddy_array[order_of_2])))
ffffffffc02009fa:	0af39a63          	bne	t2,a5,ffffffffc0200aae <buddy_system_alloc_pages+0x13c>
            for (i = order_of_2 + 1; i <= max_order; ++i)
ffffffffc02009fe:	03d8e563          	bltu	a7,t4,ffffffffc0200a28 <buddy_system_alloc_pages+0xb6>
                if (!list_empty(&(buddy_array[i])))
ffffffffc0200a02:	681c                	ld	a5,16(s0)
ffffffffc0200a04:	03f79d63          	bne	a5,t6,ffffffffc0200a3e <buddy_system_alloc_pages+0xcc>
ffffffffc0200a08:	8716                	mv	a4,t0
ffffffffc0200a0a:	87fa                	mv	a5,t5
ffffffffc0200a0c:	a811                	j	ffffffffc0200a20 <buddy_system_alloc_pages+0xae>
ffffffffc0200a0e:	6390                	ld	a2,0(a5)
ffffffffc0200a10:	ff878693          	addi	a3,a5,-8
ffffffffc0200a14:	00170593          	addi	a1,a4,1
ffffffffc0200a18:	07c1                	addi	a5,a5,16
ffffffffc0200a1a:	02d61463          	bne	a2,a3,ffffffffc0200a42 <buddy_system_alloc_pages+0xd0>
ffffffffc0200a1e:	872e                	mv	a4,a1
ffffffffc0200a20:	0007081b          	sext.w	a6,a4
            for (i = order_of_2 + 1; i <= max_order; ++i)
ffffffffc0200a24:	ff08f5e3          	bleu	a6,a7,ffffffffc0200a0e <buddy_system_alloc_pages+0x9c>
        return NULL;
ffffffffc0200a28:	4701                	li	a4,0
}
ffffffffc0200a2a:	70e2                	ld	ra,56(sp)
ffffffffc0200a2c:	7442                	ld	s0,48(sp)
ffffffffc0200a2e:	74a2                	ld	s1,40(sp)
ffffffffc0200a30:	7902                	ld	s2,32(sp)
ffffffffc0200a32:	69e2                	ld	s3,24(sp)
ffffffffc0200a34:	6a42                	ld	s4,16(sp)
ffffffffc0200a36:	6aa2                	ld	s5,8(sp)
ffffffffc0200a38:	853a                	mv	a0,a4
ffffffffc0200a3a:	6121                	addi	sp,sp,64
ffffffffc0200a3c:	8082                	ret
                if (!list_empty(&(buddy_array[i])))
ffffffffc0200a3e:	874e                	mv	a4,s3
ffffffffc0200a40:	8876                	mv	a6,t4
    assert(n > 0 && n <= max_order);
ffffffffc0200a42:	c755                	beqz	a4,ffffffffc0200aee <buddy_system_alloc_pages+0x17c>
ffffffffc0200a44:	0ae96563          	bltu	s2,a4,ffffffffc0200aee <buddy_system_alloc_pages+0x17c>
ffffffffc0200a48:	00471793          	slli	a5,a4,0x4
ffffffffc0200a4c:	00fe06b3          	add	a3,t3,a5
ffffffffc0200a50:	6a94                	ld	a3,16(a3)
    assert(!list_empty(&(buddy_array[n])));
ffffffffc0200a52:	07a1                	addi	a5,a5,8
ffffffffc0200a54:	97f2                	add	a5,a5,t3
ffffffffc0200a56:	0cf68c63          	beq	a3,a5,ffffffffc0200b2e <buddy_system_alloc_pages+0x1bc>
    page_b = page_a + (1 << (n - 1)); // 找到a的伙伴块b
ffffffffc0200a5a:	fff7061b          	addiw	a2,a4,-1
ffffffffc0200a5e:	00c495bb          	sllw	a1,s1,a2
ffffffffc0200a62:	00259793          	slli	a5,a1,0x2
ffffffffc0200a66:	97ae                	add	a5,a5,a1
ffffffffc0200a68:	078e                	slli	a5,a5,0x3
    __list_del(listelm->prev, listelm->next);
ffffffffc0200a6a:	0006ba83          	ld	s5,0(a3)
ffffffffc0200a6e:	0086ba03          	ld	s4,8(a3)
ffffffffc0200a72:	17a1                	addi	a5,a5,-24
    page_a->property = n - 1;
ffffffffc0200a74:	fec6ac23          	sw	a2,-8(a3)
    page_b = page_a + (1 << (n - 1)); // 找到a的伙伴块b
ffffffffc0200a78:	97b6                	add	a5,a5,a3
    list_add(&(buddy_array[n - 1]), &(page_a->page_link));
ffffffffc0200a7a:	177d                	addi	a4,a4,-1
    page_b->property = n - 1;
ffffffffc0200a7c:	cb90                	sw	a2,16(a5)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200a7e:	0712                	slli	a4,a4,0x4
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next)
{
    prev->next = next;
ffffffffc0200a80:	014ab423          	sd	s4,8(s5)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200a84:	00ee05b3          	add	a1,t3,a4
    next->prev = prev;
ffffffffc0200a88:	015a3023          	sd	s5,0(s4)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200a8c:	6990                	ld	a2,16(a1)
    list_add(&(buddy_array[n - 1]), &(page_a->page_link));
ffffffffc0200a8e:	0721                	addi	a4,a4,8
    prev->next = next->prev = elm;
ffffffffc0200a90:	e994                	sd	a3,16(a1)
ffffffffc0200a92:	9772                	add	a4,a4,t3
    elm->prev = prev;
ffffffffc0200a94:	e298                	sd	a4,0(a3)
    list_add(&(page_a->page_link), &(page_b->page_link));
ffffffffc0200a96:	01878713          	addi	a4,a5,24
    prev->next = next->prev = elm;
ffffffffc0200a9a:	e218                	sd	a4,0(a2)
ffffffffc0200a9c:	e698                	sd	a4,8(a3)
    elm->next = next;
ffffffffc0200a9e:	f390                	sd	a2,32(a5)
    elm->prev = prev;
ffffffffc0200aa0:	ef94                	sd	a3,24(a5)
            if (i > max_order)
ffffffffc0200aa2:	f908e3e3          	bltu	a7,a6,ffffffffc0200a28 <buddy_system_alloc_pages+0xb6>
    return list->next == list;
ffffffffc0200aa6:	01033783          	ld	a5,16(t1)
        if (!list_empty(&(buddy_array[order_of_2])))
ffffffffc0200aaa:	f4f38ae3          	beq	t2,a5,ffffffffc02009fe <buddy_system_alloc_pages+0x8c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200aae:	6794                	ld	a3,8(a5)
ffffffffc0200ab0:	6390                	ld	a2,0(a5)
            allocated_page = le2page(list_next(&(buddy_array[order_of_2])), page_link);
ffffffffc0200ab2:	fe878713          	addi	a4,a5,-24
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200ab6:	17c1                	addi	a5,a5,-16
    prev->next = next;
ffffffffc0200ab8:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0200aba:	e290                	sd	a2,0(a3)
ffffffffc0200abc:	4689                	li	a3,2
ffffffffc0200abe:	40d7b02f          	amoor.d	zero,a3,(a5)
    if (allocated_page != NULL)
ffffffffc0200ac2:	d725                	beqz	a4,ffffffffc0200a2a <buddy_system_alloc_pages+0xb8>
        nr_free -= adjusted_pages;
ffffffffc0200ac4:	0f8e2783          	lw	a5,248(t3)
ffffffffc0200ac8:	9f89                	subw	a5,a5,a0
ffffffffc0200aca:	00006697          	auipc	a3,0x6
ffffffffc0200ace:	a6f6ab23          	sw	a5,-1418(a3) # ffffffffc0206540 <buddy_s+0xf8>
ffffffffc0200ad2:	bfa1                	j	ffffffffc0200a2a <buddy_system_alloc_pages+0xb8>
    size_t res = 1;
ffffffffc0200ad4:	4785                	li	a5,1
            n = n >> 1;
ffffffffc0200ad6:	8105                	srli	a0,a0,0x1
            res = res << 1;
ffffffffc0200ad8:	0786                	slli	a5,a5,0x1
        while (n)
ffffffffc0200ada:	fd75                	bnez	a0,ffffffffc0200ad6 <buddy_system_alloc_pages+0x164>
            res = res << 1;
ffffffffc0200adc:	853e                	mv	a0,a5
ffffffffc0200ade:	bd7d                	j	ffffffffc020099c <buddy_system_alloc_pages+0x2a>
    while (n >> 1)
ffffffffc0200ae0:	4fe1                	li	t6,24
ffffffffc0200ae2:	4285                	li	t0,1
ffffffffc0200ae4:	43a1                	li	t2,8
ffffffffc0200ae6:	4985                	li	s3,1
ffffffffc0200ae8:	4e85                	li	t4,1
ffffffffc0200aea:	4781                	li	a5,0
ffffffffc0200aec:	bdf1                	j	ffffffffc02009c8 <buddy_system_alloc_pages+0x56>
    assert(n > 0 && n <= max_order);
ffffffffc0200aee:	00001697          	auipc	a3,0x1
ffffffffc0200af2:	4ca68693          	addi	a3,a3,1226 # ffffffffc0201fb8 <commands+0x648>
ffffffffc0200af6:	00001617          	auipc	a2,0x1
ffffffffc0200afa:	7c260613          	addi	a2,a2,1986 # ffffffffc02022b8 <commands+0x948>
ffffffffc0200afe:	04a00593          	li	a1,74
ffffffffc0200b02:	00001517          	auipc	a0,0x1
ffffffffc0200b06:	7ce50513          	addi	a0,a0,1998 # ffffffffc02022d0 <commands+0x960>
ffffffffc0200b0a:	8a3ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(requested_pages > 0);
ffffffffc0200b0e:	00001697          	auipc	a3,0x1
ffffffffc0200b12:	49268693          	addi	a3,a3,1170 # ffffffffc0201fa0 <commands+0x630>
ffffffffc0200b16:	00001617          	auipc	a2,0x1
ffffffffc0200b1a:	7a260613          	addi	a2,a2,1954 # ffffffffc02022b8 <commands+0x948>
ffffffffc0200b1e:	0e700593          	li	a1,231
ffffffffc0200b22:	00001517          	auipc	a0,0x1
ffffffffc0200b26:	7ae50513          	addi	a0,a0,1966 # ffffffffc02022d0 <commands+0x960>
ffffffffc0200b2a:	883ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(!list_empty(&(buddy_array[n])));
ffffffffc0200b2e:	00001697          	auipc	a3,0x1
ffffffffc0200b32:	4a268693          	addi	a3,a3,1186 # ffffffffc0201fd0 <commands+0x660>
ffffffffc0200b36:	00001617          	auipc	a2,0x1
ffffffffc0200b3a:	78260613          	addi	a2,a2,1922 # ffffffffc02022b8 <commands+0x948>
ffffffffc0200b3e:	04b00593          	li	a1,75
ffffffffc0200b42:	00001517          	auipc	a0,0x1
ffffffffc0200b46:	78e50513          	addi	a0,a0,1934 # ffffffffc02022d0 <commands+0x960>
ffffffffc0200b4a:	863ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200b4e <show_buddy_array.constprop.3>:
    assert(left >= 0 && left <= max_order && right >= 0 && right <= max_order);
ffffffffc0200b4e:	00006797          	auipc	a5,0x6
ffffffffc0200b52:	8fa78793          	addi	a5,a5,-1798 # ffffffffc0206448 <buddy_s>
ffffffffc0200b56:	4398                	lw	a4,0(a5)
static void show_buddy_array(int left, int right) {
ffffffffc0200b58:	715d                	addi	sp,sp,-80
ffffffffc0200b5a:	e486                	sd	ra,72(sp)
ffffffffc0200b5c:	e0a2                	sd	s0,64(sp)
ffffffffc0200b5e:	fc26                	sd	s1,56(sp)
ffffffffc0200b60:	f84a                	sd	s2,48(sp)
ffffffffc0200b62:	f44e                	sd	s3,40(sp)
ffffffffc0200b64:	f052                	sd	s4,32(sp)
ffffffffc0200b66:	ec56                	sd	s5,24(sp)
ffffffffc0200b68:	e85a                	sd	s6,16(sp)
ffffffffc0200b6a:	e45e                	sd	s7,8(sp)
ffffffffc0200b6c:	e062                	sd	s8,0(sp)
    assert(left >= 0 && left <= max_order && right >= 0 && right <= max_order);
ffffffffc0200b6e:	47b5                	li	a5,13
ffffffffc0200b70:	0ee7f063          	bleu	a4,a5,ffffffffc0200c50 <show_buddy_array.constprop.3+0x102>
    cprintf("空闲块大小   |");
ffffffffc0200b74:	00002517          	auipc	a0,0x2
ffffffffc0200b78:	80c50513          	addi	a0,a0,-2036 # ffffffffc0202380 <buddy_system_pmm_manager+0x80>
ffffffffc0200b7c:	00006917          	auipc	s2,0x6
ffffffffc0200b80:	8d490913          	addi	s2,s2,-1836 # ffffffffc0206450 <buddy_s+0x8>
ffffffffc0200b84:	d32ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc0200b88:	84ca                	mv	s1,s2
    for (int i = left; i <= right; i++) {
ffffffffc0200b8a:	4981                	li	s3,0
                cprintf("%d: ", i);
ffffffffc0200b8c:	00002b17          	auipc	s6,0x2
ffffffffc0200b90:	81cb0b13          	addi	s6,s6,-2020 # ffffffffc02023a8 <buddy_system_pmm_manager+0xa8>
                size_t block_size = 1 << p->property;
ffffffffc0200b94:	4a85                	li	s5,1
                cprintf("%d|", 1 << (p->property));
ffffffffc0200b96:	00002a17          	auipc	s4,0x2
ffffffffc0200b9a:	81aa0a13          	addi	s4,s4,-2022 # ffffffffc02023b0 <buddy_system_pmm_manager+0xb0>
            cprintf("%d: 空 |");
ffffffffc0200b9e:	00001c17          	auipc	s8,0x1
ffffffffc0200ba2:	7fac0c13          	addi	s8,s8,2042 # ffffffffc0202398 <buddy_system_pmm_manager+0x98>
    for (int i = left; i <= right; i++) {
ffffffffc0200ba6:	4bbd                	li	s7,15
    return listelm->next;
ffffffffc0200ba8:	6480                	ld	s0,8(s1)
        if (list_next(le) != &buddy_array[i]) {
ffffffffc0200baa:	08940b63          	beq	s0,s1,ffffffffc0200c40 <show_buddy_array.constprop.3+0xf2>
                cprintf("%d: ", i);
ffffffffc0200bae:	85ce                	mv	a1,s3
ffffffffc0200bb0:	855a                	mv	a0,s6
ffffffffc0200bb2:	d04ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
                size_t block_size = 1 << p->property;
ffffffffc0200bb6:	ff842583          	lw	a1,-8(s0)
                cprintf("%d|", 1 << (p->property));
ffffffffc0200bba:	8552                	mv	a0,s4
ffffffffc0200bbc:	00ba95bb          	sllw	a1,s5,a1
ffffffffc0200bc0:	cf6ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc0200bc4:	6400                	ld	s0,8(s0)
            while ((le = list_next(le)) != &buddy_array[i]) {
ffffffffc0200bc6:	fe9414e3          	bne	s0,s1,ffffffffc0200bae <show_buddy_array.constprop.3+0x60>
    for (int i = left; i <= right; i++) {
ffffffffc0200bca:	2985                	addiw	s3,s3,1
ffffffffc0200bcc:	04c1                	addi	s1,s1,16
ffffffffc0200bce:	fd799de3          	bne	s3,s7,ffffffffc0200ba8 <show_buddy_array.constprop.3+0x5a>
    cprintf("\n对应的页地址 |");
ffffffffc0200bd2:	00001517          	auipc	a0,0x1
ffffffffc0200bd6:	7e650513          	addi	a0,a0,2022 # ffffffffc02023b8 <buddy_system_pmm_manager+0xb8>
ffffffffc0200bda:	cdcff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    for (int i = left; i <= right; i++) {
ffffffffc0200bde:	4981                	li	s3,0
                cprintf("%p|", p);
ffffffffc0200be0:	00001497          	auipc	s1,0x1
ffffffffc0200be4:	7f048493          	addi	s1,s1,2032 # ffffffffc02023d0 <buddy_system_pmm_manager+0xd0>
            if (i != right) {
ffffffffc0200be8:	4b39                	li	s6,14
                cprintf("空|");
ffffffffc0200bea:	00001a97          	auipc	s5,0x1
ffffffffc0200bee:	7eea8a93          	addi	s5,s5,2030 # ffffffffc02023d8 <buddy_system_pmm_manager+0xd8>
    for (int i = left; i <= right; i++) {
ffffffffc0200bf2:	4a3d                	li	s4,15
ffffffffc0200bf4:	00893403          	ld	s0,8(s2)
        if (list_next(le) != &buddy_array[i]) {
ffffffffc0200bf8:	00890c63          	beq	s2,s0,ffffffffc0200c10 <show_buddy_array.constprop.3+0xc2>
                cprintf("%p|", p);
ffffffffc0200bfc:	fe840593          	addi	a1,s0,-24
ffffffffc0200c00:	8526                	mv	a0,s1
ffffffffc0200c02:	cb4ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc0200c06:	6400                	ld	s0,8(s0)
            while ((le = list_next(le)) != &buddy_array[i]) {
ffffffffc0200c08:	ff241ae3          	bne	s0,s2,ffffffffc0200bfc <show_buddy_array.constprop.3+0xae>
            if (i != right) {
ffffffffc0200c0c:	01698963          	beq	s3,s6,ffffffffc0200c1e <show_buddy_array.constprop.3+0xd0>
                cprintf("空|");
ffffffffc0200c10:	8556                	mv	a0,s5
    for (int i = left; i <= right; i++) {
ffffffffc0200c12:	2985                	addiw	s3,s3,1
                cprintf("空|");
ffffffffc0200c14:	ca2ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
        if (empty) {
ffffffffc0200c18:	0941                	addi	s2,s2,16
    for (int i = left; i <= right; i++) {
ffffffffc0200c1a:	fd499de3          	bne	s3,s4,ffffffffc0200bf4 <show_buddy_array.constprop.3+0xa6>
}
ffffffffc0200c1e:	6406                	ld	s0,64(sp)
ffffffffc0200c20:	60a6                	ld	ra,72(sp)
ffffffffc0200c22:	74e2                	ld	s1,56(sp)
ffffffffc0200c24:	7942                	ld	s2,48(sp)
ffffffffc0200c26:	79a2                	ld	s3,40(sp)
ffffffffc0200c28:	7a02                	ld	s4,32(sp)
ffffffffc0200c2a:	6ae2                	ld	s5,24(sp)
ffffffffc0200c2c:	6b42                	ld	s6,16(sp)
ffffffffc0200c2e:	6ba2                	ld	s7,8(sp)
ffffffffc0200c30:	6c02                	ld	s8,0(sp)
    cprintf("\n");
ffffffffc0200c32:	00001517          	auipc	a0,0x1
ffffffffc0200c36:	47650513          	addi	a0,a0,1142 # ffffffffc02020a8 <commands+0x738>
}
ffffffffc0200c3a:	6161                	addi	sp,sp,80
    cprintf("\n");
ffffffffc0200c3c:	c7aff06f          	j	ffffffffc02000b6 <cprintf>
            cprintf("%d: 空 |");
ffffffffc0200c40:	8562                	mv	a0,s8
    for (int i = left; i <= right; i++) {
ffffffffc0200c42:	2985                	addiw	s3,s3,1
            cprintf("%d: 空 |");
ffffffffc0200c44:	c72ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc0200c48:	04c1                	addi	s1,s1,16
    for (int i = left; i <= right; i++) {
ffffffffc0200c4a:	f5799fe3          	bne	s3,s7,ffffffffc0200ba8 <show_buddy_array.constprop.3+0x5a>
ffffffffc0200c4e:	b751                	j	ffffffffc0200bd2 <show_buddy_array.constprop.3+0x84>
    assert(left >= 0 && left <= max_order && right >= 0 && right <= max_order);
ffffffffc0200c50:	00001697          	auipc	a3,0x1
ffffffffc0200c54:	6e868693          	addi	a3,a3,1768 # ffffffffc0202338 <buddy_system_pmm_manager+0x38>
ffffffffc0200c58:	00001617          	auipc	a2,0x1
ffffffffc0200c5c:	66060613          	addi	a2,a2,1632 # ffffffffc02022b8 <commands+0x948>
ffffffffc0200c60:	07e00593          	li	a1,126
ffffffffc0200c64:	00001517          	auipc	a0,0x1
ffffffffc0200c68:	66c50513          	addi	a0,a0,1644 # ffffffffc02022d0 <commands+0x960>
ffffffffc0200c6c:	f40ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200c70 <buddy_system_free_pages>:
{
ffffffffc0200c70:	7179                	addi	sp,sp,-48
ffffffffc0200c72:	f406                	sd	ra,40(sp)
ffffffffc0200c74:	f022                	sd	s0,32(sp)
ffffffffc0200c76:	ec26                	sd	s1,24(sp)
ffffffffc0200c78:	e84a                	sd	s2,16(sp)
ffffffffc0200c7a:	e44e                	sd	s3,8(sp)
    assert(n > 0);
ffffffffc0200c7c:	12058d63          	beqz	a1,ffffffffc0200db6 <buddy_system_free_pages+0x146>
    unsigned int pnum = 1 << (base->property); // 块中页的数目
ffffffffc0200c80:	4910                	lw	a2,16(a0)
    if (n & (n - 1))
ffffffffc0200c82:	fff58713          	addi	a4,a1,-1
    unsigned int pnum = 1 << (base->property); // 块中页的数目
ffffffffc0200c86:	4385                	li	t2,1
ffffffffc0200c88:	00c393bb          	sllw	t2,t2,a2
    if (n & (n - 1))
ffffffffc0200c8c:	8f6d                	and	a4,a4,a1
    unsigned int pnum = 1 << (base->property); // 块中页的数目
ffffffffc0200c8e:	0003869b          	sext.w	a3,t2
    if (n & (n - 1))
ffffffffc0200c92:	10071c63          	bnez	a4,ffffffffc0200daa <buddy_system_free_pages+0x13a>
    assert(ROUNDUP2(n) == pnum);
ffffffffc0200c96:	02039793          	slli	a5,t2,0x20
ffffffffc0200c9a:	9381                	srli	a5,a5,0x20
ffffffffc0200c9c:	12b79d63          	bne	a5,a1,ffffffffc0200dd6 <buddy_system_free_pages+0x166>
    size_t sizeOfPage = real_block_size * sizeof(struct Page);                  // sizeof(struct Page)是0x28
ffffffffc0200ca0:	00269793          	slli	a5,a3,0x2
    size_t relative_block_addr = (size_t)block_addr - mem_begin; // 计算相对于初始化的第一个页的偏移量
ffffffffc0200ca4:	3fdf1f37          	lui	t5,0x3fdf1
    __list_add(elm, listelm, listelm->next);
ffffffffc0200ca8:	02061713          	slli	a4,a2,0x20
ffffffffc0200cac:	ce8f0f13          	addi	t5,t5,-792 # 3fdf0ce8 <BASE_ADDRESS-0xffffffff8040f318>
    size_t sizeOfPage = real_block_size * sizeof(struct Page);                  // sizeof(struct Page)是0x28
ffffffffc0200cb0:	97b6                	add	a5,a5,a3
ffffffffc0200cb2:	9301                	srli	a4,a4,0x20
ffffffffc0200cb4:	00005817          	auipc	a6,0x5
ffffffffc0200cb8:	79480813          	addi	a6,a6,1940 # ffffffffc0206448 <buddy_s>
ffffffffc0200cbc:	0712                	slli	a4,a4,0x4
    size_t relative_block_addr = (size_t)block_addr - mem_begin; // 计算相对于初始化的第一个页的偏移量
ffffffffc0200cbe:	01e506b3          	add	a3,a0,t5
    size_t sizeOfPage = real_block_size * sizeof(struct Page);                  // sizeof(struct Page)是0x28
ffffffffc0200cc2:	078e                	slli	a5,a5,0x3
ffffffffc0200cc4:	00e808b3          	add	a7,a6,a4
    size_t buddy_relative_addr = (size_t)relative_block_addr ^ sizeOfPage;      // 异或得到伙伴块的相对地址
ffffffffc0200cc8:	8fb5                	xor	a5,a5,a3
ffffffffc0200cca:	0108b583          	ld	a1,16(a7)
    struct Page *buddy_page = (struct Page *)(buddy_relative_addr + mem_begin); // 返回伙伴块指针
ffffffffc0200cce:	41e787b3          	sub	a5,a5,t5
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200cd2:	6794                	ld	a3,8(a5)
    list_add(&(buddy_array[left_block->property]), &(left_block->page_link)); // 将当前块先插入对应链表中
ffffffffc0200cd4:	01850e93          	addi	t4,a0,24
    prev->next = next->prev = elm;
ffffffffc0200cd8:	01d5b023          	sd	t4,0(a1)
ffffffffc0200cdc:	0721                	addi	a4,a4,8
ffffffffc0200cde:	01d8b823          	sd	t4,16(a7)
ffffffffc0200ce2:	9742                	add	a4,a4,a6
ffffffffc0200ce4:	8285                	srli	a3,a3,0x1
    elm->prev = prev;
ffffffffc0200ce6:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc0200ce8:	f10c                	sd	a1,32(a0)
    while (!PageProperty(buddy) && left_block->property < max_order)
ffffffffc0200cea:	0016f713          	andi	a4,a3,1
ffffffffc0200cee:	00850f93          	addi	t6,a0,8
ffffffffc0200cf2:	eb51                	bnez	a4,ffffffffc0200d86 <buddy_system_free_pages+0x116>
ffffffffc0200cf4:	00082703          	lw	a4,0(a6)
ffffffffc0200cf8:	08e67763          	bleu	a4,a2,ffffffffc0200d86 <buddy_system_free_pages+0x116>
            left_block->property = -1;     // 将左块幂次置为无效
ffffffffc0200cfc:	54fd                	li	s1,-1
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200cfe:	5475                	li	s0,-3
    size_t real_block_size = 1 << block_size;                    // 幂次转换成数
ffffffffc0200d00:	4285                	li	t0,1
        if (left_block > buddy)
ffffffffc0200d02:	00a7fc63          	bleu	a0,a5,ffffffffc0200d1a <buddy_system_free_pages+0xaa>
            left_block->property = -1;     // 将左块幂次置为无效
ffffffffc0200d06:	c904                	sw	s1,16(a0)
ffffffffc0200d08:	608fb02f          	amoand.d	zero,s0,(t6)
ffffffffc0200d0c:	872a                	mv	a4,a0
ffffffffc0200d0e:	00878f93          	addi	t6,a5,8
ffffffffc0200d12:	853e                	mv	a0,a5
ffffffffc0200d14:	01878e93          	addi	t4,a5,24
ffffffffc0200d18:	87ba                	mv	a5,a4
    __list_del(listelm->prev, listelm->next);
ffffffffc0200d1a:	6d14                	ld	a3,24(a0)
ffffffffc0200d1c:	7118                	ld	a4,32(a0)
        left_block->property += 1; // 左快头页设置幂次加一
ffffffffc0200d1e:	4910                	lw	a2,16(a0)
    size_t relative_block_addr = (size_t)block_addr - mem_begin; // 计算相对于初始化的第一个页的偏移量
ffffffffc0200d20:	01e505b3          	add	a1,a0,t5
    prev->next = next;
ffffffffc0200d24:	e698                	sd	a4,8(a3)
        left_block->property += 1; // 左快头页设置幂次加一
ffffffffc0200d26:	2605                	addiw	a2,a2,1
    next->prev = prev;
ffffffffc0200d28:	e314                	sd	a3,0(a4)
ffffffffc0200d2a:	0006091b          	sext.w	s2,a2
    __list_del(listelm->prev, listelm->next);
ffffffffc0200d2e:	0187b983          	ld	s3,24(a5)
ffffffffc0200d32:	0207be03          	ld	t3,32(a5)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200d36:	02061713          	slli	a4,a2,0x20
    size_t real_block_size = 1 << block_size;                    // 幂次转换成数
ffffffffc0200d3a:	012297bb          	sllw	a5,t0,s2
    size_t sizeOfPage = real_block_size * sizeof(struct Page);                  // sizeof(struct Page)是0x28
ffffffffc0200d3e:	00279693          	slli	a3,a5,0x2
ffffffffc0200d42:	9301                	srli	a4,a4,0x20
ffffffffc0200d44:	0712                	slli	a4,a4,0x4
ffffffffc0200d46:	96be                	add	a3,a3,a5
    prev->next = next;
ffffffffc0200d48:	01c9b423          	sd	t3,8(s3)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200d4c:	00e80333          	add	t1,a6,a4
ffffffffc0200d50:	068e                	slli	a3,a3,0x3
ffffffffc0200d52:	01033883          	ld	a7,16(t1)
    size_t buddy_relative_addr = (size_t)relative_block_addr ^ sizeOfPage;      // 异或得到伙伴块的相对地址
ffffffffc0200d56:	00b6c7b3          	xor	a5,a3,a1
    next->prev = prev;
ffffffffc0200d5a:	013e3023          	sd	s3,0(t3)
    struct Page *buddy_page = (struct Page *)(buddy_relative_addr + mem_begin); // 返回伙伴块指针
ffffffffc0200d5e:	41e787b3          	sub	a5,a5,t5
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200d62:	6794                	ld	a3,8(a5)
        left_block->property += 1; // 左快头页设置幂次加一
ffffffffc0200d64:	c910                	sw	a2,16(a0)
    prev->next = next->prev = elm;
ffffffffc0200d66:	01d8b023          	sd	t4,0(a7)
        list_add(&(buddy_array[left_block->property]), &(left_block->page_link)); // 头插入相应链表
ffffffffc0200d6a:	0721                	addi	a4,a4,8
ffffffffc0200d6c:	01d33823          	sd	t4,16(t1)
ffffffffc0200d70:	9742                	add	a4,a4,a6
    elm->prev = prev;
ffffffffc0200d72:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc0200d74:	03153023          	sd	a7,32(a0)
    while (!PageProperty(buddy) && left_block->property < max_order)
ffffffffc0200d78:	0026f713          	andi	a4,a3,2
ffffffffc0200d7c:	e709                	bnez	a4,ffffffffc0200d86 <buddy_system_free_pages+0x116>
ffffffffc0200d7e:	00082703          	lw	a4,0(a6)
ffffffffc0200d82:	f8e960e3          	bltu	s2,a4,ffffffffc0200d02 <buddy_system_free_pages+0x92>
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200d86:	57f5                	li	a5,-3
ffffffffc0200d88:	60ffb02f          	amoand.d	zero,a5,(t6)
    nr_free += pnum;
ffffffffc0200d8c:	0f882783          	lw	a5,248(a6)
}
ffffffffc0200d90:	70a2                	ld	ra,40(sp)
ffffffffc0200d92:	7402                	ld	s0,32(sp)
    nr_free += pnum;
ffffffffc0200d94:	007783bb          	addw	t2,a5,t2
ffffffffc0200d98:	00005797          	auipc	a5,0x5
ffffffffc0200d9c:	7a77a423          	sw	t2,1960(a5) # ffffffffc0206540 <buddy_s+0xf8>
}
ffffffffc0200da0:	64e2                	ld	s1,24(sp)
ffffffffc0200da2:	6942                	ld	s2,16(sp)
ffffffffc0200da4:	69a2                	ld	s3,8(sp)
ffffffffc0200da6:	6145                	addi	sp,sp,48
ffffffffc0200da8:	8082                	ret
    size_t res = 1;
ffffffffc0200daa:	4785                	li	a5,1
            n = n >> 1;
ffffffffc0200dac:	8185                	srli	a1,a1,0x1
            res = res << 1;
ffffffffc0200dae:	0786                	slli	a5,a5,0x1
        while (n)
ffffffffc0200db0:	fdf5                	bnez	a1,ffffffffc0200dac <buddy_system_free_pages+0x13c>
            res = res << 1;
ffffffffc0200db2:	85be                	mv	a1,a5
ffffffffc0200db4:	b5cd                	j	ffffffffc0200c96 <buddy_system_free_pages+0x26>
    assert(n > 0);
ffffffffc0200db6:	00001697          	auipc	a3,0x1
ffffffffc0200dba:	4fa68693          	addi	a3,a3,1274 # ffffffffc02022b0 <commands+0x940>
ffffffffc0200dbe:	00001617          	auipc	a2,0x1
ffffffffc0200dc2:	4fa60613          	addi	a2,a2,1274 # ffffffffc02022b8 <commands+0x948>
ffffffffc0200dc6:	12700593          	li	a1,295
ffffffffc0200dca:	00001517          	auipc	a0,0x1
ffffffffc0200dce:	50650513          	addi	a0,a0,1286 # ffffffffc02022d0 <commands+0x960>
ffffffffc0200dd2:	ddaff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(ROUNDUP2(n) == pnum);
ffffffffc0200dd6:	00001697          	auipc	a3,0x1
ffffffffc0200dda:	4c268693          	addi	a3,a3,1218 # ffffffffc0202298 <commands+0x928>
ffffffffc0200dde:	00001617          	auipc	a2,0x1
ffffffffc0200de2:	4da60613          	addi	a2,a2,1242 # ffffffffc02022b8 <commands+0x948>
ffffffffc0200de6:	12900593          	li	a1,297
ffffffffc0200dea:	00001517          	auipc	a0,0x1
ffffffffc0200dee:	4e650513          	addi	a0,a0,1254 # ffffffffc02022d0 <commands+0x960>
ffffffffc0200df2:	dbaff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200df6 <buddy_system_check>:

// LAB2: below code is used to check the first fit allocation algorithm
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
buddy_system_check(void)
{
ffffffffc0200df6:	7179                	addi	sp,sp,-48
    //basic_check();
    
    //buddy_system_init();
    cprintf("====================开始测试========================\n");
ffffffffc0200df8:	00001517          	auipc	a0,0x1
ffffffffc0200dfc:	1f850513          	addi	a0,a0,504 # ffffffffc0201ff0 <commands+0x680>
{
ffffffffc0200e00:	f406                	sd	ra,40(sp)
ffffffffc0200e02:	f022                	sd	s0,32(sp)
ffffffffc0200e04:	ec26                	sd	s1,24(sp)
ffffffffc0200e06:	e84a                	sd	s2,16(sp)
ffffffffc0200e08:	e44e                	sd	s3,8(sp)
    cprintf("====================开始测试========================\n");
ffffffffc0200e0a:	aacff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("总空闲块数目为：%d\n", nr_free);
ffffffffc0200e0e:	00005797          	auipc	a5,0x5
ffffffffc0200e12:	63a78793          	addi	a5,a5,1594 # ffffffffc0206448 <buddy_s>
ffffffffc0200e16:	0f87a583          	lw	a1,248(a5)
ffffffffc0200e1a:	00001517          	auipc	a0,0x1
ffffffffc0200e1e:	21650513          	addi	a0,a0,534 # ffffffffc0202030 <commands+0x6c0>
ffffffffc0200e22:	a94ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("=====================申请空闲块=======================\n");
ffffffffc0200e26:	00001517          	auipc	a0,0x1
ffffffffc0200e2a:	22a50513          	addi	a0,a0,554 # ffffffffc0202050 <commands+0x6e0>
ffffffffc0200e2e:	a88ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>


    cprintf("首先申请 p0 p1 p2 p3\n");
ffffffffc0200e32:	00001517          	auipc	a0,0x1
ffffffffc0200e36:	25e50513          	addi	a0,a0,606 # ffffffffc0202090 <commands+0x720>
ffffffffc0200e3a:	a7cff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("其大小为 70 35 257 63\n");
ffffffffc0200e3e:	00001517          	auipc	a0,0x1
ffffffffc0200e42:	27250513          	addi	a0,a0,626 # ffffffffc02020b0 <commands+0x740>
ffffffffc0200e46:	a70ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>

    // 申请 p0, p1, p2, p3
    struct Page *p0 = buddy_system_alloc_pages(70);
ffffffffc0200e4a:	04600513          	li	a0,70
ffffffffc0200e4e:	b25ff0ef          	jal	ra,ffffffffc0200972 <buddy_system_alloc_pages>
ffffffffc0200e52:	842a                	mv	s0,a0
    struct Page *p1 = buddy_system_alloc_pages(35);
ffffffffc0200e54:	02300513          	li	a0,35
ffffffffc0200e58:	b1bff0ef          	jal	ra,ffffffffc0200972 <buddy_system_alloc_pages>
ffffffffc0200e5c:	89aa                	mv	s3,a0
    struct Page *p2 = buddy_system_alloc_pages(257);
ffffffffc0200e5e:	10100513          	li	a0,257
ffffffffc0200e62:	b11ff0ef          	jal	ra,ffffffffc0200972 <buddy_system_alloc_pages>
ffffffffc0200e66:	892a                	mv	s2,a0
    struct Page *p3 = buddy_system_alloc_pages(63);
ffffffffc0200e68:	03f00513          	li	a0,63
ffffffffc0200e6c:	b07ff0ef          	jal	ra,ffffffffc0200972 <buddy_system_alloc_pages>
ffffffffc0200e70:	84aa                	mv	s1,a0

    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200e72:	cddff0ef          	jal	ra,ffffffffc0200b4e <show_buddy_array.constprop.3>
    cprintf("\n");
ffffffffc0200e76:	00001517          	auipc	a0,0x1
ffffffffc0200e7a:	23250513          	addi	a0,a0,562 # ffffffffc02020a8 <commands+0x738>
ffffffffc0200e7e:	a38ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("======================释放 p1\\p3======================\n");
ffffffffc0200e82:	00001517          	auipc	a0,0x1
ffffffffc0200e86:	24e50513          	addi	a0,a0,590 # ffffffffc02020d0 <commands+0x760>
ffffffffc0200e8a:	a2cff0ef          	jal	ra,ffffffffc02000b6 <cprintf>

    // 释放 p1 和 p3
    buddy_system_free_pages(p1, 35);
ffffffffc0200e8e:	854e                	mv	a0,s3
ffffffffc0200e90:	02300593          	li	a1,35
ffffffffc0200e94:	dddff0ef          	jal	ra,ffffffffc0200c70 <buddy_system_free_pages>
    buddy_system_free_pages(p3, 63);
ffffffffc0200e98:	03f00593          	li	a1,63
ffffffffc0200e9c:	8526                	mv	a0,s1
ffffffffc0200e9e:	dd3ff0ef          	jal	ra,ffffffffc0200c70 <buddy_system_free_pages>

    cprintf("这时候 p1 和 p3 的块应该合并\n");
ffffffffc0200ea2:	00001517          	auipc	a0,0x1
ffffffffc0200ea6:	26e50513          	addi	a0,a0,622 # ffffffffc0202110 <commands+0x7a0>
ffffffffc0200eaa:	a0cff0ef          	jal	ra,ffffffffc02000b6 <cprintf>

    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200eae:	ca1ff0ef          	jal	ra,ffffffffc0200b4e <show_buddy_array.constprop.3>
    cprintf("\n");
ffffffffc0200eb2:	00001517          	auipc	a0,0x1
ffffffffc0200eb6:	1f650513          	addi	a0,a0,502 # ffffffffc02020a8 <commands+0x738>
ffffffffc0200eba:	9fcff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("===================再释放P0=========================\n");
ffffffffc0200ebe:	00001517          	auipc	a0,0x1
ffffffffc0200ec2:	27a50513          	addi	a0,a0,634 # ffffffffc0202138 <commands+0x7c8>
ffffffffc0200ec6:	9f0ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>

    // 释放 p0
    buddy_system_free_pages(p0, 70);
ffffffffc0200eca:	04600593          	li	a1,70
ffffffffc0200ece:	8522                	mv	a0,s0
ffffffffc0200ed0:	da1ff0ef          	jal	ra,ffffffffc0200c70 <buddy_system_free_pages>

    cprintf("这时候 p0 的块与伙伴块合并\n");
ffffffffc0200ed4:	00001517          	auipc	a0,0x1
ffffffffc0200ed8:	2a450513          	addi	a0,a0,676 # ffffffffc0202178 <commands+0x808>
ffffffffc0200edc:	9daff0ef          	jal	ra,ffffffffc02000b6 <cprintf>

    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200ee0:	c6fff0ef          	jal	ra,ffffffffc0200b4e <show_buddy_array.constprop.3>
    cprintf("\n");
ffffffffc0200ee4:	00001517          	auipc	a0,0x1
ffffffffc0200ee8:	1c450513          	addi	a0,a0,452 # ffffffffc02020a8 <commands+0x738>
ffffffffc0200eec:	9caff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("====================再次申请========================\n");
ffffffffc0200ef0:	00001517          	auipc	a0,0x1
ffffffffc0200ef4:	2b050513          	addi	a0,a0,688 # ffffffffc02021a0 <commands+0x830>
ffffffffc0200ef8:	9beff0ef          	jal	ra,ffffffffc02000b6 <cprintf>

    // 申请 p4 和 p5
    struct Page *p4 = buddy_system_alloc_pages(255);
ffffffffc0200efc:	0ff00513          	li	a0,255
ffffffffc0200f00:	a73ff0ef          	jal	ra,ffffffffc0200972 <buddy_system_alloc_pages>
ffffffffc0200f04:	84aa                	mv	s1,a0
    struct Page *p5 = buddy_system_alloc_pages(255);
ffffffffc0200f06:	0ff00513          	li	a0,255
ffffffffc0200f0a:	a69ff0ef          	jal	ra,ffffffffc0200972 <buddy_system_alloc_pages>
ffffffffc0200f0e:	842a                	mv	s0,a0

    cprintf("最后我们申请 p4 p5\n");
ffffffffc0200f10:	00001517          	auipc	a0,0x1
ffffffffc0200f14:	2d050513          	addi	a0,a0,720 # ffffffffc02021e0 <commands+0x870>
ffffffffc0200f18:	99eff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("其大小为 255 255\n");
ffffffffc0200f1c:	00001517          	auipc	a0,0x1
ffffffffc0200f20:	2e450513          	addi	a0,a0,740 # ffffffffc0202200 <commands+0x890>
ffffffffc0200f24:	992ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>

    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200f28:	c27ff0ef          	jal	ra,ffffffffc0200b4e <show_buddy_array.constprop.3>
    cprintf("\n");
ffffffffc0200f2c:	00001517          	auipc	a0,0x1
ffffffffc0200f30:	17c50513          	addi	a0,a0,380 # ffffffffc02020a8 <commands+0x738>
ffffffffc0200f34:	982ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("===================释放所有块=========================\n");
ffffffffc0200f38:	00001517          	auipc	a0,0x1
ffffffffc0200f3c:	2e050513          	addi	a0,a0,736 # ffffffffc0202218 <commands+0x8a8>
ffffffffc0200f40:	976ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>

    // 释放所有页面
    buddy_system_free_pages(p2, 257);
ffffffffc0200f44:	854a                	mv	a0,s2
ffffffffc0200f46:	10100593          	li	a1,257
ffffffffc0200f4a:	d27ff0ef          	jal	ra,ffffffffc0200c70 <buddy_system_free_pages>
    buddy_system_free_pages(p4, 255);
ffffffffc0200f4e:	8526                	mv	a0,s1
ffffffffc0200f50:	0ff00593          	li	a1,255
ffffffffc0200f54:	d1dff0ef          	jal	ra,ffffffffc0200c70 <buddy_system_free_pages>
    buddy_system_free_pages(p5, 255);
ffffffffc0200f58:	8522                	mv	a0,s0
ffffffffc0200f5a:	0ff00593          	li	a1,255
ffffffffc0200f5e:	d13ff0ef          	jal	ra,ffffffffc0200c70 <buddy_system_free_pages>

    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200f62:	bedff0ef          	jal	ra,ffffffffc0200b4e <show_buddy_array.constprop.3>
    cprintf("====================测试结束========================\n");

}
ffffffffc0200f66:	7402                	ld	s0,32(sp)
ffffffffc0200f68:	70a2                	ld	ra,40(sp)
ffffffffc0200f6a:	64e2                	ld	s1,24(sp)
ffffffffc0200f6c:	6942                	ld	s2,16(sp)
ffffffffc0200f6e:	69a2                	ld	s3,8(sp)
    cprintf("====================测试结束========================\n");
ffffffffc0200f70:	00001517          	auipc	a0,0x1
ffffffffc0200f74:	2e850513          	addi	a0,a0,744 # ffffffffc0202258 <commands+0x8e8>
}
ffffffffc0200f78:	6145                	addi	sp,sp,48
    cprintf("====================测试结束========================\n");
ffffffffc0200f7a:	93cff06f          	j	ffffffffc02000b6 <cprintf>

ffffffffc0200f7e <pa2page.part.0>:
static inline int page_ref_dec(struct Page *page)
{
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa)
ffffffffc0200f7e:	1141                	addi	sp,sp,-16
{
    if (PPN(pa) >= npage)
    {
        panic("pa2page called with invalid pa");
ffffffffc0200f80:	00001617          	auipc	a2,0x1
ffffffffc0200f84:	48060613          	addi	a2,a2,1152 # ffffffffc0202400 <buddy_system_pmm_manager+0x100>
ffffffffc0200f88:	07200593          	li	a1,114
ffffffffc0200f8c:	00001517          	auipc	a0,0x1
ffffffffc0200f90:	49450513          	addi	a0,a0,1172 # ffffffffc0202420 <buddy_system_pmm_manager+0x120>
static inline struct Page *pa2page(uintptr_t pa)
ffffffffc0200f94:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0200f96:	c16ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200f9a <pmm_init>:
// init_pmm_manager - initialize a pmm_manager instance
static void init_pmm_manager(void)
{
    pmm_manager = &default_pmm_manager;
    pmm_manager = &best_fit_pmm_manager;
    pmm_manager = &buddy_system_pmm_manager;
ffffffffc0200f9a:	00001797          	auipc	a5,0x1
ffffffffc0200f9e:	36678793          	addi	a5,a5,870 # ffffffffc0202300 <buddy_system_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200fa2:	638c                	ld	a1,0(a5)
    cprintf("可用空闲页的数目: 0x%016lx.\n", (mem_end - mem_begin) / PGSIZE); // test point
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void)
{
ffffffffc0200fa4:	715d                	addi	sp,sp,-80
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200fa6:	00001517          	auipc	a0,0x1
ffffffffc0200faa:	48a50513          	addi	a0,a0,1162 # ffffffffc0202430 <buddy_system_pmm_manager+0x130>
{
ffffffffc0200fae:	e486                	sd	ra,72(sp)
ffffffffc0200fb0:	e0a2                	sd	s0,64(sp)
ffffffffc0200fb2:	f052                	sd	s4,32(sp)
    pmm_manager = &buddy_system_pmm_manager;
ffffffffc0200fb4:	00005717          	auipc	a4,0x5
ffffffffc0200fb8:	58f73e23          	sd	a5,1436(a4) # ffffffffc0206550 <pmm_manager>
{
ffffffffc0200fbc:	fc26                	sd	s1,56(sp)
ffffffffc0200fbe:	f84a                	sd	s2,48(sp)
ffffffffc0200fc0:	f44e                	sd	s3,40(sp)
ffffffffc0200fc2:	ec56                	sd	s5,24(sp)
ffffffffc0200fc4:	e85a                	sd	s6,16(sp)
ffffffffc0200fc6:	e45e                	sd	s7,8(sp)
    pmm_manager = &buddy_system_pmm_manager;
ffffffffc0200fc8:	00005a17          	auipc	s4,0x5
ffffffffc0200fcc:	588a0a13          	addi	s4,s4,1416 # ffffffffc0206550 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200fd0:	8e6ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    pmm_manager->init();
ffffffffc0200fd4:	000a3783          	ld	a5,0(s4)
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0200fd8:	4445                	li	s0,17
ffffffffc0200fda:	046e                	slli	s0,s0,0x1b
    pmm_manager->init();
ffffffffc0200fdc:	679c                	ld	a5,8(a5)
ffffffffc0200fde:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET; // 设置虚拟到物理地址的偏移:
ffffffffc0200fe0:	57f5                	li	a5,-3
ffffffffc0200fe2:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc0200fe4:	00001517          	auipc	a0,0x1
ffffffffc0200fe8:	46450513          	addi	a0,a0,1124 # ffffffffc0202448 <buddy_system_pmm_manager+0x148>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET; // 设置虚拟到物理地址的偏移:
ffffffffc0200fec:	00005717          	auipc	a4,0x5
ffffffffc0200ff0:	56f73623          	sd	a5,1388(a4) # ffffffffc0206558 <va_pa_offset>
    cprintf("physcial memory map:\n");
ffffffffc0200ff4:	8c2ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0200ff8:	40100613          	li	a2,1025
ffffffffc0200ffc:	fff40693          	addi	a3,s0,-1
ffffffffc0201000:	0656                	slli	a2,a2,0x15
ffffffffc0201002:	07e005b7          	lui	a1,0x7e00
ffffffffc0201006:	00001517          	auipc	a0,0x1
ffffffffc020100a:	45a50513          	addi	a0,a0,1114 # ffffffffc0202460 <buddy_system_pmm_manager+0x160>
ffffffffc020100e:	8a8ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("最大物理地址: 0x%016lx.\n", maxpa); // test point
ffffffffc0201012:	85a2                	mv	a1,s0
ffffffffc0201014:	00001517          	auipc	a0,0x1
ffffffffc0201018:	47c50513          	addi	a0,a0,1148 # ffffffffc0202490 <buddy_system_pmm_manager+0x190>
ffffffffc020101c:	89aff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0201020:	000887b7          	lui	a5,0x88
    cprintf("页面数量: 0x%016lx.\n", npage); // test point,为0x8800_0
ffffffffc0201024:	000885b7          	lui	a1,0x88
ffffffffc0201028:	00001517          	auipc	a0,0x1
ffffffffc020102c:	48850513          	addi	a0,a0,1160 # ffffffffc02024b0 <buddy_system_pmm_manager+0x1b0>
    npage = maxpa / PGSIZE;
ffffffffc0201030:	00005717          	auipc	a4,0x5
ffffffffc0201034:	3ef73c23          	sd	a5,1016(a4) # ffffffffc0206428 <npage>
    cprintf("页面数量: 0x%016lx.\n", npage); // test point,为0x8800_0
ffffffffc0201038:	87eff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("基本页的数量: 0x%016lx.\n", nbase); // test point，为0x8000_0
ffffffffc020103c:	000805b7          	lui	a1,0x80
ffffffffc0201040:	00001517          	auipc	a0,0x1
ffffffffc0201044:	49050513          	addi	a0,a0,1168 # ffffffffc02024d0 <buddy_system_pmm_manager+0x1d0>
ffffffffc0201048:	86eff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020104c:	00006697          	auipc	a3,0x6
ffffffffc0201050:	51b68693          	addi	a3,a3,1307 # ffffffffc0207567 <end+0xfff>
ffffffffc0201054:	75fd                	lui	a1,0xfffff
ffffffffc0201056:	8eed                	and	a3,a3,a1
ffffffffc0201058:	00005797          	auipc	a5,0x5
ffffffffc020105c:	50d7b423          	sd	a3,1288(a5) # ffffffffc0206560 <pages>
    cprintf("页结构的物理地址: 0x%016lx.\n", PADDR((uintptr_t)pages)); // test point
ffffffffc0201060:	c02007b7          	lui	a5,0xc0200
ffffffffc0201064:	1ef6ed63          	bltu	a3,a5,ffffffffc020125e <pmm_init+0x2c4>
ffffffffc0201068:	00005997          	auipc	s3,0x5
ffffffffc020106c:	4f098993          	addi	s3,s3,1264 # ffffffffc0206558 <va_pa_offset>
ffffffffc0201070:	0009b583          	ld	a1,0(s3)
ffffffffc0201074:	00001517          	auipc	a0,0x1
ffffffffc0201078:	4b450513          	addi	a0,a0,1204 # ffffffffc0202528 <buddy_system_pmm_manager+0x228>
ffffffffc020107c:	00005917          	auipc	s2,0x5
ffffffffc0201080:	3ac90913          	addi	s2,s2,940 # ffffffffc0206428 <npage>
ffffffffc0201084:	40b685b3          	sub	a1,a3,a1
ffffffffc0201088:	82eff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020108c:	00093703          	ld	a4,0(s2)
ffffffffc0201090:	000807b7          	lui	a5,0x80
ffffffffc0201094:	1af70063          	beq	a4,a5,ffffffffc0201234 <pmm_init+0x29a>
ffffffffc0201098:	4601                	li	a2,0
ffffffffc020109a:	4701                	li	a4,0
ffffffffc020109c:	00005b97          	auipc	s7,0x5
ffffffffc02010a0:	4c4b8b93          	addi	s7,s7,1220 # ffffffffc0206560 <pages>
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02010a4:	4505                	li	a0,1
ffffffffc02010a6:	fff805b7          	lui	a1,0xfff80
        SetPageReserved(pages + i);
ffffffffc02010aa:	000bb783          	ld	a5,0(s7)
ffffffffc02010ae:	97b2                	add	a5,a5,a2
ffffffffc02010b0:	07a1                	addi	a5,a5,8
ffffffffc02010b2:	40a7b02f          	amoor.d	zero,a0,(a5)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02010b6:	00093683          	ld	a3,0(s2)
ffffffffc02010ba:	0705                	addi	a4,a4,1
ffffffffc02010bc:	02860613          	addi	a2,a2,40
ffffffffc02010c0:	00b687b3          	add	a5,a3,a1
ffffffffc02010c4:	fef763e3          	bltu	a4,a5,ffffffffc02010aa <pmm_init+0x110>
ffffffffc02010c8:	00269413          	slli	s0,a3,0x2
ffffffffc02010cc:	9436                	add	s0,s0,a3
ffffffffc02010ce:	00341693          	slli	a3,s0,0x3
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 0x8034 7000 = 0x8020 7000 + 0x28 * 0x8000
ffffffffc02010d2:	000bb403          	ld	s0,0(s7)
ffffffffc02010d6:	fec00737          	lui	a4,0xfec00
ffffffffc02010da:	c02007b7          	lui	a5,0xc0200
ffffffffc02010de:	943a                	add	s0,s0,a4
ffffffffc02010e0:	9436                	add	s0,s0,a3
ffffffffc02010e2:	18f46a63          	bltu	s0,a5,ffffffffc0201276 <pmm_init+0x2dc>
ffffffffc02010e6:	0009b683          	ld	a3,0(s3)
    cprintf("page结构体大小: 0x%016lx.\n", sizeof(struct Page));                         // test point
ffffffffc02010ea:	02800593          	li	a1,40
ffffffffc02010ee:	00001517          	auipc	a0,0x1
ffffffffc02010f2:	46250513          	addi	a0,a0,1122 # ffffffffc0202550 <buddy_system_pmm_manager+0x250>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02010f6:	6485                	lui	s1,0x1
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 0x8034 7000 = 0x8020 7000 + 0x28 * 0x8000
ffffffffc02010f8:	8c15                	sub	s0,s0,a3
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02010fa:	14fd                	addi	s1,s1,-1
    cprintf("page结构体大小: 0x%016lx.\n", sizeof(struct Page));                         // test point
ffffffffc02010fc:	fbbfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("freemem: 0x%016lx.\n", freemem);     // test point
ffffffffc0201100:	85a2                	mv	a1,s0
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201102:	94a2                	add	s1,s1,s0
ffffffffc0201104:	7b7d                	lui	s6,0xfffff
    cprintf("freemem: 0x%016lx.\n", freemem);     // test point
ffffffffc0201106:	00001517          	auipc	a0,0x1
ffffffffc020110a:	46a50513          	addi	a0,a0,1130 # ffffffffc0202570 <buddy_system_pmm_manager+0x270>
ffffffffc020110e:	fa9fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc0201112:	0164fb33          	and	s6,s1,s6
    cprintf("mem_begin: 0x%016lx.\n", mem_begin); // test point
ffffffffc0201116:	85da                	mv	a1,s6
ffffffffc0201118:	00001517          	auipc	a0,0x1
ffffffffc020111c:	47050513          	addi	a0,a0,1136 # ffffffffc0202588 <buddy_system_pmm_manager+0x288>
ffffffffc0201120:	f97fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("mem_end: 0x%016lx.\n", mem_end);     // test point
ffffffffc0201124:	4ac5                	li	s5,17
ffffffffc0201126:	01ba9593          	slli	a1,s5,0x1b
ffffffffc020112a:	00001517          	auipc	a0,0x1
ffffffffc020112e:	47650513          	addi	a0,a0,1142 # ffffffffc02025a0 <buddy_system_pmm_manager+0x2a0>
    if (freemem < mem_end)
ffffffffc0201132:	0aee                	slli	s5,s5,0x1b
    cprintf("mem_end: 0x%016lx.\n", mem_end);     // test point
ffffffffc0201134:	f83fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    if (freemem < mem_end)
ffffffffc0201138:	0d546663          	bltu	s0,s5,ffffffffc0201204 <pmm_init+0x26a>
    if (PPN(pa) >= npage)
ffffffffc020113c:	00093783          	ld	a5,0(s2)
ffffffffc0201140:	00cb5493          	srli	s1,s6,0xc
ffffffffc0201144:	0ef4ff63          	bleu	a5,s1,ffffffffc0201242 <pmm_init+0x2a8>
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201148:	fff80437          	lui	s0,0xfff80
ffffffffc020114c:	008486b3          	add	a3,s1,s0
ffffffffc0201150:	00269413          	slli	s0,a3,0x2
ffffffffc0201154:	000bb583          	ld	a1,0(s7)
ffffffffc0201158:	9436                	add	s0,s0,a3
ffffffffc020115a:	040e                	slli	s0,s0,0x3
    cprintf("mem_begin对应的页结构记录(结构体page)虚拟地址: 0x%016lx.\n", pa2page(mem_begin));        // test point
ffffffffc020115c:	95a2                	add	a1,a1,s0
ffffffffc020115e:	00001517          	auipc	a0,0x1
ffffffffc0201162:	45a50513          	addi	a0,a0,1114 # ffffffffc02025b8 <buddy_system_pmm_manager+0x2b8>
ffffffffc0201166:	f51fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    if (PPN(pa) >= npage)
ffffffffc020116a:	00093783          	ld	a5,0(s2)
ffffffffc020116e:	0cf4fa63          	bleu	a5,s1,ffffffffc0201242 <pmm_init+0x2a8>
    return &pages[PPN(pa) - nbase];
ffffffffc0201172:	000bb683          	ld	a3,0(s7)
    cprintf("mem_begin对应的页结构记录(结构体page)物理地址: 0x%016lx.\n", PADDR(pa2page(mem_begin))); // test point
ffffffffc0201176:	c02004b7          	lui	s1,0xc0200
ffffffffc020117a:	96a2                	add	a3,a3,s0
ffffffffc020117c:	0c96e563          	bltu	a3,s1,ffffffffc0201246 <pmm_init+0x2ac>
ffffffffc0201180:	0009b583          	ld	a1,0(s3)
ffffffffc0201184:	00001517          	auipc	a0,0x1
ffffffffc0201188:	48450513          	addi	a0,a0,1156 # ffffffffc0202608 <buddy_system_pmm_manager+0x308>
ffffffffc020118c:	40b685b3          	sub	a1,a3,a1
ffffffffc0201190:	f27fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("可用空闲页的数目: 0x%016lx.\n", (mem_end - mem_begin) / PGSIZE); // test point
ffffffffc0201194:	45c5                	li	a1,17
ffffffffc0201196:	05ee                	slli	a1,a1,0x1b
ffffffffc0201198:	416585b3          	sub	a1,a1,s6
ffffffffc020119c:	81b1                	srli	a1,a1,0xc
ffffffffc020119e:	00001517          	auipc	a0,0x1
ffffffffc02011a2:	4ba50513          	addi	a0,a0,1210 # ffffffffc0202658 <buddy_system_pmm_manager+0x358>
ffffffffc02011a6:	f11fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc02011aa:	000a3783          	ld	a5,0(s4)
ffffffffc02011ae:	7b9c                	ld	a5,48(a5)
ffffffffc02011b0:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02011b2:	00001517          	auipc	a0,0x1
ffffffffc02011b6:	4ce50513          	addi	a0,a0,1230 # ffffffffc0202680 <buddy_system_pmm_manager+0x380>
ffffffffc02011ba:	efdfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    satp_virtual = (pte_t *)boot_page_table_sv39;
ffffffffc02011be:	00004697          	auipc	a3,0x4
ffffffffc02011c2:	e4268693          	addi	a3,a3,-446 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc02011c6:	00005797          	auipc	a5,0x5
ffffffffc02011ca:	26d7b523          	sd	a3,618(a5) # ffffffffc0206430 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc02011ce:	0c96e163          	bltu	a3,s1,ffffffffc0201290 <pmm_init+0x2f6>
ffffffffc02011d2:	0009b783          	ld	a5,0(s3)
}
ffffffffc02011d6:	6406                	ld	s0,64(sp)
ffffffffc02011d8:	60a6                	ld	ra,72(sp)
ffffffffc02011da:	74e2                	ld	s1,56(sp)
ffffffffc02011dc:	7942                	ld	s2,48(sp)
ffffffffc02011de:	79a2                	ld	s3,40(sp)
ffffffffc02011e0:	7a02                	ld	s4,32(sp)
ffffffffc02011e2:	6ae2                	ld	s5,24(sp)
ffffffffc02011e4:	6b42                	ld	s6,16(sp)
ffffffffc02011e6:	6ba2                	ld	s7,8(sp)
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02011e8:	85b6                	mv	a1,a3
    satp_physical = PADDR(satp_virtual);
ffffffffc02011ea:	8e9d                	sub	a3,a3,a5
ffffffffc02011ec:	00005797          	auipc	a5,0x5
ffffffffc02011f0:	34d7be23          	sd	a3,860(a5) # ffffffffc0206548 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02011f4:	00001517          	auipc	a0,0x1
ffffffffc02011f8:	4ac50513          	addi	a0,a0,1196 # ffffffffc02026a0 <buddy_system_pmm_manager+0x3a0>
ffffffffc02011fc:	8636                	mv	a2,a3
}
ffffffffc02011fe:	6161                	addi	sp,sp,80
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201200:	eb7fe06f          	j	ffffffffc02000b6 <cprintf>
    if (PPN(pa) >= npage)
ffffffffc0201204:	00093783          	ld	a5,0(s2)
ffffffffc0201208:	80b1                	srli	s1,s1,0xc
ffffffffc020120a:	02f4fc63          	bleu	a5,s1,ffffffffc0201242 <pmm_init+0x2a8>
    pmm_manager->init_memmap(base, n);
ffffffffc020120e:	000a3703          	ld	a4,0(s4)
    return &pages[PPN(pa) - nbase];
ffffffffc0201212:	fff80537          	lui	a0,0xfff80
ffffffffc0201216:	94aa                	add	s1,s1,a0
ffffffffc0201218:	00249793          	slli	a5,s1,0x2
ffffffffc020121c:	000bb503          	ld	a0,0(s7)
ffffffffc0201220:	94be                	add	s1,s1,a5
ffffffffc0201222:	6b1c                	ld	a5,16(a4)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201224:	416a8ab3          	sub	s5,s5,s6
ffffffffc0201228:	048e                	slli	s1,s1,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc020122a:	00cad593          	srli	a1,s5,0xc
ffffffffc020122e:	9526                	add	a0,a0,s1
ffffffffc0201230:	9782                	jalr	a5
ffffffffc0201232:	b729                	j	ffffffffc020113c <pmm_init+0x1a2>
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0201234:	014006b7          	lui	a3,0x1400
ffffffffc0201238:	00005b97          	auipc	s7,0x5
ffffffffc020123c:	328b8b93          	addi	s7,s7,808 # ffffffffc0206560 <pages>
ffffffffc0201240:	bd49                	j	ffffffffc02010d2 <pmm_init+0x138>
ffffffffc0201242:	d3dff0ef          	jal	ra,ffffffffc0200f7e <pa2page.part.0>
    cprintf("mem_begin对应的页结构记录(结构体page)物理地址: 0x%016lx.\n", PADDR(pa2page(mem_begin))); // test point
ffffffffc0201246:	00001617          	auipc	a2,0x1
ffffffffc020124a:	2aa60613          	addi	a2,a2,682 # ffffffffc02024f0 <buddy_system_pmm_manager+0x1f0>
ffffffffc020124e:	09600593          	li	a1,150
ffffffffc0201252:	00001517          	auipc	a0,0x1
ffffffffc0201256:	2c650513          	addi	a0,a0,710 # ffffffffc0202518 <buddy_system_pmm_manager+0x218>
ffffffffc020125a:	952ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    cprintf("页结构的物理地址: 0x%016lx.\n", PADDR((uintptr_t)pages)); // test point
ffffffffc020125e:	00001617          	auipc	a2,0x1
ffffffffc0201262:	29260613          	addi	a2,a2,658 # ffffffffc02024f0 <buddy_system_pmm_manager+0x1f0>
ffffffffc0201266:	07d00593          	li	a1,125
ffffffffc020126a:	00001517          	auipc	a0,0x1
ffffffffc020126e:	2ae50513          	addi	a0,a0,686 # ffffffffc0202518 <buddy_system_pmm_manager+0x218>
ffffffffc0201272:	93aff0ef          	jal	ra,ffffffffc02003ac <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 0x8034 7000 = 0x8020 7000 + 0x28 * 0x8000
ffffffffc0201276:	86a2                	mv	a3,s0
ffffffffc0201278:	00001617          	auipc	a2,0x1
ffffffffc020127c:	27860613          	addi	a2,a2,632 # ffffffffc02024f0 <buddy_system_pmm_manager+0x1f0>
ffffffffc0201280:	08800593          	li	a1,136
ffffffffc0201284:	00001517          	auipc	a0,0x1
ffffffffc0201288:	29450513          	addi	a0,a0,660 # ffffffffc0202518 <buddy_system_pmm_manager+0x218>
ffffffffc020128c:	920ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201290:	00001617          	auipc	a2,0x1
ffffffffc0201294:	26060613          	addi	a2,a2,608 # ffffffffc02024f0 <buddy_system_pmm_manager+0x1f0>
ffffffffc0201298:	0ae00593          	li	a1,174
ffffffffc020129c:	00001517          	auipc	a0,0x1
ffffffffc02012a0:	27c50513          	addi	a0,a0,636 # ffffffffc0202518 <buddy_system_pmm_manager+0x218>
ffffffffc02012a4:	908ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc02012a8 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02012a8:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02012ac:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02012ae:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02012b2:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02012b4:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02012b8:	f022                	sd	s0,32(sp)
ffffffffc02012ba:	ec26                	sd	s1,24(sp)
ffffffffc02012bc:	e84a                	sd	s2,16(sp)
ffffffffc02012be:	f406                	sd	ra,40(sp)
ffffffffc02012c0:	e44e                	sd	s3,8(sp)
ffffffffc02012c2:	84aa                	mv	s1,a0
ffffffffc02012c4:	892e                	mv	s2,a1
ffffffffc02012c6:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02012ca:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
ffffffffc02012cc:	03067e63          	bleu	a6,a2,ffffffffc0201308 <printnum+0x60>
ffffffffc02012d0:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02012d2:	00805763          	blez	s0,ffffffffc02012e0 <printnum+0x38>
ffffffffc02012d6:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02012d8:	85ca                	mv	a1,s2
ffffffffc02012da:	854e                	mv	a0,s3
ffffffffc02012dc:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02012de:	fc65                	bnez	s0,ffffffffc02012d6 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02012e0:	1a02                	slli	s4,s4,0x20
ffffffffc02012e2:	020a5a13          	srli	s4,s4,0x20
ffffffffc02012e6:	00001797          	auipc	a5,0x1
ffffffffc02012ea:	58a78793          	addi	a5,a5,1418 # ffffffffc0202870 <error_string+0x38>
ffffffffc02012ee:	9a3e                	add	s4,s4,a5
}
ffffffffc02012f0:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02012f2:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02012f6:	70a2                	ld	ra,40(sp)
ffffffffc02012f8:	69a2                	ld	s3,8(sp)
ffffffffc02012fa:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02012fc:	85ca                	mv	a1,s2
ffffffffc02012fe:	8326                	mv	t1,s1
}
ffffffffc0201300:	6942                	ld	s2,16(sp)
ffffffffc0201302:	64e2                	ld	s1,24(sp)
ffffffffc0201304:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201306:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201308:	03065633          	divu	a2,a2,a6
ffffffffc020130c:	8722                	mv	a4,s0
ffffffffc020130e:	f9bff0ef          	jal	ra,ffffffffc02012a8 <printnum>
ffffffffc0201312:	b7f9                	j	ffffffffc02012e0 <printnum+0x38>

ffffffffc0201314 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201314:	7119                	addi	sp,sp,-128
ffffffffc0201316:	f4a6                	sd	s1,104(sp)
ffffffffc0201318:	f0ca                	sd	s2,96(sp)
ffffffffc020131a:	e8d2                	sd	s4,80(sp)
ffffffffc020131c:	e4d6                	sd	s5,72(sp)
ffffffffc020131e:	e0da                	sd	s6,64(sp)
ffffffffc0201320:	fc5e                	sd	s7,56(sp)
ffffffffc0201322:	f862                	sd	s8,48(sp)
ffffffffc0201324:	f06a                	sd	s10,32(sp)
ffffffffc0201326:	fc86                	sd	ra,120(sp)
ffffffffc0201328:	f8a2                	sd	s0,112(sp)
ffffffffc020132a:	ecce                	sd	s3,88(sp)
ffffffffc020132c:	f466                	sd	s9,40(sp)
ffffffffc020132e:	ec6e                	sd	s11,24(sp)
ffffffffc0201330:	892a                	mv	s2,a0
ffffffffc0201332:	84ae                	mv	s1,a1
ffffffffc0201334:	8d32                	mv	s10,a2
ffffffffc0201336:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201338:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020133a:	00001a17          	auipc	s4,0x1
ffffffffc020133e:	3a6a0a13          	addi	s4,s4,934 # ffffffffc02026e0 <buddy_system_pmm_manager+0x3e0>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201342:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201346:	00001c17          	auipc	s8,0x1
ffffffffc020134a:	4f2c0c13          	addi	s8,s8,1266 # ffffffffc0202838 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020134e:	000d4503          	lbu	a0,0(s10)
ffffffffc0201352:	02500793          	li	a5,37
ffffffffc0201356:	001d0413          	addi	s0,s10,1
ffffffffc020135a:	00f50e63          	beq	a0,a5,ffffffffc0201376 <vprintfmt+0x62>
            if (ch == '\0') {
ffffffffc020135e:	c521                	beqz	a0,ffffffffc02013a6 <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201360:	02500993          	li	s3,37
ffffffffc0201364:	a011                	j	ffffffffc0201368 <vprintfmt+0x54>
            if (ch == '\0') {
ffffffffc0201366:	c121                	beqz	a0,ffffffffc02013a6 <vprintfmt+0x92>
            putch(ch, putdat);
ffffffffc0201368:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020136a:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc020136c:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020136e:	fff44503          	lbu	a0,-1(s0) # fffffffffff7ffff <end+0x3fd79a97>
ffffffffc0201372:	ff351ae3          	bne	a0,s3,ffffffffc0201366 <vprintfmt+0x52>
ffffffffc0201376:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc020137a:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc020137e:	4981                	li	s3,0
ffffffffc0201380:	4801                	li	a6,0
        width = precision = -1;
ffffffffc0201382:	5cfd                	li	s9,-1
ffffffffc0201384:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201386:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
ffffffffc020138a:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020138c:	fdd6069b          	addiw	a3,a2,-35
ffffffffc0201390:	0ff6f693          	andi	a3,a3,255
ffffffffc0201394:	00140d13          	addi	s10,s0,1
ffffffffc0201398:	20d5e563          	bltu	a1,a3,ffffffffc02015a2 <vprintfmt+0x28e>
ffffffffc020139c:	068a                	slli	a3,a3,0x2
ffffffffc020139e:	96d2                	add	a3,a3,s4
ffffffffc02013a0:	4294                	lw	a3,0(a3)
ffffffffc02013a2:	96d2                	add	a3,a3,s4
ffffffffc02013a4:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02013a6:	70e6                	ld	ra,120(sp)
ffffffffc02013a8:	7446                	ld	s0,112(sp)
ffffffffc02013aa:	74a6                	ld	s1,104(sp)
ffffffffc02013ac:	7906                	ld	s2,96(sp)
ffffffffc02013ae:	69e6                	ld	s3,88(sp)
ffffffffc02013b0:	6a46                	ld	s4,80(sp)
ffffffffc02013b2:	6aa6                	ld	s5,72(sp)
ffffffffc02013b4:	6b06                	ld	s6,64(sp)
ffffffffc02013b6:	7be2                	ld	s7,56(sp)
ffffffffc02013b8:	7c42                	ld	s8,48(sp)
ffffffffc02013ba:	7ca2                	ld	s9,40(sp)
ffffffffc02013bc:	7d02                	ld	s10,32(sp)
ffffffffc02013be:	6de2                	ld	s11,24(sp)
ffffffffc02013c0:	6109                	addi	sp,sp,128
ffffffffc02013c2:	8082                	ret
    if (lflag >= 2) {
ffffffffc02013c4:	4705                	li	a4,1
ffffffffc02013c6:	008a8593          	addi	a1,s5,8
ffffffffc02013ca:	01074463          	blt	a4,a6,ffffffffc02013d2 <vprintfmt+0xbe>
    else if (lflag) {
ffffffffc02013ce:	26080363          	beqz	a6,ffffffffc0201634 <vprintfmt+0x320>
        return va_arg(*ap, unsigned long);
ffffffffc02013d2:	000ab603          	ld	a2,0(s5)
ffffffffc02013d6:	46c1                	li	a3,16
ffffffffc02013d8:	8aae                	mv	s5,a1
ffffffffc02013da:	a06d                	j	ffffffffc0201484 <vprintfmt+0x170>
            goto reswitch;
ffffffffc02013dc:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02013e0:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013e2:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02013e4:	b765                	j	ffffffffc020138c <vprintfmt+0x78>
            putch(va_arg(ap, int), putdat);
ffffffffc02013e6:	000aa503          	lw	a0,0(s5)
ffffffffc02013ea:	85a6                	mv	a1,s1
ffffffffc02013ec:	0aa1                	addi	s5,s5,8
ffffffffc02013ee:	9902                	jalr	s2
            break;
ffffffffc02013f0:	bfb9                	j	ffffffffc020134e <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02013f2:	4705                	li	a4,1
ffffffffc02013f4:	008a8993          	addi	s3,s5,8
ffffffffc02013f8:	01074463          	blt	a4,a6,ffffffffc0201400 <vprintfmt+0xec>
    else if (lflag) {
ffffffffc02013fc:	22080463          	beqz	a6,ffffffffc0201624 <vprintfmt+0x310>
        return va_arg(*ap, long);
ffffffffc0201400:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
ffffffffc0201404:	24044463          	bltz	s0,ffffffffc020164c <vprintfmt+0x338>
            num = getint(&ap, lflag);
ffffffffc0201408:	8622                	mv	a2,s0
ffffffffc020140a:	8ace                	mv	s5,s3
ffffffffc020140c:	46a9                	li	a3,10
ffffffffc020140e:	a89d                	j	ffffffffc0201484 <vprintfmt+0x170>
            err = va_arg(ap, int);
ffffffffc0201410:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201414:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201416:	0aa1                	addi	s5,s5,8
            if (err < 0) {
ffffffffc0201418:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc020141c:	8fb5                	xor	a5,a5,a3
ffffffffc020141e:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201422:	1ad74363          	blt	a4,a3,ffffffffc02015c8 <vprintfmt+0x2b4>
ffffffffc0201426:	00369793          	slli	a5,a3,0x3
ffffffffc020142a:	97e2                	add	a5,a5,s8
ffffffffc020142c:	639c                	ld	a5,0(a5)
ffffffffc020142e:	18078d63          	beqz	a5,ffffffffc02015c8 <vprintfmt+0x2b4>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201432:	86be                	mv	a3,a5
ffffffffc0201434:	00001617          	auipc	a2,0x1
ffffffffc0201438:	4ec60613          	addi	a2,a2,1260 # ffffffffc0202920 <error_string+0xe8>
ffffffffc020143c:	85a6                	mv	a1,s1
ffffffffc020143e:	854a                	mv	a0,s2
ffffffffc0201440:	240000ef          	jal	ra,ffffffffc0201680 <printfmt>
ffffffffc0201444:	b729                	j	ffffffffc020134e <vprintfmt+0x3a>
            lflag ++;
ffffffffc0201446:	00144603          	lbu	a2,1(s0)
ffffffffc020144a:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020144c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020144e:	bf3d                	j	ffffffffc020138c <vprintfmt+0x78>
    if (lflag >= 2) {
ffffffffc0201450:	4705                	li	a4,1
ffffffffc0201452:	008a8593          	addi	a1,s5,8
ffffffffc0201456:	01074463          	blt	a4,a6,ffffffffc020145e <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc020145a:	1e080263          	beqz	a6,ffffffffc020163e <vprintfmt+0x32a>
        return va_arg(*ap, unsigned long);
ffffffffc020145e:	000ab603          	ld	a2,0(s5)
ffffffffc0201462:	46a1                	li	a3,8
ffffffffc0201464:	8aae                	mv	s5,a1
ffffffffc0201466:	a839                	j	ffffffffc0201484 <vprintfmt+0x170>
            putch('0', putdat);
ffffffffc0201468:	03000513          	li	a0,48
ffffffffc020146c:	85a6                	mv	a1,s1
ffffffffc020146e:	e03e                	sd	a5,0(sp)
ffffffffc0201470:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201472:	85a6                	mv	a1,s1
ffffffffc0201474:	07800513          	li	a0,120
ffffffffc0201478:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020147a:	0aa1                	addi	s5,s5,8
ffffffffc020147c:	ff8ab603          	ld	a2,-8(s5)
            goto number;
ffffffffc0201480:	6782                	ld	a5,0(sp)
ffffffffc0201482:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201484:	876e                	mv	a4,s11
ffffffffc0201486:	85a6                	mv	a1,s1
ffffffffc0201488:	854a                	mv	a0,s2
ffffffffc020148a:	e1fff0ef          	jal	ra,ffffffffc02012a8 <printnum>
            break;
ffffffffc020148e:	b5c1                	j	ffffffffc020134e <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201490:	000ab603          	ld	a2,0(s5)
ffffffffc0201494:	0aa1                	addi	s5,s5,8
ffffffffc0201496:	1c060663          	beqz	a2,ffffffffc0201662 <vprintfmt+0x34e>
            if (width > 0 && padc != '-') {
ffffffffc020149a:	00160413          	addi	s0,a2,1
ffffffffc020149e:	17b05c63          	blez	s11,ffffffffc0201616 <vprintfmt+0x302>
ffffffffc02014a2:	02d00593          	li	a1,45
ffffffffc02014a6:	14b79263          	bne	a5,a1,ffffffffc02015ea <vprintfmt+0x2d6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02014aa:	00064783          	lbu	a5,0(a2)
ffffffffc02014ae:	0007851b          	sext.w	a0,a5
ffffffffc02014b2:	c905                	beqz	a0,ffffffffc02014e2 <vprintfmt+0x1ce>
ffffffffc02014b4:	000cc563          	bltz	s9,ffffffffc02014be <vprintfmt+0x1aa>
ffffffffc02014b8:	3cfd                	addiw	s9,s9,-1
ffffffffc02014ba:	036c8263          	beq	s9,s6,ffffffffc02014de <vprintfmt+0x1ca>
                    putch('?', putdat);
ffffffffc02014be:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02014c0:	18098463          	beqz	s3,ffffffffc0201648 <vprintfmt+0x334>
ffffffffc02014c4:	3781                	addiw	a5,a5,-32
ffffffffc02014c6:	18fbf163          	bleu	a5,s7,ffffffffc0201648 <vprintfmt+0x334>
                    putch('?', putdat);
ffffffffc02014ca:	03f00513          	li	a0,63
ffffffffc02014ce:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02014d0:	0405                	addi	s0,s0,1
ffffffffc02014d2:	fff44783          	lbu	a5,-1(s0)
ffffffffc02014d6:	3dfd                	addiw	s11,s11,-1
ffffffffc02014d8:	0007851b          	sext.w	a0,a5
ffffffffc02014dc:	fd61                	bnez	a0,ffffffffc02014b4 <vprintfmt+0x1a0>
            for (; width > 0; width --) {
ffffffffc02014de:	e7b058e3          	blez	s11,ffffffffc020134e <vprintfmt+0x3a>
ffffffffc02014e2:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02014e4:	85a6                	mv	a1,s1
ffffffffc02014e6:	02000513          	li	a0,32
ffffffffc02014ea:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02014ec:	e60d81e3          	beqz	s11,ffffffffc020134e <vprintfmt+0x3a>
ffffffffc02014f0:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02014f2:	85a6                	mv	a1,s1
ffffffffc02014f4:	02000513          	li	a0,32
ffffffffc02014f8:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02014fa:	fe0d94e3          	bnez	s11,ffffffffc02014e2 <vprintfmt+0x1ce>
ffffffffc02014fe:	bd81                	j	ffffffffc020134e <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201500:	4705                	li	a4,1
ffffffffc0201502:	008a8593          	addi	a1,s5,8
ffffffffc0201506:	01074463          	blt	a4,a6,ffffffffc020150e <vprintfmt+0x1fa>
    else if (lflag) {
ffffffffc020150a:	12080063          	beqz	a6,ffffffffc020162a <vprintfmt+0x316>
        return va_arg(*ap, unsigned long);
ffffffffc020150e:	000ab603          	ld	a2,0(s5)
ffffffffc0201512:	46a9                	li	a3,10
ffffffffc0201514:	8aae                	mv	s5,a1
ffffffffc0201516:	b7bd                	j	ffffffffc0201484 <vprintfmt+0x170>
ffffffffc0201518:	00144603          	lbu	a2,1(s0)
            padc = '-';
ffffffffc020151c:	02d00793          	li	a5,45
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201520:	846a                	mv	s0,s10
ffffffffc0201522:	b5ad                	j	ffffffffc020138c <vprintfmt+0x78>
            putch(ch, putdat);
ffffffffc0201524:	85a6                	mv	a1,s1
ffffffffc0201526:	02500513          	li	a0,37
ffffffffc020152a:	9902                	jalr	s2
            break;
ffffffffc020152c:	b50d                	j	ffffffffc020134e <vprintfmt+0x3a>
            precision = va_arg(ap, int);
ffffffffc020152e:	000aac83          	lw	s9,0(s5)
            goto process_precision;
ffffffffc0201532:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201536:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201538:	846a                	mv	s0,s10
            if (width < 0)
ffffffffc020153a:	e40dd9e3          	bgez	s11,ffffffffc020138c <vprintfmt+0x78>
                width = precision, precision = -1;
ffffffffc020153e:	8de6                	mv	s11,s9
ffffffffc0201540:	5cfd                	li	s9,-1
ffffffffc0201542:	b5a9                	j	ffffffffc020138c <vprintfmt+0x78>
            goto reswitch;
ffffffffc0201544:	00144603          	lbu	a2,1(s0)
            padc = '0';
ffffffffc0201548:	03000793          	li	a5,48
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020154c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020154e:	bd3d                	j	ffffffffc020138c <vprintfmt+0x78>
                precision = precision * 10 + ch - '0';
ffffffffc0201550:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
ffffffffc0201554:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201558:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc020155a:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc020155e:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201562:	fcd56ce3          	bltu	a0,a3,ffffffffc020153a <vprintfmt+0x226>
            for (precision = 0; ; ++ fmt) {
ffffffffc0201566:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201568:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
ffffffffc020156c:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201570:	0196873b          	addw	a4,a3,s9
ffffffffc0201574:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201578:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
ffffffffc020157c:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
ffffffffc0201580:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0201584:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201588:	fcd57fe3          	bleu	a3,a0,ffffffffc0201566 <vprintfmt+0x252>
ffffffffc020158c:	b77d                	j	ffffffffc020153a <vprintfmt+0x226>
            if (width < 0)
ffffffffc020158e:	fffdc693          	not	a3,s11
ffffffffc0201592:	96fd                	srai	a3,a3,0x3f
ffffffffc0201594:	00ddfdb3          	and	s11,s11,a3
ffffffffc0201598:	00144603          	lbu	a2,1(s0)
ffffffffc020159c:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020159e:	846a                	mv	s0,s10
ffffffffc02015a0:	b3f5                	j	ffffffffc020138c <vprintfmt+0x78>
            putch('%', putdat);
ffffffffc02015a2:	85a6                	mv	a1,s1
ffffffffc02015a4:	02500513          	li	a0,37
ffffffffc02015a8:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02015aa:	fff44703          	lbu	a4,-1(s0)
ffffffffc02015ae:	02500793          	li	a5,37
ffffffffc02015b2:	8d22                	mv	s10,s0
ffffffffc02015b4:	d8f70de3          	beq	a4,a5,ffffffffc020134e <vprintfmt+0x3a>
ffffffffc02015b8:	02500713          	li	a4,37
ffffffffc02015bc:	1d7d                	addi	s10,s10,-1
ffffffffc02015be:	fffd4783          	lbu	a5,-1(s10)
ffffffffc02015c2:	fee79de3          	bne	a5,a4,ffffffffc02015bc <vprintfmt+0x2a8>
ffffffffc02015c6:	b361                	j	ffffffffc020134e <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02015c8:	00001617          	auipc	a2,0x1
ffffffffc02015cc:	34860613          	addi	a2,a2,840 # ffffffffc0202910 <error_string+0xd8>
ffffffffc02015d0:	85a6                	mv	a1,s1
ffffffffc02015d2:	854a                	mv	a0,s2
ffffffffc02015d4:	0ac000ef          	jal	ra,ffffffffc0201680 <printfmt>
ffffffffc02015d8:	bb9d                	j	ffffffffc020134e <vprintfmt+0x3a>
                p = "(null)";
ffffffffc02015da:	00001617          	auipc	a2,0x1
ffffffffc02015de:	32e60613          	addi	a2,a2,814 # ffffffffc0202908 <error_string+0xd0>
            if (width > 0 && padc != '-') {
ffffffffc02015e2:	00001417          	auipc	s0,0x1
ffffffffc02015e6:	32740413          	addi	s0,s0,807 # ffffffffc0202909 <error_string+0xd1>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02015ea:	8532                	mv	a0,a2
ffffffffc02015ec:	85e6                	mv	a1,s9
ffffffffc02015ee:	e032                	sd	a2,0(sp)
ffffffffc02015f0:	e43e                	sd	a5,8(sp)
ffffffffc02015f2:	1de000ef          	jal	ra,ffffffffc02017d0 <strnlen>
ffffffffc02015f6:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02015fa:	6602                	ld	a2,0(sp)
ffffffffc02015fc:	01b05d63          	blez	s11,ffffffffc0201616 <vprintfmt+0x302>
ffffffffc0201600:	67a2                	ld	a5,8(sp)
ffffffffc0201602:	2781                	sext.w	a5,a5
ffffffffc0201604:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
ffffffffc0201606:	6522                	ld	a0,8(sp)
ffffffffc0201608:	85a6                	mv	a1,s1
ffffffffc020160a:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020160c:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc020160e:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201610:	6602                	ld	a2,0(sp)
ffffffffc0201612:	fe0d9ae3          	bnez	s11,ffffffffc0201606 <vprintfmt+0x2f2>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201616:	00064783          	lbu	a5,0(a2)
ffffffffc020161a:	0007851b          	sext.w	a0,a5
ffffffffc020161e:	e8051be3          	bnez	a0,ffffffffc02014b4 <vprintfmt+0x1a0>
ffffffffc0201622:	b335                	j	ffffffffc020134e <vprintfmt+0x3a>
        return va_arg(*ap, int);
ffffffffc0201624:	000aa403          	lw	s0,0(s5)
ffffffffc0201628:	bbf1                	j	ffffffffc0201404 <vprintfmt+0xf0>
        return va_arg(*ap, unsigned int);
ffffffffc020162a:	000ae603          	lwu	a2,0(s5)
ffffffffc020162e:	46a9                	li	a3,10
ffffffffc0201630:	8aae                	mv	s5,a1
ffffffffc0201632:	bd89                	j	ffffffffc0201484 <vprintfmt+0x170>
ffffffffc0201634:	000ae603          	lwu	a2,0(s5)
ffffffffc0201638:	46c1                	li	a3,16
ffffffffc020163a:	8aae                	mv	s5,a1
ffffffffc020163c:	b5a1                	j	ffffffffc0201484 <vprintfmt+0x170>
ffffffffc020163e:	000ae603          	lwu	a2,0(s5)
ffffffffc0201642:	46a1                	li	a3,8
ffffffffc0201644:	8aae                	mv	s5,a1
ffffffffc0201646:	bd3d                	j	ffffffffc0201484 <vprintfmt+0x170>
                    putch(ch, putdat);
ffffffffc0201648:	9902                	jalr	s2
ffffffffc020164a:	b559                	j	ffffffffc02014d0 <vprintfmt+0x1bc>
                putch('-', putdat);
ffffffffc020164c:	85a6                	mv	a1,s1
ffffffffc020164e:	02d00513          	li	a0,45
ffffffffc0201652:	e03e                	sd	a5,0(sp)
ffffffffc0201654:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201656:	8ace                	mv	s5,s3
ffffffffc0201658:	40800633          	neg	a2,s0
ffffffffc020165c:	46a9                	li	a3,10
ffffffffc020165e:	6782                	ld	a5,0(sp)
ffffffffc0201660:	b515                	j	ffffffffc0201484 <vprintfmt+0x170>
            if (width > 0 && padc != '-') {
ffffffffc0201662:	01b05663          	blez	s11,ffffffffc020166e <vprintfmt+0x35a>
ffffffffc0201666:	02d00693          	li	a3,45
ffffffffc020166a:	f6d798e3          	bne	a5,a3,ffffffffc02015da <vprintfmt+0x2c6>
ffffffffc020166e:	00001417          	auipc	s0,0x1
ffffffffc0201672:	29b40413          	addi	s0,s0,667 # ffffffffc0202909 <error_string+0xd1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201676:	02800513          	li	a0,40
ffffffffc020167a:	02800793          	li	a5,40
ffffffffc020167e:	bd1d                	j	ffffffffc02014b4 <vprintfmt+0x1a0>

ffffffffc0201680 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201680:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201682:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201686:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201688:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020168a:	ec06                	sd	ra,24(sp)
ffffffffc020168c:	f83a                	sd	a4,48(sp)
ffffffffc020168e:	fc3e                	sd	a5,56(sp)
ffffffffc0201690:	e0c2                	sd	a6,64(sp)
ffffffffc0201692:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201694:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201696:	c7fff0ef          	jal	ra,ffffffffc0201314 <vprintfmt>
}
ffffffffc020169a:	60e2                	ld	ra,24(sp)
ffffffffc020169c:	6161                	addi	sp,sp,80
ffffffffc020169e:	8082                	ret

ffffffffc02016a0 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02016a0:	715d                	addi	sp,sp,-80
ffffffffc02016a2:	e486                	sd	ra,72(sp)
ffffffffc02016a4:	e0a2                	sd	s0,64(sp)
ffffffffc02016a6:	fc26                	sd	s1,56(sp)
ffffffffc02016a8:	f84a                	sd	s2,48(sp)
ffffffffc02016aa:	f44e                	sd	s3,40(sp)
ffffffffc02016ac:	f052                	sd	s4,32(sp)
ffffffffc02016ae:	ec56                	sd	s5,24(sp)
ffffffffc02016b0:	e85a                	sd	s6,16(sp)
ffffffffc02016b2:	e45e                	sd	s7,8(sp)
    if (prompt != NULL) {
ffffffffc02016b4:	c901                	beqz	a0,ffffffffc02016c4 <readline+0x24>
        cprintf("%s", prompt);
ffffffffc02016b6:	85aa                	mv	a1,a0
ffffffffc02016b8:	00001517          	auipc	a0,0x1
ffffffffc02016bc:	26850513          	addi	a0,a0,616 # ffffffffc0202920 <error_string+0xe8>
ffffffffc02016c0:	9f7fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
readline(const char *prompt) {
ffffffffc02016c4:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02016c6:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02016c8:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02016ca:	4aa9                	li	s5,10
ffffffffc02016cc:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02016ce:	00005b97          	auipc	s7,0x5
ffffffffc02016d2:	94ab8b93          	addi	s7,s7,-1718 # ffffffffc0206018 <edata>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02016d6:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02016da:	a55fe0ef          	jal	ra,ffffffffc020012e <getchar>
ffffffffc02016de:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc02016e0:	00054b63          	bltz	a0,ffffffffc02016f6 <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02016e4:	00a95b63          	ble	a0,s2,ffffffffc02016fa <readline+0x5a>
ffffffffc02016e8:	029a5463          	ble	s1,s4,ffffffffc0201710 <readline+0x70>
        c = getchar();
ffffffffc02016ec:	a43fe0ef          	jal	ra,ffffffffc020012e <getchar>
ffffffffc02016f0:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc02016f2:	fe0559e3          	bgez	a0,ffffffffc02016e4 <readline+0x44>
            return NULL;
ffffffffc02016f6:	4501                	li	a0,0
ffffffffc02016f8:	a099                	j	ffffffffc020173e <readline+0x9e>
        else if (c == '\b' && i > 0) {
ffffffffc02016fa:	03341463          	bne	s0,s3,ffffffffc0201722 <readline+0x82>
ffffffffc02016fe:	e8b9                	bnez	s1,ffffffffc0201754 <readline+0xb4>
        c = getchar();
ffffffffc0201700:	a2ffe0ef          	jal	ra,ffffffffc020012e <getchar>
ffffffffc0201704:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0201706:	fe0548e3          	bltz	a0,ffffffffc02016f6 <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020170a:	fea958e3          	ble	a0,s2,ffffffffc02016fa <readline+0x5a>
ffffffffc020170e:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201710:	8522                	mv	a0,s0
ffffffffc0201712:	9d9fe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            buf[i ++] = c;
ffffffffc0201716:	009b87b3          	add	a5,s7,s1
ffffffffc020171a:	00878023          	sb	s0,0(a5)
ffffffffc020171e:	2485                	addiw	s1,s1,1
ffffffffc0201720:	bf6d                	j	ffffffffc02016da <readline+0x3a>
        else if (c == '\n' || c == '\r') {
ffffffffc0201722:	01540463          	beq	s0,s5,ffffffffc020172a <readline+0x8a>
ffffffffc0201726:	fb641ae3          	bne	s0,s6,ffffffffc02016da <readline+0x3a>
            cputchar(c);
ffffffffc020172a:	8522                	mv	a0,s0
ffffffffc020172c:	9bffe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            buf[i] = '\0';
ffffffffc0201730:	00005517          	auipc	a0,0x5
ffffffffc0201734:	8e850513          	addi	a0,a0,-1816 # ffffffffc0206018 <edata>
ffffffffc0201738:	94aa                	add	s1,s1,a0
ffffffffc020173a:	00048023          	sb	zero,0(s1) # ffffffffc0200000 <kern_entry>
            return buf;
        }
    }
}
ffffffffc020173e:	60a6                	ld	ra,72(sp)
ffffffffc0201740:	6406                	ld	s0,64(sp)
ffffffffc0201742:	74e2                	ld	s1,56(sp)
ffffffffc0201744:	7942                	ld	s2,48(sp)
ffffffffc0201746:	79a2                	ld	s3,40(sp)
ffffffffc0201748:	7a02                	ld	s4,32(sp)
ffffffffc020174a:	6ae2                	ld	s5,24(sp)
ffffffffc020174c:	6b42                	ld	s6,16(sp)
ffffffffc020174e:	6ba2                	ld	s7,8(sp)
ffffffffc0201750:	6161                	addi	sp,sp,80
ffffffffc0201752:	8082                	ret
            cputchar(c);
ffffffffc0201754:	4521                	li	a0,8
ffffffffc0201756:	995fe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            i --;
ffffffffc020175a:	34fd                	addiw	s1,s1,-1
ffffffffc020175c:	bfbd                	j	ffffffffc02016da <readline+0x3a>

ffffffffc020175e <sbi_console_putchar>:
    return ret_val;
}

void sbi_console_putchar(unsigned char ch)
{
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
ffffffffc020175e:	00005797          	auipc	a5,0x5
ffffffffc0201762:	8aa78793          	addi	a5,a5,-1878 # ffffffffc0206008 <SBI_CONSOLE_PUTCHAR>
    __asm__ volatile(
ffffffffc0201766:	6398                	ld	a4,0(a5)
ffffffffc0201768:	4781                	li	a5,0
ffffffffc020176a:	88ba                	mv	a7,a4
ffffffffc020176c:	852a                	mv	a0,a0
ffffffffc020176e:	85be                	mv	a1,a5
ffffffffc0201770:	863e                	mv	a2,a5
ffffffffc0201772:	00000073          	ecall
ffffffffc0201776:	87aa                	mv	a5,a0
}
ffffffffc0201778:	8082                	ret

ffffffffc020177a <sbi_set_timer>:

void sbi_set_timer(unsigned long long stime_value)
{
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
ffffffffc020177a:	00005797          	auipc	a5,0x5
ffffffffc020177e:	cbe78793          	addi	a5,a5,-834 # ffffffffc0206438 <SBI_SET_TIMER>
    __asm__ volatile(
ffffffffc0201782:	6398                	ld	a4,0(a5)
ffffffffc0201784:	4781                	li	a5,0
ffffffffc0201786:	88ba                	mv	a7,a4
ffffffffc0201788:	852a                	mv	a0,a0
ffffffffc020178a:	85be                	mv	a1,a5
ffffffffc020178c:	863e                	mv	a2,a5
ffffffffc020178e:	00000073          	ecall
ffffffffc0201792:	87aa                	mv	a5,a0
}
ffffffffc0201794:	8082                	ret

ffffffffc0201796 <sbi_console_getchar>:

int sbi_console_getchar(void)
{
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
ffffffffc0201796:	00005797          	auipc	a5,0x5
ffffffffc020179a:	86a78793          	addi	a5,a5,-1942 # ffffffffc0206000 <SBI_CONSOLE_GETCHAR>
    __asm__ volatile(
ffffffffc020179e:	639c                	ld	a5,0(a5)
ffffffffc02017a0:	4501                	li	a0,0
ffffffffc02017a2:	88be                	mv	a7,a5
ffffffffc02017a4:	852a                	mv	a0,a0
ffffffffc02017a6:	85aa                	mv	a1,a0
ffffffffc02017a8:	862a                	mv	a2,a0
ffffffffc02017aa:	00000073          	ecall
ffffffffc02017ae:	852a                	mv	a0,a0
}
ffffffffc02017b0:	2501                	sext.w	a0,a0
ffffffffc02017b2:	8082                	ret

ffffffffc02017b4 <sbi_shutdown>:

void sbi_shutdown(void)
{
    sbi_call(SBI_SHUTDOWN, 0, 0, 0);
ffffffffc02017b4:	00005797          	auipc	a5,0x5
ffffffffc02017b8:	85c78793          	addi	a5,a5,-1956 # ffffffffc0206010 <SBI_SHUTDOWN>
    __asm__ volatile(
ffffffffc02017bc:	6398                	ld	a4,0(a5)
ffffffffc02017be:	4781                	li	a5,0
ffffffffc02017c0:	88ba                	mv	a7,a4
ffffffffc02017c2:	853e                	mv	a0,a5
ffffffffc02017c4:	85be                	mv	a1,a5
ffffffffc02017c6:	863e                	mv	a2,a5
ffffffffc02017c8:	00000073          	ecall
ffffffffc02017cc:	87aa                	mv	a5,a0
ffffffffc02017ce:	8082                	ret

ffffffffc02017d0 <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
ffffffffc02017d0:	c185                	beqz	a1,ffffffffc02017f0 <strnlen+0x20>
ffffffffc02017d2:	00054783          	lbu	a5,0(a0)
ffffffffc02017d6:	cf89                	beqz	a5,ffffffffc02017f0 <strnlen+0x20>
    size_t cnt = 0;
ffffffffc02017d8:	4781                	li	a5,0
ffffffffc02017da:	a021                	j	ffffffffc02017e2 <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
ffffffffc02017dc:	00074703          	lbu	a4,0(a4) # fffffffffec00000 <end+0x3e9f9a98>
ffffffffc02017e0:	c711                	beqz	a4,ffffffffc02017ec <strnlen+0x1c>
        cnt ++;
ffffffffc02017e2:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02017e4:	00f50733          	add	a4,a0,a5
ffffffffc02017e8:	fef59ae3          	bne	a1,a5,ffffffffc02017dc <strnlen+0xc>
    }
    return cnt;
}
ffffffffc02017ec:	853e                	mv	a0,a5
ffffffffc02017ee:	8082                	ret
    size_t cnt = 0;
ffffffffc02017f0:	4781                	li	a5,0
}
ffffffffc02017f2:	853e                	mv	a0,a5
ffffffffc02017f4:	8082                	ret

ffffffffc02017f6 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02017f6:	00054783          	lbu	a5,0(a0)
ffffffffc02017fa:	0005c703          	lbu	a4,0(a1) # fffffffffff80000 <end+0x3fd79a98>
ffffffffc02017fe:	cb91                	beqz	a5,ffffffffc0201812 <strcmp+0x1c>
ffffffffc0201800:	00e79c63          	bne	a5,a4,ffffffffc0201818 <strcmp+0x22>
        s1 ++, s2 ++;
ffffffffc0201804:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201806:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
ffffffffc020180a:	0585                	addi	a1,a1,1
ffffffffc020180c:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201810:	fbe5                	bnez	a5,ffffffffc0201800 <strcmp+0xa>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201812:	4501                	li	a0,0
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201814:	9d19                	subw	a0,a0,a4
ffffffffc0201816:	8082                	ret
ffffffffc0201818:	0007851b          	sext.w	a0,a5
ffffffffc020181c:	9d19                	subw	a0,a0,a4
ffffffffc020181e:	8082                	ret

ffffffffc0201820 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201820:	00054783          	lbu	a5,0(a0)
ffffffffc0201824:	cb91                	beqz	a5,ffffffffc0201838 <strchr+0x18>
        if (*s == c) {
ffffffffc0201826:	00b79563          	bne	a5,a1,ffffffffc0201830 <strchr+0x10>
ffffffffc020182a:	a809                	j	ffffffffc020183c <strchr+0x1c>
ffffffffc020182c:	00b78763          	beq	a5,a1,ffffffffc020183a <strchr+0x1a>
            return (char *)s;
        }
        s ++;
ffffffffc0201830:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201832:	00054783          	lbu	a5,0(a0)
ffffffffc0201836:	fbfd                	bnez	a5,ffffffffc020182c <strchr+0xc>
    }
    return NULL;
ffffffffc0201838:	4501                	li	a0,0
}
ffffffffc020183a:	8082                	ret
ffffffffc020183c:	8082                	ret

ffffffffc020183e <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc020183e:	ca01                	beqz	a2,ffffffffc020184e <memset+0x10>
ffffffffc0201840:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201842:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201844:	0785                	addi	a5,a5,1
ffffffffc0201846:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc020184a:	fec79de3          	bne	a5,a2,ffffffffc0201844 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc020184e:	8082                	ret
