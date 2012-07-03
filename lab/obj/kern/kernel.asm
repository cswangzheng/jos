
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# physical addresses [0, 4MB).  This 4MB region will be suffice
	# until we set up our real page table in mem_init in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 6c 29 11 f0       	mov    $0xf011296c,%eax
f010004b:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f0100063:	e8 3e 15 00 00       	call   f01015a6 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 8f 04 00 00       	call   f01004fc <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 c0 1a 10 f0 	movl   $0xf0101ac0,(%esp)
f010007c:	e8 cd 09 00 00       	call   f0100a4e <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 15 08 00 00       	call   f010089b <mem_init>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 8e 06 00 00       	call   f0100720 <monitor>
f0100092:	eb f2                	jmp    f0100086 <i386_init+0x46>

f0100094 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	56                   	push   %esi
f0100098:	53                   	push   %ebx
f0100099:	83 ec 10             	sub    $0x10,%esp
f010009c:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010009f:	83 3d 00 23 11 f0 00 	cmpl   $0x0,0xf0112300
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 00 23 11 f0    	mov    %esi,0xf0112300

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000ae:	fa                   	cli    
f01000af:	fc                   	cld    

	va_start(ap, fmt);
f01000b0:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000b3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01000bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000c1:	c7 04 24 db 1a 10 f0 	movl   $0xf0101adb,(%esp)
f01000c8:	e8 81 09 00 00       	call   f0100a4e <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 42 09 00 00       	call   f0100a1b <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 17 1b 10 f0 	movl   $0xf0101b17,(%esp)
f01000e0:	e8 69 09 00 00       	call   f0100a4e <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 2f 06 00 00       	call   f0100720 <monitor>
f01000f1:	eb f2                	jmp    f01000e5 <_panic+0x51>

f01000f3 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f3:	55                   	push   %ebp
f01000f4:	89 e5                	mov    %esp,%ebp
f01000f6:	53                   	push   %ebx
f01000f7:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fa:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100100:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100104:	8b 45 08             	mov    0x8(%ebp),%eax
f0100107:	89 44 24 04          	mov    %eax,0x4(%esp)
f010010b:	c7 04 24 f3 1a 10 f0 	movl   $0xf0101af3,(%esp)
f0100112:	e8 37 09 00 00       	call   f0100a4e <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 f5 08 00 00       	call   f0100a1b <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 17 1b 10 f0 	movl   $0xf0101b17,(%esp)
f010012d:	e8 1c 09 00 00       	call   f0100a4e <cprintf>
	va_end(ap);
}
f0100132:	83 c4 14             	add    $0x14,%esp
f0100135:	5b                   	pop    %ebx
f0100136:	5d                   	pop    %ebp
f0100137:	c3                   	ret    
	...

f0100140 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100140:	55                   	push   %ebp
f0100141:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100143:	ba 84 00 00 00       	mov    $0x84,%edx
f0100148:	ec                   	in     (%dx),%al
f0100149:	ec                   	in     (%dx),%al
f010014a:	ec                   	in     (%dx),%al
f010014b:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f010014c:	5d                   	pop    %ebp
f010014d:	c3                   	ret    

f010014e <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010014e:	55                   	push   %ebp
f010014f:	89 e5                	mov    %esp,%ebp
f0100151:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100156:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100157:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
static bool serial_exists;

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010015c:	a8 01                	test   $0x1,%al
f010015e:	74 06                	je     f0100166 <serial_proc_data+0x18>
f0100160:	b2 f8                	mov    $0xf8,%dl
f0100162:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100163:	0f b6 c8             	movzbl %al,%ecx
}
f0100166:	89 c8                	mov    %ecx,%eax
f0100168:	5d                   	pop    %ebp
f0100169:	c3                   	ret    

f010016a <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010016a:	55                   	push   %ebp
f010016b:	89 e5                	mov    %esp,%ebp
f010016d:	53                   	push   %ebx
f010016e:	83 ec 04             	sub    $0x4,%esp
f0100171:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100173:	eb 25                	jmp    f010019a <cons_intr+0x30>
		if (c == 0)
f0100175:	85 c0                	test   %eax,%eax
f0100177:	74 21                	je     f010019a <cons_intr+0x30>
			continue;
		cons.buf[cons.wpos++] = c;
f0100179:	8b 15 44 25 11 f0    	mov    0xf0112544,%edx
f010017f:	88 82 40 23 11 f0    	mov    %al,-0xfeedcc0(%edx)
f0100185:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f0100188:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f010018d:	ba 00 00 00 00       	mov    $0x0,%edx
f0100192:	0f 44 c2             	cmove  %edx,%eax
f0100195:	a3 44 25 11 f0       	mov    %eax,0xf0112544
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f010019a:	ff d3                	call   *%ebx
f010019c:	83 f8 ff             	cmp    $0xffffffff,%eax
f010019f:	75 d4                	jne    f0100175 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001a1:	83 c4 04             	add    $0x4,%esp
f01001a4:	5b                   	pop    %ebx
f01001a5:	5d                   	pop    %ebp
f01001a6:	c3                   	ret    

f01001a7 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01001a7:	55                   	push   %ebp
f01001a8:	89 e5                	mov    %esp,%ebp
f01001aa:	57                   	push   %edi
f01001ab:	56                   	push   %esi
f01001ac:	53                   	push   %ebx
f01001ad:	83 ec 2c             	sub    $0x2c,%esp
f01001b0:	89 c7                	mov    %eax,%edi
f01001b2:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001b7:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01001b8:	a8 20                	test   $0x20,%al
f01001ba:	75 1b                	jne    f01001d7 <cons_putc+0x30>
f01001bc:	bb 00 32 00 00       	mov    $0x3200,%ebx
f01001c1:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f01001c6:	e8 75 ff ff ff       	call   f0100140 <delay>
f01001cb:	89 f2                	mov    %esi,%edx
f01001cd:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01001ce:	a8 20                	test   $0x20,%al
f01001d0:	75 05                	jne    f01001d7 <cons_putc+0x30>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01001d2:	83 eb 01             	sub    $0x1,%ebx
f01001d5:	75 ef                	jne    f01001c6 <cons_putc+0x1f>
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
f01001d7:	89 fa                	mov    %edi,%edx
f01001d9:	89 f8                	mov    %edi,%eax
f01001db:	88 55 e7             	mov    %dl,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01001de:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01001e3:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001e4:	b2 79                	mov    $0x79,%dl
f01001e6:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01001e7:	84 c0                	test   %al,%al
f01001e9:	78 1b                	js     f0100206 <cons_putc+0x5f>
f01001eb:	bb 00 32 00 00       	mov    $0x3200,%ebx
f01001f0:	be 79 03 00 00       	mov    $0x379,%esi
		delay();
f01001f5:	e8 46 ff ff ff       	call   f0100140 <delay>
f01001fa:	89 f2                	mov    %esi,%edx
f01001fc:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01001fd:	84 c0                	test   %al,%al
f01001ff:	78 05                	js     f0100206 <cons_putc+0x5f>
f0100201:	83 eb 01             	sub    $0x1,%ebx
f0100204:	75 ef                	jne    f01001f5 <cons_putc+0x4e>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100206:	ba 78 03 00 00       	mov    $0x378,%edx
f010020b:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010020f:	ee                   	out    %al,(%dx)
f0100210:	b2 7a                	mov    $0x7a,%dl
f0100212:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100217:	ee                   	out    %al,(%dx)
f0100218:	b8 08 00 00 00       	mov    $0x8,%eax
f010021d:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010021e:	89 fa                	mov    %edi,%edx
f0100220:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100226:	89 f8                	mov    %edi,%eax
f0100228:	80 cc 07             	or     $0x7,%ah
f010022b:	85 d2                	test   %edx,%edx
f010022d:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100230:	89 f8                	mov    %edi,%eax
f0100232:	25 ff 00 00 00       	and    $0xff,%eax
f0100237:	83 f8 09             	cmp    $0x9,%eax
f010023a:	74 7c                	je     f01002b8 <cons_putc+0x111>
f010023c:	83 f8 09             	cmp    $0x9,%eax
f010023f:	7f 0b                	jg     f010024c <cons_putc+0xa5>
f0100241:	83 f8 08             	cmp    $0x8,%eax
f0100244:	0f 85 a2 00 00 00    	jne    f01002ec <cons_putc+0x145>
f010024a:	eb 16                	jmp    f0100262 <cons_putc+0xbb>
f010024c:	83 f8 0a             	cmp    $0xa,%eax
f010024f:	90                   	nop
f0100250:	74 40                	je     f0100292 <cons_putc+0xeb>
f0100252:	83 f8 0d             	cmp    $0xd,%eax
f0100255:	0f 85 91 00 00 00    	jne    f01002ec <cons_putc+0x145>
f010025b:	90                   	nop
f010025c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100260:	eb 38                	jmp    f010029a <cons_putc+0xf3>
	case '\b':
		if (crt_pos > 0) {
f0100262:	0f b7 05 54 25 11 f0 	movzwl 0xf0112554,%eax
f0100269:	66 85 c0             	test   %ax,%ax
f010026c:	0f 84 e4 00 00 00    	je     f0100356 <cons_putc+0x1af>
			crt_pos--;
f0100272:	83 e8 01             	sub    $0x1,%eax
f0100275:	66 a3 54 25 11 f0    	mov    %ax,0xf0112554
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010027b:	0f b7 c0             	movzwl %ax,%eax
f010027e:	66 81 e7 00 ff       	and    $0xff00,%di
f0100283:	83 cf 20             	or     $0x20,%edi
f0100286:	8b 15 50 25 11 f0    	mov    0xf0112550,%edx
f010028c:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100290:	eb 77                	jmp    f0100309 <cons_putc+0x162>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100292:	66 83 05 54 25 11 f0 	addw   $0x50,0xf0112554
f0100299:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010029a:	0f b7 05 54 25 11 f0 	movzwl 0xf0112554,%eax
f01002a1:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01002a7:	c1 e8 16             	shr    $0x16,%eax
f01002aa:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01002ad:	c1 e0 04             	shl    $0x4,%eax
f01002b0:	66 a3 54 25 11 f0    	mov    %ax,0xf0112554
f01002b6:	eb 51                	jmp    f0100309 <cons_putc+0x162>
		break;
	case '\t':
		cons_putc(' ');
f01002b8:	b8 20 00 00 00       	mov    $0x20,%eax
f01002bd:	e8 e5 fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002c2:	b8 20 00 00 00       	mov    $0x20,%eax
f01002c7:	e8 db fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002cc:	b8 20 00 00 00       	mov    $0x20,%eax
f01002d1:	e8 d1 fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002d6:	b8 20 00 00 00       	mov    $0x20,%eax
f01002db:	e8 c7 fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002e0:	b8 20 00 00 00       	mov    $0x20,%eax
f01002e5:	e8 bd fe ff ff       	call   f01001a7 <cons_putc>
f01002ea:	eb 1d                	jmp    f0100309 <cons_putc+0x162>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01002ec:	0f b7 05 54 25 11 f0 	movzwl 0xf0112554,%eax
f01002f3:	0f b7 c8             	movzwl %ax,%ecx
f01002f6:	8b 15 50 25 11 f0    	mov    0xf0112550,%edx
f01002fc:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f0100300:	83 c0 01             	add    $0x1,%eax
f0100303:	66 a3 54 25 11 f0    	mov    %ax,0xf0112554
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100309:	66 81 3d 54 25 11 f0 	cmpw   $0x7cf,0xf0112554
f0100310:	cf 07 
f0100312:	76 42                	jbe    f0100356 <cons_putc+0x1af>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100314:	a1 50 25 11 f0       	mov    0xf0112550,%eax
f0100319:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100320:	00 
f0100321:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100327:	89 54 24 04          	mov    %edx,0x4(%esp)
f010032b:	89 04 24             	mov    %eax,(%esp)
f010032e:	e8 ce 12 00 00       	call   f0101601 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100333:	8b 15 50 25 11 f0    	mov    0xf0112550,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100339:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f010033e:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100344:	83 c0 01             	add    $0x1,%eax
f0100347:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f010034c:	75 f0                	jne    f010033e <cons_putc+0x197>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010034e:	66 83 2d 54 25 11 f0 	subw   $0x50,0xf0112554
f0100355:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100356:	8b 0d 4c 25 11 f0    	mov    0xf011254c,%ecx
f010035c:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100361:	89 ca                	mov    %ecx,%edx
f0100363:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100364:	0f b7 35 54 25 11 f0 	movzwl 0xf0112554,%esi
f010036b:	8d 59 01             	lea    0x1(%ecx),%ebx
f010036e:	89 f0                	mov    %esi,%eax
f0100370:	66 c1 e8 08          	shr    $0x8,%ax
f0100374:	89 da                	mov    %ebx,%edx
f0100376:	ee                   	out    %al,(%dx)
f0100377:	b8 0f 00 00 00       	mov    $0xf,%eax
f010037c:	89 ca                	mov    %ecx,%edx
f010037e:	ee                   	out    %al,(%dx)
f010037f:	89 f0                	mov    %esi,%eax
f0100381:	89 da                	mov    %ebx,%edx
f0100383:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100384:	83 c4 2c             	add    $0x2c,%esp
f0100387:	5b                   	pop    %ebx
f0100388:	5e                   	pop    %esi
f0100389:	5f                   	pop    %edi
f010038a:	5d                   	pop    %ebp
f010038b:	c3                   	ret    

f010038c <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010038c:	55                   	push   %ebp
f010038d:	89 e5                	mov    %esp,%ebp
f010038f:	53                   	push   %ebx
f0100390:	83 ec 14             	sub    $0x14,%esp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100393:	ba 64 00 00 00       	mov    $0x64,%edx
f0100398:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f0100399:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f010039e:	a8 01                	test   $0x1,%al
f01003a0:	0f 84 de 00 00 00    	je     f0100484 <kbd_proc_data+0xf8>
f01003a6:	b2 60                	mov    $0x60,%dl
f01003a8:	ec                   	in     (%dx),%al
f01003a9:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01003ab:	3c e0                	cmp    $0xe0,%al
f01003ad:	75 11                	jne    f01003c0 <kbd_proc_data+0x34>
		// E0 escape character
		shift |= E0ESC;
f01003af:	83 0d 48 25 11 f0 40 	orl    $0x40,0xf0112548
		return 0;
f01003b6:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003bb:	e9 c4 00 00 00       	jmp    f0100484 <kbd_proc_data+0xf8>
	} else if (data & 0x80) {
f01003c0:	84 c0                	test   %al,%al
f01003c2:	79 37                	jns    f01003fb <kbd_proc_data+0x6f>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003c4:	8b 0d 48 25 11 f0    	mov    0xf0112548,%ecx
f01003ca:	89 cb                	mov    %ecx,%ebx
f01003cc:	83 e3 40             	and    $0x40,%ebx
f01003cf:	83 e0 7f             	and    $0x7f,%eax
f01003d2:	85 db                	test   %ebx,%ebx
f01003d4:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01003d7:	0f b6 d2             	movzbl %dl,%edx
f01003da:	0f b6 82 40 1b 10 f0 	movzbl -0xfefe4c0(%edx),%eax
f01003e1:	83 c8 40             	or     $0x40,%eax
f01003e4:	0f b6 c0             	movzbl %al,%eax
f01003e7:	f7 d0                	not    %eax
f01003e9:	21 c1                	and    %eax,%ecx
f01003eb:	89 0d 48 25 11 f0    	mov    %ecx,0xf0112548
		return 0;
f01003f1:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003f6:	e9 89 00 00 00       	jmp    f0100484 <kbd_proc_data+0xf8>
	} else if (shift & E0ESC) {
f01003fb:	8b 0d 48 25 11 f0    	mov    0xf0112548,%ecx
f0100401:	f6 c1 40             	test   $0x40,%cl
f0100404:	74 0e                	je     f0100414 <kbd_proc_data+0x88>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100406:	89 c2                	mov    %eax,%edx
f0100408:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f010040b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010040e:	89 0d 48 25 11 f0    	mov    %ecx,0xf0112548
	}

	shift |= shiftcode[data];
