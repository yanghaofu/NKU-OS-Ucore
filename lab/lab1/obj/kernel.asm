
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080200000 <kern_entry>:
#include <memlayout.h>

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    la sp, bootstacktop
    80200000:	00004117          	auipc	sp,0x4
    80200004:	00010113          	mv	sp,sp

    tail kern_init
    80200008:	0040006f          	j	8020000c <kern_init>

000000008020000c <kern_init>:
int kern_init(void) __attribute__((noreturn));
void grade_backtrace(void);

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
    8020000c:	00004517          	auipc	a0,0x4
    80200010:	00450513          	addi	a0,a0,4 # 80204010 <edata>
    80200014:	00004617          	auipc	a2,0x4
    80200018:	01460613          	addi	a2,a2,20 # 80204028 <end>
int kern_init(void) {
    8020001c:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
    8020001e:	8e09                	sub	a2,a2,a0
    80200020:	4581                	li	a1,0
int kern_init(void) {
    80200022:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
    80200024:	5ec000ef          	jal	ra,80200610 <memset>

    cons_init();  // init the console
    80200028:	14c000ef          	jal	ra,80200174 <cons_init>

    const char *message = "(THU.CST) os is loading ...\n";
    cprintf("%s\n\n", message);
    8020002c:	00001597          	auipc	a1,0x1
    80200030:	a4458593          	addi	a1,a1,-1468 # 80200a70 <etext+0x2>
    80200034:	00001517          	auipc	a0,0x1
    80200038:	a5c50513          	addi	a0,a0,-1444 # 80200a90 <etext+0x22>
    8020003c:	030000ef          	jal	ra,8020006c <cprintf>

    print_kerninfo();
    80200040:	060000ef          	jal	ra,802000a0 <print_kerninfo>

    // grade_backtrace();

    idt_init();  // init interrupt descriptor table
    80200044:	140000ef          	jal	ra,80200184 <idt_init>

    // rdtime in mbare mode crashes
    clock_init();  // init clock interrupt
    80200048:	0e8000ef          	jal	ra,80200130 <clock_init>

    intr_enable();  // enable irq interrupt
    8020004c:	132000ef          	jal	ra,8020017e <intr_enable>
    
    while (1)
        ;
    80200050:	a001                	j	80200050 <kern_init+0x44>

0000000080200052 <cputch>:

/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void cputch(int c, int *cnt) {
    80200052:	1141                	addi	sp,sp,-16
    80200054:	e022                	sd	s0,0(sp)
    80200056:	e406                	sd	ra,8(sp)
    80200058:	842e                	mv	s0,a1
    cons_putc(c);
    8020005a:	11c000ef          	jal	ra,80200176 <cons_putc>
    (*cnt)++;
    8020005e:	401c                	lw	a5,0(s0)
}
    80200060:	60a2                	ld	ra,8(sp)
    (*cnt)++;
    80200062:	2785                	addiw	a5,a5,1
    80200064:	c01c                	sw	a5,0(s0)
}
    80200066:	6402                	ld	s0,0(sp)
    80200068:	0141                	addi	sp,sp,16
    8020006a:	8082                	ret

000000008020006c <cprintf>:
 * cprintf - formats a string and writes it to stdout
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...) {
    8020006c:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
    8020006e:	02810313          	addi	t1,sp,40 # 80204028 <end>
int cprintf(const char *fmt, ...) {
    80200072:	f42e                	sd	a1,40(sp)
    80200074:	f832                	sd	a2,48(sp)
    80200076:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
    80200078:	862a                	mv	a2,a0
    8020007a:	004c                	addi	a1,sp,4
    8020007c:	00000517          	auipc	a0,0x0
    80200080:	fd650513          	addi	a0,a0,-42 # 80200052 <cputch>
    80200084:	869a                	mv	a3,t1
int cprintf(const char *fmt, ...) {
    80200086:	ec06                	sd	ra,24(sp)
    80200088:	e0ba                	sd	a4,64(sp)
    8020008a:	e4be                	sd	a5,72(sp)
    8020008c:	e8c2                	sd	a6,80(sp)
    8020008e:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
    80200090:	e41a                	sd	t1,8(sp)
    int cnt = 0;
    80200092:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
    80200094:	5fa000ef          	jal	ra,8020068e <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
    80200098:	60e2                	ld	ra,24(sp)
    8020009a:	4512                	lw	a0,4(sp)
    8020009c:	6125                	addi	sp,sp,96
    8020009e:	8082                	ret

00000000802000a0 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
    802000a0:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
    802000a2:	00001517          	auipc	a0,0x1
    802000a6:	9f650513          	addi	a0,a0,-1546 # 80200a98 <etext+0x2a>
void print_kerninfo(void) {
    802000aa:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
    802000ac:	fc1ff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  entry  0x%016x (virtual)\n", kern_init);
    802000b0:	00000597          	auipc	a1,0x0
    802000b4:	f5c58593          	addi	a1,a1,-164 # 8020000c <kern_init>
    802000b8:	00001517          	auipc	a0,0x1
    802000bc:	a0050513          	addi	a0,a0,-1536 # 80200ab8 <etext+0x4a>
    802000c0:	fadff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  etext  0x%016x (virtual)\n", etext);
    802000c4:	00001597          	auipc	a1,0x1
    802000c8:	9aa58593          	addi	a1,a1,-1622 # 80200a6e <etext>
    802000cc:	00001517          	auipc	a0,0x1
    802000d0:	a0c50513          	addi	a0,a0,-1524 # 80200ad8 <etext+0x6a>
    802000d4:	f99ff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  edata  0x%016x (virtual)\n", edata);
    802000d8:	00004597          	auipc	a1,0x4
    802000dc:	f3858593          	addi	a1,a1,-200 # 80204010 <edata>
    802000e0:	00001517          	auipc	a0,0x1
    802000e4:	a1850513          	addi	a0,a0,-1512 # 80200af8 <etext+0x8a>
    802000e8:	f85ff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  end    0x%016x (virtual)\n", end);
    802000ec:	00004597          	auipc	a1,0x4
    802000f0:	f3c58593          	addi	a1,a1,-196 # 80204028 <end>
    802000f4:	00001517          	auipc	a0,0x1
    802000f8:	a2450513          	addi	a0,a0,-1500 # 80200b18 <etext+0xaa>
    802000fc:	f71ff0ef          	jal	ra,8020006c <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
    80200100:	00004597          	auipc	a1,0x4
    80200104:	32758593          	addi	a1,a1,807 # 80204427 <end+0x3ff>
    80200108:	00000797          	auipc	a5,0x0
    8020010c:	f0478793          	addi	a5,a5,-252 # 8020000c <kern_init>
    80200110:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
    80200114:	43f7d593          	srai	a1,a5,0x3f
}
    80200118:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
    8020011a:	3ff5f593          	andi	a1,a1,1023
    8020011e:	95be                	add	a1,a1,a5
    80200120:	85a9                	srai	a1,a1,0xa
    80200122:	00001517          	auipc	a0,0x1
    80200126:	a1650513          	addi	a0,a0,-1514 # 80200b38 <etext+0xca>
}
    8020012a:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
    8020012c:	f41ff06f          	j	8020006c <cprintf>

0000000080200130 <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    80200130:	1141                	addi	sp,sp,-16
    80200132:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
    80200134:	02000793          	li	a5,32
    80200138:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
    8020013c:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
    80200140:	67e1                	lui	a5,0x18
    80200142:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0x801e7960>
    80200146:	953e                	add	a0,a0,a5
    80200148:	0ef000ef          	jal	ra,80200a36 <sbi_set_timer>
}
    8020014c:	60a2                	ld	ra,8(sp)
    ticks = 0;
    8020014e:	00004797          	auipc	a5,0x4
    80200152:	ec07b923          	sd	zero,-302(a5) # 80204020 <ticks>
    cprintf("++ setup timer interrupts\n");
    80200156:	00001517          	auipc	a0,0x1
    8020015a:	a1250513          	addi	a0,a0,-1518 # 80200b68 <etext+0xfa>
}
    8020015e:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
    80200160:	f0dff06f          	j	8020006c <cprintf>

