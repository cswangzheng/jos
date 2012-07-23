
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
f0100063:	e8 c9 48 00 00       	call   f0104931 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 be 04 00 00       	call   f010052b <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 40 4e 10 f0 	movl   $0xf0104e40,(%esp)
f010007c:	e8 c5 37 00 00       	call   f0103846 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 0a 17 00 00       	call   f0101790 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100086:	e8 57 33 00 00       	call   f01033e2 <env_init>
	trap_init();
f010008b:	90                   	nop
f010008c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100090:	e8 28 38 00 00       	call   f01038bd <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100095:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010009c:	00 
f010009d:	c7 44 24 04 64 78 00 	movl   $0x7864,0x4(%esp)
f01000a4:	00 
f01000a5:	c7 04 24 21 2d 14 f0 	movl   $0xf0142d21,(%esp)
f01000ac:	e8 be 34 00 00       	call   f010356f <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f01000b1:	a1 28 f2 17 f0       	mov    0xf017f228,%eax
f01000b6:	89 04 24             	mov    %eax,(%esp)
f01000b9:	e8 f5 36 00 00       	call   f01037b3 <env_run>

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
f01000eb:	c7 04 24 5b 4e 10 f0 	movl   $0xf0104e5b,(%esp)
f01000f2:	e8 4f 37 00 00       	call   f0103846 <cprintf>
	vcprintf(fmt, ap);
f01000f7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000fb:	89 34 24             	mov    %esi,(%esp)
f01000fe:	e8 10 37 00 00       	call   f0103813 <vcprintf>
	cprintf("\n");
f0100103:	c7 04 24 d1 60 10 f0 	movl   $0xf01060d1,(%esp)
f010010a:	e8 37 37 00 00       	call   f0103846 <cprintf>
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
f0100135:	c7 04 24 73 4e 10 f0 	movl   $0xf0104e73,(%esp)
f010013c:	e8 05 37 00 00       	call   f0103846 <cprintf>
	vcprintf(fmt, ap);
f0100141:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100145:	8b 45 10             	mov    0x10(%ebp),%eax
f0100148:	89 04 24             	mov    %eax,(%esp)
f010014b:	e8 c3 36 00 00       	call   f0103813 <vcprintf>
	cprintf("\n");
f0100150:	c7 04 24 d1 60 10 f0 	movl   $0xf01060d1,(%esp)
f0100157:	e8 ea 36 00 00       	call   f0103846 <cprintf>
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
f010035d:	e8 2a 46 00 00       	call   f010498c <memmove>
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
f0100409:	0f b6 82 c0 4e 10 f0 	movzbl -0xfefb140(%edx),%eax
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
f0100446:	0f b6 82 c0 4e 10 f0 	movzbl -0xfefb140(%edx),%eax
f010044d:	0b 05 08 f2 17 f0    	or     0xf017f208,%eax
	shift ^= togglecode[data];
f0100453:	0f b6 8a c0 4f 10 f0 	movzbl -0xfefb040(%edx),%ecx
f010045a:	31 c8                	xor    %ecx,%eax
f010045c:	a3 08 f2 17 f0       	mov    %eax,0xf017f208

	c = charcode[shift & (CTL | SHIFT)][data];
f0100461:	89 c1                	mov    %eax,%ecx
f0100463:	83 e1 03             	and    $0x3,%ecx
f0100466:	8b 0c 8d c0 50 10 f0 	mov    -0xfefaf40(,%ecx,4),%ecx
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
f010049c:	c7 04 24 8d 4e 10 f0 	movl   $0xf0104e8d,(%esp)
f01004a3:	e8 9e 33 00 00       	call   f0103846 <cprintf>
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
f010060d:	c7 04 24 99 4e 10 f0 	movl   $0xf0104e99,(%esp)
f0100614:	e8 2d 32 00 00       	call   f0103846 <cprintf>
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
f0100656:	c7 04 24 d0 50 10 f0 	movl   $0xf01050d0,(%esp)
f010065d:	e8 e4 31 00 00       	call   f0103846 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100662:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100669:	00 
f010066a:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100671:	f0 
f0100672:	c7 04 24 78 52 10 f0 	movl   $0xf0105278,(%esp)
f0100679:	e8 c8 31 00 00       	call   f0103846 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010067e:	c7 44 24 08 25 4e 10 	movl   $0x104e25,0x8(%esp)
f0100685:	00 
f0100686:	c7 44 24 04 25 4e 10 	movl   $0xf0104e25,0x4(%esp)
f010068d:	f0 
f010068e:	c7 04 24 9c 52 10 f0 	movl   $0xf010529c,(%esp)
f0100695:	e8 ac 31 00 00       	call   f0103846 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010069a:	c7 44 24 08 ca ef 17 	movl   $0x17efca,0x8(%esp)
f01006a1:	00 
f01006a2:	c7 44 24 04 ca ef 17 	movl   $0xf017efca,0x4(%esp)
f01006a9:	f0 
f01006aa:	c7 04 24 c0 52 10 f0 	movl   $0xf01052c0,(%esp)
f01006b1:	e8 90 31 00 00       	call   f0103846 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006b6:	c7 44 24 08 d0 fe 17 	movl   $0x17fed0,0x8(%esp)
f01006bd:	00 
f01006be:	c7 44 24 04 d0 fe 17 	movl   $0xf017fed0,0x4(%esp)
f01006c5:	f0 
f01006c6:	c7 04 24 e4 52 10 f0 	movl   $0xf01052e4,(%esp)
f01006cd:	e8 74 31 00 00       	call   f0103846 <cprintf>
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
f01006ee:	c7 04 24 08 53 10 f0 	movl   $0xf0105308,(%esp)
f01006f5:	e8 4c 31 00 00       	call   f0103846 <cprintf>
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
f010070d:	8b 83 c4 56 10 f0    	mov    -0xfefa93c(%ebx),%eax
f0100713:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100717:	8b 83 c0 56 10 f0    	mov    -0xfefa940(%ebx),%eax
f010071d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100721:	c7 04 24 e9 50 10 f0 	movl   $0xf01050e9,(%esp)
f0100728:	e8 19 31 00 00       	call   f0103846 <cprintf>
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
f0100752:	c7 04 24 34 53 10 f0 	movl   $0xf0105334,(%esp)
f0100759:	e8 e8 30 00 00       	call   f0103846 <cprintf>
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
f0100779:	e8 26 43 00 00       	call   f0104aa4 <strtol>
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
f010079a:	e8 05 43 00 00       	call   f0104aa4 <strtol>
f010079f:	89 45 e0             	mov    %eax,-0x20(%ebp)
	uint32_t i =0;
	uint32_t j=0;
	cprintf("VA	     Contents");
f01007a2:	c7 04 24 f2 50 10 f0 	movl   $0xf01050f2,(%esp)
f01007a9:	e8 98 30 00 00       	call   f0103846 <cprintf>
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
f01007c9:	c7 04 24 03 51 10 f0 	movl   $0xf0105103,(%esp)
f01007d0:	e8 71 30 00 00       	call   f0103846 <cprintf>
		for(j=0;j<4;j++)
f01007d5:	bb 00 00 00 00       	mov    $0x0,%ebx
			cprintf("0x%08x ",*((uintptr_t *)(va_assign+i*16+4*j)));
f01007da:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
f01007dd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007e1:	c7 04 24 0d 51 10 f0 	movl   $0xf010510d,(%esp)
f01007e8:	e8 59 30 00 00       	call   f0103846 <cprintf>
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
f0100818:	c7 04 24 03 51 10 f0 	movl   $0xf0105103,(%esp)
f010081f:	e8 22 30 00 00       	call   f0103846 <cprintf>
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
f010083c:	c7 04 24 0d 51 10 f0 	movl   $0xf010510d,(%esp)
f0100843:	e8 fe 2f 00 00       	call   f0103846 <cprintf>
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
f010084f:	c7 04 24 d1 60 10 f0 	movl   $0xf01060d1,(%esp)
f0100856:	e8 eb 2f 00 00       	call   f0103846 <cprintf>
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
f010087a:	c7 04 24 58 53 10 f0 	movl   $0xf0105358,(%esp)
f0100881:	e8 c0 2f 00 00       	call   f0103846 <cprintf>
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
f01008a1:	e8 fe 41 00 00       	call   f0104aa4 <strtol>
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
f01008b7:	c7 44 24 08 7c 53 10 	movl   $0xf010537c,0x8(%esp)
f01008be:	f0 
f01008bf:	c7 44 24 04 ea 00 00 	movl   $0xea,0x4(%esp)
f01008c6:	00 
f01008c7:	c7 04 24 15 51 10 f0 	movl   $0xf0105115,(%esp)
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
f01008fc:	e8 a3 41 00 00       	call   f0104aa4 <strtol>
f0100901:	89 45 d8             	mov    %eax,-0x28(%ebp)
	uint32_t i =0;
	uint32_t j=0;
	cprintf("PA	     Contents");
f0100904:	c7 04 24 24 51 10 f0 	movl   $0xf0105124,(%esp)
f010090b:	e8 36 2f 00 00       	call   f0103846 <cprintf>
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
f0100936:	c7 04 24 03 51 10 f0 	movl   $0xf0105103,(%esp)
f010093d:	e8 04 2f 00 00       	call   f0103846 <cprintf>
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
f0100953:	c7 04 24 0d 51 10 f0 	movl   $0xf010510d,(%esp)
f010095a:	e8 e7 2e 00 00       	call   f0103846 <cprintf>
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
f010098e:	c7 04 24 03 51 10 f0 	movl   $0xf0105103,(%esp)
f0100995:	e8 ac 2e 00 00       	call   f0103846 <cprintf>
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
f01009b2:	c7 04 24 0d 51 10 f0 	movl   $0xf010510d,(%esp)
f01009b9:	e8 88 2e 00 00       	call   f0103846 <cprintf>
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
f01009c5:	c7 04 24 d1 60 10 f0 	movl   $0xf01060d1,(%esp)
f01009cc:	e8 75 2e 00 00       	call   f0103846 <cprintf>
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
f01009fb:	c7 04 24 a0 53 10 f0 	movl   $0xf01053a0,(%esp)
f0100a02:	e8 3f 2e 00 00       	call   f0103846 <cprintf>
			cprintf("Usage:setmappings <OPER> <VA> (<Permission>)\n OPER:-set,-clear,-change Permission:U,W\n");
f0100a07:	c7 04 24 f4 53 10 f0 	movl   $0xf01053f4,(%esp)
f0100a0e:	e8 33 2e 00 00       	call   f0103846 <cprintf>
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
f0100a2e:	e8 71 40 00 00       	call   f0104aa4 <strtol>
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
f0100a53:	c7 44 24 04 35 51 10 	movl   $0xf0105135,0x4(%esp)
f0100a5a:	f0 
f0100a5b:	8b 43 04             	mov    0x4(%ebx),%eax
f0100a5e:	89 04 24             	mov    %eax,(%esp)
f0100a61:	e8 f5 3d 00 00       	call   f010485b <strcmp>
f0100a66:	85 c0                	test   %eax,%eax
f0100a68:	75 1e                	jne    f0100a88 <mon_setmappings+0xaa>
	{
		*pte=PTE_ADDR(*pte);
f0100a6a:	8b 06                	mov    (%esi),%eax
f0100a6c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a71:	89 06                	mov    %eax,(%esi)
		cprintf("\n0x%08x permissions clear OK",(*pte));
f0100a73:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a77:	c7 04 24 3c 51 10 f0 	movl   $0xf010513c,(%esp)
f0100a7e:	e8 c3 2d 00 00       	call   f0103846 <cprintf>
f0100a83:	e9 80 00 00 00       	jmp    f0100b08 <mon_setmappings+0x12a>
	}
	else if(strcmp(argv[1],"-set")==0||strcmp(argv[1],"-change")==0)
f0100a88:	c7 44 24 04 59 51 10 	movl   $0xf0105159,0x4(%esp)
f0100a8f:	f0 
f0100a90:	8b 43 04             	mov    0x4(%ebx),%eax
f0100a93:	89 04 24             	mov    %eax,(%esp)
f0100a96:	e8 c0 3d 00 00       	call   f010485b <strcmp>
f0100a9b:	85 c0                	test   %eax,%eax
f0100a9d:	74 17                	je     f0100ab6 <mon_setmappings+0xd8>
f0100a9f:	c7 44 24 04 5e 51 10 	movl   $0xf010515e,0x4(%esp)
f0100aa6:	f0 
f0100aa7:	8b 43 04             	mov    0x4(%ebx),%eax
f0100aaa:	89 04 24             	mov    %eax,(%esp)
f0100aad:	e8 a9 3d 00 00       	call   f010485b <strcmp>
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
f0100afc:	c7 04 24 66 51 10 f0 	movl   $0xf0105166,(%esp)
f0100b03:	e8 3e 2d 00 00       	call   f0103846 <cprintf>
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
f0100b2c:	c7 04 24 4c 54 10 f0 	movl   $0xf010544c,(%esp)
f0100b33:	e8 0e 2d 00 00       	call   f0103846 <cprintf>
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
f0100b53:	e8 4c 3f 00 00       	call   f0104aa4 <strtol>
f0100b58:	89 c6                	mov    %eax,%esi
	uintptr_t va_high = strtol(argv[2], 0,16);
f0100b5a:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f0100b61:	00 
f0100b62:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100b69:	00 
f0100b6a:	8b 43 08             	mov    0x8(%ebx),%eax
f0100b6d:	89 04 24             	mov    %eax,(%esp)
f0100b70:	e8 2f 3f 00 00       	call   f0104aa4 <strtol>
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
f0100b8a:	c7 04 24 94 54 10 f0 	movl   $0xf0105494,(%esp)
f0100b91:	e8 b0 2c 00 00       	call   f0103846 <cprintf>
	cprintf("Virtual Address	    Physical  Permissions(kernel/user)");
f0100b96:	c7 04 24 b8 54 10 f0 	movl   $0xf01054b8,(%esp)
f0100b9d:	e8 a4 2c 00 00       	call   f0103846 <cprintf>
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
f0100be3:	c7 04 24 79 51 10 f0 	movl   $0xf0105179,(%esp)
f0100bea:	e8 57 2c 00 00       	call   f0103846 <cprintf>
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
f0100c02:	c7 04 24 0d 51 10 f0 	movl   $0xf010510d,(%esp)
f0100c09:	e8 38 2c 00 00       	call   f0103846 <cprintf>
		if (*pte & PTE_W)
