
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
f0100015:	b8 00 70 11 00       	mov    $0x117000,%eax
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
f0100034:	bc 00 70 11 f0       	mov    $0xf0117000,%esp

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
f0100046:	b8 ac 99 11 f0       	mov    $0xf01199ac,%eax
f010004b:	2d 04 93 11 f0       	sub    $0xf0119304,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 04 93 11 f0 	movl   $0xf0119304,(%esp)
f0100063:	e8 fe 3d 00 00       	call   f0103e66 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 8e 04 00 00       	call   f01004fb <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 80 43 10 f0 	movl   $0xf0104380,(%esp)
f010007c:	e8 e1 31 00 00       	call   f0103262 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 da 16 00 00       	call   f0101760 <mem_init>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 e7 0c 00 00       	call   f0100d79 <monitor>
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
f010009f:	83 3d 20 93 11 f0 00 	cmpl   $0x0,0xf0119320
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 20 93 11 f0    	mov    %esi,0xf0119320

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
f01000c1:	c7 04 24 9b 43 10 f0 	movl   $0xf010439b,(%esp)
f01000c8:	e8 95 31 00 00       	call   f0103262 <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 56 31 00 00       	call   f010322f <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 a8 55 10 f0 	movl   $0xf01055a8,(%esp)
f01000e0:	e8 7d 31 00 00       	call   f0103262 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 88 0c 00 00       	call   f0100d79 <monitor>
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
f010010b:	c7 04 24 b3 43 10 f0 	movl   $0xf01043b3,(%esp)
f0100112:	e8 4b 31 00 00       	call   f0103262 <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 09 31 00 00       	call   f010322f <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 a8 55 10 f0 	movl   $0xf01055a8,(%esp)
f010012d:	e8 30 31 00 00       	call   f0103262 <cprintf>
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
f0100179:	8b 15 64 95 11 f0    	mov    0xf0119564,%edx
f010017f:	88 82 60 93 11 f0    	mov    %al,-0xfee6ca0(%edx)
f0100185:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f0100188:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f010018d:	ba 00 00 00 00       	mov    $0x0,%edx
f0100192:	0f 44 c2             	cmove  %edx,%eax
f0100195:	a3 64 95 11 f0       	mov    %eax,0xf0119564
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
f010021c:	a1 00 93 11 f0       	mov    0xf0119300,%eax
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
f0100262:	0f b7 15 74 95 11 f0 	movzwl 0xf0119574,%edx
f0100269:	66 85 d2             	test   %dx,%dx
f010026c:	0f 84 e3 00 00 00    	je     f0100355 <cons_putc+0x1ae>
			crt_pos--;
f0100272:	83 ea 01             	sub    $0x1,%edx
f0100275:	66 89 15 74 95 11 f0 	mov    %dx,0xf0119574
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010027c:	0f b7 d2             	movzwl %dx,%edx
f010027f:	b0 00                	mov    $0x0,%al
f0100281:	83 c8 20             	or     $0x20,%eax
f0100284:	8b 0d 70 95 11 f0    	mov    0xf0119570,%ecx
f010028a:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f010028e:	eb 78                	jmp    f0100308 <cons_putc+0x161>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100290:	66 83 05 74 95 11 f0 	addw   $0x50,0xf0119574
f0100297:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100298:	0f b7 05 74 95 11 f0 	movzwl 0xf0119574,%eax
f010029f:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01002a5:	c1 e8 16             	shr    $0x16,%eax
f01002a8:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01002ab:	c1 e0 04             	shl    $0x4,%eax
f01002ae:	66 a3 74 95 11 f0    	mov    %ax,0xf0119574
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
f01002ea:	0f b7 15 74 95 11 f0 	movzwl 0xf0119574,%edx
f01002f1:	0f b7 da             	movzwl %dx,%ebx
f01002f4:	8b 0d 70 95 11 f0    	mov    0xf0119570,%ecx
f01002fa:	66 89 04 59          	mov    %ax,(%ecx,%ebx,2)
f01002fe:	83 c2 01             	add    $0x1,%edx
f0100301:	66 89 15 74 95 11 f0 	mov    %dx,0xf0119574
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100308:	66 81 3d 74 95 11 f0 	cmpw   $0x7cf,0xf0119574
f010030f:	cf 07 
f0100311:	76 42                	jbe    f0100355 <cons_putc+0x1ae>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100313:	a1 70 95 11 f0       	mov    0xf0119570,%eax
f0100318:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010031f:	00 
f0100320:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100326:	89 54 24 04          	mov    %edx,0x4(%esp)
f010032a:	89 04 24             	mov    %eax,(%esp)
f010032d:	e8 8f 3b 00 00       	call   f0103ec1 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100332:	8b 15 70 95 11 f0    	mov    0xf0119570,%edx
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
f010034d:	66 83 2d 74 95 11 f0 	subw   $0x50,0xf0119574
f0100354:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100355:	8b 0d 6c 95 11 f0    	mov    0xf011956c,%ecx
f010035b:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100360:	89 ca                	mov    %ecx,%edx
f0100362:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100363:	0f b7 35 74 95 11 f0 	movzwl 0xf0119574,%esi
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
f01003ae:	83 0d 68 95 11 f0 40 	orl    $0x40,0xf0119568
		return 0;
f01003b5:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003ba:	e9 c4 00 00 00       	jmp    f0100483 <kbd_proc_data+0xf8>
	} else if (data & 0x80) {
f01003bf:	84 c0                	test   %al,%al
f01003c1:	79 37                	jns    f01003fa <kbd_proc_data+0x6f>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003c3:	8b 0d 68 95 11 f0    	mov    0xf0119568,%ecx
f01003c9:	89 cb                	mov    %ecx,%ebx
f01003cb:	83 e3 40             	and    $0x40,%ebx
f01003ce:	83 e0 7f             	and    $0x7f,%eax
f01003d1:	85 db                	test   %ebx,%ebx
f01003d3:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01003d6:	0f b6 d2             	movzbl %dl,%edx
f01003d9:	0f b6 82 00 44 10 f0 	movzbl -0xfefbc00(%edx),%eax
f01003e0:	83 c8 40             	or     $0x40,%eax
f01003e3:	0f b6 c0             	movzbl %al,%eax
f01003e6:	f7 d0                	not    %eax
f01003e8:	21 c1                	and    %eax,%ecx
f01003ea:	89 0d 68 95 11 f0    	mov    %ecx,0xf0119568
		return 0;
f01003f0:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003f5:	e9 89 00 00 00       	jmp    f0100483 <kbd_proc_data+0xf8>
	} else if (shift & E0ESC) {
f01003fa:	8b 0d 68 95 11 f0    	mov    0xf0119568,%ecx
f0100400:	f6 c1 40             	test   $0x40,%cl
f0100403:	74 0e                	je     f0100413 <kbd_proc_data+0x88>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100405:	89 c2                	mov    %eax,%edx
f0100407:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f010040a:	83 e1 bf             	and    $0xffffffbf,%ecx
f010040d:	89 0d 68 95 11 f0    	mov    %ecx,0xf0119568
	}

	shift |= shiftcode[data];
f0100413:	0f b6 d2             	movzbl %dl,%edx
f0100416:	0f b6 82 00 44 10 f0 	movzbl -0xfefbc00(%edx),%eax
f010041d:	0b 05 68 95 11 f0    	or     0xf0119568,%eax
	shift ^= togglecode[data];
f0100423:	0f b6 8a 00 45 10 f0 	movzbl -0xfefbb00(%edx),%ecx
f010042a:	31 c8                	xor    %ecx,%eax
f010042c:	a3 68 95 11 f0       	mov    %eax,0xf0119568

	c = charcode[shift & (CTL | SHIFT)][data];
f0100431:	89 c1                	mov    %eax,%ecx
f0100433:	83 e1 03             	and    $0x3,%ecx
f0100436:	8b 0c 8d 00 46 10 f0 	mov    -0xfefba00(,%ecx,4),%ecx
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
f010046c:	c7 04 24 cd 43 10 f0 	movl   $0xf01043cd,(%esp)
f0100473:	e8 ea 2d 00 00       	call   f0103262 <cprintf>
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
f0100491:	83 3d 40 93 11 f0 00 	cmpl   $0x0,0xf0119340
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
f01004c8:	8b 15 60 95 11 f0    	mov    0xf0119560,%edx
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
f01004d3:	3b 15 64 95 11 f0    	cmp    0xf0119564,%edx
f01004d9:	74 1e                	je     f01004f9 <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f01004db:	0f b6 82 60 93 11 f0 	movzbl -0xfee6ca0(%edx),%eax
f01004e2:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f01004e5:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004eb:	b9 00 00 00 00       	mov    $0x0,%ecx
f01004f0:	0f 44 d1             	cmove  %ecx,%edx
f01004f3:	89 15 60 95 11 f0    	mov    %edx,0xf0119560
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
f0100521:	c7 05 6c 95 11 f0 b4 	movl   $0x3b4,0xf011956c
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
f0100539:	c7 05 6c 95 11 f0 d4 	movl   $0x3d4,0xf011956c
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
f0100548:	8b 0d 6c 95 11 f0    	mov    0xf011956c,%ecx
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
f010056d:	89 35 70 95 11 f0    	mov    %esi,0xf0119570
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100573:	0f b6 d8             	movzbl %al,%ebx
f0100576:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100578:	66 89 3d 74 95 11 f0 	mov    %di,0xf0119574
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
f01005ce:	a3 40 93 11 f0       	mov    %eax,0xf0119340
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
f01005dd:	c7 04 24 d9 43 10 f0 	movl   $0xf01043d9,(%esp)
f01005e4:	e8 79 2c 00 00       	call   f0103262 <cprintf>
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
f0100626:	c7 04 24 10 46 10 f0 	movl   $0xf0104610,(%esp)
f010062d:	e8 30 2c 00 00       	call   f0103262 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100632:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100639:	00 
f010063a:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100641:	f0 
f0100642:	c7 04 24 b8 47 10 f0 	movl   $0xf01047b8,(%esp)
f0100649:	e8 14 2c 00 00       	call   f0103262 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010064e:	c7 44 24 08 65 43 10 	movl   $0x104365,0x8(%esp)
f0100655:	00 
f0100656:	c7 44 24 04 65 43 10 	movl   $0xf0104365,0x4(%esp)
f010065d:	f0 
f010065e:	c7 04 24 dc 47 10 f0 	movl   $0xf01047dc,(%esp)
f0100665:	e8 f8 2b 00 00       	call   f0103262 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010066a:	c7 44 24 08 04 93 11 	movl   $0x119304,0x8(%esp)
f0100671:	00 
f0100672:	c7 44 24 04 04 93 11 	movl   $0xf0119304,0x4(%esp)
f0100679:	f0 
f010067a:	c7 04 24 00 48 10 f0 	movl   $0xf0104800,(%esp)
f0100681:	e8 dc 2b 00 00       	call   f0103262 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100686:	c7 44 24 08 ac 99 11 	movl   $0x1199ac,0x8(%esp)
f010068d:	00 
f010068e:	c7 44 24 04 ac 99 11 	movl   $0xf01199ac,0x4(%esp)
f0100695:	f0 
f0100696:	c7 04 24 24 48 10 f0 	movl   $0xf0104824,(%esp)
f010069d:	e8 c0 2b 00 00       	call   f0103262 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
f01006a2:	b8 ab 9d 11 f0       	mov    $0xf0119dab,%eax
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
f01006be:	c7 04 24 48 48 10 f0 	movl   $0xf0104848,(%esp)
f01006c5:	e8 98 2b 00 00       	call   f0103262 <cprintf>
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
f01006dd:	8b 83 04 4c 10 f0    	mov    -0xfefb3fc(%ebx),%eax
f01006e3:	89 44 24 08          	mov    %eax,0x8(%esp)
f01006e7:	8b 83 00 4c 10 f0    	mov    -0xfefb400(%ebx),%eax
f01006ed:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006f1:	c7 04 24 29 46 10 f0 	movl   $0xf0104629,(%esp)
f01006f8:	e8 65 2b 00 00       	call   f0103262 <cprintf>
f01006fd:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f0100700:	83 fb 54             	cmp    $0x54,%ebx
f0100703:	75 d8                	jne    f01006dd <mon_help+0xc>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f0100705:	b8 00 00 00 00       	mov    $0x0,%eax
f010070a:	83 c4 14             	add    $0x14,%esp
f010070d:	5b                   	pop    %ebx
f010070e:	5d                   	pop    %ebp
f010070f:	c3                   	ret    

f0100710 <mon_dumpvirtual>:
	return 0;
}

int 
mon_dumpvirtual(int argc, char **argv, struct Trapframe *tf)
{
f0100710:	55                   	push   %ebp
f0100711:	89 e5                	mov    %esp,%ebp
f0100713:	57                   	push   %edi
f0100714:	56                   	push   %esi
f0100715:	53                   	push   %ebx
f0100716:	83 ec 2c             	sub    $0x2c,%esp
f0100719:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	if(argc!=3)
f010071c:	83 7d 08 03          	cmpl   $0x3,0x8(%ebp)
f0100720:	74 11                	je     f0100733 <mon_dumpvirtual+0x23>
		{
			cprintf("Usage:dumpvirtual <address> <size>");
f0100722:	c7 04 24 74 48 10 f0 	movl   $0xf0104874,(%esp)
f0100729:	e8 34 2b 00 00       	call   f0103262 <cprintf>
			return 0;
f010072e:	e9 f8 00 00 00       	jmp    f010082b <mon_dumpvirtual+0x11b>
		}
	uintptr_t va=strtol(argv[1], 0,16);
f0100733:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f010073a:	00 
f010073b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100742:	00 
f0100743:	8b 43 04             	mov    0x4(%ebx),%eax
f0100746:	89 04 24             	mov    %eax,(%esp)
f0100749:	e8 87 38 00 00       	call   f0103fd5 <strtol>
	uintptr_t va_assign = va&(~0xf);
f010074e:	83 e0 f0             	and    $0xfffffff0,%eax
f0100751:	89 45 dc             	mov    %eax,-0x24(%ebp)
	uint32_t size = strtol(argv[2],0,10);
f0100754:	c7 44 24 08 0a 00 00 	movl   $0xa,0x8(%esp)
f010075b:	00 
f010075c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100763:	00 
f0100764:	8b 43 08             	mov    0x8(%ebx),%eax
f0100767:	89 04 24             	mov    %eax,(%esp)
f010076a:	e8 66 38 00 00       	call   f0103fd5 <strtol>
f010076f:	89 45 e0             	mov    %eax,-0x20(%ebp)
	uint32_t i =0;
	uint32_t j=0;
	cprintf("VA	     Contents");
f0100772:	c7 04 24 32 46 10 f0 	movl   $0xf0104632,(%esp)
f0100779:	e8 e4 2a 00 00       	call   f0103262 <cprintf>
	for (i=0;i<size/4;i++)
f010077e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100781:	c1 e8 02             	shr    $0x2,%eax
f0100784:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100787:	89 c7                	mov    %eax,%edi
f0100789:	85 c0                	test   %eax,%eax
f010078b:	74 43                	je     f01007d0 <mon_dumpvirtual+0xc0>
f010078d:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0100790:	bf 00 00 00 00       	mov    $0x0,%edi
		{
		cprintf("\n0x%08x :",va_assign+i*16);
f0100795:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100799:	c7 04 24 43 46 10 f0 	movl   $0xf0104643,(%esp)
f01007a0:	e8 bd 2a 00 00       	call   f0103262 <cprintf>
		for(j=0;j<4;j++)
f01007a5:	bb 00 00 00 00       	mov    $0x0,%ebx
			cprintf("0x%08x ",*((uintptr_t *)(va_assign+i*16+4*j)));
f01007aa:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
f01007ad:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007b1:	c7 04 24 4d 46 10 f0 	movl   $0xf010464d,(%esp)
f01007b8:	e8 a5 2a 00 00       	call   f0103262 <cprintf>
	uint32_t j=0;
	cprintf("VA	     Contents");
	for (i=0;i<size/4;i++)
		{
		cprintf("\n0x%08x :",va_assign+i*16);
		for(j=0;j<4;j++)
f01007bd:	83 c3 01             	add    $0x1,%ebx
f01007c0:	83 fb 04             	cmp    $0x4,%ebx
f01007c3:	75 e5                	jne    f01007aa <mon_dumpvirtual+0x9a>
	uintptr_t va_assign = va&(~0xf);
	uint32_t size = strtol(argv[2],0,10);
	uint32_t i =0;
	uint32_t j=0;
	cprintf("VA	     Contents");
	for (i=0;i<size/4;i++)
f01007c5:	83 c7 01             	add    $0x1,%edi
f01007c8:	83 c6 10             	add    $0x10,%esi
f01007cb:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f01007ce:	75 c5                	jne    f0100795 <mon_dumpvirtual+0x85>
		{
		cprintf("\n0x%08x :",va_assign+i*16);
		for(j=0;j<4;j++)
			cprintf("0x%08x ",*((uintptr_t *)(va_assign+i*16+4*j)));
		}
	if (size-i*4>0)
f01007d0:	8d 1c bd 00 00 00 00 	lea    0x0(,%edi,4),%ebx
f01007d7:	3b 5d e0             	cmp    -0x20(%ebp),%ebx
f01007da:	74 43                	je     f010081f <mon_dumpvirtual+0x10f>
		{
		cprintf("\n0x%08x :",va_assign+i*16);
f01007dc:	89 f8                	mov    %edi,%eax
f01007de:	c1 e0 04             	shl    $0x4,%eax
f01007e1:	03 45 dc             	add    -0x24(%ebp),%eax
f01007e4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007e8:	c7 04 24 43 46 10 f0 	movl   $0xf0104643,(%esp)
f01007ef:	e8 6e 2a 00 00       	call   f0103262 <cprintf>
		for (j=0;(i*4+j<size);j++)
f01007f4:	39 5d e0             	cmp    %ebx,-0x20(%ebp)
f01007f7:	76 26                	jbe    f010081f <mon_dumpvirtual+0x10f>
f01007f9:	89 d8                	mov    %ebx,%eax
f01007fb:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01007fe:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100801:	eb 02                	jmp    f0100805 <mon_dumpvirtual+0xf5>
f0100803:	89 d8                	mov    %ebx,%eax
			cprintf("0x%08x ",*((uintptr_t *)(va_assign+i*16+4*j)));
f0100805:	8b 04 86             	mov    (%esi,%eax,4),%eax
f0100808:	89 44 24 04          	mov    %eax,0x4(%esp)
f010080c:	c7 04 24 4d 46 10 f0 	movl   $0xf010464d,(%esp)
f0100813:	e8 4a 2a 00 00       	call   f0103262 <cprintf>
			cprintf("0x%08x ",*((uintptr_t *)(va_assign+i*16+4*j)));
		}
	if (size-i*4>0)
		{
		cprintf("\n0x%08x :",va_assign+i*16);
		for (j=0;(i*4+j<size);j++)
f0100818:	83 c3 01             	add    $0x1,%ebx
f010081b:	39 df                	cmp    %ebx,%edi
f010081d:	77 e4                	ja     f0100803 <mon_dumpvirtual+0xf3>
			cprintf("0x%08x ",*((uintptr_t *)(va_assign+i*16+4*j)));
		}
	cprintf("\n");
f010081f:	c7 04 24 a8 55 10 f0 	movl   $0xf01055a8,(%esp)
f0100826:	e8 37 2a 00 00       	call   f0103262 <cprintf>
	return 0;
}
f010082b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100830:	83 c4 2c             	add    $0x2c,%esp
f0100833:	5b                   	pop    %ebx
f0100834:	5e                   	pop    %esi
f0100835:	5f                   	pop    %edi
f0100836:	5d                   	pop    %ebp
f0100837:	c3                   	ret    

f0100838 <mon_dumpphysical>:

int 
mon_dumpphysical(int argc, char **argv, struct Trapframe *tf)
{
f0100838:	55                   	push   %ebp
f0100839:	89 e5                	mov    %esp,%ebp
f010083b:	57                   	push   %edi
f010083c:	56                   	push   %esi
f010083d:	53                   	push   %ebx
f010083e:	83 ec 3c             	sub    $0x3c,%esp
f0100841:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	if(argc!=3)
f0100844:	83 7d 08 03          	cmpl   $0x3,0x8(%ebp)
f0100848:	74 11                	je     f010085b <mon_dumpphysical+0x23>
		{
			cprintf("Usage:dumpphysical <address> <size>");
f010084a:	c7 04 24 98 48 10 f0 	movl   $0xf0104898,(%esp)
f0100851:	e8 0c 2a 00 00       	call   f0103262 <cprintf>
			return 0;
f0100856:	e9 46 01 00 00       	jmp    f01009a1 <mon_dumpphysical+0x169>
		}
	physaddr_t pa=(strtol(argv[1], 0,16));
f010085b:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f0100862:	00 
f0100863:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010086a:	00 
f010086b:	8b 43 04             	mov    0x4(%ebx),%eax
f010086e:	89 04 24             	mov    %eax,(%esp)
f0100871:	e8 5f 37 00 00       	call   f0103fd5 <strtol>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100876:	89 c2                	mov    %eax,%edx
f0100878:	c1 ea 0c             	shr    $0xc,%edx
f010087b:	3b 15 a0 99 11 f0    	cmp    0xf01199a0,%edx
f0100881:	72 20                	jb     f01008a3 <mon_dumpphysical+0x6b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100883:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100887:	c7 44 24 08 bc 48 10 	movl   $0xf01048bc,0x8(%esp)
f010088e:	f0 
f010088f:	c7 44 24 04 e9 00 00 	movl   $0xe9,0x4(%esp)
f0100896:	00 
f0100897:	c7 04 24 55 46 10 f0 	movl   $0xf0104655,(%esp)
f010089e:	e8 f1 f7 ff ff       	call   f0100094 <_panic>
	physaddr_t pa_assign = pa&(~0xf);
f01008a3:	89 c2                	mov    %eax,%edx
f01008a5:	83 e2 f0             	and    $0xfffffff0,%edx
f01008a8:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	return (void *)(pa + KERNBASE);
f01008ab:	2d 00 00 00 10       	sub    $0x10000000,%eax
	uintptr_t va=(uint32_t)KADDR(pa);
	uintptr_t va_assign = va&(~0xf);
f01008b0:	83 e0 f0             	and    $0xfffffff0,%eax
f01008b3:	89 45 d0             	mov    %eax,-0x30(%ebp)
	uint32_t size = strtol(argv[2],0,10);
f01008b6:	c7 44 24 08 0a 00 00 	movl   $0xa,0x8(%esp)
f01008bd:	00 
f01008be:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01008c5:	00 
f01008c6:	8b 43 08             	mov    0x8(%ebx),%eax
f01008c9:	89 04 24             	mov    %eax,(%esp)
f01008cc:	e8 04 37 00 00       	call   f0103fd5 <strtol>
f01008d1:	89 45 d8             	mov    %eax,-0x28(%ebp)
	uint32_t i =0;
	uint32_t j=0;
	cprintf("PA	     Contents");
f01008d4:	c7 04 24 64 46 10 f0 	movl   $0xf0104664,(%esp)
f01008db:	e8 82 29 00 00       	call   f0103262 <cprintf>
	for (i=0;i<size/4;i++)
f01008e0:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01008e3:	c1 e8 02             	shr    $0x2,%eax
f01008e6:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01008e9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01008ec:	85 c0                	test   %eax,%eax
f01008ee:	74 56                	je     f0100946 <mon_dumpphysical+0x10e>
f01008f0:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01008f3:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	cprintf("\n");
	return 0;
}

int 
mon_dumpphysical(int argc, char **argv, struct Trapframe *tf)
f01008fa:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01008fd:	29 fa                	sub    %edi,%edx
f01008ff:	89 55 dc             	mov    %edx,-0x24(%ebp)
	uint32_t i =0;
	uint32_t j=0;
	cprintf("PA	     Contents");
	for (i=0;i<size/4;i++)
		{
		cprintf("\n0x%08x :",pa_assign+i*16);
f0100902:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100906:	c7 04 24 43 46 10 f0 	movl   $0xf0104643,(%esp)
f010090d:	e8 50 29 00 00       	call   f0103262 <cprintf>
		for(j=0;j<4;j++)
f0100912:	bb 00 00 00 00       	mov    $0x0,%ebx
	cprintf("\n");
	return 0;
}

int 
mon_dumpphysical(int argc, char **argv, struct Trapframe *tf)
f0100917:	8b 75 dc             	mov    -0x24(%ebp),%esi
f010091a:	01 fe                	add    %edi,%esi
	cprintf("PA	     Contents");
	for (i=0;i<size/4;i++)
		{
		cprintf("\n0x%08x :",pa_assign+i*16);
		for(j=0;j<4;j++)
			cprintf("0x%08x ",*((uintptr_t *)(va_assign+i*16+4*j)));
f010091c:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
f010091f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100923:	c7 04 24 4d 46 10 f0 	movl   $0xf010464d,(%esp)
f010092a:	e8 33 29 00 00       	call   f0103262 <cprintf>
	uint32_t j=0;
	cprintf("PA	     Contents");
	for (i=0;i<size/4;i++)
		{
		cprintf("\n0x%08x :",pa_assign+i*16);
		for(j=0;j<4;j++)
f010092f:	83 c3 01             	add    $0x1,%ebx
f0100932:	83 fb 04             	cmp    $0x4,%ebx
f0100935:	75 e5                	jne    f010091c <mon_dumpphysical+0xe4>
	uintptr_t va_assign = va&(~0xf);
	uint32_t size = strtol(argv[2],0,10);
	uint32_t i =0;
	uint32_t j=0;
	cprintf("PA	     Contents");
	for (i=0;i<size/4;i++)
f0100937:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
f010093b:	83 c7 10             	add    $0x10,%edi
f010093e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100941:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f0100944:	75 bc                	jne    f0100902 <mon_dumpphysical+0xca>
		{
		cprintf("\n0x%08x :",pa_assign+i*16);
		for(j=0;j<4;j++)
			cprintf("0x%08x ",*((uintptr_t *)(va_assign+i*16+4*j)));
		}
	if (size-i*4>0)
f0100946:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100949:	c1 e3 02             	shl    $0x2,%ebx
f010094c:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f010094f:	74 44                	je     f0100995 <mon_dumpphysical+0x15d>
		{
		cprintf("\n0x%08x :",pa_assign+i*16);
f0100951:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100954:	c1 e0 04             	shl    $0x4,%eax
f0100957:	03 45 d4             	add    -0x2c(%ebp),%eax
f010095a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010095e:	c7 04 24 43 46 10 f0 	movl   $0xf0104643,(%esp)
f0100965:	e8 f8 28 00 00       	call   f0103262 <cprintf>
		for (j=0;(i*4+j<size);j++)
f010096a:	39 5d d8             	cmp    %ebx,-0x28(%ebp)
f010096d:	76 26                	jbe    f0100995 <mon_dumpphysical+0x15d>
f010096f:	89 d8                	mov    %ebx,%eax
f0100971:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100974:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0100977:	eb 02                	jmp    f010097b <mon_dumpphysical+0x143>
f0100979:	89 d8                	mov    %ebx,%eax
			cprintf("0x%08x ",*((uintptr_t *)(va_assign+i*16+4*j)));
f010097b:	8b 04 86             	mov    (%esi,%eax,4),%eax
f010097e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100982:	c7 04 24 4d 46 10 f0 	movl   $0xf010464d,(%esp)
f0100989:	e8 d4 28 00 00       	call   f0103262 <cprintf>
			cprintf("0x%08x ",*((uintptr_t *)(va_assign+i*16+4*j)));
		}
	if (size-i*4>0)
		{
		cprintf("\n0x%08x :",pa_assign+i*16);
		for (j=0;(i*4+j<size);j++)
f010098e:	83 c3 01             	add    $0x1,%ebx
f0100991:	39 df                	cmp    %ebx,%edi
f0100993:	77 e4                	ja     f0100979 <mon_dumpphysical+0x141>
			cprintf("0x%08x ",*((uintptr_t *)(va_assign+i*16+4*j)));
		}
	cprintf("\n");
f0100995:	c7 04 24 a8 55 10 f0 	movl   $0xf01055a8,(%esp)
f010099c:	e8 c1 28 00 00       	call   f0103262 <cprintf>
	return 0;
}
f01009a1:	b8 00 00 00 00       	mov    $0x0,%eax
f01009a6:	83 c4 3c             	add    $0x3c,%esp
f01009a9:	5b                   	pop    %ebx
f01009aa:	5e                   	pop    %esi
f01009ab:	5f                   	pop    %edi
f01009ac:	5d                   	pop    %ebp
f01009ad:	c3                   	ret    

f01009ae <mon_setmappings>:
	
}

int
mon_setmappings(int argc, char **argv, struct Trapframe *tf)
{
f01009ae:	55                   	push   %ebp
f01009af:	89 e5                	mov    %esp,%ebp
f01009b1:	83 ec 28             	sub    $0x28,%esp
f01009b4:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f01009b7:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01009ba:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01009bd:	8b 7d 08             	mov    0x8(%ebp),%edi
f01009c0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	if(argc!=3&&argc!=4)
f01009c3:	8d 47 fd             	lea    -0x3(%edi),%eax
f01009c6:	83 f8 01             	cmp    $0x1,%eax
f01009c9:	76 1d                	jbe    f01009e8 <mon_setmappings+0x3a>
		{
			cprintf("set, clear, or change the permissions of any mapping in the current address space");
f01009cb:	c7 04 24 e0 48 10 f0 	movl   $0xf01048e0,(%esp)
f01009d2:	e8 8b 28 00 00       	call   f0103262 <cprintf>
			cprintf("Usage:setmappings <OPER> <VA> (<Permission>)\n OPER:-set,-clear,-change Permission:U,W\n");
f01009d7:	c7 04 24 34 49 10 f0 	movl   $0xf0104934,(%esp)
f01009de:	e8 7f 28 00 00       	call   f0103262 <cprintf>
			return 0;
f01009e3:	e9 f0 00 00 00       	jmp    f0100ad8 <mon_setmappings+0x12a>
		}
	
	uintptr_t va = strtol(argv[2], 0,16);
f01009e8:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f01009ef:	00 
f01009f0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01009f7:	00 
f01009f8:	8b 43 08             	mov    0x8(%ebx),%eax
f01009fb:	89 04 24             	mov    %eax,(%esp)
f01009fe:	e8 d2 35 00 00       	call   f0103fd5 <strtol>
	uintptr_t va_page = PTE_ADDR(va);
	pte_t *pte;
	pte = pgdir_walk(kern_pgdir, (void * )(va_page), 0);
f0100a03:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100a0a:	00 
			cprintf("Usage:setmappings <OPER> <VA> (<Permission>)\n OPER:-set,-clear,-change Permission:U,W\n");
			return 0;
		}
	
	uintptr_t va = strtol(argv[2], 0,16);
	uintptr_t va_page = PTE_ADDR(va);
f0100a0b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	pte_t *pte;
	pte = pgdir_walk(kern_pgdir, (void * )(va_page), 0);
f0100a10:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a14:	a1 a4 99 11 f0       	mov    0xf01199a4,%eax
f0100a19:	89 04 24             	mov    %eax,(%esp)
f0100a1c:	e8 70 0a 00 00       	call   f0101491 <pgdir_walk>
f0100a21:	89 c6                	mov    %eax,%esi
	if(strcmp(argv[1],"-clear")==0)
f0100a23:	c7 44 24 04 75 46 10 	movl   $0xf0104675,0x4(%esp)
f0100a2a:	f0 
f0100a2b:	8b 43 04             	mov    0x4(%ebx),%eax
f0100a2e:	89 04 24             	mov    %eax,(%esp)
f0100a31:	e8 5a 33 00 00       	call   f0103d90 <strcmp>
f0100a36:	85 c0                	test   %eax,%eax
f0100a38:	75 1e                	jne    f0100a58 <mon_setmappings+0xaa>
	{
		*pte=PTE_ADDR(*pte);
f0100a3a:	8b 06                	mov    (%esi),%eax
f0100a3c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a41:	89 06                	mov    %eax,(%esi)
		cprintf("\n0x%08x permissions clear OK",(*pte));
f0100a43:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a47:	c7 04 24 7c 46 10 f0 	movl   $0xf010467c,(%esp)
f0100a4e:	e8 0f 28 00 00       	call   f0103262 <cprintf>
f0100a53:	e9 80 00 00 00       	jmp    f0100ad8 <mon_setmappings+0x12a>
	}
	else if(strcmp(argv[1],"-set")==0||strcmp(argv[1],"-change")==0)
f0100a58:	c7 44 24 04 99 46 10 	movl   $0xf0104699,0x4(%esp)
f0100a5f:	f0 
f0100a60:	8b 43 04             	mov    0x4(%ebx),%eax
f0100a63:	89 04 24             	mov    %eax,(%esp)
f0100a66:	e8 25 33 00 00       	call   f0103d90 <strcmp>
f0100a6b:	85 c0                	test   %eax,%eax
f0100a6d:	74 17                	je     f0100a86 <mon_setmappings+0xd8>
f0100a6f:	c7 44 24 04 9e 46 10 	movl   $0xf010469e,0x4(%esp)
f0100a76:	f0 
f0100a77:	8b 43 04             	mov    0x4(%ebx),%eax
f0100a7a:	89 04 24             	mov    %eax,(%esp)
f0100a7d:	e8 0e 33 00 00       	call   f0103d90 <strcmp>
f0100a82:	85 c0                	test   %eax,%eax
f0100a84:	75 52                	jne    f0100ad8 <mon_setmappings+0x12a>
	{
		if(argc!=4)
f0100a86:	83 ff 04             	cmp    $0x4,%edi
f0100a89:	74 03                	je     f0100a8e <mon_setmappings+0xe0>
		{
			*pte=(*pte)&(~PTE_U)&(~PTE_W);
f0100a8b:	83 26 f9             	andl   $0xfffffff9,(%esi)
		}
		if (argv[3][0]=='W'||argv[3][0]=='w'||argv[3][1]=='W'||argv[3][1]=='w')
f0100a8e:	8b 43 0c             	mov    0xc(%ebx),%eax
f0100a91:	0f b6 10             	movzbl (%eax),%edx
f0100a94:	80 fa 57             	cmp    $0x57,%dl
f0100a97:	74 11                	je     f0100aaa <mon_setmappings+0xfc>
f0100a99:	80 fa 77             	cmp    $0x77,%dl
f0100a9c:	74 0c                	je     f0100aaa <mon_setmappings+0xfc>
f0100a9e:	0f b6 40 01          	movzbl 0x1(%eax),%eax
f0100aa2:	3c 57                	cmp    $0x57,%al
f0100aa4:	74 04                	je     f0100aaa <mon_setmappings+0xfc>
f0100aa6:	3c 77                	cmp    $0x77,%al
f0100aa8:	75 03                	jne    f0100aad <mon_setmappings+0xff>
		{
			*pte=(*pte)|PTE_W;
f0100aaa:	83 0e 02             	orl    $0x2,(%esi)
		}
		if (argv[3][0]=='U'||argv[3][0]=='u'||argv[3][1]=='U'||argv[3][1]=='u')
f0100aad:	8b 43 0c             	mov    0xc(%ebx),%eax
f0100ab0:	0f b6 10             	movzbl (%eax),%edx
f0100ab3:	80 fa 55             	cmp    $0x55,%dl
f0100ab6:	74 11                	je     f0100ac9 <mon_setmappings+0x11b>
f0100ab8:	80 fa 75             	cmp    $0x75,%dl
f0100abb:	74 0c                	je     f0100ac9 <mon_setmappings+0x11b>
f0100abd:	0f b6 40 01          	movzbl 0x1(%eax),%eax
f0100ac1:	3c 55                	cmp    $0x55,%al
f0100ac3:	74 04                	je     f0100ac9 <mon_setmappings+0x11b>
f0100ac5:	3c 75                	cmp    $0x75,%al
f0100ac7:	75 03                	jne    f0100acc <mon_setmappings+0x11e>
		{
			*pte=(*pte)|PTE_U;
f0100ac9:	83 0e 04             	orl    $0x4,(%esi)
		}
		cprintf("Permission set OK\n");
f0100acc:	c7 04 24 a6 46 10 f0 	movl   $0xf01046a6,(%esp)
f0100ad3:	e8 8a 27 00 00       	call   f0103262 <cprintf>
	}
	return 0;
}
f0100ad8:	b8 00 00 00 00       	mov    $0x0,%eax
f0100add:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100ae0:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100ae3:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100ae6:	89 ec                	mov    %ebp,%esp
f0100ae8:	5d                   	pop    %ebp
f0100ae9:	c3                   	ret    

f0100aea <mon_showmappings>:
	return 0;
}

