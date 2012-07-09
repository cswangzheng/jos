
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
f0100063:	e8 be 38 00 00       	call   f0103926 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 8e 04 00 00       	call   f01004fb <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 40 3e 10 f0 	movl   $0xf0103e40,(%esp)
f010007c:	e8 ad 2c 00 00       	call   f0102d2e <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 a6 11 00 00       	call   f010122c <mem_init>

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
f01000c8:	e8 61 2c 00 00       	call   f0102d2e <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 22 2c 00 00       	call   f0102cfb <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 bc 4c 10 f0 	movl   $0xf0104cbc,(%esp)
f01000e0:	e8 49 2c 00 00       	call   f0102d2e <cprintf>
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
f0100112:	e8 17 2c 00 00       	call   f0102d2e <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 d5 2b 00 00       	call   f0102cfb <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 bc 4c 10 f0 	movl   $0xf0104cbc,(%esp)
f010012d:	e8 fc 2b 00 00       	call   f0102d2e <cprintf>
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
f010032d:	e8 4f 36 00 00       	call   f0103981 <memmove>
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
f0100473:	e8 b6 28 00 00       	call   f0102d2e <cprintf>
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
f01005e4:	e8 45 27 00 00       	call   f0102d2e <cprintf>
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
f010062d:	e8 fc 26 00 00       	call   f0102d2e <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100632:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100639:	00 
f010063a:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100641:	f0 
f0100642:	c7 04 24 94 41 10 f0 	movl   $0xf0104194,(%esp)
f0100649:	e8 e0 26 00 00       	call   f0102d2e <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010064e:	c7 44 24 08 25 3e 10 	movl   $0x103e25,0x8(%esp)
f0100655:	00 
f0100656:	c7 44 24 04 25 3e 10 	movl   $0xf0103e25,0x4(%esp)
f010065d:	f0 
f010065e:	c7 04 24 b8 41 10 f0 	movl   $0xf01041b8,(%esp)
f0100665:	e8 c4 26 00 00       	call   f0102d2e <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010066a:	c7 44 24 08 04 73 11 	movl   $0x117304,0x8(%esp)
f0100671:	00 
f0100672:	c7 44 24 04 04 73 11 	movl   $0xf0117304,0x4(%esp)
f0100679:	f0 
f010067a:	c7 04 24 dc 41 10 f0 	movl   $0xf01041dc,(%esp)
f0100681:	e8 a8 26 00 00       	call   f0102d2e <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100686:	c7 44 24 08 ac 79 11 	movl   $0x1179ac,0x8(%esp)
f010068d:	00 
f010068e:	c7 44 24 04 ac 79 11 	movl   $0xf01179ac,0x4(%esp)
f0100695:	f0 
f0100696:	c7 04 24 00 42 10 f0 	movl   $0xf0104200,(%esp)
f010069d:	e8 8c 26 00 00       	call   f0102d2e <cprintf>
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
f01006c5:	e8 64 26 00 00       	call   f0102d2e <cprintf>
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
f01006f8:	e8 31 26 00 00       	call   f0102d2e <cprintf>
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
f0100748:	e8 e1 25 00 00       	call   f0102d2e <cprintf>
	
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
f010078a:	e8 9f 25 00 00       	call   f0102d2e <cprintf>
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
f01007bc:	e8 67 26 00 00       	call   f0102e28 <debuginfo_eip>
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
f010080e:	e8 1b 25 00 00       	call   f0102d2e <cprintf>
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
f0100855:	e8 d4 24 00 00       	call   f0102d2e <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010085a:	c7 04 24 a8 42 10 f0 	movl   $0xf01042a8,(%esp)
f0100861:	e8 c8 24 00 00       	call   f0102d2e <cprintf>


	while (1) {
		buf = readline("K> ");
f0100866:	c7 04 24 20 41 10 f0 	movl   $0xf0104120,(%esp)
f010086d:	e8 2e 2e 00 00       	call   f01036a0 <readline>
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
f01008a1:	e8 25 30 00 00       	call   f01038cb <strchr>
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
f01008c3:	e8 66 24 00 00       	call   f0102d2e <cprintf>
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
f01008f2:	e8 d4 2f 00 00       	call   f01038cb <strchr>
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
f0100923:	e8 28 2f 00 00       	call   f0103850 <strcmp>
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
f0100969:	e8 c0 23 00 00       	call   f0102d2e <cprintf>
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
f01009f5:	c7 44 24 04 f0 02 00 	movl   $0x2f0,0x4(%esp)
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
f0100a40:	e8 7b 22 00 00       	call   f0102cc0 <mc146818_read>
f0100a45:	89 c6                	mov    %eax,%esi
f0100a47:	83 c3 01             	add    $0x1,%ebx
f0100a4a:	89 1c 24             	mov    %ebx,(%esp)
f0100a4d:	e8 6e 22 00 00       	call   f0102cc0 <mc146818_read>
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
f0100a8a:	c7 44 24 04 33 02 00 	movl   $0x233,0x4(%esp)
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
f0100b4e:	e8 d3 2d 00 00       	call   f0103926 <memset>
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
f0100bdb:	c7 44 24 04 4d 02 00 	movl   $0x24d,0x4(%esp)
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
f0100c04:	c7 44 24 04 4e 02 00 	movl   $0x24e,0x4(%esp)
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
f0100c31:	c7 44 24 04 4f 02 00 	movl   $0x24f,0x4(%esp)
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
f0100c5f:	c7 44 24 04 52 02 00 	movl   $0x252,0x4(%esp)
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
f0100c8a:	c7 44 24 04 53 02 00 	movl   $0x253,0x4(%esp)
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
f0100cb5:	c7 44 24 04 54 02 00 	movl   $0x254,0x4(%esp)
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
f0100ce0:	c7 44 24 04 55 02 00 	movl   $0x255,0x4(%esp)
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
f0100d40:	c7 44 24 04 56 02 00 	movl   $0x256,0x4(%esp)
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
f0100d7a:	c7 44 24 04 5e 02 00 	movl   $0x25e,0x4(%esp)
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
f0100da2:	c7 44 24 04 5f 02 00 	movl   $0x25f,0x4(%esp)
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
f0100f11:	e8 10 2a 00 00       	call   f0103926 <memset>
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
f010106d:	74 34                	je     f01010a3 <boot_map_region+0x62>
{
	// Fill this function in
	if(size%PGSIZE!=0)
		size=ROUNDUP(size,PGSIZE);//panic(" Size must be a multiple of PGSIZE.");
	pte_t *pte ;
	size_t i=0;
f010106f:	bb 00 00 00 00       	mov    $0x0,%ebx
// above UTOP. As such, it should *not* change the pp_ref field on the
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f0101074:	8b 75 08             	mov    0x8(%ebp),%esi
f0101077:	01 de                	add    %ebx,%esi
		size=ROUNDUP(size,PGSIZE);//panic(" Size must be a multiple of PGSIZE.");
	pte_t *pte ;
	size_t i=0;
	while(i<size)
	{
		pte=pgdir_walk(pgdir, (void *)va, 1);
f0101079:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101080:	00 
// above UTOP. As such, it should *not* change the pp_ref field on the
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f0101081:	8d 04 3b             	lea    (%ebx,%edi,1),%eax
		size=ROUNDUP(size,PGSIZE);//panic(" Size must be a multiple of PGSIZE.");
	pte_t *pte ;
	size_t i=0;
	while(i<size)
	{
		pte=pgdir_walk(pgdir, (void *)va, 1);
f0101084:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101088:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010108b:	89 04 24             	mov    %eax,(%esp)
f010108e:	e8 ca fe ff ff       	call   f0100f5d <pgdir_walk>
		*pte= pa|perm;
f0101093:	0b 75 0c             	or     0xc(%ebp),%esi
f0101096:	89 30                	mov    %esi,(%eax)
		pa+=PGSIZE;
		va+=PGSIZE;
		i+=PGSIZE;
f0101098:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// Fill this function in
	if(size%PGSIZE!=0)
		size=ROUNDUP(size,PGSIZE);//panic(" Size must be a multiple of PGSIZE.");
	pte_t *pte ;
	size_t i=0;
	while(i<size)
f010109e:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f01010a1:	77 d1                	ja     f0101074 <boot_map_region+0x33>
		*pte= pa|perm;
		pa+=PGSIZE;
		va+=PGSIZE;
		i+=PGSIZE;
	}
}
f01010a3:	83 c4 2c             	add    $0x2c,%esp
f01010a6:	5b                   	pop    %ebx
f01010a7:	5e                   	pop    %esi
f01010a8:	5f                   	pop    %edi
f01010a9:	5d                   	pop    %ebp
f01010aa:	c3                   	ret    

f01010ab <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01010ab:	55                   	push   %ebp
f01010ac:	89 e5                	mov    %esp,%ebp
f01010ae:	53                   	push   %ebx
f01010af:	83 ec 14             	sub    $0x14,%esp
f01010b2:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pte = pgdir_walk(pgdir,(void *)va, 0);
f01010b5:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01010bc:	00 
f01010bd:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010c0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01010c4:	8b 45 08             	mov    0x8(%ebp),%eax
f01010c7:	89 04 24             	mov    %eax,(%esp)
f01010ca:	e8 8e fe ff ff       	call   f0100f5d <pgdir_walk>
	if (pte==NULL)
f01010cf:	85 c0                	test   %eax,%eax
f01010d1:	74 3e                	je     f0101111 <page_lookup+0x66>
	{
		return NULL;		
	}
	if (pte_store != 0) 
f01010d3:	85 db                	test   %ebx,%ebx
f01010d5:	74 02                	je     f01010d9 <page_lookup+0x2e>
	{
		*pte_store = pte;
f01010d7:	89 03                	mov    %eax,(%ebx)
	}
	if (*pte & PTE_P) 
f01010d9:	8b 00                	mov    (%eax),%eax
f01010db:	a8 01                	test   $0x1,%al
f01010dd:	74 39                	je     f0101118 <page_lookup+0x6d>
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010df:	c1 e8 0c             	shr    $0xc,%eax
f01010e2:	3b 05 a0 79 11 f0    	cmp    0xf01179a0,%eax
f01010e8:	72 1c                	jb     f0101106 <page_lookup+0x5b>
		panic("pa2page called with invalid pa");
f01010ea:	c7 44 24 08 50 44 10 	movl   $0xf0104450,0x8(%esp)
f01010f1:	f0 
f01010f2:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f01010f9:	00 
f01010fa:	c7 04 24 38 4a 10 f0 	movl   $0xf0104a38,(%esp)
f0101101:	e8 8e ef ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f0101106:	c1 e0 03             	shl    $0x3,%eax
f0101109:	03 05 a8 79 11 f0    	add    0xf01179a8,%eax
	{
		return pa2page (PTE_ADDR (*pte));
f010110f:	eb 0c                	jmp    f010111d <page_lookup+0x72>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t *pte = pgdir_walk(pgdir,(void *)va, 0);
	if (pte==NULL)
	{
		return NULL;		
f0101111:	b8 00 00 00 00       	mov    $0x0,%eax
f0101116:	eb 05                	jmp    f010111d <page_lookup+0x72>
	}
	if (*pte & PTE_P) 
	{
		return pa2page (PTE_ADDR (*pte));
	}
	return NULL;
f0101118:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010111d:	83 c4 14             	add    $0x14,%esp
f0101120:	5b                   	pop    %ebx
f0101121:	5d                   	pop    %ebp
f0101122:	c3                   	ret    

f0101123 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0101123:	55                   	push   %ebp
f0101124:	89 e5                	mov    %esp,%ebp
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101126:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101129:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f010112c:	5d                   	pop    %ebp
f010112d:	c3                   	ret    

f010112e <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f010112e:	55                   	push   %ebp
f010112f:	89 e5                	mov    %esp,%ebp
f0101131:	83 ec 28             	sub    $0x28,%esp
f0101134:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0101137:	89 75 fc             	mov    %esi,-0x4(%ebp)
f010113a:	8b 75 08             	mov    0x8(%ebp),%esi
f010113d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *pte;
	struct Page *pp;
    	pp=page_lookup (pgdir, va, &pte);
f0101140:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101143:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101147:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010114b:	89 34 24             	mov    %esi,(%esp)
f010114e:	e8 58 ff ff ff       	call   f01010ab <page_lookup>
	if (pp != NULL) 
f0101153:	85 c0                	test   %eax,%eax
f0101155:	74 21                	je     f0101178 <page_remove+0x4a>
	{
		page_decref (pp);//- The ref count on the physical page should decrement.
f0101157:	89 04 24             	mov    %eax,(%esp)
f010115a:	e8 db fd ff ff       	call   f0100f3a <page_decref>
//   - The physical page should be freed if the refcount reaches 0.
		if(pte!=NULL)
f010115f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101162:	85 c0                	test   %eax,%eax
f0101164:	74 06                	je     f010116c <page_remove+0x3e>
			*pte = 0;// The pg table entry corresponding to 'va' should be set to 0. (if such a PTE exists)
f0101166:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		tlb_invalidate (pgdir, va);//The TLB must be invalidated if you remove an entry from  the page table.
f010116c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101170:	89 34 24             	mov    %esi,(%esp)
f0101173:	e8 ab ff ff ff       	call   f0101123 <tlb_invalidate>
	}
}
f0101178:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f010117b:	8b 75 fc             	mov    -0x4(%ebp),%esi
f010117e:	89 ec                	mov    %ebp,%esp
f0101180:	5d                   	pop    %ebp
f0101181:	c3                   	ret    

f0101182 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{
f0101182:	55                   	push   %ebp
f0101183:	89 e5                	mov    %esp,%ebp
f0101185:	83 ec 28             	sub    $0x28,%esp
f0101188:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010118b:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010118e:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0101191:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101194:	8b 7d 10             	mov    0x10(%ebp),%edi

	pte_t * pte = pgdir_walk(pgdir, (void *)va, 1) ;
f0101197:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010119e:	00 
f010119f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011a3:	8b 45 08             	mov    0x8(%ebp),%eax
f01011a6:	89 04 24             	mov    %eax,(%esp)
f01011a9:	e8 af fd ff ff       	call   f0100f5d <pgdir_walk>
f01011ae:	89 c3                	mov    %eax,%ebx
//   - If necessary, on demand, a page table should be allocated and inserted
//     into 'pgdir'.
	if (pte==NULL)
f01011b0:	85 c0                	test   %eax,%eax
f01011b2:	74 66                	je     f010121a <page_insert+0x98>
		return -E_NO_MEM;
//-E_NO_MEM, if page table couldn't be allocated
	if (*pte & PTE_P) {
f01011b4:	8b 00                	mov    (%eax),%eax
f01011b6:	a8 01                	test   $0x1,%al
f01011b8:	74 3c                	je     f01011f6 <page_insert+0x74>
		if (PTE_ADDR(*pte) == page2pa(pp))
f01011ba:	25 00 f0 ff ff       	and    $0xfffff000,%eax
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01011bf:	89 f2                	mov    %esi,%edx
f01011c1:	2b 15 a8 79 11 f0    	sub    0xf01179a8,%edx
f01011c7:	c1 fa 03             	sar    $0x3,%edx
f01011ca:	c1 e2 0c             	shl    $0xc,%edx
f01011cd:	39 d0                	cmp    %edx,%eax
f01011cf:	75 16                	jne    f01011e7 <page_insert+0x65>
		{	
			pp->pp_ref--;
f01011d1:	66 83 6e 04 01       	subw   $0x1,0x4(%esi)
			tlb_invalidate(pgdir, va);
f01011d6:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011da:	8b 45 08             	mov    0x8(%ebp),%eax
f01011dd:	89 04 24             	mov    %eax,(%esp)
f01011e0:	e8 3e ff ff ff       	call   f0101123 <tlb_invalidate>
f01011e5:	eb 0f                	jmp    f01011f6 <page_insert+0x74>
//The TLB must be invalidated if a page was formerly present at 'va'.
		} 
		else 
		{
			page_remove (pgdir, va);
f01011e7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011eb:	8b 45 08             	mov    0x8(%ebp),%eax
f01011ee:	89 04 24             	mov    %eax,(%esp)
f01011f1:	e8 38 ff ff ff       	call   f010112e <page_remove>
//If there is already a page mapped at 'va', it should be page_remove()d.
		}
	}

	*pte = page2pa(pp)|perm|PTE_P;
f01011f6:	8b 45 14             	mov    0x14(%ebp),%eax
f01011f9:	83 c8 01             	or     $0x1,%eax
f01011fc:	89 f2                	mov    %esi,%edx
f01011fe:	2b 15 a8 79 11 f0    	sub    0xf01179a8,%edx
f0101204:	c1 fa 03             	sar    $0x3,%edx
f0101207:	c1 e2 0c             	shl    $0xc,%edx
f010120a:	09 d0                	or     %edx,%eax
f010120c:	89 03                	mov    %eax,(%ebx)
	pp->pp_ref++;
f010120e:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
//pp->pp_ref should be incremented if the insertion succeeds.
	return 0;
f0101213:	b8 00 00 00 00       	mov    $0x0,%eax
f0101218:	eb 05                	jmp    f010121f <page_insert+0x9d>

	pte_t * pte = pgdir_walk(pgdir, (void *)va, 1) ;
//   - If necessary, on demand, a page table should be allocated and inserted
//     into 'pgdir'.
	if (pte==NULL)
		return -E_NO_MEM;
f010121a:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	*pte = page2pa(pp)|perm|PTE_P;
	pp->pp_ref++;
//pp->pp_ref should be incremented if the insertion succeeds.
	return 0;
//0 on success
}
f010121f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0101222:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0101225:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101228:	89 ec                	mov    %ebp,%esp
f010122a:	5d                   	pop    %ebp
f010122b:	c3                   	ret    

f010122c <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f010122c:	55                   	push   %ebp
f010122d:	89 e5                	mov    %esp,%ebp
f010122f:	57                   	push   %edi
f0101230:	56                   	push   %esi
f0101231:	53                   	push   %ebx
f0101232:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101235:	b8 15 00 00 00       	mov    $0x15,%eax
f010123a:	e8 f0 f7 ff ff       	call   f0100a2f <nvram_read>
f010123f:	c1 e0 0a             	shl    $0xa,%eax
f0101242:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101248:	85 c0                	test   %eax,%eax
f010124a:	0f 48 c2             	cmovs  %edx,%eax
f010124d:	c1 f8 0c             	sar    $0xc,%eax
f0101250:	a3 78 75 11 f0       	mov    %eax,0xf0117578
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101255:	b8 17 00 00 00       	mov    $0x17,%eax
f010125a:	e8 d0 f7 ff ff       	call   f0100a2f <nvram_read>
f010125f:	c1 e0 0a             	shl    $0xa,%eax
f0101262:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101268:	85 c0                	test   %eax,%eax
f010126a:	0f 48 c2             	cmovs  %edx,%eax
f010126d:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101270:	85 c0                	test   %eax,%eax
f0101272:	74 0e                	je     f0101282 <mem_init+0x56>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101274:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f010127a:	89 15 a0 79 11 f0    	mov    %edx,0xf01179a0
f0101280:	eb 0c                	jmp    f010128e <mem_init+0x62>
	else
		npages = npages_basemem;
f0101282:	8b 15 78 75 11 f0    	mov    0xf0117578,%edx
f0101288:	89 15 a0 79 11 f0    	mov    %edx,0xf01179a0

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f010128e:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101291:	c1 e8 0a             	shr    $0xa,%eax
f0101294:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f0101298:	a1 78 75 11 f0       	mov    0xf0117578,%eax
f010129d:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012a0:	c1 e8 0a             	shr    $0xa,%eax
f01012a3:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f01012a7:	a1 a0 79 11 f0       	mov    0xf01179a0,%eax
f01012ac:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012af:	c1 e8 0a             	shr    $0xa,%eax
f01012b2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012b6:	c7 04 24 70 44 10 f0 	movl   $0xf0104470,(%esp)
f01012bd:	e8 6c 1a 00 00       	call   f0102d2e <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01012c2:	b8 00 10 00 00       	mov    $0x1000,%eax
f01012c7:	e8 b8 f6 ff ff       	call   f0100984 <boot_alloc>
f01012cc:	a3 a4 79 11 f0       	mov    %eax,0xf01179a4
	memset(kern_pgdir, 0, PGSIZE);
f01012d1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01012d8:	00 
f01012d9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01012e0:	00 
f01012e1:	89 04 24             	mov    %eax,(%esp)
f01012e4:	e8 3d 26 00 00       	call   f0103926 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following two lines.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01012e9:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01012ee:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01012f3:	77 20                	ja     f0101315 <mem_init+0xe9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01012f5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012f9:	c7 44 24 08 2c 44 10 	movl   $0xf010442c,0x8(%esp)
f0101300:	f0 
f0101301:	c7 44 24 04 8b 00 00 	movl   $0x8b,0x4(%esp)
f0101308:	00 
f0101309:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101310:	e8 7f ed ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101315:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010131b:	83 ca 05             	or     $0x5,%edx
f010131e:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct Page in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:

	pages =(struct Page *) boot_alloc(npages* sizeof (struct Page));
f0101324:	a1 a0 79 11 f0       	mov    0xf01179a0,%eax
f0101329:	c1 e0 03             	shl    $0x3,%eax
f010132c:	e8 53 f6 ff ff       	call   f0100984 <boot_alloc>
f0101331:	a3 a8 79 11 f0       	mov    %eax,0xf01179a8
	memset(pages, 0, npages* sizeof (struct Page));
f0101336:	8b 15 a0 79 11 f0    	mov    0xf01179a0,%edx
f010133c:	c1 e2 03             	shl    $0x3,%edx
f010133f:	89 54 24 08          	mov    %edx,0x8(%esp)
f0101343:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010134a:	00 
f010134b:	89 04 24             	mov    %eax,(%esp)
f010134e:	e8 d3 25 00 00       	call   f0103926 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101353:	e8 66 fa ff ff       	call   f0100dbe <page_init>
	check_page_free_list(1);
f0101358:	b8 01 00 00 00       	mov    $0x1,%eax
f010135d:	e8 ff f6 ff ff       	call   f0100a61 <check_page_free_list>
	int nfree;
	struct Page *fl;
	char *c;
	int i;

	if (!pages)
f0101362:	83 3d a8 79 11 f0 00 	cmpl   $0x0,0xf01179a8
f0101369:	75 1c                	jne    f0101387 <mem_init+0x15b>
		panic("'pages' is a null pointer!");
f010136b:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0101372:	f0 
f0101373:	c7 44 24 04 70 02 00 	movl   $0x270,0x4(%esp)
f010137a:	00 
f010137b:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101382:	e8 0d ed ff ff       	call   f0100094 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101387:	a1 80 75 11 f0       	mov    0xf0117580,%eax
f010138c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101391:	85 c0                	test   %eax,%eax
f0101393:	74 09                	je     f010139e <mem_init+0x172>
		++nfree;
f0101395:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101398:	8b 00                	mov    (%eax),%eax
f010139a:	85 c0                	test   %eax,%eax
f010139c:	75 f7                	jne    f0101395 <mem_init+0x169>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010139e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013a5:	e8 ee fa ff ff       	call   f0100e98 <page_alloc>
f01013aa:	89 c6                	mov    %eax,%esi
f01013ac:	85 c0                	test   %eax,%eax
f01013ae:	75 24                	jne    f01013d4 <mem_init+0x1a8>
f01013b0:	c7 44 24 0c fd 4a 10 	movl   $0xf0104afd,0xc(%esp)
f01013b7:	f0 
f01013b8:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f01013bf:	f0 
f01013c0:	c7 44 24 04 78 02 00 	movl   $0x278,0x4(%esp)
f01013c7:	00 
f01013c8:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01013cf:	e8 c0 ec ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01013d4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013db:	e8 b8 fa ff ff       	call   f0100e98 <page_alloc>
f01013e0:	89 c7                	mov    %eax,%edi
f01013e2:	85 c0                	test   %eax,%eax
f01013e4:	75 24                	jne    f010140a <mem_init+0x1de>
f01013e6:	c7 44 24 0c 13 4b 10 	movl   $0xf0104b13,0xc(%esp)
f01013ed:	f0 
f01013ee:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f01013f5:	f0 
f01013f6:	c7 44 24 04 79 02 00 	movl   $0x279,0x4(%esp)
f01013fd:	00 
f01013fe:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101405:	e8 8a ec ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f010140a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101411:	e8 82 fa ff ff       	call   f0100e98 <page_alloc>
f0101416:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101419:	85 c0                	test   %eax,%eax
f010141b:	75 24                	jne    f0101441 <mem_init+0x215>
f010141d:	c7 44 24 0c 29 4b 10 	movl   $0xf0104b29,0xc(%esp)
f0101424:	f0 
f0101425:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f010142c:	f0 
f010142d:	c7 44 24 04 7a 02 00 	movl   $0x27a,0x4(%esp)
f0101434:	00 
f0101435:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f010143c:	e8 53 ec ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101441:	39 fe                	cmp    %edi,%esi
f0101443:	75 24                	jne    f0101469 <mem_init+0x23d>
f0101445:	c7 44 24 0c 3f 4b 10 	movl   $0xf0104b3f,0xc(%esp)
f010144c:	f0 
f010144d:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101454:	f0 
f0101455:	c7 44 24 04 7d 02 00 	movl   $0x27d,0x4(%esp)
f010145c:	00 
f010145d:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101464:	e8 2b ec ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101469:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f010146c:	74 05                	je     f0101473 <mem_init+0x247>
f010146e:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101471:	75 24                	jne    f0101497 <mem_init+0x26b>
f0101473:	c7 44 24 0c ac 44 10 	movl   $0xf01044ac,0xc(%esp)
f010147a:	f0 
f010147b:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101482:	f0 
f0101483:	c7 44 24 04 7e 02 00 	movl   $0x27e,0x4(%esp)
f010148a:	00 
f010148b:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101492:	e8 fd eb ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101497:	8b 15 a8 79 11 f0    	mov    0xf01179a8,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f010149d:	a1 a0 79 11 f0       	mov    0xf01179a0,%eax
f01014a2:	c1 e0 0c             	shl    $0xc,%eax
f01014a5:	89 f1                	mov    %esi,%ecx
f01014a7:	29 d1                	sub    %edx,%ecx
f01014a9:	c1 f9 03             	sar    $0x3,%ecx
f01014ac:	c1 e1 0c             	shl    $0xc,%ecx
f01014af:	39 c1                	cmp    %eax,%ecx
f01014b1:	72 24                	jb     f01014d7 <mem_init+0x2ab>
f01014b3:	c7 44 24 0c 51 4b 10 	movl   $0xf0104b51,0xc(%esp)
f01014ba:	f0 
f01014bb:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f01014c2:	f0 
f01014c3:	c7 44 24 04 7f 02 00 	movl   $0x27f,0x4(%esp)
f01014ca:	00 
f01014cb:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01014d2:	e8 bd eb ff ff       	call   f0100094 <_panic>
f01014d7:	89 f9                	mov    %edi,%ecx
f01014d9:	29 d1                	sub    %edx,%ecx
f01014db:	c1 f9 03             	sar    $0x3,%ecx
f01014de:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f01014e1:	39 c8                	cmp    %ecx,%eax
f01014e3:	77 24                	ja     f0101509 <mem_init+0x2dd>
f01014e5:	c7 44 24 0c 6e 4b 10 	movl   $0xf0104b6e,0xc(%esp)
f01014ec:	f0 
f01014ed:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f01014f4:	f0 
f01014f5:	c7 44 24 04 80 02 00 	movl   $0x280,0x4(%esp)
f01014fc:	00 
f01014fd:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101504:	e8 8b eb ff ff       	call   f0100094 <_panic>
f0101509:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010150c:	29 d1                	sub    %edx,%ecx
f010150e:	89 ca                	mov    %ecx,%edx
f0101510:	c1 fa 03             	sar    $0x3,%edx
f0101513:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f0101516:	39 d0                	cmp    %edx,%eax
f0101518:	77 24                	ja     f010153e <mem_init+0x312>
f010151a:	c7 44 24 0c 8b 4b 10 	movl   $0xf0104b8b,0xc(%esp)
f0101521:	f0 
f0101522:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101529:	f0 
f010152a:	c7 44 24 04 81 02 00 	movl   $0x281,0x4(%esp)
f0101531:	00 
f0101532:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101539:	e8 56 eb ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010153e:	a1 80 75 11 f0       	mov    0xf0117580,%eax
f0101543:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101546:	c7 05 80 75 11 f0 00 	movl   $0x0,0xf0117580
f010154d:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101550:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101557:	e8 3c f9 ff ff       	call   f0100e98 <page_alloc>
f010155c:	85 c0                	test   %eax,%eax
f010155e:	74 24                	je     f0101584 <mem_init+0x358>
f0101560:	c7 44 24 0c a8 4b 10 	movl   $0xf0104ba8,0xc(%esp)
f0101567:	f0 
f0101568:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f010156f:	f0 
f0101570:	c7 44 24 04 88 02 00 	movl   $0x288,0x4(%esp)
f0101577:	00 
f0101578:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f010157f:	e8 10 eb ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101584:	89 34 24             	mov    %esi,(%esp)
f0101587:	e8 99 f9 ff ff       	call   f0100f25 <page_free>
	page_free(pp1);
f010158c:	89 3c 24             	mov    %edi,(%esp)
f010158f:	e8 91 f9 ff ff       	call   f0100f25 <page_free>
	page_free(pp2);
f0101594:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101597:	89 04 24             	mov    %eax,(%esp)
f010159a:	e8 86 f9 ff ff       	call   f0100f25 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010159f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015a6:	e8 ed f8 ff ff       	call   f0100e98 <page_alloc>
f01015ab:	89 c6                	mov    %eax,%esi
f01015ad:	85 c0                	test   %eax,%eax
f01015af:	75 24                	jne    f01015d5 <mem_init+0x3a9>
f01015b1:	c7 44 24 0c fd 4a 10 	movl   $0xf0104afd,0xc(%esp)
f01015b8:	f0 
f01015b9:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f01015c0:	f0 
f01015c1:	c7 44 24 04 8f 02 00 	movl   $0x28f,0x4(%esp)
f01015c8:	00 
f01015c9:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01015d0:	e8 bf ea ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01015d5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015dc:	e8 b7 f8 ff ff       	call   f0100e98 <page_alloc>
f01015e1:	89 c7                	mov    %eax,%edi
f01015e3:	85 c0                	test   %eax,%eax
f01015e5:	75 24                	jne    f010160b <mem_init+0x3df>
f01015e7:	c7 44 24 0c 13 4b 10 	movl   $0xf0104b13,0xc(%esp)
f01015ee:	f0 
f01015ef:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f01015f6:	f0 
f01015f7:	c7 44 24 04 90 02 00 	movl   $0x290,0x4(%esp)
f01015fe:	00 
f01015ff:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101606:	e8 89 ea ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f010160b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101612:	e8 81 f8 ff ff       	call   f0100e98 <page_alloc>
f0101617:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010161a:	85 c0                	test   %eax,%eax
f010161c:	75 24                	jne    f0101642 <mem_init+0x416>
f010161e:	c7 44 24 0c 29 4b 10 	movl   $0xf0104b29,0xc(%esp)
f0101625:	f0 
f0101626:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f010162d:	f0 
f010162e:	c7 44 24 04 91 02 00 	movl   $0x291,0x4(%esp)
f0101635:	00 
f0101636:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f010163d:	e8 52 ea ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101642:	39 fe                	cmp    %edi,%esi
f0101644:	75 24                	jne    f010166a <mem_init+0x43e>
f0101646:	c7 44 24 0c 3f 4b 10 	movl   $0xf0104b3f,0xc(%esp)
f010164d:	f0 
f010164e:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101655:	f0 
f0101656:	c7 44 24 04 93 02 00 	movl   $0x293,0x4(%esp)
f010165d:	00 
f010165e:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101665:	e8 2a ea ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010166a:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f010166d:	74 05                	je     f0101674 <mem_init+0x448>
f010166f:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101672:	75 24                	jne    f0101698 <mem_init+0x46c>
f0101674:	c7 44 24 0c ac 44 10 	movl   $0xf01044ac,0xc(%esp)
f010167b:	f0 
f010167c:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101683:	f0 
f0101684:	c7 44 24 04 94 02 00 	movl   $0x294,0x4(%esp)
f010168b:	00 
f010168c:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101693:	e8 fc e9 ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f0101698:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010169f:	e8 f4 f7 ff ff       	call   f0100e98 <page_alloc>
f01016a4:	85 c0                	test   %eax,%eax
f01016a6:	74 24                	je     f01016cc <mem_init+0x4a0>
f01016a8:	c7 44 24 0c a8 4b 10 	movl   $0xf0104ba8,0xc(%esp)
f01016af:	f0 
f01016b0:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f01016b7:	f0 
f01016b8:	c7 44 24 04 95 02 00 	movl   $0x295,0x4(%esp)
f01016bf:	00 
f01016c0:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01016c7:	e8 c8 e9 ff ff       	call   f0100094 <_panic>
f01016cc:	89 f0                	mov    %esi,%eax
f01016ce:	2b 05 a8 79 11 f0    	sub    0xf01179a8,%eax
f01016d4:	c1 f8 03             	sar    $0x3,%eax
f01016d7:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01016da:	89 c2                	mov    %eax,%edx
f01016dc:	c1 ea 0c             	shr    $0xc,%edx
f01016df:	3b 15 a0 79 11 f0    	cmp    0xf01179a0,%edx
f01016e5:	72 20                	jb     f0101707 <mem_init+0x4db>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01016e7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01016eb:	c7 44 24 08 44 43 10 	movl   $0xf0104344,0x8(%esp)
f01016f2:	f0 
f01016f3:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01016fa:	00 
f01016fb:	c7 04 24 38 4a 10 f0 	movl   $0xf0104a38,(%esp)
f0101702:	e8 8d e9 ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101707:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010170e:	00 
f010170f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101716:	00 
	return (void *)(pa + KERNBASE);
f0101717:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010171c:	89 04 24             	mov    %eax,(%esp)
f010171f:	e8 02 22 00 00       	call   f0103926 <memset>
	page_free(pp0);
f0101724:	89 34 24             	mov    %esi,(%esp)
f0101727:	e8 f9 f7 ff ff       	call   f0100f25 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010172c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101733:	e8 60 f7 ff ff       	call   f0100e98 <page_alloc>
f0101738:	85 c0                	test   %eax,%eax
f010173a:	75 24                	jne    f0101760 <mem_init+0x534>
f010173c:	c7 44 24 0c b7 4b 10 	movl   $0xf0104bb7,0xc(%esp)
f0101743:	f0 
f0101744:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f010174b:	f0 
f010174c:	c7 44 24 04 9a 02 00 	movl   $0x29a,0x4(%esp)
f0101753:	00 
f0101754:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f010175b:	e8 34 e9 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f0101760:	39 c6                	cmp    %eax,%esi
f0101762:	74 24                	je     f0101788 <mem_init+0x55c>
f0101764:	c7 44 24 0c d5 4b 10 	movl   $0xf0104bd5,0xc(%esp)
f010176b:	f0 
f010176c:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101773:	f0 
f0101774:	c7 44 24 04 9b 02 00 	movl   $0x29b,0x4(%esp)
f010177b:	00 
f010177c:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101783:	e8 0c e9 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101788:	89 f2                	mov    %esi,%edx
f010178a:	2b 15 a8 79 11 f0    	sub    0xf01179a8,%edx
f0101790:	c1 fa 03             	sar    $0x3,%edx
f0101793:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101796:	89 d0                	mov    %edx,%eax
f0101798:	c1 e8 0c             	shr    $0xc,%eax
f010179b:	3b 05 a0 79 11 f0    	cmp    0xf01179a0,%eax
f01017a1:	72 20                	jb     f01017c3 <mem_init+0x597>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01017a3:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01017a7:	c7 44 24 08 44 43 10 	movl   $0xf0104344,0x8(%esp)
f01017ae:	f0 
f01017af:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01017b6:	00 
f01017b7:	c7 04 24 38 4a 10 f0 	movl   $0xf0104a38,(%esp)
f01017be:	e8 d1 e8 ff ff       	call   f0100094 <_panic>
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01017c3:	80 ba 00 00 00 f0 00 	cmpb   $0x0,-0x10000000(%edx)
f01017ca:	75 11                	jne    f01017dd <mem_init+0x5b1>
f01017cc:	8d 82 01 00 00 f0    	lea    -0xfffffff(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01017d2:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01017d8:	80 38 00             	cmpb   $0x0,(%eax)
f01017db:	74 24                	je     f0101801 <mem_init+0x5d5>
f01017dd:	c7 44 24 0c e5 4b 10 	movl   $0xf0104be5,0xc(%esp)
f01017e4:	f0 
f01017e5:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f01017ec:	f0 
f01017ed:	c7 44 24 04 9e 02 00 	movl   $0x29e,0x4(%esp)
f01017f4:	00 
f01017f5:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01017fc:	e8 93 e8 ff ff       	call   f0100094 <_panic>
f0101801:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101804:	39 d0                	cmp    %edx,%eax
f0101806:	75 d0                	jne    f01017d8 <mem_init+0x5ac>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101808:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010180b:	89 15 80 75 11 f0    	mov    %edx,0xf0117580

	// free the pages we took
	page_free(pp0);
f0101811:	89 34 24             	mov    %esi,(%esp)
f0101814:	e8 0c f7 ff ff       	call   f0100f25 <page_free>
	page_free(pp1);
f0101819:	89 3c 24             	mov    %edi,(%esp)
f010181c:	e8 04 f7 ff ff       	call   f0100f25 <page_free>
	page_free(pp2);
f0101821:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101824:	89 04 24             	mov    %eax,(%esp)
f0101827:	e8 f9 f6 ff ff       	call   f0100f25 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010182c:	a1 80 75 11 f0       	mov    0xf0117580,%eax
f0101831:	85 c0                	test   %eax,%eax
f0101833:	74 09                	je     f010183e <mem_init+0x612>
		--nfree;
f0101835:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101838:	8b 00                	mov    (%eax),%eax
f010183a:	85 c0                	test   %eax,%eax
f010183c:	75 f7                	jne    f0101835 <mem_init+0x609>
		--nfree;
	assert(nfree == 0);
f010183e:	85 db                	test   %ebx,%ebx
f0101840:	74 24                	je     f0101866 <mem_init+0x63a>
f0101842:	c7 44 24 0c ef 4b 10 	movl   $0xf0104bef,0xc(%esp)
f0101849:	f0 
f010184a:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101851:	f0 
f0101852:	c7 44 24 04 ab 02 00 	movl   $0x2ab,0x4(%esp)
f0101859:	00 
f010185a:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101861:	e8 2e e8 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101866:	c7 04 24 cc 44 10 f0 	movl   $0xf01044cc,(%esp)
f010186d:	e8 bc 14 00 00       	call   f0102d2e <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101872:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101879:	e8 1a f6 ff ff       	call   f0100e98 <page_alloc>
f010187e:	89 c3                	mov    %eax,%ebx
f0101880:	85 c0                	test   %eax,%eax
f0101882:	75 24                	jne    f01018a8 <mem_init+0x67c>
f0101884:	c7 44 24 0c fd 4a 10 	movl   $0xf0104afd,0xc(%esp)
f010188b:	f0 
f010188c:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101893:	f0 
f0101894:	c7 44 24 04 04 03 00 	movl   $0x304,0x4(%esp)
f010189b:	00 
f010189c:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01018a3:	e8 ec e7 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01018a8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018af:	e8 e4 f5 ff ff       	call   f0100e98 <page_alloc>
f01018b4:	89 c7                	mov    %eax,%edi
f01018b6:	85 c0                	test   %eax,%eax
f01018b8:	75 24                	jne    f01018de <mem_init+0x6b2>
f01018ba:	c7 44 24 0c 13 4b 10 	movl   $0xf0104b13,0xc(%esp)
f01018c1:	f0 
f01018c2:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f01018c9:	f0 
f01018ca:	c7 44 24 04 05 03 00 	movl   $0x305,0x4(%esp)
f01018d1:	00 
f01018d2:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01018d9:	e8 b6 e7 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01018de:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018e5:	e8 ae f5 ff ff       	call   f0100e98 <page_alloc>
f01018ea:	89 c6                	mov    %eax,%esi
f01018ec:	85 c0                	test   %eax,%eax
f01018ee:	75 24                	jne    f0101914 <mem_init+0x6e8>
f01018f0:	c7 44 24 0c 29 4b 10 	movl   $0xf0104b29,0xc(%esp)
f01018f7:	f0 
f01018f8:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f01018ff:	f0 
f0101900:	c7 44 24 04 06 03 00 	movl   $0x306,0x4(%esp)
f0101907:	00 
f0101908:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f010190f:	e8 80 e7 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101914:	39 fb                	cmp    %edi,%ebx
f0101916:	75 24                	jne    f010193c <mem_init+0x710>
f0101918:	c7 44 24 0c 3f 4b 10 	movl   $0xf0104b3f,0xc(%esp)
f010191f:	f0 
f0101920:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101927:	f0 
f0101928:	c7 44 24 04 09 03 00 	movl   $0x309,0x4(%esp)
f010192f:	00 
f0101930:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101937:	e8 58 e7 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010193c:	39 c7                	cmp    %eax,%edi
f010193e:	74 04                	je     f0101944 <mem_init+0x718>
f0101940:	39 c3                	cmp    %eax,%ebx
f0101942:	75 24                	jne    f0101968 <mem_init+0x73c>
f0101944:	c7 44 24 0c ac 44 10 	movl   $0xf01044ac,0xc(%esp)
f010194b:	f0 
f010194c:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101953:	f0 
f0101954:	c7 44 24 04 0a 03 00 	movl   $0x30a,0x4(%esp)
f010195b:	00 
f010195c:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101963:	e8 2c e7 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101968:	8b 15 80 75 11 f0    	mov    0xf0117580,%edx
f010196e:	89 55 cc             	mov    %edx,-0x34(%ebp)
	page_free_list = 0;
f0101971:	c7 05 80 75 11 f0 00 	movl   $0x0,0xf0117580
f0101978:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010197b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101982:	e8 11 f5 ff ff       	call   f0100e98 <page_alloc>
f0101987:	85 c0                	test   %eax,%eax
f0101989:	74 24                	je     f01019af <mem_init+0x783>
f010198b:	c7 44 24 0c a8 4b 10 	movl   $0xf0104ba8,0xc(%esp)
f0101992:	f0 
f0101993:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f010199a:	f0 
f010199b:	c7 44 24 04 11 03 00 	movl   $0x311,0x4(%esp)
f01019a2:	00 
f01019a3:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01019aa:	e8 e5 e6 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01019af:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01019b2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01019b6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01019bd:	00 
f01019be:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f01019c3:	89 04 24             	mov    %eax,(%esp)
f01019c6:	e8 e0 f6 ff ff       	call   f01010ab <page_lookup>
f01019cb:	85 c0                	test   %eax,%eax
f01019cd:	74 24                	je     f01019f3 <mem_init+0x7c7>
f01019cf:	c7 44 24 0c ec 44 10 	movl   $0xf01044ec,0xc(%esp)
f01019d6:	f0 
f01019d7:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f01019de:	f0 
f01019df:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
f01019e6:	00 
f01019e7:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01019ee:	e8 a1 e6 ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01019f3:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01019fa:	00 
f01019fb:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101a02:	00 
f0101a03:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101a07:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0101a0c:	89 04 24             	mov    %eax,(%esp)
f0101a0f:	e8 6e f7 ff ff       	call   f0101182 <page_insert>
f0101a14:	85 c0                	test   %eax,%eax
f0101a16:	78 24                	js     f0101a3c <mem_init+0x810>
f0101a18:	c7 44 24 0c 24 45 10 	movl   $0xf0104524,0xc(%esp)
f0101a1f:	f0 
f0101a20:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101a27:	f0 
f0101a28:	c7 44 24 04 17 03 00 	movl   $0x317,0x4(%esp)
f0101a2f:	00 
f0101a30:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101a37:	e8 58 e6 ff ff       	call   f0100094 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101a3c:	89 1c 24             	mov    %ebx,(%esp)
f0101a3f:	e8 e1 f4 ff ff       	call   f0100f25 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101a44:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101a4b:	00 
f0101a4c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101a53:	00 
f0101a54:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101a58:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0101a5d:	89 04 24             	mov    %eax,(%esp)
f0101a60:	e8 1d f7 ff ff       	call   f0101182 <page_insert>
f0101a65:	85 c0                	test   %eax,%eax
f0101a67:	74 24                	je     f0101a8d <mem_init+0x861>
f0101a69:	c7 44 24 0c 54 45 10 	movl   $0xf0104554,0xc(%esp)
f0101a70:	f0 
f0101a71:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101a78:	f0 
f0101a79:	c7 44 24 04 1b 03 00 	movl   $0x31b,0x4(%esp)
f0101a80:	00 
f0101a81:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101a88:	e8 07 e6 ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101a8d:	8b 0d a4 79 11 f0    	mov    0xf01179a4,%ecx
f0101a93:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101a96:	a1 a8 79 11 f0       	mov    0xf01179a8,%eax
f0101a9b:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101a9e:	8b 11                	mov    (%ecx),%edx
f0101aa0:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101aa6:	89 d8                	mov    %ebx,%eax
f0101aa8:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0101aab:	c1 f8 03             	sar    $0x3,%eax
f0101aae:	c1 e0 0c             	shl    $0xc,%eax
f0101ab1:	39 c2                	cmp    %eax,%edx
f0101ab3:	74 24                	je     f0101ad9 <mem_init+0x8ad>
f0101ab5:	c7 44 24 0c 84 45 10 	movl   $0xf0104584,0xc(%esp)
f0101abc:	f0 
f0101abd:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101ac4:	f0 
f0101ac5:	c7 44 24 04 1c 03 00 	movl   $0x31c,0x4(%esp)
f0101acc:	00 
f0101acd:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101ad4:	e8 bb e5 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101ad9:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ade:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ae1:	e8 d8 ee ff ff       	call   f01009be <check_va2pa>
f0101ae6:	89 fa                	mov    %edi,%edx
f0101ae8:	2b 55 d0             	sub    -0x30(%ebp),%edx
f0101aeb:	c1 fa 03             	sar    $0x3,%edx
f0101aee:	c1 e2 0c             	shl    $0xc,%edx
f0101af1:	39 d0                	cmp    %edx,%eax
f0101af3:	74 24                	je     f0101b19 <mem_init+0x8ed>
f0101af5:	c7 44 24 0c ac 45 10 	movl   $0xf01045ac,0xc(%esp)
f0101afc:	f0 
f0101afd:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101b04:	f0 
f0101b05:	c7 44 24 04 1d 03 00 	movl   $0x31d,0x4(%esp)
f0101b0c:	00 
f0101b0d:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101b14:	e8 7b e5 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0101b19:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101b1e:	74 24                	je     f0101b44 <mem_init+0x918>
f0101b20:	c7 44 24 0c fa 4b 10 	movl   $0xf0104bfa,0xc(%esp)
f0101b27:	f0 
f0101b28:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101b2f:	f0 
f0101b30:	c7 44 24 04 1e 03 00 	movl   $0x31e,0x4(%esp)
f0101b37:	00 
f0101b38:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101b3f:	e8 50 e5 ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0101b44:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101b49:	74 24                	je     f0101b6f <mem_init+0x943>
f0101b4b:	c7 44 24 0c 0b 4c 10 	movl   $0xf0104c0b,0xc(%esp)
f0101b52:	f0 
f0101b53:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101b5a:	f0 
f0101b5b:	c7 44 24 04 1f 03 00 	movl   $0x31f,0x4(%esp)
f0101b62:	00 
f0101b63:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101b6a:	e8 25 e5 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b6f:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101b76:	00 
f0101b77:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101b7e:	00 
f0101b7f:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101b83:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101b86:	89 14 24             	mov    %edx,(%esp)
f0101b89:	e8 f4 f5 ff ff       	call   f0101182 <page_insert>
f0101b8e:	85 c0                	test   %eax,%eax
f0101b90:	74 24                	je     f0101bb6 <mem_init+0x98a>
f0101b92:	c7 44 24 0c dc 45 10 	movl   $0xf01045dc,0xc(%esp)
f0101b99:	f0 
f0101b9a:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101ba1:	f0 
f0101ba2:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f0101ba9:	00 
f0101baa:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101bb1:	e8 de e4 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bb6:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bbb:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0101bc0:	e8 f9 ed ff ff       	call   f01009be <check_va2pa>
f0101bc5:	89 f2                	mov    %esi,%edx
f0101bc7:	2b 15 a8 79 11 f0    	sub    0xf01179a8,%edx
f0101bcd:	c1 fa 03             	sar    $0x3,%edx
f0101bd0:	c1 e2 0c             	shl    $0xc,%edx
f0101bd3:	39 d0                	cmp    %edx,%eax
f0101bd5:	74 24                	je     f0101bfb <mem_init+0x9cf>
f0101bd7:	c7 44 24 0c 18 46 10 	movl   $0xf0104618,0xc(%esp)
f0101bde:	f0 
f0101bdf:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101be6:	f0 
f0101be7:	c7 44 24 04 23 03 00 	movl   $0x323,0x4(%esp)
f0101bee:	00 
f0101bef:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101bf6:	e8 99 e4 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101bfb:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c00:	74 24                	je     f0101c26 <mem_init+0x9fa>
f0101c02:	c7 44 24 0c 1c 4c 10 	movl   $0xf0104c1c,0xc(%esp)
f0101c09:	f0 
f0101c0a:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101c11:	f0 
f0101c12:	c7 44 24 04 24 03 00 	movl   $0x324,0x4(%esp)
f0101c19:	00 
f0101c1a:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101c21:	e8 6e e4 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101c26:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c2d:	e8 66 f2 ff ff       	call   f0100e98 <page_alloc>
f0101c32:	85 c0                	test   %eax,%eax
f0101c34:	74 24                	je     f0101c5a <mem_init+0xa2e>
f0101c36:	c7 44 24 0c a8 4b 10 	movl   $0xf0104ba8,0xc(%esp)
f0101c3d:	f0 
f0101c3e:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101c45:	f0 
f0101c46:	c7 44 24 04 27 03 00 	movl   $0x327,0x4(%esp)
f0101c4d:	00 
f0101c4e:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101c55:	e8 3a e4 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c5a:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101c61:	00 
f0101c62:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101c69:	00 
f0101c6a:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101c6e:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0101c73:	89 04 24             	mov    %eax,(%esp)
f0101c76:	e8 07 f5 ff ff       	call   f0101182 <page_insert>
f0101c7b:	85 c0                	test   %eax,%eax
f0101c7d:	74 24                	je     f0101ca3 <mem_init+0xa77>
f0101c7f:	c7 44 24 0c dc 45 10 	movl   $0xf01045dc,0xc(%esp)
f0101c86:	f0 
f0101c87:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101c8e:	f0 
f0101c8f:	c7 44 24 04 2a 03 00 	movl   $0x32a,0x4(%esp)
f0101c96:	00 
f0101c97:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101c9e:	e8 f1 e3 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ca3:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ca8:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0101cad:	e8 0c ed ff ff       	call   f01009be <check_va2pa>
f0101cb2:	89 f2                	mov    %esi,%edx
f0101cb4:	2b 15 a8 79 11 f0    	sub    0xf01179a8,%edx
f0101cba:	c1 fa 03             	sar    $0x3,%edx
f0101cbd:	c1 e2 0c             	shl    $0xc,%edx
f0101cc0:	39 d0                	cmp    %edx,%eax
f0101cc2:	74 24                	je     f0101ce8 <mem_init+0xabc>
f0101cc4:	c7 44 24 0c 18 46 10 	movl   $0xf0104618,0xc(%esp)
f0101ccb:	f0 
f0101ccc:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101cd3:	f0 
f0101cd4:	c7 44 24 04 2b 03 00 	movl   $0x32b,0x4(%esp)
f0101cdb:	00 
f0101cdc:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101ce3:	e8 ac e3 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101ce8:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101ced:	74 24                	je     f0101d13 <mem_init+0xae7>
f0101cef:	c7 44 24 0c 1c 4c 10 	movl   $0xf0104c1c,0xc(%esp)
f0101cf6:	f0 
f0101cf7:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101cfe:	f0 
f0101cff:	c7 44 24 04 2c 03 00 	movl   $0x32c,0x4(%esp)
f0101d06:	00 
f0101d07:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101d0e:	e8 81 e3 ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101d13:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101d1a:	e8 79 f1 ff ff       	call   f0100e98 <page_alloc>
f0101d1f:	85 c0                	test   %eax,%eax
f0101d21:	74 24                	je     f0101d47 <mem_init+0xb1b>
f0101d23:	c7 44 24 0c a8 4b 10 	movl   $0xf0104ba8,0xc(%esp)
f0101d2a:	f0 
f0101d2b:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101d32:	f0 
f0101d33:	c7 44 24 04 30 03 00 	movl   $0x330,0x4(%esp)
f0101d3a:	00 
f0101d3b:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101d42:	e8 4d e3 ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101d47:	8b 15 a4 79 11 f0    	mov    0xf01179a4,%edx
f0101d4d:	8b 02                	mov    (%edx),%eax
f0101d4f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101d54:	89 c1                	mov    %eax,%ecx
f0101d56:	c1 e9 0c             	shr    $0xc,%ecx
f0101d59:	3b 0d a0 79 11 f0    	cmp    0xf01179a0,%ecx
f0101d5f:	72 20                	jb     f0101d81 <mem_init+0xb55>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101d61:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101d65:	c7 44 24 08 44 43 10 	movl   $0xf0104344,0x8(%esp)
f0101d6c:	f0 
f0101d6d:	c7 44 24 04 33 03 00 	movl   $0x333,0x4(%esp)
f0101d74:	00 
f0101d75:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101d7c:	e8 13 e3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101d81:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101d86:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101d89:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101d90:	00 
f0101d91:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101d98:	00 
f0101d99:	89 14 24             	mov    %edx,(%esp)
f0101d9c:	e8 bc f1 ff ff       	call   f0100f5d <pgdir_walk>
f0101da1:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101da4:	83 c2 04             	add    $0x4,%edx
f0101da7:	39 d0                	cmp    %edx,%eax
f0101da9:	74 24                	je     f0101dcf <mem_init+0xba3>
f0101dab:	c7 44 24 0c 48 46 10 	movl   $0xf0104648,0xc(%esp)
f0101db2:	f0 
f0101db3:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101dba:	f0 
f0101dbb:	c7 44 24 04 34 03 00 	movl   $0x334,0x4(%esp)
f0101dc2:	00 
f0101dc3:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101dca:	e8 c5 e2 ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101dcf:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101dd6:	00 
f0101dd7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101dde:	00 
f0101ddf:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101de3:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0101de8:	89 04 24             	mov    %eax,(%esp)
f0101deb:	e8 92 f3 ff ff       	call   f0101182 <page_insert>
f0101df0:	85 c0                	test   %eax,%eax
f0101df2:	74 24                	je     f0101e18 <mem_init+0xbec>
f0101df4:	c7 44 24 0c 88 46 10 	movl   $0xf0104688,0xc(%esp)
f0101dfb:	f0 
f0101dfc:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101e03:	f0 
f0101e04:	c7 44 24 04 37 03 00 	movl   $0x337,0x4(%esp)
f0101e0b:	00 
f0101e0c:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101e13:	e8 7c e2 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101e18:	8b 0d a4 79 11 f0    	mov    0xf01179a4,%ecx
f0101e1e:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0101e21:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e26:	89 c8                	mov    %ecx,%eax
f0101e28:	e8 91 eb ff ff       	call   f01009be <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101e2d:	89 f2                	mov    %esi,%edx
f0101e2f:	2b 15 a8 79 11 f0    	sub    0xf01179a8,%edx
f0101e35:	c1 fa 03             	sar    $0x3,%edx
f0101e38:	c1 e2 0c             	shl    $0xc,%edx
f0101e3b:	39 d0                	cmp    %edx,%eax
f0101e3d:	74 24                	je     f0101e63 <mem_init+0xc37>
f0101e3f:	c7 44 24 0c 18 46 10 	movl   $0xf0104618,0xc(%esp)
f0101e46:	f0 
f0101e47:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101e4e:	f0 
f0101e4f:	c7 44 24 04 38 03 00 	movl   $0x338,0x4(%esp)
f0101e56:	00 
f0101e57:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101e5e:	e8 31 e2 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101e63:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101e68:	74 24                	je     f0101e8e <mem_init+0xc62>
f0101e6a:	c7 44 24 0c 1c 4c 10 	movl   $0xf0104c1c,0xc(%esp)
f0101e71:	f0 
f0101e72:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101e79:	f0 
f0101e7a:	c7 44 24 04 39 03 00 	movl   $0x339,0x4(%esp)
f0101e81:	00 
f0101e82:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101e89:	e8 06 e2 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101e8e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101e95:	00 
f0101e96:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101e9d:	00 
f0101e9e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ea1:	89 04 24             	mov    %eax,(%esp)
f0101ea4:	e8 b4 f0 ff ff       	call   f0100f5d <pgdir_walk>
f0101ea9:	f6 00 04             	testb  $0x4,(%eax)
f0101eac:	75 24                	jne    f0101ed2 <mem_init+0xca6>
f0101eae:	c7 44 24 0c c8 46 10 	movl   $0xf01046c8,0xc(%esp)
f0101eb5:	f0 
f0101eb6:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101ebd:	f0 
f0101ebe:	c7 44 24 04 3a 03 00 	movl   $0x33a,0x4(%esp)
f0101ec5:	00 
f0101ec6:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101ecd:	e8 c2 e1 ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101ed2:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0101ed7:	f6 00 04             	testb  $0x4,(%eax)
f0101eda:	75 24                	jne    f0101f00 <mem_init+0xcd4>
f0101edc:	c7 44 24 0c 2d 4c 10 	movl   $0xf0104c2d,0xc(%esp)
f0101ee3:	f0 
f0101ee4:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101eeb:	f0 
f0101eec:	c7 44 24 04 3b 03 00 	movl   $0x33b,0x4(%esp)
f0101ef3:	00 
f0101ef4:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101efb:	e8 94 e1 ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101f00:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f07:	00 
f0101f08:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0101f0f:	00 
f0101f10:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101f14:	89 04 24             	mov    %eax,(%esp)
f0101f17:	e8 66 f2 ff ff       	call   f0101182 <page_insert>
f0101f1c:	85 c0                	test   %eax,%eax
f0101f1e:	78 24                	js     f0101f44 <mem_init+0xd18>
f0101f20:	c7 44 24 0c fc 46 10 	movl   $0xf01046fc,0xc(%esp)
f0101f27:	f0 
f0101f28:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101f2f:	f0 
f0101f30:	c7 44 24 04 3e 03 00 	movl   $0x33e,0x4(%esp)
f0101f37:	00 
f0101f38:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101f3f:	e8 50 e1 ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101f44:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f4b:	00 
f0101f4c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101f53:	00 
f0101f54:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101f58:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0101f5d:	89 04 24             	mov    %eax,(%esp)
f0101f60:	e8 1d f2 ff ff       	call   f0101182 <page_insert>
f0101f65:	85 c0                	test   %eax,%eax
f0101f67:	74 24                	je     f0101f8d <mem_init+0xd61>
f0101f69:	c7 44 24 0c 34 47 10 	movl   $0xf0104734,0xc(%esp)
f0101f70:	f0 
f0101f71:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101f78:	f0 
f0101f79:	c7 44 24 04 41 03 00 	movl   $0x341,0x4(%esp)
f0101f80:	00 
f0101f81:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101f88:	e8 07 e1 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101f8d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f94:	00 
f0101f95:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f9c:	00 
f0101f9d:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0101fa2:	89 04 24             	mov    %eax,(%esp)
f0101fa5:	e8 b3 ef ff ff       	call   f0100f5d <pgdir_walk>
f0101faa:	f6 00 04             	testb  $0x4,(%eax)
f0101fad:	74 24                	je     f0101fd3 <mem_init+0xda7>
f0101faf:	c7 44 24 0c 70 47 10 	movl   $0xf0104770,0xc(%esp)
f0101fb6:	f0 
f0101fb7:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0101fbe:	f0 
f0101fbf:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f0101fc6:	00 
f0101fc7:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0101fce:	e8 c1 e0 ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101fd3:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0101fd8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101fdb:	ba 00 00 00 00       	mov    $0x0,%edx
f0101fe0:	e8 d9 e9 ff ff       	call   f01009be <check_va2pa>
f0101fe5:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101fe8:	89 f8                	mov    %edi,%eax
f0101fea:	2b 05 a8 79 11 f0    	sub    0xf01179a8,%eax
f0101ff0:	c1 f8 03             	sar    $0x3,%eax
f0101ff3:	c1 e0 0c             	shl    $0xc,%eax
f0101ff6:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101ff9:	74 24                	je     f010201f <mem_init+0xdf3>
f0101ffb:	c7 44 24 0c a8 47 10 	movl   $0xf01047a8,0xc(%esp)
f0102002:	f0 
f0102003:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f010200a:	f0 
f010200b:	c7 44 24 04 45 03 00 	movl   $0x345,0x4(%esp)
f0102012:	00 
f0102013:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f010201a:	e8 75 e0 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010201f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102024:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102027:	e8 92 e9 ff ff       	call   f01009be <check_va2pa>
f010202c:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f010202f:	74 24                	je     f0102055 <mem_init+0xe29>
f0102031:	c7 44 24 0c d4 47 10 	movl   $0xf01047d4,0xc(%esp)
f0102038:	f0 
f0102039:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102040:	f0 
f0102041:	c7 44 24 04 46 03 00 	movl   $0x346,0x4(%esp)
f0102048:	00 
f0102049:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102050:	e8 3f e0 ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0102055:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f010205a:	74 24                	je     f0102080 <mem_init+0xe54>
f010205c:	c7 44 24 0c 43 4c 10 	movl   $0xf0104c43,0xc(%esp)
f0102063:	f0 
f0102064:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f010206b:	f0 
f010206c:	c7 44 24 04 48 03 00 	movl   $0x348,0x4(%esp)
f0102073:	00 
f0102074:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f010207b:	e8 14 e0 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102080:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102085:	74 24                	je     f01020ab <mem_init+0xe7f>
f0102087:	c7 44 24 0c 54 4c 10 	movl   $0xf0104c54,0xc(%esp)
f010208e:	f0 
f010208f:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102096:	f0 
f0102097:	c7 44 24 04 49 03 00 	movl   $0x349,0x4(%esp)
f010209e:	00 
f010209f:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01020a6:	e8 e9 df ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f01020ab:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01020b2:	e8 e1 ed ff ff       	call   f0100e98 <page_alloc>
f01020b7:	85 c0                	test   %eax,%eax
f01020b9:	74 04                	je     f01020bf <mem_init+0xe93>
f01020bb:	39 c6                	cmp    %eax,%esi
f01020bd:	74 24                	je     f01020e3 <mem_init+0xeb7>
f01020bf:	c7 44 24 0c 04 48 10 	movl   $0xf0104804,0xc(%esp)
f01020c6:	f0 
f01020c7:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f01020ce:	f0 
f01020cf:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f01020d6:	00 
f01020d7:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01020de:	e8 b1 df ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f01020e3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01020ea:	00 
f01020eb:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f01020f0:	89 04 24             	mov    %eax,(%esp)
f01020f3:	e8 36 f0 ff ff       	call   f010112e <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01020f8:	8b 15 a4 79 11 f0    	mov    0xf01179a4,%edx
f01020fe:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0102101:	ba 00 00 00 00       	mov    $0x0,%edx
f0102106:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102109:	e8 b0 e8 ff ff       	call   f01009be <check_va2pa>
f010210e:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102111:	74 24                	je     f0102137 <mem_init+0xf0b>
f0102113:	c7 44 24 0c 28 48 10 	movl   $0xf0104828,0xc(%esp)
f010211a:	f0 
f010211b:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102122:	f0 
f0102123:	c7 44 24 04 50 03 00 	movl   $0x350,0x4(%esp)
f010212a:	00 
f010212b:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102132:	e8 5d df ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102137:	ba 00 10 00 00       	mov    $0x1000,%edx
f010213c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010213f:	e8 7a e8 ff ff       	call   f01009be <check_va2pa>
f0102144:	89 fa                	mov    %edi,%edx
f0102146:	2b 15 a8 79 11 f0    	sub    0xf01179a8,%edx
f010214c:	c1 fa 03             	sar    $0x3,%edx
f010214f:	c1 e2 0c             	shl    $0xc,%edx
f0102152:	39 d0                	cmp    %edx,%eax
f0102154:	74 24                	je     f010217a <mem_init+0xf4e>
f0102156:	c7 44 24 0c d4 47 10 	movl   $0xf01047d4,0xc(%esp)
f010215d:	f0 
f010215e:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102165:	f0 
f0102166:	c7 44 24 04 51 03 00 	movl   $0x351,0x4(%esp)
f010216d:	00 
f010216e:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102175:	e8 1a df ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f010217a:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f010217f:	74 24                	je     f01021a5 <mem_init+0xf79>
f0102181:	c7 44 24 0c fa 4b 10 	movl   $0xf0104bfa,0xc(%esp)
f0102188:	f0 
f0102189:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102190:	f0 
f0102191:	c7 44 24 04 52 03 00 	movl   $0x352,0x4(%esp)
f0102198:	00 
f0102199:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01021a0:	e8 ef de ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01021a5:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01021aa:	74 24                	je     f01021d0 <mem_init+0xfa4>
f01021ac:	c7 44 24 0c 54 4c 10 	movl   $0xf0104c54,0xc(%esp)
f01021b3:	f0 
f01021b4:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f01021bb:	f0 
f01021bc:	c7 44 24 04 53 03 00 	movl   $0x353,0x4(%esp)
f01021c3:	00 
f01021c4:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01021cb:	e8 c4 de ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01021d0:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01021d7:	00 
f01021d8:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01021db:	89 0c 24             	mov    %ecx,(%esp)
f01021de:	e8 4b ef ff ff       	call   f010112e <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01021e3:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f01021e8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01021eb:	ba 00 00 00 00       	mov    $0x0,%edx
f01021f0:	e8 c9 e7 ff ff       	call   f01009be <check_va2pa>
f01021f5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01021f8:	74 24                	je     f010221e <mem_init+0xff2>
f01021fa:	c7 44 24 0c 28 48 10 	movl   $0xf0104828,0xc(%esp)
f0102201:	f0 
f0102202:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102209:	f0 
f010220a:	c7 44 24 04 57 03 00 	movl   $0x357,0x4(%esp)
f0102211:	00 
f0102212:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102219:	e8 76 de ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f010221e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102223:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102226:	e8 93 e7 ff ff       	call   f01009be <check_va2pa>
f010222b:	83 f8 ff             	cmp    $0xffffffff,%eax
f010222e:	74 24                	je     f0102254 <mem_init+0x1028>
f0102230:	c7 44 24 0c 4c 48 10 	movl   $0xf010484c,0xc(%esp)
f0102237:	f0 
f0102238:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f010223f:	f0 
f0102240:	c7 44 24 04 58 03 00 	movl   $0x358,0x4(%esp)
f0102247:	00 
f0102248:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f010224f:	e8 40 de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102254:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102259:	74 24                	je     f010227f <mem_init+0x1053>
f010225b:	c7 44 24 0c 65 4c 10 	movl   $0xf0104c65,0xc(%esp)
f0102262:	f0 
f0102263:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f010226a:	f0 
f010226b:	c7 44 24 04 59 03 00 	movl   $0x359,0x4(%esp)
f0102272:	00 
f0102273:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f010227a:	e8 15 de ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f010227f:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102284:	74 24                	je     f01022aa <mem_init+0x107e>
f0102286:	c7 44 24 0c 54 4c 10 	movl   $0xf0104c54,0xc(%esp)
f010228d:	f0 
f010228e:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102295:	f0 
f0102296:	c7 44 24 04 5a 03 00 	movl   $0x35a,0x4(%esp)
f010229d:	00 
f010229e:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01022a5:	e8 ea dd ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f01022aa:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01022b1:	e8 e2 eb ff ff       	call   f0100e98 <page_alloc>
f01022b6:	85 c0                	test   %eax,%eax
f01022b8:	74 04                	je     f01022be <mem_init+0x1092>
f01022ba:	39 c7                	cmp    %eax,%edi
f01022bc:	74 24                	je     f01022e2 <mem_init+0x10b6>
f01022be:	c7 44 24 0c 74 48 10 	movl   $0xf0104874,0xc(%esp)
f01022c5:	f0 
f01022c6:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f01022cd:	f0 
f01022ce:	c7 44 24 04 5d 03 00 	movl   $0x35d,0x4(%esp)
f01022d5:	00 
f01022d6:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01022dd:	e8 b2 dd ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01022e2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01022e9:	e8 aa eb ff ff       	call   f0100e98 <page_alloc>
f01022ee:	85 c0                	test   %eax,%eax
f01022f0:	74 24                	je     f0102316 <mem_init+0x10ea>
f01022f2:	c7 44 24 0c a8 4b 10 	movl   $0xf0104ba8,0xc(%esp)
f01022f9:	f0 
f01022fa:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102301:	f0 
f0102302:	c7 44 24 04 60 03 00 	movl   $0x360,0x4(%esp)
f0102309:	00 
f010230a:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102311:	e8 7e dd ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102316:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f010231b:	8b 08                	mov    (%eax),%ecx
f010231d:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102323:	89 da                	mov    %ebx,%edx
f0102325:	2b 15 a8 79 11 f0    	sub    0xf01179a8,%edx
f010232b:	c1 fa 03             	sar    $0x3,%edx
f010232e:	c1 e2 0c             	shl    $0xc,%edx
f0102331:	39 d1                	cmp    %edx,%ecx
f0102333:	74 24                	je     f0102359 <mem_init+0x112d>
f0102335:	c7 44 24 0c 84 45 10 	movl   $0xf0104584,0xc(%esp)
f010233c:	f0 
f010233d:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102344:	f0 
f0102345:	c7 44 24 04 63 03 00 	movl   $0x363,0x4(%esp)
f010234c:	00 
f010234d:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102354:	e8 3b dd ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102359:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f010235f:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102364:	74 24                	je     f010238a <mem_init+0x115e>
f0102366:	c7 44 24 0c 0b 4c 10 	movl   $0xf0104c0b,0xc(%esp)
f010236d:	f0 
f010236e:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102375:	f0 
f0102376:	c7 44 24 04 65 03 00 	movl   $0x365,0x4(%esp)
f010237d:	00 
f010237e:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102385:	e8 0a dd ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f010238a:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102390:	89 1c 24             	mov    %ebx,(%esp)
f0102393:	e8 8d eb ff ff       	call   f0100f25 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102398:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010239f:	00 
f01023a0:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f01023a7:	00 
f01023a8:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f01023ad:	89 04 24             	mov    %eax,(%esp)
f01023b0:	e8 a8 eb ff ff       	call   f0100f5d <pgdir_walk>
f01023b5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01023b8:	8b 0d a4 79 11 f0    	mov    0xf01179a4,%ecx
f01023be:	8b 51 04             	mov    0x4(%ecx),%edx
f01023c1:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01023c7:	89 55 d4             	mov    %edx,-0x2c(%ebp)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01023ca:	8b 15 a0 79 11 f0    	mov    0xf01179a0,%edx
f01023d0:	89 55 c8             	mov    %edx,-0x38(%ebp)
f01023d3:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01023d6:	c1 ea 0c             	shr    $0xc,%edx
f01023d9:	89 55 d0             	mov    %edx,-0x30(%ebp)
f01023dc:	8b 55 c8             	mov    -0x38(%ebp),%edx
f01023df:	39 55 d0             	cmp    %edx,-0x30(%ebp)
f01023e2:	72 23                	jb     f0102407 <mem_init+0x11db>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01023e4:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01023e7:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01023eb:	c7 44 24 08 44 43 10 	movl   $0xf0104344,0x8(%esp)
f01023f2:	f0 
f01023f3:	c7 44 24 04 6c 03 00 	movl   $0x36c,0x4(%esp)
f01023fa:	00 
f01023fb:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102402:	e8 8d dc ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102407:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010240a:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0102410:	39 d0                	cmp    %edx,%eax
f0102412:	74 24                	je     f0102438 <mem_init+0x120c>
f0102414:	c7 44 24 0c 76 4c 10 	movl   $0xf0104c76,0xc(%esp)
f010241b:	f0 
f010241c:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102423:	f0 
f0102424:	c7 44 24 04 6d 03 00 	movl   $0x36d,0x4(%esp)
f010242b:	00 
f010242c:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102433:	e8 5c dc ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102438:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f010243f:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102445:	89 d8                	mov    %ebx,%eax
f0102447:	2b 05 a8 79 11 f0    	sub    0xf01179a8,%eax
f010244d:	c1 f8 03             	sar    $0x3,%eax
f0102450:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102453:	89 c1                	mov    %eax,%ecx
f0102455:	c1 e9 0c             	shr    $0xc,%ecx
f0102458:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f010245b:	77 20                	ja     f010247d <mem_init+0x1251>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010245d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102461:	c7 44 24 08 44 43 10 	movl   $0xf0104344,0x8(%esp)
f0102468:	f0 
f0102469:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102470:	00 
f0102471:	c7 04 24 38 4a 10 f0 	movl   $0xf0104a38,(%esp)
f0102478:	e8 17 dc ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f010247d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102484:	00 
f0102485:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f010248c:	00 
	return (void *)(pa + KERNBASE);
f010248d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102492:	89 04 24             	mov    %eax,(%esp)
f0102495:	e8 8c 14 00 00       	call   f0103926 <memset>
	page_free(pp0);
f010249a:	89 1c 24             	mov    %ebx,(%esp)
f010249d:	e8 83 ea ff ff       	call   f0100f25 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01024a2:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01024a9:	00 
f01024aa:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01024b1:	00 
f01024b2:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f01024b7:	89 04 24             	mov    %eax,(%esp)
f01024ba:	e8 9e ea ff ff       	call   f0100f5d <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01024bf:	89 da                	mov    %ebx,%edx
f01024c1:	2b 15 a8 79 11 f0    	sub    0xf01179a8,%edx
f01024c7:	c1 fa 03             	sar    $0x3,%edx
f01024ca:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024cd:	89 d0                	mov    %edx,%eax
f01024cf:	c1 e8 0c             	shr    $0xc,%eax
f01024d2:	3b 05 a0 79 11 f0    	cmp    0xf01179a0,%eax
f01024d8:	72 20                	jb     f01024fa <mem_init+0x12ce>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024da:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01024de:	c7 44 24 08 44 43 10 	movl   $0xf0104344,0x8(%esp)
f01024e5:	f0 
f01024e6:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01024ed:	00 
f01024ee:	c7 04 24 38 4a 10 f0 	movl   $0xf0104a38,(%esp)
f01024f5:	e8 9a db ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f01024fa:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102500:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102503:	f6 82 00 00 00 f0 01 	testb  $0x1,-0x10000000(%edx)
f010250a:	75 11                	jne    f010251d <mem_init+0x12f1>
f010250c:	8d 82 04 00 00 f0    	lea    -0xffffffc(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102512:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102518:	f6 00 01             	testb  $0x1,(%eax)
f010251b:	74 24                	je     f0102541 <mem_init+0x1315>
f010251d:	c7 44 24 0c 8e 4c 10 	movl   $0xf0104c8e,0xc(%esp)
f0102524:	f0 
f0102525:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f010252c:	f0 
f010252d:	c7 44 24 04 77 03 00 	movl   $0x377,0x4(%esp)
f0102534:	00 
f0102535:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f010253c:	e8 53 db ff ff       	call   f0100094 <_panic>
f0102541:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102544:	39 d0                	cmp    %edx,%eax
f0102546:	75 d0                	jne    f0102518 <mem_init+0x12ec>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102548:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f010254d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102553:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// give free list back
	page_free_list = fl;
f0102559:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f010255c:	89 0d 80 75 11 f0    	mov    %ecx,0xf0117580

	// free the pages we took
	page_free(pp0);
f0102562:	89 1c 24             	mov    %ebx,(%esp)
f0102565:	e8 bb e9 ff ff       	call   f0100f25 <page_free>
	page_free(pp1);
f010256a:	89 3c 24             	mov    %edi,(%esp)
f010256d:	e8 b3 e9 ff ff       	call   f0100f25 <page_free>
	page_free(pp2);
f0102572:	89 34 24             	mov    %esi,(%esp)
f0102575:	e8 ab e9 ff ff       	call   f0100f25 <page_free>

	cprintf("check_page() succeeded!\n");
f010257a:	c7 04 24 a5 4c 10 f0 	movl   $0xf0104ca5,(%esp)
f0102581:	e8 a8 07 00 00       	call   f0102d2e <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:

	boot_map_region(kern_pgdir,UPAGES,npages * sizeof (struct Page),PADDR (pages), PTE_U| PTE_P);
f0102586:	a1 a8 79 11 f0       	mov    0xf01179a8,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010258b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102590:	77 20                	ja     f01025b2 <mem_init+0x1386>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102592:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102596:	c7 44 24 08 2c 44 10 	movl   $0xf010442c,0x8(%esp)
f010259d:	f0 
f010259e:	c7 44 24 04 ad 00 00 	movl   $0xad,0x4(%esp)
f01025a5:	00 
f01025a6:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01025ad:	e8 e2 da ff ff       	call   f0100094 <_panic>
f01025b2:	8b 0d a0 79 11 f0    	mov    0xf01179a0,%ecx
f01025b8:	c1 e1 03             	shl    $0x3,%ecx
f01025bb:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f01025c2:	00 
	return (physaddr_t)kva - KERNBASE;
f01025c3:	05 00 00 00 10       	add    $0x10000000,%eax
f01025c8:	89 04 24             	mov    %eax,(%esp)
f01025cb:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01025d0:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f01025d5:	e8 67 ea ff ff       	call   f0101041 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01025da:	b8 00 d0 10 f0       	mov    $0xf010d000,%eax
f01025df:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01025e4:	77 20                	ja     f0102606 <mem_init+0x13da>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01025e6:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01025ea:	c7 44 24 08 2c 44 10 	movl   $0xf010442c,0x8(%esp)
f01025f1:	f0 
f01025f2:	c7 44 24 04 b9 00 00 	movl   $0xb9,0x4(%esp)
f01025f9:	00 
f01025fa:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102601:	e8 8e da ff ff       	call   f0100094 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region (kern_pgdir,KSTACKTOP - KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_W| PTE_P);
f0102606:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f010260d:	00 
f010260e:	c7 04 24 00 d0 10 00 	movl   $0x10d000,(%esp)
f0102615:	b9 00 80 00 00       	mov    $0x8000,%ecx
f010261a:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f010261f:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0102624:	e8 18 ea ff ff       	call   f0101041 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region (kern_pgdir,KERNBASE,0xffffffff-KERNBASE+1, 0,PTE_W| PTE_P);
f0102629:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102630:	00 
f0102631:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102638:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f010263d:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102642:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0102647:	e8 f5 e9 ff ff       	call   f0101041 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f010264c:	8b 1d a4 79 11 f0    	mov    0xf01179a4,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
f0102652:	8b 15 a0 79 11 f0    	mov    0xf01179a0,%edx
f0102658:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f010265b:	8d 3c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%edi
	for (i = 0; i < n; i += PGSIZE)
f0102662:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
f0102668:	74 79                	je     f01026e3 <mem_init+0x14b7>
f010266a:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010266f:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102675:	89 d8                	mov    %ebx,%eax
f0102677:	e8 42 e3 ff ff       	call   f01009be <check_va2pa>
f010267c:	8b 15 a8 79 11 f0    	mov    0xf01179a8,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102682:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102688:	77 20                	ja     f01026aa <mem_init+0x147e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010268a:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010268e:	c7 44 24 08 2c 44 10 	movl   $0xf010442c,0x8(%esp)
f0102695:	f0 
f0102696:	c7 44 24 04 c3 02 00 	movl   $0x2c3,0x4(%esp)
f010269d:	00 
f010269e:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01026a5:	e8 ea d9 ff ff       	call   f0100094 <_panic>
f01026aa:	8d 94 32 00 00 00 10 	lea    0x10000000(%edx,%esi,1),%edx
f01026b1:	39 d0                	cmp    %edx,%eax
f01026b3:	74 24                	je     f01026d9 <mem_init+0x14ad>
f01026b5:	c7 44 24 0c 98 48 10 	movl   $0xf0104898,0xc(%esp)
f01026bc:	f0 
f01026bd:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f01026c4:	f0 
f01026c5:	c7 44 24 04 c3 02 00 	movl   $0x2c3,0x4(%esp)
f01026cc:	00 
f01026cd:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01026d4:	e8 bb d9 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01026d9:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01026df:	39 f7                	cmp    %esi,%edi
f01026e1:	77 8c                	ja     f010266f <mem_init+0x1443>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01026e3:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01026e6:	c1 e7 0c             	shl    $0xc,%edi
f01026e9:	85 ff                	test   %edi,%edi
f01026eb:	74 44                	je     f0102731 <mem_init+0x1505>
f01026ed:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01026f2:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01026f8:	89 d8                	mov    %ebx,%eax
f01026fa:	e8 bf e2 ff ff       	call   f01009be <check_va2pa>
f01026ff:	39 c6                	cmp    %eax,%esi
f0102701:	74 24                	je     f0102727 <mem_init+0x14fb>
f0102703:	c7 44 24 0c cc 48 10 	movl   $0xf01048cc,0xc(%esp)
f010270a:	f0 
f010270b:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102712:	f0 
f0102713:	c7 44 24 04 c8 02 00 	movl   $0x2c8,0x4(%esp)
f010271a:	00 
f010271b:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102722:	e8 6d d9 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102727:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010272d:	39 fe                	cmp    %edi,%esi
f010272f:	72 c1                	jb     f01026f2 <mem_init+0x14c6>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102731:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f0102736:	89 d8                	mov    %ebx,%eax
f0102738:	e8 81 e2 ff ff       	call   f01009be <check_va2pa>
f010273d:	be 00 90 bf ef       	mov    $0xefbf9000,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102742:	bf 00 d0 10 f0       	mov    $0xf010d000,%edi
f0102747:	81 c7 00 70 40 20    	add    $0x20407000,%edi
f010274d:	8d 14 37             	lea    (%edi,%esi,1),%edx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102750:	39 c2                	cmp    %eax,%edx
f0102752:	74 24                	je     f0102778 <mem_init+0x154c>
f0102754:	c7 44 24 0c f4 48 10 	movl   $0xf01048f4,0xc(%esp)
f010275b:	f0 
f010275c:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102763:	f0 
f0102764:	c7 44 24 04 cc 02 00 	movl   $0x2cc,0x4(%esp)
f010276b:	00 
f010276c:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102773:	e8 1c d9 ff ff       	call   f0100094 <_panic>
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102778:	81 fe 00 00 c0 ef    	cmp    $0xefc00000,%esi
f010277e:	0f 85 27 05 00 00    	jne    f0102cab <mem_init+0x1a7f>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102784:	ba 00 00 80 ef       	mov    $0xef800000,%edx
f0102789:	89 d8                	mov    %ebx,%eax
f010278b:	e8 2e e2 ff ff       	call   f01009be <check_va2pa>
f0102790:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102793:	74 24                	je     f01027b9 <mem_init+0x158d>
f0102795:	c7 44 24 0c 3c 49 10 	movl   $0xf010493c,0xc(%esp)
f010279c:	f0 
f010279d:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f01027a4:	f0 
f01027a5:	c7 44 24 04 cd 02 00 	movl   $0x2cd,0x4(%esp)
f01027ac:	00 
f01027ad:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01027b4:	e8 db d8 ff ff       	call   f0100094 <_panic>
f01027b9:	b8 00 00 00 00       	mov    $0x0,%eax

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01027be:	8d 90 44 fc ff ff    	lea    -0x3bc(%eax),%edx
f01027c4:	83 fa 02             	cmp    $0x2,%edx
f01027c7:	77 2e                	ja     f01027f7 <mem_init+0x15cb>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f01027c9:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f01027cd:	0f 85 aa 00 00 00    	jne    f010287d <mem_init+0x1651>
f01027d3:	c7 44 24 0c be 4c 10 	movl   $0xf0104cbe,0xc(%esp)
f01027da:	f0 
f01027db:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f01027e2:	f0 
f01027e3:	c7 44 24 04 d5 02 00 	movl   $0x2d5,0x4(%esp)
f01027ea:	00 
f01027eb:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01027f2:	e8 9d d8 ff ff       	call   f0100094 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01027f7:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01027fc:	76 55                	jbe    f0102853 <mem_init+0x1627>
				assert(pgdir[i] & PTE_P);
f01027fe:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0102801:	f6 c2 01             	test   $0x1,%dl
f0102804:	75 24                	jne    f010282a <mem_init+0x15fe>
f0102806:	c7 44 24 0c be 4c 10 	movl   $0xf0104cbe,0xc(%esp)
f010280d:	f0 
f010280e:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102815:	f0 
f0102816:	c7 44 24 04 d9 02 00 	movl   $0x2d9,0x4(%esp)
f010281d:	00 
f010281e:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102825:	e8 6a d8 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f010282a:	f6 c2 02             	test   $0x2,%dl
f010282d:	75 4e                	jne    f010287d <mem_init+0x1651>
f010282f:	c7 44 24 0c cf 4c 10 	movl   $0xf0104ccf,0xc(%esp)
f0102836:	f0 
f0102837:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f010283e:	f0 
f010283f:	c7 44 24 04 da 02 00 	movl   $0x2da,0x4(%esp)
f0102846:	00 
f0102847:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f010284e:	e8 41 d8 ff ff       	call   f0100094 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102853:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0102857:	74 24                	je     f010287d <mem_init+0x1651>
f0102859:	c7 44 24 0c e0 4c 10 	movl   $0xf0104ce0,0xc(%esp)
f0102860:	f0 
f0102861:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102868:	f0 
f0102869:	c7 44 24 04 dc 02 00 	movl   $0x2dc,0x4(%esp)
f0102870:	00 
f0102871:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102878:	e8 17 d8 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f010287d:	83 c0 01             	add    $0x1,%eax
f0102880:	3d 00 04 00 00       	cmp    $0x400,%eax
f0102885:	0f 85 33 ff ff ff    	jne    f01027be <mem_init+0x1592>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f010288b:	c7 04 24 6c 49 10 f0 	movl   $0xf010496c,(%esp)
f0102892:	e8 97 04 00 00       	call   f0102d2e <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102897:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010289c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01028a1:	77 20                	ja     f01028c3 <mem_init+0x1697>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028a3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01028a7:	c7 44 24 08 2c 44 10 	movl   $0xf010442c,0x8(%esp)
f01028ae:	f0 
f01028af:	c7 44 24 04 cd 00 00 	movl   $0xcd,0x4(%esp)
f01028b6:	00 
f01028b7:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f01028be:	e8 d1 d7 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01028c3:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01028c8:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01028cb:	b8 00 00 00 00       	mov    $0x0,%eax
f01028d0:	e8 8c e1 ff ff       	call   f0100a61 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f01028d5:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
f01028d8:	0d 23 00 05 80       	or     $0x80050023,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f01028dd:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f01028e0:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01028e3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01028ea:	e8 a9 e5 ff ff       	call   f0100e98 <page_alloc>
f01028ef:	89 c6                	mov    %eax,%esi
f01028f1:	85 c0                	test   %eax,%eax
f01028f3:	75 24                	jne    f0102919 <mem_init+0x16ed>
f01028f5:	c7 44 24 0c fd 4a 10 	movl   $0xf0104afd,0xc(%esp)
f01028fc:	f0 
f01028fd:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102904:	f0 
f0102905:	c7 44 24 04 92 03 00 	movl   $0x392,0x4(%esp)
f010290c:	00 
f010290d:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102914:	e8 7b d7 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0102919:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102920:	e8 73 e5 ff ff       	call   f0100e98 <page_alloc>
f0102925:	89 c7                	mov    %eax,%edi
f0102927:	85 c0                	test   %eax,%eax
f0102929:	75 24                	jne    f010294f <mem_init+0x1723>
f010292b:	c7 44 24 0c 13 4b 10 	movl   $0xf0104b13,0xc(%esp)
f0102932:	f0 
f0102933:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f010293a:	f0 
f010293b:	c7 44 24 04 93 03 00 	movl   $0x393,0x4(%esp)
f0102942:	00 
f0102943:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f010294a:	e8 45 d7 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f010294f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102956:	e8 3d e5 ff ff       	call   f0100e98 <page_alloc>
f010295b:	89 c3                	mov    %eax,%ebx
f010295d:	85 c0                	test   %eax,%eax
f010295f:	75 24                	jne    f0102985 <mem_init+0x1759>
f0102961:	c7 44 24 0c 29 4b 10 	movl   $0xf0104b29,0xc(%esp)
f0102968:	f0 
f0102969:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102970:	f0 
f0102971:	c7 44 24 04 94 03 00 	movl   $0x394,0x4(%esp)
f0102978:	00 
f0102979:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102980:	e8 0f d7 ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f0102985:	89 34 24             	mov    %esi,(%esp)
f0102988:	e8 98 e5 ff ff       	call   f0100f25 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f010298d:	89 f8                	mov    %edi,%eax
f010298f:	2b 05 a8 79 11 f0    	sub    0xf01179a8,%eax
f0102995:	c1 f8 03             	sar    $0x3,%eax
f0102998:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010299b:	89 c2                	mov    %eax,%edx
f010299d:	c1 ea 0c             	shr    $0xc,%edx
f01029a0:	3b 15 a0 79 11 f0    	cmp    0xf01179a0,%edx
f01029a6:	72 20                	jb     f01029c8 <mem_init+0x179c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01029a8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01029ac:	c7 44 24 08 44 43 10 	movl   $0xf0104344,0x8(%esp)
f01029b3:	f0 
f01029b4:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01029bb:	00 
f01029bc:	c7 04 24 38 4a 10 f0 	movl   $0xf0104a38,(%esp)
f01029c3:	e8 cc d6 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01029c8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01029cf:	00 
f01029d0:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01029d7:	00 
	return (void *)(pa + KERNBASE);
f01029d8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01029dd:	89 04 24             	mov    %eax,(%esp)
f01029e0:	e8 41 0f 00 00       	call   f0103926 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01029e5:	89 d8                	mov    %ebx,%eax
f01029e7:	2b 05 a8 79 11 f0    	sub    0xf01179a8,%eax
f01029ed:	c1 f8 03             	sar    $0x3,%eax
f01029f0:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01029f3:	89 c2                	mov    %eax,%edx
f01029f5:	c1 ea 0c             	shr    $0xc,%edx
f01029f8:	3b 15 a0 79 11 f0    	cmp    0xf01179a0,%edx
f01029fe:	72 20                	jb     f0102a20 <mem_init+0x17f4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a00:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102a04:	c7 44 24 08 44 43 10 	movl   $0xf0104344,0x8(%esp)
f0102a0b:	f0 
f0102a0c:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102a13:	00 
f0102a14:	c7 04 24 38 4a 10 f0 	movl   $0xf0104a38,(%esp)
f0102a1b:	e8 74 d6 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102a20:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102a27:	00 
f0102a28:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102a2f:	00 
	return (void *)(pa + KERNBASE);
f0102a30:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102a35:	89 04 24             	mov    %eax,(%esp)
f0102a38:	e8 e9 0e 00 00       	call   f0103926 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102a3d:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102a44:	00 
f0102a45:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102a4c:	00 
f0102a4d:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102a51:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0102a56:	89 04 24             	mov    %eax,(%esp)
f0102a59:	e8 24 e7 ff ff       	call   f0101182 <page_insert>
	assert(pp1->pp_ref == 1);
f0102a5e:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102a63:	74 24                	je     f0102a89 <mem_init+0x185d>
f0102a65:	c7 44 24 0c fa 4b 10 	movl   $0xf0104bfa,0xc(%esp)
f0102a6c:	f0 
f0102a6d:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102a74:	f0 
f0102a75:	c7 44 24 04 99 03 00 	movl   $0x399,0x4(%esp)
f0102a7c:	00 
f0102a7d:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102a84:	e8 0b d6 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102a89:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102a90:	01 01 01 
f0102a93:	74 24                	je     f0102ab9 <mem_init+0x188d>
f0102a95:	c7 44 24 0c 8c 49 10 	movl   $0xf010498c,0xc(%esp)
f0102a9c:	f0 
f0102a9d:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102aa4:	f0 
f0102aa5:	c7 44 24 04 9a 03 00 	movl   $0x39a,0x4(%esp)
f0102aac:	00 
f0102aad:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102ab4:	e8 db d5 ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102ab9:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102ac0:	00 
f0102ac1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102ac8:	00 
f0102ac9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102acd:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0102ad2:	89 04 24             	mov    %eax,(%esp)
f0102ad5:	e8 a8 e6 ff ff       	call   f0101182 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102ada:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102ae1:	02 02 02 
f0102ae4:	74 24                	je     f0102b0a <mem_init+0x18de>
f0102ae6:	c7 44 24 0c b0 49 10 	movl   $0xf01049b0,0xc(%esp)
f0102aed:	f0 
f0102aee:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102af5:	f0 
f0102af6:	c7 44 24 04 9c 03 00 	movl   $0x39c,0x4(%esp)
f0102afd:	00 
f0102afe:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102b05:	e8 8a d5 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102b0a:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102b0f:	74 24                	je     f0102b35 <mem_init+0x1909>
f0102b11:	c7 44 24 0c 1c 4c 10 	movl   $0xf0104c1c,0xc(%esp)
f0102b18:	f0 
f0102b19:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102b20:	f0 
f0102b21:	c7 44 24 04 9d 03 00 	movl   $0x39d,0x4(%esp)
f0102b28:	00 
f0102b29:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102b30:	e8 5f d5 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102b35:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102b3a:	74 24                	je     f0102b60 <mem_init+0x1934>
f0102b3c:	c7 44 24 0c 65 4c 10 	movl   $0xf0104c65,0xc(%esp)
f0102b43:	f0 
f0102b44:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102b4b:	f0 
f0102b4c:	c7 44 24 04 9e 03 00 	movl   $0x39e,0x4(%esp)
f0102b53:	00 
f0102b54:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102b5b:	e8 34 d5 ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102b60:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102b67:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102b6a:	89 d8                	mov    %ebx,%eax
f0102b6c:	2b 05 a8 79 11 f0    	sub    0xf01179a8,%eax
f0102b72:	c1 f8 03             	sar    $0x3,%eax
f0102b75:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b78:	89 c2                	mov    %eax,%edx
f0102b7a:	c1 ea 0c             	shr    $0xc,%edx
f0102b7d:	3b 15 a0 79 11 f0    	cmp    0xf01179a0,%edx
f0102b83:	72 20                	jb     f0102ba5 <mem_init+0x1979>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b85:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102b89:	c7 44 24 08 44 43 10 	movl   $0xf0104344,0x8(%esp)
f0102b90:	f0 
f0102b91:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102b98:	00 
f0102b99:	c7 04 24 38 4a 10 f0 	movl   $0xf0104a38,(%esp)
f0102ba0:	e8 ef d4 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102ba5:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102bac:	03 03 03 
f0102baf:	74 24                	je     f0102bd5 <mem_init+0x19a9>
f0102bb1:	c7 44 24 0c d4 49 10 	movl   $0xf01049d4,0xc(%esp)
f0102bb8:	f0 
f0102bb9:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102bc0:	f0 
f0102bc1:	c7 44 24 04 a0 03 00 	movl   $0x3a0,0x4(%esp)
f0102bc8:	00 
f0102bc9:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102bd0:	e8 bf d4 ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102bd5:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102bdc:	00 
f0102bdd:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0102be2:	89 04 24             	mov    %eax,(%esp)
f0102be5:	e8 44 e5 ff ff       	call   f010112e <page_remove>
	assert(pp2->pp_ref == 0);
f0102bea:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102bef:	74 24                	je     f0102c15 <mem_init+0x19e9>
f0102bf1:	c7 44 24 0c 54 4c 10 	movl   $0xf0104c54,0xc(%esp)
f0102bf8:	f0 
f0102bf9:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102c00:	f0 
f0102c01:	c7 44 24 04 a2 03 00 	movl   $0x3a2,0x4(%esp)
f0102c08:	00 
f0102c09:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102c10:	e8 7f d4 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102c15:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0102c1a:	8b 08                	mov    (%eax),%ecx
f0102c1c:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102c22:	89 f2                	mov    %esi,%edx
f0102c24:	2b 15 a8 79 11 f0    	sub    0xf01179a8,%edx
f0102c2a:	c1 fa 03             	sar    $0x3,%edx
f0102c2d:	c1 e2 0c             	shl    $0xc,%edx
f0102c30:	39 d1                	cmp    %edx,%ecx
f0102c32:	74 24                	je     f0102c58 <mem_init+0x1a2c>
f0102c34:	c7 44 24 0c 84 45 10 	movl   $0xf0104584,0xc(%esp)
f0102c3b:	f0 
f0102c3c:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102c43:	f0 
f0102c44:	c7 44 24 04 a5 03 00 	movl   $0x3a5,0x4(%esp)
f0102c4b:	00 
f0102c4c:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102c53:	e8 3c d4 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102c58:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102c5e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102c63:	74 24                	je     f0102c89 <mem_init+0x1a5d>
f0102c65:	c7 44 24 0c 0b 4c 10 	movl   $0xf0104c0b,0xc(%esp)
f0102c6c:	f0 
f0102c6d:	c7 44 24 08 52 4a 10 	movl   $0xf0104a52,0x8(%esp)
f0102c74:	f0 
f0102c75:	c7 44 24 04 a7 03 00 	movl   $0x3a7,0x4(%esp)
f0102c7c:	00 
f0102c7d:	c7 04 24 2c 4a 10 f0 	movl   $0xf0104a2c,(%esp)
f0102c84:	e8 0b d4 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102c89:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102c8f:	89 34 24             	mov    %esi,(%esp)
f0102c92:	e8 8e e2 ff ff       	call   f0100f25 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102c97:	c7 04 24 00 4a 10 f0 	movl   $0xf0104a00,(%esp)
f0102c9e:	e8 8b 00 00 00       	call   f0102d2e <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102ca3:	83 c4 3c             	add    $0x3c,%esp
f0102ca6:	5b                   	pop    %ebx
f0102ca7:	5e                   	pop    %esi
f0102ca8:	5f                   	pop    %edi
f0102ca9:	5d                   	pop    %ebp
f0102caa:	c3                   	ret    
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102cab:	89 f2                	mov    %esi,%edx
f0102cad:	89 d8                	mov    %ebx,%eax
f0102caf:	e8 0a dd ff ff       	call   f01009be <check_va2pa>
f0102cb4:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102cba:	e9 8e fa ff ff       	jmp    f010274d <mem_init+0x1521>
	...

f0102cc0 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102cc0:	55                   	push   %ebp
f0102cc1:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102cc3:	ba 70 00 00 00       	mov    $0x70,%edx
f0102cc8:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ccb:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102ccc:	b2 71                	mov    $0x71,%dl
f0102cce:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102ccf:	0f b6 c0             	movzbl %al,%eax
}
f0102cd2:	5d                   	pop    %ebp
f0102cd3:	c3                   	ret    

f0102cd4 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102cd4:	55                   	push   %ebp
f0102cd5:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102cd7:	ba 70 00 00 00       	mov    $0x70,%edx
f0102cdc:	8b 45 08             	mov    0x8(%ebp),%eax
f0102cdf:	ee                   	out    %al,(%dx)
f0102ce0:	b2 71                	mov    $0x71,%dl
f0102ce2:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ce5:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102ce6:	5d                   	pop    %ebp
f0102ce7:	c3                   	ret    

f0102ce8 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102ce8:	55                   	push   %ebp
f0102ce9:	89 e5                	mov    %esp,%ebp
f0102ceb:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0102cee:	8b 45 08             	mov    0x8(%ebp),%eax
f0102cf1:	89 04 24             	mov    %eax,(%esp)
f0102cf4:	e8 f8 d8 ff ff       	call   f01005f1 <cputchar>
	*cnt++;
}
f0102cf9:	c9                   	leave  
f0102cfa:	c3                   	ret    

f0102cfb <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102cfb:	55                   	push   %ebp
f0102cfc:	89 e5                	mov    %esp,%ebp
f0102cfe:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0102d01:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102d08:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d0b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102d0f:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d12:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102d16:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102d19:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d1d:	c7 04 24 e8 2c 10 f0 	movl   $0xf0102ce8,(%esp)
f0102d24:	e8 61 04 00 00       	call   f010318a <vprintfmt>
	return cnt;
}
f0102d29:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102d2c:	c9                   	leave  
f0102d2d:	c3                   	ret    

f0102d2e <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102d2e:	55                   	push   %ebp
f0102d2f:	89 e5                	mov    %esp,%ebp
f0102d31:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102d34:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102d37:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d3b:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d3e:	89 04 24             	mov    %eax,(%esp)
f0102d41:	e8 b5 ff ff ff       	call   f0102cfb <vcprintf>
	va_end(ap);

	return cnt;
}
f0102d46:	c9                   	leave  
f0102d47:	c3                   	ret    