f0100c0e:	8b 06                	mov    (%esi),%eax
f0100c10:	a8 02                	test   $0x2,%al
f0100c12:	74 20                	je     f0100c34 <mon_showmappings+0x11a>
			{
			if (*pte & PTE_U)
f0100c14:	a8 04                	test   $0x4,%al
f0100c16:	74 0e                	je     f0100c26 <mon_showmappings+0x10c>
				cprintf("RW\\RW");
f0100c18:	c7 04 24 8c 51 10 f0 	movl   $0xf010518c,(%esp)
f0100c1f:	e8 22 2c 00 00       	call   f0103846 <cprintf>
f0100c24:	eb 2c                	jmp    f0100c52 <mon_showmappings+0x138>
			else
				cprintf("RW\\--");
f0100c26:	c7 04 24 92 51 10 f0 	movl   $0xf0105192,(%esp)
f0100c2d:	e8 14 2c 00 00       	call   f0103846 <cprintf>
f0100c32:	eb 1e                	jmp    f0100c52 <mon_showmappings+0x138>
			}
		else
			{
			if (*pte & PTE_U)
f0100c34:	a8 04                	test   $0x4,%al
f0100c36:	74 0e                	je     f0100c46 <mon_showmappings+0x12c>
				cprintf("R-\\R-");
f0100c38:	c7 04 24 98 51 10 f0 	movl   $0xf0105198,(%esp)
f0100c3f:	e8 02 2c 00 00       	call   f0103846 <cprintf>
f0100c44:	eb 0c                	jmp    f0100c52 <mon_showmappings+0x138>
			else
				cprintf("R-\\--");
f0100c46:	c7 04 24 9e 51 10 f0 	movl   $0xf010519e,(%esp)
f0100c4d:	e8 f4 2b 00 00       	call   f0103846 <cprintf>
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
f0100c5b:	c7 04 24 f0 54 10 f0 	movl   $0xf01054f0,(%esp)
f0100c62:	e8 df 2b 00 00       	call   f0103846 <cprintf>
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
f0100ca5:	c7 04 24 a4 51 10 f0 	movl   $0xf01051a4,(%esp)
f0100cac:	e8 95 2b 00 00       	call   f0103846 <cprintf>
	
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
f0100ce7:	c7 04 24 14 55 10 f0 	movl   $0xf0105514,(%esp)
f0100cee:	e8 53 2b 00 00       	call   f0103846 <cprintf>
			struct Eipdebuginfo info;
			info.eip_file = "<unknown>";
f0100cf3:	c7 45 d0 b6 51 10 f0 	movl   $0xf01051b6,-0x30(%ebp)
			info.eip_line = 0;
f0100cfa:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
			info.eip_fn_name = "<unknown>";
f0100d01:	c7 45 d8 b6 51 10 f0 	movl   $0xf01051b6,-0x28(%ebp)
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
f0100d20:	e8 75 30 00 00       	call   f0103d9a <debuginfo_eip>
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
f0100d6b:	c7 04 24 c0 51 10 f0 	movl   $0xf01051c0,(%esp)
f0100d72:	e8 cf 2a 00 00       	call   f0103846 <cprintf>
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
f0100db2:	c7 04 24 48 55 10 f0 	movl   $0xf0105548,(%esp)
f0100db9:	e8 88 2a 00 00       	call   f0103846 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100dbe:	c7 04 24 8c 55 10 f0 	movl   $0xf010558c,(%esp)
f0100dc5:	e8 7c 2a 00 00       	call   f0103846 <cprintf>


	while (1) {
		buf = readline("K> ");
f0100dca:	c7 04 24 d2 51 10 f0 	movl   $0xf01051d2,(%esp)
f0100dd1:	e8 aa 38 00 00       	call   f0104680 <readline>
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
f0100dfe:	c7 04 24 d6 51 10 f0 	movl   $0xf01051d6,(%esp)
f0100e05:	e8 cc 3a 00 00       	call   f01048d6 <strchr>
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
f0100e20:	c7 04 24 db 51 10 f0 	movl   $0xf01051db,(%esp)
f0100e27:	e8 1a 2a 00 00       	call   f0103846 <cprintf>
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
f0100e4f:	c7 04 24 d6 51 10 f0 	movl   $0xf01051d6,(%esp)
f0100e56:	e8 7b 3a 00 00       	call   f01048d6 <strchr>
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
f0100e71:	bb c0 56 10 f0       	mov    $0xf01056c0,%ebx
f0100e76:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100e7b:	8b 03                	mov    (%ebx),%eax
f0100e7d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e81:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100e84:	89 04 24             	mov    %eax,(%esp)
f0100e87:	e8 cf 39 00 00       	call   f010485b <strcmp>
f0100e8c:	85 c0                	test   %eax,%eax
f0100e8e:	75 24                	jne    f0100eb4 <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f0100e90:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0100e93:	8b 55 08             	mov    0x8(%ebp),%edx
f0100e96:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100e9a:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100e9d:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100ea1:	89 34 24             	mov    %esi,(%esp)
f0100ea4:	ff 14 85 c8 56 10 f0 	call   *-0xfefa938(,%eax,4)


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
f0100ec6:	c7 04 24 f8 51 10 f0 	movl   $0xf01051f8,(%esp)
f0100ecd:	e8 74 29 00 00       	call   f0103846 <cprintf>
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
f0100f51:	c7 44 24 08 7c 53 10 	movl   $0xf010537c,0x8(%esp)
f0100f58:	f0 
f0100f59:	c7 44 24 04 2f 03 00 	movl   $0x32f,0x4(%esp)
f0100f60:	00 
f0100f61:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
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
f0100fa4:	e8 2f 28 00 00       	call   f01037d8 <mc146818_read>
f0100fa9:	89 c6                	mov    %eax,%esi
f0100fab:	83 c3 01             	add    $0x1,%ebx
f0100fae:	89 1c 24             	mov    %ebx,(%esp)
f0100fb1:	e8 22 28 00 00       	call   f01037d8 <mc146818_read>
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
f0100fe6:	c7 44 24 08 14 57 10 	movl   $0xf0105714,0x8(%esp)
f0100fed:	f0 
f0100fee:	c7 44 24 04 6d 02 00 	movl   $0x26d,0x4(%esp)
f0100ff5:	00 
f0100ff6:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
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
f010107e:	c7 44 24 08 7c 53 10 	movl   $0xf010537c,0x8(%esp)
f0101085:	f0 
f0101086:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f010108d:	00 
f010108e:	c7 04 24 4d 5e 10 f0 	movl   $0xf0105e4d,(%esp)
f0101095:	e8 24 f0 ff ff       	call   f01000be <_panic>
			memset(page2kva(pp), 0x97, 128);
f010109a:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f01010a1:	00 
f01010a2:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f01010a9:	00 
	return (void *)(pa + KERNBASE);
f01010aa:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01010af:	89 04 24             	mov    %eax,(%esp)
f01010b2:	e8 7a 38 00 00       	call   f0104931 <memset>
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
f010112f:	c7 44 24 0c 5b 5e 10 	movl   $0xf0105e5b,0xc(%esp)
f0101136:	f0 
f0101137:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f010113e:	f0 
f010113f:	c7 44 24 04 87 02 00 	movl   $0x287,0x4(%esp)
f0101146:	00 
f0101147:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f010114e:	e8 6b ef ff ff       	call   f01000be <_panic>
		assert(pp < pages + npages);
f0101153:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0101156:	72 24                	jb     f010117c <check_page_free_list+0x1b7>
f0101158:	c7 44 24 0c 7c 5e 10 	movl   $0xf0105e7c,0xc(%esp)
f010115f:	f0 
f0101160:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0101167:	f0 
f0101168:	c7 44 24 04 88 02 00 	movl   $0x288,0x4(%esp)
f010116f:	00 
f0101170:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0101177:	e8 42 ef ff ff       	call   f01000be <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f010117c:	89 d0                	mov    %edx,%eax
f010117e:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0101181:	a8 07                	test   $0x7,%al
f0101183:	74 24                	je     f01011a9 <check_page_free_list+0x1e4>
f0101185:	c7 44 24 0c 38 57 10 	movl   $0xf0105738,0xc(%esp)
f010118c:	f0 
f010118d:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0101194:	f0 
f0101195:	c7 44 24 04 89 02 00 	movl   $0x289,0x4(%esp)
f010119c:	00 
f010119d:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f01011a4:	e8 15 ef ff ff       	call   f01000be <_panic>
f01011a9:	c1 f8 03             	sar    $0x3,%eax
f01011ac:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f01011af:	85 c0                	test   %eax,%eax
f01011b1:	75 24                	jne    f01011d7 <check_page_free_list+0x212>
f01011b3:	c7 44 24 0c 90 5e 10 	movl   $0xf0105e90,0xc(%esp)
f01011ba:	f0 
f01011bb:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f01011c2:	f0 
f01011c3:	c7 44 24 04 8c 02 00 	movl   $0x28c,0x4(%esp)
f01011ca:	00 
f01011cb:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f01011d2:	e8 e7 ee ff ff       	call   f01000be <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f01011d7:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f01011dc:	75 24                	jne    f0101202 <check_page_free_list+0x23d>
f01011de:	c7 44 24 0c a1 5e 10 	movl   $0xf0105ea1,0xc(%esp)
f01011e5:	f0 
f01011e6:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f01011ed:	f0 
f01011ee:	c7 44 24 04 8d 02 00 	movl   $0x28d,0x4(%esp)
f01011f5:	00 
f01011f6:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f01011fd:	e8 bc ee ff ff       	call   f01000be <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0101202:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0101207:	75 24                	jne    f010122d <check_page_free_list+0x268>
f0101209:	c7 44 24 0c 6c 57 10 	movl   $0xf010576c,0xc(%esp)
f0101210:	f0 
f0101211:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0101218:	f0 
f0101219:	c7 44 24 04 8e 02 00 	movl   $0x28e,0x4(%esp)
f0101220:	00 
f0101221:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0101228:	e8 91 ee ff ff       	call   f01000be <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f010122d:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0101232:	75 24                	jne    f0101258 <check_page_free_list+0x293>
f0101234:	c7 44 24 0c ba 5e 10 	movl   $0xf0105eba,0xc(%esp)
f010123b:	f0 
f010123c:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0101243:	f0 
f0101244:	c7 44 24 04 8f 02 00 	movl   $0x28f,0x4(%esp)
f010124b:	00 
f010124c:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
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
f010126d:	c7 44 24 08 7c 53 10 	movl   $0xf010537c,0x8(%esp)
f0101274:	f0 
f0101275:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f010127c:	00 
f010127d:	c7 04 24 4d 5e 10 f0 	movl   $0xf0105e4d,(%esp)
f0101284:	e8 35 ee ff ff       	call   f01000be <_panic>
	return (void *)(pa + KERNBASE);
f0101289:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f010128f:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0101292:	76 29                	jbe    f01012bd <check_page_free_list+0x2f8>
f0101294:	c7 44 24 0c 90 57 10 	movl   $0xf0105790,0xc(%esp)
f010129b:	f0 
f010129c:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f01012a3:	f0 
f01012a4:	c7 44 24 04 90 02 00 	movl   $0x290,0x4(%esp)
f01012ab:	00 
f01012ac:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
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
f01012ce:	c7 44 24 0c d4 5e 10 	movl   $0xf0105ed4,0xc(%esp)
f01012d5:	f0 
f01012d6:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f01012dd:	f0 
f01012de:	c7 44 24 04 98 02 00 	movl   $0x298,0x4(%esp)
f01012e5:	00 
f01012e6:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f01012ed:	e8 cc ed ff ff       	call   f01000be <_panic>
	assert(nfree_extmem > 0);
f01012f2:	85 f6                	test   %esi,%esi
f01012f4:	7f 24                	jg     f010131a <check_page_free_list+0x355>
f01012f6:	c7 44 24 0c e6 5e 10 	movl   $0xf0105ee6,0xc(%esp)
f01012fd:	f0 
f01012fe:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0101305:	f0 
f0101306:	c7 44 24 04 99 02 00 	movl   $0x299,0x4(%esp)
f010130d:	00 
f010130e:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
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
f010135c:	c7 44 24 08 d8 57 10 	movl   $0xf01057d8,0x8(%esp)
f0101363:	f0 
f0101364:	c7 44 24 04 0f 01 00 	movl   $0x10f,0x4(%esp)
f010136b:	00 
f010136c:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
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
f0101441:	c7 44 24 08 7c 53 10 	movl   $0xf010537c,0x8(%esp)
f0101448:	f0 
f0101449:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0101450:	00 
f0101451:	c7 04 24 4d 5e 10 f0 	movl   $0xf0105e4d,(%esp)
f0101458:	e8 61 ec ff ff       	call   f01000be <_panic>
			memset(page2kva(temp_alloc_page), 0, PGSIZE);
f010145d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101464:	00 
f0101465:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010146c:	00 
	return (void *)(pa + KERNBASE);
f010146d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101472:	89 04 24             	mov    %eax,(%esp)
f0101475:	e8 b7 34 00 00       	call   f0104931 <memset>
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
f01014f3:	c7 44 24 08 7c 53 10 	movl   $0xf010537c,0x8(%esp)
f01014fa:	f0 
f01014fb:	c7 44 24 04 80 01 00 	movl   $0x180,0x4(%esp)
f0101502:	00 
f0101503:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
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
f0101564:	c7 44 24 08 7c 53 10 	movl   $0xf010537c,0x8(%esp)
f010156b:	f0 
f010156c:	c7 44 24 04 8c 01 00 	movl   $0x18c,0x4(%esp)
f0101573:	00 
f0101574:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
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
f010164e:	c7 44 24 08 fc 57 10 	movl   $0xf01057fc,0x8(%esp)
f0101655:	f0 
f0101656:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f010165d:	00 
f010165e:	c7 04 24 4d 5e 10 f0 	movl   $0xf0105e4d,(%esp)
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
f010181a:	c7 04 24 1c 58 10 f0 	movl   $0xf010581c,(%esp)
f0101821:	e8 20 20 00 00       	call   f0103846 <cprintf>
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
f0101848:	e8 e4 30 00 00       	call   f0104931 <memset>
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
f010185d:	c7 44 24 08 d8 57 10 	movl   $0xf01057d8,0x8(%esp)
f0101864:	f0 
f0101865:	c7 44 24 04 8c 00 00 	movl   $0x8c,0x4(%esp)
f010186c:	00 
f010186d:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
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
f01018b2:	e8 7a 30 00 00       	call   f0104931 <memset>
	
	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env *) boot_alloc(NENV* sizeof (struct Env));
f01018b7:	b8 00 80 01 00       	mov    $0x18000,%eax
f01018bc:	e8 27 f6 ff ff       	call   f0100ee8 <boot_alloc>
f01018c1:	a3 28 f2 17 f0       	mov    %eax,0xf017f228
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01018c6:	e8 57 fa ff ff       	call   f0101322 <page_init>
	check_page_free_list(1);
f01018cb:	b8 01 00 00 00       	mov    $0x1,%eax
f01018d0:	e8 f0 f6 ff ff       	call   f0100fc5 <check_page_free_list>
	int nfree;
	struct Page *fl;
	char *c;
	int i;

	if (!pages)
f01018d5:	83 3d cc fe 17 f0 00 	cmpl   $0x0,0xf017fecc
f01018dc:	75 1c                	jne    f01018fa <mem_init+0x16a>
		panic("'pages' is a null pointer!");
f01018de:	c7 44 24 08 f7 5e 10 	movl   $0xf0105ef7,0x8(%esp)
f01018e5:	f0 
f01018e6:	c7 44 24 04 aa 02 00 	movl   $0x2aa,0x4(%esp)
f01018ed:	00 
f01018ee:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f01018f5:	e8 c4 e7 ff ff       	call   f01000be <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01018fa:	a1 20 f2 17 f0       	mov    0xf017f220,%eax
f01018ff:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101904:	85 c0                	test   %eax,%eax
f0101906:	74 09                	je     f0101911 <mem_init+0x181>
		++nfree;
f0101908:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010190b:	8b 00                	mov    (%eax),%eax
f010190d:	85 c0                	test   %eax,%eax
f010190f:	75 f7                	jne    f0101908 <mem_init+0x178>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101911:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101918:	e8 df fa ff ff       	call   f01013fc <page_alloc>
f010191d:	89 c6                	mov    %eax,%esi
f010191f:	85 c0                	test   %eax,%eax
f0101921:	75 24                	jne    f0101947 <mem_init+0x1b7>
f0101923:	c7 44 24 0c 12 5f 10 	movl   $0xf0105f12,0xc(%esp)
f010192a:	f0 
f010192b:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0101932:	f0 
f0101933:	c7 44 24 04 b2 02 00 	movl   $0x2b2,0x4(%esp)
f010193a:	00 
f010193b:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0101942:	e8 77 e7 ff ff       	call   f01000be <_panic>
	assert((pp1 = page_alloc(0)));
f0101947:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010194e:	e8 a9 fa ff ff       	call   f01013fc <page_alloc>
f0101953:	89 c7                	mov    %eax,%edi
f0101955:	85 c0                	test   %eax,%eax
f0101957:	75 24                	jne    f010197d <mem_init+0x1ed>
f0101959:	c7 44 24 0c 28 5f 10 	movl   $0xf0105f28,0xc(%esp)
f0101960:	f0 
f0101961:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0101968:	f0 
f0101969:	c7 44 24 04 b3 02 00 	movl   $0x2b3,0x4(%esp)
f0101970:	00 
f0101971:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0101978:	e8 41 e7 ff ff       	call   f01000be <_panic>
	assert((pp2 = page_alloc(0)));
f010197d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101984:	e8 73 fa ff ff       	call   f01013fc <page_alloc>
f0101989:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010198c:	85 c0                	test   %eax,%eax
f010198e:	75 24                	jne    f01019b4 <mem_init+0x224>
f0101990:	c7 44 24 0c 3e 5f 10 	movl   $0xf0105f3e,0xc(%esp)
f0101997:	f0 
f0101998:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f010199f:	f0 
f01019a0:	c7 44 24 04 b4 02 00 	movl   $0x2b4,0x4(%esp)
f01019a7:	00 
f01019a8:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f01019af:	e8 0a e7 ff ff       	call   f01000be <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01019b4:	39 fe                	cmp    %edi,%esi
f01019b6:	75 24                	jne    f01019dc <mem_init+0x24c>
f01019b8:	c7 44 24 0c 54 5f 10 	movl   $0xf0105f54,0xc(%esp)
f01019bf:	f0 
f01019c0:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f01019c7:	f0 
f01019c8:	c7 44 24 04 b7 02 00 	movl   $0x2b7,0x4(%esp)
f01019cf:	00 
f01019d0:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f01019d7:	e8 e2 e6 ff ff       	call   f01000be <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01019dc:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f01019df:	74 05                	je     f01019e6 <mem_init+0x256>
f01019e1:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f01019e4:	75 24                	jne    f0101a0a <mem_init+0x27a>
f01019e6:	c7 44 24 0c 58 58 10 	movl   $0xf0105858,0xc(%esp)
f01019ed:	f0 
f01019ee:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f01019f5:	f0 
f01019f6:	c7 44 24 04 b8 02 00 	movl   $0x2b8,0x4(%esp)
f01019fd:	00 
f01019fe:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0101a05:	e8 b4 e6 ff ff       	call   f01000be <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101a0a:	8b 15 cc fe 17 f0    	mov    0xf017fecc,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101a10:	a1 c4 fe 17 f0       	mov    0xf017fec4,%eax
f0101a15:	c1 e0 0c             	shl    $0xc,%eax
f0101a18:	89 f1                	mov    %esi,%ecx
f0101a1a:	29 d1                	sub    %edx,%ecx
f0101a1c:	c1 f9 03             	sar    $0x3,%ecx
f0101a1f:	c1 e1 0c             	shl    $0xc,%ecx
f0101a22:	39 c1                	cmp    %eax,%ecx
f0101a24:	72 24                	jb     f0101a4a <mem_init+0x2ba>
f0101a26:	c7 44 24 0c 66 5f 10 	movl   $0xf0105f66,0xc(%esp)
f0101a2d:	f0 
f0101a2e:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0101a35:	f0 
f0101a36:	c7 44 24 04 b9 02 00 	movl   $0x2b9,0x4(%esp)
f0101a3d:	00 
f0101a3e:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0101a45:	e8 74 e6 ff ff       	call   f01000be <_panic>
f0101a4a:	89 f9                	mov    %edi,%ecx
f0101a4c:	29 d1                	sub    %edx,%ecx
f0101a4e:	c1 f9 03             	sar    $0x3,%ecx
f0101a51:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101a54:	39 c8                	cmp    %ecx,%eax
f0101a56:	77 24                	ja     f0101a7c <mem_init+0x2ec>
f0101a58:	c7 44 24 0c 83 5f 10 	movl   $0xf0105f83,0xc(%esp)
f0101a5f:	f0 
f0101a60:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0101a67:	f0 
f0101a68:	c7 44 24 04 ba 02 00 	movl   $0x2ba,0x4(%esp)
f0101a6f:	00 
f0101a70:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0101a77:	e8 42 e6 ff ff       	call   f01000be <_panic>
f0101a7c:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101a7f:	29 d1                	sub    %edx,%ecx
f0101a81:	89 ca                	mov    %ecx,%edx
f0101a83:	c1 fa 03             	sar    $0x3,%edx
f0101a86:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f0101a89:	39 d0                	cmp    %edx,%eax
f0101a8b:	77 24                	ja     f0101ab1 <mem_init+0x321>
f0101a8d:	c7 44 24 0c a0 5f 10 	movl   $0xf0105fa0,0xc(%esp)
f0101a94:	f0 
f0101a95:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0101a9c:	f0 
f0101a9d:	c7 44 24 04 bb 02 00 	movl   $0x2bb,0x4(%esp)
f0101aa4:	00 
f0101aa5:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0101aac:	e8 0d e6 ff ff       	call   f01000be <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101ab1:	a1 20 f2 17 f0       	mov    0xf017f220,%eax
f0101ab6:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101ab9:	c7 05 20 f2 17 f0 00 	movl   $0x0,0xf017f220
f0101ac0:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101ac3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101aca:	e8 2d f9 ff ff       	call   f01013fc <page_alloc>
f0101acf:	85 c0                	test   %eax,%eax
f0101ad1:	74 24                	je     f0101af7 <mem_init+0x367>
f0101ad3:	c7 44 24 0c bd 5f 10 	movl   $0xf0105fbd,0xc(%esp)
f0101ada:	f0 
f0101adb:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0101ae2:	f0 
f0101ae3:	c7 44 24 04 c2 02 00 	movl   $0x2c2,0x4(%esp)
f0101aea:	00 
f0101aeb:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0101af2:	e8 c7 e5 ff ff       	call   f01000be <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101af7:	89 34 24             	mov    %esi,(%esp)
f0101afa:	e8 8a f9 ff ff       	call   f0101489 <page_free>
	page_free(pp1);
f0101aff:	89 3c 24             	mov    %edi,(%esp)
f0101b02:	e8 82 f9 ff ff       	call   f0101489 <page_free>
	page_free(pp2);
f0101b07:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b0a:	89 04 24             	mov    %eax,(%esp)
f0101b0d:	e8 77 f9 ff ff       	call   f0101489 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101b12:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b19:	e8 de f8 ff ff       	call   f01013fc <page_alloc>
f0101b1e:	89 c6                	mov    %eax,%esi
f0101b20:	85 c0                	test   %eax,%eax
f0101b22:	75 24                	jne    f0101b48 <mem_init+0x3b8>
f0101b24:	c7 44 24 0c 12 5f 10 	movl   $0xf0105f12,0xc(%esp)
f0101b2b:	f0 
f0101b2c:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0101b33:	f0 
f0101b34:	c7 44 24 04 c9 02 00 	movl   $0x2c9,0x4(%esp)
f0101b3b:	00 
f0101b3c:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0101b43:	e8 76 e5 ff ff       	call   f01000be <_panic>
	assert((pp1 = page_alloc(0)));
f0101b48:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b4f:	e8 a8 f8 ff ff       	call   f01013fc <page_alloc>
f0101b54:	89 c7                	mov    %eax,%edi
f0101b56:	85 c0                	test   %eax,%eax
f0101b58:	75 24                	jne    f0101b7e <mem_init+0x3ee>
f0101b5a:	c7 44 24 0c 28 5f 10 	movl   $0xf0105f28,0xc(%esp)
f0101b61:	f0 
f0101b62:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0101b69:	f0 
f0101b6a:	c7 44 24 04 ca 02 00 	movl   $0x2ca,0x4(%esp)
f0101b71:	00 
f0101b72:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0101b79:	e8 40 e5 ff ff       	call   f01000be <_panic>
	assert((pp2 = page_alloc(0)));
f0101b7e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b85:	e8 72 f8 ff ff       	call   f01013fc <page_alloc>
f0101b8a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101b8d:	85 c0                	test   %eax,%eax
f0101b8f:	75 24                	jne    f0101bb5 <mem_init+0x425>
f0101b91:	c7 44 24 0c 3e 5f 10 	movl   $0xf0105f3e,0xc(%esp)
f0101b98:	f0 
f0101b99:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0101ba0:	f0 
f0101ba1:	c7 44 24 04 cb 02 00 	movl   $0x2cb,0x4(%esp)
f0101ba8:	00 
f0101ba9:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0101bb0:	e8 09 e5 ff ff       	call   f01000be <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101bb5:	39 fe                	cmp    %edi,%esi
f0101bb7:	75 24                	jne    f0101bdd <mem_init+0x44d>
f0101bb9:	c7 44 24 0c 54 5f 10 	movl   $0xf0105f54,0xc(%esp)
f0101bc0:	f0 
f0101bc1:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0101bc8:	f0 
f0101bc9:	c7 44 24 04 cd 02 00 	movl   $0x2cd,0x4(%esp)
f0101bd0:	00 
f0101bd1:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0101bd8:	e8 e1 e4 ff ff       	call   f01000be <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101bdd:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101be0:	74 05                	je     f0101be7 <mem_init+0x457>
f0101be2:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101be5:	75 24                	jne    f0101c0b <mem_init+0x47b>
f0101be7:	c7 44 24 0c 58 58 10 	movl   $0xf0105858,0xc(%esp)
f0101bee:	f0 
f0101bef:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0101bf6:	f0 
f0101bf7:	c7 44 24 04 ce 02 00 	movl   $0x2ce,0x4(%esp)
f0101bfe:	00 
f0101bff:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0101c06:	e8 b3 e4 ff ff       	call   f01000be <_panic>
	assert(!page_alloc(0));
f0101c0b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c12:	e8 e5 f7 ff ff       	call   f01013fc <page_alloc>
f0101c17:	85 c0                	test   %eax,%eax
f0101c19:	74 24                	je     f0101c3f <mem_init+0x4af>
f0101c1b:	c7 44 24 0c bd 5f 10 	movl   $0xf0105fbd,0xc(%esp)
f0101c22:	f0 
f0101c23:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0101c2a:	f0 
f0101c2b:	c7 44 24 04 cf 02 00 	movl   $0x2cf,0x4(%esp)
f0101c32:	00 
f0101c33:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0101c3a:	e8 7f e4 ff ff       	call   f01000be <_panic>
f0101c3f:	89 f0                	mov    %esi,%eax
f0101c41:	2b 05 cc fe 17 f0    	sub    0xf017fecc,%eax
f0101c47:	c1 f8 03             	sar    $0x3,%eax
f0101c4a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101c4d:	89 c2                	mov    %eax,%edx
f0101c4f:	c1 ea 0c             	shr    $0xc,%edx
f0101c52:	3b 15 c4 fe 17 f0    	cmp    0xf017fec4,%edx
f0101c58:	72 20                	jb     f0101c7a <mem_init+0x4ea>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101c5a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101c5e:	c7 44 24 08 7c 53 10 	movl   $0xf010537c,0x8(%esp)
f0101c65:	f0 
f0101c66:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0101c6d:	00 
f0101c6e:	c7 04 24 4d 5e 10 f0 	movl   $0xf0105e4d,(%esp)
f0101c75:	e8 44 e4 ff ff       	call   f01000be <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101c7a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101c81:	00 
f0101c82:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101c89:	00 
	return (void *)(pa + KERNBASE);
f0101c8a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101c8f:	89 04 24             	mov    %eax,(%esp)
f0101c92:	e8 9a 2c 00 00       	call   f0104931 <memset>
	page_free(pp0);
f0101c97:	89 34 24             	mov    %esi,(%esp)
f0101c9a:	e8 ea f7 ff ff       	call   f0101489 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101c9f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101ca6:	e8 51 f7 ff ff       	call   f01013fc <page_alloc>
f0101cab:	85 c0                	test   %eax,%eax
f0101cad:	75 24                	jne    f0101cd3 <mem_init+0x543>
f0101caf:	c7 44 24 0c cc 5f 10 	movl   $0xf0105fcc,0xc(%esp)
f0101cb6:	f0 
f0101cb7:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0101cbe:	f0 
f0101cbf:	c7 44 24 04 d4 02 00 	movl   $0x2d4,0x4(%esp)
f0101cc6:	00 
f0101cc7:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0101cce:	e8 eb e3 ff ff       	call   f01000be <_panic>
	assert(pp && pp0 == pp);
f0101cd3:	39 c6                	cmp    %eax,%esi
f0101cd5:	74 24                	je     f0101cfb <mem_init+0x56b>
f0101cd7:	c7 44 24 0c ea 5f 10 	movl   $0xf0105fea,0xc(%esp)
f0101cde:	f0 
f0101cdf:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0101ce6:	f0 
f0101ce7:	c7 44 24 04 d5 02 00 	movl   $0x2d5,0x4(%esp)
f0101cee:	00 
f0101cef:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0101cf6:	e8 c3 e3 ff ff       	call   f01000be <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101cfb:	89 f2                	mov    %esi,%edx
f0101cfd:	2b 15 cc fe 17 f0    	sub    0xf017fecc,%edx
f0101d03:	c1 fa 03             	sar    $0x3,%edx
f0101d06:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101d09:	89 d0                	mov    %edx,%eax
f0101d0b:	c1 e8 0c             	shr    $0xc,%eax
f0101d0e:	3b 05 c4 fe 17 f0    	cmp    0xf017fec4,%eax
f0101d14:	72 20                	jb     f0101d36 <mem_init+0x5a6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101d16:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101d1a:	c7 44 24 08 7c 53 10 	movl   $0xf010537c,0x8(%esp)
f0101d21:	f0 
f0101d22:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0101d29:	00 
f0101d2a:	c7 04 24 4d 5e 10 f0 	movl   $0xf0105e4d,(%esp)
f0101d31:	e8 88 e3 ff ff       	call   f01000be <_panic>
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101d36:	80 ba 00 00 00 f0 00 	cmpb   $0x0,-0x10000000(%edx)
f0101d3d:	75 11                	jne    f0101d50 <mem_init+0x5c0>
f0101d3f:	8d 82 01 00 00 f0    	lea    -0xfffffff(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0101d45:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101d4b:	80 38 00             	cmpb   $0x0,(%eax)
f0101d4e:	74 24                	je     f0101d74 <mem_init+0x5e4>
f0101d50:	c7 44 24 0c fa 5f 10 	movl   $0xf0105ffa,0xc(%esp)
f0101d57:	f0 
f0101d58:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0101d5f:	f0 
f0101d60:	c7 44 24 04 d8 02 00 	movl   $0x2d8,0x4(%esp)
f0101d67:	00 
f0101d68:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0101d6f:	e8 4a e3 ff ff       	call   f01000be <_panic>
f0101d74:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101d77:	39 d0                	cmp    %edx,%eax
f0101d79:	75 d0                	jne    f0101d4b <mem_init+0x5bb>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101d7b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101d7e:	89 15 20 f2 17 f0    	mov    %edx,0xf017f220

	// free the pages we took
	page_free(pp0);
f0101d84:	89 34 24             	mov    %esi,(%esp)
f0101d87:	e8 fd f6 ff ff       	call   f0101489 <page_free>
	page_free(pp1);
f0101d8c:	89 3c 24             	mov    %edi,(%esp)
f0101d8f:	e8 f5 f6 ff ff       	call   f0101489 <page_free>
	page_free(pp2);
f0101d94:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d97:	89 04 24             	mov    %eax,(%esp)
f0101d9a:	e8 ea f6 ff ff       	call   f0101489 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101d9f:	a1 20 f2 17 f0       	mov    0xf017f220,%eax
f0101da4:	85 c0                	test   %eax,%eax
f0101da6:	74 09                	je     f0101db1 <mem_init+0x621>
		--nfree;
f0101da8:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101dab:	8b 00                	mov    (%eax),%eax
f0101dad:	85 c0                	test   %eax,%eax
f0101daf:	75 f7                	jne    f0101da8 <mem_init+0x618>
		--nfree;
	assert(nfree == 0);
f0101db1:	85 db                	test   %ebx,%ebx
f0101db3:	74 24                	je     f0101dd9 <mem_init+0x649>
f0101db5:	c7 44 24 0c 04 60 10 	movl   $0xf0106004,0xc(%esp)
f0101dbc:	f0 
f0101dbd:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0101dc4:	f0 
f0101dc5:	c7 44 24 04 e5 02 00 	movl   $0x2e5,0x4(%esp)
f0101dcc:	00 
f0101dcd:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0101dd4:	e8 e5 e2 ff ff       	call   f01000be <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101dd9:	c7 04 24 78 58 10 f0 	movl   $0xf0105878,(%esp)
f0101de0:	e8 61 1a 00 00       	call   f0103846 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101de5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101dec:	e8 0b f6 ff ff       	call   f01013fc <page_alloc>
f0101df1:	89 c3                	mov    %eax,%ebx
f0101df3:	85 c0                	test   %eax,%eax
f0101df5:	75 24                	jne    f0101e1b <mem_init+0x68b>
f0101df7:	c7 44 24 0c 12 5f 10 	movl   $0xf0105f12,0xc(%esp)
f0101dfe:	f0 
f0101dff:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0101e06:	f0 
f0101e07:	c7 44 24 04 43 03 00 	movl   $0x343,0x4(%esp)
f0101e0e:	00 
f0101e0f:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0101e16:	e8 a3 e2 ff ff       	call   f01000be <_panic>
	assert((pp1 = page_alloc(0)));
f0101e1b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101e22:	e8 d5 f5 ff ff       	call   f01013fc <page_alloc>
f0101e27:	89 c7                	mov    %eax,%edi
f0101e29:	85 c0                	test   %eax,%eax
f0101e2b:	75 24                	jne    f0101e51 <mem_init+0x6c1>
f0101e2d:	c7 44 24 0c 28 5f 10 	movl   $0xf0105f28,0xc(%esp)
f0101e34:	f0 
f0101e35:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0101e3c:	f0 
f0101e3d:	c7 44 24 04 44 03 00 	movl   $0x344,0x4(%esp)
f0101e44:	00 
f0101e45:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0101e4c:	e8 6d e2 ff ff       	call   f01000be <_panic>
	assert((pp2 = page_alloc(0)));
f0101e51:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101e58:	e8 9f f5 ff ff       	call   f01013fc <page_alloc>
f0101e5d:	89 c6                	mov    %eax,%esi
f0101e5f:	85 c0                	test   %eax,%eax
f0101e61:	75 24                	jne    f0101e87 <mem_init+0x6f7>
f0101e63:	c7 44 24 0c 3e 5f 10 	movl   $0xf0105f3e,0xc(%esp)
f0101e6a:	f0 
f0101e6b:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0101e72:	f0 
f0101e73:	c7 44 24 04 45 03 00 	movl   $0x345,0x4(%esp)
f0101e7a:	00 
f0101e7b:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0101e82:	e8 37 e2 ff ff       	call   f01000be <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101e87:	39 fb                	cmp    %edi,%ebx
f0101e89:	75 24                	jne    f0101eaf <mem_init+0x71f>
f0101e8b:	c7 44 24 0c 54 5f 10 	movl   $0xf0105f54,0xc(%esp)
f0101e92:	f0 
f0101e93:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0101e9a:	f0 
f0101e9b:	c7 44 24 04 48 03 00 	movl   $0x348,0x4(%esp)
f0101ea2:	00 
f0101ea3:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0101eaa:	e8 0f e2 ff ff       	call   f01000be <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101eaf:	39 c7                	cmp    %eax,%edi
f0101eb1:	74 04                	je     f0101eb7 <mem_init+0x727>
f0101eb3:	39 c3                	cmp    %eax,%ebx
f0101eb5:	75 24                	jne    f0101edb <mem_init+0x74b>
f0101eb7:	c7 44 24 0c 58 58 10 	movl   $0xf0105858,0xc(%esp)
f0101ebe:	f0 
f0101ebf:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0101ec6:	f0 
f0101ec7:	c7 44 24 04 49 03 00 	movl   $0x349,0x4(%esp)
f0101ece:	00 
f0101ecf:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0101ed6:	e8 e3 e1 ff ff       	call   f01000be <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101edb:	8b 15 20 f2 17 f0    	mov    0xf017f220,%edx
f0101ee1:	89 55 cc             	mov    %edx,-0x34(%ebp)
	page_free_list = 0;
f0101ee4:	c7 05 20 f2 17 f0 00 	movl   $0x0,0xf017f220
f0101eeb:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101eee:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ef5:	e8 02 f5 ff ff       	call   f01013fc <page_alloc>
f0101efa:	85 c0                	test   %eax,%eax
f0101efc:	74 24                	je     f0101f22 <mem_init+0x792>
f0101efe:	c7 44 24 0c bd 5f 10 	movl   $0xf0105fbd,0xc(%esp)
f0101f05:	f0 
f0101f06:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0101f0d:	f0 
f0101f0e:	c7 44 24 04 50 03 00 	movl   $0x350,0x4(%esp)
f0101f15:	00 
f0101f16:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0101f1d:	e8 9c e1 ff ff       	call   f01000be <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101f22:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101f25:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101f29:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101f30:	00 
f0101f31:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f0101f36:	89 04 24             	mov    %eax,(%esp)
f0101f39:	e8 d1 f6 ff ff       	call   f010160f <page_lookup>
f0101f3e:	85 c0                	test   %eax,%eax
f0101f40:	74 24                	je     f0101f66 <mem_init+0x7d6>
f0101f42:	c7 44 24 0c 98 58 10 	movl   $0xf0105898,0xc(%esp)
f0101f49:	f0 
f0101f4a:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0101f51:	f0 
f0101f52:	c7 44 24 04 53 03 00 	movl   $0x353,0x4(%esp)
f0101f59:	00 
f0101f5a:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0101f61:	e8 58 e1 ff ff       	call   f01000be <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101f66:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f6d:	00 
f0101f6e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f75:	00 
f0101f76:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101f7a:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f0101f7f:	89 04 24             	mov    %eax,(%esp)
f0101f82:	e8 5f f7 ff ff       	call   f01016e6 <page_insert>
f0101f87:	85 c0                	test   %eax,%eax
f0101f89:	78 24                	js     f0101faf <mem_init+0x81f>
f0101f8b:	c7 44 24 0c d0 58 10 	movl   $0xf01058d0,0xc(%esp)
f0101f92:	f0 
f0101f93:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0101f9a:	f0 
f0101f9b:	c7 44 24 04 56 03 00 	movl   $0x356,0x4(%esp)
f0101fa2:	00 
f0101fa3:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0101faa:	e8 0f e1 ff ff       	call   f01000be <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101faf:	89 1c 24             	mov    %ebx,(%esp)
f0101fb2:	e8 d2 f4 ff ff       	call   f0101489 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101fb7:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101fbe:	00 
f0101fbf:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101fc6:	00 
f0101fc7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101fcb:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f0101fd0:	89 04 24             	mov    %eax,(%esp)
f0101fd3:	e8 0e f7 ff ff       	call   f01016e6 <page_insert>
f0101fd8:	85 c0                	test   %eax,%eax
f0101fda:	74 24                	je     f0102000 <mem_init+0x870>
f0101fdc:	c7 44 24 0c 00 59 10 	movl   $0xf0105900,0xc(%esp)
f0101fe3:	f0 
f0101fe4:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0101feb:	f0 
f0101fec:	c7 44 24 04 5a 03 00 	movl   $0x35a,0x4(%esp)
f0101ff3:	00 
f0101ff4:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0101ffb:	e8 be e0 ff ff       	call   f01000be <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102000:	8b 0d c8 fe 17 f0    	mov    0xf017fec8,%ecx
f0102006:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102009:	a1 cc fe 17 f0       	mov    0xf017fecc,%eax
f010200e:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102011:	8b 11                	mov    (%ecx),%edx
f0102013:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102019:	89 d8                	mov    %ebx,%eax
f010201b:	2b 45 d0             	sub    -0x30(%ebp),%eax
f010201e:	c1 f8 03             	sar    $0x3,%eax
f0102021:	c1 e0 0c             	shl    $0xc,%eax
f0102024:	39 c2                	cmp    %eax,%edx
f0102026:	74 24                	je     f010204c <mem_init+0x8bc>
f0102028:	c7 44 24 0c 30 59 10 	movl   $0xf0105930,0xc(%esp)
f010202f:	f0 
f0102030:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0102037:	f0 
f0102038:	c7 44 24 04 5b 03 00 	movl   $0x35b,0x4(%esp)
f010203f:	00 
f0102040:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102047:	e8 72 e0 ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010204c:	ba 00 00 00 00       	mov    $0x0,%edx
f0102051:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102054:	e8 c9 ee ff ff       	call   f0100f22 <check_va2pa>
f0102059:	89 fa                	mov    %edi,%edx
f010205b:	2b 55 d0             	sub    -0x30(%ebp),%edx
f010205e:	c1 fa 03             	sar    $0x3,%edx
f0102061:	c1 e2 0c             	shl    $0xc,%edx
f0102064:	39 d0                	cmp    %edx,%eax
f0102066:	74 24                	je     f010208c <mem_init+0x8fc>
f0102068:	c7 44 24 0c 58 59 10 	movl   $0xf0105958,0xc(%esp)
f010206f:	f0 
f0102070:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0102077:	f0 
f0102078:	c7 44 24 04 5c 03 00 	movl   $0x35c,0x4(%esp)
f010207f:	00 
f0102080:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102087:	e8 32 e0 ff ff       	call   f01000be <_panic>
	assert(pp1->pp_ref == 1);
f010208c:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102091:	74 24                	je     f01020b7 <mem_init+0x927>
f0102093:	c7 44 24 0c 0f 60 10 	movl   $0xf010600f,0xc(%esp)
f010209a:	f0 
f010209b:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f01020a2:	f0 
f01020a3:	c7 44 24 04 5d 03 00 	movl   $0x35d,0x4(%esp)
f01020aa:	00 
f01020ab:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f01020b2:	e8 07 e0 ff ff       	call   f01000be <_panic>
	assert(pp0->pp_ref == 1);
f01020b7:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01020bc:	74 24                	je     f01020e2 <mem_init+0x952>
f01020be:	c7 44 24 0c 20 60 10 	movl   $0xf0106020,0xc(%esp)
f01020c5:	f0 
f01020c6:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f01020cd:	f0 
f01020ce:	c7 44 24 04 5e 03 00 	movl   $0x35e,0x4(%esp)
f01020d5:	00 
f01020d6:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f01020dd:	e8 dc df ff ff       	call   f01000be <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01020e2:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01020e9:	00 
f01020ea:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01020f1:	00 
f01020f2:	89 74 24 04          	mov    %esi,0x4(%esp)
f01020f6:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01020f9:	89 14 24             	mov    %edx,(%esp)
f01020fc:	e8 e5 f5 ff ff       	call   f01016e6 <page_insert>
f0102101:	85 c0                	test   %eax,%eax
f0102103:	74 24                	je     f0102129 <mem_init+0x999>
f0102105:	c7 44 24 0c 88 59 10 	movl   $0xf0105988,0xc(%esp)
f010210c:	f0 
f010210d:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0102114:	f0 
f0102115:	c7 44 24 04 61 03 00 	movl   $0x361,0x4(%esp)
f010211c:	00 
f010211d:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102124:	e8 95 df ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102129:	ba 00 10 00 00       	mov    $0x1000,%edx
f010212e:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f0102133:	e8 ea ed ff ff       	call   f0100f22 <check_va2pa>
f0102138:	89 f2                	mov    %esi,%edx
f010213a:	2b 15 cc fe 17 f0    	sub    0xf017fecc,%edx
f0102140:	c1 fa 03             	sar    $0x3,%edx
f0102143:	c1 e2 0c             	shl    $0xc,%edx
f0102146:	39 d0                	cmp    %edx,%eax
f0102148:	74 24                	je     f010216e <mem_init+0x9de>
f010214a:	c7 44 24 0c c4 59 10 	movl   $0xf01059c4,0xc(%esp)
f0102151:	f0 
f0102152:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0102159:	f0 
f010215a:	c7 44 24 04 62 03 00 	movl   $0x362,0x4(%esp)
f0102161:	00 
f0102162:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102169:	e8 50 df ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 1);
f010216e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102173:	74 24                	je     f0102199 <mem_init+0xa09>
f0102175:	c7 44 24 0c 31 60 10 	movl   $0xf0106031,0xc(%esp)
f010217c:	f0 
f010217d:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0102184:	f0 
f0102185:	c7 44 24 04 63 03 00 	movl   $0x363,0x4(%esp)
f010218c:	00 
f010218d:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102194:	e8 25 df ff ff       	call   f01000be <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102199:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01021a0:	e8 57 f2 ff ff       	call   f01013fc <page_alloc>
f01021a5:	85 c0                	test   %eax,%eax
f01021a7:	74 24                	je     f01021cd <mem_init+0xa3d>
f01021a9:	c7 44 24 0c bd 5f 10 	movl   $0xf0105fbd,0xc(%esp)
f01021b0:	f0 
f01021b1:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f01021b8:	f0 
f01021b9:	c7 44 24 04 66 03 00 	movl   $0x366,0x4(%esp)
f01021c0:	00 
f01021c1:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f01021c8:	e8 f1 de ff ff       	call   f01000be <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01021cd:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01021d4:	00 
f01021d5:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01021dc:	00 
f01021dd:	89 74 24 04          	mov    %esi,0x4(%esp)
f01021e1:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f01021e6:	89 04 24             	mov    %eax,(%esp)
f01021e9:	e8 f8 f4 ff ff       	call   f01016e6 <page_insert>
f01021ee:	85 c0                	test   %eax,%eax
f01021f0:	74 24                	je     f0102216 <mem_init+0xa86>
f01021f2:	c7 44 24 0c 88 59 10 	movl   $0xf0105988,0xc(%esp)
f01021f9:	f0 
f01021fa:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0102201:	f0 
f0102202:	c7 44 24 04 69 03 00 	movl   $0x369,0x4(%esp)
f0102209:	00 
f010220a:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102211:	e8 a8 de ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102216:	ba 00 10 00 00       	mov    $0x1000,%edx
f010221b:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f0102220:	e8 fd ec ff ff       	call   f0100f22 <check_va2pa>
f0102225:	89 f2                	mov    %esi,%edx
f0102227:	2b 15 cc fe 17 f0    	sub    0xf017fecc,%edx
f010222d:	c1 fa 03             	sar    $0x3,%edx
f0102230:	c1 e2 0c             	shl    $0xc,%edx
f0102233:	39 d0                	cmp    %edx,%eax
f0102235:	74 24                	je     f010225b <mem_init+0xacb>
f0102237:	c7 44 24 0c c4 59 10 	movl   $0xf01059c4,0xc(%esp)
f010223e:	f0 
f010223f:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0102246:	f0 
f0102247:	c7 44 24 04 6a 03 00 	movl   $0x36a,0x4(%esp)
f010224e:	00 
f010224f:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102256:	e8 63 de ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 1);
f010225b:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102260:	74 24                	je     f0102286 <mem_init+0xaf6>
f0102262:	c7 44 24 0c 31 60 10 	movl   $0xf0106031,0xc(%esp)
f0102269:	f0 
f010226a:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0102271:	f0 
f0102272:	c7 44 24 04 6b 03 00 	movl   $0x36b,0x4(%esp)
f0102279:	00 
f010227a:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102281:	e8 38 de ff ff       	call   f01000be <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0102286:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010228d:	e8 6a f1 ff ff       	call   f01013fc <page_alloc>
f0102292:	85 c0                	test   %eax,%eax
f0102294:	74 24                	je     f01022ba <mem_init+0xb2a>
f0102296:	c7 44 24 0c bd 5f 10 	movl   $0xf0105fbd,0xc(%esp)
f010229d:	f0 
f010229e:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f01022a5:	f0 
f01022a6:	c7 44 24 04 6f 03 00 	movl   $0x36f,0x4(%esp)
f01022ad:	00 
f01022ae:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f01022b5:	e8 04 de ff ff       	call   f01000be <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f01022ba:	8b 15 c8 fe 17 f0    	mov    0xf017fec8,%edx
f01022c0:	8b 02                	mov    (%edx),%eax
f01022c2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01022c7:	89 c1                	mov    %eax,%ecx
f01022c9:	c1 e9 0c             	shr    $0xc,%ecx
f01022cc:	3b 0d c4 fe 17 f0    	cmp    0xf017fec4,%ecx
f01022d2:	72 20                	jb     f01022f4 <mem_init+0xb64>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01022d4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01022d8:	c7 44 24 08 7c 53 10 	movl   $0xf010537c,0x8(%esp)
f01022df:	f0 
f01022e0:	c7 44 24 04 72 03 00 	movl   $0x372,0x4(%esp)
f01022e7:	00 
f01022e8:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f01022ef:	e8 ca dd ff ff       	call   f01000be <_panic>
	return (void *)(pa + KERNBASE);
