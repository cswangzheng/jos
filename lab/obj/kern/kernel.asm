
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
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
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
f0100034:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

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
f0100046:	b8 ac 79 11 f0       	mov    $0xf01179ac,%eax
f010004b:	2d 04 73 11 f0       	sub    $0xf0117304,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 04 73 11 f0 	movl   $0xf0117304,(%esp)
f0100063:	e8 ce 38 00 00       	call   f0103936 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 8e 04 00 00       	call   f01004fb <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 40 3e 10 f0 	movl   $0xf0103e40,(%esp)
f010007c:	e8 b5 2c 00 00       	call   f0102d36 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 af 11 00 00       	call   f0101235 <mem_init>

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
f010009f:	83 3d 20 73 11 f0 00 	cmpl   $0x0,0xf0117320
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 20 73 11 f0    	mov    %esi,0xf0117320

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
f01000c1:	c7 04 24 5b 3e 10 f0 	movl   $0xf0103e5b,(%esp)
f01000c8:	e8 69 2c 00 00       	call   f0102d36 <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 2a 2c 00 00       	call   f0102d03 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 bc 4c 10 f0 	movl   $0xf0104cbc,(%esp)
f01000e0:	e8 51 2c 00 00       	call   f0102d36 <cprintf>
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
f010010b:	c7 04 24 73 3e 10 f0 	movl   $0xf0103e73,(%esp)
f0100112:	e8 1f 2c 00 00       	call   f0102d36 <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 dd 2b 00 00       	call   f0102d03 <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 bc 4c 10 f0 	movl   $0xf0104cbc,(%esp)
f010012d:	e8 04 2c 00 00       	call   f0102d36 <cprintf>
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
f0100179:	8b 15 64 75 11 f0    	mov    0xf0117564,%edx
f010017f:	88 82 60 73 11 f0    	mov    %al,-0xfee8ca0(%edx)
f0100185:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f0100188:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f010018d:	ba 00 00 00 00       	mov    $0x0,%edx
f0100192:	0f 44 c2             	cmove  %edx,%eax
f0100195:	a3 64 75 11 f0       	mov    %eax,0xf0117564
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
f010021c:	a1 00 73 11 f0       	mov    0xf0117300,%eax
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
f0100262:	0f b7 15 74 75 11 f0 	movzwl 0xf0117574,%edx
f0100269:	66 85 d2             	test   %dx,%dx
f010026c:	0f 84 e3 00 00 00    	je     f0100355 <cons_putc+0x1ae>
			crt_pos--;
f0100272:	83 ea 01             	sub    $0x1,%edx
f0100275:	66 89 15 74 75 11 f0 	mov    %dx,0xf0117574
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010027c:	0f b7 d2             	movzwl %dx,%edx
f010027f:	b0 00                	mov    $0x0,%al
f0100281:	83 c8 20             	or     $0x20,%eax
f0100284:	8b 0d 70 75 11 f0    	mov    0xf0117570,%ecx
f010028a:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f010028e:	eb 78                	jmp    f0100308 <cons_putc+0x161>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100290:	66 83 05 74 75 11 f0 	addw   $0x50,0xf0117574
f0100297:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100298:	0f b7 05 74 75 11 f0 	movzwl 0xf0117574,%eax
f010029f:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01002a5:	c1 e8 16             	shr    $0x16,%eax
f01002a8:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01002ab:	c1 e0 04             	shl    $0x4,%eax
f01002ae:	66 a3 74 75 11 f0    	mov    %ax,0xf0117574
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
f01002ea:	0f b7 15 74 75 11 f0 	movzwl 0xf0117574,%edx
f01002f1:	0f b7 da             	movzwl %dx,%ebx
f01002f4:	8b 0d 70 75 11 f0    	mov    0xf0117570,%ecx
f01002fa:	66 89 04 59          	mov    %ax,(%ecx,%ebx,2)
f01002fe:	83 c2 01             	add    $0x1,%edx
f0100301:	66 89 15 74 75 11 f0 	mov    %dx,0xf0117574
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100308:	66 81 3d 74 75 11 f0 	cmpw   $0x7cf,0xf0117574
f010030f:	cf 07 
f0100311:	76 42                	jbe    f0100355 <cons_putc+0x1ae>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100313:	a1 70 75 11 f0       	mov    0xf0117570,%eax
f0100318:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010031f:	00 
f0100320:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100326:	89 54 24 04          	mov    %edx,0x4(%esp)
f010032a:	89 04 24             	mov    %eax,(%esp)
f010032d:	e8 5f 36 00 00       	call   f0103991 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100332:	8b 15 70 75 11 f0    	mov    0xf0117570,%edx
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
f010034d:	66 83 2d 74 75 11 f0 	subw   $0x50,0xf0117574
f0100354:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100355:	8b 0d 6c 75 11 f0    	mov    0xf011756c,%ecx
f010035b:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100360:	89 ca                	mov    %ecx,%edx
f0100362:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100363:	0f b7 35 74 75 11 f0 	movzwl 0xf0117574,%esi
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
f01003ae:	83 0d 68 75 11 f0 40 	orl    $0x40,0xf0117568
		return 0;
f01003b5:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003ba:	e9 c4 00 00 00       	jmp    f0100483 <kbd_proc_data+0xf8>
	} else if (data & 0x80) {
f01003bf:	84 c0                	test   %al,%al
f01003c1:	79 37                	jns    f01003fa <kbd_proc_data+0x6f>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003c3:	8b 0d 68 75 11 f0    	mov    0xf0117568,%ecx
f01003c9:	89 cb                	mov    %ecx,%ebx
f01003cb:	83 e3 40             	and    $0x40,%ebx
f01003ce:	83 e0 7f             	and    $0x7f,%eax
f01003d1:	85 db                	test   %ebx,%ebx
f01003d3:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01003d6:	0f b6 d2             	movzbl %dl,%edx
f01003d9:	0f b6 82 c0 3e 10 f0 	movzbl -0xfefc140(%edx),%eax
f01003e0:	83 c8 40             	or     $0x40,%eax
f01003e3:	0f b6 c0             	movzbl %al,%eax
f01003e6:	f7 d0                	not    %eax
f01003e8:	21 c1                	and    %eax,%ecx
f01003ea:	89 0d 68 75 11 f0    	mov    %ecx,0xf0117568
		return 0;
f01003f0:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003f5:	e9 89 00 00 00       	jmp    f0100483 <kbd_proc_data+0xf8>
	} else if (shift & E0ESC) {
f01003fa:	8b 0d 68 75 11 f0    	mov    0xf0117568,%ecx
f0100400:	f6 c1 40             	test   $0x40,%cl
f0100403:	74 0e                	je     f0100413 <kbd_proc_data+0x88>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100405:	89 c2                	mov    %eax,%edx
f0100407:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f010040a:	83 e1 bf             	and    $0xffffffbf,%ecx
f010040d:	89 0d 68 75 11 f0    	mov    %ecx,0xf0117568
	}

	shift |= shiftcode[data];
f0100413:	0f b6 d2             	movzbl %dl,%edx
f0100416:	0f b6 82 c0 3e 10 f0 	movzbl -0xfefc140(%edx),%eax
f010041d:	0b 05 68 75 11 f0    	or     0xf0117568,%eax
	shift ^= togglecode[data];
f0100423:	0f b6 8a c0 3f 10 f0 	movzbl -0xfefc040(%edx),%ecx
f010042a:	31 c8                	xor    %ecx,%eax
f010042c:	a3 68 75 11 f0       	mov    %eax,0xf0117568

	c = charcode[shift & (CTL | SHIFT)][data];
f0100431:	89 c1                	mov    %eax,%ecx
f0100433:	83 e1 03             	and    $0x3,%ecx
f0100436:	8b 0c 8d c0 40 10 f0 	mov    -0xfefbf40(,%ecx,4),%ecx
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
f010046c:	c7 04 24 8d 3e 10 f0 	movl   $0xf0103e8d,(%esp)
f0100473:	e8 be 28 00 00       	call   f0102d36 <cprintf>
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
f0100491:	83 3d 40 73 11 f0 00 	cmpl   $0x0,0xf0117340
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
f01004c8:	8b 15 60 75 11 f0    	mov    0xf0117560,%edx
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
f01004d3:	3b 15 64 75 11 f0    	cmp    0xf0117564,%edx
f01004d9:	74 1e                	je     f01004f9 <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f01004db:	0f b6 82 60 73 11 f0 	movzbl -0xfee8ca0(%edx),%eax
f01004e2:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f01004e5:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004eb:	b9 00 00 00 00       	mov    $0x0,%ecx
f01004f0:	0f 44 d1             	cmove  %ecx,%edx
f01004f3:	89 15 60 75 11 f0    	mov    %edx,0xf0117560
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
f0100521:	c7 05 6c 75 11 f0 b4 	movl   $0x3b4,0xf011756c
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
f0100539:	c7 05 6c 75 11 f0 d4 	movl   $0x3d4,0xf011756c
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
f0100548:	8b 0d 6c 75 11 f0    	mov    0xf011756c,%ecx
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
f010056d:	89 35 70 75 11 f0    	mov    %esi,0xf0117570
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100573:	0f b6 d8             	movzbl %al,%ebx
f0100576:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100578:	66 89 3d 74 75 11 f0 	mov    %di,0xf0117574
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
f01005ce:	a3 40 73 11 f0       	mov    %eax,0xf0117340
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
f01005dd:	c7 04 24 99 3e 10 f0 	movl   $0xf0103e99,(%esp)
f01005e4:	e8 4d 27 00 00       	call   f0102d36 <cprintf>
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
f0100626:	c7 04 24 d0 40 10 f0 	movl   $0xf01040d0,(%esp)
f010062d:	e8 04 27 00 00       	call   f0102d36 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100632:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100639:	00 
f010063a:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100641:	f0 
f0100642:	c7 04 24 94 41 10 f0 	movl   $0xf0104194,(%esp)
f0100649:	e8 e8 26 00 00       	call   f0102d36 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010064e:	c7 44 24 08 35 3e 10 	movl   $0x103e35,0x8(%esp)
f0100655:	00 
f0100656:	c7 44 24 04 35 3e 10 	movl   $0xf0103e35,0x4(%esp)
f010065d:	f0 
f010065e:	c7 04 24 b8 41 10 f0 	movl   $0xf01041b8,(%esp)
f0100665:	e8 cc 26 00 00       	call   f0102d36 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010066a:	c7 44 24 08 04 73 11 	movl   $0x117304,0x8(%esp)
f0100671:	00 
f0100672:	c7 44 24 04 04 73 11 	movl   $0xf0117304,0x4(%esp)
f0100679:	f0 
f010067a:	c7 04 24 dc 41 10 f0 	movl   $0xf01041dc,(%esp)
f0100681:	e8 b0 26 00 00       	call   f0102d36 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100686:	c7 44 24 08 ac 79 11 	movl   $0x1179ac,0x8(%esp)
f010068d:	00 
f010068e:	c7 44 24 04 ac 79 11 	movl   $0xf01179ac,0x4(%esp)
f0100695:	f0 
f0100696:	c7 04 24 00 42 10 f0 	movl   $0xf0104200,(%esp)
f010069d:	e8 94 26 00 00       	call   f0102d36 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
f01006a2:	b8 ab 7d 11 f0       	mov    $0xf0117dab,%eax
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
f01006be:	c7 04 24 24 42 10 f0 	movl   $0xf0104224,(%esp)
f01006c5:	e8 6c 26 00 00       	call   f0102d36 <cprintf>
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
f01006dd:	8b 83 24 43 10 f0    	mov    -0xfefbcdc(%ebx),%eax
f01006e3:	89 44 24 08          	mov    %eax,0x8(%esp)
f01006e7:	8b 83 20 43 10 f0    	mov    -0xfefbce0(%ebx),%eax
f01006ed:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006f1:	c7 04 24 e9 40 10 f0 	movl   $0xf01040e9,(%esp)
f01006f8:	e8 39 26 00 00       	call   f0102d36 <cprintf>
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
f0100741:	c7 04 24 f2 40 10 f0 	movl   $0xf01040f2,(%esp)
f0100748:	e8 e9 25 00 00       	call   f0102d36 <cprintf>
	
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
f0100783:	c7 04 24 50 42 10 f0 	movl   $0xf0104250,(%esp)
f010078a:	e8 a7 25 00 00       	call   f0102d36 <cprintf>
			struct Eipdebuginfo info;
			info.eip_file = "<unknown>";
f010078f:	c7 45 d0 04 41 10 f0 	movl   $0xf0104104,-0x30(%ebp)
			info.eip_line = 0;
f0100796:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
			info.eip_fn_name = "<unknown>";
f010079d:	c7 45 d8 04 41 10 f0 	movl   $0xf0104104,-0x28(%ebp)
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
f01007bc:	e8 6f 26 00 00       	call   f0102e30 <debuginfo_eip>
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
f0100807:	c7 04 24 0e 41 10 f0 	movl   $0xf010410e,(%esp)
f010080e:	e8 23 25 00 00       	call   f0102d36 <cprintf>
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
f010084e:	c7 04 24 84 42 10 f0 	movl   $0xf0104284,(%esp)
f0100855:	e8 dc 24 00 00       	call   f0102d36 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010085a:	c7 04 24 a8 42 10 f0 	movl   $0xf01042a8,(%esp)
f0100861:	e8 d0 24 00 00       	call   f0102d36 <cprintf>


	while (1) {
		buf = readline("K> ");
f0100866:	c7 04 24 20 41 10 f0 	movl   $0xf0104120,(%esp)
f010086d:	e8 3e 2e 00 00       	call   f01036b0 <readline>
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
f010089a:	c7 04 24 24 41 10 f0 	movl   $0xf0104124,(%esp)
f01008a1:	e8 35 30 00 00       	call   f01038db <strchr>
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
f01008bc:	c7 04 24 29 41 10 f0 	movl   $0xf0104129,(%esp)
f01008c3:	e8 6e 24 00 00       	call   f0102d36 <cprintf>
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
f01008eb:	c7 04 24 24 41 10 f0 	movl   $0xf0104124,(%esp)
f01008f2:	e8 e4 2f 00 00       	call   f01038db <strchr>
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
f010090d:	bb 20 43 10 f0       	mov    $0xf0104320,%ebx
f0100912:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100917:	8b 03                	mov    (%ebx),%eax
f0100919:	89 44 24 04          	mov    %eax,0x4(%esp)
f010091d:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100920:	89 04 24             	mov    %eax,(%esp)
f0100923:	e8 38 2f 00 00       	call   f0103860 <strcmp>
f0100928:	85 c0                	test   %eax,%eax
f010092a:	75 24                	jne    f0100950 <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f010092c:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f010092f:	8b 55 08             	mov    0x8(%ebp),%edx
f0100932:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100936:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100939:	89 54 24 04          	mov    %edx,0x4(%esp)
f010093d:	89 34 24             	mov    %esi,(%esp)
f0100940:	ff 14 85 28 43 10 f0 	call   *-0xfefbcd8(,%eax,4)


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
f0100962:	c7 04 24 46 41 10 f0 	movl   $0xf0104146,(%esp)
f0100969:	e8 c8 23 00 00       	call   f0102d36 <cprintf>
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
f0100987:	83 3d 7c 75 11 f0 00 	cmpl   $0x0,0xf011757c
f010098e:	75 11                	jne    f01009a1 <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100990:	ba ab 89 11 f0       	mov    $0xf01189ab,%edx
f0100995:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010099b:	89 15 7c 75 11 f0    	mov    %edx,0xf011757c
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = ROUNDUP(nextfree, PGSIZE);
f01009a1:	8b 15 7c 75 11 f0    	mov    0xf011757c,%edx
f01009a7:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f01009ad:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	nextfree = result + n;
f01009b3:	01 d0                	add    %edx,%eax
f01009b5:	a3 7c 75 11 f0       	mov    %eax,0xf011757c
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
f01009e1:	3b 05 a0 79 11 f0    	cmp    0xf01179a0,%eax
f01009e7:	72 20                	jb     f0100a09 <check_va2pa+0x4b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01009e9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01009ed:	c7 44 24 08 44 43 10 	movl   $0xf0104344,0x8(%esp)
f01009f4:	f0 
f01009f5:	c7 44 24 04 e8 02 00 	movl   $0x2e8,0x4(%esp)
f01009fc:	00 
f01009fd:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
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
f0100a40:	e8 83 22 00 00       	call   f0102cc8 <mc146818_read>
f0100a45:	89 c6                	mov    %eax,%esi
f0100a47:	83 c3 01             	add    $0x1,%ebx
f0100a4a:	89 1c 24             	mov    %ebx,(%esp)
f0100a4d:	e8 76 22 00 00       	call   f0102cc8 <mc146818_read>
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
f0100a78:	8b 1d 80 75 11 f0    	mov    0xf0117580,%ebx
f0100a7e:	85 db                	test   %ebx,%ebx
f0100a80:	75 1c                	jne    f0100a9e <check_page_free_list+0x3d>
		panic("'page_free_list' is a null pointer!");
f0100a82:	c7 44 24 08 68 43 10 	movl   $0xf0104368,0x8(%esp)
f0100a89:	f0 
f0100a8a:	c7 44 24 04 2b 02 00 	movl   $0x22b,0x4(%esp)
f0100a91:	00 
f0100a92:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
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
f0100ab0:	2b 05 a8 79 11 f0    	sub    0xf01179a8,%eax
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
f0100ae8:	89 1d 80 75 11 f0    	mov    %ebx,0xf0117580
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100aee:	85 db                	test   %ebx,%ebx
f0100af0:	74 67                	je     f0100b59 <check_page_free_list+0xf8>
f0100af2:	89 d8                	mov    %ebx,%eax
f0100af4:	2b 05 a8 79 11 f0    	sub    0xf01179a8,%eax
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
f0100b0e:	3b 15 a0 79 11 f0    	cmp    0xf01179a0,%edx
f0100b14:	72 20                	jb     f0100b36 <check_page_free_list+0xd5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b16:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b1a:	c7 44 24 08 44 43 10 	movl   $0xf0104344,0x8(%esp)
f0100b21:	f0 
f0100b22:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100b29:	00 
f0100b2a:	c7 04 24 38 4a 10 f0 	movl   $0xf0104a38,(%esp)
f0100b31:	e8 5e f5 ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b36:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100b3d:	00 
f0100b3e:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100b45:	00 
	return (void *)(pa + KERNBASE);
f0100b46:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b4b:	89 04 24             	mov    %eax,(%esp)
f0100b4e:	e8 e3 2d 00 00       	call   f0103936 <memset>
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
f0100b66:	8b 15 80 75 11 f0    	mov    0xf0117580,%edx
f0100b6c:	85 d2                	test   %edx,%edx
f0100b6e:	0f 84 f6 01 00 00    	je     f0100d6a <check_page_free_list+0x309>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b74:	8b 1d a8 79 11 f0    	mov    0xf01179a8,%ebx
f0100b7a:	39 da                	cmp    %ebx,%edx
f0100b7c:	72 4d                	jb     f0100bcb <check_page_free_list+0x16a>
		assert(pp < pages + npages);
f0100b7e:	a1 a0 79 11 f0       	mov    0xf01179a0,%eax
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
f0100bcb:	c7 44 24 0c 46 4a 10 	movl   $0xf0104a46,0xc(%esp)
f0100bd2:	f0 
f0100bd3:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0100bda:	f0 
f0100bdb:	c7 44 24 04 45 02 00 	movl   $0x245,0x4(%esp)
f0100be2:	00 
f0100be3:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0100bea:	e8 a5 f4 ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0100bef:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100bf2:	72 24                	jb     f0100c18 <check_page_free_list+0x1b7>
f0100bf4:	c7 44 24 0c 67 4a 10 	movl   $0xf0104a67,0xc(%esp)
f0100bfb:	f0 
f0100bfc:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0100c03:	f0 
f0100c04:	c7 44 24 04 46 02 00 	movl   $0x246,0x4(%esp)
f0100c0b:	00 
f0100c0c:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0100c13:	e8 7c f4 ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c18:	89 d0                	mov    %edx,%eax
f0100c1a:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100c1d:	a8 07                	test   $0x7,%al
f0100c1f:	74 24                	je     f0100c45 <check_page_free_list+0x1e4>
f0100c21:	c7 44 24 0c 8c 43 10 	movl   $0xf010438c,0xc(%esp)
f0100c28:	f0 
f0100c29:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0100c30:	f0 
f0100c31:	c7 44 24 04 47 02 00 	movl   $0x247,0x4(%esp)
f0100c38:	00 
f0100c39:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0100c40:	e8 4f f4 ff ff       	call   f0100094 <_panic>
f0100c45:	c1 f8 03             	sar    $0x3,%eax
f0100c48:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c4b:	85 c0                	test   %eax,%eax
f0100c4d:	75 24                	jne    f0100c73 <check_page_free_list+0x212>
f0100c4f:	c7 44 24 0c 7b 4a 10 	movl   $0xf0104a7b,0xc(%esp)
f0100c56:	f0 
f0100c57:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0100c5e:	f0 
f0100c5f:	c7 44 24 04 4a 02 00 	movl   $0x24a,0x4(%esp)
f0100c66:	00 
f0100c67:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0100c6e:	e8 21 f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c73:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c78:	75 24                	jne    f0100c9e <check_page_free_list+0x23d>
f0100c7a:	c7 44 24 0c 8c 4a 10 	movl   $0xf0104a8c,0xc(%esp)
f0100c81:	f0 
f0100c82:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0100c89:	f0 
f0100c8a:	c7 44 24 04 4b 02 00 	movl   $0x24b,0x4(%esp)
f0100c91:	00 
f0100c92:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0100c99:	e8 f6 f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c9e:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100ca3:	75 24                	jne    f0100cc9 <check_page_free_list+0x268>
f0100ca5:	c7 44 24 0c c0 43 10 	movl   $0xf01043c0,0xc(%esp)
f0100cac:	f0 
f0100cad:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0100cb4:	f0 
f0100cb5:	c7 44 24 04 4c 02 00 	movl   $0x24c,0x4(%esp)
f0100cbc:	00 
f0100cbd:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0100cc4:	e8 cb f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100cc9:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100cce:	75 24                	jne    f0100cf4 <check_page_free_list+0x293>
f0100cd0:	c7 44 24 0c a5 4a 10 	movl   $0xf0104aa5,0xc(%esp)
f0100cd7:	f0 
f0100cd8:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0100cdf:	f0 
f0100ce0:	c7 44 24 04 4d 02 00 	movl   $0x24d,0x4(%esp)
f0100ce7:	00 
f0100ce8:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
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
f0100d09:	c7 44 24 08 44 43 10 	movl   $0xf0104344,0x8(%esp)
f0100d10:	f0 
f0100d11:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100d18:	00 
f0100d19:	c7 04 24 38 4a 10 f0 	movl   $0xf0104a38,(%esp)
f0100d20:	e8 6f f3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100d25:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f0100d2b:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0100d2e:	76 29                	jbe    f0100d59 <check_page_free_list+0x2f8>
f0100d30:	c7 44 24 0c e4 43 10 	movl   $0xf01043e4,0xc(%esp)
f0100d37:	f0 
f0100d38:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0100d3f:	f0 
f0100d40:	c7 44 24 04 4e 02 00 	movl   $0x24e,0x4(%esp)
f0100d47:	00 
f0100d48:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
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
f0100d6a:	c7 44 24 0c bf 4a 10 	movl   $0xf0104abf,0xc(%esp)
f0100d71:	f0 
f0100d72:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0100d79:	f0 
f0100d7a:	c7 44 24 04 56 02 00 	movl   $0x256,0x4(%esp)
f0100d81:	00 
f0100d82:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0100d89:	e8 06 f3 ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f0100d8e:	85 f6                	test   %esi,%esi
f0100d90:	7f 24                	jg     f0100db6 <check_page_free_list+0x355>
f0100d92:	c7 44 24 0c d1 4a 10 	movl   $0xf0104ad1,0xc(%esp)
f0100d99:	f0 
f0100d9a:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0100da1:	f0 
f0100da2:	c7 44 24 04 57 02 00 	movl   $0x257,0x4(%esp)
f0100da9:	00 
f0100daa:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
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
f0100dc6:	c7 05 80 75 11 f0 00 	movl   $0x0,0xf0117580
f0100dcd:	00 00 00 
	physaddr_t pgnum_IOPHYSMEM = PGNUM (IOPHYSMEM);
	physaddr_t pgnum_EXTPHYSMEM =PGNUM ( PADDR (ROUNDUP(pages+npages* sizeof (struct Page),PGSIZE)));
f0100dd0:	a1 a0 79 11 f0       	mov    0xf01179a0,%eax
f0100dd5:	89 c6                	mov    %eax,%esi
f0100dd7:	c1 e6 06             	shl    $0x6,%esi
f0100dda:	03 35 a8 79 11 f0    	add    0xf01179a8,%esi
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
f0100df8:	c7 44 24 08 2c 44 10 	movl   $0xf010442c,0x8(%esp)
f0100dff:	f0 
f0100e00:	c7 44 24 04 02 01 00 	movl   $0x102,0x4(%esp)
f0100e07:	00 
f0100e08:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
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
f0100e3a:	03 1d a8 79 11 f0    	add    0xf01179a8,%ebx
f0100e40:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
			pages[i].pp_link = page_free_list;
f0100e46:	89 0b                	mov    %ecx,(%ebx)
			page_free_list = &pages[i];
f0100e48:	89 d1                	mov    %edx,%ecx
f0100e4a:	03 0d a8 79 11 f0    	add    0xf01179a8,%ecx
f0100e50:	eb 2b                	jmp    f0100e7d <page_init+0xbf>
			//a++;
		}
		else if( i>pgnum_EXTPHYSMEM)