f0100414:	0f b6 d2             	movzbl %dl,%edx
f0100417:	0f b6 82 40 1b 10 f0 	movzbl -0xfefe4c0(%edx),%eax
f010041e:	0b 05 48 25 11 f0    	or     0xf0112548,%eax
	shift ^= togglecode[data];
f0100424:	0f b6 8a 40 1c 10 f0 	movzbl -0xfefe3c0(%edx),%ecx
f010042b:	31 c8                	xor    %ecx,%eax
f010042d:	a3 48 25 11 f0       	mov    %eax,0xf0112548

	c = charcode[shift & (CTL | SHIFT)][data];
f0100432:	89 c1                	mov    %eax,%ecx
f0100434:	83 e1 03             	and    $0x3,%ecx
f0100437:	8b 0c 8d 40 1d 10 f0 	mov    -0xfefe2c0(,%ecx,4),%ecx
f010043e:	0f b6 1c 11          	movzbl (%ecx,%edx,1),%ebx
	if (shift & CAPSLOCK) {
f0100442:	a8 08                	test   $0x8,%al
f0100444:	74 19                	je     f010045f <kbd_proc_data+0xd3>
		if ('a' <= c && c <= 'z')
f0100446:	8d 53 9f             	lea    -0x61(%ebx),%edx
f0100449:	83 fa 19             	cmp    $0x19,%edx
f010044c:	77 05                	ja     f0100453 <kbd_proc_data+0xc7>
			c += 'A' - 'a';
f010044e:	83 eb 20             	sub    $0x20,%ebx
f0100451:	eb 0c                	jmp    f010045f <kbd_proc_data+0xd3>
		else if ('A' <= c && c <= 'Z')
f0100453:	8d 4b bf             	lea    -0x41(%ebx),%ecx
			c += 'a' - 'A';
f0100456:	8d 53 20             	lea    0x20(%ebx),%edx
f0100459:	83 f9 19             	cmp    $0x19,%ecx
f010045c:	0f 46 da             	cmovbe %edx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010045f:	f7 d0                	not    %eax
f0100461:	a8 06                	test   $0x6,%al
f0100463:	75 1f                	jne    f0100484 <kbd_proc_data+0xf8>
f0100465:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010046b:	75 17                	jne    f0100484 <kbd_proc_data+0xf8>
		cprintf("Rebooting!\n");
f010046d:	c7 04 24 0d 1b 10 f0 	movl   $0xf0101b0d,(%esp)
f0100474:	e8 d5 05 00 00       	call   f0100a4e <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100479:	ba 92 00 00 00       	mov    $0x92,%edx
f010047e:	b8 03 00 00 00       	mov    $0x3,%eax
f0100483:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100484:	89 d8                	mov    %ebx,%eax
f0100486:	83 c4 14             	add    $0x14,%esp
f0100489:	5b                   	pop    %ebx
f010048a:	5d                   	pop    %ebp
f010048b:	c3                   	ret    

f010048c <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010048c:	55                   	push   %ebp
f010048d:	89 e5                	mov    %esp,%ebp
f010048f:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f0100492:	83 3d 20 23 11 f0 00 	cmpl   $0x0,0xf0112320
f0100499:	74 0a                	je     f01004a5 <serial_intr+0x19>
		cons_intr(serial_proc_data);
f010049b:	b8 4e 01 10 f0       	mov    $0xf010014e,%eax
f01004a0:	e8 c5 fc ff ff       	call   f010016a <cons_intr>
}
f01004a5:	c9                   	leave  
f01004a6:	c3                   	ret    

f01004a7 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004a7:	55                   	push   %ebp
f01004a8:	89 e5                	mov    %esp,%ebp
f01004aa:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004ad:	b8 8c 03 10 f0       	mov    $0xf010038c,%eax
f01004b2:	e8 b3 fc ff ff       	call   f010016a <cons_intr>
}
f01004b7:	c9                   	leave  
f01004b8:	c3                   	ret    

f01004b9 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004b9:	55                   	push   %ebp
f01004ba:	89 e5                	mov    %esp,%ebp
f01004bc:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004bf:	e8 c8 ff ff ff       	call   f010048c <serial_intr>
	kbd_intr();
f01004c4:	e8 de ff ff ff       	call   f01004a7 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004c9:	8b 15 40 25 11 f0    	mov    0xf0112540,%edx
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f01004cf:	b8 00 00 00 00       	mov    $0x0,%eax
	// (e.g., when called from the kernel monitor).
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004d4:	3b 15 44 25 11 f0    	cmp    0xf0112544,%edx
f01004da:	74 1e                	je     f01004fa <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f01004dc:	0f b6 82 40 23 11 f0 	movzbl -0xfeedcc0(%edx),%eax
f01004e3:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f01004e6:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004ec:	b9 00 00 00 00       	mov    $0x0,%ecx
f01004f1:	0f 44 d1             	cmove  %ecx,%edx
f01004f4:	89 15 40 25 11 f0    	mov    %edx,0xf0112540
		return c;
	}
	return 0;
}
f01004fa:	c9                   	leave  
f01004fb:	c3                   	ret    

f01004fc <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004fc:	55                   	push   %ebp
f01004fd:	89 e5                	mov    %esp,%ebp
f01004ff:	57                   	push   %edi
f0100500:	56                   	push   %esi
f0100501:	53                   	push   %ebx
f0100502:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100505:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010050c:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100513:	5a a5 
	if (*cp != 0xA55A) {
f0100515:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010051c:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100520:	74 11                	je     f0100533 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100522:	c7 05 4c 25 11 f0 b4 	movl   $0x3b4,0xf011254c
f0100529:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010052c:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100531:	eb 16                	jmp    f0100549 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100533:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010053a:	c7 05 4c 25 11 f0 d4 	movl   $0x3d4,0xf011254c
f0100541:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100544:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f0100549:	8b 0d 4c 25 11 f0    	mov    0xf011254c,%ecx
f010054f:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100554:	89 ca                	mov    %ecx,%edx
f0100556:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100557:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010055a:	89 da                	mov    %ebx,%edx
f010055c:	ec                   	in     (%dx),%al
f010055d:	0f b6 f8             	movzbl %al,%edi
f0100560:	c1 e7 08             	shl    $0x8,%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100563:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100568:	89 ca                	mov    %ecx,%edx
f010056a:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056b:	89 da                	mov    %ebx,%edx
f010056d:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010056e:	89 35 50 25 11 f0    	mov    %esi,0xf0112550
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100574:	0f b6 d8             	movzbl %al,%ebx
f0100577:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100579:	66 89 3d 54 25 11 f0 	mov    %di,0xf0112554
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100580:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f0100585:	b8 00 00 00 00       	mov    $0x0,%eax
f010058a:	89 da                	mov    %ebx,%edx
f010058c:	ee                   	out    %al,(%dx)
f010058d:	b2 fb                	mov    $0xfb,%dl
f010058f:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100594:	ee                   	out    %al,(%dx)
f0100595:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f010059a:	b8 0c 00 00 00       	mov    $0xc,%eax
f010059f:	89 ca                	mov    %ecx,%edx
f01005a1:	ee                   	out    %al,(%dx)
f01005a2:	b2 f9                	mov    $0xf9,%dl
f01005a4:	b8 00 00 00 00       	mov    $0x0,%eax
f01005a9:	ee                   	out    %al,(%dx)
f01005aa:	b2 fb                	mov    $0xfb,%dl
f01005ac:	b8 03 00 00 00       	mov    $0x3,%eax
f01005b1:	ee                   	out    %al,(%dx)
f01005b2:	b2 fc                	mov    $0xfc,%dl
f01005b4:	b8 00 00 00 00       	mov    $0x0,%eax
f01005b9:	ee                   	out    %al,(%dx)
f01005ba:	b2 f9                	mov    $0xf9,%dl
f01005bc:	b8 01 00 00 00       	mov    $0x1,%eax
f01005c1:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005c2:	b2 fd                	mov    $0xfd,%dl
f01005c4:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005c5:	3c ff                	cmp    $0xff,%al
f01005c7:	0f 95 c0             	setne  %al
f01005ca:	0f b6 c0             	movzbl %al,%eax
f01005cd:	89 c6                	mov    %eax,%esi
f01005cf:	a3 20 23 11 f0       	mov    %eax,0xf0112320
f01005d4:	89 da                	mov    %ebx,%edx
f01005d6:	ec                   	in     (%dx),%al
f01005d7:	89 ca                	mov    %ecx,%edx
f01005d9:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005da:	85 f6                	test   %esi,%esi
f01005dc:	75 0c                	jne    f01005ea <cons_init+0xee>
		cprintf("Serial port does not exist!\n");
f01005de:	c7 04 24 19 1b 10 f0 	movl   $0xf0101b19,(%esp)
f01005e5:	e8 64 04 00 00       	call   f0100a4e <cprintf>
}
f01005ea:	83 c4 1c             	add    $0x1c,%esp
f01005ed:	5b                   	pop    %ebx
f01005ee:	5e                   	pop    %esi
f01005ef:	5f                   	pop    %edi
f01005f0:	5d                   	pop    %ebp
f01005f1:	c3                   	ret    

f01005f2 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01005f2:	55                   	push   %ebp
f01005f3:	89 e5                	mov    %esp,%ebp
f01005f5:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01005f8:	8b 45 08             	mov    0x8(%ebp),%eax
f01005fb:	e8 a7 fb ff ff       	call   f01001a7 <cons_putc>
}
f0100600:	c9                   	leave  
f0100601:	c3                   	ret    

f0100602 <getchar>:

int
getchar(void)
{
f0100602:	55                   	push   %ebp
f0100603:	89 e5                	mov    %esp,%ebp
f0100605:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100608:	e8 ac fe ff ff       	call   f01004b9 <cons_getc>
f010060d:	85 c0                	test   %eax,%eax
f010060f:	74 f7                	je     f0100608 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100611:	c9                   	leave  
f0100612:	c3                   	ret    

f0100613 <iscons>:

int
iscons(int fdnum)
{
f0100613:	55                   	push   %ebp
f0100614:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100616:	b8 01 00 00 00       	mov    $0x1,%eax
f010061b:	5d                   	pop    %ebp
f010061c:	c3                   	ret    
f010061d:	00 00                	add    %al,(%eax)
	...

f0100620 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100620:	55                   	push   %ebp
f0100621:	89 e5                	mov    %esp,%ebp
f0100623:	83 ec 18             	sub    $0x18,%esp
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100626:	c7 04 24 50 1d 10 f0 	movl   $0xf0101d50,(%esp)
f010062d:	e8 1c 04 00 00       	call   f0100a4e <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100632:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100639:	00 
f010063a:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100641:	f0 
f0100642:	c7 04 24 dc 1d 10 f0 	movl   $0xf0101ddc,(%esp)
f0100649:	e8 00 04 00 00       	call   f0100a4e <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010064e:	c7 44 24 08 a5 1a 10 	movl   $0x101aa5,0x8(%esp)
f0100655:	00 
f0100656:	c7 44 24 04 a5 1a 10 	movl   $0xf0101aa5,0x4(%esp)
f010065d:	f0 
f010065e:	c7 04 24 00 1e 10 f0 	movl   $0xf0101e00,(%esp)
f0100665:	e8 e4 03 00 00       	call   f0100a4e <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010066a:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f0100671:	00 
f0100672:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f0100679:	f0 
f010067a:	c7 04 24 24 1e 10 f0 	movl   $0xf0101e24,(%esp)
f0100681:	e8 c8 03 00 00       	call   f0100a4e <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100686:	c7 44 24 08 6c 29 11 	movl   $0x11296c,0x8(%esp)
f010068d:	00 
f010068e:	c7 44 24 04 6c 29 11 	movl   $0xf011296c,0x4(%esp)
f0100695:	f0 
f0100696:	c7 04 24 48 1e 10 f0 	movl   $0xf0101e48,(%esp)
f010069d:	e8 ac 03 00 00       	call   f0100a4e <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
f01006a2:	b8 6b 2d 11 f0       	mov    $0xf0112d6b,%eax
f01006a7:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006ac:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006b2:	85 c0                	test   %eax,%eax
f01006b4:	0f 48 c2             	cmovs  %edx,%eax
f01006b7:	c1 f8 0a             	sar    $0xa,%eax
f01006ba:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006be:	c7 04 24 6c 1e 10 f0 	movl   $0xf0101e6c,(%esp)
f01006c5:	e8 84 03 00 00       	call   f0100a4e <cprintf>
		(end-entry+1023)/1024);
	return 0;
}
f01006ca:	b8 00 00 00 00       	mov    $0x0,%eax
f01006cf:	c9                   	leave  
f01006d0:	c3                   	ret    

f01006d1 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006d1:	55                   	push   %ebp
f01006d2:	89 e5                	mov    %esp,%ebp
f01006d4:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006d7:	c7 44 24 08 69 1d 10 	movl   $0xf0101d69,0x8(%esp)
f01006de:	f0 
f01006df:	c7 44 24 04 87 1d 10 	movl   $0xf0101d87,0x4(%esp)
f01006e6:	f0 
f01006e7:	c7 04 24 8c 1d 10 f0 	movl   $0xf0101d8c,(%esp)
f01006ee:	e8 5b 03 00 00       	call   f0100a4e <cprintf>
f01006f3:	c7 44 24 08 98 1e 10 	movl   $0xf0101e98,0x8(%esp)
f01006fa:	f0 
f01006fb:	c7 44 24 04 95 1d 10 	movl   $0xf0101d95,0x4(%esp)
f0100702:	f0 
f0100703:	c7 04 24 8c 1d 10 f0 	movl   $0xf0101d8c,(%esp)
f010070a:	e8 3f 03 00 00       	call   f0100a4e <cprintf>
	return 0;
}
f010070f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100714:	c9                   	leave  
f0100715:	c3                   	ret    