f01022f4:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01022f9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01022fc:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102303:	00 
f0102304:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010230b:	00 
f010230c:	89 14 24             	mov    %edx,(%esp)
f010230f:	e8 ad f1 ff ff       	call   f01014c1 <pgdir_walk>
f0102314:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102317:	83 c2 04             	add    $0x4,%edx
f010231a:	39 d0                	cmp    %edx,%eax
f010231c:	74 24                	je     f0102342 <mem_init+0xbb2>
f010231e:	c7 44 24 0c f4 59 10 	movl   $0xf01059f4,0xc(%esp)
f0102325:	f0 
f0102326:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f010232d:	f0 
f010232e:	c7 44 24 04 73 03 00 	movl   $0x373,0x4(%esp)
f0102335:	00 
f0102336:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f010233d:	e8 7c dd ff ff       	call   f01000be <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102342:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0102349:	00 
f010234a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102351:	00 
f0102352:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102356:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f010235b:	89 04 24             	mov    %eax,(%esp)
f010235e:	e8 83 f3 ff ff       	call   f01016e6 <page_insert>
f0102363:	85 c0                	test   %eax,%eax
f0102365:	74 24                	je     f010238b <mem_init+0xbfb>
f0102367:	c7 44 24 0c 34 5a 10 	movl   $0xf0105a34,0xc(%esp)
f010236e:	f0 
f010236f:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0102376:	f0 
f0102377:	c7 44 24 04 76 03 00 	movl   $0x376,0x4(%esp)
f010237e:	00 
f010237f:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102386:	e8 33 dd ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010238b:	8b 0d c8 fe 17 f0    	mov    0xf017fec8,%ecx
f0102391:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0102394:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102399:	89 c8                	mov    %ecx,%eax
f010239b:	e8 82 eb ff ff       	call   f0100f22 <check_va2pa>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01023a0:	89 f2                	mov    %esi,%edx
f01023a2:	2b 15 cc fe 17 f0    	sub    0xf017fecc,%edx
f01023a8:	c1 fa 03             	sar    $0x3,%edx
f01023ab:	c1 e2 0c             	shl    $0xc,%edx
f01023ae:	39 d0                	cmp    %edx,%eax
f01023b0:	74 24                	je     f01023d6 <mem_init+0xc46>
f01023b2:	c7 44 24 0c c4 59 10 	movl   $0xf01059c4,0xc(%esp)
f01023b9:	f0 
f01023ba:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f01023c1:	f0 
f01023c2:	c7 44 24 04 77 03 00 	movl   $0x377,0x4(%esp)
f01023c9:	00 
f01023ca:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f01023d1:	e8 e8 dc ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 1);
f01023d6:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01023db:	74 24                	je     f0102401 <mem_init+0xc71>
f01023dd:	c7 44 24 0c 31 60 10 	movl   $0xf0106031,0xc(%esp)
f01023e4:	f0 
f01023e5:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f01023ec:	f0 
f01023ed:	c7 44 24 04 78 03 00 	movl   $0x378,0x4(%esp)
f01023f4:	00 
f01023f5:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f01023fc:	e8 bd dc ff ff       	call   f01000be <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0102401:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102408:	00 
f0102409:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102410:	00 
f0102411:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102414:	89 04 24             	mov    %eax,(%esp)
f0102417:	e8 a5 f0 ff ff       	call   f01014c1 <pgdir_walk>
f010241c:	f6 00 04             	testb  $0x4,(%eax)
f010241f:	75 24                	jne    f0102445 <mem_init+0xcb5>
f0102421:	c7 44 24 0c 74 5a 10 	movl   $0xf0105a74,0xc(%esp)
f0102428:	f0 
f0102429:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0102430:	f0 
f0102431:	c7 44 24 04 79 03 00 	movl   $0x379,0x4(%esp)
f0102438:	00 
f0102439:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102440:	e8 79 dc ff ff       	call   f01000be <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0102445:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f010244a:	f6 00 04             	testb  $0x4,(%eax)
f010244d:	75 24                	jne    f0102473 <mem_init+0xce3>
f010244f:	c7 44 24 0c 42 60 10 	movl   $0xf0106042,0xc(%esp)
f0102456:	f0 
f0102457:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f010245e:	f0 
f010245f:	c7 44 24 04 7a 03 00 	movl   $0x37a,0x4(%esp)
f0102466:	00 
f0102467:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f010246e:	e8 4b dc ff ff       	call   f01000be <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102473:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010247a:	00 
f010247b:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0102482:	00 
f0102483:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102487:	89 04 24             	mov    %eax,(%esp)
f010248a:	e8 57 f2 ff ff       	call   f01016e6 <page_insert>
f010248f:	85 c0                	test   %eax,%eax
f0102491:	78 24                	js     f01024b7 <mem_init+0xd27>
f0102493:	c7 44 24 0c a8 5a 10 	movl   $0xf0105aa8,0xc(%esp)
f010249a:	f0 
f010249b:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f01024a2:	f0 
f01024a3:	c7 44 24 04 7d 03 00 	movl   $0x37d,0x4(%esp)
f01024aa:	00 
f01024ab:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f01024b2:	e8 07 dc ff ff       	call   f01000be <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f01024b7:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01024be:	00 
f01024bf:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01024c6:	00 
f01024c7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01024cb:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f01024d0:	89 04 24             	mov    %eax,(%esp)
f01024d3:	e8 0e f2 ff ff       	call   f01016e6 <page_insert>
f01024d8:	85 c0                	test   %eax,%eax
f01024da:	74 24                	je     f0102500 <mem_init+0xd70>
f01024dc:	c7 44 24 0c e0 5a 10 	movl   $0xf0105ae0,0xc(%esp)
f01024e3:	f0 
f01024e4:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f01024eb:	f0 
f01024ec:	c7 44 24 04 80 03 00 	movl   $0x380,0x4(%esp)
f01024f3:	00 
f01024f4:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f01024fb:	e8 be db ff ff       	call   f01000be <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102500:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102507:	00 
f0102508:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010250f:	00 
f0102510:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f0102515:	89 04 24             	mov    %eax,(%esp)
f0102518:	e8 a4 ef ff ff       	call   f01014c1 <pgdir_walk>
f010251d:	f6 00 04             	testb  $0x4,(%eax)
f0102520:	74 24                	je     f0102546 <mem_init+0xdb6>
f0102522:	c7 44 24 0c 1c 5b 10 	movl   $0xf0105b1c,0xc(%esp)
f0102529:	f0 
f010252a:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0102531:	f0 
f0102532:	c7 44 24 04 81 03 00 	movl   $0x381,0x4(%esp)
f0102539:	00 
f010253a:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102541:	e8 78 db ff ff       	call   f01000be <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0102546:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f010254b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010254e:	ba 00 00 00 00       	mov    $0x0,%edx
f0102553:	e8 ca e9 ff ff       	call   f0100f22 <check_va2pa>
f0102558:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010255b:	89 f8                	mov    %edi,%eax
f010255d:	2b 05 cc fe 17 f0    	sub    0xf017fecc,%eax
f0102563:	c1 f8 03             	sar    $0x3,%eax
f0102566:	c1 e0 0c             	shl    $0xc,%eax
f0102569:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f010256c:	74 24                	je     f0102592 <mem_init+0xe02>
f010256e:	c7 44 24 0c 54 5b 10 	movl   $0xf0105b54,0xc(%esp)
f0102575:	f0 
f0102576:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f010257d:	f0 
f010257e:	c7 44 24 04 84 03 00 	movl   $0x384,0x4(%esp)
f0102585:	00 
f0102586:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f010258d:	e8 2c db ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102592:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102597:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010259a:	e8 83 e9 ff ff       	call   f0100f22 <check_va2pa>
f010259f:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01025a2:	74 24                	je     f01025c8 <mem_init+0xe38>
f01025a4:	c7 44 24 0c 80 5b 10 	movl   $0xf0105b80,0xc(%esp)
f01025ab:	f0 
f01025ac:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f01025b3:	f0 
f01025b4:	c7 44 24 04 85 03 00 	movl   $0x385,0x4(%esp)
f01025bb:	00 
f01025bc:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f01025c3:	e8 f6 da ff ff       	call   f01000be <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f01025c8:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f01025cd:	74 24                	je     f01025f3 <mem_init+0xe63>
f01025cf:	c7 44 24 0c 58 60 10 	movl   $0xf0106058,0xc(%esp)
f01025d6:	f0 
f01025d7:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f01025de:	f0 
f01025df:	c7 44 24 04 87 03 00 	movl   $0x387,0x4(%esp)
f01025e6:	00 
f01025e7:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f01025ee:	e8 cb da ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 0);
f01025f3:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01025f8:	74 24                	je     f010261e <mem_init+0xe8e>
f01025fa:	c7 44 24 0c 69 60 10 	movl   $0xf0106069,0xc(%esp)
f0102601:	f0 
f0102602:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0102609:	f0 
f010260a:	c7 44 24 04 88 03 00 	movl   $0x388,0x4(%esp)
f0102611:	00 
f0102612:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102619:	e8 a0 da ff ff       	call   f01000be <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f010261e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102625:	e8 d2 ed ff ff       	call   f01013fc <page_alloc>
f010262a:	85 c0                	test   %eax,%eax
f010262c:	74 04                	je     f0102632 <mem_init+0xea2>
f010262e:	39 c6                	cmp    %eax,%esi
f0102630:	74 24                	je     f0102656 <mem_init+0xec6>
f0102632:	c7 44 24 0c b0 5b 10 	movl   $0xf0105bb0,0xc(%esp)
f0102639:	f0 
f010263a:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0102641:	f0 
f0102642:	c7 44 24 04 8b 03 00 	movl   $0x38b,0x4(%esp)
f0102649:	00 
f010264a:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102651:	e8 68 da ff ff       	call   f01000be <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0102656:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010265d:	00 
f010265e:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f0102663:	89 04 24             	mov    %eax,(%esp)
f0102666:	e8 27 f0 ff ff       	call   f0101692 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010266b:	8b 15 c8 fe 17 f0    	mov    0xf017fec8,%edx
f0102671:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0102674:	ba 00 00 00 00       	mov    $0x0,%edx
f0102679:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010267c:	e8 a1 e8 ff ff       	call   f0100f22 <check_va2pa>
f0102681:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102684:	74 24                	je     f01026aa <mem_init+0xf1a>
f0102686:	c7 44 24 0c d4 5b 10 	movl   $0xf0105bd4,0xc(%esp)
f010268d:	f0 
f010268e:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0102695:	f0 
f0102696:	c7 44 24 04 8f 03 00 	movl   $0x38f,0x4(%esp)
f010269d:	00 
f010269e:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f01026a5:	e8 14 da ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01026aa:	ba 00 10 00 00       	mov    $0x1000,%edx
f01026af:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01026b2:	e8 6b e8 ff ff       	call   f0100f22 <check_va2pa>
f01026b7:	89 fa                	mov    %edi,%edx
f01026b9:	2b 15 cc fe 17 f0    	sub    0xf017fecc,%edx
f01026bf:	c1 fa 03             	sar    $0x3,%edx
f01026c2:	c1 e2 0c             	shl    $0xc,%edx
f01026c5:	39 d0                	cmp    %edx,%eax
f01026c7:	74 24                	je     f01026ed <mem_init+0xf5d>
f01026c9:	c7 44 24 0c 80 5b 10 	movl   $0xf0105b80,0xc(%esp)
f01026d0:	f0 
f01026d1:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f01026d8:	f0 
f01026d9:	c7 44 24 04 90 03 00 	movl   $0x390,0x4(%esp)
f01026e0:	00 
f01026e1:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f01026e8:	e8 d1 d9 ff ff       	call   f01000be <_panic>
	assert(pp1->pp_ref == 1);
f01026ed:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01026f2:	74 24                	je     f0102718 <mem_init+0xf88>
f01026f4:	c7 44 24 0c 0f 60 10 	movl   $0xf010600f,0xc(%esp)
f01026fb:	f0 
f01026fc:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0102703:	f0 
f0102704:	c7 44 24 04 91 03 00 	movl   $0x391,0x4(%esp)
f010270b:	00 
f010270c:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102713:	e8 a6 d9 ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 0);
f0102718:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010271d:	74 24                	je     f0102743 <mem_init+0xfb3>
f010271f:	c7 44 24 0c 69 60 10 	movl   $0xf0106069,0xc(%esp)
f0102726:	f0 
f0102727:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f010272e:	f0 
f010272f:	c7 44 24 04 92 03 00 	movl   $0x392,0x4(%esp)
f0102736:	00 
f0102737:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f010273e:	e8 7b d9 ff ff       	call   f01000be <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102743:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010274a:	00 
f010274b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010274e:	89 0c 24             	mov    %ecx,(%esp)
f0102751:	e8 3c ef ff ff       	call   f0101692 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102756:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f010275b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010275e:	ba 00 00 00 00       	mov    $0x0,%edx
f0102763:	e8 ba e7 ff ff       	call   f0100f22 <check_va2pa>
f0102768:	83 f8 ff             	cmp    $0xffffffff,%eax
f010276b:	74 24                	je     f0102791 <mem_init+0x1001>
f010276d:	c7 44 24 0c d4 5b 10 	movl   $0xf0105bd4,0xc(%esp)
f0102774:	f0 
f0102775:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f010277c:	f0 
f010277d:	c7 44 24 04 96 03 00 	movl   $0x396,0x4(%esp)
f0102784:	00 
f0102785:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f010278c:	e8 2d d9 ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102791:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102796:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102799:	e8 84 e7 ff ff       	call   f0100f22 <check_va2pa>
f010279e:	83 f8 ff             	cmp    $0xffffffff,%eax
f01027a1:	74 24                	je     f01027c7 <mem_init+0x1037>
f01027a3:	c7 44 24 0c f8 5b 10 	movl   $0xf0105bf8,0xc(%esp)
f01027aa:	f0 
f01027ab:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f01027b2:	f0 
f01027b3:	c7 44 24 04 97 03 00 	movl   $0x397,0x4(%esp)
f01027ba:	00 
f01027bb:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f01027c2:	e8 f7 d8 ff ff       	call   f01000be <_panic>
	assert(pp1->pp_ref == 0);
f01027c7:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01027cc:	74 24                	je     f01027f2 <mem_init+0x1062>
f01027ce:	c7 44 24 0c 7a 60 10 	movl   $0xf010607a,0xc(%esp)
f01027d5:	f0 
f01027d6:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f01027dd:	f0 
f01027de:	c7 44 24 04 98 03 00 	movl   $0x398,0x4(%esp)
f01027e5:	00 
f01027e6:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f01027ed:	e8 cc d8 ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 0);
f01027f2:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01027f7:	74 24                	je     f010281d <mem_init+0x108d>
f01027f9:	c7 44 24 0c 69 60 10 	movl   $0xf0106069,0xc(%esp)
f0102800:	f0 
f0102801:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0102808:	f0 
f0102809:	c7 44 24 04 99 03 00 	movl   $0x399,0x4(%esp)
f0102810:	00 
f0102811:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102818:	e8 a1 d8 ff ff       	call   f01000be <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f010281d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102824:	e8 d3 eb ff ff       	call   f01013fc <page_alloc>
f0102829:	85 c0                	test   %eax,%eax
f010282b:	74 04                	je     f0102831 <mem_init+0x10a1>
f010282d:	39 c7                	cmp    %eax,%edi
f010282f:	74 24                	je     f0102855 <mem_init+0x10c5>
f0102831:	c7 44 24 0c 20 5c 10 	movl   $0xf0105c20,0xc(%esp)
f0102838:	f0 
f0102839:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0102840:	f0 
f0102841:	c7 44 24 04 9c 03 00 	movl   $0x39c,0x4(%esp)
f0102848:	00 
f0102849:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102850:	e8 69 d8 ff ff       	call   f01000be <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102855:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010285c:	e8 9b eb ff ff       	call   f01013fc <page_alloc>
f0102861:	85 c0                	test   %eax,%eax
f0102863:	74 24                	je     f0102889 <mem_init+0x10f9>
f0102865:	c7 44 24 0c bd 5f 10 	movl   $0xf0105fbd,0xc(%esp)
f010286c:	f0 
f010286d:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0102874:	f0 
f0102875:	c7 44 24 04 9f 03 00 	movl   $0x39f,0x4(%esp)
f010287c:	00 
f010287d:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102884:	e8 35 d8 ff ff       	call   f01000be <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102889:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f010288e:	8b 08                	mov    (%eax),%ecx
f0102890:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102896:	89 da                	mov    %ebx,%edx
f0102898:	2b 15 cc fe 17 f0    	sub    0xf017fecc,%edx
f010289e:	c1 fa 03             	sar    $0x3,%edx
f01028a1:	c1 e2 0c             	shl    $0xc,%edx
f01028a4:	39 d1                	cmp    %edx,%ecx
f01028a6:	74 24                	je     f01028cc <mem_init+0x113c>
f01028a8:	c7 44 24 0c 30 59 10 	movl   $0xf0105930,0xc(%esp)
f01028af:	f0 
f01028b0:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f01028b7:	f0 
f01028b8:	c7 44 24 04 a2 03 00 	movl   $0x3a2,0x4(%esp)
f01028bf:	00 
f01028c0:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f01028c7:	e8 f2 d7 ff ff       	call   f01000be <_panic>
	kern_pgdir[0] = 0;
f01028cc:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f01028d2:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01028d7:	74 24                	je     f01028fd <mem_init+0x116d>
f01028d9:	c7 44 24 0c 20 60 10 	movl   $0xf0106020,0xc(%esp)
f01028e0:	f0 
f01028e1:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f01028e8:	f0 
f01028e9:	c7 44 24 04 a4 03 00 	movl   $0x3a4,0x4(%esp)
f01028f0:	00 
f01028f1:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f01028f8:	e8 c1 d7 ff ff       	call   f01000be <_panic>
	pp0->pp_ref = 0;
f01028fd:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102903:	89 1c 24             	mov    %ebx,(%esp)
f0102906:	e8 7e eb ff ff       	call   f0101489 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f010290b:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102912:	00 
f0102913:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f010291a:	00 
f010291b:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f0102920:	89 04 24             	mov    %eax,(%esp)
f0102923:	e8 99 eb ff ff       	call   f01014c1 <pgdir_walk>
f0102928:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f010292b:	8b 0d c8 fe 17 f0    	mov    0xf017fec8,%ecx
f0102931:	8b 51 04             	mov    0x4(%ecx),%edx
f0102934:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010293a:	89 55 d4             	mov    %edx,-0x2c(%ebp)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010293d:	8b 15 c4 fe 17 f0    	mov    0xf017fec4,%edx
f0102943:	89 55 c8             	mov    %edx,-0x38(%ebp)
f0102946:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102949:	c1 ea 0c             	shr    $0xc,%edx
f010294c:	89 55 d0             	mov    %edx,-0x30(%ebp)
f010294f:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0102952:	39 55 d0             	cmp    %edx,-0x30(%ebp)
f0102955:	72 23                	jb     f010297a <mem_init+0x11ea>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102957:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010295a:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010295e:	c7 44 24 08 7c 53 10 	movl   $0xf010537c,0x8(%esp)
f0102965:	f0 
f0102966:	c7 44 24 04 ab 03 00 	movl   $0x3ab,0x4(%esp)
f010296d:	00 
f010296e:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102975:	e8 44 d7 ff ff       	call   f01000be <_panic>
	assert(ptep == ptep1 + PTX(va));
f010297a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010297d:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0102983:	39 d0                	cmp    %edx,%eax
f0102985:	74 24                	je     f01029ab <mem_init+0x121b>
f0102987:	c7 44 24 0c 8b 60 10 	movl   $0xf010608b,0xc(%esp)
f010298e:	f0 
f010298f:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0102996:	f0 
f0102997:	c7 44 24 04 ac 03 00 	movl   $0x3ac,0x4(%esp)
f010299e:	00 
f010299f:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f01029a6:	e8 13 d7 ff ff       	call   f01000be <_panic>
	kern_pgdir[PDX(va)] = 0;
f01029ab:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f01029b2:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01029b8:	89 d8                	mov    %ebx,%eax
f01029ba:	2b 05 cc fe 17 f0    	sub    0xf017fecc,%eax
f01029c0:	c1 f8 03             	sar    $0x3,%eax
f01029c3:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01029c6:	89 c1                	mov    %eax,%ecx
f01029c8:	c1 e9 0c             	shr    $0xc,%ecx
f01029cb:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f01029ce:	77 20                	ja     f01029f0 <mem_init+0x1260>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01029d0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01029d4:	c7 44 24 08 7c 53 10 	movl   $0xf010537c,0x8(%esp)
f01029db:	f0 
f01029dc:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01029e3:	00 
f01029e4:	c7 04 24 4d 5e 10 f0 	movl   $0xf0105e4d,(%esp)
f01029eb:	e8 ce d6 ff ff       	call   f01000be <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01029f0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01029f7:	00 
f01029f8:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f01029ff:	00 
	return (void *)(pa + KERNBASE);
f0102a00:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102a05:	89 04 24             	mov    %eax,(%esp)
f0102a08:	e8 24 1f 00 00       	call   f0104931 <memset>
	page_free(pp0);
f0102a0d:	89 1c 24             	mov    %ebx,(%esp)
f0102a10:	e8 74 ea ff ff       	call   f0101489 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102a15:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102a1c:	00 
f0102a1d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102a24:	00 
f0102a25:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f0102a2a:	89 04 24             	mov    %eax,(%esp)
f0102a2d:	e8 8f ea ff ff       	call   f01014c1 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102a32:	89 da                	mov    %ebx,%edx
f0102a34:	2b 15 cc fe 17 f0    	sub    0xf017fecc,%edx
f0102a3a:	c1 fa 03             	sar    $0x3,%edx
f0102a3d:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a40:	89 d0                	mov    %edx,%eax
f0102a42:	c1 e8 0c             	shr    $0xc,%eax
f0102a45:	3b 05 c4 fe 17 f0    	cmp    0xf017fec4,%eax
f0102a4b:	72 20                	jb     f0102a6d <mem_init+0x12dd>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a4d:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102a51:	c7 44 24 08 7c 53 10 	movl   $0xf010537c,0x8(%esp)
f0102a58:	f0 
f0102a59:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102a60:	00 
f0102a61:	c7 04 24 4d 5e 10 f0 	movl   $0xf0105e4d,(%esp)
f0102a68:	e8 51 d6 ff ff       	call   f01000be <_panic>
	return (void *)(pa + KERNBASE);
f0102a6d:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102a73:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102a76:	f6 82 00 00 00 f0 01 	testb  $0x1,-0x10000000(%edx)
f0102a7d:	75 11                	jne    f0102a90 <mem_init+0x1300>
f0102a7f:	8d 82 04 00 00 f0    	lea    -0xffffffc(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102a85:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102a8b:	f6 00 01             	testb  $0x1,(%eax)
f0102a8e:	74 24                	je     f0102ab4 <mem_init+0x1324>
f0102a90:	c7 44 24 0c a3 60 10 	movl   $0xf01060a3,0xc(%esp)
f0102a97:	f0 
f0102a98:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0102a9f:	f0 
f0102aa0:	c7 44 24 04 b6 03 00 	movl   $0x3b6,0x4(%esp)
f0102aa7:	00 
f0102aa8:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102aaf:	e8 0a d6 ff ff       	call   f01000be <_panic>
f0102ab4:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102ab7:	39 d0                	cmp    %edx,%eax
f0102ab9:	75 d0                	jne    f0102a8b <mem_init+0x12fb>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102abb:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f0102ac0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102ac6:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// give free list back
	page_free_list = fl;
f0102acc:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102acf:	89 0d 20 f2 17 f0    	mov    %ecx,0xf017f220

	// free the pages we took
	page_free(pp0);
f0102ad5:	89 1c 24             	mov    %ebx,(%esp)
f0102ad8:	e8 ac e9 ff ff       	call   f0101489 <page_free>
	page_free(pp1);
f0102add:	89 3c 24             	mov    %edi,(%esp)
f0102ae0:	e8 a4 e9 ff ff       	call   f0101489 <page_free>
	page_free(pp2);
f0102ae5:	89 34 24             	mov    %esi,(%esp)
f0102ae8:	e8 9c e9 ff ff       	call   f0101489 <page_free>

	cprintf("check_page() succeeded!\n");
f0102aed:	c7 04 24 ba 60 10 f0 	movl   $0xf01060ba,(%esp)
f0102af4:	e8 4d 0d 00 00       	call   f0103846 <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:

	boot_map_region(kern_pgdir,UPAGES,npages * sizeof (struct Page),PADDR (pages), PTE_U| PTE_P);
f0102af9:	a1 cc fe 17 f0       	mov    0xf017fecc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102afe:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102b03:	77 20                	ja     f0102b25 <mem_init+0x1395>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102b05:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102b09:	c7 44 24 08 d8 57 10 	movl   $0xf01057d8,0x8(%esp)
f0102b10:	f0 
f0102b11:	c7 44 24 04 b2 00 00 	movl   $0xb2,0x4(%esp)
f0102b18:	00 
f0102b19:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102b20:	e8 99 d5 ff ff       	call   f01000be <_panic>
f0102b25:	8b 0d c4 fe 17 f0    	mov    0xf017fec4,%ecx
f0102b2b:	c1 e1 03             	shl    $0x3,%ecx
f0102b2e:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102b35:	00 
	return (physaddr_t)kva - KERNBASE;
f0102b36:	05 00 00 00 10       	add    $0x10000000,%eax
f0102b3b:	89 04 24             	mov    %eax,(%esp)
f0102b3e:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102b43:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f0102b48:	e8 58 ea ff ff       	call   f01015a5 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir,UENVS,NENV * sizeof (struct Env),PADDR (envs),PTE_U| PTE_P);
f0102b4d:	a1 28 f2 17 f0       	mov    0xf017f228,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102b52:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102b57:	77 20                	ja     f0102b79 <mem_init+0x13e9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102b59:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102b5d:	c7 44 24 08 d8 57 10 	movl   $0xf01057d8,0x8(%esp)
f0102b64:	f0 
f0102b65:	c7 44 24 04 ba 00 00 	movl   $0xba,0x4(%esp)
f0102b6c:	00 
f0102b6d:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102b74:	e8 45 d5 ff ff       	call   f01000be <_panic>
f0102b79:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102b80:	00 
	return (physaddr_t)kva - KERNBASE;