0000000080200164 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
    80200164:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
    80200168:	67e1                	lui	a5,0x18
    8020016a:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0x801e7960>
    8020016e:	953e                	add	a0,a0,a5
    80200170:	0c70006f          	j	80200a36 <sbi_set_timer>

0000000080200174 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
    80200174:	8082                	ret

0000000080200176 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
    80200176:	0ff57513          	andi	a0,a0,255
    8020017a:	0a10006f          	j	80200a1a <sbi_console_putchar>

000000008020017e <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
    8020017e:	100167f3          	csrrsi	a5,sstatus,2
    80200182:	8082                	ret

0000000080200184 <idt_init>:
 */
void idt_init(void) {
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
    80200184:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
    80200188:	00000797          	auipc	a5,0x0
    8020018c:	3ac78793          	addi	a5,a5,940 # 80200534 <__alltraps>
    80200190:	10579073          	csrw	stvec,a5
}
    80200194:	8082                	ret

0000000080200196 <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
    80200196:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
    80200198:	1141                	addi	sp,sp,-16
    8020019a:	e022                	sd	s0,0(sp)
    8020019c:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
    8020019e:	00001517          	auipc	a0,0x1
    802001a2:	b5a50513          	addi	a0,a0,-1190 # 80200cf8 <etext+0x28a>
void print_regs(struct pushregs *gpr) {
    802001a6:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
    802001a8:	ec5ff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
    802001ac:	640c                	ld	a1,8(s0)
    802001ae:	00001517          	auipc	a0,0x1
    802001b2:	b6250513          	addi	a0,a0,-1182 # 80200d10 <etext+0x2a2>
    802001b6:	eb7ff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
    802001ba:	680c                	ld	a1,16(s0)
    802001bc:	00001517          	auipc	a0,0x1
    802001c0:	b6c50513          	addi	a0,a0,-1172 # 80200d28 <etext+0x2ba>
    802001c4:	ea9ff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
    802001c8:	6c0c                	ld	a1,24(s0)
    802001ca:	00001517          	auipc	a0,0x1
    802001ce:	b7650513          	addi	a0,a0,-1162 # 80200d40 <etext+0x2d2>
    802001d2:	e9bff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
    802001d6:	700c                	ld	a1,32(s0)
    802001d8:	00001517          	auipc	a0,0x1
    802001dc:	b8050513          	addi	a0,a0,-1152 # 80200d58 <etext+0x2ea>
    802001e0:	e8dff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
    802001e4:	740c                	ld	a1,40(s0)
    802001e6:	00001517          	auipc	a0,0x1
    802001ea:	b8a50513          	addi	a0,a0,-1142 # 80200d70 <etext+0x302>
    802001ee:	e7fff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
    802001f2:	780c                	ld	a1,48(s0)
    802001f4:	00001517          	auipc	a0,0x1
    802001f8:	b9450513          	addi	a0,a0,-1132 # 80200d88 <etext+0x31a>
    802001fc:	e71ff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
    80200200:	7c0c                	ld	a1,56(s0)
    80200202:	00001517          	auipc	a0,0x1
    80200206:	b9e50513          	addi	a0,a0,-1122 # 80200da0 <etext+0x332>
    8020020a:	e63ff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
    8020020e:	602c                	ld	a1,64(s0)
    80200210:	00001517          	auipc	a0,0x1
    80200214:	ba850513          	addi	a0,a0,-1112 # 80200db8 <etext+0x34a>
    80200218:	e55ff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
    8020021c:	642c                	ld	a1,72(s0)
    8020021e:	00001517          	auipc	a0,0x1
    80200222:	bb250513          	addi	a0,a0,-1102 # 80200dd0 <etext+0x362>
    80200226:	e47ff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
    8020022a:	682c                	ld	a1,80(s0)
    8020022c:	00001517          	auipc	a0,0x1
    80200230:	bbc50513          	addi	a0,a0,-1092 # 80200de8 <etext+0x37a>
    80200234:	e39ff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
    80200238:	6c2c                	ld	a1,88(s0)
    8020023a:	00001517          	auipc	a0,0x1
    8020023e:	bc650513          	addi	a0,a0,-1082 # 80200e00 <etext+0x392>
    80200242:	e2bff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
    80200246:	702c                	ld	a1,96(s0)
    80200248:	00001517          	auipc	a0,0x1
    8020024c:	bd050513          	addi	a0,a0,-1072 # 80200e18 <etext+0x3aa>
    80200250:	e1dff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
    80200254:	742c                	ld	a1,104(s0)
    80200256:	00001517          	auipc	a0,0x1
    8020025a:	bda50513          	addi	a0,a0,-1062 # 80200e30 <etext+0x3c2>
    8020025e:	e0fff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
    80200262:	782c                	ld	a1,112(s0)
    80200264:	00001517          	auipc	a0,0x1
    80200268:	be450513          	addi	a0,a0,-1052 # 80200e48 <etext+0x3da>
    8020026c:	e01ff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
    80200270:	7c2c                	ld	a1,120(s0)
    80200272:	00001517          	auipc	a0,0x1
    80200276:	bee50513          	addi	a0,a0,-1042 # 80200e60 <etext+0x3f2>
    8020027a:	df3ff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
    8020027e:	604c                	ld	a1,128(s0)
    80200280:	00001517          	auipc	a0,0x1
    80200284:	bf850513          	addi	a0,a0,-1032 # 80200e78 <etext+0x40a>
    80200288:	de5ff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
    8020028c:	644c                	ld	a1,136(s0)
    8020028e:	00001517          	auipc	a0,0x1
    80200292:	c0250513          	addi	a0,a0,-1022 # 80200e90 <etext+0x422>
    80200296:	dd7ff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
    8020029a:	684c                	ld	a1,144(s0)
    8020029c:	00001517          	auipc	a0,0x1
    802002a0:	c0c50513          	addi	a0,a0,-1012 # 80200ea8 <etext+0x43a>
    802002a4:	dc9ff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
    802002a8:	6c4c                	ld	a1,152(s0)
    802002aa:	00001517          	auipc	a0,0x1
    802002ae:	c1650513          	addi	a0,a0,-1002 # 80200ec0 <etext+0x452>
    802002b2:	dbbff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
    802002b6:	704c                	ld	a1,160(s0)
    802002b8:	00001517          	auipc	a0,0x1
    802002bc:	c2050513          	addi	a0,a0,-992 # 80200ed8 <etext+0x46a>
    802002c0:	dadff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
    802002c4:	744c                	ld	a1,168(s0)
    802002c6:	00001517          	auipc	a0,0x1
    802002ca:	c2a50513          	addi	a0,a0,-982 # 80200ef0 <etext+0x482>
    802002ce:	d9fff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
    802002d2:	784c                	ld	a1,176(s0)
    802002d4:	00001517          	auipc	a0,0x1
    802002d8:	c3450513          	addi	a0,a0,-972 # 80200f08 <etext+0x49a>
    802002dc:	d91ff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
    802002e0:	7c4c                	ld	a1,184(s0)
    802002e2:	00001517          	auipc	a0,0x1
    802002e6:	c3e50513          	addi	a0,a0,-962 # 80200f20 <etext+0x4b2>
    802002ea:	d83ff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
    802002ee:	606c                	ld	a1,192(s0)
    802002f0:	00001517          	auipc	a0,0x1
    802002f4:	c4850513          	addi	a0,a0,-952 # 80200f38 <etext+0x4ca>
    802002f8:	d75ff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
    802002fc:	646c                	ld	a1,200(s0)
    802002fe:	00001517          	auipc	a0,0x1
    80200302:	c5250513          	addi	a0,a0,-942 # 80200f50 <etext+0x4e2>
    80200306:	d67ff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
    8020030a:	686c                	ld	a1,208(s0)
    8020030c:	00001517          	auipc	a0,0x1
    80200310:	c5c50513          	addi	a0,a0,-932 # 80200f68 <etext+0x4fa>
    80200314:	d59ff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
    80200318:	6c6c                	ld	a1,216(s0)
    8020031a:	00001517          	auipc	a0,0x1
    8020031e:	c6650513          	addi	a0,a0,-922 # 80200f80 <etext+0x512>
    80200322:	d4bff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
    80200326:	706c                	ld	a1,224(s0)
    80200328:	00001517          	auipc	a0,0x1
    8020032c:	c7050513          	addi	a0,a0,-912 # 80200f98 <etext+0x52a>
    80200330:	d3dff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
    80200334:	746c                	ld	a1,232(s0)
    80200336:	00001517          	auipc	a0,0x1
    8020033a:	c7a50513          	addi	a0,a0,-902 # 80200fb0 <etext+0x542>
    8020033e:	d2fff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
    80200342:	786c                	ld	a1,240(s0)
    80200344:	00001517          	auipc	a0,0x1
    80200348:	c8450513          	addi	a0,a0,-892 # 80200fc8 <etext+0x55a>
    8020034c:	d21ff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
    80200350:	7c6c                	ld	a1,248(s0)
}
    80200352:	6402                	ld	s0,0(sp)
    80200354:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
    80200356:	00001517          	auipc	a0,0x1
    8020035a:	c8a50513          	addi	a0,a0,-886 # 80200fe0 <etext+0x572>
}
    8020035e:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
    80200360:	d0dff06f          	j	8020006c <cprintf>

