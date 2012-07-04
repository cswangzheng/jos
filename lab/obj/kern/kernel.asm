
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
f0100015:	b8 00 60 11 00       	mov    $0x116000,%eax
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
f0100034:	bc 00 60 11 f0       	mov    $0xf0116000,%esp

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
f0100046:	b8 ac 89 11 f0       	mov    $0xf01189ac,%eax
f010004b:	2d 04 83 11 f0       	sub    $0xf0118304,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 04 83 11 f0 	movl   $0xf0118304,(%esp)
f0100063:	e8 de 38 00 00       	call   f0103946 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 8e 04 00 00       	call   f01004fb <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 60 3e 10 f0 	movl   $0xf0103e60,(%esp)
f010007c:	e8 cd 2c 00 00       	call   f0102d4e <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 bc 11 00 00       	call   f0101242 <mem_init>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 b3 07 00 00       	call   f0100845 <monitor>
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
f010009f:	83 3d 20 83 11 f0 00 	cmpl   $0x0,0xf0118320
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 20 83 11 f0    	mov    %esi,0xf0118320

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
f01000c1:	c7 04 24 7b 3e 10 f0 	movl   $0xf0103e7b,(%esp)
f01000c8:	e8 81 2c 00 00       	call   f0102d4e <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 42 2c 00 00       	call   f0102d1b <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f01000e0:	e8 69 2c 00 00       	call   f0102d4e <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 54 07 00 00       	call   f0100845 <monitor>
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
f010010b:	c7 04 24 93 3e 10 f0 	movl   $0xf0103e93,(%esp)
f0100112:	e8 37 2c 00 00       	call   f0102d4e <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 f5 2b 00 00       	call   f0102d1b <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f010012d:	e8 1c 2c 00 00       	call   f0102d4e <cprintf>
	va_end(ap);
}
f0100132:	83 c4 14             	add    $0x14,%esp
f0100135:	5b                   	pop    %ebx
f0100136:	5d                   	pop    %ebp
f0100137:	c3                   	ret    
	...

f0100140 <delay>:
extern int char_color;

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
f0100179:	8b 15 64 85 11 f0    	mov    0xf0118564,%edx
f010017f:	88 82 60 83 11 f0    	mov    %al,-0xfee7ca0(%edx)
f0100185:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f0100188:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f010018d:	ba 00 00 00 00       	mov    $0x0,%edx
f0100192:	0f 44 c2             	cmove  %edx,%eax
f0100195:	a3 64 85 11 f0       	mov    %eax,0xf0118564
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
f01001b0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01001b3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001b8:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01001b9:	a8 20                	test   $0x20,%al
f01001bb:	75 1b                	jne    f01001d8 <cons_putc+0x31>
f01001bd:	bb 00 32 00 00       	mov    $0x3200,%ebx
f01001c2:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f01001c7:	e8 74 ff ff ff       	call   f0100140 <delay>
f01001cc:	89 f2                	mov    %esi,%edx
f01001ce:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01001cf:	a8 20                	test   $0x20,%al
f01001d1:	75 05                	jne    f01001d8 <cons_putc+0x31>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01001d3:	83 eb 01             	sub    $0x1,%ebx
f01001d6:	75 ef                	jne    f01001c7 <cons_putc+0x20>
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
f01001d8:	0f b6 7d e4          	movzbl -0x1c(%ebp),%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01001dc:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01001e1:	89 f8                	mov    %edi,%eax
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
f010020b:	89 f8                	mov    %edi,%eax
f010020d:	ee                   	out    %al,(%dx)
f010020e:	b2 7a                	mov    $0x7a,%dl
f0100210:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100215:	ee                   	out    %al,(%dx)
f0100216:	b8 08 00 00 00       	mov    $0x8,%eax
f010021b:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	c = c | (char_color<<8);
f010021c:	a1 00 83 11 f0       	mov    0xf0118300,%eax
f0100221:	c1 e0 08             	shl    $0x8,%eax
f0100224:	0b 45 e4             	or     -0x1c(%ebp),%eax
	
	if (!(c & ~0xFF)){
f0100227:	89 c1                	mov    %eax,%ecx
f0100229:	81 e1 00 ff ff ff    	and    $0xffffff00,%ecx
		c |= 0x0700;
f010022f:	89 c2                	mov    %eax,%edx
f0100231:	80 ce 07             	or     $0x7,%dh
f0100234:	85 c9                	test   %ecx,%ecx
f0100236:	0f 44 c2             	cmove  %edx,%eax
		}

	switch (c & 0xff) {
f0100239:	0f b6 d0             	movzbl %al,%edx
f010023c:	83 fa 09             	cmp    $0x9,%edx
f010023f:	74 75                	je     f01002b6 <cons_putc+0x10f>
f0100241:	83 fa 09             	cmp    $0x9,%edx
f0100244:	7f 0c                	jg     f0100252 <cons_putc+0xab>
f0100246:	83 fa 08             	cmp    $0x8,%edx
f0100249:	0f 85 9b 00 00 00    	jne    f01002ea <cons_putc+0x143>
f010024f:	90                   	nop
f0100250:	eb 10                	jmp    f0100262 <cons_putc+0xbb>
f0100252:	83 fa 0a             	cmp    $0xa,%edx
f0100255:	74 39                	je     f0100290 <cons_putc+0xe9>
f0100257:	83 fa 0d             	cmp    $0xd,%edx
f010025a:	0f 85 8a 00 00 00    	jne    f01002ea <cons_putc+0x143>
f0100260:	eb 36                	jmp    f0100298 <cons_putc+0xf1>
	case '\b':
		if (crt_pos > 0) {
f0100262:	0f b7 15 74 85 11 f0 	movzwl 0xf0118574,%edx
f0100269:	66 85 d2             	test   %dx,%dx
f010026c:	0f 84 e3 00 00 00    	je     f0100355 <cons_putc+0x1ae>
			crt_pos--;
f0100272:	83 ea 01             	sub    $0x1,%edx
f0100275:	66 89 15 74 85 11 f0 	mov    %dx,0xf0118574
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010027c:	0f b7 d2             	movzwl %dx,%edx
f010027f:	b0 00                	mov    $0x0,%al
f0100281:	83 c8 20             	or     $0x20,%eax
f0100284:	8b 0d 70 85 11 f0    	mov    0xf0118570,%ecx
f010028a:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f010028e:	eb 78                	jmp    f0100308 <cons_putc+0x161>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100290:	66 83 05 74 85 11 f0 	addw   $0x50,0xf0118574
f0100297:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100298:	0f b7 05 74 85 11 f0 	movzwl 0xf0118574,%eax
f010029f:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01002a5:	c1 e8 16             	shr    $0x16,%eax
f01002a8:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01002ab:	c1 e0 04             	shl    $0x4,%eax
f01002ae:	66 a3 74 85 11 f0    	mov    %ax,0xf0118574
f01002b4:	eb 52                	jmp    f0100308 <cons_putc+0x161>
		break;
	case '\t':
		cons_putc(' ');
f01002b6:	b8 20 00 00 00       	mov    $0x20,%eax
f01002bb:	e8 e7 fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002c0:	b8 20 00 00 00       	mov    $0x20,%eax
f01002c5:	e8 dd fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002ca:	b8 20 00 00 00       	mov    $0x20,%eax
f01002cf:	e8 d3 fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002d4:	b8 20 00 00 00       	mov    $0x20,%eax
f01002d9:	e8 c9 fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002de:	b8 20 00 00 00       	mov    $0x20,%eax
f01002e3:	e8 bf fe ff ff       	call   f01001a7 <cons_putc>
f01002e8:	eb 1e                	jmp    f0100308 <cons_putc+0x161>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01002ea:	0f b7 15 74 85 11 f0 	movzwl 0xf0118574,%edx
f01002f1:	0f b7 da             	movzwl %dx,%ebx
f01002f4:	8b 0d 70 85 11 f0    	mov    0xf0118570,%ecx
f01002fa:	66 89 04 59          	mov    %ax,(%ecx,%ebx,2)
f01002fe:	83 c2 01             	add    $0x1,%edx
f0100301:	66 89 15 74 85 11 f0 	mov    %dx,0xf0118574
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100308:	66 81 3d 74 85 11 f0 	cmpw   $0x7cf,0xf0118574
f010030f:	cf 07 
f0100311:	76 42                	jbe    f0100355 <cons_putc+0x1ae>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100313:	a1 70 85 11 f0       	mov    0xf0118570,%eax
f0100318:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010031f:	00 
f0100320:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100326:	89 54 24 04          	mov    %edx,0x4(%esp)
f010032a:	89 04 24             	mov    %eax,(%esp)
f010032d:	e8 6f 36 00 00       	call   f01039a1 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100332:	8b 15 70 85 11 f0    	mov    0xf0118570,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100338:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f010033d:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100343:	83 c0 01             	add    $0x1,%eax
f0100346:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f010034b:	75 f0                	jne    f010033d <cons_putc+0x196>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010034d:	66 83 2d 74 85 11 f0 	subw   $0x50,0xf0118574
f0100354:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100355:	8b 0d 6c 85 11 f0    	mov    0xf011856c,%ecx
f010035b:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100360:	89 ca                	mov    %ecx,%edx
f0100362:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100363:	0f b7 35 74 85 11 f0 	movzwl 0xf0118574,%esi
f010036a:	8d 59 01             	lea    0x1(%ecx),%ebx
f010036d:	89 f0                	mov    %esi,%eax
f010036f:	66 c1 e8 08          	shr    $0x8,%ax
f0100373:	89 da                	mov    %ebx,%edx
f0100375:	ee                   	out    %al,(%dx)
f0100376:	b8 0f 00 00 00       	mov    $0xf,%eax
f010037b:	89 ca                	mov    %ecx,%edx
f010037d:	ee                   	out    %al,(%dx)
f010037e:	89 f0                	mov    %esi,%eax
f0100380:	89 da                	mov    %ebx,%edx
f0100382:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100383:	83 c4 2c             	add    $0x2c,%esp
f0100386:	5b                   	pop    %ebx
f0100387:	5e                   	pop    %esi
f0100388:	5f                   	pop    %edi
f0100389:	5d                   	pop    %ebp
f010038a:	c3                   	ret    

f010038b <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010038b:	55                   	push   %ebp
f010038c:	89 e5                	mov    %esp,%ebp
f010038e:	53                   	push   %ebx
f010038f:	83 ec 14             	sub    $0x14,%esp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100392:	ba 64 00 00 00       	mov    $0x64,%edx
f0100397:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f0100398:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f010039d:	a8 01                	test   $0x1,%al
f010039f:	0f 84 de 00 00 00    	je     f0100483 <kbd_proc_data+0xf8>
f01003a5:	b2 60                	mov    $0x60,%dl
f01003a7:	ec                   	in     (%dx),%al
f01003a8:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01003aa:	3c e0                	cmp    $0xe0,%al
f01003ac:	75 11                	jne    f01003bf <kbd_proc_data+0x34>
		// E0 escape character
		shift |= E0ESC;
f01003ae:	83 0d 68 85 11 f0 40 	orl    $0x40,0xf0118568
		return 0;
f01003b5:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003ba:	e9 c4 00 00 00       	jmp    f0100483 <kbd_proc_data+0xf8>
	} else if (data & 0x80) {
f01003bf:	84 c0                	test   %al,%al
f01003c1:	79 37                	jns    f01003fa <kbd_proc_data+0x6f>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003c3:	8b 0d 68 85 11 f0    	mov    0xf0118568,%ecx
f01003c9:	89 cb                	mov    %ecx,%ebx
f01003cb:	83 e3 40             	and    $0x40,%ebx
f01003ce:	83 e0 7f             	and    $0x7f,%eax
f01003d1:	85 db                	test   %ebx,%ebx
f01003d3:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01003d6:	0f b6 d2             	movzbl %dl,%edx
f01003d9:	0f b6 82 e0 3e 10 f0 	movzbl -0xfefc120(%edx),%eax
f01003e0:	83 c8 40             	or     $0x40,%eax
f01003e3:	0f b6 c0             	movzbl %al,%eax
f01003e6:	f7 d0                	not    %eax
f01003e8:	21 c1                	and    %eax,%ecx
f01003ea:	89 0d 68 85 11 f0    	mov    %ecx,0xf0118568
		return 0;
f01003f0:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003f5:	e9 89 00 00 00       	jmp    f0100483 <kbd_proc_data+0xf8>
	} else if (shift & E0ESC) {
f01003fa:	8b 0d 68 85 11 f0    	mov    0xf0118568,%ecx
f0100400:	f6 c1 40             	test   $0x40,%cl
f0100403:	74 0e                	je     f0100413 <kbd_proc_data+0x88>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100405:	89 c2                	mov    %eax,%edx
f0100407:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f010040a:	83 e1 bf             	and    $0xffffffbf,%ecx
f010040d:	89 0d 68 85 11 f0    	mov    %ecx,0xf0118568
	}

	shift |= shiftcode[data];
f0100413:	0f b6 d2             	movzbl %dl,%edx
f0100416:	0f b6 82 e0 3e 10 f0 	movzbl -0xfefc120(%edx),%eax
f010041d:	0b 05 68 85 11 f0    	or     0xf0118568,%eax
	shift ^= togglecode[data];
f0100423:	0f b6 8a e0 3f 10 f0 	movzbl -0xfefc020(%edx),%ecx
f010042a:	31 c8                	xor    %ecx,%eax
f010042c:	a3 68 85 11 f0       	mov    %eax,0xf0118568

	c = charcode[shift & (CTL | SHIFT)][data];
f0100431:	89 c1                	mov    %eax,%ecx
f0100433:	83 e1 03             	and    $0x3,%ecx
f0100436:	8b 0c 8d e0 40 10 f0 	mov    -0xfefbf20(,%ecx,4),%ecx
f010043d:	0f b6 1c 11          	movzbl (%ecx,%edx,1),%ebx
	if (shift & CAPSLOCK) {
f0100441:	a8 08                	test   $0x8,%al
f0100443:	74 19                	je     f010045e <kbd_proc_data+0xd3>
		if ('a' <= c && c <= 'z')
f0100445:	8d 53 9f             	lea    -0x61(%ebx),%edx
f0100448:	83 fa 19             	cmp    $0x19,%edx
f010044b:	77 05                	ja     f0100452 <kbd_proc_data+0xc7>
			c += 'A' - 'a';
f010044d:	83 eb 20             	sub    $0x20,%ebx
f0100450:	eb 0c                	jmp    f010045e <kbd_proc_data+0xd3>
		else if ('A' <= c && c <= 'Z')
f0100452:	8d 4b bf             	lea    -0x41(%ebx),%ecx
			c += 'a' - 'A';
f0100455:	8d 53 20             	lea    0x20(%ebx),%edx
f0100458:	83 f9 19             	cmp    $0x19,%ecx
f010045b:	0f 46 da             	cmovbe %edx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010045e:	f7 d0                	not    %eax
f0100460:	a8 06                	test   $0x6,%al
f0100462:	75 1f                	jne    f0100483 <kbd_proc_data+0xf8>
f0100464:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010046a:	75 17                	jne    f0100483 <kbd_proc_data+0xf8>
		cprintf("Rebooting!\n");
f010046c:	c7 04 24 ad 3e 10 f0 	movl   $0xf0103ead,(%esp)
f0100473:	e8 d6 28 00 00       	call   f0102d4e <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100478:	ba 92 00 00 00       	mov    $0x92,%edx
f010047d:	b8 03 00 00 00       	mov    $0x3,%eax
f0100482:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100483:	89 d8                	mov    %ebx,%eax
f0100485:	83 c4 14             	add    $0x14,%esp
f0100488:	5b                   	pop    %ebx
f0100489:	5d                   	pop    %ebp
f010048a:	c3                   	ret    

f010048b <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010048b:	55                   	push   %ebp
f010048c:	89 e5                	mov    %esp,%ebp
f010048e:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f0100491:	83 3d 40 83 11 f0 00 	cmpl   $0x0,0xf0118340
f0100498:	74 0a                	je     f01004a4 <serial_intr+0x19>
		cons_intr(serial_proc_data);
f010049a:	b8 4e 01 10 f0       	mov    $0xf010014e,%eax
f010049f:	e8 c6 fc ff ff       	call   f010016a <cons_intr>
}
f01004a4:	c9                   	leave  
f01004a5:	c3                   	ret    

f01004a6 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004a6:	55                   	push   %ebp
f01004a7:	89 e5                	mov    %esp,%ebp
f01004a9:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004ac:	b8 8b 03 10 f0       	mov    $0xf010038b,%eax
f01004b1:	e8 b4 fc ff ff       	call   f010016a <cons_intr>
}
f01004b6:	c9                   	leave  
f01004b7:	c3                   	ret    

f01004b8 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004b8:	55                   	push   %ebp
f01004b9:	89 e5                	mov    %esp,%ebp
f01004bb:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004be:	e8 c8 ff ff ff       	call   f010048b <serial_intr>
	kbd_intr();
f01004c3:	e8 de ff ff ff       	call   f01004a6 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004c8:	8b 15 60 85 11 f0    	mov    0xf0118560,%edx
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f01004ce:	b8 00 00 00 00       	mov    $0x0,%eax
	// (e.g., when called from the kernel monitor).
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004d3:	3b 15 64 85 11 f0    	cmp    0xf0118564,%edx
f01004d9:	74 1e                	je     f01004f9 <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f01004db:	0f b6 82 60 83 11 f0 	movzbl -0xfee7ca0(%edx),%eax
f01004e2:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f01004e5:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004eb:	b9 00 00 00 00       	mov    $0x0,%ecx
f01004f0:	0f 44 d1             	cmove  %ecx,%edx
f01004f3:	89 15 60 85 11 f0    	mov    %edx,0xf0118560
		return c;
	}
	return 0;
}
f01004f9:	c9                   	leave  
f01004fa:	c3                   	ret    

f01004fb <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004fb:	55                   	push   %ebp
f01004fc:	89 e5                	mov    %esp,%ebp
f01004fe:	57                   	push   %edi
f01004ff:	56                   	push   %esi
f0100500:	53                   	push   %ebx
f0100501:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100504:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010050b:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100512:	5a a5 
	if (*cp != 0xA55A) {
f0100514:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010051b:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010051f:	74 11                	je     f0100532 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100521:	c7 05 6c 85 11 f0 b4 	movl   $0x3b4,0xf011856c
f0100528:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010052b:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100530:	eb 16                	jmp    f0100548 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100532:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100539:	c7 05 6c 85 11 f0 d4 	movl   $0x3d4,0xf011856c
f0100540:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100543:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f0100548:	8b 0d 6c 85 11 f0    	mov    0xf011856c,%ecx
f010054e:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100553:	89 ca                	mov    %ecx,%edx
f0100555:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100556:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100559:	89 da                	mov    %ebx,%edx
f010055b:	ec                   	in     (%dx),%al
f010055c:	0f b6 f8             	movzbl %al,%edi
f010055f:	c1 e7 08             	shl    $0x8,%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100562:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100567:	89 ca                	mov    %ecx,%edx
f0100569:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056a:	89 da                	mov    %ebx,%edx
f010056c:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010056d:	89 35 70 85 11 f0    	mov    %esi,0xf0118570
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100573:	0f b6 d8             	movzbl %al,%ebx
f0100576:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100578:	66 89 3d 74 85 11 f0 	mov    %di,0xf0118574
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010057f:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f0100584:	b8 00 00 00 00       	mov    $0x0,%eax
f0100589:	89 da                	mov    %ebx,%edx
f010058b:	ee                   	out    %al,(%dx)
f010058c:	b2 fb                	mov    $0xfb,%dl
f010058e:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100593:	ee                   	out    %al,(%dx)
f0100594:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f0100599:	b8 0c 00 00 00       	mov    $0xc,%eax
f010059e:	89 ca                	mov    %ecx,%edx
f01005a0:	ee                   	out    %al,(%dx)
f01005a1:	b2 f9                	mov    $0xf9,%dl
f01005a3:	b8 00 00 00 00       	mov    $0x0,%eax
f01005a8:	ee                   	out    %al,(%dx)
f01005a9:	b2 fb                	mov    $0xfb,%dl
f01005ab:	b8 03 00 00 00       	mov    $0x3,%eax
f01005b0:	ee                   	out    %al,(%dx)
f01005b1:	b2 fc                	mov    $0xfc,%dl
f01005b3:	b8 00 00 00 00       	mov    $0x0,%eax
f01005b8:	ee                   	out    %al,(%dx)
f01005b9:	b2 f9                	mov    $0xf9,%dl
f01005bb:	b8 01 00 00 00       	mov    $0x1,%eax
f01005c0:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005c1:	b2 fd                	mov    $0xfd,%dl
f01005c3:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005c4:	3c ff                	cmp    $0xff,%al
f01005c6:	0f 95 c0             	setne  %al
f01005c9:	0f b6 c0             	movzbl %al,%eax
f01005cc:	89 c6                	mov    %eax,%esi
f01005ce:	a3 40 83 11 f0       	mov    %eax,0xf0118340
f01005d3:	89 da                	mov    %ebx,%edx
f01005d5:	ec                   	in     (%dx),%al
f01005d6:	89 ca                	mov    %ecx,%edx
f01005d8:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005d9:	85 f6                	test   %esi,%esi
f01005db:	75 0c                	jne    f01005e9 <cons_init+0xee>
		cprintf("Serial port does not exist!\n");
f01005dd:	c7 04 24 b9 3e 10 f0 	movl   $0xf0103eb9,(%esp)
f01005e4:	e8 65 27 00 00       	call   f0102d4e <cprintf>
}
f01005e9:	83 c4 1c             	add    $0x1c,%esp
f01005ec:	5b                   	pop    %ebx
f01005ed:	5e                   	pop    %esi
f01005ee:	5f                   	pop    %edi
f01005ef:	5d                   	pop    %ebp
f01005f0:	c3                   	ret    

f01005f1 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01005f1:	55                   	push   %ebp
f01005f2:	89 e5                	mov    %esp,%ebp
f01005f4:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01005f7:	8b 45 08             	mov    0x8(%ebp),%eax
f01005fa:	e8 a8 fb ff ff       	call   f01001a7 <cons_putc>
}
f01005ff:	c9                   	leave  
f0100600:	c3                   	ret    

f0100601 <getchar>:

int
getchar(void)
{
f0100601:	55                   	push   %ebp
f0100602:	89 e5                	mov    %esp,%ebp
f0100604:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100607:	e8 ac fe ff ff       	call   f01004b8 <cons_getc>
f010060c:	85 c0                	test   %eax,%eax
f010060e:	74 f7                	je     f0100607 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100610:	c9                   	leave  
f0100611:	c3                   	ret    

f0100612 <iscons>:

int
iscons(int fdnum)
{
f0100612:	55                   	push   %ebp
f0100613:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100615:	b8 01 00 00 00       	mov    $0x1,%eax
f010061a:	5d                   	pop    %ebp
f010061b:	c3                   	ret    
f010061c:	00 00                	add    %al,(%eax)
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
f0100626:	c7 04 24 f0 40 10 f0 	movl   $0xf01040f0,(%esp)
f010062d:	e8 1c 27 00 00       	call   f0102d4e <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100632:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100639:	00 
f010063a:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100641:	f0 
f0100642:	c7 04 24 b4 41 10 f0 	movl   $0xf01041b4,(%esp)
f0100649:	e8 00 27 00 00       	call   f0102d4e <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010064e:	c7 44 24 08 45 3e 10 	movl   $0x103e45,0x8(%esp)
f0100655:	00 
f0100656:	c7 44 24 04 45 3e 10 	movl   $0xf0103e45,0x4(%esp)
f010065d:	f0 
f010065e:	c7 04 24 d8 41 10 f0 	movl   $0xf01041d8,(%esp)
f0100665:	e8 e4 26 00 00       	call   f0102d4e <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010066a:	c7 44 24 08 04 83 11 	movl   $0x118304,0x8(%esp)
f0100671:	00 
f0100672:	c7 44 24 04 04 83 11 	movl   $0xf0118304,0x4(%esp)
f0100679:	f0 
f010067a:	c7 04 24 fc 41 10 f0 	movl   $0xf01041fc,(%esp)
f0100681:	e8 c8 26 00 00       	call   f0102d4e <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100686:	c7 44 24 08 ac 89 11 	movl   $0x1189ac,0x8(%esp)
f010068d:	00 
f010068e:	c7 44 24 04 ac 89 11 	movl   $0xf01189ac,0x4(%esp)
f0100695:	f0 
f0100696:	c7 04 24 20 42 10 f0 	movl   $0xf0104220,(%esp)
f010069d:	e8 ac 26 00 00       	call   f0102d4e <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
f01006a2:	b8 ab 8d 11 f0       	mov    $0xf0118dab,%eax
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
f01006be:	c7 04 24 44 42 10 f0 	movl   $0xf0104244,(%esp)
f01006c5:	e8 84 26 00 00       	call   f0102d4e <cprintf>
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
f01006d4:	53                   	push   %ebx
f01006d5:	83 ec 14             	sub    $0x14,%esp
f01006d8:	bb 00 00 00 00       	mov    $0x0,%ebx
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006dd:	8b 83 44 43 10 f0    	mov    -0xfefbcbc(%ebx),%eax
f01006e3:	89 44 24 08          	mov    %eax,0x8(%esp)
f01006e7:	8b 83 40 43 10 f0    	mov    -0xfefbcc0(%ebx),%eax
f01006ed:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006f1:	c7 04 24 09 41 10 f0 	movl   $0xf0104109,(%esp)
f01006f8:	e8 51 26 00 00       	call   f0102d4e <cprintf>
f01006fd:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f0100700:	83 fb 24             	cmp    $0x24,%ebx
f0100703:	75 d8                	jne    f01006dd <mon_help+0xc>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f0100705:	b8 00 00 00 00       	mov    $0x0,%eax
f010070a:	83 c4 14             	add    $0x14,%esp
f010070d:	5b                   	pop    %ebx
f010070e:	5d                   	pop    %ebp
f010070f:	c3                   	ret    

f0100710 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100710:	55                   	push   %ebp
f0100711:	89 e5                	mov    %esp,%ebp
f0100713:	57                   	push   %edi
f0100714:	56                   	push   %esi
f0100715:	53                   	push   %ebx
f0100716:	81 ec 8c 00 00 00    	sub    $0x8c,%esp

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f010071c:	89 eb                	mov    %ebp,%ebx
f010071e:	89 de                	mov    %ebx,%esi
	// Your code here.
	uint32_t ebp,eip,arg[5];
	ebp = read_ebp();
	eip = *((uint32_t*)ebp+1);
f0100720:	8b 7b 04             	mov    0x4(%ebx),%edi
	arg[0] = *((uint32_t*)ebp+2);
f0100723:	8b 43 08             	mov    0x8(%ebx),%eax
f0100726:	89 45 a4             	mov    %eax,-0x5c(%ebp)
	arg[1] = *((uint32_t*)ebp+3);
f0100729:	8b 43 0c             	mov    0xc(%ebx),%eax
f010072c:	89 45 a0             	mov    %eax,-0x60(%ebp)
	arg[2] = *((uint32_t*)ebp+4);
f010072f:	8b 43 10             	mov    0x10(%ebx),%eax
f0100732:	89 45 9c             	mov    %eax,-0x64(%ebp)
	arg[3] = *((uint32_t*)ebp+5);
f0100735:	8b 43 14             	mov    0x14(%ebx),%eax
f0100738:	89 45 98             	mov    %eax,-0x68(%ebp)
	arg[4] = *((uint32_t*)ebp+6);
f010073b:	8b 43 18             	mov    0x18(%ebx),%eax
f010073e:	89 45 94             	mov    %eax,-0x6c(%ebp)

	cprintf("Stack backtrace:\n");
f0100741:	c7 04 24 12 41 10 f0 	movl   $0xf0104112,(%esp)
f0100748:	e8 01 26 00 00       	call   f0102d4e <cprintf>
	
	while(ebp != 0x00)
f010074d:	85 db                	test   %ebx,%ebx
f010074f:	0f 84 e0 00 00 00    	je     f0100835 <mon_backtrace+0x125>
			info.eip_fn_name = "<unknown>";
			info.eip_fn_namelen = 9;
			info.eip_fn_addr = eip;
			info.eip_fn_narg = 0;
			char display_eip_fn_name[30];
			debuginfo_eip(eip,&info);
f0100755:	8d 5d d0             	lea    -0x30(%ebp),%ebx
f0100758:	8b 45 9c             	mov    -0x64(%ebp),%eax
f010075b:	8b 55 98             	mov    -0x68(%ebp),%edx
f010075e:	8b 4d 94             	mov    -0x6c(%ebp),%ecx
	cprintf("Stack backtrace:\n");
	
	while(ebp != 0x00)
		{
			
			cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",ebp,eip,arg[0],arg[1],arg[2],arg[3],arg[4]);
f0100761:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0100765:	89 54 24 18          	mov    %edx,0x18(%esp)
f0100769:	89 44 24 14          	mov    %eax,0x14(%esp)
f010076d:	8b 45 a0             	mov    -0x60(%ebp),%eax
f0100770:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100774:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100777:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010077b:	89 7c 24 08          	mov    %edi,0x8(%esp)
f010077f:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100783:	c7 04 24 70 42 10 f0 	movl   $0xf0104270,(%esp)
f010078a:	e8 bf 25 00 00       	call   f0102d4e <cprintf>
			struct Eipdebuginfo info;
			info.eip_file = "<unknown>";
f010078f:	c7 45 d0 24 41 10 f0 	movl   $0xf0104124,-0x30(%ebp)
			info.eip_line = 0;
f0100796:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
			info.eip_fn_name = "<unknown>";
f010079d:	c7 45 d8 24 41 10 f0 	movl   $0xf0104124,-0x28(%ebp)
			info.eip_fn_namelen = 9;
f01007a4:	c7 45 dc 09 00 00 00 	movl   $0x9,-0x24(%ebp)
			info.eip_fn_addr = eip;
f01007ab:	89 7d e0             	mov    %edi,-0x20(%ebp)
			info.eip_fn_narg = 0;
f01007ae:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
			char display_eip_fn_name[30];
			debuginfo_eip(eip,&info);
f01007b5:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01007b9:	89 3c 24             	mov    %edi,(%esp)
f01007bc:	e8 87 26 00 00       	call   f0102e48 <debuginfo_eip>
			int i;
			for ( i=0;(info.eip_fn_name[i]!=':')&&( i<30); i++)
f01007c1:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f01007c4:	0f b6 11             	movzbl (%ecx),%edx
f01007c7:	b8 00 00 00 00       	mov    $0x0,%eax
f01007cc:	80 fa 3a             	cmp    $0x3a,%dl
f01007cf:	74 15                	je     f01007e6 <mon_backtrace+0xd6>
				display_eip_fn_name[i]=info.eip_fn_name[i];
f01007d1:	88 54 05 b2          	mov    %dl,-0x4e(%ebp,%eax,1)
			info.eip_fn_addr = eip;
			info.eip_fn_narg = 0;
			char display_eip_fn_name[30];
			debuginfo_eip(eip,&info);
			int i;
			for ( i=0;(info.eip_fn_name[i]!=':')&&( i<30); i++)
f01007d5:	83 c0 01             	add    $0x1,%eax
f01007d8:	0f b6 14 01          	movzbl (%ecx,%eax,1),%edx
f01007dc:	80 fa 3a             	cmp    $0x3a,%dl
f01007df:	74 05                	je     f01007e6 <mon_backtrace+0xd6>
f01007e1:	83 f8 1d             	cmp    $0x1d,%eax
f01007e4:	7e eb                	jle    f01007d1 <mon_backtrace+0xc1>
				display_eip_fn_name[i]=info.eip_fn_name[i];
			display_eip_fn_name[i]='\0';
f01007e6:	c6 44 05 b2 00       	movb   $0x0,-0x4e(%ebp,%eax,1)
			cprintf("    %s:%d: %s+%d\n",info.eip_file,info.eip_line,display_eip_fn_name,(eip-info.eip_fn_addr));
f01007eb:	2b 7d e0             	sub    -0x20(%ebp),%edi
f01007ee:	89 7c 24 10          	mov    %edi,0x10(%esp)
f01007f2:	8d 45 b2             	lea    -0x4e(%ebp),%eax
f01007f5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007f9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01007fc:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100800:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100803:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100807:	c7 04 24 2e 41 10 f0 	movl   $0xf010412e,(%esp)
f010080e:	e8 3b 25 00 00       	call   f0102d4e <cprintf>
			ebp = *(uint32_t *)ebp;
f0100813:	8b 36                	mov    (%esi),%esi
			eip = *((uint32_t*)ebp+1);
f0100815:	8b 7e 04             	mov    0x4(%esi),%edi
			arg[0] = *((uint32_t*)ebp+2);
f0100818:	8b 46 08             	mov    0x8(%esi),%eax
f010081b:	89 45 a4             	mov    %eax,-0x5c(%ebp)
			arg[1] = *((uint32_t*)ebp+3);
f010081e:	8b 46 0c             	mov    0xc(%esi),%eax
f0100821:	89 45 a0             	mov    %eax,-0x60(%ebp)
			arg[2] = *((uint32_t*)ebp+4);
f0100824:	8b 46 10             	mov    0x10(%esi),%eax
			arg[3] = *((uint32_t*)ebp+5);
f0100827:	8b 56 14             	mov    0x14(%esi),%edx
			arg[4] = *((uint32_t*)ebp+6);
f010082a:	8b 4e 18             	mov    0x18(%esi),%ecx
	arg[3] = *((uint32_t*)ebp+5);
	arg[4] = *((uint32_t*)ebp+6);

	cprintf("Stack backtrace:\n");
	
	while(ebp != 0x00)
f010082d:	85 f6                	test   %esi,%esi
f010082f:	0f 85 2c ff ff ff    	jne    f0100761 <mon_backtrace+0x51>
			arg[3] = *((uint32_t*)ebp+5);
			arg[4] = *((uint32_t*)ebp+6);
			
		}
	return 0;
}
f0100835:	b8 00 00 00 00       	mov    $0x0,%eax
f010083a:	81 c4 8c 00 00 00    	add    $0x8c,%esp
f0100840:	5b                   	pop    %ebx
f0100841:	5e                   	pop    %esi
f0100842:	5f                   	pop    %edi
f0100843:	5d                   	pop    %ebp
f0100844:	c3                   	ret    

f0100845 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100845:	55                   	push   %ebp
f0100846:	89 e5                	mov    %esp,%ebp
f0100848:	57                   	push   %edi
f0100849:	56                   	push   %esi
f010084a:	53                   	push   %ebx
f010084b:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010084e:	c7 04 24 a4 42 10 f0 	movl   $0xf01042a4,(%esp)
f0100855:	e8 f4 24 00 00       	call   f0102d4e <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010085a:	c7 04 24 c8 42 10 f0 	movl   $0xf01042c8,(%esp)
f0100861:	e8 e8 24 00 00       	call   f0102d4e <cprintf>


	while (1) {
		buf = readline("K> ");
f0100866:	c7 04 24 40 41 10 f0 	movl   $0xf0104140,(%esp)
f010086d:	e8 4e 2e 00 00       	call   f01036c0 <readline>
f0100872:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100874:	85 c0                	test   %eax,%eax
f0100876:	74 ee                	je     f0100866 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100878:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010087f:	be 00 00 00 00       	mov    $0x0,%esi
f0100884:	eb 06                	jmp    f010088c <monitor+0x47>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100886:	c6 03 00             	movb   $0x0,(%ebx)
f0100889:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010088c:	0f b6 03             	movzbl (%ebx),%eax
f010088f:	84 c0                	test   %al,%al
f0100891:	74 6a                	je     f01008fd <monitor+0xb8>
f0100893:	0f be c0             	movsbl %al,%eax
f0100896:	89 44 24 04          	mov    %eax,0x4(%esp)
f010089a:	c7 04 24 44 41 10 f0 	movl   $0xf0104144,(%esp)
f01008a1:	e8 45 30 00 00       	call   f01038eb <strchr>
f01008a6:	85 c0                	test   %eax,%eax
f01008a8:	75 dc                	jne    f0100886 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f01008aa:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008ad:	74 4e                	je     f01008fd <monitor+0xb8>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008af:	83 fe 0f             	cmp    $0xf,%esi
f01008b2:	75 16                	jne    f01008ca <monitor+0x85>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008b4:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01008bb:	00 
f01008bc:	c7 04 24 49 41 10 f0 	movl   $0xf0104149,(%esp)
f01008c3:	e8 86 24 00 00       	call   f0102d4e <cprintf>
f01008c8:	eb 9c                	jmp    f0100866 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f01008ca:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008ce:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f01008d1:	0f b6 03             	movzbl (%ebx),%eax
f01008d4:	84 c0                	test   %al,%al
f01008d6:	75 0c                	jne    f01008e4 <monitor+0x9f>
f01008d8:	eb b2                	jmp    f010088c <monitor+0x47>
			buf++;
f01008da:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008dd:	0f b6 03             	movzbl (%ebx),%eax
f01008e0:	84 c0                	test   %al,%al
f01008e2:	74 a8                	je     f010088c <monitor+0x47>
f01008e4:	0f be c0             	movsbl %al,%eax
f01008e7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008eb:	c7 04 24 44 41 10 f0 	movl   $0xf0104144,(%esp)
f01008f2:	e8 f4 2f 00 00       	call   f01038eb <strchr>
f01008f7:	85 c0                	test   %eax,%eax
f01008f9:	74 df                	je     f01008da <monitor+0x95>
f01008fb:	eb 8f                	jmp    f010088c <monitor+0x47>
			buf++;
	}
	argv[argc] = 0;
f01008fd:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100904:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100905:	85 f6                	test   %esi,%esi
f0100907:	0f 84 59 ff ff ff    	je     f0100866 <monitor+0x21>
f010090d:	bb 40 43 10 f0       	mov    $0xf0104340,%ebx
f0100912:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100917:	8b 03                	mov    (%ebx),%eax
f0100919:	89 44 24 04          	mov    %eax,0x4(%esp)
f010091d:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100920:	89 04 24             	mov    %eax,(%esp)
f0100923:	e8 48 2f 00 00       	call   f0103870 <strcmp>
f0100928:	85 c0                	test   %eax,%eax
f010092a:	75 24                	jne    f0100950 <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f010092c:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f010092f:	8b 55 08             	mov    0x8(%ebp),%edx
f0100932:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100936:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100939:	89 54 24 04          	mov    %edx,0x4(%esp)
f010093d:	89 34 24             	mov    %esi,(%esp)
f0100940:	ff 14 85 48 43 10 f0 	call   *-0xfefbcb8(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100947:	85 c0                	test   %eax,%eax
f0100949:	78 28                	js     f0100973 <monitor+0x12e>
f010094b:	e9 16 ff ff ff       	jmp    f0100866 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100950:	83 c7 01             	add    $0x1,%edi
f0100953:	83 c3 0c             	add    $0xc,%ebx
f0100956:	83 ff 03             	cmp    $0x3,%edi
f0100959:	75 bc                	jne    f0100917 <monitor+0xd2>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f010095b:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010095e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100962:	c7 04 24 66 41 10 f0 	movl   $0xf0104166,(%esp)
f0100969:	e8 e0 23 00 00       	call   f0102d4e <cprintf>
f010096e:	e9 f3 fe ff ff       	jmp    f0100866 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100973:	83 c4 5c             	add    $0x5c,%esp
f0100976:	5b                   	pop    %ebx
f0100977:	5e                   	pop    %esi
f0100978:	5f                   	pop    %edi
f0100979:	5d                   	pop    %ebp
f010097a:	c3                   	ret    

f010097b <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f010097b:	55                   	push   %ebp
f010097c:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f010097e:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f0100981:	5d                   	pop    %ebp
f0100982:	c3                   	ret    
	...

f0100984 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100984:	55                   	push   %ebp
f0100985:	89 e5                	mov    %esp,%ebp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100987:	83 3d 7c 85 11 f0 00 	cmpl   $0x0,0xf011857c
f010098e:	75 11                	jne    f01009a1 <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100990:	ba ab 99 11 f0       	mov    $0xf01199ab,%edx
f0100995:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010099b:	89 15 7c 85 11 f0    	mov    %edx,0xf011857c
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = ROUNDUP(nextfree, PGSIZE);
f01009a1:	8b 15 7c 85 11 f0    	mov    0xf011857c,%edx
f01009a7:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f01009ad:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	nextfree = result + n;
f01009b3:	01 d0                	add    %edx,%eax
f01009b5:	a3 7c 85 11 f0       	mov    %eax,0xf011857c
	//cprintf("\nnextfree:0x%08x",nextfree);
	return result;
}
f01009ba:	89 d0                	mov    %edx,%eax
f01009bc:	5d                   	pop    %ebp
f01009bd:	c3                   	ret    

f01009be <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f01009be:	55                   	push   %ebp
f01009bf:	89 e5                	mov    %esp,%ebp
f01009c1:	83 ec 18             	sub    $0x18,%esp
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f01009c4:	89 d1                	mov    %edx,%ecx
f01009c6:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f01009c9:	8b 0c 88             	mov    (%eax,%ecx,4),%ecx
		return ~0;
f01009cc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f01009d1:	f6 c1 01             	test   $0x1,%cl
f01009d4:	74 57                	je     f0100a2d <check_va2pa+0x6f>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f01009d6:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01009dc:	89 c8                	mov    %ecx,%eax
f01009de:	c1 e8 0c             	shr    $0xc,%eax
f01009e1:	3b 05 a0 89 11 f0    	cmp    0xf01189a0,%eax
f01009e7:	72 20                	jb     f0100a09 <check_va2pa+0x4b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01009e9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01009ed:	c7 44 24 08 64 43 10 	movl   $0xf0104364,0x8(%esp)
f01009f4:	f0 
f01009f5:	c7 44 24 04 f9 02 00 	movl   $0x2f9,0x4(%esp)
f01009fc:	00 
f01009fd:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0100a04:	e8 8b f6 ff ff       	call   f0100094 <_panic>
	if (!(p[PTX(va)] & PTE_P))
f0100a09:	c1 ea 0c             	shr    $0xc,%edx
f0100a0c:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100a12:	8b 84 91 00 00 00 f0 	mov    -0x10000000(%ecx,%edx,4),%eax
f0100a19:	89 c2                	mov    %eax,%edx
f0100a1b:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100a1e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a23:	85 d2                	test   %edx,%edx
f0100a25:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100a2a:	0f 44 c2             	cmove  %edx,%eax
}
f0100a2d:	c9                   	leave  
f0100a2e:	c3                   	ret    

f0100a2f <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100a2f:	55                   	push   %ebp
f0100a30:	89 e5                	mov    %esp,%ebp
f0100a32:	83 ec 18             	sub    $0x18,%esp
f0100a35:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0100a38:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0100a3b:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a3d:	89 04 24             	mov    %eax,(%esp)
f0100a40:	e8 9b 22 00 00       	call   f0102ce0 <mc146818_read>
f0100a45:	89 c6                	mov    %eax,%esi
f0100a47:	83 c3 01             	add    $0x1,%ebx
f0100a4a:	89 1c 24             	mov    %ebx,(%esp)
f0100a4d:	e8 8e 22 00 00       	call   f0102ce0 <mc146818_read>
f0100a52:	c1 e0 08             	shl    $0x8,%eax
f0100a55:	09 f0                	or     %esi,%eax
}
f0100a57:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0100a5a:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0100a5d:	89 ec                	mov    %ebp,%esp
f0100a5f:	5d                   	pop    %ebp
f0100a60:	c3                   	ret    

f0100a61 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a61:	55                   	push   %ebp
f0100a62:	89 e5                	mov    %esp,%ebp
f0100a64:	57                   	push   %edi
f0100a65:	56                   	push   %esi
f0100a66:	53                   	push   %ebx
f0100a67:	83 ec 3c             	sub    $0x3c,%esp
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a6a:	83 f8 01             	cmp    $0x1,%eax
f0100a6d:	19 f6                	sbb    %esi,%esi
f0100a6f:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
f0100a75:	83 c6 01             	add    $0x1,%esi
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100a78:	8b 1d 80 85 11 f0    	mov    0xf0118580,%ebx
f0100a7e:	85 db                	test   %ebx,%ebx
f0100a80:	75 1c                	jne    f0100a9e <check_page_free_list+0x3d>
		panic("'page_free_list' is a null pointer!");
f0100a82:	c7 44 24 08 88 43 10 	movl   $0xf0104388,0x8(%esp)
f0100a89:	f0 
f0100a8a:	c7 44 24 04 3c 02 00 	movl   $0x23c,0x4(%esp)
f0100a91:	00 
f0100a92:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0100a99:	e8 f6 f5 ff ff       	call   f0100094 <_panic>

	if (only_low_memory) {
f0100a9e:	85 c0                	test   %eax,%eax
f0100aa0:	74 50                	je     f0100af2 <check_page_free_list+0x91>
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
f0100aa2:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0100aa5:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100aa8:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100aab:	89 45 dc             	mov    %eax,-0x24(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100aae:	89 d8                	mov    %ebx,%eax
f0100ab0:	2b 05 a8 89 11 f0    	sub    0xf01189a8,%eax
f0100ab6:	c1 e0 09             	shl    $0x9,%eax
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100ab9:	c1 e8 16             	shr    $0x16,%eax
f0100abc:	39 f0                	cmp    %esi,%eax
f0100abe:	0f 93 c0             	setae  %al
f0100ac1:	0f b6 c0             	movzbl %al,%eax
			*tp[pagetype] = pp;
f0100ac4:	8b 54 85 d8          	mov    -0x28(%ebp,%eax,4),%edx
f0100ac8:	89 1a                	mov    %ebx,(%edx)
			tp[pagetype] = &pp->pp_link;
f0100aca:	89 5c 85 d8          	mov    %ebx,-0x28(%ebp,%eax,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ace:	8b 1b                	mov    (%ebx),%ebx
f0100ad0:	85 db                	test   %ebx,%ebx
f0100ad2:	75 da                	jne    f0100aae <check_page_free_list+0x4d>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100ad4:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100ad7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100add:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ae0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100ae3:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100ae5:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100ae8:	89 1d 80 85 11 f0    	mov    %ebx,0xf0118580
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100aee:	85 db                	test   %ebx,%ebx
f0100af0:	74 67                	je     f0100b59 <check_page_free_list+0xf8>
f0100af2:	89 d8                	mov    %ebx,%eax
f0100af4:	2b 05 a8 89 11 f0    	sub    0xf01189a8,%eax
f0100afa:	c1 f8 03             	sar    $0x3,%eax
f0100afd:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100b00:	89 c2                	mov    %eax,%edx
f0100b02:	c1 ea 16             	shr    $0x16,%edx
f0100b05:	39 f2                	cmp    %esi,%edx
f0100b07:	73 4a                	jae    f0100b53 <check_page_free_list+0xf2>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b09:	89 c2                	mov    %eax,%edx
f0100b0b:	c1 ea 0c             	shr    $0xc,%edx
f0100b0e:	3b 15 a0 89 11 f0    	cmp    0xf01189a0,%edx
f0100b14:	72 20                	jb     f0100b36 <check_page_free_list+0xd5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b16:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b1a:	c7 44 24 08 64 43 10 	movl   $0xf0104364,0x8(%esp)
f0100b21:	f0 
f0100b22:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100b29:	00 
f0100b2a:	c7 04 24 7c 4a 10 f0 	movl   $0xf0104a7c,(%esp)
f0100b31:	e8 5e f5 ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b36:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100b3d:	00 
f0100b3e:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100b45:	00 
	return (void *)(pa + KERNBASE);
f0100b46:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b4b:	89 04 24             	mov    %eax,(%esp)
f0100b4e:	e8 f3 2d 00 00       	call   f0103946 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b53:	8b 1b                	mov    (%ebx),%ebx
f0100b55:	85 db                	test   %ebx,%ebx
f0100b57:	75 99                	jne    f0100af2 <check_page_free_list+0x91>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100b59:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b5e:	e8 21 fe ff ff       	call   f0100984 <boot_alloc>
f0100b63:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b66:	8b 15 80 85 11 f0    	mov    0xf0118580,%edx
f0100b6c:	85 d2                	test   %edx,%edx
f0100b6e:	0f 84 f6 01 00 00    	je     f0100d6a <check_page_free_list+0x309>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b74:	8b 1d a8 89 11 f0    	mov    0xf01189a8,%ebx
f0100b7a:	39 da                	cmp    %ebx,%edx
f0100b7c:	72 4d                	jb     f0100bcb <check_page_free_list+0x16a>
		assert(pp < pages + npages);
f0100b7e:	a1 a0 89 11 f0       	mov    0xf01189a0,%eax
f0100b83:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100b86:	8d 04 c3             	lea    (%ebx,%eax,8),%eax
f0100b89:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100b8c:	39 c2                	cmp    %eax,%edx
f0100b8e:	73 64                	jae    f0100bf4 <check_page_free_list+0x193>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b90:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0100b93:	89 d0                	mov    %edx,%eax
f0100b95:	29 d8                	sub    %ebx,%eax
f0100b97:	a8 07                	test   $0x7,%al
f0100b99:	0f 85 82 00 00 00    	jne    f0100c21 <check_page_free_list+0x1c0>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b9f:	c1 f8 03             	sar    $0x3,%eax
f0100ba2:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100ba5:	85 c0                	test   %eax,%eax
f0100ba7:	0f 84 a2 00 00 00    	je     f0100c4f <check_page_free_list+0x1ee>
		assert(page2pa(pp) != IOPHYSMEM);
f0100bad:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100bb2:	0f 84 c2 00 00 00    	je     f0100c7a <check_page_free_list+0x219>
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100bb8:	be 00 00 00 00       	mov    $0x0,%esi
f0100bbd:	bf 00 00 00 00       	mov    $0x0,%edi
f0100bc2:	e9 d7 00 00 00       	jmp    f0100c9e <check_page_free_list+0x23d>
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100bc7:	39 da                	cmp    %ebx,%edx
f0100bc9:	73 24                	jae    f0100bef <check_page_free_list+0x18e>
f0100bcb:	c7 44 24 0c 8a 4a 10 	movl   $0xf0104a8a,0xc(%esp)
f0100bd2:	f0 
f0100bd3:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0100bda:	f0 
f0100bdb:	c7 44 24 04 56 02 00 	movl   $0x256,0x4(%esp)
f0100be2:	00 
f0100be3:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0100bea:	e8 a5 f4 ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0100bef:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100bf2:	72 24                	jb     f0100c18 <check_page_free_list+0x1b7>
f0100bf4:	c7 44 24 0c ab 4a 10 	movl   $0xf0104aab,0xc(%esp)
f0100bfb:	f0 
f0100bfc:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0100c03:	f0 
f0100c04:	c7 44 24 04 57 02 00 	movl   $0x257,0x4(%esp)
f0100c0b:	00 
f0100c0c:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0100c13:	e8 7c f4 ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c18:	89 d0                	mov    %edx,%eax
f0100c1a:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100c1d:	a8 07                	test   $0x7,%al
f0100c1f:	74 24                	je     f0100c45 <check_page_free_list+0x1e4>
f0100c21:	c7 44 24 0c ac 43 10 	movl   $0xf01043ac,0xc(%esp)
f0100c28:	f0 
f0100c29:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0100c30:	f0 
f0100c31:	c7 44 24 04 58 02 00 	movl   $0x258,0x4(%esp)
f0100c38:	00 
f0100c39:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0100c40:	e8 4f f4 ff ff       	call   f0100094 <_panic>
f0100c45:	c1 f8 03             	sar    $0x3,%eax
f0100c48:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c4b:	85 c0                	test   %eax,%eax
f0100c4d:	75 24                	jne    f0100c73 <check_page_free_list+0x212>
f0100c4f:	c7 44 24 0c bf 4a 10 	movl   $0xf0104abf,0xc(%esp)
f0100c56:	f0 
f0100c57:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0100c5e:	f0 
f0100c5f:	c7 44 24 04 5b 02 00 	movl   $0x25b,0x4(%esp)
f0100c66:	00 
f0100c67:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0100c6e:	e8 21 f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c73:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c78:	75 24                	jne    f0100c9e <check_page_free_list+0x23d>
f0100c7a:	c7 44 24 0c d0 4a 10 	movl   $0xf0104ad0,0xc(%esp)
f0100c81:	f0 
f0100c82:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0100c89:	f0 
f0100c8a:	c7 44 24 04 5c 02 00 	movl   $0x25c,0x4(%esp)
f0100c91:	00 
f0100c92:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0100c99:	e8 f6 f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c9e:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100ca3:	75 24                	jne    f0100cc9 <check_page_free_list+0x268>
f0100ca5:	c7 44 24 0c e0 43 10 	movl   $0xf01043e0,0xc(%esp)
f0100cac:	f0 
f0100cad:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0100cb4:	f0 
f0100cb5:	c7 44 24 04 5d 02 00 	movl   $0x25d,0x4(%esp)
f0100cbc:	00 
f0100cbd:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0100cc4:	e8 cb f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100cc9:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100cce:	75 24                	jne    f0100cf4 <check_page_free_list+0x293>
f0100cd0:	c7 44 24 0c e9 4a 10 	movl   $0xf0104ae9,0xc(%esp)
f0100cd7:	f0 
f0100cd8:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0100cdf:	f0 
f0100ce0:	c7 44 24 04 5e 02 00 	movl   $0x25e,0x4(%esp)
f0100ce7:	00 
f0100ce8:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0100cef:	e8 a0 f3 ff ff       	call   f0100094 <_panic>
f0100cf4:	89 c1                	mov    %eax,%ecx
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100cf6:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100cfb:	76 57                	jbe    f0100d54 <check_page_free_list+0x2f3>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100cfd:	c1 e8 0c             	shr    $0xc,%eax
f0100d00:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100d03:	77 20                	ja     f0100d25 <check_page_free_list+0x2c4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d05:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100d09:	c7 44 24 08 64 43 10 	movl   $0xf0104364,0x8(%esp)
f0100d10:	f0 
f0100d11:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100d18:	00 
f0100d19:	c7 04 24 7c 4a 10 f0 	movl   $0xf0104a7c,(%esp)
f0100d20:	e8 6f f3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100d25:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f0100d2b:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0100d2e:	76 29                	jbe    f0100d59 <check_page_free_list+0x2f8>
f0100d30:	c7 44 24 0c 04 44 10 	movl   $0xf0104404,0xc(%esp)
f0100d37:	f0 
f0100d38:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0100d3f:	f0 
f0100d40:	c7 44 24 04 5f 02 00 	movl   $0x25f,0x4(%esp)
f0100d47:	00 
f0100d48:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0100d4f:	e8 40 f3 ff ff       	call   f0100094 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d54:	83 c7 01             	add    $0x1,%edi
f0100d57:	eb 03                	jmp    f0100d5c <check_page_free_list+0x2fb>
		else
			++nfree_extmem;
f0100d59:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d5c:	8b 12                	mov    (%edx),%edx
f0100d5e:	85 d2                	test   %edx,%edx
f0100d60:	0f 85 61 fe ff ff    	jne    f0100bc7 <check_page_free_list+0x166>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100d66:	85 ff                	test   %edi,%edi
f0100d68:	7f 24                	jg     f0100d8e <check_page_free_list+0x32d>
f0100d6a:	c7 44 24 0c 03 4b 10 	movl   $0xf0104b03,0xc(%esp)
f0100d71:	f0 
f0100d72:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0100d79:	f0 
f0100d7a:	c7 44 24 04 67 02 00 	movl   $0x267,0x4(%esp)
f0100d81:	00 
f0100d82:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0100d89:	e8 06 f3 ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f0100d8e:	85 f6                	test   %esi,%esi
f0100d90:	7f 24                	jg     f0100db6 <check_page_free_list+0x355>
f0100d92:	c7 44 24 0c 15 4b 10 	movl   $0xf0104b15,0xc(%esp)
f0100d99:	f0 
f0100d9a:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0100da1:	f0 
f0100da2:	c7 44 24 04 68 02 00 	movl   $0x268,0x4(%esp)
f0100da9:	00 
f0100daa:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0100db1:	e8 de f2 ff ff       	call   f0100094 <_panic>
}
f0100db6:	83 c4 3c             	add    $0x3c,%esp
f0100db9:	5b                   	pop    %ebx
f0100dba:	5e                   	pop    %esi
f0100dbb:	5f                   	pop    %edi
f0100dbc:	5d                   	pop    %ebp
f0100dbd:	c3                   	ret    

f0100dbe <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100dbe:	55                   	push   %ebp
f0100dbf:	89 e5                	mov    %esp,%ebp
f0100dc1:	56                   	push   %esi
f0100dc2:	53                   	push   %ebx
f0100dc3:	83 ec 10             	sub    $0x10,%esp
	// free pages!
	size_t i;
	//size_t a=0;
	//size_t b=0;
	//size_t c=0;
	page_free_list = NULL;
f0100dc6:	c7 05 80 85 11 f0 00 	movl   $0x0,0xf0118580
f0100dcd:	00 00 00 
	physaddr_t pgnum_IOPHYSMEM = PGNUM (IOPHYSMEM);
	physaddr_t pgnum_EXTPHYSMEM =PGNUM ( PADDR (ROUNDUP(pages+npages* sizeof (struct Page),PGSIZE)));
f0100dd0:	a1 a0 89 11 f0       	mov    0xf01189a0,%eax
f0100dd5:	89 c6                	mov    %eax,%esi
f0100dd7:	c1 e6 06             	shl    $0x6,%esi
f0100dda:	03 35 a8 89 11 f0    	add    0xf01189a8,%esi
f0100de0:	81 c6 ff 0f 00 00    	add    $0xfff,%esi
f0100de6:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100dec:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0100df2:	77 20                	ja     f0100e14 <page_init+0x56>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100df4:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100df8:	c7 44 24 08 4c 44 10 	movl   $0xf010444c,0x8(%esp)
f0100dff:	f0 
f0100e00:	c7 44 24 04 13 01 00 	movl   $0x113,0x4(%esp)
f0100e07:	00 
f0100e08:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0100e0f:	e8 80 f2 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100e14:	81 c6 00 00 00 10    	add    $0x10000000,%esi
f0100e1a:	c1 ee 0c             	shr    $0xc,%esi
	//PGNUM (ROUNDUP(pages+npages* sizeof (struct Page),PGSIZE))-PGNUM(kern_pgdir)+PGNUM(EXTPHYSMEM);
	for (i = 1; i < npages; i++) 
f0100e1d:	83 f8 01             	cmp    $0x1,%eax
f0100e20:	76 6f                	jbe    f0100e91 <page_init+0xd3>
f0100e22:	ba 08 00 00 00       	mov    $0x8,%edx
f0100e27:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100e2c:	b8 01 00 00 00       	mov    $0x1,%eax
	{
		
		
		if(i<pgnum_IOPHYSMEM)
f0100e31:	3d 9f 00 00 00       	cmp    $0x9f,%eax
f0100e36:	77 1a                	ja     f0100e52 <page_init+0x94>
		{
			pages[i].pp_ref = 0;
f0100e38:	89 d3                	mov    %edx,%ebx
f0100e3a:	03 1d a8 89 11 f0    	add    0xf01189a8,%ebx
f0100e40:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
			pages[i].pp_link = page_free_list;
f0100e46:	89 0b                	mov    %ecx,(%ebx)
			page_free_list = &pages[i];
f0100e48:	89 d1                	mov    %edx,%ecx
f0100e4a:	03 0d a8 89 11 f0    	add    0xf01189a8,%ecx
f0100e50:	eb 2b                	jmp    f0100e7d <page_init+0xbf>
			//a++;
		}
		else if( i>pgnum_EXTPHYSMEM)
f0100e52:	39 c6                	cmp    %eax,%esi
f0100e54:	73 1a                	jae    f0100e70 <page_init+0xb2>
		{
			pages[i].pp_ref = 0;
f0100e56:	8b 1d a8 89 11 f0    	mov    0xf01189a8,%ebx
f0100e5c:	66 c7 44 13 04 00 00 	movw   $0x0,0x4(%ebx,%edx,1)
			pages[i].pp_link = page_free_list;
f0100e63:	89 0c 13             	mov    %ecx,(%ebx,%edx,1)
			page_free_list = &pages[i];
f0100e66:	89 d1                	mov    %edx,%ecx
f0100e68:	03 0d a8 89 11 f0    	add    0xf01189a8,%ecx
f0100e6e:	eb 0d                	jmp    f0100e7d <page_init+0xbf>
			//b++;
		}
		else
		{
			pages[i].pp_ref = 1;
f0100e70:	8b 1d a8 89 11 f0    	mov    0xf01189a8,%ebx
f0100e76:	66 c7 44 13 04 01 00 	movw   $0x1,0x4(%ebx,%edx,1)
	//size_t c=0;
	page_free_list = NULL;
	physaddr_t pgnum_IOPHYSMEM = PGNUM (IOPHYSMEM);
	physaddr_t pgnum_EXTPHYSMEM =PGNUM ( PADDR (ROUNDUP(pages+npages* sizeof (struct Page),PGSIZE)));
	//PGNUM (ROUNDUP(pages+npages* sizeof (struct Page),PGSIZE))-PGNUM(kern_pgdir)+PGNUM(EXTPHYSMEM);
	for (i = 1; i < npages; i++) 
f0100e7d:	83 c0 01             	add    $0x1,%eax
f0100e80:	83 c2 08             	add    $0x8,%edx
f0100e83:	39 05 a0 89 11 f0    	cmp    %eax,0xf01189a0
f0100e89:	77 a6                	ja     f0100e31 <page_init+0x73>
f0100e8b:	89 0d 80 85 11 f0    	mov    %ecx,0xf0118580
			pages[i].pp_ref = 1;
			//c++;
		}
	}
	//cprintf("\n a:%d,b:%d c:%d  ",a,b,c);
}
f0100e91:	83 c4 10             	add    $0x10,%esp
f0100e94:	5b                   	pop    %ebx
f0100e95:	5e                   	pop    %esi
f0100e96:	5d                   	pop    %ebp
f0100e97:	c3                   	ret    

f0100e98 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct Page *
page_alloc(int alloc_flags)
{
f0100e98:	55                   	push   %ebp
f0100e99:	89 e5                	mov    %esp,%ebp
f0100e9b:	53                   	push   %ebx
f0100e9c:	83 ec 14             	sub    $0x14,%esp
f0100e9f:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	if ((alloc_flags==0 ||alloc_flags==ALLOC_ZERO)&& page_free_list!=NULL)
f0100ea2:	83 f8 01             	cmp    $0x1,%eax
f0100ea5:	77 71                	ja     f0100f18 <page_alloc+0x80>
f0100ea7:	8b 1d 80 85 11 f0    	mov    0xf0118580,%ebx
f0100ead:	85 db                	test   %ebx,%ebx
f0100eaf:	74 6c                	je     f0100f1d <page_alloc+0x85>
	{
		struct Page * temp_alloc_page = page_free_list;
		if(page_free_list->pp_link!=NULL)
f0100eb1:	8b 13                	mov    (%ebx),%edx
			page_free_list=page_free_list->pp_link;
f0100eb3:	89 15 80 85 11 f0    	mov    %edx,0xf0118580
		else 
			page_free_list=NULL;
		if(alloc_flags==ALLOC_ZERO)
f0100eb9:	83 f8 01             	cmp    $0x1,%eax
f0100ebc:	75 5f                	jne    f0100f1d <page_alloc+0x85>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ebe:	89 d8                	mov    %ebx,%eax
f0100ec0:	2b 05 a8 89 11 f0    	sub    0xf01189a8,%eax
f0100ec6:	c1 f8 03             	sar    $0x3,%eax
f0100ec9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ecc:	89 c2                	mov    %eax,%edx
f0100ece:	c1 ea 0c             	shr    $0xc,%edx
f0100ed1:	3b 15 a0 89 11 f0    	cmp    0xf01189a0,%edx
f0100ed7:	72 20                	jb     f0100ef9 <page_alloc+0x61>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ed9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100edd:	c7 44 24 08 64 43 10 	movl   $0xf0104364,0x8(%esp)
f0100ee4:	f0 
f0100ee5:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100eec:	00 
f0100eed:	c7 04 24 7c 4a 10 f0 	movl   $0xf0104a7c,(%esp)
f0100ef4:	e8 9b f1 ff ff       	call   f0100094 <_panic>
			memset(page2kva(temp_alloc_page), 0, PGSIZE);
f0100ef9:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100f00:	00 
f0100f01:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100f08:	00 
	return (void *)(pa + KERNBASE);
f0100f09:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100f0e:	89 04 24             	mov    %eax,(%esp)
f0100f11:	e8 30 2a 00 00       	call   f0103946 <memset>
f0100f16:	eb 05                	jmp    f0100f1d <page_alloc+0x85>
		return temp_alloc_page;
	}
	else
		return NULL;
f0100f18:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f0100f1d:	89 d8                	mov    %ebx,%eax
f0100f1f:	83 c4 14             	add    $0x14,%esp
f0100f22:	5b                   	pop    %ebx
f0100f23:	5d                   	pop    %ebp
f0100f24:	c3                   	ret    

f0100f25 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct Page *pp)
{
f0100f25:	55                   	push   %ebp
f0100f26:	89 e5                	mov    %esp,%ebp
f0100f28:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
//	pp->pp_ref = 0;
	pp->pp_link = page_free_list;
f0100f2b:	8b 15 80 85 11 f0    	mov    0xf0118580,%edx
f0100f31:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100f33:	a3 80 85 11 f0       	mov    %eax,0xf0118580
}
f0100f38:	5d                   	pop    %ebp
f0100f39:	c3                   	ret    

f0100f3a <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct Page* pp)
{
f0100f3a:	55                   	push   %ebp
f0100f3b:	89 e5                	mov    %esp,%ebp
f0100f3d:	83 ec 04             	sub    $0x4,%esp
f0100f40:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100f43:	0f b7 50 04          	movzwl 0x4(%eax),%edx
f0100f47:	83 ea 01             	sub    $0x1,%edx
f0100f4a:	66 89 50 04          	mov    %dx,0x4(%eax)
f0100f4e:	66 85 d2             	test   %dx,%dx
f0100f51:	75 08                	jne    f0100f5b <page_decref+0x21>
		page_free(pp);
f0100f53:	89 04 24             	mov    %eax,(%esp)
f0100f56:	e8 ca ff ff ff       	call   f0100f25 <page_free>
}
f0100f5b:	c9                   	leave  
f0100f5c:	c3                   	ret    