int
mon_showmappings(int argc, char **argv, struct Trapframe *tf)
{
f0100aea:	55                   	push   %ebp
f0100aeb:	89 e5                	mov    %esp,%ebp
f0100aed:	57                   	push   %edi
f0100aee:	56                   	push   %esi
f0100aef:	53                   	push   %ebx
f0100af0:	83 ec 2c             	sub    $0x2c,%esp
f0100af3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	if(argc!=3)
f0100af6:	83 7d 08 03          	cmpl   $0x3,0x8(%ebp)
f0100afa:	74 11                	je     f0100b0d <mon_showmappings+0x23>
		{
			cprintf("Need low va and high va in 0x , for exampe:\nshowmappings 0x3000 0x5000\n");
f0100afc:	c7 04 24 8c 49 10 f0 	movl   $0xf010498c,(%esp)
f0100b03:	e8 5a 27 00 00       	call   f0103262 <cprintf>
			return 0;
f0100b08:	e9 2a 01 00 00       	jmp    f0100c37 <mon_showmappings+0x14d>
		}
	uintptr_t va_low = strtol(argv[1], 0,16);
f0100b0d:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f0100b14:	00 
f0100b15:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100b1c:	00 
f0100b1d:	8b 43 04             	mov    0x4(%ebx),%eax
f0100b20:	89 04 24             	mov    %eax,(%esp)
f0100b23:	e8 ad 34 00 00       	call   f0103fd5 <strtol>
f0100b28:	89 c6                	mov    %eax,%esi
	uintptr_t va_high = strtol(argv[2], 0,16);
f0100b2a:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f0100b31:	00 
f0100b32:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100b39:	00 
f0100b3a:	8b 43 08             	mov    0x8(%ebx),%eax
f0100b3d:	89 04 24             	mov    %eax,(%esp)
f0100b40:	e8 90 34 00 00       	call   f0103fd5 <strtol>
	uintptr_t va_low_page = PTE_ADDR(va_low);
f0100b45:	89 f3                	mov    %esi,%ebx
f0100b47:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t va_high_page = PTE_ADDR(va_high);
f0100b4d:	25 00 f0 ff ff       	and    $0xfffff000,%eax

	int pagenum = (va_high_page-va_low_page)/PGSIZE;
f0100b52:	29 d8                	sub    %ebx,%eax
f0100b54:	c1 e8 0c             	shr    $0xc,%eax
f0100b57:	89 45 e0             	mov    %eax,-0x20(%ebp)
	int i = 0;
	pte_t *pte;
	cprintf("----------output start------------\n");
f0100b5a:	c7 04 24 d4 49 10 f0 	movl   $0xf01049d4,(%esp)
f0100b61:	e8 fc 26 00 00       	call   f0103262 <cprintf>
	cprintf("Virtual Address	    Physical  Permissions(kernel/user)");
f0100b66:	c7 04 24 f8 49 10 f0 	movl   $0xf01049f8,(%esp)
f0100b6d:	e8 f0 26 00 00       	call   f0103262 <cprintf>
	for(i=0;i<pagenum;i++)
f0100b72:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100b76:	0f 8e af 00 00 00    	jle    f0100c2b <mon_showmappings+0x141>
f0100b7c:	bf 00 00 00 00       	mov    $0x0,%edi
	{
		pte = pgdir_walk(kern_pgdir, (void * )(va_low_page+i*PGSIZE), 0);
f0100b81:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100b84:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100b8b:	00 
f0100b8c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100b90:	a1 a4 99 11 f0       	mov    0xf01199a4,%eax
f0100b95:	89 04 24             	mov    %eax,(%esp)
f0100b98:	e8 f4 08 00 00       	call   f0101491 <pgdir_walk>
f0100b9d:	89 c6                	mov    %eax,%esi
		cprintf("\n0x%08x - 0x%08x :",va_low_page+i*PGSIZE,va_low_page+(i+1)*PGSIZE);
f0100b9f:	83 c7 01             	add    $0x1,%edi
		}
	return 0;
}

int
mon_showmappings(int argc, char **argv, struct Trapframe *tf)
f0100ba2:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	cprintf("----------output start------------\n");
	cprintf("Virtual Address	    Physical  Permissions(kernel/user)");
	for(i=0;i<pagenum;i++)
	{
		pte = pgdir_walk(kern_pgdir, (void * )(va_low_page+i*PGSIZE), 0);
		cprintf("\n0x%08x - 0x%08x :",va_low_page+i*PGSIZE,va_low_page+(i+1)*PGSIZE);
f0100ba8:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100bac:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100baf:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100bb3:	c7 04 24 b9 46 10 f0 	movl   $0xf01046b9,(%esp)
f0100bba:	e8 a3 26 00 00       	call   f0103262 <cprintf>
		if ( pte!=NULL&& (*pte&PTE_P))//pte exist
f0100bbf:	85 f6                	test   %esi,%esi
f0100bc1:	74 5f                	je     f0100c22 <mon_showmappings+0x138>
f0100bc3:	8b 06                	mov    (%esi),%eax
f0100bc5:	a8 01                	test   $0x1,%al
f0100bc7:	74 59                	je     f0100c22 <mon_showmappings+0x138>
		{
		cprintf("0x%08x ",PTE_ADDR(*pte));
f0100bc9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100bce:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100bd2:	c7 04 24 4d 46 10 f0 	movl   $0xf010464d,(%esp)
f0100bd9:	e8 84 26 00 00       	call   f0103262 <cprintf>
		if (*pte & PTE_W)
f0100bde:	8b 06                	mov    (%esi),%eax
f0100be0:	a8 02                	test   $0x2,%al
f0100be2:	74 20                	je     f0100c04 <mon_showmappings+0x11a>
			{
			if (*pte & PTE_U)
f0100be4:	a8 04                	test   $0x4,%al
f0100be6:	74 0e                	je     f0100bf6 <mon_showmappings+0x10c>
				cprintf("RW\\RW");
f0100be8:	c7 04 24 cc 46 10 f0 	movl   $0xf01046cc,(%esp)
f0100bef:	e8 6e 26 00 00       	call   f0103262 <cprintf>
f0100bf4:	eb 2c                	jmp    f0100c22 <mon_showmappings+0x138>
			else
				cprintf("RW\\--");
f0100bf6:	c7 04 24 d2 46 10 f0 	movl   $0xf01046d2,(%esp)
f0100bfd:	e8 60 26 00 00       	call   f0103262 <cprintf>
f0100c02:	eb 1e                	jmp    f0100c22 <mon_showmappings+0x138>
			}
		else
			{
			if (*pte & PTE_U)
f0100c04:	a8 04                	test   $0x4,%al
f0100c06:	74 0e                	je     f0100c16 <mon_showmappings+0x12c>
				cprintf("R-\\R-");
f0100c08:	c7 04 24 d8 46 10 f0 	movl   $0xf01046d8,(%esp)
f0100c0f:	e8 4e 26 00 00       	call   f0103262 <cprintf>
f0100c14:	eb 0c                	jmp    f0100c22 <mon_showmappings+0x138>
			else
				cprintf("R-\\--");
f0100c16:	c7 04 24 de 46 10 f0 	movl   $0xf01046de,(%esp)
f0100c1d:	e8 40 26 00 00       	call   f0103262 <cprintf>
	int pagenum = (va_high_page-va_low_page)/PGSIZE;
	int i = 0;
	pte_t *pte;
	cprintf("----------output start------------\n");
	cprintf("Virtual Address	    Physical  Permissions(kernel/user)");
	for(i=0;i<pagenum;i++)
f0100c22:	39 7d e0             	cmp    %edi,-0x20(%ebp)
f0100c25:	0f 85 56 ff ff ff    	jne    f0100b81 <mon_showmappings+0x97>
			else
				cprintf("R-\\--");
			}
		}
	}
	cprintf("\n----------output end------------\n");
f0100c2b:	c7 04 24 30 4a 10 f0 	movl   $0xf0104a30,(%esp)
f0100c32:	e8 2b 26 00 00       	call   f0103262 <cprintf>
	return 0;
	
}
f0100c37:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c3c:	83 c4 2c             	add    $0x2c,%esp
f0100c3f:	5b                   	pop    %ebx
f0100c40:	5e                   	pop    %esi
f0100c41:	5f                   	pop    %edi
f0100c42:	5d                   	pop    %ebp
f0100c43:	c3                   	ret    

f0100c44 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100c44:	55                   	push   %ebp
f0100c45:	89 e5                	mov    %esp,%ebp
f0100c47:	57                   	push   %edi
f0100c48:	56                   	push   %esi
f0100c49:	53                   	push   %ebx
f0100c4a:	81 ec 8c 00 00 00    	sub    $0x8c,%esp

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100c50:	89 eb                	mov    %ebp,%ebx
f0100c52:	89 de                	mov    %ebx,%esi
	// Your code here.
	uint32_t ebp,eip,arg[5];
	ebp = read_ebp();
	eip = *((uint32_t*)ebp+1);
f0100c54:	8b 7b 04             	mov    0x4(%ebx),%edi
	arg[0] = *((uint32_t*)ebp+2);
f0100c57:	8b 43 08             	mov    0x8(%ebx),%eax
f0100c5a:	89 45 a4             	mov    %eax,-0x5c(%ebp)
	arg[1] = *((uint32_t*)ebp+3);
f0100c5d:	8b 43 0c             	mov    0xc(%ebx),%eax
f0100c60:	89 45 a0             	mov    %eax,-0x60(%ebp)
	arg[2] = *((uint32_t*)ebp+4);
f0100c63:	8b 43 10             	mov    0x10(%ebx),%eax
f0100c66:	89 45 9c             	mov    %eax,-0x64(%ebp)
	arg[3] = *((uint32_t*)ebp+5);
f0100c69:	8b 43 14             	mov    0x14(%ebx),%eax
f0100c6c:	89 45 98             	mov    %eax,-0x68(%ebp)
	arg[4] = *((uint32_t*)ebp+6);
f0100c6f:	8b 43 18             	mov    0x18(%ebx),%eax
f0100c72:	89 45 94             	mov    %eax,-0x6c(%ebp)

	cprintf("Stack backtrace:\n");
f0100c75:	c7 04 24 e4 46 10 f0 	movl   $0xf01046e4,(%esp)
f0100c7c:	e8 e1 25 00 00       	call   f0103262 <cprintf>
	
	while(ebp != 0x00)
f0100c81:	85 db                	test   %ebx,%ebx
f0100c83:	0f 84 e0 00 00 00    	je     f0100d69 <mon_backtrace+0x125>
			info.eip_fn_name = "<unknown>";
			info.eip_fn_namelen = 9;
			info.eip_fn_addr = eip;
			info.eip_fn_narg = 0;
			char display_eip_fn_name[30];
			debuginfo_eip(eip,&info);
f0100c89:	8d 5d d0             	lea    -0x30(%ebp),%ebx
f0100c8c:	8b 45 9c             	mov    -0x64(%ebp),%eax
f0100c8f:	8b 55 98             	mov    -0x68(%ebp),%edx
f0100c92:	8b 4d 94             	mov    -0x6c(%ebp),%ecx
	cprintf("Stack backtrace:\n");
	
	while(ebp != 0x00)
		{
			
			cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",ebp,eip,arg[0],arg[1],arg[2],arg[3],arg[4]);
f0100c95:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0100c99:	89 54 24 18          	mov    %edx,0x18(%esp)
f0100c9d:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100ca1:	8b 45 a0             	mov    -0x60(%ebp),%eax
f0100ca4:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100ca8:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100cab:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100caf:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0100cb3:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100cb7:	c7 04 24 54 4a 10 f0 	movl   $0xf0104a54,(%esp)
f0100cbe:	e8 9f 25 00 00       	call   f0103262 <cprintf>
			struct Eipdebuginfo info;
			info.eip_file = "<unknown>";
f0100cc3:	c7 45 d0 f6 46 10 f0 	movl   $0xf01046f6,-0x30(%ebp)
			info.eip_line = 0;
f0100cca:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
			info.eip_fn_name = "<unknown>";
f0100cd1:	c7 45 d8 f6 46 10 f0 	movl   $0xf01046f6,-0x28(%ebp)
			info.eip_fn_namelen = 9;
f0100cd8:	c7 45 dc 09 00 00 00 	movl   $0x9,-0x24(%ebp)
			info.eip_fn_addr = eip;
f0100cdf:	89 7d e0             	mov    %edi,-0x20(%ebp)
			info.eip_fn_narg = 0;
f0100ce2:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
			char display_eip_fn_name[30];
			debuginfo_eip(eip,&info);
f0100ce9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100ced:	89 3c 24             	mov    %edi,(%esp)
f0100cf0:	e8 67 26 00 00       	call   f010335c <debuginfo_eip>
			int i;
			for ( i=0;(info.eip_fn_name[i]!=':')&&( i<30); i++)
f0100cf5:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0100cf8:	0f b6 11             	movzbl (%ecx),%edx
f0100cfb:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d00:	80 fa 3a             	cmp    $0x3a,%dl
f0100d03:	74 15                	je     f0100d1a <mon_backtrace+0xd6>
				display_eip_fn_name[i]=info.eip_fn_name[i];
f0100d05:	88 54 05 b2          	mov    %dl,-0x4e(%ebp,%eax,1)
			info.eip_fn_addr = eip;
			info.eip_fn_narg = 0;
			char display_eip_fn_name[30];
			debuginfo_eip(eip,&info);
			int i;
			for ( i=0;(info.eip_fn_name[i]!=':')&&( i<30); i++)
f0100d09:	83 c0 01             	add    $0x1,%eax
f0100d0c:	0f b6 14 01          	movzbl (%ecx,%eax,1),%edx
f0100d10:	80 fa 3a             	cmp    $0x3a,%dl
f0100d13:	74 05                	je     f0100d1a <mon_backtrace+0xd6>
f0100d15:	83 f8 1d             	cmp    $0x1d,%eax
f0100d18:	7e eb                	jle    f0100d05 <mon_backtrace+0xc1>
				display_eip_fn_name[i]=info.eip_fn_name[i];
			display_eip_fn_name[i]='\0';
f0100d1a:	c6 44 05 b2 00       	movb   $0x0,-0x4e(%ebp,%eax,1)
			cprintf("    %s:%d: %s+%d\n",info.eip_file,info.eip_line,display_eip_fn_name,(eip-info.eip_fn_addr));
f0100d1f:	2b 7d e0             	sub    -0x20(%ebp),%edi
f0100d22:	89 7c 24 10          	mov    %edi,0x10(%esp)
f0100d26:	8d 45 b2             	lea    -0x4e(%ebp),%eax
f0100d29:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d2d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100d30:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d34:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100d37:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d3b:	c7 04 24 00 47 10 f0 	movl   $0xf0104700,(%esp)
f0100d42:	e8 1b 25 00 00       	call   f0103262 <cprintf>
			ebp = *(uint32_t *)ebp;
f0100d47:	8b 36                	mov    (%esi),%esi
			eip = *((uint32_t*)ebp+1);
f0100d49:	8b 7e 04             	mov    0x4(%esi),%edi
			arg[0] = *((uint32_t*)ebp+2);
f0100d4c:	8b 46 08             	mov    0x8(%esi),%eax
f0100d4f:	89 45 a4             	mov    %eax,-0x5c(%ebp)
			arg[1] = *((uint32_t*)ebp+3);
f0100d52:	8b 46 0c             	mov    0xc(%esi),%eax
f0100d55:	89 45 a0             	mov    %eax,-0x60(%ebp)
			arg[2] = *((uint32_t*)ebp+4);
f0100d58:	8b 46 10             	mov    0x10(%esi),%eax
			arg[3] = *((uint32_t*)ebp+5);
f0100d5b:	8b 56 14             	mov    0x14(%esi),%edx
			arg[4] = *((uint32_t*)ebp+6);
f0100d5e:	8b 4e 18             	mov    0x18(%esi),%ecx
	arg[3] = *((uint32_t*)ebp+5);
	arg[4] = *((uint32_t*)ebp+6);

	cprintf("Stack backtrace:\n");
	
	while(ebp != 0x00)
f0100d61:	85 f6                	test   %esi,%esi
f0100d63:	0f 85 2c ff ff ff    	jne    f0100c95 <mon_backtrace+0x51>
			arg[3] = *((uint32_t*)ebp+5);
			arg[4] = *((uint32_t*)ebp+6);
			
		}
	return 0;
}
f0100d69:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d6e:	81 c4 8c 00 00 00    	add    $0x8c,%esp
f0100d74:	5b                   	pop    %ebx
f0100d75:	5e                   	pop    %esi
f0100d76:	5f                   	pop    %edi
f0100d77:	5d                   	pop    %ebp
f0100d78:	c3                   	ret    

f0100d79 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100d79:	55                   	push   %ebp
f0100d7a:	89 e5                	mov    %esp,%ebp
f0100d7c:	57                   	push   %edi
f0100d7d:	56                   	push   %esi
f0100d7e:	53                   	push   %ebx
f0100d7f:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("\033[0;32;40mWelcome to the \033[0;36;41mJOS kernel monitor!\033[0;37;40m\n");
f0100d82:	c7 04 24 88 4a 10 f0 	movl   $0xf0104a88,(%esp)
f0100d89:	e8 d4 24 00 00       	call   f0103262 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100d8e:	c7 04 24 cc 4a 10 f0 	movl   $0xf0104acc,(%esp)
f0100d95:	e8 c8 24 00 00       	call   f0103262 <cprintf>


	while (1) {
		buf = readline("K> ");
f0100d9a:	c7 04 24 12 47 10 f0 	movl   $0xf0104712,(%esp)
f0100da1:	e8 3a 2e 00 00       	call   f0103be0 <readline>
f0100da6:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100da8:	85 c0                	test   %eax,%eax
f0100daa:	74 ee                	je     f0100d9a <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100dac:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100db3:	be 00 00 00 00       	mov    $0x0,%esi
f0100db8:	eb 06                	jmp    f0100dc0 <monitor+0x47>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100dba:	c6 03 00             	movb   $0x0,(%ebx)
f0100dbd:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100dc0:	0f b6 03             	movzbl (%ebx),%eax
f0100dc3:	84 c0                	test   %al,%al
f0100dc5:	74 6a                	je     f0100e31 <monitor+0xb8>
f0100dc7:	0f be c0             	movsbl %al,%eax
f0100dca:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100dce:	c7 04 24 16 47 10 f0 	movl   $0xf0104716,(%esp)
f0100dd5:	e8 31 30 00 00       	call   f0103e0b <strchr>
f0100dda:	85 c0                	test   %eax,%eax
f0100ddc:	75 dc                	jne    f0100dba <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f0100dde:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100de1:	74 4e                	je     f0100e31 <monitor+0xb8>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100de3:	83 fe 0f             	cmp    $0xf,%esi
f0100de6:	75 16                	jne    f0100dfe <monitor+0x85>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100de8:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100def:	00 
f0100df0:	c7 04 24 1b 47 10 f0 	movl   $0xf010471b,(%esp)
f0100df7:	e8 66 24 00 00       	call   f0103262 <cprintf>
f0100dfc:	eb 9c                	jmp    f0100d9a <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f0100dfe:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100e02:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f0100e05:	0f b6 03             	movzbl (%ebx),%eax
f0100e08:	84 c0                	test   %al,%al
f0100e0a:	75 0c                	jne    f0100e18 <monitor+0x9f>
f0100e0c:	eb b2                	jmp    f0100dc0 <monitor+0x47>
			buf++;
f0100e0e:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100e11:	0f b6 03             	movzbl (%ebx),%eax
f0100e14:	84 c0                	test   %al,%al
f0100e16:	74 a8                	je     f0100dc0 <monitor+0x47>
f0100e18:	0f be c0             	movsbl %al,%eax
f0100e1b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e1f:	c7 04 24 16 47 10 f0 	movl   $0xf0104716,(%esp)
f0100e26:	e8 e0 2f 00 00       	call   f0103e0b <strchr>
f0100e2b:	85 c0                	test   %eax,%eax
f0100e2d:	74 df                	je     f0100e0e <monitor+0x95>
f0100e2f:	eb 8f                	jmp    f0100dc0 <monitor+0x47>
			buf++;
	}
	argv[argc] = 0;
f0100e31:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100e38:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100e39:	85 f6                	test   %esi,%esi
f0100e3b:	0f 84 59 ff ff ff    	je     f0100d9a <monitor+0x21>
f0100e41:	bb 00 4c 10 f0       	mov    $0xf0104c00,%ebx
f0100e46:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100e4b:	8b 03                	mov    (%ebx),%eax
f0100e4d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e51:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100e54:	89 04 24             	mov    %eax,(%esp)
f0100e57:	e8 34 2f 00 00       	call   f0103d90 <strcmp>
f0100e5c:	85 c0                	test   %eax,%eax
f0100e5e:	75 24                	jne    f0100e84 <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f0100e60:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0100e63:	8b 55 08             	mov    0x8(%ebp),%edx
f0100e66:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100e6a:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100e6d:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100e71:	89 34 24             	mov    %esi,(%esp)
f0100e74:	ff 14 85 08 4c 10 f0 	call   *-0xfefb3f8(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100e7b:	85 c0                	test   %eax,%eax
f0100e7d:	78 28                	js     f0100ea7 <monitor+0x12e>
f0100e7f:	e9 16 ff ff ff       	jmp    f0100d9a <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100e84:	83 c7 01             	add    $0x1,%edi
f0100e87:	83 c3 0c             	add    $0xc,%ebx
f0100e8a:	83 ff 07             	cmp    $0x7,%edi
f0100e8d:	75 bc                	jne    f0100e4b <monitor+0xd2>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100e8f:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100e92:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e96:	c7 04 24 38 47 10 f0 	movl   $0xf0104738,(%esp)
f0100e9d:	e8 c0 23 00 00       	call   f0103262 <cprintf>
f0100ea2:	e9 f3 fe ff ff       	jmp    f0100d9a <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100ea7:	83 c4 5c             	add    $0x5c,%esp
f0100eaa:	5b                   	pop    %ebx
f0100eab:	5e                   	pop    %esi
f0100eac:	5f                   	pop    %edi
f0100ead:	5d                   	pop    %ebp
f0100eae:	c3                   	ret    

f0100eaf <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f0100eaf:	55                   	push   %ebp
f0100eb0:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f0100eb2:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f0100eb5:	5d                   	pop    %ebp
f0100eb6:	c3                   	ret    
	...

f0100eb8 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100eb8:	55                   	push   %ebp
f0100eb9:	89 e5                	mov    %esp,%ebp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100ebb:	83 3d 7c 95 11 f0 00 	cmpl   $0x0,0xf011957c
f0100ec2:	75 11                	jne    f0100ed5 <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100ec4:	ba ab a9 11 f0       	mov    $0xf011a9ab,%edx
f0100ec9:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100ecf:	89 15 7c 95 11 f0    	mov    %edx,0xf011957c
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = ROUNDUP(nextfree, PGSIZE);
f0100ed5:	8b 15 7c 95 11 f0    	mov    0xf011957c,%edx
f0100edb:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f0100ee1:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	nextfree = result + n;
f0100ee7:	01 d0                	add    %edx,%eax
f0100ee9:	a3 7c 95 11 f0       	mov    %eax,0xf011957c
	//cprintf("\nnextfree:0x%08x",nextfree);
	return result;
}
f0100eee:	89 d0                	mov    %edx,%eax
f0100ef0:	5d                   	pop    %ebp
f0100ef1:	c3                   	ret    

f0100ef2 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100ef2:	55                   	push   %ebp
f0100ef3:	89 e5                	mov    %esp,%ebp
f0100ef5:	83 ec 18             	sub    $0x18,%esp
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100ef8:	89 d1                	mov    %edx,%ecx
f0100efa:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100efd:	8b 0c 88             	mov    (%eax,%ecx,4),%ecx
		return ~0;
f0100f00:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100f05:	f6 c1 01             	test   $0x1,%cl
f0100f08:	74 57                	je     f0100f61 <check_va2pa+0x6f>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100f0a:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f10:	89 c8                	mov    %ecx,%eax
f0100f12:	c1 e8 0c             	shr    $0xc,%eax
f0100f15:	3b 05 a0 99 11 f0    	cmp    0xf01199a0,%eax
f0100f1b:	72 20                	jb     f0100f3d <check_va2pa+0x4b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f1d:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100f21:	c7 44 24 08 bc 48 10 	movl   $0xf01048bc,0x8(%esp)
f0100f28:	f0 
f0100f29:	c7 44 24 04 f0 02 00 	movl   $0x2f0,0x4(%esp)
f0100f30:	00 
f0100f31:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0100f38:	e8 57 f1 ff ff       	call   f0100094 <_panic>
	if (!(p[PTX(va)] & PTE_P))
f0100f3d:	c1 ea 0c             	shr    $0xc,%edx
f0100f40:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100f46:	8b 84 91 00 00 00 f0 	mov    -0x10000000(%ecx,%edx,4),%eax
f0100f4d:	89 c2                	mov    %eax,%edx
f0100f4f:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100f52:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100f57:	85 d2                	test   %edx,%edx
f0100f59:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100f5e:	0f 44 c2             	cmove  %edx,%eax
}
f0100f61:	c9                   	leave  
f0100f62:	c3                   	ret    

f0100f63 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100f63:	55                   	push   %ebp
f0100f64:	89 e5                	mov    %esp,%ebp
f0100f66:	83 ec 18             	sub    $0x18,%esp
f0100f69:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0100f6c:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0100f6f:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100f71:	89 04 24             	mov    %eax,(%esp)
f0100f74:	e8 7b 22 00 00       	call   f01031f4 <mc146818_read>
f0100f79:	89 c6                	mov    %eax,%esi
f0100f7b:	83 c3 01             	add    $0x1,%ebx
f0100f7e:	89 1c 24             	mov    %ebx,(%esp)
f0100f81:	e8 6e 22 00 00       	call   f01031f4 <mc146818_read>
f0100f86:	c1 e0 08             	shl    $0x8,%eax
f0100f89:	09 f0                	or     %esi,%eax
}
f0100f8b:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0100f8e:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0100f91:	89 ec                	mov    %ebp,%esp
f0100f93:	5d                   	pop    %ebp
f0100f94:	c3                   	ret    

f0100f95 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100f95:	55                   	push   %ebp
f0100f96:	89 e5                	mov    %esp,%ebp
f0100f98:	57                   	push   %edi
f0100f99:	56                   	push   %esi
f0100f9a:	53                   	push   %ebx
f0100f9b:	83 ec 3c             	sub    $0x3c,%esp
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100f9e:	83 f8 01             	cmp    $0x1,%eax
f0100fa1:	19 f6                	sbb    %esi,%esi
f0100fa3:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
f0100fa9:	83 c6 01             	add    $0x1,%esi
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100fac:	8b 1d 80 95 11 f0    	mov    0xf0119580,%ebx
f0100fb2:	85 db                	test   %ebx,%ebx
f0100fb4:	75 1c                	jne    f0100fd2 <check_page_free_list+0x3d>
		panic("'page_free_list' is a null pointer!");