f0100e52:	39 c6                	cmp    %eax,%esi
f0100e54:	73 1a                	jae    f0100e70 <page_init+0xb2>
		{
			pages[i].pp_ref = 0;
f0100e56:	8b 1d a8 79 11 f0    	mov    0xf01179a8,%ebx
f0100e5c:	66 c7 44 13 04 00 00 	movw   $0x0,0x4(%ebx,%edx,1)
			pages[i].pp_link = page_free_list;
f0100e63:	89 0c 13             	mov    %ecx,(%ebx,%edx,1)
			page_free_list = &pages[i];
f0100e66:	89 d1                	mov    %edx,%ecx
f0100e68:	03 0d a8 79 11 f0    	add    0xf01179a8,%ecx
f0100e6e:	eb 0d                	jmp    f0100e7d <page_init+0xbf>
			//b++;
		}
		else
		{
			pages[i].pp_ref = 1;
f0100e70:	8b 1d a8 79 11 f0    	mov    0xf01179a8,%ebx
f0100e76:	66 c7 44 13 04 01 00 	movw   $0x1,0x4(%ebx,%edx,1)
	//size_t c=0;
	page_free_list = NULL;
	physaddr_t pgnum_IOPHYSMEM = PGNUM (IOPHYSMEM);
	physaddr_t pgnum_EXTPHYSMEM =PGNUM ( PADDR (ROUNDUP(pages+npages* sizeof (struct Page),PGSIZE)));
	//PGNUM (ROUNDUP(pages+npages* sizeof (struct Page),PGSIZE))-PGNUM(kern_pgdir)+PGNUM(EXTPHYSMEM);
	for (i = 1; i < npages; i++) 
f0100e7d:	83 c0 01             	add    $0x1,%eax
f0100e80:	83 c2 08             	add    $0x8,%edx
f0100e83:	39 05 a0 79 11 f0    	cmp    %eax,0xf01179a0
f0100e89:	77 a6                	ja     f0100e31 <page_init+0x73>
f0100e8b:	89 0d 80 75 11 f0    	mov    %ecx,0xf0117580
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
f0100ea7:	8b 1d 80 75 11 f0    	mov    0xf0117580,%ebx
f0100ead:	85 db                	test   %ebx,%ebx
f0100eaf:	74 6c                	je     f0100f1d <page_alloc+0x85>
	{
		struct Page * temp_alloc_page = page_free_list;
		if(page_free_list->pp_link!=NULL)
f0100eb1:	8b 13                	mov    (%ebx),%edx
			page_free_list=page_free_list->pp_link;
f0100eb3:	89 15 80 75 11 f0    	mov    %edx,0xf0117580
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
f0100ec0:	2b 05 a8 79 11 f0    	sub    0xf01179a8,%eax
f0100ec6:	c1 f8 03             	sar    $0x3,%eax
f0100ec9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ecc:	89 c2                	mov    %eax,%edx
f0100ece:	c1 ea 0c             	shr    $0xc,%edx
f0100ed1:	3b 15 a0 79 11 f0    	cmp    0xf01179a0,%edx
f0100ed7:	72 20                	jb     f0100ef9 <page_alloc+0x61>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ed9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100edd:	c7 44 24 08 44 43 10 	movl   $0xf0104344,0x8(%esp)
f0100ee4:	f0 
f0100ee5:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100eec:	00 
f0100eed:	c7 04 24 38 4a 10 f0 	movl   $0xf0104a38,(%esp)
f0100ef4:	e8 9b f1 ff ff       	call   f0100094 <_panic>
			memset(page2kva(temp_alloc_page), 0, PGSIZE);
f0100ef9:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100f00:	00 
f0100f01:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100f08:	00 
	return (void *)(pa + KERNBASE);
f0100f09:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100f0e:	89 04 24             	mov    %eax,(%esp)
f0100f11:	e8 20 2a 00 00       	call   f0103936 <memset>
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
f0100f2b:	8b 15 80 75 11 f0    	mov    0xf0117580,%edx
f0100f31:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100f33:	a3 80 75 11 f0       	mov    %eax,0xf0117580
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
f0100f83:	3b 15 a0 79 11 f0    	cmp    0xf01179a0,%edx
f0100f89:	72 20                	jb     f0100fab <pgdir_walk+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f8b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f8f:	c7 44 24 08 44 43 10 	movl   $0xf0104344,0x8(%esp)
f0100f96:	f0 
f0100f97:	c7 44 24 04 73 01 00 	movl   $0x173,0x4(%esp)
f0100f9e:	00 
f0100f9f:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
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
f0100fd9:	2b 05 a8 79 11 f0    	sub    0xf01179a8,%eax
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
f0100ff4:	3b 15 a0 79 11 f0    	cmp    0xf01179a0,%edx
f0100ffa:	72 20                	jb     f010101c <pgdir_walk+0xbf>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ffc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101000:	c7 44 24 08 44 43 10 	movl   $0xf0104344,0x8(%esp)
f0101007:	f0 
f0101008:	c7 44 24 04 7f 01 00 	movl   $0x17f,0x4(%esp)
f010100f:	00 
f0101010:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
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
f0101058:	74 0f                	je     f0101069 <boot_map_region+0x28>
		size=ROUNDUP(size,PGSIZE);//panic(" Size must be a multiple of PGSIZE.");
f010105a:	89 c8                	mov    %ecx,%eax
f010105c:	05 ff 0f 00 00       	add    $0xfff,%eax
f0101061:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101066:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	pte_t *pte ;
	size_t i=0;
	while(i<size)
f0101069:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010106d:	74 3d                	je     f01010ac <boot_map_region+0x6b>
{
	// Fill this function in
	if(size%PGSIZE!=0)
		size=ROUNDUP(size,PGSIZE);//panic(" Size must be a multiple of PGSIZE.");
	pte_t *pte ;
	size_t i=0;
f010106f:	bb 00 00 00 00       	mov    $0x0,%ebx
	while(i<size)
	{
		pte=pgdir_walk(pgdir, (void *)va, 1);
		*pte= pa|perm|PTE_P;
f0101074:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101077:	83 c8 01             	or     $0x1,%eax
f010107a:	89 45 dc             	mov    %eax,-0x24(%ebp)
// above UTOP. As such, it should *not* change the pp_ref field on the
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f010107d:	8b 75 08             	mov    0x8(%ebp),%esi
f0101080:	01 de                	add    %ebx,%esi
		size=ROUNDUP(size,PGSIZE);//panic(" Size must be a multiple of PGSIZE.");
	pte_t *pte ;
	size_t i=0;
	while(i<size)
	{
		pte=pgdir_walk(pgdir, (void *)va, 1);
f0101082:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101089:	00 
// above UTOP. As such, it should *not* change the pp_ref field on the
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f010108a:	8d 04 3b             	lea    (%ebx,%edi,1),%eax
		size=ROUNDUP(size,PGSIZE);//panic(" Size must be a multiple of PGSIZE.");
	pte_t *pte ;
	size_t i=0;
	while(i<size)
	{
		pte=pgdir_walk(pgdir, (void *)va, 1);
f010108d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101091:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101094:	89 04 24             	mov    %eax,(%esp)
f0101097:	e8 c1 fe ff ff       	call   f0100f5d <pgdir_walk>
		*pte= pa|perm|PTE_P;
f010109c:	0b 75 dc             	or     -0x24(%ebp),%esi
f010109f:	89 30                	mov    %esi,(%eax)
		pa+=PGSIZE;
		va+=PGSIZE;
		i+=PGSIZE;
f01010a1:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// Fill this function in
	if(size%PGSIZE!=0)
		size=ROUNDUP(size,PGSIZE);//panic(" Size must be a multiple of PGSIZE.");
	pte_t *pte ;
	size_t i=0;
	while(i<size)
f01010a7:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f01010aa:	77 d1                	ja     f010107d <boot_map_region+0x3c>
		*pte= pa|perm|PTE_P;
		pa+=PGSIZE;
		va+=PGSIZE;
		i+=PGSIZE;
	}
}
f01010ac:	83 c4 2c             	add    $0x2c,%esp
f01010af:	5b                   	pop    %ebx
f01010b0:	5e                   	pop    %esi
f01010b1:	5f                   	pop    %edi
f01010b2:	5d                   	pop    %ebp
f01010b3:	c3                   	ret    

f01010b4 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01010b4:	55                   	push   %ebp
f01010b5:	89 e5                	mov    %esp,%ebp
f01010b7:	53                   	push   %ebx
f01010b8:	83 ec 14             	sub    $0x14,%esp
f01010bb:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pte = pgdir_walk(pgdir,(void *)va, 0);
f01010be:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01010c5:	00 
f01010c6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010c9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01010cd:	8b 45 08             	mov    0x8(%ebp),%eax
f01010d0:	89 04 24             	mov    %eax,(%esp)
f01010d3:	e8 85 fe ff ff       	call   f0100f5d <pgdir_walk>
	if (pte==NULL)
f01010d8:	85 c0                	test   %eax,%eax
f01010da:	74 3e                	je     f010111a <page_lookup+0x66>
	{
		return NULL;		
	}
	if (pte_store != 0) 
f01010dc:	85 db                	test   %ebx,%ebx
f01010de:	74 02                	je     f01010e2 <page_lookup+0x2e>
	{
		*pte_store = pte;
f01010e0:	89 03                	mov    %eax,(%ebx)
	}
	if (*pte & PTE_P) 
f01010e2:	8b 00                	mov    (%eax),%eax
f01010e4:	a8 01                	test   $0x1,%al
f01010e6:	74 39                	je     f0101121 <page_lookup+0x6d>
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010e8:	c1 e8 0c             	shr    $0xc,%eax
f01010eb:	3b 05 a0 79 11 f0    	cmp    0xf01179a0,%eax
f01010f1:	72 1c                	jb     f010110f <page_lookup+0x5b>
		panic("pa2page called with invalid pa");
f01010f3:	c7 44 24 08 50 44 10 	movl   $0xf0104450,0x8(%esp)
f01010fa:	f0 
f01010fb:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f0101102:	00 
f0101103:	c7 04 24 38 4a 10 f0 	movl   $0xf0104a38,(%esp)
f010110a:	e8 85 ef ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f010110f:	c1 e0 03             	shl    $0x3,%eax
f0101112:	03 05 a8 79 11 f0    	add    0xf01179a8,%eax
	{
		return pa2page (PTE_ADDR (*pte));
f0101118:	eb 0c                	jmp    f0101126 <page_lookup+0x72>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t *pte = pgdir_walk(pgdir,(void *)va, 0);
	if (pte==NULL)
	{
		return NULL;		
f010111a:	b8 00 00 00 00       	mov    $0x0,%eax
f010111f:	eb 05                	jmp    f0101126 <page_lookup+0x72>
	}
	if (*pte & PTE_P) 
	{
		return pa2page (PTE_ADDR (*pte));
	}
	return NULL;
f0101121:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101126:	83 c4 14             	add    $0x14,%esp
f0101129:	5b                   	pop    %ebx
f010112a:	5d                   	pop    %ebp
f010112b:	c3                   	ret    

f010112c <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010112c:	55                   	push   %ebp
f010112d:	89 e5                	mov    %esp,%ebp
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010112f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101132:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0101135:	5d                   	pop    %ebp
f0101136:	c3                   	ret    

f0101137 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101137:	55                   	push   %ebp
f0101138:	89 e5                	mov    %esp,%ebp
f010113a:	83 ec 28             	sub    $0x28,%esp
f010113d:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0101140:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0101143:	8b 75 08             	mov    0x8(%ebp),%esi
f0101146:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *pte;
	struct Page *pp= page_lookup (pgdir, va, &pte);
f0101149:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010114c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101150:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101154:	89 34 24             	mov    %esi,(%esp)
f0101157:	e8 58 ff ff ff       	call   f01010b4 <page_lookup>
	if (pp != NULL) 
f010115c:	85 c0                	test   %eax,%eax
f010115e:	74 21                	je     f0101181 <page_remove+0x4a>
	{
		page_decref (pp);//- The ref count on the physical page should decrement.
f0101160:	89 04 24             	mov    %eax,(%esp)
f0101163:	e8 d2 fd ff ff       	call   f0100f3a <page_decref>
//   - The physical page should be freed if the refcount reaches 0.
		if(pte!=NULL)
f0101168:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010116b:	85 c0                	test   %eax,%eax
f010116d:	74 06                	je     f0101175 <page_remove+0x3e>
		*pte = 0;// The pg table entry corresponding to 'va' should be set to 0. (if such a PTE exists)
f010116f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		tlb_invalidate (pgdir, va);//The TLB must be invalidated if you remove an entry from  the page table.
f0101175:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101179:	89 34 24             	mov    %esi,(%esp)
f010117c:	e8 ab ff ff ff       	call   f010112c <tlb_invalidate>
	}
}
f0101181:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0101184:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0101187:	89 ec                	mov    %ebp,%esp
f0101189:	5d                   	pop    %ebp
f010118a:	c3                   	ret    

f010118b <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{
f010118b:	55                   	push   %ebp
f010118c:	89 e5                	mov    %esp,%ebp
f010118e:	83 ec 28             	sub    $0x28,%esp
f0101191:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0101194:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0101197:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010119a:	8b 75 0c             	mov    0xc(%ebp),%esi
f010119d:	8b 7d 10             	mov    0x10(%ebp),%edi

	pte_t * pte = pgdir_walk(pgdir, (void *)va, 1) ;
f01011a0:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01011a7:	00 
f01011a8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011ac:	8b 45 08             	mov    0x8(%ebp),%eax
f01011af:	89 04 24             	mov    %eax,(%esp)
f01011b2:	e8 a6 fd ff ff       	call   f0100f5d <pgdir_walk>
f01011b7:	89 c3                	mov    %eax,%ebx
	if (pte==NULL)
f01011b9:	85 c0                	test   %eax,%eax
f01011bb:	74 66                	je     f0101223 <page_insert+0x98>
		return -E_NO_MEM;
	if (*pte & PTE_P) {
f01011bd:	8b 00                	mov    (%eax),%eax
f01011bf:	a8 01                	test   $0x1,%al
f01011c1:	74 3c                	je     f01011ff <page_insert+0x74>
		if (PTE_ADDR(*pte) == page2pa(pp))
f01011c3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01011c8:	89 f2                	mov    %esi,%edx
f01011ca:	2b 15 a8 79 11 f0    	sub    0xf01179a8,%edx
f01011d0:	c1 fa 03             	sar    $0x3,%edx
f01011d3:	c1 e2 0c             	shl    $0xc,%edx
f01011d6:	39 d0                	cmp    %edx,%eax
f01011d8:	75 16                	jne    f01011f0 <page_insert+0x65>
		{
			tlb_invalidate(pgdir, va);
f01011da:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011de:	8b 45 08             	mov    0x8(%ebp),%eax
f01011e1:	89 04 24             	mov    %eax,(%esp)
f01011e4:	e8 43 ff ff ff       	call   f010112c <tlb_invalidate>
			pp -> pp_ref --;
f01011e9:	66 83 6e 04 01       	subw   $0x1,0x4(%esi)
f01011ee:	eb 0f                	jmp    f01011ff <page_insert+0x74>
		} 
		else 
		{
			page_remove (pgdir, va);
f01011f0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011f4:	8b 45 08             	mov    0x8(%ebp),%eax
f01011f7:	89 04 24             	mov    %eax,(%esp)
f01011fa:	e8 38 ff ff ff       	call   f0101137 <page_remove>
		}
	}

	*pte = page2pa(pp)|perm|PTE_P;
f01011ff:	8b 45 14             	mov    0x14(%ebp),%eax
f0101202:	83 c8 01             	or     $0x1,%eax
f0101205:	89 f2                	mov    %esi,%edx
f0101207:	2b 15 a8 79 11 f0    	sub    0xf01179a8,%edx
f010120d:	c1 fa 03             	sar    $0x3,%edx
f0101210:	c1 e2 0c             	shl    $0xc,%edx
f0101213:	09 d0                	or     %edx,%eax
f0101215:	89 03                	mov    %eax,(%ebx)
	pp->pp_ref++;//pp->pp_ref should be incremented if the insertion succeeds.
f0101217:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	return 0;
f010121c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101221:	eb 05                	jmp    f0101228 <page_insert+0x9d>
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{

	pte_t * pte = pgdir_walk(pgdir, (void *)va, 1) ;
	if (pte==NULL)
		return -E_NO_MEM;
f0101223:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	}

	*pte = page2pa(pp)|perm|PTE_P;
	pp->pp_ref++;//pp->pp_ref should be incremented if the insertion succeeds.
	return 0;
}
f0101228:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f010122b:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010122e:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101231:	89 ec                	mov    %ebp,%esp
f0101233:	5d                   	pop    %ebp
f0101234:	c3                   	ret    

f0101235 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101235:	55                   	push   %ebp
f0101236:	89 e5                	mov    %esp,%ebp
f0101238:	57                   	push   %edi
f0101239:	56                   	push   %esi
f010123a:	53                   	push   %ebx
f010123b:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f010123e:	b8 15 00 00 00       	mov    $0x15,%eax
f0101243:	e8 e7 f7 ff ff       	call   f0100a2f <nvram_read>
f0101248:	c1 e0 0a             	shl    $0xa,%eax
f010124b:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101251:	85 c0                	test   %eax,%eax
f0101253:	0f 48 c2             	cmovs  %edx,%eax
f0101256:	c1 f8 0c             	sar    $0xc,%eax
f0101259:	a3 78 75 11 f0       	mov    %eax,0xf0117578
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f010125e:	b8 17 00 00 00       	mov    $0x17,%eax
f0101263:	e8 c7 f7 ff ff       	call   f0100a2f <nvram_read>
f0101268:	c1 e0 0a             	shl    $0xa,%eax
f010126b:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101271:	85 c0                	test   %eax,%eax
f0101273:	0f 48 c2             	cmovs  %edx,%eax
f0101276:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101279:	85 c0                	test   %eax,%eax
f010127b:	74 0e                	je     f010128b <mem_init+0x56>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f010127d:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101283:	89 15 a0 79 11 f0    	mov    %edx,0xf01179a0
f0101289:	eb 0c                	jmp    f0101297 <mem_init+0x62>
	else
		npages = npages_basemem;
f010128b:	8b 15 78 75 11 f0    	mov    0xf0117578,%edx
f0101291:	89 15 a0 79 11 f0    	mov    %edx,0xf01179a0

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f0101297:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010129a:	c1 e8 0a             	shr    $0xa,%eax
f010129d:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f01012a1:	a1 78 75 11 f0       	mov    0xf0117578,%eax
f01012a6:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012a9:	c1 e8 0a             	shr    $0xa,%eax
f01012ac:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f01012b0:	a1 a0 79 11 f0       	mov    0xf01179a0,%eax
f01012b5:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012b8:	c1 e8 0a             	shr    $0xa,%eax
f01012bb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012bf:	c7 04 24 70 44 10 f0 	movl   $0xf0104470,(%esp)
f01012c6:	e8 6b 1a 00 00       	call   f0102d36 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01012cb:	b8 00 10 00 00       	mov    $0x1000,%eax
f01012d0:	e8 af f6 ff ff       	call   f0100984 <boot_alloc>
f01012d5:	a3 a4 79 11 f0       	mov    %eax,0xf01179a4
	memset(kern_pgdir, 0, PGSIZE);
f01012da:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01012e1:	00 
f01012e2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01012e9:	00 
f01012ea:	89 04 24             	mov    %eax,(%esp)
f01012ed:	e8 44 26 00 00       	call   f0103936 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following two lines.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01012f2:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01012f7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01012fc:	77 20                	ja     f010131e <mem_init+0xe9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01012fe:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101302:	c7 44 24 08 2c 44 10 	movl   $0xf010442c,0x8(%esp)
f0101309:	f0 
f010130a:	c7 44 24 04 8b 00 00 	movl   $0x8b,0x4(%esp)
f0101311:	00 
f0101312:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101319:	e8 76 ed ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010131e:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101324:	83 ca 05             	or     $0x5,%edx
f0101327:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct Page in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:

	pages =(struct Page *) boot_alloc(npages* sizeof (struct Page));
f010132d:	a1 a0 79 11 f0       	mov    0xf01179a0,%eax
f0101332:	c1 e0 03             	shl    $0x3,%eax
f0101335:	e8 4a f6 ff ff       	call   f0100984 <boot_alloc>
f010133a:	a3 a8 79 11 f0       	mov    %eax,0xf01179a8
	memset(pages, 0, npages* sizeof (struct Page));
f010133f:	8b 15 a0 79 11 f0    	mov    0xf01179a0,%edx
f0101345:	c1 e2 03             	shl    $0x3,%edx
f0101348:	89 54 24 08          	mov    %edx,0x8(%esp)
f010134c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101353:	00 
f0101354:	89 04 24             	mov    %eax,(%esp)
f0101357:	e8 da 25 00 00       	call   f0103936 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010135c:	e8 5d fa ff ff       	call   f0100dbe <page_init>
	check_page_free_list(1);
f0101361:	b8 01 00 00 00       	mov    $0x1,%eax
f0101366:	e8 f6 f6 ff ff       	call   f0100a61 <check_page_free_list>
	int nfree;
	struct Page *fl;
	char *c;
	int i;

	if (!pages)
f010136b:	83 3d a8 79 11 f0 00 	cmpl   $0x0,0xf01179a8
f0101372:	75 1c                	jne    f0101390 <mem_init+0x15b>
		panic("'pages' is a null pointer!");
f0101374:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f010137b:	f0 
f010137c:	c7 44 24 04 68 02 00 	movl   $0x268,0x4(%esp)
f0101383:	00 
f0101384:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f010138b:	e8 04 ed ff ff       	call   f0100094 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101390:	a1 80 75 11 f0       	mov    0xf0117580,%eax
f0101395:	bb 00 00 00 00       	mov    $0x0,%ebx
f010139a:	85 c0                	test   %eax,%eax
f010139c:	74 09                	je     f01013a7 <mem_init+0x172>
		++nfree;
f010139e:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013a1:	8b 00                	mov    (%eax),%eax
f01013a3:	85 c0                	test   %eax,%eax
f01013a5:	75 f7                	jne    f010139e <mem_init+0x169>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01013a7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013ae:	e8 e5 fa ff ff       	call   f0100e98 <page_alloc>
f01013b3:	89 c6                	mov    %eax,%esi
f01013b5:	85 c0                	test   %eax,%eax
f01013b7:	75 24                	jne    f01013dd <mem_init+0x1a8>
f01013b9:	c7 44 24 0c fd 4a 10 	movl   $0xf0104afd,0xc(%esp)
f01013c0:	f0 
f01013c1:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f01013c8:	f0 
f01013c9:	c7 44 24 04 70 02 00 	movl   $0x270,0x4(%esp)
f01013d0:	00 
f01013d1:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01013d8:	e8 b7 ec ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01013dd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013e4:	e8 af fa ff ff       	call   f0100e98 <page_alloc>
f01013e9:	89 c7                	mov    %eax,%edi
f01013eb:	85 c0                	test   %eax,%eax
f01013ed:	75 24                	jne    f0101413 <mem_init+0x1de>
f01013ef:	c7 44 24 0c 13 4b 10 	movl   $0xf0104b13,0xc(%esp)
f01013f6:	f0 
f01013f7:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f01013fe:	f0 
f01013ff:	c7 44 24 04 71 02 00 	movl   $0x271,0x4(%esp)
f0101406:	00 
f0101407:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f010140e:	e8 81 ec ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101413:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010141a:	e8 79 fa ff ff       	call   f0100e98 <page_alloc>
f010141f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101422:	85 c0                	test   %eax,%eax
f0101424:	75 24                	jne    f010144a <mem_init+0x215>
f0101426:	c7 44 24 0c 29 4b 10 	movl   $0xf0104b29,0xc(%esp)
f010142d:	f0 
f010142e:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101435:	f0 
f0101436:	c7 44 24 04 72 02 00 	movl   $0x272,0x4(%esp)
f010143d:	00 
f010143e:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101445:	e8 4a ec ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010144a:	39 fe                	cmp    %edi,%esi
f010144c:	75 24                	jne    f0101472 <mem_init+0x23d>
f010144e:	c7 44 24 0c 3f 4b 10 	movl   $0xf0104b3f,0xc(%esp)
f0101455:	f0 
f0101456:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f010145d:	f0 
f010145e:	c7 44 24 04 75 02 00 	movl   $0x275,0x4(%esp)
f0101465:	00 
f0101466:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f010146d:	e8 22 ec ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101472:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101475:	74 05                	je     f010147c <mem_init+0x247>
f0101477:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f010147a:	75 24                	jne    f01014a0 <mem_init+0x26b>
f010147c:	c7 44 24 0c ac 44 10 	movl   $0xf01044ac,0xc(%esp)
f0101483:	f0 
f0101484:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f010148b:	f0 
f010148c:	c7 44 24 04 76 02 00 	movl   $0x276,0x4(%esp)
f0101493:	00 
f0101494:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f010149b:	e8 f4 eb ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01014a0:	8b 15 a8 79 11 f0    	mov    0xf01179a8,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f01014a6:	a1 a0 79 11 f0       	mov    0xf01179a0,%eax
f01014ab:	c1 e0 0c             	shl    $0xc,%eax
f01014ae:	89 f1                	mov    %esi,%ecx
f01014b0:	29 d1                	sub    %edx,%ecx
f01014b2:	c1 f9 03             	sar    $0x3,%ecx
f01014b5:	c1 e1 0c             	shl    $0xc,%ecx
f01014b8:	39 c1                	cmp    %eax,%ecx
f01014ba:	72 24                	jb     f01014e0 <mem_init+0x2ab>
f01014bc:	c7 44 24 0c 51 4b 10 	movl   $0xf0104b51,0xc(%esp)
f01014c3:	f0 
f01014c4:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f01014cb:	f0 
f01014cc:	c7 44 24 04 77 02 00 	movl   $0x277,0x4(%esp)
f01014d3:	00 
f01014d4:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01014db:	e8 b4 eb ff ff       	call   f0100094 <_panic>
f01014e0:	89 f9                	mov    %edi,%ecx
f01014e2:	29 d1                	sub    %edx,%ecx
f01014e4:	c1 f9 03             	sar    $0x3,%ecx
f01014e7:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f01014ea:	39 c8                	cmp    %ecx,%eax
f01014ec:	77 24                	ja     f0101512 <mem_init+0x2dd>
f01014ee:	c7 44 24 0c 6e 4b 10 	movl   $0xf0104b6e,0xc(%esp)
f01014f5:	f0 
f01014f6:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f01014fd:	f0 
f01014fe:	c7 44 24 04 78 02 00 	movl   $0x278,0x4(%esp)
f0101505:	00 
f0101506:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f010150d:	e8 82 eb ff ff       	call   f0100094 <_panic>
f0101512:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101515:	29 d1                	sub    %edx,%ecx
f0101517:	89 ca                	mov    %ecx,%edx
f0101519:	c1 fa 03             	sar    $0x3,%edx
f010151c:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f010151f:	39 d0                	cmp    %edx,%eax
f0101521:	77 24                	ja     f0101547 <mem_init+0x312>
f0101523:	c7 44 24 0c 8b 4b 10 	movl   $0xf0104b8b,0xc(%esp)
f010152a:	f0 
f010152b:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101532:	f0 
f0101533:	c7 44 24 04 79 02 00 	movl   $0x279,0x4(%esp)
f010153a:	00 
f010153b:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101542:	e8 4d eb ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101547:	a1 80 75 11 f0       	mov    0xf0117580,%eax
f010154c:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010154f:	c7 05 80 75 11 f0 00 	movl   $0x0,0xf0117580
f0101556:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101559:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101560:	e8 33 f9 ff ff       	call   f0100e98 <page_alloc>
f0101565:	85 c0                	test   %eax,%eax
f0101567:	74 24                	je     f010158d <mem_init+0x358>
f0101569:	c7 44 24 0c a8 4b 10 	movl   $0xf0104ba8,0xc(%esp)
f0101570:	f0 
f0101571:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101578:	f0 
f0101579:	c7 44 24 04 80 02 00 	movl   $0x280,0x4(%esp)
f0101580:	00 
f0101581:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101588:	e8 07 eb ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f010158d:	89 34 24             	mov    %esi,(%esp)
f0101590:	e8 90 f9 ff ff       	call   f0100f25 <page_free>
	page_free(pp1);
f0101595:	89 3c 24             	mov    %edi,(%esp)
f0101598:	e8 88 f9 ff ff       	call   f0100f25 <page_free>
	page_free(pp2);
f010159d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015a0:	89 04 24             	mov    %eax,(%esp)
f01015a3:	e8 7d f9 ff ff       	call   f0100f25 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015a8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015af:	e8 e4 f8 ff ff       	call   f0100e98 <page_alloc>
f01015b4:	89 c6                	mov    %eax,%esi
f01015b6:	85 c0                	test   %eax,%eax
f01015b8:	75 24                	jne    f01015de <mem_init+0x3a9>
f01015ba:	c7 44 24 0c fd 4a 10 	movl   $0xf0104afd,0xc(%esp)
f01015c1:	f0 
f01015c2:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f01015c9:	f0 
f01015ca:	c7 44 24 04 87 02 00 	movl   $0x287,0x4(%esp)
f01015d1:	00 
f01015d2:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01015d9:	e8 b6 ea ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01015de:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015e5:	e8 ae f8 ff ff       	call   f0100e98 <page_alloc>
f01015ea:	89 c7                	mov    %eax,%edi
f01015ec:	85 c0                	test   %eax,%eax
f01015ee:	75 24                	jne    f0101614 <mem_init+0x3df>
f01015f0:	c7 44 24 0c 13 4b 10 	movl   $0xf0104b13,0xc(%esp)
f01015f7:	f0 
f01015f8:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f01015ff:	f0 
f0101600:	c7 44 24 04 88 02 00 	movl   $0x288,0x4(%esp)
f0101607:	00 
f0101608:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f010160f:	e8 80 ea ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101614:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010161b:	e8 78 f8 ff ff       	call   f0100e98 <page_alloc>
f0101620:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101623:	85 c0                	test   %eax,%eax
f0101625:	75 24                	jne    f010164b <mem_init+0x416>
f0101627:	c7 44 24 0c 29 4b 10 	movl   $0xf0104b29,0xc(%esp)
f010162e:	f0 
f010162f:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101636:	f0 
f0101637:	c7 44 24 04 89 02 00 	movl   $0x289,0x4(%esp)
f010163e:	00 
f010163f:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101646:	e8 49 ea ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010164b:	39 fe                	cmp    %edi,%esi
f010164d:	75 24                	jne    f0101673 <mem_init+0x43e>
f010164f:	c7 44 24 0c 3f 4b 10 	movl   $0xf0104b3f,0xc(%esp)
f0101656:	f0 
f0101657:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f010165e:	f0 
f010165f:	c7 44 24 04 8b 02 00 	movl   $0x28b,0x4(%esp)
f0101666:	00 
f0101667:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f010166e:	e8 21 ea ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101673:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101676:	74 05                	je     f010167d <mem_init+0x448>
f0101678:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f010167b:	75 24                	jne    f01016a1 <mem_init+0x46c>
f010167d:	c7 44 24 0c ac 44 10 	movl   $0xf01044ac,0xc(%esp)
f0101684:	f0 
f0101685:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f010168c:	f0 
f010168d:	c7 44 24 04 8c 02 00 	movl   $0x28c,0x4(%esp)
f0101694:	00 
f0101695:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f010169c:	e8 f3 e9 ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f01016a1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016a8:	e8 eb f7 ff ff       	call   f0100e98 <page_alloc>
f01016ad:	85 c0                	test   %eax,%eax
f01016af:	74 24                	je     f01016d5 <mem_init+0x4a0>
f01016b1:	c7 44 24 0c a8 4b 10 	movl   $0xf0104ba8,0xc(%esp)
f01016b8:	f0 
f01016b9:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f01016c0:	f0 
f01016c1:	c7 44 24 04 8d 02 00 	movl   $0x28d,0x4(%esp)
f01016c8:	00 
f01016c9:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01016d0:	e8 bf e9 ff ff       	call   f0100094 <_panic>
f01016d5:	89 f0                	mov    %esi,%eax
f01016d7:	2b 05 a8 79 11 f0    	sub    0xf01179a8,%eax
f01016dd:	c1 f8 03             	sar    $0x3,%eax
f01016e0:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01016e3:	89 c2                	mov    %eax,%edx
f01016e5:	c1 ea 0c             	shr    $0xc,%edx
f01016e8:	3b 15 a0 79 11 f0    	cmp    0xf01179a0,%edx
f01016ee:	72 20                	jb     f0101710 <mem_init+0x4db>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01016f0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01016f4:	c7 44 24 08 44 43 10 	movl   $0xf0104344,0x8(%esp)
f01016fb:	f0 
f01016fc:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101703:	00 
f0101704:	c7 04 24 38 4a 10 f0 	movl   $0xf0104a38,(%esp)
f010170b:	e8 84 e9 ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101710:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101717:	00 
f0101718:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f010171f:	00 
	return (void *)(pa + KERNBASE);
f0101720:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101725:	89 04 24             	mov    %eax,(%esp)
f0101728:	e8 09 22 00 00       	call   f0103936 <memset>
	page_free(pp0);
f010172d:	89 34 24             	mov    %esi,(%esp)
f0101730:	e8 f0 f7 ff ff       	call   f0100f25 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101735:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010173c:	e8 57 f7 ff ff       	call   f0100e98 <page_alloc>
f0101741:	85 c0                	test   %eax,%eax
f0101743:	75 24                	jne    f0101769 <mem_init+0x534>
f0101745:	c7 44 24 0c b7 4b 10 	movl   $0xf0104bb7,0xc(%esp)
f010174c:	f0 
f010174d:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101754:	f0 
f0101755:	c7 44 24 04 92 02 00 	movl   $0x292,0x4(%esp)
f010175c:	00 
f010175d:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101764:	e8 2b e9 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f0101769:	39 c6                	cmp    %eax,%esi
f010176b:	74 24                	je     f0101791 <mem_init+0x55c>
f010176d:	c7 44 24 0c d5 4b 10 	movl   $0xf0104bd5,0xc(%esp)
f0101774:	f0 
f0101775:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f010177c:	f0 
f010177d:	c7 44 24 04 93 02 00 	movl   $0x293,0x4(%esp)
f0101784:	00 
f0101785:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f010178c:	e8 03 e9 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101791:	89 f2                	mov    %esi,%edx
f0101793:	2b 15 a8 79 11 f0    	sub    0xf01179a8,%edx
f0101799:	c1 fa 03             	sar    $0x3,%edx
f010179c:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010179f:	89 d0                	mov    %edx,%eax
f01017a1:	c1 e8 0c             	shr    $0xc,%eax
f01017a4:	3b 05 a0 79 11 f0    	cmp    0xf01179a0,%eax
f01017aa:	72 20                	jb     f01017cc <mem_init+0x597>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01017ac:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01017b0:	c7 44 24 08 44 43 10 	movl   $0xf0104344,0x8(%esp)
f01017b7:	f0 
f01017b8:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01017bf:	00 
f01017c0:	c7 04 24 38 4a 10 f0 	movl   $0xf0104a38,(%esp)
f01017c7:	e8 c8 e8 ff ff       	call   f0100094 <_panic>
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01017cc:	80 ba 00 00 00 f0 00 	cmpb   $0x0,-0x10000000(%edx)
f01017d3:	75 11                	jne    f01017e6 <mem_init+0x5b1>
f01017d5:	8d 82 01 00 00 f0    	lea    -0xfffffff(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01017db:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01017e1:	80 38 00             	cmpb   $0x0,(%eax)
f01017e4:	74 24                	je     f010180a <mem_init+0x5d5>
f01017e6:	c7 44 24 0c e5 4b 10 	movl   $0xf0104be5,0xc(%esp)
f01017ed:	f0 
f01017ee:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f01017f5:	f0 
f01017f6:	c7 44 24 04 96 02 00 	movl   $0x296,0x4(%esp)
f01017fd:	00 
f01017fe:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101805:	e8 8a e8 ff ff       	call   f0100094 <_panic>
f010180a:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010180d:	39 d0                	cmp    %edx,%eax
f010180f:	75 d0                	jne    f01017e1 <mem_init+0x5ac>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101811:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101814:	89 15 80 75 11 f0    	mov    %edx,0xf0117580

	// free the pages we took
	page_free(pp0);
f010181a:	89 34 24             	mov    %esi,(%esp)
f010181d:	e8 03 f7 ff ff       	call   f0100f25 <page_free>
	page_free(pp1);
f0101822:	89 3c 24             	mov    %edi,(%esp)
f0101825:	e8 fb f6 ff ff       	call   f0100f25 <page_free>
	page_free(pp2);
f010182a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010182d:	89 04 24             	mov    %eax,(%esp)
f0101830:	e8 f0 f6 ff ff       	call   f0100f25 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101835:	a1 80 75 11 f0       	mov    0xf0117580,%eax
f010183a:	85 c0                	test   %eax,%eax
f010183c:	74 09                	je     f0101847 <mem_init+0x612>
		--nfree;
f010183e:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101841:	8b 00                	mov    (%eax),%eax
f0101843:	85 c0                	test   %eax,%eax
f0101845:	75 f7                	jne    f010183e <mem_init+0x609>
		--nfree;
	assert(nfree == 0);
f0101847:	85 db                	test   %ebx,%ebx
f0101849:	74 24                	je     f010186f <mem_init+0x63a>
f010184b:	c7 44 24 0c ef 4b 10 	movl   $0xf0104bef,0xc(%esp)
f0101852:	f0 
f0101853:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f010185a:	f0 
f010185b:	c7 44 24 04 a3 02 00 	movl   $0x2a3,0x4(%esp)
f0101862:	00 
f0101863:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f010186a:	e8 25 e8 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010186f:	c7 04 24 cc 44 10 f0 	movl   $0xf01044cc,(%esp)
f0101876:	e8 bb 14 00 00       	call   f0102d36 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010187b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101882:	e8 11 f6 ff ff       	call   f0100e98 <page_alloc>
f0101887:	89 c3                	mov    %eax,%ebx
f0101889:	85 c0                	test   %eax,%eax
f010188b:	75 24                	jne    f01018b1 <mem_init+0x67c>
f010188d:	c7 44 24 0c fd 4a 10 	movl   $0xf0104afd,0xc(%esp)
f0101894:	f0 
f0101895:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f010189c:	f0 
f010189d:	c7 44 24 04 fc 02 00 	movl   $0x2fc,0x4(%esp)
f01018a4:	00 
f01018a5:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01018ac:	e8 e3 e7 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01018b1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018b8:	e8 db f5 ff ff       	call   f0100e98 <page_alloc>
f01018bd:	89 c7                	mov    %eax,%edi
f01018bf:	85 c0                	test   %eax,%eax
f01018c1:	75 24                	jne    f01018e7 <mem_init+0x6b2>
f01018c3:	c7 44 24 0c 13 4b 10 	movl   $0xf0104b13,0xc(%esp)
f01018ca:	f0 
f01018cb:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f01018d2:	f0 
f01018d3:	c7 44 24 04 fd 02 00 	movl   $0x2fd,0x4(%esp)
f01018da:	00 
f01018db:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01018e2:	e8 ad e7 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01018e7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018ee:	e8 a5 f5 ff ff       	call   f0100e98 <page_alloc>
f01018f3:	89 c6                	mov    %eax,%esi
f01018f5:	85 c0                	test   %eax,%eax
f01018f7:	75 24                	jne    f010191d <mem_init+0x6e8>
f01018f9:	c7 44 24 0c 29 4b 10 	movl   $0xf0104b29,0xc(%esp)
f0101900:	f0 
f0101901:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101908:	f0 
f0101909:	c7 44 24 04 fe 02 00 	movl   $0x2fe,0x4(%esp)
f0101910:	00 
f0101911:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101918:	e8 77 e7 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010191d:	39 fb                	cmp    %edi,%ebx
f010191f:	75 24                	jne    f0101945 <mem_init+0x710>
f0101921:	c7 44 24 0c 3f 4b 10 	movl   $0xf0104b3f,0xc(%esp)
f0101928:	f0 
f0101929:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101930:	f0 
f0101931:	c7 44 24 04 01 03 00 	movl   $0x301,0x4(%esp)
f0101938:	00 
f0101939:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101940:	e8 4f e7 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101945:	39 c7                	cmp    %eax,%edi
f0101947:	74 04                	je     f010194d <mem_init+0x718>
f0101949:	39 c3                	cmp    %eax,%ebx
f010194b:	75 24                	jne    f0101971 <mem_init+0x73c>
f010194d:	c7 44 24 0c ac 44 10 	movl   $0xf01044ac,0xc(%esp)
f0101954:	f0 
f0101955:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f010195c:	f0 
f010195d:	c7 44 24 04 02 03 00 	movl   $0x302,0x4(%esp)
f0101964:	00 
f0101965:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f010196c:	e8 23 e7 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101971:	8b 15 80 75 11 f0    	mov    0xf0117580,%edx
f0101977:	89 55 cc             	mov    %edx,-0x34(%ebp)
	page_free_list = 0;
f010197a:	c7 05 80 75 11 f0 00 	movl   $0x0,0xf0117580
f0101981:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101984:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010198b:	e8 08 f5 ff ff       	call   f0100e98 <page_alloc>
f0101990:	85 c0                	test   %eax,%eax
f0101992:	74 24                	je     f01019b8 <mem_init+0x783>
f0101994:	c7 44 24 0c a8 4b 10 	movl   $0xf0104ba8,0xc(%esp)
f010199b:	f0 
f010199c:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f01019a3:	f0 
f01019a4:	c7 44 24 04 09 03 00 	movl   $0x309,0x4(%esp)
f01019ab:	00 
f01019ac:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01019b3:	e8 dc e6 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01019b8:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01019bb:	89 44 24 08          	mov    %eax,0x8(%esp)
f01019bf:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01019c6:	00 
f01019c7:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f01019cc:	89 04 24             	mov    %eax,(%esp)
f01019cf:	e8 e0 f6 ff ff       	call   f01010b4 <page_lookup>
f01019d4:	85 c0                	test   %eax,%eax
f01019d6:	74 24                	je     f01019fc <mem_init+0x7c7>
f01019d8:	c7 44 24 0c ec 44 10 	movl   $0xf01044ec,0xc(%esp)
f01019df:	f0 
f01019e0:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f01019e7:	f0 
f01019e8:	c7 44 24 04 0c 03 00 	movl   $0x30c,0x4(%esp)
f01019ef:	00 
f01019f0:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01019f7:	e8 98 e6 ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01019fc:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101a03:	00 
f0101a04:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101a0b:	00 
f0101a0c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101a10:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0101a15:	89 04 24             	mov    %eax,(%esp)
f0101a18:	e8 6e f7 ff ff       	call   f010118b <page_insert>
f0101a1d:	85 c0                	test   %eax,%eax
f0101a1f:	78 24                	js     f0101a45 <mem_init+0x810>
f0101a21:	c7 44 24 0c 24 45 10 	movl   $0xf0104524,0xc(%esp)
f0101a28:	f0 
f0101a29:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101a30:	f0 
f0101a31:	c7 44 24 04 0f 03 00 	movl   $0x30f,0x4(%esp)
f0101a38:	00 
f0101a39:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101a40:	e8 4f e6 ff ff       	call   f0100094 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101a45:	89 1c 24             	mov    %ebx,(%esp)
f0101a48:	e8 d8 f4 ff ff       	call   f0100f25 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101a4d:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101a54:	00 
f0101a55:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101a5c:	00 
f0101a5d:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101a61:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0101a66:	89 04 24             	mov    %eax,(%esp)
f0101a69:	e8 1d f7 ff ff       	call   f010118b <page_insert>
f0101a6e:	85 c0                	test   %eax,%eax
f0101a70:	74 24                	je     f0101a96 <mem_init+0x861>
f0101a72:	c7 44 24 0c 54 45 10 	movl   $0xf0104554,0xc(%esp)
f0101a79:	f0 
f0101a7a:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101a81:	f0 
f0101a82:	c7 44 24 04 13 03 00 	movl   $0x313,0x4(%esp)
f0101a89:	00 
f0101a8a:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101a91:	e8 fe e5 ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101a96:	8b 0d a4 79 11 f0    	mov    0xf01179a4,%ecx
f0101a9c:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101a9f:	a1 a8 79 11 f0       	mov    0xf01179a8,%eax
f0101aa4:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101aa7:	8b 11                	mov    (%ecx),%edx
f0101aa9:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101aaf:	89 d8                	mov    %ebx,%eax
f0101ab1:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0101ab4:	c1 f8 03             	sar    $0x3,%eax
f0101ab7:	c1 e0 0c             	shl    $0xc,%eax
f0101aba:	39 c2                	cmp    %eax,%edx
f0101abc:	74 24                	je     f0101ae2 <mem_init+0x8ad>
f0101abe:	c7 44 24 0c 84 45 10 	movl   $0xf0104584,0xc(%esp)
f0101ac5:	f0 
f0101ac6:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101acd:	f0 
f0101ace:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
f0101ad5:	00 
f0101ad6:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101add:	e8 b2 e5 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101ae2:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ae7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101aea:	e8 cf ee ff ff       	call   f01009be <check_va2pa>
f0101aef:	89 fa                	mov    %edi,%edx
f0101af1:	2b 55 d0             	sub    -0x30(%ebp),%edx
f0101af4:	c1 fa 03             	sar    $0x3,%edx
f0101af7:	c1 e2 0c             	shl    $0xc,%edx
f0101afa:	39 d0                	cmp    %edx,%eax
f0101afc:	74 24                	je     f0101b22 <mem_init+0x8ed>
f0101afe:	c7 44 24 0c ac 45 10 	movl   $0xf01045ac,0xc(%esp)
f0101b05:	f0 
f0101b06:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101b0d:	f0 
f0101b0e:	c7 44 24 04 15 03 00 	movl   $0x315,0x4(%esp)
f0101b15:	00 
f0101b16:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101b1d:	e8 72 e5 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0101b22:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101b27:	74 24                	je     f0101b4d <mem_init+0x918>
f0101b29:	c7 44 24 0c fa 4b 10 	movl   $0xf0104bfa,0xc(%esp)
f0101b30:	f0 
f0101b31:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101b38:	f0 
f0101b39:	c7 44 24 04 16 03 00 	movl   $0x316,0x4(%esp)
f0101b40:	00 
f0101b41:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101b48:	e8 47 e5 ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0101b4d:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101b52:	74 24                	je     f0101b78 <mem_init+0x943>
f0101b54:	c7 44 24 0c 0b 4c 10 	movl   $0xf0104c0b,0xc(%esp)
f0101b5b:	f0 
f0101b5c:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101b63:	f0 
f0101b64:	c7 44 24 04 17 03 00 	movl   $0x317,0x4(%esp)
f0101b6b:	00 
f0101b6c:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101b73:	e8 1c e5 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b78:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101b7f:	00 
f0101b80:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101b87:	00 
f0101b88:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101b8c:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101b8f:	89 14 24             	mov    %edx,(%esp)
f0101b92:	e8 f4 f5 ff ff       	call   f010118b <page_insert>
f0101b97:	85 c0                	test   %eax,%eax
f0101b99:	74 24                	je     f0101bbf <mem_init+0x98a>
f0101b9b:	c7 44 24 0c dc 45 10 	movl   $0xf01045dc,0xc(%esp)
f0101ba2:	f0 
f0101ba3:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101baa:	f0 
f0101bab:	c7 44 24 04 1a 03 00 	movl   $0x31a,0x4(%esp)
f0101bb2:	00 
f0101bb3:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101bba:	e8 d5 e4 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bbf:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bc4:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0101bc9:	e8 f0 ed ff ff       	call   f01009be <check_va2pa>
f0101bce:	89 f2                	mov    %esi,%edx
f0101bd0:	2b 15 a8 79 11 f0    	sub    0xf01179a8,%edx
f0101bd6:	c1 fa 03             	sar    $0x3,%edx
f0101bd9:	c1 e2 0c             	shl    $0xc,%edx
f0101bdc:	39 d0                	cmp    %edx,%eax
f0101bde:	74 24                	je     f0101c04 <mem_init+0x9cf>
f0101be0:	c7 44 24 0c 18 46 10 	movl   $0xf0104618,0xc(%esp)
f0101be7:	f0 
f0101be8:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101bef:	f0 
f0101bf0:	c7 44 24 04 1b 03 00 	movl   $0x31b,0x4(%esp)
f0101bf7:	00 
f0101bf8:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101bff:	e8 90 e4 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101c04:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c09:	74 24                	je     f0101c2f <mem_init+0x9fa>
f0101c0b:	c7 44 24 0c 1c 4c 10 	movl   $0xf0104c1c,0xc(%esp)
f0101c12:	f0 
f0101c13:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101c1a:	f0 
f0101c1b:	c7 44 24 04 1c 03 00 	movl   $0x31c,0x4(%esp)
f0101c22:	00 
f0101c23:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101c2a:	e8 65 e4 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101c2f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c36:	e8 5d f2 ff ff       	call   f0100e98 <page_alloc>
f0101c3b:	85 c0                	test   %eax,%eax
f0101c3d:	74 24                	je     f0101c63 <mem_init+0xa2e>
f0101c3f:	c7 44 24 0c a8 4b 10 	movl   $0xf0104ba8,0xc(%esp)
f0101c46:	f0 
f0101c47:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101c4e:	f0 
f0101c4f:	c7 44 24 04 1f 03 00 	movl   $0x31f,0x4(%esp)
f0101c56:	00 
f0101c57:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101c5e:	e8 31 e4 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c63:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101c6a:	00 
f0101c6b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101c72:	00 
f0101c73:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101c77:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0101c7c:	89 04 24             	mov    %eax,(%esp)
f0101c7f:	e8 07 f5 ff ff       	call   f010118b <page_insert>
f0101c84:	85 c0                	test   %eax,%eax
f0101c86:	74 24                	je     f0101cac <mem_init+0xa77>
f0101c88:	c7 44 24 0c dc 45 10 	movl   $0xf01045dc,0xc(%esp)
f0101c8f:	f0 
f0101c90:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101c97:	f0 
f0101c98:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f0101c9f:	00 
f0101ca0:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101ca7:	e8 e8 e3 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101cac:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cb1:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0101cb6:	e8 03 ed ff ff       	call   f01009be <check_va2pa>
f0101cbb:	89 f2                	mov    %esi,%edx
f0101cbd:	2b 15 a8 79 11 f0    	sub    0xf01179a8,%edx
f0101cc3:	c1 fa 03             	sar    $0x3,%edx
f0101cc6:	c1 e2 0c             	shl    $0xc,%edx
f0101cc9:	39 d0                	cmp    %edx,%eax
f0101ccb:	74 24                	je     f0101cf1 <mem_init+0xabc>
f0101ccd:	c7 44 24 0c 18 46 10 	movl   $0xf0104618,0xc(%esp)
f0101cd4:	f0 
f0101cd5:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101cdc:	f0 
f0101cdd:	c7 44 24 04 23 03 00 	movl   $0x323,0x4(%esp)
f0101ce4:	00 
f0101ce5:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101cec:	e8 a3 e3 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101cf1:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101cf6:	74 24                	je     f0101d1c <mem_init+0xae7>
f0101cf8:	c7 44 24 0c 1c 4c 10 	movl   $0xf0104c1c,0xc(%esp)
f0101cff:	f0 
f0101d00:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101d07:	f0 
f0101d08:	c7 44 24 04 24 03 00 	movl   $0x324,0x4(%esp)
f0101d0f:	00 
f0101d10:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101d17:	e8 78 e3 ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101d1c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101d23:	e8 70 f1 ff ff       	call   f0100e98 <page_alloc>
f0101d28:	85 c0                	test   %eax,%eax
f0101d2a:	74 24                	je     f0101d50 <mem_init+0xb1b>
f0101d2c:	c7 44 24 0c a8 4b 10 	movl   $0xf0104ba8,0xc(%esp)
f0101d33:	f0 
f0101d34:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101d3b:	f0 
f0101d3c:	c7 44 24 04 28 03 00 	movl   $0x328,0x4(%esp)
f0101d43:	00 
f0101d44:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101d4b:	e8 44 e3 ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101d50:	8b 15 a4 79 11 f0    	mov    0xf01179a4,%edx
f0101d56:	8b 02                	mov    (%edx),%eax
f0101d58:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101d5d:	89 c1                	mov    %eax,%ecx
f0101d5f:	c1 e9 0c             	shr    $0xc,%ecx
f0101d62:	3b 0d a0 79 11 f0    	cmp    0xf01179a0,%ecx
f0101d68:	72 20                	jb     f0101d8a <mem_init+0xb55>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101d6a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101d6e:	c7 44 24 08 44 43 10 	movl   $0xf0104344,0x8(%esp)
f0101d75:	f0 
f0101d76:	c7 44 24 04 2b 03 00 	movl   $0x32b,0x4(%esp)
f0101d7d:	00 
f0101d7e:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101d85:	e8 0a e3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101d8a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101d8f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101d92:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101d99:	00 
f0101d9a:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101da1:	00 
f0101da2:	89 14 24             	mov    %edx,(%esp)
f0101da5:	e8 b3 f1 ff ff       	call   f0100f5d <pgdir_walk>
f0101daa:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101dad:	83 c2 04             	add    $0x4,%edx
f0101db0:	39 d0                	cmp    %edx,%eax
f0101db2:	74 24                	je     f0101dd8 <mem_init+0xba3>
f0101db4:	c7 44 24 0c 48 46 10 	movl   $0xf0104648,0xc(%esp)
f0101dbb:	f0 
f0101dbc:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101dc3:	f0 
f0101dc4:	c7 44 24 04 2c 03 00 	movl   $0x32c,0x4(%esp)
f0101dcb:	00 
f0101dcc:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101dd3:	e8 bc e2 ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101dd8:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101ddf:	00 
f0101de0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101de7:	00 
f0101de8:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101dec:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0101df1:	89 04 24             	mov    %eax,(%esp)
f0101df4:	e8 92 f3 ff ff       	call   f010118b <page_insert>
f0101df9:	85 c0                	test   %eax,%eax
f0101dfb:	74 24                	je     f0101e21 <mem_init+0xbec>
f0101dfd:	c7 44 24 0c 88 46 10 	movl   $0xf0104688,0xc(%esp)
f0101e04:	f0 
f0101e05:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101e0c:	f0 
f0101e0d:	c7 44 24 04 2f 03 00 	movl   $0x32f,0x4(%esp)
f0101e14:	00 
f0101e15:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101e1c:	e8 73 e2 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101e21:	8b 0d a4 79 11 f0    	mov    0xf01179a4,%ecx
f0101e27:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0101e2a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e2f:	89 c8                	mov    %ecx,%eax
f0101e31:	e8 88 eb ff ff       	call   f01009be <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101e36:	89 f2                	mov    %esi,%edx
f0101e38:	2b 15 a8 79 11 f0    	sub    0xf01179a8,%edx
f0101e3e:	c1 fa 03             	sar    $0x3,%edx
f0101e41:	c1 e2 0c             	shl    $0xc,%edx
f0101e44:	39 d0                	cmp    %edx,%eax
f0101e46:	74 24                	je     f0101e6c <mem_init+0xc37>
f0101e48:	c7 44 24 0c 18 46 10 	movl   $0xf0104618,0xc(%esp)
f0101e4f:	f0 
f0101e50:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101e57:	f0 
f0101e58:	c7 44 24 04 30 03 00 	movl   $0x330,0x4(%esp)
f0101e5f:	00 
f0101e60:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101e67:	e8 28 e2 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101e6c:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101e71:	74 24                	je     f0101e97 <mem_init+0xc62>
f0101e73:	c7 44 24 0c 1c 4c 10 	movl   $0xf0104c1c,0xc(%esp)
f0101e7a:	f0 
f0101e7b:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101e82:	f0 
f0101e83:	c7 44 24 04 31 03 00 	movl   $0x331,0x4(%esp)
f0101e8a:	00 
f0101e8b:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101e92:	e8 fd e1 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101e97:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101e9e:	00 
f0101e9f:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101ea6:	00 
f0101ea7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101eaa:	89 04 24             	mov    %eax,(%esp)
f0101ead:	e8 ab f0 ff ff       	call   f0100f5d <pgdir_walk>
f0101eb2:	f6 00 04             	testb  $0x4,(%eax)
f0101eb5:	75 24                	jne    f0101edb <mem_init+0xca6>
f0101eb7:	c7 44 24 0c c8 46 10 	movl   $0xf01046c8,0xc(%esp)
f0101ebe:	f0 
f0101ebf:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101ec6:	f0 
f0101ec7:	c7 44 24 04 32 03 00 	movl   $0x332,0x4(%esp)
f0101ece:	00 
f0101ecf:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101ed6:	e8 b9 e1 ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101edb:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0101ee0:	f6 00 04             	testb  $0x4,(%eax)
f0101ee3:	75 24                	jne    f0101f09 <mem_init+0xcd4>
f0101ee5:	c7 44 24 0c 2d 4c 10 	movl   $0xf0104c2d,0xc(%esp)
f0101eec:	f0 
f0101eed:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101ef4:	f0 
f0101ef5:	c7 44 24 04 33 03 00 	movl   $0x333,0x4(%esp)
f0101efc:	00 
f0101efd:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101f04:	e8 8b e1 ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101f09:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f10:	00 
f0101f11:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0101f18:	00 
f0101f19:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101f1d:	89 04 24             	mov    %eax,(%esp)
f0101f20:	e8 66 f2 ff ff       	call   f010118b <page_insert>
f0101f25:	85 c0                	test   %eax,%eax
f0101f27:	78 24                	js     f0101f4d <mem_init+0xd18>
f0101f29:	c7 44 24 0c fc 46 10 	movl   $0xf01046fc,0xc(%esp)
f0101f30:	f0 
f0101f31:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101f38:	f0 
f0101f39:	c7 44 24 04 36 03 00 	movl   $0x336,0x4(%esp)
f0101f40:	00 
f0101f41:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101f48:	e8 47 e1 ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101f4d:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f54:	00 
f0101f55:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101f5c:	00 
f0101f5d:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101f61:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0101f66:	89 04 24             	mov    %eax,(%esp)
f0101f69:	e8 1d f2 ff ff       	call   f010118b <page_insert>
f0101f6e:	85 c0                	test   %eax,%eax
f0101f70:	74 24                	je     f0101f96 <mem_init+0xd61>
f0101f72:	c7 44 24 0c 34 47 10 	movl   $0xf0104734,0xc(%esp)
f0101f79:	f0 
f0101f7a:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101f81:	f0 
f0101f82:	c7 44 24 04 39 03 00 	movl   $0x339,0x4(%esp)
f0101f89:	00 
f0101f8a:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101f91:	e8 fe e0 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101f96:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f9d:	00 
f0101f9e:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101fa5:	00 
f0101fa6:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0101fab:	89 04 24             	mov    %eax,(%esp)
f0101fae:	e8 aa ef ff ff       	call   f0100f5d <pgdir_walk>
f0101fb3:	f6 00 04             	testb  $0x4,(%eax)
f0101fb6:	74 24                	je     f0101fdc <mem_init+0xda7>
f0101fb8:	c7 44 24 0c 70 47 10 	movl   $0xf0104770,0xc(%esp)
f0101fbf:	f0 
f0101fc0:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101fc7:	f0 
f0101fc8:	c7 44 24 04 3a 03 00 	movl   $0x33a,0x4(%esp)
f0101fcf:	00 
f0101fd0:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101fd7:	e8 b8 e0 ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101fdc:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0101fe1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101fe4:	ba 00 00 00 00       	mov    $0x0,%edx
f0101fe9:	e8 d0 e9 ff ff       	call   f01009be <check_va2pa>
f0101fee:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101ff1:	89 f8                	mov    %edi,%eax
f0101ff3:	2b 05 a8 79 11 f0    	sub    0xf01179a8,%eax
f0101ff9:	c1 f8 03             	sar    $0x3,%eax
f0101ffc:	c1 e0 0c             	shl    $0xc,%eax
f0101fff:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102002:	74 24                	je     f0102028 <mem_init+0xdf3>
f0102004:	c7 44 24 0c a8 47 10 	movl   $0xf01047a8,0xc(%esp)
f010200b:	f0 
f010200c:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102013:	f0 
f0102014:	c7 44 24 04 3d 03 00 	movl   $0x33d,0x4(%esp)
f010201b:	00 
f010201c:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102023:	e8 6c e0 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102028:	ba 00 10 00 00       	mov    $0x1000,%edx
f010202d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102030:	e8 89 e9 ff ff       	call   f01009be <check_va2pa>
f0102035:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102038:	74 24                	je     f010205e <mem_init+0xe29>
f010203a:	c7 44 24 0c d4 47 10 	movl   $0xf01047d4,0xc(%esp)
f0102041:	f0 
f0102042:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102049:	f0 
f010204a:	c7 44 24 04 3e 03 00 	movl   $0x33e,0x4(%esp)
f0102051:	00 
f0102052:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102059:	e8 36 e0 ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f010205e:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f0102063:	74 24                	je     f0102089 <mem_init+0xe54>
f0102065:	c7 44 24 0c 43 4c 10 	movl   $0xf0104c43,0xc(%esp)
f010206c:	f0 
f010206d:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102074:	f0 
f0102075:	c7 44 24 04 40 03 00 	movl   $0x340,0x4(%esp)
f010207c:	00 
f010207d:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102084:	e8 0b e0 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102089:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010208e:	74 24                	je     f01020b4 <mem_init+0xe7f>
f0102090:	c7 44 24 0c 54 4c 10 	movl   $0xf0104c54,0xc(%esp)
f0102097:	f0 
f0102098:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f010209f:	f0 
f01020a0:	c7 44 24 04 41 03 00 	movl   $0x341,0x4(%esp)
f01020a7:	00 
f01020a8:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01020af:	e8 e0 df ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f01020b4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01020bb:	e8 d8 ed ff ff       	call   f0100e98 <page_alloc>
f01020c0:	85 c0                	test   %eax,%eax
f01020c2:	74 04                	je     f01020c8 <mem_init+0xe93>
f01020c4:	39 c6                	cmp    %eax,%esi
f01020c6:	74 24                	je     f01020ec <mem_init+0xeb7>
f01020c8:	c7 44 24 0c 04 48 10 	movl   $0xf0104804,0xc(%esp)
f01020cf:	f0 
f01020d0:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f01020d7:	f0 
f01020d8:	c7 44 24 04 44 03 00 	movl   $0x344,0x4(%esp)
f01020df:	00 
f01020e0:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01020e7:	e8 a8 df ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f01020ec:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01020f3:	00 
f01020f4:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f01020f9:	89 04 24             	mov    %eax,(%esp)
f01020fc:	e8 36 f0 ff ff       	call   f0101137 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102101:	8b 15 a4 79 11 f0    	mov    0xf01179a4,%edx
f0102107:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f010210a:	ba 00 00 00 00       	mov    $0x0,%edx
f010210f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102112:	e8 a7 e8 ff ff       	call   f01009be <check_va2pa>
f0102117:	83 f8 ff             	cmp    $0xffffffff,%eax
f010211a:	74 24                	je     f0102140 <mem_init+0xf0b>
f010211c:	c7 44 24 0c 28 48 10 	movl   $0xf0104828,0xc(%esp)
f0102123:	f0 
f0102124:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f010212b:	f0 
f010212c:	c7 44 24 04 48 03 00 	movl   $0x348,0x4(%esp)
f0102133:	00 
f0102134:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f010213b:	e8 54 df ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102140:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102145:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102148:	e8 71 e8 ff ff       	call   f01009be <check_va2pa>
f010214d:	89 fa                	mov    %edi,%edx
f010214f:	2b 15 a8 79 11 f0    	sub    0xf01179a8,%edx
f0102155:	c1 fa 03             	sar    $0x3,%edx
f0102158:	c1 e2 0c             	shl    $0xc,%edx
f010215b:	39 d0                	cmp    %edx,%eax
f010215d:	74 24                	je     f0102183 <mem_init+0xf4e>
f010215f:	c7 44 24 0c d4 47 10 	movl   $0xf01047d4,0xc(%esp)
f0102166:	f0 
f0102167:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f010216e:	f0 
f010216f:	c7 44 24 04 49 03 00 	movl   $0x349,0x4(%esp)
f0102176:	00 
f0102177:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f010217e:	e8 11 df ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0102183:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102188:	74 24                	je     f01021ae <mem_init+0xf79>
f010218a:	c7 44 24 0c fa 4b 10 	movl   $0xf0104bfa,0xc(%esp)
f0102191:	f0 
f0102192:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102199:	f0 
f010219a:	c7 44 24 04 4a 03 00 	movl   $0x34a,0x4(%esp)
f01021a1:	00 
f01021a2:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01021a9:	e8 e6 de ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01021ae:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01021b3:	74 24                	je     f01021d9 <mem_init+0xfa4>
f01021b5:	c7 44 24 0c 54 4c 10 	movl   $0xf0104c54,0xc(%esp)
f01021bc:	f0 
f01021bd:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f01021c4:	f0 
f01021c5:	c7 44 24 04 4b 03 00 	movl   $0x34b,0x4(%esp)
f01021cc:	00 
f01021cd:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01021d4:	e8 bb de ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01021d9:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01021e0:	00 
f01021e1:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01021e4:	89 0c 24             	mov    %ecx,(%esp)
f01021e7:	e8 4b ef ff ff       	call   f0101137 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01021ec:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f01021f1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01021f4:	ba 00 00 00 00       	mov    $0x0,%edx
f01021f9:	e8 c0 e7 ff ff       	call   f01009be <check_va2pa>
f01021fe:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102201:	74 24                	je     f0102227 <mem_init+0xff2>
f0102203:	c7 44 24 0c 28 48 10 	movl   $0xf0104828,0xc(%esp)
f010220a:	f0 
f010220b:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102212:	f0 
f0102213:	c7 44 24 04 4f 03 00 	movl   $0x34f,0x4(%esp)
f010221a:	00 
f010221b:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102222:	e8 6d de ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102227:	ba 00 10 00 00       	mov    $0x1000,%edx
f010222c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010222f:	e8 8a e7 ff ff       	call   f01009be <check_va2pa>
f0102234:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102237:	74 24                	je     f010225d <mem_init+0x1028>
f0102239:	c7 44 24 0c 4c 48 10 	movl   $0xf010484c,0xc(%esp)
f0102240:	f0 
f0102241:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102248:	f0 
f0102249:	c7 44 24 04 50 03 00 	movl   $0x350,0x4(%esp)
f0102250:	00 
f0102251:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102258:	e8 37 de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f010225d:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102262:	74 24                	je     f0102288 <mem_init+0x1053>
f0102264:	c7 44 24 0c 65 4c 10 	movl   $0xf0104c65,0xc(%esp)
f010226b:	f0 
f010226c:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102273:	f0 
f0102274:	c7 44 24 04 51 03 00 	movl   $0x351,0x4(%esp)
f010227b:	00 
f010227c:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102283:	e8 0c de ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102288:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010228d:	74 24                	je     f01022b3 <mem_init+0x107e>
f010228f:	c7 44 24 0c 54 4c 10 	movl   $0xf0104c54,0xc(%esp)
f0102296:	f0 
f0102297:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f010229e:	f0 
f010229f:	c7 44 24 04 52 03 00 	movl   $0x352,0x4(%esp)
f01022a6:	00 
f01022a7:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01022ae:	e8 e1 dd ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f01022b3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01022ba:	e8 d9 eb ff ff       	call   f0100e98 <page_alloc>
f01022bf:	85 c0                	test   %eax,%eax
f01022c1:	74 04                	je     f01022c7 <mem_init+0x1092>
f01022c3:	39 c7                	cmp    %eax,%edi
f01022c5:	74 24                	je     f01022eb <mem_init+0x10b6>
f01022c7:	c7 44 24 0c 74 48 10 	movl   $0xf0104874,0xc(%esp)
f01022ce:	f0 
f01022cf:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f01022d6:	f0 
f01022d7:	c7 44 24 04 55 03 00 	movl   $0x355,0x4(%esp)
f01022de:	00 
f01022df:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01022e6:	e8 a9 dd ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01022eb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01022f2:	e8 a1 eb ff ff       	call   f0100e98 <page_alloc>
f01022f7:	85 c0                	test   %eax,%eax
f01022f9:	74 24                	je     f010231f <mem_init+0x10ea>
f01022fb:	c7 44 24 0c a8 4b 10 	movl   $0xf0104ba8,0xc(%esp)
f0102302:	f0 
f0102303:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f010230a:	f0 
f010230b:	c7 44 24 04 58 03 00 	movl   $0x358,0x4(%esp)
f0102312:	00 
f0102313:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f010231a:	e8 75 dd ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010231f:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0102324:	8b 08                	mov    (%eax),%ecx
f0102326:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f010232c:	89 da                	mov    %ebx,%edx
f010232e:	2b 15 a8 79 11 f0    	sub    0xf01179a8,%edx
f0102334:	c1 fa 03             	sar    $0x3,%edx
f0102337:	c1 e2 0c             	shl    $0xc,%edx
f010233a:	39 d1                	cmp    %edx,%ecx
f010233c:	74 24                	je     f0102362 <mem_init+0x112d>
f010233e:	c7 44 24 0c 84 45 10 	movl   $0xf0104584,0xc(%esp)
f0102345:	f0 
f0102346:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f010234d:	f0 
f010234e:	c7 44 24 04 5b 03 00 	movl   $0x35b,0x4(%esp)
f0102355:	00 
f0102356:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f010235d:	e8 32 dd ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102362:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102368:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010236d:	74 24                	je     f0102393 <mem_init+0x115e>
f010236f:	c7 44 24 0c 0b 4c 10 	movl   $0xf0104c0b,0xc(%esp)
f0102376:	f0 
f0102377:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f010237e:	f0 
f010237f:	c7 44 24 04 5d 03 00 	movl   $0x35d,0x4(%esp)
f0102386:	00 
f0102387:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f010238e:	e8 01 dd ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102393:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102399:	89 1c 24             	mov    %ebx,(%esp)
f010239c:	e8 84 eb ff ff       	call   f0100f25 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01023a1:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01023a8:	00 
f01023a9:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f01023b0:	00 
f01023b1:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f01023b6:	89 04 24             	mov    %eax,(%esp)
f01023b9:	e8 9f eb ff ff       	call   f0100f5d <pgdir_walk>
f01023be:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01023c1:	8b 0d a4 79 11 f0    	mov    0xf01179a4,%ecx
f01023c7:	8b 51 04             	mov    0x4(%ecx),%edx
f01023ca:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01023d0:	89 55 d4             	mov    %edx,-0x2c(%ebp)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01023d3:	8b 15 a0 79 11 f0    	mov    0xf01179a0,%edx
f01023d9:	89 55 c8             	mov    %edx,-0x38(%ebp)
f01023dc:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01023df:	c1 ea 0c             	shr    $0xc,%edx
f01023e2:	89 55 d0             	mov    %edx,-0x30(%ebp)
f01023e5:	8b 55 c8             	mov    -0x38(%ebp),%edx
f01023e8:	39 55 d0             	cmp    %edx,-0x30(%ebp)
f01023eb:	72 23                	jb     f0102410 <mem_init+0x11db>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01023ed:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01023f0:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01023f4:	c7 44 24 08 44 43 10 	movl   $0xf0104344,0x8(%esp)
f01023fb:	f0 
f01023fc:	c7 44 24 04 64 03 00 	movl   $0x364,0x4(%esp)
f0102403:	00 
f0102404:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f010240b:	e8 84 dc ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102410:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102413:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0102419:	39 d0                	cmp    %edx,%eax
f010241b:	74 24                	je     f0102441 <mem_init+0x120c>
f010241d:	c7 44 24 0c 76 4c 10 	movl   $0xf0104c76,0xc(%esp)
f0102424:	f0 
f0102425:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f010242c:	f0 
f010242d:	c7 44 24 04 65 03 00 	movl   $0x365,0x4(%esp)
f0102434:	00 
f0102435:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f010243c:	e8 53 dc ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102441:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f0102448:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f010244e:	89 d8                	mov    %ebx,%eax
f0102450:	2b 05 a8 79 11 f0    	sub    0xf01179a8,%eax
f0102456:	c1 f8 03             	sar    $0x3,%eax
f0102459:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010245c:	89 c1                	mov    %eax,%ecx
f010245e:	c1 e9 0c             	shr    $0xc,%ecx
f0102461:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0102464:	77 20                	ja     f0102486 <mem_init+0x1251>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102466:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010246a:	c7 44 24 08 44 43 10 	movl   $0xf0104344,0x8(%esp)
f0102471:	f0 
f0102472:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102479:	00 
f010247a:	c7 04 24 38 4a 10 f0 	movl   $0xf0104a38,(%esp)
f0102481:	e8 0e dc ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102486:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010248d:	00 
f010248e:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f0102495:	00 
	return (void *)(pa + KERNBASE);
f0102496:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010249b:	89 04 24             	mov    %eax,(%esp)
f010249e:	e8 93 14 00 00       	call   f0103936 <memset>
	page_free(pp0);
f01024a3:	89 1c 24             	mov    %ebx,(%esp)
f01024a6:	e8 7a ea ff ff       	call   f0100f25 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01024ab:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01024b2:	00 
f01024b3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01024ba:	00 
f01024bb:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f01024c0:	89 04 24             	mov    %eax,(%esp)
f01024c3:	e8 95 ea ff ff       	call   f0100f5d <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01024c8:	89 da                	mov    %ebx,%edx
f01024ca:	2b 15 a8 79 11 f0    	sub    0xf01179a8,%edx
f01024d0:	c1 fa 03             	sar    $0x3,%edx
f01024d3:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024d6:	89 d0                	mov    %edx,%eax
f01024d8:	c1 e8 0c             	shr    $0xc,%eax
f01024db:	3b 05 a0 79 11 f0    	cmp    0xf01179a0,%eax
f01024e1:	72 20                	jb     f0102503 <mem_init+0x12ce>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024e3:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01024e7:	c7 44 24 08 44 43 10 	movl   $0xf0104344,0x8(%esp)
f01024ee:	f0 
f01024ef:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01024f6:	00 
f01024f7:	c7 04 24 38 4a 10 f0 	movl   $0xf0104a38,(%esp)
f01024fe:	e8 91 db ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0102503:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102509:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010250c:	f6 82 00 00 00 f0 01 	testb  $0x1,-0x10000000(%edx)
f0102513:	75 11                	jne    f0102526 <mem_init+0x12f1>
f0102515:	8d 82 04 00 00 f0    	lea    -0xffffffc(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010251b:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102521:	f6 00 01             	testb  $0x1,(%eax)
f0102524:	74 24                	je     f010254a <mem_init+0x1315>
f0102526:	c7 44 24 0c 8e 4c 10 	movl   $0xf0104c8e,0xc(%esp)
f010252d:	f0 
f010252e:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102535:	f0 
f0102536:	c7 44 24 04 6f 03 00 	movl   $0x36f,0x4(%esp)
f010253d:	00 
f010253e:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102545:	e8 4a db ff ff       	call   f0100094 <_panic>
f010254a:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f010254d:	39 d0                	cmp    %edx,%eax
f010254f:	75 d0                	jne    f0102521 <mem_init+0x12ec>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102551:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0102556:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010255c:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// give free list back
	page_free_list = fl;
f0102562:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102565:	89 0d 80 75 11 f0    	mov    %ecx,0xf0117580

	// free the pages we took
	page_free(pp0);
f010256b:	89 1c 24             	mov    %ebx,(%esp)
f010256e:	e8 b2 e9 ff ff       	call   f0100f25 <page_free>
	page_free(pp1);
f0102573:	89 3c 24             	mov    %edi,(%esp)
f0102576:	e8 aa e9 ff ff       	call   f0100f25 <page_free>
	page_free(pp2);
f010257b:	89 34 24             	mov    %esi,(%esp)
f010257e:	e8 a2 e9 ff ff       	call   f0100f25 <page_free>

	cprintf("check_page() succeeded!\n");
f0102583:	c7 04 24 a5 4c 10 f0 	movl   $0xf0104ca5,(%esp)
f010258a:	e8 a7 07 00 00       	call   f0102d36 <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:

	boot_map_region(kern_pgdir,UPAGES,npages * sizeof (struct Page),PADDR ((uintptr_t *) pages), PTE_U);
f010258f:	a1 a8 79 11 f0       	mov    0xf01179a8,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102594:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102599:	77 20                	ja     f01025bb <mem_init+0x1386>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010259b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010259f:	c7 44 24 08 2c 44 10 	movl   $0xf010442c,0x8(%esp)
f01025a6:	f0 
f01025a7:	c7 44 24 04 ad 00 00 	movl   $0xad,0x4(%esp)
f01025ae:	00 
f01025af:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01025b6:	e8 d9 da ff ff       	call   f0100094 <_panic>
f01025bb:	8b 0d a0 79 11 f0    	mov    0xf01179a0,%ecx
f01025c1:	c1 e1 03             	shl    $0x3,%ecx
f01025c4:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
f01025cb:	00 
	return (physaddr_t)kva - KERNBASE;
f01025cc:	05 00 00 00 10       	add    $0x10000000,%eax
f01025d1:	89 04 24             	mov    %eax,(%esp)
f01025d4:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01025d9:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f01025de:	e8 5e ea ff ff       	call   f0101041 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01025e3:	b8 00 d0 10 f0       	mov    $0xf010d000,%eax
f01025e8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01025ed:	77 20                	ja     f010260f <mem_init+0x13da>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01025ef:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01025f3:	c7 44 24 08 2c 44 10 	movl   $0xf010442c,0x8(%esp)
f01025fa:	f0 
f01025fb:	c7 44 24 04 b9 00 00 	movl   $0xb9,0x4(%esp)
f0102602:	00 
f0102603:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f010260a:	e8 85 da ff ff       	call   f0100094 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region (kern_pgdir,KSTACKTOP - KSTKSIZE,KSTKSIZE,PADDR((uintptr_t *)bootstack),PTE_W);
f010260f:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102616:	00 
f0102617:	c7 04 24 00 d0 10 00 	movl   $0x10d000,(%esp)
f010261e:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102623:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f0102628:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f010262d:	e8 0f ea ff ff       	call   f0101041 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region (kern_pgdir,KERNBASE,0xffffffff-KERNBASE+1,(physaddr_t) 0,PTE_W);
f0102632:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102639:	00 
f010263a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102641:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102646:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f010264b:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0102650:	e8 ec e9 ff ff       	call   f0101041 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102655:	8b 1d a4 79 11 f0    	mov    0xf01179a4,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
f010265b:	8b 15 a0 79 11 f0    	mov    0xf01179a0,%edx
f0102661:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0102664:	8d 3c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%edi
	for (i = 0; i < n; i += PGSIZE)
f010266b:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
f0102671:	74 79                	je     f01026ec <mem_init+0x14b7>
f0102673:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102678:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010267e:	89 d8                	mov    %ebx,%eax
f0102680:	e8 39 e3 ff ff       	call   f01009be <check_va2pa>
f0102685:	8b 15 a8 79 11 f0    	mov    0xf01179a8,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010268b:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102691:	77 20                	ja     f01026b3 <mem_init+0x147e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102693:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102697:	c7 44 24 08 2c 44 10 	movl   $0xf010442c,0x8(%esp)
f010269e:	f0 
f010269f:	c7 44 24 04 bb 02 00 	movl   $0x2bb,0x4(%esp)
f01026a6:	00 
f01026a7:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01026ae:	e8 e1 d9 ff ff       	call   f0100094 <_panic>
f01026b3:	8d 94 32 00 00 00 10 	lea    0x10000000(%edx,%esi,1),%edx
f01026ba:	39 d0                	cmp    %edx,%eax
f01026bc:	74 24                	je     f01026e2 <mem_init+0x14ad>
f01026be:	c7 44 24 0c 98 48 10 	movl   $0xf0104898,0xc(%esp)
f01026c5:	f0 
f01026c6:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f01026cd:	f0 
f01026ce:	c7 44 24 04 bb 02 00 	movl   $0x2bb,0x4(%esp)
f01026d5:	00 
f01026d6:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01026dd:	e8 b2 d9 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01026e2:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01026e8:	39 f7                	cmp    %esi,%edi
f01026ea:	77 8c                	ja     f0102678 <mem_init+0x1443>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01026ec:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01026ef:	c1 e7 0c             	shl    $0xc,%edi
f01026f2:	85 ff                	test   %edi,%edi
f01026f4:	74 44                	je     f010273a <mem_init+0x1505>
f01026f6:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01026fb:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102701:	89 d8                	mov    %ebx,%eax
f0102703:	e8 b6 e2 ff ff       	call   f01009be <check_va2pa>
f0102708:	39 c6                	cmp    %eax,%esi
f010270a:	74 24                	je     f0102730 <mem_init+0x14fb>
f010270c:	c7 44 24 0c cc 48 10 	movl   $0xf01048cc,0xc(%esp)
f0102713:	f0 
f0102714:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f010271b:	f0 
f010271c:	c7 44 24 04 c0 02 00 	movl   $0x2c0,0x4(%esp)
f0102723:	00 
f0102724:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f010272b:	e8 64 d9 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102730:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102736:	39 fe                	cmp    %edi,%esi
f0102738:	72 c1                	jb     f01026fb <mem_init+0x14c6>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010273a:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f010273f:	89 d8                	mov    %ebx,%eax
f0102741:	e8 78 e2 ff ff       	call   f01009be <check_va2pa>
f0102746:	be 00 90 bf ef       	mov    $0xefbf9000,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010274b:	bf 00 d0 10 f0       	mov    $0xf010d000,%edi
f0102750:	81 c7 00 70 40 20    	add    $0x20407000,%edi
f0102756:	8d 14 37             	lea    (%edi,%esi,1),%edx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102759:	39 c2                	cmp    %eax,%edx
f010275b:	74 24                	je     f0102781 <mem_init+0x154c>
f010275d:	c7 44 24 0c f4 48 10 	movl   $0xf01048f4,0xc(%esp)
f0102764:	f0 
f0102765:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f010276c:	f0 
f010276d:	c7 44 24 04 c4 02 00 	movl   $0x2c4,0x4(%esp)
f0102774:	00 
f0102775:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f010277c:	e8 13 d9 ff ff       	call   f0100094 <_panic>
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102781:	81 fe 00 00 c0 ef    	cmp    $0xefc00000,%esi
f0102787:	0f 85 27 05 00 00    	jne    f0102cb4 <mem_init+0x1a7f>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010278d:	ba 00 00 80 ef       	mov    $0xef800000,%edx
f0102792:	89 d8                	mov    %ebx,%eax
f0102794:	e8 25 e2 ff ff       	call   f01009be <check_va2pa>
f0102799:	83 f8 ff             	cmp    $0xffffffff,%eax
f010279c:	74 24                	je     f01027c2 <mem_init+0x158d>
f010279e:	c7 44 24 0c 3c 49 10 	movl   $0xf010493c,0xc(%esp)
f01027a5:	f0 
f01027a6:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f01027ad:	f0 
f01027ae:	c7 44 24 04 c5 02 00 	movl   $0x2c5,0x4(%esp)
f01027b5:	00 
f01027b6:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01027bd:	e8 d2 d8 ff ff       	call   f0100094 <_panic>
f01027c2:	b8 00 00 00 00       	mov    $0x0,%eax

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01027c7:	8d 90 44 fc ff ff    	lea    -0x3bc(%eax),%edx
f01027cd:	83 fa 02             	cmp    $0x2,%edx
f01027d0:	77 2e                	ja     f0102800 <mem_init+0x15cb>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f01027d2:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f01027d6:	0f 85 aa 00 00 00    	jne    f0102886 <mem_init+0x1651>
f01027dc:	c7 44 24 0c be 4c 10 	movl   $0xf0104cbe,0xc(%esp)
f01027e3:	f0 
f01027e4:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f01027eb:	f0 
f01027ec:	c7 44 24 04 cd 02 00 	movl   $0x2cd,0x4(%esp)
f01027f3:	00 
f01027f4:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01027fb:	e8 94 d8 ff ff       	call   f0100094 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102800:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102805:	76 55                	jbe    f010285c <mem_init+0x1627>
				assert(pgdir[i] & PTE_P);
f0102807:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f010280a:	f6 c2 01             	test   $0x1,%dl
f010280d:	75 24                	jne    f0102833 <mem_init+0x15fe>
f010280f:	c7 44 24 0c be 4c 10 	movl   $0xf0104cbe,0xc(%esp)
f0102816:	f0 
f0102817:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f010281e:	f0 
f010281f:	c7 44 24 04 d1 02 00 	movl   $0x2d1,0x4(%esp)
f0102826:	00 
f0102827:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f010282e:	e8 61 d8 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f0102833:	f6 c2 02             	test   $0x2,%dl
f0102836:	75 4e                	jne    f0102886 <mem_init+0x1651>
f0102838:	c7 44 24 0c cf 4c 10 	movl   $0xf0104ccf,0xc(%esp)
f010283f:	f0 
f0102840:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102847:	f0 
f0102848:	c7 44 24 04 d2 02 00 	movl   $0x2d2,0x4(%esp)
f010284f:	00 
f0102850:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102857:	e8 38 d8 ff ff       	call   f0100094 <_panic>
			} else
				assert(pgdir[i] == 0);
f010285c:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0102860:	74 24                	je     f0102886 <mem_init+0x1651>
f0102862:	c7 44 24 0c e0 4c 10 	movl   $0xf0104ce0,0xc(%esp)
f0102869:	f0 
f010286a:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102871:	f0 
f0102872:	c7 44 24 04 d4 02 00 	movl   $0x2d4,0x4(%esp)
f0102879:	00 
f010287a:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102881:	e8 0e d8 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102886:	83 c0 01             	add    $0x1,%eax
f0102889:	3d 00 04 00 00       	cmp    $0x400,%eax
f010288e:	0f 85 33 ff ff ff    	jne    f01027c7 <mem_init+0x1592>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102894:	c7 04 24 6c 49 10 f0 	movl   $0xf010496c,(%esp)
f010289b:	e8 96 04 00 00       	call   f0102d36 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01028a0:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01028a5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01028aa:	77 20                	ja     f01028cc <mem_init+0x1697>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028ac:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01028b0:	c7 44 24 08 2c 44 10 	movl   $0xf010442c,0x8(%esp)
f01028b7:	f0 
f01028b8:	c7 44 24 04 cd 00 00 	movl   $0xcd,0x4(%esp)
f01028bf:	00 
f01028c0:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01028c7:	e8 c8 d7 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01028cc:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01028d1:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01028d4:	b8 00 00 00 00       	mov    $0x0,%eax
f01028d9:	e8 83 e1 ff ff       	call   f0100a61 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f01028de:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
f01028e1:	0d 23 00 05 80       	or     $0x80050023,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f01028e6:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f01028e9:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01028ec:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01028f3:	e8 a0 e5 ff ff       	call   f0100e98 <page_alloc>
f01028f8:	89 c6                	mov    %eax,%esi
f01028fa:	85 c0                	test   %eax,%eax
f01028fc:	75 24                	jne    f0102922 <mem_init+0x16ed>
f01028fe:	c7 44 24 0c fd 4a 10 	movl   $0xf0104afd,0xc(%esp)
f0102905:	f0 
f0102906:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f010290d:	f0 
f010290e:	c7 44 24 04 8a 03 00 	movl   $0x38a,0x4(%esp)
f0102915:	00 
f0102916:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f010291d:	e8 72 d7 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0102922:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102929:	e8 6a e5 ff ff       	call   f0100e98 <page_alloc>
f010292e:	89 c7                	mov    %eax,%edi
f0102930:	85 c0                	test   %eax,%eax
f0102932:	75 24                	jne    f0102958 <mem_init+0x1723>
f0102934:	c7 44 24 0c 13 4b 10 	movl   $0xf0104b13,0xc(%esp)
f010293b:	f0 
f010293c:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102943:	f0 
f0102944:	c7 44 24 04 8b 03 00 	movl   $0x38b,0x4(%esp)
f010294b:	00 
f010294c:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102953:	e8 3c d7 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0102958:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010295f:	e8 34 e5 ff ff       	call   f0100e98 <page_alloc>
f0102964:	89 c3                	mov    %eax,%ebx
f0102966:	85 c0                	test   %eax,%eax
f0102968:	75 24                	jne    f010298e <mem_init+0x1759>
f010296a:	c7 44 24 0c 29 4b 10 	movl   $0xf0104b29,0xc(%esp)
f0102971:	f0 
f0102972:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102979:	f0 
f010297a:	c7 44 24 04 8c 03 00 	movl   $0x38c,0x4(%esp)
f0102981:	00 
f0102982:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102989:	e8 06 d7 ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f010298e:	89 34 24             	mov    %esi,(%esp)
f0102991:	e8 8f e5 ff ff       	call   f0100f25 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102996:	89 f8                	mov    %edi,%eax
f0102998:	2b 05 a8 79 11 f0    	sub    0xf01179a8,%eax
f010299e:	c1 f8 03             	sar    $0x3,%eax
f01029a1:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01029a4:	89 c2                	mov    %eax,%edx
f01029a6:	c1 ea 0c             	shr    $0xc,%edx
f01029a9:	3b 15 a0 79 11 f0    	cmp    0xf01179a0,%edx
f01029af:	72 20                	jb     f01029d1 <mem_init+0x179c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01029b1:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01029b5:	c7 44 24 08 44 43 10 	movl   $0xf0104344,0x8(%esp)
f01029bc:	f0 
f01029bd:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01029c4:	00 
f01029c5:	c7 04 24 38 4a 10 f0 	movl   $0xf0104a38,(%esp)
f01029cc:	e8 c3 d6 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01029d1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01029d8:	00 
f01029d9:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01029e0:	00 
	return (void *)(pa + KERNBASE);
f01029e1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01029e6:	89 04 24             	mov    %eax,(%esp)
f01029e9:	e8 48 0f 00 00       	call   f0103936 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01029ee:	89 d8                	mov    %ebx,%eax
f01029f0:	2b 05 a8 79 11 f0    	sub    0xf01179a8,%eax
f01029f6:	c1 f8 03             	sar    $0x3,%eax
f01029f9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01029fc:	89 c2                	mov    %eax,%edx
f01029fe:	c1 ea 0c             	shr    $0xc,%edx
f0102a01:	3b 15 a0 79 11 f0    	cmp    0xf01179a0,%edx
f0102a07:	72 20                	jb     f0102a29 <mem_init+0x17f4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a09:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102a0d:	c7 44 24 08 44 43 10 	movl   $0xf0104344,0x8(%esp)
f0102a14:	f0 
f0102a15:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102a1c:	00 
f0102a1d:	c7 04 24 38 4a 10 f0 	movl   $0xf0104a38,(%esp)
f0102a24:	e8 6b d6 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102a29:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102a30:	00 
f0102a31:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102a38:	00 
	return (void *)(pa + KERNBASE);
f0102a39:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102a3e:	89 04 24             	mov    %eax,(%esp)
f0102a41:	e8 f0 0e 00 00       	call   f0103936 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102a46:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102a4d:	00 
f0102a4e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102a55:	00 
f0102a56:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102a5a:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0102a5f:	89 04 24             	mov    %eax,(%esp)
f0102a62:	e8 24 e7 ff ff       	call   f010118b <page_insert>
	assert(pp1->pp_ref == 1);
f0102a67:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102a6c:	74 24                	je     f0102a92 <mem_init+0x185d>
f0102a6e:	c7 44 24 0c fa 4b 10 	movl   $0xf0104bfa,0xc(%esp)
f0102a75:	f0 
f0102a76:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102a7d:	f0 
f0102a7e:	c7 44 24 04 91 03 00 	movl   $0x391,0x4(%esp)
f0102a85:	00 
f0102a86:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102a8d:	e8 02 d6 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102a92:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102a99:	01 01 01 
f0102a9c:	74 24                	je     f0102ac2 <mem_init+0x188d>
f0102a9e:	c7 44 24 0c 8c 49 10 	movl   $0xf010498c,0xc(%esp)
f0102aa5:	f0 
f0102aa6:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102aad:	f0 
f0102aae:	c7 44 24 04 92 03 00 	movl   $0x392,0x4(%esp)
f0102ab5:	00 
f0102ab6:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102abd:	e8 d2 d5 ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102ac2:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102ac9:	00 
f0102aca:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102ad1:	00 
f0102ad2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102ad6:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0102adb:	89 04 24             	mov    %eax,(%esp)
f0102ade:	e8 a8 e6 ff ff       	call   f010118b <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102ae3:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102aea:	02 02 02 
f0102aed:	74 24                	je     f0102b13 <mem_init+0x18de>
f0102aef:	c7 44 24 0c b0 49 10 	movl   $0xf01049b0,0xc(%esp)
f0102af6:	f0 
f0102af7:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102afe:	f0 
f0102aff:	c7 44 24 04 94 03 00 	movl   $0x394,0x4(%esp)
f0102b06:	00 
f0102b07:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102b0e:	e8 81 d5 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102b13:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102b18:	74 24                	je     f0102b3e <mem_init+0x1909>
f0102b1a:	c7 44 24 0c 1c 4c 10 	movl   $0xf0104c1c,0xc(%esp)
f0102b21:	f0 
f0102b22:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102b29:	f0 
f0102b2a:	c7 44 24 04 95 03 00 	movl   $0x395,0x4(%esp)
f0102b31:	00 
f0102b32:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102b39:	e8 56 d5 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102b3e:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102b43:	74 24                	je     f0102b69 <mem_init+0x1934>
f0102b45:	c7 44 24 0c 65 4c 10 	movl   $0xf0104c65,0xc(%esp)
f0102b4c:	f0 
f0102b4d:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102b54:	f0 
f0102b55:	c7 44 24 04 96 03 00 	movl   $0x396,0x4(%esp)
f0102b5c:	00 
f0102b5d:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102b64:	e8 2b d5 ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102b69:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102b70:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102b73:	89 d8                	mov    %ebx,%eax
f0102b75:	2b 05 a8 79 11 f0    	sub    0xf01179a8,%eax
f0102b7b:	c1 f8 03             	sar    $0x3,%eax
f0102b7e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b81:	89 c2                	mov    %eax,%edx
f0102b83:	c1 ea 0c             	shr    $0xc,%edx
f0102b86:	3b 15 a0 79 11 f0    	cmp    0xf01179a0,%edx
f0102b8c:	72 20                	jb     f0102bae <mem_init+0x1979>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b8e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102b92:	c7 44 24 08 44 43 10 	movl   $0xf0104344,0x8(%esp)
f0102b99:	f0 
f0102b9a:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102ba1:	00 
f0102ba2:	c7 04 24 38 4a 10 f0 	movl   $0xf0104a38,(%esp)
f0102ba9:	e8 e6 d4 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102bae:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102bb5:	03 03 03 
f0102bb8:	74 24                	je     f0102bde <mem_init+0x19a9>
f0102bba:	c7 44 24 0c d4 49 10 	movl   $0xf01049d4,0xc(%esp)
f0102bc1:	f0 
f0102bc2:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102bc9:	f0 
f0102bca:	c7 44 24 04 98 03 00 	movl   $0x398,0x4(%esp)
f0102bd1:	00 
f0102bd2:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102bd9:	e8 b6 d4 ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102bde:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102be5:	00 
f0102be6:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0102beb:	89 04 24             	mov    %eax,(%esp)
f0102bee:	e8 44 e5 ff ff       	call   f0101137 <page_remove>
	assert(pp2->pp_ref == 0);
f0102bf3:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102bf8:	74 24                	je     f0102c1e <mem_init+0x19e9>
f0102bfa:	c7 44 24 0c 54 4c 10 	movl   $0xf0104c54,0xc(%esp)
f0102c01:	f0 
f0102c02:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102c09:	f0 
f0102c0a:	c7 44 24 04 9a 03 00 	movl   $0x39a,0x4(%esp)
f0102c11:	00 
f0102c12:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102c19:	e8 76 d4 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102c1e:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0102c23:	8b 08                	mov    (%eax),%ecx
f0102c25:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102c2b:	89 f2                	mov    %esi,%edx
f0102c2d:	2b 15 a8 79 11 f0    	sub    0xf01179a8,%edx
f0102c33:	c1 fa 03             	sar    $0x3,%edx
f0102c36:	c1 e2 0c             	shl    $0xc,%edx
f0102c39:	39 d1                	cmp    %edx,%ecx
f0102c3b:	74 24                	je     f0102c61 <mem_init+0x1a2c>
f0102c3d:	c7 44 24 0c 84 45 10 	movl   $0xf0104584,0xc(%esp)
f0102c44:	f0 
f0102c45:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102c4c:	f0 
f0102c4d:	c7 44 24 04 9d 03 00 	movl   $0x39d,0x4(%esp)
f0102c54:	00 
f0102c55:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102c5c:	e8 33 d4 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102c61:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102c67:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102c6c:	74 24                	je     f0102c92 <mem_init+0x1a5d>
f0102c6e:	c7 44 24 0c 0b 4c 10 	movl   $0xf0104c0b,0xc(%esp)
f0102c75:	f0 
f0102c76:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102c7d:	f0 
f0102c7e:	c7 44 24 04 9f 03 00 	movl   $0x39f,0x4(%esp)
f0102c85:	00 
f0102c86:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102c8d:	e8 02 d4 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102c92:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102c98:	89 34 24             	mov    %esi,(%esp)
f0102c9b:	e8 85 e2 ff ff       	call   f0100f25 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102ca0:	c7 04 24 00 4a 10 f0 	movl   $0xf0104a00,(%esp)
f0102ca7:	e8 8a 00 00 00       	call   f0102d36 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102cac:	83 c4 3c             	add    $0x3c,%esp
f0102caf:	5b                   	pop    %ebx
f0102cb0:	5e                   	pop    %esi
f0102cb1:	5f                   	pop    %edi
f0102cb2:	5d                   	pop    %ebp
f0102cb3:	c3                   	ret    
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102cb4:	89 f2                	mov    %esi,%edx
f0102cb6:	89 d8                	mov    %ebx,%eax
f0102cb8:	e8 01 dd ff ff       	call   f01009be <check_va2pa>
f0102cbd:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102cc3:	e9 8e fa ff ff       	jmp    f0102756 <mem_init+0x1521>

f0102cc8 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102cc8:	55                   	push   %ebp
f0102cc9:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102ccb:	ba 70 00 00 00       	mov    $0x70,%edx
f0102cd0:	8b 45 08             	mov    0x8(%ebp),%eax
f0102cd3:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102cd4:	b2 71                	mov    $0x71,%dl
f0102cd6:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102cd7:	0f b6 c0             	movzbl %al,%eax
}
f0102cda:	5d                   	pop    %ebp
f0102cdb:	c3                   	ret    

f0102cdc <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102cdc:	55                   	push   %ebp
f0102cdd:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102cdf:	ba 70 00 00 00       	mov    $0x70,%edx
f0102ce4:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ce7:	ee                   	out    %al,(%dx)
f0102ce8:	b2 71                	mov    $0x71,%dl
f0102cea:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ced:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102cee:	5d                   	pop    %ebp
f0102cef:	c3                   	ret    

f0102cf0 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102cf0:	55                   	push   %ebp
f0102cf1:	89 e5                	mov    %esp,%ebp
f0102cf3:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0102cf6:	8b 45 08             	mov    0x8(%ebp),%eax
f0102cf9:	89 04 24             	mov    %eax,(%esp)
f0102cfc:	e8 f0 d8 ff ff       	call   f01005f1 <cputchar>
	*cnt++;
}
f0102d01:	c9                   	leave  
f0102d02:	c3                   	ret    

f0102d03 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102d03:	55                   	push   %ebp
f0102d04:	89 e5                	mov    %esp,%ebp
f0102d06:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0102d09:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102d10:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d13:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102d17:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d1a:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102d1e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102d21:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d25:	c7 04 24 f0 2c 10 f0 	movl   $0xf0102cf0,(%esp)
f0102d2c:	e8 69 04 00 00       	call   f010319a <vprintfmt>
	return cnt;
}
f0102d31:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102d34:	c9                   	leave  
f0102d35:	c3                   	ret    

f0102d36 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102d36:	55                   	push   %ebp
f0102d37:	89 e5                	mov    %esp,%ebp
f0102d39:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102d3c:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102d3f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d43:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d46:	89 04 24             	mov    %eax,(%esp)
f0102d49:	e8 b5 ff ff ff       	call   f0102d03 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102d4e:	c9                   	leave  
f0102d4f:	c3                   	ret    

f0102d50 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102d50:	55                   	push   %ebp
f0102d51:	89 e5                	mov    %esp,%ebp
f0102d53:	57                   	push   %edi
f0102d54:	56                   	push   %esi
f0102d55:	53                   	push   %ebx
f0102d56:	83 ec 10             	sub    $0x10,%esp
f0102d59:	89 c3                	mov    %eax,%ebx
f0102d5b:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0102d5e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0102d61:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102d64:	8b 0a                	mov    (%edx),%ecx
f0102d66:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102d69:	8b 00                	mov    (%eax),%eax
f0102d6b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102d6e:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f0102d75:	eb 77                	jmp    f0102dee <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f0102d77:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102d7a:	01 c8                	add    %ecx,%eax
f0102d7c:	bf 02 00 00 00       	mov    $0x2,%edi
f0102d81:	99                   	cltd   
f0102d82:	f7 ff                	idiv   %edi
f0102d84:	89 c2                	mov    %eax,%edx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102d86:	eb 01                	jmp    f0102d89 <stab_binsearch+0x39>
			m--;
f0102d88:	4a                   	dec    %edx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102d89:	39 ca                	cmp    %ecx,%edx
f0102d8b:	7c 1d                	jl     f0102daa <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0102d8d:	6b fa 0c             	imul   $0xc,%edx,%edi
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102d90:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f0102d95:	39 f7                	cmp    %esi,%edi
f0102d97:	75 ef                	jne    f0102d88 <stab_binsearch+0x38>
f0102d99:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102d9c:	6b fa 0c             	imul   $0xc,%edx,%edi
f0102d9f:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f0102da3:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0102da6:	73 18                	jae    f0102dc0 <stab_binsearch+0x70>
f0102da8:	eb 05                	jmp    f0102daf <stab_binsearch+0x5f>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102daa:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0102dad:	eb 3f                	jmp    f0102dee <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0102daf:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0102db2:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0102db4:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102db7:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102dbe:	eb 2e                	jmp    f0102dee <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102dc0:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0102dc3:	76 15                	jbe    f0102dda <stab_binsearch+0x8a>
			*region_right = m - 1;
f0102dc5:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0102dc8:	4f                   	dec    %edi
f0102dc9:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0102dcc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102dcf:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102dd1:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102dd8:	eb 14                	jmp    f0102dee <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102dda:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0102ddd:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0102de0:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f0102de2:	ff 45 0c             	incl   0xc(%ebp)
f0102de5:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102de7:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0102dee:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0102df1:	7e 84                	jle    f0102d77 <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102df3:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0102df7:	75 0d                	jne    f0102e06 <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0102df9:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102dfc:	8b 02                	mov    (%edx),%eax
f0102dfe:	48                   	dec    %eax
f0102dff:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102e02:	89 01                	mov    %eax,(%ecx)
f0102e04:	eb 22                	jmp    f0102e28 <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102e06:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102e09:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102e0b:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102e0e:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102e10:	eb 01                	jmp    f0102e13 <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102e12:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102e13:	39 c1                	cmp    %eax,%ecx
f0102e15:	7d 0c                	jge    f0102e23 <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0102e17:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0102e1a:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f0102e1f:	39 f2                	cmp    %esi,%edx
f0102e21:	75 ef                	jne    f0102e12 <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102e23:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102e26:	89 02                	mov    %eax,(%edx)
	}
}
f0102e28:	83 c4 10             	add    $0x10,%esp
f0102e2b:	5b                   	pop    %ebx
f0102e2c:	5e                   	pop    %esi
f0102e2d:	5f                   	pop    %edi
f0102e2e:	5d                   	pop    %ebp
f0102e2f:	c3                   	ret    

