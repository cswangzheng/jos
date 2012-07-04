
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
f0100063:	e8 2e 39 00 00       	call   f0103996 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 8e 04 00 00       	call   f01004fb <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 a0 3e 10 f0 	movl   $0xf0103ea0,(%esp)
f010007c:	e8 11 2d 00 00       	call   f0102d92 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 01 12 00 00       	call   f0101287 <mem_init>

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
f01000c1:	c7 04 24 bb 3e 10 f0 	movl   $0xf0103ebb,(%esp)
f01000c8:	e8 c5 2c 00 00       	call   f0102d92 <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 86 2c 00 00       	call   f0102d5f <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 1c 4d 10 f0 	movl   $0xf0104d1c,(%esp)
f01000e0:	e8 ad 2c 00 00       	call   f0102d92 <cprintf>
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
f010010b:	c7 04 24 d3 3e 10 f0 	movl   $0xf0103ed3,(%esp)
f0100112:	e8 7b 2c 00 00       	call   f0102d92 <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 39 2c 00 00       	call   f0102d5f <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 1c 4d 10 f0 	movl   $0xf0104d1c,(%esp)
f010012d:	e8 60 2c 00 00       	call   f0102d92 <cprintf>
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
f010032d:	e8 bf 36 00 00       	call   f01039f1 <memmove>
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
f01003d9:	0f b6 82 20 3f 10 f0 	movzbl -0xfefc0e0(%edx),%eax
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
f0100416:	0f b6 82 20 3f 10 f0 	movzbl -0xfefc0e0(%edx),%eax
f010041d:	0b 05 68 85 11 f0    	or     0xf0118568,%eax
	shift ^= togglecode[data];
f0100423:	0f b6 8a 20 40 10 f0 	movzbl -0xfefbfe0(%edx),%ecx
f010042a:	31 c8                	xor    %ecx,%eax
f010042c:	a3 68 85 11 f0       	mov    %eax,0xf0118568

	c = charcode[shift & (CTL | SHIFT)][data];
f0100431:	89 c1                	mov    %eax,%ecx
f0100433:	83 e1 03             	and    $0x3,%ecx
f0100436:	8b 0c 8d 20 41 10 f0 	mov    -0xfefbee0(,%ecx,4),%ecx
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
f010046c:	c7 04 24 ed 3e 10 f0 	movl   $0xf0103eed,(%esp)
f0100473:	e8 1a 29 00 00       	call   f0102d92 <cprintf>
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
f01005dd:	c7 04 24 f9 3e 10 f0 	movl   $0xf0103ef9,(%esp)
f01005e4:	e8 a9 27 00 00       	call   f0102d92 <cprintf>
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
f0100626:	c7 04 24 30 41 10 f0 	movl   $0xf0104130,(%esp)
f010062d:	e8 60 27 00 00       	call   f0102d92 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100632:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100639:	00 
f010063a:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100641:	f0 
f0100642:	c7 04 24 f4 41 10 f0 	movl   $0xf01041f4,(%esp)
f0100649:	e8 44 27 00 00       	call   f0102d92 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010064e:	c7 44 24 08 95 3e 10 	movl   $0x103e95,0x8(%esp)
f0100655:	00 
f0100656:	c7 44 24 04 95 3e 10 	movl   $0xf0103e95,0x4(%esp)
f010065d:	f0 
f010065e:	c7 04 24 18 42 10 f0 	movl   $0xf0104218,(%esp)
f0100665:	e8 28 27 00 00       	call   f0102d92 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010066a:	c7 44 24 08 04 83 11 	movl   $0x118304,0x8(%esp)
f0100671:	00 
f0100672:	c7 44 24 04 04 83 11 	movl   $0xf0118304,0x4(%esp)
f0100679:	f0 
f010067a:	c7 04 24 3c 42 10 f0 	movl   $0xf010423c,(%esp)
f0100681:	e8 0c 27 00 00       	call   f0102d92 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100686:	c7 44 24 08 ac 89 11 	movl   $0x1189ac,0x8(%esp)
f010068d:	00 
f010068e:	c7 44 24 04 ac 89 11 	movl   $0xf01189ac,0x4(%esp)
f0100695:	f0 
f0100696:	c7 04 24 60 42 10 f0 	movl   $0xf0104260,(%esp)
f010069d:	e8 f0 26 00 00       	call   f0102d92 <cprintf>
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
f01006be:	c7 04 24 84 42 10 f0 	movl   $0xf0104284,(%esp)
f01006c5:	e8 c8 26 00 00       	call   f0102d92 <cprintf>
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
f01006dd:	8b 83 84 43 10 f0    	mov    -0xfefbc7c(%ebx),%eax
f01006e3:	89 44 24 08          	mov    %eax,0x8(%esp)
f01006e7:	8b 83 80 43 10 f0    	mov    -0xfefbc80(%ebx),%eax
f01006ed:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006f1:	c7 04 24 49 41 10 f0 	movl   $0xf0104149,(%esp)
f01006f8:	e8 95 26 00 00       	call   f0102d92 <cprintf>
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
f0100741:	c7 04 24 52 41 10 f0 	movl   $0xf0104152,(%esp)
f0100748:	e8 45 26 00 00       	call   f0102d92 <cprintf>
	
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
f0100783:	c7 04 24 b0 42 10 f0 	movl   $0xf01042b0,(%esp)
f010078a:	e8 03 26 00 00       	call   f0102d92 <cprintf>
			struct Eipdebuginfo info;
			info.eip_file = "<unknown>";
f010078f:	c7 45 d0 64 41 10 f0 	movl   $0xf0104164,-0x30(%ebp)
			info.eip_line = 0;
f0100796:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
			info.eip_fn_name = "<unknown>";
f010079d:	c7 45 d8 64 41 10 f0 	movl   $0xf0104164,-0x28(%ebp)
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
f01007bc:	e8 cb 26 00 00       	call   f0102e8c <debuginfo_eip>
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
f0100807:	c7 04 24 6e 41 10 f0 	movl   $0xf010416e,(%esp)
f010080e:	e8 7f 25 00 00       	call   f0102d92 <cprintf>
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
f010084e:	c7 04 24 e4 42 10 f0 	movl   $0xf01042e4,(%esp)
f0100855:	e8 38 25 00 00       	call   f0102d92 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010085a:	c7 04 24 08 43 10 f0 	movl   $0xf0104308,(%esp)
f0100861:	e8 2c 25 00 00       	call   f0102d92 <cprintf>


	while (1) {
		buf = readline("K> ");
f0100866:	c7 04 24 80 41 10 f0 	movl   $0xf0104180,(%esp)
f010086d:	e8 9e 2e 00 00       	call   f0103710 <readline>
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
f010089a:	c7 04 24 84 41 10 f0 	movl   $0xf0104184,(%esp)
f01008a1:	e8 95 30 00 00       	call   f010393b <strchr>
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
f01008bc:	c7 04 24 89 41 10 f0 	movl   $0xf0104189,(%esp)
f01008c3:	e8 ca 24 00 00       	call   f0102d92 <cprintf>
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
f01008eb:	c7 04 24 84 41 10 f0 	movl   $0xf0104184,(%esp)
f01008f2:	e8 44 30 00 00       	call   f010393b <strchr>
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
f010090d:	bb 80 43 10 f0       	mov    $0xf0104380,%ebx
f0100912:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100917:	8b 03                	mov    (%ebx),%eax
f0100919:	89 44 24 04          	mov    %eax,0x4(%esp)
f010091d:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100920:	89 04 24             	mov    %eax,(%esp)
f0100923:	e8 98 2f 00 00       	call   f01038c0 <strcmp>
f0100928:	85 c0                	test   %eax,%eax
f010092a:	75 24                	jne    f0100950 <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f010092c:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f010092f:	8b 55 08             	mov    0x8(%ebp),%edx
f0100932:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100936:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100939:	89 54 24 04          	mov    %edx,0x4(%esp)
f010093d:	89 34 24             	mov    %esi,(%esp)
f0100940:	ff 14 85 88 43 10 f0 	call   *-0xfefbc78(,%eax,4)


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
f0100962:	c7 04 24 a6 41 10 f0 	movl   $0xf01041a6,(%esp)
f0100969:	e8 24 24 00 00       	call   f0102d92 <cprintf>
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
f01009ed:	c7 44 24 08 a4 43 10 	movl   $0xf01043a4,0x8(%esp)
f01009f4:	f0 
f01009f5:	c7 44 24 04 f0 02 00 	movl   $0x2f0,0x4(%esp)
f01009fc:	00 
f01009fd:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
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
f0100a40:	e8 df 22 00 00       	call   f0102d24 <mc146818_read>
f0100a45:	89 c6                	mov    %eax,%esi
f0100a47:	83 c3 01             	add    $0x1,%ebx
f0100a4a:	89 1c 24             	mov    %ebx,(%esp)
f0100a4d:	e8 d2 22 00 00       	call   f0102d24 <mc146818_read>
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
f0100a82:	c7 44 24 08 c8 43 10 	movl   $0xf01043c8,0x8(%esp)
f0100a89:	f0 
f0100a8a:	c7 44 24 04 33 02 00 	movl   $0x233,0x4(%esp)
f0100a91:	00 
f0100a92:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
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
f0100b1a:	c7 44 24 08 a4 43 10 	movl   $0xf01043a4,0x8(%esp)
f0100b21:	f0 
f0100b22:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100b29:	00 
f0100b2a:	c7 04 24 98 4a 10 f0 	movl   $0xf0104a98,(%esp)
f0100b31:	e8 5e f5 ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b36:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100b3d:	00 
f0100b3e:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100b45:	00 
	return (void *)(pa + KERNBASE);
f0100b46:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b4b:	89 04 24             	mov    %eax,(%esp)
f0100b4e:	e8 43 2e 00 00       	call   f0103996 <memset>
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
f0100bcb:	c7 44 24 0c a6 4a 10 	movl   $0xf0104aa6,0xc(%esp)
f0100bd2:	f0 
f0100bd3:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0100bda:	f0 
f0100bdb:	c7 44 24 04 4d 02 00 	movl   $0x24d,0x4(%esp)
f0100be2:	00 
f0100be3:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0100bea:	e8 a5 f4 ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0100bef:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100bf2:	72 24                	jb     f0100c18 <check_page_free_list+0x1b7>
f0100bf4:	c7 44 24 0c c7 4a 10 	movl   $0xf0104ac7,0xc(%esp)
f0100bfb:	f0 
f0100bfc:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0100c03:	f0 
f0100c04:	c7 44 24 04 4e 02 00 	movl   $0x24e,0x4(%esp)
f0100c0b:	00 
f0100c0c:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0100c13:	e8 7c f4 ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c18:	89 d0                	mov    %edx,%eax
f0100c1a:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100c1d:	a8 07                	test   $0x7,%al
f0100c1f:	74 24                	je     f0100c45 <check_page_free_list+0x1e4>
f0100c21:	c7 44 24 0c ec 43 10 	movl   $0xf01043ec,0xc(%esp)
f0100c28:	f0 
f0100c29:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0100c30:	f0 
f0100c31:	c7 44 24 04 4f 02 00 	movl   $0x24f,0x4(%esp)
f0100c38:	00 
f0100c39:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0100c40:	e8 4f f4 ff ff       	call   f0100094 <_panic>
f0100c45:	c1 f8 03             	sar    $0x3,%eax
f0100c48:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c4b:	85 c0                	test   %eax,%eax
f0100c4d:	75 24                	jne    f0100c73 <check_page_free_list+0x212>
f0100c4f:	c7 44 24 0c db 4a 10 	movl   $0xf0104adb,0xc(%esp)
f0100c56:	f0 
f0100c57:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0100c5e:	f0 
f0100c5f:	c7 44 24 04 52 02 00 	movl   $0x252,0x4(%esp)
f0100c66:	00 
f0100c67:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0100c6e:	e8 21 f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c73:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c78:	75 24                	jne    f0100c9e <check_page_free_list+0x23d>
f0100c7a:	c7 44 24 0c ec 4a 10 	movl   $0xf0104aec,0xc(%esp)
f0100c81:	f0 
f0100c82:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0100c89:	f0 
f0100c8a:	c7 44 24 04 53 02 00 	movl   $0x253,0x4(%esp)
f0100c91:	00 
f0100c92:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0100c99:	e8 f6 f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c9e:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100ca3:	75 24                	jne    f0100cc9 <check_page_free_list+0x268>
f0100ca5:	c7 44 24 0c 20 44 10 	movl   $0xf0104420,0xc(%esp)
f0100cac:	f0 
f0100cad:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0100cb4:	f0 
f0100cb5:	c7 44 24 04 54 02 00 	movl   $0x254,0x4(%esp)
f0100cbc:	00 
f0100cbd:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0100cc4:	e8 cb f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100cc9:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100cce:	75 24                	jne    f0100cf4 <check_page_free_list+0x293>
f0100cd0:	c7 44 24 0c 05 4b 10 	movl   $0xf0104b05,0xc(%esp)
f0100cd7:	f0 
f0100cd8:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0100cdf:	f0 
f0100ce0:	c7 44 24 04 55 02 00 	movl   $0x255,0x4(%esp)
f0100ce7:	00 
f0100ce8:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
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
f0100d09:	c7 44 24 08 a4 43 10 	movl   $0xf01043a4,0x8(%esp)
f0100d10:	f0 
f0100d11:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100d18:	00 
f0100d19:	c7 04 24 98 4a 10 f0 	movl   $0xf0104a98,(%esp)
f0100d20:	e8 6f f3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100d25:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f0100d2b:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0100d2e:	76 29                	jbe    f0100d59 <check_page_free_list+0x2f8>
f0100d30:	c7 44 24 0c 44 44 10 	movl   $0xf0104444,0xc(%esp)
f0100d37:	f0 
f0100d38:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0100d3f:	f0 
f0100d40:	c7 44 24 04 56 02 00 	movl   $0x256,0x4(%esp)
f0100d47:	00 
f0100d48:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
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
f0100d6a:	c7 44 24 0c 1f 4b 10 	movl   $0xf0104b1f,0xc(%esp)
f0100d71:	f0 
f0100d72:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0100d79:	f0 
f0100d7a:	c7 44 24 04 5e 02 00 	movl   $0x25e,0x4(%esp)
f0100d81:	00 
f0100d82:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0100d89:	e8 06 f3 ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f0100d8e:	85 f6                	test   %esi,%esi
f0100d90:	7f 24                	jg     f0100db6 <check_page_free_list+0x355>
f0100d92:	c7 44 24 0c 31 4b 10 	movl   $0xf0104b31,0xc(%esp)
f0100d99:	f0 
f0100d9a:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0100da1:	f0 
f0100da2:	c7 44 24 04 5f 02 00 	movl   $0x25f,0x4(%esp)
f0100da9:	00 
f0100daa:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
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
f0100df8:	c7 44 24 08 8c 44 10 	movl   $0xf010448c,0x8(%esp)
f0100dff:	f0 
f0100e00:	c7 44 24 04 15 01 00 	movl   $0x115,0x4(%esp)
f0100e07:	00 
f0100e08:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
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
f0100ea5:	77 77                	ja     f0100f1e <page_alloc+0x86>
f0100ea7:	8b 1d 80 85 11 f0    	mov    0xf0118580,%ebx
f0100ead:	85 db                	test   %ebx,%ebx
f0100eaf:	74 72                	je     f0100f23 <page_alloc+0x8b>
	{
		struct Page * temp_alloc_page = page_free_list;
		temp_alloc_page->pp_ref=1;
f0100eb1:	66 c7 43 04 01 00    	movw   $0x1,0x4(%ebx)
		if(page_free_list->pp_link!=NULL)
f0100eb7:	8b 13                	mov    (%ebx),%edx
			page_free_list=page_free_list->pp_link;
f0100eb9:	89 15 80 85 11 f0    	mov    %edx,0xf0118580
		else 
			page_free_list=NULL;
	if(alloc_flags==ALLOC_ZERO)
f0100ebf:	83 f8 01             	cmp    $0x1,%eax
f0100ec2:	75 5f                	jne    f0100f23 <page_alloc+0x8b>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ec4:	89 d8                	mov    %ebx,%eax
f0100ec6:	2b 05 a8 89 11 f0    	sub    0xf01189a8,%eax
f0100ecc:	c1 f8 03             	sar    $0x3,%eax
f0100ecf:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ed2:	89 c2                	mov    %eax,%edx
f0100ed4:	c1 ea 0c             	shr    $0xc,%edx
f0100ed7:	3b 15 a0 89 11 f0    	cmp    0xf01189a0,%edx
f0100edd:	72 20                	jb     f0100eff <page_alloc+0x67>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100edf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ee3:	c7 44 24 08 a4 43 10 	movl   $0xf01043a4,0x8(%esp)
f0100eea:	f0 
f0100eeb:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100ef2:	00 
f0100ef3:	c7 04 24 98 4a 10 f0 	movl   $0xf0104a98,(%esp)
f0100efa:	e8 95 f1 ff ff       	call   f0100094 <_panic>
		memset(page2kva(temp_alloc_page), 0, PGSIZE);
f0100eff:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100f06:	00 
f0100f07:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100f0e:	00 
	return (void *)(pa + KERNBASE);
f0100f0f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100f14:	89 04 24             	mov    %eax,(%esp)
f0100f17:	e8 7a 2a 00 00       	call   f0103996 <memset>
f0100f1c:	eb 05                	jmp    f0100f23 <page_alloc+0x8b>
		return temp_alloc_page;
	}
	else
		return NULL;
f0100f1e:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f0100f23:	89 d8                	mov    %ebx,%eax
f0100f25:	83 c4 14             	add    $0x14,%esp
f0100f28:	5b                   	pop    %ebx
f0100f29:	5d                   	pop    %ebp
f0100f2a:	c3                   	ret    

f0100f2b <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct Page *pp)
{
f0100f2b:	55                   	push   %ebp
f0100f2c:	89 e5                	mov    %esp,%ebp
f0100f2e:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	pp->pp_ref = 0;
f0100f31:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
	pp->pp_link = page_free_list;
f0100f37:	8b 15 80 85 11 f0    	mov    0xf0118580,%edx
f0100f3d:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100f3f:	a3 80 85 11 f0       	mov    %eax,0xf0118580
}
f0100f44:	5d                   	pop    %ebp
f0100f45:	c3                   	ret    

f0100f46 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct Page* pp)
{
f0100f46:	55                   	push   %ebp
f0100f47:	89 e5                	mov    %esp,%ebp
f0100f49:	83 ec 04             	sub    $0x4,%esp
f0100f4c:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100f4f:	0f b7 50 04          	movzwl 0x4(%eax),%edx
f0100f53:	83 ea 01             	sub    $0x1,%edx
f0100f56:	66 89 50 04          	mov    %dx,0x4(%eax)
f0100f5a:	66 85 d2             	test   %dx,%dx
f0100f5d:	75 08                	jne    f0100f67 <page_decref+0x21>
		page_free(pp);
f0100f5f:	89 04 24             	mov    %eax,(%esp)
f0100f62:	e8 c4 ff ff ff       	call   f0100f2b <page_free>
}
f0100f67:	c9                   	leave  
f0100f68:	c3                   	ret    

f0100f69 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100f69:	55                   	push   %ebp
f0100f6a:	89 e5                	mov    %esp,%ebp
f0100f6c:	56                   	push   %esi
f0100f6d:	53                   	push   %ebx
f0100f6e:	83 ec 10             	sub    $0x10,%esp
f0100f71:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	pde_t pde;//page directory entry,
	pte_t pte;//page table entry
	pde=pgdir[PDX(va)];//get the entry of pde
f0100f74:	89 f3                	mov    %esi,%ebx
f0100f76:	c1 eb 16             	shr    $0x16,%ebx
f0100f79:	c1 e3 02             	shl    $0x2,%ebx
f0100f7c:	03 5d 08             	add    0x8(%ebp),%ebx
f0100f7f:	8b 03                	mov    (%ebx),%eax

	if (pde & PTE_P)//the address exists
f0100f81:	a8 01                	test   $0x1,%al
f0100f83:	74 47                	je     f0100fcc <pgdir_walk+0x63>
	{
		pte=PTE_ADDR(pde)+PTX(va);
f0100f85:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100f8a:	c1 ee 0c             	shr    $0xc,%esi
f0100f8d:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
f0100f93:	01 f0                	add    %esi,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f95:	89 c2                	mov    %eax,%edx
f0100f97:	c1 ea 0c             	shr    $0xc,%edx
f0100f9a:	3b 15 a0 89 11 f0    	cmp    0xf01189a0,%edx
f0100fa0:	72 20                	jb     f0100fc2 <pgdir_walk+0x59>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fa2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100fa6:	c7 44 24 08 a4 43 10 	movl   $0xf01043a4,0x8(%esp)
f0100fad:	f0 
f0100fae:	c7 44 24 04 88 01 00 	movl   $0x188,0x4(%esp)
f0100fb5:	00 
f0100fb6:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0100fbd:	e8 d2 f0 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100fc2:	2d 00 00 00 10       	sub    $0x10000000,%eax
		return (pte_t *)KADDR(pte);
f0100fc7:	e9 da 00 00 00       	jmp    f01010a6 <pgdir_walk+0x13d>
	}
	//the page does not exist
	if (create )//create a new item 
f0100fcc:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100fd0:	0f 84 c4 00 00 00    	je     f010109a <pgdir_walk+0x131>
	{	
		struct Page *pp;
		pp=page_alloc(ALLOC_ZERO);
f0100fd6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0100fdd:	e8 b6 fe ff ff       	call   f0100e98 <page_alloc>
		if (pp!=NULL)
f0100fe2:	85 c0                	test   %eax,%eax
f0100fe4:	0f 84 b7 00 00 00    	je     f01010a1 <pgdir_walk+0x138>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100fea:	2b 05 a8 89 11 f0    	sub    0xf01189a8,%eax
f0100ff0:	c1 f8 03             	sar    $0x3,%eax
f0100ff3:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ff6:	89 c2                	mov    %eax,%edx
f0100ff8:	c1 ea 0c             	shr    $0xc,%edx
f0100ffb:	3b 15 a0 89 11 f0    	cmp    0xf01189a0,%edx
f0101001:	72 20                	jb     f0101023 <pgdir_walk+0xba>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101003:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101007:	c7 44 24 08 a4 43 10 	movl   $0xf01043a4,0x8(%esp)
f010100e:	f0 
f010100f:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101016:	00 
f0101017:	c7 04 24 98 4a 10 f0 	movl   $0xf0104a98,(%esp)
f010101e:	e8 71 f0 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101023:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101029:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f010102f:	77 20                	ja     f0101051 <pgdir_walk+0xe8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101031:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101035:	c7 44 24 08 8c 44 10 	movl   $0xf010448c,0x8(%esp)
f010103c:	f0 
f010103d:	c7 44 24 04 91 01 00 	movl   $0x191,0x4(%esp)
f0101044:	00 
f0101045:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f010104c:	e8 43 f0 ff ff       	call   f0100094 <_panic>
		{	
			pde = PADDR(page2kva(pp))|PTE_U|PTE_W |PTE_P ;
f0101051:	83 c8 07             	or     $0x7,%eax
			pgdir[PDX(va)] = pde;
f0101054:	89 03                	mov    %eax,(%ebx)
			pte=PTE_ADDR(pde)+PTX(va);
f0101056:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010105b:	c1 ee 0c             	shr    $0xc,%esi
f010105e:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
f0101064:	01 f0                	add    %esi,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101066:	89 c2                	mov    %eax,%edx
f0101068:	c1 ea 0c             	shr    $0xc,%edx
f010106b:	3b 15 a0 89 11 f0    	cmp    0xf01189a0,%edx
f0101071:	72 20                	jb     f0101093 <pgdir_walk+0x12a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101073:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101077:	c7 44 24 08 a4 43 10 	movl   $0xf01043a4,0x8(%esp)
f010107e:	f0 
f010107f:	c7 44 24 04 94 01 00 	movl   $0x194,0x4(%esp)
f0101086:	00 
f0101087:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f010108e:	e8 01 f0 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101093:	2d 00 00 00 10       	sub    $0x10000000,%eax
			return (pte_t *)KADDR(pte);
f0101098:	eb 0c                	jmp    f01010a6 <pgdir_walk+0x13d>
		}
	}
	
	
	
	return NULL;
f010109a:	b8 00 00 00 00       	mov    $0x0,%eax
f010109f:	eb 05                	jmp    f01010a6 <pgdir_walk+0x13d>
f01010a1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01010a6:	83 c4 10             	add    $0x10,%esp
f01010a9:	5b                   	pop    %ebx
f01010aa:	5e                   	pop    %esi
f01010ab:	5d                   	pop    %ebp
f01010ac:	c3                   	ret    

f01010ad <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f01010ad:	55                   	push   %ebp
f01010ae:	89 e5                	mov    %esp,%ebp
f01010b0:	57                   	push   %edi
f01010b1:	56                   	push   %esi
f01010b2:	53                   	push   %ebx
f01010b3:	83 ec 2c             	sub    $0x2c,%esp
f01010b6:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01010b9:	89 d3                	mov    %edx,%ebx
f01010bb:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01010be:	8b 7d 08             	mov    0x8(%ebp),%edi
	// Fill this function in
	pte_t *pte ;
	size_t i;
	for(i=0;i<size;i++)