f0102b81:	05 00 00 00 10       	add    $0x10000000,%eax
f0102b86:	89 04 24             	mov    %eax,(%esp)
f0102b89:	b9 00 80 01 00       	mov    $0x18000,%ecx
f0102b8e:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102b93:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f0102b98:	e8 08 ea ff ff       	call   f01015a5 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102b9d:	b8 00 20 11 f0       	mov    $0xf0112000,%eax
f0102ba2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102ba7:	77 20                	ja     f0102bc9 <mem_init+0x1439>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ba9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102bad:	c7 44 24 08 d8 57 10 	movl   $0xf01057d8,0x8(%esp)
f0102bb4:	f0 
f0102bb5:	c7 44 24 04 c6 00 00 	movl   $0xc6,0x4(%esp)
f0102bbc:	00 
f0102bbd:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102bc4:	e8 f5 d4 ff ff       	call   f01000be <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region (kern_pgdir,KSTACKTOP - KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_W| PTE_P);
f0102bc9:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102bd0:	00 
f0102bd1:	c7 04 24 00 20 11 00 	movl   $0x112000,(%esp)
f0102bd8:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102bdd:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f0102be2:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f0102be7:	e8 b9 e9 ff ff       	call   f01015a5 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region (kern_pgdir,KERNBASE,0xffffffff-KERNBASE+1, 0,PTE_W| PTE_P);
f0102bec:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102bf3:	00 
f0102bf4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102bfb:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102c00:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102c05:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f0102c0a:	e8 96 e9 ff ff       	call   f01015a5 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102c0f:	8b 1d c8 fe 17 f0    	mov    0xf017fec8,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
f0102c15:	8b 15 c4 fe 17 f0    	mov    0xf017fec4,%edx
f0102c1b:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0102c1e:	8d 3c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%edi
	for (i = 0; i < n; i += PGSIZE)
f0102c25:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
f0102c2b:	0f 84 80 00 00 00    	je     f0102cb1 <mem_init+0x1521>
f0102c31:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102c36:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102c3c:	89 d8                	mov    %ebx,%eax
f0102c3e:	e8 df e2 ff ff       	call   f0100f22 <check_va2pa>
f0102c43:	8b 15 cc fe 17 f0    	mov    0xf017fecc,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102c49:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102c4f:	77 20                	ja     f0102c71 <mem_init+0x14e1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c51:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102c55:	c7 44 24 08 d8 57 10 	movl   $0xf01057d8,0x8(%esp)
f0102c5c:	f0 
f0102c5d:	c7 44 24 04 fd 02 00 	movl   $0x2fd,0x4(%esp)
f0102c64:	00 
f0102c65:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102c6c:	e8 4d d4 ff ff       	call   f01000be <_panic>
f0102c71:	8d 94 32 00 00 00 10 	lea    0x10000000(%edx,%esi,1),%edx
f0102c78:	39 d0                	cmp    %edx,%eax
f0102c7a:	74 24                	je     f0102ca0 <mem_init+0x1510>
f0102c7c:	c7 44 24 0c 44 5c 10 	movl   $0xf0105c44,0xc(%esp)
f0102c83:	f0 
f0102c84:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0102c8b:	f0 
f0102c8c:	c7 44 24 04 fd 02 00 	movl   $0x2fd,0x4(%esp)
f0102c93:	00 
f0102c94:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102c9b:	e8 1e d4 ff ff       	call   f01000be <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102ca0:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102ca6:	39 f7                	cmp    %esi,%edi
f0102ca8:	77 8c                	ja     f0102c36 <mem_init+0x14a6>
f0102caa:	be 00 00 00 00       	mov    $0x0,%esi
f0102caf:	eb 05                	jmp    f0102cb6 <mem_init+0x1526>
f0102cb1:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102cb6:	8d 96 00 00 c0 ee    	lea    -0x11400000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102cbc:	89 d8                	mov    %ebx,%eax
f0102cbe:	e8 5f e2 ff ff       	call   f0100f22 <check_va2pa>
f0102cc3:	8b 15 28 f2 17 f0    	mov    0xf017f228,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102cc9:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102ccf:	77 20                	ja     f0102cf1 <mem_init+0x1561>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102cd1:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102cd5:	c7 44 24 08 d8 57 10 	movl   $0xf01057d8,0x8(%esp)
f0102cdc:	f0 
f0102cdd:	c7 44 24 04 02 03 00 	movl   $0x302,0x4(%esp)
f0102ce4:	00 
f0102ce5:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102cec:	e8 cd d3 ff ff       	call   f01000be <_panic>
f0102cf1:	8d 94 32 00 00 00 10 	lea    0x10000000(%edx,%esi,1),%edx
f0102cf8:	39 d0                	cmp    %edx,%eax
f0102cfa:	74 24                	je     f0102d20 <mem_init+0x1590>
f0102cfc:	c7 44 24 0c 78 5c 10 	movl   $0xf0105c78,0xc(%esp)
f0102d03:	f0 
f0102d04:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0102d0b:	f0 
f0102d0c:	c7 44 24 04 02 03 00 	movl   $0x302,0x4(%esp)
f0102d13:	00 
f0102d14:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102d1b:	e8 9e d3 ff ff       	call   f01000be <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102d20:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102d26:	81 fe 00 80 01 00    	cmp    $0x18000,%esi
f0102d2c:	75 88                	jne    f0102cb6 <mem_init+0x1526>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102d2e:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102d31:	c1 e7 0c             	shl    $0xc,%edi
f0102d34:	85 ff                	test   %edi,%edi
f0102d36:	74 44                	je     f0102d7c <mem_init+0x15ec>
f0102d38:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102d3d:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102d43:	89 d8                	mov    %ebx,%eax
f0102d45:	e8 d8 e1 ff ff       	call   f0100f22 <check_va2pa>
f0102d4a:	39 c6                	cmp    %eax,%esi
f0102d4c:	74 24                	je     f0102d72 <mem_init+0x15e2>
f0102d4e:	c7 44 24 0c ac 5c 10 	movl   $0xf0105cac,0xc(%esp)
f0102d55:	f0 
f0102d56:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0102d5d:	f0 
f0102d5e:	c7 44 24 04 06 03 00 	movl   $0x306,0x4(%esp)
f0102d65:	00 
f0102d66:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102d6d:	e8 4c d3 ff ff       	call   f01000be <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102d72:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102d78:	39 fe                	cmp    %edi,%esi
f0102d7a:	72 c1                	jb     f0102d3d <mem_init+0x15ad>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102d7c:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f0102d81:	89 d8                	mov    %ebx,%eax
f0102d83:	e8 9a e1 ff ff       	call   f0100f22 <check_va2pa>
f0102d88:	be 00 90 bf ef       	mov    $0xefbf9000,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102d8d:	bf 00 20 11 f0       	mov    $0xf0112000,%edi
f0102d92:	81 c7 00 70 40 20    	add    $0x20407000,%edi
f0102d98:	8d 14 37             	lea    (%edi,%esi,1),%edx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102d9b:	39 c2                	cmp    %eax,%edx
f0102d9d:	74 24                	je     f0102dc3 <mem_init+0x1633>
f0102d9f:	c7 44 24 0c d4 5c 10 	movl   $0xf0105cd4,0xc(%esp)
f0102da6:	f0 
f0102da7:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0102dae:	f0 
f0102daf:	c7 44 24 04 0a 03 00 	movl   $0x30a,0x4(%esp)
f0102db6:	00 
f0102db7:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102dbe:	e8 fb d2 ff ff       	call   f01000be <_panic>
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102dc3:	81 fe 00 00 c0 ef    	cmp    $0xefc00000,%esi
f0102dc9:	0f 85 27 05 00 00    	jne    f01032f6 <mem_init+0x1b66>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102dcf:	ba 00 00 80 ef       	mov    $0xef800000,%edx
f0102dd4:	89 d8                	mov    %ebx,%eax
f0102dd6:	e8 47 e1 ff ff       	call   f0100f22 <check_va2pa>
f0102ddb:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102dde:	74 24                	je     f0102e04 <mem_init+0x1674>
f0102de0:	c7 44 24 0c 1c 5d 10 	movl   $0xf0105d1c,0xc(%esp)
f0102de7:	f0 
f0102de8:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0102def:	f0 
f0102df0:	c7 44 24 04 0b 03 00 	movl   $0x30b,0x4(%esp)
f0102df7:	00 
f0102df8:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102dff:	e8 ba d2 ff ff       	call   f01000be <_panic>
f0102e04:	b8 00 00 00 00       	mov    $0x0,%eax

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102e09:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f0102e0f:	83 fa 03             	cmp    $0x3,%edx
f0102e12:	77 2e                	ja     f0102e42 <mem_init+0x16b2>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f0102e14:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0102e18:	0f 85 aa 00 00 00    	jne    f0102ec8 <mem_init+0x1738>
f0102e1e:	c7 44 24 0c d3 60 10 	movl   $0xf01060d3,0xc(%esp)
f0102e25:	f0 
f0102e26:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0102e2d:	f0 
f0102e2e:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
f0102e35:	00 
f0102e36:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102e3d:	e8 7c d2 ff ff       	call   f01000be <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102e42:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102e47:	76 55                	jbe    f0102e9e <mem_init+0x170e>
				assert(pgdir[i] & PTE_P);
f0102e49:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0102e4c:	f6 c2 01             	test   $0x1,%dl
f0102e4f:	75 24                	jne    f0102e75 <mem_init+0x16e5>
f0102e51:	c7 44 24 0c d3 60 10 	movl   $0xf01060d3,0xc(%esp)
f0102e58:	f0 
f0102e59:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0102e60:	f0 
f0102e61:	c7 44 24 04 18 03 00 	movl   $0x318,0x4(%esp)
f0102e68:	00 
f0102e69:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102e70:	e8 49 d2 ff ff       	call   f01000be <_panic>
				assert(pgdir[i] & PTE_W);
f0102e75:	f6 c2 02             	test   $0x2,%dl
f0102e78:	75 4e                	jne    f0102ec8 <mem_init+0x1738>
f0102e7a:	c7 44 24 0c e4 60 10 	movl   $0xf01060e4,0xc(%esp)
f0102e81:	f0 
f0102e82:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0102e89:	f0 
f0102e8a:	c7 44 24 04 19 03 00 	movl   $0x319,0x4(%esp)
f0102e91:	00 
f0102e92:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102e99:	e8 20 d2 ff ff       	call   f01000be <_panic>
			} else
				assert(pgdir[i] == 0);
f0102e9e:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0102ea2:	74 24                	je     f0102ec8 <mem_init+0x1738>
f0102ea4:	c7 44 24 0c f5 60 10 	movl   $0xf01060f5,0xc(%esp)
f0102eab:	f0 
f0102eac:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0102eb3:	f0 
f0102eb4:	c7 44 24 04 1b 03 00 	movl   $0x31b,0x4(%esp)
f0102ebb:	00 
f0102ebc:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102ec3:	e8 f6 d1 ff ff       	call   f01000be <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102ec8:	83 c0 01             	add    $0x1,%eax
f0102ecb:	3d 00 04 00 00       	cmp    $0x400,%eax
f0102ed0:	0f 85 33 ff ff ff    	jne    f0102e09 <mem_init+0x1679>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102ed6:	c7 04 24 4c 5d 10 f0 	movl   $0xf0105d4c,(%esp)
f0102edd:	e8 64 09 00 00       	call   f0103846 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102ee2:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102ee7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102eec:	77 20                	ja     f0102f0e <mem_init+0x177e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102eee:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102ef2:	c7 44 24 08 d8 57 10 	movl   $0xf01057d8,0x8(%esp)
f0102ef9:	f0 
f0102efa:	c7 44 24 04 da 00 00 	movl   $0xda,0x4(%esp)
f0102f01:	00 
f0102f02:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102f09:	e8 b0 d1 ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102f0e:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102f13:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102f16:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f1b:	e8 a5 e0 ff ff       	call   f0100fc5 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102f20:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
f0102f23:	0d 23 00 05 80       	or     $0x80050023,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102f28:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102f2b:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102f2e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102f35:	e8 c2 e4 ff ff       	call   f01013fc <page_alloc>
f0102f3a:	89 c6                	mov    %eax,%esi
f0102f3c:	85 c0                	test   %eax,%eax
f0102f3e:	75 24                	jne    f0102f64 <mem_init+0x17d4>
f0102f40:	c7 44 24 0c 12 5f 10 	movl   $0xf0105f12,0xc(%esp)
f0102f47:	f0 
f0102f48:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0102f4f:	f0 
f0102f50:	c7 44 24 04 d1 03 00 	movl   $0x3d1,0x4(%esp)
f0102f57:	00 
f0102f58:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102f5f:	e8 5a d1 ff ff       	call   f01000be <_panic>
	assert((pp1 = page_alloc(0)));
f0102f64:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102f6b:	e8 8c e4 ff ff       	call   f01013fc <page_alloc>
f0102f70:	89 c7                	mov    %eax,%edi
f0102f72:	85 c0                	test   %eax,%eax
f0102f74:	75 24                	jne    f0102f9a <mem_init+0x180a>
f0102f76:	c7 44 24 0c 28 5f 10 	movl   $0xf0105f28,0xc(%esp)
f0102f7d:	f0 
f0102f7e:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0102f85:	f0 
f0102f86:	c7 44 24 04 d2 03 00 	movl   $0x3d2,0x4(%esp)
f0102f8d:	00 
f0102f8e:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102f95:	e8 24 d1 ff ff       	call   f01000be <_panic>
	assert((pp2 = page_alloc(0)));
f0102f9a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102fa1:	e8 56 e4 ff ff       	call   f01013fc <page_alloc>
f0102fa6:	89 c3                	mov    %eax,%ebx
f0102fa8:	85 c0                	test   %eax,%eax
f0102faa:	75 24                	jne    f0102fd0 <mem_init+0x1840>
f0102fac:	c7 44 24 0c 3e 5f 10 	movl   $0xf0105f3e,0xc(%esp)
f0102fb3:	f0 
f0102fb4:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0102fbb:	f0 
f0102fbc:	c7 44 24 04 d3 03 00 	movl   $0x3d3,0x4(%esp)
f0102fc3:	00 
f0102fc4:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0102fcb:	e8 ee d0 ff ff       	call   f01000be <_panic>
	page_free(pp0);
f0102fd0:	89 34 24             	mov    %esi,(%esp)
f0102fd3:	e8 b1 e4 ff ff       	call   f0101489 <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102fd8:	89 f8                	mov    %edi,%eax
f0102fda:	2b 05 cc fe 17 f0    	sub    0xf017fecc,%eax
f0102fe0:	c1 f8 03             	sar    $0x3,%eax
f0102fe3:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102fe6:	89 c2                	mov    %eax,%edx
f0102fe8:	c1 ea 0c             	shr    $0xc,%edx
f0102feb:	3b 15 c4 fe 17 f0    	cmp    0xf017fec4,%edx
f0102ff1:	72 20                	jb     f0103013 <mem_init+0x1883>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102ff3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102ff7:	c7 44 24 08 7c 53 10 	movl   $0xf010537c,0x8(%esp)
f0102ffe:	f0 
f0102fff:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0103006:	00 
f0103007:	c7 04 24 4d 5e 10 f0 	movl   $0xf0105e4d,(%esp)
f010300e:	e8 ab d0 ff ff       	call   f01000be <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0103013:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010301a:	00 
f010301b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0103022:	00 
	return (void *)(pa + KERNBASE);
f0103023:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0103028:	89 04 24             	mov    %eax,(%esp)
f010302b:	e8 01 19 00 00       	call   f0104931 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0103030:	89 d8                	mov    %ebx,%eax
f0103032:	2b 05 cc fe 17 f0    	sub    0xf017fecc,%eax
f0103038:	c1 f8 03             	sar    $0x3,%eax
f010303b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010303e:	89 c2                	mov    %eax,%edx
f0103040:	c1 ea 0c             	shr    $0xc,%edx
f0103043:	3b 15 c4 fe 17 f0    	cmp    0xf017fec4,%edx
f0103049:	72 20                	jb     f010306b <mem_init+0x18db>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010304b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010304f:	c7 44 24 08 7c 53 10 	movl   $0xf010537c,0x8(%esp)
f0103056:	f0 
f0103057:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f010305e:	00 
f010305f:	c7 04 24 4d 5e 10 f0 	movl   $0xf0105e4d,(%esp)
f0103066:	e8 53 d0 ff ff       	call   f01000be <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f010306b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0103072:	00 
f0103073:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f010307a:	00 
	return (void *)(pa + KERNBASE);
f010307b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0103080:	89 04 24             	mov    %eax,(%esp)
f0103083:	e8 a9 18 00 00       	call   f0104931 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0103088:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010308f:	00 
f0103090:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0103097:	00 
f0103098:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010309c:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f01030a1:	89 04 24             	mov    %eax,(%esp)
f01030a4:	e8 3d e6 ff ff       	call   f01016e6 <page_insert>
	assert(pp1->pp_ref == 1);
f01030a9:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01030ae:	74 24                	je     f01030d4 <mem_init+0x1944>
f01030b0:	c7 44 24 0c 0f 60 10 	movl   $0xf010600f,0xc(%esp)
f01030b7:	f0 
f01030b8:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f01030bf:	f0 
f01030c0:	c7 44 24 04 d8 03 00 	movl   $0x3d8,0x4(%esp)
f01030c7:	00 
f01030c8:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f01030cf:	e8 ea cf ff ff       	call   f01000be <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01030d4:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01030db:	01 01 01 
f01030de:	74 24                	je     f0103104 <mem_init+0x1974>
f01030e0:	c7 44 24 0c 6c 5d 10 	movl   $0xf0105d6c,0xc(%esp)
f01030e7:	f0 
f01030e8:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f01030ef:	f0 
f01030f0:	c7 44 24 04 d9 03 00 	movl   $0x3d9,0x4(%esp)
f01030f7:	00 
f01030f8:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f01030ff:	e8 ba cf ff ff       	call   f01000be <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0103104:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010310b:	00 
f010310c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0103113:	00 
f0103114:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103118:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f010311d:	89 04 24             	mov    %eax,(%esp)
f0103120:	e8 c1 e5 ff ff       	call   f01016e6 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0103125:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f010312c:	02 02 02 
f010312f:	74 24                	je     f0103155 <mem_init+0x19c5>
f0103131:	c7 44 24 0c 90 5d 10 	movl   $0xf0105d90,0xc(%esp)
f0103138:	f0 
f0103139:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0103140:	f0 
f0103141:	c7 44 24 04 db 03 00 	movl   $0x3db,0x4(%esp)
f0103148:	00 
f0103149:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f0103150:	e8 69 cf ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 1);
f0103155:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010315a:	74 24                	je     f0103180 <mem_init+0x19f0>
f010315c:	c7 44 24 0c 31 60 10 	movl   $0xf0106031,0xc(%esp)
f0103163:	f0 
f0103164:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f010316b:	f0 
f010316c:	c7 44 24 04 dc 03 00 	movl   $0x3dc,0x4(%esp)
f0103173:	00 
f0103174:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f010317b:	e8 3e cf ff ff       	call   f01000be <_panic>
	assert(pp1->pp_ref == 0);
f0103180:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0103185:	74 24                	je     f01031ab <mem_init+0x1a1b>
f0103187:	c7 44 24 0c 7a 60 10 	movl   $0xf010607a,0xc(%esp)
f010318e:	f0 
f010318f:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0103196:	f0 
f0103197:	c7 44 24 04 dd 03 00 	movl   $0x3dd,0x4(%esp)
f010319e:	00 
f010319f:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f01031a6:	e8 13 cf ff ff       	call   f01000be <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01031ab:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01031b2:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01031b5:	89 d8                	mov    %ebx,%eax
f01031b7:	2b 05 cc fe 17 f0    	sub    0xf017fecc,%eax
f01031bd:	c1 f8 03             	sar    $0x3,%eax
f01031c0:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01031c3:	89 c2                	mov    %eax,%edx
f01031c5:	c1 ea 0c             	shr    $0xc,%edx
f01031c8:	3b 15 c4 fe 17 f0    	cmp    0xf017fec4,%edx
f01031ce:	72 20                	jb     f01031f0 <mem_init+0x1a60>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01031d0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01031d4:	c7 44 24 08 7c 53 10 	movl   $0xf010537c,0x8(%esp)
f01031db:	f0 
f01031dc:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01031e3:	00 
f01031e4:	c7 04 24 4d 5e 10 f0 	movl   $0xf0105e4d,(%esp)
f01031eb:	e8 ce ce ff ff       	call   f01000be <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01031f0:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01031f7:	03 03 03 
f01031fa:	74 24                	je     f0103220 <mem_init+0x1a90>
f01031fc:	c7 44 24 0c b4 5d 10 	movl   $0xf0105db4,0xc(%esp)
f0103203:	f0 
f0103204:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f010320b:	f0 
f010320c:	c7 44 24 04 df 03 00 	movl   $0x3df,0x4(%esp)
f0103213:	00 
f0103214:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f010321b:	e8 9e ce ff ff       	call   f01000be <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0103220:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0103227:	00 
f0103228:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f010322d:	89 04 24             	mov    %eax,(%esp)
f0103230:	e8 5d e4 ff ff       	call   f0101692 <page_remove>
	assert(pp2->pp_ref == 0);
f0103235:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010323a:	74 24                	je     f0103260 <mem_init+0x1ad0>
f010323c:	c7 44 24 0c 69 60 10 	movl   $0xf0106069,0xc(%esp)
f0103243:	f0 
f0103244:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f010324b:	f0 
f010324c:	c7 44 24 04 e1 03 00 	movl   $0x3e1,0x4(%esp)
f0103253:	00 
f0103254:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f010325b:	e8 5e ce ff ff       	call   f01000be <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0103260:	a1 c8 fe 17 f0       	mov    0xf017fec8,%eax
f0103265:	8b 08                	mov    (%eax),%ecx
f0103267:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f010326d:	89 f2                	mov    %esi,%edx
f010326f:	2b 15 cc fe 17 f0    	sub    0xf017fecc,%edx
f0103275:	c1 fa 03             	sar    $0x3,%edx
f0103278:	c1 e2 0c             	shl    $0xc,%edx
f010327b:	39 d1                	cmp    %edx,%ecx
f010327d:	74 24                	je     f01032a3 <mem_init+0x1b13>
f010327f:	c7 44 24 0c 30 59 10 	movl   $0xf0105930,0xc(%esp)
f0103286:	f0 
f0103287:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f010328e:	f0 
f010328f:	c7 44 24 04 e4 03 00 	movl   $0x3e4,0x4(%esp)
f0103296:	00 
f0103297:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f010329e:	e8 1b ce ff ff       	call   f01000be <_panic>
	kern_pgdir[0] = 0;
f01032a3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f01032a9:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01032ae:	74 24                	je     f01032d4 <mem_init+0x1b44>
f01032b0:	c7 44 24 0c 20 60 10 	movl   $0xf0106020,0xc(%esp)
f01032b7:	f0 
f01032b8:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f01032bf:	f0 
f01032c0:	c7 44 24 04 e6 03 00 	movl   $0x3e6,0x4(%esp)
f01032c7:	00 
f01032c8:	c7 04 24 41 5e 10 f0 	movl   $0xf0105e41,(%esp)
f01032cf:	e8 ea cd ff ff       	call   f01000be <_panic>
	pp0->pp_ref = 0;
f01032d4:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f01032da:	89 34 24             	mov    %esi,(%esp)
f01032dd:	e8 a7 e1 ff ff       	call   f0101489 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01032e2:	c7 04 24 e0 5d 10 f0 	movl   $0xf0105de0,(%esp)
f01032e9:	e8 58 05 00 00       	call   f0103846 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f01032ee:	83 c4 3c             	add    $0x3c,%esp
f01032f1:	5b                   	pop    %ebx
f01032f2:	5e                   	pop    %esi
f01032f3:	5f                   	pop    %edi
f01032f4:	5d                   	pop    %ebp
f01032f5:	c3                   	ret    
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01032f6:	89 f2                	mov    %esi,%edx
f01032f8:	89 d8                	mov    %ebx,%eax
f01032fa:	e8 23 dc ff ff       	call   f0100f22 <check_va2pa>
f01032ff:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0103305:	e9 8e fa ff ff       	jmp    f0102d98 <mem_init+0x1608>

f010330a <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f010330a:	55                   	push   %ebp
f010330b:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.

	return 0;
}
f010330d:	b8 00 00 00 00       	mov    $0x0,%eax
f0103312:	5d                   	pop    %ebp
f0103313:	c3                   	ret    

f0103314 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0103314:	55                   	push   %ebp
f0103315:	89 e5                	mov    %esp,%ebp
f0103317:	53                   	push   %ebx
f0103318:	83 ec 14             	sub    $0x14,%esp
f010331b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f010331e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103321:	83 c8 04             	or     $0x4,%eax
f0103324:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103328:	8b 45 10             	mov    0x10(%ebp),%eax
f010332b:	89 44 24 08          	mov    %eax,0x8(%esp)
f010332f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103332:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103336:	89 1c 24             	mov    %ebx,(%esp)
f0103339:	e8 cc ff ff ff       	call   f010330a <user_mem_check>
f010333e:	85 c0                	test   %eax,%eax
f0103340:	79 23                	jns    f0103365 <user_mem_assert+0x51>
		cprintf("[%08x] user_mem_check assertion failure for "
f0103342:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0103349:	00 
f010334a:	8b 43 48             	mov    0x48(%ebx),%eax
f010334d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103351:	c7 04 24 0c 5e 10 f0 	movl   $0xf0105e0c,(%esp)
f0103358:	e8 e9 04 00 00       	call   f0103846 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f010335d:	89 1c 24             	mov    %ebx,(%esp)
f0103360:	e8 f7 03 00 00       	call   f010375c <env_destroy>
	}
}
f0103365:	83 c4 14             	add    $0x14,%esp
f0103368:	5b                   	pop    %ebx
f0103369:	5d                   	pop    %ebp
f010336a:	c3                   	ret    
	...

f010336c <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f010336c:	55                   	push   %ebp
f010336d:	89 e5                	mov    %esp,%ebp
f010336f:	53                   	push   %ebx
f0103370:	8b 45 08             	mov    0x8(%ebp),%eax
f0103373:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0103376:	85 c0                	test   %eax,%eax
f0103378:	75 0e                	jne    f0103388 <envid2env+0x1c>
		*env_store = curenv;
f010337a:	a1 24 f2 17 f0       	mov    0xf017f224,%eax
f010337f:	89 01                	mov    %eax,(%ecx)
		return 0;
f0103381:	b8 00 00 00 00       	mov    $0x0,%eax
f0103386:	eb 57                	jmp    f01033df <envid2env+0x73>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0103388:	89 c2                	mov    %eax,%edx
f010338a:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0103390:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103393:	c1 e2 05             	shl    $0x5,%edx
f0103396:	03 15 28 f2 17 f0    	add    0xf017f228,%edx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f010339c:	83 7a 54 00          	cmpl   $0x0,0x54(%edx)
f01033a0:	74 05                	je     f01033a7 <envid2env+0x3b>
f01033a2:	39 42 48             	cmp    %eax,0x48(%edx)
f01033a5:	74 0d                	je     f01033b4 <envid2env+0x48>
		*env_store = 0;
f01033a7:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		return -E_BAD_ENV;
f01033ad:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01033b2:	eb 2b                	jmp    f01033df <envid2env+0x73>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f01033b4:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01033b8:	74 1e                	je     f01033d8 <envid2env+0x6c>
f01033ba:	a1 24 f2 17 f0       	mov    0xf017f224,%eax
f01033bf:	39 c2                	cmp    %eax,%edx
f01033c1:	74 15                	je     f01033d8 <envid2env+0x6c>
f01033c3:	8b 58 48             	mov    0x48(%eax),%ebx
f01033c6:	39 5a 4c             	cmp    %ebx,0x4c(%edx)
f01033c9:	74 0d                	je     f01033d8 <envid2env+0x6c>
		*env_store = 0;
f01033cb:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		return -E_BAD_ENV;
f01033d1:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01033d6:	eb 07                	jmp    f01033df <envid2env+0x73>
	}

	*env_store = e;
f01033d8:	89 11                	mov    %edx,(%ecx)
	return 0;
f01033da:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01033df:	5b                   	pop    %ebx
f01033e0:	5d                   	pop    %ebp
f01033e1:	c3                   	ret    

f01033e2 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f01033e2:	55                   	push   %ebp
f01033e3:	89 e5                	mov    %esp,%ebp
	// Set up envs array
	// LAB 3: Your code here.
	size_t i;
	env_free_list = NULL;