f0100716 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100716:	55                   	push   %ebp
f0100717:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f0100719:	b8 00 00 00 00       	mov    $0x0,%eax
f010071e:	5d                   	pop    %ebp
f010071f:	c3                   	ret    

f0100720 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100720:	55                   	push   %ebp
f0100721:	89 e5                	mov    %esp,%ebp
f0100723:	57                   	push   %edi
f0100724:	56                   	push   %esi
f0100725:	53                   	push   %ebx
f0100726:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100729:	c7 04 24 c0 1e 10 f0 	movl   $0xf0101ec0,(%esp)
f0100730:	e8 19 03 00 00       	call   f0100a4e <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100735:	c7 04 24 e4 1e 10 f0 	movl   $0xf0101ee4,(%esp)
f010073c:	e8 0d 03 00 00       	call   f0100a4e <cprintf>
	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
f0100741:	8d 7d a8             	lea    -0x58(%ebp),%edi
	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");


	while (1) {
		buf = readline("K> ");
f0100744:	c7 04 24 9e 1d 10 f0 	movl   $0xf0101d9e,(%esp)
f010074b:	e8 d0 0b 00 00       	call   f0101320 <readline>
f0100750:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100752:	85 c0                	test   %eax,%eax
f0100754:	74 ee                	je     f0100744 <monitor+0x24>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100756:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010075d:	be 00 00 00 00       	mov    $0x0,%esi
f0100762:	eb 06                	jmp    f010076a <monitor+0x4a>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100764:	c6 03 00             	movb   $0x0,(%ebx)
f0100767:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010076a:	0f b6 03             	movzbl (%ebx),%eax
f010076d:	84 c0                	test   %al,%al
f010076f:	74 6a                	je     f01007db <monitor+0xbb>
f0100771:	0f be c0             	movsbl %al,%eax
f0100774:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100778:	c7 04 24 a2 1d 10 f0 	movl   $0xf0101da2,(%esp)
f010077f:	e8 c7 0d 00 00       	call   f010154b <strchr>
f0100784:	85 c0                	test   %eax,%eax
f0100786:	75 dc                	jne    f0100764 <monitor+0x44>
			*buf++ = 0;
		if (*buf == 0)
f0100788:	80 3b 00             	cmpb   $0x0,(%ebx)
f010078b:	74 4e                	je     f01007db <monitor+0xbb>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010078d:	83 fe 0f             	cmp    $0xf,%esi
f0100790:	75 16                	jne    f01007a8 <monitor+0x88>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100792:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100799:	00 
f010079a:	c7 04 24 a7 1d 10 f0 	movl   $0xf0101da7,(%esp)
f01007a1:	e8 a8 02 00 00       	call   f0100a4e <cprintf>
f01007a6:	eb 9c                	jmp    f0100744 <monitor+0x24>
			return 0;
		}
		argv[argc++] = buf;
f01007a8:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01007ac:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f01007af:	0f b6 03             	movzbl (%ebx),%eax
f01007b2:	84 c0                	test   %al,%al
f01007b4:	75 0c                	jne    f01007c2 <monitor+0xa2>
f01007b6:	eb b2                	jmp    f010076a <monitor+0x4a>
			buf++;
f01007b8:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01007bb:	0f b6 03             	movzbl (%ebx),%eax
f01007be:	84 c0                	test   %al,%al
f01007c0:	74 a8                	je     f010076a <monitor+0x4a>
f01007c2:	0f be c0             	movsbl %al,%eax
f01007c5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007c9:	c7 04 24 a2 1d 10 f0 	movl   $0xf0101da2,(%esp)
f01007d0:	e8 76 0d 00 00       	call   f010154b <strchr>
f01007d5:	85 c0                	test   %eax,%eax
f01007d7:	74 df                	je     f01007b8 <monitor+0x98>
f01007d9:	eb 8f                	jmp    f010076a <monitor+0x4a>
			buf++;
	}
	argv[argc] = 0;
f01007db:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01007e2:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01007e3:	85 f6                	test   %esi,%esi
f01007e5:	0f 84 59 ff ff ff    	je     f0100744 <monitor+0x24>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01007eb:	c7 44 24 04 87 1d 10 	movl   $0xf0101d87,0x4(%esp)
f01007f2:	f0 
f01007f3:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01007f6:	89 04 24             	mov    %eax,(%esp)
f01007f9:	e8 d2 0c 00 00       	call   f01014d0 <strcmp>
f01007fe:	ba 00 00 00 00       	mov    $0x0,%edx
f0100803:	85 c0                	test   %eax,%eax
f0100805:	74 1c                	je     f0100823 <monitor+0x103>
f0100807:	c7 44 24 04 95 1d 10 	movl   $0xf0101d95,0x4(%esp)
f010080e:	f0 
f010080f:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100812:	89 04 24             	mov    %eax,(%esp)
f0100815:	e8 b6 0c 00 00       	call   f01014d0 <strcmp>
f010081a:	85 c0                	test   %eax,%eax
f010081c:	75 28                	jne    f0100846 <monitor+0x126>
f010081e:	ba 01 00 00 00       	mov    $0x1,%edx
			return commands[i].func(argc, argv, tf);
f0100823:	8d 04 12             	lea    (%edx,%edx,1),%eax
f0100826:	01 c2                	add    %eax,%edx
f0100828:	8b 45 08             	mov    0x8(%ebp),%eax
f010082b:	89 44 24 08          	mov    %eax,0x8(%esp)
f010082f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100833:	89 34 24             	mov    %esi,(%esp)
f0100836:	ff 14 95 14 1f 10 f0 	call   *-0xfefe0ec(,%edx,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010083d:	85 c0                	test   %eax,%eax
f010083f:	78 1d                	js     f010085e <monitor+0x13e>
f0100841:	e9 fe fe ff ff       	jmp    f0100744 <monitor+0x24>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100846:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100849:	89 44 24 04          	mov    %eax,0x4(%esp)
f010084d:	c7 04 24 c4 1d 10 f0 	movl   $0xf0101dc4,(%esp)
f0100854:	e8 f5 01 00 00       	call   f0100a4e <cprintf>
f0100859:	e9 e6 fe ff ff       	jmp    f0100744 <monitor+0x24>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f010085e:	83 c4 5c             	add    $0x5c,%esp
f0100861:	5b                   	pop    %ebx
f0100862:	5e                   	pop    %esi
f0100863:	5f                   	pop    %edi
f0100864:	5d                   	pop    %ebp
f0100865:	c3                   	ret    

f0100866 <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f0100866:	55                   	push   %ebp
f0100867:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f0100869:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f010086c:	5d                   	pop    %ebp
f010086d:	c3                   	ret    
	...

f0100870 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100870:	55                   	push   %ebp
f0100871:	89 e5                	mov    %esp,%ebp
f0100873:	56                   	push   %esi
f0100874:	53                   	push   %ebx
f0100875:	83 ec 10             	sub    $0x10,%esp
f0100878:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010087a:	89 04 24             	mov    %eax,(%esp)
f010087d:	e8 5e 01 00 00       	call   f01009e0 <mc146818_read>
f0100882:	89 c6                	mov    %eax,%esi
f0100884:	83 c3 01             	add    $0x1,%ebx
f0100887:	89 1c 24             	mov    %ebx,(%esp)
f010088a:	e8 51 01 00 00       	call   f01009e0 <mc146818_read>
f010088f:	c1 e0 08             	shl    $0x8,%eax
f0100892:	09 f0                	or     %esi,%eax
}
f0100894:	83 c4 10             	add    $0x10,%esp
f0100897:	5b                   	pop    %ebx
f0100898:	5e                   	pop    %esi
f0100899:	5d                   	pop    %ebp
f010089a:	c3                   	ret    

f010089b <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f010089b:	55                   	push   %ebp
f010089c:	89 e5                	mov    %esp,%ebp
f010089e:	83 ec 18             	sub    $0x18,%esp
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f01008a1:	b8 15 00 00 00       	mov    $0x15,%eax
f01008a6:	e8 c5 ff ff ff       	call   f0100870 <nvram_read>
f01008ab:	c1 e0 0a             	shl    $0xa,%eax
f01008ae:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01008b4:	85 c0                	test   %eax,%eax
f01008b6:	0f 48 c2             	cmovs  %edx,%eax
f01008b9:	c1 f8 0c             	sar    $0xc,%eax
f01008bc:	a3 58 25 11 f0       	mov    %eax,0xf0112558
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01008c1:	b8 17 00 00 00       	mov    $0x17,%eax
f01008c6:	e8 a5 ff ff ff       	call   f0100870 <nvram_read>
f01008cb:	c1 e0 0a             	shl    $0xa,%eax
f01008ce:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01008d4:	85 c0                	test   %eax,%eax
f01008d6:	0f 48 c2             	cmovs  %edx,%eax
f01008d9:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01008dc:	85 c0                	test   %eax,%eax
f01008de:	74 0e                	je     f01008ee <mem_init+0x53>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01008e0:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f01008e6:	89 15 60 29 11 f0    	mov    %edx,0xf0112960
f01008ec:	eb 0c                	jmp    f01008fa <mem_init+0x5f>
	else
		npages = npages_basemem;
f01008ee:	8b 15 58 25 11 f0    	mov    0xf0112558,%edx
f01008f4:	89 15 60 29 11 f0    	mov    %edx,0xf0112960

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f01008fa:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01008fd:	c1 e8 0a             	shr    $0xa,%eax
f0100900:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f0100904:	a1 58 25 11 f0       	mov    0xf0112558,%eax
f0100909:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010090c:	c1 e8 0a             	shr    $0xa,%eax
f010090f:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f0100913:	a1 60 29 11 f0       	mov    0xf0112960,%eax
f0100918:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010091b:	c1 e8 0a             	shr    $0xa,%eax
f010091e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100922:	c7 04 24 24 1f 10 f0 	movl   $0xf0101f24,(%esp)
f0100929:	e8 20 01 00 00       	call   f0100a4e <cprintf>

	// Find out how much memory the machine has (npages & npages_basemem).
	i386_detect_memory();

	// Remove this line when you're ready to test this function.
	panic("mem_init: This function is not finished\n");
f010092e:	c7 44 24 08 60 1f 10 	movl   $0xf0101f60,0x8(%esp)
f0100935:	f0 
f0100936:	c7 44 24 04 7c 00 00 	movl   $0x7c,0x4(%esp)
f010093d:	00 
f010093e:	c7 04 24 8c 1f 10 f0 	movl   $0xf0101f8c,(%esp)
f0100945:	e8 4a f7 ff ff       	call   f0100094 <_panic>

f010094a <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f010094a:	55                   	push   %ebp
f010094b:	89 e5                	mov    %esp,%ebp
f010094d:	53                   	push   %ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f010094e:	83 3d 60 29 11 f0 00 	cmpl   $0x0,0xf0112960
f0100955:	74 3b                	je     f0100992 <page_init+0x48>
f0100957:	8b 1d 5c 25 11 f0    	mov    0xf011255c,%ebx
f010095d:	b8 00 00 00 00       	mov    $0x0,%eax
		pages[i].pp_ref = 0;
f0100962:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100969:	89 d1                	mov    %edx,%ecx
f010096b:	03 0d 68 29 11 f0    	add    0xf0112968,%ecx
f0100971:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100977:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f0100979:	89 d3                	mov    %edx,%ebx
f010097b:	03 1d 68 29 11 f0    	add    0xf0112968,%ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100981:	83 c0 01             	add    $0x1,%eax
f0100984:	39 05 60 29 11 f0    	cmp    %eax,0xf0112960
f010098a:	77 d6                	ja     f0100962 <page_init+0x18>
f010098c:	89 1d 5c 25 11 f0    	mov    %ebx,0xf011255c
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f0100992:	5b                   	pop    %ebx
f0100993:	5d                   	pop    %ebp
f0100994:	c3                   	ret    

f0100995 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct Page *
page_alloc(int alloc_flags)
{
f0100995:	55                   	push   %ebp
f0100996:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f0100998:	b8 00 00 00 00       	mov    $0x0,%eax
f010099d:	5d                   	pop    %ebp
f010099e:	c3                   	ret    

f010099f <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct Page *pp)
{
f010099f:	55                   	push   %ebp
f01009a0:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f01009a2:	5d                   	pop    %ebp
f01009a3:	c3                   	ret    

f01009a4 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct Page* pp)
{
f01009a4:	55                   	push   %ebp
f01009a5:	89 e5                	mov    %esp,%ebp
f01009a7:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f01009aa:	66 83 68 04 01       	subw   $0x1,0x4(%eax)
		page_free(pp);
}
f01009af:	5d                   	pop    %ebp
f01009b0:	c3                   	ret    

f01009b1 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f01009b1:	55                   	push   %ebp
f01009b2:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f01009b4:	b8 00 00 00 00       	mov    $0x0,%eax
f01009b9:	5d                   	pop    %ebp
f01009ba:	c3                   	ret    

f01009bb <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{
f01009bb:	55                   	push   %ebp
f01009bc:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f01009be:	b8 00 00 00 00       	mov    $0x0,%eax
f01009c3:	5d                   	pop    %ebp
f01009c4:	c3                   	ret    

f01009c5 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01009c5:	55                   	push   %ebp
f01009c6:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f01009c8:	b8 00 00 00 00       	mov    $0x0,%eax
f01009cd:	5d                   	pop    %ebp
f01009ce:	c3                   	ret    

f01009cf <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01009cf:	55                   	push   %ebp
f01009d0:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f01009d2:	5d                   	pop    %ebp
f01009d3:	c3                   	ret    

f01009d4 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01009d4:	55                   	push   %ebp
f01009d5:	89 e5                	mov    %esp,%ebp
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01009d7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01009da:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01009dd:	5d                   	pop    %ebp
f01009de:	c3                   	ret    
	...

f01009e0 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01009e0:	55                   	push   %ebp
f01009e1:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01009e3:	ba 70 00 00 00       	mov    $0x70,%edx
f01009e8:	8b 45 08             	mov    0x8(%ebp),%eax
f01009eb:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01009ec:	b2 71                	mov    $0x71,%dl
f01009ee:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01009ef:	0f b6 c0             	movzbl %al,%eax
}
f01009f2:	5d                   	pop    %ebp
f01009f3:	c3                   	ret    

