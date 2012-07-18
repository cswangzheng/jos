
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
f0100063:	e8 5e 3b 00 00       	call   f0103bc6 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 8e 04 00 00       	call   f01004fb <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 e0 40 10 f0 	movl   $0xf01040e0,(%esp)
f010007c:	e8 45 2f 00 00       	call   f0102fc6 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 3e 14 00 00       	call   f01014c4 <mem_init>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 49 0a 00 00       	call   f0100adb <monitor>
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
f01000c1:	c7 04 24 fb 40 10 f0 	movl   $0xf01040fb,(%esp)
f01000c8:	e8 f9 2e 00 00       	call   f0102fc6 <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 ba 2e 00 00       	call   f0102f93 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 d4 51 10 f0 	movl   $0xf01051d4,(%esp)
f01000e0:	e8 e1 2e 00 00       	call   f0102fc6 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 ea 09 00 00       	call   f0100adb <monitor>
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
f010010b:	c7 04 24 13 41 10 f0 	movl   $0xf0104113,(%esp)
f0100112:	e8 af 2e 00 00       	call   f0102fc6 <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 6d 2e 00 00       	call   f0102f93 <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 d4 51 10 f0 	movl   $0xf01051d4,(%esp)
f010012d:	e8 94 2e 00 00       	call   f0102fc6 <cprintf>
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
f010032d:	e8 ef 38 00 00       	call   f0103c21 <memmove>
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
f01003d9:	0f b6 82 60 41 10 f0 	movzbl -0xfefbea0(%edx),%eax
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
f0100416:	0f b6 82 60 41 10 f0 	movzbl -0xfefbea0(%edx),%eax
f010041d:	0b 05 68 85 11 f0    	or     0xf0118568,%eax
	shift ^= togglecode[data];
f0100423:	0f b6 8a 60 42 10 f0 	movzbl -0xfefbda0(%edx),%ecx
f010042a:	31 c8                	xor    %ecx,%eax
f010042c:	a3 68 85 11 f0       	mov    %eax,0xf0118568

	c = charcode[shift & (CTL | SHIFT)][data];
f0100431:	89 c1                	mov    %eax,%ecx
f0100433:	83 e1 03             	and    $0x3,%ecx
f0100436:	8b 0c 8d 60 43 10 f0 	mov    -0xfefbca0(,%ecx,4),%ecx
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
f010046c:	c7 04 24 2d 41 10 f0 	movl   $0xf010412d,(%esp)
f0100473:	e8 4e 2b 00 00       	call   f0102fc6 <cprintf>
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
f01005dd:	c7 04 24 39 41 10 f0 	movl   $0xf0104139,(%esp)
f01005e4:	e8 dd 29 00 00       	call   f0102fc6 <cprintf>
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
f0100626:	c7 04 24 70 43 10 f0 	movl   $0xf0104370,(%esp)
f010062d:	e8 94 29 00 00       	call   f0102fc6 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100632:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100639:	00 
f010063a:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100641:	f0 
f0100642:	c7 04 24 c4 44 10 f0 	movl   $0xf01044c4,(%esp)
f0100649:	e8 78 29 00 00       	call   f0102fc6 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010064e:	c7 44 24 08 c5 40 10 	movl   $0x1040c5,0x8(%esp)
f0100655:	00 
f0100656:	c7 44 24 04 c5 40 10 	movl   $0xf01040c5,0x4(%esp)
f010065d:	f0 
f010065e:	c7 04 24 e8 44 10 f0 	movl   $0xf01044e8,(%esp)
f0100665:	e8 5c 29 00 00       	call   f0102fc6 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010066a:	c7 44 24 08 04 83 11 	movl   $0x118304,0x8(%esp)
f0100671:	00 
f0100672:	c7 44 24 04 04 83 11 	movl   $0xf0118304,0x4(%esp)
f0100679:	f0 
f010067a:	c7 04 24 0c 45 10 f0 	movl   $0xf010450c,(%esp)
f0100681:	e8 40 29 00 00       	call   f0102fc6 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100686:	c7 44 24 08 ac 89 11 	movl   $0x1189ac,0x8(%esp)
f010068d:	00 
f010068e:	c7 44 24 04 ac 89 11 	movl   $0xf01189ac,0x4(%esp)
f0100695:	f0 
f0100696:	c7 04 24 30 45 10 f0 	movl   $0xf0104530,(%esp)
f010069d:	e8 24 29 00 00       	call   f0102fc6 <cprintf>
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
f01006be:	c7 04 24 54 45 10 f0 	movl   $0xf0104554,(%esp)
f01006c5:	e8 fc 28 00 00       	call   f0102fc6 <cprintf>
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
f01006dd:	8b 83 24 48 10 f0    	mov    -0xfefb7dc(%ebx),%eax
f01006e3:	89 44 24 08          	mov    %eax,0x8(%esp)
f01006e7:	8b 83 20 48 10 f0    	mov    -0xfefb7e0(%ebx),%eax
f01006ed:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006f1:	c7 04 24 89 43 10 f0 	movl   $0xf0104389,(%esp)
f01006f8:	e8 c9 28 00 00       	call   f0102fc6 <cprintf>
f01006fd:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f0100700:	83 fb 3c             	cmp    $0x3c,%ebx
f0100703:	75 d8                	jne    f01006dd <mon_help+0xc>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f0100705:	b8 00 00 00 00       	mov    $0x0,%eax
f010070a:	83 c4 14             	add    $0x14,%esp
f010070d:	5b                   	pop    %ebx
f010070e:	5d                   	pop    %ebp
f010070f:	c3                   	ret    

f0100710 <mon_setmappings>:
	
}

int
mon_setmappings(int argc, char **argv, struct Trapframe *tf)
{
f0100710:	55                   	push   %ebp
f0100711:	89 e5                	mov    %esp,%ebp
f0100713:	83 ec 28             	sub    $0x28,%esp
f0100716:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100719:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010071c:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010071f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100722:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	if(argc!=3&&argc!=4)
f0100725:	8d 47 fd             	lea    -0x3(%edi),%eax
f0100728:	83 f8 01             	cmp    $0x1,%eax
f010072b:	76 1d                	jbe    f010074a <mon_setmappings+0x3a>
		{
			cprintf("set, clear, or change the permissions of any mapping in the current address space");
f010072d:	c7 04 24 80 45 10 f0 	movl   $0xf0104580,(%esp)
f0100734:	e8 8d 28 00 00       	call   f0102fc6 <cprintf>
			cprintf("Usage:setmappings <OPER> <VA> (<Permission>)\n OPER:-set,-clear,-change Permission:U,W\n");
f0100739:	c7 04 24 d4 45 10 f0 	movl   $0xf01045d4,(%esp)
f0100740:	e8 81 28 00 00       	call   f0102fc6 <cprintf>
			return 0;
f0100745:	e9 f0 00 00 00       	jmp    f010083a <mon_setmappings+0x12a>
		}
	
	uintptr_t va = strtol(argv[2], 0,16);
f010074a:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f0100751:	00 
f0100752:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100759:	00 
f010075a:	8b 43 08             	mov    0x8(%ebx),%eax
f010075d:	89 04 24             	mov    %eax,(%esp)
f0100760:	e8 d0 35 00 00       	call   f0103d35 <strtol>
	uintptr_t va_page = PTE_ADDR(va);
	pte_t *pte;
	pte = pgdir_walk(kern_pgdir, (void * )(va_page), 0);
f0100765:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010076c:	00 
			cprintf("Usage:setmappings <OPER> <VA> (<Permission>)\n OPER:-set,-clear,-change Permission:U,W\n");
			return 0;
		}
	
	uintptr_t va = strtol(argv[2], 0,16);
	uintptr_t va_page = PTE_ADDR(va);
f010076d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	pte_t *pte;
	pte = pgdir_walk(kern_pgdir, (void * )(va_page), 0);
f0100772:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100776:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f010077b:	89 04 24             	mov    %eax,(%esp)
f010077e:	e8 72 0a 00 00       	call   f01011f5 <pgdir_walk>
f0100783:	89 c6                	mov    %eax,%esi
	if(strcmp(argv[1],"-clear")==0)
f0100785:	c7 44 24 04 92 43 10 	movl   $0xf0104392,0x4(%esp)
f010078c:	f0 
f010078d:	8b 43 04             	mov    0x4(%ebx),%eax
f0100790:	89 04 24             	mov    %eax,(%esp)
f0100793:	e8 58 33 00 00       	call   f0103af0 <strcmp>
f0100798:	85 c0                	test   %eax,%eax
f010079a:	75 1e                	jne    f01007ba <mon_setmappings+0xaa>
	{
		*pte=PTE_ADDR(*pte);
f010079c:	8b 06                	mov    (%esi),%eax
f010079e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01007a3:	89 06                	mov    %eax,(%esi)
		cprintf("\n0x%08x permissions clear OK",(*pte));
f01007a5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007a9:	c7 04 24 99 43 10 f0 	movl   $0xf0104399,(%esp)
f01007b0:	e8 11 28 00 00       	call   f0102fc6 <cprintf>
f01007b5:	e9 80 00 00 00       	jmp    f010083a <mon_setmappings+0x12a>
	}
	else if(strcmp(argv[1],"-set")==0||strcmp(argv[1],"-change")==0)
f01007ba:	c7 44 24 04 b6 43 10 	movl   $0xf01043b6,0x4(%esp)
f01007c1:	f0 
f01007c2:	8b 43 04             	mov    0x4(%ebx),%eax
f01007c5:	89 04 24             	mov    %eax,(%esp)
f01007c8:	e8 23 33 00 00       	call   f0103af0 <strcmp>
f01007cd:	85 c0                	test   %eax,%eax
f01007cf:	74 17                	je     f01007e8 <mon_setmappings+0xd8>
f01007d1:	c7 44 24 04 bb 43 10 	movl   $0xf01043bb,0x4(%esp)
f01007d8:	f0 
f01007d9:	8b 43 04             	mov    0x4(%ebx),%eax
f01007dc:	89 04 24             	mov    %eax,(%esp)
f01007df:	e8 0c 33 00 00       	call   f0103af0 <strcmp>
f01007e4:	85 c0                	test   %eax,%eax
f01007e6:	75 52                	jne    f010083a <mon_setmappings+0x12a>
	{
		if(argc!=4)
f01007e8:	83 ff 04             	cmp    $0x4,%edi
f01007eb:	74 03                	je     f01007f0 <mon_setmappings+0xe0>
		{
			*pte=(*pte)&(~PTE_U)&(~PTE_W);
f01007ed:	83 26 f9             	andl   $0xfffffff9,(%esi)
		}
		if (argv[3][0]=='W'||argv[3][0]=='w'||argv[3][1]=='W'||argv[3][1]=='w')
f01007f0:	8b 43 0c             	mov    0xc(%ebx),%eax
f01007f3:	0f b6 10             	movzbl (%eax),%edx
f01007f6:	80 fa 57             	cmp    $0x57,%dl
f01007f9:	74 11                	je     f010080c <mon_setmappings+0xfc>
f01007fb:	80 fa 77             	cmp    $0x77,%dl
f01007fe:	74 0c                	je     f010080c <mon_setmappings+0xfc>
f0100800:	0f b6 40 01          	movzbl 0x1(%eax),%eax
f0100804:	3c 57                	cmp    $0x57,%al
f0100806:	74 04                	je     f010080c <mon_setmappings+0xfc>
f0100808:	3c 77                	cmp    $0x77,%al
f010080a:	75 03                	jne    f010080f <mon_setmappings+0xff>
		{
			*pte=(*pte)|PTE_W;
f010080c:	83 0e 02             	orl    $0x2,(%esi)
		}
		if (argv[3][0]=='U'||argv[3][0]=='u'||argv[3][1]=='U'||argv[3][1]=='u')
f010080f:	8b 43 0c             	mov    0xc(%ebx),%eax
f0100812:	0f b6 10             	movzbl (%eax),%edx
f0100815:	80 fa 55             	cmp    $0x55,%dl
f0100818:	74 11                	je     f010082b <mon_setmappings+0x11b>
f010081a:	80 fa 75             	cmp    $0x75,%dl
f010081d:	74 0c                	je     f010082b <mon_setmappings+0x11b>
f010081f:	0f b6 40 01          	movzbl 0x1(%eax),%eax
f0100823:	3c 55                	cmp    $0x55,%al
f0100825:	74 04                	je     f010082b <mon_setmappings+0x11b>
f0100827:	3c 75                	cmp    $0x75,%al
f0100829:	75 03                	jne    f010082e <mon_setmappings+0x11e>
		{
			*pte=(*pte)|PTE_U;
f010082b:	83 0e 04             	orl    $0x4,(%esi)
		}
		cprintf("Permission set OK\n");
f010082e:	c7 04 24 c3 43 10 f0 	movl   $0xf01043c3,(%esp)
f0100835:	e8 8c 27 00 00       	call   f0102fc6 <cprintf>
	}
	return 0;
}
f010083a:	b8 00 00 00 00       	mov    $0x0,%eax
f010083f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100842:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100845:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100848:	89 ec                	mov    %ebp,%esp
f010084a:	5d                   	pop    %ebp
f010084b:	c3                   	ret    

f010084c <mon_showmappings>:
	return 0;
}

int
mon_showmappings(int argc, char **argv, struct Trapframe *tf)
{
f010084c:	55                   	push   %ebp
f010084d:	89 e5                	mov    %esp,%ebp
f010084f:	57                   	push   %edi
f0100850:	56                   	push   %esi
f0100851:	53                   	push   %ebx
f0100852:	83 ec 2c             	sub    $0x2c,%esp
f0100855:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	if(argc!=3)
f0100858:	83 7d 08 03          	cmpl   $0x3,0x8(%ebp)
f010085c:	74 11                	je     f010086f <mon_showmappings+0x23>
		{
			cprintf("Need low va and high va in 0x , for exampe:\nshowmappings 0x3000 0x5000\n");
f010085e:	c7 04 24 2c 46 10 f0 	movl   $0xf010462c,(%esp)
f0100865:	e8 5c 27 00 00       	call   f0102fc6 <cprintf>
			return 0;
f010086a:	e9 2a 01 00 00       	jmp    f0100999 <mon_showmappings+0x14d>
		}
	uintptr_t va_low = strtol(argv[1], 0,16);
f010086f:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f0100876:	00 
f0100877:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010087e:	00 
f010087f:	8b 43 04             	mov    0x4(%ebx),%eax
f0100882:	89 04 24             	mov    %eax,(%esp)
f0100885:	e8 ab 34 00 00       	call   f0103d35 <strtol>
f010088a:	89 c6                	mov    %eax,%esi
	uintptr_t va_high = strtol(argv[2], 0,16);
f010088c:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f0100893:	00 
f0100894:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010089b:	00 
f010089c:	8b 43 08             	mov    0x8(%ebx),%eax
f010089f:	89 04 24             	mov    %eax,(%esp)
f01008a2:	e8 8e 34 00 00       	call   f0103d35 <strtol>
	uintptr_t va_low_page = PTE_ADDR(va_low);
f01008a7:	89 f3                	mov    %esi,%ebx
f01008a9:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t va_high_page = PTE_ADDR(va_high);
f01008af:	25 00 f0 ff ff       	and    $0xfffff000,%eax

	int pagenum = (va_high_page-va_low_page)/PGSIZE;
f01008b4:	29 d8                	sub    %ebx,%eax
f01008b6:	c1 e8 0c             	shr    $0xc,%eax
f01008b9:	89 45 e0             	mov    %eax,-0x20(%ebp)
	int i = 0;
	pte_t *pte;
	cprintf("----------output start------------\n");
f01008bc:	c7 04 24 74 46 10 f0 	movl   $0xf0104674,(%esp)
f01008c3:	e8 fe 26 00 00       	call   f0102fc6 <cprintf>
	cprintf("Virtual Address	    Physical  Permissions(kernel/user)");
f01008c8:	c7 04 24 98 46 10 f0 	movl   $0xf0104698,(%esp)
f01008cf:	e8 f2 26 00 00       	call   f0102fc6 <cprintf>
	for(i=0;i<pagenum;i++)
f01008d4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01008d8:	0f 8e af 00 00 00    	jle    f010098d <mon_showmappings+0x141>
f01008de:	bf 00 00 00 00       	mov    $0x0,%edi
	{
		pte = pgdir_walk(kern_pgdir, (void * )(va_low_page+i*PGSIZE), 0);
f01008e3:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f01008e6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01008ed:	00 
f01008ee:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01008f2:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f01008f7:	89 04 24             	mov    %eax,(%esp)
f01008fa:	e8 f6 08 00 00       	call   f01011f5 <pgdir_walk>
f01008ff:	89 c6                	mov    %eax,%esi
		cprintf("\n0x%08x - 0x%08x :",va_low_page+i*PGSIZE,va_low_page+(i+1)*PGSIZE);
f0100901:	83 c7 01             	add    $0x1,%edi
		}
	return 0;
}

int
mon_showmappings(int argc, char **argv, struct Trapframe *tf)
f0100904:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	cprintf("----------output start------------\n");
	cprintf("Virtual Address	    Physical  Permissions(kernel/user)");
	for(i=0;i<pagenum;i++)
	{
		pte = pgdir_walk(kern_pgdir, (void * )(va_low_page+i*PGSIZE), 0);
		cprintf("\n0x%08x - 0x%08x :",va_low_page+i*PGSIZE,va_low_page+(i+1)*PGSIZE);
f010090a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010090e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100911:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100915:	c7 04 24 d6 43 10 f0 	movl   $0xf01043d6,(%esp)
f010091c:	e8 a5 26 00 00       	call   f0102fc6 <cprintf>
		if ( pte!=NULL&& (*pte&PTE_P))//pte exist
f0100921:	85 f6                	test   %esi,%esi
f0100923:	74 5f                	je     f0100984 <mon_showmappings+0x138>
f0100925:	8b 06                	mov    (%esi),%eax
f0100927:	a8 01                	test   $0x1,%al
f0100929:	74 59                	je     f0100984 <mon_showmappings+0x138>
		{
		cprintf("0x%08x ",PTE_ADDR(*pte));
f010092b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100930:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100934:	c7 04 24 e9 43 10 f0 	movl   $0xf01043e9,(%esp)
f010093b:	e8 86 26 00 00       	call   f0102fc6 <cprintf>
		if (*pte & PTE_W)
f0100940:	8b 06                	mov    (%esi),%eax
f0100942:	a8 02                	test   $0x2,%al
f0100944:	74 20                	je     f0100966 <mon_showmappings+0x11a>
			{
			if (*pte & PTE_U)
f0100946:	a8 04                	test   $0x4,%al
f0100948:	74 0e                	je     f0100958 <mon_showmappings+0x10c>
				cprintf("RW\\RW");
f010094a:	c7 04 24 f1 43 10 f0 	movl   $0xf01043f1,(%esp)
f0100951:	e8 70 26 00 00       	call   f0102fc6 <cprintf>
f0100956:	eb 2c                	jmp    f0100984 <mon_showmappings+0x138>
			else
				cprintf("RW\\--");
f0100958:	c7 04 24 f7 43 10 f0 	movl   $0xf01043f7,(%esp)
f010095f:	e8 62 26 00 00       	call   f0102fc6 <cprintf>
f0100964:	eb 1e                	jmp    f0100984 <mon_showmappings+0x138>
			}
		else
			{
			if (*pte & PTE_U)
f0100966:	a8 04                	test   $0x4,%al
f0100968:	74 0e                	je     f0100978 <mon_showmappings+0x12c>
				cprintf("R-\\R-");
f010096a:	c7 04 24 fd 43 10 f0 	movl   $0xf01043fd,(%esp)
f0100971:	e8 50 26 00 00       	call   f0102fc6 <cprintf>
f0100976:	eb 0c                	jmp    f0100984 <mon_showmappings+0x138>
			else
				cprintf("R-\\--");
f0100978:	c7 04 24 03 44 10 f0 	movl   $0xf0104403,(%esp)
f010097f:	e8 42 26 00 00       	call   f0102fc6 <cprintf>
	int pagenum = (va_high_page-va_low_page)/PGSIZE;
	int i = 0;
	pte_t *pte;
	cprintf("----------output start------------\n");
	cprintf("Virtual Address	    Physical  Permissions(kernel/user)");
	for(i=0;i<pagenum;i++)
f0100984:	39 7d e0             	cmp    %edi,-0x20(%ebp)
f0100987:	0f 85 56 ff ff ff    	jne    f01008e3 <mon_showmappings+0x97>
			else
				cprintf("R-\\--");
			}
		}
	}
	cprintf("\n----------output end------------\n");
f010098d:	c7 04 24 d0 46 10 f0 	movl   $0xf01046d0,(%esp)
f0100994:	e8 2d 26 00 00       	call   f0102fc6 <cprintf>
	return 0;
	
}
f0100999:	b8 00 00 00 00       	mov    $0x0,%eax
f010099e:	83 c4 2c             	add    $0x2c,%esp
f01009a1:	5b                   	pop    %ebx
f01009a2:	5e                   	pop    %esi
f01009a3:	5f                   	pop    %edi
f01009a4:	5d                   	pop    %ebp
f01009a5:	c3                   	ret    

f01009a6 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01009a6:	55                   	push   %ebp
f01009a7:	89 e5                	mov    %esp,%ebp
f01009a9:	57                   	push   %edi
f01009aa:	56                   	push   %esi
f01009ab:	53                   	push   %ebx
f01009ac:	81 ec 8c 00 00 00    	sub    $0x8c,%esp

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f01009b2:	89 eb                	mov    %ebp,%ebx
f01009b4:	89 de                	mov    %ebx,%esi
	// Your code here.
	uint32_t ebp,eip,arg[5];
	ebp = read_ebp();
	eip = *((uint32_t*)ebp+1);
f01009b6:	8b 7b 04             	mov    0x4(%ebx),%edi
	arg[0] = *((uint32_t*)ebp+2);
f01009b9:	8b 43 08             	mov    0x8(%ebx),%eax
f01009bc:	89 45 a4             	mov    %eax,-0x5c(%ebp)
	arg[1] = *((uint32_t*)ebp+3);
f01009bf:	8b 43 0c             	mov    0xc(%ebx),%eax
f01009c2:	89 45 a0             	mov    %eax,-0x60(%ebp)
	arg[2] = *((uint32_t*)ebp+4);
f01009c5:	8b 43 10             	mov    0x10(%ebx),%eax
f01009c8:	89 45 9c             	mov    %eax,-0x64(%ebp)
	arg[3] = *((uint32_t*)ebp+5);
f01009cb:	8b 43 14             	mov    0x14(%ebx),%eax
f01009ce:	89 45 98             	mov    %eax,-0x68(%ebp)
	arg[4] = *((uint32_t*)ebp+6);
f01009d1:	8b 43 18             	mov    0x18(%ebx),%eax
f01009d4:	89 45 94             	mov    %eax,-0x6c(%ebp)

	cprintf("Stack backtrace:\n");
f01009d7:	c7 04 24 09 44 10 f0 	movl   $0xf0104409,(%esp)
f01009de:	e8 e3 25 00 00       	call   f0102fc6 <cprintf>
	
	while(ebp != 0x00)
f01009e3:	85 db                	test   %ebx,%ebx
f01009e5:	0f 84 e0 00 00 00    	je     f0100acb <mon_backtrace+0x125>
			info.eip_fn_name = "<unknown>";
			info.eip_fn_namelen = 9;
			info.eip_fn_addr = eip;
			info.eip_fn_narg = 0;
			char display_eip_fn_name[30];
			debuginfo_eip(eip,&info);
f01009eb:	8d 5d d0             	lea    -0x30(%ebp),%ebx
f01009ee:	8b 45 9c             	mov    -0x64(%ebp),%eax
f01009f1:	8b 55 98             	mov    -0x68(%ebp),%edx
f01009f4:	8b 4d 94             	mov    -0x6c(%ebp),%ecx
	cprintf("Stack backtrace:\n");
	
	while(ebp != 0x00)
		{
			
			cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",ebp,eip,arg[0],arg[1],arg[2],arg[3],arg[4]);
f01009f7:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f01009fb:	89 54 24 18          	mov    %edx,0x18(%esp)
f01009ff:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100a03:	8b 45 a0             	mov    -0x60(%ebp),%eax
f0100a06:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100a0a:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100a0d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a11:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0100a15:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100a19:	c7 04 24 f4 46 10 f0 	movl   $0xf01046f4,(%esp)
f0100a20:	e8 a1 25 00 00       	call   f0102fc6 <cprintf>
			struct Eipdebuginfo info;
			info.eip_file = "<unknown>";
f0100a25:	c7 45 d0 1b 44 10 f0 	movl   $0xf010441b,-0x30(%ebp)
			info.eip_line = 0;
f0100a2c:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
			info.eip_fn_name = "<unknown>";
f0100a33:	c7 45 d8 1b 44 10 f0 	movl   $0xf010441b,-0x28(%ebp)
			info.eip_fn_namelen = 9;
f0100a3a:	c7 45 dc 09 00 00 00 	movl   $0x9,-0x24(%ebp)
			info.eip_fn_addr = eip;
f0100a41:	89 7d e0             	mov    %edi,-0x20(%ebp)
			info.eip_fn_narg = 0;
f0100a44:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
			char display_eip_fn_name[30];
			debuginfo_eip(eip,&info);
f0100a4b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100a4f:	89 3c 24             	mov    %edi,(%esp)
f0100a52:	e8 69 26 00 00       	call   f01030c0 <debuginfo_eip>
			int i;
			for ( i=0;(info.eip_fn_name[i]!=':')&&( i<30); i++)
f0100a57:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0100a5a:	0f b6 11             	movzbl (%ecx),%edx
f0100a5d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a62:	80 fa 3a             	cmp    $0x3a,%dl
f0100a65:	74 15                	je     f0100a7c <mon_backtrace+0xd6>
				display_eip_fn_name[i]=info.eip_fn_name[i];
f0100a67:	88 54 05 b2          	mov    %dl,-0x4e(%ebp,%eax,1)
			info.eip_fn_addr = eip;
			info.eip_fn_narg = 0;
			char display_eip_fn_name[30];
			debuginfo_eip(eip,&info);
			int i;
			for ( i=0;(info.eip_fn_name[i]!=':')&&( i<30); i++)
f0100a6b:	83 c0 01             	add    $0x1,%eax
f0100a6e:	0f b6 14 01          	movzbl (%ecx,%eax,1),%edx
f0100a72:	80 fa 3a             	cmp    $0x3a,%dl
f0100a75:	74 05                	je     f0100a7c <mon_backtrace+0xd6>
f0100a77:	83 f8 1d             	cmp    $0x1d,%eax
f0100a7a:	7e eb                	jle    f0100a67 <mon_backtrace+0xc1>
				display_eip_fn_name[i]=info.eip_fn_name[i];
			display_eip_fn_name[i]='\0';
f0100a7c:	c6 44 05 b2 00       	movb   $0x0,-0x4e(%ebp,%eax,1)
			cprintf("    %s:%d: %s+%d\n",info.eip_file,info.eip_line,display_eip_fn_name,(eip-info.eip_fn_addr));
f0100a81:	2b 7d e0             	sub    -0x20(%ebp),%edi
f0100a84:	89 7c 24 10          	mov    %edi,0x10(%esp)
f0100a88:	8d 45 b2             	lea    -0x4e(%ebp),%eax
f0100a8b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a8f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100a92:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100a96:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100a99:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a9d:	c7 04 24 25 44 10 f0 	movl   $0xf0104425,(%esp)
f0100aa4:	e8 1d 25 00 00       	call   f0102fc6 <cprintf>
			ebp = *(uint32_t *)ebp;
f0100aa9:	8b 36                	mov    (%esi),%esi
			eip = *((uint32_t*)ebp+1);
f0100aab:	8b 7e 04             	mov    0x4(%esi),%edi
			arg[0] = *((uint32_t*)ebp+2);
f0100aae:	8b 46 08             	mov    0x8(%esi),%eax
f0100ab1:	89 45 a4             	mov    %eax,-0x5c(%ebp)
			arg[1] = *((uint32_t*)ebp+3);
f0100ab4:	8b 46 0c             	mov    0xc(%esi),%eax
f0100ab7:	89 45 a0             	mov    %eax,-0x60(%ebp)
			arg[2] = *((uint32_t*)ebp+4);
f0100aba:	8b 46 10             	mov    0x10(%esi),%eax
			arg[3] = *((uint32_t*)ebp+5);
f0100abd:	8b 56 14             	mov    0x14(%esi),%edx
			arg[4] = *((uint32_t*)ebp+6);
f0100ac0:	8b 4e 18             	mov    0x18(%esi),%ecx
	arg[3] = *((uint32_t*)ebp+5);
	arg[4] = *((uint32_t*)ebp+6);

	cprintf("Stack backtrace:\n");
	
	while(ebp != 0x00)
f0100ac3:	85 f6                	test   %esi,%esi
f0100ac5:	0f 85 2c ff ff ff    	jne    f01009f7 <mon_backtrace+0x51>
			arg[3] = *((uint32_t*)ebp+5);
			arg[4] = *((uint32_t*)ebp+6);
			
		}
	return 0;
}
f0100acb:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ad0:	81 c4 8c 00 00 00    	add    $0x8c,%esp
f0100ad6:	5b                   	pop    %ebx
f0100ad7:	5e                   	pop    %esi
f0100ad8:	5f                   	pop    %edi
f0100ad9:	5d                   	pop    %ebp
f0100ada:	c3                   	ret    