f0102d48 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102d48:	55                   	push   %ebp
f0102d49:	89 e5                	mov    %esp,%ebp
f0102d4b:	57                   	push   %edi
f0102d4c:	56                   	push   %esi
f0102d4d:	53                   	push   %ebx
f0102d4e:	83 ec 10             	sub    $0x10,%esp
f0102d51:	89 c3                	mov    %eax,%ebx
f0102d53:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0102d56:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0102d59:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102d5c:	8b 0a                	mov    (%edx),%ecx
f0102d5e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102d61:	8b 00                	mov    (%eax),%eax
f0102d63:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102d66:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f0102d6d:	eb 77                	jmp    f0102de6 <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f0102d6f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102d72:	01 c8                	add    %ecx,%eax
f0102d74:	bf 02 00 00 00       	mov    $0x2,%edi
f0102d79:	99                   	cltd   
f0102d7a:	f7 ff                	idiv   %edi
f0102d7c:	89 c2                	mov    %eax,%edx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102d7e:	eb 01                	jmp    f0102d81 <stab_binsearch+0x39>
			m--;
f0102d80:	4a                   	dec    %edx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102d81:	39 ca                	cmp    %ecx,%edx
f0102d83:	7c 1d                	jl     f0102da2 <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0102d85:	6b fa 0c             	imul   $0xc,%edx,%edi
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102d88:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f0102d8d:	39 f7                	cmp    %esi,%edi
f0102d8f:	75 ef                	jne    f0102d80 <stab_binsearch+0x38>
f0102d91:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102d94:	6b fa 0c             	imul   $0xc,%edx,%edi
f0102d97:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f0102d9b:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0102d9e:	73 18                	jae    f0102db8 <stab_binsearch+0x70>
f0102da0:	eb 05                	jmp    f0102da7 <stab_binsearch+0x5f>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102da2:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0102da5:	eb 3f                	jmp    f0102de6 <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0102da7:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0102daa:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0102dac:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102daf:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102db6:	eb 2e                	jmp    f0102de6 <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102db8:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0102dbb:	76 15                	jbe    f0102dd2 <stab_binsearch+0x8a>
			*region_right = m - 1;