f01009f4 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01009f4:	55                   	push   %ebp
f01009f5:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01009f7:	ba 70 00 00 00       	mov    $0x70,%edx
f01009fc:	8b 45 08             	mov    0x8(%ebp),%eax
f01009ff:	ee                   	out    %al,(%dx)
f0100a00:	b2 71                	mov    $0x71,%dl
f0100a02:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100a05:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0100a06:	5d                   	pop    %ebp
f0100a07:	c3                   	ret    

f0100a08 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100a08:	55                   	push   %ebp
f0100a09:	89 e5                	mov    %esp,%ebp
f0100a0b:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0100a0e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a11:	89 04 24             	mov    %eax,(%esp)
f0100a14:	e8 d9 fb ff ff       	call   f01005f2 <cputchar>
	*cnt++;
}
f0100a19:	c9                   	leave  
f0100a1a:	c3                   	ret    

f0100a1b <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100a1b:	55                   	push   %ebp
f0100a1c:	89 e5                	mov    %esp,%ebp
f0100a1e:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0100a21:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100a28:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100a2b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a2f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a32:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100a36:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100a39:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a3d:	c7 04 24 08 0a 10 f0 	movl   $0xf0100a08,(%esp)
f0100a44:	e8 61 04 00 00       	call   f0100eaa <vprintfmt>
	return cnt;
}
f0100a49:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100a4c:	c9                   	leave  
f0100a4d:	c3                   	ret    

f0100a4e <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100a4e:	55                   	push   %ebp
f0100a4f:	89 e5                	mov    %esp,%ebp
f0100a51:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100a54:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100a57:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a5b:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a5e:	89 04 24             	mov    %eax,(%esp)
f0100a61:	e8 b5 ff ff ff       	call   f0100a1b <vcprintf>
	va_end(ap);

	return cnt;
}
f0100a66:	c9                   	leave  
f0100a67:	c3                   	ret    

f0100a68 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a68:	55                   	push   %ebp
f0100a69:	89 e5                	mov    %esp,%ebp
f0100a6b:	57                   	push   %edi
f0100a6c:	56                   	push   %esi
f0100a6d:	53                   	push   %ebx
f0100a6e:	83 ec 10             	sub    $0x10,%esp
f0100a71:	89 c3                	mov    %eax,%ebx
f0100a73:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100a76:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100a79:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a7c:	8b 0a                	mov    (%edx),%ecx
f0100a7e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a81:	8b 00                	mov    (%eax),%eax
f0100a83:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a86:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f0100a8d:	eb 77                	jmp    f0100b06 <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f0100a8f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a92:	01 c8                	add    %ecx,%eax
f0100a94:	bf 02 00 00 00       	mov    $0x2,%edi
f0100a99:	99                   	cltd   
f0100a9a:	f7 ff                	idiv   %edi
f0100a9c:	89 c2                	mov    %eax,%edx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a9e:	eb 01                	jmp    f0100aa1 <stab_binsearch+0x39>
			m--;
f0100aa0:	4a                   	dec    %edx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100aa1:	39 ca                	cmp    %ecx,%edx
f0100aa3:	7c 1d                	jl     f0100ac2 <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100aa5:	6b fa 0c             	imul   $0xc,%edx,%edi
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100aa8:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f0100aad:	39 f7                	cmp    %esi,%edi
f0100aaf:	75 ef                	jne    f0100aa0 <stab_binsearch+0x38>
f0100ab1:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100ab4:	6b fa 0c             	imul   $0xc,%edx,%edi
f0100ab7:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f0100abb:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100abe:	73 18                	jae    f0100ad8 <stab_binsearch+0x70>
f0100ac0:	eb 05                	jmp    f0100ac7 <stab_binsearch+0x5f>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100ac2:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0100ac5:	eb 3f                	jmp    f0100b06 <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100ac7:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100aca:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0100acc:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100acf:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100ad6:	eb 2e                	jmp    f0100b06 <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100ad8:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100adb:	76 15                	jbe    f0100af2 <stab_binsearch+0x8a>
			*region_right = m - 1;
f0100add:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100ae0:	4f                   	dec    %edi
f0100ae1:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0100ae4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ae7:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100ae9:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100af0:	eb 14                	jmp    f0100b06 <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100af2:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100af5:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100af8:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f0100afa:	ff 45 0c             	incl   0xc(%ebp)
f0100afd:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100aff:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0100b06:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0100b09:	7e 84                	jle    f0100a8f <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100b0b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100b0f:	75 0d                	jne    f0100b1e <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0100b11:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100b14:	8b 02                	mov    (%edx),%eax
f0100b16:	48                   	dec    %eax
f0100b17:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100b1a:	89 01                	mov    %eax,(%ecx)
f0100b1c:	eb 22                	jmp    f0100b40 <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b1e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100b21:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100b23:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100b26:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b28:	eb 01                	jmp    f0100b2b <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100b2a:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b2b:	39 c1                	cmp    %eax,%ecx
f0100b2d:	7d 0c                	jge    f0100b3b <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100b2f:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0100b32:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f0100b37:	39 f2                	cmp    %esi,%edx
f0100b39:	75 ef                	jne    f0100b2a <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100b3b:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100b3e:	89 02                	mov    %eax,(%edx)
	}
}
f0100b40:	83 c4 10             	add    $0x10,%esp
f0100b43:	5b                   	pop    %ebx
f0100b44:	5e                   	pop    %esi
f0100b45:	5f                   	pop    %edi
f0100b46:	5d                   	pop    %ebp
f0100b47:	c3                   	ret    

f0100b48 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100b48:	55                   	push   %ebp
f0100b49:	89 e5                	mov    %esp,%ebp
f0100b4b:	83 ec 38             	sub    $0x38,%esp
f0100b4e:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100b51:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100b54:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100b57:	8b 75 08             	mov    0x8(%ebp),%esi
f0100b5a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100b5d:	c7 03 98 1f 10 f0    	movl   $0xf0101f98,(%ebx)
	info->eip_line = 0;
f0100b63:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100b6a:	c7 43 08 98 1f 10 f0 	movl   $0xf0101f98,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100b71:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100b78:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100b7b:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b82:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100b88:	76 12                	jbe    f0100b9c <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b8a:	b8 26 7f 10 f0       	mov    $0xf0107f26,%eax
f0100b8f:	3d a1 63 10 f0       	cmp    $0xf01063a1,%eax
f0100b94:	0f 86 9b 01 00 00    	jbe    f0100d35 <debuginfo_eip+0x1ed>
f0100b9a:	eb 1c                	jmp    f0100bb8 <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100b9c:	c7 44 24 08 a2 1f 10 	movl   $0xf0101fa2,0x8(%esp)
f0100ba3:	f0 
f0100ba4:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100bab:	00 
f0100bac:	c7 04 24 af 1f 10 f0 	movl   $0xf0101faf,(%esp)
f0100bb3:	e8 dc f4 ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100bb8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100bbd:	80 3d 25 7f 10 f0 00 	cmpb   $0x0,0xf0107f25
f0100bc4:	0f 85 77 01 00 00    	jne    f0100d41 <debuginfo_eip+0x1f9>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100bca:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100bd1:	b8 a0 63 10 f0       	mov    $0xf01063a0,%eax
f0100bd6:	2d d0 21 10 f0       	sub    $0xf01021d0,%eax
f0100bdb:	c1 f8 02             	sar    $0x2,%eax
f0100bde:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100be4:	83 e8 01             	sub    $0x1,%eax
f0100be7:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100bea:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100bee:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100bf5:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100bf8:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100bfb:	b8 d0 21 10 f0       	mov    $0xf01021d0,%eax
f0100c00:	e8 63 fe ff ff       	call   f0100a68 <stab_binsearch>
	if (lfile == 0)
f0100c05:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0100c08:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0100c0d:	85 d2                	test   %edx,%edx
f0100c0f:	0f 84 2c 01 00 00    	je     f0100d41 <debuginfo_eip+0x1f9>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100c15:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0100c18:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c1b:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100c1e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c22:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100c29:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100c2c:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c2f:	b8 d0 21 10 f0       	mov    $0xf01021d0,%eax
f0100c34:	e8 2f fe ff ff       	call   f0100a68 <stab_binsearch>

	if (lfun <= rfun) {
f0100c39:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100c3c:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0100c3f:	7f 2e                	jg     f0100c6f <debuginfo_eip+0x127>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100c41:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100c44:	8d 90 d0 21 10 f0    	lea    -0xfefde30(%eax),%edx
f0100c4a:	8b 80 d0 21 10 f0    	mov    -0xfefde30(%eax),%eax
f0100c50:	b9 26 7f 10 f0       	mov    $0xf0107f26,%ecx
f0100c55:	81 e9 a1 63 10 f0    	sub    $0xf01063a1,%ecx
f0100c5b:	39 c8                	cmp    %ecx,%eax
f0100c5d:	73 08                	jae    f0100c67 <debuginfo_eip+0x11f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100c5f:	05 a1 63 10 f0       	add    $0xf01063a1,%eax
f0100c64:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100c67:	8b 42 08             	mov    0x8(%edx),%eax
f0100c6a:	89 43 10             	mov    %eax,0x10(%ebx)
f0100c6d:	eb 06                	jmp    f0100c75 <debuginfo_eip+0x12d>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100c6f:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100c72:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c75:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100c7c:	00 
f0100c7d:	8b 43 08             	mov    0x8(%ebx),%eax
f0100c80:	89 04 24             	mov    %eax,(%esp)
f0100c83:	e8 f7 08 00 00       	call   f010157f <strfind>
f0100c88:	2b 43 08             	sub    0x8(%ebx),%eax
f0100c8b:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c8e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100c91:	39 d7                	cmp    %edx,%edi
f0100c93:	7c 5f                	jl     f0100cf4 <debuginfo_eip+0x1ac>
	       && stabs[lline].n_type != N_SOL
f0100c95:	89 f8                	mov    %edi,%eax
f0100c97:	6b cf 0c             	imul   $0xc,%edi,%ecx
f0100c9a:	80 b9 d4 21 10 f0 84 	cmpb   $0x84,-0xfefde2c(%ecx)
f0100ca1:	75 18                	jne    f0100cbb <debuginfo_eip+0x173>
f0100ca3:	eb 30                	jmp    f0100cd5 <debuginfo_eip+0x18d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100ca5:	83 ef 01             	sub    $0x1,%edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100ca8:	39 fa                	cmp    %edi,%edx
f0100caa:	7f 48                	jg     f0100cf4 <debuginfo_eip+0x1ac>
	       && stabs[lline].n_type != N_SOL
f0100cac:	89 f8                	mov    %edi,%eax
f0100cae:	8d 0c 7f             	lea    (%edi,%edi,2),%ecx
f0100cb1:	80 3c 8d d4 21 10 f0 	cmpb   $0x84,-0xfefde2c(,%ecx,4)
f0100cb8:	84 
f0100cb9:	74 1a                	je     f0100cd5 <debuginfo_eip+0x18d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100cbb:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100cbe:	8d 04 85 d0 21 10 f0 	lea    -0xfefde30(,%eax,4),%eax
f0100cc5:	80 78 04 64          	cmpb   $0x64,0x4(%eax)
f0100cc9:	75 da                	jne    f0100ca5 <debuginfo_eip+0x15d>
f0100ccb:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100ccf:	74 d4                	je     f0100ca5 <debuginfo_eip+0x15d>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100cd1:	39 fa                	cmp    %edi,%edx
f0100cd3:	7f 1f                	jg     f0100cf4 <debuginfo_eip+0x1ac>
f0100cd5:	6b ff 0c             	imul   $0xc,%edi,%edi
f0100cd8:	8b 87 d0 21 10 f0    	mov    -0xfefde30(%edi),%eax
f0100cde:	ba 26 7f 10 f0       	mov    $0xf0107f26,%edx
f0100ce3:	81 ea a1 63 10 f0    	sub    $0xf01063a1,%edx
f0100ce9:	39 d0                	cmp    %edx,%eax
f0100ceb:	73 07                	jae    f0100cf4 <debuginfo_eip+0x1ac>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100ced:	05 a1 63 10 f0       	add    $0xf01063a1,%eax
f0100cf2:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100cf4:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100cf7:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100cfa:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100cff:	39 ca                	cmp    %ecx,%edx
f0100d01:	7d 3e                	jge    f0100d41 <debuginfo_eip+0x1f9>
		for (lline = lfun + 1;
f0100d03:	83 c2 01             	add    $0x1,%edx
f0100d06:	39 d1                	cmp    %edx,%ecx
f0100d08:	7e 37                	jle    f0100d41 <debuginfo_eip+0x1f9>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100d0a:	6b f2 0c             	imul   $0xc,%edx,%esi
f0100d0d:	80 be d4 21 10 f0 a0 	cmpb   $0xa0,-0xfefde2c(%esi)
f0100d14:	75 2b                	jne    f0100d41 <debuginfo_eip+0x1f9>
		     lline++)
			info->eip_fn_narg++;
f0100d16:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100d1a:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100d1d:	39 d1                	cmp    %edx,%ecx
f0100d1f:	7e 1b                	jle    f0100d3c <debuginfo_eip+0x1f4>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100d21:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100d24:	80 3c 85 d4 21 10 f0 	cmpb   $0xa0,-0xfefde2c(,%eax,4)
f0100d2b:	a0 
f0100d2c:	74 e8                	je     f0100d16 <debuginfo_eip+0x1ce>
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100d2e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d33:	eb 0c                	jmp    f0100d41 <debuginfo_eip+0x1f9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100d35:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d3a:	eb 05                	jmp    f0100d41 <debuginfo_eip+0x1f9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100d3c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100d41:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100d44:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100d47:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100d4a:	89 ec                	mov    %ebp,%esp
f0100d4c:	5d                   	pop    %ebp
f0100d4d:	c3                   	ret    
	...

f0100d50 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d50:	55                   	push   %ebp
f0100d51:	89 e5                	mov    %esp,%ebp
f0100d53:	57                   	push   %edi
f0100d54:	56                   	push   %esi
f0100d55:	53                   	push   %ebx
f0100d56:	83 ec 3c             	sub    $0x3c,%esp
f0100d59:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100d5c:	89 d7                	mov    %edx,%edi
f0100d5e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d61:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100d64:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d67:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d6a:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100d6d:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100d70:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d75:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100d78:	72 11                	jb     f0100d8b <printnum+0x3b>
f0100d7a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100d7d:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100d80:	76 09                	jbe    f0100d8b <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d82:	83 eb 01             	sub    $0x1,%ebx
f0100d85:	85 db                	test   %ebx,%ebx
f0100d87:	7f 51                	jg     f0100dda <printnum+0x8a>
f0100d89:	eb 5e                	jmp    f0100de9 <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100d8b:	89 74 24 10          	mov    %esi,0x10(%esp)
f0100d8f:	83 eb 01             	sub    $0x1,%ebx
f0100d92:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100d96:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d99:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d9d:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0100da1:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0100da5:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100dac:	00 
f0100dad:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100db0:	89 04 24             	mov    %eax,(%esp)
f0100db3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100db6:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100dba:	e8 41 0a 00 00       	call   f0101800 <__udivdi3>
f0100dbf:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100dc3:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100dc7:	89 04 24             	mov    %eax,(%esp)
f0100dca:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100dce:	89 fa                	mov    %edi,%edx
f0100dd0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100dd3:	e8 78 ff ff ff       	call   f0100d50 <printnum>
f0100dd8:	eb 0f                	jmp    f0100de9 <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100dda:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100dde:	89 34 24             	mov    %esi,(%esp)
f0100de1:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100de4:	83 eb 01             	sub    $0x1,%ebx
f0100de7:	75 f1                	jne    f0100dda <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100de9:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100ded:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100df1:	8b 45 10             	mov    0x10(%ebp),%eax
f0100df4:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100df8:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100dff:	00 
f0100e00:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100e03:	89 04 24             	mov    %eax,(%esp)
f0100e06:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e09:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e0d:	e8 1e 0b 00 00       	call   f0101930 <__umoddi3>
f0100e12:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e16:	0f be 80 bd 1f 10 f0 	movsbl -0xfefe043(%eax),%eax
f0100e1d:	89 04 24             	mov    %eax,(%esp)
f0100e20:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0100e23:	83 c4 3c             	add    $0x3c,%esp
f0100e26:	5b                   	pop    %ebx
f0100e27:	5e                   	pop    %esi
f0100e28:	5f                   	pop    %edi
f0100e29:	5d                   	pop    %ebp
f0100e2a:	c3                   	ret    

f0100e2b <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100e2b:	55                   	push   %ebp
f0100e2c:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100e2e:	83 fa 01             	cmp    $0x1,%edx
f0100e31:	7e 0e                	jle    f0100e41 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100e33:	8b 10                	mov    (%eax),%edx
f0100e35:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100e38:	89 08                	mov    %ecx,(%eax)
f0100e3a:	8b 02                	mov    (%edx),%eax
f0100e3c:	8b 52 04             	mov    0x4(%edx),%edx
f0100e3f:	eb 22                	jmp    f0100e63 <getuint+0x38>
	else if (lflag)
f0100e41:	85 d2                	test   %edx,%edx
f0100e43:	74 10                	je     f0100e55 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100e45:	8b 10                	mov    (%eax),%edx
f0100e47:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e4a:	89 08                	mov    %ecx,(%eax)
f0100e4c:	8b 02                	mov    (%edx),%eax
f0100e4e:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e53:	eb 0e                	jmp    f0100e63 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100e55:	8b 10                	mov    (%eax),%edx
f0100e57:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e5a:	89 08                	mov    %ecx,(%eax)
f0100e5c:	8b 02                	mov    (%edx),%eax
f0100e5e:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100e63:	5d                   	pop    %ebp
f0100e64:	c3                   	ret    

f0100e65 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100e65:	55                   	push   %ebp
f0100e66:	89 e5                	mov    %esp,%ebp
f0100e68:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100e6b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100e6f:	8b 10                	mov    (%eax),%edx
f0100e71:	3b 50 04             	cmp    0x4(%eax),%edx
f0100e74:	73 0a                	jae    f0100e80 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100e76:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100e79:	88 0a                	mov    %cl,(%edx)
f0100e7b:	83 c2 01             	add    $0x1,%edx
f0100e7e:	89 10                	mov    %edx,(%eax)
}
f0100e80:	5d                   	pop    %ebp
f0100e81:	c3                   	ret    