f01010c1:	85 c9                	test   %ecx,%ecx
f01010c3:	74 40                	je     f0101105 <boot_map_region+0x58>
f01010c5:	be 00 00 00 00       	mov    $0x0,%esi
	{
		pte=pgdir_walk(pgdir, (void *)va, 1);
		*pte= pa|perm|PTE_P;
f01010ca:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010cd:	83 c8 01             	or     $0x1,%eax
f01010d0:	89 45 dc             	mov    %eax,-0x24(%ebp)
	// Fill this function in
	pte_t *pte ;
	size_t i;
	for(i=0;i<size;i++)
	{
		pte=pgdir_walk(pgdir, (void *)va, 1);
f01010d3:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01010da:	00 
f01010db:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010df:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01010e2:	89 04 24             	mov    %eax,(%esp)
f01010e5:	e8 7f fe ff ff       	call   f0100f69 <pgdir_walk>
		*pte= pa|perm|PTE_P;
f01010ea:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01010ed:	09 fa                	or     %edi,%edx
f01010ef:	89 10                	mov    %edx,(%eax)
		pa+=PGSIZE;
f01010f1:	81 c7 00 10 00 00    	add    $0x1000,%edi
		va+=PGSIZE;
f01010f7:	81 c3 00 10 00 00    	add    $0x1000,%ebx
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	pte_t *pte ;
	size_t i;
	for(i=0;i<size;i++)
f01010fd:	83 c6 01             	add    $0x1,%esi
f0101100:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0101103:	75 ce                	jne    f01010d3 <boot_map_region+0x26>
		pte=pgdir_walk(pgdir, (void *)va, 1);
		*pte= pa|perm|PTE_P;
		pa+=PGSIZE;
		va+=PGSIZE;
	}
}
f0101105:	83 c4 2c             	add    $0x2c,%esp
f0101108:	5b                   	pop    %ebx
f0101109:	5e                   	pop    %esi
f010110a:	5f                   	pop    %edi
f010110b:	5d                   	pop    %ebp
f010110c:	c3                   	ret    

f010110d <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f010110d:	55                   	push   %ebp
f010110e:	89 e5                	mov    %esp,%ebp
f0101110:	53                   	push   %ebx
f0101111:	83 ec 14             	sub    $0x14,%esp
f0101114:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pte = pgdir_walk (pgdir, va, 0);
f0101117:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010111e:	00 
f010111f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101122:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101126:	8b 45 08             	mov    0x8(%ebp),%eax
f0101129:	89 04 24             	mov    %eax,(%esp)
f010112c:	e8 38 fe ff ff       	call   f0100f69 <pgdir_walk>
	if (pte_store != 0) {
f0101131:	85 db                	test   %ebx,%ebx
f0101133:	74 02                	je     f0101137 <page_lookup+0x2a>
		*pte_store = pte;
f0101135:	89 03                	mov    %eax,(%ebx)
		}
	if (pte != NULL && (*pte & PTE_P)) {
f0101137:	85 c0                	test   %eax,%eax
f0101139:	74 38                	je     f0101173 <page_lookup+0x66>
f010113b:	8b 00                	mov    (%eax),%eax
f010113d:	a8 01                	test   $0x1,%al
f010113f:	74 39                	je     f010117a <page_lookup+0x6d>
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101141:	c1 e8 0c             	shr    $0xc,%eax
f0101144:	3b 05 a0 89 11 f0    	cmp    0xf01189a0,%eax
f010114a:	72 1c                	jb     f0101168 <page_lookup+0x5b>
		panic("pa2page called with invalid pa");
f010114c:	c7 44 24 08 b0 44 10 	movl   $0xf01044b0,0x8(%esp)
f0101153:	f0 
f0101154:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f010115b:	00 
f010115c:	c7 04 24 98 4a 10 f0 	movl   $0xf0104a98,(%esp)
f0101163:	e8 2c ef ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f0101168:	c1 e0 03             	shl    $0x3,%eax
f010116b:	03 05 a8 89 11 f0    	add    0xf01189a8,%eax
		return pa2page (PTE_ADDR (*pte));
f0101171:	eb 0c                	jmp    f010117f <page_lookup+0x72>
	}
	return NULL;
f0101173:	b8 00 00 00 00       	mov    $0x0,%eax
f0101178:	eb 05                	jmp    f010117f <page_lookup+0x72>
f010117a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010117f:	83 c4 14             	add    $0x14,%esp
f0101182:	5b                   	pop    %ebx
f0101183:	5d                   	pop    %ebp
f0101184:	c3                   	ret    

f0101185 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0101185:	55                   	push   %ebp
f0101186:	89 e5                	mov    %esp,%ebp
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101188:	8b 45 0c             	mov    0xc(%ebp),%eax
f010118b:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f010118e:	5d                   	pop    %ebp
f010118f:	c3                   	ret    

f0101190 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101190:	55                   	push   %ebp
f0101191:	89 e5                	mov    %esp,%ebp
f0101193:	83 ec 28             	sub    $0x28,%esp
f0101196:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0101199:	89 75 fc             	mov    %esi,-0x4(%ebp)
f010119c:	8b 75 08             	mov    0x8(%ebp),%esi
f010119f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *pte;
	struct Page *physpage = page_lookup (pgdir, va, &pte);
f01011a2:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01011a5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01011a9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011ad:	89 34 24             	mov    %esi,(%esp)
f01011b0:	e8 58 ff ff ff       	call   f010110d <page_lookup>
	if (physpage != NULL) {
f01011b5:	85 c0                	test   %eax,%eax
f01011b7:	74 1d                	je     f01011d6 <page_remove+0x46>
		page_decref (physpage);
f01011b9:	89 04 24             	mov    %eax,(%esp)
f01011bc:	e8 85 fd ff ff       	call   f0100f46 <page_decref>
		*pte = 0;
f01011c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011c4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		tlb_invalidate (pgdir, va);
f01011ca:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011ce:	89 34 24             	mov    %esi,(%esp)
f01011d1:	e8 af ff ff ff       	call   f0101185 <tlb_invalidate>
}
}
f01011d6:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f01011d9:	8b 75 fc             	mov    -0x4(%ebp),%esi
f01011dc:	89 ec                	mov    %ebp,%esp
f01011de:	5d                   	pop    %ebp
f01011df:	c3                   	ret    

f01011e0 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{
f01011e0:	55                   	push   %ebp
f01011e1:	89 e5                	mov    %esp,%ebp
f01011e3:	83 ec 28             	sub    $0x28,%esp
f01011e6:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f01011e9:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01011ec:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01011ef:	8b 75 0c             	mov    0xc(%ebp),%esi
f01011f2:	8b 7d 10             	mov    0x10(%ebp),%edi

	pte_t * pte = pgdir_walk(pgdir, va, 1) ;
f01011f5:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01011fc:	00 
f01011fd:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101201:	8b 45 08             	mov    0x8(%ebp),%eax
f0101204:	89 04 24             	mov    %eax,(%esp)
f0101207:	e8 5d fd ff ff       	call   f0100f69 <pgdir_walk>
f010120c:	89 c3                	mov    %eax,%ebx
	if (!pte)
f010120e:	85 c0                	test   %eax,%eax
f0101210:	74 63                	je     f0101275 <page_insert+0x95>
		return -E_NO_MEM;
	if (*pte & PTE_P) {
f0101212:	8b 00                	mov    (%eax),%eax
f0101214:	a8 01                	test   $0x1,%al
f0101216:	74 3c                	je     f0101254 <page_insert+0x74>
		if (PTE_ADDR(*pte) == page2pa (pp)) {
f0101218:	25 00 f0 ff ff       	and    $0xfffff000,%eax
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f010121d:	89 f2                	mov    %esi,%edx
f010121f:	2b 15 a8 89 11 f0    	sub    0xf01189a8,%edx
f0101225:	c1 fa 03             	sar    $0x3,%edx
f0101228:	c1 e2 0c             	shl    $0xc,%edx
f010122b:	39 d0                	cmp    %edx,%eax
f010122d:	75 16                	jne    f0101245 <page_insert+0x65>
			tlb_invalidate (pgdir, va);
f010122f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101233:	8b 45 08             	mov    0x8(%ebp),%eax
f0101236:	89 04 24             	mov    %eax,(%esp)
f0101239:	e8 47 ff ff ff       	call   f0101185 <tlb_invalidate>
			pp -> pp_ref --;
f010123e:	66 83 6e 04 01       	subw   $0x1,0x4(%esi)
f0101243:	eb 0f                	jmp    f0101254 <page_insert+0x74>
			} else {
		page_remove (pgdir, va);
f0101245:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101249:	8b 45 08             	mov    0x8(%ebp),%eax
f010124c:	89 04 24             	mov    %eax,(%esp)
f010124f:	e8 3c ff ff ff       	call   f0101190 <page_remove>
		}
	}

	*pte = page2pa (pp)|perm|PTE_P;
f0101254:	8b 55 14             	mov    0x14(%ebp),%edx
f0101257:	83 ca 01             	or     $0x1,%edx
f010125a:	2b 35 a8 89 11 f0    	sub    0xf01189a8,%esi
f0101260:	c1 fe 03             	sar    $0x3,%esi
f0101263:	89 f0                	mov    %esi,%eax
f0101265:	c1 e0 0c             	shl    $0xc,%eax
f0101268:	89 d6                	mov    %edx,%esi
f010126a:	09 c6                	or     %eax,%esi
f010126c:	89 33                	mov    %esi,(%ebx)

	return 0;
f010126e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101273:	eb 05                	jmp    f010127a <page_insert+0x9a>
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{

	pte_t * pte = pgdir_walk(pgdir, va, 1) ;
	if (!pte)
		return -E_NO_MEM;
f0101275:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	}

	*pte = page2pa (pp)|perm|PTE_P;

	return 0;
}
f010127a:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f010127d:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0101280:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101283:	89 ec                	mov    %ebp,%esp
f0101285:	5d                   	pop    %ebp
f0101286:	c3                   	ret    

f0101287 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101287:	55                   	push   %ebp
f0101288:	89 e5                	mov    %esp,%ebp
f010128a:	57                   	push   %edi
f010128b:	56                   	push   %esi
f010128c:	53                   	push   %ebx
f010128d:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101290:	b8 15 00 00 00       	mov    $0x15,%eax
f0101295:	e8 95 f7 ff ff       	call   f0100a2f <nvram_read>
f010129a:	c1 e0 0a             	shl    $0xa,%eax
f010129d:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01012a3:	85 c0                	test   %eax,%eax
f01012a5:	0f 48 c2             	cmovs  %edx,%eax
f01012a8:	c1 f8 0c             	sar    $0xc,%eax
f01012ab:	a3 78 85 11 f0       	mov    %eax,0xf0118578
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01012b0:	b8 17 00 00 00       	mov    $0x17,%eax
f01012b5:	e8 75 f7 ff ff       	call   f0100a2f <nvram_read>
f01012ba:	c1 e0 0a             	shl    $0xa,%eax
f01012bd:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01012c3:	85 c0                	test   %eax,%eax
f01012c5:	0f 48 c2             	cmovs  %edx,%eax
f01012c8:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01012cb:	85 c0                	test   %eax,%eax
f01012cd:	74 0e                	je     f01012dd <mem_init+0x56>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01012cf:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f01012d5:	89 15 a0 89 11 f0    	mov    %edx,0xf01189a0
f01012db:	eb 0c                	jmp    f01012e9 <mem_init+0x62>
	else
		npages = npages_basemem;
f01012dd:	8b 15 78 85 11 f0    	mov    0xf0118578,%edx
f01012e3:	89 15 a0 89 11 f0    	mov    %edx,0xf01189a0

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f01012e9:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012ec:	c1 e8 0a             	shr    $0xa,%eax
f01012ef:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f01012f3:	a1 78 85 11 f0       	mov    0xf0118578,%eax
f01012f8:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012fb:	c1 e8 0a             	shr    $0xa,%eax
f01012fe:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f0101302:	a1 a0 89 11 f0       	mov    0xf01189a0,%eax
f0101307:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010130a:	c1 e8 0a             	shr    $0xa,%eax
f010130d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101311:	c7 04 24 d0 44 10 f0 	movl   $0xf01044d0,(%esp)
f0101318:	e8 75 1a 00 00       	call   f0102d92 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010131d:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101322:	e8 5d f6 ff ff       	call   f0100984 <boot_alloc>
f0101327:	a3 a4 89 11 f0       	mov    %eax,0xf01189a4
	memset(kern_pgdir, 0, PGSIZE);
f010132c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101333:	00 
f0101334:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010133b:	00 
f010133c:	89 04 24             	mov    %eax,(%esp)
f010133f:	e8 52 26 00 00       	call   f0103996 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following two lines.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101344:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101349:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010134e:	77 20                	ja     f0101370 <mem_init+0xe9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101350:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101354:	c7 44 24 08 8c 44 10 	movl   $0xf010448c,0x8(%esp)
f010135b:	f0 
f010135c:	c7 44 24 04 8b 00 00 	movl   $0x8b,0x4(%esp)
f0101363:	00 
f0101364:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f010136b:	e8 24 ed ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101370:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101376:	83 ca 05             	or     $0x5,%edx
f0101379:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct Page in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:

	pages =(struct Page *) boot_alloc(npages* sizeof (struct Page));
f010137f:	a1 a0 89 11 f0       	mov    0xf01189a0,%eax
f0101384:	c1 e0 03             	shl    $0x3,%eax
f0101387:	e8 f8 f5 ff ff       	call   f0100984 <boot_alloc>
f010138c:	a3 a8 89 11 f0       	mov    %eax,0xf01189a8
	memset(pages, 0, npages* sizeof (struct Page));
f0101391:	8b 15 a0 89 11 f0    	mov    0xf01189a0,%edx
f0101397:	c1 e2 03             	shl    $0x3,%edx
f010139a:	89 54 24 08          	mov    %edx,0x8(%esp)
f010139e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01013a5:	00 
f01013a6:	89 04 24             	mov    %eax,(%esp)
f01013a9:	e8 e8 25 00 00       	call   f0103996 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01013ae:	e8 0b fa ff ff       	call   f0100dbe <page_init>
	check_page_free_list(1);
f01013b3:	b8 01 00 00 00       	mov    $0x1,%eax
f01013b8:	e8 a4 f6 ff ff       	call   f0100a61 <check_page_free_list>
	int nfree;
	struct Page *fl;
	char *c;
	int i;

	if (!pages)
f01013bd:	83 3d a8 89 11 f0 00 	cmpl   $0x0,0xf01189a8
f01013c4:	75 1c                	jne    f01013e2 <mem_init+0x15b>
		panic("'pages' is a null pointer!");
f01013c6:	c7 44 24 08 42 4b 10 	movl   $0xf0104b42,0x8(%esp)
f01013cd:	f0 
f01013ce:	c7 44 24 04 70 02 00 	movl   $0x270,0x4(%esp)
f01013d5:	00 
f01013d6:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f01013dd:	e8 b2 ec ff ff       	call   f0100094 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013e2:	a1 80 85 11 f0       	mov    0xf0118580,%eax
f01013e7:	bb 00 00 00 00       	mov    $0x0,%ebx
f01013ec:	85 c0                	test   %eax,%eax
f01013ee:	74 09                	je     f01013f9 <mem_init+0x172>
		++nfree;
f01013f0:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013f3:	8b 00                	mov    (%eax),%eax
f01013f5:	85 c0                	test   %eax,%eax
f01013f7:	75 f7                	jne    f01013f0 <mem_init+0x169>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01013f9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101400:	e8 93 fa ff ff       	call   f0100e98 <page_alloc>
f0101405:	89 c6                	mov    %eax,%esi
f0101407:	85 c0                	test   %eax,%eax
f0101409:	75 24                	jne    f010142f <mem_init+0x1a8>
f010140b:	c7 44 24 0c 5d 4b 10 	movl   $0xf0104b5d,0xc(%esp)
f0101412:	f0 
f0101413:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f010141a:	f0 
f010141b:	c7 44 24 04 78 02 00 	movl   $0x278,0x4(%esp)
f0101422:	00 
f0101423:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f010142a:	e8 65 ec ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f010142f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101436:	e8 5d fa ff ff       	call   f0100e98 <page_alloc>
f010143b:	89 c7                	mov    %eax,%edi
f010143d:	85 c0                	test   %eax,%eax
f010143f:	75 24                	jne    f0101465 <mem_init+0x1de>
f0101441:	c7 44 24 0c 73 4b 10 	movl   $0xf0104b73,0xc(%esp)
f0101448:	f0 
f0101449:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0101450:	f0 
f0101451:	c7 44 24 04 79 02 00 	movl   $0x279,0x4(%esp)
f0101458:	00 
f0101459:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0101460:	e8 2f ec ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101465:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010146c:	e8 27 fa ff ff       	call   f0100e98 <page_alloc>
f0101471:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101474:	85 c0                	test   %eax,%eax
f0101476:	75 24                	jne    f010149c <mem_init+0x215>
f0101478:	c7 44 24 0c 89 4b 10 	movl   $0xf0104b89,0xc(%esp)
f010147f:	f0 
f0101480:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0101487:	f0 
f0101488:	c7 44 24 04 7a 02 00 	movl   $0x27a,0x4(%esp)
f010148f:	00 
f0101490:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0101497:	e8 f8 eb ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010149c:	39 fe                	cmp    %edi,%esi
f010149e:	75 24                	jne    f01014c4 <mem_init+0x23d>
f01014a0:	c7 44 24 0c 9f 4b 10 	movl   $0xf0104b9f,0xc(%esp)
f01014a7:	f0 
f01014a8:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f01014af:	f0 
f01014b0:	c7 44 24 04 7d 02 00 	movl   $0x27d,0x4(%esp)
f01014b7:	00 
f01014b8:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f01014bf:	e8 d0 eb ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014c4:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f01014c7:	74 05                	je     f01014ce <mem_init+0x247>
f01014c9:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f01014cc:	75 24                	jne    f01014f2 <mem_init+0x26b>
f01014ce:	c7 44 24 0c 0c 45 10 	movl   $0xf010450c,0xc(%esp)
f01014d5:	f0 
f01014d6:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f01014dd:	f0 
f01014de:	c7 44 24 04 7e 02 00 	movl   $0x27e,0x4(%esp)
f01014e5:	00 
f01014e6:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f01014ed:	e8 a2 eb ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01014f2:	8b 15 a8 89 11 f0    	mov    0xf01189a8,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f01014f8:	a1 a0 89 11 f0       	mov    0xf01189a0,%eax
f01014fd:	c1 e0 0c             	shl    $0xc,%eax
f0101500:	89 f1                	mov    %esi,%ecx
f0101502:	29 d1                	sub    %edx,%ecx
f0101504:	c1 f9 03             	sar    $0x3,%ecx
f0101507:	c1 e1 0c             	shl    $0xc,%ecx
f010150a:	39 c1                	cmp    %eax,%ecx
f010150c:	72 24                	jb     f0101532 <mem_init+0x2ab>
f010150e:	c7 44 24 0c b1 4b 10 	movl   $0xf0104bb1,0xc(%esp)
f0101515:	f0 
f0101516:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f010151d:	f0 
f010151e:	c7 44 24 04 7f 02 00 	movl   $0x27f,0x4(%esp)
f0101525:	00 
f0101526:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f010152d:	e8 62 eb ff ff       	call   f0100094 <_panic>
f0101532:	89 f9                	mov    %edi,%ecx
f0101534:	29 d1                	sub    %edx,%ecx
f0101536:	c1 f9 03             	sar    $0x3,%ecx
f0101539:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f010153c:	39 c8                	cmp    %ecx,%eax
f010153e:	77 24                	ja     f0101564 <mem_init+0x2dd>
f0101540:	c7 44 24 0c ce 4b 10 	movl   $0xf0104bce,0xc(%esp)
f0101547:	f0 
f0101548:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f010154f:	f0 
f0101550:	c7 44 24 04 80 02 00 	movl   $0x280,0x4(%esp)
f0101557:	00 
f0101558:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f010155f:	e8 30 eb ff ff       	call   f0100094 <_panic>
f0101564:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101567:	29 d1                	sub    %edx,%ecx
f0101569:	89 ca                	mov    %ecx,%edx
f010156b:	c1 fa 03             	sar    $0x3,%edx
f010156e:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f0101571:	39 d0                	cmp    %edx,%eax
f0101573:	77 24                	ja     f0101599 <mem_init+0x312>
f0101575:	c7 44 24 0c eb 4b 10 	movl   $0xf0104beb,0xc(%esp)
f010157c:	f0 
f010157d:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0101584:	f0 
f0101585:	c7 44 24 04 81 02 00 	movl   $0x281,0x4(%esp)
f010158c:	00 
f010158d:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0101594:	e8 fb ea ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101599:	a1 80 85 11 f0       	mov    0xf0118580,%eax
f010159e:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01015a1:	c7 05 80 85 11 f0 00 	movl   $0x0,0xf0118580
f01015a8:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01015ab:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015b2:	e8 e1 f8 ff ff       	call   f0100e98 <page_alloc>
f01015b7:	85 c0                	test   %eax,%eax
f01015b9:	74 24                	je     f01015df <mem_init+0x358>
f01015bb:	c7 44 24 0c 08 4c 10 	movl   $0xf0104c08,0xc(%esp)
f01015c2:	f0 
f01015c3:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f01015ca:	f0 
f01015cb:	c7 44 24 04 88 02 00 	movl   $0x288,0x4(%esp)
f01015d2:	00 
f01015d3:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f01015da:	e8 b5 ea ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01015df:	89 34 24             	mov    %esi,(%esp)
f01015e2:	e8 44 f9 ff ff       	call   f0100f2b <page_free>
	page_free(pp1);
f01015e7:	89 3c 24             	mov    %edi,(%esp)
f01015ea:	e8 3c f9 ff ff       	call   f0100f2b <page_free>
	page_free(pp2);
f01015ef:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015f2:	89 04 24             	mov    %eax,(%esp)
f01015f5:	e8 31 f9 ff ff       	call   f0100f2b <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015fa:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101601:	e8 92 f8 ff ff       	call   f0100e98 <page_alloc>
f0101606:	89 c6                	mov    %eax,%esi
f0101608:	85 c0                	test   %eax,%eax
f010160a:	75 24                	jne    f0101630 <mem_init+0x3a9>
f010160c:	c7 44 24 0c 5d 4b 10 	movl   $0xf0104b5d,0xc(%esp)
f0101613:	f0 
f0101614:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f010161b:	f0 
f010161c:	c7 44 24 04 8f 02 00 	movl   $0x28f,0x4(%esp)
f0101623:	00 
f0101624:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f010162b:	e8 64 ea ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101630:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101637:	e8 5c f8 ff ff       	call   f0100e98 <page_alloc>
f010163c:	89 c7                	mov    %eax,%edi
f010163e:	85 c0                	test   %eax,%eax
f0101640:	75 24                	jne    f0101666 <mem_init+0x3df>
f0101642:	c7 44 24 0c 73 4b 10 	movl   $0xf0104b73,0xc(%esp)
f0101649:	f0 
f010164a:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0101651:	f0 
f0101652:	c7 44 24 04 90 02 00 	movl   $0x290,0x4(%esp)
f0101659:	00 
f010165a:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0101661:	e8 2e ea ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101666:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010166d:	e8 26 f8 ff ff       	call   f0100e98 <page_alloc>
f0101672:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101675:	85 c0                	test   %eax,%eax
f0101677:	75 24                	jne    f010169d <mem_init+0x416>
f0101679:	c7 44 24 0c 89 4b 10 	movl   $0xf0104b89,0xc(%esp)
f0101680:	f0 
f0101681:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0101688:	f0 
f0101689:	c7 44 24 04 91 02 00 	movl   $0x291,0x4(%esp)
f0101690:	00 
f0101691:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0101698:	e8 f7 e9 ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010169d:	39 fe                	cmp    %edi,%esi
f010169f:	75 24                	jne    f01016c5 <mem_init+0x43e>
f01016a1:	c7 44 24 0c 9f 4b 10 	movl   $0xf0104b9f,0xc(%esp)
f01016a8:	f0 
f01016a9:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f01016b0:	f0 
f01016b1:	c7 44 24 04 93 02 00 	movl   $0x293,0x4(%esp)
f01016b8:	00 
f01016b9:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f01016c0:	e8 cf e9 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01016c5:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f01016c8:	74 05                	je     f01016cf <mem_init+0x448>
f01016ca:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f01016cd:	75 24                	jne    f01016f3 <mem_init+0x46c>
f01016cf:	c7 44 24 0c 0c 45 10 	movl   $0xf010450c,0xc(%esp)
f01016d6:	f0 
f01016d7:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f01016de:	f0 
f01016df:	c7 44 24 04 94 02 00 	movl   $0x294,0x4(%esp)
f01016e6:	00 
f01016e7:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f01016ee:	e8 a1 e9 ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f01016f3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016fa:	e8 99 f7 ff ff       	call   f0100e98 <page_alloc>
f01016ff:	85 c0                	test   %eax,%eax
f0101701:	74 24                	je     f0101727 <mem_init+0x4a0>
f0101703:	c7 44 24 0c 08 4c 10 	movl   $0xf0104c08,0xc(%esp)
f010170a:	f0 
f010170b:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0101712:	f0 
f0101713:	c7 44 24 04 95 02 00 	movl   $0x295,0x4(%esp)
f010171a:	00 
f010171b:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0101722:	e8 6d e9 ff ff       	call   f0100094 <_panic>
f0101727:	89 f0                	mov    %esi,%eax
f0101729:	2b 05 a8 89 11 f0    	sub    0xf01189a8,%eax
f010172f:	c1 f8 03             	sar    $0x3,%eax
f0101732:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101735:	89 c2                	mov    %eax,%edx
f0101737:	c1 ea 0c             	shr    $0xc,%edx
f010173a:	3b 15 a0 89 11 f0    	cmp    0xf01189a0,%edx
f0101740:	72 20                	jb     f0101762 <mem_init+0x4db>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101742:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101746:	c7 44 24 08 a4 43 10 	movl   $0xf01043a4,0x8(%esp)
f010174d:	f0 
f010174e:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101755:	00 
f0101756:	c7 04 24 98 4a 10 f0 	movl   $0xf0104a98,(%esp)
f010175d:	e8 32 e9 ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101762:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101769:	00 
f010176a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101771:	00 
	return (void *)(pa + KERNBASE);