f0102e30 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102e30:	55                   	push   %ebp
f0102e31:	89 e5                	mov    %esp,%ebp
f0102e33:	83 ec 38             	sub    $0x38,%esp
f0102e36:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0102e39:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0102e3c:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0102e3f:	8b 75 08             	mov    0x8(%ebp),%esi
f0102e42:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102e45:	c7 03 04 41 10 f0    	movl   $0xf0104104,(%ebx)
	info->eip_line = 0;
f0102e4b:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102e52:	c7 43 08 04 41 10 f0 	movl   $0xf0104104,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102e59:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102e60:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102e63:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102e6a:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102e70:	76 12                	jbe    f0102e84 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102e72:	b8 f9 cf 10 f0       	mov    $0xf010cff9,%eax
f0102e77:	3d c5 b1 10 f0       	cmp    $0xf010b1c5,%eax
f0102e7c:	0f 86 9b 01 00 00    	jbe    f010301d <debuginfo_eip+0x1ed>
f0102e82:	eb 1c                	jmp    f0102ea0 <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102e84:	c7 44 24 08 ee 4c 10 	movl   $0xf0104cee,0x8(%esp)
f0102e8b:	f0 
f0102e8c:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0102e93:	00 
f0102e94:	c7 04 24 fb 4c 10 f0 	movl   $0xf0104cfb,(%esp)
f0102e9b:	e8 f4 d1 ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102ea0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102ea5:	80 3d f8 cf 10 f0 00 	cmpb   $0x0,0xf010cff8
f0102eac:	0f 85 77 01 00 00    	jne    f0103029 <debuginfo_eip+0x1f9>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102eb2:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102eb9:	b8 c4 b1 10 f0       	mov    $0xf010b1c4,%eax
f0102ebe:	2d 18 4f 10 f0       	sub    $0xf0104f18,%eax
f0102ec3:	c1 f8 02             	sar    $0x2,%eax
f0102ec6:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102ecc:	83 e8 01             	sub    $0x1,%eax
f0102ecf:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102ed2:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102ed6:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0102edd:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102ee0:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102ee3:	b8 18 4f 10 f0       	mov    $0xf0104f18,%eax
f0102ee8:	e8 63 fe ff ff       	call   f0102d50 <stab_binsearch>
	if (lfile == 0)
