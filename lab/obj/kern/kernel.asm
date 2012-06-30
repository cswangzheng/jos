
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
	# until we set up our real page table in i386_vm_init in lab 2.

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
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 a0 1b 10 f0 	movl   $0xf0101ba0,(%esp)
f0100055:	e8 e0 09 00 00       	call   f0100a3a <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 f9 06 00 00       	call   f0100780 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 bc 1b 10 f0 	movl   $0xf0101bbc,(%esp)
f0100092:	e8 a3 09 00 00       	call   f0100a3a <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 80 29 11 f0       	mov    $0xf0112980,%eax
f01000a8:	2d 04 23 11 f0       	sub    $0xf0112304,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 04 23 11 f0 	movl   $0xf0112304,(%esp)
f01000c0:	e8 c1 15 00 00       	call   f0101686 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 a1 04 00 00       	call   f010056b <cons_init>
	cprintf("color test: \033[0;32;40m hello \033[0;36;41mworld\033[0;37;40m\n");
f01000ca:	c7 04 24 24 1c 10 f0 	movl   $0xf0101c24,(%esp)
f01000d1:	e8 64 09 00 00       	call   f0100a3a <cprintf>
	cprintf("6828 decimal is %o octal!\n", 6828);
f01000d6:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000dd:	00 
f01000de:	c7 04 24 d7 1b 10 f0 	movl   $0xf0101bd7,(%esp)
f01000e5:	e8 50 09 00 00       	call   f0100a3a <cprintf>
	//cprintf("H%x Wo%s", 57616, &i);	
	//Now test print
	//int x = 1, y = 3, z = 4;
	//cprintf("x %d, y %x, z %d\n", x, y, z);
	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000ea:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000f1:	e8 4a ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000f6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000fd:	e8 b3 07 00 00       	call   f01008b5 <monitor>
f0100102:	eb f2                	jmp    f01000f6 <i386_init+0x59>

f0100104 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100104:	55                   	push   %ebp
f0100105:	89 e5                	mov    %esp,%ebp
f0100107:	56                   	push   %esi
f0100108:	53                   	push   %ebx
f0100109:	83 ec 10             	sub    $0x10,%esp
f010010c:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010010f:	83 3d 20 23 11 f0 00 	cmpl   $0x0,0xf0112320
f0100116:	75 3d                	jne    f0100155 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f0100118:	89 35 20 23 11 f0    	mov    %esi,0xf0112320

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f010011e:	fa                   	cli    
f010011f:	fc                   	cld    

	va_start(ap, fmt);
f0100120:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100123:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100126:	89 44 24 08          	mov    %eax,0x8(%esp)
f010012a:	8b 45 08             	mov    0x8(%ebp),%eax
f010012d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100131:	c7 04 24 f2 1b 10 f0 	movl   $0xf0101bf2,(%esp)
f0100138:	e8 fd 08 00 00       	call   f0100a3a <cprintf>
	vcprintf(fmt, ap);
f010013d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100141:	89 34 24             	mov    %esi,(%esp)
f0100144:	e8 be 08 00 00       	call   f0100a07 <vcprintf>
	cprintf("\n");
f0100149:	c7 04 24 66 1c 10 f0 	movl   $0xf0101c66,(%esp)
f0100150:	e8 e5 08 00 00       	call   f0100a3a <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100155:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010015c:	e8 54 07 00 00       	call   f01008b5 <monitor>
f0100161:	eb f2                	jmp    f0100155 <_panic+0x51>

f0100163 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100163:	55                   	push   %ebp
f0100164:	89 e5                	mov    %esp,%ebp
f0100166:	53                   	push   %ebx
f0100167:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010016a:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f010016d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100170:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100174:	8b 45 08             	mov    0x8(%ebp),%eax
f0100177:	89 44 24 04          	mov    %eax,0x4(%esp)
f010017b:	c7 04 24 0a 1c 10 f0 	movl   $0xf0101c0a,(%esp)
f0100182:	e8 b3 08 00 00       	call   f0100a3a <cprintf>
	vcprintf(fmt, ap);
f0100187:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010018b:	8b 45 10             	mov    0x10(%ebp),%eax
f010018e:	89 04 24             	mov    %eax,(%esp)
f0100191:	e8 71 08 00 00       	call   f0100a07 <vcprintf>
	cprintf("\n");
f0100196:	c7 04 24 66 1c 10 f0 	movl   $0xf0101c66,(%esp)
f010019d:	e8 98 08 00 00       	call   f0100a3a <cprintf>
	va_end(ap);
}
f01001a2:	83 c4 14             	add    $0x14,%esp
f01001a5:	5b                   	pop    %ebx
f01001a6:	5d                   	pop    %ebp
f01001a7:	c3                   	ret    
	...

f01001b0 <delay>:
extern int char_color;

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f01001b0:	55                   	push   %ebp
f01001b1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001b3:	ba 84 00 00 00       	mov    $0x84,%edx
f01001b8:	ec                   	in     (%dx),%al
f01001b9:	ec                   	in     (%dx),%al
f01001ba:	ec                   	in     (%dx),%al
f01001bb:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f01001bc:	5d                   	pop    %ebp
f01001bd:	c3                   	ret    

f01001be <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001be:	55                   	push   %ebp
f01001bf:	89 e5                	mov    %esp,%ebp
f01001c1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001c6:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001c7:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
static bool serial_exists;

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001cc:	a8 01                	test   $0x1,%al
f01001ce:	74 06                	je     f01001d6 <serial_proc_data+0x18>
f01001d0:	b2 f8                	mov    $0xf8,%dl
f01001d2:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001d3:	0f b6 c8             	movzbl %al,%ecx
}
f01001d6:	89 c8                	mov    %ecx,%eax
f01001d8:	5d                   	pop    %ebp
f01001d9:	c3                   	ret    

f01001da <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001da:	55                   	push   %ebp
f01001db:	89 e5                	mov    %esp,%ebp
f01001dd:	53                   	push   %ebx
f01001de:	83 ec 04             	sub    $0x4,%esp
f01001e1:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001e3:	eb 25                	jmp    f010020a <cons_intr+0x30>
		if (c == 0)
f01001e5:	85 c0                	test   %eax,%eax
f01001e7:	74 21                	je     f010020a <cons_intr+0x30>
			continue;
		cons.buf[cons.wpos++] = c;
f01001e9:	8b 15 64 25 11 f0    	mov    0xf0112564,%edx
f01001ef:	88 82 60 23 11 f0    	mov    %al,-0xfeedca0(%edx)
f01001f5:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f01001f8:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f01001fd:	ba 00 00 00 00       	mov    $0x0,%edx
f0100202:	0f 44 c2             	cmove  %edx,%eax
f0100205:	a3 64 25 11 f0       	mov    %eax,0xf0112564
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f010020a:	ff d3                	call   *%ebx
f010020c:	83 f8 ff             	cmp    $0xffffffff,%eax
f010020f:	75 d4                	jne    f01001e5 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100211:	83 c4 04             	add    $0x4,%esp
f0100214:	5b                   	pop    %ebx
f0100215:	5d                   	pop    %ebp
f0100216:	c3                   	ret    

f0100217 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100217:	55                   	push   %ebp
f0100218:	89 e5                	mov    %esp,%ebp
f010021a:	57                   	push   %edi
f010021b:	56                   	push   %esi
f010021c:	53                   	push   %ebx
f010021d:	83 ec 2c             	sub    $0x2c,%esp
f0100220:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100223:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100228:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f0100229:	a8 20                	test   $0x20,%al
f010022b:	75 1b                	jne    f0100248 <cons_putc+0x31>
f010022d:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100232:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f0100237:	e8 74 ff ff ff       	call   f01001b0 <delay>
f010023c:	89 f2                	mov    %esi,%edx
f010023e:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f010023f:	a8 20                	test   $0x20,%al
f0100241:	75 05                	jne    f0100248 <cons_putc+0x31>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100243:	83 eb 01             	sub    $0x1,%ebx
f0100246:	75 ef                	jne    f0100237 <cons_putc+0x20>
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
f0100248:	0f b6 7d e4          	movzbl -0x1c(%ebp),%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010024c:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100251:	89 f8                	mov    %edi,%eax
f0100253:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100254:	b2 79                	mov    $0x79,%dl
f0100256:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100257:	84 c0                	test   %al,%al
f0100259:	78 1b                	js     f0100276 <cons_putc+0x5f>
f010025b:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100260:	be 79 03 00 00       	mov    $0x379,%esi
		delay();
f0100265:	e8 46 ff ff ff       	call   f01001b0 <delay>
f010026a:	89 f2                	mov    %esi,%edx
f010026c:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010026d:	84 c0                	test   %al,%al
f010026f:	78 05                	js     f0100276 <cons_putc+0x5f>
f0100271:	83 eb 01             	sub    $0x1,%ebx
f0100274:	75 ef                	jne    f0100265 <cons_putc+0x4e>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100276:	ba 78 03 00 00       	mov    $0x378,%edx
f010027b:	89 f8                	mov    %edi,%eax
f010027d:	ee                   	out    %al,(%dx)
f010027e:	b2 7a                	mov    $0x7a,%dl
f0100280:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100285:	ee                   	out    %al,(%dx)
f0100286:	b8 08 00 00 00       	mov    $0x8,%eax
f010028b:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	c = c | (char_color<<8);
f010028c:	a1 00 23 11 f0       	mov    0xf0112300,%eax
f0100291:	c1 e0 08             	shl    $0x8,%eax
f0100294:	0b 45 e4             	or     -0x1c(%ebp),%eax
	
	if (!(c & ~0xFF)){
f0100297:	89 c1                	mov    %eax,%ecx
f0100299:	81 e1 00 ff ff ff    	and    $0xffffff00,%ecx
		c |= 0x0700;
f010029f:	89 c2                	mov    %eax,%edx
f01002a1:	80 ce 07             	or     $0x7,%dh
f01002a4:	85 c9                	test   %ecx,%ecx
f01002a6:	0f 44 c2             	cmove  %edx,%eax
		}

	switch (c & 0xff) {
f01002a9:	0f b6 d0             	movzbl %al,%edx
f01002ac:	83 fa 09             	cmp    $0x9,%edx
f01002af:	74 75                	je     f0100326 <cons_putc+0x10f>
f01002b1:	83 fa 09             	cmp    $0x9,%edx
f01002b4:	7f 0c                	jg     f01002c2 <cons_putc+0xab>
f01002b6:	83 fa 08             	cmp    $0x8,%edx
f01002b9:	0f 85 9b 00 00 00    	jne    f010035a <cons_putc+0x143>
f01002bf:	90                   	nop
f01002c0:	eb 10                	jmp    f01002d2 <cons_putc+0xbb>
f01002c2:	83 fa 0a             	cmp    $0xa,%edx
f01002c5:	74 39                	je     f0100300 <cons_putc+0xe9>
f01002c7:	83 fa 0d             	cmp    $0xd,%edx
f01002ca:	0f 85 8a 00 00 00    	jne    f010035a <cons_putc+0x143>
f01002d0:	eb 36                	jmp    f0100308 <cons_putc+0xf1>
	case '\b':
		if (crt_pos > 0) {
f01002d2:	0f b7 15 74 25 11 f0 	movzwl 0xf0112574,%edx
f01002d9:	66 85 d2             	test   %dx,%dx
f01002dc:	0f 84 e3 00 00 00    	je     f01003c5 <cons_putc+0x1ae>
			crt_pos--;
f01002e2:	83 ea 01             	sub    $0x1,%edx
f01002e5:	66 89 15 74 25 11 f0 	mov    %dx,0xf0112574
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01002ec:	0f b7 d2             	movzwl %dx,%edx
f01002ef:	b0 00                	mov    $0x0,%al
f01002f1:	83 c8 20             	or     $0x20,%eax
f01002f4:	8b 0d 70 25 11 f0    	mov    0xf0112570,%ecx
f01002fa:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f01002fe:	eb 78                	jmp    f0100378 <cons_putc+0x161>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100300:	66 83 05 74 25 11 f0 	addw   $0x50,0xf0112574
f0100307:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100308:	0f b7 05 74 25 11 f0 	movzwl 0xf0112574,%eax
f010030f:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100315:	c1 e8 16             	shr    $0x16,%eax
f0100318:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010031b:	c1 e0 04             	shl    $0x4,%eax
f010031e:	66 a3 74 25 11 f0    	mov    %ax,0xf0112574
f0100324:	eb 52                	jmp    f0100378 <cons_putc+0x161>
		break;
	case '\t':
		cons_putc(' ');
f0100326:	b8 20 00 00 00       	mov    $0x20,%eax
f010032b:	e8 e7 fe ff ff       	call   f0100217 <cons_putc>
		cons_putc(' ');
f0100330:	b8 20 00 00 00       	mov    $0x20,%eax
f0100335:	e8 dd fe ff ff       	call   f0100217 <cons_putc>
		cons_putc(' ');
f010033a:	b8 20 00 00 00       	mov    $0x20,%eax
f010033f:	e8 d3 fe ff ff       	call   f0100217 <cons_putc>
		cons_putc(' ');
f0100344:	b8 20 00 00 00       	mov    $0x20,%eax
f0100349:	e8 c9 fe ff ff       	call   f0100217 <cons_putc>
		cons_putc(' ');
f010034e:	b8 20 00 00 00       	mov    $0x20,%eax
f0100353:	e8 bf fe ff ff       	call   f0100217 <cons_putc>
f0100358:	eb 1e                	jmp    f0100378 <cons_putc+0x161>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010035a:	0f b7 15 74 25 11 f0 	movzwl 0xf0112574,%edx
f0100361:	0f b7 da             	movzwl %dx,%ebx
f0100364:	8b 0d 70 25 11 f0    	mov    0xf0112570,%ecx
f010036a:	66 89 04 59          	mov    %ax,(%ecx,%ebx,2)
f010036e:	83 c2 01             	add    $0x1,%edx
f0100371:	66 89 15 74 25 11 f0 	mov    %dx,0xf0112574
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100378:	66 81 3d 74 25 11 f0 	cmpw   $0x7cf,0xf0112574
f010037f:	cf 07 
f0100381:	76 42                	jbe    f01003c5 <cons_putc+0x1ae>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100383:	a1 70 25 11 f0       	mov    0xf0112570,%eax
f0100388:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010038f:	00 
f0100390:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100396:	89 54 24 04          	mov    %edx,0x4(%esp)
f010039a:	89 04 24             	mov    %eax,(%esp)
f010039d:	e8 3f 13 00 00       	call   f01016e1 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01003a2:	8b 15 70 25 11 f0    	mov    0xf0112570,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01003a8:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f01003ad:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01003b3:	83 c0 01             	add    $0x1,%eax
f01003b6:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01003bb:	75 f0                	jne    f01003ad <cons_putc+0x196>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01003bd:	66 83 2d 74 25 11 f0 	subw   $0x50,0xf0112574
f01003c4:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01003c5:	8b 0d 6c 25 11 f0    	mov    0xf011256c,%ecx
f01003cb:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003d0:	89 ca                	mov    %ecx,%edx
f01003d2:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003d3:	0f b7 35 74 25 11 f0 	movzwl 0xf0112574,%esi
f01003da:	8d 59 01             	lea    0x1(%ecx),%ebx
f01003dd:	89 f0                	mov    %esi,%eax
f01003df:	66 c1 e8 08          	shr    $0x8,%ax
f01003e3:	89 da                	mov    %ebx,%edx
f01003e5:	ee                   	out    %al,(%dx)
f01003e6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01003eb:	89 ca                	mov    %ecx,%edx
f01003ed:	ee                   	out    %al,(%dx)
f01003ee:	89 f0                	mov    %esi,%eax
f01003f0:	89 da                	mov    %ebx,%edx
f01003f2:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01003f3:	83 c4 2c             	add    $0x2c,%esp
f01003f6:	5b                   	pop    %ebx
f01003f7:	5e                   	pop    %esi
f01003f8:	5f                   	pop    %edi
f01003f9:	5d                   	pop    %ebp
f01003fa:	c3                   	ret    

f01003fb <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01003fb:	55                   	push   %ebp
f01003fc:	89 e5                	mov    %esp,%ebp
f01003fe:	53                   	push   %ebx
f01003ff:	83 ec 14             	sub    $0x14,%esp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100402:	ba 64 00 00 00       	mov    $0x64,%edx
f0100407:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f0100408:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f010040d:	a8 01                	test   $0x1,%al
f010040f:	0f 84 de 00 00 00    	je     f01004f3 <kbd_proc_data+0xf8>
f0100415:	b2 60                	mov    $0x60,%dl
f0100417:	ec                   	in     (%dx),%al
f0100418:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010041a:	3c e0                	cmp    $0xe0,%al
f010041c:	75 11                	jne    f010042f <kbd_proc_data+0x34>
		// E0 escape character
		shift |= E0ESC;
f010041e:	83 0d 68 25 11 f0 40 	orl    $0x40,0xf0112568
		return 0;
f0100425:	bb 00 00 00 00       	mov    $0x0,%ebx
f010042a:	e9 c4 00 00 00       	jmp    f01004f3 <kbd_proc_data+0xf8>
	} else if (data & 0x80) {
f010042f:	84 c0                	test   %al,%al
f0100431:	79 37                	jns    f010046a <kbd_proc_data+0x6f>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100433:	8b 0d 68 25 11 f0    	mov    0xf0112568,%ecx
f0100439:	89 cb                	mov    %ecx,%ebx
f010043b:	83 e3 40             	and    $0x40,%ebx
f010043e:	83 e0 7f             	and    $0x7f,%eax
f0100441:	85 db                	test   %ebx,%ebx
f0100443:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100446:	0f b6 d2             	movzbl %dl,%edx
f0100449:	0f b6 82 a0 1c 10 f0 	movzbl -0xfefe360(%edx),%eax
f0100450:	83 c8 40             	or     $0x40,%eax
f0100453:	0f b6 c0             	movzbl %al,%eax
f0100456:	f7 d0                	not    %eax
f0100458:	21 c1                	and    %eax,%ecx
f010045a:	89 0d 68 25 11 f0    	mov    %ecx,0xf0112568
		return 0;
f0100460:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100465:	e9 89 00 00 00       	jmp    f01004f3 <kbd_proc_data+0xf8>
	} else if (shift & E0ESC) {
f010046a:	8b 0d 68 25 11 f0    	mov    0xf0112568,%ecx
f0100470:	f6 c1 40             	test   $0x40,%cl
f0100473:	74 0e                	je     f0100483 <kbd_proc_data+0x88>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100475:	89 c2                	mov    %eax,%edx
f0100477:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f010047a:	83 e1 bf             	and    $0xffffffbf,%ecx
f010047d:	89 0d 68 25 11 f0    	mov    %ecx,0xf0112568
	}

	shift |= shiftcode[data];
f0100483:	0f b6 d2             	movzbl %dl,%edx
f0100486:	0f b6 82 a0 1c 10 f0 	movzbl -0xfefe360(%edx),%eax
f010048d:	0b 05 68 25 11 f0    	or     0xf0112568,%eax
	shift ^= togglecode[data];
f0100493:	0f b6 8a a0 1d 10 f0 	movzbl -0xfefe260(%edx),%ecx
f010049a:	31 c8                	xor    %ecx,%eax
f010049c:	a3 68 25 11 f0       	mov    %eax,0xf0112568

	c = charcode[shift & (CTL | SHIFT)][data];
f01004a1:	89 c1                	mov    %eax,%ecx
f01004a3:	83 e1 03             	and    $0x3,%ecx
f01004a6:	8b 0c 8d a0 1e 10 f0 	mov    -0xfefe160(,%ecx,4),%ecx
f01004ad:	0f b6 1c 11          	movzbl (%ecx,%edx,1),%ebx
	if (shift & CAPSLOCK) {
f01004b1:	a8 08                	test   $0x8,%al
f01004b3:	74 19                	je     f01004ce <kbd_proc_data+0xd3>
		if ('a' <= c && c <= 'z')
f01004b5:	8d 53 9f             	lea    -0x61(%ebx),%edx
f01004b8:	83 fa 19             	cmp    $0x19,%edx
f01004bb:	77 05                	ja     f01004c2 <kbd_proc_data+0xc7>
			c += 'A' - 'a';
f01004bd:	83 eb 20             	sub    $0x20,%ebx
f01004c0:	eb 0c                	jmp    f01004ce <kbd_proc_data+0xd3>
		else if ('A' <= c && c <= 'Z')
f01004c2:	8d 4b bf             	lea    -0x41(%ebx),%ecx
			c += 'a' - 'A';
f01004c5:	8d 53 20             	lea    0x20(%ebx),%edx
f01004c8:	83 f9 19             	cmp    $0x19,%ecx
f01004cb:	0f 46 da             	cmovbe %edx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01004ce:	f7 d0                	not    %eax
f01004d0:	a8 06                	test   $0x6,%al
f01004d2:	75 1f                	jne    f01004f3 <kbd_proc_data+0xf8>
f01004d4:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01004da:	75 17                	jne    f01004f3 <kbd_proc_data+0xf8>
		cprintf("Rebooting!\n");
f01004dc:	c7 04 24 5c 1c 10 f0 	movl   $0xf0101c5c,(%esp)
f01004e3:	e8 52 05 00 00       	call   f0100a3a <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01004e8:	ba 92 00 00 00       	mov    $0x92,%edx
f01004ed:	b8 03 00 00 00       	mov    $0x3,%eax
f01004f2:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01004f3:	89 d8                	mov    %ebx,%eax
f01004f5:	83 c4 14             	add    $0x14,%esp
f01004f8:	5b                   	pop    %ebx
f01004f9:	5d                   	pop    %ebp
f01004fa:	c3                   	ret    

f01004fb <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004fb:	55                   	push   %ebp
f01004fc:	89 e5                	mov    %esp,%ebp
f01004fe:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f0100501:	83 3d 40 23 11 f0 00 	cmpl   $0x0,0xf0112340
f0100508:	74 0a                	je     f0100514 <serial_intr+0x19>
		cons_intr(serial_proc_data);
f010050a:	b8 be 01 10 f0       	mov    $0xf01001be,%eax
f010050f:	e8 c6 fc ff ff       	call   f01001da <cons_intr>
}
f0100514:	c9                   	leave  
f0100515:	c3                   	ret    

f0100516 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100516:	55                   	push   %ebp
f0100517:	89 e5                	mov    %esp,%ebp
f0100519:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f010051c:	b8 fb 03 10 f0       	mov    $0xf01003fb,%eax
f0100521:	e8 b4 fc ff ff       	call   f01001da <cons_intr>
}
f0100526:	c9                   	leave  
f0100527:	c3                   	ret    

