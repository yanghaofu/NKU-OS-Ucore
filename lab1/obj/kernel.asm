
bin/kernel：     文件格式 elf64-littleriscv


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
    80200024:	239000ef          	jal	ra,80200a5c <memset>

    cons_init();  // init the console
    80200028:	152000ef          	jal	ra,8020017a <cons_init>

    const char *message = "(THU.CST) os is loading ...\n";
    cprintf("%s\n\n", message);
    8020002c:	00001597          	auipc	a1,0x1
    80200030:	a4458593          	addi	a1,a1,-1468 # 80200a70 <etext+0x2>
    80200034:	00001517          	auipc	a0,0x1
    80200038:	a5c50513          	addi	a0,a0,-1444 # 80200a90 <etext+0x22>
    8020003c:	036000ef          	jal	ra,80200072 <cprintf>

    print_kerninfo();
    80200040:	066000ef          	jal	ra,802000a6 <print_kerninfo>

    // grade_backtrace();

    idt_init();  // init interrupt descriptor table
    80200044:	146000ef          	jal	ra,8020018a <idt_init>

    // rdtime in mbare mode crashes
    clock_init();  // init clock interrupt
    80200048:	0ee000ef          	jal	ra,80200136 <clock_init>

    intr_enable();  // enable irq interrupt
    8020004c:	138000ef          	jal	ra,80200184 <intr_enable>
     
    asm volatile("mret");   
    80200050:	30200073          	mret
    asm volatile("ebreak");
    80200054:	9002                	ebreak

    while (1)
        ;
    80200056:	a001                	j	80200056 <kern_init+0x4a>

0000000080200058 <cputch>:

/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void cputch(int c, int *cnt) {
    80200058:	1141                	addi	sp,sp,-16
    8020005a:	e022                	sd	s0,0(sp)
    8020005c:	e406                	sd	ra,8(sp)
    8020005e:	842e                	mv	s0,a1
    cons_putc(c);
    80200060:	11c000ef          	jal	ra,8020017c <cons_putc>
    (*cnt)++;
    80200064:	401c                	lw	a5,0(s0)
}
    80200066:	60a2                	ld	ra,8(sp)
    (*cnt)++;
    80200068:	2785                	addiw	a5,a5,1
    8020006a:	c01c                	sw	a5,0(s0)
}
    8020006c:	6402                	ld	s0,0(sp)
    8020006e:	0141                	addi	sp,sp,16
    80200070:	8082                	ret

0000000080200072 <cprintf>:
 * cprintf - formats a string and writes it to stdout
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...) {
    80200072:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
    80200074:	02810313          	addi	t1,sp,40 # 80204028 <end>
int cprintf(const char *fmt, ...) {
    80200078:	f42e                	sd	a1,40(sp)
    8020007a:	f832                	sd	a2,48(sp)
    8020007c:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
    8020007e:	862a                	mv	a2,a0
    80200080:	004c                	addi	a1,sp,4
    80200082:	00000517          	auipc	a0,0x0
    80200086:	fd650513          	addi	a0,a0,-42 # 80200058 <cputch>
    8020008a:	869a                	mv	a3,t1
int cprintf(const char *fmt, ...) {
    8020008c:	ec06                	sd	ra,24(sp)
    8020008e:	e0ba                	sd	a4,64(sp)
    80200090:	e4be                	sd	a5,72(sp)
    80200092:	e8c2                	sd	a6,80(sp)
    80200094:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
    80200096:	e41a                	sd	t1,8(sp)
    int cnt = 0;
    80200098:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
    8020009a:	5bc000ef          	jal	ra,80200656 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
    8020009e:	60e2                	ld	ra,24(sp)
    802000a0:	4512                	lw	a0,4(sp)
    802000a2:	6125                	addi	sp,sp,96
    802000a4:	8082                	ret

00000000802000a6 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
    802000a6:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
    802000a8:	00001517          	auipc	a0,0x1
    802000ac:	9f050513          	addi	a0,a0,-1552 # 80200a98 <etext+0x2a>
void print_kerninfo(void) {
    802000b0:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
    802000b2:	fc1ff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  entry  0x%016x (virtual)\n", kern_init);
    802000b6:	00000597          	auipc	a1,0x0
    802000ba:	f5658593          	addi	a1,a1,-170 # 8020000c <kern_init>
    802000be:	00001517          	auipc	a0,0x1
    802000c2:	9fa50513          	addi	a0,a0,-1542 # 80200ab8 <etext+0x4a>
    802000c6:	fadff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  etext  0x%016x (virtual)\n", etext);
    802000ca:	00001597          	auipc	a1,0x1
    802000ce:	9a458593          	addi	a1,a1,-1628 # 80200a6e <etext>
    802000d2:	00001517          	auipc	a0,0x1
    802000d6:	a0650513          	addi	a0,a0,-1530 # 80200ad8 <etext+0x6a>
    802000da:	f99ff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  edata  0x%016x (virtual)\n", edata);
    802000de:	00004597          	auipc	a1,0x4
    802000e2:	f3258593          	addi	a1,a1,-206 # 80204010 <edata>
    802000e6:	00001517          	auipc	a0,0x1
    802000ea:	a1250513          	addi	a0,a0,-1518 # 80200af8 <etext+0x8a>
    802000ee:	f85ff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  end    0x%016x (virtual)\n", end);
    802000f2:	00004597          	auipc	a1,0x4
    802000f6:	f3658593          	addi	a1,a1,-202 # 80204028 <end>
    802000fa:	00001517          	auipc	a0,0x1
    802000fe:	a1e50513          	addi	a0,a0,-1506 # 80200b18 <etext+0xaa>
    80200102:	f71ff0ef          	jal	ra,80200072 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
    80200106:	00004597          	auipc	a1,0x4
    8020010a:	32158593          	addi	a1,a1,801 # 80204427 <end+0x3ff>
    8020010e:	00000797          	auipc	a5,0x0
    80200112:	efe78793          	addi	a5,a5,-258 # 8020000c <kern_init>
    80200116:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
    8020011a:	43f7d593          	srai	a1,a5,0x3f
}
    8020011e:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
    80200120:	3ff5f593          	andi	a1,a1,1023
    80200124:	95be                	add	a1,a1,a5
    80200126:	85a9                	srai	a1,a1,0xa
    80200128:	00001517          	auipc	a0,0x1
    8020012c:	a1050513          	addi	a0,a0,-1520 # 80200b38 <etext+0xca>
}
    80200130:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
    80200132:	f41ff06f          	j	80200072 <cprintf>

0000000080200136 <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    80200136:	1141                	addi	sp,sp,-16
    80200138:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
    8020013a:	02000793          	li	a5,32
    8020013e:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
    80200142:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
    80200146:	67e1                	lui	a5,0x18
    80200148:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0x801e7960>
    8020014c:	953e                	add	a0,a0,a5
    8020014e:	0b1000ef          	jal	ra,802009fe <sbi_set_timer>
}
    80200152:	60a2                	ld	ra,8(sp)
    ticks = 0;
    80200154:	00004797          	auipc	a5,0x4
    80200158:	ec07b623          	sd	zero,-308(a5) # 80204020 <ticks>
    cprintf("++ setup timer interrupts\n");
    8020015c:	00001517          	auipc	a0,0x1
    80200160:	a0c50513          	addi	a0,a0,-1524 # 80200b68 <etext+0xfa>
}
    80200164:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
    80200166:	f0dff06f          	j	80200072 <cprintf>

