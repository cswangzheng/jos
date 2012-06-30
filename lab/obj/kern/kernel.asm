
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
f010004e:	c7 04 24 c0 1a 10 f0 	movl   $0xf0101ac0,(%esp)
f0100055:	e8 60 09 00 00       	call   f01009ba <cprintf>
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
f0100082:	e8 ff 06 00 00       	call   f0100786 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 dc 1a 10 f0 	movl   $0xf0101adc,(%esp)
f0100092:	e8 23 09 00 00       	call   f01009ba <cprintf>
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
f01000c0:	e8 f1 14 00 00       	call   f01015b6 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 a1 04 00 00       	call   f010056b <cons_init>
	cprintf("color test: \033[0;32;40m hello \033[0;36;41mworld\033[0;37;40m\n");
f01000ca:	c7 04 24 44 1b 10 f0 	movl   $0xf0101b44,(%esp)
f01000d1:	e8 e4 08 00 00       	call   f01009ba <cprintf>
	cprintf("6828 decimal is %o octal!\n", 6828);
f01000d6:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000dd:	00 
f01000de:	c7 04 24 f7 1a 10 f0 	movl   $0xf0101af7,(%esp)
f01000e5:	e8 d0 08 00 00       	call   f01009ba <cprintf>
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
f01000fd:	e8 21 07 00 00       	call   f0100823 <monitor>
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
f0100131:	c7 04 24 12 1b 10 f0 	movl   $0xf0101b12,(%esp)
f0100138:	e8 7d 08 00 00       	call   f01009ba <cprintf>
	vcprintf(fmt, ap);
f010013d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100141:	89 34 24             	mov    %esi,(%esp)
f0100144:	e8 3e 08 00 00       	call   f0100987 <vcprintf>
	cprintf("\n");
f0100149:	c7 04 24 86 1b 10 f0 	movl   $0xf0101b86,(%esp)
f0100150:	e8 65 08 00 00       	call   f01009ba <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100155:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010015c:	e8 c2 06 00 00       	call   f0100823 <monitor>
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
f010017b:	c7 04 24 2a 1b 10 f0 	movl   $0xf0101b2a,(%esp)
f0100182:	e8 33 08 00 00       	call   f01009ba <cprintf>
	vcprintf(fmt, ap);
f0100187:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010018b:	8b 45 10             	mov    0x10(%ebp),%eax
f010018e:	89 04 24             	mov    %eax,(%esp)
f0100191:	e8 f1 07 00 00       	call   f0100987 <vcprintf>
	cprintf("\n");
f0100196:	c7 04 24 86 1b 10 f0 	movl   $0xf0101b86,(%esp)
f010019d:	e8 18 08 00 00       	call   f01009ba <cprintf>
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
f010039d:	e8 6f 12 00 00       	call   f0101611 <memmove>
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
f0100449:	0f b6 82 c0 1b 10 f0 	movzbl -0xfefe440(%edx),%eax
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
f0100486:	0f b6 82 c0 1b 10 f0 	movzbl -0xfefe440(%edx),%eax
f010048d:	0b 05 68 25 11 f0    	or     0xf0112568,%eax
	shift ^= togglecode[data];
f0100493:	0f b6 8a c0 1c 10 f0 	movzbl -0xfefe340(%edx),%ecx
f010049a:	31 c8                	xor    %ecx,%eax
f010049c:	a3 68 25 11 f0       	mov    %eax,0xf0112568

	c = charcode[shift & (CTL | SHIFT)][data];
f01004a1:	89 c1                	mov    %eax,%ecx
f01004a3:	83 e1 03             	and    $0x3,%ecx
f01004a6:	8b 0c 8d c0 1d 10 f0 	mov    -0xfefe240(,%ecx,4),%ecx
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
f01004dc:	c7 04 24 7c 1b 10 f0 	movl   $0xf0101b7c,(%esp)
f01004e3:	e8 d2 04 00 00       	call   f01009ba <cprintf>
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
f010064d:	c7 04 24 88 1b 10 f0 	movl   $0xf0101b88,(%esp)
f0100654:	e8 61 03 00 00       	call   f01009ba <cprintf>
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
f0100696:	c7 04 24 d0 1d 10 f0 	movl   $0xf0101dd0,(%esp)
f010069d:	e8 18 03 00 00       	call   f01009ba <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006a2:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006a9:	00 
f01006aa:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006b1:	f0 
f01006b2:	c7 04 24 6c 1e 10 f0 	movl   $0xf0101e6c,(%esp)
f01006b9:	e8 fc 02 00 00       	call   f01009ba <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006be:	c7 44 24 08 b5 1a 10 	movl   $0x101ab5,0x8(%esp)
f01006c5:	00 
f01006c6:	c7 44 24 04 b5 1a 10 	movl   $0xf0101ab5,0x4(%esp)
f01006cd:	f0 
f01006ce:	c7 04 24 90 1e 10 f0 	movl   $0xf0101e90,(%esp)
f01006d5:	e8 e0 02 00 00       	call   f01009ba <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006da:	c7 44 24 08 04 23 11 	movl   $0x112304,0x8(%esp)
f01006e1:	00 
f01006e2:	c7 44 24 04 04 23 11 	movl   $0xf0112304,0x4(%esp)
f01006e9:	f0 
f01006ea:	c7 04 24 b4 1e 10 f0 	movl   $0xf0101eb4,(%esp)
f01006f1:	e8 c4 02 00 00       	call   f01009ba <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006f6:	c7 44 24 08 80 29 11 	movl   $0x112980,0x8(%esp)
f01006fd:	00 
f01006fe:	c7 44 24 04 80 29 11 	movl   $0xf0112980,0x4(%esp)
f0100705:	f0 
f0100706:	c7 04 24 d8 1e 10 f0 	movl   $0xf0101ed8,(%esp)
f010070d:	e8 a8 02 00 00       	call   f01009ba <cprintf>
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
f010072e:	c7 04 24 fc 1e 10 f0 	movl   $0xf0101efc,(%esp)
f0100735:	e8 80 02 00 00       	call   f01009ba <cprintf>
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
f0100744:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100747:	c7 44 24 08 e9 1d 10 	movl   $0xf0101de9,0x8(%esp)
f010074e:	f0 
f010074f:	c7 44 24 04 07 1e 10 	movl   $0xf0101e07,0x4(%esp)
f0100756:	f0 
f0100757:	c7 04 24 0c 1e 10 f0 	movl   $0xf0101e0c,(%esp)
f010075e:	e8 57 02 00 00       	call   f01009ba <cprintf>
f0100763:	c7 44 24 08 28 1f 10 	movl   $0xf0101f28,0x8(%esp)
f010076a:	f0 
f010076b:	c7 44 24 04 15 1e 10 	movl   $0xf0101e15,0x4(%esp)
f0100772:	f0 
f0100773:	c7 04 24 0c 1e 10 f0 	movl   $0xf0101e0c,(%esp)
f010077a:	e8 3b 02 00 00       	call   f01009ba <cprintf>
	return 0;
}
f010077f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100784:	c9                   	leave  
f0100785:	c3                   	ret    

f0100786 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100786:	55                   	push   %ebp
f0100787:	89 e5                	mov    %esp,%ebp
f0100789:	57                   	push   %edi
f010078a:	56                   	push   %esi
f010078b:	53                   	push   %ebx
f010078c:	83 ec 4c             	sub    $0x4c,%esp

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f010078f:	89 eb                	mov    %ebp,%ebx
f0100791:	89 de                	mov    %ebx,%esi
	// Your code here.
	uint32_t ebp,eip,arg[5];
	ebp = read_ebp();
	eip = *((uint32_t*)ebp+1);
f0100793:	8b 7b 04             	mov    0x4(%ebx),%edi
	arg[0] = *((uint32_t*)ebp+2);
f0100796:	8b 43 08             	mov    0x8(%ebx),%eax
f0100799:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	arg[1] = *((uint32_t*)ebp+3);
f010079c:	8b 43 0c             	mov    0xc(%ebx),%eax
f010079f:	89 45 e0             	mov    %eax,-0x20(%ebp)
	arg[2] = *((uint32_t*)ebp+4);
f01007a2:	8b 43 10             	mov    0x10(%ebx),%eax
f01007a5:	89 45 dc             	mov    %eax,-0x24(%ebp)
	arg[3] = *((uint32_t*)ebp+5);
f01007a8:	8b 43 14             	mov    0x14(%ebx),%eax
f01007ab:	89 45 d8             	mov    %eax,-0x28(%ebp)
	arg[4] = *((uint32_t*)ebp+6);
f01007ae:	8b 43 18             	mov    0x18(%ebx),%eax
f01007b1:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	cprintf("Stack backtrace:\n");
f01007b4:	c7 04 24 1e 1e 10 f0 	movl   $0xf0101e1e,(%esp)
f01007bb:	e8 fa 01 00 00       	call   f01009ba <cprintf>
	
	while(ebp != 0x00)
f01007c0:	85 db                	test   %ebx,%ebx
f01007c2:	74 52                	je     f0100816 <mon_backtrace+0x90>
f01007c4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01007c7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01007ca:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f01007cd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
		{
			cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",ebp,eip,arg[0],arg[1],arg[2],arg[3],arg[4]);
f01007d0:	89 5c 24 1c          	mov    %ebx,0x1c(%esp)
f01007d4:	89 4c 24 18          	mov    %ecx,0x18(%esp)
f01007d8:	89 54 24 14          	mov    %edx,0x14(%esp)
f01007dc:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007e0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01007e3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007e7:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01007eb:	89 74 24 04          	mov    %esi,0x4(%esp)
f01007ef:	c7 04 24 50 1f 10 f0 	movl   $0xf0101f50,(%esp)
f01007f6:	e8 bf 01 00 00       	call   f01009ba <cprintf>
			ebp = *(uint32_t *)ebp;
f01007fb:	8b 36                	mov    (%esi),%esi
			eip = *((uint32_t*)ebp+1);
f01007fd:	8b 7e 04             	mov    0x4(%esi),%edi
			arg[0] = *((uint32_t*)ebp+2);
f0100800:	8b 46 08             	mov    0x8(%esi),%eax
f0100803:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			arg[1] = *((uint32_t*)ebp+3);
f0100806:	8b 46 0c             	mov    0xc(%esi),%eax
			arg[2] = *((uint32_t*)ebp+4);
f0100809:	8b 56 10             	mov    0x10(%esi),%edx
			arg[3] = *((uint32_t*)ebp+5);
f010080c:	8b 4e 14             	mov    0x14(%esi),%ecx
			arg[4] = *((uint32_t*)ebp+6);
f010080f:	8b 5e 18             	mov    0x18(%esi),%ebx
	arg[3] = *((uint32_t*)ebp+5);
	arg[4] = *((uint32_t*)ebp+6);

	cprintf("Stack backtrace:\n");
	
	while(ebp != 0x00)
f0100812:	85 f6                	test   %esi,%esi
f0100814:	75 ba                	jne    f01007d0 <mon_backtrace+0x4a>
			arg[3] = *((uint32_t*)ebp+5);
			arg[4] = *((uint32_t*)ebp+6);
			
		}
	return 0;
}
f0100816:	b8 00 00 00 00       	mov    $0x0,%eax
f010081b:	83 c4 4c             	add    $0x4c,%esp
f010081e:	5b                   	pop    %ebx
f010081f:	5e                   	pop    %esi
f0100820:	5f                   	pop    %edi
f0100821:	5d                   	pop    %ebp
f0100822:	c3                   	ret    

f0100823 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100823:	55                   	push   %ebp
f0100824:	89 e5                	mov    %esp,%ebp
f0100826:	57                   	push   %edi
f0100827:	56                   	push   %esi
f0100828:	53                   	push   %ebx
f0100829:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010082c:	c7 04 24 84 1f 10 f0 	movl   $0xf0101f84,(%esp)
f0100833:	e8 82 01 00 00       	call   f01009ba <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100838:	c7 04 24 a8 1f 10 f0 	movl   $0xf0101fa8,(%esp)
f010083f:	e8 76 01 00 00       	call   f01009ba <cprintf>
	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