f0100528 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100528:	55                   	push   %ebp
f0100529:	89 e5                	mov    %esp,%ebp
f010052b:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010052e:	e8 c8 ff ff ff       	call   f01004fb <serial_intr>
	kbd_intr();
f0100533:	e8 de ff ff ff       	call   f0100516 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100538:	8b 15 60 25 11 f0    	mov    0xf0112560,%edx
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f010053e:	b8 00 00 00 00       	mov    $0x0,%eax
	// (e.g., when called from the kernel monitor).
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100543:	3b 15 64 25 11 f0    	cmp    0xf0112564,%edx
f0100549:	74 1e                	je     f0100569 <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f010054b:	0f b6 82 60 23 11 f0 	movzbl -0xfeedca0(%edx),%eax
f0100552:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f0100555:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010055b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100560:	0f 44 d1             	cmove  %ecx,%edx
f0100563:	89 15 60 25 11 f0    	mov    %edx,0xf0112560
		return c;
	}
	return 0;
}
f0100569:	c9                   	leave  
f010056a:	c3                   	ret    

f010056b <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010056b:	55                   	push   %ebp
f010056c:	89 e5                	mov    %esp,%ebp
f010056e:	57                   	push   %edi
f010056f:	56                   	push   %esi
f0100570:	53                   	push   %ebx
f0100571:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100574:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010057b:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100582:	5a a5 
	if (*cp != 0xA55A) {
f0100584:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010058b:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010058f:	74 11                	je     f01005a2 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100591:	c7 05 6c 25 11 f0 b4 	movl   $0x3b4,0xf011256c
f0100598:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010059b:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f01005a0:	eb 16                	jmp    f01005b8 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01005a2:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005a9:	c7 05 6c 25 11 f0 d4 	movl   $0x3d4,0xf011256c
f01005b0:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005b3:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f01005b8:	8b 0d 6c 25 11 f0    	mov    0xf011256c,%ecx
f01005be:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005c3:	89 ca                	mov    %ecx,%edx
f01005c5:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005c6:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005c9:	89 da                	mov    %ebx,%edx
f01005cb:	ec                   	in     (%dx),%al
f01005cc:	0f b6 f8             	movzbl %al,%edi
f01005cf:	c1 e7 08             	shl    $0x8,%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005d2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005d7:	89 ca                	mov    %ecx,%edx
f01005d9:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005da:	89 da                	mov    %ebx,%edx
f01005dc:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005dd:	89 35 70 25 11 f0    	mov    %esi,0xf0112570
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005e3:	0f b6 d8             	movzbl %al,%ebx
f01005e6:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005e8:	66 89 3d 74 25 11 f0 	mov    %di,0xf0112574
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005ef:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f01005f4:	b8 00 00 00 00       	mov    $0x0,%eax
f01005f9:	89 da                	mov    %ebx,%edx
f01005fb:	ee                   	out    %al,(%dx)
f01005fc:	b2 fb                	mov    $0xfb,%dl
f01005fe:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100603:	ee                   	out    %al,(%dx)
f0100604:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f0100609:	b8 0c 00 00 00       	mov    $0xc,%eax
f010060e:	89 ca                	mov    %ecx,%edx
f0100610:	ee                   	out    %al,(%dx)
f0100611:	b2 f9                	mov    $0xf9,%dl
f0100613:	b8 00 00 00 00       	mov    $0x0,%eax
f0100618:	ee                   	out    %al,(%dx)
f0100619:	b2 fb                	mov    $0xfb,%dl
f010061b:	b8 03 00 00 00       	mov    $0x3,%eax
f0100620:	ee                   	out    %al,(%dx)
f0100621:	b2 fc                	mov    $0xfc,%dl
f0100623:	b8 00 00 00 00       	mov    $0x0,%eax
f0100628:	ee                   	out    %al,(%dx)
f0100629:	b2 f9                	mov    $0xf9,%dl
f010062b:	b8 01 00 00 00       	mov    $0x1,%eax
f0100630:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100631:	b2 fd                	mov    $0xfd,%dl
f0100633:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100634:	3c ff                	cmp    $0xff,%al
f0100636:	0f 95 c0             	setne  %al
f0100639:	0f b6 c0             	movzbl %al,%eax
f010063c:	89 c6                	mov    %eax,%esi
f010063e:	a3 40 23 11 f0       	mov    %eax,0xf0112340
f0100643:	89 da                	mov    %ebx,%edx
f0100645:	ec                   	in     (%dx),%al
f0100646:	89 ca                	mov    %ecx,%edx
f0100648:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100649:	85 f6                	test   %esi,%esi
f010064b:	75 0c                	jne    f0100659 <cons_init+0xee>
		cprintf("Serial port does not exist!\n");
f010064d:	c7 04 24 68 1c 10 f0 	movl   $0xf0101c68,(%esp)
f0100654:	e8 e1 03 00 00       	call   f0100a3a <cprintf>
}
f0100659:	83 c4 1c             	add    $0x1c,%esp
f010065c:	5b                   	pop    %ebx
f010065d:	5e                   	pop    %esi
f010065e:	5f                   	pop    %edi
f010065f:	5d                   	pop    %ebp
f0100660:	c3                   	ret    

f0100661 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100661:	55                   	push   %ebp
f0100662:	89 e5                	mov    %esp,%ebp
f0100664:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100667:	8b 45 08             	mov    0x8(%ebp),%eax
f010066a:	e8 a8 fb ff ff       	call   f0100217 <cons_putc>
}
f010066f:	c9                   	leave  
f0100670:	c3                   	ret    

f0100671 <getchar>:

int
getchar(void)
{
f0100671:	55                   	push   %ebp
f0100672:	89 e5                	mov    %esp,%ebp
f0100674:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100677:	e8 ac fe ff ff       	call   f0100528 <cons_getc>
f010067c:	85 c0                	test   %eax,%eax
f010067e:	74 f7                	je     f0100677 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100680:	c9                   	leave  
f0100681:	c3                   	ret    

f0100682 <iscons>:

int
iscons(int fdnum)
{
f0100682:	55                   	push   %ebp
f0100683:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100685:	b8 01 00 00 00       	mov    $0x1,%eax
f010068a:	5d                   	pop    %ebp
f010068b:	c3                   	ret    
f010068c:	00 00                	add    %al,(%eax)
	...

f0100690 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100690:	55                   	push   %ebp
f0100691:	89 e5                	mov    %esp,%ebp
f0100693:	83 ec 18             	sub    $0x18,%esp
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100696:	c7 04 24 b0 1e 10 f0 	movl   $0xf0101eb0,(%esp)
f010069d:	e8 98 03 00 00       	call   f0100a3a <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006a2:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006a9:	00 
f01006aa:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006b1:	f0 
f01006b2:	c7 04 24 74 1f 10 f0 	movl   $0xf0101f74,(%esp)
f01006b9:	e8 7c 03 00 00       	call   f0100a3a <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006be:	c7 44 24 08 85 1b 10 	movl   $0x101b85,0x8(%esp)
f01006c5:	00 
f01006c6:	c7 44 24 04 85 1b 10 	movl   $0xf0101b85,0x4(%esp)
f01006cd:	f0 
f01006ce:	c7 04 24 98 1f 10 f0 	movl   $0xf0101f98,(%esp)
f01006d5:	e8 60 03 00 00       	call   f0100a3a <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006da:	c7 44 24 08 04 23 11 	movl   $0x112304,0x8(%esp)
f01006e1:	00 
f01006e2:	c7 44 24 04 04 23 11 	movl   $0xf0112304,0x4(%esp)
f01006e9:	f0 
f01006ea:	c7 04 24 bc 1f 10 f0 	movl   $0xf0101fbc,(%esp)
f01006f1:	e8 44 03 00 00       	call   f0100a3a <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006f6:	c7 44 24 08 80 29 11 	movl   $0x112980,0x8(%esp)
f01006fd:	00 
f01006fe:	c7 44 24 04 80 29 11 	movl   $0xf0112980,0x4(%esp)
f0100705:	f0 
f0100706:	c7 04 24 e0 1f 10 f0 	movl   $0xf0101fe0,(%esp)
f010070d:	e8 28 03 00 00       	call   f0100a3a <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
f0100712:	b8 7f 2d 11 f0       	mov    $0xf0112d7f,%eax
f0100717:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010071c:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100722:	85 c0                	test   %eax,%eax
f0100724:	0f 48 c2             	cmovs  %edx,%eax
f0100727:	c1 f8 0a             	sar    $0xa,%eax
f010072a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010072e:	c7 04 24 04 20 10 f0 	movl   $0xf0102004,(%esp)
f0100735:	e8 00 03 00 00       	call   f0100a3a <cprintf>
		(end-entry+1023)/1024);
	return 0;
}
f010073a:	b8 00 00 00 00       	mov    $0x0,%eax
f010073f:	c9                   	leave  
f0100740:	c3                   	ret    

f0100741 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100741:	55                   	push   %ebp
f0100742:	89 e5                	mov    %esp,%ebp
f0100744:	53                   	push   %ebx
f0100745:	83 ec 14             	sub    $0x14,%esp
f0100748:	bb 00 00 00 00       	mov    $0x0,%ebx
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010074d:	8b 83 04 21 10 f0    	mov    -0xfefdefc(%ebx),%eax
f0100753:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100757:	8b 83 00 21 10 f0    	mov    -0xfefdf00(%ebx),%eax
f010075d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100761:	c7 04 24 c9 1e 10 f0 	movl   $0xf0101ec9,(%esp)
f0100768:	e8 cd 02 00 00       	call   f0100a3a <cprintf>
f010076d:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f0100770:	83 fb 24             	cmp    $0x24,%ebx
f0100773:	75 d8                	jne    f010074d <mon_help+0xc>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f0100775:	b8 00 00 00 00       	mov    $0x0,%eax
f010077a:	83 c4 14             	add    $0x14,%esp
f010077d:	5b                   	pop    %ebx
f010077e:	5d                   	pop    %ebp
f010077f:	c3                   	ret    