f0100adb <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100adb:	55                   	push   %ebp
f0100adc:	89 e5                	mov    %esp,%ebp
f0100ade:	57                   	push   %edi
f0100adf:	56                   	push   %esi
f0100ae0:	53                   	push   %ebx
f0100ae1:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("\033[0;32;40mWelcome to the \033[0;36;41mJOS kernel monitor!\033[0;37;40m\n");
f0100ae4:	c7 04 24 28 47 10 f0 	movl   $0xf0104728,(%esp)
f0100aeb:	e8 d6 24 00 00       	call   f0102fc6 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100af0:	c7 04 24 6c 47 10 f0 	movl   $0xf010476c,(%esp)
f0100af7:	e8 ca 24 00 00       	call   f0102fc6 <cprintf>


	while (1) {
		buf = readline("K> ");
f0100afc:	c7 04 24 37 44 10 f0 	movl   $0xf0104437,(%esp)
f0100b03:	e8 38 2e 00 00       	call   f0103940 <readline>
f0100b08:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100b0a:	85 c0                	test   %eax,%eax
f0100b0c:	74 ee                	je     f0100afc <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100b0e:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100b15:	be 00 00 00 00       	mov    $0x0,%esi
f0100b1a:	eb 06                	jmp    f0100b22 <monitor+0x47>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100b1c:	c6 03 00             	movb   $0x0,(%ebx)
f0100b1f:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100b22:	0f b6 03             	movzbl (%ebx),%eax
f0100b25:	84 c0                	test   %al,%al
f0100b27:	74 6a                	je     f0100b93 <monitor+0xb8>
f0100b29:	0f be c0             	movsbl %al,%eax
f0100b2c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b30:	c7 04 24 3b 44 10 f0 	movl   $0xf010443b,(%esp)
f0100b37:	e8 2f 30 00 00       	call   f0103b6b <strchr>
f0100b3c:	85 c0                	test   %eax,%eax
f0100b3e:	75 dc                	jne    f0100b1c <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f0100b40:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100b43:	74 4e                	je     f0100b93 <monitor+0xb8>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100b45:	83 fe 0f             	cmp    $0xf,%esi
f0100b48:	75 16                	jne    f0100b60 <monitor+0x85>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100b4a:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100b51:	00 
f0100b52:	c7 04 24 40 44 10 f0 	movl   $0xf0104440,(%esp)
f0100b59:	e8 68 24 00 00       	call   f0102fc6 <cprintf>
f0100b5e:	eb 9c                	jmp    f0100afc <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f0100b60:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100b64:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f0100b67:	0f b6 03             	movzbl (%ebx),%eax
f0100b6a:	84 c0                	test   %al,%al
f0100b6c:	75 0c                	jne    f0100b7a <monitor+0x9f>
f0100b6e:	eb b2                	jmp    f0100b22 <monitor+0x47>
			buf++;
f0100b70:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100b73:	0f b6 03             	movzbl (%ebx),%eax
f0100b76:	84 c0                	test   %al,%al
f0100b78:	74 a8                	je     f0100b22 <monitor+0x47>
f0100b7a:	0f be c0             	movsbl %al,%eax
f0100b7d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b81:	c7 04 24 3b 44 10 f0 	movl   $0xf010443b,(%esp)
f0100b88:	e8 de 2f 00 00       	call   f0103b6b <strchr>
f0100b8d:	85 c0                	test   %eax,%eax
f0100b8f:	74 df                	je     f0100b70 <monitor+0x95>
f0100b91:	eb 8f                	jmp    f0100b22 <monitor+0x47>
			buf++;
	}
	argv[argc] = 0;
f0100b93:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100b9a:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100b9b:	85 f6                	test   %esi,%esi
f0100b9d:	0f 84 59 ff ff ff    	je     f0100afc <monitor+0x21>
f0100ba3:	bb 20 48 10 f0       	mov    $0xf0104820,%ebx
f0100ba8:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100bad:	8b 03                	mov    (%ebx),%eax
f0100baf:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100bb3:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100bb6:	89 04 24             	mov    %eax,(%esp)
f0100bb9:	e8 32 2f 00 00       	call   f0103af0 <strcmp>
f0100bbe:	85 c0                	test   %eax,%eax
f0100bc0:	75 24                	jne    f0100be6 <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f0100bc2:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0100bc5:	8b 55 08             	mov    0x8(%ebp),%edx
f0100bc8:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100bcc:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100bcf:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100bd3:	89 34 24             	mov    %esi,(%esp)
f0100bd6:	ff 14 85 28 48 10 f0 	call   *-0xfefb7d8(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100bdd:	85 c0                	test   %eax,%eax
f0100bdf:	78 28                	js     f0100c09 <monitor+0x12e>
f0100be1:	e9 16 ff ff ff       	jmp    f0100afc <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100be6:	83 c7 01             	add    $0x1,%edi
f0100be9:	83 c3 0c             	add    $0xc,%ebx
f0100bec:	83 ff 05             	cmp    $0x5,%edi
f0100bef:	75 bc                	jne    f0100bad <monitor+0xd2>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100bf1:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100bf4:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100bf8:	c7 04 24 5d 44 10 f0 	movl   $0xf010445d,(%esp)
f0100bff:	e8 c2 23 00 00       	call   f0102fc6 <cprintf>
f0100c04:	e9 f3 fe ff ff       	jmp    f0100afc <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100c09:	83 c4 5c             	add    $0x5c,%esp
f0100c0c:	5b                   	pop    %ebx
f0100c0d:	5e                   	pop    %esi
f0100c0e:	5f                   	pop    %edi
f0100c0f:	5d                   	pop    %ebp
f0100c10:	c3                   	ret    

f0100c11 <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f0100c11:	55                   	push   %ebp
f0100c12:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f0100c14:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f0100c17:	5d                   	pop    %ebp
f0100c18:	c3                   	ret    
f0100c19:	00 00                	add    %al,(%eax)
	...

f0100c1c <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100c1c:	55                   	push   %ebp
f0100c1d:	89 e5                	mov    %esp,%ebp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100c1f:	83 3d 7c 85 11 f0 00 	cmpl   $0x0,0xf011857c
f0100c26:	75 11                	jne    f0100c39 <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100c28:	ba ab 99 11 f0       	mov    $0xf01199ab,%edx
f0100c2d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100c33:	89 15 7c 85 11 f0    	mov    %edx,0xf011857c
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = ROUNDUP(nextfree, PGSIZE);
f0100c39:	8b 15 7c 85 11 f0    	mov    0xf011857c,%edx
f0100c3f:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f0100c45:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	nextfree = result + n;
f0100c4b:	01 d0                	add    %edx,%eax
f0100c4d:	a3 7c 85 11 f0       	mov    %eax,0xf011857c
	//cprintf("\nnextfree:0x%08x",nextfree);
	return result;
}
f0100c52:	89 d0                	mov    %edx,%eax
f0100c54:	5d                   	pop    %ebp
f0100c55:	c3                   	ret    

f0100c56 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100c56:	55                   	push   %ebp
f0100c57:	89 e5                	mov    %esp,%ebp
f0100c59:	83 ec 18             	sub    $0x18,%esp
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100c5c:	89 d1                	mov    %edx,%ecx
f0100c5e:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100c61:	8b 0c 88             	mov    (%eax,%ecx,4),%ecx
		return ~0;
f0100c64:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100c69:	f6 c1 01             	test   $0x1,%cl
f0100c6c:	74 57                	je     f0100cc5 <check_va2pa+0x6f>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100c6e:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c74:	89 c8                	mov    %ecx,%eax
f0100c76:	c1 e8 0c             	shr    $0xc,%eax
f0100c79:	3b 05 a0 89 11 f0    	cmp    0xf01189a0,%eax
f0100c7f:	72 20                	jb     f0100ca1 <check_va2pa+0x4b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c81:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100c85:	c7 44 24 08 5c 48 10 	movl   $0xf010485c,0x8(%esp)
f0100c8c:	f0 
f0100c8d:	c7 44 24 04 f0 02 00 	movl   $0x2f0,0x4(%esp)
f0100c94:	00 
f0100c95:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0100c9c:	e8 f3 f3 ff ff       	call   f0100094 <_panic>
	if (!(p[PTX(va)] & PTE_P))
f0100ca1:	c1 ea 0c             	shr    $0xc,%edx
f0100ca4:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100caa:	8b 84 91 00 00 00 f0 	mov    -0x10000000(%ecx,%edx,4),%eax
f0100cb1:	89 c2                	mov    %eax,%edx
f0100cb3:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100cb6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100cbb:	85 d2                	test   %edx,%edx
f0100cbd:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100cc2:	0f 44 c2             	cmove  %edx,%eax
}
f0100cc5:	c9                   	leave  
f0100cc6:	c3                   	ret    

f0100cc7 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100cc7:	55                   	push   %ebp
f0100cc8:	89 e5                	mov    %esp,%ebp
f0100cca:	83 ec 18             	sub    $0x18,%esp
f0100ccd:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0100cd0:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0100cd3:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100cd5:	89 04 24             	mov    %eax,(%esp)
f0100cd8:	e8 7b 22 00 00       	call   f0102f58 <mc146818_read>
f0100cdd:	89 c6                	mov    %eax,%esi
f0100cdf:	83 c3 01             	add    $0x1,%ebx
f0100ce2:	89 1c 24             	mov    %ebx,(%esp)
f0100ce5:	e8 6e 22 00 00       	call   f0102f58 <mc146818_read>
f0100cea:	c1 e0 08             	shl    $0x8,%eax
f0100ced:	09 f0                	or     %esi,%eax
}
f0100cef:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0100cf2:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0100cf5:	89 ec                	mov    %ebp,%esp
f0100cf7:	5d                   	pop    %ebp
f0100cf8:	c3                   	ret    

f0100cf9 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100cf9:	55                   	push   %ebp
f0100cfa:	89 e5                	mov    %esp,%ebp
f0100cfc:	57                   	push   %edi
f0100cfd:	56                   	push   %esi
f0100cfe:	53                   	push   %ebx
f0100cff:	83 ec 3c             	sub    $0x3c,%esp
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100d02:	83 f8 01             	cmp    $0x1,%eax
f0100d05:	19 f6                	sbb    %esi,%esi
f0100d07:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
f0100d0d:	83 c6 01             	add    $0x1,%esi
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100d10:	8b 1d 80 85 11 f0    	mov    0xf0118580,%ebx
f0100d16:	85 db                	test   %ebx,%ebx
f0100d18:	75 1c                	jne    f0100d36 <check_page_free_list+0x3d>
		panic("'page_free_list' is a null pointer!");
f0100d1a:	c7 44 24 08 80 48 10 	movl   $0xf0104880,0x8(%esp)
f0100d21:	f0 
f0100d22:	c7 44 24 04 33 02 00 	movl   $0x233,0x4(%esp)
f0100d29:	00 
f0100d2a:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0100d31:	e8 5e f3 ff ff       	call   f0100094 <_panic>

	if (only_low_memory) {
f0100d36:	85 c0                	test   %eax,%eax
f0100d38:	74 50                	je     f0100d8a <check_page_free_list+0x91>
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
f0100d3a:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0100d3d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100d40:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100d43:	89 45 dc             	mov    %eax,-0x24(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d46:	89 d8                	mov    %ebx,%eax
f0100d48:	2b 05 a8 89 11 f0    	sub    0xf01189a8,%eax
f0100d4e:	c1 e0 09             	shl    $0x9,%eax
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100d51:	c1 e8 16             	shr    $0x16,%eax
f0100d54:	39 f0                	cmp    %esi,%eax
f0100d56:	0f 93 c0             	setae  %al
f0100d59:	0f b6 c0             	movzbl %al,%eax
			*tp[pagetype] = pp;
f0100d5c:	8b 54 85 d8          	mov    -0x28(%ebp,%eax,4),%edx
f0100d60:	89 1a                	mov    %ebx,(%edx)
			tp[pagetype] = &pp->pp_link;
f0100d62:	89 5c 85 d8          	mov    %ebx,-0x28(%ebp,%eax,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d66:	8b 1b                	mov    (%ebx),%ebx
f0100d68:	85 db                	test   %ebx,%ebx
f0100d6a:	75 da                	jne    f0100d46 <check_page_free_list+0x4d>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100d6c:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100d6f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100d75:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100d78:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100d7b:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100d7d:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100d80:	89 1d 80 85 11 f0    	mov    %ebx,0xf0118580
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100d86:	85 db                	test   %ebx,%ebx
f0100d88:	74 67                	je     f0100df1 <check_page_free_list+0xf8>
f0100d8a:	89 d8                	mov    %ebx,%eax
f0100d8c:	2b 05 a8 89 11 f0    	sub    0xf01189a8,%eax
f0100d92:	c1 f8 03             	sar    $0x3,%eax
f0100d95:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100d98:	89 c2                	mov    %eax,%edx
f0100d9a:	c1 ea 16             	shr    $0x16,%edx
f0100d9d:	39 f2                	cmp    %esi,%edx
f0100d9f:	73 4a                	jae    f0100deb <check_page_free_list+0xf2>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100da1:	89 c2                	mov    %eax,%edx
f0100da3:	c1 ea 0c             	shr    $0xc,%edx
f0100da6:	3b 15 a0 89 11 f0    	cmp    0xf01189a0,%edx
f0100dac:	72 20                	jb     f0100dce <check_page_free_list+0xd5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100dae:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100db2:	c7 44 24 08 5c 48 10 	movl   $0xf010485c,0x8(%esp)
f0100db9:	f0 
f0100dba:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100dc1:	00 
f0100dc2:	c7 04 24 50 4f 10 f0 	movl   $0xf0104f50,(%esp)
f0100dc9:	e8 c6 f2 ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100dce:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100dd5:	00 
f0100dd6:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100ddd:	00 
	return (void *)(pa + KERNBASE);
f0100dde:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100de3:	89 04 24             	mov    %eax,(%esp)
f0100de6:	e8 db 2d 00 00       	call   f0103bc6 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100deb:	8b 1b                	mov    (%ebx),%ebx
f0100ded:	85 db                	test   %ebx,%ebx
f0100def:	75 99                	jne    f0100d8a <check_page_free_list+0x91>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100df1:	b8 00 00 00 00       	mov    $0x0,%eax
f0100df6:	e8 21 fe ff ff       	call   f0100c1c <boot_alloc>
f0100dfb:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100dfe:	8b 15 80 85 11 f0    	mov    0xf0118580,%edx
f0100e04:	85 d2                	test   %edx,%edx
f0100e06:	0f 84 f6 01 00 00    	je     f0101002 <check_page_free_list+0x309>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100e0c:	8b 1d a8 89 11 f0    	mov    0xf01189a8,%ebx
f0100e12:	39 da                	cmp    %ebx,%edx
f0100e14:	72 4d                	jb     f0100e63 <check_page_free_list+0x16a>
		assert(pp < pages + npages);
f0100e16:	a1 a0 89 11 f0       	mov    0xf01189a0,%eax
f0100e1b:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100e1e:	8d 04 c3             	lea    (%ebx,%eax,8),%eax
f0100e21:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100e24:	39 c2                	cmp    %eax,%edx
f0100e26:	73 64                	jae    f0100e8c <check_page_free_list+0x193>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100e28:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0100e2b:	89 d0                	mov    %edx,%eax
f0100e2d:	29 d8                	sub    %ebx,%eax
f0100e2f:	a8 07                	test   $0x7,%al
f0100e31:	0f 85 82 00 00 00    	jne    f0100eb9 <check_page_free_list+0x1c0>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100e37:	c1 f8 03             	sar    $0x3,%eax
f0100e3a:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100e3d:	85 c0                	test   %eax,%eax
f0100e3f:	0f 84 a2 00 00 00    	je     f0100ee7 <check_page_free_list+0x1ee>
		assert(page2pa(pp) != IOPHYSMEM);
f0100e45:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100e4a:	0f 84 c2 00 00 00    	je     f0100f12 <check_page_free_list+0x219>
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100e50:	be 00 00 00 00       	mov    $0x0,%esi
f0100e55:	bf 00 00 00 00       	mov    $0x0,%edi
f0100e5a:	e9 d7 00 00 00       	jmp    f0100f36 <check_page_free_list+0x23d>
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100e5f:	39 da                	cmp    %ebx,%edx
f0100e61:	73 24                	jae    f0100e87 <check_page_free_list+0x18e>
f0100e63:	c7 44 24 0c 5e 4f 10 	movl   $0xf0104f5e,0xc(%esp)
f0100e6a:	f0 
f0100e6b:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0100e72:	f0 
f0100e73:	c7 44 24 04 4d 02 00 	movl   $0x24d,0x4(%esp)
f0100e7a:	00 
f0100e7b:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0100e82:	e8 0d f2 ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0100e87:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100e8a:	72 24                	jb     f0100eb0 <check_page_free_list+0x1b7>
f0100e8c:	c7 44 24 0c 7f 4f 10 	movl   $0xf0104f7f,0xc(%esp)
f0100e93:	f0 
f0100e94:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0100e9b:	f0 
f0100e9c:	c7 44 24 04 4e 02 00 	movl   $0x24e,0x4(%esp)
f0100ea3:	00 
f0100ea4:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0100eab:	e8 e4 f1 ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100eb0:	89 d0                	mov    %edx,%eax
f0100eb2:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100eb5:	a8 07                	test   $0x7,%al
f0100eb7:	74 24                	je     f0100edd <check_page_free_list+0x1e4>
f0100eb9:	c7 44 24 0c a4 48 10 	movl   $0xf01048a4,0xc(%esp)
f0100ec0:	f0 
f0100ec1:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0100ec8:	f0 
f0100ec9:	c7 44 24 04 4f 02 00 	movl   $0x24f,0x4(%esp)
f0100ed0:	00 
f0100ed1:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0100ed8:	e8 b7 f1 ff ff       	call   f0100094 <_panic>
f0100edd:	c1 f8 03             	sar    $0x3,%eax
f0100ee0:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100ee3:	85 c0                	test   %eax,%eax
f0100ee5:	75 24                	jne    f0100f0b <check_page_free_list+0x212>
f0100ee7:	c7 44 24 0c 93 4f 10 	movl   $0xf0104f93,0xc(%esp)
f0100eee:	f0 
f0100eef:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0100ef6:	f0 
f0100ef7:	c7 44 24 04 52 02 00 	movl   $0x252,0x4(%esp)
f0100efe:	00 
f0100eff:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0100f06:	e8 89 f1 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100f0b:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100f10:	75 24                	jne    f0100f36 <check_page_free_list+0x23d>
f0100f12:	c7 44 24 0c a4 4f 10 	movl   $0xf0104fa4,0xc(%esp)
f0100f19:	f0 
f0100f1a:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0100f21:	f0 
f0100f22:	c7 44 24 04 53 02 00 	movl   $0x253,0x4(%esp)
f0100f29:	00 
f0100f2a:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0100f31:	e8 5e f1 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100f36:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100f3b:	75 24                	jne    f0100f61 <check_page_free_list+0x268>
f0100f3d:	c7 44 24 0c d8 48 10 	movl   $0xf01048d8,0xc(%esp)
f0100f44:	f0 
f0100f45:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0100f4c:	f0 
f0100f4d:	c7 44 24 04 54 02 00 	movl   $0x254,0x4(%esp)
f0100f54:	00 
f0100f55:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0100f5c:	e8 33 f1 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100f61:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100f66:	75 24                	jne    f0100f8c <check_page_free_list+0x293>
f0100f68:	c7 44 24 0c bd 4f 10 	movl   $0xf0104fbd,0xc(%esp)
f0100f6f:	f0 
f0100f70:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0100f77:	f0 
f0100f78:	c7 44 24 04 55 02 00 	movl   $0x255,0x4(%esp)
f0100f7f:	00 
f0100f80:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0100f87:	e8 08 f1 ff ff       	call   f0100094 <_panic>
f0100f8c:	89 c1                	mov    %eax,%ecx
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100f8e:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100f93:	76 57                	jbe    f0100fec <check_page_free_list+0x2f3>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f95:	c1 e8 0c             	shr    $0xc,%eax
f0100f98:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100f9b:	77 20                	ja     f0100fbd <check_page_free_list+0x2c4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f9d:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100fa1:	c7 44 24 08 5c 48 10 	movl   $0xf010485c,0x8(%esp)
f0100fa8:	f0 
f0100fa9:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100fb0:	00 
f0100fb1:	c7 04 24 50 4f 10 f0 	movl   $0xf0104f50,(%esp)
f0100fb8:	e8 d7 f0 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100fbd:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f0100fc3:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0100fc6:	76 29                	jbe    f0100ff1 <check_page_free_list+0x2f8>
f0100fc8:	c7 44 24 0c fc 48 10 	movl   $0xf01048fc,0xc(%esp)
f0100fcf:	f0 
f0100fd0:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0100fd7:	f0 
f0100fd8:	c7 44 24 04 56 02 00 	movl   $0x256,0x4(%esp)
f0100fdf:	00 
f0100fe0:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0100fe7:	e8 a8 f0 ff ff       	call   f0100094 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100fec:	83 c7 01             	add    $0x1,%edi
f0100fef:	eb 03                	jmp    f0100ff4 <check_page_free_list+0x2fb>
		else
			++nfree_extmem;
f0100ff1:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ff4:	8b 12                	mov    (%edx),%edx
f0100ff6:	85 d2                	test   %edx,%edx
f0100ff8:	0f 85 61 fe ff ff    	jne    f0100e5f <check_page_free_list+0x166>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100ffe:	85 ff                	test   %edi,%edi
f0101000:	7f 24                	jg     f0101026 <check_page_free_list+0x32d>
f0101002:	c7 44 24 0c d7 4f 10 	movl   $0xf0104fd7,0xc(%esp)
f0101009:	f0 
f010100a:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0101011:	f0 
f0101012:	c7 44 24 04 5e 02 00 	movl   $0x25e,0x4(%esp)
f0101019:	00 
f010101a:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0101021:	e8 6e f0 ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f0101026:	85 f6                	test   %esi,%esi
f0101028:	7f 24                	jg     f010104e <check_page_free_list+0x355>
f010102a:	c7 44 24 0c e9 4f 10 	movl   $0xf0104fe9,0xc(%esp)
f0101031:	f0 
f0101032:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0101039:	f0 
f010103a:	c7 44 24 04 5f 02 00 	movl   $0x25f,0x4(%esp)
f0101041:	00 
f0101042:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0101049:	e8 46 f0 ff ff       	call   f0100094 <_panic>
}
f010104e:	83 c4 3c             	add    $0x3c,%esp
f0101051:	5b                   	pop    %ebx
f0101052:	5e                   	pop    %esi
f0101053:	5f                   	pop    %edi
f0101054:	5d                   	pop    %ebp
f0101055:	c3                   	ret    

f0101056 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0101056:	55                   	push   %ebp
f0101057:	89 e5                	mov    %esp,%ebp
f0101059:	56                   	push   %esi
f010105a:	53                   	push   %ebx
f010105b:	83 ec 10             	sub    $0x10,%esp
	// free pages!
	size_t i;
	//size_t a=0;
	//size_t b=0;
	//size_t c=0;
	page_free_list = NULL;
f010105e:	c7 05 80 85 11 f0 00 	movl   $0x0,0xf0118580
f0101065:	00 00 00 
	physaddr_t pgnum_IOPHYSMEM = PGNUM (IOPHYSMEM);
	physaddr_t pgnum_EXTPHYSMEM =PGNUM ( PADDR (ROUNDUP(pages+npages* sizeof (struct Page),PGSIZE)));
f0101068:	a1 a0 89 11 f0       	mov    0xf01189a0,%eax
f010106d:	89 c6                	mov    %eax,%esi
f010106f:	c1 e6 06             	shl    $0x6,%esi
f0101072:	03 35 a8 89 11 f0    	add    0xf01189a8,%esi
f0101078:	81 c6 ff 0f 00 00    	add    $0xfff,%esi
f010107e:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101084:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f010108a:	77 20                	ja     f01010ac <page_init+0x56>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010108c:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0101090:	c7 44 24 08 44 49 10 	movl   $0xf0104944,0x8(%esp)
f0101097:	f0 
f0101098:	c7 44 24 04 02 01 00 	movl   $0x102,0x4(%esp)
f010109f:	00 
f01010a0:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f01010a7:	e8 e8 ef ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01010ac:	81 c6 00 00 00 10    	add    $0x10000000,%esi
f01010b2:	c1 ee 0c             	shr    $0xc,%esi
	//PGNUM (ROUNDUP(pages+npages* sizeof (struct Page),PGSIZE))-PGNUM(kern_pgdir)+PGNUM(EXTPHYSMEM);
	for (i = 1; i < npages; i++) 
f01010b5:	83 f8 01             	cmp    $0x1,%eax
f01010b8:	76 6f                	jbe    f0101129 <page_init+0xd3>
f01010ba:	ba 08 00 00 00       	mov    $0x8,%edx
f01010bf:	b9 00 00 00 00       	mov    $0x0,%ecx
f01010c4:	b8 01 00 00 00       	mov    $0x1,%eax
	{
		
		
		if(i<pgnum_IOPHYSMEM)
f01010c9:	3d 9f 00 00 00       	cmp    $0x9f,%eax
f01010ce:	77 1a                	ja     f01010ea <page_init+0x94>
		{
			pages[i].pp_ref = 0;
f01010d0:	89 d3                	mov    %edx,%ebx
f01010d2:	03 1d a8 89 11 f0    	add    0xf01189a8,%ebx
f01010d8:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
			pages[i].pp_link = page_free_list;
f01010de:	89 0b                	mov    %ecx,(%ebx)
			page_free_list = &pages[i];
f01010e0:	89 d1                	mov    %edx,%ecx
f01010e2:	03 0d a8 89 11 f0    	add    0xf01189a8,%ecx
f01010e8:	eb 2b                	jmp    f0101115 <page_init+0xbf>
			//a++;
		}
		else if( i>pgnum_EXTPHYSMEM)
f01010ea:	39 c6                	cmp    %eax,%esi
f01010ec:	73 1a                	jae    f0101108 <page_init+0xb2>
		{
			pages[i].pp_ref = 0;
f01010ee:	8b 1d a8 89 11 f0    	mov    0xf01189a8,%ebx
f01010f4:	66 c7 44 13 04 00 00 	movw   $0x0,0x4(%ebx,%edx,1)
			pages[i].pp_link = page_free_list;
f01010fb:	89 0c 13             	mov    %ecx,(%ebx,%edx,1)
			page_free_list = &pages[i];
f01010fe:	89 d1                	mov    %edx,%ecx
f0101100:	03 0d a8 89 11 f0    	add    0xf01189a8,%ecx
f0101106:	eb 0d                	jmp    f0101115 <page_init+0xbf>
			//b++;
		}
		else
		{
			pages[i].pp_ref = 1;
f0101108:	8b 1d a8 89 11 f0    	mov    0xf01189a8,%ebx
f010110e:	66 c7 44 13 04 01 00 	movw   $0x1,0x4(%ebx,%edx,1)
	//size_t c=0;
	page_free_list = NULL;
	physaddr_t pgnum_IOPHYSMEM = PGNUM (IOPHYSMEM);
	physaddr_t pgnum_EXTPHYSMEM =PGNUM ( PADDR (ROUNDUP(pages+npages* sizeof (struct Page),PGSIZE)));
	//PGNUM (ROUNDUP(pages+npages* sizeof (struct Page),PGSIZE))-PGNUM(kern_pgdir)+PGNUM(EXTPHYSMEM);
	for (i = 1; i < npages; i++) 
f0101115:	83 c0 01             	add    $0x1,%eax
f0101118:	83 c2 08             	add    $0x8,%edx
f010111b:	39 05 a0 89 11 f0    	cmp    %eax,0xf01189a0
f0101121:	77 a6                	ja     f01010c9 <page_init+0x73>
f0101123:	89 0d 80 85 11 f0    	mov    %ecx,0xf0118580
			pages[i].pp_ref = 1;
			//c++;
		}
	}
	//cprintf("\n a:%d,b:%d c:%d  ",a,b,c);
}
f0101129:	83 c4 10             	add    $0x10,%esp
f010112c:	5b                   	pop    %ebx
f010112d:	5e                   	pop    %esi
f010112e:	5d                   	pop    %ebp
f010112f:	c3                   	ret    

f0101130 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct Page *
page_alloc(int alloc_flags)
{
f0101130:	55                   	push   %ebp
f0101131:	89 e5                	mov    %esp,%ebp
f0101133:	53                   	push   %ebx
f0101134:	83 ec 14             	sub    $0x14,%esp
f0101137:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	if ((alloc_flags==0 ||alloc_flags==ALLOC_ZERO)&& page_free_list!=NULL)
f010113a:	83 f8 01             	cmp    $0x1,%eax
f010113d:	77 71                	ja     f01011b0 <page_alloc+0x80>
f010113f:	8b 1d 80 85 11 f0    	mov    0xf0118580,%ebx
f0101145:	85 db                	test   %ebx,%ebx
f0101147:	74 6c                	je     f01011b5 <page_alloc+0x85>
	{
		struct Page * temp_alloc_page = page_free_list;
		if(page_free_list->pp_link!=NULL)
f0101149:	8b 13                	mov    (%ebx),%edx
			page_free_list=page_free_list->pp_link;
f010114b:	89 15 80 85 11 f0    	mov    %edx,0xf0118580
		else 
			page_free_list=NULL;
		if(alloc_flags==ALLOC_ZERO)
f0101151:	83 f8 01             	cmp    $0x1,%eax
f0101154:	75 5f                	jne    f01011b5 <page_alloc+0x85>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101156:	89 d8                	mov    %ebx,%eax
f0101158:	2b 05 a8 89 11 f0    	sub    0xf01189a8,%eax
f010115e:	c1 f8 03             	sar    $0x3,%eax
f0101161:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101164:	89 c2                	mov    %eax,%edx
f0101166:	c1 ea 0c             	shr    $0xc,%edx
f0101169:	3b 15 a0 89 11 f0    	cmp    0xf01189a0,%edx
f010116f:	72 20                	jb     f0101191 <page_alloc+0x61>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101171:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101175:	c7 44 24 08 5c 48 10 	movl   $0xf010485c,0x8(%esp)
f010117c:	f0 
f010117d:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101184:	00 
f0101185:	c7 04 24 50 4f 10 f0 	movl   $0xf0104f50,(%esp)
f010118c:	e8 03 ef ff ff       	call   f0100094 <_panic>
			memset(page2kva(temp_alloc_page), 0, PGSIZE);
f0101191:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101198:	00 
f0101199:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01011a0:	00 
	return (void *)(pa + KERNBASE);
f01011a1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01011a6:	89 04 24             	mov    %eax,(%esp)
f01011a9:	e8 18 2a 00 00       	call   f0103bc6 <memset>
f01011ae:	eb 05                	jmp    f01011b5 <page_alloc+0x85>
		return temp_alloc_page;
	}
	else
		return NULL;
f01011b0:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f01011b5:	89 d8                	mov    %ebx,%eax
f01011b7:	83 c4 14             	add    $0x14,%esp
f01011ba:	5b                   	pop    %ebx
f01011bb:	5d                   	pop    %ebp
f01011bc:	c3                   	ret    

f01011bd <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct Page *pp)
{
f01011bd:	55                   	push   %ebp
f01011be:	89 e5                	mov    %esp,%ebp
f01011c0:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
//	pp->pp_ref = 0;
	pp->pp_link = page_free_list;
f01011c3:	8b 15 80 85 11 f0    	mov    0xf0118580,%edx
f01011c9:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f01011cb:	a3 80 85 11 f0       	mov    %eax,0xf0118580
}
f01011d0:	5d                   	pop    %ebp
f01011d1:	c3                   	ret    

f01011d2 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct Page* pp)
{
f01011d2:	55                   	push   %ebp
f01011d3:	89 e5                	mov    %esp,%ebp
f01011d5:	83 ec 04             	sub    $0x4,%esp
f01011d8:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f01011db:	0f b7 50 04          	movzwl 0x4(%eax),%edx
f01011df:	83 ea 01             	sub    $0x1,%edx
f01011e2:	66 89 50 04          	mov    %dx,0x4(%eax)
f01011e6:	66 85 d2             	test   %dx,%dx
f01011e9:	75 08                	jne    f01011f3 <page_decref+0x21>
		page_free(pp);
f01011eb:	89 04 24             	mov    %eax,(%esp)
f01011ee:	e8 ca ff ff ff       	call   f01011bd <page_free>
}
f01011f3:	c9                   	leave  
f01011f4:	c3                   	ret    