f01033e5:	c7 05 2c f2 17 f0 00 	movl   $0x0,0xf017f22c
f01033ec:	00 00 00 
// Make sure the environments are in the free list in the same order
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
f01033ef:	a1 28 f2 17 f0       	mov    0xf017f228,%eax
f01033f4:	05 a0 7f 01 00       	add    $0x17fa0,%eax
f01033f9:	ba 00 00 00 00       	mov    $0x0,%edx
	// LAB 3: Your code here.
	size_t i;
	env_free_list = NULL;
	for (i=NENV-1;i>=0;i++)
	{
		envs[i].env_id = 0;
f01033fe:	89 c1                	mov    %eax,%ecx
f0103400:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_status = ENV_FREE;
f0103407:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[i].env_link = env_free_list;
f010340e:	89 50 44             	mov    %edx,0x44(%eax)
f0103411:	83 c0 60             	add    $0x60,%eax
		env_free_list = &envs[i];
f0103414:	89 ca                	mov    %ecx,%edx
f0103416:	eb e6                	jmp    f01033fe <env_init+0x1c>

f0103418 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0103418:	55                   	push   %ebp
f0103419:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f010341b:	b8 00 c3 11 f0       	mov    $0xf011c300,%eax
f0103420:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f0103423:	b8 23 00 00 00       	mov    $0x23,%eax
f0103428:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f010342a:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f010342c:	b0 10                	mov    $0x10,%al
f010342e:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f0103430:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f0103432:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f0103434:	ea 3b 34 10 f0 08 00 	ljmp   $0x8,$0xf010343b
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f010343b:	b0 00                	mov    $0x0,%al
f010343d:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0103440:	5d                   	pop    %ebp
f0103441:	c3                   	ret    

f0103442 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0103442:	55                   	push   %ebp
f0103443:	89 e5                	mov    %esp,%ebp
f0103445:	53                   	push   %ebx
f0103446:	83 ec 14             	sub    $0x14,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0103449:	8b 1d 2c f2 17 f0    	mov    0xf017f22c,%ebx
f010344f:	85 db                	test   %ebx,%ebx
f0103451:	0f 84 06 01 00 00    	je     f010355d <env_alloc+0x11b>
{
	int i;
	struct Page *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0103457:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010345e:	e8 99 df ff ff       	call   f01013fc <page_alloc>
f0103463:	85 c0                	test   %eax,%eax
f0103465:	0f 84 f9 00 00 00    	je     f0103564 <env_alloc+0x122>

	// LAB 3: Your code here.

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f010346b:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010346e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103473:	77 20                	ja     f0103495 <env_alloc+0x53>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103475:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103479:	c7 44 24 08 d8 57 10 	movl   $0xf01057d8,0x8(%esp)
f0103480:	f0 
f0103481:	c7 44 24 04 c1 00 00 	movl   $0xc1,0x4(%esp)
f0103488:	00 
f0103489:	c7 04 24 3a 61 10 f0 	movl   $0xf010613a,(%esp)
f0103490:	e8 29 cc ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103495:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010349b:	83 ca 05             	or     $0x5,%edx
f010349e:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01034a4:	8b 43 48             	mov    0x48(%ebx),%eax
f01034a7:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f01034ac:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f01034b1:	ba 00 10 00 00       	mov    $0x1000,%edx
f01034b6:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01034b9:	89 da                	mov    %ebx,%edx
f01034bb:	2b 15 28 f2 17 f0    	sub    0xf017f228,%edx
f01034c1:	c1 fa 05             	sar    $0x5,%edx
f01034c4:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01034ca:	09 d0                	or     %edx,%eax
f01034cc:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f01034cf:	8b 45 0c             	mov    0xc(%ebp),%eax
f01034d2:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f01034d5:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f01034dc:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
	e->env_runs = 0;
f01034e3:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f01034ea:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f01034f1:	00 
f01034f2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01034f9:	00 
f01034fa:	89 1c 24             	mov    %ebx,(%esp)
f01034fd:	e8 2f 14 00 00       	call   f0104931 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0103502:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0103508:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f010350e:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0103514:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f010351b:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0103521:	8b 43 44             	mov    0x44(%ebx),%eax
f0103524:	a3 2c f2 17 f0       	mov    %eax,0xf017f22c
	*newenv_store = e;
f0103529:	8b 45 08             	mov    0x8(%ebp),%eax
f010352c:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f010352e:	8b 4b 48             	mov    0x48(%ebx),%ecx
f0103531:	a1 24 f2 17 f0       	mov    0xf017f224,%eax
f0103536:	ba 00 00 00 00       	mov    $0x0,%edx
f010353b:	85 c0                	test   %eax,%eax
f010353d:	74 03                	je     f0103542 <env_alloc+0x100>
f010353f:	8b 50 48             	mov    0x48(%eax),%edx
f0103542:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103546:	89 54 24 04          	mov    %edx,0x4(%esp)
f010354a:	c7 04 24 45 61 10 f0 	movl   $0xf0106145,(%esp)
f0103551:	e8 f0 02 00 00       	call   f0103846 <cprintf>
	return 0;
f0103556:	b8 00 00 00 00       	mov    $0x0,%eax
f010355b:	eb 0c                	jmp    f0103569 <env_alloc+0x127>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f010355d:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0103562:	eb 05                	jmp    f0103569 <env_alloc+0x127>
	int i;
	struct Page *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0103564:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0103569:	83 c4 14             	add    $0x14,%esp
f010356c:	5b                   	pop    %ebx
f010356d:	5d                   	pop    %ebp
f010356e:	c3                   	ret    

f010356f <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, size_t size, enum EnvType type)
{
f010356f:	55                   	push   %ebp
f0103570:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.
}
f0103572:	5d                   	pop    %ebp
f0103573:	c3                   	ret    

f0103574 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0103574:	55                   	push   %ebp
f0103575:	89 e5                	mov    %esp,%ebp
f0103577:	57                   	push   %edi
f0103578:	56                   	push   %esi
f0103579:	53                   	push   %ebx
f010357a:	83 ec 2c             	sub    $0x2c,%esp
f010357d:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0103580:	a1 24 f2 17 f0       	mov    0xf017f224,%eax
f0103585:	39 c7                	cmp    %eax,%edi
f0103587:	75 37                	jne    f01035c0 <env_free+0x4c>
		lcr3(PADDR(kern_pgdir));
f0103589:	8b 15 c8 fe 17 f0    	mov    0xf017fec8,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010358f:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0103595:	77 20                	ja     f01035b7 <env_free+0x43>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103597:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010359b:	c7 44 24 08 d8 57 10 	movl   $0xf01057d8,0x8(%esp)
f01035a2:	f0 
f01035a3:	c7 44 24 04 70 01 00 	movl   $0x170,0x4(%esp)
f01035aa:	00 
f01035ab:	c7 04 24 3a 61 10 f0 	movl   $0xf010613a,(%esp)
f01035b2:	e8 07 cb ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f01035b7:	81 c2 00 00 00 10    	add    $0x10000000,%edx
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01035bd:	0f 22 da             	mov    %edx,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01035c0:	8b 4f 48             	mov    0x48(%edi),%ecx
f01035c3:	ba 00 00 00 00       	mov    $0x0,%edx
f01035c8:	85 c0                	test   %eax,%eax
f01035ca:	74 03                	je     f01035cf <env_free+0x5b>
f01035cc:	8b 50 48             	mov    0x48(%eax),%edx
f01035cf:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01035d3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01035d7:	c7 04 24 5a 61 10 f0 	movl   $0xf010615a,(%esp)
f01035de:	e8 63 02 00 00       	call   f0103846 <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01035e3:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f01035ea:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01035ed:	c1 e0 02             	shl    $0x2,%eax
f01035f0:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01035f3:	8b 47 5c             	mov    0x5c(%edi),%eax
f01035f6:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01035f9:	8b 34 90             	mov    (%eax,%edx,4),%esi
f01035fc:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103602:	0f 84 b8 00 00 00    	je     f01036c0 <env_free+0x14c>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103608:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010360e:	89 f0                	mov    %esi,%eax
f0103610:	c1 e8 0c             	shr    $0xc,%eax
f0103613:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103616:	3b 05 c4 fe 17 f0    	cmp    0xf017fec4,%eax
f010361c:	72 20                	jb     f010363e <env_free+0xca>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010361e:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103622:	c7 44 24 08 7c 53 10 	movl   $0xf010537c,0x8(%esp)
f0103629:	f0 
f010362a:	c7 44 24 04 7f 01 00 	movl   $0x17f,0x4(%esp)
f0103631:	00 
f0103632:	c7 04 24 3a 61 10 f0 	movl   $0xf010613a,(%esp)
f0103639:	e8 80 ca ff ff       	call   f01000be <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f010363e:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103641:	c1 e2 16             	shl    $0x16,%edx
f0103644:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103647:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f010364c:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0103653:	01 
f0103654:	74 17                	je     f010366d <env_free+0xf9>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103656:	89 d8                	mov    %ebx,%eax
f0103658:	c1 e0 0c             	shl    $0xc,%eax
f010365b:	0b 45 e4             	or     -0x1c(%ebp),%eax
f010365e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103662:	8b 47 5c             	mov    0x5c(%edi),%eax
f0103665:	89 04 24             	mov    %eax,(%esp)
f0103668:	e8 25 e0 ff ff       	call   f0101692 <page_remove>
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f010366d:	83 c3 01             	add    $0x1,%ebx
f0103670:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103676:	75 d4                	jne    f010364c <env_free+0xd8>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103678:	8b 47 5c             	mov    0x5c(%edi),%eax
f010367b:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010367e:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103685:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103688:	3b 05 c4 fe 17 f0    	cmp    0xf017fec4,%eax
f010368e:	72 1c                	jb     f01036ac <env_free+0x138>
		panic("pa2page called with invalid pa");
f0103690:	c7 44 24 08 fc 57 10 	movl   $0xf01057fc,0x8(%esp)
f0103697:	f0 
f0103698:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f010369f:	00 
f01036a0:	c7 04 24 4d 5e 10 f0 	movl   $0xf0105e4d,(%esp)
f01036a7:	e8 12 ca ff ff       	call   f01000be <_panic>
	return &pages[PGNUM(pa)];
f01036ac:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01036af:	c1 e0 03             	shl    $0x3,%eax
f01036b2:	03 05 cc fe 17 f0    	add    0xf017fecc,%eax
		page_decref(pa2page(pa));
f01036b8:	89 04 24             	mov    %eax,(%esp)
f01036bb:	e8 de dd ff ff       	call   f010149e <page_decref>
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01036c0:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f01036c4:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f01036cb:	0f 85 19 ff ff ff    	jne    f01035ea <env_free+0x76>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f01036d1:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01036d4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01036d9:	77 20                	ja     f01036fb <env_free+0x187>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01036db:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01036df:	c7 44 24 08 d8 57 10 	movl   $0xf01057d8,0x8(%esp)
f01036e6:	f0 
f01036e7:	c7 44 24 04 8d 01 00 	movl   $0x18d,0x4(%esp)
f01036ee:	00 
f01036ef:	c7 04 24 3a 61 10 f0 	movl   $0xf010613a,(%esp)
f01036f6:	e8 c3 c9 ff ff       	call   f01000be <_panic>
	e->env_pgdir = 0;
f01036fb:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
	return (physaddr_t)kva - KERNBASE;
f0103702:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103707:	c1 e8 0c             	shr    $0xc,%eax
f010370a:	3b 05 c4 fe 17 f0    	cmp    0xf017fec4,%eax
f0103710:	72 1c                	jb     f010372e <env_free+0x1ba>
		panic("pa2page called with invalid pa");
f0103712:	c7 44 24 08 fc 57 10 	movl   $0xf01057fc,0x8(%esp)
f0103719:	f0 
f010371a:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0103721:	00 
f0103722:	c7 04 24 4d 5e 10 f0 	movl   $0xf0105e4d,(%esp)
f0103729:	e8 90 c9 ff ff       	call   f01000be <_panic>
	return &pages[PGNUM(pa)];
f010372e:	c1 e0 03             	shl    $0x3,%eax
f0103731:	03 05 cc fe 17 f0    	add    0xf017fecc,%eax
	page_decref(pa2page(pa));
f0103737:	89 04 24             	mov    %eax,(%esp)
f010373a:	e8 5f dd ff ff       	call   f010149e <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f010373f:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103746:	a1 2c f2 17 f0       	mov    0xf017f22c,%eax
f010374b:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f010374e:	89 3d 2c f2 17 f0    	mov    %edi,0xf017f22c
}
f0103754:	83 c4 2c             	add    $0x2c,%esp
f0103757:	5b                   	pop    %ebx
f0103758:	5e                   	pop    %esi
f0103759:	5f                   	pop    %edi
f010375a:	5d                   	pop    %ebp
f010375b:	c3                   	ret    

f010375c <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f010375c:	55                   	push   %ebp
f010375d:	89 e5                	mov    %esp,%ebp
f010375f:	83 ec 18             	sub    $0x18,%esp
	env_free(e);
f0103762:	8b 45 08             	mov    0x8(%ebp),%eax
f0103765:	89 04 24             	mov    %eax,(%esp)
f0103768:	e8 07 fe ff ff       	call   f0103574 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f010376d:	c7 04 24 04 61 10 f0 	movl   $0xf0106104,(%esp)
f0103774:	e8 cd 00 00 00       	call   f0103846 <cprintf>
	while (1)
		monitor(NULL);
f0103779:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103780:	e8 24 d6 ff ff       	call   f0100da9 <monitor>
f0103785:	eb f2                	jmp    f0103779 <env_destroy+0x1d>

f0103787 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103787:	55                   	push   %ebp
f0103788:	89 e5                	mov    %esp,%ebp
f010378a:	83 ec 18             	sub    $0x18,%esp
	__asm __volatile("movl %0,%%esp\n"
f010378d:	8b 65 08             	mov    0x8(%ebp),%esp
f0103790:	61                   	popa   
f0103791:	07                   	pop    %es
f0103792:	1f                   	pop    %ds
f0103793:	83 c4 08             	add    $0x8,%esp
f0103796:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103797:	c7 44 24 08 70 61 10 	movl   $0xf0106170,0x8(%esp)
f010379e:	f0 
f010379f:	c7 44 24 04 b5 01 00 	movl   $0x1b5,0x4(%esp)
f01037a6:	00 
f01037a7:	c7 04 24 3a 61 10 f0 	movl   $0xf010613a,(%esp)
f01037ae:	e8 0b c9 ff ff       	call   f01000be <_panic>

f01037b3 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f01037b3:	55                   	push   %ebp
f01037b4:	89 e5                	mov    %esp,%ebp
f01037b6:	83 ec 18             	sub    $0x18,%esp
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.

	panic("env_run not yet implemented");
f01037b9:	c7 44 24 08 7c 61 10 	movl   $0xf010617c,0x8(%esp)
f01037c0:	f0 
f01037c1:	c7 44 24 04 d4 01 00 	movl   $0x1d4,0x4(%esp)
f01037c8:	00 
f01037c9:	c7 04 24 3a 61 10 f0 	movl   $0xf010613a,(%esp)
f01037d0:	e8 e9 c8 ff ff       	call   f01000be <_panic>
f01037d5:	00 00                	add    %al,(%eax)
	...

f01037d8 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01037d8:	55                   	push   %ebp
f01037d9:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01037db:	ba 70 00 00 00       	mov    $0x70,%edx
f01037e0:	8b 45 08             	mov    0x8(%ebp),%eax
f01037e3:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01037e4:	b2 71                	mov    $0x71,%dl
f01037e6:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01037e7:	0f b6 c0             	movzbl %al,%eax
}
f01037ea:	5d                   	pop    %ebp
f01037eb:	c3                   	ret    

f01037ec <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01037ec:	55                   	push   %ebp
f01037ed:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01037ef:	ba 70 00 00 00       	mov    $0x70,%edx
f01037f4:	8b 45 08             	mov    0x8(%ebp),%eax
f01037f7:	ee                   	out    %al,(%dx)
f01037f8:	b2 71                	mov    $0x71,%dl
f01037fa:	8b 45 0c             	mov    0xc(%ebp),%eax
f01037fd:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01037fe:	5d                   	pop    %ebp
f01037ff:	c3                   	ret    

f0103800 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103800:	55                   	push   %ebp
f0103801:	89 e5                	mov    %esp,%ebp
f0103803:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0103806:	8b 45 08             	mov    0x8(%ebp),%eax
f0103809:	89 04 24             	mov    %eax,(%esp)
f010380c:	e8 10 ce ff ff       	call   f0100621 <cputchar>
	*cnt++;
}
f0103811:	c9                   	leave  
f0103812:	c3                   	ret    

f0103813 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103813:	55                   	push   %ebp
f0103814:	89 e5                	mov    %esp,%ebp
f0103816:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0103819:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103820:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103823:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103827:	8b 45 08             	mov    0x8(%ebp),%eax
f010382a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010382e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103831:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103835:	c7 04 24 00 38 10 f0 	movl   $0xf0103800,(%esp)
f010383c:	e8 29 09 00 00       	call   f010416a <vprintfmt>
	return cnt;
}
f0103841:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103844:	c9                   	leave  
f0103845:	c3                   	ret    

f0103846 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103846:	55                   	push   %ebp
f0103847:	89 e5                	mov    %esp,%ebp
f0103849:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010384c:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010384f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103853:	8b 45 08             	mov    0x8(%ebp),%eax
f0103856:	89 04 24             	mov    %eax,(%esp)
f0103859:	e8 b5 ff ff ff       	call   f0103813 <vcprintf>
	va_end(ap);

	return cnt;
}
f010385e:	c9                   	leave  
f010385f:	c3                   	ret    

f0103860 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103860:	55                   	push   %ebp
f0103861:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0103863:	c7 05 44 fa 17 f0 00 	movl   $0xefc00000,0xf017fa44
f010386a:	00 c0 ef 
	ts.ts_ss0 = GD_KD;
f010386d:	66 c7 05 48 fa 17 f0 	movw   $0x10,0xf017fa48
f0103874:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0103876:	66 c7 05 48 c3 11 f0 	movw   $0x68,0xf011c348
f010387d:	68 00 
f010387f:	b8 40 fa 17 f0       	mov    $0xf017fa40,%eax
f0103884:	66 a3 4a c3 11 f0    	mov    %ax,0xf011c34a
f010388a:	89 c2                	mov    %eax,%edx
f010388c:	c1 ea 10             	shr    $0x10,%edx
f010388f:	88 15 4c c3 11 f0    	mov    %dl,0xf011c34c
f0103895:	c6 05 4e c3 11 f0 40 	movb   $0x40,0xf011c34e
f010389c:	c1 e8 18             	shr    $0x18,%eax
f010389f:	a2 4f c3 11 f0       	mov    %al,0xf011c34f
					sizeof(struct Taskstate), 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f01038a4:	c6 05 4d c3 11 f0 89 	movb   $0x89,0xf011c34d
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f01038ab:	b8 28 00 00 00       	mov    $0x28,%eax
f01038b0:	0f 00 d8             	ltr    %ax
}  

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f01038b3:	b8 50 c3 11 f0       	mov    $0xf011c350,%eax
f01038b8:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f01038bb:	5d                   	pop    %ebp
f01038bc:	c3                   	ret    

f01038bd <trap_init>:
}


void
trap_init(void)
{
f01038bd:	55                   	push   %ebp
f01038be:	89 e5                	mov    %esp,%ebp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.

	// Per-CPU setup 
	trap_init_percpu();
f01038c0:	e8 9b ff ff ff       	call   f0103860 <trap_init_percpu>
}
f01038c5:	5d                   	pop    %ebp
f01038c6:	c3                   	ret    

f01038c7 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f01038c7:	55                   	push   %ebp
f01038c8:	89 e5                	mov    %esp,%ebp
f01038ca:	53                   	push   %ebx
f01038cb:	83 ec 14             	sub    $0x14,%esp
f01038ce:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01038d1:	8b 03                	mov    (%ebx),%eax
f01038d3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01038d7:	c7 04 24 98 61 10 f0 	movl   $0xf0106198,(%esp)
f01038de:	e8 63 ff ff ff       	call   f0103846 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01038e3:	8b 43 04             	mov    0x4(%ebx),%eax
f01038e6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01038ea:	c7 04 24 a7 61 10 f0 	movl   $0xf01061a7,(%esp)
f01038f1:	e8 50 ff ff ff       	call   f0103846 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f01038f6:	8b 43 08             	mov    0x8(%ebx),%eax
f01038f9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01038fd:	c7 04 24 b6 61 10 f0 	movl   $0xf01061b6,(%esp)
f0103904:	e8 3d ff ff ff       	call   f0103846 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103909:	8b 43 0c             	mov    0xc(%ebx),%eax
f010390c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103910:	c7 04 24 c5 61 10 f0 	movl   $0xf01061c5,(%esp)
f0103917:	e8 2a ff ff ff       	call   f0103846 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f010391c:	8b 43 10             	mov    0x10(%ebx),%eax
f010391f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103923:	c7 04 24 d4 61 10 f0 	movl   $0xf01061d4,(%esp)
f010392a:	e8 17 ff ff ff       	call   f0103846 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f010392f:	8b 43 14             	mov    0x14(%ebx),%eax
f0103932:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103936:	c7 04 24 e3 61 10 f0 	movl   $0xf01061e3,(%esp)
f010393d:	e8 04 ff ff ff       	call   f0103846 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103942:	8b 43 18             	mov    0x18(%ebx),%eax
f0103945:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103949:	c7 04 24 f2 61 10 f0 	movl   $0xf01061f2,(%esp)
f0103950:	e8 f1 fe ff ff       	call   f0103846 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103955:	8b 43 1c             	mov    0x1c(%ebx),%eax
f0103958:	89 44 24 04          	mov    %eax,0x4(%esp)
f010395c:	c7 04 24 01 62 10 f0 	movl   $0xf0106201,(%esp)
f0103963:	e8 de fe ff ff       	call   f0103846 <cprintf>
}
f0103968:	83 c4 14             	add    $0x14,%esp
f010396b:	5b                   	pop    %ebx
f010396c:	5d                   	pop    %ebp
f010396d:	c3                   	ret    

f010396e <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f010396e:	55                   	push   %ebp
f010396f:	89 e5                	mov    %esp,%ebp
f0103971:	56                   	push   %esi
f0103972:	53                   	push   %ebx
f0103973:	83 ec 10             	sub    $0x10,%esp
f0103976:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0103979:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010397d:	c7 04 24 37 63 10 f0 	movl   $0xf0106337,(%esp)
f0103984:	e8 bd fe ff ff       	call   f0103846 <cprintf>
	print_regs(&tf->tf_regs);
f0103989:	89 1c 24             	mov    %ebx,(%esp)
f010398c:	e8 36 ff ff ff       	call   f01038c7 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103991:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103995:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103999:	c7 04 24 52 62 10 f0 	movl   $0xf0106252,(%esp)
f01039a0:	e8 a1 fe ff ff       	call   f0103846 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f01039a5:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f01039a9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01039ad:	c7 04 24 65 62 10 f0 	movl   $0xf0106265,(%esp)
f01039b4:	e8 8d fe ff ff       	call   f0103846 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01039b9:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f01039bc:	83 f8 13             	cmp    $0x13,%eax
f01039bf:	77 09                	ja     f01039ca <print_trapframe+0x5c>
		return excnames[trapno];
f01039c1:	8b 14 85 00 65 10 f0 	mov    -0xfef9b00(,%eax,4),%edx
f01039c8:	eb 10                	jmp    f01039da <print_trapframe+0x6c>
	if (trapno == T_SYSCALL)
		return "System call";
f01039ca:	83 f8 30             	cmp    $0x30,%eax
f01039cd:	ba 10 62 10 f0       	mov    $0xf0106210,%edx
f01039d2:	b9 1c 62 10 f0       	mov    $0xf010621c,%ecx
f01039d7:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01039da:	89 54 24 08          	mov    %edx,0x8(%esp)
f01039de:	89 44 24 04          	mov    %eax,0x4(%esp)
f01039e2:	c7 04 24 78 62 10 f0 	movl   $0xf0106278,(%esp)
f01039e9:	e8 58 fe ff ff       	call   f0103846 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f01039ee:	3b 1d a8 fa 17 f0    	cmp    0xf017faa8,%ebx
f01039f4:	75 19                	jne    f0103a0f <print_trapframe+0xa1>
f01039f6:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01039fa:	75 13                	jne    f0103a0f <print_trapframe+0xa1>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f01039fc:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f01039ff:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a03:	c7 04 24 8a 62 10 f0 	movl   $0xf010628a,(%esp)
f0103a0a:	e8 37 fe ff ff       	call   f0103846 <cprintf>
	cprintf("  err  0x%08x", tf->tf_err);
f0103a0f:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0103a12:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a16:	c7 04 24 99 62 10 f0 	movl   $0xf0106299,(%esp)
f0103a1d:	e8 24 fe ff ff       	call   f0103846 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103a22:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103a26:	75 51                	jne    f0103a79 <print_trapframe+0x10b>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103a28:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103a2b:	89 c2                	mov    %eax,%edx
f0103a2d:	83 e2 01             	and    $0x1,%edx
f0103a30:	ba 2b 62 10 f0       	mov    $0xf010622b,%edx
f0103a35:	b9 36 62 10 f0       	mov    $0xf0106236,%ecx
f0103a3a:	0f 45 ca             	cmovne %edx,%ecx
f0103a3d:	89 c2                	mov    %eax,%edx
f0103a3f:	83 e2 02             	and    $0x2,%edx
f0103a42:	ba 42 62 10 f0       	mov    $0xf0106242,%edx
f0103a47:	be 48 62 10 f0       	mov    $0xf0106248,%esi
f0103a4c:	0f 44 d6             	cmove  %esi,%edx
f0103a4f:	83 e0 04             	and    $0x4,%eax
f0103a52:	b8 4d 62 10 f0       	mov    $0xf010624d,%eax
f0103a57:	be 62 63 10 f0       	mov    $0xf0106362,%esi
f0103a5c:	0f 44 c6             	cmove  %esi,%eax
f0103a5f:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103a63:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103a67:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a6b:	c7 04 24 a7 62 10 f0 	movl   $0xf01062a7,(%esp)
f0103a72:	e8 cf fd ff ff       	call   f0103846 <cprintf>
f0103a77:	eb 0c                	jmp    f0103a85 <print_trapframe+0x117>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103a79:	c7 04 24 d1 60 10 f0 	movl   $0xf01060d1,(%esp)
f0103a80:	e8 c1 fd ff ff       	call   f0103846 <cprintf>
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103a85:	8b 43 30             	mov    0x30(%ebx),%eax
f0103a88:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a8c:	c7 04 24 b6 62 10 f0 	movl   $0xf01062b6,(%esp)
f0103a93:	e8 ae fd ff ff       	call   f0103846 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103a98:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103a9c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103aa0:	c7 04 24 c5 62 10 f0 	movl   $0xf01062c5,(%esp)
f0103aa7:	e8 9a fd ff ff       	call   f0103846 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103aac:	8b 43 38             	mov    0x38(%ebx),%eax
f0103aaf:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ab3:	c7 04 24 d8 62 10 f0 	movl   $0xf01062d8,(%esp)
f0103aba:	e8 87 fd ff ff       	call   f0103846 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103abf:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103ac3:	74 27                	je     f0103aec <print_trapframe+0x17e>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103ac5:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103ac8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103acc:	c7 04 24 e7 62 10 f0 	movl   $0xf01062e7,(%esp)
f0103ad3:	e8 6e fd ff ff       	call   f0103846 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103ad8:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103adc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ae0:	c7 04 24 f6 62 10 f0 	movl   $0xf01062f6,(%esp)
f0103ae7:	e8 5a fd ff ff       	call   f0103846 <cprintf>
	}
}
f0103aec:	83 c4 10             	add    $0x10,%esp
f0103aef:	5b                   	pop    %ebx
f0103af0:	5e                   	pop    %esi
f0103af1:	5d                   	pop    %ebp
f0103af2:	c3                   	ret    

f0103af3 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103af3:	55                   	push   %ebp
f0103af4:	89 e5                	mov    %esp,%ebp
f0103af6:	57                   	push   %edi
f0103af7:	56                   	push   %esi
f0103af8:	83 ec 10             	sub    $0x10,%esp
f0103afb:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103afe:	fc                   	cld    