f0100780 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100780:	55                   	push   %ebp
f0100781:	89 e5                	mov    %esp,%ebp
f0100783:	57                   	push   %edi
f0100784:	56                   	push   %esi
f0100785:	53                   	push   %ebx
f0100786:	81 ec 8c 00 00 00    	sub    $0x8c,%esp

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f010078c:	89 eb                	mov    %ebp,%ebx
f010078e:	89 de                	mov    %ebx,%esi
	// Your code here.
	uint32_t ebp,eip,arg[5];
	ebp = read_ebp();
	eip = *((uint32_t*)ebp+1);
f0100790:	8b 7b 04             	mov    0x4(%ebx),%edi
	arg[0] = *((uint32_t*)ebp+2);
f0100793:	8b 43 08             	mov    0x8(%ebx),%eax
f0100796:	89 45 a4             	mov    %eax,-0x5c(%ebp)
	arg[1] = *((uint32_t*)ebp+3);
f0100799:	8b 43 0c             	mov    0xc(%ebx),%eax
f010079c:	89 45 a0             	mov    %eax,-0x60(%ebp)
	arg[2] = *((uint32_t*)ebp+4);
f010079f:	8b 43 10             	mov    0x10(%ebx),%eax
f01007a2:	89 45 9c             	mov    %eax,-0x64(%ebp)
	arg[3] = *((uint32_t*)ebp+5);
f01007a5:	8b 43 14             	mov    0x14(%ebx),%eax
f01007a8:	89 45 98             	mov    %eax,-0x68(%ebp)
	arg[4] = *((uint32_t*)ebp+6);
f01007ab:	8b 43 18             	mov    0x18(%ebx),%eax
f01007ae:	89 45 94             	mov    %eax,-0x6c(%ebp)

	cprintf("Stack backtrace:\n");
f01007b1:	c7 04 24 d2 1e 10 f0 	movl   $0xf0101ed2,(%esp)
f01007b8:	e8 7d 02 00 00       	call   f0100a3a <cprintf>
	
	while(ebp != 0x00)
f01007bd:	85 db                	test   %ebx,%ebx
f01007bf:	0f 84 e0 00 00 00    	je     f01008a5 <mon_backtrace+0x125>
			info.eip_fn_name = "<unknown>";
			info.eip_fn_namelen = 9;
			info.eip_fn_addr = eip;
			info.eip_fn_narg = 0;
			char display_eip_fn_name[30];
			debuginfo_eip(eip,&info);
f01007c5:	8d 5d d0             	lea    -0x30(%ebp),%ebx
f01007c8:	8b 45 9c             	mov    -0x64(%ebp),%eax
f01007cb:	8b 55 98             	mov    -0x68(%ebp),%edx
f01007ce:	8b 4d 94             	mov    -0x6c(%ebp),%ecx
	cprintf("Stack backtrace:\n");
	
	while(ebp != 0x00)
		{
			
			cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",ebp,eip,arg[0],arg[1],arg[2],arg[3],arg[4]);
f01007d1:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f01007d5:	89 54 24 18          	mov    %edx,0x18(%esp)
f01007d9:	89 44 24 14          	mov    %eax,0x14(%esp)
f01007dd:	8b 45 a0             	mov    -0x60(%ebp),%eax
f01007e0:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007e4:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f01007e7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007eb:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01007ef:	89 74 24 04          	mov    %esi,0x4(%esp)
f01007f3:	c7 04 24 30 20 10 f0 	movl   $0xf0102030,(%esp)
f01007fa:	e8 3b 02 00 00       	call   f0100a3a <cprintf>
			struct Eipdebuginfo info;
			info.eip_file = "<unknown>";
f01007ff:	c7 45 d0 e4 1e 10 f0 	movl   $0xf0101ee4,-0x30(%ebp)
			info.eip_line = 0;
f0100806:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
			info.eip_fn_name = "<unknown>";
f010080d:	c7 45 d8 e4 1e 10 f0 	movl   $0xf0101ee4,-0x28(%ebp)
			info.eip_fn_namelen = 9;
f0100814:	c7 45 dc 09 00 00 00 	movl   $0x9,-0x24(%ebp)
			info.eip_fn_addr = eip;
f010081b:	89 7d e0             	mov    %edi,-0x20(%ebp)
			info.eip_fn_narg = 0;
f010081e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
			char display_eip_fn_name[30];
			debuginfo_eip(eip,&info);
f0100825:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100829:	89 3c 24             	mov    %edi,(%esp)
f010082c:	e8 03 03 00 00       	call   f0100b34 <debuginfo_eip>
			int i;
			for ( i=0;(info.eip_fn_name[i]!=':')&&( i<30); i++)
f0100831:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0100834:	0f b6 11             	movzbl (%ecx),%edx
f0100837:	b8 00 00 00 00       	mov    $0x0,%eax
f010083c:	80 fa 3a             	cmp    $0x3a,%dl
f010083f:	74 15                	je     f0100856 <mon_backtrace+0xd6>
				display_eip_fn_name[i]=info.eip_fn_name[i];
f0100841:	88 54 05 b2          	mov    %dl,-0x4e(%ebp,%eax,1)
			info.eip_fn_addr = eip;
			info.eip_fn_narg = 0;
			char display_eip_fn_name[30];
			debuginfo_eip(eip,&info);
			int i;
			for ( i=0;(info.eip_fn_name[i]!=':')&&( i<30); i++)
f0100845:	83 c0 01             	add    $0x1,%eax
f0100848:	0f b6 14 01          	movzbl (%ecx,%eax,1),%edx
f010084c:	80 fa 3a             	cmp    $0x3a,%dl
f010084f:	74 05                	je     f0100856 <mon_backtrace+0xd6>
f0100851:	83 f8 1d             	cmp    $0x1d,%eax
f0100854:	7e eb                	jle    f0100841 <mon_backtrace+0xc1>
				display_eip_fn_name[i]=info.eip_fn_name[i];
			display_eip_fn_name[i]='\0';
f0100856:	c6 44 05 b2 00       	movb   $0x0,-0x4e(%ebp,%eax,1)
			cprintf("    %s:%d: %s+%d\n",info.eip_file,info.eip_line,display_eip_fn_name,(eip-info.eip_fn_addr));
f010085b:	2b 7d e0             	sub    -0x20(%ebp),%edi
f010085e:	89 7c 24 10          	mov    %edi,0x10(%esp)
f0100862:	8d 45 b2             	lea    -0x4e(%ebp),%eax
f0100865:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100869:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010086c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100870:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100873:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100877:	c7 04 24 ee 1e 10 f0 	movl   $0xf0101eee,(%esp)
f010087e:	e8 b7 01 00 00       	call   f0100a3a <cprintf>
			ebp = *(uint32_t *)ebp;
f0100883:	8b 36                	mov    (%esi),%esi
			eip = *((uint32_t*)ebp+1);
f0100885:	8b 7e 04             	mov    0x4(%esi),%edi
			arg[0] = *((uint32_t*)ebp+2);
f0100888:	8b 46 08             	mov    0x8(%esi),%eax
f010088b:	89 45 a4             	mov    %eax,-0x5c(%ebp)
			arg[1] = *((uint32_t*)ebp+3);
f010088e:	8b 46 0c             	mov    0xc(%esi),%eax
f0100891:	89 45 a0             	mov    %eax,-0x60(%ebp)
			arg[2] = *((uint32_t*)ebp+4);
f0100894:	8b 46 10             	mov    0x10(%esi),%eax
			arg[3] = *((uint32_t*)ebp+5);
f0100897:	8b 56 14             	mov    0x14(%esi),%edx
			arg[4] = *((uint32_t*)ebp+6);
f010089a:	8b 4e 18             	mov    0x18(%esi),%ecx
	arg[3] = *((uint32_t*)ebp+5);
	arg[4] = *((uint32_t*)ebp+6);

	cprintf("Stack backtrace:\n");
	
	while(ebp != 0x00)
f010089d:	85 f6                	test   %esi,%esi
f010089f:	0f 85 2c ff ff ff    	jne    f01007d1 <mon_backtrace+0x51>
			arg[3] = *((uint32_t*)ebp+5);
			arg[4] = *((uint32_t*)ebp+6);
			
		}
	return 0;
}
f01008a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01008aa:	81 c4 8c 00 00 00    	add    $0x8c,%esp
f01008b0:	5b                   	pop    %ebx
f01008b1:	5e                   	pop    %esi
f01008b2:	5f                   	pop    %edi
f01008b3:	5d                   	pop    %ebp
f01008b4:	c3                   	ret    

f01008b5 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01008b5:	55                   	push   %ebp
f01008b6:	89 e5                	mov    %esp,%ebp
f01008b8:	57                   	push   %edi
f01008b9:	56                   	push   %esi
f01008ba:	53                   	push   %ebx
f01008bb:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01008be:	c7 04 24 64 20 10 f0 	movl   $0xf0102064,(%esp)
f01008c5:	e8 70 01 00 00       	call   f0100a3a <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01008ca:	c7 04 24 88 20 10 f0 	movl   $0xf0102088,(%esp)
f01008d1:	e8 64 01 00 00       	call   f0100a3a <cprintf>


	while (1) {
		buf = readline("K> ");
f01008d6:	c7 04 24 00 1f 10 f0 	movl   $0xf0101f00,(%esp)
f01008dd:	e8 1e 0b 00 00       	call   f0101400 <readline>
f01008e2:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01008e4:	85 c0                	test   %eax,%eax
f01008e6:	74 ee                	je     f01008d6 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01008e8:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01008ef:	be 00 00 00 00       	mov    $0x0,%esi
f01008f4:	eb 06                	jmp    f01008fc <monitor+0x47>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01008f6:	c6 03 00             	movb   $0x0,(%ebx)
f01008f9:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01008fc:	0f b6 03             	movzbl (%ebx),%eax
f01008ff:	84 c0                	test   %al,%al
f0100901:	74 6a                	je     f010096d <monitor+0xb8>
f0100903:	0f be c0             	movsbl %al,%eax
f0100906:	89 44 24 04          	mov    %eax,0x4(%esp)
f010090a:	c7 04 24 04 1f 10 f0 	movl   $0xf0101f04,(%esp)
f0100911:	e8 15 0d 00 00       	call   f010162b <strchr>
f0100916:	85 c0                	test   %eax,%eax
f0100918:	75 dc                	jne    f01008f6 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f010091a:	80 3b 00             	cmpb   $0x0,(%ebx)
f010091d:	74 4e                	je     f010096d <monitor+0xb8>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010091f:	83 fe 0f             	cmp    $0xf,%esi
f0100922:	75 16                	jne    f010093a <monitor+0x85>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100924:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f010092b:	00 
f010092c:	c7 04 24 09 1f 10 f0 	movl   $0xf0101f09,(%esp)
f0100933:	e8 02 01 00 00       	call   f0100a3a <cprintf>
f0100938:	eb 9c                	jmp    f01008d6 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f010093a:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010093e:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f0100941:	0f b6 03             	movzbl (%ebx),%eax
f0100944:	84 c0                	test   %al,%al
f0100946:	75 0c                	jne    f0100954 <monitor+0x9f>
f0100948:	eb b2                	jmp    f01008fc <monitor+0x47>
			buf++;
f010094a:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010094d:	0f b6 03             	movzbl (%ebx),%eax
f0100950:	84 c0                	test   %al,%al
f0100952:	74 a8                	je     f01008fc <monitor+0x47>
f0100954:	0f be c0             	movsbl %al,%eax
f0100957:	89 44 24 04          	mov    %eax,0x4(%esp)
f010095b:	c7 04 24 04 1f 10 f0 	movl   $0xf0101f04,(%esp)
f0100962:	e8 c4 0c 00 00       	call   f010162b <strchr>
f0100967:	85 c0                	test   %eax,%eax
f0100969:	74 df                	je     f010094a <monitor+0x95>
f010096b:	eb 8f                	jmp    f01008fc <monitor+0x47>
			buf++;
	}
	argv[argc] = 0;
f010096d:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100974:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100975:	85 f6                	test   %esi,%esi
f0100977:	0f 84 59 ff ff ff    	je     f01008d6 <monitor+0x21>
f010097d:	bb 00 21 10 f0       	mov    $0xf0102100,%ebx
f0100982:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100987:	8b 03                	mov    (%ebx),%eax
f0100989:	89 44 24 04          	mov    %eax,0x4(%esp)
f010098d:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100990:	89 04 24             	mov    %eax,(%esp)
f0100993:	e8 18 0c 00 00       	call   f01015b0 <strcmp>
f0100998:	85 c0                	test   %eax,%eax
f010099a:	75 24                	jne    f01009c0 <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f010099c:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f010099f:	8b 55 08             	mov    0x8(%ebp),%edx
f01009a2:	89 54 24 08          	mov    %edx,0x8(%esp)
f01009a6:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01009a9:	89 54 24 04          	mov    %edx,0x4(%esp)
f01009ad:	89 34 24             	mov    %esi,(%esp)
f01009b0:	ff 14 85 08 21 10 f0 	call   *-0xfefdef8(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01009b7:	85 c0                	test   %eax,%eax
f01009b9:	78 28                	js     f01009e3 <monitor+0x12e>
f01009bb:	e9 16 ff ff ff       	jmp    f01008d6 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01009c0:	83 c7 01             	add    $0x1,%edi
f01009c3:	83 c3 0c             	add    $0xc,%ebx
f01009c6:	83 ff 03             	cmp    $0x3,%edi
f01009c9:	75 bc                	jne    f0100987 <monitor+0xd2>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01009cb:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01009ce:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009d2:	c7 04 24 26 1f 10 f0 	movl   $0xf0101f26,(%esp)
f01009d9:	e8 5c 00 00 00       	call   f0100a3a <cprintf>
f01009de:	e9 f3 fe ff ff       	jmp    f01008d6 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01009e3:	83 c4 5c             	add    $0x5c,%esp
f01009e6:	5b                   	pop    %ebx
f01009e7:	5e                   	pop    %esi
f01009e8:	5f                   	pop    %edi
f01009e9:	5d                   	pop    %ebp
f01009ea:	c3                   	ret    

f01009eb <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f01009eb:	55                   	push   %ebp
f01009ec:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f01009ee:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f01009f1:	5d                   	pop    %ebp
f01009f2:	c3                   	ret    
	...

f01009f4 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01009f4:	55                   	push   %ebp
f01009f5:	89 e5                	mov    %esp,%ebp
f01009f7:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01009fa:	8b 45 08             	mov    0x8(%ebp),%eax
f01009fd:	89 04 24             	mov    %eax,(%esp)
f0100a00:	e8 5c fc ff ff       	call   f0100661 <cputchar>
	*cnt++;
}
f0100a05:	c9                   	leave  
f0100a06:	c3                   	ret    

f0100a07 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100a07:	55                   	push   %ebp
f0100a08:	89 e5                	mov    %esp,%ebp
f0100a0a:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0100a0d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100a14:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100a17:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a1b:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a1e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100a22:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100a25:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a29:	c7 04 24 f4 09 10 f0 	movl   $0xf01009f4,(%esp)
f0100a30:	e8 b5 04 00 00       	call   f0100eea <vprintfmt>
	return cnt;
}
f0100a35:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100a38:	c9                   	leave  
f0100a39:	c3                   	ret    

f0100a3a <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100a3a:	55                   	push   %ebp
f0100a3b:	89 e5                	mov    %esp,%ebp
f0100a3d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100a40:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100a43:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a47:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a4a:	89 04 24             	mov    %eax,(%esp)
f0100a4d:	e8 b5 ff ff ff       	call   f0100a07 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100a52:	c9                   	leave  
f0100a53:	c3                   	ret    