f01011f5 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f01011f5:	55                   	push   %ebp
f01011f6:	89 e5                	mov    %esp,%ebp
f01011f8:	56                   	push   %esi
f01011f9:	53                   	push   %ebx
f01011fa:	83 ec 10             	sub    $0x10,%esp
f01011fd:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	pde_t *pde;//page directory entry,
	pte_t *pte;//page table entry
	pde=(pde_t *)pgdir+PDX(va);//get the entry of pde
f0101200:	89 f3                	mov    %esi,%ebx
f0101202:	c1 eb 16             	shr    $0x16,%ebx
f0101205:	c1 e3 02             	shl    $0x2,%ebx
f0101208:	03 5d 08             	add    0x8(%ebp),%ebx

	if (*pde & PTE_P)//the address exists
f010120b:	8b 03                	mov    (%ebx),%eax
f010120d:	a8 01                	test   $0x1,%al
f010120f:	74 44                	je     f0101255 <pgdir_walk+0x60>
	{
		pte=(pte_t *)KADDR(PTE_ADDR(*pde))+PTX(va);
f0101211:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101216:	89 c2                	mov    %eax,%edx
f0101218:	c1 ea 0c             	shr    $0xc,%edx
f010121b:	3b 15 a0 89 11 f0    	cmp    0xf01189a0,%edx
f0101221:	72 20                	jb     f0101243 <pgdir_walk+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101223:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101227:	c7 44 24 08 5c 48 10 	movl   $0xf010485c,0x8(%esp)
f010122e:	f0 
f010122f:	c7 44 24 04 73 01 00 	movl   $0x173,0x4(%esp)
f0101236:	00 
f0101237:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f010123e:	e8 51 ee ff ff       	call   f0100094 <_panic>
f0101243:	c1 ee 0a             	shr    $0xa,%esi
f0101246:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f010124c:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
		return pte;
f0101253:	eb 7d                	jmp    f01012d2 <pgdir_walk+0xdd>
	}
	//the page does not exist
	if (create )//create a new page table 
f0101255:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101259:	74 6b                	je     f01012c6 <pgdir_walk+0xd1>
	{	
		struct Page *pp;
		pp=page_alloc(ALLOC_ZERO);
f010125b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101262:	e8 c9 fe ff ff       	call   f0101130 <page_alloc>
		if (pp!=NULL)
f0101267:	85 c0                	test   %eax,%eax
f0101269:	74 62                	je     f01012cd <pgdir_walk+0xd8>
		{
			pp->pp_ref=1;
f010126b:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101271:	2b 05 a8 89 11 f0    	sub    0xf01189a8,%eax
f0101277:	c1 f8 03             	sar    $0x3,%eax
f010127a:	c1 e0 0c             	shl    $0xc,%eax
			*pde = page2pa(pp)|PTE_U|PTE_W|PTE_P ;
f010127d:	83 c8 07             	or     $0x7,%eax
f0101280:	89 03                	mov    %eax,(%ebx)
			pte=(pte_t *)KADDR(PTE_ADDR(*pde))+PTX(va);
f0101282:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101287:	89 c2                	mov    %eax,%edx
f0101289:	c1 ea 0c             	shr    $0xc,%edx
f010128c:	3b 15 a0 89 11 f0    	cmp    0xf01189a0,%edx
f0101292:	72 20                	jb     f01012b4 <pgdir_walk+0xbf>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101294:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101298:	c7 44 24 08 5c 48 10 	movl   $0xf010485c,0x8(%esp)
f010129f:	f0 
f01012a0:	c7 44 24 04 7f 01 00 	movl   $0x17f,0x4(%esp)
f01012a7:	00 
f01012a8:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f01012af:	e8 e0 ed ff ff       	call   f0100094 <_panic>
f01012b4:	c1 ee 0a             	shr    $0xa,%esi
f01012b7:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f01012bd:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
			return pte;
f01012c4:	eb 0c                	jmp    f01012d2 <pgdir_walk+0xdd>
		}
	}
	return NULL;
f01012c6:	b8 00 00 00 00       	mov    $0x0,%eax
f01012cb:	eb 05                	jmp    f01012d2 <pgdir_walk+0xdd>
f01012cd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01012d2:	83 c4 10             	add    $0x10,%esp
f01012d5:	5b                   	pop    %ebx
f01012d6:	5e                   	pop    %esi
f01012d7:	5d                   	pop    %ebp
f01012d8:	c3                   	ret    

f01012d9 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f01012d9:	55                   	push   %ebp
f01012da:	89 e5                	mov    %esp,%ebp
f01012dc:	57                   	push   %edi
f01012dd:	56                   	push   %esi
f01012de:	53                   	push   %ebx
f01012df:	83 ec 2c             	sub    $0x2c,%esp
f01012e2:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01012e5:	89 d7                	mov    %edx,%edi
f01012e7:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in
	if(size%PGSIZE!=0)
f01012ea:	f7 c1 ff 0f 00 00    	test   $0xfff,%ecx
f01012f0:	74 0f                	je     f0101301 <boot_map_region+0x28>
		size=ROUNDUP(size,PGSIZE);//panic(" Size must be a multiple of PGSIZE.");
f01012f2:	89 c8                	mov    %ecx,%eax
f01012f4:	05 ff 0f 00 00       	add    $0xfff,%eax
f01012f9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01012fe:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	pte_t *pte ;
	size_t i=0;
	while(i<size)