f0100844:	8d 7d a8             	lea    -0x58(%ebp),%edi
	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");


	while (1) {
		buf = readline("K> ");
f0100847:	c7 04 24 30 1e 10 f0 	movl   $0xf0101e30,(%esp)
f010084e:	e8 dd 0a 00 00       	call   f0101330 <readline>
f0100853:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100855:	85 c0                	test   %eax,%eax
f0100857:	74 ee                	je     f0100847 <monitor+0x24>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100859:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100860:	be 00 00 00 00       	mov    $0x0,%esi
f0100865:	eb 06                	jmp    f010086d <monitor+0x4a>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100867:	c6 03 00             	movb   $0x0,(%ebx)
f010086a:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010086d:	0f b6 03             	movzbl (%ebx),%eax
f0100870:	84 c0                	test   %al,%al
f0100872:	74 6a                	je     f01008de <monitor+0xbb>
f0100874:	0f be c0             	movsbl %al,%eax
f0100877:	89 44 24 04          	mov    %eax,0x4(%esp)
f010087b:	c7 04 24 34 1e 10 f0 	movl   $0xf0101e34,(%esp)
f0100882:	e8 d4 0c 00 00       	call   f010155b <strchr>
f0100887:	85 c0                	test   %eax,%eax
f0100889:	75 dc                	jne    f0100867 <monitor+0x44>
			*buf++ = 0;
		if (*buf == 0)
f010088b:	80 3b 00             	cmpb   $0x0,(%ebx)
f010088e:	74 4e                	je     f01008de <monitor+0xbb>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100890:	83 fe 0f             	cmp    $0xf,%esi
f0100893:	75 16                	jne    f01008ab <monitor+0x88>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100895:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f010089c:	00 
f010089d:	c7 04 24 39 1e 10 f0 	movl   $0xf0101e39,(%esp)
f01008a4:	e8 11 01 00 00       	call   f01009ba <cprintf>
f01008a9:	eb 9c                	jmp    f0100847 <monitor+0x24>
			return 0;
		}
		argv[argc++] = buf;
f01008ab:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008af:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f01008b2:	0f b6 03             	movzbl (%ebx),%eax
f01008b5:	84 c0                	test   %al,%al
f01008b7:	75 0c                	jne    f01008c5 <monitor+0xa2>
f01008b9:	eb b2                	jmp    f010086d <monitor+0x4a>
			buf++;
f01008bb:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008be:	0f b6 03             	movzbl (%ebx),%eax
f01008c1:	84 c0                	test   %al,%al
f01008c3:	74 a8                	je     f010086d <monitor+0x4a>
f01008c5:	0f be c0             	movsbl %al,%eax
f01008c8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008cc:	c7 04 24 34 1e 10 f0 	movl   $0xf0101e34,(%esp)
f01008d3:	e8 83 0c 00 00       	call   f010155b <strchr>
f01008d8:	85 c0                	test   %eax,%eax
f01008da:	74 df                	je     f01008bb <monitor+0x98>
f01008dc:	eb 8f                	jmp    f010086d <monitor+0x4a>
			buf++;
	}
	argv[argc] = 0;
f01008de:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008e5:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008e6:	85 f6                	test   %esi,%esi
f01008e8:	0f 84 59 ff ff ff    	je     f0100847 <monitor+0x24>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008ee:	c7 44 24 04 07 1e 10 	movl   $0xf0101e07,0x4(%esp)
f01008f5:	f0 
f01008f6:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008f9:	89 04 24             	mov    %eax,(%esp)
f01008fc:	e8 df 0b 00 00       	call   f01014e0 <strcmp>
f0100901:	ba 00 00 00 00       	mov    $0x0,%edx
f0100906:	85 c0                	test   %eax,%eax
f0100908:	74 1c                	je     f0100926 <monitor+0x103>
f010090a:	c7 44 24 04 15 1e 10 	movl   $0xf0101e15,0x4(%esp)
f0100911:	f0 
f0100912:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100915:	89 04 24             	mov    %eax,(%esp)
f0100918:	e8 c3 0b 00 00       	call   f01014e0 <strcmp>
f010091d:	85 c0                	test   %eax,%eax
f010091f:	75 28                	jne    f0100949 <monitor+0x126>
f0100921:	ba 01 00 00 00       	mov    $0x1,%edx
			return commands[i].func(argc, argv, tf);
f0100926:	8d 04 12             	lea    (%edx,%edx,1),%eax
f0100929:	01 c2                	add    %eax,%edx
f010092b:	8b 45 08             	mov    0x8(%ebp),%eax
f010092e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100932:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100936:	89 34 24             	mov    %esi,(%esp)
f0100939:	ff 14 95 d8 1f 10 f0 	call   *-0xfefe028(,%edx,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100940:	85 c0                	test   %eax,%eax
f0100942:	78 1d                	js     f0100961 <monitor+0x13e>
f0100944:	e9 fe fe ff ff       	jmp    f0100847 <monitor+0x24>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100949:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010094c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100950:	c7 04 24 56 1e 10 f0 	movl   $0xf0101e56,(%esp)
f0100957:	e8 5e 00 00 00       	call   f01009ba <cprintf>
f010095c:	e9 e6 fe ff ff       	jmp    f0100847 <monitor+0x24>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100961:	83 c4 5c             	add    $0x5c,%esp
f0100964:	5b                   	pop    %ebx
f0100965:	5e                   	pop    %esi
f0100966:	5f                   	pop    %edi
f0100967:	5d                   	pop    %ebp
f0100968:	c3                   	ret    

f0100969 <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f0100969:	55                   	push   %ebp
f010096a:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f010096c:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f010096f:	5d                   	pop    %ebp
f0100970:	c3                   	ret    
f0100971:	00 00                	add    %al,(%eax)
	...

f0100974 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100974:	55                   	push   %ebp
f0100975:	89 e5                	mov    %esp,%ebp
f0100977:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f010097a:	8b 45 08             	mov    0x8(%ebp),%eax
f010097d:	89 04 24             	mov    %eax,(%esp)
f0100980:	e8 dc fc ff ff       	call   f0100661 <cputchar>
	*cnt++;
}
f0100985:	c9                   	leave  
f0100986:	c3                   	ret    

f0100987 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100987:	55                   	push   %ebp
f0100988:	89 e5                	mov    %esp,%ebp
f010098a:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f010098d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100994:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100997:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010099b:	8b 45 08             	mov    0x8(%ebp),%eax
f010099e:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009a2:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01009a5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009a9:	c7 04 24 74 09 10 f0 	movl   $0xf0100974,(%esp)
f01009b0:	e8 65 04 00 00       	call   f0100e1a <vprintfmt>
	return cnt;
}
f01009b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01009b8:	c9                   	leave  
f01009b9:	c3                   	ret    

f01009ba <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009ba:	55                   	push   %ebp
f01009bb:	89 e5                	mov    %esp,%ebp
f01009bd:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01009c0:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01009c3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009c7:	8b 45 08             	mov    0x8(%ebp),%eax
f01009ca:	89 04 24             	mov    %eax,(%esp)
f01009cd:	e8 b5 ff ff ff       	call   f0100987 <vcprintf>
	va_end(ap);

	return cnt;
}
f01009d2:	c9                   	leave  
f01009d3:	c3                   	ret    

f01009d4 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01009d4:	55                   	push   %ebp
f01009d5:	89 e5                	mov    %esp,%ebp
f01009d7:	57                   	push   %edi
f01009d8:	56                   	push   %esi
f01009d9:	53                   	push   %ebx
f01009da:	83 ec 10             	sub    $0x10,%esp
f01009dd:	89 c3                	mov    %eax,%ebx
f01009df:	89 55 e8             	mov    %edx,-0x18(%ebp)
f01009e2:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01009e5:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f01009e8:	8b 0a                	mov    (%edx),%ecx
f01009ea:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01009ed:	8b 00                	mov    (%eax),%eax
f01009ef:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009f2:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f01009f9:	eb 77                	jmp    f0100a72 <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f01009fb:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01009fe:	01 c8                	add    %ecx,%eax
f0100a00:	bf 02 00 00 00       	mov    $0x2,%edi
f0100a05:	99                   	cltd   
f0100a06:	f7 ff                	idiv   %edi
f0100a08:	89 c2                	mov    %eax,%edx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a0a:	eb 01                	jmp    f0100a0d <stab_binsearch+0x39>
			m--;
f0100a0c:	4a                   	dec    %edx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a0d:	39 ca                	cmp    %ecx,%edx
f0100a0f:	7c 1d                	jl     f0100a2e <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100a11:	6b fa 0c             	imul   $0xc,%edx,%edi
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a14:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f0100a19:	39 f7                	cmp    %esi,%edi
f0100a1b:	75 ef                	jne    f0100a0c <stab_binsearch+0x38>
f0100a1d:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a20:	6b fa 0c             	imul   $0xc,%edx,%edi
f0100a23:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f0100a27:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100a2a:	73 18                	jae    f0100a44 <stab_binsearch+0x70>
f0100a2c:	eb 05                	jmp    f0100a33 <stab_binsearch+0x5f>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a2e:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0100a31:	eb 3f                	jmp    f0100a72 <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100a33:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100a36:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0100a38:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a3b:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a42:	eb 2e                	jmp    f0100a72 <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a44:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100a47:	76 15                	jbe    f0100a5e <stab_binsearch+0x8a>
			*region_right = m - 1;
f0100a49:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100a4c:	4f                   	dec    %edi
f0100a4d:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0100a50:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a53:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a55:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a5c:	eb 14                	jmp    f0100a72 <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a5e:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100a61:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100a64:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f0100a66:	ff 45 0c             	incl   0xc(%ebp)
f0100a69:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a6b:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0100a72:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0100a75:	7e 84                	jle    f01009fb <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a77:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100a7b:	75 0d                	jne    f0100a8a <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0100a7d:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100a80:	8b 02                	mov    (%edx),%eax
f0100a82:	48                   	dec    %eax
f0100a83:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100a86:	89 01                	mov    %eax,(%ecx)
f0100a88:	eb 22                	jmp    f0100aac <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a8a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100a8d:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a8f:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100a92:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a94:	eb 01                	jmp    f0100a97 <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a96:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a97:	39 c1                	cmp    %eax,%ecx
f0100a99:	7d 0c                	jge    f0100aa7 <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100a9b:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0100a9e:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f0100aa3:	39 f2                	cmp    %esi,%edx
f0100aa5:	75 ef                	jne    f0100a96 <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100aa7:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100aaa:	89 02                	mov    %eax,(%edx)
	}
}
f0100aac:	83 c4 10             	add    $0x10,%esp
f0100aaf:	5b                   	pop    %ebx
f0100ab0:	5e                   	pop    %esi
f0100ab1:	5f                   	pop    %edi
f0100ab2:	5d                   	pop    %ebp
f0100ab3:	c3                   	ret    

f0100ab4 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100ab4:	55                   	push   %ebp
f0100ab5:	89 e5                	mov    %esp,%ebp
f0100ab7:	83 ec 38             	sub    $0x38,%esp
f0100aba:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100abd:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100ac0:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100ac3:	8b 75 08             	mov    0x8(%ebp),%esi
f0100ac6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100ac9:	c7 03 e8 1f 10 f0    	movl   $0xf0101fe8,(%ebx)
	info->eip_line = 0;
f0100acf:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100ad6:	c7 43 08 e8 1f 10 f0 	movl   $0xf0101fe8,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100add:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100ae4:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100ae7:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100aee:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100af4:	76 12                	jbe    f0100b08 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100af6:	b8 b3 78 10 f0       	mov    $0xf01078b3,%eax
f0100afb:	3d e1 5e 10 f0       	cmp    $0xf0105ee1,%eax
f0100b00:	0f 86 9b 01 00 00    	jbe    f0100ca1 <debuginfo_eip+0x1ed>
f0100b06:	eb 1c                	jmp    f0100b24 <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100b08:	c7 44 24 08 f2 1f 10 	movl   $0xf0101ff2,0x8(%esp)
f0100b0f:	f0 
f0100b10:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100b17:	00 
f0100b18:	c7 04 24 ff 1f 10 f0 	movl   $0xf0101fff,(%esp)
f0100b1f:	e8 e0 f5 ff ff       	call   f0100104 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100b24:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b29:	80 3d b2 78 10 f0 00 	cmpb   $0x0,0xf01078b2
f0100b30:	0f 85 77 01 00 00    	jne    f0100cad <debuginfo_eip+0x1f9>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b36:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b3d:	b8 e0 5e 10 f0       	mov    $0xf0105ee0,%eax
f0100b42:	2d 20 22 10 f0       	sub    $0xf0102220,%eax
f0100b47:	c1 f8 02             	sar    $0x2,%eax
f0100b4a:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b50:	83 e8 01             	sub    $0x1,%eax
f0100b53:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b56:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b5a:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100b61:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b64:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b67:	b8 20 22 10 f0       	mov    $0xf0102220,%eax
f0100b6c:	e8 63 fe ff ff       	call   f01009d4 <stab_binsearch>
	if (lfile == 0)