f0101772:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101777:	89 04 24             	mov    %eax,(%esp)
f010177a:	e8 17 22 00 00       	call   f0103996 <memset>
	page_free(pp0);
f010177f:	89 34 24             	mov    %esi,(%esp)
f0101782:	e8 a4 f7 ff ff       	call   f0100f2b <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101787:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010178e:	e8 05 f7 ff ff       	call   f0100e98 <page_alloc>
f0101793:	85 c0                	test   %eax,%eax
f0101795:	75 24                	jne    f01017bb <mem_init+0x534>
f0101797:	c7 44 24 0c 17 4c 10 	movl   $0xf0104c17,0xc(%esp)
f010179e:	f0 
f010179f:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f01017a6:	f0 
f01017a7:	c7 44 24 04 9a 02 00 	movl   $0x29a,0x4(%esp)
f01017ae:	00 
f01017af:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f01017b6:	e8 d9 e8 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f01017bb:	39 c6                	cmp    %eax,%esi
f01017bd:	74 24                	je     f01017e3 <mem_init+0x55c>
f01017bf:	c7 44 24 0c 35 4c 10 	movl   $0xf0104c35,0xc(%esp)
f01017c6:	f0 
f01017c7:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f01017ce:	f0 
f01017cf:	c7 44 24 04 9b 02 00 	movl   $0x29b,0x4(%esp)
f01017d6:	00 
f01017d7:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f01017de:	e8 b1 e8 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01017e3:	89 f2                	mov    %esi,%edx
f01017e5:	2b 15 a8 89 11 f0    	sub    0xf01189a8,%edx
f01017eb:	c1 fa 03             	sar    $0x3,%edx
f01017ee:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01017f1:	89 d0                	mov    %edx,%eax
f01017f3:	c1 e8 0c             	shr    $0xc,%eax
f01017f6:	3b 05 a0 89 11 f0    	cmp    0xf01189a0,%eax
f01017fc:	72 20                	jb     f010181e <mem_init+0x597>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01017fe:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101802:	c7 44 24 08 a4 43 10 	movl   $0xf01043a4,0x8(%esp)
f0101809:	f0 
f010180a:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101811:	00 
f0101812:	c7 04 24 98 4a 10 f0 	movl   $0xf0104a98,(%esp)
f0101819:	e8 76 e8 ff ff       	call   f0100094 <_panic>
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010181e:	80 ba 00 00 00 f0 00 	cmpb   $0x0,-0x10000000(%edx)
f0101825:	75 11                	jne    f0101838 <mem_init+0x5b1>
f0101827:	8d 82 01 00 00 f0    	lea    -0xfffffff(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010182d:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101833:	80 38 00             	cmpb   $0x0,(%eax)
f0101836:	74 24                	je     f010185c <mem_init+0x5d5>
f0101838:	c7 44 24 0c 45 4c 10 	movl   $0xf0104c45,0xc(%esp)
f010183f:	f0 
f0101840:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0101847:	f0 
f0101848:	c7 44 24 04 9e 02 00 	movl   $0x29e,0x4(%esp)
f010184f:	00 
f0101850:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0101857:	e8 38 e8 ff ff       	call   f0100094 <_panic>
f010185c:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010185f:	39 d0                	cmp    %edx,%eax
f0101861:	75 d0                	jne    f0101833 <mem_init+0x5ac>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101863:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101866:	89 15 80 85 11 f0    	mov    %edx,0xf0118580

	// free the pages we took
	page_free(pp0);
f010186c:	89 34 24             	mov    %esi,(%esp)
f010186f:	e8 b7 f6 ff ff       	call   f0100f2b <page_free>
	page_free(pp1);
f0101874:	89 3c 24             	mov    %edi,(%esp)
f0101877:	e8 af f6 ff ff       	call   f0100f2b <page_free>
	page_free(pp2);
f010187c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010187f:	89 04 24             	mov    %eax,(%esp)
f0101882:	e8 a4 f6 ff ff       	call   f0100f2b <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101887:	a1 80 85 11 f0       	mov    0xf0118580,%eax
f010188c:	85 c0                	test   %eax,%eax
f010188e:	74 09                	je     f0101899 <mem_init+0x612>
		--nfree;
f0101890:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101893:	8b 00                	mov    (%eax),%eax
f0101895:	85 c0                	test   %eax,%eax
f0101897:	75 f7                	jne    f0101890 <mem_init+0x609>
		--nfree;
	assert(nfree == 0);
f0101899:	85 db                	test   %ebx,%ebx
f010189b:	74 24                	je     f01018c1 <mem_init+0x63a>
f010189d:	c7 44 24 0c 4f 4c 10 	movl   $0xf0104c4f,0xc(%esp)
f01018a4:	f0 
f01018a5:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f01018ac:	f0 
f01018ad:	c7 44 24 04 ab 02 00 	movl   $0x2ab,0x4(%esp)
f01018b4:	00 
f01018b5:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f01018bc:	e8 d3 e7 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01018c1:	c7 04 24 2c 45 10 f0 	movl   $0xf010452c,(%esp)
f01018c8:	e8 c5 14 00 00       	call   f0102d92 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01018cd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018d4:	e8 bf f5 ff ff       	call   f0100e98 <page_alloc>
f01018d9:	89 c3                	mov    %eax,%ebx
f01018db:	85 c0                	test   %eax,%eax
f01018dd:	75 24                	jne    f0101903 <mem_init+0x67c>
f01018df:	c7 44 24 0c 5d 4b 10 	movl   $0xf0104b5d,0xc(%esp)
f01018e6:	f0 
f01018e7:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f01018ee:	f0 
f01018ef:	c7 44 24 04 04 03 00 	movl   $0x304,0x4(%esp)
f01018f6:	00 
f01018f7:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f01018fe:	e8 91 e7 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101903:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010190a:	e8 89 f5 ff ff       	call   f0100e98 <page_alloc>
f010190f:	89 c7                	mov    %eax,%edi
f0101911:	85 c0                	test   %eax,%eax
f0101913:	75 24                	jne    f0101939 <mem_init+0x6b2>
f0101915:	c7 44 24 0c 73 4b 10 	movl   $0xf0104b73,0xc(%esp)
f010191c:	f0 
f010191d:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0101924:	f0 
f0101925:	c7 44 24 04 05 03 00 	movl   $0x305,0x4(%esp)
f010192c:	00 
f010192d:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0101934:	e8 5b e7 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101939:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101940:	e8 53 f5 ff ff       	call   f0100e98 <page_alloc>
f0101945:	89 c6                	mov    %eax,%esi
f0101947:	85 c0                	test   %eax,%eax
f0101949:	75 24                	jne    f010196f <mem_init+0x6e8>
f010194b:	c7 44 24 0c 89 4b 10 	movl   $0xf0104b89,0xc(%esp)
f0101952:	f0 
f0101953:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f010195a:	f0 
f010195b:	c7 44 24 04 06 03 00 	movl   $0x306,0x4(%esp)
f0101962:	00 
f0101963:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f010196a:	e8 25 e7 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010196f:	39 fb                	cmp    %edi,%ebx
f0101971:	75 24                	jne    f0101997 <mem_init+0x710>
f0101973:	c7 44 24 0c 9f 4b 10 	movl   $0xf0104b9f,0xc(%esp)
f010197a:	f0 
f010197b:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0101982:	f0 
f0101983:	c7 44 24 04 09 03 00 	movl   $0x309,0x4(%esp)
f010198a:	00 
f010198b:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0101992:	e8 fd e6 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101997:	39 c7                	cmp    %eax,%edi
f0101999:	74 04                	je     f010199f <mem_init+0x718>
f010199b:	39 c3                	cmp    %eax,%ebx
f010199d:	75 24                	jne    f01019c3 <mem_init+0x73c>
f010199f:	c7 44 24 0c 0c 45 10 	movl   $0xf010450c,0xc(%esp)
f01019a6:	f0 
f01019a7:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f01019ae:	f0 
f01019af:	c7 44 24 04 0a 03 00 	movl   $0x30a,0x4(%esp)
f01019b6:	00 
f01019b7:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f01019be:	e8 d1 e6 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01019c3:	8b 15 80 85 11 f0    	mov    0xf0118580,%edx
f01019c9:	89 55 cc             	mov    %edx,-0x34(%ebp)
	page_free_list = 0;
f01019cc:	c7 05 80 85 11 f0 00 	movl   $0x0,0xf0118580
f01019d3:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01019d6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019dd:	e8 b6 f4 ff ff       	call   f0100e98 <page_alloc>
f01019e2:	85 c0                	test   %eax,%eax
f01019e4:	74 24                	je     f0101a0a <mem_init+0x783>
f01019e6:	c7 44 24 0c 08 4c 10 	movl   $0xf0104c08,0xc(%esp)
f01019ed:	f0 
f01019ee:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f01019f5:	f0 
f01019f6:	c7 44 24 04 11 03 00 	movl   $0x311,0x4(%esp)
f01019fd:	00 
f01019fe:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0101a05:	e8 8a e6 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101a0a:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101a0d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101a11:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101a18:	00 
f0101a19:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0101a1e:	89 04 24             	mov    %eax,(%esp)
f0101a21:	e8 e7 f6 ff ff       	call   f010110d <page_lookup>
f0101a26:	85 c0                	test   %eax,%eax
f0101a28:	74 24                	je     f0101a4e <mem_init+0x7c7>
f0101a2a:	c7 44 24 0c 4c 45 10 	movl   $0xf010454c,0xc(%esp)
f0101a31:	f0 
f0101a32:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0101a39:	f0 
f0101a3a:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
f0101a41:	00 
f0101a42:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0101a49:	e8 46 e6 ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101a4e:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101a55:	00 
f0101a56:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101a5d:	00 
f0101a5e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101a62:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0101a67:	89 04 24             	mov    %eax,(%esp)
f0101a6a:	e8 71 f7 ff ff       	call   f01011e0 <page_insert>
f0101a6f:	85 c0                	test   %eax,%eax
f0101a71:	78 24                	js     f0101a97 <mem_init+0x810>
f0101a73:	c7 44 24 0c 84 45 10 	movl   $0xf0104584,0xc(%esp)
f0101a7a:	f0 
f0101a7b:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0101a82:	f0 
f0101a83:	c7 44 24 04 17 03 00 	movl   $0x317,0x4(%esp)
f0101a8a:	00 
f0101a8b:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0101a92:	e8 fd e5 ff ff       	call   f0100094 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101a97:	89 1c 24             	mov    %ebx,(%esp)
f0101a9a:	e8 8c f4 ff ff       	call   f0100f2b <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101a9f:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101aa6:	00 
f0101aa7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101aae:	00 
f0101aaf:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101ab3:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0101ab8:	89 04 24             	mov    %eax,(%esp)
f0101abb:	e8 20 f7 ff ff       	call   f01011e0 <page_insert>
f0101ac0:	85 c0                	test   %eax,%eax
f0101ac2:	74 24                	je     f0101ae8 <mem_init+0x861>
f0101ac4:	c7 44 24 0c b4 45 10 	movl   $0xf01045b4,0xc(%esp)
f0101acb:	f0 
f0101acc:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0101ad3:	f0 
f0101ad4:	c7 44 24 04 1b 03 00 	movl   $0x31b,0x4(%esp)
f0101adb:	00 
f0101adc:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0101ae3:	e8 ac e5 ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101ae8:	8b 0d a4 89 11 f0    	mov    0xf01189a4,%ecx
f0101aee:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101af1:	a1 a8 89 11 f0       	mov    0xf01189a8,%eax
f0101af6:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101af9:	8b 11                	mov    (%ecx),%edx
f0101afb:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101b01:	89 d8                	mov    %ebx,%eax
f0101b03:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0101b06:	c1 f8 03             	sar    $0x3,%eax
f0101b09:	c1 e0 0c             	shl    $0xc,%eax
f0101b0c:	39 c2                	cmp    %eax,%edx
f0101b0e:	74 24                	je     f0101b34 <mem_init+0x8ad>
f0101b10:	c7 44 24 0c e4 45 10 	movl   $0xf01045e4,0xc(%esp)
f0101b17:	f0 
f0101b18:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0101b1f:	f0 
f0101b20:	c7 44 24 04 1c 03 00 	movl   $0x31c,0x4(%esp)
f0101b27:	00 
f0101b28:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0101b2f:	e8 60 e5 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101b34:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b39:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b3c:	e8 7d ee ff ff       	call   f01009be <check_va2pa>
f0101b41:	89 fa                	mov    %edi,%edx
f0101b43:	2b 55 d0             	sub    -0x30(%ebp),%edx
f0101b46:	c1 fa 03             	sar    $0x3,%edx
f0101b49:	c1 e2 0c             	shl    $0xc,%edx
f0101b4c:	39 d0                	cmp    %edx,%eax
f0101b4e:	74 24                	je     f0101b74 <mem_init+0x8ed>
f0101b50:	c7 44 24 0c 0c 46 10 	movl   $0xf010460c,0xc(%esp)
f0101b57:	f0 
f0101b58:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0101b5f:	f0 
f0101b60:	c7 44 24 04 1d 03 00 	movl   $0x31d,0x4(%esp)
f0101b67:	00 
f0101b68:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0101b6f:	e8 20 e5 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0101b74:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101b79:	74 24                	je     f0101b9f <mem_init+0x918>
f0101b7b:	c7 44 24 0c 5a 4c 10 	movl   $0xf0104c5a,0xc(%esp)
f0101b82:	f0 
f0101b83:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0101b8a:	f0 
f0101b8b:	c7 44 24 04 1e 03 00 	movl   $0x31e,0x4(%esp)
f0101b92:	00 
f0101b93:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0101b9a:	e8 f5 e4 ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0101b9f:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101ba4:	74 24                	je     f0101bca <mem_init+0x943>
f0101ba6:	c7 44 24 0c 6b 4c 10 	movl   $0xf0104c6b,0xc(%esp)
f0101bad:	f0 
f0101bae:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0101bb5:	f0 
f0101bb6:	c7 44 24 04 1f 03 00 	movl   $0x31f,0x4(%esp)
f0101bbd:	00 
f0101bbe:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0101bc5:	e8 ca e4 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101bca:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101bd1:	00 
f0101bd2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101bd9:	00 
f0101bda:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101bde:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101be1:	89 14 24             	mov    %edx,(%esp)
f0101be4:	e8 f7 f5 ff ff       	call   f01011e0 <page_insert>
f0101be9:	85 c0                	test   %eax,%eax
f0101beb:	74 24                	je     f0101c11 <mem_init+0x98a>
f0101bed:	c7 44 24 0c 3c 46 10 	movl   $0xf010463c,0xc(%esp)
f0101bf4:	f0 
f0101bf5:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0101bfc:	f0 
f0101bfd:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f0101c04:	00 
f0101c05:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0101c0c:	e8 83 e4 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c11:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c16:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0101c1b:	e8 9e ed ff ff       	call   f01009be <check_va2pa>
f0101c20:	89 f2                	mov    %esi,%edx
f0101c22:	2b 15 a8 89 11 f0    	sub    0xf01189a8,%edx
f0101c28:	c1 fa 03             	sar    $0x3,%edx
f0101c2b:	c1 e2 0c             	shl    $0xc,%edx
f0101c2e:	39 d0                	cmp    %edx,%eax
f0101c30:	74 24                	je     f0101c56 <mem_init+0x9cf>
f0101c32:	c7 44 24 0c 78 46 10 	movl   $0xf0104678,0xc(%esp)
f0101c39:	f0 
f0101c3a:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0101c41:	f0 
f0101c42:	c7 44 24 04 23 03 00 	movl   $0x323,0x4(%esp)
f0101c49:	00 
f0101c4a:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0101c51:	e8 3e e4 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101c56:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c5b:	74 24                	je     f0101c81 <mem_init+0x9fa>
f0101c5d:	c7 44 24 0c 7c 4c 10 	movl   $0xf0104c7c,0xc(%esp)
f0101c64:	f0 
f0101c65:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0101c6c:	f0 
f0101c6d:	c7 44 24 04 24 03 00 	movl   $0x324,0x4(%esp)
f0101c74:	00 
f0101c75:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0101c7c:	e8 13 e4 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101c81:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c88:	e8 0b f2 ff ff       	call   f0100e98 <page_alloc>
f0101c8d:	85 c0                	test   %eax,%eax
f0101c8f:	74 24                	je     f0101cb5 <mem_init+0xa2e>
f0101c91:	c7 44 24 0c 08 4c 10 	movl   $0xf0104c08,0xc(%esp)
f0101c98:	f0 
f0101c99:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0101ca0:	f0 
f0101ca1:	c7 44 24 04 27 03 00 	movl   $0x327,0x4(%esp)
f0101ca8:	00 
f0101ca9:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0101cb0:	e8 df e3 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101cb5:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101cbc:	00 
f0101cbd:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101cc4:	00 
f0101cc5:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101cc9:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0101cce:	89 04 24             	mov    %eax,(%esp)
f0101cd1:	e8 0a f5 ff ff       	call   f01011e0 <page_insert>
f0101cd6:	85 c0                	test   %eax,%eax
f0101cd8:	74 24                	je     f0101cfe <mem_init+0xa77>
f0101cda:	c7 44 24 0c 3c 46 10 	movl   $0xf010463c,0xc(%esp)
f0101ce1:	f0 
f0101ce2:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0101ce9:	f0 
f0101cea:	c7 44 24 04 2a 03 00 	movl   $0x32a,0x4(%esp)
f0101cf1:	00 
f0101cf2:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0101cf9:	e8 96 e3 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101cfe:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d03:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0101d08:	e8 b1 ec ff ff       	call   f01009be <check_va2pa>
f0101d0d:	89 f2                	mov    %esi,%edx
f0101d0f:	2b 15 a8 89 11 f0    	sub    0xf01189a8,%edx
f0101d15:	c1 fa 03             	sar    $0x3,%edx
f0101d18:	c1 e2 0c             	shl    $0xc,%edx
f0101d1b:	39 d0                	cmp    %edx,%eax
f0101d1d:	74 24                	je     f0101d43 <mem_init+0xabc>
f0101d1f:	c7 44 24 0c 78 46 10 	movl   $0xf0104678,0xc(%esp)
f0101d26:	f0 
f0101d27:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0101d2e:	f0 
f0101d2f:	c7 44 24 04 2b 03 00 	movl   $0x32b,0x4(%esp)
f0101d36:	00 
f0101d37:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0101d3e:	e8 51 e3 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101d43:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d48:	74 24                	je     f0101d6e <mem_init+0xae7>
f0101d4a:	c7 44 24 0c 7c 4c 10 	movl   $0xf0104c7c,0xc(%esp)
f0101d51:	f0 
f0101d52:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0101d59:	f0 
f0101d5a:	c7 44 24 04 2c 03 00 	movl   $0x32c,0x4(%esp)
f0101d61:	00 
f0101d62:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0101d69:	e8 26 e3 ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101d6e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101d75:	e8 1e f1 ff ff       	call   f0100e98 <page_alloc>
f0101d7a:	85 c0                	test   %eax,%eax
f0101d7c:	74 24                	je     f0101da2 <mem_init+0xb1b>
f0101d7e:	c7 44 24 0c 08 4c 10 	movl   $0xf0104c08,0xc(%esp)
f0101d85:	f0 
f0101d86:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0101d8d:	f0 
f0101d8e:	c7 44 24 04 30 03 00 	movl   $0x330,0x4(%esp)
f0101d95:	00 
f0101d96:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0101d9d:	e8 f2 e2 ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101da2:	8b 15 a4 89 11 f0    	mov    0xf01189a4,%edx
f0101da8:	8b 02                	mov    (%edx),%eax
f0101daa:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101daf:	89 c1                	mov    %eax,%ecx
f0101db1:	c1 e9 0c             	shr    $0xc,%ecx
f0101db4:	3b 0d a0 89 11 f0    	cmp    0xf01189a0,%ecx
f0101dba:	72 20                	jb     f0101ddc <mem_init+0xb55>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101dbc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101dc0:	c7 44 24 08 a4 43 10 	movl   $0xf01043a4,0x8(%esp)
f0101dc7:	f0 
f0101dc8:	c7 44 24 04 33 03 00 	movl   $0x333,0x4(%esp)
f0101dcf:	00 
f0101dd0:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0101dd7:	e8 b8 e2 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101ddc:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101de1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101de4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101deb:	00 
f0101dec:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101df3:	00 
f0101df4:	89 14 24             	mov    %edx,(%esp)
f0101df7:	e8 6d f1 ff ff       	call   f0100f69 <pgdir_walk>
f0101dfc:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101dff:	83 c2 04             	add    $0x4,%edx
f0101e02:	39 d0                	cmp    %edx,%eax
f0101e04:	74 24                	je     f0101e2a <mem_init+0xba3>
f0101e06:	c7 44 24 0c a8 46 10 	movl   $0xf01046a8,0xc(%esp)
f0101e0d:	f0 
f0101e0e:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0101e15:	f0 
f0101e16:	c7 44 24 04 34 03 00 	movl   $0x334,0x4(%esp)
f0101e1d:	00 
f0101e1e:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0101e25:	e8 6a e2 ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101e2a:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101e31:	00 
f0101e32:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101e39:	00 
f0101e3a:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101e3e:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0101e43:	89 04 24             	mov    %eax,(%esp)
f0101e46:	e8 95 f3 ff ff       	call   f01011e0 <page_insert>
f0101e4b:	85 c0                	test   %eax,%eax
f0101e4d:	74 24                	je     f0101e73 <mem_init+0xbec>
f0101e4f:	c7 44 24 0c e8 46 10 	movl   $0xf01046e8,0xc(%esp)
f0101e56:	f0 
f0101e57:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0101e5e:	f0 
f0101e5f:	c7 44 24 04 37 03 00 	movl   $0x337,0x4(%esp)
f0101e66:	00 
f0101e67:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0101e6e:	e8 21 e2 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101e73:	8b 0d a4 89 11 f0    	mov    0xf01189a4,%ecx
f0101e79:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0101e7c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e81:	89 c8                	mov    %ecx,%eax
f0101e83:	e8 36 eb ff ff       	call   f01009be <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101e88:	89 f2                	mov    %esi,%edx
f0101e8a:	2b 15 a8 89 11 f0    	sub    0xf01189a8,%edx
f0101e90:	c1 fa 03             	sar    $0x3,%edx
f0101e93:	c1 e2 0c             	shl    $0xc,%edx
f0101e96:	39 d0                	cmp    %edx,%eax
f0101e98:	74 24                	je     f0101ebe <mem_init+0xc37>
f0101e9a:	c7 44 24 0c 78 46 10 	movl   $0xf0104678,0xc(%esp)
f0101ea1:	f0 
f0101ea2:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0101ea9:	f0 
f0101eaa:	c7 44 24 04 38 03 00 	movl   $0x338,0x4(%esp)
f0101eb1:	00 
f0101eb2:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0101eb9:	e8 d6 e1 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101ebe:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101ec3:	74 24                	je     f0101ee9 <mem_init+0xc62>
f0101ec5:	c7 44 24 0c 7c 4c 10 	movl   $0xf0104c7c,0xc(%esp)
f0101ecc:	f0 
f0101ecd:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0101ed4:	f0 
f0101ed5:	c7 44 24 04 39 03 00 	movl   $0x339,0x4(%esp)
f0101edc:	00 
f0101edd:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0101ee4:	e8 ab e1 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101ee9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101ef0:	00 
f0101ef1:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101ef8:	00 
f0101ef9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101efc:	89 04 24             	mov    %eax,(%esp)
f0101eff:	e8 65 f0 ff ff       	call   f0100f69 <pgdir_walk>
f0101f04:	f6 00 04             	testb  $0x4,(%eax)
f0101f07:	75 24                	jne    f0101f2d <mem_init+0xca6>
f0101f09:	c7 44 24 0c 28 47 10 	movl   $0xf0104728,0xc(%esp)
f0101f10:	f0 
f0101f11:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0101f18:	f0 
f0101f19:	c7 44 24 04 3a 03 00 	movl   $0x33a,0x4(%esp)
f0101f20:	00 
f0101f21:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0101f28:	e8 67 e1 ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101f2d:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0101f32:	f6 00 04             	testb  $0x4,(%eax)
f0101f35:	75 24                	jne    f0101f5b <mem_init+0xcd4>
f0101f37:	c7 44 24 0c 8d 4c 10 	movl   $0xf0104c8d,0xc(%esp)
f0101f3e:	f0 
f0101f3f:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0101f46:	f0 
f0101f47:	c7 44 24 04 3b 03 00 	movl   $0x33b,0x4(%esp)
f0101f4e:	00 
f0101f4f:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0101f56:	e8 39 e1 ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101f5b:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f62:	00 
f0101f63:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0101f6a:	00 
f0101f6b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101f6f:	89 04 24             	mov    %eax,(%esp)
f0101f72:	e8 69 f2 ff ff       	call   f01011e0 <page_insert>
f0101f77:	85 c0                	test   %eax,%eax
f0101f79:	78 24                	js     f0101f9f <mem_init+0xd18>
f0101f7b:	c7 44 24 0c 5c 47 10 	movl   $0xf010475c,0xc(%esp)
f0101f82:	f0 
f0101f83:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0101f8a:	f0 
f0101f8b:	c7 44 24 04 3e 03 00 	movl   $0x33e,0x4(%esp)
f0101f92:	00 
f0101f93:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0101f9a:	e8 f5 e0 ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101f9f:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101fa6:	00 
f0101fa7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101fae:	00 
f0101faf:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101fb3:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0101fb8:	89 04 24             	mov    %eax,(%esp)
f0101fbb:	e8 20 f2 ff ff       	call   f01011e0 <page_insert>
f0101fc0:	85 c0                	test   %eax,%eax
f0101fc2:	74 24                	je     f0101fe8 <mem_init+0xd61>
f0101fc4:	c7 44 24 0c 94 47 10 	movl   $0xf0104794,0xc(%esp)
f0101fcb:	f0 
f0101fcc:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0101fd3:	f0 
f0101fd4:	c7 44 24 04 41 03 00 	movl   $0x341,0x4(%esp)
f0101fdb:	00 
f0101fdc:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0101fe3:	e8 ac e0 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101fe8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101fef:	00 
f0101ff0:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101ff7:	00 
f0101ff8:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0101ffd:	89 04 24             	mov    %eax,(%esp)
f0102000:	e8 64 ef ff ff       	call   f0100f69 <pgdir_walk>
f0102005:	f6 00 04             	testb  $0x4,(%eax)
f0102008:	74 24                	je     f010202e <mem_init+0xda7>
f010200a:	c7 44 24 0c d0 47 10 	movl   $0xf01047d0,0xc(%esp)
f0102011:	f0 
f0102012:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0102019:	f0 
f010201a:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f0102021:	00 
f0102022:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0102029:	e8 66 e0 ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010202e:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0102033:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102036:	ba 00 00 00 00       	mov    $0x0,%edx
f010203b:	e8 7e e9 ff ff       	call   f01009be <check_va2pa>
f0102040:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102043:	89 f8                	mov    %edi,%eax
f0102045:	2b 05 a8 89 11 f0    	sub    0xf01189a8,%eax
f010204b:	c1 f8 03             	sar    $0x3,%eax
f010204e:	c1 e0 0c             	shl    $0xc,%eax
f0102051:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102054:	74 24                	je     f010207a <mem_init+0xdf3>
f0102056:	c7 44 24 0c 08 48 10 	movl   $0xf0104808,0xc(%esp)
f010205d:	f0 
f010205e:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0102065:	f0 
f0102066:	c7 44 24 04 45 03 00 	movl   $0x345,0x4(%esp)
f010206d:	00 
f010206e:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0102075:	e8 1a e0 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010207a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010207f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102082:	e8 37 e9 ff ff       	call   f01009be <check_va2pa>
f0102087:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f010208a:	74 24                	je     f01020b0 <mem_init+0xe29>
f010208c:	c7 44 24 0c 34 48 10 	movl   $0xf0104834,0xc(%esp)
f0102093:	f0 
f0102094:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f010209b:	f0 
f010209c:	c7 44 24 04 46 03 00 	movl   $0x346,0x4(%esp)
f01020a3:	00 
f01020a4:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f01020ab:	e8 e4 df ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f01020b0:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f01020b5:	74 24                	je     f01020db <mem_init+0xe54>
f01020b7:	c7 44 24 0c a3 4c 10 	movl   $0xf0104ca3,0xc(%esp)
f01020be:	f0 
f01020bf:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f01020c6:	f0 
f01020c7:	c7 44 24 04 48 03 00 	movl   $0x348,0x4(%esp)
f01020ce:	00 
f01020cf:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f01020d6:	e8 b9 df ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01020db:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01020e0:	74 24                	je     f0102106 <mem_init+0xe7f>
f01020e2:	c7 44 24 0c b4 4c 10 	movl   $0xf0104cb4,0xc(%esp)
f01020e9:	f0 
f01020ea:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f01020f1:	f0 
f01020f2:	c7 44 24 04 49 03 00 	movl   $0x349,0x4(%esp)
f01020f9:	00 
f01020fa:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0102101:	e8 8e df ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102106:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010210d:	e8 86 ed ff ff       	call   f0100e98 <page_alloc>
f0102112:	85 c0                	test   %eax,%eax
f0102114:	74 04                	je     f010211a <mem_init+0xe93>
f0102116:	39 c6                	cmp    %eax,%esi
f0102118:	74 24                	je     f010213e <mem_init+0xeb7>
f010211a:	c7 44 24 0c 64 48 10 	movl   $0xf0104864,0xc(%esp)
f0102121:	f0 
f0102122:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0102129:	f0 
f010212a:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f0102131:	00 
f0102132:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0102139:	e8 56 df ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f010213e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102145:	00 
f0102146:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f010214b:	89 04 24             	mov    %eax,(%esp)
f010214e:	e8 3d f0 ff ff       	call   f0101190 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102153:	8b 15 a4 89 11 f0    	mov    0xf01189a4,%edx
f0102159:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f010215c:	ba 00 00 00 00       	mov    $0x0,%edx
f0102161:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102164:	e8 55 e8 ff ff       	call   f01009be <check_va2pa>
f0102169:	83 f8 ff             	cmp    $0xffffffff,%eax
f010216c:	74 24                	je     f0102192 <mem_init+0xf0b>
f010216e:	c7 44 24 0c 88 48 10 	movl   $0xf0104888,0xc(%esp)
f0102175:	f0 
f0102176:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f010217d:	f0 
f010217e:	c7 44 24 04 50 03 00 	movl   $0x350,0x4(%esp)
f0102185:	00 
f0102186:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f010218d:	e8 02 df ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102192:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102197:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010219a:	e8 1f e8 ff ff       	call   f01009be <check_va2pa>
f010219f:	89 fa                	mov    %edi,%edx
f01021a1:	2b 15 a8 89 11 f0    	sub    0xf01189a8,%edx
f01021a7:	c1 fa 03             	sar    $0x3,%edx
f01021aa:	c1 e2 0c             	shl    $0xc,%edx
f01021ad:	39 d0                	cmp    %edx,%eax
f01021af:	74 24                	je     f01021d5 <mem_init+0xf4e>
f01021b1:	c7 44 24 0c 34 48 10 	movl   $0xf0104834,0xc(%esp)
f01021b8:	f0 
f01021b9:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f01021c0:	f0 
f01021c1:	c7 44 24 04 51 03 00 	movl   $0x351,0x4(%esp)
f01021c8:	00 
f01021c9:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f01021d0:	e8 bf de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f01021d5:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01021da:	74 24                	je     f0102200 <mem_init+0xf79>
f01021dc:	c7 44 24 0c 5a 4c 10 	movl   $0xf0104c5a,0xc(%esp)
f01021e3:	f0 
f01021e4:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f01021eb:	f0 
f01021ec:	c7 44 24 04 52 03 00 	movl   $0x352,0x4(%esp)
f01021f3:	00 
f01021f4:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f01021fb:	e8 94 de ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102200:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102205:	74 24                	je     f010222b <mem_init+0xfa4>
f0102207:	c7 44 24 0c b4 4c 10 	movl   $0xf0104cb4,0xc(%esp)
f010220e:	f0 
f010220f:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0102216:	f0 
f0102217:	c7 44 24 04 53 03 00 	movl   $0x353,0x4(%esp)
f010221e:	00 
f010221f:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0102226:	e8 69 de ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f010222b:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102232:	00 
f0102233:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102236:	89 0c 24             	mov    %ecx,(%esp)
f0102239:	e8 52 ef ff ff       	call   f0101190 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010223e:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0102243:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102246:	ba 00 00 00 00       	mov    $0x0,%edx
f010224b:	e8 6e e7 ff ff       	call   f01009be <check_va2pa>
f0102250:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102253:	74 24                	je     f0102279 <mem_init+0xff2>
f0102255:	c7 44 24 0c 88 48 10 	movl   $0xf0104888,0xc(%esp)
f010225c:	f0 
f010225d:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0102264:	f0 
f0102265:	c7 44 24 04 57 03 00 	movl   $0x357,0x4(%esp)
f010226c:	00 
f010226d:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0102274:	e8 1b de ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102279:	ba 00 10 00 00       	mov    $0x1000,%edx
f010227e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102281:	e8 38 e7 ff ff       	call   f01009be <check_va2pa>
f0102286:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102289:	74 24                	je     f01022af <mem_init+0x1028>
f010228b:	c7 44 24 0c ac 48 10 	movl   $0xf01048ac,0xc(%esp)
f0102292:	f0 
f0102293:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f010229a:	f0 
f010229b:	c7 44 24 04 58 03 00 	movl   $0x358,0x4(%esp)
f01022a2:	00 
f01022a3:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f01022aa:	e8 e5 dd ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f01022af:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01022b4:	74 24                	je     f01022da <mem_init+0x1053>
f01022b6:	c7 44 24 0c c5 4c 10 	movl   $0xf0104cc5,0xc(%esp)
f01022bd:	f0 
f01022be:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f01022c5:	f0 
f01022c6:	c7 44 24 04 59 03 00 	movl   $0x359,0x4(%esp)
f01022cd:	00 
f01022ce:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f01022d5:	e8 ba dd ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01022da:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01022df:	74 24                	je     f0102305 <mem_init+0x107e>
f01022e1:	c7 44 24 0c b4 4c 10 	movl   $0xf0104cb4,0xc(%esp)
f01022e8:	f0 
f01022e9:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f01022f0:	f0 
f01022f1:	c7 44 24 04 5a 03 00 	movl   $0x35a,0x4(%esp)
f01022f8:	00 
f01022f9:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0102300:	e8 8f dd ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102305:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010230c:	e8 87 eb ff ff       	call   f0100e98 <page_alloc>
f0102311:	85 c0                	test   %eax,%eax
f0102313:	74 04                	je     f0102319 <mem_init+0x1092>
f0102315:	39 c7                	cmp    %eax,%edi
f0102317:	74 24                	je     f010233d <mem_init+0x10b6>
f0102319:	c7 44 24 0c d4 48 10 	movl   $0xf01048d4,0xc(%esp)
f0102320:	f0 
f0102321:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0102328:	f0 
f0102329:	c7 44 24 04 5d 03 00 	movl   $0x35d,0x4(%esp)
f0102330:	00 
f0102331:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0102338:	e8 57 dd ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010233d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102344:	e8 4f eb ff ff       	call   f0100e98 <page_alloc>
f0102349:	85 c0                	test   %eax,%eax
f010234b:	74 24                	je     f0102371 <mem_init+0x10ea>
f010234d:	c7 44 24 0c 08 4c 10 	movl   $0xf0104c08,0xc(%esp)
f0102354:	f0 
f0102355:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f010235c:	f0 
f010235d:	c7 44 24 04 60 03 00 	movl   $0x360,0x4(%esp)
f0102364:	00 
f0102365:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f010236c:	e8 23 dd ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102371:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0102376:	8b 08                	mov    (%eax),%ecx
f0102378:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f010237e:	89 da                	mov    %ebx,%edx
f0102380:	2b 15 a8 89 11 f0    	sub    0xf01189a8,%edx
f0102386:	c1 fa 03             	sar    $0x3,%edx
f0102389:	c1 e2 0c             	shl    $0xc,%edx
f010238c:	39 d1                	cmp    %edx,%ecx
f010238e:	74 24                	je     f01023b4 <mem_init+0x112d>
f0102390:	c7 44 24 0c e4 45 10 	movl   $0xf01045e4,0xc(%esp)
f0102397:	f0 
f0102398:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f010239f:	f0 
f01023a0:	c7 44 24 04 63 03 00 	movl   $0x363,0x4(%esp)
f01023a7:	00 
f01023a8:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f01023af:	e8 e0 dc ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f01023b4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f01023ba:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01023bf:	74 24                	je     f01023e5 <mem_init+0x115e>
f01023c1:	c7 44 24 0c 6b 4c 10 	movl   $0xf0104c6b,0xc(%esp)
f01023c8:	f0 
f01023c9:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f01023d0:	f0 
f01023d1:	c7 44 24 04 65 03 00 	movl   $0x365,0x4(%esp)
f01023d8:	00 
f01023d9:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f01023e0:	e8 af dc ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f01023e5:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01023eb:	89 1c 24             	mov    %ebx,(%esp)
f01023ee:	e8 38 eb ff ff       	call   f0100f2b <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01023f3:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01023fa:	00 
f01023fb:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f0102402:	00 
f0102403:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0102408:	89 04 24             	mov    %eax,(%esp)
f010240b:	e8 59 eb ff ff       	call   f0100f69 <pgdir_walk>
f0102410:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102413:	8b 0d a4 89 11 f0    	mov    0xf01189a4,%ecx
f0102419:	8b 51 04             	mov    0x4(%ecx),%edx
f010241c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102422:	89 55 d4             	mov    %edx,-0x2c(%ebp)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102425:	8b 15 a0 89 11 f0    	mov    0xf01189a0,%edx
f010242b:	89 55 c8             	mov    %edx,-0x38(%ebp)
f010242e:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102431:	c1 ea 0c             	shr    $0xc,%edx
f0102434:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102437:	8b 55 c8             	mov    -0x38(%ebp),%edx
f010243a:	39 55 d0             	cmp    %edx,-0x30(%ebp)
f010243d:	72 23                	jb     f0102462 <mem_init+0x11db>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010243f:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102442:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0102446:	c7 44 24 08 a4 43 10 	movl   $0xf01043a4,0x8(%esp)
f010244d:	f0 
f010244e:	c7 44 24 04 6c 03 00 	movl   $0x36c,0x4(%esp)
f0102455:	00 
f0102456:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f010245d:	e8 32 dc ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102462:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102465:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f010246b:	39 d0                	cmp    %edx,%eax
f010246d:	74 24                	je     f0102493 <mem_init+0x120c>
f010246f:	c7 44 24 0c d6 4c 10 	movl   $0xf0104cd6,0xc(%esp)
f0102476:	f0 
f0102477:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f010247e:	f0 
f010247f:	c7 44 24 04 6d 03 00 	movl   $0x36d,0x4(%esp)
f0102486:	00 
f0102487:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f010248e:	e8 01 dc ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102493:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f010249a:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01024a0:	89 d8                	mov    %ebx,%eax
f01024a2:	2b 05 a8 89 11 f0    	sub    0xf01189a8,%eax
f01024a8:	c1 f8 03             	sar    $0x3,%eax
f01024ab:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024ae:	89 c1                	mov    %eax,%ecx
f01024b0:	c1 e9 0c             	shr    $0xc,%ecx
f01024b3:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f01024b6:	77 20                	ja     f01024d8 <mem_init+0x1251>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024b8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01024bc:	c7 44 24 08 a4 43 10 	movl   $0xf01043a4,0x8(%esp)
f01024c3:	f0 
f01024c4:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01024cb:	00 
f01024cc:	c7 04 24 98 4a 10 f0 	movl   $0xf0104a98,(%esp)
f01024d3:	e8 bc db ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01024d8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01024df:	00 
f01024e0:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f01024e7:	00 
	return (void *)(pa + KERNBASE);
f01024e8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024ed:	89 04 24             	mov    %eax,(%esp)
f01024f0:	e8 a1 14 00 00       	call   f0103996 <memset>
	page_free(pp0);
f01024f5:	89 1c 24             	mov    %ebx,(%esp)
f01024f8:	e8 2e ea ff ff       	call   f0100f2b <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01024fd:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102504:	00 
f0102505:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010250c:	00 
f010250d:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0102512:	89 04 24             	mov    %eax,(%esp)
f0102515:	e8 4f ea ff ff       	call   f0100f69 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f010251a:	89 da                	mov    %ebx,%edx
f010251c:	2b 15 a8 89 11 f0    	sub    0xf01189a8,%edx
f0102522:	c1 fa 03             	sar    $0x3,%edx
f0102525:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102528:	89 d0                	mov    %edx,%eax
f010252a:	c1 e8 0c             	shr    $0xc,%eax
f010252d:	3b 05 a0 89 11 f0    	cmp    0xf01189a0,%eax
f0102533:	72 20                	jb     f0102555 <mem_init+0x12ce>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102535:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102539:	c7 44 24 08 a4 43 10 	movl   $0xf01043a4,0x8(%esp)
f0102540:	f0 
f0102541:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102548:	00 
f0102549:	c7 04 24 98 4a 10 f0 	movl   $0xf0104a98,(%esp)
f0102550:	e8 3f db ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0102555:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010255b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010255e:	f6 82 00 00 00 f0 01 	testb  $0x1,-0x10000000(%edx)
f0102565:	75 11                	jne    f0102578 <mem_init+0x12f1>
f0102567:	8d 82 04 00 00 f0    	lea    -0xffffffc(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010256d:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102573:	f6 00 01             	testb  $0x1,(%eax)
f0102576:	74 24                	je     f010259c <mem_init+0x1315>
f0102578:	c7 44 24 0c ee 4c 10 	movl   $0xf0104cee,0xc(%esp)
f010257f:	f0 
f0102580:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0102587:	f0 
f0102588:	c7 44 24 04 77 03 00 	movl   $0x377,0x4(%esp)
f010258f:	00 
f0102590:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0102597:	e8 f8 da ff ff       	call   f0100094 <_panic>
f010259c:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f010259f:	39 d0                	cmp    %edx,%eax
f01025a1:	75 d0                	jne    f0102573 <mem_init+0x12ec>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01025a3:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f01025a8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01025ae:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// give free list back
	page_free_list = fl;
f01025b4:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f01025b7:	89 0d 80 85 11 f0    	mov    %ecx,0xf0118580

	// free the pages we took
	page_free(pp0);
f01025bd:	89 1c 24             	mov    %ebx,(%esp)
f01025c0:	e8 66 e9 ff ff       	call   f0100f2b <page_free>
	page_free(pp1);
f01025c5:	89 3c 24             	mov    %edi,(%esp)
f01025c8:	e8 5e e9 ff ff       	call   f0100f2b <page_free>
	page_free(pp2);
f01025cd:	89 34 24             	mov    %esi,(%esp)
f01025d0:	e8 56 e9 ff ff       	call   f0100f2b <page_free>

	cprintf("check_page() succeeded!\n");
f01025d5:	c7 04 24 05 4d 10 f0 	movl   $0xf0104d05,(%esp)
f01025dc:	e8 b1 07 00 00       	call   f0102d92 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
boot_map_region(
f01025e1:	a1 a8 89 11 f0       	mov    0xf01189a8,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01025e6:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01025eb:	77 20                	ja     f010260d <mem_init+0x1386>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01025ed:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01025f1:	c7 44 24 08 8c 44 10 	movl   $0xf010448c,0x8(%esp)
f01025f8:	f0 
f01025f9:	c7 44 24 04 b0 00 00 	movl   $0xb0,0x4(%esp)
f0102600:	00 
f0102601:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0102608:	e8 87 da ff ff       	call   f0100094 <_panic>
kern_pgdir,
UPAGES,
ROUNDUP (npages * sizeof (struct Page), PGSIZE),
f010260d:	8b 15 a0 89 11 f0    	mov    0xf01189a0,%edx
f0102613:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
f010261a:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
boot_map_region(
f0102620:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
f0102627:	00 
	return (physaddr_t)kva - KERNBASE;
f0102628:	05 00 00 00 10       	add    $0x10000000,%eax
f010262d:	89 04 24             	mov    %eax,(%esp)
f0102630:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102635:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f010263a:	e8 6e ea ff ff       	call   f01010ad <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010263f:	b8 00 e0 10 f0       	mov    $0xf010e000,%eax
f0102644:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102649:	77 20                	ja     f010266b <mem_init+0x13e4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010264b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010264f:	c7 44 24 08 8c 44 10 	movl   $0xf010448c,0x8(%esp)
f0102656:	f0 
f0102657:	c7 44 24 04 c2 00 00 	movl   $0xc2,0x4(%esp)
f010265e:	00 
f010265f:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0102666:	e8 29 da ff ff       	call   f0100094 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
boot_map_region (
f010266b:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102672:	00 
f0102673:	c7 04 24 00 e0 10 00 	movl   $0x10e000,(%esp)
f010267a:	b9 00 80 00 00       	mov    $0x8000,%ecx
f010267f:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f0102684:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0102689:	e8 1f ea ff ff       	call   f01010ad <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
boot_map_region (
f010268e:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102695:	00 
f0102696:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010269d:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01026a2:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01026a7:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f01026ac:	e8 fc e9 ff ff       	call   f01010ad <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01026b1:	8b 1d a4 89 11 f0    	mov    0xf01189a4,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
f01026b7:	8b 15 a0 89 11 f0    	mov    0xf01189a0,%edx
f01026bd:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f01026c0:	8d 3c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%edi
	for (i = 0; i < n; i += PGSIZE)
f01026c7:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
f01026cd:	74 79                	je     f0102748 <mem_init+0x14c1>
f01026cf:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01026d4:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01026da:	89 d8                	mov    %ebx,%eax
f01026dc:	e8 dd e2 ff ff       	call   f01009be <check_va2pa>
f01026e1:	8b 15 a8 89 11 f0    	mov    0xf01189a8,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026e7:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f01026ed:	77 20                	ja     f010270f <mem_init+0x1488>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026ef:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01026f3:	c7 44 24 08 8c 44 10 	movl   $0xf010448c,0x8(%esp)
f01026fa:	f0 
f01026fb:	c7 44 24 04 c3 02 00 	movl   $0x2c3,0x4(%esp)
f0102702:	00 
f0102703:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f010270a:	e8 85 d9 ff ff       	call   f0100094 <_panic>
f010270f:	8d 94 32 00 00 00 10 	lea    0x10000000(%edx,%esi,1),%edx
f0102716:	39 d0                	cmp    %edx,%eax
f0102718:	74 24                	je     f010273e <mem_init+0x14b7>
f010271a:	c7 44 24 0c f8 48 10 	movl   $0xf01048f8,0xc(%esp)
f0102721:	f0 
f0102722:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0102729:	f0 
f010272a:	c7 44 24 04 c3 02 00 	movl   $0x2c3,0x4(%esp)
f0102731:	00 
f0102732:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0102739:	e8 56 d9 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010273e:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102744:	39 f7                	cmp    %esi,%edi
f0102746:	77 8c                	ja     f01026d4 <mem_init+0x144d>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102748:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010274b:	c1 e7 0c             	shl    $0xc,%edi
f010274e:	85 ff                	test   %edi,%edi
f0102750:	74 44                	je     f0102796 <mem_init+0x150f>
f0102752:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102757:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010275d:	89 d8                	mov    %ebx,%eax
f010275f:	e8 5a e2 ff ff       	call   f01009be <check_va2pa>
f0102764:	39 c6                	cmp    %eax,%esi
f0102766:	74 24                	je     f010278c <mem_init+0x1505>
f0102768:	c7 44 24 0c 2c 49 10 	movl   $0xf010492c,0xc(%esp)
f010276f:	f0 
f0102770:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0102777:	f0 
f0102778:	c7 44 24 04 c8 02 00 	movl   $0x2c8,0x4(%esp)
f010277f:	00 
f0102780:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0102787:	e8 08 d9 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010278c:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102792:	39 fe                	cmp    %edi,%esi
f0102794:	72 c1                	jb     f0102757 <mem_init+0x14d0>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102796:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f010279b:	89 d8                	mov    %ebx,%eax
f010279d:	e8 1c e2 ff ff       	call   f01009be <check_va2pa>
f01027a2:	be 00 90 bf ef       	mov    $0xefbf9000,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01027a7:	bf 00 e0 10 f0       	mov    $0xf010e000,%edi
f01027ac:	81 c7 00 70 40 20    	add    $0x20407000,%edi
f01027b2:	8d 14 37             	lea    (%edi,%esi,1),%edx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01027b5:	39 c2                	cmp    %eax,%edx
f01027b7:	74 24                	je     f01027dd <mem_init+0x1556>
f01027b9:	c7 44 24 0c 54 49 10 	movl   $0xf0104954,0xc(%esp)
f01027c0:	f0 
f01027c1:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f01027c8:	f0 
f01027c9:	c7 44 24 04 cc 02 00 	movl   $0x2cc,0x4(%esp)
f01027d0:	00 
f01027d1:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f01027d8:	e8 b7 d8 ff ff       	call   f0100094 <_panic>
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01027dd:	81 fe 00 00 c0 ef    	cmp    $0xefc00000,%esi
f01027e3:	0f 85 27 05 00 00    	jne    f0102d10 <mem_init+0x1a89>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01027e9:	ba 00 00 80 ef       	mov    $0xef800000,%edx
f01027ee:	89 d8                	mov    %ebx,%eax
f01027f0:	e8 c9 e1 ff ff       	call   f01009be <check_va2pa>
f01027f5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01027f8:	74 24                	je     f010281e <mem_init+0x1597>
f01027fa:	c7 44 24 0c 9c 49 10 	movl   $0xf010499c,0xc(%esp)
f0102801:	f0 
f0102802:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0102809:	f0 
f010280a:	c7 44 24 04 cd 02 00 	movl   $0x2cd,0x4(%esp)
f0102811:	00 
f0102812:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0102819:	e8 76 d8 ff ff       	call   f0100094 <_panic>
f010281e:	b8 00 00 00 00       	mov    $0x0,%eax

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102823:	8d 90 44 fc ff ff    	lea    -0x3bc(%eax),%edx
f0102829:	83 fa 02             	cmp    $0x2,%edx
f010282c:	77 2e                	ja     f010285c <mem_init+0x15d5>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f010282e:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0102832:	0f 85 aa 00 00 00    	jne    f01028e2 <mem_init+0x165b>
f0102838:	c7 44 24 0c 1e 4d 10 	movl   $0xf0104d1e,0xc(%esp)
f010283f:	f0 
f0102840:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0102847:	f0 
f0102848:	c7 44 24 04 d5 02 00 	movl   $0x2d5,0x4(%esp)
f010284f:	00 
f0102850:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0102857:	e8 38 d8 ff ff       	call   f0100094 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f010285c:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102861:	76 55                	jbe    f01028b8 <mem_init+0x1631>
				assert(pgdir[i] & PTE_P);
f0102863:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0102866:	f6 c2 01             	test   $0x1,%dl
f0102869:	75 24                	jne    f010288f <mem_init+0x1608>
f010286b:	c7 44 24 0c 1e 4d 10 	movl   $0xf0104d1e,0xc(%esp)
f0102872:	f0 
f0102873:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f010287a:	f0 
f010287b:	c7 44 24 04 d9 02 00 	movl   $0x2d9,0x4(%esp)
f0102882:	00 
f0102883:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f010288a:	e8 05 d8 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f010288f:	f6 c2 02             	test   $0x2,%dl
f0102892:	75 4e                	jne    f01028e2 <mem_init+0x165b>
f0102894:	c7 44 24 0c 2f 4d 10 	movl   $0xf0104d2f,0xc(%esp)
f010289b:	f0 
f010289c:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f01028a3:	f0 
f01028a4:	c7 44 24 04 da 02 00 	movl   $0x2da,0x4(%esp)
f01028ab:	00 
f01028ac:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f01028b3:	e8 dc d7 ff ff       	call   f0100094 <_panic>
			} else
				assert(pgdir[i] == 0);
f01028b8:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f01028bc:	74 24                	je     f01028e2 <mem_init+0x165b>
f01028be:	c7 44 24 0c 40 4d 10 	movl   $0xf0104d40,0xc(%esp)
f01028c5:	f0 
f01028c6:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f01028cd:	f0 
f01028ce:	c7 44 24 04 dc 02 00 	movl   $0x2dc,0x4(%esp)
f01028d5:	00 
f01028d6:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f01028dd:	e8 b2 d7 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01028e2:	83 c0 01             	add    $0x1,%eax
f01028e5:	3d 00 04 00 00       	cmp    $0x400,%eax
f01028ea:	0f 85 33 ff ff ff    	jne    f0102823 <mem_init+0x159c>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01028f0:	c7 04 24 cc 49 10 f0 	movl   $0xf01049cc,(%esp)
f01028f7:	e8 96 04 00 00       	call   f0102d92 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01028fc:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102901:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102906:	77 20                	ja     f0102928 <mem_init+0x16a1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102908:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010290c:	c7 44 24 08 8c 44 10 	movl   $0xf010448c,0x8(%esp)
f0102913:	f0 
f0102914:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
f010291b:	00 
f010291c:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0102923:	e8 6c d7 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102928:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f010292d:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102930:	b8 00 00 00 00       	mov    $0x0,%eax
f0102935:	e8 27 e1 ff ff       	call   f0100a61 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f010293a:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
f010293d:	0d 23 00 05 80       	or     $0x80050023,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102942:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102945:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102948:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010294f:	e8 44 e5 ff ff       	call   f0100e98 <page_alloc>
f0102954:	89 c6                	mov    %eax,%esi
f0102956:	85 c0                	test   %eax,%eax
f0102958:	75 24                	jne    f010297e <mem_init+0x16f7>
f010295a:	c7 44 24 0c 5d 4b 10 	movl   $0xf0104b5d,0xc(%esp)
f0102961:	f0 
f0102962:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0102969:	f0 
f010296a:	c7 44 24 04 92 03 00 	movl   $0x392,0x4(%esp)
f0102971:	00 
f0102972:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0102979:	e8 16 d7 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f010297e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102985:	e8 0e e5 ff ff       	call   f0100e98 <page_alloc>
f010298a:	89 c7                	mov    %eax,%edi
f010298c:	85 c0                	test   %eax,%eax
f010298e:	75 24                	jne    f01029b4 <mem_init+0x172d>
f0102990:	c7 44 24 0c 73 4b 10 	movl   $0xf0104b73,0xc(%esp)
f0102997:	f0 
f0102998:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f010299f:	f0 
f01029a0:	c7 44 24 04 93 03 00 	movl   $0x393,0x4(%esp)
f01029a7:	00 
f01029a8:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f01029af:	e8 e0 d6 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01029b4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01029bb:	e8 d8 e4 ff ff       	call   f0100e98 <page_alloc>
f01029c0:	89 c3                	mov    %eax,%ebx
f01029c2:	85 c0                	test   %eax,%eax
f01029c4:	75 24                	jne    f01029ea <mem_init+0x1763>
f01029c6:	c7 44 24 0c 89 4b 10 	movl   $0xf0104b89,0xc(%esp)
f01029cd:	f0 
f01029ce:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f01029d5:	f0 
f01029d6:	c7 44 24 04 94 03 00 	movl   $0x394,0x4(%esp)
f01029dd:	00 
f01029de:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f01029e5:	e8 aa d6 ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f01029ea:	89 34 24             	mov    %esi,(%esp)
f01029ed:	e8 39 e5 ff ff       	call   f0100f2b <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01029f2:	89 f8                	mov    %edi,%eax
f01029f4:	2b 05 a8 89 11 f0    	sub    0xf01189a8,%eax
f01029fa:	c1 f8 03             	sar    $0x3,%eax
f01029fd:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a00:	89 c2                	mov    %eax,%edx
f0102a02:	c1 ea 0c             	shr    $0xc,%edx
f0102a05:	3b 15 a0 89 11 f0    	cmp    0xf01189a0,%edx
f0102a0b:	72 20                	jb     f0102a2d <mem_init+0x17a6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a0d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102a11:	c7 44 24 08 a4 43 10 	movl   $0xf01043a4,0x8(%esp)
f0102a18:	f0 
f0102a19:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102a20:	00 
f0102a21:	c7 04 24 98 4a 10 f0 	movl   $0xf0104a98,(%esp)
f0102a28:	e8 67 d6 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102a2d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102a34:	00 
f0102a35:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102a3c:	00 
	return (void *)(pa + KERNBASE);
f0102a3d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102a42:	89 04 24             	mov    %eax,(%esp)
f0102a45:	e8 4c 0f 00 00       	call   f0103996 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102a4a:	89 d8                	mov    %ebx,%eax
f0102a4c:	2b 05 a8 89 11 f0    	sub    0xf01189a8,%eax
f0102a52:	c1 f8 03             	sar    $0x3,%eax
f0102a55:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a58:	89 c2                	mov    %eax,%edx
f0102a5a:	c1 ea 0c             	shr    $0xc,%edx
f0102a5d:	3b 15 a0 89 11 f0    	cmp    0xf01189a0,%edx
f0102a63:	72 20                	jb     f0102a85 <mem_init+0x17fe>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a65:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102a69:	c7 44 24 08 a4 43 10 	movl   $0xf01043a4,0x8(%esp)
f0102a70:	f0 
f0102a71:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102a78:	00 
f0102a79:	c7 04 24 98 4a 10 f0 	movl   $0xf0104a98,(%esp)
f0102a80:	e8 0f d6 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102a85:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102a8c:	00 
f0102a8d:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102a94:	00 
	return (void *)(pa + KERNBASE);
f0102a95:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102a9a:	89 04 24             	mov    %eax,(%esp)
f0102a9d:	e8 f4 0e 00 00       	call   f0103996 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102aa2:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102aa9:	00 
f0102aaa:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102ab1:	00 
f0102ab2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102ab6:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0102abb:	89 04 24             	mov    %eax,(%esp)
f0102abe:	e8 1d e7 ff ff       	call   f01011e0 <page_insert>
	assert(pp1->pp_ref == 1);
f0102ac3:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102ac8:	74 24                	je     f0102aee <mem_init+0x1867>
f0102aca:	c7 44 24 0c 5a 4c 10 	movl   $0xf0104c5a,0xc(%esp)
f0102ad1:	f0 
f0102ad2:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0102ad9:	f0 
f0102ada:	c7 44 24 04 99 03 00 	movl   $0x399,0x4(%esp)
f0102ae1:	00 
f0102ae2:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0102ae9:	e8 a6 d5 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102aee:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102af5:	01 01 01 
f0102af8:	74 24                	je     f0102b1e <mem_init+0x1897>
f0102afa:	c7 44 24 0c ec 49 10 	movl   $0xf01049ec,0xc(%esp)
f0102b01:	f0 
f0102b02:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0102b09:	f0 
f0102b0a:	c7 44 24 04 9a 03 00 	movl   $0x39a,0x4(%esp)
f0102b11:	00 
f0102b12:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0102b19:	e8 76 d5 ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102b1e:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102b25:	00 
f0102b26:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102b2d:	00 
f0102b2e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102b32:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0102b37:	89 04 24             	mov    %eax,(%esp)
f0102b3a:	e8 a1 e6 ff ff       	call   f01011e0 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102b3f:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102b46:	02 02 02 
f0102b49:	74 24                	je     f0102b6f <mem_init+0x18e8>
f0102b4b:	c7 44 24 0c 10 4a 10 	movl   $0xf0104a10,0xc(%esp)
f0102b52:	f0 
f0102b53:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0102b5a:	f0 
f0102b5b:	c7 44 24 04 9c 03 00 	movl   $0x39c,0x4(%esp)
f0102b62:	00 
f0102b63:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0102b6a:	e8 25 d5 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102b6f:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102b74:	74 24                	je     f0102b9a <mem_init+0x1913>
f0102b76:	c7 44 24 0c 7c 4c 10 	movl   $0xf0104c7c,0xc(%esp)
f0102b7d:	f0 
f0102b7e:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0102b85:	f0 
f0102b86:	c7 44 24 04 9d 03 00 	movl   $0x39d,0x4(%esp)
f0102b8d:	00 
f0102b8e:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0102b95:	e8 fa d4 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102b9a:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102b9f:	74 24                	je     f0102bc5 <mem_init+0x193e>
f0102ba1:	c7 44 24 0c c5 4c 10 	movl   $0xf0104cc5,0xc(%esp)
f0102ba8:	f0 
f0102ba9:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0102bb0:	f0 
f0102bb1:	c7 44 24 04 9e 03 00 	movl   $0x39e,0x4(%esp)
f0102bb8:	00 
f0102bb9:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0102bc0:	e8 cf d4 ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102bc5:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102bcc:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102bcf:	89 d8                	mov    %ebx,%eax
f0102bd1:	2b 05 a8 89 11 f0    	sub    0xf01189a8,%eax
f0102bd7:	c1 f8 03             	sar    $0x3,%eax
f0102bda:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102bdd:	89 c2                	mov    %eax,%edx
f0102bdf:	c1 ea 0c             	shr    $0xc,%edx
f0102be2:	3b 15 a0 89 11 f0    	cmp    0xf01189a0,%edx
f0102be8:	72 20                	jb     f0102c0a <mem_init+0x1983>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102bea:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102bee:	c7 44 24 08 a4 43 10 	movl   $0xf01043a4,0x8(%esp)
f0102bf5:	f0 
f0102bf6:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102bfd:	00 
f0102bfe:	c7 04 24 98 4a 10 f0 	movl   $0xf0104a98,(%esp)
f0102c05:	e8 8a d4 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102c0a:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102c11:	03 03 03 
f0102c14:	74 24                	je     f0102c3a <mem_init+0x19b3>
f0102c16:	c7 44 24 0c 34 4a 10 	movl   $0xf0104a34,0xc(%esp)
f0102c1d:	f0 
f0102c1e:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0102c25:	f0 
f0102c26:	c7 44 24 04 a0 03 00 	movl   $0x3a0,0x4(%esp)
f0102c2d:	00 
f0102c2e:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0102c35:	e8 5a d4 ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102c3a:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102c41:	00 
f0102c42:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0102c47:	89 04 24             	mov    %eax,(%esp)
f0102c4a:	e8 41 e5 ff ff       	call   f0101190 <page_remove>
	assert(pp2->pp_ref == 0);
f0102c4f:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102c54:	74 24                	je     f0102c7a <mem_init+0x19f3>
f0102c56:	c7 44 24 0c b4 4c 10 	movl   $0xf0104cb4,0xc(%esp)
f0102c5d:	f0 
f0102c5e:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0102c65:	f0 
f0102c66:	c7 44 24 04 a2 03 00 	movl   $0x3a2,0x4(%esp)
f0102c6d:	00 
f0102c6e:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0102c75:	e8 1a d4 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102c7a:	a1 a4 89 11 f0       	mov    0xf01189a4,%eax
f0102c7f:	8b 08                	mov    (%eax),%ecx
f0102c81:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102c87:	89 f2                	mov    %esi,%edx
f0102c89:	2b 15 a8 89 11 f0    	sub    0xf01189a8,%edx
f0102c8f:	c1 fa 03             	sar    $0x3,%edx
f0102c92:	c1 e2 0c             	shl    $0xc,%edx
f0102c95:	39 d1                	cmp    %edx,%ecx
f0102c97:	74 24                	je     f0102cbd <mem_init+0x1a36>
f0102c99:	c7 44 24 0c e4 45 10 	movl   $0xf01045e4,0xc(%esp)
f0102ca0:	f0 
f0102ca1:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0102ca8:	f0 
f0102ca9:	c7 44 24 04 a5 03 00 	movl   $0x3a5,0x4(%esp)
f0102cb0:	00 
f0102cb1:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0102cb8:	e8 d7 d3 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102cbd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102cc3:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102cc8:	74 24                	je     f0102cee <mem_init+0x1a67>
f0102cca:	c7 44 24 0c 6b 4c 10 	movl   $0xf0104c6b,0xc(%esp)
f0102cd1:	f0 
f0102cd2:	c7 44 24 08 b2 4a 10 	movl   $0xf0104ab2,0x8(%esp)
f0102cd9:	f0 
f0102cda:	c7 44 24 04 a7 03 00 	movl   $0x3a7,0x4(%esp)
f0102ce1:	00 
f0102ce2:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0102ce9:	e8 a6 d3 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102cee:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102cf4:	89 34 24             	mov    %esi,(%esp)
f0102cf7:	e8 2f e2 ff ff       	call   f0100f2b <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102cfc:	c7 04 24 60 4a 10 f0 	movl   $0xf0104a60,(%esp)
f0102d03:	e8 8a 00 00 00       	call   f0102d92 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102d08:	83 c4 3c             	add    $0x3c,%esp
f0102d0b:	5b                   	pop    %ebx
f0102d0c:	5e                   	pop    %esi
f0102d0d:	5f                   	pop    %edi
f0102d0e:	5d                   	pop    %ebp
f0102d0f:	c3                   	ret    
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102d10:	89 f2                	mov    %esi,%edx
f0102d12:	89 d8                	mov    %ebx,%eax
f0102d14:	e8 a5 dc ff ff       	call   f01009be <check_va2pa>
f0102d19:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102d1f:	e9 8e fa ff ff       	jmp    f01027b2 <mem_init+0x152b>

f0102d24 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102d24:	55                   	push   %ebp
f0102d25:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102d27:	ba 70 00 00 00       	mov    $0x70,%edx
f0102d2c:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d2f:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102d30:	b2 71                	mov    $0x71,%dl
f0102d32:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102d33:	0f b6 c0             	movzbl %al,%eax
}
f0102d36:	5d                   	pop    %ebp
f0102d37:	c3                   	ret    

f0102d38 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102d38:	55                   	push   %ebp
f0102d39:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102d3b:	ba 70 00 00 00       	mov    $0x70,%edx
f0102d40:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d43:	ee                   	out    %al,(%dx)
f0102d44:	b2 71                	mov    $0x71,%dl
f0102d46:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d49:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102d4a:	5d                   	pop    %ebp
f0102d4b:	c3                   	ret    

f0102d4c <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102d4c:	55                   	push   %ebp
f0102d4d:	89 e5                	mov    %esp,%ebp
f0102d4f:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0102d52:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d55:	89 04 24             	mov    %eax,(%esp)
f0102d58:	e8 94 d8 ff ff       	call   f01005f1 <cputchar>
	*cnt++;
}
f0102d5d:	c9                   	leave  
f0102d5e:	c3                   	ret    

f0102d5f <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102d5f:	55                   	push   %ebp
f0102d60:	89 e5                	mov    %esp,%ebp
f0102d62:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0102d65:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102d6c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d6f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102d73:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d76:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102d7a:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102d7d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d81:	c7 04 24 4c 2d 10 f0 	movl   $0xf0102d4c,(%esp)
f0102d88:	e8 6d 04 00 00       	call   f01031fa <vprintfmt>
	return cnt;
}
f0102d8d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102d90:	c9                   	leave  
f0102d91:	c3                   	ret    

f0102d92 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102d92:	55                   	push   %ebp
f0102d93:	89 e5                	mov    %esp,%ebp
f0102d95:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102d98:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102d9b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d9f:	8b 45 08             	mov    0x8(%ebp),%eax
f0102da2:	89 04 24             	mov    %eax,(%esp)
f0102da5:	e8 b5 ff ff ff       	call   f0102d5f <vcprintf>
	va_end(ap);

	return cnt;
}
f0102daa:	c9                   	leave  
f0102dab:	c3                   	ret    

f0102dac <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102dac:	55                   	push   %ebp
f0102dad:	89 e5                	mov    %esp,%ebp
f0102daf:	57                   	push   %edi
f0102db0:	56                   	push   %esi
f0102db1:	53                   	push   %ebx
f0102db2:	83 ec 10             	sub    $0x10,%esp
f0102db5:	89 c3                	mov    %eax,%ebx
f0102db7:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0102dba:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0102dbd:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102dc0:	8b 0a                	mov    (%edx),%ecx
f0102dc2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102dc5:	8b 00                	mov    (%eax),%eax
f0102dc7:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102dca:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f0102dd1:	eb 77                	jmp    f0102e4a <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f0102dd3:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102dd6:	01 c8                	add    %ecx,%eax
f0102dd8:	bf 02 00 00 00       	mov    $0x2,%edi
f0102ddd:	99                   	cltd   
f0102dde:	f7 ff                	idiv   %edi
f0102de0:	89 c2                	mov    %eax,%edx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102de2:	eb 01                	jmp    f0102de5 <stab_binsearch+0x39>
			m--;
f0102de4:	4a                   	dec    %edx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102de5:	39 ca                	cmp    %ecx,%edx
f0102de7:	7c 1d                	jl     f0102e06 <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0102de9:	6b fa 0c             	imul   $0xc,%edx,%edi
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102dec:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f0102df1:	39 f7                	cmp    %esi,%edi
f0102df3:	75 ef                	jne    f0102de4 <stab_binsearch+0x38>
f0102df5:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102df8:	6b fa 0c             	imul   $0xc,%edx,%edi
f0102dfb:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f0102dff:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0102e02:	73 18                	jae    f0102e1c <stab_binsearch+0x70>
f0102e04:	eb 05                	jmp    f0102e0b <stab_binsearch+0x5f>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102e06:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0102e09:	eb 3f                	jmp    f0102e4a <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0102e0b:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0102e0e:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0102e10:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102e13:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102e1a:	eb 2e                	jmp    f0102e4a <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102e1c:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0102e1f:	76 15                	jbe    f0102e36 <stab_binsearch+0x8a>
			*region_right = m - 1;
f0102e21:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0102e24:	4f                   	dec    %edi
f0102e25:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0102e28:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102e2b:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102e2d:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102e34:	eb 14                	jmp    f0102e4a <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102e36:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0102e39:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0102e3c:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f0102e3e:	ff 45 0c             	incl   0xc(%ebp)
f0102e41:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102e43:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0102e4a:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0102e4d:	7e 84                	jle    f0102dd3 <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102e4f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0102e53:	75 0d                	jne    f0102e62 <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0102e55:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102e58:	8b 02                	mov    (%edx),%eax
f0102e5a:	48                   	dec    %eax
f0102e5b:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102e5e:	89 01                	mov    %eax,(%ecx)
f0102e60:	eb 22                	jmp    f0102e84 <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102e62:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102e65:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102e67:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102e6a:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102e6c:	eb 01                	jmp    f0102e6f <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102e6e:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102e6f:	39 c1                	cmp    %eax,%ecx
f0102e71:	7d 0c                	jge    f0102e7f <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0102e73:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0102e76:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f0102e7b:	39 f2                	cmp    %esi,%edx
f0102e7d:	75 ef                	jne    f0102e6e <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102e7f:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102e82:	89 02                	mov    %eax,(%edx)
	}
}
f0102e84:	83 c4 10             	add    $0x10,%esp
f0102e87:	5b                   	pop    %ebx
f0102e88:	5e                   	pop    %esi
f0102e89:	5f                   	pop    %edi
f0102e8a:	5d                   	pop    %ebp
f0102e8b:	c3                   	ret    