f0102eed:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0102ef0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0102ef5:	85 d2                	test   %edx,%edx
f0102ef7:	0f 84 2c 01 00 00    	je     f0103029 <debuginfo_eip+0x1f9>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102efd:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0102f00:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102f03:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102f06:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102f0a:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0102f11:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102f14:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102f17:	b8 18 4f 10 f0       	mov    $0xf0104f18,%eax
f0102f1c:	e8 2f fe ff ff       	call   f0102d50 <stab_binsearch>

	if (lfun <= rfun) {
f0102f21:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0102f24:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0102f27:	7f 2e                	jg     f0102f57 <debuginfo_eip+0x127>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102f29:	6b c7 0c             	imul   $0xc,%edi,%eax
f0102f2c:	8d 90 18 4f 10 f0    	lea    -0xfefb0e8(%eax),%edx
f0102f32:	8b 80 18 4f 10 f0    	mov    -0xfefb0e8(%eax),%eax
f0102f38:	b9 f9 cf 10 f0       	mov    $0xf010cff9,%ecx
f0102f3d:	81 e9 c5 b1 10 f0    	sub    $0xf010b1c5,%ecx
f0102f43:	39 c8                	cmp    %ecx,%eax
f0102f45:	73 08                	jae    f0102f4f <debuginfo_eip+0x11f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102f47:	05 c5 b1 10 f0       	add    $0xf010b1c5,%eax
f0102f4c:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102f4f:	8b 42 08             	mov    0x8(%edx),%eax
f0102f52:	89 43 10             	mov    %eax,0x10(%ebx)
f0102f55:	eb 06                	jmp    f0102f5d <debuginfo_eip+0x12d>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102f57:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102f5a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102f5d:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0102f64:	00 
f0102f65:	8b 43 08             	mov    0x8(%ebx),%eax
f0102f68:	89 04 24             	mov    %eax,(%esp)
f0102f6b:	e8 9f 09 00 00       	call   f010390f <strfind>
f0102f70:	2b 43 08             	sub    0x8(%ebx),%eax
f0102f73:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102f76:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102f79:	39 d7                	cmp    %edx,%edi
f0102f7b:	7c 5f                	jl     f0102fdc <debuginfo_eip+0x1ac>
	       && stabs[lline].n_type != N_SOL
f0102f7d:	89 f8                	mov    %edi,%eax
f0102f7f:	6b cf 0c             	imul   $0xc,%edi,%ecx
f0102f82:	80 b9 1c 4f 10 f0 84 	cmpb   $0x84,-0xfefb0e4(%ecx)
f0102f89:	75 18                	jne    f0102fa3 <debuginfo_eip+0x173>
f0102f8b:	eb 30                	jmp    f0102fbd <debuginfo_eip+0x18d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0102f8d:	83 ef 01             	sub    $0x1,%edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102f90:	39 fa                	cmp    %edi,%edx
f0102f92:	7f 48                	jg     f0102fdc <debuginfo_eip+0x1ac>
	       && stabs[lline].n_type != N_SOL
f0102f94:	89 f8                	mov    %edi,%eax
f0102f96:	8d 0c 7f             	lea    (%edi,%edi,2),%ecx
f0102f99:	80 3c 8d 1c 4f 10 f0 	cmpb   $0x84,-0xfefb0e4(,%ecx,4)
f0102fa0:	84 
f0102fa1:	74 1a                	je     f0102fbd <debuginfo_eip+0x18d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102fa3:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102fa6:	8d 04 85 18 4f 10 f0 	lea    -0xfefb0e8(,%eax,4),%eax
f0102fad:	80 78 04 64          	cmpb   $0x64,0x4(%eax)
f0102fb1:	75 da                	jne    f0102f8d <debuginfo_eip+0x15d>
f0102fb3:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0102fb7:	74 d4                	je     f0102f8d <debuginfo_eip+0x15d>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102fb9:	39 fa                	cmp    %edi,%edx
f0102fbb:	7f 1f                	jg     f0102fdc <debuginfo_eip+0x1ac>
f0102fbd:	6b ff 0c             	imul   $0xc,%edi,%edi
f0102fc0:	8b 87 18 4f 10 f0    	mov    -0xfefb0e8(%edi),%eax
f0102fc6:	ba f9 cf 10 f0       	mov    $0xf010cff9,%edx
f0102fcb:	81 ea c5 b1 10 f0    	sub    $0xf010b1c5,%edx
f0102fd1:	39 d0                	cmp    %edx,%eax
f0102fd3:	73 07                	jae    f0102fdc <debuginfo_eip+0x1ac>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102fd5:	05 c5 b1 10 f0       	add    $0xf010b1c5,%eax
f0102fda:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102fdc:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102fdf:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0102fe2:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102fe7:	39 ca                	cmp    %ecx,%edx
f0102fe9:	7d 3e                	jge    f0103029 <debuginfo_eip+0x1f9>
		for (lline = lfun + 1;
f0102feb:	83 c2 01             	add    $0x1,%edx
f0102fee:	39 d1                	cmp    %edx,%ecx
f0102ff0:	7e 37                	jle    f0103029 <debuginfo_eip+0x1f9>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102ff2:	6b f2 0c             	imul   $0xc,%edx,%esi
f0102ff5:	80 be 1c 4f 10 f0 a0 	cmpb   $0xa0,-0xfefb0e4(%esi)
f0102ffc:	75 2b                	jne    f0103029 <debuginfo_eip+0x1f9>
		     lline++)
			info->eip_fn_narg++;
f0102ffe:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0103002:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103005:	39 d1                	cmp    %edx,%ecx
f0103007:	7e 1b                	jle    f0103024 <debuginfo_eip+0x1f4>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103009:	8d 04 52             	lea    (%edx,%edx,2),%eax
f010300c:	80 3c 85 1c 4f 10 f0 	cmpb   $0xa0,-0xfefb0e4(,%eax,4)
f0103013:	a0 
f0103014:	74 e8                	je     f0102ffe <debuginfo_eip+0x1ce>
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0103016:	b8 00 00 00 00       	mov    $0x0,%eax
f010301b:	eb 0c                	jmp    f0103029 <debuginfo_eip+0x1f9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f010301d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103022:	eb 05                	jmp    f0103029 <debuginfo_eip+0x1f9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0103024:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103029:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f010302c:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010302f:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0103032:	89 ec                	mov    %ebp,%esp
f0103034:	5d                   	pop    %ebp
f0103035:	c3                   	ret    
	...

f0103040 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103040:	55                   	push   %ebp
f0103041:	89 e5                	mov    %esp,%ebp
f0103043:	57                   	push   %edi
f0103044:	56                   	push   %esi
f0103045:	53                   	push   %ebx
f0103046:	83 ec 3c             	sub    $0x3c,%esp
f0103049:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010304c:	89 d7                	mov    %edx,%edi
f010304e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103051:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103054:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103057:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010305a:	8b 5d 14             	mov    0x14(%ebp),%ebx
f010305d:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103060:	b8 00 00 00 00       	mov    $0x0,%eax
f0103065:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0103068:	72 11                	jb     f010307b <printnum+0x3b>
f010306a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010306d:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103070:	76 09                	jbe    f010307b <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103072:	83 eb 01             	sub    $0x1,%ebx
f0103075:	85 db                	test   %ebx,%ebx
f0103077:	7f 51                	jg     f01030ca <printnum+0x8a>
f0103079:	eb 5e                	jmp    f01030d9 <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010307b:	89 74 24 10          	mov    %esi,0x10(%esp)
f010307f:	83 eb 01             	sub    $0x1,%ebx
f0103082:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103086:	8b 45 10             	mov    0x10(%ebp),%eax
f0103089:	89 44 24 08          	mov    %eax,0x8(%esp)
f010308d:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0103091:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0103095:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010309c:	00 
f010309d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01030a0:	89 04 24             	mov    %eax,(%esp)
f01030a3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01030a6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01030aa:	e8 e1 0a 00 00       	call   f0103b90 <__udivdi3>
f01030af:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01030b3:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01030b7:	89 04 24             	mov    %eax,(%esp)
f01030ba:	89 54 24 04          	mov    %edx,0x4(%esp)
f01030be:	89 fa                	mov    %edi,%edx
f01030c0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01030c3:	e8 78 ff ff ff       	call   f0103040 <printnum>
f01030c8:	eb 0f                	jmp    f01030d9 <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01030ca:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01030ce:	89 34 24             	mov    %esi,(%esp)
f01030d1:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01030d4:	83 eb 01             	sub    $0x1,%ebx
f01030d7:	75 f1                	jne    f01030ca <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01030d9:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01030dd:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01030e1:	8b 45 10             	mov    0x10(%ebp),%eax
f01030e4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01030e8:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01030ef:	00 
f01030f0:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01030f3:	89 04 24             	mov    %eax,(%esp)
f01030f6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01030f9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01030fd:	e8 be 0b 00 00       	call   f0103cc0 <__umoddi3>
f0103102:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103106:	0f be 80 09 4d 10 f0 	movsbl -0xfefb2f7(%eax),%eax
f010310d:	89 04 24             	mov    %eax,(%esp)
f0103110:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0103113:	83 c4 3c             	add    $0x3c,%esp
f0103116:	5b                   	pop    %ebx
f0103117:	5e                   	pop    %esi
f0103118:	5f                   	pop    %edi
f0103119:	5d                   	pop    %ebp
f010311a:	c3                   	ret    

f010311b <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f010311b:	55                   	push   %ebp
f010311c:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f010311e:	83 fa 01             	cmp    $0x1,%edx
f0103121:	7e 0e                	jle    f0103131 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103123:	8b 10                	mov    (%eax),%edx
f0103125:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103128:	89 08                	mov    %ecx,(%eax)
f010312a:	8b 02                	mov    (%edx),%eax
f010312c:	8b 52 04             	mov    0x4(%edx),%edx
f010312f:	eb 22                	jmp    f0103153 <getuint+0x38>
	else if (lflag)
f0103131:	85 d2                	test   %edx,%edx
f0103133:	74 10                	je     f0103145 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103135:	8b 10                	mov    (%eax),%edx
f0103137:	8d 4a 04             	lea    0x4(%edx),%ecx
f010313a:	89 08                	mov    %ecx,(%eax)
f010313c:	8b 02                	mov    (%edx),%eax
f010313e:	ba 00 00 00 00       	mov    $0x0,%edx
f0103143:	eb 0e                	jmp    f0103153 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103145:	8b 10                	mov    (%eax),%edx
f0103147:	8d 4a 04             	lea    0x4(%edx),%ecx
f010314a:	89 08                	mov    %ecx,(%eax)
f010314c:	8b 02                	mov    (%edx),%eax
f010314e:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103153:	5d                   	pop    %ebp
f0103154:	c3                   	ret    

f0103155 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103155:	55                   	push   %ebp
f0103156:	89 e5                	mov    %esp,%ebp
f0103158:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010315b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f010315f:	8b 10                	mov    (%eax),%edx
f0103161:	3b 50 04             	cmp    0x4(%eax),%edx
f0103164:	73 0a                	jae    f0103170 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103166:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103169:	88 0a                	mov    %cl,(%edx)
f010316b:	83 c2 01             	add    $0x1,%edx
f010316e:	89 10                	mov    %edx,(%eax)
}
f0103170:	5d                   	pop    %ebp
f0103171:	c3                   	ret    