0000000080200364 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
    80200364:	1141                	addi	sp,sp,-16
    80200366:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
    80200368:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
    8020036a:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
    8020036c:	00001517          	auipc	a0,0x1
    80200370:	c8c50513          	addi	a0,a0,-884 # 80200ff8 <etext+0x58a>
void print_trapframe(struct trapframe *tf) {
    80200374:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
    80200376:	cf7ff0ef          	jal	ra,8020006c <cprintf>
    print_regs(&tf->gpr);
    8020037a:	8522                	mv	a0,s0
    8020037c:	e1bff0ef          	jal	ra,80200196 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
    80200380:	10043583          	ld	a1,256(s0)
    80200384:	00001517          	auipc	a0,0x1
    80200388:	c8c50513          	addi	a0,a0,-884 # 80201010 <etext+0x5a2>
    8020038c:	ce1ff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
    80200390:	10843583          	ld	a1,264(s0)
    80200394:	00001517          	auipc	a0,0x1
    80200398:	c9450513          	addi	a0,a0,-876 # 80201028 <etext+0x5ba>
    8020039c:	cd1ff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    802003a0:	11043583          	ld	a1,272(s0)
    802003a4:	00001517          	auipc	a0,0x1
    802003a8:	c9c50513          	addi	a0,a0,-868 # 80201040 <etext+0x5d2>
    802003ac:	cc1ff0ef          	jal	ra,8020006c <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
    802003b0:	11843583          	ld	a1,280(s0)
}
    802003b4:	6402                	ld	s0,0(sp)
    802003b6:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
    802003b8:	00001517          	auipc	a0,0x1
    802003bc:	ca050513          	addi	a0,a0,-864 # 80201058 <etext+0x5ea>
}
    802003c0:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
    802003c2:	cabff06f          	j	8020006c <cprintf>