f0100e82 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100e82:	55                   	push   %ebp
f0100e83:	89 e5                	mov    %esp,%ebp
f0100e85:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100e88:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100e8b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e8f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e92:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e96:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e99:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e9d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ea0:	89 04 24             	mov    %eax,(%esp)
f0100ea3:	e8 02 00 00 00       	call   f0100eaa <vprintfmt>
	va_end(ap);
}
f0100ea8:	c9                   	leave  
f0100ea9:	c3                   	ret    

f0100eaa <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100eaa:	55                   	push   %ebp
f0100eab:	89 e5                	mov    %esp,%ebp
f0100ead:	57                   	push   %edi
f0100eae:	56                   	push   %esi
f0100eaf:	53                   	push   %ebx
f0100eb0:	83 ec 4c             	sub    $0x4c,%esp
f0100eb3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100eb6:	8b 75 10             	mov    0x10(%ebp),%esi
f0100eb9:	eb 12                	jmp    f0100ecd <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100ebb:	85 c0                	test   %eax,%eax
f0100ebd:	0f 84 c9 03 00 00    	je     f010128c <vprintfmt+0x3e2>
				return;
			putch(ch, putdat);
f0100ec3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100ec7:	89 04 24             	mov    %eax,(%esp)
f0100eca:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100ecd:	0f b6 06             	movzbl (%esi),%eax
f0100ed0:	83 c6 01             	add    $0x1,%esi
f0100ed3:	83 f8 25             	cmp    $0x25,%eax
f0100ed6:	75 e3                	jne    f0100ebb <vprintfmt+0x11>
f0100ed8:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0100edc:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0100ee3:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f0100ee8:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0100eef:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100ef4:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100ef7:	eb 2b                	jmp    f0100f24 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ef9:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100efc:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0100f00:	eb 22                	jmp    f0100f24 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f02:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100f05:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0100f09:	eb 19                	jmp    f0100f24 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f0b:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0100f0e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0100f15:	eb 0d                	jmp    f0100f24 <vprintfmt+0x7a>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100f17:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100f1a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100f1d:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f24:	0f b6 06             	movzbl (%esi),%eax
f0100f27:	0f b6 d0             	movzbl %al,%edx
f0100f2a:	8d 7e 01             	lea    0x1(%esi),%edi
f0100f2d:	89 7d e0             	mov    %edi,-0x20(%ebp)
f0100f30:	83 e8 23             	sub    $0x23,%eax
f0100f33:	3c 55                	cmp    $0x55,%al
f0100f35:	0f 87 2b 03 00 00    	ja     f0101266 <vprintfmt+0x3bc>
f0100f3b:	0f b6 c0             	movzbl %al,%eax
f0100f3e:	ff 24 85 4c 20 10 f0 	jmp    *-0xfefdfb4(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100f45:	83 ea 30             	sub    $0x30,%edx
f0100f48:	89 55 d4             	mov    %edx,-0x2c(%ebp)
				ch = *fmt;
f0100f4b:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f0100f4f:	8d 50 d0             	lea    -0x30(%eax),%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f52:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f0100f55:	83 fa 09             	cmp    $0x9,%edx
f0100f58:	77 4a                	ja     f0100fa4 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f5a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100f5d:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f0100f60:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f0100f63:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f0100f67:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100f6a:	8d 50 d0             	lea    -0x30(%eax),%edx
f0100f6d:	83 fa 09             	cmp    $0x9,%edx
f0100f70:	76 eb                	jbe    f0100f5d <vprintfmt+0xb3>
f0100f72:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100f75:	eb 2d                	jmp    f0100fa4 <vprintfmt+0xfa>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100f77:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f7a:	8d 50 04             	lea    0x4(%eax),%edx
f0100f7d:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f80:	8b 00                	mov    (%eax),%eax
f0100f82:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f85:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100f88:	eb 1a                	jmp    f0100fa4 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f8a:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f0100f8d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100f91:	79 91                	jns    f0100f24 <vprintfmt+0x7a>
f0100f93:	e9 73 ff ff ff       	jmp    f0100f0b <vprintfmt+0x61>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f98:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100f9b:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0100fa2:	eb 80                	jmp    f0100f24 <vprintfmt+0x7a>

		process_precision:
			if (width < 0)
f0100fa4:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100fa8:	0f 89 76 ff ff ff    	jns    f0100f24 <vprintfmt+0x7a>
f0100fae:	e9 64 ff ff ff       	jmp    f0100f17 <vprintfmt+0x6d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100fb3:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fb6:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100fb9:	e9 66 ff ff ff       	jmp    f0100f24 <vprintfmt+0x7a>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100fbe:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fc1:	8d 50 04             	lea    0x4(%eax),%edx
f0100fc4:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fc7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100fcb:	8b 00                	mov    (%eax),%eax
f0100fcd:	89 04 24             	mov    %eax,(%esp)
f0100fd0:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fd3:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100fd6:	e9 f2 fe ff ff       	jmp    f0100ecd <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100fdb:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fde:	8d 50 04             	lea    0x4(%eax),%edx
f0100fe1:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fe4:	8b 00                	mov    (%eax),%eax
f0100fe6:	89 c2                	mov    %eax,%edx
f0100fe8:	c1 fa 1f             	sar    $0x1f,%edx
f0100feb:	31 d0                	xor    %edx,%eax
f0100fed:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100fef:	83 f8 06             	cmp    $0x6,%eax
f0100ff2:	7f 0b                	jg     f0100fff <vprintfmt+0x155>
f0100ff4:	8b 14 85 a4 21 10 f0 	mov    -0xfefde5c(,%eax,4),%edx
f0100ffb:	85 d2                	test   %edx,%edx
f0100ffd:	75 23                	jne    f0101022 <vprintfmt+0x178>
				printfmt(putch, putdat, "error %d", err);
f0100fff:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101003:	c7 44 24 08 d5 1f 10 	movl   $0xf0101fd5,0x8(%esp)
f010100a:	f0 
f010100b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010100f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101012:	89 3c 24             	mov    %edi,(%esp)
f0101015:	e8 68 fe ff ff       	call   f0100e82 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010101a:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f010101d:	e9 ab fe ff ff       	jmp    f0100ecd <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
f0101022:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101026:	c7 44 24 08 de 1f 10 	movl   $0xf0101fde,0x8(%esp)
f010102d:	f0 
f010102e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101032:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101035:	89 3c 24             	mov    %edi,(%esp)
f0101038:	e8 45 fe ff ff       	call   f0100e82 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010103d:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0101040:	e9 88 fe ff ff       	jmp    f0100ecd <vprintfmt+0x23>
f0101045:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101048:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010104b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010104e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101051:	8d 50 04             	lea    0x4(%eax),%edx
f0101054:	89 55 14             	mov    %edx,0x14(%ebp)
f0101057:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f0101059:	85 f6                	test   %esi,%esi
f010105b:	ba ce 1f 10 f0       	mov    $0xf0101fce,%edx
f0101060:	0f 44 f2             	cmove  %edx,%esi
			if (width > 0 && padc != '-')
f0101063:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0101067:	7e 06                	jle    f010106f <vprintfmt+0x1c5>
f0101069:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f010106d:	75 10                	jne    f010107f <vprintfmt+0x1d5>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010106f:	0f be 06             	movsbl (%esi),%eax
f0101072:	83 c6 01             	add    $0x1,%esi
f0101075:	85 c0                	test   %eax,%eax
f0101077:	0f 85 86 00 00 00    	jne    f0101103 <vprintfmt+0x259>
f010107d:	eb 76                	jmp    f01010f5 <vprintfmt+0x24b>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010107f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101083:	89 34 24             	mov    %esi,(%esp)
f0101086:	e8 80 03 00 00       	call   f010140b <strnlen>
f010108b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010108e:	29 c2                	sub    %eax,%edx
f0101090:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101093:	85 d2                	test   %edx,%edx
f0101095:	7e d8                	jle    f010106f <vprintfmt+0x1c5>
					putch(padc, putdat);
f0101097:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f010109b:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f010109e:	89 d6                	mov    %edx,%esi
f01010a0:	89 7d d0             	mov    %edi,-0x30(%ebp)
f01010a3:	89 c7                	mov    %eax,%edi
f01010a5:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010a9:	89 3c 24             	mov    %edi,(%esp)
f01010ac:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01010af:	83 ee 01             	sub    $0x1,%esi
f01010b2:	75 f1                	jne    f01010a5 <vprintfmt+0x1fb>
f01010b4:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f01010b7:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f01010ba:	8b 7d d0             	mov    -0x30(%ebp),%edi
f01010bd:	eb b0                	jmp    f010106f <vprintfmt+0x1c5>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01010bf:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01010c3:	74 18                	je     f01010dd <vprintfmt+0x233>
f01010c5:	8d 50 e0             	lea    -0x20(%eax),%edx
f01010c8:	83 fa 5e             	cmp    $0x5e,%edx
f01010cb:	76 10                	jbe    f01010dd <vprintfmt+0x233>
					putch('?', putdat);
f01010cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010d1:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01010d8:	ff 55 08             	call   *0x8(%ebp)
f01010db:	eb 0a                	jmp    f01010e7 <vprintfmt+0x23d>
				else
					putch(ch, putdat);
f01010dd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010e1:	89 04 24             	mov    %eax,(%esp)
f01010e4:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01010e7:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f01010eb:	0f be 06             	movsbl (%esi),%eax
f01010ee:	83 c6 01             	add    $0x1,%esi
f01010f1:	85 c0                	test   %eax,%eax
f01010f3:	75 0e                	jne    f0101103 <vprintfmt+0x259>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010f5:	8b 75 e0             	mov    -0x20(%ebp),%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01010f8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01010fc:	7f 16                	jg     f0101114 <vprintfmt+0x26a>
f01010fe:	e9 ca fd ff ff       	jmp    f0100ecd <vprintfmt+0x23>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101103:	85 ff                	test   %edi,%edi
f0101105:	78 b8                	js     f01010bf <vprintfmt+0x215>
f0101107:	83 ef 01             	sub    $0x1,%edi
f010110a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101110:	79 ad                	jns    f01010bf <vprintfmt+0x215>
f0101112:	eb e1                	jmp    f01010f5 <vprintfmt+0x24b>
f0101114:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101117:	8b 7d 08             	mov    0x8(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010111a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010111e:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101125:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101127:	83 ee 01             	sub    $0x1,%esi
f010112a:	75 ee                	jne    f010111a <vprintfmt+0x270>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010112c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010112f:	e9 99 fd ff ff       	jmp    f0100ecd <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101134:	83 f9 01             	cmp    $0x1,%ecx
f0101137:	7e 10                	jle    f0101149 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0101139:	8b 45 14             	mov    0x14(%ebp),%eax
f010113c:	8d 50 08             	lea    0x8(%eax),%edx
f010113f:	89 55 14             	mov    %edx,0x14(%ebp)
f0101142:	8b 30                	mov    (%eax),%esi
f0101144:	8b 78 04             	mov    0x4(%eax),%edi
f0101147:	eb 26                	jmp    f010116f <vprintfmt+0x2c5>
	else if (lflag)
f0101149:	85 c9                	test   %ecx,%ecx
f010114b:	74 12                	je     f010115f <vprintfmt+0x2b5>
		return va_arg(*ap, long);
f010114d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101150:	8d 50 04             	lea    0x4(%eax),%edx
f0101153:	89 55 14             	mov    %edx,0x14(%ebp)
f0101156:	8b 30                	mov    (%eax),%esi
f0101158:	89 f7                	mov    %esi,%edi
f010115a:	c1 ff 1f             	sar    $0x1f,%edi
f010115d:	eb 10                	jmp    f010116f <vprintfmt+0x2c5>
	else
		return va_arg(*ap, int);
f010115f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101162:	8d 50 04             	lea    0x4(%eax),%edx
f0101165:	89 55 14             	mov    %edx,0x14(%ebp)
f0101168:	8b 30                	mov    (%eax),%esi
f010116a:	89 f7                	mov    %esi,%edi
f010116c:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010116f:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101174:	85 ff                	test   %edi,%edi
f0101176:	0f 89 ac 00 00 00    	jns    f0101228 <vprintfmt+0x37e>
				putch('-', putdat);
f010117c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101180:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0101187:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010118a:	f7 de                	neg    %esi
f010118c:	83 d7 00             	adc    $0x0,%edi
f010118f:	f7 df                	neg    %edi
			}
			base = 10;
f0101191:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101196:	e9 8d 00 00 00       	jmp    f0101228 <vprintfmt+0x37e>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f010119b:	89 ca                	mov    %ecx,%edx
f010119d:	8d 45 14             	lea    0x14(%ebp),%eax
f01011a0:	e8 86 fc ff ff       	call   f0100e2b <getuint>
f01011a5:	89 c6                	mov    %eax,%esi
f01011a7:	89 d7                	mov    %edx,%edi
			base = 10;
f01011a9:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f01011ae:	eb 78                	jmp    f0101228 <vprintfmt+0x37e>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f01011b0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011b4:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f01011bb:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f01011be:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011c2:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f01011c9:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f01011cc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011d0:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f01011d7:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011da:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f01011dd:	e9 eb fc ff ff       	jmp    f0100ecd <vprintfmt+0x23>

		// pointer
		case 'p':
			putch('0', putdat);
f01011e2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011e6:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01011ed:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01011f0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011f4:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01011fb:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01011fe:	8b 45 14             	mov    0x14(%ebp),%eax
f0101201:	8d 50 04             	lea    0x4(%eax),%edx
f0101204:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101207:	8b 30                	mov    (%eax),%esi
f0101209:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010120e:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0101213:	eb 13                	jmp    f0101228 <vprintfmt+0x37e>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101215:	89 ca                	mov    %ecx,%edx
f0101217:	8d 45 14             	lea    0x14(%ebp),%eax
f010121a:	e8 0c fc ff ff       	call   f0100e2b <getuint>
f010121f:	89 c6                	mov    %eax,%esi
f0101221:	89 d7                	mov    %edx,%edi
			base = 16;
f0101223:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101228:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
f010122c:	89 54 24 10          	mov    %edx,0x10(%esp)
f0101230:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101233:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101237:	89 44 24 08          	mov    %eax,0x8(%esp)
f010123b:	89 34 24             	mov    %esi,(%esp)
f010123e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101242:	89 da                	mov    %ebx,%edx
f0101244:	8b 45 08             	mov    0x8(%ebp),%eax
f0101247:	e8 04 fb ff ff       	call   f0100d50 <printnum>
			break;
f010124c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010124f:	e9 79 fc ff ff       	jmp    f0100ecd <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101254:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101258:	89 14 24             	mov    %edx,(%esp)
f010125b:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010125e:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101261:	e9 67 fc ff ff       	jmp    f0100ecd <vprintfmt+0x23>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101266:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010126a:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101271:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101274:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0101278:	0f 84 4f fc ff ff    	je     f0100ecd <vprintfmt+0x23>
f010127e:	83 ee 01             	sub    $0x1,%esi
f0101281:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0101285:	75 f7                	jne    f010127e <vprintfmt+0x3d4>
f0101287:	e9 41 fc ff ff       	jmp    f0100ecd <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
f010128c:	83 c4 4c             	add    $0x4c,%esp
f010128f:	5b                   	pop    %ebx
f0101290:	5e                   	pop    %esi
f0101291:	5f                   	pop    %edi
f0101292:	5d                   	pop    %ebp
f0101293:	c3                   	ret    

f0101294 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101294:	55                   	push   %ebp
f0101295:	89 e5                	mov    %esp,%ebp
f0101297:	83 ec 28             	sub    $0x28,%esp
f010129a:	8b 45 08             	mov    0x8(%ebp),%eax
f010129d:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01012a0:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01012a3:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01012a7:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01012aa:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01012b1:	85 c0                	test   %eax,%eax
f01012b3:	74 30                	je     f01012e5 <vsnprintf+0x51>
f01012b5:	85 d2                	test   %edx,%edx
f01012b7:	7e 2c                	jle    f01012e5 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01012b9:	8b 45 14             	mov    0x14(%ebp),%eax
f01012bc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012c0:	8b 45 10             	mov    0x10(%ebp),%eax
f01012c3:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012c7:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01012ca:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012ce:	c7 04 24 65 0e 10 f0 	movl   $0xf0100e65,(%esp)
f01012d5:	e8 d0 fb ff ff       	call   f0100eaa <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01012da:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01012dd:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01012e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01012e3:	eb 05                	jmp    f01012ea <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01012e5:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01012ea:	c9                   	leave  
f01012eb:	c3                   	ret    

f01012ec <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01012ec:	55                   	push   %ebp
f01012ed:	89 e5                	mov    %esp,%ebp
f01012ef:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01012f2:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01012f5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012f9:	8b 45 10             	mov    0x10(%ebp),%eax
f01012fc:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101300:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101303:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101307:	8b 45 08             	mov    0x8(%ebp),%eax
f010130a:	89 04 24             	mov    %eax,(%esp)
f010130d:	e8 82 ff ff ff       	call   f0101294 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101312:	c9                   	leave  
f0101313:	c3                   	ret    
	...

f0101320 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101320:	55                   	push   %ebp
f0101321:	89 e5                	mov    %esp,%ebp
f0101323:	57                   	push   %edi
f0101324:	56                   	push   %esi
f0101325:	53                   	push   %ebx
f0101326:	83 ec 1c             	sub    $0x1c,%esp
f0101329:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010132c:	85 c0                	test   %eax,%eax
f010132e:	74 10                	je     f0101340 <readline+0x20>
		cprintf("%s", prompt);
f0101330:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101334:	c7 04 24 de 1f 10 f0 	movl   $0xf0101fde,(%esp)
f010133b:	e8 0e f7 ff ff       	call   f0100a4e <cprintf>

	i = 0;
	echoing = iscons(0);
f0101340:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101347:	e8 c7 f2 ff ff       	call   f0100613 <iscons>
f010134c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010134e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101353:	e8 aa f2 ff ff       	call   f0100602 <getchar>
f0101358:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010135a:	85 c0                	test   %eax,%eax
f010135c:	79 17                	jns    f0101375 <readline+0x55>
			cprintf("read error: %e\n", c);
f010135e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101362:	c7 04 24 c0 21 10 f0 	movl   $0xf01021c0,(%esp)
f0101369:	e8 e0 f6 ff ff       	call   f0100a4e <cprintf>
			return NULL;
f010136e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101373:	eb 6d                	jmp    f01013e2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101375:	83 f8 08             	cmp    $0x8,%eax
f0101378:	74 05                	je     f010137f <readline+0x5f>
f010137a:	83 f8 7f             	cmp    $0x7f,%eax
f010137d:	75 19                	jne    f0101398 <readline+0x78>
f010137f:	85 f6                	test   %esi,%esi
f0101381:	7e 15                	jle    f0101398 <readline+0x78>
			if (echoing)
f0101383:	85 ff                	test   %edi,%edi
f0101385:	74 0c                	je     f0101393 <readline+0x73>
				cputchar('\b');
f0101387:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010138e:	e8 5f f2 ff ff       	call   f01005f2 <cputchar>
			i--;
f0101393:	83 ee 01             	sub    $0x1,%esi
f0101396:	eb bb                	jmp    f0101353 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101398:	83 fb 1f             	cmp    $0x1f,%ebx
f010139b:	7e 1f                	jle    f01013bc <readline+0x9c>
f010139d:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01013a3:	7f 17                	jg     f01013bc <readline+0x9c>
			if (echoing)
f01013a5:	85 ff                	test   %edi,%edi
f01013a7:	74 08                	je     f01013b1 <readline+0x91>
				cputchar(c);
f01013a9:	89 1c 24             	mov    %ebx,(%esp)
f01013ac:	e8 41 f2 ff ff       	call   f01005f2 <cputchar>
			buf[i++] = c;
f01013b1:	88 9e 60 25 11 f0    	mov    %bl,-0xfeedaa0(%esi)
f01013b7:	83 c6 01             	add    $0x1,%esi
f01013ba:	eb 97                	jmp    f0101353 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01013bc:	83 fb 0a             	cmp    $0xa,%ebx
f01013bf:	74 05                	je     f01013c6 <readline+0xa6>
f01013c1:	83 fb 0d             	cmp    $0xd,%ebx
f01013c4:	75 8d                	jne    f0101353 <readline+0x33>
			if (echoing)
f01013c6:	85 ff                	test   %edi,%edi
f01013c8:	74 0c                	je     f01013d6 <readline+0xb6>
				cputchar('\n');
f01013ca:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01013d1:	e8 1c f2 ff ff       	call   f01005f2 <cputchar>
			buf[i] = 0;
f01013d6:	c6 86 60 25 11 f0 00 	movb   $0x0,-0xfeedaa0(%esi)
			return buf;
f01013dd:	b8 60 25 11 f0       	mov    $0xf0112560,%eax
		}
	}
}
f01013e2:	83 c4 1c             	add    $0x1c,%esp
f01013e5:	5b                   	pop    %ebx
f01013e6:	5e                   	pop    %esi
f01013e7:	5f                   	pop    %edi
f01013e8:	5d                   	pop    %ebp
f01013e9:	c3                   	ret    
f01013ea:	00 00                	add    %al,(%eax)
f01013ec:	00 00                	add    %al,(%eax)
	...