f0101301:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101305:	74 34                	je     f010133b <boot_map_region+0x62>
{
	// Fill this function in
	if(size%PGSIZE!=0)
		size=ROUNDUP(size,PGSIZE);//panic(" Size must be a multiple of PGSIZE.");
	pte_t *pte ;
	size_t i=0;
f0101307:	bb 00 00 00 00       	mov    $0x0,%ebx
// above UTOP. As such, it should *not* change the pp_ref field on the
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f010130c:	8b 75 08             	mov    0x8(%ebp),%esi
f010130f:	01 de                	add    %ebx,%esi
		size=ROUNDUP(size,PGSIZE);//panic(" Size must be a multiple of PGSIZE.");
	pte_t *pte ;
	size_t i=0;
	while(i<size)
	{
		pte=pgdir_walk(pgdir, (void *)va, 1);
f0101311:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101318:	00 
// above UTOP. As such, it should *not* change the pp_ref field on the
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f0101319:	8d 04 3b             	lea    (%ebx,%edi,1),%eax
		size=ROUNDUP(size,PGSIZE);//panic(" Size must be a multiple of PGSIZE.");
	pte_t *pte ;
	size_t i=0;
	while(i<size)
	{
		pte=pgdir_walk(pgdir, (void *)va, 1);
f010131c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101320:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101323:	89 04 24             	mov    %eax,(%esp)
f0101326:	e8 ca fe ff ff       	call   f01011f5 <pgdir_walk>
		*pte= pa|perm;
f010132b:	0b 75 0c             	or     0xc(%ebp),%esi
f010132e:	89 30                	mov    %esi,(%eax)
		pa+=PGSIZE;
		va+=PGSIZE;
		i+=PGSIZE;
f0101330:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// Fill this function in
	if(size%PGSIZE!=0)
		size=ROUNDUP(size,PGSIZE);//panic(" Size must be a multiple of PGSIZE.");
	pte_t *pte ;
	size_t i=0;
	while(i<size)
f0101336:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f0101339:	77 d1                	ja     f010130c <boot_map_region+0x33>
		*pte= pa|perm;
		pa+=PGSIZE;
		va+=PGSIZE;
		i+=PGSIZE;
	}
}
f010133b:	83 c4 2c             	add    $0x2c,%esp
f010133e:	5b                   	pop    %ebx
f010133f:	5e                   	pop    %esi
f0101340:	5f                   	pop    %edi
f0101341:	5d                   	pop    %ebp
f0101342:	c3                   	ret    

f0101343 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101343:	55                   	push   %ebp
f0101344:	89 e5                	mov    %esp,%ebp
f0101346:	53                   	push   %ebx
f0101347:	83 ec 14             	sub    $0x14,%esp
f010134a:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pte = pgdir_walk(pgdir,(void *)va, 0);
f010134d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101354:	00 
f0101355:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101358:	89 44 24 04          	mov    %eax,0x4(%esp)
f010135c:	8b 45 08             	mov    0x8(%ebp),%eax
f010135f:	89 04 24             	mov    %eax,(%esp)
f0101362:	e8 8e fe ff ff       	call   f01011f5 <pgdir_walk>
	if (pte==NULL)
f0101367:	85 c0                	test   %eax,%eax
f0101369:	74 3e                	je     f01013a9 <page_lookup+0x66>
	{
		return NULL;		
	}
	if (pte_store != 0) 
f010136b:	85 db                	test   %ebx,%ebx
f010136d:	74 02                	je     f0101371 <page_lookup+0x2e>
	{
		*pte_store = pte;
f010136f:	89 03                	mov    %eax,(%ebx)
	}
	if (*pte & PTE_P) 
f0101371:	8b 00                	mov    (%eax),%eax
f0101373:	a8 01                	test   $0x1,%al
f0101375:	74 39                	je     f01013b0 <page_lookup+0x6d>
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101377:	c1 e8 0c             	shr    $0xc,%eax
f010137a:	3b 05 a0 89 11 f0    	cmp    0xf01189a0,%eax
f0101380:	72 1c                	jb     f010139e <page_lookup+0x5b>
		panic("pa2page called with invalid pa");
f0101382:	c7 44 24 08 68 49 10 	movl   $0xf0104968,0x8(%esp)
f0101389:	f0 
f010138a:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f0101391:	00 
f0101392:	c7 04 24 50 4f 10 f0 	movl   $0xf0104f50,(%esp)
f0101399:	e8 f6 ec ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f010139e:	c1 e0 03             	shl    $0x3,%eax
f01013a1:	03 05 a8 89 11 f0    	add    0xf01189a8,%eax
	{
		return pa2page (PTE_ADDR (*pte));
f01013a7:	eb 0c                	jmp    f01013b5 <page_lookup+0x72>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t *pte = pgdir_walk(pgdir,(void *)va, 0);
	if (pte==NULL)
	{
		return NULL;		
f01013a9:	b8 00 00 00 00       	mov    $0x0,%eax
f01013ae:	eb 05                	jmp    f01013b5 <page_lookup+0x72>
	}
	if (*pte & PTE_P) 
	{
		return pa2page (PTE_ADDR (*pte));
	}
	return NULL;
f01013b0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01013b5:	83 c4 14             	add    $0x14,%esp
f01013b8:	5b                   	pop    %ebx
f01013b9:	5d                   	pop    %ebp
f01013ba:	c3                   	ret    

f01013bb <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01013bb:	55                   	push   %ebp
f01013bc:	89 e5                	mov    %esp,%ebp
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01013be:	8b 45 0c             	mov    0xc(%ebp),%eax
f01013c1:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01013c4:	5d                   	pop    %ebp
f01013c5:	c3                   	ret    

f01013c6 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01013c6:	55                   	push   %ebp
f01013c7:	89 e5                	mov    %esp,%ebp
f01013c9:	83 ec 28             	sub    $0x28,%esp
f01013cc:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f01013cf:	89 75 fc             	mov    %esi,-0x4(%ebp)
f01013d2:	8b 75 08             	mov    0x8(%ebp),%esi
f01013d5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *pte;
	struct Page *pp;
    	pp=page_lookup (pgdir, va, &pte);
f01013d8:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01013db:	89 44 24 08          	mov    %eax,0x8(%esp)
f01013df:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01013e3:	89 34 24             	mov    %esi,(%esp)
f01013e6:	e8 58 ff ff ff       	call   f0101343 <page_lookup>
	if (pp != NULL) 
f01013eb:	85 c0                	test   %eax,%eax
f01013ed:	74 21                	je     f0101410 <page_remove+0x4a>
	{
		page_decref (pp);//- The ref count on the physical page should decrement.
f01013ef:	89 04 24             	mov    %eax,(%esp)
f01013f2:	e8 db fd ff ff       	call   f01011d2 <page_decref>
//   - The physical page should be freed if the refcount reaches 0.
		if(pte!=NULL)
f01013f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01013fa:	85 c0                	test   %eax,%eax
f01013fc:	74 06                	je     f0101404 <page_remove+0x3e>
			*pte = 0;// The pg table entry corresponding to 'va' should be set to 0. (if such a PTE exists)
f01013fe:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		tlb_invalidate (pgdir, va);//The TLB must be invalidated if you remove an entry from  the page table.
f0101404:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101408:	89 34 24             	mov    %esi,(%esp)
f010140b:	e8 ab ff ff ff       	call   f01013bb <tlb_invalidate>
	}
}
f0101410:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0101413:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0101416:	89 ec                	mov    %ebp,%esp
f0101418:	5d                   	pop    %ebp
f0101419:	c3                   	ret    

f010141a <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{
f010141a:	55                   	push   %ebp
f010141b:	89 e5                	mov    %esp,%ebp
f010141d:	83 ec 28             	sub    $0x28,%esp
f0101420:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0101423:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0101426:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0101429:	8b 75 0c             	mov    0xc(%ebp),%esi
f010142c:	8b 7d 10             	mov    0x10(%ebp),%edi

	pte_t * pte = pgdir_walk(pgdir, (void *)va, 1) ;
f010142f:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101436:	00 
f0101437:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010143b:	8b 45 08             	mov    0x8(%ebp),%eax
f010143e:	89 04 24             	mov    %eax,(%esp)
f0101441:	e8 af fd ff ff       	call   f01011f5 <pgdir_walk>
f0101446:	89 c3                	mov    %eax,%ebx
//   - If necessary, on demand, a page table should be allocated and inserted
//     into 'pgdir'.
	if (pte==NULL)
f0101448:	85 c0                	test   %eax,%eax
f010144a:	74 66                	je     f01014b2 <page_insert+0x98>
		return -E_NO_MEM;
//-E_NO_MEM, if page table couldn't be allocated
	if (*pte & PTE_P) {
f010144c:	8b 00                	mov    (%eax),%eax
f010144e:	a8 01                	test   $0x1,%al
f0101450:	74 3c                	je     f010148e <page_insert+0x74>
		if (PTE_ADDR(*pte) == page2pa(pp))
f0101452:	25 00 f0 ff ff       	and    $0xfffff000,%eax
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101457:	89 f2                	mov    %esi,%edx
f0101459:	2b 15 a8 89 11 f0    	sub    0xf01189a8,%edx
f010145f:	c1 fa 03             	sar    $0x3,%edx
f0101462:	c1 e2 0c             	shl    $0xc,%edx
f0101465:	39 d0                	cmp    %edx,%eax
f0101467:	75 16                	jne    f010147f <page_insert+0x65>
		{	
			pp->pp_ref--;
f0101469:	66 83 6e 04 01       	subw   $0x1,0x4(%esi)
			tlb_invalidate(pgdir, va);
f010146e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101472:	8b 45 08             	mov    0x8(%ebp),%eax
f0101475:	89 04 24             	mov    %eax,(%esp)
f0101478:	e8 3e ff ff ff       	call   f01013bb <tlb_invalidate>
f010147d:	eb 0f                	jmp    f010148e <page_insert+0x74>
//The TLB must be invalidated if a page was formerly present at 'va'.
		} 
		else 
		{
			page_remove (pgdir, va);
f010147f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101483:	8b 45 08             	mov    0x8(%ebp),%eax
f0101486:	89 04 24             	mov    %eax,(%esp)
f0101489:	e8 38 ff ff ff       	call   f01013c6 <page_remove>
//If there is already a page mapped at 'va', it should be page_remove()d.
		}
	}

	*pte = page2pa(pp)|perm|PTE_P;
f010148e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101491:	83 c8 01             	or     $0x1,%eax
f0101494:	89 f2                	mov    %esi,%edx
f0101496:	2b 15 a8 89 11 f0    	sub    0xf01189a8,%edx
f010149c:	c1 fa 03             	sar    $0x3,%edx
f010149f:	c1 e2 0c             	shl    $0xc,%edx
f01014a2:	09 d0                	or     %edx,%eax
f01014a4:	89 03                	mov    %eax,(%ebx)
	pp->pp_ref++;
f01014a6:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
//pp->pp_ref should be incremented if the insertion succeeds.
	return 0;
f01014ab:	b8 00 00 00 00       	mov    $0x0,%eax
f01014b0:	eb 05                	jmp    f01014b7 <page_insert+0x9d>

	pte_t * pte = pgdir_walk(pgdir, (void *)va, 1) ;
//   - If necessary, on demand, a page table should be allocated and inserted
//     into 'pgdir'.
	if (pte==NULL)
		return -E_NO_MEM;
f01014b2:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	*pte = page2pa(pp)|perm|PTE_P;
	pp->pp_ref++;
//pp->pp_ref should be incremented if the insertion succeeds.
	return 0;
//0 on success
}
f01014b7:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01014ba:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01014bd:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01014c0:	89 ec                	mov    %ebp,%esp
f01014c2:	5d                   	pop    %ebp
f01014c3:	c3                   	ret    

f01014c4 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01014c4:	55                   	push   %ebp
f01014c5:	89 e5                	mov    %esp,%ebp
f01014c7:	57                   	push   %edi
f01014c8:	56                   	push   %esi
f01014c9:	53                   	push   %ebx
f01014ca:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f01014cd:	b8 15 00 00 00       	mov    $0x15,%eax
f01014d2:	e8 f0 f7 ff ff       	call   f0100cc7 <nvram_read>
f01014d7:	c1 e0 0a             	shl    $0xa,%eax
f01014da:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01014e0:	85 c0                	test   %eax,%eax
f01014e2:	0f 48 c2             	cmovs  %edx,%eax
f01014e5:	c1 f8 0c             	sar    $0xc,%eax
f01014e8:	a3 78 85 11 f0       	mov    %eax,0xf0118578
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01014ed:	b8 17 00 00 00       	mov    $0x17,%eax
f01014f2:	e8 d0 f7 ff ff       	call   f0100cc7 <nvram_read>
f01014f7:	c1 e0 0a             	shl    $0xa,%eax
f01014fa:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101500:	85 c0                	test   %eax,%eax
f0101502:	0f 48 c2             	cmovs  %edx,%eax
f0101505:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101508:	85 c0                	test   %eax,%eax
f010150a:	74 0e                	je     f010151a <mem_init+0x56>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f010150c:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101512:	89 15 a0 89 11 f0    	mov    %edx,0xf01189a0
f0101518:	eb 0c                	jmp    f0101526 <mem_init+0x62>
	else
		npages = npages_basemem;
f010151a:	8b 15 78 85 11 f0    	mov    0xf0118578,%edx
f0101520:	89 15 a0 89 11 f0    	mov    %edx,0xf01189a0

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f0101526:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101529:	c1 e8 0a             	shr    $0xa,%eax
f010152c:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f0101530:	a1 78 85 11 f0       	mov    0xf0118578,%eax
f0101535:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101538:	c1 e8 0a             	shr    $0xa,%eax
f010153b:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f010153f:	a1 a0 89 11 f0       	mov    0xf01189a0,%eax
f0101544:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101547:	c1 e8 0a             	shr    $0xa,%eax
f010154a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010154e:	c7 04 24 88 49 10 f0 	movl   $0xf0104988,(%esp)
f0101555:	e8 6c 1a 00 00       	call   f0102fc6 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010155a:	b8 00 10 00 00       	mov    $0x1000,%eax
f010155f:	e8 b8 f6 ff ff       	call   f0100c1c <boot_alloc>
f0101564:	a3 a4 89 11 f0       	mov    %eax,0xf01189a4
	memset(kern_pgdir, 0, PGSIZE);
f0101569:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101570:	00 
f0101571:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101578:	00 
f0101579:	89 04 24             	mov    %eax,(%esp)
f010157c:	e8 45 26 00 00       	call   f0103bc6 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following two lines.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101581:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101586:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010158b:	77 20                	ja     f01015ad <mem_init+0xe9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010158d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101591:	c7 44 24 08 44 49 10 	movl   $0xf0104944,0x8(%esp)
f0101598:	f0 
f0101599:	c7 44 24 04 8b 00 00 	movl   $0x8b,0x4(%esp)
f01015a0:	00 
f01015a1:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f01015a8:	e8 e7 ea ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01015ad:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01015b3:	83 ca 05             	or     $0x5,%edx
f01015b6:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct Page in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:

	pages =(struct Page *) boot_alloc(npages* sizeof (struct Page));
f01015bc:	a1 a0 89 11 f0       	mov    0xf01189a0,%eax
f01015c1:	c1 e0 03             	shl    $0x3,%eax
f01015c4:	e8 53 f6 ff ff       	call   f0100c1c <boot_alloc>
f01015c9:	a3 a8 89 11 f0       	mov    %eax,0xf01189a8
	memset(pages, 0, npages* sizeof (struct Page));
f01015ce:	8b 15 a0 89 11 f0    	mov    0xf01189a0,%edx
f01015d4:	c1 e2 03             	shl    $0x3,%edx
f01015d7:	89 54 24 08          	mov    %edx,0x8(%esp)
f01015db:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01015e2:	00 
f01015e3:	89 04 24             	mov    %eax,(%esp)
f01015e6:	e8 db 25 00 00       	call   f0103bc6 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01015eb:	e8 66 fa ff ff       	call   f0101056 <page_init>
	check_page_free_list(1);
f01015f0:	b8 01 00 00 00       	mov    $0x1,%eax
f01015f5:	e8 ff f6 ff ff       	call   f0100cf9 <check_page_free_list>
	int nfree;
	struct Page *fl;
	char *c;
	int i;

	if (!pages)
f01015fa:	83 3d a8 89 11 f0 00 	cmpl   $0x0,0xf01189a8
f0101601:	75 1c                	jne    f010161f <mem_init+0x15b>
		panic("'pages' is a null pointer!");
f0101603:	c7 44 24 08 fa 4f 10 	movl   $0xf0104ffa,0x8(%esp)
f010160a:	f0 
f010160b:	c7 44 24 04 70 02 00 	movl   $0x270,0x4(%esp)
f0101612:	00 
f0101613:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f010161a:	e8 75 ea ff ff       	call   f0100094 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010161f:	a1 80 85 11 f0       	mov    0xf0118580,%eax
f0101624:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101629:	85 c0                	test   %eax,%eax
f010162b:	74 09                	je     f0101636 <mem_init+0x172>
		++nfree;
f010162d:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101630:	8b 00                	mov    (%eax),%eax
f0101632:	85 c0                	test   %eax,%eax
f0101634:	75 f7                	jne    f010162d <mem_init+0x169>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101636:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010163d:	e8 ee fa ff ff       	call   f0101130 <page_alloc>
f0101642:	89 c6                	mov    %eax,%esi
f0101644:	85 c0                	test   %eax,%eax
f0101646:	75 24                	jne    f010166c <mem_init+0x1a8>
f0101648:	c7 44 24 0c 15 50 10 	movl   $0xf0105015,0xc(%esp)
f010164f:	f0 
f0101650:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0101657:	f0 
f0101658:	c7 44 24 04 78 02 00 	movl   $0x278,0x4(%esp)
f010165f:	00 
f0101660:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0101667:	e8 28 ea ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f010166c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101673:	e8 b8 fa ff ff       	call   f0101130 <page_alloc>
f0101678:	89 c7                	mov    %eax,%edi
f010167a:	85 c0                	test   %eax,%eax
f010167c:	75 24                	jne    f01016a2 <mem_init+0x1de>
f010167e:	c7 44 24 0c 2b 50 10 	movl   $0xf010502b,0xc(%esp)
f0101685:	f0 
f0101686:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f010168d:	f0 
f010168e:	c7 44 24 04 79 02 00 	movl   $0x279,0x4(%esp)
f0101695:	00 
f0101696:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f010169d:	e8 f2 e9 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01016a2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016a9:	e8 82 fa ff ff       	call   f0101130 <page_alloc>
f01016ae:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01016b1:	85 c0                	test   %eax,%eax
f01016b3:	75 24                	jne    f01016d9 <mem_init+0x215>
f01016b5:	c7 44 24 0c 41 50 10 	movl   $0xf0105041,0xc(%esp)
f01016bc:	f0 
f01016bd:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f01016c4:	f0 
f01016c5:	c7 44 24 04 7a 02 00 	movl   $0x27a,0x4(%esp)
f01016cc:	00 
f01016cd:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f01016d4:	e8 bb e9 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01016d9:	39 fe                	cmp    %edi,%esi
f01016db:	75 24                	jne    f0101701 <mem_init+0x23d>
f01016dd:	c7 44 24 0c 57 50 10 	movl   $0xf0105057,0xc(%esp)
f01016e4:	f0 
f01016e5:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f01016ec:	f0 
f01016ed:	c7 44 24 04 7d 02 00 	movl   $0x27d,0x4(%esp)
f01016f4:	00 
f01016f5:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f01016fc:	e8 93 e9 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101701:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101704:	74 05                	je     f010170b <mem_init+0x247>
f0101706:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101709:	75 24                	jne    f010172f <mem_init+0x26b>
f010170b:	c7 44 24 0c c4 49 10 	movl   $0xf01049c4,0xc(%esp)
f0101712:	f0 
f0101713:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f010171a:	f0 
f010171b:	c7 44 24 04 7e 02 00 	movl   $0x27e,0x4(%esp)
f0101722:	00 
f0101723:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f010172a:	e8 65 e9 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f010172f:	8b 15 a8 89 11 f0    	mov    0xf01189a8,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101735:	a1 a0 89 11 f0       	mov    0xf01189a0,%eax
f010173a:	c1 e0 0c             	shl    $0xc,%eax
f010173d:	89 f1                	mov    %esi,%ecx
f010173f:	29 d1                	sub    %edx,%ecx
f0101741:	c1 f9 03             	sar    $0x3,%ecx
f0101744:	c1 e1 0c             	shl    $0xc,%ecx
f0101747:	39 c1                	cmp    %eax,%ecx
f0101749:	72 24                	jb     f010176f <mem_init+0x2ab>
f010174b:	c7 44 24 0c 69 50 10 	movl   $0xf0105069,0xc(%esp)
f0101752:	f0 
f0101753:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f010175a:	f0 
f010175b:	c7 44 24 04 7f 02 00 	movl   $0x27f,0x4(%esp)
f0101762:	00 
f0101763:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f010176a:	e8 25 e9 ff ff       	call   f0100094 <_panic>
f010176f:	89 f9                	mov    %edi,%ecx
f0101771:	29 d1                	sub    %edx,%ecx
f0101773:	c1 f9 03             	sar    $0x3,%ecx
f0101776:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101779:	39 c8                	cmp    %ecx,%eax
f010177b:	77 24                	ja     f01017a1 <mem_init+0x2dd>
f010177d:	c7 44 24 0c 86 50 10 	movl   $0xf0105086,0xc(%esp)
f0101784:	f0 
f0101785:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f010178c:	f0 
f010178d:	c7 44 24 04 80 02 00 	movl   $0x280,0x4(%esp)
f0101794:	00 
f0101795:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f010179c:	e8 f3 e8 ff ff       	call   f0100094 <_panic>
f01017a1:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01017a4:	29 d1                	sub    %edx,%ecx
f01017a6:	89 ca                	mov    %ecx,%edx
f01017a8:	c1 fa 03             	sar    $0x3,%edx
f01017ab:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f01017ae:	39 d0                	cmp    %edx,%eax
f01017b0:	77 24                	ja     f01017d6 <mem_init+0x312>
f01017b2:	c7 44 24 0c a3 50 10 	movl   $0xf01050a3,0xc(%esp)
f01017b9:	f0 
f01017ba:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f01017c1:	f0 
f01017c2:	c7 44 24 04 81 02 00 	movl   $0x281,0x4(%esp)
f01017c9:	00 
f01017ca:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f01017d1:	e8 be e8 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01017d6:	a1 80 85 11 f0       	mov    0xf0118580,%eax
f01017db:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01017de:	c7 05 80 85 11 f0 00 	movl   $0x0,0xf0118580
f01017e5:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01017e8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017ef:	e8 3c f9 ff ff       	call   f0101130 <page_alloc>
f01017f4:	85 c0                	test   %eax,%eax
f01017f6:	74 24                	je     f010181c <mem_init+0x358>
f01017f8:	c7 44 24 0c c0 50 10 	movl   $0xf01050c0,0xc(%esp)
f01017ff:	f0 
f0101800:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0101807:	f0 
f0101808:	c7 44 24 04 88 02 00 	movl   $0x288,0x4(%esp)
f010180f:	00 
f0101810:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0101817:	e8 78 e8 ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f010181c:	89 34 24             	mov    %esi,(%esp)
f010181f:	e8 99 f9 ff ff       	call   f01011bd <page_free>
	page_free(pp1);
f0101824:	89 3c 24             	mov    %edi,(%esp)
f0101827:	e8 91 f9 ff ff       	call   f01011bd <page_free>
	page_free(pp2);
f010182c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010182f:	89 04 24             	mov    %eax,(%esp)
f0101832:	e8 86 f9 ff ff       	call   f01011bd <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101837:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010183e:	e8 ed f8 ff ff       	call   f0101130 <page_alloc>
f0101843:	89 c6                	mov    %eax,%esi
f0101845:	85 c0                	test   %eax,%eax
f0101847:	75 24                	jne    f010186d <mem_init+0x3a9>
f0101849:	c7 44 24 0c 15 50 10 	movl   $0xf0105015,0xc(%esp)
f0101850:	f0 
f0101851:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0101858:	f0 
f0101859:	c7 44 24 04 8f 02 00 	movl   $0x28f,0x4(%esp)
f0101860:	00 
f0101861:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0101868:	e8 27 e8 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f010186d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101874:	e8 b7 f8 ff ff       	call   f0101130 <page_alloc>
f0101879:	89 c7                	mov    %eax,%edi
f010187b:	85 c0                	test   %eax,%eax
f010187d:	75 24                	jne    f01018a3 <mem_init+0x3df>
f010187f:	c7 44 24 0c 2b 50 10 	movl   $0xf010502b,0xc(%esp)
f0101886:	f0 
f0101887:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f010188e:	f0 
f010188f:	c7 44 24 04 90 02 00 	movl   $0x290,0x4(%esp)
f0101896:	00 
f0101897:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f010189e:	e8 f1 e7 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01018a3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018aa:	e8 81 f8 ff ff       	call   f0101130 <page_alloc>
f01018af:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01018b2:	85 c0                	test   %eax,%eax
f01018b4:	75 24                	jne    f01018da <mem_init+0x416>
f01018b6:	c7 44 24 0c 41 50 10 	movl   $0xf0105041,0xc(%esp)
f01018bd:	f0 
f01018be:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f01018c5:	f0 
f01018c6:	c7 44 24 04 91 02 00 	movl   $0x291,0x4(%esp)
f01018cd:	00 
f01018ce:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f01018d5:	e8 ba e7 ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01018da:	39 fe                	cmp    %edi,%esi
f01018dc:	75 24                	jne    f0101902 <mem_init+0x43e>
f01018de:	c7 44 24 0c 57 50 10 	movl   $0xf0105057,0xc(%esp)
f01018e5:	f0 
f01018e6:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f01018ed:	f0 
f01018ee:	c7 44 24 04 93 02 00 	movl   $0x293,0x4(%esp)
f01018f5:	00 
f01018f6:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f01018fd:	e8 92 e7 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101902:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101905:	74 05                	je     f010190c <mem_init+0x448>
f0101907:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f010190a:	75 24                	jne    f0101930 <mem_init+0x46c>
f010190c:	c7 44 24 0c c4 49 10 	movl   $0xf01049c4,0xc(%esp)
f0101913:	f0 
f0101914:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f010191b:	f0 
f010191c:	c7 44 24 04 94 02 00 	movl   $0x294,0x4(%esp)
f0101923:	00 
f0101924:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f010192b:	e8 64 e7 ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f0101930:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101937:	e8 f4 f7 ff ff       	call   f0101130 <page_alloc>
f010193c:	85 c0                	test   %eax,%eax
f010193e:	74 24                	je     f0101964 <mem_init+0x4a0>
f0101940:	c7 44 24 0c c0 50 10 	movl   $0xf01050c0,0xc(%esp)
f0101947:	f0 
f0101948:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f010194f:	f0 
f0101950:	c7 44 24 04 95 02 00 	movl   $0x295,0x4(%esp)
f0101957:	00 
f0101958:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f010195f:	e8 30 e7 ff ff       	call   f0100094 <_panic>
f0101964:	89 f0                	mov    %esi,%eax
f0101966:	2b 05 a8 89 11 f0    	sub    0xf01189a8,%eax
f010196c:	c1 f8 03             	sar    $0x3,%eax
f010196f:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101972:	89 c2                	mov    %eax,%edx
f0101974:	c1 ea 0c             	shr    $0xc,%edx
f0101977:	3b 15 a0 89 11 f0    	cmp    0xf01189a0,%edx
f010197d:	72 20                	jb     f010199f <mem_init+0x4db>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010197f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101983:	c7 44 24 08 5c 48 10 	movl   $0xf010485c,0x8(%esp)
f010198a:	f0 
f010198b:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101992:	00 
f0101993:	c7 04 24 50 4f 10 f0 	movl   $0xf0104f50,(%esp)
f010199a:	e8 f5 e6 ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010199f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01019a6:	00 
f01019a7:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01019ae:	00 
	return (void *)(pa + KERNBASE);
f01019af:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01019b4:	89 04 24             	mov    %eax,(%esp)
f01019b7:	e8 0a 22 00 00       	call   f0103bc6 <memset>
	page_free(pp0);
f01019bc:	89 34 24             	mov    %esi,(%esp)
f01019bf:	e8 f9 f7 ff ff       	call   f01011bd <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01019c4:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01019cb:	e8 60 f7 ff ff       	call   f0101130 <page_alloc>
f01019d0:	85 c0                	test   %eax,%eax
f01019d2:	75 24                	jne    f01019f8 <mem_init+0x534>
f01019d4:	c7 44 24 0c cf 50 10 	movl   $0xf01050cf,0xc(%esp)
f01019db:	f0 
f01019dc:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f01019e3:	f0 
f01019e4:	c7 44 24 04 9a 02 00 	movl   $0x29a,0x4(%esp)
f01019eb:	00 
f01019ec:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f01019f3:	e8 9c e6 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f01019f8:	39 c6                	cmp    %eax,%esi
f01019fa:	74 24                	je     f0101a20 <mem_init+0x55c>
f01019fc:	c7 44 24 0c ed 50 10 	movl   $0xf01050ed,0xc(%esp)
f0101a03:	f0 
f0101a04:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0101a0b:	f0 
f0101a0c:	c7 44 24 04 9b 02 00 	movl   $0x29b,0x4(%esp)
f0101a13:	00 
f0101a14:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0101a1b:	e8 74 e6 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101a20:	89 f2                	mov    %esi,%edx
f0101a22:	2b 15 a8 89 11 f0    	sub    0xf01189a8,%edx
f0101a28:	c1 fa 03             	sar    $0x3,%edx
f0101a2b:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101a2e:	89 d0                	mov    %edx,%eax
f0101a30:	c1 e8 0c             	shr    $0xc,%eax
f0101a33:	3b 05 a0 89 11 f0    	cmp    0xf01189a0,%eax
f0101a39:	72 20                	jb     f0101a5b <mem_init+0x597>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101a3b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101a3f:	c7 44 24 08 5c 48 10 	movl   $0xf010485c,0x8(%esp)
f0101a46:	f0 
f0101a47:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101a4e:	00 
f0101a4f:	c7 04 24 50 4f 10 f0 	movl   $0xf0104f50,(%esp)
f0101a56:	e8 39 e6 ff ff       	call   f0100094 <_panic>
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101a5b:	80 ba 00 00 00 f0 00 	cmpb   $0x0,-0x10000000(%edx)
f0101a62:	75 11                	jne    f0101a75 <mem_init+0x5b1>
f0101a64:	8d 82 01 00 00 f0    	lea    -0xfffffff(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0101a6a:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101a70:	80 38 00             	cmpb   $0x0,(%eax)
f0101a73:	74 24                	je     f0101a99 <mem_init+0x5d5>
f0101a75:	c7 44 24 0c fd 50 10 	movl   $0xf01050fd,0xc(%esp)
f0101a7c:	f0 
f0101a7d:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0101a84:	f0 
f0101a85:	c7 44 24 04 9e 02 00 	movl   $0x29e,0x4(%esp)
f0101a8c:	00 
f0101a8d:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0101a94:	e8 fb e5 ff ff       	call   f0100094 <_panic>
f0101a99:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101a9c:	39 d0                	cmp    %edx,%eax
f0101a9e:	75 d0                	jne    f0101a70 <mem_init+0x5ac>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101aa0:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101aa3:	89 15 80 85 11 f0    	mov    %edx,0xf0118580

	// free the pages we took
	page_free(pp0);
f0101aa9:	89 34 24             	mov    %esi,(%esp)
f0101aac:	e8 0c f7 ff ff       	call   f01011bd <page_free>
	page_free(pp1);
f0101ab1:	89 3c 24             	mov    %edi,(%esp)
f0101ab4:	e8 04 f7 ff ff       	call   f01011bd <page_free>
	page_free(pp2);
f0101ab9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101abc:	89 04 24             	mov    %eax,(%esp)
f0101abf:	e8 f9 f6 ff ff       	call   f01011bd <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101ac4:	a1 80 85 11 f0       	mov    0xf0118580,%eax
f0101ac9:	85 c0                	test   %eax,%eax
f0101acb:	74 09                	je     f0101ad6 <mem_init+0x612>
		--nfree;
f0101acd:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101ad0:	8b 00                	mov    (%eax),%eax
f0101ad2:	85 c0                	test   %eax,%eax
f0101ad4:	75 f7                	jne    f0101acd <mem_init+0x609>
		--nfree;
	assert(nfree == 0);
f0101ad6:	85 db                	test   %ebx,%ebx
f0101ad8:	74 24                	je     f0101afe <mem_init+0x63a>
f0101ada:	c7 44 24 0c 07 51 10 	movl   $0xf0105107,0xc(%esp)
f0101ae1:	f0 
f0101ae2:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0101ae9:	f0 
f0101aea:	c7 44 24 04 ab 02 00 	movl   $0x2ab,0x4(%esp)
f0101af1:	00 
f0101af2:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0101af9:	e8 96 e5 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101afe:	c7 04 24 e4 49 10 f0 	movl   $0xf01049e4,(%esp)
f0101b05:	e8 bc 14 00 00       	call   f0102fc6 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101b0a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b11:	e8 1a f6 ff ff       	call   f0101130 <page_alloc>
f0101b16:	89 c3                	mov    %eax,%ebx
f0101b18:	85 c0                	test   %eax,%eax
f0101b1a:	75 24                	jne    f0101b40 <mem_init+0x67c>
f0101b1c:	c7 44 24 0c 15 50 10 	movl   $0xf0105015,0xc(%esp)
f0101b23:	f0 
f0101b24:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0101b2b:	f0 
f0101b2c:	c7 44 24 04 04 03 00 	movl   $0x304,0x4(%esp)
f0101b33:	00 
f0101b34:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0101b3b:	e8 54 e5 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101b40:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b47:	e8 e4 f5 ff ff       	call   f0101130 <page_alloc>
f0101b4c:	89 c7                	mov    %eax,%edi
f0101b4e:	85 c0                	test   %eax,%eax
f0101b50:	75 24                	jne    f0101b76 <mem_init+0x6b2>
f0101b52:	c7 44 24 0c 2b 50 10 	movl   $0xf010502b,0xc(%esp)
f0101b59:	f0 
f0101b5a:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0101b61:	f0 
f0101b62:	c7 44 24 04 05 03 00 	movl   $0x305,0x4(%esp)
f0101b69:	00 
f0101b6a:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0101b71:	e8 1e e5 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101b76:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b7d:	e8 ae f5 ff ff       	call   f0101130 <page_alloc>
f0101b82:	89 c6                	mov    %eax,%esi
f0101b84:	85 c0                	test   %eax,%eax
f0101b86:	75 24                	jne    f0101bac <mem_init+0x6e8>
f0101b88:	c7 44 24 0c 41 50 10 	movl   $0xf0105041,0xc(%esp)
f0101b8f:	f0 
f0101b90:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0101b97:	f0 
f0101b98:	c7 44 24 04 06 03 00 	movl   $0x306,0x4(%esp)
f0101b9f:	00 
f0101ba0:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0101ba7:	e8 e8 e4 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101bac:	39 fb                	cmp    %edi,%ebx
f0101bae:	75 24                	jne    f0101bd4 <mem_init+0x710>
f0101bb0:	c7 44 24 0c 57 50 10 	movl   $0xf0105057,0xc(%esp)
f0101bb7:	f0 
f0101bb8:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0101bbf:	f0 
f0101bc0:	c7 44 24 04 09 03 00 	movl   $0x309,0x4(%esp)
f0101bc7:	00 
f0101bc8:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0101bcf:	e8 c0 e4 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101bd4:	39 c7                	cmp    %eax,%edi
f0101bd6:	74 04                	je     f0101bdc <mem_init+0x718>
f0101bd8:	39 c3                	cmp    %eax,%ebx
f0101bda:	75 24                	jne    f0101c00 <mem_init+0x73c>
f0101bdc:	c7 44 24 0c c4 49 10 	movl   $0xf01049c4,0xc(%esp)
f0101be3:	f0 
f0101be4:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0101beb:	f0 
f0101bec:	c7 44 24 04 0a 03 00 	movl   $0x30a,0x4(%esp)
f0101bf3:	00 
f0101bf4:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0101bfb:	e8 94 e4 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101c00:	8b 15 80 85 11 f0    	mov    0xf0118580,%edx
f0101c06:	89 55 cc             	mov    %edx,-0x34(%ebp)
	page_free_list = 0;
f0101c09:	c7 05 80 85 11 f0 00 	movl   $0x0,0xf0118580
f0101c10:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101c13:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c1a:	e8 11 f5 ff ff       	call   f0101130 <page_alloc>
f0101c1f:	85 c0                	test   %eax,%eax
f0101c21:	74 24                	je     f0101c47 <mem_init+0x783>
f0101c23:	c7 44 24 0c c0 50 10 	movl   $0xf01050c0,0xc(%esp)
f0101c2a:	f0 
f0101c2b:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0101c32:	f0 
f0101c33:	c7 44 24 04 11 03 00 	movl   $0x311,0x4(%esp)
f0101c3a:	00 
f0101c3b:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0101c42:	e8 4d e4 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101c47:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101c4a:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101c4e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101c55:	00 
f0101c56:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0101c5b:	89 04 24             	mov    %eax,(%esp)
f0101c5e:	e8 e0 f6 ff ff       	call   f0101343 <page_lookup>
f0101c63:	85 c0                	test   %eax,%eax
f0101c65:	74 24                	je     f0101c8b <mem_init+0x7c7>
f0101c67:	c7 44 24 0c 04 4a 10 	movl   $0xf0104a04,0xc(%esp)
f0101c6e:	f0 
f0101c6f:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0101c76:	f0 
f0101c77:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
f0101c7e:	00 
f0101c7f:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0101c86:	e8 09 e4 ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101c8b:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101c92:	00 
f0101c93:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101c9a:	00 
f0101c9b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101c9f:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0101ca4:	89 04 24             	mov    %eax,(%esp)
f0101ca7:	e8 6e f7 ff ff       	call   f010141a <page_insert>
f0101cac:	85 c0                	test   %eax,%eax
f0101cae:	78 24                	js     f0101cd4 <mem_init+0x810>
f0101cb0:	c7 44 24 0c 3c 4a 10 	movl   $0xf0104a3c,0xc(%esp)
f0101cb7:	f0 
f0101cb8:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0101cbf:	f0 
f0101cc0:	c7 44 24 04 17 03 00 	movl   $0x317,0x4(%esp)
f0101cc7:	00 
f0101cc8:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0101ccf:	e8 c0 e3 ff ff       	call   f0100094 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101cd4:	89 1c 24             	mov    %ebx,(%esp)
f0101cd7:	e8 e1 f4 ff ff       	call   f01011bd <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101cdc:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101ce3:	00 
f0101ce4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101ceb:	00 
f0101cec:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101cf0:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0101cf5:	89 04 24             	mov    %eax,(%esp)
f0101cf8:	e8 1d f7 ff ff       	call   f010141a <page_insert>
f0101cfd:	85 c0                	test   %eax,%eax
f0101cff:	74 24                	je     f0101d25 <mem_init+0x861>
f0101d01:	c7 44 24 0c 6c 4a 10 	movl   $0xf0104a6c,0xc(%esp)
f0101d08:	f0 
f0101d09:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0101d10:	f0 
f0101d11:	c7 44 24 04 1b 03 00 	movl   $0x31b,0x4(%esp)
f0101d18:	00 
f0101d19:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0101d20:	e8 6f e3 ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101d25:	8b 0d a4 89 11 f0    	mov    0xf01189a4,%ecx
f0101d2b:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101d2e:	a1 a8 89 11 f0       	mov    0xf01189a8,%eax
f0101d33:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101d36:	8b 11                	mov    (%ecx),%edx
f0101d38:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101d3e:	89 d8                	mov    %ebx,%eax
f0101d40:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0101d43:	c1 f8 03             	sar    $0x3,%eax
f0101d46:	c1 e0 0c             	shl    $0xc,%eax
f0101d49:	39 c2                	cmp    %eax,%edx
f0101d4b:	74 24                	je     f0101d71 <mem_init+0x8ad>
f0101d4d:	c7 44 24 0c 9c 4a 10 	movl   $0xf0104a9c,0xc(%esp)
f0101d54:	f0 
f0101d55:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0101d5c:	f0 
f0101d5d:	c7 44 24 04 1c 03 00 	movl   $0x31c,0x4(%esp)
f0101d64:	00 
f0101d65:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0101d6c:	e8 23 e3 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101d71:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d76:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d79:	e8 d8 ee ff ff       	call   f0100c56 <check_va2pa>
f0101d7e:	89 fa                	mov    %edi,%edx
f0101d80:	2b 55 d0             	sub    -0x30(%ebp),%edx
f0101d83:	c1 fa 03             	sar    $0x3,%edx
f0101d86:	c1 e2 0c             	shl    $0xc,%edx
f0101d89:	39 d0                	cmp    %edx,%eax
f0101d8b:	74 24                	je     f0101db1 <mem_init+0x8ed>
f0101d8d:	c7 44 24 0c c4 4a 10 	movl   $0xf0104ac4,0xc(%esp)
f0101d94:	f0 
f0101d95:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0101d9c:	f0 
f0101d9d:	c7 44 24 04 1d 03 00 	movl   $0x31d,0x4(%esp)
f0101da4:	00 
f0101da5:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0101dac:	e8 e3 e2 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0101db1:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101db6:	74 24                	je     f0101ddc <mem_init+0x918>
f0101db8:	c7 44 24 0c 12 51 10 	movl   $0xf0105112,0xc(%esp)
f0101dbf:	f0 
f0101dc0:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0101dc7:	f0 
f0101dc8:	c7 44 24 04 1e 03 00 	movl   $0x31e,0x4(%esp)
f0101dcf:	00 
f0101dd0:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0101dd7:	e8 b8 e2 ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0101ddc:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101de1:	74 24                	je     f0101e07 <mem_init+0x943>
f0101de3:	c7 44 24 0c 23 51 10 	movl   $0xf0105123,0xc(%esp)
f0101dea:	f0 
f0101deb:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0101df2:	f0 
f0101df3:	c7 44 24 04 1f 03 00 	movl   $0x31f,0x4(%esp)
f0101dfa:	00 
f0101dfb:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0101e02:	e8 8d e2 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101e07:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101e0e:	00 
f0101e0f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101e16:	00 
f0101e17:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101e1b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101e1e:	89 14 24             	mov    %edx,(%esp)
f0101e21:	e8 f4 f5 ff ff       	call   f010141a <page_insert>
f0101e26:	85 c0                	test   %eax,%eax
f0101e28:	74 24                	je     f0101e4e <mem_init+0x98a>
f0101e2a:	c7 44 24 0c f4 4a 10 	movl   $0xf0104af4,0xc(%esp)
f0101e31:	f0 
f0101e32:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0101e39:	f0 
f0101e3a:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f0101e41:	00 
f0101e42:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0101e49:	e8 46 e2 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101e4e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e53:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0101e58:	e8 f9 ed ff ff       	call   f0100c56 <check_va2pa>
f0101e5d:	89 f2                	mov    %esi,%edx
f0101e5f:	2b 15 a8 89 11 f0    	sub    0xf01189a8,%edx
f0101e65:	c1 fa 03             	sar    $0x3,%edx
f0101e68:	c1 e2 0c             	shl    $0xc,%edx
f0101e6b:	39 d0                	cmp    %edx,%eax
f0101e6d:	74 24                	je     f0101e93 <mem_init+0x9cf>
f0101e6f:	c7 44 24 0c 30 4b 10 	movl   $0xf0104b30,0xc(%esp)
f0101e76:	f0 
f0101e77:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0101e7e:	f0 
f0101e7f:	c7 44 24 04 23 03 00 	movl   $0x323,0x4(%esp)
f0101e86:	00 
f0101e87:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0101e8e:	e8 01 e2 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101e93:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101e98:	74 24                	je     f0101ebe <mem_init+0x9fa>
f0101e9a:	c7 44 24 0c 34 51 10 	movl   $0xf0105134,0xc(%esp)
f0101ea1:	f0 
f0101ea2:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0101ea9:	f0 
f0101eaa:	c7 44 24 04 24 03 00 	movl   $0x324,0x4(%esp)
f0101eb1:	00 
f0101eb2:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0101eb9:	e8 d6 e1 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101ebe:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ec5:	e8 66 f2 ff ff       	call   f0101130 <page_alloc>
f0101eca:	85 c0                	test   %eax,%eax
f0101ecc:	74 24                	je     f0101ef2 <mem_init+0xa2e>
f0101ece:	c7 44 24 0c c0 50 10 	movl   $0xf01050c0,0xc(%esp)
f0101ed5:	f0 
f0101ed6:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0101edd:	f0 
f0101ede:	c7 44 24 04 27 03 00 	movl   $0x327,0x4(%esp)
f0101ee5:	00 
f0101ee6:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0101eed:	e8 a2 e1 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ef2:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101ef9:	00 
f0101efa:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101f01:	00 
f0101f02:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101f06:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0101f0b:	89 04 24             	mov    %eax,(%esp)
f0101f0e:	e8 07 f5 ff ff       	call   f010141a <page_insert>
f0101f13:	85 c0                	test   %eax,%eax
f0101f15:	74 24                	je     f0101f3b <mem_init+0xa77>
f0101f17:	c7 44 24 0c f4 4a 10 	movl   $0xf0104af4,0xc(%esp)
f0101f1e:	f0 
f0101f1f:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0101f26:	f0 
f0101f27:	c7 44 24 04 2a 03 00 	movl   $0x32a,0x4(%esp)
f0101f2e:	00 
f0101f2f:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0101f36:	e8 59 e1 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101f3b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f40:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0101f45:	e8 0c ed ff ff       	call   f0100c56 <check_va2pa>
f0101f4a:	89 f2                	mov    %esi,%edx
f0101f4c:	2b 15 a8 89 11 f0    	sub    0xf01189a8,%edx
f0101f52:	c1 fa 03             	sar    $0x3,%edx
f0101f55:	c1 e2 0c             	shl    $0xc,%edx
f0101f58:	39 d0                	cmp    %edx,%eax
f0101f5a:	74 24                	je     f0101f80 <mem_init+0xabc>
f0101f5c:	c7 44 24 0c 30 4b 10 	movl   $0xf0104b30,0xc(%esp)
f0101f63:	f0 
f0101f64:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0101f6b:	f0 
f0101f6c:	c7 44 24 04 2b 03 00 	movl   $0x32b,0x4(%esp)
f0101f73:	00 
f0101f74:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0101f7b:	e8 14 e1 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101f80:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101f85:	74 24                	je     f0101fab <mem_init+0xae7>
f0101f87:	c7 44 24 0c 34 51 10 	movl   $0xf0105134,0xc(%esp)
f0101f8e:	f0 
f0101f8f:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0101f96:	f0 
f0101f97:	c7 44 24 04 2c 03 00 	movl   $0x32c,0x4(%esp)
f0101f9e:	00 
f0101f9f:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0101fa6:	e8 e9 e0 ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101fab:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101fb2:	e8 79 f1 ff ff       	call   f0101130 <page_alloc>
f0101fb7:	85 c0                	test   %eax,%eax
f0101fb9:	74 24                	je     f0101fdf <mem_init+0xb1b>
f0101fbb:	c7 44 24 0c c0 50 10 	movl   $0xf01050c0,0xc(%esp)
f0101fc2:	f0 
f0101fc3:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0101fca:	f0 
f0101fcb:	c7 44 24 04 30 03 00 	movl   $0x330,0x4(%esp)
f0101fd2:	00 
f0101fd3:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0101fda:	e8 b5 e0 ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101fdf:	8b 15 a4 89 11 f0    	mov    0xf01189a4,%edx
f0101fe5:	8b 02                	mov    (%edx),%eax
f0101fe7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fec:	89 c1                	mov    %eax,%ecx
f0101fee:	c1 e9 0c             	shr    $0xc,%ecx
f0101ff1:	3b 0d a0 89 11 f0    	cmp    0xf01189a0,%ecx
f0101ff7:	72 20                	jb     f0102019 <mem_init+0xb55>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101ff9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101ffd:	c7 44 24 08 5c 48 10 	movl   $0xf010485c,0x8(%esp)
f0102004:	f0 
f0102005:	c7 44 24 04 33 03 00 	movl   $0x333,0x4(%esp)
f010200c:	00 
f010200d:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0102014:	e8 7b e0 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0102019:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010201e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0102021:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102028:	00 
f0102029:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102030:	00 
f0102031:	89 14 24             	mov    %edx,(%esp)
f0102034:	e8 bc f1 ff ff       	call   f01011f5 <pgdir_walk>
f0102039:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010203c:	83 c2 04             	add    $0x4,%edx
f010203f:	39 d0                	cmp    %edx,%eax
f0102041:	74 24                	je     f0102067 <mem_init+0xba3>
f0102043:	c7 44 24 0c 60 4b 10 	movl   $0xf0104b60,0xc(%esp)
f010204a:	f0 
f010204b:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0102052:	f0 
f0102053:	c7 44 24 04 34 03 00 	movl   $0x334,0x4(%esp)
f010205a:	00 
f010205b:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0102062:	e8 2d e0 ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102067:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f010206e:	00 
f010206f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102076:	00 
f0102077:	89 74 24 04          	mov    %esi,0x4(%esp)
f010207b:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0102080:	89 04 24             	mov    %eax,(%esp)
f0102083:	e8 92 f3 ff ff       	call   f010141a <page_insert>
f0102088:	85 c0                	test   %eax,%eax
f010208a:	74 24                	je     f01020b0 <mem_init+0xbec>
f010208c:	c7 44 24 0c a0 4b 10 	movl   $0xf0104ba0,0xc(%esp)
f0102093:	f0 
f0102094:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f010209b:	f0 
f010209c:	c7 44 24 04 37 03 00 	movl   $0x337,0x4(%esp)
f01020a3:	00 
f01020a4:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f01020ab:	e8 e4 df ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01020b0:	8b 0d a4 89 11 f0    	mov    0xf01189a4,%ecx
f01020b6:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f01020b9:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020be:	89 c8                	mov    %ecx,%eax
f01020c0:	e8 91 eb ff ff       	call   f0100c56 <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01020c5:	89 f2                	mov    %esi,%edx
f01020c7:	2b 15 a8 89 11 f0    	sub    0xf01189a8,%edx
f01020cd:	c1 fa 03             	sar    $0x3,%edx
f01020d0:	c1 e2 0c             	shl    $0xc,%edx
f01020d3:	39 d0                	cmp    %edx,%eax
f01020d5:	74 24                	je     f01020fb <mem_init+0xc37>
f01020d7:	c7 44 24 0c 30 4b 10 	movl   $0xf0104b30,0xc(%esp)
f01020de:	f0 
f01020df:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f01020e6:	f0 
f01020e7:	c7 44 24 04 38 03 00 	movl   $0x338,0x4(%esp)
f01020ee:	00 
f01020ef:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f01020f6:	e8 99 df ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f01020fb:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102100:	74 24                	je     f0102126 <mem_init+0xc62>
f0102102:	c7 44 24 0c 34 51 10 	movl   $0xf0105134,0xc(%esp)
f0102109:	f0 
f010210a:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0102111:	f0 
f0102112:	c7 44 24 04 39 03 00 	movl   $0x339,0x4(%esp)
f0102119:	00 
f010211a:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0102121:	e8 6e df ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0102126:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010212d:	00 
f010212e:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102135:	00 
f0102136:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102139:	89 04 24             	mov    %eax,(%esp)
f010213c:	e8 b4 f0 ff ff       	call   f01011f5 <pgdir_walk>
f0102141:	f6 00 04             	testb  $0x4,(%eax)
f0102144:	75 24                	jne    f010216a <mem_init+0xca6>
f0102146:	c7 44 24 0c e0 4b 10 	movl   $0xf0104be0,0xc(%esp)
f010214d:	f0 
f010214e:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0102155:	f0 
f0102156:	c7 44 24 04 3a 03 00 	movl   $0x33a,0x4(%esp)
f010215d:	00 
f010215e:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0102165:	e8 2a df ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f010216a:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f010216f:	f6 00 04             	testb  $0x4,(%eax)
f0102172:	75 24                	jne    f0102198 <mem_init+0xcd4>
f0102174:	c7 44 24 0c 45 51 10 	movl   $0xf0105145,0xc(%esp)
f010217b:	f0 
f010217c:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0102183:	f0 
f0102184:	c7 44 24 04 3b 03 00 	movl   $0x33b,0x4(%esp)
f010218b:	00 
f010218c:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0102193:	e8 fc de ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102198:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010219f:	00 
f01021a0:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f01021a7:	00 
f01021a8:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01021ac:	89 04 24             	mov    %eax,(%esp)
f01021af:	e8 66 f2 ff ff       	call   f010141a <page_insert>
f01021b4:	85 c0                	test   %eax,%eax
f01021b6:	78 24                	js     f01021dc <mem_init+0xd18>
f01021b8:	c7 44 24 0c 14 4c 10 	movl   $0xf0104c14,0xc(%esp)
f01021bf:	f0 
f01021c0:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f01021c7:	f0 
f01021c8:	c7 44 24 04 3e 03 00 	movl   $0x33e,0x4(%esp)
f01021cf:	00 
f01021d0:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f01021d7:	e8 b8 de ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f01021dc:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01021e3:	00 
f01021e4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01021eb:	00 
f01021ec:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01021f0:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f01021f5:	89 04 24             	mov    %eax,(%esp)
f01021f8:	e8 1d f2 ff ff       	call   f010141a <page_insert>
f01021fd:	85 c0                	test   %eax,%eax
f01021ff:	74 24                	je     f0102225 <mem_init+0xd61>
f0102201:	c7 44 24 0c 4c 4c 10 	movl   $0xf0104c4c,0xc(%esp)
f0102208:	f0 
f0102209:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0102210:	f0 
f0102211:	c7 44 24 04 41 03 00 	movl   $0x341,0x4(%esp)
f0102218:	00 
f0102219:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0102220:	e8 6f de ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102225:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010222c:	00 
f010222d:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102234:	00 
f0102235:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f010223a:	89 04 24             	mov    %eax,(%esp)
f010223d:	e8 b3 ef ff ff       	call   f01011f5 <pgdir_walk>
f0102242:	f6 00 04             	testb  $0x4,(%eax)
f0102245:	74 24                	je     f010226b <mem_init+0xda7>
f0102247:	c7 44 24 0c 88 4c 10 	movl   $0xf0104c88,0xc(%esp)
f010224e:	f0 
f010224f:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0102256:	f0 
f0102257:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f010225e:	00 
f010225f:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0102266:	e8 29 de ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010226b:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0102270:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102273:	ba 00 00 00 00       	mov    $0x0,%edx
f0102278:	e8 d9 e9 ff ff       	call   f0100c56 <check_va2pa>
f010227d:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102280:	89 f8                	mov    %edi,%eax
f0102282:	2b 05 a8 89 11 f0    	sub    0xf01189a8,%eax
f0102288:	c1 f8 03             	sar    $0x3,%eax
f010228b:	c1 e0 0c             	shl    $0xc,%eax
f010228e:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102291:	74 24                	je     f01022b7 <mem_init+0xdf3>
f0102293:	c7 44 24 0c c0 4c 10 	movl   $0xf0104cc0,0xc(%esp)
f010229a:	f0 
f010229b:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f01022a2:	f0 
f01022a3:	c7 44 24 04 45 03 00 	movl   $0x345,0x4(%esp)
f01022aa:	00 
f01022ab:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f01022b2:	e8 dd dd ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01022b7:	ba 00 10 00 00       	mov    $0x1000,%edx
f01022bc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022bf:	e8 92 e9 ff ff       	call   f0100c56 <check_va2pa>
f01022c4:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01022c7:	74 24                	je     f01022ed <mem_init+0xe29>
f01022c9:	c7 44 24 0c ec 4c 10 	movl   $0xf0104cec,0xc(%esp)
f01022d0:	f0 
f01022d1:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f01022d8:	f0 
f01022d9:	c7 44 24 04 46 03 00 	movl   $0x346,0x4(%esp)
f01022e0:	00 
f01022e1:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f01022e8:	e8 a7 dd ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f01022ed:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f01022f2:	74 24                	je     f0102318 <mem_init+0xe54>
f01022f4:	c7 44 24 0c 5b 51 10 	movl   $0xf010515b,0xc(%esp)
f01022fb:	f0 
f01022fc:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0102303:	f0 
f0102304:	c7 44 24 04 48 03 00 	movl   $0x348,0x4(%esp)
f010230b:	00 
f010230c:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0102313:	e8 7c dd ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102318:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010231d:	74 24                	je     f0102343 <mem_init+0xe7f>
f010231f:	c7 44 24 0c 6c 51 10 	movl   $0xf010516c,0xc(%esp)
f0102326:	f0 
f0102327:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f010232e:	f0 
f010232f:	c7 44 24 04 49 03 00 	movl   $0x349,0x4(%esp)
f0102336:	00 
f0102337:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f010233e:	e8 51 dd ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102343:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010234a:	e8 e1 ed ff ff       	call   f0101130 <page_alloc>
f010234f:	85 c0                	test   %eax,%eax
f0102351:	74 04                	je     f0102357 <mem_init+0xe93>
f0102353:	39 c6                	cmp    %eax,%esi
f0102355:	74 24                	je     f010237b <mem_init+0xeb7>
f0102357:	c7 44 24 0c 1c 4d 10 	movl   $0xf0104d1c,0xc(%esp)
f010235e:	f0 
f010235f:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0102366:	f0 
f0102367:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f010236e:	00 
f010236f:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0102376:	e8 19 dd ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f010237b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102382:	00 
f0102383:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0102388:	89 04 24             	mov    %eax,(%esp)
f010238b:	e8 36 f0 ff ff       	call   f01013c6 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102390:	8b 15 a4 89 11 f0    	mov    0xf01189a4,%edx
f0102396:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0102399:	ba 00 00 00 00       	mov    $0x0,%edx
f010239e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01023a1:	e8 b0 e8 ff ff       	call   f0100c56 <check_va2pa>
f01023a6:	83 f8 ff             	cmp    $0xffffffff,%eax
f01023a9:	74 24                	je     f01023cf <mem_init+0xf0b>
f01023ab:	c7 44 24 0c 40 4d 10 	movl   $0xf0104d40,0xc(%esp)
f01023b2:	f0 
f01023b3:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f01023ba:	f0 
f01023bb:	c7 44 24 04 50 03 00 	movl   $0x350,0x4(%esp)
f01023c2:	00 
f01023c3:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f01023ca:	e8 c5 dc ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01023cf:	ba 00 10 00 00       	mov    $0x1000,%edx
f01023d4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01023d7:	e8 7a e8 ff ff       	call   f0100c56 <check_va2pa>
f01023dc:	89 fa                	mov    %edi,%edx
f01023de:	2b 15 a8 89 11 f0    	sub    0xf01189a8,%edx
f01023e4:	c1 fa 03             	sar    $0x3,%edx
f01023e7:	c1 e2 0c             	shl    $0xc,%edx
f01023ea:	39 d0                	cmp    %edx,%eax
f01023ec:	74 24                	je     f0102412 <mem_init+0xf4e>
f01023ee:	c7 44 24 0c ec 4c 10 	movl   $0xf0104cec,0xc(%esp)
f01023f5:	f0 
f01023f6:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f01023fd:	f0 
f01023fe:	c7 44 24 04 51 03 00 	movl   $0x351,0x4(%esp)
f0102405:	00 
f0102406:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f010240d:	e8 82 dc ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0102412:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102417:	74 24                	je     f010243d <mem_init+0xf79>
f0102419:	c7 44 24 0c 12 51 10 	movl   $0xf0105112,0xc(%esp)
f0102420:	f0 
f0102421:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0102428:	f0 
f0102429:	c7 44 24 04 52 03 00 	movl   $0x352,0x4(%esp)
f0102430:	00 
f0102431:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0102438:	e8 57 dc ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f010243d:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102442:	74 24                	je     f0102468 <mem_init+0xfa4>
f0102444:	c7 44 24 0c 6c 51 10 	movl   $0xf010516c,0xc(%esp)
f010244b:	f0 
f010244c:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0102453:	f0 
f0102454:	c7 44 24 04 53 03 00 	movl   $0x353,0x4(%esp)
f010245b:	00 
f010245c:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0102463:	e8 2c dc ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102468:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010246f:	00 
f0102470:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102473:	89 0c 24             	mov    %ecx,(%esp)
f0102476:	e8 4b ef ff ff       	call   f01013c6 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010247b:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0102480:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102483:	ba 00 00 00 00       	mov    $0x0,%edx
f0102488:	e8 c9 e7 ff ff       	call   f0100c56 <check_va2pa>
f010248d:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102490:	74 24                	je     f01024b6 <mem_init+0xff2>
f0102492:	c7 44 24 0c 40 4d 10 	movl   $0xf0104d40,0xc(%esp)
f0102499:	f0 
f010249a:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f01024a1:	f0 
f01024a2:	c7 44 24 04 57 03 00 	movl   $0x357,0x4(%esp)
f01024a9:	00 
f01024aa:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f01024b1:	e8 de db ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01024b6:	ba 00 10 00 00       	mov    $0x1000,%edx
f01024bb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01024be:	e8 93 e7 ff ff       	call   f0100c56 <check_va2pa>
f01024c3:	83 f8 ff             	cmp    $0xffffffff,%eax
f01024c6:	74 24                	je     f01024ec <mem_init+0x1028>
f01024c8:	c7 44 24 0c 64 4d 10 	movl   $0xf0104d64,0xc(%esp)
f01024cf:	f0 
f01024d0:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f01024d7:	f0 
f01024d8:	c7 44 24 04 58 03 00 	movl   $0x358,0x4(%esp)
f01024df:	00 
f01024e0:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f01024e7:	e8 a8 db ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f01024ec:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01024f1:	74 24                	je     f0102517 <mem_init+0x1053>
f01024f3:	c7 44 24 0c 7d 51 10 	movl   $0xf010517d,0xc(%esp)
f01024fa:	f0 
f01024fb:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0102502:	f0 
f0102503:	c7 44 24 04 59 03 00 	movl   $0x359,0x4(%esp)
f010250a:	00 
f010250b:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0102512:	e8 7d db ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102517:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010251c:	74 24                	je     f0102542 <mem_init+0x107e>
f010251e:	c7 44 24 0c 6c 51 10 	movl   $0xf010516c,0xc(%esp)
f0102525:	f0 
f0102526:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f010252d:	f0 
f010252e:	c7 44 24 04 5a 03 00 	movl   $0x35a,0x4(%esp)
f0102535:	00 
f0102536:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f010253d:	e8 52 db ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102542:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102549:	e8 e2 eb ff ff       	call   f0101130 <page_alloc>
f010254e:	85 c0                	test   %eax,%eax
f0102550:	74 04                	je     f0102556 <mem_init+0x1092>
f0102552:	39 c7                	cmp    %eax,%edi
f0102554:	74 24                	je     f010257a <mem_init+0x10b6>
f0102556:	c7 44 24 0c 8c 4d 10 	movl   $0xf0104d8c,0xc(%esp)
f010255d:	f0 
f010255e:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0102565:	f0 
f0102566:	c7 44 24 04 5d 03 00 	movl   $0x35d,0x4(%esp)
f010256d:	00 
f010256e:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0102575:	e8 1a db ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010257a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102581:	e8 aa eb ff ff       	call   f0101130 <page_alloc>
f0102586:	85 c0                	test   %eax,%eax
f0102588:	74 24                	je     f01025ae <mem_init+0x10ea>
f010258a:	c7 44 24 0c c0 50 10 	movl   $0xf01050c0,0xc(%esp)
f0102591:	f0 
f0102592:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0102599:	f0 
f010259a:	c7 44 24 04 60 03 00 	movl   $0x360,0x4(%esp)
f01025a1:	00 
f01025a2:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f01025a9:	e8 e6 da ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01025ae:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f01025b3:	8b 08                	mov    (%eax),%ecx
f01025b5:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01025bb:	89 da                	mov    %ebx,%edx
f01025bd:	2b 15 a8 89 11 f0    	sub    0xf01189a8,%edx
f01025c3:	c1 fa 03             	sar    $0x3,%edx
f01025c6:	c1 e2 0c             	shl    $0xc,%edx
f01025c9:	39 d1                	cmp    %edx,%ecx
f01025cb:	74 24                	je     f01025f1 <mem_init+0x112d>
f01025cd:	c7 44 24 0c 9c 4a 10 	movl   $0xf0104a9c,0xc(%esp)
f01025d4:	f0 
f01025d5:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f01025dc:	f0 
f01025dd:	c7 44 24 04 63 03 00 	movl   $0x363,0x4(%esp)
f01025e4:	00 
f01025e5:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f01025ec:	e8 a3 da ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f01025f1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f01025f7:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01025fc:	74 24                	je     f0102622 <mem_init+0x115e>
f01025fe:	c7 44 24 0c 23 51 10 	movl   $0xf0105123,0xc(%esp)
f0102605:	f0 
f0102606:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f010260d:	f0 
f010260e:	c7 44 24 04 65 03 00 	movl   $0x365,0x4(%esp)
f0102615:	00 
f0102616:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f010261d:	e8 72 da ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102622:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102628:	89 1c 24             	mov    %ebx,(%esp)
f010262b:	e8 8d eb ff ff       	call   f01011bd <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102630:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102637:	00 
f0102638:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f010263f:	00 
f0102640:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0102645:	89 04 24             	mov    %eax,(%esp)
f0102648:	e8 a8 eb ff ff       	call   f01011f5 <pgdir_walk>
f010264d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102650:	8b 0d a4 89 11 f0    	mov    0xf01189a4,%ecx
f0102656:	8b 51 04             	mov    0x4(%ecx),%edx
f0102659:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010265f:	89 55 d4             	mov    %edx,-0x2c(%ebp)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102662:	8b 15 a0 89 11 f0    	mov    0xf01189a0,%edx
f0102668:	89 55 c8             	mov    %edx,-0x38(%ebp)
f010266b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010266e:	c1 ea 0c             	shr    $0xc,%edx
f0102671:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102674:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0102677:	39 55 d0             	cmp    %edx,-0x30(%ebp)
f010267a:	72 23                	jb     f010269f <mem_init+0x11db>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010267c:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010267f:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0102683:	c7 44 24 08 5c 48 10 	movl   $0xf010485c,0x8(%esp)
f010268a:	f0 
f010268b:	c7 44 24 04 6c 03 00 	movl   $0x36c,0x4(%esp)
f0102692:	00 
f0102693:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f010269a:	e8 f5 d9 ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f010269f:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01026a2:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f01026a8:	39 d0                	cmp    %edx,%eax
f01026aa:	74 24                	je     f01026d0 <mem_init+0x120c>
f01026ac:	c7 44 24 0c 8e 51 10 	movl   $0xf010518e,0xc(%esp)
f01026b3:	f0 
f01026b4:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f01026bb:	f0 
f01026bc:	c7 44 24 04 6d 03 00 	movl   $0x36d,0x4(%esp)
f01026c3:	00 
f01026c4:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f01026cb:	e8 c4 d9 ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f01026d0:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f01026d7:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01026dd:	89 d8                	mov    %ebx,%eax
f01026df:	2b 05 a8 89 11 f0    	sub    0xf01189a8,%eax
f01026e5:	c1 f8 03             	sar    $0x3,%eax
f01026e8:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01026eb:	89 c1                	mov    %eax,%ecx
f01026ed:	c1 e9 0c             	shr    $0xc,%ecx
f01026f0:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f01026f3:	77 20                	ja     f0102715 <mem_init+0x1251>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01026f5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01026f9:	c7 44 24 08 5c 48 10 	movl   $0xf010485c,0x8(%esp)
f0102700:	f0 
f0102701:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102708:	00 
f0102709:	c7 04 24 50 4f 10 f0 	movl   $0xf0104f50,(%esp)
f0102710:	e8 7f d9 ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102715:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010271c:	00 
f010271d:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f0102724:	00 
	return (void *)(pa + KERNBASE);
f0102725:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010272a:	89 04 24             	mov    %eax,(%esp)
f010272d:	e8 94 14 00 00       	call   f0103bc6 <memset>
	page_free(pp0);
f0102732:	89 1c 24             	mov    %ebx,(%esp)
f0102735:	e8 83 ea ff ff       	call   f01011bd <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010273a:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102741:	00 
f0102742:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102749:	00 
f010274a:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f010274f:	89 04 24             	mov    %eax,(%esp)
f0102752:	e8 9e ea ff ff       	call   f01011f5 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102757:	89 da                	mov    %ebx,%edx
f0102759:	2b 15 a8 89 11 f0    	sub    0xf01189a8,%edx
f010275f:	c1 fa 03             	sar    $0x3,%edx
f0102762:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102765:	89 d0                	mov    %edx,%eax
f0102767:	c1 e8 0c             	shr    $0xc,%eax
f010276a:	3b 05 a0 89 11 f0    	cmp    0xf01189a0,%eax
f0102770:	72 20                	jb     f0102792 <mem_init+0x12ce>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102772:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102776:	c7 44 24 08 5c 48 10 	movl   $0xf010485c,0x8(%esp)
f010277d:	f0 
f010277e:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102785:	00 
f0102786:	c7 04 24 50 4f 10 f0 	movl   $0xf0104f50,(%esp)
f010278d:	e8 02 d9 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0102792:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102798:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010279b:	f6 82 00 00 00 f0 01 	testb  $0x1,-0x10000000(%edx)
f01027a2:	75 11                	jne    f01027b5 <mem_init+0x12f1>
f01027a4:	8d 82 04 00 00 f0    	lea    -0xffffffc(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01027aa:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01027b0:	f6 00 01             	testb  $0x1,(%eax)
f01027b3:	74 24                	je     f01027d9 <mem_init+0x1315>
f01027b5:	c7 44 24 0c a6 51 10 	movl   $0xf01051a6,0xc(%esp)
f01027bc:	f0 
f01027bd:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f01027c4:	f0 
f01027c5:	c7 44 24 04 77 03 00 	movl   $0x377,0x4(%esp)
f01027cc:	00 
f01027cd:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f01027d4:	e8 bb d8 ff ff       	call   f0100094 <_panic>
f01027d9:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01027dc:	39 d0                	cmp    %edx,%eax
f01027de:	75 d0                	jne    f01027b0 <mem_init+0x12ec>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01027e0:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f01027e5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01027eb:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// give free list back
	page_free_list = fl;
f01027f1:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f01027f4:	89 0d 80 85 11 f0    	mov    %ecx,0xf0118580

	// free the pages we took
	page_free(pp0);
f01027fa:	89 1c 24             	mov    %ebx,(%esp)
f01027fd:	e8 bb e9 ff ff       	call   f01011bd <page_free>
	page_free(pp1);
f0102802:	89 3c 24             	mov    %edi,(%esp)
f0102805:	e8 b3 e9 ff ff       	call   f01011bd <page_free>
	page_free(pp2);
f010280a:	89 34 24             	mov    %esi,(%esp)
f010280d:	e8 ab e9 ff ff       	call   f01011bd <page_free>

	cprintf("check_page() succeeded!\n");
f0102812:	c7 04 24 bd 51 10 f0 	movl   $0xf01051bd,(%esp)
f0102819:	e8 a8 07 00 00       	call   f0102fc6 <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:

	boot_map_region(kern_pgdir,UPAGES,npages * sizeof (struct Page),PADDR (pages), PTE_U| PTE_P);
f010281e:	a1 a8 89 11 f0       	mov    0xf01189a8,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102823:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102828:	77 20                	ja     f010284a <mem_init+0x1386>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010282a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010282e:	c7 44 24 08 44 49 10 	movl   $0xf0104944,0x8(%esp)
f0102835:	f0 
f0102836:	c7 44 24 04 ad 00 00 	movl   $0xad,0x4(%esp)
f010283d:	00 
f010283e:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0102845:	e8 4a d8 ff ff       	call   f0100094 <_panic>
f010284a:	8b 0d a0 89 11 f0    	mov    0xf01189a0,%ecx
f0102850:	c1 e1 03             	shl    $0x3,%ecx
f0102853:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f010285a:	00 
	return (physaddr_t)kva - KERNBASE;
f010285b:	05 00 00 00 10       	add    $0x10000000,%eax
f0102860:	89 04 24             	mov    %eax,(%esp)
f0102863:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102868:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f010286d:	e8 67 ea ff ff       	call   f01012d9 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102872:	b8 00 e0 10 f0       	mov    $0xf010e000,%eax
f0102877:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010287c:	77 20                	ja     f010289e <mem_init+0x13da>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010287e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102882:	c7 44 24 08 44 49 10 	movl   $0xf0104944,0x8(%esp)
f0102889:	f0 
f010288a:	c7 44 24 04 b9 00 00 	movl   $0xb9,0x4(%esp)
f0102891:	00 
f0102892:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0102899:	e8 f6 d7 ff ff       	call   f0100094 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region (kern_pgdir,KSTACKTOP - KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_W| PTE_P);
f010289e:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f01028a5:	00 
f01028a6:	c7 04 24 00 e0 10 00 	movl   $0x10e000,(%esp)
f01028ad:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01028b2:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f01028b7:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f01028bc:	e8 18 ea ff ff       	call   f01012d9 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region (kern_pgdir,KERNBASE,0xffffffff-KERNBASE+1, 0,PTE_W| PTE_P);
f01028c1:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f01028c8:	00 
f01028c9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01028d0:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01028d5:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01028da:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f01028df:	e8 f5 e9 ff ff       	call   f01012d9 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01028e4:	8b 1d a4 89 11 f0    	mov    0xf01189a4,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
f01028ea:	8b 15 a0 89 11 f0    	mov    0xf01189a0,%edx
f01028f0:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f01028f3:	8d 3c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%edi
	for (i = 0; i < n; i += PGSIZE)
f01028fa:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
f0102900:	74 79                	je     f010297b <mem_init+0x14b7>
f0102902:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102907:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010290d:	89 d8                	mov    %ebx,%eax
f010290f:	e8 42 e3 ff ff       	call   f0100c56 <check_va2pa>
f0102914:	8b 15 a8 89 11 f0    	mov    0xf01189a8,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010291a:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102920:	77 20                	ja     f0102942 <mem_init+0x147e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102922:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102926:	c7 44 24 08 44 49 10 	movl   $0xf0104944,0x8(%esp)
f010292d:	f0 
f010292e:	c7 44 24 04 c3 02 00 	movl   $0x2c3,0x4(%esp)
f0102935:	00 
f0102936:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f010293d:	e8 52 d7 ff ff       	call   f0100094 <_panic>
f0102942:	8d 94 32 00 00 00 10 	lea    0x10000000(%edx,%esi,1),%edx
f0102949:	39 d0                	cmp    %edx,%eax
f010294b:	74 24                	je     f0102971 <mem_init+0x14ad>
f010294d:	c7 44 24 0c b0 4d 10 	movl   $0xf0104db0,0xc(%esp)
f0102954:	f0 
f0102955:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f010295c:	f0 
f010295d:	c7 44 24 04 c3 02 00 	movl   $0x2c3,0x4(%esp)
f0102964:	00 
f0102965:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f010296c:	e8 23 d7 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102971:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102977:	39 f7                	cmp    %esi,%edi
f0102979:	77 8c                	ja     f0102907 <mem_init+0x1443>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010297b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010297e:	c1 e7 0c             	shl    $0xc,%edi
f0102981:	85 ff                	test   %edi,%edi
f0102983:	74 44                	je     f01029c9 <mem_init+0x1505>
f0102985:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010298a:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102990:	89 d8                	mov    %ebx,%eax
f0102992:	e8 bf e2 ff ff       	call   f0100c56 <check_va2pa>
f0102997:	39 c6                	cmp    %eax,%esi
f0102999:	74 24                	je     f01029bf <mem_init+0x14fb>
f010299b:	c7 44 24 0c e4 4d 10 	movl   $0xf0104de4,0xc(%esp)
f01029a2:	f0 
f01029a3:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f01029aa:	f0 
f01029ab:	c7 44 24 04 c8 02 00 	movl   $0x2c8,0x4(%esp)
f01029b2:	00 
f01029b3:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f01029ba:	e8 d5 d6 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01029bf:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01029c5:	39 fe                	cmp    %edi,%esi
f01029c7:	72 c1                	jb     f010298a <mem_init+0x14c6>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01029c9:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f01029ce:	89 d8                	mov    %ebx,%eax
f01029d0:	e8 81 e2 ff ff       	call   f0100c56 <check_va2pa>
f01029d5:	be 00 90 bf ef       	mov    $0xefbf9000,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01029da:	bf 00 e0 10 f0       	mov    $0xf010e000,%edi
f01029df:	81 c7 00 70 40 20    	add    $0x20407000,%edi
f01029e5:	8d 14 37             	lea    (%edi,%esi,1),%edx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01029e8:	39 c2                	cmp    %eax,%edx
f01029ea:	74 24                	je     f0102a10 <mem_init+0x154c>
f01029ec:	c7 44 24 0c 0c 4e 10 	movl   $0xf0104e0c,0xc(%esp)
f01029f3:	f0 
f01029f4:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f01029fb:	f0 
f01029fc:	c7 44 24 04 cc 02 00 	movl   $0x2cc,0x4(%esp)
f0102a03:	00 
f0102a04:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0102a0b:	e8 84 d6 ff ff       	call   f0100094 <_panic>
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102a10:	81 fe 00 00 c0 ef    	cmp    $0xefc00000,%esi
f0102a16:	0f 85 27 05 00 00    	jne    f0102f43 <mem_init+0x1a7f>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102a1c:	ba 00 00 80 ef       	mov    $0xef800000,%edx
f0102a21:	89 d8                	mov    %ebx,%eax
f0102a23:	e8 2e e2 ff ff       	call   f0100c56 <check_va2pa>
f0102a28:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102a2b:	74 24                	je     f0102a51 <mem_init+0x158d>
f0102a2d:	c7 44 24 0c 54 4e 10 	movl   $0xf0104e54,0xc(%esp)
f0102a34:	f0 
f0102a35:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0102a3c:	f0 
f0102a3d:	c7 44 24 04 cd 02 00 	movl   $0x2cd,0x4(%esp)
f0102a44:	00 
f0102a45:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0102a4c:	e8 43 d6 ff ff       	call   f0100094 <_panic>
f0102a51:	b8 00 00 00 00       	mov    $0x0,%eax

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102a56:	8d 90 44 fc ff ff    	lea    -0x3bc(%eax),%edx
f0102a5c:	83 fa 02             	cmp    $0x2,%edx
f0102a5f:	77 2e                	ja     f0102a8f <mem_init+0x15cb>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0102a61:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0102a65:	0f 85 aa 00 00 00    	jne    f0102b15 <mem_init+0x1651>
f0102a6b:	c7 44 24 0c d6 51 10 	movl   $0xf01051d6,0xc(%esp)
f0102a72:	f0 
f0102a73:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0102a7a:	f0 
f0102a7b:	c7 44 24 04 d5 02 00 	movl   $0x2d5,0x4(%esp)
f0102a82:	00 
f0102a83:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0102a8a:	e8 05 d6 ff ff       	call   f0100094 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102a8f:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102a94:	76 55                	jbe    f0102aeb <mem_init+0x1627>
				assert(pgdir[i] & PTE_P);
f0102a96:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0102a99:	f6 c2 01             	test   $0x1,%dl
f0102a9c:	75 24                	jne    f0102ac2 <mem_init+0x15fe>
f0102a9e:	c7 44 24 0c d6 51 10 	movl   $0xf01051d6,0xc(%esp)
f0102aa5:	f0 
f0102aa6:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0102aad:	f0 
f0102aae:	c7 44 24 04 d9 02 00 	movl   $0x2d9,0x4(%esp)
f0102ab5:	00 
f0102ab6:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0102abd:	e8 d2 d5 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f0102ac2:	f6 c2 02             	test   $0x2,%dl
f0102ac5:	75 4e                	jne    f0102b15 <mem_init+0x1651>
f0102ac7:	c7 44 24 0c e7 51 10 	movl   $0xf01051e7,0xc(%esp)
f0102ace:	f0 
f0102acf:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0102ad6:	f0 
f0102ad7:	c7 44 24 04 da 02 00 	movl   $0x2da,0x4(%esp)
f0102ade:	00 
f0102adf:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0102ae6:	e8 a9 d5 ff ff       	call   f0100094 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102aeb:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0102aef:	74 24                	je     f0102b15 <mem_init+0x1651>
f0102af1:	c7 44 24 0c f8 51 10 	movl   $0xf01051f8,0xc(%esp)
f0102af8:	f0 
f0102af9:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0102b00:	f0 
f0102b01:	c7 44 24 04 dc 02 00 	movl   $0x2dc,0x4(%esp)
f0102b08:	00 
f0102b09:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0102b10:	e8 7f d5 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102b15:	83 c0 01             	add    $0x1,%eax
f0102b18:	3d 00 04 00 00       	cmp    $0x400,%eax
f0102b1d:	0f 85 33 ff ff ff    	jne    f0102a56 <mem_init+0x1592>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102b23:	c7 04 24 84 4e 10 f0 	movl   $0xf0104e84,(%esp)
f0102b2a:	e8 97 04 00 00       	call   f0102fc6 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102b2f:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102b34:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102b39:	77 20                	ja     f0102b5b <mem_init+0x1697>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102b3b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102b3f:	c7 44 24 08 44 49 10 	movl   $0xf0104944,0x8(%esp)
f0102b46:	f0 
f0102b47:	c7 44 24 04 cd 00 00 	movl   $0xcd,0x4(%esp)
f0102b4e:	00 
f0102b4f:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0102b56:	e8 39 d5 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102b5b:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102b60:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102b63:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b68:	e8 8c e1 ff ff       	call   f0100cf9 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102b6d:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
f0102b70:	0d 23 00 05 80       	or     $0x80050023,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102b75:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102b78:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102b7b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102b82:	e8 a9 e5 ff ff       	call   f0101130 <page_alloc>
f0102b87:	89 c6                	mov    %eax,%esi
f0102b89:	85 c0                	test   %eax,%eax
f0102b8b:	75 24                	jne    f0102bb1 <mem_init+0x16ed>
f0102b8d:	c7 44 24 0c 15 50 10 	movl   $0xf0105015,0xc(%esp)
f0102b94:	f0 
f0102b95:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0102b9c:	f0 
f0102b9d:	c7 44 24 04 92 03 00 	movl   $0x392,0x4(%esp)
f0102ba4:	00 
f0102ba5:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0102bac:	e8 e3 d4 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0102bb1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102bb8:	e8 73 e5 ff ff       	call   f0101130 <page_alloc>
f0102bbd:	89 c7                	mov    %eax,%edi
f0102bbf:	85 c0                	test   %eax,%eax
f0102bc1:	75 24                	jne    f0102be7 <mem_init+0x1723>
f0102bc3:	c7 44 24 0c 2b 50 10 	movl   $0xf010502b,0xc(%esp)
f0102bca:	f0 
f0102bcb:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0102bd2:	f0 
f0102bd3:	c7 44 24 04 93 03 00 	movl   $0x393,0x4(%esp)
f0102bda:	00 
f0102bdb:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0102be2:	e8 ad d4 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0102be7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102bee:	e8 3d e5 ff ff       	call   f0101130 <page_alloc>
f0102bf3:	89 c3                	mov    %eax,%ebx
f0102bf5:	85 c0                	test   %eax,%eax
f0102bf7:	75 24                	jne    f0102c1d <mem_init+0x1759>
f0102bf9:	c7 44 24 0c 41 50 10 	movl   $0xf0105041,0xc(%esp)
f0102c00:	f0 
f0102c01:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0102c08:	f0 
f0102c09:	c7 44 24 04 94 03 00 	movl   $0x394,0x4(%esp)
f0102c10:	00 
f0102c11:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0102c18:	e8 77 d4 ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f0102c1d:	89 34 24             	mov    %esi,(%esp)
f0102c20:	e8 98 e5 ff ff       	call   f01011bd <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102c25:	89 f8                	mov    %edi,%eax
f0102c27:	2b 05 a8 89 11 f0    	sub    0xf01189a8,%eax
f0102c2d:	c1 f8 03             	sar    $0x3,%eax
f0102c30:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c33:	89 c2                	mov    %eax,%edx
f0102c35:	c1 ea 0c             	shr    $0xc,%edx
f0102c38:	3b 15 a0 89 11 f0    	cmp    0xf01189a0,%edx
f0102c3e:	72 20                	jb     f0102c60 <mem_init+0x179c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c40:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102c44:	c7 44 24 08 5c 48 10 	movl   $0xf010485c,0x8(%esp)
f0102c4b:	f0 
f0102c4c:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102c53:	00 
f0102c54:	c7 04 24 50 4f 10 f0 	movl   $0xf0104f50,(%esp)
f0102c5b:	e8 34 d4 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102c60:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102c67:	00 
f0102c68:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102c6f:	00 
	return (void *)(pa + KERNBASE);
f0102c70:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102c75:	89 04 24             	mov    %eax,(%esp)
f0102c78:	e8 49 0f 00 00       	call   f0103bc6 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102c7d:	89 d8                	mov    %ebx,%eax
f0102c7f:	2b 05 a8 89 11 f0    	sub    0xf01189a8,%eax
f0102c85:	c1 f8 03             	sar    $0x3,%eax
f0102c88:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c8b:	89 c2                	mov    %eax,%edx
f0102c8d:	c1 ea 0c             	shr    $0xc,%edx
f0102c90:	3b 15 a0 89 11 f0    	cmp    0xf01189a0,%edx
f0102c96:	72 20                	jb     f0102cb8 <mem_init+0x17f4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c98:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102c9c:	c7 44 24 08 5c 48 10 	movl   $0xf010485c,0x8(%esp)
f0102ca3:	f0 
f0102ca4:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102cab:	00 
f0102cac:	c7 04 24 50 4f 10 f0 	movl   $0xf0104f50,(%esp)
f0102cb3:	e8 dc d3 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102cb8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102cbf:	00 
f0102cc0:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102cc7:	00 
	return (void *)(pa + KERNBASE);
f0102cc8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102ccd:	89 04 24             	mov    %eax,(%esp)
f0102cd0:	e8 f1 0e 00 00       	call   f0103bc6 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102cd5:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102cdc:	00 
f0102cdd:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102ce4:	00 
f0102ce5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102ce9:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0102cee:	89 04 24             	mov    %eax,(%esp)
f0102cf1:	e8 24 e7 ff ff       	call   f010141a <page_insert>
	assert(pp1->pp_ref == 1);
f0102cf6:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102cfb:	74 24                	je     f0102d21 <mem_init+0x185d>
f0102cfd:	c7 44 24 0c 12 51 10 	movl   $0xf0105112,0xc(%esp)
f0102d04:	f0 
f0102d05:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0102d0c:	f0 
f0102d0d:	c7 44 24 04 99 03 00 	movl   $0x399,0x4(%esp)
f0102d14:	00 
f0102d15:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0102d1c:	e8 73 d3 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102d21:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102d28:	01 01 01 
f0102d2b:	74 24                	je     f0102d51 <mem_init+0x188d>
f0102d2d:	c7 44 24 0c a4 4e 10 	movl   $0xf0104ea4,0xc(%esp)
f0102d34:	f0 
f0102d35:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0102d3c:	f0 
f0102d3d:	c7 44 24 04 9a 03 00 	movl   $0x39a,0x4(%esp)
f0102d44:	00 
f0102d45:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0102d4c:	e8 43 d3 ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102d51:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102d58:	00 
f0102d59:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102d60:	00 
f0102d61:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102d65:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0102d6a:	89 04 24             	mov    %eax,(%esp)
f0102d6d:	e8 a8 e6 ff ff       	call   f010141a <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102d72:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102d79:	02 02 02 
f0102d7c:	74 24                	je     f0102da2 <mem_init+0x18de>
f0102d7e:	c7 44 24 0c c8 4e 10 	movl   $0xf0104ec8,0xc(%esp)
f0102d85:	f0 
f0102d86:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0102d8d:	f0 
f0102d8e:	c7 44 24 04 9c 03 00 	movl   $0x39c,0x4(%esp)
f0102d95:	00 
f0102d96:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0102d9d:	e8 f2 d2 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102da2:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102da7:	74 24                	je     f0102dcd <mem_init+0x1909>
f0102da9:	c7 44 24 0c 34 51 10 	movl   $0xf0105134,0xc(%esp)
f0102db0:	f0 
f0102db1:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0102db8:	f0 
f0102db9:	c7 44 24 04 9d 03 00 	movl   $0x39d,0x4(%esp)
f0102dc0:	00 
f0102dc1:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0102dc8:	e8 c7 d2 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102dcd:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102dd2:	74 24                	je     f0102df8 <mem_init+0x1934>
f0102dd4:	c7 44 24 0c 7d 51 10 	movl   $0xf010517d,0xc(%esp)
f0102ddb:	f0 
f0102ddc:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0102de3:	f0 
f0102de4:	c7 44 24 04 9e 03 00 	movl   $0x39e,0x4(%esp)
f0102deb:	00 
f0102dec:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0102df3:	e8 9c d2 ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102df8:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102dff:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102e02:	89 d8                	mov    %ebx,%eax
f0102e04:	2b 05 a8 89 11 f0    	sub    0xf01189a8,%eax
f0102e0a:	c1 f8 03             	sar    $0x3,%eax
f0102e0d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102e10:	89 c2                	mov    %eax,%edx
f0102e12:	c1 ea 0c             	shr    $0xc,%edx
f0102e15:	3b 15 a0 89 11 f0    	cmp    0xf01189a0,%edx
f0102e1b:	72 20                	jb     f0102e3d <mem_init+0x1979>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102e1d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102e21:	c7 44 24 08 5c 48 10 	movl   $0xf010485c,0x8(%esp)
f0102e28:	f0 
f0102e29:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102e30:	00 
f0102e31:	c7 04 24 50 4f 10 f0 	movl   $0xf0104f50,(%esp)
f0102e38:	e8 57 d2 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102e3d:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102e44:	03 03 03 
f0102e47:	74 24                	je     f0102e6d <mem_init+0x19a9>
f0102e49:	c7 44 24 0c ec 4e 10 	movl   $0xf0104eec,0xc(%esp)
f0102e50:	f0 
f0102e51:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0102e58:	f0 
f0102e59:	c7 44 24 04 a0 03 00 	movl   $0x3a0,0x4(%esp)
f0102e60:	00 
f0102e61:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0102e68:	e8 27 d2 ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102e6d:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102e74:	00 
f0102e75:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0102e7a:	89 04 24             	mov    %eax,(%esp)
f0102e7d:	e8 44 e5 ff ff       	call   f01013c6 <page_remove>
	assert(pp2->pp_ref == 0);
f0102e82:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102e87:	74 24                	je     f0102ead <mem_init+0x19e9>
f0102e89:	c7 44 24 0c 6c 51 10 	movl   $0xf010516c,0xc(%esp)
f0102e90:	f0 
f0102e91:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0102e98:	f0 
f0102e99:	c7 44 24 04 a2 03 00 	movl   $0x3a2,0x4(%esp)
f0102ea0:	00 
f0102ea1:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0102ea8:	e8 e7 d1 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102ead:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0102eb2:	8b 08                	mov    (%eax),%ecx
f0102eb4:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102eba:	89 f2                	mov    %esi,%edx
f0102ebc:	2b 15 a8 89 11 f0    	sub    0xf01189a8,%edx
f0102ec2:	c1 fa 03             	sar    $0x3,%edx
f0102ec5:	c1 e2 0c             	shl    $0xc,%edx
f0102ec8:	39 d1                	cmp    %edx,%ecx
f0102eca:	74 24                	je     f0102ef0 <mem_init+0x1a2c>
f0102ecc:	c7 44 24 0c 9c 4a 10 	movl   $0xf0104a9c,0xc(%esp)
f0102ed3:	f0 
f0102ed4:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0102edb:	f0 
f0102edc:	c7 44 24 04 a5 03 00 	movl   $0x3a5,0x4(%esp)
f0102ee3:	00 
f0102ee4:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0102eeb:	e8 a4 d1 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102ef0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102ef6:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102efb:	74 24                	je     f0102f21 <mem_init+0x1a5d>
f0102efd:	c7 44 24 0c 23 51 10 	movl   $0xf0105123,0xc(%esp)
f0102f04:	f0 
f0102f05:	c7 44 24 08 6a 4f 10 	movl   $0xf0104f6a,0x8(%esp)
f0102f0c:	f0 
f0102f0d:	c7 44 24 04 a7 03 00 	movl   $0x3a7,0x4(%esp)
f0102f14:	00 
f0102f15:	c7 04 24 44 4f 10 f0 	movl   $0xf0104f44,(%esp)
f0102f1c:	e8 73 d1 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102f21:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102f27:	89 34 24             	mov    %esi,(%esp)
f0102f2a:	e8 8e e2 ff ff       	call   f01011bd <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102f2f:	c7 04 24 18 4f 10 f0 	movl   $0xf0104f18,(%esp)
f0102f36:	e8 8b 00 00 00       	call   f0102fc6 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102f3b:	83 c4 3c             	add    $0x3c,%esp
f0102f3e:	5b                   	pop    %ebx
f0102f3f:	5e                   	pop    %esi
f0102f40:	5f                   	pop    %edi
f0102f41:	5d                   	pop    %ebp
f0102f42:	c3                   	ret    
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102f43:	89 f2                	mov    %esi,%edx
f0102f45:	89 d8                	mov    %ebx,%eax
f0102f47:	e8 0a dd ff ff       	call   f0100c56 <check_va2pa>
f0102f4c:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102f52:	e9 8e fa ff ff       	jmp    f01029e5 <mem_init+0x1521>
	...

f0102f58 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102f58:	55                   	push   %ebp
f0102f59:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102f5b:	ba 70 00 00 00       	mov    $0x70,%edx
f0102f60:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f63:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102f64:	b2 71                	mov    $0x71,%dl
f0102f66:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102f67:	0f b6 c0             	movzbl %al,%eax
}
f0102f6a:	5d                   	pop    %ebp
f0102f6b:	c3                   	ret    

f0102f6c <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102f6c:	55                   	push   %ebp
f0102f6d:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102f6f:	ba 70 00 00 00       	mov    $0x70,%edx
f0102f74:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f77:	ee                   	out    %al,(%dx)
f0102f78:	b2 71                	mov    $0x71,%dl
f0102f7a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f7d:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102f7e:	5d                   	pop    %ebp
f0102f7f:	c3                   	ret    

f0102f80 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102f80:	55                   	push   %ebp
f0102f81:	89 e5                	mov    %esp,%ebp
f0102f83:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0102f86:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f89:	89 04 24             	mov    %eax,(%esp)
f0102f8c:	e8 60 d6 ff ff       	call   f01005f1 <cputchar>
	*cnt++;
}
f0102f91:	c9                   	leave  
f0102f92:	c3                   	ret    

f0102f93 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102f93:	55                   	push   %ebp
f0102f94:	89 e5                	mov    %esp,%ebp
f0102f96:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0102f99:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102fa0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102fa3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102fa7:	8b 45 08             	mov    0x8(%ebp),%eax
f0102faa:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102fae:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102fb1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102fb5:	c7 04 24 80 2f 10 f0 	movl   $0xf0102f80,(%esp)
f0102fbc:	e8 69 04 00 00       	call   f010342a <vprintfmt>
	return cnt;
}
f0102fc1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102fc4:	c9                   	leave  
f0102fc5:	c3                   	ret    