f0102e8c <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102e8c:	55                   	push   %ebp
f0102e8d:	89 e5                	mov    %esp,%ebp
f0102e8f:	83 ec 38             	sub    $0x38,%esp
f0102e92:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0102e95:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0102e98:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0102e9b:	8b 75 08             	mov    0x8(%ebp),%esi
f0102e9e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102ea1:	c7 03 64 41 10 f0    	movl   $0xf0104164,(%ebx)
	info->eip_line = 0;
f0102ea7:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102eae:	c7 43 08 64 41 10 f0 	movl   $0xf0104164,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102eb5:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102ebc:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102ebf:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102ec6:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102ecc:	76 12                	jbe    f0102ee0 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102ece:	b8 44 d0 10 f0       	mov    $0xf010d044,%eax
f0102ed3:	3d 01 b2 10 f0       	cmp    $0xf010b201,%eax
f0102ed8:	0f 86 9b 01 00 00    	jbe    f0103079 <debuginfo_eip+0x1ed>
f0102ede:	eb 1c                	jmp    f0102efc <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102ee0:	c7 44 24 08 4e 4d 10 	movl   $0xf0104d4e,0x8(%esp)
f0102ee7:	f0 
f0102ee8:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0102eef:	00 
f0102ef0:	c7 04 24 5b 4d 10 f0 	movl   $0xf0104d5b,(%esp)
f0102ef7:	e8 98 d1 ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102efc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102f01:	80 3d 43 d0 10 f0 00 	cmpb   $0x0,0xf010d043
f0102f08:	0f 85 77 01 00 00    	jne    f0103085 <debuginfo_eip+0x1f9>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102f0e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102f15:	b8 00 b2 10 f0       	mov    $0xf010b200,%eax
f0102f1a:	2d 78 4f 10 f0       	sub    $0xf0104f78,%eax
f0102f1f:	c1 f8 02             	sar    $0x2,%eax
f0102f22:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102f28:	83 e8 01             	sub    $0x1,%eax
f0102f2b:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102f2e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102f32:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0102f39:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102f3c:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102f3f:	b8 78 4f 10 f0       	mov    $0xf0104f78,%eax
f0102f44:	e8 63 fe ff ff       	call   f0102dac <stab_binsearch>
	if (lfile == 0)