f0102dbd:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0102dc0:	4f                   	dec    %edi
f0102dc1:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0102dc4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102dc7:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102dc9:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102dd0:	eb 14                	jmp    f0102de6 <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102dd2:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0102dd5:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0102dd8:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f0102dda:	ff 45 0c             	incl   0xc(%ebp)
f0102ddd:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102ddf:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0102de6:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0102de9:	7e 84                	jle    f0102d6f <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102deb:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0102def:	75 0d                	jne    f0102dfe <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0102df1:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102df4:	8b 02                	mov    (%edx),%eax
f0102df6:	48                   	dec    %eax
f0102df7:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102dfa:	89 01                	mov    %eax,(%ecx)
f0102dfc:	eb 22                	jmp    f0102e20 <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102dfe:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102e01:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102e03:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102e06:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102e08:	eb 01                	jmp    f0102e0b <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102e0a:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102e0b:	39 c1                	cmp    %eax,%ecx
f0102e0d:	7d 0c                	jge    f0102e1b <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0102e0f:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0102e12:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f0102e17:	39 f2                	cmp    %esi,%edx
f0102e19:	75 ef                	jne    f0102e0a <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102e1b:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102e1e:	89 02                	mov    %eax,(%edx)
	}
}
f0102e20:	83 c4 10             	add    $0x10,%esp
f0102e23:	5b                   	pop    %ebx
f0102e24:	5e                   	pop    %esi
f0102e25:	5f                   	pop    %edi
f0102e26:	5d                   	pop    %ebp
f0102e27:	c3                   	ret    