f0100f5d <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100f5d:	55                   	push   %ebp
f0100f5e:	89 e5                	mov    %esp,%ebp
f0100f60:	56                   	push   %esi
f0100f61:	53                   	push   %ebx
f0100f62:	83 ec 10             	sub    $0x10,%esp
f0100f65:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	pde_t *pde;//page directory entry,
	pte_t *pte;//page table entry
	pde=(pde_t *)pgdir+PDX(va);//get the entry of pde
f0100f68:	89 f3                	mov    %esi,%ebx
f0100f6a:	c1 eb 16             	shr    $0x16,%ebx
f0100f6d:	c1 e3 02             	shl    $0x2,%ebx
f0100f70:	03 5d 08             	add    0x8(%ebp),%ebx

	if (*pde & PTE_P)//the address exists
f0100f73:	8b 03                	mov    (%ebx),%eax
f0100f75:	a8 01                	test   $0x1,%al
f0100f77:	74 44                	je     f0100fbd <pgdir_walk+0x60>
	{
		pte=(pte_t *)KADDR(PTE_ADDR(*pde))+PTX(va);
f0100f79:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f7e:	89 c2                	mov    %eax,%edx
f0100f80:	c1 ea 0c             	shr    $0xc,%edx
f0100f83:	3b 15 a0 89 11 f0    	cmp    0xf01189a0,%edx
f0100f89:	72 20                	jb     f0100fab <pgdir_walk+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f8b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f8f:	c7 44 24 08 64 43 10 	movl   $0xf0104364,0x8(%esp)
f0100f96:	f0 
f0100f97:	c7 44 24 04 84 01 00 	movl   $0x184,0x4(%esp)
f0100f9e:	00 
f0100f9f:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0100fa6:	e8 e9 f0 ff ff       	call   f0100094 <_panic>
f0100fab:	c1 ee 0a             	shr    $0xa,%esi
f0100fae:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0100fb4:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
		return pte;
f0100fbb:	eb 7d                	jmp    f010103a <pgdir_walk+0xdd>
	}
	//the page does not exist
	if (create )//create a new page table 
f0100fbd:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100fc1:	74 6b                	je     f010102e <pgdir_walk+0xd1>
	{	
		struct Page *pp;
		pp=page_alloc(ALLOC_ZERO);
f0100fc3:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0100fca:	e8 c9 fe ff ff       	call   f0100e98 <page_alloc>
		if (pp!=NULL)
f0100fcf:	85 c0                	test   %eax,%eax
f0100fd1:	74 62                	je     f0101035 <pgdir_walk+0xd8>
		{
			pp->pp_ref=1;
f0100fd3:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100fd9:	2b 05 a8 89 11 f0    	sub    0xf01189a8,%eax
f0100fdf:	c1 f8 03             	sar    $0x3,%eax
f0100fe2:	c1 e0 0c             	shl    $0xc,%eax
			*pde = page2pa(pp)|PTE_U|PTE_W|PTE_P ;
f0100fe5:	83 c8 07             	or     $0x7,%eax
f0100fe8:	89 03                	mov    %eax,(%ebx)
			pte=(pte_t *)KADDR(PTE_ADDR(*pde))+PTX(va);
f0100fea:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fef:	89 c2                	mov    %eax,%edx
f0100ff1:	c1 ea 0c             	shr    $0xc,%edx
f0100ff4:	3b 15 a0 89 11 f0    	cmp    0xf01189a0,%edx
f0100ffa:	72 20                	jb     f010101c <pgdir_walk+0xbf>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ffc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101000:	c7 44 24 08 64 43 10 	movl   $0xf0104364,0x8(%esp)
f0101007:	f0 
f0101008:	c7 44 24 04 90 01 00 	movl   $0x190,0x4(%esp)
f010100f:	00 
f0101010:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101017:	e8 78 f0 ff ff       	call   f0100094 <_panic>
f010101c:	c1 ee 0a             	shr    $0xa,%esi
f010101f:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0101025:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
			return pte;
f010102c:	eb 0c                	jmp    f010103a <pgdir_walk+0xdd>
		}
	}
	return NULL;
f010102e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101033:	eb 05                	jmp    f010103a <pgdir_walk+0xdd>
f0101035:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010103a:	83 c4 10             	add    $0x10,%esp
f010103d:	5b                   	pop    %ebx
f010103e:	5e                   	pop    %esi
f010103f:	5d                   	pop    %ebp
f0101040:	c3                   	ret    

f0101041 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0101041:	55                   	push   %ebp
f0101042:	89 e5                	mov    %esp,%ebp
f0101044:	57                   	push   %edi
f0101045:	56                   	push   %esi
f0101046:	53                   	push   %ebx
f0101047:	83 ec 2c             	sub    $0x2c,%esp
f010104a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010104d:	89 d7                	mov    %edx,%edi
f010104f:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in
	if(size%PGSIZE!=0)
f0101052:	f7 c1 ff 0f 00 00    	test   $0xfff,%ecx
f0101058:	75 14                	jne    f010106e <boot_map_region+0x2d>
		panic(" Size must be a multiple of PGSIZE.");
	pte_t *pte ;
	size_t i=0;
	while(i<size)