f0102f49:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0102f4c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0102f51:	85 d2                	test   %edx,%edx
f0102f53:	0f 84 2c 01 00 00    	je     f0103085 <debuginfo_eip+0x1f9>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102f59:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0102f5c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102f5f:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102f62:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102f66:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0102f6d:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102f70:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102f73:	b8 78 4f 10 f0       	mov    $0xf0104f78,%eax
f0102f78:	e8 2f fe ff ff       	call   f0102dac <stab_binsearch>

	if (lfun <= rfun) {
f0102f7d:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0102f80:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0102f83:	7f 2e                	jg     f0102fb3 <debuginfo_eip+0x127>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102f85:	6b c7 0c             	imul   $0xc,%edi,%eax
f0102f88:	8d 90 78 4f 10 f0    	lea    -0xfefb088(%eax),%edx
f0102f8e:	8b 80 78 4f 10 f0    	mov    -0xfefb088(%eax),%eax
f0102f94:	b9 44 d0 10 f0       	mov    $0xf010d044,%ecx
f0102f99:	81 e9 01 b2 10 f0    	sub    $0xf010b201,%ecx
f0102f9f:	39 c8                	cmp    %ecx,%eax
f0102fa1:	73 08                	jae    f0102fab <debuginfo_eip+0x11f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102fa3:	05 01 b2 10 f0       	add    $0xf010b201,%eax
f0102fa8:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102fab:	8b 42 08             	mov    0x8(%edx),%eax
f0102fae:	89 43 10             	mov    %eax,0x10(%ebx)
f0102fb1:	eb 06                	jmp    f0102fb9 <debuginfo_eip+0x12d>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102fb3:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102fb6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102fb9:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0102fc0:	00 
f0102fc1:	8b 43 08             	mov    0x8(%ebx),%eax
f0102fc4:	89 04 24             	mov    %eax,(%esp)
f0102fc7:	e8 a3 09 00 00       	call   f010396f <strfind>
f0102fcc:	2b 43 08             	sub    0x8(%ebx),%eax
f0102fcf:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102fd2:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102fd5:	39 d7                	cmp    %edx,%edi
f0102fd7:	7c 5f                	jl     f0103038 <debuginfo_eip+0x1ac>
	       && stabs[lline].n_type != N_SOL
f0102fd9:	89 f8                	mov    %edi,%eax
f0102fdb:	6b cf 0c             	imul   $0xc,%edi,%ecx
f0102fde:	80 b9 7c 4f 10 f0 84 	cmpb   $0x84,-0xfefb084(%ecx)
f0102fe5:	75 18                	jne    f0102fff <debuginfo_eip+0x173>
f0102fe7:	eb 30                	jmp    f0103019 <debuginfo_eip+0x18d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0102fe9:	83 ef 01             	sub    $0x1,%edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102fec:	39 fa                	cmp    %edi,%edx
f0102fee:	7f 48                	jg     f0103038 <debuginfo_eip+0x1ac>
	       && stabs[lline].n_type != N_SOL
f0102ff0:	89 f8                	mov    %edi,%eax
f0102ff2:	8d 0c 7f             	lea    (%edi,%edi,2),%ecx
f0102ff5:	80 3c 8d 7c 4f 10 f0 	cmpb   $0x84,-0xfefb084(,%ecx,4)
f0102ffc:	84 
f0102ffd:	74 1a                	je     f0103019 <debuginfo_eip+0x18d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102fff:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103002:	8d 04 85 78 4f 10 f0 	lea    -0xfefb088(,%eax,4),%eax
f0103009:	80 78 04 64          	cmpb   $0x64,0x4(%eax)
f010300d:	75 da                	jne    f0102fe9 <debuginfo_eip+0x15d>
f010300f:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0103013:	74 d4                	je     f0102fe9 <debuginfo_eip+0x15d>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103015:	39 fa                	cmp    %edi,%edx
f0103017:	7f 1f                	jg     f0103038 <debuginfo_eip+0x1ac>
f0103019:	6b ff 0c             	imul   $0xc,%edi,%edi
f010301c:	8b 87 78 4f 10 f0    	mov    -0xfefb088(%edi),%eax
f0103022:	ba 44 d0 10 f0       	mov    $0xf010d044,%edx
f0103027:	81 ea 01 b2 10 f0    	sub    $0xf010b201,%edx
f010302d:	39 d0                	cmp    %edx,%eax
f010302f:	73 07                	jae    f0103038 <debuginfo_eip+0x1ac>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103031:	05 01 b2 10 f0       	add    $0xf010b201,%eax
f0103036:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103038:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010303b:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f010303e:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103043:	39 ca                	cmp    %ecx,%edx
f0103045:	7d 3e                	jge    f0103085 <debuginfo_eip+0x1f9>
		for (lline = lfun + 1;
f0103047:	83 c2 01             	add    $0x1,%edx
f010304a:	39 d1                	cmp    %edx,%ecx
f010304c:	7e 37                	jle    f0103085 <debuginfo_eip+0x1f9>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010304e:	6b f2 0c             	imul   $0xc,%edx,%esi
f0103051:	80 be 7c 4f 10 f0 a0 	cmpb   $0xa0,-0xfefb084(%esi)
f0103058:	75 2b                	jne    f0103085 <debuginfo_eip+0x1f9>
		     lline++)
			info->eip_fn_narg++;
f010305a:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f010305e:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103061:	39 d1                	cmp    %edx,%ecx
f0103063:	7e 1b                	jle    f0103080 <debuginfo_eip+0x1f4>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103065:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0103068:	80 3c 85 7c 4f 10 f0 	cmpb   $0xa0,-0xfefb084(,%eax,4)
f010306f:	a0 
f0103070:	74 e8                	je     f010305a <debuginfo_eip+0x1ce>
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0103072:	b8 00 00 00 00       	mov    $0x0,%eax
f0103077:	eb 0c                	jmp    f0103085 <debuginfo_eip+0x1f9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103079:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010307e:	eb 05                	jmp    f0103085 <debuginfo_eip+0x1f9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0103080:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103085:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0103088:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010308b:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010308e:	89 ec                	mov    %ebp,%esp
f0103090:	5d                   	pop    %ebp
f0103091:	c3                   	ret    
	...

f01030a0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01030a0:	55                   	push   %ebp
f01030a1:	89 e5                	mov    %esp,%ebp
f01030a3:	57                   	push   %edi
f01030a4:	56                   	push   %esi
f01030a5:	53                   	push   %ebx
f01030a6:	83 ec 3c             	sub    $0x3c,%esp
f01030a9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01030ac:	89 d7                	mov    %edx,%edi
f01030ae:	8b 45 08             	mov    0x8(%ebp),%eax
f01030b1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01030b4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030b7:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01030ba:	8b 5d 14             	mov    0x14(%ebp),%ebx
f01030bd:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01030c0:	b8 00 00 00 00       	mov    $0x0,%eax
f01030c5:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f01030c8:	72 11                	jb     f01030db <printnum+0x3b>
f01030ca:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01030cd:	39 45 10             	cmp    %eax,0x10(%ebp)
f01030d0:	76 09                	jbe    f01030db <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01030d2:	83 eb 01             	sub    $0x1,%ebx
f01030d5:	85 db                	test   %ebx,%ebx
f01030d7:	7f 51                	jg     f010312a <printnum+0x8a>
f01030d9:	eb 5e                	jmp    f0103139 <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01030db:	89 74 24 10          	mov    %esi,0x10(%esp)
f01030df:	83 eb 01             	sub    $0x1,%ebx
f01030e2:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01030e6:	8b 45 10             	mov    0x10(%ebp),%eax
f01030e9:	89 44 24 08          	mov    %eax,0x8(%esp)
f01030ed:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f01030f1:	8b 74 24 0c          	mov    0xc(%esp),%esi
f01030f5:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01030fc:	00 
f01030fd:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103100:	89 04 24             	mov    %eax,(%esp)
f0103103:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103106:	89 44 24 04          	mov    %eax,0x4(%esp)
f010310a:	e8 e1 0a 00 00       	call   f0103bf0 <__udivdi3>
f010310f:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103113:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103117:	89 04 24             	mov    %eax,(%esp)
f010311a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010311e:	89 fa                	mov    %edi,%edx
f0103120:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103123:	e8 78 ff ff ff       	call   f01030a0 <printnum>
f0103128:	eb 0f                	jmp    f0103139 <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010312a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010312e:	89 34 24             	mov    %esi,(%esp)
f0103131:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103134:	83 eb 01             	sub    $0x1,%ebx
f0103137:	75 f1                	jne    f010312a <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103139:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010313d:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103141:	8b 45 10             	mov    0x10(%ebp),%eax
f0103144:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103148:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010314f:	00 
f0103150:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103153:	89 04 24             	mov    %eax,(%esp)
f0103156:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103159:	89 44 24 04          	mov    %eax,0x4(%esp)
f010315d:	e8 be 0b 00 00       	call   f0103d20 <__umoddi3>
f0103162:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103166:	0f be 80 69 4d 10 f0 	movsbl -0xfefb297(%eax),%eax
f010316d:	89 04 24             	mov    %eax,(%esp)
f0103170:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0103173:	83 c4 3c             	add    $0x3c,%esp
f0103176:	5b                   	pop    %ebx
f0103177:	5e                   	pop    %esi
f0103178:	5f                   	pop    %edi
f0103179:	5d                   	pop    %ebp
f010317a:	c3                   	ret    

f010317b <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f010317b:	55                   	push   %ebp
f010317c:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f010317e:	83 fa 01             	cmp    $0x1,%edx
f0103181:	7e 0e                	jle    f0103191 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103183:	8b 10                	mov    (%eax),%edx
f0103185:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103188:	89 08                	mov    %ecx,(%eax)
f010318a:	8b 02                	mov    (%edx),%eax
f010318c:	8b 52 04             	mov    0x4(%edx),%edx
f010318f:	eb 22                	jmp    f01031b3 <getuint+0x38>
	else if (lflag)
f0103191:	85 d2                	test   %edx,%edx
f0103193:	74 10                	je     f01031a5 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103195:	8b 10                	mov    (%eax),%edx
f0103197:	8d 4a 04             	lea    0x4(%edx),%ecx
f010319a:	89 08                	mov    %ecx,(%eax)
f010319c:	8b 02                	mov    (%edx),%eax
f010319e:	ba 00 00 00 00       	mov    $0x0,%edx
f01031a3:	eb 0e                	jmp    f01031b3 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01031a5:	8b 10                	mov    (%eax),%edx
f01031a7:	8d 4a 04             	lea    0x4(%edx),%ecx
f01031aa:	89 08                	mov    %ecx,(%eax)
f01031ac:	8b 02                	mov    (%edx),%eax
f01031ae:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01031b3:	5d                   	pop    %ebp
f01031b4:	c3                   	ret    

f01031b5 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01031b5:	55                   	push   %ebp
f01031b6:	89 e5                	mov    %esp,%ebp
f01031b8:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01031bb:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01031bf:	8b 10                	mov    (%eax),%edx
f01031c1:	3b 50 04             	cmp    0x4(%eax),%edx
f01031c4:	73 0a                	jae    f01031d0 <sprintputch+0x1b>
		*b->buf++ = ch;
f01031c6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01031c9:	88 0a                	mov    %cl,(%edx)
f01031cb:	83 c2 01             	add    $0x1,%edx
f01031ce:	89 10                	mov    %edx,(%eax)
}
f01031d0:	5d                   	pop    %ebp
f01031d1:	c3                   	ret    