f0100fb6:	c7 44 24 08 54 4c 10 	movl   $0xf0104c54,0x8(%esp)
f0100fbd:	f0 
f0100fbe:	c7 44 24 04 33 02 00 	movl   $0x233,0x4(%esp)
f0100fc5:	00 
f0100fc6:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0100fcd:	e8 c2 f0 ff ff       	call   f0100094 <_panic>

	if (only_low_memory) {
f0100fd2:	85 c0                	test   %eax,%eax
f0100fd4:	74 50                	je     f0101026 <check_page_free_list+0x91>
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
f0100fd6:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0100fd9:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100fdc:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100fdf:	89 45 dc             	mov    %eax,-0x24(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100fe2:	89 d8                	mov    %ebx,%eax
f0100fe4:	2b 05 a8 99 11 f0    	sub    0xf01199a8,%eax
f0100fea:	c1 e0 09             	shl    $0x9,%eax
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100fed:	c1 e8 16             	shr    $0x16,%eax
f0100ff0:	39 f0                	cmp    %esi,%eax
f0100ff2:	0f 93 c0             	setae  %al
f0100ff5:	0f b6 c0             	movzbl %al,%eax
			*tp[pagetype] = pp;
f0100ff8:	8b 54 85 d8          	mov    -0x28(%ebp,%eax,4),%edx
f0100ffc:	89 1a                	mov    %ebx,(%edx)
			tp[pagetype] = &pp->pp_link;
f0100ffe:	89 5c 85 d8          	mov    %ebx,-0x28(%ebp,%eax,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0101002:	8b 1b                	mov    (%ebx),%ebx
f0101004:	85 db                	test   %ebx,%ebx
f0101006:	75 da                	jne    f0100fe2 <check_page_free_list+0x4d>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0101008:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010100b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0101011:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101014:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101017:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0101019:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010101c:	89 1d 80 95 11 f0    	mov    %ebx,0xf0119580
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101022:	85 db                	test   %ebx,%ebx
f0101024:	74 67                	je     f010108d <check_page_free_list+0xf8>
f0101026:	89 d8                	mov    %ebx,%eax
f0101028:	2b 05 a8 99 11 f0    	sub    0xf01199a8,%eax
f010102e:	c1 f8 03             	sar    $0x3,%eax
f0101031:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0101034:	89 c2                	mov    %eax,%edx
f0101036:	c1 ea 16             	shr    $0x16,%edx
f0101039:	39 f2                	cmp    %esi,%edx
f010103b:	73 4a                	jae    f0101087 <check_page_free_list+0xf2>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010103d:	89 c2                	mov    %eax,%edx
f010103f:	c1 ea 0c             	shr    $0xc,%edx
f0101042:	3b 15 a0 99 11 f0    	cmp    0xf01199a0,%edx
f0101048:	72 20                	jb     f010106a <check_page_free_list+0xd5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010104a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010104e:	c7 44 24 08 bc 48 10 	movl   $0xf01048bc,0x8(%esp)
f0101055:	f0 
f0101056:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010105d:	00 
f010105e:	c7 04 24 24 53 10 f0 	movl   $0xf0105324,(%esp)
f0101065:	e8 2a f0 ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f010106a:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0101071:	00 
f0101072:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0101079:	00 
	return (void *)(pa + KERNBASE);
f010107a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010107f:	89 04 24             	mov    %eax,(%esp)
f0101082:	e8 df 2d 00 00       	call   f0103e66 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101087:	8b 1b                	mov    (%ebx),%ebx
f0101089:	85 db                	test   %ebx,%ebx
f010108b:	75 99                	jne    f0101026 <check_page_free_list+0x91>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f010108d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101092:	e8 21 fe ff ff       	call   f0100eb8 <boot_alloc>
f0101097:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f010109a:	8b 15 80 95 11 f0    	mov    0xf0119580,%edx
f01010a0:	85 d2                	test   %edx,%edx
f01010a2:	0f 84 f6 01 00 00    	je     f010129e <check_page_free_list+0x309>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f01010a8:	8b 1d a8 99 11 f0    	mov    0xf01199a8,%ebx
f01010ae:	39 da                	cmp    %ebx,%edx
f01010b0:	72 4d                	jb     f01010ff <check_page_free_list+0x16a>
		assert(pp < pages + npages);
f01010b2:	a1 a0 99 11 f0       	mov    0xf01199a0,%eax
f01010b7:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01010ba:	8d 04 c3             	lea    (%ebx,%eax,8),%eax
f01010bd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01010c0:	39 c2                	cmp    %eax,%edx
f01010c2:	73 64                	jae    f0101128 <check_page_free_list+0x193>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f01010c4:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f01010c7:	89 d0                	mov    %edx,%eax
f01010c9:	29 d8                	sub    %ebx,%eax
f01010cb:	a8 07                	test   $0x7,%al
f01010cd:	0f 85 82 00 00 00    	jne    f0101155 <check_page_free_list+0x1c0>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01010d3:	c1 f8 03             	sar    $0x3,%eax
f01010d6:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f01010d9:	85 c0                	test   %eax,%eax
f01010db:	0f 84 a2 00 00 00    	je     f0101183 <check_page_free_list+0x1ee>
		assert(page2pa(pp) != IOPHYSMEM);
f01010e1:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f01010e6:	0f 84 c2 00 00 00    	je     f01011ae <check_page_free_list+0x219>
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f01010ec:	be 00 00 00 00       	mov    $0x0,%esi
f01010f1:	bf 00 00 00 00       	mov    $0x0,%edi
f01010f6:	e9 d7 00 00 00       	jmp    f01011d2 <check_page_free_list+0x23d>
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f01010fb:	39 da                	cmp    %ebx,%edx
f01010fd:	73 24                	jae    f0101123 <check_page_free_list+0x18e>
f01010ff:	c7 44 24 0c 32 53 10 	movl   $0xf0105332,0xc(%esp)
f0101106:	f0 
f0101107:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f010110e:	f0 
f010110f:	c7 44 24 04 4d 02 00 	movl   $0x24d,0x4(%esp)
f0101116:	00 
f0101117:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f010111e:	e8 71 ef ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0101123:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0101126:	72 24                	jb     f010114c <check_page_free_list+0x1b7>
f0101128:	c7 44 24 0c 53 53 10 	movl   $0xf0105353,0xc(%esp)
f010112f:	f0 
f0101130:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0101137:	f0 
f0101138:	c7 44 24 04 4e 02 00 	movl   $0x24e,0x4(%esp)
f010113f:	00 
f0101140:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0101147:	e8 48 ef ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f010114c:	89 d0                	mov    %edx,%eax
f010114e:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0101151:	a8 07                	test   $0x7,%al
f0101153:	74 24                	je     f0101179 <check_page_free_list+0x1e4>
f0101155:	c7 44 24 0c 78 4c 10 	movl   $0xf0104c78,0xc(%esp)
f010115c:	f0 
f010115d:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0101164:	f0 
f0101165:	c7 44 24 04 4f 02 00 	movl   $0x24f,0x4(%esp)
f010116c:	00 
f010116d:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0101174:	e8 1b ef ff ff       	call   f0100094 <_panic>
f0101179:	c1 f8 03             	sar    $0x3,%eax
f010117c:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f010117f:	85 c0                	test   %eax,%eax
f0101181:	75 24                	jne    f01011a7 <check_page_free_list+0x212>
f0101183:	c7 44 24 0c 67 53 10 	movl   $0xf0105367,0xc(%esp)
f010118a:	f0 
f010118b:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0101192:	f0 
f0101193:	c7 44 24 04 52 02 00 	movl   $0x252,0x4(%esp)
f010119a:	00 
f010119b:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f01011a2:	e8 ed ee ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f01011a7:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f01011ac:	75 24                	jne    f01011d2 <check_page_free_list+0x23d>
f01011ae:	c7 44 24 0c 78 53 10 	movl   $0xf0105378,0xc(%esp)
f01011b5:	f0 
f01011b6:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f01011bd:	f0 
f01011be:	c7 44 24 04 53 02 00 	movl   $0x253,0x4(%esp)
f01011c5:	00 
f01011c6:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f01011cd:	e8 c2 ee ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f01011d2:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f01011d7:	75 24                	jne    f01011fd <check_page_free_list+0x268>
f01011d9:	c7 44 24 0c ac 4c 10 	movl   $0xf0104cac,0xc(%esp)
f01011e0:	f0 
f01011e1:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f01011e8:	f0 
f01011e9:	c7 44 24 04 54 02 00 	movl   $0x254,0x4(%esp)
f01011f0:	00 
f01011f1:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f01011f8:	e8 97 ee ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f01011fd:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0101202:	75 24                	jne    f0101228 <check_page_free_list+0x293>
f0101204:	c7 44 24 0c 91 53 10 	movl   $0xf0105391,0xc(%esp)
f010120b:	f0 
f010120c:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0101213:	f0 
f0101214:	c7 44 24 04 55 02 00 	movl   $0x255,0x4(%esp)
f010121b:	00 
f010121c:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0101223:	e8 6c ee ff ff       	call   f0100094 <_panic>
f0101228:	89 c1                	mov    %eax,%ecx
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f010122a:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f010122f:	76 57                	jbe    f0101288 <check_page_free_list+0x2f3>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101231:	c1 e8 0c             	shr    $0xc,%eax
f0101234:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101237:	77 20                	ja     f0101259 <check_page_free_list+0x2c4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101239:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010123d:	c7 44 24 08 bc 48 10 	movl   $0xf01048bc,0x8(%esp)
f0101244:	f0 
f0101245:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010124c:	00 
f010124d:	c7 04 24 24 53 10 f0 	movl   $0xf0105324,(%esp)
f0101254:	e8 3b ee ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101259:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f010125f:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0101262:	76 29                	jbe    f010128d <check_page_free_list+0x2f8>
f0101264:	c7 44 24 0c d0 4c 10 	movl   $0xf0104cd0,0xc(%esp)
f010126b:	f0 
f010126c:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0101273:	f0 
f0101274:	c7 44 24 04 56 02 00 	movl   $0x256,0x4(%esp)
f010127b:	00 
f010127c:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0101283:	e8 0c ee ff ff       	call   f0100094 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0101288:	83 c7 01             	add    $0x1,%edi
f010128b:	eb 03                	jmp    f0101290 <check_page_free_list+0x2fb>
		else
			++nfree_extmem;
f010128d:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0101290:	8b 12                	mov    (%edx),%edx
f0101292:	85 d2                	test   %edx,%edx
f0101294:	0f 85 61 fe ff ff    	jne    f01010fb <check_page_free_list+0x166>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f010129a:	85 ff                	test   %edi,%edi
f010129c:	7f 24                	jg     f01012c2 <check_page_free_list+0x32d>
f010129e:	c7 44 24 0c ab 53 10 	movl   $0xf01053ab,0xc(%esp)
f01012a5:	f0 
f01012a6:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f01012ad:	f0 
f01012ae:	c7 44 24 04 5e 02 00 	movl   $0x25e,0x4(%esp)
f01012b5:	00 
f01012b6:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f01012bd:	e8 d2 ed ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f01012c2:	85 f6                	test   %esi,%esi
f01012c4:	7f 24                	jg     f01012ea <check_page_free_list+0x355>
f01012c6:	c7 44 24 0c bd 53 10 	movl   $0xf01053bd,0xc(%esp)
f01012cd:	f0 
f01012ce:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f01012d5:	f0 
f01012d6:	c7 44 24 04 5f 02 00 	movl   $0x25f,0x4(%esp)
f01012dd:	00 
f01012de:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f01012e5:	e8 aa ed ff ff       	call   f0100094 <_panic>
}
f01012ea:	83 c4 3c             	add    $0x3c,%esp
f01012ed:	5b                   	pop    %ebx
f01012ee:	5e                   	pop    %esi
f01012ef:	5f                   	pop    %edi
f01012f0:	5d                   	pop    %ebp
f01012f1:	c3                   	ret    

f01012f2 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f01012f2:	55                   	push   %ebp
f01012f3:	89 e5                	mov    %esp,%ebp
f01012f5:	56                   	push   %esi
f01012f6:	53                   	push   %ebx
f01012f7:	83 ec 10             	sub    $0x10,%esp
	// free pages!
	size_t i;
	//size_t a=0;
	//size_t b=0;
	//size_t c=0;
	page_free_list = NULL;
f01012fa:	c7 05 80 95 11 f0 00 	movl   $0x0,0xf0119580
f0101301:	00 00 00 
	physaddr_t pgnum_IOPHYSMEM = PGNUM (IOPHYSMEM);
	physaddr_t pgnum_EXTPHYSMEM =PGNUM ( PADDR (ROUNDUP(pages+npages* sizeof (struct Page),PGSIZE)));
f0101304:	a1 a0 99 11 f0       	mov    0xf01199a0,%eax
f0101309:	89 c6                	mov    %eax,%esi
f010130b:	c1 e6 06             	shl    $0x6,%esi
f010130e:	03 35 a8 99 11 f0    	add    0xf01199a8,%esi
f0101314:	81 c6 ff 0f 00 00    	add    $0xfff,%esi
f010131a:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101320:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0101326:	77 20                	ja     f0101348 <page_init+0x56>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101328:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010132c:	c7 44 24 08 18 4d 10 	movl   $0xf0104d18,0x8(%esp)
f0101333:	f0 
f0101334:	c7 44 24 04 02 01 00 	movl   $0x102,0x4(%esp)
f010133b:	00 
f010133c:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0101343:	e8 4c ed ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101348:	81 c6 00 00 00 10    	add    $0x10000000,%esi
f010134e:	c1 ee 0c             	shr    $0xc,%esi
	//PGNUM (ROUNDUP(pages+npages* sizeof (struct Page),PGSIZE))-PGNUM(kern_pgdir)+PGNUM(EXTPHYSMEM);
	for (i = 1; i < npages; i++) 
f0101351:	83 f8 01             	cmp    $0x1,%eax
f0101354:	76 6f                	jbe    f01013c5 <page_init+0xd3>
f0101356:	ba 08 00 00 00       	mov    $0x8,%edx
f010135b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101360:	b8 01 00 00 00       	mov    $0x1,%eax
	{
		
		
		if(i<pgnum_IOPHYSMEM)
f0101365:	3d 9f 00 00 00       	cmp    $0x9f,%eax
f010136a:	77 1a                	ja     f0101386 <page_init+0x94>
		{
			pages[i].pp_ref = 0;
f010136c:	89 d3                	mov    %edx,%ebx
f010136e:	03 1d a8 99 11 f0    	add    0xf01199a8,%ebx
f0101374:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
			pages[i].pp_link = page_free_list;
f010137a:	89 0b                	mov    %ecx,(%ebx)
			page_free_list = &pages[i];
f010137c:	89 d1                	mov    %edx,%ecx
f010137e:	03 0d a8 99 11 f0    	add    0xf01199a8,%ecx
f0101384:	eb 2b                	jmp    f01013b1 <page_init+0xbf>
			//a++;
		}
		else if( i>pgnum_EXTPHYSMEM)
f0101386:	39 c6                	cmp    %eax,%esi
f0101388:	73 1a                	jae    f01013a4 <page_init+0xb2>
		{
			pages[i].pp_ref = 0;
f010138a:	8b 1d a8 99 11 f0    	mov    0xf01199a8,%ebx
f0101390:	66 c7 44 13 04 00 00 	movw   $0x0,0x4(%ebx,%edx,1)
			pages[i].pp_link = page_free_list;
f0101397:	89 0c 13             	mov    %ecx,(%ebx,%edx,1)
			page_free_list = &pages[i];
f010139a:	89 d1                	mov    %edx,%ecx
f010139c:	03 0d a8 99 11 f0    	add    0xf01199a8,%ecx
f01013a2:	eb 0d                	jmp    f01013b1 <page_init+0xbf>
			//b++;
		}
		else
		{
			pages[i].pp_ref = 1;
f01013a4:	8b 1d a8 99 11 f0    	mov    0xf01199a8,%ebx
f01013aa:	66 c7 44 13 04 01 00 	movw   $0x1,0x4(%ebx,%edx,1)
	//size_t c=0;
	page_free_list = NULL;
	physaddr_t pgnum_IOPHYSMEM = PGNUM (IOPHYSMEM);
	physaddr_t pgnum_EXTPHYSMEM =PGNUM ( PADDR (ROUNDUP(pages+npages* sizeof (struct Page),PGSIZE)));
	//PGNUM (ROUNDUP(pages+npages* sizeof (struct Page),PGSIZE))-PGNUM(kern_pgdir)+PGNUM(EXTPHYSMEM);
	for (i = 1; i < npages; i++) 
f01013b1:	83 c0 01             	add    $0x1,%eax
f01013b4:	83 c2 08             	add    $0x8,%edx
f01013b7:	39 05 a0 99 11 f0    	cmp    %eax,0xf01199a0
f01013bd:	77 a6                	ja     f0101365 <page_init+0x73>
f01013bf:	89 0d 80 95 11 f0    	mov    %ecx,0xf0119580
			pages[i].pp_ref = 1;
			//c++;
		}
	}
	//cprintf("\n a:%d,b:%d c:%d  ",a,b,c);
}
f01013c5:	83 c4 10             	add    $0x10,%esp
f01013c8:	5b                   	pop    %ebx
f01013c9:	5e                   	pop    %esi
f01013ca:	5d                   	pop    %ebp
f01013cb:	c3                   	ret    

f01013cc <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct Page *
page_alloc(int alloc_flags)
{
f01013cc:	55                   	push   %ebp
f01013cd:	89 e5                	mov    %esp,%ebp
f01013cf:	53                   	push   %ebx
f01013d0:	83 ec 14             	sub    $0x14,%esp
f01013d3:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	if ((alloc_flags==0 ||alloc_flags==ALLOC_ZERO)&& page_free_list!=NULL)
f01013d6:	83 f8 01             	cmp    $0x1,%eax
f01013d9:	77 71                	ja     f010144c <page_alloc+0x80>
f01013db:	8b 1d 80 95 11 f0    	mov    0xf0119580,%ebx
f01013e1:	85 db                	test   %ebx,%ebx
f01013e3:	74 6c                	je     f0101451 <page_alloc+0x85>
	{
		struct Page * temp_alloc_page = page_free_list;
		if(page_free_list->pp_link!=NULL)
f01013e5:	8b 13                	mov    (%ebx),%edx
			page_free_list=page_free_list->pp_link;
f01013e7:	89 15 80 95 11 f0    	mov    %edx,0xf0119580
		else 
			page_free_list=NULL;
		if(alloc_flags==ALLOC_ZERO)
f01013ed:	83 f8 01             	cmp    $0x1,%eax
f01013f0:	75 5f                	jne    f0101451 <page_alloc+0x85>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01013f2:	89 d8                	mov    %ebx,%eax
f01013f4:	2b 05 a8 99 11 f0    	sub    0xf01199a8,%eax
f01013fa:	c1 f8 03             	sar    $0x3,%eax
f01013fd:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101400:	89 c2                	mov    %eax,%edx
f0101402:	c1 ea 0c             	shr    $0xc,%edx
f0101405:	3b 15 a0 99 11 f0    	cmp    0xf01199a0,%edx
f010140b:	72 20                	jb     f010142d <page_alloc+0x61>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010140d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101411:	c7 44 24 08 bc 48 10 	movl   $0xf01048bc,0x8(%esp)
f0101418:	f0 
f0101419:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101420:	00 
f0101421:	c7 04 24 24 53 10 f0 	movl   $0xf0105324,(%esp)
f0101428:	e8 67 ec ff ff       	call   f0100094 <_panic>
			memset(page2kva(temp_alloc_page), 0, PGSIZE);
f010142d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101434:	00 
f0101435:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010143c:	00 
	return (void *)(pa + KERNBASE);
f010143d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101442:	89 04 24             	mov    %eax,(%esp)
f0101445:	e8 1c 2a 00 00       	call   f0103e66 <memset>
f010144a:	eb 05                	jmp    f0101451 <page_alloc+0x85>
		return temp_alloc_page;
	}
	else
		return NULL;
f010144c:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f0101451:	89 d8                	mov    %ebx,%eax
f0101453:	83 c4 14             	add    $0x14,%esp
f0101456:	5b                   	pop    %ebx
f0101457:	5d                   	pop    %ebp
f0101458:	c3                   	ret    

f0101459 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct Page *pp)
{
f0101459:	55                   	push   %ebp
f010145a:	89 e5                	mov    %esp,%ebp
f010145c:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
//	pp->pp_ref = 0;
	pp->pp_link = page_free_list;
f010145f:	8b 15 80 95 11 f0    	mov    0xf0119580,%edx
f0101465:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0101467:	a3 80 95 11 f0       	mov    %eax,0xf0119580
}
f010146c:	5d                   	pop    %ebp
f010146d:	c3                   	ret    

f010146e <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct Page* pp)
{
f010146e:	55                   	push   %ebp
f010146f:	89 e5                	mov    %esp,%ebp
f0101471:	83 ec 04             	sub    $0x4,%esp
f0101474:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0101477:	0f b7 50 04          	movzwl 0x4(%eax),%edx
f010147b:	83 ea 01             	sub    $0x1,%edx
f010147e:	66 89 50 04          	mov    %dx,0x4(%eax)
f0101482:	66 85 d2             	test   %dx,%dx
f0101485:	75 08                	jne    f010148f <page_decref+0x21>
		page_free(pp);
f0101487:	89 04 24             	mov    %eax,(%esp)
f010148a:	e8 ca ff ff ff       	call   f0101459 <page_free>
}
f010148f:	c9                   	leave  
f0101490:	c3                   	ret    

f0101491 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0101491:	55                   	push   %ebp
f0101492:	89 e5                	mov    %esp,%ebp
f0101494:	56                   	push   %esi
f0101495:	53                   	push   %ebx
f0101496:	83 ec 10             	sub    $0x10,%esp
f0101499:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	pde_t *pde;//page directory entry,
	pte_t *pte;//page table entry
	pde=(pde_t *)pgdir+PDX(va);//get the entry of pde
f010149c:	89 f3                	mov    %esi,%ebx
f010149e:	c1 eb 16             	shr    $0x16,%ebx
f01014a1:	c1 e3 02             	shl    $0x2,%ebx
f01014a4:	03 5d 08             	add    0x8(%ebp),%ebx

	if (*pde & PTE_P)//the address exists
f01014a7:	8b 03                	mov    (%ebx),%eax
f01014a9:	a8 01                	test   $0x1,%al
f01014ab:	74 44                	je     f01014f1 <pgdir_walk+0x60>
	{
		pte=(pte_t *)KADDR(PTE_ADDR(*pde))+PTX(va);
f01014ad:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01014b2:	89 c2                	mov    %eax,%edx
f01014b4:	c1 ea 0c             	shr    $0xc,%edx
f01014b7:	3b 15 a0 99 11 f0    	cmp    0xf01199a0,%edx
f01014bd:	72 20                	jb     f01014df <pgdir_walk+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014bf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01014c3:	c7 44 24 08 bc 48 10 	movl   $0xf01048bc,0x8(%esp)
f01014ca:	f0 
f01014cb:	c7 44 24 04 73 01 00 	movl   $0x173,0x4(%esp)
f01014d2:	00 
f01014d3:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f01014da:	e8 b5 eb ff ff       	call   f0100094 <_panic>
f01014df:	c1 ee 0a             	shr    $0xa,%esi
f01014e2:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f01014e8:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
		return pte;
f01014ef:	eb 7d                	jmp    f010156e <pgdir_walk+0xdd>
	}
	//the page does not exist
	if (create )//create a new page table 
f01014f1:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01014f5:	74 6b                	je     f0101562 <pgdir_walk+0xd1>
	{	
		struct Page *pp;
		pp=page_alloc(ALLOC_ZERO);
f01014f7:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01014fe:	e8 c9 fe ff ff       	call   f01013cc <page_alloc>
		if (pp!=NULL)
f0101503:	85 c0                	test   %eax,%eax
f0101505:	74 62                	je     f0101569 <pgdir_walk+0xd8>
		{
			pp->pp_ref=1;
f0101507:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f010150d:	2b 05 a8 99 11 f0    	sub    0xf01199a8,%eax
f0101513:	c1 f8 03             	sar    $0x3,%eax
f0101516:	c1 e0 0c             	shl    $0xc,%eax
			*pde = page2pa(pp)|PTE_U|PTE_W|PTE_P ;
f0101519:	83 c8 07             	or     $0x7,%eax
f010151c:	89 03                	mov    %eax,(%ebx)
			pte=(pte_t *)KADDR(PTE_ADDR(*pde))+PTX(va);
f010151e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101523:	89 c2                	mov    %eax,%edx
f0101525:	c1 ea 0c             	shr    $0xc,%edx
f0101528:	3b 15 a0 99 11 f0    	cmp    0xf01199a0,%edx
f010152e:	72 20                	jb     f0101550 <pgdir_walk+0xbf>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101530:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101534:	c7 44 24 08 bc 48 10 	movl   $0xf01048bc,0x8(%esp)
f010153b:	f0 
f010153c:	c7 44 24 04 7f 01 00 	movl   $0x17f,0x4(%esp)
f0101543:	00 
f0101544:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f010154b:	e8 44 eb ff ff       	call   f0100094 <_panic>
f0101550:	c1 ee 0a             	shr    $0xa,%esi
f0101553:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0101559:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
			return pte;
f0101560:	eb 0c                	jmp    f010156e <pgdir_walk+0xdd>
		}
	}
	return NULL;
f0101562:	b8 00 00 00 00       	mov    $0x0,%eax
f0101567:	eb 05                	jmp    f010156e <pgdir_walk+0xdd>
f0101569:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010156e:	83 c4 10             	add    $0x10,%esp
f0101571:	5b                   	pop    %ebx
f0101572:	5e                   	pop    %esi
f0101573:	5d                   	pop    %ebp
f0101574:	c3                   	ret    

f0101575 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0101575:	55                   	push   %ebp
f0101576:	89 e5                	mov    %esp,%ebp
f0101578:	57                   	push   %edi
f0101579:	56                   	push   %esi
f010157a:	53                   	push   %ebx
f010157b:	83 ec 2c             	sub    $0x2c,%esp
f010157e:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101581:	89 d7                	mov    %edx,%edi
f0101583:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in
	if(size%PGSIZE!=0)
f0101586:	f7 c1 ff 0f 00 00    	test   $0xfff,%ecx
f010158c:	74 0f                	je     f010159d <boot_map_region+0x28>
		size=ROUNDUP(size,PGSIZE);//panic(" Size must be a multiple of PGSIZE.");
f010158e:	89 c8                	mov    %ecx,%eax
f0101590:	05 ff 0f 00 00       	add    $0xfff,%eax
f0101595:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010159a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	pte_t *pte ;
	size_t i=0;
	while(i<size)