000000008020016a <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
    8020016a:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
    8020016e:	67e1                	lui	a5,0x18
    80200170:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0x801e7960>
    80200174:	953e                	add	a0,a0,a5
    80200176:	0890006f          	j	802009fe <sbi_set_timer>

000000008020017a <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
    8020017a:	8082                	ret

000000008020017c <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
    8020017c:	0ff57513          	andi	a0,a0,255
    80200180:	0630006f          	j	802009e2 <sbi_console_putchar>

0000000080200184 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
    80200184:	100167f3          	csrrsi	a5,sstatus,2
    80200188:	8082                	ret

000000008020018a <idt_init>:
 */
void idt_init(void) {
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
    8020018a:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
    8020018e:	00000797          	auipc	a5,0x0
    80200192:	3a678793          	addi	a5,a5,934 # 80200534 <__alltraps>
    80200196:	10579073          	csrw	stvec,a5
}
    8020019a:	8082                	ret

000000008020019c <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
    8020019c:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
    8020019e:	1141                	addi	sp,sp,-16
    802001a0:	e022                	sd	s0,0(sp)
    802001a2:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
    802001a4:	00001517          	auipc	a0,0x1
    802001a8:	b4c50513          	addi	a0,a0,-1204 # 80200cf0 <etext+0x282>
void print_regs(struct pushregs *gpr) {
    802001ac:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
    802001ae:	ec5ff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
    802001b2:	640c                	ld	a1,8(s0)
    802001b4:	00001517          	auipc	a0,0x1
    802001b8:	b5450513          	addi	a0,a0,-1196 # 80200d08 <etext+0x29a>
    802001bc:	eb7ff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
    802001c0:	680c                	ld	a1,16(s0)
    802001c2:	00001517          	auipc	a0,0x1
    802001c6:	b5e50513          	addi	a0,a0,-1186 # 80200d20 <etext+0x2b2>
    802001ca:	ea9ff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
    802001ce:	6c0c                	ld	a1,24(s0)
    802001d0:	00001517          	auipc	a0,0x1
    802001d4:	b6850513          	addi	a0,a0,-1176 # 80200d38 <etext+0x2ca>
    802001d8:	e9bff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
    802001dc:	700c                	ld	a1,32(s0)
    802001de:	00001517          	auipc	a0,0x1
    802001e2:	b7250513          	addi	a0,a0,-1166 # 80200d50 <etext+0x2e2>
    802001e6:	e8dff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
    802001ea:	740c                	ld	a1,40(s0)
    802001ec:	00001517          	auipc	a0,0x1
    802001f0:	b7c50513          	addi	a0,a0,-1156 # 80200d68 <etext+0x2fa>
    802001f4:	e7fff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
    802001f8:	780c                	ld	a1,48(s0)
    802001fa:	00001517          	auipc	a0,0x1
    802001fe:	b8650513          	addi	a0,a0,-1146 # 80200d80 <etext+0x312>
    80200202:	e71ff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
    80200206:	7c0c                	ld	a1,56(s0)
    80200208:	00001517          	auipc	a0,0x1
    8020020c:	b9050513          	addi	a0,a0,-1136 # 80200d98 <etext+0x32a>
    80200210:	e63ff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
    80200214:	602c                	ld	a1,64(s0)
    80200216:	00001517          	auipc	a0,0x1
    8020021a:	b9a50513          	addi	a0,a0,-1126 # 80200db0 <etext+0x342>
    8020021e:	e55ff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
    80200222:	642c                	ld	a1,72(s0)
    80200224:	00001517          	auipc	a0,0x1
    80200228:	ba450513          	addi	a0,a0,-1116 # 80200dc8 <etext+0x35a>
    8020022c:	e47ff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
    80200230:	682c                	ld	a1,80(s0)
    80200232:	00001517          	auipc	a0,0x1
    80200236:	bae50513          	addi	a0,a0,-1106 # 80200de0 <etext+0x372>
    8020023a:	e39ff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
    8020023e:	6c2c                	ld	a1,88(s0)
    80200240:	00001517          	auipc	a0,0x1
    80200244:	bb850513          	addi	a0,a0,-1096 # 80200df8 <etext+0x38a>
    80200248:	e2bff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
    8020024c:	702c                	ld	a1,96(s0)
    8020024e:	00001517          	auipc	a0,0x1
    80200252:	bc250513          	addi	a0,a0,-1086 # 80200e10 <etext+0x3a2>
    80200256:	e1dff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
    8020025a:	742c                	ld	a1,104(s0)
    8020025c:	00001517          	auipc	a0,0x1
    80200260:	bcc50513          	addi	a0,a0,-1076 # 80200e28 <etext+0x3ba>
    80200264:	e0fff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
    80200268:	782c                	ld	a1,112(s0)
    8020026a:	00001517          	auipc	a0,0x1
    8020026e:	bd650513          	addi	a0,a0,-1066 # 80200e40 <etext+0x3d2>
    80200272:	e01ff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
    80200276:	7c2c                	ld	a1,120(s0)
    80200278:	00001517          	auipc	a0,0x1
    8020027c:	be050513          	addi	a0,a0,-1056 # 80200e58 <etext+0x3ea>
    80200280:	df3ff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
    80200284:	604c                	ld	a1,128(s0)
    80200286:	00001517          	auipc	a0,0x1
    8020028a:	bea50513          	addi	a0,a0,-1046 # 80200e70 <etext+0x402>
    8020028e:	de5ff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
    80200292:	644c                	ld	a1,136(s0)
    80200294:	00001517          	auipc	a0,0x1
    80200298:	bf450513          	addi	a0,a0,-1036 # 80200e88 <etext+0x41a>
    8020029c:	dd7ff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
    802002a0:	684c                	ld	a1,144(s0)
    802002a2:	00001517          	auipc	a0,0x1
    802002a6:	bfe50513          	addi	a0,a0,-1026 # 80200ea0 <etext+0x432>
    802002aa:	dc9ff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
    802002ae:	6c4c                	ld	a1,152(s0)
    802002b0:	00001517          	auipc	a0,0x1
    802002b4:	c0850513          	addi	a0,a0,-1016 # 80200eb8 <etext+0x44a>
    802002b8:	dbbff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
    802002bc:	704c                	ld	a1,160(s0)
    802002be:	00001517          	auipc	a0,0x1
    802002c2:	c1250513          	addi	a0,a0,-1006 # 80200ed0 <etext+0x462>
    802002c6:	dadff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
    802002ca:	744c                	ld	a1,168(s0)
    802002cc:	00001517          	auipc	a0,0x1
    802002d0:	c1c50513          	addi	a0,a0,-996 # 80200ee8 <etext+0x47a>
    802002d4:	d9fff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
    802002d8:	784c                	ld	a1,176(s0)
    802002da:	00001517          	auipc	a0,0x1
    802002de:	c2650513          	addi	a0,a0,-986 # 80200f00 <etext+0x492>
    802002e2:	d91ff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
    802002e6:	7c4c                	ld	a1,184(s0)
    802002e8:	00001517          	auipc	a0,0x1
    802002ec:	c3050513          	addi	a0,a0,-976 # 80200f18 <etext+0x4aa>
    802002f0:	d83ff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
    802002f4:	606c                	ld	a1,192(s0)
    802002f6:	00001517          	auipc	a0,0x1
    802002fa:	c3a50513          	addi	a0,a0,-966 # 80200f30 <etext+0x4c2>
    802002fe:	d75ff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
    80200302:	646c                	ld	a1,200(s0)
    80200304:	00001517          	auipc	a0,0x1
    80200308:	c4450513          	addi	a0,a0,-956 # 80200f48 <etext+0x4da>
    8020030c:	d67ff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
    80200310:	686c                	ld	a1,208(s0)
    80200312:	00001517          	auipc	a0,0x1
    80200316:	c4e50513          	addi	a0,a0,-946 # 80200f60 <etext+0x4f2>
    8020031a:	d59ff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
    8020031e:	6c6c                	ld	a1,216(s0)
    80200320:	00001517          	auipc	a0,0x1
    80200324:	c5850513          	addi	a0,a0,-936 # 80200f78 <etext+0x50a>
    80200328:	d4bff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
    8020032c:	706c                	ld	a1,224(s0)
    8020032e:	00001517          	auipc	a0,0x1
    80200332:	c6250513          	addi	a0,a0,-926 # 80200f90 <etext+0x522>
    80200336:	d3dff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
    8020033a:	746c                	ld	a1,232(s0)
    8020033c:	00001517          	auipc	a0,0x1
    80200340:	c6c50513          	addi	a0,a0,-916 # 80200fa8 <etext+0x53a>
    80200344:	d2fff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
    80200348:	786c                	ld	a1,240(s0)
    8020034a:	00001517          	auipc	a0,0x1
    8020034e:	c7650513          	addi	a0,a0,-906 # 80200fc0 <etext+0x552>
    80200352:	d21ff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
    80200356:	7c6c                	ld	a1,248(s0)
}
    80200358:	6402                	ld	s0,0(sp)
    8020035a:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
    8020035c:	00001517          	auipc	a0,0x1
    80200360:	c7c50513          	addi	a0,a0,-900 # 80200fd8 <etext+0x56a>
}
    80200364:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
    80200366:	d0dff06f          	j	80200072 <cprintf>