f0102fc6 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102fc6:	55                   	push   %ebp
f0102fc7:	89 e5                	mov    %esp,%ebp
f0102fc9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102fcc:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102fcf:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102fd3:	8b 45 08             	mov    0x8(%ebp),%eax
f0102fd6:	89 04 24             	mov    %eax,(%esp)
f0102fd9:	e8 b5 ff ff ff       	call   f0102f93 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102fde:	c9                   	leave  
f0102fdf:	c3                   	ret    

f0102fe0 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102fe0:	55                   	push   %ebp
f0102fe1:	89 e5                	mov    %esp,%ebp
f0102fe3:	57                   	push   %edi
f0102fe4:	56                   	push   %esi
f0102fe5:	53                   	push   %ebx
f0102fe6:	83 ec 10             	sub    $0x10,%esp
f0102fe9:	89 c3                	mov    %eax,%ebx
f0102feb:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0102fee:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0102ff1:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102ff4:	8b 0a                	mov    (%edx),%ecx
f0102ff6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102ff9:	8b 00                	mov    (%eax),%eax
f0102ffb:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102ffe:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f0103005:	eb 77                	jmp    f010307e <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f0103007:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010300a:	01 c8                	add    %ecx,%eax
f010300c:	bf 02 00 00 00       	mov    $0x2,%edi
f0103011:	99                   	cltd   
f0103012:	f7 ff                	idiv   %edi
f0103014:	89 c2                	mov    %eax,%edx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103016:	eb 01                	jmp    f0103019 <stab_binsearch+0x39>
			m--;