00000000802003c6 <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    802003c6:	11853783          	ld	a5,280(a0)
    802003ca:	577d                	li	a4,-1
    802003cc:	8305                	srli	a4,a4,0x1
    802003ce:	8ff9                	and	a5,a5,a4
    switch (cause) {
    802003d0:	472d                	li	a4,11
    802003d2:	06f76f63          	bltu	a4,a5,80200450 <interrupt_handler+0x8a>
    802003d6:	00000717          	auipc	a4,0x0
    802003da:	7ae70713          	addi	a4,a4,1966 # 80200b84 <etext+0x116>
    802003de:	078a                	slli	a5,a5,0x2
    802003e0:	97ba                	add	a5,a5,a4
    802003e2:	439c                	lw	a5,0(a5)
    802003e4:	97ba                	add	a5,a5,a4
    802003e6:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
    802003e8:	00001517          	auipc	a0,0x1
    802003ec:	8c050513          	addi	a0,a0,-1856 # 80200ca8 <etext+0x23a>
    802003f0:	c7dff06f          	j	8020006c <cprintf>
            cprintf("Hypervisor software interrupt\n");
    802003f4:	00001517          	auipc	a0,0x1
    802003f8:	89450513          	addi	a0,a0,-1900 # 80200c88 <etext+0x21a>
    802003fc:	c71ff06f          	j	8020006c <cprintf>
            cprintf("User software interrupt\n");
    80200400:	00001517          	auipc	a0,0x1
    80200404:	84850513          	addi	a0,a0,-1976 # 80200c48 <etext+0x1da>
    80200408:	c65ff06f          	j	8020006c <cprintf>
            cprintf("Supervisor software interrupt\n");
    8020040c:	00001517          	auipc	a0,0x1
    80200410:	85c50513          	addi	a0,a0,-1956 # 80200c68 <etext+0x1fa>
    80200414:	c59ff06f          	j	8020006c <cprintf>
            break;
        case IRQ_U_EXT:
            cprintf("User software interrupt\n");
            break;
        case IRQ_S_EXT:
            cprintf("Supervisor external interrupt\n");
    80200418:	00001517          	auipc	a0,0x1
    8020041c:	8c050513          	addi	a0,a0,-1856 # 80200cd8 <etext+0x26a>
    80200420:	c4dff06f          	j	8020006c <cprintf>
void interrupt_handler(struct trapframe *tf) {
    80200424:	1141                	addi	sp,sp,-16
    80200426:	e406                	sd	ra,8(sp)
            clock_set_next_event();//设置时钟中断
    80200428:	d3dff0ef          	jal	ra,80200164 <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
    8020042c:	00004797          	auipc	a5,0x4
    80200430:	bf478793          	addi	a5,a5,-1036 # 80204020 <ticks>
    80200434:	639c                	ld	a5,0(a5)
    80200436:	06400713          	li	a4,100
    8020043a:	0785                	addi	a5,a5,1
    8020043c:	02e7f733          	remu	a4,a5,a4
    80200440:	00004697          	auipc	a3,0x4
    80200444:	bef6b023          	sd	a5,-1056(a3) # 80204020 <ticks>
    80200448:	c711                	beqz	a4,80200454 <interrupt_handler+0x8e>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
    8020044a:	60a2                	ld	ra,8(sp)
    8020044c:	0141                	addi	sp,sp,16
    8020044e:	8082                	ret
            print_trapframe(tf);
    80200450:	f15ff06f          	j	80200364 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
    80200454:	06400593          	li	a1,100
    80200458:	00001517          	auipc	a0,0x1
    8020045c:	87050513          	addi	a0,a0,-1936 # 80200cc8 <etext+0x25a>
    80200460:	c0dff0ef          	jal	ra,8020006c <cprintf>
                __asm__ volatile ("ebreak");//为了观察断点异常是否能正常输出，我们在这里打印ticks的同时触发一个ebreak指令。
    80200464:	9002                	ebreak
                __asm__ volatile ("mret");//为了观察违法指令异常是否能正常输出，我们在这里打印ticks的同时触发一个mret指令。
    80200466:	30200073          	mret
                num++;
    8020046a:	00004717          	auipc	a4,0x4
    8020046e:	ba670713          	addi	a4,a4,-1114 # 80204010 <edata>
    80200472:	631c                	ld	a5,0(a4)
                if(num==10)
    80200474:	46a9                	li	a3,10
                num++;
    80200476:	0785                	addi	a5,a5,1
    80200478:	00004617          	auipc	a2,0x4
    8020047c:	b8f63c23          	sd	a5,-1128(a2) # 80204010 <edata>
                if(num==10)
    80200480:	631c                	ld	a5,0(a4)
    80200482:	fcd794e3          	bne	a5,a3,8020044a <interrupt_handler+0x84>
}
    80200486:	60a2                	ld	ra,8(sp)
    80200488:	0141                	addi	sp,sp,16
                    sbi_shutdown();
    8020048a:	5c80006f          	j	80200a52 <sbi_shutdown>

000000008020048e <exception_handler>:

void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
    8020048e:	11853783          	ld	a5,280(a0)
    80200492:	472d                	li	a4,11
    80200494:	02f76863          	bltu	a4,a5,802004c4 <exception_handler+0x36>
    80200498:	4705                	li	a4,1
    8020049a:	00f71733          	sll	a4,a4,a5
    8020049e:	6785                	lui	a5,0x1
    802004a0:	17cd                	addi	a5,a5,-13
    802004a2:	8ff9                	and	a5,a5,a4
    802004a4:	ef99                	bnez	a5,802004c2 <exception_handler+0x34>
void exception_handler(struct trapframe *tf) {
    802004a6:	1141                	addi	sp,sp,-16
    802004a8:	e022                	sd	s0,0(sp)
    802004aa:	e406                	sd	ra,8(sp)
    802004ac:	00877793          	andi	a5,a4,8
    802004b0:	842a                	mv	s0,a0
    802004b2:	e3b1                	bnez	a5,802004f6 <exception_handler+0x68>
    802004b4:	8b11                	andi	a4,a4,4
    802004b6:	eb09                	bnez	a4,802004c8 <exception_handler+0x3a>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
    802004b8:	6402                	ld	s0,0(sp)
    802004ba:	60a2                	ld	ra,8(sp)
    802004bc:	0141                	addi	sp,sp,16
            print_trapframe(tf);
    802004be:	ea7ff06f          	j	80200364 <print_trapframe>
    802004c2:	8082                	ret
    802004c4:	ea1ff06f          	j	80200364 <print_trapframe>
            cprintf("Illegal instruction at 0x%016llx\n", tf->epc);
    802004c8:	10853583          	ld	a1,264(a0)
    802004cc:	00000517          	auipc	a0,0x0
    802004d0:	6ec50513          	addi	a0,a0,1772 # 80200bb8 <etext+0x14a>
    802004d4:	b99ff0ef          	jal	ra,8020006c <cprintf>
            cprintf("Exception type:Illegal instruction\n");
    802004d8:	00000517          	auipc	a0,0x0
    802004dc:	70850513          	addi	a0,a0,1800 # 80200be0 <etext+0x172>
    802004e0:	b8dff0ef          	jal	ra,8020006c <cprintf>
            tf->epc += 4;
    802004e4:	10843783          	ld	a5,264(s0)
}
    802004e8:	60a2                	ld	ra,8(sp)
            tf->epc += 4;
    802004ea:	0791                	addi	a5,a5,4
    802004ec:	10f43423          	sd	a5,264(s0)
}
    802004f0:	6402                	ld	s0,0(sp)
    802004f2:	0141                	addi	sp,sp,16
    802004f4:	8082                	ret
            cprintf("ebreak caught at 0x%016llx\n", tf->epc);
    802004f6:	10853583          	ld	a1,264(a0)
    802004fa:	00000517          	auipc	a0,0x0
    802004fe:	70e50513          	addi	a0,a0,1806 # 80200c08 <etext+0x19a>
    80200502:	b6bff0ef          	jal	ra,8020006c <cprintf>
            cprintf("Exception type: breakpoint\n");
    80200506:	00000517          	auipc	a0,0x0
    8020050a:	72250513          	addi	a0,a0,1826 # 80200c28 <etext+0x1ba>
    8020050e:	b5fff0ef          	jal	ra,8020006c <cprintf>
            tf->epc += 2;
    80200512:	10843783          	ld	a5,264(s0)
}
    80200516:	60a2                	ld	ra,8(sp)
            tf->epc += 2;
    80200518:	0789                	addi	a5,a5,2
    8020051a:	10f43423          	sd	a5,264(s0)
}
    8020051e:	6402                	ld	s0,0(sp)
    80200520:	0141                	addi	sp,sp,16
    80200522:	8082                	ret

0000000080200524 <trap>:

/* trap_dispatch - dispatch based on what type of trap occurred */
static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
    80200524:	11853783          	ld	a5,280(a0)
    80200528:	0007c463          	bltz	a5,80200530 <trap+0xc>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
    8020052c:	f63ff06f          	j	8020048e <exception_handler>
        interrupt_handler(tf);
    80200530:	e97ff06f          	j	802003c6 <interrupt_handler>

0000000080200534 <__alltraps>:
    .endm

    .globl __alltraps
.align(2)
__alltraps:
    SAVE_ALL
    80200534:	14011073          	csrw	sscratch,sp
    80200538:	712d                	addi	sp,sp,-288
    8020053a:	e002                	sd	zero,0(sp)
    8020053c:	e406                	sd	ra,8(sp)
    8020053e:	ec0e                	sd	gp,24(sp)
    80200540:	f012                	sd	tp,32(sp)
    80200542:	f416                	sd	t0,40(sp)
    80200544:	f81a                	sd	t1,48(sp)
    80200546:	fc1e                	sd	t2,56(sp)
    80200548:	e0a2                	sd	s0,64(sp)
    8020054a:	e4a6                	sd	s1,72(sp)
    8020054c:	e8aa                	sd	a0,80(sp)
    8020054e:	ecae                	sd	a1,88(sp)
    80200550:	f0b2                	sd	a2,96(sp)
    80200552:	f4b6                	sd	a3,104(sp)
    80200554:	f8ba                	sd	a4,112(sp)
    80200556:	fcbe                	sd	a5,120(sp)
    80200558:	e142                	sd	a6,128(sp)
    8020055a:	e546                	sd	a7,136(sp)
    8020055c:	e94a                	sd	s2,144(sp)
    8020055e:	ed4e                	sd	s3,152(sp)
    80200560:	f152                	sd	s4,160(sp)
    80200562:	f556                	sd	s5,168(sp)
    80200564:	f95a                	sd	s6,176(sp)
    80200566:	fd5e                	sd	s7,184(sp)
    80200568:	e1e2                	sd	s8,192(sp)
    8020056a:	e5e6                	sd	s9,200(sp)
    8020056c:	e9ea                	sd	s10,208(sp)
    8020056e:	edee                	sd	s11,216(sp)
    80200570:	f1f2                	sd	t3,224(sp)
    80200572:	f5f6                	sd	t4,232(sp)
    80200574:	f9fa                	sd	t5,240(sp)
    80200576:	fdfe                	sd	t6,248(sp)
    80200578:	14001473          	csrrw	s0,sscratch,zero
    8020057c:	100024f3          	csrr	s1,sstatus
    80200580:	14102973          	csrr	s2,sepc
    80200584:	143029f3          	csrr	s3,stval
    80200588:	14202a73          	csrr	s4,scause
    8020058c:	e822                	sd	s0,16(sp)
    8020058e:	e226                	sd	s1,256(sp)
    80200590:	e64a                	sd	s2,264(sp)
    80200592:	ea4e                	sd	s3,272(sp)
    80200594:	ee52                	sd	s4,280(sp)

    move  a0, sp
    80200596:	850a                	mv	a0,sp
    jal trap
    80200598:	f8dff0ef          	jal	ra,80200524 <trap>