000000008020036a <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
    8020036a:	1141                	addi	sp,sp,-16
    8020036c:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
    8020036e:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
    80200370:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
    80200372:	00001517          	auipc	a0,0x1
    80200376:	c7e50513          	addi	a0,a0,-898 # 80200ff0 <etext+0x582>
void print_trapframe(struct trapframe *tf) {
    8020037a:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
    8020037c:	cf7ff0ef          	jal	ra,80200072 <cprintf>
    print_regs(&tf->gpr);
    80200380:	8522                	mv	a0,s0
    80200382:	e1bff0ef          	jal	ra,8020019c <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
    80200386:	10043583          	ld	a1,256(s0)
    8020038a:	00001517          	auipc	a0,0x1
    8020038e:	c7e50513          	addi	a0,a0,-898 # 80201008 <etext+0x59a>
    80200392:	ce1ff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
    80200396:	10843583          	ld	a1,264(s0)
    8020039a:	00001517          	auipc	a0,0x1
    8020039e:	c8650513          	addi	a0,a0,-890 # 80201020 <etext+0x5b2>
    802003a2:	cd1ff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    802003a6:	11043583          	ld	a1,272(s0)
    802003aa:	00001517          	auipc	a0,0x1
    802003ae:	c8e50513          	addi	a0,a0,-882 # 80201038 <etext+0x5ca>
    802003b2:	cc1ff0ef          	jal	ra,80200072 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
    802003b6:	11843583          	ld	a1,280(s0)
}
    802003ba:	6402                	ld	s0,0(sp)
    802003bc:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
    802003be:	00001517          	auipc	a0,0x1
    802003c2:	c9250513          	addi	a0,a0,-878 # 80201050 <etext+0x5e2>
}
    802003c6:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
    802003c8:	cabff06f          	j	80200072 <cprintf>