f0100b71:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0100b74:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0100b79:	85 d2                	test   %edx,%edx
f0100b7b:	0f 84 2c 01 00 00    	je     f0100cad <debuginfo_eip+0x1f9>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b81:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0100b84:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b87:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b8a:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b8e:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100b95:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b98:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b9b:	b8 20 22 10 f0       	mov    $0xf0102220,%eax
f0100ba0:	e8 2f fe ff ff       	call   f01009d4 <stab_binsearch>

	if (lfun <= rfun) {
f0100ba5:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100ba8:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0100bab:	7f 2e                	jg     f0100bdb <debuginfo_eip+0x127>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100bad:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100bb0:	8d 90 20 22 10 f0    	lea    -0xfefdde0(%eax),%edx
f0100bb6:	8b 80 20 22 10 f0    	mov    -0xfefdde0(%eax),%eax
f0100bbc:	b9 b3 78 10 f0       	mov    $0xf01078b3,%ecx
f0100bc1:	81 e9 e1 5e 10 f0    	sub    $0xf0105ee1,%ecx
f0100bc7:	39 c8                	cmp    %ecx,%eax
f0100bc9:	73 08                	jae    f0100bd3 <debuginfo_eip+0x11f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100bcb:	05 e1 5e 10 f0       	add    $0xf0105ee1,%eax
f0100bd0:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100bd3:	8b 42 08             	mov    0x8(%edx),%eax
f0100bd6:	89 43 10             	mov    %eax,0x10(%ebx)
f0100bd9:	eb 06                	jmp    f0100be1 <debuginfo_eip+0x12d>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100bdb:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100bde:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100be1:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100be8:	00 
f0100be9:	8b 43 08             	mov    0x8(%ebx),%eax
f0100bec:	89 04 24             	mov    %eax,(%esp)
f0100bef:	e8 9b 09 00 00       	call   f010158f <strfind>
f0100bf4:	2b 43 08             	sub    0x8(%ebx),%eax
f0100bf7:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100bfa:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100bfd:	39 d7                	cmp    %edx,%edi
f0100bff:	7c 5f                	jl     f0100c60 <debuginfo_eip+0x1ac>
	       && stabs[lline].n_type != N_SOL
f0100c01:	89 f8                	mov    %edi,%eax
f0100c03:	6b cf 0c             	imul   $0xc,%edi,%ecx
f0100c06:	80 b9 24 22 10 f0 84 	cmpb   $0x84,-0xfefdddc(%ecx)
f0100c0d:	75 18                	jne    f0100c27 <debuginfo_eip+0x173>
f0100c0f:	eb 30                	jmp    f0100c41 <debuginfo_eip+0x18d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100c11:	83 ef 01             	sub    $0x1,%edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c14:	39 fa                	cmp    %edi,%edx
f0100c16:	7f 48                	jg     f0100c60 <debuginfo_eip+0x1ac>
	       && stabs[lline].n_type != N_SOL
f0100c18:	89 f8                	mov    %edi,%eax
f0100c1a:	8d 0c 7f             	lea    (%edi,%edi,2),%ecx
f0100c1d:	80 3c 8d 24 22 10 f0 	cmpb   $0x84,-0xfefdddc(,%ecx,4)
f0100c24:	84 
f0100c25:	74 1a                	je     f0100c41 <debuginfo_eip+0x18d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c27:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100c2a:	8d 04 85 20 22 10 f0 	lea    -0xfefdde0(,%eax,4),%eax
f0100c31:	80 78 04 64          	cmpb   $0x64,0x4(%eax)
f0100c35:	75 da                	jne    f0100c11 <debuginfo_eip+0x15d>
f0100c37:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100c3b:	74 d4                	je     f0100c11 <debuginfo_eip+0x15d>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c3d:	39 fa                	cmp    %edi,%edx
f0100c3f:	7f 1f                	jg     f0100c60 <debuginfo_eip+0x1ac>
f0100c41:	6b ff 0c             	imul   $0xc,%edi,%edi
f0100c44:	8b 87 20 22 10 f0    	mov    -0xfefdde0(%edi),%eax
f0100c4a:	ba b3 78 10 f0       	mov    $0xf01078b3,%edx
f0100c4f:	81 ea e1 5e 10 f0    	sub    $0xf0105ee1,%edx
f0100c55:	39 d0                	cmp    %edx,%eax
f0100c57:	73 07                	jae    f0100c60 <debuginfo_eip+0x1ac>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c59:	05 e1 5e 10 f0       	add    $0xf0105ee1,%eax
f0100c5e:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c60:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c63:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100c66:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c6b:	39 ca                	cmp    %ecx,%edx
f0100c6d:	7d 3e                	jge    f0100cad <debuginfo_eip+0x1f9>
		for (lline = lfun + 1;
f0100c6f:	83 c2 01             	add    $0x1,%edx
f0100c72:	39 d1                	cmp    %edx,%ecx
f0100c74:	7e 37                	jle    f0100cad <debuginfo_eip+0x1f9>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c76:	6b f2 0c             	imul   $0xc,%edx,%esi
f0100c79:	80 be 24 22 10 f0 a0 	cmpb   $0xa0,-0xfefdddc(%esi)
f0100c80:	75 2b                	jne    f0100cad <debuginfo_eip+0x1f9>
		     lline++)
			info->eip_fn_narg++;
f0100c82:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100c86:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c89:	39 d1                	cmp    %edx,%ecx
f0100c8b:	7e 1b                	jle    f0100ca8 <debuginfo_eip+0x1f4>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c8d:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100c90:	80 3c 85 24 22 10 f0 	cmpb   $0xa0,-0xfefdddc(,%eax,4)
f0100c97:	a0 
f0100c98:	74 e8                	je     f0100c82 <debuginfo_eip+0x1ce>
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100c9a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c9f:	eb 0c                	jmp    f0100cad <debuginfo_eip+0x1f9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100ca1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ca6:	eb 05                	jmp    f0100cad <debuginfo_eip+0x1f9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100ca8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100cad:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100cb0:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100cb3:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100cb6:	89 ec                	mov    %ebp,%esp
f0100cb8:	5d                   	pop    %ebp
f0100cb9:	c3                   	ret    
f0100cba:	00 00                	add    %al,(%eax)
f0100cbc:	00 00                	add    %al,(%eax)
	...

f0100cc0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100cc0:	55                   	push   %ebp
f0100cc1:	89 e5                	mov    %esp,%ebp
f0100cc3:	57                   	push   %edi
f0100cc4:	56                   	push   %esi
f0100cc5:	53                   	push   %ebx
f0100cc6:	83 ec 3c             	sub    $0x3c,%esp
f0100cc9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100ccc:	89 d7                	mov    %edx,%edi
f0100cce:	8b 45 08             	mov    0x8(%ebp),%eax
f0100cd1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100cd4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100cd7:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100cda:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100cdd:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100ce0:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ce5:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100ce8:	72 11                	jb     f0100cfb <printnum+0x3b>
f0100cea:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100ced:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100cf0:	76 09                	jbe    f0100cfb <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100cf2:	83 eb 01             	sub    $0x1,%ebx
f0100cf5:	85 db                	test   %ebx,%ebx
f0100cf7:	7f 51                	jg     f0100d4a <printnum+0x8a>
f0100cf9:	eb 5e                	jmp    f0100d59 <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100cfb:	89 74 24 10          	mov    %esi,0x10(%esp)
f0100cff:	83 eb 01             	sub    $0x1,%ebx
f0100d02:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100d06:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d09:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d0d:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0100d11:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0100d15:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100d1c:	00 
f0100d1d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100d20:	89 04 24             	mov    %eax,(%esp)
f0100d23:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d26:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d2a:	e8 e1 0a 00 00       	call   f0101810 <__udivdi3>
f0100d2f:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100d33:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100d37:	89 04 24             	mov    %eax,(%esp)
f0100d3a:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100d3e:	89 fa                	mov    %edi,%edx
f0100d40:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d43:	e8 78 ff ff ff       	call   f0100cc0 <printnum>
f0100d48:	eb 0f                	jmp    f0100d59 <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d4a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d4e:	89 34 24             	mov    %esi,(%esp)
f0100d51:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d54:	83 eb 01             	sub    $0x1,%ebx
f0100d57:	75 f1                	jne    f0100d4a <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d59:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d5d:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100d61:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d64:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d68:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100d6f:	00 
f0100d70:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100d73:	89 04 24             	mov    %eax,(%esp)
f0100d76:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d79:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d7d:	e8 be 0b 00 00       	call   f0101940 <__umoddi3>
f0100d82:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d86:	0f be 80 0d 20 10 f0 	movsbl -0xfefdff3(%eax),%eax
f0100d8d:	89 04 24             	mov    %eax,(%esp)
f0100d90:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0100d93:	83 c4 3c             	add    $0x3c,%esp
f0100d96:	5b                   	pop    %ebx
f0100d97:	5e                   	pop    %esi
f0100d98:	5f                   	pop    %edi
f0100d99:	5d                   	pop    %ebp
f0100d9a:	c3                   	ret    

f0100d9b <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100d9b:	55                   	push   %ebp
f0100d9c:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100d9e:	83 fa 01             	cmp    $0x1,%edx
f0100da1:	7e 0e                	jle    f0100db1 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100da3:	8b 10                	mov    (%eax),%edx
f0100da5:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100da8:	89 08                	mov    %ecx,(%eax)
f0100daa:	8b 02                	mov    (%edx),%eax
f0100dac:	8b 52 04             	mov    0x4(%edx),%edx
f0100daf:	eb 22                	jmp    f0100dd3 <getuint+0x38>
	else if (lflag)
f0100db1:	85 d2                	test   %edx,%edx
f0100db3:	74 10                	je     f0100dc5 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100db5:	8b 10                	mov    (%eax),%edx
f0100db7:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100dba:	89 08                	mov    %ecx,(%eax)
f0100dbc:	8b 02                	mov    (%edx),%eax
f0100dbe:	ba 00 00 00 00       	mov    $0x0,%edx
f0100dc3:	eb 0e                	jmp    f0100dd3 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100dc5:	8b 10                	mov    (%eax),%edx
f0100dc7:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100dca:	89 08                	mov    %ecx,(%eax)
f0100dcc:	8b 02                	mov    (%edx),%eax
f0100dce:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100dd3:	5d                   	pop    %ebp
f0100dd4:	c3                   	ret    

f0100dd5 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100dd5:	55                   	push   %ebp
f0100dd6:	89 e5                	mov    %esp,%ebp
f0100dd8:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100ddb:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100ddf:	8b 10                	mov    (%eax),%edx
f0100de1:	3b 50 04             	cmp    0x4(%eax),%edx
f0100de4:	73 0a                	jae    f0100df0 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100de6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100de9:	88 0a                	mov    %cl,(%edx)
f0100deb:	83 c2 01             	add    $0x1,%edx
f0100dee:	89 10                	mov    %edx,(%eax)
}
f0100df0:	5d                   	pop    %ebp
f0100df1:	c3                   	ret    

f0100df2 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100df2:	55                   	push   %ebp
f0100df3:	89 e5                	mov    %esp,%ebp
f0100df5:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100df8:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100dfb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100dff:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e02:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e06:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e09:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e0d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e10:	89 04 24             	mov    %eax,(%esp)
f0100e13:	e8 02 00 00 00       	call   f0100e1a <vprintfmt>
	va_end(ap);
}
f0100e18:	c9                   	leave  
f0100e19:	c3                   	ret    