000000008020059c <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
    8020059c:	6492                	ld	s1,256(sp)
    8020059e:	6932                	ld	s2,264(sp)
    802005a0:	10049073          	csrw	sstatus,s1
    802005a4:	14191073          	csrw	sepc,s2
    802005a8:	60a2                	ld	ra,8(sp)
    802005aa:	61e2                	ld	gp,24(sp)
    802005ac:	7202                	ld	tp,32(sp)
    802005ae:	72a2                	ld	t0,40(sp)
    802005b0:	7342                	ld	t1,48(sp)
    802005b2:	73e2                	ld	t2,56(sp)
    802005b4:	6406                	ld	s0,64(sp)
    802005b6:	64a6                	ld	s1,72(sp)
    802005b8:	6546                	ld	a0,80(sp)
    802005ba:	65e6                	ld	a1,88(sp)
    802005bc:	7606                	ld	a2,96(sp)
    802005be:	76a6                	ld	a3,104(sp)
    802005c0:	7746                	ld	a4,112(sp)
    802005c2:	77e6                	ld	a5,120(sp)
    802005c4:	680a                	ld	a6,128(sp)
    802005c6:	68aa                	ld	a7,136(sp)
    802005c8:	694a                	ld	s2,144(sp)
    802005ca:	69ea                	ld	s3,152(sp)
    802005cc:	7a0a                	ld	s4,160(sp)
    802005ce:	7aaa                	ld	s5,168(sp)
    802005d0:	7b4a                	ld	s6,176(sp)
    802005d2:	7bea                	ld	s7,184(sp)
    802005d4:	6c0e                	ld	s8,192(sp)
    802005d6:	6cae                	ld	s9,200(sp)
    802005d8:	6d4e                	ld	s10,208(sp)
    802005da:	6dee                	ld	s11,216(sp)
    802005dc:	7e0e                	ld	t3,224(sp)
    802005de:	7eae                	ld	t4,232(sp)
    802005e0:	7f4e                	ld	t5,240(sp)
    802005e2:	7fee                	ld	t6,248(sp)
    802005e4:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
    802005e6:	10200073          	sret

00000000802005ea <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
    802005ea:	c185                	beqz	a1,8020060a <strnlen+0x20>
    802005ec:	00054783          	lbu	a5,0(a0)
    802005f0:	cf89                	beqz	a5,8020060a <strnlen+0x20>
    size_t cnt = 0;
    802005f2:	4781                	li	a5,0
    802005f4:	a021                	j	802005fc <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
    802005f6:	00074703          	lbu	a4,0(a4)
    802005fa:	c711                	beqz	a4,80200606 <strnlen+0x1c>
        cnt ++;
    802005fc:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
    802005fe:	00f50733          	add	a4,a0,a5
    80200602:	fef59ae3          	bne	a1,a5,802005f6 <strnlen+0xc>
    }
    return cnt;
}
    80200606:	853e                	mv	a0,a5
    80200608:	8082                	ret
    size_t cnt = 0;
    8020060a:	4781                	li	a5,0
}
    8020060c:	853e                	mv	a0,a5
    8020060e:	8082                	ret

0000000080200610 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
    80200610:	ca01                	beqz	a2,80200620 <memset+0x10>
    80200612:	962a                	add	a2,a2,a0
    char *p = s;
    80200614:	87aa                	mv	a5,a0
        *p ++ = c;
    80200616:	0785                	addi	a5,a5,1
    80200618:	feb78fa3          	sb	a1,-1(a5) # fff <BASE_ADDRESS-0x801ff001>
    while (n -- > 0) {
    8020061c:	fec79de3          	bne	a5,a2,80200616 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
    80200620:	8082                	ret

0000000080200622 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
    80200622:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
    80200626:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
    80200628:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
    8020062c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
    8020062e:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
    80200632:	f022                	sd	s0,32(sp)
    80200634:	ec26                	sd	s1,24(sp)
    80200636:	e84a                	sd	s2,16(sp)
    80200638:	f406                	sd	ra,40(sp)
    8020063a:	e44e                	sd	s3,8(sp)
    8020063c:	84aa                	mv	s1,a0
    8020063e:	892e                	mv	s2,a1
    80200640:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
    80200644:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
    80200646:	03067e63          	bleu	a6,a2,80200682 <printnum+0x60>
    8020064a:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
    8020064c:	00805763          	blez	s0,8020065a <printnum+0x38>
    80200650:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
    80200652:	85ca                	mv	a1,s2
    80200654:	854e                	mv	a0,s3
    80200656:	9482                	jalr	s1
        while (-- width > 0)
    80200658:	fc65                	bnez	s0,80200650 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
    8020065a:	1a02                	slli	s4,s4,0x20
    8020065c:	020a5a13          	srli	s4,s4,0x20
    80200660:	00001797          	auipc	a5,0x1
    80200664:	ba078793          	addi	a5,a5,-1120 # 80201200 <error_string+0x38>
    80200668:	9a3e                	add	s4,s4,a5
}
    8020066a:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
    8020066c:	000a4503          	lbu	a0,0(s4)
}
    80200670:	70a2                	ld	ra,40(sp)
    80200672:	69a2                	ld	s3,8(sp)
    80200674:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
    80200676:	85ca                	mv	a1,s2
    80200678:	8326                	mv	t1,s1
}
    8020067a:	6942                	ld	s2,16(sp)
    8020067c:	64e2                	ld	s1,24(sp)
    8020067e:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
    80200680:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
    80200682:	03065633          	divu	a2,a2,a6
    80200686:	8722                	mv	a4,s0
    80200688:	f9bff0ef          	jal	ra,80200622 <printnum>
    8020068c:	b7f9                	j	8020065a <printnum+0x38>