f010105a:	bb 00 00 00 00       	mov    $0x0,%ebx
	{
		pte=pgdir_walk(pgdir, (void *)va, 1);
		*pte= pa|perm|PTE_P;
f010105f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101062:	83 c8 01             	or     $0x1,%eax
f0101065:	89 45 dc             	mov    %eax,-0x24(%ebp)
	// Fill this function in
	if(size%PGSIZE!=0)
		panic(" Size must be a multiple of PGSIZE.");
	pte_t *pte ;
	size_t i=0;
	while(i<size)
f0101068:	85 c9                	test   %ecx,%ecx
f010106a:	75 1e                	jne    f010108a <boot_map_region+0x49>
f010106c:	eb 4b                	jmp    f01010b9 <boot_map_region+0x78>
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	if(size%PGSIZE!=0)
		panic(" Size must be a multiple of PGSIZE.");
f010106e:	c7 44 24 08 70 44 10 	movl   $0xf0104470,0x8(%esp)
f0101075:	f0 
f0101076:	c7 44 24 04 a6 01 00 	movl   $0x1a6,0x4(%esp)
f010107d:	00 
f010107e:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101085:	e8 0a f0 ff ff       	call   f0100094 <_panic>
// above UTOP. As such, it should *not* change the pp_ref field on the
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f010108a:	8b 75 08             	mov    0x8(%ebp),%esi
f010108d:	01 de                	add    %ebx,%esi
		panic(" Size must be a multiple of PGSIZE.");
	pte_t *pte ;
	size_t i=0;
	while(i<size)
	{
		pte=pgdir_walk(pgdir, (void *)va, 1);
f010108f:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101096:	00 
// above UTOP. As such, it should *not* change the pp_ref field on the
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f0101097:	8d 04 3b             	lea    (%ebx,%edi,1),%eax
		panic(" Size must be a multiple of PGSIZE.");
	pte_t *pte ;
	size_t i=0;
	while(i<size)
	{
		pte=pgdir_walk(pgdir, (void *)va, 1);
f010109a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010109e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01010a1:	89 04 24             	mov    %eax,(%esp)
f01010a4:	e8 b4 fe ff ff       	call   f0100f5d <pgdir_walk>
		*pte= pa|perm|PTE_P;
f01010a9:	0b 75 dc             	or     -0x24(%ebp),%esi
f01010ac:	89 30                	mov    %esi,(%eax)
		pa+=PGSIZE;
		va+=PGSIZE;
		i+=PGSIZE;
f01010ae:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// Fill this function in
	if(size%PGSIZE!=0)
		panic(" Size must be a multiple of PGSIZE.");
	pte_t *pte ;
	size_t i=0;
	while(i<size)
f01010b4:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f01010b7:	77 d1                	ja     f010108a <boot_map_region+0x49>
		*pte= pa|perm|PTE_P;
		pa+=PGSIZE;
		va+=PGSIZE;
		i+=PGSIZE;
	}
}
f01010b9:	83 c4 2c             	add    $0x2c,%esp
f01010bc:	5b                   	pop    %ebx
f01010bd:	5e                   	pop    %esi
f01010be:	5f                   	pop    %edi
f01010bf:	5d                   	pop    %ebp
f01010c0:	c3                   	ret    

f01010c1 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01010c1:	55                   	push   %ebp
f01010c2:	89 e5                	mov    %esp,%ebp
f01010c4:	53                   	push   %ebx
f01010c5:	83 ec 14             	sub    $0x14,%esp
f01010c8:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pte = pgdir_walk(pgdir,(void *)va, 0);
f01010cb:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01010d2:	00 
f01010d3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010d6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01010da:	8b 45 08             	mov    0x8(%ebp),%eax
f01010dd:	89 04 24             	mov    %eax,(%esp)
f01010e0:	e8 78 fe ff ff       	call   f0100f5d <pgdir_walk>
	if (pte==NULL)
f01010e5:	85 c0                	test   %eax,%eax
f01010e7:	74 3e                	je     f0101127 <page_lookup+0x66>
	{
		return NULL;		
	}
	if (pte_store != 0) 
f01010e9:	85 db                	test   %ebx,%ebx
f01010eb:	74 02                	je     f01010ef <page_lookup+0x2e>
	{
		*pte_store = pte;
f01010ed:	89 03                	mov    %eax,(%ebx)
	}
	if (*pte & PTE_P) 
f01010ef:	8b 00                	mov    (%eax),%eax
f01010f1:	a8 01                	test   $0x1,%al
f01010f3:	74 39                	je     f010112e <page_lookup+0x6d>
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010f5:	c1 e8 0c             	shr    $0xc,%eax
f01010f8:	3b 05 a0 89 11 f0    	cmp    0xf01189a0,%eax
f01010fe:	72 1c                	jb     f010111c <page_lookup+0x5b>
		panic("pa2page called with invalid pa");
f0101100:	c7 44 24 08 94 44 10 	movl   $0xf0104494,0x8(%esp)
f0101107:	f0 
f0101108:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f010110f:	00 
f0101110:	c7 04 24 7c 4a 10 f0 	movl   $0xf0104a7c,(%esp)
f0101117:	e8 78 ef ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f010111c:	c1 e0 03             	shl    $0x3,%eax
f010111f:	03 05 a8 89 11 f0    	add    0xf01189a8,%eax
	{
		return pa2page (PTE_ADDR (*pte));
f0101125:	eb 0c                	jmp    f0101133 <page_lookup+0x72>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t *pte = pgdir_walk(pgdir,(void *)va, 0);
	if (pte==NULL)
	{
		return NULL;		
f0101127:	b8 00 00 00 00       	mov    $0x0,%eax
f010112c:	eb 05                	jmp    f0101133 <page_lookup+0x72>
	}
	if (*pte & PTE_P) 
	{
		return pa2page (PTE_ADDR (*pte));
	}
	return NULL;
f010112e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101133:	83 c4 14             	add    $0x14,%esp
f0101136:	5b                   	pop    %ebx
f0101137:	5d                   	pop    %ebp
f0101138:	c3                   	ret    

f0101139 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0101139:	55                   	push   %ebp
f010113a:	89 e5                	mov    %esp,%ebp
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010113c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010113f:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0101142:	5d                   	pop    %ebp
f0101143:	c3                   	ret    

f0101144 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101144:	55                   	push   %ebp
f0101145:	89 e5                	mov    %esp,%ebp
f0101147:	83 ec 28             	sub    $0x28,%esp
f010114a:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f010114d:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0101150:	8b 75 08             	mov    0x8(%ebp),%esi
f0101153:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *pte;
	struct Page *pp= page_lookup (pgdir, va, &pte);
f0101156:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101159:	89 44 24 08          	mov    %eax,0x8(%esp)
f010115d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101161:	89 34 24             	mov    %esi,(%esp)
f0101164:	e8 58 ff ff ff       	call   f01010c1 <page_lookup>
	if (pp != NULL) 
f0101169:	85 c0                	test   %eax,%eax
f010116b:	74 21                	je     f010118e <page_remove+0x4a>
	{
		page_decref (pp);//- The ref count on the physical page should decrement.
f010116d:	89 04 24             	mov    %eax,(%esp)
f0101170:	e8 c5 fd ff ff       	call   f0100f3a <page_decref>
//   - The physical page should be freed if the refcount reaches 0.
		if(pte!=NULL)
f0101175:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101178:	85 c0                	test   %eax,%eax
f010117a:	74 06                	je     f0101182 <page_remove+0x3e>
		*pte = 0;// The pg table entry corresponding to 'va' should be set to 0. (if such a PTE exists)
f010117c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		tlb_invalidate (pgdir, va);//The TLB must be invalidated if you remove an entry from  the page table.
f0101182:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101186:	89 34 24             	mov    %esi,(%esp)
f0101189:	e8 ab ff ff ff       	call   f0101139 <tlb_invalidate>
	}
}
f010118e:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0101191:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0101194:	89 ec                	mov    %ebp,%esp
f0101196:	5d                   	pop    %ebp
f0101197:	c3                   	ret    

f0101198 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{
f0101198:	55                   	push   %ebp
f0101199:	89 e5                	mov    %esp,%ebp
f010119b:	83 ec 28             	sub    $0x28,%esp
f010119e:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f01011a1:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01011a4:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01011a7:	8b 75 0c             	mov    0xc(%ebp),%esi
f01011aa:	8b 7d 10             	mov    0x10(%ebp),%edi

	pte_t * pte = pgdir_walk(pgdir, (void *)va, 1) ;
f01011ad:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01011b4:	00 
f01011b5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011b9:	8b 45 08             	mov    0x8(%ebp),%eax
f01011bc:	89 04 24             	mov    %eax,(%esp)
f01011bf:	e8 99 fd ff ff       	call   f0100f5d <pgdir_walk>
f01011c4:	89 c3                	mov    %eax,%ebx
	if (pte==NULL)
f01011c6:	85 c0                	test   %eax,%eax
f01011c8:	74 66                	je     f0101230 <page_insert+0x98>
		return -E_NO_MEM;
	if (*pte & PTE_P) {
f01011ca:	8b 00                	mov    (%eax),%eax
f01011cc:	a8 01                	test   $0x1,%al
f01011ce:	74 3c                	je     f010120c <page_insert+0x74>
		if (PTE_ADDR(*pte) == page2pa(pp))
f01011d0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01011d5:	89 f2                	mov    %esi,%edx
f01011d7:	2b 15 a8 89 11 f0    	sub    0xf01189a8,%edx
f01011dd:	c1 fa 03             	sar    $0x3,%edx
f01011e0:	c1 e2 0c             	shl    $0xc,%edx
f01011e3:	39 d0                	cmp    %edx,%eax
f01011e5:	75 16                	jne    f01011fd <page_insert+0x65>
		{
			tlb_invalidate(pgdir, va);
f01011e7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011eb:	8b 45 08             	mov    0x8(%ebp),%eax
f01011ee:	89 04 24             	mov    %eax,(%esp)
f01011f1:	e8 43 ff ff ff       	call   f0101139 <tlb_invalidate>
			pp -> pp_ref --;
f01011f6:	66 83 6e 04 01       	subw   $0x1,0x4(%esi)
f01011fb:	eb 0f                	jmp    f010120c <page_insert+0x74>
		} 
		else 
		{
			page_remove (pgdir, va);
f01011fd:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101201:	8b 45 08             	mov    0x8(%ebp),%eax
f0101204:	89 04 24             	mov    %eax,(%esp)
f0101207:	e8 38 ff ff ff       	call   f0101144 <page_remove>
		}
	}

	*pte = page2pa(pp)|perm|PTE_P;
f010120c:	8b 45 14             	mov    0x14(%ebp),%eax
f010120f:	83 c8 01             	or     $0x1,%eax
f0101212:	89 f2                	mov    %esi,%edx
f0101214:	2b 15 a8 89 11 f0    	sub    0xf01189a8,%edx
f010121a:	c1 fa 03             	sar    $0x3,%edx
f010121d:	c1 e2 0c             	shl    $0xc,%edx
f0101220:	09 d0                	or     %edx,%eax
f0101222:	89 03                	mov    %eax,(%ebx)
	pp->pp_ref++;//pp->pp_ref should be incremented if the insertion succeeds.
f0101224:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	return 0;
f0101229:	b8 00 00 00 00       	mov    $0x0,%eax
f010122e:	eb 05                	jmp    f0101235 <page_insert+0x9d>
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{

	pte_t * pte = pgdir_walk(pgdir, (void *)va, 1) ;
	if (pte==NULL)
		return -E_NO_MEM;
f0101230:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	}

	*pte = page2pa(pp)|perm|PTE_P;
	pp->pp_ref++;//pp->pp_ref should be incremented if the insertion succeeds.
	return 0;
}
f0101235:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0101238:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010123b:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010123e:	89 ec                	mov    %ebp,%esp
f0101240:	5d                   	pop    %ebp
f0101241:	c3                   	ret    

f0101242 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101242:	55                   	push   %ebp
f0101243:	89 e5                	mov    %esp,%ebp
f0101245:	57                   	push   %edi
f0101246:	56                   	push   %esi
f0101247:	53                   	push   %ebx
f0101248:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f010124b:	b8 15 00 00 00       	mov    $0x15,%eax
f0101250:	e8 da f7 ff ff       	call   f0100a2f <nvram_read>
f0101255:	c1 e0 0a             	shl    $0xa,%eax
f0101258:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010125e:	85 c0                	test   %eax,%eax
f0101260:	0f 48 c2             	cmovs  %edx,%eax
f0101263:	c1 f8 0c             	sar    $0xc,%eax
f0101266:	a3 78 85 11 f0       	mov    %eax,0xf0118578
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f010126b:	b8 17 00 00 00       	mov    $0x17,%eax
f0101270:	e8 ba f7 ff ff       	call   f0100a2f <nvram_read>
f0101275:	c1 e0 0a             	shl    $0xa,%eax
f0101278:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010127e:	85 c0                	test   %eax,%eax
f0101280:	0f 48 c2             	cmovs  %edx,%eax
f0101283:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101286:	85 c0                	test   %eax,%eax
f0101288:	74 0e                	je     f0101298 <mem_init+0x56>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f010128a:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101290:	89 15 a0 89 11 f0    	mov    %edx,0xf01189a0
f0101296:	eb 0c                	jmp    f01012a4 <mem_init+0x62>
	else
		npages = npages_basemem;
f0101298:	8b 15 78 85 11 f0    	mov    0xf0118578,%edx
f010129e:	89 15 a0 89 11 f0    	mov    %edx,0xf01189a0

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f01012a4:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012a7:	c1 e8 0a             	shr    $0xa,%eax
f01012aa:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f01012ae:	a1 78 85 11 f0       	mov    0xf0118578,%eax
f01012b3:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012b6:	c1 e8 0a             	shr    $0xa,%eax
f01012b9:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f01012bd:	a1 a0 89 11 f0       	mov    0xf01189a0,%eax
f01012c2:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012c5:	c1 e8 0a             	shr    $0xa,%eax
f01012c8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012cc:	c7 04 24 b4 44 10 f0 	movl   $0xf01044b4,(%esp)
f01012d3:	e8 76 1a 00 00       	call   f0102d4e <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01012d8:	b8 00 10 00 00       	mov    $0x1000,%eax
f01012dd:	e8 a2 f6 ff ff       	call   f0100984 <boot_alloc>
f01012e2:	a3 a4 89 11 f0       	mov    %eax,0xf01189a4
	memset(kern_pgdir, 0, PGSIZE);
f01012e7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01012ee:	00 
f01012ef:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01012f6:	00 
f01012f7:	89 04 24             	mov    %eax,(%esp)
f01012fa:	e8 47 26 00 00       	call   f0103946 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following two lines.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01012ff:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101304:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101309:	77 20                	ja     f010132b <mem_init+0xe9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010130b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010130f:	c7 44 24 08 4c 44 10 	movl   $0xf010444c,0x8(%esp)
f0101316:	f0 
f0101317:	c7 44 24 04 8b 00 00 	movl   $0x8b,0x4(%esp)
f010131e:	00 
f010131f:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101326:	e8 69 ed ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010132b:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101331:	83 ca 05             	or     $0x5,%edx
f0101334:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct Page in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:

	pages =(struct Page *) boot_alloc(npages* sizeof (struct Page));
f010133a:	a1 a0 89 11 f0       	mov    0xf01189a0,%eax
f010133f:	c1 e0 03             	shl    $0x3,%eax
f0101342:	e8 3d f6 ff ff       	call   f0100984 <boot_alloc>
f0101347:	a3 a8 89 11 f0       	mov    %eax,0xf01189a8
	memset(pages, 0, npages* sizeof (struct Page));
f010134c:	8b 15 a0 89 11 f0    	mov    0xf01189a0,%edx
f0101352:	c1 e2 03             	shl    $0x3,%edx
f0101355:	89 54 24 08          	mov    %edx,0x8(%esp)
f0101359:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101360:	00 
f0101361:	89 04 24             	mov    %eax,(%esp)
f0101364:	e8 dd 25 00 00       	call   f0103946 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101369:	e8 50 fa ff ff       	call   f0100dbe <page_init>
	check_page_free_list(1);
f010136e:	b8 01 00 00 00       	mov    $0x1,%eax
f0101373:	e8 e9 f6 ff ff       	call   f0100a61 <check_page_free_list>
	int nfree;
	struct Page *fl;
	char *c;
	int i;

	if (!pages)
f0101378:	83 3d a8 89 11 f0 00 	cmpl   $0x0,0xf01189a8
f010137f:	75 1c                	jne    f010139d <mem_init+0x15b>
		panic("'pages' is a null pointer!");
f0101381:	c7 44 24 08 26 4b 10 	movl   $0xf0104b26,0x8(%esp)
f0101388:	f0 
f0101389:	c7 44 24 04 79 02 00 	movl   $0x279,0x4(%esp)
f0101390:	00 
f0101391:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101398:	e8 f7 ec ff ff       	call   f0100094 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010139d:	a1 80 85 11 f0       	mov    0xf0118580,%eax
f01013a2:	bb 00 00 00 00       	mov    $0x0,%ebx
f01013a7:	85 c0                	test   %eax,%eax
f01013a9:	74 09                	je     f01013b4 <mem_init+0x172>
		++nfree;
f01013ab:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013ae:	8b 00                	mov    (%eax),%eax
f01013b0:	85 c0                	test   %eax,%eax
f01013b2:	75 f7                	jne    f01013ab <mem_init+0x169>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01013b4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013bb:	e8 d8 fa ff ff       	call   f0100e98 <page_alloc>
f01013c0:	89 c6                	mov    %eax,%esi
f01013c2:	85 c0                	test   %eax,%eax
f01013c4:	75 24                	jne    f01013ea <mem_init+0x1a8>
f01013c6:	c7 44 24 0c 41 4b 10 	movl   $0xf0104b41,0xc(%esp)
f01013cd:	f0 
f01013ce:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f01013d5:	f0 
f01013d6:	c7 44 24 04 81 02 00 	movl   $0x281,0x4(%esp)
f01013dd:	00 
f01013de:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f01013e5:	e8 aa ec ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01013ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013f1:	e8 a2 fa ff ff       	call   f0100e98 <page_alloc>
f01013f6:	89 c7                	mov    %eax,%edi
f01013f8:	85 c0                	test   %eax,%eax
f01013fa:	75 24                	jne    f0101420 <mem_init+0x1de>
f01013fc:	c7 44 24 0c 57 4b 10 	movl   $0xf0104b57,0xc(%esp)
f0101403:	f0 
f0101404:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f010140b:	f0 
f010140c:	c7 44 24 04 82 02 00 	movl   $0x282,0x4(%esp)
f0101413:	00 
f0101414:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f010141b:	e8 74 ec ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101420:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101427:	e8 6c fa ff ff       	call   f0100e98 <page_alloc>
f010142c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010142f:	85 c0                	test   %eax,%eax
f0101431:	75 24                	jne    f0101457 <mem_init+0x215>
f0101433:	c7 44 24 0c 6d 4b 10 	movl   $0xf0104b6d,0xc(%esp)
f010143a:	f0 
f010143b:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0101442:	f0 
f0101443:	c7 44 24 04 83 02 00 	movl   $0x283,0x4(%esp)
f010144a:	00 
f010144b:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101452:	e8 3d ec ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101457:	39 fe                	cmp    %edi,%esi
f0101459:	75 24                	jne    f010147f <mem_init+0x23d>
f010145b:	c7 44 24 0c 83 4b 10 	movl   $0xf0104b83,0xc(%esp)
f0101462:	f0 
f0101463:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f010146a:	f0 
f010146b:	c7 44 24 04 86 02 00 	movl   $0x286,0x4(%esp)
f0101472:	00 
f0101473:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f010147a:	e8 15 ec ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010147f:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101482:	74 05                	je     f0101489 <mem_init+0x247>
f0101484:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101487:	75 24                	jne    f01014ad <mem_init+0x26b>
f0101489:	c7 44 24 0c f0 44 10 	movl   $0xf01044f0,0xc(%esp)
f0101490:	f0 
f0101491:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0101498:	f0 
f0101499:	c7 44 24 04 87 02 00 	movl   $0x287,0x4(%esp)
f01014a0:	00 
f01014a1:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f01014a8:	e8 e7 eb ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01014ad:	8b 15 a8 89 11 f0    	mov    0xf01189a8,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f01014b3:	a1 a0 89 11 f0       	mov    0xf01189a0,%eax
f01014b8:	c1 e0 0c             	shl    $0xc,%eax
f01014bb:	89 f1                	mov    %esi,%ecx
f01014bd:	29 d1                	sub    %edx,%ecx
f01014bf:	c1 f9 03             	sar    $0x3,%ecx
f01014c2:	c1 e1 0c             	shl    $0xc,%ecx
f01014c5:	39 c1                	cmp    %eax,%ecx
f01014c7:	72 24                	jb     f01014ed <mem_init+0x2ab>
f01014c9:	c7 44 24 0c 95 4b 10 	movl   $0xf0104b95,0xc(%esp)
f01014d0:	f0 
f01014d1:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f01014d8:	f0 
f01014d9:	c7 44 24 04 88 02 00 	movl   $0x288,0x4(%esp)
f01014e0:	00 
f01014e1:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f01014e8:	e8 a7 eb ff ff       	call   f0100094 <_panic>
f01014ed:	89 f9                	mov    %edi,%ecx
f01014ef:	29 d1                	sub    %edx,%ecx
f01014f1:	c1 f9 03             	sar    $0x3,%ecx
f01014f4:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f01014f7:	39 c8                	cmp    %ecx,%eax
f01014f9:	77 24                	ja     f010151f <mem_init+0x2dd>
f01014fb:	c7 44 24 0c b2 4b 10 	movl   $0xf0104bb2,0xc(%esp)
f0101502:	f0 
f0101503:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f010150a:	f0 
f010150b:	c7 44 24 04 89 02 00 	movl   $0x289,0x4(%esp)
f0101512:	00 
f0101513:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f010151a:	e8 75 eb ff ff       	call   f0100094 <_panic>
f010151f:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101522:	29 d1                	sub    %edx,%ecx
f0101524:	89 ca                	mov    %ecx,%edx
f0101526:	c1 fa 03             	sar    $0x3,%edx
f0101529:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f010152c:	39 d0                	cmp    %edx,%eax
f010152e:	77 24                	ja     f0101554 <mem_init+0x312>
f0101530:	c7 44 24 0c cf 4b 10 	movl   $0xf0104bcf,0xc(%esp)
f0101537:	f0 
f0101538:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f010153f:	f0 
f0101540:	c7 44 24 04 8a 02 00 	movl   $0x28a,0x4(%esp)
f0101547:	00 
f0101548:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f010154f:	e8 40 eb ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101554:	a1 80 85 11 f0       	mov    0xf0118580,%eax
f0101559:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010155c:	c7 05 80 85 11 f0 00 	movl   $0x0,0xf0118580
f0101563:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101566:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010156d:	e8 26 f9 ff ff       	call   f0100e98 <page_alloc>
f0101572:	85 c0                	test   %eax,%eax
f0101574:	74 24                	je     f010159a <mem_init+0x358>
f0101576:	c7 44 24 0c ec 4b 10 	movl   $0xf0104bec,0xc(%esp)
f010157d:	f0 
f010157e:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0101585:	f0 
f0101586:	c7 44 24 04 91 02 00 	movl   $0x291,0x4(%esp)
f010158d:	00 
f010158e:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101595:	e8 fa ea ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f010159a:	89 34 24             	mov    %esi,(%esp)
f010159d:	e8 83 f9 ff ff       	call   f0100f25 <page_free>
	page_free(pp1);
f01015a2:	89 3c 24             	mov    %edi,(%esp)
f01015a5:	e8 7b f9 ff ff       	call   f0100f25 <page_free>
	page_free(pp2);
f01015aa:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015ad:	89 04 24             	mov    %eax,(%esp)
f01015b0:	e8 70 f9 ff ff       	call   f0100f25 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015b5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015bc:	e8 d7 f8 ff ff       	call   f0100e98 <page_alloc>
f01015c1:	89 c6                	mov    %eax,%esi
f01015c3:	85 c0                	test   %eax,%eax
f01015c5:	75 24                	jne    f01015eb <mem_init+0x3a9>
f01015c7:	c7 44 24 0c 41 4b 10 	movl   $0xf0104b41,0xc(%esp)
f01015ce:	f0 
f01015cf:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f01015d6:	f0 
f01015d7:	c7 44 24 04 98 02 00 	movl   $0x298,0x4(%esp)
f01015de:	00 
f01015df:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f01015e6:	e8 a9 ea ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01015eb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015f2:	e8 a1 f8 ff ff       	call   f0100e98 <page_alloc>
f01015f7:	89 c7                	mov    %eax,%edi
f01015f9:	85 c0                	test   %eax,%eax
f01015fb:	75 24                	jne    f0101621 <mem_init+0x3df>
f01015fd:	c7 44 24 0c 57 4b 10 	movl   $0xf0104b57,0xc(%esp)
f0101604:	f0 
f0101605:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f010160c:	f0 
f010160d:	c7 44 24 04 99 02 00 	movl   $0x299,0x4(%esp)
f0101614:	00 
f0101615:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f010161c:	e8 73 ea ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101621:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101628:	e8 6b f8 ff ff       	call   f0100e98 <page_alloc>
f010162d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101630:	85 c0                	test   %eax,%eax
f0101632:	75 24                	jne    f0101658 <mem_init+0x416>
f0101634:	c7 44 24 0c 6d 4b 10 	movl   $0xf0104b6d,0xc(%esp)
f010163b:	f0 
f010163c:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0101643:	f0 
f0101644:	c7 44 24 04 9a 02 00 	movl   $0x29a,0x4(%esp)
f010164b:	00 
f010164c:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101653:	e8 3c ea ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101658:	39 fe                	cmp    %edi,%esi
f010165a:	75 24                	jne    f0101680 <mem_init+0x43e>
f010165c:	c7 44 24 0c 83 4b 10 	movl   $0xf0104b83,0xc(%esp)
f0101663:	f0 
f0101664:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f010166b:	f0 
f010166c:	c7 44 24 04 9c 02 00 	movl   $0x29c,0x4(%esp)
f0101673:	00 
f0101674:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f010167b:	e8 14 ea ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101680:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101683:	74 05                	je     f010168a <mem_init+0x448>
f0101685:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101688:	75 24                	jne    f01016ae <mem_init+0x46c>
f010168a:	c7 44 24 0c f0 44 10 	movl   $0xf01044f0,0xc(%esp)
f0101691:	f0 
f0101692:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0101699:	f0 
f010169a:	c7 44 24 04 9d 02 00 	movl   $0x29d,0x4(%esp)
f01016a1:	00 
f01016a2:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f01016a9:	e8 e6 e9 ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f01016ae:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016b5:	e8 de f7 ff ff       	call   f0100e98 <page_alloc>
f01016ba:	85 c0                	test   %eax,%eax
f01016bc:	74 24                	je     f01016e2 <mem_init+0x4a0>
f01016be:	c7 44 24 0c ec 4b 10 	movl   $0xf0104bec,0xc(%esp)
f01016c5:	f0 
f01016c6:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f01016cd:	f0 
f01016ce:	c7 44 24 04 9e 02 00 	movl   $0x29e,0x4(%esp)
f01016d5:	00 
f01016d6:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f01016dd:	e8 b2 e9 ff ff       	call   f0100094 <_panic>
f01016e2:	89 f0                	mov    %esi,%eax
f01016e4:	2b 05 a8 89 11 f0    	sub    0xf01189a8,%eax
f01016ea:	c1 f8 03             	sar    $0x3,%eax
f01016ed:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01016f0:	89 c2                	mov    %eax,%edx
f01016f2:	c1 ea 0c             	shr    $0xc,%edx
f01016f5:	3b 15 a0 89 11 f0    	cmp    0xf01189a0,%edx
f01016fb:	72 20                	jb     f010171d <mem_init+0x4db>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01016fd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101701:	c7 44 24 08 64 43 10 	movl   $0xf0104364,0x8(%esp)
f0101708:	f0 
f0101709:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101710:	00 
f0101711:	c7 04 24 7c 4a 10 f0 	movl   $0xf0104a7c,(%esp)
f0101718:	e8 77 e9 ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010171d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101724:	00 
f0101725:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f010172c:	00 
	return (void *)(pa + KERNBASE);
f010172d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101732:	89 04 24             	mov    %eax,(%esp)
f0101735:	e8 0c 22 00 00       	call   f0103946 <memset>
	page_free(pp0);
f010173a:	89 34 24             	mov    %esi,(%esp)
f010173d:	e8 e3 f7 ff ff       	call   f0100f25 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101742:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101749:	e8 4a f7 ff ff       	call   f0100e98 <page_alloc>
f010174e:	85 c0                	test   %eax,%eax
f0101750:	75 24                	jne    f0101776 <mem_init+0x534>
f0101752:	c7 44 24 0c fb 4b 10 	movl   $0xf0104bfb,0xc(%esp)
f0101759:	f0 
f010175a:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0101761:	f0 
f0101762:	c7 44 24 04 a3 02 00 	movl   $0x2a3,0x4(%esp)
f0101769:	00 
f010176a:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101771:	e8 1e e9 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f0101776:	39 c6                	cmp    %eax,%esi
f0101778:	74 24                	je     f010179e <mem_init+0x55c>
f010177a:	c7 44 24 0c 19 4c 10 	movl   $0xf0104c19,0xc(%esp)
f0101781:	f0 
f0101782:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0101789:	f0 
f010178a:	c7 44 24 04 a4 02 00 	movl   $0x2a4,0x4(%esp)
f0101791:	00 
f0101792:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101799:	e8 f6 e8 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f010179e:	89 f2                	mov    %esi,%edx
f01017a0:	2b 15 a8 89 11 f0    	sub    0xf01189a8,%edx
f01017a6:	c1 fa 03             	sar    $0x3,%edx
f01017a9:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01017ac:	89 d0                	mov    %edx,%eax
f01017ae:	c1 e8 0c             	shr    $0xc,%eax
f01017b1:	3b 05 a0 89 11 f0    	cmp    0xf01189a0,%eax
f01017b7:	72 20                	jb     f01017d9 <mem_init+0x597>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01017b9:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01017bd:	c7 44 24 08 64 43 10 	movl   $0xf0104364,0x8(%esp)
f01017c4:	f0 
f01017c5:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01017cc:	00 
f01017cd:	c7 04 24 7c 4a 10 f0 	movl   $0xf0104a7c,(%esp)
f01017d4:	e8 bb e8 ff ff       	call   f0100094 <_panic>
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01017d9:	80 ba 00 00 00 f0 00 	cmpb   $0x0,-0x10000000(%edx)
f01017e0:	75 11                	jne    f01017f3 <mem_init+0x5b1>
f01017e2:	8d 82 01 00 00 f0    	lea    -0xfffffff(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01017e8:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01017ee:	80 38 00             	cmpb   $0x0,(%eax)
f01017f1:	74 24                	je     f0101817 <mem_init+0x5d5>
f01017f3:	c7 44 24 0c 29 4c 10 	movl   $0xf0104c29,0xc(%esp)
f01017fa:	f0 
f01017fb:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0101802:	f0 
f0101803:	c7 44 24 04 a7 02 00 	movl   $0x2a7,0x4(%esp)
f010180a:	00 
f010180b:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101812:	e8 7d e8 ff ff       	call   f0100094 <_panic>
f0101817:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010181a:	39 d0                	cmp    %edx,%eax
f010181c:	75 d0                	jne    f01017ee <mem_init+0x5ac>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f010181e:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101821:	89 15 80 85 11 f0    	mov    %edx,0xf0118580

	// free the pages we took
	page_free(pp0);
f0101827:	89 34 24             	mov    %esi,(%esp)
f010182a:	e8 f6 f6 ff ff       	call   f0100f25 <page_free>
	page_free(pp1);
f010182f:	89 3c 24             	mov    %edi,(%esp)
f0101832:	e8 ee f6 ff ff       	call   f0100f25 <page_free>
	page_free(pp2);
f0101837:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010183a:	89 04 24             	mov    %eax,(%esp)
f010183d:	e8 e3 f6 ff ff       	call   f0100f25 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101842:	a1 80 85 11 f0       	mov    0xf0118580,%eax
f0101847:	85 c0                	test   %eax,%eax
f0101849:	74 09                	je     f0101854 <mem_init+0x612>
		--nfree;
f010184b:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010184e:	8b 00                	mov    (%eax),%eax
f0101850:	85 c0                	test   %eax,%eax
f0101852:	75 f7                	jne    f010184b <mem_init+0x609>
		--nfree;
	assert(nfree == 0);
f0101854:	85 db                	test   %ebx,%ebx
f0101856:	74 24                	je     f010187c <mem_init+0x63a>
f0101858:	c7 44 24 0c 33 4c 10 	movl   $0xf0104c33,0xc(%esp)
f010185f:	f0 
f0101860:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0101867:	f0 
f0101868:	c7 44 24 04 b4 02 00 	movl   $0x2b4,0x4(%esp)
f010186f:	00 
f0101870:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101877:	e8 18 e8 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010187c:	c7 04 24 10 45 10 f0 	movl   $0xf0104510,(%esp)
f0101883:	e8 c6 14 00 00       	call   f0102d4e <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101888:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010188f:	e8 04 f6 ff ff       	call   f0100e98 <page_alloc>
f0101894:	89 c3                	mov    %eax,%ebx
f0101896:	85 c0                	test   %eax,%eax
f0101898:	75 24                	jne    f01018be <mem_init+0x67c>
f010189a:	c7 44 24 0c 41 4b 10 	movl   $0xf0104b41,0xc(%esp)
f01018a1:	f0 
f01018a2:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f01018a9:	f0 
f01018aa:	c7 44 24 04 0d 03 00 	movl   $0x30d,0x4(%esp)
f01018b1:	00 
f01018b2:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f01018b9:	e8 d6 e7 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01018be:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018c5:	e8 ce f5 ff ff       	call   f0100e98 <page_alloc>
f01018ca:	89 c7                	mov    %eax,%edi
f01018cc:	85 c0                	test   %eax,%eax
f01018ce:	75 24                	jne    f01018f4 <mem_init+0x6b2>
f01018d0:	c7 44 24 0c 57 4b 10 	movl   $0xf0104b57,0xc(%esp)
f01018d7:	f0 
f01018d8:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f01018df:	f0 
f01018e0:	c7 44 24 04 0e 03 00 	movl   $0x30e,0x4(%esp)
f01018e7:	00 
f01018e8:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f01018ef:	e8 a0 e7 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01018f4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018fb:	e8 98 f5 ff ff       	call   f0100e98 <page_alloc>
f0101900:	89 c6                	mov    %eax,%esi
f0101902:	85 c0                	test   %eax,%eax
f0101904:	75 24                	jne    f010192a <mem_init+0x6e8>
f0101906:	c7 44 24 0c 6d 4b 10 	movl   $0xf0104b6d,0xc(%esp)
f010190d:	f0 
f010190e:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0101915:	f0 
f0101916:	c7 44 24 04 0f 03 00 	movl   $0x30f,0x4(%esp)
f010191d:	00 
f010191e:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101925:	e8 6a e7 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010192a:	39 fb                	cmp    %edi,%ebx
f010192c:	75 24                	jne    f0101952 <mem_init+0x710>
f010192e:	c7 44 24 0c 83 4b 10 	movl   $0xf0104b83,0xc(%esp)
f0101935:	f0 
f0101936:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f010193d:	f0 
f010193e:	c7 44 24 04 12 03 00 	movl   $0x312,0x4(%esp)
f0101945:	00 
f0101946:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f010194d:	e8 42 e7 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101952:	39 c7                	cmp    %eax,%edi
f0101954:	74 04                	je     f010195a <mem_init+0x718>
f0101956:	39 c3                	cmp    %eax,%ebx
f0101958:	75 24                	jne    f010197e <mem_init+0x73c>
f010195a:	c7 44 24 0c f0 44 10 	movl   $0xf01044f0,0xc(%esp)
f0101961:	f0 
f0101962:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0101969:	f0 
f010196a:	c7 44 24 04 13 03 00 	movl   $0x313,0x4(%esp)
f0101971:	00 
f0101972:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101979:	e8 16 e7 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010197e:	8b 15 80 85 11 f0    	mov    0xf0118580,%edx
f0101984:	89 55 cc             	mov    %edx,-0x34(%ebp)
	page_free_list = 0;
f0101987:	c7 05 80 85 11 f0 00 	movl   $0x0,0xf0118580
f010198e:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101991:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101998:	e8 fb f4 ff ff       	call   f0100e98 <page_alloc>
f010199d:	85 c0                	test   %eax,%eax
f010199f:	74 24                	je     f01019c5 <mem_init+0x783>
f01019a1:	c7 44 24 0c ec 4b 10 	movl   $0xf0104bec,0xc(%esp)
f01019a8:	f0 
f01019a9:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f01019b0:	f0 
f01019b1:	c7 44 24 04 1a 03 00 	movl   $0x31a,0x4(%esp)
f01019b8:	00 
f01019b9:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f01019c0:	e8 cf e6 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01019c5:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01019c8:	89 44 24 08          	mov    %eax,0x8(%esp)
f01019cc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01019d3:	00 
f01019d4:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f01019d9:	89 04 24             	mov    %eax,(%esp)
f01019dc:	e8 e0 f6 ff ff       	call   f01010c1 <page_lookup>
f01019e1:	85 c0                	test   %eax,%eax
f01019e3:	74 24                	je     f0101a09 <mem_init+0x7c7>
f01019e5:	c7 44 24 0c 30 45 10 	movl   $0xf0104530,0xc(%esp)
f01019ec:	f0 
f01019ed:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f01019f4:	f0 
f01019f5:	c7 44 24 04 1d 03 00 	movl   $0x31d,0x4(%esp)
f01019fc:	00 
f01019fd:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101a04:	e8 8b e6 ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101a09:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101a10:	00 
f0101a11:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101a18:	00 
f0101a19:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101a1d:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0101a22:	89 04 24             	mov    %eax,(%esp)
f0101a25:	e8 6e f7 ff ff       	call   f0101198 <page_insert>
f0101a2a:	85 c0                	test   %eax,%eax
f0101a2c:	78 24                	js     f0101a52 <mem_init+0x810>
f0101a2e:	c7 44 24 0c 68 45 10 	movl   $0xf0104568,0xc(%esp)
f0101a35:	f0 
f0101a36:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0101a3d:	f0 
f0101a3e:	c7 44 24 04 20 03 00 	movl   $0x320,0x4(%esp)
f0101a45:	00 
f0101a46:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101a4d:	e8 42 e6 ff ff       	call   f0100094 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101a52:	89 1c 24             	mov    %ebx,(%esp)
f0101a55:	e8 cb f4 ff ff       	call   f0100f25 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101a5a:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101a61:	00 
f0101a62:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101a69:	00 
f0101a6a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101a6e:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0101a73:	89 04 24             	mov    %eax,(%esp)
f0101a76:	e8 1d f7 ff ff       	call   f0101198 <page_insert>
f0101a7b:	85 c0                	test   %eax,%eax
f0101a7d:	74 24                	je     f0101aa3 <mem_init+0x861>
f0101a7f:	c7 44 24 0c 98 45 10 	movl   $0xf0104598,0xc(%esp)
f0101a86:	f0 
f0101a87:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0101a8e:	f0 
f0101a8f:	c7 44 24 04 24 03 00 	movl   $0x324,0x4(%esp)
f0101a96:	00 
f0101a97:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101a9e:	e8 f1 e5 ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101aa3:	8b 0d a4 89 11 f0    	mov    0xf01189a4,%ecx
f0101aa9:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101aac:	a1 a8 89 11 f0       	mov    0xf01189a8,%eax
f0101ab1:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101ab4:	8b 11                	mov    (%ecx),%edx
f0101ab6:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101abc:	89 d8                	mov    %ebx,%eax
f0101abe:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0101ac1:	c1 f8 03             	sar    $0x3,%eax
f0101ac4:	c1 e0 0c             	shl    $0xc,%eax
f0101ac7:	39 c2                	cmp    %eax,%edx
f0101ac9:	74 24                	je     f0101aef <mem_init+0x8ad>
f0101acb:	c7 44 24 0c c8 45 10 	movl   $0xf01045c8,0xc(%esp)
f0101ad2:	f0 
f0101ad3:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0101ada:	f0 
f0101adb:	c7 44 24 04 25 03 00 	movl   $0x325,0x4(%esp)
f0101ae2:	00 
f0101ae3:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101aea:	e8 a5 e5 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101aef:	ba 00 00 00 00       	mov    $0x0,%edx
f0101af4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101af7:	e8 c2 ee ff ff       	call   f01009be <check_va2pa>
f0101afc:	89 fa                	mov    %edi,%edx
f0101afe:	2b 55 d0             	sub    -0x30(%ebp),%edx
f0101b01:	c1 fa 03             	sar    $0x3,%edx
f0101b04:	c1 e2 0c             	shl    $0xc,%edx
f0101b07:	39 d0                	cmp    %edx,%eax
f0101b09:	74 24                	je     f0101b2f <mem_init+0x8ed>
f0101b0b:	c7 44 24 0c f0 45 10 	movl   $0xf01045f0,0xc(%esp)
f0101b12:	f0 
f0101b13:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0101b1a:	f0 
f0101b1b:	c7 44 24 04 26 03 00 	movl   $0x326,0x4(%esp)
f0101b22:	00 
f0101b23:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101b2a:	e8 65 e5 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0101b2f:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101b34:	74 24                	je     f0101b5a <mem_init+0x918>
f0101b36:	c7 44 24 0c 3e 4c 10 	movl   $0xf0104c3e,0xc(%esp)
f0101b3d:	f0 
f0101b3e:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0101b45:	f0 
f0101b46:	c7 44 24 04 27 03 00 	movl   $0x327,0x4(%esp)
f0101b4d:	00 
f0101b4e:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101b55:	e8 3a e5 ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0101b5a:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101b5f:	74 24                	je     f0101b85 <mem_init+0x943>
f0101b61:	c7 44 24 0c 4f 4c 10 	movl   $0xf0104c4f,0xc(%esp)
f0101b68:	f0 
f0101b69:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0101b70:	f0 
f0101b71:	c7 44 24 04 28 03 00 	movl   $0x328,0x4(%esp)
f0101b78:	00 
f0101b79:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101b80:	e8 0f e5 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b85:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101b8c:	00 
f0101b8d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101b94:	00 
f0101b95:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101b99:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101b9c:	89 14 24             	mov    %edx,(%esp)
f0101b9f:	e8 f4 f5 ff ff       	call   f0101198 <page_insert>
f0101ba4:	85 c0                	test   %eax,%eax
f0101ba6:	74 24                	je     f0101bcc <mem_init+0x98a>
f0101ba8:	c7 44 24 0c 20 46 10 	movl   $0xf0104620,0xc(%esp)
f0101baf:	f0 
f0101bb0:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0101bb7:	f0 
f0101bb8:	c7 44 24 04 2b 03 00 	movl   $0x32b,0x4(%esp)
f0101bbf:	00 
f0101bc0:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101bc7:	e8 c8 e4 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bcc:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bd1:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0101bd6:	e8 e3 ed ff ff       	call   f01009be <check_va2pa>
f0101bdb:	89 f2                	mov    %esi,%edx
f0101bdd:	2b 15 a8 89 11 f0    	sub    0xf01189a8,%edx
f0101be3:	c1 fa 03             	sar    $0x3,%edx
f0101be6:	c1 e2 0c             	shl    $0xc,%edx
f0101be9:	39 d0                	cmp    %edx,%eax
f0101beb:	74 24                	je     f0101c11 <mem_init+0x9cf>
f0101bed:	c7 44 24 0c 5c 46 10 	movl   $0xf010465c,0xc(%esp)
f0101bf4:	f0 
f0101bf5:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0101bfc:	f0 
f0101bfd:	c7 44 24 04 2c 03 00 	movl   $0x32c,0x4(%esp)
f0101c04:	00 
f0101c05:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101c0c:	e8 83 e4 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101c11:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c16:	74 24                	je     f0101c3c <mem_init+0x9fa>
f0101c18:	c7 44 24 0c 60 4c 10 	movl   $0xf0104c60,0xc(%esp)
f0101c1f:	f0 
f0101c20:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0101c27:	f0 
f0101c28:	c7 44 24 04 2d 03 00 	movl   $0x32d,0x4(%esp)
f0101c2f:	00 
f0101c30:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101c37:	e8 58 e4 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101c3c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c43:	e8 50 f2 ff ff       	call   f0100e98 <page_alloc>
f0101c48:	85 c0                	test   %eax,%eax
f0101c4a:	74 24                	je     f0101c70 <mem_init+0xa2e>
f0101c4c:	c7 44 24 0c ec 4b 10 	movl   $0xf0104bec,0xc(%esp)
f0101c53:	f0 
f0101c54:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0101c5b:	f0 
f0101c5c:	c7 44 24 04 30 03 00 	movl   $0x330,0x4(%esp)
f0101c63:	00 
f0101c64:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101c6b:	e8 24 e4 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c70:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101c77:	00 
f0101c78:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101c7f:	00 
f0101c80:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101c84:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0101c89:	89 04 24             	mov    %eax,(%esp)
f0101c8c:	e8 07 f5 ff ff       	call   f0101198 <page_insert>
f0101c91:	85 c0                	test   %eax,%eax
f0101c93:	74 24                	je     f0101cb9 <mem_init+0xa77>
f0101c95:	c7 44 24 0c 20 46 10 	movl   $0xf0104620,0xc(%esp)
f0101c9c:	f0 
f0101c9d:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0101ca4:	f0 
f0101ca5:	c7 44 24 04 33 03 00 	movl   $0x333,0x4(%esp)
f0101cac:	00 
f0101cad:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101cb4:	e8 db e3 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101cb9:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cbe:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0101cc3:	e8 f6 ec ff ff       	call   f01009be <check_va2pa>
f0101cc8:	89 f2                	mov    %esi,%edx
f0101cca:	2b 15 a8 89 11 f0    	sub    0xf01189a8,%edx
f0101cd0:	c1 fa 03             	sar    $0x3,%edx
f0101cd3:	c1 e2 0c             	shl    $0xc,%edx
f0101cd6:	39 d0                	cmp    %edx,%eax
f0101cd8:	74 24                	je     f0101cfe <mem_init+0xabc>
f0101cda:	c7 44 24 0c 5c 46 10 	movl   $0xf010465c,0xc(%esp)
f0101ce1:	f0 
f0101ce2:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0101ce9:	f0 
f0101cea:	c7 44 24 04 34 03 00 	movl   $0x334,0x4(%esp)
f0101cf1:	00 
f0101cf2:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101cf9:	e8 96 e3 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101cfe:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d03:	74 24                	je     f0101d29 <mem_init+0xae7>
f0101d05:	c7 44 24 0c 60 4c 10 	movl   $0xf0104c60,0xc(%esp)
f0101d0c:	f0 
f0101d0d:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0101d14:	f0 
f0101d15:	c7 44 24 04 35 03 00 	movl   $0x335,0x4(%esp)
f0101d1c:	00 
f0101d1d:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101d24:	e8 6b e3 ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101d29:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101d30:	e8 63 f1 ff ff       	call   f0100e98 <page_alloc>
f0101d35:	85 c0                	test   %eax,%eax
f0101d37:	74 24                	je     f0101d5d <mem_init+0xb1b>
f0101d39:	c7 44 24 0c ec 4b 10 	movl   $0xf0104bec,0xc(%esp)
f0101d40:	f0 
f0101d41:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0101d48:	f0 
f0101d49:	c7 44 24 04 39 03 00 	movl   $0x339,0x4(%esp)
f0101d50:	00 
f0101d51:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101d58:	e8 37 e3 ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101d5d:	8b 15 a4 89 11 f0    	mov    0xf01189a4,%edx
f0101d63:	8b 02                	mov    (%edx),%eax
f0101d65:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101d6a:	89 c1                	mov    %eax,%ecx
f0101d6c:	c1 e9 0c             	shr    $0xc,%ecx
f0101d6f:	3b 0d a0 89 11 f0    	cmp    0xf01189a0,%ecx
f0101d75:	72 20                	jb     f0101d97 <mem_init+0xb55>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101d77:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101d7b:	c7 44 24 08 64 43 10 	movl   $0xf0104364,0x8(%esp)
f0101d82:	f0 
f0101d83:	c7 44 24 04 3c 03 00 	movl   $0x33c,0x4(%esp)
f0101d8a:	00 
f0101d8b:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101d92:	e8 fd e2 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101d97:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101d9c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101d9f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101da6:	00 
f0101da7:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101dae:	00 
f0101daf:	89 14 24             	mov    %edx,(%esp)
f0101db2:	e8 a6 f1 ff ff       	call   f0100f5d <pgdir_walk>
f0101db7:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101dba:	83 c2 04             	add    $0x4,%edx
f0101dbd:	39 d0                	cmp    %edx,%eax
f0101dbf:	74 24                	je     f0101de5 <mem_init+0xba3>
f0101dc1:	c7 44 24 0c 8c 46 10 	movl   $0xf010468c,0xc(%esp)
f0101dc8:	f0 
f0101dc9:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0101dd0:	f0 
f0101dd1:	c7 44 24 04 3d 03 00 	movl   $0x33d,0x4(%esp)
f0101dd8:	00 
f0101dd9:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101de0:	e8 af e2 ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101de5:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101dec:	00 
f0101ded:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101df4:	00 
f0101df5:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101df9:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0101dfe:	89 04 24             	mov    %eax,(%esp)
f0101e01:	e8 92 f3 ff ff       	call   f0101198 <page_insert>
f0101e06:	85 c0                	test   %eax,%eax
f0101e08:	74 24                	je     f0101e2e <mem_init+0xbec>
f0101e0a:	c7 44 24 0c cc 46 10 	movl   $0xf01046cc,0xc(%esp)
f0101e11:	f0 
f0101e12:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0101e19:	f0 
f0101e1a:	c7 44 24 04 40 03 00 	movl   $0x340,0x4(%esp)
f0101e21:	00 
f0101e22:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101e29:	e8 66 e2 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101e2e:	8b 0d a4 89 11 f0    	mov    0xf01189a4,%ecx
f0101e34:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0101e37:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e3c:	89 c8                	mov    %ecx,%eax
f0101e3e:	e8 7b eb ff ff       	call   f01009be <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101e43:	89 f2                	mov    %esi,%edx
f0101e45:	2b 15 a8 89 11 f0    	sub    0xf01189a8,%edx
f0101e4b:	c1 fa 03             	sar    $0x3,%edx
f0101e4e:	c1 e2 0c             	shl    $0xc,%edx
f0101e51:	39 d0                	cmp    %edx,%eax
f0101e53:	74 24                	je     f0101e79 <mem_init+0xc37>
f0101e55:	c7 44 24 0c 5c 46 10 	movl   $0xf010465c,0xc(%esp)
f0101e5c:	f0 
f0101e5d:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0101e64:	f0 
f0101e65:	c7 44 24 04 41 03 00 	movl   $0x341,0x4(%esp)
f0101e6c:	00 
f0101e6d:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101e74:	e8 1b e2 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101e79:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101e7e:	74 24                	je     f0101ea4 <mem_init+0xc62>
f0101e80:	c7 44 24 0c 60 4c 10 	movl   $0xf0104c60,0xc(%esp)
f0101e87:	f0 
f0101e88:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0101e8f:	f0 
f0101e90:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f0101e97:	00 
f0101e98:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101e9f:	e8 f0 e1 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101ea4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101eab:	00 
f0101eac:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101eb3:	00 
f0101eb4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101eb7:	89 04 24             	mov    %eax,(%esp)
f0101eba:	e8 9e f0 ff ff       	call   f0100f5d <pgdir_walk>
f0101ebf:	f6 00 04             	testb  $0x4,(%eax)
f0101ec2:	75 24                	jne    f0101ee8 <mem_init+0xca6>
f0101ec4:	c7 44 24 0c 0c 47 10 	movl   $0xf010470c,0xc(%esp)
f0101ecb:	f0 
f0101ecc:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0101ed3:	f0 
f0101ed4:	c7 44 24 04 43 03 00 	movl   $0x343,0x4(%esp)
f0101edb:	00 
f0101edc:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101ee3:	e8 ac e1 ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101ee8:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0101eed:	f6 00 04             	testb  $0x4,(%eax)
f0101ef0:	75 24                	jne    f0101f16 <mem_init+0xcd4>
f0101ef2:	c7 44 24 0c 71 4c 10 	movl   $0xf0104c71,0xc(%esp)
f0101ef9:	f0 
f0101efa:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0101f01:	f0 
f0101f02:	c7 44 24 04 44 03 00 	movl   $0x344,0x4(%esp)
f0101f09:	00 
f0101f0a:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101f11:	e8 7e e1 ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101f16:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f1d:	00 
f0101f1e:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0101f25:	00 
f0101f26:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101f2a:	89 04 24             	mov    %eax,(%esp)
f0101f2d:	e8 66 f2 ff ff       	call   f0101198 <page_insert>
f0101f32:	85 c0                	test   %eax,%eax
f0101f34:	78 24                	js     f0101f5a <mem_init+0xd18>
f0101f36:	c7 44 24 0c 40 47 10 	movl   $0xf0104740,0xc(%esp)
f0101f3d:	f0 
f0101f3e:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0101f45:	f0 
f0101f46:	c7 44 24 04 47 03 00 	movl   $0x347,0x4(%esp)
f0101f4d:	00 
f0101f4e:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101f55:	e8 3a e1 ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101f5a:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f61:	00 
f0101f62:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101f69:	00 
f0101f6a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101f6e:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0101f73:	89 04 24             	mov    %eax,(%esp)
f0101f76:	e8 1d f2 ff ff       	call   f0101198 <page_insert>
f0101f7b:	85 c0                	test   %eax,%eax
f0101f7d:	74 24                	je     f0101fa3 <mem_init+0xd61>
f0101f7f:	c7 44 24 0c 78 47 10 	movl   $0xf0104778,0xc(%esp)
f0101f86:	f0 
f0101f87:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0101f8e:	f0 
f0101f8f:	c7 44 24 04 4a 03 00 	movl   $0x34a,0x4(%esp)
f0101f96:	00 
f0101f97:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101f9e:	e8 f1 e0 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101fa3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101faa:	00 
f0101fab:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101fb2:	00 
f0101fb3:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0101fb8:	89 04 24             	mov    %eax,(%esp)
f0101fbb:	e8 9d ef ff ff       	call   f0100f5d <pgdir_walk>
f0101fc0:	f6 00 04             	testb  $0x4,(%eax)
f0101fc3:	74 24                	je     f0101fe9 <mem_init+0xda7>
f0101fc5:	c7 44 24 0c b4 47 10 	movl   $0xf01047b4,0xc(%esp)
f0101fcc:	f0 
f0101fcd:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0101fd4:	f0 
f0101fd5:	c7 44 24 04 4b 03 00 	movl   $0x34b,0x4(%esp)
f0101fdc:	00 
f0101fdd:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0101fe4:	e8 ab e0 ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101fe9:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0101fee:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101ff1:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ff6:	e8 c3 e9 ff ff       	call   f01009be <check_va2pa>
f0101ffb:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101ffe:	89 f8                	mov    %edi,%eax
f0102000:	2b 05 a8 89 11 f0    	sub    0xf01189a8,%eax
f0102006:	c1 f8 03             	sar    $0x3,%eax
f0102009:	c1 e0 0c             	shl    $0xc,%eax
f010200c:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f010200f:	74 24                	je     f0102035 <mem_init+0xdf3>
f0102011:	c7 44 24 0c ec 47 10 	movl   $0xf01047ec,0xc(%esp)
f0102018:	f0 
f0102019:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0102020:	f0 
f0102021:	c7 44 24 04 4e 03 00 	movl   $0x34e,0x4(%esp)
f0102028:	00 
f0102029:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0102030:	e8 5f e0 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102035:	ba 00 10 00 00       	mov    $0x1000,%edx
f010203a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010203d:	e8 7c e9 ff ff       	call   f01009be <check_va2pa>
f0102042:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102045:	74 24                	je     f010206b <mem_init+0xe29>
f0102047:	c7 44 24 0c 18 48 10 	movl   $0xf0104818,0xc(%esp)
f010204e:	f0 
f010204f:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0102056:	f0 
f0102057:	c7 44 24 04 4f 03 00 	movl   $0x34f,0x4(%esp)
f010205e:	00 
f010205f:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0102066:	e8 29 e0 ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f010206b:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f0102070:	74 24                	je     f0102096 <mem_init+0xe54>
f0102072:	c7 44 24 0c 87 4c 10 	movl   $0xf0104c87,0xc(%esp)
f0102079:	f0 
f010207a:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0102081:	f0 
f0102082:	c7 44 24 04 51 03 00 	movl   $0x351,0x4(%esp)
f0102089:	00 
f010208a:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0102091:	e8 fe df ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102096:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010209b:	74 24                	je     f01020c1 <mem_init+0xe7f>
f010209d:	c7 44 24 0c 98 4c 10 	movl   $0xf0104c98,0xc(%esp)
f01020a4:	f0 
f01020a5:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f01020ac:	f0 
f01020ad:	c7 44 24 04 52 03 00 	movl   $0x352,0x4(%esp)
f01020b4:	00 
f01020b5:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f01020bc:	e8 d3 df ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f01020c1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01020c8:	e8 cb ed ff ff       	call   f0100e98 <page_alloc>
f01020cd:	85 c0                	test   %eax,%eax
f01020cf:	74 04                	je     f01020d5 <mem_init+0xe93>
f01020d1:	39 c6                	cmp    %eax,%esi
f01020d3:	74 24                	je     f01020f9 <mem_init+0xeb7>
f01020d5:	c7 44 24 0c 48 48 10 	movl   $0xf0104848,0xc(%esp)
f01020dc:	f0 
f01020dd:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f01020e4:	f0 
f01020e5:	c7 44 24 04 55 03 00 	movl   $0x355,0x4(%esp)
f01020ec:	00 
f01020ed:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f01020f4:	e8 9b df ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f01020f9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102100:	00 
f0102101:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0102106:	89 04 24             	mov    %eax,(%esp)
f0102109:	e8 36 f0 ff ff       	call   f0101144 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010210e:	8b 15 a4 89 11 f0    	mov    0xf01189a4,%edx
f0102114:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0102117:	ba 00 00 00 00       	mov    $0x0,%edx
f010211c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010211f:	e8 9a e8 ff ff       	call   f01009be <check_va2pa>
f0102124:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102127:	74 24                	je     f010214d <mem_init+0xf0b>
f0102129:	c7 44 24 0c 6c 48 10 	movl   $0xf010486c,0xc(%esp)
f0102130:	f0 
f0102131:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0102138:	f0 
f0102139:	c7 44 24 04 59 03 00 	movl   $0x359,0x4(%esp)
f0102140:	00 
f0102141:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0102148:	e8 47 df ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010214d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102152:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102155:	e8 64 e8 ff ff       	call   f01009be <check_va2pa>
f010215a:	89 fa                	mov    %edi,%edx
f010215c:	2b 15 a8 89 11 f0    	sub    0xf01189a8,%edx
f0102162:	c1 fa 03             	sar    $0x3,%edx
f0102165:	c1 e2 0c             	shl    $0xc,%edx
f0102168:	39 d0                	cmp    %edx,%eax
f010216a:	74 24                	je     f0102190 <mem_init+0xf4e>
f010216c:	c7 44 24 0c 18 48 10 	movl   $0xf0104818,0xc(%esp)
f0102173:	f0 
f0102174:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f010217b:	f0 
f010217c:	c7 44 24 04 5a 03 00 	movl   $0x35a,0x4(%esp)
f0102183:	00 
f0102184:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f010218b:	e8 04 df ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0102190:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102195:	74 24                	je     f01021bb <mem_init+0xf79>
f0102197:	c7 44 24 0c 3e 4c 10 	movl   $0xf0104c3e,0xc(%esp)
f010219e:	f0 
f010219f:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f01021a6:	f0 
f01021a7:	c7 44 24 04 5b 03 00 	movl   $0x35b,0x4(%esp)
f01021ae:	00 
f01021af:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f01021b6:	e8 d9 de ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01021bb:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01021c0:	74 24                	je     f01021e6 <mem_init+0xfa4>
f01021c2:	c7 44 24 0c 98 4c 10 	movl   $0xf0104c98,0xc(%esp)
f01021c9:	f0 
f01021ca:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f01021d1:	f0 
f01021d2:	c7 44 24 04 5c 03 00 	movl   $0x35c,0x4(%esp)
f01021d9:	00 
f01021da:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f01021e1:	e8 ae de ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01021e6:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01021ed:	00 
f01021ee:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01021f1:	89 0c 24             	mov    %ecx,(%esp)
f01021f4:	e8 4b ef ff ff       	call   f0101144 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01021f9:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f01021fe:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102201:	ba 00 00 00 00       	mov    $0x0,%edx
f0102206:	e8 b3 e7 ff ff       	call   f01009be <check_va2pa>
f010220b:	83 f8 ff             	cmp    $0xffffffff,%eax
f010220e:	74 24                	je     f0102234 <mem_init+0xff2>
f0102210:	c7 44 24 0c 6c 48 10 	movl   $0xf010486c,0xc(%esp)
f0102217:	f0 
f0102218:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f010221f:	f0 
f0102220:	c7 44 24 04 60 03 00 	movl   $0x360,0x4(%esp)
f0102227:	00 
f0102228:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f010222f:	e8 60 de ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102234:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102239:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010223c:	e8 7d e7 ff ff       	call   f01009be <check_va2pa>
f0102241:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102244:	74 24                	je     f010226a <mem_init+0x1028>
f0102246:	c7 44 24 0c 90 48 10 	movl   $0xf0104890,0xc(%esp)
f010224d:	f0 
f010224e:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0102255:	f0 
f0102256:	c7 44 24 04 61 03 00 	movl   $0x361,0x4(%esp)
f010225d:	00 
f010225e:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0102265:	e8 2a de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f010226a:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f010226f:	74 24                	je     f0102295 <mem_init+0x1053>
f0102271:	c7 44 24 0c a9 4c 10 	movl   $0xf0104ca9,0xc(%esp)
f0102278:	f0 
f0102279:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0102280:	f0 
f0102281:	c7 44 24 04 62 03 00 	movl   $0x362,0x4(%esp)
f0102288:	00 
f0102289:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0102290:	e8 ff dd ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102295:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010229a:	74 24                	je     f01022c0 <mem_init+0x107e>
f010229c:	c7 44 24 0c 98 4c 10 	movl   $0xf0104c98,0xc(%esp)
f01022a3:	f0 
f01022a4:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f01022ab:	f0 
f01022ac:	c7 44 24 04 63 03 00 	movl   $0x363,0x4(%esp)
f01022b3:	00 
f01022b4:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f01022bb:	e8 d4 dd ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f01022c0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01022c7:	e8 cc eb ff ff       	call   f0100e98 <page_alloc>
f01022cc:	85 c0                	test   %eax,%eax
f01022ce:	74 04                	je     f01022d4 <mem_init+0x1092>
f01022d0:	39 c7                	cmp    %eax,%edi
f01022d2:	74 24                	je     f01022f8 <mem_init+0x10b6>
f01022d4:	c7 44 24 0c b8 48 10 	movl   $0xf01048b8,0xc(%esp)
f01022db:	f0 
f01022dc:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f01022e3:	f0 
f01022e4:	c7 44 24 04 66 03 00 	movl   $0x366,0x4(%esp)
f01022eb:	00 
f01022ec:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f01022f3:	e8 9c dd ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01022f8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01022ff:	e8 94 eb ff ff       	call   f0100e98 <page_alloc>
f0102304:	85 c0                	test   %eax,%eax
f0102306:	74 24                	je     f010232c <mem_init+0x10ea>
f0102308:	c7 44 24 0c ec 4b 10 	movl   $0xf0104bec,0xc(%esp)
f010230f:	f0 
f0102310:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0102317:	f0 
f0102318:	c7 44 24 04 69 03 00 	movl   $0x369,0x4(%esp)
f010231f:	00 
f0102320:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0102327:	e8 68 dd ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010232c:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0102331:	8b 08                	mov    (%eax),%ecx
f0102333:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102339:	89 da                	mov    %ebx,%edx
f010233b:	2b 15 a8 89 11 f0    	sub    0xf01189a8,%edx
f0102341:	c1 fa 03             	sar    $0x3,%edx
f0102344:	c1 e2 0c             	shl    $0xc,%edx
f0102347:	39 d1                	cmp    %edx,%ecx
f0102349:	74 24                	je     f010236f <mem_init+0x112d>
f010234b:	c7 44 24 0c c8 45 10 	movl   $0xf01045c8,0xc(%esp)
f0102352:	f0 
f0102353:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f010235a:	f0 
f010235b:	c7 44 24 04 6c 03 00 	movl   $0x36c,0x4(%esp)
f0102362:	00 
f0102363:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f010236a:	e8 25 dd ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f010236f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102375:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010237a:	74 24                	je     f01023a0 <mem_init+0x115e>
f010237c:	c7 44 24 0c 4f 4c 10 	movl   $0xf0104c4f,0xc(%esp)
f0102383:	f0 
f0102384:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f010238b:	f0 
f010238c:	c7 44 24 04 6e 03 00 	movl   $0x36e,0x4(%esp)
f0102393:	00 
f0102394:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f010239b:	e8 f4 dc ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f01023a0:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01023a6:	89 1c 24             	mov    %ebx,(%esp)
f01023a9:	e8 77 eb ff ff       	call   f0100f25 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01023ae:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01023b5:	00 
f01023b6:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f01023bd:	00 
f01023be:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f01023c3:	89 04 24             	mov    %eax,(%esp)
f01023c6:	e8 92 eb ff ff       	call   f0100f5d <pgdir_walk>
f01023cb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01023ce:	8b 0d a4 89 11 f0    	mov    0xf01189a4,%ecx
f01023d4:	8b 51 04             	mov    0x4(%ecx),%edx
f01023d7:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01023dd:	89 55 d4             	mov    %edx,-0x2c(%ebp)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01023e0:	8b 15 a0 89 11 f0    	mov    0xf01189a0,%edx
f01023e6:	89 55 c8             	mov    %edx,-0x38(%ebp)
f01023e9:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01023ec:	c1 ea 0c             	shr    $0xc,%edx
f01023ef:	89 55 d0             	mov    %edx,-0x30(%ebp)
f01023f2:	8b 55 c8             	mov    -0x38(%ebp),%edx
f01023f5:	39 55 d0             	cmp    %edx,-0x30(%ebp)
f01023f8:	72 23                	jb     f010241d <mem_init+0x11db>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01023fa:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01023fd:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0102401:	c7 44 24 08 64 43 10 	movl   $0xf0104364,0x8(%esp)
f0102408:	f0 
f0102409:	c7 44 24 04 75 03 00 	movl   $0x375,0x4(%esp)
f0102410:	00 
f0102411:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0102418:	e8 77 dc ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f010241d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102420:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0102426:	39 d0                	cmp    %edx,%eax
f0102428:	74 24                	je     f010244e <mem_init+0x120c>
f010242a:	c7 44 24 0c ba 4c 10 	movl   $0xf0104cba,0xc(%esp)
f0102431:	f0 
f0102432:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0102439:	f0 
f010243a:	c7 44 24 04 76 03 00 	movl   $0x376,0x4(%esp)
f0102441:	00 
f0102442:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0102449:	e8 46 dc ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f010244e:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f0102455:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f010245b:	89 d8                	mov    %ebx,%eax
f010245d:	2b 05 a8 89 11 f0    	sub    0xf01189a8,%eax
f0102463:	c1 f8 03             	sar    $0x3,%eax
f0102466:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102469:	89 c1                	mov    %eax,%ecx
f010246b:	c1 e9 0c             	shr    $0xc,%ecx
f010246e:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0102471:	77 20                	ja     f0102493 <mem_init+0x1251>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102473:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102477:	c7 44 24 08 64 43 10 	movl   $0xf0104364,0x8(%esp)
f010247e:	f0 
f010247f:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102486:	00 
f0102487:	c7 04 24 7c 4a 10 f0 	movl   $0xf0104a7c,(%esp)
f010248e:	e8 01 dc ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102493:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010249a:	00 
f010249b:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f01024a2:	00 
	return (void *)(pa + KERNBASE);
f01024a3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024a8:	89 04 24             	mov    %eax,(%esp)
f01024ab:	e8 96 14 00 00       	call   f0103946 <memset>
	page_free(pp0);
f01024b0:	89 1c 24             	mov    %ebx,(%esp)
f01024b3:	e8 6d ea ff ff       	call   f0100f25 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01024b8:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01024bf:	00 
f01024c0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01024c7:	00 
f01024c8:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f01024cd:	89 04 24             	mov    %eax,(%esp)
f01024d0:	e8 88 ea ff ff       	call   f0100f5d <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01024d5:	89 da                	mov    %ebx,%edx
f01024d7:	2b 15 a8 89 11 f0    	sub    0xf01189a8,%edx
f01024dd:	c1 fa 03             	sar    $0x3,%edx
f01024e0:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024e3:	89 d0                	mov    %edx,%eax
f01024e5:	c1 e8 0c             	shr    $0xc,%eax
f01024e8:	3b 05 a0 89 11 f0    	cmp    0xf01189a0,%eax
f01024ee:	72 20                	jb     f0102510 <mem_init+0x12ce>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024f0:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01024f4:	c7 44 24 08 64 43 10 	movl   $0xf0104364,0x8(%esp)
f01024fb:	f0 
f01024fc:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102503:	00 
f0102504:	c7 04 24 7c 4a 10 f0 	movl   $0xf0104a7c,(%esp)
f010250b:	e8 84 db ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0102510:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102516:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102519:	f6 82 00 00 00 f0 01 	testb  $0x1,-0x10000000(%edx)
f0102520:	75 11                	jne    f0102533 <mem_init+0x12f1>
f0102522:	8d 82 04 00 00 f0    	lea    -0xffffffc(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102528:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010252e:	f6 00 01             	testb  $0x1,(%eax)
f0102531:	74 24                	je     f0102557 <mem_init+0x1315>
f0102533:	c7 44 24 0c d2 4c 10 	movl   $0xf0104cd2,0xc(%esp)
f010253a:	f0 
f010253b:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0102542:	f0 
f0102543:	c7 44 24 04 80 03 00 	movl   $0x380,0x4(%esp)
f010254a:	00 
f010254b:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0102552:	e8 3d db ff ff       	call   f0100094 <_panic>
f0102557:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f010255a:	39 d0                	cmp    %edx,%eax
f010255c:	75 d0                	jne    f010252e <mem_init+0x12ec>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f010255e:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0102563:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102569:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// give free list back
	page_free_list = fl;
f010256f:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102572:	89 0d 80 85 11 f0    	mov    %ecx,0xf0118580

	// free the pages we took
	page_free(pp0);
f0102578:	89 1c 24             	mov    %ebx,(%esp)
f010257b:	e8 a5 e9 ff ff       	call   f0100f25 <page_free>
	page_free(pp1);
f0102580:	89 3c 24             	mov    %edi,(%esp)
f0102583:	e8 9d e9 ff ff       	call   f0100f25 <page_free>
	page_free(pp2);
f0102588:	89 34 24             	mov    %esi,(%esp)
f010258b:	e8 95 e9 ff ff       	call   f0100f25 <page_free>

	cprintf("check_page() succeeded!\n");
f0102590:	c7 04 24 e9 4c 10 f0 	movl   $0xf0104ce9,(%esp)
f0102597:	e8 b2 07 00 00       	call   f0102d4e <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:

boot_map_region(
f010259c:	a1 a8 89 11 f0       	mov    0xf01189a8,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01025a1:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01025a6:	77 20                	ja     f01025c8 <mem_init+0x1386>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01025a8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01025ac:	c7 44 24 08 4c 44 10 	movl   $0xf010444c,0x8(%esp)
f01025b3:	f0 
f01025b4:	c7 44 24 04 b1 00 00 	movl   $0xb1,0x4(%esp)
f01025bb:	00 
f01025bc:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f01025c3:	e8 cc da ff ff       	call   f0100094 <_panic>
kern_pgdir,
UPAGES,
ROUNDUP (npages * sizeof (struct Page), PGSIZE),
f01025c8:	8b 15 a0 89 11 f0    	mov    0xf01189a0,%edx
f01025ce:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
f01025d5:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:

boot_map_region(
f01025db:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
f01025e2:	00 
	return (physaddr_t)kva - KERNBASE;
f01025e3:	05 00 00 00 10       	add    $0x10000000,%eax
f01025e8:	89 04 24             	mov    %eax,(%esp)
f01025eb:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01025f0:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f01025f5:	e8 47 ea ff ff       	call   f0101041 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01025fa:	b8 00 e0 10 f0       	mov    $0xf010e000,%eax
f01025ff:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102604:	77 20                	ja     f0102626 <mem_init+0x13e4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102606:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010260a:	c7 44 24 08 4c 44 10 	movl   $0xf010444c,0x8(%esp)
f0102611:	f0 
f0102612:	c7 44 24 04 c2 00 00 	movl   $0xc2,0x4(%esp)
f0102619:	00 
f010261a:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0102621:	e8 6e da ff ff       	call   f0100094 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
boot_map_region (
f0102626:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f010262d:	00 
f010262e:	c7 04 24 00 e0 10 00 	movl   $0x10e000,(%esp)
f0102635:	b9 00 80 00 00       	mov    $0x8000,%ecx
f010263a:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f010263f:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0102644:	e8 f8 e9 ff ff       	call   f0101041 <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:

boot_map_region (
f0102649:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102650:	00 
f0102651:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102658:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f010265d:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102662:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0102667:	e8 d5 e9 ff ff       	call   f0101041 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f010266c:	8b 1d a4 89 11 f0    	mov    0xf01189a4,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
f0102672:	8b 15 a0 89 11 f0    	mov    0xf01189a0,%edx
f0102678:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f010267b:	8d 3c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%edi
	for (i = 0; i < n; i += PGSIZE)
f0102682:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
f0102688:	74 79                	je     f0102703 <mem_init+0x14c1>
f010268a:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010268f:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102695:	89 d8                	mov    %ebx,%eax
f0102697:	e8 22 e3 ff ff       	call   f01009be <check_va2pa>
f010269c:	8b 15 a8 89 11 f0    	mov    0xf01189a8,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026a2:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f01026a8:	77 20                	ja     f01026ca <mem_init+0x1488>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026aa:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01026ae:	c7 44 24 08 4c 44 10 	movl   $0xf010444c,0x8(%esp)
f01026b5:	f0 
f01026b6:	c7 44 24 04 cc 02 00 	movl   $0x2cc,0x4(%esp)
f01026bd:	00 
f01026be:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f01026c5:	e8 ca d9 ff ff       	call   f0100094 <_panic>
f01026ca:	8d 94 32 00 00 00 10 	lea    0x10000000(%edx,%esi,1),%edx
f01026d1:	39 d0                	cmp    %edx,%eax
f01026d3:	74 24                	je     f01026f9 <mem_init+0x14b7>
f01026d5:	c7 44 24 0c dc 48 10 	movl   $0xf01048dc,0xc(%esp)
f01026dc:	f0 
f01026dd:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f01026e4:	f0 
f01026e5:	c7 44 24 04 cc 02 00 	movl   $0x2cc,0x4(%esp)
f01026ec:	00 
f01026ed:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f01026f4:	e8 9b d9 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01026f9:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01026ff:	39 f7                	cmp    %esi,%edi
f0102701:	77 8c                	ja     f010268f <mem_init+0x144d>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102703:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102706:	c1 e7 0c             	shl    $0xc,%edi
f0102709:	85 ff                	test   %edi,%edi
f010270b:	74 44                	je     f0102751 <mem_init+0x150f>
f010270d:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102712:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102718:	89 d8                	mov    %ebx,%eax
f010271a:	e8 9f e2 ff ff       	call   f01009be <check_va2pa>
f010271f:	39 c6                	cmp    %eax,%esi
f0102721:	74 24                	je     f0102747 <mem_init+0x1505>
f0102723:	c7 44 24 0c 10 49 10 	movl   $0xf0104910,0xc(%esp)
f010272a:	f0 
f010272b:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0102732:	f0 
f0102733:	c7 44 24 04 d1 02 00 	movl   $0x2d1,0x4(%esp)
f010273a:	00 
f010273b:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0102742:	e8 4d d9 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102747:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010274d:	39 fe                	cmp    %edi,%esi
f010274f:	72 c1                	jb     f0102712 <mem_init+0x14d0>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102751:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f0102756:	89 d8                	mov    %ebx,%eax
f0102758:	e8 61 e2 ff ff       	call   f01009be <check_va2pa>
f010275d:	be 00 90 bf ef       	mov    $0xefbf9000,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102762:	bf 00 e0 10 f0       	mov    $0xf010e000,%edi
f0102767:	81 c7 00 70 40 20    	add    $0x20407000,%edi
f010276d:	8d 14 37             	lea    (%edi,%esi,1),%edx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102770:	39 c2                	cmp    %eax,%edx
f0102772:	74 24                	je     f0102798 <mem_init+0x1556>
f0102774:	c7 44 24 0c 38 49 10 	movl   $0xf0104938,0xc(%esp)
f010277b:	f0 
f010277c:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0102783:	f0 
f0102784:	c7 44 24 04 d5 02 00 	movl   $0x2d5,0x4(%esp)
f010278b:	00 
f010278c:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0102793:	e8 fc d8 ff ff       	call   f0100094 <_panic>
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102798:	81 fe 00 00 c0 ef    	cmp    $0xefc00000,%esi
f010279e:	0f 85 27 05 00 00    	jne    f0102ccb <mem_init+0x1a89>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01027a4:	ba 00 00 80 ef       	mov    $0xef800000,%edx
f01027a9:	89 d8                	mov    %ebx,%eax
f01027ab:	e8 0e e2 ff ff       	call   f01009be <check_va2pa>
f01027b0:	83 f8 ff             	cmp    $0xffffffff,%eax
f01027b3:	74 24                	je     f01027d9 <mem_init+0x1597>
f01027b5:	c7 44 24 0c 80 49 10 	movl   $0xf0104980,0xc(%esp)
f01027bc:	f0 
f01027bd:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f01027c4:	f0 
f01027c5:	c7 44 24 04 d6 02 00 	movl   $0x2d6,0x4(%esp)
f01027cc:	00 
f01027cd:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f01027d4:	e8 bb d8 ff ff       	call   f0100094 <_panic>
f01027d9:	b8 00 00 00 00       	mov    $0x0,%eax

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01027de:	8d 90 44 fc ff ff    	lea    -0x3bc(%eax),%edx
f01027e4:	83 fa 02             	cmp    $0x2,%edx
f01027e7:	77 2e                	ja     f0102817 <mem_init+0x15d5>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f01027e9:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f01027ed:	0f 85 aa 00 00 00    	jne    f010289d <mem_init+0x165b>
f01027f3:	c7 44 24 0c 02 4d 10 	movl   $0xf0104d02,0xc(%esp)
f01027fa:	f0 
f01027fb:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0102802:	f0 
f0102803:	c7 44 24 04 de 02 00 	movl   $0x2de,0x4(%esp)
f010280a:	00 
f010280b:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0102812:	e8 7d d8 ff ff       	call   f0100094 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102817:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010281c:	76 55                	jbe    f0102873 <mem_init+0x1631>
				assert(pgdir[i] & PTE_P);
f010281e:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0102821:	f6 c2 01             	test   $0x1,%dl
f0102824:	75 24                	jne    f010284a <mem_init+0x1608>
f0102826:	c7 44 24 0c 02 4d 10 	movl   $0xf0104d02,0xc(%esp)
f010282d:	f0 
f010282e:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0102835:	f0 
f0102836:	c7 44 24 04 e2 02 00 	movl   $0x2e2,0x4(%esp)
f010283d:	00 
f010283e:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0102845:	e8 4a d8 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f010284a:	f6 c2 02             	test   $0x2,%dl
f010284d:	75 4e                	jne    f010289d <mem_init+0x165b>
f010284f:	c7 44 24 0c 13 4d 10 	movl   $0xf0104d13,0xc(%esp)
f0102856:	f0 
f0102857:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f010285e:	f0 
f010285f:	c7 44 24 04 e3 02 00 	movl   $0x2e3,0x4(%esp)
f0102866:	00 
f0102867:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f010286e:	e8 21 d8 ff ff       	call   f0100094 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102873:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0102877:	74 24                	je     f010289d <mem_init+0x165b>
f0102879:	c7 44 24 0c 24 4d 10 	movl   $0xf0104d24,0xc(%esp)
f0102880:	f0 
f0102881:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0102888:	f0 
f0102889:	c7 44 24 04 e5 02 00 	movl   $0x2e5,0x4(%esp)
f0102890:	00 
f0102891:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0102898:	e8 f7 d7 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f010289d:	83 c0 01             	add    $0x1,%eax
f01028a0:	3d 00 04 00 00       	cmp    $0x400,%eax
f01028a5:	0f 85 33 ff ff ff    	jne    f01027de <mem_init+0x159c>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01028ab:	c7 04 24 b0 49 10 f0 	movl   $0xf01049b0,(%esp)
f01028b2:	e8 97 04 00 00       	call   f0102d4e <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01028b7:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01028bc:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01028c1:	77 20                	ja     f01028e3 <mem_init+0x16a1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028c3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01028c7:	c7 44 24 08 4c 44 10 	movl   $0xf010444c,0x8(%esp)
f01028ce:	f0 
f01028cf:	c7 44 24 04 de 00 00 	movl   $0xde,0x4(%esp)
f01028d6:	00 
f01028d7:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f01028de:	e8 b1 d7 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01028e3:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01028e8:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01028eb:	b8 00 00 00 00       	mov    $0x0,%eax
f01028f0:	e8 6c e1 ff ff       	call   f0100a61 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f01028f5:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
f01028f8:	0d 23 00 05 80       	or     $0x80050023,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f01028fd:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102900:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102903:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010290a:	e8 89 e5 ff ff       	call   f0100e98 <page_alloc>
f010290f:	89 c6                	mov    %eax,%esi
f0102911:	85 c0                	test   %eax,%eax
f0102913:	75 24                	jne    f0102939 <mem_init+0x16f7>
f0102915:	c7 44 24 0c 41 4b 10 	movl   $0xf0104b41,0xc(%esp)
f010291c:	f0 
f010291d:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0102924:	f0 
f0102925:	c7 44 24 04 9b 03 00 	movl   $0x39b,0x4(%esp)
f010292c:	00 
f010292d:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0102934:	e8 5b d7 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0102939:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102940:	e8 53 e5 ff ff       	call   f0100e98 <page_alloc>
f0102945:	89 c7                	mov    %eax,%edi
f0102947:	85 c0                	test   %eax,%eax
f0102949:	75 24                	jne    f010296f <mem_init+0x172d>
f010294b:	c7 44 24 0c 57 4b 10 	movl   $0xf0104b57,0xc(%esp)
f0102952:	f0 
f0102953:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f010295a:	f0 
f010295b:	c7 44 24 04 9c 03 00 	movl   $0x39c,0x4(%esp)
f0102962:	00 
f0102963:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f010296a:	e8 25 d7 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f010296f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102976:	e8 1d e5 ff ff       	call   f0100e98 <page_alloc>
f010297b:	89 c3                	mov    %eax,%ebx
f010297d:	85 c0                	test   %eax,%eax
f010297f:	75 24                	jne    f01029a5 <mem_init+0x1763>
f0102981:	c7 44 24 0c 6d 4b 10 	movl   $0xf0104b6d,0xc(%esp)
f0102988:	f0 
f0102989:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0102990:	f0 
f0102991:	c7 44 24 04 9d 03 00 	movl   $0x39d,0x4(%esp)
f0102998:	00 
f0102999:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f01029a0:	e8 ef d6 ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f01029a5:	89 34 24             	mov    %esi,(%esp)
f01029a8:	e8 78 e5 ff ff       	call   f0100f25 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01029ad:	89 f8                	mov    %edi,%eax
f01029af:	2b 05 a8 89 11 f0    	sub    0xf01189a8,%eax
f01029b5:	c1 f8 03             	sar    $0x3,%eax
f01029b8:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01029bb:	89 c2                	mov    %eax,%edx
f01029bd:	c1 ea 0c             	shr    $0xc,%edx
f01029c0:	3b 15 a0 89 11 f0    	cmp    0xf01189a0,%edx
f01029c6:	72 20                	jb     f01029e8 <mem_init+0x17a6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01029c8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01029cc:	c7 44 24 08 64 43 10 	movl   $0xf0104364,0x8(%esp)
f01029d3:	f0 
f01029d4:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01029db:	00 
f01029dc:	c7 04 24 7c 4a 10 f0 	movl   $0xf0104a7c,(%esp)
f01029e3:	e8 ac d6 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01029e8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01029ef:	00 
f01029f0:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01029f7:	00 
	return (void *)(pa + KERNBASE);
f01029f8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01029fd:	89 04 24             	mov    %eax,(%esp)
f0102a00:	e8 41 0f 00 00       	call   f0103946 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102a05:	89 d8                	mov    %ebx,%eax
f0102a07:	2b 05 a8 89 11 f0    	sub    0xf01189a8,%eax
f0102a0d:	c1 f8 03             	sar    $0x3,%eax
f0102a10:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a13:	89 c2                	mov    %eax,%edx
f0102a15:	c1 ea 0c             	shr    $0xc,%edx
f0102a18:	3b 15 a0 89 11 f0    	cmp    0xf01189a0,%edx
f0102a1e:	72 20                	jb     f0102a40 <mem_init+0x17fe>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a20:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102a24:	c7 44 24 08 64 43 10 	movl   $0xf0104364,0x8(%esp)
f0102a2b:	f0 
f0102a2c:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102a33:	00 
f0102a34:	c7 04 24 7c 4a 10 f0 	movl   $0xf0104a7c,(%esp)
f0102a3b:	e8 54 d6 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102a40:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102a47:	00 
f0102a48:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102a4f:	00 
	return (void *)(pa + KERNBASE);
f0102a50:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102a55:	89 04 24             	mov    %eax,(%esp)
f0102a58:	e8 e9 0e 00 00       	call   f0103946 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102a5d:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102a64:	00 
f0102a65:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102a6c:	00 
f0102a6d:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102a71:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0102a76:	89 04 24             	mov    %eax,(%esp)
f0102a79:	e8 1a e7 ff ff       	call   f0101198 <page_insert>
	assert(pp1->pp_ref == 1);
f0102a7e:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102a83:	74 24                	je     f0102aa9 <mem_init+0x1867>
f0102a85:	c7 44 24 0c 3e 4c 10 	movl   $0xf0104c3e,0xc(%esp)
f0102a8c:	f0 
f0102a8d:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0102a94:	f0 
f0102a95:	c7 44 24 04 a2 03 00 	movl   $0x3a2,0x4(%esp)
f0102a9c:	00 
f0102a9d:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0102aa4:	e8 eb d5 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102aa9:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102ab0:	01 01 01 
f0102ab3:	74 24                	je     f0102ad9 <mem_init+0x1897>
f0102ab5:	c7 44 24 0c d0 49 10 	movl   $0xf01049d0,0xc(%esp)
f0102abc:	f0 
f0102abd:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0102ac4:	f0 
f0102ac5:	c7 44 24 04 a3 03 00 	movl   $0x3a3,0x4(%esp)
f0102acc:	00 
f0102acd:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0102ad4:	e8 bb d5 ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102ad9:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102ae0:	00 
f0102ae1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102ae8:	00 
f0102ae9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102aed:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0102af2:	89 04 24             	mov    %eax,(%esp)
f0102af5:	e8 9e e6 ff ff       	call   f0101198 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102afa:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102b01:	02 02 02 
f0102b04:	74 24                	je     f0102b2a <mem_init+0x18e8>
f0102b06:	c7 44 24 0c f4 49 10 	movl   $0xf01049f4,0xc(%esp)
f0102b0d:	f0 
f0102b0e:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0102b15:	f0 
f0102b16:	c7 44 24 04 a5 03 00 	movl   $0x3a5,0x4(%esp)
f0102b1d:	00 
f0102b1e:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0102b25:	e8 6a d5 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102b2a:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102b2f:	74 24                	je     f0102b55 <mem_init+0x1913>
f0102b31:	c7 44 24 0c 60 4c 10 	movl   $0xf0104c60,0xc(%esp)
f0102b38:	f0 
f0102b39:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0102b40:	f0 
f0102b41:	c7 44 24 04 a6 03 00 	movl   $0x3a6,0x4(%esp)
f0102b48:	00 
f0102b49:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0102b50:	e8 3f d5 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102b55:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102b5a:	74 24                	je     f0102b80 <mem_init+0x193e>
f0102b5c:	c7 44 24 0c a9 4c 10 	movl   $0xf0104ca9,0xc(%esp)
f0102b63:	f0 
f0102b64:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0102b6b:	f0 
f0102b6c:	c7 44 24 04 a7 03 00 	movl   $0x3a7,0x4(%esp)
f0102b73:	00 
f0102b74:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0102b7b:	e8 14 d5 ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102b80:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102b87:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102b8a:	89 d8                	mov    %ebx,%eax
f0102b8c:	2b 05 a8 89 11 f0    	sub    0xf01189a8,%eax
f0102b92:	c1 f8 03             	sar    $0x3,%eax
f0102b95:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b98:	89 c2                	mov    %eax,%edx
f0102b9a:	c1 ea 0c             	shr    $0xc,%edx
f0102b9d:	3b 15 a0 89 11 f0    	cmp    0xf01189a0,%edx
f0102ba3:	72 20                	jb     f0102bc5 <mem_init+0x1983>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102ba5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102ba9:	c7 44 24 08 64 43 10 	movl   $0xf0104364,0x8(%esp)
f0102bb0:	f0 
f0102bb1:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102bb8:	00 
f0102bb9:	c7 04 24 7c 4a 10 f0 	movl   $0xf0104a7c,(%esp)
f0102bc0:	e8 cf d4 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102bc5:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102bcc:	03 03 03 
f0102bcf:	74 24                	je     f0102bf5 <mem_init+0x19b3>
f0102bd1:	c7 44 24 0c 18 4a 10 	movl   $0xf0104a18,0xc(%esp)
f0102bd8:	f0 
f0102bd9:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0102be0:	f0 
f0102be1:	c7 44 24 04 a9 03 00 	movl   $0x3a9,0x4(%esp)
f0102be8:	00 
f0102be9:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0102bf0:	e8 9f d4 ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102bf5:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102bfc:	00 
f0102bfd:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0102c02:	89 04 24             	mov    %eax,(%esp)
f0102c05:	e8 3a e5 ff ff       	call   f0101144 <page_remove>
	assert(pp2->pp_ref == 0);
f0102c0a:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102c0f:	74 24                	je     f0102c35 <mem_init+0x19f3>
f0102c11:	c7 44 24 0c 98 4c 10 	movl   $0xf0104c98,0xc(%esp)
f0102c18:	f0 
f0102c19:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0102c20:	f0 
f0102c21:	c7 44 24 04 ab 03 00 	movl   $0x3ab,0x4(%esp)
f0102c28:	00 
f0102c29:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0102c30:	e8 5f d4 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102c35:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0102c3a:	8b 08                	mov    (%eax),%ecx
f0102c3c:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102c42:	89 f2                	mov    %esi,%edx
f0102c44:	2b 15 a8 89 11 f0    	sub    0xf01189a8,%edx
f0102c4a:	c1 fa 03             	sar    $0x3,%edx
f0102c4d:	c1 e2 0c             	shl    $0xc,%edx
f0102c50:	39 d1                	cmp    %edx,%ecx
f0102c52:	74 24                	je     f0102c78 <mem_init+0x1a36>
f0102c54:	c7 44 24 0c c8 45 10 	movl   $0xf01045c8,0xc(%esp)
f0102c5b:	f0 
f0102c5c:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0102c63:	f0 
f0102c64:	c7 44 24 04 ae 03 00 	movl   $0x3ae,0x4(%esp)
f0102c6b:	00 
f0102c6c:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0102c73:	e8 1c d4 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102c78:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102c7e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102c83:	74 24                	je     f0102ca9 <mem_init+0x1a67>
f0102c85:	c7 44 24 0c 4f 4c 10 	movl   $0xf0104c4f,0xc(%esp)
f0102c8c:	f0 
f0102c8d:	c7 44 24 08 96 4a 10 	movl   $0xf0104a96,0x8(%esp)
f0102c94:	f0 
f0102c95:	c7 44 24 04 b0 03 00 	movl   $0x3b0,0x4(%esp)
f0102c9c:	00 
f0102c9d:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0102ca4:	e8 eb d3 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102ca9:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102caf:	89 34 24             	mov    %esi,(%esp)
f0102cb2:	e8 6e e2 ff ff       	call   f0100f25 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102cb7:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0102cbe:	e8 8b 00 00 00       	call   f0102d4e <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102cc3:	83 c4 3c             	add    $0x3c,%esp
f0102cc6:	5b                   	pop    %ebx
f0102cc7:	5e                   	pop    %esi
f0102cc8:	5f                   	pop    %edi
f0102cc9:	5d                   	pop    %ebp
f0102cca:	c3                   	ret    
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102ccb:	89 f2                	mov    %esi,%edx
f0102ccd:	89 d8                	mov    %ebx,%eax
f0102ccf:	e8 ea dc ff ff       	call   f01009be <check_va2pa>
f0102cd4:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102cda:	e9 8e fa ff ff       	jmp    f010276d <mem_init+0x152b>
	...

f0102ce0 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102ce0:	55                   	push   %ebp
f0102ce1:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102ce3:	ba 70 00 00 00       	mov    $0x70,%edx
f0102ce8:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ceb:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102cec:	b2 71                	mov    $0x71,%dl
f0102cee:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102cef:	0f b6 c0             	movzbl %al,%eax
}
f0102cf2:	5d                   	pop    %ebp
f0102cf3:	c3                   	ret    

f0102cf4 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102cf4:	55                   	push   %ebp
f0102cf5:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102cf7:	ba 70 00 00 00       	mov    $0x70,%edx
f0102cfc:	8b 45 08             	mov    0x8(%ebp),%eax
f0102cff:	ee                   	out    %al,(%dx)
f0102d00:	b2 71                	mov    $0x71,%dl
f0102d02:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d05:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102d06:	5d                   	pop    %ebp
f0102d07:	c3                   	ret    

f0102d08 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102d08:	55                   	push   %ebp
f0102d09:	89 e5                	mov    %esp,%ebp
f0102d0b:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0102d0e:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d11:	89 04 24             	mov    %eax,(%esp)
f0102d14:	e8 d8 d8 ff ff       	call   f01005f1 <cputchar>
	*cnt++;
}
f0102d19:	c9                   	leave  
f0102d1a:	c3                   	ret    

f0102d1b <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102d1b:	55                   	push   %ebp
f0102d1c:	89 e5                	mov    %esp,%ebp
f0102d1e:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0102d21:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102d28:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d2b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102d2f:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d32:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102d36:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102d39:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d3d:	c7 04 24 08 2d 10 f0 	movl   $0xf0102d08,(%esp)
f0102d44:	e8 61 04 00 00       	call   f01031aa <vprintfmt>
	return cnt;
}
f0102d49:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102d4c:	c9                   	leave  
f0102d4d:	c3                   	ret    

f0102d4e <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102d4e:	55                   	push   %ebp
f0102d4f:	89 e5                	mov    %esp,%ebp
f0102d51:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102d54:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102d57:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d5b:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d5e:	89 04 24             	mov    %eax,(%esp)
f0102d61:	e8 b5 ff ff ff       	call   f0102d1b <vcprintf>
	va_end(ap);

	return cnt;
}
f0102d66:	c9                   	leave  
f0102d67:	c3                   	ret    

f0102d68 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102d68:	55                   	push   %ebp
f0102d69:	89 e5                	mov    %esp,%ebp
f0102d6b:	57                   	push   %edi
f0102d6c:	56                   	push   %esi
f0102d6d:	53                   	push   %ebx
f0102d6e:	83 ec 10             	sub    $0x10,%esp
f0102d71:	89 c3                	mov    %eax,%ebx
f0102d73:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0102d76:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0102d79:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102d7c:	8b 0a                	mov    (%edx),%ecx
f0102d7e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102d81:	8b 00                	mov    (%eax),%eax
f0102d83:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102d86:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f0102d8d:	eb 77                	jmp    f0102e06 <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f0102d8f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102d92:	01 c8                	add    %ecx,%eax
f0102d94:	bf 02 00 00 00       	mov    $0x2,%edi
f0102d99:	99                   	cltd   
f0102d9a:	f7 ff                	idiv   %edi
f0102d9c:	89 c2                	mov    %eax,%edx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102d9e:	eb 01                	jmp    f0102da1 <stab_binsearch+0x39>
			m--;
f0102da0:	4a                   	dec    %edx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102da1:	39 ca                	cmp    %ecx,%edx
f0102da3:	7c 1d                	jl     f0102dc2 <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0102da5:	6b fa 0c             	imul   $0xc,%edx,%edi
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102da8:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f0102dad:	39 f7                	cmp    %esi,%edi
f0102daf:	75 ef                	jne    f0102da0 <stab_binsearch+0x38>
f0102db1:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102db4:	6b fa 0c             	imul   $0xc,%edx,%edi
f0102db7:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f0102dbb:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0102dbe:	73 18                	jae    f0102dd8 <stab_binsearch+0x70>
f0102dc0:	eb 05                	jmp    f0102dc7 <stab_binsearch+0x5f>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102dc2:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0102dc5:	eb 3f                	jmp    f0102e06 <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0102dc7:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0102dca:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0102dcc:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102dcf:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102dd6:	eb 2e                	jmp    f0102e06 <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102dd8:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0102ddb:	76 15                	jbe    f0102df2 <stab_binsearch+0x8a>
			*region_right = m - 1;
f0102ddd:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0102de0:	4f                   	dec    %edi
f0102de1:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0102de4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102de7:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102de9:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102df0:	eb 14                	jmp    f0102e06 <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102df2:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0102df5:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0102df8:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f0102dfa:	ff 45 0c             	incl   0xc(%ebp)
f0102dfd:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102dff:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0102e06:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0102e09:	7e 84                	jle    f0102d8f <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102e0b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0102e0f:	75 0d                	jne    f0102e1e <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0102e11:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102e14:	8b 02                	mov    (%edx),%eax
f0102e16:	48                   	dec    %eax
f0102e17:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102e1a:	89 01                	mov    %eax,(%ecx)
f0102e1c:	eb 22                	jmp    f0102e40 <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102e1e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102e21:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102e23:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102e26:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102e28:	eb 01                	jmp    f0102e2b <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102e2a:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102e2b:	39 c1                	cmp    %eax,%ecx
f0102e2d:	7d 0c                	jge    f0102e3b <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0102e2f:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0102e32:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f0102e37:	39 f2                	cmp    %esi,%edx
f0102e39:	75 ef                	jne    f0102e2a <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102e3b:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102e3e:	89 02                	mov    %eax,(%edx)
	}
}
f0102e40:	83 c4 10             	add    $0x10,%esp
f0102e43:	5b                   	pop    %ebx
f0102e44:	5e                   	pop    %esi
f0102e45:	5f                   	pop    %edi
f0102e46:	5d                   	pop    %ebp
f0102e47:	c3                   	ret    

f0102e48 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102e48:	55                   	push   %ebp
f0102e49:	89 e5                	mov    %esp,%ebp
f0102e4b:	83 ec 38             	sub    $0x38,%esp
f0102e4e:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0102e51:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0102e54:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0102e57:	8b 75 08             	mov    0x8(%ebp),%esi
f0102e5a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102e5d:	c7 03 24 41 10 f0    	movl   $0xf0104124,(%ebx)
	info->eip_line = 0;
f0102e63:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102e6a:	c7 43 08 24 41 10 f0 	movl   $0xf0104124,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102e71:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102e78:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102e7b:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102e82:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102e88:	76 12                	jbe    f0102e9c <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102e8a:	b8 49 d0 10 f0       	mov    $0xf010d049,%eax
f0102e8f:	3d 15 b2 10 f0       	cmp    $0xf010b215,%eax
f0102e94:	0f 86 9b 01 00 00    	jbe    f0103035 <debuginfo_eip+0x1ed>
f0102e9a:	eb 1c                	jmp    f0102eb8 <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102e9c:	c7 44 24 08 32 4d 10 	movl   $0xf0104d32,0x8(%esp)
f0102ea3:	f0 
f0102ea4:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0102eab:	00 
f0102eac:	c7 04 24 3f 4d 10 f0 	movl   $0xf0104d3f,(%esp)
f0102eb3:	e8 dc d1 ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102eb8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102ebd:	80 3d 48 d0 10 f0 00 	cmpb   $0x0,0xf010d048
f0102ec4:	0f 85 77 01 00 00    	jne    f0103041 <debuginfo_eip+0x1f9>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102eca:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102ed1:	b8 14 b2 10 f0       	mov    $0xf010b214,%eax
f0102ed6:	2d 5c 4f 10 f0       	sub    $0xf0104f5c,%eax
f0102edb:	c1 f8 02             	sar    $0x2,%eax
f0102ede:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102ee4:	83 e8 01             	sub    $0x1,%eax
f0102ee7:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102eea:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102eee:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0102ef5:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102ef8:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102efb:	b8 5c 4f 10 f0       	mov    $0xf0104f5c,%eax
f0102f00:	e8 63 fe ff ff       	call   f0102d68 <stab_binsearch>
	if (lfile == 0)
f0102f05:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0102f08:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0102f0d:	85 d2                	test   %edx,%edx
f0102f0f:	0f 84 2c 01 00 00    	je     f0103041 <debuginfo_eip+0x1f9>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102f15:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0102f18:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102f1b:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102f1e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102f22:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0102f29:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102f2c:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102f2f:	b8 5c 4f 10 f0       	mov    $0xf0104f5c,%eax
f0102f34:	e8 2f fe ff ff       	call   f0102d68 <stab_binsearch>

	if (lfun <= rfun) {
f0102f39:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0102f3c:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0102f3f:	7f 2e                	jg     f0102f6f <debuginfo_eip+0x127>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102f41:	6b c7 0c             	imul   $0xc,%edi,%eax
f0102f44:	8d 90 5c 4f 10 f0    	lea    -0xfefb0a4(%eax),%edx
f0102f4a:	8b 80 5c 4f 10 f0    	mov    -0xfefb0a4(%eax),%eax
f0102f50:	b9 49 d0 10 f0       	mov    $0xf010d049,%ecx
f0102f55:	81 e9 15 b2 10 f0    	sub    $0xf010b215,%ecx
f0102f5b:	39 c8                	cmp    %ecx,%eax
f0102f5d:	73 08                	jae    f0102f67 <debuginfo_eip+0x11f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102f5f:	05 15 b2 10 f0       	add    $0xf010b215,%eax
f0102f64:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102f67:	8b 42 08             	mov    0x8(%edx),%eax
f0102f6a:	89 43 10             	mov    %eax,0x10(%ebx)
f0102f6d:	eb 06                	jmp    f0102f75 <debuginfo_eip+0x12d>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102f6f:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102f72:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102f75:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0102f7c:	00 
f0102f7d:	8b 43 08             	mov    0x8(%ebx),%eax
f0102f80:	89 04 24             	mov    %eax,(%esp)
f0102f83:	e8 97 09 00 00       	call   f010391f <strfind>
f0102f88:	2b 43 08             	sub    0x8(%ebx),%eax
f0102f8b:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102f8e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102f91:	39 d7                	cmp    %edx,%edi
f0102f93:	7c 5f                	jl     f0102ff4 <debuginfo_eip+0x1ac>
	       && stabs[lline].n_type != N_SOL
f0102f95:	89 f8                	mov    %edi,%eax
f0102f97:	6b cf 0c             	imul   $0xc,%edi,%ecx
f0102f9a:	80 b9 60 4f 10 f0 84 	cmpb   $0x84,-0xfefb0a0(%ecx)
f0102fa1:	75 18                	jne    f0102fbb <debuginfo_eip+0x173>
f0102fa3:	eb 30                	jmp    f0102fd5 <debuginfo_eip+0x18d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0102fa5:	83 ef 01             	sub    $0x1,%edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102fa8:	39 fa                	cmp    %edi,%edx
f0102faa:	7f 48                	jg     f0102ff4 <debuginfo_eip+0x1ac>
	       && stabs[lline].n_type != N_SOL
f0102fac:	89 f8                	mov    %edi,%eax
f0102fae:	8d 0c 7f             	lea    (%edi,%edi,2),%ecx
f0102fb1:	80 3c 8d 60 4f 10 f0 	cmpb   $0x84,-0xfefb0a0(,%ecx,4)
f0102fb8:	84 
f0102fb9:	74 1a                	je     f0102fd5 <debuginfo_eip+0x18d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102fbb:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102fbe:	8d 04 85 5c 4f 10 f0 	lea    -0xfefb0a4(,%eax,4),%eax
f0102fc5:	80 78 04 64          	cmpb   $0x64,0x4(%eax)
f0102fc9:	75 da                	jne    f0102fa5 <debuginfo_eip+0x15d>
f0102fcb:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0102fcf:	74 d4                	je     f0102fa5 <debuginfo_eip+0x15d>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102fd1:	39 fa                	cmp    %edi,%edx
f0102fd3:	7f 1f                	jg     f0102ff4 <debuginfo_eip+0x1ac>
f0102fd5:	6b ff 0c             	imul   $0xc,%edi,%edi
f0102fd8:	8b 87 5c 4f 10 f0    	mov    -0xfefb0a4(%edi),%eax
f0102fde:	ba 49 d0 10 f0       	mov    $0xf010d049,%edx
f0102fe3:	81 ea 15 b2 10 f0    	sub    $0xf010b215,%edx
f0102fe9:	39 d0                	cmp    %edx,%eax
f0102feb:	73 07                	jae    f0102ff4 <debuginfo_eip+0x1ac>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102fed:	05 15 b2 10 f0       	add    $0xf010b215,%eax
f0102ff2:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102ff4:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102ff7:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0102ffa:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102fff:	39 ca                	cmp    %ecx,%edx
f0103001:	7d 3e                	jge    f0103041 <debuginfo_eip+0x1f9>
		for (lline = lfun + 1;
f0103003:	83 c2 01             	add    $0x1,%edx
f0103006:	39 d1                	cmp    %edx,%ecx
f0103008:	7e 37                	jle    f0103041 <debuginfo_eip+0x1f9>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010300a:	6b f2 0c             	imul   $0xc,%edx,%esi
f010300d:	80 be 60 4f 10 f0 a0 	cmpb   $0xa0,-0xfefb0a0(%esi)
f0103014:	75 2b                	jne    f0103041 <debuginfo_eip+0x1f9>
		     lline++)
			info->eip_fn_narg++;
f0103016:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f010301a:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f010301d:	39 d1                	cmp    %edx,%ecx
f010301f:	7e 1b                	jle    f010303c <debuginfo_eip+0x1f4>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103021:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0103024:	80 3c 85 60 4f 10 f0 	cmpb   $0xa0,-0xfefb0a0(,%eax,4)
f010302b:	a0 
f010302c:	74 e8                	je     f0103016 <debuginfo_eip+0x1ce>
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f010302e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103033:	eb 0c                	jmp    f0103041 <debuginfo_eip+0x1f9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103035:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010303a:	eb 05                	jmp    f0103041 <debuginfo_eip+0x1f9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f010303c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103041:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0103044:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0103047:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010304a:	89 ec                	mov    %ebp,%esp
f010304c:	5d                   	pop    %ebp
f010304d:	c3                   	ret    
	...

f0103050 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103050:	55                   	push   %ebp
f0103051:	89 e5                	mov    %esp,%ebp
f0103053:	57                   	push   %edi
f0103054:	56                   	push   %esi
f0103055:	53                   	push   %ebx
f0103056:	83 ec 3c             	sub    $0x3c,%esp
f0103059:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010305c:	89 d7                	mov    %edx,%edi
f010305e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103061:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103064:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103067:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010306a:	8b 5d 14             	mov    0x14(%ebp),%ebx
f010306d:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103070:	b8 00 00 00 00       	mov    $0x0,%eax
f0103075:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0103078:	72 11                	jb     f010308b <printnum+0x3b>
f010307a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010307d:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103080:	76 09                	jbe    f010308b <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103082:	83 eb 01             	sub    $0x1,%ebx
f0103085:	85 db                	test   %ebx,%ebx
f0103087:	7f 51                	jg     f01030da <printnum+0x8a>
f0103089:	eb 5e                	jmp    f01030e9 <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010308b:	89 74 24 10          	mov    %esi,0x10(%esp)
f010308f:	83 eb 01             	sub    $0x1,%ebx
f0103092:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103096:	8b 45 10             	mov    0x10(%ebp),%eax
f0103099:	89 44 24 08          	mov    %eax,0x8(%esp)
f010309d:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f01030a1:	8b 74 24 0c          	mov    0xc(%esp),%esi
f01030a5:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01030ac:	00 
f01030ad:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01030b0:	89 04 24             	mov    %eax,(%esp)
f01030b3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01030b6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01030ba:	e8 e1 0a 00 00       	call   f0103ba0 <__udivdi3>
f01030bf:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01030c3:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01030c7:	89 04 24             	mov    %eax,(%esp)
f01030ca:	89 54 24 04          	mov    %edx,0x4(%esp)
f01030ce:	89 fa                	mov    %edi,%edx
f01030d0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01030d3:	e8 78 ff ff ff       	call   f0103050 <printnum>
f01030d8:	eb 0f                	jmp    f01030e9 <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01030da:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01030de:	89 34 24             	mov    %esi,(%esp)
f01030e1:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01030e4:	83 eb 01             	sub    $0x1,%ebx
f01030e7:	75 f1                	jne    f01030da <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01030e9:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01030ed:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01030f1:	8b 45 10             	mov    0x10(%ebp),%eax
f01030f4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01030f8:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01030ff:	00 
f0103100:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103103:	89 04 24             	mov    %eax,(%esp)
f0103106:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103109:	89 44 24 04          	mov    %eax,0x4(%esp)
f010310d:	e8 be 0b 00 00       	call   f0103cd0 <__umoddi3>
f0103112:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103116:	0f be 80 4d 4d 10 f0 	movsbl -0xfefb2b3(%eax),%eax
f010311d:	89 04 24             	mov    %eax,(%esp)
f0103120:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0103123:	83 c4 3c             	add    $0x3c,%esp
f0103126:	5b                   	pop    %ebx
f0103127:	5e                   	pop    %esi
f0103128:	5f                   	pop    %edi
f0103129:	5d                   	pop    %ebp
f010312a:	c3                   	ret    

f010312b <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f010312b:	55                   	push   %ebp
f010312c:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f010312e:	83 fa 01             	cmp    $0x1,%edx
f0103131:	7e 0e                	jle    f0103141 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103133:	8b 10                	mov    (%eax),%edx
f0103135:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103138:	89 08                	mov    %ecx,(%eax)
f010313a:	8b 02                	mov    (%edx),%eax
f010313c:	8b 52 04             	mov    0x4(%edx),%edx
f010313f:	eb 22                	jmp    f0103163 <getuint+0x38>
	else if (lflag)
f0103141:	85 d2                	test   %edx,%edx
f0103143:	74 10                	je     f0103155 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103145:	8b 10                	mov    (%eax),%edx
f0103147:	8d 4a 04             	lea    0x4(%edx),%ecx
f010314a:	89 08                	mov    %ecx,(%eax)
f010314c:	8b 02                	mov    (%edx),%eax
f010314e:	ba 00 00 00 00       	mov    $0x0,%edx
f0103153:	eb 0e                	jmp    f0103163 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103155:	8b 10                	mov    (%eax),%edx
f0103157:	8d 4a 04             	lea    0x4(%edx),%ecx
f010315a:	89 08                	mov    %ecx,(%eax)
f010315c:	8b 02                	mov    (%edx),%eax
f010315e:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103163:	5d                   	pop    %ebp
f0103164:	c3                   	ret    

f0103165 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103165:	55                   	push   %ebp
f0103166:	89 e5                	mov    %esp,%ebp
f0103168:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010316b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f010316f:	8b 10                	mov    (%eax),%edx
f0103171:	3b 50 04             	cmp    0x4(%eax),%edx
f0103174:	73 0a                	jae    f0103180 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103176:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103179:	88 0a                	mov    %cl,(%edx)
f010317b:	83 c2 01             	add    $0x1,%edx
f010317e:	89 10                	mov    %edx,(%eax)
}
f0103180:	5d                   	pop    %ebp
f0103181:	c3                   	ret    

f0103182 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103182:	55                   	push   %ebp
f0103183:	89 e5                	mov    %esp,%ebp
f0103185:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0103188:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010318b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010318f:	8b 45 10             	mov    0x10(%ebp),%eax
f0103192:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103196:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103199:	89 44 24 04          	mov    %eax,0x4(%esp)
f010319d:	8b 45 08             	mov    0x8(%ebp),%eax
f01031a0:	89 04 24             	mov    %eax,(%esp)
f01031a3:	e8 02 00 00 00       	call   f01031aa <vprintfmt>
	va_end(ap);
}
f01031a8:	c9                   	leave  
f01031a9:	c3                   	ret    