f0100e1a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100e1a:	55                   	push   %ebp
f0100e1b:	89 e5                	mov    %esp,%ebp
f0100e1d:	57                   	push   %edi
f0100e1e:	56                   	push   %esi
f0100e1f:	53                   	push   %ebx
f0100e20:	83 ec 3c             	sub    $0x3c,%esp
f0100e23:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100e26:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100e29:	e9 bb 00 00 00       	jmp    f0100ee9 <vprintfmt+0xcf>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100e2e:	85 c0                	test   %eax,%eax
f0100e30:	0f 84 63 04 00 00    	je     f0101299 <vprintfmt+0x47f>
				return;
			if (ch =='\033'){//if this is Escape character  and this if is char color set.
f0100e36:	83 f8 1b             	cmp    $0x1b,%eax
f0100e39:	0f 85 9a 00 00 00    	jne    f0100ed9 <vprintfmt+0xbf>
				int temp_color_no=0;
				ch = *(unsigned char *) fmt++;
f0100e3f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100e42:	83 c3 02             	add    $0x2,%ebx
				while (ch != 'm') 
f0100e45:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e48:	80 78 01 6d          	cmpb   $0x6d,0x1(%eax)
f0100e4c:	0f 84 81 00 00 00    	je     f0100ed3 <vprintfmt+0xb9>
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
				return;
			if (ch =='\033'){//if this is Escape character  and this if is char color set.
				int temp_color_no=0;
f0100e52:	ba 00 00 00 00       	mov    $0x0,%edx
				ch = *(unsigned char *) fmt++;
				while (ch != 'm') 
				{
					ch = *(unsigned char *) fmt++;
f0100e57:	0f b6 03             	movzbl (%ebx),%eax
f0100e5a:	83 c3 01             	add    $0x1,%ebx
					if ( ch !=';' && ch!='m')
f0100e5d:	83 f8 6d             	cmp    $0x6d,%eax
f0100e60:	0f 95 c1             	setne  %cl
f0100e63:	83 f8 3b             	cmp    $0x3b,%eax
f0100e66:	74 0d                	je     f0100e75 <vprintfmt+0x5b>
f0100e68:	84 c9                	test   %cl,%cl
f0100e6a:	74 09                	je     f0100e75 <vprintfmt+0x5b>
						temp_color_no=temp_color_no*10+ch-'0';
f0100e6c:	8d 14 92             	lea    (%edx,%edx,4),%edx
f0100e6f:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
f0100e73:	eb 55                	jmp    f0100eca <vprintfmt+0xb0>
					else if ( ch==';' || ch=='m'){
f0100e75:	83 f8 3b             	cmp    $0x3b,%eax
f0100e78:	74 05                	je     f0100e7f <vprintfmt+0x65>
f0100e7a:	83 f8 6d             	cmp    $0x6d,%eax
f0100e7d:	75 4b                	jne    f0100eca <vprintfmt+0xb0>
						if ( temp_color_no >=30 && temp_color_no<40){// Foreground colors
f0100e7f:	89 d6                	mov    %edx,%esi
f0100e81:	8d 7a e2             	lea    -0x1e(%edx),%edi
f0100e84:	83 ff 09             	cmp    $0x9,%edi
f0100e87:	77 16                	ja     f0100e9f <vprintfmt+0x85>
							char_color = (char_color&0xf0) + (temp_color_no-30);						
f0100e89:	8b 3d 00 23 11 f0    	mov    0xf0112300,%edi
f0100e8f:	81 e7 f0 00 00 00    	and    $0xf0,%edi
f0100e95:	8d 7c 3a e2          	lea    -0x1e(%edx,%edi,1),%edi
f0100e99:	89 3d 00 23 11 f0    	mov    %edi,0xf0112300
							}
						if ( temp_color_no >=40 && temp_color_no<50){// Background colors
f0100e9f:	83 ee 28             	sub    $0x28,%esi
f0100ea2:	83 fe 09             	cmp    $0x9,%esi
f0100ea5:	77 1e                	ja     f0100ec5 <vprintfmt+0xab>
							char_color = (char_color&0x0f) + ((temp_color_no-40)<<4);
f0100ea7:	8b 35 00 23 11 f0    	mov    0xf0112300,%esi
f0100ead:	83 e6 0f             	and    $0xf,%esi
f0100eb0:	83 ea 28             	sub    $0x28,%edx
f0100eb3:	c1 e2 04             	shl    $0x4,%edx
f0100eb6:	01 f2                	add    %esi,%edx
f0100eb8:	89 15 00 23 11 f0    	mov    %edx,0xf0112300
						}
						//cprintf("0x%o ,",char_color);
						temp_color_no=0;
f0100ebe:	ba 00 00 00 00       	mov    $0x0,%edx
f0100ec3:	eb 05                	jmp    f0100eca <vprintfmt+0xb0>
f0100ec5:	ba 00 00 00 00       	mov    $0x0,%edx
			if (ch == '\0')
				return;
			if (ch =='\033'){//if this is Escape character  and this if is char color set.
				int temp_color_no=0;
				ch = *(unsigned char *) fmt++;
				while (ch != 'm') 
f0100eca:	84 c9                	test   %cl,%cl
f0100ecc:	75 89                	jne    f0100e57 <vprintfmt+0x3d>
						}
						//cprintf("0x%o ,",char_color);
						temp_color_no=0;
					}
				}
				if (ch == 'm')
f0100ece:	83 f8 6d             	cmp    $0x6d,%eax
f0100ed1:	75 06                	jne    f0100ed9 <vprintfmt+0xbf>
					ch = *(unsigned char *) fmt++;
f0100ed3:	0f b6 03             	movzbl (%ebx),%eax
f0100ed6:	83 c3 01             	add    $0x1,%ebx
				
			}
			putch(ch, putdat);
f0100ed9:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100edc:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100ee0:	89 04 24             	mov    %eax,(%esp)
f0100ee3:	ff 55 08             	call   *0x8(%ebp)
f0100ee6:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100ee9:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100eec:	0f b6 03             	movzbl (%ebx),%eax
f0100eef:	83 c3 01             	add    $0x1,%ebx
f0100ef2:	83 f8 25             	cmp    $0x25,%eax
f0100ef5:	0f 85 33 ff ff ff    	jne    f0100e2e <vprintfmt+0x14>
f0100efb:	c6 45 e0 20          	movb   $0x20,-0x20(%ebp)
f0100eff:	bf 00 00 00 00       	mov    $0x0,%edi
f0100f04:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0100f09:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0100f10:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100f15:	eb 23                	jmp    f0100f3a <vprintfmt+0x120>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f17:	89 c3                	mov    %eax,%ebx

		// flag to pad on the right
		case '-':
			padc = '-';
f0100f19:	c6 45 e0 2d          	movb   $0x2d,-0x20(%ebp)
f0100f1d:	eb 1b                	jmp    f0100f3a <vprintfmt+0x120>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f1f:	89 c3                	mov    %eax,%ebx
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100f21:	c6 45 e0 30          	movb   $0x30,-0x20(%ebp)
f0100f25:	eb 13                	jmp    f0100f3a <vprintfmt+0x120>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f27:	89 c3                	mov    %eax,%ebx
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0100f29:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0100f30:	eb 08                	jmp    f0100f3a <vprintfmt+0x120>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100f32:	89 75 dc             	mov    %esi,-0x24(%ebp)
f0100f35:	be ff ff ff ff       	mov    $0xffffffff,%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f3a:	0f b6 13             	movzbl (%ebx),%edx
f0100f3d:	0f b6 c2             	movzbl %dl,%eax
f0100f40:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100f43:	8d 43 01             	lea    0x1(%ebx),%eax
f0100f46:	83 ea 23             	sub    $0x23,%edx
f0100f49:	80 fa 55             	cmp    $0x55,%dl
f0100f4c:	0f 87 18 03 00 00    	ja     f010126a <vprintfmt+0x450>
f0100f52:	0f b6 d2             	movzbl %dl,%edx
f0100f55:	ff 24 95 9c 20 10 f0 	jmp    *-0xfefdf64(,%edx,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100f5c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100f5f:	83 ee 30             	sub    $0x30,%esi
				ch = *fmt;
f0100f62:	0f be 53 01          	movsbl 0x1(%ebx),%edx
				if (ch < '0' || ch > '9')
f0100f66:	8d 5a d0             	lea    -0x30(%edx),%ebx
f0100f69:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f6c:	89 c3                	mov    %eax,%ebx
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f0100f6e:	83 7d e4 09          	cmpl   $0x9,-0x1c(%ebp)
f0100f72:	77 3b                	ja     f0100faf <vprintfmt+0x195>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100f74:	83 c0 01             	add    $0x1,%eax
				precision = precision * 10 + ch - '0';
f0100f77:	8d 1c b6             	lea    (%esi,%esi,4),%ebx
f0100f7a:	8d 74 5a d0          	lea    -0x30(%edx,%ebx,2),%esi
				ch = *fmt;
f0100f7e:	0f be 10             	movsbl (%eax),%edx
				if (ch < '0' || ch > '9')
f0100f81:	8d 5a d0             	lea    -0x30(%edx),%ebx
f0100f84:	83 fb 09             	cmp    $0x9,%ebx
f0100f87:	76 eb                	jbe    f0100f74 <vprintfmt+0x15a>
f0100f89:	eb 22                	jmp    f0100fad <vprintfmt+0x193>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100f8b:	8b 55 14             	mov    0x14(%ebp),%edx
f0100f8e:	8d 5a 04             	lea    0x4(%edx),%ebx
f0100f91:	89 5d 14             	mov    %ebx,0x14(%ebp)
f0100f94:	8b 32                	mov    (%edx),%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f96:	89 c3                	mov    %eax,%ebx
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100f98:	eb 15                	jmp    f0100faf <vprintfmt+0x195>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f9a:	89 c3                	mov    %eax,%ebx
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f0100f9c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100fa0:	79 98                	jns    f0100f3a <vprintfmt+0x120>
f0100fa2:	eb 83                	jmp    f0100f27 <vprintfmt+0x10d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fa4:	89 c3                	mov    %eax,%ebx
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100fa6:	bf 01 00 00 00       	mov    $0x1,%edi
			goto reswitch;
f0100fab:	eb 8d                	jmp    f0100f3a <vprintfmt+0x120>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100fad:	89 c3                	mov    %eax,%ebx
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f0100faf:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100fb3:	79 85                	jns    f0100f3a <vprintfmt+0x120>
f0100fb5:	e9 78 ff ff ff       	jmp    f0100f32 <vprintfmt+0x118>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100fba:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fbd:	89 c3                	mov    %eax,%ebx
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100fbf:	e9 76 ff ff ff       	jmp    f0100f3a <vprintfmt+0x120>
f0100fc4:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100fc7:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fca:	8d 50 04             	lea    0x4(%eax),%edx
f0100fcd:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fd0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100fd3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100fd7:	8b 00                	mov    (%eax),%eax
f0100fd9:	89 04 24             	mov    %eax,(%esp)
f0100fdc:	ff 55 08             	call   *0x8(%ebp)
			break;
f0100fdf:	e9 05 ff ff ff       	jmp    f0100ee9 <vprintfmt+0xcf>
f0100fe4:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100fe7:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fea:	8d 50 04             	lea    0x4(%eax),%edx
f0100fed:	89 55 14             	mov    %edx,0x14(%ebp)
f0100ff0:	8b 00                	mov    (%eax),%eax
f0100ff2:	89 c2                	mov    %eax,%edx
f0100ff4:	c1 fa 1f             	sar    $0x1f,%edx
f0100ff7:	31 d0                	xor    %edx,%eax
f0100ff9:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100ffb:	83 f8 06             	cmp    $0x6,%eax
f0100ffe:	7f 0b                	jg     f010100b <vprintfmt+0x1f1>
f0101000:	8b 14 85 f4 21 10 f0 	mov    -0xfefde0c(,%eax,4),%edx
f0101007:	85 d2                	test   %edx,%edx
f0101009:	75 23                	jne    f010102e <vprintfmt+0x214>
				printfmt(putch, putdat, "error %d", err);
f010100b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010100f:	c7 44 24 08 25 20 10 	movl   $0xf0102025,0x8(%esp)
f0101016:	f0 
f0101017:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010101a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010101e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101021:	89 1c 24             	mov    %ebx,(%esp)
f0101024:	e8 c9 fd ff ff       	call   f0100df2 <printfmt>
f0101029:	e9 bb fe ff ff       	jmp    f0100ee9 <vprintfmt+0xcf>
			else
				printfmt(putch, putdat, "%s", p);
f010102e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101032:	c7 44 24 08 2e 20 10 	movl   $0xf010202e,0x8(%esp)
f0101039:	f0 
f010103a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010103d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101041:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101044:	89 1c 24             	mov    %ebx,(%esp)
f0101047:	e8 a6 fd ff ff       	call   f0100df2 <printfmt>
f010104c:	e9 98 fe ff ff       	jmp    f0100ee9 <vprintfmt+0xcf>
f0101051:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101054:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0101057:	89 5d d8             	mov    %ebx,-0x28(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010105a:	8b 45 14             	mov    0x14(%ebp),%eax
f010105d:	8d 50 04             	lea    0x4(%eax),%edx
f0101060:	89 55 14             	mov    %edx,0x14(%ebp)
f0101063:	8b 18                	mov    (%eax),%ebx
				p = "(null)";
f0101065:	85 db                	test   %ebx,%ebx
f0101067:	b8 1e 20 10 f0       	mov    $0xf010201e,%eax
f010106c:	0f 44 d8             	cmove  %eax,%ebx
			if (width > 0 && padc != '-')
f010106f:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101073:	7e 06                	jle    f010107b <vprintfmt+0x261>
f0101075:	80 7d e0 2d          	cmpb   $0x2d,-0x20(%ebp)
f0101079:	75 10                	jne    f010108b <vprintfmt+0x271>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010107b:	0f be 03             	movsbl (%ebx),%eax
f010107e:	83 c3 01             	add    $0x1,%ebx
f0101081:	85 c0                	test   %eax,%eax
f0101083:	0f 85 82 00 00 00    	jne    f010110b <vprintfmt+0x2f1>
f0101089:	eb 75                	jmp    f0101100 <vprintfmt+0x2e6>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010108b:	89 74 24 04          	mov    %esi,0x4(%esp)
f010108f:	89 1c 24             	mov    %ebx,(%esp)
f0101092:	e8 84 03 00 00       	call   f010141b <strnlen>
f0101097:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010109a:	29 c2                	sub    %eax,%edx
f010109c:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010109f:	85 d2                	test   %edx,%edx
f01010a1:	7e d8                	jle    f010107b <vprintfmt+0x261>
					putch(padc, putdat);
f01010a3:	0f be 45 e0          	movsbl -0x20(%ebp),%eax
f01010a7:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01010aa:	8b 55 0c             	mov    0xc(%ebp),%edx
f01010ad:	89 54 24 04          	mov    %edx,0x4(%esp)
f01010b1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01010b4:	89 04 24             	mov    %eax,(%esp)
f01010b7:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01010ba:	83 6d dc 01          	subl   $0x1,-0x24(%ebp)
f01010be:	75 ea                	jne    f01010aa <vprintfmt+0x290>
f01010c0:	eb b9                	jmp    f010107b <vprintfmt+0x261>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01010c2:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01010c6:	74 1b                	je     f01010e3 <vprintfmt+0x2c9>
f01010c8:	8d 50 e0             	lea    -0x20(%eax),%edx
f01010cb:	83 fa 5e             	cmp    $0x5e,%edx
f01010ce:	76 13                	jbe    f01010e3 <vprintfmt+0x2c9>
					putch('?', putdat);
f01010d0:	8b 55 0c             	mov    0xc(%ebp),%edx
f01010d3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01010d7:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01010de:	ff 55 08             	call   *0x8(%ebp)
f01010e1:	eb 0d                	jmp    f01010f0 <vprintfmt+0x2d6>
				else
					putch(ch, putdat);
f01010e3:	8b 55 0c             	mov    0xc(%ebp),%edx
f01010e6:	89 54 24 04          	mov    %edx,0x4(%esp)
f01010ea:	89 04 24             	mov    %eax,(%esp)
f01010ed:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01010f0:	83 ef 01             	sub    $0x1,%edi
f01010f3:	0f be 03             	movsbl (%ebx),%eax
f01010f6:	83 c3 01             	add    $0x1,%ebx
f01010f9:	85 c0                	test   %eax,%eax
f01010fb:	75 14                	jne    f0101111 <vprintfmt+0x2f7>
f01010fd:	89 7d dc             	mov    %edi,-0x24(%ebp)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101100:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101104:	7f 19                	jg     f010111f <vprintfmt+0x305>
f0101106:	e9 de fd ff ff       	jmp    f0100ee9 <vprintfmt+0xcf>
f010110b:	89 7d e0             	mov    %edi,-0x20(%ebp)
f010110e:	8b 7d dc             	mov    -0x24(%ebp),%edi
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101111:	85 f6                	test   %esi,%esi
f0101113:	78 ad                	js     f01010c2 <vprintfmt+0x2a8>
f0101115:	83 ee 01             	sub    $0x1,%esi
f0101118:	79 a8                	jns    f01010c2 <vprintfmt+0x2a8>
f010111a:	89 7d dc             	mov    %edi,-0x24(%ebp)
f010111d:	eb e1                	jmp    f0101100 <vprintfmt+0x2e6>
f010111f:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0101122:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101125:	8b 75 0c             	mov    0xc(%ebp),%esi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101128:	89 74 24 04          	mov    %esi,0x4(%esp)
f010112c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101133:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101135:	83 eb 01             	sub    $0x1,%ebx
f0101138:	75 ee                	jne    f0101128 <vprintfmt+0x30e>
f010113a:	e9 aa fd ff ff       	jmp    f0100ee9 <vprintfmt+0xcf>
f010113f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101142:	83 f9 01             	cmp    $0x1,%ecx
f0101145:	7e 10                	jle    f0101157 <vprintfmt+0x33d>
		return va_arg(*ap, long long);
f0101147:	8b 45 14             	mov    0x14(%ebp),%eax
f010114a:	8d 50 08             	lea    0x8(%eax),%edx
f010114d:	89 55 14             	mov    %edx,0x14(%ebp)
f0101150:	8b 30                	mov    (%eax),%esi
f0101152:	8b 78 04             	mov    0x4(%eax),%edi
f0101155:	eb 26                	jmp    f010117d <vprintfmt+0x363>
	else if (lflag)
f0101157:	85 c9                	test   %ecx,%ecx
f0101159:	74 12                	je     f010116d <vprintfmt+0x353>
		return va_arg(*ap, long);
f010115b:	8b 45 14             	mov    0x14(%ebp),%eax
f010115e:	8d 50 04             	lea    0x4(%eax),%edx
f0101161:	89 55 14             	mov    %edx,0x14(%ebp)
f0101164:	8b 30                	mov    (%eax),%esi
f0101166:	89 f7                	mov    %esi,%edi
f0101168:	c1 ff 1f             	sar    $0x1f,%edi
f010116b:	eb 10                	jmp    f010117d <vprintfmt+0x363>
	else
		return va_arg(*ap, int);
f010116d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101170:	8d 50 04             	lea    0x4(%eax),%edx
f0101173:	89 55 14             	mov    %edx,0x14(%ebp)
f0101176:	8b 30                	mov    (%eax),%esi
f0101178:	89 f7                	mov    %esi,%edi
f010117a:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010117d:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101182:	85 ff                	test   %edi,%edi
f0101184:	0f 89 9e 00 00 00    	jns    f0101228 <vprintfmt+0x40e>
				putch('-', putdat);
f010118a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010118d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101191:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0101198:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010119b:	f7 de                	neg    %esi
f010119d:	83 d7 00             	adc    $0x0,%edi
f01011a0:	f7 df                	neg    %edi
			}
			base = 10;
f01011a2:	b8 0a 00 00 00       	mov    $0xa,%eax
f01011a7:	eb 7f                	jmp    f0101228 <vprintfmt+0x40e>
f01011a9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01011ac:	89 ca                	mov    %ecx,%edx
f01011ae:	8d 45 14             	lea    0x14(%ebp),%eax
f01011b1:	e8 e5 fb ff ff       	call   f0100d9b <getuint>
f01011b6:	89 c6                	mov    %eax,%esi
f01011b8:	89 d7                	mov    %edx,%edi
			base = 10;
f01011ba:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f01011bf:	eb 67                	jmp    f0101228 <vprintfmt+0x40e>
f01011c1:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap,lflag);
f01011c4:	89 ca                	mov    %ecx,%edx
f01011c6:	8d 45 14             	lea    0x14(%ebp),%eax
f01011c9:	e8 cd fb ff ff       	call   f0100d9b <getuint>
f01011ce:	89 c6                	mov    %eax,%esi
f01011d0:	89 d7                	mov    %edx,%edi
			base = 8;
f01011d2:	b8 08 00 00 00       	mov    $0x8,%eax

			goto number;
f01011d7:	eb 4f                	jmp    f0101228 <vprintfmt+0x40e>
f01011d9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// pointer
		case 'p':
			putch('0', putdat);
f01011dc:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01011df:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011e3:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01011ea:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01011ed:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011f1:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01011f8:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01011fb:	8b 45 14             	mov    0x14(%ebp),%eax
f01011fe:	8d 50 04             	lea    0x4(%eax),%edx
f0101201:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101204:	8b 30                	mov    (%eax),%esi
f0101206:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010120b:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0101210:	eb 16                	jmp    f0101228 <vprintfmt+0x40e>
f0101212:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101215:	89 ca                	mov    %ecx,%edx
f0101217:	8d 45 14             	lea    0x14(%ebp),%eax
f010121a:	e8 7c fb ff ff       	call   f0100d9b <getuint>
f010121f:	89 c6                	mov    %eax,%esi
f0101221:	89 d7                	mov    %edx,%edi
			base = 16;
f0101223:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101228:	0f be 55 e0          	movsbl -0x20(%ebp),%edx
f010122c:	89 54 24 10          	mov    %edx,0x10(%esp)
f0101230:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0101233:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0101237:	89 44 24 08          	mov    %eax,0x8(%esp)
f010123b:	89 34 24             	mov    %esi,(%esp)
f010123e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101242:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101245:	8b 45 08             	mov    0x8(%ebp),%eax
f0101248:	e8 73 fa ff ff       	call   f0100cc0 <printnum>
			break;
f010124d:	e9 97 fc ff ff       	jmp    f0100ee9 <vprintfmt+0xcf>
f0101252:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101255:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101258:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010125b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010125f:	89 14 24             	mov    %edx,(%esp)
f0101262:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101265:	e9 7f fc ff ff       	jmp    f0100ee9 <vprintfmt+0xcf>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010126a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010126d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101271:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101278:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f010127b:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f010127e:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0101282:	0f 84 61 fc ff ff    	je     f0100ee9 <vprintfmt+0xcf>
f0101288:	83 eb 01             	sub    $0x1,%ebx
f010128b:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f010128f:	75 f7                	jne    f0101288 <vprintfmt+0x46e>
f0101291:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0101294:	e9 50 fc ff ff       	jmp    f0100ee9 <vprintfmt+0xcf>
				/* do nothing */;
			break;
		}
	}
}
f0101299:	83 c4 3c             	add    $0x3c,%esp
f010129c:	5b                   	pop    %ebx
f010129d:	5e                   	pop    %esi
f010129e:	5f                   	pop    %edi
f010129f:	5d                   	pop    %ebp
f01012a0:	c3                   	ret    