f010159d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01015a1:	74 34                	je     f01015d7 <boot_map_region+0x62>
{
	// Fill this function in
	if(size%PGSIZE!=0)
		size=ROUNDUP(size,PGSIZE);//panic(" Size must be a multiple of PGSIZE.");
	pte_t *pte ;
	size_t i=0;
f01015a3:	bb 00 00 00 00       	mov    $0x0,%ebx
// above UTOP. As such, it should *not* change the pp_ref field on the
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f01015a8:	8b 75 08             	mov    0x8(%ebp),%esi
f01015ab:	01 de                	add    %ebx,%esi
		size=ROUNDUP(size,PGSIZE);//panic(" Size must be a multiple of PGSIZE.");
	pte_t *pte ;
	size_t i=0;
	while(i<size)
	{
		pte=pgdir_walk(pgdir, (void *)va, 1);
f01015ad:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01015b4:	00 
// above UTOP. As such, it should *not* change the pp_ref field on the
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f01015b5:	8d 04 3b             	lea    (%ebx,%edi,1),%eax
		size=ROUNDUP(size,PGSIZE);//panic(" Size must be a multiple of PGSIZE.");
	pte_t *pte ;
	size_t i=0;
	while(i<size)
	{
		pte=pgdir_walk(pgdir, (void *)va, 1);
f01015b8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015bc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01015bf:	89 04 24             	mov    %eax,(%esp)
f01015c2:	e8 ca fe ff ff       	call   f0101491 <pgdir_walk>
		*pte= pa|perm;
f01015c7:	0b 75 0c             	or     0xc(%ebp),%esi
f01015ca:	89 30                	mov    %esi,(%eax)
		pa+=PGSIZE;
		va+=PGSIZE;
		i+=PGSIZE;
f01015cc:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// Fill this function in
	if(size%PGSIZE!=0)
		size=ROUNDUP(size,PGSIZE);//panic(" Size must be a multiple of PGSIZE.");
	pte_t *pte ;
	size_t i=0;
	while(i<size)
f01015d2:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f01015d5:	77 d1                	ja     f01015a8 <boot_map_region+0x33>
		*pte= pa|perm;
		pa+=PGSIZE;
		va+=PGSIZE;
		i+=PGSIZE;
	}
}
f01015d7:	83 c4 2c             	add    $0x2c,%esp
f01015da:	5b                   	pop    %ebx
f01015db:	5e                   	pop    %esi
f01015dc:	5f                   	pop    %edi
f01015dd:	5d                   	pop    %ebp
f01015de:	c3                   	ret    

f01015df <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01015df:	55                   	push   %ebp
f01015e0:	89 e5                	mov    %esp,%ebp
f01015e2:	53                   	push   %ebx
f01015e3:	83 ec 14             	sub    $0x14,%esp
f01015e6:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pte = pgdir_walk(pgdir,(void *)va, 0);
f01015e9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01015f0:	00 
f01015f1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015f4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015f8:	8b 45 08             	mov    0x8(%ebp),%eax
f01015fb:	89 04 24             	mov    %eax,(%esp)
f01015fe:	e8 8e fe ff ff       	call   f0101491 <pgdir_walk>
	if (pte==NULL)
f0101603:	85 c0                	test   %eax,%eax
f0101605:	74 3e                	je     f0101645 <page_lookup+0x66>
	{
		return NULL;		
	}
	if (pte_store != 0) 
f0101607:	85 db                	test   %ebx,%ebx
f0101609:	74 02                	je     f010160d <page_lookup+0x2e>
	{
		*pte_store = pte;
f010160b:	89 03                	mov    %eax,(%ebx)
	}
	if (*pte & PTE_P) 
f010160d:	8b 00                	mov    (%eax),%eax
f010160f:	a8 01                	test   $0x1,%al
f0101611:	74 39                	je     f010164c <page_lookup+0x6d>
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101613:	c1 e8 0c             	shr    $0xc,%eax
f0101616:	3b 05 a0 99 11 f0    	cmp    0xf01199a0,%eax
f010161c:	72 1c                	jb     f010163a <page_lookup+0x5b>
		panic("pa2page called with invalid pa");
f010161e:	c7 44 24 08 3c 4d 10 	movl   $0xf0104d3c,0x8(%esp)
f0101625:	f0 
f0101626:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f010162d:	00 
f010162e:	c7 04 24 24 53 10 f0 	movl   $0xf0105324,(%esp)
f0101635:	e8 5a ea ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f010163a:	c1 e0 03             	shl    $0x3,%eax
f010163d:	03 05 a8 99 11 f0    	add    0xf01199a8,%eax
	{
		return pa2page (PTE_ADDR (*pte));
f0101643:	eb 0c                	jmp    f0101651 <page_lookup+0x72>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t *pte = pgdir_walk(pgdir,(void *)va, 0);
	if (pte==NULL)
	{
		return NULL;		
f0101645:	b8 00 00 00 00       	mov    $0x0,%eax
f010164a:	eb 05                	jmp    f0101651 <page_lookup+0x72>
	}
	if (*pte & PTE_P) 
	{
		return pa2page (PTE_ADDR (*pte));
	}
	return NULL;
f010164c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101651:	83 c4 14             	add    $0x14,%esp
f0101654:	5b                   	pop    %ebx
f0101655:	5d                   	pop    %ebp
f0101656:	c3                   	ret    

f0101657 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0101657:	55                   	push   %ebp
f0101658:	89 e5                	mov    %esp,%ebp
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010165a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010165d:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0101660:	5d                   	pop    %ebp
f0101661:	c3                   	ret    

f0101662 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101662:	55                   	push   %ebp
f0101663:	89 e5                	mov    %esp,%ebp
f0101665:	83 ec 28             	sub    $0x28,%esp
f0101668:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f010166b:	89 75 fc             	mov    %esi,-0x4(%ebp)
f010166e:	8b 75 08             	mov    0x8(%ebp),%esi
f0101671:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *pte;
	struct Page *pp;
    	pp=page_lookup (pgdir, va, &pte);
f0101674:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101677:	89 44 24 08          	mov    %eax,0x8(%esp)
f010167b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010167f:	89 34 24             	mov    %esi,(%esp)
f0101682:	e8 58 ff ff ff       	call   f01015df <page_lookup>
	if (pp != NULL) 
f0101687:	85 c0                	test   %eax,%eax
f0101689:	74 21                	je     f01016ac <page_remove+0x4a>
	{
		page_decref (pp);//- The ref count on the physical page should decrement.
f010168b:	89 04 24             	mov    %eax,(%esp)
f010168e:	e8 db fd ff ff       	call   f010146e <page_decref>
//   - The physical page should be freed if the refcount reaches 0.
		if(pte!=NULL)
f0101693:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101696:	85 c0                	test   %eax,%eax
f0101698:	74 06                	je     f01016a0 <page_remove+0x3e>
			*pte = 0;// The pg table entry corresponding to 'va' should be set to 0. (if such a PTE exists)
f010169a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		tlb_invalidate (pgdir, va);//The TLB must be invalidated if you remove an entry from  the page table.
f01016a0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01016a4:	89 34 24             	mov    %esi,(%esp)
f01016a7:	e8 ab ff ff ff       	call   f0101657 <tlb_invalidate>
	}
}
f01016ac:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f01016af:	8b 75 fc             	mov    -0x4(%ebp),%esi
f01016b2:	89 ec                	mov    %ebp,%esp
f01016b4:	5d                   	pop    %ebp
f01016b5:	c3                   	ret    

f01016b6 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{
f01016b6:	55                   	push   %ebp
f01016b7:	89 e5                	mov    %esp,%ebp
f01016b9:	83 ec 28             	sub    $0x28,%esp
f01016bc:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f01016bf:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01016c2:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01016c5:	8b 75 0c             	mov    0xc(%ebp),%esi
f01016c8:	8b 7d 10             	mov    0x10(%ebp),%edi

	pte_t * pte = pgdir_walk(pgdir, (void *)va, 1) ;
f01016cb:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01016d2:	00 
f01016d3:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01016d7:	8b 45 08             	mov    0x8(%ebp),%eax
f01016da:	89 04 24             	mov    %eax,(%esp)
f01016dd:	e8 af fd ff ff       	call   f0101491 <pgdir_walk>
f01016e2:	89 c3                	mov    %eax,%ebx
//   - If necessary, on demand, a page table should be allocated and inserted
//     into 'pgdir'.
	if (pte==NULL)
f01016e4:	85 c0                	test   %eax,%eax
f01016e6:	74 66                	je     f010174e <page_insert+0x98>
		return -E_NO_MEM;
//-E_NO_MEM, if page table couldn't be allocated
	if (*pte & PTE_P) {
f01016e8:	8b 00                	mov    (%eax),%eax
f01016ea:	a8 01                	test   $0x1,%al
f01016ec:	74 3c                	je     f010172a <page_insert+0x74>
		if (PTE_ADDR(*pte) == page2pa(pp))
f01016ee:	25 00 f0 ff ff       	and    $0xfffff000,%eax
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01016f3:	89 f2                	mov    %esi,%edx
f01016f5:	2b 15 a8 99 11 f0    	sub    0xf01199a8,%edx
f01016fb:	c1 fa 03             	sar    $0x3,%edx
f01016fe:	c1 e2 0c             	shl    $0xc,%edx
f0101701:	39 d0                	cmp    %edx,%eax
f0101703:	75 16                	jne    f010171b <page_insert+0x65>
		{	
			pp->pp_ref--;
f0101705:	66 83 6e 04 01       	subw   $0x1,0x4(%esi)
			tlb_invalidate(pgdir, va);
f010170a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010170e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101711:	89 04 24             	mov    %eax,(%esp)
f0101714:	e8 3e ff ff ff       	call   f0101657 <tlb_invalidate>
f0101719:	eb 0f                	jmp    f010172a <page_insert+0x74>
//The TLB must be invalidated if a page was formerly present at 'va'.
		} 
		else 
		{
			page_remove (pgdir, va);
f010171b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010171f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101722:	89 04 24             	mov    %eax,(%esp)
f0101725:	e8 38 ff ff ff       	call   f0101662 <page_remove>
//If there is already a page mapped at 'va', it should be page_remove()d.
		}
	}

	*pte = page2pa(pp)|perm|PTE_P;
f010172a:	8b 45 14             	mov    0x14(%ebp),%eax
f010172d:	83 c8 01             	or     $0x1,%eax
f0101730:	89 f2                	mov    %esi,%edx
f0101732:	2b 15 a8 99 11 f0    	sub    0xf01199a8,%edx
f0101738:	c1 fa 03             	sar    $0x3,%edx
f010173b:	c1 e2 0c             	shl    $0xc,%edx
f010173e:	09 d0                	or     %edx,%eax
f0101740:	89 03                	mov    %eax,(%ebx)
	pp->pp_ref++;
f0101742:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
//pp->pp_ref should be incremented if the insertion succeeds.
	return 0;
f0101747:	b8 00 00 00 00       	mov    $0x0,%eax
f010174c:	eb 05                	jmp    f0101753 <page_insert+0x9d>

	pte_t * pte = pgdir_walk(pgdir, (void *)va, 1) ;
//   - If necessary, on demand, a page table should be allocated and inserted
//     into 'pgdir'.
	if (pte==NULL)
		return -E_NO_MEM;
f010174e:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	*pte = page2pa(pp)|perm|PTE_P;
	pp->pp_ref++;
//pp->pp_ref should be incremented if the insertion succeeds.
	return 0;
//0 on success
}
f0101753:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0101756:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0101759:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010175c:	89 ec                	mov    %ebp,%esp
f010175e:	5d                   	pop    %ebp
f010175f:	c3                   	ret    

f0101760 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101760:	55                   	push   %ebp
f0101761:	89 e5                	mov    %esp,%ebp
f0101763:	57                   	push   %edi
f0101764:	56                   	push   %esi
f0101765:	53                   	push   %ebx
f0101766:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101769:	b8 15 00 00 00       	mov    $0x15,%eax
f010176e:	e8 f0 f7 ff ff       	call   f0100f63 <nvram_read>
f0101773:	c1 e0 0a             	shl    $0xa,%eax
f0101776:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010177c:	85 c0                	test   %eax,%eax
f010177e:	0f 48 c2             	cmovs  %edx,%eax
f0101781:	c1 f8 0c             	sar    $0xc,%eax
f0101784:	a3 78 95 11 f0       	mov    %eax,0xf0119578
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101789:	b8 17 00 00 00       	mov    $0x17,%eax
f010178e:	e8 d0 f7 ff ff       	call   f0100f63 <nvram_read>
f0101793:	c1 e0 0a             	shl    $0xa,%eax
f0101796:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010179c:	85 c0                	test   %eax,%eax
f010179e:	0f 48 c2             	cmovs  %edx,%eax
f01017a1:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01017a4:	85 c0                	test   %eax,%eax
f01017a6:	74 0e                	je     f01017b6 <mem_init+0x56>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01017a8:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f01017ae:	89 15 a0 99 11 f0    	mov    %edx,0xf01199a0
f01017b4:	eb 0c                	jmp    f01017c2 <mem_init+0x62>
	else
		npages = npages_basemem;
f01017b6:	8b 15 78 95 11 f0    	mov    0xf0119578,%edx
f01017bc:	89 15 a0 99 11 f0    	mov    %edx,0xf01199a0

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f01017c2:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01017c5:	c1 e8 0a             	shr    $0xa,%eax
f01017c8:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f01017cc:	a1 78 95 11 f0       	mov    0xf0119578,%eax
f01017d1:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01017d4:	c1 e8 0a             	shr    $0xa,%eax
f01017d7:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f01017db:	a1 a0 99 11 f0       	mov    0xf01199a0,%eax
f01017e0:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01017e3:	c1 e8 0a             	shr    $0xa,%eax
f01017e6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01017ea:	c7 04 24 5c 4d 10 f0 	movl   $0xf0104d5c,(%esp)
f01017f1:	e8 6c 1a 00 00       	call   f0103262 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01017f6:	b8 00 10 00 00       	mov    $0x1000,%eax
f01017fb:	e8 b8 f6 ff ff       	call   f0100eb8 <boot_alloc>
f0101800:	a3 a4 99 11 f0       	mov    %eax,0xf01199a4
	memset(kern_pgdir, 0, PGSIZE);
f0101805:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010180c:	00 
f010180d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101814:	00 
f0101815:	89 04 24             	mov    %eax,(%esp)
f0101818:	e8 49 26 00 00       	call   f0103e66 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following two lines.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010181d:	a1 a4 99 11 f0       	mov    0xf01199a4,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101822:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101827:	77 20                	ja     f0101849 <mem_init+0xe9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101829:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010182d:	c7 44 24 08 18 4d 10 	movl   $0xf0104d18,0x8(%esp)
f0101834:	f0 
f0101835:	c7 44 24 04 8b 00 00 	movl   $0x8b,0x4(%esp)
f010183c:	00 
f010183d:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0101844:	e8 4b e8 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101849:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010184f:	83 ca 05             	or     $0x5,%edx
f0101852:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct Page in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:

	pages =(struct Page *) boot_alloc(npages* sizeof (struct Page));
f0101858:	a1 a0 99 11 f0       	mov    0xf01199a0,%eax
f010185d:	c1 e0 03             	shl    $0x3,%eax
f0101860:	e8 53 f6 ff ff       	call   f0100eb8 <boot_alloc>
f0101865:	a3 a8 99 11 f0       	mov    %eax,0xf01199a8
	memset(pages, 0, npages* sizeof (struct Page));
f010186a:	8b 15 a0 99 11 f0    	mov    0xf01199a0,%edx
f0101870:	c1 e2 03             	shl    $0x3,%edx
f0101873:	89 54 24 08          	mov    %edx,0x8(%esp)
f0101877:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010187e:	00 
f010187f:	89 04 24             	mov    %eax,(%esp)
f0101882:	e8 df 25 00 00       	call   f0103e66 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101887:	e8 66 fa ff ff       	call   f01012f2 <page_init>
	check_page_free_list(1);
f010188c:	b8 01 00 00 00       	mov    $0x1,%eax
f0101891:	e8 ff f6 ff ff       	call   f0100f95 <check_page_free_list>
	int nfree;
	struct Page *fl;
	char *c;
	int i;

	if (!pages)
f0101896:	83 3d a8 99 11 f0 00 	cmpl   $0x0,0xf01199a8
f010189d:	75 1c                	jne    f01018bb <mem_init+0x15b>
		panic("'pages' is a null pointer!");
f010189f:	c7 44 24 08 ce 53 10 	movl   $0xf01053ce,0x8(%esp)
f01018a6:	f0 
f01018a7:	c7 44 24 04 70 02 00 	movl   $0x270,0x4(%esp)
f01018ae:	00 
f01018af:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f01018b6:	e8 d9 e7 ff ff       	call   f0100094 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01018bb:	a1 80 95 11 f0       	mov    0xf0119580,%eax
f01018c0:	bb 00 00 00 00       	mov    $0x0,%ebx
f01018c5:	85 c0                	test   %eax,%eax
f01018c7:	74 09                	je     f01018d2 <mem_init+0x172>
		++nfree;
f01018c9:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01018cc:	8b 00                	mov    (%eax),%eax
f01018ce:	85 c0                	test   %eax,%eax
f01018d0:	75 f7                	jne    f01018c9 <mem_init+0x169>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01018d2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018d9:	e8 ee fa ff ff       	call   f01013cc <page_alloc>
f01018de:	89 c6                	mov    %eax,%esi
f01018e0:	85 c0                	test   %eax,%eax
f01018e2:	75 24                	jne    f0101908 <mem_init+0x1a8>
f01018e4:	c7 44 24 0c e9 53 10 	movl   $0xf01053e9,0xc(%esp)
f01018eb:	f0 
f01018ec:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f01018f3:	f0 
f01018f4:	c7 44 24 04 78 02 00 	movl   $0x278,0x4(%esp)
f01018fb:	00 
f01018fc:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0101903:	e8 8c e7 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101908:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010190f:	e8 b8 fa ff ff       	call   f01013cc <page_alloc>
f0101914:	89 c7                	mov    %eax,%edi
f0101916:	85 c0                	test   %eax,%eax
f0101918:	75 24                	jne    f010193e <mem_init+0x1de>
f010191a:	c7 44 24 0c ff 53 10 	movl   $0xf01053ff,0xc(%esp)
f0101921:	f0 
f0101922:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0101929:	f0 
f010192a:	c7 44 24 04 79 02 00 	movl   $0x279,0x4(%esp)
f0101931:	00 
f0101932:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0101939:	e8 56 e7 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f010193e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101945:	e8 82 fa ff ff       	call   f01013cc <page_alloc>
f010194a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010194d:	85 c0                	test   %eax,%eax
f010194f:	75 24                	jne    f0101975 <mem_init+0x215>
f0101951:	c7 44 24 0c 15 54 10 	movl   $0xf0105415,0xc(%esp)
f0101958:	f0 
f0101959:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0101960:	f0 
f0101961:	c7 44 24 04 7a 02 00 	movl   $0x27a,0x4(%esp)
f0101968:	00 
f0101969:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0101970:	e8 1f e7 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101975:	39 fe                	cmp    %edi,%esi
f0101977:	75 24                	jne    f010199d <mem_init+0x23d>
f0101979:	c7 44 24 0c 2b 54 10 	movl   $0xf010542b,0xc(%esp)
f0101980:	f0 
f0101981:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0101988:	f0 
f0101989:	c7 44 24 04 7d 02 00 	movl   $0x27d,0x4(%esp)
f0101990:	00 
f0101991:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0101998:	e8 f7 e6 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010199d:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f01019a0:	74 05                	je     f01019a7 <mem_init+0x247>
f01019a2:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f01019a5:	75 24                	jne    f01019cb <mem_init+0x26b>
f01019a7:	c7 44 24 0c 98 4d 10 	movl   $0xf0104d98,0xc(%esp)
f01019ae:	f0 
f01019af:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f01019b6:	f0 
f01019b7:	c7 44 24 04 7e 02 00 	movl   $0x27e,0x4(%esp)
f01019be:	00 
f01019bf:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f01019c6:	e8 c9 e6 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01019cb:	8b 15 a8 99 11 f0    	mov    0xf01199a8,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f01019d1:	a1 a0 99 11 f0       	mov    0xf01199a0,%eax
f01019d6:	c1 e0 0c             	shl    $0xc,%eax
f01019d9:	89 f1                	mov    %esi,%ecx
f01019db:	29 d1                	sub    %edx,%ecx
f01019dd:	c1 f9 03             	sar    $0x3,%ecx
f01019e0:	c1 e1 0c             	shl    $0xc,%ecx
f01019e3:	39 c1                	cmp    %eax,%ecx
f01019e5:	72 24                	jb     f0101a0b <mem_init+0x2ab>
f01019e7:	c7 44 24 0c 3d 54 10 	movl   $0xf010543d,0xc(%esp)
f01019ee:	f0 
f01019ef:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f01019f6:	f0 
f01019f7:	c7 44 24 04 7f 02 00 	movl   $0x27f,0x4(%esp)
f01019fe:	00 
f01019ff:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0101a06:	e8 89 e6 ff ff       	call   f0100094 <_panic>
f0101a0b:	89 f9                	mov    %edi,%ecx
f0101a0d:	29 d1                	sub    %edx,%ecx
f0101a0f:	c1 f9 03             	sar    $0x3,%ecx
f0101a12:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101a15:	39 c8                	cmp    %ecx,%eax
f0101a17:	77 24                	ja     f0101a3d <mem_init+0x2dd>
f0101a19:	c7 44 24 0c 5a 54 10 	movl   $0xf010545a,0xc(%esp)
f0101a20:	f0 
f0101a21:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0101a28:	f0 
f0101a29:	c7 44 24 04 80 02 00 	movl   $0x280,0x4(%esp)
f0101a30:	00 
f0101a31:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0101a38:	e8 57 e6 ff ff       	call   f0100094 <_panic>
f0101a3d:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101a40:	29 d1                	sub    %edx,%ecx
f0101a42:	89 ca                	mov    %ecx,%edx
f0101a44:	c1 fa 03             	sar    $0x3,%edx
f0101a47:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f0101a4a:	39 d0                	cmp    %edx,%eax
f0101a4c:	77 24                	ja     f0101a72 <mem_init+0x312>
f0101a4e:	c7 44 24 0c 77 54 10 	movl   $0xf0105477,0xc(%esp)
f0101a55:	f0 
f0101a56:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0101a5d:	f0 
f0101a5e:	c7 44 24 04 81 02 00 	movl   $0x281,0x4(%esp)
f0101a65:	00 
f0101a66:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0101a6d:	e8 22 e6 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101a72:	a1 80 95 11 f0       	mov    0xf0119580,%eax
f0101a77:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101a7a:	c7 05 80 95 11 f0 00 	movl   $0x0,0xf0119580
f0101a81:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101a84:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a8b:	e8 3c f9 ff ff       	call   f01013cc <page_alloc>
f0101a90:	85 c0                	test   %eax,%eax
f0101a92:	74 24                	je     f0101ab8 <mem_init+0x358>
f0101a94:	c7 44 24 0c 94 54 10 	movl   $0xf0105494,0xc(%esp)
f0101a9b:	f0 
f0101a9c:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0101aa3:	f0 
f0101aa4:	c7 44 24 04 88 02 00 	movl   $0x288,0x4(%esp)
f0101aab:	00 
f0101aac:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0101ab3:	e8 dc e5 ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101ab8:	89 34 24             	mov    %esi,(%esp)
f0101abb:	e8 99 f9 ff ff       	call   f0101459 <page_free>
	page_free(pp1);
f0101ac0:	89 3c 24             	mov    %edi,(%esp)
f0101ac3:	e8 91 f9 ff ff       	call   f0101459 <page_free>
	page_free(pp2);
f0101ac8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101acb:	89 04 24             	mov    %eax,(%esp)
f0101ace:	e8 86 f9 ff ff       	call   f0101459 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101ad3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ada:	e8 ed f8 ff ff       	call   f01013cc <page_alloc>
f0101adf:	89 c6                	mov    %eax,%esi
f0101ae1:	85 c0                	test   %eax,%eax
f0101ae3:	75 24                	jne    f0101b09 <mem_init+0x3a9>
f0101ae5:	c7 44 24 0c e9 53 10 	movl   $0xf01053e9,0xc(%esp)
f0101aec:	f0 
f0101aed:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0101af4:	f0 
f0101af5:	c7 44 24 04 8f 02 00 	movl   $0x28f,0x4(%esp)
f0101afc:	00 
f0101afd:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0101b04:	e8 8b e5 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101b09:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b10:	e8 b7 f8 ff ff       	call   f01013cc <page_alloc>
f0101b15:	89 c7                	mov    %eax,%edi
f0101b17:	85 c0                	test   %eax,%eax
f0101b19:	75 24                	jne    f0101b3f <mem_init+0x3df>
f0101b1b:	c7 44 24 0c ff 53 10 	movl   $0xf01053ff,0xc(%esp)
f0101b22:	f0 
f0101b23:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0101b2a:	f0 
f0101b2b:	c7 44 24 04 90 02 00 	movl   $0x290,0x4(%esp)
f0101b32:	00 
f0101b33:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0101b3a:	e8 55 e5 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101b3f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b46:	e8 81 f8 ff ff       	call   f01013cc <page_alloc>
f0101b4b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101b4e:	85 c0                	test   %eax,%eax
f0101b50:	75 24                	jne    f0101b76 <mem_init+0x416>
f0101b52:	c7 44 24 0c 15 54 10 	movl   $0xf0105415,0xc(%esp)
f0101b59:	f0 
f0101b5a:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0101b61:	f0 
f0101b62:	c7 44 24 04 91 02 00 	movl   $0x291,0x4(%esp)
f0101b69:	00 
f0101b6a:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0101b71:	e8 1e e5 ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101b76:	39 fe                	cmp    %edi,%esi
f0101b78:	75 24                	jne    f0101b9e <mem_init+0x43e>
f0101b7a:	c7 44 24 0c 2b 54 10 	movl   $0xf010542b,0xc(%esp)
f0101b81:	f0 
f0101b82:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0101b89:	f0 
f0101b8a:	c7 44 24 04 93 02 00 	movl   $0x293,0x4(%esp)
f0101b91:	00 
f0101b92:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0101b99:	e8 f6 e4 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101b9e:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101ba1:	74 05                	je     f0101ba8 <mem_init+0x448>
f0101ba3:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101ba6:	75 24                	jne    f0101bcc <mem_init+0x46c>
f0101ba8:	c7 44 24 0c 98 4d 10 	movl   $0xf0104d98,0xc(%esp)
f0101baf:	f0 
f0101bb0:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0101bb7:	f0 
f0101bb8:	c7 44 24 04 94 02 00 	movl   $0x294,0x4(%esp)
f0101bbf:	00 
f0101bc0:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0101bc7:	e8 c8 e4 ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f0101bcc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101bd3:	e8 f4 f7 ff ff       	call   f01013cc <page_alloc>
f0101bd8:	85 c0                	test   %eax,%eax
f0101bda:	74 24                	je     f0101c00 <mem_init+0x4a0>
f0101bdc:	c7 44 24 0c 94 54 10 	movl   $0xf0105494,0xc(%esp)
f0101be3:	f0 
f0101be4:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0101beb:	f0 
f0101bec:	c7 44 24 04 95 02 00 	movl   $0x295,0x4(%esp)
f0101bf3:	00 
f0101bf4:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0101bfb:	e8 94 e4 ff ff       	call   f0100094 <_panic>
f0101c00:	89 f0                	mov    %esi,%eax
f0101c02:	2b 05 a8 99 11 f0    	sub    0xf01199a8,%eax
f0101c08:	c1 f8 03             	sar    $0x3,%eax
f0101c0b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101c0e:	89 c2                	mov    %eax,%edx
f0101c10:	c1 ea 0c             	shr    $0xc,%edx
f0101c13:	3b 15 a0 99 11 f0    	cmp    0xf01199a0,%edx
f0101c19:	72 20                	jb     f0101c3b <mem_init+0x4db>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101c1b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101c1f:	c7 44 24 08 bc 48 10 	movl   $0xf01048bc,0x8(%esp)
f0101c26:	f0 
f0101c27:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101c2e:	00 
f0101c2f:	c7 04 24 24 53 10 f0 	movl   $0xf0105324,(%esp)
f0101c36:	e8 59 e4 ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101c3b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101c42:	00 
f0101c43:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101c4a:	00 
	return (void *)(pa + KERNBASE);
f0101c4b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101c50:	89 04 24             	mov    %eax,(%esp)
f0101c53:	e8 0e 22 00 00       	call   f0103e66 <memset>
	page_free(pp0);
f0101c58:	89 34 24             	mov    %esi,(%esp)
f0101c5b:	e8 f9 f7 ff ff       	call   f0101459 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101c60:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101c67:	e8 60 f7 ff ff       	call   f01013cc <page_alloc>
f0101c6c:	85 c0                	test   %eax,%eax
f0101c6e:	75 24                	jne    f0101c94 <mem_init+0x534>
f0101c70:	c7 44 24 0c a3 54 10 	movl   $0xf01054a3,0xc(%esp)
f0101c77:	f0 
f0101c78:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0101c7f:	f0 
f0101c80:	c7 44 24 04 9a 02 00 	movl   $0x29a,0x4(%esp)
f0101c87:	00 
f0101c88:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0101c8f:	e8 00 e4 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f0101c94:	39 c6                	cmp    %eax,%esi
f0101c96:	74 24                	je     f0101cbc <mem_init+0x55c>
f0101c98:	c7 44 24 0c c1 54 10 	movl   $0xf01054c1,0xc(%esp)
f0101c9f:	f0 
f0101ca0:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0101ca7:	f0 
f0101ca8:	c7 44 24 04 9b 02 00 	movl   $0x29b,0x4(%esp)
f0101caf:	00 
f0101cb0:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0101cb7:	e8 d8 e3 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101cbc:	89 f2                	mov    %esi,%edx
f0101cbe:	2b 15 a8 99 11 f0    	sub    0xf01199a8,%edx
f0101cc4:	c1 fa 03             	sar    $0x3,%edx
f0101cc7:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101cca:	89 d0                	mov    %edx,%eax
f0101ccc:	c1 e8 0c             	shr    $0xc,%eax
f0101ccf:	3b 05 a0 99 11 f0    	cmp    0xf01199a0,%eax
f0101cd5:	72 20                	jb     f0101cf7 <mem_init+0x597>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101cd7:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101cdb:	c7 44 24 08 bc 48 10 	movl   $0xf01048bc,0x8(%esp)
f0101ce2:	f0 
f0101ce3:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101cea:	00 
f0101ceb:	c7 04 24 24 53 10 f0 	movl   $0xf0105324,(%esp)
f0101cf2:	e8 9d e3 ff ff       	call   f0100094 <_panic>
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101cf7:	80 ba 00 00 00 f0 00 	cmpb   $0x0,-0x10000000(%edx)
f0101cfe:	75 11                	jne    f0101d11 <mem_init+0x5b1>
f0101d00:	8d 82 01 00 00 f0    	lea    -0xfffffff(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0101d06:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101d0c:	80 38 00             	cmpb   $0x0,(%eax)
f0101d0f:	74 24                	je     f0101d35 <mem_init+0x5d5>
f0101d11:	c7 44 24 0c d1 54 10 	movl   $0xf01054d1,0xc(%esp)
f0101d18:	f0 
f0101d19:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0101d20:	f0 
f0101d21:	c7 44 24 04 9e 02 00 	movl   $0x29e,0x4(%esp)
f0101d28:	00 
f0101d29:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0101d30:	e8 5f e3 ff ff       	call   f0100094 <_panic>
f0101d35:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101d38:	39 d0                	cmp    %edx,%eax
f0101d3a:	75 d0                	jne    f0101d0c <mem_init+0x5ac>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101d3c:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101d3f:	89 15 80 95 11 f0    	mov    %edx,0xf0119580

	// free the pages we took
	page_free(pp0);
f0101d45:	89 34 24             	mov    %esi,(%esp)
f0101d48:	e8 0c f7 ff ff       	call   f0101459 <page_free>
	page_free(pp1);
f0101d4d:	89 3c 24             	mov    %edi,(%esp)
f0101d50:	e8 04 f7 ff ff       	call   f0101459 <page_free>
	page_free(pp2);
f0101d55:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d58:	89 04 24             	mov    %eax,(%esp)
f0101d5b:	e8 f9 f6 ff ff       	call   f0101459 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101d60:	a1 80 95 11 f0       	mov    0xf0119580,%eax
f0101d65:	85 c0                	test   %eax,%eax
f0101d67:	74 09                	je     f0101d72 <mem_init+0x612>
		--nfree;
f0101d69:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101d6c:	8b 00                	mov    (%eax),%eax
f0101d6e:	85 c0                	test   %eax,%eax
f0101d70:	75 f7                	jne    f0101d69 <mem_init+0x609>
		--nfree;
	assert(nfree == 0);
f0101d72:	85 db                	test   %ebx,%ebx
f0101d74:	74 24                	je     f0101d9a <mem_init+0x63a>
f0101d76:	c7 44 24 0c db 54 10 	movl   $0xf01054db,0xc(%esp)
f0101d7d:	f0 
f0101d7e:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0101d85:	f0 
f0101d86:	c7 44 24 04 ab 02 00 	movl   $0x2ab,0x4(%esp)
f0101d8d:	00 
f0101d8e:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0101d95:	e8 fa e2 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101d9a:	c7 04 24 b8 4d 10 f0 	movl   $0xf0104db8,(%esp)
f0101da1:	e8 bc 14 00 00       	call   f0103262 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101da6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101dad:	e8 1a f6 ff ff       	call   f01013cc <page_alloc>
f0101db2:	89 c3                	mov    %eax,%ebx
f0101db4:	85 c0                	test   %eax,%eax
f0101db6:	75 24                	jne    f0101ddc <mem_init+0x67c>
f0101db8:	c7 44 24 0c e9 53 10 	movl   $0xf01053e9,0xc(%esp)
f0101dbf:	f0 
f0101dc0:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0101dc7:	f0 
f0101dc8:	c7 44 24 04 04 03 00 	movl   $0x304,0x4(%esp)
f0101dcf:	00 
f0101dd0:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0101dd7:	e8 b8 e2 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101ddc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101de3:	e8 e4 f5 ff ff       	call   f01013cc <page_alloc>
f0101de8:	89 c7                	mov    %eax,%edi
f0101dea:	85 c0                	test   %eax,%eax
f0101dec:	75 24                	jne    f0101e12 <mem_init+0x6b2>
f0101dee:	c7 44 24 0c ff 53 10 	movl   $0xf01053ff,0xc(%esp)
f0101df5:	f0 
f0101df6:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0101dfd:	f0 
f0101dfe:	c7 44 24 04 05 03 00 	movl   $0x305,0x4(%esp)
f0101e05:	00 
f0101e06:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0101e0d:	e8 82 e2 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101e12:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101e19:	e8 ae f5 ff ff       	call   f01013cc <page_alloc>
f0101e1e:	89 c6                	mov    %eax,%esi
f0101e20:	85 c0                	test   %eax,%eax
f0101e22:	75 24                	jne    f0101e48 <mem_init+0x6e8>
f0101e24:	c7 44 24 0c 15 54 10 	movl   $0xf0105415,0xc(%esp)
f0101e2b:	f0 
f0101e2c:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0101e33:	f0 
f0101e34:	c7 44 24 04 06 03 00 	movl   $0x306,0x4(%esp)
f0101e3b:	00 
f0101e3c:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0101e43:	e8 4c e2 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101e48:	39 fb                	cmp    %edi,%ebx
f0101e4a:	75 24                	jne    f0101e70 <mem_init+0x710>
f0101e4c:	c7 44 24 0c 2b 54 10 	movl   $0xf010542b,0xc(%esp)
f0101e53:	f0 
f0101e54:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0101e5b:	f0 
f0101e5c:	c7 44 24 04 09 03 00 	movl   $0x309,0x4(%esp)
f0101e63:	00 
f0101e64:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0101e6b:	e8 24 e2 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101e70:	39 c7                	cmp    %eax,%edi
f0101e72:	74 04                	je     f0101e78 <mem_init+0x718>
f0101e74:	39 c3                	cmp    %eax,%ebx
f0101e76:	75 24                	jne    f0101e9c <mem_init+0x73c>
f0101e78:	c7 44 24 0c 98 4d 10 	movl   $0xf0104d98,0xc(%esp)
f0101e7f:	f0 
f0101e80:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0101e87:	f0 
f0101e88:	c7 44 24 04 0a 03 00 	movl   $0x30a,0x4(%esp)
f0101e8f:	00 
f0101e90:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0101e97:	e8 f8 e1 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101e9c:	8b 15 80 95 11 f0    	mov    0xf0119580,%edx
f0101ea2:	89 55 cc             	mov    %edx,-0x34(%ebp)
	page_free_list = 0;
f0101ea5:	c7 05 80 95 11 f0 00 	movl   $0x0,0xf0119580
f0101eac:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101eaf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101eb6:	e8 11 f5 ff ff       	call   f01013cc <page_alloc>
f0101ebb:	85 c0                	test   %eax,%eax
f0101ebd:	74 24                	je     f0101ee3 <mem_init+0x783>
f0101ebf:	c7 44 24 0c 94 54 10 	movl   $0xf0105494,0xc(%esp)
f0101ec6:	f0 
f0101ec7:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0101ece:	f0 
f0101ecf:	c7 44 24 04 11 03 00 	movl   $0x311,0x4(%esp)
f0101ed6:	00 
f0101ed7:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0101ede:	e8 b1 e1 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101ee3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101ee6:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101eea:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101ef1:	00 
f0101ef2:	a1 a4 99 11 f0       	mov    0xf01199a4,%eax
f0101ef7:	89 04 24             	mov    %eax,(%esp)
f0101efa:	e8 e0 f6 ff ff       	call   f01015df <page_lookup>
f0101eff:	85 c0                	test   %eax,%eax
f0101f01:	74 24                	je     f0101f27 <mem_init+0x7c7>
f0101f03:	c7 44 24 0c d8 4d 10 	movl   $0xf0104dd8,0xc(%esp)
f0101f0a:	f0 
f0101f0b:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0101f12:	f0 
f0101f13:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
f0101f1a:	00 
f0101f1b:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0101f22:	e8 6d e1 ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101f27:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f2e:	00 
f0101f2f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f36:	00 
f0101f37:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101f3b:	a1 a4 99 11 f0       	mov    0xf01199a4,%eax
f0101f40:	89 04 24             	mov    %eax,(%esp)
f0101f43:	e8 6e f7 ff ff       	call   f01016b6 <page_insert>
f0101f48:	85 c0                	test   %eax,%eax
f0101f4a:	78 24                	js     f0101f70 <mem_init+0x810>
f0101f4c:	c7 44 24 0c 10 4e 10 	movl   $0xf0104e10,0xc(%esp)
f0101f53:	f0 
f0101f54:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0101f5b:	f0 
f0101f5c:	c7 44 24 04 17 03 00 	movl   $0x317,0x4(%esp)
f0101f63:	00 
f0101f64:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0101f6b:	e8 24 e1 ff ff       	call   f0100094 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101f70:	89 1c 24             	mov    %ebx,(%esp)
f0101f73:	e8 e1 f4 ff ff       	call   f0101459 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101f78:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f7f:	00 
f0101f80:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f87:	00 
f0101f88:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101f8c:	a1 a4 99 11 f0       	mov    0xf01199a4,%eax
f0101f91:	89 04 24             	mov    %eax,(%esp)
f0101f94:	e8 1d f7 ff ff       	call   f01016b6 <page_insert>
f0101f99:	85 c0                	test   %eax,%eax
f0101f9b:	74 24                	je     f0101fc1 <mem_init+0x861>
f0101f9d:	c7 44 24 0c 40 4e 10 	movl   $0xf0104e40,0xc(%esp)
f0101fa4:	f0 
f0101fa5:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0101fac:	f0 
f0101fad:	c7 44 24 04 1b 03 00 	movl   $0x31b,0x4(%esp)
f0101fb4:	00 
f0101fb5:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0101fbc:	e8 d3 e0 ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101fc1:	8b 0d a4 99 11 f0    	mov    0xf01199a4,%ecx
f0101fc7:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101fca:	a1 a8 99 11 f0       	mov    0xf01199a8,%eax
f0101fcf:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101fd2:	8b 11                	mov    (%ecx),%edx
f0101fd4:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101fda:	89 d8                	mov    %ebx,%eax
f0101fdc:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0101fdf:	c1 f8 03             	sar    $0x3,%eax
f0101fe2:	c1 e0 0c             	shl    $0xc,%eax
f0101fe5:	39 c2                	cmp    %eax,%edx
f0101fe7:	74 24                	je     f010200d <mem_init+0x8ad>
f0101fe9:	c7 44 24 0c 70 4e 10 	movl   $0xf0104e70,0xc(%esp)
f0101ff0:	f0 
f0101ff1:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0101ff8:	f0 
f0101ff9:	c7 44 24 04 1c 03 00 	movl   $0x31c,0x4(%esp)
f0102000:	00 
f0102001:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102008:	e8 87 e0 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010200d:	ba 00 00 00 00       	mov    $0x0,%edx
f0102012:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102015:	e8 d8 ee ff ff       	call   f0100ef2 <check_va2pa>
f010201a:	89 fa                	mov    %edi,%edx
f010201c:	2b 55 d0             	sub    -0x30(%ebp),%edx
f010201f:	c1 fa 03             	sar    $0x3,%edx
f0102022:	c1 e2 0c             	shl    $0xc,%edx
f0102025:	39 d0                	cmp    %edx,%eax
f0102027:	74 24                	je     f010204d <mem_init+0x8ed>
f0102029:	c7 44 24 0c 98 4e 10 	movl   $0xf0104e98,0xc(%esp)
f0102030:	f0 
f0102031:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0102038:	f0 
f0102039:	c7 44 24 04 1d 03 00 	movl   $0x31d,0x4(%esp)
f0102040:	00 
f0102041:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102048:	e8 47 e0 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f010204d:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102052:	74 24                	je     f0102078 <mem_init+0x918>
f0102054:	c7 44 24 0c e6 54 10 	movl   $0xf01054e6,0xc(%esp)
f010205b:	f0 
f010205c:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0102063:	f0 
f0102064:	c7 44 24 04 1e 03 00 	movl   $0x31e,0x4(%esp)
f010206b:	00 
f010206c:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102073:	e8 1c e0 ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0102078:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010207d:	74 24                	je     f01020a3 <mem_init+0x943>
f010207f:	c7 44 24 0c f7 54 10 	movl   $0xf01054f7,0xc(%esp)
f0102086:	f0 
f0102087:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f010208e:	f0 
f010208f:	c7 44 24 04 1f 03 00 	movl   $0x31f,0x4(%esp)
f0102096:	00 
f0102097:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f010209e:	e8 f1 df ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01020a3:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01020aa:	00 
f01020ab:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01020b2:	00 
f01020b3:	89 74 24 04          	mov    %esi,0x4(%esp)
f01020b7:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01020ba:	89 14 24             	mov    %edx,(%esp)
f01020bd:	e8 f4 f5 ff ff       	call   f01016b6 <page_insert>
f01020c2:	85 c0                	test   %eax,%eax
f01020c4:	74 24                	je     f01020ea <mem_init+0x98a>
f01020c6:	c7 44 24 0c c8 4e 10 	movl   $0xf0104ec8,0xc(%esp)
f01020cd:	f0 
f01020ce:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f01020d5:	f0 
f01020d6:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f01020dd:	00 
f01020de:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f01020e5:	e8 aa df ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01020ea:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020ef:	a1 a4 99 11 f0       	mov    0xf01199a4,%eax
f01020f4:	e8 f9 ed ff ff       	call   f0100ef2 <check_va2pa>
f01020f9:	89 f2                	mov    %esi,%edx
f01020fb:	2b 15 a8 99 11 f0    	sub    0xf01199a8,%edx
f0102101:	c1 fa 03             	sar    $0x3,%edx
f0102104:	c1 e2 0c             	shl    $0xc,%edx
f0102107:	39 d0                	cmp    %edx,%eax
f0102109:	74 24                	je     f010212f <mem_init+0x9cf>
f010210b:	c7 44 24 0c 04 4f 10 	movl   $0xf0104f04,0xc(%esp)
f0102112:	f0 
f0102113:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f010211a:	f0 
f010211b:	c7 44 24 04 23 03 00 	movl   $0x323,0x4(%esp)
f0102122:	00 
f0102123:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f010212a:	e8 65 df ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f010212f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102134:	74 24                	je     f010215a <mem_init+0x9fa>
f0102136:	c7 44 24 0c 08 55 10 	movl   $0xf0105508,0xc(%esp)
f010213d:	f0 
f010213e:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0102145:	f0 
f0102146:	c7 44 24 04 24 03 00 	movl   $0x324,0x4(%esp)
f010214d:	00 
f010214e:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102155:	e8 3a df ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010215a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102161:	e8 66 f2 ff ff       	call   f01013cc <page_alloc>
f0102166:	85 c0                	test   %eax,%eax
f0102168:	74 24                	je     f010218e <mem_init+0xa2e>
f010216a:	c7 44 24 0c 94 54 10 	movl   $0xf0105494,0xc(%esp)
f0102171:	f0 
f0102172:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0102179:	f0 
f010217a:	c7 44 24 04 27 03 00 	movl   $0x327,0x4(%esp)
f0102181:	00 
f0102182:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102189:	e8 06 df ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010218e:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102195:	00 
f0102196:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010219d:	00 
f010219e:	89 74 24 04          	mov    %esi,0x4(%esp)
f01021a2:	a1 a4 99 11 f0       	mov    0xf01199a4,%eax
f01021a7:	89 04 24             	mov    %eax,(%esp)
f01021aa:	e8 07 f5 ff ff       	call   f01016b6 <page_insert>
f01021af:	85 c0                	test   %eax,%eax
f01021b1:	74 24                	je     f01021d7 <mem_init+0xa77>
f01021b3:	c7 44 24 0c c8 4e 10 	movl   $0xf0104ec8,0xc(%esp)
f01021ba:	f0 
f01021bb:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f01021c2:	f0 
f01021c3:	c7 44 24 04 2a 03 00 	movl   $0x32a,0x4(%esp)
f01021ca:	00 
f01021cb:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f01021d2:	e8 bd de ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01021d7:	ba 00 10 00 00       	mov    $0x1000,%edx
f01021dc:	a1 a4 99 11 f0       	mov    0xf01199a4,%eax
f01021e1:	e8 0c ed ff ff       	call   f0100ef2 <check_va2pa>
f01021e6:	89 f2                	mov    %esi,%edx
f01021e8:	2b 15 a8 99 11 f0    	sub    0xf01199a8,%edx
f01021ee:	c1 fa 03             	sar    $0x3,%edx
f01021f1:	c1 e2 0c             	shl    $0xc,%edx
f01021f4:	39 d0                	cmp    %edx,%eax
f01021f6:	74 24                	je     f010221c <mem_init+0xabc>
f01021f8:	c7 44 24 0c 04 4f 10 	movl   $0xf0104f04,0xc(%esp)
f01021ff:	f0 
f0102200:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0102207:	f0 
f0102208:	c7 44 24 04 2b 03 00 	movl   $0x32b,0x4(%esp)
f010220f:	00 
f0102210:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102217:	e8 78 de ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f010221c:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102221:	74 24                	je     f0102247 <mem_init+0xae7>
f0102223:	c7 44 24 0c 08 55 10 	movl   $0xf0105508,0xc(%esp)
f010222a:	f0 
f010222b:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0102232:	f0 
f0102233:	c7 44 24 04 2c 03 00 	movl   $0x32c,0x4(%esp)
f010223a:	00 
f010223b:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102242:	e8 4d de ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0102247:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010224e:	e8 79 f1 ff ff       	call   f01013cc <page_alloc>
f0102253:	85 c0                	test   %eax,%eax
f0102255:	74 24                	je     f010227b <mem_init+0xb1b>
f0102257:	c7 44 24 0c 94 54 10 	movl   $0xf0105494,0xc(%esp)
f010225e:	f0 
f010225f:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0102266:	f0 
f0102267:	c7 44 24 04 30 03 00 	movl   $0x330,0x4(%esp)
f010226e:	00 
f010226f:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102276:	e8 19 de ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f010227b:	8b 15 a4 99 11 f0    	mov    0xf01199a4,%edx
f0102281:	8b 02                	mov    (%edx),%eax
f0102283:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102288:	89 c1                	mov    %eax,%ecx
f010228a:	c1 e9 0c             	shr    $0xc,%ecx
f010228d:	3b 0d a0 99 11 f0    	cmp    0xf01199a0,%ecx
f0102293:	72 20                	jb     f01022b5 <mem_init+0xb55>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102295:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102299:	c7 44 24 08 bc 48 10 	movl   $0xf01048bc,0x8(%esp)
f01022a0:	f0 
f01022a1:	c7 44 24 04 33 03 00 	movl   $0x333,0x4(%esp)
f01022a8:	00 
f01022a9:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f01022b0:	e8 df dd ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f01022b5:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01022ba:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01022bd:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01022c4:	00 
f01022c5:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01022cc:	00 
f01022cd:	89 14 24             	mov    %edx,(%esp)
f01022d0:	e8 bc f1 ff ff       	call   f0101491 <pgdir_walk>
f01022d5:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01022d8:	83 c2 04             	add    $0x4,%edx
f01022db:	39 d0                	cmp    %edx,%eax
f01022dd:	74 24                	je     f0102303 <mem_init+0xba3>
f01022df:	c7 44 24 0c 34 4f 10 	movl   $0xf0104f34,0xc(%esp)
f01022e6:	f0 
f01022e7:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f01022ee:	f0 
f01022ef:	c7 44 24 04 34 03 00 	movl   $0x334,0x4(%esp)
f01022f6:	00 
f01022f7:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f01022fe:	e8 91 dd ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102303:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f010230a:	00 
f010230b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102312:	00 
f0102313:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102317:	a1 a4 99 11 f0       	mov    0xf01199a4,%eax
f010231c:	89 04 24             	mov    %eax,(%esp)
f010231f:	e8 92 f3 ff ff       	call   f01016b6 <page_insert>
f0102324:	85 c0                	test   %eax,%eax
f0102326:	74 24                	je     f010234c <mem_init+0xbec>
f0102328:	c7 44 24 0c 74 4f 10 	movl   $0xf0104f74,0xc(%esp)
f010232f:	f0 
f0102330:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0102337:	f0 
f0102338:	c7 44 24 04 37 03 00 	movl   $0x337,0x4(%esp)
f010233f:	00 
f0102340:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102347:	e8 48 dd ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010234c:	8b 0d a4 99 11 f0    	mov    0xf01199a4,%ecx
f0102352:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0102355:	ba 00 10 00 00       	mov    $0x1000,%edx
f010235a:	89 c8                	mov    %ecx,%eax
f010235c:	e8 91 eb ff ff       	call   f0100ef2 <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102361:	89 f2                	mov    %esi,%edx
f0102363:	2b 15 a8 99 11 f0    	sub    0xf01199a8,%edx
f0102369:	c1 fa 03             	sar    $0x3,%edx
f010236c:	c1 e2 0c             	shl    $0xc,%edx
f010236f:	39 d0                	cmp    %edx,%eax
f0102371:	74 24                	je     f0102397 <mem_init+0xc37>
f0102373:	c7 44 24 0c 04 4f 10 	movl   $0xf0104f04,0xc(%esp)
f010237a:	f0 
f010237b:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0102382:	f0 
f0102383:	c7 44 24 04 38 03 00 	movl   $0x338,0x4(%esp)
f010238a:	00 
f010238b:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102392:	e8 fd dc ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102397:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010239c:	74 24                	je     f01023c2 <mem_init+0xc62>
f010239e:	c7 44 24 0c 08 55 10 	movl   $0xf0105508,0xc(%esp)
f01023a5:	f0 
f01023a6:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f01023ad:	f0 
f01023ae:	c7 44 24 04 39 03 00 	movl   $0x339,0x4(%esp)
f01023b5:	00 
f01023b6:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f01023bd:	e8 d2 dc ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01023c2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01023c9:	00 
f01023ca:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01023d1:	00 
f01023d2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01023d5:	89 04 24             	mov    %eax,(%esp)
f01023d8:	e8 b4 f0 ff ff       	call   f0101491 <pgdir_walk>
f01023dd:	f6 00 04             	testb  $0x4,(%eax)
f01023e0:	75 24                	jne    f0102406 <mem_init+0xca6>
f01023e2:	c7 44 24 0c b4 4f 10 	movl   $0xf0104fb4,0xc(%esp)
f01023e9:	f0 
f01023ea:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f01023f1:	f0 
f01023f2:	c7 44 24 04 3a 03 00 	movl   $0x33a,0x4(%esp)
f01023f9:	00 
f01023fa:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102401:	e8 8e dc ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0102406:	a1 a4 99 11 f0       	mov    0xf01199a4,%eax
f010240b:	f6 00 04             	testb  $0x4,(%eax)
f010240e:	75 24                	jne    f0102434 <mem_init+0xcd4>
f0102410:	c7 44 24 0c 19 55 10 	movl   $0xf0105519,0xc(%esp)
f0102417:	f0 
f0102418:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f010241f:	f0 
f0102420:	c7 44 24 04 3b 03 00 	movl   $0x33b,0x4(%esp)
f0102427:	00 
f0102428:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f010242f:	e8 60 dc ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102434:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010243b:	00 
f010243c:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0102443:	00 
f0102444:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102448:	89 04 24             	mov    %eax,(%esp)
f010244b:	e8 66 f2 ff ff       	call   f01016b6 <page_insert>
f0102450:	85 c0                	test   %eax,%eax
f0102452:	78 24                	js     f0102478 <mem_init+0xd18>
f0102454:	c7 44 24 0c e8 4f 10 	movl   $0xf0104fe8,0xc(%esp)
f010245b:	f0 
f010245c:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0102463:	f0 
f0102464:	c7 44 24 04 3e 03 00 	movl   $0x33e,0x4(%esp)
f010246b:	00 
f010246c:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102473:	e8 1c dc ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0102478:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010247f:	00 
f0102480:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102487:	00 
f0102488:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010248c:	a1 a4 99 11 f0       	mov    0xf01199a4,%eax
f0102491:	89 04 24             	mov    %eax,(%esp)
f0102494:	e8 1d f2 ff ff       	call   f01016b6 <page_insert>
f0102499:	85 c0                	test   %eax,%eax
f010249b:	74 24                	je     f01024c1 <mem_init+0xd61>
f010249d:	c7 44 24 0c 20 50 10 	movl   $0xf0105020,0xc(%esp)
f01024a4:	f0 
f01024a5:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f01024ac:	f0 
f01024ad:	c7 44 24 04 41 03 00 	movl   $0x341,0x4(%esp)
f01024b4:	00 
f01024b5:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f01024bc:	e8 d3 db ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01024c1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01024c8:	00 
f01024c9:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01024d0:	00 
f01024d1:	a1 a4 99 11 f0       	mov    0xf01199a4,%eax
f01024d6:	89 04 24             	mov    %eax,(%esp)
f01024d9:	e8 b3 ef ff ff       	call   f0101491 <pgdir_walk>
f01024de:	f6 00 04             	testb  $0x4,(%eax)
f01024e1:	74 24                	je     f0102507 <mem_init+0xda7>
f01024e3:	c7 44 24 0c 5c 50 10 	movl   $0xf010505c,0xc(%esp)
f01024ea:	f0 
f01024eb:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f01024f2:	f0 
f01024f3:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f01024fa:	00 
f01024fb:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102502:	e8 8d db ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0102507:	a1 a4 99 11 f0       	mov    0xf01199a4,%eax
f010250c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010250f:	ba 00 00 00 00       	mov    $0x0,%edx
f0102514:	e8 d9 e9 ff ff       	call   f0100ef2 <check_va2pa>
f0102519:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010251c:	89 f8                	mov    %edi,%eax
f010251e:	2b 05 a8 99 11 f0    	sub    0xf01199a8,%eax
f0102524:	c1 f8 03             	sar    $0x3,%eax
f0102527:	c1 e0 0c             	shl    $0xc,%eax
f010252a:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f010252d:	74 24                	je     f0102553 <mem_init+0xdf3>
f010252f:	c7 44 24 0c 94 50 10 	movl   $0xf0105094,0xc(%esp)
f0102536:	f0 
f0102537:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f010253e:	f0 
f010253f:	c7 44 24 04 45 03 00 	movl   $0x345,0x4(%esp)
f0102546:	00 
f0102547:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f010254e:	e8 41 db ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102553:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102558:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010255b:	e8 92 e9 ff ff       	call   f0100ef2 <check_va2pa>
f0102560:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102563:	74 24                	je     f0102589 <mem_init+0xe29>
f0102565:	c7 44 24 0c c0 50 10 	movl   $0xf01050c0,0xc(%esp)
f010256c:	f0 
f010256d:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0102574:	f0 
f0102575:	c7 44 24 04 46 03 00 	movl   $0x346,0x4(%esp)
f010257c:	00 
f010257d:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102584:	e8 0b db ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0102589:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f010258e:	74 24                	je     f01025b4 <mem_init+0xe54>
f0102590:	c7 44 24 0c 2f 55 10 	movl   $0xf010552f,0xc(%esp)
f0102597:	f0 
f0102598:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f010259f:	f0 
f01025a0:	c7 44 24 04 48 03 00 	movl   $0x348,0x4(%esp)
f01025a7:	00 
f01025a8:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f01025af:	e8 e0 da ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01025b4:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01025b9:	74 24                	je     f01025df <mem_init+0xe7f>
f01025bb:	c7 44 24 0c 40 55 10 	movl   $0xf0105540,0xc(%esp)
f01025c2:	f0 
f01025c3:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f01025ca:	f0 
f01025cb:	c7 44 24 04 49 03 00 	movl   $0x349,0x4(%esp)
f01025d2:	00 
f01025d3:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f01025da:	e8 b5 da ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f01025df:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01025e6:	e8 e1 ed ff ff       	call   f01013cc <page_alloc>
f01025eb:	85 c0                	test   %eax,%eax
f01025ed:	74 04                	je     f01025f3 <mem_init+0xe93>
f01025ef:	39 c6                	cmp    %eax,%esi
f01025f1:	74 24                	je     f0102617 <mem_init+0xeb7>
f01025f3:	c7 44 24 0c f0 50 10 	movl   $0xf01050f0,0xc(%esp)
f01025fa:	f0 
f01025fb:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0102602:	f0 
f0102603:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f010260a:	00 
f010260b:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102612:	e8 7d da ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0102617:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010261e:	00 
f010261f:	a1 a4 99 11 f0       	mov    0xf01199a4,%eax
f0102624:	89 04 24             	mov    %eax,(%esp)
f0102627:	e8 36 f0 ff ff       	call   f0101662 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010262c:	8b 15 a4 99 11 f0    	mov    0xf01199a4,%edx
f0102632:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0102635:	ba 00 00 00 00       	mov    $0x0,%edx
f010263a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010263d:	e8 b0 e8 ff ff       	call   f0100ef2 <check_va2pa>
f0102642:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102645:	74 24                	je     f010266b <mem_init+0xf0b>
f0102647:	c7 44 24 0c 14 51 10 	movl   $0xf0105114,0xc(%esp)
f010264e:	f0 
f010264f:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0102656:	f0 
f0102657:	c7 44 24 04 50 03 00 	movl   $0x350,0x4(%esp)
f010265e:	00 
f010265f:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102666:	e8 29 da ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010266b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102670:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102673:	e8 7a e8 ff ff       	call   f0100ef2 <check_va2pa>
f0102678:	89 fa                	mov    %edi,%edx
f010267a:	2b 15 a8 99 11 f0    	sub    0xf01199a8,%edx
f0102680:	c1 fa 03             	sar    $0x3,%edx
f0102683:	c1 e2 0c             	shl    $0xc,%edx
f0102686:	39 d0                	cmp    %edx,%eax
f0102688:	74 24                	je     f01026ae <mem_init+0xf4e>
f010268a:	c7 44 24 0c c0 50 10 	movl   $0xf01050c0,0xc(%esp)
f0102691:	f0 
f0102692:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0102699:	f0 
f010269a:	c7 44 24 04 51 03 00 	movl   $0x351,0x4(%esp)
f01026a1:	00 
f01026a2:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f01026a9:	e8 e6 d9 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f01026ae:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01026b3:	74 24                	je     f01026d9 <mem_init+0xf79>
f01026b5:	c7 44 24 0c e6 54 10 	movl   $0xf01054e6,0xc(%esp)
f01026bc:	f0 
f01026bd:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f01026c4:	f0 
f01026c5:	c7 44 24 04 52 03 00 	movl   $0x352,0x4(%esp)
f01026cc:	00 
f01026cd:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f01026d4:	e8 bb d9 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01026d9:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01026de:	74 24                	je     f0102704 <mem_init+0xfa4>
f01026e0:	c7 44 24 0c 40 55 10 	movl   $0xf0105540,0xc(%esp)
f01026e7:	f0 
f01026e8:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f01026ef:	f0 
f01026f0:	c7 44 24 04 53 03 00 	movl   $0x353,0x4(%esp)
f01026f7:	00 
f01026f8:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f01026ff:	e8 90 d9 ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102704:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010270b:	00 
f010270c:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010270f:	89 0c 24             	mov    %ecx,(%esp)
f0102712:	e8 4b ef ff ff       	call   f0101662 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102717:	a1 a4 99 11 f0       	mov    0xf01199a4,%eax
f010271c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010271f:	ba 00 00 00 00       	mov    $0x0,%edx
f0102724:	e8 c9 e7 ff ff       	call   f0100ef2 <check_va2pa>
f0102729:	83 f8 ff             	cmp    $0xffffffff,%eax
f010272c:	74 24                	je     f0102752 <mem_init+0xff2>
f010272e:	c7 44 24 0c 14 51 10 	movl   $0xf0105114,0xc(%esp)
f0102735:	f0 
f0102736:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f010273d:	f0 
f010273e:	c7 44 24 04 57 03 00 	movl   $0x357,0x4(%esp)
f0102745:	00 
f0102746:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f010274d:	e8 42 d9 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102752:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102757:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010275a:	e8 93 e7 ff ff       	call   f0100ef2 <check_va2pa>
f010275f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102762:	74 24                	je     f0102788 <mem_init+0x1028>
f0102764:	c7 44 24 0c 38 51 10 	movl   $0xf0105138,0xc(%esp)
f010276b:	f0 
f010276c:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0102773:	f0 
f0102774:	c7 44 24 04 58 03 00 	movl   $0x358,0x4(%esp)
f010277b:	00 
f010277c:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102783:	e8 0c d9 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102788:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f010278d:	74 24                	je     f01027b3 <mem_init+0x1053>
f010278f:	c7 44 24 0c 51 55 10 	movl   $0xf0105551,0xc(%esp)
f0102796:	f0 
f0102797:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f010279e:	f0 
f010279f:	c7 44 24 04 59 03 00 	movl   $0x359,0x4(%esp)
f01027a6:	00 
f01027a7:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f01027ae:	e8 e1 d8 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01027b3:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01027b8:	74 24                	je     f01027de <mem_init+0x107e>
f01027ba:	c7 44 24 0c 40 55 10 	movl   $0xf0105540,0xc(%esp)
f01027c1:	f0 
f01027c2:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f01027c9:	f0 
f01027ca:	c7 44 24 04 5a 03 00 	movl   $0x35a,0x4(%esp)
f01027d1:	00 
f01027d2:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f01027d9:	e8 b6 d8 ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f01027de:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01027e5:	e8 e2 eb ff ff       	call   f01013cc <page_alloc>
f01027ea:	85 c0                	test   %eax,%eax
f01027ec:	74 04                	je     f01027f2 <mem_init+0x1092>
f01027ee:	39 c7                	cmp    %eax,%edi
f01027f0:	74 24                	je     f0102816 <mem_init+0x10b6>
f01027f2:	c7 44 24 0c 60 51 10 	movl   $0xf0105160,0xc(%esp)
f01027f9:	f0 
f01027fa:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0102801:	f0 
f0102802:	c7 44 24 04 5d 03 00 	movl   $0x35d,0x4(%esp)
f0102809:	00 
f010280a:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102811:	e8 7e d8 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102816:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010281d:	e8 aa eb ff ff       	call   f01013cc <page_alloc>
f0102822:	85 c0                	test   %eax,%eax
f0102824:	74 24                	je     f010284a <mem_init+0x10ea>
f0102826:	c7 44 24 0c 94 54 10 	movl   $0xf0105494,0xc(%esp)
f010282d:	f0 
f010282e:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0102835:	f0 
f0102836:	c7 44 24 04 60 03 00 	movl   $0x360,0x4(%esp)
f010283d:	00 
f010283e:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102845:	e8 4a d8 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010284a:	a1 a4 99 11 f0       	mov    0xf01199a4,%eax
f010284f:	8b 08                	mov    (%eax),%ecx
f0102851:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102857:	89 da                	mov    %ebx,%edx
f0102859:	2b 15 a8 99 11 f0    	sub    0xf01199a8,%edx
f010285f:	c1 fa 03             	sar    $0x3,%edx
f0102862:	c1 e2 0c             	shl    $0xc,%edx
f0102865:	39 d1                	cmp    %edx,%ecx
f0102867:	74 24                	je     f010288d <mem_init+0x112d>
f0102869:	c7 44 24 0c 70 4e 10 	movl   $0xf0104e70,0xc(%esp)
f0102870:	f0 
f0102871:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0102878:	f0 
f0102879:	c7 44 24 04 63 03 00 	movl   $0x363,0x4(%esp)
f0102880:	00 
f0102881:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102888:	e8 07 d8 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f010288d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102893:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102898:	74 24                	je     f01028be <mem_init+0x115e>
f010289a:	c7 44 24 0c f7 54 10 	movl   $0xf01054f7,0xc(%esp)
f01028a1:	f0 
f01028a2:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f01028a9:	f0 
f01028aa:	c7 44 24 04 65 03 00 	movl   $0x365,0x4(%esp)
f01028b1:	00 
f01028b2:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f01028b9:	e8 d6 d7 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f01028be:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01028c4:	89 1c 24             	mov    %ebx,(%esp)
f01028c7:	e8 8d eb ff ff       	call   f0101459 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01028cc:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01028d3:	00 
f01028d4:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f01028db:	00 
f01028dc:	a1 a4 99 11 f0       	mov    0xf01199a4,%eax
f01028e1:	89 04 24             	mov    %eax,(%esp)
f01028e4:	e8 a8 eb ff ff       	call   f0101491 <pgdir_walk>
f01028e9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01028ec:	8b 0d a4 99 11 f0    	mov    0xf01199a4,%ecx
f01028f2:	8b 51 04             	mov    0x4(%ecx),%edx
f01028f5:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01028fb:	89 55 d4             	mov    %edx,-0x2c(%ebp)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01028fe:	8b 15 a0 99 11 f0    	mov    0xf01199a0,%edx
f0102904:	89 55 c8             	mov    %edx,-0x38(%ebp)
f0102907:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010290a:	c1 ea 0c             	shr    $0xc,%edx
f010290d:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102910:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0102913:	39 55 d0             	cmp    %edx,-0x30(%ebp)
f0102916:	72 23                	jb     f010293b <mem_init+0x11db>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102918:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010291b:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010291f:	c7 44 24 08 bc 48 10 	movl   $0xf01048bc,0x8(%esp)
f0102926:	f0 
f0102927:	c7 44 24 04 6c 03 00 	movl   $0x36c,0x4(%esp)
f010292e:	00 
f010292f:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102936:	e8 59 d7 ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f010293b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010293e:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0102944:	39 d0                	cmp    %edx,%eax
f0102946:	74 24                	je     f010296c <mem_init+0x120c>
f0102948:	c7 44 24 0c 62 55 10 	movl   $0xf0105562,0xc(%esp)
f010294f:	f0 
f0102950:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0102957:	f0 
f0102958:	c7 44 24 04 6d 03 00 	movl   $0x36d,0x4(%esp)
f010295f:	00 
f0102960:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102967:	e8 28 d7 ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f010296c:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f0102973:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102979:	89 d8                	mov    %ebx,%eax
f010297b:	2b 05 a8 99 11 f0    	sub    0xf01199a8,%eax
f0102981:	c1 f8 03             	sar    $0x3,%eax
f0102984:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102987:	89 c1                	mov    %eax,%ecx
f0102989:	c1 e9 0c             	shr    $0xc,%ecx
f010298c:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f010298f:	77 20                	ja     f01029b1 <mem_init+0x1251>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102991:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102995:	c7 44 24 08 bc 48 10 	movl   $0xf01048bc,0x8(%esp)
f010299c:	f0 
f010299d:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01029a4:	00 
f01029a5:	c7 04 24 24 53 10 f0 	movl   $0xf0105324,(%esp)
f01029ac:	e8 e3 d6 ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01029b1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01029b8:	00 
f01029b9:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f01029c0:	00 
	return (void *)(pa + KERNBASE);
f01029c1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01029c6:	89 04 24             	mov    %eax,(%esp)
f01029c9:	e8 98 14 00 00       	call   f0103e66 <memset>
	page_free(pp0);
f01029ce:	89 1c 24             	mov    %ebx,(%esp)
f01029d1:	e8 83 ea ff ff       	call   f0101459 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01029d6:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01029dd:	00 
f01029de:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01029e5:	00 
f01029e6:	a1 a4 99 11 f0       	mov    0xf01199a4,%eax
f01029eb:	89 04 24             	mov    %eax,(%esp)
f01029ee:	e8 9e ea ff ff       	call   f0101491 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01029f3:	89 da                	mov    %ebx,%edx
f01029f5:	2b 15 a8 99 11 f0    	sub    0xf01199a8,%edx
f01029fb:	c1 fa 03             	sar    $0x3,%edx
f01029fe:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a01:	89 d0                	mov    %edx,%eax
f0102a03:	c1 e8 0c             	shr    $0xc,%eax
f0102a06:	3b 05 a0 99 11 f0    	cmp    0xf01199a0,%eax
f0102a0c:	72 20                	jb     f0102a2e <mem_init+0x12ce>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a0e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102a12:	c7 44 24 08 bc 48 10 	movl   $0xf01048bc,0x8(%esp)
f0102a19:	f0 
f0102a1a:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102a21:	00 
f0102a22:	c7 04 24 24 53 10 f0 	movl   $0xf0105324,(%esp)
f0102a29:	e8 66 d6 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0102a2e:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102a34:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102a37:	f6 82 00 00 00 f0 01 	testb  $0x1,-0x10000000(%edx)
f0102a3e:	75 11                	jne    f0102a51 <mem_init+0x12f1>
f0102a40:	8d 82 04 00 00 f0    	lea    -0xffffffc(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102a46:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102a4c:	f6 00 01             	testb  $0x1,(%eax)
f0102a4f:	74 24                	je     f0102a75 <mem_init+0x1315>
f0102a51:	c7 44 24 0c 7a 55 10 	movl   $0xf010557a,0xc(%esp)
f0102a58:	f0 
f0102a59:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0102a60:	f0 
f0102a61:	c7 44 24 04 77 03 00 	movl   $0x377,0x4(%esp)
f0102a68:	00 
f0102a69:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102a70:	e8 1f d6 ff ff       	call   f0100094 <_panic>
f0102a75:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102a78:	39 d0                	cmp    %edx,%eax
f0102a7a:	75 d0                	jne    f0102a4c <mem_init+0x12ec>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102a7c:	a1 a4 99 11 f0       	mov    0xf01199a4,%eax
f0102a81:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102a87:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// give free list back
	page_free_list = fl;
f0102a8d:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102a90:	89 0d 80 95 11 f0    	mov    %ecx,0xf0119580

	// free the pages we took
	page_free(pp0);
f0102a96:	89 1c 24             	mov    %ebx,(%esp)
f0102a99:	e8 bb e9 ff ff       	call   f0101459 <page_free>
	page_free(pp1);
f0102a9e:	89 3c 24             	mov    %edi,(%esp)
f0102aa1:	e8 b3 e9 ff ff       	call   f0101459 <page_free>
	page_free(pp2);
f0102aa6:	89 34 24             	mov    %esi,(%esp)
f0102aa9:	e8 ab e9 ff ff       	call   f0101459 <page_free>

	cprintf("check_page() succeeded!\n");
f0102aae:	c7 04 24 91 55 10 f0 	movl   $0xf0105591,(%esp)
f0102ab5:	e8 a8 07 00 00       	call   f0103262 <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:

	boot_map_region(kern_pgdir,UPAGES,npages * sizeof (struct Page),PADDR (pages), PTE_U| PTE_P);
f0102aba:	a1 a8 99 11 f0       	mov    0xf01199a8,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102abf:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102ac4:	77 20                	ja     f0102ae6 <mem_init+0x1386>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ac6:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102aca:	c7 44 24 08 18 4d 10 	movl   $0xf0104d18,0x8(%esp)
f0102ad1:	f0 
f0102ad2:	c7 44 24 04 ad 00 00 	movl   $0xad,0x4(%esp)
f0102ad9:	00 
f0102ada:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102ae1:	e8 ae d5 ff ff       	call   f0100094 <_panic>
f0102ae6:	8b 0d a0 99 11 f0    	mov    0xf01199a0,%ecx
f0102aec:	c1 e1 03             	shl    $0x3,%ecx
f0102aef:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102af6:	00 
	return (physaddr_t)kva - KERNBASE;
f0102af7:	05 00 00 00 10       	add    $0x10000000,%eax
f0102afc:	89 04 24             	mov    %eax,(%esp)
f0102aff:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102b04:	a1 a4 99 11 f0       	mov    0xf01199a4,%eax
f0102b09:	e8 67 ea ff ff       	call   f0101575 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102b0e:	b8 00 f0 10 f0       	mov    $0xf010f000,%eax
f0102b13:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102b18:	77 20                	ja     f0102b3a <mem_init+0x13da>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102b1a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102b1e:	c7 44 24 08 18 4d 10 	movl   $0xf0104d18,0x8(%esp)
f0102b25:	f0 
f0102b26:	c7 44 24 04 b9 00 00 	movl   $0xb9,0x4(%esp)
f0102b2d:	00 
f0102b2e:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102b35:	e8 5a d5 ff ff       	call   f0100094 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region (kern_pgdir,KSTACKTOP - KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_W| PTE_P);
f0102b3a:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102b41:	00 
f0102b42:	c7 04 24 00 f0 10 00 	movl   $0x10f000,(%esp)
f0102b49:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102b4e:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f0102b53:	a1 a4 99 11 f0       	mov    0xf01199a4,%eax
f0102b58:	e8 18 ea ff ff       	call   f0101575 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region (kern_pgdir,KERNBASE,0xffffffff-KERNBASE+1, 0,PTE_W| PTE_P);
f0102b5d:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102b64:	00 
f0102b65:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102b6c:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102b71:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102b76:	a1 a4 99 11 f0       	mov    0xf01199a4,%eax
f0102b7b:	e8 f5 e9 ff ff       	call   f0101575 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102b80:	8b 1d a4 99 11 f0    	mov    0xf01199a4,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
f0102b86:	8b 15 a0 99 11 f0    	mov    0xf01199a0,%edx
f0102b8c:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0102b8f:	8d 3c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%edi
	for (i = 0; i < n; i += PGSIZE)
f0102b96:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
f0102b9c:	74 79                	je     f0102c17 <mem_init+0x14b7>
f0102b9e:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102ba3:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102ba9:	89 d8                	mov    %ebx,%eax
f0102bab:	e8 42 e3 ff ff       	call   f0100ef2 <check_va2pa>
f0102bb0:	8b 15 a8 99 11 f0    	mov    0xf01199a8,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102bb6:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102bbc:	77 20                	ja     f0102bde <mem_init+0x147e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102bbe:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102bc2:	c7 44 24 08 18 4d 10 	movl   $0xf0104d18,0x8(%esp)
f0102bc9:	f0 
f0102bca:	c7 44 24 04 c3 02 00 	movl   $0x2c3,0x4(%esp)
f0102bd1:	00 
f0102bd2:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102bd9:	e8 b6 d4 ff ff       	call   f0100094 <_panic>
f0102bde:	8d 94 32 00 00 00 10 	lea    0x10000000(%edx,%esi,1),%edx
f0102be5:	39 d0                	cmp    %edx,%eax
f0102be7:	74 24                	je     f0102c0d <mem_init+0x14ad>
f0102be9:	c7 44 24 0c 84 51 10 	movl   $0xf0105184,0xc(%esp)
f0102bf0:	f0 
f0102bf1:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0102bf8:	f0 
f0102bf9:	c7 44 24 04 c3 02 00 	movl   $0x2c3,0x4(%esp)
f0102c00:	00 
f0102c01:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102c08:	e8 87 d4 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102c0d:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102c13:	39 f7                	cmp    %esi,%edi
f0102c15:	77 8c                	ja     f0102ba3 <mem_init+0x1443>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102c17:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102c1a:	c1 e7 0c             	shl    $0xc,%edi
f0102c1d:	85 ff                	test   %edi,%edi
f0102c1f:	74 44                	je     f0102c65 <mem_init+0x1505>
f0102c21:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102c26:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102c2c:	89 d8                	mov    %ebx,%eax
f0102c2e:	e8 bf e2 ff ff       	call   f0100ef2 <check_va2pa>
f0102c33:	39 c6                	cmp    %eax,%esi
f0102c35:	74 24                	je     f0102c5b <mem_init+0x14fb>
f0102c37:	c7 44 24 0c b8 51 10 	movl   $0xf01051b8,0xc(%esp)
f0102c3e:	f0 
f0102c3f:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0102c46:	f0 
f0102c47:	c7 44 24 04 c8 02 00 	movl   $0x2c8,0x4(%esp)
f0102c4e:	00 
f0102c4f:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102c56:	e8 39 d4 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102c5b:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102c61:	39 fe                	cmp    %edi,%esi
f0102c63:	72 c1                	jb     f0102c26 <mem_init+0x14c6>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102c65:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f0102c6a:	89 d8                	mov    %ebx,%eax
f0102c6c:	e8 81 e2 ff ff       	call   f0100ef2 <check_va2pa>
f0102c71:	be 00 90 bf ef       	mov    $0xefbf9000,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102c76:	bf 00 f0 10 f0       	mov    $0xf010f000,%edi
f0102c7b:	81 c7 00 70 40 20    	add    $0x20407000,%edi
f0102c81:	8d 14 37             	lea    (%edi,%esi,1),%edx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102c84:	39 c2                	cmp    %eax,%edx
f0102c86:	74 24                	je     f0102cac <mem_init+0x154c>
f0102c88:	c7 44 24 0c e0 51 10 	movl   $0xf01051e0,0xc(%esp)
f0102c8f:	f0 
f0102c90:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0102c97:	f0 
f0102c98:	c7 44 24 04 cc 02 00 	movl   $0x2cc,0x4(%esp)
f0102c9f:	00 
f0102ca0:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102ca7:	e8 e8 d3 ff ff       	call   f0100094 <_panic>
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102cac:	81 fe 00 00 c0 ef    	cmp    $0xefc00000,%esi
f0102cb2:	0f 85 27 05 00 00    	jne    f01031df <mem_init+0x1a7f>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102cb8:	ba 00 00 80 ef       	mov    $0xef800000,%edx
f0102cbd:	89 d8                	mov    %ebx,%eax
f0102cbf:	e8 2e e2 ff ff       	call   f0100ef2 <check_va2pa>
f0102cc4:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102cc7:	74 24                	je     f0102ced <mem_init+0x158d>
f0102cc9:	c7 44 24 0c 28 52 10 	movl   $0xf0105228,0xc(%esp)
f0102cd0:	f0 
f0102cd1:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0102cd8:	f0 
f0102cd9:	c7 44 24 04 cd 02 00 	movl   $0x2cd,0x4(%esp)
f0102ce0:	00 
f0102ce1:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102ce8:	e8 a7 d3 ff ff       	call   f0100094 <_panic>
f0102ced:	b8 00 00 00 00       	mov    $0x0,%eax

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102cf2:	8d 90 44 fc ff ff    	lea    -0x3bc(%eax),%edx
f0102cf8:	83 fa 02             	cmp    $0x2,%edx
f0102cfb:	77 2e                	ja     f0102d2b <mem_init+0x15cb>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0102cfd:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0102d01:	0f 85 aa 00 00 00    	jne    f0102db1 <mem_init+0x1651>
f0102d07:	c7 44 24 0c aa 55 10 	movl   $0xf01055aa,0xc(%esp)
f0102d0e:	f0 
f0102d0f:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0102d16:	f0 
f0102d17:	c7 44 24 04 d5 02 00 	movl   $0x2d5,0x4(%esp)
f0102d1e:	00 
f0102d1f:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102d26:	e8 69 d3 ff ff       	call   f0100094 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102d2b:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102d30:	76 55                	jbe    f0102d87 <mem_init+0x1627>
				assert(pgdir[i] & PTE_P);
f0102d32:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0102d35:	f6 c2 01             	test   $0x1,%dl
f0102d38:	75 24                	jne    f0102d5e <mem_init+0x15fe>
f0102d3a:	c7 44 24 0c aa 55 10 	movl   $0xf01055aa,0xc(%esp)
f0102d41:	f0 
f0102d42:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0102d49:	f0 
f0102d4a:	c7 44 24 04 d9 02 00 	movl   $0x2d9,0x4(%esp)
f0102d51:	00 
f0102d52:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102d59:	e8 36 d3 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f0102d5e:	f6 c2 02             	test   $0x2,%dl
f0102d61:	75 4e                	jne    f0102db1 <mem_init+0x1651>
f0102d63:	c7 44 24 0c bb 55 10 	movl   $0xf01055bb,0xc(%esp)
f0102d6a:	f0 
f0102d6b:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0102d72:	f0 
f0102d73:	c7 44 24 04 da 02 00 	movl   $0x2da,0x4(%esp)
f0102d7a:	00 
f0102d7b:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102d82:	e8 0d d3 ff ff       	call   f0100094 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102d87:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0102d8b:	74 24                	je     f0102db1 <mem_init+0x1651>
f0102d8d:	c7 44 24 0c cc 55 10 	movl   $0xf01055cc,0xc(%esp)
f0102d94:	f0 
f0102d95:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0102d9c:	f0 
f0102d9d:	c7 44 24 04 dc 02 00 	movl   $0x2dc,0x4(%esp)
f0102da4:	00 
f0102da5:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102dac:	e8 e3 d2 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102db1:	83 c0 01             	add    $0x1,%eax
f0102db4:	3d 00 04 00 00       	cmp    $0x400,%eax
f0102db9:	0f 85 33 ff ff ff    	jne    f0102cf2 <mem_init+0x1592>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102dbf:	c7 04 24 58 52 10 f0 	movl   $0xf0105258,(%esp)
f0102dc6:	e8 97 04 00 00       	call   f0103262 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102dcb:	a1 a4 99 11 f0       	mov    0xf01199a4,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102dd0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102dd5:	77 20                	ja     f0102df7 <mem_init+0x1697>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102dd7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102ddb:	c7 44 24 08 18 4d 10 	movl   $0xf0104d18,0x8(%esp)
f0102de2:	f0 
f0102de3:	c7 44 24 04 cd 00 00 	movl   $0xcd,0x4(%esp)
f0102dea:	00 
f0102deb:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102df2:	e8 9d d2 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102df7:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102dfc:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102dff:	b8 00 00 00 00       	mov    $0x0,%eax
f0102e04:	e8 8c e1 ff ff       	call   f0100f95 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102e09:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
f0102e0c:	0d 23 00 05 80       	or     $0x80050023,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102e11:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102e14:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102e17:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102e1e:	e8 a9 e5 ff ff       	call   f01013cc <page_alloc>
f0102e23:	89 c6                	mov    %eax,%esi
f0102e25:	85 c0                	test   %eax,%eax
f0102e27:	75 24                	jne    f0102e4d <mem_init+0x16ed>
f0102e29:	c7 44 24 0c e9 53 10 	movl   $0xf01053e9,0xc(%esp)
f0102e30:	f0 
f0102e31:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0102e38:	f0 
f0102e39:	c7 44 24 04 92 03 00 	movl   $0x392,0x4(%esp)
f0102e40:	00 
f0102e41:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102e48:	e8 47 d2 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0102e4d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102e54:	e8 73 e5 ff ff       	call   f01013cc <page_alloc>
f0102e59:	89 c7                	mov    %eax,%edi
f0102e5b:	85 c0                	test   %eax,%eax
f0102e5d:	75 24                	jne    f0102e83 <mem_init+0x1723>
f0102e5f:	c7 44 24 0c ff 53 10 	movl   $0xf01053ff,0xc(%esp)
f0102e66:	f0 
f0102e67:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0102e6e:	f0 
f0102e6f:	c7 44 24 04 93 03 00 	movl   $0x393,0x4(%esp)
f0102e76:	00 
f0102e77:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102e7e:	e8 11 d2 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0102e83:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102e8a:	e8 3d e5 ff ff       	call   f01013cc <page_alloc>
f0102e8f:	89 c3                	mov    %eax,%ebx
f0102e91:	85 c0                	test   %eax,%eax
f0102e93:	75 24                	jne    f0102eb9 <mem_init+0x1759>
f0102e95:	c7 44 24 0c 15 54 10 	movl   $0xf0105415,0xc(%esp)
f0102e9c:	f0 
f0102e9d:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0102ea4:	f0 
f0102ea5:	c7 44 24 04 94 03 00 	movl   $0x394,0x4(%esp)
f0102eac:	00 
f0102ead:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102eb4:	e8 db d1 ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f0102eb9:	89 34 24             	mov    %esi,(%esp)
f0102ebc:	e8 98 e5 ff ff       	call   f0101459 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102ec1:	89 f8                	mov    %edi,%eax
f0102ec3:	2b 05 a8 99 11 f0    	sub    0xf01199a8,%eax
f0102ec9:	c1 f8 03             	sar    $0x3,%eax
f0102ecc:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102ecf:	89 c2                	mov    %eax,%edx
f0102ed1:	c1 ea 0c             	shr    $0xc,%edx
f0102ed4:	3b 15 a0 99 11 f0    	cmp    0xf01199a0,%edx
f0102eda:	72 20                	jb     f0102efc <mem_init+0x179c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102edc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102ee0:	c7 44 24 08 bc 48 10 	movl   $0xf01048bc,0x8(%esp)
f0102ee7:	f0 
f0102ee8:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102eef:	00 
f0102ef0:	c7 04 24 24 53 10 f0 	movl   $0xf0105324,(%esp)
f0102ef7:	e8 98 d1 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102efc:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102f03:	00 
f0102f04:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102f0b:	00 
	return (void *)(pa + KERNBASE);
f0102f0c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102f11:	89 04 24             	mov    %eax,(%esp)
f0102f14:	e8 4d 0f 00 00       	call   f0103e66 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102f19:	89 d8                	mov    %ebx,%eax
f0102f1b:	2b 05 a8 99 11 f0    	sub    0xf01199a8,%eax
f0102f21:	c1 f8 03             	sar    $0x3,%eax
f0102f24:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102f27:	89 c2                	mov    %eax,%edx
f0102f29:	c1 ea 0c             	shr    $0xc,%edx
f0102f2c:	3b 15 a0 99 11 f0    	cmp    0xf01199a0,%edx
f0102f32:	72 20                	jb     f0102f54 <mem_init+0x17f4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102f34:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102f38:	c7 44 24 08 bc 48 10 	movl   $0xf01048bc,0x8(%esp)
f0102f3f:	f0 
f0102f40:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102f47:	00 
f0102f48:	c7 04 24 24 53 10 f0 	movl   $0xf0105324,(%esp)
f0102f4f:	e8 40 d1 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102f54:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102f5b:	00 
f0102f5c:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102f63:	00 
	return (void *)(pa + KERNBASE);
f0102f64:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102f69:	89 04 24             	mov    %eax,(%esp)
f0102f6c:	e8 f5 0e 00 00       	call   f0103e66 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102f71:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102f78:	00 
f0102f79:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102f80:	00 
f0102f81:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102f85:	a1 a4 99 11 f0       	mov    0xf01199a4,%eax
f0102f8a:	89 04 24             	mov    %eax,(%esp)
f0102f8d:	e8 24 e7 ff ff       	call   f01016b6 <page_insert>
	assert(pp1->pp_ref == 1);
f0102f92:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102f97:	74 24                	je     f0102fbd <mem_init+0x185d>
f0102f99:	c7 44 24 0c e6 54 10 	movl   $0xf01054e6,0xc(%esp)
f0102fa0:	f0 
f0102fa1:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0102fa8:	f0 
f0102fa9:	c7 44 24 04 99 03 00 	movl   $0x399,0x4(%esp)
f0102fb0:	00 
f0102fb1:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102fb8:	e8 d7 d0 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102fbd:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102fc4:	01 01 01 
f0102fc7:	74 24                	je     f0102fed <mem_init+0x188d>
f0102fc9:	c7 44 24 0c 78 52 10 	movl   $0xf0105278,0xc(%esp)
f0102fd0:	f0 
f0102fd1:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0102fd8:	f0 
f0102fd9:	c7 44 24 04 9a 03 00 	movl   $0x39a,0x4(%esp)
f0102fe0:	00 
f0102fe1:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0102fe8:	e8 a7 d0 ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102fed:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102ff4:	00 
f0102ff5:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102ffc:	00 
f0102ffd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103001:	a1 a4 99 11 f0       	mov    0xf01199a4,%eax
f0103006:	89 04 24             	mov    %eax,(%esp)
f0103009:	e8 a8 e6 ff ff       	call   f01016b6 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010300e:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0103015:	02 02 02 
f0103018:	74 24                	je     f010303e <mem_init+0x18de>
f010301a:	c7 44 24 0c 9c 52 10 	movl   $0xf010529c,0xc(%esp)
f0103021:	f0 
f0103022:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0103029:	f0 
f010302a:	c7 44 24 04 9c 03 00 	movl   $0x39c,0x4(%esp)
f0103031:	00 
f0103032:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0103039:	e8 56 d0 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f010303e:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0103043:	74 24                	je     f0103069 <mem_init+0x1909>
f0103045:	c7 44 24 0c 08 55 10 	movl   $0xf0105508,0xc(%esp)
f010304c:	f0 
f010304d:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0103054:	f0 
f0103055:	c7 44 24 04 9d 03 00 	movl   $0x39d,0x4(%esp)
f010305c:	00 
f010305d:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0103064:	e8 2b d0 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0103069:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f010306e:	74 24                	je     f0103094 <mem_init+0x1934>
f0103070:	c7 44 24 0c 51 55 10 	movl   $0xf0105551,0xc(%esp)
f0103077:	f0 
f0103078:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f010307f:	f0 
f0103080:	c7 44 24 04 9e 03 00 	movl   $0x39e,0x4(%esp)
f0103087:	00 
f0103088:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f010308f:	e8 00 d0 ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0103094:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f010309b:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f010309e:	89 d8                	mov    %ebx,%eax
f01030a0:	2b 05 a8 99 11 f0    	sub    0xf01199a8,%eax
f01030a6:	c1 f8 03             	sar    $0x3,%eax
f01030a9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01030ac:	89 c2                	mov    %eax,%edx
f01030ae:	c1 ea 0c             	shr    $0xc,%edx
f01030b1:	3b 15 a0 99 11 f0    	cmp    0xf01199a0,%edx
f01030b7:	72 20                	jb     f01030d9 <mem_init+0x1979>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01030b9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01030bd:	c7 44 24 08 bc 48 10 	movl   $0xf01048bc,0x8(%esp)
f01030c4:	f0 
f01030c5:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01030cc:	00 
f01030cd:	c7 04 24 24 53 10 f0 	movl   $0xf0105324,(%esp)
f01030d4:	e8 bb cf ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01030d9:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01030e0:	03 03 03 
f01030e3:	74 24                	je     f0103109 <mem_init+0x19a9>
f01030e5:	c7 44 24 0c c0 52 10 	movl   $0xf01052c0,0xc(%esp)
f01030ec:	f0 
f01030ed:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f01030f4:	f0 
f01030f5:	c7 44 24 04 a0 03 00 	movl   $0x3a0,0x4(%esp)
f01030fc:	00 
f01030fd:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0103104:	e8 8b cf ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0103109:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0103110:	00 
f0103111:	a1 a4 99 11 f0       	mov    0xf01199a4,%eax
f0103116:	89 04 24             	mov    %eax,(%esp)
f0103119:	e8 44 e5 ff ff       	call   f0101662 <page_remove>
	assert(pp2->pp_ref == 0);
f010311e:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0103123:	74 24                	je     f0103149 <mem_init+0x19e9>
f0103125:	c7 44 24 0c 40 55 10 	movl   $0xf0105540,0xc(%esp)
f010312c:	f0 
f010312d:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0103134:	f0 
f0103135:	c7 44 24 04 a2 03 00 	movl   $0x3a2,0x4(%esp)
f010313c:	00 
f010313d:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0103144:	e8 4b cf ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0103149:	a1 a4 99 11 f0       	mov    0xf01199a4,%eax
f010314e:	8b 08                	mov    (%eax),%ecx
f0103150:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0103156:	89 f2                	mov    %esi,%edx
f0103158:	2b 15 a8 99 11 f0    	sub    0xf01199a8,%edx
f010315e:	c1 fa 03             	sar    $0x3,%edx
f0103161:	c1 e2 0c             	shl    $0xc,%edx
f0103164:	39 d1                	cmp    %edx,%ecx
f0103166:	74 24                	je     f010318c <mem_init+0x1a2c>
f0103168:	c7 44 24 0c 70 4e 10 	movl   $0xf0104e70,0xc(%esp)
f010316f:	f0 
f0103170:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f0103177:	f0 
f0103178:	c7 44 24 04 a5 03 00 	movl   $0x3a5,0x4(%esp)
f010317f:	00 
f0103180:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f0103187:	e8 08 cf ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f010318c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0103192:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0103197:	74 24                	je     f01031bd <mem_init+0x1a5d>
f0103199:	c7 44 24 0c f7 54 10 	movl   $0xf01054f7,0xc(%esp)
f01031a0:	f0 
f01031a1:	c7 44 24 08 3e 53 10 	movl   $0xf010533e,0x8(%esp)
f01031a8:	f0 
f01031a9:	c7 44 24 04 a7 03 00 	movl   $0x3a7,0x4(%esp)
f01031b0:	00 
f01031b1:	c7 04 24 18 53 10 f0 	movl   $0xf0105318,(%esp)
f01031b8:	e8 d7 ce ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f01031bd:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f01031c3:	89 34 24             	mov    %esi,(%esp)
f01031c6:	e8 8e e2 ff ff       	call   f0101459 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01031cb:	c7 04 24 ec 52 10 f0 	movl   $0xf01052ec,(%esp)
f01031d2:	e8 8b 00 00 00       	call   f0103262 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f01031d7:	83 c4 3c             	add    $0x3c,%esp
f01031da:	5b                   	pop    %ebx
f01031db:	5e                   	pop    %esi
f01031dc:	5f                   	pop    %edi
f01031dd:	5d                   	pop    %ebp
f01031de:	c3                   	ret    
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01031df:	89 f2                	mov    %esi,%edx
f01031e1:	89 d8                	mov    %ebx,%eax
f01031e3:	e8 0a dd ff ff       	call   f0100ef2 <check_va2pa>
f01031e8:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01031ee:	e9 8e fa ff ff       	jmp    f0102c81 <mem_init+0x1521>
	...

f01031f4 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01031f4:	55                   	push   %ebp
f01031f5:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01031f7:	ba 70 00 00 00       	mov    $0x70,%edx
f01031fc:	8b 45 08             	mov    0x8(%ebp),%eax
f01031ff:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103200:	b2 71                	mov    $0x71,%dl
f0103202:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103203:	0f b6 c0             	movzbl %al,%eax
}
f0103206:	5d                   	pop    %ebp
f0103207:	c3                   	ret    

f0103208 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103208:	55                   	push   %ebp
f0103209:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010320b:	ba 70 00 00 00       	mov    $0x70,%edx
f0103210:	8b 45 08             	mov    0x8(%ebp),%eax
f0103213:	ee                   	out    %al,(%dx)
f0103214:	b2 71                	mov    $0x71,%dl
f0103216:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103219:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010321a:	5d                   	pop    %ebp
f010321b:	c3                   	ret    

f010321c <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010321c:	55                   	push   %ebp
f010321d:	89 e5                	mov    %esp,%ebp
f010321f:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0103222:	8b 45 08             	mov    0x8(%ebp),%eax
f0103225:	89 04 24             	mov    %eax,(%esp)
f0103228:	e8 c4 d3 ff ff       	call   f01005f1 <cputchar>
	*cnt++;
}
f010322d:	c9                   	leave  
f010322e:	c3                   	ret    

f010322f <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010322f:	55                   	push   %ebp
f0103230:	89 e5                	mov    %esp,%ebp
f0103232:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0103235:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010323c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010323f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103243:	8b 45 08             	mov    0x8(%ebp),%eax
f0103246:	89 44 24 08          	mov    %eax,0x8(%esp)
f010324a:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010324d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103251:	c7 04 24 1c 32 10 f0 	movl   $0xf010321c,(%esp)
f0103258:	e8 6d 04 00 00       	call   f01036ca <vprintfmt>
	return cnt;
}
f010325d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103260:	c9                   	leave  
f0103261:	c3                   	ret    