static __inline uint32_t
read_eflags(void)
{
        uint32_t eflags;
        __asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0103aff:	9c                   	pushf  
f0103b00:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103b01:	f6 c4 02             	test   $0x2,%ah
f0103b04:	74 24                	je     f0103b2a <trap+0x37>
f0103b06:	c7 44 24 0c 09 63 10 	movl   $0xf0106309,0xc(%esp)
f0103b0d:	f0 
f0103b0e:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0103b15:	f0 
f0103b16:	c7 44 24 04 a7 00 00 	movl   $0xa7,0x4(%esp)
f0103b1d:	00 
f0103b1e:	c7 04 24 22 63 10 f0 	movl   $0xf0106322,(%esp)
f0103b25:	e8 94 c5 ff ff       	call   f01000be <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0103b2a:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103b2e:	c7 04 24 2e 63 10 f0 	movl   $0xf010632e,(%esp)
f0103b35:	e8 0c fd ff ff       	call   f0103846 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103b3a:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103b3e:	83 e0 03             	and    $0x3,%eax
f0103b41:	83 f8 03             	cmp    $0x3,%eax
f0103b44:	75 3c                	jne    f0103b82 <trap+0x8f>
		// Trapped from user mode.
		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		assert(curenv);
f0103b46:	a1 24 f2 17 f0       	mov    0xf017f224,%eax
f0103b4b:	85 c0                	test   %eax,%eax
f0103b4d:	75 24                	jne    f0103b73 <trap+0x80>
f0103b4f:	c7 44 24 0c 49 63 10 	movl   $0xf0106349,0xc(%esp)
f0103b56:	f0 
f0103b57:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0103b5e:	f0 
f0103b5f:	c7 44 24 04 b0 00 00 	movl   $0xb0,0x4(%esp)
f0103b66:	00 
f0103b67:	c7 04 24 22 63 10 f0 	movl   $0xf0106322,(%esp)
f0103b6e:	e8 4b c5 ff ff       	call   f01000be <_panic>
		curenv->env_tf = *tf;
f0103b73:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103b78:	89 c7                	mov    %eax,%edi
f0103b7a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103b7c:	8b 35 24 f2 17 f0    	mov    0xf017f224,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103b82:	89 35 a8 fa 17 f0    	mov    %esi,0xf017faa8
{
	// Handle processor exceptions.
	// LAB 3: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103b88:	89 34 24             	mov    %esi,(%esp)
f0103b8b:	e8 de fd ff ff       	call   f010396e <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103b90:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103b95:	75 1c                	jne    f0103bb3 <trap+0xc0>
		panic("unhandled trap in kernel");
f0103b97:	c7 44 24 08 50 63 10 	movl   $0xf0106350,0x8(%esp)
f0103b9e:	f0 
f0103b9f:	c7 44 24 04 96 00 00 	movl   $0x96,0x4(%esp)
f0103ba6:	00 
f0103ba7:	c7 04 24 22 63 10 f0 	movl   $0xf0106322,(%esp)
f0103bae:	e8 0b c5 ff ff       	call   f01000be <_panic>
	else {
		env_destroy(curenv);
f0103bb3:	a1 24 f2 17 f0       	mov    0xf017f224,%eax
f0103bb8:	89 04 24             	mov    %eax,(%esp)
f0103bbb:	e8 9c fb ff ff       	call   f010375c <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0103bc0:	a1 24 f2 17 f0       	mov    0xf017f224,%eax
f0103bc5:	85 c0                	test   %eax,%eax
f0103bc7:	74 06                	je     f0103bcf <trap+0xdc>
f0103bc9:	83 78 54 02          	cmpl   $0x2,0x54(%eax)
f0103bcd:	74 24                	je     f0103bf3 <trap+0x100>
f0103bcf:	c7 44 24 0c ac 64 10 	movl   $0xf01064ac,0xc(%esp)
f0103bd6:	f0 
f0103bd7:	c7 44 24 08 67 5e 10 	movl   $0xf0105e67,0x8(%esp)
f0103bde:	f0 
f0103bdf:	c7 44 24 04 be 00 00 	movl   $0xbe,0x4(%esp)
f0103be6:	00 
f0103be7:	c7 04 24 22 63 10 f0 	movl   $0xf0106322,(%esp)
f0103bee:	e8 cb c4 ff ff       	call   f01000be <_panic>
	env_run(curenv);
f0103bf3:	89 04 24             	mov    %eax,(%esp)
f0103bf6:	e8 b8 fb ff ff       	call   f01037b3 <env_run>

f0103bfb <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103bfb:	55                   	push   %ebp
f0103bfc:	89 e5                	mov    %esp,%ebp
f0103bfe:	53                   	push   %ebx
f0103bff:	83 ec 14             	sub    $0x14,%esp
f0103c02:	8b 5d 08             	mov    0x8(%ebp),%ebx

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103c05:	0f 20 d0             	mov    %cr2,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c08:	8b 53 30             	mov    0x30(%ebx),%edx
f0103c0b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103c0f:	89 44 24 08          	mov    %eax,0x8(%esp)
		curenv->env_id, fault_va, tf->tf_eip);
f0103c13:	a1 24 f2 17 f0       	mov    0xf017f224,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c18:	8b 40 48             	mov    0x48(%eax),%eax
f0103c1b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c1f:	c7 04 24 d8 64 10 f0 	movl   $0xf01064d8,(%esp)
f0103c26:	e8 1b fc ff ff       	call   f0103846 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103c2b:	89 1c 24             	mov    %ebx,(%esp)
f0103c2e:	e8 3b fd ff ff       	call   f010396e <print_trapframe>
	env_destroy(curenv);
f0103c33:	a1 24 f2 17 f0       	mov    0xf017f224,%eax
f0103c38:	89 04 24             	mov    %eax,(%esp)
f0103c3b:	e8 1c fb ff ff       	call   f010375c <env_destroy>
}
f0103c40:	83 c4 14             	add    $0x14,%esp
f0103c43:	5b                   	pop    %ebx
f0103c44:	5d                   	pop    %ebp
f0103c45:	c3                   	ret    
	...

f0103c48 <syscall>:
f0103c48:	55                   	push   %ebp
f0103c49:	89 e5                	mov    %esp,%ebp
f0103c4b:	83 ec 18             	sub    $0x18,%esp
f0103c4e:	c7 44 24 08 50 65 10 	movl   $0xf0106550,0x8(%esp)
f0103c55:	f0 
f0103c56:	c7 44 24 04 49 00 00 	movl   $0x49,0x4(%esp)
f0103c5d:	00 
f0103c5e:	c7 04 24 68 65 10 f0 	movl   $0xf0106568,(%esp)
f0103c65:	e8 54 c4 ff ff       	call   f01000be <_panic>
	...

f0103c6c <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0103c6c:	55                   	push   %ebp
f0103c6d:	89 e5                	mov    %esp,%ebp
f0103c6f:	57                   	push   %edi
f0103c70:	56                   	push   %esi
f0103c71:	53                   	push   %ebx
f0103c72:	83 ec 14             	sub    $0x14,%esp
f0103c75:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103c78:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0103c7b:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103c7e:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0103c81:	8b 1a                	mov    (%edx),%ebx
f0103c83:	8b 01                	mov    (%ecx),%eax
f0103c85:	89 45 ec             	mov    %eax,-0x14(%ebp)
	
	while (l <= r) {
f0103c88:	39 c3                	cmp    %eax,%ebx
f0103c8a:	0f 8f 9c 00 00 00    	jg     f0103d2c <stab_binsearch+0xc0>
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
f0103c90:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f0103c97:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103c9a:	01 d8                	add    %ebx,%eax
f0103c9c:	89 c7                	mov    %eax,%edi
f0103c9e:	c1 ef 1f             	shr    $0x1f,%edi
f0103ca1:	01 c7                	add    %eax,%edi
f0103ca3:	d1 ff                	sar    %edi
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103ca5:	39 df                	cmp    %ebx,%edi
f0103ca7:	7c 33                	jl     f0103cdc <stab_binsearch+0x70>
f0103ca9:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0103cac:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0103caf:	0f b6 44 82 04       	movzbl 0x4(%edx,%eax,4),%eax
f0103cb4:	39 f0                	cmp    %esi,%eax
f0103cb6:	0f 84 bc 00 00 00    	je     f0103d78 <stab_binsearch+0x10c>
f0103cbc:	8d 44 7f fd          	lea    -0x3(%edi,%edi,2),%eax
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0103cc0:	8d 54 82 04          	lea    0x4(%edx,%eax,4),%edx
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f0103cc4:	89 f8                	mov    %edi,%eax
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0103cc6:	83 e8 01             	sub    $0x1,%eax
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103cc9:	39 d8                	cmp    %ebx,%eax
f0103ccb:	7c 0f                	jl     f0103cdc <stab_binsearch+0x70>
f0103ccd:	0f b6 0a             	movzbl (%edx),%ecx
f0103cd0:	83 ea 0c             	sub    $0xc,%edx
f0103cd3:	39 f1                	cmp    %esi,%ecx
f0103cd5:	75 ef                	jne    f0103cc6 <stab_binsearch+0x5a>
f0103cd7:	e9 9e 00 00 00       	jmp    f0103d7a <stab_binsearch+0x10e>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0103cdc:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0103cdf:	eb 3c                	jmp    f0103d1d <stab_binsearch+0xb1>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0103ce1:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0103ce4:	89 02                	mov    %eax,(%edx)
			l = true_m + 1;
f0103ce6:	8d 5f 01             	lea    0x1(%edi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103ce9:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f0103cf0:	eb 2b                	jmp    f0103d1d <stab_binsearch+0xb1>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0103cf2:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0103cf5:	76 14                	jbe    f0103d0b <stab_binsearch+0x9f>
			*region_right = m - 1;
f0103cf7:	83 e8 01             	sub    $0x1,%eax
f0103cfa:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103cfd:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103d00:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103d02:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f0103d09:	eb 12                	jmp    f0103d1d <stab_binsearch+0xb1>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103d0b:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0103d0e:	89 02                	mov    %eax,(%edx)
			l = m;
			addr++;
f0103d10:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0103d14:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103d16:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0103d1d:	39 5d ec             	cmp    %ebx,-0x14(%ebp)
f0103d20:	0f 8d 71 ff ff ff    	jge    f0103c97 <stab_binsearch+0x2b>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0103d26:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103d2a:	75 0f                	jne    f0103d3b <stab_binsearch+0xcf>
		*region_right = *region_left - 1;
f0103d2c:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0103d2f:	8b 02                	mov    (%edx),%eax
f0103d31:	83 e8 01             	sub    $0x1,%eax
f0103d34:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103d37:	89 01                	mov    %eax,(%ecx)
f0103d39:	eb 57                	jmp    f0103d92 <stab_binsearch+0x126>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103d3b:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103d3e:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103d40:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0103d43:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103d45:	39 c1                	cmp    %eax,%ecx
f0103d47:	7d 28                	jge    f0103d71 <stab_binsearch+0x105>
		     l > *region_left && stabs[l].n_type != type;
f0103d49:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103d4c:	8b 5d f0             	mov    -0x10(%ebp),%ebx
f0103d4f:	0f b6 54 93 04       	movzbl 0x4(%ebx,%edx,4),%edx
f0103d54:	39 f2                	cmp    %esi,%edx
f0103d56:	74 19                	je     f0103d71 <stab_binsearch+0x105>
f0103d58:	8d 54 40 fd          	lea    -0x3(%eax,%eax,2),%edx
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0103d5c:	8d 54 93 04          	lea    0x4(%ebx,%edx,4),%edx
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0103d60:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103d63:	39 c1                	cmp    %eax,%ecx
f0103d65:	7d 0a                	jge    f0103d71 <stab_binsearch+0x105>
		     l > *region_left && stabs[l].n_type != type;
f0103d67:	0f b6 1a             	movzbl (%edx),%ebx
f0103d6a:	83 ea 0c             	sub    $0xc,%edx
f0103d6d:	39 f3                	cmp    %esi,%ebx
f0103d6f:	75 ef                	jne    f0103d60 <stab_binsearch+0xf4>
		     l--)
			/* do nothing */;
		*region_left = l;
f0103d71:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0103d74:	89 02                	mov    %eax,(%edx)
f0103d76:	eb 1a                	jmp    f0103d92 <stab_binsearch+0x126>
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f0103d78:	89 f8                	mov    %edi,%eax
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103d7a:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103d7d:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f0103d80:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0103d84:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0103d87:	0f 82 54 ff ff ff    	jb     f0103ce1 <stab_binsearch+0x75>
f0103d8d:	e9 60 ff ff ff       	jmp    f0103cf2 <stab_binsearch+0x86>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0103d92:	83 c4 14             	add    $0x14,%esp
f0103d95:	5b                   	pop    %ebx
f0103d96:	5e                   	pop    %esi
f0103d97:	5f                   	pop    %edi
f0103d98:	5d                   	pop    %ebp
f0103d99:	c3                   	ret    

f0103d9a <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103d9a:	55                   	push   %ebp
f0103d9b:	89 e5                	mov    %esp,%ebp
f0103d9d:	57                   	push   %edi
f0103d9e:	56                   	push   %esi
f0103d9f:	53                   	push   %ebx
f0103da0:	83 ec 5c             	sub    $0x5c,%esp
f0103da3:	8b 75 08             	mov    0x8(%ebp),%esi
f0103da6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103da9:	c7 03 b6 51 10 f0    	movl   $0xf01051b6,(%ebx)
	info->eip_line = 0;
f0103daf:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0103db6:	c7 43 08 b6 51 10 f0 	movl   $0xf01051b6,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0103dbd:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0103dc4:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0103dc7:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0103dce:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0103dd4:	77 23                	ja     f0103df9 <debuginfo_eip+0x5f>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f0103dd6:	8b 3d 00 00 20 00    	mov    0x200000,%edi
f0103ddc:	89 7d c4             	mov    %edi,-0x3c(%ebp)
		stab_end = usd->stab_end;
f0103ddf:	8b 15 04 00 20 00    	mov    0x200004,%edx
		stabstr = usd->stabstr;
f0103de5:	8b 3d 08 00 20 00    	mov    0x200008,%edi
f0103deb:	89 7d b8             	mov    %edi,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f0103dee:	8b 3d 0c 00 20 00    	mov    0x20000c,%edi
f0103df4:	89 7d c0             	mov    %edi,-0x40(%ebp)
f0103df7:	eb 1a                	jmp    f0103e13 <debuginfo_eip+0x79>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0103df9:	c7 45 c0 4b 14 11 f0 	movl   $0xf011144b,-0x40(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0103e00:	c7 45 b8 0d e9 10 f0 	movl   $0xf010e90d,-0x48(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0103e07:	ba 0c e9 10 f0       	mov    $0xf010e90c,%edx
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0103e0c:	c7 45 c4 88 67 10 f0 	movl   $0xf0106788,-0x3c(%ebp)
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103e13:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103e18:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103e1b:	39 7d b8             	cmp    %edi,-0x48(%ebp)
f0103e1e:	0f 83 d8 01 00 00    	jae    f0103ffc <debuginfo_eip+0x262>
f0103e24:	80 7f ff 00          	cmpb   $0x0,-0x1(%edi)
f0103e28:	0f 85 ce 01 00 00    	jne    f0103ffc <debuginfo_eip+0x262>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103e2e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103e35:	2b 55 c4             	sub    -0x3c(%ebp),%edx
f0103e38:	c1 fa 02             	sar    $0x2,%edx
f0103e3b:	69 c2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%eax
f0103e41:	83 e8 01             	sub    $0x1,%eax
f0103e44:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103e47:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103e4b:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0103e52:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0103e55:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103e58:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0103e5b:	e8 0c fe ff ff       	call   f0103c6c <stab_binsearch>
	if (lfile == 0)
f0103e60:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0103e63:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0103e68:	85 d2                	test   %edx,%edx
f0103e6a:	0f 84 8c 01 00 00    	je     f0103ffc <debuginfo_eip+0x262>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103e70:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0103e73:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103e76:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103e79:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103e7d:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0103e84:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0103e87:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103e8a:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0103e8d:	e8 da fd ff ff       	call   f0103c6c <stab_binsearch>

	if (lfun <= rfun) {
f0103e92:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103e95:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103e98:	39 d0                	cmp    %edx,%eax
f0103e9a:	7f 32                	jg     f0103ece <debuginfo_eip+0x134>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103e9c:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0103e9f:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0103ea2:	8d 0c 8f             	lea    (%edi,%ecx,4),%ecx
f0103ea5:	8b 39                	mov    (%ecx),%edi
f0103ea7:	89 7d b4             	mov    %edi,-0x4c(%ebp)
f0103eaa:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103ead:	2b 7d b8             	sub    -0x48(%ebp),%edi
f0103eb0:	39 7d b4             	cmp    %edi,-0x4c(%ebp)
f0103eb3:	73 09                	jae    f0103ebe <debuginfo_eip+0x124>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103eb5:	8b 7d b4             	mov    -0x4c(%ebp),%edi
f0103eb8:	03 7d b8             	add    -0x48(%ebp),%edi
f0103ebb:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103ebe:	8b 49 08             	mov    0x8(%ecx),%ecx
f0103ec1:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0103ec4:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0103ec6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103ec9:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0103ecc:	eb 0f                	jmp    f0103edd <debuginfo_eip+0x143>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103ece:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0103ed1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103ed4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103ed7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103eda:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103edd:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0103ee4:	00 
f0103ee5:	8b 43 08             	mov    0x8(%ebx),%eax
f0103ee8:	89 04 24             	mov    %eax,(%esp)
f0103eeb:	e8 1a 0a 00 00       	call   f010490a <strfind>
f0103ef0:	2b 43 08             	sub    0x8(%ebx),%eax
f0103ef3:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103ef6:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103efa:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0103f01:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103f04:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103f07:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0103f0a:	e8 5d fd ff ff       	call   f0103c6c <stab_binsearch>

	
	if (lline <= rline) {
f0103f0f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103f12:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0103f15:	7f 0e                	jg     f0103f25 <debuginfo_eip+0x18b>
	info->eip_line = stabs[lline].n_desc;
f0103f17:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103f1a:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0103f1d:	0f b7 44 86 06       	movzwl 0x6(%esi,%eax,4),%eax
f0103f22:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103f25:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103f28:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103f2b:	89 7d bc             	mov    %edi,-0x44(%ebp)
f0103f2e:	39 f8                	cmp    %edi,%eax
f0103f30:	7c 75                	jl     f0103fa7 <debuginfo_eip+0x20d>
	       && stabs[lline].n_type != N_SOL
f0103f32:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103f35:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0103f38:	8d 34 97             	lea    (%edi,%edx,4),%esi
f0103f3b:	0f b6 4e 04          	movzbl 0x4(%esi),%ecx
f0103f3f:	80 f9 84             	cmp    $0x84,%cl
f0103f42:	74 46                	je     f0103f8a <debuginfo_eip+0x1f0>
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0103f44:	8d 54 40 fd          	lea    -0x3(%eax,%eax,2),%edx
f0103f48:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0103f4b:	89 c7                	mov    %eax,%edi
f0103f4d:	89 5d b4             	mov    %ebx,-0x4c(%ebp)
f0103f50:	8b 5d bc             	mov    -0x44(%ebp),%ebx
f0103f53:	eb 1f                	jmp    f0103f74 <debuginfo_eip+0x1da>
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0103f55:	83 e8 01             	sub    $0x1,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103f58:	39 c3                	cmp    %eax,%ebx
f0103f5a:	7f 48                	jg     f0103fa4 <debuginfo_eip+0x20a>
	       && stabs[lline].n_type != N_SOL
f0103f5c:	89 d6                	mov    %edx,%esi
f0103f5e:	83 ea 0c             	sub    $0xc,%edx
f0103f61:	0f b6 4a 10          	movzbl 0x10(%edx),%ecx
f0103f65:	80 f9 84             	cmp    $0x84,%cl
f0103f68:	75 08                	jne    f0103f72 <debuginfo_eip+0x1d8>
f0103f6a:	8b 5d b4             	mov    -0x4c(%ebp),%ebx
f0103f6d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103f70:	eb 18                	jmp    f0103f8a <debuginfo_eip+0x1f0>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0103f72:	89 c7                	mov    %eax,%edi
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103f74:	80 f9 64             	cmp    $0x64,%cl
f0103f77:	75 dc                	jne    f0103f55 <debuginfo_eip+0x1bb>
f0103f79:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
f0103f7d:	74 d6                	je     f0103f55 <debuginfo_eip+0x1bb>
f0103f7f:	8b 5d b4             	mov    -0x4c(%ebp),%ebx
f0103f82:	89 7d d4             	mov    %edi,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103f85:	3b 45 bc             	cmp    -0x44(%ebp),%eax
f0103f88:	7c 1d                	jl     f0103fa7 <debuginfo_eip+0x20d>
f0103f8a:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103f8d:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0103f90:	8b 04 86             	mov    (%esi,%eax,4),%eax
f0103f93:	8b 55 c0             	mov    -0x40(%ebp),%edx
f0103f96:	2b 55 b8             	sub    -0x48(%ebp),%edx
f0103f99:	39 d0                	cmp    %edx,%eax
f0103f9b:	73 0a                	jae    f0103fa7 <debuginfo_eip+0x20d>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103f9d:	03 45 b8             	add    -0x48(%ebp),%eax
f0103fa0:	89 03                	mov    %eax,(%ebx)
f0103fa2:	eb 03                	jmp    f0103fa7 <debuginfo_eip+0x20d>
f0103fa4:	8b 5d b4             	mov    -0x4c(%ebp),%ebx
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103fa7:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0103faa:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103fad:	89 45 bc             	mov    %eax,-0x44(%ebp)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0103fb0:	b8 00 00 00 00       	mov    $0x0,%eax
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103fb5:	3b 7d bc             	cmp    -0x44(%ebp),%edi
f0103fb8:	7d 42                	jge    f0103ffc <debuginfo_eip+0x262>
		for (lline = lfun + 1;
f0103fba:	8d 57 01             	lea    0x1(%edi),%edx
f0103fbd:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103fc0:	39 55 bc             	cmp    %edx,-0x44(%ebp)
f0103fc3:	7e 37                	jle    f0103ffc <debuginfo_eip+0x262>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103fc5:	8d 0c 52             	lea    (%edx,%edx,2),%ecx
f0103fc8:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0103fcb:	80 7c 8e 04 a0       	cmpb   $0xa0,0x4(%esi,%ecx,4)
f0103fd0:	75 2a                	jne    f0103ffc <debuginfo_eip+0x262>
f0103fd2:	8d 04 7f             	lea    (%edi,%edi,2),%eax
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0103fd5:	8d 44 86 1c          	lea    0x1c(%esi,%eax,4),%eax
f0103fd9:	8b 4d bc             	mov    -0x44(%ebp),%ecx
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0103fdc:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0103fe0:	83 c2 01             	add    $0x1,%edx
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103fe3:	39 d1                	cmp    %edx,%ecx
f0103fe5:	7e 10                	jle    f0103ff7 <debuginfo_eip+0x25d>
f0103fe7:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103fea:	80 78 f4 a0          	cmpb   $0xa0,-0xc(%eax)
f0103fee:	74 ec                	je     f0103fdc <debuginfo_eip+0x242>
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0103ff0:	b8 00 00 00 00       	mov    $0x0,%eax
f0103ff5:	eb 05                	jmp    f0103ffc <debuginfo_eip+0x262>
f0103ff7:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103ffc:	83 c4 5c             	add    $0x5c,%esp
f0103fff:	5b                   	pop    %ebx
f0104000:	5e                   	pop    %esi
f0104001:	5f                   	pop    %edi
f0104002:	5d                   	pop    %ebp
f0104003:	c3                   	ret    
	...

f0104010 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104010:	55                   	push   %ebp
f0104011:	89 e5                	mov    %esp,%ebp
f0104013:	57                   	push   %edi
f0104014:	56                   	push   %esi
f0104015:	53                   	push   %ebx
f0104016:	83 ec 3c             	sub    $0x3c,%esp
f0104019:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010401c:	89 d7                	mov    %edx,%edi
f010401e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104021:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0104024:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104027:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010402a:	8b 5d 14             	mov    0x14(%ebp),%ebx
f010402d:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0104030:	b8 00 00 00 00       	mov    $0x0,%eax
f0104035:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0104038:	72 11                	jb     f010404b <printnum+0x3b>
f010403a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010403d:	39 45 10             	cmp    %eax,0x10(%ebp)
f0104040:	76 09                	jbe    f010404b <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0104042:	83 eb 01             	sub    $0x1,%ebx
f0104045:	85 db                	test   %ebx,%ebx
f0104047:	7f 51                	jg     f010409a <printnum+0x8a>
f0104049:	eb 5e                	jmp    f01040a9 <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010404b:	89 74 24 10          	mov    %esi,0x10(%esp)
f010404f:	83 eb 01             	sub    $0x1,%ebx
f0104052:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0104056:	8b 45 10             	mov    0x10(%ebp),%eax
f0104059:	89 44 24 08          	mov    %eax,0x8(%esp)
f010405d:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0104061:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0104065:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010406c:	00 
f010406d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104070:	89 04 24             	mov    %eax,(%esp)
f0104073:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104076:	89 44 24 04          	mov    %eax,0x4(%esp)
f010407a:	e8 01 0b 00 00       	call   f0104b80 <__udivdi3>
f010407f:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104083:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0104087:	89 04 24             	mov    %eax,(%esp)
f010408a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010408e:	89 fa                	mov    %edi,%edx
f0104090:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104093:	e8 78 ff ff ff       	call   f0104010 <printnum>
f0104098:	eb 0f                	jmp    f01040a9 <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010409a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010409e:	89 34 24             	mov    %esi,(%esp)
f01040a1:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01040a4:	83 eb 01             	sub    $0x1,%ebx
f01040a7:	75 f1                	jne    f010409a <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01040a9:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01040ad:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01040b1:	8b 45 10             	mov    0x10(%ebp),%eax
f01040b4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01040b8:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01040bf:	00 
f01040c0:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01040c3:	89 04 24             	mov    %eax,(%esp)
f01040c6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01040c9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01040cd:	e8 de 0b 00 00       	call   f0104cb0 <__umoddi3>
f01040d2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01040d6:	0f be 80 77 65 10 f0 	movsbl -0xfef9a89(%eax),%eax
f01040dd:	89 04 24             	mov    %eax,(%esp)
f01040e0:	ff 55 e4             	call   *-0x1c(%ebp)
}
f01040e3:	83 c4 3c             	add    $0x3c,%esp
f01040e6:	5b                   	pop    %ebx
f01040e7:	5e                   	pop    %esi
f01040e8:	5f                   	pop    %edi
f01040e9:	5d                   	pop    %ebp
f01040ea:	c3                   	ret    

f01040eb <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01040eb:	55                   	push   %ebp
f01040ec:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01040ee:	83 fa 01             	cmp    $0x1,%edx
f01040f1:	7e 0e                	jle    f0104101 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01040f3:	8b 10                	mov    (%eax),%edx
f01040f5:	8d 4a 08             	lea    0x8(%edx),%ecx
f01040f8:	89 08                	mov    %ecx,(%eax)
f01040fa:	8b 02                	mov    (%edx),%eax
f01040fc:	8b 52 04             	mov    0x4(%edx),%edx
f01040ff:	eb 22                	jmp    f0104123 <getuint+0x38>
	else if (lflag)
f0104101:	85 d2                	test   %edx,%edx
f0104103:	74 10                	je     f0104115 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0104105:	8b 10                	mov    (%eax),%edx
f0104107:	8d 4a 04             	lea    0x4(%edx),%ecx
f010410a:	89 08                	mov    %ecx,(%eax)
f010410c:	8b 02                	mov    (%edx),%eax
f010410e:	ba 00 00 00 00       	mov    $0x0,%edx
f0104113:	eb 0e                	jmp    f0104123 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0104115:	8b 10                	mov    (%eax),%edx
f0104117:	8d 4a 04             	lea    0x4(%edx),%ecx
f010411a:	89 08                	mov    %ecx,(%eax)
f010411c:	8b 02                	mov    (%edx),%eax
f010411e:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0104123:	5d                   	pop    %ebp
f0104124:	c3                   	ret    

f0104125 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104125:	55                   	push   %ebp
f0104126:	89 e5                	mov    %esp,%ebp
f0104128:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010412b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f010412f:	8b 10                	mov    (%eax),%edx
f0104131:	3b 50 04             	cmp    0x4(%eax),%edx
f0104134:	73 0a                	jae    f0104140 <sprintputch+0x1b>
		*b->buf++ = ch;
f0104136:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104139:	88 0a                	mov    %cl,(%edx)
f010413b:	83 c2 01             	add    $0x1,%edx
f010413e:	89 10                	mov    %edx,(%eax)
}
f0104140:	5d                   	pop    %ebp
f0104141:	c3                   	ret    

f0104142 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0104142:	55                   	push   %ebp
f0104143:	89 e5                	mov    %esp,%ebp
f0104145:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0104148:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010414b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010414f:	8b 45 10             	mov    0x10(%ebp),%eax
f0104152:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104156:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104159:	89 44 24 04          	mov    %eax,0x4(%esp)
f010415d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104160:	89 04 24             	mov    %eax,(%esp)
f0104163:	e8 02 00 00 00       	call   f010416a <vprintfmt>
	va_end(ap);
}
f0104168:	c9                   	leave  
f0104169:	c3                   	ret    

f010416a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010416a:	55                   	push   %ebp
f010416b:	89 e5                	mov    %esp,%ebp
f010416d:	57                   	push   %edi
f010416e:	56                   	push   %esi
f010416f:	53                   	push   %ebx
f0104170:	83 ec 3c             	sub    $0x3c,%esp
f0104173:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0104176:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0104179:	e9 bb 00 00 00       	jmp    f0104239 <vprintfmt+0xcf>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010417e:	85 c0                	test   %eax,%eax
f0104180:	0f 84 63 04 00 00    	je     f01045e9 <vprintfmt+0x47f>
				return;
			if (ch =='\033'){//if this is Escape character  and this if is char color set.
f0104186:	83 f8 1b             	cmp    $0x1b,%eax
f0104189:	0f 85 9a 00 00 00    	jne    f0104229 <vprintfmt+0xbf>
				int temp_color_no=0;
				ch = *(unsigned char *) fmt++;
f010418f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104192:	83 c3 02             	add    $0x2,%ebx
				while (ch != 'm') 
f0104195:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104198:	80 78 01 6d          	cmpb   $0x6d,0x1(%eax)
f010419c:	0f 84 81 00 00 00    	je     f0104223 <vprintfmt+0xb9>
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
				return;
			if (ch =='\033'){//if this is Escape character  and this if is char color set.
				int temp_color_no=0;
f01041a2:	ba 00 00 00 00       	mov    $0x0,%edx
				ch = *(unsigned char *) fmt++;
				while (ch != 'm') 
				{
					ch = *(unsigned char *) fmt++;
f01041a7:	0f b6 03             	movzbl (%ebx),%eax
f01041aa:	83 c3 01             	add    $0x1,%ebx
					if ( ch !=';' && ch!='m')
f01041ad:	83 f8 6d             	cmp    $0x6d,%eax
f01041b0:	0f 95 c1             	setne  %cl
f01041b3:	83 f8 3b             	cmp    $0x3b,%eax
f01041b6:	74 0d                	je     f01041c5 <vprintfmt+0x5b>
f01041b8:	84 c9                	test   %cl,%cl
f01041ba:	74 09                	je     f01041c5 <vprintfmt+0x5b>
						temp_color_no=temp_color_no*10+ch-'0';
f01041bc:	8d 14 92             	lea    (%edx,%edx,4),%edx
f01041bf:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
f01041c3:	eb 55                	jmp    f010421a <vprintfmt+0xb0>
					else if ( ch==';' || ch=='m'){
f01041c5:	83 f8 3b             	cmp    $0x3b,%eax
f01041c8:	74 05                	je     f01041cf <vprintfmt+0x65>
f01041ca:	83 f8 6d             	cmp    $0x6d,%eax
f01041cd:	75 4b                	jne    f010421a <vprintfmt+0xb0>
						if ( temp_color_no >=30 && temp_color_no<40){// Foreground colors
f01041cf:	89 d6                	mov    %edx,%esi
f01041d1:	8d 7a e2             	lea    -0x1e(%edx),%edi
f01041d4:	83 ff 09             	cmp    $0x9,%edi
f01041d7:	77 16                	ja     f01041ef <vprintfmt+0x85>
							char_color = (char_color&0xf0) + (temp_color_no-30);						
f01041d9:	8b 3d 58 c3 11 f0    	mov    0xf011c358,%edi
f01041df:	81 e7 f0 00 00 00    	and    $0xf0,%edi
f01041e5:	8d 7c 3a e2          	lea    -0x1e(%edx,%edi,1),%edi
f01041e9:	89 3d 58 c3 11 f0    	mov    %edi,0xf011c358
							}
						if ( temp_color_no >=40 && temp_color_no<50){// Background colors
f01041ef:	83 ee 28             	sub    $0x28,%esi
f01041f2:	83 fe 09             	cmp    $0x9,%esi
f01041f5:	77 1e                	ja     f0104215 <vprintfmt+0xab>
							char_color = (char_color&0x0f) + ((temp_color_no-40)<<4);
f01041f7:	8b 35 58 c3 11 f0    	mov    0xf011c358,%esi
f01041fd:	83 e6 0f             	and    $0xf,%esi
f0104200:	83 ea 28             	sub    $0x28,%edx
f0104203:	c1 e2 04             	shl    $0x4,%edx
f0104206:	01 f2                	add    %esi,%edx
f0104208:	89 15 58 c3 11 f0    	mov    %edx,0xf011c358
						}
						//cprintf("0x%o ,",char_color);
						temp_color_no=0;
f010420e:	ba 00 00 00 00       	mov    $0x0,%edx
f0104213:	eb 05                	jmp    f010421a <vprintfmt+0xb0>
f0104215:	ba 00 00 00 00       	mov    $0x0,%edx
			if (ch == '\0')
				return;
			if (ch =='\033'){//if this is Escape character  and this if is char color set.
				int temp_color_no=0;
				ch = *(unsigned char *) fmt++;
				while (ch != 'm') 
f010421a:	84 c9                	test   %cl,%cl
f010421c:	75 89                	jne    f01041a7 <vprintfmt+0x3d>
						}
						//cprintf("0x%o ,",char_color);
						temp_color_no=0;
					}
				}
				if (ch == 'm')
f010421e:	83 f8 6d             	cmp    $0x6d,%eax
f0104221:	75 06                	jne    f0104229 <vprintfmt+0xbf>
					ch = *(unsigned char *) fmt++;
f0104223:	0f b6 03             	movzbl (%ebx),%eax
f0104226:	83 c3 01             	add    $0x1,%ebx
				
			}
			putch(ch, putdat);
f0104229:	8b 55 0c             	mov    0xc(%ebp),%edx
f010422c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104230:	89 04 24             	mov    %eax,(%esp)
f0104233:	ff 55 08             	call   *0x8(%ebp)
f0104236:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104239:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010423c:	0f b6 03             	movzbl (%ebx),%eax
f010423f:	83 c3 01             	add    $0x1,%ebx
f0104242:	83 f8 25             	cmp    $0x25,%eax
f0104245:	0f 85 33 ff ff ff    	jne    f010417e <vprintfmt+0x14>
f010424b:	c6 45 e0 20          	movb   $0x20,-0x20(%ebp)
f010424f:	bf 00 00 00 00       	mov    $0x0,%edi
f0104254:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0104259:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0104260:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104265:	eb 23                	jmp    f010428a <vprintfmt+0x120>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104267:	89 c3                	mov    %eax,%ebx

		// flag to pad on the right
		case '-':
			padc = '-';
f0104269:	c6 45 e0 2d          	movb   $0x2d,-0x20(%ebp)
f010426d:	eb 1b                	jmp    f010428a <vprintfmt+0x120>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010426f:	89 c3                	mov    %eax,%ebx
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0104271:	c6 45 e0 30          	movb   $0x30,-0x20(%ebp)
f0104275:	eb 13                	jmp    f010428a <vprintfmt+0x120>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104277:	89 c3                	mov    %eax,%ebx
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0104279:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0104280:	eb 08                	jmp    f010428a <vprintfmt+0x120>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0104282:	89 75 dc             	mov    %esi,-0x24(%ebp)
f0104285:	be ff ff ff ff       	mov    $0xffffffff,%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010428a:	0f b6 13             	movzbl (%ebx),%edx
f010428d:	0f b6 c2             	movzbl %dl,%eax
f0104290:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104293:	8d 43 01             	lea    0x1(%ebx),%eax
f0104296:	83 ea 23             	sub    $0x23,%edx
f0104299:	80 fa 55             	cmp    $0x55,%dl
f010429c:	0f 87 18 03 00 00    	ja     f01045ba <vprintfmt+0x450>
f01042a2:	0f b6 d2             	movzbl %dl,%edx
f01042a5:	ff 24 95 04 66 10 f0 	jmp    *-0xfef99fc(,%edx,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01042ac:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01042af:	83 ee 30             	sub    $0x30,%esi
				ch = *fmt;
f01042b2:	0f be 53 01          	movsbl 0x1(%ebx),%edx
				if (ch < '0' || ch > '9')
f01042b6:	8d 5a d0             	lea    -0x30(%edx),%ebx
f01042b9:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01042bc:	89 c3                	mov    %eax,%ebx
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f01042be:	83 7d e4 09          	cmpl   $0x9,-0x1c(%ebp)
f01042c2:	77 3b                	ja     f01042ff <vprintfmt+0x195>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01042c4:	83 c0 01             	add    $0x1,%eax
				precision = precision * 10 + ch - '0';
f01042c7:	8d 1c b6             	lea    (%esi,%esi,4),%ebx
f01042ca:	8d 74 5a d0          	lea    -0x30(%edx,%ebx,2),%esi
				ch = *fmt;
f01042ce:	0f be 10             	movsbl (%eax),%edx
				if (ch < '0' || ch > '9')
f01042d1:	8d 5a d0             	lea    -0x30(%edx),%ebx
f01042d4:	83 fb 09             	cmp    $0x9,%ebx
f01042d7:	76 eb                	jbe    f01042c4 <vprintfmt+0x15a>
f01042d9:	eb 22                	jmp    f01042fd <vprintfmt+0x193>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01042db:	8b 55 14             	mov    0x14(%ebp),%edx
f01042de:	8d 5a 04             	lea    0x4(%edx),%ebx
f01042e1:	89 5d 14             	mov    %ebx,0x14(%ebp)
f01042e4:	8b 32                	mov    (%edx),%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01042e6:	89 c3                	mov    %eax,%ebx
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01042e8:	eb 15                	jmp    f01042ff <vprintfmt+0x195>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01042ea:	89 c3                	mov    %eax,%ebx
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f01042ec:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01042f0:	79 98                	jns    f010428a <vprintfmt+0x120>
f01042f2:	eb 83                	jmp    f0104277 <vprintfmt+0x10d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01042f4:	89 c3                	mov    %eax,%ebx
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01042f6:	bf 01 00 00 00       	mov    $0x1,%edi
			goto reswitch;
f01042fb:	eb 8d                	jmp    f010428a <vprintfmt+0x120>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01042fd:	89 c3                	mov    %eax,%ebx
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f01042ff:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0104303:	79 85                	jns    f010428a <vprintfmt+0x120>
f0104305:	e9 78 ff ff ff       	jmp    f0104282 <vprintfmt+0x118>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f010430a:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010430d:	89 c3                	mov    %eax,%ebx
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010430f:	e9 76 ff ff ff       	jmp    f010428a <vprintfmt+0x120>
f0104314:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104317:	8b 45 14             	mov    0x14(%ebp),%eax
f010431a:	8d 50 04             	lea    0x4(%eax),%edx
f010431d:	89 55 14             	mov    %edx,0x14(%ebp)
f0104320:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104323:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104327:	8b 00                	mov    (%eax),%eax
f0104329:	89 04 24             	mov    %eax,(%esp)
f010432c:	ff 55 08             	call   *0x8(%ebp)
			break;
f010432f:	e9 05 ff ff ff       	jmp    f0104239 <vprintfmt+0xcf>
f0104334:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// error message
		case 'e':
			err = va_arg(ap, int);
f0104337:	8b 45 14             	mov    0x14(%ebp),%eax
f010433a:	8d 50 04             	lea    0x4(%eax),%edx
f010433d:	89 55 14             	mov    %edx,0x14(%ebp)
f0104340:	8b 00                	mov    (%eax),%eax
f0104342:	89 c2                	mov    %eax,%edx
f0104344:	c1 fa 1f             	sar    $0x1f,%edx
f0104347:	31 d0                	xor    %edx,%eax
f0104349:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010434b:	83 f8 06             	cmp    $0x6,%eax
f010434e:	7f 0b                	jg     f010435b <vprintfmt+0x1f1>
f0104350:	8b 14 85 5c 67 10 f0 	mov    -0xfef98a4(,%eax,4),%edx
f0104357:	85 d2                	test   %edx,%edx
f0104359:	75 23                	jne    f010437e <vprintfmt+0x214>
				printfmt(putch, putdat, "error %d", err);
f010435b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010435f:	c7 44 24 08 8f 65 10 	movl   $0xf010658f,0x8(%esp)
f0104366:	f0 
f0104367:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010436a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010436e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0104371:	89 1c 24             	mov    %ebx,(%esp)
f0104374:	e8 c9 fd ff ff       	call   f0104142 <printfmt>
f0104379:	e9 bb fe ff ff       	jmp    f0104239 <vprintfmt+0xcf>
			else
				printfmt(putch, putdat, "%s", p);
f010437e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104382:	c7 44 24 08 79 5e 10 	movl   $0xf0105e79,0x8(%esp)
f0104389:	f0 
f010438a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010438d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104391:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0104394:	89 1c 24             	mov    %ebx,(%esp)
f0104397:	e8 a6 fd ff ff       	call   f0104142 <printfmt>
f010439c:	e9 98 fe ff ff       	jmp    f0104239 <vprintfmt+0xcf>
f01043a1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01043a4:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01043a7:	89 5d d8             	mov    %ebx,-0x28(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01043aa:	8b 45 14             	mov    0x14(%ebp),%eax
f01043ad:	8d 50 04             	lea    0x4(%eax),%edx
f01043b0:	89 55 14             	mov    %edx,0x14(%ebp)
f01043b3:	8b 18                	mov    (%eax),%ebx
				p = "(null)";
f01043b5:	85 db                	test   %ebx,%ebx
f01043b7:	b8 88 65 10 f0       	mov    $0xf0106588,%eax
f01043bc:	0f 44 d8             	cmove  %eax,%ebx
			if (width > 0 && padc != '-')
f01043bf:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01043c3:	7e 06                	jle    f01043cb <vprintfmt+0x261>
f01043c5:	80 7d e0 2d          	cmpb   $0x2d,-0x20(%ebp)
f01043c9:	75 10                	jne    f01043db <vprintfmt+0x271>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01043cb:	0f be 03             	movsbl (%ebx),%eax
f01043ce:	83 c3 01             	add    $0x1,%ebx
f01043d1:	85 c0                	test   %eax,%eax
f01043d3:	0f 85 82 00 00 00    	jne    f010445b <vprintfmt+0x2f1>
f01043d9:	eb 75                	jmp    f0104450 <vprintfmt+0x2e6>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01043db:	89 74 24 04          	mov    %esi,0x4(%esp)
f01043df:	89 1c 24             	mov    %ebx,(%esp)
f01043e2:	e8 84 03 00 00       	call   f010476b <strnlen>
f01043e7:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01043ea:	29 c2                	sub    %eax,%edx
f01043ec:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01043ef:	85 d2                	test   %edx,%edx
f01043f1:	7e d8                	jle    f01043cb <vprintfmt+0x261>
					putch(padc, putdat);
f01043f3:	0f be 45 e0          	movsbl -0x20(%ebp),%eax
f01043f7:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01043fa:	8b 55 0c             	mov    0xc(%ebp),%edx
f01043fd:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104401:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104404:	89 04 24             	mov    %eax,(%esp)
f0104407:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010440a:	83 6d dc 01          	subl   $0x1,-0x24(%ebp)
f010440e:	75 ea                	jne    f01043fa <vprintfmt+0x290>
f0104410:	eb b9                	jmp    f01043cb <vprintfmt+0x261>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104412:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104416:	74 1b                	je     f0104433 <vprintfmt+0x2c9>
f0104418:	8d 50 e0             	lea    -0x20(%eax),%edx
f010441b:	83 fa 5e             	cmp    $0x5e,%edx
f010441e:	76 13                	jbe    f0104433 <vprintfmt+0x2c9>
					putch('?', putdat);
f0104420:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104423:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104427:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f010442e:	ff 55 08             	call   *0x8(%ebp)
f0104431:	eb 0d                	jmp    f0104440 <vprintfmt+0x2d6>
				else
					putch(ch, putdat);
f0104433:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104436:	89 54 24 04          	mov    %edx,0x4(%esp)
f010443a:	89 04 24             	mov    %eax,(%esp)
f010443d:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104440:	83 ef 01             	sub    $0x1,%edi
f0104443:	0f be 03             	movsbl (%ebx),%eax
f0104446:	83 c3 01             	add    $0x1,%ebx
f0104449:	85 c0                	test   %eax,%eax
f010444b:	75 14                	jne    f0104461 <vprintfmt+0x2f7>
f010444d:	89 7d dc             	mov    %edi,-0x24(%ebp)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0104450:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0104454:	7f 19                	jg     f010446f <vprintfmt+0x305>
f0104456:	e9 de fd ff ff       	jmp    f0104239 <vprintfmt+0xcf>
f010445b:	89 7d e0             	mov    %edi,-0x20(%ebp)
f010445e:	8b 7d dc             	mov    -0x24(%ebp),%edi
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104461:	85 f6                	test   %esi,%esi
f0104463:	78 ad                	js     f0104412 <vprintfmt+0x2a8>
f0104465:	83 ee 01             	sub    $0x1,%esi
f0104468:	79 a8                	jns    f0104412 <vprintfmt+0x2a8>
f010446a:	89 7d dc             	mov    %edi,-0x24(%ebp)
f010446d:	eb e1                	jmp    f0104450 <vprintfmt+0x2e6>
f010446f:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0104472:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104475:	8b 75 0c             	mov    0xc(%ebp),%esi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0104478:	89 74 24 04          	mov    %esi,0x4(%esp)
f010447c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0104483:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0104485:	83 eb 01             	sub    $0x1,%ebx
f0104488:	75 ee                	jne    f0104478 <vprintfmt+0x30e>
f010448a:	e9 aa fd ff ff       	jmp    f0104239 <vprintfmt+0xcf>
f010448f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0104492:	83 f9 01             	cmp    $0x1,%ecx
f0104495:	7e 10                	jle    f01044a7 <vprintfmt+0x33d>
		return va_arg(*ap, long long);
f0104497:	8b 45 14             	mov    0x14(%ebp),%eax
f010449a:	8d 50 08             	lea    0x8(%eax),%edx
f010449d:	89 55 14             	mov    %edx,0x14(%ebp)
f01044a0:	8b 30                	mov    (%eax),%esi
f01044a2:	8b 78 04             	mov    0x4(%eax),%edi
f01044a5:	eb 26                	jmp    f01044cd <vprintfmt+0x363>
	else if (lflag)
f01044a7:	85 c9                	test   %ecx,%ecx
f01044a9:	74 12                	je     f01044bd <vprintfmt+0x353>
		return va_arg(*ap, long);
f01044ab:	8b 45 14             	mov    0x14(%ebp),%eax
f01044ae:	8d 50 04             	lea    0x4(%eax),%edx
f01044b1:	89 55 14             	mov    %edx,0x14(%ebp)
f01044b4:	8b 30                	mov    (%eax),%esi
f01044b6:	89 f7                	mov    %esi,%edi
f01044b8:	c1 ff 1f             	sar    $0x1f,%edi
f01044bb:	eb 10                	jmp    f01044cd <vprintfmt+0x363>
	else
		return va_arg(*ap, int);
f01044bd:	8b 45 14             	mov    0x14(%ebp),%eax
f01044c0:	8d 50 04             	lea    0x4(%eax),%edx
f01044c3:	89 55 14             	mov    %edx,0x14(%ebp)
f01044c6:	8b 30                	mov    (%eax),%esi
f01044c8:	89 f7                	mov    %esi,%edi
f01044ca:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01044cd:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01044d2:	85 ff                	test   %edi,%edi
f01044d4:	0f 89 9e 00 00 00    	jns    f0104578 <vprintfmt+0x40e>
				putch('-', putdat);
f01044da:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01044dd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01044e1:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01044e8:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01044eb:	f7 de                	neg    %esi
f01044ed:	83 d7 00             	adc    $0x0,%edi
f01044f0:	f7 df                	neg    %edi
			}
			base = 10;
f01044f2:	b8 0a 00 00 00       	mov    $0xa,%eax
f01044f7:	eb 7f                	jmp    f0104578 <vprintfmt+0x40e>
f01044f9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01044fc:	89 ca                	mov    %ecx,%edx
f01044fe:	8d 45 14             	lea    0x14(%ebp),%eax
f0104501:	e8 e5 fb ff ff       	call   f01040eb <getuint>
f0104506:	89 c6                	mov    %eax,%esi
f0104508:	89 d7                	mov    %edx,%edi
			base = 10;
f010450a:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f010450f:	eb 67                	jmp    f0104578 <vprintfmt+0x40e>
f0104511:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap,lflag);
f0104514:	89 ca                	mov    %ecx,%edx
f0104516:	8d 45 14             	lea    0x14(%ebp),%eax
f0104519:	e8 cd fb ff ff       	call   f01040eb <getuint>
f010451e:	89 c6                	mov    %eax,%esi
f0104520:	89 d7                	mov    %edx,%edi
			base = 8;
f0104522:	b8 08 00 00 00       	mov    $0x8,%eax

			goto number;
f0104527:	eb 4f                	jmp    f0104578 <vprintfmt+0x40e>
f0104529:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// pointer
		case 'p':
			putch('0', putdat);
f010452c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010452f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104533:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010453a:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f010453d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104541:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0104548:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010454b:	8b 45 14             	mov    0x14(%ebp),%eax
f010454e:	8d 50 04             	lea    0x4(%eax),%edx
f0104551:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0104554:	8b 30                	mov    (%eax),%esi
f0104556:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010455b:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0104560:	eb 16                	jmp    f0104578 <vprintfmt+0x40e>
f0104562:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0104565:	89 ca                	mov    %ecx,%edx
f0104567:	8d 45 14             	lea    0x14(%ebp),%eax
f010456a:	e8 7c fb ff ff       	call   f01040eb <getuint>
f010456f:	89 c6                	mov    %eax,%esi
f0104571:	89 d7                	mov    %edx,%edi
			base = 16;
f0104573:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0104578:	0f be 55 e0          	movsbl -0x20(%ebp),%edx
f010457c:	89 54 24 10          	mov    %edx,0x10(%esp)
f0104580:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0104583:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0104587:	89 44 24 08          	mov    %eax,0x8(%esp)
f010458b:	89 34 24             	mov    %esi,(%esp)
f010458e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104592:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104595:	8b 45 08             	mov    0x8(%ebp),%eax
f0104598:	e8 73 fa ff ff       	call   f0104010 <printnum>
			break;
f010459d:	e9 97 fc ff ff       	jmp    f0104239 <vprintfmt+0xcf>
f01045a2:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01045a5:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01045a8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01045ab:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01045af:	89 14 24             	mov    %edx,(%esp)
f01045b2:	ff 55 08             	call   *0x8(%ebp)
			break;
f01045b5:	e9 7f fc ff ff       	jmp    f0104239 <vprintfmt+0xcf>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01045ba:	8b 45 0c             	mov    0xc(%ebp),%eax
f01045bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01045c1:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01045c8:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01045cb:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f01045ce:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f01045d2:	0f 84 61 fc ff ff    	je     f0104239 <vprintfmt+0xcf>
f01045d8:	83 eb 01             	sub    $0x1,%ebx
f01045db:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f01045df:	75 f7                	jne    f01045d8 <vprintfmt+0x46e>
f01045e1:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f01045e4:	e9 50 fc ff ff       	jmp    f0104239 <vprintfmt+0xcf>
				/* do nothing */;
			break;
		}
	}
}
f01045e9:	83 c4 3c             	add    $0x3c,%esp
f01045ec:	5b                   	pop    %ebx
f01045ed:	5e                   	pop    %esi
f01045ee:	5f                   	pop    %edi
f01045ef:	5d                   	pop    %ebp
f01045f0:	c3                   	ret    

f01045f1 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01045f1:	55                   	push   %ebp
f01045f2:	89 e5                	mov    %esp,%ebp
f01045f4:	83 ec 28             	sub    $0x28,%esp
f01045f7:	8b 45 08             	mov    0x8(%ebp),%eax
f01045fa:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01045fd:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104600:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104604:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104607:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010460e:	85 c0                	test   %eax,%eax
f0104610:	74 30                	je     f0104642 <vsnprintf+0x51>
f0104612:	85 d2                	test   %edx,%edx
f0104614:	7e 2c                	jle    f0104642 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104616:	8b 45 14             	mov    0x14(%ebp),%eax
f0104619:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010461d:	8b 45 10             	mov    0x10(%ebp),%eax
f0104620:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104624:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104627:	89 44 24 04          	mov    %eax,0x4(%esp)
f010462b:	c7 04 24 25 41 10 f0 	movl   $0xf0104125,(%esp)
f0104632:	e8 33 fb ff ff       	call   f010416a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104637:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010463a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010463d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104640:	eb 05                	jmp    f0104647 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104642:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0104647:	c9                   	leave  
f0104648:	c3                   	ret    

f0104649 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104649:	55                   	push   %ebp
f010464a:	89 e5                	mov    %esp,%ebp
f010464c:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010464f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104652:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104656:	8b 45 10             	mov    0x10(%ebp),%eax
f0104659:	89 44 24 08          	mov    %eax,0x8(%esp)
f010465d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104660:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104664:	8b 45 08             	mov    0x8(%ebp),%eax
f0104667:	89 04 24             	mov    %eax,(%esp)
f010466a:	e8 82 ff ff ff       	call   f01045f1 <vsnprintf>
	va_end(ap);

	return rc;
}
f010466f:	c9                   	leave  
f0104670:	c3                   	ret    
	...

f0104680 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104680:	55                   	push   %ebp
f0104681:	89 e5                	mov    %esp,%ebp
f0104683:	57                   	push   %edi
f0104684:	56                   	push   %esi
f0104685:	53                   	push   %ebx
f0104686:	83 ec 1c             	sub    $0x1c,%esp
f0104689:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010468c:	85 c0                	test   %eax,%eax
f010468e:	74 10                	je     f01046a0 <readline+0x20>
		cprintf("%s", prompt);
f0104690:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104694:	c7 04 24 79 5e 10 f0 	movl   $0xf0105e79,(%esp)
f010469b:	e8 a6 f1 ff ff       	call   f0103846 <cprintf>

	i = 0;
	echoing = iscons(0);
f01046a0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01046a7:	e8 96 bf ff ff       	call   f0100642 <iscons>
f01046ac:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01046ae:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01046b3:	e8 79 bf ff ff       	call   f0100631 <getchar>
f01046b8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01046ba:	85 c0                	test   %eax,%eax
f01046bc:	79 17                	jns    f01046d5 <readline+0x55>
			cprintf("read error: %e\n", c);
f01046be:	89 44 24 04          	mov    %eax,0x4(%esp)
f01046c2:	c7 04 24 78 67 10 f0 	movl   $0xf0106778,(%esp)
f01046c9:	e8 78 f1 ff ff       	call   f0103846 <cprintf>
			return NULL;
f01046ce:	b8 00 00 00 00       	mov    $0x0,%eax
f01046d3:	eb 6d                	jmp    f0104742 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01046d5:	83 f8 08             	cmp    $0x8,%eax
f01046d8:	74 05                	je     f01046df <readline+0x5f>
f01046da:	83 f8 7f             	cmp    $0x7f,%eax
f01046dd:	75 19                	jne    f01046f8 <readline+0x78>
f01046df:	85 f6                	test   %esi,%esi
f01046e1:	7e 15                	jle    f01046f8 <readline+0x78>
			if (echoing)
f01046e3:	85 ff                	test   %edi,%edi
f01046e5:	74 0c                	je     f01046f3 <readline+0x73>
				cputchar('\b');
f01046e7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01046ee:	e8 2e bf ff ff       	call   f0100621 <cputchar>
			i--;
f01046f3:	83 ee 01             	sub    $0x1,%esi
f01046f6:	eb bb                	jmp    f01046b3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01046f8:	83 fb 1f             	cmp    $0x1f,%ebx
f01046fb:	7e 1f                	jle    f010471c <readline+0x9c>
f01046fd:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0104703:	7f 17                	jg     f010471c <readline+0x9c>
			if (echoing)
f0104705:	85 ff                	test   %edi,%edi
f0104707:	74 08                	je     f0104711 <readline+0x91>
				cputchar(c);
f0104709:	89 1c 24             	mov    %ebx,(%esp)
f010470c:	e8 10 bf ff ff       	call   f0100621 <cputchar>
			buf[i++] = c;
f0104711:	88 9e c0 fa 17 f0    	mov    %bl,-0xfe80540(%esi)
f0104717:	83 c6 01             	add    $0x1,%esi
f010471a:	eb 97                	jmp    f01046b3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010471c:	83 fb 0a             	cmp    $0xa,%ebx
f010471f:	74 05                	je     f0104726 <readline+0xa6>
f0104721:	83 fb 0d             	cmp    $0xd,%ebx
f0104724:	75 8d                	jne    f01046b3 <readline+0x33>
			if (echoing)
f0104726:	85 ff                	test   %edi,%edi
f0104728:	74 0c                	je     f0104736 <readline+0xb6>
				cputchar('\n');
f010472a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0104731:	e8 eb be ff ff       	call   f0100621 <cputchar>
			buf[i] = 0;
f0104736:	c6 86 c0 fa 17 f0 00 	movb   $0x0,-0xfe80540(%esi)
			return buf;
f010473d:	b8 c0 fa 17 f0       	mov    $0xf017fac0,%eax
		}
	}
}
f0104742:	83 c4 1c             	add    $0x1c,%esp
f0104745:	5b                   	pop    %ebx
f0104746:	5e                   	pop    %esi
f0104747:	5f                   	pop    %edi
f0104748:	5d                   	pop    %ebp
f0104749:	c3                   	ret    
f010474a:	00 00                	add    %al,(%eax)
f010474c:	00 00                	add    %al,(%eax)
	...