f01031aa <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01031aa:	55                   	push   %ebp
f01031ab:	89 e5                	mov    %esp,%ebp
f01031ad:	57                   	push   %edi
f01031ae:	56                   	push   %esi
f01031af:	53                   	push   %ebx
f01031b0:	83 ec 3c             	sub    $0x3c,%esp
f01031b3:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01031b6:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f01031b9:	e9 bb 00 00 00       	jmp    f0103279 <vprintfmt+0xcf>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01031be:	85 c0                	test   %eax,%eax
f01031c0:	0f 84 63 04 00 00    	je     f0103629 <vprintfmt+0x47f>
				return;
			if (ch =='\033'){//if this is Escape character  and this if is char color set.
f01031c6:	83 f8 1b             	cmp    $0x1b,%eax
f01031c9:	0f 85 9a 00 00 00    	jne    f0103269 <vprintfmt+0xbf>
				int temp_color_no=0;
				ch = *(unsigned char *) fmt++;
f01031cf:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01031d2:	83 c3 02             	add    $0x2,%ebx
				while (ch != 'm') 
f01031d5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01031d8:	80 78 01 6d          	cmpb   $0x6d,0x1(%eax)
f01031dc:	0f 84 81 00 00 00    	je     f0103263 <vprintfmt+0xb9>
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
				return;
			if (ch =='\033'){//if this is Escape character  and this if is char color set.
				int temp_color_no=0;
f01031e2:	ba 00 00 00 00       	mov    $0x0,%edx
				ch = *(unsigned char *) fmt++;
				while (ch != 'm') 
				{
					ch = *(unsigned char *) fmt++;
f01031e7:	0f b6 03             	movzbl (%ebx),%eax
f01031ea:	83 c3 01             	add    $0x1,%ebx
					if ( ch !=';' && ch!='m')
f01031ed:	83 f8 6d             	cmp    $0x6d,%eax
f01031f0:	0f 95 c1             	setne  %cl
f01031f3:	83 f8 3b             	cmp    $0x3b,%eax
f01031f6:	74 0d                	je     f0103205 <vprintfmt+0x5b>
f01031f8:	84 c9                	test   %cl,%cl
f01031fa:	74 09                	je     f0103205 <vprintfmt+0x5b>
						temp_color_no=temp_color_no*10+ch-'0';
f01031fc:	8d 14 92             	lea    (%edx,%edx,4),%edx
f01031ff:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
f0103203:	eb 55                	jmp    f010325a <vprintfmt+0xb0>
					else if ( ch==';' || ch=='m'){
f0103205:	83 f8 3b             	cmp    $0x3b,%eax
f0103208:	74 05                	je     f010320f <vprintfmt+0x65>
f010320a:	83 f8 6d             	cmp    $0x6d,%eax
f010320d:	75 4b                	jne    f010325a <vprintfmt+0xb0>
						if ( temp_color_no >=30 && temp_color_no<40){// Foreground colors
f010320f:	89 d6                	mov    %edx,%esi
f0103211:	8d 7a e2             	lea    -0x1e(%edx),%edi
f0103214:	83 ff 09             	cmp    $0x9,%edi
f0103217:	77 16                	ja     f010322f <vprintfmt+0x85>
							char_color = (char_color&0xf0) + (temp_color_no-30);						
f0103219:	8b 3d 00 83 11 f0    	mov    0xf0118300,%edi
f010321f:	81 e7 f0 00 00 00    	and    $0xf0,%edi
f0103225:	8d 7c 3a e2          	lea    -0x1e(%edx,%edi,1),%edi
f0103229:	89 3d 00 83 11 f0    	mov    %edi,0xf0118300
							}
						if ( temp_color_no >=40 && temp_color_no<50){// Background colors
f010322f:	83 ee 28             	sub    $0x28,%esi
f0103232:	83 fe 09             	cmp    $0x9,%esi
f0103235:	77 1e                	ja     f0103255 <vprintfmt+0xab>
							char_color = (char_color&0x0f) + ((temp_color_no-40)<<4);
f0103237:	8b 35 00 83 11 f0    	mov    0xf0118300,%esi
f010323d:	83 e6 0f             	and    $0xf,%esi
f0103240:	83 ea 28             	sub    $0x28,%edx
f0103243:	c1 e2 04             	shl    $0x4,%edx
f0103246:	01 f2                	add    %esi,%edx
f0103248:	89 15 00 83 11 f0    	mov    %edx,0xf0118300
						}
						//cprintf("0x%o ,",char_color);
						temp_color_no=0;
f010324e:	ba 00 00 00 00       	mov    $0x0,%edx
f0103253:	eb 05                	jmp    f010325a <vprintfmt+0xb0>
f0103255:	ba 00 00 00 00       	mov    $0x0,%edx
			if (ch == '\0')
				return;
			if (ch =='\033'){//if this is Escape character  and this if is char color set.
				int temp_color_no=0;
				ch = *(unsigned char *) fmt++;
				while (ch != 'm') 
f010325a:	84 c9                	test   %cl,%cl
f010325c:	75 89                	jne    f01031e7 <vprintfmt+0x3d>
						}
						//cprintf("0x%o ,",char_color);
						temp_color_no=0;
					}
				}
				if (ch == 'm')
f010325e:	83 f8 6d             	cmp    $0x6d,%eax
f0103261:	75 06                	jne    f0103269 <vprintfmt+0xbf>
					ch = *(unsigned char *) fmt++;
f0103263:	0f b6 03             	movzbl (%ebx),%eax
f0103266:	83 c3 01             	add    $0x1,%ebx
				
			}
			putch(ch, putdat);
f0103269:	8b 55 0c             	mov    0xc(%ebp),%edx
f010326c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103270:	89 04 24             	mov    %eax,(%esp)
f0103273:	ff 55 08             	call   *0x8(%ebp)
f0103276:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103279:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010327c:	0f b6 03             	movzbl (%ebx),%eax
f010327f:	83 c3 01             	add    $0x1,%ebx
f0103282:	83 f8 25             	cmp    $0x25,%eax
f0103285:	0f 85 33 ff ff ff    	jne    f01031be <vprintfmt+0x14>
f010328b:	c6 45 e0 20          	movb   $0x20,-0x20(%ebp)
f010328f:	bf 00 00 00 00       	mov    $0x0,%edi
f0103294:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0103299:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f01032a0:	b9 00 00 00 00       	mov    $0x0,%ecx
f01032a5:	eb 23                	jmp    f01032ca <vprintfmt+0x120>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032a7:	89 c3                	mov    %eax,%ebx

		// flag to pad on the right
		case '-':
			padc = '-';
f01032a9:	c6 45 e0 2d          	movb   $0x2d,-0x20(%ebp)
f01032ad:	eb 1b                	jmp    f01032ca <vprintfmt+0x120>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032af:	89 c3                	mov    %eax,%ebx
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01032b1:	c6 45 e0 30          	movb   $0x30,-0x20(%ebp)
f01032b5:	eb 13                	jmp    f01032ca <vprintfmt+0x120>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032b7:	89 c3                	mov    %eax,%ebx
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f01032b9:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f01032c0:	eb 08                	jmp    f01032ca <vprintfmt+0x120>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f01032c2:	89 75 dc             	mov    %esi,-0x24(%ebp)
f01032c5:	be ff ff ff ff       	mov    $0xffffffff,%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032ca:	0f b6 13             	movzbl (%ebx),%edx
f01032cd:	0f b6 c2             	movzbl %dl,%eax
f01032d0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01032d3:	8d 43 01             	lea    0x1(%ebx),%eax
f01032d6:	83 ea 23             	sub    $0x23,%edx
f01032d9:	80 fa 55             	cmp    $0x55,%dl
f01032dc:	0f 87 18 03 00 00    	ja     f01035fa <vprintfmt+0x450>
f01032e2:	0f b6 d2             	movzbl %dl,%edx
f01032e5:	ff 24 95 d8 4d 10 f0 	jmp    *-0xfefb228(,%edx,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01032ec:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01032ef:	83 ee 30             	sub    $0x30,%esi
				ch = *fmt;
f01032f2:	0f be 53 01          	movsbl 0x1(%ebx),%edx
				if (ch < '0' || ch > '9')
f01032f6:	8d 5a d0             	lea    -0x30(%edx),%ebx
f01032f9:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032fc:	89 c3                	mov    %eax,%ebx
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f01032fe:	83 7d e4 09          	cmpl   $0x9,-0x1c(%ebp)
f0103302:	77 3b                	ja     f010333f <vprintfmt+0x195>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103304:	83 c0 01             	add    $0x1,%eax
				precision = precision * 10 + ch - '0';
f0103307:	8d 1c b6             	lea    (%esi,%esi,4),%ebx
f010330a:	8d 74 5a d0          	lea    -0x30(%edx,%ebx,2),%esi
				ch = *fmt;
f010330e:	0f be 10             	movsbl (%eax),%edx
				if (ch < '0' || ch > '9')
f0103311:	8d 5a d0             	lea    -0x30(%edx),%ebx
f0103314:	83 fb 09             	cmp    $0x9,%ebx
f0103317:	76 eb                	jbe    f0103304 <vprintfmt+0x15a>
f0103319:	eb 22                	jmp    f010333d <vprintfmt+0x193>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f010331b:	8b 55 14             	mov    0x14(%ebp),%edx
f010331e:	8d 5a 04             	lea    0x4(%edx),%ebx
f0103321:	89 5d 14             	mov    %ebx,0x14(%ebp)
f0103324:	8b 32                	mov    (%edx),%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103326:	89 c3                	mov    %eax,%ebx
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103328:	eb 15                	jmp    f010333f <vprintfmt+0x195>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010332a:	89 c3                	mov    %eax,%ebx
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f010332c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103330:	79 98                	jns    f01032ca <vprintfmt+0x120>
f0103332:	eb 83                	jmp    f01032b7 <vprintfmt+0x10d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103334:	89 c3                	mov    %eax,%ebx
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103336:	bf 01 00 00 00       	mov    $0x1,%edi
			goto reswitch;
f010333b:	eb 8d                	jmp    f01032ca <vprintfmt+0x120>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f010333d:	89 c3                	mov    %eax,%ebx
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f010333f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103343:	79 85                	jns    f01032ca <vprintfmt+0x120>
f0103345:	e9 78 ff ff ff       	jmp    f01032c2 <vprintfmt+0x118>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f010334a:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010334d:	89 c3                	mov    %eax,%ebx
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010334f:	e9 76 ff ff ff       	jmp    f01032ca <vprintfmt+0x120>
f0103354:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103357:	8b 45 14             	mov    0x14(%ebp),%eax
f010335a:	8d 50 04             	lea    0x4(%eax),%edx
f010335d:	89 55 14             	mov    %edx,0x14(%ebp)
f0103360:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103363:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103367:	8b 00                	mov    (%eax),%eax
f0103369:	89 04 24             	mov    %eax,(%esp)
f010336c:	ff 55 08             	call   *0x8(%ebp)
			break;
f010336f:	e9 05 ff ff ff       	jmp    f0103279 <vprintfmt+0xcf>
f0103374:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103377:	8b 45 14             	mov    0x14(%ebp),%eax
f010337a:	8d 50 04             	lea    0x4(%eax),%edx
f010337d:	89 55 14             	mov    %edx,0x14(%ebp)
f0103380:	8b 00                	mov    (%eax),%eax
f0103382:	89 c2                	mov    %eax,%edx
f0103384:	c1 fa 1f             	sar    $0x1f,%edx
f0103387:	31 d0                	xor    %edx,%eax
f0103389:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010338b:	83 f8 06             	cmp    $0x6,%eax
f010338e:	7f 0b                	jg     f010339b <vprintfmt+0x1f1>
f0103390:	8b 14 85 30 4f 10 f0 	mov    -0xfefb0d0(,%eax,4),%edx
f0103397:	85 d2                	test   %edx,%edx
f0103399:	75 23                	jne    f01033be <vprintfmt+0x214>
				printfmt(putch, putdat, "error %d", err);
f010339b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010339f:	c7 44 24 08 65 4d 10 	movl   $0xf0104d65,0x8(%esp)
f01033a6:	f0 
f01033a7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01033aa:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01033ae:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01033b1:	89 1c 24             	mov    %ebx,(%esp)
f01033b4:	e8 c9 fd ff ff       	call   f0103182 <printfmt>
f01033b9:	e9 bb fe ff ff       	jmp    f0103279 <vprintfmt+0xcf>
			else
				printfmt(putch, putdat, "%s", p);
f01033be:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01033c2:	c7 44 24 08 a8 4a 10 	movl   $0xf0104aa8,0x8(%esp)
f01033c9:	f0 
f01033ca:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01033cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01033d1:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01033d4:	89 1c 24             	mov    %ebx,(%esp)
f01033d7:	e8 a6 fd ff ff       	call   f0103182 <printfmt>
f01033dc:	e9 98 fe ff ff       	jmp    f0103279 <vprintfmt+0xcf>
f01033e1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01033e4:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01033e7:	89 5d d8             	mov    %ebx,-0x28(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01033ea:	8b 45 14             	mov    0x14(%ebp),%eax
f01033ed:	8d 50 04             	lea    0x4(%eax),%edx
f01033f0:	89 55 14             	mov    %edx,0x14(%ebp)
f01033f3:	8b 18                	mov    (%eax),%ebx
				p = "(null)";
f01033f5:	85 db                	test   %ebx,%ebx
f01033f7:	b8 5e 4d 10 f0       	mov    $0xf0104d5e,%eax
f01033fc:	0f 44 d8             	cmove  %eax,%ebx
			if (width > 0 && padc != '-')
f01033ff:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103403:	7e 06                	jle    f010340b <vprintfmt+0x261>
f0103405:	80 7d e0 2d          	cmpb   $0x2d,-0x20(%ebp)
f0103409:	75 10                	jne    f010341b <vprintfmt+0x271>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010340b:	0f be 03             	movsbl (%ebx),%eax
f010340e:	83 c3 01             	add    $0x1,%ebx
f0103411:	85 c0                	test   %eax,%eax
f0103413:	0f 85 82 00 00 00    	jne    f010349b <vprintfmt+0x2f1>
f0103419:	eb 75                	jmp    f0103490 <vprintfmt+0x2e6>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010341b:	89 74 24 04          	mov    %esi,0x4(%esp)
f010341f:	89 1c 24             	mov    %ebx,(%esp)
f0103422:	e8 84 03 00 00       	call   f01037ab <strnlen>
f0103427:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010342a:	29 c2                	sub    %eax,%edx
f010342c:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010342f:	85 d2                	test   %edx,%edx
f0103431:	7e d8                	jle    f010340b <vprintfmt+0x261>
					putch(padc, putdat);
f0103433:	0f be 45 e0          	movsbl -0x20(%ebp),%eax
f0103437:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010343a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010343d:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103441:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103444:	89 04 24             	mov    %eax,(%esp)
f0103447:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010344a:	83 6d dc 01          	subl   $0x1,-0x24(%ebp)
f010344e:	75 ea                	jne    f010343a <vprintfmt+0x290>
f0103450:	eb b9                	jmp    f010340b <vprintfmt+0x261>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103452:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103456:	74 1b                	je     f0103473 <vprintfmt+0x2c9>
f0103458:	8d 50 e0             	lea    -0x20(%eax),%edx
f010345b:	83 fa 5e             	cmp    $0x5e,%edx
f010345e:	76 13                	jbe    f0103473 <vprintfmt+0x2c9>
					putch('?', putdat);
f0103460:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103463:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103467:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f010346e:	ff 55 08             	call   *0x8(%ebp)
f0103471:	eb 0d                	jmp    f0103480 <vprintfmt+0x2d6>
				else
					putch(ch, putdat);
f0103473:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103476:	89 54 24 04          	mov    %edx,0x4(%esp)
f010347a:	89 04 24             	mov    %eax,(%esp)
f010347d:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103480:	83 ef 01             	sub    $0x1,%edi
f0103483:	0f be 03             	movsbl (%ebx),%eax
f0103486:	83 c3 01             	add    $0x1,%ebx
f0103489:	85 c0                	test   %eax,%eax
f010348b:	75 14                	jne    f01034a1 <vprintfmt+0x2f7>
f010348d:	89 7d dc             	mov    %edi,-0x24(%ebp)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103490:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103494:	7f 19                	jg     f01034af <vprintfmt+0x305>
f0103496:	e9 de fd ff ff       	jmp    f0103279 <vprintfmt+0xcf>
f010349b:	89 7d e0             	mov    %edi,-0x20(%ebp)
f010349e:	8b 7d dc             	mov    -0x24(%ebp),%edi
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01034a1:	85 f6                	test   %esi,%esi
f01034a3:	78 ad                	js     f0103452 <vprintfmt+0x2a8>
f01034a5:	83 ee 01             	sub    $0x1,%esi
f01034a8:	79 a8                	jns    f0103452 <vprintfmt+0x2a8>
f01034aa:	89 7d dc             	mov    %edi,-0x24(%ebp)
f01034ad:	eb e1                	jmp    f0103490 <vprintfmt+0x2e6>
f01034af:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01034b2:	8b 7d 08             	mov    0x8(%ebp),%edi
f01034b5:	8b 75 0c             	mov    0xc(%ebp),%esi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01034b8:	89 74 24 04          	mov    %esi,0x4(%esp)
f01034bc:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01034c3:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01034c5:	83 eb 01             	sub    $0x1,%ebx
f01034c8:	75 ee                	jne    f01034b8 <vprintfmt+0x30e>
f01034ca:	e9 aa fd ff ff       	jmp    f0103279 <vprintfmt+0xcf>
f01034cf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01034d2:	83 f9 01             	cmp    $0x1,%ecx
f01034d5:	7e 10                	jle    f01034e7 <vprintfmt+0x33d>
		return va_arg(*ap, long long);
f01034d7:	8b 45 14             	mov    0x14(%ebp),%eax
f01034da:	8d 50 08             	lea    0x8(%eax),%edx
f01034dd:	89 55 14             	mov    %edx,0x14(%ebp)
f01034e0:	8b 30                	mov    (%eax),%esi
f01034e2:	8b 78 04             	mov    0x4(%eax),%edi
f01034e5:	eb 26                	jmp    f010350d <vprintfmt+0x363>
	else if (lflag)
f01034e7:	85 c9                	test   %ecx,%ecx
f01034e9:	74 12                	je     f01034fd <vprintfmt+0x353>
		return va_arg(*ap, long);
f01034eb:	8b 45 14             	mov    0x14(%ebp),%eax
f01034ee:	8d 50 04             	lea    0x4(%eax),%edx
f01034f1:	89 55 14             	mov    %edx,0x14(%ebp)
f01034f4:	8b 30                	mov    (%eax),%esi
f01034f6:	89 f7                	mov    %esi,%edi
f01034f8:	c1 ff 1f             	sar    $0x1f,%edi
f01034fb:	eb 10                	jmp    f010350d <vprintfmt+0x363>
	else
		return va_arg(*ap, int);
f01034fd:	8b 45 14             	mov    0x14(%ebp),%eax
f0103500:	8d 50 04             	lea    0x4(%eax),%edx
f0103503:	89 55 14             	mov    %edx,0x14(%ebp)
f0103506:	8b 30                	mov    (%eax),%esi
f0103508:	89 f7                	mov    %esi,%edi
f010350a:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010350d:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103512:	85 ff                	test   %edi,%edi
f0103514:	0f 89 9e 00 00 00    	jns    f01035b8 <vprintfmt+0x40e>
				putch('-', putdat);
f010351a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010351d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103521:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0103528:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010352b:	f7 de                	neg    %esi
f010352d:	83 d7 00             	adc    $0x0,%edi
f0103530:	f7 df                	neg    %edi
			}
			base = 10;
f0103532:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103537:	eb 7f                	jmp    f01035b8 <vprintfmt+0x40e>
f0103539:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f010353c:	89 ca                	mov    %ecx,%edx
f010353e:	8d 45 14             	lea    0x14(%ebp),%eax
f0103541:	e8 e5 fb ff ff       	call   f010312b <getuint>
f0103546:	89 c6                	mov    %eax,%esi
f0103548:	89 d7                	mov    %edx,%edi
			base = 10;
f010354a:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f010354f:	eb 67                	jmp    f01035b8 <vprintfmt+0x40e>
f0103551:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap,lflag);
f0103554:	89 ca                	mov    %ecx,%edx
f0103556:	8d 45 14             	lea    0x14(%ebp),%eax
f0103559:	e8 cd fb ff ff       	call   f010312b <getuint>
f010355e:	89 c6                	mov    %eax,%esi
f0103560:	89 d7                	mov    %edx,%edi
			base = 8;
f0103562:	b8 08 00 00 00       	mov    $0x8,%eax

			goto number;
f0103567:	eb 4f                	jmp    f01035b8 <vprintfmt+0x40e>
f0103569:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// pointer
		case 'p':
			putch('0', putdat);
f010356c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010356f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103573:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010357a:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f010357d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103581:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0103588:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010358b:	8b 45 14             	mov    0x14(%ebp),%eax
f010358e:	8d 50 04             	lea    0x4(%eax),%edx
f0103591:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103594:	8b 30                	mov    (%eax),%esi
f0103596:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010359b:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f01035a0:	eb 16                	jmp    f01035b8 <vprintfmt+0x40e>
f01035a2:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01035a5:	89 ca                	mov    %ecx,%edx
f01035a7:	8d 45 14             	lea    0x14(%ebp),%eax
f01035aa:	e8 7c fb ff ff       	call   f010312b <getuint>
f01035af:	89 c6                	mov    %eax,%esi
f01035b1:	89 d7                	mov    %edx,%edi
			base = 16;
f01035b3:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f01035b8:	0f be 55 e0          	movsbl -0x20(%ebp),%edx
f01035bc:	89 54 24 10          	mov    %edx,0x10(%esp)
f01035c0:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01035c3:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01035c7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01035cb:	89 34 24             	mov    %esi,(%esp)
f01035ce:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01035d2:	8b 55 0c             	mov    0xc(%ebp),%edx
f01035d5:	8b 45 08             	mov    0x8(%ebp),%eax
f01035d8:	e8 73 fa ff ff       	call   f0103050 <printnum>
			break;
f01035dd:	e9 97 fc ff ff       	jmp    f0103279 <vprintfmt+0xcf>
f01035e2:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01035e5:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01035e8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01035eb:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01035ef:	89 14 24             	mov    %edx,(%esp)
f01035f2:	ff 55 08             	call   *0x8(%ebp)
			break;
f01035f5:	e9 7f fc ff ff       	jmp    f0103279 <vprintfmt+0xcf>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01035fa:	8b 45 0c             	mov    0xc(%ebp),%eax
f01035fd:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103601:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0103608:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f010360b:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f010360e:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0103612:	0f 84 61 fc ff ff    	je     f0103279 <vprintfmt+0xcf>
f0103618:	83 eb 01             	sub    $0x1,%ebx
f010361b:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f010361f:	75 f7                	jne    f0103618 <vprintfmt+0x46e>
f0103621:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103624:	e9 50 fc ff ff       	jmp    f0103279 <vprintfmt+0xcf>
				/* do nothing */;
			break;
		}
	}
}
f0103629:	83 c4 3c             	add    $0x3c,%esp
f010362c:	5b                   	pop    %ebx
f010362d:	5e                   	pop    %esi
f010362e:	5f                   	pop    %edi
f010362f:	5d                   	pop    %ebp
f0103630:	c3                   	ret    