f0103018:	4a                   	dec    %edx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103019:	39 ca                	cmp    %ecx,%edx
f010301b:	7c 1d                	jl     f010303a <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f010301d:	6b fa 0c             	imul   $0xc,%edx,%edi
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103020:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f0103025:	39 f7                	cmp    %esi,%edi
f0103027:	75 ef                	jne    f0103018 <stab_binsearch+0x38>
f0103029:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010302c:	6b fa 0c             	imul   $0xc,%edx,%edi
f010302f:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f0103033:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0103036:	73 18                	jae    f0103050 <stab_binsearch+0x70>
f0103038:	eb 05                	jmp    f010303f <stab_binsearch+0x5f>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010303a:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f010303d:	eb 3f                	jmp    f010307e <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f010303f:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0103042:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0103044:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103047:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f010304e:	eb 2e                	jmp    f010307e <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0103050:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0103053:	76 15                	jbe    f010306a <stab_binsearch+0x8a>
			*region_right = m - 1;
f0103055:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0103058:	4f                   	dec    %edi
f0103059:	89 7d f0             	mov    %edi,-0x10(%ebp)
f010305c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010305f:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103061:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0103068:	eb 14                	jmp    f010307e <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010306a:	8b 7d ec             	mov    -0x14(%ebp),%edi
f010306d:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0103070:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f0103072:	ff 45 0c             	incl   0xc(%ebp)
f0103075:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103077:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f010307e:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0103081:	7e 84                	jle    f0103007 <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0103083:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0103087:	75 0d                	jne    f0103096 <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0103089:	8b 55 e8             	mov    -0x18(%ebp),%edx
f010308c:	8b 02                	mov    (%edx),%eax
f010308e:	48                   	dec    %eax
f010308f:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0103092:	89 01                	mov    %eax,(%ecx)
f0103094:	eb 22                	jmp    f01030b8 <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103096:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0103099:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f010309b:	8b 55 e8             	mov    -0x18(%ebp),%edx
f010309e:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01030a0:	eb 01                	jmp    f01030a3 <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01030a2:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01030a3:	39 c1                	cmp    %eax,%ecx
f01030a5:	7d 0c                	jge    f01030b3 <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f01030a7:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f01030aa:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f01030af:	39 f2                	cmp    %esi,%edx
f01030b1:	75 ef                	jne    f01030a2 <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f01030b3:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01030b6:	89 02                	mov    %eax,(%edx)
	}
}
f01030b8:	83 c4 10             	add    $0x10,%esp
f01030bb:	5b                   	pop    %ebx
f01030bc:	5e                   	pop    %esi
f01030bd:	5f                   	pop    %edi
f01030be:	5d                   	pop    %ebp
f01030bf:	c3                   	ret    

f01030c0 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01030c0:	55                   	push   %ebp
f01030c1:	89 e5                	mov    %esp,%ebp
f01030c3:	83 ec 38             	sub    $0x38,%esp
f01030c6:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f01030c9:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01030cc:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01030cf:	8b 75 08             	mov    0x8(%ebp),%esi
f01030d2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01030d5:	c7 03 1b 44 10 f0    	movl   $0xf010441b,(%ebx)
	info->eip_line = 0;
f01030db:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01030e2:	c7 43 08 1b 44 10 f0 	movl   $0xf010441b,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01030e9:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01030f0:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01030f3:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01030fa:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0103100:	76 12                	jbe    f0103114 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103102:	b8 ee d8 10 f0       	mov    $0xf010d8ee,%eax
f0103107:	3d 3d ba 10 f0       	cmp    $0xf010ba3d,%eax
f010310c:	0f 86 9b 01 00 00    	jbe    f01032ad <debuginfo_eip+0x1ed>
f0103112:	eb 1c                	jmp    f0103130 <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0103114:	c7 44 24 08 06 52 10 	movl   $0xf0105206,0x8(%esp)
f010311b:	f0 
f010311c:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0103123:	00 
f0103124:	c7 04 24 13 52 10 f0 	movl   $0xf0105213,(%esp)
f010312b:	e8 64 cf ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103130:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103135:	80 3d ed d8 10 f0 00 	cmpb   $0x0,0xf010d8ed
f010313c:	0f 85 77 01 00 00    	jne    f01032b9 <debuginfo_eip+0x1f9>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103142:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103149:	b8 3c ba 10 f0       	mov    $0xf010ba3c,%eax
f010314e:	2d 30 54 10 f0       	sub    $0xf0105430,%eax
f0103153:	c1 f8 02             	sar    $0x2,%eax
f0103156:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f010315c:	83 e8 01             	sub    $0x1,%eax
f010315f:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103162:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103166:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f010316d:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0103170:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103173:	b8 30 54 10 f0       	mov    $0xf0105430,%eax
f0103178:	e8 63 fe ff ff       	call   f0102fe0 <stab_binsearch>
	if (lfile == 0)
f010317d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0103180:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0103185:	85 d2                	test   %edx,%edx
f0103187:	0f 84 2c 01 00 00    	je     f01032b9 <debuginfo_eip+0x1f9>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010318d:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0103190:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103193:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103196:	89 74 24 04          	mov    %esi,0x4(%esp)
f010319a:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f01031a1:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01031a4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01031a7:	b8 30 54 10 f0       	mov    $0xf0105430,%eax
f01031ac:	e8 2f fe ff ff       	call   f0102fe0 <stab_binsearch>

	if (lfun <= rfun) {
f01031b1:	8b 7d dc             	mov    -0x24(%ebp),%edi
f01031b4:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f01031b7:	7f 2e                	jg     f01031e7 <debuginfo_eip+0x127>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01031b9:	6b c7 0c             	imul   $0xc,%edi,%eax
f01031bc:	8d 90 30 54 10 f0    	lea    -0xfefabd0(%eax),%edx
f01031c2:	8b 80 30 54 10 f0    	mov    -0xfefabd0(%eax),%eax
f01031c8:	b9 ee d8 10 f0       	mov    $0xf010d8ee,%ecx
f01031cd:	81 e9 3d ba 10 f0    	sub    $0xf010ba3d,%ecx
f01031d3:	39 c8                	cmp    %ecx,%eax
f01031d5:	73 08                	jae    f01031df <debuginfo_eip+0x11f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01031d7:	05 3d ba 10 f0       	add    $0xf010ba3d,%eax
f01031dc:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f01031df:	8b 42 08             	mov    0x8(%edx),%eax
f01031e2:	89 43 10             	mov    %eax,0x10(%ebx)
f01031e5:	eb 06                	jmp    f01031ed <debuginfo_eip+0x12d>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01031e7:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f01031ea:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01031ed:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f01031f4:	00 
f01031f5:	8b 43 08             	mov    0x8(%ebx),%eax
f01031f8:	89 04 24             	mov    %eax,(%esp)
f01031fb:	e8 9f 09 00 00       	call   f0103b9f <strfind>
f0103200:	2b 43 08             	sub    0x8(%ebx),%eax
f0103203:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103206:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103209:	39 d7                	cmp    %edx,%edi
f010320b:	7c 5f                	jl     f010326c <debuginfo_eip+0x1ac>
	       && stabs[lline].n_type != N_SOL
f010320d:	89 f8                	mov    %edi,%eax
f010320f:	6b cf 0c             	imul   $0xc,%edi,%ecx
f0103212:	80 b9 34 54 10 f0 84 	cmpb   $0x84,-0xfefabcc(%ecx)
f0103219:	75 18                	jne    f0103233 <debuginfo_eip+0x173>
f010321b:	eb 30                	jmp    f010324d <debuginfo_eip+0x18d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f010321d:	83 ef 01             	sub    $0x1,%edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103220:	39 fa                	cmp    %edi,%edx
f0103222:	7f 48                	jg     f010326c <debuginfo_eip+0x1ac>
	       && stabs[lline].n_type != N_SOL
f0103224:	89 f8                	mov    %edi,%eax
f0103226:	8d 0c 7f             	lea    (%edi,%edi,2),%ecx
f0103229:	80 3c 8d 34 54 10 f0 	cmpb   $0x84,-0xfefabcc(,%ecx,4)
f0103230:	84 
f0103231:	74 1a                	je     f010324d <debuginfo_eip+0x18d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103233:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103236:	8d 04 85 30 54 10 f0 	lea    -0xfefabd0(,%eax,4),%eax
f010323d:	80 78 04 64          	cmpb   $0x64,0x4(%eax)
f0103241:	75 da                	jne    f010321d <debuginfo_eip+0x15d>
f0103243:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0103247:	74 d4                	je     f010321d <debuginfo_eip+0x15d>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103249:	39 fa                	cmp    %edi,%edx
f010324b:	7f 1f                	jg     f010326c <debuginfo_eip+0x1ac>
f010324d:	6b ff 0c             	imul   $0xc,%edi,%edi
f0103250:	8b 87 30 54 10 f0    	mov    -0xfefabd0(%edi),%eax
f0103256:	ba ee d8 10 f0       	mov    $0xf010d8ee,%edx
f010325b:	81 ea 3d ba 10 f0    	sub    $0xf010ba3d,%edx
f0103261:	39 d0                	cmp    %edx,%eax
f0103263:	73 07                	jae    f010326c <debuginfo_eip+0x1ac>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103265:	05 3d ba 10 f0       	add    $0xf010ba3d,%eax
f010326a:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010326c:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010326f:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0103272:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103277:	39 ca                	cmp    %ecx,%edx
f0103279:	7d 3e                	jge    f01032b9 <debuginfo_eip+0x1f9>
		for (lline = lfun + 1;
f010327b:	83 c2 01             	add    $0x1,%edx
f010327e:	39 d1                	cmp    %edx,%ecx
f0103280:	7e 37                	jle    f01032b9 <debuginfo_eip+0x1f9>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103282:	6b f2 0c             	imul   $0xc,%edx,%esi
f0103285:	80 be 34 54 10 f0 a0 	cmpb   $0xa0,-0xfefabcc(%esi)
f010328c:	75 2b                	jne    f01032b9 <debuginfo_eip+0x1f9>
		     lline++)
			info->eip_fn_narg++;
f010328e:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0103292:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103295:	39 d1                	cmp    %edx,%ecx
f0103297:	7e 1b                	jle    f01032b4 <debuginfo_eip+0x1f4>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103299:	8d 04 52             	lea    (%edx,%edx,2),%eax
f010329c:	80 3c 85 34 54 10 f0 	cmpb   $0xa0,-0xfefabcc(,%eax,4)
f01032a3:	a0 
f01032a4:	74 e8                	je     f010328e <debuginfo_eip+0x1ce>
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f01032a6:	b8 00 00 00 00       	mov    $0x0,%eax
f01032ab:	eb 0c                	jmp    f01032b9 <debuginfo_eip+0x1f9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01032ad:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01032b2:	eb 05                	jmp    f01032b9 <debuginfo_eip+0x1f9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f01032b4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01032b9:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01032bc:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01032bf:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01032c2:	89 ec                	mov    %ebp,%esp
f01032c4:	5d                   	pop    %ebp
f01032c5:	c3                   	ret    
	...

f01032d0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01032d0:	55                   	push   %ebp
f01032d1:	89 e5                	mov    %esp,%ebp
f01032d3:	57                   	push   %edi
f01032d4:	56                   	push   %esi
f01032d5:	53                   	push   %ebx
f01032d6:	83 ec 3c             	sub    $0x3c,%esp
f01032d9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01032dc:	89 d7                	mov    %edx,%edi
f01032de:	8b 45 08             	mov    0x8(%ebp),%eax
f01032e1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01032e4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01032e7:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01032ea:	8b 5d 14             	mov    0x14(%ebp),%ebx
f01032ed:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01032f0:	b8 00 00 00 00       	mov    $0x0,%eax
f01032f5:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f01032f8:	72 11                	jb     f010330b <printnum+0x3b>
f01032fa:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01032fd:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103300:	76 09                	jbe    f010330b <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103302:	83 eb 01             	sub    $0x1,%ebx
f0103305:	85 db                	test   %ebx,%ebx
f0103307:	7f 51                	jg     f010335a <printnum+0x8a>
f0103309:	eb 5e                	jmp    f0103369 <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010330b:	89 74 24 10          	mov    %esi,0x10(%esp)
f010330f:	83 eb 01             	sub    $0x1,%ebx
f0103312:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103316:	8b 45 10             	mov    0x10(%ebp),%eax
f0103319:	89 44 24 08          	mov    %eax,0x8(%esp)
f010331d:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0103321:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0103325:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010332c:	00 
f010332d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103330:	89 04 24             	mov    %eax,(%esp)
f0103333:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103336:	89 44 24 04          	mov    %eax,0x4(%esp)
f010333a:	e8 e1 0a 00 00       	call   f0103e20 <__udivdi3>
f010333f:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103343:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103347:	89 04 24             	mov    %eax,(%esp)
f010334a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010334e:	89 fa                	mov    %edi,%edx
f0103350:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103353:	e8 78 ff ff ff       	call   f01032d0 <printnum>
f0103358:	eb 0f                	jmp    f0103369 <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010335a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010335e:	89 34 24             	mov    %esi,(%esp)
f0103361:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103364:	83 eb 01             	sub    $0x1,%ebx
f0103367:	75 f1                	jne    f010335a <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103369:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010336d:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103371:	8b 45 10             	mov    0x10(%ebp),%eax
f0103374:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103378:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010337f:	00 
f0103380:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103383:	89 04 24             	mov    %eax,(%esp)
f0103386:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103389:	89 44 24 04          	mov    %eax,0x4(%esp)
f010338d:	e8 be 0b 00 00       	call   f0103f50 <__umoddi3>
f0103392:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103396:	0f be 80 21 52 10 f0 	movsbl -0xfefaddf(%eax),%eax
f010339d:	89 04 24             	mov    %eax,(%esp)
f01033a0:	ff 55 e4             	call   *-0x1c(%ebp)
}
f01033a3:	83 c4 3c             	add    $0x3c,%esp
f01033a6:	5b                   	pop    %ebx
f01033a7:	5e                   	pop    %esi
f01033a8:	5f                   	pop    %edi
f01033a9:	5d                   	pop    %ebp
f01033aa:	c3                   	ret    

f01033ab <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01033ab:	55                   	push   %ebp
f01033ac:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01033ae:	83 fa 01             	cmp    $0x1,%edx
f01033b1:	7e 0e                	jle    f01033c1 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01033b3:	8b 10                	mov    (%eax),%edx
f01033b5:	8d 4a 08             	lea    0x8(%edx),%ecx
f01033b8:	89 08                	mov    %ecx,(%eax)
f01033ba:	8b 02                	mov    (%edx),%eax
f01033bc:	8b 52 04             	mov    0x4(%edx),%edx
f01033bf:	eb 22                	jmp    f01033e3 <getuint+0x38>
	else if (lflag)
f01033c1:	85 d2                	test   %edx,%edx
f01033c3:	74 10                	je     f01033d5 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01033c5:	8b 10                	mov    (%eax),%edx
f01033c7:	8d 4a 04             	lea    0x4(%edx),%ecx
f01033ca:	89 08                	mov    %ecx,(%eax)
f01033cc:	8b 02                	mov    (%edx),%eax
f01033ce:	ba 00 00 00 00       	mov    $0x0,%edx
f01033d3:	eb 0e                	jmp    f01033e3 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01033d5:	8b 10                	mov    (%eax),%edx
f01033d7:	8d 4a 04             	lea    0x4(%edx),%ecx
f01033da:	89 08                	mov    %ecx,(%eax)
f01033dc:	8b 02                	mov    (%edx),%eax
f01033de:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01033e3:	5d                   	pop    %ebp
f01033e4:	c3                   	ret    

f01033e5 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01033e5:	55                   	push   %ebp
f01033e6:	89 e5                	mov    %esp,%ebp
f01033e8:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01033eb:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01033ef:	8b 10                	mov    (%eax),%edx
f01033f1:	3b 50 04             	cmp    0x4(%eax),%edx
f01033f4:	73 0a                	jae    f0103400 <sprintputch+0x1b>
		*b->buf++ = ch;
f01033f6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01033f9:	88 0a                	mov    %cl,(%edx)
f01033fb:	83 c2 01             	add    $0x1,%edx
f01033fe:	89 10                	mov    %edx,(%eax)
}
f0103400:	5d                   	pop    %ebp
f0103401:	c3                   	ret    

f0103402 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103402:	55                   	push   %ebp
f0103403:	89 e5                	mov    %esp,%ebp
f0103405:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0103408:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010340b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010340f:	8b 45 10             	mov    0x10(%ebp),%eax
f0103412:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103416:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103419:	89 44 24 04          	mov    %eax,0x4(%esp)
f010341d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103420:	89 04 24             	mov    %eax,(%esp)
f0103423:	e8 02 00 00 00       	call   f010342a <vprintfmt>
	va_end(ap);
}
f0103428:	c9                   	leave  
f0103429:	c3                   	ret    