000000008020068e <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
    8020068e:	7119                	addi	sp,sp,-128
    80200690:	f4a6                	sd	s1,104(sp)
    80200692:	f0ca                	sd	s2,96(sp)
    80200694:	e8d2                	sd	s4,80(sp)
    80200696:	e4d6                	sd	s5,72(sp)
    80200698:	e0da                	sd	s6,64(sp)
    8020069a:	fc5e                	sd	s7,56(sp)
    8020069c:	f862                	sd	s8,48(sp)
    8020069e:	f06a                	sd	s10,32(sp)
    802006a0:	fc86                	sd	ra,120(sp)
    802006a2:	f8a2                	sd	s0,112(sp)
    802006a4:	ecce                	sd	s3,88(sp)
    802006a6:	f466                	sd	s9,40(sp)
    802006a8:	ec6e                	sd	s11,24(sp)
    802006aa:	892a                	mv	s2,a0
    802006ac:	84ae                	mv	s1,a1
    802006ae:	8d32                	mv	s10,a2
    802006b0:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
    802006b2:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
    802006b4:	00001a17          	auipc	s4,0x1
    802006b8:	9b8a0a13          	addi	s4,s4,-1608 # 8020106c <etext+0x5fe>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
    802006bc:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    802006c0:	00001c17          	auipc	s8,0x1
    802006c4:	b08c0c13          	addi	s8,s8,-1272 # 802011c8 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    802006c8:	000d4503          	lbu	a0,0(s10)
    802006cc:	02500793          	li	a5,37
    802006d0:	001d0413          	addi	s0,s10,1
    802006d4:	00f50e63          	beq	a0,a5,802006f0 <vprintfmt+0x62>
            if (ch == '\0') {
    802006d8:	c521                	beqz	a0,80200720 <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    802006da:	02500993          	li	s3,37
    802006de:	a011                	j	802006e2 <vprintfmt+0x54>
            if (ch == '\0') {
    802006e0:	c121                	beqz	a0,80200720 <vprintfmt+0x92>
            putch(ch, putdat);
    802006e2:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    802006e4:	0405                	addi	s0,s0,1
            putch(ch, putdat);
    802006e6:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    802006e8:	fff44503          	lbu	a0,-1(s0)
    802006ec:	ff351ae3          	bne	a0,s3,802006e0 <vprintfmt+0x52>
    802006f0:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
    802006f4:	02000793          	li	a5,32
        lflag = altflag = 0;
    802006f8:	4981                	li	s3,0
    802006fa:	4801                	li	a6,0
        width = precision = -1;
    802006fc:	5cfd                	li	s9,-1
    802006fe:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
    80200700:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
    80200704:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
    80200706:	fdd6069b          	addiw	a3,a2,-35
    8020070a:	0ff6f693          	andi	a3,a3,255
    8020070e:	00140d13          	addi	s10,s0,1
    80200712:	20d5e563          	bltu	a1,a3,8020091c <vprintfmt+0x28e>
    80200716:	068a                	slli	a3,a3,0x2
    80200718:	96d2                	add	a3,a3,s4
    8020071a:	4294                	lw	a3,0(a3)
    8020071c:	96d2                	add	a3,a3,s4
    8020071e:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
    80200720:	70e6                	ld	ra,120(sp)
    80200722:	7446                	ld	s0,112(sp)
    80200724:	74a6                	ld	s1,104(sp)
    80200726:	7906                	ld	s2,96(sp)
    80200728:	69e6                	ld	s3,88(sp)
    8020072a:	6a46                	ld	s4,80(sp)
    8020072c:	6aa6                	ld	s5,72(sp)
    8020072e:	6b06                	ld	s6,64(sp)
    80200730:	7be2                	ld	s7,56(sp)
    80200732:	7c42                	ld	s8,48(sp)
    80200734:	7ca2                	ld	s9,40(sp)
    80200736:	7d02                	ld	s10,32(sp)
    80200738:	6de2                	ld	s11,24(sp)
    8020073a:	6109                	addi	sp,sp,128
    8020073c:	8082                	ret
    if (lflag >= 2) {
    8020073e:	4705                	li	a4,1
    80200740:	008a8593          	addi	a1,s5,8
    80200744:	01074463          	blt	a4,a6,8020074c <vprintfmt+0xbe>
    else if (lflag) {
    80200748:	26080363          	beqz	a6,802009ae <vprintfmt+0x320>
        return va_arg(*ap, unsigned long);
    8020074c:	000ab603          	ld	a2,0(s5)
    80200750:	46c1                	li	a3,16
    80200752:	8aae                	mv	s5,a1
    80200754:	a06d                	j	802007fe <vprintfmt+0x170>
            goto reswitch;
    80200756:	00144603          	lbu	a2,1(s0)
            altflag = 1;
    8020075a:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
    8020075c:	846a                	mv	s0,s10
            goto reswitch;
    8020075e:	b765                	j	80200706 <vprintfmt+0x78>
            putch(va_arg(ap, int), putdat);
    80200760:	000aa503          	lw	a0,0(s5)
    80200764:	85a6                	mv	a1,s1
    80200766:	0aa1                	addi	s5,s5,8
    80200768:	9902                	jalr	s2
            break;
    8020076a:	bfb9                	j	802006c8 <vprintfmt+0x3a>
    if (lflag >= 2) {
    8020076c:	4705                	li	a4,1
    8020076e:	008a8993          	addi	s3,s5,8
    80200772:	01074463          	blt	a4,a6,8020077a <vprintfmt+0xec>
    else if (lflag) {
    80200776:	22080463          	beqz	a6,8020099e <vprintfmt+0x310>
        return va_arg(*ap, long);
    8020077a:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
    8020077e:	24044463          	bltz	s0,802009c6 <vprintfmt+0x338>
            num = getint(&ap, lflag);
    80200782:	8622                	mv	a2,s0
    80200784:	8ace                	mv	s5,s3
    80200786:	46a9                	li	a3,10
    80200788:	a89d                	j	802007fe <vprintfmt+0x170>
            err = va_arg(ap, int);
    8020078a:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    8020078e:	4719                	li	a4,6
            err = va_arg(ap, int);
    80200790:	0aa1                	addi	s5,s5,8
            if (err < 0) {
    80200792:	41f7d69b          	sraiw	a3,a5,0x1f
    80200796:	8fb5                	xor	a5,a5,a3
    80200798:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    8020079c:	1ad74363          	blt	a4,a3,80200942 <vprintfmt+0x2b4>
    802007a0:	00369793          	slli	a5,a3,0x3
    802007a4:	97e2                	add	a5,a5,s8
    802007a6:	639c                	ld	a5,0(a5)
    802007a8:	18078d63          	beqz	a5,80200942 <vprintfmt+0x2b4>
                printfmt(putch, putdat, "%s", p);
    802007ac:	86be                	mv	a3,a5
    802007ae:	00001617          	auipc	a2,0x1
    802007b2:	b0260613          	addi	a2,a2,-1278 # 802012b0 <error_string+0xe8>
    802007b6:	85a6                	mv	a1,s1
    802007b8:	854a                	mv	a0,s2
    802007ba:	240000ef          	jal	ra,802009fa <printfmt>
    802007be:	b729                	j	802006c8 <vprintfmt+0x3a>
            lflag ++;
    802007c0:	00144603          	lbu	a2,1(s0)
    802007c4:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
    802007c6:	846a                	mv	s0,s10
            goto reswitch;
    802007c8:	bf3d                	j	80200706 <vprintfmt+0x78>
    if (lflag >= 2) {
    802007ca:	4705                	li	a4,1
    802007cc:	008a8593          	addi	a1,s5,8
    802007d0:	01074463          	blt	a4,a6,802007d8 <vprintfmt+0x14a>
    else if (lflag) {
    802007d4:	1e080263          	beqz	a6,802009b8 <vprintfmt+0x32a>
        return va_arg(*ap, unsigned long);
    802007d8:	000ab603          	ld	a2,0(s5)
    802007dc:	46a1                	li	a3,8
    802007de:	8aae                	mv	s5,a1
    802007e0:	a839                	j	802007fe <vprintfmt+0x170>
            putch('0', putdat);
    802007e2:	03000513          	li	a0,48
    802007e6:	85a6                	mv	a1,s1
    802007e8:	e03e                	sd	a5,0(sp)
    802007ea:	9902                	jalr	s2
            putch('x', putdat);
    802007ec:	85a6                	mv	a1,s1
    802007ee:	07800513          	li	a0,120
    802007f2:	9902                	jalr	s2
            num = (unsigned long long)va_arg(ap, void *);
    802007f4:	0aa1                	addi	s5,s5,8
    802007f6:	ff8ab603          	ld	a2,-8(s5)
            goto number;
    802007fa:	6782                	ld	a5,0(sp)
    802007fc:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
    802007fe:	876e                	mv	a4,s11
    80200800:	85a6                	mv	a1,s1
    80200802:	854a                	mv	a0,s2
    80200804:	e1fff0ef          	jal	ra,80200622 <printnum>
            break;
    80200808:	b5c1                	j	802006c8 <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
    8020080a:	000ab603          	ld	a2,0(s5)
    8020080e:	0aa1                	addi	s5,s5,8
    80200810:	1c060663          	beqz	a2,802009dc <vprintfmt+0x34e>
            if (width > 0 && padc != '-') {
    80200814:	00160413          	addi	s0,a2,1
    80200818:	17b05c63          	blez	s11,80200990 <vprintfmt+0x302>
    8020081c:	02d00593          	li	a1,45
    80200820:	14b79263          	bne	a5,a1,80200964 <vprintfmt+0x2d6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    80200824:	00064783          	lbu	a5,0(a2)
    80200828:	0007851b          	sext.w	a0,a5
    8020082c:	c905                	beqz	a0,8020085c <vprintfmt+0x1ce>
    8020082e:	000cc563          	bltz	s9,80200838 <vprintfmt+0x1aa>
    80200832:	3cfd                	addiw	s9,s9,-1
    80200834:	036c8263          	beq	s9,s6,80200858 <vprintfmt+0x1ca>
                    putch('?', putdat);
    80200838:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
    8020083a:	18098463          	beqz	s3,802009c2 <vprintfmt+0x334>
    8020083e:	3781                	addiw	a5,a5,-32
    80200840:	18fbf163          	bleu	a5,s7,802009c2 <vprintfmt+0x334>
                    putch('?', putdat);
    80200844:	03f00513          	li	a0,63
    80200848:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    8020084a:	0405                	addi	s0,s0,1
    8020084c:	fff44783          	lbu	a5,-1(s0)
    80200850:	3dfd                	addiw	s11,s11,-1
    80200852:	0007851b          	sext.w	a0,a5
    80200856:	fd61                	bnez	a0,8020082e <vprintfmt+0x1a0>
            for (; width > 0; width --) {
    80200858:	e7b058e3          	blez	s11,802006c8 <vprintfmt+0x3a>
    8020085c:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
    8020085e:	85a6                	mv	a1,s1
    80200860:	02000513          	li	a0,32
    80200864:	9902                	jalr	s2
            for (; width > 0; width --) {
    80200866:	e60d81e3          	beqz	s11,802006c8 <vprintfmt+0x3a>
    8020086a:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
    8020086c:	85a6                	mv	a1,s1
    8020086e:	02000513          	li	a0,32
    80200872:	9902                	jalr	s2
            for (; width > 0; width --) {
    80200874:	fe0d94e3          	bnez	s11,8020085c <vprintfmt+0x1ce>
    80200878:	bd81                	j	802006c8 <vprintfmt+0x3a>
    if (lflag >= 2) {
    8020087a:	4705                	li	a4,1
    8020087c:	008a8593          	addi	a1,s5,8
    80200880:	01074463          	blt	a4,a6,80200888 <vprintfmt+0x1fa>
    else if (lflag) {
    80200884:	12080063          	beqz	a6,802009a4 <vprintfmt+0x316>
        return va_arg(*ap, unsigned long);
    80200888:	000ab603          	ld	a2,0(s5)
    8020088c:	46a9                	li	a3,10
    8020088e:	8aae                	mv	s5,a1
    80200890:	b7bd                	j	802007fe <vprintfmt+0x170>
    80200892:	00144603          	lbu	a2,1(s0)
            padc = '-';
    80200896:	02d00793          	li	a5,45
        switch (ch = *(unsigned char *)fmt ++) {
    8020089a:	846a                	mv	s0,s10
    8020089c:	b5ad                	j	80200706 <vprintfmt+0x78>
            putch(ch, putdat);
    8020089e:	85a6                	mv	a1,s1
    802008a0:	02500513          	li	a0,37
    802008a4:	9902                	jalr	s2
            break;
    802008a6:	b50d                	j	802006c8 <vprintfmt+0x3a>
            precision = va_arg(ap, int);
    802008a8:	000aac83          	lw	s9,0(s5)
            goto process_precision;
    802008ac:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
    802008b0:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
    802008b2:	846a                	mv	s0,s10
            if (width < 0)
    802008b4:	e40dd9e3          	bgez	s11,80200706 <vprintfmt+0x78>
                width = precision, precision = -1;
    802008b8:	8de6                	mv	s11,s9
    802008ba:	5cfd                	li	s9,-1
    802008bc:	b5a9                	j	80200706 <vprintfmt+0x78>
            goto reswitch;
    802008be:	00144603          	lbu	a2,1(s0)
            padc = '0';
    802008c2:	03000793          	li	a5,48
        switch (ch = *(unsigned char *)fmt ++) {
    802008c6:	846a                	mv	s0,s10
            goto reswitch;
    802008c8:	bd3d                	j	80200706 <vprintfmt+0x78>
                precision = precision * 10 + ch - '0';
    802008ca:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
    802008ce:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
    802008d2:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
    802008d4:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
    802008d8:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
    802008dc:	fcd56ce3          	bltu	a0,a3,802008b4 <vprintfmt+0x226>
            for (precision = 0; ; ++ fmt) {
    802008e0:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
    802008e2:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
    802008e6:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
    802008ea:	0196873b          	addw	a4,a3,s9
    802008ee:	0017171b          	slliw	a4,a4,0x1
    802008f2:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
    802008f6:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
    802008fa:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
    802008fe:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
    80200902:	fcd57fe3          	bleu	a3,a0,802008e0 <vprintfmt+0x252>
    80200906:	b77d                	j	802008b4 <vprintfmt+0x226>
            if (width < 0)
    80200908:	fffdc693          	not	a3,s11
    8020090c:	96fd                	srai	a3,a3,0x3f
    8020090e:	00ddfdb3          	and	s11,s11,a3
    80200912:	00144603          	lbu	a2,1(s0)
    80200916:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
    80200918:	846a                	mv	s0,s10
    8020091a:	b3f5                	j	80200706 <vprintfmt+0x78>
            putch('%', putdat);
    8020091c:	85a6                	mv	a1,s1
    8020091e:	02500513          	li	a0,37
    80200922:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
    80200924:	fff44703          	lbu	a4,-1(s0)
    80200928:	02500793          	li	a5,37
    8020092c:	8d22                	mv	s10,s0
    8020092e:	d8f70de3          	beq	a4,a5,802006c8 <vprintfmt+0x3a>
    80200932:	02500713          	li	a4,37
    80200936:	1d7d                	addi	s10,s10,-1
    80200938:	fffd4783          	lbu	a5,-1(s10)
    8020093c:	fee79de3          	bne	a5,a4,80200936 <vprintfmt+0x2a8>
    80200940:	b361                	j	802006c8 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
    80200942:	00001617          	auipc	a2,0x1
    80200946:	95e60613          	addi	a2,a2,-1698 # 802012a0 <error_string+0xd8>
    8020094a:	85a6                	mv	a1,s1
    8020094c:	854a                	mv	a0,s2
    8020094e:	0ac000ef          	jal	ra,802009fa <printfmt>
    80200952:	bb9d                	j	802006c8 <vprintfmt+0x3a>
                p = "(null)";
    80200954:	00001617          	auipc	a2,0x1
    80200958:	94460613          	addi	a2,a2,-1724 # 80201298 <error_string+0xd0>
            if (width > 0 && padc != '-') {
    8020095c:	00001417          	auipc	s0,0x1
    80200960:	93d40413          	addi	s0,s0,-1731 # 80201299 <error_string+0xd1>
                for (width -= strnlen(p, precision); width > 0; width --) {
    80200964:	8532                	mv	a0,a2
    80200966:	85e6                	mv	a1,s9
    80200968:	e032                	sd	a2,0(sp)
    8020096a:	e43e                	sd	a5,8(sp)
    8020096c:	c7fff0ef          	jal	ra,802005ea <strnlen>
    80200970:	40ad8dbb          	subw	s11,s11,a0
    80200974:	6602                	ld	a2,0(sp)
    80200976:	01b05d63          	blez	s11,80200990 <vprintfmt+0x302>
    8020097a:	67a2                	ld	a5,8(sp)
    8020097c:	2781                	sext.w	a5,a5
    8020097e:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
    80200980:	6522                	ld	a0,8(sp)
    80200982:	85a6                	mv	a1,s1
    80200984:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
    80200986:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
    80200988:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
    8020098a:	6602                	ld	a2,0(sp)
    8020098c:	fe0d9ae3          	bnez	s11,80200980 <vprintfmt+0x2f2>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    80200990:	00064783          	lbu	a5,0(a2)
    80200994:	0007851b          	sext.w	a0,a5
    80200998:	e8051be3          	bnez	a0,8020082e <vprintfmt+0x1a0>
    8020099c:	b335                	j	802006c8 <vprintfmt+0x3a>
        return va_arg(*ap, int);
    8020099e:	000aa403          	lw	s0,0(s5)
    802009a2:	bbf1                	j	8020077e <vprintfmt+0xf0>
        return va_arg(*ap, unsigned int);
    802009a4:	000ae603          	lwu	a2,0(s5)
    802009a8:	46a9                	li	a3,10
    802009aa:	8aae                	mv	s5,a1
    802009ac:	bd89                	j	802007fe <vprintfmt+0x170>
    802009ae:	000ae603          	lwu	a2,0(s5)
    802009b2:	46c1                	li	a3,16
    802009b4:	8aae                	mv	s5,a1
    802009b6:	b5a1                	j	802007fe <vprintfmt+0x170>
    802009b8:	000ae603          	lwu	a2,0(s5)
    802009bc:	46a1                	li	a3,8
    802009be:	8aae                	mv	s5,a1
    802009c0:	bd3d                	j	802007fe <vprintfmt+0x170>
                    putch(ch, putdat);
    802009c2:	9902                	jalr	s2
    802009c4:	b559                	j	8020084a <vprintfmt+0x1bc>
                putch('-', putdat);
    802009c6:	85a6                	mv	a1,s1
    802009c8:	02d00513          	li	a0,45
    802009cc:	e03e                	sd	a5,0(sp)
    802009ce:	9902                	jalr	s2
                num = -(long long)num;
    802009d0:	8ace                	mv	s5,s3
    802009d2:	40800633          	neg	a2,s0
    802009d6:	46a9                	li	a3,10
    802009d8:	6782                	ld	a5,0(sp)
    802009da:	b515                	j	802007fe <vprintfmt+0x170>
            if (width > 0 && padc != '-') {
    802009dc:	01b05663          	blez	s11,802009e8 <vprintfmt+0x35a>
    802009e0:	02d00693          	li	a3,45
    802009e4:	f6d798e3          	bne	a5,a3,80200954 <vprintfmt+0x2c6>
    802009e8:	00001417          	auipc	s0,0x1
    802009ec:	8b140413          	addi	s0,s0,-1871 # 80201299 <error_string+0xd1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    802009f0:	02800513          	li	a0,40
    802009f4:	02800793          	li	a5,40
    802009f8:	bd1d                	j	8020082e <vprintfmt+0x1a0>

00000000802009fa <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    802009fa:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
    802009fc:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    80200a00:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
    80200a02:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    80200a04:	ec06                	sd	ra,24(sp)
    80200a06:	f83a                	sd	a4,48(sp)
    80200a08:	fc3e                	sd	a5,56(sp)
    80200a0a:	e0c2                	sd	a6,64(sp)
    80200a0c:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
    80200a0e:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
    80200a10:	c7fff0ef          	jal	ra,8020068e <vprintfmt>
}
    80200a14:	60e2                	ld	ra,24(sp)
    80200a16:	6161                	addi	sp,sp,80
    80200a18:	8082                	ret

0000000080200a1a <sbi_console_putchar>:

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
    80200a1a:	00003797          	auipc	a5,0x3
    80200a1e:	5e678793          	addi	a5,a5,1510 # 80204000 <bootstacktop>
    __asm__ volatile (
    80200a22:	6398                	ld	a4,0(a5)
    80200a24:	4781                	li	a5,0
    80200a26:	88ba                	mv	a7,a4
    80200a28:	852a                	mv	a0,a0
    80200a2a:	85be                	mv	a1,a5
    80200a2c:	863e                	mv	a2,a5
    80200a2e:	00000073          	ecall
    80200a32:	87aa                	mv	a5,a0
}
    80200a34:	8082                	ret

0000000080200a36 <sbi_set_timer>:

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
    80200a36:	00003797          	auipc	a5,0x3
    80200a3a:	5e278793          	addi	a5,a5,1506 # 80204018 <SBI_SET_TIMER>
    __asm__ volatile (
    80200a3e:	6398                	ld	a4,0(a5)
    80200a40:	4781                	li	a5,0
    80200a42:	88ba                	mv	a7,a4
    80200a44:	852a                	mv	a0,a0
    80200a46:	85be                	mv	a1,a5
    80200a48:	863e                	mv	a2,a5
    80200a4a:	00000073          	ecall
    80200a4e:	87aa                	mv	a5,a0
}
    80200a50:	8082                	ret

0000000080200a52 <sbi_shutdown>:


void sbi_shutdown(void)
{
    sbi_call(SBI_SHUTDOWN,0,0,0);
    80200a52:	00003797          	auipc	a5,0x3
    80200a56:	5b678793          	addi	a5,a5,1462 # 80204008 <SBI_SHUTDOWN>
    __asm__ volatile (
    80200a5a:	6398                	ld	a4,0(a5)
    80200a5c:	4781                	li	a5,0
    80200a5e:	88ba                	mv	a7,a4
    80200a60:	853e                	mv	a0,a5
    80200a62:	85be                	mv	a1,a5
    80200a64:	863e                	mv	a2,a5
    80200a66:	00000073          	ecall
    80200a6a:	87aa                	mv	a5,a0
    80200a6c:	8082                	ret