f0102e28 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102e28:	55                   	push   %ebp
f0102e29:	89 e5                	mov    %esp,%ebp
f0102e2b:	83 ec 38             	sub    $0x38,%esp
f0102e2e:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0102e31:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0102e34:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0102e37:	8b 75 08             	mov    0x8(%ebp),%esi
f0102e3a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102e3d:	c7 03 04 41 10 f0    	movl   $0xf0104104,(%ebx)
	info->eip_line = 0;
f0102e43:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102e4a:	c7 43 08 04 41 10 f0 	movl   $0xf0104104,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102e51:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102e58:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102e5b:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102e62:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102e68:	76 12                	jbe    f0102e7c <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102e6a:	b8 e1 cf 10 f0       	mov    $0xf010cfe1,%eax
f0102e6f:	3d ad b1 10 f0       	cmp    $0xf010b1ad,%eax
f0102e74:	0f 86 9b 01 00 00    	jbe    f0103015 <debuginfo_eip+0x1ed>
f0102e7a:	eb 1c                	jmp    f0102e98 <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102e7c:	c7 44 24 08 ee 4c 10 	movl   $0xf0104cee,0x8(%esp)
f0102e83:	f0 
f0102e84:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0102e8b:	00 
f0102e8c:	c7 04 24 fb 4c 10 f0 	movl   $0xf0104cfb,(%esp)
f0102e93:	e8 fc d1 ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102e98:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102e9d:	80 3d e0 cf 10 f0 00 	cmpb   $0x0,0xf010cfe0
f0102ea4:	0f 85 77 01 00 00    	jne    f0103021 <debuginfo_eip+0x1f9>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102eaa:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102eb1:	b8 ac b1 10 f0       	mov    $0xf010b1ac,%eax
f0102eb6:	2d 18 4f 10 f0       	sub    $0xf0104f18,%eax
f0102ebb:	c1 f8 02             	sar    $0x2,%eax
f0102ebe:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102ec4:	83 e8 01             	sub    $0x1,%eax
f0102ec7:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102eca:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102ece:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0102ed5:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102ed8:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102edb:	b8 18 4f 10 f0       	mov    $0xf0104f18,%eax
f0102ee0:	e8 63 fe ff ff       	call   f0102d48 <stab_binsearch>
	if (lfile == 0)