f0100a54 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a54:	55                   	push   %ebp
f0100a55:	89 e5                	mov    %esp,%ebp
f0100a57:	57                   	push   %edi
f0100a58:	56                   	push   %esi
f0100a59:	53                   	push   %ebx
f0100a5a:	83 ec 10             	sub    $0x10,%esp
f0100a5d:	89 c3                	mov    %eax,%ebx
f0100a5f:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100a62:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100a65:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a68:	8b 0a                	mov    (%edx),%ecx
f0100a6a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a6d:	8b 00                	mov    (%eax),%eax
f0100a6f:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a72:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f0100a79:	eb 77                	jmp    f0100af2 <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f0100a7b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a7e:	01 c8                	add    %ecx,%eax
f0100a80:	bf 02 00 00 00       	mov    $0x2,%edi
f0100a85:	99                   	cltd   
f0100a86:	f7 ff                	idiv   %edi
f0100a88:	89 c2                	mov    %eax,%edx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a8a:	eb 01                	jmp    f0100a8d <stab_binsearch+0x39>
			m--;
f0100a8c:	4a                   	dec    %edx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a8d:	39 ca                	cmp    %ecx,%edx
f0100a8f:	7c 1d                	jl     f0100aae <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100a91:	6b fa 0c             	imul   $0xc,%edx,%edi
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a94:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f0100a99:	39 f7                	cmp    %esi,%edi
f0100a9b:	75 ef                	jne    f0100a8c <stab_binsearch+0x38>
f0100a9d:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100aa0:	6b fa 0c             	imul   $0xc,%edx,%edi
f0100aa3:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f0100aa7:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100aaa:	73 18                	jae    f0100ac4 <stab_binsearch+0x70>
f0100aac:	eb 05                	jmp    f0100ab3 <stab_binsearch+0x5f>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100aae:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0100ab1:	eb 3f                	jmp    f0100af2 <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100ab3:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100ab6:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0100ab8:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100abb:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100ac2:	eb 2e                	jmp    f0100af2 <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100ac4:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100ac7:	76 15                	jbe    f0100ade <stab_binsearch+0x8a>
			*region_right = m - 1;
f0100ac9:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100acc:	4f                   	dec    %edi
f0100acd:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0100ad0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ad3:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100ad5:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100adc:	eb 14                	jmp    f0100af2 <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100ade:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100ae1:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100ae4:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f0100ae6:	ff 45 0c             	incl   0xc(%ebp)
f0100ae9:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100aeb:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0100af2:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0100af5:	7e 84                	jle    f0100a7b <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100af7:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100afb:	75 0d                	jne    f0100b0a <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0100afd:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100b00:	8b 02                	mov    (%edx),%eax
f0100b02:	48                   	dec    %eax
f0100b03:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100b06:	89 01                	mov    %eax,(%ecx)
f0100b08:	eb 22                	jmp    f0100b2c <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b0a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100b0d:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100b0f:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100b12:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b14:	eb 01                	jmp    f0100b17 <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100b16:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b17:	39 c1                	cmp    %eax,%ecx
f0100b19:	7d 0c                	jge    f0100b27 <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100b1b:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0100b1e:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f0100b23:	39 f2                	cmp    %esi,%edx
f0100b25:	75 ef                	jne    f0100b16 <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100b27:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100b2a:	89 02                	mov    %eax,(%edx)
	}
}
f0100b2c:	83 c4 10             	add    $0x10,%esp
f0100b2f:	5b                   	pop    %ebx
f0100b30:	5e                   	pop    %esi
f0100b31:	5f                   	pop    %edi
f0100b32:	5d                   	pop    %ebp
f0100b33:	c3                   	ret    

f0100b34 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100b34:	55                   	push   %ebp
f0100b35:	89 e5                	mov    %esp,%ebp
f0100b37:	83 ec 58             	sub    $0x58,%esp
f0100b3a:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100b3d:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100b40:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100b43:	8b 75 08             	mov    0x8(%ebp),%esi
f0100b46:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100b49:	c7 03 e4 1e 10 f0    	movl   $0xf0101ee4,(%ebx)
	info->eip_line = 0;
f0100b4f:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100b56:	c7 43 08 e4 1e 10 f0 	movl   $0xf0101ee4,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100b5d:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100b64:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100b67:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b6e:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100b74:	76 12                	jbe    f0100b88 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b76:	b8 55 7b 10 f0       	mov    $0xf0107b55,%eax
f0100b7b:	3d 31 61 10 f0       	cmp    $0xf0106131,%eax
f0100b80:	0f 86 e8 01 00 00    	jbe    f0100d6e <debuginfo_eip+0x23a>
f0100b86:	eb 1c                	jmp    f0100ba4 <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100b88:	c7 44 24 08 24 21 10 	movl   $0xf0102124,0x8(%esp)
f0100b8f:	f0 
f0100b90:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100b97:	00 
f0100b98:	c7 04 24 31 21 10 f0 	movl   $0xf0102131,(%esp)
f0100b9f:	e8 60 f5 ff ff       	call   f0100104 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100ba4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100ba9:	80 3d 54 7b 10 f0 00 	cmpb   $0x0,0xf0107b54
f0100bb0:	0f 85 c4 01 00 00    	jne    f0100d7a <debuginfo_eip+0x246>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100bb6:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100bbd:	b8 30 61 10 f0       	mov    $0xf0106130,%eax
f0100bc2:	2d 50 23 10 f0       	sub    $0xf0102350,%eax
f0100bc7:	c1 f8 02             	sar    $0x2,%eax
f0100bca:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100bd0:	83 e8 01             	sub    $0x1,%eax
f0100bd3:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100bd6:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100bda:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100be1:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100be4:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100be7:	b8 50 23 10 f0       	mov    $0xf0102350,%eax
f0100bec:	e8 63 fe ff ff       	call   f0100a54 <stab_binsearch>
	if (lfile == 0)