f0103172 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103172:	55                   	push   %ebp
f0103173:	89 e5                	mov    %esp,%ebp
f0103175:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0103178:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010317b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010317f:	8b 45 10             	mov    0x10(%ebp),%eax
f0103182:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103186:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103189:	89 44 24 04          	mov    %eax,0x4(%esp)
f010318d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103190:	89 04 24             	mov    %eax,(%esp)
f0103193:	e8 02 00 00 00       	call   f010319a <vprintfmt>
	va_end(ap);
}
f0103198:	c9                   	leave  
f0103199:	c3                   	ret    

f010319a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010319a:	55                   	push   %ebp
f010319b:	89 e5                	mov    %esp,%ebp
f010319d:	57                   	push   %edi
f010319e:	56                   	push   %esi
f010319f:	53                   	push   %ebx
f01031a0:	83 ec 3c             	sub    $0x3c,%esp
f01031a3:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01031a6:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f01031a9:	e9 bb 00 00 00       	jmp    f0103269 <vprintfmt+0xcf>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01031ae:	85 c0                	test   %eax,%eax
f01031b0:	0f 84 63 04 00 00    	je     f0103619 <vprintfmt+0x47f>
				return;
			if (ch =='\033'){//if this is Escape character  and this if is char color set.
f01031b6:	83 f8 1b             	cmp    $0x1b,%eax
f01031b9:	0f 85 9a 00 00 00    	jne    f0103259 <vprintfmt+0xbf>
				int temp_color_no=0;
				ch = *(unsigned char *) fmt++;
f01031bf:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01031c2:	83 c3 02             	add    $0x2,%ebx
				while (ch != 'm') 
f01031c5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01031c8:	80 78 01 6d          	cmpb   $0x6d,0x1(%eax)
f01031cc:	0f 84 81 00 00 00    	je     f0103253 <vprintfmt+0xb9>
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
				return;
			if (ch =='\033'){//if this is Escape character  and this if is char color set.
				int temp_color_no=0;
f01031d2:	ba 00 00 00 00       	mov    $0x0,%edx
				ch = *(unsigned char *) fmt++;
				while (ch != 'm') 
				{
					ch = *(unsigned char *) fmt++;
f01031d7:	0f b6 03             	movzbl (%ebx),%eax
f01031da:	83 c3 01             	add    $0x1,%ebx
					if ( ch !=';' && ch!='m')
f01031dd:	83 f8 6d             	cmp    $0x6d,%eax
f01031e0:	0f 95 c1             	setne  %cl
f01031e3:	83 f8 3b             	cmp    $0x3b,%eax
f01031e6:	74 0d                	je     f01031f5 <vprintfmt+0x5b>
f01031e8:	84 c9                	test   %cl,%cl
f01031ea:	74 09                	je     f01031f5 <vprintfmt+0x5b>
						temp_color_no=temp_color_no*10+ch-'0';
f01031ec:	8d 14 92             	lea    (%edx,%edx,4),%edx
f01031ef:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
f01031f3:	eb 55                	jmp    f010324a <vprintfmt+0xb0>
					else if ( ch==';' || ch=='m'){
f01031f5:	83 f8 3b             	cmp    $0x3b,%eax
f01031f8:	74 05                	je     f01031ff <vprintfmt+0x65>
f01031fa:	83 f8 6d             	cmp    $0x6d,%eax
f01031fd:	75 4b                	jne    f010324a <vprintfmt+0xb0>
						if ( temp_color_no >=30 && temp_color_no<40){// Foreground colors
f01031ff:	89 d6                	mov    %edx,%esi
f0103201:	8d 7a e2             	lea    -0x1e(%edx),%edi
f0103204:	83 ff 09             	cmp    $0x9,%edi
f0103207:	77 16                	ja     f010321f <vprintfmt+0x85>
							char_color = (char_color&0xf0) + (temp_color_no-30);						
f0103209:	8b 3d 00 73 11 f0    	mov    0xf0117300,%edi
f010320f:	81 e7 f0 00 00 00    	and    $0xf0,%edi
f0103215:	8d 7c 3a e2          	lea    -0x1e(%edx,%edi,1),%edi
f0103219:	89 3d 00 73 11 f0    	mov    %edi,0xf0117300
							}
						if ( temp_color_no >=40 && temp_color_no<50){// Background colors
f010321f:	83 ee 28             	sub    $0x28,%esi
f0103222:	83 fe 09             	cmp    $0x9,%esi
f0103225:	77 1e                	ja     f0103245 <vprintfmt+0xab>
							char_color = (char_color&0x0f) + ((temp_color_no-40)<<4);
f0103227:	8b 35 00 73 11 f0    	mov    0xf0117300,%esi
f010322d:	83 e6 0f             	and    $0xf,%esi
f0103230:	83 ea 28             	sub    $0x28,%edx
f0103233:	c1 e2 04             	shl    $0x4,%edx
f0103236:	01 f2                	add    %esi,%edx
f0103238:	89 15 00 73 11 f0    	mov    %edx,0xf0117300
						}
						//cprintf("0x%o ,",char_color);
						temp_color_no=0;
f010323e:	ba 00 00 00 00       	mov    $0x0,%edx
f0103243:	eb 05                	jmp    f010324a <vprintfmt+0xb0>
f0103245:	ba 00 00 00 00       	mov    $0x0,%edx
			if (ch == '\0')
				return;
			if (ch =='\033'){//if this is Escape character  and this if is char color set.
				int temp_color_no=0;
				ch = *(unsigned char *) fmt++;
				while (ch != 'm') 
f010324a:	84 c9                	test   %cl,%cl
f010324c:	75 89                	jne    f01031d7 <vprintfmt+0x3d>
						}
						//cprintf("0x%o ,",char_color);
						temp_color_no=0;
					}
				}
				if (ch == 'm')
f010324e:	83 f8 6d             	cmp    $0x6d,%eax
f0103251:	75 06                	jne    f0103259 <vprintfmt+0xbf>
					ch = *(unsigned char *) fmt++;
f0103253:	0f b6 03             	movzbl (%ebx),%eax
f0103256:	83 c3 01             	add    $0x1,%ebx
				
			}
			putch(ch, putdat);
f0103259:	8b 55 0c             	mov    0xc(%ebp),%edx
f010325c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103260:	89 04 24             	mov    %eax,(%esp)
f0103263:	ff 55 08             	call   *0x8(%ebp)
f0103266:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103269:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010326c:	0f b6 03             	movzbl (%ebx),%eax
f010326f:	83 c3 01             	add    $0x1,%ebx
f0103272:	83 f8 25             	cmp    $0x25,%eax
f0103275:	0f 85 33 ff ff ff    	jne    f01031ae <vprintfmt+0x14>
f010327b:	c6 45 e0 20          	movb   $0x20,-0x20(%ebp)
f010327f:	bf 00 00 00 00       	mov    $0x0,%edi
f0103284:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0103289:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0103290:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103295:	eb 23                	jmp    f01032ba <vprintfmt+0x120>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103297:	89 c3                	mov    %eax,%ebx

		// flag to pad on the right
		case '-':
			padc = '-';
f0103299:	c6 45 e0 2d          	movb   $0x2d,-0x20(%ebp)
f010329d:	eb 1b                	jmp    f01032ba <vprintfmt+0x120>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010329f:	89 c3                	mov    %eax,%ebx
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01032a1:	c6 45 e0 30          	movb   $0x30,-0x20(%ebp)
f01032a5:	eb 13                	jmp    f01032ba <vprintfmt+0x120>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032a7:	89 c3                	mov    %eax,%ebx
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f01032a9:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f01032b0:	eb 08                	jmp    f01032ba <vprintfmt+0x120>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f01032b2:	89 75 dc             	mov    %esi,-0x24(%ebp)
f01032b5:	be ff ff ff ff       	mov    $0xffffffff,%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032ba:	0f b6 13             	movzbl (%ebx),%edx
f01032bd:	0f b6 c2             	movzbl %dl,%eax
f01032c0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01032c3:	8d 43 01             	lea    0x1(%ebx),%eax
f01032c6:	83 ea 23             	sub    $0x23,%edx
f01032c9:	80 fa 55             	cmp    $0x55,%dl
f01032cc:	0f 87 18 03 00 00    	ja     f01035ea <vprintfmt+0x450>
f01032d2:	0f b6 d2             	movzbl %dl,%edx
f01032d5:	ff 24 95 94 4d 10 f0 	jmp    *-0xfefb26c(,%edx,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01032dc:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01032df:	83 ee 30             	sub    $0x30,%esi
				ch = *fmt;
f01032e2:	0f be 53 01          	movsbl 0x1(%ebx),%edx
				if (ch < '0' || ch > '9')
f01032e6:	8d 5a d0             	lea    -0x30(%edx),%ebx
f01032e9:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032ec:	89 c3                	mov    %eax,%ebx
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f01032ee:	83 7d e4 09          	cmpl   $0x9,-0x1c(%ebp)
f01032f2:	77 3b                	ja     f010332f <vprintfmt+0x195>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01032f4:	83 c0 01             	add    $0x1,%eax
				precision = precision * 10 + ch - '0';
f01032f7:	8d 1c b6             	lea    (%esi,%esi,4),%ebx
f01032fa:	8d 74 5a d0          	lea    -0x30(%edx,%ebx,2),%esi
				ch = *fmt;
f01032fe:	0f be 10             	movsbl (%eax),%edx
				if (ch < '0' || ch > '9')
f0103301:	8d 5a d0             	lea    -0x30(%edx),%ebx
f0103304:	83 fb 09             	cmp    $0x9,%ebx
f0103307:	76 eb                	jbe    f01032f4 <vprintfmt+0x15a>
f0103309:	eb 22                	jmp    f010332d <vprintfmt+0x193>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f010330b:	8b 55 14             	mov    0x14(%ebp),%edx
f010330e:	8d 5a 04             	lea    0x4(%edx),%ebx
f0103311:	89 5d 14             	mov    %ebx,0x14(%ebp)
f0103314:	8b 32                	mov    (%edx),%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103316:	89 c3                	mov    %eax,%ebx
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103318:	eb 15                	jmp    f010332f <vprintfmt+0x195>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010331a:	89 c3                	mov    %eax,%ebx
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f010331c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103320:	79 98                	jns    f01032ba <vprintfmt+0x120>
f0103322:	eb 83                	jmp    f01032a7 <vprintfmt+0x10d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103324:	89 c3                	mov    %eax,%ebx
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103326:	bf 01 00 00 00       	mov    $0x1,%edi
			goto reswitch;
f010332b:	eb 8d                	jmp    f01032ba <vprintfmt+0x120>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f010332d:	89 c3                	mov    %eax,%ebx
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f010332f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103333:	79 85                	jns    f01032ba <vprintfmt+0x120>
f0103335:	e9 78 ff ff ff       	jmp    f01032b2 <vprintfmt+0x118>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f010333a:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010333d:	89 c3                	mov    %eax,%ebx
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010333f:	e9 76 ff ff ff       	jmp    f01032ba <vprintfmt+0x120>
f0103344:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103347:	8b 45 14             	mov    0x14(%ebp),%eax
f010334a:	8d 50 04             	lea    0x4(%eax),%edx
f010334d:	89 55 14             	mov    %edx,0x14(%ebp)
f0103350:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103353:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103357:	8b 00                	mov    (%eax),%eax
f0103359:	89 04 24             	mov    %eax,(%esp)
f010335c:	ff 55 08             	call   *0x8(%ebp)
			break;
f010335f:	e9 05 ff ff ff       	jmp    f0103269 <vprintfmt+0xcf>
f0103364:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103367:	8b 45 14             	mov    0x14(%ebp),%eax
f010336a:	8d 50 04             	lea    0x4(%eax),%edx
f010336d:	89 55 14             	mov    %edx,0x14(%ebp)
f0103370:	8b 00                	mov    (%eax),%eax
f0103372:	89 c2                	mov    %eax,%edx
f0103374:	c1 fa 1f             	sar    $0x1f,%edx
f0103377:	31 d0                	xor    %edx,%eax
f0103379:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010337b:	83 f8 06             	cmp    $0x6,%eax
f010337e:	7f 0b                	jg     f010338b <vprintfmt+0x1f1>
f0103380:	8b 14 85 ec 4e 10 f0 	mov    -0xfefb114(,%eax,4),%edx
f0103387:	85 d2                	test   %edx,%edx
f0103389:	75 23                	jne    f01033ae <vprintfmt+0x214>
				printfmt(putch, putdat, "error %d", err);
f010338b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010338f:	c7 44 24 08 21 4d 10 	movl   $0xf0104d21,0x8(%esp)
f0103396:	f0 
f0103397:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010339a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010339e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01033a1:	89 1c 24             	mov    %ebx,(%esp)
f01033a4:	e8 c9 fd ff ff       	call   f0103172 <printfmt>
f01033a9:	e9 bb fe ff ff       	jmp    f0103269 <vprintfmt+0xcf>
			else
				printfmt(putch, putdat, "%s", p);
f01033ae:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01033b2:	c7 44 24 08 64 4a 10 	movl   $0xf0104a64,0x8(%esp)
f01033b9:	f0 
f01033ba:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01033bd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01033c1:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01033c4:	89 1c 24             	mov    %ebx,(%esp)
f01033c7:	e8 a6 fd ff ff       	call   f0103172 <printfmt>
f01033cc:	e9 98 fe ff ff       	jmp    f0103269 <vprintfmt+0xcf>
f01033d1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01033d4:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01033d7:	89 5d d8             	mov    %ebx,-0x28(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01033da:	8b 45 14             	mov    0x14(%ebp),%eax
f01033dd:	8d 50 04             	lea    0x4(%eax),%edx
f01033e0:	89 55 14             	mov    %edx,0x14(%ebp)
f01033e3:	8b 18                	mov    (%eax),%ebx
				p = "(null)";
f01033e5:	85 db                	test   %ebx,%ebx
f01033e7:	b8 1a 4d 10 f0       	mov    $0xf0104d1a,%eax
f01033ec:	0f 44 d8             	cmove  %eax,%ebx
			if (width > 0 && padc != '-')
f01033ef:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01033f3:	7e 06                	jle    f01033fb <vprintfmt+0x261>
f01033f5:	80 7d e0 2d          	cmpb   $0x2d,-0x20(%ebp)
f01033f9:	75 10                	jne    f010340b <vprintfmt+0x271>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01033fb:	0f be 03             	movsbl (%ebx),%eax
f01033fe:	83 c3 01             	add    $0x1,%ebx
f0103401:	85 c0                	test   %eax,%eax
f0103403:	0f 85 82 00 00 00    	jne    f010348b <vprintfmt+0x2f1>
f0103409:	eb 75                	jmp    f0103480 <vprintfmt+0x2e6>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010340b:	89 74 24 04          	mov    %esi,0x4(%esp)
f010340f:	89 1c 24             	mov    %ebx,(%esp)
f0103412:	e8 84 03 00 00       	call   f010379b <strnlen>
f0103417:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010341a:	29 c2                	sub    %eax,%edx
f010341c:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010341f:	85 d2                	test   %edx,%edx
f0103421:	7e d8                	jle    f01033fb <vprintfmt+0x261>
					putch(padc, putdat);
f0103423:	0f be 45 e0          	movsbl -0x20(%ebp),%eax
f0103427:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010342a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010342d:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103431:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103434:	89 04 24             	mov    %eax,(%esp)
f0103437:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010343a:	83 6d dc 01          	subl   $0x1,-0x24(%ebp)
f010343e:	75 ea                	jne    f010342a <vprintfmt+0x290>
f0103440:	eb b9                	jmp    f01033fb <vprintfmt+0x261>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103442:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103446:	74 1b                	je     f0103463 <vprintfmt+0x2c9>
f0103448:	8d 50 e0             	lea    -0x20(%eax),%edx
f010344b:	83 fa 5e             	cmp    $0x5e,%edx
f010344e:	76 13                	jbe    f0103463 <vprintfmt+0x2c9>
					putch('?', putdat);
f0103450:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103453:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103457:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f010345e:	ff 55 08             	call   *0x8(%ebp)
f0103461:	eb 0d                	jmp    f0103470 <vprintfmt+0x2d6>
				else
					putch(ch, putdat);
f0103463:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103466:	89 54 24 04          	mov    %edx,0x4(%esp)
f010346a:	89 04 24             	mov    %eax,(%esp)
f010346d:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103470:	83 ef 01             	sub    $0x1,%edi
f0103473:	0f be 03             	movsbl (%ebx),%eax
f0103476:	83 c3 01             	add    $0x1,%ebx
f0103479:	85 c0                	test   %eax,%eax
f010347b:	75 14                	jne    f0103491 <vprintfmt+0x2f7>
f010347d:	89 7d dc             	mov    %edi,-0x24(%ebp)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103480:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103484:	7f 19                	jg     f010349f <vprintfmt+0x305>
f0103486:	e9 de fd ff ff       	jmp    f0103269 <vprintfmt+0xcf>
f010348b:	89 7d e0             	mov    %edi,-0x20(%ebp)
f010348e:	8b 7d dc             	mov    -0x24(%ebp),%edi
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103491:	85 f6                	test   %esi,%esi
f0103493:	78 ad                	js     f0103442 <vprintfmt+0x2a8>
f0103495:	83 ee 01             	sub    $0x1,%esi
f0103498:	79 a8                	jns    f0103442 <vprintfmt+0x2a8>
f010349a:	89 7d dc             	mov    %edi,-0x24(%ebp)
f010349d:	eb e1                	jmp    f0103480 <vprintfmt+0x2e6>
f010349f:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01034a2:	8b 7d 08             	mov    0x8(%ebp),%edi
f01034a5:	8b 75 0c             	mov    0xc(%ebp),%esi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01034a8:	89 74 24 04          	mov    %esi,0x4(%esp)
f01034ac:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01034b3:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01034b5:	83 eb 01             	sub    $0x1,%ebx
f01034b8:	75 ee                	jne    f01034a8 <vprintfmt+0x30e>
f01034ba:	e9 aa fd ff ff       	jmp    f0103269 <vprintfmt+0xcf>
f01034bf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01034c2:	83 f9 01             	cmp    $0x1,%ecx
f01034c5:	7e 10                	jle    f01034d7 <vprintfmt+0x33d>
		return va_arg(*ap, long long);
f01034c7:	8b 45 14             	mov    0x14(%ebp),%eax
f01034ca:	8d 50 08             	lea    0x8(%eax),%edx
f01034cd:	89 55 14             	mov    %edx,0x14(%ebp)
f01034d0:	8b 30                	mov    (%eax),%esi
f01034d2:	8b 78 04             	mov    0x4(%eax),%edi
f01034d5:	eb 26                	jmp    f01034fd <vprintfmt+0x363>
	else if (lflag)
f01034d7:	85 c9                	test   %ecx,%ecx
f01034d9:	74 12                	je     f01034ed <vprintfmt+0x353>
		return va_arg(*ap, long);
f01034db:	8b 45 14             	mov    0x14(%ebp),%eax
f01034de:	8d 50 04             	lea    0x4(%eax),%edx
f01034e1:	89 55 14             	mov    %edx,0x14(%ebp)
f01034e4:	8b 30                	mov    (%eax),%esi
f01034e6:	89 f7                	mov    %esi,%edi
f01034e8:	c1 ff 1f             	sar    $0x1f,%edi
f01034eb:	eb 10                	jmp    f01034fd <vprintfmt+0x363>
	else
		return va_arg(*ap, int);
f01034ed:	8b 45 14             	mov    0x14(%ebp),%eax
f01034f0:	8d 50 04             	lea    0x4(%eax),%edx
f01034f3:	89 55 14             	mov    %edx,0x14(%ebp)
f01034f6:	8b 30                	mov    (%eax),%esi
f01034f8:	89 f7                	mov    %esi,%edi
f01034fa:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01034fd:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103502:	85 ff                	test   %edi,%edi
f0103504:	0f 89 9e 00 00 00    	jns    f01035a8 <vprintfmt+0x40e>
				putch('-', putdat);
f010350a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010350d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103511:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0103518:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010351b:	f7 de                	neg    %esi
f010351d:	83 d7 00             	adc    $0x0,%edi
f0103520:	f7 df                	neg    %edi
			}
			base = 10;
f0103522:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103527:	eb 7f                	jmp    f01035a8 <vprintfmt+0x40e>
f0103529:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f010352c:	89 ca                	mov    %ecx,%edx
f010352e:	8d 45 14             	lea    0x14(%ebp),%eax
f0103531:	e8 e5 fb ff ff       	call   f010311b <getuint>
f0103536:	89 c6                	mov    %eax,%esi
f0103538:	89 d7                	mov    %edx,%edi
			base = 10;
f010353a:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f010353f:	eb 67                	jmp    f01035a8 <vprintfmt+0x40e>
f0103541:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap,lflag);
f0103544:	89 ca                	mov    %ecx,%edx
f0103546:	8d 45 14             	lea    0x14(%ebp),%eax
f0103549:	e8 cd fb ff ff       	call   f010311b <getuint>
f010354e:	89 c6                	mov    %eax,%esi
f0103550:	89 d7                	mov    %edx,%edi
			base = 8;
f0103552:	b8 08 00 00 00       	mov    $0x8,%eax

			goto number;
f0103557:	eb 4f                	jmp    f01035a8 <vprintfmt+0x40e>
f0103559:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// pointer
		case 'p':
			putch('0', putdat);
f010355c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010355f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103563:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010356a:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f010356d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103571:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0103578:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010357b:	8b 45 14             	mov    0x14(%ebp),%eax
f010357e:	8d 50 04             	lea    0x4(%eax),%edx
f0103581:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103584:	8b 30                	mov    (%eax),%esi
f0103586:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010358b:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0103590:	eb 16                	jmp    f01035a8 <vprintfmt+0x40e>
f0103592:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103595:	89 ca                	mov    %ecx,%edx
f0103597:	8d 45 14             	lea    0x14(%ebp),%eax
f010359a:	e8 7c fb ff ff       	call   f010311b <getuint>
f010359f:	89 c6                	mov    %eax,%esi
f01035a1:	89 d7                	mov    %edx,%edi
			base = 16;
f01035a3:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f01035a8:	0f be 55 e0          	movsbl -0x20(%ebp),%edx
f01035ac:	89 54 24 10          	mov    %edx,0x10(%esp)
f01035b0:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01035b3:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01035b7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01035bb:	89 34 24             	mov    %esi,(%esp)
f01035be:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01035c2:	8b 55 0c             	mov    0xc(%ebp),%edx
f01035c5:	8b 45 08             	mov    0x8(%ebp),%eax
f01035c8:	e8 73 fa ff ff       	call   f0103040 <printnum>
			break;
f01035cd:	e9 97 fc ff ff       	jmp    f0103269 <vprintfmt+0xcf>
f01035d2:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01035d5:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01035d8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01035db:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01035df:	89 14 24             	mov    %edx,(%esp)
f01035e2:	ff 55 08             	call   *0x8(%ebp)
			break;
f01035e5:	e9 7f fc ff ff       	jmp    f0103269 <vprintfmt+0xcf>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01035ea:	8b 45 0c             	mov    0xc(%ebp),%eax
f01035ed:	89 44 24 04          	mov    %eax,0x4(%esp)
f01035f1:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01035f8:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01035fb:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f01035fe:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0103602:	0f 84 61 fc ff ff    	je     f0103269 <vprintfmt+0xcf>
f0103608:	83 eb 01             	sub    $0x1,%ebx
f010360b:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f010360f:	75 f7                	jne    f0103608 <vprintfmt+0x46e>
f0103611:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103614:	e9 50 fc ff ff       	jmp    f0103269 <vprintfmt+0xcf>
				/* do nothing */;
			break;
		}
	}
}
f0103619:	83 c4 3c             	add    $0x3c,%esp
f010361c:	5b                   	pop    %ebx
f010361d:	5e                   	pop    %esi
f010361e:	5f                   	pop    %edi
f010361f:	5d                   	pop    %ebp
f0103620:	c3                   	ret    