f0102ee5:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0102ee8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0102eed:	85 d2                	test   %edx,%edx
f0102eef:	0f 84 2c 01 00 00    	je     f0103021 <debuginfo_eip+0x1f9>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102ef5:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0102ef8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102efb:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102efe:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102f02:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0102f09:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102f0c:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102f0f:	b8 18 4f 10 f0       	mov    $0xf0104f18,%eax
f0102f14:	e8 2f fe ff ff       	call   f0102d48 <stab_binsearch>

	if (lfun <= rfun) {
f0102f19:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0102f1c:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0102f1f:	7f 2e                	jg     f0102f4f <debuginfo_eip+0x127>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102f21:	6b c7 0c             	imul   $0xc,%edi,%eax
f0102f24:	8d 90 18 4f 10 f0    	lea    -0xfefb0e8(%eax),%edx
f0102f2a:	8b 80 18 4f 10 f0    	mov    -0xfefb0e8(%eax),%eax
f0102f30:	b9 e1 cf 10 f0       	mov    $0xf010cfe1,%ecx
f0102f35:	81 e9 ad b1 10 f0    	sub    $0xf010b1ad,%ecx
f0102f3b:	39 c8                	cmp    %ecx,%eax
f0102f3d:	73 08                	jae    f0102f47 <debuginfo_eip+0x11f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102f3f:	05 ad b1 10 f0       	add    $0xf010b1ad,%eax
f0102f44:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102f47:	8b 42 08             	mov    0x8(%edx),%eax
f0102f4a:	89 43 10             	mov    %eax,0x10(%ebx)
f0102f4d:	eb 06                	jmp    f0102f55 <debuginfo_eip+0x12d>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102f4f:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102f52:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102f55:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0102f5c:	00 
f0102f5d:	8b 43 08             	mov    0x8(%ebx),%eax
f0102f60:	89 04 24             	mov    %eax,(%esp)
f0102f63:	e8 97 09 00 00       	call   f01038ff <strfind>
f0102f68:	2b 43 08             	sub    0x8(%ebx),%eax
f0102f6b:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102f6e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102f71:	39 d7                	cmp    %edx,%edi
f0102f73:	7c 5f                	jl     f0102fd4 <debuginfo_eip+0x1ac>
	       && stabs[lline].n_type != N_SOL
f0102f75:	89 f8                	mov    %edi,%eax
f0102f77:	6b cf 0c             	imul   $0xc,%edi,%ecx
f0102f7a:	80 b9 1c 4f 10 f0 84 	cmpb   $0x84,-0xfefb0e4(%ecx)
f0102f81:	75 18                	jne    f0102f9b <debuginfo_eip+0x173>
f0102f83:	eb 30                	jmp    f0102fb5 <debuginfo_eip+0x18d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0102f85:	83 ef 01             	sub    $0x1,%edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102f88:	39 fa                	cmp    %edi,%edx
f0102f8a:	7f 48                	jg     f0102fd4 <debuginfo_eip+0x1ac>
	       && stabs[lline].n_type != N_SOL
f0102f8c:	89 f8                	mov    %edi,%eax
f0102f8e:	8d 0c 7f             	lea    (%edi,%edi,2),%ecx
f0102f91:	80 3c 8d 1c 4f 10 f0 	cmpb   $0x84,-0xfefb0e4(,%ecx,4)
f0102f98:	84 
f0102f99:	74 1a                	je     f0102fb5 <debuginfo_eip+0x18d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102f9b:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102f9e:	8d 04 85 18 4f 10 f0 	lea    -0xfefb0e8(,%eax,4),%eax
f0102fa5:	80 78 04 64          	cmpb   $0x64,0x4(%eax)
f0102fa9:	75 da                	jne    f0102f85 <debuginfo_eip+0x15d>
f0102fab:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0102faf:	74 d4                	je     f0102f85 <debuginfo_eip+0x15d>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102fb1:	39 fa                	cmp    %edi,%edx
f0102fb3:	7f 1f                	jg     f0102fd4 <debuginfo_eip+0x1ac>
f0102fb5:	6b ff 0c             	imul   $0xc,%edi,%edi
f0102fb8:	8b 87 18 4f 10 f0    	mov    -0xfefb0e8(%edi),%eax
f0102fbe:	ba e1 cf 10 f0       	mov    $0xf010cfe1,%edx
f0102fc3:	81 ea ad b1 10 f0    	sub    $0xf010b1ad,%edx
f0102fc9:	39 d0                	cmp    %edx,%eax
f0102fcb:	73 07                	jae    f0102fd4 <debuginfo_eip+0x1ac>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102fcd:	05 ad b1 10 f0       	add    $0xf010b1ad,%eax
f0102fd2:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102fd4:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102fd7:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0102fda:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102fdf:	39 ca                	cmp    %ecx,%edx
f0102fe1:	7d 3e                	jge    f0103021 <debuginfo_eip+0x1f9>
		for (lline = lfun + 1;
f0102fe3:	83 c2 01             	add    $0x1,%edx
f0102fe6:	39 d1                	cmp    %edx,%ecx
f0102fe8:	7e 37                	jle    f0103021 <debuginfo_eip+0x1f9>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102fea:	6b f2 0c             	imul   $0xc,%edx,%esi
f0102fed:	80 be 1c 4f 10 f0 a0 	cmpb   $0xa0,-0xfefb0e4(%esi)
f0102ff4:	75 2b                	jne    f0103021 <debuginfo_eip+0x1f9>
		     lline++)
			info->eip_fn_narg++;
f0102ff6:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0102ffa:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102ffd:	39 d1                	cmp    %edx,%ecx
f0102fff:	7e 1b                	jle    f010301c <debuginfo_eip+0x1f4>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103001:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0103004:	80 3c 85 1c 4f 10 f0 	cmpb   $0xa0,-0xfefb0e4(,%eax,4)
f010300b:	a0 
f010300c:	74 e8                	je     f0102ff6 <debuginfo_eip+0x1ce>
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f010300e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103013:	eb 0c                	jmp    f0103021 <debuginfo_eip+0x1f9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103015:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010301a:	eb 05                	jmp    f0103021 <debuginfo_eip+0x1f9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f010301c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103021:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0103024:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0103027:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010302a:	89 ec                	mov    %ebp,%esp
f010302c:	5d                   	pop    %ebp
f010302d:	c3                   	ret    
	...

f0103030 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103030:	55                   	push   %ebp
f0103031:	89 e5                	mov    %esp,%ebp
f0103033:	57                   	push   %edi
f0103034:	56                   	push   %esi
f0103035:	53                   	push   %ebx
f0103036:	83 ec 3c             	sub    $0x3c,%esp
f0103039:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010303c:	89 d7                	mov    %edx,%edi
f010303e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103041:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103044:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103047:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010304a:	8b 5d 14             	mov    0x14(%ebp),%ebx
f010304d:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103050:	b8 00 00 00 00       	mov    $0x0,%eax
f0103055:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0103058:	72 11                	jb     f010306b <printnum+0x3b>
f010305a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010305d:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103060:	76 09                	jbe    f010306b <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103062:	83 eb 01             	sub    $0x1,%ebx
f0103065:	85 db                	test   %ebx,%ebx
f0103067:	7f 51                	jg     f01030ba <printnum+0x8a>
f0103069:	eb 5e                	jmp    f01030c9 <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010306b:	89 74 24 10          	mov    %esi,0x10(%esp)
f010306f:	83 eb 01             	sub    $0x1,%ebx
f0103072:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103076:	8b 45 10             	mov    0x10(%ebp),%eax
f0103079:	89 44 24 08          	mov    %eax,0x8(%esp)
f010307d:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0103081:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0103085:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010308c:	00 
f010308d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103090:	89 04 24             	mov    %eax,(%esp)
f0103093:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103096:	89 44 24 04          	mov    %eax,0x4(%esp)
f010309a:	e8 e1 0a 00 00       	call   f0103b80 <__udivdi3>
f010309f:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01030a3:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01030a7:	89 04 24             	mov    %eax,(%esp)
f01030aa:	89 54 24 04          	mov    %edx,0x4(%esp)
f01030ae:	89 fa                	mov    %edi,%edx
f01030b0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01030b3:	e8 78 ff ff ff       	call   f0103030 <printnum>
f01030b8:	eb 0f                	jmp    f01030c9 <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01030ba:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01030be:	89 34 24             	mov    %esi,(%esp)
f01030c1:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01030c4:	83 eb 01             	sub    $0x1,%ebx
f01030c7:	75 f1                	jne    f01030ba <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01030c9:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01030cd:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01030d1:	8b 45 10             	mov    0x10(%ebp),%eax
f01030d4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01030d8:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01030df:	00 
f01030e0:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01030e3:	89 04 24             	mov    %eax,(%esp)
f01030e6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01030e9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01030ed:	e8 be 0b 00 00       	call   f0103cb0 <__umoddi3>
f01030f2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01030f6:	0f be 80 09 4d 10 f0 	movsbl -0xfefb2f7(%eax),%eax
f01030fd:	89 04 24             	mov    %eax,(%esp)
f0103100:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0103103:	83 c4 3c             	add    $0x3c,%esp
f0103106:	5b                   	pop    %ebx
f0103107:	5e                   	pop    %esi
f0103108:	5f                   	pop    %edi
f0103109:	5d                   	pop    %ebp
f010310a:	c3                   	ret    

f010310b <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f010310b:	55                   	push   %ebp
f010310c:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f010310e:	83 fa 01             	cmp    $0x1,%edx
f0103111:	7e 0e                	jle    f0103121 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103113:	8b 10                	mov    (%eax),%edx
f0103115:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103118:	89 08                	mov    %ecx,(%eax)
f010311a:	8b 02                	mov    (%edx),%eax
f010311c:	8b 52 04             	mov    0x4(%edx),%edx
f010311f:	eb 22                	jmp    f0103143 <getuint+0x38>
	else if (lflag)
f0103121:	85 d2                	test   %edx,%edx
f0103123:	74 10                	je     f0103135 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103125:	8b 10                	mov    (%eax),%edx
f0103127:	8d 4a 04             	lea    0x4(%edx),%ecx
f010312a:	89 08                	mov    %ecx,(%eax)
f010312c:	8b 02                	mov    (%edx),%eax
f010312e:	ba 00 00 00 00       	mov    $0x0,%edx
f0103133:	eb 0e                	jmp    f0103143 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103135:	8b 10                	mov    (%eax),%edx
f0103137:	8d 4a 04             	lea    0x4(%edx),%ecx
f010313a:	89 08                	mov    %ecx,(%eax)
f010313c:	8b 02                	mov    (%edx),%eax
f010313e:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103143:	5d                   	pop    %ebp
f0103144:	c3                   	ret    

f0103145 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103145:	55                   	push   %ebp
f0103146:	89 e5                	mov    %esp,%ebp
f0103148:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010314b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f010314f:	8b 10                	mov    (%eax),%edx
f0103151:	3b 50 04             	cmp    0x4(%eax),%edx
f0103154:	73 0a                	jae    f0103160 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103156:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103159:	88 0a                	mov    %cl,(%edx)
f010315b:	83 c2 01             	add    $0x1,%edx
f010315e:	89 10                	mov    %edx,(%eax)
}
f0103160:	5d                   	pop    %ebp
f0103161:	c3                   	ret    