00000000802003cc <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    802003cc:	11853783          	ld	a5,280(a0)
    802003d0:	577d                	li	a4,-1
    802003d2:	8305                	srli	a4,a4,0x1
    802003d4:	8ff9                	and	a5,a5,a4
    switch (cause) {
    802003d6:	472d                	li	a4,11
    802003d8:	06f76f63          	bltu	a4,a5,80200456 <interrupt_handler+0x8a>
    802003dc:	00000717          	auipc	a4,0x0
    802003e0:	7a870713          	addi	a4,a4,1960 # 80200b84 <etext+0x116>
    802003e4:	078a                	slli	a5,a5,0x2
    802003e6:	97ba                	add	a5,a5,a4
    802003e8:	439c                	lw	a5,0(a5)
    802003ea:	97ba                	add	a5,a5,a4
    802003ec:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
    802003ee:	00001517          	auipc	a0,0x1
    802003f2:	8b250513          	addi	a0,a0,-1870 # 80200ca0 <etext+0x232>
    802003f6:	c7dff06f          	j	80200072 <cprintf>
            cprintf("Hypervisor software interrupt\n");
    802003fa:	00001517          	auipc	a0,0x1
    802003fe:	88650513          	addi	a0,a0,-1914 # 80200c80 <etext+0x212>
    80200402:	c71ff06f          	j	80200072 <cprintf>
            cprintf("User software interrupt\n");
    80200406:	00001517          	auipc	a0,0x1
    8020040a:	83a50513          	addi	a0,a0,-1990 # 80200c40 <etext+0x1d2>
    8020040e:	c65ff06f          	j	80200072 <cprintf>
            cprintf("Supervisor software interrupt\n");
    80200412:	00001517          	auipc	a0,0x1
    80200416:	84e50513          	addi	a0,a0,-1970 # 80200c60 <etext+0x1f2>
    8020041a:	c59ff06f          	j	80200072 <cprintf>
            break;
        case IRQ_U_EXT:
            cprintf("User software interrupt\n");
            break;
        case IRQ_S_EXT:
            cprintf("Supervisor external interrupt\n");
    8020041e:	00001517          	auipc	a0,0x1
    80200422:	8b250513          	addi	a0,a0,-1870 # 80200cd0 <etext+0x262>
    80200426:	c4dff06f          	j	80200072 <cprintf>
void interrupt_handler(struct trapframe *tf) {
    8020042a:	1141                	addi	sp,sp,-16
    8020042c:	e406                	sd	ra,8(sp)
            clock_set_next_event();
    8020042e:	d3dff0ef          	jal	ra,8020016a <clock_set_next_event>
            if(++ticks % TICK_NUM == 0) {
    80200432:	00004797          	auipc	a5,0x4
    80200436:	bee78793          	addi	a5,a5,-1042 # 80204020 <ticks>
    8020043a:	639c                	ld	a5,0(a5)
    8020043c:	06400713          	li	a4,100
    80200440:	0785                	addi	a5,a5,1
    80200442:	02e7f733          	remu	a4,a5,a4
    80200446:	00004697          	auipc	a3,0x4
    8020044a:	bcf6bd23          	sd	a5,-1062(a3) # 80204020 <ticks>
    8020044e:	c711                	beqz	a4,8020045a <interrupt_handler+0x8e>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
    80200450:	60a2                	ld	ra,8(sp)
    80200452:	0141                	addi	sp,sp,16
    80200454:	8082                	ret
            print_trapframe(tf);
    80200456:	f15ff06f          	j	8020036a <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
    8020045a:	06400593          	li	a1,100
    8020045e:	00001517          	auipc	a0,0x1
    80200462:	86250513          	addi	a0,a0,-1950 # 80200cc0 <etext+0x252>
    80200466:	c0dff0ef          	jal	ra,80200072 <cprintf>
                num++;
    8020046a:	00004717          	auipc	a4,0x4
    8020046e:	ba670713          	addi	a4,a4,-1114 # 80204010 <edata>
    80200472:	631c                	ld	a5,0(a4)
                if(num==10){                   
    80200474:	46a9                	li	a3,10
                num++;
    80200476:	0785                	addi	a5,a5,1
    80200478:	00004617          	auipc	a2,0x4
    8020047c:	b8f63c23          	sd	a5,-1128(a2) # 80204010 <edata>
                if(num==10){                   
    80200480:	631c                	ld	a5,0(a4)
    80200482:	fcd797e3          	bne	a5,a3,80200450 <interrupt_handler+0x84>
}
    80200486:	60a2                	ld	ra,8(sp)
    80200488:	0141                	addi	sp,sp,16
                    sbi_shutdown();
    8020048a:	5900006f          	j	80200a1a <sbi_shutdown>

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
    802004be:	eadff06f          	j	8020036a <print_trapframe>
    802004c2:	8082                	ret
    802004c4:	ea7ff06f          	j	8020036a <print_trapframe>
            cprintf("Exception type: Illegal instruction\n");
    802004c8:	00000517          	auipc	a0,0x0
    802004cc:	6f050513          	addi	a0,a0,1776 # 80200bb8 <etext+0x14a>
    802004d0:	ba3ff0ef          	jal	ra,80200072 <cprintf>
            cprintf("Illegal instruction caught at 0x%x\n",tf->epc);
    802004d4:	10843583          	ld	a1,264(s0)
    802004d8:	00000517          	auipc	a0,0x0
    802004dc:	70850513          	addi	a0,a0,1800 # 80200be0 <etext+0x172>
    802004e0:	b93ff0ef          	jal	ra,80200072 <cprintf>
            tf->epc+=4;
    802004e4:	10843783          	ld	a5,264(s0)
}
    802004e8:	60a2                	ld	ra,8(sp)
            tf->epc+=4;
    802004ea:	0791                	addi	a5,a5,4
    802004ec:	10f43423          	sd	a5,264(s0)
}
    802004f0:	6402                	ld	s0,0(sp)
    802004f2:	0141                	addi	sp,sp,16
    802004f4:	8082                	ret
            cprintf("Exception type: breakpoint\n");
    802004f6:	00000517          	auipc	a0,0x0
    802004fa:	71250513          	addi	a0,a0,1810 # 80200c08 <etext+0x19a>
    802004fe:	b75ff0ef          	jal	ra,80200072 <cprintf>
            cprintf("ebreak caught at 0x%x\n",tf->epc);
    80200502:	10843583          	ld	a1,264(s0)
    80200506:	00000517          	auipc	a0,0x0
    8020050a:	72250513          	addi	a0,a0,1826 # 80200c28 <etext+0x1ba>
    8020050e:	b65ff0ef          	jal	ra,80200072 <cprintf>
            tf->epc+=2;
    80200512:	10843783          	ld	a5,264(s0)
}
    80200516:	60a2                	ld	ra,8(sp)
            tf->epc+=2;
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
    80200530:	e9dff06f          	j	802003cc <interrupt_handler>

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

00000000802005ea <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
    802005ea:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
    802005ee:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
    802005f0:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
    802005f4:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
    802005f6:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
    802005fa:	f022                	sd	s0,32(sp)
    802005fc:	ec26                	sd	s1,24(sp)
    802005fe:	e84a                	sd	s2,16(sp)
    80200600:	f406                	sd	ra,40(sp)
    80200602:	e44e                	sd	s3,8(sp)
    80200604:	84aa                	mv	s1,a0
    80200606:	892e                	mv	s2,a1
    80200608:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
    8020060c:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
    8020060e:	03067e63          	bleu	a6,a2,8020064a <printnum+0x60>
    80200612:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
    80200614:	00805763          	blez	s0,80200622 <printnum+0x38>
    80200618:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
    8020061a:	85ca                	mv	a1,s2
    8020061c:	854e                	mv	a0,s3
    8020061e:	9482                	jalr	s1
        while (-- width > 0)
    80200620:	fc65                	bnez	s0,80200618 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
    80200622:	1a02                	slli	s4,s4,0x20
    80200624:	020a5a13          	srli	s4,s4,0x20
    80200628:	00001797          	auipc	a5,0x1
    8020062c:	bd078793          	addi	a5,a5,-1072 # 802011f8 <error_string+0x38>
    80200630:	9a3e                	add	s4,s4,a5
}
    80200632:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
    80200634:	000a4503          	lbu	a0,0(s4)
}
    80200638:	70a2                	ld	ra,40(sp)
    8020063a:	69a2                	ld	s3,8(sp)
    8020063c:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
    8020063e:	85ca                	mv	a1,s2
    80200640:	8326                	mv	t1,s1
}
    80200642:	6942                	ld	s2,16(sp)
    80200644:	64e2                	ld	s1,24(sp)
    80200646:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
    80200648:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
    8020064a:	03065633          	divu	a2,a2,a6
    8020064e:	8722                	mv	a4,s0
    80200650:	f9bff0ef          	jal	ra,802005ea <printnum>
    80200654:	b7f9                	j	80200622 <printnum+0x38>