f0103621 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103621:	55                   	push   %ebp
f0103622:	89 e5                	mov    %esp,%ebp
f0103624:	83 ec 28             	sub    $0x28,%esp
f0103627:	8b 45 08             	mov    0x8(%ebp),%eax
f010362a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010362d:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103630:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103634:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103637:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010363e:	85 c0                	test   %eax,%eax
f0103640:	74 30                	je     f0103672 <vsnprintf+0x51>
f0103642:	85 d2                	test   %edx,%edx
f0103644:	7e 2c                	jle    f0103672 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103646:	8b 45 14             	mov    0x14(%ebp),%eax
f0103649:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010364d:	8b 45 10             	mov    0x10(%ebp),%eax
f0103650:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103654:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103657:	89 44 24 04          	mov    %eax,0x4(%esp)
f010365b:	c7 04 24 55 31 10 f0 	movl   $0xf0103155,(%esp)
f0103662:	e8 33 fb ff ff       	call   f010319a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103667:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010366a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010366d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103670:	eb 05                	jmp    f0103677 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103672:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103677:	c9                   	leave  
f0103678:	c3                   	ret    

f0103679 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103679:	55                   	push   %ebp
f010367a:	89 e5                	mov    %esp,%ebp
f010367c:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010367f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103682:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103686:	8b 45 10             	mov    0x10(%ebp),%eax
f0103689:	89 44 24 08          	mov    %eax,0x8(%esp)
f010368d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103690:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103694:	8b 45 08             	mov    0x8(%ebp),%eax
f0103697:	89 04 24             	mov    %eax,(%esp)
f010369a:	e8 82 ff ff ff       	call   f0103621 <vsnprintf>
	va_end(ap);

	return rc;
}
f010369f:	c9                   	leave  
f01036a0:	c3                   	ret    
	...