f01012a1 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01012a1:	55                   	push   %ebp
f01012a2:	89 e5                	mov    %esp,%ebp
f01012a4:	83 ec 28             	sub    $0x28,%esp
f01012a7:	8b 45 08             	mov    0x8(%ebp),%eax
f01012aa:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01012ad:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01012b0:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01012b4:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01012b7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01012be:	85 c0                	test   %eax,%eax
f01012c0:	74 30                	je     f01012f2 <vsnprintf+0x51>
f01012c2:	85 d2                	test   %edx,%edx
f01012c4:	7e 2c                	jle    f01012f2 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01012c6:	8b 45 14             	mov    0x14(%ebp),%eax
f01012c9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012cd:	8b 45 10             	mov    0x10(%ebp),%eax
f01012d0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012d4:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01012d7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012db:	c7 04 24 d5 0d 10 f0 	movl   $0xf0100dd5,(%esp)
f01012e2:	e8 33 fb ff ff       	call   f0100e1a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01012e7:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01012ea:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01012ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01012f0:	eb 05                	jmp    f01012f7 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01012f2:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01012f7:	c9                   	leave  
f01012f8:	c3                   	ret    

f01012f9 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01012f9:	55                   	push   %ebp
f01012fa:	89 e5                	mov    %esp,%ebp
f01012fc:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01012ff:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101302:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101306:	8b 45 10             	mov    0x10(%ebp),%eax
f0101309:	89 44 24 08          	mov    %eax,0x8(%esp)
f010130d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101310:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101314:	8b 45 08             	mov    0x8(%ebp),%eax
f0101317:	89 04 24             	mov    %eax,(%esp)
f010131a:	e8 82 ff ff ff       	call   f01012a1 <vsnprintf>
	va_end(ap);

	return rc;
}
f010131f:	c9                   	leave  
f0101320:	c3                   	ret    
	...

f0101330 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101330:	55                   	push   %ebp
f0101331:	89 e5                	mov    %esp,%ebp
f0101333:	57                   	push   %edi
f0101334:	56                   	push   %esi
f0101335:	53                   	push   %ebx
f0101336:	83 ec 1c             	sub    $0x1c,%esp
f0101339:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010133c:	85 c0                	test   %eax,%eax
f010133e:	74 10                	je     f0101350 <readline+0x20>
		cprintf("%s", prompt);