f0100bf1:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0100bf4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0100bf9:	85 d2                	test   %edx,%edx
f0100bfb:	0f 84 79 01 00 00    	je     f0100d7a <debuginfo_eip+0x246>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100c01:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0100c04:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c07:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100c0a:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c0e:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100c15:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100c18:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c1b:	b8 50 23 10 f0       	mov    $0xf0102350,%eax
f0100c20:	e8 2f fe ff ff       	call   f0100a54 <stab_binsearch>

	if (lfun <= rfun) {
f0100c25:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100c28:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100c2b:	39 d0                	cmp    %edx,%eax
f0100c2d:	7f 3d                	jg     f0100c6c <debuginfo_eip+0x138>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100c2f:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100c32:	8d b9 50 23 10 f0    	lea    -0xfefdcb0(%ecx),%edi
f0100c38:	89 7d c0             	mov    %edi,-0x40(%ebp)
f0100c3b:	8b 89 50 23 10 f0    	mov    -0xfefdcb0(%ecx),%ecx
f0100c41:	bf 55 7b 10 f0       	mov    $0xf0107b55,%edi
f0100c46:	81 ef 31 61 10 f0    	sub    $0xf0106131,%edi
f0100c4c:	39 f9                	cmp    %edi,%ecx
f0100c4e:	73 09                	jae    f0100c59 <debuginfo_eip+0x125>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100c50:	81 c1 31 61 10 f0    	add    $0xf0106131,%ecx
f0100c56:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100c59:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0100c5c:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100c5f:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100c62:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100c64:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100c67:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100c6a:	eb 0f                	jmp    f0100c7b <debuginfo_eip+0x147>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100c6c:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100c6f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c72:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100c75:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c78:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c7b:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100c82:	00 
f0100c83:	8b 43 08             	mov    0x8(%ebx),%eax
f0100c86:	89 04 24             	mov    %eax,(%esp)
f0100c89:	e8 d1 09 00 00       	call   f010165f <strfind>
f0100c8e:	2b 43 08             	sub    0x8(%ebx),%eax
f0100c91:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100c94:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c98:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100c9f:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100ca2:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100ca5:	b8 50 23 10 f0       	mov    $0xf0102350,%eax
f0100caa:	e8 a5 fd ff ff       	call   f0100a54 <stab_binsearch>

	
	if (lline <= rline) {
f0100caf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100cb2:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0100cb5:	7f 0d                	jg     f0100cc4 <debuginfo_eip+0x190>
	info->eip_line = stabs[lline].n_desc;
f0100cb7:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100cba:	0f b7 80 56 23 10 f0 	movzwl -0xfefdcaa(%eax),%eax
f0100cc1:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100cc4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100cc7:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100cca:	39 c8                	cmp    %ecx,%eax
f0100ccc:	7c 5f                	jl     f0100d2d <debuginfo_eip+0x1f9>
	       && stabs[lline].n_type != N_SOL
f0100cce:	89 c2                	mov    %eax,%edx
f0100cd0:	6b f0 0c             	imul   $0xc,%eax,%esi
f0100cd3:	80 be 54 23 10 f0 84 	cmpb   $0x84,-0xfefdcac(%esi)
f0100cda:	75 18                	jne    f0100cf4 <debuginfo_eip+0x1c0>
f0100cdc:	eb 30                	jmp    f0100d0e <debuginfo_eip+0x1da>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100cde:	83 e8 01             	sub    $0x1,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100ce1:	39 c1                	cmp    %eax,%ecx
f0100ce3:	7f 48                	jg     f0100d2d <debuginfo_eip+0x1f9>
	       && stabs[lline].n_type != N_SOL
f0100ce5:	89 c2                	mov    %eax,%edx
f0100ce7:	8d 34 40             	lea    (%eax,%eax,2),%esi
f0100cea:	80 3c b5 54 23 10 f0 	cmpb   $0x84,-0xfefdcac(,%esi,4)
f0100cf1:	84 
f0100cf2:	74 1a                	je     f0100d0e <debuginfo_eip+0x1da>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100cf4:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100cf7:	8d 14 95 50 23 10 f0 	lea    -0xfefdcb0(,%edx,4),%edx
f0100cfe:	80 7a 04 64          	cmpb   $0x64,0x4(%edx)
f0100d02:	75 da                	jne    f0100cde <debuginfo_eip+0x1aa>
f0100d04:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0100d08:	74 d4                	je     f0100cde <debuginfo_eip+0x1aa>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100d0a:	39 c8                	cmp    %ecx,%eax
f0100d0c:	7c 1f                	jl     f0100d2d <debuginfo_eip+0x1f9>
f0100d0e:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100d11:	8b 80 50 23 10 f0    	mov    -0xfefdcb0(%eax),%eax
f0100d17:	ba 55 7b 10 f0       	mov    $0xf0107b55,%edx
f0100d1c:	81 ea 31 61 10 f0    	sub    $0xf0106131,%edx
f0100d22:	39 d0                	cmp    %edx,%eax
f0100d24:	73 07                	jae    f0100d2d <debuginfo_eip+0x1f9>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100d26:	05 31 61 10 f0       	add    $0xf0106131,%eax
f0100d2b:	89 03                	mov    %eax,(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100d2d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100d30:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100d33:	b8 00 00 00 00       	mov    $0x0,%eax
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100d38:	39 ca                	cmp    %ecx,%edx
f0100d3a:	7d 3e                	jge    f0100d7a <debuginfo_eip+0x246>
		for (lline = lfun + 1;
f0100d3c:	83 c2 01             	add    $0x1,%edx
f0100d3f:	39 d1                	cmp    %edx,%ecx
f0100d41:	7e 37                	jle    f0100d7a <debuginfo_eip+0x246>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100d43:	6b f2 0c             	imul   $0xc,%edx,%esi
f0100d46:	80 be 54 23 10 f0 a0 	cmpb   $0xa0,-0xfefdcac(%esi)
f0100d4d:	75 2b                	jne    f0100d7a <debuginfo_eip+0x246>
		     lline++)
			info->eip_fn_narg++;
f0100d4f:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100d53:	83 c2 01             	add    $0x1,%edx
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100d56:	39 d1                	cmp    %edx,%ecx
f0100d58:	7e 1b                	jle    f0100d75 <debuginfo_eip+0x241>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100d5a:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100d5d:	80 3c 85 54 23 10 f0 	cmpb   $0xa0,-0xfefdcac(,%eax,4)
f0100d64:	a0 
f0100d65:	74 e8                	je     f0100d4f <debuginfo_eip+0x21b>
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100d67:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d6c:	eb 0c                	jmp    f0100d7a <debuginfo_eip+0x246>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100d6e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d73:	eb 05                	jmp    f0100d7a <debuginfo_eip+0x246>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100d75:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100d7a:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100d7d:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100d80:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100d83:	89 ec                	mov    %ebp,%esp
f0100d85:	5d                   	pop    %ebp
f0100d86:	c3                   	ret    
	...

f0100d90 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d90:	55                   	push   %ebp
f0100d91:	89 e5                	mov    %esp,%ebp
f0100d93:	57                   	push   %edi
f0100d94:	56                   	push   %esi
f0100d95:	53                   	push   %ebx
f0100d96:	83 ec 3c             	sub    $0x3c,%esp
f0100d99:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100d9c:	89 d7                	mov    %edx,%edi
f0100d9e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100da1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100da4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100da7:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100daa:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100dad:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100db0:	b8 00 00 00 00       	mov    $0x0,%eax
f0100db5:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100db8:	72 11                	jb     f0100dcb <printnum+0x3b>
f0100dba:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100dbd:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100dc0:	76 09                	jbe    f0100dcb <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100dc2:	83 eb 01             	sub    $0x1,%ebx
f0100dc5:	85 db                	test   %ebx,%ebx
f0100dc7:	7f 51                	jg     f0100e1a <printnum+0x8a>
f0100dc9:	eb 5e                	jmp    f0100e29 <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100dcb:	89 74 24 10          	mov    %esi,0x10(%esp)
f0100dcf:	83 eb 01             	sub    $0x1,%ebx
f0100dd2:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100dd6:	8b 45 10             	mov    0x10(%ebp),%eax
f0100dd9:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100ddd:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0100de1:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0100de5:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100dec:	00 
f0100ded:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100df0:	89 04 24             	mov    %eax,(%esp)
f0100df3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100df6:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100dfa:	e8 e1 0a 00 00       	call   f01018e0 <__udivdi3>
f0100dff:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100e03:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100e07:	89 04 24             	mov    %eax,(%esp)
f0100e0a:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100e0e:	89 fa                	mov    %edi,%edx
f0100e10:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e13:	e8 78 ff ff ff       	call   f0100d90 <printnum>
f0100e18:	eb 0f                	jmp    f0100e29 <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100e1a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e1e:	89 34 24             	mov    %esi,(%esp)
f0100e21:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100e24:	83 eb 01             	sub    $0x1,%ebx
f0100e27:	75 f1                	jne    f0100e1a <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100e29:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e2d:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100e31:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e34:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e38:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100e3f:	00 
f0100e40:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100e43:	89 04 24             	mov    %eax,(%esp)
f0100e46:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e49:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e4d:	e8 be 0b 00 00       	call   f0101a10 <__umoddi3>
f0100e52:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e56:	0f be 80 3f 21 10 f0 	movsbl -0xfefdec1(%eax),%eax
f0100e5d:	89 04 24             	mov    %eax,(%esp)
f0100e60:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0100e63:	83 c4 3c             	add    $0x3c,%esp
f0100e66:	5b                   	pop    %ebx
f0100e67:	5e                   	pop    %esi
f0100e68:	5f                   	pop    %edi
f0100e69:	5d                   	pop    %ebp
f0100e6a:	c3                   	ret    

f0100e6b <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100e6b:	55                   	push   %ebp
f0100e6c:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100e6e:	83 fa 01             	cmp    $0x1,%edx
f0100e71:	7e 0e                	jle    f0100e81 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100e73:	8b 10                	mov    (%eax),%edx
f0100e75:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100e78:	89 08                	mov    %ecx,(%eax)
f0100e7a:	8b 02                	mov    (%edx),%eax
f0100e7c:	8b 52 04             	mov    0x4(%edx),%edx
f0100e7f:	eb 22                	jmp    f0100ea3 <getuint+0x38>
	else if (lflag)
f0100e81:	85 d2                	test   %edx,%edx
f0100e83:	74 10                	je     f0100e95 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100e85:	8b 10                	mov    (%eax),%edx
f0100e87:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e8a:	89 08                	mov    %ecx,(%eax)
f0100e8c:	8b 02                	mov    (%edx),%eax
f0100e8e:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e93:	eb 0e                	jmp    f0100ea3 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100e95:	8b 10                	mov    (%eax),%edx
f0100e97:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e9a:	89 08                	mov    %ecx,(%eax)
f0100e9c:	8b 02                	mov    (%edx),%eax
f0100e9e:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100ea3:	5d                   	pop    %ebp
f0100ea4:	c3                   	ret    

f0100ea5 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100ea5:	55                   	push   %ebp
f0100ea6:	89 e5                	mov    %esp,%ebp
f0100ea8:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100eab:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100eaf:	8b 10                	mov    (%eax),%edx
f0100eb1:	3b 50 04             	cmp    0x4(%eax),%edx
f0100eb4:	73 0a                	jae    f0100ec0 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100eb6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100eb9:	88 0a                	mov    %cl,(%edx)
f0100ebb:	83 c2 01             	add    $0x1,%edx
f0100ebe:	89 10                	mov    %edx,(%eax)
}
f0100ec0:	5d                   	pop    %ebp
f0100ec1:	c3                   	ret    

f0100ec2 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100ec2:	55                   	push   %ebp
f0100ec3:	89 e5                	mov    %esp,%ebp
f0100ec5:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100ec8:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100ecb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ecf:	8b 45 10             	mov    0x10(%ebp),%eax
f0100ed2:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100ed6:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ed9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100edd:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ee0:	89 04 24             	mov    %eax,(%esp)
f0100ee3:	e8 02 00 00 00       	call   f0100eea <vprintfmt>
	va_end(ap);
}
f0100ee8:	c9                   	leave  
f0100ee9:	c3                   	ret    

f0100eea <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100eea:	55                   	push   %ebp
f0100eeb:	89 e5                	mov    %esp,%ebp
f0100eed:	57                   	push   %edi
f0100eee:	56                   	push   %esi
f0100eef:	53                   	push   %ebx
f0100ef0:	83 ec 3c             	sub    $0x3c,%esp
f0100ef3:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100ef6:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100ef9:	e9 bb 00 00 00       	jmp    f0100fb9 <vprintfmt+0xcf>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100efe:	85 c0                	test   %eax,%eax
f0100f00:	0f 84 63 04 00 00    	je     f0101369 <vprintfmt+0x47f>
				return;
			if (ch =='\033'){//if this is Escape character  and this if is char color set.
f0100f06:	83 f8 1b             	cmp    $0x1b,%eax
f0100f09:	0f 85 9a 00 00 00    	jne    f0100fa9 <vprintfmt+0xbf>
				int temp_color_no=0;
				ch = *(unsigned char *) fmt++;
f0100f0f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100f12:	83 c3 02             	add    $0x2,%ebx
				while (ch != 'm') 
f0100f15:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100f18:	80 78 01 6d          	cmpb   $0x6d,0x1(%eax)
f0100f1c:	0f 84 81 00 00 00    	je     f0100fa3 <vprintfmt+0xb9>
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
				return;
			if (ch =='\033'){//if this is Escape character  and this if is char color set.
				int temp_color_no=0;
f0100f22:	ba 00 00 00 00       	mov    $0x0,%edx
				ch = *(unsigned char *) fmt++;
				while (ch != 'm') 
				{
					ch = *(unsigned char *) fmt++;
f0100f27:	0f b6 03             	movzbl (%ebx),%eax
f0100f2a:	83 c3 01             	add    $0x1,%ebx
					if ( ch !=';' && ch!='m')
f0100f2d:	83 f8 6d             	cmp    $0x6d,%eax
f0100f30:	0f 95 c1             	setne  %cl
f0100f33:	83 f8 3b             	cmp    $0x3b,%eax
f0100f36:	74 0d                	je     f0100f45 <vprintfmt+0x5b>
f0100f38:	84 c9                	test   %cl,%cl
f0100f3a:	74 09                	je     f0100f45 <vprintfmt+0x5b>
						temp_color_no=temp_color_no*10+ch-'0';
f0100f3c:	8d 14 92             	lea    (%edx,%edx,4),%edx
f0100f3f:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
f0100f43:	eb 55                	jmp    f0100f9a <vprintfmt+0xb0>
					else if ( ch==';' || ch=='m'){
f0100f45:	83 f8 3b             	cmp    $0x3b,%eax
f0100f48:	74 05                	je     f0100f4f <vprintfmt+0x65>
f0100f4a:	83 f8 6d             	cmp    $0x6d,%eax
f0100f4d:	75 4b                	jne    f0100f9a <vprintfmt+0xb0>
						if ( temp_color_no >=30 && temp_color_no<40){// Foreground colors
f0100f4f:	89 d6                	mov    %edx,%esi
f0100f51:	8d 7a e2             	lea    -0x1e(%edx),%edi
f0100f54:	83 ff 09             	cmp    $0x9,%edi
f0100f57:	77 16                	ja     f0100f6f <vprintfmt+0x85>
							char_color = (char_color&0xf0) + (temp_color_no-30);						
f0100f59:	8b 3d 00 23 11 f0    	mov    0xf0112300,%edi
f0100f5f:	81 e7 f0 00 00 00    	and    $0xf0,%edi
f0100f65:	8d 7c 3a e2          	lea    -0x1e(%edx,%edi,1),%edi
f0100f69:	89 3d 00 23 11 f0    	mov    %edi,0xf0112300
							}
						if ( temp_color_no >=40 && temp_color_no<50){// Background colors
f0100f6f:	83 ee 28             	sub    $0x28,%esi
f0100f72:	83 fe 09             	cmp    $0x9,%esi
f0100f75:	77 1e                	ja     f0100f95 <vprintfmt+0xab>
							char_color = (char_color&0x0f) + ((temp_color_no-40)<<4);
f0100f77:	8b 35 00 23 11 f0    	mov    0xf0112300,%esi
f0100f7d:	83 e6 0f             	and    $0xf,%esi
f0100f80:	83 ea 28             	sub    $0x28,%edx
f0100f83:	c1 e2 04             	shl    $0x4,%edx
f0100f86:	01 f2                	add    %esi,%edx
f0100f88:	89 15 00 23 11 f0    	mov    %edx,0xf0112300
						}
						//cprintf("0x%o ,",char_color);
						temp_color_no=0;
f0100f8e:	ba 00 00 00 00       	mov    $0x0,%edx
f0100f93:	eb 05                	jmp    f0100f9a <vprintfmt+0xb0>
f0100f95:	ba 00 00 00 00       	mov    $0x0,%edx
			if (ch == '\0')
				return;
			if (ch =='\033'){//if this is Escape character  and this if is char color set.
				int temp_color_no=0;
				ch = *(unsigned char *) fmt++;
				while (ch != 'm') 
f0100f9a:	84 c9                	test   %cl,%cl
f0100f9c:	75 89                	jne    f0100f27 <vprintfmt+0x3d>
						}
						//cprintf("0x%o ,",char_color);
						temp_color_no=0;
					}
				}
				if (ch == 'm')
f0100f9e:	83 f8 6d             	cmp    $0x6d,%eax
f0100fa1:	75 06                	jne    f0100fa9 <vprintfmt+0xbf>
					ch = *(unsigned char *) fmt++;
f0100fa3:	0f b6 03             	movzbl (%ebx),%eax
f0100fa6:	83 c3 01             	add    $0x1,%ebx
				
			}
			putch(ch, putdat);
f0100fa9:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100fac:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100fb0:	89 04 24             	mov    %eax,(%esp)
f0100fb3:	ff 55 08             	call   *0x8(%ebp)
f0100fb6:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100fb9:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100fbc:	0f b6 03             	movzbl (%ebx),%eax
f0100fbf:	83 c3 01             	add    $0x1,%ebx
f0100fc2:	83 f8 25             	cmp    $0x25,%eax
f0100fc5:	0f 85 33 ff ff ff    	jne    f0100efe <vprintfmt+0x14>
f0100fcb:	c6 45 e0 20          	movb   $0x20,-0x20(%ebp)
f0100fcf:	bf 00 00 00 00       	mov    $0x0,%edi
f0100fd4:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0100fd9:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0100fe0:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100fe5:	eb 23                	jmp    f010100a <vprintfmt+0x120>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fe7:	89 c3                	mov    %eax,%ebx

		// flag to pad on the right
		case '-':
			padc = '-';
f0100fe9:	c6 45 e0 2d          	movb   $0x2d,-0x20(%ebp)
f0100fed:	eb 1b                	jmp    f010100a <vprintfmt+0x120>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fef:	89 c3                	mov    %eax,%ebx
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100ff1:	c6 45 e0 30          	movb   $0x30,-0x20(%ebp)
f0100ff5:	eb 13                	jmp    f010100a <vprintfmt+0x120>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ff7:	89 c3                	mov    %eax,%ebx
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0100ff9:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0101000:	eb 08                	jmp    f010100a <vprintfmt+0x120>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0101002:	89 75 dc             	mov    %esi,-0x24(%ebp)
f0101005:	be ff ff ff ff       	mov    $0xffffffff,%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010100a:	0f b6 13             	movzbl (%ebx),%edx
f010100d:	0f b6 c2             	movzbl %dl,%eax
f0101010:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101013:	8d 43 01             	lea    0x1(%ebx),%eax
f0101016:	83 ea 23             	sub    $0x23,%edx
f0101019:	80 fa 55             	cmp    $0x55,%dl
f010101c:	0f 87 18 03 00 00    	ja     f010133a <vprintfmt+0x450>
f0101022:	0f b6 d2             	movzbl %dl,%edx
f0101025:	ff 24 95 cc 21 10 f0 	jmp    *-0xfefde34(,%edx,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f010102c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010102f:	83 ee 30             	sub    $0x30,%esi
				ch = *fmt;
f0101032:	0f be 53 01          	movsbl 0x1(%ebx),%edx
				if (ch < '0' || ch > '9')
f0101036:	8d 5a d0             	lea    -0x30(%edx),%ebx
f0101039:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010103c:	89 c3                	mov    %eax,%ebx
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f010103e:	83 7d e4 09          	cmpl   $0x9,-0x1c(%ebp)
f0101042:	77 3b                	ja     f010107f <vprintfmt+0x195>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0101044:	83 c0 01             	add    $0x1,%eax
				precision = precision * 10 + ch - '0';
f0101047:	8d 1c b6             	lea    (%esi,%esi,4),%ebx
f010104a:	8d 74 5a d0          	lea    -0x30(%edx,%ebx,2),%esi
				ch = *fmt;
f010104e:	0f be 10             	movsbl (%eax),%edx
				if (ch < '0' || ch > '9')
f0101051:	8d 5a d0             	lea    -0x30(%edx),%ebx
f0101054:	83 fb 09             	cmp    $0x9,%ebx
f0101057:	76 eb                	jbe    f0101044 <vprintfmt+0x15a>
f0101059:	eb 22                	jmp    f010107d <vprintfmt+0x193>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f010105b:	8b 55 14             	mov    0x14(%ebp),%edx
f010105e:	8d 5a 04             	lea    0x4(%edx),%ebx
f0101061:	89 5d 14             	mov    %ebx,0x14(%ebp)
f0101064:	8b 32                	mov    (%edx),%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101066:	89 c3                	mov    %eax,%ebx
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0101068:	eb 15                	jmp    f010107f <vprintfmt+0x195>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010106a:	89 c3                	mov    %eax,%ebx
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f010106c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101070:	79 98                	jns    f010100a <vprintfmt+0x120>
f0101072:	eb 83                	jmp    f0100ff7 <vprintfmt+0x10d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101074:	89 c3                	mov    %eax,%ebx
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0101076:	bf 01 00 00 00       	mov    $0x1,%edi
			goto reswitch;
f010107b:	eb 8d                	jmp    f010100a <vprintfmt+0x120>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f010107d:	89 c3                	mov    %eax,%ebx
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f010107f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101083:	79 85                	jns    f010100a <vprintfmt+0x120>
f0101085:	e9 78 ff ff ff       	jmp    f0101002 <vprintfmt+0x118>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f010108a:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010108d:	89 c3                	mov    %eax,%ebx
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010108f:	e9 76 ff ff ff       	jmp    f010100a <vprintfmt+0x120>
f0101094:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0101097:	8b 45 14             	mov    0x14(%ebp),%eax
f010109a:	8d 50 04             	lea    0x4(%eax),%edx
f010109d:	89 55 14             	mov    %edx,0x14(%ebp)
f01010a0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01010a3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010a7:	8b 00                	mov    (%eax),%eax
f01010a9:	89 04 24             	mov    %eax,(%esp)
f01010ac:	ff 55 08             	call   *0x8(%ebp)
			break;
f01010af:	e9 05 ff ff ff       	jmp    f0100fb9 <vprintfmt+0xcf>
f01010b4:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// error message
		case 'e':
			err = va_arg(ap, int);
f01010b7:	8b 45 14             	mov    0x14(%ebp),%eax
f01010ba:	8d 50 04             	lea    0x4(%eax),%edx
f01010bd:	89 55 14             	mov    %edx,0x14(%ebp)
f01010c0:	8b 00                	mov    (%eax),%eax
f01010c2:	89 c2                	mov    %eax,%edx
f01010c4:	c1 fa 1f             	sar    $0x1f,%edx
f01010c7:	31 d0                	xor    %edx,%eax
f01010c9:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01010cb:	83 f8 06             	cmp    $0x6,%eax
f01010ce:	7f 0b                	jg     f01010db <vprintfmt+0x1f1>
f01010d0:	8b 14 85 24 23 10 f0 	mov    -0xfefdcdc(,%eax,4),%edx
f01010d7:	85 d2                	test   %edx,%edx
f01010d9:	75 23                	jne    f01010fe <vprintfmt+0x214>
				printfmt(putch, putdat, "error %d", err);
f01010db:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01010df:	c7 44 24 08 57 21 10 	movl   $0xf0102157,0x8(%esp)
f01010e6:	f0 
f01010e7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01010ea:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010ee:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01010f1:	89 1c 24             	mov    %ebx,(%esp)
f01010f4:	e8 c9 fd ff ff       	call   f0100ec2 <printfmt>
f01010f9:	e9 bb fe ff ff       	jmp    f0100fb9 <vprintfmt+0xcf>
			else
				printfmt(putch, putdat, "%s", p);
f01010fe:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101102:	c7 44 24 08 60 21 10 	movl   $0xf0102160,0x8(%esp)
f0101109:	f0 
f010110a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010110d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101111:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101114:	89 1c 24             	mov    %ebx,(%esp)
f0101117:	e8 a6 fd ff ff       	call   f0100ec2 <printfmt>
f010111c:	e9 98 fe ff ff       	jmp    f0100fb9 <vprintfmt+0xcf>
f0101121:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101124:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0101127:	89 5d d8             	mov    %ebx,-0x28(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010112a:	8b 45 14             	mov    0x14(%ebp),%eax
f010112d:	8d 50 04             	lea    0x4(%eax),%edx
f0101130:	89 55 14             	mov    %edx,0x14(%ebp)
f0101133:	8b 18                	mov    (%eax),%ebx
				p = "(null)";
f0101135:	85 db                	test   %ebx,%ebx
f0101137:	b8 50 21 10 f0       	mov    $0xf0102150,%eax
f010113c:	0f 44 d8             	cmove  %eax,%ebx
			if (width > 0 && padc != '-')
f010113f:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101143:	7e 06                	jle    f010114b <vprintfmt+0x261>
f0101145:	80 7d e0 2d          	cmpb   $0x2d,-0x20(%ebp)
f0101149:	75 10                	jne    f010115b <vprintfmt+0x271>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010114b:	0f be 03             	movsbl (%ebx),%eax
f010114e:	83 c3 01             	add    $0x1,%ebx
f0101151:	85 c0                	test   %eax,%eax
f0101153:	0f 85 82 00 00 00    	jne    f01011db <vprintfmt+0x2f1>
f0101159:	eb 75                	jmp    f01011d0 <vprintfmt+0x2e6>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010115b:	89 74 24 04          	mov    %esi,0x4(%esp)
f010115f:	89 1c 24             	mov    %ebx,(%esp)
f0101162:	e8 84 03 00 00       	call   f01014eb <strnlen>
f0101167:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010116a:	29 c2                	sub    %eax,%edx
f010116c:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010116f:	85 d2                	test   %edx,%edx
f0101171:	7e d8                	jle    f010114b <vprintfmt+0x261>
					putch(padc, putdat);
f0101173:	0f be 45 e0          	movsbl -0x20(%ebp),%eax
f0101177:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010117a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010117d:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101181:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101184:	89 04 24             	mov    %eax,(%esp)
f0101187:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010118a:	83 6d dc 01          	subl   $0x1,-0x24(%ebp)
f010118e:	75 ea                	jne    f010117a <vprintfmt+0x290>
f0101190:	eb b9                	jmp    f010114b <vprintfmt+0x261>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0101192:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101196:	74 1b                	je     f01011b3 <vprintfmt+0x2c9>
f0101198:	8d 50 e0             	lea    -0x20(%eax),%edx
f010119b:	83 fa 5e             	cmp    $0x5e,%edx
f010119e:	76 13                	jbe    f01011b3 <vprintfmt+0x2c9>
					putch('?', putdat);
f01011a0:	8b 55 0c             	mov    0xc(%ebp),%edx
f01011a3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01011a7:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01011ae:	ff 55 08             	call   *0x8(%ebp)
f01011b1:	eb 0d                	jmp    f01011c0 <vprintfmt+0x2d6>
				else
					putch(ch, putdat);
f01011b3:	8b 55 0c             	mov    0xc(%ebp),%edx
f01011b6:	89 54 24 04          	mov    %edx,0x4(%esp)
f01011ba:	89 04 24             	mov    %eax,(%esp)
f01011bd:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01011c0:	83 ef 01             	sub    $0x1,%edi
f01011c3:	0f be 03             	movsbl (%ebx),%eax
f01011c6:	83 c3 01             	add    $0x1,%ebx
f01011c9:	85 c0                	test   %eax,%eax
f01011cb:	75 14                	jne    f01011e1 <vprintfmt+0x2f7>
f01011cd:	89 7d dc             	mov    %edi,-0x24(%ebp)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01011d0:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01011d4:	7f 19                	jg     f01011ef <vprintfmt+0x305>
f01011d6:	e9 de fd ff ff       	jmp    f0100fb9 <vprintfmt+0xcf>
f01011db:	89 7d e0             	mov    %edi,-0x20(%ebp)
f01011de:	8b 7d dc             	mov    -0x24(%ebp),%edi
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01011e1:	85 f6                	test   %esi,%esi
f01011e3:	78 ad                	js     f0101192 <vprintfmt+0x2a8>
f01011e5:	83 ee 01             	sub    $0x1,%esi
f01011e8:	79 a8                	jns    f0101192 <vprintfmt+0x2a8>
f01011ea:	89 7d dc             	mov    %edi,-0x24(%ebp)
f01011ed:	eb e1                	jmp    f01011d0 <vprintfmt+0x2e6>
f01011ef:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01011f2:	8b 7d 08             	mov    0x8(%ebp),%edi
f01011f5:	8b 75 0c             	mov    0xc(%ebp),%esi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01011f8:	89 74 24 04          	mov    %esi,0x4(%esp)
f01011fc:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101203:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101205:	83 eb 01             	sub    $0x1,%ebx
f0101208:	75 ee                	jne    f01011f8 <vprintfmt+0x30e>
f010120a:	e9 aa fd ff ff       	jmp    f0100fb9 <vprintfmt+0xcf>
f010120f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101212:	83 f9 01             	cmp    $0x1,%ecx
f0101215:	7e 10                	jle    f0101227 <vprintfmt+0x33d>
		return va_arg(*ap, long long);
f0101217:	8b 45 14             	mov    0x14(%ebp),%eax
f010121a:	8d 50 08             	lea    0x8(%eax),%edx
f010121d:	89 55 14             	mov    %edx,0x14(%ebp)
f0101220:	8b 30                	mov    (%eax),%esi
f0101222:	8b 78 04             	mov    0x4(%eax),%edi
f0101225:	eb 26                	jmp    f010124d <vprintfmt+0x363>
	else if (lflag)
f0101227:	85 c9                	test   %ecx,%ecx
f0101229:	74 12                	je     f010123d <vprintfmt+0x353>
		return va_arg(*ap, long);
f010122b:	8b 45 14             	mov    0x14(%ebp),%eax
f010122e:	8d 50 04             	lea    0x4(%eax),%edx
f0101231:	89 55 14             	mov    %edx,0x14(%ebp)
f0101234:	8b 30                	mov    (%eax),%esi
f0101236:	89 f7                	mov    %esi,%edi
f0101238:	c1 ff 1f             	sar    $0x1f,%edi
f010123b:	eb 10                	jmp    f010124d <vprintfmt+0x363>
	else
		return va_arg(*ap, int);
f010123d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101240:	8d 50 04             	lea    0x4(%eax),%edx
f0101243:	89 55 14             	mov    %edx,0x14(%ebp)
f0101246:	8b 30                	mov    (%eax),%esi
f0101248:	89 f7                	mov    %esi,%edi
f010124a:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010124d:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101252:	85 ff                	test   %edi,%edi
f0101254:	0f 89 9e 00 00 00    	jns    f01012f8 <vprintfmt+0x40e>
				putch('-', putdat);
f010125a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010125d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101261:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0101268:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010126b:	f7 de                	neg    %esi
f010126d:	83 d7 00             	adc    $0x0,%edi
f0101270:	f7 df                	neg    %edi
			}
			base = 10;
f0101272:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101277:	eb 7f                	jmp    f01012f8 <vprintfmt+0x40e>
f0101279:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f010127c:	89 ca                	mov    %ecx,%edx
f010127e:	8d 45 14             	lea    0x14(%ebp),%eax
f0101281:	e8 e5 fb ff ff       	call   f0100e6b <getuint>
f0101286:	89 c6                	mov    %eax,%esi
f0101288:	89 d7                	mov    %edx,%edi
			base = 10;
f010128a:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f010128f:	eb 67                	jmp    f01012f8 <vprintfmt+0x40e>
f0101291:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap,lflag);
f0101294:	89 ca                	mov    %ecx,%edx
f0101296:	8d 45 14             	lea    0x14(%ebp),%eax
f0101299:	e8 cd fb ff ff       	call   f0100e6b <getuint>
f010129e:	89 c6                	mov    %eax,%esi
f01012a0:	89 d7                	mov    %edx,%edi
			base = 8;
f01012a2:	b8 08 00 00 00       	mov    $0x8,%eax

			goto number;
f01012a7:	eb 4f                	jmp    f01012f8 <vprintfmt+0x40e>
f01012a9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// pointer
		case 'p':
			putch('0', putdat);
f01012ac:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01012af:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01012b3:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01012ba:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01012bd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01012c1:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01012c8:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01012cb:	8b 45 14             	mov    0x14(%ebp),%eax
f01012ce:	8d 50 04             	lea    0x4(%eax),%edx
f01012d1:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01012d4:	8b 30                	mov    (%eax),%esi
f01012d6:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01012db:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f01012e0:	eb 16                	jmp    f01012f8 <vprintfmt+0x40e>
f01012e2:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01012e5:	89 ca                	mov    %ecx,%edx
f01012e7:	8d 45 14             	lea    0x14(%ebp),%eax
f01012ea:	e8 7c fb ff ff       	call   f0100e6b <getuint>
f01012ef:	89 c6                	mov    %eax,%esi
f01012f1:	89 d7                	mov    %edx,%edi
			base = 16;
f01012f3:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f01012f8:	0f be 55 e0          	movsbl -0x20(%ebp),%edx
f01012fc:	89 54 24 10          	mov    %edx,0x10(%esp)
f0101300:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0101303:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0101307:	89 44 24 08          	mov    %eax,0x8(%esp)
f010130b:	89 34 24             	mov    %esi,(%esp)
f010130e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101312:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101315:	8b 45 08             	mov    0x8(%ebp),%eax
f0101318:	e8 73 fa ff ff       	call   f0100d90 <printnum>
			break;
f010131d:	e9 97 fc ff ff       	jmp    f0100fb9 <vprintfmt+0xcf>
f0101322:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101325:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101328:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010132b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010132f:	89 14 24             	mov    %edx,(%esp)
f0101332:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101335:	e9 7f fc ff ff       	jmp    f0100fb9 <vprintfmt+0xcf>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010133a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010133d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101341:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101348:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f010134b:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f010134e:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0101352:	0f 84 61 fc ff ff    	je     f0100fb9 <vprintfmt+0xcf>
f0101358:	83 eb 01             	sub    $0x1,%ebx
f010135b:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f010135f:	75 f7                	jne    f0101358 <vprintfmt+0x46e>
f0101361:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0101364:	e9 50 fc ff ff       	jmp    f0100fb9 <vprintfmt+0xcf>
				/* do nothing */;
			break;
		}
	}
}
f0101369:	83 c4 3c             	add    $0x3c,%esp
f010136c:	5b                   	pop    %ebx
f010136d:	5e                   	pop    %esi
f010136e:	5f                   	pop    %edi
f010136f:	5d                   	pop    %ebp
f0101370:	c3                   	ret    