f0103631 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103631:	55                   	push   %ebp
f0103632:	89 e5                	mov    %esp,%ebp
f0103634:	83 ec 28             	sub    $0x28,%esp
f0103637:	8b 45 08             	mov    0x8(%ebp),%eax
f010363a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010363d:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103640:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103644:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103647:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010364e:	85 c0                	test   %eax,%eax
f0103650:	74 30                	je     f0103682 <vsnprintf+0x51>
f0103652:	85 d2                	test   %edx,%edx
f0103654:	7e 2c                	jle    f0103682 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103656:	8b 45 14             	mov    0x14(%ebp),%eax
f0103659:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010365d:	8b 45 10             	mov    0x10(%ebp),%eax
f0103660:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103664:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103667:	89 44 24 04          	mov    %eax,0x4(%esp)
f010366b:	c7 04 24 65 31 10 f0 	movl   $0xf0103165,(%esp)
f0103672:	e8 33 fb ff ff       	call   f01031aa <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103677:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010367a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010367d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103680:	eb 05                	jmp    f0103687 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103682:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103687:	c9                   	leave  
f0103688:	c3                   	ret    

f0103689 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103689:	55                   	push   %ebp
f010368a:	89 e5                	mov    %esp,%ebp
f010368c:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010368f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103692:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103696:	8b 45 10             	mov    0x10(%ebp),%eax
f0103699:	89 44 24 08          	mov    %eax,0x8(%esp)
f010369d:	8b 45 0c             	mov    0xc(%ebp),%eax
f01036a0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036a4:	8b 45 08             	mov    0x8(%ebp),%eax
f01036a7:	89 04 24             	mov    %eax,(%esp)
f01036aa:	e8 82 ff ff ff       	call   f0103631 <vsnprintf>
	va_end(ap);

	return rc;
}
f01036af:	c9                   	leave  
f01036b0:	c3                   	ret    
	...