f0103162 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103162:	55                   	push   %ebp
f0103163:	89 e5                	mov    %esp,%ebp
f0103165:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0103168:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010316b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010316f:	8b 45 10             	mov    0x10(%ebp),%eax
f0103172:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103176:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103179:	89 44 24 04          	mov    %eax,0x4(%esp)
f010317d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103180:	89 04 24             	mov    %eax,(%esp)
f0103183:	e8 02 00 00 00       	call   f010318a <vprintfmt>
	va_end(ap);
}
f0103188:	c9                   	leave  
f0103189:	c3                   	ret    

f010318a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010318a:	55                   	push   %ebp
f010318b:	89 e5                	mov    %esp,%ebp
f010318d:	57                   	push   %edi
f010318e:	56                   	push   %esi
f010318f:	53                   	push   %ebx
f0103190:	83 ec 3c             	sub    $0x3c,%esp
f0103193:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0103196:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103199:	e9 bb 00 00 00       	jmp    f0103259 <vprintfmt+0xcf>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010319e:	85 c0                	test   %eax,%eax
f01031a0:	0f 84 63 04 00 00    	je     f0103609 <vprintfmt+0x47f>
				return;
			if (ch =='\033'){//if this is Escape character  and this if is char color set.
f01031a6:	83 f8 1b             	cmp    $0x1b,%eax
f01031a9:	0f 85 9a 00 00 00    	jne    f0103249 <vprintfmt+0xbf>
				int temp_color_no=0;
				ch = *(unsigned char *) fmt++;
f01031af:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01031b2:	83 c3 02             	add    $0x2,%ebx
				while (ch != 'm') 
f01031b5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01031b8:	80 78 01 6d          	cmpb   $0x6d,0x1(%eax)
f01031bc:	0f 84 81 00 00 00    	je     f0103243 <vprintfmt+0xb9>
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
				return;
			if (ch =='\033'){//if this is Escape character  and this if is char color set.
				int temp_color_no=0;
f01031c2:	ba 00 00 00 00       	mov    $0x0,%edx
				ch = *(unsigned char *) fmt++;
				while (ch != 'm') 
				{
					ch = *(unsigned char *) fmt++;
f01031c7:	0f b6 03             	movzbl (%ebx),%eax
f01031ca:	83 c3 01             	add    $0x1,%ebx
					if ( ch !=';' && ch!='m')
f01031cd:	83 f8 6d             	cmp    $0x6d,%eax
f01031d0:	0f 95 c1             	setne  %cl
f01031d3:	83 f8 3b             	cmp    $0x3b,%eax
f01031d6:	74 0d                	je     f01031e5 <vprintfmt+0x5b>
f01031d8:	84 c9                	test   %cl,%cl
f01031da:	74 09                	je     f01031e5 <vprintfmt+0x5b>
						temp_color_no=temp_color_no*10+ch-'0';
f01031dc:	8d 14 92             	lea    (%edx,%edx,4),%edx
f01031df:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
f01031e3:	eb 55                	jmp    f010323a <vprintfmt+0xb0>
					else if ( ch==';' || ch=='m'){
f01031e5:	83 f8 3b             	cmp    $0x3b,%eax
f01031e8:	74 05                	je     f01031ef <vprintfmt+0x65>
f01031ea:	83 f8 6d             	cmp    $0x6d,%eax
f01031ed:	75 4b                	jne    f010323a <vprintfmt+0xb0>
						if ( temp_color_no >=30 && temp_color_no<40){// Foreground colors
f01031ef:	89 d6                	mov    %edx,%esi
f01031f1:	8d 7a e2             	lea    -0x1e(%edx),%edi
f01031f4:	83 ff 09             	cmp    $0x9,%edi
f01031f7:	77 16                	ja     f010320f <vprintfmt+0x85>
							char_color = (char_color&0xf0) + (temp_color_no-30);						
f01031f9:	8b 3d 00 73 11 f0    	mov    0xf0117300,%edi
f01031ff:	81 e7 f0 00 00 00    	and    $0xf0,%edi
f0103205:	8d 7c 3a e2          	lea    -0x1e(%edx,%edi,1),%edi
f0103209:	89 3d 00 73 11 f0    	mov    %edi,0xf0117300
							}
						if ( temp_color_no >=40 && temp_color_no<50){// Background colors
f010320f:	83 ee 28             	sub    $0x28,%esi
f0103212:	83 fe 09             	cmp    $0x9,%esi
f0103215:	77 1e                	ja     f0103235 <vprintfmt+0xab>
							char_color = (char_color&0x0f) + ((temp_color_no-40)<<4);
f0103217:	8b 35 00 73 11 f0    	mov    0xf0117300,%esi
f010321d:	83 e6 0f             	and    $0xf,%esi
f0103220:	83 ea 28             	sub    $0x28,%edx
f0103223:	c1 e2 04             	shl    $0x4,%edx
f0103226:	01 f2                	add    %esi,%edx
f0103228:	89 15 00 73 11 f0    	mov    %edx,0xf0117300
						}
						//cprintf("0x%o ,",char_color);
						temp_color_no=0;
f010322e:	ba 00 00 00 00       	mov    $0x0,%edx
f0103233:	eb 05                	jmp    f010323a <vprintfmt+0xb0>
f0103235:	ba 00 00 00 00       	mov    $0x0,%edx
			if (ch == '\0')
				return;
			if (ch =='\033'){//if this is Escape character  and this if is char color set.
				int temp_color_no=0;
				ch = *(unsigned char *) fmt++;
				while (ch != 'm') 
f010323a:	84 c9                	test   %cl,%cl
f010323c:	75 89                	jne    f01031c7 <vprintfmt+0x3d>
						}
						//cprintf("0x%o ,",char_color);
						temp_color_no=0;
					}
				}
				if (ch == 'm')
f010323e:	83 f8 6d             	cmp    $0x6d,%eax
f0103241:	75 06                	jne    f0103249 <vprintfmt+0xbf>
					ch = *(unsigned char *) fmt++;
f0103243:	0f b6 03             	movzbl (%ebx),%eax
f0103246:	83 c3 01             	add    $0x1,%ebx
				
			}
			putch(ch, putdat);
f0103249:	8b 55 0c             	mov    0xc(%ebp),%edx
f010324c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103250:	89 04 24             	mov    %eax,(%esp)
f0103253:	ff 55 08             	call   *0x8(%ebp)
f0103256:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103259:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010325c:	0f b6 03             	movzbl (%ebx),%eax
f010325f:	83 c3 01             	add    $0x1,%ebx
f0103262:	83 f8 25             	cmp    $0x25,%eax
f0103265:	0f 85 33 ff ff ff    	jne    f010319e <vprintfmt+0x14>
f010326b:	c6 45 e0 20          	movb   $0x20,-0x20(%ebp)
f010326f:	bf 00 00 00 00       	mov    $0x0,%edi
f0103274:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0103279:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0103280:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103285:	eb 23                	jmp    f01032aa <vprintfmt+0x120>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103287:	89 c3                	mov    %eax,%ebx

		// flag to pad on the right
		case '-':
			padc = '-';
f0103289:	c6 45 e0 2d          	movb   $0x2d,-0x20(%ebp)
f010328d:	eb 1b                	jmp    f01032aa <vprintfmt+0x120>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010328f:	89 c3                	mov    %eax,%ebx
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103291:	c6 45 e0 30          	movb   $0x30,-0x20(%ebp)
f0103295:	eb 13                	jmp    f01032aa <vprintfmt+0x120>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103297:	89 c3                	mov    %eax,%ebx
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0103299:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f01032a0:	eb 08                	jmp    f01032aa <vprintfmt+0x120>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f01032a2:	89 75 dc             	mov    %esi,-0x24(%ebp)
f01032a5:	be ff ff ff ff       	mov    $0xffffffff,%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032aa:	0f b6 13             	movzbl (%ebx),%edx
f01032ad:	0f b6 c2             	movzbl %dl,%eax
f01032b0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01032b3:	8d 43 01             	lea    0x1(%ebx),%eax
f01032b6:	83 ea 23             	sub    $0x23,%edx
f01032b9:	80 fa 55             	cmp    $0x55,%dl
f01032bc:	0f 87 18 03 00 00    	ja     f01035da <vprintfmt+0x450>
f01032c2:	0f b6 d2             	movzbl %dl,%edx
f01032c5:	ff 24 95 94 4d 10 f0 	jmp    *-0xfefb26c(,%edx,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01032cc:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01032cf:	83 ee 30             	sub    $0x30,%esi
				ch = *fmt;
f01032d2:	0f be 53 01          	movsbl 0x1(%ebx),%edx
				if (ch < '0' || ch > '9')
f01032d6:	8d 5a d0             	lea    -0x30(%edx),%ebx
f01032d9:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032dc:	89 c3                	mov    %eax,%ebx
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f01032de:	83 7d e4 09          	cmpl   $0x9,-0x1c(%ebp)
f01032e2:	77 3b                	ja     f010331f <vprintfmt+0x195>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01032e4:	83 c0 01             	add    $0x1,%eax
				precision = precision * 10 + ch - '0';
f01032e7:	8d 1c b6             	lea    (%esi,%esi,4),%ebx
f01032ea:	8d 74 5a d0          	lea    -0x30(%edx,%ebx,2),%esi
				ch = *fmt;
f01032ee:	0f be 10             	movsbl (%eax),%edx
				if (ch < '0' || ch > '9')
f01032f1:	8d 5a d0             	lea    -0x30(%edx),%ebx
f01032f4:	83 fb 09             	cmp    $0x9,%ebx
f01032f7:	76 eb                	jbe    f01032e4 <vprintfmt+0x15a>
f01032f9:	eb 22                	jmp    f010331d <vprintfmt+0x193>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01032fb:	8b 55 14             	mov    0x14(%ebp),%edx
f01032fe:	8d 5a 04             	lea    0x4(%edx),%ebx
f0103301:	89 5d 14             	mov    %ebx,0x14(%ebp)
f0103304:	8b 32                	mov    (%edx),%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103306:	89 c3                	mov    %eax,%ebx
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103308:	eb 15                	jmp    f010331f <vprintfmt+0x195>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010330a:	89 c3                	mov    %eax,%ebx
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f010330c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103310:	79 98                	jns    f01032aa <vprintfmt+0x120>
f0103312:	eb 83                	jmp    f0103297 <vprintfmt+0x10d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103314:	89 c3                	mov    %eax,%ebx
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103316:	bf 01 00 00 00       	mov    $0x1,%edi
			goto reswitch;
f010331b:	eb 8d                	jmp    f01032aa <vprintfmt+0x120>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f010331d:	89 c3                	mov    %eax,%ebx
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f010331f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103323:	79 85                	jns    f01032aa <vprintfmt+0x120>
f0103325:	e9 78 ff ff ff       	jmp    f01032a2 <vprintfmt+0x118>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f010332a:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010332d:	89 c3                	mov    %eax,%ebx
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010332f:	e9 76 ff ff ff       	jmp    f01032aa <vprintfmt+0x120>
f0103334:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103337:	8b 45 14             	mov    0x14(%ebp),%eax
f010333a:	8d 50 04             	lea    0x4(%eax),%edx
f010333d:	89 55 14             	mov    %edx,0x14(%ebp)
f0103340:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103343:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103347:	8b 00                	mov    (%eax),%eax
f0103349:	89 04 24             	mov    %eax,(%esp)
f010334c:	ff 55 08             	call   *0x8(%ebp)
			break;
f010334f:	e9 05 ff ff ff       	jmp    f0103259 <vprintfmt+0xcf>
f0103354:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103357:	8b 45 14             	mov    0x14(%ebp),%eax
f010335a:	8d 50 04             	lea    0x4(%eax),%edx
f010335d:	89 55 14             	mov    %edx,0x14(%ebp)
f0103360:	8b 00                	mov    (%eax),%eax
f0103362:	89 c2                	mov    %eax,%edx
f0103364:	c1 fa 1f             	sar    $0x1f,%edx
f0103367:	31 d0                	xor    %edx,%eax
f0103369:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010336b:	83 f8 06             	cmp    $0x6,%eax
f010336e:	7f 0b                	jg     f010337b <vprintfmt+0x1f1>
f0103370:	8b 14 85 ec 4e 10 f0 	mov    -0xfefb114(,%eax,4),%edx
f0103377:	85 d2                	test   %edx,%edx
f0103379:	75 23                	jne    f010339e <vprintfmt+0x214>
				printfmt(putch, putdat, "error %d", err);
f010337b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010337f:	c7 44 24 08 21 4d 10 	movl   $0xf0104d21,0x8(%esp)
f0103386:	f0 
f0103387:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010338a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010338e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103391:	89 1c 24             	mov    %ebx,(%esp)
f0103394:	e8 c9 fd ff ff       	call   f0103162 <printfmt>
f0103399:	e9 bb fe ff ff       	jmp    f0103259 <vprintfmt+0xcf>
			else
				printfmt(putch, putdat, "%s", p);
f010339e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01033a2:	c7 44 24 08 64 4a 10 	movl   $0xf0104a64,0x8(%esp)
f01033a9:	f0 
f01033aa:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01033ad:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01033b1:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01033b4:	89 1c 24             	mov    %ebx,(%esp)
f01033b7:	e8 a6 fd ff ff       	call   f0103162 <printfmt>
f01033bc:	e9 98 fe ff ff       	jmp    f0103259 <vprintfmt+0xcf>
f01033c1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01033c4:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01033c7:	89 5d d8             	mov    %ebx,-0x28(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01033ca:	8b 45 14             	mov    0x14(%ebp),%eax
f01033cd:	8d 50 04             	lea    0x4(%eax),%edx
f01033d0:	89 55 14             	mov    %edx,0x14(%ebp)
f01033d3:	8b 18                	mov    (%eax),%ebx
				p = "(null)";
f01033d5:	85 db                	test   %ebx,%ebx
f01033d7:	b8 1a 4d 10 f0       	mov    $0xf0104d1a,%eax
f01033dc:	0f 44 d8             	cmove  %eax,%ebx
			if (width > 0 && padc != '-')
f01033df:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01033e3:	7e 06                	jle    f01033eb <vprintfmt+0x261>
f01033e5:	80 7d e0 2d          	cmpb   $0x2d,-0x20(%ebp)
f01033e9:	75 10                	jne    f01033fb <vprintfmt+0x271>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01033eb:	0f be 03             	movsbl (%ebx),%eax
f01033ee:	83 c3 01             	add    $0x1,%ebx
f01033f1:	85 c0                	test   %eax,%eax
f01033f3:	0f 85 82 00 00 00    	jne    f010347b <vprintfmt+0x2f1>
f01033f9:	eb 75                	jmp    f0103470 <vprintfmt+0x2e6>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01033fb:	89 74 24 04          	mov    %esi,0x4(%esp)
f01033ff:	89 1c 24             	mov    %ebx,(%esp)
f0103402:	e8 84 03 00 00       	call   f010378b <strnlen>
f0103407:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010340a:	29 c2                	sub    %eax,%edx
f010340c:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010340f:	85 d2                	test   %edx,%edx
f0103411:	7e d8                	jle    f01033eb <vprintfmt+0x261>
					putch(padc, putdat);
f0103413:	0f be 45 e0          	movsbl -0x20(%ebp),%eax
f0103417:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010341a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010341d:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103421:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103424:	89 04 24             	mov    %eax,(%esp)
f0103427:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010342a:	83 6d dc 01          	subl   $0x1,-0x24(%ebp)
f010342e:	75 ea                	jne    f010341a <vprintfmt+0x290>
f0103430:	eb b9                	jmp    f01033eb <vprintfmt+0x261>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103432:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103436:	74 1b                	je     f0103453 <vprintfmt+0x2c9>
f0103438:	8d 50 e0             	lea    -0x20(%eax),%edx
f010343b:	83 fa 5e             	cmp    $0x5e,%edx
f010343e:	76 13                	jbe    f0103453 <vprintfmt+0x2c9>
					putch('?', putdat);
f0103440:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103443:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103447:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f010344e:	ff 55 08             	call   *0x8(%ebp)
f0103451:	eb 0d                	jmp    f0103460 <vprintfmt+0x2d6>
				else
					putch(ch, putdat);
f0103453:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103456:	89 54 24 04          	mov    %edx,0x4(%esp)
f010345a:	89 04 24             	mov    %eax,(%esp)
f010345d:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103460:	83 ef 01             	sub    $0x1,%edi
f0103463:	0f be 03             	movsbl (%ebx),%eax
f0103466:	83 c3 01             	add    $0x1,%ebx
f0103469:	85 c0                	test   %eax,%eax
f010346b:	75 14                	jne    f0103481 <vprintfmt+0x2f7>
f010346d:	89 7d dc             	mov    %edi,-0x24(%ebp)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103470:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103474:	7f 19                	jg     f010348f <vprintfmt+0x305>
f0103476:	e9 de fd ff ff       	jmp    f0103259 <vprintfmt+0xcf>
f010347b:	89 7d e0             	mov    %edi,-0x20(%ebp)
f010347e:	8b 7d dc             	mov    -0x24(%ebp),%edi
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103481:	85 f6                	test   %esi,%esi
f0103483:	78 ad                	js     f0103432 <vprintfmt+0x2a8>
f0103485:	83 ee 01             	sub    $0x1,%esi
f0103488:	79 a8                	jns    f0103432 <vprintfmt+0x2a8>
f010348a:	89 7d dc             	mov    %edi,-0x24(%ebp)
f010348d:	eb e1                	jmp    f0103470 <vprintfmt+0x2e6>
f010348f:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103492:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103495:	8b 75 0c             	mov    0xc(%ebp),%esi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103498:	89 74 24 04          	mov    %esi,0x4(%esp)
f010349c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01034a3:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01034a5:	83 eb 01             	sub    $0x1,%ebx
f01034a8:	75 ee                	jne    f0103498 <vprintfmt+0x30e>
f01034aa:	e9 aa fd ff ff       	jmp    f0103259 <vprintfmt+0xcf>
f01034af:	89 45 e4             	mov    %eax,-0x1c(%ebp)
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01034b2:	83 f9 01             	cmp    $0x1,%ecx
f01034b5:	7e 10                	jle    f01034c7 <vprintfmt+0x33d>
		return va_arg(*ap, long long);
f01034b7:	8b 45 14             	mov    0x14(%ebp),%eax
f01034ba:	8d 50 08             	lea    0x8(%eax),%edx
f01034bd:	89 55 14             	mov    %edx,0x14(%ebp)
f01034c0:	8b 30                	mov    (%eax),%esi
f01034c2:	8b 78 04             	mov    0x4(%eax),%edi
f01034c5:	eb 26                	jmp    f01034ed <vprintfmt+0x363>
	else if (lflag)
f01034c7:	85 c9                	test   %ecx,%ecx
f01034c9:	74 12                	je     f01034dd <vprintfmt+0x353>
		return va_arg(*ap, long);
f01034cb:	8b 45 14             	mov    0x14(%ebp),%eax
f01034ce:	8d 50 04             	lea    0x4(%eax),%edx
f01034d1:	89 55 14             	mov    %edx,0x14(%ebp)
f01034d4:	8b 30                	mov    (%eax),%esi
f01034d6:	89 f7                	mov    %esi,%edi
f01034d8:	c1 ff 1f             	sar    $0x1f,%edi
f01034db:	eb 10                	jmp    f01034ed <vprintfmt+0x363>
	else
		return va_arg(*ap, int);
f01034dd:	8b 45 14             	mov    0x14(%ebp),%eax
f01034e0:	8d 50 04             	lea    0x4(%eax),%edx
f01034e3:	89 55 14             	mov    %edx,0x14(%ebp)
f01034e6:	8b 30                	mov    (%eax),%esi
f01034e8:	89 f7                	mov    %esi,%edi
f01034ea:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01034ed:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01034f2:	85 ff                	test   %edi,%edi
f01034f4:	0f 89 9e 00 00 00    	jns    f0103598 <vprintfmt+0x40e>
				putch('-', putdat);
f01034fa:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01034fd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103501:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0103508:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010350b:	f7 de                	neg    %esi
f010350d:	83 d7 00             	adc    $0x0,%edi
f0103510:	f7 df                	neg    %edi
			}
			base = 10;
f0103512:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103517:	eb 7f                	jmp    f0103598 <vprintfmt+0x40e>
f0103519:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f010351c:	89 ca                	mov    %ecx,%edx
f010351e:	8d 45 14             	lea    0x14(%ebp),%eax
f0103521:	e8 e5 fb ff ff       	call   f010310b <getuint>
f0103526:	89 c6                	mov    %eax,%esi
f0103528:	89 d7                	mov    %edx,%edi
			base = 10;
f010352a:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f010352f:	eb 67                	jmp    f0103598 <vprintfmt+0x40e>
f0103531:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap,lflag);
f0103534:	89 ca                	mov    %ecx,%edx
f0103536:	8d 45 14             	lea    0x14(%ebp),%eax
f0103539:	e8 cd fb ff ff       	call   f010310b <getuint>
f010353e:	89 c6                	mov    %eax,%esi
f0103540:	89 d7                	mov    %edx,%edi
			base = 8;
f0103542:	b8 08 00 00 00       	mov    $0x8,%eax

			goto number;
f0103547:	eb 4f                	jmp    f0103598 <vprintfmt+0x40e>
f0103549:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// pointer
		case 'p':
			putch('0', putdat);
f010354c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010354f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103553:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010355a:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f010355d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103561:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0103568:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010356b:	8b 45 14             	mov    0x14(%ebp),%eax
f010356e:	8d 50 04             	lea    0x4(%eax),%edx
f0103571:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103574:	8b 30                	mov    (%eax),%esi
f0103576:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010357b:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0103580:	eb 16                	jmp    f0103598 <vprintfmt+0x40e>
f0103582:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103585:	89 ca                	mov    %ecx,%edx
f0103587:	8d 45 14             	lea    0x14(%ebp),%eax
f010358a:	e8 7c fb ff ff       	call   f010310b <getuint>
f010358f:	89 c6                	mov    %eax,%esi
f0103591:	89 d7                	mov    %edx,%edi
			base = 16;
f0103593:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103598:	0f be 55 e0          	movsbl -0x20(%ebp),%edx
f010359c:	89 54 24 10          	mov    %edx,0x10(%esp)
f01035a0:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01035a3:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01035a7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01035ab:	89 34 24             	mov    %esi,(%esp)
f01035ae:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01035b2:	8b 55 0c             	mov    0xc(%ebp),%edx
f01035b5:	8b 45 08             	mov    0x8(%ebp),%eax
f01035b8:	e8 73 fa ff ff       	call   f0103030 <printnum>
			break;
f01035bd:	e9 97 fc ff ff       	jmp    f0103259 <vprintfmt+0xcf>
f01035c2:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01035c5:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01035c8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01035cb:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01035cf:	89 14 24             	mov    %edx,(%esp)
f01035d2:	ff 55 08             	call   *0x8(%ebp)
			break;
f01035d5:	e9 7f fc ff ff       	jmp    f0103259 <vprintfmt+0xcf>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01035da:	8b 45 0c             	mov    0xc(%ebp),%eax
f01035dd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01035e1:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01035e8:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01035eb:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f01035ee:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f01035f2:	0f 84 61 fc ff ff    	je     f0103259 <vprintfmt+0xcf>
f01035f8:	83 eb 01             	sub    $0x1,%ebx
f01035fb:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f01035ff:	75 f7                	jne    f01035f8 <vprintfmt+0x46e>
f0103601:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103604:	e9 50 fc ff ff       	jmp    f0103259 <vprintfmt+0xcf>
				/* do nothing */;
			break;
		}
	}
}
f0103609:	83 c4 3c             	add    $0x3c,%esp
f010360c:	5b                   	pop    %ebx
f010360d:	5e                   	pop    %esi
f010360e:	5f                   	pop    %edi
f010360f:	5d                   	pop    %ebp
f0103610:	c3                   	ret    