f0101371 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101371:	55                   	push   %ebp
f0101372:	89 e5                	mov    %esp,%ebp
f0101374:	83 ec 28             	sub    $0x28,%esp
f0101377:	8b 45 08             	mov    0x8(%ebp),%eax
f010137a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010137d:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101380:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101384:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101387:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010138e:	85 c0                	test   %eax,%eax
f0101390:	74 30                	je     f01013c2 <vsnprintf+0x51>
f0101392:	85 d2                	test   %edx,%edx
f0101394:	7e 2c                	jle    f01013c2 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101396:	8b 45 14             	mov    0x14(%ebp),%eax
f0101399:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010139d:	8b 45 10             	mov    0x10(%ebp),%eax
f01013a0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01013a4:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01013a7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013ab:	c7 04 24 a5 0e 10 f0 	movl   $0xf0100ea5,(%esp)
f01013b2:	e8 33 fb ff ff       	call   f0100eea <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01013b7:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01013ba:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01013bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01013c0:	eb 05                	jmp    f01013c7 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01013c2:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01013c7:	c9                   	leave  
f01013c8:	c3                   	ret    

f01013c9 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01013c9:	55                   	push   %ebp
f01013ca:	89 e5                	mov    %esp,%ebp
f01013cc:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01013cf:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01013d2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01013d6:	8b 45 10             	mov    0x10(%ebp),%eax
f01013d9:	89 44 24 08          	mov    %eax,0x8(%esp)
f01013dd:	8b 45 0c             	mov    0xc(%ebp),%eax
f01013e0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013e4:	8b 45 08             	mov    0x8(%ebp),%eax
f01013e7:	89 04 24             	mov    %eax,(%esp)
f01013ea:	e8 82 ff ff ff       	call   f0101371 <vsnprintf>
	va_end(ap);

	return rc;
}
f01013ef:	c9                   	leave  
f01013f0:	c3                   	ret    
	...

f0101400 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101400:	55                   	push   %ebp
f0101401:	89 e5                	mov    %esp,%ebp
f0101403:	57                   	push   %edi
f0101404:	56                   	push   %esi
f0101405:	53                   	push   %ebx
f0101406:	83 ec 1c             	sub    $0x1c,%esp
f0101409:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010140c:	85 c0                	test   %eax,%eax
f010140e:	74 10                	je     f0101420 <readline+0x20>
		cprintf("%s", prompt);
f0101410:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101414:	c7 04 24 60 21 10 f0 	movl   $0xf0102160,(%esp)
f010141b:	e8 1a f6 ff ff       	call   f0100a3a <cprintf>

	i = 0;
	echoing = iscons(0);
f0101420:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101427:	e8 56 f2 ff ff       	call   f0100682 <iscons>
f010142c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010142e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101433:	e8 39 f2 ff ff       	call   f0100671 <getchar>
f0101438:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010143a:	85 c0                	test   %eax,%eax
f010143c:	79 17                	jns    f0101455 <readline+0x55>
			cprintf("read error: %e\n", c);
f010143e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101442:	c7 04 24 40 23 10 f0 	movl   $0xf0102340,(%esp)
f0101449:	e8 ec f5 ff ff       	call   f0100a3a <cprintf>
			return NULL;
f010144e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101453:	eb 6d                	jmp    f01014c2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101455:	83 f8 08             	cmp    $0x8,%eax
f0101458:	74 05                	je     f010145f <readline+0x5f>
f010145a:	83 f8 7f             	cmp    $0x7f,%eax
f010145d:	75 19                	jne    f0101478 <readline+0x78>
f010145f:	85 f6                	test   %esi,%esi
f0101461:	7e 15                	jle    f0101478 <readline+0x78>
			if (echoing)
f0101463:	85 ff                	test   %edi,%edi
f0101465:	74 0c                	je     f0101473 <readline+0x73>
				cputchar('\b');
f0101467:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010146e:	e8 ee f1 ff ff       	call   f0100661 <cputchar>
			i--;
f0101473:	83 ee 01             	sub    $0x1,%esi
f0101476:	eb bb                	jmp    f0101433 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101478:	83 fb 1f             	cmp    $0x1f,%ebx
f010147b:	7e 1f                	jle    f010149c <readline+0x9c>
f010147d:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101483:	7f 17                	jg     f010149c <readline+0x9c>
			if (echoing)
f0101485:	85 ff                	test   %edi,%edi
f0101487:	74 08                	je     f0101491 <readline+0x91>
				cputchar(c);
f0101489:	89 1c 24             	mov    %ebx,(%esp)
f010148c:	e8 d0 f1 ff ff       	call   f0100661 <cputchar>
			buf[i++] = c;
f0101491:	88 9e 80 25 11 f0    	mov    %bl,-0xfeeda80(%esi)
f0101497:	83 c6 01             	add    $0x1,%esi
f010149a:	eb 97                	jmp    f0101433 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010149c:	83 fb 0a             	cmp    $0xa,%ebx
f010149f:	74 05                	je     f01014a6 <readline+0xa6>
f01014a1:	83 fb 0d             	cmp    $0xd,%ebx
f01014a4:	75 8d                	jne    f0101433 <readline+0x33>
			if (echoing)
f01014a6:	85 ff                	test   %edi,%edi
f01014a8:	74 0c                	je     f01014b6 <readline+0xb6>
				cputchar('\n');
f01014aa:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01014b1:	e8 ab f1 ff ff       	call   f0100661 <cputchar>
			buf[i] = 0;
f01014b6:	c6 86 80 25 11 f0 00 	movb   $0x0,-0xfeeda80(%esi)
			return buf;
f01014bd:	b8 80 25 11 f0       	mov    $0xf0112580,%eax
		}
	}
}
f01014c2:	83 c4 1c             	add    $0x1c,%esp
f01014c5:	5b                   	pop    %ebx
f01014c6:	5e                   	pop    %esi
f01014c7:	5f                   	pop    %edi
f01014c8:	5d                   	pop    %ebp
f01014c9:	c3                   	ret    
f01014ca:	00 00                	add    %al,(%eax)
f01014cc:	00 00                	add    %al,(%eax)
	...

f01014d0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01014d0:	55                   	push   %ebp
f01014d1:	89 e5                	mov    %esp,%ebp
f01014d3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01014d6:	b8 00 00 00 00       	mov    $0x0,%eax
f01014db:	80 3a 00             	cmpb   $0x0,(%edx)
f01014de:	74 09                	je     f01014e9 <strlen+0x19>
		n++;
f01014e0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01014e3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01014e7:	75 f7                	jne    f01014e0 <strlen+0x10>
		n++;
	return n;
}
f01014e9:	5d                   	pop    %ebp
f01014ea:	c3                   	ret    

f01014eb <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01014eb:	55                   	push   %ebp
f01014ec:	89 e5                	mov    %esp,%ebp
f01014ee:	53                   	push   %ebx
f01014ef:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01014f2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01014f5:	b8 00 00 00 00       	mov    $0x0,%eax
f01014fa:	85 c9                	test   %ecx,%ecx
f01014fc:	74 1a                	je     f0101518 <strnlen+0x2d>
f01014fe:	80 3b 00             	cmpb   $0x0,(%ebx)
f0101501:	74 15                	je     f0101518 <strnlen+0x2d>
f0101503:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f0101508:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010150a:	39 ca                	cmp    %ecx,%edx
f010150c:	74 0a                	je     f0101518 <strnlen+0x2d>
f010150e:	83 c2 01             	add    $0x1,%edx
f0101511:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0101516:	75 f0                	jne    f0101508 <strnlen+0x1d>
		n++;
	return n;
}
f0101518:	5b                   	pop    %ebx
f0101519:	5d                   	pop    %ebp
f010151a:	c3                   	ret    