f01036c0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01036c0:	55                   	push   %ebp
f01036c1:	89 e5                	mov    %esp,%ebp
f01036c3:	57                   	push   %edi
f01036c4:	56                   	push   %esi
f01036c5:	53                   	push   %ebx
f01036c6:	83 ec 1c             	sub    $0x1c,%esp
f01036c9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01036cc:	85 c0                	test   %eax,%eax
f01036ce:	74 10                	je     f01036e0 <readline+0x20>
		cprintf("%s", prompt);
f01036d0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036d4:	c7 04 24 a8 4a 10 f0 	movl   $0xf0104aa8,(%esp)
f01036db:	e8 6e f6 ff ff       	call   f0102d4e <cprintf>

	i = 0;
	echoing = iscons(0);
f01036e0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01036e7:	e8 26 cf ff ff       	call   f0100612 <iscons>
f01036ec:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01036ee:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01036f3:	e8 09 cf ff ff       	call   f0100601 <getchar>
f01036f8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01036fa:	85 c0                	test   %eax,%eax
f01036fc:	79 17                	jns    f0103715 <readline+0x55>
			cprintf("read error: %e\n", c);
f01036fe:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103702:	c7 04 24 4c 4f 10 f0 	movl   $0xf0104f4c,(%esp)
f0103709:	e8 40 f6 ff ff       	call   f0102d4e <cprintf>
			return NULL;
f010370e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103713:	eb 6d                	jmp    f0103782 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103715:	83 f8 08             	cmp    $0x8,%eax
f0103718:	74 05                	je     f010371f <readline+0x5f>
f010371a:	83 f8 7f             	cmp    $0x7f,%eax
f010371d:	75 19                	jne    f0103738 <readline+0x78>
f010371f:	85 f6                	test   %esi,%esi
f0103721:	7e 15                	jle    f0103738 <readline+0x78>
			if (echoing)
f0103723:	85 ff                	test   %edi,%edi
f0103725:	74 0c                	je     f0103733 <readline+0x73>
				cputchar('\b');
f0103727:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010372e:	e8 be ce ff ff       	call   f01005f1 <cputchar>
			i--;
f0103733:	83 ee 01             	sub    $0x1,%esi
f0103736:	eb bb                	jmp    f01036f3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103738:	83 fb 1f             	cmp    $0x1f,%ebx
f010373b:	7e 1f                	jle    f010375c <readline+0x9c>
f010373d:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103743:	7f 17                	jg     f010375c <readline+0x9c>
			if (echoing)
f0103745:	85 ff                	test   %edi,%edi
f0103747:	74 08                	je     f0103751 <readline+0x91>
				cputchar(c);
f0103749:	89 1c 24             	mov    %ebx,(%esp)
f010374c:	e8 a0 ce ff ff       	call   f01005f1 <cputchar>
			buf[i++] = c;
f0103751:	88 9e a0 85 11 f0    	mov    %bl,-0xfee7a60(%esi)
f0103757:	83 c6 01             	add    $0x1,%esi
f010375a:	eb 97                	jmp    f01036f3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010375c:	83 fb 0a             	cmp    $0xa,%ebx
f010375f:	74 05                	je     f0103766 <readline+0xa6>
f0103761:	83 fb 0d             	cmp    $0xd,%ebx
f0103764:	75 8d                	jne    f01036f3 <readline+0x33>
			if (echoing)
f0103766:	85 ff                	test   %edi,%edi
f0103768:	74 0c                	je     f0103776 <readline+0xb6>
				cputchar('\n');
f010376a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0103771:	e8 7b ce ff ff       	call   f01005f1 <cputchar>
			buf[i] = 0;
f0103776:	c6 86 a0 85 11 f0 00 	movb   $0x0,-0xfee7a60(%esi)
			return buf;
f010377d:	b8 a0 85 11 f0       	mov    $0xf01185a0,%eax
		}
	}
}
f0103782:	83 c4 1c             	add    $0x1c,%esp
f0103785:	5b                   	pop    %ebx
f0103786:	5e                   	pop    %esi
f0103787:	5f                   	pop    %edi
f0103788:	5d                   	pop    %ebp
f0103789:	c3                   	ret    
f010378a:	00 00                	add    %al,(%eax)
f010378c:	00 00                	add    %al,(%eax)
	...

f0103790 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103790:	55                   	push   %ebp
f0103791:	89 e5                	mov    %esp,%ebp
f0103793:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103796:	b8 00 00 00 00       	mov    $0x0,%eax
f010379b:	80 3a 00             	cmpb   $0x0,(%edx)
f010379e:	74 09                	je     f01037a9 <strlen+0x19>
		n++;
f01037a0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01037a3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01037a7:	75 f7                	jne    f01037a0 <strlen+0x10>
		n++;
	return n;
}
f01037a9:	5d                   	pop    %ebp
f01037aa:	c3                   	ret    

f01037ab <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01037ab:	55                   	push   %ebp
f01037ac:	89 e5                	mov    %esp,%ebp
f01037ae:	53                   	push   %ebx
f01037af:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01037b2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01037b5:	b8 00 00 00 00       	mov    $0x0,%eax
f01037ba:	85 c9                	test   %ecx,%ecx
f01037bc:	74 1a                	je     f01037d8 <strnlen+0x2d>
f01037be:	80 3b 00             	cmpb   $0x0,(%ebx)
f01037c1:	74 15                	je     f01037d8 <strnlen+0x2d>
f01037c3:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f01037c8:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01037ca:	39 ca                	cmp    %ecx,%edx
f01037cc:	74 0a                	je     f01037d8 <strnlen+0x2d>
f01037ce:	83 c2 01             	add    $0x1,%edx
f01037d1:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f01037d6:	75 f0                	jne    f01037c8 <strnlen+0x1d>
		n++;
	return n;
}
f01037d8:	5b                   	pop    %ebx
f01037d9:	5d                   	pop    %ebp
f01037da:	c3                   	ret    

f01037db <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01037db:	55                   	push   %ebp
f01037dc:	89 e5                	mov    %esp,%ebp
f01037de:	53                   	push   %ebx
f01037df:	8b 45 08             	mov    0x8(%ebp),%eax
f01037e2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01037e5:	ba 00 00 00 00       	mov    $0x0,%edx
f01037ea:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01037ee:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f01037f1:	83 c2 01             	add    $0x1,%edx
f01037f4:	84 c9                	test   %cl,%cl
f01037f6:	75 f2                	jne    f01037ea <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f01037f8:	5b                   	pop    %ebx
f01037f9:	5d                   	pop    %ebp
f01037fa:	c3                   	ret    