f01036b0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01036b0:	55                   	push   %ebp
f01036b1:	89 e5                	mov    %esp,%ebp
f01036b3:	57                   	push   %edi
f01036b4:	56                   	push   %esi
f01036b5:	53                   	push   %ebx
f01036b6:	83 ec 1c             	sub    $0x1c,%esp
f01036b9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01036bc:	85 c0                	test   %eax,%eax
f01036be:	74 10                	je     f01036d0 <readline+0x20>
		cprintf("%s", prompt);
f01036c0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036c4:	c7 04 24 64 4a 10 f0 	movl   $0xf0104a64,(%esp)
f01036cb:	e8 66 f6 ff ff       	call   f0102d36 <cprintf>

	i = 0;
	echoing = iscons(0);
f01036d0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01036d7:	e8 36 cf ff ff       	call   f0100612 <iscons>
f01036dc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01036de:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01036e3:	e8 19 cf ff ff       	call   f0100601 <getchar>
f01036e8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01036ea:	85 c0                	test   %eax,%eax
f01036ec:	79 17                	jns    f0103705 <readline+0x55>
			cprintf("read error: %e\n", c);
f01036ee:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036f2:	c7 04 24 08 4f 10 f0 	movl   $0xf0104f08,(%esp)
f01036f9:	e8 38 f6 ff ff       	call   f0102d36 <cprintf>
			return NULL;
f01036fe:	b8 00 00 00 00       	mov    $0x0,%eax
f0103703:	eb 6d                	jmp    f0103772 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103705:	83 f8 08             	cmp    $0x8,%eax
f0103708:	74 05                	je     f010370f <readline+0x5f>
f010370a:	83 f8 7f             	cmp    $0x7f,%eax
f010370d:	75 19                	jne    f0103728 <readline+0x78>
f010370f:	85 f6                	test   %esi,%esi
f0103711:	7e 15                	jle    f0103728 <readline+0x78>
			if (echoing)
f0103713:	85 ff                	test   %edi,%edi
f0103715:	74 0c                	je     f0103723 <readline+0x73>
				cputchar('\b');
f0103717:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010371e:	e8 ce ce ff ff       	call   f01005f1 <cputchar>
			i--;
f0103723:	83 ee 01             	sub    $0x1,%esi
f0103726:	eb bb                	jmp    f01036e3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103728:	83 fb 1f             	cmp    $0x1f,%ebx
f010372b:	7e 1f                	jle    f010374c <readline+0x9c>
f010372d:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103733:	7f 17                	jg     f010374c <readline+0x9c>
			if (echoing)
f0103735:	85 ff                	test   %edi,%edi
f0103737:	74 08                	je     f0103741 <readline+0x91>
				cputchar(c);
f0103739:	89 1c 24             	mov    %ebx,(%esp)
f010373c:	e8 b0 ce ff ff       	call   f01005f1 <cputchar>
			buf[i++] = c;
f0103741:	88 9e a0 75 11 f0    	mov    %bl,-0xfee8a60(%esi)
f0103747:	83 c6 01             	add    $0x1,%esi
f010374a:	eb 97                	jmp    f01036e3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010374c:	83 fb 0a             	cmp    $0xa,%ebx
f010374f:	74 05                	je     f0103756 <readline+0xa6>
f0103751:	83 fb 0d             	cmp    $0xd,%ebx
f0103754:	75 8d                	jne    f01036e3 <readline+0x33>
			if (echoing)
f0103756:	85 ff                	test   %edi,%edi
f0103758:	74 0c                	je     f0103766 <readline+0xb6>
				cputchar('\n');
f010375a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0103761:	e8 8b ce ff ff       	call   f01005f1 <cputchar>
			buf[i] = 0;
f0103766:	c6 86 a0 75 11 f0 00 	movb   $0x0,-0xfee8a60(%esi)
			return buf;
f010376d:	b8 a0 75 11 f0       	mov    $0xf01175a0,%eax
		}
	}
}
f0103772:	83 c4 1c             	add    $0x1c,%esp
f0103775:	5b                   	pop    %ebx
f0103776:	5e                   	pop    %esi
f0103777:	5f                   	pop    %edi
f0103778:	5d                   	pop    %ebp
f0103779:	c3                   	ret    
f010377a:	00 00                	add    %al,(%eax)
f010377c:	00 00                	add    %al,(%eax)
	...

f0103780 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103780:	55                   	push   %ebp
f0103781:	89 e5                	mov    %esp,%ebp
f0103783:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103786:	b8 00 00 00 00       	mov    $0x0,%eax
f010378b:	80 3a 00             	cmpb   $0x0,(%edx)
f010378e:	74 09                	je     f0103799 <strlen+0x19>
		n++;
f0103790:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103793:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103797:	75 f7                	jne    f0103790 <strlen+0x10>
		n++;
	return n;
}
f0103799:	5d                   	pop    %ebp
f010379a:	c3                   	ret    

f010379b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010379b:	55                   	push   %ebp
f010379c:	89 e5                	mov    %esp,%ebp
f010379e:	53                   	push   %ebx
f010379f:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01037a2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01037a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01037aa:	85 c9                	test   %ecx,%ecx
f01037ac:	74 1a                	je     f01037c8 <strnlen+0x2d>
f01037ae:	80 3b 00             	cmpb   $0x0,(%ebx)
f01037b1:	74 15                	je     f01037c8 <strnlen+0x2d>
f01037b3:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f01037b8:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01037ba:	39 ca                	cmp    %ecx,%edx
f01037bc:	74 0a                	je     f01037c8 <strnlen+0x2d>
f01037be:	83 c2 01             	add    $0x1,%edx
f01037c1:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f01037c6:	75 f0                	jne    f01037b8 <strnlen+0x1d>
		n++;
	return n;
}
f01037c8:	5b                   	pop    %ebx
f01037c9:	5d                   	pop    %ebp
f01037ca:	c3                   	ret    

f01037cb <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01037cb:	55                   	push   %ebp
f01037cc:	89 e5                	mov    %esp,%ebp
f01037ce:	53                   	push   %ebx
f01037cf:	8b 45 08             	mov    0x8(%ebp),%eax
f01037d2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01037d5:	ba 00 00 00 00       	mov    $0x0,%edx
f01037da:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01037de:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f01037e1:	83 c2 01             	add    $0x1,%edx
f01037e4:	84 c9                	test   %cl,%cl
f01037e6:	75 f2                	jne    f01037da <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f01037e8:	5b                   	pop    %ebx
f01037e9:	5d                   	pop    %ebp
f01037ea:	c3                   	ret    

f01037eb <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01037eb:	55                   	push   %ebp
f01037ec:	89 e5                	mov    %esp,%ebp
f01037ee:	56                   	push   %esi
f01037ef:	53                   	push   %ebx
f01037f0:	8b 45 08             	mov    0x8(%ebp),%eax
f01037f3:	8b 55 0c             	mov    0xc(%ebp),%edx
f01037f6:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01037f9:	85 f6                	test   %esi,%esi
f01037fb:	74 18                	je     f0103815 <strncpy+0x2a>
f01037fd:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f0103802:	0f b6 1a             	movzbl (%edx),%ebx
f0103805:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103808:	80 3a 01             	cmpb   $0x1,(%edx)
f010380b:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010380e:	83 c1 01             	add    $0x1,%ecx
f0103811:	39 f1                	cmp    %esi,%ecx
f0103813:	75 ed                	jne    f0103802 <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103815:	5b                   	pop    %ebx
f0103816:	5e                   	pop    %esi
f0103817:	5d                   	pop    %ebp
f0103818:	c3                   	ret    

f0103819 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103819:	55                   	push   %ebp
f010381a:	89 e5                	mov    %esp,%ebp
f010381c:	57                   	push   %edi
f010381d:	56                   	push   %esi
f010381e:	53                   	push   %ebx
f010381f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103822:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103825:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103828:	89 f8                	mov    %edi,%eax
f010382a:	85 f6                	test   %esi,%esi
f010382c:	74 2b                	je     f0103859 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f010382e:	83 fe 01             	cmp    $0x1,%esi
f0103831:	74 23                	je     f0103856 <strlcpy+0x3d>
f0103833:	0f b6 0b             	movzbl (%ebx),%ecx
f0103836:	84 c9                	test   %cl,%cl
f0103838:	74 1c                	je     f0103856 <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f010383a:	83 ee 02             	sub    $0x2,%esi
f010383d:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103842:	88 08                	mov    %cl,(%eax)
f0103844:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103847:	39 f2                	cmp    %esi,%edx
f0103849:	74 0b                	je     f0103856 <strlcpy+0x3d>
f010384b:	83 c2 01             	add    $0x1,%edx
f010384e:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0103852:	84 c9                	test   %cl,%cl
f0103854:	75 ec                	jne    f0103842 <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f0103856:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103859:	29 f8                	sub    %edi,%eax
}
f010385b:	5b                   	pop    %ebx
f010385c:	5e                   	pop    %esi
f010385d:	5f                   	pop    %edi
f010385e:	5d                   	pop    %ebp
f010385f:	c3                   	ret    

f0103860 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103860:	55                   	push   %ebp
f0103861:	89 e5                	mov    %esp,%ebp
f0103863:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103866:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103869:	0f b6 01             	movzbl (%ecx),%eax
f010386c:	84 c0                	test   %al,%al
f010386e:	74 16                	je     f0103886 <strcmp+0x26>
f0103870:	3a 02                	cmp    (%edx),%al
f0103872:	75 12                	jne    f0103886 <strcmp+0x26>
		p++, q++;
f0103874:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103877:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f010387b:	84 c0                	test   %al,%al
f010387d:	74 07                	je     f0103886 <strcmp+0x26>
f010387f:	83 c1 01             	add    $0x1,%ecx
f0103882:	3a 02                	cmp    (%edx),%al
f0103884:	74 ee                	je     f0103874 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103886:	0f b6 c0             	movzbl %al,%eax
f0103889:	0f b6 12             	movzbl (%edx),%edx
f010388c:	29 d0                	sub    %edx,%eax
}
f010388e:	5d                   	pop    %ebp
f010388f:	c3                   	ret    

f0103890 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103890:	55                   	push   %ebp
f0103891:	89 e5                	mov    %esp,%ebp
f0103893:	53                   	push   %ebx
f0103894:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103897:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010389a:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010389d:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01038a2:	85 d2                	test   %edx,%edx
f01038a4:	74 28                	je     f01038ce <strncmp+0x3e>
f01038a6:	0f b6 01             	movzbl (%ecx),%eax
f01038a9:	84 c0                	test   %al,%al
f01038ab:	74 24                	je     f01038d1 <strncmp+0x41>
f01038ad:	3a 03                	cmp    (%ebx),%al
f01038af:	75 20                	jne    f01038d1 <strncmp+0x41>
f01038b1:	83 ea 01             	sub    $0x1,%edx
f01038b4:	74 13                	je     f01038c9 <strncmp+0x39>
		n--, p++, q++;
f01038b6:	83 c1 01             	add    $0x1,%ecx
f01038b9:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01038bc:	0f b6 01             	movzbl (%ecx),%eax
f01038bf:	84 c0                	test   %al,%al
f01038c1:	74 0e                	je     f01038d1 <strncmp+0x41>
f01038c3:	3a 03                	cmp    (%ebx),%al
f01038c5:	74 ea                	je     f01038b1 <strncmp+0x21>
f01038c7:	eb 08                	jmp    f01038d1 <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f01038c9:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01038ce:	5b                   	pop    %ebx
f01038cf:	5d                   	pop    %ebp
f01038d0:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01038d1:	0f b6 01             	movzbl (%ecx),%eax
f01038d4:	0f b6 13             	movzbl (%ebx),%edx
f01038d7:	29 d0                	sub    %edx,%eax
f01038d9:	eb f3                	jmp    f01038ce <strncmp+0x3e>

f01038db <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01038db:	55                   	push   %ebp
f01038dc:	89 e5                	mov    %esp,%ebp
f01038de:	8b 45 08             	mov    0x8(%ebp),%eax
f01038e1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01038e5:	0f b6 10             	movzbl (%eax),%edx
f01038e8:	84 d2                	test   %dl,%dl
f01038ea:	74 1c                	je     f0103908 <strchr+0x2d>
		if (*s == c)