f01013f0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01013f0:	55                   	push   %ebp
f01013f1:	89 e5                	mov    %esp,%ebp
f01013f3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01013f6:	b8 00 00 00 00       	mov    $0x0,%eax
f01013fb:	80 3a 00             	cmpb   $0x0,(%edx)
f01013fe:	74 09                	je     f0101409 <strlen+0x19>
		n++;
f0101400:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101403:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101407:	75 f7                	jne    f0101400 <strlen+0x10>
		n++;
	return n;
}
f0101409:	5d                   	pop    %ebp
f010140a:	c3                   	ret    

f010140b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010140b:	55                   	push   %ebp
f010140c:	89 e5                	mov    %esp,%ebp
f010140e:	53                   	push   %ebx
f010140f:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101412:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101415:	b8 00 00 00 00       	mov    $0x0,%eax
f010141a:	85 c9                	test   %ecx,%ecx
f010141c:	74 1a                	je     f0101438 <strnlen+0x2d>
f010141e:	80 3b 00             	cmpb   $0x0,(%ebx)
f0101421:	74 15                	je     f0101438 <strnlen+0x2d>
f0101423:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f0101428:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010142a:	39 ca                	cmp    %ecx,%edx
f010142c:	74 0a                	je     f0101438 <strnlen+0x2d>
f010142e:	83 c2 01             	add    $0x1,%edx
f0101431:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0101436:	75 f0                	jne    f0101428 <strnlen+0x1d>
		n++;
	return n;
}
f0101438:	5b                   	pop    %ebx
f0101439:	5d                   	pop    %ebp
f010143a:	c3                   	ret    

f010143b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010143b:	55                   	push   %ebp
f010143c:	89 e5                	mov    %esp,%ebp
f010143e:	53                   	push   %ebx
f010143f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101442:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101445:	ba 00 00 00 00       	mov    $0x0,%edx
f010144a:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f010144e:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0101451:	83 c2 01             	add    $0x1,%edx
f0101454:	84 c9                	test   %cl,%cl
f0101456:	75 f2                	jne    f010144a <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0101458:	5b                   	pop    %ebx
f0101459:	5d                   	pop    %ebp
f010145a:	c3                   	ret    

f010145b <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010145b:	55                   	push   %ebp
f010145c:	89 e5                	mov    %esp,%ebp
f010145e:	56                   	push   %esi
f010145f:	53                   	push   %ebx
f0101460:	8b 45 08             	mov    0x8(%ebp),%eax
f0101463:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101466:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101469:	85 f6                	test   %esi,%esi
f010146b:	74 18                	je     f0101485 <strncpy+0x2a>
f010146d:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f0101472:	0f b6 1a             	movzbl (%edx),%ebx
f0101475:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101478:	80 3a 01             	cmpb   $0x1,(%edx)
f010147b:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010147e:	83 c1 01             	add    $0x1,%ecx
f0101481:	39 f1                	cmp    %esi,%ecx
f0101483:	75 ed                	jne    f0101472 <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101485:	5b                   	pop    %ebx
f0101486:	5e                   	pop    %esi
f0101487:	5d                   	pop    %ebp
f0101488:	c3                   	ret    

f0101489 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101489:	55                   	push   %ebp
f010148a:	89 e5                	mov    %esp,%ebp
f010148c:	57                   	push   %edi
f010148d:	56                   	push   %esi
f010148e:	53                   	push   %ebx
f010148f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101492:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101495:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101498:	89 f8                	mov    %edi,%eax
f010149a:	85 f6                	test   %esi,%esi
f010149c:	74 2b                	je     f01014c9 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f010149e:	83 fe 01             	cmp    $0x1,%esi
f01014a1:	74 23                	je     f01014c6 <strlcpy+0x3d>
f01014a3:	0f b6 0b             	movzbl (%ebx),%ecx
f01014a6:	84 c9                	test   %cl,%cl
f01014a8:	74 1c                	je     f01014c6 <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f01014aa:	83 ee 02             	sub    $0x2,%esi
f01014ad:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01014b2:	88 08                	mov    %cl,(%eax)
f01014b4:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01014b7:	39 f2                	cmp    %esi,%edx
f01014b9:	74 0b                	je     f01014c6 <strlcpy+0x3d>
f01014bb:	83 c2 01             	add    $0x1,%edx
f01014be:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01014c2:	84 c9                	test   %cl,%cl
f01014c4:	75 ec                	jne    f01014b2 <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f01014c6:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01014c9:	29 f8                	sub    %edi,%eax
}
f01014cb:	5b                   	pop    %ebx
f01014cc:	5e                   	pop    %esi
f01014cd:	5f                   	pop    %edi
f01014ce:	5d                   	pop    %ebp
f01014cf:	c3                   	ret    