f01031d2 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01031d2:	55                   	push   %ebp
f01031d3:	89 e5                	mov    %esp,%ebp
f01031d5:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f01031d8:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01031db:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01031df:	8b 45 10             	mov    0x10(%ebp),%eax
f01031e2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01031e6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01031e9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01031ed:	8b 45 08             	mov    0x8(%ebp),%eax
f01031f0:	89 04 24             	mov    %eax,(%esp)
f01031f3:	e8 02 00 00 00       	call   f01031fa <vprintfmt>
	va_end(ap);
}
f01031f8:	c9                   	leave  
f01031f9:	c3                   	ret    

f01031fa <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01031fa:	55                   	push   %ebp
f01031fb:	89 e5                	mov    %esp,%ebp
f01031fd:	57                   	push   %edi
f01031fe:	56                   	push   %esi
f01031ff:	53                   	push   %ebx
f0103200:	83 ec 3c             	sub    $0x3c,%esp
f0103203:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0103206:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103209:	e9 bb 00 00 00       	jmp    f01032c9 <vprintfmt+0xcf>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010320e:	85 c0                	test   %eax,%eax
f0103210:	0f 84 63 04 00 00    	je     f0103679 <vprintfmt+0x47f>
				return;
			if (ch =='\033'){//if this is Escape character  and this if is char color set.
f0103216:	83 f8 1b             	cmp    $0x1b,%eax
f0103219:	0f 85 9a 00 00 00    	jne    f01032b9 <vprintfmt+0xbf>
				int temp_color_no=0;
				ch = *(unsigned char *) fmt++;
f010321f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103222:	83 c3 02             	add    $0x2,%ebx
				while (ch != 'm') 
f0103225:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103228:	80 78 01 6d          	cmpb   $0x6d,0x1(%eax)
f010322c:	0f 84 81 00 00 00    	je     f01032b3 <vprintfmt+0xb9>
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
				return;
			if (ch =='\033'){//if this is Escape character  and this if is char color set.
				int temp_color_no=0;
f0103232:	ba 00 00 00 00       	mov    $0x0,%edx
				ch = *(unsigned char *) fmt++;
				while (ch != 'm') 
				{
					ch = *(unsigned char *) fmt++;
f0103237:	0f b6 03             	movzbl (%ebx),%eax
f010323a:	83 c3 01             	add    $0x1,%ebx
					if ( ch !=';' && ch!='m')
f010323d:	83 f8 6d             	cmp    $0x6d,%eax
f0103240:	0f 95 c1             	setne  %cl
f0103243:	83 f8 3b             	cmp    $0x3b,%eax
f0103246:	74 0d                	je     f0103255 <vprintfmt+0x5b>
f0103248:	84 c9                	test   %cl,%cl
f010324a:	74 09                	je     f0103255 <vprintfmt+0x5b>
						temp_color_no=temp_color_no*10+ch-'0';
f010324c:	8d 14 92             	lea    (%edx,%edx,4),%edx
f010324f:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
f0103253:	eb 55                	jmp    f01032aa <vprintfmt+0xb0>
					else if ( ch==';' || ch=='m'){
f0103255:	83 f8 3b             	cmp    $0x3b,%eax
f0103258:	74 05                	je     f010325f <vprintfmt+0x65>
f010325a:	83 f8 6d             	cmp    $0x6d,%eax
f010325d:	75 4b                	jne    f01032aa <vprintfmt+0xb0>
						if ( temp_color_no >=30 && temp_color_no<40){// Foreground colors
f010325f:	89 d6                	mov    %edx,%esi
f0103261:	8d 7a e2             	lea    -0x1e(%edx),%edi
f0103264:	83 ff 09             	cmp    $0x9,%edi
f0103267:	77 16                	ja     f010327f <vprintfmt+0x85>
							char_color = (char_color&0xf0) + (temp_color_no-30);						
f0103269:	8b 3d 00 83 11 f0    	mov    0xf0118300,%edi
f010326f:	81 e7 f0 00 00 00    	and    $0xf0,%edi
f0103275:	8d 7c 3a e2          	lea    -0x1e(%edx,%edi,1),%edi
f0103279:	89 3d 00 83 11 f0    	mov    %edi,0xf0118300
							}
						if ( temp_color_no >=40 && temp_color_no<50){// Background colors
f010327f:	83 ee 28             	sub    $0x28,%esi
f0103282:	83 fe 09             	cmp    $0x9,%esi
f0103285:	77 1e                	ja     f01032a5 <vprintfmt+0xab>
							char_color = (char_color&0x0f) + ((temp_color_no-40)<<4);
f0103287:	8b 35 00 83 11 f0    	mov    0xf0118300,%esi
f010328d:	83 e6 0f             	and    $0xf,%esi
f0103290:	83 ea 28             	sub    $0x28,%edx
f0103293:	c1 e2 04             	shl    $0x4,%edx
f0103296:	01 f2                	add    %esi,%edx
f0103298:	89 15 00 83 11 f0    	mov    %edx,0xf0118300
						}
						//cprintf("0x%o ,",char_color);
						temp_color_no=0;
f010329e:	ba 00 00 00 00       	mov    $0x0,%edx
f01032a3:	eb 05                	jmp    f01032aa <vprintfmt+0xb0>
f01032a5:	ba 00 00 00 00       	mov    $0x0,%edx
			if (ch == '\0')
				return;
			if (ch =='\033'){//if this is Escape character  and this if is char color set.
				int temp_color_no=0;
				ch = *(unsigned char *) fmt++;
				while (ch != 'm') 
f01032aa:	84 c9                	test   %cl,%cl
f01032ac:	75 89                	jne    f0103237 <vprintfmt+0x3d>
						}
						//cprintf("0x%o ,",char_color);
						temp_color_no=0;
					}
				}
				if (ch == 'm')
f01032ae:	83 f8 6d             	cmp    $0x6d,%eax
f01032b1:	75 06                	jne    f01032b9 <vprintfmt+0xbf>
					ch = *(unsigned char *) fmt++;
f01032b3:	0f b6 03             	movzbl (%ebx),%eax
f01032b6:	83 c3 01             	add    $0x1,%ebx
				
			}
			putch(ch, putdat);
f01032b9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01032bc:	89 54 24 04          	mov    %edx,0x4(%esp)
f01032c0:	89 04 24             	mov    %eax,(%esp)
f01032c3:	ff 55 08             	call   *0x8(%ebp)
f01032c6:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01032c9:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01032cc:	0f b6 03             	movzbl (%ebx),%eax
f01032cf:	83 c3 01             	add    $0x1,%ebx
f01032d2:	83 f8 25             	cmp    $0x25,%eax
f01032d5:	0f 85 33 ff ff ff    	jne    f010320e <vprintfmt+0x14>
f01032db:	c6 45 e0 20          	movb   $0x20,-0x20(%ebp)
f01032df:	bf 00 00 00 00       	mov    $0x0,%edi
f01032e4:	be ff ff ff ff       	mov    $0xffffffff,%esi
f01032e9:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f01032f0:	b9 00 00 00 00       	mov    $0x0,%ecx
f01032f5:	eb 23                	jmp    f010331a <vprintfmt+0x120>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032f7:	89 c3                	mov    %eax,%ebx

		// flag to pad on the right
		case '-':
			padc = '-';
f01032f9:	c6 45 e0 2d          	movb   $0x2d,-0x20(%ebp)
f01032fd:	eb 1b                	jmp    f010331a <vprintfmt+0x120>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032ff:	89 c3                	mov    %eax,%ebx
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103301:	c6 45 e0 30          	movb   $0x30,-0x20(%ebp)
f0103305:	eb 13                	jmp    f010331a <vprintfmt+0x120>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103307:	89 c3                	mov    %eax,%ebx
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0103309:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0103310:	eb 08                	jmp    f010331a <vprintfmt+0x120>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0103312:	89 75 dc             	mov    %esi,-0x24(%ebp)
f0103315:	be ff ff ff ff       	mov    $0xffffffff,%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010331a:	0f b6 13             	movzbl (%ebx),%edx
f010331d:	0f b6 c2             	movzbl %dl,%eax
f0103320:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103323:	8d 43 01             	lea    0x1(%ebx),%eax
f0103326:	83 ea 23             	sub    $0x23,%edx
f0103329:	80 fa 55             	cmp    $0x55,%dl
f010332c:	0f 87 18 03 00 00    	ja     f010364a <vprintfmt+0x450>
f0103332:	0f b6 d2             	movzbl %dl,%edx
f0103335:	ff 24 95 f4 4d 10 f0 	jmp    *-0xfefb20c(,%edx,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f010333c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010333f:	83 ee 30             	sub    $0x30,%esi
				ch = *fmt;
f0103342:	0f be 53 01          	movsbl 0x1(%ebx),%edx
				if (ch < '0' || ch > '9')
f0103346:	8d 5a d0             	lea    -0x30(%edx),%ebx
f0103349:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010334c:	89 c3                	mov    %eax,%ebx
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f010334e:	83 7d e4 09          	cmpl   $0x9,-0x1c(%ebp)
f0103352:	77 3b                	ja     f010338f <vprintfmt+0x195>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103354:	83 c0 01             	add    $0x1,%eax
				precision = precision * 10 + ch - '0';
f0103357:	8d 1c b6             	lea    (%esi,%esi,4),%ebx
f010335a:	8d 74 5a d0          	lea    -0x30(%edx,%ebx,2),%esi
				ch = *fmt;
f010335e:	0f be 10             	movsbl (%eax),%edx
				if (ch < '0' || ch > '9')
f0103361:	8d 5a d0             	lea    -0x30(%edx),%ebx
f0103364:	83 fb 09             	cmp    $0x9,%ebx
f0103367:	76 eb                	jbe    f0103354 <vprintfmt+0x15a>
f0103369:	eb 22                	jmp    f010338d <vprintfmt+0x193>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f010336b:	8b 55 14             	mov    0x14(%ebp),%edx
f010336e:	8d 5a 04             	lea    0x4(%edx),%ebx
f0103371:	89 5d 14             	mov    %ebx,0x14(%ebp)
f0103374:	8b 32                	mov    (%edx),%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103376:	89 c3                	mov    %eax,%ebx
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103378:	eb 15                	jmp    f010338f <vprintfmt+0x195>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010337a:	89 c3                	mov    %eax,%ebx
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f010337c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103380:	79 98                	jns    f010331a <vprintfmt+0x120>
f0103382:	eb 83                	jmp    f0103307 <vprintfmt+0x10d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103384:	89 c3                	mov    %eax,%ebx
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103386:	bf 01 00 00 00       	mov    $0x1,%edi
			goto reswitch;
f010338b:	eb 8d                	jmp    f010331a <vprintfmt+0x120>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f010338d:	89 c3                	mov    %eax,%ebx
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f010338f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103393:	79 85                	jns    f010331a <vprintfmt+0x120>
f0103395:	e9 78 ff ff ff       	jmp    f0103312 <vprintfmt+0x118>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f010339a:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010339d:	89 c3                	mov    %eax,%ebx
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010339f:	e9 76 ff ff ff       	jmp    f010331a <vprintfmt+0x120>
f01033a4:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01033a7:	8b 45 14             	mov    0x14(%ebp),%eax
f01033aa:	8d 50 04             	lea    0x4(%eax),%edx
f01033ad:	89 55 14             	mov    %edx,0x14(%ebp)
f01033b0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01033b3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01033b7:	8b 00                	mov    (%eax),%eax
f01033b9:	89 04 24             	mov    %eax,(%esp)
f01033bc:	ff 55 08             	call   *0x8(%ebp)
			break;
f01033bf:	e9 05 ff ff ff       	jmp    f01032c9 <vprintfmt+0xcf>
f01033c4:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// error message
		case 'e':
			err = va_arg(ap, int);
f01033c7:	8b 45 14             	mov    0x14(%ebp),%eax
f01033ca:	8d 50 04             	lea    0x4(%eax),%edx
f01033cd:	89 55 14             	mov    %edx,0x14(%ebp)
f01033d0:	8b 00                	mov    (%eax),%eax
f01033d2:	89 c2                	mov    %eax,%edx
f01033d4:	c1 fa 1f             	sar    $0x1f,%edx
f01033d7:	31 d0                	xor    %edx,%eax
f01033d9:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01033db:	83 f8 06             	cmp    $0x6,%eax
f01033de:	7f 0b                	jg     f01033eb <vprintfmt+0x1f1>
f01033e0:	8b 14 85 4c 4f 10 f0 	mov    -0xfefb0b4(,%eax,4),%edx
f01033e7:	85 d2                	test   %edx,%edx
f01033e9:	75 23                	jne    f010340e <vprintfmt+0x214>
				printfmt(putch, putdat, "error %d", err);
f01033eb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01033ef:	c7 44 24 08 81 4d 10 	movl   $0xf0104d81,0x8(%esp)
f01033f6:	f0 
f01033f7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01033fa:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01033fe:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103401:	89 1c 24             	mov    %ebx,(%esp)
f0103404:	e8 c9 fd ff ff       	call   f01031d2 <printfmt>
f0103409:	e9 bb fe ff ff       	jmp    f01032c9 <vprintfmt+0xcf>
			else
				printfmt(putch, putdat, "%s", p);
f010340e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103412:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0103419:	f0 
f010341a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010341d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103421:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103424:	89 1c 24             	mov    %ebx,(%esp)
f0103427:	e8 a6 fd ff ff       	call   f01031d2 <printfmt>
f010342c:	e9 98 fe ff ff       	jmp    f01032c9 <vprintfmt+0xcf>
f0103431:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103434:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103437:	89 5d d8             	mov    %ebx,-0x28(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010343a:	8b 45 14             	mov    0x14(%ebp),%eax
f010343d:	8d 50 04             	lea    0x4(%eax),%edx
f0103440:	89 55 14             	mov    %edx,0x14(%ebp)
f0103443:	8b 18                	mov    (%eax),%ebx
				p = "(null)";
f0103445:	85 db                	test   %ebx,%ebx
f0103447:	b8 7a 4d 10 f0       	mov    $0xf0104d7a,%eax
f010344c:	0f 44 d8             	cmove  %eax,%ebx
			if (width > 0 && padc != '-')
f010344f:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103453:	7e 06                	jle    f010345b <vprintfmt+0x261>
f0103455:	80 7d e0 2d          	cmpb   $0x2d,-0x20(%ebp)
f0103459:	75 10                	jne    f010346b <vprintfmt+0x271>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010345b:	0f be 03             	movsbl (%ebx),%eax
f010345e:	83 c3 01             	add    $0x1,%ebx
f0103461:	85 c0                	test   %eax,%eax
f0103463:	0f 85 82 00 00 00    	jne    f01034eb <vprintfmt+0x2f1>
f0103469:	eb 75                	jmp    f01034e0 <vprintfmt+0x2e6>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010346b:	89 74 24 04          	mov    %esi,0x4(%esp)
f010346f:	89 1c 24             	mov    %ebx,(%esp)
f0103472:	e8 84 03 00 00       	call   f01037fb <strnlen>
f0103477:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010347a:	29 c2                	sub    %eax,%edx
f010347c:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010347f:	85 d2                	test   %edx,%edx
f0103481:	7e d8                	jle    f010345b <vprintfmt+0x261>
					putch(padc, putdat);
f0103483:	0f be 45 e0          	movsbl -0x20(%ebp),%eax
f0103487:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010348a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010348d:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103491:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103494:	89 04 24             	mov    %eax,(%esp)
f0103497:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010349a:	83 6d dc 01          	subl   $0x1,-0x24(%ebp)
f010349e:	75 ea                	jne    f010348a <vprintfmt+0x290>
f01034a0:	eb b9                	jmp    f010345b <vprintfmt+0x261>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01034a2:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01034a6:	74 1b                	je     f01034c3 <vprintfmt+0x2c9>
f01034a8:	8d 50 e0             	lea    -0x20(%eax),%edx
f01034ab:	83 fa 5e             	cmp    $0x5e,%edx
f01034ae:	76 13                	jbe    f01034c3 <vprintfmt+0x2c9>
					putch('?', putdat);
f01034b0:	8b 55 0c             	mov    0xc(%ebp),%edx
f01034b3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01034b7:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01034be:	ff 55 08             	call   *0x8(%ebp)
f01034c1:	eb 0d                	jmp    f01034d0 <vprintfmt+0x2d6>
				else
					putch(ch, putdat);
f01034c3:	8b 55 0c             	mov    0xc(%ebp),%edx
f01034c6:	89 54 24 04          	mov    %edx,0x4(%esp)
f01034ca:	89 04 24             	mov    %eax,(%esp)
f01034cd:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01034d0:	83 ef 01             	sub    $0x1,%edi
f01034d3:	0f be 03             	movsbl (%ebx),%eax
f01034d6:	83 c3 01             	add    $0x1,%ebx
f01034d9:	85 c0                	test   %eax,%eax
f01034db:	75 14                	jne    f01034f1 <vprintfmt+0x2f7>
f01034dd:	89 7d dc             	mov    %edi,-0x24(%ebp)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01034e0:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01034e4:	7f 19                	jg     f01034ff <vprintfmt+0x305>
f01034e6:	e9 de fd ff ff       	jmp    f01032c9 <vprintfmt+0xcf>
f01034eb:	89 7d e0             	mov    %edi,-0x20(%ebp)
f01034ee:	8b 7d dc             	mov    -0x24(%ebp),%edi
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01034f1:	85 f6                	test   %esi,%esi
f01034f3:	78 ad                	js     f01034a2 <vprintfmt+0x2a8>
f01034f5:	83 ee 01             	sub    $0x1,%esi
f01034f8:	79 a8                	jns    f01034a2 <vprintfmt+0x2a8>
f01034fa:	89 7d dc             	mov    %edi,-0x24(%ebp)
f01034fd:	eb e1                	jmp    f01034e0 <vprintfmt+0x2e6>
f01034ff:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103502:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103505:	8b 75 0c             	mov    0xc(%ebp),%esi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103508:	89 74 24 04          	mov    %esi,0x4(%esp)
f010350c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0103513:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103515:	83 eb 01             	sub    $0x1,%ebx
f0103518:	75 ee                	jne    f0103508 <vprintfmt+0x30e>
f010351a:	e9 aa fd ff ff       	jmp    f01032c9 <vprintfmt+0xcf>
f010351f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103522:	83 f9 01             	cmp    $0x1,%ecx
f0103525:	7e 10                	jle    f0103537 <vprintfmt+0x33d>
		return va_arg(*ap, long long);
f0103527:	8b 45 14             	mov    0x14(%ebp),%eax
f010352a:	8d 50 08             	lea    0x8(%eax),%edx
f010352d:	89 55 14             	mov    %edx,0x14(%ebp)
f0103530:	8b 30                	mov    (%eax),%esi
f0103532:	8b 78 04             	mov    0x4(%eax),%edi
f0103535:	eb 26                	jmp    f010355d <vprintfmt+0x363>
	else if (lflag)
f0103537:	85 c9                	test   %ecx,%ecx
f0103539:	74 12                	je     f010354d <vprintfmt+0x353>
		return va_arg(*ap, long);
f010353b:	8b 45 14             	mov    0x14(%ebp),%eax
f010353e:	8d 50 04             	lea    0x4(%eax),%edx
f0103541:	89 55 14             	mov    %edx,0x14(%ebp)
f0103544:	8b 30                	mov    (%eax),%esi
f0103546:	89 f7                	mov    %esi,%edi
f0103548:	c1 ff 1f             	sar    $0x1f,%edi
f010354b:	eb 10                	jmp    f010355d <vprintfmt+0x363>
	else
		return va_arg(*ap, int);
f010354d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103550:	8d 50 04             	lea    0x4(%eax),%edx
f0103553:	89 55 14             	mov    %edx,0x14(%ebp)
f0103556:	8b 30                	mov    (%eax),%esi
f0103558:	89 f7                	mov    %esi,%edi
f010355a:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010355d:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103562:	85 ff                	test   %edi,%edi
f0103564:	0f 89 9e 00 00 00    	jns    f0103608 <vprintfmt+0x40e>
				putch('-', putdat);
f010356a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010356d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103571:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0103578:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010357b:	f7 de                	neg    %esi
f010357d:	83 d7 00             	adc    $0x0,%edi
f0103580:	f7 df                	neg    %edi
			}
			base = 10;
f0103582:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103587:	eb 7f                	jmp    f0103608 <vprintfmt+0x40e>
f0103589:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f010358c:	89 ca                	mov    %ecx,%edx
f010358e:	8d 45 14             	lea    0x14(%ebp),%eax
f0103591:	e8 e5 fb ff ff       	call   f010317b <getuint>
f0103596:	89 c6                	mov    %eax,%esi
f0103598:	89 d7                	mov    %edx,%edi
			base = 10;
f010359a:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f010359f:	eb 67                	jmp    f0103608 <vprintfmt+0x40e>
f01035a1:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap,lflag);
f01035a4:	89 ca                	mov    %ecx,%edx
f01035a6:	8d 45 14             	lea    0x14(%ebp),%eax
f01035a9:	e8 cd fb ff ff       	call   f010317b <getuint>
f01035ae:	89 c6                	mov    %eax,%esi
f01035b0:	89 d7                	mov    %edx,%edi
			base = 8;
f01035b2:	b8 08 00 00 00       	mov    $0x8,%eax

			goto number;
f01035b7:	eb 4f                	jmp    f0103608 <vprintfmt+0x40e>
f01035b9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// pointer
		case 'p':
			putch('0', putdat);
f01035bc:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01035bf:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01035c3:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01035ca:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01035cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01035d1:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01035d8:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01035db:	8b 45 14             	mov    0x14(%ebp),%eax
f01035de:	8d 50 04             	lea    0x4(%eax),%edx
f01035e1:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01035e4:	8b 30                	mov    (%eax),%esi
f01035e6:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01035eb:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f01035f0:	eb 16                	jmp    f0103608 <vprintfmt+0x40e>
f01035f2:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01035f5:	89 ca                	mov    %ecx,%edx
f01035f7:	8d 45 14             	lea    0x14(%ebp),%eax
f01035fa:	e8 7c fb ff ff       	call   f010317b <getuint>
f01035ff:	89 c6                	mov    %eax,%esi
f0103601:	89 d7                	mov    %edx,%edi
			base = 16;
f0103603:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103608:	0f be 55 e0          	movsbl -0x20(%ebp),%edx
f010360c:	89 54 24 10          	mov    %edx,0x10(%esp)
f0103610:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103613:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103617:	89 44 24 08          	mov    %eax,0x8(%esp)
f010361b:	89 34 24             	mov    %esi,(%esp)
f010361e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103622:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103625:	8b 45 08             	mov    0x8(%ebp),%eax
f0103628:	e8 73 fa ff ff       	call   f01030a0 <printnum>
			break;
f010362d:	e9 97 fc ff ff       	jmp    f01032c9 <vprintfmt+0xcf>
f0103632:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103635:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103638:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010363b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010363f:	89 14 24             	mov    %edx,(%esp)
f0103642:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103645:	e9 7f fc ff ff       	jmp    f01032c9 <vprintfmt+0xcf>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010364a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010364d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103651:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0103658:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f010365b:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f010365e:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0103662:	0f 84 61 fc ff ff    	je     f01032c9 <vprintfmt+0xcf>
f0103668:	83 eb 01             	sub    $0x1,%ebx
f010366b:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f010366f:	75 f7                	jne    f0103668 <vprintfmt+0x46e>
f0103671:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103674:	e9 50 fc ff ff       	jmp    f01032c9 <vprintfmt+0xcf>
				/* do nothing */;
			break;
		}
	}
}
f0103679:	83 c4 3c             	add    $0x3c,%esp
f010367c:	5b                   	pop    %ebx
f010367d:	5e                   	pop    %esi
f010367e:	5f                   	pop    %edi
f010367f:	5d                   	pop    %ebp
f0103680:	c3                   	ret    