f010342a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010342a:	55                   	push   %ebp
f010342b:	89 e5                	mov    %esp,%ebp
f010342d:	57                   	push   %edi
f010342e:	56                   	push   %esi
f010342f:	53                   	push   %ebx
f0103430:	83 ec 3c             	sub    $0x3c,%esp
f0103433:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0103436:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103439:	e9 bb 00 00 00       	jmp    f01034f9 <vprintfmt+0xcf>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010343e:	85 c0                	test   %eax,%eax
f0103440:	0f 84 63 04 00 00    	je     f01038a9 <vprintfmt+0x47f>
				return;
			if (ch =='\033'){//if this is Escape character  and this if is char color set.
f0103446:	83 f8 1b             	cmp    $0x1b,%eax
f0103449:	0f 85 9a 00 00 00    	jne    f01034e9 <vprintfmt+0xbf>
				int temp_color_no=0;
				ch = *(unsigned char *) fmt++;
f010344f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103452:	83 c3 02             	add    $0x2,%ebx
				while (ch != 'm') 
f0103455:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103458:	80 78 01 6d          	cmpb   $0x6d,0x1(%eax)
f010345c:	0f 84 81 00 00 00    	je     f01034e3 <vprintfmt+0xb9>
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
				return;
			if (ch =='\033'){//if this is Escape character  and this if is char color set.
				int temp_color_no=0;
f0103462:	ba 00 00 00 00       	mov    $0x0,%edx
				ch = *(unsigned char *) fmt++;
				while (ch != 'm') 
				{
					ch = *(unsigned char *) fmt++;
f0103467:	0f b6 03             	movzbl (%ebx),%eax
f010346a:	83 c3 01             	add    $0x1,%ebx
					if ( ch !=';' && ch!='m')
f010346d:	83 f8 6d             	cmp    $0x6d,%eax
f0103470:	0f 95 c1             	setne  %cl
f0103473:	83 f8 3b             	cmp    $0x3b,%eax
f0103476:	74 0d                	je     f0103485 <vprintfmt+0x5b>
f0103478:	84 c9                	test   %cl,%cl
f010347a:	74 09                	je     f0103485 <vprintfmt+0x5b>
						temp_color_no=temp_color_no*10+ch-'0';
f010347c:	8d 14 92             	lea    (%edx,%edx,4),%edx
f010347f:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
f0103483:	eb 55                	jmp    f01034da <vprintfmt+0xb0>
					else if ( ch==';' || ch=='m'){
f0103485:	83 f8 3b             	cmp    $0x3b,%eax
f0103488:	74 05                	je     f010348f <vprintfmt+0x65>
f010348a:	83 f8 6d             	cmp    $0x6d,%eax
f010348d:	75 4b                	jne    f01034da <vprintfmt+0xb0>
						if ( temp_color_no >=30 && temp_color_no<40){// Foreground colors
f010348f:	89 d6                	mov    %edx,%esi
f0103491:	8d 7a e2             	lea    -0x1e(%edx),%edi
f0103494:	83 ff 09             	cmp    $0x9,%edi
f0103497:	77 16                	ja     f01034af <vprintfmt+0x85>
							char_color = (char_color&0xf0) + (temp_color_no-30);						
f0103499:	8b 3d 00 83 11 f0    	mov    0xf0118300,%edi
f010349f:	81 e7 f0 00 00 00    	and    $0xf0,%edi
f01034a5:	8d 7c 3a e2          	lea    -0x1e(%edx,%edi,1),%edi
f01034a9:	89 3d 00 83 11 f0    	mov    %edi,0xf0118300
							}
						if ( temp_color_no >=40 && temp_color_no<50){// Background colors
f01034af:	83 ee 28             	sub    $0x28,%esi
f01034b2:	83 fe 09             	cmp    $0x9,%esi
f01034b5:	77 1e                	ja     f01034d5 <vprintfmt+0xab>
							char_color = (char_color&0x0f) + ((temp_color_no-40)<<4);
f01034b7:	8b 35 00 83 11 f0    	mov    0xf0118300,%esi
f01034bd:	83 e6 0f             	and    $0xf,%esi
f01034c0:	83 ea 28             	sub    $0x28,%edx
f01034c3:	c1 e2 04             	shl    $0x4,%edx
f01034c6:	01 f2                	add    %esi,%edx
f01034c8:	89 15 00 83 11 f0    	mov    %edx,0xf0118300
						}
						//cprintf("0x%o ,",char_color);
						temp_color_no=0;
f01034ce:	ba 00 00 00 00       	mov    $0x0,%edx
f01034d3:	eb 05                	jmp    f01034da <vprintfmt+0xb0>
f01034d5:	ba 00 00 00 00       	mov    $0x0,%edx
			if (ch == '\0')
				return;
			if (ch =='\033'){//if this is Escape character  and this if is char color set.
				int temp_color_no=0;
				ch = *(unsigned char *) fmt++;
				while (ch != 'm') 
f01034da:	84 c9                	test   %cl,%cl
f01034dc:	75 89                	jne    f0103467 <vprintfmt+0x3d>
						}
						//cprintf("0x%o ,",char_color);
						temp_color_no=0;
					}
				}
				if (ch == 'm')
f01034de:	83 f8 6d             	cmp    $0x6d,%eax
f01034e1:	75 06                	jne    f01034e9 <vprintfmt+0xbf>
					ch = *(unsigned char *) fmt++;
f01034e3:	0f b6 03             	movzbl (%ebx),%eax
f01034e6:	83 c3 01             	add    $0x1,%ebx
				
			}
			putch(ch, putdat);
f01034e9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01034ec:	89 54 24 04          	mov    %edx,0x4(%esp)
f01034f0:	89 04 24             	mov    %eax,(%esp)
f01034f3:	ff 55 08             	call   *0x8(%ebp)
f01034f6:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01034f9:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01034fc:	0f b6 03             	movzbl (%ebx),%eax
f01034ff:	83 c3 01             	add    $0x1,%ebx
f0103502:	83 f8 25             	cmp    $0x25,%eax
f0103505:	0f 85 33 ff ff ff    	jne    f010343e <vprintfmt+0x14>
f010350b:	c6 45 e0 20          	movb   $0x20,-0x20(%ebp)
f010350f:	bf 00 00 00 00       	mov    $0x0,%edi
f0103514:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0103519:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0103520:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103525:	eb 23                	jmp    f010354a <vprintfmt+0x120>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103527:	89 c3                	mov    %eax,%ebx

		// flag to pad on the right
		case '-':
			padc = '-';
f0103529:	c6 45 e0 2d          	movb   $0x2d,-0x20(%ebp)
f010352d:	eb 1b                	jmp    f010354a <vprintfmt+0x120>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010352f:	89 c3                	mov    %eax,%ebx
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103531:	c6 45 e0 30          	movb   $0x30,-0x20(%ebp)
f0103535:	eb 13                	jmp    f010354a <vprintfmt+0x120>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103537:	89 c3                	mov    %eax,%ebx
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0103539:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0103540:	eb 08                	jmp    f010354a <vprintfmt+0x120>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0103542:	89 75 dc             	mov    %esi,-0x24(%ebp)
f0103545:	be ff ff ff ff       	mov    $0xffffffff,%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010354a:	0f b6 13             	movzbl (%ebx),%edx
f010354d:	0f b6 c2             	movzbl %dl,%eax
f0103550:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103553:	8d 43 01             	lea    0x1(%ebx),%eax
f0103556:	83 ea 23             	sub    $0x23,%edx
f0103559:	80 fa 55             	cmp    $0x55,%dl
f010355c:	0f 87 18 03 00 00    	ja     f010387a <vprintfmt+0x450>
f0103562:	0f b6 d2             	movzbl %dl,%edx
f0103565:	ff 24 95 ac 52 10 f0 	jmp    *-0xfefad54(,%edx,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f010356c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010356f:	83 ee 30             	sub    $0x30,%esi
				ch = *fmt;
f0103572:	0f be 53 01          	movsbl 0x1(%ebx),%edx
				if (ch < '0' || ch > '9')
f0103576:	8d 5a d0             	lea    -0x30(%edx),%ebx
f0103579:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010357c:	89 c3                	mov    %eax,%ebx
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f010357e:	83 7d e4 09          	cmpl   $0x9,-0x1c(%ebp)
f0103582:	77 3b                	ja     f01035bf <vprintfmt+0x195>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103584:	83 c0 01             	add    $0x1,%eax
				precision = precision * 10 + ch - '0';
f0103587:	8d 1c b6             	lea    (%esi,%esi,4),%ebx
f010358a:	8d 74 5a d0          	lea    -0x30(%edx,%ebx,2),%esi
				ch = *fmt;
f010358e:	0f be 10             	movsbl (%eax),%edx
				if (ch < '0' || ch > '9')
f0103591:	8d 5a d0             	lea    -0x30(%edx),%ebx
f0103594:	83 fb 09             	cmp    $0x9,%ebx
f0103597:	76 eb                	jbe    f0103584 <vprintfmt+0x15a>
f0103599:	eb 22                	jmp    f01035bd <vprintfmt+0x193>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f010359b:	8b 55 14             	mov    0x14(%ebp),%edx
f010359e:	8d 5a 04             	lea    0x4(%edx),%ebx
f01035a1:	89 5d 14             	mov    %ebx,0x14(%ebp)
f01035a4:	8b 32                	mov    (%edx),%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01035a6:	89 c3                	mov    %eax,%ebx
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01035a8:	eb 15                	jmp    f01035bf <vprintfmt+0x195>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01035aa:	89 c3                	mov    %eax,%ebx
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f01035ac:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01035b0:	79 98                	jns    f010354a <vprintfmt+0x120>
f01035b2:	eb 83                	jmp    f0103537 <vprintfmt+0x10d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01035b4:	89 c3                	mov    %eax,%ebx
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01035b6:	bf 01 00 00 00       	mov    $0x1,%edi
			goto reswitch;
f01035bb:	eb 8d                	jmp    f010354a <vprintfmt+0x120>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01035bd:	89 c3                	mov    %eax,%ebx
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f01035bf:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01035c3:	79 85                	jns    f010354a <vprintfmt+0x120>
f01035c5:	e9 78 ff ff ff       	jmp    f0103542 <vprintfmt+0x118>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01035ca:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01035cd:	89 c3                	mov    %eax,%ebx
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f01035cf:	e9 76 ff ff ff       	jmp    f010354a <vprintfmt+0x120>
f01035d4:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01035d7:	8b 45 14             	mov    0x14(%ebp),%eax
f01035da:	8d 50 04             	lea    0x4(%eax),%edx
f01035dd:	89 55 14             	mov    %edx,0x14(%ebp)
f01035e0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01035e3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01035e7:	8b 00                	mov    (%eax),%eax
f01035e9:	89 04 24             	mov    %eax,(%esp)
f01035ec:	ff 55 08             	call   *0x8(%ebp)
			break;
f01035ef:	e9 05 ff ff ff       	jmp    f01034f9 <vprintfmt+0xcf>
f01035f4:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// error message
		case 'e':
			err = va_arg(ap, int);
f01035f7:	8b 45 14             	mov    0x14(%ebp),%eax
f01035fa:	8d 50 04             	lea    0x4(%eax),%edx
f01035fd:	89 55 14             	mov    %edx,0x14(%ebp)
f0103600:	8b 00                	mov    (%eax),%eax
f0103602:	89 c2                	mov    %eax,%edx
f0103604:	c1 fa 1f             	sar    $0x1f,%edx
f0103607:	31 d0                	xor    %edx,%eax
f0103609:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010360b:	83 f8 06             	cmp    $0x6,%eax
f010360e:	7f 0b                	jg     f010361b <vprintfmt+0x1f1>
f0103610:	8b 14 85 04 54 10 f0 	mov    -0xfefabfc(,%eax,4),%edx
f0103617:	85 d2                	test   %edx,%edx
f0103619:	75 23                	jne    f010363e <vprintfmt+0x214>
				printfmt(putch, putdat, "error %d", err);
f010361b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010361f:	c7 44 24 08 39 52 10 	movl   $0xf0105239,0x8(%esp)
f0103626:	f0 
f0103627:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010362a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010362e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103631:	89 1c 24             	mov    %ebx,(%esp)
f0103634:	e8 c9 fd ff ff       	call   f0103402 <printfmt>
f0103639:	e9 bb fe ff ff       	jmp    f01034f9 <vprintfmt+0xcf>
			else
				printfmt(putch, putdat, "%s", p);
f010363e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103642:	c7 44 24 08 7c 4f 10 	movl   $0xf0104f7c,0x8(%esp)
f0103649:	f0 
f010364a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010364d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103651:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103654:	89 1c 24             	mov    %ebx,(%esp)
f0103657:	e8 a6 fd ff ff       	call   f0103402 <printfmt>
f010365c:	e9 98 fe ff ff       	jmp    f01034f9 <vprintfmt+0xcf>
f0103661:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103664:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103667:	89 5d d8             	mov    %ebx,-0x28(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010366a:	8b 45 14             	mov    0x14(%ebp),%eax
f010366d:	8d 50 04             	lea    0x4(%eax),%edx
f0103670:	89 55 14             	mov    %edx,0x14(%ebp)
f0103673:	8b 18                	mov    (%eax),%ebx
				p = "(null)";
f0103675:	85 db                	test   %ebx,%ebx
f0103677:	b8 32 52 10 f0       	mov    $0xf0105232,%eax
f010367c:	0f 44 d8             	cmove  %eax,%ebx
			if (width > 0 && padc != '-')
f010367f:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103683:	7e 06                	jle    f010368b <vprintfmt+0x261>
f0103685:	80 7d e0 2d          	cmpb   $0x2d,-0x20(%ebp)
f0103689:	75 10                	jne    f010369b <vprintfmt+0x271>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010368b:	0f be 03             	movsbl (%ebx),%eax
f010368e:	83 c3 01             	add    $0x1,%ebx
f0103691:	85 c0                	test   %eax,%eax
f0103693:	0f 85 82 00 00 00    	jne    f010371b <vprintfmt+0x2f1>
f0103699:	eb 75                	jmp    f0103710 <vprintfmt+0x2e6>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010369b:	89 74 24 04          	mov    %esi,0x4(%esp)
f010369f:	89 1c 24             	mov    %ebx,(%esp)
f01036a2:	e8 84 03 00 00       	call   f0103a2b <strnlen>
f01036a7:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01036aa:	29 c2                	sub    %eax,%edx
f01036ac:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01036af:	85 d2                	test   %edx,%edx
f01036b1:	7e d8                	jle    f010368b <vprintfmt+0x261>
					putch(padc, putdat);
f01036b3:	0f be 45 e0          	movsbl -0x20(%ebp),%eax
f01036b7:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01036ba:	8b 55 0c             	mov    0xc(%ebp),%edx
f01036bd:	89 54 24 04          	mov    %edx,0x4(%esp)
f01036c1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01036c4:	89 04 24             	mov    %eax,(%esp)
f01036c7:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01036ca:	83 6d dc 01          	subl   $0x1,-0x24(%ebp)
f01036ce:	75 ea                	jne    f01036ba <vprintfmt+0x290>
f01036d0:	eb b9                	jmp    f010368b <vprintfmt+0x261>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01036d2:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01036d6:	74 1b                	je     f01036f3 <vprintfmt+0x2c9>
f01036d8:	8d 50 e0             	lea    -0x20(%eax),%edx
f01036db:	83 fa 5e             	cmp    $0x5e,%edx
f01036de:	76 13                	jbe    f01036f3 <vprintfmt+0x2c9>
					putch('?', putdat);
f01036e0:	8b 55 0c             	mov    0xc(%ebp),%edx
f01036e3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01036e7:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01036ee:	ff 55 08             	call   *0x8(%ebp)
f01036f1:	eb 0d                	jmp    f0103700 <vprintfmt+0x2d6>
				else
					putch(ch, putdat);
f01036f3:	8b 55 0c             	mov    0xc(%ebp),%edx
f01036f6:	89 54 24 04          	mov    %edx,0x4(%esp)
f01036fa:	89 04 24             	mov    %eax,(%esp)
f01036fd:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103700:	83 ef 01             	sub    $0x1,%edi
f0103703:	0f be 03             	movsbl (%ebx),%eax
f0103706:	83 c3 01             	add    $0x1,%ebx
f0103709:	85 c0                	test   %eax,%eax
f010370b:	75 14                	jne    f0103721 <vprintfmt+0x2f7>
f010370d:	89 7d dc             	mov    %edi,-0x24(%ebp)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103710:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103714:	7f 19                	jg     f010372f <vprintfmt+0x305>
f0103716:	e9 de fd ff ff       	jmp    f01034f9 <vprintfmt+0xcf>
f010371b:	89 7d e0             	mov    %edi,-0x20(%ebp)
f010371e:	8b 7d dc             	mov    -0x24(%ebp),%edi
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103721:	85 f6                	test   %esi,%esi
f0103723:	78 ad                	js     f01036d2 <vprintfmt+0x2a8>
f0103725:	83 ee 01             	sub    $0x1,%esi
f0103728:	79 a8                	jns    f01036d2 <vprintfmt+0x2a8>
f010372a:	89 7d dc             	mov    %edi,-0x24(%ebp)
f010372d:	eb e1                	jmp    f0103710 <vprintfmt+0x2e6>
f010372f:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103732:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103735:	8b 75 0c             	mov    0xc(%ebp),%esi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103738:	89 74 24 04          	mov    %esi,0x4(%esp)
f010373c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0103743:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103745:	83 eb 01             	sub    $0x1,%ebx
f0103748:	75 ee                	jne    f0103738 <vprintfmt+0x30e>
f010374a:	e9 aa fd ff ff       	jmp    f01034f9 <vprintfmt+0xcf>
f010374f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103752:	83 f9 01             	cmp    $0x1,%ecx
f0103755:	7e 10                	jle    f0103767 <vprintfmt+0x33d>
		return va_arg(*ap, long long);
f0103757:	8b 45 14             	mov    0x14(%ebp),%eax
f010375a:	8d 50 08             	lea    0x8(%eax),%edx
f010375d:	89 55 14             	mov    %edx,0x14(%ebp)
f0103760:	8b 30                	mov    (%eax),%esi
f0103762:	8b 78 04             	mov    0x4(%eax),%edi
f0103765:	eb 26                	jmp    f010378d <vprintfmt+0x363>
	else if (lflag)
f0103767:	85 c9                	test   %ecx,%ecx
f0103769:	74 12                	je     f010377d <vprintfmt+0x353>
		return va_arg(*ap, long);
f010376b:	8b 45 14             	mov    0x14(%ebp),%eax
f010376e:	8d 50 04             	lea    0x4(%eax),%edx
f0103771:	89 55 14             	mov    %edx,0x14(%ebp)
f0103774:	8b 30                	mov    (%eax),%esi
f0103776:	89 f7                	mov    %esi,%edi
f0103778:	c1 ff 1f             	sar    $0x1f,%edi
f010377b:	eb 10                	jmp    f010378d <vprintfmt+0x363>
	else
		return va_arg(*ap, int);
f010377d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103780:	8d 50 04             	lea    0x4(%eax),%edx
f0103783:	89 55 14             	mov    %edx,0x14(%ebp)
f0103786:	8b 30                	mov    (%eax),%esi
f0103788:	89 f7                	mov    %esi,%edi
f010378a:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010378d:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103792:	85 ff                	test   %edi,%edi
f0103794:	0f 89 9e 00 00 00    	jns    f0103838 <vprintfmt+0x40e>
				putch('-', putdat);
f010379a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010379d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01037a1:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01037a8:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01037ab:	f7 de                	neg    %esi
f01037ad:	83 d7 00             	adc    $0x0,%edi
f01037b0:	f7 df                	neg    %edi
			}
			base = 10;
f01037b2:	b8 0a 00 00 00       	mov    $0xa,%eax
f01037b7:	eb 7f                	jmp    f0103838 <vprintfmt+0x40e>
f01037b9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01037bc:	89 ca                	mov    %ecx,%edx
f01037be:	8d 45 14             	lea    0x14(%ebp),%eax
f01037c1:	e8 e5 fb ff ff       	call   f01033ab <getuint>
f01037c6:	89 c6                	mov    %eax,%esi
f01037c8:	89 d7                	mov    %edx,%edi
			base = 10;
f01037ca:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f01037cf:	eb 67                	jmp    f0103838 <vprintfmt+0x40e>
f01037d1:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap,lflag);
f01037d4:	89 ca                	mov    %ecx,%edx
f01037d6:	8d 45 14             	lea    0x14(%ebp),%eax
f01037d9:	e8 cd fb ff ff       	call   f01033ab <getuint>
f01037de:	89 c6                	mov    %eax,%esi
f01037e0:	89 d7                	mov    %edx,%edi
			base = 8;
f01037e2:	b8 08 00 00 00       	mov    $0x8,%eax

			goto number;
f01037e7:	eb 4f                	jmp    f0103838 <vprintfmt+0x40e>
f01037e9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// pointer
		case 'p':
			putch('0', putdat);
f01037ec:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01037ef:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01037f3:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01037fa:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01037fd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103801:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0103808:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010380b:	8b 45 14             	mov    0x14(%ebp),%eax
f010380e:	8d 50 04             	lea    0x4(%eax),%edx
f0103811:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103814:	8b 30                	mov    (%eax),%esi
f0103816:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010381b:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0103820:	eb 16                	jmp    f0103838 <vprintfmt+0x40e>
f0103822:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103825:	89 ca                	mov    %ecx,%edx
f0103827:	8d 45 14             	lea    0x14(%ebp),%eax
f010382a:	e8 7c fb ff ff       	call   f01033ab <getuint>
f010382f:	89 c6                	mov    %eax,%esi
f0103831:	89 d7                	mov    %edx,%edi
			base = 16;
f0103833:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103838:	0f be 55 e0          	movsbl -0x20(%ebp),%edx
f010383c:	89 54 24 10          	mov    %edx,0x10(%esp)
f0103840:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103843:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103847:	89 44 24 08          	mov    %eax,0x8(%esp)
f010384b:	89 34 24             	mov    %esi,(%esp)
f010384e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103852:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103855:	8b 45 08             	mov    0x8(%ebp),%eax
f0103858:	e8 73 fa ff ff       	call   f01032d0 <printnum>
			break;
f010385d:	e9 97 fc ff ff       	jmp    f01034f9 <vprintfmt+0xcf>
f0103862:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103865:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103868:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010386b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010386f:	89 14 24             	mov    %edx,(%esp)
f0103872:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103875:	e9 7f fc ff ff       	jmp    f01034f9 <vprintfmt+0xcf>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010387a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010387d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103881:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0103888:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f010388b:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f010388e:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0103892:	0f 84 61 fc ff ff    	je     f01034f9 <vprintfmt+0xcf>
f0103898:	83 eb 01             	sub    $0x1,%ebx
f010389b:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f010389f:	75 f7                	jne    f0103898 <vprintfmt+0x46e>
f01038a1:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f01038a4:	e9 50 fc ff ff       	jmp    f01034f9 <vprintfmt+0xcf>
				/* do nothing */;
			break;
		}
	}
}
f01038a9:	83 c4 3c             	add    $0x3c,%esp
f01038ac:	5b                   	pop    %ebx
f01038ad:	5e                   	pop    %esi
f01038ae:	5f                   	pop    %edi
f01038af:	5d                   	pop    %ebp
f01038b0:	c3                   	ret    

f01038b1 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01038b1:	55                   	push   %ebp
f01038b2:	89 e5                	mov    %esp,%ebp
f01038b4:	83 ec 28             	sub    $0x28,%esp
f01038b7:	8b 45 08             	mov    0x8(%ebp),%eax
f01038ba:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01038bd:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01038c0:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01038c4:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01038c7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01038ce:	85 c0                	test   %eax,%eax
f01038d0:	74 30                	je     f0103902 <vsnprintf+0x51>
f01038d2:	85 d2                	test   %edx,%edx
f01038d4:	7e 2c                	jle    f0103902 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01038d6:	8b 45 14             	mov    0x14(%ebp),%eax
f01038d9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01038dd:	8b 45 10             	mov    0x10(%ebp),%eax
f01038e0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01038e4:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01038e7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01038eb:	c7 04 24 e5 33 10 f0 	movl   $0xf01033e5,(%esp)
f01038f2:	e8 33 fb ff ff       	call   f010342a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01038f7:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01038fa:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01038fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103900:	eb 05                	jmp    f0103907 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103902:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103907:	c9                   	leave  
f0103908:	c3                   	ret    

f0103909 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103909:	55                   	push   %ebp
f010390a:	89 e5                	mov    %esp,%ebp
f010390c:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010390f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103912:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103916:	8b 45 10             	mov    0x10(%ebp),%eax
f0103919:	89 44 24 08          	mov    %eax,0x8(%esp)
f010391d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103920:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103924:	8b 45 08             	mov    0x8(%ebp),%eax
f0103927:	89 04 24             	mov    %eax,(%esp)
f010392a:	e8 82 ff ff ff       	call   f01038b1 <vsnprintf>
	va_end(ap);

	return rc;
}
f010392f:	c9                   	leave  
f0103930:	c3                   	ret    
	...

f0103940 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103940:	55                   	push   %ebp
f0103941:	89 e5                	mov    %esp,%ebp
f0103943:	57                   	push   %edi
f0103944:	56                   	push   %esi
f0103945:	53                   	push   %ebx
f0103946:	83 ec 1c             	sub    $0x1c,%esp
f0103949:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010394c:	85 c0                	test   %eax,%eax
f010394e:	74 10                	je     f0103960 <readline+0x20>
		cprintf("%s", prompt);
f0103950:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103954:	c7 04 24 7c 4f 10 f0 	movl   $0xf0104f7c,(%esp)
f010395b:	e8 66 f6 ff ff       	call   f0102fc6 <cprintf>

	i = 0;
	echoing = iscons(0);
f0103960:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103967:	e8 a6 cc ff ff       	call   f0100612 <iscons>
f010396c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010396e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103973:	e8 89 cc ff ff       	call   f0100601 <getchar>
f0103978:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010397a:	85 c0                	test   %eax,%eax
f010397c:	79 17                	jns    f0103995 <readline+0x55>
			cprintf("read error: %e\n", c);
f010397e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103982:	c7 04 24 20 54 10 f0 	movl   $0xf0105420,(%esp)
f0103989:	e8 38 f6 ff ff       	call   f0102fc6 <cprintf>
			return NULL;
f010398e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103993:	eb 6d                	jmp    f0103a02 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103995:	83 f8 08             	cmp    $0x8,%eax
f0103998:	74 05                	je     f010399f <readline+0x5f>
f010399a:	83 f8 7f             	cmp    $0x7f,%eax
f010399d:	75 19                	jne    f01039b8 <readline+0x78>
f010399f:	85 f6                	test   %esi,%esi
f01039a1:	7e 15                	jle    f01039b8 <readline+0x78>
			if (echoing)
f01039a3:	85 ff                	test   %edi,%edi
f01039a5:	74 0c                	je     f01039b3 <readline+0x73>
				cputchar('\b');
f01039a7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01039ae:	e8 3e cc ff ff       	call   f01005f1 <cputchar>
			i--;
f01039b3:	83 ee 01             	sub    $0x1,%esi
f01039b6:	eb bb                	jmp    f0103973 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01039b8:	83 fb 1f             	cmp    $0x1f,%ebx
f01039bb:	7e 1f                	jle    f01039dc <readline+0x9c>
f01039bd:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01039c3:	7f 17                	jg     f01039dc <readline+0x9c>
			if (echoing)
f01039c5:	85 ff                	test   %edi,%edi
f01039c7:	74 08                	je     f01039d1 <readline+0x91>
				cputchar(c);
f01039c9:	89 1c 24             	mov    %ebx,(%esp)
f01039cc:	e8 20 cc ff ff       	call   f01005f1 <cputchar>
			buf[i++] = c;
f01039d1:	88 9e a0 85 11 f0    	mov    %bl,-0xfee7a60(%esi)
f01039d7:	83 c6 01             	add    $0x1,%esi
f01039da:	eb 97                	jmp    f0103973 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01039dc:	83 fb 0a             	cmp    $0xa,%ebx
f01039df:	74 05                	je     f01039e6 <readline+0xa6>
f01039e1:	83 fb 0d             	cmp    $0xd,%ebx
f01039e4:	75 8d                	jne    f0103973 <readline+0x33>
			if (echoing)
f01039e6:	85 ff                	test   %edi,%edi
f01039e8:	74 0c                	je     f01039f6 <readline+0xb6>
				cputchar('\n');
f01039ea:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01039f1:	e8 fb cb ff ff       	call   f01005f1 <cputchar>
			buf[i] = 0;
f01039f6:	c6 86 a0 85 11 f0 00 	movb   $0x0,-0xfee7a60(%esi)
			return buf;
f01039fd:	b8 a0 85 11 f0       	mov    $0xf01185a0,%eax
		}
	}
}
f0103a02:	83 c4 1c             	add    $0x1c,%esp
f0103a05:	5b                   	pop    %ebx
f0103a06:	5e                   	pop    %esi
f0103a07:	5f                   	pop    %edi
f0103a08:	5d                   	pop    %ebp
f0103a09:	c3                   	ret    
f0103a0a:	00 00                	add    %al,(%eax)
f0103a0c:	00 00                	add    %al,(%eax)
	...

f0103a10 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103a10:	55                   	push   %ebp
f0103a11:	89 e5                	mov    %esp,%ebp
f0103a13:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103a16:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a1b:	80 3a 00             	cmpb   $0x0,(%edx)
f0103a1e:	74 09                	je     f0103a29 <strlen+0x19>
		n++;
f0103a20:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103a23:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103a27:	75 f7                	jne    f0103a20 <strlen+0x10>
		n++;
	return n;
}
f0103a29:	5d                   	pop    %ebp
f0103a2a:	c3                   	ret    

f0103a2b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103a2b:	55                   	push   %ebp
f0103a2c:	89 e5                	mov    %esp,%ebp
f0103a2e:	53                   	push   %ebx
f0103a2f:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103a32:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103a35:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a3a:	85 c9                	test   %ecx,%ecx
f0103a3c:	74 1a                	je     f0103a58 <strnlen+0x2d>
f0103a3e:	80 3b 00             	cmpb   $0x0,(%ebx)
f0103a41:	74 15                	je     f0103a58 <strnlen+0x2d>
f0103a43:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f0103a48:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103a4a:	39 ca                	cmp    %ecx,%edx
f0103a4c:	74 0a                	je     f0103a58 <strnlen+0x2d>
f0103a4e:	83 c2 01             	add    $0x1,%edx
f0103a51:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0103a56:	75 f0                	jne    f0103a48 <strnlen+0x1d>
		n++;
	return n;
}
f0103a58:	5b                   	pop    %ebx
f0103a59:	5d                   	pop    %ebp
f0103a5a:	c3                   	ret    

f0103a5b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103a5b:	55                   	push   %ebp
f0103a5c:	89 e5                	mov    %esp,%ebp
f0103a5e:	53                   	push   %ebx
f0103a5f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a62:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103a65:	ba 00 00 00 00       	mov    $0x0,%edx
f0103a6a:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0103a6e:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0103a71:	83 c2 01             	add    $0x1,%edx
f0103a74:	84 c9                	test   %cl,%cl
f0103a76:	75 f2                	jne    f0103a6a <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0103a78:	5b                   	pop    %ebx
f0103a79:	5d                   	pop    %ebp
f0103a7a:	c3                   	ret    

f0103a7b <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103a7b:	55                   	push   %ebp
f0103a7c:	89 e5                	mov    %esp,%ebp
f0103a7e:	56                   	push   %esi
f0103a7f:	53                   	push   %ebx
f0103a80:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a83:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103a86:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103a89:	85 f6                	test   %esi,%esi
f0103a8b:	74 18                	je     f0103aa5 <strncpy+0x2a>
f0103a8d:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f0103a92:	0f b6 1a             	movzbl (%edx),%ebx
f0103a95:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103a98:	80 3a 01             	cmpb   $0x1,(%edx)
f0103a9b:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103a9e:	83 c1 01             	add    $0x1,%ecx
f0103aa1:	39 f1                	cmp    %esi,%ecx
f0103aa3:	75 ed                	jne    f0103a92 <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103aa5:	5b                   	pop    %ebx
f0103aa6:	5e                   	pop    %esi
f0103aa7:	5d                   	pop    %ebp
f0103aa8:	c3                   	ret    