f01037fb <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01037fb:	55                   	push   %ebp
f01037fc:	89 e5                	mov    %esp,%ebp
f01037fe:	56                   	push   %esi
f01037ff:	53                   	push   %ebx
f0103800:	8b 45 08             	mov    0x8(%ebp),%eax
f0103803:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103806:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103809:	85 f6                	test   %esi,%esi
f010380b:	74 18                	je     f0103825 <strncpy+0x2a>
f010380d:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f0103812:	0f b6 1a             	movzbl (%edx),%ebx
f0103815:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103818:	80 3a 01             	cmpb   $0x1,(%edx)
f010381b:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010381e:	83 c1 01             	add    $0x1,%ecx
f0103821:	39 f1                	cmp    %esi,%ecx
f0103823:	75 ed                	jne    f0103812 <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103825:	5b                   	pop    %ebx
f0103826:	5e                   	pop    %esi
f0103827:	5d                   	pop    %ebp
f0103828:	c3                   	ret    

f0103829 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103829:	55                   	push   %ebp
f010382a:	89 e5                	mov    %esp,%ebp
f010382c:	57                   	push   %edi
f010382d:	56                   	push   %esi
f010382e:	53                   	push   %ebx
f010382f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103832:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103835:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103838:	89 f8                	mov    %edi,%eax
f010383a:	85 f6                	test   %esi,%esi
f010383c:	74 2b                	je     f0103869 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f010383e:	83 fe 01             	cmp    $0x1,%esi
f0103841:	74 23                	je     f0103866 <strlcpy+0x3d>
f0103843:	0f b6 0b             	movzbl (%ebx),%ecx
f0103846:	84 c9                	test   %cl,%cl
f0103848:	74 1c                	je     f0103866 <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f010384a:	83 ee 02             	sub    $0x2,%esi
f010384d:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103852:	88 08                	mov    %cl,(%eax)
f0103854:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103857:	39 f2                	cmp    %esi,%edx
f0103859:	74 0b                	je     f0103866 <strlcpy+0x3d>
f010385b:	83 c2 01             	add    $0x1,%edx
f010385e:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0103862:	84 c9                	test   %cl,%cl
f0103864:	75 ec                	jne    f0103852 <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f0103866:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103869:	29 f8                	sub    %edi,%eax
}
f010386b:	5b                   	pop    %ebx
f010386c:	5e                   	pop    %esi
f010386d:	5f                   	pop    %edi
f010386e:	5d                   	pop    %ebp
f010386f:	c3                   	ret    

f0103870 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103870:	55                   	push   %ebp
f0103871:	89 e5                	mov    %esp,%ebp
f0103873:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103876:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103879:	0f b6 01             	movzbl (%ecx),%eax
f010387c:	84 c0                	test   %al,%al
f010387e:	74 16                	je     f0103896 <strcmp+0x26>
f0103880:	3a 02                	cmp    (%edx),%al
f0103882:	75 12                	jne    f0103896 <strcmp+0x26>
		p++, q++;
f0103884:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103887:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f010388b:	84 c0                	test   %al,%al
f010388d:	74 07                	je     f0103896 <strcmp+0x26>
f010388f:	83 c1 01             	add    $0x1,%ecx
f0103892:	3a 02                	cmp    (%edx),%al
f0103894:	74 ee                	je     f0103884 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103896:	0f b6 c0             	movzbl %al,%eax
f0103899:	0f b6 12             	movzbl (%edx),%edx
f010389c:	29 d0                	sub    %edx,%eax
}
f010389e:	5d                   	pop    %ebp
f010389f:	c3                   	ret    

f01038a0 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01038a0:	55                   	push   %ebp
f01038a1:	89 e5                	mov    %esp,%ebp
f01038a3:	53                   	push   %ebx
f01038a4:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01038a7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01038aa:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01038ad:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01038b2:	85 d2                	test   %edx,%edx
f01038b4:	74 28                	je     f01038de <strncmp+0x3e>
f01038b6:	0f b6 01             	movzbl (%ecx),%eax
f01038b9:	84 c0                	test   %al,%al
f01038bb:	74 24                	je     f01038e1 <strncmp+0x41>
f01038bd:	3a 03                	cmp    (%ebx),%al
f01038bf:	75 20                	jne    f01038e1 <strncmp+0x41>
f01038c1:	83 ea 01             	sub    $0x1,%edx
f01038c4:	74 13                	je     f01038d9 <strncmp+0x39>
		n--, p++, q++;
f01038c6:	83 c1 01             	add    $0x1,%ecx
f01038c9:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01038cc:	0f b6 01             	movzbl (%ecx),%eax
f01038cf:	84 c0                	test   %al,%al
f01038d1:	74 0e                	je     f01038e1 <strncmp+0x41>
f01038d3:	3a 03                	cmp    (%ebx),%al
f01038d5:	74 ea                	je     f01038c1 <strncmp+0x21>
f01038d7:	eb 08                	jmp    f01038e1 <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f01038d9:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01038de:	5b                   	pop    %ebx
f01038df:	5d                   	pop    %ebp
f01038e0:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01038e1:	0f b6 01             	movzbl (%ecx),%eax
f01038e4:	0f b6 13             	movzbl (%ebx),%edx
f01038e7:	29 d0                	sub    %edx,%eax
f01038e9:	eb f3                	jmp    f01038de <strncmp+0x3e>

f01038eb <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01038eb:	55                   	push   %ebp
f01038ec:	89 e5                	mov    %esp,%ebp
f01038ee:	8b 45 08             	mov    0x8(%ebp),%eax
f01038f1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01038f5:	0f b6 10             	movzbl (%eax),%edx
f01038f8:	84 d2                	test   %dl,%dl
f01038fa:	74 1c                	je     f0103918 <strchr+0x2d>
		if (*s == c)
f01038fc:	38 ca                	cmp    %cl,%dl
f01038fe:	75 09                	jne    f0103909 <strchr+0x1e>
f0103900:	eb 1b                	jmp    f010391d <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103902:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f0103905:	38 ca                	cmp    %cl,%dl
f0103907:	74 14                	je     f010391d <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103909:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f010390d:	84 d2                	test   %dl,%dl
f010390f:	75 f1                	jne    f0103902 <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f0103911:	b8 00 00 00 00       	mov    $0x0,%eax
f0103916:	eb 05                	jmp    f010391d <strchr+0x32>
f0103918:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010391d:	5d                   	pop    %ebp
f010391e:	c3                   	ret    

f010391f <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010391f:	55                   	push   %ebp
f0103920:	89 e5                	mov    %esp,%ebp
f0103922:	8b 45 08             	mov    0x8(%ebp),%eax
f0103925:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103929:	0f b6 10             	movzbl (%eax),%edx
f010392c:	84 d2                	test   %dl,%dl
f010392e:	74 14                	je     f0103944 <strfind+0x25>
		if (*s == c)
f0103930:	38 ca                	cmp    %cl,%dl
f0103932:	75 06                	jne    f010393a <strfind+0x1b>
f0103934:	eb 0e                	jmp    f0103944 <strfind+0x25>
f0103936:	38 ca                	cmp    %cl,%dl
f0103938:	74 0a                	je     f0103944 <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010393a:	83 c0 01             	add    $0x1,%eax
f010393d:	0f b6 10             	movzbl (%eax),%edx
f0103940:	84 d2                	test   %dl,%dl
f0103942:	75 f2                	jne    f0103936 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f0103944:	5d                   	pop    %ebp
f0103945:	c3                   	ret    

f0103946 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103946:	55                   	push   %ebp
f0103947:	89 e5                	mov    %esp,%ebp
f0103949:	83 ec 0c             	sub    $0xc,%esp
f010394c:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010394f:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0103952:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0103955:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103958:	8b 45 0c             	mov    0xc(%ebp),%eax
f010395b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010395e:	85 c9                	test   %ecx,%ecx
f0103960:	74 30                	je     f0103992 <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103962:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103968:	75 25                	jne    f010398f <memset+0x49>
f010396a:	f6 c1 03             	test   $0x3,%cl
f010396d:	75 20                	jne    f010398f <memset+0x49>
		c &= 0xFF;
f010396f:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103972:	89 d3                	mov    %edx,%ebx
f0103974:	c1 e3 08             	shl    $0x8,%ebx
f0103977:	89 d6                	mov    %edx,%esi
f0103979:	c1 e6 18             	shl    $0x18,%esi
f010397c:	89 d0                	mov    %edx,%eax
f010397e:	c1 e0 10             	shl    $0x10,%eax
f0103981:	09 f0                	or     %esi,%eax
f0103983:	09 d0                	or     %edx,%eax
f0103985:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0103987:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f010398a:	fc                   	cld    
f010398b:	f3 ab                	rep stos %eax,%es:(%edi)
f010398d:	eb 03                	jmp    f0103992 <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010398f:	fc                   	cld    
f0103990:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103992:	89 f8                	mov    %edi,%eax
f0103994:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0103997:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010399a:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010399d:	89 ec                	mov    %ebp,%esp
f010399f:	5d                   	pop    %ebp
f01039a0:	c3                   	ret    

f01039a1 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01039a1:	55                   	push   %ebp
f01039a2:	89 e5                	mov    %esp,%ebp
f01039a4:	83 ec 08             	sub    $0x8,%esp
f01039a7:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01039aa:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01039ad:	8b 45 08             	mov    0x8(%ebp),%eax
f01039b0:	8b 75 0c             	mov    0xc(%ebp),%esi
f01039b3:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01039b6:	39 c6                	cmp    %eax,%esi
f01039b8:	73 36                	jae    f01039f0 <memmove+0x4f>
f01039ba:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01039bd:	39 d0                	cmp    %edx,%eax
f01039bf:	73 2f                	jae    f01039f0 <memmove+0x4f>
		s += n;
		d += n;
f01039c1:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01039c4:	f6 c2 03             	test   $0x3,%dl
f01039c7:	75 1b                	jne    f01039e4 <memmove+0x43>
f01039c9:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01039cf:	75 13                	jne    f01039e4 <memmove+0x43>
f01039d1:	f6 c1 03             	test   $0x3,%cl
f01039d4:	75 0e                	jne    f01039e4 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01039d6:	83 ef 04             	sub    $0x4,%edi
f01039d9:	8d 72 fc             	lea    -0x4(%edx),%esi
f01039dc:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01039df:	fd                   	std    
f01039e0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01039e2:	eb 09                	jmp    f01039ed <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01039e4:	83 ef 01             	sub    $0x1,%edi
f01039e7:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01039ea:	fd                   	std    
f01039eb:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01039ed:	fc                   	cld    
f01039ee:	eb 20                	jmp    f0103a10 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01039f0:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01039f6:	75 13                	jne    f0103a0b <memmove+0x6a>
f01039f8:	a8 03                	test   $0x3,%al
f01039fa:	75 0f                	jne    f0103a0b <memmove+0x6a>
f01039fc:	f6 c1 03             	test   $0x3,%cl
f01039ff:	75 0a                	jne    f0103a0b <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103a01:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0103a04:	89 c7                	mov    %eax,%edi
f0103a06:	fc                   	cld    
f0103a07:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103a09:	eb 05                	jmp    f0103a10 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103a0b:	89 c7                	mov    %eax,%edi
f0103a0d:	fc                   	cld    
f0103a0e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103a10:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0103a13:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0103a16:	89 ec                	mov    %ebp,%esp
f0103a18:	5d                   	pop    %ebp
f0103a19:	c3                   	ret    

f0103a1a <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0103a1a:	55                   	push   %ebp
f0103a1b:	89 e5                	mov    %esp,%ebp
f0103a1d:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0103a20:	8b 45 10             	mov    0x10(%ebp),%eax
f0103a23:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103a27:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103a2a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a2e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a31:	89 04 24             	mov    %eax,(%esp)
f0103a34:	e8 68 ff ff ff       	call   f01039a1 <memmove>
}
f0103a39:	c9                   	leave  
f0103a3a:	c3                   	ret    

f0103a3b <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103a3b:	55                   	push   %ebp
f0103a3c:	89 e5                	mov    %esp,%ebp
f0103a3e:	57                   	push   %edi
f0103a3f:	56                   	push   %esi
f0103a40:	53                   	push   %ebx
f0103a41:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103a44:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103a47:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103a4a:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103a4f:	85 ff                	test   %edi,%edi
f0103a51:	74 37                	je     f0103a8a <memcmp+0x4f>
		if (*s1 != *s2)
f0103a53:	0f b6 03             	movzbl (%ebx),%eax
f0103a56:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103a59:	83 ef 01             	sub    $0x1,%edi
f0103a5c:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f0103a61:	38 c8                	cmp    %cl,%al
f0103a63:	74 1c                	je     f0103a81 <memcmp+0x46>
f0103a65:	eb 10                	jmp    f0103a77 <memcmp+0x3c>
f0103a67:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0103a6c:	83 c2 01             	add    $0x1,%edx
f0103a6f:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0103a73:	38 c8                	cmp    %cl,%al
f0103a75:	74 0a                	je     f0103a81 <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f0103a77:	0f b6 c0             	movzbl %al,%eax
f0103a7a:	0f b6 c9             	movzbl %cl,%ecx
f0103a7d:	29 c8                	sub    %ecx,%eax
f0103a7f:	eb 09                	jmp    f0103a8a <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103a81:	39 fa                	cmp    %edi,%edx
f0103a83:	75 e2                	jne    f0103a67 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103a85:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103a8a:	5b                   	pop    %ebx
f0103a8b:	5e                   	pop    %esi
f0103a8c:	5f                   	pop    %edi
f0103a8d:	5d                   	pop    %ebp
f0103a8e:	c3                   	ret    

f0103a8f <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103a8f:	55                   	push   %ebp
f0103a90:	89 e5                	mov    %esp,%ebp
f0103a92:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103a95:	89 c2                	mov    %eax,%edx
f0103a97:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103a9a:	39 d0                	cmp    %edx,%eax
f0103a9c:	73 15                	jae    f0103ab3 <memfind+0x24>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103a9e:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f0103aa2:	38 08                	cmp    %cl,(%eax)
f0103aa4:	75 06                	jne    f0103aac <memfind+0x1d>
f0103aa6:	eb 0b                	jmp    f0103ab3 <memfind+0x24>
f0103aa8:	38 08                	cmp    %cl,(%eax)
f0103aaa:	74 07                	je     f0103ab3 <memfind+0x24>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103aac:	83 c0 01             	add    $0x1,%eax
f0103aaf:	39 d0                	cmp    %edx,%eax
f0103ab1:	75 f5                	jne    f0103aa8 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103ab3:	5d                   	pop    %ebp
f0103ab4:	c3                   	ret    

f0103ab5 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103ab5:	55                   	push   %ebp
f0103ab6:	89 e5                	mov    %esp,%ebp
f0103ab8:	57                   	push   %edi
f0103ab9:	56                   	push   %esi
f0103aba:	53                   	push   %ebx
f0103abb:	8b 55 08             	mov    0x8(%ebp),%edx
f0103abe:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103ac1:	0f b6 02             	movzbl (%edx),%eax
f0103ac4:	3c 20                	cmp    $0x20,%al
f0103ac6:	74 04                	je     f0103acc <strtol+0x17>
f0103ac8:	3c 09                	cmp    $0x9,%al
f0103aca:	75 0e                	jne    f0103ada <strtol+0x25>
		s++;
f0103acc:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103acf:	0f b6 02             	movzbl (%edx),%eax
f0103ad2:	3c 20                	cmp    $0x20,%al
f0103ad4:	74 f6                	je     f0103acc <strtol+0x17>
f0103ad6:	3c 09                	cmp    $0x9,%al
f0103ad8:	74 f2                	je     f0103acc <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103ada:	3c 2b                	cmp    $0x2b,%al
f0103adc:	75 0a                	jne    f0103ae8 <strtol+0x33>
		s++;
f0103ade:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103ae1:	bf 00 00 00 00       	mov    $0x0,%edi
f0103ae6:	eb 10                	jmp    f0103af8 <strtol+0x43>
f0103ae8:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103aed:	3c 2d                	cmp    $0x2d,%al
f0103aef:	75 07                	jne    f0103af8 <strtol+0x43>
		s++, neg = 1;
f0103af1:	83 c2 01             	add    $0x1,%edx
f0103af4:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103af8:	85 db                	test   %ebx,%ebx
f0103afa:	0f 94 c0             	sete   %al
f0103afd:	74 05                	je     f0103b04 <strtol+0x4f>
f0103aff:	83 fb 10             	cmp    $0x10,%ebx
f0103b02:	75 15                	jne    f0103b19 <strtol+0x64>
f0103b04:	80 3a 30             	cmpb   $0x30,(%edx)
f0103b07:	75 10                	jne    f0103b19 <strtol+0x64>
f0103b09:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0103b0d:	75 0a                	jne    f0103b19 <strtol+0x64>
		s += 2, base = 16;
f0103b0f:	83 c2 02             	add    $0x2,%edx
f0103b12:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103b17:	eb 13                	jmp    f0103b2c <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f0103b19:	84 c0                	test   %al,%al
f0103b1b:	74 0f                	je     f0103b2c <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103b1d:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103b22:	80 3a 30             	cmpb   $0x30,(%edx)
f0103b25:	75 05                	jne    f0103b2c <strtol+0x77>
		s++, base = 8;
f0103b27:	83 c2 01             	add    $0x1,%edx
f0103b2a:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f0103b2c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b31:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103b33:	0f b6 0a             	movzbl (%edx),%ecx
f0103b36:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0103b39:	80 fb 09             	cmp    $0x9,%bl
f0103b3c:	77 08                	ja     f0103b46 <strtol+0x91>
			dig = *s - '0';
f0103b3e:	0f be c9             	movsbl %cl,%ecx
f0103b41:	83 e9 30             	sub    $0x30,%ecx
f0103b44:	eb 1e                	jmp    f0103b64 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f0103b46:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f0103b49:	80 fb 19             	cmp    $0x19,%bl
f0103b4c:	77 08                	ja     f0103b56 <strtol+0xa1>
			dig = *s - 'a' + 10;
f0103b4e:	0f be c9             	movsbl %cl,%ecx
f0103b51:	83 e9 57             	sub    $0x57,%ecx
f0103b54:	eb 0e                	jmp    f0103b64 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f0103b56:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0103b59:	80 fb 19             	cmp    $0x19,%bl
f0103b5c:	77 14                	ja     f0103b72 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103b5e:	0f be c9             	movsbl %cl,%ecx
f0103b61:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0103b64:	39 f1                	cmp    %esi,%ecx
f0103b66:	7d 0e                	jge    f0103b76 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f0103b68:	83 c2 01             	add    $0x1,%edx
f0103b6b:	0f af c6             	imul   %esi,%eax
f0103b6e:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0103b70:	eb c1                	jmp    f0103b33 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0103b72:	89 c1                	mov    %eax,%ecx
f0103b74:	eb 02                	jmp    f0103b78 <strtol+0xc3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0103b76:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0103b78:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103b7c:	74 05                	je     f0103b83 <strtol+0xce>
		*endptr = (char *) s;
f0103b7e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103b81:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0103b83:	89 ca                	mov    %ecx,%edx
f0103b85:	f7 da                	neg    %edx
f0103b87:	85 ff                	test   %edi,%edi
f0103b89:	0f 45 c2             	cmovne %edx,%eax
}
f0103b8c:	5b                   	pop    %ebx
f0103b8d:	5e                   	pop    %esi
f0103b8e:	5f                   	pop    %edi
f0103b8f:	5d                   	pop    %ebp
f0103b90:	c3                   	ret    
	...

f0103ba0 <__udivdi3>:
f0103ba0:	83 ec 1c             	sub    $0x1c,%esp
f0103ba3:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0103ba7:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f0103bab:	8b 44 24 20          	mov    0x20(%esp),%eax
f0103baf:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0103bb3:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103bb7:	8b 74 24 24          	mov    0x24(%esp),%esi
f0103bbb:	85 ff                	test   %edi,%edi
f0103bbd:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0103bc1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103bc5:	89 cd                	mov    %ecx,%ebp
f0103bc7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103bcb:	75 33                	jne    f0103c00 <__udivdi3+0x60>
f0103bcd:	39 f1                	cmp    %esi,%ecx
f0103bcf:	77 57                	ja     f0103c28 <__udivdi3+0x88>
f0103bd1:	85 c9                	test   %ecx,%ecx
f0103bd3:	75 0b                	jne    f0103be0 <__udivdi3+0x40>
f0103bd5:	b8 01 00 00 00       	mov    $0x1,%eax
f0103bda:	31 d2                	xor    %edx,%edx
f0103bdc:	f7 f1                	div    %ecx
f0103bde:	89 c1                	mov    %eax,%ecx
f0103be0:	89 f0                	mov    %esi,%eax
f0103be2:	31 d2                	xor    %edx,%edx
f0103be4:	f7 f1                	div    %ecx
f0103be6:	89 c6                	mov    %eax,%esi
f0103be8:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103bec:	f7 f1                	div    %ecx
f0103bee:	89 f2                	mov    %esi,%edx
f0103bf0:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103bf4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103bf8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103bfc:	83 c4 1c             	add    $0x1c,%esp
f0103bff:	c3                   	ret    
f0103c00:	31 d2                	xor    %edx,%edx
f0103c02:	31 c0                	xor    %eax,%eax
f0103c04:	39 f7                	cmp    %esi,%edi
f0103c06:	77 e8                	ja     f0103bf0 <__udivdi3+0x50>
f0103c08:	0f bd cf             	bsr    %edi,%ecx
f0103c0b:	83 f1 1f             	xor    $0x1f,%ecx
f0103c0e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103c12:	75 2c                	jne    f0103c40 <__udivdi3+0xa0>
f0103c14:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0103c18:	76 04                	jbe    f0103c1e <__udivdi3+0x7e>
f0103c1a:	39 f7                	cmp    %esi,%edi
f0103c1c:	73 d2                	jae    f0103bf0 <__udivdi3+0x50>
f0103c1e:	31 d2                	xor    %edx,%edx
f0103c20:	b8 01 00 00 00       	mov    $0x1,%eax
f0103c25:	eb c9                	jmp    f0103bf0 <__udivdi3+0x50>
f0103c27:	90                   	nop
f0103c28:	89 f2                	mov    %esi,%edx
f0103c2a:	f7 f1                	div    %ecx
f0103c2c:	31 d2                	xor    %edx,%edx
f0103c2e:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103c32:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103c36:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103c3a:	83 c4 1c             	add    $0x1c,%esp
f0103c3d:	c3                   	ret    
f0103c3e:	66 90                	xchg   %ax,%ax
f0103c40:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103c45:	b8 20 00 00 00       	mov    $0x20,%eax
f0103c4a:	89 ea                	mov    %ebp,%edx
f0103c4c:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103c50:	d3 e7                	shl    %cl,%edi
f0103c52:	89 c1                	mov    %eax,%ecx
f0103c54:	d3 ea                	shr    %cl,%edx
f0103c56:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103c5b:	09 fa                	or     %edi,%edx
f0103c5d:	89 f7                	mov    %esi,%edi
f0103c5f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103c63:	89 f2                	mov    %esi,%edx
f0103c65:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103c69:	d3 e5                	shl    %cl,%ebp
f0103c6b:	89 c1                	mov    %eax,%ecx
f0103c6d:	d3 ef                	shr    %cl,%edi
f0103c6f:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103c74:	d3 e2                	shl    %cl,%edx
f0103c76:	89 c1                	mov    %eax,%ecx
f0103c78:	d3 ee                	shr    %cl,%esi
f0103c7a:	09 d6                	or     %edx,%esi
f0103c7c:	89 fa                	mov    %edi,%edx
f0103c7e:	89 f0                	mov    %esi,%eax
f0103c80:	f7 74 24 0c          	divl   0xc(%esp)
f0103c84:	89 d7                	mov    %edx,%edi
f0103c86:	89 c6                	mov    %eax,%esi
f0103c88:	f7 e5                	mul    %ebp
f0103c8a:	39 d7                	cmp    %edx,%edi
f0103c8c:	72 22                	jb     f0103cb0 <__udivdi3+0x110>
f0103c8e:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0103c92:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103c97:	d3 e5                	shl    %cl,%ebp
f0103c99:	39 c5                	cmp    %eax,%ebp
f0103c9b:	73 04                	jae    f0103ca1 <__udivdi3+0x101>
f0103c9d:	39 d7                	cmp    %edx,%edi
f0103c9f:	74 0f                	je     f0103cb0 <__udivdi3+0x110>
f0103ca1:	89 f0                	mov    %esi,%eax
f0103ca3:	31 d2                	xor    %edx,%edx
f0103ca5:	e9 46 ff ff ff       	jmp    f0103bf0 <__udivdi3+0x50>
f0103caa:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103cb0:	8d 46 ff             	lea    -0x1(%esi),%eax
f0103cb3:	31 d2                	xor    %edx,%edx
f0103cb5:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103cb9:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103cbd:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103cc1:	83 c4 1c             	add    $0x1c,%esp
f0103cc4:	c3                   	ret    
	...

f0103cd0 <__umoddi3>:
f0103cd0:	83 ec 1c             	sub    $0x1c,%esp
f0103cd3:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0103cd7:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f0103cdb:	8b 44 24 20          	mov    0x20(%esp),%eax
f0103cdf:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103ce3:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0103ce7:	8b 74 24 24          	mov    0x24(%esp),%esi
f0103ceb:	85 ed                	test   %ebp,%ebp
f0103ced:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0103cf1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103cf5:	89 cf                	mov    %ecx,%edi
f0103cf7:	89 04 24             	mov    %eax,(%esp)
f0103cfa:	89 f2                	mov    %esi,%edx
f0103cfc:	75 1a                	jne    f0103d18 <__umoddi3+0x48>
f0103cfe:	39 f1                	cmp    %esi,%ecx
f0103d00:	76 4e                	jbe    f0103d50 <__umoddi3+0x80>
f0103d02:	f7 f1                	div    %ecx
f0103d04:	89 d0                	mov    %edx,%eax
f0103d06:	31 d2                	xor    %edx,%edx
f0103d08:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103d0c:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103d10:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103d14:	83 c4 1c             	add    $0x1c,%esp
f0103d17:	c3                   	ret    
f0103d18:	39 f5                	cmp    %esi,%ebp
f0103d1a:	77 54                	ja     f0103d70 <__umoddi3+0xa0>
f0103d1c:	0f bd c5             	bsr    %ebp,%eax
f0103d1f:	83 f0 1f             	xor    $0x1f,%eax
f0103d22:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d26:	75 60                	jne    f0103d88 <__umoddi3+0xb8>
f0103d28:	3b 0c 24             	cmp    (%esp),%ecx
f0103d2b:	0f 87 07 01 00 00    	ja     f0103e38 <__umoddi3+0x168>
f0103d31:	89 f2                	mov    %esi,%edx
f0103d33:	8b 34 24             	mov    (%esp),%esi
f0103d36:	29 ce                	sub    %ecx,%esi
f0103d38:	19 ea                	sbb    %ebp,%edx
f0103d3a:	89 34 24             	mov    %esi,(%esp)
f0103d3d:	8b 04 24             	mov    (%esp),%eax
f0103d40:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103d44:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103d48:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103d4c:	83 c4 1c             	add    $0x1c,%esp
f0103d4f:	c3                   	ret    
f0103d50:	85 c9                	test   %ecx,%ecx
f0103d52:	75 0b                	jne    f0103d5f <__umoddi3+0x8f>
f0103d54:	b8 01 00 00 00       	mov    $0x1,%eax
f0103d59:	31 d2                	xor    %edx,%edx
f0103d5b:	f7 f1                	div    %ecx
f0103d5d:	89 c1                	mov    %eax,%ecx
f0103d5f:	89 f0                	mov    %esi,%eax
f0103d61:	31 d2                	xor    %edx,%edx
f0103d63:	f7 f1                	div    %ecx
f0103d65:	8b 04 24             	mov    (%esp),%eax
f0103d68:	f7 f1                	div    %ecx
f0103d6a:	eb 98                	jmp    f0103d04 <__umoddi3+0x34>
f0103d6c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103d70:	89 f2                	mov    %esi,%edx
f0103d72:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103d76:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103d7a:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103d7e:	83 c4 1c             	add    $0x1c,%esp
f0103d81:	c3                   	ret    
f0103d82:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103d88:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103d8d:	89 e8                	mov    %ebp,%eax
f0103d8f:	bd 20 00 00 00       	mov    $0x20,%ebp
f0103d94:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0103d98:	89 fa                	mov    %edi,%edx
f0103d9a:	d3 e0                	shl    %cl,%eax
f0103d9c:	89 e9                	mov    %ebp,%ecx
f0103d9e:	d3 ea                	shr    %cl,%edx
f0103da0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103da5:	09 c2                	or     %eax,%edx
f0103da7:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103dab:	89 14 24             	mov    %edx,(%esp)
f0103dae:	89 f2                	mov    %esi,%edx
f0103db0:	d3 e7                	shl    %cl,%edi
f0103db2:	89 e9                	mov    %ebp,%ecx
f0103db4:	d3 ea                	shr    %cl,%edx
f0103db6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103dbb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103dbf:	d3 e6                	shl    %cl,%esi
f0103dc1:	89 e9                	mov    %ebp,%ecx
f0103dc3:	d3 e8                	shr    %cl,%eax
f0103dc5:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103dca:	09 f0                	or     %esi,%eax
f0103dcc:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103dd0:	f7 34 24             	divl   (%esp)
f0103dd3:	d3 e6                	shl    %cl,%esi
f0103dd5:	89 74 24 08          	mov    %esi,0x8(%esp)
f0103dd9:	89 d6                	mov    %edx,%esi
f0103ddb:	f7 e7                	mul    %edi
f0103ddd:	39 d6                	cmp    %edx,%esi
f0103ddf:	89 c1                	mov    %eax,%ecx
f0103de1:	89 d7                	mov    %edx,%edi
f0103de3:	72 3f                	jb     f0103e24 <__umoddi3+0x154>
f0103de5:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0103de9:	72 35                	jb     f0103e20 <__umoddi3+0x150>
f0103deb:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103def:	29 c8                	sub    %ecx,%eax
f0103df1:	19 fe                	sbb    %edi,%esi
f0103df3:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103df8:	89 f2                	mov    %esi,%edx
f0103dfa:	d3 e8                	shr    %cl,%eax
f0103dfc:	89 e9                	mov    %ebp,%ecx
f0103dfe:	d3 e2                	shl    %cl,%edx
f0103e00:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103e05:	09 d0                	or     %edx,%eax
f0103e07:	89 f2                	mov    %esi,%edx
f0103e09:	d3 ea                	shr    %cl,%edx
f0103e0b:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103e0f:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103e13:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103e17:	83 c4 1c             	add    $0x1c,%esp
f0103e1a:	c3                   	ret    
f0103e1b:	90                   	nop
f0103e1c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103e20:	39 d6                	cmp    %edx,%esi
f0103e22:	75 c7                	jne    f0103deb <__umoddi3+0x11b>
f0103e24:	89 d7                	mov    %edx,%edi
f0103e26:	89 c1                	mov    %eax,%ecx
f0103e28:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f0103e2c:	1b 3c 24             	sbb    (%esp),%edi
f0103e2f:	eb ba                	jmp    f0103deb <__umoddi3+0x11b>
f0103e31:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103e38:	39 f5                	cmp    %esi,%ebp
f0103e3a:	0f 82 f1 fe ff ff    	jb     f0103d31 <__umoddi3+0x61>
f0103e40:	e9 f8 fe ff ff       	jmp    f0103d3d <__umoddi3+0x6d>