f0103262 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103262:	55                   	push   %ebp
f0103263:	89 e5                	mov    %esp,%ebp
f0103265:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103268:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010326b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010326f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103272:	89 04 24             	mov    %eax,(%esp)
f0103275:	e8 b5 ff ff ff       	call   f010322f <vcprintf>
	va_end(ap);

	return cnt;
}
f010327a:	c9                   	leave  
f010327b:	c3                   	ret    

f010327c <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010327c:	55                   	push   %ebp
f010327d:	89 e5                	mov    %esp,%ebp
f010327f:	57                   	push   %edi
f0103280:	56                   	push   %esi
f0103281:	53                   	push   %ebx
f0103282:	83 ec 10             	sub    $0x10,%esp
f0103285:	89 c3                	mov    %eax,%ebx
f0103287:	89 55 e8             	mov    %edx,-0x18(%ebp)
f010328a:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f010328d:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0103290:	8b 0a                	mov    (%edx),%ecx
f0103292:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103295:	8b 00                	mov    (%eax),%eax
f0103297:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010329a:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f01032a1:	eb 77                	jmp    f010331a <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f01032a3:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01032a6:	01 c8                	add    %ecx,%eax
f01032a8:	bf 02 00 00 00       	mov    $0x2,%edi
f01032ad:	99                   	cltd   
f01032ae:	f7 ff                	idiv   %edi
f01032b0:	89 c2                	mov    %eax,%edx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01032b2:	eb 01                	jmp    f01032b5 <stab_binsearch+0x39>
			m--;