0000000080200656 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
    80200656:	7119                	addi	sp,sp,-128
    80200658:	f4a6                	sd	s1,104(sp)
    8020065a:	f0ca                	sd	s2,96(sp)
    8020065c:	e8d2                	sd	s4,80(sp)
    8020065e:	e4d6                	sd	s5,72(sp)
    80200660:	e0da                	sd	s6,64(sp)
    80200662:	fc5e                	sd	s7,56(sp)
    80200664:	f862                	sd	s8,48(sp)
    80200666:	f06a                	sd	s10,32(sp)
    80200668:	fc86                	sd	ra,120(sp)
    8020066a:	f8a2                	sd	s0,112(sp)
    8020066c:	ecce                	sd	s3,88(sp)
    8020066e:	f466                	sd	s9,40(sp)
    80200670:	ec6e                	sd	s11,24(sp)
    80200672:	892a                	mv	s2,a0
    80200674:	84ae                	mv	s1,a1
    80200676:	8d32                	mv	s10,a2
    80200678:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
    8020067a:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
    8020067c:	00001a17          	auipc	s4,0x1
    80200680:	9e8a0a13          	addi	s4,s4,-1560 # 80201064 <etext+0x5f6>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
    80200684:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    80200688:	00001c17          	auipc	s8,0x1
    8020068c:	b38c0c13          	addi	s8,s8,-1224 # 802011c0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    80200690:	000d4503          	lbu	a0,0(s10)
    80200694:	02500793          	li	a5,37
    80200698:	001d0413          	addi	s0,s10,1
    8020069c:	00f50e63          	beq	a0,a5,802006b8 <vprintfmt+0x62>
            if (ch == '\0') {
    802006a0:	c521                	beqz	a0,802006e8 <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    802006a2:	02500993          	li	s3,37
    802006a6:	a011                	j	802006aa <vprintfmt+0x54>
            if (ch == '\0') {
    802006a8:	c121                	beqz	a0,802006e8 <vprintfmt+0x92>
            putch(ch, putdat);
    802006aa:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    802006ac:	0405                	addi	s0,s0,1
            putch(ch, putdat);
    802006ae:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    802006b0:	fff44503          	lbu	a0,-1(s0)
    802006b4:	ff351ae3          	bne	a0,s3,802006a8 <vprintfmt+0x52>
    802006b8:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
    802006bc:	02000793          	li	a5,32
        lflag = altflag = 0;
    802006c0:	4981                	li	s3,0
    802006c2:	4801                	li	a6,0
        width = precision = -1;
    802006c4:	5cfd                	li	s9,-1
    802006c6:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
    802006c8:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
    802006cc:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
    802006ce:	fdd6069b          	addiw	a3,a2,-35
    802006d2:	0ff6f693          	andi	a3,a3,255
    802006d6:	00140d13          	addi	s10,s0,1
    802006da:	20d5e563          	bltu	a1,a3,802008e4 <vprintfmt+0x28e>
    802006de:	068a                	slli	a3,a3,0x2
    802006e0:	96d2                	add	a3,a3,s4
    802006e2:	4294                	lw	a3,0(a3)
    802006e4:	96d2                	add	a3,a3,s4
    802006e6:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
    802006e8:	70e6                	ld	ra,120(sp)
    802006ea:	7446                	ld	s0,112(sp)
    802006ec:	74a6                	ld	s1,104(sp)
    802006ee:	7906                	ld	s2,96(sp)
    802006f0:	69e6                	ld	s3,88(sp)
    802006f2:	6a46                	ld	s4,80(sp)
    802006f4:	6aa6                	ld	s5,72(sp)
    802006f6:	6b06                	ld	s6,64(sp)
    802006f8:	7be2                	ld	s7,56(sp)
    802006fa:	7c42                	ld	s8,48(sp)
    802006fc:	7ca2                	ld	s9,40(sp)
    802006fe:	7d02                	ld	s10,32(sp)
    80200700:	6de2                	ld	s11,24(sp)
    80200702:	6109                	addi	sp,sp,128
    80200704:	8082                	ret
    if (lflag >= 2) {
    80200706:	4705                	li	a4,1
    80200708:	008a8593          	addi	a1,s5,8
    8020070c:	01074463          	blt	a4,a6,80200714 <vprintfmt+0xbe>
    else if (lflag) {
    80200710:	26080363          	beqz	a6,80200976 <vprintfmt+0x320>
        return va_arg(*ap, unsigned long);
    80200714:	000ab603          	ld	a2,0(s5)
    80200718:	46c1                	li	a3,16
    8020071a:	8aae                	mv	s5,a1
    8020071c:	a06d                	j	802007c6 <vprintfmt+0x170>
            goto reswitch;
    8020071e:	00144603          	lbu	a2,1(s0)
            altflag = 1;
    80200722:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
    80200724:	846a                	mv	s0,s10
            goto reswitch;
    80200726:	b765                	j	802006ce <vprintfmt+0x78>
            putch(va_arg(ap, int), putdat);
    80200728:	000aa503          	lw	a0,0(s5)
    8020072c:	85a6                	mv	a1,s1
    8020072e:	0aa1                	addi	s5,s5,8
    80200730:	9902                	jalr	s2
            break;
    80200732:	bfb9                	j	80200690 <vprintfmt+0x3a>
    if (lflag >= 2) {
    80200734:	4705                	li	a4,1
    80200736:	008a8993          	addi	s3,s5,8
    8020073a:	01074463          	blt	a4,a6,80200742 <vprintfmt+0xec>
    else if (lflag) {
    8020073e:	22080463          	beqz	a6,80200966 <vprintfmt+0x310>
        return va_arg(*ap, long);
    80200742:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
    80200746:	24044463          	bltz	s0,8020098e <vprintfmt+0x338>
            num = getint(&ap, lflag);
    8020074a:	8622                	mv	a2,s0
    8020074c:	8ace                	mv	s5,s3
    8020074e:	46a9                	li	a3,10
    80200750:	a89d                	j	802007c6 <vprintfmt+0x170>
            err = va_arg(ap, int);
    80200752:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    80200756:	4719                	li	a4,6
            err = va_arg(ap, int);
    80200758:	0aa1                	addi	s5,s5,8
            if (err < 0) {
    8020075a:	41f7d69b          	sraiw	a3,a5,0x1f
    8020075e:	8fb5                	xor	a5,a5,a3
    80200760:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    80200764:	1ad74363          	blt	a4,a3,8020090a <vprintfmt+0x2b4>
    80200768:	00369793          	slli	a5,a3,0x3
    8020076c:	97e2                	add	a5,a5,s8
    8020076e:	639c                	ld	a5,0(a5)
    80200770:	18078d63          	beqz	a5,8020090a <vprintfmt+0x2b4>
                printfmt(putch, putdat, "%s", p);
    80200774:	86be                	mv	a3,a5
    80200776:	00001617          	auipc	a2,0x1
    8020077a:	b3260613          	addi	a2,a2,-1230 # 802012a8 <error_string+0xe8>
    8020077e:	85a6                	mv	a1,s1
    80200780:	854a                	mv	a0,s2
    80200782:	240000ef          	jal	ra,802009c2 <printfmt>
    80200786:	b729                	j	80200690 <vprintfmt+0x3a>
            lflag ++;
    80200788:	00144603          	lbu	a2,1(s0)
    8020078c:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
    8020078e:	846a                	mv	s0,s10
            goto reswitch;
    80200790:	bf3d                	j	802006ce <vprintfmt+0x78>
    if (lflag >= 2) {
    80200792:	4705                	li	a4,1
    80200794:	008a8593          	addi	a1,s5,8
    80200798:	01074463          	blt	a4,a6,802007a0 <vprintfmt+0x14a>
    else if (lflag) {
    8020079c:	1e080263          	beqz	a6,80200980 <vprintfmt+0x32a>
        return va_arg(*ap, unsigned long);
    802007a0:	000ab603          	ld	a2,0(s5)
    802007a4:	46a1                	li	a3,8
    802007a6:	8aae                	mv	s5,a1
    802007a8:	a839                	j	802007c6 <vprintfmt+0x170>
            putch('0', putdat);
    802007aa:	03000513          	li	a0,48
    802007ae:	85a6                	mv	a1,s1
    802007b0:	e03e                	sd	a5,0(sp)
    802007b2:	9902                	jalr	s2
            putch('x', putdat);
    802007b4:	85a6                	mv	a1,s1
    802007b6:	07800513          	li	a0,120
    802007ba:	9902                	jalr	s2
            num = (unsigned long long)va_arg(ap, void *);
    802007bc:	0aa1                	addi	s5,s5,8
    802007be:	ff8ab603          	ld	a2,-8(s5)
            goto number;
    802007c2:	6782                	ld	a5,0(sp)
    802007c4:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
    802007c6:	876e                	mv	a4,s11
    802007c8:	85a6                	mv	a1,s1
    802007ca:	854a                	mv	a0,s2
    802007cc:	e1fff0ef          	jal	ra,802005ea <printnum>
            break;
    802007d0:	b5c1                	j	80200690 <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
    802007d2:	000ab603          	ld	a2,0(s5)
    802007d6:	0aa1                	addi	s5,s5,8
    802007d8:	1c060663          	beqz	a2,802009a4 <vprintfmt+0x34e>
            if (width > 0 && padc != '-') {
    802007dc:	00160413          	addi	s0,a2,1
    802007e0:	17b05c63          	blez	s11,80200958 <vprintfmt+0x302>
    802007e4:	02d00593          	li	a1,45
    802007e8:	14b79263          	bne	a5,a1,8020092c <vprintfmt+0x2d6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    802007ec:	00064783          	lbu	a5,0(a2)
    802007f0:	0007851b          	sext.w	a0,a5
    802007f4:	c905                	beqz	a0,80200824 <vprintfmt+0x1ce>
    802007f6:	000cc563          	bltz	s9,80200800 <vprintfmt+0x1aa>
    802007fa:	3cfd                	addiw	s9,s9,-1
    802007fc:	036c8263          	beq	s9,s6,80200820 <vprintfmt+0x1ca>
                    putch('?', putdat);
    80200800:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
    80200802:	18098463          	beqz	s3,8020098a <vprintfmt+0x334>
    80200806:	3781                	addiw	a5,a5,-32
    80200808:	18fbf163          	bleu	a5,s7,8020098a <vprintfmt+0x334>
                    putch('?', putdat);
    8020080c:	03f00513          	li	a0,63
    80200810:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    80200812:	0405                	addi	s0,s0,1
    80200814:	fff44783          	lbu	a5,-1(s0)
    80200818:	3dfd                	addiw	s11,s11,-1
    8020081a:	0007851b          	sext.w	a0,a5
    8020081e:	fd61                	bnez	a0,802007f6 <vprintfmt+0x1a0>
            for (; width > 0; width --) {
    80200820:	e7b058e3          	blez	s11,80200690 <vprintfmt+0x3a>
    80200824:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
    80200826:	85a6                	mv	a1,s1
    80200828:	02000513          	li	a0,32
    8020082c:	9902                	jalr	s2
            for (; width > 0; width --) {
    8020082e:	e60d81e3          	beqz	s11,80200690 <vprintfmt+0x3a>
    80200832:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
    80200834:	85a6                	mv	a1,s1
    80200836:	02000513          	li	a0,32
    8020083a:	9902                	jalr	s2
            for (; width > 0; width --) {
    8020083c:	fe0d94e3          	bnez	s11,80200824 <vprintfmt+0x1ce>
    80200840:	bd81                	j	80200690 <vprintfmt+0x3a>
    if (lflag >= 2) {
    80200842:	4705                	li	a4,1
    80200844:	008a8593          	addi	a1,s5,8
    80200848:	01074463          	blt	a4,a6,80200850 <vprintfmt+0x1fa>
    else if (lflag) {
    8020084c:	12080063          	beqz	a6,8020096c <vprintfmt+0x316>
        return va_arg(*ap, unsigned long);
    80200850:	000ab603          	ld	a2,0(s5)
    80200854:	46a9                	li	a3,10
    80200856:	8aae                	mv	s5,a1
    80200858:	b7bd                	j	802007c6 <vprintfmt+0x170>
    8020085a:	00144603          	lbu	a2,1(s0)
            padc = '-';
    8020085e:	02d00793          	li	a5,45
        switch (ch = *(unsigned char *)fmt ++) {
    80200862:	846a                	mv	s0,s10
    80200864:	b5ad                	j	802006ce <vprintfmt+0x78>
            putch(ch, putdat);
    80200866:	85a6                	mv	a1,s1
    80200868:	02500513          	li	a0,37
    8020086c:	9902                	jalr	s2
            break;
    8020086e:	b50d                	j	80200690 <vprintfmt+0x3a>
            precision = va_arg(ap, int);
    80200870:	000aac83          	lw	s9,0(s5)
            goto process_precision;
    80200874:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
    80200878:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
    8020087a:	846a                	mv	s0,s10
            if (width < 0)
    8020087c:	e40dd9e3          	bgez	s11,802006ce <vprintfmt+0x78>
                width = precision, precision = -1;
    80200880:	8de6                	mv	s11,s9
    80200882:	5cfd                	li	s9,-1
    80200884:	b5a9                	j	802006ce <vprintfmt+0x78>
            goto reswitch;
    80200886:	00144603          	lbu	a2,1(s0)
            padc = '0';
    8020088a:	03000793          	li	a5,48
        switch (ch = *(unsigned char *)fmt ++) {
    8020088e:	846a                	mv	s0,s10
            goto reswitch;
    80200890:	bd3d                	j	802006ce <vprintfmt+0x78>
                precision = precision * 10 + ch - '0';
    80200892:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
    80200896:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
    8020089a:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
    8020089c:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
    802008a0:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
    802008a4:	fcd56ce3          	bltu	a0,a3,8020087c <vprintfmt+0x226>
            for (precision = 0; ; ++ fmt) {
    802008a8:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
    802008aa:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
    802008ae:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
    802008b2:	0196873b          	addw	a4,a3,s9
    802008b6:	0017171b          	slliw	a4,a4,0x1
    802008ba:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
    802008be:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
    802008c2:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
    802008c6:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
    802008ca:	fcd57fe3          	bleu	a3,a0,802008a8 <vprintfmt+0x252>
    802008ce:	b77d                	j	8020087c <vprintfmt+0x226>
            if (width < 0)
    802008d0:	fffdc693          	not	a3,s11
    802008d4:	96fd                	srai	a3,a3,0x3f
    802008d6:	00ddfdb3          	and	s11,s11,a3
    802008da:	00144603          	lbu	a2,1(s0)
    802008de:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
    802008e0:	846a                	mv	s0,s10
    802008e2:	b3f5                	j	802006ce <vprintfmt+0x78>
            putch('%', putdat);
    802008e4:	85a6                	mv	a1,s1
    802008e6:	02500513          	li	a0,37
    802008ea:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
    802008ec:	fff44703          	lbu	a4,-1(s0)
    802008f0:	02500793          	li	a5,37
    802008f4:	8d22                	mv	s10,s0
    802008f6:	d8f70de3          	beq	a4,a5,80200690 <vprintfmt+0x3a>
    802008fa:	02500713          	li	a4,37
    802008fe:	1d7d                	addi	s10,s10,-1
    80200900:	fffd4783          	lbu	a5,-1(s10)
    80200904:	fee79de3          	bne	a5,a4,802008fe <vprintfmt+0x2a8>
    80200908:	b361                	j	80200690 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
    8020090a:	00001617          	auipc	a2,0x1
    8020090e:	98e60613          	addi	a2,a2,-1650 # 80201298 <error_string+0xd8>
    80200912:	85a6                	mv	a1,s1
    80200914:	854a                	mv	a0,s2
    80200916:	0ac000ef          	jal	ra,802009c2 <printfmt>
    8020091a:	bb9d                	j	80200690 <vprintfmt+0x3a>
                p = "(null)";
    8020091c:	00001617          	auipc	a2,0x1
    80200920:	97460613          	addi	a2,a2,-1676 # 80201290 <error_string+0xd0>
            if (width > 0 && padc != '-') {
    80200924:	00001417          	auipc	s0,0x1
    80200928:	96d40413          	addi	s0,s0,-1683 # 80201291 <error_string+0xd1>
                for (width -= strnlen(p, precision); width > 0; width --) {
    8020092c:	8532                	mv	a0,a2
    8020092e:	85e6                	mv	a1,s9
    80200930:	e032                	sd	a2,0(sp)
    80200932:	e43e                	sd	a5,8(sp)
    80200934:	102000ef          	jal	ra,80200a36 <strnlen>
    80200938:	40ad8dbb          	subw	s11,s11,a0
    8020093c:	6602                	ld	a2,0(sp)
    8020093e:	01b05d63          	blez	s11,80200958 <vprintfmt+0x302>
    80200942:	67a2                	ld	a5,8(sp)
    80200944:	2781                	sext.w	a5,a5
    80200946:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
    80200948:	6522                	ld	a0,8(sp)
    8020094a:	85a6                	mv	a1,s1
    8020094c:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
    8020094e:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
    80200950:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
    80200952:	6602                	ld	a2,0(sp)
    80200954:	fe0d9ae3          	bnez	s11,80200948 <vprintfmt+0x2f2>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    80200958:	00064783          	lbu	a5,0(a2)
    8020095c:	0007851b          	sext.w	a0,a5
    80200960:	e8051be3          	bnez	a0,802007f6 <vprintfmt+0x1a0>
    80200964:	b335                	j	80200690 <vprintfmt+0x3a>
        return va_arg(*ap, int);
    80200966:	000aa403          	lw	s0,0(s5)
    8020096a:	bbf1                	j	80200746 <vprintfmt+0xf0>
        return va_arg(*ap, unsigned int);
    8020096c:	000ae603          	lwu	a2,0(s5)
    80200970:	46a9                	li	a3,10
    80200972:	8aae                	mv	s5,a1
    80200974:	bd89                	j	802007c6 <vprintfmt+0x170>
    80200976:	000ae603          	lwu	a2,0(s5)
    8020097a:	46c1                	li	a3,16
    8020097c:	8aae                	mv	s5,a1
    8020097e:	b5a1                	j	802007c6 <vprintfmt+0x170>
    80200980:	000ae603          	lwu	a2,0(s5)
    80200984:	46a1                	li	a3,8
    80200986:	8aae                	mv	s5,a1
    80200988:	bd3d                	j	802007c6 <vprintfmt+0x170>
                    putch(ch, putdat);
    8020098a:	9902                	jalr	s2
    8020098c:	b559                	j	80200812 <vprintfmt+0x1bc>
                putch('-', putdat);
    8020098e:	85a6                	mv	a1,s1
    80200990:	02d00513          	li	a0,45
    80200994:	e03e                	sd	a5,0(sp)
    80200996:	9902                	jalr	s2
                num = -(long long)num;
    80200998:	8ace                	mv	s5,s3
    8020099a:	40800633          	neg	a2,s0
    8020099e:	46a9                	li	a3,10
    802009a0:	6782                	ld	a5,0(sp)
    802009a2:	b515                	j	802007c6 <vprintfmt+0x170>
            if (width > 0 && padc != '-') {
    802009a4:	01b05663          	blez	s11,802009b0 <vprintfmt+0x35a>
    802009a8:	02d00693          	li	a3,45
    802009ac:	f6d798e3          	bne	a5,a3,8020091c <vprintfmt+0x2c6>
    802009b0:	00001417          	auipc	s0,0x1
    802009b4:	8e140413          	addi	s0,s0,-1823 # 80201291 <error_string+0xd1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    802009b8:	02800513          	li	a0,40
    802009bc:	02800793          	li	a5,40
    802009c0:	bd1d                	j	802007f6 <vprintfmt+0x1a0>

00000000802009c2 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    802009c2:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
    802009c4:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    802009c8:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
    802009ca:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    802009cc:	ec06                	sd	ra,24(sp)
    802009ce:	f83a                	sd	a4,48(sp)
    802009d0:	fc3e                	sd	a5,56(sp)
    802009d2:	e0c2                	sd	a6,64(sp)
    802009d4:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
    802009d6:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
    802009d8:	c7fff0ef          	jal	ra,80200656 <vprintfmt>
}
    802009dc:	60e2                	ld	ra,24(sp)
    802009de:	6161                	addi	sp,sp,80
    802009e0:	8082                	ret

00000000802009e2 <sbi_console_putchar>:

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
    802009e2:	00003797          	auipc	a5,0x3
    802009e6:	61e78793          	addi	a5,a5,1566 # 80204000 <bootstacktop>
    __asm__ volatile (
    802009ea:	6398                	ld	a4,0(a5)
    802009ec:	4781                	li	a5,0
    802009ee:	88ba                	mv	a7,a4
    802009f0:	852a                	mv	a0,a0
    802009f2:	85be                	mv	a1,a5
    802009f4:	863e                	mv	a2,a5
    802009f6:	00000073          	ecall
    802009fa:	87aa                	mv	a5,a0
}
    802009fc:	8082                	ret

00000000802009fe <sbi_set_timer>:

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
    802009fe:	00003797          	auipc	a5,0x3
    80200a02:	61a78793          	addi	a5,a5,1562 # 80204018 <SBI_SET_TIMER>
    __asm__ volatile (
    80200a06:	6398                	ld	a4,0(a5)
    80200a08:	4781                	li	a5,0
    80200a0a:	88ba                	mv	a7,a4
    80200a0c:	852a                	mv	a0,a0
    80200a0e:	85be                	mv	a1,a5
    80200a10:	863e                	mv	a2,a5
    80200a12:	00000073          	ecall
    80200a16:	87aa                	mv	a5,a0
}
    80200a18:	8082                	ret

0000000080200a1a <sbi_shutdown>:


void sbi_shutdown(void)
{
    sbi_call(SBI_SHUTDOWN,0,0,0);
    80200a1a:	00003797          	auipc	a5,0x3
    80200a1e:	5ee78793          	addi	a5,a5,1518 # 80204008 <SBI_SHUTDOWN>
    __asm__ volatile (
    80200a22:	6398                	ld	a4,0(a5)
    80200a24:	4781                	li	a5,0
    80200a26:	88ba                	mv	a7,a4
    80200a28:	853e                	mv	a0,a5
    80200a2a:	85be                	mv	a1,a5
    80200a2c:	863e                	mv	a2,a5
    80200a2e:	00000073          	ecall
    80200a32:	87aa                	mv	a5,a0
    80200a34:	8082                	ret

0000000080200a36 <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
    80200a36:	c185                	beqz	a1,80200a56 <strnlen+0x20>
    80200a38:	00054783          	lbu	a5,0(a0)
    80200a3c:	cf89                	beqz	a5,80200a56 <strnlen+0x20>
    size_t cnt = 0;
    80200a3e:	4781                	li	a5,0
    80200a40:	a021                	j	80200a48 <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
    80200a42:	00074703          	lbu	a4,0(a4)
    80200a46:	c711                	beqz	a4,80200a52 <strnlen+0x1c>
        cnt ++;
    80200a48:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
    80200a4a:	00f50733          	add	a4,a0,a5
    80200a4e:	fef59ae3          	bne	a1,a5,80200a42 <strnlen+0xc>
    }
    return cnt;
}
    80200a52:	853e                	mv	a0,a5
    80200a54:	8082                	ret
    size_t cnt = 0;
    80200a56:	4781                	li	a5,0
}
    80200a58:	853e                	mv	a0,a5
    80200a5a:	8082                	ret

0000000080200a5c <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
    80200a5c:	ca01                	beqz	a2,80200a6c <memset+0x10>
    80200a5e:	962a                	add	a2,a2,a0
    char *p = s;
    80200a60:	87aa                	mv	a5,a0
        *p ++ = c;
    80200a62:	0785                	addi	a5,a5,1
    80200a64:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
    80200a68:	fec79de3          	bne	a5,a2,80200a62 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
    80200a6c:	8082                	ret