f0104750 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104750:	55                   	push   %ebp
f0104751:	89 e5                	mov    %esp,%ebp
f0104753:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104756:	b8 00 00 00 00       	mov    $0x0,%eax
f010475b:	80 3a 00             	cmpb   $0x0,(%edx)
f010475e:	74 09                	je     f0104769 <strlen+0x19>
		n++;
f0104760:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104763:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104767:	75 f7                	jne    f0104760 <strlen+0x10>
		n++;
	return n;
}
f0104769:	5d                   	pop    %ebp
f010476a:	c3                   	ret    

f010476b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010476b:	55                   	push   %ebp
f010476c:	89 e5                	mov    %esp,%ebp
f010476e:	53                   	push   %ebx
f010476f:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0104772:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104775:	b8 00 00 00 00       	mov    $0x0,%eax
f010477a:	85 c9                	test   %ecx,%ecx
f010477c:	74 1a                	je     f0104798 <strnlen+0x2d>
f010477e:	80 3b 00             	cmpb   $0x0,(%ebx)
f0104781:	74 15                	je     f0104798 <strnlen+0x2d>
f0104783:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f0104788:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010478a:	39 ca                	cmp    %ecx,%edx
f010478c:	74 0a                	je     f0104798 <strnlen+0x2d>
f010478e:	83 c2 01             	add    $0x1,%edx
f0104791:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0104796:	75 f0                	jne    f0104788 <strnlen+0x1d>
		n++;
	return n;
}
f0104798:	5b                   	pop    %ebx
f0104799:	5d                   	pop    %ebp
f010479a:	c3                   	ret    

f010479b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010479b:	55                   	push   %ebp
f010479c:	89 e5                	mov    %esp,%ebp
f010479e:	53                   	push   %ebx
f010479f:	8b 45 08             	mov    0x8(%ebp),%eax
f01047a2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01047a5:	ba 00 00 00 00       	mov    $0x0,%edx
f01047aa:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01047ae:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f01047b1:	83 c2 01             	add    $0x1,%edx
f01047b4:	84 c9                	test   %cl,%cl
f01047b6:	75 f2                	jne    f01047aa <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f01047b8:	5b                   	pop    %ebx
f01047b9:	5d                   	pop    %ebp
f01047ba:	c3                   	ret    

f01047bb <strcat>:

char *
strcat(char *dst, const char *src)
{
f01047bb:	55                   	push   %ebp
f01047bc:	89 e5                	mov    %esp,%ebp
f01047be:	53                   	push   %ebx
f01047bf:	83 ec 08             	sub    $0x8,%esp
f01047c2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01047c5:	89 1c 24             	mov    %ebx,(%esp)
f01047c8:	e8 83 ff ff ff       	call   f0104750 <strlen>
	strcpy(dst + len, src);
f01047cd:	8b 55 0c             	mov    0xc(%ebp),%edx
f01047d0:	89 54 24 04          	mov    %edx,0x4(%esp)
f01047d4:	01 d8                	add    %ebx,%eax
f01047d6:	89 04 24             	mov    %eax,(%esp)
f01047d9:	e8 bd ff ff ff       	call   f010479b <strcpy>
	return dst;
}
f01047de:	89 d8                	mov    %ebx,%eax
f01047e0:	83 c4 08             	add    $0x8,%esp
f01047e3:	5b                   	pop    %ebx
f01047e4:	5d                   	pop    %ebp
f01047e5:	c3                   	ret    

f01047e6 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01047e6:	55                   	push   %ebp
f01047e7:	89 e5                	mov    %esp,%ebp
f01047e9:	56                   	push   %esi
f01047ea:	53                   	push   %ebx
f01047eb:	8b 45 08             	mov    0x8(%ebp),%eax
f01047ee:	8b 55 0c             	mov    0xc(%ebp),%edx
f01047f1:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01047f4:	85 f6                	test   %esi,%esi
f01047f6:	74 18                	je     f0104810 <strncpy+0x2a>
f01047f8:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f01047fd:	0f b6 1a             	movzbl (%edx),%ebx
f0104800:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104803:	80 3a 01             	cmpb   $0x1,(%edx)
f0104806:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104809:	83 c1 01             	add    $0x1,%ecx
f010480c:	39 f1                	cmp    %esi,%ecx
f010480e:	75 ed                	jne    f01047fd <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104810:	5b                   	pop    %ebx
f0104811:	5e                   	pop    %esi
f0104812:	5d                   	pop    %ebp
f0104813:	c3                   	ret    

f0104814 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104814:	55                   	push   %ebp
f0104815:	89 e5                	mov    %esp,%ebp
f0104817:	57                   	push   %edi
f0104818:	56                   	push   %esi
f0104819:	53                   	push   %ebx
f010481a:	8b 7d 08             	mov    0x8(%ebp),%edi
f010481d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104820:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104823:	89 f8                	mov    %edi,%eax
f0104825:	85 f6                	test   %esi,%esi
f0104827:	74 2b                	je     f0104854 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f0104829:	83 fe 01             	cmp    $0x1,%esi
f010482c:	74 23                	je     f0104851 <strlcpy+0x3d>
f010482e:	0f b6 0b             	movzbl (%ebx),%ecx
f0104831:	84 c9                	test   %cl,%cl
f0104833:	74 1c                	je     f0104851 <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f0104835:	83 ee 02             	sub    $0x2,%esi
f0104838:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010483d:	88 08                	mov    %cl,(%eax)
f010483f:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104842:	39 f2                	cmp    %esi,%edx
f0104844:	74 0b                	je     f0104851 <strlcpy+0x3d>
f0104846:	83 c2 01             	add    $0x1,%edx
f0104849:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f010484d:	84 c9                	test   %cl,%cl
f010484f:	75 ec                	jne    f010483d <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f0104851:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104854:	29 f8                	sub    %edi,%eax
}
f0104856:	5b                   	pop    %ebx
f0104857:	5e                   	pop    %esi
f0104858:	5f                   	pop    %edi
f0104859:	5d                   	pop    %ebp
f010485a:	c3                   	ret    