f01032b4:	4a                   	dec    %edx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01032b5:	39 ca                	cmp    %ecx,%edx
f01032b7:	7c 1d                	jl     f01032d6 <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f01032b9:	6b fa 0c             	imul   $0xc,%edx,%edi
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01032bc:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f01032c1:	39 f7                	cmp    %esi,%edi
f01032c3:	75 ef                	jne    f01032b4 <stab_binsearch+0x38>
f01032c5:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01032c8:	6b fa 0c             	imul   $0xc,%edx,%edi
f01032cb:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f01032cf:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f01032d2:	73 18                	jae    f01032ec <stab_binsearch+0x70>
f01032d4:	eb 05                	jmp    f01032db <stab_binsearch+0x5f>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01032d6:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f01032d9:	eb 3f                	jmp    f010331a <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f01032db:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f01032de:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f01032e0:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01032e3:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f01032ea:	eb 2e                	jmp    f010331a <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01032ec:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f01032ef:	76 15                	jbe    f0103306 <stab_binsearch+0x8a>
			*region_right = m - 1;
f01032f1:	8b 7d ec             	mov    -0x14(%ebp),%edi
f01032f4:	4f                   	dec    %edi
f01032f5:	89 7d f0             	mov    %edi,-0x10(%ebp)
f01032f8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01032fb:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01032fd:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0103304:	eb 14                	jmp    f010331a <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103306:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0103309:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f010330c:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f010330e:	ff 45 0c             	incl   0xc(%ebp)
f0103311:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103313:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f010331a:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f010331d:	7e 84                	jle    f01032a3 <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010331f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0103323:	75 0d                	jne    f0103332 <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0103325:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0103328:	8b 02                	mov    (%edx),%eax
f010332a:	48                   	dec    %eax
f010332b:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010332e:	89 01                	mov    %eax,(%ecx)
f0103330:	eb 22                	jmp    f0103354 <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103332:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0103335:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103337:	8b 55 e8             	mov    -0x18(%ebp),%edx
f010333a:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010333c:	eb 01                	jmp    f010333f <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010333e:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010333f:	39 c1                	cmp    %eax,%ecx
f0103341:	7d 0c                	jge    f010334f <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0103343:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0103346:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f010334b:	39 f2                	cmp    %esi,%edx
f010334d:	75 ef                	jne    f010333e <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f010334f:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0103352:	89 02                	mov    %eax,(%edx)
	}
}
f0103354:	83 c4 10             	add    $0x10,%esp
f0103357:	5b                   	pop    %ebx
f0103358:	5e                   	pop    %esi
f0103359:	5f                   	pop    %edi
f010335a:	5d                   	pop    %ebp
f010335b:	c3                   	ret    

f010335c <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010335c:	55                   	push   %ebp
f010335d:	89 e5                	mov    %esp,%ebp
f010335f:	83 ec 38             	sub    $0x38,%esp
f0103362:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0103365:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0103368:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010336b:	8b 75 08             	mov    0x8(%ebp),%esi
f010336e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103371:	c7 03 f6 46 10 f0    	movl   $0xf01046f6,(%ebx)
	info->eip_line = 0;
f0103377:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f010337e:	c7 43 08 f6 46 10 f0 	movl   $0xf01046f6,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0103385:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f010338c:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f010338f:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0103396:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f010339c:	76 12                	jbe    f01033b0 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010339e:	b8 81 e0 10 f0       	mov    $0xf010e081,%eax
f01033a3:	3d 71 c1 10 f0       	cmp    $0xf010c171,%eax
f01033a8:	0f 86 9b 01 00 00    	jbe    f0103549 <debuginfo_eip+0x1ed>
f01033ae:	eb 1c                	jmp    f01033cc <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f01033b0:	c7 44 24 08 da 55 10 	movl   $0xf01055da,0x8(%esp)
f01033b7:	f0 
f01033b8:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f01033bf:	00 
f01033c0:	c7 04 24 e7 55 10 f0 	movl   $0xf01055e7,(%esp)
f01033c7:	e8 c8 cc ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01033cc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01033d1:	80 3d 80 e0 10 f0 00 	cmpb   $0x0,0xf010e080
f01033d8:	0f 85 77 01 00 00    	jne    f0103555 <debuginfo_eip+0x1f9>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01033de:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01033e5:	b8 70 c1 10 f0       	mov    $0xf010c170,%eax
f01033ea:	2d 04 58 10 f0       	sub    $0xf0105804,%eax
f01033ef:	c1 f8 02             	sar    $0x2,%eax
f01033f2:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01033f8:	83 e8 01             	sub    $0x1,%eax
f01033fb:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01033fe:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103402:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0103409:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f010340c:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010340f:	b8 04 58 10 f0       	mov    $0xf0105804,%eax
f0103414:	e8 63 fe ff ff       	call   f010327c <stab_binsearch>
	if (lfile == 0)
f0103419:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f010341c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0103421:	85 d2                	test   %edx,%edx
f0103423:	0f 84 2c 01 00 00    	je     f0103555 <debuginfo_eip+0x1f9>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103429:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f010342c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010342f:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103432:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103436:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f010343d:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0103440:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103443:	b8 04 58 10 f0       	mov    $0xf0105804,%eax
f0103448:	e8 2f fe ff ff       	call   f010327c <stab_binsearch>

	if (lfun <= rfun) {
f010344d:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0103450:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0103453:	7f 2e                	jg     f0103483 <debuginfo_eip+0x127>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103455:	6b c7 0c             	imul   $0xc,%edi,%eax
f0103458:	8d 90 04 58 10 f0    	lea    -0xfefa7fc(%eax),%edx
f010345e:	8b 80 04 58 10 f0    	mov    -0xfefa7fc(%eax),%eax
f0103464:	b9 81 e0 10 f0       	mov    $0xf010e081,%ecx
f0103469:	81 e9 71 c1 10 f0    	sub    $0xf010c171,%ecx
f010346f:	39 c8                	cmp    %ecx,%eax
f0103471:	73 08                	jae    f010347b <debuginfo_eip+0x11f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103473:	05 71 c1 10 f0       	add    $0xf010c171,%eax
f0103478:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f010347b:	8b 42 08             	mov    0x8(%edx),%eax
f010347e:	89 43 10             	mov    %eax,0x10(%ebx)
f0103481:	eb 06                	jmp    f0103489 <debuginfo_eip+0x12d>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103483:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0103486:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103489:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0103490:	00 
f0103491:	8b 43 08             	mov    0x8(%ebx),%eax
f0103494:	89 04 24             	mov    %eax,(%esp)
f0103497:	e8 a3 09 00 00       	call   f0103e3f <strfind>
f010349c:	2b 43 08             	sub    0x8(%ebx),%eax
f010349f:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01034a2:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01034a5:	39 d7                	cmp    %edx,%edi
f01034a7:	7c 5f                	jl     f0103508 <debuginfo_eip+0x1ac>
	       && stabs[lline].n_type != N_SOL
f01034a9:	89 f8                	mov    %edi,%eax
f01034ab:	6b cf 0c             	imul   $0xc,%edi,%ecx
f01034ae:	80 b9 08 58 10 f0 84 	cmpb   $0x84,-0xfefa7f8(%ecx)
f01034b5:	75 18                	jne    f01034cf <debuginfo_eip+0x173>
f01034b7:	eb 30                	jmp    f01034e9 <debuginfo_eip+0x18d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f01034b9:	83 ef 01             	sub    $0x1,%edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01034bc:	39 fa                	cmp    %edi,%edx
f01034be:	7f 48                	jg     f0103508 <debuginfo_eip+0x1ac>
	       && stabs[lline].n_type != N_SOL
f01034c0:	89 f8                	mov    %edi,%eax
f01034c2:	8d 0c 7f             	lea    (%edi,%edi,2),%ecx
f01034c5:	80 3c 8d 08 58 10 f0 	cmpb   $0x84,-0xfefa7f8(,%ecx,4)
f01034cc:	84 
f01034cd:	74 1a                	je     f01034e9 <debuginfo_eip+0x18d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01034cf:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01034d2:	8d 04 85 04 58 10 f0 	lea    -0xfefa7fc(,%eax,4),%eax
f01034d9:	80 78 04 64          	cmpb   $0x64,0x4(%eax)
f01034dd:	75 da                	jne    f01034b9 <debuginfo_eip+0x15d>
f01034df:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f01034e3:	74 d4                	je     f01034b9 <debuginfo_eip+0x15d>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01034e5:	39 fa                	cmp    %edi,%edx
f01034e7:	7f 1f                	jg     f0103508 <debuginfo_eip+0x1ac>
f01034e9:	6b ff 0c             	imul   $0xc,%edi,%edi
f01034ec:	8b 87 04 58 10 f0    	mov    -0xfefa7fc(%edi),%eax
f01034f2:	ba 81 e0 10 f0       	mov    $0xf010e081,%edx
f01034f7:	81 ea 71 c1 10 f0    	sub    $0xf010c171,%edx
f01034fd:	39 d0                	cmp    %edx,%eax
f01034ff:	73 07                	jae    f0103508 <debuginfo_eip+0x1ac>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103501:	05 71 c1 10 f0       	add    $0xf010c171,%eax
f0103506:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103508:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010350b:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f010350e:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103513:	39 ca                	cmp    %ecx,%edx
f0103515:	7d 3e                	jge    f0103555 <debuginfo_eip+0x1f9>
		for (lline = lfun + 1;
f0103517:	83 c2 01             	add    $0x1,%edx
f010351a:	39 d1                	cmp    %edx,%ecx
f010351c:	7e 37                	jle    f0103555 <debuginfo_eip+0x1f9>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010351e:	6b f2 0c             	imul   $0xc,%edx,%esi
f0103521:	80 be 08 58 10 f0 a0 	cmpb   $0xa0,-0xfefa7f8(%esi)
f0103528:	75 2b                	jne    f0103555 <debuginfo_eip+0x1f9>
		     lline++)
			info->eip_fn_narg++;
f010352a:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f010352e:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103531:	39 d1                	cmp    %edx,%ecx
f0103533:	7e 1b                	jle    f0103550 <debuginfo_eip+0x1f4>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103535:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0103538:	80 3c 85 08 58 10 f0 	cmpb   $0xa0,-0xfefa7f8(,%eax,4)
f010353f:	a0 
f0103540:	74 e8                	je     f010352a <debuginfo_eip+0x1ce>
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0103542:	b8 00 00 00 00       	mov    $0x0,%eax
f0103547:	eb 0c                	jmp    f0103555 <debuginfo_eip+0x1f9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103549:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010354e:	eb 05                	jmp    f0103555 <debuginfo_eip+0x1f9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0103550:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103555:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0103558:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010355b:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010355e:	89 ec                	mov    %ebp,%esp
f0103560:	5d                   	pop    %ebp
f0103561:	c3                   	ret    
	...

f0103570 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103570:	55                   	push   %ebp
f0103571:	89 e5                	mov    %esp,%ebp
f0103573:	57                   	push   %edi
f0103574:	56                   	push   %esi
f0103575:	53                   	push   %ebx
f0103576:	83 ec 3c             	sub    $0x3c,%esp
f0103579:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010357c:	89 d7                	mov    %edx,%edi
f010357e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103581:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103584:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103587:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010358a:	8b 5d 14             	mov    0x14(%ebp),%ebx
f010358d:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103590:	b8 00 00 00 00       	mov    $0x0,%eax
f0103595:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0103598:	72 11                	jb     f01035ab <printnum+0x3b>
f010359a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010359d:	39 45 10             	cmp    %eax,0x10(%ebp)
f01035a0:	76 09                	jbe    f01035ab <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01035a2:	83 eb 01             	sub    $0x1,%ebx
f01035a5:	85 db                	test   %ebx,%ebx
f01035a7:	7f 51                	jg     f01035fa <printnum+0x8a>
f01035a9:	eb 5e                	jmp    f0103609 <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01035ab:	89 74 24 10          	mov    %esi,0x10(%esp)
f01035af:	83 eb 01             	sub    $0x1,%ebx
f01035b2:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01035b6:	8b 45 10             	mov    0x10(%ebp),%eax
f01035b9:	89 44 24 08          	mov    %eax,0x8(%esp)
f01035bd:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f01035c1:	8b 74 24 0c          	mov    0xc(%esp),%esi
f01035c5:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01035cc:	00 
f01035cd:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01035d0:	89 04 24             	mov    %eax,(%esp)
f01035d3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01035d6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01035da:	e8 e1 0a 00 00       	call   f01040c0 <__udivdi3>
f01035df:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01035e3:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01035e7:	89 04 24             	mov    %eax,(%esp)
f01035ea:	89 54 24 04          	mov    %edx,0x4(%esp)
f01035ee:	89 fa                	mov    %edi,%edx
f01035f0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01035f3:	e8 78 ff ff ff       	call   f0103570 <printnum>
f01035f8:	eb 0f                	jmp    f0103609 <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01035fa:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01035fe:	89 34 24             	mov    %esi,(%esp)
f0103601:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103604:	83 eb 01             	sub    $0x1,%ebx
f0103607:	75 f1                	jne    f01035fa <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103609:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010360d:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103611:	8b 45 10             	mov    0x10(%ebp),%eax
f0103614:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103618:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010361f:	00 
f0103620:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103623:	89 04 24             	mov    %eax,(%esp)
f0103626:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103629:	89 44 24 04          	mov    %eax,0x4(%esp)
f010362d:	e8 be 0b 00 00       	call   f01041f0 <__umoddi3>
f0103632:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103636:	0f be 80 f5 55 10 f0 	movsbl -0xfefaa0b(%eax),%eax
f010363d:	89 04 24             	mov    %eax,(%esp)
f0103640:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0103643:	83 c4 3c             	add    $0x3c,%esp
f0103646:	5b                   	pop    %ebx
f0103647:	5e                   	pop    %esi
f0103648:	5f                   	pop    %edi
f0103649:	5d                   	pop    %ebp
f010364a:	c3                   	ret    

f010364b <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f010364b:	55                   	push   %ebp
f010364c:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f010364e:	83 fa 01             	cmp    $0x1,%edx
f0103651:	7e 0e                	jle    f0103661 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103653:	8b 10                	mov    (%eax),%edx
f0103655:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103658:	89 08                	mov    %ecx,(%eax)
f010365a:	8b 02                	mov    (%edx),%eax
f010365c:	8b 52 04             	mov    0x4(%edx),%edx
f010365f:	eb 22                	jmp    f0103683 <getuint+0x38>
	else if (lflag)
f0103661:	85 d2                	test   %edx,%edx
f0103663:	74 10                	je     f0103675 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103665:	8b 10                	mov    (%eax),%edx
f0103667:	8d 4a 04             	lea    0x4(%edx),%ecx
f010366a:	89 08                	mov    %ecx,(%eax)
f010366c:	8b 02                	mov    (%edx),%eax
f010366e:	ba 00 00 00 00       	mov    $0x0,%edx
f0103673:	eb 0e                	jmp    f0103683 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103675:	8b 10                	mov    (%eax),%edx
f0103677:	8d 4a 04             	lea    0x4(%edx),%ecx
f010367a:	89 08                	mov    %ecx,(%eax)
f010367c:	8b 02                	mov    (%edx),%eax
f010367e:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103683:	5d                   	pop    %ebp
f0103684:	c3                   	ret    

f0103685 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103685:	55                   	push   %ebp
f0103686:	89 e5                	mov    %esp,%ebp
f0103688:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010368b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f010368f:	8b 10                	mov    (%eax),%edx
f0103691:	3b 50 04             	cmp    0x4(%eax),%edx
f0103694:	73 0a                	jae    f01036a0 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103696:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103699:	88 0a                	mov    %cl,(%edx)
f010369b:	83 c2 01             	add    $0x1,%edx
f010369e:	89 10                	mov    %edx,(%eax)
}
f01036a0:	5d                   	pop    %ebp
f01036a1:	c3                   	ret    