f010151b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010151b:	55                   	push   %ebp
f010151c:	89 e5                	mov    %esp,%ebp
f010151e:	53                   	push   %ebx
f010151f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101522:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101525:	ba 00 00 00 00       	mov    $0x0,%edx
f010152a:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f010152e:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0101531:	83 c2 01             	add    $0x1,%edx
f0101534:	84 c9                	test   %cl,%cl
f0101536:	75 f2                	jne    f010152a <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0101538:	5b                   	pop    %ebx
f0101539:	5d                   	pop    %ebp
f010153a:	c3                   	ret    

f010153b <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010153b:	55                   	push   %ebp
f010153c:	89 e5                	mov    %esp,%ebp
f010153e:	56                   	push   %esi
f010153f:	53                   	push   %ebx
f0101540:	8b 45 08             	mov    0x8(%ebp),%eax
f0101543:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101546:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101549:	85 f6                	test   %esi,%esi
f010154b:	74 18                	je     f0101565 <strncpy+0x2a>
f010154d:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f0101552:	0f b6 1a             	movzbl (%edx),%ebx
f0101555:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101558:	80 3a 01             	cmpb   $0x1,(%edx)
f010155b:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010155e:	83 c1 01             	add    $0x1,%ecx
f0101561:	39 f1                	cmp    %esi,%ecx
f0101563:	75 ed                	jne    f0101552 <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101565:	5b                   	pop    %ebx
f0101566:	5e                   	pop    %esi
f0101567:	5d                   	pop    %ebp
f0101568:	c3                   	ret    

f0101569 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101569:	55                   	push   %ebp
f010156a:	89 e5                	mov    %esp,%ebp
f010156c:	57                   	push   %edi
f010156d:	56                   	push   %esi
f010156e:	53                   	push   %ebx
f010156f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101572:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101575:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101578:	89 f8                	mov    %edi,%eax
f010157a:	85 f6                	test   %esi,%esi
f010157c:	74 2b                	je     f01015a9 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f010157e:	83 fe 01             	cmp    $0x1,%esi
f0101581:	74 23                	je     f01015a6 <strlcpy+0x3d>
f0101583:	0f b6 0b             	movzbl (%ebx),%ecx
f0101586:	84 c9                	test   %cl,%cl
f0101588:	74 1c                	je     f01015a6 <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f010158a:	83 ee 02             	sub    $0x2,%esi
f010158d:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101592:	88 08                	mov    %cl,(%eax)
f0101594:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101597:	39 f2                	cmp    %esi,%edx
f0101599:	74 0b                	je     f01015a6 <strlcpy+0x3d>
f010159b:	83 c2 01             	add    $0x1,%edx
f010159e:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01015a2:	84 c9                	test   %cl,%cl
f01015a4:	75 ec                	jne    f0101592 <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f01015a6:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01015a9:	29 f8                	sub    %edi,%eax
}
f01015ab:	5b                   	pop    %ebx
f01015ac:	5e                   	pop    %esi
f01015ad:	5f                   	pop    %edi
f01015ae:	5d                   	pop    %ebp
f01015af:	c3                   	ret    

f01015b0 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01015b0:	55                   	push   %ebp
f01015b1:	89 e5                	mov    %esp,%ebp
f01015b3:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01015b6:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01015b9:	0f b6 01             	movzbl (%ecx),%eax
f01015bc:	84 c0                	test   %al,%al
f01015be:	74 16                	je     f01015d6 <strcmp+0x26>
f01015c0:	3a 02                	cmp    (%edx),%al
f01015c2:	75 12                	jne    f01015d6 <strcmp+0x26>
		p++, q++;
f01015c4:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01015c7:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f01015cb:	84 c0                	test   %al,%al
f01015cd:	74 07                	je     f01015d6 <strcmp+0x26>
f01015cf:	83 c1 01             	add    $0x1,%ecx
f01015d2:	3a 02                	cmp    (%edx),%al
f01015d4:	74 ee                	je     f01015c4 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01015d6:	0f b6 c0             	movzbl %al,%eax
f01015d9:	0f b6 12             	movzbl (%edx),%edx
f01015dc:	29 d0                	sub    %edx,%eax
}
f01015de:	5d                   	pop    %ebp
f01015df:	c3                   	ret    

f01015e0 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01015e0:	55                   	push   %ebp
f01015e1:	89 e5                	mov    %esp,%ebp
f01015e3:	53                   	push   %ebx
f01015e4:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01015e7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01015ea:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01015ed:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01015f2:	85 d2                	test   %edx,%edx
f01015f4:	74 28                	je     f010161e <strncmp+0x3e>
f01015f6:	0f b6 01             	movzbl (%ecx),%eax
f01015f9:	84 c0                	test   %al,%al
f01015fb:	74 24                	je     f0101621 <strncmp+0x41>
f01015fd:	3a 03                	cmp    (%ebx),%al
f01015ff:	75 20                	jne    f0101621 <strncmp+0x41>
f0101601:	83 ea 01             	sub    $0x1,%edx
f0101604:	74 13                	je     f0101619 <strncmp+0x39>
		n--, p++, q++;
f0101606:	83 c1 01             	add    $0x1,%ecx
f0101609:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010160c:	0f b6 01             	movzbl (%ecx),%eax
f010160f:	84 c0                	test   %al,%al
f0101611:	74 0e                	je     f0101621 <strncmp+0x41>
f0101613:	3a 03                	cmp    (%ebx),%al
f0101615:	74 ea                	je     f0101601 <strncmp+0x21>
f0101617:	eb 08                	jmp    f0101621 <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101619:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010161e:	5b                   	pop    %ebx
f010161f:	5d                   	pop    %ebp
f0101620:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101621:	0f b6 01             	movzbl (%ecx),%eax
f0101624:	0f b6 13             	movzbl (%ebx),%edx
f0101627:	29 d0                	sub    %edx,%eax
f0101629:	eb f3                	jmp    f010161e <strncmp+0x3e>

f010162b <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010162b:	55                   	push   %ebp
f010162c:	89 e5                	mov    %esp,%ebp
f010162e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101631:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101635:	0f b6 10             	movzbl (%eax),%edx
f0101638:	84 d2                	test   %dl,%dl
f010163a:	74 1c                	je     f0101658 <strchr+0x2d>
		if (*s == c)
f010163c:	38 ca                	cmp    %cl,%dl
f010163e:	75 09                	jne    f0101649 <strchr+0x1e>
f0101640:	eb 1b                	jmp    f010165d <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101642:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f0101645:	38 ca                	cmp    %cl,%dl
f0101647:	74 14                	je     f010165d <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101649:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f010164d:	84 d2                	test   %dl,%dl
f010164f:	75 f1                	jne    f0101642 <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f0101651:	b8 00 00 00 00       	mov    $0x0,%eax
f0101656:	eb 05                	jmp    f010165d <strchr+0x32>
f0101658:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010165d:	5d                   	pop    %ebp
f010165e:	c3                   	ret    

f010165f <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010165f:	55                   	push   %ebp
f0101660:	89 e5                	mov    %esp,%ebp
f0101662:	8b 45 08             	mov    0x8(%ebp),%eax
f0101665:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101669:	0f b6 10             	movzbl (%eax),%edx
f010166c:	84 d2                	test   %dl,%dl
f010166e:	74 14                	je     f0101684 <strfind+0x25>
		if (*s == c)
f0101670:	38 ca                	cmp    %cl,%dl
f0101672:	75 06                	jne    f010167a <strfind+0x1b>
f0101674:	eb 0e                	jmp    f0101684 <strfind+0x25>
f0101676:	38 ca                	cmp    %cl,%dl
f0101678:	74 0a                	je     f0101684 <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010167a:	83 c0 01             	add    $0x1,%eax
f010167d:	0f b6 10             	movzbl (%eax),%edx
f0101680:	84 d2                	test   %dl,%dl
f0101682:	75 f2                	jne    f0101676 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f0101684:	5d                   	pop    %ebp
f0101685:	c3                   	ret    

f0101686 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101686:	55                   	push   %ebp
f0101687:	89 e5                	mov    %esp,%ebp
f0101689:	83 ec 0c             	sub    $0xc,%esp
f010168c:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010168f:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0101692:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0101695:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101698:	8b 45 0c             	mov    0xc(%ebp),%eax
f010169b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010169e:	85 c9                	test   %ecx,%ecx
f01016a0:	74 30                	je     f01016d2 <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01016a2:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01016a8:	75 25                	jne    f01016cf <memset+0x49>
f01016aa:	f6 c1 03             	test   $0x3,%cl
f01016ad:	75 20                	jne    f01016cf <memset+0x49>
		c &= 0xFF;
f01016af:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01016b2:	89 d3                	mov    %edx,%ebx
f01016b4:	c1 e3 08             	shl    $0x8,%ebx
f01016b7:	89 d6                	mov    %edx,%esi
f01016b9:	c1 e6 18             	shl    $0x18,%esi
f01016bc:	89 d0                	mov    %edx,%eax
f01016be:	c1 e0 10             	shl    $0x10,%eax
f01016c1:	09 f0                	or     %esi,%eax
f01016c3:	09 d0                	or     %edx,%eax
f01016c5:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01016c7:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01016ca:	fc                   	cld    
f01016cb:	f3 ab                	rep stos %eax,%es:(%edi)
f01016cd:	eb 03                	jmp    f01016d2 <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01016cf:	fc                   	cld    
f01016d0:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01016d2:	89 f8                	mov    %edi,%eax
f01016d4:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01016d7:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01016da:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01016dd:	89 ec                	mov    %ebp,%esp
f01016df:	5d                   	pop    %ebp
f01016e0:	c3                   	ret    

f01016e1 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01016e1:	55                   	push   %ebp
f01016e2:	89 e5                	mov    %esp,%ebp
f01016e4:	83 ec 08             	sub    $0x8,%esp
f01016e7:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01016ea:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01016ed:	8b 45 08             	mov    0x8(%ebp),%eax
f01016f0:	8b 75 0c             	mov    0xc(%ebp),%esi
f01016f3:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01016f6:	39 c6                	cmp    %eax,%esi
f01016f8:	73 36                	jae    f0101730 <memmove+0x4f>
f01016fa:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01016fd:	39 d0                	cmp    %edx,%eax
f01016ff:	73 2f                	jae    f0101730 <memmove+0x4f>
		s += n;
		d += n;
f0101701:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101704:	f6 c2 03             	test   $0x3,%dl
f0101707:	75 1b                	jne    f0101724 <memmove+0x43>
f0101709:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010170f:	75 13                	jne    f0101724 <memmove+0x43>
f0101711:	f6 c1 03             	test   $0x3,%cl
f0101714:	75 0e                	jne    f0101724 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101716:	83 ef 04             	sub    $0x4,%edi
f0101719:	8d 72 fc             	lea    -0x4(%edx),%esi
f010171c:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010171f:	fd                   	std    
f0101720:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101722:	eb 09                	jmp    f010172d <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101724:	83 ef 01             	sub    $0x1,%edi
f0101727:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010172a:	fd                   	std    
f010172b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010172d:	fc                   	cld    
f010172e:	eb 20                	jmp    f0101750 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101730:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101736:	75 13                	jne    f010174b <memmove+0x6a>
f0101738:	a8 03                	test   $0x3,%al
f010173a:	75 0f                	jne    f010174b <memmove+0x6a>
f010173c:	f6 c1 03             	test   $0x3,%cl
f010173f:	75 0a                	jne    f010174b <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101741:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0101744:	89 c7                	mov    %eax,%edi
f0101746:	fc                   	cld    
f0101747:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101749:	eb 05                	jmp    f0101750 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010174b:	89 c7                	mov    %eax,%edi
f010174d:	fc                   	cld    
f010174e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101750:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0101753:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101756:	89 ec                	mov    %ebp,%esp
f0101758:	5d                   	pop    %ebp
f0101759:	c3                   	ret    

f010175a <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f010175a:	55                   	push   %ebp
f010175b:	89 e5                	mov    %esp,%ebp
f010175d:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101760:	8b 45 10             	mov    0x10(%ebp),%eax
f0101763:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101767:	8b 45 0c             	mov    0xc(%ebp),%eax
f010176a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010176e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101771:	89 04 24             	mov    %eax,(%esp)
f0101774:	e8 68 ff ff ff       	call   f01016e1 <memmove>
}
f0101779:	c9                   	leave  
f010177a:	c3                   	ret    

f010177b <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010177b:	55                   	push   %ebp
f010177c:	89 e5                	mov    %esp,%ebp
f010177e:	57                   	push   %edi
f010177f:	56                   	push   %esi
f0101780:	53                   	push   %ebx
f0101781:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101784:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101787:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010178a:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010178f:	85 ff                	test   %edi,%edi
f0101791:	74 37                	je     f01017ca <memcmp+0x4f>
		if (*s1 != *s2)
f0101793:	0f b6 03             	movzbl (%ebx),%eax
f0101796:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101799:	83 ef 01             	sub    $0x1,%edi
f010179c:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f01017a1:	38 c8                	cmp    %cl,%al
f01017a3:	74 1c                	je     f01017c1 <memcmp+0x46>
f01017a5:	eb 10                	jmp    f01017b7 <memcmp+0x3c>
f01017a7:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f01017ac:	83 c2 01             	add    $0x1,%edx
f01017af:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f01017b3:	38 c8                	cmp    %cl,%al
f01017b5:	74 0a                	je     f01017c1 <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f01017b7:	0f b6 c0             	movzbl %al,%eax
f01017ba:	0f b6 c9             	movzbl %cl,%ecx
f01017bd:	29 c8                	sub    %ecx,%eax
f01017bf:	eb 09                	jmp    f01017ca <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01017c1:	39 fa                	cmp    %edi,%edx
f01017c3:	75 e2                	jne    f01017a7 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01017c5:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01017ca:	5b                   	pop    %ebx
f01017cb:	5e                   	pop    %esi
f01017cc:	5f                   	pop    %edi
f01017cd:	5d                   	pop    %ebp
f01017ce:	c3                   	ret    

f01017cf <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01017cf:	55                   	push   %ebp
f01017d0:	89 e5                	mov    %esp,%ebp
f01017d2:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01017d5:	89 c2                	mov    %eax,%edx
f01017d7:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01017da:	39 d0                	cmp    %edx,%eax
f01017dc:	73 15                	jae    f01017f3 <memfind+0x24>
		if (*(const unsigned char *) s == (unsigned char) c)
f01017de:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f01017e2:	38 08                	cmp    %cl,(%eax)
f01017e4:	75 06                	jne    f01017ec <memfind+0x1d>
f01017e6:	eb 0b                	jmp    f01017f3 <memfind+0x24>
f01017e8:	38 08                	cmp    %cl,(%eax)
f01017ea:	74 07                	je     f01017f3 <memfind+0x24>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01017ec:	83 c0 01             	add    $0x1,%eax
f01017ef:	39 d0                	cmp    %edx,%eax
f01017f1:	75 f5                	jne    f01017e8 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01017f3:	5d                   	pop    %ebp
f01017f4:	c3                   	ret    

f01017f5 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01017f5:	55                   	push   %ebp
f01017f6:	89 e5                	mov    %esp,%ebp
f01017f8:	57                   	push   %edi
f01017f9:	56                   	push   %esi
f01017fa:	53                   	push   %ebx
f01017fb:	8b 55 08             	mov    0x8(%ebp),%edx
f01017fe:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101801:	0f b6 02             	movzbl (%edx),%eax
f0101804:	3c 20                	cmp    $0x20,%al
f0101806:	74 04                	je     f010180c <strtol+0x17>
f0101808:	3c 09                	cmp    $0x9,%al
f010180a:	75 0e                	jne    f010181a <strtol+0x25>
		s++;