f010485b <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010485b:	55                   	push   %ebp
f010485c:	89 e5                	mov    %esp,%ebp
f010485e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104861:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104864:	0f b6 01             	movzbl (%ecx),%eax
f0104867:	84 c0                	test   %al,%al
f0104869:	74 16                	je     f0104881 <strcmp+0x26>
f010486b:	3a 02                	cmp    (%edx),%al
f010486d:	75 12                	jne    f0104881 <strcmp+0x26>
		p++, q++;
f010486f:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104872:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f0104876:	84 c0                	test   %al,%al
f0104878:	74 07                	je     f0104881 <strcmp+0x26>
f010487a:	83 c1 01             	add    $0x1,%ecx
f010487d:	3a 02                	cmp    (%edx),%al
f010487f:	74 ee                	je     f010486f <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104881:	0f b6 c0             	movzbl %al,%eax
f0104884:	0f b6 12             	movzbl (%edx),%edx
f0104887:	29 d0                	sub    %edx,%eax
}
f0104889:	5d                   	pop    %ebp
f010488a:	c3                   	ret    

f010488b <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010488b:	55                   	push   %ebp
f010488c:	89 e5                	mov    %esp,%ebp
f010488e:	53                   	push   %ebx
f010488f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104892:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104895:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104898:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010489d:	85 d2                	test   %edx,%edx
f010489f:	74 28                	je     f01048c9 <strncmp+0x3e>
f01048a1:	0f b6 01             	movzbl (%ecx),%eax
f01048a4:	84 c0                	test   %al,%al
f01048a6:	74 24                	je     f01048cc <strncmp+0x41>
f01048a8:	3a 03                	cmp    (%ebx),%al
f01048aa:	75 20                	jne    f01048cc <strncmp+0x41>
f01048ac:	83 ea 01             	sub    $0x1,%edx
f01048af:	74 13                	je     f01048c4 <strncmp+0x39>
		n--, p++, q++;
f01048b1:	83 c1 01             	add    $0x1,%ecx
f01048b4:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01048b7:	0f b6 01             	movzbl (%ecx),%eax
f01048ba:	84 c0                	test   %al,%al
f01048bc:	74 0e                	je     f01048cc <strncmp+0x41>
f01048be:	3a 03                	cmp    (%ebx),%al
f01048c0:	74 ea                	je     f01048ac <strncmp+0x21>
f01048c2:	eb 08                	jmp    f01048cc <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f01048c4:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01048c9:	5b                   	pop    %ebx
f01048ca:	5d                   	pop    %ebp
f01048cb:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01048cc:	0f b6 01             	movzbl (%ecx),%eax
f01048cf:	0f b6 13             	movzbl (%ebx),%edx
f01048d2:	29 d0                	sub    %edx,%eax
f01048d4:	eb f3                	jmp    f01048c9 <strncmp+0x3e>

f01048d6 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01048d6:	55                   	push   %ebp
f01048d7:	89 e5                	mov    %esp,%ebp
f01048d9:	8b 45 08             	mov    0x8(%ebp),%eax
f01048dc:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01048e0:	0f b6 10             	movzbl (%eax),%edx
f01048e3:	84 d2                	test   %dl,%dl
f01048e5:	74 1c                	je     f0104903 <strchr+0x2d>
		if (*s == c)
f01048e7:	38 ca                	cmp    %cl,%dl
f01048e9:	75 09                	jne    f01048f4 <strchr+0x1e>
f01048eb:	eb 1b                	jmp    f0104908 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01048ed:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f01048f0:	38 ca                	cmp    %cl,%dl
f01048f2:	74 14                	je     f0104908 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01048f4:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f01048f8:	84 d2                	test   %dl,%dl
f01048fa:	75 f1                	jne    f01048ed <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f01048fc:	b8 00 00 00 00       	mov    $0x0,%eax
f0104901:	eb 05                	jmp    f0104908 <strchr+0x32>
f0104903:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104908:	5d                   	pop    %ebp
f0104909:	c3                   	ret    

f010490a <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010490a:	55                   	push   %ebp
f010490b:	89 e5                	mov    %esp,%ebp
f010490d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104910:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104914:	0f b6 10             	movzbl (%eax),%edx
f0104917:	84 d2                	test   %dl,%dl
f0104919:	74 14                	je     f010492f <strfind+0x25>
		if (*s == c)
f010491b:	38 ca                	cmp    %cl,%dl
f010491d:	75 06                	jne    f0104925 <strfind+0x1b>
f010491f:	eb 0e                	jmp    f010492f <strfind+0x25>
f0104921:	38 ca                	cmp    %cl,%dl
f0104923:	74 0a                	je     f010492f <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0104925:	83 c0 01             	add    $0x1,%eax
f0104928:	0f b6 10             	movzbl (%eax),%edx
f010492b:	84 d2                	test   %dl,%dl
f010492d:	75 f2                	jne    f0104921 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f010492f:	5d                   	pop    %ebp
f0104930:	c3                   	ret    

f0104931 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104931:	55                   	push   %ebp
f0104932:	89 e5                	mov    %esp,%ebp
f0104934:	83 ec 0c             	sub    $0xc,%esp
f0104937:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010493a:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010493d:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0104940:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104943:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104946:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104949:	85 c9                	test   %ecx,%ecx
f010494b:	74 30                	je     f010497d <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010494d:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104953:	75 25                	jne    f010497a <memset+0x49>
f0104955:	f6 c1 03             	test   $0x3,%cl
f0104958:	75 20                	jne    f010497a <memset+0x49>
		c &= 0xFF;
f010495a:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010495d:	89 d3                	mov    %edx,%ebx
f010495f:	c1 e3 08             	shl    $0x8,%ebx
f0104962:	89 d6                	mov    %edx,%esi
f0104964:	c1 e6 18             	shl    $0x18,%esi
f0104967:	89 d0                	mov    %edx,%eax
f0104969:	c1 e0 10             	shl    $0x10,%eax
f010496c:	09 f0                	or     %esi,%eax
f010496e:	09 d0                	or     %edx,%eax
f0104970:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0104972:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0104975:	fc                   	cld    
f0104976:	f3 ab                	rep stos %eax,%es:(%edi)
f0104978:	eb 03                	jmp    f010497d <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010497a:	fc                   	cld    
f010497b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010497d:	89 f8                	mov    %edi,%eax
f010497f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0104982:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0104985:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0104988:	89 ec                	mov    %ebp,%esp
f010498a:	5d                   	pop    %ebp
f010498b:	c3                   	ret    

f010498c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010498c:	55                   	push   %ebp
f010498d:	89 e5                	mov    %esp,%ebp
f010498f:	83 ec 08             	sub    $0x8,%esp
f0104992:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0104995:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0104998:	8b 45 08             	mov    0x8(%ebp),%eax
f010499b:	8b 75 0c             	mov    0xc(%ebp),%esi
f010499e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01049a1:	39 c6                	cmp    %eax,%esi
f01049a3:	73 36                	jae    f01049db <memmove+0x4f>
f01049a5:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01049a8:	39 d0                	cmp    %edx,%eax
f01049aa:	73 2f                	jae    f01049db <memmove+0x4f>
		s += n;
		d += n;
f01049ac:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01049af:	f6 c2 03             	test   $0x3,%dl
f01049b2:	75 1b                	jne    f01049cf <memmove+0x43>
f01049b4:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01049ba:	75 13                	jne    f01049cf <memmove+0x43>
f01049bc:	f6 c1 03             	test   $0x3,%cl
f01049bf:	75 0e                	jne    f01049cf <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01049c1:	83 ef 04             	sub    $0x4,%edi
f01049c4:	8d 72 fc             	lea    -0x4(%edx),%esi
f01049c7:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01049ca:	fd                   	std    
f01049cb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01049cd:	eb 09                	jmp    f01049d8 <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01049cf:	83 ef 01             	sub    $0x1,%edi
f01049d2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01049d5:	fd                   	std    
f01049d6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01049d8:	fc                   	cld    
f01049d9:	eb 20                	jmp    f01049fb <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01049db:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01049e1:	75 13                	jne    f01049f6 <memmove+0x6a>
f01049e3:	a8 03                	test   $0x3,%al
f01049e5:	75 0f                	jne    f01049f6 <memmove+0x6a>
f01049e7:	f6 c1 03             	test   $0x3,%cl
f01049ea:	75 0a                	jne    f01049f6 <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01049ec:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01049ef:	89 c7                	mov    %eax,%edi
f01049f1:	fc                   	cld    
f01049f2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01049f4:	eb 05                	jmp    f01049fb <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01049f6:	89 c7                	mov    %eax,%edi
f01049f8:	fc                   	cld    
f01049f9:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01049fb:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01049fe:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0104a01:	89 ec                	mov    %ebp,%esp
f0104a03:	5d                   	pop    %ebp
f0104a04:	c3                   	ret    

f0104a05 <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0104a05:	55                   	push   %ebp
f0104a06:	89 e5                	mov    %esp,%ebp
f0104a08:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0104a0b:	8b 45 10             	mov    0x10(%ebp),%eax
f0104a0e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104a12:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104a15:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104a19:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a1c:	89 04 24             	mov    %eax,(%esp)
f0104a1f:	e8 68 ff ff ff       	call   f010498c <memmove>
}
f0104a24:	c9                   	leave  
f0104a25:	c3                   	ret    

f0104a26 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104a26:	55                   	push   %ebp
f0104a27:	89 e5                	mov    %esp,%ebp
f0104a29:	57                   	push   %edi
f0104a2a:	56                   	push   %esi
f0104a2b:	53                   	push   %ebx
f0104a2c:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0104a2f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104a32:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104a35:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104a3a:	85 ff                	test   %edi,%edi
f0104a3c:	74 37                	je     f0104a75 <memcmp+0x4f>
		if (*s1 != *s2)
f0104a3e:	0f b6 03             	movzbl (%ebx),%eax
f0104a41:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104a44:	83 ef 01             	sub    $0x1,%edi
f0104a47:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f0104a4c:	38 c8                	cmp    %cl,%al
f0104a4e:	74 1c                	je     f0104a6c <memcmp+0x46>
f0104a50:	eb 10                	jmp    f0104a62 <memcmp+0x3c>
f0104a52:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0104a57:	83 c2 01             	add    $0x1,%edx
f0104a5a:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0104a5e:	38 c8                	cmp    %cl,%al
f0104a60:	74 0a                	je     f0104a6c <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f0104a62:	0f b6 c0             	movzbl %al,%eax
f0104a65:	0f b6 c9             	movzbl %cl,%ecx
f0104a68:	29 c8                	sub    %ecx,%eax
f0104a6a:	eb 09                	jmp    f0104a75 <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104a6c:	39 fa                	cmp    %edi,%edx
f0104a6e:	75 e2                	jne    f0104a52 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104a70:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104a75:	5b                   	pop    %ebx
f0104a76:	5e                   	pop    %esi
f0104a77:	5f                   	pop    %edi
f0104a78:	5d                   	pop    %ebp
f0104a79:	c3                   	ret    

f0104a7a <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104a7a:	55                   	push   %ebp
f0104a7b:	89 e5                	mov    %esp,%ebp
f0104a7d:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0104a80:	89 c2                	mov    %eax,%edx
f0104a82:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0104a85:	39 d0                	cmp    %edx,%eax
f0104a87:	73 19                	jae    f0104aa2 <memfind+0x28>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104a89:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f0104a8d:	38 08                	cmp    %cl,(%eax)
f0104a8f:	75 06                	jne    f0104a97 <memfind+0x1d>
f0104a91:	eb 0f                	jmp    f0104aa2 <memfind+0x28>
f0104a93:	38 08                	cmp    %cl,(%eax)
f0104a95:	74 0b                	je     f0104aa2 <memfind+0x28>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104a97:	83 c0 01             	add    $0x1,%eax
f0104a9a:	39 d0                	cmp    %edx,%eax
f0104a9c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104aa0:	75 f1                	jne    f0104a93 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104aa2:	5d                   	pop    %ebp
f0104aa3:	c3                   	ret    

f0104aa4 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104aa4:	55                   	push   %ebp
f0104aa5:	89 e5                	mov    %esp,%ebp
f0104aa7:	57                   	push   %edi
f0104aa8:	56                   	push   %esi
f0104aa9:	53                   	push   %ebx
f0104aaa:	8b 55 08             	mov    0x8(%ebp),%edx
f0104aad:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104ab0:	0f b6 02             	movzbl (%edx),%eax
f0104ab3:	3c 20                	cmp    $0x20,%al
f0104ab5:	74 04                	je     f0104abb <strtol+0x17>
f0104ab7:	3c 09                	cmp    $0x9,%al
f0104ab9:	75 0e                	jne    f0104ac9 <strtol+0x25>
		s++;
f0104abb:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104abe:	0f b6 02             	movzbl (%edx),%eax
f0104ac1:	3c 20                	cmp    $0x20,%al
f0104ac3:	74 f6                	je     f0104abb <strtol+0x17>
f0104ac5:	3c 09                	cmp    $0x9,%al
f0104ac7:	74 f2                	je     f0104abb <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104ac9:	3c 2b                	cmp    $0x2b,%al
f0104acb:	75 0a                	jne    f0104ad7 <strtol+0x33>
		s++;
f0104acd:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0104ad0:	bf 00 00 00 00       	mov    $0x0,%edi
f0104ad5:	eb 10                	jmp    f0104ae7 <strtol+0x43>
f0104ad7:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104adc:	3c 2d                	cmp    $0x2d,%al
f0104ade:	75 07                	jne    f0104ae7 <strtol+0x43>
		s++, neg = 1;
f0104ae0:	83 c2 01             	add    $0x1,%edx
f0104ae3:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104ae7:	85 db                	test   %ebx,%ebx
f0104ae9:	0f 94 c0             	sete   %al
f0104aec:	74 05                	je     f0104af3 <strtol+0x4f>
f0104aee:	83 fb 10             	cmp    $0x10,%ebx
f0104af1:	75 15                	jne    f0104b08 <strtol+0x64>
f0104af3:	80 3a 30             	cmpb   $0x30,(%edx)
f0104af6:	75 10                	jne    f0104b08 <strtol+0x64>
f0104af8:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0104afc:	75 0a                	jne    f0104b08 <strtol+0x64>
		s += 2, base = 16;
f0104afe:	83 c2 02             	add    $0x2,%edx
f0104b01:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104b06:	eb 13                	jmp    f0104b1b <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f0104b08:	84 c0                	test   %al,%al
f0104b0a:	74 0f                	je     f0104b1b <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104b0c:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104b11:	80 3a 30             	cmpb   $0x30,(%edx)
f0104b14:	75 05                	jne    f0104b1b <strtol+0x77>
		s++, base = 8;
f0104b16:	83 c2 01             	add    $0x1,%edx
f0104b19:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f0104b1b:	b8 00 00 00 00       	mov    $0x0,%eax
f0104b20:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104b22:	0f b6 0a             	movzbl (%edx),%ecx
f0104b25:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0104b28:	80 fb 09             	cmp    $0x9,%bl
f0104b2b:	77 08                	ja     f0104b35 <strtol+0x91>
			dig = *s - '0';
f0104b2d:	0f be c9             	movsbl %cl,%ecx
f0104b30:	83 e9 30             	sub    $0x30,%ecx
f0104b33:	eb 1e                	jmp    f0104b53 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f0104b35:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f0104b38:	80 fb 19             	cmp    $0x19,%bl
f0104b3b:	77 08                	ja     f0104b45 <strtol+0xa1>
			dig = *s - 'a' + 10;
f0104b3d:	0f be c9             	movsbl %cl,%ecx
f0104b40:	83 e9 57             	sub    $0x57,%ecx
f0104b43:	eb 0e                	jmp    f0104b53 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f0104b45:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0104b48:	80 fb 19             	cmp    $0x19,%bl
f0104b4b:	77 14                	ja     f0104b61 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0104b4d:	0f be c9             	movsbl %cl,%ecx
f0104b50:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0104b53:	39 f1                	cmp    %esi,%ecx
f0104b55:	7d 0e                	jge    f0104b65 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f0104b57:	83 c2 01             	add    $0x1,%edx
f0104b5a:	0f af c6             	imul   %esi,%eax
f0104b5d:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0104b5f:	eb c1                	jmp    f0104b22 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0104b61:	89 c1                	mov    %eax,%ecx
f0104b63:	eb 02                	jmp    f0104b67 <strtol+0xc3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0104b65:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0104b67:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104b6b:	74 05                	je     f0104b72 <strtol+0xce>
		*endptr = (char *) s;
f0104b6d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104b70:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0104b72:	89 ca                	mov    %ecx,%edx
f0104b74:	f7 da                	neg    %edx
f0104b76:	85 ff                	test   %edi,%edi
f0104b78:	0f 45 c2             	cmovne %edx,%eax
}
f0104b7b:	5b                   	pop    %ebx
f0104b7c:	5e                   	pop    %esi
f0104b7d:	5f                   	pop    %edi
f0104b7e:	5d                   	pop    %ebp
f0104b7f:	c3                   	ret    

f0104b80 <__udivdi3>:
f0104b80:	83 ec 1c             	sub    $0x1c,%esp
f0104b83:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0104b87:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f0104b8b:	8b 44 24 20          	mov    0x20(%esp),%eax
f0104b8f:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0104b93:	89 74 24 10          	mov    %esi,0x10(%esp)
f0104b97:	8b 74 24 24          	mov    0x24(%esp),%esi
f0104b9b:	85 ff                	test   %edi,%edi
f0104b9d:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0104ba1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104ba5:	89 cd                	mov    %ecx,%ebp
f0104ba7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104bab:	75 33                	jne    f0104be0 <__udivdi3+0x60>
f0104bad:	39 f1                	cmp    %esi,%ecx
f0104baf:	77 57                	ja     f0104c08 <__udivdi3+0x88>
f0104bb1:	85 c9                	test   %ecx,%ecx
f0104bb3:	75 0b                	jne    f0104bc0 <__udivdi3+0x40>
f0104bb5:	b8 01 00 00 00       	mov    $0x1,%eax
f0104bba:	31 d2                	xor    %edx,%edx
f0104bbc:	f7 f1                	div    %ecx
f0104bbe:	89 c1                	mov    %eax,%ecx
f0104bc0:	89 f0                	mov    %esi,%eax
f0104bc2:	31 d2                	xor    %edx,%edx
f0104bc4:	f7 f1                	div    %ecx
f0104bc6:	89 c6                	mov    %eax,%esi
f0104bc8:	8b 44 24 04          	mov    0x4(%esp),%eax
f0104bcc:	f7 f1                	div    %ecx
f0104bce:	89 f2                	mov    %esi,%edx
f0104bd0:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104bd4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104bd8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104bdc:	83 c4 1c             	add    $0x1c,%esp
f0104bdf:	c3                   	ret    
f0104be0:	31 d2                	xor    %edx,%edx
f0104be2:	31 c0                	xor    %eax,%eax
f0104be4:	39 f7                	cmp    %esi,%edi
f0104be6:	77 e8                	ja     f0104bd0 <__udivdi3+0x50>
f0104be8:	0f bd cf             	bsr    %edi,%ecx
f0104beb:	83 f1 1f             	xor    $0x1f,%ecx
f0104bee:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104bf2:	75 2c                	jne    f0104c20 <__udivdi3+0xa0>
f0104bf4:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0104bf8:	76 04                	jbe    f0104bfe <__udivdi3+0x7e>
f0104bfa:	39 f7                	cmp    %esi,%edi
f0104bfc:	73 d2                	jae    f0104bd0 <__udivdi3+0x50>
f0104bfe:	31 d2                	xor    %edx,%edx
f0104c00:	b8 01 00 00 00       	mov    $0x1,%eax
f0104c05:	eb c9                	jmp    f0104bd0 <__udivdi3+0x50>
f0104c07:	90                   	nop
f0104c08:	89 f2                	mov    %esi,%edx
f0104c0a:	f7 f1                	div    %ecx
f0104c0c:	31 d2                	xor    %edx,%edx
f0104c0e:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104c12:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104c16:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104c1a:	83 c4 1c             	add    $0x1c,%esp
f0104c1d:	c3                   	ret    
f0104c1e:	66 90                	xchg   %ax,%ax
f0104c20:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104c25:	b8 20 00 00 00       	mov    $0x20,%eax
f0104c2a:	89 ea                	mov    %ebp,%edx
f0104c2c:	2b 44 24 04          	sub    0x4(%esp),%eax
f0104c30:	d3 e7                	shl    %cl,%edi
f0104c32:	89 c1                	mov    %eax,%ecx
f0104c34:	d3 ea                	shr    %cl,%edx
f0104c36:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104c3b:	09 fa                	or     %edi,%edx
f0104c3d:	89 f7                	mov    %esi,%edi
f0104c3f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104c43:	89 f2                	mov    %esi,%edx
f0104c45:	8b 74 24 08          	mov    0x8(%esp),%esi
f0104c49:	d3 e5                	shl    %cl,%ebp
f0104c4b:	89 c1                	mov    %eax,%ecx
f0104c4d:	d3 ef                	shr    %cl,%edi
f0104c4f:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104c54:	d3 e2                	shl    %cl,%edx
f0104c56:	89 c1                	mov    %eax,%ecx
f0104c58:	d3 ee                	shr    %cl,%esi
f0104c5a:	09 d6                	or     %edx,%esi
f0104c5c:	89 fa                	mov    %edi,%edx
f0104c5e:	89 f0                	mov    %esi,%eax
f0104c60:	f7 74 24 0c          	divl   0xc(%esp)
f0104c64:	89 d7                	mov    %edx,%edi
f0104c66:	89 c6                	mov    %eax,%esi
f0104c68:	f7 e5                	mul    %ebp
f0104c6a:	39 d7                	cmp    %edx,%edi
f0104c6c:	72 22                	jb     f0104c90 <__udivdi3+0x110>
f0104c6e:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0104c72:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104c77:	d3 e5                	shl    %cl,%ebp
f0104c79:	39 c5                	cmp    %eax,%ebp
f0104c7b:	73 04                	jae    f0104c81 <__udivdi3+0x101>
f0104c7d:	39 d7                	cmp    %edx,%edi
f0104c7f:	74 0f                	je     f0104c90 <__udivdi3+0x110>
f0104c81:	89 f0                	mov    %esi,%eax
f0104c83:	31 d2                	xor    %edx,%edx
f0104c85:	e9 46 ff ff ff       	jmp    f0104bd0 <__udivdi3+0x50>
f0104c8a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104c90:	8d 46 ff             	lea    -0x1(%esi),%eax
f0104c93:	31 d2                	xor    %edx,%edx
f0104c95:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104c99:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104c9d:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104ca1:	83 c4 1c             	add    $0x1c,%esp
f0104ca4:	c3                   	ret    
	...

f0104cb0 <__umoddi3>:
f0104cb0:	83 ec 1c             	sub    $0x1c,%esp
f0104cb3:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0104cb7:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f0104cbb:	8b 44 24 20          	mov    0x20(%esp),%eax
f0104cbf:	89 74 24 10          	mov    %esi,0x10(%esp)
f0104cc3:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0104cc7:	8b 74 24 24          	mov    0x24(%esp),%esi
f0104ccb:	85 ed                	test   %ebp,%ebp
f0104ccd:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0104cd1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104cd5:	89 cf                	mov    %ecx,%edi
f0104cd7:	89 04 24             	mov    %eax,(%esp)
f0104cda:	89 f2                	mov    %esi,%edx
f0104cdc:	75 1a                	jne    f0104cf8 <__umoddi3+0x48>
f0104cde:	39 f1                	cmp    %esi,%ecx
f0104ce0:	76 4e                	jbe    f0104d30 <__umoddi3+0x80>
f0104ce2:	f7 f1                	div    %ecx
f0104ce4:	89 d0                	mov    %edx,%eax
f0104ce6:	31 d2                	xor    %edx,%edx
f0104ce8:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104cec:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104cf0:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104cf4:	83 c4 1c             	add    $0x1c,%esp
f0104cf7:	c3                   	ret    
f0104cf8:	39 f5                	cmp    %esi,%ebp
f0104cfa:	77 54                	ja     f0104d50 <__umoddi3+0xa0>
f0104cfc:	0f bd c5             	bsr    %ebp,%eax
f0104cff:	83 f0 1f             	xor    $0x1f,%eax
f0104d02:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104d06:	75 60                	jne    f0104d68 <__umoddi3+0xb8>
f0104d08:	3b 0c 24             	cmp    (%esp),%ecx
f0104d0b:	0f 87 07 01 00 00    	ja     f0104e18 <__umoddi3+0x168>
f0104d11:	89 f2                	mov    %esi,%edx
f0104d13:	8b 34 24             	mov    (%esp),%esi
f0104d16:	29 ce                	sub    %ecx,%esi
f0104d18:	19 ea                	sbb    %ebp,%edx
f0104d1a:	89 34 24             	mov    %esi,(%esp)
f0104d1d:	8b 04 24             	mov    (%esp),%eax
f0104d20:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104d24:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104d28:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104d2c:	83 c4 1c             	add    $0x1c,%esp
f0104d2f:	c3                   	ret    
f0104d30:	85 c9                	test   %ecx,%ecx
f0104d32:	75 0b                	jne    f0104d3f <__umoddi3+0x8f>
f0104d34:	b8 01 00 00 00       	mov    $0x1,%eax
f0104d39:	31 d2                	xor    %edx,%edx
f0104d3b:	f7 f1                	div    %ecx
f0104d3d:	89 c1                	mov    %eax,%ecx
f0104d3f:	89 f0                	mov    %esi,%eax
f0104d41:	31 d2                	xor    %edx,%edx
f0104d43:	f7 f1                	div    %ecx
f0104d45:	8b 04 24             	mov    (%esp),%eax
f0104d48:	f7 f1                	div    %ecx
f0104d4a:	eb 98                	jmp    f0104ce4 <__umoddi3+0x34>
f0104d4c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104d50:	89 f2                	mov    %esi,%edx
f0104d52:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104d56:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104d5a:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104d5e:	83 c4 1c             	add    $0x1c,%esp
f0104d61:	c3                   	ret    
f0104d62:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104d68:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104d6d:	89 e8                	mov    %ebp,%eax
f0104d6f:	bd 20 00 00 00       	mov    $0x20,%ebp
f0104d74:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0104d78:	89 fa                	mov    %edi,%edx
f0104d7a:	d3 e0                	shl    %cl,%eax
f0104d7c:	89 e9                	mov    %ebp,%ecx
f0104d7e:	d3 ea                	shr    %cl,%edx
f0104d80:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104d85:	09 c2                	or     %eax,%edx
f0104d87:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104d8b:	89 14 24             	mov    %edx,(%esp)
f0104d8e:	89 f2                	mov    %esi,%edx
f0104d90:	d3 e7                	shl    %cl,%edi
f0104d92:	89 e9                	mov    %ebp,%ecx
f0104d94:	d3 ea                	shr    %cl,%edx
f0104d96:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104d9b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104d9f:	d3 e6                	shl    %cl,%esi
f0104da1:	89 e9                	mov    %ebp,%ecx
f0104da3:	d3 e8                	shr    %cl,%eax
f0104da5:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104daa:	09 f0                	or     %esi,%eax
f0104dac:	8b 74 24 08          	mov    0x8(%esp),%esi
f0104db0:	f7 34 24             	divl   (%esp)
f0104db3:	d3 e6                	shl    %cl,%esi
f0104db5:	89 74 24 08          	mov    %esi,0x8(%esp)
f0104db9:	89 d6                	mov    %edx,%esi
f0104dbb:	f7 e7                	mul    %edi
f0104dbd:	39 d6                	cmp    %edx,%esi
f0104dbf:	89 c1                	mov    %eax,%ecx
f0104dc1:	89 d7                	mov    %edx,%edi
f0104dc3:	72 3f                	jb     f0104e04 <__umoddi3+0x154>
f0104dc5:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0104dc9:	72 35                	jb     f0104e00 <__umoddi3+0x150>
f0104dcb:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104dcf:	29 c8                	sub    %ecx,%eax
f0104dd1:	19 fe                	sbb    %edi,%esi
f0104dd3:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104dd8:	89 f2                	mov    %esi,%edx
f0104dda:	d3 e8                	shr    %cl,%eax
f0104ddc:	89 e9                	mov    %ebp,%ecx
f0104dde:	d3 e2                	shl    %cl,%edx
f0104de0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104de5:	09 d0                	or     %edx,%eax
f0104de7:	89 f2                	mov    %esi,%edx
f0104de9:	d3 ea                	shr    %cl,%edx
f0104deb:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104def:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104df3:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104df7:	83 c4 1c             	add    $0x1c,%esp
f0104dfa:	c3                   	ret    
f0104dfb:	90                   	nop
f0104dfc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104e00:	39 d6                	cmp    %edx,%esi
f0104e02:	75 c7                	jne    f0104dcb <__umoddi3+0x11b>
f0104e04:	89 d7                	mov    %edx,%edi
f0104e06:	89 c1                	mov    %eax,%ecx
f0104e08:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f0104e0c:	1b 3c 24             	sbb    (%esp),%edi
f0104e0f:	eb ba                	jmp    f0104dcb <__umoddi3+0x11b>
f0104e11:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104e18:	39 f5                	cmp    %esi,%ebp
f0104e1a:	0f 82 f1 fe ff ff    	jb     f0104d11 <__umoddi3+0x61>
f0104e20:	e9 f8 fe ff ff       	jmp    f0104d1d <__umoddi3+0x6d>