f0101340:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101344:	c7 04 24 2e 20 10 f0 	movl   $0xf010202e,(%esp)
f010134b:	e8 6a f6 ff ff       	call   f01009ba <cprintf>

	i = 0;
	echoing = iscons(0);
f0101350:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101357:	e8 26 f3 ff ff       	call   f0100682 <iscons>
f010135c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010135e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101363:	e8 09 f3 ff ff       	call   f0100671 <getchar>
f0101368:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010136a:	85 c0                	test   %eax,%eax
f010136c:	79 17                	jns    f0101385 <readline+0x55>
			cprintf("read error: %e\n", c);
f010136e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101372:	c7 04 24 10 22 10 f0 	movl   $0xf0102210,(%esp)
f0101379:	e8 3c f6 ff ff       	call   f01009ba <cprintf>
			return NULL;
f010137e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101383:	eb 6d                	jmp    f01013f2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101385:	83 f8 08             	cmp    $0x8,%eax
f0101388:	74 05                	je     f010138f <readline+0x5f>
f010138a:	83 f8 7f             	cmp    $0x7f,%eax
f010138d:	75 19                	jne    f01013a8 <readline+0x78>
f010138f:	85 f6                	test   %esi,%esi
f0101391:	7e 15                	jle    f01013a8 <readline+0x78>
			if (echoing)
f0101393:	85 ff                	test   %edi,%edi
f0101395:	74 0c                	je     f01013a3 <readline+0x73>
				cputchar('\b');
f0101397:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010139e:	e8 be f2 ff ff       	call   f0100661 <cputchar>
			i--;
f01013a3:	83 ee 01             	sub    $0x1,%esi
f01013a6:	eb bb                	jmp    f0101363 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01013a8:	83 fb 1f             	cmp    $0x1f,%ebx
f01013ab:	7e 1f                	jle    f01013cc <readline+0x9c>
f01013ad:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01013b3:	7f 17                	jg     f01013cc <readline+0x9c>
			if (echoing)
f01013b5:	85 ff                	test   %edi,%edi
f01013b7:	74 08                	je     f01013c1 <readline+0x91>
				cputchar(c);
f01013b9:	89 1c 24             	mov    %ebx,(%esp)
f01013bc:	e8 a0 f2 ff ff       	call   f0100661 <cputchar>
			buf[i++] = c;
f01013c1:	88 9e 80 25 11 f0    	mov    %bl,-0xfeeda80(%esi)
f01013c7:	83 c6 01             	add    $0x1,%esi
f01013ca:	eb 97                	jmp    f0101363 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01013cc:	83 fb 0a             	cmp    $0xa,%ebx
f01013cf:	74 05                	je     f01013d6 <readline+0xa6>
f01013d1:	83 fb 0d             	cmp    $0xd,%ebx
f01013d4:	75 8d                	jne    f0101363 <readline+0x33>
			if (echoing)
f01013d6:	85 ff                	test   %edi,%edi
f01013d8:	74 0c                	je     f01013e6 <readline+0xb6>
				cputchar('\n');
f01013da:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01013e1:	e8 7b f2 ff ff       	call   f0100661 <cputchar>
			buf[i] = 0;
f01013e6:	c6 86 80 25 11 f0 00 	movb   $0x0,-0xfeeda80(%esi)
			return buf;
f01013ed:	b8 80 25 11 f0       	mov    $0xf0112580,%eax
		}
	}
}
f01013f2:	83 c4 1c             	add    $0x1c,%esp
f01013f5:	5b                   	pop    %ebx
f01013f6:	5e                   	pop    %esi
f01013f7:	5f                   	pop    %edi
f01013f8:	5d                   	pop    %ebp
f01013f9:	c3                   	ret    
f01013fa:	00 00                	add    %al,(%eax)
f01013fc:	00 00                	add    %al,(%eax)
	...

f0101400 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101400:	55                   	push   %ebp
f0101401:	89 e5                	mov    %esp,%ebp
f0101403:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101406:	b8 00 00 00 00       	mov    $0x0,%eax
f010140b:	80 3a 00             	cmpb   $0x0,(%edx)
f010140e:	74 09                	je     f0101419 <strlen+0x19>
		n++;
f0101410:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101413:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101417:	75 f7                	jne    f0101410 <strlen+0x10>
		n++;
	return n;
}
f0101419:	5d                   	pop    %ebp
f010141a:	c3                   	ret    

f010141b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010141b:	55                   	push   %ebp
f010141c:	89 e5                	mov    %esp,%ebp
f010141e:	53                   	push   %ebx
f010141f:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101422:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101425:	b8 00 00 00 00       	mov    $0x0,%eax
f010142a:	85 c9                	test   %ecx,%ecx
f010142c:	74 1a                	je     f0101448 <strnlen+0x2d>
f010142e:	80 3b 00             	cmpb   $0x0,(%ebx)
f0101431:	74 15                	je     f0101448 <strnlen+0x2d>
f0101433:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f0101438:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010143a:	39 ca                	cmp    %ecx,%edx
f010143c:	74 0a                	je     f0101448 <strnlen+0x2d>
f010143e:	83 c2 01             	add    $0x1,%edx
f0101441:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0101446:	75 f0                	jne    f0101438 <strnlen+0x1d>
		n++;
	return n;
}
f0101448:	5b                   	pop    %ebx
f0101449:	5d                   	pop    %ebp
f010144a:	c3                   	ret    

f010144b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010144b:	55                   	push   %ebp
f010144c:	89 e5                	mov    %esp,%ebp
f010144e:	53                   	push   %ebx
f010144f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101452:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101455:	ba 00 00 00 00       	mov    $0x0,%edx
f010145a:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f010145e:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0101461:	83 c2 01             	add    $0x1,%edx
f0101464:	84 c9                	test   %cl,%cl
f0101466:	75 f2                	jne    f010145a <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0101468:	5b                   	pop    %ebx
f0101469:	5d                   	pop    %ebp
f010146a:	c3                   	ret    

f010146b <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010146b:	55                   	push   %ebp
f010146c:	89 e5                	mov    %esp,%ebp
f010146e:	56                   	push   %esi
f010146f:	53                   	push   %ebx
f0101470:	8b 45 08             	mov    0x8(%ebp),%eax
f0101473:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101476:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101479:	85 f6                	test   %esi,%esi
f010147b:	74 18                	je     f0101495 <strncpy+0x2a>
f010147d:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f0101482:	0f b6 1a             	movzbl (%edx),%ebx
f0101485:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101488:	80 3a 01             	cmpb   $0x1,(%edx)
f010148b:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010148e:	83 c1 01             	add    $0x1,%ecx
f0101491:	39 f1                	cmp    %esi,%ecx
f0101493:	75 ed                	jne    f0101482 <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101495:	5b                   	pop    %ebx
f0101496:	5e                   	pop    %esi
f0101497:	5d                   	pop    %ebp
f0101498:	c3                   	ret    

f0101499 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101499:	55                   	push   %ebp
f010149a:	89 e5                	mov    %esp,%ebp
f010149c:	57                   	push   %edi
f010149d:	56                   	push   %esi
f010149e:	53                   	push   %ebx
f010149f:	8b 7d 08             	mov    0x8(%ebp),%edi
f01014a2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01014a5:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01014a8:	89 f8                	mov    %edi,%eax
f01014aa:	85 f6                	test   %esi,%esi
f01014ac:	74 2b                	je     f01014d9 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f01014ae:	83 fe 01             	cmp    $0x1,%esi
f01014b1:	74 23                	je     f01014d6 <strlcpy+0x3d>
f01014b3:	0f b6 0b             	movzbl (%ebx),%ecx
f01014b6:	84 c9                	test   %cl,%cl
f01014b8:	74 1c                	je     f01014d6 <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f01014ba:	83 ee 02             	sub    $0x2,%esi
f01014bd:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01014c2:	88 08                	mov    %cl,(%eax)
f01014c4:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01014c7:	39 f2                	cmp    %esi,%edx
f01014c9:	74 0b                	je     f01014d6 <strlcpy+0x3d>
f01014cb:	83 c2 01             	add    $0x1,%edx
f01014ce:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01014d2:	84 c9                	test   %cl,%cl
f01014d4:	75 ec                	jne    f01014c2 <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f01014d6:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01014d9:	29 f8                	sub    %edi,%eax
}
f01014db:	5b                   	pop    %ebx
f01014dc:	5e                   	pop    %esi
f01014dd:	5f                   	pop    %edi
f01014de:	5d                   	pop    %ebp
f01014df:	c3                   	ret    

f01014e0 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01014e0:	55                   	push   %ebp
f01014e1:	89 e5                	mov    %esp,%ebp
f01014e3:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01014e6:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01014e9:	0f b6 01             	movzbl (%ecx),%eax
f01014ec:	84 c0                	test   %al,%al
f01014ee:	74 16                	je     f0101506 <strcmp+0x26>
f01014f0:	3a 02                	cmp    (%edx),%al
f01014f2:	75 12                	jne    f0101506 <strcmp+0x26>
		p++, q++;
f01014f4:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01014f7:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f01014fb:	84 c0                	test   %al,%al
f01014fd:	74 07                	je     f0101506 <strcmp+0x26>
f01014ff:	83 c1 01             	add    $0x1,%ecx
f0101502:	3a 02                	cmp    (%edx),%al
f0101504:	74 ee                	je     f01014f4 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101506:	0f b6 c0             	movzbl %al,%eax
f0101509:	0f b6 12             	movzbl (%edx),%edx
f010150c:	29 d0                	sub    %edx,%eax
}
f010150e:	5d                   	pop    %ebp
f010150f:	c3                   	ret    

f0101510 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101510:	55                   	push   %ebp
f0101511:	89 e5                	mov    %esp,%ebp
f0101513:	53                   	push   %ebx
f0101514:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101517:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010151a:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010151d:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101522:	85 d2                	test   %edx,%edx
f0101524:	74 28                	je     f010154e <strncmp+0x3e>
f0101526:	0f b6 01             	movzbl (%ecx),%eax
f0101529:	84 c0                	test   %al,%al
f010152b:	74 24                	je     f0101551 <strncmp+0x41>
f010152d:	3a 03                	cmp    (%ebx),%al
f010152f:	75 20                	jne    f0101551 <strncmp+0x41>
f0101531:	83 ea 01             	sub    $0x1,%edx
f0101534:	74 13                	je     f0101549 <strncmp+0x39>
		n--, p++, q++;
f0101536:	83 c1 01             	add    $0x1,%ecx
f0101539:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010153c:	0f b6 01             	movzbl (%ecx),%eax
f010153f:	84 c0                	test   %al,%al
f0101541:	74 0e                	je     f0101551 <strncmp+0x41>
f0101543:	3a 03                	cmp    (%ebx),%al
f0101545:	74 ea                	je     f0101531 <strncmp+0x21>
f0101547:	eb 08                	jmp    f0101551 <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101549:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010154e:	5b                   	pop    %ebx
f010154f:	5d                   	pop    %ebp
f0101550:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101551:	0f b6 01             	movzbl (%ecx),%eax
f0101554:	0f b6 13             	movzbl (%ebx),%edx
f0101557:	29 d0                	sub    %edx,%eax
f0101559:	eb f3                	jmp    f010154e <strncmp+0x3e>

f010155b <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010155b:	55                   	push   %ebp
f010155c:	89 e5                	mov    %esp,%ebp
f010155e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101561:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101565:	0f b6 10             	movzbl (%eax),%edx
f0101568:	84 d2                	test   %dl,%dl
f010156a:	74 1c                	je     f0101588 <strchr+0x2d>
		if (*s == c)
f010156c:	38 ca                	cmp    %cl,%dl
f010156e:	75 09                	jne    f0101579 <strchr+0x1e>
f0101570:	eb 1b                	jmp    f010158d <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101572:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f0101575:	38 ca                	cmp    %cl,%dl
f0101577:	74 14                	je     f010158d <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101579:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f010157d:	84 d2                	test   %dl,%dl
f010157f:	75 f1                	jne    f0101572 <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f0101581:	b8 00 00 00 00       	mov    $0x0,%eax
f0101586:	eb 05                	jmp    f010158d <strchr+0x32>
f0101588:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010158d:	5d                   	pop    %ebp
f010158e:	c3                   	ret    

f010158f <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010158f:	55                   	push   %ebp
f0101590:	89 e5                	mov    %esp,%ebp
f0101592:	8b 45 08             	mov    0x8(%ebp),%eax
f0101595:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101599:	0f b6 10             	movzbl (%eax),%edx
f010159c:	84 d2                	test   %dl,%dl
f010159e:	74 14                	je     f01015b4 <strfind+0x25>
		if (*s == c)