f0103aa9 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103aa9:	55                   	push   %ebp
f0103aaa:	89 e5                	mov    %esp,%ebp
f0103aac:	57                   	push   %edi
f0103aad:	56                   	push   %esi
f0103aae:	53                   	push   %ebx
f0103aaf:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103ab2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103ab5:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103ab8:	89 f8                	mov    %edi,%eax
f0103aba:	85 f6                	test   %esi,%esi
f0103abc:	74 2b                	je     f0103ae9 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f0103abe:	83 fe 01             	cmp    $0x1,%esi
f0103ac1:	74 23                	je     f0103ae6 <strlcpy+0x3d>
f0103ac3:	0f b6 0b             	movzbl (%ebx),%ecx
f0103ac6:	84 c9                	test   %cl,%cl
f0103ac8:	74 1c                	je     f0103ae6 <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f0103aca:	83 ee 02             	sub    $0x2,%esi
f0103acd:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103ad2:	88 08                	mov    %cl,(%eax)
f0103ad4:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103ad7:	39 f2                	cmp    %esi,%edx
f0103ad9:	74 0b                	je     f0103ae6 <strlcpy+0x3d>
f0103adb:	83 c2 01             	add    $0x1,%edx
f0103ade:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0103ae2:	84 c9                	test   %cl,%cl
f0103ae4:	75 ec                	jne    f0103ad2 <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f0103ae6:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103ae9:	29 f8                	sub    %edi,%eax
}
f0103aeb:	5b                   	pop    %ebx
f0103aec:	5e                   	pop    %esi
f0103aed:	5f                   	pop    %edi
f0103aee:	5d                   	pop    %ebp
f0103aef:	c3                   	ret    

f0103af0 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103af0:	55                   	push   %ebp
f0103af1:	89 e5                	mov    %esp,%ebp
f0103af3:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103af6:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103af9:	0f b6 01             	movzbl (%ecx),%eax
f0103afc:	84 c0                	test   %al,%al
f0103afe:	74 16                	je     f0103b16 <strcmp+0x26>
f0103b00:	3a 02                	cmp    (%edx),%al
f0103b02:	75 12                	jne    f0103b16 <strcmp+0x26>
		p++, q++;
f0103b04:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103b07:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f0103b0b:	84 c0                	test   %al,%al
f0103b0d:	74 07                	je     f0103b16 <strcmp+0x26>
f0103b0f:	83 c1 01             	add    $0x1,%ecx
f0103b12:	3a 02                	cmp    (%edx),%al
f0103b14:	74 ee                	je     f0103b04 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103b16:	0f b6 c0             	movzbl %al,%eax
f0103b19:	0f b6 12             	movzbl (%edx),%edx
f0103b1c:	29 d0                	sub    %edx,%eax
}
f0103b1e:	5d                   	pop    %ebp
f0103b1f:	c3                   	ret    

f0103b20 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103b20:	55                   	push   %ebp
f0103b21:	89 e5                	mov    %esp,%ebp
f0103b23:	53                   	push   %ebx
f0103b24:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103b27:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103b2a:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103b2d:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103b32:	85 d2                	test   %edx,%edx
f0103b34:	74 28                	je     f0103b5e <strncmp+0x3e>
f0103b36:	0f b6 01             	movzbl (%ecx),%eax
f0103b39:	84 c0                	test   %al,%al
f0103b3b:	74 24                	je     f0103b61 <strncmp+0x41>
f0103b3d:	3a 03                	cmp    (%ebx),%al
f0103b3f:	75 20                	jne    f0103b61 <strncmp+0x41>
f0103b41:	83 ea 01             	sub    $0x1,%edx
f0103b44:	74 13                	je     f0103b59 <strncmp+0x39>
		n--, p++, q++;
f0103b46:	83 c1 01             	add    $0x1,%ecx
f0103b49:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103b4c:	0f b6 01             	movzbl (%ecx),%eax
f0103b4f:	84 c0                	test   %al,%al
f0103b51:	74 0e                	je     f0103b61 <strncmp+0x41>
f0103b53:	3a 03                	cmp    (%ebx),%al
f0103b55:	74 ea                	je     f0103b41 <strncmp+0x21>
f0103b57:	eb 08                	jmp    f0103b61 <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103b59:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103b5e:	5b                   	pop    %ebx
f0103b5f:	5d                   	pop    %ebp
f0103b60:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103b61:	0f b6 01             	movzbl (%ecx),%eax
f0103b64:	0f b6 13             	movzbl (%ebx),%edx
f0103b67:	29 d0                	sub    %edx,%eax
f0103b69:	eb f3                	jmp    f0103b5e <strncmp+0x3e>

f0103b6b <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103b6b:	55                   	push   %ebp
f0103b6c:	89 e5                	mov    %esp,%ebp
f0103b6e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b71:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103b75:	0f b6 10             	movzbl (%eax),%edx
f0103b78:	84 d2                	test   %dl,%dl
f0103b7a:	74 1c                	je     f0103b98 <strchr+0x2d>
		if (*s == c)
f0103b7c:	38 ca                	cmp    %cl,%dl
f0103b7e:	75 09                	jne    f0103b89 <strchr+0x1e>
f0103b80:	eb 1b                	jmp    f0103b9d <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103b82:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f0103b85:	38 ca                	cmp    %cl,%dl
f0103b87:	74 14                	je     f0103b9d <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103b89:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f0103b8d:	84 d2                	test   %dl,%dl
f0103b8f:	75 f1                	jne    f0103b82 <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f0103b91:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b96:	eb 05                	jmp    f0103b9d <strchr+0x32>
f0103b98:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103b9d:	5d                   	pop    %ebp
f0103b9e:	c3                   	ret    

f0103b9f <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103b9f:	55                   	push   %ebp
f0103ba0:	89 e5                	mov    %esp,%ebp
f0103ba2:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ba5:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103ba9:	0f b6 10             	movzbl (%eax),%edx
f0103bac:	84 d2                	test   %dl,%dl
f0103bae:	74 14                	je     f0103bc4 <strfind+0x25>
		if (*s == c)
f0103bb0:	38 ca                	cmp    %cl,%dl
f0103bb2:	75 06                	jne    f0103bba <strfind+0x1b>
f0103bb4:	eb 0e                	jmp    f0103bc4 <strfind+0x25>
f0103bb6:	38 ca                	cmp    %cl,%dl
f0103bb8:	74 0a                	je     f0103bc4 <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0103bba:	83 c0 01             	add    $0x1,%eax
f0103bbd:	0f b6 10             	movzbl (%eax),%edx
f0103bc0:	84 d2                	test   %dl,%dl
f0103bc2:	75 f2                	jne    f0103bb6 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f0103bc4:	5d                   	pop    %ebp
f0103bc5:	c3                   	ret    

f0103bc6 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103bc6:	55                   	push   %ebp
f0103bc7:	89 e5                	mov    %esp,%ebp
f0103bc9:	83 ec 0c             	sub    $0xc,%esp
f0103bcc:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0103bcf:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0103bd2:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0103bd5:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103bd8:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103bdb:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103bde:	85 c9                	test   %ecx,%ecx
f0103be0:	74 30                	je     f0103c12 <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103be2:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103be8:	75 25                	jne    f0103c0f <memset+0x49>
f0103bea:	f6 c1 03             	test   $0x3,%cl
f0103bed:	75 20                	jne    f0103c0f <memset+0x49>
		c &= 0xFF;
f0103bef:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103bf2:	89 d3                	mov    %edx,%ebx
f0103bf4:	c1 e3 08             	shl    $0x8,%ebx
f0103bf7:	89 d6                	mov    %edx,%esi
f0103bf9:	c1 e6 18             	shl    $0x18,%esi
f0103bfc:	89 d0                	mov    %edx,%eax
f0103bfe:	c1 e0 10             	shl    $0x10,%eax
f0103c01:	09 f0                	or     %esi,%eax
f0103c03:	09 d0                	or     %edx,%eax
f0103c05:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0103c07:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0103c0a:	fc                   	cld    
f0103c0b:	f3 ab                	rep stos %eax,%es:(%edi)
f0103c0d:	eb 03                	jmp    f0103c12 <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103c0f:	fc                   	cld    
f0103c10:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103c12:	89 f8                	mov    %edi,%eax
f0103c14:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0103c17:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0103c1a:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0103c1d:	89 ec                	mov    %ebp,%esp
f0103c1f:	5d                   	pop    %ebp
f0103c20:	c3                   	ret    

f0103c21 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103c21:	55                   	push   %ebp
f0103c22:	89 e5                	mov    %esp,%ebp
f0103c24:	83 ec 08             	sub    $0x8,%esp
f0103c27:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0103c2a:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0103c2d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c30:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103c33:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103c36:	39 c6                	cmp    %eax,%esi
f0103c38:	73 36                	jae    f0103c70 <memmove+0x4f>
f0103c3a:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103c3d:	39 d0                	cmp    %edx,%eax
f0103c3f:	73 2f                	jae    f0103c70 <memmove+0x4f>
		s += n;
		d += n;
f0103c41:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103c44:	f6 c2 03             	test   $0x3,%dl
f0103c47:	75 1b                	jne    f0103c64 <memmove+0x43>
f0103c49:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103c4f:	75 13                	jne    f0103c64 <memmove+0x43>
f0103c51:	f6 c1 03             	test   $0x3,%cl
f0103c54:	75 0e                	jne    f0103c64 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103c56:	83 ef 04             	sub    $0x4,%edi
f0103c59:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103c5c:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0103c5f:	fd                   	std    
f0103c60:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103c62:	eb 09                	jmp    f0103c6d <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0103c64:	83 ef 01             	sub    $0x1,%edi
f0103c67:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103c6a:	fd                   	std    
f0103c6b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103c6d:	fc                   	cld    
f0103c6e:	eb 20                	jmp    f0103c90 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103c70:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103c76:	75 13                	jne    f0103c8b <memmove+0x6a>
f0103c78:	a8 03                	test   $0x3,%al
f0103c7a:	75 0f                	jne    f0103c8b <memmove+0x6a>
f0103c7c:	f6 c1 03             	test   $0x3,%cl
f0103c7f:	75 0a                	jne    f0103c8b <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103c81:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0103c84:	89 c7                	mov    %eax,%edi
f0103c86:	fc                   	cld    
f0103c87:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103c89:	eb 05                	jmp    f0103c90 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103c8b:	89 c7                	mov    %eax,%edi
f0103c8d:	fc                   	cld    
f0103c8e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103c90:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0103c93:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0103c96:	89 ec                	mov    %ebp,%esp
f0103c98:	5d                   	pop    %ebp
f0103c99:	c3                   	ret    

f0103c9a <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0103c9a:	55                   	push   %ebp
f0103c9b:	89 e5                	mov    %esp,%ebp
f0103c9d:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0103ca0:	8b 45 10             	mov    0x10(%ebp),%eax
f0103ca3:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103ca7:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103caa:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103cae:	8b 45 08             	mov    0x8(%ebp),%eax
f0103cb1:	89 04 24             	mov    %eax,(%esp)
f0103cb4:	e8 68 ff ff ff       	call   f0103c21 <memmove>
}
f0103cb9:	c9                   	leave  
f0103cba:	c3                   	ret    

f0103cbb <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103cbb:	55                   	push   %ebp
f0103cbc:	89 e5                	mov    %esp,%ebp
f0103cbe:	57                   	push   %edi
f0103cbf:	56                   	push   %esi
f0103cc0:	53                   	push   %ebx
f0103cc1:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103cc4:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103cc7:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103cca:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103ccf:	85 ff                	test   %edi,%edi
f0103cd1:	74 37                	je     f0103d0a <memcmp+0x4f>
		if (*s1 != *s2)
f0103cd3:	0f b6 03             	movzbl (%ebx),%eax
f0103cd6:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103cd9:	83 ef 01             	sub    $0x1,%edi
f0103cdc:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f0103ce1:	38 c8                	cmp    %cl,%al
f0103ce3:	74 1c                	je     f0103d01 <memcmp+0x46>
f0103ce5:	eb 10                	jmp    f0103cf7 <memcmp+0x3c>
f0103ce7:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0103cec:	83 c2 01             	add    $0x1,%edx
f0103cef:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0103cf3:	38 c8                	cmp    %cl,%al
f0103cf5:	74 0a                	je     f0103d01 <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f0103cf7:	0f b6 c0             	movzbl %al,%eax
f0103cfa:	0f b6 c9             	movzbl %cl,%ecx
f0103cfd:	29 c8                	sub    %ecx,%eax
f0103cff:	eb 09                	jmp    f0103d0a <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103d01:	39 fa                	cmp    %edi,%edx
f0103d03:	75 e2                	jne    f0103ce7 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103d05:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103d0a:	5b                   	pop    %ebx
f0103d0b:	5e                   	pop    %esi
f0103d0c:	5f                   	pop    %edi
f0103d0d:	5d                   	pop    %ebp
f0103d0e:	c3                   	ret    

f0103d0f <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103d0f:	55                   	push   %ebp
f0103d10:	89 e5                	mov    %esp,%ebp
f0103d12:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103d15:	89 c2                	mov    %eax,%edx
f0103d17:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103d1a:	39 d0                	cmp    %edx,%eax
f0103d1c:	73 15                	jae    f0103d33 <memfind+0x24>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103d1e:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f0103d22:	38 08                	cmp    %cl,(%eax)
f0103d24:	75 06                	jne    f0103d2c <memfind+0x1d>
f0103d26:	eb 0b                	jmp    f0103d33 <memfind+0x24>
f0103d28:	38 08                	cmp    %cl,(%eax)
f0103d2a:	74 07                	je     f0103d33 <memfind+0x24>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103d2c:	83 c0 01             	add    $0x1,%eax
f0103d2f:	39 d0                	cmp    %edx,%eax
f0103d31:	75 f5                	jne    f0103d28 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103d33:	5d                   	pop    %ebp
f0103d34:	c3                   	ret    

f0103d35 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103d35:	55                   	push   %ebp
f0103d36:	89 e5                	mov    %esp,%ebp
f0103d38:	57                   	push   %edi
f0103d39:	56                   	push   %esi
f0103d3a:	53                   	push   %ebx
f0103d3b:	8b 55 08             	mov    0x8(%ebp),%edx
f0103d3e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103d41:	0f b6 02             	movzbl (%edx),%eax
f0103d44:	3c 20                	cmp    $0x20,%al
f0103d46:	74 04                	je     f0103d4c <strtol+0x17>
f0103d48:	3c 09                	cmp    $0x9,%al
f0103d4a:	75 0e                	jne    f0103d5a <strtol+0x25>
		s++;
f0103d4c:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103d4f:	0f b6 02             	movzbl (%edx),%eax
f0103d52:	3c 20                	cmp    $0x20,%al
f0103d54:	74 f6                	je     f0103d4c <strtol+0x17>
f0103d56:	3c 09                	cmp    $0x9,%al
f0103d58:	74 f2                	je     f0103d4c <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103d5a:	3c 2b                	cmp    $0x2b,%al
f0103d5c:	75 0a                	jne    f0103d68 <strtol+0x33>
		s++;
f0103d5e:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103d61:	bf 00 00 00 00       	mov    $0x0,%edi
f0103d66:	eb 10                	jmp    f0103d78 <strtol+0x43>
f0103d68:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103d6d:	3c 2d                	cmp    $0x2d,%al
f0103d6f:	75 07                	jne    f0103d78 <strtol+0x43>
		s++, neg = 1;
f0103d71:	83 c2 01             	add    $0x1,%edx
f0103d74:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103d78:	85 db                	test   %ebx,%ebx
f0103d7a:	0f 94 c0             	sete   %al
f0103d7d:	74 05                	je     f0103d84 <strtol+0x4f>
f0103d7f:	83 fb 10             	cmp    $0x10,%ebx
f0103d82:	75 15                	jne    f0103d99 <strtol+0x64>
f0103d84:	80 3a 30             	cmpb   $0x30,(%edx)
f0103d87:	75 10                	jne    f0103d99 <strtol+0x64>
f0103d89:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0103d8d:	75 0a                	jne    f0103d99 <strtol+0x64>
		s += 2, base = 16;
f0103d8f:	83 c2 02             	add    $0x2,%edx
f0103d92:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103d97:	eb 13                	jmp    f0103dac <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f0103d99:	84 c0                	test   %al,%al
f0103d9b:	74 0f                	je     f0103dac <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103d9d:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103da2:	80 3a 30             	cmpb   $0x30,(%edx)
f0103da5:	75 05                	jne    f0103dac <strtol+0x77>
		s++, base = 8;
f0103da7:	83 c2 01             	add    $0x1,%edx
f0103daa:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f0103dac:	b8 00 00 00 00       	mov    $0x0,%eax
f0103db1:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103db3:	0f b6 0a             	movzbl (%edx),%ecx
f0103db6:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0103db9:	80 fb 09             	cmp    $0x9,%bl
f0103dbc:	77 08                	ja     f0103dc6 <strtol+0x91>
			dig = *s - '0';
f0103dbe:	0f be c9             	movsbl %cl,%ecx
f0103dc1:	83 e9 30             	sub    $0x30,%ecx
f0103dc4:	eb 1e                	jmp    f0103de4 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f0103dc6:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f0103dc9:	80 fb 19             	cmp    $0x19,%bl
f0103dcc:	77 08                	ja     f0103dd6 <strtol+0xa1>
			dig = *s - 'a' + 10;
f0103dce:	0f be c9             	movsbl %cl,%ecx
f0103dd1:	83 e9 57             	sub    $0x57,%ecx
f0103dd4:	eb 0e                	jmp    f0103de4 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f0103dd6:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0103dd9:	80 fb 19             	cmp    $0x19,%bl
f0103ddc:	77 14                	ja     f0103df2 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103dde:	0f be c9             	movsbl %cl,%ecx
f0103de1:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0103de4:	39 f1                	cmp    %esi,%ecx
f0103de6:	7d 0e                	jge    f0103df6 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f0103de8:	83 c2 01             	add    $0x1,%edx
f0103deb:	0f af c6             	imul   %esi,%eax
f0103dee:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0103df0:	eb c1                	jmp    f0103db3 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0103df2:	89 c1                	mov    %eax,%ecx
f0103df4:	eb 02                	jmp    f0103df8 <strtol+0xc3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0103df6:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0103df8:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103dfc:	74 05                	je     f0103e03 <strtol+0xce>
		*endptr = (char *) s;
f0103dfe:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103e01:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0103e03:	89 ca                	mov    %ecx,%edx
f0103e05:	f7 da                	neg    %edx
f0103e07:	85 ff                	test   %edi,%edi
f0103e09:	0f 45 c2             	cmovne %edx,%eax
}
f0103e0c:	5b                   	pop    %ebx
f0103e0d:	5e                   	pop    %esi
f0103e0e:	5f                   	pop    %edi
f0103e0f:	5d                   	pop    %ebp
f0103e10:	c3                   	ret    
	...

f0103e20 <__udivdi3>:
f0103e20:	83 ec 1c             	sub    $0x1c,%esp
f0103e23:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0103e27:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f0103e2b:	8b 44 24 20          	mov    0x20(%esp),%eax
f0103e2f:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0103e33:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103e37:	8b 74 24 24          	mov    0x24(%esp),%esi
f0103e3b:	85 ff                	test   %edi,%edi
f0103e3d:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0103e41:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103e45:	89 cd                	mov    %ecx,%ebp
f0103e47:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103e4b:	75 33                	jne    f0103e80 <__udivdi3+0x60>
f0103e4d:	39 f1                	cmp    %esi,%ecx
f0103e4f:	77 57                	ja     f0103ea8 <__udivdi3+0x88>
f0103e51:	85 c9                	test   %ecx,%ecx
f0103e53:	75 0b                	jne    f0103e60 <__udivdi3+0x40>
f0103e55:	b8 01 00 00 00       	mov    $0x1,%eax
f0103e5a:	31 d2                	xor    %edx,%edx
f0103e5c:	f7 f1                	div    %ecx
f0103e5e:	89 c1                	mov    %eax,%ecx
f0103e60:	89 f0                	mov    %esi,%eax
f0103e62:	31 d2                	xor    %edx,%edx
f0103e64:	f7 f1                	div    %ecx
f0103e66:	89 c6                	mov    %eax,%esi
f0103e68:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103e6c:	f7 f1                	div    %ecx
f0103e6e:	89 f2                	mov    %esi,%edx
f0103e70:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103e74:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103e78:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103e7c:	83 c4 1c             	add    $0x1c,%esp
f0103e7f:	c3                   	ret    
f0103e80:	31 d2                	xor    %edx,%edx
f0103e82:	31 c0                	xor    %eax,%eax
f0103e84:	39 f7                	cmp    %esi,%edi
f0103e86:	77 e8                	ja     f0103e70 <__udivdi3+0x50>
f0103e88:	0f bd cf             	bsr    %edi,%ecx
f0103e8b:	83 f1 1f             	xor    $0x1f,%ecx
f0103e8e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103e92:	75 2c                	jne    f0103ec0 <__udivdi3+0xa0>
f0103e94:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0103e98:	76 04                	jbe    f0103e9e <__udivdi3+0x7e>
f0103e9a:	39 f7                	cmp    %esi,%edi
f0103e9c:	73 d2                	jae    f0103e70 <__udivdi3+0x50>
f0103e9e:	31 d2                	xor    %edx,%edx
f0103ea0:	b8 01 00 00 00       	mov    $0x1,%eax
f0103ea5:	eb c9                	jmp    f0103e70 <__udivdi3+0x50>
f0103ea7:	90                   	nop
f0103ea8:	89 f2                	mov    %esi,%edx
f0103eaa:	f7 f1                	div    %ecx
f0103eac:	31 d2                	xor    %edx,%edx
f0103eae:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103eb2:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103eb6:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103eba:	83 c4 1c             	add    $0x1c,%esp
f0103ebd:	c3                   	ret    
f0103ebe:	66 90                	xchg   %ax,%ax
f0103ec0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103ec5:	b8 20 00 00 00       	mov    $0x20,%eax
f0103eca:	89 ea                	mov    %ebp,%edx
f0103ecc:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103ed0:	d3 e7                	shl    %cl,%edi
f0103ed2:	89 c1                	mov    %eax,%ecx
f0103ed4:	d3 ea                	shr    %cl,%edx
f0103ed6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103edb:	09 fa                	or     %edi,%edx
f0103edd:	89 f7                	mov    %esi,%edi
f0103edf:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103ee3:	89 f2                	mov    %esi,%edx
f0103ee5:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103ee9:	d3 e5                	shl    %cl,%ebp
f0103eeb:	89 c1                	mov    %eax,%ecx
f0103eed:	d3 ef                	shr    %cl,%edi
f0103eef:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103ef4:	d3 e2                	shl    %cl,%edx
f0103ef6:	89 c1                	mov    %eax,%ecx
f0103ef8:	d3 ee                	shr    %cl,%esi
f0103efa:	09 d6                	or     %edx,%esi
f0103efc:	89 fa                	mov    %edi,%edx
f0103efe:	89 f0                	mov    %esi,%eax
f0103f00:	f7 74 24 0c          	divl   0xc(%esp)
f0103f04:	89 d7                	mov    %edx,%edi
f0103f06:	89 c6                	mov    %eax,%esi
f0103f08:	f7 e5                	mul    %ebp
f0103f0a:	39 d7                	cmp    %edx,%edi
f0103f0c:	72 22                	jb     f0103f30 <__udivdi3+0x110>
f0103f0e:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0103f12:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103f17:	d3 e5                	shl    %cl,%ebp
f0103f19:	39 c5                	cmp    %eax,%ebp
f0103f1b:	73 04                	jae    f0103f21 <__udivdi3+0x101>
f0103f1d:	39 d7                	cmp    %edx,%edi
f0103f1f:	74 0f                	je     f0103f30 <__udivdi3+0x110>
f0103f21:	89 f0                	mov    %esi,%eax
f0103f23:	31 d2                	xor    %edx,%edx
f0103f25:	e9 46 ff ff ff       	jmp    f0103e70 <__udivdi3+0x50>
f0103f2a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103f30:	8d 46 ff             	lea    -0x1(%esi),%eax
f0103f33:	31 d2                	xor    %edx,%edx
f0103f35:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103f39:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103f3d:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103f41:	83 c4 1c             	add    $0x1c,%esp
f0103f44:	c3                   	ret    
	...

f0103f50 <__umoddi3>:
f0103f50:	83 ec 1c             	sub    $0x1c,%esp
f0103f53:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0103f57:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f0103f5b:	8b 44 24 20          	mov    0x20(%esp),%eax
f0103f5f:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103f63:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0103f67:	8b 74 24 24          	mov    0x24(%esp),%esi
f0103f6b:	85 ed                	test   %ebp,%ebp
f0103f6d:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0103f71:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103f75:	89 cf                	mov    %ecx,%edi
f0103f77:	89 04 24             	mov    %eax,(%esp)
f0103f7a:	89 f2                	mov    %esi,%edx
f0103f7c:	75 1a                	jne    f0103f98 <__umoddi3+0x48>
f0103f7e:	39 f1                	cmp    %esi,%ecx
f0103f80:	76 4e                	jbe    f0103fd0 <__umoddi3+0x80>
f0103f82:	f7 f1                	div    %ecx
f0103f84:	89 d0                	mov    %edx,%eax
f0103f86:	31 d2                	xor    %edx,%edx
f0103f88:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103f8c:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103f90:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103f94:	83 c4 1c             	add    $0x1c,%esp
f0103f97:	c3                   	ret    
f0103f98:	39 f5                	cmp    %esi,%ebp
f0103f9a:	77 54                	ja     f0103ff0 <__umoddi3+0xa0>
f0103f9c:	0f bd c5             	bsr    %ebp,%eax
f0103f9f:	83 f0 1f             	xor    $0x1f,%eax
f0103fa2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103fa6:	75 60                	jne    f0104008 <__umoddi3+0xb8>
f0103fa8:	3b 0c 24             	cmp    (%esp),%ecx
f0103fab:	0f 87 07 01 00 00    	ja     f01040b8 <__umoddi3+0x168>
f0103fb1:	89 f2                	mov    %esi,%edx
f0103fb3:	8b 34 24             	mov    (%esp),%esi
f0103fb6:	29 ce                	sub    %ecx,%esi
f0103fb8:	19 ea                	sbb    %ebp,%edx
f0103fba:	89 34 24             	mov    %esi,(%esp)
f0103fbd:	8b 04 24             	mov    (%esp),%eax
f0103fc0:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103fc4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103fc8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103fcc:	83 c4 1c             	add    $0x1c,%esp
f0103fcf:	c3                   	ret    
f0103fd0:	85 c9                	test   %ecx,%ecx
f0103fd2:	75 0b                	jne    f0103fdf <__umoddi3+0x8f>
f0103fd4:	b8 01 00 00 00       	mov    $0x1,%eax
f0103fd9:	31 d2                	xor    %edx,%edx
f0103fdb:	f7 f1                	div    %ecx
f0103fdd:	89 c1                	mov    %eax,%ecx
f0103fdf:	89 f0                	mov    %esi,%eax
f0103fe1:	31 d2                	xor    %edx,%edx
f0103fe3:	f7 f1                	div    %ecx
f0103fe5:	8b 04 24             	mov    (%esp),%eax
f0103fe8:	f7 f1                	div    %ecx
f0103fea:	eb 98                	jmp    f0103f84 <__umoddi3+0x34>
f0103fec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103ff0:	89 f2                	mov    %esi,%edx
f0103ff2:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103ff6:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103ffa:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103ffe:	83 c4 1c             	add    $0x1c,%esp
f0104001:	c3                   	ret    
f0104002:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104008:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010400d:	89 e8                	mov    %ebp,%eax
f010400f:	bd 20 00 00 00       	mov    $0x20,%ebp
f0104014:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0104018:	89 fa                	mov    %edi,%edx
f010401a:	d3 e0                	shl    %cl,%eax
f010401c:	89 e9                	mov    %ebp,%ecx
f010401e:	d3 ea                	shr    %cl,%edx
f0104020:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104025:	09 c2                	or     %eax,%edx
f0104027:	8b 44 24 08          	mov    0x8(%esp),%eax
f010402b:	89 14 24             	mov    %edx,(%esp)
f010402e:	89 f2                	mov    %esi,%edx
f0104030:	d3 e7                	shl    %cl,%edi
f0104032:	89 e9                	mov    %ebp,%ecx
f0104034:	d3 ea                	shr    %cl,%edx
f0104036:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010403b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010403f:	d3 e6                	shl    %cl,%esi
f0104041:	89 e9                	mov    %ebp,%ecx
f0104043:	d3 e8                	shr    %cl,%eax
f0104045:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010404a:	09 f0                	or     %esi,%eax
f010404c:	8b 74 24 08          	mov    0x8(%esp),%esi
f0104050:	f7 34 24             	divl   (%esp)
f0104053:	d3 e6                	shl    %cl,%esi
f0104055:	89 74 24 08          	mov    %esi,0x8(%esp)
f0104059:	89 d6                	mov    %edx,%esi
f010405b:	f7 e7                	mul    %edi
f010405d:	39 d6                	cmp    %edx,%esi
f010405f:	89 c1                	mov    %eax,%ecx
f0104061:	89 d7                	mov    %edx,%edi
f0104063:	72 3f                	jb     f01040a4 <__umoddi3+0x154>
f0104065:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0104069:	72 35                	jb     f01040a0 <__umoddi3+0x150>
f010406b:	8b 44 24 08          	mov    0x8(%esp),%eax
f010406f:	29 c8                	sub    %ecx,%eax
f0104071:	19 fe                	sbb    %edi,%esi
f0104073:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104078:	89 f2                	mov    %esi,%edx
f010407a:	d3 e8                	shr    %cl,%eax
f010407c:	89 e9                	mov    %ebp,%ecx
f010407e:	d3 e2                	shl    %cl,%edx
f0104080:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104085:	09 d0                	or     %edx,%eax
f0104087:	89 f2                	mov    %esi,%edx
f0104089:	d3 ea                	shr    %cl,%edx
f010408b:	8b 74 24 10          	mov    0x10(%esp),%esi
f010408f:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104093:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104097:	83 c4 1c             	add    $0x1c,%esp
f010409a:	c3                   	ret    
f010409b:	90                   	nop
f010409c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01040a0:	39 d6                	cmp    %edx,%esi
f01040a2:	75 c7                	jne    f010406b <__umoddi3+0x11b>
f01040a4:	89 d7                	mov    %edx,%edi
f01040a6:	89 c1                	mov    %eax,%ecx
f01040a8:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f01040ac:	1b 3c 24             	sbb    (%esp),%edi
f01040af:	eb ba                	jmp    f010406b <__umoddi3+0x11b>
f01040b1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01040b8:	39 f5                	cmp    %esi,%ebp
f01040ba:	0f 82 f1 fe ff ff    	jb     f0103fb1 <__umoddi3+0x61>
f01040c0:	e9 f8 fe ff ff       	jmp    f0103fbd <__umoddi3+0x6d>