f0103611 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103611:	55                   	push   %ebp
f0103612:	89 e5                	mov    %esp,%ebp
f0103614:	83 ec 28             	sub    $0x28,%esp
f0103617:	8b 45 08             	mov    0x8(%ebp),%eax
f010361a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010361d:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103620:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103624:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103627:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010362e:	85 c0                	test   %eax,%eax
f0103630:	74 30                	je     f0103662 <vsnprintf+0x51>
f0103632:	85 d2                	test   %edx,%edx
f0103634:	7e 2c                	jle    f0103662 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103636:	8b 45 14             	mov    0x14(%ebp),%eax
f0103639:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010363d:	8b 45 10             	mov    0x10(%ebp),%eax
f0103640:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103644:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103647:	89 44 24 04          	mov    %eax,0x4(%esp)
f010364b:	c7 04 24 45 31 10 f0 	movl   $0xf0103145,(%esp)
f0103652:	e8 33 fb ff ff       	call   f010318a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103657:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010365a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010365d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103660:	eb 05                	jmp    f0103667 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103662:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103667:	c9                   	leave  
f0103668:	c3                   	ret    

f0103669 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103669:	55                   	push   %ebp
f010366a:	89 e5                	mov    %esp,%ebp
f010366c:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010366f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103672:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103676:	8b 45 10             	mov    0x10(%ebp),%eax
f0103679:	89 44 24 08          	mov    %eax,0x8(%esp)
f010367d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103680:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103684:	8b 45 08             	mov    0x8(%ebp),%eax
f0103687:	89 04 24             	mov    %eax,(%esp)
f010368a:	e8 82 ff ff ff       	call   f0103611 <vsnprintf>
	va_end(ap);

	return rc;
}
f010368f:	c9                   	leave  
f0103690:	c3                   	ret    
	...

f01036a0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01036a0:	55                   	push   %ebp
f01036a1:	89 e5                	mov    %esp,%ebp
f01036a3:	57                   	push   %edi
f01036a4:	56                   	push   %esi
f01036a5:	53                   	push   %ebx
f01036a6:	83 ec 1c             	sub    $0x1c,%esp
f01036a9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01036ac:	85 c0                	test   %eax,%eax
f01036ae:	74 10                	je     f01036c0 <readline+0x20>
		cprintf("%s", prompt);
f01036b0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036b4:	c7 04 24 64 4a 10 f0 	movl   $0xf0104a64,(%esp)
f01036bb:	e8 6e f6 ff ff       	call   f0102d2e <cprintf>

	i = 0;
	echoing = iscons(0);
f01036c0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01036c7:	e8 46 cf ff ff       	call   f0100612 <iscons>
f01036cc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01036ce:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01036d3:	e8 29 cf ff ff       	call   f0100601 <getchar>
f01036d8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01036da:	85 c0                	test   %eax,%eax
f01036dc:	79 17                	jns    f01036f5 <readline+0x55>
			cprintf("read error: %e\n", c);
f01036de:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036e2:	c7 04 24 08 4f 10 f0 	movl   $0xf0104f08,(%esp)
f01036e9:	e8 40 f6 ff ff       	call   f0102d2e <cprintf>
			return NULL;
f01036ee:	b8 00 00 00 00       	mov    $0x0,%eax
f01036f3:	eb 6d                	jmp    f0103762 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01036f5:	83 f8 08             	cmp    $0x8,%eax
f01036f8:	74 05                	je     f01036ff <readline+0x5f>
f01036fa:	83 f8 7f             	cmp    $0x7f,%eax
f01036fd:	75 19                	jne    f0103718 <readline+0x78>
f01036ff:	85 f6                	test   %esi,%esi
f0103701:	7e 15                	jle    f0103718 <readline+0x78>
			if (echoing)
f0103703:	85 ff                	test   %edi,%edi
f0103705:	74 0c                	je     f0103713 <readline+0x73>
				cputchar('\b');
f0103707:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010370e:	e8 de ce ff ff       	call   f01005f1 <cputchar>
			i--;
f0103713:	83 ee 01             	sub    $0x1,%esi
f0103716:	eb bb                	jmp    f01036d3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103718:	83 fb 1f             	cmp    $0x1f,%ebx
f010371b:	7e 1f                	jle    f010373c <readline+0x9c>
f010371d:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103723:	7f 17                	jg     f010373c <readline+0x9c>
			if (echoing)
f0103725:	85 ff                	test   %edi,%edi
f0103727:	74 08                	je     f0103731 <readline+0x91>
				cputchar(c);
f0103729:	89 1c 24             	mov    %ebx,(%esp)
f010372c:	e8 c0 ce ff ff       	call   f01005f1 <cputchar>
			buf[i++] = c;
f0103731:	88 9e a0 75 11 f0    	mov    %bl,-0xfee8a60(%esi)
f0103737:	83 c6 01             	add    $0x1,%esi
f010373a:	eb 97                	jmp    f01036d3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010373c:	83 fb 0a             	cmp    $0xa,%ebx
f010373f:	74 05                	je     f0103746 <readline+0xa6>
f0103741:	83 fb 0d             	cmp    $0xd,%ebx
f0103744:	75 8d                	jne    f01036d3 <readline+0x33>
			if (echoing)
f0103746:	85 ff                	test   %edi,%edi
f0103748:	74 0c                	je     f0103756 <readline+0xb6>
				cputchar('\n');
f010374a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0103751:	e8 9b ce ff ff       	call   f01005f1 <cputchar>
			buf[i] = 0;
f0103756:	c6 86 a0 75 11 f0 00 	movb   $0x0,-0xfee8a60(%esi)
			return buf;
f010375d:	b8 a0 75 11 f0       	mov    $0xf01175a0,%eax
		}
	}
}
f0103762:	83 c4 1c             	add    $0x1c,%esp
f0103765:	5b                   	pop    %ebx
f0103766:	5e                   	pop    %esi
f0103767:	5f                   	pop    %edi
f0103768:	5d                   	pop    %ebp
f0103769:	c3                   	ret    
f010376a:	00 00                	add    %al,(%eax)
f010376c:	00 00                	add    %al,(%eax)
	...

f0103770 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103770:	55                   	push   %ebp
f0103771:	89 e5                	mov    %esp,%ebp
f0103773:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103776:	b8 00 00 00 00       	mov    $0x0,%eax
f010377b:	80 3a 00             	cmpb   $0x0,(%edx)
f010377e:	74 09                	je     f0103789 <strlen+0x19>
		n++;
f0103780:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103783:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103787:	75 f7                	jne    f0103780 <strlen+0x10>
		n++;
	return n;
}
f0103789:	5d                   	pop    %ebp
f010378a:	c3                   	ret    

f010378b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010378b:	55                   	push   %ebp
f010378c:	89 e5                	mov    %esp,%ebp
f010378e:	53                   	push   %ebx
f010378f:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103792:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103795:	b8 00 00 00 00       	mov    $0x0,%eax
f010379a:	85 c9                	test   %ecx,%ecx
f010379c:	74 1a                	je     f01037b8 <strnlen+0x2d>
f010379e:	80 3b 00             	cmpb   $0x0,(%ebx)
f01037a1:	74 15                	je     f01037b8 <strnlen+0x2d>
f01037a3:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f01037a8:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01037aa:	39 ca                	cmp    %ecx,%edx
f01037ac:	74 0a                	je     f01037b8 <strnlen+0x2d>
f01037ae:	83 c2 01             	add    $0x1,%edx
f01037b1:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f01037b6:	75 f0                	jne    f01037a8 <strnlen+0x1d>
		n++;
	return n;
}
f01037b8:	5b                   	pop    %ebx
f01037b9:	5d                   	pop    %ebp
f01037ba:	c3                   	ret    

f01037bb <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01037bb:	55                   	push   %ebp
f01037bc:	89 e5                	mov    %esp,%ebp
f01037be:	53                   	push   %ebx
f01037bf:	8b 45 08             	mov    0x8(%ebp),%eax
f01037c2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01037c5:	ba 00 00 00 00       	mov    $0x0,%edx
f01037ca:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01037ce:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f01037d1:	83 c2 01             	add    $0x1,%edx
f01037d4:	84 c9                	test   %cl,%cl
f01037d6:	75 f2                	jne    f01037ca <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f01037d8:	5b                   	pop    %ebx
f01037d9:	5d                   	pop    %ebp
f01037da:	c3                   	ret    

f01037db <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01037db:	55                   	push   %ebp
f01037dc:	89 e5                	mov    %esp,%ebp
f01037de:	56                   	push   %esi
f01037df:	53                   	push   %ebx
f01037e0:	8b 45 08             	mov    0x8(%ebp),%eax
f01037e3:	8b 55 0c             	mov    0xc(%ebp),%edx
f01037e6:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01037e9:	85 f6                	test   %esi,%esi
f01037eb:	74 18                	je     f0103805 <strncpy+0x2a>
f01037ed:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f01037f2:	0f b6 1a             	movzbl (%edx),%ebx
f01037f5:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01037f8:	80 3a 01             	cmpb   $0x1,(%edx)
f01037fb:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01037fe:	83 c1 01             	add    $0x1,%ecx
f0103801:	39 f1                	cmp    %esi,%ecx
f0103803:	75 ed                	jne    f01037f2 <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103805:	5b                   	pop    %ebx
f0103806:	5e                   	pop    %esi
f0103807:	5d                   	pop    %ebp
f0103808:	c3                   	ret    

f0103809 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103809:	55                   	push   %ebp
f010380a:	89 e5                	mov    %esp,%ebp
f010380c:	57                   	push   %edi
f010380d:	56                   	push   %esi
f010380e:	53                   	push   %ebx
f010380f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103812:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103815:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103818:	89 f8                	mov    %edi,%eax
f010381a:	85 f6                	test   %esi,%esi
f010381c:	74 2b                	je     f0103849 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f010381e:	83 fe 01             	cmp    $0x1,%esi
f0103821:	74 23                	je     f0103846 <strlcpy+0x3d>
f0103823:	0f b6 0b             	movzbl (%ebx),%ecx
f0103826:	84 c9                	test   %cl,%cl
f0103828:	74 1c                	je     f0103846 <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f010382a:	83 ee 02             	sub    $0x2,%esi
f010382d:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103832:	88 08                	mov    %cl,(%eax)
f0103834:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103837:	39 f2                	cmp    %esi,%edx
f0103839:	74 0b                	je     f0103846 <strlcpy+0x3d>
f010383b:	83 c2 01             	add    $0x1,%edx
f010383e:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0103842:	84 c9                	test   %cl,%cl
f0103844:	75 ec                	jne    f0103832 <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f0103846:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103849:	29 f8                	sub    %edi,%eax
}
f010384b:	5b                   	pop    %ebx
f010384c:	5e                   	pop    %esi
f010384d:	5f                   	pop    %edi
f010384e:	5d                   	pop    %ebp
f010384f:	c3                   	ret    

f0103850 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103850:	55                   	push   %ebp
f0103851:	89 e5                	mov    %esp,%ebp
f0103853:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103856:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103859:	0f b6 01             	movzbl (%ecx),%eax
f010385c:	84 c0                	test   %al,%al
f010385e:	74 16                	je     f0103876 <strcmp+0x26>
f0103860:	3a 02                	cmp    (%edx),%al
f0103862:	75 12                	jne    f0103876 <strcmp+0x26>
		p++, q++;
f0103864:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103867:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f010386b:	84 c0                	test   %al,%al
f010386d:	74 07                	je     f0103876 <strcmp+0x26>
f010386f:	83 c1 01             	add    $0x1,%ecx
f0103872:	3a 02                	cmp    (%edx),%al
f0103874:	74 ee                	je     f0103864 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103876:	0f b6 c0             	movzbl %al,%eax
f0103879:	0f b6 12             	movzbl (%edx),%edx
f010387c:	29 d0                	sub    %edx,%eax
}
f010387e:	5d                   	pop    %ebp
f010387f:	c3                   	ret    

f0103880 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103880:	55                   	push   %ebp
f0103881:	89 e5                	mov    %esp,%ebp
f0103883:	53                   	push   %ebx
f0103884:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103887:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010388a:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010388d:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103892:	85 d2                	test   %edx,%edx
f0103894:	74 28                	je     f01038be <strncmp+0x3e>
f0103896:	0f b6 01             	movzbl (%ecx),%eax
f0103899:	84 c0                	test   %al,%al
f010389b:	74 24                	je     f01038c1 <strncmp+0x41>
f010389d:	3a 03                	cmp    (%ebx),%al
f010389f:	75 20                	jne    f01038c1 <strncmp+0x41>
f01038a1:	83 ea 01             	sub    $0x1,%edx
f01038a4:	74 13                	je     f01038b9 <strncmp+0x39>
		n--, p++, q++;
f01038a6:	83 c1 01             	add    $0x1,%ecx
f01038a9:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01038ac:	0f b6 01             	movzbl (%ecx),%eax
f01038af:	84 c0                	test   %al,%al
f01038b1:	74 0e                	je     f01038c1 <strncmp+0x41>
f01038b3:	3a 03                	cmp    (%ebx),%al
f01038b5:	74 ea                	je     f01038a1 <strncmp+0x21>
f01038b7:	eb 08                	jmp    f01038c1 <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f01038b9:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01038be:	5b                   	pop    %ebx
f01038bf:	5d                   	pop    %ebp
f01038c0:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01038c1:	0f b6 01             	movzbl (%ecx),%eax
f01038c4:	0f b6 13             	movzbl (%ebx),%edx
f01038c7:	29 d0                	sub    %edx,%eax
f01038c9:	eb f3                	jmp    f01038be <strncmp+0x3e>

f01038cb <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01038cb:	55                   	push   %ebp
f01038cc:	89 e5                	mov    %esp,%ebp
f01038ce:	8b 45 08             	mov    0x8(%ebp),%eax
f01038d1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01038d5:	0f b6 10             	movzbl (%eax),%edx
f01038d8:	84 d2                	test   %dl,%dl
f01038da:	74 1c                	je     f01038f8 <strchr+0x2d>
		if (*s == c)
f01038dc:	38 ca                	cmp    %cl,%dl
f01038de:	75 09                	jne    f01038e9 <strchr+0x1e>
f01038e0:	eb 1b                	jmp    f01038fd <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01038e2:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f01038e5:	38 ca                	cmp    %cl,%dl
f01038e7:	74 14                	je     f01038fd <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01038e9:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f01038ed:	84 d2                	test   %dl,%dl
f01038ef:	75 f1                	jne    f01038e2 <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f01038f1:	b8 00 00 00 00       	mov    $0x0,%eax
f01038f6:	eb 05                	jmp    f01038fd <strchr+0x32>
f01038f8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01038fd:	5d                   	pop    %ebp
f01038fe:	c3                   	ret    

f01038ff <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01038ff:	55                   	push   %ebp
f0103900:	89 e5                	mov    %esp,%ebp
f0103902:	8b 45 08             	mov    0x8(%ebp),%eax
f0103905:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103909:	0f b6 10             	movzbl (%eax),%edx
f010390c:	84 d2                	test   %dl,%dl
f010390e:	74 14                	je     f0103924 <strfind+0x25>
		if (*s == c)
f0103910:	38 ca                	cmp    %cl,%dl
f0103912:	75 06                	jne    f010391a <strfind+0x1b>
f0103914:	eb 0e                	jmp    f0103924 <strfind+0x25>
f0103916:	38 ca                	cmp    %cl,%dl
f0103918:	74 0a                	je     f0103924 <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010391a:	83 c0 01             	add    $0x1,%eax
f010391d:	0f b6 10             	movzbl (%eax),%edx
f0103920:	84 d2                	test   %dl,%dl
f0103922:	75 f2                	jne    f0103916 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f0103924:	5d                   	pop    %ebp
f0103925:	c3                   	ret    

f0103926 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103926:	55                   	push   %ebp
f0103927:	89 e5                	mov    %esp,%ebp
f0103929:	83 ec 0c             	sub    $0xc,%esp
f010392c:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010392f:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0103932:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0103935:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103938:	8b 45 0c             	mov    0xc(%ebp),%eax
f010393b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010393e:	85 c9                	test   %ecx,%ecx
f0103940:	74 30                	je     f0103972 <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103942:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103948:	75 25                	jne    f010396f <memset+0x49>
f010394a:	f6 c1 03             	test   $0x3,%cl
f010394d:	75 20                	jne    f010396f <memset+0x49>
		c &= 0xFF;
f010394f:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103952:	89 d3                	mov    %edx,%ebx
f0103954:	c1 e3 08             	shl    $0x8,%ebx
f0103957:	89 d6                	mov    %edx,%esi
f0103959:	c1 e6 18             	shl    $0x18,%esi
f010395c:	89 d0                	mov    %edx,%eax
f010395e:	c1 e0 10             	shl    $0x10,%eax
f0103961:	09 f0                	or     %esi,%eax
f0103963:	09 d0                	or     %edx,%eax
f0103965:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0103967:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f010396a:	fc                   	cld    
f010396b:	f3 ab                	rep stos %eax,%es:(%edi)
f010396d:	eb 03                	jmp    f0103972 <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010396f:	fc                   	cld    
f0103970:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103972:	89 f8                	mov    %edi,%eax
f0103974:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0103977:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010397a:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010397d:	89 ec                	mov    %ebp,%esp
f010397f:	5d                   	pop    %ebp
f0103980:	c3                   	ret    