f01015a0:	38 ca                	cmp    %cl,%dl
f01015a2:	75 06                	jne    f01015aa <strfind+0x1b>
f01015a4:	eb 0e                	jmp    f01015b4 <strfind+0x25>
f01015a6:	38 ca                	cmp    %cl,%dl
f01015a8:	74 0a                	je     f01015b4 <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f01015aa:	83 c0 01             	add    $0x1,%eax
f01015ad:	0f b6 10             	movzbl (%eax),%edx
f01015b0:	84 d2                	test   %dl,%dl
f01015b2:	75 f2                	jne    f01015a6 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f01015b4:	5d                   	pop    %ebp
f01015b5:	c3                   	ret    

f01015b6 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01015b6:	55                   	push   %ebp
f01015b7:	89 e5                	mov    %esp,%ebp
f01015b9:	83 ec 0c             	sub    $0xc,%esp
f01015bc:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f01015bf:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01015c2:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01015c5:	8b 7d 08             	mov    0x8(%ebp),%edi
f01015c8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015cb:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01015ce:	85 c9                	test   %ecx,%ecx
f01015d0:	74 30                	je     f0101602 <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01015d2:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01015d8:	75 25                	jne    f01015ff <memset+0x49>
f01015da:	f6 c1 03             	test   $0x3,%cl
f01015dd:	75 20                	jne    f01015ff <memset+0x49>
		c &= 0xFF;
f01015df:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01015e2:	89 d3                	mov    %edx,%ebx
f01015e4:	c1 e3 08             	shl    $0x8,%ebx
f01015e7:	89 d6                	mov    %edx,%esi
f01015e9:	c1 e6 18             	shl    $0x18,%esi
f01015ec:	89 d0                	mov    %edx,%eax
f01015ee:	c1 e0 10             	shl    $0x10,%eax
f01015f1:	09 f0                	or     %esi,%eax
f01015f3:	09 d0                	or     %edx,%eax
f01015f5:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01015f7:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01015fa:	fc                   	cld    
f01015fb:	f3 ab                	rep stos %eax,%es:(%edi)
f01015fd:	eb 03                	jmp    f0101602 <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01015ff:	fc                   	cld    
f0101600:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101602:	89 f8                	mov    %edi,%eax
f0101604:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0101607:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010160a:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010160d:	89 ec                	mov    %ebp,%esp
f010160f:	5d                   	pop    %ebp
f0101610:	c3                   	ret    

f0101611 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101611:	55                   	push   %ebp
f0101612:	89 e5                	mov    %esp,%ebp
f0101614:	83 ec 08             	sub    $0x8,%esp
f0101617:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010161a:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010161d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101620:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101623:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101626:	39 c6                	cmp    %eax,%esi
f0101628:	73 36                	jae    f0101660 <memmove+0x4f>
f010162a:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010162d:	39 d0                	cmp    %edx,%eax
f010162f:	73 2f                	jae    f0101660 <memmove+0x4f>
		s += n;
		d += n;
f0101631:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101634:	f6 c2 03             	test   $0x3,%dl
f0101637:	75 1b                	jne    f0101654 <memmove+0x43>
f0101639:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010163f:	75 13                	jne    f0101654 <memmove+0x43>
f0101641:	f6 c1 03             	test   $0x3,%cl
f0101644:	75 0e                	jne    f0101654 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101646:	83 ef 04             	sub    $0x4,%edi
f0101649:	8d 72 fc             	lea    -0x4(%edx),%esi
f010164c:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010164f:	fd                   	std    
f0101650:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101652:	eb 09                	jmp    f010165d <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101654:	83 ef 01             	sub    $0x1,%edi
f0101657:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010165a:	fd                   	std    
f010165b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010165d:	fc                   	cld    
f010165e:	eb 20                	jmp    f0101680 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101660:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101666:	75 13                	jne    f010167b <memmove+0x6a>
f0101668:	a8 03                	test   $0x3,%al
f010166a:	75 0f                	jne    f010167b <memmove+0x6a>
f010166c:	f6 c1 03             	test   $0x3,%cl
f010166f:	75 0a                	jne    f010167b <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101671:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0101674:	89 c7                	mov    %eax,%edi
f0101676:	fc                   	cld    
f0101677:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101679:	eb 05                	jmp    f0101680 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010167b:	89 c7                	mov    %eax,%edi
f010167d:	fc                   	cld    
f010167e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101680:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0101683:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101686:	89 ec                	mov    %ebp,%esp
f0101688:	5d                   	pop    %ebp
f0101689:	c3                   	ret    

f010168a <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f010168a:	55                   	push   %ebp
f010168b:	89 e5                	mov    %esp,%ebp
f010168d:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101690:	8b 45 10             	mov    0x10(%ebp),%eax
f0101693:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101697:	8b 45 0c             	mov    0xc(%ebp),%eax
f010169a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010169e:	8b 45 08             	mov    0x8(%ebp),%eax
f01016a1:	89 04 24             	mov    %eax,(%esp)
f01016a4:	e8 68 ff ff ff       	call   f0101611 <memmove>
}
f01016a9:	c9                   	leave  
f01016aa:	c3                   	ret    

f01016ab <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01016ab:	55                   	push   %ebp
f01016ac:	89 e5                	mov    %esp,%ebp
f01016ae:	57                   	push   %edi
f01016af:	56                   	push   %esi
f01016b0:	53                   	push   %ebx
f01016b1:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01016b4:	8b 75 0c             	mov    0xc(%ebp),%esi
f01016b7:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01016ba:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01016bf:	85 ff                	test   %edi,%edi
f01016c1:	74 37                	je     f01016fa <memcmp+0x4f>
		if (*s1 != *s2)
f01016c3:	0f b6 03             	movzbl (%ebx),%eax
f01016c6:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01016c9:	83 ef 01             	sub    $0x1,%edi
f01016cc:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f01016d1:	38 c8                	cmp    %cl,%al
f01016d3:	74 1c                	je     f01016f1 <memcmp+0x46>
f01016d5:	eb 10                	jmp    f01016e7 <memcmp+0x3c>
f01016d7:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f01016dc:	83 c2 01             	add    $0x1,%edx
f01016df:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f01016e3:	38 c8                	cmp    %cl,%al
f01016e5:	74 0a                	je     f01016f1 <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f01016e7:	0f b6 c0             	movzbl %al,%eax
f01016ea:	0f b6 c9             	movzbl %cl,%ecx
f01016ed:	29 c8                	sub    %ecx,%eax
f01016ef:	eb 09                	jmp    f01016fa <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01016f1:	39 fa                	cmp    %edi,%edx
f01016f3:	75 e2                	jne    f01016d7 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01016f5:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01016fa:	5b                   	pop    %ebx
f01016fb:	5e                   	pop    %esi
f01016fc:	5f                   	pop    %edi
f01016fd:	5d                   	pop    %ebp
f01016fe:	c3                   	ret    

f01016ff <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01016ff:	55                   	push   %ebp
f0101700:	89 e5                	mov    %esp,%ebp
f0101702:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0101705:	89 c2                	mov    %eax,%edx
f0101707:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f010170a:	39 d0                	cmp    %edx,%eax
f010170c:	73 15                	jae    f0101723 <memfind+0x24>
		if (*(const unsigned char *) s == (unsigned char) c)
f010170e:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f0101712:	38 08                	cmp    %cl,(%eax)
f0101714:	75 06                	jne    f010171c <memfind+0x1d>
f0101716:	eb 0b                	jmp    f0101723 <memfind+0x24>
f0101718:	38 08                	cmp    %cl,(%eax)
f010171a:	74 07                	je     f0101723 <memfind+0x24>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010171c:	83 c0 01             	add    $0x1,%eax
f010171f:	39 d0                	cmp    %edx,%eax
f0101721:	75 f5                	jne    f0101718 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101723:	5d                   	pop    %ebp
f0101724:	c3                   	ret    

f0101725 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101725:	55                   	push   %ebp
f0101726:	89 e5                	mov    %esp,%ebp
f0101728:	57                   	push   %edi
f0101729:	56                   	push   %esi
f010172a:	53                   	push   %ebx
f010172b:	8b 55 08             	mov    0x8(%ebp),%edx
f010172e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101731:	0f b6 02             	movzbl (%edx),%eax
f0101734:	3c 20                	cmp    $0x20,%al
f0101736:	74 04                	je     f010173c <strtol+0x17>
f0101738:	3c 09                	cmp    $0x9,%al
f010173a:	75 0e                	jne    f010174a <strtol+0x25>
		s++;
f010173c:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010173f:	0f b6 02             	movzbl (%edx),%eax
f0101742:	3c 20                	cmp    $0x20,%al
f0101744:	74 f6                	je     f010173c <strtol+0x17>
f0101746:	3c 09                	cmp    $0x9,%al
f0101748:	74 f2                	je     f010173c <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f010174a:	3c 2b                	cmp    $0x2b,%al
f010174c:	75 0a                	jne    f0101758 <strtol+0x33>
		s++;
f010174e:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101751:	bf 00 00 00 00       	mov    $0x0,%edi
f0101756:	eb 10                	jmp    f0101768 <strtol+0x43>
f0101758:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010175d:	3c 2d                	cmp    $0x2d,%al
f010175f:	75 07                	jne    f0101768 <strtol+0x43>
		s++, neg = 1;
f0101761:	83 c2 01             	add    $0x1,%edx
f0101764:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101768:	85 db                	test   %ebx,%ebx
f010176a:	0f 94 c0             	sete   %al
f010176d:	74 05                	je     f0101774 <strtol+0x4f>
f010176f:	83 fb 10             	cmp    $0x10,%ebx
f0101772:	75 15                	jne    f0101789 <strtol+0x64>
f0101774:	80 3a 30             	cmpb   $0x30,(%edx)
f0101777:	75 10                	jne    f0101789 <strtol+0x64>
f0101779:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f010177d:	75 0a                	jne    f0101789 <strtol+0x64>
		s += 2, base = 16;
f010177f:	83 c2 02             	add    $0x2,%edx
f0101782:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101787:	eb 13                	jmp    f010179c <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f0101789:	84 c0                	test   %al,%al
f010178b:	74 0f                	je     f010179c <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010178d:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101792:	80 3a 30             	cmpb   $0x30,(%edx)
f0101795:	75 05                	jne    f010179c <strtol+0x77>
		s++, base = 8;
f0101797:	83 c2 01             	add    $0x1,%edx
f010179a:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f010179c:	b8 00 00 00 00       	mov    $0x0,%eax
f01017a1:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01017a3:	0f b6 0a             	movzbl (%edx),%ecx
f01017a6:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f01017a9:	80 fb 09             	cmp    $0x9,%bl
f01017ac:	77 08                	ja     f01017b6 <strtol+0x91>
			dig = *s - '0';
f01017ae:	0f be c9             	movsbl %cl,%ecx
f01017b1:	83 e9 30             	sub    $0x30,%ecx
f01017b4:	eb 1e                	jmp    f01017d4 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f01017b6:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f01017b9:	80 fb 19             	cmp    $0x19,%bl
f01017bc:	77 08                	ja     f01017c6 <strtol+0xa1>
			dig = *s - 'a' + 10;
f01017be:	0f be c9             	movsbl %cl,%ecx
f01017c1:	83 e9 57             	sub    $0x57,%ecx
f01017c4:	eb 0e                	jmp    f01017d4 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f01017c6:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f01017c9:	80 fb 19             	cmp    $0x19,%bl
f01017cc:	77 14                	ja     f01017e2 <strtol+0xbd>
			dig = *s - 'A' + 10;
f01017ce:	0f be c9             	movsbl %cl,%ecx
f01017d1:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01017d4:	39 f1                	cmp    %esi,%ecx
f01017d6:	7d 0e                	jge    f01017e6 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f01017d8:	83 c2 01             	add    $0x1,%edx
f01017db:	0f af c6             	imul   %esi,%eax
f01017de:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f01017e0:	eb c1                	jmp    f01017a3 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f01017e2:	89 c1                	mov    %eax,%ecx
f01017e4:	eb 02                	jmp    f01017e8 <strtol+0xc3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f01017e6:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f01017e8:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01017ec:	74 05                	je     f01017f3 <strtol+0xce>
		*endptr = (char *) s;
f01017ee:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01017f1:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f01017f3:	89 ca                	mov    %ecx,%edx
f01017f5:	f7 da                	neg    %edx
f01017f7:	85 ff                	test   %edi,%edi
f01017f9:	0f 45 c2             	cmovne %edx,%eax
}
f01017fc:	5b                   	pop    %ebx
f01017fd:	5e                   	pop    %esi
f01017fe:	5f                   	pop    %edi
f01017ff:	5d                   	pop    %ebp
f0101800:	c3                   	ret    
	...