f0103681 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103681:	55                   	push   %ebp
f0103682:	89 e5                	mov    %esp,%ebp
f0103684:	83 ec 28             	sub    $0x28,%esp
f0103687:	8b 45 08             	mov    0x8(%ebp),%eax
f010368a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010368d:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103690:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103694:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103697:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010369e:	85 c0                	test   %eax,%eax
f01036a0:	74 30                	je     f01036d2 <vsnprintf+0x51>
f01036a2:	85 d2                	test   %edx,%edx
f01036a4:	7e 2c                	jle    f01036d2 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01036a6:	8b 45 14             	mov    0x14(%ebp),%eax
f01036a9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01036ad:	8b 45 10             	mov    0x10(%ebp),%eax
f01036b0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01036b4:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01036b7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036bb:	c7 04 24 b5 31 10 f0 	movl   $0xf01031b5,(%esp)
f01036c2:	e8 33 fb ff ff       	call   f01031fa <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01036c7:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01036ca:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01036cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01036d0:	eb 05                	jmp    f01036d7 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01036d2:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01036d7:	c9                   	leave  
f01036d8:	c3                   	ret    

f01036d9 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01036d9:	55                   	push   %ebp
f01036da:	89 e5                	mov    %esp,%ebp
f01036dc:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01036df:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01036e2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01036e6:	8b 45 10             	mov    0x10(%ebp),%eax
f01036e9:	89 44 24 08          	mov    %eax,0x8(%esp)
f01036ed:	8b 45 0c             	mov    0xc(%ebp),%eax
f01036f0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036f4:	8b 45 08             	mov    0x8(%ebp),%eax
f01036f7:	89 04 24             	mov    %eax,(%esp)
f01036fa:	e8 82 ff ff ff       	call   f0103681 <vsnprintf>
	va_end(ap);

	return rc;
}
f01036ff:	c9                   	leave  
f0103700:	c3                   	ret    
	...

f0103710 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103710:	55                   	push   %ebp
f0103711:	89 e5                	mov    %esp,%ebp
f0103713:	57                   	push   %edi
f0103714:	56                   	push   %esi
f0103715:	53                   	push   %ebx
f0103716:	83 ec 1c             	sub    $0x1c,%esp
f0103719:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010371c:	85 c0                	test   %eax,%eax
f010371e:	74 10                	je     f0103730 <readline+0x20>
		cprintf("%s", prompt);
f0103720:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103724:	c7 04 24 c4 4a 10 f0 	movl   $0xf0104ac4,(%esp)
f010372b:	e8 62 f6 ff ff       	call   f0102d92 <cprintf>

	i = 0;
	echoing = iscons(0);
f0103730:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103737:	e8 d6 ce ff ff       	call   f0100612 <iscons>
f010373c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010373e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103743:	e8 b9 ce ff ff       	call   f0100601 <getchar>
f0103748:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010374a:	85 c0                	test   %eax,%eax
f010374c:	79 17                	jns    f0103765 <readline+0x55>
			cprintf("read error: %e\n", c);
f010374e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103752:	c7 04 24 68 4f 10 f0 	movl   $0xf0104f68,(%esp)
f0103759:	e8 34 f6 ff ff       	call   f0102d92 <cprintf>
			return NULL;
f010375e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103763:	eb 6d                	jmp    f01037d2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103765:	83 f8 08             	cmp    $0x8,%eax
f0103768:	74 05                	je     f010376f <readline+0x5f>
f010376a:	83 f8 7f             	cmp    $0x7f,%eax
f010376d:	75 19                	jne    f0103788 <readline+0x78>
f010376f:	85 f6                	test   %esi,%esi
f0103771:	7e 15                	jle    f0103788 <readline+0x78>
			if (echoing)
f0103773:	85 ff                	test   %edi,%edi
f0103775:	74 0c                	je     f0103783 <readline+0x73>
				cputchar('\b');
f0103777:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010377e:	e8 6e ce ff ff       	call   f01005f1 <cputchar>
			i--;
f0103783:	83 ee 01             	sub    $0x1,%esi
f0103786:	eb bb                	jmp    f0103743 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103788:	83 fb 1f             	cmp    $0x1f,%ebx
f010378b:	7e 1f                	jle    f01037ac <readline+0x9c>
f010378d:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103793:	7f 17                	jg     f01037ac <readline+0x9c>
			if (echoing)
f0103795:	85 ff                	test   %edi,%edi
f0103797:	74 08                	je     f01037a1 <readline+0x91>
				cputchar(c);
f0103799:	89 1c 24             	mov    %ebx,(%esp)
f010379c:	e8 50 ce ff ff       	call   f01005f1 <cputchar>
			buf[i++] = c;
f01037a1:	88 9e a0 85 11 f0    	mov    %bl,-0xfee7a60(%esi)
f01037a7:	83 c6 01             	add    $0x1,%esi
f01037aa:	eb 97                	jmp    f0103743 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01037ac:	83 fb 0a             	cmp    $0xa,%ebx
f01037af:	74 05                	je     f01037b6 <readline+0xa6>
f01037b1:	83 fb 0d             	cmp    $0xd,%ebx
f01037b4:	75 8d                	jne    f0103743 <readline+0x33>
			if (echoing)
f01037b6:	85 ff                	test   %edi,%edi
f01037b8:	74 0c                	je     f01037c6 <readline+0xb6>
				cputchar('\n');
f01037ba:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01037c1:	e8 2b ce ff ff       	call   f01005f1 <cputchar>
			buf[i] = 0;
f01037c6:	c6 86 a0 85 11 f0 00 	movb   $0x0,-0xfee7a60(%esi)
			return buf;
f01037cd:	b8 a0 85 11 f0       	mov    $0xf01185a0,%eax
		}
	}
}
f01037d2:	83 c4 1c             	add    $0x1c,%esp
f01037d5:	5b                   	pop    %ebx
f01037d6:	5e                   	pop    %esi
f01037d7:	5f                   	pop    %edi
f01037d8:	5d                   	pop    %ebp
f01037d9:	c3                   	ret    
f01037da:	00 00                	add    %al,(%eax)
f01037dc:	00 00                	add    %al,(%eax)
	...

f01037e0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01037e0:	55                   	push   %ebp
f01037e1:	89 e5                	mov    %esp,%ebp
f01037e3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01037e6:	b8 00 00 00 00       	mov    $0x0,%eax
f01037eb:	80 3a 00             	cmpb   $0x0,(%edx)
f01037ee:	74 09                	je     f01037f9 <strlen+0x19>
		n++;
f01037f0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01037f3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01037f7:	75 f7                	jne    f01037f0 <strlen+0x10>
		n++;
	return n;
}
f01037f9:	5d                   	pop    %ebp
f01037fa:	c3                   	ret    

f01037fb <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01037fb:	55                   	push   %ebp
f01037fc:	89 e5                	mov    %esp,%ebp
f01037fe:	53                   	push   %ebx
f01037ff:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103802:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103805:	b8 00 00 00 00       	mov    $0x0,%eax
f010380a:	85 c9                	test   %ecx,%ecx
f010380c:	74 1a                	je     f0103828 <strnlen+0x2d>
f010380e:	80 3b 00             	cmpb   $0x0,(%ebx)
f0103811:	74 15                	je     f0103828 <strnlen+0x2d>
f0103813:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f0103818:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010381a:	39 ca                	cmp    %ecx,%edx
f010381c:	74 0a                	je     f0103828 <strnlen+0x2d>
f010381e:	83 c2 01             	add    $0x1,%edx
f0103821:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0103826:	75 f0                	jne    f0103818 <strnlen+0x1d>
		n++;
	return n;
}
f0103828:	5b                   	pop    %ebx
f0103829:	5d                   	pop    %ebp
f010382a:	c3                   	ret    

f010382b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010382b:	55                   	push   %ebp
f010382c:	89 e5                	mov    %esp,%ebp
f010382e:	53                   	push   %ebx
f010382f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103832:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103835:	ba 00 00 00 00       	mov    $0x0,%edx
f010383a:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f010383e:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0103841:	83 c2 01             	add    $0x1,%edx
f0103844:	84 c9                	test   %cl,%cl
f0103846:	75 f2                	jne    f010383a <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0103848:	5b                   	pop    %ebx
f0103849:	5d                   	pop    %ebp
f010384a:	c3                   	ret    

f010384b <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010384b:	55                   	push   %ebp
f010384c:	89 e5                	mov    %esp,%ebp
f010384e:	56                   	push   %esi
f010384f:	53                   	push   %ebx
f0103850:	8b 45 08             	mov    0x8(%ebp),%eax
f0103853:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103856:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103859:	85 f6                	test   %esi,%esi
f010385b:	74 18                	je     f0103875 <strncpy+0x2a>
f010385d:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f0103862:	0f b6 1a             	movzbl (%edx),%ebx
f0103865:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103868:	80 3a 01             	cmpb   $0x1,(%edx)
f010386b:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010386e:	83 c1 01             	add    $0x1,%ecx
f0103871:	39 f1                	cmp    %esi,%ecx
f0103873:	75 ed                	jne    f0103862 <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103875:	5b                   	pop    %ebx
f0103876:	5e                   	pop    %esi
f0103877:	5d                   	pop    %ebp
f0103878:	c3                   	ret    

f0103879 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103879:	55                   	push   %ebp
f010387a:	89 e5                	mov    %esp,%ebp
f010387c:	57                   	push   %edi
f010387d:	56                   	push   %esi
f010387e:	53                   	push   %ebx
f010387f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103882:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103885:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103888:	89 f8                	mov    %edi,%eax
f010388a:	85 f6                	test   %esi,%esi
f010388c:	74 2b                	je     f01038b9 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f010388e:	83 fe 01             	cmp    $0x1,%esi
f0103891:	74 23                	je     f01038b6 <strlcpy+0x3d>
f0103893:	0f b6 0b             	movzbl (%ebx),%ecx
f0103896:	84 c9                	test   %cl,%cl
f0103898:	74 1c                	je     f01038b6 <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f010389a:	83 ee 02             	sub    $0x2,%esi
f010389d:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01038a2:	88 08                	mov    %cl,(%eax)
f01038a4:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01038a7:	39 f2                	cmp    %esi,%edx
f01038a9:	74 0b                	je     f01038b6 <strlcpy+0x3d>
f01038ab:	83 c2 01             	add    $0x1,%edx
f01038ae:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01038b2:	84 c9                	test   %cl,%cl
f01038b4:	75 ec                	jne    f01038a2 <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f01038b6:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01038b9:	29 f8                	sub    %edi,%eax
}
f01038bb:	5b                   	pop    %ebx
f01038bc:	5e                   	pop    %esi
f01038bd:	5f                   	pop    %edi
f01038be:	5d                   	pop    %ebp
f01038bf:	c3                   	ret    

f01038c0 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01038c0:	55                   	push   %ebp
f01038c1:	89 e5                	mov    %esp,%ebp
f01038c3:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01038c6:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01038c9:	0f b6 01             	movzbl (%ecx),%eax
f01038cc:	84 c0                	test   %al,%al
f01038ce:	74 16                	je     f01038e6 <strcmp+0x26>
f01038d0:	3a 02                	cmp    (%edx),%al
f01038d2:	75 12                	jne    f01038e6 <strcmp+0x26>
		p++, q++;
f01038d4:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01038d7:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f01038db:	84 c0                	test   %al,%al
f01038dd:	74 07                	je     f01038e6 <strcmp+0x26>
f01038df:	83 c1 01             	add    $0x1,%ecx
f01038e2:	3a 02                	cmp    (%edx),%al
f01038e4:	74 ee                	je     f01038d4 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01038e6:	0f b6 c0             	movzbl %al,%eax
f01038e9:	0f b6 12             	movzbl (%edx),%edx
f01038ec:	29 d0                	sub    %edx,%eax
}
f01038ee:	5d                   	pop    %ebp
f01038ef:	c3                   	ret    

f01038f0 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01038f0:	55                   	push   %ebp
f01038f1:	89 e5                	mov    %esp,%ebp
f01038f3:	53                   	push   %ebx
f01038f4:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01038f7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01038fa:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01038fd:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103902:	85 d2                	test   %edx,%edx
f0103904:	74 28                	je     f010392e <strncmp+0x3e>
f0103906:	0f b6 01             	movzbl (%ecx),%eax
f0103909:	84 c0                	test   %al,%al
f010390b:	74 24                	je     f0103931 <strncmp+0x41>
f010390d:	3a 03                	cmp    (%ebx),%al
f010390f:	75 20                	jne    f0103931 <strncmp+0x41>
f0103911:	83 ea 01             	sub    $0x1,%edx
f0103914:	74 13                	je     f0103929 <strncmp+0x39>
		n--, p++, q++;
f0103916:	83 c1 01             	add    $0x1,%ecx
f0103919:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010391c:	0f b6 01             	movzbl (%ecx),%eax
f010391f:	84 c0                	test   %al,%al
f0103921:	74 0e                	je     f0103931 <strncmp+0x41>
f0103923:	3a 03                	cmp    (%ebx),%al
f0103925:	74 ea                	je     f0103911 <strncmp+0x21>
f0103927:	eb 08                	jmp    f0103931 <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103929:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010392e:	5b                   	pop    %ebx
f010392f:	5d                   	pop    %ebp
f0103930:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103931:	0f b6 01             	movzbl (%ecx),%eax
f0103934:	0f b6 13             	movzbl (%ebx),%edx
f0103937:	29 d0                	sub    %edx,%eax
f0103939:	eb f3                	jmp    f010392e <strncmp+0x3e>

f010393b <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010393b:	55                   	push   %ebp
f010393c:	89 e5                	mov    %esp,%ebp
f010393e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103941:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103945:	0f b6 10             	movzbl (%eax),%edx
f0103948:	84 d2                	test   %dl,%dl
f010394a:	74 1c                	je     f0103968 <strchr+0x2d>
		if (*s == c)
f010394c:	38 ca                	cmp    %cl,%dl
f010394e:	75 09                	jne    f0103959 <strchr+0x1e>
f0103950:	eb 1b                	jmp    f010396d <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103952:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f0103955:	38 ca                	cmp    %cl,%dl
f0103957:	74 14                	je     f010396d <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103959:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f010395d:	84 d2                	test   %dl,%dl
f010395f:	75 f1                	jne    f0103952 <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f0103961:	b8 00 00 00 00       	mov    $0x0,%eax
f0103966:	eb 05                	jmp    f010396d <strchr+0x32>
f0103968:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010396d:	5d                   	pop    %ebp
f010396e:	c3                   	ret    