f01036a2 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01036a2:	55                   	push   %ebp
f01036a3:	89 e5                	mov    %esp,%ebp
f01036a5:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f01036a8:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01036ab:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01036af:	8b 45 10             	mov    0x10(%ebp),%eax
f01036b2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01036b6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01036b9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036bd:	8b 45 08             	mov    0x8(%ebp),%eax
f01036c0:	89 04 24             	mov    %eax,(%esp)
f01036c3:	e8 02 00 00 00       	call   f01036ca <vprintfmt>
	va_end(ap);
}
f01036c8:	c9                   	leave  
f01036c9:	c3                   	ret    

f01036ca <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01036ca:	55                   	push   %ebp
f01036cb:	89 e5                	mov    %esp,%ebp
f01036cd:	57                   	push   %edi
f01036ce:	56                   	push   %esi
f01036cf:	53                   	push   %ebx
f01036d0:	83 ec 3c             	sub    $0x3c,%esp
f01036d3:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01036d6:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f01036d9:	e9 bb 00 00 00       	jmp    f0103799 <vprintfmt+0xcf>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01036de:	85 c0                	test   %eax,%eax
f01036e0:	0f 84 63 04 00 00    	je     f0103b49 <vprintfmt+0x47f>
				return;
			if (ch =='\033'){//if this is Escape character  and this if is char color set.
f01036e6:	83 f8 1b             	cmp    $0x1b,%eax
f01036e9:	0f 85 9a 00 00 00    	jne    f0103789 <vprintfmt+0xbf>
				int temp_color_no=0;
				ch = *(unsigned char *) fmt++;
f01036ef:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01036f2:	83 c3 02             	add    $0x2,%ebx
				while (ch != 'm') 
f01036f5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01036f8:	80 78 01 6d          	cmpb   $0x6d,0x1(%eax)
f01036fc:	0f 84 81 00 00 00    	je     f0103783 <vprintfmt+0xb9>
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
				return;
			if (ch =='\033'){//if this is Escape character  and this if is char color set.
				int temp_color_no=0;
f0103702:	ba 00 00 00 00       	mov    $0x0,%edx
				ch = *(unsigned char *) fmt++;
				while (ch != 'm') 
				{
					ch = *(unsigned char *) fmt++;
f0103707:	0f b6 03             	movzbl (%ebx),%eax
f010370a:	83 c3 01             	add    $0x1,%ebx
					if ( ch !=';' && ch!='m')
f010370d:	83 f8 6d             	cmp    $0x6d,%eax
f0103710:	0f 95 c1             	setne  %cl
f0103713:	83 f8 3b             	cmp    $0x3b,%eax
f0103716:	74 0d                	je     f0103725 <vprintfmt+0x5b>
f0103718:	84 c9                	test   %cl,%cl
f010371a:	74 09                	je     f0103725 <vprintfmt+0x5b>
						temp_color_no=temp_color_no*10+ch-'0';
f010371c:	8d 14 92             	lea    (%edx,%edx,4),%edx
f010371f:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
f0103723:	eb 55                	jmp    f010377a <vprintfmt+0xb0>
					else if ( ch==';' || ch=='m'){
f0103725:	83 f8 3b             	cmp    $0x3b,%eax
f0103728:	74 05                	je     f010372f <vprintfmt+0x65>
f010372a:	83 f8 6d             	cmp    $0x6d,%eax
f010372d:	75 4b                	jne    f010377a <vprintfmt+0xb0>
						if ( temp_color_no >=30 && temp_color_no<40){// Foreground colors
f010372f:	89 d6                	mov    %edx,%esi
f0103731:	8d 7a e2             	lea    -0x1e(%edx),%edi
f0103734:	83 ff 09             	cmp    $0x9,%edi
f0103737:	77 16                	ja     f010374f <vprintfmt+0x85>
							char_color = (char_color&0xf0) + (temp_color_no-30);						
f0103739:	8b 3d 00 93 11 f0    	mov    0xf0119300,%edi
f010373f:	81 e7 f0 00 00 00    	and    $0xf0,%edi
f0103745:	8d 7c 3a e2          	lea    -0x1e(%edx,%edi,1),%edi
f0103749:	89 3d 00 93 11 f0    	mov    %edi,0xf0119300
							}
						if ( temp_color_no >=40 && temp_color_no<50){// Background colors
f010374f:	83 ee 28             	sub    $0x28,%esi
f0103752:	83 fe 09             	cmp    $0x9,%esi
f0103755:	77 1e                	ja     f0103775 <vprintfmt+0xab>
							char_color = (char_color&0x0f) + ((temp_color_no-40)<<4);
f0103757:	8b 35 00 93 11 f0    	mov    0xf0119300,%esi
f010375d:	83 e6 0f             	and    $0xf,%esi
f0103760:	83 ea 28             	sub    $0x28,%edx
f0103763:	c1 e2 04             	shl    $0x4,%edx
f0103766:	01 f2                	add    %esi,%edx
f0103768:	89 15 00 93 11 f0    	mov    %edx,0xf0119300
						}
						//cprintf("0x%o ,",char_color);
						temp_color_no=0;
f010376e:	ba 00 00 00 00       	mov    $0x0,%edx
f0103773:	eb 05                	jmp    f010377a <vprintfmt+0xb0>
f0103775:	ba 00 00 00 00       	mov    $0x0,%edx
			if (ch == '\0')
				return;
			if (ch =='\033'){//if this is Escape character  and this if is char color set.
				int temp_color_no=0;
				ch = *(unsigned char *) fmt++;
				while (ch != 'm') 
f010377a:	84 c9                	test   %cl,%cl
f010377c:	75 89                	jne    f0103707 <vprintfmt+0x3d>
						}
						//cprintf("0x%o ,",char_color);
						temp_color_no=0;
					}
				}
				if (ch == 'm')
f010377e:	83 f8 6d             	cmp    $0x6d,%eax
f0103781:	75 06                	jne    f0103789 <vprintfmt+0xbf>
					ch = *(unsigned char *) fmt++;
f0103783:	0f b6 03             	movzbl (%ebx),%eax
f0103786:	83 c3 01             	add    $0x1,%ebx
				
			}
			putch(ch, putdat);
f0103789:	8b 55 0c             	mov    0xc(%ebp),%edx
f010378c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103790:	89 04 24             	mov    %eax,(%esp)
f0103793:	ff 55 08             	call   *0x8(%ebp)
f0103796:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103799:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010379c:	0f b6 03             	movzbl (%ebx),%eax
f010379f:	83 c3 01             	add    $0x1,%ebx
f01037a2:	83 f8 25             	cmp    $0x25,%eax
f01037a5:	0f 85 33 ff ff ff    	jne    f01036de <vprintfmt+0x14>
f01037ab:	c6 45 e0 20          	movb   $0x20,-0x20(%ebp)
f01037af:	bf 00 00 00 00       	mov    $0x0,%edi
f01037b4:	be ff ff ff ff       	mov    $0xffffffff,%esi
f01037b9:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f01037c0:	b9 00 00 00 00       	mov    $0x0,%ecx
f01037c5:	eb 23                	jmp    f01037ea <vprintfmt+0x120>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01037c7:	89 c3                	mov    %eax,%ebx

		// flag to pad on the right
		case '-':
			padc = '-';
f01037c9:	c6 45 e0 2d          	movb   $0x2d,-0x20(%ebp)
f01037cd:	eb 1b                	jmp    f01037ea <vprintfmt+0x120>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01037cf:	89 c3                	mov    %eax,%ebx
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01037d1:	c6 45 e0 30          	movb   $0x30,-0x20(%ebp)
f01037d5:	eb 13                	jmp    f01037ea <vprintfmt+0x120>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01037d7:	89 c3                	mov    %eax,%ebx
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f01037d9:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f01037e0:	eb 08                	jmp    f01037ea <vprintfmt+0x120>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f01037e2:	89 75 dc             	mov    %esi,-0x24(%ebp)
f01037e5:	be ff ff ff ff       	mov    $0xffffffff,%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01037ea:	0f b6 13             	movzbl (%ebx),%edx
f01037ed:	0f b6 c2             	movzbl %dl,%eax
f01037f0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01037f3:	8d 43 01             	lea    0x1(%ebx),%eax
f01037f6:	83 ea 23             	sub    $0x23,%edx
f01037f9:	80 fa 55             	cmp    $0x55,%dl
f01037fc:	0f 87 18 03 00 00    	ja     f0103b1a <vprintfmt+0x450>
f0103802:	0f b6 d2             	movzbl %dl,%edx
f0103805:	ff 24 95 80 56 10 f0 	jmp    *-0xfefa980(,%edx,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f010380c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010380f:	83 ee 30             	sub    $0x30,%esi
				ch = *fmt;
f0103812:	0f be 53 01          	movsbl 0x1(%ebx),%edx
				if (ch < '0' || ch > '9')
f0103816:	8d 5a d0             	lea    -0x30(%edx),%ebx
f0103819:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010381c:	89 c3                	mov    %eax,%ebx
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f010381e:	83 7d e4 09          	cmpl   $0x9,-0x1c(%ebp)
f0103822:	77 3b                	ja     f010385f <vprintfmt+0x195>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103824:	83 c0 01             	add    $0x1,%eax
				precision = precision * 10 + ch - '0';
f0103827:	8d 1c b6             	lea    (%esi,%esi,4),%ebx
f010382a:	8d 74 5a d0          	lea    -0x30(%edx,%ebx,2),%esi
				ch = *fmt;
f010382e:	0f be 10             	movsbl (%eax),%edx
				if (ch < '0' || ch > '9')
f0103831:	8d 5a d0             	lea    -0x30(%edx),%ebx
f0103834:	83 fb 09             	cmp    $0x9,%ebx
f0103837:	76 eb                	jbe    f0103824 <vprintfmt+0x15a>
f0103839:	eb 22                	jmp    f010385d <vprintfmt+0x193>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f010383b:	8b 55 14             	mov    0x14(%ebp),%edx
f010383e:	8d 5a 04             	lea    0x4(%edx),%ebx
f0103841:	89 5d 14             	mov    %ebx,0x14(%ebp)
f0103844:	8b 32                	mov    (%edx),%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103846:	89 c3                	mov    %eax,%ebx
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103848:	eb 15                	jmp    f010385f <vprintfmt+0x195>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010384a:	89 c3                	mov    %eax,%ebx
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f010384c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103850:	79 98                	jns    f01037ea <vprintfmt+0x120>
f0103852:	eb 83                	jmp    f01037d7 <vprintfmt+0x10d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103854:	89 c3                	mov    %eax,%ebx
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103856:	bf 01 00 00 00       	mov    $0x1,%edi
			goto reswitch;
f010385b:	eb 8d                	jmp    f01037ea <vprintfmt+0x120>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f010385d:	89 c3                	mov    %eax,%ebx
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f010385f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103863:	79 85                	jns    f01037ea <vprintfmt+0x120>
f0103865:	e9 78 ff ff ff       	jmp    f01037e2 <vprintfmt+0x118>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f010386a:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010386d:	89 c3                	mov    %eax,%ebx
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010386f:	e9 76 ff ff ff       	jmp    f01037ea <vprintfmt+0x120>
f0103874:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103877:	8b 45 14             	mov    0x14(%ebp),%eax
f010387a:	8d 50 04             	lea    0x4(%eax),%edx
f010387d:	89 55 14             	mov    %edx,0x14(%ebp)
f0103880:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103883:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103887:	8b 00                	mov    (%eax),%eax
f0103889:	89 04 24             	mov    %eax,(%esp)
f010388c:	ff 55 08             	call   *0x8(%ebp)
			break;
f010388f:	e9 05 ff ff ff       	jmp    f0103799 <vprintfmt+0xcf>
f0103894:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103897:	8b 45 14             	mov    0x14(%ebp),%eax
f010389a:	8d 50 04             	lea    0x4(%eax),%edx
f010389d:	89 55 14             	mov    %edx,0x14(%ebp)
f01038a0:	8b 00                	mov    (%eax),%eax
f01038a2:	89 c2                	mov    %eax,%edx
f01038a4:	c1 fa 1f             	sar    $0x1f,%edx
f01038a7:	31 d0                	xor    %edx,%eax
f01038a9:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01038ab:	83 f8 06             	cmp    $0x6,%eax
f01038ae:	7f 0b                	jg     f01038bb <vprintfmt+0x1f1>
f01038b0:	8b 14 85 d8 57 10 f0 	mov    -0xfefa828(,%eax,4),%edx
f01038b7:	85 d2                	test   %edx,%edx
f01038b9:	75 23                	jne    f01038de <vprintfmt+0x214>
				printfmt(putch, putdat, "error %d", err);
f01038bb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01038bf:	c7 44 24 08 0d 56 10 	movl   $0xf010560d,0x8(%esp)
f01038c6:	f0 
f01038c7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01038ca:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01038ce:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01038d1:	89 1c 24             	mov    %ebx,(%esp)
f01038d4:	e8 c9 fd ff ff       	call   f01036a2 <printfmt>
f01038d9:	e9 bb fe ff ff       	jmp    f0103799 <vprintfmt+0xcf>
			else
				printfmt(putch, putdat, "%s", p);
f01038de:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01038e2:	c7 44 24 08 50 53 10 	movl   $0xf0105350,0x8(%esp)
f01038e9:	f0 
f01038ea:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01038ed:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01038f1:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01038f4:	89 1c 24             	mov    %ebx,(%esp)
f01038f7:	e8 a6 fd ff ff       	call   f01036a2 <printfmt>
f01038fc:	e9 98 fe ff ff       	jmp    f0103799 <vprintfmt+0xcf>
f0103901:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103904:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103907:	89 5d d8             	mov    %ebx,-0x28(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010390a:	8b 45 14             	mov    0x14(%ebp),%eax
f010390d:	8d 50 04             	lea    0x4(%eax),%edx
f0103910:	89 55 14             	mov    %edx,0x14(%ebp)
f0103913:	8b 18                	mov    (%eax),%ebx
				p = "(null)";
f0103915:	85 db                	test   %ebx,%ebx
f0103917:	b8 06 56 10 f0       	mov    $0xf0105606,%eax
f010391c:	0f 44 d8             	cmove  %eax,%ebx
			if (width > 0 && padc != '-')
f010391f:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103923:	7e 06                	jle    f010392b <vprintfmt+0x261>
f0103925:	80 7d e0 2d          	cmpb   $0x2d,-0x20(%ebp)
f0103929:	75 10                	jne    f010393b <vprintfmt+0x271>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010392b:	0f be 03             	movsbl (%ebx),%eax
f010392e:	83 c3 01             	add    $0x1,%ebx
f0103931:	85 c0                	test   %eax,%eax
f0103933:	0f 85 82 00 00 00    	jne    f01039bb <vprintfmt+0x2f1>
f0103939:	eb 75                	jmp    f01039b0 <vprintfmt+0x2e6>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010393b:	89 74 24 04          	mov    %esi,0x4(%esp)
f010393f:	89 1c 24             	mov    %ebx,(%esp)
f0103942:	e8 84 03 00 00       	call   f0103ccb <strnlen>
f0103947:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010394a:	29 c2                	sub    %eax,%edx
f010394c:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010394f:	85 d2                	test   %edx,%edx
f0103951:	7e d8                	jle    f010392b <vprintfmt+0x261>
					putch(padc, putdat);
f0103953:	0f be 45 e0          	movsbl -0x20(%ebp),%eax
f0103957:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010395a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010395d:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103961:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103964:	89 04 24             	mov    %eax,(%esp)
f0103967:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010396a:	83 6d dc 01          	subl   $0x1,-0x24(%ebp)
f010396e:	75 ea                	jne    f010395a <vprintfmt+0x290>
f0103970:	eb b9                	jmp    f010392b <vprintfmt+0x261>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103972:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103976:	74 1b                	je     f0103993 <vprintfmt+0x2c9>
f0103978:	8d 50 e0             	lea    -0x20(%eax),%edx
f010397b:	83 fa 5e             	cmp    $0x5e,%edx
f010397e:	76 13                	jbe    f0103993 <vprintfmt+0x2c9>
					putch('?', putdat);
f0103980:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103983:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103987:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f010398e:	ff 55 08             	call   *0x8(%ebp)
f0103991:	eb 0d                	jmp    f01039a0 <vprintfmt+0x2d6>
				else
					putch(ch, putdat);
f0103993:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103996:	89 54 24 04          	mov    %edx,0x4(%esp)
f010399a:	89 04 24             	mov    %eax,(%esp)
f010399d:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01039a0:	83 ef 01             	sub    $0x1,%edi
f01039a3:	0f be 03             	movsbl (%ebx),%eax
f01039a6:	83 c3 01             	add    $0x1,%ebx
f01039a9:	85 c0                	test   %eax,%eax
f01039ab:	75 14                	jne    f01039c1 <vprintfmt+0x2f7>
f01039ad:	89 7d dc             	mov    %edi,-0x24(%ebp)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01039b0:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01039b4:	7f 19                	jg     f01039cf <vprintfmt+0x305>
f01039b6:	e9 de fd ff ff       	jmp    f0103799 <vprintfmt+0xcf>
f01039bb:	89 7d e0             	mov    %edi,-0x20(%ebp)
f01039be:	8b 7d dc             	mov    -0x24(%ebp),%edi
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01039c1:	85 f6                	test   %esi,%esi
f01039c3:	78 ad                	js     f0103972 <vprintfmt+0x2a8>
f01039c5:	83 ee 01             	sub    $0x1,%esi
f01039c8:	79 a8                	jns    f0103972 <vprintfmt+0x2a8>
f01039ca:	89 7d dc             	mov    %edi,-0x24(%ebp)
f01039cd:	eb e1                	jmp    f01039b0 <vprintfmt+0x2e6>
f01039cf:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01039d2:	8b 7d 08             	mov    0x8(%ebp),%edi
f01039d5:	8b 75 0c             	mov    0xc(%ebp),%esi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01039d8:	89 74 24 04          	mov    %esi,0x4(%esp)
f01039dc:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01039e3:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01039e5:	83 eb 01             	sub    $0x1,%ebx
f01039e8:	75 ee                	jne    f01039d8 <vprintfmt+0x30e>
f01039ea:	e9 aa fd ff ff       	jmp    f0103799 <vprintfmt+0xcf>
f01039ef:	89 45 e4             	mov    %eax,-0x1c(%ebp)
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01039f2:	83 f9 01             	cmp    $0x1,%ecx
f01039f5:	7e 10                	jle    f0103a07 <vprintfmt+0x33d>
		return va_arg(*ap, long long);
f01039f7:	8b 45 14             	mov    0x14(%ebp),%eax
f01039fa:	8d 50 08             	lea    0x8(%eax),%edx
f01039fd:	89 55 14             	mov    %edx,0x14(%ebp)
f0103a00:	8b 30                	mov    (%eax),%esi
f0103a02:	8b 78 04             	mov    0x4(%eax),%edi
f0103a05:	eb 26                	jmp    f0103a2d <vprintfmt+0x363>
	else if (lflag)
f0103a07:	85 c9                	test   %ecx,%ecx
f0103a09:	74 12                	je     f0103a1d <vprintfmt+0x353>
		return va_arg(*ap, long);
f0103a0b:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a0e:	8d 50 04             	lea    0x4(%eax),%edx
f0103a11:	89 55 14             	mov    %edx,0x14(%ebp)
f0103a14:	8b 30                	mov    (%eax),%esi
f0103a16:	89 f7                	mov    %esi,%edi
f0103a18:	c1 ff 1f             	sar    $0x1f,%edi
f0103a1b:	eb 10                	jmp    f0103a2d <vprintfmt+0x363>
	else
		return va_arg(*ap, int);
f0103a1d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a20:	8d 50 04             	lea    0x4(%eax),%edx
f0103a23:	89 55 14             	mov    %edx,0x14(%ebp)
f0103a26:	8b 30                	mov    (%eax),%esi
f0103a28:	89 f7                	mov    %esi,%edi
f0103a2a:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103a2d:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103a32:	85 ff                	test   %edi,%edi
f0103a34:	0f 89 9e 00 00 00    	jns    f0103ad8 <vprintfmt+0x40e>
				putch('-', putdat);
f0103a3a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103a3d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103a41:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0103a48:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0103a4b:	f7 de                	neg    %esi
f0103a4d:	83 d7 00             	adc    $0x0,%edi
f0103a50:	f7 df                	neg    %edi
			}
			base = 10;
f0103a52:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103a57:	eb 7f                	jmp    f0103ad8 <vprintfmt+0x40e>
f0103a59:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103a5c:	89 ca                	mov    %ecx,%edx
f0103a5e:	8d 45 14             	lea    0x14(%ebp),%eax
f0103a61:	e8 e5 fb ff ff       	call   f010364b <getuint>
f0103a66:	89 c6                	mov    %eax,%esi
f0103a68:	89 d7                	mov    %edx,%edi
			base = 10;
f0103a6a:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f0103a6f:	eb 67                	jmp    f0103ad8 <vprintfmt+0x40e>
f0103a71:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap,lflag);
f0103a74:	89 ca                	mov    %ecx,%edx
f0103a76:	8d 45 14             	lea    0x14(%ebp),%eax
f0103a79:	e8 cd fb ff ff       	call   f010364b <getuint>
f0103a7e:	89 c6                	mov    %eax,%esi
f0103a80:	89 d7                	mov    %edx,%edi
			base = 8;
f0103a82:	b8 08 00 00 00       	mov    $0x8,%eax

			goto number;
f0103a87:	eb 4f                	jmp    f0103ad8 <vprintfmt+0x40e>
f0103a89:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// pointer
		case 'p':
			putch('0', putdat);
f0103a8c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103a8f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103a93:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0103a9a:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0103a9d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103aa1:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0103aa8:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103aab:	8b 45 14             	mov    0x14(%ebp),%eax
f0103aae:	8d 50 04             	lea    0x4(%eax),%edx
f0103ab1:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103ab4:	8b 30                	mov    (%eax),%esi
f0103ab6:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0103abb:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0103ac0:	eb 16                	jmp    f0103ad8 <vprintfmt+0x40e>
f0103ac2:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103ac5:	89 ca                	mov    %ecx,%edx
f0103ac7:	8d 45 14             	lea    0x14(%ebp),%eax
f0103aca:	e8 7c fb ff ff       	call   f010364b <getuint>
f0103acf:	89 c6                	mov    %eax,%esi
f0103ad1:	89 d7                	mov    %edx,%edi
			base = 16;
f0103ad3:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103ad8:	0f be 55 e0          	movsbl -0x20(%ebp),%edx
f0103adc:	89 54 24 10          	mov    %edx,0x10(%esp)
f0103ae0:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103ae3:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103ae7:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103aeb:	89 34 24             	mov    %esi,(%esp)
f0103aee:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103af2:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103af5:	8b 45 08             	mov    0x8(%ebp),%eax
f0103af8:	e8 73 fa ff ff       	call   f0103570 <printnum>
			break;
f0103afd:	e9 97 fc ff ff       	jmp    f0103799 <vprintfmt+0xcf>
f0103b02:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103b05:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103b08:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103b0b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103b0f:	89 14 24             	mov    %edx,(%esp)
f0103b12:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103b15:	e9 7f fc ff ff       	jmp    f0103799 <vprintfmt+0xcf>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103b1a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103b1d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b21:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0103b28:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103b2b:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103b2e:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0103b32:	0f 84 61 fc ff ff    	je     f0103799 <vprintfmt+0xcf>
f0103b38:	83 eb 01             	sub    $0x1,%ebx
f0103b3b:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0103b3f:	75 f7                	jne    f0103b38 <vprintfmt+0x46e>
f0103b41:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103b44:	e9 50 fc ff ff       	jmp    f0103799 <vprintfmt+0xcf>
				/* do nothing */;
			break;
		}
	}
}
f0103b49:	83 c4 3c             	add    $0x3c,%esp
f0103b4c:	5b                   	pop    %ebx
f0103b4d:	5e                   	pop    %esi
f0103b4e:	5f                   	pop    %edi
f0103b4f:	5d                   	pop    %ebp
f0103b50:	c3                   	ret    

f0103b51 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103b51:	55                   	push   %ebp
f0103b52:	89 e5                	mov    %esp,%ebp
f0103b54:	83 ec 28             	sub    $0x28,%esp
f0103b57:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b5a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103b5d:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103b60:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103b64:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103b67:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103b6e:	85 c0                	test   %eax,%eax
f0103b70:	74 30                	je     f0103ba2 <vsnprintf+0x51>
f0103b72:	85 d2                	test   %edx,%edx
f0103b74:	7e 2c                	jle    f0103ba2 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103b76:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b79:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103b7d:	8b 45 10             	mov    0x10(%ebp),%eax
f0103b80:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103b84:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103b87:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b8b:	c7 04 24 85 36 10 f0 	movl   $0xf0103685,(%esp)
f0103b92:	e8 33 fb ff ff       	call   f01036ca <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103b97:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103b9a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103b9d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103ba0:	eb 05                	jmp    f0103ba7 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103ba2:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103ba7:	c9                   	leave  
f0103ba8:	c3                   	ret    

f0103ba9 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103ba9:	55                   	push   %ebp
f0103baa:	89 e5                	mov    %esp,%ebp
f0103bac:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103baf:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103bb2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103bb6:	8b 45 10             	mov    0x10(%ebp),%eax
f0103bb9:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103bbd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103bc0:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103bc4:	8b 45 08             	mov    0x8(%ebp),%eax
f0103bc7:	89 04 24             	mov    %eax,(%esp)
f0103bca:	e8 82 ff ff ff       	call   f0103b51 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103bcf:	c9                   	leave  
f0103bd0:	c3                   	ret    
	...

f0103be0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103be0:	55                   	push   %ebp
f0103be1:	89 e5                	mov    %esp,%ebp
f0103be3:	57                   	push   %edi
f0103be4:	56                   	push   %esi
f0103be5:	53                   	push   %ebx
f0103be6:	83 ec 1c             	sub    $0x1c,%esp
f0103be9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103bec:	85 c0                	test   %eax,%eax
f0103bee:	74 10                	je     f0103c00 <readline+0x20>
		cprintf("%s", prompt);
f0103bf0:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103bf4:	c7 04 24 50 53 10 f0 	movl   $0xf0105350,(%esp)
f0103bfb:	e8 62 f6 ff ff       	call   f0103262 <cprintf>

	i = 0;
	echoing = iscons(0);
f0103c00:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103c07:	e8 06 ca ff ff       	call   f0100612 <iscons>
f0103c0c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103c0e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103c13:	e8 e9 c9 ff ff       	call   f0100601 <getchar>
f0103c18:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0103c1a:	85 c0                	test   %eax,%eax
f0103c1c:	79 17                	jns    f0103c35 <readline+0x55>
			cprintf("read error: %e\n", c);
f0103c1e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c22:	c7 04 24 f4 57 10 f0 	movl   $0xf01057f4,(%esp)
f0103c29:	e8 34 f6 ff ff       	call   f0103262 <cprintf>
			return NULL;
f0103c2e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103c33:	eb 6d                	jmp    f0103ca2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103c35:	83 f8 08             	cmp    $0x8,%eax
f0103c38:	74 05                	je     f0103c3f <readline+0x5f>
f0103c3a:	83 f8 7f             	cmp    $0x7f,%eax
f0103c3d:	75 19                	jne    f0103c58 <readline+0x78>
f0103c3f:	85 f6                	test   %esi,%esi
f0103c41:	7e 15                	jle    f0103c58 <readline+0x78>
			if (echoing)
f0103c43:	85 ff                	test   %edi,%edi
f0103c45:	74 0c                	je     f0103c53 <readline+0x73>
				cputchar('\b');
f0103c47:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f0103c4e:	e8 9e c9 ff ff       	call   f01005f1 <cputchar>
			i--;
f0103c53:	83 ee 01             	sub    $0x1,%esi
f0103c56:	eb bb                	jmp    f0103c13 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103c58:	83 fb 1f             	cmp    $0x1f,%ebx
f0103c5b:	7e 1f                	jle    f0103c7c <readline+0x9c>
f0103c5d:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103c63:	7f 17                	jg     f0103c7c <readline+0x9c>
			if (echoing)
f0103c65:	85 ff                	test   %edi,%edi
f0103c67:	74 08                	je     f0103c71 <readline+0x91>
				cputchar(c);
f0103c69:	89 1c 24             	mov    %ebx,(%esp)
f0103c6c:	e8 80 c9 ff ff       	call   f01005f1 <cputchar>
			buf[i++] = c;
f0103c71:	88 9e a0 95 11 f0    	mov    %bl,-0xfee6a60(%esi)
f0103c77:	83 c6 01             	add    $0x1,%esi
f0103c7a:	eb 97                	jmp    f0103c13 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0103c7c:	83 fb 0a             	cmp    $0xa,%ebx
f0103c7f:	74 05                	je     f0103c86 <readline+0xa6>
f0103c81:	83 fb 0d             	cmp    $0xd,%ebx
f0103c84:	75 8d                	jne    f0103c13 <readline+0x33>
			if (echoing)
f0103c86:	85 ff                	test   %edi,%edi
f0103c88:	74 0c                	je     f0103c96 <readline+0xb6>
				cputchar('\n');
f0103c8a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0103c91:	e8 5b c9 ff ff       	call   f01005f1 <cputchar>
			buf[i] = 0;
f0103c96:	c6 86 a0 95 11 f0 00 	movb   $0x0,-0xfee6a60(%esi)
			return buf;
f0103c9d:	b8 a0 95 11 f0       	mov    $0xf01195a0,%eax
		}
	}
}
f0103ca2:	83 c4 1c             	add    $0x1c,%esp
f0103ca5:	5b                   	pop    %ebx
f0103ca6:	5e                   	pop    %esi
f0103ca7:	5f                   	pop    %edi
f0103ca8:	5d                   	pop    %ebp
f0103ca9:	c3                   	ret    
f0103caa:	00 00                	add    %al,(%eax)
f0103cac:	00 00                	add    %al,(%eax)
	...

f0103cb0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103cb0:	55                   	push   %ebp
f0103cb1:	89 e5                	mov    %esp,%ebp
f0103cb3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103cb6:	b8 00 00 00 00       	mov    $0x0,%eax
f0103cbb:	80 3a 00             	cmpb   $0x0,(%edx)
f0103cbe:	74 09                	je     f0103cc9 <strlen+0x19>
		n++;