f0101810 <__udivdi3>:
f0101810:	83 ec 1c             	sub    $0x1c,%esp
f0101813:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0101817:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f010181b:	8b 44 24 20          	mov    0x20(%esp),%eax
f010181f:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101823:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101827:	8b 74 24 24          	mov    0x24(%esp),%esi
f010182b:	85 ff                	test   %edi,%edi
f010182d:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101831:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101835:	89 cd                	mov    %ecx,%ebp
f0101837:	89 44 24 04          	mov    %eax,0x4(%esp)
f010183b:	75 33                	jne    f0101870 <__udivdi3+0x60>
f010183d:	39 f1                	cmp    %esi,%ecx
f010183f:	77 57                	ja     f0101898 <__udivdi3+0x88>
f0101841:	85 c9                	test   %ecx,%ecx
f0101843:	75 0b                	jne    f0101850 <__udivdi3+0x40>
f0101845:	b8 01 00 00 00       	mov    $0x1,%eax
f010184a:	31 d2                	xor    %edx,%edx
f010184c:	f7 f1                	div    %ecx
f010184e:	89 c1                	mov    %eax,%ecx
f0101850:	89 f0                	mov    %esi,%eax
f0101852:	31 d2                	xor    %edx,%edx
f0101854:	f7 f1                	div    %ecx
f0101856:	89 c6                	mov    %eax,%esi
f0101858:	8b 44 24 04          	mov    0x4(%esp),%eax
f010185c:	f7 f1                	div    %ecx
f010185e:	89 f2                	mov    %esi,%edx
f0101860:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101864:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101868:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010186c:	83 c4 1c             	add    $0x1c,%esp
f010186f:	c3                   	ret    
f0101870:	31 d2                	xor    %edx,%edx
f0101872:	31 c0                	xor    %eax,%eax
f0101874:	39 f7                	cmp    %esi,%edi
f0101876:	77 e8                	ja     f0101860 <__udivdi3+0x50>
f0101878:	0f bd cf             	bsr    %edi,%ecx
f010187b:	83 f1 1f             	xor    $0x1f,%ecx
f010187e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101882:	75 2c                	jne    f01018b0 <__udivdi3+0xa0>
f0101884:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0101888:	76 04                	jbe    f010188e <__udivdi3+0x7e>
f010188a:	39 f7                	cmp    %esi,%edi
f010188c:	73 d2                	jae    f0101860 <__udivdi3+0x50>
f010188e:	31 d2                	xor    %edx,%edx
f0101890:	b8 01 00 00 00       	mov    $0x1,%eax
f0101895:	eb c9                	jmp    f0101860 <__udivdi3+0x50>
f0101897:	90                   	nop
f0101898:	89 f2                	mov    %esi,%edx
f010189a:	f7 f1                	div    %ecx
f010189c:	31 d2                	xor    %edx,%edx
f010189e:	8b 74 24 10          	mov    0x10(%esp),%esi
f01018a2:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01018a6:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01018aa:	83 c4 1c             	add    $0x1c,%esp
f01018ad:	c3                   	ret    
f01018ae:	66 90                	xchg   %ax,%ax
f01018b0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01018b5:	b8 20 00 00 00       	mov    $0x20,%eax
f01018ba:	89 ea                	mov    %ebp,%edx
f01018bc:	2b 44 24 04          	sub    0x4(%esp),%eax
f01018c0:	d3 e7                	shl    %cl,%edi
f01018c2:	89 c1                	mov    %eax,%ecx
f01018c4:	d3 ea                	shr    %cl,%edx
f01018c6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01018cb:	09 fa                	or     %edi,%edx
f01018cd:	89 f7                	mov    %esi,%edi
f01018cf:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01018d3:	89 f2                	mov    %esi,%edx
f01018d5:	8b 74 24 08          	mov    0x8(%esp),%esi
f01018d9:	d3 e5                	shl    %cl,%ebp
f01018db:	89 c1                	mov    %eax,%ecx
f01018dd:	d3 ef                	shr    %cl,%edi
f01018df:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01018e4:	d3 e2                	shl    %cl,%edx
f01018e6:	89 c1                	mov    %eax,%ecx
f01018e8:	d3 ee                	shr    %cl,%esi
f01018ea:	09 d6                	or     %edx,%esi
f01018ec:	89 fa                	mov    %edi,%edx
f01018ee:	89 f0                	mov    %esi,%eax
f01018f0:	f7 74 24 0c          	divl   0xc(%esp)
f01018f4:	89 d7                	mov    %edx,%edi
f01018f6:	89 c6                	mov    %eax,%esi
f01018f8:	f7 e5                	mul    %ebp
f01018fa:	39 d7                	cmp    %edx,%edi
f01018fc:	72 22                	jb     f0101920 <__udivdi3+0x110>
f01018fe:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0101902:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101907:	d3 e5                	shl    %cl,%ebp
f0101909:	39 c5                	cmp    %eax,%ebp
f010190b:	73 04                	jae    f0101911 <__udivdi3+0x101>
f010190d:	39 d7                	cmp    %edx,%edi
f010190f:	74 0f                	je     f0101920 <__udivdi3+0x110>
f0101911:	89 f0                	mov    %esi,%eax
f0101913:	31 d2                	xor    %edx,%edx
f0101915:	e9 46 ff ff ff       	jmp    f0101860 <__udivdi3+0x50>
f010191a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101920:	8d 46 ff             	lea    -0x1(%esi),%eax
f0101923:	31 d2                	xor    %edx,%edx
f0101925:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101929:	8b 7c 24 14          	mov    0x14(%esp),%edi
f010192d:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101931:	83 c4 1c             	add    $0x1c,%esp
f0101934:	c3                   	ret    
	...

f0101940 <__umoddi3>:
f0101940:	83 ec 1c             	sub    $0x1c,%esp
f0101943:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101947:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f010194b:	8b 44 24 20          	mov    0x20(%esp),%eax
f010194f:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101953:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101957:	8b 74 24 24          	mov    0x24(%esp),%esi
f010195b:	85 ed                	test   %ebp,%ebp
f010195d:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0101961:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101965:	89 cf                	mov    %ecx,%edi
f0101967:	89 04 24             	mov    %eax,(%esp)
f010196a:	89 f2                	mov    %esi,%edx
f010196c:	75 1a                	jne    f0101988 <__umoddi3+0x48>
f010196e:	39 f1                	cmp    %esi,%ecx
f0101970:	76 4e                	jbe    f01019c0 <__umoddi3+0x80>
f0101972:	f7 f1                	div    %ecx
f0101974:	89 d0                	mov    %edx,%eax
f0101976:	31 d2                	xor    %edx,%edx
f0101978:	8b 74 24 10          	mov    0x10(%esp),%esi
f010197c:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101980:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101984:	83 c4 1c             	add    $0x1c,%esp
f0101987:	c3                   	ret    
f0101988:	39 f5                	cmp    %esi,%ebp
f010198a:	77 54                	ja     f01019e0 <__umoddi3+0xa0>
f010198c:	0f bd c5             	bsr    %ebp,%eax
f010198f:	83 f0 1f             	xor    $0x1f,%eax
f0101992:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101996:	75 60                	jne    f01019f8 <__umoddi3+0xb8>
f0101998:	3b 0c 24             	cmp    (%esp),%ecx
f010199b:	0f 87 07 01 00 00    	ja     f0101aa8 <__umoddi3+0x168>
f01019a1:	89 f2                	mov    %esi,%edx
f01019a3:	8b 34 24             	mov    (%esp),%esi
f01019a6:	29 ce                	sub    %ecx,%esi
f01019a8:	19 ea                	sbb    %ebp,%edx
f01019aa:	89 34 24             	mov    %esi,(%esp)
f01019ad:	8b 04 24             	mov    (%esp),%eax
f01019b0:	8b 74 24 10          	mov    0x10(%esp),%esi
f01019b4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01019b8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01019bc:	83 c4 1c             	add    $0x1c,%esp
f01019bf:	c3                   	ret    
f01019c0:	85 c9                	test   %ecx,%ecx
f01019c2:	75 0b                	jne    f01019cf <__umoddi3+0x8f>
f01019c4:	b8 01 00 00 00       	mov    $0x1,%eax
f01019c9:	31 d2                	xor    %edx,%edx
f01019cb:	f7 f1                	div    %ecx
f01019cd:	89 c1                	mov    %eax,%ecx
f01019cf:	89 f0                	mov    %esi,%eax
f01019d1:	31 d2                	xor    %edx,%edx
f01019d3:	f7 f1                	div    %ecx
f01019d5:	8b 04 24             	mov    (%esp),%eax
f01019d8:	f7 f1                	div    %ecx
f01019da:	eb 98                	jmp    f0101974 <__umoddi3+0x34>
f01019dc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019e0:	89 f2                	mov    %esi,%edx
f01019e2:	8b 74 24 10          	mov    0x10(%esp),%esi
f01019e6:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01019ea:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01019ee:	83 c4 1c             	add    $0x1c,%esp
f01019f1:	c3                   	ret    
f01019f2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01019f8:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01019fd:	89 e8                	mov    %ebp,%eax
f01019ff:	bd 20 00 00 00       	mov    $0x20,%ebp
f0101a04:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0101a08:	89 fa                	mov    %edi,%edx
f0101a0a:	d3 e0                	shl    %cl,%eax
f0101a0c:	89 e9                	mov    %ebp,%ecx
f0101a0e:	d3 ea                	shr    %cl,%edx
f0101a10:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101a15:	09 c2                	or     %eax,%edx
f0101a17:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101a1b:	89 14 24             	mov    %edx,(%esp)
f0101a1e:	89 f2                	mov    %esi,%edx
f0101a20:	d3 e7                	shl    %cl,%edi
f0101a22:	89 e9                	mov    %ebp,%ecx
f0101a24:	d3 ea                	shr    %cl,%edx
f0101a26:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101a2b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101a2f:	d3 e6                	shl    %cl,%esi
f0101a31:	89 e9                	mov    %ebp,%ecx
f0101a33:	d3 e8                	shr    %cl,%eax
f0101a35:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101a3a:	09 f0                	or     %esi,%eax
f0101a3c:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101a40:	f7 34 24             	divl   (%esp)
f0101a43:	d3 e6                	shl    %cl,%esi
f0101a45:	89 74 24 08          	mov    %esi,0x8(%esp)
f0101a49:	89 d6                	mov    %edx,%esi
f0101a4b:	f7 e7                	mul    %edi
f0101a4d:	39 d6                	cmp    %edx,%esi
f0101a4f:	89 c1                	mov    %eax,%ecx
f0101a51:	89 d7                	mov    %edx,%edi
f0101a53:	72 3f                	jb     f0101a94 <__umoddi3+0x154>
f0101a55:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0101a59:	72 35                	jb     f0101a90 <__umoddi3+0x150>
f0101a5b:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101a5f:	29 c8                	sub    %ecx,%eax
f0101a61:	19 fe                	sbb    %edi,%esi
f0101a63:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101a68:	89 f2                	mov    %esi,%edx
f0101a6a:	d3 e8                	shr    %cl,%eax
f0101a6c:	89 e9                	mov    %ebp,%ecx
f0101a6e:	d3 e2                	shl    %cl,%edx
f0101a70:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101a75:	09 d0                	or     %edx,%eax
f0101a77:	89 f2                	mov    %esi,%edx
f0101a79:	d3 ea                	shr    %cl,%edx
f0101a7b:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101a7f:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101a83:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101a87:	83 c4 1c             	add    $0x1c,%esp
f0101a8a:	c3                   	ret    
f0101a8b:	90                   	nop
f0101a8c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a90:	39 d6                	cmp    %edx,%esi
f0101a92:	75 c7                	jne    f0101a5b <__umoddi3+0x11b>
f0101a94:	89 d7                	mov    %edx,%edi
f0101a96:	89 c1                	mov    %eax,%ecx
f0101a98:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f0101a9c:	1b 3c 24             	sbb    (%esp),%edi
f0101a9f:	eb ba                	jmp    f0101a5b <__umoddi3+0x11b>
f0101aa1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101aa8:	39 f5                	cmp    %esi,%ebp
f0101aaa:	0f 82 f1 fe ff ff    	jb     f01019a1 <__umoddi3+0x61>
f0101ab0:	e9 f8 fe ff ff       	jmp    f01019ad <__umoddi3+0x6d>