f010180c:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010180f:	0f b6 02             	movzbl (%edx),%eax
f0101812:	3c 20                	cmp    $0x20,%al
f0101814:	74 f6                	je     f010180c <strtol+0x17>
f0101816:	3c 09                	cmp    $0x9,%al
f0101818:	74 f2                	je     f010180c <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f010181a:	3c 2b                	cmp    $0x2b,%al
f010181c:	75 0a                	jne    f0101828 <strtol+0x33>
		s++;
f010181e:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101821:	bf 00 00 00 00       	mov    $0x0,%edi
f0101826:	eb 10                	jmp    f0101838 <strtol+0x43>
f0101828:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010182d:	3c 2d                	cmp    $0x2d,%al
f010182f:	75 07                	jne    f0101838 <strtol+0x43>
		s++, neg = 1;
f0101831:	83 c2 01             	add    $0x1,%edx
f0101834:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101838:	85 db                	test   %ebx,%ebx
f010183a:	0f 94 c0             	sete   %al
f010183d:	74 05                	je     f0101844 <strtol+0x4f>
f010183f:	83 fb 10             	cmp    $0x10,%ebx
f0101842:	75 15                	jne    f0101859 <strtol+0x64>
f0101844:	80 3a 30             	cmpb   $0x30,(%edx)
f0101847:	75 10                	jne    f0101859 <strtol+0x64>
f0101849:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f010184d:	75 0a                	jne    f0101859 <strtol+0x64>
		s += 2, base = 16;
f010184f:	83 c2 02             	add    $0x2,%edx
f0101852:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101857:	eb 13                	jmp    f010186c <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f0101859:	84 c0                	test   %al,%al
f010185b:	74 0f                	je     f010186c <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010185d:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101862:	80 3a 30             	cmpb   $0x30,(%edx)
f0101865:	75 05                	jne    f010186c <strtol+0x77>
		s++, base = 8;
f0101867:	83 c2 01             	add    $0x1,%edx
f010186a:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f010186c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101871:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101873:	0f b6 0a             	movzbl (%edx),%ecx
f0101876:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0101879:	80 fb 09             	cmp    $0x9,%bl
f010187c:	77 08                	ja     f0101886 <strtol+0x91>
			dig = *s - '0';
f010187e:	0f be c9             	movsbl %cl,%ecx
f0101881:	83 e9 30             	sub    $0x30,%ecx
f0101884:	eb 1e                	jmp    f01018a4 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f0101886:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f0101889:	80 fb 19             	cmp    $0x19,%bl
f010188c:	77 08                	ja     f0101896 <strtol+0xa1>
			dig = *s - 'a' + 10;
f010188e:	0f be c9             	movsbl %cl,%ecx
f0101891:	83 e9 57             	sub    $0x57,%ecx
f0101894:	eb 0e                	jmp    f01018a4 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f0101896:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0101899:	80 fb 19             	cmp    $0x19,%bl
f010189c:	77 14                	ja     f01018b2 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010189e:	0f be c9             	movsbl %cl,%ecx
f01018a1:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01018a4:	39 f1                	cmp    %esi,%ecx
f01018a6:	7d 0e                	jge    f01018b6 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f01018a8:	83 c2 01             	add    $0x1,%edx
f01018ab:	0f af c6             	imul   %esi,%eax
f01018ae:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f01018b0:	eb c1                	jmp    f0101873 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f01018b2:	89 c1                	mov    %eax,%ecx
f01018b4:	eb 02                	jmp    f01018b8 <strtol+0xc3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f01018b6:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f01018b8:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01018bc:	74 05                	je     f01018c3 <strtol+0xce>
		*endptr = (char *) s;
f01018be:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01018c1:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f01018c3:	89 ca                	mov    %ecx,%edx
f01018c5:	f7 da                	neg    %edx
f01018c7:	85 ff                	test   %edi,%edi
f01018c9:	0f 45 c2             	cmovne %edx,%eax
}
f01018cc:	5b                   	pop    %ebx
f01018cd:	5e                   	pop    %esi
f01018ce:	5f                   	pop    %edi
f01018cf:	5d                   	pop    %ebp
f01018d0:	c3                   	ret    
	...

f01018e0 <__udivdi3>:
f01018e0:	83 ec 1c             	sub    $0x1c,%esp
f01018e3:	89 7c 24 14          	mov    %edi,0x14(%esp)
f01018e7:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f01018eb:	8b 44 24 20          	mov    0x20(%esp),%eax
f01018ef:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f01018f3:	89 74 24 10          	mov    %esi,0x10(%esp)
f01018f7:	8b 74 24 24          	mov    0x24(%esp),%esi
f01018fb:	85 ff                	test   %edi,%edi
f01018fd:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101901:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101905:	89 cd                	mov    %ecx,%ebp
f0101907:	89 44 24 04          	mov    %eax,0x4(%esp)
f010190b:	75 33                	jne    f0101940 <__udivdi3+0x60>
f010190d:	39 f1                	cmp    %esi,%ecx
f010190f:	77 57                	ja     f0101968 <__udivdi3+0x88>
f0101911:	85 c9                	test   %ecx,%ecx
f0101913:	75 0b                	jne    f0101920 <__udivdi3+0x40>
f0101915:	b8 01 00 00 00       	mov    $0x1,%eax
f010191a:	31 d2                	xor    %edx,%edx
f010191c:	f7 f1                	div    %ecx
f010191e:	89 c1                	mov    %eax,%ecx
f0101920:	89 f0                	mov    %esi,%eax
f0101922:	31 d2                	xor    %edx,%edx
f0101924:	f7 f1                	div    %ecx
f0101926:	89 c6                	mov    %eax,%esi
f0101928:	8b 44 24 04          	mov    0x4(%esp),%eax
f010192c:	f7 f1                	div    %ecx
f010192e:	89 f2                	mov    %esi,%edx
f0101930:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101934:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101938:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010193c:	83 c4 1c             	add    $0x1c,%esp
f010193f:	c3                   	ret    
f0101940:	31 d2                	xor    %edx,%edx
f0101942:	31 c0                	xor    %eax,%eax
f0101944:	39 f7                	cmp    %esi,%edi
f0101946:	77 e8                	ja     f0101930 <__udivdi3+0x50>
f0101948:	0f bd cf             	bsr    %edi,%ecx
f010194b:	83 f1 1f             	xor    $0x1f,%ecx
f010194e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101952:	75 2c                	jne    f0101980 <__udivdi3+0xa0>
f0101954:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0101958:	76 04                	jbe    f010195e <__udivdi3+0x7e>
f010195a:	39 f7                	cmp    %esi,%edi
f010195c:	73 d2                	jae    f0101930 <__udivdi3+0x50>
f010195e:	31 d2                	xor    %edx,%edx
f0101960:	b8 01 00 00 00       	mov    $0x1,%eax
f0101965:	eb c9                	jmp    f0101930 <__udivdi3+0x50>
f0101967:	90                   	nop
f0101968:	89 f2                	mov    %esi,%edx
f010196a:	f7 f1                	div    %ecx
f010196c:	31 d2                	xor    %edx,%edx
f010196e:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101972:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101976:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010197a:	83 c4 1c             	add    $0x1c,%esp
f010197d:	c3                   	ret    
f010197e:	66 90                	xchg   %ax,%ax
f0101980:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101985:	b8 20 00 00 00       	mov    $0x20,%eax
f010198a:	89 ea                	mov    %ebp,%edx
f010198c:	2b 44 24 04          	sub    0x4(%esp),%eax
f0101990:	d3 e7                	shl    %cl,%edi
f0101992:	89 c1                	mov    %eax,%ecx
f0101994:	d3 ea                	shr    %cl,%edx
f0101996:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010199b:	09 fa                	or     %edi,%edx
f010199d:	89 f7                	mov    %esi,%edi
f010199f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01019a3:	89 f2                	mov    %esi,%edx
f01019a5:	8b 74 24 08          	mov    0x8(%esp),%esi
f01019a9:	d3 e5                	shl    %cl,%ebp
f01019ab:	89 c1                	mov    %eax,%ecx
f01019ad:	d3 ef                	shr    %cl,%edi
f01019af:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01019b4:	d3 e2                	shl    %cl,%edx
f01019b6:	89 c1                	mov    %eax,%ecx
f01019b8:	d3 ee                	shr    %cl,%esi
f01019ba:	09 d6                	or     %edx,%esi
f01019bc:	89 fa                	mov    %edi,%edx
f01019be:	89 f0                	mov    %esi,%eax
f01019c0:	f7 74 24 0c          	divl   0xc(%esp)
f01019c4:	89 d7                	mov    %edx,%edi
f01019c6:	89 c6                	mov    %eax,%esi
f01019c8:	f7 e5                	mul    %ebp
f01019ca:	39 d7                	cmp    %edx,%edi
f01019cc:	72 22                	jb     f01019f0 <__udivdi3+0x110>
f01019ce:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f01019d2:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01019d7:	d3 e5                	shl    %cl,%ebp
f01019d9:	39 c5                	cmp    %eax,%ebp
f01019db:	73 04                	jae    f01019e1 <__udivdi3+0x101>
f01019dd:	39 d7                	cmp    %edx,%edi
f01019df:	74 0f                	je     f01019f0 <__udivdi3+0x110>
f01019e1:	89 f0                	mov    %esi,%eax
f01019e3:	31 d2                	xor    %edx,%edx
f01019e5:	e9 46 ff ff ff       	jmp    f0101930 <__udivdi3+0x50>
f01019ea:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01019f0:	8d 46 ff             	lea    -0x1(%esi),%eax
f01019f3:	31 d2                	xor    %edx,%edx
f01019f5:	8b 74 24 10          	mov    0x10(%esp),%esi
f01019f9:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01019fd:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101a01:	83 c4 1c             	add    $0x1c,%esp
f0101a04:	c3                   	ret    
	...

f0101a10 <__umoddi3>:
f0101a10:	83 ec 1c             	sub    $0x1c,%esp
f0101a13:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101a17:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f0101a1b:	8b 44 24 20          	mov    0x20(%esp),%eax
f0101a1f:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101a23:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101a27:	8b 74 24 24          	mov    0x24(%esp),%esi
f0101a2b:	85 ed                	test   %ebp,%ebp
f0101a2d:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0101a31:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101a35:	89 cf                	mov    %ecx,%edi
f0101a37:	89 04 24             	mov    %eax,(%esp)
f0101a3a:	89 f2                	mov    %esi,%edx
f0101a3c:	75 1a                	jne    f0101a58 <__umoddi3+0x48>
f0101a3e:	39 f1                	cmp    %esi,%ecx
f0101a40:	76 4e                	jbe    f0101a90 <__umoddi3+0x80>
f0101a42:	f7 f1                	div    %ecx
f0101a44:	89 d0                	mov    %edx,%eax
f0101a46:	31 d2                	xor    %edx,%edx
f0101a48:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101a4c:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101a50:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101a54:	83 c4 1c             	add    $0x1c,%esp
f0101a57:	c3                   	ret    
f0101a58:	39 f5                	cmp    %esi,%ebp
f0101a5a:	77 54                	ja     f0101ab0 <__umoddi3+0xa0>
f0101a5c:	0f bd c5             	bsr    %ebp,%eax
f0101a5f:	83 f0 1f             	xor    $0x1f,%eax
f0101a62:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101a66:	75 60                	jne    f0101ac8 <__umoddi3+0xb8>
f0101a68:	3b 0c 24             	cmp    (%esp),%ecx
f0101a6b:	0f 87 07 01 00 00    	ja     f0101b78 <__umoddi3+0x168>
f0101a71:	89 f2                	mov    %esi,%edx
f0101a73:	8b 34 24             	mov    (%esp),%esi
f0101a76:	29 ce                	sub    %ecx,%esi
f0101a78:	19 ea                	sbb    %ebp,%edx
f0101a7a:	89 34 24             	mov    %esi,(%esp)
f0101a7d:	8b 04 24             	mov    (%esp),%eax
f0101a80:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101a84:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101a88:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101a8c:	83 c4 1c             	add    $0x1c,%esp
f0101a8f:	c3                   	ret    
f0101a90:	85 c9                	test   %ecx,%ecx
f0101a92:	75 0b                	jne    f0101a9f <__umoddi3+0x8f>
f0101a94:	b8 01 00 00 00       	mov    $0x1,%eax
f0101a99:	31 d2                	xor    %edx,%edx
f0101a9b:	f7 f1                	div    %ecx
f0101a9d:	89 c1                	mov    %eax,%ecx
f0101a9f:	89 f0                	mov    %esi,%eax
f0101aa1:	31 d2                	xor    %edx,%edx
f0101aa3:	f7 f1                	div    %ecx
f0101aa5:	8b 04 24             	mov    (%esp),%eax
f0101aa8:	f7 f1                	div    %ecx
f0101aaa:	eb 98                	jmp    f0101a44 <__umoddi3+0x34>
f0101aac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101ab0:	89 f2                	mov    %esi,%edx
f0101ab2:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101ab6:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101aba:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101abe:	83 c4 1c             	add    $0x1c,%esp
f0101ac1:	c3                   	ret    
f0101ac2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101ac8:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101acd:	89 e8                	mov    %ebp,%eax
f0101acf:	bd 20 00 00 00       	mov    $0x20,%ebp
f0101ad4:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0101ad8:	89 fa                	mov    %edi,%edx
f0101ada:	d3 e0                	shl    %cl,%eax
f0101adc:	89 e9                	mov    %ebp,%ecx
f0101ade:	d3 ea                	shr    %cl,%edx
f0101ae0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101ae5:	09 c2                	or     %eax,%edx
f0101ae7:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101aeb:	89 14 24             	mov    %edx,(%esp)
f0101aee:	89 f2                	mov    %esi,%edx
f0101af0:	d3 e7                	shl    %cl,%edi
f0101af2:	89 e9                	mov    %ebp,%ecx
f0101af4:	d3 ea                	shr    %cl,%edx
f0101af6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101afb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101aff:	d3 e6                	shl    %cl,%esi
f0101b01:	89 e9                	mov    %ebp,%ecx
f0101b03:	d3 e8                	shr    %cl,%eax
f0101b05:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101b0a:	09 f0                	or     %esi,%eax
f0101b0c:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101b10:	f7 34 24             	divl   (%esp)
f0101b13:	d3 e6                	shl    %cl,%esi
f0101b15:	89 74 24 08          	mov    %esi,0x8(%esp)
f0101b19:	89 d6                	mov    %edx,%esi
f0101b1b:	f7 e7                	mul    %edi
f0101b1d:	39 d6                	cmp    %edx,%esi
f0101b1f:	89 c1                	mov    %eax,%ecx
f0101b21:	89 d7                	mov    %edx,%edi
f0101b23:	72 3f                	jb     f0101b64 <__umoddi3+0x154>
f0101b25:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0101b29:	72 35                	jb     f0101b60 <__umoddi3+0x150>
f0101b2b:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101b2f:	29 c8                	sub    %ecx,%eax
f0101b31:	19 fe                	sbb    %edi,%esi
f0101b33:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101b38:	89 f2                	mov    %esi,%edx
f0101b3a:	d3 e8                	shr    %cl,%eax
f0101b3c:	89 e9                	mov    %ebp,%ecx
f0101b3e:	d3 e2                	shl    %cl,%edx
f0101b40:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101b45:	09 d0                	or     %edx,%eax
f0101b47:	89 f2                	mov    %esi,%edx
f0101b49:	d3 ea                	shr    %cl,%edx
f0101b4b:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101b4f:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101b53:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101b57:	83 c4 1c             	add    $0x1c,%esp
f0101b5a:	c3                   	ret    
f0101b5b:	90                   	nop
f0101b5c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101b60:	39 d6                	cmp    %edx,%esi
f0101b62:	75 c7                	jne    f0101b2b <__umoddi3+0x11b>
f0101b64:	89 d7                	mov    %edx,%edi
f0101b66:	89 c1                	mov    %eax,%ecx
f0101b68:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f0101b6c:	1b 3c 24             	sbb    (%esp),%edi
f0101b6f:	eb ba                	jmp    f0101b2b <__umoddi3+0x11b>
f0101b71:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101b78:	39 f5                	cmp    %esi,%ebp
f0101b7a:	0f 82 f1 fe ff ff    	jb     f0101a71 <__umoddi3+0x61>
f0101b80:	e9 f8 fe ff ff       	jmp    f0101a7d <__umoddi3+0x6d>