f0103981 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103981:	55                   	push   %ebp
f0103982:	89 e5                	mov    %esp,%ebp
f0103984:	83 ec 08             	sub    $0x8,%esp
f0103987:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010398a:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010398d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103990:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103993:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103996:	39 c6                	cmp    %eax,%esi
f0103998:	73 36                	jae    f01039d0 <memmove+0x4f>
f010399a:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010399d:	39 d0                	cmp    %edx,%eax
f010399f:	73 2f                	jae    f01039d0 <memmove+0x4f>
		s += n;
		d += n;
f01039a1:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01039a4:	f6 c2 03             	test   $0x3,%dl
f01039a7:	75 1b                	jne    f01039c4 <memmove+0x43>
f01039a9:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01039af:	75 13                	jne    f01039c4 <memmove+0x43>
f01039b1:	f6 c1 03             	test   $0x3,%cl
f01039b4:	75 0e                	jne    f01039c4 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01039b6:	83 ef 04             	sub    $0x4,%edi
f01039b9:	8d 72 fc             	lea    -0x4(%edx),%esi
f01039bc:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01039bf:	fd                   	std    
f01039c0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01039c2:	eb 09                	jmp    f01039cd <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01039c4:	83 ef 01             	sub    $0x1,%edi
f01039c7:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01039ca:	fd                   	std    
f01039cb:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01039cd:	fc                   	cld    
f01039ce:	eb 20                	jmp    f01039f0 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01039d0:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01039d6:	75 13                	jne    f01039eb <memmove+0x6a>
f01039d8:	a8 03                	test   $0x3,%al
f01039da:	75 0f                	jne    f01039eb <memmove+0x6a>
f01039dc:	f6 c1 03             	test   $0x3,%cl
f01039df:	75 0a                	jne    f01039eb <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01039e1:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01039e4:	89 c7                	mov    %eax,%edi
f01039e6:	fc                   	cld    
f01039e7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01039e9:	eb 05                	jmp    f01039f0 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01039eb:	89 c7                	mov    %eax,%edi
f01039ed:	fc                   	cld    
f01039ee:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01039f0:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01039f3:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01039f6:	89 ec                	mov    %ebp,%esp
f01039f8:	5d                   	pop    %ebp
f01039f9:	c3                   	ret    

f01039fa <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f01039fa:	55                   	push   %ebp
f01039fb:	89 e5                	mov    %esp,%ebp
f01039fd:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0103a00:	8b 45 10             	mov    0x10(%ebp),%eax
f0103a03:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103a07:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103a0a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a0e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a11:	89 04 24             	mov    %eax,(%esp)
f0103a14:	e8 68 ff ff ff       	call   f0103981 <memmove>
}
f0103a19:	c9                   	leave  
f0103a1a:	c3                   	ret    

f0103a1b <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103a1b:	55                   	push   %ebp
f0103a1c:	89 e5                	mov    %esp,%ebp
f0103a1e:	57                   	push   %edi
f0103a1f:	56                   	push   %esi
f0103a20:	53                   	push   %ebx
f0103a21:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103a24:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103a27:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103a2a:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103a2f:	85 ff                	test   %edi,%edi
f0103a31:	74 37                	je     f0103a6a <memcmp+0x4f>
		if (*s1 != *s2)
f0103a33:	0f b6 03             	movzbl (%ebx),%eax
f0103a36:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103a39:	83 ef 01             	sub    $0x1,%edi
f0103a3c:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f0103a41:	38 c8                	cmp    %cl,%al
f0103a43:	74 1c                	je     f0103a61 <memcmp+0x46>
f0103a45:	eb 10                	jmp    f0103a57 <memcmp+0x3c>
f0103a47:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0103a4c:	83 c2 01             	add    $0x1,%edx
f0103a4f:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0103a53:	38 c8                	cmp    %cl,%al
f0103a55:	74 0a                	je     f0103a61 <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f0103a57:	0f b6 c0             	movzbl %al,%eax
f0103a5a:	0f b6 c9             	movzbl %cl,%ecx
f0103a5d:	29 c8                	sub    %ecx,%eax
f0103a5f:	eb 09                	jmp    f0103a6a <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103a61:	39 fa                	cmp    %edi,%edx
f0103a63:	75 e2                	jne    f0103a47 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103a65:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103a6a:	5b                   	pop    %ebx
f0103a6b:	5e                   	pop    %esi
f0103a6c:	5f                   	pop    %edi
f0103a6d:	5d                   	pop    %ebp
f0103a6e:	c3                   	ret    

f0103a6f <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103a6f:	55                   	push   %ebp
f0103a70:	89 e5                	mov    %esp,%ebp
f0103a72:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103a75:	89 c2                	mov    %eax,%edx
f0103a77:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103a7a:	39 d0                	cmp    %edx,%eax
f0103a7c:	73 15                	jae    f0103a93 <memfind+0x24>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103a7e:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f0103a82:	38 08                	cmp    %cl,(%eax)
f0103a84:	75 06                	jne    f0103a8c <memfind+0x1d>
f0103a86:	eb 0b                	jmp    f0103a93 <memfind+0x24>
f0103a88:	38 08                	cmp    %cl,(%eax)
f0103a8a:	74 07                	je     f0103a93 <memfind+0x24>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103a8c:	83 c0 01             	add    $0x1,%eax
f0103a8f:	39 d0                	cmp    %edx,%eax
f0103a91:	75 f5                	jne    f0103a88 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103a93:	5d                   	pop    %ebp
f0103a94:	c3                   	ret    

f0103a95 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103a95:	55                   	push   %ebp
f0103a96:	89 e5                	mov    %esp,%ebp
f0103a98:	57                   	push   %edi
f0103a99:	56                   	push   %esi
f0103a9a:	53                   	push   %ebx
f0103a9b:	8b 55 08             	mov    0x8(%ebp),%edx
f0103a9e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103aa1:	0f b6 02             	movzbl (%edx),%eax
f0103aa4:	3c 20                	cmp    $0x20,%al
f0103aa6:	74 04                	je     f0103aac <strtol+0x17>
f0103aa8:	3c 09                	cmp    $0x9,%al
f0103aaa:	75 0e                	jne    f0103aba <strtol+0x25>
		s++;
f0103aac:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103aaf:	0f b6 02             	movzbl (%edx),%eax
f0103ab2:	3c 20                	cmp    $0x20,%al
f0103ab4:	74 f6                	je     f0103aac <strtol+0x17>
f0103ab6:	3c 09                	cmp    $0x9,%al
f0103ab8:	74 f2                	je     f0103aac <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103aba:	3c 2b                	cmp    $0x2b,%al
f0103abc:	75 0a                	jne    f0103ac8 <strtol+0x33>
		s++;
f0103abe:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103ac1:	bf 00 00 00 00       	mov    $0x0,%edi
f0103ac6:	eb 10                	jmp    f0103ad8 <strtol+0x43>
f0103ac8:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103acd:	3c 2d                	cmp    $0x2d,%al
f0103acf:	75 07                	jne    f0103ad8 <strtol+0x43>
		s++, neg = 1;
f0103ad1:	83 c2 01             	add    $0x1,%edx
f0103ad4:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103ad8:	85 db                	test   %ebx,%ebx
f0103ada:	0f 94 c0             	sete   %al
f0103add:	74 05                	je     f0103ae4 <strtol+0x4f>
f0103adf:	83 fb 10             	cmp    $0x10,%ebx
f0103ae2:	75 15                	jne    f0103af9 <strtol+0x64>
f0103ae4:	80 3a 30             	cmpb   $0x30,(%edx)
f0103ae7:	75 10                	jne    f0103af9 <strtol+0x64>
f0103ae9:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0103aed:	75 0a                	jne    f0103af9 <strtol+0x64>
		s += 2, base = 16;
f0103aef:	83 c2 02             	add    $0x2,%edx
f0103af2:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103af7:	eb 13                	jmp    f0103b0c <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f0103af9:	84 c0                	test   %al,%al
f0103afb:	74 0f                	je     f0103b0c <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103afd:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103b02:	80 3a 30             	cmpb   $0x30,(%edx)
f0103b05:	75 05                	jne    f0103b0c <strtol+0x77>
		s++, base = 8;
f0103b07:	83 c2 01             	add    $0x1,%edx
f0103b0a:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f0103b0c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b11:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103b13:	0f b6 0a             	movzbl (%edx),%ecx
f0103b16:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0103b19:	80 fb 09             	cmp    $0x9,%bl
f0103b1c:	77 08                	ja     f0103b26 <strtol+0x91>
			dig = *s - '0';
f0103b1e:	0f be c9             	movsbl %cl,%ecx
f0103b21:	83 e9 30             	sub    $0x30,%ecx
f0103b24:	eb 1e                	jmp    f0103b44 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f0103b26:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f0103b29:	80 fb 19             	cmp    $0x19,%bl
f0103b2c:	77 08                	ja     f0103b36 <strtol+0xa1>
			dig = *s - 'a' + 10;
f0103b2e:	0f be c9             	movsbl %cl,%ecx
f0103b31:	83 e9 57             	sub    $0x57,%ecx
f0103b34:	eb 0e                	jmp    f0103b44 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f0103b36:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0103b39:	80 fb 19             	cmp    $0x19,%bl
f0103b3c:	77 14                	ja     f0103b52 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103b3e:	0f be c9             	movsbl %cl,%ecx
f0103b41:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0103b44:	39 f1                	cmp    %esi,%ecx
f0103b46:	7d 0e                	jge    f0103b56 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f0103b48:	83 c2 01             	add    $0x1,%edx
f0103b4b:	0f af c6             	imul   %esi,%eax
f0103b4e:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0103b50:	eb c1                	jmp    f0103b13 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0103b52:	89 c1                	mov    %eax,%ecx
f0103b54:	eb 02                	jmp    f0103b58 <strtol+0xc3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0103b56:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0103b58:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103b5c:	74 05                	je     f0103b63 <strtol+0xce>
		*endptr = (char *) s;
f0103b5e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103b61:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0103b63:	89 ca                	mov    %ecx,%edx
f0103b65:	f7 da                	neg    %edx
f0103b67:	85 ff                	test   %edi,%edi
f0103b69:	0f 45 c2             	cmovne %edx,%eax
}
f0103b6c:	5b                   	pop    %ebx
f0103b6d:	5e                   	pop    %esi
f0103b6e:	5f                   	pop    %edi
f0103b6f:	5d                   	pop    %ebp
f0103b70:	c3                   	ret    
	...

f0103b80 <__udivdi3>:
f0103b80:	83 ec 1c             	sub    $0x1c,%esp
f0103b83:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0103b87:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f0103b8b:	8b 44 24 20          	mov    0x20(%esp),%eax
f0103b8f:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0103b93:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103b97:	8b 74 24 24          	mov    0x24(%esp),%esi
f0103b9b:	85 ff                	test   %edi,%edi
f0103b9d:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0103ba1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103ba5:	89 cd                	mov    %ecx,%ebp
f0103ba7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103bab:	75 33                	jne    f0103be0 <__udivdi3+0x60>
f0103bad:	39 f1                	cmp    %esi,%ecx
f0103baf:	77 57                	ja     f0103c08 <__udivdi3+0x88>
f0103bb1:	85 c9                	test   %ecx,%ecx
f0103bb3:	75 0b                	jne    f0103bc0 <__udivdi3+0x40>
f0103bb5:	b8 01 00 00 00       	mov    $0x1,%eax
f0103bba:	31 d2                	xor    %edx,%edx
f0103bbc:	f7 f1                	div    %ecx
f0103bbe:	89 c1                	mov    %eax,%ecx
f0103bc0:	89 f0                	mov    %esi,%eax
f0103bc2:	31 d2                	xor    %edx,%edx
f0103bc4:	f7 f1                	div    %ecx
f0103bc6:	89 c6                	mov    %eax,%esi
f0103bc8:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103bcc:	f7 f1                	div    %ecx
f0103bce:	89 f2                	mov    %esi,%edx
f0103bd0:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103bd4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103bd8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103bdc:	83 c4 1c             	add    $0x1c,%esp
f0103bdf:	c3                   	ret    
f0103be0:	31 d2                	xor    %edx,%edx
f0103be2:	31 c0                	xor    %eax,%eax
f0103be4:	39 f7                	cmp    %esi,%edi
f0103be6:	77 e8                	ja     f0103bd0 <__udivdi3+0x50>
f0103be8:	0f bd cf             	bsr    %edi,%ecx
f0103beb:	83 f1 1f             	xor    $0x1f,%ecx
f0103bee:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103bf2:	75 2c                	jne    f0103c20 <__udivdi3+0xa0>
f0103bf4:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0103bf8:	76 04                	jbe    f0103bfe <__udivdi3+0x7e>
f0103bfa:	39 f7                	cmp    %esi,%edi
f0103bfc:	73 d2                	jae    f0103bd0 <__udivdi3+0x50>
f0103bfe:	31 d2                	xor    %edx,%edx
f0103c00:	b8 01 00 00 00       	mov    $0x1,%eax
f0103c05:	eb c9                	jmp    f0103bd0 <__udivdi3+0x50>
f0103c07:	90                   	nop
f0103c08:	89 f2                	mov    %esi,%edx
f0103c0a:	f7 f1                	div    %ecx
f0103c0c:	31 d2                	xor    %edx,%edx
f0103c0e:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103c12:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103c16:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103c1a:	83 c4 1c             	add    $0x1c,%esp
f0103c1d:	c3                   	ret    
f0103c1e:	66 90                	xchg   %ax,%ax
f0103c20:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103c25:	b8 20 00 00 00       	mov    $0x20,%eax
f0103c2a:	89 ea                	mov    %ebp,%edx
f0103c2c:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103c30:	d3 e7                	shl    %cl,%edi
f0103c32:	89 c1                	mov    %eax,%ecx
f0103c34:	d3 ea                	shr    %cl,%edx
f0103c36:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103c3b:	09 fa                	or     %edi,%edx
f0103c3d:	89 f7                	mov    %esi,%edi
f0103c3f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103c43:	89 f2                	mov    %esi,%edx
f0103c45:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103c49:	d3 e5                	shl    %cl,%ebp
f0103c4b:	89 c1                	mov    %eax,%ecx
f0103c4d:	d3 ef                	shr    %cl,%edi
f0103c4f:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103c54:	d3 e2                	shl    %cl,%edx
f0103c56:	89 c1                	mov    %eax,%ecx
f0103c58:	d3 ee                	shr    %cl,%esi
f0103c5a:	09 d6                	or     %edx,%esi
f0103c5c:	89 fa                	mov    %edi,%edx
f0103c5e:	89 f0                	mov    %esi,%eax
f0103c60:	f7 74 24 0c          	divl   0xc(%esp)
f0103c64:	89 d7                	mov    %edx,%edi
f0103c66:	89 c6                	mov    %eax,%esi
f0103c68:	f7 e5                	mul    %ebp
f0103c6a:	39 d7                	cmp    %edx,%edi
f0103c6c:	72 22                	jb     f0103c90 <__udivdi3+0x110>
f0103c6e:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0103c72:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103c77:	d3 e5                	shl    %cl,%ebp
f0103c79:	39 c5                	cmp    %eax,%ebp
f0103c7b:	73 04                	jae    f0103c81 <__udivdi3+0x101>
f0103c7d:	39 d7                	cmp    %edx,%edi
f0103c7f:	74 0f                	je     f0103c90 <__udivdi3+0x110>
f0103c81:	89 f0                	mov    %esi,%eax
f0103c83:	31 d2                	xor    %edx,%edx
f0103c85:	e9 46 ff ff ff       	jmp    f0103bd0 <__udivdi3+0x50>
f0103c8a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103c90:	8d 46 ff             	lea    -0x1(%esi),%eax
f0103c93:	31 d2                	xor    %edx,%edx
f0103c95:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103c99:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103c9d:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103ca1:	83 c4 1c             	add    $0x1c,%esp
f0103ca4:	c3                   	ret    
	...

f0103cb0 <__umoddi3>:
f0103cb0:	83 ec 1c             	sub    $0x1c,%esp
f0103cb3:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0103cb7:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f0103cbb:	8b 44 24 20          	mov    0x20(%esp),%eax
f0103cbf:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103cc3:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0103cc7:	8b 74 24 24          	mov    0x24(%esp),%esi
f0103ccb:	85 ed                	test   %ebp,%ebp
f0103ccd:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0103cd1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103cd5:	89 cf                	mov    %ecx,%edi
f0103cd7:	89 04 24             	mov    %eax,(%esp)
f0103cda:	89 f2                	mov    %esi,%edx
f0103cdc:	75 1a                	jne    f0103cf8 <__umoddi3+0x48>
f0103cde:	39 f1                	cmp    %esi,%ecx
f0103ce0:	76 4e                	jbe    f0103d30 <__umoddi3+0x80>
f0103ce2:	f7 f1                	div    %ecx
f0103ce4:	89 d0                	mov    %edx,%eax
f0103ce6:	31 d2                	xor    %edx,%edx
f0103ce8:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103cec:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103cf0:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103cf4:	83 c4 1c             	add    $0x1c,%esp
f0103cf7:	c3                   	ret    
f0103cf8:	39 f5                	cmp    %esi,%ebp
f0103cfa:	77 54                	ja     f0103d50 <__umoddi3+0xa0>
f0103cfc:	0f bd c5             	bsr    %ebp,%eax
f0103cff:	83 f0 1f             	xor    $0x1f,%eax
f0103d02:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d06:	75 60                	jne    f0103d68 <__umoddi3+0xb8>
f0103d08:	3b 0c 24             	cmp    (%esp),%ecx
f0103d0b:	0f 87 07 01 00 00    	ja     f0103e18 <__umoddi3+0x168>
f0103d11:	89 f2                	mov    %esi,%edx
f0103d13:	8b 34 24             	mov    (%esp),%esi
f0103d16:	29 ce                	sub    %ecx,%esi
f0103d18:	19 ea                	sbb    %ebp,%edx
f0103d1a:	89 34 24             	mov    %esi,(%esp)
f0103d1d:	8b 04 24             	mov    (%esp),%eax
f0103d20:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103d24:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103d28:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103d2c:	83 c4 1c             	add    $0x1c,%esp
f0103d2f:	c3                   	ret    
f0103d30:	85 c9                	test   %ecx,%ecx
f0103d32:	75 0b                	jne    f0103d3f <__umoddi3+0x8f>
f0103d34:	b8 01 00 00 00       	mov    $0x1,%eax
f0103d39:	31 d2                	xor    %edx,%edx
f0103d3b:	f7 f1                	div    %ecx
f0103d3d:	89 c1                	mov    %eax,%ecx
f0103d3f:	89 f0                	mov    %esi,%eax
f0103d41:	31 d2                	xor    %edx,%edx
f0103d43:	f7 f1                	div    %ecx
f0103d45:	8b 04 24             	mov    (%esp),%eax
f0103d48:	f7 f1                	div    %ecx
f0103d4a:	eb 98                	jmp    f0103ce4 <__umoddi3+0x34>
f0103d4c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103d50:	89 f2                	mov    %esi,%edx
f0103d52:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103d56:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103d5a:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103d5e:	83 c4 1c             	add    $0x1c,%esp
f0103d61:	c3                   	ret    
f0103d62:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103d68:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103d6d:	89 e8                	mov    %ebp,%eax
f0103d6f:	bd 20 00 00 00       	mov    $0x20,%ebp
f0103d74:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0103d78:	89 fa                	mov    %edi,%edx
f0103d7a:	d3 e0                	shl    %cl,%eax
f0103d7c:	89 e9                	mov    %ebp,%ecx
f0103d7e:	d3 ea                	shr    %cl,%edx
f0103d80:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103d85:	09 c2                	or     %eax,%edx
f0103d87:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103d8b:	89 14 24             	mov    %edx,(%esp)
f0103d8e:	89 f2                	mov    %esi,%edx
f0103d90:	d3 e7                	shl    %cl,%edi
f0103d92:	89 e9                	mov    %ebp,%ecx
f0103d94:	d3 ea                	shr    %cl,%edx
f0103d96:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103d9b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103d9f:	d3 e6                	shl    %cl,%esi
f0103da1:	89 e9                	mov    %ebp,%ecx
f0103da3:	d3 e8                	shr    %cl,%eax
f0103da5:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103daa:	09 f0                	or     %esi,%eax
f0103dac:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103db0:	f7 34 24             	divl   (%esp)
f0103db3:	d3 e6                	shl    %cl,%esi
f0103db5:	89 74 24 08          	mov    %esi,0x8(%esp)
f0103db9:	89 d6                	mov    %edx,%esi
f0103dbb:	f7 e7                	mul    %edi
f0103dbd:	39 d6                	cmp    %edx,%esi
f0103dbf:	89 c1                	mov    %eax,%ecx
f0103dc1:	89 d7                	mov    %edx,%edi
f0103dc3:	72 3f                	jb     f0103e04 <__umoddi3+0x154>
f0103dc5:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0103dc9:	72 35                	jb     f0103e00 <__umoddi3+0x150>
f0103dcb:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103dcf:	29 c8                	sub    %ecx,%eax
f0103dd1:	19 fe                	sbb    %edi,%esi
f0103dd3:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103dd8:	89 f2                	mov    %esi,%edx
f0103dda:	d3 e8                	shr    %cl,%eax
f0103ddc:	89 e9                	mov    %ebp,%ecx
f0103dde:	d3 e2                	shl    %cl,%edx
f0103de0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103de5:	09 d0                	or     %edx,%eax
f0103de7:	89 f2                	mov    %esi,%edx
f0103de9:	d3 ea                	shr    %cl,%edx
f0103deb:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103def:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103df3:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103df7:	83 c4 1c             	add    $0x1c,%esp
f0103dfa:	c3                   	ret    
f0103dfb:	90                   	nop
f0103dfc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103e00:	39 d6                	cmp    %edx,%esi
f0103e02:	75 c7                	jne    f0103dcb <__umoddi3+0x11b>
f0103e04:	89 d7                	mov    %edx,%edi
f0103e06:	89 c1                	mov    %eax,%ecx
f0103e08:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f0103e0c:	1b 3c 24             	sbb    (%esp),%edi
f0103e0f:	eb ba                	jmp    f0103dcb <__umoddi3+0x11b>
f0103e11:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103e18:	39 f5                	cmp    %esi,%ebp
f0103e1a:	0f 82 f1 fe ff ff    	jb     f0103d11 <__umoddi3+0x61>
f0103e20:	e9 f8 fe ff ff       	jmp    f0103d1d <__umoddi3+0x6d>