f010396f <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010396f:	55                   	push   %ebp
f0103970:	89 e5                	mov    %esp,%ebp
f0103972:	8b 45 08             	mov    0x8(%ebp),%eax
f0103975:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103979:	0f b6 10             	movzbl (%eax),%edx
f010397c:	84 d2                	test   %dl,%dl
f010397e:	74 14                	je     f0103994 <strfind+0x25>
		if (*s == c)
f0103980:	38 ca                	cmp    %cl,%dl
f0103982:	75 06                	jne    f010398a <strfind+0x1b>
f0103984:	eb 0e                	jmp    f0103994 <strfind+0x25>
f0103986:	38 ca                	cmp    %cl,%dl
f0103988:	74 0a                	je     f0103994 <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010398a:	83 c0 01             	add    $0x1,%eax
f010398d:	0f b6 10             	movzbl (%eax),%edx
f0103990:	84 d2                	test   %dl,%dl
f0103992:	75 f2                	jne    f0103986 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f0103994:	5d                   	pop    %ebp
f0103995:	c3                   	ret    

f0103996 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103996:	55                   	push   %ebp
f0103997:	89 e5                	mov    %esp,%ebp
f0103999:	83 ec 0c             	sub    $0xc,%esp
f010399c:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010399f:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01039a2:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01039a5:	8b 7d 08             	mov    0x8(%ebp),%edi
f01039a8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01039ab:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01039ae:	85 c9                	test   %ecx,%ecx
f01039b0:	74 30                	je     f01039e2 <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01039b2:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01039b8:	75 25                	jne    f01039df <memset+0x49>
f01039ba:	f6 c1 03             	test   $0x3,%cl
f01039bd:	75 20                	jne    f01039df <memset+0x49>
		c &= 0xFF;
f01039bf:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01039c2:	89 d3                	mov    %edx,%ebx
f01039c4:	c1 e3 08             	shl    $0x8,%ebx
f01039c7:	89 d6                	mov    %edx,%esi
f01039c9:	c1 e6 18             	shl    $0x18,%esi
f01039cc:	89 d0                	mov    %edx,%eax
f01039ce:	c1 e0 10             	shl    $0x10,%eax
f01039d1:	09 f0                	or     %esi,%eax
f01039d3:	09 d0                	or     %edx,%eax
f01039d5:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01039d7:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01039da:	fc                   	cld    
f01039db:	f3 ab                	rep stos %eax,%es:(%edi)
f01039dd:	eb 03                	jmp    f01039e2 <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01039df:	fc                   	cld    
f01039e0:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01039e2:	89 f8                	mov    %edi,%eax
f01039e4:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01039e7:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01039ea:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01039ed:	89 ec                	mov    %ebp,%esp
f01039ef:	5d                   	pop    %ebp
f01039f0:	c3                   	ret    

f01039f1 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01039f1:	55                   	push   %ebp
f01039f2:	89 e5                	mov    %esp,%ebp
f01039f4:	83 ec 08             	sub    $0x8,%esp
f01039f7:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01039fa:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01039fd:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a00:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103a03:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103a06:	39 c6                	cmp    %eax,%esi
f0103a08:	73 36                	jae    f0103a40 <memmove+0x4f>
f0103a0a:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103a0d:	39 d0                	cmp    %edx,%eax
f0103a0f:	73 2f                	jae    f0103a40 <memmove+0x4f>
		s += n;
		d += n;
f0103a11:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103a14:	f6 c2 03             	test   $0x3,%dl
f0103a17:	75 1b                	jne    f0103a34 <memmove+0x43>
f0103a19:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103a1f:	75 13                	jne    f0103a34 <memmove+0x43>
f0103a21:	f6 c1 03             	test   $0x3,%cl
f0103a24:	75 0e                	jne    f0103a34 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103a26:	83 ef 04             	sub    $0x4,%edi
f0103a29:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103a2c:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0103a2f:	fd                   	std    
f0103a30:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103a32:	eb 09                	jmp    f0103a3d <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0103a34:	83 ef 01             	sub    $0x1,%edi
f0103a37:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103a3a:	fd                   	std    
f0103a3b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103a3d:	fc                   	cld    
f0103a3e:	eb 20                	jmp    f0103a60 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103a40:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103a46:	75 13                	jne    f0103a5b <memmove+0x6a>
f0103a48:	a8 03                	test   $0x3,%al
f0103a4a:	75 0f                	jne    f0103a5b <memmove+0x6a>
f0103a4c:	f6 c1 03             	test   $0x3,%cl
f0103a4f:	75 0a                	jne    f0103a5b <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103a51:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0103a54:	89 c7                	mov    %eax,%edi
f0103a56:	fc                   	cld    
f0103a57:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103a59:	eb 05                	jmp    f0103a60 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103a5b:	89 c7                	mov    %eax,%edi
f0103a5d:	fc                   	cld    
f0103a5e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103a60:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0103a63:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0103a66:	89 ec                	mov    %ebp,%esp
f0103a68:	5d                   	pop    %ebp
f0103a69:	c3                   	ret    

f0103a6a <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0103a6a:	55                   	push   %ebp
f0103a6b:	89 e5                	mov    %esp,%ebp
f0103a6d:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0103a70:	8b 45 10             	mov    0x10(%ebp),%eax
f0103a73:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103a77:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103a7a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a7e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a81:	89 04 24             	mov    %eax,(%esp)
f0103a84:	e8 68 ff ff ff       	call   f01039f1 <memmove>
}
f0103a89:	c9                   	leave  
f0103a8a:	c3                   	ret    

f0103a8b <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103a8b:	55                   	push   %ebp
f0103a8c:	89 e5                	mov    %esp,%ebp
f0103a8e:	57                   	push   %edi
f0103a8f:	56                   	push   %esi
f0103a90:	53                   	push   %ebx
f0103a91:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103a94:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103a97:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103a9a:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103a9f:	85 ff                	test   %edi,%edi
f0103aa1:	74 37                	je     f0103ada <memcmp+0x4f>
		if (*s1 != *s2)
f0103aa3:	0f b6 03             	movzbl (%ebx),%eax
f0103aa6:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103aa9:	83 ef 01             	sub    $0x1,%edi
f0103aac:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f0103ab1:	38 c8                	cmp    %cl,%al
f0103ab3:	74 1c                	je     f0103ad1 <memcmp+0x46>
f0103ab5:	eb 10                	jmp    f0103ac7 <memcmp+0x3c>
f0103ab7:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0103abc:	83 c2 01             	add    $0x1,%edx
f0103abf:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0103ac3:	38 c8                	cmp    %cl,%al
f0103ac5:	74 0a                	je     f0103ad1 <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f0103ac7:	0f b6 c0             	movzbl %al,%eax
f0103aca:	0f b6 c9             	movzbl %cl,%ecx
f0103acd:	29 c8                	sub    %ecx,%eax
f0103acf:	eb 09                	jmp    f0103ada <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103ad1:	39 fa                	cmp    %edi,%edx
f0103ad3:	75 e2                	jne    f0103ab7 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103ad5:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103ada:	5b                   	pop    %ebx
f0103adb:	5e                   	pop    %esi
f0103adc:	5f                   	pop    %edi
f0103add:	5d                   	pop    %ebp
f0103ade:	c3                   	ret    

f0103adf <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103adf:	55                   	push   %ebp
f0103ae0:	89 e5                	mov    %esp,%ebp
f0103ae2:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103ae5:	89 c2                	mov    %eax,%edx
f0103ae7:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103aea:	39 d0                	cmp    %edx,%eax
f0103aec:	73 15                	jae    f0103b03 <memfind+0x24>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103aee:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f0103af2:	38 08                	cmp    %cl,(%eax)
f0103af4:	75 06                	jne    f0103afc <memfind+0x1d>
f0103af6:	eb 0b                	jmp    f0103b03 <memfind+0x24>
f0103af8:	38 08                	cmp    %cl,(%eax)
f0103afa:	74 07                	je     f0103b03 <memfind+0x24>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103afc:	83 c0 01             	add    $0x1,%eax
f0103aff:	39 d0                	cmp    %edx,%eax
f0103b01:	75 f5                	jne    f0103af8 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103b03:	5d                   	pop    %ebp
f0103b04:	c3                   	ret    

f0103b05 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103b05:	55                   	push   %ebp
f0103b06:	89 e5                	mov    %esp,%ebp
f0103b08:	57                   	push   %edi
f0103b09:	56                   	push   %esi
f0103b0a:	53                   	push   %ebx
f0103b0b:	8b 55 08             	mov    0x8(%ebp),%edx
f0103b0e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103b11:	0f b6 02             	movzbl (%edx),%eax
f0103b14:	3c 20                	cmp    $0x20,%al
f0103b16:	74 04                	je     f0103b1c <strtol+0x17>
f0103b18:	3c 09                	cmp    $0x9,%al
f0103b1a:	75 0e                	jne    f0103b2a <strtol+0x25>
		s++;
f0103b1c:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103b1f:	0f b6 02             	movzbl (%edx),%eax
f0103b22:	3c 20                	cmp    $0x20,%al
f0103b24:	74 f6                	je     f0103b1c <strtol+0x17>
f0103b26:	3c 09                	cmp    $0x9,%al
f0103b28:	74 f2                	je     f0103b1c <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103b2a:	3c 2b                	cmp    $0x2b,%al
f0103b2c:	75 0a                	jne    f0103b38 <strtol+0x33>
		s++;
f0103b2e:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103b31:	bf 00 00 00 00       	mov    $0x0,%edi
f0103b36:	eb 10                	jmp    f0103b48 <strtol+0x43>
f0103b38:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103b3d:	3c 2d                	cmp    $0x2d,%al
f0103b3f:	75 07                	jne    f0103b48 <strtol+0x43>
		s++, neg = 1;
f0103b41:	83 c2 01             	add    $0x1,%edx
f0103b44:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103b48:	85 db                	test   %ebx,%ebx
f0103b4a:	0f 94 c0             	sete   %al
f0103b4d:	74 05                	je     f0103b54 <strtol+0x4f>
f0103b4f:	83 fb 10             	cmp    $0x10,%ebx
f0103b52:	75 15                	jne    f0103b69 <strtol+0x64>
f0103b54:	80 3a 30             	cmpb   $0x30,(%edx)
f0103b57:	75 10                	jne    f0103b69 <strtol+0x64>
f0103b59:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0103b5d:	75 0a                	jne    f0103b69 <strtol+0x64>
		s += 2, base = 16;
f0103b5f:	83 c2 02             	add    $0x2,%edx
f0103b62:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103b67:	eb 13                	jmp    f0103b7c <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f0103b69:	84 c0                	test   %al,%al
f0103b6b:	74 0f                	je     f0103b7c <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103b6d:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103b72:	80 3a 30             	cmpb   $0x30,(%edx)
f0103b75:	75 05                	jne    f0103b7c <strtol+0x77>
		s++, base = 8;
f0103b77:	83 c2 01             	add    $0x1,%edx
f0103b7a:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f0103b7c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b81:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103b83:	0f b6 0a             	movzbl (%edx),%ecx
f0103b86:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0103b89:	80 fb 09             	cmp    $0x9,%bl
f0103b8c:	77 08                	ja     f0103b96 <strtol+0x91>
			dig = *s - '0';
f0103b8e:	0f be c9             	movsbl %cl,%ecx
f0103b91:	83 e9 30             	sub    $0x30,%ecx
f0103b94:	eb 1e                	jmp    f0103bb4 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f0103b96:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f0103b99:	80 fb 19             	cmp    $0x19,%bl
f0103b9c:	77 08                	ja     f0103ba6 <strtol+0xa1>
			dig = *s - 'a' + 10;
f0103b9e:	0f be c9             	movsbl %cl,%ecx
f0103ba1:	83 e9 57             	sub    $0x57,%ecx
f0103ba4:	eb 0e                	jmp    f0103bb4 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f0103ba6:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0103ba9:	80 fb 19             	cmp    $0x19,%bl
f0103bac:	77 14                	ja     f0103bc2 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103bae:	0f be c9             	movsbl %cl,%ecx
f0103bb1:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0103bb4:	39 f1                	cmp    %esi,%ecx
f0103bb6:	7d 0e                	jge    f0103bc6 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f0103bb8:	83 c2 01             	add    $0x1,%edx
f0103bbb:	0f af c6             	imul   %esi,%eax
f0103bbe:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0103bc0:	eb c1                	jmp    f0103b83 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0103bc2:	89 c1                	mov    %eax,%ecx
f0103bc4:	eb 02                	jmp    f0103bc8 <strtol+0xc3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0103bc6:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0103bc8:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103bcc:	74 05                	je     f0103bd3 <strtol+0xce>
		*endptr = (char *) s;
f0103bce:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103bd1:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0103bd3:	89 ca                	mov    %ecx,%edx
f0103bd5:	f7 da                	neg    %edx
f0103bd7:	85 ff                	test   %edi,%edi
f0103bd9:	0f 45 c2             	cmovne %edx,%eax
}
f0103bdc:	5b                   	pop    %ebx
f0103bdd:	5e                   	pop    %esi
f0103bde:	5f                   	pop    %edi
f0103bdf:	5d                   	pop    %ebp
f0103be0:	c3                   	ret    
	...

f0103bf0 <__udivdi3>:
f0103bf0:	83 ec 1c             	sub    $0x1c,%esp
f0103bf3:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0103bf7:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f0103bfb:	8b 44 24 20          	mov    0x20(%esp),%eax
f0103bff:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0103c03:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103c07:	8b 74 24 24          	mov    0x24(%esp),%esi
f0103c0b:	85 ff                	test   %edi,%edi
f0103c0d:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0103c11:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103c15:	89 cd                	mov    %ecx,%ebp
f0103c17:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c1b:	75 33                	jne    f0103c50 <__udivdi3+0x60>
f0103c1d:	39 f1                	cmp    %esi,%ecx
f0103c1f:	77 57                	ja     f0103c78 <__udivdi3+0x88>
f0103c21:	85 c9                	test   %ecx,%ecx
f0103c23:	75 0b                	jne    f0103c30 <__udivdi3+0x40>
f0103c25:	b8 01 00 00 00       	mov    $0x1,%eax
f0103c2a:	31 d2                	xor    %edx,%edx
f0103c2c:	f7 f1                	div    %ecx
f0103c2e:	89 c1                	mov    %eax,%ecx
f0103c30:	89 f0                	mov    %esi,%eax
f0103c32:	31 d2                	xor    %edx,%edx
f0103c34:	f7 f1                	div    %ecx
f0103c36:	89 c6                	mov    %eax,%esi
f0103c38:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103c3c:	f7 f1                	div    %ecx
f0103c3e:	89 f2                	mov    %esi,%edx
f0103c40:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103c44:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103c48:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103c4c:	83 c4 1c             	add    $0x1c,%esp
f0103c4f:	c3                   	ret    
f0103c50:	31 d2                	xor    %edx,%edx
f0103c52:	31 c0                	xor    %eax,%eax
f0103c54:	39 f7                	cmp    %esi,%edi
f0103c56:	77 e8                	ja     f0103c40 <__udivdi3+0x50>
f0103c58:	0f bd cf             	bsr    %edi,%ecx
f0103c5b:	83 f1 1f             	xor    $0x1f,%ecx
f0103c5e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103c62:	75 2c                	jne    f0103c90 <__udivdi3+0xa0>
f0103c64:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0103c68:	76 04                	jbe    f0103c6e <__udivdi3+0x7e>
f0103c6a:	39 f7                	cmp    %esi,%edi
f0103c6c:	73 d2                	jae    f0103c40 <__udivdi3+0x50>
f0103c6e:	31 d2                	xor    %edx,%edx
f0103c70:	b8 01 00 00 00       	mov    $0x1,%eax
f0103c75:	eb c9                	jmp    f0103c40 <__udivdi3+0x50>
f0103c77:	90                   	nop
f0103c78:	89 f2                	mov    %esi,%edx
f0103c7a:	f7 f1                	div    %ecx
f0103c7c:	31 d2                	xor    %edx,%edx
f0103c7e:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103c82:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103c86:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103c8a:	83 c4 1c             	add    $0x1c,%esp
f0103c8d:	c3                   	ret    
f0103c8e:	66 90                	xchg   %ax,%ax
f0103c90:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103c95:	b8 20 00 00 00       	mov    $0x20,%eax
f0103c9a:	89 ea                	mov    %ebp,%edx
f0103c9c:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103ca0:	d3 e7                	shl    %cl,%edi
f0103ca2:	89 c1                	mov    %eax,%ecx
f0103ca4:	d3 ea                	shr    %cl,%edx
f0103ca6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103cab:	09 fa                	or     %edi,%edx
f0103cad:	89 f7                	mov    %esi,%edi
f0103caf:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103cb3:	89 f2                	mov    %esi,%edx
f0103cb5:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103cb9:	d3 e5                	shl    %cl,%ebp
f0103cbb:	89 c1                	mov    %eax,%ecx
f0103cbd:	d3 ef                	shr    %cl,%edi
f0103cbf:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103cc4:	d3 e2                	shl    %cl,%edx
f0103cc6:	89 c1                	mov    %eax,%ecx
f0103cc8:	d3 ee                	shr    %cl,%esi
f0103cca:	09 d6                	or     %edx,%esi
f0103ccc:	89 fa                	mov    %edi,%edx
f0103cce:	89 f0                	mov    %esi,%eax
f0103cd0:	f7 74 24 0c          	divl   0xc(%esp)
f0103cd4:	89 d7                	mov    %edx,%edi
f0103cd6:	89 c6                	mov    %eax,%esi
f0103cd8:	f7 e5                	mul    %ebp
f0103cda:	39 d7                	cmp    %edx,%edi
f0103cdc:	72 22                	jb     f0103d00 <__udivdi3+0x110>
f0103cde:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0103ce2:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103ce7:	d3 e5                	shl    %cl,%ebp
f0103ce9:	39 c5                	cmp    %eax,%ebp
f0103ceb:	73 04                	jae    f0103cf1 <__udivdi3+0x101>
f0103ced:	39 d7                	cmp    %edx,%edi
f0103cef:	74 0f                	je     f0103d00 <__udivdi3+0x110>
f0103cf1:	89 f0                	mov    %esi,%eax
f0103cf3:	31 d2                	xor    %edx,%edx
f0103cf5:	e9 46 ff ff ff       	jmp    f0103c40 <__udivdi3+0x50>
f0103cfa:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103d00:	8d 46 ff             	lea    -0x1(%esi),%eax
f0103d03:	31 d2                	xor    %edx,%edx
f0103d05:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103d09:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103d0d:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103d11:	83 c4 1c             	add    $0x1c,%esp
f0103d14:	c3                   	ret    
	...

f0103d20 <__umoddi3>:
f0103d20:	83 ec 1c             	sub    $0x1c,%esp
f0103d23:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0103d27:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f0103d2b:	8b 44 24 20          	mov    0x20(%esp),%eax
f0103d2f:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103d33:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0103d37:	8b 74 24 24          	mov    0x24(%esp),%esi
f0103d3b:	85 ed                	test   %ebp,%ebp
f0103d3d:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0103d41:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103d45:	89 cf                	mov    %ecx,%edi
f0103d47:	89 04 24             	mov    %eax,(%esp)
f0103d4a:	89 f2                	mov    %esi,%edx
f0103d4c:	75 1a                	jne    f0103d68 <__umoddi3+0x48>
f0103d4e:	39 f1                	cmp    %esi,%ecx
f0103d50:	76 4e                	jbe    f0103da0 <__umoddi3+0x80>
f0103d52:	f7 f1                	div    %ecx
f0103d54:	89 d0                	mov    %edx,%eax
f0103d56:	31 d2                	xor    %edx,%edx
f0103d58:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103d5c:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103d60:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103d64:	83 c4 1c             	add    $0x1c,%esp
f0103d67:	c3                   	ret    
f0103d68:	39 f5                	cmp    %esi,%ebp
f0103d6a:	77 54                	ja     f0103dc0 <__umoddi3+0xa0>
f0103d6c:	0f bd c5             	bsr    %ebp,%eax
f0103d6f:	83 f0 1f             	xor    $0x1f,%eax
f0103d72:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d76:	75 60                	jne    f0103dd8 <__umoddi3+0xb8>
f0103d78:	3b 0c 24             	cmp    (%esp),%ecx
f0103d7b:	0f 87 07 01 00 00    	ja     f0103e88 <__umoddi3+0x168>
f0103d81:	89 f2                	mov    %esi,%edx
f0103d83:	8b 34 24             	mov    (%esp),%esi
f0103d86:	29 ce                	sub    %ecx,%esi
f0103d88:	19 ea                	sbb    %ebp,%edx
f0103d8a:	89 34 24             	mov    %esi,(%esp)
f0103d8d:	8b 04 24             	mov    (%esp),%eax
f0103d90:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103d94:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103d98:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103d9c:	83 c4 1c             	add    $0x1c,%esp
f0103d9f:	c3                   	ret    
f0103da0:	85 c9                	test   %ecx,%ecx
f0103da2:	75 0b                	jne    f0103daf <__umoddi3+0x8f>
f0103da4:	b8 01 00 00 00       	mov    $0x1,%eax
f0103da9:	31 d2                	xor    %edx,%edx
f0103dab:	f7 f1                	div    %ecx
f0103dad:	89 c1                	mov    %eax,%ecx
f0103daf:	89 f0                	mov    %esi,%eax
f0103db1:	31 d2                	xor    %edx,%edx
f0103db3:	f7 f1                	div    %ecx
f0103db5:	8b 04 24             	mov    (%esp),%eax
f0103db8:	f7 f1                	div    %ecx
f0103dba:	eb 98                	jmp    f0103d54 <__umoddi3+0x34>
f0103dbc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103dc0:	89 f2                	mov    %esi,%edx
f0103dc2:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103dc6:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103dca:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103dce:	83 c4 1c             	add    $0x1c,%esp
f0103dd1:	c3                   	ret    
f0103dd2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103dd8:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103ddd:	89 e8                	mov    %ebp,%eax
f0103ddf:	bd 20 00 00 00       	mov    $0x20,%ebp
f0103de4:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0103de8:	89 fa                	mov    %edi,%edx
f0103dea:	d3 e0                	shl    %cl,%eax
f0103dec:	89 e9                	mov    %ebp,%ecx
f0103dee:	d3 ea                	shr    %cl,%edx
f0103df0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103df5:	09 c2                	or     %eax,%edx
f0103df7:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103dfb:	89 14 24             	mov    %edx,(%esp)
f0103dfe:	89 f2                	mov    %esi,%edx
f0103e00:	d3 e7                	shl    %cl,%edi
f0103e02:	89 e9                	mov    %ebp,%ecx
f0103e04:	d3 ea                	shr    %cl,%edx
f0103e06:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103e0b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103e0f:	d3 e6                	shl    %cl,%esi
f0103e11:	89 e9                	mov    %ebp,%ecx
f0103e13:	d3 e8                	shr    %cl,%eax
f0103e15:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103e1a:	09 f0                	or     %esi,%eax
f0103e1c:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103e20:	f7 34 24             	divl   (%esp)
f0103e23:	d3 e6                	shl    %cl,%esi
f0103e25:	89 74 24 08          	mov    %esi,0x8(%esp)
f0103e29:	89 d6                	mov    %edx,%esi
f0103e2b:	f7 e7                	mul    %edi
f0103e2d:	39 d6                	cmp    %edx,%esi
f0103e2f:	89 c1                	mov    %eax,%ecx
f0103e31:	89 d7                	mov    %edx,%edi
f0103e33:	72 3f                	jb     f0103e74 <__umoddi3+0x154>
f0103e35:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0103e39:	72 35                	jb     f0103e70 <__umoddi3+0x150>
f0103e3b:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103e3f:	29 c8                	sub    %ecx,%eax
f0103e41:	19 fe                	sbb    %edi,%esi
f0103e43:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103e48:	89 f2                	mov    %esi,%edx
f0103e4a:	d3 e8                	shr    %cl,%eax
f0103e4c:	89 e9                	mov    %ebp,%ecx
f0103e4e:	d3 e2                	shl    %cl,%edx
f0103e50:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103e55:	09 d0                	or     %edx,%eax
f0103e57:	89 f2                	mov    %esi,%edx
f0103e59:	d3 ea                	shr    %cl,%edx
f0103e5b:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103e5f:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103e63:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103e67:	83 c4 1c             	add    $0x1c,%esp
f0103e6a:	c3                   	ret    
f0103e6b:	90                   	nop
f0103e6c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103e70:	39 d6                	cmp    %edx,%esi
f0103e72:	75 c7                	jne    f0103e3b <__umoddi3+0x11b>
f0103e74:	89 d7                	mov    %edx,%edi
f0103e76:	89 c1                	mov    %eax,%ecx
f0103e78:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f0103e7c:	1b 3c 24             	sbb    (%esp),%edi
f0103e7f:	eb ba                	jmp    f0103e3b <__umoddi3+0x11b>
f0103e81:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103e88:	39 f5                	cmp    %esi,%ebp
f0103e8a:	0f 82 f1 fe ff ff    	jb     f0103d81 <__umoddi3+0x61>
f0103e90:	e9 f8 fe ff ff       	jmp    f0103d8d <__umoddi3+0x6d>