f01014d0 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01014d0:	55                   	push   %ebp
f01014d1:	89 e5                	mov    %esp,%ebp
f01014d3:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01014d6:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01014d9:	0f b6 01             	movzbl (%ecx),%eax
f01014dc:	84 c0                	test   %al,%al
f01014de:	74 16                	je     f01014f6 <strcmp+0x26>
f01014e0:	3a 02                	cmp    (%edx),%al
f01014e2:	75 12                	jne    f01014f6 <strcmp+0x26>
		p++, q++;
f01014e4:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01014e7:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f01014eb:	84 c0                	test   %al,%al
f01014ed:	74 07                	je     f01014f6 <strcmp+0x26>
f01014ef:	83 c1 01             	add    $0x1,%ecx
f01014f2:	3a 02                	cmp    (%edx),%al
f01014f4:	74 ee                	je     f01014e4 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01014f6:	0f b6 c0             	movzbl %al,%eax
f01014f9:	0f b6 12             	movzbl (%edx),%edx
f01014fc:	29 d0                	sub    %edx,%eax
}
f01014fe:	5d                   	pop    %ebp
f01014ff:	c3                   	ret    

f0101500 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101500:	55                   	push   %ebp
f0101501:	89 e5                	mov    %esp,%ebp
f0101503:	53                   	push   %ebx
f0101504:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101507:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010150a:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010150d:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101512:	85 d2                	test   %edx,%edx
f0101514:	74 28                	je     f010153e <strncmp+0x3e>
f0101516:	0f b6 01             	movzbl (%ecx),%eax
f0101519:	84 c0                	test   %al,%al
f010151b:	74 24                	je     f0101541 <strncmp+0x41>
f010151d:	3a 03                	cmp    (%ebx),%al
f010151f:	75 20                	jne    f0101541 <strncmp+0x41>
f0101521:	83 ea 01             	sub    $0x1,%edx
f0101524:	74 13                	je     f0101539 <strncmp+0x39>
		n--, p++, q++;
f0101526:	83 c1 01             	add    $0x1,%ecx
f0101529:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010152c:	0f b6 01             	movzbl (%ecx),%eax
f010152f:	84 c0                	test   %al,%al
f0101531:	74 0e                	je     f0101541 <strncmp+0x41>
f0101533:	3a 03                	cmp    (%ebx),%al
f0101535:	74 ea                	je     f0101521 <strncmp+0x21>
f0101537:	eb 08                	jmp    f0101541 <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101539:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010153e:	5b                   	pop    %ebx
f010153f:	5d                   	pop    %ebp
f0101540:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101541:	0f b6 01             	movzbl (%ecx),%eax
f0101544:	0f b6 13             	movzbl (%ebx),%edx
f0101547:	29 d0                	sub    %edx,%eax
f0101549:	eb f3                	jmp    f010153e <strncmp+0x3e>

f010154b <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010154b:	55                   	push   %ebp
f010154c:	89 e5                	mov    %esp,%ebp
f010154e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101551:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101555:	0f b6 10             	movzbl (%eax),%edx
f0101558:	84 d2                	test   %dl,%dl
f010155a:	74 1c                	je     f0101578 <strchr+0x2d>
		if (*s == c)
f010155c:	38 ca                	cmp    %cl,%dl
f010155e:	75 09                	jne    f0101569 <strchr+0x1e>
f0101560:	eb 1b                	jmp    f010157d <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101562:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f0101565:	38 ca                	cmp    %cl,%dl
f0101567:	74 14                	je     f010157d <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101569:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f010156d:	84 d2                	test   %dl,%dl
f010156f:	75 f1                	jne    f0101562 <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f0101571:	b8 00 00 00 00       	mov    $0x0,%eax
f0101576:	eb 05                	jmp    f010157d <strchr+0x32>
f0101578:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010157d:	5d                   	pop    %ebp
f010157e:	c3                   	ret    

f010157f <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010157f:	55                   	push   %ebp
f0101580:	89 e5                	mov    %esp,%ebp
f0101582:	8b 45 08             	mov    0x8(%ebp),%eax
f0101585:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101589:	0f b6 10             	movzbl (%eax),%edx
f010158c:	84 d2                	test   %dl,%dl
f010158e:	74 14                	je     f01015a4 <strfind+0x25>
		if (*s == c)
f0101590:	38 ca                	cmp    %cl,%dl
f0101592:	75 06                	jne    f010159a <strfind+0x1b>
f0101594:	eb 0e                	jmp    f01015a4 <strfind+0x25>
f0101596:	38 ca                	cmp    %cl,%dl
f0101598:	74 0a                	je     f01015a4 <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010159a:	83 c0 01             	add    $0x1,%eax
f010159d:	0f b6 10             	movzbl (%eax),%edx
f01015a0:	84 d2                	test   %dl,%dl
f01015a2:	75 f2                	jne    f0101596 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f01015a4:	5d                   	pop    %ebp
f01015a5:	c3                   	ret    

f01015a6 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01015a6:	55                   	push   %ebp
f01015a7:	89 e5                	mov    %esp,%ebp
f01015a9:	83 ec 0c             	sub    $0xc,%esp
f01015ac:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f01015af:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01015b2:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01015b5:	8b 7d 08             	mov    0x8(%ebp),%edi
f01015b8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015bb:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01015be:	85 c9                	test   %ecx,%ecx
f01015c0:	74 30                	je     f01015f2 <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01015c2:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01015c8:	75 25                	jne    f01015ef <memset+0x49>
f01015ca:	f6 c1 03             	test   $0x3,%cl
f01015cd:	75 20                	jne    f01015ef <memset+0x49>
		c &= 0xFF;
f01015cf:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01015d2:	89 d3                	mov    %edx,%ebx
f01015d4:	c1 e3 08             	shl    $0x8,%ebx
f01015d7:	89 d6                	mov    %edx,%esi
f01015d9:	c1 e6 18             	shl    $0x18,%esi
f01015dc:	89 d0                	mov    %edx,%eax
f01015de:	c1 e0 10             	shl    $0x10,%eax
f01015e1:	09 f0                	or     %esi,%eax
f01015e3:	09 d0                	or     %edx,%eax
f01015e5:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01015e7:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01015ea:	fc                   	cld    
f01015eb:	f3 ab                	rep stos %eax,%es:(%edi)
f01015ed:	eb 03                	jmp    f01015f2 <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01015ef:	fc                   	cld    
f01015f0:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01015f2:	89 f8                	mov    %edi,%eax
f01015f4:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01015f7:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01015fa:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01015fd:	89 ec                	mov    %ebp,%esp
f01015ff:	5d                   	pop    %ebp
f0101600:	c3                   	ret    

f0101601 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101601:	55                   	push   %ebp
f0101602:	89 e5                	mov    %esp,%ebp
f0101604:	83 ec 08             	sub    $0x8,%esp
f0101607:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010160a:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010160d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101610:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101613:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101616:	39 c6                	cmp    %eax,%esi
f0101618:	73 36                	jae    f0101650 <memmove+0x4f>
f010161a:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010161d:	39 d0                	cmp    %edx,%eax
f010161f:	73 2f                	jae    f0101650 <memmove+0x4f>
		s += n;
		d += n;
f0101621:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101624:	f6 c2 03             	test   $0x3,%dl
f0101627:	75 1b                	jne    f0101644 <memmove+0x43>
f0101629:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010162f:	75 13                	jne    f0101644 <memmove+0x43>
f0101631:	f6 c1 03             	test   $0x3,%cl
f0101634:	75 0e                	jne    f0101644 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101636:	83 ef 04             	sub    $0x4,%edi
f0101639:	8d 72 fc             	lea    -0x4(%edx),%esi
f010163c:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010163f:	fd                   	std    
f0101640:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101642:	eb 09                	jmp    f010164d <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101644:	83 ef 01             	sub    $0x1,%edi
f0101647:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010164a:	fd                   	std    
f010164b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010164d:	fc                   	cld    
f010164e:	eb 20                	jmp    f0101670 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101650:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101656:	75 13                	jne    f010166b <memmove+0x6a>
f0101658:	a8 03                	test   $0x3,%al
f010165a:	75 0f                	jne    f010166b <memmove+0x6a>
f010165c:	f6 c1 03             	test   $0x3,%cl
f010165f:	75 0a                	jne    f010166b <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101661:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0101664:	89 c7                	mov    %eax,%edi
f0101666:	fc                   	cld    
f0101667:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101669:	eb 05                	jmp    f0101670 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010166b:	89 c7                	mov    %eax,%edi
f010166d:	fc                   	cld    
f010166e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101670:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0101673:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101676:	89 ec                	mov    %ebp,%esp
f0101678:	5d                   	pop    %ebp
f0101679:	c3                   	ret    

f010167a <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f010167a:	55                   	push   %ebp
f010167b:	89 e5                	mov    %esp,%ebp
f010167d:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101680:	8b 45 10             	mov    0x10(%ebp),%eax
f0101683:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101687:	8b 45 0c             	mov    0xc(%ebp),%eax
f010168a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010168e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101691:	89 04 24             	mov    %eax,(%esp)
f0101694:	e8 68 ff ff ff       	call   f0101601 <memmove>
}
f0101699:	c9                   	leave  
f010169a:	c3                   	ret    

f010169b <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010169b:	55                   	push   %ebp
f010169c:	89 e5                	mov    %esp,%ebp
f010169e:	57                   	push   %edi
f010169f:	56                   	push   %esi
f01016a0:	53                   	push   %ebx
f01016a1:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01016a4:	8b 75 0c             	mov    0xc(%ebp),%esi
f01016a7:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01016aa:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01016af:	85 ff                	test   %edi,%edi
f01016b1:	74 37                	je     f01016ea <memcmp+0x4f>
		if (*s1 != *s2)
f01016b3:	0f b6 03             	movzbl (%ebx),%eax
f01016b6:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01016b9:	83 ef 01             	sub    $0x1,%edi
f01016bc:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f01016c1:	38 c8                	cmp    %cl,%al
f01016c3:	74 1c                	je     f01016e1 <memcmp+0x46>
f01016c5:	eb 10                	jmp    f01016d7 <memcmp+0x3c>
f01016c7:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f01016cc:	83 c2 01             	add    $0x1,%edx
f01016cf:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f01016d3:	38 c8                	cmp    %cl,%al
f01016d5:	74 0a                	je     f01016e1 <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f01016d7:	0f b6 c0             	movzbl %al,%eax
f01016da:	0f b6 c9             	movzbl %cl,%ecx
f01016dd:	29 c8                	sub    %ecx,%eax
f01016df:	eb 09                	jmp    f01016ea <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01016e1:	39 fa                	cmp    %edi,%edx
f01016e3:	75 e2                	jne    f01016c7 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01016e5:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01016ea:	5b                   	pop    %ebx
f01016eb:	5e                   	pop    %esi
f01016ec:	5f                   	pop    %edi
f01016ed:	5d                   	pop    %ebp
f01016ee:	c3                   	ret    

f01016ef <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01016ef:	55                   	push   %ebp
f01016f0:	89 e5                	mov    %esp,%ebp
f01016f2:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01016f5:	89 c2                	mov    %eax,%edx
f01016f7:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01016fa:	39 d0                	cmp    %edx,%eax
f01016fc:	73 15                	jae    f0101713 <memfind+0x24>
		if (*(const unsigned char *) s == (unsigned char) c)
f01016fe:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f0101702:	38 08                	cmp    %cl,(%eax)
f0101704:	75 06                	jne    f010170c <memfind+0x1d>
f0101706:	eb 0b                	jmp    f0101713 <memfind+0x24>
f0101708:	38 08                	cmp    %cl,(%eax)
f010170a:	74 07                	je     f0101713 <memfind+0x24>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010170c:	83 c0 01             	add    $0x1,%eax
f010170f:	39 d0                	cmp    %edx,%eax
f0101711:	75 f5                	jne    f0101708 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101713:	5d                   	pop    %ebp
f0101714:	c3                   	ret    

f0101715 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101715:	55                   	push   %ebp
f0101716:	89 e5                	mov    %esp,%ebp
f0101718:	57                   	push   %edi
f0101719:	56                   	push   %esi
f010171a:	53                   	push   %ebx
f010171b:	8b 55 08             	mov    0x8(%ebp),%edx
f010171e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101721:	0f b6 02             	movzbl (%edx),%eax
f0101724:	3c 20                	cmp    $0x20,%al
f0101726:	74 04                	je     f010172c <strtol+0x17>
f0101728:	3c 09                	cmp    $0x9,%al
f010172a:	75 0e                	jne    f010173a <strtol+0x25>
		s++;
f010172c:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010172f:	0f b6 02             	movzbl (%edx),%eax
f0101732:	3c 20                	cmp    $0x20,%al
f0101734:	74 f6                	je     f010172c <strtol+0x17>
f0101736:	3c 09                	cmp    $0x9,%al
f0101738:	74 f2                	je     f010172c <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f010173a:	3c 2b                	cmp    $0x2b,%al
f010173c:	75 0a                	jne    f0101748 <strtol+0x33>
		s++;
f010173e:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101741:	bf 00 00 00 00       	mov    $0x0,%edi
f0101746:	eb 10                	jmp    f0101758 <strtol+0x43>
f0101748:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010174d:	3c 2d                	cmp    $0x2d,%al
f010174f:	75 07                	jne    f0101758 <strtol+0x43>
		s++, neg = 1;
f0101751:	83 c2 01             	add    $0x1,%edx
f0101754:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101758:	85 db                	test   %ebx,%ebx
f010175a:	0f 94 c0             	sete   %al
f010175d:	74 05                	je     f0101764 <strtol+0x4f>
f010175f:	83 fb 10             	cmp    $0x10,%ebx
f0101762:	75 15                	jne    f0101779 <strtol+0x64>
f0101764:	80 3a 30             	cmpb   $0x30,(%edx)
f0101767:	75 10                	jne    f0101779 <strtol+0x64>
f0101769:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f010176d:	75 0a                	jne    f0101779 <strtol+0x64>
		s += 2, base = 16;
f010176f:	83 c2 02             	add    $0x2,%edx
f0101772:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101777:	eb 13                	jmp    f010178c <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f0101779:	84 c0                	test   %al,%al
f010177b:	74 0f                	je     f010178c <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010177d:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101782:	80 3a 30             	cmpb   $0x30,(%edx)
f0101785:	75 05                	jne    f010178c <strtol+0x77>
		s++, base = 8;
