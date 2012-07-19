
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
f0100015:	b8 00 a0 11 00       	mov    $0x11a000,%eax
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
f0100034:	bc 00 a0 11 f0       	mov    $0xf011a000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/trap.h>


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
f0100046:	b8 d0 fe 17 f0       	mov    $0xf017fed0,%eax
f010004b:	2d ca ef 17 f0       	sub    $0xf017efca,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 ca ef 17 f0 	movl   $0xf017efca,(%esp)
f0100063:	e8 39 48 00 00       	call   f01048a1 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 be 04 00 00       	call   f010052b <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 a0 4d 10 f0 	movl   $0xf0104da0,(%esp)
f010007c:	e8 39 37 00 00       	call   f01037ba <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 0a 17 00 00       	call   f0101790 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100086:	e8 21 33 00 00       	call   f01033ac <env_init>
	trap_init();
f010008b:	90                   	nop
f010008c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100090:	e8 9c 37 00 00       	call   f0103831 <trap_init>
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
f0100095:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010009c:	00 
f010009d:	c7 44 24 04 4d 78 00 	movl   $0x784d,0x4(%esp)
f01000a4:	00 
f01000a5:	c7 04 24 5c c3 11 f0 	movl   $0xf011c35c,(%esp)
f01000ac:	e8 32 34 00 00       	call   f01034e3 <env_create>
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f01000b1:	a1 28 f2 17 f0       	mov    0xf017f228,%eax
f01000b6:	89 04 24             	mov    %eax,(%esp)
f01000b9:	e8 69 36 00 00       	call   f0103727 <env_run>

f01000be <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000be:	55                   	push   %ebp
f01000bf:	89 e5                	mov    %esp,%ebp
f01000c1:	56                   	push   %esi
f01000c2:	53                   	push   %ebx
f01000c3:	83 ec 10             	sub    $0x10,%esp
f01000c6:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000c9:	83 3d c0 fe 17 f0 00 	cmpl   $0x0,0xf017fec0
f01000d0:	75 3d                	jne    f010010f <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000d2:	89 35 c0 fe 17 f0    	mov    %esi,0xf017fec0

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000d8:	fa                   	cli    
f01000d9:	fc                   	cld    

	va_start(ap, fmt);
f01000da:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000dd:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000e0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000e4:	8b 45 08             	mov    0x8(%ebp),%eax
f01000e7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000eb:	c7 04 24 bb 4d 10 f0 	movl   $0xf0104dbb,(%esp)
f01000f2:	e8 c3 36 00 00       	call   f01037ba <cprintf>
	vcprintf(fmt, ap);
f01000f7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000fb:	89 34 24             	mov    %esi,(%esp)
f01000fe:	e8 84 36 00 00       	call   f0103787 <vcprintf>
	cprintf("\n");
f0100103:	c7 04 24 31 60 10 f0 	movl   $0xf0106031,(%esp)
f010010a:	e8 ab 36 00 00       	call   f01037ba <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010010f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100116:	e8 8e 0c 00 00       	call   f0100da9 <monitor>
f010011b:	eb f2                	jmp    f010010f <_panic+0x51>

f010011d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010011d:	55                   	push   %ebp
f010011e:	89 e5                	mov    %esp,%ebp
f0100120:	53                   	push   %ebx
f0100121:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f0100124:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100127:	8b 45 0c             	mov    0xc(%ebp),%eax
f010012a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010012e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100131:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100135:	c7 04 24 d3 4d 10 f0 	movl   $0xf0104dd3,(%esp)
f010013c:	e8 79 36 00 00       	call   f01037ba <cprintf>
	vcprintf(fmt, ap);
f0100141:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100145:	8b 45 10             	mov    0x10(%ebp),%eax
f0100148:	89 04 24             	mov    %eax,(%esp)
f010014b:	e8 37 36 00 00       	call   f0103787 <vcprintf>
	cprintf("\n");
f0100150:	c7 04 24 31 60 10 f0 	movl   $0xf0106031,(%esp)
f0100157:	e8 5e 36 00 00       	call   f01037ba <cprintf>
	va_end(ap);
}
f010015c:	83 c4 14             	add    $0x14,%esp
f010015f:	5b                   	pop    %ebx
f0100160:	5d                   	pop    %ebp
f0100161:	c3                   	ret    
	...

f0100170 <delay>:
extern int char_color;

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100170:	55                   	push   %ebp
f0100171:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100173:	ba 84 00 00 00       	mov    $0x84,%edx
f0100178:	ec                   	in     (%dx),%al
f0100179:	ec                   	in     (%dx),%al
f010017a:	ec                   	in     (%dx),%al
f010017b:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f010017c:	5d                   	pop    %ebp
f010017d:	c3                   	ret    

f010017e <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010017e:	55                   	push   %ebp
f010017f:	89 e5                	mov    %esp,%ebp
f0100181:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100186:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100187:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
static bool serial_exists;

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010018c:	a8 01                	test   $0x1,%al
f010018e:	74 06                	je     f0100196 <serial_proc_data+0x18>
f0100190:	b2 f8                	mov    $0xf8,%dl
f0100192:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100193:	0f b6 c8             	movzbl %al,%ecx
}
f0100196:	89 c8                	mov    %ecx,%eax
f0100198:	5d                   	pop    %ebp
f0100199:	c3                   	ret    

f010019a <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010019a:	55                   	push   %ebp
f010019b:	89 e5                	mov    %esp,%ebp
f010019d:	53                   	push   %ebx
f010019e:	83 ec 04             	sub    $0x4,%esp
f01001a1:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001a3:	eb 25                	jmp    f01001ca <cons_intr+0x30>
		if (c == 0)
f01001a5:	85 c0                	test   %eax,%eax
f01001a7:	74 21                	je     f01001ca <cons_intr+0x30>
			continue;
		cons.buf[cons.wpos++] = c;
f01001a9:	8b 15 04 f2 17 f0    	mov    0xf017f204,%edx
f01001af:	88 82 00 f0 17 f0    	mov    %al,-0xfe81000(%edx)
f01001b5:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f01001b8:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f01001bd:	ba 00 00 00 00       	mov    $0x0,%edx
f01001c2:	0f 44 c2             	cmove  %edx,%eax
f01001c5:	a3 04 f2 17 f0       	mov    %eax,0xf017f204
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001ca:	ff d3                	call   *%ebx
f01001cc:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001cf:	75 d4                	jne    f01001a5 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001d1:	83 c4 04             	add    $0x4,%esp
f01001d4:	5b                   	pop    %ebx
f01001d5:	5d                   	pop    %ebp
f01001d6:	c3                   	ret    

f01001d7 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01001d7:	55                   	push   %ebp
f01001d8:	89 e5                	mov    %esp,%ebp
f01001da:	57                   	push   %edi
f01001db:	56                   	push   %esi
f01001dc:	53                   	push   %ebx
f01001dd:	83 ec 2c             	sub    $0x2c,%esp
f01001e0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01001e3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001e8:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01001e9:	a8 20                	test   $0x20,%al
f01001eb:	75 1b                	jne    f0100208 <cons_putc+0x31>
f01001ed:	bb 00 32 00 00       	mov    $0x3200,%ebx
f01001f2:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f01001f7:	e8 74 ff ff ff       	call   f0100170 <delay>
f01001fc:	89 f2                	mov    %esi,%edx
f01001fe:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01001ff:	a8 20                	test   $0x20,%al
f0100201:	75 05                	jne    f0100208 <cons_putc+0x31>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100203:	83 eb 01             	sub    $0x1,%ebx
f0100206:	75 ef                	jne    f01001f7 <cons_putc+0x20>
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
f0100208:	0f b6 7d e4          	movzbl -0x1c(%ebp),%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010020c:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100211:	89 f8                	mov    %edi,%eax
f0100213:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100214:	b2 79                	mov    $0x79,%dl
f0100216:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100217:	84 c0                	test   %al,%al
f0100219:	78 1b                	js     f0100236 <cons_putc+0x5f>
f010021b:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100220:	be 79 03 00 00       	mov    $0x379,%esi
		delay();
f0100225:	e8 46 ff ff ff       	call   f0100170 <delay>
f010022a:	89 f2                	mov    %esi,%edx
f010022c:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010022d:	84 c0                	test   %al,%al
f010022f:	78 05                	js     f0100236 <cons_putc+0x5f>
f0100231:	83 eb 01             	sub    $0x1,%ebx
f0100234:	75 ef                	jne    f0100225 <cons_putc+0x4e>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100236:	ba 78 03 00 00       	mov    $0x378,%edx
f010023b:	89 f8                	mov    %edi,%eax
f010023d:	ee                   	out    %al,(%dx)
f010023e:	b2 7a                	mov    $0x7a,%dl
f0100240:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100245:	ee                   	out    %al,(%dx)
f0100246:	b8 08 00 00 00       	mov    $0x8,%eax
f010024b:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	c = c | (char_color<<8);
f010024c:	a1 58 c3 11 f0       	mov    0xf011c358,%eax
f0100251:	c1 e0 08             	shl    $0x8,%eax
f0100254:	0b 45 e4             	or     -0x1c(%ebp),%eax
	
	if (!(c & ~0xFF)){
f0100257:	89 c1                	mov    %eax,%ecx
f0100259:	81 e1 00 ff ff ff    	and    $0xffffff00,%ecx
		c |= 0x0700;
f010025f:	89 c2                	mov    %eax,%edx
f0100261:	80 ce 07             	or     $0x7,%dh
f0100264:	85 c9                	test   %ecx,%ecx
f0100266:	0f 44 c2             	cmove  %edx,%eax
		}

	switch (c & 0xff) {
f0100269:	0f b6 d0             	movzbl %al,%edx
f010026c:	83 fa 09             	cmp    $0x9,%edx
f010026f:	74 75                	je     f01002e6 <cons_putc+0x10f>
f0100271:	83 fa 09             	cmp    $0x9,%edx
f0100274:	7f 0c                	jg     f0100282 <cons_putc+0xab>
f0100276:	83 fa 08             	cmp    $0x8,%edx
f0100279:	0f 85 9b 00 00 00    	jne    f010031a <cons_putc+0x143>
f010027f:	90                   	nop
f0100280:	eb 10                	jmp    f0100292 <cons_putc+0xbb>
f0100282:	83 fa 0a             	cmp    $0xa,%edx
f0100285:	74 39                	je     f01002c0 <cons_putc+0xe9>
f0100287:	83 fa 0d             	cmp    $0xd,%edx
f010028a:	0f 85 8a 00 00 00    	jne    f010031a <cons_putc+0x143>
f0100290:	eb 36                	jmp    f01002c8 <cons_putc+0xf1>
	case '\b':
		if (crt_pos > 0) {
f0100292:	0f b7 15 14 f2 17 f0 	movzwl 0xf017f214,%edx
f0100299:	66 85 d2             	test   %dx,%dx
f010029c:	0f 84 e3 00 00 00    	je     f0100385 <cons_putc+0x1ae>
			crt_pos--;
f01002a2:	83 ea 01             	sub    $0x1,%edx
f01002a5:	66 89 15 14 f2 17 f0 	mov    %dx,0xf017f214
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01002ac:	0f b7 d2             	movzwl %dx,%edx
f01002af:	b0 00                	mov    $0x0,%al
f01002b1:	83 c8 20             	or     $0x20,%eax
f01002b4:	8b 0d 10 f2 17 f0    	mov    0xf017f210,%ecx
f01002ba:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f01002be:	eb 78                	jmp    f0100338 <cons_putc+0x161>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01002c0:	66 83 05 14 f2 17 f0 	addw   $0x50,0xf017f214
f01002c7:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01002c8:	0f b7 05 14 f2 17 f0 	movzwl 0xf017f214,%eax
f01002cf:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01002d5:	c1 e8 16             	shr    $0x16,%eax
f01002d8:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01002db:	c1 e0 04             	shl    $0x4,%eax
f01002de:	66 a3 14 f2 17 f0    	mov    %ax,0xf017f214
f01002e4:	eb 52                	jmp    f0100338 <cons_putc+0x161>
		break;
	case '\t':
		cons_putc(' ');
f01002e6:	b8 20 00 00 00       	mov    $0x20,%eax
f01002eb:	e8 e7 fe ff ff       	call   f01001d7 <cons_putc>
		cons_putc(' ');
f01002f0:	b8 20 00 00 00       	mov    $0x20,%eax
f01002f5:	e8 dd fe ff ff       	call   f01001d7 <cons_putc>
		cons_putc(' ');
f01002fa:	b8 20 00 00 00       	mov    $0x20,%eax
f01002ff:	e8 d3 fe ff ff       	call   f01001d7 <cons_putc>
		cons_putc(' ');
f0100304:	b8 20 00 00 00       	mov    $0x20,%eax
f0100309:	e8 c9 fe ff ff       	call   f01001d7 <cons_putc>
		cons_putc(' ');
f010030e:	b8 20 00 00 00       	mov    $0x20,%eax
f0100313:	e8 bf fe ff ff       	call   f01001d7 <cons_putc>
f0100318:	eb 1e                	jmp    f0100338 <cons_putc+0x161>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010031a:	0f b7 15 14 f2 17 f0 	movzwl 0xf017f214,%edx
f0100321:	0f b7 da             	movzwl %dx,%ebx
f0100324:	8b 0d 10 f2 17 f0    	mov    0xf017f210,%ecx
f010032a:	66 89 04 59          	mov    %ax,(%ecx,%ebx,2)
f010032e:	83 c2 01             	add    $0x1,%edx
f0100331:	66 89 15 14 f2 17 f0 	mov    %dx,0xf017f214
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100338:	66 81 3d 14 f2 17 f0 	cmpw   $0x7cf,0xf017f214
f010033f:	cf 07 
f0100341:	76 42                	jbe    f0100385 <cons_putc+0x1ae>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100343:	a1 10 f2 17 f0       	mov    0xf017f210,%eax
f0100348:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010034f:	00 
f0100350:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100356:	89 54 24 04          	mov    %edx,0x4(%esp)
f010035a:	89 04 24             	mov    %eax,(%esp)
f010035d:	e8 9a 45 00 00       	call   f01048fc <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100362:	8b 15 10 f2 17 f0    	mov    0xf017f210,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100368:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f010036d:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100373:	83 c0 01             	add    $0x1,%eax
f0100376:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f010037b:	75 f0                	jne    f010036d <cons_putc+0x196>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010037d:	66 83 2d 14 f2 17 f0 	subw   $0x50,0xf017f214
f0100384:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100385:	8b 0d 0c f2 17 f0    	mov    0xf017f20c,%ecx
f010038b:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100390:	89 ca                	mov    %ecx,%edx
f0100392:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100393:	0f b7 35 14 f2 17 f0 	movzwl 0xf017f214,%esi
f010039a:	8d 59 01             	lea    0x1(%ecx),%ebx
f010039d:	89 f0                	mov    %esi,%eax
f010039f:	66 c1 e8 08          	shr    $0x8,%ax
f01003a3:	89 da                	mov    %ebx,%edx
f01003a5:	ee                   	out    %al,(%dx)
f01003a6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01003ab:	89 ca                	mov    %ecx,%edx
f01003ad:	ee                   	out    %al,(%dx)
f01003ae:	89 f0                	mov    %esi,%eax
f01003b0:	89 da                	mov    %ebx,%edx
f01003b2:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01003b3:	83 c4 2c             	add    $0x2c,%esp
f01003b6:	5b                   	pop    %ebx
f01003b7:	5e                   	pop    %esi
f01003b8:	5f                   	pop    %edi
f01003b9:	5d                   	pop    %ebp
f01003ba:	c3                   	ret    

f01003bb <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01003bb:	55                   	push   %ebp
f01003bc:	89 e5                	mov    %esp,%ebp
f01003be:	53                   	push   %ebx
f01003bf:	83 ec 14             	sub    $0x14,%esp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003c2:	ba 64 00 00 00       	mov    $0x64,%edx
f01003c7:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01003c8:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01003cd:	a8 01                	test   $0x1,%al
f01003cf:	0f 84 de 00 00 00    	je     f01004b3 <kbd_proc_data+0xf8>
f01003d5:	b2 60                	mov    $0x60,%dl
f01003d7:	ec                   	in     (%dx),%al
f01003d8:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01003da:	3c e0                	cmp    $0xe0,%al
f01003dc:	75 11                	jne    f01003ef <kbd_proc_data+0x34>
		// E0 escape character
		shift |= E0ESC;
f01003de:	83 0d 08 f2 17 f0 40 	orl    $0x40,0xf017f208
		return 0;
f01003e5:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003ea:	e9 c4 00 00 00       	jmp    f01004b3 <kbd_proc_data+0xf8>
	} else if (data & 0x80) {
f01003ef:	84 c0                	test   %al,%al
f01003f1:	79 37                	jns    f010042a <kbd_proc_data+0x6f>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003f3:	8b 0d 08 f2 17 f0    	mov    0xf017f208,%ecx
f01003f9:	89 cb                	mov    %ecx,%ebx
f01003fb:	83 e3 40             	and    $0x40,%ebx
f01003fe:	83 e0 7f             	and    $0x7f,%eax
f0100401:	85 db                	test   %ebx,%ebx
f0100403:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100406:	0f b6 d2             	movzbl %dl,%edx
f0100409:	0f b6 82 20 4e 10 f0 	movzbl -0xfefb1e0(%edx),%eax
f0100410:	83 c8 40             	or     $0x40,%eax
f0100413:	0f b6 c0             	movzbl %al,%eax
f0100416:	f7 d0                	not    %eax
f0100418:	21 c1                	and    %eax,%ecx
f010041a:	89 0d 08 f2 17 f0    	mov    %ecx,0xf017f208
		return 0;
f0100420:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100425:	e9 89 00 00 00       	jmp    f01004b3 <kbd_proc_data+0xf8>
	} else if (shift & E0ESC) {
f010042a:	8b 0d 08 f2 17 f0    	mov    0xf017f208,%ecx
f0100430:	f6 c1 40             	test   $0x40,%cl
f0100433:	74 0e                	je     f0100443 <kbd_proc_data+0x88>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100435:	89 c2                	mov    %eax,%edx
f0100437:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f010043a:	83 e1 bf             	and    $0xffffffbf,%ecx
f010043d:	89 0d 08 f2 17 f0    	mov    %ecx,0xf017f208
	}

	shift |= shiftcode[data];
f0100443:	0f b6 d2             	movzbl %dl,%edx
f0100446:	0f b6 82 20 4e 10 f0 	movzbl -0xfefb1e0(%edx),%eax
f010044d:	0b 05 08 f2 17 f0    	or     0xf017f208,%eax
	shift ^= togglecode[data];
f0100453:	0f b6 8a 20 4f 10 f0 	movzbl -0xfefb0e0(%edx),%ecx
f010045a:	31 c8                	xor    %ecx,%eax
f010045c:	a3 08 f2 17 f0       	mov    %eax,0xf017f208

	c = charcode[shift & (CTL | SHIFT)][data];
f0100461:	89 c1                	mov    %eax,%ecx
f0100463:	83 e1 03             	and    $0x3,%ecx
f0100466:	8b 0c 8d 20 50 10 f0 	mov    -0xfefafe0(,%ecx,4),%ecx
f010046d:	0f b6 1c 11          	movzbl (%ecx,%edx,1),%ebx
	if (shift & CAPSLOCK) {
f0100471:	a8 08                	test   $0x8,%al
f0100473:	74 19                	je     f010048e <kbd_proc_data+0xd3>
		if ('a' <= c && c <= 'z')
f0100475:	8d 53 9f             	lea    -0x61(%ebx),%edx
f0100478:	83 fa 19             	cmp    $0x19,%edx
f010047b:	77 05                	ja     f0100482 <kbd_proc_data+0xc7>
			c += 'A' - 'a';
f010047d:	83 eb 20             	sub    $0x20,%ebx
f0100480:	eb 0c                	jmp    f010048e <kbd_proc_data+0xd3>
		else if ('A' <= c && c <= 'Z')
f0100482:	8d 4b bf             	lea    -0x41(%ebx),%ecx
			c += 'a' - 'A';
f0100485:	8d 53 20             	lea    0x20(%ebx),%edx
f0100488:	83 f9 19             	cmp    $0x19,%ecx
f010048b:	0f 46 da             	cmovbe %edx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010048e:	f7 d0                	not    %eax
f0100490:	a8 06                	test   $0x6,%al
f0100492:	75 1f                	jne    f01004b3 <kbd_proc_data+0xf8>
f0100494:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010049a:	75 17                	jne    f01004b3 <kbd_proc_data+0xf8>
		cprintf("Rebooting!\n");
f010049c:	c7 04 24 ed 4d 10 f0 	movl   $0xf0104ded,(%esp)
f01004a3:	e8 12 33 00 00       	call   f01037ba <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01004a8:	ba 92 00 00 00       	mov    $0x92,%edx
f01004ad:	b8 03 00 00 00       	mov    $0x3,%eax
f01004b2:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01004b3:	89 d8                	mov    %ebx,%eax
f01004b5:	83 c4 14             	add    $0x14,%esp
f01004b8:	5b                   	pop    %ebx
f01004b9:	5d                   	pop    %ebp
f01004ba:	c3                   	ret    

f01004bb <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004bb:	55                   	push   %ebp
f01004bc:	89 e5                	mov    %esp,%ebp
f01004be:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f01004c1:	83 3d e0 ef 17 f0 00 	cmpl   $0x0,0xf017efe0
f01004c8:	74 0a                	je     f01004d4 <serial_intr+0x19>
		cons_intr(serial_proc_data);
f01004ca:	b8 7e 01 10 f0       	mov    $0xf010017e,%eax
f01004cf:	e8 c6 fc ff ff       	call   f010019a <cons_intr>
}
f01004d4:	c9                   	leave  
f01004d5:	c3                   	ret    

f01004d6 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004d6:	55                   	push   %ebp
f01004d7:	89 e5                	mov    %esp,%ebp
f01004d9:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004dc:	b8 bb 03 10 f0       	mov    $0xf01003bb,%eax
f01004e1:	e8 b4 fc ff ff       	call   f010019a <cons_intr>
}
f01004e6:	c9                   	leave  
f01004e7:	c3                   	ret    

f01004e8 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004e8:	55                   	push   %ebp
f01004e9:	89 e5                	mov    %esp,%ebp
f01004eb:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004ee:	e8 c8 ff ff ff       	call   f01004bb <serial_intr>
	kbd_intr();
f01004f3:	e8 de ff ff ff       	call   f01004d6 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004f8:	8b 15 00 f2 17 f0    	mov    0xf017f200,%edx
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f01004fe:	b8 00 00 00 00       	mov    $0x0,%eax
	// (e.g., when called from the kernel monitor).
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100503:	3b 15 04 f2 17 f0    	cmp    0xf017f204,%edx
f0100509:	74 1e                	je     f0100529 <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f010050b:	0f b6 82 00 f0 17 f0 	movzbl -0xfe81000(%edx),%eax
f0100512:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f0100515:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010051b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100520:	0f 44 d1             	cmove  %ecx,%edx
f0100523:	89 15 00 f2 17 f0    	mov    %edx,0xf017f200
		return c;
	}
	return 0;
}
f0100529:	c9                   	leave  
f010052a:	c3                   	ret    

f010052b <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010052b:	55                   	push   %ebp
f010052c:	89 e5                	mov    %esp,%ebp
f010052e:	57                   	push   %edi
f010052f:	56                   	push   %esi
f0100530:	53                   	push   %ebx
f0100531:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100534:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010053b:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100542:	5a a5 
	if (*cp != 0xA55A) {
f0100544:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010054b:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010054f:	74 11                	je     f0100562 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100551:	c7 05 0c f2 17 f0 b4 	movl   $0x3b4,0xf017f20c
f0100558:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010055b:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100560:	eb 16                	jmp    f0100578 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100562:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100569:	c7 05 0c f2 17 f0 d4 	movl   $0x3d4,0xf017f20c
f0100570:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100573:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f0100578:	8b 0d 0c f2 17 f0    	mov    0xf017f20c,%ecx
f010057e:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100583:	89 ca                	mov    %ecx,%edx
f0100585:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100586:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100589:	89 da                	mov    %ebx,%edx
f010058b:	ec                   	in     (%dx),%al
f010058c:	0f b6 f8             	movzbl %al,%edi
f010058f:	c1 e7 08             	shl    $0x8,%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100592:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100597:	89 ca                	mov    %ecx,%edx
f0100599:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010059a:	89 da                	mov    %ebx,%edx
f010059c:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010059d:	89 35 10 f2 17 f0    	mov    %esi,0xf017f210
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005a3:	0f b6 d8             	movzbl %al,%ebx
f01005a6:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005a8:	66 89 3d 14 f2 17 f0 	mov    %di,0xf017f214
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005af:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f01005b4:	b8 00 00 00 00       	mov    $0x0,%eax
f01005b9:	89 da                	mov    %ebx,%edx
f01005bb:	ee                   	out    %al,(%dx)
f01005bc:	b2 fb                	mov    $0xfb,%dl
f01005be:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005c3:	ee                   	out    %al,(%dx)
f01005c4:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f01005c9:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005ce:	89 ca                	mov    %ecx,%edx
f01005d0:	ee                   	out    %al,(%dx)
f01005d1:	b2 f9                	mov    $0xf9,%dl
f01005d3:	b8 00 00 00 00       	mov    $0x0,%eax
f01005d8:	ee                   	out    %al,(%dx)
f01005d9:	b2 fb                	mov    $0xfb,%dl
f01005db:	b8 03 00 00 00       	mov    $0x3,%eax
f01005e0:	ee                   	out    %al,(%dx)
f01005e1:	b2 fc                	mov    $0xfc,%dl
f01005e3:	b8 00 00 00 00       	mov    $0x0,%eax
f01005e8:	ee                   	out    %al,(%dx)
f01005e9:	b2 f9                	mov    $0xf9,%dl
f01005eb:	b8 01 00 00 00       	mov    $0x1,%eax
f01005f0:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005f1:	b2 fd                	mov    $0xfd,%dl
f01005f3:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005f4:	3c ff                	cmp    $0xff,%al
f01005f6:	0f 95 c0             	setne  %al
f01005f9:	0f b6 c0             	movzbl %al,%eax
f01005fc:	89 c6                	mov    %eax,%esi
f01005fe:	a3 e0 ef 17 f0       	mov    %eax,0xf017efe0
f0100603:	89 da                	mov    %ebx,%edx
f0100605:	ec                   	in     (%dx),%al
f0100606:	89 ca                	mov    %ecx,%edx
f0100608:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100609:	85 f6                	test   %esi,%esi
f010060b:	75 0c                	jne    f0100619 <cons_init+0xee>
		cprintf("Serial port does not exist!\n");
f010060d:	c7 04 24 f9 4d 10 f0 	movl   $0xf0104df9,(%esp)
f0100614:	e8 a1 31 00 00       	call   f01037ba <cprintf>
}
f0100619:	83 c4 1c             	add    $0x1c,%esp
f010061c:	5b                   	pop    %ebx
f010061d:	5e                   	pop    %esi
f010061e:	5f                   	pop    %edi
f010061f:	5d                   	pop    %ebp
f0100620:	c3                   	ret    

f0100621 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100621:	55                   	push   %ebp
f0100622:	89 e5                	mov    %esp,%ebp
f0100624:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100627:	8b 45 08             	mov    0x8(%ebp),%eax
f010062a:	e8 a8 fb ff ff       	call   f01001d7 <cons_putc>
}
f010062f:	c9                   	leave  
f0100630:	c3                   	ret    

f0100631 <getchar>:

int
getchar(void)
{
f0100631:	55                   	push   %ebp
f0100632:	89 e5                	mov    %esp,%ebp
f0100634:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100637:	e8 ac fe ff ff       	call   f01004e8 <cons_getc>
f010063c:	85 c0                	test   %eax,%eax
f010063e:	74 f7                	je     f0100637 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100640:	c9                   	leave  
f0100641:	c3                   	ret    

f0100642 <iscons>:

int
iscons(int fdnum)
{
f0100642:	55                   	push   %ebp
f0100643:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100645:	b8 01 00 00 00       	mov    $0x1,%eax
f010064a:	5d                   	pop    %ebp
f010064b:	c3                   	ret    
f010064c:	00 00                	add    %al,(%eax)
	...

f0100650 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100650:	55                   	push   %ebp
f0100651:	89 e5                	mov    %esp,%ebp
f0100653:	83 ec 18             	sub    $0x18,%esp
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100656:	c7 04 24 30 50 10 f0 	movl   $0xf0105030,(%esp)
f010065d:	e8 58 31 00 00       	call   f01037ba <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100662:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100669:	00 
f010066a:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100671:	f0 
f0100672:	c7 04 24 d8 51 10 f0 	movl   $0xf01051d8,(%esp)
f0100679:	e8 3c 31 00 00       	call   f01037ba <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010067e:	c7 44 24 08 95 4d 10 	movl   $0x104d95,0x8(%esp)
f0100685:	00 
f0100686:	c7 44 24 04 95 4d 10 	movl   $0xf0104d95,0x4(%esp)
f010068d:	f0 
f010068e:	c7 04 24 fc 51 10 f0 	movl   $0xf01051fc,(%esp)
f0100695:	e8 20 31 00 00       	call   f01037ba <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010069a:	c7 44 24 08 ca ef 17 	movl   $0x17efca,0x8(%esp)
f01006a1:	00 
f01006a2:	c7 44 24 04 ca ef 17 	movl   $0xf017efca,0x4(%esp)
f01006a9:	f0 
f01006aa:	c7 04 24 20 52 10 f0 	movl   $0xf0105220,(%esp)
f01006b1:	e8 04 31 00 00       	call   f01037ba <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006b6:	c7 44 24 08 d0 fe 17 	movl   $0x17fed0,0x8(%esp)
f01006bd:	00 
f01006be:	c7 44 24 04 d0 fe 17 	movl   $0xf017fed0,0x4(%esp)
f01006c5:	f0 
f01006c6:	c7 04 24 44 52 10 f0 	movl   $0xf0105244,(%esp)
f01006cd:	e8 e8 30 00 00       	call   f01037ba <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
f01006d2:	b8 cf 02 18 f0       	mov    $0xf01802cf,%eax
f01006d7:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006dc:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006e2:	85 c0                	test   %eax,%eax
f01006e4:	0f 48 c2             	cmovs  %edx,%eax
f01006e7:	c1 f8 0a             	sar    $0xa,%eax
f01006ea:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006ee:	c7 04 24 68 52 10 f0 	movl   $0xf0105268,(%esp)
f01006f5:	e8 c0 30 00 00       	call   f01037ba <cprintf>
		(end-entry+1023)/1024);
	return 0;
}
f01006fa:	b8 00 00 00 00       	mov    $0x0,%eax
f01006ff:	c9                   	leave  
f0100700:	c3                   	ret    

f0100701 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100701:	55                   	push   %ebp
f0100702:	89 e5                	mov    %esp,%ebp
f0100704:	53                   	push   %ebx
f0100705:	83 ec 14             	sub    $0x14,%esp
f0100708:	bb 00 00 00 00       	mov    $0x0,%ebx
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010070d:	8b 83 24 56 10 f0    	mov    -0xfefa9dc(%ebx),%eax
f0100713:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100717:	8b 83 20 56 10 f0    	mov    -0xfefa9e0(%ebx),%eax
f010071d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100721:	c7 04 24 49 50 10 f0 	movl   $0xf0105049,(%esp)
f0100728:	e8 8d 30 00 00       	call   f01037ba <cprintf>
f010072d:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f0100730:	83 fb 54             	cmp    $0x54,%ebx
f0100733:	75 d8                	jne    f010070d <mon_help+0xc>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f0100735:	b8 00 00 00 00       	mov    $0x0,%eax
f010073a:	83 c4 14             	add    $0x14,%esp
f010073d:	5b                   	pop    %ebx
f010073e:	5d                   	pop    %ebp
f010073f:	c3                   	ret    

f0100740 <mon_dumpvirtual>:
	return 0;
}

int 
mon_dumpvirtual(int argc, char **argv, struct Trapframe *tf)
{
f0100740:	55                   	push   %ebp
f0100741:	89 e5                	mov    %esp,%ebp
f0100743:	57                   	push   %edi
f0100744:	56                   	push   %esi
f0100745:	53                   	push   %ebx
f0100746:	83 ec 2c             	sub    $0x2c,%esp
f0100749:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	if(argc!=3)
f010074c:	83 7d 08 03          	cmpl   $0x3,0x8(%ebp)
f0100750:	74 11                	je     f0100763 <mon_dumpvirtual+0x23>
		{
			cprintf("Usage:dumpvirtual <address> <size>");
f0100752:	c7 04 24 94 52 10 f0 	movl   $0xf0105294,(%esp)
f0100759:	e8 5c 30 00 00       	call   f01037ba <cprintf>
			return 0;
f010075e:	e9 f8 00 00 00       	jmp    f010085b <mon_dumpvirtual+0x11b>
		}
	uintptr_t va=strtol(argv[1], 0,16);
f0100763:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f010076a:	00 
f010076b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100772:	00 
f0100773:	8b 43 04             	mov    0x4(%ebx),%eax
f0100776:	89 04 24             	mov    %eax,(%esp)
f0100779:	e8 96 42 00 00       	call   f0104a14 <strtol>
	uintptr_t va_assign = va&(~0xf);
f010077e:	83 e0 f0             	and    $0xfffffff0,%eax
f0100781:	89 45 dc             	mov    %eax,-0x24(%ebp)
	uint32_t size = strtol(argv[2],0,10);
f0100784:	c7 44 24 08 0a 00 00 	movl   $0xa,0x8(%esp)
f010078b:	00 
f010078c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100793:	00 
f0100794:	8b 43 08             	mov    0x8(%ebx),%eax
f0100797:	89 04 24             	mov    %eax,(%esp)
f010079a:	e8 75 42 00 00       	call   f0104a14 <strtol>
f010079f:	89 45 e0             	mov    %eax,-0x20(%ebp)
	uint32_t i =0;
	uint32_t j=0;
	cprintf("VA	     Contents");
f01007a2:	c7 04 24 52 50 10 f0 	movl   $0xf0105052,(%esp)
f01007a9:	e8 0c 30 00 00       	call   f01037ba <cprintf>
	for (i=0;i<size/4;i++)
f01007ae:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01007b1:	c1 e8 02             	shr    $0x2,%eax
f01007b4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01007b7:	89 c7                	mov    %eax,%edi
f01007b9:	85 c0                	test   %eax,%eax
f01007bb:	74 43                	je     f0100800 <mon_dumpvirtual+0xc0>
f01007bd:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01007c0:	bf 00 00 00 00       	mov    $0x0,%edi
		{
		cprintf("\n0x%08x :",va_assign+i*16);
f01007c5:	89 74 24 04          	mov    %esi,0x4(%esp)
f01007c9:	c7 04 24 63 50 10 f0 	movl   $0xf0105063,(%esp)
f01007d0:	e8 e5 2f 00 00       	call   f01037ba <cprintf>
		for(j=0;j<4;j++)
f01007d5:	bb 00 00 00 00       	mov    $0x0,%ebx
			cprintf("0x%08x ",*((uintptr_t *)(va_assign+i*16+4*j)));
f01007da:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
f01007dd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007e1:	c7 04 24 6d 50 10 f0 	movl   $0xf010506d,(%esp)
f01007e8:	e8 cd 2f 00 00       	call   f01037ba <cprintf>
	uint32_t j=0;
	cprintf("VA	     Contents");
	for (i=0;i<size/4;i++)
		{
		cprintf("\n0x%08x :",va_assign+i*16);
		for(j=0;j<4;j++)
f01007ed:	83 c3 01             	add    $0x1,%ebx
f01007f0:	83 fb 04             	cmp    $0x4,%ebx
f01007f3:	75 e5                	jne    f01007da <mon_dumpvirtual+0x9a>
	uintptr_t va_assign = va&(~0xf);
	uint32_t size = strtol(argv[2],0,10);
	uint32_t i =0;
	uint32_t j=0;
	cprintf("VA	     Contents");
	for (i=0;i<size/4;i++)
f01007f5:	83 c7 01             	add    $0x1,%edi
f01007f8:	83 c6 10             	add    $0x10,%esi
f01007fb:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f01007fe:	75 c5                	jne    f01007c5 <mon_dumpvirtual+0x85>
		{
		cprintf("\n0x%08x :",va_assign+i*16);
		for(j=0;j<4;j++)
			cprintf("0x%08x ",*((uintptr_t *)(va_assign+i*16+4*j)));
		}
	if (size-i*4>0)
f0100800:	8d 1c bd 00 00 00 00 	lea    0x0(,%edi,4),%ebx
f0100807:	3b 5d e0             	cmp    -0x20(%ebp),%ebx
f010080a:	74 43                	je     f010084f <mon_dumpvirtual+0x10f>
		{
		cprintf("\n0x%08x :",va_assign+i*16);
f010080c:	89 f8                	mov    %edi,%eax
f010080e:	c1 e0 04             	shl    $0x4,%eax
f0100811:	03 45 dc             	add    -0x24(%ebp),%eax
f0100814:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100818:	c7 04 24 63 50 10 f0 	movl   $0xf0105063,(%esp)
f010081f:	e8 96 2f 00 00       	call   f01037ba <cprintf>
		for (j=0;(i*4+j<size);j++)
f0100824:	39 5d e0             	cmp    %ebx,-0x20(%ebp)
f0100827:	76 26                	jbe    f010084f <mon_dumpvirtual+0x10f>
f0100829:	89 d8                	mov    %ebx,%eax
f010082b:	8b 75 dc             	mov    -0x24(%ebp),%esi
f010082e:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100831:	eb 02                	jmp    f0100835 <mon_dumpvirtual+0xf5>
f0100833:	89 d8                	mov    %ebx,%eax
			cprintf("0x%08x ",*((uintptr_t *)(va_assign+i*16+4*j)));
f0100835:	8b 04 86             	mov    (%esi,%eax,4),%eax
f0100838:	89 44 24 04          	mov    %eax,0x4(%esp)
f010083c:	c7 04 24 6d 50 10 f0 	movl   $0xf010506d,(%esp)
f0100843:	e8 72 2f 00 00       	call   f01037ba <cprintf>
			cprintf("0x%08x ",*((uintptr_t *)(va_assign+i*16+4*j)));
		}
	if (size-i*4>0)
		{
		cprintf("\n0x%08x :",va_assign+i*16);
		for (j=0;(i*4+j<size);j++)
f0100848:	83 c3 01             	add    $0x1,%ebx
f010084b:	39 df                	cmp    %ebx,%edi
f010084d:	77 e4                	ja     f0100833 <mon_dumpvirtual+0xf3>
			cprintf("0x%08x ",*((uintptr_t *)(va_assign+i*16+4*j)));
		}
	cprintf("\n");
f010084f:	c7 04 24 31 60 10 f0 	movl   $0xf0106031,(%esp)
f0100856:	e8 5f 2f 00 00       	call   f01037ba <cprintf>
	return 0;
}
f010085b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100860:	83 c4 2c             	add    $0x2c,%esp
f0100863:	5b                   	pop    %ebx
f0100864:	5e                   	pop    %esi
f0100865:	5f                   	pop    %edi
f0100866:	5d                   	pop    %ebp
f0100867:	c3                   	ret    

f0100868 <mon_dumpphysical>:

int 
mon_dumpphysical(int argc, char **argv, struct Trapframe *tf)
{
f0100868:	55                   	push   %ebp
f0100869:	89 e5                	mov    %esp,%ebp
f010086b:	57                   	push   %edi
f010086c:	56                   	push   %esi
f010086d:	53                   	push   %ebx
f010086e:	83 ec 3c             	sub    $0x3c,%esp
f0100871:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	if(argc!=3)
f0100874:	83 7d 08 03          	cmpl   $0x3,0x8(%ebp)
f0100878:	74 11                	je     f010088b <mon_dumpphysical+0x23>
		{
			cprintf("Usage:dumpphysical <address> <size>");
f010087a:	c7 04 24 b8 52 10 f0 	movl   $0xf01052b8,(%esp)
f0100881:	e8 34 2f 00 00       	call   f01037ba <cprintf>
			return 0;
f0100886:	e9 46 01 00 00       	jmp    f01009d1 <mon_dumpphysical+0x169>
		}
	physaddr_t pa=(strtol(argv[1], 0,16));
f010088b:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f0100892:	00 
f0100893:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010089a:	00 
f010089b:	8b 43 04             	mov    0x4(%ebx),%eax
f010089e:	89 04 24             	mov    %eax,(%esp)
f01008a1:	e8 6e 41 00 00       	call   f0104a14 <strtol>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01008a6:	89 c2                	mov    %eax,%edx
f01008a8:	c1 ea 0c             	shr    $0xc,%edx
f01008ab:	3b 15 c4 fe 17 f0    	cmp    0xf017fec4,%edx
f01008b1:	72 20                	jb     f01008d3 <mon_dumpphysical+0x6b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01008b3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01008b7:	c7 44 24 08 dc 52 10 	movl   $0xf01052dc,0x8(%esp)
f01008be:	f0 
f01008bf:	c7 44 24 04 ea 00 00 	movl   $0xea,0x4(%esp)
f01008c6:	00 
f01008c7:	c7 04 24 75 50 10 f0 	movl   $0xf0105075,(%esp)
f01008ce:	e8 eb f7 ff ff       	call   f01000be <_panic>
	physaddr_t pa_assign = pa&(~0xf);
f01008d3:	89 c2                	mov    %eax,%edx
f01008d5:	83 e2 f0             	and    $0xfffffff0,%edx
f01008d8:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	return (void *)(pa + KERNBASE);
f01008db:	2d 00 00 00 10       	sub    $0x10000000,%eax
	uintptr_t va=(uint32_t)KADDR(pa);
	uintptr_t va_assign = va&(~0xf);
f01008e0:	83 e0 f0             	and    $0xfffffff0,%eax
f01008e3:	89 45 d0             	mov    %eax,-0x30(%ebp)
	uint32_t size = strtol(argv[2],0,10);
f01008e6:	c7 44 24 08 0a 00 00 	movl   $0xa,0x8(%esp)
f01008ed:	00 
f01008ee:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01008f5:	00 
f01008f6:	8b 43 08             	mov    0x8(%ebx),%eax
f01008f9:	89 04 24             	mov    %eax,(%esp)
f01008fc:	e8 13 41 00 00       	call   f0104a14 <strtol>
f0100901:	89 45 d8             	mov    %eax,-0x28(%ebp)
	uint32_t i =0;
	uint32_t j=0;
	cprintf("PA	     Contents");
f0100904:	c7 04 24 84 50 10 f0 	movl   $0xf0105084,(%esp)
f010090b:	e8 aa 2e 00 00       	call   f01037ba <cprintf>
	for (i=0;i<size/4;i++)
f0100910:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100913:	c1 e8 02             	shr    $0x2,%eax
f0100916:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100919:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010091c:	85 c0                	test   %eax,%eax
f010091e:	74 56                	je     f0100976 <mon_dumpphysical+0x10e>
f0100920:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100923:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	cprintf("\n");
	return 0;
}

int 
mon_dumpphysical(int argc, char **argv, struct Trapframe *tf)
f010092a:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010092d:	29 fa                	sub    %edi,%edx
f010092f:	89 55 dc             	mov    %edx,-0x24(%ebp)
	uint32_t i =0;
	uint32_t j=0;
	cprintf("PA	     Contents");
	for (i=0;i<size/4;i++)
		{
		cprintf("\n0x%08x :",pa_assign+i*16);
f0100932:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100936:	c7 04 24 63 50 10 f0 	movl   $0xf0105063,(%esp)
f010093d:	e8 78 2e 00 00       	call   f01037ba <cprintf>
		for(j=0;j<4;j++)
f0100942:	bb 00 00 00 00       	mov    $0x0,%ebx
	cprintf("\n");
	return 0;
}

int 
mon_dumpphysical(int argc, char **argv, struct Trapframe *tf)
f0100947:	8b 75 dc             	mov    -0x24(%ebp),%esi
f010094a:	01 fe                	add    %edi,%esi
	cprintf("PA	     Contents");
	for (i=0;i<size/4;i++)
		{
		cprintf("\n0x%08x :",pa_assign+i*16);
		for(j=0;j<4;j++)
			cprintf("0x%08x ",*((uintptr_t *)(va_assign+i*16+4*j)));
f010094c:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
f010094f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100953:	c7 04 24 6d 50 10 f0 	movl   $0xf010506d,(%esp)
f010095a:	e8 5b 2e 00 00       	call   f01037ba <cprintf>
	uint32_t j=0;
	cprintf("PA	     Contents");
	for (i=0;i<size/4;i++)
		{
		cprintf("\n0x%08x :",pa_assign+i*16);
		for(j=0;j<4;j++)
f010095f:	83 c3 01             	add    $0x1,%ebx
f0100962:	83 fb 04             	cmp    $0x4,%ebx
f0100965:	75 e5                	jne    f010094c <mon_dumpphysical+0xe4>
	uintptr_t va_assign = va&(~0xf);
	uint32_t size = strtol(argv[2],0,10);
	uint32_t i =0;
	uint32_t j=0;
	cprintf("PA	     Contents");
	for (i=0;i<size/4;i++)
f0100967:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
f010096b:	83 c7 10             	add    $0x10,%edi
f010096e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100971:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f0100974:	75 bc                	jne    f0100932 <mon_dumpphysical+0xca>
		{
		cprintf("\n0x%08x :",pa_assign+i*16);
		for(j=0;j<4;j++)
			cprintf("0x%08x ",*((uintptr_t *)(va_assign+i*16+4*j)));
		}
	if (size-i*4>0)
f0100976:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100979:	c1 e3 02             	shl    $0x2,%ebx
f010097c:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f010097f:	74 44                	je     f01009c5 <mon_dumpphysical+0x15d>
		{
		cprintf("\n0x%08x :",pa_assign+i*16);
f0100981:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100984:	c1 e0 04             	shl    $0x4,%eax
f0100987:	03 45 d4             	add    -0x2c(%ebp),%eax
f010098a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010098e:	c7 04 24 63 50 10 f0 	movl   $0xf0105063,(%esp)
f0100995:	e8 20 2e 00 00       	call   f01037ba <cprintf>
		for (j=0;(i*4+j<size);j++)
f010099a:	39 5d d8             	cmp    %ebx,-0x28(%ebp)
f010099d:	76 26                	jbe    f01009c5 <mon_dumpphysical+0x15d>
f010099f:	89 d8                	mov    %ebx,%eax
f01009a1:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01009a4:	8b 7d d8             	mov    -0x28(%ebp),%edi
f01009a7:	eb 02                	jmp    f01009ab <mon_dumpphysical+0x143>
f01009a9:	89 d8                	mov    %ebx,%eax
			cprintf("0x%08x ",*((uintptr_t *)(va_assign+i*16+4*j)));
f01009ab:	8b 04 86             	mov    (%esi,%eax,4),%eax
f01009ae:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009b2:	c7 04 24 6d 50 10 f0 	movl   $0xf010506d,(%esp)
f01009b9:	e8 fc 2d 00 00       	call   f01037ba <cprintf>
			cprintf("0x%08x ",*((uintptr_t *)(va_assign+i*16+4*j)));
		}
	if (size-i*4>0)
		{
		cprintf("\n0x%08x :",pa_assign+i*16);
		for (j=0;(i*4+j<size);j++)
f01009be:	83 c3 01             	add    $0x1,%ebx
f01009c1:	39 df                	cmp    %ebx,%edi
f01009c3:	77 e4                	ja     f01009a9 <mon_dumpphysical+0x141>
			cprintf("0x%08x ",*((uintptr_t *)(va_assign+i*16+4*j)));
		}
	cprintf("\n");
f01009c5:	c7 04 24 31 60 10 f0 	movl   $0xf0106031,(%esp)
f01009cc:	e8 e9 2d 00 00       	call   f01037ba <cprintf>
	return 0;
}
f01009d1:	b8 00 00 00 00       	mov    $0x0,%eax
f01009d6:	83 c4 3c             	add    $0x3c,%esp
f01009d9:	5b                   	pop    %ebx
f01009da:	5e                   	pop    %esi
f01009db:	5f                   	pop    %edi
f01009dc:	5d                   	pop    %ebp
f01009dd:	c3                   	ret    

f01009de <mon_setmappings>:
	
}

int
mon_setmappings(int argc, char **argv, struct Trapframe *tf)
{
f01009de:	55                   	push   %ebp
f01009df:	89 e5                	mov    %esp,%ebp
f01009e1:	83 ec 28             	sub    $0x28,%esp
f01009e4:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f01009e7:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01009ea:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01009ed:	8b 7d 08             	mov    0x8(%ebp),%edi
f01009f0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	if(argc!=3&&argc!=4)
f01009f3:	8d 47 fd             	lea    -0x3(%edi),%eax
f01009f6:	83 f8 01             	cmp    $0x1,%eax
f01009f9:	76 1d                	jbe    f0100a18 <mon_setmappings+0x3a>
		{
			cprintf("set, clear, or change the permissions of any mapping in the current address space");
f01009fb:	c7 04 24 00 53 10 f0 	movl   $0xf0105300,(%esp)
f0100a02:	e8 b3 2d 00 00       	call   f01037ba <cprintf>
			cprintf("Usage:setmappings <OPER> <VA> (<Permission>)\n OPER:-set,-clear,-change Permission:U,W\n");
f0100a07:	c7 04 24 54 53 10 f0 	movl   $0xf0105354,(%esp)
f0100a0e:	e8 a7 2d 00 00       	call   f01037ba <cprintf>
			return 0;
f0100a13:	e9 f0 00 00 00       	jmp    f0100b08 <mon_setmappings+0x12a>
		}
	
	uintptr_t va = strtol(argv[2], 0,16);
f0100a18:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f0100a1f:	00 
f0100a20:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100a27:	00 
f0100a28:	8b 43 08             	mov    0x8(%ebx),%eax
f0100a2b:	89 04 24             	mov    %eax,(%esp)
f0100a2e:	e8 e1 3f 00 00       	call   f0104a14 <strtol>
	uintptr_t va_page = PTE_ADDR(va);
	pte_t *pte;
	pte = pgdir_walk(kern_pgdir, (void * )(va_page), 0);
f0100a33:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100a3a:	00 
			cprintf("Usage:setmappings <OPER> <VA> (<Permission>)\n OPER:-set,-clear,-change Permission:U,W\n");
			return 0;
		}
	
	uintptr_t va = strtol(argv[2], 0,16);
	uintptr_t va_page = PTE_ADDR(va);
f0100a3b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	pte_t *pte;
	pte = pgdir_walk(kern_pgdir, (void * )(va_page), 0);
f0100a40:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a44:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f0100a49:	89 04 24             	mov    %eax,(%esp)
f0100a4c:	e8 70 0a 00 00       	call   f01014c1 <pgdir_walk>
f0100a51:	89 c6                	mov    %eax,%esi
	if(strcmp(argv[1],"-clear")==0)
f0100a53:	c7 44 24 04 95 50 10 	movl   $0xf0105095,0x4(%esp)
f0100a5a:	f0 
f0100a5b:	8b 43 04             	mov    0x4(%ebx),%eax
f0100a5e:	89 04 24             	mov    %eax,(%esp)
f0100a61:	e8 65 3d 00 00       	call   f01047cb <strcmp>
f0100a66:	85 c0                	test   %eax,%eax
f0100a68:	75 1e                	jne    f0100a88 <mon_setmappings+0xaa>
	{
		*pte=PTE_ADDR(*pte);
f0100a6a:	8b 06                	mov    (%esi),%eax
f0100a6c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a71:	89 06                	mov    %eax,(%esi)
		cprintf("\n0x%08x permissions clear OK",(*pte));
f0100a73:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a77:	c7 04 24 9c 50 10 f0 	movl   $0xf010509c,(%esp)
f0100a7e:	e8 37 2d 00 00       	call   f01037ba <cprintf>
f0100a83:	e9 80 00 00 00       	jmp    f0100b08 <mon_setmappings+0x12a>
	}
	else if(strcmp(argv[1],"-set")==0||strcmp(argv[1],"-change")==0)
f0100a88:	c7 44 24 04 b9 50 10 	movl   $0xf01050b9,0x4(%esp)
f0100a8f:	f0 
f0100a90:	8b 43 04             	mov    0x4(%ebx),%eax
f0100a93:	89 04 24             	mov    %eax,(%esp)
f0100a96:	e8 30 3d 00 00       	call   f01047cb <strcmp>
f0100a9b:	85 c0                	test   %eax,%eax
f0100a9d:	74 17                	je     f0100ab6 <mon_setmappings+0xd8>
f0100a9f:	c7 44 24 04 be 50 10 	movl   $0xf01050be,0x4(%esp)
f0100aa6:	f0 
f0100aa7:	8b 43 04             	mov    0x4(%ebx),%eax
f0100aaa:	89 04 24             	mov    %eax,(%esp)
f0100aad:	e8 19 3d 00 00       	call   f01047cb <strcmp>
f0100ab2:	85 c0                	test   %eax,%eax
f0100ab4:	75 52                	jne    f0100b08 <mon_setmappings+0x12a>
	{
		if(argc!=4)
f0100ab6:	83 ff 04             	cmp    $0x4,%edi
f0100ab9:	74 03                	je     f0100abe <mon_setmappings+0xe0>
		{
			*pte=(*pte)&(~PTE_U)&(~PTE_W);
f0100abb:	83 26 f9             	andl   $0xfffffff9,(%esi)
		}
		if (argv[3][0]=='W'||argv[3][0]=='w'||argv[3][1]=='W'||argv[3][1]=='w')
f0100abe:	8b 43 0c             	mov    0xc(%ebx),%eax
f0100ac1:	0f b6 10             	movzbl (%eax),%edx
f0100ac4:	80 fa 57             	cmp    $0x57,%dl
f0100ac7:	74 11                	je     f0100ada <mon_setmappings+0xfc>
f0100ac9:	80 fa 77             	cmp    $0x77,%dl
f0100acc:	74 0c                	je     f0100ada <mon_setmappings+0xfc>
f0100ace:	0f b6 40 01          	movzbl 0x1(%eax),%eax
f0100ad2:	3c 57                	cmp    $0x57,%al
f0100ad4:	74 04                	je     f0100ada <mon_setmappings+0xfc>
f0100ad6:	3c 77                	cmp    $0x77,%al
f0100ad8:	75 03                	jne    f0100add <mon_setmappings+0xff>
		{
			*pte=(*pte)|PTE_W;
f0100ada:	83 0e 02             	orl    $0x2,(%esi)
		}
		if (argv[3][0]=='U'||argv[3][0]=='u'||argv[3][1]=='U'||argv[3][1]=='u')
f0100add:	8b 43 0c             	mov    0xc(%ebx),%eax
f0100ae0:	0f b6 10             	movzbl (%eax),%edx
f0100ae3:	80 fa 55             	cmp    $0x55,%dl
f0100ae6:	74 11                	je     f0100af9 <mon_setmappings+0x11b>
f0100ae8:	80 fa 75             	cmp    $0x75,%dl
f0100aeb:	74 0c                	je     f0100af9 <mon_setmappings+0x11b>
f0100aed:	0f b6 40 01          	movzbl 0x1(%eax),%eax
f0100af1:	3c 55                	cmp    $0x55,%al
f0100af3:	74 04                	je     f0100af9 <mon_setmappings+0x11b>
f0100af5:	3c 75                	cmp    $0x75,%al
f0100af7:	75 03                	jne    f0100afc <mon_setmappings+0x11e>
		{
			*pte=(*pte)|PTE_U;
f0100af9:	83 0e 04             	orl    $0x4,(%esi)
		}
		cprintf("Permission set OK\n");
f0100afc:	c7 04 24 c6 50 10 f0 	movl   $0xf01050c6,(%esp)
f0100b03:	e8 b2 2c 00 00       	call   f01037ba <cprintf>
	}
	return 0;
}
f0100b08:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b0d:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100b10:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100b13:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100b16:	89 ec                	mov    %ebp,%esp
f0100b18:	5d                   	pop    %ebp
f0100b19:	c3                   	ret    

f0100b1a <mon_showmappings>:
	return 0;
}

int
mon_showmappings(int argc, char **argv, struct Trapframe *tf)
{
f0100b1a:	55                   	push   %ebp
f0100b1b:	89 e5                	mov    %esp,%ebp
f0100b1d:	57                   	push   %edi
f0100b1e:	56                   	push   %esi
f0100b1f:	53                   	push   %ebx
f0100b20:	83 ec 2c             	sub    $0x2c,%esp
f0100b23:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	if(argc!=3)
f0100b26:	83 7d 08 03          	cmpl   $0x3,0x8(%ebp)
f0100b2a:	74 11                	je     f0100b3d <mon_showmappings+0x23>
		{
			cprintf("Need low va and high va in 0x , for exampe:\nshowmappings 0x3000 0x5000\n");
f0100b2c:	c7 04 24 ac 53 10 f0 	movl   $0xf01053ac,(%esp)
f0100b33:	e8 82 2c 00 00       	call   f01037ba <cprintf>
			return 0;
f0100b38:	e9 2a 01 00 00       	jmp    f0100c67 <mon_showmappings+0x14d>
		}
	uintptr_t va_low = strtol(argv[1], 0,16);
f0100b3d:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f0100b44:	00 
f0100b45:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100b4c:	00 
f0100b4d:	8b 43 04             	mov    0x4(%ebx),%eax
f0100b50:	89 04 24             	mov    %eax,(%esp)
f0100b53:	e8 bc 3e 00 00       	call   f0104a14 <strtol>
f0100b58:	89 c6                	mov    %eax,%esi
	uintptr_t va_high = strtol(argv[2], 0,16);
f0100b5a:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f0100b61:	00 
f0100b62:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100b69:	00 
f0100b6a:	8b 43 08             	mov    0x8(%ebx),%eax
f0100b6d:	89 04 24             	mov    %eax,(%esp)
f0100b70:	e8 9f 3e 00 00       	call   f0104a14 <strtol>
	uintptr_t va_low_page = PTE_ADDR(va_low);
f0100b75:	89 f3                	mov    %esi,%ebx
f0100b77:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t va_high_page = PTE_ADDR(va_high);
f0100b7d:	25 00 f0 ff ff       	and    $0xfffff000,%eax

	int pagenum = (va_high_page-va_low_page)/PGSIZE;
f0100b82:	29 d8                	sub    %ebx,%eax
f0100b84:	c1 e8 0c             	shr    $0xc,%eax
f0100b87:	89 45 e0             	mov    %eax,-0x20(%ebp)
	int i = 0;
	pte_t *pte;
	cprintf("----------output start------------\n");
f0100b8a:	c7 04 24 f4 53 10 f0 	movl   $0xf01053f4,(%esp)
f0100b91:	e8 24 2c 00 00       	call   f01037ba <cprintf>
	cprintf("Virtual Address	    Physical  Permissions(kernel/user)");
f0100b96:	c7 04 24 18 54 10 f0 	movl   $0xf0105418,(%esp)
f0100b9d:	e8 18 2c 00 00       	call   f01037ba <cprintf>
	for(i=0;i<pagenum;i++)
f0100ba2:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100ba6:	0f 8e af 00 00 00    	jle    f0100c5b <mon_showmappings+0x141>
f0100bac:	bf 00 00 00 00       	mov    $0x0,%edi
	{
		pte = pgdir_walk(kern_pgdir, (void * )(va_low_page+i*PGSIZE), 0);
f0100bb1:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100bb4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100bbb:	00 
f0100bbc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100bc0:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f0100bc5:	89 04 24             	mov    %eax,(%esp)
f0100bc8:	e8 f4 08 00 00       	call   f01014c1 <pgdir_walk>
f0100bcd:	89 c6                	mov    %eax,%esi
		cprintf("\n0x%08x - 0x%08x :",va_low_page+i*PGSIZE,va_low_page+(i+1)*PGSIZE);
f0100bcf:	83 c7 01             	add    $0x1,%edi
		}
	return 0;
}

int
mon_showmappings(int argc, char **argv, struct Trapframe *tf)
f0100bd2:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	cprintf("----------output start------------\n");
	cprintf("Virtual Address	    Physical  Permissions(kernel/user)");
	for(i=0;i<pagenum;i++)
	{
		pte = pgdir_walk(kern_pgdir, (void * )(va_low_page+i*PGSIZE), 0);
		cprintf("\n0x%08x - 0x%08x :",va_low_page+i*PGSIZE,va_low_page+(i+1)*PGSIZE);
f0100bd8:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100bdc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bdf:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100be3:	c7 04 24 d9 50 10 f0 	movl   $0xf01050d9,(%esp)
f0100bea:	e8 cb 2b 00 00       	call   f01037ba <cprintf>
		if ( pte!=NULL&& (*pte&PTE_P))//pte exist
f0100bef:	85 f6                	test   %esi,%esi
f0100bf1:	74 5f                	je     f0100c52 <mon_showmappings+0x138>
f0100bf3:	8b 06                	mov    (%esi),%eax
f0100bf5:	a8 01                	test   $0x1,%al
f0100bf7:	74 59                	je     f0100c52 <mon_showmappings+0x138>
		{
		cprintf("0x%08x ",PTE_ADDR(*pte));
f0100bf9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100bfe:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c02:	c7 04 24 6d 50 10 f0 	movl   $0xf010506d,(%esp)
f0100c09:	e8 ac 2b 00 00       	call   f01037ba <cprintf>
		if (*pte & PTE_W)
f0100c0e:	8b 06                	mov    (%esi),%eax
f0100c10:	a8 02                	test   $0x2,%al
f0100c12:	74 20                	je     f0100c34 <mon_showmappings+0x11a>
			{
			if (*pte & PTE_U)
f0100c14:	a8 04                	test   $0x4,%al
f0100c16:	74 0e                	je     f0100c26 <mon_showmappings+0x10c>
				cprintf("RW\\RW");
f0100c18:	c7 04 24 ec 50 10 f0 	movl   $0xf01050ec,(%esp)
f0100c1f:	e8 96 2b 00 00       	call   f01037ba <cprintf>
f0100c24:	eb 2c                	jmp    f0100c52 <mon_showmappings+0x138>
			else
				cprintf("RW\\--");
f0100c26:	c7 04 24 f2 50 10 f0 	movl   $0xf01050f2,(%esp)
f0100c2d:	e8 88 2b 00 00       	call   f01037ba <cprintf>
f0100c32:	eb 1e                	jmp    f0100c52 <mon_showmappings+0x138>
			}
		else
			{
			if (*pte & PTE_U)
f0100c34:	a8 04                	test   $0x4,%al
f0100c36:	74 0e                	je     f0100c46 <mon_showmappings+0x12c>
				cprintf("R-\\R-");
f0100c38:	c7 04 24 f8 50 10 f0 	movl   $0xf01050f8,(%esp)
f0100c3f:	e8 76 2b 00 00       	call   f01037ba <cprintf>
f0100c44:	eb 0c                	jmp    f0100c52 <mon_showmappings+0x138>
			else
				cprintf("R-\\--");
f0100c46:	c7 04 24 fe 50 10 f0 	movl   $0xf01050fe,(%esp)
f0100c4d:	e8 68 2b 00 00       	call   f01037ba <cprintf>
	int pagenum = (va_high_page-va_low_page)/PGSIZE;
	int i = 0;
	pte_t *pte;
	cprintf("----------output start------------\n");
	cprintf("Virtual Address	    Physical  Permissions(kernel/user)");
	for(i=0;i<pagenum;i++)
f0100c52:	39 7d e0             	cmp    %edi,-0x20(%ebp)
f0100c55:	0f 85 56 ff ff ff    	jne    f0100bb1 <mon_showmappings+0x97>
			else
				cprintf("R-\\--");
			}
		}
	}
	cprintf("\n----------output end------------\n");
f0100c5b:	c7 04 24 50 54 10 f0 	movl   $0xf0105450,(%esp)
f0100c62:	e8 53 2b 00 00       	call   f01037ba <cprintf>
	return 0;
	
}
f0100c67:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c6c:	83 c4 2c             	add    $0x2c,%esp
f0100c6f:	5b                   	pop    %ebx
f0100c70:	5e                   	pop    %esi
f0100c71:	5f                   	pop    %edi
f0100c72:	5d                   	pop    %ebp
f0100c73:	c3                   	ret    

f0100c74 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100c74:	55                   	push   %ebp
f0100c75:	89 e5                	mov    %esp,%ebp
f0100c77:	57                   	push   %edi
f0100c78:	56                   	push   %esi
f0100c79:	53                   	push   %ebx
f0100c7a:	81 ec 8c 00 00 00    	sub    $0x8c,%esp

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100c80:	89 eb                	mov    %ebp,%ebx
f0100c82:	89 de                	mov    %ebx,%esi
	// Your code here.
	uint32_t ebp,eip,arg[5];
	ebp = read_ebp();
	eip = *((uint32_t*)ebp+1);
f0100c84:	8b 7b 04             	mov    0x4(%ebx),%edi
	arg[0] = *((uint32_t*)ebp+2);
f0100c87:	8b 43 08             	mov    0x8(%ebx),%eax
f0100c8a:	89 45 a4             	mov    %eax,-0x5c(%ebp)
	arg[1] = *((uint32_t*)ebp+3);
f0100c8d:	8b 43 0c             	mov    0xc(%ebx),%eax
f0100c90:	89 45 a0             	mov    %eax,-0x60(%ebp)
	arg[2] = *((uint32_t*)ebp+4);
f0100c93:	8b 43 10             	mov    0x10(%ebx),%eax
f0100c96:	89 45 9c             	mov    %eax,-0x64(%ebp)
	arg[3] = *((uint32_t*)ebp+5);
f0100c99:	8b 43 14             	mov    0x14(%ebx),%eax
f0100c9c:	89 45 98             	mov    %eax,-0x68(%ebp)
	arg[4] = *((uint32_t*)ebp+6);
f0100c9f:	8b 43 18             	mov    0x18(%ebx),%eax
f0100ca2:	89 45 94             	mov    %eax,-0x6c(%ebp)

	cprintf("Stack backtrace:\n");
f0100ca5:	c7 04 24 04 51 10 f0 	movl   $0xf0105104,(%esp)
f0100cac:	e8 09 2b 00 00       	call   f01037ba <cprintf>
	
	while(ebp != 0x00)
f0100cb1:	85 db                	test   %ebx,%ebx
f0100cb3:	0f 84 e0 00 00 00    	je     f0100d99 <mon_backtrace+0x125>
			info.eip_fn_name = "<unknown>";
			info.eip_fn_namelen = 9;
			info.eip_fn_addr = eip;
			info.eip_fn_narg = 0;
			char display_eip_fn_name[30];
			debuginfo_eip(eip,&info);
f0100cb9:	8d 5d d0             	lea    -0x30(%ebp),%ebx
f0100cbc:	8b 45 9c             	mov    -0x64(%ebp),%eax
f0100cbf:	8b 55 98             	mov    -0x68(%ebp),%edx
f0100cc2:	8b 4d 94             	mov    -0x6c(%ebp),%ecx
	cprintf("Stack backtrace:\n");
	
	while(ebp != 0x00)
		{
			
			cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",ebp,eip,arg[0],arg[1],arg[2],arg[3],arg[4]);
f0100cc5:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0100cc9:	89 54 24 18          	mov    %edx,0x18(%esp)
f0100ccd:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100cd1:	8b 45 a0             	mov    -0x60(%ebp),%eax
f0100cd4:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100cd8:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100cdb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100cdf:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0100ce3:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100ce7:	c7 04 24 74 54 10 f0 	movl   $0xf0105474,(%esp)
f0100cee:	e8 c7 2a 00 00       	call   f01037ba <cprintf>
			struct Eipdebuginfo info;
			info.eip_file = "<unknown>";
f0100cf3:	c7 45 d0 16 51 10 f0 	movl   $0xf0105116,-0x30(%ebp)
			info.eip_line = 0;
f0100cfa:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
			info.eip_fn_name = "<unknown>";
f0100d01:	c7 45 d8 16 51 10 f0 	movl   $0xf0105116,-0x28(%ebp)
			info.eip_fn_namelen = 9;
f0100d08:	c7 45 dc 09 00 00 00 	movl   $0x9,-0x24(%ebp)
			info.eip_fn_addr = eip;
f0100d0f:	89 7d e0             	mov    %edi,-0x20(%ebp)
			info.eip_fn_narg = 0;
f0100d12:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
			char display_eip_fn_name[30];
			debuginfo_eip(eip,&info);
f0100d19:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100d1d:	89 3c 24             	mov    %edi,(%esp)
f0100d20:	e8 e9 2f 00 00       	call   f0103d0e <debuginfo_eip>
			int i;
			for ( i=0;(info.eip_fn_name[i]!=':')&&( i<30); i++)
f0100d25:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0100d28:	0f b6 11             	movzbl (%ecx),%edx
f0100d2b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d30:	80 fa 3a             	cmp    $0x3a,%dl
f0100d33:	74 15                	je     f0100d4a <mon_backtrace+0xd6>
				display_eip_fn_name[i]=info.eip_fn_name[i];
f0100d35:	88 54 05 b2          	mov    %dl,-0x4e(%ebp,%eax,1)
			info.eip_fn_addr = eip;
			info.eip_fn_narg = 0;
			char display_eip_fn_name[30];
			debuginfo_eip(eip,&info);
			int i;
			for ( i=0;(info.eip_fn_name[i]!=':')&&( i<30); i++)
f0100d39:	83 c0 01             	add    $0x1,%eax
f0100d3c:	0f b6 14 01          	movzbl (%ecx,%eax,1),%edx
f0100d40:	80 fa 3a             	cmp    $0x3a,%dl
f0100d43:	74 05                	je     f0100d4a <mon_backtrace+0xd6>
f0100d45:	83 f8 1d             	cmp    $0x1d,%eax
f0100d48:	7e eb                	jle    f0100d35 <mon_backtrace+0xc1>
				display_eip_fn_name[i]=info.eip_fn_name[i];
			display_eip_fn_name[i]='\0';
f0100d4a:	c6 44 05 b2 00       	movb   $0x0,-0x4e(%ebp,%eax,1)
			cprintf("    %s:%d: %s+%d\n",info.eip_file,info.eip_line,display_eip_fn_name,(eip-info.eip_fn_addr));
f0100d4f:	2b 7d e0             	sub    -0x20(%ebp),%edi
f0100d52:	89 7c 24 10          	mov    %edi,0x10(%esp)
f0100d56:	8d 45 b2             	lea    -0x4e(%ebp),%eax
f0100d59:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d5d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100d60:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d64:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100d67:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d6b:	c7 04 24 20 51 10 f0 	movl   $0xf0105120,(%esp)
f0100d72:	e8 43 2a 00 00       	call   f01037ba <cprintf>
			ebp = *(uint32_t *)ebp;
f0100d77:	8b 36                	mov    (%esi),%esi
			eip = *((uint32_t*)ebp+1);
f0100d79:	8b 7e 04             	mov    0x4(%esi),%edi
			arg[0] = *((uint32_t*)ebp+2);
f0100d7c:	8b 46 08             	mov    0x8(%esi),%eax
f0100d7f:	89 45 a4             	mov    %eax,-0x5c(%ebp)
			arg[1] = *((uint32_t*)ebp+3);
f0100d82:	8b 46 0c             	mov    0xc(%esi),%eax
f0100d85:	89 45 a0             	mov    %eax,-0x60(%ebp)
			arg[2] = *((uint32_t*)ebp+4);
f0100d88:	8b 46 10             	mov    0x10(%esi),%eax
			arg[3] = *((uint32_t*)ebp+5);
f0100d8b:	8b 56 14             	mov    0x14(%esi),%edx
			arg[4] = *((uint32_t*)ebp+6);
f0100d8e:	8b 4e 18             	mov    0x18(%esi),%ecx
	arg[3] = *((uint32_t*)ebp+5);
	arg[4] = *((uint32_t*)ebp+6);

	cprintf("Stack backtrace:\n");
	
	while(ebp != 0x00)
f0100d91:	85 f6                	test   %esi,%esi
f0100d93:	0f 85 2c ff ff ff    	jne    f0100cc5 <mon_backtrace+0x51>
			arg[3] = *((uint32_t*)ebp+5);
			arg[4] = *((uint32_t*)ebp+6);
			
		}
	return 0;
}
f0100d99:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d9e:	81 c4 8c 00 00 00    	add    $0x8c,%esp
f0100da4:	5b                   	pop    %ebx
f0100da5:	5e                   	pop    %esi
f0100da6:	5f                   	pop    %edi
f0100da7:	5d                   	pop    %ebp
f0100da8:	c3                   	ret    

f0100da9 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100da9:	55                   	push   %ebp
f0100daa:	89 e5                	mov    %esp,%ebp
f0100dac:	57                   	push   %edi
f0100dad:	56                   	push   %esi
f0100dae:	53                   	push   %ebx
f0100daf:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("\033[0;32;40mWelcome to the \033[0;36;41mJOS kernel monitor!\033[0;37;40m\n");
f0100db2:	c7 04 24 a8 54 10 f0 	movl   $0xf01054a8,(%esp)
f0100db9:	e8 fc 29 00 00       	call   f01037ba <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100dbe:	c7 04 24 ec 54 10 f0 	movl   $0xf01054ec,(%esp)
f0100dc5:	e8 f0 29 00 00       	call   f01037ba <cprintf>


	while (1) {
		buf = readline("K> ");
f0100dca:	c7 04 24 32 51 10 f0 	movl   $0xf0105132,(%esp)
f0100dd1:	e8 1a 38 00 00       	call   f01045f0 <readline>
f0100dd6:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100dd8:	85 c0                	test   %eax,%eax
f0100dda:	74 ee                	je     f0100dca <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100ddc:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100de3:	be 00 00 00 00       	mov    $0x0,%esi
f0100de8:	eb 06                	jmp    f0100df0 <monitor+0x47>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100dea:	c6 03 00             	movb   $0x0,(%ebx)
f0100ded:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100df0:	0f b6 03             	movzbl (%ebx),%eax
f0100df3:	84 c0                	test   %al,%al
f0100df5:	74 6a                	je     f0100e61 <monitor+0xb8>
f0100df7:	0f be c0             	movsbl %al,%eax
f0100dfa:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100dfe:	c7 04 24 36 51 10 f0 	movl   $0xf0105136,(%esp)
f0100e05:	e8 3c 3a 00 00       	call   f0104846 <strchr>
f0100e0a:	85 c0                	test   %eax,%eax
f0100e0c:	75 dc                	jne    f0100dea <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f0100e0e:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100e11:	74 4e                	je     f0100e61 <monitor+0xb8>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100e13:	83 fe 0f             	cmp    $0xf,%esi
f0100e16:	75 16                	jne    f0100e2e <monitor+0x85>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100e18:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100e1f:	00 
f0100e20:	c7 04 24 3b 51 10 f0 	movl   $0xf010513b,(%esp)
f0100e27:	e8 8e 29 00 00       	call   f01037ba <cprintf>
f0100e2c:	eb 9c                	jmp    f0100dca <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f0100e2e:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100e32:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f0100e35:	0f b6 03             	movzbl (%ebx),%eax
f0100e38:	84 c0                	test   %al,%al
f0100e3a:	75 0c                	jne    f0100e48 <monitor+0x9f>
f0100e3c:	eb b2                	jmp    f0100df0 <monitor+0x47>
			buf++;
f0100e3e:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100e41:	0f b6 03             	movzbl (%ebx),%eax
f0100e44:	84 c0                	test   %al,%al
f0100e46:	74 a8                	je     f0100df0 <monitor+0x47>
f0100e48:	0f be c0             	movsbl %al,%eax
f0100e4b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e4f:	c7 04 24 36 51 10 f0 	movl   $0xf0105136,(%esp)
f0100e56:	e8 eb 39 00 00       	call   f0104846 <strchr>
f0100e5b:	85 c0                	test   %eax,%eax
f0100e5d:	74 df                	je     f0100e3e <monitor+0x95>
f0100e5f:	eb 8f                	jmp    f0100df0 <monitor+0x47>
			buf++;
	}
	argv[argc] = 0;
f0100e61:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100e68:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100e69:	85 f6                	test   %esi,%esi
f0100e6b:	0f 84 59 ff ff ff    	je     f0100dca <monitor+0x21>
f0100e71:	bb 20 56 10 f0       	mov    $0xf0105620,%ebx
f0100e76:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100e7b:	8b 03                	mov    (%ebx),%eax
f0100e7d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e81:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100e84:	89 04 24             	mov    %eax,(%esp)
f0100e87:	e8 3f 39 00 00       	call   f01047cb <strcmp>
f0100e8c:	85 c0                	test   %eax,%eax
f0100e8e:	75 24                	jne    f0100eb4 <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f0100e90:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0100e93:	8b 55 08             	mov    0x8(%ebp),%edx
f0100e96:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100e9a:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100e9d:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100ea1:	89 34 24             	mov    %esi,(%esp)
f0100ea4:	ff 14 85 28 56 10 f0 	call   *-0xfefa9d8(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100eab:	85 c0                	test   %eax,%eax
f0100ead:	78 28                	js     f0100ed7 <monitor+0x12e>
f0100eaf:	e9 16 ff ff ff       	jmp    f0100dca <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100eb4:	83 c7 01             	add    $0x1,%edi
f0100eb7:	83 c3 0c             	add    $0xc,%ebx
f0100eba:	83 ff 07             	cmp    $0x7,%edi
f0100ebd:	75 bc                	jne    f0100e7b <monitor+0xd2>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100ebf:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100ec2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ec6:	c7 04 24 58 51 10 f0 	movl   $0xf0105158,(%esp)
f0100ecd:	e8 e8 28 00 00       	call   f01037ba <cprintf>
f0100ed2:	e9 f3 fe ff ff       	jmp    f0100dca <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100ed7:	83 c4 5c             	add    $0x5c,%esp
f0100eda:	5b                   	pop    %ebx
f0100edb:	5e                   	pop    %esi
f0100edc:	5f                   	pop    %edi
f0100edd:	5d                   	pop    %ebp
f0100ede:	c3                   	ret    

f0100edf <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f0100edf:	55                   	push   %ebp
f0100ee0:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f0100ee2:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f0100ee5:	5d                   	pop    %ebp
f0100ee6:	c3                   	ret    
	...

f0100ee8 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100ee8:	55                   	push   %ebp
f0100ee9:	89 e5                	mov    %esp,%ebp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100eeb:	83 3d 1c f2 17 f0 00 	cmpl   $0x0,0xf017f21c
f0100ef2:	75 11                	jne    f0100f05 <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100ef4:	ba cf 0e 18 f0       	mov    $0xf0180ecf,%edx
f0100ef9:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100eff:	89 15 1c f2 17 f0    	mov    %edx,0xf017f21c
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = ROUNDUP(nextfree, PGSIZE);
f0100f05:	8b 15 1c f2 17 f0    	mov    0xf017f21c,%edx
f0100f0b:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f0100f11:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	nextfree = result + n;
f0100f17:	01 d0                	add    %edx,%eax
f0100f19:	a3 1c f2 17 f0       	mov    %eax,0xf017f21c
	//cprintf("\nnextfree:0x%08x",nextfree);
	return result;
}
f0100f1e:	89 d0                	mov    %edx,%eax
f0100f20:	5d                   	pop    %ebp
f0100f21:	c3                   	ret    

f0100f22 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100f22:	55                   	push   %ebp
f0100f23:	89 e5                	mov    %esp,%ebp
f0100f25:	83 ec 18             	sub    $0x18,%esp
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100f28:	89 d1                	mov    %edx,%ecx
f0100f2a:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100f2d:	8b 0c 88             	mov    (%eax,%ecx,4),%ecx
		return ~0;
f0100f30:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100f35:	f6 c1 01             	test   $0x1,%cl
f0100f38:	74 57                	je     f0100f91 <check_va2pa+0x6f>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100f3a:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f40:	89 c8                	mov    %ecx,%eax
f0100f42:	c1 e8 0c             	shr    $0xc,%eax
f0100f45:	3b 05 c4 fe 17 f0    	cmp    0xf017fec4,%eax
f0100f4b:	72 20                	jb     f0100f6d <check_va2pa+0x4b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f4d:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100f51:	c7 44 24 08 dc 52 10 	movl   $0xf01052dc,0x8(%esp)
f0100f58:	f0 
f0100f59:	c7 44 24 04 2f 03 00 	movl   $0x32f,0x4(%esp)
f0100f60:	00 
f0100f61:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0100f68:	e8 51 f1 ff ff       	call   f01000be <_panic>
	if (!(p[PTX(va)] & PTE_P))
f0100f6d:	c1 ea 0c             	shr    $0xc,%edx
f0100f70:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100f76:	8b 84 91 00 00 00 f0 	mov    -0x10000000(%ecx,%edx,4),%eax
f0100f7d:	89 c2                	mov    %eax,%edx
f0100f7f:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100f82:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100f87:	85 d2                	test   %edx,%edx
f0100f89:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100f8e:	0f 44 c2             	cmove  %edx,%eax
}
f0100f91:	c9                   	leave  
f0100f92:	c3                   	ret    

f0100f93 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100f93:	55                   	push   %ebp
f0100f94:	89 e5                	mov    %esp,%ebp
f0100f96:	83 ec 18             	sub    $0x18,%esp
f0100f99:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0100f9c:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0100f9f:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100fa1:	89 04 24             	mov    %eax,(%esp)
f0100fa4:	e8 a3 27 00 00       	call   f010374c <mc146818_read>
f0100fa9:	89 c6                	mov    %eax,%esi
f0100fab:	83 c3 01             	add    $0x1,%ebx
f0100fae:	89 1c 24             	mov    %ebx,(%esp)
f0100fb1:	e8 96 27 00 00       	call   f010374c <mc146818_read>
f0100fb6:	c1 e0 08             	shl    $0x8,%eax
f0100fb9:	09 f0                	or     %esi,%eax
}
f0100fbb:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0100fbe:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0100fc1:	89 ec                	mov    %ebp,%esp
f0100fc3:	5d                   	pop    %ebp
f0100fc4:	c3                   	ret    

f0100fc5 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100fc5:	55                   	push   %ebp
f0100fc6:	89 e5                	mov    %esp,%ebp
f0100fc8:	57                   	push   %edi
f0100fc9:	56                   	push   %esi
f0100fca:	53                   	push   %ebx
f0100fcb:	83 ec 3c             	sub    $0x3c,%esp
	struct Page *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100fce:	83 f8 01             	cmp    $0x1,%eax
f0100fd1:	19 f6                	sbb    %esi,%esi
f0100fd3:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
f0100fd9:	83 c6 01             	add    $0x1,%esi
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100fdc:	8b 1d 20 f2 17 f0    	mov    0xf017f220,%ebx
f0100fe2:	85 db                	test   %ebx,%ebx
f0100fe4:	75 1c                	jne    f0101002 <check_page_free_list+0x3d>
		panic("'page_free_list' is a null pointer!");
f0100fe6:	c7 44 24 08 74 56 10 	movl   $0xf0105674,0x8(%esp)
f0100fed:	f0 
f0100fee:	c7 44 24 04 6d 02 00 	movl   $0x26d,0x4(%esp)
f0100ff5:	00 
f0100ff6:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0100ffd:	e8 bc f0 ff ff       	call   f01000be <_panic>

	if (only_low_memory) {
f0101002:	85 c0                	test   %eax,%eax
f0101004:	74 50                	je     f0101056 <check_page_free_list+0x91>
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
f0101006:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0101009:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010100c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010100f:	89 45 dc             	mov    %eax,-0x24(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101012:	89 d8                	mov    %ebx,%eax
f0101014:	2b 05 cc fe 17 f0    	sub    0xf017fecc,%eax
f010101a:	c1 e0 09             	shl    $0x9,%eax
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f010101d:	c1 e8 16             	shr    $0x16,%eax
f0101020:	39 c6                	cmp    %eax,%esi
f0101022:	0f 96 c0             	setbe  %al
f0101025:	0f b6 c0             	movzbl %al,%eax
			*tp[pagetype] = pp;
f0101028:	8b 54 85 d8          	mov    -0x28(%ebp,%eax,4),%edx
f010102c:	89 1a                	mov    %ebx,(%edx)
			tp[pagetype] = &pp->pp_link;
f010102e:	89 5c 85 d8          	mov    %ebx,-0x28(%ebp,%eax,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0101032:	8b 1b                	mov    (%ebx),%ebx
f0101034:	85 db                	test   %ebx,%ebx
f0101036:	75 da                	jne    f0101012 <check_page_free_list+0x4d>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0101038:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010103b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0101041:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101044:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101047:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0101049:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010104c:	89 1d 20 f2 17 f0    	mov    %ebx,0xf017f220
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101052:	85 db                	test   %ebx,%ebx
f0101054:	74 67                	je     f01010bd <check_page_free_list+0xf8>
f0101056:	89 d8                	mov    %ebx,%eax
f0101058:	2b 05 cc fe 17 f0    	sub    0xf017fecc,%eax
f010105e:	c1 f8 03             	sar    $0x3,%eax
f0101061:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0101064:	89 c2                	mov    %eax,%edx
f0101066:	c1 ea 16             	shr    $0x16,%edx
f0101069:	39 d6                	cmp    %edx,%esi
f010106b:	76 4a                	jbe    f01010b7 <check_page_free_list+0xf2>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010106d:	89 c2                	mov    %eax,%edx
f010106f:	c1 ea 0c             	shr    $0xc,%edx
f0101072:	3b 15 c4 fe 17 f0    	cmp    0xf017fec4,%edx
f0101078:	72 20                	jb     f010109a <check_page_free_list+0xd5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010107a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010107e:	c7 44 24 08 dc 52 10 	movl   $0xf01052dc,0x8(%esp)
f0101085:	f0 
f0101086:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f010108d:	00 
f010108e:	c7 04 24 ad 5d 10 f0 	movl   $0xf0105dad,(%esp)
f0101095:	e8 24 f0 ff ff       	call   f01000be <_panic>
			memset(page2kva(pp), 0x97, 128);
f010109a:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f01010a1:	00 
f01010a2:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f01010a9:	00 
	return (void *)(pa + KERNBASE);
f01010aa:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01010af:	89 04 24             	mov    %eax,(%esp)
f01010b2:	e8 ea 37 00 00       	call   f01048a1 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01010b7:	8b 1b                	mov    (%ebx),%ebx
f01010b9:	85 db                	test   %ebx,%ebx
f01010bb:	75 99                	jne    f0101056 <check_page_free_list+0x91>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f01010bd:	b8 00 00 00 00       	mov    $0x0,%eax
f01010c2:	e8 21 fe ff ff       	call   f0100ee8 <boot_alloc>
f01010c7:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f01010ca:	8b 15 20 f2 17 f0    	mov    0xf017f220,%edx
f01010d0:	85 d2                	test   %edx,%edx
f01010d2:	0f 84 f6 01 00 00    	je     f01012ce <check_page_free_list+0x309>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f01010d8:	8b 1d cc fe 17 f0    	mov    0xf017fecc,%ebx
f01010de:	39 da                	cmp    %ebx,%edx
f01010e0:	72 4d                	jb     f010112f <check_page_free_list+0x16a>
		assert(pp < pages + npages);
f01010e2:	a1 c4 fe 17 f0       	mov    0xf017fec4,%eax
f01010e7:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01010ea:	8d 04 c3             	lea    (%ebx,%eax,8),%eax
f01010ed:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01010f0:	39 c2                	cmp    %eax,%edx
f01010f2:	73 64                	jae    f0101158 <check_page_free_list+0x193>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f01010f4:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f01010f7:	89 d0                	mov    %edx,%eax
f01010f9:	29 d8                	sub    %ebx,%eax
f01010fb:	a8 07                	test   $0x7,%al
f01010fd:	0f 85 82 00 00 00    	jne    f0101185 <check_page_free_list+0x1c0>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101103:	c1 f8 03             	sar    $0x3,%eax
f0101106:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0101109:	85 c0                	test   %eax,%eax
f010110b:	0f 84 a2 00 00 00    	je     f01011b3 <check_page_free_list+0x1ee>
		assert(page2pa(pp) != IOPHYSMEM);
f0101111:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0101116:	0f 84 c2 00 00 00    	je     f01011de <check_page_free_list+0x219>
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f010111c:	be 00 00 00 00       	mov    $0x0,%esi
f0101121:	bf 00 00 00 00       	mov    $0x0,%edi
f0101126:	e9 d7 00 00 00       	jmp    f0101202 <check_page_free_list+0x23d>
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f010112b:	39 da                	cmp    %ebx,%edx
f010112d:	73 24                	jae    f0101153 <check_page_free_list+0x18e>
f010112f:	c7 44 24 0c bb 5d 10 	movl   $0xf0105dbb,0xc(%esp)
f0101136:	f0 
f0101137:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f010113e:	f0 
f010113f:	c7 44 24 04 87 02 00 	movl   $0x287,0x4(%esp)
f0101146:	00 
f0101147:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f010114e:	e8 6b ef ff ff       	call   f01000be <_panic>
		assert(pp < pages + npages);
f0101153:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0101156:	72 24                	jb     f010117c <check_page_free_list+0x1b7>
f0101158:	c7 44 24 0c dc 5d 10 	movl   $0xf0105ddc,0xc(%esp)
f010115f:	f0 
f0101160:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0101167:	f0 
f0101168:	c7 44 24 04 88 02 00 	movl   $0x288,0x4(%esp)
f010116f:	00 
f0101170:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0101177:	e8 42 ef ff ff       	call   f01000be <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f010117c:	89 d0                	mov    %edx,%eax
f010117e:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0101181:	a8 07                	test   $0x7,%al
f0101183:	74 24                	je     f01011a9 <check_page_free_list+0x1e4>
f0101185:	c7 44 24 0c 98 56 10 	movl   $0xf0105698,0xc(%esp)
f010118c:	f0 
f010118d:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0101194:	f0 
f0101195:	c7 44 24 04 89 02 00 	movl   $0x289,0x4(%esp)
f010119c:	00 
f010119d:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f01011a4:	e8 15 ef ff ff       	call   f01000be <_panic>
f01011a9:	c1 f8 03             	sar    $0x3,%eax
f01011ac:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f01011af:	85 c0                	test   %eax,%eax
f01011b1:	75 24                	jne    f01011d7 <check_page_free_list+0x212>
f01011b3:	c7 44 24 0c f0 5d 10 	movl   $0xf0105df0,0xc(%esp)
f01011ba:	f0 
f01011bb:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f01011c2:	f0 
f01011c3:	c7 44 24 04 8c 02 00 	movl   $0x28c,0x4(%esp)
f01011ca:	00 
f01011cb:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f01011d2:	e8 e7 ee ff ff       	call   f01000be <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f01011d7:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f01011dc:	75 24                	jne    f0101202 <check_page_free_list+0x23d>
f01011de:	c7 44 24 0c 01 5e 10 	movl   $0xf0105e01,0xc(%esp)
f01011e5:	f0 
f01011e6:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f01011ed:	f0 
f01011ee:	c7 44 24 04 8d 02 00 	movl   $0x28d,0x4(%esp)
f01011f5:	00 
f01011f6:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f01011fd:	e8 bc ee ff ff       	call   f01000be <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0101202:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0101207:	75 24                	jne    f010122d <check_page_free_list+0x268>
f0101209:	c7 44 24 0c cc 56 10 	movl   $0xf01056cc,0xc(%esp)
f0101210:	f0 
f0101211:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0101218:	f0 
f0101219:	c7 44 24 04 8e 02 00 	movl   $0x28e,0x4(%esp)
f0101220:	00 
f0101221:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0101228:	e8 91 ee ff ff       	call   f01000be <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f010122d:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0101232:	75 24                	jne    f0101258 <check_page_free_list+0x293>
f0101234:	c7 44 24 0c 1a 5e 10 	movl   $0xf0105e1a,0xc(%esp)
f010123b:	f0 
f010123c:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0101243:	f0 
f0101244:	c7 44 24 04 8f 02 00 	movl   $0x28f,0x4(%esp)
f010124b:	00 
f010124c:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0101253:	e8 66 ee ff ff       	call   f01000be <_panic>
f0101258:	89 c1                	mov    %eax,%ecx
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f010125a:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f010125f:	76 57                	jbe    f01012b8 <check_page_free_list+0x2f3>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101261:	c1 e8 0c             	shr    $0xc,%eax
f0101264:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101267:	77 20                	ja     f0101289 <check_page_free_list+0x2c4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101269:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010126d:	c7 44 24 08 dc 52 10 	movl   $0xf01052dc,0x8(%esp)
f0101274:	f0 
f0101275:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f010127c:	00 
f010127d:	c7 04 24 ad 5d 10 f0 	movl   $0xf0105dad,(%esp)
f0101284:	e8 35 ee ff ff       	call   f01000be <_panic>
	return (void *)(pa + KERNBASE);
f0101289:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f010128f:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0101292:	76 29                	jbe    f01012bd <check_page_free_list+0x2f8>
f0101294:	c7 44 24 0c f0 56 10 	movl   $0xf01056f0,0xc(%esp)
f010129b:	f0 
f010129c:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f01012a3:	f0 
f01012a4:	c7 44 24 04 90 02 00 	movl   $0x290,0x4(%esp)
f01012ab:	00 
f01012ac:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f01012b3:	e8 06 ee ff ff       	call   f01000be <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f01012b8:	83 c7 01             	add    $0x1,%edi
f01012bb:	eb 03                	jmp    f01012c0 <check_page_free_list+0x2fb>
		else
			++nfree_extmem;
f01012bd:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f01012c0:	8b 12                	mov    (%edx),%edx
f01012c2:	85 d2                	test   %edx,%edx
f01012c4:	0f 85 61 fe ff ff    	jne    f010112b <check_page_free_list+0x166>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f01012ca:	85 ff                	test   %edi,%edi
f01012cc:	7f 24                	jg     f01012f2 <check_page_free_list+0x32d>
f01012ce:	c7 44 24 0c 34 5e 10 	movl   $0xf0105e34,0xc(%esp)
f01012d5:	f0 
f01012d6:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f01012dd:	f0 
f01012de:	c7 44 24 04 98 02 00 	movl   $0x298,0x4(%esp)
f01012e5:	00 
f01012e6:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f01012ed:	e8 cc ed ff ff       	call   f01000be <_panic>
	assert(nfree_extmem > 0);
f01012f2:	85 f6                	test   %esi,%esi
f01012f4:	7f 24                	jg     f010131a <check_page_free_list+0x355>
f01012f6:	c7 44 24 0c 46 5e 10 	movl   $0xf0105e46,0xc(%esp)
f01012fd:	f0 
f01012fe:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0101305:	f0 
f0101306:	c7 44 24 04 99 02 00 	movl   $0x299,0x4(%esp)
f010130d:	00 
f010130e:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0101315:	e8 a4 ed ff ff       	call   f01000be <_panic>
}
f010131a:	83 c4 3c             	add    $0x3c,%esp
f010131d:	5b                   	pop    %ebx
f010131e:	5e                   	pop    %esi
f010131f:	5f                   	pop    %edi
f0101320:	5d                   	pop    %ebp
f0101321:	c3                   	ret    

f0101322 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0101322:	55                   	push   %ebp
f0101323:	89 e5                	mov    %esp,%ebp
f0101325:	56                   	push   %esi
f0101326:	53                   	push   %ebx
f0101327:	83 ec 10             	sub    $0x10,%esp
	// free pages!
	size_t i;
	//size_t a=0;
	//size_t b=0;
	//size_t c=0;
	page_free_list = NULL;
f010132a:	c7 05 20 f2 17 f0 00 	movl   $0x0,0xf017f220
f0101331:	00 00 00 
	physaddr_t pgnum_IOPHYSMEM = PGNUM (IOPHYSMEM);
	physaddr_t pgnum_EXTPHYSMEM =PGNUM ( PADDR (ROUNDUP(pages+npages* sizeof (struct Page),PGSIZE)));
f0101334:	a1 c4 fe 17 f0       	mov    0xf017fec4,%eax
f0101339:	89 c6                	mov    %eax,%esi
f010133b:	c1 e6 06             	shl    $0x6,%esi
f010133e:	03 35 cc fe 17 f0    	add    0xf017fecc,%esi
f0101344:	81 c6 ff 0f 00 00    	add    $0xfff,%esi
f010134a:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101350:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0101356:	77 20                	ja     f0101378 <page_init+0x56>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101358:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010135c:	c7 44 24 08 38 57 10 	movl   $0xf0105738,0x8(%esp)
f0101363:	f0 
f0101364:	c7 44 24 04 0f 01 00 	movl   $0x10f,0x4(%esp)
f010136b:	00 
f010136c:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0101373:	e8 46 ed ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101378:	81 c6 00 00 00 10    	add    $0x10000000,%esi
f010137e:	c1 ee 0c             	shr    $0xc,%esi
	//PGNUM (ROUNDUP(pages+npages* sizeof (struct Page),PGSIZE))-PGNUM(kern_pgdir)+PGNUM(EXTPHYSMEM);
	for (i = 1; i < npages; i++) 
f0101381:	83 f8 01             	cmp    $0x1,%eax
f0101384:	76 6f                	jbe    f01013f5 <page_init+0xd3>
f0101386:	ba 08 00 00 00       	mov    $0x8,%edx
f010138b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101390:	b8 01 00 00 00       	mov    $0x1,%eax
	{
		
		
		if(i<pgnum_IOPHYSMEM)
f0101395:	3d 9f 00 00 00       	cmp    $0x9f,%eax
f010139a:	77 1a                	ja     f01013b6 <page_init+0x94>
		{
			pages[i].pp_ref = 0;
f010139c:	89 d3                	mov    %edx,%ebx
f010139e:	03 1d cc fe 17 f0    	add    0xf017fecc,%ebx
f01013a4:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
			pages[i].pp_link = page_free_list;
f01013aa:	89 0b                	mov    %ecx,(%ebx)
			page_free_list = &pages[i];
f01013ac:	89 d1                	mov    %edx,%ecx
f01013ae:	03 0d cc fe 17 f0    	add    0xf017fecc,%ecx
f01013b4:	eb 2b                	jmp    f01013e1 <page_init+0xbf>
			//a++;
		}
		else if( i>pgnum_EXTPHYSMEM)
f01013b6:	39 c6                	cmp    %eax,%esi
f01013b8:	73 1a                	jae    f01013d4 <page_init+0xb2>
		{
			pages[i].pp_ref = 0;
f01013ba:	8b 1d cc fe 17 f0    	mov    0xf017fecc,%ebx
f01013c0:	66 c7 44 13 04 00 00 	movw   $0x0,0x4(%ebx,%edx,1)
			pages[i].pp_link = page_free_list;
f01013c7:	89 0c 13             	mov    %ecx,(%ebx,%edx,1)
			page_free_list = &pages[i];
f01013ca:	89 d1                	mov    %edx,%ecx
f01013cc:	03 0d cc fe 17 f0    	add    0xf017fecc,%ecx
f01013d2:	eb 0d                	jmp    f01013e1 <page_init+0xbf>
			//b++;
		}
		else
		{
			pages[i].pp_ref = 1;
f01013d4:	8b 1d cc fe 17 f0    	mov    0xf017fecc,%ebx
f01013da:	66 c7 44 13 04 01 00 	movw   $0x1,0x4(%ebx,%edx,1)
	//size_t c=0;
	page_free_list = NULL;
	physaddr_t pgnum_IOPHYSMEM = PGNUM (IOPHYSMEM);
	physaddr_t pgnum_EXTPHYSMEM =PGNUM ( PADDR (ROUNDUP(pages+npages* sizeof (struct Page),PGSIZE)));
	//PGNUM (ROUNDUP(pages+npages* sizeof (struct Page),PGSIZE))-PGNUM(kern_pgdir)+PGNUM(EXTPHYSMEM);
	for (i = 1; i < npages; i++) 
f01013e1:	83 c0 01             	add    $0x1,%eax
f01013e4:	83 c2 08             	add    $0x8,%edx
f01013e7:	39 05 c4 fe 17 f0    	cmp    %eax,0xf017fec4
f01013ed:	77 a6                	ja     f0101395 <page_init+0x73>
f01013ef:	89 0d 20 f2 17 f0    	mov    %ecx,0xf017f220
			pages[i].pp_ref = 1;
			//c++;
		}
	}
	//cprintf("\n a:%d,b:%d c:%d  ",a,b,c);
}
f01013f5:	83 c4 10             	add    $0x10,%esp
f01013f8:	5b                   	pop    %ebx
f01013f9:	5e                   	pop    %esi
f01013fa:	5d                   	pop    %ebp
f01013fb:	c3                   	ret    

f01013fc <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct Page *
page_alloc(int alloc_flags)
{
f01013fc:	55                   	push   %ebp
f01013fd:	89 e5                	mov    %esp,%ebp
f01013ff:	53                   	push   %ebx
f0101400:	83 ec 14             	sub    $0x14,%esp
f0101403:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	if ((alloc_flags==0 ||alloc_flags==ALLOC_ZERO)&& page_free_list!=NULL)
f0101406:	83 f8 01             	cmp    $0x1,%eax
f0101409:	77 71                	ja     f010147c <page_alloc+0x80>
f010140b:	8b 1d 20 f2 17 f0    	mov    0xf017f220,%ebx
f0101411:	85 db                	test   %ebx,%ebx
f0101413:	74 6c                	je     f0101481 <page_alloc+0x85>
	{
		struct Page * temp_alloc_page = page_free_list;
		if(page_free_list->pp_link!=NULL)
f0101415:	8b 13                	mov    (%ebx),%edx
			page_free_list=page_free_list->pp_link;
f0101417:	89 15 20 f2 17 f0    	mov    %edx,0xf017f220
		else 
			page_free_list=NULL;
		if(alloc_flags==ALLOC_ZERO)
f010141d:	83 f8 01             	cmp    $0x1,%eax
f0101420:	75 5f                	jne    f0101481 <page_alloc+0x85>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101422:	89 d8                	mov    %ebx,%eax
f0101424:	2b 05 cc fe 17 f0    	sub    0xf017fecc,%eax
f010142a:	c1 f8 03             	sar    $0x3,%eax
f010142d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101430:	89 c2                	mov    %eax,%edx
f0101432:	c1 ea 0c             	shr    $0xc,%edx
f0101435:	3b 15 c4 fe 17 f0    	cmp    0xf017fec4,%edx
f010143b:	72 20                	jb     f010145d <page_alloc+0x61>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010143d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101441:	c7 44 24 08 dc 52 10 	movl   $0xf01052dc,0x8(%esp)
f0101448:	f0 
f0101449:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0101450:	00 
f0101451:	c7 04 24 ad 5d 10 f0 	movl   $0xf0105dad,(%esp)
f0101458:	e8 61 ec ff ff       	call   f01000be <_panic>
			memset(page2kva(temp_alloc_page), 0, PGSIZE);
f010145d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101464:	00 
f0101465:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010146c:	00 
	return (void *)(pa + KERNBASE);
f010146d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101472:	89 04 24             	mov    %eax,(%esp)
f0101475:	e8 27 34 00 00       	call   f01048a1 <memset>
f010147a:	eb 05                	jmp    f0101481 <page_alloc+0x85>
		return temp_alloc_page;
	}
	else
		return NULL;
f010147c:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f0101481:	89 d8                	mov    %ebx,%eax
f0101483:	83 c4 14             	add    $0x14,%esp
f0101486:	5b                   	pop    %ebx
f0101487:	5d                   	pop    %ebp
f0101488:	c3                   	ret    

f0101489 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct Page *pp)
{
f0101489:	55                   	push   %ebp
f010148a:	89 e5                	mov    %esp,%ebp
f010148c:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
//	pp->pp_ref = 0;
	pp->pp_link = page_free_list;
f010148f:	8b 15 20 f2 17 f0    	mov    0xf017f220,%edx
f0101495:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0101497:	a3 20 f2 17 f0       	mov    %eax,0xf017f220
}
f010149c:	5d                   	pop    %ebp
f010149d:	c3                   	ret    

f010149e <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct Page* pp)
{
f010149e:	55                   	push   %ebp
f010149f:	89 e5                	mov    %esp,%ebp
f01014a1:	83 ec 04             	sub    $0x4,%esp
f01014a4:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f01014a7:	0f b7 50 04          	movzwl 0x4(%eax),%edx
f01014ab:	83 ea 01             	sub    $0x1,%edx
f01014ae:	66 89 50 04          	mov    %dx,0x4(%eax)
f01014b2:	66 85 d2             	test   %dx,%dx
f01014b5:	75 08                	jne    f01014bf <page_decref+0x21>
		page_free(pp);
f01014b7:	89 04 24             	mov    %eax,(%esp)
f01014ba:	e8 ca ff ff ff       	call   f0101489 <page_free>
}
f01014bf:	c9                   	leave  
f01014c0:	c3                   	ret    

f01014c1 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f01014c1:	55                   	push   %ebp
f01014c2:	89 e5                	mov    %esp,%ebp
f01014c4:	56                   	push   %esi
f01014c5:	53                   	push   %ebx
f01014c6:	83 ec 10             	sub    $0x10,%esp
f01014c9:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	pde_t *pde;//page directory entry,
	pte_t *pte;//page table entry
	pde=(pde_t *)pgdir+PDX(va);//get the entry of pde
f01014cc:	89 f3                	mov    %esi,%ebx
f01014ce:	c1 eb 16             	shr    $0x16,%ebx
f01014d1:	c1 e3 02             	shl    $0x2,%ebx
f01014d4:	03 5d 08             	add    0x8(%ebp),%ebx

	if (*pde & PTE_P)//the address exists
f01014d7:	8b 03                	mov    (%ebx),%eax
f01014d9:	a8 01                	test   $0x1,%al
f01014db:	74 44                	je     f0101521 <pgdir_walk+0x60>
	{
		pte=(pte_t *)KADDR(PTE_ADDR(*pde))+PTX(va);
f01014dd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01014e2:	89 c2                	mov    %eax,%edx
f01014e4:	c1 ea 0c             	shr    $0xc,%edx
f01014e7:	3b 15 c4 fe 17 f0    	cmp    0xf017fec4,%edx
f01014ed:	72 20                	jb     f010150f <pgdir_walk+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014ef:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01014f3:	c7 44 24 08 dc 52 10 	movl   $0xf01052dc,0x8(%esp)
f01014fa:	f0 
f01014fb:	c7 44 24 04 80 01 00 	movl   $0x180,0x4(%esp)
f0101502:	00 
f0101503:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f010150a:	e8 af eb ff ff       	call   f01000be <_panic>
f010150f:	c1 ee 0a             	shr    $0xa,%esi
f0101512:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0101518:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
		return pte;
f010151f:	eb 7d                	jmp    f010159e <pgdir_walk+0xdd>
	}
	//the page does not exist
	if (create )//create a new page table 
f0101521:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101525:	74 6b                	je     f0101592 <pgdir_walk+0xd1>
	{	
		struct Page *pp;
		pp=page_alloc(ALLOC_ZERO);
f0101527:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010152e:	e8 c9 fe ff ff       	call   f01013fc <page_alloc>
		if (pp!=NULL)
f0101533:	85 c0                	test   %eax,%eax
f0101535:	74 62                	je     f0101599 <pgdir_walk+0xd8>
		{
			pp->pp_ref=1;
f0101537:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f010153d:	2b 05 cc fe 17 f0    	sub    0xf017fecc,%eax
f0101543:	c1 f8 03             	sar    $0x3,%eax
f0101546:	c1 e0 0c             	shl    $0xc,%eax
			*pde = page2pa(pp)|PTE_U|PTE_W|PTE_P ;
f0101549:	83 c8 07             	or     $0x7,%eax
f010154c:	89 03                	mov    %eax,(%ebx)
			pte=(pte_t *)KADDR(PTE_ADDR(*pde))+PTX(va);
f010154e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101553:	89 c2                	mov    %eax,%edx
f0101555:	c1 ea 0c             	shr    $0xc,%edx
f0101558:	3b 15 c4 fe 17 f0    	cmp    0xf017fec4,%edx
f010155e:	72 20                	jb     f0101580 <pgdir_walk+0xbf>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101560:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101564:	c7 44 24 08 dc 52 10 	movl   $0xf01052dc,0x8(%esp)
f010156b:	f0 
f010156c:	c7 44 24 04 8c 01 00 	movl   $0x18c,0x4(%esp)
f0101573:	00 
f0101574:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f010157b:	e8 3e eb ff ff       	call   f01000be <_panic>
f0101580:	c1 ee 0a             	shr    $0xa,%esi
f0101583:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0101589:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
			return pte;
f0101590:	eb 0c                	jmp    f010159e <pgdir_walk+0xdd>
		}
	}
	return NULL;
f0101592:	b8 00 00 00 00       	mov    $0x0,%eax
f0101597:	eb 05                	jmp    f010159e <pgdir_walk+0xdd>
f0101599:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010159e:	83 c4 10             	add    $0x10,%esp
f01015a1:	5b                   	pop    %ebx
f01015a2:	5e                   	pop    %esi
f01015a3:	5d                   	pop    %ebp
f01015a4:	c3                   	ret    

f01015a5 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f01015a5:	55                   	push   %ebp
f01015a6:	89 e5                	mov    %esp,%ebp
f01015a8:	57                   	push   %edi
f01015a9:	56                   	push   %esi
f01015aa:	53                   	push   %ebx
f01015ab:	83 ec 2c             	sub    $0x2c,%esp
f01015ae:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01015b1:	89 d7                	mov    %edx,%edi
f01015b3:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in
	if(size%PGSIZE!=0)
f01015b6:	f7 c1 ff 0f 00 00    	test   $0xfff,%ecx
f01015bc:	74 0f                	je     f01015cd <boot_map_region+0x28>
		size=ROUNDUP(size,PGSIZE);//panic(" Size must be a multiple of PGSIZE.");
f01015be:	89 c8                	mov    %ecx,%eax
f01015c0:	05 ff 0f 00 00       	add    $0xfff,%eax
f01015c5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01015ca:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	pte_t *pte ;
	size_t i=0;
	while(i<size)
f01015cd:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01015d1:	74 34                	je     f0101607 <boot_map_region+0x62>
{
	// Fill this function in
	if(size%PGSIZE!=0)
		size=ROUNDUP(size,PGSIZE);//panic(" Size must be a multiple of PGSIZE.");
	pte_t *pte ;
	size_t i=0;
f01015d3:	bb 00 00 00 00       	mov    $0x0,%ebx
// above UTOP. As such, it should *not* change the pp_ref field on the
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f01015d8:	8b 75 08             	mov    0x8(%ebp),%esi
f01015db:	01 de                	add    %ebx,%esi
		size=ROUNDUP(size,PGSIZE);//panic(" Size must be a multiple of PGSIZE.");
	pte_t *pte ;
	size_t i=0;
	while(i<size)
	{
		pte=pgdir_walk(pgdir, (void *)va, 1);
f01015dd:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01015e4:	00 
// above UTOP. As such, it should *not* change the pp_ref field on the
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f01015e5:	8d 04 3b             	lea    (%ebx,%edi,1),%eax
		size=ROUNDUP(size,PGSIZE);//panic(" Size must be a multiple of PGSIZE.");
	pte_t *pte ;
	size_t i=0;
	while(i<size)
	{
		pte=pgdir_walk(pgdir, (void *)va, 1);
f01015e8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015ec:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01015ef:	89 04 24             	mov    %eax,(%esp)
f01015f2:	e8 ca fe ff ff       	call   f01014c1 <pgdir_walk>
		*pte= pa|perm;
f01015f7:	0b 75 0c             	or     0xc(%ebp),%esi
f01015fa:	89 30                	mov    %esi,(%eax)
		pa+=PGSIZE;
		va+=PGSIZE;
		i+=PGSIZE;
f01015fc:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// Fill this function in
	if(size%PGSIZE!=0)
		size=ROUNDUP(size,PGSIZE);//panic(" Size must be a multiple of PGSIZE.");
	pte_t *pte ;
	size_t i=0;
	while(i<size)
f0101602:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f0101605:	77 d1                	ja     f01015d8 <boot_map_region+0x33>
		*pte= pa|perm;
		pa+=PGSIZE;
		va+=PGSIZE;
		i+=PGSIZE;
	}
}
f0101607:	83 c4 2c             	add    $0x2c,%esp
f010160a:	5b                   	pop    %ebx
f010160b:	5e                   	pop    %esi
f010160c:	5f                   	pop    %edi
f010160d:	5d                   	pop    %ebp
f010160e:	c3                   	ret    

f010160f <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f010160f:	55                   	push   %ebp
f0101610:	89 e5                	mov    %esp,%ebp
f0101612:	53                   	push   %ebx
f0101613:	83 ec 14             	sub    $0x14,%esp
f0101616:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pte = pgdir_walk(pgdir,(void *)va, 0);
f0101619:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101620:	00 
f0101621:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101624:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101628:	8b 45 08             	mov    0x8(%ebp),%eax
f010162b:	89 04 24             	mov    %eax,(%esp)
f010162e:	e8 8e fe ff ff       	call   f01014c1 <pgdir_walk>
	if (pte==NULL)
f0101633:	85 c0                	test   %eax,%eax
f0101635:	74 3e                	je     f0101675 <page_lookup+0x66>
	{
		return NULL;		
	}
	if (pte_store != 0) 
f0101637:	85 db                	test   %ebx,%ebx
f0101639:	74 02                	je     f010163d <page_lookup+0x2e>
	{
		*pte_store = pte;
f010163b:	89 03                	mov    %eax,(%ebx)
	}
	if (*pte & PTE_P) 
f010163d:	8b 00                	mov    (%eax),%eax
f010163f:	a8 01                	test   $0x1,%al
f0101641:	74 39                	je     f010167c <page_lookup+0x6d>
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101643:	c1 e8 0c             	shr    $0xc,%eax
f0101646:	3b 05 c4 fe 17 f0    	cmp    0xf017fec4,%eax
f010164c:	72 1c                	jb     f010166a <page_lookup+0x5b>
		panic("pa2page called with invalid pa");
f010164e:	c7 44 24 08 5c 57 10 	movl   $0xf010575c,0x8(%esp)
f0101655:	f0 
f0101656:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f010165d:	00 
f010165e:	c7 04 24 ad 5d 10 f0 	movl   $0xf0105dad,(%esp)
f0101665:	e8 54 ea ff ff       	call   f01000be <_panic>
	return &pages[PGNUM(pa)];
f010166a:	c1 e0 03             	shl    $0x3,%eax
f010166d:	03 05 cc fe 17 f0    	add    0xf017fecc,%eax
	{
		return pa2page (PTE_ADDR (*pte));
f0101673:	eb 0c                	jmp    f0101681 <page_lookup+0x72>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t *pte = pgdir_walk(pgdir,(void *)va, 0);
	if (pte==NULL)
	{
		return NULL;		
f0101675:	b8 00 00 00 00       	mov    $0x0,%eax
f010167a:	eb 05                	jmp    f0101681 <page_lookup+0x72>
	}
	if (*pte & PTE_P) 
	{
		return pa2page (PTE_ADDR (*pte));
	}
	return NULL;
f010167c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101681:	83 c4 14             	add    $0x14,%esp
f0101684:	5b                   	pop    %ebx
f0101685:	5d                   	pop    %ebp
f0101686:	c3                   	ret    

f0101687 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0101687:	55                   	push   %ebp
f0101688:	89 e5                	mov    %esp,%ebp
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010168a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010168d:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0101690:	5d                   	pop    %ebp
f0101691:	c3                   	ret    

f0101692 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101692:	55                   	push   %ebp
f0101693:	89 e5                	mov    %esp,%ebp
f0101695:	83 ec 28             	sub    $0x28,%esp
f0101698:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f010169b:	89 75 fc             	mov    %esi,-0x4(%ebp)
f010169e:	8b 75 08             	mov    0x8(%ebp),%esi
f01016a1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *pte;
	struct Page *pp;
    	pp=page_lookup (pgdir, va, &pte);
f01016a4:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01016a7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01016ab:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01016af:	89 34 24             	mov    %esi,(%esp)
f01016b2:	e8 58 ff ff ff       	call   f010160f <page_lookup>
	if (pp != NULL) 
f01016b7:	85 c0                	test   %eax,%eax
f01016b9:	74 21                	je     f01016dc <page_remove+0x4a>
	{
		page_decref (pp);//- The ref count on the physical page should decrement.
f01016bb:	89 04 24             	mov    %eax,(%esp)
f01016be:	e8 db fd ff ff       	call   f010149e <page_decref>
//   - The physical page should be freed if the refcount reaches 0.
		if(pte!=NULL)
f01016c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01016c6:	85 c0                	test   %eax,%eax
f01016c8:	74 06                	je     f01016d0 <page_remove+0x3e>
			*pte = 0;// The pg table entry corresponding to 'va' should be set to 0. (if such a PTE exists)
f01016ca:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		tlb_invalidate (pgdir, va);//The TLB must be invalidated if you remove an entry from  the page table.
f01016d0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01016d4:	89 34 24             	mov    %esi,(%esp)
f01016d7:	e8 ab ff ff ff       	call   f0101687 <tlb_invalidate>
	}
}
f01016dc:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f01016df:	8b 75 fc             	mov    -0x4(%ebp),%esi
f01016e2:	89 ec                	mov    %ebp,%esp
f01016e4:	5d                   	pop    %ebp
f01016e5:	c3                   	ret    

f01016e6 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{
f01016e6:	55                   	push   %ebp
f01016e7:	89 e5                	mov    %esp,%ebp
f01016e9:	83 ec 28             	sub    $0x28,%esp
f01016ec:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f01016ef:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01016f2:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01016f5:	8b 75 0c             	mov    0xc(%ebp),%esi
f01016f8:	8b 7d 10             	mov    0x10(%ebp),%edi

	pte_t * pte = pgdir_walk(pgdir, (void *)va, 1) ;
f01016fb:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101702:	00 
f0101703:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101707:	8b 45 08             	mov    0x8(%ebp),%eax
f010170a:	89 04 24             	mov    %eax,(%esp)
f010170d:	e8 af fd ff ff       	call   f01014c1 <pgdir_walk>
f0101712:	89 c3                	mov    %eax,%ebx
//   - If necessary, on demand, a page table should be allocated and inserted
//     into 'pgdir'.
	if (pte==NULL)
f0101714:	85 c0                	test   %eax,%eax
f0101716:	74 66                	je     f010177e <page_insert+0x98>
		return -E_NO_MEM;
//-E_NO_MEM, if page table couldn't be allocated
	if (*pte & PTE_P) {
f0101718:	8b 00                	mov    (%eax),%eax
f010171a:	a8 01                	test   $0x1,%al
f010171c:	74 3c                	je     f010175a <page_insert+0x74>
		if (PTE_ADDR(*pte) == page2pa(pp))
f010171e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101723:	89 f2                	mov    %esi,%edx
f0101725:	2b 15 cc fe 17 f0    	sub    0xf017fecc,%edx
f010172b:	c1 fa 03             	sar    $0x3,%edx
f010172e:	c1 e2 0c             	shl    $0xc,%edx
f0101731:	39 d0                	cmp    %edx,%eax
f0101733:	75 16                	jne    f010174b <page_insert+0x65>
		{	
			pp->pp_ref--;
f0101735:	66 83 6e 04 01       	subw   $0x1,0x4(%esi)
			tlb_invalidate(pgdir, va);
f010173a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010173e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101741:	89 04 24             	mov    %eax,(%esp)
f0101744:	e8 3e ff ff ff       	call   f0101687 <tlb_invalidate>
f0101749:	eb 0f                	jmp    f010175a <page_insert+0x74>
//The TLB must be invalidated if a page was formerly present at 'va'.
		} 
		else 
		{
			page_remove (pgdir, va);
f010174b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010174f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101752:	89 04 24             	mov    %eax,(%esp)
f0101755:	e8 38 ff ff ff       	call   f0101692 <page_remove>
//If there is already a page mapped at 'va', it should be page_remove()d.
		}
	}

	*pte = page2pa(pp)|perm|PTE_P;
f010175a:	8b 45 14             	mov    0x14(%ebp),%eax
f010175d:	83 c8 01             	or     $0x1,%eax
f0101760:	89 f2                	mov    %esi,%edx
f0101762:	2b 15 cc fe 17 f0    	sub    0xf017fecc,%edx
f0101768:	c1 fa 03             	sar    $0x3,%edx
f010176b:	c1 e2 0c             	shl    $0xc,%edx
f010176e:	09 d0                	or     %edx,%eax
f0101770:	89 03                	mov    %eax,(%ebx)
	pp->pp_ref++;
f0101772:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
//pp->pp_ref should be incremented if the insertion succeeds.
	return 0;
f0101777:	b8 00 00 00 00       	mov    $0x0,%eax
f010177c:	eb 05                	jmp    f0101783 <page_insert+0x9d>

	pte_t * pte = pgdir_walk(pgdir, (void *)va, 1) ;
//   - If necessary, on demand, a page table should be allocated and inserted
//     into 'pgdir'.
	if (pte==NULL)
		return -E_NO_MEM;
f010177e:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	*pte = page2pa(pp)|perm|PTE_P;
	pp->pp_ref++;
//pp->pp_ref should be incremented if the insertion succeeds.
	return 0;
//0 on success
}
f0101783:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0101786:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0101789:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010178c:	89 ec                	mov    %ebp,%esp
f010178e:	5d                   	pop    %ebp
f010178f:	c3                   	ret    

f0101790 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101790:	55                   	push   %ebp
f0101791:	89 e5                	mov    %esp,%ebp
f0101793:	57                   	push   %edi
f0101794:	56                   	push   %esi
f0101795:	53                   	push   %ebx
f0101796:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101799:	b8 15 00 00 00       	mov    $0x15,%eax
f010179e:	e8 f0 f7 ff ff       	call   f0100f93 <nvram_read>
f01017a3:	c1 e0 0a             	shl    $0xa,%eax
f01017a6:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01017ac:	85 c0                	test   %eax,%eax
f01017ae:	0f 48 c2             	cmovs  %edx,%eax
f01017b1:	c1 f8 0c             	sar    $0xc,%eax
f01017b4:	a3 18 f2 17 f0       	mov    %eax,0xf017f218
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01017b9:	b8 17 00 00 00       	mov    $0x17,%eax
f01017be:	e8 d0 f7 ff ff       	call   f0100f93 <nvram_read>
f01017c3:	c1 e0 0a             	shl    $0xa,%eax
f01017c6:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01017cc:	85 c0                	test   %eax,%eax
f01017ce:	0f 48 c2             	cmovs  %edx,%eax
f01017d1:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01017d4:	85 c0                	test   %eax,%eax
f01017d6:	74 0e                	je     f01017e6 <mem_init+0x56>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01017d8:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f01017de:	89 15 c4 fe 17 f0    	mov    %edx,0xf017fec4
f01017e4:	eb 0c                	jmp    f01017f2 <mem_init+0x62>
	else
		npages = npages_basemem;
f01017e6:	8b 15 18 f2 17 f0    	mov    0xf017f218,%edx
f01017ec:	89 15 c4 fe 17 f0    	mov    %edx,0xf017fec4

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f01017f2:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01017f5:	c1 e8 0a             	shr    $0xa,%eax
f01017f8:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f01017fc:	a1 18 f2 17 f0       	mov    0xf017f218,%eax
f0101801:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101804:	c1 e8 0a             	shr    $0xa,%eax
f0101807:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f010180b:	a1 c4 fe 17 f0       	mov    0xf017fec4,%eax
f0101810:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101813:	c1 e8 0a             	shr    $0xa,%eax
f0101816:	89 44 24 04          	mov    %eax,0x4(%esp)
f010181a:	c7 04 24 7c 57 10 f0 	movl   $0xf010577c,(%esp)
f0101821:	e8 94 1f 00 00       	call   f01037ba <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101826:	b8 00 10 00 00       	mov    $0x1000,%eax
f010182b:	e8 b8 f6 ff ff       	call   f0100ee8 <boot_alloc>
f0101830:	a3 c8 fe 17 f0       	mov    %eax,0xf017fec8
	memset(kern_pgdir, 0, PGSIZE);
f0101835:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010183c:	00 
f010183d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101844:	00 
f0101845:	89 04 24             	mov    %eax,(%esp)
f0101848:	e8 54 30 00 00       	call   f01048a1 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following two lines.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010184d:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101852:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101857:	77 20                	ja     f0101879 <mem_init+0xe9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101859:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010185d:	c7 44 24 08 38 57 10 	movl   $0xf0105738,0x8(%esp)
f0101864:	f0 
f0101865:	c7 44 24 04 8c 00 00 	movl   $0x8c,0x4(%esp)
f010186c:	00 
f010186d:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0101874:	e8 45 e8 ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101879:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010187f:	83 ca 05             	or     $0x5,%edx
f0101882:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct Page in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:

	pages =(struct Page *) boot_alloc(npages* sizeof (struct Page));
f0101888:	a1 c4 fe 17 f0       	mov    0xf017fec4,%eax
f010188d:	c1 e0 03             	shl    $0x3,%eax
f0101890:	e8 53 f6 ff ff       	call   f0100ee8 <boot_alloc>
f0101895:	a3 cc fe 17 f0       	mov    %eax,0xf017fecc
	memset(pages, 0, npages* sizeof (struct Page));
f010189a:	8b 15 c4 fe 17 f0    	mov    0xf017fec4,%edx
f01018a0:	c1 e2 03             	shl    $0x3,%edx
f01018a3:	89 54 24 08          	mov    %edx,0x8(%esp)
f01018a7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01018ae:	00 
f01018af:	89 04 24             	mov    %eax,(%esp)
f01018b2:	e8 ea 2f 00 00       	call   f01048a1 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01018b7:	e8 66 fa ff ff       	call   f0101322 <page_init>
	check_page_free_list(1);
f01018bc:	b8 01 00 00 00       	mov    $0x1,%eax
f01018c1:	e8 ff f6 ff ff       	call   f0100fc5 <check_page_free_list>
	int nfree;
	struct Page *fl;
	char *c;
	int i;

	if (!pages)
f01018c6:	83 3d cc fe 17 f0 00 	cmpl   $0x0,0xf017fecc
f01018cd:	75 1c                	jne    f01018eb <mem_init+0x15b>
		panic("'pages' is a null pointer!");
f01018cf:	c7 44 24 08 57 5e 10 	movl   $0xf0105e57,0x8(%esp)
f01018d6:	f0 
f01018d7:	c7 44 24 04 aa 02 00 	movl   $0x2aa,0x4(%esp)
f01018de:	00 
f01018df:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f01018e6:	e8 d3 e7 ff ff       	call   f01000be <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01018eb:	a1 20 f2 17 f0       	mov    0xf017f220,%eax
f01018f0:	bb 00 00 00 00       	mov    $0x0,%ebx
f01018f5:	85 c0                	test   %eax,%eax
f01018f7:	74 09                	je     f0101902 <mem_init+0x172>
		++nfree;
f01018f9:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01018fc:	8b 00                	mov    (%eax),%eax
f01018fe:	85 c0                	test   %eax,%eax
f0101900:	75 f7                	jne    f01018f9 <mem_init+0x169>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101902:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101909:	e8 ee fa ff ff       	call   f01013fc <page_alloc>
f010190e:	89 c6                	mov    %eax,%esi
f0101910:	85 c0                	test   %eax,%eax
f0101912:	75 24                	jne    f0101938 <mem_init+0x1a8>
f0101914:	c7 44 24 0c 72 5e 10 	movl   $0xf0105e72,0xc(%esp)
f010191b:	f0 
f010191c:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0101923:	f0 
f0101924:	c7 44 24 04 b2 02 00 	movl   $0x2b2,0x4(%esp)
f010192b:	00 
f010192c:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0101933:	e8 86 e7 ff ff       	call   f01000be <_panic>
	assert((pp1 = page_alloc(0)));
f0101938:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010193f:	e8 b8 fa ff ff       	call   f01013fc <page_alloc>
f0101944:	89 c7                	mov    %eax,%edi
f0101946:	85 c0                	test   %eax,%eax
f0101948:	75 24                	jne    f010196e <mem_init+0x1de>
f010194a:	c7 44 24 0c 88 5e 10 	movl   $0xf0105e88,0xc(%esp)
f0101951:	f0 
f0101952:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0101959:	f0 
f010195a:	c7 44 24 04 b3 02 00 	movl   $0x2b3,0x4(%esp)
f0101961:	00 
f0101962:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0101969:	e8 50 e7 ff ff       	call   f01000be <_panic>
	assert((pp2 = page_alloc(0)));
f010196e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101975:	e8 82 fa ff ff       	call   f01013fc <page_alloc>
f010197a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010197d:	85 c0                	test   %eax,%eax
f010197f:	75 24                	jne    f01019a5 <mem_init+0x215>
f0101981:	c7 44 24 0c 9e 5e 10 	movl   $0xf0105e9e,0xc(%esp)
f0101988:	f0 
f0101989:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0101990:	f0 
f0101991:	c7 44 24 04 b4 02 00 	movl   $0x2b4,0x4(%esp)
f0101998:	00 
f0101999:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f01019a0:	e8 19 e7 ff ff       	call   f01000be <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01019a5:	39 fe                	cmp    %edi,%esi
f01019a7:	75 24                	jne    f01019cd <mem_init+0x23d>
f01019a9:	c7 44 24 0c b4 5e 10 	movl   $0xf0105eb4,0xc(%esp)
f01019b0:	f0 
f01019b1:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f01019b8:	f0 
f01019b9:	c7 44 24 04 b7 02 00 	movl   $0x2b7,0x4(%esp)
f01019c0:	00 
f01019c1:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f01019c8:	e8 f1 e6 ff ff       	call   f01000be <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01019cd:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f01019d0:	74 05                	je     f01019d7 <mem_init+0x247>
f01019d2:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f01019d5:	75 24                	jne    f01019fb <mem_init+0x26b>
f01019d7:	c7 44 24 0c b8 57 10 	movl   $0xf01057b8,0xc(%esp)
f01019de:	f0 
f01019df:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f01019e6:	f0 
f01019e7:	c7 44 24 04 b8 02 00 	movl   $0x2b8,0x4(%esp)
f01019ee:	00 
f01019ef:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f01019f6:	e8 c3 e6 ff ff       	call   f01000be <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01019fb:	8b 15 cc fe 17 f0    	mov    0xf017fecc,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101a01:	a1 c4 fe 17 f0       	mov    0xf017fec4,%eax
f0101a06:	c1 e0 0c             	shl    $0xc,%eax
f0101a09:	89 f1                	mov    %esi,%ecx
f0101a0b:	29 d1                	sub    %edx,%ecx
f0101a0d:	c1 f9 03             	sar    $0x3,%ecx
f0101a10:	c1 e1 0c             	shl    $0xc,%ecx
f0101a13:	39 c1                	cmp    %eax,%ecx
f0101a15:	72 24                	jb     f0101a3b <mem_init+0x2ab>
f0101a17:	c7 44 24 0c c6 5e 10 	movl   $0xf0105ec6,0xc(%esp)
f0101a1e:	f0 
f0101a1f:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0101a26:	f0 
f0101a27:	c7 44 24 04 b9 02 00 	movl   $0x2b9,0x4(%esp)
f0101a2e:	00 
f0101a2f:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0101a36:	e8 83 e6 ff ff       	call   f01000be <_panic>
f0101a3b:	89 f9                	mov    %edi,%ecx
f0101a3d:	29 d1                	sub    %edx,%ecx
f0101a3f:	c1 f9 03             	sar    $0x3,%ecx
f0101a42:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101a45:	39 c8                	cmp    %ecx,%eax
f0101a47:	77 24                	ja     f0101a6d <mem_init+0x2dd>
f0101a49:	c7 44 24 0c e3 5e 10 	movl   $0xf0105ee3,0xc(%esp)
f0101a50:	f0 
f0101a51:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0101a58:	f0 
f0101a59:	c7 44 24 04 ba 02 00 	movl   $0x2ba,0x4(%esp)
f0101a60:	00 
f0101a61:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0101a68:	e8 51 e6 ff ff       	call   f01000be <_panic>
f0101a6d:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101a70:	29 d1                	sub    %edx,%ecx
f0101a72:	89 ca                	mov    %ecx,%edx
f0101a74:	c1 fa 03             	sar    $0x3,%edx
f0101a77:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f0101a7a:	39 d0                	cmp    %edx,%eax
f0101a7c:	77 24                	ja     f0101aa2 <mem_init+0x312>
f0101a7e:	c7 44 24 0c 00 5f 10 	movl   $0xf0105f00,0xc(%esp)
f0101a85:	f0 
f0101a86:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0101a8d:	f0 
f0101a8e:	c7 44 24 04 bb 02 00 	movl   $0x2bb,0x4(%esp)
f0101a95:	00 
f0101a96:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0101a9d:	e8 1c e6 ff ff       	call   f01000be <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101aa2:	a1 20 f2 17 f0       	mov    0xf017f220,%eax
f0101aa7:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101aaa:	c7 05 20 f2 17 f0 00 	movl   $0x0,0xf017f220
f0101ab1:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101ab4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101abb:	e8 3c f9 ff ff       	call   f01013fc <page_alloc>
f0101ac0:	85 c0                	test   %eax,%eax
f0101ac2:	74 24                	je     f0101ae8 <mem_init+0x358>
f0101ac4:	c7 44 24 0c 1d 5f 10 	movl   $0xf0105f1d,0xc(%esp)
f0101acb:	f0 
f0101acc:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0101ad3:	f0 
f0101ad4:	c7 44 24 04 c2 02 00 	movl   $0x2c2,0x4(%esp)
f0101adb:	00 
f0101adc:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0101ae3:	e8 d6 e5 ff ff       	call   f01000be <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101ae8:	89 34 24             	mov    %esi,(%esp)
f0101aeb:	e8 99 f9 ff ff       	call   f0101489 <page_free>
	page_free(pp1);
f0101af0:	89 3c 24             	mov    %edi,(%esp)
f0101af3:	e8 91 f9 ff ff       	call   f0101489 <page_free>
	page_free(pp2);
f0101af8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101afb:	89 04 24             	mov    %eax,(%esp)
f0101afe:	e8 86 f9 ff ff       	call   f0101489 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101b03:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b0a:	e8 ed f8 ff ff       	call   f01013fc <page_alloc>
f0101b0f:	89 c6                	mov    %eax,%esi
f0101b11:	85 c0                	test   %eax,%eax
f0101b13:	75 24                	jne    f0101b39 <mem_init+0x3a9>
f0101b15:	c7 44 24 0c 72 5e 10 	movl   $0xf0105e72,0xc(%esp)
f0101b1c:	f0 
f0101b1d:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0101b24:	f0 
f0101b25:	c7 44 24 04 c9 02 00 	movl   $0x2c9,0x4(%esp)
f0101b2c:	00 
f0101b2d:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0101b34:	e8 85 e5 ff ff       	call   f01000be <_panic>
	assert((pp1 = page_alloc(0)));
f0101b39:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b40:	e8 b7 f8 ff ff       	call   f01013fc <page_alloc>
f0101b45:	89 c7                	mov    %eax,%edi
f0101b47:	85 c0                	test   %eax,%eax
f0101b49:	75 24                	jne    f0101b6f <mem_init+0x3df>
f0101b4b:	c7 44 24 0c 88 5e 10 	movl   $0xf0105e88,0xc(%esp)
f0101b52:	f0 
f0101b53:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0101b5a:	f0 
f0101b5b:	c7 44 24 04 ca 02 00 	movl   $0x2ca,0x4(%esp)
f0101b62:	00 
f0101b63:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0101b6a:	e8 4f e5 ff ff       	call   f01000be <_panic>
	assert((pp2 = page_alloc(0)));
f0101b6f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b76:	e8 81 f8 ff ff       	call   f01013fc <page_alloc>
f0101b7b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101b7e:	85 c0                	test   %eax,%eax
f0101b80:	75 24                	jne    f0101ba6 <mem_init+0x416>
f0101b82:	c7 44 24 0c 9e 5e 10 	movl   $0xf0105e9e,0xc(%esp)
f0101b89:	f0 
f0101b8a:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0101b91:	f0 
f0101b92:	c7 44 24 04 cb 02 00 	movl   $0x2cb,0x4(%esp)
f0101b99:	00 
f0101b9a:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0101ba1:	e8 18 e5 ff ff       	call   f01000be <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101ba6:	39 fe                	cmp    %edi,%esi
f0101ba8:	75 24                	jne    f0101bce <mem_init+0x43e>
f0101baa:	c7 44 24 0c b4 5e 10 	movl   $0xf0105eb4,0xc(%esp)
f0101bb1:	f0 
f0101bb2:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0101bb9:	f0 
f0101bba:	c7 44 24 04 cd 02 00 	movl   $0x2cd,0x4(%esp)
f0101bc1:	00 
f0101bc2:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0101bc9:	e8 f0 e4 ff ff       	call   f01000be <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101bce:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101bd1:	74 05                	je     f0101bd8 <mem_init+0x448>
f0101bd3:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101bd6:	75 24                	jne    f0101bfc <mem_init+0x46c>
f0101bd8:	c7 44 24 0c b8 57 10 	movl   $0xf01057b8,0xc(%esp)
f0101bdf:	f0 
f0101be0:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0101be7:	f0 
f0101be8:	c7 44 24 04 ce 02 00 	movl   $0x2ce,0x4(%esp)
f0101bef:	00 
f0101bf0:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0101bf7:	e8 c2 e4 ff ff       	call   f01000be <_panic>
	assert(!page_alloc(0));
f0101bfc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c03:	e8 f4 f7 ff ff       	call   f01013fc <page_alloc>
f0101c08:	85 c0                	test   %eax,%eax
f0101c0a:	74 24                	je     f0101c30 <mem_init+0x4a0>
f0101c0c:	c7 44 24 0c 1d 5f 10 	movl   $0xf0105f1d,0xc(%esp)
f0101c13:	f0 
f0101c14:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0101c1b:	f0 
f0101c1c:	c7 44 24 04 cf 02 00 	movl   $0x2cf,0x4(%esp)
f0101c23:	00 
f0101c24:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0101c2b:	e8 8e e4 ff ff       	call   f01000be <_panic>
f0101c30:	89 f0                	mov    %esi,%eax
f0101c32:	2b 05 cc fe 17 f0    	sub    0xf017fecc,%eax
f0101c38:	c1 f8 03             	sar    $0x3,%eax
f0101c3b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101c3e:	89 c2                	mov    %eax,%edx
f0101c40:	c1 ea 0c             	shr    $0xc,%edx
f0101c43:	3b 15 c4 fe 17 f0    	cmp    0xf017fec4,%edx
f0101c49:	72 20                	jb     f0101c6b <mem_init+0x4db>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101c4b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101c4f:	c7 44 24 08 dc 52 10 	movl   $0xf01052dc,0x8(%esp)
f0101c56:	f0 
f0101c57:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0101c5e:	00 
f0101c5f:	c7 04 24 ad 5d 10 f0 	movl   $0xf0105dad,(%esp)
f0101c66:	e8 53 e4 ff ff       	call   f01000be <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101c6b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101c72:	00 
f0101c73:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101c7a:	00 
	return (void *)(pa + KERNBASE);
f0101c7b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101c80:	89 04 24             	mov    %eax,(%esp)
f0101c83:	e8 19 2c 00 00       	call   f01048a1 <memset>
	page_free(pp0);
f0101c88:	89 34 24             	mov    %esi,(%esp)
f0101c8b:	e8 f9 f7 ff ff       	call   f0101489 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101c90:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101c97:	e8 60 f7 ff ff       	call   f01013fc <page_alloc>
f0101c9c:	85 c0                	test   %eax,%eax
f0101c9e:	75 24                	jne    f0101cc4 <mem_init+0x534>
f0101ca0:	c7 44 24 0c 2c 5f 10 	movl   $0xf0105f2c,0xc(%esp)
f0101ca7:	f0 
f0101ca8:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0101caf:	f0 
f0101cb0:	c7 44 24 04 d4 02 00 	movl   $0x2d4,0x4(%esp)
f0101cb7:	00 
f0101cb8:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0101cbf:	e8 fa e3 ff ff       	call   f01000be <_panic>
	assert(pp && pp0 == pp);
f0101cc4:	39 c6                	cmp    %eax,%esi
f0101cc6:	74 24                	je     f0101cec <mem_init+0x55c>
f0101cc8:	c7 44 24 0c 4a 5f 10 	movl   $0xf0105f4a,0xc(%esp)
f0101ccf:	f0 
f0101cd0:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0101cd7:	f0 
f0101cd8:	c7 44 24 04 d5 02 00 	movl   $0x2d5,0x4(%esp)
f0101cdf:	00 
f0101ce0:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0101ce7:	e8 d2 e3 ff ff       	call   f01000be <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101cec:	89 f2                	mov    %esi,%edx
f0101cee:	2b 15 cc fe 17 f0    	sub    0xf017fecc,%edx
f0101cf4:	c1 fa 03             	sar    $0x3,%edx
f0101cf7:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101cfa:	89 d0                	mov    %edx,%eax
f0101cfc:	c1 e8 0c             	shr    $0xc,%eax
f0101cff:	3b 05 c4 fe 17 f0    	cmp    0xf017fec4,%eax
f0101d05:	72 20                	jb     f0101d27 <mem_init+0x597>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101d07:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101d0b:	c7 44 24 08 dc 52 10 	movl   $0xf01052dc,0x8(%esp)
f0101d12:	f0 
f0101d13:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0101d1a:	00 
f0101d1b:	c7 04 24 ad 5d 10 f0 	movl   $0xf0105dad,(%esp)
f0101d22:	e8 97 e3 ff ff       	call   f01000be <_panic>
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101d27:	80 ba 00 00 00 f0 00 	cmpb   $0x0,-0x10000000(%edx)
f0101d2e:	75 11                	jne    f0101d41 <mem_init+0x5b1>
f0101d30:	8d 82 01 00 00 f0    	lea    -0xfffffff(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0101d36:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101d3c:	80 38 00             	cmpb   $0x0,(%eax)
f0101d3f:	74 24                	je     f0101d65 <mem_init+0x5d5>
f0101d41:	c7 44 24 0c 5a 5f 10 	movl   $0xf0105f5a,0xc(%esp)
f0101d48:	f0 
f0101d49:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0101d50:	f0 
f0101d51:	c7 44 24 04 d8 02 00 	movl   $0x2d8,0x4(%esp)
f0101d58:	00 
f0101d59:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0101d60:	e8 59 e3 ff ff       	call   f01000be <_panic>
f0101d65:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101d68:	39 d0                	cmp    %edx,%eax
f0101d6a:	75 d0                	jne    f0101d3c <mem_init+0x5ac>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101d6c:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101d6f:	89 15 20 f2 17 f0    	mov    %edx,0xf017f220

	// free the pages we took
	page_free(pp0);
f0101d75:	89 34 24             	mov    %esi,(%esp)
f0101d78:	e8 0c f7 ff ff       	call   f0101489 <page_free>
	page_free(pp1);
f0101d7d:	89 3c 24             	mov    %edi,(%esp)
f0101d80:	e8 04 f7 ff ff       	call   f0101489 <page_free>
	page_free(pp2);
f0101d85:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d88:	89 04 24             	mov    %eax,(%esp)
f0101d8b:	e8 f9 f6 ff ff       	call   f0101489 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101d90:	a1 20 f2 17 f0       	mov    0xf017f220,%eax
f0101d95:	85 c0                	test   %eax,%eax
f0101d97:	74 09                	je     f0101da2 <mem_init+0x612>
		--nfree;
f0101d99:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101d9c:	8b 00                	mov    (%eax),%eax
f0101d9e:	85 c0                	test   %eax,%eax
f0101da0:	75 f7                	jne    f0101d99 <mem_init+0x609>
		--nfree;
	assert(nfree == 0);
f0101da2:	85 db                	test   %ebx,%ebx
f0101da4:	74 24                	je     f0101dca <mem_init+0x63a>
f0101da6:	c7 44 24 0c 64 5f 10 	movl   $0xf0105f64,0xc(%esp)
f0101dad:	f0 
f0101dae:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0101db5:	f0 
f0101db6:	c7 44 24 04 e5 02 00 	movl   $0x2e5,0x4(%esp)
f0101dbd:	00 
f0101dbe:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0101dc5:	e8 f4 e2 ff ff       	call   f01000be <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101dca:	c7 04 24 d8 57 10 f0 	movl   $0xf01057d8,(%esp)
f0101dd1:	e8 e4 19 00 00       	call   f01037ba <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101dd6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ddd:	e8 1a f6 ff ff       	call   f01013fc <page_alloc>
f0101de2:	89 c3                	mov    %eax,%ebx
f0101de4:	85 c0                	test   %eax,%eax
f0101de6:	75 24                	jne    f0101e0c <mem_init+0x67c>
f0101de8:	c7 44 24 0c 72 5e 10 	movl   $0xf0105e72,0xc(%esp)
f0101def:	f0 
f0101df0:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0101df7:	f0 
f0101df8:	c7 44 24 04 43 03 00 	movl   $0x343,0x4(%esp)
f0101dff:	00 
f0101e00:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0101e07:	e8 b2 e2 ff ff       	call   f01000be <_panic>
	assert((pp1 = page_alloc(0)));
f0101e0c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101e13:	e8 e4 f5 ff ff       	call   f01013fc <page_alloc>
f0101e18:	89 c7                	mov    %eax,%edi
f0101e1a:	85 c0                	test   %eax,%eax
f0101e1c:	75 24                	jne    f0101e42 <mem_init+0x6b2>
f0101e1e:	c7 44 24 0c 88 5e 10 	movl   $0xf0105e88,0xc(%esp)
f0101e25:	f0 
f0101e26:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0101e2d:	f0 
f0101e2e:	c7 44 24 04 44 03 00 	movl   $0x344,0x4(%esp)
f0101e35:	00 
f0101e36:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0101e3d:	e8 7c e2 ff ff       	call   f01000be <_panic>
	assert((pp2 = page_alloc(0)));
f0101e42:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101e49:	e8 ae f5 ff ff       	call   f01013fc <page_alloc>
f0101e4e:	89 c6                	mov    %eax,%esi
f0101e50:	85 c0                	test   %eax,%eax
f0101e52:	75 24                	jne    f0101e78 <mem_init+0x6e8>
f0101e54:	c7 44 24 0c 9e 5e 10 	movl   $0xf0105e9e,0xc(%esp)
f0101e5b:	f0 
f0101e5c:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0101e63:	f0 
f0101e64:	c7 44 24 04 45 03 00 	movl   $0x345,0x4(%esp)
f0101e6b:	00 
f0101e6c:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0101e73:	e8 46 e2 ff ff       	call   f01000be <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101e78:	39 fb                	cmp    %edi,%ebx
f0101e7a:	75 24                	jne    f0101ea0 <mem_init+0x710>
f0101e7c:	c7 44 24 0c b4 5e 10 	movl   $0xf0105eb4,0xc(%esp)
f0101e83:	f0 
f0101e84:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0101e8b:	f0 
f0101e8c:	c7 44 24 04 48 03 00 	movl   $0x348,0x4(%esp)
f0101e93:	00 
f0101e94:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0101e9b:	e8 1e e2 ff ff       	call   f01000be <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101ea0:	39 c7                	cmp    %eax,%edi
f0101ea2:	74 04                	je     f0101ea8 <mem_init+0x718>
f0101ea4:	39 c3                	cmp    %eax,%ebx
f0101ea6:	75 24                	jne    f0101ecc <mem_init+0x73c>
f0101ea8:	c7 44 24 0c b8 57 10 	movl   $0xf01057b8,0xc(%esp)
f0101eaf:	f0 
f0101eb0:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0101eb7:	f0 
f0101eb8:	c7 44 24 04 49 03 00 	movl   $0x349,0x4(%esp)
f0101ebf:	00 
f0101ec0:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0101ec7:	e8 f2 e1 ff ff       	call   f01000be <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101ecc:	8b 15 20 f2 17 f0    	mov    0xf017f220,%edx
f0101ed2:	89 55 cc             	mov    %edx,-0x34(%ebp)
	page_free_list = 0;
f0101ed5:	c7 05 20 f2 17 f0 00 	movl   $0x0,0xf017f220
f0101edc:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101edf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ee6:	e8 11 f5 ff ff       	call   f01013fc <page_alloc>
f0101eeb:	85 c0                	test   %eax,%eax
f0101eed:	74 24                	je     f0101f13 <mem_init+0x783>
f0101eef:	c7 44 24 0c 1d 5f 10 	movl   $0xf0105f1d,0xc(%esp)
f0101ef6:	f0 
f0101ef7:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0101efe:	f0 
f0101eff:	c7 44 24 04 50 03 00 	movl   $0x350,0x4(%esp)
f0101f06:	00 
f0101f07:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0101f0e:	e8 ab e1 ff ff       	call   f01000be <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101f13:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101f16:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101f1a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101f21:	00 
f0101f22:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f0101f27:	89 04 24             	mov    %eax,(%esp)
f0101f2a:	e8 e0 f6 ff ff       	call   f010160f <page_lookup>
f0101f2f:	85 c0                	test   %eax,%eax
f0101f31:	74 24                	je     f0101f57 <mem_init+0x7c7>
f0101f33:	c7 44 24 0c f8 57 10 	movl   $0xf01057f8,0xc(%esp)
f0101f3a:	f0 
f0101f3b:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0101f42:	f0 
f0101f43:	c7 44 24 04 53 03 00 	movl   $0x353,0x4(%esp)
f0101f4a:	00 
f0101f4b:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0101f52:	e8 67 e1 ff ff       	call   f01000be <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101f57:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f5e:	00 
f0101f5f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f66:	00 
f0101f67:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101f6b:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f0101f70:	89 04 24             	mov    %eax,(%esp)
f0101f73:	e8 6e f7 ff ff       	call   f01016e6 <page_insert>
f0101f78:	85 c0                	test   %eax,%eax
f0101f7a:	78 24                	js     f0101fa0 <mem_init+0x810>
f0101f7c:	c7 44 24 0c 30 58 10 	movl   $0xf0105830,0xc(%esp)
f0101f83:	f0 
f0101f84:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0101f8b:	f0 
f0101f8c:	c7 44 24 04 56 03 00 	movl   $0x356,0x4(%esp)
f0101f93:	00 
f0101f94:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0101f9b:	e8 1e e1 ff ff       	call   f01000be <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101fa0:	89 1c 24             	mov    %ebx,(%esp)
f0101fa3:	e8 e1 f4 ff ff       	call   f0101489 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101fa8:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101faf:	00 
f0101fb0:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101fb7:	00 
f0101fb8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101fbc:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f0101fc1:	89 04 24             	mov    %eax,(%esp)
f0101fc4:	e8 1d f7 ff ff       	call   f01016e6 <page_insert>
f0101fc9:	85 c0                	test   %eax,%eax
f0101fcb:	74 24                	je     f0101ff1 <mem_init+0x861>
f0101fcd:	c7 44 24 0c 60 58 10 	movl   $0xf0105860,0xc(%esp)
f0101fd4:	f0 
f0101fd5:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0101fdc:	f0 
f0101fdd:	c7 44 24 04 5a 03 00 	movl   $0x35a,0x4(%esp)
f0101fe4:	00 
f0101fe5:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0101fec:	e8 cd e0 ff ff       	call   f01000be <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101ff1:	8b 0d c8 fe 17 f0    	mov    0xf017fec8,%ecx
f0101ff7:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101ffa:	a1 cc fe 17 f0       	mov    0xf017fecc,%eax
f0101fff:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102002:	8b 11                	mov    (%ecx),%edx
f0102004:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010200a:	89 d8                	mov    %ebx,%eax
f010200c:	2b 45 d0             	sub    -0x30(%ebp),%eax
f010200f:	c1 f8 03             	sar    $0x3,%eax
f0102012:	c1 e0 0c             	shl    $0xc,%eax
f0102015:	39 c2                	cmp    %eax,%edx
f0102017:	74 24                	je     f010203d <mem_init+0x8ad>
f0102019:	c7 44 24 0c 90 58 10 	movl   $0xf0105890,0xc(%esp)
f0102020:	f0 
f0102021:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0102028:	f0 
f0102029:	c7 44 24 04 5b 03 00 	movl   $0x35b,0x4(%esp)
f0102030:	00 
f0102031:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102038:	e8 81 e0 ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010203d:	ba 00 00 00 00       	mov    $0x0,%edx
f0102042:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102045:	e8 d8 ee ff ff       	call   f0100f22 <check_va2pa>
f010204a:	89 fa                	mov    %edi,%edx
f010204c:	2b 55 d0             	sub    -0x30(%ebp),%edx
f010204f:	c1 fa 03             	sar    $0x3,%edx
f0102052:	c1 e2 0c             	shl    $0xc,%edx
f0102055:	39 d0                	cmp    %edx,%eax
f0102057:	74 24                	je     f010207d <mem_init+0x8ed>
f0102059:	c7 44 24 0c b8 58 10 	movl   $0xf01058b8,0xc(%esp)
f0102060:	f0 
f0102061:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0102068:	f0 
f0102069:	c7 44 24 04 5c 03 00 	movl   $0x35c,0x4(%esp)
f0102070:	00 
f0102071:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102078:	e8 41 e0 ff ff       	call   f01000be <_panic>
	assert(pp1->pp_ref == 1);
f010207d:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102082:	74 24                	je     f01020a8 <mem_init+0x918>
f0102084:	c7 44 24 0c 6f 5f 10 	movl   $0xf0105f6f,0xc(%esp)
f010208b:	f0 
f010208c:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0102093:	f0 
f0102094:	c7 44 24 04 5d 03 00 	movl   $0x35d,0x4(%esp)
f010209b:	00 
f010209c:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f01020a3:	e8 16 e0 ff ff       	call   f01000be <_panic>
	assert(pp0->pp_ref == 1);
f01020a8:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01020ad:	74 24                	je     f01020d3 <mem_init+0x943>
f01020af:	c7 44 24 0c 80 5f 10 	movl   $0xf0105f80,0xc(%esp)
f01020b6:	f0 
f01020b7:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f01020be:	f0 
f01020bf:	c7 44 24 04 5e 03 00 	movl   $0x35e,0x4(%esp)
f01020c6:	00 
f01020c7:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f01020ce:	e8 eb df ff ff       	call   f01000be <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01020d3:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01020da:	00 
f01020db:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01020e2:	00 
f01020e3:	89 74 24 04          	mov    %esi,0x4(%esp)
f01020e7:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01020ea:	89 14 24             	mov    %edx,(%esp)
f01020ed:	e8 f4 f5 ff ff       	call   f01016e6 <page_insert>
f01020f2:	85 c0                	test   %eax,%eax
f01020f4:	74 24                	je     f010211a <mem_init+0x98a>
f01020f6:	c7 44 24 0c e8 58 10 	movl   $0xf01058e8,0xc(%esp)
f01020fd:	f0 
f01020fe:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0102105:	f0 
f0102106:	c7 44 24 04 61 03 00 	movl   $0x361,0x4(%esp)
f010210d:	00 
f010210e:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102115:	e8 a4 df ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010211a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010211f:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f0102124:	e8 f9 ed ff ff       	call   f0100f22 <check_va2pa>
f0102129:	89 f2                	mov    %esi,%edx
f010212b:	2b 15 cc fe 17 f0    	sub    0xf017fecc,%edx
f0102131:	c1 fa 03             	sar    $0x3,%edx
f0102134:	c1 e2 0c             	shl    $0xc,%edx
f0102137:	39 d0                	cmp    %edx,%eax
f0102139:	74 24                	je     f010215f <mem_init+0x9cf>
f010213b:	c7 44 24 0c 24 59 10 	movl   $0xf0105924,0xc(%esp)
f0102142:	f0 
f0102143:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f010214a:	f0 
f010214b:	c7 44 24 04 62 03 00 	movl   $0x362,0x4(%esp)
f0102152:	00 
f0102153:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f010215a:	e8 5f df ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 1);
f010215f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102164:	74 24                	je     f010218a <mem_init+0x9fa>
f0102166:	c7 44 24 0c 91 5f 10 	movl   $0xf0105f91,0xc(%esp)
f010216d:	f0 
f010216e:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0102175:	f0 
f0102176:	c7 44 24 04 63 03 00 	movl   $0x363,0x4(%esp)
f010217d:	00 
f010217e:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102185:	e8 34 df ff ff       	call   f01000be <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010218a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102191:	e8 66 f2 ff ff       	call   f01013fc <page_alloc>
f0102196:	85 c0                	test   %eax,%eax
f0102198:	74 24                	je     f01021be <mem_init+0xa2e>
f010219a:	c7 44 24 0c 1d 5f 10 	movl   $0xf0105f1d,0xc(%esp)
f01021a1:	f0 
f01021a2:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f01021a9:	f0 
f01021aa:	c7 44 24 04 66 03 00 	movl   $0x366,0x4(%esp)
f01021b1:	00 
f01021b2:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f01021b9:	e8 00 df ff ff       	call   f01000be <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01021be:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01021c5:	00 
f01021c6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01021cd:	00 
f01021ce:	89 74 24 04          	mov    %esi,0x4(%esp)
f01021d2:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f01021d7:	89 04 24             	mov    %eax,(%esp)
f01021da:	e8 07 f5 ff ff       	call   f01016e6 <page_insert>
f01021df:	85 c0                	test   %eax,%eax
f01021e1:	74 24                	je     f0102207 <mem_init+0xa77>
f01021e3:	c7 44 24 0c e8 58 10 	movl   $0xf01058e8,0xc(%esp)
f01021ea:	f0 
f01021eb:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f01021f2:	f0 
f01021f3:	c7 44 24 04 69 03 00 	movl   $0x369,0x4(%esp)
f01021fa:	00 
f01021fb:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102202:	e8 b7 de ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102207:	ba 00 10 00 00       	mov    $0x1000,%edx
f010220c:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f0102211:	e8 0c ed ff ff       	call   f0100f22 <check_va2pa>
f0102216:	89 f2                	mov    %esi,%edx
f0102218:	2b 15 cc fe 17 f0    	sub    0xf017fecc,%edx
f010221e:	c1 fa 03             	sar    $0x3,%edx
f0102221:	c1 e2 0c             	shl    $0xc,%edx
f0102224:	39 d0                	cmp    %edx,%eax
f0102226:	74 24                	je     f010224c <mem_init+0xabc>
f0102228:	c7 44 24 0c 24 59 10 	movl   $0xf0105924,0xc(%esp)
f010222f:	f0 
f0102230:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0102237:	f0 
f0102238:	c7 44 24 04 6a 03 00 	movl   $0x36a,0x4(%esp)
f010223f:	00 
f0102240:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102247:	e8 72 de ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 1);
f010224c:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102251:	74 24                	je     f0102277 <mem_init+0xae7>
f0102253:	c7 44 24 0c 91 5f 10 	movl   $0xf0105f91,0xc(%esp)
f010225a:	f0 
f010225b:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0102262:	f0 
f0102263:	c7 44 24 04 6b 03 00 	movl   $0x36b,0x4(%esp)
f010226a:	00 
f010226b:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102272:	e8 47 de ff ff       	call   f01000be <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0102277:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010227e:	e8 79 f1 ff ff       	call   f01013fc <page_alloc>
f0102283:	85 c0                	test   %eax,%eax
f0102285:	74 24                	je     f01022ab <mem_init+0xb1b>
f0102287:	c7 44 24 0c 1d 5f 10 	movl   $0xf0105f1d,0xc(%esp)
f010228e:	f0 
f010228f:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0102296:	f0 
f0102297:	c7 44 24 04 6f 03 00 	movl   $0x36f,0x4(%esp)
f010229e:	00 
f010229f:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f01022a6:	e8 13 de ff ff       	call   f01000be <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f01022ab:	8b 15 c8 fe 17 f0    	mov    0xf017fec8,%edx
f01022b1:	8b 02                	mov    (%edx),%eax
f01022b3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01022b8:	89 c1                	mov    %eax,%ecx
f01022ba:	c1 e9 0c             	shr    $0xc,%ecx
f01022bd:	3b 0d c4 fe 17 f0    	cmp    0xf017fec4,%ecx
f01022c3:	72 20                	jb     f01022e5 <mem_init+0xb55>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01022c5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01022c9:	c7 44 24 08 dc 52 10 	movl   $0xf01052dc,0x8(%esp)
f01022d0:	f0 
f01022d1:	c7 44 24 04 72 03 00 	movl   $0x372,0x4(%esp)
f01022d8:	00 
f01022d9:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f01022e0:	e8 d9 dd ff ff       	call   f01000be <_panic>
	return (void *)(pa + KERNBASE);
f01022e5:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01022ea:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01022ed:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01022f4:	00 
f01022f5:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01022fc:	00 
f01022fd:	89 14 24             	mov    %edx,(%esp)
f0102300:	e8 bc f1 ff ff       	call   f01014c1 <pgdir_walk>
f0102305:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102308:	83 c2 04             	add    $0x4,%edx
f010230b:	39 d0                	cmp    %edx,%eax
f010230d:	74 24                	je     f0102333 <mem_init+0xba3>
f010230f:	c7 44 24 0c 54 59 10 	movl   $0xf0105954,0xc(%esp)
f0102316:	f0 
f0102317:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f010231e:	f0 
f010231f:	c7 44 24 04 73 03 00 	movl   $0x373,0x4(%esp)
f0102326:	00 
f0102327:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f010232e:	e8 8b dd ff ff       	call   f01000be <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102333:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f010233a:	00 
f010233b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102342:	00 
f0102343:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102347:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f010234c:	89 04 24             	mov    %eax,(%esp)
f010234f:	e8 92 f3 ff ff       	call   f01016e6 <page_insert>
f0102354:	85 c0                	test   %eax,%eax
f0102356:	74 24                	je     f010237c <mem_init+0xbec>
f0102358:	c7 44 24 0c 94 59 10 	movl   $0xf0105994,0xc(%esp)
f010235f:	f0 
f0102360:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0102367:	f0 
f0102368:	c7 44 24 04 76 03 00 	movl   $0x376,0x4(%esp)
f010236f:	00 
f0102370:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102377:	e8 42 dd ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010237c:	8b 0d c8 fe 17 f0    	mov    0xf017fec8,%ecx
f0102382:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0102385:	ba 00 10 00 00       	mov    $0x1000,%edx
f010238a:	89 c8                	mov    %ecx,%eax
f010238c:	e8 91 eb ff ff       	call   f0100f22 <check_va2pa>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102391:	89 f2                	mov    %esi,%edx
f0102393:	2b 15 cc fe 17 f0    	sub    0xf017fecc,%edx
f0102399:	c1 fa 03             	sar    $0x3,%edx
f010239c:	c1 e2 0c             	shl    $0xc,%edx
f010239f:	39 d0                	cmp    %edx,%eax
f01023a1:	74 24                	je     f01023c7 <mem_init+0xc37>
f01023a3:	c7 44 24 0c 24 59 10 	movl   $0xf0105924,0xc(%esp)
f01023aa:	f0 
f01023ab:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f01023b2:	f0 
f01023b3:	c7 44 24 04 77 03 00 	movl   $0x377,0x4(%esp)
f01023ba:	00 
f01023bb:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f01023c2:	e8 f7 dc ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 1);
f01023c7:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01023cc:	74 24                	je     f01023f2 <mem_init+0xc62>
f01023ce:	c7 44 24 0c 91 5f 10 	movl   $0xf0105f91,0xc(%esp)
f01023d5:	f0 
f01023d6:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f01023dd:	f0 
f01023de:	c7 44 24 04 78 03 00 	movl   $0x378,0x4(%esp)
f01023e5:	00 
f01023e6:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f01023ed:	e8 cc dc ff ff       	call   f01000be <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01023f2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01023f9:	00 
f01023fa:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102401:	00 
f0102402:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102405:	89 04 24             	mov    %eax,(%esp)
f0102408:	e8 b4 f0 ff ff       	call   f01014c1 <pgdir_walk>
f010240d:	f6 00 04             	testb  $0x4,(%eax)
f0102410:	75 24                	jne    f0102436 <mem_init+0xca6>
f0102412:	c7 44 24 0c d4 59 10 	movl   $0xf01059d4,0xc(%esp)
f0102419:	f0 
f010241a:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0102421:	f0 
f0102422:	c7 44 24 04 79 03 00 	movl   $0x379,0x4(%esp)
f0102429:	00 
f010242a:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102431:	e8 88 dc ff ff       	call   f01000be <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0102436:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f010243b:	f6 00 04             	testb  $0x4,(%eax)
f010243e:	75 24                	jne    f0102464 <mem_init+0xcd4>
f0102440:	c7 44 24 0c a2 5f 10 	movl   $0xf0105fa2,0xc(%esp)
f0102447:	f0 
f0102448:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f010244f:	f0 
f0102450:	c7 44 24 04 7a 03 00 	movl   $0x37a,0x4(%esp)
f0102457:	00 
f0102458:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f010245f:	e8 5a dc ff ff       	call   f01000be <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102464:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010246b:	00 
f010246c:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0102473:	00 
f0102474:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102478:	89 04 24             	mov    %eax,(%esp)
f010247b:	e8 66 f2 ff ff       	call   f01016e6 <page_insert>
f0102480:	85 c0                	test   %eax,%eax
f0102482:	78 24                	js     f01024a8 <mem_init+0xd18>
f0102484:	c7 44 24 0c 08 5a 10 	movl   $0xf0105a08,0xc(%esp)
f010248b:	f0 
f010248c:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0102493:	f0 
f0102494:	c7 44 24 04 7d 03 00 	movl   $0x37d,0x4(%esp)
f010249b:	00 
f010249c:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f01024a3:	e8 16 dc ff ff       	call   f01000be <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f01024a8:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01024af:	00 
f01024b0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01024b7:	00 
f01024b8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01024bc:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f01024c1:	89 04 24             	mov    %eax,(%esp)
f01024c4:	e8 1d f2 ff ff       	call   f01016e6 <page_insert>
f01024c9:	85 c0                	test   %eax,%eax
f01024cb:	74 24                	je     f01024f1 <mem_init+0xd61>
f01024cd:	c7 44 24 0c 40 5a 10 	movl   $0xf0105a40,0xc(%esp)
f01024d4:	f0 
f01024d5:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f01024dc:	f0 
f01024dd:	c7 44 24 04 80 03 00 	movl   $0x380,0x4(%esp)
f01024e4:	00 
f01024e5:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f01024ec:	e8 cd db ff ff       	call   f01000be <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01024f1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01024f8:	00 
f01024f9:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102500:	00 
f0102501:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f0102506:	89 04 24             	mov    %eax,(%esp)
f0102509:	e8 b3 ef ff ff       	call   f01014c1 <pgdir_walk>
f010250e:	f6 00 04             	testb  $0x4,(%eax)
f0102511:	74 24                	je     f0102537 <mem_init+0xda7>
f0102513:	c7 44 24 0c 7c 5a 10 	movl   $0xf0105a7c,0xc(%esp)
f010251a:	f0 
f010251b:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0102522:	f0 
f0102523:	c7 44 24 04 81 03 00 	movl   $0x381,0x4(%esp)
f010252a:	00 
f010252b:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102532:	e8 87 db ff ff       	call   f01000be <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0102537:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f010253c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010253f:	ba 00 00 00 00       	mov    $0x0,%edx
f0102544:	e8 d9 e9 ff ff       	call   f0100f22 <check_va2pa>
f0102549:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010254c:	89 f8                	mov    %edi,%eax
f010254e:	2b 05 cc fe 17 f0    	sub    0xf017fecc,%eax
f0102554:	c1 f8 03             	sar    $0x3,%eax
f0102557:	c1 e0 0c             	shl    $0xc,%eax
f010255a:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f010255d:	74 24                	je     f0102583 <mem_init+0xdf3>
f010255f:	c7 44 24 0c b4 5a 10 	movl   $0xf0105ab4,0xc(%esp)
f0102566:	f0 
f0102567:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f010256e:	f0 
f010256f:	c7 44 24 04 84 03 00 	movl   $0x384,0x4(%esp)
f0102576:	00 
f0102577:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f010257e:	e8 3b db ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102583:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102588:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010258b:	e8 92 e9 ff ff       	call   f0100f22 <check_va2pa>
f0102590:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102593:	74 24                	je     f01025b9 <mem_init+0xe29>
f0102595:	c7 44 24 0c e0 5a 10 	movl   $0xf0105ae0,0xc(%esp)
f010259c:	f0 
f010259d:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f01025a4:	f0 
f01025a5:	c7 44 24 04 85 03 00 	movl   $0x385,0x4(%esp)
f01025ac:	00 
f01025ad:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f01025b4:	e8 05 db ff ff       	call   f01000be <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f01025b9:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f01025be:	74 24                	je     f01025e4 <mem_init+0xe54>
f01025c0:	c7 44 24 0c b8 5f 10 	movl   $0xf0105fb8,0xc(%esp)
f01025c7:	f0 
f01025c8:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f01025cf:	f0 
f01025d0:	c7 44 24 04 87 03 00 	movl   $0x387,0x4(%esp)
f01025d7:	00 
f01025d8:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f01025df:	e8 da da ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 0);
f01025e4:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01025e9:	74 24                	je     f010260f <mem_init+0xe7f>
f01025eb:	c7 44 24 0c c9 5f 10 	movl   $0xf0105fc9,0xc(%esp)
f01025f2:	f0 
f01025f3:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f01025fa:	f0 
f01025fb:	c7 44 24 04 88 03 00 	movl   $0x388,0x4(%esp)
f0102602:	00 
f0102603:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f010260a:	e8 af da ff ff       	call   f01000be <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f010260f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102616:	e8 e1 ed ff ff       	call   f01013fc <page_alloc>
f010261b:	85 c0                	test   %eax,%eax
f010261d:	74 04                	je     f0102623 <mem_init+0xe93>
f010261f:	39 c6                	cmp    %eax,%esi
f0102621:	74 24                	je     f0102647 <mem_init+0xeb7>
f0102623:	c7 44 24 0c 10 5b 10 	movl   $0xf0105b10,0xc(%esp)
f010262a:	f0 
f010262b:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0102632:	f0 
f0102633:	c7 44 24 04 8b 03 00 	movl   $0x38b,0x4(%esp)
f010263a:	00 
f010263b:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102642:	e8 77 da ff ff       	call   f01000be <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0102647:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010264e:	00 
f010264f:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f0102654:	89 04 24             	mov    %eax,(%esp)
f0102657:	e8 36 f0 ff ff       	call   f0101692 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010265c:	8b 15 c8 fe 17 f0    	mov    0xf017fec8,%edx
f0102662:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0102665:	ba 00 00 00 00       	mov    $0x0,%edx
f010266a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010266d:	e8 b0 e8 ff ff       	call   f0100f22 <check_va2pa>
f0102672:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102675:	74 24                	je     f010269b <mem_init+0xf0b>
f0102677:	c7 44 24 0c 34 5b 10 	movl   $0xf0105b34,0xc(%esp)
f010267e:	f0 
f010267f:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0102686:	f0 
f0102687:	c7 44 24 04 8f 03 00 	movl   $0x38f,0x4(%esp)
f010268e:	00 
f010268f:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102696:	e8 23 da ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010269b:	ba 00 10 00 00       	mov    $0x1000,%edx
f01026a0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01026a3:	e8 7a e8 ff ff       	call   f0100f22 <check_va2pa>
f01026a8:	89 fa                	mov    %edi,%edx
f01026aa:	2b 15 cc fe 17 f0    	sub    0xf017fecc,%edx
f01026b0:	c1 fa 03             	sar    $0x3,%edx
f01026b3:	c1 e2 0c             	shl    $0xc,%edx
f01026b6:	39 d0                	cmp    %edx,%eax
f01026b8:	74 24                	je     f01026de <mem_init+0xf4e>
f01026ba:	c7 44 24 0c e0 5a 10 	movl   $0xf0105ae0,0xc(%esp)
f01026c1:	f0 
f01026c2:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f01026c9:	f0 
f01026ca:	c7 44 24 04 90 03 00 	movl   $0x390,0x4(%esp)
f01026d1:	00 
f01026d2:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f01026d9:	e8 e0 d9 ff ff       	call   f01000be <_panic>
	assert(pp1->pp_ref == 1);
f01026de:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01026e3:	74 24                	je     f0102709 <mem_init+0xf79>
f01026e5:	c7 44 24 0c 6f 5f 10 	movl   $0xf0105f6f,0xc(%esp)
f01026ec:	f0 
f01026ed:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f01026f4:	f0 
f01026f5:	c7 44 24 04 91 03 00 	movl   $0x391,0x4(%esp)
f01026fc:	00 
f01026fd:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102704:	e8 b5 d9 ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 0);
f0102709:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010270e:	74 24                	je     f0102734 <mem_init+0xfa4>
f0102710:	c7 44 24 0c c9 5f 10 	movl   $0xf0105fc9,0xc(%esp)
f0102717:	f0 
f0102718:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f010271f:	f0 
f0102720:	c7 44 24 04 92 03 00 	movl   $0x392,0x4(%esp)
f0102727:	00 
f0102728:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f010272f:	e8 8a d9 ff ff       	call   f01000be <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102734:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010273b:	00 
f010273c:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010273f:	89 0c 24             	mov    %ecx,(%esp)
f0102742:	e8 4b ef ff ff       	call   f0101692 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102747:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f010274c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010274f:	ba 00 00 00 00       	mov    $0x0,%edx
f0102754:	e8 c9 e7 ff ff       	call   f0100f22 <check_va2pa>
f0102759:	83 f8 ff             	cmp    $0xffffffff,%eax
f010275c:	74 24                	je     f0102782 <mem_init+0xff2>
f010275e:	c7 44 24 0c 34 5b 10 	movl   $0xf0105b34,0xc(%esp)
f0102765:	f0 
f0102766:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f010276d:	f0 
f010276e:	c7 44 24 04 96 03 00 	movl   $0x396,0x4(%esp)
f0102775:	00 
f0102776:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f010277d:	e8 3c d9 ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102782:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102787:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010278a:	e8 93 e7 ff ff       	call   f0100f22 <check_va2pa>
f010278f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102792:	74 24                	je     f01027b8 <mem_init+0x1028>
f0102794:	c7 44 24 0c 58 5b 10 	movl   $0xf0105b58,0xc(%esp)
f010279b:	f0 
f010279c:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f01027a3:	f0 
f01027a4:	c7 44 24 04 97 03 00 	movl   $0x397,0x4(%esp)
f01027ab:	00 
f01027ac:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f01027b3:	e8 06 d9 ff ff       	call   f01000be <_panic>
	assert(pp1->pp_ref == 0);
f01027b8:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01027bd:	74 24                	je     f01027e3 <mem_init+0x1053>
f01027bf:	c7 44 24 0c da 5f 10 	movl   $0xf0105fda,0xc(%esp)
f01027c6:	f0 
f01027c7:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f01027ce:	f0 
f01027cf:	c7 44 24 04 98 03 00 	movl   $0x398,0x4(%esp)
f01027d6:	00 
f01027d7:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f01027de:	e8 db d8 ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 0);
f01027e3:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01027e8:	74 24                	je     f010280e <mem_init+0x107e>
f01027ea:	c7 44 24 0c c9 5f 10 	movl   $0xf0105fc9,0xc(%esp)
f01027f1:	f0 
f01027f2:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f01027f9:	f0 
f01027fa:	c7 44 24 04 99 03 00 	movl   $0x399,0x4(%esp)
f0102801:	00 
f0102802:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102809:	e8 b0 d8 ff ff       	call   f01000be <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f010280e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102815:	e8 e2 eb ff ff       	call   f01013fc <page_alloc>
f010281a:	85 c0                	test   %eax,%eax
f010281c:	74 04                	je     f0102822 <mem_init+0x1092>
f010281e:	39 c7                	cmp    %eax,%edi
f0102820:	74 24                	je     f0102846 <mem_init+0x10b6>
f0102822:	c7 44 24 0c 80 5b 10 	movl   $0xf0105b80,0xc(%esp)
f0102829:	f0 
f010282a:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0102831:	f0 
f0102832:	c7 44 24 04 9c 03 00 	movl   $0x39c,0x4(%esp)
f0102839:	00 
f010283a:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102841:	e8 78 d8 ff ff       	call   f01000be <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102846:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010284d:	e8 aa eb ff ff       	call   f01013fc <page_alloc>
f0102852:	85 c0                	test   %eax,%eax
f0102854:	74 24                	je     f010287a <mem_init+0x10ea>
f0102856:	c7 44 24 0c 1d 5f 10 	movl   $0xf0105f1d,0xc(%esp)
f010285d:	f0 
f010285e:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0102865:	f0 
f0102866:	c7 44 24 04 9f 03 00 	movl   $0x39f,0x4(%esp)
f010286d:	00 
f010286e:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102875:	e8 44 d8 ff ff       	call   f01000be <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010287a:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f010287f:	8b 08                	mov    (%eax),%ecx
f0102881:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102887:	89 da                	mov    %ebx,%edx
f0102889:	2b 15 cc fe 17 f0    	sub    0xf017fecc,%edx
f010288f:	c1 fa 03             	sar    $0x3,%edx
f0102892:	c1 e2 0c             	shl    $0xc,%edx
f0102895:	39 d1                	cmp    %edx,%ecx
f0102897:	74 24                	je     f01028bd <mem_init+0x112d>
f0102899:	c7 44 24 0c 90 58 10 	movl   $0xf0105890,0xc(%esp)
f01028a0:	f0 
f01028a1:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f01028a8:	f0 
f01028a9:	c7 44 24 04 a2 03 00 	movl   $0x3a2,0x4(%esp)
f01028b0:	00 
f01028b1:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f01028b8:	e8 01 d8 ff ff       	call   f01000be <_panic>
	kern_pgdir[0] = 0;
f01028bd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f01028c3:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01028c8:	74 24                	je     f01028ee <mem_init+0x115e>
f01028ca:	c7 44 24 0c 80 5f 10 	movl   $0xf0105f80,0xc(%esp)
f01028d1:	f0 
f01028d2:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f01028d9:	f0 
f01028da:	c7 44 24 04 a4 03 00 	movl   $0x3a4,0x4(%esp)
f01028e1:	00 
f01028e2:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f01028e9:	e8 d0 d7 ff ff       	call   f01000be <_panic>
	pp0->pp_ref = 0;
f01028ee:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01028f4:	89 1c 24             	mov    %ebx,(%esp)
f01028f7:	e8 8d eb ff ff       	call   f0101489 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01028fc:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102903:	00 
f0102904:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f010290b:	00 
f010290c:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f0102911:	89 04 24             	mov    %eax,(%esp)
f0102914:	e8 a8 eb ff ff       	call   f01014c1 <pgdir_walk>
f0102919:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f010291c:	8b 0d c8 fe 17 f0    	mov    0xf017fec8,%ecx
f0102922:	8b 51 04             	mov    0x4(%ecx),%edx
f0102925:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010292b:	89 55 d4             	mov    %edx,-0x2c(%ebp)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010292e:	8b 15 c4 fe 17 f0    	mov    0xf017fec4,%edx
f0102934:	89 55 c8             	mov    %edx,-0x38(%ebp)
f0102937:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010293a:	c1 ea 0c             	shr    $0xc,%edx
f010293d:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102940:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0102943:	39 55 d0             	cmp    %edx,-0x30(%ebp)
f0102946:	72 23                	jb     f010296b <mem_init+0x11db>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102948:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010294b:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010294f:	c7 44 24 08 dc 52 10 	movl   $0xf01052dc,0x8(%esp)
f0102956:	f0 
f0102957:	c7 44 24 04 ab 03 00 	movl   $0x3ab,0x4(%esp)
f010295e:	00 
f010295f:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102966:	e8 53 d7 ff ff       	call   f01000be <_panic>
	assert(ptep == ptep1 + PTX(va));
f010296b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010296e:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0102974:	39 d0                	cmp    %edx,%eax
f0102976:	74 24                	je     f010299c <mem_init+0x120c>
f0102978:	c7 44 24 0c eb 5f 10 	movl   $0xf0105feb,0xc(%esp)
f010297f:	f0 
f0102980:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0102987:	f0 
f0102988:	c7 44 24 04 ac 03 00 	movl   $0x3ac,0x4(%esp)
f010298f:	00 
f0102990:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102997:	e8 22 d7 ff ff       	call   f01000be <_panic>
	kern_pgdir[PDX(va)] = 0;
f010299c:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f01029a3:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01029a9:	89 d8                	mov    %ebx,%eax
f01029ab:	2b 05 cc fe 17 f0    	sub    0xf017fecc,%eax
f01029b1:	c1 f8 03             	sar    $0x3,%eax
f01029b4:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01029b7:	89 c1                	mov    %eax,%ecx
f01029b9:	c1 e9 0c             	shr    $0xc,%ecx
f01029bc:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f01029bf:	77 20                	ja     f01029e1 <mem_init+0x1251>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01029c1:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01029c5:	c7 44 24 08 dc 52 10 	movl   $0xf01052dc,0x8(%esp)
f01029cc:	f0 
f01029cd:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01029d4:	00 
f01029d5:	c7 04 24 ad 5d 10 f0 	movl   $0xf0105dad,(%esp)
f01029dc:	e8 dd d6 ff ff       	call   f01000be <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01029e1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01029e8:	00 
f01029e9:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f01029f0:	00 
	return (void *)(pa + KERNBASE);
f01029f1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01029f6:	89 04 24             	mov    %eax,(%esp)
f01029f9:	e8 a3 1e 00 00       	call   f01048a1 <memset>
	page_free(pp0);
f01029fe:	89 1c 24             	mov    %ebx,(%esp)
f0102a01:	e8 83 ea ff ff       	call   f0101489 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102a06:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102a0d:	00 
f0102a0e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102a15:	00 
f0102a16:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f0102a1b:	89 04 24             	mov    %eax,(%esp)
f0102a1e:	e8 9e ea ff ff       	call   f01014c1 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102a23:	89 da                	mov    %ebx,%edx
f0102a25:	2b 15 cc fe 17 f0    	sub    0xf017fecc,%edx
f0102a2b:	c1 fa 03             	sar    $0x3,%edx
f0102a2e:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a31:	89 d0                	mov    %edx,%eax
f0102a33:	c1 e8 0c             	shr    $0xc,%eax
f0102a36:	3b 05 c4 fe 17 f0    	cmp    0xf017fec4,%eax
f0102a3c:	72 20                	jb     f0102a5e <mem_init+0x12ce>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a3e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102a42:	c7 44 24 08 dc 52 10 	movl   $0xf01052dc,0x8(%esp)
f0102a49:	f0 
f0102a4a:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102a51:	00 
f0102a52:	c7 04 24 ad 5d 10 f0 	movl   $0xf0105dad,(%esp)
f0102a59:	e8 60 d6 ff ff       	call   f01000be <_panic>
	return (void *)(pa + KERNBASE);
f0102a5e:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102a64:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102a67:	f6 82 00 00 00 f0 01 	testb  $0x1,-0x10000000(%edx)
f0102a6e:	75 11                	jne    f0102a81 <mem_init+0x12f1>
f0102a70:	8d 82 04 00 00 f0    	lea    -0xffffffc(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102a76:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102a7c:	f6 00 01             	testb  $0x1,(%eax)
f0102a7f:	74 24                	je     f0102aa5 <mem_init+0x1315>
f0102a81:	c7 44 24 0c 03 60 10 	movl   $0xf0106003,0xc(%esp)
f0102a88:	f0 
f0102a89:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0102a90:	f0 
f0102a91:	c7 44 24 04 b6 03 00 	movl   $0x3b6,0x4(%esp)
f0102a98:	00 
f0102a99:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102aa0:	e8 19 d6 ff ff       	call   f01000be <_panic>
f0102aa5:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102aa8:	39 d0                	cmp    %edx,%eax
f0102aaa:	75 d0                	jne    f0102a7c <mem_init+0x12ec>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102aac:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f0102ab1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102ab7:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// give free list back
	page_free_list = fl;
f0102abd:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102ac0:	89 0d 20 f2 17 f0    	mov    %ecx,0xf017f220

	// free the pages we took
	page_free(pp0);
f0102ac6:	89 1c 24             	mov    %ebx,(%esp)
f0102ac9:	e8 bb e9 ff ff       	call   f0101489 <page_free>
	page_free(pp1);
f0102ace:	89 3c 24             	mov    %edi,(%esp)
f0102ad1:	e8 b3 e9 ff ff       	call   f0101489 <page_free>
	page_free(pp2);
f0102ad6:	89 34 24             	mov    %esi,(%esp)
f0102ad9:	e8 ab e9 ff ff       	call   f0101489 <page_free>

	cprintf("check_page() succeeded!\n");
f0102ade:	c7 04 24 1a 60 10 f0 	movl   $0xf010601a,(%esp)
f0102ae5:	e8 d0 0c 00 00       	call   f01037ba <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:

	boot_map_region(kern_pgdir,UPAGES,npages * sizeof (struct Page),PADDR (pages), PTE_U| PTE_P);
f0102aea:	a1 cc fe 17 f0       	mov    0xf017fecc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102aef:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102af4:	77 20                	ja     f0102b16 <mem_init+0x1386>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102af6:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102afa:	c7 44 24 08 38 57 10 	movl   $0xf0105738,0x8(%esp)
f0102b01:	f0 
f0102b02:	c7 44 24 04 b2 00 00 	movl   $0xb2,0x4(%esp)
f0102b09:	00 
f0102b0a:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102b11:	e8 a8 d5 ff ff       	call   f01000be <_panic>
f0102b16:	8b 0d c4 fe 17 f0    	mov    0xf017fec4,%ecx
f0102b1c:	c1 e1 03             	shl    $0x3,%ecx
f0102b1f:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102b26:	00 
	return (physaddr_t)kva - KERNBASE;
f0102b27:	05 00 00 00 10       	add    $0x10000000,%eax
f0102b2c:	89 04 24             	mov    %eax,(%esp)
f0102b2f:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102b34:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f0102b39:	e8 67 ea ff ff       	call   f01015a5 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102b3e:	b8 00 20 11 f0       	mov    $0xf0112000,%eax
f0102b43:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102b48:	77 20                	ja     f0102b6a <mem_init+0x13da>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102b4a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102b4e:	c7 44 24 08 38 57 10 	movl   $0xf0105738,0x8(%esp)
f0102b55:	f0 
f0102b56:	c7 44 24 04 c6 00 00 	movl   $0xc6,0x4(%esp)
f0102b5d:	00 
f0102b5e:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102b65:	e8 54 d5 ff ff       	call   f01000be <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region (kern_pgdir,KSTACKTOP - KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_W| PTE_P);
f0102b6a:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102b71:	00 
f0102b72:	c7 04 24 00 20 11 00 	movl   $0x112000,(%esp)
f0102b79:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102b7e:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f0102b83:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f0102b88:	e8 18 ea ff ff       	call   f01015a5 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region (kern_pgdir,KERNBASE,0xffffffff-KERNBASE+1, 0,PTE_W| PTE_P);
f0102b8d:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102b94:	00 
f0102b95:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102b9c:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102ba1:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102ba6:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f0102bab:	e8 f5 e9 ff ff       	call   f01015a5 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102bb0:	8b 1d c8 fe 17 f0    	mov    0xf017fec8,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
f0102bb6:	8b 15 c4 fe 17 f0    	mov    0xf017fec4,%edx
f0102bbc:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0102bbf:	8d 3c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%edi
	for (i = 0; i < n; i += PGSIZE)
f0102bc6:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
f0102bcc:	0f 84 80 00 00 00    	je     f0102c52 <mem_init+0x14c2>
f0102bd2:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102bd7:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102bdd:	89 d8                	mov    %ebx,%eax
f0102bdf:	e8 3e e3 ff ff       	call   f0100f22 <check_va2pa>
f0102be4:	8b 15 cc fe 17 f0    	mov    0xf017fecc,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102bea:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102bf0:	77 20                	ja     f0102c12 <mem_init+0x1482>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102bf2:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102bf6:	c7 44 24 08 38 57 10 	movl   $0xf0105738,0x8(%esp)
f0102bfd:	f0 
f0102bfe:	c7 44 24 04 fd 02 00 	movl   $0x2fd,0x4(%esp)
f0102c05:	00 
f0102c06:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102c0d:	e8 ac d4 ff ff       	call   f01000be <_panic>
f0102c12:	8d 94 32 00 00 00 10 	lea    0x10000000(%edx,%esi,1),%edx
f0102c19:	39 d0                	cmp    %edx,%eax
f0102c1b:	74 24                	je     f0102c41 <mem_init+0x14b1>
f0102c1d:	c7 44 24 0c a4 5b 10 	movl   $0xf0105ba4,0xc(%esp)
f0102c24:	f0 
f0102c25:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0102c2c:	f0 
f0102c2d:	c7 44 24 04 fd 02 00 	movl   $0x2fd,0x4(%esp)
f0102c34:	00 
f0102c35:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102c3c:	e8 7d d4 ff ff       	call   f01000be <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102c41:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102c47:	39 f7                	cmp    %esi,%edi
f0102c49:	77 8c                	ja     f0102bd7 <mem_init+0x1447>
f0102c4b:	be 00 00 00 00       	mov    $0x0,%esi
f0102c50:	eb 05                	jmp    f0102c57 <mem_init+0x14c7>
f0102c52:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102c57:	8d 96 00 00 c0 ee    	lea    -0x11400000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102c5d:	89 d8                	mov    %ebx,%eax
f0102c5f:	e8 be e2 ff ff       	call   f0100f22 <check_va2pa>
f0102c64:	8b 15 28 f2 17 f0    	mov    0xf017f228,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102c6a:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102c70:	77 20                	ja     f0102c92 <mem_init+0x1502>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c72:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102c76:	c7 44 24 08 38 57 10 	movl   $0xf0105738,0x8(%esp)
f0102c7d:	f0 
f0102c7e:	c7 44 24 04 02 03 00 	movl   $0x302,0x4(%esp)
f0102c85:	00 
f0102c86:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102c8d:	e8 2c d4 ff ff       	call   f01000be <_panic>
f0102c92:	8d 94 32 00 00 00 10 	lea    0x10000000(%edx,%esi,1),%edx
f0102c99:	39 d0                	cmp    %edx,%eax
f0102c9b:	74 24                	je     f0102cc1 <mem_init+0x1531>
f0102c9d:	c7 44 24 0c d8 5b 10 	movl   $0xf0105bd8,0xc(%esp)
f0102ca4:	f0 
f0102ca5:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0102cac:	f0 
f0102cad:	c7 44 24 04 02 03 00 	movl   $0x302,0x4(%esp)
f0102cb4:	00 
f0102cb5:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102cbc:	e8 fd d3 ff ff       	call   f01000be <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102cc1:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102cc7:	81 fe 00 80 01 00    	cmp    $0x18000,%esi
f0102ccd:	75 88                	jne    f0102c57 <mem_init+0x14c7>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102ccf:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102cd2:	c1 e7 0c             	shl    $0xc,%edi
f0102cd5:	85 ff                	test   %edi,%edi
f0102cd7:	74 44                	je     f0102d1d <mem_init+0x158d>
f0102cd9:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102cde:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102ce4:	89 d8                	mov    %ebx,%eax
f0102ce6:	e8 37 e2 ff ff       	call   f0100f22 <check_va2pa>
f0102ceb:	39 c6                	cmp    %eax,%esi
f0102ced:	74 24                	je     f0102d13 <mem_init+0x1583>
f0102cef:	c7 44 24 0c 0c 5c 10 	movl   $0xf0105c0c,0xc(%esp)
f0102cf6:	f0 
f0102cf7:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0102cfe:	f0 
f0102cff:	c7 44 24 04 06 03 00 	movl   $0x306,0x4(%esp)
f0102d06:	00 
f0102d07:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102d0e:	e8 ab d3 ff ff       	call   f01000be <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102d13:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102d19:	39 fe                	cmp    %edi,%esi
f0102d1b:	72 c1                	jb     f0102cde <mem_init+0x154e>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102d1d:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f0102d22:	89 d8                	mov    %ebx,%eax
f0102d24:	e8 f9 e1 ff ff       	call   f0100f22 <check_va2pa>
f0102d29:	be 00 90 bf ef       	mov    $0xefbf9000,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102d2e:	bf 00 20 11 f0       	mov    $0xf0112000,%edi
f0102d33:	81 c7 00 70 40 20    	add    $0x20407000,%edi
f0102d39:	8d 14 37             	lea    (%edi,%esi,1),%edx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102d3c:	39 c2                	cmp    %eax,%edx
f0102d3e:	74 24                	je     f0102d64 <mem_init+0x15d4>
f0102d40:	c7 44 24 0c 34 5c 10 	movl   $0xf0105c34,0xc(%esp)
f0102d47:	f0 
f0102d48:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0102d4f:	f0 
f0102d50:	c7 44 24 04 0a 03 00 	movl   $0x30a,0x4(%esp)
f0102d57:	00 
f0102d58:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102d5f:	e8 5a d3 ff ff       	call   f01000be <_panic>
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102d64:	81 fe 00 00 c0 ef    	cmp    $0xefc00000,%esi
f0102d6a:	0f 85 27 05 00 00    	jne    f0103297 <mem_init+0x1b07>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102d70:	ba 00 00 80 ef       	mov    $0xef800000,%edx
f0102d75:	89 d8                	mov    %ebx,%eax
f0102d77:	e8 a6 e1 ff ff       	call   f0100f22 <check_va2pa>
f0102d7c:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102d7f:	74 24                	je     f0102da5 <mem_init+0x1615>
f0102d81:	c7 44 24 0c 7c 5c 10 	movl   $0xf0105c7c,0xc(%esp)
f0102d88:	f0 
f0102d89:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0102d90:	f0 
f0102d91:	c7 44 24 04 0b 03 00 	movl   $0x30b,0x4(%esp)
f0102d98:	00 
f0102d99:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102da0:	e8 19 d3 ff ff       	call   f01000be <_panic>
f0102da5:	b8 00 00 00 00       	mov    $0x0,%eax

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102daa:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f0102db0:	83 fa 03             	cmp    $0x3,%edx
f0102db3:	77 2e                	ja     f0102de3 <mem_init+0x1653>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f0102db5:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0102db9:	0f 85 aa 00 00 00    	jne    f0102e69 <mem_init+0x16d9>
f0102dbf:	c7 44 24 0c 33 60 10 	movl   $0xf0106033,0xc(%esp)
f0102dc6:	f0 
f0102dc7:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0102dce:	f0 
f0102dcf:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
f0102dd6:	00 
f0102dd7:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102dde:	e8 db d2 ff ff       	call   f01000be <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102de3:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102de8:	76 55                	jbe    f0102e3f <mem_init+0x16af>
				assert(pgdir[i] & PTE_P);
f0102dea:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0102ded:	f6 c2 01             	test   $0x1,%dl
f0102df0:	75 24                	jne    f0102e16 <mem_init+0x1686>
f0102df2:	c7 44 24 0c 33 60 10 	movl   $0xf0106033,0xc(%esp)
f0102df9:	f0 
f0102dfa:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0102e01:	f0 
f0102e02:	c7 44 24 04 18 03 00 	movl   $0x318,0x4(%esp)
f0102e09:	00 
f0102e0a:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102e11:	e8 a8 d2 ff ff       	call   f01000be <_panic>
				assert(pgdir[i] & PTE_W);
f0102e16:	f6 c2 02             	test   $0x2,%dl
f0102e19:	75 4e                	jne    f0102e69 <mem_init+0x16d9>
f0102e1b:	c7 44 24 0c 44 60 10 	movl   $0xf0106044,0xc(%esp)
f0102e22:	f0 
f0102e23:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0102e2a:	f0 
f0102e2b:	c7 44 24 04 19 03 00 	movl   $0x319,0x4(%esp)
f0102e32:	00 
f0102e33:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102e3a:	e8 7f d2 ff ff       	call   f01000be <_panic>
			} else
				assert(pgdir[i] == 0);
f0102e3f:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0102e43:	74 24                	je     f0102e69 <mem_init+0x16d9>
f0102e45:	c7 44 24 0c 55 60 10 	movl   $0xf0106055,0xc(%esp)
f0102e4c:	f0 
f0102e4d:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0102e54:	f0 
f0102e55:	c7 44 24 04 1b 03 00 	movl   $0x31b,0x4(%esp)
f0102e5c:	00 
f0102e5d:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102e64:	e8 55 d2 ff ff       	call   f01000be <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102e69:	83 c0 01             	add    $0x1,%eax
f0102e6c:	3d 00 04 00 00       	cmp    $0x400,%eax
f0102e71:	0f 85 33 ff ff ff    	jne    f0102daa <mem_init+0x161a>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102e77:	c7 04 24 ac 5c 10 f0 	movl   $0xf0105cac,(%esp)
f0102e7e:	e8 37 09 00 00       	call   f01037ba <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102e83:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e88:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102e8d:	77 20                	ja     f0102eaf <mem_init+0x171f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e8f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102e93:	c7 44 24 08 38 57 10 	movl   $0xf0105738,0x8(%esp)
f0102e9a:	f0 
f0102e9b:	c7 44 24 04 da 00 00 	movl   $0xda,0x4(%esp)
f0102ea2:	00 
f0102ea3:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102eaa:	e8 0f d2 ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102eaf:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102eb4:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102eb7:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ebc:	e8 04 e1 ff ff       	call   f0100fc5 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102ec1:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
f0102ec4:	0d 23 00 05 80       	or     $0x80050023,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102ec9:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102ecc:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102ecf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102ed6:	e8 21 e5 ff ff       	call   f01013fc <page_alloc>
f0102edb:	89 c6                	mov    %eax,%esi
f0102edd:	85 c0                	test   %eax,%eax
f0102edf:	75 24                	jne    f0102f05 <mem_init+0x1775>
f0102ee1:	c7 44 24 0c 72 5e 10 	movl   $0xf0105e72,0xc(%esp)
f0102ee8:	f0 
f0102ee9:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0102ef0:	f0 
f0102ef1:	c7 44 24 04 d1 03 00 	movl   $0x3d1,0x4(%esp)
f0102ef8:	00 
f0102ef9:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102f00:	e8 b9 d1 ff ff       	call   f01000be <_panic>
	assert((pp1 = page_alloc(0)));
f0102f05:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102f0c:	e8 eb e4 ff ff       	call   f01013fc <page_alloc>
f0102f11:	89 c7                	mov    %eax,%edi
f0102f13:	85 c0                	test   %eax,%eax
f0102f15:	75 24                	jne    f0102f3b <mem_init+0x17ab>
f0102f17:	c7 44 24 0c 88 5e 10 	movl   $0xf0105e88,0xc(%esp)
f0102f1e:	f0 
f0102f1f:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0102f26:	f0 
f0102f27:	c7 44 24 04 d2 03 00 	movl   $0x3d2,0x4(%esp)
f0102f2e:	00 
f0102f2f:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102f36:	e8 83 d1 ff ff       	call   f01000be <_panic>
	assert((pp2 = page_alloc(0)));
f0102f3b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102f42:	e8 b5 e4 ff ff       	call   f01013fc <page_alloc>
f0102f47:	89 c3                	mov    %eax,%ebx
f0102f49:	85 c0                	test   %eax,%eax
f0102f4b:	75 24                	jne    f0102f71 <mem_init+0x17e1>
f0102f4d:	c7 44 24 0c 9e 5e 10 	movl   $0xf0105e9e,0xc(%esp)
f0102f54:	f0 
f0102f55:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0102f5c:	f0 
f0102f5d:	c7 44 24 04 d3 03 00 	movl   $0x3d3,0x4(%esp)
f0102f64:	00 
f0102f65:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0102f6c:	e8 4d d1 ff ff       	call   f01000be <_panic>
	page_free(pp0);
f0102f71:	89 34 24             	mov    %esi,(%esp)
f0102f74:	e8 10 e5 ff ff       	call   f0101489 <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102f79:	89 f8                	mov    %edi,%eax
f0102f7b:	2b 05 cc fe 17 f0    	sub    0xf017fecc,%eax
f0102f81:	c1 f8 03             	sar    $0x3,%eax
f0102f84:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102f87:	89 c2                	mov    %eax,%edx
f0102f89:	c1 ea 0c             	shr    $0xc,%edx
f0102f8c:	3b 15 c4 fe 17 f0    	cmp    0xf017fec4,%edx
f0102f92:	72 20                	jb     f0102fb4 <mem_init+0x1824>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102f94:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102f98:	c7 44 24 08 dc 52 10 	movl   $0xf01052dc,0x8(%esp)
f0102f9f:	f0 
f0102fa0:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102fa7:	00 
f0102fa8:	c7 04 24 ad 5d 10 f0 	movl   $0xf0105dad,(%esp)
f0102faf:	e8 0a d1 ff ff       	call   f01000be <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102fb4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102fbb:	00 
f0102fbc:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102fc3:	00 
	return (void *)(pa + KERNBASE);
f0102fc4:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102fc9:	89 04 24             	mov    %eax,(%esp)
f0102fcc:	e8 d0 18 00 00       	call   f01048a1 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102fd1:	89 d8                	mov    %ebx,%eax
f0102fd3:	2b 05 cc fe 17 f0    	sub    0xf017fecc,%eax
f0102fd9:	c1 f8 03             	sar    $0x3,%eax
f0102fdc:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102fdf:	89 c2                	mov    %eax,%edx
f0102fe1:	c1 ea 0c             	shr    $0xc,%edx
f0102fe4:	3b 15 c4 fe 17 f0    	cmp    0xf017fec4,%edx
f0102fea:	72 20                	jb     f010300c <mem_init+0x187c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102fec:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102ff0:	c7 44 24 08 dc 52 10 	movl   $0xf01052dc,0x8(%esp)
f0102ff7:	f0 
f0102ff8:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102fff:	00 
f0103000:	c7 04 24 ad 5d 10 f0 	movl   $0xf0105dad,(%esp)
f0103007:	e8 b2 d0 ff ff       	call   f01000be <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f010300c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0103013:	00 
f0103014:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f010301b:	00 
	return (void *)(pa + KERNBASE);
f010301c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0103021:	89 04 24             	mov    %eax,(%esp)
f0103024:	e8 78 18 00 00       	call   f01048a1 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0103029:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0103030:	00 
f0103031:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0103038:	00 
f0103039:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010303d:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f0103042:	89 04 24             	mov    %eax,(%esp)
f0103045:	e8 9c e6 ff ff       	call   f01016e6 <page_insert>
	assert(pp1->pp_ref == 1);
f010304a:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f010304f:	74 24                	je     f0103075 <mem_init+0x18e5>
f0103051:	c7 44 24 0c 6f 5f 10 	movl   $0xf0105f6f,0xc(%esp)
f0103058:	f0 
f0103059:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0103060:	f0 
f0103061:	c7 44 24 04 d8 03 00 	movl   $0x3d8,0x4(%esp)
f0103068:	00 
f0103069:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0103070:	e8 49 d0 ff ff       	call   f01000be <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0103075:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f010307c:	01 01 01 
f010307f:	74 24                	je     f01030a5 <mem_init+0x1915>
f0103081:	c7 44 24 0c cc 5c 10 	movl   $0xf0105ccc,0xc(%esp)
f0103088:	f0 
f0103089:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0103090:	f0 
f0103091:	c7 44 24 04 d9 03 00 	movl   $0x3d9,0x4(%esp)
f0103098:	00 
f0103099:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f01030a0:	e8 19 d0 ff ff       	call   f01000be <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f01030a5:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01030ac:	00 
f01030ad:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01030b4:	00 
f01030b5:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01030b9:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f01030be:	89 04 24             	mov    %eax,(%esp)
f01030c1:	e8 20 e6 ff ff       	call   f01016e6 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f01030c6:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f01030cd:	02 02 02 
f01030d0:	74 24                	je     f01030f6 <mem_init+0x1966>
f01030d2:	c7 44 24 0c f0 5c 10 	movl   $0xf0105cf0,0xc(%esp)
f01030d9:	f0 
f01030da:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f01030e1:	f0 
f01030e2:	c7 44 24 04 db 03 00 	movl   $0x3db,0x4(%esp)
f01030e9:	00 
f01030ea:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f01030f1:	e8 c8 cf ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 1);
f01030f6:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01030fb:	74 24                	je     f0103121 <mem_init+0x1991>
f01030fd:	c7 44 24 0c 91 5f 10 	movl   $0xf0105f91,0xc(%esp)
f0103104:	f0 
f0103105:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f010310c:	f0 
f010310d:	c7 44 24 04 dc 03 00 	movl   $0x3dc,0x4(%esp)
f0103114:	00 
f0103115:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f010311c:	e8 9d cf ff ff       	call   f01000be <_panic>
	assert(pp1->pp_ref == 0);
f0103121:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0103126:	74 24                	je     f010314c <mem_init+0x19bc>
f0103128:	c7 44 24 0c da 5f 10 	movl   $0xf0105fda,0xc(%esp)
f010312f:	f0 
f0103130:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0103137:	f0 
f0103138:	c7 44 24 04 dd 03 00 	movl   $0x3dd,0x4(%esp)
f010313f:	00 
f0103140:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0103147:	e8 72 cf ff ff       	call   f01000be <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f010314c:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0103153:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0103156:	89 d8                	mov    %ebx,%eax
f0103158:	2b 05 cc fe 17 f0    	sub    0xf017fecc,%eax
f010315e:	c1 f8 03             	sar    $0x3,%eax
f0103161:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103164:	89 c2                	mov    %eax,%edx
f0103166:	c1 ea 0c             	shr    $0xc,%edx
f0103169:	3b 15 c4 fe 17 f0    	cmp    0xf017fec4,%edx
f010316f:	72 20                	jb     f0103191 <mem_init+0x1a01>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103171:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103175:	c7 44 24 08 dc 52 10 	movl   $0xf01052dc,0x8(%esp)
f010317c:	f0 
f010317d:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0103184:	00 
f0103185:	c7 04 24 ad 5d 10 f0 	movl   $0xf0105dad,(%esp)
f010318c:	e8 2d cf ff ff       	call   f01000be <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0103191:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0103198:	03 03 03 
f010319b:	74 24                	je     f01031c1 <mem_init+0x1a31>
f010319d:	c7 44 24 0c 14 5d 10 	movl   $0xf0105d14,0xc(%esp)
f01031a4:	f0 
f01031a5:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f01031ac:	f0 
f01031ad:	c7 44 24 04 df 03 00 	movl   $0x3df,0x4(%esp)
f01031b4:	00 
f01031b5:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f01031bc:	e8 fd ce ff ff       	call   f01000be <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01031c1:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01031c8:	00 
f01031c9:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f01031ce:	89 04 24             	mov    %eax,(%esp)
f01031d1:	e8 bc e4 ff ff       	call   f0101692 <page_remove>
	assert(pp2->pp_ref == 0);
f01031d6:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01031db:	74 24                	je     f0103201 <mem_init+0x1a71>
f01031dd:	c7 44 24 0c c9 5f 10 	movl   $0xf0105fc9,0xc(%esp)
f01031e4:	f0 
f01031e5:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f01031ec:	f0 
f01031ed:	c7 44 24 04 e1 03 00 	movl   $0x3e1,0x4(%esp)
f01031f4:	00 
f01031f5:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f01031fc:	e8 bd ce ff ff       	call   f01000be <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0103201:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f0103206:	8b 08                	mov    (%eax),%ecx
f0103208:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f010320e:	89 f2                	mov    %esi,%edx
f0103210:	2b 15 cc fe 17 f0    	sub    0xf017fecc,%edx
f0103216:	c1 fa 03             	sar    $0x3,%edx
f0103219:	c1 e2 0c             	shl    $0xc,%edx
f010321c:	39 d1                	cmp    %edx,%ecx
f010321e:	74 24                	je     f0103244 <mem_init+0x1ab4>
f0103220:	c7 44 24 0c 90 58 10 	movl   $0xf0105890,0xc(%esp)
f0103227:	f0 
f0103228:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f010322f:	f0 
f0103230:	c7 44 24 04 e4 03 00 	movl   $0x3e4,0x4(%esp)
f0103237:	00 
f0103238:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f010323f:	e8 7a ce ff ff       	call   f01000be <_panic>
	kern_pgdir[0] = 0;
f0103244:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f010324a:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010324f:	74 24                	je     f0103275 <mem_init+0x1ae5>
f0103251:	c7 44 24 0c 80 5f 10 	movl   $0xf0105f80,0xc(%esp)
f0103258:	f0 
f0103259:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0103260:	f0 
f0103261:	c7 44 24 04 e6 03 00 	movl   $0x3e6,0x4(%esp)
f0103268:	00 
f0103269:	c7 04 24 a1 5d 10 f0 	movl   $0xf0105da1,(%esp)
f0103270:	e8 49 ce ff ff       	call   f01000be <_panic>
	pp0->pp_ref = 0;
f0103275:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f010327b:	89 34 24             	mov    %esi,(%esp)
f010327e:	e8 06 e2 ff ff       	call   f0101489 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0103283:	c7 04 24 40 5d 10 f0 	movl   $0xf0105d40,(%esp)
f010328a:	e8 2b 05 00 00       	call   f01037ba <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f010328f:	83 c4 3c             	add    $0x3c,%esp
f0103292:	5b                   	pop    %ebx
f0103293:	5e                   	pop    %esi
f0103294:	5f                   	pop    %edi
f0103295:	5d                   	pop    %ebp
f0103296:	c3                   	ret    
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0103297:	89 f2                	mov    %esi,%edx
f0103299:	89 d8                	mov    %ebx,%eax
f010329b:	e8 82 dc ff ff       	call   f0100f22 <check_va2pa>
f01032a0:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01032a6:	e9 8e fa ff ff       	jmp    f0102d39 <mem_init+0x15a9>

f01032ab <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f01032ab:	55                   	push   %ebp
f01032ac:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.

	return 0;
}
f01032ae:	b8 00 00 00 00       	mov    $0x0,%eax
f01032b3:	5d                   	pop    %ebp
f01032b4:	c3                   	ret    

f01032b5 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f01032b5:	55                   	push   %ebp
f01032b6:	89 e5                	mov    %esp,%ebp
f01032b8:	53                   	push   %ebx
f01032b9:	83 ec 14             	sub    $0x14,%esp
f01032bc:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f01032bf:	8b 45 14             	mov    0x14(%ebp),%eax
f01032c2:	83 c8 04             	or     $0x4,%eax
f01032c5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01032c9:	8b 45 10             	mov    0x10(%ebp),%eax
f01032cc:	89 44 24 08          	mov    %eax,0x8(%esp)
f01032d0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01032d3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01032d7:	89 1c 24             	mov    %ebx,(%esp)
f01032da:	e8 cc ff ff ff       	call   f01032ab <user_mem_check>
f01032df:	85 c0                	test   %eax,%eax
f01032e1:	79 23                	jns    f0103306 <user_mem_assert+0x51>
		cprintf("[%08x] user_mem_check assertion failure for "
f01032e3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01032ea:	00 
f01032eb:	8b 43 48             	mov    0x48(%ebx),%eax
f01032ee:	89 44 24 04          	mov    %eax,0x4(%esp)
f01032f2:	c7 04 24 6c 5d 10 f0 	movl   $0xf0105d6c,(%esp)
f01032f9:	e8 bc 04 00 00       	call   f01037ba <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f01032fe:	89 1c 24             	mov    %ebx,(%esp)
f0103301:	e8 ca 03 00 00       	call   f01036d0 <env_destroy>
	}
}
f0103306:	83 c4 14             	add    $0x14,%esp
f0103309:	5b                   	pop    %ebx
f010330a:	5d                   	pop    %ebp
f010330b:	c3                   	ret    

f010330c <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f010330c:	55                   	push   %ebp
f010330d:	89 e5                	mov    %esp,%ebp
f010330f:	53                   	push   %ebx
f0103310:	8b 45 08             	mov    0x8(%ebp),%eax
f0103313:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0103316:	85 c0                	test   %eax,%eax
f0103318:	75 0e                	jne    f0103328 <envid2env+0x1c>
		*env_store = curenv;
f010331a:	a1 24 f2 17 f0       	mov    0xf017f224,%eax
f010331f:	89 01                	mov    %eax,(%ecx)
		return 0;
f0103321:	b8 00 00 00 00       	mov    $0x0,%eax
f0103326:	eb 57                	jmp    f010337f <envid2env+0x73>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0103328:	89 c2                	mov    %eax,%edx
f010332a:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0103330:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103333:	c1 e2 05             	shl    $0x5,%edx
f0103336:	03 15 28 f2 17 f0    	add    0xf017f228,%edx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f010333c:	83 7a 54 00          	cmpl   $0x0,0x54(%edx)
f0103340:	74 05                	je     f0103347 <envid2env+0x3b>
f0103342:	39 42 48             	cmp    %eax,0x48(%edx)
f0103345:	74 0d                	je     f0103354 <envid2env+0x48>
		*env_store = 0;
f0103347:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		return -E_BAD_ENV;
f010334d:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103352:	eb 2b                	jmp    f010337f <envid2env+0x73>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0103354:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0103358:	74 1e                	je     f0103378 <envid2env+0x6c>
f010335a:	a1 24 f2 17 f0       	mov    0xf017f224,%eax
f010335f:	39 c2                	cmp    %eax,%edx
f0103361:	74 15                	je     f0103378 <envid2env+0x6c>
f0103363:	8b 58 48             	mov    0x48(%eax),%ebx
f0103366:	39 5a 4c             	cmp    %ebx,0x4c(%edx)
f0103369:	74 0d                	je     f0103378 <envid2env+0x6c>
		*env_store = 0;
f010336b:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		return -E_BAD_ENV;
f0103371:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103376:	eb 07                	jmp    f010337f <envid2env+0x73>
	}

	*env_store = e;
f0103378:	89 11                	mov    %edx,(%ecx)
	return 0;
f010337a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010337f:	5b                   	pop    %ebx
f0103380:	5d                   	pop    %ebp
f0103381:	c3                   	ret    

f0103382 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0103382:	55                   	push   %ebp
f0103383:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f0103385:	b8 00 c3 11 f0       	mov    $0xf011c300,%eax
f010338a:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f010338d:	b8 23 00 00 00       	mov    $0x23,%eax
f0103392:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f0103394:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f0103396:	b0 10                	mov    $0x10,%al
f0103398:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f010339a:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f010339c:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f010339e:	ea a5 33 10 f0 08 00 	ljmp   $0x8,$0xf01033a5
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f01033a5:	b0 00                	mov    $0x0,%al
f01033a7:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f01033aa:	5d                   	pop    %ebp
f01033ab:	c3                   	ret    

f01033ac <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f01033ac:	55                   	push   %ebp
f01033ad:	89 e5                	mov    %esp,%ebp
	// Set up envs array
	// LAB 3: Your code here.

	// Per-CPU part of the initialization
	env_init_percpu();
f01033af:	e8 ce ff ff ff       	call   f0103382 <env_init_percpu>
}
f01033b4:	5d                   	pop    %ebp
f01033b5:	c3                   	ret    

f01033b6 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f01033b6:	55                   	push   %ebp
f01033b7:	89 e5                	mov    %esp,%ebp
f01033b9:	53                   	push   %ebx
f01033ba:	83 ec 14             	sub    $0x14,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f01033bd:	8b 1d 2c f2 17 f0    	mov    0xf017f22c,%ebx
f01033c3:	85 db                	test   %ebx,%ebx
f01033c5:	0f 84 06 01 00 00    	je     f01034d1 <env_alloc+0x11b>
{
	int i;
	struct Page *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f01033cb:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01033d2:	e8 25 e0 ff ff       	call   f01013fc <page_alloc>
f01033d7:	85 c0                	test   %eax,%eax
f01033d9:	0f 84 f9 00 00 00    	je     f01034d8 <env_alloc+0x122>

	// LAB 3: Your code here.

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f01033df:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01033e2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01033e7:	77 20                	ja     f0103409 <env_alloc+0x53>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01033e9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01033ed:	c7 44 24 08 38 57 10 	movl   $0xf0105738,0x8(%esp)
f01033f4:	f0 
f01033f5:	c7 44 24 04 b9 00 00 	movl   $0xb9,0x4(%esp)
f01033fc:	00 
f01033fd:	c7 04 24 9a 60 10 f0 	movl   $0xf010609a,(%esp)
f0103404:	e8 b5 cc ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103409:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010340f:	83 ca 05             	or     $0x5,%edx
f0103412:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0103418:	8b 43 48             	mov    0x48(%ebx),%eax
f010341b:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0103420:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0103425:	ba 00 10 00 00       	mov    $0x1000,%edx
f010342a:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f010342d:	89 da                	mov    %ebx,%edx
f010342f:	2b 15 28 f2 17 f0    	sub    0xf017f228,%edx
f0103435:	c1 fa 05             	sar    $0x5,%edx
f0103438:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f010343e:	09 d0                	or     %edx,%eax
f0103440:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0103443:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103446:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0103449:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0103450:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
	e->env_runs = 0;
f0103457:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f010345e:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f0103465:	00 
f0103466:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010346d:	00 
f010346e:	89 1c 24             	mov    %ebx,(%esp)
f0103471:	e8 2b 14 00 00       	call   f01048a1 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0103476:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f010347c:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0103482:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0103488:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f010348f:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0103495:	8b 43 44             	mov    0x44(%ebx),%eax
f0103498:	a3 2c f2 17 f0       	mov    %eax,0xf017f22c
	*newenv_store = e;
f010349d:	8b 45 08             	mov    0x8(%ebp),%eax
f01034a0:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01034a2:	8b 4b 48             	mov    0x48(%ebx),%ecx
f01034a5:	a1 24 f2 17 f0       	mov    0xf017f224,%eax
f01034aa:	ba 00 00 00 00       	mov    $0x0,%edx
f01034af:	85 c0                	test   %eax,%eax
f01034b1:	74 03                	je     f01034b6 <env_alloc+0x100>
f01034b3:	8b 50 48             	mov    0x48(%eax),%edx
f01034b6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01034ba:	89 54 24 04          	mov    %edx,0x4(%esp)
f01034be:	c7 04 24 a5 60 10 f0 	movl   $0xf01060a5,(%esp)
f01034c5:	e8 f0 02 00 00       	call   f01037ba <cprintf>
	return 0;
f01034ca:	b8 00 00 00 00       	mov    $0x0,%eax
f01034cf:	eb 0c                	jmp    f01034dd <env_alloc+0x127>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f01034d1:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f01034d6:	eb 05                	jmp    f01034dd <env_alloc+0x127>
	int i;
	struct Page *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f01034d8:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f01034dd:	83 c4 14             	add    $0x14,%esp
f01034e0:	5b                   	pop    %ebx
f01034e1:	5d                   	pop    %ebp
f01034e2:	c3                   	ret    

f01034e3 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, size_t size, enum EnvType type)
{
f01034e3:	55                   	push   %ebp
f01034e4:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.
}
f01034e6:	5d                   	pop    %ebp
f01034e7:	c3                   	ret    

f01034e8 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01034e8:	55                   	push   %ebp
f01034e9:	89 e5                	mov    %esp,%ebp
f01034eb:	57                   	push   %edi
f01034ec:	56                   	push   %esi
f01034ed:	53                   	push   %ebx
f01034ee:	83 ec 2c             	sub    $0x2c,%esp
f01034f1:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01034f4:	a1 24 f2 17 f0       	mov    0xf017f224,%eax
f01034f9:	39 c7                	cmp    %eax,%edi
f01034fb:	75 37                	jne    f0103534 <env_free+0x4c>
		lcr3(PADDR(kern_pgdir));
f01034fd:	8b 15 c8 fe 17 f0    	mov    0xf017fec8,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103503:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0103509:	77 20                	ja     f010352b <env_free+0x43>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010350b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010350f:	c7 44 24 08 38 57 10 	movl   $0xf0105738,0x8(%esp)
f0103516:	f0 
f0103517:	c7 44 24 04 68 01 00 	movl   $0x168,0x4(%esp)
f010351e:	00 
f010351f:	c7 04 24 9a 60 10 f0 	movl   $0xf010609a,(%esp)
f0103526:	e8 93 cb ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f010352b:	81 c2 00 00 00 10    	add    $0x10000000,%edx
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0103531:	0f 22 da             	mov    %edx,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103534:	8b 4f 48             	mov    0x48(%edi),%ecx
f0103537:	ba 00 00 00 00       	mov    $0x0,%edx
f010353c:	85 c0                	test   %eax,%eax
f010353e:	74 03                	je     f0103543 <env_free+0x5b>
f0103540:	8b 50 48             	mov    0x48(%eax),%edx
f0103543:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103547:	89 54 24 04          	mov    %edx,0x4(%esp)
f010354b:	c7 04 24 ba 60 10 f0 	movl   $0xf01060ba,(%esp)
f0103552:	e8 63 02 00 00       	call   f01037ba <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103557:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f010355e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103561:	c1 e0 02             	shl    $0x2,%eax
f0103564:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103567:	8b 47 5c             	mov    0x5c(%edi),%eax
f010356a:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010356d:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0103570:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103576:	0f 84 b8 00 00 00    	je     f0103634 <env_free+0x14c>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f010357c:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103582:	89 f0                	mov    %esi,%eax
f0103584:	c1 e8 0c             	shr    $0xc,%eax
f0103587:	89 45 dc             	mov    %eax,-0x24(%ebp)
f010358a:	3b 05 c4 fe 17 f0    	cmp    0xf017fec4,%eax
f0103590:	72 20                	jb     f01035b2 <env_free+0xca>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103592:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103596:	c7 44 24 08 dc 52 10 	movl   $0xf01052dc,0x8(%esp)
f010359d:	f0 
f010359e:	c7 44 24 04 77 01 00 	movl   $0x177,0x4(%esp)
f01035a5:	00 
f01035a6:	c7 04 24 9a 60 10 f0 	movl   $0xf010609a,(%esp)
f01035ad:	e8 0c cb ff ff       	call   f01000be <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01035b2:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01035b5:	c1 e2 16             	shl    $0x16,%edx
f01035b8:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01035bb:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f01035c0:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f01035c7:	01 
f01035c8:	74 17                	je     f01035e1 <env_free+0xf9>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01035ca:	89 d8                	mov    %ebx,%eax
f01035cc:	c1 e0 0c             	shl    $0xc,%eax
f01035cf:	0b 45 e4             	or     -0x1c(%ebp),%eax
f01035d2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01035d6:	8b 47 5c             	mov    0x5c(%edi),%eax
f01035d9:	89 04 24             	mov    %eax,(%esp)
f01035dc:	e8 b1 e0 ff ff       	call   f0101692 <page_remove>
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01035e1:	83 c3 01             	add    $0x1,%ebx
f01035e4:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f01035ea:	75 d4                	jne    f01035c0 <env_free+0xd8>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f01035ec:	8b 47 5c             	mov    0x5c(%edi),%eax
f01035ef:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01035f2:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01035f9:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01035fc:	3b 05 c4 fe 17 f0    	cmp    0xf017fec4,%eax
f0103602:	72 1c                	jb     f0103620 <env_free+0x138>
		panic("pa2page called with invalid pa");
f0103604:	c7 44 24 08 5c 57 10 	movl   $0xf010575c,0x8(%esp)
f010360b:	f0 
f010360c:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0103613:	00 
f0103614:	c7 04 24 ad 5d 10 f0 	movl   $0xf0105dad,(%esp)
f010361b:	e8 9e ca ff ff       	call   f01000be <_panic>
	return &pages[PGNUM(pa)];
f0103620:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103623:	c1 e0 03             	shl    $0x3,%eax
f0103626:	03 05 cc fe 17 f0    	add    0xf017fecc,%eax
		page_decref(pa2page(pa));
f010362c:	89 04 24             	mov    %eax,(%esp)
f010362f:	e8 6a de ff ff       	call   f010149e <page_decref>
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103634:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0103638:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f010363f:	0f 85 19 ff ff ff    	jne    f010355e <env_free+0x76>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103645:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103648:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010364d:	77 20                	ja     f010366f <env_free+0x187>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010364f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103653:	c7 44 24 08 38 57 10 	movl   $0xf0105738,0x8(%esp)
f010365a:	f0 
f010365b:	c7 44 24 04 85 01 00 	movl   $0x185,0x4(%esp)
f0103662:	00 
f0103663:	c7 04 24 9a 60 10 f0 	movl   $0xf010609a,(%esp)
f010366a:	e8 4f ca ff ff       	call   f01000be <_panic>
	e->env_pgdir = 0;
f010366f:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
	return (physaddr_t)kva - KERNBASE;
f0103676:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010367b:	c1 e8 0c             	shr    $0xc,%eax
f010367e:	3b 05 c4 fe 17 f0    	cmp    0xf017fec4,%eax
f0103684:	72 1c                	jb     f01036a2 <env_free+0x1ba>
		panic("pa2page called with invalid pa");
f0103686:	c7 44 24 08 5c 57 10 	movl   $0xf010575c,0x8(%esp)
f010368d:	f0 
f010368e:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0103695:	00 
f0103696:	c7 04 24 ad 5d 10 f0 	movl   $0xf0105dad,(%esp)
f010369d:	e8 1c ca ff ff       	call   f01000be <_panic>
	return &pages[PGNUM(pa)];
f01036a2:	c1 e0 03             	shl    $0x3,%eax
f01036a5:	03 05 cc fe 17 f0    	add    0xf017fecc,%eax
	page_decref(pa2page(pa));
f01036ab:	89 04 24             	mov    %eax,(%esp)
f01036ae:	e8 eb dd ff ff       	call   f010149e <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f01036b3:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f01036ba:	a1 2c f2 17 f0       	mov    0xf017f22c,%eax
f01036bf:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f01036c2:	89 3d 2c f2 17 f0    	mov    %edi,0xf017f22c
}
f01036c8:	83 c4 2c             	add    $0x2c,%esp
f01036cb:	5b                   	pop    %ebx
f01036cc:	5e                   	pop    %esi
f01036cd:	5f                   	pop    %edi
f01036ce:	5d                   	pop    %ebp
f01036cf:	c3                   	ret    

f01036d0 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f01036d0:	55                   	push   %ebp
f01036d1:	89 e5                	mov    %esp,%ebp
f01036d3:	83 ec 18             	sub    $0x18,%esp
	env_free(e);
f01036d6:	8b 45 08             	mov    0x8(%ebp),%eax
f01036d9:	89 04 24             	mov    %eax,(%esp)
f01036dc:	e8 07 fe ff ff       	call   f01034e8 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f01036e1:	c7 04 24 64 60 10 f0 	movl   $0xf0106064,(%esp)
f01036e8:	e8 cd 00 00 00       	call   f01037ba <cprintf>
	while (1)
		monitor(NULL);
f01036ed:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01036f4:	e8 b0 d6 ff ff       	call   f0100da9 <monitor>
f01036f9:	eb f2                	jmp    f01036ed <env_destroy+0x1d>

f01036fb <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01036fb:	55                   	push   %ebp
f01036fc:	89 e5                	mov    %esp,%ebp
f01036fe:	83 ec 18             	sub    $0x18,%esp
	__asm __volatile("movl %0,%%esp\n"
f0103701:	8b 65 08             	mov    0x8(%ebp),%esp
f0103704:	61                   	popa   
f0103705:	07                   	pop    %es
f0103706:	1f                   	pop    %ds
f0103707:	83 c4 08             	add    $0x8,%esp
f010370a:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f010370b:	c7 44 24 08 d0 60 10 	movl   $0xf01060d0,0x8(%esp)
f0103712:	f0 
f0103713:	c7 44 24 04 ad 01 00 	movl   $0x1ad,0x4(%esp)
f010371a:	00 
f010371b:	c7 04 24 9a 60 10 f0 	movl   $0xf010609a,(%esp)
f0103722:	e8 97 c9 ff ff       	call   f01000be <_panic>

f0103727 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103727:	55                   	push   %ebp
f0103728:	89 e5                	mov    %esp,%ebp
f010372a:	83 ec 18             	sub    $0x18,%esp
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.

	panic("env_run not yet implemented");
f010372d:	c7 44 24 08 dc 60 10 	movl   $0xf01060dc,0x8(%esp)
f0103734:	f0 
f0103735:	c7 44 24 04 cc 01 00 	movl   $0x1cc,0x4(%esp)
f010373c:	00 
f010373d:	c7 04 24 9a 60 10 f0 	movl   $0xf010609a,(%esp)
f0103744:	e8 75 c9 ff ff       	call   f01000be <_panic>
f0103749:	00 00                	add    %al,(%eax)
	...

f010374c <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f010374c:	55                   	push   %ebp
f010374d:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010374f:	ba 70 00 00 00       	mov    $0x70,%edx
f0103754:	8b 45 08             	mov    0x8(%ebp),%eax
f0103757:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103758:	b2 71                	mov    $0x71,%dl
f010375a:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f010375b:	0f b6 c0             	movzbl %al,%eax
}
f010375e:	5d                   	pop    %ebp
f010375f:	c3                   	ret    

f0103760 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103760:	55                   	push   %ebp
f0103761:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103763:	ba 70 00 00 00       	mov    $0x70,%edx
f0103768:	8b 45 08             	mov    0x8(%ebp),%eax
f010376b:	ee                   	out    %al,(%dx)
f010376c:	b2 71                	mov    $0x71,%dl
f010376e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103771:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103772:	5d                   	pop    %ebp
f0103773:	c3                   	ret    

f0103774 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103774:	55                   	push   %ebp
f0103775:	89 e5                	mov    %esp,%ebp
f0103777:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f010377a:	8b 45 08             	mov    0x8(%ebp),%eax
f010377d:	89 04 24             	mov    %eax,(%esp)
f0103780:	e8 9c ce ff ff       	call   f0100621 <cputchar>
	*cnt++;
}
f0103785:	c9                   	leave  
f0103786:	c3                   	ret    

f0103787 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103787:	55                   	push   %ebp
f0103788:	89 e5                	mov    %esp,%ebp
f010378a:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f010378d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103794:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103797:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010379b:	8b 45 08             	mov    0x8(%ebp),%eax
f010379e:	89 44 24 08          	mov    %eax,0x8(%esp)
f01037a2:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01037a5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01037a9:	c7 04 24 74 37 10 f0 	movl   $0xf0103774,(%esp)
f01037b0:	e8 25 09 00 00       	call   f01040da <vprintfmt>
	return cnt;
}
f01037b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01037b8:	c9                   	leave  
f01037b9:	c3                   	ret    

f01037ba <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01037ba:	55                   	push   %ebp
f01037bb:	89 e5                	mov    %esp,%ebp
f01037bd:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01037c0:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01037c3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01037c7:	8b 45 08             	mov    0x8(%ebp),%eax
f01037ca:	89 04 24             	mov    %eax,(%esp)
f01037cd:	e8 b5 ff ff ff       	call   f0103787 <vcprintf>
	va_end(ap);

	return cnt;
}
f01037d2:	c9                   	leave  
f01037d3:	c3                   	ret    

f01037d4 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f01037d4:	55                   	push   %ebp
f01037d5:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f01037d7:	c7 05 44 fa 17 f0 00 	movl   $0xefc00000,0xf017fa44
f01037de:	00 c0 ef 
	ts.ts_ss0 = GD_KD;
f01037e1:	66 c7 05 48 fa 17 f0 	movw   $0x10,0xf017fa48
f01037e8:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f01037ea:	66 c7 05 48 c3 11 f0 	movw   $0x68,0xf011c348
f01037f1:	68 00 
f01037f3:	b8 40 fa 17 f0       	mov    $0xf017fa40,%eax
f01037f8:	66 a3 4a c3 11 f0    	mov    %ax,0xf011c34a
f01037fe:	89 c2                	mov    %eax,%edx
f0103800:	c1 ea 10             	shr    $0x10,%edx
f0103803:	88 15 4c c3 11 f0    	mov    %dl,0xf011c34c
f0103809:	c6 05 4e c3 11 f0 40 	movb   $0x40,0xf011c34e
f0103810:	c1 e8 18             	shr    $0x18,%eax
f0103813:	a2 4f c3 11 f0       	mov    %al,0xf011c34f
					sizeof(struct Taskstate), 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0103818:	c6 05 4d c3 11 f0 89 	movb   $0x89,0xf011c34d
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f010381f:	b8 28 00 00 00       	mov    $0x28,%eax
f0103824:	0f 00 d8             	ltr    %ax
}  

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f0103827:	b8 50 c3 11 f0       	mov    $0xf011c350,%eax
f010382c:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f010382f:	5d                   	pop    %ebp
f0103830:	c3                   	ret    

f0103831 <trap_init>:
}


void
trap_init(void)
{
f0103831:	55                   	push   %ebp
f0103832:	89 e5                	mov    %esp,%ebp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.

	// Per-CPU setup 
	trap_init_percpu();
f0103834:	e8 9b ff ff ff       	call   f01037d4 <trap_init_percpu>
}
f0103839:	5d                   	pop    %ebp
f010383a:	c3                   	ret    

f010383b <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f010383b:	55                   	push   %ebp
f010383c:	89 e5                	mov    %esp,%ebp
f010383e:	53                   	push   %ebx
f010383f:	83 ec 14             	sub    $0x14,%esp
f0103842:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103845:	8b 03                	mov    (%ebx),%eax
f0103847:	89 44 24 04          	mov    %eax,0x4(%esp)
f010384b:	c7 04 24 f8 60 10 f0 	movl   $0xf01060f8,(%esp)
f0103852:	e8 63 ff ff ff       	call   f01037ba <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103857:	8b 43 04             	mov    0x4(%ebx),%eax
f010385a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010385e:	c7 04 24 07 61 10 f0 	movl   $0xf0106107,(%esp)
f0103865:	e8 50 ff ff ff       	call   f01037ba <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f010386a:	8b 43 08             	mov    0x8(%ebx),%eax
f010386d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103871:	c7 04 24 16 61 10 f0 	movl   $0xf0106116,(%esp)
f0103878:	e8 3d ff ff ff       	call   f01037ba <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f010387d:	8b 43 0c             	mov    0xc(%ebx),%eax
f0103880:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103884:	c7 04 24 25 61 10 f0 	movl   $0xf0106125,(%esp)
f010388b:	e8 2a ff ff ff       	call   f01037ba <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103890:	8b 43 10             	mov    0x10(%ebx),%eax
f0103893:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103897:	c7 04 24 34 61 10 f0 	movl   $0xf0106134,(%esp)
f010389e:	e8 17 ff ff ff       	call   f01037ba <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f01038a3:	8b 43 14             	mov    0x14(%ebx),%eax
f01038a6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01038aa:	c7 04 24 43 61 10 f0 	movl   $0xf0106143,(%esp)
f01038b1:	e8 04 ff ff ff       	call   f01037ba <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f01038b6:	8b 43 18             	mov    0x18(%ebx),%eax
f01038b9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01038bd:	c7 04 24 52 61 10 f0 	movl   $0xf0106152,(%esp)
f01038c4:	e8 f1 fe ff ff       	call   f01037ba <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f01038c9:	8b 43 1c             	mov    0x1c(%ebx),%eax
f01038cc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01038d0:	c7 04 24 61 61 10 f0 	movl   $0xf0106161,(%esp)
f01038d7:	e8 de fe ff ff       	call   f01037ba <cprintf>
}
f01038dc:	83 c4 14             	add    $0x14,%esp
f01038df:	5b                   	pop    %ebx
f01038e0:	5d                   	pop    %ebp
f01038e1:	c3                   	ret    

f01038e2 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f01038e2:	55                   	push   %ebp
f01038e3:	89 e5                	mov    %esp,%ebp
f01038e5:	56                   	push   %esi
f01038e6:	53                   	push   %ebx
f01038e7:	83 ec 10             	sub    $0x10,%esp
f01038ea:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f01038ed:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01038f1:	c7 04 24 97 62 10 f0 	movl   $0xf0106297,(%esp)
f01038f8:	e8 bd fe ff ff       	call   f01037ba <cprintf>
	print_regs(&tf->tf_regs);
f01038fd:	89 1c 24             	mov    %ebx,(%esp)
f0103900:	e8 36 ff ff ff       	call   f010383b <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103905:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103909:	89 44 24 04          	mov    %eax,0x4(%esp)
f010390d:	c7 04 24 b2 61 10 f0 	movl   $0xf01061b2,(%esp)
f0103914:	e8 a1 fe ff ff       	call   f01037ba <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103919:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f010391d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103921:	c7 04 24 c5 61 10 f0 	movl   $0xf01061c5,(%esp)
f0103928:	e8 8d fe ff ff       	call   f01037ba <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f010392d:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0103930:	83 f8 13             	cmp    $0x13,%eax
f0103933:	77 09                	ja     f010393e <print_trapframe+0x5c>
		return excnames[trapno];
f0103935:	8b 14 85 60 64 10 f0 	mov    -0xfef9ba0(,%eax,4),%edx
f010393c:	eb 10                	jmp    f010394e <print_trapframe+0x6c>
	if (trapno == T_SYSCALL)
		return "System call";
f010393e:	83 f8 30             	cmp    $0x30,%eax
f0103941:	ba 70 61 10 f0       	mov    $0xf0106170,%edx
f0103946:	b9 7c 61 10 f0       	mov    $0xf010617c,%ecx
f010394b:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f010394e:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103952:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103956:	c7 04 24 d8 61 10 f0 	movl   $0xf01061d8,(%esp)
f010395d:	e8 58 fe ff ff       	call   f01037ba <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103962:	3b 1d a8 fa 17 f0    	cmp    0xf017faa8,%ebx
f0103968:	75 19                	jne    f0103983 <print_trapframe+0xa1>
f010396a:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f010396e:	75 13                	jne    f0103983 <print_trapframe+0xa1>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103970:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103973:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103977:	c7 04 24 ea 61 10 f0 	movl   $0xf01061ea,(%esp)
f010397e:	e8 37 fe ff ff       	call   f01037ba <cprintf>
	cprintf("  err  0x%08x", tf->tf_err);
f0103983:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0103986:	89 44 24 04          	mov    %eax,0x4(%esp)
f010398a:	c7 04 24 f9 61 10 f0 	movl   $0xf01061f9,(%esp)
f0103991:	e8 24 fe ff ff       	call   f01037ba <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103996:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f010399a:	75 51                	jne    f01039ed <print_trapframe+0x10b>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f010399c:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f010399f:	89 c2                	mov    %eax,%edx
f01039a1:	83 e2 01             	and    $0x1,%edx
f01039a4:	ba 8b 61 10 f0       	mov    $0xf010618b,%edx
f01039a9:	b9 96 61 10 f0       	mov    $0xf0106196,%ecx
f01039ae:	0f 45 ca             	cmovne %edx,%ecx
f01039b1:	89 c2                	mov    %eax,%edx
f01039b3:	83 e2 02             	and    $0x2,%edx
f01039b6:	ba a2 61 10 f0       	mov    $0xf01061a2,%edx
f01039bb:	be a8 61 10 f0       	mov    $0xf01061a8,%esi
f01039c0:	0f 44 d6             	cmove  %esi,%edx
f01039c3:	83 e0 04             	and    $0x4,%eax
f01039c6:	b8 ad 61 10 f0       	mov    $0xf01061ad,%eax
f01039cb:	be c2 62 10 f0       	mov    $0xf01062c2,%esi
f01039d0:	0f 44 c6             	cmove  %esi,%eax
f01039d3:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01039d7:	89 54 24 08          	mov    %edx,0x8(%esp)
f01039db:	89 44 24 04          	mov    %eax,0x4(%esp)
f01039df:	c7 04 24 07 62 10 f0 	movl   $0xf0106207,(%esp)
f01039e6:	e8 cf fd ff ff       	call   f01037ba <cprintf>
f01039eb:	eb 0c                	jmp    f01039f9 <print_trapframe+0x117>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f01039ed:	c7 04 24 31 60 10 f0 	movl   $0xf0106031,(%esp)
f01039f4:	e8 c1 fd ff ff       	call   f01037ba <cprintf>
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f01039f9:	8b 43 30             	mov    0x30(%ebx),%eax
f01039fc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a00:	c7 04 24 16 62 10 f0 	movl   $0xf0106216,(%esp)
f0103a07:	e8 ae fd ff ff       	call   f01037ba <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103a0c:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103a10:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a14:	c7 04 24 25 62 10 f0 	movl   $0xf0106225,(%esp)
f0103a1b:	e8 9a fd ff ff       	call   f01037ba <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103a20:	8b 43 38             	mov    0x38(%ebx),%eax
f0103a23:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a27:	c7 04 24 38 62 10 f0 	movl   $0xf0106238,(%esp)
f0103a2e:	e8 87 fd ff ff       	call   f01037ba <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103a33:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103a37:	74 27                	je     f0103a60 <print_trapframe+0x17e>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103a39:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103a3c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a40:	c7 04 24 47 62 10 f0 	movl   $0xf0106247,(%esp)
f0103a47:	e8 6e fd ff ff       	call   f01037ba <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103a4c:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103a50:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a54:	c7 04 24 56 62 10 f0 	movl   $0xf0106256,(%esp)
f0103a5b:	e8 5a fd ff ff       	call   f01037ba <cprintf>
	}
}
f0103a60:	83 c4 10             	add    $0x10,%esp
f0103a63:	5b                   	pop    %ebx
f0103a64:	5e                   	pop    %esi
f0103a65:	5d                   	pop    %ebp
f0103a66:	c3                   	ret    

f0103a67 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103a67:	55                   	push   %ebp
f0103a68:	89 e5                	mov    %esp,%ebp
f0103a6a:	57                   	push   %edi
f0103a6b:	56                   	push   %esi
f0103a6c:	83 ec 10             	sub    $0x10,%esp
f0103a6f:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103a72:	fc                   	cld    

static __inline uint32_t
read_eflags(void)
{
        uint32_t eflags;
        __asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0103a73:	9c                   	pushf  
f0103a74:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103a75:	f6 c4 02             	test   $0x2,%ah
f0103a78:	74 24                	je     f0103a9e <trap+0x37>
f0103a7a:	c7 44 24 0c 69 62 10 	movl   $0xf0106269,0xc(%esp)
f0103a81:	f0 
f0103a82:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0103a89:	f0 
f0103a8a:	c7 44 24 04 a7 00 00 	movl   $0xa7,0x4(%esp)
f0103a91:	00 
f0103a92:	c7 04 24 82 62 10 f0 	movl   $0xf0106282,(%esp)
f0103a99:	e8 20 c6 ff ff       	call   f01000be <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0103a9e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103aa2:	c7 04 24 8e 62 10 f0 	movl   $0xf010628e,(%esp)
f0103aa9:	e8 0c fd ff ff       	call   f01037ba <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103aae:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103ab2:	83 e0 03             	and    $0x3,%eax
f0103ab5:	83 f8 03             	cmp    $0x3,%eax
f0103ab8:	75 3c                	jne    f0103af6 <trap+0x8f>
		// Trapped from user mode.
		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		assert(curenv);
f0103aba:	a1 24 f2 17 f0       	mov    0xf017f224,%eax
f0103abf:	85 c0                	test   %eax,%eax
f0103ac1:	75 24                	jne    f0103ae7 <trap+0x80>
f0103ac3:	c7 44 24 0c a9 62 10 	movl   $0xf01062a9,0xc(%esp)
f0103aca:	f0 
f0103acb:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0103ad2:	f0 
f0103ad3:	c7 44 24 04 b0 00 00 	movl   $0xb0,0x4(%esp)
f0103ada:	00 
f0103adb:	c7 04 24 82 62 10 f0 	movl   $0xf0106282,(%esp)
f0103ae2:	e8 d7 c5 ff ff       	call   f01000be <_panic>
		curenv->env_tf = *tf;
f0103ae7:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103aec:	89 c7                	mov    %eax,%edi
f0103aee:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103af0:	8b 35 24 f2 17 f0    	mov    0xf017f224,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103af6:	89 35 a8 fa 17 f0    	mov    %esi,0xf017faa8
{
	// Handle processor exceptions.
	// LAB 3: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103afc:	89 34 24             	mov    %esi,(%esp)
f0103aff:	e8 de fd ff ff       	call   f01038e2 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103b04:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103b09:	75 1c                	jne    f0103b27 <trap+0xc0>
		panic("unhandled trap in kernel");
f0103b0b:	c7 44 24 08 b0 62 10 	movl   $0xf01062b0,0x8(%esp)
f0103b12:	f0 
f0103b13:	c7 44 24 04 96 00 00 	movl   $0x96,0x4(%esp)
f0103b1a:	00 
f0103b1b:	c7 04 24 82 62 10 f0 	movl   $0xf0106282,(%esp)
f0103b22:	e8 97 c5 ff ff       	call   f01000be <_panic>
	else {
		env_destroy(curenv);
f0103b27:	a1 24 f2 17 f0       	mov    0xf017f224,%eax
f0103b2c:	89 04 24             	mov    %eax,(%esp)
f0103b2f:	e8 9c fb ff ff       	call   f01036d0 <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0103b34:	a1 24 f2 17 f0       	mov    0xf017f224,%eax
f0103b39:	85 c0                	test   %eax,%eax
f0103b3b:	74 06                	je     f0103b43 <trap+0xdc>
f0103b3d:	83 78 54 02          	cmpl   $0x2,0x54(%eax)
f0103b41:	74 24                	je     f0103b67 <trap+0x100>
f0103b43:	c7 44 24 0c 0c 64 10 	movl   $0xf010640c,0xc(%esp)
f0103b4a:	f0 
f0103b4b:	c7 44 24 08 c7 5d 10 	movl   $0xf0105dc7,0x8(%esp)
f0103b52:	f0 
f0103b53:	c7 44 24 04 be 00 00 	movl   $0xbe,0x4(%esp)
f0103b5a:	00 
f0103b5b:	c7 04 24 82 62 10 f0 	movl   $0xf0106282,(%esp)
f0103b62:	e8 57 c5 ff ff       	call   f01000be <_panic>
	env_run(curenv);
f0103b67:	89 04 24             	mov    %eax,(%esp)
f0103b6a:	e8 b8 fb ff ff       	call   f0103727 <env_run>

f0103b6f <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103b6f:	55                   	push   %ebp
f0103b70:	89 e5                	mov    %esp,%ebp
f0103b72:	53                   	push   %ebx
f0103b73:	83 ec 14             	sub    $0x14,%esp
f0103b76:	8b 5d 08             	mov    0x8(%ebp),%ebx

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103b79:	0f 20 d0             	mov    %cr2,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103b7c:	8b 53 30             	mov    0x30(%ebx),%edx
f0103b7f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103b83:	89 44 24 08          	mov    %eax,0x8(%esp)
		curenv->env_id, fault_va, tf->tf_eip);
f0103b87:	a1 24 f2 17 f0       	mov    0xf017f224,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103b8c:	8b 40 48             	mov    0x48(%eax),%eax
f0103b8f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b93:	c7 04 24 38 64 10 f0 	movl   $0xf0106438,(%esp)
f0103b9a:	e8 1b fc ff ff       	call   f01037ba <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103b9f:	89 1c 24             	mov    %ebx,(%esp)
f0103ba2:	e8 3b fd ff ff       	call   f01038e2 <print_trapframe>
	env_destroy(curenv);
f0103ba7:	a1 24 f2 17 f0       	mov    0xf017f224,%eax
f0103bac:	89 04 24             	mov    %eax,(%esp)
f0103baf:	e8 1c fb ff ff       	call   f01036d0 <env_destroy>
}
f0103bb4:	83 c4 14             	add    $0x14,%esp
f0103bb7:	5b                   	pop    %ebx
f0103bb8:	5d                   	pop    %ebp
f0103bb9:	c3                   	ret    
	...

f0103bbc <syscall>:
f0103bbc:	55                   	push   %ebp
f0103bbd:	89 e5                	mov    %esp,%ebp
f0103bbf:	83 ec 18             	sub    $0x18,%esp
f0103bc2:	c7 44 24 08 b0 64 10 	movl   $0xf01064b0,0x8(%esp)
f0103bc9:	f0 
f0103bca:	c7 44 24 04 49 00 00 	movl   $0x49,0x4(%esp)
f0103bd1:	00 
f0103bd2:	c7 04 24 c8 64 10 f0 	movl   $0xf01064c8,(%esp)
f0103bd9:	e8 e0 c4 ff ff       	call   f01000be <_panic>
	...

f0103be0 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0103be0:	55                   	push   %ebp
f0103be1:	89 e5                	mov    %esp,%ebp
f0103be3:	57                   	push   %edi
f0103be4:	56                   	push   %esi
f0103be5:	53                   	push   %ebx
f0103be6:	83 ec 14             	sub    $0x14,%esp
f0103be9:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103bec:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0103bef:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103bf2:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0103bf5:	8b 1a                	mov    (%edx),%ebx
f0103bf7:	8b 01                	mov    (%ecx),%eax
f0103bf9:	89 45 ec             	mov    %eax,-0x14(%ebp)
	
	while (l <= r) {
f0103bfc:	39 c3                	cmp    %eax,%ebx
f0103bfe:	0f 8f 9c 00 00 00    	jg     f0103ca0 <stab_binsearch+0xc0>
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
f0103c04:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f0103c0b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103c0e:	01 d8                	add    %ebx,%eax
f0103c10:	89 c7                	mov    %eax,%edi
f0103c12:	c1 ef 1f             	shr    $0x1f,%edi
f0103c15:	01 c7                	add    %eax,%edi
f0103c17:	d1 ff                	sar    %edi
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103c19:	39 df                	cmp    %ebx,%edi
f0103c1b:	7c 33                	jl     f0103c50 <stab_binsearch+0x70>
f0103c1d:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0103c20:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0103c23:	0f b6 44 82 04       	movzbl 0x4(%edx,%eax,4),%eax
f0103c28:	39 f0                	cmp    %esi,%eax
f0103c2a:	0f 84 bc 00 00 00    	je     f0103cec <stab_binsearch+0x10c>
f0103c30:	8d 44 7f fd          	lea    -0x3(%edi,%edi,2),%eax
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0103c34:	8d 54 82 04          	lea    0x4(%edx,%eax,4),%edx
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f0103c38:	89 f8                	mov    %edi,%eax
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0103c3a:	83 e8 01             	sub    $0x1,%eax
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103c3d:	39 d8                	cmp    %ebx,%eax
f0103c3f:	7c 0f                	jl     f0103c50 <stab_binsearch+0x70>
f0103c41:	0f b6 0a             	movzbl (%edx),%ecx
f0103c44:	83 ea 0c             	sub    $0xc,%edx
f0103c47:	39 f1                	cmp    %esi,%ecx
f0103c49:	75 ef                	jne    f0103c3a <stab_binsearch+0x5a>
f0103c4b:	e9 9e 00 00 00       	jmp    f0103cee <stab_binsearch+0x10e>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0103c50:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0103c53:	eb 3c                	jmp    f0103c91 <stab_binsearch+0xb1>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0103c55:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0103c58:	89 02                	mov    %eax,(%edx)
			l = true_m + 1;
f0103c5a:	8d 5f 01             	lea    0x1(%edi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103c5d:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f0103c64:	eb 2b                	jmp    f0103c91 <stab_binsearch+0xb1>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0103c66:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0103c69:	76 14                	jbe    f0103c7f <stab_binsearch+0x9f>
			*region_right = m - 1;
f0103c6b:	83 e8 01             	sub    $0x1,%eax
f0103c6e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103c71:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103c74:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103c76:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f0103c7d:	eb 12                	jmp    f0103c91 <stab_binsearch+0xb1>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103c7f:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0103c82:	89 02                	mov    %eax,(%edx)
			l = m;
			addr++;
f0103c84:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0103c88:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103c8a:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0103c91:	39 5d ec             	cmp    %ebx,-0x14(%ebp)
f0103c94:	0f 8d 71 ff ff ff    	jge    f0103c0b <stab_binsearch+0x2b>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0103c9a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103c9e:	75 0f                	jne    f0103caf <stab_binsearch+0xcf>
		*region_right = *region_left - 1;
f0103ca0:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0103ca3:	8b 02                	mov    (%edx),%eax
f0103ca5:	83 e8 01             	sub    $0x1,%eax
f0103ca8:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103cab:	89 01                	mov    %eax,(%ecx)
f0103cad:	eb 57                	jmp    f0103d06 <stab_binsearch+0x126>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103caf:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103cb2:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103cb4:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0103cb7:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103cb9:	39 c1                	cmp    %eax,%ecx
f0103cbb:	7d 28                	jge    f0103ce5 <stab_binsearch+0x105>
		     l > *region_left && stabs[l].n_type != type;
f0103cbd:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103cc0:	8b 5d f0             	mov    -0x10(%ebp),%ebx
f0103cc3:	0f b6 54 93 04       	movzbl 0x4(%ebx,%edx,4),%edx
f0103cc8:	39 f2                	cmp    %esi,%edx
f0103cca:	74 19                	je     f0103ce5 <stab_binsearch+0x105>
f0103ccc:	8d 54 40 fd          	lea    -0x3(%eax,%eax,2),%edx
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0103cd0:	8d 54 93 04          	lea    0x4(%ebx,%edx,4),%edx
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0103cd4:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103cd7:	39 c1                	cmp    %eax,%ecx
f0103cd9:	7d 0a                	jge    f0103ce5 <stab_binsearch+0x105>
		     l > *region_left && stabs[l].n_type != type;
f0103cdb:	0f b6 1a             	movzbl (%edx),%ebx
f0103cde:	83 ea 0c             	sub    $0xc,%edx
f0103ce1:	39 f3                	cmp    %esi,%ebx
f0103ce3:	75 ef                	jne    f0103cd4 <stab_binsearch+0xf4>
		     l--)
			/* do nothing */;
		*region_left = l;
f0103ce5:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0103ce8:	89 02                	mov    %eax,(%edx)
f0103cea:	eb 1a                	jmp    f0103d06 <stab_binsearch+0x126>
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f0103cec:	89 f8                	mov    %edi,%eax
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103cee:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103cf1:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f0103cf4:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0103cf8:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0103cfb:	0f 82 54 ff ff ff    	jb     f0103c55 <stab_binsearch+0x75>
f0103d01:	e9 60 ff ff ff       	jmp    f0103c66 <stab_binsearch+0x86>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0103d06:	83 c4 14             	add    $0x14,%esp
f0103d09:	5b                   	pop    %ebx
f0103d0a:	5e                   	pop    %esi
f0103d0b:	5f                   	pop    %edi
f0103d0c:	5d                   	pop    %ebp
f0103d0d:	c3                   	ret    

f0103d0e <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103d0e:	55                   	push   %ebp
f0103d0f:	89 e5                	mov    %esp,%ebp
f0103d11:	57                   	push   %edi
f0103d12:	56                   	push   %esi
f0103d13:	53                   	push   %ebx
f0103d14:	83 ec 5c             	sub    $0x5c,%esp
f0103d17:	8b 75 08             	mov    0x8(%ebp),%esi
f0103d1a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103d1d:	c7 03 16 51 10 f0    	movl   $0xf0105116,(%ebx)
	info->eip_line = 0;
f0103d23:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0103d2a:	c7 43 08 16 51 10 f0 	movl   $0xf0105116,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0103d31:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0103d38:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0103d3b:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0103d42:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0103d48:	77 23                	ja     f0103d6d <debuginfo_eip+0x5f>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f0103d4a:	8b 3d 00 00 20 00    	mov    0x200000,%edi
f0103d50:	89 7d c4             	mov    %edi,-0x3c(%ebp)
		stab_end = usd->stab_end;
f0103d53:	8b 15 04 00 20 00    	mov    0x200004,%edx
		stabstr = usd->stabstr;
f0103d59:	8b 3d 08 00 20 00    	mov    0x200008,%edi
f0103d5f:	89 7d b8             	mov    %edi,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f0103d62:	8b 3d 0c 00 20 00    	mov    0x20000c,%edi
f0103d68:	89 7d c0             	mov    %edi,-0x40(%ebp)
f0103d6b:	eb 1a                	jmp    f0103d87 <debuginfo_eip+0x79>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0103d6d:	c7 45 c0 f7 12 11 f0 	movl   $0xf01112f7,-0x40(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0103d74:	c7 45 b8 b9 e7 10 f0 	movl   $0xf010e7b9,-0x48(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0103d7b:	ba b8 e7 10 f0       	mov    $0xf010e7b8,%edx
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0103d80:	c7 45 c4 e8 66 10 f0 	movl   $0xf01066e8,-0x3c(%ebp)
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103d87:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103d8c:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103d8f:	39 7d b8             	cmp    %edi,-0x48(%ebp)
f0103d92:	0f 83 d8 01 00 00    	jae    f0103f70 <debuginfo_eip+0x262>
f0103d98:	80 7f ff 00          	cmpb   $0x0,-0x1(%edi)
f0103d9c:	0f 85 ce 01 00 00    	jne    f0103f70 <debuginfo_eip+0x262>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103da2:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103da9:	2b 55 c4             	sub    -0x3c(%ebp),%edx
f0103dac:	c1 fa 02             	sar    $0x2,%edx
f0103daf:	69 c2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%eax
f0103db5:	83 e8 01             	sub    $0x1,%eax
f0103db8:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103dbb:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103dbf:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0103dc6:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0103dc9:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103dcc:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0103dcf:	e8 0c fe ff ff       	call   f0103be0 <stab_binsearch>
	if (lfile == 0)
f0103dd4:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0103dd7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0103ddc:	85 d2                	test   %edx,%edx
f0103dde:	0f 84 8c 01 00 00    	je     f0103f70 <debuginfo_eip+0x262>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103de4:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0103de7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103dea:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103ded:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103df1:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0103df8:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0103dfb:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103dfe:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0103e01:	e8 da fd ff ff       	call   f0103be0 <stab_binsearch>

	if (lfun <= rfun) {
f0103e06:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103e09:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103e0c:	39 d0                	cmp    %edx,%eax
f0103e0e:	7f 32                	jg     f0103e42 <debuginfo_eip+0x134>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103e10:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0103e13:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0103e16:	8d 0c 8f             	lea    (%edi,%ecx,4),%ecx
f0103e19:	8b 39                	mov    (%ecx),%edi
f0103e1b:	89 7d b4             	mov    %edi,-0x4c(%ebp)
f0103e1e:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103e21:	2b 7d b8             	sub    -0x48(%ebp),%edi
f0103e24:	39 7d b4             	cmp    %edi,-0x4c(%ebp)
f0103e27:	73 09                	jae    f0103e32 <debuginfo_eip+0x124>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103e29:	8b 7d b4             	mov    -0x4c(%ebp),%edi
f0103e2c:	03 7d b8             	add    -0x48(%ebp),%edi
f0103e2f:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103e32:	8b 49 08             	mov    0x8(%ecx),%ecx
f0103e35:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0103e38:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0103e3a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103e3d:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0103e40:	eb 0f                	jmp    f0103e51 <debuginfo_eip+0x143>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103e42:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0103e45:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103e48:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103e4b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103e4e:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103e51:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0103e58:	00 
f0103e59:	8b 43 08             	mov    0x8(%ebx),%eax
f0103e5c:	89 04 24             	mov    %eax,(%esp)
f0103e5f:	e8 16 0a 00 00       	call   f010487a <strfind>
f0103e64:	2b 43 08             	sub    0x8(%ebx),%eax
f0103e67:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103e6a:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103e6e:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0103e75:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103e78:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103e7b:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0103e7e:	e8 5d fd ff ff       	call   f0103be0 <stab_binsearch>

	
	if (lline <= rline) {
f0103e83:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103e86:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0103e89:	7f 0e                	jg     f0103e99 <debuginfo_eip+0x18b>
	info->eip_line = stabs[lline].n_desc;
f0103e8b:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103e8e:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0103e91:	0f b7 44 86 06       	movzwl 0x6(%esi,%eax,4),%eax
f0103e96:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103e99:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103e9c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103e9f:	89 7d bc             	mov    %edi,-0x44(%ebp)
f0103ea2:	39 f8                	cmp    %edi,%eax
f0103ea4:	7c 75                	jl     f0103f1b <debuginfo_eip+0x20d>
	       && stabs[lline].n_type != N_SOL
f0103ea6:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103ea9:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0103eac:	8d 34 97             	lea    (%edi,%edx,4),%esi
f0103eaf:	0f b6 4e 04          	movzbl 0x4(%esi),%ecx
f0103eb3:	80 f9 84             	cmp    $0x84,%cl
f0103eb6:	74 46                	je     f0103efe <debuginfo_eip+0x1f0>
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0103eb8:	8d 54 40 fd          	lea    -0x3(%eax,%eax,2),%edx
f0103ebc:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0103ebf:	89 c7                	mov    %eax,%edi
f0103ec1:	89 5d b4             	mov    %ebx,-0x4c(%ebp)
f0103ec4:	8b 5d bc             	mov    -0x44(%ebp),%ebx
f0103ec7:	eb 1f                	jmp    f0103ee8 <debuginfo_eip+0x1da>
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0103ec9:	83 e8 01             	sub    $0x1,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103ecc:	39 c3                	cmp    %eax,%ebx
f0103ece:	7f 48                	jg     f0103f18 <debuginfo_eip+0x20a>
	       && stabs[lline].n_type != N_SOL
f0103ed0:	89 d6                	mov    %edx,%esi
f0103ed2:	83 ea 0c             	sub    $0xc,%edx
f0103ed5:	0f b6 4a 10          	movzbl 0x10(%edx),%ecx
f0103ed9:	80 f9 84             	cmp    $0x84,%cl
f0103edc:	75 08                	jne    f0103ee6 <debuginfo_eip+0x1d8>
f0103ede:	8b 5d b4             	mov    -0x4c(%ebp),%ebx
f0103ee1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103ee4:	eb 18                	jmp    f0103efe <debuginfo_eip+0x1f0>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0103ee6:	89 c7                	mov    %eax,%edi
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103ee8:	80 f9 64             	cmp    $0x64,%cl
f0103eeb:	75 dc                	jne    f0103ec9 <debuginfo_eip+0x1bb>
f0103eed:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
f0103ef1:	74 d6                	je     f0103ec9 <debuginfo_eip+0x1bb>
f0103ef3:	8b 5d b4             	mov    -0x4c(%ebp),%ebx
f0103ef6:	89 7d d4             	mov    %edi,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103ef9:	3b 45 bc             	cmp    -0x44(%ebp),%eax
f0103efc:	7c 1d                	jl     f0103f1b <debuginfo_eip+0x20d>
f0103efe:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103f01:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0103f04:	8b 04 86             	mov    (%esi,%eax,4),%eax
f0103f07:	8b 55 c0             	mov    -0x40(%ebp),%edx
f0103f0a:	2b 55 b8             	sub    -0x48(%ebp),%edx
f0103f0d:	39 d0                	cmp    %edx,%eax
f0103f0f:	73 0a                	jae    f0103f1b <debuginfo_eip+0x20d>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103f11:	03 45 b8             	add    -0x48(%ebp),%eax
f0103f14:	89 03                	mov    %eax,(%ebx)
f0103f16:	eb 03                	jmp    f0103f1b <debuginfo_eip+0x20d>
f0103f18:	8b 5d b4             	mov    -0x4c(%ebp),%ebx
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103f1b:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0103f1e:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103f21:	89 45 bc             	mov    %eax,-0x44(%ebp)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0103f24:	b8 00 00 00 00       	mov    $0x0,%eax
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103f29:	3b 7d bc             	cmp    -0x44(%ebp),%edi
f0103f2c:	7d 42                	jge    f0103f70 <debuginfo_eip+0x262>
		for (lline = lfun + 1;
f0103f2e:	8d 57 01             	lea    0x1(%edi),%edx
f0103f31:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103f34:	39 55 bc             	cmp    %edx,-0x44(%ebp)
f0103f37:	7e 37                	jle    f0103f70 <debuginfo_eip+0x262>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103f39:	8d 0c 52             	lea    (%edx,%edx,2),%ecx
f0103f3c:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0103f3f:	80 7c 8e 04 a0       	cmpb   $0xa0,0x4(%esi,%ecx,4)
f0103f44:	75 2a                	jne    f0103f70 <debuginfo_eip+0x262>
f0103f46:	8d 04 7f             	lea    (%edi,%edi,2),%eax
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0103f49:	8d 44 86 1c          	lea    0x1c(%esi,%eax,4),%eax
f0103f4d:	8b 4d bc             	mov    -0x44(%ebp),%ecx
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0103f50:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0103f54:	83 c2 01             	add    $0x1,%edx
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103f57:	39 d1                	cmp    %edx,%ecx
f0103f59:	7e 10                	jle    f0103f6b <debuginfo_eip+0x25d>
f0103f5b:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103f5e:	80 78 f4 a0          	cmpb   $0xa0,-0xc(%eax)
f0103f62:	74 ec                	je     f0103f50 <debuginfo_eip+0x242>
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0103f64:	b8 00 00 00 00       	mov    $0x0,%eax
f0103f69:	eb 05                	jmp    f0103f70 <debuginfo_eip+0x262>
f0103f6b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103f70:	83 c4 5c             	add    $0x5c,%esp
f0103f73:	5b                   	pop    %ebx
f0103f74:	5e                   	pop    %esi
f0103f75:	5f                   	pop    %edi
f0103f76:	5d                   	pop    %ebp
f0103f77:	c3                   	ret    
	...

f0103f80 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103f80:	55                   	push   %ebp
f0103f81:	89 e5                	mov    %esp,%ebp
f0103f83:	57                   	push   %edi
f0103f84:	56                   	push   %esi
f0103f85:	53                   	push   %ebx
f0103f86:	83 ec 3c             	sub    $0x3c,%esp
f0103f89:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103f8c:	89 d7                	mov    %edx,%edi
f0103f8e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f91:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103f94:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103f97:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103f9a:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0103f9d:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103fa0:	b8 00 00 00 00       	mov    $0x0,%eax
f0103fa5:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0103fa8:	72 11                	jb     f0103fbb <printnum+0x3b>
f0103faa:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103fad:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103fb0:	76 09                	jbe    f0103fbb <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103fb2:	83 eb 01             	sub    $0x1,%ebx
f0103fb5:	85 db                	test   %ebx,%ebx
f0103fb7:	7f 51                	jg     f010400a <printnum+0x8a>
f0103fb9:	eb 5e                	jmp    f0104019 <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103fbb:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103fbf:	83 eb 01             	sub    $0x1,%ebx
f0103fc2:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103fc6:	8b 45 10             	mov    0x10(%ebp),%eax
f0103fc9:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103fcd:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0103fd1:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0103fd5:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0103fdc:	00 
f0103fdd:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103fe0:	89 04 24             	mov    %eax,(%esp)
f0103fe3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103fe6:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103fea:	e8 01 0b 00 00       	call   f0104af0 <__udivdi3>
f0103fef:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103ff3:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103ff7:	89 04 24             	mov    %eax,(%esp)
f0103ffa:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103ffe:	89 fa                	mov    %edi,%edx
f0104000:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104003:	e8 78 ff ff ff       	call   f0103f80 <printnum>
f0104008:	eb 0f                	jmp    f0104019 <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010400a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010400e:	89 34 24             	mov    %esi,(%esp)
f0104011:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0104014:	83 eb 01             	sub    $0x1,%ebx
f0104017:	75 f1                	jne    f010400a <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0104019:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010401d:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0104021:	8b 45 10             	mov    0x10(%ebp),%eax
f0104024:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104028:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010402f:	00 
f0104030:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104033:	89 04 24             	mov    %eax,(%esp)
f0104036:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104039:	89 44 24 04          	mov    %eax,0x4(%esp)
f010403d:	e8 de 0b 00 00       	call   f0104c20 <__umoddi3>
f0104042:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104046:	0f be 80 d7 64 10 f0 	movsbl -0xfef9b29(%eax),%eax
f010404d:	89 04 24             	mov    %eax,(%esp)
f0104050:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0104053:	83 c4 3c             	add    $0x3c,%esp
f0104056:	5b                   	pop    %ebx
f0104057:	5e                   	pop    %esi
f0104058:	5f                   	pop    %edi
f0104059:	5d                   	pop    %ebp
f010405a:	c3                   	ret    

f010405b <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f010405b:	55                   	push   %ebp
f010405c:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f010405e:	83 fa 01             	cmp    $0x1,%edx
f0104061:	7e 0e                	jle    f0104071 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0104063:	8b 10                	mov    (%eax),%edx
f0104065:	8d 4a 08             	lea    0x8(%edx),%ecx
f0104068:	89 08                	mov    %ecx,(%eax)
f010406a:	8b 02                	mov    (%edx),%eax
f010406c:	8b 52 04             	mov    0x4(%edx),%edx
f010406f:	eb 22                	jmp    f0104093 <getuint+0x38>
	else if (lflag)
f0104071:	85 d2                	test   %edx,%edx
f0104073:	74 10                	je     f0104085 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0104075:	8b 10                	mov    (%eax),%edx
f0104077:	8d 4a 04             	lea    0x4(%edx),%ecx
f010407a:	89 08                	mov    %ecx,(%eax)
f010407c:	8b 02                	mov    (%edx),%eax
f010407e:	ba 00 00 00 00       	mov    $0x0,%edx
f0104083:	eb 0e                	jmp    f0104093 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0104085:	8b 10                	mov    (%eax),%edx
f0104087:	8d 4a 04             	lea    0x4(%edx),%ecx
f010408a:	89 08                	mov    %ecx,(%eax)
f010408c:	8b 02                	mov    (%edx),%eax
f010408e:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0104093:	5d                   	pop    %ebp
f0104094:	c3                   	ret    

f0104095 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104095:	55                   	push   %ebp
f0104096:	89 e5                	mov    %esp,%ebp
f0104098:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010409b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f010409f:	8b 10                	mov    (%eax),%edx
f01040a1:	3b 50 04             	cmp    0x4(%eax),%edx
f01040a4:	73 0a                	jae    f01040b0 <sprintputch+0x1b>
		*b->buf++ = ch;
f01040a6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01040a9:	88 0a                	mov    %cl,(%edx)
f01040ab:	83 c2 01             	add    $0x1,%edx
f01040ae:	89 10                	mov    %edx,(%eax)
}
f01040b0:	5d                   	pop    %ebp
f01040b1:	c3                   	ret    

f01040b2 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01040b2:	55                   	push   %ebp
f01040b3:	89 e5                	mov    %esp,%ebp
f01040b5:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f01040b8:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01040bb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01040bf:	8b 45 10             	mov    0x10(%ebp),%eax
f01040c2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01040c6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01040c9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01040cd:	8b 45 08             	mov    0x8(%ebp),%eax
f01040d0:	89 04 24             	mov    %eax,(%esp)
f01040d3:	e8 02 00 00 00       	call   f01040da <vprintfmt>
	va_end(ap);
}
f01040d8:	c9                   	leave  
f01040d9:	c3                   	ret    

f01040da <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01040da:	55                   	push   %ebp
f01040db:	89 e5                	mov    %esp,%ebp
f01040dd:	57                   	push   %edi
f01040de:	56                   	push   %esi
f01040df:	53                   	push   %ebx
f01040e0:	83 ec 3c             	sub    $0x3c,%esp
f01040e3:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01040e6:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f01040e9:	e9 bb 00 00 00       	jmp    f01041a9 <vprintfmt+0xcf>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01040ee:	85 c0                	test   %eax,%eax
f01040f0:	0f 84 63 04 00 00    	je     f0104559 <vprintfmt+0x47f>
				return;
			if (ch =='\033'){//if this is Escape character  and this if is char color set.
f01040f6:	83 f8 1b             	cmp    $0x1b,%eax
f01040f9:	0f 85 9a 00 00 00    	jne    f0104199 <vprintfmt+0xbf>
				int temp_color_no=0;
				ch = *(unsigned char *) fmt++;
f01040ff:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104102:	83 c3 02             	add    $0x2,%ebx
				while (ch != 'm') 
f0104105:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104108:	80 78 01 6d          	cmpb   $0x6d,0x1(%eax)
f010410c:	0f 84 81 00 00 00    	je     f0104193 <vprintfmt+0xb9>
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
				return;
			if (ch =='\033'){//if this is Escape character  and this if is char color set.
				int temp_color_no=0;
f0104112:	ba 00 00 00 00       	mov    $0x0,%edx
				ch = *(unsigned char *) fmt++;
				while (ch != 'm') 
				{
					ch = *(unsigned char *) fmt++;
f0104117:	0f b6 03             	movzbl (%ebx),%eax
f010411a:	83 c3 01             	add    $0x1,%ebx
					if ( ch !=';' && ch!='m')
f010411d:	83 f8 6d             	cmp    $0x6d,%eax
f0104120:	0f 95 c1             	setne  %cl
f0104123:	83 f8 3b             	cmp    $0x3b,%eax
f0104126:	74 0d                	je     f0104135 <vprintfmt+0x5b>
f0104128:	84 c9                	test   %cl,%cl
f010412a:	74 09                	je     f0104135 <vprintfmt+0x5b>
						temp_color_no=temp_color_no*10+ch-'0';
f010412c:	8d 14 92             	lea    (%edx,%edx,4),%edx
f010412f:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
f0104133:	eb 55                	jmp    f010418a <vprintfmt+0xb0>
					else if ( ch==';' || ch=='m'){
f0104135:	83 f8 3b             	cmp    $0x3b,%eax
f0104138:	74 05                	je     f010413f <vprintfmt+0x65>
f010413a:	83 f8 6d             	cmp    $0x6d,%eax
f010413d:	75 4b                	jne    f010418a <vprintfmt+0xb0>
						if ( temp_color_no >=30 && temp_color_no<40){// Foreground colors
f010413f:	89 d6                	mov    %edx,%esi
f0104141:	8d 7a e2             	lea    -0x1e(%edx),%edi
f0104144:	83 ff 09             	cmp    $0x9,%edi
f0104147:	77 16                	ja     f010415f <vprintfmt+0x85>
							char_color = (char_color&0xf0) + (temp_color_no-30);						
f0104149:	8b 3d 58 c3 11 f0    	mov    0xf011c358,%edi
f010414f:	81 e7 f0 00 00 00    	and    $0xf0,%edi
f0104155:	8d 7c 3a e2          	lea    -0x1e(%edx,%edi,1),%edi
f0104159:	89 3d 58 c3 11 f0    	mov    %edi,0xf011c358
							}
						if ( temp_color_no >=40 && temp_color_no<50){// Background colors
f010415f:	83 ee 28             	sub    $0x28,%esi
f0104162:	83 fe 09             	cmp    $0x9,%esi
f0104165:	77 1e                	ja     f0104185 <vprintfmt+0xab>
							char_color = (char_color&0x0f) + ((temp_color_no-40)<<4);
f0104167:	8b 35 58 c3 11 f0    	mov    0xf011c358,%esi
f010416d:	83 e6 0f             	and    $0xf,%esi
f0104170:	83 ea 28             	sub    $0x28,%edx
f0104173:	c1 e2 04             	shl    $0x4,%edx
f0104176:	01 f2                	add    %esi,%edx
f0104178:	89 15 58 c3 11 f0    	mov    %edx,0xf011c358
						}
						//cprintf("0x%o ,",char_color);
						temp_color_no=0;
f010417e:	ba 00 00 00 00       	mov    $0x0,%edx
f0104183:	eb 05                	jmp    f010418a <vprintfmt+0xb0>
f0104185:	ba 00 00 00 00       	mov    $0x0,%edx
			if (ch == '\0')
				return;
			if (ch =='\033'){//if this is Escape character  and this if is char color set.
				int temp_color_no=0;
				ch = *(unsigned char *) fmt++;
				while (ch != 'm') 
f010418a:	84 c9                	test   %cl,%cl
f010418c:	75 89                	jne    f0104117 <vprintfmt+0x3d>
						}
						//cprintf("0x%o ,",char_color);
						temp_color_no=0;
					}
				}
				if (ch == 'm')
f010418e:	83 f8 6d             	cmp    $0x6d,%eax
f0104191:	75 06                	jne    f0104199 <vprintfmt+0xbf>
					ch = *(unsigned char *) fmt++;
f0104193:	0f b6 03             	movzbl (%ebx),%eax
f0104196:	83 c3 01             	add    $0x1,%ebx
				
			}
			putch(ch, putdat);
f0104199:	8b 55 0c             	mov    0xc(%ebp),%edx
f010419c:	89 54 24 04          	mov    %edx,0x4(%esp)
f01041a0:	89 04 24             	mov    %eax,(%esp)
f01041a3:	ff 55 08             	call   *0x8(%ebp)
f01041a6:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01041a9:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01041ac:	0f b6 03             	movzbl (%ebx),%eax
f01041af:	83 c3 01             	add    $0x1,%ebx
f01041b2:	83 f8 25             	cmp    $0x25,%eax
f01041b5:	0f 85 33 ff ff ff    	jne    f01040ee <vprintfmt+0x14>
f01041bb:	c6 45 e0 20          	movb   $0x20,-0x20(%ebp)
f01041bf:	bf 00 00 00 00       	mov    $0x0,%edi
f01041c4:	be ff ff ff ff       	mov    $0xffffffff,%esi
f01041c9:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f01041d0:	b9 00 00 00 00       	mov    $0x0,%ecx
f01041d5:	eb 23                	jmp    f01041fa <vprintfmt+0x120>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01041d7:	89 c3                	mov    %eax,%ebx

		// flag to pad on the right
		case '-':
			padc = '-';
f01041d9:	c6 45 e0 2d          	movb   $0x2d,-0x20(%ebp)
f01041dd:	eb 1b                	jmp    f01041fa <vprintfmt+0x120>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01041df:	89 c3                	mov    %eax,%ebx
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01041e1:	c6 45 e0 30          	movb   $0x30,-0x20(%ebp)
f01041e5:	eb 13                	jmp    f01041fa <vprintfmt+0x120>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01041e7:	89 c3                	mov    %eax,%ebx
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f01041e9:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f01041f0:	eb 08                	jmp    f01041fa <vprintfmt+0x120>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f01041f2:	89 75 dc             	mov    %esi,-0x24(%ebp)
f01041f5:	be ff ff ff ff       	mov    $0xffffffff,%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01041fa:	0f b6 13             	movzbl (%ebx),%edx
f01041fd:	0f b6 c2             	movzbl %dl,%eax
f0104200:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104203:	8d 43 01             	lea    0x1(%ebx),%eax
f0104206:	83 ea 23             	sub    $0x23,%edx
f0104209:	80 fa 55             	cmp    $0x55,%dl
f010420c:	0f 87 18 03 00 00    	ja     f010452a <vprintfmt+0x450>
f0104212:	0f b6 d2             	movzbl %dl,%edx
f0104215:	ff 24 95 64 65 10 f0 	jmp    *-0xfef9a9c(,%edx,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f010421c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010421f:	83 ee 30             	sub    $0x30,%esi
				ch = *fmt;
f0104222:	0f be 53 01          	movsbl 0x1(%ebx),%edx
				if (ch < '0' || ch > '9')
f0104226:	8d 5a d0             	lea    -0x30(%edx),%ebx
f0104229:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010422c:	89 c3                	mov    %eax,%ebx
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f010422e:	83 7d e4 09          	cmpl   $0x9,-0x1c(%ebp)
f0104232:	77 3b                	ja     f010426f <vprintfmt+0x195>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0104234:	83 c0 01             	add    $0x1,%eax
				precision = precision * 10 + ch - '0';
f0104237:	8d 1c b6             	lea    (%esi,%esi,4),%ebx
f010423a:	8d 74 5a d0          	lea    -0x30(%edx,%ebx,2),%esi
				ch = *fmt;
f010423e:	0f be 10             	movsbl (%eax),%edx
				if (ch < '0' || ch > '9')
f0104241:	8d 5a d0             	lea    -0x30(%edx),%ebx
f0104244:	83 fb 09             	cmp    $0x9,%ebx
f0104247:	76 eb                	jbe    f0104234 <vprintfmt+0x15a>
f0104249:	eb 22                	jmp    f010426d <vprintfmt+0x193>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f010424b:	8b 55 14             	mov    0x14(%ebp),%edx
f010424e:	8d 5a 04             	lea    0x4(%edx),%ebx
f0104251:	89 5d 14             	mov    %ebx,0x14(%ebp)
f0104254:	8b 32                	mov    (%edx),%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104256:	89 c3                	mov    %eax,%ebx
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0104258:	eb 15                	jmp    f010426f <vprintfmt+0x195>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010425a:	89 c3                	mov    %eax,%ebx
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f010425c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0104260:	79 98                	jns    f01041fa <vprintfmt+0x120>
f0104262:	eb 83                	jmp    f01041e7 <vprintfmt+0x10d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104264:	89 c3                	mov    %eax,%ebx
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0104266:	bf 01 00 00 00       	mov    $0x1,%edi
			goto reswitch;
f010426b:	eb 8d                	jmp    f01041fa <vprintfmt+0x120>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f010426d:	89 c3                	mov    %eax,%ebx
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f010426f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0104273:	79 85                	jns    f01041fa <vprintfmt+0x120>
f0104275:	e9 78 ff ff ff       	jmp    f01041f2 <vprintfmt+0x118>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f010427a:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010427d:	89 c3                	mov    %eax,%ebx
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010427f:	e9 76 ff ff ff       	jmp    f01041fa <vprintfmt+0x120>
f0104284:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104287:	8b 45 14             	mov    0x14(%ebp),%eax
f010428a:	8d 50 04             	lea    0x4(%eax),%edx
f010428d:	89 55 14             	mov    %edx,0x14(%ebp)
f0104290:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104293:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104297:	8b 00                	mov    (%eax),%eax
f0104299:	89 04 24             	mov    %eax,(%esp)
f010429c:	ff 55 08             	call   *0x8(%ebp)
			break;
f010429f:	e9 05 ff ff ff       	jmp    f01041a9 <vprintfmt+0xcf>
f01042a4:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// error message
		case 'e':
			err = va_arg(ap, int);
f01042a7:	8b 45 14             	mov    0x14(%ebp),%eax
f01042aa:	8d 50 04             	lea    0x4(%eax),%edx
f01042ad:	89 55 14             	mov    %edx,0x14(%ebp)
f01042b0:	8b 00                	mov    (%eax),%eax
f01042b2:	89 c2                	mov    %eax,%edx
f01042b4:	c1 fa 1f             	sar    $0x1f,%edx
f01042b7:	31 d0                	xor    %edx,%eax
f01042b9:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01042bb:	83 f8 06             	cmp    $0x6,%eax
f01042be:	7f 0b                	jg     f01042cb <vprintfmt+0x1f1>
f01042c0:	8b 14 85 bc 66 10 f0 	mov    -0xfef9944(,%eax,4),%edx
f01042c7:	85 d2                	test   %edx,%edx
f01042c9:	75 23                	jne    f01042ee <vprintfmt+0x214>
				printfmt(putch, putdat, "error %d", err);
f01042cb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01042cf:	c7 44 24 08 ef 64 10 	movl   $0xf01064ef,0x8(%esp)
f01042d6:	f0 
f01042d7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01042da:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01042de:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01042e1:	89 1c 24             	mov    %ebx,(%esp)
f01042e4:	e8 c9 fd ff ff       	call   f01040b2 <printfmt>
f01042e9:	e9 bb fe ff ff       	jmp    f01041a9 <vprintfmt+0xcf>
			else
				printfmt(putch, putdat, "%s", p);
f01042ee:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01042f2:	c7 44 24 08 d9 5d 10 	movl   $0xf0105dd9,0x8(%esp)
f01042f9:	f0 
f01042fa:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01042fd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104301:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0104304:	89 1c 24             	mov    %ebx,(%esp)
f0104307:	e8 a6 fd ff ff       	call   f01040b2 <printfmt>
f010430c:	e9 98 fe ff ff       	jmp    f01041a9 <vprintfmt+0xcf>
f0104311:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104314:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0104317:	89 5d d8             	mov    %ebx,-0x28(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010431a:	8b 45 14             	mov    0x14(%ebp),%eax
f010431d:	8d 50 04             	lea    0x4(%eax),%edx
f0104320:	89 55 14             	mov    %edx,0x14(%ebp)
f0104323:	8b 18                	mov    (%eax),%ebx
				p = "(null)";
f0104325:	85 db                	test   %ebx,%ebx
f0104327:	b8 e8 64 10 f0       	mov    $0xf01064e8,%eax
f010432c:	0f 44 d8             	cmove  %eax,%ebx
			if (width > 0 && padc != '-')
f010432f:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0104333:	7e 06                	jle    f010433b <vprintfmt+0x261>
f0104335:	80 7d e0 2d          	cmpb   $0x2d,-0x20(%ebp)
f0104339:	75 10                	jne    f010434b <vprintfmt+0x271>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010433b:	0f be 03             	movsbl (%ebx),%eax
f010433e:	83 c3 01             	add    $0x1,%ebx
f0104341:	85 c0                	test   %eax,%eax
f0104343:	0f 85 82 00 00 00    	jne    f01043cb <vprintfmt+0x2f1>
f0104349:	eb 75                	jmp    f01043c0 <vprintfmt+0x2e6>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010434b:	89 74 24 04          	mov    %esi,0x4(%esp)
f010434f:	89 1c 24             	mov    %ebx,(%esp)
f0104352:	e8 84 03 00 00       	call   f01046db <strnlen>
f0104357:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010435a:	29 c2                	sub    %eax,%edx
f010435c:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010435f:	85 d2                	test   %edx,%edx
f0104361:	7e d8                	jle    f010433b <vprintfmt+0x261>
					putch(padc, putdat);
f0104363:	0f be 45 e0          	movsbl -0x20(%ebp),%eax
f0104367:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010436a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010436d:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104371:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104374:	89 04 24             	mov    %eax,(%esp)
f0104377:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010437a:	83 6d dc 01          	subl   $0x1,-0x24(%ebp)
f010437e:	75 ea                	jne    f010436a <vprintfmt+0x290>
f0104380:	eb b9                	jmp    f010433b <vprintfmt+0x261>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104382:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104386:	74 1b                	je     f01043a3 <vprintfmt+0x2c9>
f0104388:	8d 50 e0             	lea    -0x20(%eax),%edx
f010438b:	83 fa 5e             	cmp    $0x5e,%edx
f010438e:	76 13                	jbe    f01043a3 <vprintfmt+0x2c9>
					putch('?', putdat);
f0104390:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104393:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104397:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f010439e:	ff 55 08             	call   *0x8(%ebp)
f01043a1:	eb 0d                	jmp    f01043b0 <vprintfmt+0x2d6>
				else
					putch(ch, putdat);
f01043a3:	8b 55 0c             	mov    0xc(%ebp),%edx
f01043a6:	89 54 24 04          	mov    %edx,0x4(%esp)
f01043aa:	89 04 24             	mov    %eax,(%esp)
f01043ad:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01043b0:	83 ef 01             	sub    $0x1,%edi
f01043b3:	0f be 03             	movsbl (%ebx),%eax
f01043b6:	83 c3 01             	add    $0x1,%ebx
f01043b9:	85 c0                	test   %eax,%eax
f01043bb:	75 14                	jne    f01043d1 <vprintfmt+0x2f7>
f01043bd:	89 7d dc             	mov    %edi,-0x24(%ebp)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01043c0:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01043c4:	7f 19                	jg     f01043df <vprintfmt+0x305>
f01043c6:	e9 de fd ff ff       	jmp    f01041a9 <vprintfmt+0xcf>
f01043cb:	89 7d e0             	mov    %edi,-0x20(%ebp)
f01043ce:	8b 7d dc             	mov    -0x24(%ebp),%edi
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01043d1:	85 f6                	test   %esi,%esi
f01043d3:	78 ad                	js     f0104382 <vprintfmt+0x2a8>
f01043d5:	83 ee 01             	sub    $0x1,%esi
f01043d8:	79 a8                	jns    f0104382 <vprintfmt+0x2a8>
f01043da:	89 7d dc             	mov    %edi,-0x24(%ebp)
f01043dd:	eb e1                	jmp    f01043c0 <vprintfmt+0x2e6>
f01043df:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01043e2:	8b 7d 08             	mov    0x8(%ebp),%edi
f01043e5:	8b 75 0c             	mov    0xc(%ebp),%esi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01043e8:	89 74 24 04          	mov    %esi,0x4(%esp)
f01043ec:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01043f3:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01043f5:	83 eb 01             	sub    $0x1,%ebx
f01043f8:	75 ee                	jne    f01043e8 <vprintfmt+0x30e>
f01043fa:	e9 aa fd ff ff       	jmp    f01041a9 <vprintfmt+0xcf>
f01043ff:	89 45 e4             	mov    %eax,-0x1c(%ebp)
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0104402:	83 f9 01             	cmp    $0x1,%ecx
f0104405:	7e 10                	jle    f0104417 <vprintfmt+0x33d>
		return va_arg(*ap, long long);
f0104407:	8b 45 14             	mov    0x14(%ebp),%eax
f010440a:	8d 50 08             	lea    0x8(%eax),%edx
f010440d:	89 55 14             	mov    %edx,0x14(%ebp)
f0104410:	8b 30                	mov    (%eax),%esi
f0104412:	8b 78 04             	mov    0x4(%eax),%edi
f0104415:	eb 26                	jmp    f010443d <vprintfmt+0x363>
	else if (lflag)
f0104417:	85 c9                	test   %ecx,%ecx
f0104419:	74 12                	je     f010442d <vprintfmt+0x353>
		return va_arg(*ap, long);
f010441b:	8b 45 14             	mov    0x14(%ebp),%eax
f010441e:	8d 50 04             	lea    0x4(%eax),%edx
f0104421:	89 55 14             	mov    %edx,0x14(%ebp)
f0104424:	8b 30                	mov    (%eax),%esi
f0104426:	89 f7                	mov    %esi,%edi
f0104428:	c1 ff 1f             	sar    $0x1f,%edi
f010442b:	eb 10                	jmp    f010443d <vprintfmt+0x363>
	else
		return va_arg(*ap, int);
f010442d:	8b 45 14             	mov    0x14(%ebp),%eax
f0104430:	8d 50 04             	lea    0x4(%eax),%edx
f0104433:	89 55 14             	mov    %edx,0x14(%ebp)
f0104436:	8b 30                	mov    (%eax),%esi
f0104438:	89 f7                	mov    %esi,%edi
f010443a:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010443d:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0104442:	85 ff                	test   %edi,%edi
f0104444:	0f 89 9e 00 00 00    	jns    f01044e8 <vprintfmt+0x40e>
				putch('-', putdat);
f010444a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010444d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104451:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0104458:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010445b:	f7 de                	neg    %esi
f010445d:	83 d7 00             	adc    $0x0,%edi
f0104460:	f7 df                	neg    %edi
			}
			base = 10;
f0104462:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104467:	eb 7f                	jmp    f01044e8 <vprintfmt+0x40e>
f0104469:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f010446c:	89 ca                	mov    %ecx,%edx
f010446e:	8d 45 14             	lea    0x14(%ebp),%eax
f0104471:	e8 e5 fb ff ff       	call   f010405b <getuint>
f0104476:	89 c6                	mov    %eax,%esi
f0104478:	89 d7                	mov    %edx,%edi
			base = 10;
f010447a:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f010447f:	eb 67                	jmp    f01044e8 <vprintfmt+0x40e>
f0104481:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap,lflag);
f0104484:	89 ca                	mov    %ecx,%edx
f0104486:	8d 45 14             	lea    0x14(%ebp),%eax
f0104489:	e8 cd fb ff ff       	call   f010405b <getuint>
f010448e:	89 c6                	mov    %eax,%esi
f0104490:	89 d7                	mov    %edx,%edi
			base = 8;
f0104492:	b8 08 00 00 00       	mov    $0x8,%eax

			goto number;
f0104497:	eb 4f                	jmp    f01044e8 <vprintfmt+0x40e>
f0104499:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// pointer
		case 'p':
			putch('0', putdat);
f010449c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010449f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01044a3:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01044aa:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01044ad:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01044b1:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01044b8:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01044bb:	8b 45 14             	mov    0x14(%ebp),%eax
f01044be:	8d 50 04             	lea    0x4(%eax),%edx
f01044c1:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01044c4:	8b 30                	mov    (%eax),%esi
f01044c6:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01044cb:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f01044d0:	eb 16                	jmp    f01044e8 <vprintfmt+0x40e>
f01044d2:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01044d5:	89 ca                	mov    %ecx,%edx
f01044d7:	8d 45 14             	lea    0x14(%ebp),%eax
f01044da:	e8 7c fb ff ff       	call   f010405b <getuint>
f01044df:	89 c6                	mov    %eax,%esi
f01044e1:	89 d7                	mov    %edx,%edi
			base = 16;
f01044e3:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f01044e8:	0f be 55 e0          	movsbl -0x20(%ebp),%edx
f01044ec:	89 54 24 10          	mov    %edx,0x10(%esp)
f01044f0:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01044f3:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01044f7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01044fb:	89 34 24             	mov    %esi,(%esp)
f01044fe:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104502:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104505:	8b 45 08             	mov    0x8(%ebp),%eax
f0104508:	e8 73 fa ff ff       	call   f0103f80 <printnum>
			break;
f010450d:	e9 97 fc ff ff       	jmp    f01041a9 <vprintfmt+0xcf>
f0104512:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104515:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0104518:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010451b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010451f:	89 14 24             	mov    %edx,(%esp)
f0104522:	ff 55 08             	call   *0x8(%ebp)
			break;
f0104525:	e9 7f fc ff ff       	jmp    f01041a9 <vprintfmt+0xcf>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010452a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010452d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104531:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0104538:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f010453b:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f010453e:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0104542:	0f 84 61 fc ff ff    	je     f01041a9 <vprintfmt+0xcf>
f0104548:	83 eb 01             	sub    $0x1,%ebx
f010454b:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f010454f:	75 f7                	jne    f0104548 <vprintfmt+0x46e>
f0104551:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0104554:	e9 50 fc ff ff       	jmp    f01041a9 <vprintfmt+0xcf>
				/* do nothing */;
			break;
		}
	}
}
f0104559:	83 c4 3c             	add    $0x3c,%esp
f010455c:	5b                   	pop    %ebx
f010455d:	5e                   	pop    %esi
f010455e:	5f                   	pop    %edi
f010455f:	5d                   	pop    %ebp
f0104560:	c3                   	ret    

f0104561 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104561:	55                   	push   %ebp
f0104562:	89 e5                	mov    %esp,%ebp
f0104564:	83 ec 28             	sub    $0x28,%esp
f0104567:	8b 45 08             	mov    0x8(%ebp),%eax
f010456a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010456d:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104570:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104574:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104577:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010457e:	85 c0                	test   %eax,%eax
f0104580:	74 30                	je     f01045b2 <vsnprintf+0x51>
f0104582:	85 d2                	test   %edx,%edx
f0104584:	7e 2c                	jle    f01045b2 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104586:	8b 45 14             	mov    0x14(%ebp),%eax
f0104589:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010458d:	8b 45 10             	mov    0x10(%ebp),%eax
f0104590:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104594:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104597:	89 44 24 04          	mov    %eax,0x4(%esp)
f010459b:	c7 04 24 95 40 10 f0 	movl   $0xf0104095,(%esp)
f01045a2:	e8 33 fb ff ff       	call   f01040da <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01045a7:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01045aa:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01045ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01045b0:	eb 05                	jmp    f01045b7 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01045b2:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01045b7:	c9                   	leave  
f01045b8:	c3                   	ret    

f01045b9 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01045b9:	55                   	push   %ebp
f01045ba:	89 e5                	mov    %esp,%ebp
f01045bc:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01045bf:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01045c2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01045c6:	8b 45 10             	mov    0x10(%ebp),%eax
f01045c9:	89 44 24 08          	mov    %eax,0x8(%esp)
f01045cd:	8b 45 0c             	mov    0xc(%ebp),%eax
f01045d0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01045d4:	8b 45 08             	mov    0x8(%ebp),%eax
f01045d7:	89 04 24             	mov    %eax,(%esp)
f01045da:	e8 82 ff ff ff       	call   f0104561 <vsnprintf>
	va_end(ap);

	return rc;
}
f01045df:	c9                   	leave  
f01045e0:	c3                   	ret    
	...

f01045f0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01045f0:	55                   	push   %ebp
f01045f1:	89 e5                	mov    %esp,%ebp
f01045f3:	57                   	push   %edi
f01045f4:	56                   	push   %esi
f01045f5:	53                   	push   %ebx
f01045f6:	83 ec 1c             	sub    $0x1c,%esp
f01045f9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01045fc:	85 c0                	test   %eax,%eax
f01045fe:	74 10                	je     f0104610 <readline+0x20>
		cprintf("%s", prompt);
f0104600:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104604:	c7 04 24 d9 5d 10 f0 	movl   $0xf0105dd9,(%esp)
f010460b:	e8 aa f1 ff ff       	call   f01037ba <cprintf>

	i = 0;
	echoing = iscons(0);
f0104610:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0104617:	e8 26 c0 ff ff       	call   f0100642 <iscons>
f010461c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010461e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0104623:	e8 09 c0 ff ff       	call   f0100631 <getchar>
f0104628:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010462a:	85 c0                	test   %eax,%eax
f010462c:	79 17                	jns    f0104645 <readline+0x55>
			cprintf("read error: %e\n", c);
f010462e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104632:	c7 04 24 d8 66 10 f0 	movl   $0xf01066d8,(%esp)
f0104639:	e8 7c f1 ff ff       	call   f01037ba <cprintf>
			return NULL;
f010463e:	b8 00 00 00 00       	mov    $0x0,%eax
f0104643:	eb 6d                	jmp    f01046b2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104645:	83 f8 08             	cmp    $0x8,%eax
f0104648:	74 05                	je     f010464f <readline+0x5f>
f010464a:	83 f8 7f             	cmp    $0x7f,%eax
f010464d:	75 19                	jne    f0104668 <readline+0x78>
f010464f:	85 f6                	test   %esi,%esi
f0104651:	7e 15                	jle    f0104668 <readline+0x78>
			if (echoing)
f0104653:	85 ff                	test   %edi,%edi
f0104655:	74 0c                	je     f0104663 <readline+0x73>
				cputchar('\b');
f0104657:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010465e:	e8 be bf ff ff       	call   f0100621 <cputchar>
			i--;
f0104663:	83 ee 01             	sub    $0x1,%esi
f0104666:	eb bb                	jmp    f0104623 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104668:	83 fb 1f             	cmp    $0x1f,%ebx
f010466b:	7e 1f                	jle    f010468c <readline+0x9c>
f010466d:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0104673:	7f 17                	jg     f010468c <readline+0x9c>
			if (echoing)
f0104675:	85 ff                	test   %edi,%edi
f0104677:	74 08                	je     f0104681 <readline+0x91>
				cputchar(c);
f0104679:	89 1c 24             	mov    %ebx,(%esp)
f010467c:	e8 a0 bf ff ff       	call   f0100621 <cputchar>
			buf[i++] = c;
f0104681:	88 9e c0 fa 17 f0    	mov    %bl,-0xfe80540(%esi)
f0104687:	83 c6 01             	add    $0x1,%esi
f010468a:	eb 97                	jmp    f0104623 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010468c:	83 fb 0a             	cmp    $0xa,%ebx
f010468f:	74 05                	je     f0104696 <readline+0xa6>
f0104691:	83 fb 0d             	cmp    $0xd,%ebx
f0104694:	75 8d                	jne    f0104623 <readline+0x33>
			if (echoing)
f0104696:	85 ff                	test   %edi,%edi
f0104698:	74 0c                	je     f01046a6 <readline+0xb6>
				cputchar('\n');
f010469a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01046a1:	e8 7b bf ff ff       	call   f0100621 <cputchar>
			buf[i] = 0;
f01046a6:	c6 86 c0 fa 17 f0 00 	movb   $0x0,-0xfe80540(%esi)
			return buf;
f01046ad:	b8 c0 fa 17 f0       	mov    $0xf017fac0,%eax
		}
	}
}
f01046b2:	83 c4 1c             	add    $0x1c,%esp
f01046b5:	5b                   	pop    %ebx
f01046b6:	5e                   	pop    %esi
f01046b7:	5f                   	pop    %edi
f01046b8:	5d                   	pop    %ebp
f01046b9:	c3                   	ret    
f01046ba:	00 00                	add    %al,(%eax)
f01046bc:	00 00                	add    %al,(%eax)
	...

f01046c0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01046c0:	55                   	push   %ebp
f01046c1:	89 e5                	mov    %esp,%ebp
f01046c3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01046c6:	b8 00 00 00 00       	mov    $0x0,%eax
f01046cb:	80 3a 00             	cmpb   $0x0,(%edx)
f01046ce:	74 09                	je     f01046d9 <strlen+0x19>
		n++;
f01046d0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01046d3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01046d7:	75 f7                	jne    f01046d0 <strlen+0x10>
		n++;
	return n;
}
f01046d9:	5d                   	pop    %ebp
f01046da:	c3                   	ret    

f01046db <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01046db:	55                   	push   %ebp
f01046dc:	89 e5                	mov    %esp,%ebp
f01046de:	53                   	push   %ebx
f01046df:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01046e2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01046e5:	b8 00 00 00 00       	mov    $0x0,%eax
f01046ea:	85 c9                	test   %ecx,%ecx
f01046ec:	74 1a                	je     f0104708 <strnlen+0x2d>
f01046ee:	80 3b 00             	cmpb   $0x0,(%ebx)
f01046f1:	74 15                	je     f0104708 <strnlen+0x2d>
f01046f3:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f01046f8:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01046fa:	39 ca                	cmp    %ecx,%edx
f01046fc:	74 0a                	je     f0104708 <strnlen+0x2d>
f01046fe:	83 c2 01             	add    $0x1,%edx
f0104701:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0104706:	75 f0                	jne    f01046f8 <strnlen+0x1d>
		n++;
	return n;
}
f0104708:	5b                   	pop    %ebx
f0104709:	5d                   	pop    %ebp
f010470a:	c3                   	ret    

f010470b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010470b:	55                   	push   %ebp
f010470c:	89 e5                	mov    %esp,%ebp
f010470e:	53                   	push   %ebx
f010470f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104712:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104715:	ba 00 00 00 00       	mov    $0x0,%edx
f010471a:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f010471e:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0104721:	83 c2 01             	add    $0x1,%edx
f0104724:	84 c9                	test   %cl,%cl
f0104726:	75 f2                	jne    f010471a <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0104728:	5b                   	pop    %ebx
f0104729:	5d                   	pop    %ebp
f010472a:	c3                   	ret    

f010472b <strcat>:

char *
strcat(char *dst, const char *src)
{
f010472b:	55                   	push   %ebp
f010472c:	89 e5                	mov    %esp,%ebp
f010472e:	53                   	push   %ebx
f010472f:	83 ec 08             	sub    $0x8,%esp
f0104732:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104735:	89 1c 24             	mov    %ebx,(%esp)
f0104738:	e8 83 ff ff ff       	call   f01046c0 <strlen>
	strcpy(dst + len, src);
f010473d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104740:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104744:	01 d8                	add    %ebx,%eax
f0104746:	89 04 24             	mov    %eax,(%esp)
f0104749:	e8 bd ff ff ff       	call   f010470b <strcpy>
	return dst;
}
f010474e:	89 d8                	mov    %ebx,%eax
f0104750:	83 c4 08             	add    $0x8,%esp
f0104753:	5b                   	pop    %ebx
f0104754:	5d                   	pop    %ebp
f0104755:	c3                   	ret    

f0104756 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104756:	55                   	push   %ebp
f0104757:	89 e5                	mov    %esp,%ebp
f0104759:	56                   	push   %esi
f010475a:	53                   	push   %ebx
f010475b:	8b 45 08             	mov    0x8(%ebp),%eax
f010475e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104761:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104764:	85 f6                	test   %esi,%esi
f0104766:	74 18                	je     f0104780 <strncpy+0x2a>
f0104768:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f010476d:	0f b6 1a             	movzbl (%edx),%ebx
f0104770:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104773:	80 3a 01             	cmpb   $0x1,(%edx)
f0104776:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104779:	83 c1 01             	add    $0x1,%ecx
f010477c:	39 f1                	cmp    %esi,%ecx
f010477e:	75 ed                	jne    f010476d <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104780:	5b                   	pop    %ebx
f0104781:	5e                   	pop    %esi
f0104782:	5d                   	pop    %ebp
f0104783:	c3                   	ret    

f0104784 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104784:	55                   	push   %ebp
f0104785:	89 e5                	mov    %esp,%ebp
f0104787:	57                   	push   %edi
f0104788:	56                   	push   %esi
f0104789:	53                   	push   %ebx
f010478a:	8b 7d 08             	mov    0x8(%ebp),%edi
f010478d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104790:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104793:	89 f8                	mov    %edi,%eax
f0104795:	85 f6                	test   %esi,%esi
f0104797:	74 2b                	je     f01047c4 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f0104799:	83 fe 01             	cmp    $0x1,%esi
f010479c:	74 23                	je     f01047c1 <strlcpy+0x3d>
f010479e:	0f b6 0b             	movzbl (%ebx),%ecx
f01047a1:	84 c9                	test   %cl,%cl
f01047a3:	74 1c                	je     f01047c1 <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f01047a5:	83 ee 02             	sub    $0x2,%esi
f01047a8:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01047ad:	88 08                	mov    %cl,(%eax)
f01047af:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01047b2:	39 f2                	cmp    %esi,%edx
f01047b4:	74 0b                	je     f01047c1 <strlcpy+0x3d>
f01047b6:	83 c2 01             	add    $0x1,%edx
f01047b9:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01047bd:	84 c9                	test   %cl,%cl
f01047bf:	75 ec                	jne    f01047ad <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f01047c1:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01047c4:	29 f8                	sub    %edi,%eax
}
f01047c6:	5b                   	pop    %ebx
f01047c7:	5e                   	pop    %esi
f01047c8:	5f                   	pop    %edi
f01047c9:	5d                   	pop    %ebp
f01047ca:	c3                   	ret    

f01047cb <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01047cb:	55                   	push   %ebp
f01047cc:	89 e5                	mov    %esp,%ebp
f01047ce:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01047d1:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01047d4:	0f b6 01             	movzbl (%ecx),%eax
f01047d7:	84 c0                	test   %al,%al
f01047d9:	74 16                	je     f01047f1 <strcmp+0x26>
f01047db:	3a 02                	cmp    (%edx),%al
f01047dd:	75 12                	jne    f01047f1 <strcmp+0x26>
		p++, q++;
f01047df:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01047e2:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f01047e6:	84 c0                	test   %al,%al
f01047e8:	74 07                	je     f01047f1 <strcmp+0x26>
f01047ea:	83 c1 01             	add    $0x1,%ecx
f01047ed:	3a 02                	cmp    (%edx),%al
f01047ef:	74 ee                	je     f01047df <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01047f1:	0f b6 c0             	movzbl %al,%eax
f01047f4:	0f b6 12             	movzbl (%edx),%edx
f01047f7:	29 d0                	sub    %edx,%eax
}
f01047f9:	5d                   	pop    %ebp
f01047fa:	c3                   	ret    

f01047fb <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01047fb:	55                   	push   %ebp
f01047fc:	89 e5                	mov    %esp,%ebp
f01047fe:	53                   	push   %ebx
f01047ff:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104802:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104805:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104808:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010480d:	85 d2                	test   %edx,%edx
f010480f:	74 28                	je     f0104839 <strncmp+0x3e>
f0104811:	0f b6 01             	movzbl (%ecx),%eax
f0104814:	84 c0                	test   %al,%al
f0104816:	74 24                	je     f010483c <strncmp+0x41>
f0104818:	3a 03                	cmp    (%ebx),%al
f010481a:	75 20                	jne    f010483c <strncmp+0x41>
f010481c:	83 ea 01             	sub    $0x1,%edx
f010481f:	74 13                	je     f0104834 <strncmp+0x39>
		n--, p++, q++;
f0104821:	83 c1 01             	add    $0x1,%ecx
f0104824:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0104827:	0f b6 01             	movzbl (%ecx),%eax
f010482a:	84 c0                	test   %al,%al
f010482c:	74 0e                	je     f010483c <strncmp+0x41>
f010482e:	3a 03                	cmp    (%ebx),%al
f0104830:	74 ea                	je     f010481c <strncmp+0x21>
f0104832:	eb 08                	jmp    f010483c <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104834:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0104839:	5b                   	pop    %ebx
f010483a:	5d                   	pop    %ebp
f010483b:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010483c:	0f b6 01             	movzbl (%ecx),%eax
f010483f:	0f b6 13             	movzbl (%ebx),%edx
f0104842:	29 d0                	sub    %edx,%eax
f0104844:	eb f3                	jmp    f0104839 <strncmp+0x3e>

f0104846 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104846:	55                   	push   %ebp
f0104847:	89 e5                	mov    %esp,%ebp
f0104849:	8b 45 08             	mov    0x8(%ebp),%eax
f010484c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104850:	0f b6 10             	movzbl (%eax),%edx
f0104853:	84 d2                	test   %dl,%dl
f0104855:	74 1c                	je     f0104873 <strchr+0x2d>
		if (*s == c)
f0104857:	38 ca                	cmp    %cl,%dl
f0104859:	75 09                	jne    f0104864 <strchr+0x1e>
f010485b:	eb 1b                	jmp    f0104878 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010485d:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f0104860:	38 ca                	cmp    %cl,%dl
f0104862:	74 14                	je     f0104878 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104864:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f0104868:	84 d2                	test   %dl,%dl
f010486a:	75 f1                	jne    f010485d <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f010486c:	b8 00 00 00 00       	mov    $0x0,%eax
f0104871:	eb 05                	jmp    f0104878 <strchr+0x32>
f0104873:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104878:	5d                   	pop    %ebp
f0104879:	c3                   	ret    

f010487a <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010487a:	55                   	push   %ebp
f010487b:	89 e5                	mov    %esp,%ebp
f010487d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104880:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104884:	0f b6 10             	movzbl (%eax),%edx
f0104887:	84 d2                	test   %dl,%dl
f0104889:	74 14                	je     f010489f <strfind+0x25>
		if (*s == c)
f010488b:	38 ca                	cmp    %cl,%dl
f010488d:	75 06                	jne    f0104895 <strfind+0x1b>
f010488f:	eb 0e                	jmp    f010489f <strfind+0x25>
f0104891:	38 ca                	cmp    %cl,%dl
f0104893:	74 0a                	je     f010489f <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0104895:	83 c0 01             	add    $0x1,%eax
f0104898:	0f b6 10             	movzbl (%eax),%edx
f010489b:	84 d2                	test   %dl,%dl
f010489d:	75 f2                	jne    f0104891 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f010489f:	5d                   	pop    %ebp
f01048a0:	c3                   	ret    

f01048a1 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01048a1:	55                   	push   %ebp
f01048a2:	89 e5                	mov    %esp,%ebp
f01048a4:	83 ec 0c             	sub    $0xc,%esp
f01048a7:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f01048aa:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01048ad:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01048b0:	8b 7d 08             	mov    0x8(%ebp),%edi
f01048b3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01048b6:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01048b9:	85 c9                	test   %ecx,%ecx
f01048bb:	74 30                	je     f01048ed <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01048bd:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01048c3:	75 25                	jne    f01048ea <memset+0x49>
f01048c5:	f6 c1 03             	test   $0x3,%cl
f01048c8:	75 20                	jne    f01048ea <memset+0x49>
		c &= 0xFF;
f01048ca:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01048cd:	89 d3                	mov    %edx,%ebx
f01048cf:	c1 e3 08             	shl    $0x8,%ebx
f01048d2:	89 d6                	mov    %edx,%esi
f01048d4:	c1 e6 18             	shl    $0x18,%esi
f01048d7:	89 d0                	mov    %edx,%eax
f01048d9:	c1 e0 10             	shl    $0x10,%eax
f01048dc:	09 f0                	or     %esi,%eax
f01048de:	09 d0                	or     %edx,%eax
f01048e0:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01048e2:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01048e5:	fc                   	cld    
f01048e6:	f3 ab                	rep stos %eax,%es:(%edi)
f01048e8:	eb 03                	jmp    f01048ed <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01048ea:	fc                   	cld    
f01048eb:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01048ed:	89 f8                	mov    %edi,%eax
f01048ef:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01048f2:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01048f5:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01048f8:	89 ec                	mov    %ebp,%esp
f01048fa:	5d                   	pop    %ebp
f01048fb:	c3                   	ret    

f01048fc <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01048fc:	55                   	push   %ebp
f01048fd:	89 e5                	mov    %esp,%ebp
f01048ff:	83 ec 08             	sub    $0x8,%esp
f0104902:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0104905:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0104908:	8b 45 08             	mov    0x8(%ebp),%eax
f010490b:	8b 75 0c             	mov    0xc(%ebp),%esi
f010490e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104911:	39 c6                	cmp    %eax,%esi
f0104913:	73 36                	jae    f010494b <memmove+0x4f>
f0104915:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104918:	39 d0                	cmp    %edx,%eax
f010491a:	73 2f                	jae    f010494b <memmove+0x4f>
		s += n;
		d += n;
f010491c:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010491f:	f6 c2 03             	test   $0x3,%dl
f0104922:	75 1b                	jne    f010493f <memmove+0x43>
f0104924:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010492a:	75 13                	jne    f010493f <memmove+0x43>
f010492c:	f6 c1 03             	test   $0x3,%cl
f010492f:	75 0e                	jne    f010493f <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0104931:	83 ef 04             	sub    $0x4,%edi
f0104934:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104937:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010493a:	fd                   	std    
f010493b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010493d:	eb 09                	jmp    f0104948 <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010493f:	83 ef 01             	sub    $0x1,%edi
f0104942:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0104945:	fd                   	std    
f0104946:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104948:	fc                   	cld    
f0104949:	eb 20                	jmp    f010496b <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010494b:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104951:	75 13                	jne    f0104966 <memmove+0x6a>
f0104953:	a8 03                	test   $0x3,%al
f0104955:	75 0f                	jne    f0104966 <memmove+0x6a>
f0104957:	f6 c1 03             	test   $0x3,%cl
f010495a:	75 0a                	jne    f0104966 <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f010495c:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010495f:	89 c7                	mov    %eax,%edi
f0104961:	fc                   	cld    
f0104962:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104964:	eb 05                	jmp    f010496b <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104966:	89 c7                	mov    %eax,%edi
f0104968:	fc                   	cld    
f0104969:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010496b:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010496e:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0104971:	89 ec                	mov    %ebp,%esp
f0104973:	5d                   	pop    %ebp
f0104974:	c3                   	ret    

f0104975 <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0104975:	55                   	push   %ebp
f0104976:	89 e5                	mov    %esp,%ebp
f0104978:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f010497b:	8b 45 10             	mov    0x10(%ebp),%eax
f010497e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104982:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104985:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104989:	8b 45 08             	mov    0x8(%ebp),%eax
f010498c:	89 04 24             	mov    %eax,(%esp)
f010498f:	e8 68 ff ff ff       	call   f01048fc <memmove>
}
f0104994:	c9                   	leave  
f0104995:	c3                   	ret    

f0104996 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104996:	55                   	push   %ebp
f0104997:	89 e5                	mov    %esp,%ebp
f0104999:	57                   	push   %edi
f010499a:	56                   	push   %esi
f010499b:	53                   	push   %ebx
f010499c:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010499f:	8b 75 0c             	mov    0xc(%ebp),%esi
f01049a2:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01049a5:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01049aa:	85 ff                	test   %edi,%edi
f01049ac:	74 37                	je     f01049e5 <memcmp+0x4f>
		if (*s1 != *s2)
f01049ae:	0f b6 03             	movzbl (%ebx),%eax
f01049b1:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01049b4:	83 ef 01             	sub    $0x1,%edi
f01049b7:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f01049bc:	38 c8                	cmp    %cl,%al
f01049be:	74 1c                	je     f01049dc <memcmp+0x46>
f01049c0:	eb 10                	jmp    f01049d2 <memcmp+0x3c>
f01049c2:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f01049c7:	83 c2 01             	add    $0x1,%edx
f01049ca:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f01049ce:	38 c8                	cmp    %cl,%al
f01049d0:	74 0a                	je     f01049dc <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f01049d2:	0f b6 c0             	movzbl %al,%eax
f01049d5:	0f b6 c9             	movzbl %cl,%ecx
f01049d8:	29 c8                	sub    %ecx,%eax
f01049da:	eb 09                	jmp    f01049e5 <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01049dc:	39 fa                	cmp    %edi,%edx
f01049de:	75 e2                	jne    f01049c2 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01049e0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01049e5:	5b                   	pop    %ebx
f01049e6:	5e                   	pop    %esi
f01049e7:	5f                   	pop    %edi
f01049e8:	5d                   	pop    %ebp
f01049e9:	c3                   	ret    

f01049ea <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01049ea:	55                   	push   %ebp
f01049eb:	89 e5                	mov    %esp,%ebp
f01049ed:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01049f0:	89 c2                	mov    %eax,%edx
f01049f2:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01049f5:	39 d0                	cmp    %edx,%eax
f01049f7:	73 19                	jae    f0104a12 <memfind+0x28>
		if (*(const unsigned char *) s == (unsigned char) c)
f01049f9:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f01049fd:	38 08                	cmp    %cl,(%eax)
f01049ff:	75 06                	jne    f0104a07 <memfind+0x1d>
f0104a01:	eb 0f                	jmp    f0104a12 <memfind+0x28>
f0104a03:	38 08                	cmp    %cl,(%eax)
f0104a05:	74 0b                	je     f0104a12 <memfind+0x28>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104a07:	83 c0 01             	add    $0x1,%eax
f0104a0a:	39 d0                	cmp    %edx,%eax
f0104a0c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104a10:	75 f1                	jne    f0104a03 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104a12:	5d                   	pop    %ebp
f0104a13:	c3                   	ret    

f0104a14 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104a14:	55                   	push   %ebp
f0104a15:	89 e5                	mov    %esp,%ebp
f0104a17:	57                   	push   %edi
f0104a18:	56                   	push   %esi
f0104a19:	53                   	push   %ebx
f0104a1a:	8b 55 08             	mov    0x8(%ebp),%edx
f0104a1d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104a20:	0f b6 02             	movzbl (%edx),%eax
f0104a23:	3c 20                	cmp    $0x20,%al
f0104a25:	74 04                	je     f0104a2b <strtol+0x17>
f0104a27:	3c 09                	cmp    $0x9,%al
f0104a29:	75 0e                	jne    f0104a39 <strtol+0x25>
		s++;
f0104a2b:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104a2e:	0f b6 02             	movzbl (%edx),%eax
f0104a31:	3c 20                	cmp    $0x20,%al
f0104a33:	74 f6                	je     f0104a2b <strtol+0x17>
f0104a35:	3c 09                	cmp    $0x9,%al
f0104a37:	74 f2                	je     f0104a2b <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104a39:	3c 2b                	cmp    $0x2b,%al
f0104a3b:	75 0a                	jne    f0104a47 <strtol+0x33>
		s++;
f0104a3d:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0104a40:	bf 00 00 00 00       	mov    $0x0,%edi
f0104a45:	eb 10                	jmp    f0104a57 <strtol+0x43>
f0104a47:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104a4c:	3c 2d                	cmp    $0x2d,%al
f0104a4e:	75 07                	jne    f0104a57 <strtol+0x43>
		s++, neg = 1;
f0104a50:	83 c2 01             	add    $0x1,%edx
f0104a53:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104a57:	85 db                	test   %ebx,%ebx
f0104a59:	0f 94 c0             	sete   %al
f0104a5c:	74 05                	je     f0104a63 <strtol+0x4f>
f0104a5e:	83 fb 10             	cmp    $0x10,%ebx
f0104a61:	75 15                	jne    f0104a78 <strtol+0x64>
f0104a63:	80 3a 30             	cmpb   $0x30,(%edx)
f0104a66:	75 10                	jne    f0104a78 <strtol+0x64>
f0104a68:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0104a6c:	75 0a                	jne    f0104a78 <strtol+0x64>
		s += 2, base = 16;
f0104a6e:	83 c2 02             	add    $0x2,%edx
f0104a71:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104a76:	eb 13                	jmp    f0104a8b <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f0104a78:	84 c0                	test   %al,%al
f0104a7a:	74 0f                	je     f0104a8b <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104a7c:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104a81:	80 3a 30             	cmpb   $0x30,(%edx)
f0104a84:	75 05                	jne    f0104a8b <strtol+0x77>
		s++, base = 8;
f0104a86:	83 c2 01             	add    $0x1,%edx
f0104a89:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f0104a8b:	b8 00 00 00 00       	mov    $0x0,%eax
f0104a90:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104a92:	0f b6 0a             	movzbl (%edx),%ecx
f0104a95:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0104a98:	80 fb 09             	cmp    $0x9,%bl
f0104a9b:	77 08                	ja     f0104aa5 <strtol+0x91>
			dig = *s - '0';
f0104a9d:	0f be c9             	movsbl %cl,%ecx
f0104aa0:	83 e9 30             	sub    $0x30,%ecx
f0104aa3:	eb 1e                	jmp    f0104ac3 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f0104aa5:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f0104aa8:	80 fb 19             	cmp    $0x19,%bl
f0104aab:	77 08                	ja     f0104ab5 <strtol+0xa1>
			dig = *s - 'a' + 10;
f0104aad:	0f be c9             	movsbl %cl,%ecx
f0104ab0:	83 e9 57             	sub    $0x57,%ecx
f0104ab3:	eb 0e                	jmp    f0104ac3 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f0104ab5:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0104ab8:	80 fb 19             	cmp    $0x19,%bl
f0104abb:	77 14                	ja     f0104ad1 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0104abd:	0f be c9             	movsbl %cl,%ecx
f0104ac0:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0104ac3:	39 f1                	cmp    %esi,%ecx
f0104ac5:	7d 0e                	jge    f0104ad5 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f0104ac7:	83 c2 01             	add    $0x1,%edx
f0104aca:	0f af c6             	imul   %esi,%eax
f0104acd:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0104acf:	eb c1                	jmp    f0104a92 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0104ad1:	89 c1                	mov    %eax,%ecx
f0104ad3:	eb 02                	jmp    f0104ad7 <strtol+0xc3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0104ad5:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0104ad7:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104adb:	74 05                	je     f0104ae2 <strtol+0xce>
		*endptr = (char *) s;
f0104add:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104ae0:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0104ae2:	89 ca                	mov    %ecx,%edx
f0104ae4:	f7 da                	neg    %edx
f0104ae6:	85 ff                	test   %edi,%edi
f0104ae8:	0f 45 c2             	cmovne %edx,%eax
}
f0104aeb:	5b                   	pop    %ebx
f0104aec:	5e                   	pop    %esi
f0104aed:	5f                   	pop    %edi
f0104aee:	5d                   	pop    %ebp
f0104aef:	c3                   	ret    

f0104af0 <__udivdi3>:
f0104af0:	83 ec 1c             	sub    $0x1c,%esp
f0104af3:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0104af7:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f0104afb:	8b 44 24 20          	mov    0x20(%esp),%eax
f0104aff:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0104b03:	89 74 24 10          	mov    %esi,0x10(%esp)
f0104b07:	8b 74 24 24          	mov    0x24(%esp),%esi
f0104b0b:	85 ff                	test   %edi,%edi
f0104b0d:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0104b11:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104b15:	89 cd                	mov    %ecx,%ebp
f0104b17:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104b1b:	75 33                	jne    f0104b50 <__udivdi3+0x60>
f0104b1d:	39 f1                	cmp    %esi,%ecx
f0104b1f:	77 57                	ja     f0104b78 <__udivdi3+0x88>
f0104b21:	85 c9                	test   %ecx,%ecx
f0104b23:	75 0b                	jne    f0104b30 <__udivdi3+0x40>
f0104b25:	b8 01 00 00 00       	mov    $0x1,%eax
f0104b2a:	31 d2                	xor    %edx,%edx
f0104b2c:	f7 f1                	div    %ecx
f0104b2e:	89 c1                	mov    %eax,%ecx
f0104b30:	89 f0                	mov    %esi,%eax
f0104b32:	31 d2                	xor    %edx,%edx
f0104b34:	f7 f1                	div    %ecx
f0104b36:	89 c6                	mov    %eax,%esi
f0104b38:	8b 44 24 04          	mov    0x4(%esp),%eax
f0104b3c:	f7 f1                	div    %ecx
f0104b3e:	89 f2                	mov    %esi,%edx
f0104b40:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104b44:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104b48:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104b4c:	83 c4 1c             	add    $0x1c,%esp
f0104b4f:	c3                   	ret    
f0104b50:	31 d2                	xor    %edx,%edx
f0104b52:	31 c0                	xor    %eax,%eax
f0104b54:	39 f7                	cmp    %esi,%edi
f0104b56:	77 e8                	ja     f0104b40 <__udivdi3+0x50>
f0104b58:	0f bd cf             	bsr    %edi,%ecx
f0104b5b:	83 f1 1f             	xor    $0x1f,%ecx
f0104b5e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104b62:	75 2c                	jne    f0104b90 <__udivdi3+0xa0>
f0104b64:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0104b68:	76 04                	jbe    f0104b6e <__udivdi3+0x7e>
f0104b6a:	39 f7                	cmp    %esi,%edi
f0104b6c:	73 d2                	jae    f0104b40 <__udivdi3+0x50>
f0104b6e:	31 d2                	xor    %edx,%edx
f0104b70:	b8 01 00 00 00       	mov    $0x1,%eax
f0104b75:	eb c9                	jmp    f0104b40 <__udivdi3+0x50>
f0104b77:	90                   	nop
f0104b78:	89 f2                	mov    %esi,%edx
f0104b7a:	f7 f1                	div    %ecx
f0104b7c:	31 d2                	xor    %edx,%edx
f0104b7e:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104b82:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104b86:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104b8a:	83 c4 1c             	add    $0x1c,%esp
f0104b8d:	c3                   	ret    
f0104b8e:	66 90                	xchg   %ax,%ax
f0104b90:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104b95:	b8 20 00 00 00       	mov    $0x20,%eax
f0104b9a:	89 ea                	mov    %ebp,%edx
f0104b9c:	2b 44 24 04          	sub    0x4(%esp),%eax
f0104ba0:	d3 e7                	shl    %cl,%edi
f0104ba2:	89 c1                	mov    %eax,%ecx
f0104ba4:	d3 ea                	shr    %cl,%edx
f0104ba6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104bab:	09 fa                	or     %edi,%edx
f0104bad:	89 f7                	mov    %esi,%edi
f0104baf:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104bb3:	89 f2                	mov    %esi,%edx
f0104bb5:	8b 74 24 08          	mov    0x8(%esp),%esi
f0104bb9:	d3 e5                	shl    %cl,%ebp
f0104bbb:	89 c1                	mov    %eax,%ecx
f0104bbd:	d3 ef                	shr    %cl,%edi
f0104bbf:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104bc4:	d3 e2                	shl    %cl,%edx
f0104bc6:	89 c1                	mov    %eax,%ecx
f0104bc8:	d3 ee                	shr    %cl,%esi
f0104bca:	09 d6                	or     %edx,%esi
f0104bcc:	89 fa                	mov    %edi,%edx
f0104bce:	89 f0                	mov    %esi,%eax
f0104bd0:	f7 74 24 0c          	divl   0xc(%esp)
f0104bd4:	89 d7                	mov    %edx,%edi
f0104bd6:	89 c6                	mov    %eax,%esi
f0104bd8:	f7 e5                	mul    %ebp
f0104bda:	39 d7                	cmp    %edx,%edi
f0104bdc:	72 22                	jb     f0104c00 <__udivdi3+0x110>
f0104bde:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0104be2:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104be7:	d3 e5                	shl    %cl,%ebp
f0104be9:	39 c5                	cmp    %eax,%ebp
f0104beb:	73 04                	jae    f0104bf1 <__udivdi3+0x101>
f0104bed:	39 d7                	cmp    %edx,%edi
f0104bef:	74 0f                	je     f0104c00 <__udivdi3+0x110>
f0104bf1:	89 f0                	mov    %esi,%eax
f0104bf3:	31 d2                	xor    %edx,%edx
f0104bf5:	e9 46 ff ff ff       	jmp    f0104b40 <__udivdi3+0x50>
f0104bfa:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104c00:	8d 46 ff             	lea    -0x1(%esi),%eax
f0104c03:	31 d2                	xor    %edx,%edx
f0104c05:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104c09:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104c0d:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104c11:	83 c4 1c             	add    $0x1c,%esp
f0104c14:	c3                   	ret    
	...

f0104c20 <__umoddi3>:
f0104c20:	83 ec 1c             	sub    $0x1c,%esp
f0104c23:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0104c27:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f0104c2b:	8b 44 24 20          	mov    0x20(%esp),%eax
f0104c2f:	89 74 24 10          	mov    %esi,0x10(%esp)
f0104c33:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0104c37:	8b 74 24 24          	mov    0x24(%esp),%esi
f0104c3b:	85 ed                	test   %ebp,%ebp
f0104c3d:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0104c41:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104c45:	89 cf                	mov    %ecx,%edi
f0104c47:	89 04 24             	mov    %eax,(%esp)
f0104c4a:	89 f2                	mov    %esi,%edx
f0104c4c:	75 1a                	jne    f0104c68 <__umoddi3+0x48>
f0104c4e:	39 f1                	cmp    %esi,%ecx
f0104c50:	76 4e                	jbe    f0104ca0 <__umoddi3+0x80>
f0104c52:	f7 f1                	div    %ecx
f0104c54:	89 d0                	mov    %edx,%eax
f0104c56:	31 d2                	xor    %edx,%edx
f0104c58:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104c5c:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104c60:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104c64:	83 c4 1c             	add    $0x1c,%esp
f0104c67:	c3                   	ret    
f0104c68:	39 f5                	cmp    %esi,%ebp
f0104c6a:	77 54                	ja     f0104cc0 <__umoddi3+0xa0>
f0104c6c:	0f bd c5             	bsr    %ebp,%eax
f0104c6f:	83 f0 1f             	xor    $0x1f,%eax
f0104c72:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104c76:	75 60                	jne    f0104cd8 <__umoddi3+0xb8>
f0104c78:	3b 0c 24             	cmp    (%esp),%ecx
f0104c7b:	0f 87 07 01 00 00    	ja     f0104d88 <__umoddi3+0x168>
f0104c81:	89 f2                	mov    %esi,%edx
f0104c83:	8b 34 24             	mov    (%esp),%esi
f0104c86:	29 ce                	sub    %ecx,%esi
f0104c88:	19 ea                	sbb    %ebp,%edx
f0104c8a:	89 34 24             	mov    %esi,(%esp)
f0104c8d:	8b 04 24             	mov    (%esp),%eax
f0104c90:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104c94:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104c98:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104c9c:	83 c4 1c             	add    $0x1c,%esp
f0104c9f:	c3                   	ret    
f0104ca0:	85 c9                	test   %ecx,%ecx
f0104ca2:	75 0b                	jne    f0104caf <__umoddi3+0x8f>
f0104ca4:	b8 01 00 00 00       	mov    $0x1,%eax
f0104ca9:	31 d2                	xor    %edx,%edx
f0104cab:	f7 f1                	div    %ecx
f0104cad:	89 c1                	mov    %eax,%ecx
f0104caf:	89 f0                	mov    %esi,%eax
f0104cb1:	31 d2                	xor    %edx,%edx
f0104cb3:	f7 f1                	div    %ecx
f0104cb5:	8b 04 24             	mov    (%esp),%eax
f0104cb8:	f7 f1                	div    %ecx
f0104cba:	eb 98                	jmp    f0104c54 <__umoddi3+0x34>
f0104cbc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104cc0:	89 f2                	mov    %esi,%edx
f0104cc2:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104cc6:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104cca:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104cce:	83 c4 1c             	add    $0x1c,%esp
f0104cd1:	c3                   	ret    
f0104cd2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104cd8:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104cdd:	89 e8                	mov    %ebp,%eax
f0104cdf:	bd 20 00 00 00       	mov    $0x20,%ebp
f0104ce4:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0104ce8:	89 fa                	mov    %edi,%edx
f0104cea:	d3 e0                	shl    %cl,%eax
f0104cec:	89 e9                	mov    %ebp,%ecx
f0104cee:	d3 ea                	shr    %cl,%edx
f0104cf0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104cf5:	09 c2                	or     %eax,%edx
f0104cf7:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104cfb:	89 14 24             	mov    %edx,(%esp)
f0104cfe:	89 f2                	mov    %esi,%edx
f0104d00:	d3 e7                	shl    %cl,%edi
f0104d02:	89 e9                	mov    %ebp,%ecx
f0104d04:	d3 ea                	shr    %cl,%edx
f0104d06:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104d0b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104d0f:	d3 e6                	shl    %cl,%esi
f0104d11:	89 e9                	mov    %ebp,%ecx
f0104d13:	d3 e8                	shr    %cl,%eax
f0104d15:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104d1a:	09 f0                	or     %esi,%eax
f0104d1c:	8b 74 24 08          	mov    0x8(%esp),%esi
f0104d20:	f7 34 24             	divl   (%esp)
f0104d23:	d3 e6                	shl    %cl,%esi
f0104d25:	89 74 24 08          	mov    %esi,0x8(%esp)
f0104d29:	89 d6                	mov    %edx,%esi
f0104d2b:	f7 e7                	mul    %edi
f0104d2d:	39 d6                	cmp    %edx,%esi
f0104d2f:	89 c1                	mov    %eax,%ecx
f0104d31:	89 d7                	mov    %edx,%edi
f0104d33:	72 3f                	jb     f0104d74 <__umoddi3+0x154>
f0104d35:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0104d39:	72 35                	jb     f0104d70 <__umoddi3+0x150>
f0104d3b:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104d3f:	29 c8                	sub    %ecx,%eax
f0104d41:	19 fe                	sbb    %edi,%esi
f0104d43:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104d48:	89 f2                	mov    %esi,%edx
f0104d4a:	d3 e8                	shr    %cl,%eax
f0104d4c:	89 e9                	mov    %ebp,%ecx
f0104d4e:	d3 e2                	shl    %cl,%edx
f0104d50:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104d55:	09 d0                	or     %edx,%eax
f0104d57:	89 f2                	mov    %esi,%edx
f0104d59:	d3 ea                	shr    %cl,%edx
f0104d5b:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104d5f:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104d63:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104d67:	83 c4 1c             	add    $0x1c,%esp
f0104d6a:	c3                   	ret    
f0104d6b:	90                   	nop
f0104d6c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104d70:	39 d6                	cmp    %edx,%esi
f0104d72:	75 c7                	jne    f0104d3b <__umoddi3+0x11b>
f0104d74:	89 d7                	mov    %edx,%edi
f0104d76:	89 c1                	mov    %eax,%ecx
f0104d78:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f0104d7c:	1b 3c 24             	sbb    (%esp),%edi
f0104d7f:	eb ba                	jmp    f0104d3b <__umoddi3+0x11b>
f0104d81:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104d88:	39 f5                	cmp    %esi,%ebp
f0104d8a:	0f 82 f1 fe ff ff    	jb     f0104c81 <__umoddi3+0x61>
f0104d90:	e9 f8 fe ff ff       	jmp    f0104c8d <__umoddi3+0x6d>
