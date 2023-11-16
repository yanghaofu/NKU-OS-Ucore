
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c02092b7          	lui	t0,0xc0209
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	01e31313          	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000c:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
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
ffffffffc0200028:	c0209137          	lui	sp,0xc0209

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc020002c:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200030:	03628293          	addi	t0,t0,54 # ffffffffc0200036 <kern_init>
    jr t0
ffffffffc0200034:	8282                	jr	t0

ffffffffc0200036 <kern_init>:


int
kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200036:	0000a517          	auipc	a0,0xa
ffffffffc020003a:	00a50513          	addi	a0,a0,10 # ffffffffc020a040 <edata>
ffffffffc020003e:	00011617          	auipc	a2,0x11
ffffffffc0200042:	55a60613          	addi	a2,a2,1370 # ffffffffc0211598 <end>
kern_init(void) {
ffffffffc0200046:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200048:	8e09                	sub	a2,a2,a0
ffffffffc020004a:	4581                	li	a1,0
kern_init(void) {
ffffffffc020004c:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004e:	6c3030ef          	jal	ra,ffffffffc0203f10 <memset>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc0200052:	00004597          	auipc	a1,0x4
ffffffffc0200056:	39e58593          	addi	a1,a1,926 # ffffffffc02043f0 <etext>
ffffffffc020005a:	00004517          	auipc	a0,0x4
ffffffffc020005e:	3b650513          	addi	a0,a0,950 # ffffffffc0204410 <etext+0x20>
ffffffffc0200062:	05c000ef          	jal	ra,ffffffffc02000be <cprintf>

    print_kerninfo();
ffffffffc0200066:	100000ef          	jal	ra,ffffffffc0200166 <print_kerninfo>

    // grade_backtrace();

    pmm_init();                 // init physical memory management
ffffffffc020006a:	73b000ef          	jal	ra,ffffffffc0200fa4 <pmm_init>

    idt_init();                 // init interrupt descriptor table
ffffffffc020006e:	504000ef          	jal	ra,ffffffffc0200572 <idt_init>

    vmm_init();                 // init virtual memory management
ffffffffc0200072:	200020ef          	jal	ra,ffffffffc0202272 <vmm_init>

    ide_init();                 // init ide devices
ffffffffc0200076:	35e000ef          	jal	ra,ffffffffc02003d4 <ide_init>
    swap_init();                // init swap
ffffffffc020007a:	099020ef          	jal	ra,ffffffffc0202912 <swap_init>

    clock_init();               // init clock interrupt
ffffffffc020007e:	3ae000ef          	jal	ra,ffffffffc020042c <clock_init>
    // intr_enable();              // enable irq interrupt



    /* do nothing */
    while (1);
ffffffffc0200082:	a001                	j	ffffffffc0200082 <kern_init+0x4c>

ffffffffc0200084 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200084:	1141                	addi	sp,sp,-16
ffffffffc0200086:	e022                	sd	s0,0(sp)
ffffffffc0200088:	e406                	sd	ra,8(sp)
ffffffffc020008a:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020008c:	3f6000ef          	jal	ra,ffffffffc0200482 <cons_putc>
    (*cnt) ++;
ffffffffc0200090:	401c                	lw	a5,0(s0)
}
ffffffffc0200092:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200094:	2785                	addiw	a5,a5,1
ffffffffc0200096:	c01c                	sw	a5,0(s0)
}
ffffffffc0200098:	6402                	ld	s0,0(sp)
ffffffffc020009a:	0141                	addi	sp,sp,16
ffffffffc020009c:	8082                	ret

ffffffffc020009e <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020009e:	1101                	addi	sp,sp,-32
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000a0:	86ae                	mv	a3,a1
ffffffffc02000a2:	862a                	mv	a2,a0
ffffffffc02000a4:	006c                	addi	a1,sp,12
ffffffffc02000a6:	00000517          	auipc	a0,0x0
ffffffffc02000aa:	fde50513          	addi	a0,a0,-34 # ffffffffc0200084 <cputch>
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000ae:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000b0:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000b2:	6f5030ef          	jal	ra,ffffffffc0203fa6 <vprintfmt>
    return cnt;
}
ffffffffc02000b6:	60e2                	ld	ra,24(sp)
ffffffffc02000b8:	4532                	lw	a0,12(sp)
ffffffffc02000ba:	6105                	addi	sp,sp,32
ffffffffc02000bc:	8082                	ret

ffffffffc02000be <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000be:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000c0:	02810313          	addi	t1,sp,40 # ffffffffc0209028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000c4:	f42e                	sd	a1,40(sp)
ffffffffc02000c6:	f832                	sd	a2,48(sp)
ffffffffc02000c8:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000ca:	862a                	mv	a2,a0
ffffffffc02000cc:	004c                	addi	a1,sp,4
ffffffffc02000ce:	00000517          	auipc	a0,0x0
ffffffffc02000d2:	fb650513          	addi	a0,a0,-74 # ffffffffc0200084 <cputch>
ffffffffc02000d6:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02000d8:	ec06                	sd	ra,24(sp)
ffffffffc02000da:	e0ba                	sd	a4,64(sp)
ffffffffc02000dc:	e4be                	sd	a5,72(sp)
ffffffffc02000de:	e8c2                	sd	a6,80(sp)
ffffffffc02000e0:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000e2:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000e4:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000e6:	6c1030ef          	jal	ra,ffffffffc0203fa6 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000ea:	60e2                	ld	ra,24(sp)
ffffffffc02000ec:	4512                	lw	a0,4(sp)
ffffffffc02000ee:	6125                	addi	sp,sp,96
ffffffffc02000f0:	8082                	ret

ffffffffc02000f2 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02000f2:	3900006f          	j	ffffffffc0200482 <cons_putc>

ffffffffc02000f6 <getchar>:
    return cnt;
}

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc02000f6:	1141                	addi	sp,sp,-16
ffffffffc02000f8:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc02000fa:	3be000ef          	jal	ra,ffffffffc02004b8 <cons_getc>
ffffffffc02000fe:	dd75                	beqz	a0,ffffffffc02000fa <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200100:	60a2                	ld	ra,8(sp)
ffffffffc0200102:	0141                	addi	sp,sp,16
ffffffffc0200104:	8082                	ret

ffffffffc0200106 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200106:	00011317          	auipc	t1,0x11
ffffffffc020010a:	33a30313          	addi	t1,t1,826 # ffffffffc0211440 <is_panic>
ffffffffc020010e:	00032303          	lw	t1,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200112:	715d                	addi	sp,sp,-80
ffffffffc0200114:	ec06                	sd	ra,24(sp)
ffffffffc0200116:	e822                	sd	s0,16(sp)
ffffffffc0200118:	f436                	sd	a3,40(sp)
ffffffffc020011a:	f83a                	sd	a4,48(sp)
ffffffffc020011c:	fc3e                	sd	a5,56(sp)
ffffffffc020011e:	e0c2                	sd	a6,64(sp)
ffffffffc0200120:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc0200122:	02031c63          	bnez	t1,ffffffffc020015a <__panic+0x54>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200126:	4785                	li	a5,1
ffffffffc0200128:	8432                	mv	s0,a2
ffffffffc020012a:	00011717          	auipc	a4,0x11
ffffffffc020012e:	30f72b23          	sw	a5,790(a4) # ffffffffc0211440 <is_panic>

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200132:	862e                	mv	a2,a1
    va_start(ap, fmt);
ffffffffc0200134:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200136:	85aa                	mv	a1,a0
ffffffffc0200138:	00004517          	auipc	a0,0x4
ffffffffc020013c:	2e050513          	addi	a0,a0,736 # ffffffffc0204418 <etext+0x28>
    va_start(ap, fmt);
ffffffffc0200140:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200142:	f7dff0ef          	jal	ra,ffffffffc02000be <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200146:	65a2                	ld	a1,8(sp)
ffffffffc0200148:	8522                	mv	a0,s0
ffffffffc020014a:	f55ff0ef          	jal	ra,ffffffffc020009e <vcprintf>
    cprintf("\n");
ffffffffc020014e:	00005517          	auipc	a0,0x5
ffffffffc0200152:	0da50513          	addi	a0,a0,218 # ffffffffc0205228 <commands+0xcf0>
ffffffffc0200156:	f69ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc020015a:	3a0000ef          	jal	ra,ffffffffc02004fa <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc020015e:	4501                	li	a0,0
ffffffffc0200160:	132000ef          	jal	ra,ffffffffc0200292 <kmonitor>
ffffffffc0200164:	bfed                	j	ffffffffc020015e <__panic+0x58>

ffffffffc0200166 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200166:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200168:	00004517          	auipc	a0,0x4
ffffffffc020016c:	30050513          	addi	a0,a0,768 # ffffffffc0204468 <etext+0x78>
void print_kerninfo(void) {
ffffffffc0200170:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200172:	f4dff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200176:	00000597          	auipc	a1,0x0
ffffffffc020017a:	ec058593          	addi	a1,a1,-320 # ffffffffc0200036 <kern_init>
ffffffffc020017e:	00004517          	auipc	a0,0x4
ffffffffc0200182:	30a50513          	addi	a0,a0,778 # ffffffffc0204488 <etext+0x98>
ffffffffc0200186:	f39ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc020018a:	00004597          	auipc	a1,0x4
ffffffffc020018e:	26658593          	addi	a1,a1,614 # ffffffffc02043f0 <etext>
ffffffffc0200192:	00004517          	auipc	a0,0x4
ffffffffc0200196:	31650513          	addi	a0,a0,790 # ffffffffc02044a8 <etext+0xb8>
ffffffffc020019a:	f25ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc020019e:	0000a597          	auipc	a1,0xa
ffffffffc02001a2:	ea258593          	addi	a1,a1,-350 # ffffffffc020a040 <edata>
ffffffffc02001a6:	00004517          	auipc	a0,0x4
ffffffffc02001aa:	32250513          	addi	a0,a0,802 # ffffffffc02044c8 <etext+0xd8>
ffffffffc02001ae:	f11ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc02001b2:	00011597          	auipc	a1,0x11
ffffffffc02001b6:	3e658593          	addi	a1,a1,998 # ffffffffc0211598 <end>
ffffffffc02001ba:	00004517          	auipc	a0,0x4
ffffffffc02001be:	32e50513          	addi	a0,a0,814 # ffffffffc02044e8 <etext+0xf8>
ffffffffc02001c2:	efdff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001c6:	00011597          	auipc	a1,0x11
ffffffffc02001ca:	7d158593          	addi	a1,a1,2001 # ffffffffc0211997 <end+0x3ff>
ffffffffc02001ce:	00000797          	auipc	a5,0x0
ffffffffc02001d2:	e6878793          	addi	a5,a5,-408 # ffffffffc0200036 <kern_init>
ffffffffc02001d6:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001da:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001de:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001e0:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001e4:	95be                	add	a1,a1,a5
ffffffffc02001e6:	85a9                	srai	a1,a1,0xa
ffffffffc02001e8:	00004517          	auipc	a0,0x4
ffffffffc02001ec:	32050513          	addi	a0,a0,800 # ffffffffc0204508 <etext+0x118>
}
ffffffffc02001f0:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001f2:	ecdff06f          	j	ffffffffc02000be <cprintf>

ffffffffc02001f6 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001f6:	1141                	addi	sp,sp,-16

    panic("Not Implemented!");
ffffffffc02001f8:	00004617          	auipc	a2,0x4
ffffffffc02001fc:	24060613          	addi	a2,a2,576 # ffffffffc0204438 <etext+0x48>
ffffffffc0200200:	04e00593          	li	a1,78
ffffffffc0200204:	00004517          	auipc	a0,0x4
ffffffffc0200208:	24c50513          	addi	a0,a0,588 # ffffffffc0204450 <etext+0x60>
void print_stackframe(void) {
ffffffffc020020c:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc020020e:	ef9ff0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc0200212 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200212:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200214:	00004617          	auipc	a2,0x4
ffffffffc0200218:	3fc60613          	addi	a2,a2,1020 # ffffffffc0204610 <commands+0xd8>
ffffffffc020021c:	00004597          	auipc	a1,0x4
ffffffffc0200220:	41458593          	addi	a1,a1,1044 # ffffffffc0204630 <commands+0xf8>
ffffffffc0200224:	00004517          	auipc	a0,0x4
ffffffffc0200228:	41450513          	addi	a0,a0,1044 # ffffffffc0204638 <commands+0x100>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020022c:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020022e:	e91ff0ef          	jal	ra,ffffffffc02000be <cprintf>
ffffffffc0200232:	00004617          	auipc	a2,0x4
ffffffffc0200236:	41660613          	addi	a2,a2,1046 # ffffffffc0204648 <commands+0x110>
ffffffffc020023a:	00004597          	auipc	a1,0x4
ffffffffc020023e:	43658593          	addi	a1,a1,1078 # ffffffffc0204670 <commands+0x138>
ffffffffc0200242:	00004517          	auipc	a0,0x4
ffffffffc0200246:	3f650513          	addi	a0,a0,1014 # ffffffffc0204638 <commands+0x100>
ffffffffc020024a:	e75ff0ef          	jal	ra,ffffffffc02000be <cprintf>
ffffffffc020024e:	00004617          	auipc	a2,0x4
ffffffffc0200252:	43260613          	addi	a2,a2,1074 # ffffffffc0204680 <commands+0x148>
ffffffffc0200256:	00004597          	auipc	a1,0x4
ffffffffc020025a:	44a58593          	addi	a1,a1,1098 # ffffffffc02046a0 <commands+0x168>
ffffffffc020025e:	00004517          	auipc	a0,0x4
ffffffffc0200262:	3da50513          	addi	a0,a0,986 # ffffffffc0204638 <commands+0x100>
ffffffffc0200266:	e59ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    }
    return 0;
}
ffffffffc020026a:	60a2                	ld	ra,8(sp)
ffffffffc020026c:	4501                	li	a0,0
ffffffffc020026e:	0141                	addi	sp,sp,16
ffffffffc0200270:	8082                	ret

ffffffffc0200272 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200272:	1141                	addi	sp,sp,-16
ffffffffc0200274:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200276:	ef1ff0ef          	jal	ra,ffffffffc0200166 <print_kerninfo>
    return 0;
}
ffffffffc020027a:	60a2                	ld	ra,8(sp)
ffffffffc020027c:	4501                	li	a0,0
ffffffffc020027e:	0141                	addi	sp,sp,16
ffffffffc0200280:	8082                	ret

ffffffffc0200282 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200282:	1141                	addi	sp,sp,-16
ffffffffc0200284:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200286:	f71ff0ef          	jal	ra,ffffffffc02001f6 <print_stackframe>
    return 0;
}
ffffffffc020028a:	60a2                	ld	ra,8(sp)
ffffffffc020028c:	4501                	li	a0,0
ffffffffc020028e:	0141                	addi	sp,sp,16
ffffffffc0200290:	8082                	ret

ffffffffc0200292 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200292:	7115                	addi	sp,sp,-224
ffffffffc0200294:	e962                	sd	s8,144(sp)
ffffffffc0200296:	8c2a                	mv	s8,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200298:	00004517          	auipc	a0,0x4
ffffffffc020029c:	2e850513          	addi	a0,a0,744 # ffffffffc0204580 <commands+0x48>
kmonitor(struct trapframe *tf) {
ffffffffc02002a0:	ed86                	sd	ra,216(sp)
ffffffffc02002a2:	e9a2                	sd	s0,208(sp)
ffffffffc02002a4:	e5a6                	sd	s1,200(sp)
ffffffffc02002a6:	e1ca                	sd	s2,192(sp)
ffffffffc02002a8:	fd4e                	sd	s3,184(sp)
ffffffffc02002aa:	f952                	sd	s4,176(sp)
ffffffffc02002ac:	f556                	sd	s5,168(sp)
ffffffffc02002ae:	f15a                	sd	s6,160(sp)
ffffffffc02002b0:	ed5e                	sd	s7,152(sp)
ffffffffc02002b2:	e566                	sd	s9,136(sp)
ffffffffc02002b4:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002b6:	e09ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02002ba:	00004517          	auipc	a0,0x4
ffffffffc02002be:	2ee50513          	addi	a0,a0,750 # ffffffffc02045a8 <commands+0x70>
ffffffffc02002c2:	dfdff0ef          	jal	ra,ffffffffc02000be <cprintf>
    if (tf != NULL) {
ffffffffc02002c6:	000c0563          	beqz	s8,ffffffffc02002d0 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002ca:	8562                	mv	a0,s8
ffffffffc02002cc:	492000ef          	jal	ra,ffffffffc020075e <print_trapframe>
ffffffffc02002d0:	00004c97          	auipc	s9,0x4
ffffffffc02002d4:	268c8c93          	addi	s9,s9,616 # ffffffffc0204538 <commands>
        if ((buf = readline("")) != NULL) {
ffffffffc02002d8:	00006997          	auipc	s3,0x6
ffffffffc02002dc:	97898993          	addi	s3,s3,-1672 # ffffffffc0205c50 <commands+0x1718>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002e0:	00004917          	auipc	s2,0x4
ffffffffc02002e4:	2f090913          	addi	s2,s2,752 # ffffffffc02045d0 <commands+0x98>
        if (argc == MAXARGS - 1) {
ffffffffc02002e8:	4a3d                	li	s4,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002ea:	00004b17          	auipc	s6,0x4
ffffffffc02002ee:	2eeb0b13          	addi	s6,s6,750 # ffffffffc02045d8 <commands+0xa0>
    if (argc == 0) {
ffffffffc02002f2:	00004a97          	auipc	s5,0x4
ffffffffc02002f6:	33ea8a93          	addi	s5,s5,830 # ffffffffc0204630 <commands+0xf8>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002fa:	4b8d                	li	s7,3
        if ((buf = readline("")) != NULL) {
ffffffffc02002fc:	854e                	mv	a0,s3
ffffffffc02002fe:	034040ef          	jal	ra,ffffffffc0204332 <readline>
ffffffffc0200302:	842a                	mv	s0,a0
ffffffffc0200304:	dd65                	beqz	a0,ffffffffc02002fc <kmonitor+0x6a>
ffffffffc0200306:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020030a:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020030c:	c999                	beqz	a1,ffffffffc0200322 <kmonitor+0x90>
ffffffffc020030e:	854a                	mv	a0,s2
ffffffffc0200310:	3e3030ef          	jal	ra,ffffffffc0203ef2 <strchr>
ffffffffc0200314:	c925                	beqz	a0,ffffffffc0200384 <kmonitor+0xf2>
            *buf ++ = '\0';
ffffffffc0200316:	00144583          	lbu	a1,1(s0)
ffffffffc020031a:	00040023          	sb	zero,0(s0)
ffffffffc020031e:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200320:	f5fd                	bnez	a1,ffffffffc020030e <kmonitor+0x7c>
    if (argc == 0) {
ffffffffc0200322:	dce9                	beqz	s1,ffffffffc02002fc <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200324:	6582                	ld	a1,0(sp)
ffffffffc0200326:	00004d17          	auipc	s10,0x4
ffffffffc020032a:	212d0d13          	addi	s10,s10,530 # ffffffffc0204538 <commands>
    if (argc == 0) {
ffffffffc020032e:	8556                	mv	a0,s5
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200330:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200332:	0d61                	addi	s10,s10,24
ffffffffc0200334:	395030ef          	jal	ra,ffffffffc0203ec8 <strcmp>
ffffffffc0200338:	c919                	beqz	a0,ffffffffc020034e <kmonitor+0xbc>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020033a:	2405                	addiw	s0,s0,1
ffffffffc020033c:	09740463          	beq	s0,s7,ffffffffc02003c4 <kmonitor+0x132>
ffffffffc0200340:	000d3503          	ld	a0,0(s10)
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200344:	6582                	ld	a1,0(sp)
ffffffffc0200346:	0d61                	addi	s10,s10,24
ffffffffc0200348:	381030ef          	jal	ra,ffffffffc0203ec8 <strcmp>
ffffffffc020034c:	f57d                	bnez	a0,ffffffffc020033a <kmonitor+0xa8>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020034e:	00141793          	slli	a5,s0,0x1
ffffffffc0200352:	97a2                	add	a5,a5,s0
ffffffffc0200354:	078e                	slli	a5,a5,0x3
ffffffffc0200356:	97e6                	add	a5,a5,s9
ffffffffc0200358:	6b9c                	ld	a5,16(a5)
ffffffffc020035a:	8662                	mv	a2,s8
ffffffffc020035c:	002c                	addi	a1,sp,8
ffffffffc020035e:	fff4851b          	addiw	a0,s1,-1
ffffffffc0200362:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200364:	f8055ce3          	bgez	a0,ffffffffc02002fc <kmonitor+0x6a>
}
ffffffffc0200368:	60ee                	ld	ra,216(sp)
ffffffffc020036a:	644e                	ld	s0,208(sp)
ffffffffc020036c:	64ae                	ld	s1,200(sp)
ffffffffc020036e:	690e                	ld	s2,192(sp)
ffffffffc0200370:	79ea                	ld	s3,184(sp)
ffffffffc0200372:	7a4a                	ld	s4,176(sp)
ffffffffc0200374:	7aaa                	ld	s5,168(sp)
ffffffffc0200376:	7b0a                	ld	s6,160(sp)
ffffffffc0200378:	6bea                	ld	s7,152(sp)
ffffffffc020037a:	6c4a                	ld	s8,144(sp)
ffffffffc020037c:	6caa                	ld	s9,136(sp)
ffffffffc020037e:	6d0a                	ld	s10,128(sp)
ffffffffc0200380:	612d                	addi	sp,sp,224
ffffffffc0200382:	8082                	ret
        if (*buf == '\0') {
ffffffffc0200384:	00044783          	lbu	a5,0(s0)
ffffffffc0200388:	dfc9                	beqz	a5,ffffffffc0200322 <kmonitor+0x90>
        if (argc == MAXARGS - 1) {
ffffffffc020038a:	03448863          	beq	s1,s4,ffffffffc02003ba <kmonitor+0x128>
        argv[argc ++] = buf;
ffffffffc020038e:	00349793          	slli	a5,s1,0x3
ffffffffc0200392:	0118                	addi	a4,sp,128
ffffffffc0200394:	97ba                	add	a5,a5,a4
ffffffffc0200396:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020039a:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc020039e:	2485                	addiw	s1,s1,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003a0:	e591                	bnez	a1,ffffffffc02003ac <kmonitor+0x11a>
ffffffffc02003a2:	b749                	j	ffffffffc0200324 <kmonitor+0x92>
            buf ++;
ffffffffc02003a4:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003a6:	00044583          	lbu	a1,0(s0)
ffffffffc02003aa:	ddad                	beqz	a1,ffffffffc0200324 <kmonitor+0x92>
ffffffffc02003ac:	854a                	mv	a0,s2
ffffffffc02003ae:	345030ef          	jal	ra,ffffffffc0203ef2 <strchr>
ffffffffc02003b2:	d96d                	beqz	a0,ffffffffc02003a4 <kmonitor+0x112>
ffffffffc02003b4:	00044583          	lbu	a1,0(s0)
ffffffffc02003b8:	bf91                	j	ffffffffc020030c <kmonitor+0x7a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003ba:	45c1                	li	a1,16
ffffffffc02003bc:	855a                	mv	a0,s6
ffffffffc02003be:	d01ff0ef          	jal	ra,ffffffffc02000be <cprintf>
ffffffffc02003c2:	b7f1                	j	ffffffffc020038e <kmonitor+0xfc>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003c4:	6582                	ld	a1,0(sp)
ffffffffc02003c6:	00004517          	auipc	a0,0x4
ffffffffc02003ca:	23250513          	addi	a0,a0,562 # ffffffffc02045f8 <commands+0xc0>
ffffffffc02003ce:	cf1ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    return 0;
ffffffffc02003d2:	b72d                	j	ffffffffc02002fc <kmonitor+0x6a>

ffffffffc02003d4 <ide_init>:
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <riscv.h>

void ide_init(void) {}
ffffffffc02003d4:	8082                	ret

ffffffffc02003d6 <ide_device_valid>:

#define MAX_IDE 2
#define MAX_DISK_NSECS 56
static char ide[MAX_DISK_NSECS * SECTSIZE];

bool ide_device_valid(unsigned short ideno) { return ideno < MAX_IDE; }
ffffffffc02003d6:	00253513          	sltiu	a0,a0,2
ffffffffc02003da:	8082                	ret

ffffffffc02003dc <ide_device_size>:

size_t ide_device_size(unsigned short ideno) { return MAX_DISK_NSECS; }
ffffffffc02003dc:	03800513          	li	a0,56
ffffffffc02003e0:	8082                	ret

ffffffffc02003e2 <ide_read_secs>:

int ide_read_secs(unsigned short ideno, uint32_t secno, void *dst,
                  size_t nsecs) {
    int iobase = secno * SECTSIZE;
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02003e2:	0000a797          	auipc	a5,0xa
ffffffffc02003e6:	c5e78793          	addi	a5,a5,-930 # ffffffffc020a040 <edata>
ffffffffc02003ea:	0095959b          	slliw	a1,a1,0x9
                  size_t nsecs) {
ffffffffc02003ee:	1141                	addi	sp,sp,-16
ffffffffc02003f0:	8532                	mv	a0,a2
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02003f2:	95be                	add	a1,a1,a5
ffffffffc02003f4:	00969613          	slli	a2,a3,0x9
                  size_t nsecs) {
ffffffffc02003f8:	e406                	sd	ra,8(sp)
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02003fa:	329030ef          	jal	ra,ffffffffc0203f22 <memcpy>
    return 0;
}
ffffffffc02003fe:	60a2                	ld	ra,8(sp)
ffffffffc0200400:	4501                	li	a0,0
ffffffffc0200402:	0141                	addi	sp,sp,16
ffffffffc0200404:	8082                	ret

ffffffffc0200406 <ide_write_secs>:

int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src,
                   size_t nsecs) {
ffffffffc0200406:	8732                	mv	a4,a2
    int iobase = secno * SECTSIZE;
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200408:	0095979b          	slliw	a5,a1,0x9
ffffffffc020040c:	0000a517          	auipc	a0,0xa
ffffffffc0200410:	c3450513          	addi	a0,a0,-972 # ffffffffc020a040 <edata>
                   size_t nsecs) {
ffffffffc0200414:	1141                	addi	sp,sp,-16
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200416:	00969613          	slli	a2,a3,0x9
ffffffffc020041a:	85ba                	mv	a1,a4
ffffffffc020041c:	953e                	add	a0,a0,a5
                   size_t nsecs) {
ffffffffc020041e:	e406                	sd	ra,8(sp)
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200420:	303030ef          	jal	ra,ffffffffc0203f22 <memcpy>
    return 0;
}
ffffffffc0200424:	60a2                	ld	ra,8(sp)
ffffffffc0200426:	4501                	li	a0,0
ffffffffc0200428:	0141                	addi	sp,sp,16
ffffffffc020042a:	8082                	ret

ffffffffc020042c <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc020042c:	67e1                	lui	a5,0x18
ffffffffc020042e:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0xffffffffc01e7960>
ffffffffc0200432:	00011717          	auipc	a4,0x11
ffffffffc0200436:	00f73b23          	sd	a5,22(a4) # ffffffffc0211448 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020043a:	c0102573          	rdtime	a0
static inline void sbi_set_timer(uint64_t stime_value)
{
#if __riscv_xlen == 32
	SBI_CALL_2(SBI_SET_TIMER, stime_value, stime_value >> 32);
#else
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc020043e:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200440:	953e                	add	a0,a0,a5
ffffffffc0200442:	4601                	li	a2,0
ffffffffc0200444:	4881                	li	a7,0
ffffffffc0200446:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc020044a:	02000793          	li	a5,32
ffffffffc020044e:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc0200452:	00004517          	auipc	a0,0x4
ffffffffc0200456:	25e50513          	addi	a0,a0,606 # ffffffffc02046b0 <commands+0x178>
    ticks = 0;
ffffffffc020045a:	00011797          	auipc	a5,0x11
ffffffffc020045e:	0007bf23          	sd	zero,30(a5) # ffffffffc0211478 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200462:	c5dff06f          	j	ffffffffc02000be <cprintf>

ffffffffc0200466 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200466:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020046a:	00011797          	auipc	a5,0x11
ffffffffc020046e:	fde78793          	addi	a5,a5,-34 # ffffffffc0211448 <timebase>
ffffffffc0200472:	639c                	ld	a5,0(a5)
ffffffffc0200474:	4581                	li	a1,0
ffffffffc0200476:	4601                	li	a2,0
ffffffffc0200478:	953e                	add	a0,a0,a5
ffffffffc020047a:	4881                	li	a7,0
ffffffffc020047c:	00000073          	ecall
ffffffffc0200480:	8082                	ret

ffffffffc0200482 <cons_putc>:
#include <intr.h>
#include <mmu.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200482:	100027f3          	csrr	a5,sstatus
ffffffffc0200486:	8b89                	andi	a5,a5,2
ffffffffc0200488:	0ff57513          	andi	a0,a0,255
ffffffffc020048c:	e799                	bnez	a5,ffffffffc020049a <cons_putc+0x18>
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc020048e:	4581                	li	a1,0
ffffffffc0200490:	4601                	li	a2,0
ffffffffc0200492:	4885                	li	a7,1
ffffffffc0200494:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc0200498:	8082                	ret

/* cons_init - initializes the console devices */
void cons_init(void) {}

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc020049a:	1101                	addi	sp,sp,-32
ffffffffc020049c:	ec06                	sd	ra,24(sp)
ffffffffc020049e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02004a0:	05a000ef          	jal	ra,ffffffffc02004fa <intr_disable>
ffffffffc02004a4:	6522                	ld	a0,8(sp)
ffffffffc02004a6:	4581                	li	a1,0
ffffffffc02004a8:	4601                	li	a2,0
ffffffffc02004aa:	4885                	li	a7,1
ffffffffc02004ac:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02004b0:	60e2                	ld	ra,24(sp)
ffffffffc02004b2:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02004b4:	0400006f          	j	ffffffffc02004f4 <intr_enable>

ffffffffc02004b8 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02004b8:	100027f3          	csrr	a5,sstatus
ffffffffc02004bc:	8b89                	andi	a5,a5,2
ffffffffc02004be:	eb89                	bnez	a5,ffffffffc02004d0 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02004c0:	4501                	li	a0,0
ffffffffc02004c2:	4581                	li	a1,0
ffffffffc02004c4:	4601                	li	a2,0
ffffffffc02004c6:	4889                	li	a7,2
ffffffffc02004c8:	00000073          	ecall
ffffffffc02004cc:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc02004ce:	8082                	ret
int cons_getc(void) {
ffffffffc02004d0:	1101                	addi	sp,sp,-32
ffffffffc02004d2:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02004d4:	026000ef          	jal	ra,ffffffffc02004fa <intr_disable>
ffffffffc02004d8:	4501                	li	a0,0
ffffffffc02004da:	4581                	li	a1,0
ffffffffc02004dc:	4601                	li	a2,0
ffffffffc02004de:	4889                	li	a7,2
ffffffffc02004e0:	00000073          	ecall
ffffffffc02004e4:	2501                	sext.w	a0,a0
ffffffffc02004e6:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02004e8:	00c000ef          	jal	ra,ffffffffc02004f4 <intr_enable>
}
ffffffffc02004ec:	60e2                	ld	ra,24(sp)
ffffffffc02004ee:	6522                	ld	a0,8(sp)
ffffffffc02004f0:	6105                	addi	sp,sp,32
ffffffffc02004f2:	8082                	ret

ffffffffc02004f4 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02004f4:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02004f8:	8082                	ret

ffffffffc02004fa <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02004fa:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02004fe:	8082                	ret

ffffffffc0200500 <pgfault_handler>:
    set_csr(sstatus, SSTATUS_SUM);
}

/* trap_in_kernel - test if trap happened in kernel */
bool trap_in_kernel(struct trapframe *tf) {
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200500:	10053783          	ld	a5,256(a0)
    cprintf("page fault at 0x%08x: %c/%c\n", tf->badvaddr,
            trap_in_kernel(tf) ? 'K' : 'U',
            tf->cause == CAUSE_STORE_PAGE_FAULT ? 'W' : 'R');
}

static int pgfault_handler(struct trapframe *tf) {
ffffffffc0200504:	1141                	addi	sp,sp,-16
ffffffffc0200506:	e022                	sd	s0,0(sp)
ffffffffc0200508:	e406                	sd	ra,8(sp)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc020050a:	1007f793          	andi	a5,a5,256
static int pgfault_handler(struct trapframe *tf) {
ffffffffc020050e:	842a                	mv	s0,a0
    cprintf("page fault at 0x%08x: %c/%c\n", tf->badvaddr,
ffffffffc0200510:	11053583          	ld	a1,272(a0)
ffffffffc0200514:	05500613          	li	a2,85
ffffffffc0200518:	c399                	beqz	a5,ffffffffc020051e <pgfault_handler+0x1e>
ffffffffc020051a:	04b00613          	li	a2,75
ffffffffc020051e:	11843703          	ld	a4,280(s0)
ffffffffc0200522:	47bd                	li	a5,15
ffffffffc0200524:	05700693          	li	a3,87
ffffffffc0200528:	00f70463          	beq	a4,a5,ffffffffc0200530 <pgfault_handler+0x30>
ffffffffc020052c:	05200693          	li	a3,82
ffffffffc0200530:	00004517          	auipc	a0,0x4
ffffffffc0200534:	47850513          	addi	a0,a0,1144 # ffffffffc02049a8 <commands+0x470>
ffffffffc0200538:	b87ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    extern struct mm_struct *check_mm_struct;
    print_pgfault(tf);
    if (check_mm_struct != NULL) {
ffffffffc020053c:	00011797          	auipc	a5,0x11
ffffffffc0200540:	f7478793          	addi	a5,a5,-140 # ffffffffc02114b0 <check_mm_struct>
ffffffffc0200544:	6388                	ld	a0,0(a5)
ffffffffc0200546:	c911                	beqz	a0,ffffffffc020055a <pgfault_handler+0x5a>
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
ffffffffc0200548:	11043603          	ld	a2,272(s0)
ffffffffc020054c:	11843583          	ld	a1,280(s0)
    }
    panic("unhandled page fault.\n");
}
ffffffffc0200550:	6402                	ld	s0,0(sp)
ffffffffc0200552:	60a2                	ld	ra,8(sp)
ffffffffc0200554:	0141                	addi	sp,sp,16
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
ffffffffc0200556:	25a0206f          	j	ffffffffc02027b0 <do_pgfault>
    panic("unhandled page fault.\n");
ffffffffc020055a:	00004617          	auipc	a2,0x4
ffffffffc020055e:	46e60613          	addi	a2,a2,1134 # ffffffffc02049c8 <commands+0x490>
ffffffffc0200562:	07800593          	li	a1,120
ffffffffc0200566:	00004517          	auipc	a0,0x4
ffffffffc020056a:	47a50513          	addi	a0,a0,1146 # ffffffffc02049e0 <commands+0x4a8>
ffffffffc020056e:	b99ff0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc0200572 <idt_init>:
    write_csr(sscratch, 0);
ffffffffc0200572:	14005073          	csrwi	sscratch,0
    write_csr(stvec, &__alltraps);
ffffffffc0200576:	00000797          	auipc	a5,0x0
ffffffffc020057a:	49a78793          	addi	a5,a5,1178 # ffffffffc0200a10 <__alltraps>
ffffffffc020057e:	10579073          	csrw	stvec,a5
    set_csr(sstatus, SSTATUS_SIE);
ffffffffc0200582:	100167f3          	csrrsi	a5,sstatus,2
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc0200586:	000407b7          	lui	a5,0x40
ffffffffc020058a:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc020058e:	8082                	ret

ffffffffc0200590 <print_regs>:
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200590:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200592:	1141                	addi	sp,sp,-16
ffffffffc0200594:	e022                	sd	s0,0(sp)
ffffffffc0200596:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200598:	00004517          	auipc	a0,0x4
ffffffffc020059c:	46050513          	addi	a0,a0,1120 # ffffffffc02049f8 <commands+0x4c0>
void print_regs(struct pushregs *gpr) {
ffffffffc02005a0:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02005a2:	b1dff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02005a6:	640c                	ld	a1,8(s0)
ffffffffc02005a8:	00004517          	auipc	a0,0x4
ffffffffc02005ac:	46850513          	addi	a0,a0,1128 # ffffffffc0204a10 <commands+0x4d8>
ffffffffc02005b0:	b0fff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02005b4:	680c                	ld	a1,16(s0)
ffffffffc02005b6:	00004517          	auipc	a0,0x4
ffffffffc02005ba:	47250513          	addi	a0,a0,1138 # ffffffffc0204a28 <commands+0x4f0>
ffffffffc02005be:	b01ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02005c2:	6c0c                	ld	a1,24(s0)
ffffffffc02005c4:	00004517          	auipc	a0,0x4
ffffffffc02005c8:	47c50513          	addi	a0,a0,1148 # ffffffffc0204a40 <commands+0x508>
ffffffffc02005cc:	af3ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02005d0:	700c                	ld	a1,32(s0)
ffffffffc02005d2:	00004517          	auipc	a0,0x4
ffffffffc02005d6:	48650513          	addi	a0,a0,1158 # ffffffffc0204a58 <commands+0x520>
ffffffffc02005da:	ae5ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02005de:	740c                	ld	a1,40(s0)
ffffffffc02005e0:	00004517          	auipc	a0,0x4
ffffffffc02005e4:	49050513          	addi	a0,a0,1168 # ffffffffc0204a70 <commands+0x538>
ffffffffc02005e8:	ad7ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02005ec:	780c                	ld	a1,48(s0)
ffffffffc02005ee:	00004517          	auipc	a0,0x4
ffffffffc02005f2:	49a50513          	addi	a0,a0,1178 # ffffffffc0204a88 <commands+0x550>
ffffffffc02005f6:	ac9ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02005fa:	7c0c                	ld	a1,56(s0)
ffffffffc02005fc:	00004517          	auipc	a0,0x4
ffffffffc0200600:	4a450513          	addi	a0,a0,1188 # ffffffffc0204aa0 <commands+0x568>
ffffffffc0200604:	abbff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200608:	602c                	ld	a1,64(s0)
ffffffffc020060a:	00004517          	auipc	a0,0x4
ffffffffc020060e:	4ae50513          	addi	a0,a0,1198 # ffffffffc0204ab8 <commands+0x580>
ffffffffc0200612:	aadff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200616:	642c                	ld	a1,72(s0)
ffffffffc0200618:	00004517          	auipc	a0,0x4
ffffffffc020061c:	4b850513          	addi	a0,a0,1208 # ffffffffc0204ad0 <commands+0x598>
ffffffffc0200620:	a9fff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200624:	682c                	ld	a1,80(s0)
ffffffffc0200626:	00004517          	auipc	a0,0x4
ffffffffc020062a:	4c250513          	addi	a0,a0,1218 # ffffffffc0204ae8 <commands+0x5b0>
ffffffffc020062e:	a91ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200632:	6c2c                	ld	a1,88(s0)
ffffffffc0200634:	00004517          	auipc	a0,0x4
ffffffffc0200638:	4cc50513          	addi	a0,a0,1228 # ffffffffc0204b00 <commands+0x5c8>
ffffffffc020063c:	a83ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200640:	702c                	ld	a1,96(s0)
ffffffffc0200642:	00004517          	auipc	a0,0x4
ffffffffc0200646:	4d650513          	addi	a0,a0,1238 # ffffffffc0204b18 <commands+0x5e0>
ffffffffc020064a:	a75ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020064e:	742c                	ld	a1,104(s0)
ffffffffc0200650:	00004517          	auipc	a0,0x4
ffffffffc0200654:	4e050513          	addi	a0,a0,1248 # ffffffffc0204b30 <commands+0x5f8>
ffffffffc0200658:	a67ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc020065c:	782c                	ld	a1,112(s0)
ffffffffc020065e:	00004517          	auipc	a0,0x4
ffffffffc0200662:	4ea50513          	addi	a0,a0,1258 # ffffffffc0204b48 <commands+0x610>
ffffffffc0200666:	a59ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc020066a:	7c2c                	ld	a1,120(s0)
ffffffffc020066c:	00004517          	auipc	a0,0x4
ffffffffc0200670:	4f450513          	addi	a0,a0,1268 # ffffffffc0204b60 <commands+0x628>
ffffffffc0200674:	a4bff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200678:	604c                	ld	a1,128(s0)
ffffffffc020067a:	00004517          	auipc	a0,0x4
ffffffffc020067e:	4fe50513          	addi	a0,a0,1278 # ffffffffc0204b78 <commands+0x640>
ffffffffc0200682:	a3dff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200686:	644c                	ld	a1,136(s0)
ffffffffc0200688:	00004517          	auipc	a0,0x4
ffffffffc020068c:	50850513          	addi	a0,a0,1288 # ffffffffc0204b90 <commands+0x658>
ffffffffc0200690:	a2fff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200694:	684c                	ld	a1,144(s0)
ffffffffc0200696:	00004517          	auipc	a0,0x4
ffffffffc020069a:	51250513          	addi	a0,a0,1298 # ffffffffc0204ba8 <commands+0x670>
ffffffffc020069e:	a21ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc02006a2:	6c4c                	ld	a1,152(s0)
ffffffffc02006a4:	00004517          	auipc	a0,0x4
ffffffffc02006a8:	51c50513          	addi	a0,a0,1308 # ffffffffc0204bc0 <commands+0x688>
ffffffffc02006ac:	a13ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc02006b0:	704c                	ld	a1,160(s0)
ffffffffc02006b2:	00004517          	auipc	a0,0x4
ffffffffc02006b6:	52650513          	addi	a0,a0,1318 # ffffffffc0204bd8 <commands+0x6a0>
ffffffffc02006ba:	a05ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02006be:	744c                	ld	a1,168(s0)
ffffffffc02006c0:	00004517          	auipc	a0,0x4
ffffffffc02006c4:	53050513          	addi	a0,a0,1328 # ffffffffc0204bf0 <commands+0x6b8>
ffffffffc02006c8:	9f7ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02006cc:	784c                	ld	a1,176(s0)
ffffffffc02006ce:	00004517          	auipc	a0,0x4
ffffffffc02006d2:	53a50513          	addi	a0,a0,1338 # ffffffffc0204c08 <commands+0x6d0>
ffffffffc02006d6:	9e9ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02006da:	7c4c                	ld	a1,184(s0)
ffffffffc02006dc:	00004517          	auipc	a0,0x4
ffffffffc02006e0:	54450513          	addi	a0,a0,1348 # ffffffffc0204c20 <commands+0x6e8>
ffffffffc02006e4:	9dbff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02006e8:	606c                	ld	a1,192(s0)
ffffffffc02006ea:	00004517          	auipc	a0,0x4
ffffffffc02006ee:	54e50513          	addi	a0,a0,1358 # ffffffffc0204c38 <commands+0x700>
ffffffffc02006f2:	9cdff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02006f6:	646c                	ld	a1,200(s0)
ffffffffc02006f8:	00004517          	auipc	a0,0x4
ffffffffc02006fc:	55850513          	addi	a0,a0,1368 # ffffffffc0204c50 <commands+0x718>
ffffffffc0200700:	9bfff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200704:	686c                	ld	a1,208(s0)
ffffffffc0200706:	00004517          	auipc	a0,0x4
ffffffffc020070a:	56250513          	addi	a0,a0,1378 # ffffffffc0204c68 <commands+0x730>
ffffffffc020070e:	9b1ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200712:	6c6c                	ld	a1,216(s0)
ffffffffc0200714:	00004517          	auipc	a0,0x4
ffffffffc0200718:	56c50513          	addi	a0,a0,1388 # ffffffffc0204c80 <commands+0x748>
ffffffffc020071c:	9a3ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200720:	706c                	ld	a1,224(s0)
ffffffffc0200722:	00004517          	auipc	a0,0x4
ffffffffc0200726:	57650513          	addi	a0,a0,1398 # ffffffffc0204c98 <commands+0x760>
ffffffffc020072a:	995ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc020072e:	746c                	ld	a1,232(s0)
ffffffffc0200730:	00004517          	auipc	a0,0x4
ffffffffc0200734:	58050513          	addi	a0,a0,1408 # ffffffffc0204cb0 <commands+0x778>
ffffffffc0200738:	987ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc020073c:	786c                	ld	a1,240(s0)
ffffffffc020073e:	00004517          	auipc	a0,0x4
ffffffffc0200742:	58a50513          	addi	a0,a0,1418 # ffffffffc0204cc8 <commands+0x790>
ffffffffc0200746:	979ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020074a:	7c6c                	ld	a1,248(s0)
}
ffffffffc020074c:	6402                	ld	s0,0(sp)
ffffffffc020074e:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200750:	00004517          	auipc	a0,0x4
ffffffffc0200754:	59050513          	addi	a0,a0,1424 # ffffffffc0204ce0 <commands+0x7a8>
}
ffffffffc0200758:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020075a:	965ff06f          	j	ffffffffc02000be <cprintf>

ffffffffc020075e <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc020075e:	1141                	addi	sp,sp,-16
ffffffffc0200760:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200762:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200764:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200766:	00004517          	auipc	a0,0x4
ffffffffc020076a:	59250513          	addi	a0,a0,1426 # ffffffffc0204cf8 <commands+0x7c0>
void print_trapframe(struct trapframe *tf) {
ffffffffc020076e:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200770:	94fff0ef          	jal	ra,ffffffffc02000be <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200774:	8522                	mv	a0,s0
ffffffffc0200776:	e1bff0ef          	jal	ra,ffffffffc0200590 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc020077a:	10043583          	ld	a1,256(s0)
ffffffffc020077e:	00004517          	auipc	a0,0x4
ffffffffc0200782:	59250513          	addi	a0,a0,1426 # ffffffffc0204d10 <commands+0x7d8>
ffffffffc0200786:	939ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc020078a:	10843583          	ld	a1,264(s0)
ffffffffc020078e:	00004517          	auipc	a0,0x4
ffffffffc0200792:	59a50513          	addi	a0,a0,1434 # ffffffffc0204d28 <commands+0x7f0>
ffffffffc0200796:	929ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc020079a:	11043583          	ld	a1,272(s0)
ffffffffc020079e:	00004517          	auipc	a0,0x4
ffffffffc02007a2:	5a250513          	addi	a0,a0,1442 # ffffffffc0204d40 <commands+0x808>
ffffffffc02007a6:	919ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02007aa:	11843583          	ld	a1,280(s0)
}
ffffffffc02007ae:	6402                	ld	s0,0(sp)
ffffffffc02007b0:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02007b2:	00004517          	auipc	a0,0x4
ffffffffc02007b6:	5a650513          	addi	a0,a0,1446 # ffffffffc0204d58 <commands+0x820>
}
ffffffffc02007ba:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02007bc:	903ff06f          	j	ffffffffc02000be <cprintf>

ffffffffc02007c0 <interrupt_handler>:

static volatile int in_swap_tick_event = 0;
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02007c0:	11853783          	ld	a5,280(a0)
ffffffffc02007c4:	577d                	li	a4,-1
ffffffffc02007c6:	8305                	srli	a4,a4,0x1
ffffffffc02007c8:	8ff9                	and	a5,a5,a4
    switch (cause) {
ffffffffc02007ca:	472d                	li	a4,11
ffffffffc02007cc:	06f76f63          	bltu	a4,a5,ffffffffc020084a <interrupt_handler+0x8a>
ffffffffc02007d0:	00004717          	auipc	a4,0x4
ffffffffc02007d4:	efc70713          	addi	a4,a4,-260 # ffffffffc02046cc <commands+0x194>
ffffffffc02007d8:	078a                	slli	a5,a5,0x2
ffffffffc02007da:	97ba                	add	a5,a5,a4
ffffffffc02007dc:	439c                	lw	a5,0(a5)
ffffffffc02007de:	97ba                	add	a5,a5,a4
ffffffffc02007e0:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02007e2:	00004517          	auipc	a0,0x4
ffffffffc02007e6:	17650513          	addi	a0,a0,374 # ffffffffc0204958 <commands+0x420>
ffffffffc02007ea:	8d5ff06f          	j	ffffffffc02000be <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02007ee:	00004517          	auipc	a0,0x4
ffffffffc02007f2:	14a50513          	addi	a0,a0,330 # ffffffffc0204938 <commands+0x400>
ffffffffc02007f6:	8c9ff06f          	j	ffffffffc02000be <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02007fa:	00004517          	auipc	a0,0x4
ffffffffc02007fe:	0fe50513          	addi	a0,a0,254 # ffffffffc02048f8 <commands+0x3c0>
ffffffffc0200802:	8bdff06f          	j	ffffffffc02000be <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200806:	00004517          	auipc	a0,0x4
ffffffffc020080a:	11250513          	addi	a0,a0,274 # ffffffffc0204918 <commands+0x3e0>
ffffffffc020080e:	8b1ff06f          	j	ffffffffc02000be <cprintf>
            break;
        case IRQ_U_EXT:
            cprintf("User software interrupt\n");
            break;
        case IRQ_S_EXT:
            cprintf("Supervisor external interrupt\n");
ffffffffc0200812:	00004517          	auipc	a0,0x4
ffffffffc0200816:	17650513          	addi	a0,a0,374 # ffffffffc0204988 <commands+0x450>
ffffffffc020081a:	8a5ff06f          	j	ffffffffc02000be <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc020081e:	1141                	addi	sp,sp,-16
ffffffffc0200820:	e406                	sd	ra,8(sp)
            clock_set_next_event();
ffffffffc0200822:	c45ff0ef          	jal	ra,ffffffffc0200466 <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc0200826:	00011797          	auipc	a5,0x11
ffffffffc020082a:	c5278793          	addi	a5,a5,-942 # ffffffffc0211478 <ticks>
ffffffffc020082e:	639c                	ld	a5,0(a5)
ffffffffc0200830:	06400713          	li	a4,100
ffffffffc0200834:	0785                	addi	a5,a5,1
ffffffffc0200836:	02e7f733          	remu	a4,a5,a4
ffffffffc020083a:	00011697          	auipc	a3,0x11
ffffffffc020083e:	c2f6bf23          	sd	a5,-962(a3) # ffffffffc0211478 <ticks>
ffffffffc0200842:	c711                	beqz	a4,ffffffffc020084e <interrupt_handler+0x8e>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200844:	60a2                	ld	ra,8(sp)
ffffffffc0200846:	0141                	addi	sp,sp,16
ffffffffc0200848:	8082                	ret
            print_trapframe(tf);
ffffffffc020084a:	f15ff06f          	j	ffffffffc020075e <print_trapframe>
}
ffffffffc020084e:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200850:	06400593          	li	a1,100
ffffffffc0200854:	00004517          	auipc	a0,0x4
ffffffffc0200858:	12450513          	addi	a0,a0,292 # ffffffffc0204978 <commands+0x440>
}
ffffffffc020085c:	0141                	addi	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc020085e:	861ff06f          	j	ffffffffc02000be <cprintf>

ffffffffc0200862 <exception_handler>:


void exception_handler(struct trapframe *tf) {
    int ret;
    switch (tf->cause) {
ffffffffc0200862:	11853783          	ld	a5,280(a0)
ffffffffc0200866:	473d                	li	a4,15
ffffffffc0200868:	16f76563          	bltu	a4,a5,ffffffffc02009d2 <exception_handler+0x170>
ffffffffc020086c:	00004717          	auipc	a4,0x4
ffffffffc0200870:	e9070713          	addi	a4,a4,-368 # ffffffffc02046fc <commands+0x1c4>
ffffffffc0200874:	078a                	slli	a5,a5,0x2
ffffffffc0200876:	97ba                	add	a5,a5,a4
ffffffffc0200878:	439c                	lw	a5,0(a5)
void exception_handler(struct trapframe *tf) {
ffffffffc020087a:	1101                	addi	sp,sp,-32
ffffffffc020087c:	e822                	sd	s0,16(sp)
ffffffffc020087e:	ec06                	sd	ra,24(sp)
ffffffffc0200880:	e426                	sd	s1,8(sp)
    switch (tf->cause) {
ffffffffc0200882:	97ba                	add	a5,a5,a4
ffffffffc0200884:	842a                	mv	s0,a0
ffffffffc0200886:	8782                	jr	a5
                print_trapframe(tf);
                panic("handle pgfault failed. %e\n", ret);
            }
            break;
        case CAUSE_STORE_PAGE_FAULT:
            cprintf("Store/AMO page fault\n");
ffffffffc0200888:	00004517          	auipc	a0,0x4
ffffffffc020088c:	05850513          	addi	a0,a0,88 # ffffffffc02048e0 <commands+0x3a8>
ffffffffc0200890:	82fff0ef          	jal	ra,ffffffffc02000be <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200894:	8522                	mv	a0,s0
ffffffffc0200896:	c6bff0ef          	jal	ra,ffffffffc0200500 <pgfault_handler>
ffffffffc020089a:	84aa                	mv	s1,a0
ffffffffc020089c:	12051d63          	bnez	a0,ffffffffc02009d6 <exception_handler+0x174>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc02008a0:	60e2                	ld	ra,24(sp)
ffffffffc02008a2:	6442                	ld	s0,16(sp)
ffffffffc02008a4:	64a2                	ld	s1,8(sp)
ffffffffc02008a6:	6105                	addi	sp,sp,32
ffffffffc02008a8:	8082                	ret
            cprintf("Instruction address misaligned\n");
ffffffffc02008aa:	00004517          	auipc	a0,0x4
ffffffffc02008ae:	e9650513          	addi	a0,a0,-362 # ffffffffc0204740 <commands+0x208>
}
ffffffffc02008b2:	6442                	ld	s0,16(sp)
ffffffffc02008b4:	60e2                	ld	ra,24(sp)
ffffffffc02008b6:	64a2                	ld	s1,8(sp)
ffffffffc02008b8:	6105                	addi	sp,sp,32
            cprintf("Instruction access fault\n");
ffffffffc02008ba:	805ff06f          	j	ffffffffc02000be <cprintf>
ffffffffc02008be:	00004517          	auipc	a0,0x4
ffffffffc02008c2:	ea250513          	addi	a0,a0,-350 # ffffffffc0204760 <commands+0x228>
ffffffffc02008c6:	b7f5                	j	ffffffffc02008b2 <exception_handler+0x50>
            cprintf("Illegal instruction\n");
ffffffffc02008c8:	00004517          	auipc	a0,0x4
ffffffffc02008cc:	eb850513          	addi	a0,a0,-328 # ffffffffc0204780 <commands+0x248>
ffffffffc02008d0:	b7cd                	j	ffffffffc02008b2 <exception_handler+0x50>
            cprintf("Breakpoint\n");
ffffffffc02008d2:	00004517          	auipc	a0,0x4
ffffffffc02008d6:	ec650513          	addi	a0,a0,-314 # ffffffffc0204798 <commands+0x260>
ffffffffc02008da:	bfe1                	j	ffffffffc02008b2 <exception_handler+0x50>
            cprintf("Load address misaligned\n");
ffffffffc02008dc:	00004517          	auipc	a0,0x4
ffffffffc02008e0:	ecc50513          	addi	a0,a0,-308 # ffffffffc02047a8 <commands+0x270>
ffffffffc02008e4:	b7f9                	j	ffffffffc02008b2 <exception_handler+0x50>
            cprintf("Load access fault\n");
ffffffffc02008e6:	00004517          	auipc	a0,0x4
ffffffffc02008ea:	ee250513          	addi	a0,a0,-286 # ffffffffc02047c8 <commands+0x290>
ffffffffc02008ee:	fd0ff0ef          	jal	ra,ffffffffc02000be <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc02008f2:	8522                	mv	a0,s0
ffffffffc02008f4:	c0dff0ef          	jal	ra,ffffffffc0200500 <pgfault_handler>
ffffffffc02008f8:	84aa                	mv	s1,a0
ffffffffc02008fa:	d15d                	beqz	a0,ffffffffc02008a0 <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc02008fc:	8522                	mv	a0,s0
ffffffffc02008fe:	e61ff0ef          	jal	ra,ffffffffc020075e <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200902:	86a6                	mv	a3,s1
ffffffffc0200904:	00004617          	auipc	a2,0x4
ffffffffc0200908:	edc60613          	addi	a2,a2,-292 # ffffffffc02047e0 <commands+0x2a8>
ffffffffc020090c:	0ca00593          	li	a1,202
ffffffffc0200910:	00004517          	auipc	a0,0x4
ffffffffc0200914:	0d050513          	addi	a0,a0,208 # ffffffffc02049e0 <commands+0x4a8>
ffffffffc0200918:	feeff0ef          	jal	ra,ffffffffc0200106 <__panic>
            cprintf("AMO address misaligned\n");
ffffffffc020091c:	00004517          	auipc	a0,0x4
ffffffffc0200920:	ee450513          	addi	a0,a0,-284 # ffffffffc0204800 <commands+0x2c8>
ffffffffc0200924:	b779                	j	ffffffffc02008b2 <exception_handler+0x50>
            cprintf("Store/AMO access fault\n");
ffffffffc0200926:	00004517          	auipc	a0,0x4
ffffffffc020092a:	ef250513          	addi	a0,a0,-270 # ffffffffc0204818 <commands+0x2e0>
ffffffffc020092e:	f90ff0ef          	jal	ra,ffffffffc02000be <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200932:	8522                	mv	a0,s0
ffffffffc0200934:	bcdff0ef          	jal	ra,ffffffffc0200500 <pgfault_handler>
ffffffffc0200938:	84aa                	mv	s1,a0
ffffffffc020093a:	d13d                	beqz	a0,ffffffffc02008a0 <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc020093c:	8522                	mv	a0,s0
ffffffffc020093e:	e21ff0ef          	jal	ra,ffffffffc020075e <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200942:	86a6                	mv	a3,s1
ffffffffc0200944:	00004617          	auipc	a2,0x4
ffffffffc0200948:	e9c60613          	addi	a2,a2,-356 # ffffffffc02047e0 <commands+0x2a8>
ffffffffc020094c:	0d400593          	li	a1,212
ffffffffc0200950:	00004517          	auipc	a0,0x4
ffffffffc0200954:	09050513          	addi	a0,a0,144 # ffffffffc02049e0 <commands+0x4a8>
ffffffffc0200958:	faeff0ef          	jal	ra,ffffffffc0200106 <__panic>
            cprintf("Environment call from U-mode\n");
ffffffffc020095c:	00004517          	auipc	a0,0x4
ffffffffc0200960:	ed450513          	addi	a0,a0,-300 # ffffffffc0204830 <commands+0x2f8>
ffffffffc0200964:	b7b9                	j	ffffffffc02008b2 <exception_handler+0x50>
            cprintf("Environment call from S-mode\n");
ffffffffc0200966:	00004517          	auipc	a0,0x4
ffffffffc020096a:	eea50513          	addi	a0,a0,-278 # ffffffffc0204850 <commands+0x318>
ffffffffc020096e:	b791                	j	ffffffffc02008b2 <exception_handler+0x50>
            cprintf("Environment call from H-mode\n");
ffffffffc0200970:	00004517          	auipc	a0,0x4
ffffffffc0200974:	f0050513          	addi	a0,a0,-256 # ffffffffc0204870 <commands+0x338>
ffffffffc0200978:	bf2d                	j	ffffffffc02008b2 <exception_handler+0x50>
            cprintf("Environment call from M-mode\n");
ffffffffc020097a:	00004517          	auipc	a0,0x4
ffffffffc020097e:	f1650513          	addi	a0,a0,-234 # ffffffffc0204890 <commands+0x358>
ffffffffc0200982:	bf05                	j	ffffffffc02008b2 <exception_handler+0x50>
            cprintf("Instruction page fault\n");
ffffffffc0200984:	00004517          	auipc	a0,0x4
ffffffffc0200988:	f2c50513          	addi	a0,a0,-212 # ffffffffc02048b0 <commands+0x378>
ffffffffc020098c:	b71d                	j	ffffffffc02008b2 <exception_handler+0x50>
            cprintf("Load page fault\n");
ffffffffc020098e:	00004517          	auipc	a0,0x4
ffffffffc0200992:	f3a50513          	addi	a0,a0,-198 # ffffffffc02048c8 <commands+0x390>
ffffffffc0200996:	f28ff0ef          	jal	ra,ffffffffc02000be <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc020099a:	8522                	mv	a0,s0
ffffffffc020099c:	b65ff0ef          	jal	ra,ffffffffc0200500 <pgfault_handler>
ffffffffc02009a0:	84aa                	mv	s1,a0
ffffffffc02009a2:	ee050fe3          	beqz	a0,ffffffffc02008a0 <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc02009a6:	8522                	mv	a0,s0
ffffffffc02009a8:	db7ff0ef          	jal	ra,ffffffffc020075e <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc02009ac:	86a6                	mv	a3,s1
ffffffffc02009ae:	00004617          	auipc	a2,0x4
ffffffffc02009b2:	e3260613          	addi	a2,a2,-462 # ffffffffc02047e0 <commands+0x2a8>
ffffffffc02009b6:	0ea00593          	li	a1,234
ffffffffc02009ba:	00004517          	auipc	a0,0x4
ffffffffc02009be:	02650513          	addi	a0,a0,38 # ffffffffc02049e0 <commands+0x4a8>
ffffffffc02009c2:	f44ff0ef          	jal	ra,ffffffffc0200106 <__panic>
}
ffffffffc02009c6:	6442                	ld	s0,16(sp)
ffffffffc02009c8:	60e2                	ld	ra,24(sp)
ffffffffc02009ca:	64a2                	ld	s1,8(sp)
ffffffffc02009cc:	6105                	addi	sp,sp,32
            print_trapframe(tf);
ffffffffc02009ce:	d91ff06f          	j	ffffffffc020075e <print_trapframe>
ffffffffc02009d2:	d8dff06f          	j	ffffffffc020075e <print_trapframe>
                print_trapframe(tf);
ffffffffc02009d6:	8522                	mv	a0,s0
ffffffffc02009d8:	d87ff0ef          	jal	ra,ffffffffc020075e <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc02009dc:	86a6                	mv	a3,s1
ffffffffc02009de:	00004617          	auipc	a2,0x4
ffffffffc02009e2:	e0260613          	addi	a2,a2,-510 # ffffffffc02047e0 <commands+0x2a8>
ffffffffc02009e6:	0f100593          	li	a1,241
ffffffffc02009ea:	00004517          	auipc	a0,0x4
ffffffffc02009ee:	ff650513          	addi	a0,a0,-10 # ffffffffc02049e0 <commands+0x4a8>
ffffffffc02009f2:	f14ff0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc02009f6 <trap>:
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    if ((intptr_t)tf->cause < 0) {
ffffffffc02009f6:	11853783          	ld	a5,280(a0)
ffffffffc02009fa:	0007c463          	bltz	a5,ffffffffc0200a02 <trap+0xc>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc02009fe:	e65ff06f          	j	ffffffffc0200862 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200a02:	dbfff06f          	j	ffffffffc02007c0 <interrupt_handler>
	...

ffffffffc0200a10 <__alltraps>:
    .endm

    .align 4
    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200a10:	14011073          	csrw	sscratch,sp
ffffffffc0200a14:	712d                	addi	sp,sp,-288
ffffffffc0200a16:	e406                	sd	ra,8(sp)
ffffffffc0200a18:	ec0e                	sd	gp,24(sp)
ffffffffc0200a1a:	f012                	sd	tp,32(sp)
ffffffffc0200a1c:	f416                	sd	t0,40(sp)
ffffffffc0200a1e:	f81a                	sd	t1,48(sp)
ffffffffc0200a20:	fc1e                	sd	t2,56(sp)
ffffffffc0200a22:	e0a2                	sd	s0,64(sp)
ffffffffc0200a24:	e4a6                	sd	s1,72(sp)
ffffffffc0200a26:	e8aa                	sd	a0,80(sp)
ffffffffc0200a28:	ecae                	sd	a1,88(sp)
ffffffffc0200a2a:	f0b2                	sd	a2,96(sp)
ffffffffc0200a2c:	f4b6                	sd	a3,104(sp)
ffffffffc0200a2e:	f8ba                	sd	a4,112(sp)
ffffffffc0200a30:	fcbe                	sd	a5,120(sp)
ffffffffc0200a32:	e142                	sd	a6,128(sp)
ffffffffc0200a34:	e546                	sd	a7,136(sp)
ffffffffc0200a36:	e94a                	sd	s2,144(sp)
ffffffffc0200a38:	ed4e                	sd	s3,152(sp)
ffffffffc0200a3a:	f152                	sd	s4,160(sp)
ffffffffc0200a3c:	f556                	sd	s5,168(sp)
ffffffffc0200a3e:	f95a                	sd	s6,176(sp)
ffffffffc0200a40:	fd5e                	sd	s7,184(sp)
ffffffffc0200a42:	e1e2                	sd	s8,192(sp)
ffffffffc0200a44:	e5e6                	sd	s9,200(sp)
ffffffffc0200a46:	e9ea                	sd	s10,208(sp)
ffffffffc0200a48:	edee                	sd	s11,216(sp)
ffffffffc0200a4a:	f1f2                	sd	t3,224(sp)
ffffffffc0200a4c:	f5f6                	sd	t4,232(sp)
ffffffffc0200a4e:	f9fa                	sd	t5,240(sp)
ffffffffc0200a50:	fdfe                	sd	t6,248(sp)
ffffffffc0200a52:	14002473          	csrr	s0,sscratch
ffffffffc0200a56:	100024f3          	csrr	s1,sstatus
ffffffffc0200a5a:	14102973          	csrr	s2,sepc
ffffffffc0200a5e:	143029f3          	csrr	s3,stval
ffffffffc0200a62:	14202a73          	csrr	s4,scause
ffffffffc0200a66:	e822                	sd	s0,16(sp)
ffffffffc0200a68:	e226                	sd	s1,256(sp)
ffffffffc0200a6a:	e64a                	sd	s2,264(sp)
ffffffffc0200a6c:	ea4e                	sd	s3,272(sp)
ffffffffc0200a6e:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200a70:	850a                	mv	a0,sp
    jal trap
ffffffffc0200a72:	f85ff0ef          	jal	ra,ffffffffc02009f6 <trap>

ffffffffc0200a76 <__trapret>:
    // sp should be the same as before "jal trap"
    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200a76:	6492                	ld	s1,256(sp)
ffffffffc0200a78:	6932                	ld	s2,264(sp)
ffffffffc0200a7a:	10049073          	csrw	sstatus,s1
ffffffffc0200a7e:	14191073          	csrw	sepc,s2
ffffffffc0200a82:	60a2                	ld	ra,8(sp)
ffffffffc0200a84:	61e2                	ld	gp,24(sp)
ffffffffc0200a86:	7202                	ld	tp,32(sp)
ffffffffc0200a88:	72a2                	ld	t0,40(sp)
ffffffffc0200a8a:	7342                	ld	t1,48(sp)
ffffffffc0200a8c:	73e2                	ld	t2,56(sp)
ffffffffc0200a8e:	6406                	ld	s0,64(sp)
ffffffffc0200a90:	64a6                	ld	s1,72(sp)
ffffffffc0200a92:	6546                	ld	a0,80(sp)
ffffffffc0200a94:	65e6                	ld	a1,88(sp)
ffffffffc0200a96:	7606                	ld	a2,96(sp)
ffffffffc0200a98:	76a6                	ld	a3,104(sp)
ffffffffc0200a9a:	7746                	ld	a4,112(sp)
ffffffffc0200a9c:	77e6                	ld	a5,120(sp)
ffffffffc0200a9e:	680a                	ld	a6,128(sp)
ffffffffc0200aa0:	68aa                	ld	a7,136(sp)
ffffffffc0200aa2:	694a                	ld	s2,144(sp)
ffffffffc0200aa4:	69ea                	ld	s3,152(sp)
ffffffffc0200aa6:	7a0a                	ld	s4,160(sp)
ffffffffc0200aa8:	7aaa                	ld	s5,168(sp)
ffffffffc0200aaa:	7b4a                	ld	s6,176(sp)
ffffffffc0200aac:	7bea                	ld	s7,184(sp)
ffffffffc0200aae:	6c0e                	ld	s8,192(sp)
ffffffffc0200ab0:	6cae                	ld	s9,200(sp)
ffffffffc0200ab2:	6d4e                	ld	s10,208(sp)
ffffffffc0200ab4:	6dee                	ld	s11,216(sp)
ffffffffc0200ab6:	7e0e                	ld	t3,224(sp)
ffffffffc0200ab8:	7eae                	ld	t4,232(sp)
ffffffffc0200aba:	7f4e                	ld	t5,240(sp)
ffffffffc0200abc:	7fee                	ld	t6,248(sp)
ffffffffc0200abe:	6142                	ld	sp,16(sp)
    // go back from supervisor call
    sret
ffffffffc0200ac0:	10200073          	sret
	...

ffffffffc0200ad0 <pa2page.part.4>:

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
}

static inline struct Page *pa2page(uintptr_t pa) {
ffffffffc0200ad0:	1141                	addi	sp,sp,-16
    if (PPN(pa) >= npage) {
        panic("pa2page called with invalid pa");
ffffffffc0200ad2:	00004617          	auipc	a2,0x4
ffffffffc0200ad6:	31e60613          	addi	a2,a2,798 # ffffffffc0204df0 <commands+0x8b8>
ffffffffc0200ada:	06500593          	li	a1,101
ffffffffc0200ade:	00004517          	auipc	a0,0x4
ffffffffc0200ae2:	33250513          	addi	a0,a0,818 # ffffffffc0204e10 <commands+0x8d8>
static inline struct Page *pa2page(uintptr_t pa) {
ffffffffc0200ae6:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0200ae8:	e1eff0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc0200aec <alloc_pages>:
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
ffffffffc0200aec:	715d                	addi	sp,sp,-80
ffffffffc0200aee:	e0a2                	sd	s0,64(sp)
ffffffffc0200af0:	fc26                	sd	s1,56(sp)
ffffffffc0200af2:	f84a                	sd	s2,48(sp)
ffffffffc0200af4:	f44e                	sd	s3,40(sp)
ffffffffc0200af6:	f052                	sd	s4,32(sp)
ffffffffc0200af8:	ec56                	sd	s5,24(sp)
ffffffffc0200afa:	e486                	sd	ra,72(sp)
ffffffffc0200afc:	842a                	mv	s0,a0
ffffffffc0200afe:	00011497          	auipc	s1,0x11
ffffffffc0200b02:	98248493          	addi	s1,s1,-1662 # ffffffffc0211480 <pmm_manager>
    while (1) {
        local_intr_save(intr_flag);
        { page = pmm_manager->alloc_pages(n); }
        local_intr_restore(intr_flag);

        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0200b06:	4985                	li	s3,1
ffffffffc0200b08:	00011a17          	auipc	s4,0x11
ffffffffc0200b0c:	968a0a13          	addi	s4,s4,-1688 # ffffffffc0211470 <swap_init_ok>

        extern struct mm_struct *check_mm_struct;
        // cprintf("page %x, call swap_out in alloc_pages %d\n",page, n);
        swap_out(check_mm_struct, n, 0);
ffffffffc0200b10:	0005091b          	sext.w	s2,a0
ffffffffc0200b14:	00011a97          	auipc	s5,0x11
ffffffffc0200b18:	99ca8a93          	addi	s5,s5,-1636 # ffffffffc02114b0 <check_mm_struct>
ffffffffc0200b1c:	a00d                	j	ffffffffc0200b3e <alloc_pages+0x52>
        { page = pmm_manager->alloc_pages(n); }
ffffffffc0200b1e:	609c                	ld	a5,0(s1)
ffffffffc0200b20:	6f9c                	ld	a5,24(a5)
ffffffffc0200b22:	9782                	jalr	a5
        swap_out(check_mm_struct, n, 0);
ffffffffc0200b24:	4601                	li	a2,0
ffffffffc0200b26:	85ca                	mv	a1,s2
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0200b28:	ed0d                	bnez	a0,ffffffffc0200b62 <alloc_pages+0x76>
ffffffffc0200b2a:	0289ec63          	bltu	s3,s0,ffffffffc0200b62 <alloc_pages+0x76>
ffffffffc0200b2e:	000a2783          	lw	a5,0(s4)
ffffffffc0200b32:	2781                	sext.w	a5,a5
ffffffffc0200b34:	c79d                	beqz	a5,ffffffffc0200b62 <alloc_pages+0x76>
        swap_out(check_mm_struct, n, 0);
ffffffffc0200b36:	000ab503          	ld	a0,0(s5)
ffffffffc0200b3a:	4b4020ef          	jal	ra,ffffffffc0202fee <swap_out>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200b3e:	100027f3          	csrr	a5,sstatus
ffffffffc0200b42:	8b89                	andi	a5,a5,2
        { page = pmm_manager->alloc_pages(n); }
ffffffffc0200b44:	8522                	mv	a0,s0
ffffffffc0200b46:	dfe1                	beqz	a5,ffffffffc0200b1e <alloc_pages+0x32>
        intr_disable();
ffffffffc0200b48:	9b3ff0ef          	jal	ra,ffffffffc02004fa <intr_disable>
ffffffffc0200b4c:	609c                	ld	a5,0(s1)
ffffffffc0200b4e:	8522                	mv	a0,s0
ffffffffc0200b50:	6f9c                	ld	a5,24(a5)
ffffffffc0200b52:	9782                	jalr	a5
ffffffffc0200b54:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0200b56:	99fff0ef          	jal	ra,ffffffffc02004f4 <intr_enable>
ffffffffc0200b5a:	6522                	ld	a0,8(sp)
        swap_out(check_mm_struct, n, 0);
ffffffffc0200b5c:	4601                	li	a2,0
ffffffffc0200b5e:	85ca                	mv	a1,s2
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0200b60:	d569                	beqz	a0,ffffffffc0200b2a <alloc_pages+0x3e>
    }
    // cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page;
}
ffffffffc0200b62:	60a6                	ld	ra,72(sp)
ffffffffc0200b64:	6406                	ld	s0,64(sp)
ffffffffc0200b66:	74e2                	ld	s1,56(sp)
ffffffffc0200b68:	7942                	ld	s2,48(sp)
ffffffffc0200b6a:	79a2                	ld	s3,40(sp)
ffffffffc0200b6c:	7a02                	ld	s4,32(sp)
ffffffffc0200b6e:	6ae2                	ld	s5,24(sp)
ffffffffc0200b70:	6161                	addi	sp,sp,80
ffffffffc0200b72:	8082                	ret

ffffffffc0200b74 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200b74:	100027f3          	csrr	a5,sstatus
ffffffffc0200b78:	8b89                	andi	a5,a5,2
ffffffffc0200b7a:	eb89                	bnez	a5,ffffffffc0200b8c <free_pages+0x18>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;

    local_intr_save(intr_flag);
    { pmm_manager->free_pages(base, n); }
ffffffffc0200b7c:	00011797          	auipc	a5,0x11
ffffffffc0200b80:	90478793          	addi	a5,a5,-1788 # ffffffffc0211480 <pmm_manager>
ffffffffc0200b84:	639c                	ld	a5,0(a5)
ffffffffc0200b86:	0207b303          	ld	t1,32(a5)
ffffffffc0200b8a:	8302                	jr	t1
void free_pages(struct Page *base, size_t n) {
ffffffffc0200b8c:	1101                	addi	sp,sp,-32
ffffffffc0200b8e:	ec06                	sd	ra,24(sp)
ffffffffc0200b90:	e822                	sd	s0,16(sp)
ffffffffc0200b92:	e426                	sd	s1,8(sp)
ffffffffc0200b94:	842a                	mv	s0,a0
ffffffffc0200b96:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0200b98:	963ff0ef          	jal	ra,ffffffffc02004fa <intr_disable>
    { pmm_manager->free_pages(base, n); }
ffffffffc0200b9c:	00011797          	auipc	a5,0x11
ffffffffc0200ba0:	8e478793          	addi	a5,a5,-1820 # ffffffffc0211480 <pmm_manager>
ffffffffc0200ba4:	639c                	ld	a5,0(a5)
ffffffffc0200ba6:	85a6                	mv	a1,s1
ffffffffc0200ba8:	8522                	mv	a0,s0
ffffffffc0200baa:	739c                	ld	a5,32(a5)
ffffffffc0200bac:	9782                	jalr	a5
    local_intr_restore(intr_flag);
}
ffffffffc0200bae:	6442                	ld	s0,16(sp)
ffffffffc0200bb0:	60e2                	ld	ra,24(sp)
ffffffffc0200bb2:	64a2                	ld	s1,8(sp)
ffffffffc0200bb4:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0200bb6:	93fff06f          	j	ffffffffc02004f4 <intr_enable>

ffffffffc0200bba <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200bba:	100027f3          	csrr	a5,sstatus
ffffffffc0200bbe:	8b89                	andi	a5,a5,2
ffffffffc0200bc0:	eb89                	bnez	a5,ffffffffc0200bd2 <nr_free_pages+0x18>
// of current free memory
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc0200bc2:	00011797          	auipc	a5,0x11
ffffffffc0200bc6:	8be78793          	addi	a5,a5,-1858 # ffffffffc0211480 <pmm_manager>
ffffffffc0200bca:	639c                	ld	a5,0(a5)
ffffffffc0200bcc:	0287b303          	ld	t1,40(a5)
ffffffffc0200bd0:	8302                	jr	t1
size_t nr_free_pages(void) {
ffffffffc0200bd2:	1141                	addi	sp,sp,-16
ffffffffc0200bd4:	e406                	sd	ra,8(sp)
ffffffffc0200bd6:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0200bd8:	923ff0ef          	jal	ra,ffffffffc02004fa <intr_disable>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc0200bdc:	00011797          	auipc	a5,0x11
ffffffffc0200be0:	8a478793          	addi	a5,a5,-1884 # ffffffffc0211480 <pmm_manager>
ffffffffc0200be4:	639c                	ld	a5,0(a5)
ffffffffc0200be6:	779c                	ld	a5,40(a5)
ffffffffc0200be8:	9782                	jalr	a5
ffffffffc0200bea:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0200bec:	909ff0ef          	jal	ra,ffffffffc02004f4 <intr_enable>
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0200bf0:	8522                	mv	a0,s0
ffffffffc0200bf2:	60a2                	ld	ra,8(sp)
ffffffffc0200bf4:	6402                	ld	s0,0(sp)
ffffffffc0200bf6:	0141                	addi	sp,sp,16
ffffffffc0200bf8:	8082                	ret

ffffffffc0200bfa <get_pte>:
// parameter:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0200bfa:	715d                	addi	sp,sp,-80
ffffffffc0200bfc:	fc26                	sd	s1,56(sp)
     *   PTE_W           0x002                   // page table/directory entry
     * flags bit : Writeable
     *   PTE_U           0x004                   // page table/directory entry
     * flags bit : User can access
     */
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0200bfe:	01e5d493          	srli	s1,a1,0x1e
ffffffffc0200c02:	1ff4f493          	andi	s1,s1,511
ffffffffc0200c06:	048e                	slli	s1,s1,0x3
ffffffffc0200c08:	94aa                	add	s1,s1,a0
    //cprintf("pdep1: \n%p\n",*pdep1);

    if (!(*pdep1 & PTE_V)) {
ffffffffc0200c0a:	6094                	ld	a3,0(s1)
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0200c0c:	f84a                	sd	s2,48(sp)
ffffffffc0200c0e:	f44e                	sd	s3,40(sp)
ffffffffc0200c10:	f052                	sd	s4,32(sp)
ffffffffc0200c12:	e486                	sd	ra,72(sp)
ffffffffc0200c14:	e0a2                	sd	s0,64(sp)
ffffffffc0200c16:	ec56                	sd	s5,24(sp)
ffffffffc0200c18:	e85a                	sd	s6,16(sp)
ffffffffc0200c1a:	e45e                	sd	s7,8(sp)
    if (!(*pdep1 & PTE_V)) {
ffffffffc0200c1c:	0016f793          	andi	a5,a3,1
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0200c20:	892e                	mv	s2,a1
ffffffffc0200c22:	8a32                	mv	s4,a2
ffffffffc0200c24:	00011997          	auipc	s3,0x11
ffffffffc0200c28:	83498993          	addi	s3,s3,-1996 # ffffffffc0211458 <npage>
    if (!(*pdep1 & PTE_V)) {
ffffffffc0200c2c:	e3c9                	bnez	a5,ffffffffc0200cae <get_pte+0xb4>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0200c2e:	16060163          	beqz	a2,ffffffffc0200d90 <get_pte+0x196>
ffffffffc0200c32:	4505                	li	a0,1
ffffffffc0200c34:	eb9ff0ef          	jal	ra,ffffffffc0200aec <alloc_pages>
ffffffffc0200c38:	842a                	mv	s0,a0
ffffffffc0200c3a:	14050b63          	beqz	a0,ffffffffc0200d90 <get_pte+0x196>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200c3e:	00011b97          	auipc	s7,0x11
ffffffffc0200c42:	85ab8b93          	addi	s7,s7,-1958 # ffffffffc0211498 <pages>
ffffffffc0200c46:	000bb503          	ld	a0,0(s7)
ffffffffc0200c4a:	00004797          	auipc	a5,0x4
ffffffffc0200c4e:	12678793          	addi	a5,a5,294 # ffffffffc0204d70 <commands+0x838>
ffffffffc0200c52:	0007bb03          	ld	s6,0(a5)
ffffffffc0200c56:	40a40533          	sub	a0,s0,a0
ffffffffc0200c5a:	850d                	srai	a0,a0,0x3
ffffffffc0200c5c:	03650533          	mul	a0,a0,s6
    return pa2page(PDE_ADDR(pde));
}

static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200c60:	4785                	li	a5,1
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0200c62:	00010997          	auipc	s3,0x10
ffffffffc0200c66:	7f698993          	addi	s3,s3,2038 # ffffffffc0211458 <npage>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200c6a:	00080ab7          	lui	s5,0x80
ffffffffc0200c6e:	0009b703          	ld	a4,0(s3)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200c72:	c01c                	sw	a5,0(s0)
ffffffffc0200c74:	57fd                	li	a5,-1
ffffffffc0200c76:	83b1                	srli	a5,a5,0xc
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200c78:	9556                	add	a0,a0,s5
ffffffffc0200c7a:	8fe9                	and	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0200c7c:	0532                	slli	a0,a0,0xc
ffffffffc0200c7e:	16e7f063          	bleu	a4,a5,ffffffffc0200dde <get_pte+0x1e4>
ffffffffc0200c82:	00011797          	auipc	a5,0x11
ffffffffc0200c86:	80678793          	addi	a5,a5,-2042 # ffffffffc0211488 <va_pa_offset>
ffffffffc0200c8a:	639c                	ld	a5,0(a5)
ffffffffc0200c8c:	6605                	lui	a2,0x1
ffffffffc0200c8e:	4581                	li	a1,0
ffffffffc0200c90:	953e                	add	a0,a0,a5
ffffffffc0200c92:	27e030ef          	jal	ra,ffffffffc0203f10 <memset>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200c96:	000bb683          	ld	a3,0(s7)
ffffffffc0200c9a:	40d406b3          	sub	a3,s0,a3
ffffffffc0200c9e:	868d                	srai	a3,a3,0x3
ffffffffc0200ca0:	036686b3          	mul	a3,a3,s6
ffffffffc0200ca4:	96d6                	add	a3,a3,s5

static inline void flush_tlb() { asm volatile("sfence.vma"); }

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type) {
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0200ca6:	06aa                	slli	a3,a3,0xa
ffffffffc0200ca8:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0200cac:	e094                	sd	a3,0(s1)
    }
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0200cae:	77fd                	lui	a5,0xfffff
ffffffffc0200cb0:	068a                	slli	a3,a3,0x2
ffffffffc0200cb2:	0009b703          	ld	a4,0(s3)
ffffffffc0200cb6:	8efd                	and	a3,a3,a5
ffffffffc0200cb8:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200cbc:	0ce7fc63          	bleu	a4,a5,ffffffffc0200d94 <get_pte+0x19a>
ffffffffc0200cc0:	00010a97          	auipc	s5,0x10
ffffffffc0200cc4:	7c8a8a93          	addi	s5,s5,1992 # ffffffffc0211488 <va_pa_offset>
ffffffffc0200cc8:	000ab403          	ld	s0,0(s5)
ffffffffc0200ccc:	01595793          	srli	a5,s2,0x15
ffffffffc0200cd0:	1ff7f793          	andi	a5,a5,511
ffffffffc0200cd4:	96a2                	add	a3,a3,s0
ffffffffc0200cd6:	00379413          	slli	s0,a5,0x3
ffffffffc0200cda:	9436                	add	s0,s0,a3
//    pde_t *pdep0 = &((pde_t *)(PDE_ADDR(*pdep1)))[PDX0(la)];
    if (!(*pdep0 & PTE_V)) {
ffffffffc0200cdc:	6014                	ld	a3,0(s0)
ffffffffc0200cde:	0016f793          	andi	a5,a3,1
ffffffffc0200ce2:	ebbd                	bnez	a5,ffffffffc0200d58 <get_pte+0x15e>
    	struct Page *page;
    	if (!create || (page = alloc_page()) == NULL) {
ffffffffc0200ce4:	0a0a0663          	beqz	s4,ffffffffc0200d90 <get_pte+0x196>
ffffffffc0200ce8:	4505                	li	a0,1
ffffffffc0200cea:	e03ff0ef          	jal	ra,ffffffffc0200aec <alloc_pages>
ffffffffc0200cee:	84aa                	mv	s1,a0
ffffffffc0200cf0:	c145                	beqz	a0,ffffffffc0200d90 <get_pte+0x196>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200cf2:	00010b97          	auipc	s7,0x10
ffffffffc0200cf6:	7a6b8b93          	addi	s7,s7,1958 # ffffffffc0211498 <pages>
ffffffffc0200cfa:	000bb503          	ld	a0,0(s7)
ffffffffc0200cfe:	00004797          	auipc	a5,0x4
ffffffffc0200d02:	07278793          	addi	a5,a5,114 # ffffffffc0204d70 <commands+0x838>
ffffffffc0200d06:	0007bb03          	ld	s6,0(a5)
ffffffffc0200d0a:	40a48533          	sub	a0,s1,a0
ffffffffc0200d0e:	850d                	srai	a0,a0,0x3
ffffffffc0200d10:	03650533          	mul	a0,a0,s6
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200d14:	4785                	li	a5,1
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200d16:	00080a37          	lui	s4,0x80
    		return NULL;
    	}
    	set_page_ref(page, 1);
    	uintptr_t pa = page2pa(page);
    	memset(KADDR(pa), 0, PGSIZE);
ffffffffc0200d1a:	0009b703          	ld	a4,0(s3)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200d1e:	c09c                	sw	a5,0(s1)
ffffffffc0200d20:	57fd                	li	a5,-1
ffffffffc0200d22:	83b1                	srli	a5,a5,0xc
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200d24:	9552                	add	a0,a0,s4
ffffffffc0200d26:	8fe9                	and	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d28:	0532                	slli	a0,a0,0xc
ffffffffc0200d2a:	08e7fd63          	bleu	a4,a5,ffffffffc0200dc4 <get_pte+0x1ca>
ffffffffc0200d2e:	000ab783          	ld	a5,0(s5)
ffffffffc0200d32:	6605                	lui	a2,0x1
ffffffffc0200d34:	4581                	li	a1,0
ffffffffc0200d36:	953e                	add	a0,a0,a5
ffffffffc0200d38:	1d8030ef          	jal	ra,ffffffffc0203f10 <memset>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200d3c:	000bb683          	ld	a3,0(s7)
ffffffffc0200d40:	40d486b3          	sub	a3,s1,a3
ffffffffc0200d44:	868d                	srai	a3,a3,0x3
ffffffffc0200d46:	036686b3          	mul	a3,a3,s6
ffffffffc0200d4a:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0200d4c:	06aa                	slli	a3,a3,0xa
ffffffffc0200d4e:	0116e693          	ori	a3,a3,17
 //   	memset(pa, 0, PGSIZE);
    	*pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0200d52:	e014                	sd	a3,0(s0)
ffffffffc0200d54:	0009b703          	ld	a4,0(s3)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0200d58:	068a                	slli	a3,a3,0x2
ffffffffc0200d5a:	757d                	lui	a0,0xfffff
ffffffffc0200d5c:	8ee9                	and	a3,a3,a0
ffffffffc0200d5e:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200d62:	04e7f563          	bleu	a4,a5,ffffffffc0200dac <get_pte+0x1b2>
ffffffffc0200d66:	000ab503          	ld	a0,0(s5)
ffffffffc0200d6a:	00c95793          	srli	a5,s2,0xc
ffffffffc0200d6e:	1ff7f793          	andi	a5,a5,511
ffffffffc0200d72:	96aa                	add	a3,a3,a0
ffffffffc0200d74:	00379513          	slli	a0,a5,0x3
ffffffffc0200d78:	9536                	add	a0,a0,a3
}
ffffffffc0200d7a:	60a6                	ld	ra,72(sp)
ffffffffc0200d7c:	6406                	ld	s0,64(sp)
ffffffffc0200d7e:	74e2                	ld	s1,56(sp)
ffffffffc0200d80:	7942                	ld	s2,48(sp)
ffffffffc0200d82:	79a2                	ld	s3,40(sp)
ffffffffc0200d84:	7a02                	ld	s4,32(sp)
ffffffffc0200d86:	6ae2                	ld	s5,24(sp)
ffffffffc0200d88:	6b42                	ld	s6,16(sp)
ffffffffc0200d8a:	6ba2                	ld	s7,8(sp)
ffffffffc0200d8c:	6161                	addi	sp,sp,80
ffffffffc0200d8e:	8082                	ret
            return NULL;
ffffffffc0200d90:	4501                	li	a0,0
ffffffffc0200d92:	b7e5                	j	ffffffffc0200d7a <get_pte+0x180>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0200d94:	00004617          	auipc	a2,0x4
ffffffffc0200d98:	fe460613          	addi	a2,a2,-28 # ffffffffc0204d78 <commands+0x840>
ffffffffc0200d9c:	10400593          	li	a1,260
ffffffffc0200da0:	00004517          	auipc	a0,0x4
ffffffffc0200da4:	00050513          	mv	a0,a0
ffffffffc0200da8:	b5eff0ef          	jal	ra,ffffffffc0200106 <__panic>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0200dac:	00004617          	auipc	a2,0x4
ffffffffc0200db0:	fcc60613          	addi	a2,a2,-52 # ffffffffc0204d78 <commands+0x840>
ffffffffc0200db4:	11100593          	li	a1,273
ffffffffc0200db8:	00004517          	auipc	a0,0x4
ffffffffc0200dbc:	fe850513          	addi	a0,a0,-24 # ffffffffc0204da0 <commands+0x868>
ffffffffc0200dc0:	b46ff0ef          	jal	ra,ffffffffc0200106 <__panic>
    	memset(KADDR(pa), 0, PGSIZE);
ffffffffc0200dc4:	86aa                	mv	a3,a0
ffffffffc0200dc6:	00004617          	auipc	a2,0x4
ffffffffc0200dca:	fb260613          	addi	a2,a2,-78 # ffffffffc0204d78 <commands+0x840>
ffffffffc0200dce:	10d00593          	li	a1,269
ffffffffc0200dd2:	00004517          	auipc	a0,0x4
ffffffffc0200dd6:	fce50513          	addi	a0,a0,-50 # ffffffffc0204da0 <commands+0x868>
ffffffffc0200dda:	b2cff0ef          	jal	ra,ffffffffc0200106 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0200dde:	86aa                	mv	a3,a0
ffffffffc0200de0:	00004617          	auipc	a2,0x4
ffffffffc0200de4:	f9860613          	addi	a2,a2,-104 # ffffffffc0204d78 <commands+0x840>
ffffffffc0200de8:	10100593          	li	a1,257
ffffffffc0200dec:	00004517          	auipc	a0,0x4
ffffffffc0200df0:	fb450513          	addi	a0,a0,-76 # ffffffffc0204da0 <commands+0x868>
ffffffffc0200df4:	b12ff0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc0200df8 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0200df8:	1141                	addi	sp,sp,-16
ffffffffc0200dfa:	e022                	sd	s0,0(sp)
ffffffffc0200dfc:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0200dfe:	4601                	li	a2,0
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0200e00:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0200e02:	df9ff0ef          	jal	ra,ffffffffc0200bfa <get_pte>
    if (ptep_store != NULL) {
ffffffffc0200e06:	c011                	beqz	s0,ffffffffc0200e0a <get_page+0x12>
        *ptep_store = ptep;
ffffffffc0200e08:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc0200e0a:	c521                	beqz	a0,ffffffffc0200e52 <get_page+0x5a>
ffffffffc0200e0c:	611c                	ld	a5,0(a0)
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0200e0e:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc0200e10:	0017f713          	andi	a4,a5,1
ffffffffc0200e14:	e709                	bnez	a4,ffffffffc0200e1e <get_page+0x26>
}
ffffffffc0200e16:	60a2                	ld	ra,8(sp)
ffffffffc0200e18:	6402                	ld	s0,0(sp)
ffffffffc0200e1a:	0141                	addi	sp,sp,16
ffffffffc0200e1c:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc0200e1e:	00010717          	auipc	a4,0x10
ffffffffc0200e22:	63a70713          	addi	a4,a4,1594 # ffffffffc0211458 <npage>
ffffffffc0200e26:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc0200e28:	078a                	slli	a5,a5,0x2
ffffffffc0200e2a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0200e2c:	02e7f863          	bleu	a4,a5,ffffffffc0200e5c <get_page+0x64>
    return &pages[PPN(pa) - nbase];
ffffffffc0200e30:	fff80537          	lui	a0,0xfff80
ffffffffc0200e34:	97aa                	add	a5,a5,a0
ffffffffc0200e36:	00010697          	auipc	a3,0x10
ffffffffc0200e3a:	66268693          	addi	a3,a3,1634 # ffffffffc0211498 <pages>
ffffffffc0200e3e:	6288                	ld	a0,0(a3)
ffffffffc0200e40:	60a2                	ld	ra,8(sp)
ffffffffc0200e42:	6402                	ld	s0,0(sp)
ffffffffc0200e44:	00379713          	slli	a4,a5,0x3
ffffffffc0200e48:	97ba                	add	a5,a5,a4
ffffffffc0200e4a:	078e                	slli	a5,a5,0x3
ffffffffc0200e4c:	953e                	add	a0,a0,a5
ffffffffc0200e4e:	0141                	addi	sp,sp,16
ffffffffc0200e50:	8082                	ret
ffffffffc0200e52:	60a2                	ld	ra,8(sp)
ffffffffc0200e54:	6402                	ld	s0,0(sp)
    return NULL;
ffffffffc0200e56:	4501                	li	a0,0
}
ffffffffc0200e58:	0141                	addi	sp,sp,16
ffffffffc0200e5a:	8082                	ret
ffffffffc0200e5c:	c75ff0ef          	jal	ra,ffffffffc0200ad0 <pa2page.part.4>

ffffffffc0200e60 <page_remove>:
    }
}

// page_remove - free an Page which is related linear address la and has an
// validated pte
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0200e60:	1141                	addi	sp,sp,-16
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0200e62:	4601                	li	a2,0
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0200e64:	e406                	sd	ra,8(sp)
ffffffffc0200e66:	e022                	sd	s0,0(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0200e68:	d93ff0ef          	jal	ra,ffffffffc0200bfa <get_pte>
    if (ptep != NULL) {
ffffffffc0200e6c:	c511                	beqz	a0,ffffffffc0200e78 <page_remove+0x18>
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
ffffffffc0200e6e:	611c                	ld	a5,0(a0)
ffffffffc0200e70:	842a                	mv	s0,a0
ffffffffc0200e72:	0017f713          	andi	a4,a5,1
ffffffffc0200e76:	e709                	bnez	a4,ffffffffc0200e80 <page_remove+0x20>
        page_remove_pte(pgdir, la, ptep);
    }
}
ffffffffc0200e78:	60a2                	ld	ra,8(sp)
ffffffffc0200e7a:	6402                	ld	s0,0(sp)
ffffffffc0200e7c:	0141                	addi	sp,sp,16
ffffffffc0200e7e:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc0200e80:	00010717          	auipc	a4,0x10
ffffffffc0200e84:	5d870713          	addi	a4,a4,1496 # ffffffffc0211458 <npage>
ffffffffc0200e88:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc0200e8a:	078a                	slli	a5,a5,0x2
ffffffffc0200e8c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0200e8e:	04e7f063          	bleu	a4,a5,ffffffffc0200ece <page_remove+0x6e>
    return &pages[PPN(pa) - nbase];
ffffffffc0200e92:	fff80737          	lui	a4,0xfff80
ffffffffc0200e96:	97ba                	add	a5,a5,a4
ffffffffc0200e98:	00010717          	auipc	a4,0x10
ffffffffc0200e9c:	60070713          	addi	a4,a4,1536 # ffffffffc0211498 <pages>
ffffffffc0200ea0:	6308                	ld	a0,0(a4)
ffffffffc0200ea2:	00379713          	slli	a4,a5,0x3
ffffffffc0200ea6:	97ba                	add	a5,a5,a4
ffffffffc0200ea8:	078e                	slli	a5,a5,0x3
ffffffffc0200eaa:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0200eac:	411c                	lw	a5,0(a0)
ffffffffc0200eae:	fff7871b          	addiw	a4,a5,-1
ffffffffc0200eb2:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0200eb4:	cb09                	beqz	a4,ffffffffc0200ec6 <page_remove+0x66>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc0200eb6:	00043023          	sd	zero,0(s0)
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc0200eba:	12000073          	sfence.vma
}
ffffffffc0200ebe:	60a2                	ld	ra,8(sp)
ffffffffc0200ec0:	6402                	ld	s0,0(sp)
ffffffffc0200ec2:	0141                	addi	sp,sp,16
ffffffffc0200ec4:	8082                	ret
            free_page(page);
ffffffffc0200ec6:	4585                	li	a1,1
ffffffffc0200ec8:	cadff0ef          	jal	ra,ffffffffc0200b74 <free_pages>
ffffffffc0200ecc:	b7ed                	j	ffffffffc0200eb6 <page_remove+0x56>
ffffffffc0200ece:	c03ff0ef          	jal	ra,ffffffffc0200ad0 <pa2page.part.4>

ffffffffc0200ed2 <page_insert>:
//  page:  the Page which need to map
//  la:    the linear address need to map
//  perm:  the permission of this Page which is setted in related pte
// return value: always 0
// note: PT is changed, so the TLB need to be invalidate
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0200ed2:	7179                	addi	sp,sp,-48
ffffffffc0200ed4:	87b2                	mv	a5,a2
ffffffffc0200ed6:	f022                	sd	s0,32(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0200ed8:	4605                	li	a2,1
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0200eda:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0200edc:	85be                	mv	a1,a5
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0200ede:	ec26                	sd	s1,24(sp)
ffffffffc0200ee0:	f406                	sd	ra,40(sp)
ffffffffc0200ee2:	e84a                	sd	s2,16(sp)
ffffffffc0200ee4:	e44e                	sd	s3,8(sp)
ffffffffc0200ee6:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0200ee8:	d13ff0ef          	jal	ra,ffffffffc0200bfa <get_pte>
    if (ptep == NULL) {
ffffffffc0200eec:	c945                	beqz	a0,ffffffffc0200f9c <page_insert+0xca>
    page->ref += 1;
ffffffffc0200eee:	4014                	lw	a3,0(s0)
        return -E_NO_MEM;
    }
    page_ref_inc(page);
    if (*ptep & PTE_V) {
ffffffffc0200ef0:	611c                	ld	a5,0(a0)
ffffffffc0200ef2:	892a                	mv	s2,a0
ffffffffc0200ef4:	0016871b          	addiw	a4,a3,1
ffffffffc0200ef8:	c018                	sw	a4,0(s0)
ffffffffc0200efa:	0017f713          	andi	a4,a5,1
ffffffffc0200efe:	e339                	bnez	a4,ffffffffc0200f44 <page_insert+0x72>
ffffffffc0200f00:	00010797          	auipc	a5,0x10
ffffffffc0200f04:	59878793          	addi	a5,a5,1432 # ffffffffc0211498 <pages>
ffffffffc0200f08:	639c                	ld	a5,0(a5)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200f0a:	00004717          	auipc	a4,0x4
ffffffffc0200f0e:	e6670713          	addi	a4,a4,-410 # ffffffffc0204d70 <commands+0x838>
ffffffffc0200f12:	40f407b3          	sub	a5,s0,a5
ffffffffc0200f16:	6300                	ld	s0,0(a4)
ffffffffc0200f18:	878d                	srai	a5,a5,0x3
ffffffffc0200f1a:	000806b7          	lui	a3,0x80
ffffffffc0200f1e:	028787b3          	mul	a5,a5,s0
ffffffffc0200f22:	97b6                	add	a5,a5,a3
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0200f24:	07aa                	slli	a5,a5,0xa
ffffffffc0200f26:	8fc5                	or	a5,a5,s1
ffffffffc0200f28:	0017e793          	ori	a5,a5,1
            page_ref_dec(page);
        } else {
            page_remove_pte(pgdir, la, ptep);
        }
    }
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0200f2c:	00f93023          	sd	a5,0(s2)
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc0200f30:	12000073          	sfence.vma
    tlb_invalidate(pgdir, la);
    return 0;
ffffffffc0200f34:	4501                	li	a0,0
}
ffffffffc0200f36:	70a2                	ld	ra,40(sp)
ffffffffc0200f38:	7402                	ld	s0,32(sp)
ffffffffc0200f3a:	64e2                	ld	s1,24(sp)
ffffffffc0200f3c:	6942                	ld	s2,16(sp)
ffffffffc0200f3e:	69a2                	ld	s3,8(sp)
ffffffffc0200f40:	6145                	addi	sp,sp,48
ffffffffc0200f42:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc0200f44:	00010717          	auipc	a4,0x10
ffffffffc0200f48:	51470713          	addi	a4,a4,1300 # ffffffffc0211458 <npage>
ffffffffc0200f4c:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc0200f4e:	00279513          	slli	a0,a5,0x2
ffffffffc0200f52:	8131                	srli	a0,a0,0xc
    if (PPN(pa) >= npage) {
ffffffffc0200f54:	04e57663          	bleu	a4,a0,ffffffffc0200fa0 <page_insert+0xce>
    return &pages[PPN(pa) - nbase];
ffffffffc0200f58:	fff807b7          	lui	a5,0xfff80
ffffffffc0200f5c:	953e                	add	a0,a0,a5
ffffffffc0200f5e:	00010997          	auipc	s3,0x10
ffffffffc0200f62:	53a98993          	addi	s3,s3,1338 # ffffffffc0211498 <pages>
ffffffffc0200f66:	0009b783          	ld	a5,0(s3)
ffffffffc0200f6a:	00351713          	slli	a4,a0,0x3
ffffffffc0200f6e:	953a                	add	a0,a0,a4
ffffffffc0200f70:	050e                	slli	a0,a0,0x3
ffffffffc0200f72:	953e                	add	a0,a0,a5
        if (p == page) {
ffffffffc0200f74:	00a40e63          	beq	s0,a0,ffffffffc0200f90 <page_insert+0xbe>
    page->ref -= 1;
ffffffffc0200f78:	411c                	lw	a5,0(a0)
ffffffffc0200f7a:	fff7871b          	addiw	a4,a5,-1
ffffffffc0200f7e:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0200f80:	cb11                	beqz	a4,ffffffffc0200f94 <page_insert+0xc2>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc0200f82:	00093023          	sd	zero,0(s2)
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc0200f86:	12000073          	sfence.vma
ffffffffc0200f8a:	0009b783          	ld	a5,0(s3)
ffffffffc0200f8e:	bfb5                	j	ffffffffc0200f0a <page_insert+0x38>
    page->ref -= 1;
ffffffffc0200f90:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0200f92:	bfa5                	j	ffffffffc0200f0a <page_insert+0x38>
            free_page(page);
ffffffffc0200f94:	4585                	li	a1,1
ffffffffc0200f96:	bdfff0ef          	jal	ra,ffffffffc0200b74 <free_pages>
ffffffffc0200f9a:	b7e5                	j	ffffffffc0200f82 <page_insert+0xb0>
        return -E_NO_MEM;
ffffffffc0200f9c:	5571                	li	a0,-4
ffffffffc0200f9e:	bf61                	j	ffffffffc0200f36 <page_insert+0x64>
ffffffffc0200fa0:	b31ff0ef          	jal	ra,ffffffffc0200ad0 <pa2page.part.4>

ffffffffc0200fa4 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0200fa4:	00005797          	auipc	a5,0x5
ffffffffc0200fa8:	0a478793          	addi	a5,a5,164 # ffffffffc0206048 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200fac:	638c                	ld	a1,0(a5)
void pmm_init(void) {
ffffffffc0200fae:	711d                	addi	sp,sp,-96
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200fb0:	00004517          	auipc	a0,0x4
ffffffffc0200fb4:	e8850513          	addi	a0,a0,-376 # ffffffffc0204e38 <commands+0x900>
void pmm_init(void) {
ffffffffc0200fb8:	ec86                	sd	ra,88(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0200fba:	00010717          	auipc	a4,0x10
ffffffffc0200fbe:	4cf73323          	sd	a5,1222(a4) # ffffffffc0211480 <pmm_manager>
void pmm_init(void) {
ffffffffc0200fc2:	e8a2                	sd	s0,80(sp)
ffffffffc0200fc4:	e4a6                	sd	s1,72(sp)
ffffffffc0200fc6:	e0ca                	sd	s2,64(sp)
ffffffffc0200fc8:	fc4e                	sd	s3,56(sp)
ffffffffc0200fca:	f852                	sd	s4,48(sp)
ffffffffc0200fcc:	f456                	sd	s5,40(sp)
ffffffffc0200fce:	f05a                	sd	s6,32(sp)
ffffffffc0200fd0:	ec5e                	sd	s7,24(sp)
ffffffffc0200fd2:	e862                	sd	s8,16(sp)
ffffffffc0200fd4:	e466                	sd	s9,8(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0200fd6:	00010417          	auipc	s0,0x10
ffffffffc0200fda:	4aa40413          	addi	s0,s0,1194 # ffffffffc0211480 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200fde:	8e0ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    pmm_manager->init();
ffffffffc0200fe2:	601c                	ld	a5,0(s0)
    cprintf("membegin %llx memend %llx mem_size %llx\n",mem_begin, mem_end, mem_size);
ffffffffc0200fe4:	49c5                	li	s3,17
ffffffffc0200fe6:	40100a13          	li	s4,1025
    pmm_manager->init();
ffffffffc0200fea:	679c                	ld	a5,8(a5)
ffffffffc0200fec:	00010497          	auipc	s1,0x10
ffffffffc0200ff0:	46c48493          	addi	s1,s1,1132 # ffffffffc0211458 <npage>
ffffffffc0200ff4:	00010917          	auipc	s2,0x10
ffffffffc0200ff8:	4a490913          	addi	s2,s2,1188 # ffffffffc0211498 <pages>
ffffffffc0200ffc:	9782                	jalr	a5
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0200ffe:	57f5                	li	a5,-3
ffffffffc0201000:	07fa                	slli	a5,a5,0x1e
    cprintf("membegin %llx memend %llx mem_size %llx\n",mem_begin, mem_end, mem_size);
ffffffffc0201002:	07e006b7          	lui	a3,0x7e00
ffffffffc0201006:	01b99613          	slli	a2,s3,0x1b
ffffffffc020100a:	015a1593          	slli	a1,s4,0x15
ffffffffc020100e:	00004517          	auipc	a0,0x4
ffffffffc0201012:	e4250513          	addi	a0,a0,-446 # ffffffffc0204e50 <commands+0x918>
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0201016:	00010717          	auipc	a4,0x10
ffffffffc020101a:	46f73923          	sd	a5,1138(a4) # ffffffffc0211488 <va_pa_offset>
    cprintf("membegin %llx memend %llx mem_size %llx\n",mem_begin, mem_end, mem_size);
ffffffffc020101e:	8a0ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("physcial memory map:\n");
ffffffffc0201022:	00004517          	auipc	a0,0x4
ffffffffc0201026:	e5e50513          	addi	a0,a0,-418 # ffffffffc0204e80 <commands+0x948>
ffffffffc020102a:	894ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc020102e:	01b99693          	slli	a3,s3,0x1b
ffffffffc0201032:	16fd                	addi	a3,a3,-1
ffffffffc0201034:	015a1613          	slli	a2,s4,0x15
ffffffffc0201038:	07e005b7          	lui	a1,0x7e00
ffffffffc020103c:	00004517          	auipc	a0,0x4
ffffffffc0201040:	e5c50513          	addi	a0,a0,-420 # ffffffffc0204e98 <commands+0x960>
ffffffffc0201044:	87aff0ef          	jal	ra,ffffffffc02000be <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201048:	777d                	lui	a4,0xfffff
ffffffffc020104a:	00011797          	auipc	a5,0x11
ffffffffc020104e:	54d78793          	addi	a5,a5,1357 # ffffffffc0212597 <end+0xfff>
ffffffffc0201052:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc0201054:	00088737          	lui	a4,0x88
ffffffffc0201058:	00010697          	auipc	a3,0x10
ffffffffc020105c:	40e6b023          	sd	a4,1024(a3) # ffffffffc0211458 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201060:	00010717          	auipc	a4,0x10
ffffffffc0201064:	42f73c23          	sd	a5,1080(a4) # ffffffffc0211498 <pages>
ffffffffc0201068:	4681                	li	a3,0
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020106a:	4701                	li	a4,0
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020106c:	4585                	li	a1,1
ffffffffc020106e:	fff80637          	lui	a2,0xfff80
ffffffffc0201072:	a019                	j	ffffffffc0201078 <pmm_init+0xd4>
ffffffffc0201074:	00093783          	ld	a5,0(s2)
        SetPageReserved(pages + i);
ffffffffc0201078:	97b6                	add	a5,a5,a3
ffffffffc020107a:	07a1                	addi	a5,a5,8
ffffffffc020107c:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201080:	609c                	ld	a5,0(s1)
ffffffffc0201082:	0705                	addi	a4,a4,1
ffffffffc0201084:	04868693          	addi	a3,a3,72
ffffffffc0201088:	00c78533          	add	a0,a5,a2
ffffffffc020108c:	fea764e3          	bltu	a4,a0,ffffffffc0201074 <pmm_init+0xd0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201090:	00093503          	ld	a0,0(s2)
ffffffffc0201094:	00379693          	slli	a3,a5,0x3
ffffffffc0201098:	96be                	add	a3,a3,a5
ffffffffc020109a:	fdc00737          	lui	a4,0xfdc00
ffffffffc020109e:	972a                	add	a4,a4,a0
ffffffffc02010a0:	068e                	slli	a3,a3,0x3
ffffffffc02010a2:	96ba                	add	a3,a3,a4
ffffffffc02010a4:	c0200737          	lui	a4,0xc0200
ffffffffc02010a8:	58e6ea63          	bltu	a3,a4,ffffffffc020163c <pmm_init+0x698>
ffffffffc02010ac:	00010997          	auipc	s3,0x10
ffffffffc02010b0:	3dc98993          	addi	s3,s3,988 # ffffffffc0211488 <va_pa_offset>
ffffffffc02010b4:	0009b703          	ld	a4,0(s3)
    if (freemem < mem_end) {
ffffffffc02010b8:	45c5                	li	a1,17
ffffffffc02010ba:	05ee                	slli	a1,a1,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02010bc:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc02010be:	44b6ef63          	bltu	a3,a1,ffffffffc020151c <pmm_init+0x578>

    return page;
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02010c2:	601c                	ld	a5,0(s0)
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc02010c4:	00010417          	auipc	s0,0x10
ffffffffc02010c8:	38c40413          	addi	s0,s0,908 # ffffffffc0211450 <boot_pgdir>
    pmm_manager->check();
ffffffffc02010cc:	7b9c                	ld	a5,48(a5)
ffffffffc02010ce:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02010d0:	00004517          	auipc	a0,0x4
ffffffffc02010d4:	e1850513          	addi	a0,a0,-488 # ffffffffc0204ee8 <commands+0x9b0>
ffffffffc02010d8:	fe7fe0ef          	jal	ra,ffffffffc02000be <cprintf>
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc02010dc:	00008697          	auipc	a3,0x8
ffffffffc02010e0:	f2468693          	addi	a3,a3,-220 # ffffffffc0209000 <boot_page_table_sv39>
ffffffffc02010e4:	00010797          	auipc	a5,0x10
ffffffffc02010e8:	36d7b623          	sd	a3,876(a5) # ffffffffc0211450 <boot_pgdir>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc02010ec:	c02007b7          	lui	a5,0xc0200
ffffffffc02010f0:	0ef6ece3          	bltu	a3,a5,ffffffffc02019e8 <pmm_init+0xa44>
ffffffffc02010f4:	0009b783          	ld	a5,0(s3)
ffffffffc02010f8:	8e9d                	sub	a3,a3,a5
ffffffffc02010fa:	00010797          	auipc	a5,0x10
ffffffffc02010fe:	38d7bb23          	sd	a3,918(a5) # ffffffffc0211490 <boot_cr3>
    // assert(npage <= KMEMSIZE / PGSIZE);
    // The memory starts at 2GB in RISC-V
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store=nr_free_pages();
ffffffffc0201102:	ab9ff0ef          	jal	ra,ffffffffc0200bba <nr_free_pages>

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0201106:	6098                	ld	a4,0(s1)
ffffffffc0201108:	c80007b7          	lui	a5,0xc8000
ffffffffc020110c:	83b1                	srli	a5,a5,0xc
    nr_free_store=nr_free_pages();
ffffffffc020110e:	8a2a                	mv	s4,a0
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0201110:	0ae7ece3          	bltu	a5,a4,ffffffffc02019c8 <pmm_init+0xa24>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc0201114:	6008                	ld	a0,0(s0)
ffffffffc0201116:	4c050363          	beqz	a0,ffffffffc02015dc <pmm_init+0x638>
ffffffffc020111a:	6785                	lui	a5,0x1
ffffffffc020111c:	17fd                	addi	a5,a5,-1
ffffffffc020111e:	8fe9                	and	a5,a5,a0
ffffffffc0201120:	2781                	sext.w	a5,a5
ffffffffc0201122:	4a079d63          	bnez	a5,ffffffffc02015dc <pmm_init+0x638>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc0201126:	4601                	li	a2,0
ffffffffc0201128:	4581                	li	a1,0
ffffffffc020112a:	ccfff0ef          	jal	ra,ffffffffc0200df8 <get_page>
ffffffffc020112e:	4c051763          	bnez	a0,ffffffffc02015fc <pmm_init+0x658>

    struct Page *p1, *p2;
    p1 = alloc_page();
ffffffffc0201132:	4505                	li	a0,1
ffffffffc0201134:	9b9ff0ef          	jal	ra,ffffffffc0200aec <alloc_pages>
ffffffffc0201138:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc020113a:	6008                	ld	a0,0(s0)
ffffffffc020113c:	4681                	li	a3,0
ffffffffc020113e:	4601                	li	a2,0
ffffffffc0201140:	85d6                	mv	a1,s5
ffffffffc0201142:	d91ff0ef          	jal	ra,ffffffffc0200ed2 <page_insert>
ffffffffc0201146:	52051763          	bnez	a0,ffffffffc0201674 <pmm_init+0x6d0>
    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc020114a:	6008                	ld	a0,0(s0)
ffffffffc020114c:	4601                	li	a2,0
ffffffffc020114e:	4581                	li	a1,0
ffffffffc0201150:	aabff0ef          	jal	ra,ffffffffc0200bfa <get_pte>
ffffffffc0201154:	50050063          	beqz	a0,ffffffffc0201654 <pmm_init+0x6b0>
    assert(pte2page(*ptep) == p1);
ffffffffc0201158:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc020115a:	0017f713          	andi	a4,a5,1
ffffffffc020115e:	46070363          	beqz	a4,ffffffffc02015c4 <pmm_init+0x620>
    if (PPN(pa) >= npage) {
ffffffffc0201162:	6090                	ld	a2,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201164:	078a                	slli	a5,a5,0x2
ffffffffc0201166:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201168:	44c7f063          	bleu	a2,a5,ffffffffc02015a8 <pmm_init+0x604>
    return &pages[PPN(pa) - nbase];
ffffffffc020116c:	fff80737          	lui	a4,0xfff80
ffffffffc0201170:	97ba                	add	a5,a5,a4
ffffffffc0201172:	00379713          	slli	a4,a5,0x3
ffffffffc0201176:	00093683          	ld	a3,0(s2)
ffffffffc020117a:	97ba                	add	a5,a5,a4
ffffffffc020117c:	078e                	slli	a5,a5,0x3
ffffffffc020117e:	97b6                	add	a5,a5,a3
ffffffffc0201180:	5efa9463          	bne	s5,a5,ffffffffc0201768 <pmm_init+0x7c4>
    assert(page_ref(p1) == 1);
ffffffffc0201184:	000aab83          	lw	s7,0(s5)
ffffffffc0201188:	4785                	li	a5,1
ffffffffc020118a:	5afb9f63          	bne	s7,a5,ffffffffc0201748 <pmm_init+0x7a4>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc020118e:	6008                	ld	a0,0(s0)
ffffffffc0201190:	76fd                	lui	a3,0xfffff
ffffffffc0201192:	611c                	ld	a5,0(a0)
ffffffffc0201194:	078a                	slli	a5,a5,0x2
ffffffffc0201196:	8ff5                	and	a5,a5,a3
ffffffffc0201198:	00c7d713          	srli	a4,a5,0xc
ffffffffc020119c:	58c77963          	bleu	a2,a4,ffffffffc020172e <pmm_init+0x78a>
ffffffffc02011a0:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02011a4:	97e2                	add	a5,a5,s8
ffffffffc02011a6:	0007bb03          	ld	s6,0(a5) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
ffffffffc02011aa:	0b0a                	slli	s6,s6,0x2
ffffffffc02011ac:	00db7b33          	and	s6,s6,a3
ffffffffc02011b0:	00cb5793          	srli	a5,s6,0xc
ffffffffc02011b4:	56c7f063          	bleu	a2,a5,ffffffffc0201714 <pmm_init+0x770>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02011b8:	4601                	li	a2,0
ffffffffc02011ba:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02011bc:	9b62                	add	s6,s6,s8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02011be:	a3dff0ef          	jal	ra,ffffffffc0200bfa <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02011c2:	0b21                	addi	s6,s6,8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02011c4:	53651863          	bne	a0,s6,ffffffffc02016f4 <pmm_init+0x750>

    p2 = alloc_page();
ffffffffc02011c8:	4505                	li	a0,1
ffffffffc02011ca:	923ff0ef          	jal	ra,ffffffffc0200aec <alloc_pages>
ffffffffc02011ce:	8b2a                	mv	s6,a0
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02011d0:	6008                	ld	a0,0(s0)
ffffffffc02011d2:	46d1                	li	a3,20
ffffffffc02011d4:	6605                	lui	a2,0x1
ffffffffc02011d6:	85da                	mv	a1,s6
ffffffffc02011d8:	cfbff0ef          	jal	ra,ffffffffc0200ed2 <page_insert>
ffffffffc02011dc:	4e051c63          	bnez	a0,ffffffffc02016d4 <pmm_init+0x730>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc02011e0:	6008                	ld	a0,0(s0)
ffffffffc02011e2:	4601                	li	a2,0
ffffffffc02011e4:	6585                	lui	a1,0x1
ffffffffc02011e6:	a15ff0ef          	jal	ra,ffffffffc0200bfa <get_pte>
ffffffffc02011ea:	4c050563          	beqz	a0,ffffffffc02016b4 <pmm_init+0x710>
    assert(*ptep & PTE_U);
ffffffffc02011ee:	611c                	ld	a5,0(a0)
ffffffffc02011f0:	0107f713          	andi	a4,a5,16
ffffffffc02011f4:	4a070063          	beqz	a4,ffffffffc0201694 <pmm_init+0x6f0>
    assert(*ptep & PTE_W);
ffffffffc02011f8:	8b91                	andi	a5,a5,4
ffffffffc02011fa:	66078763          	beqz	a5,ffffffffc0201868 <pmm_init+0x8c4>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc02011fe:	6008                	ld	a0,0(s0)
ffffffffc0201200:	611c                	ld	a5,0(a0)
ffffffffc0201202:	8bc1                	andi	a5,a5,16
ffffffffc0201204:	64078263          	beqz	a5,ffffffffc0201848 <pmm_init+0x8a4>
    assert(page_ref(p2) == 1);
ffffffffc0201208:	000b2783          	lw	a5,0(s6)
ffffffffc020120c:	61779e63          	bne	a5,s7,ffffffffc0201828 <pmm_init+0x884>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0201210:	4681                	li	a3,0
ffffffffc0201212:	6605                	lui	a2,0x1
ffffffffc0201214:	85d6                	mv	a1,s5
ffffffffc0201216:	cbdff0ef          	jal	ra,ffffffffc0200ed2 <page_insert>
ffffffffc020121a:	5e051763          	bnez	a0,ffffffffc0201808 <pmm_init+0x864>
    assert(page_ref(p1) == 2);
ffffffffc020121e:	000aa703          	lw	a4,0(s5)
ffffffffc0201222:	4789                	li	a5,2
ffffffffc0201224:	5cf71263          	bne	a4,a5,ffffffffc02017e8 <pmm_init+0x844>
    assert(page_ref(p2) == 0);
ffffffffc0201228:	000b2783          	lw	a5,0(s6)
ffffffffc020122c:	58079e63          	bnez	a5,ffffffffc02017c8 <pmm_init+0x824>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0201230:	6008                	ld	a0,0(s0)
ffffffffc0201232:	4601                	li	a2,0
ffffffffc0201234:	6585                	lui	a1,0x1
ffffffffc0201236:	9c5ff0ef          	jal	ra,ffffffffc0200bfa <get_pte>
ffffffffc020123a:	56050763          	beqz	a0,ffffffffc02017a8 <pmm_init+0x804>
    assert(pte2page(*ptep) == p1);
ffffffffc020123e:	6114                	ld	a3,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0201240:	0016f793          	andi	a5,a3,1
ffffffffc0201244:	38078063          	beqz	a5,ffffffffc02015c4 <pmm_init+0x620>
    if (PPN(pa) >= npage) {
ffffffffc0201248:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc020124a:	00269793          	slli	a5,a3,0x2
ffffffffc020124e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201250:	34e7fc63          	bleu	a4,a5,ffffffffc02015a8 <pmm_init+0x604>
    return &pages[PPN(pa) - nbase];
ffffffffc0201254:	fff80737          	lui	a4,0xfff80
ffffffffc0201258:	97ba                	add	a5,a5,a4
ffffffffc020125a:	00379713          	slli	a4,a5,0x3
ffffffffc020125e:	00093603          	ld	a2,0(s2)
ffffffffc0201262:	97ba                	add	a5,a5,a4
ffffffffc0201264:	078e                	slli	a5,a5,0x3
ffffffffc0201266:	97b2                	add	a5,a5,a2
ffffffffc0201268:	52fa9063          	bne	s5,a5,ffffffffc0201788 <pmm_init+0x7e4>
    assert((*ptep & PTE_U) == 0);
ffffffffc020126c:	8ac1                	andi	a3,a3,16
ffffffffc020126e:	6e069d63          	bnez	a3,ffffffffc0201968 <pmm_init+0x9c4>

    page_remove(boot_pgdir, 0x0);
ffffffffc0201272:	6008                	ld	a0,0(s0)
ffffffffc0201274:	4581                	li	a1,0
ffffffffc0201276:	bebff0ef          	jal	ra,ffffffffc0200e60 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc020127a:	000aa703          	lw	a4,0(s5)
ffffffffc020127e:	4785                	li	a5,1
ffffffffc0201280:	6cf71463          	bne	a4,a5,ffffffffc0201948 <pmm_init+0x9a4>
    assert(page_ref(p2) == 0);
ffffffffc0201284:	000b2783          	lw	a5,0(s6)
ffffffffc0201288:	6a079063          	bnez	a5,ffffffffc0201928 <pmm_init+0x984>

    page_remove(boot_pgdir, PGSIZE);
ffffffffc020128c:	6008                	ld	a0,0(s0)
ffffffffc020128e:	6585                	lui	a1,0x1
ffffffffc0201290:	bd1ff0ef          	jal	ra,ffffffffc0200e60 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0201294:	000aa783          	lw	a5,0(s5)
ffffffffc0201298:	66079863          	bnez	a5,ffffffffc0201908 <pmm_init+0x964>
    assert(page_ref(p2) == 0);
ffffffffc020129c:	000b2783          	lw	a5,0(s6)
ffffffffc02012a0:	70079463          	bnez	a5,ffffffffc02019a8 <pmm_init+0xa04>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc02012a4:	00043b03          	ld	s6,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc02012a8:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02012aa:	000b3783          	ld	a5,0(s6)
ffffffffc02012ae:	078a                	slli	a5,a5,0x2
ffffffffc02012b0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02012b2:	2eb7fb63          	bleu	a1,a5,ffffffffc02015a8 <pmm_init+0x604>
    return &pages[PPN(pa) - nbase];
ffffffffc02012b6:	fff80737          	lui	a4,0xfff80
ffffffffc02012ba:	973e                	add	a4,a4,a5
ffffffffc02012bc:	00371793          	slli	a5,a4,0x3
ffffffffc02012c0:	00093603          	ld	a2,0(s2)
ffffffffc02012c4:	97ba                	add	a5,a5,a4
ffffffffc02012c6:	078e                	slli	a5,a5,0x3
ffffffffc02012c8:	00f60733          	add	a4,a2,a5
ffffffffc02012cc:	4314                	lw	a3,0(a4)
ffffffffc02012ce:	4705                	li	a4,1
ffffffffc02012d0:	6ae69c63          	bne	a3,a4,ffffffffc0201988 <pmm_init+0x9e4>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02012d4:	00004a97          	auipc	s5,0x4
ffffffffc02012d8:	a9ca8a93          	addi	s5,s5,-1380 # ffffffffc0204d70 <commands+0x838>
ffffffffc02012dc:	000ab703          	ld	a4,0(s5)
ffffffffc02012e0:	4037d693          	srai	a3,a5,0x3
ffffffffc02012e4:	00080bb7          	lui	s7,0x80
ffffffffc02012e8:	02e686b3          	mul	a3,a3,a4
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc02012ec:	577d                	li	a4,-1
ffffffffc02012ee:	8331                	srli	a4,a4,0xc
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02012f0:	96de                	add	a3,a3,s7
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc02012f2:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02012f4:	06b2                	slli	a3,a3,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc02012f6:	2ab77b63          	bleu	a1,a4,ffffffffc02015ac <pmm_init+0x608>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
ffffffffc02012fa:	0009b783          	ld	a5,0(s3)
ffffffffc02012fe:	96be                	add	a3,a3,a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0201300:	629c                	ld	a5,0(a3)
ffffffffc0201302:	078a                	slli	a5,a5,0x2
ffffffffc0201304:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201306:	2ab7f163          	bleu	a1,a5,ffffffffc02015a8 <pmm_init+0x604>
    return &pages[PPN(pa) - nbase];
ffffffffc020130a:	417787b3          	sub	a5,a5,s7
ffffffffc020130e:	00379513          	slli	a0,a5,0x3
ffffffffc0201312:	97aa                	add	a5,a5,a0
ffffffffc0201314:	00379513          	slli	a0,a5,0x3
ffffffffc0201318:	9532                	add	a0,a0,a2
ffffffffc020131a:	4585                	li	a1,1
ffffffffc020131c:	859ff0ef          	jal	ra,ffffffffc0200b74 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0201320:	000b3503          	ld	a0,0(s6)
    if (PPN(pa) >= npage) {
ffffffffc0201324:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201326:	050a                	slli	a0,a0,0x2
ffffffffc0201328:	8131                	srli	a0,a0,0xc
    if (PPN(pa) >= npage) {
ffffffffc020132a:	26f57f63          	bleu	a5,a0,ffffffffc02015a8 <pmm_init+0x604>
    return &pages[PPN(pa) - nbase];
ffffffffc020132e:	417507b3          	sub	a5,a0,s7
ffffffffc0201332:	00379513          	slli	a0,a5,0x3
ffffffffc0201336:	00093703          	ld	a4,0(s2)
ffffffffc020133a:	953e                	add	a0,a0,a5
ffffffffc020133c:	050e                	slli	a0,a0,0x3
    free_page(pde2page(pd1[0]));
ffffffffc020133e:	4585                	li	a1,1
ffffffffc0201340:	953a                	add	a0,a0,a4
ffffffffc0201342:	833ff0ef          	jal	ra,ffffffffc0200b74 <free_pages>
    boot_pgdir[0] = 0;
ffffffffc0201346:	601c                	ld	a5,0(s0)
ffffffffc0201348:	0007b023          	sd	zero,0(a5)

    assert(nr_free_store==nr_free_pages());
ffffffffc020134c:	86fff0ef          	jal	ra,ffffffffc0200bba <nr_free_pages>
ffffffffc0201350:	2caa1663          	bne	s4,a0,ffffffffc020161c <pmm_init+0x678>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0201354:	00004517          	auipc	a0,0x4
ffffffffc0201358:	ebc50513          	addi	a0,a0,-324 # ffffffffc0205210 <commands+0xcd8>
ffffffffc020135c:	d63fe0ef          	jal	ra,ffffffffc02000be <cprintf>
static void check_boot_pgdir(void) {
    size_t nr_free_store;
    pte_t *ptep;
    int i;

    nr_free_store=nr_free_pages();
ffffffffc0201360:	85bff0ef          	jal	ra,ffffffffc0200bba <nr_free_pages>

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0201364:	6098                	ld	a4,0(s1)
ffffffffc0201366:	c02007b7          	lui	a5,0xc0200
    nr_free_store=nr_free_pages();
ffffffffc020136a:	8b2a                	mv	s6,a0
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc020136c:	00c71693          	slli	a3,a4,0xc
ffffffffc0201370:	1cd7fd63          	bleu	a3,a5,ffffffffc020154a <pmm_init+0x5a6>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0201374:	83b1                	srli	a5,a5,0xc
ffffffffc0201376:	6008                	ld	a0,0(s0)
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0201378:	c0200a37          	lui	s4,0xc0200
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc020137c:	1ce7f963          	bleu	a4,a5,ffffffffc020154e <pmm_init+0x5aa>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201380:	7c7d                	lui	s8,0xfffff
ffffffffc0201382:	6b85                	lui	s7,0x1
ffffffffc0201384:	a029                	j	ffffffffc020138e <pmm_init+0x3ea>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0201386:	00ca5713          	srli	a4,s4,0xc
ffffffffc020138a:	1cf77263          	bleu	a5,a4,ffffffffc020154e <pmm_init+0x5aa>
ffffffffc020138e:	0009b583          	ld	a1,0(s3)
ffffffffc0201392:	4601                	li	a2,0
ffffffffc0201394:	95d2                	add	a1,a1,s4
ffffffffc0201396:	865ff0ef          	jal	ra,ffffffffc0200bfa <get_pte>
ffffffffc020139a:	1c050763          	beqz	a0,ffffffffc0201568 <pmm_init+0x5c4>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc020139e:	611c                	ld	a5,0(a0)
ffffffffc02013a0:	078a                	slli	a5,a5,0x2
ffffffffc02013a2:	0187f7b3          	and	a5,a5,s8
ffffffffc02013a6:	1f479163          	bne	a5,s4,ffffffffc0201588 <pmm_init+0x5e4>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc02013aa:	609c                	ld	a5,0(s1)
ffffffffc02013ac:	9a5e                	add	s4,s4,s7
ffffffffc02013ae:	6008                	ld	a0,0(s0)
ffffffffc02013b0:	00c79713          	slli	a4,a5,0xc
ffffffffc02013b4:	fcea69e3          	bltu	s4,a4,ffffffffc0201386 <pmm_init+0x3e2>
    }


    assert(boot_pgdir[0] == 0);
ffffffffc02013b8:	611c                	ld	a5,0(a0)
ffffffffc02013ba:	6a079363          	bnez	a5,ffffffffc0201a60 <pmm_init+0xabc>

    struct Page *p;
    p = alloc_page();
ffffffffc02013be:	4505                	li	a0,1
ffffffffc02013c0:	f2cff0ef          	jal	ra,ffffffffc0200aec <alloc_pages>
ffffffffc02013c4:	8a2a                	mv	s4,a0
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02013c6:	6008                	ld	a0,0(s0)
ffffffffc02013c8:	4699                	li	a3,6
ffffffffc02013ca:	10000613          	li	a2,256
ffffffffc02013ce:	85d2                	mv	a1,s4
ffffffffc02013d0:	b03ff0ef          	jal	ra,ffffffffc0200ed2 <page_insert>
ffffffffc02013d4:	66051663          	bnez	a0,ffffffffc0201a40 <pmm_init+0xa9c>
    assert(page_ref(p) == 1);
ffffffffc02013d8:	000a2703          	lw	a4,0(s4) # ffffffffc0200000 <kern_entry>
ffffffffc02013dc:	4785                	li	a5,1
ffffffffc02013de:	64f71163          	bne	a4,a5,ffffffffc0201a20 <pmm_init+0xa7c>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02013e2:	6008                	ld	a0,0(s0)
ffffffffc02013e4:	6b85                	lui	s7,0x1
ffffffffc02013e6:	4699                	li	a3,6
ffffffffc02013e8:	100b8613          	addi	a2,s7,256 # 1100 <BASE_ADDRESS-0xffffffffc01fef00>
ffffffffc02013ec:	85d2                	mv	a1,s4
ffffffffc02013ee:	ae5ff0ef          	jal	ra,ffffffffc0200ed2 <page_insert>
ffffffffc02013f2:	60051763          	bnez	a0,ffffffffc0201a00 <pmm_init+0xa5c>
    assert(page_ref(p) == 2);
ffffffffc02013f6:	000a2703          	lw	a4,0(s4)
ffffffffc02013fa:	4789                	li	a5,2
ffffffffc02013fc:	4ef71663          	bne	a4,a5,ffffffffc02018e8 <pmm_init+0x944>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0201400:	00004597          	auipc	a1,0x4
ffffffffc0201404:	f4858593          	addi	a1,a1,-184 # ffffffffc0205348 <commands+0xe10>
ffffffffc0201408:	10000513          	li	a0,256
ffffffffc020140c:	2ab020ef          	jal	ra,ffffffffc0203eb6 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0201410:	100b8593          	addi	a1,s7,256
ffffffffc0201414:	10000513          	li	a0,256
ffffffffc0201418:	2b1020ef          	jal	ra,ffffffffc0203ec8 <strcmp>
ffffffffc020141c:	4a051663          	bnez	a0,ffffffffc02018c8 <pmm_init+0x924>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201420:	00093683          	ld	a3,0(s2)
ffffffffc0201424:	000abc83          	ld	s9,0(s5)
ffffffffc0201428:	00080c37          	lui	s8,0x80
ffffffffc020142c:	40da06b3          	sub	a3,s4,a3
ffffffffc0201430:	868d                	srai	a3,a3,0x3
ffffffffc0201432:	039686b3          	mul	a3,a3,s9
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201436:	5afd                	li	s5,-1
ffffffffc0201438:	609c                	ld	a5,0(s1)
ffffffffc020143a:	00cada93          	srli	s5,s5,0xc
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020143e:	96e2                	add	a3,a3,s8
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201440:	0156f733          	and	a4,a3,s5
    return page2ppn(page) << PGSHIFT;
ffffffffc0201444:	06b2                	slli	a3,a3,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201446:	16f77363          	bleu	a5,a4,ffffffffc02015ac <pmm_init+0x608>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc020144a:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc020144e:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0201452:	96be                	add	a3,a3,a5
ffffffffc0201454:	10068023          	sb	zero,256(a3) # fffffffffffff100 <end+0x3fdedb68>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0201458:	21b020ef          	jal	ra,ffffffffc0203e72 <strlen>
ffffffffc020145c:	44051663          	bnez	a0,ffffffffc02018a8 <pmm_init+0x904>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc0201460:	00043b83          	ld	s7,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc0201464:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201466:	000bb783          	ld	a5,0(s7)
ffffffffc020146a:	078a                	slli	a5,a5,0x2
ffffffffc020146c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020146e:	12e7fd63          	bleu	a4,a5,ffffffffc02015a8 <pmm_init+0x604>
    return &pages[PPN(pa) - nbase];
ffffffffc0201472:	418787b3          	sub	a5,a5,s8
ffffffffc0201476:	00379693          	slli	a3,a5,0x3
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020147a:	96be                	add	a3,a3,a5
ffffffffc020147c:	039686b3          	mul	a3,a3,s9
ffffffffc0201480:	96e2                	add	a3,a3,s8
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201482:	0156fab3          	and	s5,a3,s5
    return page2ppn(page) << PGSHIFT;
ffffffffc0201486:	06b2                	slli	a3,a3,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201488:	12eaf263          	bleu	a4,s5,ffffffffc02015ac <pmm_init+0x608>
ffffffffc020148c:	0009b983          	ld	s3,0(s3)
    free_page(p);
ffffffffc0201490:	4585                	li	a1,1
ffffffffc0201492:	8552                	mv	a0,s4
ffffffffc0201494:	99b6                	add	s3,s3,a3
ffffffffc0201496:	edeff0ef          	jal	ra,ffffffffc0200b74 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc020149a:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage) {
ffffffffc020149e:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02014a0:	078a                	slli	a5,a5,0x2
ffffffffc02014a2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02014a4:	10e7f263          	bleu	a4,a5,ffffffffc02015a8 <pmm_init+0x604>
    return &pages[PPN(pa) - nbase];
ffffffffc02014a8:	fff809b7          	lui	s3,0xfff80
ffffffffc02014ac:	97ce                	add	a5,a5,s3
ffffffffc02014ae:	00379513          	slli	a0,a5,0x3
ffffffffc02014b2:	00093703          	ld	a4,0(s2)
ffffffffc02014b6:	97aa                	add	a5,a5,a0
ffffffffc02014b8:	00379513          	slli	a0,a5,0x3
    free_page(pde2page(pd0[0]));
ffffffffc02014bc:	953a                	add	a0,a0,a4
ffffffffc02014be:	4585                	li	a1,1
ffffffffc02014c0:	eb4ff0ef          	jal	ra,ffffffffc0200b74 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc02014c4:	000bb503          	ld	a0,0(s7)
    if (PPN(pa) >= npage) {
ffffffffc02014c8:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02014ca:	050a                	slli	a0,a0,0x2
ffffffffc02014cc:	8131                	srli	a0,a0,0xc
    if (PPN(pa) >= npage) {
ffffffffc02014ce:	0cf57d63          	bleu	a5,a0,ffffffffc02015a8 <pmm_init+0x604>
    return &pages[PPN(pa) - nbase];
ffffffffc02014d2:	013507b3          	add	a5,a0,s3
ffffffffc02014d6:	00379513          	slli	a0,a5,0x3
ffffffffc02014da:	00093703          	ld	a4,0(s2)
ffffffffc02014de:	953e                	add	a0,a0,a5
ffffffffc02014e0:	050e                	slli	a0,a0,0x3
    free_page(pde2page(pd1[0]));
ffffffffc02014e2:	4585                	li	a1,1
ffffffffc02014e4:	953a                	add	a0,a0,a4
ffffffffc02014e6:	e8eff0ef          	jal	ra,ffffffffc0200b74 <free_pages>
    boot_pgdir[0] = 0;
ffffffffc02014ea:	601c                	ld	a5,0(s0)
ffffffffc02014ec:	0007b023          	sd	zero,0(a5) # ffffffffc0200000 <kern_entry>

    assert(nr_free_store==nr_free_pages());
ffffffffc02014f0:	ecaff0ef          	jal	ra,ffffffffc0200bba <nr_free_pages>
ffffffffc02014f4:	38ab1a63          	bne	s6,a0,ffffffffc0201888 <pmm_init+0x8e4>
}
ffffffffc02014f8:	6446                	ld	s0,80(sp)
ffffffffc02014fa:	60e6                	ld	ra,88(sp)
ffffffffc02014fc:	64a6                	ld	s1,72(sp)
ffffffffc02014fe:	6906                	ld	s2,64(sp)
ffffffffc0201500:	79e2                	ld	s3,56(sp)
ffffffffc0201502:	7a42                	ld	s4,48(sp)
ffffffffc0201504:	7aa2                	ld	s5,40(sp)
ffffffffc0201506:	7b02                	ld	s6,32(sp)
ffffffffc0201508:	6be2                	ld	s7,24(sp)
ffffffffc020150a:	6c42                	ld	s8,16(sp)
ffffffffc020150c:	6ca2                	ld	s9,8(sp)

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc020150e:	00004517          	auipc	a0,0x4
ffffffffc0201512:	eb250513          	addi	a0,a0,-334 # ffffffffc02053c0 <commands+0xe88>
}
ffffffffc0201516:	6125                	addi	sp,sp,96
    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0201518:	ba7fe06f          	j	ffffffffc02000be <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020151c:	6705                	lui	a4,0x1
ffffffffc020151e:	177d                	addi	a4,a4,-1
ffffffffc0201520:	96ba                	add	a3,a3,a4
    if (PPN(pa) >= npage) {
ffffffffc0201522:	00c6d713          	srli	a4,a3,0xc
ffffffffc0201526:	08f77163          	bleu	a5,a4,ffffffffc02015a8 <pmm_init+0x604>
    pmm_manager->init_memmap(base, n);
ffffffffc020152a:	00043803          	ld	a6,0(s0)
    return &pages[PPN(pa) - nbase];
ffffffffc020152e:	9732                	add	a4,a4,a2
ffffffffc0201530:	00371793          	slli	a5,a4,0x3
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201534:	767d                	lui	a2,0xfffff
ffffffffc0201536:	8ef1                	and	a3,a3,a2
ffffffffc0201538:	97ba                	add	a5,a5,a4
    pmm_manager->init_memmap(base, n);
ffffffffc020153a:	01083703          	ld	a4,16(a6)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc020153e:	8d95                	sub	a1,a1,a3
ffffffffc0201540:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0201542:	81b1                	srli	a1,a1,0xc
ffffffffc0201544:	953e                	add	a0,a0,a5
ffffffffc0201546:	9702                	jalr	a4
ffffffffc0201548:	bead                	j	ffffffffc02010c2 <pmm_init+0x11e>
ffffffffc020154a:	6008                	ld	a0,0(s0)
ffffffffc020154c:	b5b5                	j	ffffffffc02013b8 <pmm_init+0x414>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc020154e:	86d2                	mv	a3,s4
ffffffffc0201550:	00004617          	auipc	a2,0x4
ffffffffc0201554:	82860613          	addi	a2,a2,-2008 # ffffffffc0204d78 <commands+0x840>
ffffffffc0201558:	1cf00593          	li	a1,463
ffffffffc020155c:	00004517          	auipc	a0,0x4
ffffffffc0201560:	84450513          	addi	a0,a0,-1980 # ffffffffc0204da0 <commands+0x868>
ffffffffc0201564:	ba3fe0ef          	jal	ra,ffffffffc0200106 <__panic>
ffffffffc0201568:	00004697          	auipc	a3,0x4
ffffffffc020156c:	cc868693          	addi	a3,a3,-824 # ffffffffc0205230 <commands+0xcf8>
ffffffffc0201570:	00004617          	auipc	a2,0x4
ffffffffc0201574:	9b860613          	addi	a2,a2,-1608 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201578:	1cf00593          	li	a1,463
ffffffffc020157c:	00004517          	auipc	a0,0x4
ffffffffc0201580:	82450513          	addi	a0,a0,-2012 # ffffffffc0204da0 <commands+0x868>
ffffffffc0201584:	b83fe0ef          	jal	ra,ffffffffc0200106 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201588:	00004697          	auipc	a3,0x4
ffffffffc020158c:	ce868693          	addi	a3,a3,-792 # ffffffffc0205270 <commands+0xd38>
ffffffffc0201590:	00004617          	auipc	a2,0x4
ffffffffc0201594:	99860613          	addi	a2,a2,-1640 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201598:	1d000593          	li	a1,464
ffffffffc020159c:	00004517          	auipc	a0,0x4
ffffffffc02015a0:	80450513          	addi	a0,a0,-2044 # ffffffffc0204da0 <commands+0x868>
ffffffffc02015a4:	b63fe0ef          	jal	ra,ffffffffc0200106 <__panic>
ffffffffc02015a8:	d28ff0ef          	jal	ra,ffffffffc0200ad0 <pa2page.part.4>
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc02015ac:	00003617          	auipc	a2,0x3
ffffffffc02015b0:	7cc60613          	addi	a2,a2,1996 # ffffffffc0204d78 <commands+0x840>
ffffffffc02015b4:	06a00593          	li	a1,106
ffffffffc02015b8:	00004517          	auipc	a0,0x4
ffffffffc02015bc:	85850513          	addi	a0,a0,-1960 # ffffffffc0204e10 <commands+0x8d8>
ffffffffc02015c0:	b47fe0ef          	jal	ra,ffffffffc0200106 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc02015c4:	00004617          	auipc	a2,0x4
ffffffffc02015c8:	a3c60613          	addi	a2,a2,-1476 # ffffffffc0205000 <commands+0xac8>
ffffffffc02015cc:	07000593          	li	a1,112
ffffffffc02015d0:	00004517          	auipc	a0,0x4
ffffffffc02015d4:	84050513          	addi	a0,a0,-1984 # ffffffffc0204e10 <commands+0x8d8>
ffffffffc02015d8:	b2ffe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc02015dc:	00004697          	auipc	a3,0x4
ffffffffc02015e0:	96468693          	addi	a3,a3,-1692 # ffffffffc0204f40 <commands+0xa08>
ffffffffc02015e4:	00004617          	auipc	a2,0x4
ffffffffc02015e8:	94460613          	addi	a2,a2,-1724 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02015ec:	19500593          	li	a1,405
ffffffffc02015f0:	00003517          	auipc	a0,0x3
ffffffffc02015f4:	7b050513          	addi	a0,a0,1968 # ffffffffc0204da0 <commands+0x868>
ffffffffc02015f8:	b0ffe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc02015fc:	00004697          	auipc	a3,0x4
ffffffffc0201600:	97c68693          	addi	a3,a3,-1668 # ffffffffc0204f78 <commands+0xa40>
ffffffffc0201604:	00004617          	auipc	a2,0x4
ffffffffc0201608:	92460613          	addi	a2,a2,-1756 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc020160c:	19600593          	li	a1,406
ffffffffc0201610:	00003517          	auipc	a0,0x3
ffffffffc0201614:	79050513          	addi	a0,a0,1936 # ffffffffc0204da0 <commands+0x868>
ffffffffc0201618:	aeffe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc020161c:	00004697          	auipc	a3,0x4
ffffffffc0201620:	bd468693          	addi	a3,a3,-1068 # ffffffffc02051f0 <commands+0xcb8>
ffffffffc0201624:	00004617          	auipc	a2,0x4
ffffffffc0201628:	90460613          	addi	a2,a2,-1788 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc020162c:	1c200593          	li	a1,450
ffffffffc0201630:	00003517          	auipc	a0,0x3
ffffffffc0201634:	77050513          	addi	a0,a0,1904 # ffffffffc0204da0 <commands+0x868>
ffffffffc0201638:	acffe0ef          	jal	ra,ffffffffc0200106 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020163c:	00004617          	auipc	a2,0x4
ffffffffc0201640:	88460613          	addi	a2,a2,-1916 # ffffffffc0204ec0 <commands+0x988>
ffffffffc0201644:	07700593          	li	a1,119
ffffffffc0201648:	00003517          	auipc	a0,0x3
ffffffffc020164c:	75850513          	addi	a0,a0,1880 # ffffffffc0204da0 <commands+0x868>
ffffffffc0201650:	ab7fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0201654:	00004697          	auipc	a3,0x4
ffffffffc0201658:	97c68693          	addi	a3,a3,-1668 # ffffffffc0204fd0 <commands+0xa98>
ffffffffc020165c:	00004617          	auipc	a2,0x4
ffffffffc0201660:	8cc60613          	addi	a2,a2,-1844 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201664:	19c00593          	li	a1,412
ffffffffc0201668:	00003517          	auipc	a0,0x3
ffffffffc020166c:	73850513          	addi	a0,a0,1848 # ffffffffc0204da0 <commands+0x868>
ffffffffc0201670:	a97fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0201674:	00004697          	auipc	a3,0x4
ffffffffc0201678:	92c68693          	addi	a3,a3,-1748 # ffffffffc0204fa0 <commands+0xa68>
ffffffffc020167c:	00004617          	auipc	a2,0x4
ffffffffc0201680:	8ac60613          	addi	a2,a2,-1876 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201684:	19a00593          	li	a1,410
ffffffffc0201688:	00003517          	auipc	a0,0x3
ffffffffc020168c:	71850513          	addi	a0,a0,1816 # ffffffffc0204da0 <commands+0x868>
ffffffffc0201690:	a77fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0201694:	00004697          	auipc	a3,0x4
ffffffffc0201698:	a5468693          	addi	a3,a3,-1452 # ffffffffc02050e8 <commands+0xbb0>
ffffffffc020169c:	00004617          	auipc	a2,0x4
ffffffffc02016a0:	88c60613          	addi	a2,a2,-1908 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02016a4:	1a700593          	li	a1,423
ffffffffc02016a8:	00003517          	auipc	a0,0x3
ffffffffc02016ac:	6f850513          	addi	a0,a0,1784 # ffffffffc0204da0 <commands+0x868>
ffffffffc02016b0:	a57fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc02016b4:	00004697          	auipc	a3,0x4
ffffffffc02016b8:	a0468693          	addi	a3,a3,-1532 # ffffffffc02050b8 <commands+0xb80>
ffffffffc02016bc:	00004617          	auipc	a2,0x4
ffffffffc02016c0:	86c60613          	addi	a2,a2,-1940 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02016c4:	1a600593          	li	a1,422
ffffffffc02016c8:	00003517          	auipc	a0,0x3
ffffffffc02016cc:	6d850513          	addi	a0,a0,1752 # ffffffffc0204da0 <commands+0x868>
ffffffffc02016d0:	a37fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02016d4:	00004697          	auipc	a3,0x4
ffffffffc02016d8:	9ac68693          	addi	a3,a3,-1620 # ffffffffc0205080 <commands+0xb48>
ffffffffc02016dc:	00004617          	auipc	a2,0x4
ffffffffc02016e0:	84c60613          	addi	a2,a2,-1972 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02016e4:	1a500593          	li	a1,421
ffffffffc02016e8:	00003517          	auipc	a0,0x3
ffffffffc02016ec:	6b850513          	addi	a0,a0,1720 # ffffffffc0204da0 <commands+0x868>
ffffffffc02016f0:	a17fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02016f4:	00004697          	auipc	a3,0x4
ffffffffc02016f8:	96468693          	addi	a3,a3,-1692 # ffffffffc0205058 <commands+0xb20>
ffffffffc02016fc:	00004617          	auipc	a2,0x4
ffffffffc0201700:	82c60613          	addi	a2,a2,-2004 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201704:	1a200593          	li	a1,418
ffffffffc0201708:	00003517          	auipc	a0,0x3
ffffffffc020170c:	69850513          	addi	a0,a0,1688 # ffffffffc0204da0 <commands+0x868>
ffffffffc0201710:	9f7fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201714:	86da                	mv	a3,s6
ffffffffc0201716:	00003617          	auipc	a2,0x3
ffffffffc020171a:	66260613          	addi	a2,a2,1634 # ffffffffc0204d78 <commands+0x840>
ffffffffc020171e:	1a100593          	li	a1,417
ffffffffc0201722:	00003517          	auipc	a0,0x3
ffffffffc0201726:	67e50513          	addi	a0,a0,1662 # ffffffffc0204da0 <commands+0x868>
ffffffffc020172a:	9ddfe0ef          	jal	ra,ffffffffc0200106 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc020172e:	86be                	mv	a3,a5
ffffffffc0201730:	00003617          	auipc	a2,0x3
ffffffffc0201734:	64860613          	addi	a2,a2,1608 # ffffffffc0204d78 <commands+0x840>
ffffffffc0201738:	1a000593          	li	a1,416
ffffffffc020173c:	00003517          	auipc	a0,0x3
ffffffffc0201740:	66450513          	addi	a0,a0,1636 # ffffffffc0204da0 <commands+0x868>
ffffffffc0201744:	9c3fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0201748:	00004697          	auipc	a3,0x4
ffffffffc020174c:	8f868693          	addi	a3,a3,-1800 # ffffffffc0205040 <commands+0xb08>
ffffffffc0201750:	00003617          	auipc	a2,0x3
ffffffffc0201754:	7d860613          	addi	a2,a2,2008 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201758:	19e00593          	li	a1,414
ffffffffc020175c:	00003517          	auipc	a0,0x3
ffffffffc0201760:	64450513          	addi	a0,a0,1604 # ffffffffc0204da0 <commands+0x868>
ffffffffc0201764:	9a3fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0201768:	00004697          	auipc	a3,0x4
ffffffffc020176c:	8c068693          	addi	a3,a3,-1856 # ffffffffc0205028 <commands+0xaf0>
ffffffffc0201770:	00003617          	auipc	a2,0x3
ffffffffc0201774:	7b860613          	addi	a2,a2,1976 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201778:	19d00593          	li	a1,413
ffffffffc020177c:	00003517          	auipc	a0,0x3
ffffffffc0201780:	62450513          	addi	a0,a0,1572 # ffffffffc0204da0 <commands+0x868>
ffffffffc0201784:	983fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0201788:	00004697          	auipc	a3,0x4
ffffffffc020178c:	8a068693          	addi	a3,a3,-1888 # ffffffffc0205028 <commands+0xaf0>
ffffffffc0201790:	00003617          	auipc	a2,0x3
ffffffffc0201794:	79860613          	addi	a2,a2,1944 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201798:	1b000593          	li	a1,432
ffffffffc020179c:	00003517          	auipc	a0,0x3
ffffffffc02017a0:	60450513          	addi	a0,a0,1540 # ffffffffc0204da0 <commands+0x868>
ffffffffc02017a4:	963fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc02017a8:	00004697          	auipc	a3,0x4
ffffffffc02017ac:	91068693          	addi	a3,a3,-1776 # ffffffffc02050b8 <commands+0xb80>
ffffffffc02017b0:	00003617          	auipc	a2,0x3
ffffffffc02017b4:	77860613          	addi	a2,a2,1912 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02017b8:	1af00593          	li	a1,431
ffffffffc02017bc:	00003517          	auipc	a0,0x3
ffffffffc02017c0:	5e450513          	addi	a0,a0,1508 # ffffffffc0204da0 <commands+0x868>
ffffffffc02017c4:	943fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02017c8:	00004697          	auipc	a3,0x4
ffffffffc02017cc:	9b868693          	addi	a3,a3,-1608 # ffffffffc0205180 <commands+0xc48>
ffffffffc02017d0:	00003617          	auipc	a2,0x3
ffffffffc02017d4:	75860613          	addi	a2,a2,1880 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02017d8:	1ae00593          	li	a1,430
ffffffffc02017dc:	00003517          	auipc	a0,0x3
ffffffffc02017e0:	5c450513          	addi	a0,a0,1476 # ffffffffc0204da0 <commands+0x868>
ffffffffc02017e4:	923fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc02017e8:	00004697          	auipc	a3,0x4
ffffffffc02017ec:	98068693          	addi	a3,a3,-1664 # ffffffffc0205168 <commands+0xc30>
ffffffffc02017f0:	00003617          	auipc	a2,0x3
ffffffffc02017f4:	73860613          	addi	a2,a2,1848 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02017f8:	1ad00593          	li	a1,429
ffffffffc02017fc:	00003517          	auipc	a0,0x3
ffffffffc0201800:	5a450513          	addi	a0,a0,1444 # ffffffffc0204da0 <commands+0x868>
ffffffffc0201804:	903fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0201808:	00004697          	auipc	a3,0x4
ffffffffc020180c:	93068693          	addi	a3,a3,-1744 # ffffffffc0205138 <commands+0xc00>
ffffffffc0201810:	00003617          	auipc	a2,0x3
ffffffffc0201814:	71860613          	addi	a2,a2,1816 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201818:	1ac00593          	li	a1,428
ffffffffc020181c:	00003517          	auipc	a0,0x3
ffffffffc0201820:	58450513          	addi	a0,a0,1412 # ffffffffc0204da0 <commands+0x868>
ffffffffc0201824:	8e3fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0201828:	00004697          	auipc	a3,0x4
ffffffffc020182c:	8f868693          	addi	a3,a3,-1800 # ffffffffc0205120 <commands+0xbe8>
ffffffffc0201830:	00003617          	auipc	a2,0x3
ffffffffc0201834:	6f860613          	addi	a2,a2,1784 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201838:	1aa00593          	li	a1,426
ffffffffc020183c:	00003517          	auipc	a0,0x3
ffffffffc0201840:	56450513          	addi	a0,a0,1380 # ffffffffc0204da0 <commands+0x868>
ffffffffc0201844:	8c3fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0201848:	00004697          	auipc	a3,0x4
ffffffffc020184c:	8c068693          	addi	a3,a3,-1856 # ffffffffc0205108 <commands+0xbd0>
ffffffffc0201850:	00003617          	auipc	a2,0x3
ffffffffc0201854:	6d860613          	addi	a2,a2,1752 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201858:	1a900593          	li	a1,425
ffffffffc020185c:	00003517          	auipc	a0,0x3
ffffffffc0201860:	54450513          	addi	a0,a0,1348 # ffffffffc0204da0 <commands+0x868>
ffffffffc0201864:	8a3fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(*ptep & PTE_W);
ffffffffc0201868:	00004697          	auipc	a3,0x4
ffffffffc020186c:	89068693          	addi	a3,a3,-1904 # ffffffffc02050f8 <commands+0xbc0>
ffffffffc0201870:	00003617          	auipc	a2,0x3
ffffffffc0201874:	6b860613          	addi	a2,a2,1720 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201878:	1a800593          	li	a1,424
ffffffffc020187c:	00003517          	auipc	a0,0x3
ffffffffc0201880:	52450513          	addi	a0,a0,1316 # ffffffffc0204da0 <commands+0x868>
ffffffffc0201884:	883fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc0201888:	00004697          	auipc	a3,0x4
ffffffffc020188c:	96868693          	addi	a3,a3,-1688 # ffffffffc02051f0 <commands+0xcb8>
ffffffffc0201890:	00003617          	auipc	a2,0x3
ffffffffc0201894:	69860613          	addi	a2,a2,1688 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201898:	1ea00593          	li	a1,490
ffffffffc020189c:	00003517          	auipc	a0,0x3
ffffffffc02018a0:	50450513          	addi	a0,a0,1284 # ffffffffc0204da0 <commands+0x868>
ffffffffc02018a4:	863fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc02018a8:	00004697          	auipc	a3,0x4
ffffffffc02018ac:	af068693          	addi	a3,a3,-1296 # ffffffffc0205398 <commands+0xe60>
ffffffffc02018b0:	00003617          	auipc	a2,0x3
ffffffffc02018b4:	67860613          	addi	a2,a2,1656 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02018b8:	1e200593          	li	a1,482
ffffffffc02018bc:	00003517          	auipc	a0,0x3
ffffffffc02018c0:	4e450513          	addi	a0,a0,1252 # ffffffffc0204da0 <commands+0x868>
ffffffffc02018c4:	843fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02018c8:	00004697          	auipc	a3,0x4
ffffffffc02018cc:	a9868693          	addi	a3,a3,-1384 # ffffffffc0205360 <commands+0xe28>
ffffffffc02018d0:	00003617          	auipc	a2,0x3
ffffffffc02018d4:	65860613          	addi	a2,a2,1624 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02018d8:	1df00593          	li	a1,479
ffffffffc02018dc:	00003517          	auipc	a0,0x3
ffffffffc02018e0:	4c450513          	addi	a0,a0,1220 # ffffffffc0204da0 <commands+0x868>
ffffffffc02018e4:	823fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page_ref(p) == 2);
ffffffffc02018e8:	00004697          	auipc	a3,0x4
ffffffffc02018ec:	a4868693          	addi	a3,a3,-1464 # ffffffffc0205330 <commands+0xdf8>
ffffffffc02018f0:	00003617          	auipc	a2,0x3
ffffffffc02018f4:	63860613          	addi	a2,a2,1592 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02018f8:	1db00593          	li	a1,475
ffffffffc02018fc:	00003517          	auipc	a0,0x3
ffffffffc0201900:	4a450513          	addi	a0,a0,1188 # ffffffffc0204da0 <commands+0x868>
ffffffffc0201904:	803fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0201908:	00004697          	auipc	a3,0x4
ffffffffc020190c:	8a868693          	addi	a3,a3,-1880 # ffffffffc02051b0 <commands+0xc78>
ffffffffc0201910:	00003617          	auipc	a2,0x3
ffffffffc0201914:	61860613          	addi	a2,a2,1560 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201918:	1b800593          	li	a1,440
ffffffffc020191c:	00003517          	auipc	a0,0x3
ffffffffc0201920:	48450513          	addi	a0,a0,1156 # ffffffffc0204da0 <commands+0x868>
ffffffffc0201924:	fe2fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0201928:	00004697          	auipc	a3,0x4
ffffffffc020192c:	85868693          	addi	a3,a3,-1960 # ffffffffc0205180 <commands+0xc48>
ffffffffc0201930:	00003617          	auipc	a2,0x3
ffffffffc0201934:	5f860613          	addi	a2,a2,1528 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201938:	1b500593          	li	a1,437
ffffffffc020193c:	00003517          	auipc	a0,0x3
ffffffffc0201940:	46450513          	addi	a0,a0,1124 # ffffffffc0204da0 <commands+0x868>
ffffffffc0201944:	fc2fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0201948:	00003697          	auipc	a3,0x3
ffffffffc020194c:	6f868693          	addi	a3,a3,1784 # ffffffffc0205040 <commands+0xb08>
ffffffffc0201950:	00003617          	auipc	a2,0x3
ffffffffc0201954:	5d860613          	addi	a2,a2,1496 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201958:	1b400593          	li	a1,436
ffffffffc020195c:	00003517          	auipc	a0,0x3
ffffffffc0201960:	44450513          	addi	a0,a0,1092 # ffffffffc0204da0 <commands+0x868>
ffffffffc0201964:	fa2fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0201968:	00004697          	auipc	a3,0x4
ffffffffc020196c:	83068693          	addi	a3,a3,-2000 # ffffffffc0205198 <commands+0xc60>
ffffffffc0201970:	00003617          	auipc	a2,0x3
ffffffffc0201974:	5b860613          	addi	a2,a2,1464 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201978:	1b100593          	li	a1,433
ffffffffc020197c:	00003517          	auipc	a0,0x3
ffffffffc0201980:	42450513          	addi	a0,a0,1060 # ffffffffc0204da0 <commands+0x868>
ffffffffc0201984:	f82fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc0201988:	00004697          	auipc	a3,0x4
ffffffffc020198c:	84068693          	addi	a3,a3,-1984 # ffffffffc02051c8 <commands+0xc90>
ffffffffc0201990:	00003617          	auipc	a2,0x3
ffffffffc0201994:	59860613          	addi	a2,a2,1432 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201998:	1bb00593          	li	a1,443
ffffffffc020199c:	00003517          	auipc	a0,0x3
ffffffffc02019a0:	40450513          	addi	a0,a0,1028 # ffffffffc0204da0 <commands+0x868>
ffffffffc02019a4:	f62fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02019a8:	00003697          	auipc	a3,0x3
ffffffffc02019ac:	7d868693          	addi	a3,a3,2008 # ffffffffc0205180 <commands+0xc48>
ffffffffc02019b0:	00003617          	auipc	a2,0x3
ffffffffc02019b4:	57860613          	addi	a2,a2,1400 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02019b8:	1b900593          	li	a1,441
ffffffffc02019bc:	00003517          	auipc	a0,0x3
ffffffffc02019c0:	3e450513          	addi	a0,a0,996 # ffffffffc0204da0 <commands+0x868>
ffffffffc02019c4:	f42fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02019c8:	00003697          	auipc	a3,0x3
ffffffffc02019cc:	54068693          	addi	a3,a3,1344 # ffffffffc0204f08 <commands+0x9d0>
ffffffffc02019d0:	00003617          	auipc	a2,0x3
ffffffffc02019d4:	55860613          	addi	a2,a2,1368 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02019d8:	19400593          	li	a1,404
ffffffffc02019dc:	00003517          	auipc	a0,0x3
ffffffffc02019e0:	3c450513          	addi	a0,a0,964 # ffffffffc0204da0 <commands+0x868>
ffffffffc02019e4:	f22fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc02019e8:	00003617          	auipc	a2,0x3
ffffffffc02019ec:	4d860613          	addi	a2,a2,1240 # ffffffffc0204ec0 <commands+0x988>
ffffffffc02019f0:	0bd00593          	li	a1,189
ffffffffc02019f4:	00003517          	auipc	a0,0x3
ffffffffc02019f8:	3ac50513          	addi	a0,a0,940 # ffffffffc0204da0 <commands+0x868>
ffffffffc02019fc:	f0afe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0201a00:	00004697          	auipc	a3,0x4
ffffffffc0201a04:	8f068693          	addi	a3,a3,-1808 # ffffffffc02052f0 <commands+0xdb8>
ffffffffc0201a08:	00003617          	auipc	a2,0x3
ffffffffc0201a0c:	52060613          	addi	a2,a2,1312 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201a10:	1da00593          	li	a1,474
ffffffffc0201a14:	00003517          	auipc	a0,0x3
ffffffffc0201a18:	38c50513          	addi	a0,a0,908 # ffffffffc0204da0 <commands+0x868>
ffffffffc0201a1c:	eeafe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page_ref(p) == 1);
ffffffffc0201a20:	00004697          	auipc	a3,0x4
ffffffffc0201a24:	8b868693          	addi	a3,a3,-1864 # ffffffffc02052d8 <commands+0xda0>
ffffffffc0201a28:	00003617          	auipc	a2,0x3
ffffffffc0201a2c:	50060613          	addi	a2,a2,1280 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201a30:	1d900593          	li	a1,473
ffffffffc0201a34:	00003517          	auipc	a0,0x3
ffffffffc0201a38:	36c50513          	addi	a0,a0,876 # ffffffffc0204da0 <commands+0x868>
ffffffffc0201a3c:	ecafe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0201a40:	00004697          	auipc	a3,0x4
ffffffffc0201a44:	86068693          	addi	a3,a3,-1952 # ffffffffc02052a0 <commands+0xd68>
ffffffffc0201a48:	00003617          	auipc	a2,0x3
ffffffffc0201a4c:	4e060613          	addi	a2,a2,1248 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201a50:	1d800593          	li	a1,472
ffffffffc0201a54:	00003517          	auipc	a0,0x3
ffffffffc0201a58:	34c50513          	addi	a0,a0,844 # ffffffffc0204da0 <commands+0x868>
ffffffffc0201a5c:	eaafe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(boot_pgdir[0] == 0);
ffffffffc0201a60:	00004697          	auipc	a3,0x4
ffffffffc0201a64:	82868693          	addi	a3,a3,-2008 # ffffffffc0205288 <commands+0xd50>
ffffffffc0201a68:	00003617          	auipc	a2,0x3
ffffffffc0201a6c:	4c060613          	addi	a2,a2,1216 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201a70:	1d400593          	li	a1,468
ffffffffc0201a74:	00003517          	auipc	a0,0x3
ffffffffc0201a78:	32c50513          	addi	a0,a0,812 # ffffffffc0204da0 <commands+0x868>
ffffffffc0201a7c:	e8afe0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc0201a80 <tlb_invalidate>:
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc0201a80:	12000073          	sfence.vma
void tlb_invalidate(pde_t *pgdir, uintptr_t la) { flush_tlb(); }
ffffffffc0201a84:	8082                	ret

ffffffffc0201a86 <pgdir_alloc_page>:
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0201a86:	7179                	addi	sp,sp,-48
ffffffffc0201a88:	e84a                	sd	s2,16(sp)
ffffffffc0201a8a:	892a                	mv	s2,a0
    struct Page *page = alloc_page();
ffffffffc0201a8c:	4505                	li	a0,1
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0201a8e:	f022                	sd	s0,32(sp)
ffffffffc0201a90:	ec26                	sd	s1,24(sp)
ffffffffc0201a92:	e44e                	sd	s3,8(sp)
ffffffffc0201a94:	f406                	sd	ra,40(sp)
ffffffffc0201a96:	84ae                	mv	s1,a1
ffffffffc0201a98:	89b2                	mv	s3,a2
    struct Page *page = alloc_page();
ffffffffc0201a9a:	852ff0ef          	jal	ra,ffffffffc0200aec <alloc_pages>
ffffffffc0201a9e:	842a                	mv	s0,a0
    if (page != NULL) {
ffffffffc0201aa0:	cd19                	beqz	a0,ffffffffc0201abe <pgdir_alloc_page+0x38>
        if (page_insert(pgdir, page, la, perm) != 0) {
ffffffffc0201aa2:	85aa                	mv	a1,a0
ffffffffc0201aa4:	86ce                	mv	a3,s3
ffffffffc0201aa6:	8626                	mv	a2,s1
ffffffffc0201aa8:	854a                	mv	a0,s2
ffffffffc0201aaa:	c28ff0ef          	jal	ra,ffffffffc0200ed2 <page_insert>
ffffffffc0201aae:	ed39                	bnez	a0,ffffffffc0201b0c <pgdir_alloc_page+0x86>
        if (swap_init_ok) {
ffffffffc0201ab0:	00010797          	auipc	a5,0x10
ffffffffc0201ab4:	9c078793          	addi	a5,a5,-1600 # ffffffffc0211470 <swap_init_ok>
ffffffffc0201ab8:	439c                	lw	a5,0(a5)
ffffffffc0201aba:	2781                	sext.w	a5,a5
ffffffffc0201abc:	eb89                	bnez	a5,ffffffffc0201ace <pgdir_alloc_page+0x48>
}
ffffffffc0201abe:	8522                	mv	a0,s0
ffffffffc0201ac0:	70a2                	ld	ra,40(sp)
ffffffffc0201ac2:	7402                	ld	s0,32(sp)
ffffffffc0201ac4:	64e2                	ld	s1,24(sp)
ffffffffc0201ac6:	6942                	ld	s2,16(sp)
ffffffffc0201ac8:	69a2                	ld	s3,8(sp)
ffffffffc0201aca:	6145                	addi	sp,sp,48
ffffffffc0201acc:	8082                	ret
            swap_map_swappable(check_mm_struct, la, page, 0);
ffffffffc0201ace:	00010797          	auipc	a5,0x10
ffffffffc0201ad2:	9e278793          	addi	a5,a5,-1566 # ffffffffc02114b0 <check_mm_struct>
ffffffffc0201ad6:	6388                	ld	a0,0(a5)
ffffffffc0201ad8:	4681                	li	a3,0
ffffffffc0201ada:	8622                	mv	a2,s0
ffffffffc0201adc:	85a6                	mv	a1,s1
ffffffffc0201ade:	500010ef          	jal	ra,ffffffffc0202fde <swap_map_swappable>
            assert(page_ref(page) == 1);
ffffffffc0201ae2:	4018                	lw	a4,0(s0)
            page->pra_vaddr = la;
ffffffffc0201ae4:	e024                	sd	s1,64(s0)
            assert(page_ref(page) == 1);
ffffffffc0201ae6:	4785                	li	a5,1
ffffffffc0201ae8:	fcf70be3          	beq	a4,a5,ffffffffc0201abe <pgdir_alloc_page+0x38>
ffffffffc0201aec:	00003697          	auipc	a3,0x3
ffffffffc0201af0:	33468693          	addi	a3,a3,820 # ffffffffc0204e20 <commands+0x8e8>
ffffffffc0201af4:	00003617          	auipc	a2,0x3
ffffffffc0201af8:	43460613          	addi	a2,a2,1076 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201afc:	17c00593          	li	a1,380
ffffffffc0201b00:	00003517          	auipc	a0,0x3
ffffffffc0201b04:	2a050513          	addi	a0,a0,672 # ffffffffc0204da0 <commands+0x868>
ffffffffc0201b08:	dfefe0ef          	jal	ra,ffffffffc0200106 <__panic>
            free_page(page);
ffffffffc0201b0c:	8522                	mv	a0,s0
ffffffffc0201b0e:	4585                	li	a1,1
ffffffffc0201b10:	864ff0ef          	jal	ra,ffffffffc0200b74 <free_pages>
            return NULL;
ffffffffc0201b14:	4401                	li	s0,0
ffffffffc0201b16:	b765                	j	ffffffffc0201abe <pgdir_alloc_page+0x38>

ffffffffc0201b18 <kmalloc>:
}

void *kmalloc(size_t n) {
ffffffffc0201b18:	1141                	addi	sp,sp,-16
    void *ptr = NULL;
    struct Page *base = NULL;
    assert(n > 0 && n < 1024 * 0124);
ffffffffc0201b1a:	67d5                	lui	a5,0x15
void *kmalloc(size_t n) {
ffffffffc0201b1c:	e406                	sd	ra,8(sp)
    assert(n > 0 && n < 1024 * 0124);
ffffffffc0201b1e:	fff50713          	addi	a4,a0,-1
ffffffffc0201b22:	17f9                	addi	a5,a5,-2
ffffffffc0201b24:	04e7ee63          	bltu	a5,a4,ffffffffc0201b80 <kmalloc+0x68>
    int num_pages = (n + PGSIZE - 1) / PGSIZE;
ffffffffc0201b28:	6785                	lui	a5,0x1
ffffffffc0201b2a:	17fd                	addi	a5,a5,-1
ffffffffc0201b2c:	953e                	add	a0,a0,a5
    base = alloc_pages(num_pages);
ffffffffc0201b2e:	8131                	srli	a0,a0,0xc
ffffffffc0201b30:	fbdfe0ef          	jal	ra,ffffffffc0200aec <alloc_pages>
    assert(base != NULL);
ffffffffc0201b34:	c159                	beqz	a0,ffffffffc0201bba <kmalloc+0xa2>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201b36:	00010797          	auipc	a5,0x10
ffffffffc0201b3a:	96278793          	addi	a5,a5,-1694 # ffffffffc0211498 <pages>
ffffffffc0201b3e:	639c                	ld	a5,0(a5)
ffffffffc0201b40:	8d1d                	sub	a0,a0,a5
ffffffffc0201b42:	00003797          	auipc	a5,0x3
ffffffffc0201b46:	22e78793          	addi	a5,a5,558 # ffffffffc0204d70 <commands+0x838>
ffffffffc0201b4a:	6394                	ld	a3,0(a5)
ffffffffc0201b4c:	850d                	srai	a0,a0,0x3
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201b4e:	00010797          	auipc	a5,0x10
ffffffffc0201b52:	90a78793          	addi	a5,a5,-1782 # ffffffffc0211458 <npage>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201b56:	02d50533          	mul	a0,a0,a3
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201b5a:	6398                	ld	a4,0(a5)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201b5c:	000806b7          	lui	a3,0x80
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201b60:	57fd                	li	a5,-1
ffffffffc0201b62:	83b1                	srli	a5,a5,0xc
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201b64:	9536                	add	a0,a0,a3
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201b66:	8fe9                	and	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0201b68:	0532                	slli	a0,a0,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201b6a:	02e7fb63          	bleu	a4,a5,ffffffffc0201ba0 <kmalloc+0x88>
ffffffffc0201b6e:	00010797          	auipc	a5,0x10
ffffffffc0201b72:	91a78793          	addi	a5,a5,-1766 # ffffffffc0211488 <va_pa_offset>
ffffffffc0201b76:	639c                	ld	a5,0(a5)
    ptr = page2kva(base);
    return ptr;
}
ffffffffc0201b78:	60a2                	ld	ra,8(sp)
ffffffffc0201b7a:	953e                	add	a0,a0,a5
ffffffffc0201b7c:	0141                	addi	sp,sp,16
ffffffffc0201b7e:	8082                	ret
    assert(n > 0 && n < 1024 * 0124);
ffffffffc0201b80:	00003697          	auipc	a3,0x3
ffffffffc0201b84:	24068693          	addi	a3,a3,576 # ffffffffc0204dc0 <commands+0x888>
ffffffffc0201b88:	00003617          	auipc	a2,0x3
ffffffffc0201b8c:	3a060613          	addi	a2,a2,928 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201b90:	1f200593          	li	a1,498
ffffffffc0201b94:	00003517          	auipc	a0,0x3
ffffffffc0201b98:	20c50513          	addi	a0,a0,524 # ffffffffc0204da0 <commands+0x868>
ffffffffc0201b9c:	d6afe0ef          	jal	ra,ffffffffc0200106 <__panic>
ffffffffc0201ba0:	86aa                	mv	a3,a0
ffffffffc0201ba2:	00003617          	auipc	a2,0x3
ffffffffc0201ba6:	1d660613          	addi	a2,a2,470 # ffffffffc0204d78 <commands+0x840>
ffffffffc0201baa:	06a00593          	li	a1,106
ffffffffc0201bae:	00003517          	auipc	a0,0x3
ffffffffc0201bb2:	26250513          	addi	a0,a0,610 # ffffffffc0204e10 <commands+0x8d8>
ffffffffc0201bb6:	d50fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(base != NULL);
ffffffffc0201bba:	00003697          	auipc	a3,0x3
ffffffffc0201bbe:	22668693          	addi	a3,a3,550 # ffffffffc0204de0 <commands+0x8a8>
ffffffffc0201bc2:	00003617          	auipc	a2,0x3
ffffffffc0201bc6:	36660613          	addi	a2,a2,870 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201bca:	1f500593          	li	a1,501
ffffffffc0201bce:	00003517          	auipc	a0,0x3
ffffffffc0201bd2:	1d250513          	addi	a0,a0,466 # ffffffffc0204da0 <commands+0x868>
ffffffffc0201bd6:	d30fe0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc0201bda <kfree>:

void kfree(void *ptr, size_t n) {
ffffffffc0201bda:	1141                	addi	sp,sp,-16
    assert(n > 0 && n < 1024 * 0124);
ffffffffc0201bdc:	67d5                	lui	a5,0x15
void kfree(void *ptr, size_t n) {
ffffffffc0201bde:	e406                	sd	ra,8(sp)
    assert(n > 0 && n < 1024 * 0124);
ffffffffc0201be0:	fff58713          	addi	a4,a1,-1
ffffffffc0201be4:	17f9                	addi	a5,a5,-2
ffffffffc0201be6:	04e7eb63          	bltu	a5,a4,ffffffffc0201c3c <kfree+0x62>
    assert(ptr != NULL);
ffffffffc0201bea:	c941                	beqz	a0,ffffffffc0201c7a <kfree+0xa0>
    struct Page *base = NULL;
    int num_pages = (n + PGSIZE - 1) / PGSIZE;
ffffffffc0201bec:	6785                	lui	a5,0x1
ffffffffc0201bee:	17fd                	addi	a5,a5,-1
ffffffffc0201bf0:	95be                	add	a1,a1,a5
static inline struct Page *kva2page(void *kva) { return pa2page(PADDR(kva)); }
ffffffffc0201bf2:	c02007b7          	lui	a5,0xc0200
ffffffffc0201bf6:	81b1                	srli	a1,a1,0xc
ffffffffc0201bf8:	06f56463          	bltu	a0,a5,ffffffffc0201c60 <kfree+0x86>
ffffffffc0201bfc:	00010797          	auipc	a5,0x10
ffffffffc0201c00:	88c78793          	addi	a5,a5,-1908 # ffffffffc0211488 <va_pa_offset>
ffffffffc0201c04:	639c                	ld	a5,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc0201c06:	00010717          	auipc	a4,0x10
ffffffffc0201c0a:	85270713          	addi	a4,a4,-1966 # ffffffffc0211458 <npage>
ffffffffc0201c0e:	6318                	ld	a4,0(a4)
static inline struct Page *kva2page(void *kva) { return pa2page(PADDR(kva)); }
ffffffffc0201c10:	40f507b3          	sub	a5,a0,a5
    if (PPN(pa) >= npage) {
ffffffffc0201c14:	83b1                	srli	a5,a5,0xc
ffffffffc0201c16:	04e7f363          	bleu	a4,a5,ffffffffc0201c5c <kfree+0x82>
    return &pages[PPN(pa) - nbase];
ffffffffc0201c1a:	fff80537          	lui	a0,0xfff80
ffffffffc0201c1e:	97aa                	add	a5,a5,a0
ffffffffc0201c20:	00010697          	auipc	a3,0x10
ffffffffc0201c24:	87868693          	addi	a3,a3,-1928 # ffffffffc0211498 <pages>
ffffffffc0201c28:	6288                	ld	a0,0(a3)
ffffffffc0201c2a:	00379713          	slli	a4,a5,0x3
    base = kva2page(ptr);
    free_pages(base, num_pages);
}
ffffffffc0201c2e:	60a2                	ld	ra,8(sp)
ffffffffc0201c30:	97ba                	add	a5,a5,a4
ffffffffc0201c32:	078e                	slli	a5,a5,0x3
    free_pages(base, num_pages);
ffffffffc0201c34:	953e                	add	a0,a0,a5
}
ffffffffc0201c36:	0141                	addi	sp,sp,16
    free_pages(base, num_pages);
ffffffffc0201c38:	f3dfe06f          	j	ffffffffc0200b74 <free_pages>
    assert(n > 0 && n < 1024 * 0124);
ffffffffc0201c3c:	00003697          	auipc	a3,0x3
ffffffffc0201c40:	18468693          	addi	a3,a3,388 # ffffffffc0204dc0 <commands+0x888>
ffffffffc0201c44:	00003617          	auipc	a2,0x3
ffffffffc0201c48:	2e460613          	addi	a2,a2,740 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201c4c:	1fb00593          	li	a1,507
ffffffffc0201c50:	00003517          	auipc	a0,0x3
ffffffffc0201c54:	15050513          	addi	a0,a0,336 # ffffffffc0204da0 <commands+0x868>
ffffffffc0201c58:	caefe0ef          	jal	ra,ffffffffc0200106 <__panic>
ffffffffc0201c5c:	e75fe0ef          	jal	ra,ffffffffc0200ad0 <pa2page.part.4>
static inline struct Page *kva2page(void *kva) { return pa2page(PADDR(kva)); }
ffffffffc0201c60:	86aa                	mv	a3,a0
ffffffffc0201c62:	00003617          	auipc	a2,0x3
ffffffffc0201c66:	25e60613          	addi	a2,a2,606 # ffffffffc0204ec0 <commands+0x988>
ffffffffc0201c6a:	06c00593          	li	a1,108
ffffffffc0201c6e:	00003517          	auipc	a0,0x3
ffffffffc0201c72:	1a250513          	addi	a0,a0,418 # ffffffffc0204e10 <commands+0x8d8>
ffffffffc0201c76:	c90fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(ptr != NULL);
ffffffffc0201c7a:	00003697          	auipc	a3,0x3
ffffffffc0201c7e:	13668693          	addi	a3,a3,310 # ffffffffc0204db0 <commands+0x878>
ffffffffc0201c82:	00003617          	auipc	a2,0x3
ffffffffc0201c86:	2a660613          	addi	a2,a2,678 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201c8a:	1fc00593          	li	a1,508
ffffffffc0201c8e:	00003517          	auipc	a0,0x3
ffffffffc0201c92:	11250513          	addi	a0,a0,274 # ffffffffc0204da0 <commands+0x868>
ffffffffc0201c96:	c70fe0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc0201c9a <_fifo_init_mm>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0201c9a:	00010797          	auipc	a5,0x10
ffffffffc0201c9e:	80678793          	addi	a5,a5,-2042 # ffffffffc02114a0 <pra_list_head>
 */
static int
_fifo_init_mm(struct mm_struct *mm)
{     
     list_init(&pra_list_head);
     mm->sm_priv = &pra_list_head;
ffffffffc0201ca2:	f51c                	sd	a5,40(a0)
ffffffffc0201ca4:	e79c                	sd	a5,8(a5)
ffffffffc0201ca6:	e39c                	sd	a5,0(a5)
     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     return 0;
}
ffffffffc0201ca8:	4501                	li	a0,0
ffffffffc0201caa:	8082                	ret

ffffffffc0201cac <_fifo_init>:

static int
_fifo_init(void)
{
    return 0;
}
ffffffffc0201cac:	4501                	li	a0,0
ffffffffc0201cae:	8082                	ret

ffffffffc0201cb0 <_fifo_set_unswappable>:

static int
_fifo_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}
ffffffffc0201cb0:	4501                	li	a0,0
ffffffffc0201cb2:	8082                	ret

ffffffffc0201cb4 <_fifo_tick_event>:

static int
_fifo_tick_event(struct mm_struct *mm)
{ return 0; }
ffffffffc0201cb4:	4501                	li	a0,0
ffffffffc0201cb6:	8082                	ret

ffffffffc0201cb8 <_fifo_check_swap>:
_fifo_check_swap(void) {
ffffffffc0201cb8:	711d                	addi	sp,sp,-96
ffffffffc0201cba:	fc4e                	sd	s3,56(sp)
ffffffffc0201cbc:	f852                	sd	s4,48(sp)
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0201cbe:	00003517          	auipc	a0,0x3
ffffffffc0201cc2:	72250513          	addi	a0,a0,1826 # ffffffffc02053e0 <commands+0xea8>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0201cc6:	698d                	lui	s3,0x3
ffffffffc0201cc8:	4a31                	li	s4,12
_fifo_check_swap(void) {
ffffffffc0201cca:	e8a2                	sd	s0,80(sp)
ffffffffc0201ccc:	e4a6                	sd	s1,72(sp)
ffffffffc0201cce:	ec86                	sd	ra,88(sp)
ffffffffc0201cd0:	e0ca                	sd	s2,64(sp)
ffffffffc0201cd2:	f456                	sd	s5,40(sp)
ffffffffc0201cd4:	f05a                	sd	s6,32(sp)
ffffffffc0201cd6:	ec5e                	sd	s7,24(sp)
ffffffffc0201cd8:	e862                	sd	s8,16(sp)
ffffffffc0201cda:	e466                	sd	s9,8(sp)
    assert(pgfault_num==4);
ffffffffc0201cdc:	0000f417          	auipc	s0,0xf
ffffffffc0201ce0:	78440413          	addi	s0,s0,1924 # ffffffffc0211460 <pgfault_num>
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0201ce4:	bdafe0ef          	jal	ra,ffffffffc02000be <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0201ce8:	01498023          	sb	s4,0(s3) # 3000 <BASE_ADDRESS-0xffffffffc01fd000>
    assert(pgfault_num==4);
ffffffffc0201cec:	4004                	lw	s1,0(s0)
ffffffffc0201cee:	4791                	li	a5,4
ffffffffc0201cf0:	2481                	sext.w	s1,s1
ffffffffc0201cf2:	14f49963          	bne	s1,a5,ffffffffc0201e44 <_fifo_check_swap+0x18c>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0201cf6:	00003517          	auipc	a0,0x3
ffffffffc0201cfa:	73a50513          	addi	a0,a0,1850 # ffffffffc0205430 <commands+0xef8>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0201cfe:	6a85                	lui	s5,0x1
ffffffffc0201d00:	4b29                	li	s6,10
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0201d02:	bbcfe0ef          	jal	ra,ffffffffc02000be <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0201d06:	016a8023          	sb	s6,0(s5) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
    assert(pgfault_num==4);
ffffffffc0201d0a:	00042903          	lw	s2,0(s0)
ffffffffc0201d0e:	2901                	sext.w	s2,s2
ffffffffc0201d10:	2a991a63          	bne	s2,s1,ffffffffc0201fc4 <_fifo_check_swap+0x30c>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0201d14:	00003517          	auipc	a0,0x3
ffffffffc0201d18:	74450513          	addi	a0,a0,1860 # ffffffffc0205458 <commands+0xf20>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0201d1c:	6b91                	lui	s7,0x4
ffffffffc0201d1e:	4c35                	li	s8,13
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0201d20:	b9efe0ef          	jal	ra,ffffffffc02000be <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0201d24:	018b8023          	sb	s8,0(s7) # 4000 <BASE_ADDRESS-0xffffffffc01fc000>
    assert(pgfault_num==4);
ffffffffc0201d28:	4004                	lw	s1,0(s0)
ffffffffc0201d2a:	2481                	sext.w	s1,s1
ffffffffc0201d2c:	27249c63          	bne	s1,s2,ffffffffc0201fa4 <_fifo_check_swap+0x2ec>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0201d30:	00003517          	auipc	a0,0x3
ffffffffc0201d34:	75050513          	addi	a0,a0,1872 # ffffffffc0205480 <commands+0xf48>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0201d38:	6909                	lui	s2,0x2
ffffffffc0201d3a:	4cad                	li	s9,11
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0201d3c:	b82fe0ef          	jal	ra,ffffffffc02000be <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0201d40:	01990023          	sb	s9,0(s2) # 2000 <BASE_ADDRESS-0xffffffffc01fe000>
    assert(pgfault_num==4);
ffffffffc0201d44:	401c                	lw	a5,0(s0)
ffffffffc0201d46:	2781                	sext.w	a5,a5
ffffffffc0201d48:	22979e63          	bne	a5,s1,ffffffffc0201f84 <_fifo_check_swap+0x2cc>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc0201d4c:	00003517          	auipc	a0,0x3
ffffffffc0201d50:	75c50513          	addi	a0,a0,1884 # ffffffffc02054a8 <commands+0xf70>
ffffffffc0201d54:	b6afe0ef          	jal	ra,ffffffffc02000be <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0201d58:	6795                	lui	a5,0x5
ffffffffc0201d5a:	4739                	li	a4,14
ffffffffc0201d5c:	00e78023          	sb	a4,0(a5) # 5000 <BASE_ADDRESS-0xffffffffc01fb000>
    assert(pgfault_num==5);
ffffffffc0201d60:	4004                	lw	s1,0(s0)
ffffffffc0201d62:	4795                	li	a5,5
ffffffffc0201d64:	2481                	sext.w	s1,s1
ffffffffc0201d66:	1ef49f63          	bne	s1,a5,ffffffffc0201f64 <_fifo_check_swap+0x2ac>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0201d6a:	00003517          	auipc	a0,0x3
ffffffffc0201d6e:	71650513          	addi	a0,a0,1814 # ffffffffc0205480 <commands+0xf48>
ffffffffc0201d72:	b4cfe0ef          	jal	ra,ffffffffc02000be <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0201d76:	01990023          	sb	s9,0(s2)
    assert(pgfault_num==5);
ffffffffc0201d7a:	401c                	lw	a5,0(s0)
ffffffffc0201d7c:	2781                	sext.w	a5,a5
ffffffffc0201d7e:	1c979363          	bne	a5,s1,ffffffffc0201f44 <_fifo_check_swap+0x28c>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0201d82:	00003517          	auipc	a0,0x3
ffffffffc0201d86:	6ae50513          	addi	a0,a0,1710 # ffffffffc0205430 <commands+0xef8>
ffffffffc0201d8a:	b34fe0ef          	jal	ra,ffffffffc02000be <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0201d8e:	016a8023          	sb	s6,0(s5)
    assert(pgfault_num==6);
ffffffffc0201d92:	401c                	lw	a5,0(s0)
ffffffffc0201d94:	4719                	li	a4,6
ffffffffc0201d96:	2781                	sext.w	a5,a5
ffffffffc0201d98:	18e79663          	bne	a5,a4,ffffffffc0201f24 <_fifo_check_swap+0x26c>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0201d9c:	00003517          	auipc	a0,0x3
ffffffffc0201da0:	6e450513          	addi	a0,a0,1764 # ffffffffc0205480 <commands+0xf48>
ffffffffc0201da4:	b1afe0ef          	jal	ra,ffffffffc02000be <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0201da8:	01990023          	sb	s9,0(s2)
    assert(pgfault_num==7);
ffffffffc0201dac:	401c                	lw	a5,0(s0)
ffffffffc0201dae:	471d                	li	a4,7
ffffffffc0201db0:	2781                	sext.w	a5,a5
ffffffffc0201db2:	14e79963          	bne	a5,a4,ffffffffc0201f04 <_fifo_check_swap+0x24c>
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0201db6:	00003517          	auipc	a0,0x3
ffffffffc0201dba:	62a50513          	addi	a0,a0,1578 # ffffffffc02053e0 <commands+0xea8>
ffffffffc0201dbe:	b00fe0ef          	jal	ra,ffffffffc02000be <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0201dc2:	01498023          	sb	s4,0(s3)
    assert(pgfault_num==8);
ffffffffc0201dc6:	401c                	lw	a5,0(s0)
ffffffffc0201dc8:	4721                	li	a4,8
ffffffffc0201dca:	2781                	sext.w	a5,a5
ffffffffc0201dcc:	10e79c63          	bne	a5,a4,ffffffffc0201ee4 <_fifo_check_swap+0x22c>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0201dd0:	00003517          	auipc	a0,0x3
ffffffffc0201dd4:	68850513          	addi	a0,a0,1672 # ffffffffc0205458 <commands+0xf20>
ffffffffc0201dd8:	ae6fe0ef          	jal	ra,ffffffffc02000be <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0201ddc:	018b8023          	sb	s8,0(s7)
    assert(pgfault_num==9);
ffffffffc0201de0:	401c                	lw	a5,0(s0)
ffffffffc0201de2:	4725                	li	a4,9
ffffffffc0201de4:	2781                	sext.w	a5,a5
ffffffffc0201de6:	0ce79f63          	bne	a5,a4,ffffffffc0201ec4 <_fifo_check_swap+0x20c>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc0201dea:	00003517          	auipc	a0,0x3
ffffffffc0201dee:	6be50513          	addi	a0,a0,1726 # ffffffffc02054a8 <commands+0xf70>
ffffffffc0201df2:	accfe0ef          	jal	ra,ffffffffc02000be <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0201df6:	6795                	lui	a5,0x5
ffffffffc0201df8:	4739                	li	a4,14
ffffffffc0201dfa:	00e78023          	sb	a4,0(a5) # 5000 <BASE_ADDRESS-0xffffffffc01fb000>
    assert(pgfault_num==10);
ffffffffc0201dfe:	4004                	lw	s1,0(s0)
ffffffffc0201e00:	47a9                	li	a5,10
ffffffffc0201e02:	2481                	sext.w	s1,s1
ffffffffc0201e04:	0af49063          	bne	s1,a5,ffffffffc0201ea4 <_fifo_check_swap+0x1ec>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0201e08:	00003517          	auipc	a0,0x3
ffffffffc0201e0c:	62850513          	addi	a0,a0,1576 # ffffffffc0205430 <commands+0xef8>
ffffffffc0201e10:	aaefe0ef          	jal	ra,ffffffffc02000be <cprintf>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0201e14:	6785                	lui	a5,0x1
ffffffffc0201e16:	0007c783          	lbu	a5,0(a5) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
ffffffffc0201e1a:	06979563          	bne	a5,s1,ffffffffc0201e84 <_fifo_check_swap+0x1cc>
    assert(pgfault_num==11);
ffffffffc0201e1e:	401c                	lw	a5,0(s0)
ffffffffc0201e20:	472d                	li	a4,11
ffffffffc0201e22:	2781                	sext.w	a5,a5
ffffffffc0201e24:	04e79063          	bne	a5,a4,ffffffffc0201e64 <_fifo_check_swap+0x1ac>
}
ffffffffc0201e28:	60e6                	ld	ra,88(sp)
ffffffffc0201e2a:	6446                	ld	s0,80(sp)
ffffffffc0201e2c:	64a6                	ld	s1,72(sp)
ffffffffc0201e2e:	6906                	ld	s2,64(sp)
ffffffffc0201e30:	79e2                	ld	s3,56(sp)
ffffffffc0201e32:	7a42                	ld	s4,48(sp)
ffffffffc0201e34:	7aa2                	ld	s5,40(sp)
ffffffffc0201e36:	7b02                	ld	s6,32(sp)
ffffffffc0201e38:	6be2                	ld	s7,24(sp)
ffffffffc0201e3a:	6c42                	ld	s8,16(sp)
ffffffffc0201e3c:	6ca2                	ld	s9,8(sp)
ffffffffc0201e3e:	4501                	li	a0,0
ffffffffc0201e40:	6125                	addi	sp,sp,96
ffffffffc0201e42:	8082                	ret
    assert(pgfault_num==4);
ffffffffc0201e44:	00003697          	auipc	a3,0x3
ffffffffc0201e48:	5c468693          	addi	a3,a3,1476 # ffffffffc0205408 <commands+0xed0>
ffffffffc0201e4c:	00003617          	auipc	a2,0x3
ffffffffc0201e50:	0dc60613          	addi	a2,a2,220 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201e54:	05500593          	li	a1,85
ffffffffc0201e58:	00003517          	auipc	a0,0x3
ffffffffc0201e5c:	5c050513          	addi	a0,a0,1472 # ffffffffc0205418 <commands+0xee0>
ffffffffc0201e60:	aa6fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(pgfault_num==11);
ffffffffc0201e64:	00003697          	auipc	a3,0x3
ffffffffc0201e68:	6f468693          	addi	a3,a3,1780 # ffffffffc0205558 <commands+0x1020>
ffffffffc0201e6c:	00003617          	auipc	a2,0x3
ffffffffc0201e70:	0bc60613          	addi	a2,a2,188 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201e74:	07700593          	li	a1,119
ffffffffc0201e78:	00003517          	auipc	a0,0x3
ffffffffc0201e7c:	5a050513          	addi	a0,a0,1440 # ffffffffc0205418 <commands+0xee0>
ffffffffc0201e80:	a86fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0201e84:	00003697          	auipc	a3,0x3
ffffffffc0201e88:	6ac68693          	addi	a3,a3,1708 # ffffffffc0205530 <commands+0xff8>
ffffffffc0201e8c:	00003617          	auipc	a2,0x3
ffffffffc0201e90:	09c60613          	addi	a2,a2,156 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201e94:	07500593          	li	a1,117
ffffffffc0201e98:	00003517          	auipc	a0,0x3
ffffffffc0201e9c:	58050513          	addi	a0,a0,1408 # ffffffffc0205418 <commands+0xee0>
ffffffffc0201ea0:	a66fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(pgfault_num==10);
ffffffffc0201ea4:	00003697          	auipc	a3,0x3
ffffffffc0201ea8:	67c68693          	addi	a3,a3,1660 # ffffffffc0205520 <commands+0xfe8>
ffffffffc0201eac:	00003617          	auipc	a2,0x3
ffffffffc0201eb0:	07c60613          	addi	a2,a2,124 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201eb4:	07300593          	li	a1,115
ffffffffc0201eb8:	00003517          	auipc	a0,0x3
ffffffffc0201ebc:	56050513          	addi	a0,a0,1376 # ffffffffc0205418 <commands+0xee0>
ffffffffc0201ec0:	a46fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(pgfault_num==9);
ffffffffc0201ec4:	00003697          	auipc	a3,0x3
ffffffffc0201ec8:	64c68693          	addi	a3,a3,1612 # ffffffffc0205510 <commands+0xfd8>
ffffffffc0201ecc:	00003617          	auipc	a2,0x3
ffffffffc0201ed0:	05c60613          	addi	a2,a2,92 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201ed4:	07000593          	li	a1,112
ffffffffc0201ed8:	00003517          	auipc	a0,0x3
ffffffffc0201edc:	54050513          	addi	a0,a0,1344 # ffffffffc0205418 <commands+0xee0>
ffffffffc0201ee0:	a26fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(pgfault_num==8);
ffffffffc0201ee4:	00003697          	auipc	a3,0x3
ffffffffc0201ee8:	61c68693          	addi	a3,a3,1564 # ffffffffc0205500 <commands+0xfc8>
ffffffffc0201eec:	00003617          	auipc	a2,0x3
ffffffffc0201ef0:	03c60613          	addi	a2,a2,60 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201ef4:	06d00593          	li	a1,109
ffffffffc0201ef8:	00003517          	auipc	a0,0x3
ffffffffc0201efc:	52050513          	addi	a0,a0,1312 # ffffffffc0205418 <commands+0xee0>
ffffffffc0201f00:	a06fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(pgfault_num==7);
ffffffffc0201f04:	00003697          	auipc	a3,0x3
ffffffffc0201f08:	5ec68693          	addi	a3,a3,1516 # ffffffffc02054f0 <commands+0xfb8>
ffffffffc0201f0c:	00003617          	auipc	a2,0x3
ffffffffc0201f10:	01c60613          	addi	a2,a2,28 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201f14:	06a00593          	li	a1,106
ffffffffc0201f18:	00003517          	auipc	a0,0x3
ffffffffc0201f1c:	50050513          	addi	a0,a0,1280 # ffffffffc0205418 <commands+0xee0>
ffffffffc0201f20:	9e6fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(pgfault_num==6);
ffffffffc0201f24:	00003697          	auipc	a3,0x3
ffffffffc0201f28:	5bc68693          	addi	a3,a3,1468 # ffffffffc02054e0 <commands+0xfa8>
ffffffffc0201f2c:	00003617          	auipc	a2,0x3
ffffffffc0201f30:	ffc60613          	addi	a2,a2,-4 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201f34:	06700593          	li	a1,103
ffffffffc0201f38:	00003517          	auipc	a0,0x3
ffffffffc0201f3c:	4e050513          	addi	a0,a0,1248 # ffffffffc0205418 <commands+0xee0>
ffffffffc0201f40:	9c6fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(pgfault_num==5);
ffffffffc0201f44:	00003697          	auipc	a3,0x3
ffffffffc0201f48:	58c68693          	addi	a3,a3,1420 # ffffffffc02054d0 <commands+0xf98>
ffffffffc0201f4c:	00003617          	auipc	a2,0x3
ffffffffc0201f50:	fdc60613          	addi	a2,a2,-36 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201f54:	06400593          	li	a1,100
ffffffffc0201f58:	00003517          	auipc	a0,0x3
ffffffffc0201f5c:	4c050513          	addi	a0,a0,1216 # ffffffffc0205418 <commands+0xee0>
ffffffffc0201f60:	9a6fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(pgfault_num==5);
ffffffffc0201f64:	00003697          	auipc	a3,0x3
ffffffffc0201f68:	56c68693          	addi	a3,a3,1388 # ffffffffc02054d0 <commands+0xf98>
ffffffffc0201f6c:	00003617          	auipc	a2,0x3
ffffffffc0201f70:	fbc60613          	addi	a2,a2,-68 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201f74:	06100593          	li	a1,97
ffffffffc0201f78:	00003517          	auipc	a0,0x3
ffffffffc0201f7c:	4a050513          	addi	a0,a0,1184 # ffffffffc0205418 <commands+0xee0>
ffffffffc0201f80:	986fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(pgfault_num==4);
ffffffffc0201f84:	00003697          	auipc	a3,0x3
ffffffffc0201f88:	48468693          	addi	a3,a3,1156 # ffffffffc0205408 <commands+0xed0>
ffffffffc0201f8c:	00003617          	auipc	a2,0x3
ffffffffc0201f90:	f9c60613          	addi	a2,a2,-100 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201f94:	05e00593          	li	a1,94
ffffffffc0201f98:	00003517          	auipc	a0,0x3
ffffffffc0201f9c:	48050513          	addi	a0,a0,1152 # ffffffffc0205418 <commands+0xee0>
ffffffffc0201fa0:	966fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(pgfault_num==4);
ffffffffc0201fa4:	00003697          	auipc	a3,0x3
ffffffffc0201fa8:	46468693          	addi	a3,a3,1124 # ffffffffc0205408 <commands+0xed0>
ffffffffc0201fac:	00003617          	auipc	a2,0x3
ffffffffc0201fb0:	f7c60613          	addi	a2,a2,-132 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201fb4:	05b00593          	li	a1,91
ffffffffc0201fb8:	00003517          	auipc	a0,0x3
ffffffffc0201fbc:	46050513          	addi	a0,a0,1120 # ffffffffc0205418 <commands+0xee0>
ffffffffc0201fc0:	946fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(pgfault_num==4);
ffffffffc0201fc4:	00003697          	auipc	a3,0x3
ffffffffc0201fc8:	44468693          	addi	a3,a3,1092 # ffffffffc0205408 <commands+0xed0>
ffffffffc0201fcc:	00003617          	auipc	a2,0x3
ffffffffc0201fd0:	f5c60613          	addi	a2,a2,-164 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0201fd4:	05800593          	li	a1,88
ffffffffc0201fd8:	00003517          	auipc	a0,0x3
ffffffffc0201fdc:	44050513          	addi	a0,a0,1088 # ffffffffc0205418 <commands+0xee0>
ffffffffc0201fe0:	926fe0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc0201fe4 <_fifo_swap_out_victim>:
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc0201fe4:	7518                	ld	a4,40(a0)
{
ffffffffc0201fe6:	1141                	addi	sp,sp,-16
ffffffffc0201fe8:	e406                	sd	ra,8(sp)
         assert(head != NULL);
ffffffffc0201fea:	c731                	beqz	a4,ffffffffc0202036 <_fifo_swap_out_victim+0x52>
     assert(in_tick==0);
ffffffffc0201fec:	e60d                	bnez	a2,ffffffffc0202016 <_fifo_swap_out_victim+0x32>
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0201fee:	631c                	ld	a5,0(a4)
    if (entry != head) {
ffffffffc0201ff0:	00f70d63          	beq	a4,a5,ffffffffc020200a <_fifo_swap_out_victim+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0201ff4:	6394                	ld	a3,0(a5)
ffffffffc0201ff6:	6798                	ld	a4,8(a5)
}
ffffffffc0201ff8:	60a2                	ld	ra,8(sp)
        *ptr_page = le2page(entry, pra_page_link);
ffffffffc0201ffa:	fd078793          	addi	a5,a5,-48
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201ffe:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0202000:	e314                	sd	a3,0(a4)
ffffffffc0202002:	e19c                	sd	a5,0(a1)
}
ffffffffc0202004:	4501                	li	a0,0
ffffffffc0202006:	0141                	addi	sp,sp,16
ffffffffc0202008:	8082                	ret
ffffffffc020200a:	60a2                	ld	ra,8(sp)
        *ptr_page = NULL;
ffffffffc020200c:	0005b023          	sd	zero,0(a1)
}
ffffffffc0202010:	4501                	li	a0,0
ffffffffc0202012:	0141                	addi	sp,sp,16
ffffffffc0202014:	8082                	ret
     assert(in_tick==0);
ffffffffc0202016:	00003697          	auipc	a3,0x3
ffffffffc020201a:	58268693          	addi	a3,a3,1410 # ffffffffc0205598 <commands+0x1060>
ffffffffc020201e:	00003617          	auipc	a2,0x3
ffffffffc0202022:	f0a60613          	addi	a2,a2,-246 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202026:	04300593          	li	a1,67
ffffffffc020202a:	00003517          	auipc	a0,0x3
ffffffffc020202e:	3ee50513          	addi	a0,a0,1006 # ffffffffc0205418 <commands+0xee0>
ffffffffc0202032:	8d4fe0ef          	jal	ra,ffffffffc0200106 <__panic>
         assert(head != NULL);
ffffffffc0202036:	00003697          	auipc	a3,0x3
ffffffffc020203a:	55268693          	addi	a3,a3,1362 # ffffffffc0205588 <commands+0x1050>
ffffffffc020203e:	00003617          	auipc	a2,0x3
ffffffffc0202042:	eea60613          	addi	a2,a2,-278 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202046:	04200593          	li	a1,66
ffffffffc020204a:	00003517          	auipc	a0,0x3
ffffffffc020204e:	3ce50513          	addi	a0,a0,974 # ffffffffc0205418 <commands+0xee0>
ffffffffc0202052:	8b4fe0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc0202056 <_fifo_map_swappable>:
    list_entry_t *entry=&(page->pra_page_link);
ffffffffc0202056:	03060713          	addi	a4,a2,48
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc020205a:	751c                	ld	a5,40(a0)
    assert(entry != NULL && head != NULL);
ffffffffc020205c:	cb09                	beqz	a4,ffffffffc020206e <_fifo_map_swappable+0x18>
ffffffffc020205e:	cb81                	beqz	a5,ffffffffc020206e <_fifo_map_swappable+0x18>
    __list_add(elm, listelm, listelm->next);
ffffffffc0202060:	6794                	ld	a3,8(a5)
}
ffffffffc0202062:	4501                	li	a0,0
    prev->next = next->prev = elm;
ffffffffc0202064:	e298                	sd	a4,0(a3)
ffffffffc0202066:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0202068:	fe14                	sd	a3,56(a2)
    elm->prev = prev;
ffffffffc020206a:	fa1c                	sd	a5,48(a2)
ffffffffc020206c:	8082                	ret
{
ffffffffc020206e:	1141                	addi	sp,sp,-16
    assert(entry != NULL && head != NULL);
ffffffffc0202070:	00003697          	auipc	a3,0x3
ffffffffc0202074:	4f868693          	addi	a3,a3,1272 # ffffffffc0205568 <commands+0x1030>
ffffffffc0202078:	00003617          	auipc	a2,0x3
ffffffffc020207c:	eb060613          	addi	a2,a2,-336 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202080:	03200593          	li	a1,50
ffffffffc0202084:	00003517          	auipc	a0,0x3
ffffffffc0202088:	39450513          	addi	a0,a0,916 # ffffffffc0205418 <commands+0xee0>
{
ffffffffc020208c:	e406                	sd	ra,8(sp)
    assert(entry != NULL && head != NULL);
ffffffffc020208e:	878fe0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc0202092 <check_vma_overlap.isra.0.part.1>:
}


// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc0202092:	1141                	addi	sp,sp,-16
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0202094:	00003697          	auipc	a3,0x3
ffffffffc0202098:	52c68693          	addi	a3,a3,1324 # ffffffffc02055c0 <commands+0x1088>
ffffffffc020209c:	00003617          	auipc	a2,0x3
ffffffffc02020a0:	e8c60613          	addi	a2,a2,-372 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02020a4:	07d00593          	li	a1,125
ffffffffc02020a8:	00003517          	auipc	a0,0x3
ffffffffc02020ac:	53850513          	addi	a0,a0,1336 # ffffffffc02055e0 <commands+0x10a8>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc02020b0:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc02020b2:	854fe0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc02020b6 <mm_create>:
mm_create(void) {
ffffffffc02020b6:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02020b8:	03000513          	li	a0,48
mm_create(void) {
ffffffffc02020bc:	e022                	sd	s0,0(sp)
ffffffffc02020be:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02020c0:	a59ff0ef          	jal	ra,ffffffffc0201b18 <kmalloc>
ffffffffc02020c4:	842a                	mv	s0,a0
    if (mm != NULL) {
ffffffffc02020c6:	c115                	beqz	a0,ffffffffc02020ea <mm_create+0x34>
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc02020c8:	0000f797          	auipc	a5,0xf
ffffffffc02020cc:	3a878793          	addi	a5,a5,936 # ffffffffc0211470 <swap_init_ok>
ffffffffc02020d0:	439c                	lw	a5,0(a5)
    elm->prev = elm->next = elm;
ffffffffc02020d2:	e408                	sd	a0,8(s0)
ffffffffc02020d4:	e008                	sd	a0,0(s0)
        mm->mmap_cache = NULL;
ffffffffc02020d6:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02020da:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02020de:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc02020e2:	2781                	sext.w	a5,a5
ffffffffc02020e4:	eb81                	bnez	a5,ffffffffc02020f4 <mm_create+0x3e>
        else mm->sm_priv = NULL;
ffffffffc02020e6:	02053423          	sd	zero,40(a0)
}
ffffffffc02020ea:	8522                	mv	a0,s0
ffffffffc02020ec:	60a2                	ld	ra,8(sp)
ffffffffc02020ee:	6402                	ld	s0,0(sp)
ffffffffc02020f0:	0141                	addi	sp,sp,16
ffffffffc02020f2:	8082                	ret
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc02020f4:	6db000ef          	jal	ra,ffffffffc0202fce <swap_init_mm>
}
ffffffffc02020f8:	8522                	mv	a0,s0
ffffffffc02020fa:	60a2                	ld	ra,8(sp)
ffffffffc02020fc:	6402                	ld	s0,0(sp)
ffffffffc02020fe:	0141                	addi	sp,sp,16
ffffffffc0202100:	8082                	ret

ffffffffc0202102 <vma_create>:
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint_t vm_flags) {
ffffffffc0202102:	1101                	addi	sp,sp,-32
ffffffffc0202104:	e04a                	sd	s2,0(sp)
ffffffffc0202106:	892a                	mv	s2,a0
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202108:	03000513          	li	a0,48
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint_t vm_flags) {
ffffffffc020210c:	e822                	sd	s0,16(sp)
ffffffffc020210e:	e426                	sd	s1,8(sp)
ffffffffc0202110:	ec06                	sd	ra,24(sp)
ffffffffc0202112:	84ae                	mv	s1,a1
ffffffffc0202114:	8432                	mv	s0,a2
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202116:	a03ff0ef          	jal	ra,ffffffffc0201b18 <kmalloc>
    if (vma != NULL) {
ffffffffc020211a:	c509                	beqz	a0,ffffffffc0202124 <vma_create+0x22>
        vma->vm_start = vm_start;
ffffffffc020211c:	01253423          	sd	s2,8(a0)
        vma->vm_end = vm_end;
ffffffffc0202120:	e904                	sd	s1,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202122:	ed00                	sd	s0,24(a0)
}
ffffffffc0202124:	60e2                	ld	ra,24(sp)
ffffffffc0202126:	6442                	ld	s0,16(sp)
ffffffffc0202128:	64a2                	ld	s1,8(sp)
ffffffffc020212a:	6902                	ld	s2,0(sp)
ffffffffc020212c:	6105                	addi	sp,sp,32
ffffffffc020212e:	8082                	ret

ffffffffc0202130 <find_vma>:
    if (mm != NULL) {
ffffffffc0202130:	c51d                	beqz	a0,ffffffffc020215e <find_vma+0x2e>
        vma = mm->mmap_cache;
ffffffffc0202132:	691c                	ld	a5,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc0202134:	c781                	beqz	a5,ffffffffc020213c <find_vma+0xc>
ffffffffc0202136:	6798                	ld	a4,8(a5)
ffffffffc0202138:	02e5f663          	bleu	a4,a1,ffffffffc0202164 <find_vma+0x34>
                list_entry_t *list = &(mm->mmap_list), *le = list;
ffffffffc020213c:	87aa                	mv	a5,a0
    return listelm->next;
ffffffffc020213e:	679c                	ld	a5,8(a5)
                while ((le = list_next(le)) != list) {
ffffffffc0202140:	00f50f63          	beq	a0,a5,ffffffffc020215e <find_vma+0x2e>
                    if (vma->vm_start<=addr && addr < vma->vm_end) {
ffffffffc0202144:	fe87b703          	ld	a4,-24(a5)
ffffffffc0202148:	fee5ebe3          	bltu	a1,a4,ffffffffc020213e <find_vma+0xe>
ffffffffc020214c:	ff07b703          	ld	a4,-16(a5)
ffffffffc0202150:	fee5f7e3          	bleu	a4,a1,ffffffffc020213e <find_vma+0xe>
                    vma = le2vma(le, list_link);
ffffffffc0202154:	1781                	addi	a5,a5,-32
        if (vma != NULL) {
ffffffffc0202156:	c781                	beqz	a5,ffffffffc020215e <find_vma+0x2e>
            mm->mmap_cache = vma;
ffffffffc0202158:	e91c                	sd	a5,16(a0)
}
ffffffffc020215a:	853e                	mv	a0,a5
ffffffffc020215c:	8082                	ret
    struct vma_struct *vma = NULL;
ffffffffc020215e:	4781                	li	a5,0
}
ffffffffc0202160:	853e                	mv	a0,a5
ffffffffc0202162:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc0202164:	6b98                	ld	a4,16(a5)
ffffffffc0202166:	fce5fbe3          	bleu	a4,a1,ffffffffc020213c <find_vma+0xc>
            mm->mmap_cache = vma;
ffffffffc020216a:	e91c                	sd	a5,16(a0)
    return vma;
ffffffffc020216c:	b7fd                	j	ffffffffc020215a <find_vma+0x2a>

ffffffffc020216e <insert_vma_struct>:


// insert_vma_struct -insert vma in mm's list link
void
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
    assert(vma->vm_start < vma->vm_end);
ffffffffc020216e:	6590                	ld	a2,8(a1)
ffffffffc0202170:	0105b803          	ld	a6,16(a1)
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
ffffffffc0202174:	1141                	addi	sp,sp,-16
ffffffffc0202176:	e406                	sd	ra,8(sp)
ffffffffc0202178:	872a                	mv	a4,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc020217a:	01066863          	bltu	a2,a6,ffffffffc020218a <insert_vma_struct+0x1c>
ffffffffc020217e:	a8b9                	j	ffffffffc02021dc <insert_vma_struct+0x6e>
    list_entry_t *le_prev = list, *le_next;

        list_entry_t *le = list;
        while ((le = list_next(le)) != list) {
            struct vma_struct *mmap_prev = le2vma(le, list_link);
            if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc0202180:	fe87b683          	ld	a3,-24(a5)
ffffffffc0202184:	04d66763          	bltu	a2,a3,ffffffffc02021d2 <insert_vma_struct+0x64>
ffffffffc0202188:	873e                	mv	a4,a5
ffffffffc020218a:	671c                	ld	a5,8(a4)
        while ((le = list_next(le)) != list) {
ffffffffc020218c:	fef51ae3          	bne	a0,a5,ffffffffc0202180 <insert_vma_struct+0x12>
        }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list) {
ffffffffc0202190:	02a70463          	beq	a4,a0,ffffffffc02021b8 <insert_vma_struct+0x4a>
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0202194:	ff073683          	ld	a3,-16(a4)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0202198:	fe873883          	ld	a7,-24(a4)
ffffffffc020219c:	08d8f063          	bleu	a3,a7,ffffffffc020221c <insert_vma_struct+0xae>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02021a0:	04d66e63          	bltu	a2,a3,ffffffffc02021fc <insert_vma_struct+0x8e>
    }
    if (le_next != list) {
ffffffffc02021a4:	00f50a63          	beq	a0,a5,ffffffffc02021b8 <insert_vma_struct+0x4a>
ffffffffc02021a8:	fe87b683          	ld	a3,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc02021ac:	0506e863          	bltu	a3,a6,ffffffffc02021fc <insert_vma_struct+0x8e>
    assert(next->vm_start < next->vm_end);
ffffffffc02021b0:	ff07b603          	ld	a2,-16(a5)
ffffffffc02021b4:	02c6f263          	bleu	a2,a3,ffffffffc02021d8 <insert_vma_struct+0x6a>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count ++;
ffffffffc02021b8:	5114                	lw	a3,32(a0)
    vma->vm_mm = mm;
ffffffffc02021ba:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc02021bc:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc02021c0:	e390                	sd	a2,0(a5)
ffffffffc02021c2:	e710                	sd	a2,8(a4)
}
ffffffffc02021c4:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc02021c6:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc02021c8:	f198                	sd	a4,32(a1)
    mm->map_count ++;
ffffffffc02021ca:	2685                	addiw	a3,a3,1
ffffffffc02021cc:	d114                	sw	a3,32(a0)
}
ffffffffc02021ce:	0141                	addi	sp,sp,16
ffffffffc02021d0:	8082                	ret
    if (le_prev != list) {
ffffffffc02021d2:	fca711e3          	bne	a4,a0,ffffffffc0202194 <insert_vma_struct+0x26>
ffffffffc02021d6:	bfd9                	j	ffffffffc02021ac <insert_vma_struct+0x3e>
ffffffffc02021d8:	ebbff0ef          	jal	ra,ffffffffc0202092 <check_vma_overlap.isra.0.part.1>
    assert(vma->vm_start < vma->vm_end);
ffffffffc02021dc:	00003697          	auipc	a3,0x3
ffffffffc02021e0:	4e468693          	addi	a3,a3,1252 # ffffffffc02056c0 <commands+0x1188>
ffffffffc02021e4:	00003617          	auipc	a2,0x3
ffffffffc02021e8:	d4460613          	addi	a2,a2,-700 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02021ec:	08400593          	li	a1,132
ffffffffc02021f0:	00003517          	auipc	a0,0x3
ffffffffc02021f4:	3f050513          	addi	a0,a0,1008 # ffffffffc02055e0 <commands+0x10a8>
ffffffffc02021f8:	f0ffd0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02021fc:	00003697          	auipc	a3,0x3
ffffffffc0202200:	50468693          	addi	a3,a3,1284 # ffffffffc0205700 <commands+0x11c8>
ffffffffc0202204:	00003617          	auipc	a2,0x3
ffffffffc0202208:	d2460613          	addi	a2,a2,-732 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc020220c:	07c00593          	li	a1,124
ffffffffc0202210:	00003517          	auipc	a0,0x3
ffffffffc0202214:	3d050513          	addi	a0,a0,976 # ffffffffc02055e0 <commands+0x10a8>
ffffffffc0202218:	eeffd0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc020221c:	00003697          	auipc	a3,0x3
ffffffffc0202220:	4c468693          	addi	a3,a3,1220 # ffffffffc02056e0 <commands+0x11a8>
ffffffffc0202224:	00003617          	auipc	a2,0x3
ffffffffc0202228:	d0460613          	addi	a2,a2,-764 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc020222c:	07b00593          	li	a1,123
ffffffffc0202230:	00003517          	auipc	a0,0x3
ffffffffc0202234:	3b050513          	addi	a0,a0,944 # ffffffffc02055e0 <commands+0x10a8>
ffffffffc0202238:	ecffd0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc020223c <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void
mm_destroy(struct mm_struct *mm) {
ffffffffc020223c:	1141                	addi	sp,sp,-16
ffffffffc020223e:	e022                	sd	s0,0(sp)
ffffffffc0202240:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0202242:	6508                	ld	a0,8(a0)
ffffffffc0202244:	e406                	sd	ra,8(sp)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list) {
ffffffffc0202246:	00a40e63          	beq	s0,a0,ffffffffc0202262 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc020224a:	6118                	ld	a4,0(a0)
ffffffffc020224c:	651c                	ld	a5,8(a0)
        list_del(le);
        kfree(le2vma(le, list_link),sizeof(struct vma_struct));  //kfree vma        
ffffffffc020224e:	03000593          	li	a1,48
ffffffffc0202252:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0202254:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0202256:	e398                	sd	a4,0(a5)
ffffffffc0202258:	983ff0ef          	jal	ra,ffffffffc0201bda <kfree>
    return listelm->next;
ffffffffc020225c:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc020225e:	fea416e3          	bne	s0,a0,ffffffffc020224a <mm_destroy+0xe>
    }
    kfree(mm, sizeof(struct mm_struct)); //kfree mm
ffffffffc0202262:	8522                	mv	a0,s0
    mm=NULL;
}
ffffffffc0202264:	6402                	ld	s0,0(sp)
ffffffffc0202266:	60a2                	ld	ra,8(sp)
    kfree(mm, sizeof(struct mm_struct)); //kfree mm
ffffffffc0202268:	03000593          	li	a1,48
}
ffffffffc020226c:	0141                	addi	sp,sp,16
    kfree(mm, sizeof(struct mm_struct)); //kfree mm
ffffffffc020226e:	96dff06f          	j	ffffffffc0201bda <kfree>

ffffffffc0202272 <vmm_init>:

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void
vmm_init(void) {
ffffffffc0202272:	715d                	addi	sp,sp,-80
ffffffffc0202274:	e486                	sd	ra,72(sp)
ffffffffc0202276:	e0a2                	sd	s0,64(sp)
ffffffffc0202278:	fc26                	sd	s1,56(sp)
ffffffffc020227a:	f84a                	sd	s2,48(sp)
ffffffffc020227c:	f052                	sd	s4,32(sp)
ffffffffc020227e:	f44e                	sd	s3,40(sp)
ffffffffc0202280:	ec56                	sd	s5,24(sp)
ffffffffc0202282:	e85a                	sd	s6,16(sp)
ffffffffc0202284:	e45e                	sd	s7,8(sp)
}

// check_vmm - check correctness of vmm
static void
check_vmm(void) {
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0202286:	935fe0ef          	jal	ra,ffffffffc0200bba <nr_free_pages>
ffffffffc020228a:	892a                	mv	s2,a0
    cprintf("check_vmm() succeeded.\n");
}

static void
check_vma_struct(void) {
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc020228c:	92ffe0ef          	jal	ra,ffffffffc0200bba <nr_free_pages>
ffffffffc0202290:	8a2a                	mv	s4,a0

    struct mm_struct *mm = mm_create();
ffffffffc0202292:	e25ff0ef          	jal	ra,ffffffffc02020b6 <mm_create>
    assert(mm != NULL);
ffffffffc0202296:	842a                	mv	s0,a0
ffffffffc0202298:	03200493          	li	s1,50
ffffffffc020229c:	e919                	bnez	a0,ffffffffc02022b2 <vmm_init+0x40>
ffffffffc020229e:	aeed                	j	ffffffffc0202698 <vmm_init+0x426>
        vma->vm_start = vm_start;
ffffffffc02022a0:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc02022a2:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02022a4:	00053c23          	sd	zero,24(a0)

    int i;
    for (i = step1; i >= 1; i --) {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc02022a8:	14ed                	addi	s1,s1,-5
ffffffffc02022aa:	8522                	mv	a0,s0
ffffffffc02022ac:	ec3ff0ef          	jal	ra,ffffffffc020216e <insert_vma_struct>
    for (i = step1; i >= 1; i --) {
ffffffffc02022b0:	c88d                	beqz	s1,ffffffffc02022e2 <vmm_init+0x70>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02022b2:	03000513          	li	a0,48
ffffffffc02022b6:	863ff0ef          	jal	ra,ffffffffc0201b18 <kmalloc>
ffffffffc02022ba:	85aa                	mv	a1,a0
ffffffffc02022bc:	00248793          	addi	a5,s1,2
    if (vma != NULL) {
ffffffffc02022c0:	f165                	bnez	a0,ffffffffc02022a0 <vmm_init+0x2e>
        assert(vma != NULL);
ffffffffc02022c2:	00003697          	auipc	a3,0x3
ffffffffc02022c6:	68668693          	addi	a3,a3,1670 # ffffffffc0205948 <commands+0x1410>
ffffffffc02022ca:	00003617          	auipc	a2,0x3
ffffffffc02022ce:	c5e60613          	addi	a2,a2,-930 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02022d2:	0ce00593          	li	a1,206
ffffffffc02022d6:	00003517          	auipc	a0,0x3
ffffffffc02022da:	30a50513          	addi	a0,a0,778 # ffffffffc02055e0 <commands+0x10a8>
ffffffffc02022de:	e29fd0ef          	jal	ra,ffffffffc0200106 <__panic>
    for (i = step1; i >= 1; i --) {
ffffffffc02022e2:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc02022e6:	1f900993          	li	s3,505
ffffffffc02022ea:	a819                	j	ffffffffc0202300 <vmm_init+0x8e>
        vma->vm_start = vm_start;
ffffffffc02022ec:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc02022ee:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02022f0:	00053c23          	sd	zero,24(a0)
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc02022f4:	0495                	addi	s1,s1,5
ffffffffc02022f6:	8522                	mv	a0,s0
ffffffffc02022f8:	e77ff0ef          	jal	ra,ffffffffc020216e <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc02022fc:	03348a63          	beq	s1,s3,ffffffffc0202330 <vmm_init+0xbe>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202300:	03000513          	li	a0,48
ffffffffc0202304:	815ff0ef          	jal	ra,ffffffffc0201b18 <kmalloc>
ffffffffc0202308:	85aa                	mv	a1,a0
ffffffffc020230a:	00248793          	addi	a5,s1,2
    if (vma != NULL) {
ffffffffc020230e:	fd79                	bnez	a0,ffffffffc02022ec <vmm_init+0x7a>
        assert(vma != NULL);
ffffffffc0202310:	00003697          	auipc	a3,0x3
ffffffffc0202314:	63868693          	addi	a3,a3,1592 # ffffffffc0205948 <commands+0x1410>
ffffffffc0202318:	00003617          	auipc	a2,0x3
ffffffffc020231c:	c1060613          	addi	a2,a2,-1008 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202320:	0d400593          	li	a1,212
ffffffffc0202324:	00003517          	auipc	a0,0x3
ffffffffc0202328:	2bc50513          	addi	a0,a0,700 # ffffffffc02055e0 <commands+0x10a8>
ffffffffc020232c:	ddbfd0ef          	jal	ra,ffffffffc0200106 <__panic>
ffffffffc0202330:	6418                	ld	a4,8(s0)
ffffffffc0202332:	479d                	li	a5,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i ++) {
ffffffffc0202334:	1fb00593          	li	a1,507
        assert(le != &(mm->mmap_list));
ffffffffc0202338:	2ae40063          	beq	s0,a4,ffffffffc02025d8 <vmm_init+0x366>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc020233c:	fe873603          	ld	a2,-24(a4)
ffffffffc0202340:	ffe78693          	addi	a3,a5,-2
ffffffffc0202344:	20d61a63          	bne	a2,a3,ffffffffc0202558 <vmm_init+0x2e6>
ffffffffc0202348:	ff073683          	ld	a3,-16(a4)
ffffffffc020234c:	20d79663          	bne	a5,a3,ffffffffc0202558 <vmm_init+0x2e6>
ffffffffc0202350:	0795                	addi	a5,a5,5
ffffffffc0202352:	6718                	ld	a4,8(a4)
    for (i = 1; i <= step2; i ++) {
ffffffffc0202354:	feb792e3          	bne	a5,a1,ffffffffc0202338 <vmm_init+0xc6>
ffffffffc0202358:	499d                	li	s3,7
ffffffffc020235a:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc020235c:	1f900b93          	li	s7,505
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0202360:	85a6                	mv	a1,s1
ffffffffc0202362:	8522                	mv	a0,s0
ffffffffc0202364:	dcdff0ef          	jal	ra,ffffffffc0202130 <find_vma>
ffffffffc0202368:	8b2a                	mv	s6,a0
        assert(vma1 != NULL);
ffffffffc020236a:	2e050763          	beqz	a0,ffffffffc0202658 <vmm_init+0x3e6>
        struct vma_struct *vma2 = find_vma(mm, i+1);
ffffffffc020236e:	00148593          	addi	a1,s1,1
ffffffffc0202372:	8522                	mv	a0,s0
ffffffffc0202374:	dbdff0ef          	jal	ra,ffffffffc0202130 <find_vma>
ffffffffc0202378:	8aaa                	mv	s5,a0
        assert(vma2 != NULL);
ffffffffc020237a:	2a050f63          	beqz	a0,ffffffffc0202638 <vmm_init+0x3c6>
        struct vma_struct *vma3 = find_vma(mm, i+2);
ffffffffc020237e:	85ce                	mv	a1,s3
ffffffffc0202380:	8522                	mv	a0,s0
ffffffffc0202382:	dafff0ef          	jal	ra,ffffffffc0202130 <find_vma>
        assert(vma3 == NULL);
ffffffffc0202386:	28051963          	bnez	a0,ffffffffc0202618 <vmm_init+0x3a6>
        struct vma_struct *vma4 = find_vma(mm, i+3);
ffffffffc020238a:	00348593          	addi	a1,s1,3
ffffffffc020238e:	8522                	mv	a0,s0
ffffffffc0202390:	da1ff0ef          	jal	ra,ffffffffc0202130 <find_vma>
        assert(vma4 == NULL);
ffffffffc0202394:	26051263          	bnez	a0,ffffffffc02025f8 <vmm_init+0x386>
        struct vma_struct *vma5 = find_vma(mm, i+4);
ffffffffc0202398:	00448593          	addi	a1,s1,4
ffffffffc020239c:	8522                	mv	a0,s0
ffffffffc020239e:	d93ff0ef          	jal	ra,ffffffffc0202130 <find_vma>
        assert(vma5 == NULL);
ffffffffc02023a2:	2c051b63          	bnez	a0,ffffffffc0202678 <vmm_init+0x406>

        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc02023a6:	008b3783          	ld	a5,8(s6)
ffffffffc02023aa:	1c979763          	bne	a5,s1,ffffffffc0202578 <vmm_init+0x306>
ffffffffc02023ae:	010b3783          	ld	a5,16(s6)
ffffffffc02023b2:	1d379363          	bne	a5,s3,ffffffffc0202578 <vmm_init+0x306>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc02023b6:	008ab783          	ld	a5,8(s5)
ffffffffc02023ba:	1c979f63          	bne	a5,s1,ffffffffc0202598 <vmm_init+0x326>
ffffffffc02023be:	010ab783          	ld	a5,16(s5)
ffffffffc02023c2:	1d379b63          	bne	a5,s3,ffffffffc0202598 <vmm_init+0x326>
ffffffffc02023c6:	0495                	addi	s1,s1,5
ffffffffc02023c8:	0995                	addi	s3,s3,5
    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc02023ca:	f9749be3          	bne	s1,s7,ffffffffc0202360 <vmm_init+0xee>
ffffffffc02023ce:	4491                	li	s1,4
    }

    for (i =4; i>=0; i--) {
ffffffffc02023d0:	59fd                	li	s3,-1
        struct vma_struct *vma_below_5= find_vma(mm,i);
ffffffffc02023d2:	85a6                	mv	a1,s1
ffffffffc02023d4:	8522                	mv	a0,s0
ffffffffc02023d6:	d5bff0ef          	jal	ra,ffffffffc0202130 <find_vma>
ffffffffc02023da:	0004859b          	sext.w	a1,s1
        if (vma_below_5 != NULL ) {
ffffffffc02023de:	c90d                	beqz	a0,ffffffffc0202410 <vmm_init+0x19e>
           cprintf("vma_below_5: i %x, start %x, end %x\n",i, vma_below_5->vm_start, vma_below_5->vm_end); 
ffffffffc02023e0:	6914                	ld	a3,16(a0)
ffffffffc02023e2:	6510                	ld	a2,8(a0)
ffffffffc02023e4:	00003517          	auipc	a0,0x3
ffffffffc02023e8:	44c50513          	addi	a0,a0,1100 # ffffffffc0205830 <commands+0x12f8>
ffffffffc02023ec:	cd3fd0ef          	jal	ra,ffffffffc02000be <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc02023f0:	00003697          	auipc	a3,0x3
ffffffffc02023f4:	46868693          	addi	a3,a3,1128 # ffffffffc0205858 <commands+0x1320>
ffffffffc02023f8:	00003617          	auipc	a2,0x3
ffffffffc02023fc:	b3060613          	addi	a2,a2,-1232 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202400:	0f600593          	li	a1,246
ffffffffc0202404:	00003517          	auipc	a0,0x3
ffffffffc0202408:	1dc50513          	addi	a0,a0,476 # ffffffffc02055e0 <commands+0x10a8>
ffffffffc020240c:	cfbfd0ef          	jal	ra,ffffffffc0200106 <__panic>
ffffffffc0202410:	14fd                	addi	s1,s1,-1
    for (i =4; i>=0; i--) {
ffffffffc0202412:	fd3490e3          	bne	s1,s3,ffffffffc02023d2 <vmm_init+0x160>
    }

    mm_destroy(mm);
ffffffffc0202416:	8522                	mv	a0,s0
ffffffffc0202418:	e25ff0ef          	jal	ra,ffffffffc020223c <mm_destroy>

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc020241c:	f9efe0ef          	jal	ra,ffffffffc0200bba <nr_free_pages>
ffffffffc0202420:	28aa1c63          	bne	s4,a0,ffffffffc02026b8 <vmm_init+0x446>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0202424:	00003517          	auipc	a0,0x3
ffffffffc0202428:	47450513          	addi	a0,a0,1140 # ffffffffc0205898 <commands+0x1360>
ffffffffc020242c:	c93fd0ef          	jal	ra,ffffffffc02000be <cprintf>

// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void) {
	// char *name = "check_pgfault";
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0202430:	f8afe0ef          	jal	ra,ffffffffc0200bba <nr_free_pages>
ffffffffc0202434:	89aa                	mv	s3,a0

    check_mm_struct = mm_create();
ffffffffc0202436:	c81ff0ef          	jal	ra,ffffffffc02020b6 <mm_create>
ffffffffc020243a:	0000f797          	auipc	a5,0xf
ffffffffc020243e:	06a7bb23          	sd	a0,118(a5) # ffffffffc02114b0 <check_mm_struct>
ffffffffc0202442:	842a                	mv	s0,a0

    assert(check_mm_struct != NULL);
ffffffffc0202444:	2a050a63          	beqz	a0,ffffffffc02026f8 <vmm_init+0x486>
    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202448:	0000f797          	auipc	a5,0xf
ffffffffc020244c:	00878793          	addi	a5,a5,8 # ffffffffc0211450 <boot_pgdir>
ffffffffc0202450:	6384                	ld	s1,0(a5)
    assert(pgdir[0] == 0);
ffffffffc0202452:	609c                	ld	a5,0(s1)
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202454:	ed04                	sd	s1,24(a0)
    assert(pgdir[0] == 0);
ffffffffc0202456:	32079d63          	bnez	a5,ffffffffc0202790 <vmm_init+0x51e>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020245a:	03000513          	li	a0,48
ffffffffc020245e:	ebaff0ef          	jal	ra,ffffffffc0201b18 <kmalloc>
ffffffffc0202462:	8a2a                	mv	s4,a0
    if (vma != NULL) {
ffffffffc0202464:	14050a63          	beqz	a0,ffffffffc02025b8 <vmm_init+0x346>
        vma->vm_end = vm_end;
ffffffffc0202468:	002007b7          	lui	a5,0x200
ffffffffc020246c:	00fa3823          	sd	a5,16(s4)
        vma->vm_flags = vm_flags;
ffffffffc0202470:	4789                	li	a5,2

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);

    assert(vma != NULL);

    insert_vma_struct(mm, vma);
ffffffffc0202472:	85aa                	mv	a1,a0
        vma->vm_flags = vm_flags;
ffffffffc0202474:	00fa3c23          	sd	a5,24(s4)
    insert_vma_struct(mm, vma);
ffffffffc0202478:	8522                	mv	a0,s0
        vma->vm_start = vm_start;
ffffffffc020247a:	000a3423          	sd	zero,8(s4)
    insert_vma_struct(mm, vma);
ffffffffc020247e:	cf1ff0ef          	jal	ra,ffffffffc020216e <insert_vma_struct>

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);
ffffffffc0202482:	10000593          	li	a1,256
ffffffffc0202486:	8522                	mv	a0,s0
ffffffffc0202488:	ca9ff0ef          	jal	ra,ffffffffc0202130 <find_vma>
ffffffffc020248c:	10000793          	li	a5,256

    int i, sum = 0;
    for (i = 0; i < 100; i ++) {
ffffffffc0202490:	16400713          	li	a4,356
    assert(find_vma(mm, addr) == vma);
ffffffffc0202494:	2aaa1263          	bne	s4,a0,ffffffffc0202738 <vmm_init+0x4c6>
        *(char *)(addr + i) = i;
ffffffffc0202498:	00f78023          	sb	a5,0(a5) # 200000 <BASE_ADDRESS-0xffffffffc0000000>
        sum += i;
ffffffffc020249c:	0785                	addi	a5,a5,1
    for (i = 0; i < 100; i ++) {
ffffffffc020249e:	fee79de3          	bne	a5,a4,ffffffffc0202498 <vmm_init+0x226>
        sum += i;
ffffffffc02024a2:	6705                	lui	a4,0x1
    for (i = 0; i < 100; i ++) {
ffffffffc02024a4:	10000793          	li	a5,256
        sum += i;
ffffffffc02024a8:	35670713          	addi	a4,a4,854 # 1356 <BASE_ADDRESS-0xffffffffc01fecaa>
    }
    for (i = 0; i < 100; i ++) {
ffffffffc02024ac:	16400613          	li	a2,356
        sum -= *(char *)(addr + i);
ffffffffc02024b0:	0007c683          	lbu	a3,0(a5)
ffffffffc02024b4:	0785                	addi	a5,a5,1
ffffffffc02024b6:	9f15                	subw	a4,a4,a3
    for (i = 0; i < 100; i ++) {
ffffffffc02024b8:	fec79ce3          	bne	a5,a2,ffffffffc02024b0 <vmm_init+0x23e>
    }
    assert(sum == 0);
ffffffffc02024bc:	2a071a63          	bnez	a4,ffffffffc0202770 <vmm_init+0x4fe>

    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
ffffffffc02024c0:	4581                	li	a1,0
ffffffffc02024c2:	8526                	mv	a0,s1
ffffffffc02024c4:	99dfe0ef          	jal	ra,ffffffffc0200e60 <page_remove>
    return pa2page(PDE_ADDR(pde));
ffffffffc02024c8:	609c                	ld	a5,0(s1)
    if (PPN(pa) >= npage) {
ffffffffc02024ca:	0000f717          	auipc	a4,0xf
ffffffffc02024ce:	f8e70713          	addi	a4,a4,-114 # ffffffffc0211458 <npage>
ffffffffc02024d2:	6318                	ld	a4,0(a4)
    return pa2page(PDE_ADDR(pde));
ffffffffc02024d4:	078a                	slli	a5,a5,0x2
ffffffffc02024d6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02024d8:	28e7f063          	bleu	a4,a5,ffffffffc0202758 <vmm_init+0x4e6>
    return &pages[PPN(pa) - nbase];
ffffffffc02024dc:	00004717          	auipc	a4,0x4
ffffffffc02024e0:	e5c70713          	addi	a4,a4,-420 # ffffffffc0206338 <nbase>
ffffffffc02024e4:	6318                	ld	a4,0(a4)
ffffffffc02024e6:	0000f697          	auipc	a3,0xf
ffffffffc02024ea:	fb268693          	addi	a3,a3,-78 # ffffffffc0211498 <pages>
ffffffffc02024ee:	6288                	ld	a0,0(a3)
ffffffffc02024f0:	8f99                	sub	a5,a5,a4
ffffffffc02024f2:	00379713          	slli	a4,a5,0x3
ffffffffc02024f6:	97ba                	add	a5,a5,a4
ffffffffc02024f8:	078e                	slli	a5,a5,0x3

    free_page(pde2page(pgdir[0]));
ffffffffc02024fa:	953e                	add	a0,a0,a5
ffffffffc02024fc:	4585                	li	a1,1
ffffffffc02024fe:	e76fe0ef          	jal	ra,ffffffffc0200b74 <free_pages>

    pgdir[0] = 0;
ffffffffc0202502:	0004b023          	sd	zero,0(s1)

    mm->pgdir = NULL;
    mm_destroy(mm);
ffffffffc0202506:	8522                	mv	a0,s0
    mm->pgdir = NULL;
ffffffffc0202508:	00043c23          	sd	zero,24(s0)
    mm_destroy(mm);
ffffffffc020250c:	d31ff0ef          	jal	ra,ffffffffc020223c <mm_destroy>

    check_mm_struct = NULL;
    nr_free_pages_store--;	// szx : Sv39第二级页表多占了一个内存页，所以执行此操作
ffffffffc0202510:	19fd                	addi	s3,s3,-1
    check_mm_struct = NULL;
ffffffffc0202512:	0000f797          	auipc	a5,0xf
ffffffffc0202516:	f807bf23          	sd	zero,-98(a5) # ffffffffc02114b0 <check_mm_struct>

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc020251a:	ea0fe0ef          	jal	ra,ffffffffc0200bba <nr_free_pages>
ffffffffc020251e:	1aa99d63          	bne	s3,a0,ffffffffc02026d8 <vmm_init+0x466>

    cprintf("check_pgfault() succeeded!\n");
ffffffffc0202522:	00003517          	auipc	a0,0x3
ffffffffc0202526:	3ee50513          	addi	a0,a0,1006 # ffffffffc0205910 <commands+0x13d8>
ffffffffc020252a:	b95fd0ef          	jal	ra,ffffffffc02000be <cprintf>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc020252e:	e8cfe0ef          	jal	ra,ffffffffc0200bba <nr_free_pages>
    nr_free_pages_store--;	// szx : Sv39三级页表多占一个内存页，所以执行此操作
ffffffffc0202532:	197d                	addi	s2,s2,-1
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0202534:	1ea91263          	bne	s2,a0,ffffffffc0202718 <vmm_init+0x4a6>
}
ffffffffc0202538:	6406                	ld	s0,64(sp)
ffffffffc020253a:	60a6                	ld	ra,72(sp)
ffffffffc020253c:	74e2                	ld	s1,56(sp)
ffffffffc020253e:	7942                	ld	s2,48(sp)
ffffffffc0202540:	79a2                	ld	s3,40(sp)
ffffffffc0202542:	7a02                	ld	s4,32(sp)
ffffffffc0202544:	6ae2                	ld	s5,24(sp)
ffffffffc0202546:	6b42                	ld	s6,16(sp)
ffffffffc0202548:	6ba2                	ld	s7,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc020254a:	00003517          	auipc	a0,0x3
ffffffffc020254e:	3e650513          	addi	a0,a0,998 # ffffffffc0205930 <commands+0x13f8>
}
ffffffffc0202552:	6161                	addi	sp,sp,80
    cprintf("check_vmm() succeeded.\n");
ffffffffc0202554:	b6bfd06f          	j	ffffffffc02000be <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0202558:	00003697          	auipc	a3,0x3
ffffffffc020255c:	1f068693          	addi	a3,a3,496 # ffffffffc0205748 <commands+0x1210>
ffffffffc0202560:	00003617          	auipc	a2,0x3
ffffffffc0202564:	9c860613          	addi	a2,a2,-1592 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202568:	0dd00593          	li	a1,221
ffffffffc020256c:	00003517          	auipc	a0,0x3
ffffffffc0202570:	07450513          	addi	a0,a0,116 # ffffffffc02055e0 <commands+0x10a8>
ffffffffc0202574:	b93fd0ef          	jal	ra,ffffffffc0200106 <__panic>
        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc0202578:	00003697          	auipc	a3,0x3
ffffffffc020257c:	25868693          	addi	a3,a3,600 # ffffffffc02057d0 <commands+0x1298>
ffffffffc0202580:	00003617          	auipc	a2,0x3
ffffffffc0202584:	9a860613          	addi	a2,a2,-1624 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202588:	0ed00593          	li	a1,237
ffffffffc020258c:	00003517          	auipc	a0,0x3
ffffffffc0202590:	05450513          	addi	a0,a0,84 # ffffffffc02055e0 <commands+0x10a8>
ffffffffc0202594:	b73fd0ef          	jal	ra,ffffffffc0200106 <__panic>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc0202598:	00003697          	auipc	a3,0x3
ffffffffc020259c:	26868693          	addi	a3,a3,616 # ffffffffc0205800 <commands+0x12c8>
ffffffffc02025a0:	00003617          	auipc	a2,0x3
ffffffffc02025a4:	98860613          	addi	a2,a2,-1656 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02025a8:	0ee00593          	li	a1,238
ffffffffc02025ac:	00003517          	auipc	a0,0x3
ffffffffc02025b0:	03450513          	addi	a0,a0,52 # ffffffffc02055e0 <commands+0x10a8>
ffffffffc02025b4:	b53fd0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(vma != NULL);
ffffffffc02025b8:	00003697          	auipc	a3,0x3
ffffffffc02025bc:	39068693          	addi	a3,a3,912 # ffffffffc0205948 <commands+0x1410>
ffffffffc02025c0:	00003617          	auipc	a2,0x3
ffffffffc02025c4:	96860613          	addi	a2,a2,-1688 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02025c8:	11100593          	li	a1,273
ffffffffc02025cc:	00003517          	auipc	a0,0x3
ffffffffc02025d0:	01450513          	addi	a0,a0,20 # ffffffffc02055e0 <commands+0x10a8>
ffffffffc02025d4:	b33fd0ef          	jal	ra,ffffffffc0200106 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc02025d8:	00003697          	auipc	a3,0x3
ffffffffc02025dc:	15868693          	addi	a3,a3,344 # ffffffffc0205730 <commands+0x11f8>
ffffffffc02025e0:	00003617          	auipc	a2,0x3
ffffffffc02025e4:	94860613          	addi	a2,a2,-1720 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02025e8:	0db00593          	li	a1,219
ffffffffc02025ec:	00003517          	auipc	a0,0x3
ffffffffc02025f0:	ff450513          	addi	a0,a0,-12 # ffffffffc02055e0 <commands+0x10a8>
ffffffffc02025f4:	b13fd0ef          	jal	ra,ffffffffc0200106 <__panic>
        assert(vma4 == NULL);
ffffffffc02025f8:	00003697          	auipc	a3,0x3
ffffffffc02025fc:	1b868693          	addi	a3,a3,440 # ffffffffc02057b0 <commands+0x1278>
ffffffffc0202600:	00003617          	auipc	a2,0x3
ffffffffc0202604:	92860613          	addi	a2,a2,-1752 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202608:	0e900593          	li	a1,233
ffffffffc020260c:	00003517          	auipc	a0,0x3
ffffffffc0202610:	fd450513          	addi	a0,a0,-44 # ffffffffc02055e0 <commands+0x10a8>
ffffffffc0202614:	af3fd0ef          	jal	ra,ffffffffc0200106 <__panic>
        assert(vma3 == NULL);
ffffffffc0202618:	00003697          	auipc	a3,0x3
ffffffffc020261c:	18868693          	addi	a3,a3,392 # ffffffffc02057a0 <commands+0x1268>
ffffffffc0202620:	00003617          	auipc	a2,0x3
ffffffffc0202624:	90860613          	addi	a2,a2,-1784 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202628:	0e700593          	li	a1,231
ffffffffc020262c:	00003517          	auipc	a0,0x3
ffffffffc0202630:	fb450513          	addi	a0,a0,-76 # ffffffffc02055e0 <commands+0x10a8>
ffffffffc0202634:	ad3fd0ef          	jal	ra,ffffffffc0200106 <__panic>
        assert(vma2 != NULL);
ffffffffc0202638:	00003697          	auipc	a3,0x3
ffffffffc020263c:	15868693          	addi	a3,a3,344 # ffffffffc0205790 <commands+0x1258>
ffffffffc0202640:	00003617          	auipc	a2,0x3
ffffffffc0202644:	8e860613          	addi	a2,a2,-1816 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202648:	0e500593          	li	a1,229
ffffffffc020264c:	00003517          	auipc	a0,0x3
ffffffffc0202650:	f9450513          	addi	a0,a0,-108 # ffffffffc02055e0 <commands+0x10a8>
ffffffffc0202654:	ab3fd0ef          	jal	ra,ffffffffc0200106 <__panic>
        assert(vma1 != NULL);
ffffffffc0202658:	00003697          	auipc	a3,0x3
ffffffffc020265c:	12868693          	addi	a3,a3,296 # ffffffffc0205780 <commands+0x1248>
ffffffffc0202660:	00003617          	auipc	a2,0x3
ffffffffc0202664:	8c860613          	addi	a2,a2,-1848 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202668:	0e300593          	li	a1,227
ffffffffc020266c:	00003517          	auipc	a0,0x3
ffffffffc0202670:	f7450513          	addi	a0,a0,-140 # ffffffffc02055e0 <commands+0x10a8>
ffffffffc0202674:	a93fd0ef          	jal	ra,ffffffffc0200106 <__panic>
        assert(vma5 == NULL);
ffffffffc0202678:	00003697          	auipc	a3,0x3
ffffffffc020267c:	14868693          	addi	a3,a3,328 # ffffffffc02057c0 <commands+0x1288>
ffffffffc0202680:	00003617          	auipc	a2,0x3
ffffffffc0202684:	8a860613          	addi	a2,a2,-1880 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202688:	0eb00593          	li	a1,235
ffffffffc020268c:	00003517          	auipc	a0,0x3
ffffffffc0202690:	f5450513          	addi	a0,a0,-172 # ffffffffc02055e0 <commands+0x10a8>
ffffffffc0202694:	a73fd0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(mm != NULL);
ffffffffc0202698:	00003697          	auipc	a3,0x3
ffffffffc020269c:	08868693          	addi	a3,a3,136 # ffffffffc0205720 <commands+0x11e8>
ffffffffc02026a0:	00003617          	auipc	a2,0x3
ffffffffc02026a4:	88860613          	addi	a2,a2,-1912 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02026a8:	0c700593          	li	a1,199
ffffffffc02026ac:	00003517          	auipc	a0,0x3
ffffffffc02026b0:	f3450513          	addi	a0,a0,-204 # ffffffffc02055e0 <commands+0x10a8>
ffffffffc02026b4:	a53fd0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02026b8:	00003697          	auipc	a3,0x3
ffffffffc02026bc:	1b868693          	addi	a3,a3,440 # ffffffffc0205870 <commands+0x1338>
ffffffffc02026c0:	00003617          	auipc	a2,0x3
ffffffffc02026c4:	86860613          	addi	a2,a2,-1944 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02026c8:	0fb00593          	li	a1,251
ffffffffc02026cc:	00003517          	auipc	a0,0x3
ffffffffc02026d0:	f1450513          	addi	a0,a0,-236 # ffffffffc02055e0 <commands+0x10a8>
ffffffffc02026d4:	a33fd0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02026d8:	00003697          	auipc	a3,0x3
ffffffffc02026dc:	19868693          	addi	a3,a3,408 # ffffffffc0205870 <commands+0x1338>
ffffffffc02026e0:	00003617          	auipc	a2,0x3
ffffffffc02026e4:	84860613          	addi	a2,a2,-1976 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02026e8:	12e00593          	li	a1,302
ffffffffc02026ec:	00003517          	auipc	a0,0x3
ffffffffc02026f0:	ef450513          	addi	a0,a0,-268 # ffffffffc02055e0 <commands+0x10a8>
ffffffffc02026f4:	a13fd0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(check_mm_struct != NULL);
ffffffffc02026f8:	00003697          	auipc	a3,0x3
ffffffffc02026fc:	1c068693          	addi	a3,a3,448 # ffffffffc02058b8 <commands+0x1380>
ffffffffc0202700:	00003617          	auipc	a2,0x3
ffffffffc0202704:	82860613          	addi	a2,a2,-2008 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202708:	10a00593          	li	a1,266
ffffffffc020270c:	00003517          	auipc	a0,0x3
ffffffffc0202710:	ed450513          	addi	a0,a0,-300 # ffffffffc02055e0 <commands+0x10a8>
ffffffffc0202714:	9f3fd0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0202718:	00003697          	auipc	a3,0x3
ffffffffc020271c:	15868693          	addi	a3,a3,344 # ffffffffc0205870 <commands+0x1338>
ffffffffc0202720:	00003617          	auipc	a2,0x3
ffffffffc0202724:	80860613          	addi	a2,a2,-2040 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202728:	0bd00593          	li	a1,189
ffffffffc020272c:	00003517          	auipc	a0,0x3
ffffffffc0202730:	eb450513          	addi	a0,a0,-332 # ffffffffc02055e0 <commands+0x10a8>
ffffffffc0202734:	9d3fd0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(find_vma(mm, addr) == vma);
ffffffffc0202738:	00003697          	auipc	a3,0x3
ffffffffc020273c:	1a868693          	addi	a3,a3,424 # ffffffffc02058e0 <commands+0x13a8>
ffffffffc0202740:	00002617          	auipc	a2,0x2
ffffffffc0202744:	7e860613          	addi	a2,a2,2024 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202748:	11600593          	li	a1,278
ffffffffc020274c:	00003517          	auipc	a0,0x3
ffffffffc0202750:	e9450513          	addi	a0,a0,-364 # ffffffffc02055e0 <commands+0x10a8>
ffffffffc0202754:	9b3fd0ef          	jal	ra,ffffffffc0200106 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0202758:	00002617          	auipc	a2,0x2
ffffffffc020275c:	69860613          	addi	a2,a2,1688 # ffffffffc0204df0 <commands+0x8b8>
ffffffffc0202760:	06500593          	li	a1,101
ffffffffc0202764:	00002517          	auipc	a0,0x2
ffffffffc0202768:	6ac50513          	addi	a0,a0,1708 # ffffffffc0204e10 <commands+0x8d8>
ffffffffc020276c:	99bfd0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(sum == 0);
ffffffffc0202770:	00003697          	auipc	a3,0x3
ffffffffc0202774:	19068693          	addi	a3,a3,400 # ffffffffc0205900 <commands+0x13c8>
ffffffffc0202778:	00002617          	auipc	a2,0x2
ffffffffc020277c:	7b060613          	addi	a2,a2,1968 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202780:	12000593          	li	a1,288
ffffffffc0202784:	00003517          	auipc	a0,0x3
ffffffffc0202788:	e5c50513          	addi	a0,a0,-420 # ffffffffc02055e0 <commands+0x10a8>
ffffffffc020278c:	97bfd0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(pgdir[0] == 0);
ffffffffc0202790:	00003697          	auipc	a3,0x3
ffffffffc0202794:	14068693          	addi	a3,a3,320 # ffffffffc02058d0 <commands+0x1398>
ffffffffc0202798:	00002617          	auipc	a2,0x2
ffffffffc020279c:	79060613          	addi	a2,a2,1936 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02027a0:	10d00593          	li	a1,269
ffffffffc02027a4:	00003517          	auipc	a0,0x3
ffffffffc02027a8:	e3c50513          	addi	a0,a0,-452 # ffffffffc02055e0 <commands+0x10a8>
ffffffffc02027ac:	95bfd0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc02027b0 <do_pgfault>:
 *            was a read (0) or write (1).
 *         -- The U/S flag (bit 2) indicates whether the processor was executing at user mode (1)
 *            or supervisor mode (0) at the time of the exception.
 */
int
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc02027b0:	7139                	addi	sp,sp,-64



    int ret = -E_INVAL;
    //try to find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc02027b2:	85b2                	mv	a1,a2
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc02027b4:	f822                	sd	s0,48(sp)
ffffffffc02027b6:	f426                	sd	s1,40(sp)
ffffffffc02027b8:	fc06                	sd	ra,56(sp)
ffffffffc02027ba:	f04a                	sd	s2,32(sp)
ffffffffc02027bc:	ec4e                	sd	s3,24(sp)
ffffffffc02027be:	8432                	mv	s0,a2
ffffffffc02027c0:	84aa                	mv	s1,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc02027c2:	96fff0ef          	jal	ra,ffffffffc0202130 <find_vma>

    pgfault_num++;
ffffffffc02027c6:	0000f797          	auipc	a5,0xf
ffffffffc02027ca:	c9a78793          	addi	a5,a5,-870 # ffffffffc0211460 <pgfault_num>
ffffffffc02027ce:	439c                	lw	a5,0(a5)
ffffffffc02027d0:	2785                	addiw	a5,a5,1
ffffffffc02027d2:	0000f717          	auipc	a4,0xf
ffffffffc02027d6:	c8f72723          	sw	a5,-882(a4) # ffffffffc0211460 <pgfault_num>
    //If the addr is in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr) {
ffffffffc02027da:	cd79                	beqz	a0,ffffffffc02028b8 <do_pgfault+0x108>
ffffffffc02027dc:	651c                	ld	a5,8(a0)
ffffffffc02027de:	0cf46d63          	bltu	s0,a5,ffffffffc02028b8 <do_pgfault+0x108>
     *    (read  an non_existed addr && addr is readable)
     * THEN
     *    continue process
     */
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) {
ffffffffc02027e2:	6d1c                	ld	a5,24(a0)
    uint32_t perm = PTE_U;
ffffffffc02027e4:	49c1                	li	s3,16
    if (vma->vm_flags & VM_WRITE) {
ffffffffc02027e6:	8b89                	andi	a5,a5,2
ffffffffc02027e8:	e7dd                	bnez	a5,ffffffffc0202896 <do_pgfault+0xe6>
        perm |= (PTE_R | PTE_W);
    }
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc02027ea:	77fd                	lui	a5,0xfffff
    */




    ptep = get_pte(mm->pgdir, addr, 1);  //(1) try to find a pte, if pte's
ffffffffc02027ec:	6c88                	ld	a0,24(s1)
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc02027ee:	8c7d                	and	s0,s0,a5
    ptep = get_pte(mm->pgdir, addr, 1);  //(1) try to find a pte, if pte's
ffffffffc02027f0:	4605                	li	a2,1
ffffffffc02027f2:	85a2                	mv	a1,s0
ffffffffc02027f4:	c06fe0ef          	jal	ra,ffffffffc0200bfa <get_pte>
                                         //PT(Page Table) isn't existed, then
                                         //create a PT.

    //*ptep |= PTE_R;                                     

    cprintf("\n%p\n",*ptep);
ffffffffc02027f8:	610c                	ld	a1,0(a0)
    ptep = get_pte(mm->pgdir, addr, 1);  //(1) try to find a pte, if pte's
ffffffffc02027fa:	892a                	mv	s2,a0
    cprintf("\n%p\n",*ptep);
ffffffffc02027fc:	00003517          	auipc	a0,0x3
ffffffffc0202800:	e2450513          	addi	a0,a0,-476 # ffffffffc0205620 <commands+0x10e8>
ffffffffc0202804:	8bbfd0ef          	jal	ra,ffffffffc02000be <cprintf>

    if (*ptep == 0) {
ffffffffc0202808:	00093583          	ld	a1,0(s2)
ffffffffc020280c:	c5d9                	beqz	a1,ffffffffc020289a <do_pgfault+0xea>
        *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
        *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
        *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
        *    swap_map_swappable ： 设置页面可交换
        */
        if (swap_init_ok) {
ffffffffc020280e:	0000f797          	auipc	a5,0xf
ffffffffc0202812:	c6278793          	addi	a5,a5,-926 # ffffffffc0211470 <swap_init_ok>
ffffffffc0202816:	439c                	lw	a5,0(a5)
ffffffffc0202818:	2781                	sext.w	a5,a5
ffffffffc020281a:	cbc5                	beqz	a5,ffffffffc02028ca <do_pgfault+0x11a>
            //(1）According to the mm AND addr, try
            //to load the content of right disk page
            //into the memory which page managed.
            // swap_in(mm, addr, &page);
            // 根据 mm 和 addr，将适当的磁盘页的内容加载到由 page 管理的内存中
            if (swap_in(mm, addr, &page) != 0) {
ffffffffc020281c:	0030                	addi	a2,sp,8
ffffffffc020281e:	85a2                	mv	a1,s0
ffffffffc0202820:	8526                	mv	a0,s1
            struct Page *page = NULL;
ffffffffc0202822:	e402                	sd	zero,8(sp)
            if (swap_in(mm, addr, &page) != 0) {
ffffffffc0202824:	0df000ef          	jal	ra,ffffffffc0203102 <swap_in>
ffffffffc0202828:	e94d                	bnez	a0,ffffffffc02028da <do_pgfault+0x12a>
            //addr AND page, setup the
            //map of phy addr <--->
            //logical addr
            // page_insert(mm->pgdir, page, addr, perm);
            // 建立物理地址（page->phy_addr）与逻辑地址（addr）的映射关系
            if (page_insert(mm->pgdir, page, addr, perm) != 0) {
ffffffffc020282a:	65a2                	ld	a1,8(sp)
ffffffffc020282c:	6c88                	ld	a0,24(s1)
ffffffffc020282e:	86ce                	mv	a3,s3
ffffffffc0202830:	8622                	mv	a2,s0
ffffffffc0202832:	ea0fe0ef          	jal	ra,ffffffffc0200ed2 <page_insert>
ffffffffc0202836:	892a                	mv	s2,a0
ffffffffc0202838:	e94d                	bnez	a0,ffffffffc02028ea <do_pgfault+0x13a>
                cprintf("page_insert in do_pgfault failed\n");
                goto failed;
            }
            //(3) make the page swappable.
            swap_map_swappable(mm, addr, page, 1);
ffffffffc020283a:	6622                	ld	a2,8(sp)
ffffffffc020283c:	4685                	li	a3,1
ffffffffc020283e:	85a2                	mv	a1,s0
ffffffffc0202840:	8526                	mv	a0,s1
ffffffffc0202842:	79c000ef          	jal	ra,ffffffffc0202fde <swap_map_swappable>
            page->pra_vaddr = addr;
ffffffffc0202846:	67a2                	ld	a5,8(sp)
ffffffffc0202848:	e3a0                	sd	s0,64(a5)
    if (PPN(pa) >= npage) {
ffffffffc020284a:	0000f797          	auipc	a5,0xf
ffffffffc020284e:	c0e78793          	addi	a5,a5,-1010 # ffffffffc0211458 <npage>
ffffffffc0202852:	639c                	ld	a5,0(a5)
ffffffffc0202854:	8031                	srli	s0,s0,0xc
ffffffffc0202856:	0af47263          	bleu	a5,s0,ffffffffc02028fa <do_pgfault+0x14a>
    return &pages[PPN(pa) - nbase];
ffffffffc020285a:	00004797          	auipc	a5,0x4
ffffffffc020285e:	ade78793          	addi	a5,a5,-1314 # ffffffffc0206338 <nbase>
ffffffffc0202862:	639c                	ld	a5,0(a5)
ffffffffc0202864:	0000f717          	auipc	a4,0xf
ffffffffc0202868:	c3470713          	addi	a4,a4,-972 # ffffffffc0211498 <pages>
ffffffffc020286c:	630c                	ld	a1,0(a4)
ffffffffc020286e:	8c1d                	sub	s0,s0,a5
ffffffffc0202870:	00341793          	slli	a5,s0,0x3
ffffffffc0202874:	943e                	add	s0,s0,a5
ffffffffc0202876:	040e                	slli	s0,s0,0x3
            goto failed;
        }
   }
   ret = 0;
failed:
    cprintf("\n%p\n",pa2page(addr));
ffffffffc0202878:	95a2                	add	a1,a1,s0
ffffffffc020287a:	00003517          	auipc	a0,0x3
ffffffffc020287e:	da650513          	addi	a0,a0,-602 # ffffffffc0205620 <commands+0x10e8>
ffffffffc0202882:	83dfd0ef          	jal	ra,ffffffffc02000be <cprintf>
//         pte_t *pte = get_pte(mm ->pgdir, ptr -> pra_vaddr, 0);
//         *pte &= (~PTE_R);
//         temp=list_next(temp);//把所有的页的属性改回来
//     }
    return ret;
}
ffffffffc0202886:	70e2                	ld	ra,56(sp)
ffffffffc0202888:	7442                	ld	s0,48(sp)
ffffffffc020288a:	854a                	mv	a0,s2
ffffffffc020288c:	74a2                	ld	s1,40(sp)
ffffffffc020288e:	7902                	ld	s2,32(sp)
ffffffffc0202890:	69e2                	ld	s3,24(sp)
ffffffffc0202892:	6121                	addi	sp,sp,64
ffffffffc0202894:	8082                	ret
        perm |= (PTE_R | PTE_W);
ffffffffc0202896:	49d9                	li	s3,22
ffffffffc0202898:	bf89                	j	ffffffffc02027ea <do_pgfault+0x3a>
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc020289a:	6c88                	ld	a0,24(s1)
ffffffffc020289c:	864e                	mv	a2,s3
ffffffffc020289e:	85a2                	mv	a1,s0
ffffffffc02028a0:	9e6ff0ef          	jal	ra,ffffffffc0201a86 <pgdir_alloc_page>
   ret = 0;
ffffffffc02028a4:	4901                	li	s2,0
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc02028a6:	f155                	bnez	a0,ffffffffc020284a <do_pgfault+0x9a>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
ffffffffc02028a8:	00003517          	auipc	a0,0x3
ffffffffc02028ac:	d8050513          	addi	a0,a0,-640 # ffffffffc0205628 <commands+0x10f0>
ffffffffc02028b0:	80ffd0ef          	jal	ra,ffffffffc02000be <cprintf>
    ret = -E_NO_MEM;
ffffffffc02028b4:	5971                	li	s2,-4
            goto failed;
ffffffffc02028b6:	bf51                	j	ffffffffc020284a <do_pgfault+0x9a>
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
ffffffffc02028b8:	85a2                	mv	a1,s0
ffffffffc02028ba:	00003517          	auipc	a0,0x3
ffffffffc02028be:	d3650513          	addi	a0,a0,-714 # ffffffffc02055f0 <commands+0x10b8>
ffffffffc02028c2:	ffcfd0ef          	jal	ra,ffffffffc02000be <cprintf>
    int ret = -E_INVAL;
ffffffffc02028c6:	5975                	li	s2,-3
        goto failed;
ffffffffc02028c8:	b749                	j	ffffffffc020284a <do_pgfault+0x9a>
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
ffffffffc02028ca:	00003517          	auipc	a0,0x3
ffffffffc02028ce:	dce50513          	addi	a0,a0,-562 # ffffffffc0205698 <commands+0x1160>
ffffffffc02028d2:	fecfd0ef          	jal	ra,ffffffffc02000be <cprintf>
    ret = -E_NO_MEM;
ffffffffc02028d6:	5971                	li	s2,-4
            goto failed;
ffffffffc02028d8:	bf8d                	j	ffffffffc020284a <do_pgfault+0x9a>
                cprintf("swap_in in do_pgfault failed\n");
ffffffffc02028da:	00003517          	auipc	a0,0x3
ffffffffc02028de:	d7650513          	addi	a0,a0,-650 # ffffffffc0205650 <commands+0x1118>
ffffffffc02028e2:	fdcfd0ef          	jal	ra,ffffffffc02000be <cprintf>
    ret = -E_NO_MEM;
ffffffffc02028e6:	5971                	li	s2,-4
ffffffffc02028e8:	b78d                	j	ffffffffc020284a <do_pgfault+0x9a>
                cprintf("page_insert in do_pgfault failed\n");
ffffffffc02028ea:	00003517          	auipc	a0,0x3
ffffffffc02028ee:	d8650513          	addi	a0,a0,-634 # ffffffffc0205670 <commands+0x1138>
ffffffffc02028f2:	fccfd0ef          	jal	ra,ffffffffc02000be <cprintf>
    ret = -E_NO_MEM;
ffffffffc02028f6:	5971                	li	s2,-4
ffffffffc02028f8:	bf89                	j	ffffffffc020284a <do_pgfault+0x9a>
        panic("pa2page called with invalid pa");
ffffffffc02028fa:	00002617          	auipc	a2,0x2
ffffffffc02028fe:	4f660613          	addi	a2,a2,1270 # ffffffffc0204df0 <commands+0x8b8>
ffffffffc0202902:	06500593          	li	a1,101
ffffffffc0202906:	00002517          	auipc	a0,0x2
ffffffffc020290a:	50a50513          	addi	a0,a0,1290 # ffffffffc0204e10 <commands+0x8d8>
ffffffffc020290e:	ff8fd0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc0202912 <swap_init>:

static void check_swap(void);

int
swap_init(void)
{
ffffffffc0202912:	7135                	addi	sp,sp,-160
ffffffffc0202914:	ed06                	sd	ra,152(sp)
ffffffffc0202916:	e922                	sd	s0,144(sp)
ffffffffc0202918:	e526                	sd	s1,136(sp)
ffffffffc020291a:	e14a                	sd	s2,128(sp)
ffffffffc020291c:	fcce                	sd	s3,120(sp)
ffffffffc020291e:	f8d2                	sd	s4,112(sp)
ffffffffc0202920:	f4d6                	sd	s5,104(sp)
ffffffffc0202922:	f0da                	sd	s6,96(sp)
ffffffffc0202924:	ecde                	sd	s7,88(sp)
ffffffffc0202926:	e8e2                	sd	s8,80(sp)
ffffffffc0202928:	e4e6                	sd	s9,72(sp)
ffffffffc020292a:	e0ea                	sd	s10,64(sp)
ffffffffc020292c:	fc6e                	sd	s11,56(sp)
     swapfs_init();
ffffffffc020292e:	3c0010ef          	jal	ra,ffffffffc0203cee <swapfs_init>

     // Since the IDE is faked, it can only store 7 pages at most to pass the test
     if (!(7 <= max_swap_offset &&
ffffffffc0202932:	0000f797          	auipc	a5,0xf
ffffffffc0202936:	c0e78793          	addi	a5,a5,-1010 # ffffffffc0211540 <max_swap_offset>
ffffffffc020293a:	6394                	ld	a3,0(a5)
ffffffffc020293c:	010007b7          	lui	a5,0x1000
ffffffffc0202940:	17e1                	addi	a5,a5,-8
ffffffffc0202942:	ff968713          	addi	a4,a3,-7
ffffffffc0202946:	44e7e863          	bltu	a5,a4,ffffffffc0202d96 <swap_init+0x484>
        max_swap_offset < MAX_SWAP_OFFSET_LIMIT)) {
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
     }

     //sm=&swap_manager_fifo;
    sm = &swap_manager_fifo;//use first in first out Page Replacement Algorithm
ffffffffc020294a:	00007797          	auipc	a5,0x7
ffffffffc020294e:	6b678793          	addi	a5,a5,1718 # ffffffffc020a000 <swap_manager_fifo>
     int r = sm->init();
ffffffffc0202952:	6798                	ld	a4,8(a5)
    sm = &swap_manager_fifo;//use first in first out Page Replacement Algorithm
ffffffffc0202954:	0000f697          	auipc	a3,0xf
ffffffffc0202958:	b0f6ba23          	sd	a5,-1260(a3) # ffffffffc0211468 <sm>
     int r = sm->init();
ffffffffc020295c:	9702                	jalr	a4
ffffffffc020295e:	8b2a                	mv	s6,a0
     
     if (r == 0)
ffffffffc0202960:	c10d                	beqz	a0,ffffffffc0202982 <swap_init+0x70>
          cprintf("SWAP: manager = %s\n", sm->name);
          check_swap();
     }

     return r;
}
ffffffffc0202962:	60ea                	ld	ra,152(sp)
ffffffffc0202964:	644a                	ld	s0,144(sp)
ffffffffc0202966:	855a                	mv	a0,s6
ffffffffc0202968:	64aa                	ld	s1,136(sp)
ffffffffc020296a:	690a                	ld	s2,128(sp)
ffffffffc020296c:	79e6                	ld	s3,120(sp)
ffffffffc020296e:	7a46                	ld	s4,112(sp)
ffffffffc0202970:	7aa6                	ld	s5,104(sp)
ffffffffc0202972:	7b06                	ld	s6,96(sp)
ffffffffc0202974:	6be6                	ld	s7,88(sp)
ffffffffc0202976:	6c46                	ld	s8,80(sp)
ffffffffc0202978:	6ca6                	ld	s9,72(sp)
ffffffffc020297a:	6d06                	ld	s10,64(sp)
ffffffffc020297c:	7de2                	ld	s11,56(sp)
ffffffffc020297e:	610d                	addi	sp,sp,160
ffffffffc0202980:	8082                	ret
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0202982:	0000f797          	auipc	a5,0xf
ffffffffc0202986:	ae678793          	addi	a5,a5,-1306 # ffffffffc0211468 <sm>
ffffffffc020298a:	639c                	ld	a5,0(a5)
ffffffffc020298c:	00003517          	auipc	a0,0x3
ffffffffc0202990:	04c50513          	addi	a0,a0,76 # ffffffffc02059d8 <commands+0x14a0>
ffffffffc0202994:	0000f417          	auipc	s0,0xf
ffffffffc0202998:	bec40413          	addi	s0,s0,-1044 # ffffffffc0211580 <free_area>
ffffffffc020299c:	638c                	ld	a1,0(a5)
          swap_init_ok = 1;
ffffffffc020299e:	4785                	li	a5,1
ffffffffc02029a0:	0000f717          	auipc	a4,0xf
ffffffffc02029a4:	acf72823          	sw	a5,-1328(a4) # ffffffffc0211470 <swap_init_ok>
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc02029a8:	f16fd0ef          	jal	ra,ffffffffc02000be <cprintf>
ffffffffc02029ac:	641c                	ld	a5,8(s0)
check_swap(void)
{
    //backup mem env
     int ret, count = 0, total = 0, i;
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc02029ae:	30878863          	beq	a5,s0,ffffffffc0202cbe <swap_init+0x3ac>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02029b2:	fe87b703          	ld	a4,-24(a5)
ffffffffc02029b6:	8305                	srli	a4,a4,0x1
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc02029b8:	8b05                	andi	a4,a4,1
ffffffffc02029ba:	30070663          	beqz	a4,ffffffffc0202cc6 <swap_init+0x3b4>
     int ret, count = 0, total = 0, i;
ffffffffc02029be:	4481                	li	s1,0
ffffffffc02029c0:	4901                	li	s2,0
ffffffffc02029c2:	a031                	j	ffffffffc02029ce <swap_init+0xbc>
ffffffffc02029c4:	fe87b703          	ld	a4,-24(a5)
        assert(PageProperty(p));
ffffffffc02029c8:	8b09                	andi	a4,a4,2
ffffffffc02029ca:	2e070e63          	beqz	a4,ffffffffc0202cc6 <swap_init+0x3b4>
        count ++, total += p->property;
ffffffffc02029ce:	ff87a703          	lw	a4,-8(a5)
ffffffffc02029d2:	679c                	ld	a5,8(a5)
ffffffffc02029d4:	2905                	addiw	s2,s2,1
ffffffffc02029d6:	9cb9                	addw	s1,s1,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc02029d8:	fe8796e3          	bne	a5,s0,ffffffffc02029c4 <swap_init+0xb2>
ffffffffc02029dc:	89a6                	mv	s3,s1
     }
     assert(total == nr_free_pages());
ffffffffc02029de:	9dcfe0ef          	jal	ra,ffffffffc0200bba <nr_free_pages>
ffffffffc02029e2:	5d351663          	bne	a0,s3,ffffffffc0202fae <swap_init+0x69c>
     cprintf("BEGIN check_swap: count %d, total %d\n",count,total);
ffffffffc02029e6:	8626                	mv	a2,s1
ffffffffc02029e8:	85ca                	mv	a1,s2
ffffffffc02029ea:	00003517          	auipc	a0,0x3
ffffffffc02029ee:	03650513          	addi	a0,a0,54 # ffffffffc0205a20 <commands+0x14e8>
ffffffffc02029f2:	eccfd0ef          	jal	ra,ffffffffc02000be <cprintf>
     
     //now we set the phy pages env     
     struct mm_struct *mm = mm_create();
ffffffffc02029f6:	ec0ff0ef          	jal	ra,ffffffffc02020b6 <mm_create>
ffffffffc02029fa:	8baa                	mv	s7,a0
     assert(mm != NULL);
ffffffffc02029fc:	52050963          	beqz	a0,ffffffffc0202f2e <swap_init+0x61c>

     extern struct mm_struct *check_mm_struct;
     assert(check_mm_struct == NULL);
ffffffffc0202a00:	0000f797          	auipc	a5,0xf
ffffffffc0202a04:	ab078793          	addi	a5,a5,-1360 # ffffffffc02114b0 <check_mm_struct>
ffffffffc0202a08:	639c                	ld	a5,0(a5)
ffffffffc0202a0a:	54079263          	bnez	a5,ffffffffc0202f4e <swap_init+0x63c>

     check_mm_struct = mm;

     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202a0e:	0000f797          	auipc	a5,0xf
ffffffffc0202a12:	a4278793          	addi	a5,a5,-1470 # ffffffffc0211450 <boot_pgdir>
ffffffffc0202a16:	6398                	ld	a4,0(a5)
     check_mm_struct = mm;
ffffffffc0202a18:	0000f797          	auipc	a5,0xf
ffffffffc0202a1c:	a8a7bc23          	sd	a0,-1384(a5) # ffffffffc02114b0 <check_mm_struct>
     assert(pgdir[0] == 0);
ffffffffc0202a20:	631c                	ld	a5,0(a4)
     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202a22:	ec3a                	sd	a4,24(sp)
ffffffffc0202a24:	ed18                	sd	a4,24(a0)
     assert(pgdir[0] == 0);
ffffffffc0202a26:	54079463          	bnez	a5,ffffffffc0202f6e <swap_init+0x65c>

     struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ);
ffffffffc0202a2a:	6599                	lui	a1,0x6
ffffffffc0202a2c:	460d                	li	a2,3
ffffffffc0202a2e:	6505                	lui	a0,0x1
ffffffffc0202a30:	ed2ff0ef          	jal	ra,ffffffffc0202102 <vma_create>
ffffffffc0202a34:	85aa                	mv	a1,a0
     assert(vma != NULL);
ffffffffc0202a36:	54050c63          	beqz	a0,ffffffffc0202f8e <swap_init+0x67c>

     insert_vma_struct(mm, vma);
ffffffffc0202a3a:	855e                	mv	a0,s7
ffffffffc0202a3c:	f32ff0ef          	jal	ra,ffffffffc020216e <insert_vma_struct>

     //setup the temp Page Table vaddr 0~4MB
     cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
ffffffffc0202a40:	00003517          	auipc	a0,0x3
ffffffffc0202a44:	02050513          	addi	a0,a0,32 # ffffffffc0205a60 <commands+0x1528>
ffffffffc0202a48:	e76fd0ef          	jal	ra,ffffffffc02000be <cprintf>
     pte_t *temp_ptep=NULL;
     temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1);
ffffffffc0202a4c:	018bb503          	ld	a0,24(s7)
ffffffffc0202a50:	4605                	li	a2,1
ffffffffc0202a52:	6585                	lui	a1,0x1
ffffffffc0202a54:	9a6fe0ef          	jal	ra,ffffffffc0200bfa <get_pte>
     assert(temp_ptep!= NULL);
ffffffffc0202a58:	42050b63          	beqz	a0,ffffffffc0202e8e <swap_init+0x57c>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0202a5c:	00003517          	auipc	a0,0x3
ffffffffc0202a60:	05450513          	addi	a0,a0,84 # ffffffffc0205ab0 <commands+0x1578>
ffffffffc0202a64:	0000fa17          	auipc	s4,0xf
ffffffffc0202a68:	a54a0a13          	addi	s4,s4,-1452 # ffffffffc02114b8 <check_rp>
ffffffffc0202a6c:	e52fd0ef          	jal	ra,ffffffffc02000be <cprintf>
     
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202a70:	0000fa97          	auipc	s5,0xf
ffffffffc0202a74:	a68a8a93          	addi	s5,s5,-1432 # ffffffffc02114d8 <swap_in_seq_no>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0202a78:	89d2                	mv	s3,s4
          check_rp[i] = alloc_page();
ffffffffc0202a7a:	4505                	li	a0,1
ffffffffc0202a7c:	870fe0ef          	jal	ra,ffffffffc0200aec <alloc_pages>
ffffffffc0202a80:	00a9b023          	sd	a0,0(s3)
          assert(check_rp[i] != NULL );
ffffffffc0202a84:	2c050963          	beqz	a0,ffffffffc0202d56 <swap_init+0x444>
ffffffffc0202a88:	651c                	ld	a5,8(a0)
          assert(!PageProperty(check_rp[i]));
ffffffffc0202a8a:	8b89                	andi	a5,a5,2
ffffffffc0202a8c:	2a079563          	bnez	a5,ffffffffc0202d36 <swap_init+0x424>
ffffffffc0202a90:	09a1                	addi	s3,s3,8
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202a92:	ff5994e3          	bne	s3,s5,ffffffffc0202a7a <swap_init+0x168>
     }
     list_entry_t free_list_store = free_list;
ffffffffc0202a96:	601c                	ld	a5,0(s0)
ffffffffc0202a98:	00843983          	ld	s3,8(s0)
     assert(list_empty(&free_list));
     
     //assert(alloc_page() == NULL);
     
     unsigned int nr_free_store = nr_free;
     nr_free = 0;
ffffffffc0202a9c:	0000fd17          	auipc	s10,0xf
ffffffffc0202aa0:	a1cd0d13          	addi	s10,s10,-1508 # ffffffffc02114b8 <check_rp>
     list_entry_t free_list_store = free_list;
ffffffffc0202aa4:	f03e                	sd	a5,32(sp)
     unsigned int nr_free_store = nr_free;
ffffffffc0202aa6:	481c                	lw	a5,16(s0)
ffffffffc0202aa8:	f43e                	sd	a5,40(sp)
    elm->prev = elm->next = elm;
ffffffffc0202aaa:	0000f797          	auipc	a5,0xf
ffffffffc0202aae:	ac87bf23          	sd	s0,-1314(a5) # ffffffffc0211588 <free_area+0x8>
ffffffffc0202ab2:	0000f797          	auipc	a5,0xf
ffffffffc0202ab6:	ac87b723          	sd	s0,-1330(a5) # ffffffffc0211580 <free_area>
     nr_free = 0;
ffffffffc0202aba:	0000f797          	auipc	a5,0xf
ffffffffc0202abe:	ac07ab23          	sw	zero,-1322(a5) # ffffffffc0211590 <free_area+0x10>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
        free_pages(check_rp[i],1);
ffffffffc0202ac2:	000d3503          	ld	a0,0(s10)
ffffffffc0202ac6:	4585                	li	a1,1
ffffffffc0202ac8:	0d21                	addi	s10,s10,8
ffffffffc0202aca:	8aafe0ef          	jal	ra,ffffffffc0200b74 <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202ace:	ff5d1ae3          	bne	s10,s5,ffffffffc0202ac2 <swap_init+0x1b0>
     }
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0202ad2:	01042d83          	lw	s11,16(s0)
ffffffffc0202ad6:	4791                	li	a5,4
ffffffffc0202ad8:	38fd9b63          	bne	s11,a5,ffffffffc0202e6e <swap_init+0x55c>
     
     cprintf("set up init env for check_swap begin!\n");
ffffffffc0202adc:	00003517          	auipc	a0,0x3
ffffffffc0202ae0:	05c50513          	addi	a0,a0,92 # ffffffffc0205b38 <commands+0x1600>
ffffffffc0202ae4:	ddafd0ef          	jal	ra,ffffffffc02000be <cprintf>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0202ae8:	6c05                	lui	s8,0x1
     //setup initial vir_page<->phy_page environment for page relpacement algorithm 

     
     pgfault_num=0;
ffffffffc0202aea:	0000f797          	auipc	a5,0xf
ffffffffc0202aee:	9607ab23          	sw	zero,-1674(a5) # ffffffffc0211460 <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0202af2:	4ca9                	li	s9,10
ffffffffc0202af4:	019c0023          	sb	s9,0(s8) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
     cprintf("0x3a\n");
ffffffffc0202af8:	00003517          	auipc	a0,0x3
ffffffffc0202afc:	06850513          	addi	a0,a0,104 # ffffffffc0205b60 <commands+0x1628>
ffffffffc0202b00:	dbefd0ef          	jal	ra,ffffffffc02000be <cprintf>
     pgfault_num=0;
ffffffffc0202b04:	0000fd17          	auipc	s10,0xf
ffffffffc0202b08:	95cd0d13          	addi	s10,s10,-1700 # ffffffffc0211460 <pgfault_num>
     assert(pgfault_num==1);
ffffffffc0202b0c:	000d2783          	lw	a5,0(s10)
ffffffffc0202b10:	4605                	li	a2,1
ffffffffc0202b12:	2781                	sext.w	a5,a5
ffffffffc0202b14:	30c79d63          	bne	a5,a2,ffffffffc0202e2e <swap_init+0x51c>
     *(unsigned char *)0x1010 = 0x0a;
ffffffffc0202b18:	019c0823          	sb	s9,16(s8)
     assert(pgfault_num==1);
ffffffffc0202b1c:	000d2703          	lw	a4,0(s10)
ffffffffc0202b20:	2701                	sext.w	a4,a4
ffffffffc0202b22:	32f71663          	bne	a4,a5,ffffffffc0202e4e <swap_init+0x53c>
     *(unsigned char *)0x2000 = 0x0b;
ffffffffc0202b26:	6709                	lui	a4,0x2
ffffffffc0202b28:	46ad                	li	a3,11
ffffffffc0202b2a:	00d70023          	sb	a3,0(a4) # 2000 <BASE_ADDRESS-0xffffffffc01fe000>
     assert(pgfault_num==2);
ffffffffc0202b2e:	000d2783          	lw	a5,0(s10)
ffffffffc0202b32:	4609                	li	a2,2
ffffffffc0202b34:	2781                	sext.w	a5,a5
ffffffffc0202b36:	26c79c63          	bne	a5,a2,ffffffffc0202dae <swap_init+0x49c>
     *(unsigned char *)0x2010 = 0x0b;
ffffffffc0202b3a:	00d70823          	sb	a3,16(a4)
     assert(pgfault_num==2);
ffffffffc0202b3e:	000d2703          	lw	a4,0(s10)
ffffffffc0202b42:	2701                	sext.w	a4,a4
ffffffffc0202b44:	28f71563          	bne	a4,a5,ffffffffc0202dce <swap_init+0x4bc>
     *(unsigned char *)0x3000 = 0x0c;
ffffffffc0202b48:	670d                	lui	a4,0x3
ffffffffc0202b4a:	46b1                	li	a3,12
ffffffffc0202b4c:	00d70023          	sb	a3,0(a4) # 3000 <BASE_ADDRESS-0xffffffffc01fd000>
     assert(pgfault_num==3);
ffffffffc0202b50:	000d2783          	lw	a5,0(s10)
ffffffffc0202b54:	460d                	li	a2,3
ffffffffc0202b56:	2781                	sext.w	a5,a5
ffffffffc0202b58:	28c79b63          	bne	a5,a2,ffffffffc0202dee <swap_init+0x4dc>
     *(unsigned char *)0x3010 = 0x0c;
ffffffffc0202b5c:	00d70823          	sb	a3,16(a4)
     assert(pgfault_num==3);
ffffffffc0202b60:	000d2703          	lw	a4,0(s10)
ffffffffc0202b64:	2701                	sext.w	a4,a4
ffffffffc0202b66:	2af71463          	bne	a4,a5,ffffffffc0202e0e <swap_init+0x4fc>
     *(unsigned char *)0x4000 = 0x0d;
ffffffffc0202b6a:	6711                	lui	a4,0x4
ffffffffc0202b6c:	46b5                	li	a3,13
ffffffffc0202b6e:	00d70023          	sb	a3,0(a4) # 4000 <BASE_ADDRESS-0xffffffffc01fc000>
     assert(pgfault_num==4);
ffffffffc0202b72:	000d2783          	lw	a5,0(s10)
ffffffffc0202b76:	2781                	sext.w	a5,a5
ffffffffc0202b78:	33b79b63          	bne	a5,s11,ffffffffc0202eae <swap_init+0x59c>
     *(unsigned char *)0x4010 = 0x0d;
ffffffffc0202b7c:	00d70823          	sb	a3,16(a4)
     assert(pgfault_num==4);
ffffffffc0202b80:	000d2703          	lw	a4,0(s10)
ffffffffc0202b84:	2701                	sext.w	a4,a4
ffffffffc0202b86:	34f71463          	bne	a4,a5,ffffffffc0202ece <swap_init+0x5bc>
     //初始化内存空间
     check_content_set();
     
     assert( nr_free == 0);         
ffffffffc0202b8a:	481c                	lw	a5,16(s0)
ffffffffc0202b8c:	36079163          	bnez	a5,ffffffffc0202eee <swap_init+0x5dc>
ffffffffc0202b90:	0000f797          	auipc	a5,0xf
ffffffffc0202b94:	94878793          	addi	a5,a5,-1720 # ffffffffc02114d8 <swap_in_seq_no>
ffffffffc0202b98:	0000f717          	auipc	a4,0xf
ffffffffc0202b9c:	96870713          	addi	a4,a4,-1688 # ffffffffc0211500 <swap_out_seq_no>
ffffffffc0202ba0:	0000f617          	auipc	a2,0xf
ffffffffc0202ba4:	96060613          	addi	a2,a2,-1696 # ffffffffc0211500 <swap_out_seq_no>
     for(i = 0; i<MAX_SEQ_NO ; i++) 
         swap_out_seq_no[i]=swap_in_seq_no[i]=-1;
ffffffffc0202ba8:	56fd                	li	a3,-1
ffffffffc0202baa:	c394                	sw	a3,0(a5)
ffffffffc0202bac:	c314                	sw	a3,0(a4)
ffffffffc0202bae:	0791                	addi	a5,a5,4
ffffffffc0202bb0:	0711                	addi	a4,a4,4
     for(i = 0; i<MAX_SEQ_NO ; i++) 
ffffffffc0202bb2:	fec79ce3          	bne	a5,a2,ffffffffc0202baa <swap_init+0x298>
ffffffffc0202bb6:	0000f697          	auipc	a3,0xf
ffffffffc0202bba:	9aa68693          	addi	a3,a3,-1622 # ffffffffc0211560 <check_ptep>
ffffffffc0202bbe:	0000f817          	auipc	a6,0xf
ffffffffc0202bc2:	8fa80813          	addi	a6,a6,-1798 # ffffffffc02114b8 <check_rp>
ffffffffc0202bc6:	6c05                	lui	s8,0x1
    if (PPN(pa) >= npage) {
ffffffffc0202bc8:	0000fc97          	auipc	s9,0xf
ffffffffc0202bcc:	890c8c93          	addi	s9,s9,-1904 # ffffffffc0211458 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0202bd0:	0000fd97          	auipc	s11,0xf
ffffffffc0202bd4:	8c8d8d93          	addi	s11,s11,-1848 # ffffffffc0211498 <pages>
ffffffffc0202bd8:	00003d17          	auipc	s10,0x3
ffffffffc0202bdc:	760d0d13          	addi	s10,s10,1888 # ffffffffc0206338 <nbase>
     
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         check_ptep[i]=0;
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202be0:	6562                	ld	a0,24(sp)
         check_ptep[i]=0;
ffffffffc0202be2:	0006b023          	sd	zero,0(a3)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202be6:	4601                	li	a2,0
ffffffffc0202be8:	85e2                	mv	a1,s8
ffffffffc0202bea:	e842                	sd	a6,16(sp)
         check_ptep[i]=0;
ffffffffc0202bec:	e436                	sd	a3,8(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202bee:	80cfe0ef          	jal	ra,ffffffffc0200bfa <get_pte>
ffffffffc0202bf2:	66a2                	ld	a3,8(sp)
         //cprintf("i %d, check_ptep addr %x, value %x\n", i, check_ptep[i], *check_ptep[i]);
         assert(check_ptep[i] != NULL);
ffffffffc0202bf4:	6842                	ld	a6,16(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202bf6:	e288                	sd	a0,0(a3)
         assert(check_ptep[i] != NULL);
ffffffffc0202bf8:	16050f63          	beqz	a0,ffffffffc0202d76 <swap_init+0x464>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0202bfc:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0202bfe:	0017f613          	andi	a2,a5,1
ffffffffc0202c02:	10060263          	beqz	a2,ffffffffc0202d06 <swap_init+0x3f4>
    if (PPN(pa) >= npage) {
ffffffffc0202c06:	000cb603          	ld	a2,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202c0a:	078a                	slli	a5,a5,0x2
ffffffffc0202c0c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202c0e:	10c7f863          	bleu	a2,a5,ffffffffc0202d1e <swap_init+0x40c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c12:	000d3603          	ld	a2,0(s10)
ffffffffc0202c16:	000db583          	ld	a1,0(s11)
ffffffffc0202c1a:	00083503          	ld	a0,0(a6)
ffffffffc0202c1e:	8f91                	sub	a5,a5,a2
ffffffffc0202c20:	00379613          	slli	a2,a5,0x3
ffffffffc0202c24:	97b2                	add	a5,a5,a2
ffffffffc0202c26:	078e                	slli	a5,a5,0x3
ffffffffc0202c28:	97ae                	add	a5,a5,a1
ffffffffc0202c2a:	0af51e63          	bne	a0,a5,ffffffffc0202ce6 <swap_init+0x3d4>
ffffffffc0202c2e:	6785                	lui	a5,0x1
ffffffffc0202c30:	9c3e                	add	s8,s8,a5
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202c32:	6795                	lui	a5,0x5
ffffffffc0202c34:	06a1                	addi	a3,a3,8
ffffffffc0202c36:	0821                	addi	a6,a6,8
ffffffffc0202c38:	fafc14e3          	bne	s8,a5,ffffffffc0202be0 <swap_init+0x2ce>
         assert((*check_ptep[i] & PTE_V));  
         //cprintf("fuck \n%p\n",*check_ptep[i]);
         // 把这个修改为只读
          //*check_ptep[i] &= (~PTE_R);
     }
     cprintf("set up init env for check_swap over!\n");
ffffffffc0202c3c:	00003517          	auipc	a0,0x3
ffffffffc0202c40:	fac50513          	addi	a0,a0,-84 # ffffffffc0205be8 <commands+0x16b0>
ffffffffc0202c44:	c7afd0ef          	jal	ra,ffffffffc02000be <cprintf>
    int ret = sm->check_swap();
ffffffffc0202c48:	0000f797          	auipc	a5,0xf
ffffffffc0202c4c:	82078793          	addi	a5,a5,-2016 # ffffffffc0211468 <sm>
ffffffffc0202c50:	639c                	ld	a5,0(a5)
ffffffffc0202c52:	7f9c                	ld	a5,56(a5)
ffffffffc0202c54:	9782                	jalr	a5
     // now access the virt pages to test  page relpacement algorithm 
     // 这个应该是去检验初始化的页表
     ret=check_content_access();
     assert(ret==0);
ffffffffc0202c56:	2a051c63          	bnez	a0,ffffffffc0202f0e <swap_init+0x5fc>
     
     //restore kernel mem env
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         free_pages(check_rp[i],1);
ffffffffc0202c5a:	000a3503          	ld	a0,0(s4)
ffffffffc0202c5e:	4585                	li	a1,1
ffffffffc0202c60:	0a21                	addi	s4,s4,8
ffffffffc0202c62:	f13fd0ef          	jal	ra,ffffffffc0200b74 <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202c66:	ff5a1ae3          	bne	s4,s5,ffffffffc0202c5a <swap_init+0x348>
     } 

     //free_page(pte2page(*temp_ptep));
     
     mm_destroy(mm);
ffffffffc0202c6a:	855e                	mv	a0,s7
ffffffffc0202c6c:	dd0ff0ef          	jal	ra,ffffffffc020223c <mm_destroy>
         
     nr_free = nr_free_store;
ffffffffc0202c70:	77a2                	ld	a5,40(sp)
ffffffffc0202c72:	0000f717          	auipc	a4,0xf
ffffffffc0202c76:	90f72f23          	sw	a5,-1762(a4) # ffffffffc0211590 <free_area+0x10>
     free_list = free_list_store;
ffffffffc0202c7a:	7782                	ld	a5,32(sp)
ffffffffc0202c7c:	0000f717          	auipc	a4,0xf
ffffffffc0202c80:	90f73223          	sd	a5,-1788(a4) # ffffffffc0211580 <free_area>
ffffffffc0202c84:	0000f797          	auipc	a5,0xf
ffffffffc0202c88:	9137b223          	sd	s3,-1788(a5) # ffffffffc0211588 <free_area+0x8>

     
     le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202c8c:	00898a63          	beq	s3,s0,ffffffffc0202ca0 <swap_init+0x38e>
         struct Page *p = le2page(le, page_link);
         count --, total -= p->property;
ffffffffc0202c90:	ff89a783          	lw	a5,-8(s3)
    return listelm->next;
ffffffffc0202c94:	0089b983          	ld	s3,8(s3)
ffffffffc0202c98:	397d                	addiw	s2,s2,-1
ffffffffc0202c9a:	9c9d                	subw	s1,s1,a5
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202c9c:	fe899ae3          	bne	s3,s0,ffffffffc0202c90 <swap_init+0x37e>
     }
     cprintf("count is %d, total is %d\n",count,total);
ffffffffc0202ca0:	8626                	mv	a2,s1
ffffffffc0202ca2:	85ca                	mv	a1,s2
ffffffffc0202ca4:	00003517          	auipc	a0,0x3
ffffffffc0202ca8:	f7450513          	addi	a0,a0,-140 # ffffffffc0205c18 <commands+0x16e0>
ffffffffc0202cac:	c12fd0ef          	jal	ra,ffffffffc02000be <cprintf>
     //assert(count == 0);
     
     cprintf("check_swap() succeeded!\n");
ffffffffc0202cb0:	00003517          	auipc	a0,0x3
ffffffffc0202cb4:	f8850513          	addi	a0,a0,-120 # ffffffffc0205c38 <commands+0x1700>
ffffffffc0202cb8:	c06fd0ef          	jal	ra,ffffffffc02000be <cprintf>
ffffffffc0202cbc:	b15d                	j	ffffffffc0202962 <swap_init+0x50>
     int ret, count = 0, total = 0, i;
ffffffffc0202cbe:	4481                	li	s1,0
ffffffffc0202cc0:	4901                	li	s2,0
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202cc2:	4981                	li	s3,0
ffffffffc0202cc4:	bb29                	j	ffffffffc02029de <swap_init+0xcc>
        assert(PageProperty(p));
ffffffffc0202cc6:	00003697          	auipc	a3,0x3
ffffffffc0202cca:	d2a68693          	addi	a3,a3,-726 # ffffffffc02059f0 <commands+0x14b8>
ffffffffc0202cce:	00002617          	auipc	a2,0x2
ffffffffc0202cd2:	25a60613          	addi	a2,a2,602 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202cd6:	0bf00593          	li	a1,191
ffffffffc0202cda:	00003517          	auipc	a0,0x3
ffffffffc0202cde:	cee50513          	addi	a0,a0,-786 # ffffffffc02059c8 <commands+0x1490>
ffffffffc0202ce2:	c24fd0ef          	jal	ra,ffffffffc0200106 <__panic>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0202ce6:	00003697          	auipc	a3,0x3
ffffffffc0202cea:	eda68693          	addi	a3,a3,-294 # ffffffffc0205bc0 <commands+0x1688>
ffffffffc0202cee:	00002617          	auipc	a2,0x2
ffffffffc0202cf2:	23a60613          	addi	a2,a2,570 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202cf6:	10000593          	li	a1,256
ffffffffc0202cfa:	00003517          	auipc	a0,0x3
ffffffffc0202cfe:	cce50513          	addi	a0,a0,-818 # ffffffffc02059c8 <commands+0x1490>
ffffffffc0202d02:	c04fd0ef          	jal	ra,ffffffffc0200106 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0202d06:	00002617          	auipc	a2,0x2
ffffffffc0202d0a:	2fa60613          	addi	a2,a2,762 # ffffffffc0205000 <commands+0xac8>
ffffffffc0202d0e:	07000593          	li	a1,112
ffffffffc0202d12:	00002517          	auipc	a0,0x2
ffffffffc0202d16:	0fe50513          	addi	a0,a0,254 # ffffffffc0204e10 <commands+0x8d8>
ffffffffc0202d1a:	becfd0ef          	jal	ra,ffffffffc0200106 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0202d1e:	00002617          	auipc	a2,0x2
ffffffffc0202d22:	0d260613          	addi	a2,a2,210 # ffffffffc0204df0 <commands+0x8b8>
ffffffffc0202d26:	06500593          	li	a1,101
ffffffffc0202d2a:	00002517          	auipc	a0,0x2
ffffffffc0202d2e:	0e650513          	addi	a0,a0,230 # ffffffffc0204e10 <commands+0x8d8>
ffffffffc0202d32:	bd4fd0ef          	jal	ra,ffffffffc0200106 <__panic>
          assert(!PageProperty(check_rp[i]));
ffffffffc0202d36:	00003697          	auipc	a3,0x3
ffffffffc0202d3a:	dba68693          	addi	a3,a3,-582 # ffffffffc0205af0 <commands+0x15b8>
ffffffffc0202d3e:	00002617          	auipc	a2,0x2
ffffffffc0202d42:	1ea60613          	addi	a2,a2,490 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202d46:	0e000593          	li	a1,224
ffffffffc0202d4a:	00003517          	auipc	a0,0x3
ffffffffc0202d4e:	c7e50513          	addi	a0,a0,-898 # ffffffffc02059c8 <commands+0x1490>
ffffffffc0202d52:	bb4fd0ef          	jal	ra,ffffffffc0200106 <__panic>
          assert(check_rp[i] != NULL );
ffffffffc0202d56:	00003697          	auipc	a3,0x3
ffffffffc0202d5a:	d8268693          	addi	a3,a3,-638 # ffffffffc0205ad8 <commands+0x15a0>
ffffffffc0202d5e:	00002617          	auipc	a2,0x2
ffffffffc0202d62:	1ca60613          	addi	a2,a2,458 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202d66:	0df00593          	li	a1,223
ffffffffc0202d6a:	00003517          	auipc	a0,0x3
ffffffffc0202d6e:	c5e50513          	addi	a0,a0,-930 # ffffffffc02059c8 <commands+0x1490>
ffffffffc0202d72:	b94fd0ef          	jal	ra,ffffffffc0200106 <__panic>
         assert(check_ptep[i] != NULL);
ffffffffc0202d76:	00003697          	auipc	a3,0x3
ffffffffc0202d7a:	e3268693          	addi	a3,a3,-462 # ffffffffc0205ba8 <commands+0x1670>
ffffffffc0202d7e:	00002617          	auipc	a2,0x2
ffffffffc0202d82:	1aa60613          	addi	a2,a2,426 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202d86:	0ff00593          	li	a1,255
ffffffffc0202d8a:	00003517          	auipc	a0,0x3
ffffffffc0202d8e:	c3e50513          	addi	a0,a0,-962 # ffffffffc02059c8 <commands+0x1490>
ffffffffc0202d92:	b74fd0ef          	jal	ra,ffffffffc0200106 <__panic>
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
ffffffffc0202d96:	00003617          	auipc	a2,0x3
ffffffffc0202d9a:	c1260613          	addi	a2,a2,-1006 # ffffffffc02059a8 <commands+0x1470>
ffffffffc0202d9e:	02800593          	li	a1,40
ffffffffc0202da2:	00003517          	auipc	a0,0x3
ffffffffc0202da6:	c2650513          	addi	a0,a0,-986 # ffffffffc02059c8 <commands+0x1490>
ffffffffc0202daa:	b5cfd0ef          	jal	ra,ffffffffc0200106 <__panic>
     assert(pgfault_num==2);
ffffffffc0202dae:	00003697          	auipc	a3,0x3
ffffffffc0202db2:	dca68693          	addi	a3,a3,-566 # ffffffffc0205b78 <commands+0x1640>
ffffffffc0202db6:	00002617          	auipc	a2,0x2
ffffffffc0202dba:	17260613          	addi	a2,a2,370 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202dbe:	09900593          	li	a1,153
ffffffffc0202dc2:	00003517          	auipc	a0,0x3
ffffffffc0202dc6:	c0650513          	addi	a0,a0,-1018 # ffffffffc02059c8 <commands+0x1490>
ffffffffc0202dca:	b3cfd0ef          	jal	ra,ffffffffc0200106 <__panic>
     assert(pgfault_num==2);
ffffffffc0202dce:	00003697          	auipc	a3,0x3
ffffffffc0202dd2:	daa68693          	addi	a3,a3,-598 # ffffffffc0205b78 <commands+0x1640>
ffffffffc0202dd6:	00002617          	auipc	a2,0x2
ffffffffc0202dda:	15260613          	addi	a2,a2,338 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202dde:	09b00593          	li	a1,155
ffffffffc0202de2:	00003517          	auipc	a0,0x3
ffffffffc0202de6:	be650513          	addi	a0,a0,-1050 # ffffffffc02059c8 <commands+0x1490>
ffffffffc0202dea:	b1cfd0ef          	jal	ra,ffffffffc0200106 <__panic>
     assert(pgfault_num==3);
ffffffffc0202dee:	00003697          	auipc	a3,0x3
ffffffffc0202df2:	d9a68693          	addi	a3,a3,-614 # ffffffffc0205b88 <commands+0x1650>
ffffffffc0202df6:	00002617          	auipc	a2,0x2
ffffffffc0202dfa:	13260613          	addi	a2,a2,306 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202dfe:	09d00593          	li	a1,157
ffffffffc0202e02:	00003517          	auipc	a0,0x3
ffffffffc0202e06:	bc650513          	addi	a0,a0,-1082 # ffffffffc02059c8 <commands+0x1490>
ffffffffc0202e0a:	afcfd0ef          	jal	ra,ffffffffc0200106 <__panic>
     assert(pgfault_num==3);
ffffffffc0202e0e:	00003697          	auipc	a3,0x3
ffffffffc0202e12:	d7a68693          	addi	a3,a3,-646 # ffffffffc0205b88 <commands+0x1650>
ffffffffc0202e16:	00002617          	auipc	a2,0x2
ffffffffc0202e1a:	11260613          	addi	a2,a2,274 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202e1e:	09f00593          	li	a1,159
ffffffffc0202e22:	00003517          	auipc	a0,0x3
ffffffffc0202e26:	ba650513          	addi	a0,a0,-1114 # ffffffffc02059c8 <commands+0x1490>
ffffffffc0202e2a:	adcfd0ef          	jal	ra,ffffffffc0200106 <__panic>
     assert(pgfault_num==1);
ffffffffc0202e2e:	00003697          	auipc	a3,0x3
ffffffffc0202e32:	d3a68693          	addi	a3,a3,-710 # ffffffffc0205b68 <commands+0x1630>
ffffffffc0202e36:	00002617          	auipc	a2,0x2
ffffffffc0202e3a:	0f260613          	addi	a2,a2,242 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202e3e:	09500593          	li	a1,149
ffffffffc0202e42:	00003517          	auipc	a0,0x3
ffffffffc0202e46:	b8650513          	addi	a0,a0,-1146 # ffffffffc02059c8 <commands+0x1490>
ffffffffc0202e4a:	abcfd0ef          	jal	ra,ffffffffc0200106 <__panic>
     assert(pgfault_num==1);
ffffffffc0202e4e:	00003697          	auipc	a3,0x3
ffffffffc0202e52:	d1a68693          	addi	a3,a3,-742 # ffffffffc0205b68 <commands+0x1630>
ffffffffc0202e56:	00002617          	auipc	a2,0x2
ffffffffc0202e5a:	0d260613          	addi	a2,a2,210 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202e5e:	09700593          	li	a1,151
ffffffffc0202e62:	00003517          	auipc	a0,0x3
ffffffffc0202e66:	b6650513          	addi	a0,a0,-1178 # ffffffffc02059c8 <commands+0x1490>
ffffffffc0202e6a:	a9cfd0ef          	jal	ra,ffffffffc0200106 <__panic>
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0202e6e:	00003697          	auipc	a3,0x3
ffffffffc0202e72:	ca268693          	addi	a3,a3,-862 # ffffffffc0205b10 <commands+0x15d8>
ffffffffc0202e76:	00002617          	auipc	a2,0x2
ffffffffc0202e7a:	0b260613          	addi	a2,a2,178 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202e7e:	0ed00593          	li	a1,237
ffffffffc0202e82:	00003517          	auipc	a0,0x3
ffffffffc0202e86:	b4650513          	addi	a0,a0,-1210 # ffffffffc02059c8 <commands+0x1490>
ffffffffc0202e8a:	a7cfd0ef          	jal	ra,ffffffffc0200106 <__panic>
     assert(temp_ptep!= NULL);
ffffffffc0202e8e:	00003697          	auipc	a3,0x3
ffffffffc0202e92:	c0a68693          	addi	a3,a3,-1014 # ffffffffc0205a98 <commands+0x1560>
ffffffffc0202e96:	00002617          	auipc	a2,0x2
ffffffffc0202e9a:	09260613          	addi	a2,a2,146 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202e9e:	0da00593          	li	a1,218
ffffffffc0202ea2:	00003517          	auipc	a0,0x3
ffffffffc0202ea6:	b2650513          	addi	a0,a0,-1242 # ffffffffc02059c8 <commands+0x1490>
ffffffffc0202eaa:	a5cfd0ef          	jal	ra,ffffffffc0200106 <__panic>
     assert(pgfault_num==4);
ffffffffc0202eae:	00002697          	auipc	a3,0x2
ffffffffc0202eb2:	55a68693          	addi	a3,a3,1370 # ffffffffc0205408 <commands+0xed0>
ffffffffc0202eb6:	00002617          	auipc	a2,0x2
ffffffffc0202eba:	07260613          	addi	a2,a2,114 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202ebe:	0a100593          	li	a1,161
ffffffffc0202ec2:	00003517          	auipc	a0,0x3
ffffffffc0202ec6:	b0650513          	addi	a0,a0,-1274 # ffffffffc02059c8 <commands+0x1490>
ffffffffc0202eca:	a3cfd0ef          	jal	ra,ffffffffc0200106 <__panic>
     assert(pgfault_num==4);
ffffffffc0202ece:	00002697          	auipc	a3,0x2
ffffffffc0202ed2:	53a68693          	addi	a3,a3,1338 # ffffffffc0205408 <commands+0xed0>
ffffffffc0202ed6:	00002617          	auipc	a2,0x2
ffffffffc0202eda:	05260613          	addi	a2,a2,82 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202ede:	0a300593          	li	a1,163
ffffffffc0202ee2:	00003517          	auipc	a0,0x3
ffffffffc0202ee6:	ae650513          	addi	a0,a0,-1306 # ffffffffc02059c8 <commands+0x1490>
ffffffffc0202eea:	a1cfd0ef          	jal	ra,ffffffffc0200106 <__panic>
     assert( nr_free == 0);         
ffffffffc0202eee:	00003697          	auipc	a3,0x3
ffffffffc0202ef2:	caa68693          	addi	a3,a3,-854 # ffffffffc0205b98 <commands+0x1660>
ffffffffc0202ef6:	00002617          	auipc	a2,0x2
ffffffffc0202efa:	03260613          	addi	a2,a2,50 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202efe:	0f700593          	li	a1,247
ffffffffc0202f02:	00003517          	auipc	a0,0x3
ffffffffc0202f06:	ac650513          	addi	a0,a0,-1338 # ffffffffc02059c8 <commands+0x1490>
ffffffffc0202f0a:	9fcfd0ef          	jal	ra,ffffffffc0200106 <__panic>
     assert(ret==0);
ffffffffc0202f0e:	00003697          	auipc	a3,0x3
ffffffffc0202f12:	d0268693          	addi	a3,a3,-766 # ffffffffc0205c10 <commands+0x16d8>
ffffffffc0202f16:	00002617          	auipc	a2,0x2
ffffffffc0202f1a:	01260613          	addi	a2,a2,18 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202f1e:	10a00593          	li	a1,266
ffffffffc0202f22:	00003517          	auipc	a0,0x3
ffffffffc0202f26:	aa650513          	addi	a0,a0,-1370 # ffffffffc02059c8 <commands+0x1490>
ffffffffc0202f2a:	9dcfd0ef          	jal	ra,ffffffffc0200106 <__panic>
     assert(mm != NULL);
ffffffffc0202f2e:	00002697          	auipc	a3,0x2
ffffffffc0202f32:	7f268693          	addi	a3,a3,2034 # ffffffffc0205720 <commands+0x11e8>
ffffffffc0202f36:	00002617          	auipc	a2,0x2
ffffffffc0202f3a:	ff260613          	addi	a2,a2,-14 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202f3e:	0c700593          	li	a1,199
ffffffffc0202f42:	00003517          	auipc	a0,0x3
ffffffffc0202f46:	a8650513          	addi	a0,a0,-1402 # ffffffffc02059c8 <commands+0x1490>
ffffffffc0202f4a:	9bcfd0ef          	jal	ra,ffffffffc0200106 <__panic>
     assert(check_mm_struct == NULL);
ffffffffc0202f4e:	00003697          	auipc	a3,0x3
ffffffffc0202f52:	afa68693          	addi	a3,a3,-1286 # ffffffffc0205a48 <commands+0x1510>
ffffffffc0202f56:	00002617          	auipc	a2,0x2
ffffffffc0202f5a:	fd260613          	addi	a2,a2,-46 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202f5e:	0ca00593          	li	a1,202
ffffffffc0202f62:	00003517          	auipc	a0,0x3
ffffffffc0202f66:	a6650513          	addi	a0,a0,-1434 # ffffffffc02059c8 <commands+0x1490>
ffffffffc0202f6a:	99cfd0ef          	jal	ra,ffffffffc0200106 <__panic>
     assert(pgdir[0] == 0);
ffffffffc0202f6e:	00003697          	auipc	a3,0x3
ffffffffc0202f72:	96268693          	addi	a3,a3,-1694 # ffffffffc02058d0 <commands+0x1398>
ffffffffc0202f76:	00002617          	auipc	a2,0x2
ffffffffc0202f7a:	fb260613          	addi	a2,a2,-78 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202f7e:	0cf00593          	li	a1,207
ffffffffc0202f82:	00003517          	auipc	a0,0x3
ffffffffc0202f86:	a4650513          	addi	a0,a0,-1466 # ffffffffc02059c8 <commands+0x1490>
ffffffffc0202f8a:	97cfd0ef          	jal	ra,ffffffffc0200106 <__panic>
     assert(vma != NULL);
ffffffffc0202f8e:	00003697          	auipc	a3,0x3
ffffffffc0202f92:	9ba68693          	addi	a3,a3,-1606 # ffffffffc0205948 <commands+0x1410>
ffffffffc0202f96:	00002617          	auipc	a2,0x2
ffffffffc0202f9a:	f9260613          	addi	a2,a2,-110 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202f9e:	0d200593          	li	a1,210
ffffffffc0202fa2:	00003517          	auipc	a0,0x3
ffffffffc0202fa6:	a2650513          	addi	a0,a0,-1498 # ffffffffc02059c8 <commands+0x1490>
ffffffffc0202faa:	95cfd0ef          	jal	ra,ffffffffc0200106 <__panic>
     assert(total == nr_free_pages());
ffffffffc0202fae:	00003697          	auipc	a3,0x3
ffffffffc0202fb2:	a5268693          	addi	a3,a3,-1454 # ffffffffc0205a00 <commands+0x14c8>
ffffffffc0202fb6:	00002617          	auipc	a2,0x2
ffffffffc0202fba:	f7260613          	addi	a2,a2,-142 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0202fbe:	0c200593          	li	a1,194
ffffffffc0202fc2:	00003517          	auipc	a0,0x3
ffffffffc0202fc6:	a0650513          	addi	a0,a0,-1530 # ffffffffc02059c8 <commands+0x1490>
ffffffffc0202fca:	93cfd0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc0202fce <swap_init_mm>:
     return sm->init_mm(mm);
ffffffffc0202fce:	0000e797          	auipc	a5,0xe
ffffffffc0202fd2:	49a78793          	addi	a5,a5,1178 # ffffffffc0211468 <sm>
ffffffffc0202fd6:	639c                	ld	a5,0(a5)
ffffffffc0202fd8:	0107b303          	ld	t1,16(a5)
ffffffffc0202fdc:	8302                	jr	t1

ffffffffc0202fde <swap_map_swappable>:
     return sm->map_swappable(mm, addr, page, swap_in);
ffffffffc0202fde:	0000e797          	auipc	a5,0xe
ffffffffc0202fe2:	48a78793          	addi	a5,a5,1162 # ffffffffc0211468 <sm>
ffffffffc0202fe6:	639c                	ld	a5,0(a5)
ffffffffc0202fe8:	0207b303          	ld	t1,32(a5)
ffffffffc0202fec:	8302                	jr	t1

ffffffffc0202fee <swap_out>:
{
ffffffffc0202fee:	711d                	addi	sp,sp,-96
ffffffffc0202ff0:	ec86                	sd	ra,88(sp)
ffffffffc0202ff2:	e8a2                	sd	s0,80(sp)
ffffffffc0202ff4:	e4a6                	sd	s1,72(sp)
ffffffffc0202ff6:	e0ca                	sd	s2,64(sp)
ffffffffc0202ff8:	fc4e                	sd	s3,56(sp)
ffffffffc0202ffa:	f852                	sd	s4,48(sp)
ffffffffc0202ffc:	f456                	sd	s5,40(sp)
ffffffffc0202ffe:	f05a                	sd	s6,32(sp)
ffffffffc0203000:	ec5e                	sd	s7,24(sp)
ffffffffc0203002:	e862                	sd	s8,16(sp)
     for (i = 0; i != n; ++ i)
ffffffffc0203004:	cde9                	beqz	a1,ffffffffc02030de <swap_out+0xf0>
ffffffffc0203006:	8ab2                	mv	s5,a2
ffffffffc0203008:	892a                	mv	s2,a0
ffffffffc020300a:	8a2e                	mv	s4,a1
ffffffffc020300c:	4401                	li	s0,0
ffffffffc020300e:	0000e997          	auipc	s3,0xe
ffffffffc0203012:	45a98993          	addi	s3,s3,1114 # ffffffffc0211468 <sm>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203016:	00003b17          	auipc	s6,0x3
ffffffffc020301a:	ca2b0b13          	addi	s6,s6,-862 # ffffffffc0205cb8 <commands+0x1780>
                    cprintf("SWAP: failed to save\n");
ffffffffc020301e:	00003b97          	auipc	s7,0x3
ffffffffc0203022:	c82b8b93          	addi	s7,s7,-894 # ffffffffc0205ca0 <commands+0x1768>
ffffffffc0203026:	a825                	j	ffffffffc020305e <swap_out+0x70>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203028:	67a2                	ld	a5,8(sp)
ffffffffc020302a:	8626                	mv	a2,s1
ffffffffc020302c:	85a2                	mv	a1,s0
ffffffffc020302e:	63b4                	ld	a3,64(a5)
ffffffffc0203030:	855a                	mv	a0,s6
     for (i = 0; i != n; ++ i)
ffffffffc0203032:	2405                	addiw	s0,s0,1
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203034:	82b1                	srli	a3,a3,0xc
ffffffffc0203036:	0685                	addi	a3,a3,1
ffffffffc0203038:	886fd0ef          	jal	ra,ffffffffc02000be <cprintf>
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc020303c:	6522                	ld	a0,8(sp)
                    free_page(page);
ffffffffc020303e:	4585                	li	a1,1
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc0203040:	613c                	ld	a5,64(a0)
ffffffffc0203042:	83b1                	srli	a5,a5,0xc
ffffffffc0203044:	0785                	addi	a5,a5,1
ffffffffc0203046:	07a2                	slli	a5,a5,0x8
ffffffffc0203048:	00fc3023          	sd	a5,0(s8) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
                    free_page(page);
ffffffffc020304c:	b29fd0ef          	jal	ra,ffffffffc0200b74 <free_pages>
          tlb_invalidate(mm->pgdir, v);
ffffffffc0203050:	01893503          	ld	a0,24(s2)
ffffffffc0203054:	85a6                	mv	a1,s1
ffffffffc0203056:	a2bfe0ef          	jal	ra,ffffffffc0201a80 <tlb_invalidate>
     for (i = 0; i != n; ++ i)
ffffffffc020305a:	048a0d63          	beq	s4,s0,ffffffffc02030b4 <swap_out+0xc6>
          int r = sm->swap_out_victim(mm, &page, in_tick);
ffffffffc020305e:	0009b783          	ld	a5,0(s3)
ffffffffc0203062:	8656                	mv	a2,s5
ffffffffc0203064:	002c                	addi	a1,sp,8
ffffffffc0203066:	7b9c                	ld	a5,48(a5)
ffffffffc0203068:	854a                	mv	a0,s2
ffffffffc020306a:	9782                	jalr	a5
          if (r != 0) {
ffffffffc020306c:	e12d                	bnez	a0,ffffffffc02030ce <swap_out+0xe0>
          v=page->pra_vaddr; 
ffffffffc020306e:	67a2                	ld	a5,8(sp)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203070:	01893503          	ld	a0,24(s2)
ffffffffc0203074:	4601                	li	a2,0
          v=page->pra_vaddr; 
ffffffffc0203076:	63a4                	ld	s1,64(a5)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203078:	85a6                	mv	a1,s1
ffffffffc020307a:	b81fd0ef          	jal	ra,ffffffffc0200bfa <get_pte>
          assert((*ptep & PTE_V) != 0);
ffffffffc020307e:	611c                	ld	a5,0(a0)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203080:	8c2a                	mv	s8,a0
          assert((*ptep & PTE_V) != 0);
ffffffffc0203082:	8b85                	andi	a5,a5,1
ffffffffc0203084:	cfb9                	beqz	a5,ffffffffc02030e2 <swap_out+0xf4>
          if (swapfs_write( (page->pra_vaddr/PGSIZE+1)<<8, page) != 0) {
ffffffffc0203086:	65a2                	ld	a1,8(sp)
ffffffffc0203088:	61bc                	ld	a5,64(a1)
ffffffffc020308a:	83b1                	srli	a5,a5,0xc
ffffffffc020308c:	00178513          	addi	a0,a5,1
ffffffffc0203090:	0522                	slli	a0,a0,0x8
ffffffffc0203092:	53b000ef          	jal	ra,ffffffffc0203dcc <swapfs_write>
ffffffffc0203096:	d949                	beqz	a0,ffffffffc0203028 <swap_out+0x3a>
                    cprintf("SWAP: failed to save\n");
ffffffffc0203098:	855e                	mv	a0,s7
ffffffffc020309a:	824fd0ef          	jal	ra,ffffffffc02000be <cprintf>
                    sm->map_swappable(mm, v, page, 0);
ffffffffc020309e:	0009b783          	ld	a5,0(s3)
ffffffffc02030a2:	6622                	ld	a2,8(sp)
ffffffffc02030a4:	4681                	li	a3,0
ffffffffc02030a6:	739c                	ld	a5,32(a5)
ffffffffc02030a8:	85a6                	mv	a1,s1
ffffffffc02030aa:	854a                	mv	a0,s2
     for (i = 0; i != n; ++ i)
ffffffffc02030ac:	2405                	addiw	s0,s0,1
                    sm->map_swappable(mm, v, page, 0);
ffffffffc02030ae:	9782                	jalr	a5
     for (i = 0; i != n; ++ i)
ffffffffc02030b0:	fa8a17e3          	bne	s4,s0,ffffffffc020305e <swap_out+0x70>
}
ffffffffc02030b4:	8522                	mv	a0,s0
ffffffffc02030b6:	60e6                	ld	ra,88(sp)
ffffffffc02030b8:	6446                	ld	s0,80(sp)
ffffffffc02030ba:	64a6                	ld	s1,72(sp)
ffffffffc02030bc:	6906                	ld	s2,64(sp)
ffffffffc02030be:	79e2                	ld	s3,56(sp)
ffffffffc02030c0:	7a42                	ld	s4,48(sp)
ffffffffc02030c2:	7aa2                	ld	s5,40(sp)
ffffffffc02030c4:	7b02                	ld	s6,32(sp)
ffffffffc02030c6:	6be2                	ld	s7,24(sp)
ffffffffc02030c8:	6c42                	ld	s8,16(sp)
ffffffffc02030ca:	6125                	addi	sp,sp,96
ffffffffc02030cc:	8082                	ret
                    cprintf("i %d, swap_out: call swap_out_victim failed\n",i);
ffffffffc02030ce:	85a2                	mv	a1,s0
ffffffffc02030d0:	00003517          	auipc	a0,0x3
ffffffffc02030d4:	b8850513          	addi	a0,a0,-1144 # ffffffffc0205c58 <commands+0x1720>
ffffffffc02030d8:	fe7fc0ef          	jal	ra,ffffffffc02000be <cprintf>
                  break;
ffffffffc02030dc:	bfe1                	j	ffffffffc02030b4 <swap_out+0xc6>
     for (i = 0; i != n; ++ i)
ffffffffc02030de:	4401                	li	s0,0
ffffffffc02030e0:	bfd1                	j	ffffffffc02030b4 <swap_out+0xc6>
          assert((*ptep & PTE_V) != 0);
ffffffffc02030e2:	00003697          	auipc	a3,0x3
ffffffffc02030e6:	ba668693          	addi	a3,a3,-1114 # ffffffffc0205c88 <commands+0x1750>
ffffffffc02030ea:	00002617          	auipc	a2,0x2
ffffffffc02030ee:	e3e60613          	addi	a2,a2,-450 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02030f2:	06900593          	li	a1,105
ffffffffc02030f6:	00003517          	auipc	a0,0x3
ffffffffc02030fa:	8d250513          	addi	a0,a0,-1838 # ffffffffc02059c8 <commands+0x1490>
ffffffffc02030fe:	808fd0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc0203102 <swap_in>:
{
ffffffffc0203102:	7179                	addi	sp,sp,-48
ffffffffc0203104:	e84a                	sd	s2,16(sp)
ffffffffc0203106:	892a                	mv	s2,a0
     struct Page *result = alloc_page();
ffffffffc0203108:	4505                	li	a0,1
{
ffffffffc020310a:	ec26                	sd	s1,24(sp)
ffffffffc020310c:	e44e                	sd	s3,8(sp)
ffffffffc020310e:	f406                	sd	ra,40(sp)
ffffffffc0203110:	f022                	sd	s0,32(sp)
ffffffffc0203112:	84ae                	mv	s1,a1
ffffffffc0203114:	89b2                	mv	s3,a2
     struct Page *result = alloc_page();
ffffffffc0203116:	9d7fd0ef          	jal	ra,ffffffffc0200aec <alloc_pages>
     assert(result!=NULL);
ffffffffc020311a:	c129                	beqz	a0,ffffffffc020315c <swap_in+0x5a>
     pte_t *ptep = get_pte(mm->pgdir, addr, 0);
ffffffffc020311c:	842a                	mv	s0,a0
ffffffffc020311e:	01893503          	ld	a0,24(s2)
ffffffffc0203122:	4601                	li	a2,0
ffffffffc0203124:	85a6                	mv	a1,s1
ffffffffc0203126:	ad5fd0ef          	jal	ra,ffffffffc0200bfa <get_pte>
ffffffffc020312a:	892a                	mv	s2,a0
     if ((r = swapfs_read((*ptep), result)) != 0)
ffffffffc020312c:	6108                	ld	a0,0(a0)
ffffffffc020312e:	85a2                	mv	a1,s0
ffffffffc0203130:	3f7000ef          	jal	ra,ffffffffc0203d26 <swapfs_read>
     cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep)>>8, addr);
ffffffffc0203134:	00093583          	ld	a1,0(s2)
ffffffffc0203138:	8626                	mv	a2,s1
ffffffffc020313a:	00003517          	auipc	a0,0x3
ffffffffc020313e:	82e50513          	addi	a0,a0,-2002 # ffffffffc0205968 <commands+0x1430>
ffffffffc0203142:	81a1                	srli	a1,a1,0x8
ffffffffc0203144:	f7bfc0ef          	jal	ra,ffffffffc02000be <cprintf>
}
ffffffffc0203148:	70a2                	ld	ra,40(sp)
     *ptr_result=result;
ffffffffc020314a:	0089b023          	sd	s0,0(s3)
}
ffffffffc020314e:	7402                	ld	s0,32(sp)
ffffffffc0203150:	64e2                	ld	s1,24(sp)
ffffffffc0203152:	6942                	ld	s2,16(sp)
ffffffffc0203154:	69a2                	ld	s3,8(sp)
ffffffffc0203156:	4501                	li	a0,0
ffffffffc0203158:	6145                	addi	sp,sp,48
ffffffffc020315a:	8082                	ret
     assert(result!=NULL);
ffffffffc020315c:	00002697          	auipc	a3,0x2
ffffffffc0203160:	7fc68693          	addi	a3,a3,2044 # ffffffffc0205958 <commands+0x1420>
ffffffffc0203164:	00002617          	auipc	a2,0x2
ffffffffc0203168:	dc460613          	addi	a2,a2,-572 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc020316c:	07f00593          	li	a1,127
ffffffffc0203170:	00003517          	auipc	a0,0x3
ffffffffc0203174:	85850513          	addi	a0,a0,-1960 # ffffffffc02059c8 <commands+0x1490>
ffffffffc0203178:	f8ffc0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc020317c <default_init>:
    elm->prev = elm->next = elm;
ffffffffc020317c:	0000e797          	auipc	a5,0xe
ffffffffc0203180:	40478793          	addi	a5,a5,1028 # ffffffffc0211580 <free_area>
ffffffffc0203184:	e79c                	sd	a5,8(a5)
ffffffffc0203186:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0203188:	0007a823          	sw	zero,16(a5)
}
ffffffffc020318c:	8082                	ret

ffffffffc020318e <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc020318e:	0000e517          	auipc	a0,0xe
ffffffffc0203192:	40256503          	lwu	a0,1026(a0) # ffffffffc0211590 <free_area+0x10>
ffffffffc0203196:	8082                	ret

ffffffffc0203198 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0203198:	715d                	addi	sp,sp,-80
ffffffffc020319a:	f84a                	sd	s2,48(sp)
    return listelm->next;
ffffffffc020319c:	0000e917          	auipc	s2,0xe
ffffffffc02031a0:	3e490913          	addi	s2,s2,996 # ffffffffc0211580 <free_area>
ffffffffc02031a4:	00893783          	ld	a5,8(s2)
ffffffffc02031a8:	e486                	sd	ra,72(sp)
ffffffffc02031aa:	e0a2                	sd	s0,64(sp)
ffffffffc02031ac:	fc26                	sd	s1,56(sp)
ffffffffc02031ae:	f44e                	sd	s3,40(sp)
ffffffffc02031b0:	f052                	sd	s4,32(sp)
ffffffffc02031b2:	ec56                	sd	s5,24(sp)
ffffffffc02031b4:	e85a                	sd	s6,16(sp)
ffffffffc02031b6:	e45e                	sd	s7,8(sp)
ffffffffc02031b8:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02031ba:	31278f63          	beq	a5,s2,ffffffffc02034d8 <default_check+0x340>
ffffffffc02031be:	fe87b703          	ld	a4,-24(a5)
ffffffffc02031c2:	8305                	srli	a4,a4,0x1
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc02031c4:	8b05                	andi	a4,a4,1
ffffffffc02031c6:	30070d63          	beqz	a4,ffffffffc02034e0 <default_check+0x348>
    int count = 0, total = 0;
ffffffffc02031ca:	4401                	li	s0,0
ffffffffc02031cc:	4481                	li	s1,0
ffffffffc02031ce:	a031                	j	ffffffffc02031da <default_check+0x42>
ffffffffc02031d0:	fe87b703          	ld	a4,-24(a5)
        assert(PageProperty(p));
ffffffffc02031d4:	8b09                	andi	a4,a4,2
ffffffffc02031d6:	30070563          	beqz	a4,ffffffffc02034e0 <default_check+0x348>
        count ++, total += p->property;
ffffffffc02031da:	ff87a703          	lw	a4,-8(a5)
ffffffffc02031de:	679c                	ld	a5,8(a5)
ffffffffc02031e0:	2485                	addiw	s1,s1,1
ffffffffc02031e2:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02031e4:	ff2796e3          	bne	a5,s2,ffffffffc02031d0 <default_check+0x38>
ffffffffc02031e8:	89a2                	mv	s3,s0
    }
    assert(total == nr_free_pages());
ffffffffc02031ea:	9d1fd0ef          	jal	ra,ffffffffc0200bba <nr_free_pages>
ffffffffc02031ee:	75351963          	bne	a0,s3,ffffffffc0203940 <default_check+0x7a8>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02031f2:	4505                	li	a0,1
ffffffffc02031f4:	8f9fd0ef          	jal	ra,ffffffffc0200aec <alloc_pages>
ffffffffc02031f8:	8a2a                	mv	s4,a0
ffffffffc02031fa:	48050363          	beqz	a0,ffffffffc0203680 <default_check+0x4e8>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02031fe:	4505                	li	a0,1
ffffffffc0203200:	8edfd0ef          	jal	ra,ffffffffc0200aec <alloc_pages>
ffffffffc0203204:	89aa                	mv	s3,a0
ffffffffc0203206:	74050d63          	beqz	a0,ffffffffc0203960 <default_check+0x7c8>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020320a:	4505                	li	a0,1
ffffffffc020320c:	8e1fd0ef          	jal	ra,ffffffffc0200aec <alloc_pages>
ffffffffc0203210:	8aaa                	mv	s5,a0
ffffffffc0203212:	4e050763          	beqz	a0,ffffffffc0203700 <default_check+0x568>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0203216:	2f3a0563          	beq	s4,s3,ffffffffc0203500 <default_check+0x368>
ffffffffc020321a:	2eaa0363          	beq	s4,a0,ffffffffc0203500 <default_check+0x368>
ffffffffc020321e:	2ea98163          	beq	s3,a0,ffffffffc0203500 <default_check+0x368>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0203222:	000a2783          	lw	a5,0(s4)
ffffffffc0203226:	2e079d63          	bnez	a5,ffffffffc0203520 <default_check+0x388>
ffffffffc020322a:	0009a783          	lw	a5,0(s3)
ffffffffc020322e:	2e079963          	bnez	a5,ffffffffc0203520 <default_check+0x388>
ffffffffc0203232:	411c                	lw	a5,0(a0)
ffffffffc0203234:	2e079663          	bnez	a5,ffffffffc0203520 <default_check+0x388>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203238:	0000e797          	auipc	a5,0xe
ffffffffc020323c:	26078793          	addi	a5,a5,608 # ffffffffc0211498 <pages>
ffffffffc0203240:	639c                	ld	a5,0(a5)
ffffffffc0203242:	00002717          	auipc	a4,0x2
ffffffffc0203246:	b2e70713          	addi	a4,a4,-1234 # ffffffffc0204d70 <commands+0x838>
ffffffffc020324a:	630c                	ld	a1,0(a4)
ffffffffc020324c:	40fa0733          	sub	a4,s4,a5
ffffffffc0203250:	870d                	srai	a4,a4,0x3
ffffffffc0203252:	02b70733          	mul	a4,a4,a1
ffffffffc0203256:	00003697          	auipc	a3,0x3
ffffffffc020325a:	0e268693          	addi	a3,a3,226 # ffffffffc0206338 <nbase>
ffffffffc020325e:	6290                	ld	a2,0(a3)
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0203260:	0000e697          	auipc	a3,0xe
ffffffffc0203264:	1f868693          	addi	a3,a3,504 # ffffffffc0211458 <npage>
ffffffffc0203268:	6294                	ld	a3,0(a3)
ffffffffc020326a:	06b2                	slli	a3,a3,0xc
ffffffffc020326c:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020326e:	0732                	slli	a4,a4,0xc
ffffffffc0203270:	2cd77863          	bleu	a3,a4,ffffffffc0203540 <default_check+0x3a8>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203274:	40f98733          	sub	a4,s3,a5
ffffffffc0203278:	870d                	srai	a4,a4,0x3
ffffffffc020327a:	02b70733          	mul	a4,a4,a1
ffffffffc020327e:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0203280:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0203282:	4ed77f63          	bleu	a3,a4,ffffffffc0203780 <default_check+0x5e8>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203286:	40f507b3          	sub	a5,a0,a5
ffffffffc020328a:	878d                	srai	a5,a5,0x3
ffffffffc020328c:	02b787b3          	mul	a5,a5,a1
ffffffffc0203290:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0203292:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0203294:	34d7f663          	bleu	a3,a5,ffffffffc02035e0 <default_check+0x448>
    assert(alloc_page() == NULL);
ffffffffc0203298:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020329a:	00093c03          	ld	s8,0(s2)
ffffffffc020329e:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc02032a2:	01092b03          	lw	s6,16(s2)
    elm->prev = elm->next = elm;
ffffffffc02032a6:	0000e797          	auipc	a5,0xe
ffffffffc02032aa:	2f27b123          	sd	s2,738(a5) # ffffffffc0211588 <free_area+0x8>
ffffffffc02032ae:	0000e797          	auipc	a5,0xe
ffffffffc02032b2:	2d27b923          	sd	s2,722(a5) # ffffffffc0211580 <free_area>
    nr_free = 0;
ffffffffc02032b6:	0000e797          	auipc	a5,0xe
ffffffffc02032ba:	2c07ad23          	sw	zero,730(a5) # ffffffffc0211590 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02032be:	82ffd0ef          	jal	ra,ffffffffc0200aec <alloc_pages>
ffffffffc02032c2:	2e051f63          	bnez	a0,ffffffffc02035c0 <default_check+0x428>
    free_page(p0);
ffffffffc02032c6:	4585                	li	a1,1
ffffffffc02032c8:	8552                	mv	a0,s4
ffffffffc02032ca:	8abfd0ef          	jal	ra,ffffffffc0200b74 <free_pages>
    free_page(p1);
ffffffffc02032ce:	4585                	li	a1,1
ffffffffc02032d0:	854e                	mv	a0,s3
ffffffffc02032d2:	8a3fd0ef          	jal	ra,ffffffffc0200b74 <free_pages>
    free_page(p2);
ffffffffc02032d6:	4585                	li	a1,1
ffffffffc02032d8:	8556                	mv	a0,s5
ffffffffc02032da:	89bfd0ef          	jal	ra,ffffffffc0200b74 <free_pages>
    assert(nr_free == 3);
ffffffffc02032de:	01092703          	lw	a4,16(s2)
ffffffffc02032e2:	478d                	li	a5,3
ffffffffc02032e4:	2af71e63          	bne	a4,a5,ffffffffc02035a0 <default_check+0x408>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02032e8:	4505                	li	a0,1
ffffffffc02032ea:	803fd0ef          	jal	ra,ffffffffc0200aec <alloc_pages>
ffffffffc02032ee:	89aa                	mv	s3,a0
ffffffffc02032f0:	28050863          	beqz	a0,ffffffffc0203580 <default_check+0x3e8>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02032f4:	4505                	li	a0,1
ffffffffc02032f6:	ff6fd0ef          	jal	ra,ffffffffc0200aec <alloc_pages>
ffffffffc02032fa:	8aaa                	mv	s5,a0
ffffffffc02032fc:	3e050263          	beqz	a0,ffffffffc02036e0 <default_check+0x548>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0203300:	4505                	li	a0,1
ffffffffc0203302:	feafd0ef          	jal	ra,ffffffffc0200aec <alloc_pages>
ffffffffc0203306:	8a2a                	mv	s4,a0
ffffffffc0203308:	3a050c63          	beqz	a0,ffffffffc02036c0 <default_check+0x528>
    assert(alloc_page() == NULL);
ffffffffc020330c:	4505                	li	a0,1
ffffffffc020330e:	fdefd0ef          	jal	ra,ffffffffc0200aec <alloc_pages>
ffffffffc0203312:	38051763          	bnez	a0,ffffffffc02036a0 <default_check+0x508>
    free_page(p0);
ffffffffc0203316:	4585                	li	a1,1
ffffffffc0203318:	854e                	mv	a0,s3
ffffffffc020331a:	85bfd0ef          	jal	ra,ffffffffc0200b74 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc020331e:	00893783          	ld	a5,8(s2)
ffffffffc0203322:	23278f63          	beq	a5,s2,ffffffffc0203560 <default_check+0x3c8>
    assert((p = alloc_page()) == p0);
ffffffffc0203326:	4505                	li	a0,1
ffffffffc0203328:	fc4fd0ef          	jal	ra,ffffffffc0200aec <alloc_pages>
ffffffffc020332c:	32a99a63          	bne	s3,a0,ffffffffc0203660 <default_check+0x4c8>
    assert(alloc_page() == NULL);
ffffffffc0203330:	4505                	li	a0,1
ffffffffc0203332:	fbafd0ef          	jal	ra,ffffffffc0200aec <alloc_pages>
ffffffffc0203336:	30051563          	bnez	a0,ffffffffc0203640 <default_check+0x4a8>
    assert(nr_free == 0);
ffffffffc020333a:	01092783          	lw	a5,16(s2)
ffffffffc020333e:	2e079163          	bnez	a5,ffffffffc0203620 <default_check+0x488>
    free_page(p);
ffffffffc0203342:	854e                	mv	a0,s3
ffffffffc0203344:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0203346:	0000e797          	auipc	a5,0xe
ffffffffc020334a:	2387bd23          	sd	s8,570(a5) # ffffffffc0211580 <free_area>
ffffffffc020334e:	0000e797          	auipc	a5,0xe
ffffffffc0203352:	2377bd23          	sd	s7,570(a5) # ffffffffc0211588 <free_area+0x8>
    nr_free = nr_free_store;
ffffffffc0203356:	0000e797          	auipc	a5,0xe
ffffffffc020335a:	2367ad23          	sw	s6,570(a5) # ffffffffc0211590 <free_area+0x10>
    free_page(p);
ffffffffc020335e:	817fd0ef          	jal	ra,ffffffffc0200b74 <free_pages>
    free_page(p1);
ffffffffc0203362:	4585                	li	a1,1
ffffffffc0203364:	8556                	mv	a0,s5
ffffffffc0203366:	80ffd0ef          	jal	ra,ffffffffc0200b74 <free_pages>
    free_page(p2);
ffffffffc020336a:	4585                	li	a1,1
ffffffffc020336c:	8552                	mv	a0,s4
ffffffffc020336e:	807fd0ef          	jal	ra,ffffffffc0200b74 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0203372:	4515                	li	a0,5
ffffffffc0203374:	f78fd0ef          	jal	ra,ffffffffc0200aec <alloc_pages>
ffffffffc0203378:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc020337a:	28050363          	beqz	a0,ffffffffc0203600 <default_check+0x468>
ffffffffc020337e:	651c                	ld	a5,8(a0)
ffffffffc0203380:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0203382:	8b85                	andi	a5,a5,1
ffffffffc0203384:	54079e63          	bnez	a5,ffffffffc02038e0 <default_check+0x748>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0203388:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020338a:	00093b03          	ld	s6,0(s2)
ffffffffc020338e:	00893a83          	ld	s5,8(s2)
ffffffffc0203392:	0000e797          	auipc	a5,0xe
ffffffffc0203396:	1f27b723          	sd	s2,494(a5) # ffffffffc0211580 <free_area>
ffffffffc020339a:	0000e797          	auipc	a5,0xe
ffffffffc020339e:	1f27b723          	sd	s2,494(a5) # ffffffffc0211588 <free_area+0x8>
    assert(alloc_page() == NULL);
ffffffffc02033a2:	f4afd0ef          	jal	ra,ffffffffc0200aec <alloc_pages>
ffffffffc02033a6:	50051d63          	bnez	a0,ffffffffc02038c0 <default_check+0x728>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc02033aa:	09098a13          	addi	s4,s3,144
ffffffffc02033ae:	8552                	mv	a0,s4
ffffffffc02033b0:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc02033b2:	01092b83          	lw	s7,16(s2)
    nr_free = 0;
ffffffffc02033b6:	0000e797          	auipc	a5,0xe
ffffffffc02033ba:	1c07ad23          	sw	zero,474(a5) # ffffffffc0211590 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc02033be:	fb6fd0ef          	jal	ra,ffffffffc0200b74 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02033c2:	4511                	li	a0,4
ffffffffc02033c4:	f28fd0ef          	jal	ra,ffffffffc0200aec <alloc_pages>
ffffffffc02033c8:	4c051c63          	bnez	a0,ffffffffc02038a0 <default_check+0x708>
ffffffffc02033cc:	0989b783          	ld	a5,152(s3)
ffffffffc02033d0:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02033d2:	8b85                	andi	a5,a5,1
ffffffffc02033d4:	4a078663          	beqz	a5,ffffffffc0203880 <default_check+0x6e8>
ffffffffc02033d8:	0a89a703          	lw	a4,168(s3)
ffffffffc02033dc:	478d                	li	a5,3
ffffffffc02033de:	4af71163          	bne	a4,a5,ffffffffc0203880 <default_check+0x6e8>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02033e2:	450d                	li	a0,3
ffffffffc02033e4:	f08fd0ef          	jal	ra,ffffffffc0200aec <alloc_pages>
ffffffffc02033e8:	8c2a                	mv	s8,a0
ffffffffc02033ea:	46050b63          	beqz	a0,ffffffffc0203860 <default_check+0x6c8>
    assert(alloc_page() == NULL);
ffffffffc02033ee:	4505                	li	a0,1
ffffffffc02033f0:	efcfd0ef          	jal	ra,ffffffffc0200aec <alloc_pages>
ffffffffc02033f4:	44051663          	bnez	a0,ffffffffc0203840 <default_check+0x6a8>
    assert(p0 + 2 == p1);
ffffffffc02033f8:	438a1463          	bne	s4,s8,ffffffffc0203820 <default_check+0x688>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc02033fc:	4585                	li	a1,1
ffffffffc02033fe:	854e                	mv	a0,s3
ffffffffc0203400:	f74fd0ef          	jal	ra,ffffffffc0200b74 <free_pages>
    free_pages(p1, 3);
ffffffffc0203404:	458d                	li	a1,3
ffffffffc0203406:	8552                	mv	a0,s4
ffffffffc0203408:	f6cfd0ef          	jal	ra,ffffffffc0200b74 <free_pages>
ffffffffc020340c:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0203410:	04898c13          	addi	s8,s3,72
ffffffffc0203414:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0203416:	8b85                	andi	a5,a5,1
ffffffffc0203418:	3e078463          	beqz	a5,ffffffffc0203800 <default_check+0x668>
ffffffffc020341c:	0189a703          	lw	a4,24(s3)
ffffffffc0203420:	4785                	li	a5,1
ffffffffc0203422:	3cf71f63          	bne	a4,a5,ffffffffc0203800 <default_check+0x668>
ffffffffc0203426:	008a3783          	ld	a5,8(s4)
ffffffffc020342a:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc020342c:	8b85                	andi	a5,a5,1
ffffffffc020342e:	3a078963          	beqz	a5,ffffffffc02037e0 <default_check+0x648>
ffffffffc0203432:	018a2703          	lw	a4,24(s4)
ffffffffc0203436:	478d                	li	a5,3
ffffffffc0203438:	3af71463          	bne	a4,a5,ffffffffc02037e0 <default_check+0x648>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc020343c:	4505                	li	a0,1
ffffffffc020343e:	eaefd0ef          	jal	ra,ffffffffc0200aec <alloc_pages>
ffffffffc0203442:	36a99f63          	bne	s3,a0,ffffffffc02037c0 <default_check+0x628>
    free_page(p0);
ffffffffc0203446:	4585                	li	a1,1
ffffffffc0203448:	f2cfd0ef          	jal	ra,ffffffffc0200b74 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc020344c:	4509                	li	a0,2
ffffffffc020344e:	e9efd0ef          	jal	ra,ffffffffc0200aec <alloc_pages>
ffffffffc0203452:	34aa1763          	bne	s4,a0,ffffffffc02037a0 <default_check+0x608>

    free_pages(p0, 2);
ffffffffc0203456:	4589                	li	a1,2
ffffffffc0203458:	f1cfd0ef          	jal	ra,ffffffffc0200b74 <free_pages>
    free_page(p2);
ffffffffc020345c:	4585                	li	a1,1
ffffffffc020345e:	8562                	mv	a0,s8
ffffffffc0203460:	f14fd0ef          	jal	ra,ffffffffc0200b74 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0203464:	4515                	li	a0,5
ffffffffc0203466:	e86fd0ef          	jal	ra,ffffffffc0200aec <alloc_pages>
ffffffffc020346a:	89aa                	mv	s3,a0
ffffffffc020346c:	48050a63          	beqz	a0,ffffffffc0203900 <default_check+0x768>
    assert(alloc_page() == NULL);
ffffffffc0203470:	4505                	li	a0,1
ffffffffc0203472:	e7afd0ef          	jal	ra,ffffffffc0200aec <alloc_pages>
ffffffffc0203476:	2e051563          	bnez	a0,ffffffffc0203760 <default_check+0x5c8>

    assert(nr_free == 0);
ffffffffc020347a:	01092783          	lw	a5,16(s2)
ffffffffc020347e:	2c079163          	bnez	a5,ffffffffc0203740 <default_check+0x5a8>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0203482:	4595                	li	a1,5
ffffffffc0203484:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0203486:	0000e797          	auipc	a5,0xe
ffffffffc020348a:	1177a523          	sw	s7,266(a5) # ffffffffc0211590 <free_area+0x10>
    free_list = free_list_store;
ffffffffc020348e:	0000e797          	auipc	a5,0xe
ffffffffc0203492:	0f67b923          	sd	s6,242(a5) # ffffffffc0211580 <free_area>
ffffffffc0203496:	0000e797          	auipc	a5,0xe
ffffffffc020349a:	0f57b923          	sd	s5,242(a5) # ffffffffc0211588 <free_area+0x8>
    free_pages(p0, 5);
ffffffffc020349e:	ed6fd0ef          	jal	ra,ffffffffc0200b74 <free_pages>
    return listelm->next;
ffffffffc02034a2:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02034a6:	01278963          	beq	a5,s2,ffffffffc02034b8 <default_check+0x320>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc02034aa:	ff87a703          	lw	a4,-8(a5)
ffffffffc02034ae:	679c                	ld	a5,8(a5)
ffffffffc02034b0:	34fd                	addiw	s1,s1,-1
ffffffffc02034b2:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02034b4:	ff279be3          	bne	a5,s2,ffffffffc02034aa <default_check+0x312>
    }
    assert(count == 0);
ffffffffc02034b8:	26049463          	bnez	s1,ffffffffc0203720 <default_check+0x588>
    assert(total == 0);
ffffffffc02034bc:	46041263          	bnez	s0,ffffffffc0203920 <default_check+0x788>
}
ffffffffc02034c0:	60a6                	ld	ra,72(sp)
ffffffffc02034c2:	6406                	ld	s0,64(sp)
ffffffffc02034c4:	74e2                	ld	s1,56(sp)
ffffffffc02034c6:	7942                	ld	s2,48(sp)
ffffffffc02034c8:	79a2                	ld	s3,40(sp)
ffffffffc02034ca:	7a02                	ld	s4,32(sp)
ffffffffc02034cc:	6ae2                	ld	s5,24(sp)
ffffffffc02034ce:	6b42                	ld	s6,16(sp)
ffffffffc02034d0:	6ba2                	ld	s7,8(sp)
ffffffffc02034d2:	6c02                	ld	s8,0(sp)
ffffffffc02034d4:	6161                	addi	sp,sp,80
ffffffffc02034d6:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc02034d8:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc02034da:	4401                	li	s0,0
ffffffffc02034dc:	4481                	li	s1,0
ffffffffc02034de:	b331                	j	ffffffffc02031ea <default_check+0x52>
        assert(PageProperty(p));
ffffffffc02034e0:	00002697          	auipc	a3,0x2
ffffffffc02034e4:	51068693          	addi	a3,a3,1296 # ffffffffc02059f0 <commands+0x14b8>
ffffffffc02034e8:	00002617          	auipc	a2,0x2
ffffffffc02034ec:	a4060613          	addi	a2,a2,-1472 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02034f0:	0f000593          	li	a1,240
ffffffffc02034f4:	00003517          	auipc	a0,0x3
ffffffffc02034f8:	80450513          	addi	a0,a0,-2044 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc02034fc:	c0bfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0203500:	00003697          	auipc	a3,0x3
ffffffffc0203504:	87068693          	addi	a3,a3,-1936 # ffffffffc0205d70 <commands+0x1838>
ffffffffc0203508:	00002617          	auipc	a2,0x2
ffffffffc020350c:	a2060613          	addi	a2,a2,-1504 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0203510:	0bd00593          	li	a1,189
ffffffffc0203514:	00002517          	auipc	a0,0x2
ffffffffc0203518:	7e450513          	addi	a0,a0,2020 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc020351c:	bebfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0203520:	00003697          	auipc	a3,0x3
ffffffffc0203524:	87868693          	addi	a3,a3,-1928 # ffffffffc0205d98 <commands+0x1860>
ffffffffc0203528:	00002617          	auipc	a2,0x2
ffffffffc020352c:	a0060613          	addi	a2,a2,-1536 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0203530:	0be00593          	li	a1,190
ffffffffc0203534:	00002517          	auipc	a0,0x2
ffffffffc0203538:	7c450513          	addi	a0,a0,1988 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc020353c:	bcbfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0203540:	00003697          	auipc	a3,0x3
ffffffffc0203544:	89868693          	addi	a3,a3,-1896 # ffffffffc0205dd8 <commands+0x18a0>
ffffffffc0203548:	00002617          	auipc	a2,0x2
ffffffffc020354c:	9e060613          	addi	a2,a2,-1568 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0203550:	0c000593          	li	a1,192
ffffffffc0203554:	00002517          	auipc	a0,0x2
ffffffffc0203558:	7a450513          	addi	a0,a0,1956 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc020355c:	babfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0203560:	00003697          	auipc	a3,0x3
ffffffffc0203564:	90068693          	addi	a3,a3,-1792 # ffffffffc0205e60 <commands+0x1928>
ffffffffc0203568:	00002617          	auipc	a2,0x2
ffffffffc020356c:	9c060613          	addi	a2,a2,-1600 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0203570:	0d900593          	li	a1,217
ffffffffc0203574:	00002517          	auipc	a0,0x2
ffffffffc0203578:	78450513          	addi	a0,a0,1924 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc020357c:	b8bfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0203580:	00002697          	auipc	a3,0x2
ffffffffc0203584:	79068693          	addi	a3,a3,1936 # ffffffffc0205d10 <commands+0x17d8>
ffffffffc0203588:	00002617          	auipc	a2,0x2
ffffffffc020358c:	9a060613          	addi	a2,a2,-1632 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0203590:	0d200593          	li	a1,210
ffffffffc0203594:	00002517          	auipc	a0,0x2
ffffffffc0203598:	76450513          	addi	a0,a0,1892 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc020359c:	b6bfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(nr_free == 3);
ffffffffc02035a0:	00003697          	auipc	a3,0x3
ffffffffc02035a4:	8b068693          	addi	a3,a3,-1872 # ffffffffc0205e50 <commands+0x1918>
ffffffffc02035a8:	00002617          	auipc	a2,0x2
ffffffffc02035ac:	98060613          	addi	a2,a2,-1664 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02035b0:	0d000593          	li	a1,208
ffffffffc02035b4:	00002517          	auipc	a0,0x2
ffffffffc02035b8:	74450513          	addi	a0,a0,1860 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc02035bc:	b4bfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02035c0:	00003697          	auipc	a3,0x3
ffffffffc02035c4:	87868693          	addi	a3,a3,-1928 # ffffffffc0205e38 <commands+0x1900>
ffffffffc02035c8:	00002617          	auipc	a2,0x2
ffffffffc02035cc:	96060613          	addi	a2,a2,-1696 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02035d0:	0cb00593          	li	a1,203
ffffffffc02035d4:	00002517          	auipc	a0,0x2
ffffffffc02035d8:	72450513          	addi	a0,a0,1828 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc02035dc:	b2bfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02035e0:	00003697          	auipc	a3,0x3
ffffffffc02035e4:	83868693          	addi	a3,a3,-1992 # ffffffffc0205e18 <commands+0x18e0>
ffffffffc02035e8:	00002617          	auipc	a2,0x2
ffffffffc02035ec:	94060613          	addi	a2,a2,-1728 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02035f0:	0c200593          	li	a1,194
ffffffffc02035f4:	00002517          	auipc	a0,0x2
ffffffffc02035f8:	70450513          	addi	a0,a0,1796 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc02035fc:	b0bfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(p0 != NULL);
ffffffffc0203600:	00003697          	auipc	a3,0x3
ffffffffc0203604:	89868693          	addi	a3,a3,-1896 # ffffffffc0205e98 <commands+0x1960>
ffffffffc0203608:	00002617          	auipc	a2,0x2
ffffffffc020360c:	92060613          	addi	a2,a2,-1760 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0203610:	0f800593          	li	a1,248
ffffffffc0203614:	00002517          	auipc	a0,0x2
ffffffffc0203618:	6e450513          	addi	a0,a0,1764 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc020361c:	aebfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(nr_free == 0);
ffffffffc0203620:	00002697          	auipc	a3,0x2
ffffffffc0203624:	57868693          	addi	a3,a3,1400 # ffffffffc0205b98 <commands+0x1660>
ffffffffc0203628:	00002617          	auipc	a2,0x2
ffffffffc020362c:	90060613          	addi	a2,a2,-1792 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0203630:	0df00593          	li	a1,223
ffffffffc0203634:	00002517          	auipc	a0,0x2
ffffffffc0203638:	6c450513          	addi	a0,a0,1732 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc020363c:	acbfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0203640:	00002697          	auipc	a3,0x2
ffffffffc0203644:	7f868693          	addi	a3,a3,2040 # ffffffffc0205e38 <commands+0x1900>
ffffffffc0203648:	00002617          	auipc	a2,0x2
ffffffffc020364c:	8e060613          	addi	a2,a2,-1824 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0203650:	0dd00593          	li	a1,221
ffffffffc0203654:	00002517          	auipc	a0,0x2
ffffffffc0203658:	6a450513          	addi	a0,a0,1700 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc020365c:	aabfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0203660:	00003697          	auipc	a3,0x3
ffffffffc0203664:	81868693          	addi	a3,a3,-2024 # ffffffffc0205e78 <commands+0x1940>
ffffffffc0203668:	00002617          	auipc	a2,0x2
ffffffffc020366c:	8c060613          	addi	a2,a2,-1856 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0203670:	0dc00593          	li	a1,220
ffffffffc0203674:	00002517          	auipc	a0,0x2
ffffffffc0203678:	68450513          	addi	a0,a0,1668 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc020367c:	a8bfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0203680:	00002697          	auipc	a3,0x2
ffffffffc0203684:	69068693          	addi	a3,a3,1680 # ffffffffc0205d10 <commands+0x17d8>
ffffffffc0203688:	00002617          	auipc	a2,0x2
ffffffffc020368c:	8a060613          	addi	a2,a2,-1888 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0203690:	0b900593          	li	a1,185
ffffffffc0203694:	00002517          	auipc	a0,0x2
ffffffffc0203698:	66450513          	addi	a0,a0,1636 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc020369c:	a6bfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02036a0:	00002697          	auipc	a3,0x2
ffffffffc02036a4:	79868693          	addi	a3,a3,1944 # ffffffffc0205e38 <commands+0x1900>
ffffffffc02036a8:	00002617          	auipc	a2,0x2
ffffffffc02036ac:	88060613          	addi	a2,a2,-1920 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02036b0:	0d600593          	li	a1,214
ffffffffc02036b4:	00002517          	auipc	a0,0x2
ffffffffc02036b8:	64450513          	addi	a0,a0,1604 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc02036bc:	a4bfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02036c0:	00002697          	auipc	a3,0x2
ffffffffc02036c4:	69068693          	addi	a3,a3,1680 # ffffffffc0205d50 <commands+0x1818>
ffffffffc02036c8:	00002617          	auipc	a2,0x2
ffffffffc02036cc:	86060613          	addi	a2,a2,-1952 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02036d0:	0d400593          	li	a1,212
ffffffffc02036d4:	00002517          	auipc	a0,0x2
ffffffffc02036d8:	62450513          	addi	a0,a0,1572 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc02036dc:	a2bfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02036e0:	00002697          	auipc	a3,0x2
ffffffffc02036e4:	65068693          	addi	a3,a3,1616 # ffffffffc0205d30 <commands+0x17f8>
ffffffffc02036e8:	00002617          	auipc	a2,0x2
ffffffffc02036ec:	84060613          	addi	a2,a2,-1984 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02036f0:	0d300593          	li	a1,211
ffffffffc02036f4:	00002517          	auipc	a0,0x2
ffffffffc02036f8:	60450513          	addi	a0,a0,1540 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc02036fc:	a0bfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0203700:	00002697          	auipc	a3,0x2
ffffffffc0203704:	65068693          	addi	a3,a3,1616 # ffffffffc0205d50 <commands+0x1818>
ffffffffc0203708:	00002617          	auipc	a2,0x2
ffffffffc020370c:	82060613          	addi	a2,a2,-2016 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0203710:	0bb00593          	li	a1,187
ffffffffc0203714:	00002517          	auipc	a0,0x2
ffffffffc0203718:	5e450513          	addi	a0,a0,1508 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc020371c:	9ebfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(count == 0);
ffffffffc0203720:	00003697          	auipc	a3,0x3
ffffffffc0203724:	8c868693          	addi	a3,a3,-1848 # ffffffffc0205fe8 <commands+0x1ab0>
ffffffffc0203728:	00002617          	auipc	a2,0x2
ffffffffc020372c:	80060613          	addi	a2,a2,-2048 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0203730:	12500593          	li	a1,293
ffffffffc0203734:	00002517          	auipc	a0,0x2
ffffffffc0203738:	5c450513          	addi	a0,a0,1476 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc020373c:	9cbfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(nr_free == 0);
ffffffffc0203740:	00002697          	auipc	a3,0x2
ffffffffc0203744:	45868693          	addi	a3,a3,1112 # ffffffffc0205b98 <commands+0x1660>
ffffffffc0203748:	00001617          	auipc	a2,0x1
ffffffffc020374c:	7e060613          	addi	a2,a2,2016 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0203750:	11a00593          	li	a1,282
ffffffffc0203754:	00002517          	auipc	a0,0x2
ffffffffc0203758:	5a450513          	addi	a0,a0,1444 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc020375c:	9abfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0203760:	00002697          	auipc	a3,0x2
ffffffffc0203764:	6d868693          	addi	a3,a3,1752 # ffffffffc0205e38 <commands+0x1900>
ffffffffc0203768:	00001617          	auipc	a2,0x1
ffffffffc020376c:	7c060613          	addi	a2,a2,1984 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0203770:	11800593          	li	a1,280
ffffffffc0203774:	00002517          	auipc	a0,0x2
ffffffffc0203778:	58450513          	addi	a0,a0,1412 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc020377c:	98bfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0203780:	00002697          	auipc	a3,0x2
ffffffffc0203784:	67868693          	addi	a3,a3,1656 # ffffffffc0205df8 <commands+0x18c0>
ffffffffc0203788:	00001617          	auipc	a2,0x1
ffffffffc020378c:	7a060613          	addi	a2,a2,1952 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0203790:	0c100593          	li	a1,193
ffffffffc0203794:	00002517          	auipc	a0,0x2
ffffffffc0203798:	56450513          	addi	a0,a0,1380 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc020379c:	96bfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02037a0:	00003697          	auipc	a3,0x3
ffffffffc02037a4:	80868693          	addi	a3,a3,-2040 # ffffffffc0205fa8 <commands+0x1a70>
ffffffffc02037a8:	00001617          	auipc	a2,0x1
ffffffffc02037ac:	78060613          	addi	a2,a2,1920 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02037b0:	11200593          	li	a1,274
ffffffffc02037b4:	00002517          	auipc	a0,0x2
ffffffffc02037b8:	54450513          	addi	a0,a0,1348 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc02037bc:	94bfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02037c0:	00002697          	auipc	a3,0x2
ffffffffc02037c4:	7c868693          	addi	a3,a3,1992 # ffffffffc0205f88 <commands+0x1a50>
ffffffffc02037c8:	00001617          	auipc	a2,0x1
ffffffffc02037cc:	76060613          	addi	a2,a2,1888 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02037d0:	11000593          	li	a1,272
ffffffffc02037d4:	00002517          	auipc	a0,0x2
ffffffffc02037d8:	52450513          	addi	a0,a0,1316 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc02037dc:	92bfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02037e0:	00002697          	auipc	a3,0x2
ffffffffc02037e4:	78068693          	addi	a3,a3,1920 # ffffffffc0205f60 <commands+0x1a28>
ffffffffc02037e8:	00001617          	auipc	a2,0x1
ffffffffc02037ec:	74060613          	addi	a2,a2,1856 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02037f0:	10e00593          	li	a1,270
ffffffffc02037f4:	00002517          	auipc	a0,0x2
ffffffffc02037f8:	50450513          	addi	a0,a0,1284 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc02037fc:	90bfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0203800:	00002697          	auipc	a3,0x2
ffffffffc0203804:	73868693          	addi	a3,a3,1848 # ffffffffc0205f38 <commands+0x1a00>
ffffffffc0203808:	00001617          	auipc	a2,0x1
ffffffffc020380c:	72060613          	addi	a2,a2,1824 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0203810:	10d00593          	li	a1,269
ffffffffc0203814:	00002517          	auipc	a0,0x2
ffffffffc0203818:	4e450513          	addi	a0,a0,1252 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc020381c:	8ebfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(p0 + 2 == p1);
ffffffffc0203820:	00002697          	auipc	a3,0x2
ffffffffc0203824:	70868693          	addi	a3,a3,1800 # ffffffffc0205f28 <commands+0x19f0>
ffffffffc0203828:	00001617          	auipc	a2,0x1
ffffffffc020382c:	70060613          	addi	a2,a2,1792 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0203830:	10800593          	li	a1,264
ffffffffc0203834:	00002517          	auipc	a0,0x2
ffffffffc0203838:	4c450513          	addi	a0,a0,1220 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc020383c:	8cbfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0203840:	00002697          	auipc	a3,0x2
ffffffffc0203844:	5f868693          	addi	a3,a3,1528 # ffffffffc0205e38 <commands+0x1900>
ffffffffc0203848:	00001617          	auipc	a2,0x1
ffffffffc020384c:	6e060613          	addi	a2,a2,1760 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0203850:	10700593          	li	a1,263
ffffffffc0203854:	00002517          	auipc	a0,0x2
ffffffffc0203858:	4a450513          	addi	a0,a0,1188 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc020385c:	8abfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0203860:	00002697          	auipc	a3,0x2
ffffffffc0203864:	6a868693          	addi	a3,a3,1704 # ffffffffc0205f08 <commands+0x19d0>
ffffffffc0203868:	00001617          	auipc	a2,0x1
ffffffffc020386c:	6c060613          	addi	a2,a2,1728 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0203870:	10600593          	li	a1,262
ffffffffc0203874:	00002517          	auipc	a0,0x2
ffffffffc0203878:	48450513          	addi	a0,a0,1156 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc020387c:	88bfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0203880:	00002697          	auipc	a3,0x2
ffffffffc0203884:	65868693          	addi	a3,a3,1624 # ffffffffc0205ed8 <commands+0x19a0>
ffffffffc0203888:	00001617          	auipc	a2,0x1
ffffffffc020388c:	6a060613          	addi	a2,a2,1696 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0203890:	10500593          	li	a1,261
ffffffffc0203894:	00002517          	auipc	a0,0x2
ffffffffc0203898:	46450513          	addi	a0,a0,1124 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc020389c:	86bfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02038a0:	00002697          	auipc	a3,0x2
ffffffffc02038a4:	62068693          	addi	a3,a3,1568 # ffffffffc0205ec0 <commands+0x1988>
ffffffffc02038a8:	00001617          	auipc	a2,0x1
ffffffffc02038ac:	68060613          	addi	a2,a2,1664 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02038b0:	10400593          	li	a1,260
ffffffffc02038b4:	00002517          	auipc	a0,0x2
ffffffffc02038b8:	44450513          	addi	a0,a0,1092 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc02038bc:	84bfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02038c0:	00002697          	auipc	a3,0x2
ffffffffc02038c4:	57868693          	addi	a3,a3,1400 # ffffffffc0205e38 <commands+0x1900>
ffffffffc02038c8:	00001617          	auipc	a2,0x1
ffffffffc02038cc:	66060613          	addi	a2,a2,1632 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02038d0:	0fe00593          	li	a1,254
ffffffffc02038d4:	00002517          	auipc	a0,0x2
ffffffffc02038d8:	42450513          	addi	a0,a0,1060 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc02038dc:	82bfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(!PageProperty(p0));
ffffffffc02038e0:	00002697          	auipc	a3,0x2
ffffffffc02038e4:	5c868693          	addi	a3,a3,1480 # ffffffffc0205ea8 <commands+0x1970>
ffffffffc02038e8:	00001617          	auipc	a2,0x1
ffffffffc02038ec:	64060613          	addi	a2,a2,1600 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc02038f0:	0f900593          	li	a1,249
ffffffffc02038f4:	00002517          	auipc	a0,0x2
ffffffffc02038f8:	40450513          	addi	a0,a0,1028 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc02038fc:	80bfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0203900:	00002697          	auipc	a3,0x2
ffffffffc0203904:	6c868693          	addi	a3,a3,1736 # ffffffffc0205fc8 <commands+0x1a90>
ffffffffc0203908:	00001617          	auipc	a2,0x1
ffffffffc020390c:	62060613          	addi	a2,a2,1568 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0203910:	11700593          	li	a1,279
ffffffffc0203914:	00002517          	auipc	a0,0x2
ffffffffc0203918:	3e450513          	addi	a0,a0,996 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc020391c:	feafc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(total == 0);
ffffffffc0203920:	00002697          	auipc	a3,0x2
ffffffffc0203924:	6d868693          	addi	a3,a3,1752 # ffffffffc0205ff8 <commands+0x1ac0>
ffffffffc0203928:	00001617          	auipc	a2,0x1
ffffffffc020392c:	60060613          	addi	a2,a2,1536 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0203930:	12600593          	li	a1,294
ffffffffc0203934:	00002517          	auipc	a0,0x2
ffffffffc0203938:	3c450513          	addi	a0,a0,964 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc020393c:	fcafc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(total == nr_free_pages());
ffffffffc0203940:	00002697          	auipc	a3,0x2
ffffffffc0203944:	0c068693          	addi	a3,a3,192 # ffffffffc0205a00 <commands+0x14c8>
ffffffffc0203948:	00001617          	auipc	a2,0x1
ffffffffc020394c:	5e060613          	addi	a2,a2,1504 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0203950:	0f300593          	li	a1,243
ffffffffc0203954:	00002517          	auipc	a0,0x2
ffffffffc0203958:	3a450513          	addi	a0,a0,932 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc020395c:	faafc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0203960:	00002697          	auipc	a3,0x2
ffffffffc0203964:	3d068693          	addi	a3,a3,976 # ffffffffc0205d30 <commands+0x17f8>
ffffffffc0203968:	00001617          	auipc	a2,0x1
ffffffffc020396c:	5c060613          	addi	a2,a2,1472 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0203970:	0ba00593          	li	a1,186
ffffffffc0203974:	00002517          	auipc	a0,0x2
ffffffffc0203978:	38450513          	addi	a0,a0,900 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc020397c:	f8afc0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc0203980 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0203980:	1141                	addi	sp,sp,-16
ffffffffc0203982:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0203984:	18058063          	beqz	a1,ffffffffc0203b04 <default_free_pages+0x184>
    for (; p != base + n; p ++) {
ffffffffc0203988:	00359693          	slli	a3,a1,0x3
ffffffffc020398c:	96ae                	add	a3,a3,a1
ffffffffc020398e:	068e                	slli	a3,a3,0x3
ffffffffc0203990:	96aa                	add	a3,a3,a0
ffffffffc0203992:	02d50d63          	beq	a0,a3,ffffffffc02039cc <default_free_pages+0x4c>
ffffffffc0203996:	651c                	ld	a5,8(a0)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0203998:	8b85                	andi	a5,a5,1
ffffffffc020399a:	14079563          	bnez	a5,ffffffffc0203ae4 <default_free_pages+0x164>
ffffffffc020399e:	651c                	ld	a5,8(a0)
ffffffffc02039a0:	8385                	srli	a5,a5,0x1
ffffffffc02039a2:	8b85                	andi	a5,a5,1
ffffffffc02039a4:	14079063          	bnez	a5,ffffffffc0203ae4 <default_free_pages+0x164>
ffffffffc02039a8:	87aa                	mv	a5,a0
ffffffffc02039aa:	a809                	j	ffffffffc02039bc <default_free_pages+0x3c>
ffffffffc02039ac:	6798                	ld	a4,8(a5)
ffffffffc02039ae:	8b05                	andi	a4,a4,1
ffffffffc02039b0:	12071a63          	bnez	a4,ffffffffc0203ae4 <default_free_pages+0x164>
ffffffffc02039b4:	6798                	ld	a4,8(a5)
ffffffffc02039b6:	8b09                	andi	a4,a4,2
ffffffffc02039b8:	12071663          	bnez	a4,ffffffffc0203ae4 <default_free_pages+0x164>
        p->flags = 0;
ffffffffc02039bc:	0007b423          	sd	zero,8(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02039c0:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02039c4:	04878793          	addi	a5,a5,72
ffffffffc02039c8:	fed792e3          	bne	a5,a3,ffffffffc02039ac <default_free_pages+0x2c>
    base->property = n;
ffffffffc02039cc:	2581                	sext.w	a1,a1
ffffffffc02039ce:	cd0c                	sw	a1,24(a0)
    SetPageProperty(base);
ffffffffc02039d0:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02039d4:	4789                	li	a5,2
ffffffffc02039d6:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02039da:	0000e697          	auipc	a3,0xe
ffffffffc02039de:	ba668693          	addi	a3,a3,-1114 # ffffffffc0211580 <free_area>
ffffffffc02039e2:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02039e4:	669c                	ld	a5,8(a3)
ffffffffc02039e6:	9db9                	addw	a1,a1,a4
ffffffffc02039e8:	0000e717          	auipc	a4,0xe
ffffffffc02039ec:	bab72423          	sw	a1,-1112(a4) # ffffffffc0211590 <free_area+0x10>
    if (list_empty(&free_list)) {
ffffffffc02039f0:	08d78f63          	beq	a5,a3,ffffffffc0203a8e <default_free_pages+0x10e>
            struct Page* page = le2page(le, page_link);
ffffffffc02039f4:	fe078713          	addi	a4,a5,-32
ffffffffc02039f8:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02039fa:	4801                	li	a6,0
ffffffffc02039fc:	02050613          	addi	a2,a0,32
            if (base < page) {
ffffffffc0203a00:	00e56a63          	bltu	a0,a4,ffffffffc0203a14 <default_free_pages+0x94>
    return listelm->next;
ffffffffc0203a04:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0203a06:	02d70563          	beq	a4,a3,ffffffffc0203a30 <default_free_pages+0xb0>
        while ((le = list_next(le)) != &free_list) {
ffffffffc0203a0a:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0203a0c:	fe078713          	addi	a4,a5,-32
            if (base < page) {
ffffffffc0203a10:	fee57ae3          	bleu	a4,a0,ffffffffc0203a04 <default_free_pages+0x84>
ffffffffc0203a14:	00080663          	beqz	a6,ffffffffc0203a20 <default_free_pages+0xa0>
ffffffffc0203a18:	0000e817          	auipc	a6,0xe
ffffffffc0203a1c:	b6b83423          	sd	a1,-1176(a6) # ffffffffc0211580 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0203a20:	638c                	ld	a1,0(a5)
    prev->next = next->prev = elm;
ffffffffc0203a22:	e390                	sd	a2,0(a5)
ffffffffc0203a24:	e590                	sd	a2,8(a1)
    elm->next = next;
ffffffffc0203a26:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc0203a28:	f10c                	sd	a1,32(a0)
    if (le != &free_list) {
ffffffffc0203a2a:	02d59163          	bne	a1,a3,ffffffffc0203a4c <default_free_pages+0xcc>
ffffffffc0203a2e:	a091                	j	ffffffffc0203a72 <default_free_pages+0xf2>
    prev->next = next->prev = elm;
ffffffffc0203a30:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0203a32:	f514                	sd	a3,40(a0)
ffffffffc0203a34:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0203a36:	f11c                	sd	a5,32(a0)
                list_add(le, &(base->page_link));
ffffffffc0203a38:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0203a3a:	00d70563          	beq	a4,a3,ffffffffc0203a44 <default_free_pages+0xc4>
ffffffffc0203a3e:	4805                	li	a6,1
ffffffffc0203a40:	87ba                	mv	a5,a4
ffffffffc0203a42:	b7e9                	j	ffffffffc0203a0c <default_free_pages+0x8c>
ffffffffc0203a44:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc0203a46:	85be                	mv	a1,a5
    if (le != &free_list) {
ffffffffc0203a48:	02d78163          	beq	a5,a3,ffffffffc0203a6a <default_free_pages+0xea>
        if (p + p->property == base) {
ffffffffc0203a4c:	ff85a803          	lw	a6,-8(a1) # ff8 <BASE_ADDRESS-0xffffffffc01ff008>
        p = le2page(le, page_link);
ffffffffc0203a50:	fe058613          	addi	a2,a1,-32
        if (p + p->property == base) {
ffffffffc0203a54:	02081713          	slli	a4,a6,0x20
ffffffffc0203a58:	9301                	srli	a4,a4,0x20
ffffffffc0203a5a:	00371793          	slli	a5,a4,0x3
ffffffffc0203a5e:	97ba                	add	a5,a5,a4
ffffffffc0203a60:	078e                	slli	a5,a5,0x3
ffffffffc0203a62:	97b2                	add	a5,a5,a2
ffffffffc0203a64:	02f50e63          	beq	a0,a5,ffffffffc0203aa0 <default_free_pages+0x120>
ffffffffc0203a68:	751c                	ld	a5,40(a0)
    if (le != &free_list) {
ffffffffc0203a6a:	fe078713          	addi	a4,a5,-32
ffffffffc0203a6e:	00d78d63          	beq	a5,a3,ffffffffc0203a88 <default_free_pages+0x108>
        if (base + base->property == p) {
ffffffffc0203a72:	4d0c                	lw	a1,24(a0)
ffffffffc0203a74:	02059613          	slli	a2,a1,0x20
ffffffffc0203a78:	9201                	srli	a2,a2,0x20
ffffffffc0203a7a:	00361693          	slli	a3,a2,0x3
ffffffffc0203a7e:	96b2                	add	a3,a3,a2
ffffffffc0203a80:	068e                	slli	a3,a3,0x3
ffffffffc0203a82:	96aa                	add	a3,a3,a0
ffffffffc0203a84:	04d70063          	beq	a4,a3,ffffffffc0203ac4 <default_free_pages+0x144>
}
ffffffffc0203a88:	60a2                	ld	ra,8(sp)
ffffffffc0203a8a:	0141                	addi	sp,sp,16
ffffffffc0203a8c:	8082                	ret
ffffffffc0203a8e:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0203a90:	02050713          	addi	a4,a0,32
    prev->next = next->prev = elm;
ffffffffc0203a94:	e398                	sd	a4,0(a5)
ffffffffc0203a96:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0203a98:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc0203a9a:	f11c                	sd	a5,32(a0)
}
ffffffffc0203a9c:	0141                	addi	sp,sp,16
ffffffffc0203a9e:	8082                	ret
            p->property += base->property;
ffffffffc0203aa0:	4d1c                	lw	a5,24(a0)
ffffffffc0203aa2:	0107883b          	addw	a6,a5,a6
ffffffffc0203aa6:	ff05ac23          	sw	a6,-8(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0203aaa:	57f5                	li	a5,-3
ffffffffc0203aac:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0203ab0:	02053803          	ld	a6,32(a0)
ffffffffc0203ab4:	7518                	ld	a4,40(a0)
            base = p;
ffffffffc0203ab6:	8532                	mv	a0,a2
    prev->next = next;
ffffffffc0203ab8:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc0203abc:	659c                	ld	a5,8(a1)
ffffffffc0203abe:	01073023          	sd	a6,0(a4)
ffffffffc0203ac2:	b765                	j	ffffffffc0203a6a <default_free_pages+0xea>
            base->property += p->property;
ffffffffc0203ac4:	ff87a703          	lw	a4,-8(a5)
ffffffffc0203ac8:	fe878693          	addi	a3,a5,-24
ffffffffc0203acc:	9db9                	addw	a1,a1,a4
ffffffffc0203ace:	cd0c                	sw	a1,24(a0)
ffffffffc0203ad0:	5775                	li	a4,-3
ffffffffc0203ad2:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0203ad6:	6398                	ld	a4,0(a5)
ffffffffc0203ad8:	679c                	ld	a5,8(a5)
}
ffffffffc0203ada:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0203adc:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203ade:	e398                	sd	a4,0(a5)
ffffffffc0203ae0:	0141                	addi	sp,sp,16
ffffffffc0203ae2:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0203ae4:	00002697          	auipc	a3,0x2
ffffffffc0203ae8:	52468693          	addi	a3,a3,1316 # ffffffffc0206008 <commands+0x1ad0>
ffffffffc0203aec:	00001617          	auipc	a2,0x1
ffffffffc0203af0:	43c60613          	addi	a2,a2,1084 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0203af4:	08300593          	li	a1,131
ffffffffc0203af8:	00002517          	auipc	a0,0x2
ffffffffc0203afc:	20050513          	addi	a0,a0,512 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc0203b00:	e06fc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(n > 0);
ffffffffc0203b04:	00002697          	auipc	a3,0x2
ffffffffc0203b08:	52c68693          	addi	a3,a3,1324 # ffffffffc0206030 <commands+0x1af8>
ffffffffc0203b0c:	00001617          	auipc	a2,0x1
ffffffffc0203b10:	41c60613          	addi	a2,a2,1052 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0203b14:	08000593          	li	a1,128
ffffffffc0203b18:	00002517          	auipc	a0,0x2
ffffffffc0203b1c:	1e050513          	addi	a0,a0,480 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc0203b20:	de6fc0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc0203b24 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0203b24:	cd51                	beqz	a0,ffffffffc0203bc0 <default_alloc_pages+0x9c>
    if (n > nr_free) {
ffffffffc0203b26:	0000e597          	auipc	a1,0xe
ffffffffc0203b2a:	a5a58593          	addi	a1,a1,-1446 # ffffffffc0211580 <free_area>
ffffffffc0203b2e:	0105a803          	lw	a6,16(a1)
ffffffffc0203b32:	862a                	mv	a2,a0
ffffffffc0203b34:	02081793          	slli	a5,a6,0x20
ffffffffc0203b38:	9381                	srli	a5,a5,0x20
ffffffffc0203b3a:	00a7ee63          	bltu	a5,a0,ffffffffc0203b56 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0203b3e:	87ae                	mv	a5,a1
ffffffffc0203b40:	a801                	j	ffffffffc0203b50 <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc0203b42:	ff87a703          	lw	a4,-8(a5)
ffffffffc0203b46:	02071693          	slli	a3,a4,0x20
ffffffffc0203b4a:	9281                	srli	a3,a3,0x20
ffffffffc0203b4c:	00c6f763          	bleu	a2,a3,ffffffffc0203b5a <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0203b50:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0203b52:	feb798e3          	bne	a5,a1,ffffffffc0203b42 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0203b56:	4501                	li	a0,0
}
ffffffffc0203b58:	8082                	ret
        struct Page *p = le2page(le, page_link);
ffffffffc0203b5a:	fe078513          	addi	a0,a5,-32
    if (page != NULL) {
ffffffffc0203b5e:	dd6d                	beqz	a0,ffffffffc0203b58 <default_alloc_pages+0x34>
    return listelm->prev;
ffffffffc0203b60:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0203b64:	0087b303          	ld	t1,8(a5)
    prev->next = next;
ffffffffc0203b68:	00060e1b          	sext.w	t3,a2
ffffffffc0203b6c:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc0203b70:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc0203b74:	02d67b63          	bleu	a3,a2,ffffffffc0203baa <default_alloc_pages+0x86>
            struct Page *p = page + n;
ffffffffc0203b78:	00361693          	slli	a3,a2,0x3
ffffffffc0203b7c:	96b2                	add	a3,a3,a2
ffffffffc0203b7e:	068e                	slli	a3,a3,0x3
ffffffffc0203b80:	96aa                	add	a3,a3,a0
            p->property = page->property - n;
ffffffffc0203b82:	41c7073b          	subw	a4,a4,t3
ffffffffc0203b86:	ce98                	sw	a4,24(a3)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0203b88:	00868613          	addi	a2,a3,8
ffffffffc0203b8c:	4709                	li	a4,2
ffffffffc0203b8e:	40e6302f          	amoor.d	zero,a4,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0203b92:	0088b703          	ld	a4,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0203b96:	02068613          	addi	a2,a3,32
    prev->next = next->prev = elm;
ffffffffc0203b9a:	0105a803          	lw	a6,16(a1)
ffffffffc0203b9e:	e310                	sd	a2,0(a4)
ffffffffc0203ba0:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0203ba4:	f698                	sd	a4,40(a3)
    elm->prev = prev;
ffffffffc0203ba6:	0316b023          	sd	a7,32(a3)
        nr_free -= n;
ffffffffc0203baa:	41c8083b          	subw	a6,a6,t3
ffffffffc0203bae:	0000e717          	auipc	a4,0xe
ffffffffc0203bb2:	9f072123          	sw	a6,-1566(a4) # ffffffffc0211590 <free_area+0x10>
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0203bb6:	5775                	li	a4,-3
ffffffffc0203bb8:	17a1                	addi	a5,a5,-24
ffffffffc0203bba:	60e7b02f          	amoand.d	zero,a4,(a5)
ffffffffc0203bbe:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0203bc0:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0203bc2:	00002697          	auipc	a3,0x2
ffffffffc0203bc6:	46e68693          	addi	a3,a3,1134 # ffffffffc0206030 <commands+0x1af8>
ffffffffc0203bca:	00001617          	auipc	a2,0x1
ffffffffc0203bce:	35e60613          	addi	a2,a2,862 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0203bd2:	06200593          	li	a1,98
ffffffffc0203bd6:	00002517          	auipc	a0,0x2
ffffffffc0203bda:	12250513          	addi	a0,a0,290 # ffffffffc0205cf8 <commands+0x17c0>
default_alloc_pages(size_t n) {
ffffffffc0203bde:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0203be0:	d26fc0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc0203be4 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0203be4:	1141                	addi	sp,sp,-16
ffffffffc0203be6:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0203be8:	c1fd                	beqz	a1,ffffffffc0203cce <default_init_memmap+0xea>
    for (; p != base + n; p ++) {
ffffffffc0203bea:	00359693          	slli	a3,a1,0x3
ffffffffc0203bee:	96ae                	add	a3,a3,a1
ffffffffc0203bf0:	068e                	slli	a3,a3,0x3
ffffffffc0203bf2:	96aa                	add	a3,a3,a0
ffffffffc0203bf4:	02d50463          	beq	a0,a3,ffffffffc0203c1c <default_init_memmap+0x38>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0203bf8:	6518                	ld	a4,8(a0)
        assert(PageReserved(p));
ffffffffc0203bfa:	87aa                	mv	a5,a0
ffffffffc0203bfc:	8b05                	andi	a4,a4,1
ffffffffc0203bfe:	e709                	bnez	a4,ffffffffc0203c08 <default_init_memmap+0x24>
ffffffffc0203c00:	a07d                	j	ffffffffc0203cae <default_init_memmap+0xca>
ffffffffc0203c02:	6798                	ld	a4,8(a5)
ffffffffc0203c04:	8b05                	andi	a4,a4,1
ffffffffc0203c06:	c745                	beqz	a4,ffffffffc0203cae <default_init_memmap+0xca>
        p->flags = p->property = 0;
ffffffffc0203c08:	0007ac23          	sw	zero,24(a5)
ffffffffc0203c0c:	0007b423          	sd	zero,8(a5)
ffffffffc0203c10:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0203c14:	04878793          	addi	a5,a5,72
ffffffffc0203c18:	fed795e3          	bne	a5,a3,ffffffffc0203c02 <default_init_memmap+0x1e>
    base->property = n;
ffffffffc0203c1c:	2581                	sext.w	a1,a1
ffffffffc0203c1e:	cd0c                	sw	a1,24(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0203c20:	4789                	li	a5,2
ffffffffc0203c22:	00850713          	addi	a4,a0,8
ffffffffc0203c26:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0203c2a:	0000e697          	auipc	a3,0xe
ffffffffc0203c2e:	95668693          	addi	a3,a3,-1706 # ffffffffc0211580 <free_area>
ffffffffc0203c32:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0203c34:	669c                	ld	a5,8(a3)
ffffffffc0203c36:	9db9                	addw	a1,a1,a4
ffffffffc0203c38:	0000e717          	auipc	a4,0xe
ffffffffc0203c3c:	94b72c23          	sw	a1,-1704(a4) # ffffffffc0211590 <free_area+0x10>
    if (list_empty(&free_list)) {
ffffffffc0203c40:	04d78a63          	beq	a5,a3,ffffffffc0203c94 <default_init_memmap+0xb0>
            struct Page* page = le2page(le, page_link);
ffffffffc0203c44:	fe078713          	addi	a4,a5,-32
ffffffffc0203c48:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0203c4a:	4801                	li	a6,0
ffffffffc0203c4c:	02050613          	addi	a2,a0,32
            if (base < page) {
ffffffffc0203c50:	00e56a63          	bltu	a0,a4,ffffffffc0203c64 <default_init_memmap+0x80>
    return listelm->next;
ffffffffc0203c54:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0203c56:	02d70563          	beq	a4,a3,ffffffffc0203c80 <default_init_memmap+0x9c>
        while ((le = list_next(le)) != &free_list) {
ffffffffc0203c5a:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0203c5c:	fe078713          	addi	a4,a5,-32
            if (base < page) {
ffffffffc0203c60:	fee57ae3          	bleu	a4,a0,ffffffffc0203c54 <default_init_memmap+0x70>
ffffffffc0203c64:	00080663          	beqz	a6,ffffffffc0203c70 <default_init_memmap+0x8c>
ffffffffc0203c68:	0000e717          	auipc	a4,0xe
ffffffffc0203c6c:	90b73c23          	sd	a1,-1768(a4) # ffffffffc0211580 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0203c70:	6398                	ld	a4,0(a5)
}
ffffffffc0203c72:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0203c74:	e390                	sd	a2,0(a5)
ffffffffc0203c76:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0203c78:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc0203c7a:	f118                	sd	a4,32(a0)
ffffffffc0203c7c:	0141                	addi	sp,sp,16
ffffffffc0203c7e:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0203c80:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0203c82:	f514                	sd	a3,40(a0)
ffffffffc0203c84:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0203c86:	f11c                	sd	a5,32(a0)
                list_add(le, &(base->page_link));
ffffffffc0203c88:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0203c8a:	00d70e63          	beq	a4,a3,ffffffffc0203ca6 <default_init_memmap+0xc2>
ffffffffc0203c8e:	4805                	li	a6,1
ffffffffc0203c90:	87ba                	mv	a5,a4
ffffffffc0203c92:	b7e9                	j	ffffffffc0203c5c <default_init_memmap+0x78>
}
ffffffffc0203c94:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0203c96:	02050713          	addi	a4,a0,32
    prev->next = next->prev = elm;
ffffffffc0203c9a:	e398                	sd	a4,0(a5)
ffffffffc0203c9c:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0203c9e:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc0203ca0:	f11c                	sd	a5,32(a0)
}
ffffffffc0203ca2:	0141                	addi	sp,sp,16
ffffffffc0203ca4:	8082                	ret
ffffffffc0203ca6:	60a2                	ld	ra,8(sp)
ffffffffc0203ca8:	e290                	sd	a2,0(a3)
ffffffffc0203caa:	0141                	addi	sp,sp,16
ffffffffc0203cac:	8082                	ret
        assert(PageReserved(p));
ffffffffc0203cae:	00002697          	auipc	a3,0x2
ffffffffc0203cb2:	38a68693          	addi	a3,a3,906 # ffffffffc0206038 <commands+0x1b00>
ffffffffc0203cb6:	00001617          	auipc	a2,0x1
ffffffffc0203cba:	27260613          	addi	a2,a2,626 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0203cbe:	04900593          	li	a1,73
ffffffffc0203cc2:	00002517          	auipc	a0,0x2
ffffffffc0203cc6:	03650513          	addi	a0,a0,54 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc0203cca:	c3cfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(n > 0);
ffffffffc0203cce:	00002697          	auipc	a3,0x2
ffffffffc0203cd2:	36268693          	addi	a3,a3,866 # ffffffffc0206030 <commands+0x1af8>
ffffffffc0203cd6:	00001617          	auipc	a2,0x1
ffffffffc0203cda:	25260613          	addi	a2,a2,594 # ffffffffc0204f28 <commands+0x9f0>
ffffffffc0203cde:	04600593          	li	a1,70
ffffffffc0203ce2:	00002517          	auipc	a0,0x2
ffffffffc0203ce6:	01650513          	addi	a0,a0,22 # ffffffffc0205cf8 <commands+0x17c0>
ffffffffc0203cea:	c1cfc0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc0203cee <swapfs_init>:
#include <ide.h>
#include <pmm.h>
#include <assert.h>

void
swapfs_init(void) {
ffffffffc0203cee:	1141                	addi	sp,sp,-16
    static_assert((PGSIZE % SECTSIZE) == 0);
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0203cf0:	4505                	li	a0,1
swapfs_init(void) {
ffffffffc0203cf2:	e406                	sd	ra,8(sp)
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0203cf4:	ee2fc0ef          	jal	ra,ffffffffc02003d6 <ide_device_valid>
ffffffffc0203cf8:	cd01                	beqz	a0,ffffffffc0203d10 <swapfs_init+0x22>
        panic("swap fs isn't available.\n");
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0203cfa:	4505                	li	a0,1
ffffffffc0203cfc:	ee0fc0ef          	jal	ra,ffffffffc02003dc <ide_device_size>
}
ffffffffc0203d00:	60a2                	ld	ra,8(sp)
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0203d02:	810d                	srli	a0,a0,0x3
ffffffffc0203d04:	0000e797          	auipc	a5,0xe
ffffffffc0203d08:	82a7be23          	sd	a0,-1988(a5) # ffffffffc0211540 <max_swap_offset>
}
ffffffffc0203d0c:	0141                	addi	sp,sp,16
ffffffffc0203d0e:	8082                	ret
        panic("swap fs isn't available.\n");
ffffffffc0203d10:	00002617          	auipc	a2,0x2
ffffffffc0203d14:	38860613          	addi	a2,a2,904 # ffffffffc0206098 <default_pmm_manager+0x50>
ffffffffc0203d18:	45b5                	li	a1,13
ffffffffc0203d1a:	00002517          	auipc	a0,0x2
ffffffffc0203d1e:	39e50513          	addi	a0,a0,926 # ffffffffc02060b8 <default_pmm_manager+0x70>
ffffffffc0203d22:	be4fc0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc0203d26 <swapfs_read>:

int
swapfs_read(swap_entry_t entry, struct Page *page) {
ffffffffc0203d26:	1141                	addi	sp,sp,-16
ffffffffc0203d28:	e406                	sd	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203d2a:	00855793          	srli	a5,a0,0x8
ffffffffc0203d2e:	c7b5                	beqz	a5,ffffffffc0203d9a <swapfs_read+0x74>
ffffffffc0203d30:	0000e717          	auipc	a4,0xe
ffffffffc0203d34:	81070713          	addi	a4,a4,-2032 # ffffffffc0211540 <max_swap_offset>
ffffffffc0203d38:	6318                	ld	a4,0(a4)
ffffffffc0203d3a:	06e7f063          	bleu	a4,a5,ffffffffc0203d9a <swapfs_read+0x74>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203d3e:	0000d717          	auipc	a4,0xd
ffffffffc0203d42:	75a70713          	addi	a4,a4,1882 # ffffffffc0211498 <pages>
ffffffffc0203d46:	6310                	ld	a2,0(a4)
ffffffffc0203d48:	00001717          	auipc	a4,0x1
ffffffffc0203d4c:	02870713          	addi	a4,a4,40 # ffffffffc0204d70 <commands+0x838>
ffffffffc0203d50:	00002697          	auipc	a3,0x2
ffffffffc0203d54:	5e868693          	addi	a3,a3,1512 # ffffffffc0206338 <nbase>
ffffffffc0203d58:	40c58633          	sub	a2,a1,a2
ffffffffc0203d5c:	630c                	ld	a1,0(a4)
ffffffffc0203d5e:	860d                	srai	a2,a2,0x3
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203d60:	0000d717          	auipc	a4,0xd
ffffffffc0203d64:	6f870713          	addi	a4,a4,1784 # ffffffffc0211458 <npage>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203d68:	02b60633          	mul	a2,a2,a1
ffffffffc0203d6c:	0037959b          	slliw	a1,a5,0x3
ffffffffc0203d70:	629c                	ld	a5,0(a3)
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203d72:	6318                	ld	a4,0(a4)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203d74:	963e                	add	a2,a2,a5
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203d76:	57fd                	li	a5,-1
ffffffffc0203d78:	83b1                	srli	a5,a5,0xc
ffffffffc0203d7a:	8ff1                	and	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0203d7c:	0632                	slli	a2,a2,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203d7e:	02e7fa63          	bleu	a4,a5,ffffffffc0203db2 <swapfs_read+0x8c>
ffffffffc0203d82:	0000d797          	auipc	a5,0xd
ffffffffc0203d86:	70678793          	addi	a5,a5,1798 # ffffffffc0211488 <va_pa_offset>
ffffffffc0203d8a:	639c                	ld	a5,0(a5)
}
ffffffffc0203d8c:	60a2                	ld	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203d8e:	46a1                	li	a3,8
ffffffffc0203d90:	963e                	add	a2,a2,a5
ffffffffc0203d92:	4505                	li	a0,1
}
ffffffffc0203d94:	0141                	addi	sp,sp,16
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203d96:	e4cfc06f          	j	ffffffffc02003e2 <ide_read_secs>
ffffffffc0203d9a:	86aa                	mv	a3,a0
ffffffffc0203d9c:	00002617          	auipc	a2,0x2
ffffffffc0203da0:	33460613          	addi	a2,a2,820 # ffffffffc02060d0 <default_pmm_manager+0x88>
ffffffffc0203da4:	45d1                	li	a1,20
ffffffffc0203da6:	00002517          	auipc	a0,0x2
ffffffffc0203daa:	31250513          	addi	a0,a0,786 # ffffffffc02060b8 <default_pmm_manager+0x70>
ffffffffc0203dae:	b58fc0ef          	jal	ra,ffffffffc0200106 <__panic>
ffffffffc0203db2:	86b2                	mv	a3,a2
ffffffffc0203db4:	06a00593          	li	a1,106
ffffffffc0203db8:	00001617          	auipc	a2,0x1
ffffffffc0203dbc:	fc060613          	addi	a2,a2,-64 # ffffffffc0204d78 <commands+0x840>
ffffffffc0203dc0:	00001517          	auipc	a0,0x1
ffffffffc0203dc4:	05050513          	addi	a0,a0,80 # ffffffffc0204e10 <commands+0x8d8>
ffffffffc0203dc8:	b3efc0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc0203dcc <swapfs_write>:

int
swapfs_write(swap_entry_t entry, struct Page *page) {
ffffffffc0203dcc:	1141                	addi	sp,sp,-16
ffffffffc0203dce:	e406                	sd	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203dd0:	00855793          	srli	a5,a0,0x8
ffffffffc0203dd4:	c7b5                	beqz	a5,ffffffffc0203e40 <swapfs_write+0x74>
ffffffffc0203dd6:	0000d717          	auipc	a4,0xd
ffffffffc0203dda:	76a70713          	addi	a4,a4,1898 # ffffffffc0211540 <max_swap_offset>
ffffffffc0203dde:	6318                	ld	a4,0(a4)
ffffffffc0203de0:	06e7f063          	bleu	a4,a5,ffffffffc0203e40 <swapfs_write+0x74>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203de4:	0000d717          	auipc	a4,0xd
ffffffffc0203de8:	6b470713          	addi	a4,a4,1716 # ffffffffc0211498 <pages>
ffffffffc0203dec:	6310                	ld	a2,0(a4)
ffffffffc0203dee:	00001717          	auipc	a4,0x1
ffffffffc0203df2:	f8270713          	addi	a4,a4,-126 # ffffffffc0204d70 <commands+0x838>
ffffffffc0203df6:	00002697          	auipc	a3,0x2
ffffffffc0203dfa:	54268693          	addi	a3,a3,1346 # ffffffffc0206338 <nbase>
ffffffffc0203dfe:	40c58633          	sub	a2,a1,a2
ffffffffc0203e02:	630c                	ld	a1,0(a4)
ffffffffc0203e04:	860d                	srai	a2,a2,0x3
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203e06:	0000d717          	auipc	a4,0xd
ffffffffc0203e0a:	65270713          	addi	a4,a4,1618 # ffffffffc0211458 <npage>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203e0e:	02b60633          	mul	a2,a2,a1
ffffffffc0203e12:	0037959b          	slliw	a1,a5,0x3
ffffffffc0203e16:	629c                	ld	a5,0(a3)
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203e18:	6318                	ld	a4,0(a4)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203e1a:	963e                	add	a2,a2,a5
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203e1c:	57fd                	li	a5,-1
ffffffffc0203e1e:	83b1                	srli	a5,a5,0xc
ffffffffc0203e20:	8ff1                	and	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0203e22:	0632                	slli	a2,a2,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203e24:	02e7fa63          	bleu	a4,a5,ffffffffc0203e58 <swapfs_write+0x8c>
ffffffffc0203e28:	0000d797          	auipc	a5,0xd
ffffffffc0203e2c:	66078793          	addi	a5,a5,1632 # ffffffffc0211488 <va_pa_offset>
ffffffffc0203e30:	639c                	ld	a5,0(a5)
}
ffffffffc0203e32:	60a2                	ld	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203e34:	46a1                	li	a3,8
ffffffffc0203e36:	963e                	add	a2,a2,a5
ffffffffc0203e38:	4505                	li	a0,1
}
ffffffffc0203e3a:	0141                	addi	sp,sp,16
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203e3c:	dcafc06f          	j	ffffffffc0200406 <ide_write_secs>
ffffffffc0203e40:	86aa                	mv	a3,a0
ffffffffc0203e42:	00002617          	auipc	a2,0x2
ffffffffc0203e46:	28e60613          	addi	a2,a2,654 # ffffffffc02060d0 <default_pmm_manager+0x88>
ffffffffc0203e4a:	45e5                	li	a1,25
ffffffffc0203e4c:	00002517          	auipc	a0,0x2
ffffffffc0203e50:	26c50513          	addi	a0,a0,620 # ffffffffc02060b8 <default_pmm_manager+0x70>
ffffffffc0203e54:	ab2fc0ef          	jal	ra,ffffffffc0200106 <__panic>
ffffffffc0203e58:	86b2                	mv	a3,a2
ffffffffc0203e5a:	06a00593          	li	a1,106
ffffffffc0203e5e:	00001617          	auipc	a2,0x1
ffffffffc0203e62:	f1a60613          	addi	a2,a2,-230 # ffffffffc0204d78 <commands+0x840>
ffffffffc0203e66:	00001517          	auipc	a0,0x1
ffffffffc0203e6a:	faa50513          	addi	a0,a0,-86 # ffffffffc0204e10 <commands+0x8d8>
ffffffffc0203e6e:	a98fc0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc0203e72 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0203e72:	00054783          	lbu	a5,0(a0)
ffffffffc0203e76:	cb91                	beqz	a5,ffffffffc0203e8a <strlen+0x18>
    size_t cnt = 0;
ffffffffc0203e78:	4781                	li	a5,0
        cnt ++;
ffffffffc0203e7a:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc0203e7c:	00f50733          	add	a4,a0,a5
ffffffffc0203e80:	00074703          	lbu	a4,0(a4)
ffffffffc0203e84:	fb7d                	bnez	a4,ffffffffc0203e7a <strlen+0x8>
    }
    return cnt;
}
ffffffffc0203e86:	853e                	mv	a0,a5
ffffffffc0203e88:	8082                	ret
    size_t cnt = 0;
ffffffffc0203e8a:	4781                	li	a5,0
}
ffffffffc0203e8c:	853e                	mv	a0,a5
ffffffffc0203e8e:	8082                	ret

ffffffffc0203e90 <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203e90:	c185                	beqz	a1,ffffffffc0203eb0 <strnlen+0x20>
ffffffffc0203e92:	00054783          	lbu	a5,0(a0)
ffffffffc0203e96:	cf89                	beqz	a5,ffffffffc0203eb0 <strnlen+0x20>
    size_t cnt = 0;
ffffffffc0203e98:	4781                	li	a5,0
ffffffffc0203e9a:	a021                	j	ffffffffc0203ea2 <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203e9c:	00074703          	lbu	a4,0(a4)
ffffffffc0203ea0:	c711                	beqz	a4,ffffffffc0203eac <strnlen+0x1c>
        cnt ++;
ffffffffc0203ea2:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203ea4:	00f50733          	add	a4,a0,a5
ffffffffc0203ea8:	fef59ae3          	bne	a1,a5,ffffffffc0203e9c <strnlen+0xc>
    }
    return cnt;
}
ffffffffc0203eac:	853e                	mv	a0,a5
ffffffffc0203eae:	8082                	ret
    size_t cnt = 0;
ffffffffc0203eb0:	4781                	li	a5,0
}
ffffffffc0203eb2:	853e                	mv	a0,a5
ffffffffc0203eb4:	8082                	ret

ffffffffc0203eb6 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0203eb6:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0203eb8:	0585                	addi	a1,a1,1
ffffffffc0203eba:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0203ebe:	0785                	addi	a5,a5,1
ffffffffc0203ec0:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0203ec4:	fb75                	bnez	a4,ffffffffc0203eb8 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0203ec6:	8082                	ret

ffffffffc0203ec8 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203ec8:	00054783          	lbu	a5,0(a0)
ffffffffc0203ecc:	0005c703          	lbu	a4,0(a1)
ffffffffc0203ed0:	cb91                	beqz	a5,ffffffffc0203ee4 <strcmp+0x1c>
ffffffffc0203ed2:	00e79c63          	bne	a5,a4,ffffffffc0203eea <strcmp+0x22>
        s1 ++, s2 ++;
ffffffffc0203ed6:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203ed8:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
ffffffffc0203edc:	0585                	addi	a1,a1,1
ffffffffc0203ede:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203ee2:	fbe5                	bnez	a5,ffffffffc0203ed2 <strcmp+0xa>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203ee4:	4501                	li	a0,0
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0203ee6:	9d19                	subw	a0,a0,a4
ffffffffc0203ee8:	8082                	ret
ffffffffc0203eea:	0007851b          	sext.w	a0,a5
ffffffffc0203eee:	9d19                	subw	a0,a0,a4
ffffffffc0203ef0:	8082                	ret

ffffffffc0203ef2 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0203ef2:	00054783          	lbu	a5,0(a0)
ffffffffc0203ef6:	cb91                	beqz	a5,ffffffffc0203f0a <strchr+0x18>
        if (*s == c) {
ffffffffc0203ef8:	00b79563          	bne	a5,a1,ffffffffc0203f02 <strchr+0x10>
ffffffffc0203efc:	a809                	j	ffffffffc0203f0e <strchr+0x1c>
ffffffffc0203efe:	00b78763          	beq	a5,a1,ffffffffc0203f0c <strchr+0x1a>
            return (char *)s;
        }
        s ++;
ffffffffc0203f02:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0203f04:	00054783          	lbu	a5,0(a0)
ffffffffc0203f08:	fbfd                	bnez	a5,ffffffffc0203efe <strchr+0xc>
    }
    return NULL;
ffffffffc0203f0a:	4501                	li	a0,0
}
ffffffffc0203f0c:	8082                	ret
ffffffffc0203f0e:	8082                	ret

ffffffffc0203f10 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0203f10:	ca01                	beqz	a2,ffffffffc0203f20 <memset+0x10>
ffffffffc0203f12:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0203f14:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0203f16:	0785                	addi	a5,a5,1
ffffffffc0203f18:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0203f1c:	fec79de3          	bne	a5,a2,ffffffffc0203f16 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0203f20:	8082                	ret

ffffffffc0203f22 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0203f22:	ca19                	beqz	a2,ffffffffc0203f38 <memcpy+0x16>
ffffffffc0203f24:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0203f26:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0203f28:	0585                	addi	a1,a1,1
ffffffffc0203f2a:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0203f2e:	0785                	addi	a5,a5,1
ffffffffc0203f30:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0203f34:	fec59ae3          	bne	a1,a2,ffffffffc0203f28 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0203f38:	8082                	ret

ffffffffc0203f3a <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0203f3a:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203f3e:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0203f40:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203f44:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0203f46:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203f4a:	f022                	sd	s0,32(sp)
ffffffffc0203f4c:	ec26                	sd	s1,24(sp)
ffffffffc0203f4e:	e84a                	sd	s2,16(sp)
ffffffffc0203f50:	f406                	sd	ra,40(sp)
ffffffffc0203f52:	e44e                	sd	s3,8(sp)
ffffffffc0203f54:	84aa                	mv	s1,a0
ffffffffc0203f56:	892e                	mv	s2,a1
ffffffffc0203f58:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0203f5c:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
ffffffffc0203f5e:	03067e63          	bleu	a6,a2,ffffffffc0203f9a <printnum+0x60>
ffffffffc0203f62:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0203f64:	00805763          	blez	s0,ffffffffc0203f72 <printnum+0x38>
ffffffffc0203f68:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0203f6a:	85ca                	mv	a1,s2
ffffffffc0203f6c:	854e                	mv	a0,s3
ffffffffc0203f6e:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0203f70:	fc65                	bnez	s0,ffffffffc0203f68 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203f72:	1a02                	slli	s4,s4,0x20
ffffffffc0203f74:	020a5a13          	srli	s4,s4,0x20
ffffffffc0203f78:	00002797          	auipc	a5,0x2
ffffffffc0203f7c:	30878793          	addi	a5,a5,776 # ffffffffc0206280 <error_string+0x38>
ffffffffc0203f80:	9a3e                	add	s4,s4,a5
}
ffffffffc0203f82:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203f84:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0203f88:	70a2                	ld	ra,40(sp)
ffffffffc0203f8a:	69a2                	ld	s3,8(sp)
ffffffffc0203f8c:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203f8e:	85ca                	mv	a1,s2
ffffffffc0203f90:	8326                	mv	t1,s1
}
ffffffffc0203f92:	6942                	ld	s2,16(sp)
ffffffffc0203f94:	64e2                	ld	s1,24(sp)
ffffffffc0203f96:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203f98:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0203f9a:	03065633          	divu	a2,a2,a6
ffffffffc0203f9e:	8722                	mv	a4,s0
ffffffffc0203fa0:	f9bff0ef          	jal	ra,ffffffffc0203f3a <printnum>
ffffffffc0203fa4:	b7f9                	j	ffffffffc0203f72 <printnum+0x38>

ffffffffc0203fa6 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0203fa6:	7119                	addi	sp,sp,-128
ffffffffc0203fa8:	f4a6                	sd	s1,104(sp)
ffffffffc0203faa:	f0ca                	sd	s2,96(sp)
ffffffffc0203fac:	e8d2                	sd	s4,80(sp)
ffffffffc0203fae:	e4d6                	sd	s5,72(sp)
ffffffffc0203fb0:	e0da                	sd	s6,64(sp)
ffffffffc0203fb2:	fc5e                	sd	s7,56(sp)
ffffffffc0203fb4:	f862                	sd	s8,48(sp)
ffffffffc0203fb6:	f06a                	sd	s10,32(sp)
ffffffffc0203fb8:	fc86                	sd	ra,120(sp)
ffffffffc0203fba:	f8a2                	sd	s0,112(sp)
ffffffffc0203fbc:	ecce                	sd	s3,88(sp)
ffffffffc0203fbe:	f466                	sd	s9,40(sp)
ffffffffc0203fc0:	ec6e                	sd	s11,24(sp)
ffffffffc0203fc2:	892a                	mv	s2,a0
ffffffffc0203fc4:	84ae                	mv	s1,a1
ffffffffc0203fc6:	8d32                	mv	s10,a2
ffffffffc0203fc8:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0203fca:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203fcc:	00002a17          	auipc	s4,0x2
ffffffffc0203fd0:	124a0a13          	addi	s4,s4,292 # ffffffffc02060f0 <default_pmm_manager+0xa8>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203fd4:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203fd8:	00002c17          	auipc	s8,0x2
ffffffffc0203fdc:	270c0c13          	addi	s8,s8,624 # ffffffffc0206248 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203fe0:	000d4503          	lbu	a0,0(s10)
ffffffffc0203fe4:	02500793          	li	a5,37
ffffffffc0203fe8:	001d0413          	addi	s0,s10,1
ffffffffc0203fec:	00f50e63          	beq	a0,a5,ffffffffc0204008 <vprintfmt+0x62>
            if (ch == '\0') {
ffffffffc0203ff0:	c521                	beqz	a0,ffffffffc0204038 <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203ff2:	02500993          	li	s3,37
ffffffffc0203ff6:	a011                	j	ffffffffc0203ffa <vprintfmt+0x54>
            if (ch == '\0') {
ffffffffc0203ff8:	c121                	beqz	a0,ffffffffc0204038 <vprintfmt+0x92>
            putch(ch, putdat);
ffffffffc0203ffa:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203ffc:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0203ffe:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204000:	fff44503          	lbu	a0,-1(s0)
ffffffffc0204004:	ff351ae3          	bne	a0,s3,ffffffffc0203ff8 <vprintfmt+0x52>
ffffffffc0204008:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc020400c:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0204010:	4981                	li	s3,0
ffffffffc0204012:	4801                	li	a6,0
        width = precision = -1;
ffffffffc0204014:	5cfd                	li	s9,-1
ffffffffc0204016:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204018:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
ffffffffc020401c:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020401e:	fdd6069b          	addiw	a3,a2,-35
ffffffffc0204022:	0ff6f693          	andi	a3,a3,255
ffffffffc0204026:	00140d13          	addi	s10,s0,1
ffffffffc020402a:	20d5e563          	bltu	a1,a3,ffffffffc0204234 <vprintfmt+0x28e>
ffffffffc020402e:	068a                	slli	a3,a3,0x2
ffffffffc0204030:	96d2                	add	a3,a3,s4
ffffffffc0204032:	4294                	lw	a3,0(a3)
ffffffffc0204034:	96d2                	add	a3,a3,s4
ffffffffc0204036:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0204038:	70e6                	ld	ra,120(sp)
ffffffffc020403a:	7446                	ld	s0,112(sp)
ffffffffc020403c:	74a6                	ld	s1,104(sp)
ffffffffc020403e:	7906                	ld	s2,96(sp)
ffffffffc0204040:	69e6                	ld	s3,88(sp)
ffffffffc0204042:	6a46                	ld	s4,80(sp)
ffffffffc0204044:	6aa6                	ld	s5,72(sp)
ffffffffc0204046:	6b06                	ld	s6,64(sp)
ffffffffc0204048:	7be2                	ld	s7,56(sp)
ffffffffc020404a:	7c42                	ld	s8,48(sp)
ffffffffc020404c:	7ca2                	ld	s9,40(sp)
ffffffffc020404e:	7d02                	ld	s10,32(sp)
ffffffffc0204050:	6de2                	ld	s11,24(sp)
ffffffffc0204052:	6109                	addi	sp,sp,128
ffffffffc0204054:	8082                	ret
    if (lflag >= 2) {
ffffffffc0204056:	4705                	li	a4,1
ffffffffc0204058:	008a8593          	addi	a1,s5,8
ffffffffc020405c:	01074463          	blt	a4,a6,ffffffffc0204064 <vprintfmt+0xbe>
    else if (lflag) {
ffffffffc0204060:	26080363          	beqz	a6,ffffffffc02042c6 <vprintfmt+0x320>
        return va_arg(*ap, unsigned long);
ffffffffc0204064:	000ab603          	ld	a2,0(s5)
ffffffffc0204068:	46c1                	li	a3,16
ffffffffc020406a:	8aae                	mv	s5,a1
ffffffffc020406c:	a06d                	j	ffffffffc0204116 <vprintfmt+0x170>
            goto reswitch;
ffffffffc020406e:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0204072:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204074:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0204076:	b765                	j	ffffffffc020401e <vprintfmt+0x78>
            putch(va_arg(ap, int), putdat);
ffffffffc0204078:	000aa503          	lw	a0,0(s5)
ffffffffc020407c:	85a6                	mv	a1,s1
ffffffffc020407e:	0aa1                	addi	s5,s5,8
ffffffffc0204080:	9902                	jalr	s2
            break;
ffffffffc0204082:	bfb9                	j	ffffffffc0203fe0 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0204084:	4705                	li	a4,1
ffffffffc0204086:	008a8993          	addi	s3,s5,8
ffffffffc020408a:	01074463          	blt	a4,a6,ffffffffc0204092 <vprintfmt+0xec>
    else if (lflag) {
ffffffffc020408e:	22080463          	beqz	a6,ffffffffc02042b6 <vprintfmt+0x310>
        return va_arg(*ap, long);
ffffffffc0204092:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
ffffffffc0204096:	24044463          	bltz	s0,ffffffffc02042de <vprintfmt+0x338>
            num = getint(&ap, lflag);
ffffffffc020409a:	8622                	mv	a2,s0
ffffffffc020409c:	8ace                	mv	s5,s3
ffffffffc020409e:	46a9                	li	a3,10
ffffffffc02040a0:	a89d                	j	ffffffffc0204116 <vprintfmt+0x170>
            err = va_arg(ap, int);
ffffffffc02040a2:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02040a6:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc02040a8:	0aa1                	addi	s5,s5,8
            if (err < 0) {
ffffffffc02040aa:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02040ae:	8fb5                	xor	a5,a5,a3
ffffffffc02040b0:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02040b4:	1ad74363          	blt	a4,a3,ffffffffc020425a <vprintfmt+0x2b4>
ffffffffc02040b8:	00369793          	slli	a5,a3,0x3
ffffffffc02040bc:	97e2                	add	a5,a5,s8
ffffffffc02040be:	639c                	ld	a5,0(a5)
ffffffffc02040c0:	18078d63          	beqz	a5,ffffffffc020425a <vprintfmt+0x2b4>
                printfmt(putch, putdat, "%s", p);
ffffffffc02040c4:	86be                	mv	a3,a5
ffffffffc02040c6:	00002617          	auipc	a2,0x2
ffffffffc02040ca:	26a60613          	addi	a2,a2,618 # ffffffffc0206330 <error_string+0xe8>
ffffffffc02040ce:	85a6                	mv	a1,s1
ffffffffc02040d0:	854a                	mv	a0,s2
ffffffffc02040d2:	240000ef          	jal	ra,ffffffffc0204312 <printfmt>
ffffffffc02040d6:	b729                	j	ffffffffc0203fe0 <vprintfmt+0x3a>
            lflag ++;
ffffffffc02040d8:	00144603          	lbu	a2,1(s0)
ffffffffc02040dc:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02040de:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02040e0:	bf3d                	j	ffffffffc020401e <vprintfmt+0x78>
    if (lflag >= 2) {
ffffffffc02040e2:	4705                	li	a4,1
ffffffffc02040e4:	008a8593          	addi	a1,s5,8
ffffffffc02040e8:	01074463          	blt	a4,a6,ffffffffc02040f0 <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc02040ec:	1e080263          	beqz	a6,ffffffffc02042d0 <vprintfmt+0x32a>
        return va_arg(*ap, unsigned long);
ffffffffc02040f0:	000ab603          	ld	a2,0(s5)
ffffffffc02040f4:	46a1                	li	a3,8
ffffffffc02040f6:	8aae                	mv	s5,a1
ffffffffc02040f8:	a839                	j	ffffffffc0204116 <vprintfmt+0x170>
            putch('0', putdat);
ffffffffc02040fa:	03000513          	li	a0,48
ffffffffc02040fe:	85a6                	mv	a1,s1
ffffffffc0204100:	e03e                	sd	a5,0(sp)
ffffffffc0204102:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0204104:	85a6                	mv	a1,s1
ffffffffc0204106:	07800513          	li	a0,120
ffffffffc020410a:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020410c:	0aa1                	addi	s5,s5,8
ffffffffc020410e:	ff8ab603          	ld	a2,-8(s5)
            goto number;
ffffffffc0204112:	6782                	ld	a5,0(sp)
ffffffffc0204114:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0204116:	876e                	mv	a4,s11
ffffffffc0204118:	85a6                	mv	a1,s1
ffffffffc020411a:	854a                	mv	a0,s2
ffffffffc020411c:	e1fff0ef          	jal	ra,ffffffffc0203f3a <printnum>
            break;
ffffffffc0204120:	b5c1                	j	ffffffffc0203fe0 <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0204122:	000ab603          	ld	a2,0(s5)
ffffffffc0204126:	0aa1                	addi	s5,s5,8
ffffffffc0204128:	1c060663          	beqz	a2,ffffffffc02042f4 <vprintfmt+0x34e>
            if (width > 0 && padc != '-') {
ffffffffc020412c:	00160413          	addi	s0,a2,1
ffffffffc0204130:	17b05c63          	blez	s11,ffffffffc02042a8 <vprintfmt+0x302>
ffffffffc0204134:	02d00593          	li	a1,45
ffffffffc0204138:	14b79263          	bne	a5,a1,ffffffffc020427c <vprintfmt+0x2d6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020413c:	00064783          	lbu	a5,0(a2)
ffffffffc0204140:	0007851b          	sext.w	a0,a5
ffffffffc0204144:	c905                	beqz	a0,ffffffffc0204174 <vprintfmt+0x1ce>
ffffffffc0204146:	000cc563          	bltz	s9,ffffffffc0204150 <vprintfmt+0x1aa>
ffffffffc020414a:	3cfd                	addiw	s9,s9,-1
ffffffffc020414c:	036c8263          	beq	s9,s6,ffffffffc0204170 <vprintfmt+0x1ca>
                    putch('?', putdat);
ffffffffc0204150:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0204152:	18098463          	beqz	s3,ffffffffc02042da <vprintfmt+0x334>
ffffffffc0204156:	3781                	addiw	a5,a5,-32
ffffffffc0204158:	18fbf163          	bleu	a5,s7,ffffffffc02042da <vprintfmt+0x334>
                    putch('?', putdat);
ffffffffc020415c:	03f00513          	li	a0,63
ffffffffc0204160:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204162:	0405                	addi	s0,s0,1
ffffffffc0204164:	fff44783          	lbu	a5,-1(s0)
ffffffffc0204168:	3dfd                	addiw	s11,s11,-1
ffffffffc020416a:	0007851b          	sext.w	a0,a5
ffffffffc020416e:	fd61                	bnez	a0,ffffffffc0204146 <vprintfmt+0x1a0>
            for (; width > 0; width --) {
ffffffffc0204170:	e7b058e3          	blez	s11,ffffffffc0203fe0 <vprintfmt+0x3a>
ffffffffc0204174:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0204176:	85a6                	mv	a1,s1
ffffffffc0204178:	02000513          	li	a0,32
ffffffffc020417c:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc020417e:	e60d81e3          	beqz	s11,ffffffffc0203fe0 <vprintfmt+0x3a>
ffffffffc0204182:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0204184:	85a6                	mv	a1,s1
ffffffffc0204186:	02000513          	li	a0,32
ffffffffc020418a:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc020418c:	fe0d94e3          	bnez	s11,ffffffffc0204174 <vprintfmt+0x1ce>
ffffffffc0204190:	bd81                	j	ffffffffc0203fe0 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0204192:	4705                	li	a4,1
ffffffffc0204194:	008a8593          	addi	a1,s5,8
ffffffffc0204198:	01074463          	blt	a4,a6,ffffffffc02041a0 <vprintfmt+0x1fa>
    else if (lflag) {
ffffffffc020419c:	12080063          	beqz	a6,ffffffffc02042bc <vprintfmt+0x316>
        return va_arg(*ap, unsigned long);
ffffffffc02041a0:	000ab603          	ld	a2,0(s5)
ffffffffc02041a4:	46a9                	li	a3,10
ffffffffc02041a6:	8aae                	mv	s5,a1
ffffffffc02041a8:	b7bd                	j	ffffffffc0204116 <vprintfmt+0x170>
ffffffffc02041aa:	00144603          	lbu	a2,1(s0)
            padc = '-';
ffffffffc02041ae:	02d00793          	li	a5,45
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02041b2:	846a                	mv	s0,s10
ffffffffc02041b4:	b5ad                	j	ffffffffc020401e <vprintfmt+0x78>
            putch(ch, putdat);
ffffffffc02041b6:	85a6                	mv	a1,s1
ffffffffc02041b8:	02500513          	li	a0,37
ffffffffc02041bc:	9902                	jalr	s2
            break;
ffffffffc02041be:	b50d                	j	ffffffffc0203fe0 <vprintfmt+0x3a>
            precision = va_arg(ap, int);
ffffffffc02041c0:	000aac83          	lw	s9,0(s5)
            goto process_precision;
ffffffffc02041c4:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02041c8:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02041ca:	846a                	mv	s0,s10
            if (width < 0)
ffffffffc02041cc:	e40dd9e3          	bgez	s11,ffffffffc020401e <vprintfmt+0x78>
                width = precision, precision = -1;
ffffffffc02041d0:	8de6                	mv	s11,s9
ffffffffc02041d2:	5cfd                	li	s9,-1
ffffffffc02041d4:	b5a9                	j	ffffffffc020401e <vprintfmt+0x78>
            goto reswitch;
ffffffffc02041d6:	00144603          	lbu	a2,1(s0)
            padc = '0';
ffffffffc02041da:	03000793          	li	a5,48
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02041de:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02041e0:	bd3d                	j	ffffffffc020401e <vprintfmt+0x78>
                precision = precision * 10 + ch - '0';
ffffffffc02041e2:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
ffffffffc02041e6:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02041ea:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02041ec:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02041f0:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc02041f4:	fcd56ce3          	bltu	a0,a3,ffffffffc02041cc <vprintfmt+0x226>
            for (precision = 0; ; ++ fmt) {
ffffffffc02041f8:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02041fa:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
ffffffffc02041fe:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0204202:	0196873b          	addw	a4,a3,s9
ffffffffc0204206:	0017171b          	slliw	a4,a4,0x1
ffffffffc020420a:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
ffffffffc020420e:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
ffffffffc0204212:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0204216:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc020421a:	fcd57fe3          	bleu	a3,a0,ffffffffc02041f8 <vprintfmt+0x252>
ffffffffc020421e:	b77d                	j	ffffffffc02041cc <vprintfmt+0x226>
            if (width < 0)
ffffffffc0204220:	fffdc693          	not	a3,s11
ffffffffc0204224:	96fd                	srai	a3,a3,0x3f
ffffffffc0204226:	00ddfdb3          	and	s11,s11,a3
ffffffffc020422a:	00144603          	lbu	a2,1(s0)
ffffffffc020422e:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204230:	846a                	mv	s0,s10
ffffffffc0204232:	b3f5                	j	ffffffffc020401e <vprintfmt+0x78>
            putch('%', putdat);
ffffffffc0204234:	85a6                	mv	a1,s1
ffffffffc0204236:	02500513          	li	a0,37
ffffffffc020423a:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc020423c:	fff44703          	lbu	a4,-1(s0)
ffffffffc0204240:	02500793          	li	a5,37
ffffffffc0204244:	8d22                	mv	s10,s0
ffffffffc0204246:	d8f70de3          	beq	a4,a5,ffffffffc0203fe0 <vprintfmt+0x3a>
ffffffffc020424a:	02500713          	li	a4,37
ffffffffc020424e:	1d7d                	addi	s10,s10,-1
ffffffffc0204250:	fffd4783          	lbu	a5,-1(s10)
ffffffffc0204254:	fee79de3          	bne	a5,a4,ffffffffc020424e <vprintfmt+0x2a8>
ffffffffc0204258:	b361                	j	ffffffffc0203fe0 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc020425a:	00002617          	auipc	a2,0x2
ffffffffc020425e:	0c660613          	addi	a2,a2,198 # ffffffffc0206320 <error_string+0xd8>
ffffffffc0204262:	85a6                	mv	a1,s1
ffffffffc0204264:	854a                	mv	a0,s2
ffffffffc0204266:	0ac000ef          	jal	ra,ffffffffc0204312 <printfmt>
ffffffffc020426a:	bb9d                	j	ffffffffc0203fe0 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc020426c:	00002617          	auipc	a2,0x2
ffffffffc0204270:	0ac60613          	addi	a2,a2,172 # ffffffffc0206318 <error_string+0xd0>
            if (width > 0 && padc != '-') {
ffffffffc0204274:	00002417          	auipc	s0,0x2
ffffffffc0204278:	0a540413          	addi	s0,s0,165 # ffffffffc0206319 <error_string+0xd1>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020427c:	8532                	mv	a0,a2
ffffffffc020427e:	85e6                	mv	a1,s9
ffffffffc0204280:	e032                	sd	a2,0(sp)
ffffffffc0204282:	e43e                	sd	a5,8(sp)
ffffffffc0204284:	c0dff0ef          	jal	ra,ffffffffc0203e90 <strnlen>
ffffffffc0204288:	40ad8dbb          	subw	s11,s11,a0
ffffffffc020428c:	6602                	ld	a2,0(sp)
ffffffffc020428e:	01b05d63          	blez	s11,ffffffffc02042a8 <vprintfmt+0x302>
ffffffffc0204292:	67a2                	ld	a5,8(sp)
ffffffffc0204294:	2781                	sext.w	a5,a5
ffffffffc0204296:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
ffffffffc0204298:	6522                	ld	a0,8(sp)
ffffffffc020429a:	85a6                	mv	a1,s1
ffffffffc020429c:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020429e:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc02042a0:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02042a2:	6602                	ld	a2,0(sp)
ffffffffc02042a4:	fe0d9ae3          	bnez	s11,ffffffffc0204298 <vprintfmt+0x2f2>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02042a8:	00064783          	lbu	a5,0(a2)
ffffffffc02042ac:	0007851b          	sext.w	a0,a5
ffffffffc02042b0:	e8051be3          	bnez	a0,ffffffffc0204146 <vprintfmt+0x1a0>
ffffffffc02042b4:	b335                	j	ffffffffc0203fe0 <vprintfmt+0x3a>
        return va_arg(*ap, int);
ffffffffc02042b6:	000aa403          	lw	s0,0(s5)
ffffffffc02042ba:	bbf1                	j	ffffffffc0204096 <vprintfmt+0xf0>
        return va_arg(*ap, unsigned int);
ffffffffc02042bc:	000ae603          	lwu	a2,0(s5)
ffffffffc02042c0:	46a9                	li	a3,10
ffffffffc02042c2:	8aae                	mv	s5,a1
ffffffffc02042c4:	bd89                	j	ffffffffc0204116 <vprintfmt+0x170>
ffffffffc02042c6:	000ae603          	lwu	a2,0(s5)
ffffffffc02042ca:	46c1                	li	a3,16
ffffffffc02042cc:	8aae                	mv	s5,a1
ffffffffc02042ce:	b5a1                	j	ffffffffc0204116 <vprintfmt+0x170>
ffffffffc02042d0:	000ae603          	lwu	a2,0(s5)
ffffffffc02042d4:	46a1                	li	a3,8
ffffffffc02042d6:	8aae                	mv	s5,a1
ffffffffc02042d8:	bd3d                	j	ffffffffc0204116 <vprintfmt+0x170>
                    putch(ch, putdat);
ffffffffc02042da:	9902                	jalr	s2
ffffffffc02042dc:	b559                	j	ffffffffc0204162 <vprintfmt+0x1bc>
                putch('-', putdat);
ffffffffc02042de:	85a6                	mv	a1,s1
ffffffffc02042e0:	02d00513          	li	a0,45
ffffffffc02042e4:	e03e                	sd	a5,0(sp)
ffffffffc02042e6:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02042e8:	8ace                	mv	s5,s3
ffffffffc02042ea:	40800633          	neg	a2,s0
ffffffffc02042ee:	46a9                	li	a3,10
ffffffffc02042f0:	6782                	ld	a5,0(sp)
ffffffffc02042f2:	b515                	j	ffffffffc0204116 <vprintfmt+0x170>
            if (width > 0 && padc != '-') {
ffffffffc02042f4:	01b05663          	blez	s11,ffffffffc0204300 <vprintfmt+0x35a>
ffffffffc02042f8:	02d00693          	li	a3,45
ffffffffc02042fc:	f6d798e3          	bne	a5,a3,ffffffffc020426c <vprintfmt+0x2c6>
ffffffffc0204300:	00002417          	auipc	s0,0x2
ffffffffc0204304:	01940413          	addi	s0,s0,25 # ffffffffc0206319 <error_string+0xd1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204308:	02800513          	li	a0,40
ffffffffc020430c:	02800793          	li	a5,40
ffffffffc0204310:	bd1d                	j	ffffffffc0204146 <vprintfmt+0x1a0>

ffffffffc0204312 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204312:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0204314:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204318:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020431a:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020431c:	ec06                	sd	ra,24(sp)
ffffffffc020431e:	f83a                	sd	a4,48(sp)
ffffffffc0204320:	fc3e                	sd	a5,56(sp)
ffffffffc0204322:	e0c2                	sd	a6,64(sp)
ffffffffc0204324:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0204326:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0204328:	c7fff0ef          	jal	ra,ffffffffc0203fa6 <vprintfmt>
}
ffffffffc020432c:	60e2                	ld	ra,24(sp)
ffffffffc020432e:	6161                	addi	sp,sp,80
ffffffffc0204330:	8082                	ret

ffffffffc0204332 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0204332:	715d                	addi	sp,sp,-80
ffffffffc0204334:	e486                	sd	ra,72(sp)
ffffffffc0204336:	e0a2                	sd	s0,64(sp)
ffffffffc0204338:	fc26                	sd	s1,56(sp)
ffffffffc020433a:	f84a                	sd	s2,48(sp)
ffffffffc020433c:	f44e                	sd	s3,40(sp)
ffffffffc020433e:	f052                	sd	s4,32(sp)
ffffffffc0204340:	ec56                	sd	s5,24(sp)
ffffffffc0204342:	e85a                	sd	s6,16(sp)
ffffffffc0204344:	e45e                	sd	s7,8(sp)
    if (prompt != NULL) {
ffffffffc0204346:	c901                	beqz	a0,ffffffffc0204356 <readline+0x24>
        cprintf("%s", prompt);
ffffffffc0204348:	85aa                	mv	a1,a0
ffffffffc020434a:	00002517          	auipc	a0,0x2
ffffffffc020434e:	fe650513          	addi	a0,a0,-26 # ffffffffc0206330 <error_string+0xe8>
ffffffffc0204352:	d6dfb0ef          	jal	ra,ffffffffc02000be <cprintf>
readline(const char *prompt) {
ffffffffc0204356:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0204358:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc020435a:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc020435c:	4aa9                	li	s5,10
ffffffffc020435e:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0204360:	0000db97          	auipc	s7,0xd
ffffffffc0204364:	ce0b8b93          	addi	s7,s7,-800 # ffffffffc0211040 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0204368:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc020436c:	d8bfb0ef          	jal	ra,ffffffffc02000f6 <getchar>
ffffffffc0204370:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0204372:	00054b63          	bltz	a0,ffffffffc0204388 <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0204376:	00a95b63          	ble	a0,s2,ffffffffc020438c <readline+0x5a>
ffffffffc020437a:	029a5463          	ble	s1,s4,ffffffffc02043a2 <readline+0x70>
        c = getchar();
ffffffffc020437e:	d79fb0ef          	jal	ra,ffffffffc02000f6 <getchar>
ffffffffc0204382:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0204384:	fe0559e3          	bgez	a0,ffffffffc0204376 <readline+0x44>
            return NULL;
ffffffffc0204388:	4501                	li	a0,0
ffffffffc020438a:	a099                	j	ffffffffc02043d0 <readline+0x9e>
        else if (c == '\b' && i > 0) {
ffffffffc020438c:	03341463          	bne	s0,s3,ffffffffc02043b4 <readline+0x82>
ffffffffc0204390:	e8b9                	bnez	s1,ffffffffc02043e6 <readline+0xb4>
        c = getchar();
ffffffffc0204392:	d65fb0ef          	jal	ra,ffffffffc02000f6 <getchar>
ffffffffc0204396:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0204398:	fe0548e3          	bltz	a0,ffffffffc0204388 <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020439c:	fea958e3          	ble	a0,s2,ffffffffc020438c <readline+0x5a>
ffffffffc02043a0:	4481                	li	s1,0
            cputchar(c);
ffffffffc02043a2:	8522                	mv	a0,s0
ffffffffc02043a4:	d4ffb0ef          	jal	ra,ffffffffc02000f2 <cputchar>
            buf[i ++] = c;
ffffffffc02043a8:	009b87b3          	add	a5,s7,s1
ffffffffc02043ac:	00878023          	sb	s0,0(a5)
ffffffffc02043b0:	2485                	addiw	s1,s1,1
ffffffffc02043b2:	bf6d                	j	ffffffffc020436c <readline+0x3a>
        else if (c == '\n' || c == '\r') {
ffffffffc02043b4:	01540463          	beq	s0,s5,ffffffffc02043bc <readline+0x8a>
ffffffffc02043b8:	fb641ae3          	bne	s0,s6,ffffffffc020436c <readline+0x3a>
            cputchar(c);
ffffffffc02043bc:	8522                	mv	a0,s0
ffffffffc02043be:	d35fb0ef          	jal	ra,ffffffffc02000f2 <cputchar>
            buf[i] = '\0';
ffffffffc02043c2:	0000d517          	auipc	a0,0xd
ffffffffc02043c6:	c7e50513          	addi	a0,a0,-898 # ffffffffc0211040 <buf>
ffffffffc02043ca:	94aa                	add	s1,s1,a0
ffffffffc02043cc:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc02043d0:	60a6                	ld	ra,72(sp)
ffffffffc02043d2:	6406                	ld	s0,64(sp)
ffffffffc02043d4:	74e2                	ld	s1,56(sp)
ffffffffc02043d6:	7942                	ld	s2,48(sp)
ffffffffc02043d8:	79a2                	ld	s3,40(sp)
ffffffffc02043da:	7a02                	ld	s4,32(sp)
ffffffffc02043dc:	6ae2                	ld	s5,24(sp)
ffffffffc02043de:	6b42                	ld	s6,16(sp)
ffffffffc02043e0:	6ba2                	ld	s7,8(sp)
ffffffffc02043e2:	6161                	addi	sp,sp,80
ffffffffc02043e4:	8082                	ret
            cputchar(c);
ffffffffc02043e6:	4521                	li	a0,8
ffffffffc02043e8:	d0bfb0ef          	jal	ra,ffffffffc02000f2 <cputchar>
            i --;
ffffffffc02043ec:	34fd                	addiw	s1,s1,-1
ffffffffc02043ee:	bfbd                	j	ffffffffc020436c <readline+0x3a>