f0101787:	83 c2 01             	add    $0x1,%edx
f010178a:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f010178c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101791:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101793:	0f b6 0a             	movzbl (%edx),%ecx
f0101796:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0101799:	80 fb 09             	cmp    $0x9,%bl
f010179c:	77 08                	ja     f01017a6 <strtol+0x91>
			dig = *s - '0';
f010179e:	0f be c9             	movsbl %cl,%ecx
f01017a1:	83 e9 30             	sub    $0x30,%ecx
f01017a4:	eb 1e                	jmp    f01017c4 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f01017a6:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f01017a9:	80 fb 19             	cmp    $0x19,%bl
f01017ac:	77 08                	ja     f01017b6 <strtol+0xa1>
			dig = *s - 'a' + 10;
f01017ae:	0f be c9             	movsbl %cl,%ecx
f01017b1:	83 e9 57             	sub    $0x57,%ecx
f01017b4:	eb 0e                	jmp    f01017c4 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f01017b6:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f01017b9:	80 fb 19             	cmp    $0x19,%bl
f01017bc:	77 14                	ja     f01017d2 <strtol+0xbd>
			dig = *s - 'A' + 10;
f01017be:	0f be c9             	movsbl %cl,%ecx
f01017c1:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01017c4:	39 f1                	cmp    %esi,%ecx
f01017c6:	7d 0e                	jge    f01017d6 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f01017c8:	83 c2 01             	add    $0x1,%edx
f01017cb:	0f af c6             	imul   %esi,%eax
f01017ce:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f01017d0:	eb c1                	jmp    f0101793 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f01017d2:	89 c1                	mov    %eax,%ecx
f01017d4:	eb 02                	jmp    f01017d8 <strtol+0xc3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f01017d6:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f01017d8:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01017dc:	74 05                	je     f01017e3 <strtol+0xce>
		*endptr = (char *) s;
f01017de:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01017e1:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f01017e3:	89 ca                	mov    %ecx,%edx
f01017e5:	f7 da                	neg    %edx
f01017e7:	85 ff                	test   %edi,%edi
f01017e9:	0f 45 c2             	cmovne %edx,%eax
}
f01017ec:	5b                   	pop    %ebx
f01017ed:	5e                   	pop    %esi
f01017ee:	5f                   	pop    %edi
f01017ef:	5d                   	pop    %ebp
f01017f0:	c3                   	ret    
	...

f0101800 <__udivdi3>:
f0101800:	83 ec 1c             	sub    $0x1c,%esp
f0101803:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0101807:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f010180b:	8b 44 24 20          	mov    0x20(%esp),%eax
f010180f:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101813:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101817:	8b 74 24 24          	mov    0x24(%esp),%esi
f010181b:	85 ff                	test   %edi,%edi
f010181d:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101821:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101825:	89 cd                	mov    %ecx,%ebp
f0101827:	89 44 24 04          	mov    %eax,0x4(%esp)
f010182b:	75 33                	jne    f0101860 <__udivdi3+0x60>
f010182d:	39 f1                	cmp    %esi,%ecx
f010182f:	77 57                	ja     f0101888 <__udivdi3+0x88>
f0101831:	85 c9                	test   %ecx,%ecx
f0101833:	75 0b                	jne    f0101840 <__udivdi3+0x40>
f0101835:	b8 01 00 00 00       	mov    $0x1,%eax
f010183a:	31 d2                	xor    %edx,%edx
f010183c:	f7 f1                	div    %ecx
f010183e:	89 c1                	mov    %eax,%ecx
f0101840:	89 f0                	mov    %esi,%eax
f0101842:	31 d2                	xor    %edx,%edx
f0101844:	f7 f1                	div    %ecx
f0101846:	89 c6                	mov    %eax,%esi
f0101848:	8b 44 24 04          	mov    0x4(%esp),%eax
f010184c:	f7 f1                	div    %ecx
f010184e:	89 f2                	mov    %esi,%edx
f0101850:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101854:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101858:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010185c:	83 c4 1c             	add    $0x1c,%esp
f010185f:	c3                   	ret    
f0101860:	31 d2                	xor    %edx,%edx
f0101862:	31 c0                	xor    %eax,%eax
f0101864:	39 f7                	cmp    %esi,%edi
f0101866:	77 e8                	ja     f0101850 <__udivdi3+0x50>
f0101868:	0f bd cf             	bsr    %edi,%ecx
f010186b:	83 f1 1f             	xor    $0x1f,%ecx
f010186e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101872:	75 2c                	jne    f01018a0 <__udivdi3+0xa0>
f0101874:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0101878:	76 04                	jbe    f010187e <__udivdi3+0x7e>
f010187a:	39 f7                	cmp    %esi,%edi
f010187c:	73 d2                	jae    f0101850 <__udivdi3+0x50>
f010187e:	31 d2                	xor    %edx,%edx
f0101880:	b8 01 00 00 00       	mov    $0x1,%eax
f0101885:	eb c9                	jmp    f0101850 <__udivdi3+0x50>
f0101887:	90                   	nop
f0101888:	89 f2                	mov    %esi,%edx
f010188a:	f7 f1                	div    %ecx
f010188c:	31 d2                	xor    %edx,%edx
f010188e:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101892:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101896:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010189a:	83 c4 1c             	add    $0x1c,%esp
f010189d:	c3                   	ret    
f010189e:	66 90                	xchg   %ax,%ax
f01018a0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01018a5:	b8 20 00 00 00       	mov    $0x20,%eax
f01018aa:	89 ea                	mov    %ebp,%edx
f01018ac:	2b 44 24 04          	sub    0x4(%esp),%eax
f01018b0:	d3 e7                	shl    %cl,%edi
f01018b2:	89 c1                	mov    %eax,%ecx
f01018b4:	d3 ea                	shr    %cl,%edx
f01018b6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01018bb:	09 fa                	or     %edi,%edx
f01018bd:	89 f7                	mov    %esi,%edi
f01018bf:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01018c3:	89 f2                	mov    %esi,%edx
f01018c5:	8b 74 24 08          	mov    0x8(%esp),%esi
f01018c9:	d3 e5                	shl    %cl,%ebp
f01018cb:	89 c1                	mov    %eax,%ecx
f01018cd:	d3 ef                	shr    %cl,%edi
f01018cf:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01018d4:	d3 e2                	shl    %cl,%edx
f01018d6:	89 c1                	mov    %eax,%ecx
f01018d8:	d3 ee                	shr    %cl,%esi
f01018da:	09 d6                	or     %edx,%esi
f01018dc:	89 fa                	mov    %edi,%edx
f01018de:	89 f0                	mov    %esi,%eax
f01018e0:	f7 74 24 0c          	divl   0xc(%esp)
f01018e4:	89 d7                	mov    %edx,%edi
f01018e6:	89 c6                	mov    %eax,%esi
f01018e8:	f7 e5                	mul    %ebp
f01018ea:	39 d7                	cmp    %edx,%edi
f01018ec:	72 22                	jb     f0101910 <__udivdi3+0x110>
f01018ee:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f01018f2:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01018f7:	d3 e5                	shl    %cl,%ebp
f01018f9:	39 c5                	cmp    %eax,%ebp
f01018fb:	73 04                	jae    f0101901 <__udivdi3+0x101>
f01018fd:	39 d7                	cmp    %edx,%edi
f01018ff:	74 0f                	je     f0101910 <__udivdi3+0x110>
f0101901:	89 f0                	mov    %esi,%eax
f0101903:	31 d2                	xor    %edx,%edx
f0101905:	e9 46 ff ff ff       	jmp    f0101850 <__udivdi3+0x50>
f010190a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101910:	8d 46 ff             	lea    -0x1(%esi),%eax
f0101913:	31 d2                	xor    %edx,%edx
f0101915:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101919:	8b 7c 24 14          	mov    0x14(%esp),%edi
f010191d:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101921:	83 c4 1c             	add    $0x1c,%esp
f0101924:	c3                   	ret    
	...

f0101930 <__umoddi3>:
f0101930:	83 ec 1c             	sub    $0x1c,%esp
f0101933:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101937:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f010193b:	8b 44 24 20          	mov    0x20(%esp),%eax
f010193f:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101943:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101947:	8b 74 24 24          	mov    0x24(%esp),%esi
f010194b:	85 ed                	test   %ebp,%ebp
f010194d:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0101951:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101955:	89 cf                	mov    %ecx,%edi
f0101957:	89 04 24             	mov    %eax,(%esp)
f010195a:	89 f2                	mov    %esi,%edx
f010195c:	75 1a                	jne    f0101978 <__umoddi3+0x48>
f010195e:	39 f1                	cmp    %esi,%ecx
f0101960:	76 4e                	jbe    f01019b0 <__umoddi3+0x80>
f0101962:	f7 f1                	div    %ecx
f0101964:	89 d0                	mov    %edx,%eax
f0101966:	31 d2                	xor    %edx,%edx
f0101968:	8b 74 24 10          	mov    0x10(%esp),%esi
f010196c:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101970:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101974:	83 c4 1c             	add    $0x1c,%esp
f0101977:	c3                   	ret    
f0101978:	39 f5                	cmp    %esi,%ebp
f010197a:	77 54                	ja     f01019d0 <__umoddi3+0xa0>
f010197c:	0f bd c5             	bsr    %ebp,%eax
f010197f:	83 f0 1f             	xor    $0x1f,%eax
f0101982:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101986:	75 60                	jne    f01019e8 <__umoddi3+0xb8>
f0101988:	3b 0c 24             	cmp    (%esp),%ecx
f010198b:	0f 87 07 01 00 00    	ja     f0101a98 <__umoddi3+0x168>
f0101991:	89 f2                	mov    %esi,%edx
f0101993:	8b 34 24             	mov    (%esp),%esi
f0101996:	29 ce                	sub    %ecx,%esi
f0101998:	19 ea                	sbb    %ebp,%edx
f010199a:	89 34 24             	mov    %esi,(%esp)
f010199d:	8b 04 24             	mov    (%esp),%eax
f01019a0:	8b 74 24 10          	mov    0x10(%esp),%esi
f01019a4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01019a8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01019ac:	83 c4 1c             	add    $0x1c,%esp
f01019af:	c3                   	ret    
f01019b0:	85 c9                	test   %ecx,%ecx
f01019b2:	75 0b                	jne    f01019bf <__umoddi3+0x8f>
f01019b4:	b8 01 00 00 00       	mov    $0x1,%eax
f01019b9:	31 d2                	xor    %edx,%edx
f01019bb:	f7 f1                	div    %ecx
f01019bd:	89 c1                	mov    %eax,%ecx
f01019bf:	89 f0                	mov    %esi,%eax
f01019c1:	31 d2                	xor    %edx,%edx
f01019c3:	f7 f1                	div    %ecx
f01019c5:	8b 04 24             	mov    (%esp),%eax
f01019c8:	f7 f1                	div    %ecx
f01019ca:	eb 98                	jmp    f0101964 <__umoddi3+0x34>
f01019cc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019d0:	89 f2                	mov    %esi,%edx
f01019d2:	8b 74 24 10          	mov    0x10(%esp),%esi
f01019d6:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01019da:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01019de:	83 c4 1c             	add    $0x1c,%esp
f01019e1:	c3                   	ret    
f01019e2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01019e8:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01019ed:	89 e8                	mov    %ebp,%eax
f01019ef:	bd 20 00 00 00       	mov    $0x20,%ebp
f01019f4:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f01019f8:	89 fa                	mov    %edi,%edx
f01019fa:	d3 e0                	shl    %cl,%eax
f01019fc:	89 e9                	mov    %ebp,%ecx
f01019fe:	d3 ea                	shr    %cl,%edx
f0101a00:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101a05:	09 c2                	or     %eax,%edx
f0101a07:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101a0b:	89 14 24             	mov    %edx,(%esp)
f0101a0e:	89 f2                	mov    %esi,%edx
f0101a10:	d3 e7                	shl    %cl,%edi
f0101a12:	89 e9                	mov    %ebp,%ecx
f0101a14:	d3 ea                	shr    %cl,%edx
f0101a16:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101a1b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101a1f:	d3 e6                	shl    %cl,%esi
f0101a21:	89 e9                	mov    %ebp,%ecx
f0101a23:	d3 e8                	shr    %cl,%eax
f0101a25:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101a2a:	09 f0                	or     %esi,%eax
f0101a2c:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101a30:	f7 34 24             	divl   (%esp)
f0101a33:	d3 e6                	shl    %cl,%esi
f0101a35:	89 74 24 08          	mov    %esi,0x8(%esp)
f0101a39:	89 d6                	mov    %edx,%esi
f0101a3b:	f7 e7                	mul    %edi
f0101a3d:	39 d6                	cmp    %edx,%esi
f0101a3f:	89 c1                	mov    %eax,%ecx
f0101a41:	89 d7                	mov    %edx,%edi
f0101a43:	72 3f                	jb     f0101a84 <__umoddi3+0x154>
f0101a45:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0101a49:	72 35                	jb     f0101a80 <__umoddi3+0x150>
f0101a4b:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101a4f:	29 c8                	sub    %ecx,%eax
f0101a51:	19 fe                	sbb    %edi,%esi
f0101a53:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101a58:	89 f2                	mov    %esi,%edx
f0101a5a:	d3 e8                	shr    %cl,%eax
f0101a5c:	89 e9                	mov    %ebp,%ecx
f0101a5e:	d3 e2                	shl    %cl,%edx
f0101a60:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101a65:	09 d0                	or     %edx,%eax
f0101a67:	89 f2                	mov    %esi,%edx
f0101a69:	d3 ea                	shr    %cl,%edx
f0101a6b:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101a6f:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101a73:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101a77:	83 c4 1c             	add    $0x1c,%esp
f0101a7a:	c3                   	ret    
f0101a7b:	90                   	nop
f0101a7c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a80:	39 d6                	cmp    %edx,%esi
f0101a82:	75 c7                	jne    f0101a4b <__umoddi3+0x11b>
f0101a84:	89 d7                	mov    %edx,%edi
f0101a86:	89 c1                	mov    %eax,%ecx
f0101a88:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f0101a8c:	1b 3c 24             	sbb    (%esp),%edi
f0101a8f:	eb ba                	jmp    f0101a4b <__umoddi3+0x11b>
f0101a91:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101a98:	39 f5                	cmp    %esi,%ebp
f0101a9a:	0f 82 f1 fe ff ff    	jb     f0101991 <__umoddi3+0x61>
f0101aa0:	e9 f8 fe ff ff       	jmp    f010199d <__umoddi3+0x6d>