f0103cc0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103cc3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103cc7:	75 f7                	jne    f0103cc0 <strlen+0x10>
		n++;
	return n;
}
f0103cc9:	5d                   	pop    %ebp
f0103cca:	c3                   	ret    

f0103ccb <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103ccb:	55                   	push   %ebp
f0103ccc:	89 e5                	mov    %esp,%ebp
f0103cce:	53                   	push   %ebx
f0103ccf:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103cd2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103cd5:	b8 00 00 00 00       	mov    $0x0,%eax
f0103cda:	85 c9                	test   %ecx,%ecx
f0103cdc:	74 1a                	je     f0103cf8 <strnlen+0x2d>
f0103cde:	80 3b 00             	cmpb   $0x0,(%ebx)
f0103ce1:	74 15                	je     f0103cf8 <strnlen+0x2d>
f0103ce3:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f0103ce8:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103cea:	39 ca                	cmp    %ecx,%edx
f0103cec:	74 0a                	je     f0103cf8 <strnlen+0x2d>
f0103cee:	83 c2 01             	add    $0x1,%edx
f0103cf1:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0103cf6:	75 f0                	jne    f0103ce8 <strnlen+0x1d>
		n++;
	return n;
}
f0103cf8:	5b                   	pop    %ebx
f0103cf9:	5d                   	pop    %ebp
f0103cfa:	c3                   	ret    

f0103cfb <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103cfb:	55                   	push   %ebp
f0103cfc:	89 e5                	mov    %esp,%ebp
f0103cfe:	53                   	push   %ebx
f0103cff:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d02:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103d05:	ba 00 00 00 00       	mov    $0x0,%edx
f0103d0a:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0103d0e:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0103d11:	83 c2 01             	add    $0x1,%edx
f0103d14:	84 c9                	test   %cl,%cl
f0103d16:	75 f2                	jne    f0103d0a <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0103d18:	5b                   	pop    %ebx
f0103d19:	5d                   	pop    %ebp
f0103d1a:	c3                   	ret    

f0103d1b <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103d1b:	55                   	push   %ebp
f0103d1c:	89 e5                	mov    %esp,%ebp
f0103d1e:	56                   	push   %esi
f0103d1f:	53                   	push   %ebx
f0103d20:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d23:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103d26:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103d29:	85 f6                	test   %esi,%esi
f0103d2b:	74 18                	je     f0103d45 <strncpy+0x2a>
f0103d2d:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f0103d32:	0f b6 1a             	movzbl (%edx),%ebx
f0103d35:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103d38:	80 3a 01             	cmpb   $0x1,(%edx)
f0103d3b:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103d3e:	83 c1 01             	add    $0x1,%ecx
f0103d41:	39 f1                	cmp    %esi,%ecx
f0103d43:	75 ed                	jne    f0103d32 <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103d45:	5b                   	pop    %ebx
f0103d46:	5e                   	pop    %esi
f0103d47:	5d                   	pop    %ebp
f0103d48:	c3                   	ret    

f0103d49 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103d49:	55                   	push   %ebp
f0103d4a:	89 e5                	mov    %esp,%ebp
f0103d4c:	57                   	push   %edi
f0103d4d:	56                   	push   %esi
f0103d4e:	53                   	push   %ebx
f0103d4f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103d52:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103d55:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103d58:	89 f8                	mov    %edi,%eax
f0103d5a:	85 f6                	test   %esi,%esi
f0103d5c:	74 2b                	je     f0103d89 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f0103d5e:	83 fe 01             	cmp    $0x1,%esi
f0103d61:	74 23                	je     f0103d86 <strlcpy+0x3d>
f0103d63:	0f b6 0b             	movzbl (%ebx),%ecx
f0103d66:	84 c9                	test   %cl,%cl
f0103d68:	74 1c                	je     f0103d86 <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f0103d6a:	83 ee 02             	sub    $0x2,%esi
f0103d6d:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103d72:	88 08                	mov    %cl,(%eax)
f0103d74:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103d77:	39 f2                	cmp    %esi,%edx
f0103d79:	74 0b                	je     f0103d86 <strlcpy+0x3d>
f0103d7b:	83 c2 01             	add    $0x1,%edx
f0103d7e:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0103d82:	84 c9                	test   %cl,%cl
f0103d84:	75 ec                	jne    f0103d72 <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f0103d86:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103d89:	29 f8                	sub    %edi,%eax
}
f0103d8b:	5b                   	pop    %ebx
f0103d8c:	5e                   	pop    %esi
f0103d8d:	5f                   	pop    %edi
f0103d8e:	5d                   	pop    %ebp
f0103d8f:	c3                   	ret    

f0103d90 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103d90:	55                   	push   %ebp
f0103d91:	89 e5                	mov    %esp,%ebp
f0103d93:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103d96:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103d99:	0f b6 01             	movzbl (%ecx),%eax
f0103d9c:	84 c0                	test   %al,%al
f0103d9e:	74 16                	je     f0103db6 <strcmp+0x26>
f0103da0:	3a 02                	cmp    (%edx),%al
f0103da2:	75 12                	jne    f0103db6 <strcmp+0x26>
		p++, q++;
f0103da4:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103da7:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f0103dab:	84 c0                	test   %al,%al
f0103dad:	74 07                	je     f0103db6 <strcmp+0x26>
f0103daf:	83 c1 01             	add    $0x1,%ecx
f0103db2:	3a 02                	cmp    (%edx),%al
f0103db4:	74 ee                	je     f0103da4 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103db6:	0f b6 c0             	movzbl %al,%eax
f0103db9:	0f b6 12             	movzbl (%edx),%edx
f0103dbc:	29 d0                	sub    %edx,%eax
}
f0103dbe:	5d                   	pop    %ebp
f0103dbf:	c3                   	ret    

f0103dc0 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103dc0:	55                   	push   %ebp
f0103dc1:	89 e5                	mov    %esp,%ebp
f0103dc3:	53                   	push   %ebx
f0103dc4:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103dc7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103dca:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103dcd:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103dd2:	85 d2                	test   %edx,%edx
f0103dd4:	74 28                	je     f0103dfe <strncmp+0x3e>
f0103dd6:	0f b6 01             	movzbl (%ecx),%eax
f0103dd9:	84 c0                	test   %al,%al
f0103ddb:	74 24                	je     f0103e01 <strncmp+0x41>
f0103ddd:	3a 03                	cmp    (%ebx),%al
f0103ddf:	75 20                	jne    f0103e01 <strncmp+0x41>
f0103de1:	83 ea 01             	sub    $0x1,%edx
f0103de4:	74 13                	je     f0103df9 <strncmp+0x39>
		n--, p++, q++;
f0103de6:	83 c1 01             	add    $0x1,%ecx
f0103de9:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103dec:	0f b6 01             	movzbl (%ecx),%eax
f0103def:	84 c0                	test   %al,%al
f0103df1:	74 0e                	je     f0103e01 <strncmp+0x41>
f0103df3:	3a 03                	cmp    (%ebx),%al
f0103df5:	74 ea                	je     f0103de1 <strncmp+0x21>
f0103df7:	eb 08                	jmp    f0103e01 <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103df9:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103dfe:	5b                   	pop    %ebx
f0103dff:	5d                   	pop    %ebp
f0103e00:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103e01:	0f b6 01             	movzbl (%ecx),%eax
f0103e04:	0f b6 13             	movzbl (%ebx),%edx
f0103e07:	29 d0                	sub    %edx,%eax
f0103e09:	eb f3                	jmp    f0103dfe <strncmp+0x3e>

f0103e0b <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103e0b:	55                   	push   %ebp
f0103e0c:	89 e5                	mov    %esp,%ebp
f0103e0e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e11:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103e15:	0f b6 10             	movzbl (%eax),%edx
f0103e18:	84 d2                	test   %dl,%dl
f0103e1a:	74 1c                	je     f0103e38 <strchr+0x2d>
		if (*s == c)
f0103e1c:	38 ca                	cmp    %cl,%dl
f0103e1e:	75 09                	jne    f0103e29 <strchr+0x1e>
f0103e20:	eb 1b                	jmp    f0103e3d <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103e22:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f0103e25:	38 ca                	cmp    %cl,%dl
f0103e27:	74 14                	je     f0103e3d <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103e29:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f0103e2d:	84 d2                	test   %dl,%dl
f0103e2f:	75 f1                	jne    f0103e22 <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f0103e31:	b8 00 00 00 00       	mov    $0x0,%eax
f0103e36:	eb 05                	jmp    f0103e3d <strchr+0x32>
f0103e38:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103e3d:	5d                   	pop    %ebp
f0103e3e:	c3                   	ret    

f0103e3f <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103e3f:	55                   	push   %ebp
f0103e40:	89 e5                	mov    %esp,%ebp
f0103e42:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e45:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103e49:	0f b6 10             	movzbl (%eax),%edx
f0103e4c:	84 d2                	test   %dl,%dl
f0103e4e:	74 14                	je     f0103e64 <strfind+0x25>
		if (*s == c)
f0103e50:	38 ca                	cmp    %cl,%dl
f0103e52:	75 06                	jne    f0103e5a <strfind+0x1b>
f0103e54:	eb 0e                	jmp    f0103e64 <strfind+0x25>
f0103e56:	38 ca                	cmp    %cl,%dl
f0103e58:	74 0a                	je     f0103e64 <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0103e5a:	83 c0 01             	add    $0x1,%eax
f0103e5d:	0f b6 10             	movzbl (%eax),%edx
f0103e60:	84 d2                	test   %dl,%dl
f0103e62:	75 f2                	jne    f0103e56 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f0103e64:	5d                   	pop    %ebp
f0103e65:	c3                   	ret    

f0103e66 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103e66:	55                   	push   %ebp
f0103e67:	89 e5                	mov    %esp,%ebp
f0103e69:	83 ec 0c             	sub    $0xc,%esp
f0103e6c:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0103e6f:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0103e72:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0103e75:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103e78:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103e7b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103e7e:	85 c9                	test   %ecx,%ecx
f0103e80:	74 30                	je     f0103eb2 <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103e82:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103e88:	75 25                	jne    f0103eaf <memset+0x49>
f0103e8a:	f6 c1 03             	test   $0x3,%cl
f0103e8d:	75 20                	jne    f0103eaf <memset+0x49>
		c &= 0xFF;
f0103e8f:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103e92:	89 d3                	mov    %edx,%ebx
f0103e94:	c1 e3 08             	shl    $0x8,%ebx
f0103e97:	89 d6                	mov    %edx,%esi
f0103e99:	c1 e6 18             	shl    $0x18,%esi
f0103e9c:	89 d0                	mov    %edx,%eax
f0103e9e:	c1 e0 10             	shl    $0x10,%eax
f0103ea1:	09 f0                	or     %esi,%eax
f0103ea3:	09 d0                	or     %edx,%eax
f0103ea5:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0103ea7:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0103eaa:	fc                   	cld    
f0103eab:	f3 ab                	rep stos %eax,%es:(%edi)
f0103ead:	eb 03                	jmp    f0103eb2 <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103eaf:	fc                   	cld    
f0103eb0:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103eb2:	89 f8                	mov    %edi,%eax
f0103eb4:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0103eb7:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0103eba:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0103ebd:	89 ec                	mov    %ebp,%esp
f0103ebf:	5d                   	pop    %ebp
f0103ec0:	c3                   	ret    

f0103ec1 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103ec1:	55                   	push   %ebp
f0103ec2:	89 e5                	mov    %esp,%ebp
f0103ec4:	83 ec 08             	sub    $0x8,%esp
f0103ec7:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0103eca:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0103ecd:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ed0:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103ed3:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103ed6:	39 c6                	cmp    %eax,%esi
f0103ed8:	73 36                	jae    f0103f10 <memmove+0x4f>
f0103eda:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103edd:	39 d0                	cmp    %edx,%eax
f0103edf:	73 2f                	jae    f0103f10 <memmove+0x4f>
		s += n;
		d += n;
f0103ee1:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103ee4:	f6 c2 03             	test   $0x3,%dl
f0103ee7:	75 1b                	jne    f0103f04 <memmove+0x43>
f0103ee9:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103eef:	75 13                	jne    f0103f04 <memmove+0x43>
f0103ef1:	f6 c1 03             	test   $0x3,%cl
f0103ef4:	75 0e                	jne    f0103f04 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103ef6:	83 ef 04             	sub    $0x4,%edi
f0103ef9:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103efc:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0103eff:	fd                   	std    
f0103f00:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103f02:	eb 09                	jmp    f0103f0d <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0103f04:	83 ef 01             	sub    $0x1,%edi
f0103f07:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103f0a:	fd                   	std    
f0103f0b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103f0d:	fc                   	cld    
f0103f0e:	eb 20                	jmp    f0103f30 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103f10:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103f16:	75 13                	jne    f0103f2b <memmove+0x6a>
f0103f18:	a8 03                	test   $0x3,%al
f0103f1a:	75 0f                	jne    f0103f2b <memmove+0x6a>
f0103f1c:	f6 c1 03             	test   $0x3,%cl
f0103f1f:	75 0a                	jne    f0103f2b <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103f21:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0103f24:	89 c7                	mov    %eax,%edi
f0103f26:	fc                   	cld    
f0103f27:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103f29:	eb 05                	jmp    f0103f30 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103f2b:	89 c7                	mov    %eax,%edi
f0103f2d:	fc                   	cld    
f0103f2e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103f30:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0103f33:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0103f36:	89 ec                	mov    %ebp,%esp
f0103f38:	5d                   	pop    %ebp
f0103f39:	c3                   	ret    

f0103f3a <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0103f3a:	55                   	push   %ebp
f0103f3b:	89 e5                	mov    %esp,%ebp
f0103f3d:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0103f40:	8b 45 10             	mov    0x10(%ebp),%eax
f0103f43:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103f47:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103f4a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103f4e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f51:	89 04 24             	mov    %eax,(%esp)
f0103f54:	e8 68 ff ff ff       	call   f0103ec1 <memmove>
}
f0103f59:	c9                   	leave  
f0103f5a:	c3                   	ret    

f0103f5b <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103f5b:	55                   	push   %ebp
f0103f5c:	89 e5                	mov    %esp,%ebp
f0103f5e:	57                   	push   %edi
f0103f5f:	56                   	push   %esi
f0103f60:	53                   	push   %ebx
f0103f61:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103f64:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103f67:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103f6a:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103f6f:	85 ff                	test   %edi,%edi
f0103f71:	74 37                	je     f0103faa <memcmp+0x4f>
		if (*s1 != *s2)
f0103f73:	0f b6 03             	movzbl (%ebx),%eax
f0103f76:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103f79:	83 ef 01             	sub    $0x1,%edi
f0103f7c:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f0103f81:	38 c8                	cmp    %cl,%al
f0103f83:	74 1c                	je     f0103fa1 <memcmp+0x46>
f0103f85:	eb 10                	jmp    f0103f97 <memcmp+0x3c>
f0103f87:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0103f8c:	83 c2 01             	add    $0x1,%edx
f0103f8f:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0103f93:	38 c8                	cmp    %cl,%al
f0103f95:	74 0a                	je     f0103fa1 <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f0103f97:	0f b6 c0             	movzbl %al,%eax
f0103f9a:	0f b6 c9             	movzbl %cl,%ecx
f0103f9d:	29 c8                	sub    %ecx,%eax
f0103f9f:	eb 09                	jmp    f0103faa <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103fa1:	39 fa                	cmp    %edi,%edx
f0103fa3:	75 e2                	jne    f0103f87 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103fa5:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103faa:	5b                   	pop    %ebx
f0103fab:	5e                   	pop    %esi
f0103fac:	5f                   	pop    %edi
f0103fad:	5d                   	pop    %ebp
f0103fae:	c3                   	ret    

f0103faf <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103faf:	55                   	push   %ebp
f0103fb0:	89 e5                	mov    %esp,%ebp
f0103fb2:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103fb5:	89 c2                	mov    %eax,%edx
f0103fb7:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103fba:	39 d0                	cmp    %edx,%eax
f0103fbc:	73 15                	jae    f0103fd3 <memfind+0x24>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103fbe:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f0103fc2:	38 08                	cmp    %cl,(%eax)
f0103fc4:	75 06                	jne    f0103fcc <memfind+0x1d>
f0103fc6:	eb 0b                	jmp    f0103fd3 <memfind+0x24>
f0103fc8:	38 08                	cmp    %cl,(%eax)
f0103fca:	74 07                	je     f0103fd3 <memfind+0x24>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103fcc:	83 c0 01             	add    $0x1,%eax
f0103fcf:	39 d0                	cmp    %edx,%eax
f0103fd1:	75 f5                	jne    f0103fc8 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103fd3:	5d                   	pop    %ebp
f0103fd4:	c3                   	ret    

f0103fd5 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103fd5:	55                   	push   %ebp
f0103fd6:	89 e5                	mov    %esp,%ebp
f0103fd8:	57                   	push   %edi
f0103fd9:	56                   	push   %esi
f0103fda:	53                   	push   %ebx
f0103fdb:	8b 55 08             	mov    0x8(%ebp),%edx
f0103fde:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103fe1:	0f b6 02             	movzbl (%edx),%eax
f0103fe4:	3c 20                	cmp    $0x20,%al
f0103fe6:	74 04                	je     f0103fec <strtol+0x17>
f0103fe8:	3c 09                	cmp    $0x9,%al
f0103fea:	75 0e                	jne    f0103ffa <strtol+0x25>
		s++;
f0103fec:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103fef:	0f b6 02             	movzbl (%edx),%eax
f0103ff2:	3c 20                	cmp    $0x20,%al
f0103ff4:	74 f6                	je     f0103fec <strtol+0x17>
f0103ff6:	3c 09                	cmp    $0x9,%al
f0103ff8:	74 f2                	je     f0103fec <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103ffa:	3c 2b                	cmp    $0x2b,%al
f0103ffc:	75 0a                	jne    f0104008 <strtol+0x33>
		s++;
f0103ffe:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0104001:	bf 00 00 00 00       	mov    $0x0,%edi
f0104006:	eb 10                	jmp    f0104018 <strtol+0x43>
f0104008:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010400d:	3c 2d                	cmp    $0x2d,%al
f010400f:	75 07                	jne    f0104018 <strtol+0x43>
		s++, neg = 1;
f0104011:	83 c2 01             	add    $0x1,%edx
f0104014:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104018:	85 db                	test   %ebx,%ebx
f010401a:	0f 94 c0             	sete   %al
f010401d:	74 05                	je     f0104024 <strtol+0x4f>
f010401f:	83 fb 10             	cmp    $0x10,%ebx
f0104022:	75 15                	jne    f0104039 <strtol+0x64>
f0104024:	80 3a 30             	cmpb   $0x30,(%edx)
f0104027:	75 10                	jne    f0104039 <strtol+0x64>
f0104029:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f010402d:	75 0a                	jne    f0104039 <strtol+0x64>
		s += 2, base = 16;
f010402f:	83 c2 02             	add    $0x2,%edx
f0104032:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104037:	eb 13                	jmp    f010404c <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f0104039:	84 c0                	test   %al,%al
f010403b:	74 0f                	je     f010404c <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010403d:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104042:	80 3a 30             	cmpb   $0x30,(%edx)
f0104045:	75 05                	jne    f010404c <strtol+0x77>
		s++, base = 8;
f0104047:	83 c2 01             	add    $0x1,%edx
f010404a:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f010404c:	b8 00 00 00 00       	mov    $0x0,%eax
f0104051:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104053:	0f b6 0a             	movzbl (%edx),%ecx
f0104056:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0104059:	80 fb 09             	cmp    $0x9,%bl
f010405c:	77 08                	ja     f0104066 <strtol+0x91>
			dig = *s - '0';
f010405e:	0f be c9             	movsbl %cl,%ecx
f0104061:	83 e9 30             	sub    $0x30,%ecx
f0104064:	eb 1e                	jmp    f0104084 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f0104066:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f0104069:	80 fb 19             	cmp    $0x19,%bl
f010406c:	77 08                	ja     f0104076 <strtol+0xa1>
			dig = *s - 'a' + 10;
f010406e:	0f be c9             	movsbl %cl,%ecx
f0104071:	83 e9 57             	sub    $0x57,%ecx
f0104074:	eb 0e                	jmp    f0104084 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f0104076:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0104079:	80 fb 19             	cmp    $0x19,%bl
f010407c:	77 14                	ja     f0104092 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010407e:	0f be c9             	movsbl %cl,%ecx
f0104081:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0104084:	39 f1                	cmp    %esi,%ecx
f0104086:	7d 0e                	jge    f0104096 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f0104088:	83 c2 01             	add    $0x1,%edx
f010408b:	0f af c6             	imul   %esi,%eax
f010408e:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0104090:	eb c1                	jmp    f0104053 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0104092:	89 c1                	mov    %eax,%ecx
f0104094:	eb 02                	jmp    f0104098 <strtol+0xc3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0104096:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0104098:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010409c:	74 05                	je     f01040a3 <strtol+0xce>
		*endptr = (char *) s;
f010409e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01040a1:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f01040a3:	89 ca                	mov    %ecx,%edx
f01040a5:	f7 da                	neg    %edx
f01040a7:	85 ff                	test   %edi,%edi
f01040a9:	0f 45 c2             	cmovne %edx,%eax
}
f01040ac:	5b                   	pop    %ebx
f01040ad:	5e                   	pop    %esi
f01040ae:	5f                   	pop    %edi
f01040af:	5d                   	pop    %ebp
f01040b0:	c3                   	ret    
	...

f01040c0 <__udivdi3>:
f01040c0:	83 ec 1c             	sub    $0x1c,%esp
f01040c3:	89 7c 24 14          	mov    %edi,0x14(%esp)
f01040c7:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f01040cb:	8b 44 24 20          	mov    0x20(%esp),%eax
f01040cf:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f01040d3:	89 74 24 10          	mov    %esi,0x10(%esp)
f01040d7:	8b 74 24 24          	mov    0x24(%esp),%esi
f01040db:	85 ff                	test   %edi,%edi
f01040dd:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f01040e1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01040e5:	89 cd                	mov    %ecx,%ebp
f01040e7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01040eb:	75 33                	jne    f0104120 <__udivdi3+0x60>
f01040ed:	39 f1                	cmp    %esi,%ecx
f01040ef:	77 57                	ja     f0104148 <__udivdi3+0x88>
f01040f1:	85 c9                	test   %ecx,%ecx
f01040f3:	75 0b                	jne    f0104100 <__udivdi3+0x40>
f01040f5:	b8 01 00 00 00       	mov    $0x1,%eax
f01040fa:	31 d2                	xor    %edx,%edx
f01040fc:	f7 f1                	div    %ecx
f01040fe:	89 c1                	mov    %eax,%ecx
f0104100:	89 f0                	mov    %esi,%eax
f0104102:	31 d2                	xor    %edx,%edx
f0104104:	f7 f1                	div    %ecx
f0104106:	89 c6                	mov    %eax,%esi
f0104108:	8b 44 24 04          	mov    0x4(%esp),%eax
f010410c:	f7 f1                	div    %ecx
f010410e:	89 f2                	mov    %esi,%edx
f0104110:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104114:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104118:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010411c:	83 c4 1c             	add    $0x1c,%esp
f010411f:	c3                   	ret    
f0104120:	31 d2                	xor    %edx,%edx
f0104122:	31 c0                	xor    %eax,%eax
f0104124:	39 f7                	cmp    %esi,%edi
f0104126:	77 e8                	ja     f0104110 <__udivdi3+0x50>
f0104128:	0f bd cf             	bsr    %edi,%ecx
f010412b:	83 f1 1f             	xor    $0x1f,%ecx
f010412e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104132:	75 2c                	jne    f0104160 <__udivdi3+0xa0>
f0104134:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0104138:	76 04                	jbe    f010413e <__udivdi3+0x7e>
f010413a:	39 f7                	cmp    %esi,%edi
f010413c:	73 d2                	jae    f0104110 <__udivdi3+0x50>
f010413e:	31 d2                	xor    %edx,%edx
f0104140:	b8 01 00 00 00       	mov    $0x1,%eax
f0104145:	eb c9                	jmp    f0104110 <__udivdi3+0x50>
f0104147:	90                   	nop
f0104148:	89 f2                	mov    %esi,%edx
f010414a:	f7 f1                	div    %ecx
f010414c:	31 d2                	xor    %edx,%edx
f010414e:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104152:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104156:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010415a:	83 c4 1c             	add    $0x1c,%esp
f010415d:	c3                   	ret    
f010415e:	66 90                	xchg   %ax,%ax
f0104160:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104165:	b8 20 00 00 00       	mov    $0x20,%eax
f010416a:	89 ea                	mov    %ebp,%edx
f010416c:	2b 44 24 04          	sub    0x4(%esp),%eax
f0104170:	d3 e7                	shl    %cl,%edi
f0104172:	89 c1                	mov    %eax,%ecx
f0104174:	d3 ea                	shr    %cl,%edx
f0104176:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010417b:	09 fa                	or     %edi,%edx
f010417d:	89 f7                	mov    %esi,%edi
f010417f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104183:	89 f2                	mov    %esi,%edx
f0104185:	8b 74 24 08          	mov    0x8(%esp),%esi
f0104189:	d3 e5                	shl    %cl,%ebp
f010418b:	89 c1                	mov    %eax,%ecx
f010418d:	d3 ef                	shr    %cl,%edi
f010418f:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104194:	d3 e2                	shl    %cl,%edx
f0104196:	89 c1                	mov    %eax,%ecx
f0104198:	d3 ee                	shr    %cl,%esi
f010419a:	09 d6                	or     %edx,%esi
f010419c:	89 fa                	mov    %edi,%edx
f010419e:	89 f0                	mov    %esi,%eax
f01041a0:	f7 74 24 0c          	divl   0xc(%esp)
f01041a4:	89 d7                	mov    %edx,%edi
f01041a6:	89 c6                	mov    %eax,%esi
f01041a8:	f7 e5                	mul    %ebp
f01041aa:	39 d7                	cmp    %edx,%edi
f01041ac:	72 22                	jb     f01041d0 <__udivdi3+0x110>
f01041ae:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f01041b2:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01041b7:	d3 e5                	shl    %cl,%ebp
f01041b9:	39 c5                	cmp    %eax,%ebp
f01041bb:	73 04                	jae    f01041c1 <__udivdi3+0x101>
f01041bd:	39 d7                	cmp    %edx,%edi
f01041bf:	74 0f                	je     f01041d0 <__udivdi3+0x110>
f01041c1:	89 f0                	mov    %esi,%eax
f01041c3:	31 d2                	xor    %edx,%edx
f01041c5:	e9 46 ff ff ff       	jmp    f0104110 <__udivdi3+0x50>
f01041ca:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01041d0:	8d 46 ff             	lea    -0x1(%esi),%eax
f01041d3:	31 d2                	xor    %edx,%edx
f01041d5:	8b 74 24 10          	mov    0x10(%esp),%esi
f01041d9:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01041dd:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01041e1:	83 c4 1c             	add    $0x1c,%esp
f01041e4:	c3                   	ret    
	...

f01041f0 <__umoddi3>:
f01041f0:	83 ec 1c             	sub    $0x1c,%esp
f01041f3:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f01041f7:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f01041fb:	8b 44 24 20          	mov    0x20(%esp),%eax
f01041ff:	89 74 24 10          	mov    %esi,0x10(%esp)
f0104203:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0104207:	8b 74 24 24          	mov    0x24(%esp),%esi
f010420b:	85 ed                	test   %ebp,%ebp
f010420d:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0104211:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104215:	89 cf                	mov    %ecx,%edi
f0104217:	89 04 24             	mov    %eax,(%esp)
f010421a:	89 f2                	mov    %esi,%edx
f010421c:	75 1a                	jne    f0104238 <__umoddi3+0x48>
f010421e:	39 f1                	cmp    %esi,%ecx
f0104220:	76 4e                	jbe    f0104270 <__umoddi3+0x80>
f0104222:	f7 f1                	div    %ecx
f0104224:	89 d0                	mov    %edx,%eax
f0104226:	31 d2                	xor    %edx,%edx
f0104228:	8b 74 24 10          	mov    0x10(%esp),%esi
f010422c:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104230:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104234:	83 c4 1c             	add    $0x1c,%esp
f0104237:	c3                   	ret    
f0104238:	39 f5                	cmp    %esi,%ebp
f010423a:	77 54                	ja     f0104290 <__umoddi3+0xa0>
f010423c:	0f bd c5             	bsr    %ebp,%eax
f010423f:	83 f0 1f             	xor    $0x1f,%eax
f0104242:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104246:	75 60                	jne    f01042a8 <__umoddi3+0xb8>
f0104248:	3b 0c 24             	cmp    (%esp),%ecx
f010424b:	0f 87 07 01 00 00    	ja     f0104358 <__umoddi3+0x168>
f0104251:	89 f2                	mov    %esi,%edx
f0104253:	8b 34 24             	mov    (%esp),%esi
f0104256:	29 ce                	sub    %ecx,%esi
f0104258:	19 ea                	sbb    %ebp,%edx
f010425a:	89 34 24             	mov    %esi,(%esp)
f010425d:	8b 04 24             	mov    (%esp),%eax
f0104260:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104264:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104268:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010426c:	83 c4 1c             	add    $0x1c,%esp
f010426f:	c3                   	ret    
f0104270:	85 c9                	test   %ecx,%ecx
f0104272:	75 0b                	jne    f010427f <__umoddi3+0x8f>
f0104274:	b8 01 00 00 00       	mov    $0x1,%eax
f0104279:	31 d2                	xor    %edx,%edx
f010427b:	f7 f1                	div    %ecx
f010427d:	89 c1                	mov    %eax,%ecx
f010427f:	89 f0                	mov    %esi,%eax
f0104281:	31 d2                	xor    %edx,%edx
f0104283:	f7 f1                	div    %ecx
f0104285:	8b 04 24             	mov    (%esp),%eax
f0104288:	f7 f1                	div    %ecx
f010428a:	eb 98                	jmp    f0104224 <__umoddi3+0x34>
f010428c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104290:	89 f2                	mov    %esi,%edx
f0104292:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104296:	8b 7c 24 14          	mov    0x14(%esp),%edi
f010429a:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010429e:	83 c4 1c             	add    $0x1c,%esp
f01042a1:	c3                   	ret    
f01042a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01042a8:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01042ad:	89 e8                	mov    %ebp,%eax
f01042af:	bd 20 00 00 00       	mov    $0x20,%ebp
f01042b4:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f01042b8:	89 fa                	mov    %edi,%edx
f01042ba:	d3 e0                	shl    %cl,%eax
f01042bc:	89 e9                	mov    %ebp,%ecx
f01042be:	d3 ea                	shr    %cl,%edx
f01042c0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01042c5:	09 c2                	or     %eax,%edx
f01042c7:	8b 44 24 08          	mov    0x8(%esp),%eax
f01042cb:	89 14 24             	mov    %edx,(%esp)
f01042ce:	89 f2                	mov    %esi,%edx
f01042d0:	d3 e7                	shl    %cl,%edi
f01042d2:	89 e9                	mov    %ebp,%ecx
f01042d4:	d3 ea                	shr    %cl,%edx
f01042d6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01042db:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01042df:	d3 e6                	shl    %cl,%esi
f01042e1:	89 e9                	mov    %ebp,%ecx
f01042e3:	d3 e8                	shr    %cl,%eax
f01042e5:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01042ea:	09 f0                	or     %esi,%eax
f01042ec:	8b 74 24 08          	mov    0x8(%esp),%esi
f01042f0:	f7 34 24             	divl   (%esp)
f01042f3:	d3 e6                	shl    %cl,%esi
f01042f5:	89 74 24 08          	mov    %esi,0x8(%esp)
f01042f9:	89 d6                	mov    %edx,%esi
f01042fb:	f7 e7                	mul    %edi
f01042fd:	39 d6                	cmp    %edx,%esi
f01042ff:	89 c1                	mov    %eax,%ecx
f0104301:	89 d7                	mov    %edx,%edi
f0104303:	72 3f                	jb     f0104344 <__umoddi3+0x154>
f0104305:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0104309:	72 35                	jb     f0104340 <__umoddi3+0x150>
f010430b:	8b 44 24 08          	mov    0x8(%esp),%eax
f010430f:	29 c8                	sub    %ecx,%eax
f0104311:	19 fe                	sbb    %edi,%esi
f0104313:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104318:	89 f2                	mov    %esi,%edx
f010431a:	d3 e8                	shr    %cl,%eax
f010431c:	89 e9                	mov    %ebp,%ecx
f010431e:	d3 e2                	shl    %cl,%edx
f0104320:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104325:	09 d0                	or     %edx,%eax
f0104327:	89 f2                	mov    %esi,%edx
f0104329:	d3 ea                	shr    %cl,%edx
f010432b:	8b 74 24 10          	mov    0x10(%esp),%esi
f010432f:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104333:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104337:	83 c4 1c             	add    $0x1c,%esp
f010433a:	c3                   	ret    
f010433b:	90                   	nop
f010433c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104340:	39 d6                	cmp    %edx,%esi
f0104342:	75 c7                	jne    f010430b <__umoddi3+0x11b>
f0104344:	89 d7                	mov    %edx,%edi
f0104346:	89 c1                	mov    %eax,%ecx
f0104348:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f010434c:	1b 3c 24             	sbb    (%esp),%edi
f010434f:	eb ba                	jmp    f010430b <__umoddi3+0x11b>
f0104351:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104358:	39 f5                	cmp    %esi,%ebp
f010435a:	0f 82 f1 fe ff ff    	jb     f0104251 <__umoddi3+0x61>
f0104360:	e9 f8 fe ff ff       	jmp    f010425d <__umoddi3+0x6d>