f01038ec:	38 ca                	cmp    %cl,%dl
f01038ee:	75 09                	jne    f01038f9 <strchr+0x1e>
f01038f0:	eb 1b                	jmp    f010390d <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01038f2:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f01038f5:	38 ca                	cmp    %cl,%dl
f01038f7:	74 14                	je     f010390d <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01038f9:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f01038fd:	84 d2                	test   %dl,%dl
f01038ff:	75 f1                	jne    f01038f2 <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f0103901:	b8 00 00 00 00       	mov    $0x0,%eax
f0103906:	eb 05                	jmp    f010390d <strchr+0x32>
f0103908:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010390d:	5d                   	pop    %ebp
f010390e:	c3                   	ret    

f010390f <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010390f:	55                   	push   %ebp
f0103910:	89 e5                	mov    %esp,%ebp
f0103912:	8b 45 08             	mov    0x8(%ebp),%eax
f0103915:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103919:	0f b6 10             	movzbl (%eax),%edx
f010391c:	84 d2                	test   %dl,%dl
f010391e:	74 14                	je     f0103934 <strfind+0x25>
		if (*s == c)
f0103920:	38 ca                	cmp    %cl,%dl
f0103922:	75 06                	jne    f010392a <strfind+0x1b>
f0103924:	eb 0e                	jmp    f0103934 <strfind+0x25>
f0103926:	38 ca                	cmp    %cl,%dl
f0103928:	74 0a                	je     f0103934 <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010392a:	83 c0 01             	add    $0x1,%eax
f010392d:	0f b6 10             	movzbl (%eax),%edx
f0103930:	84 d2                	test   %dl,%dl
f0103932:	75 f2                	jne    f0103926 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f0103934:	5d                   	pop    %ebp
f0103935:	c3                   	ret    

f0103936 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103936:	55                   	push   %ebp
f0103937:	89 e5                	mov    %esp,%ebp
f0103939:	83 ec 0c             	sub    $0xc,%esp
f010393c:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010393f:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0103942:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0103945:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103948:	8b 45 0c             	mov    0xc(%ebp),%eax
f010394b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010394e:	85 c9                	test   %ecx,%ecx
f0103950:	74 30                	je     f0103982 <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103952:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103958:	75 25                	jne    f010397f <memset+0x49>
f010395a:	f6 c1 03             	test   $0x3,%cl
f010395d:	75 20                	jne    f010397f <memset+0x49>
		c &= 0xFF;
f010395f:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103962:	89 d3                	mov    %edx,%ebx
f0103964:	c1 e3 08             	shl    $0x8,%ebx
f0103967:	89 d6                	mov    %edx,%esi
f0103969:	c1 e6 18             	shl    $0x18,%esi
f010396c:	89 d0                	mov    %edx,%eax
f010396e:	c1 e0 10             	shl    $0x10,%eax
f0103971:	09 f0                	or     %esi,%eax
f0103973:	09 d0                	or     %edx,%eax
f0103975:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0103977:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f010397a:	fc                   	cld    
f010397b:	f3 ab                	rep stos %eax,%es:(%edi)
f010397d:	eb 03                	jmp    f0103982 <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010397f:	fc                   	cld    
f0103980:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103982:	89 f8                	mov    %edi,%eax
f0103984:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0103987:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010398a:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010398d:	89 ec                	mov    %ebp,%esp
f010398f:	5d                   	pop    %ebp
f0103990:	c3                   	ret    

f0103991 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103991:	55                   	push   %ebp
f0103992:	89 e5                	mov    %esp,%ebp
f0103994:	83 ec 08             	sub    $0x8,%esp
f0103997:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010399a:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010399d:	8b 45 08             	mov    0x8(%ebp),%eax
f01039a0:	8b 75 0c             	mov    0xc(%ebp),%esi
f01039a3:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01039a6:	39 c6                	cmp    %eax,%esi
f01039a8:	73 36                	jae    f01039e0 <memmove+0x4f>
f01039aa:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01039ad:	39 d0                	cmp    %edx,%eax
f01039af:	73 2f                	jae    f01039e0 <memmove+0x4f>
		s += n;
		d += n;
f01039b1:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01039b4:	f6 c2 03             	test   $0x3,%dl
f01039b7:	75 1b                	jne    f01039d4 <memmove+0x43>
f01039b9:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01039bf:	75 13                	jne    f01039d4 <memmove+0x43>
f01039c1:	f6 c1 03             	test   $0x3,%cl
f01039c4:	75 0e                	jne    f01039d4 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01039c6:	83 ef 04             	sub    $0x4,%edi
f01039c9:	8d 72 fc             	lea    -0x4(%edx),%esi
f01039cc:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01039cf:	fd                   	std    
f01039d0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01039d2:	eb 09                	jmp    f01039dd <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01039d4:	83 ef 01             	sub    $0x1,%edi
f01039d7:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01039da:	fd                   	std    
f01039db:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01039dd:	fc                   	cld    
f01039de:	eb 20                	jmp    f0103a00 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01039e0:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01039e6:	75 13                	jne    f01039fb <memmove+0x6a>
f01039e8:	a8 03                	test   $0x3,%al
f01039ea:	75 0f                	jne    f01039fb <memmove+0x6a>
f01039ec:	f6 c1 03             	test   $0x3,%cl
f01039ef:	75 0a                	jne    f01039fb <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01039f1:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01039f4:	89 c7                	mov    %eax,%edi
f01039f6:	fc                   	cld    
f01039f7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01039f9:	eb 05                	jmp    f0103a00 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01039fb:	89 c7                	mov    %eax,%edi
f01039fd:	fc                   	cld    
f01039fe:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103a00:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0103a03:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0103a06:	89 ec                	mov    %ebp,%esp
f0103a08:	5d                   	pop    %ebp
f0103a09:	c3                   	ret    

f0103a0a <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0103a0a:	55                   	push   %ebp
f0103a0b:	89 e5                	mov    %esp,%ebp
f0103a0d:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0103a10:	8b 45 10             	mov    0x10(%ebp),%eax
f0103a13:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103a17:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103a1a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a1e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a21:	89 04 24             	mov    %eax,(%esp)
f0103a24:	e8 68 ff ff ff       	call   f0103991 <memmove>
}
f0103a29:	c9                   	leave  
f0103a2a:	c3                   	ret    

f0103a2b <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103a2b:	55                   	push   %ebp
f0103a2c:	89 e5                	mov    %esp,%ebp
f0103a2e:	57                   	push   %edi
f0103a2f:	56                   	push   %esi
f0103a30:	53                   	push   %ebx
f0103a31:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103a34:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103a37:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103a3a:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103a3f:	85 ff                	test   %edi,%edi
f0103a41:	74 37                	je     f0103a7a <memcmp+0x4f>
		if (*s1 != *s2)
f0103a43:	0f b6 03             	movzbl (%ebx),%eax
f0103a46:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103a49:	83 ef 01             	sub    $0x1,%edi
f0103a4c:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f0103a51:	38 c8                	cmp    %cl,%al
f0103a53:	74 1c                	je     f0103a71 <memcmp+0x46>
f0103a55:	eb 10                	jmp    f0103a67 <memcmp+0x3c>
f0103a57:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0103a5c:	83 c2 01             	add    $0x1,%edx
f0103a5f:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0103a63:	38 c8                	cmp    %cl,%al
f0103a65:	74 0a                	je     f0103a71 <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f0103a67:	0f b6 c0             	movzbl %al,%eax
f0103a6a:	0f b6 c9             	movzbl %cl,%ecx
f0103a6d:	29 c8                	sub    %ecx,%eax
f0103a6f:	eb 09                	jmp    f0103a7a <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103a71:	39 fa                	cmp    %edi,%edx
f0103a73:	75 e2                	jne    f0103a57 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103a75:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103a7a:	5b                   	pop    %ebx
f0103a7b:	5e                   	pop    %esi
f0103a7c:	5f                   	pop    %edi
f0103a7d:	5d                   	pop    %ebp
f0103a7e:	c3                   	ret    

f0103a7f <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103a7f:	55                   	push   %ebp
f0103a80:	89 e5                	mov    %esp,%ebp
f0103a82:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103a85:	89 c2                	mov    %eax,%edx
f0103a87:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103a8a:	39 d0                	cmp    %edx,%eax
f0103a8c:	73 15                	jae    f0103aa3 <memfind+0x24>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103a8e:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f0103a92:	38 08                	cmp    %cl,(%eax)
f0103a94:	75 06                	jne    f0103a9c <memfind+0x1d>
f0103a96:	eb 0b                	jmp    f0103aa3 <memfind+0x24>
f0103a98:	38 08                	cmp    %cl,(%eax)
f0103a9a:	74 07                	je     f0103aa3 <memfind+0x24>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103a9c:	83 c0 01             	add    $0x1,%eax
f0103a9f:	39 d0                	cmp    %edx,%eax
f0103aa1:	75 f5                	jne    f0103a98 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103aa3:	5d                   	pop    %ebp
f0103aa4:	c3                   	ret    

f0103aa5 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103aa5:	55                   	push   %ebp
f0103aa6:	89 e5                	mov    %esp,%ebp
f0103aa8:	57                   	push   %edi
f0103aa9:	56                   	push   %esi
f0103aaa:	53                   	push   %ebx
f0103aab:	8b 55 08             	mov    0x8(%ebp),%edx
f0103aae:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103ab1:	0f b6 02             	movzbl (%edx),%eax
f0103ab4:	3c 20                	cmp    $0x20,%al
f0103ab6:	74 04                	je     f0103abc <strtol+0x17>
f0103ab8:	3c 09                	cmp    $0x9,%al
f0103aba:	75 0e                	jne    f0103aca <strtol+0x25>
		s++;
f0103abc:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103abf:	0f b6 02             	movzbl (%edx),%eax
f0103ac2:	3c 20                	cmp    $0x20,%al
f0103ac4:	74 f6                	je     f0103abc <strtol+0x17>
f0103ac6:	3c 09                	cmp    $0x9,%al
f0103ac8:	74 f2                	je     f0103abc <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103aca:	3c 2b                	cmp    $0x2b,%al
f0103acc:	75 0a                	jne    f0103ad8 <strtol+0x33>
		s++;
f0103ace:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103ad1:	bf 00 00 00 00       	mov    $0x0,%edi
f0103ad6:	eb 10                	jmp    f0103ae8 <strtol+0x43>
f0103ad8:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103add:	3c 2d                	cmp    $0x2d,%al
f0103adf:	75 07                	jne    f0103ae8 <strtol+0x43>
		s++, neg = 1;
f0103ae1:	83 c2 01             	add    $0x1,%edx
f0103ae4:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103ae8:	85 db                	test   %ebx,%ebx
f0103aea:	0f 94 c0             	sete   %al
f0103aed:	74 05                	je     f0103af4 <strtol+0x4f>
f0103aef:	83 fb 10             	cmp    $0x10,%ebx
f0103af2:	75 15                	jne    f0103b09 <strtol+0x64>
f0103af4:	80 3a 30             	cmpb   $0x30,(%edx)
f0103af7:	75 10                	jne    f0103b09 <strtol+0x64>
f0103af9:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0103afd:	75 0a                	jne    f0103b09 <strtol+0x64>
		s += 2, base = 16;
f0103aff:	83 c2 02             	add    $0x2,%edx
f0103b02:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103b07:	eb 13                	jmp    f0103b1c <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f0103b09:	84 c0                	test   %al,%al
f0103b0b:	74 0f                	je     f0103b1c <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103b0d:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103b12:	80 3a 30             	cmpb   $0x30,(%edx)
f0103b15:	75 05                	jne    f0103b1c <strtol+0x77>
		s++, base = 8;
f0103b17:	83 c2 01             	add    $0x1,%edx
f0103b1a:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f0103b1c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b21:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103b23:	0f b6 0a             	movzbl (%edx),%ecx
f0103b26:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0103b29:	80 fb 09             	cmp    $0x9,%bl
f0103b2c:	77 08                	ja     f0103b36 <strtol+0x91>
			dig = *s - '0';
f0103b2e:	0f be c9             	movsbl %cl,%ecx
f0103b31:	83 e9 30             	sub    $0x30,%ecx
f0103b34:	eb 1e                	jmp    f0103b54 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f0103b36:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f0103b39:	80 fb 19             	cmp    $0x19,%bl
f0103b3c:	77 08                	ja     f0103b46 <strtol+0xa1>
			dig = *s - 'a' + 10;
f0103b3e:	0f be c9             	movsbl %cl,%ecx
f0103b41:	83 e9 57             	sub    $0x57,%ecx
f0103b44:	eb 0e                	jmp    f0103b54 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f0103b46:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0103b49:	80 fb 19             	cmp    $0x19,%bl
f0103b4c:	77 14                	ja     f0103b62 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103b4e:	0f be c9             	movsbl %cl,%ecx
f0103b51:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0103b54:	39 f1                	cmp    %esi,%ecx
f0103b56:	7d 0e                	jge    f0103b66 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f0103b58:	83 c2 01             	add    $0x1,%edx
f0103b5b:	0f af c6             	imul   %esi,%eax
f0103b5e:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0103b60:	eb c1                	jmp    f0103b23 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0103b62:	89 c1                	mov    %eax,%ecx
f0103b64:	eb 02                	jmp    f0103b68 <strtol+0xc3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0103b66:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0103b68:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103b6c:	74 05                	je     f0103b73 <strtol+0xce>
		*endptr = (char *) s;
f0103b6e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103b71:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0103b73:	89 ca                	mov    %ecx,%edx
f0103b75:	f7 da                	neg    %edx
f0103b77:	85 ff                	test   %edi,%edi
f0103b79:	0f 45 c2             	cmovne %edx,%eax
}
f0103b7c:	5b                   	pop    %ebx
f0103b7d:	5e                   	pop    %esi
f0103b7e:	5f                   	pop    %edi
f0103b7f:	5d                   	pop    %ebp
f0103b80:	c3                   	ret    
	...

f0103b90 <__udivdi3>:
f0103b90:	83 ec 1c             	sub    $0x1c,%esp
f0103b93:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0103b97:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f0103b9b:	8b 44 24 20          	mov    0x20(%esp),%eax
f0103b9f:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0103ba3:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103ba7:	8b 74 24 24          	mov    0x24(%esp),%esi
f0103bab:	85 ff                	test   %edi,%edi
f0103bad:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0103bb1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103bb5:	89 cd                	mov    %ecx,%ebp
f0103bb7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103bbb:	75 33                	jne    f0103bf0 <__udivdi3+0x60>
f0103bbd:	39 f1                	cmp    %esi,%ecx
f0103bbf:	77 57                	ja     f0103c18 <__udivdi3+0x88>
f0103bc1:	85 c9                	test   %ecx,%ecx
f0103bc3:	75 0b                	jne    f0103bd0 <__udivdi3+0x40>
f0103bc5:	b8 01 00 00 00       	mov    $0x1,%eax
f0103bca:	31 d2                	xor    %edx,%edx
f0103bcc:	f7 f1                	div    %ecx
f0103bce:	89 c1                	mov    %eax,%ecx
f0103bd0:	89 f0                	mov    %esi,%eax
f0103bd2:	31 d2                	xor    %edx,%edx
f0103bd4:	f7 f1                	div    %ecx
f0103bd6:	89 c6                	mov    %eax,%esi
f0103bd8:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103bdc:	f7 f1                	div    %ecx
f0103bde:	89 f2                	mov    %esi,%edx
f0103be0:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103be4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103be8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103bec:	83 c4 1c             	add    $0x1c,%esp
f0103bef:	c3                   	ret    
f0103bf0:	31 d2                	xor    %edx,%edx
f0103bf2:	31 c0                	xor    %eax,%eax
f0103bf4:	39 f7                	cmp    %esi,%edi
f0103bf6:	77 e8                	ja     f0103be0 <__udivdi3+0x50>
f0103bf8:	0f bd cf             	bsr    %edi,%ecx
f0103bfb:	83 f1 1f             	xor    $0x1f,%ecx
f0103bfe:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103c02:	75 2c                	jne    f0103c30 <__udivdi3+0xa0>
f0103c04:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0103c08:	76 04                	jbe    f0103c0e <__udivdi3+0x7e>
f0103c0a:	39 f7                	cmp    %esi,%edi
f0103c0c:	73 d2                	jae    f0103be0 <__udivdi3+0x50>
f0103c0e:	31 d2                	xor    %edx,%edx
f0103c10:	b8 01 00 00 00       	mov    $0x1,%eax
f0103c15:	eb c9                	jmp    f0103be0 <__udivdi3+0x50>
f0103c17:	90                   	nop
f0103c18:	89 f2                	mov    %esi,%edx
f0103c1a:	f7 f1                	div    %ecx
f0103c1c:	31 d2                	xor    %edx,%edx
f0103c1e:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103c22:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103c26:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103c2a:	83 c4 1c             	add    $0x1c,%esp
f0103c2d:	c3                   	ret    
f0103c2e:	66 90                	xchg   %ax,%ax
f0103c30:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103c35:	b8 20 00 00 00       	mov    $0x20,%eax
f0103c3a:	89 ea                	mov    %ebp,%edx
f0103c3c:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103c40:	d3 e7                	shl    %cl,%edi
f0103c42:	89 c1                	mov    %eax,%ecx
f0103c44:	d3 ea                	shr    %cl,%edx
f0103c46:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103c4b:	09 fa                	or     %edi,%edx
f0103c4d:	89 f7                	mov    %esi,%edi
f0103c4f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103c53:	89 f2                	mov    %esi,%edx
f0103c55:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103c59:	d3 e5                	shl    %cl,%ebp
f0103c5b:	89 c1                	mov    %eax,%ecx
f0103c5d:	d3 ef                	shr    %cl,%edi
f0103c5f:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103c64:	d3 e2                	shl    %cl,%edx
f0103c66:	89 c1                	mov    %eax,%ecx
f0103c68:	d3 ee                	shr    %cl,%esi
f0103c6a:	09 d6                	or     %edx,%esi
f0103c6c:	89 fa                	mov    %edi,%edx
f0103c6e:	89 f0                	mov    %esi,%eax
f0103c70:	f7 74 24 0c          	divl   0xc(%esp)
f0103c74:	89 d7                	mov    %edx,%edi
f0103c76:	89 c6                	mov    %eax,%esi
f0103c78:	f7 e5                	mul    %ebp
f0103c7a:	39 d7                	cmp    %edx,%edi
f0103c7c:	72 22                	jb     f0103ca0 <__udivdi3+0x110>
f0103c7e:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0103c82:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103c87:	d3 e5                	shl    %cl,%ebp
f0103c89:	39 c5                	cmp    %eax,%ebp
f0103c8b:	73 04                	jae    f0103c91 <__udivdi3+0x101>
f0103c8d:	39 d7                	cmp    %edx,%edi
f0103c8f:	74 0f                	je     f0103ca0 <__udivdi3+0x110>
f0103c91:	89 f0                	mov    %esi,%eax
f0103c93:	31 d2                	xor    %edx,%edx
f0103c95:	e9 46 ff ff ff       	jmp    f0103be0 <__udivdi3+0x50>
f0103c9a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103ca0:	8d 46 ff             	lea    -0x1(%esi),%eax
f0103ca3:	31 d2                	xor    %edx,%edx
f0103ca5:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103ca9:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103cad:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103cb1:	83 c4 1c             	add    $0x1c,%esp
f0103cb4:	c3                   	ret    
	...

f0103cc0 <__umoddi3>:
f0103cc0:	83 ec 1c             	sub    $0x1c,%esp
f0103cc3:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0103cc7:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f0103ccb:	8b 44 24 20          	mov    0x20(%esp),%eax
f0103ccf:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103cd3:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0103cd7:	8b 74 24 24          	mov    0x24(%esp),%esi
f0103cdb:	85 ed                	test   %ebp,%ebp
f0103cdd:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0103ce1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103ce5:	89 cf                	mov    %ecx,%edi
f0103ce7:	89 04 24             	mov    %eax,(%esp)
f0103cea:	89 f2                	mov    %esi,%edx
f0103cec:	75 1a                	jne    f0103d08 <__umoddi3+0x48>
f0103cee:	39 f1                	cmp    %esi,%ecx
f0103cf0:	76 4e                	jbe    f0103d40 <__umoddi3+0x80>
f0103cf2:	f7 f1                	div    %ecx
f0103cf4:	89 d0                	mov    %edx,%eax
f0103cf6:	31 d2                	xor    %edx,%edx
f0103cf8:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103cfc:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103d00:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103d04:	83 c4 1c             	add    $0x1c,%esp
f0103d07:	c3                   	ret    
f0103d08:	39 f5                	cmp    %esi,%ebp
f0103d0a:	77 54                	ja     f0103d60 <__umoddi3+0xa0>
f0103d0c:	0f bd c5             	bsr    %ebp,%eax
f0103d0f:	83 f0 1f             	xor    $0x1f,%eax
f0103d12:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d16:	75 60                	jne    f0103d78 <__umoddi3+0xb8>
f0103d18:	3b 0c 24             	cmp    (%esp),%ecx
f0103d1b:	0f 87 07 01 00 00    	ja     f0103e28 <__umoddi3+0x168>
f0103d21:	89 f2                	mov    %esi,%edx
f0103d23:	8b 34 24             	mov    (%esp),%esi
f0103d26:	29 ce                	sub    %ecx,%esi
f0103d28:	19 ea                	sbb    %ebp,%edx
f0103d2a:	89 34 24             	mov    %esi,(%esp)
f0103d2d:	8b 04 24             	mov    (%esp),%eax
f0103d30:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103d34:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103d38:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103d3c:	83 c4 1c             	add    $0x1c,%esp
f0103d3f:	c3                   	ret    
f0103d40:	85 c9                	test   %ecx,%ecx
f0103d42:	75 0b                	jne    f0103d4f <__umoddi3+0x8f>
f0103d44:	b8 01 00 00 00       	mov    $0x1,%eax
f0103d49:	31 d2                	xor    %edx,%edx
f0103d4b:	f7 f1                	div    %ecx
f0103d4d:	89 c1                	mov    %eax,%ecx
f0103d4f:	89 f0                	mov    %esi,%eax
f0103d51:	31 d2                	xor    %edx,%edx
f0103d53:	f7 f1                	div    %ecx
f0103d55:	8b 04 24             	mov    (%esp),%eax
f0103d58:	f7 f1                	div    %ecx
f0103d5a:	eb 98                	jmp    f0103cf4 <__umoddi3+0x34>
f0103d5c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103d60:	89 f2                	mov    %esi,%edx
f0103d62:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103d66:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103d6a:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103d6e:	83 c4 1c             	add    $0x1c,%esp
f0103d71:	c3                   	ret    
f0103d72:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103d78:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103d7d:	89 e8                	mov    %ebp,%eax
f0103d7f:	bd 20 00 00 00       	mov    $0x20,%ebp
f0103d84:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0103d88:	89 fa                	mov    %edi,%edx
f0103d8a:	d3 e0                	shl    %cl,%eax
f0103d8c:	89 e9                	mov    %ebp,%ecx
f0103d8e:	d3 ea                	shr    %cl,%edx
f0103d90:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103d95:	09 c2                	or     %eax,%edx
f0103d97:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103d9b:	89 14 24             	mov    %edx,(%esp)
f0103d9e:	89 f2                	mov    %esi,%edx
f0103da0:	d3 e7                	shl    %cl,%edi
f0103da2:	89 e9                	mov    %ebp,%ecx
f0103da4:	d3 ea                	shr    %cl,%edx
f0103da6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103dab:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103daf:	d3 e6                	shl    %cl,%esi
f0103db1:	89 e9                	mov    %ebp,%ecx
f0103db3:	d3 e8                	shr    %cl,%eax
f0103db5:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103dba:	09 f0                	or     %esi,%eax
f0103dbc:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103dc0:	f7 34 24             	divl   (%esp)
f0103dc3:	d3 e6                	shl    %cl,%esi
f0103dc5:	89 74 24 08          	mov    %esi,0x8(%esp)
f0103dc9:	89 d6                	mov    %edx,%esi
f0103dcb:	f7 e7                	mul    %edi
f0103dcd:	39 d6                	cmp    %edx,%esi
f0103dcf:	89 c1                	mov    %eax,%ecx
f0103dd1:	89 d7                	mov    %edx,%edi
f0103dd3:	72 3f                	jb     f0103e14 <__umoddi3+0x154>
f0103dd5:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0103dd9:	72 35                	jb     f0103e10 <__umoddi3+0x150>
f0103ddb:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103ddf:	29 c8                	sub    %ecx,%eax
f0103de1:	19 fe                	sbb    %edi,%esi
f0103de3:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103de8:	89 f2                	mov    %esi,%edx
f0103dea:	d3 e8                	shr    %cl,%eax
f0103dec:	89 e9                	mov    %ebp,%ecx
f0103dee:	d3 e2                	shl    %cl,%edx
f0103df0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103df5:	09 d0                	or     %edx,%eax
f0103df7:	89 f2                	mov    %esi,%edx
f0103df9:	d3 ea                	shr    %cl,%edx
f0103dfb:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103dff:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103e03:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103e07:	83 c4 1c             	add    $0x1c,%esp
f0103e0a:	c3                   	ret    
f0103e0b:	90                   	nop
f0103e0c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103e10:	39 d6                	cmp    %edx,%esi
f0103e12:	75 c7                	jne    f0103ddb <__umoddi3+0x11b>
f0103e14:	89 d7                	mov    %edx,%edi
f0103e16:	89 c1                	mov    %eax,%ecx
f0103e18:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f0103e1c:	1b 3c 24             	sbb    (%esp),%edi
f0103e1f:	eb ba                	jmp    f0103ddb <__umoddi3+0x11b>
f0103e21:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103e28:	39 f5                	cmp    %esi,%ebp
f0103e2a:	0f 82 f1 fe ff ff    	jb     f0103d21 <__umoddi3+0x61>
f0103e30:	e9 f8 fe ff ff       	jmp    f0103d2d <__umoddi3+0x6d>
