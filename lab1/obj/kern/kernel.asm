
obj/kern/kernel：     文件格式 elf32-i386


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
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 f0 10 00       	mov    $0x10f000,%eax
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
f0100034:	bc 00 f0 10 f0       	mov    $0xf010f000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 56 00 00 00       	call   f0100094 <i386_init>

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
f0100044:	83 ec 0c             	sub    $0xc,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	53                   	push   %ebx
f010004b:	68 80 17 10 f0       	push   $0xf0101780
f0100050:	e8 57 08 00 00       	call   f01008ac <cprintf>
	if (x > 0)
f0100055:	83 c4 10             	add    $0x10,%esp
f0100058:	85 db                	test   %ebx,%ebx
f010005a:	7e 11                	jle    f010006d <test_backtrace+0x2d>
		test_backtrace(x-1);
f010005c:	83 ec 0c             	sub    $0xc,%esp
f010005f:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100062:	50                   	push   %eax
f0100063:	e8 d8 ff ff ff       	call   f0100040 <test_backtrace>
f0100068:	83 c4 10             	add    $0x10,%esp
f010006b:	eb 11                	jmp    f010007e <test_backtrace+0x3e>
	else
		mon_backtrace(0, 0, 0);
f010006d:	83 ec 04             	sub    $0x4,%esp
f0100070:	6a 00                	push   $0x0
f0100072:	6a 00                	push   $0x0
f0100074:	6a 00                	push   $0x0
f0100076:	e8 ab 06 00 00       	call   f0100726 <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 9c 17 10 f0       	push   $0xf010179c
f0100087:	e8 20 08 00 00       	call   f01008ac <cprintf>
}
f010008c:	83 c4 10             	add    $0x10,%esp
f010008f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100092:	c9                   	leave  
f0100093:	c3                   	ret    

f0100094 <i386_init>:

void
i386_init(void)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f010009a:	b8 44 19 11 f0       	mov    $0xf0111944,%eax
f010009f:	2d 00 13 11 f0       	sub    $0xf0111300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 13 11 f0       	push   $0xf0111300
f01000ac:	e8 52 12 00 00       	call   f0101303 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 73 04 00 00       	call   f0100529 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 b7 17 10 f0       	push   $0xf01017b7
f01000c3:	e8 e4 07 00 00       	call   f01008ac <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000c8:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000cf:	e8 6c ff ff ff       	call   f0100040 <test_backtrace>
f01000d4:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000d7:	83 ec 0c             	sub    $0xc,%esp
f01000da:	6a 00                	push   $0x0
f01000dc:	e8 4f 06 00 00       	call   f0100730 <monitor>
f01000e1:	83 c4 10             	add    $0x10,%esp
f01000e4:	eb f1                	jmp    f01000d7 <i386_init+0x43>

f01000e6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000e6:	55                   	push   %ebp
f01000e7:	89 e5                	mov    %esp,%ebp
f01000e9:	56                   	push   %esi
f01000ea:	53                   	push   %ebx
f01000eb:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000ee:	83 3d 40 19 11 f0 00 	cmpl   $0x0,0xf0111940
f01000f5:	75 37                	jne    f010012e <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000f7:	89 35 40 19 11 f0    	mov    %esi,0xf0111940

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000fd:	fa                   	cli    
f01000fe:	fc                   	cld    

	va_start(ap, fmt);
f01000ff:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100102:	83 ec 04             	sub    $0x4,%esp
f0100105:	ff 75 0c             	pushl  0xc(%ebp)
f0100108:	ff 75 08             	pushl  0x8(%ebp)
f010010b:	68 d2 17 10 f0       	push   $0xf01017d2
f0100110:	e8 97 07 00 00       	call   f01008ac <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 67 07 00 00       	call   f0100886 <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 0e 18 10 f0 	movl   $0xf010180e,(%esp)
f0100126:	e8 81 07 00 00       	call   f01008ac <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 f8 05 00 00       	call   f0100730 <monitor>
f0100138:	83 c4 10             	add    $0x10,%esp
f010013b:	eb f1                	jmp    f010012e <_panic+0x48>

f010013d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010013d:	55                   	push   %ebp
f010013e:	89 e5                	mov    %esp,%ebp
f0100140:	53                   	push   %ebx
f0100141:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100144:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100147:	ff 75 0c             	pushl  0xc(%ebp)
f010014a:	ff 75 08             	pushl  0x8(%ebp)
f010014d:	68 ea 17 10 f0       	push   $0xf01017ea
f0100152:	e8 55 07 00 00       	call   f01008ac <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 23 07 00 00       	call   f0100886 <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 0e 18 10 f0 	movl   $0xf010180e,(%esp)
f010016a:	e8 3d 07 00 00       	call   f01008ac <cprintf>
	va_end(ap);
}
f010016f:	83 c4 10             	add    $0x10,%esp
f0100172:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100175:	c9                   	leave  
f0100176:	c3                   	ret    

f0100177 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100177:	55                   	push   %ebp
f0100178:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010017a:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010017f:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100180:	a8 01                	test   $0x1,%al
f0100182:	74 0b                	je     f010018f <serial_proc_data+0x18>
f0100184:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100189:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010018a:	0f b6 c0             	movzbl %al,%eax
f010018d:	eb 05                	jmp    f0100194 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010018f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100194:	5d                   	pop    %ebp
f0100195:	c3                   	ret    

f0100196 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100196:	55                   	push   %ebp
f0100197:	89 e5                	mov    %esp,%ebp
f0100199:	53                   	push   %ebx
f010019a:	83 ec 04             	sub    $0x4,%esp
f010019d:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010019f:	eb 2b                	jmp    f01001cc <cons_intr+0x36>
		if (c == 0)
f01001a1:	85 c0                	test   %eax,%eax
f01001a3:	74 27                	je     f01001cc <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f01001a5:	8b 0d 24 15 11 f0    	mov    0xf0111524,%ecx
f01001ab:	8d 51 01             	lea    0x1(%ecx),%edx
f01001ae:	89 15 24 15 11 f0    	mov    %edx,0xf0111524
f01001b4:	88 81 20 13 11 f0    	mov    %al,-0xfeeece0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01001ba:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001c0:	75 0a                	jne    f01001cc <cons_intr+0x36>
			cons.wpos = 0;
f01001c2:	c7 05 24 15 11 f0 00 	movl   $0x0,0xf0111524
f01001c9:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001cc:	ff d3                	call   *%ebx
f01001ce:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001d1:	75 ce                	jne    f01001a1 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001d3:	83 c4 04             	add    $0x4,%esp
f01001d6:	5b                   	pop    %ebx
f01001d7:	5d                   	pop    %ebp
f01001d8:	c3                   	ret    

f01001d9 <kbd_proc_data>:
f01001d9:	ba 64 00 00 00       	mov    $0x64,%edx
f01001de:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01001df:	a8 01                	test   $0x1,%al
f01001e1:	0f 84 ee 00 00 00    	je     f01002d5 <kbd_proc_data+0xfc>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01001e7:	a8 20                	test   $0x20,%al
f01001e9:	0f 85 ec 00 00 00    	jne    f01002db <kbd_proc_data+0x102>
f01001ef:	ba 60 00 00 00       	mov    $0x60,%edx
f01001f4:	ec                   	in     (%dx),%al
f01001f5:	88 c2                	mov    %al,%dl
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001f7:	3c e0                	cmp    $0xe0,%al
f01001f9:	75 0d                	jne    f0100208 <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001fb:	83 0d 00 13 11 f0 40 	orl    $0x40,0xf0111300
		return 0;
f0100202:	b8 00 00 00 00       	mov    $0x0,%eax
f0100207:	c3                   	ret    
	} else if (data & 0x80) {
f0100208:	84 c0                	test   %al,%al
f010020a:	79 2e                	jns    f010023a <kbd_proc_data+0x61>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010020c:	8b 0d 00 13 11 f0    	mov    0xf0111300,%ecx
f0100212:	f6 c1 40             	test   $0x40,%cl
f0100215:	75 05                	jne    f010021c <kbd_proc_data+0x43>
f0100217:	83 e0 7f             	and    $0x7f,%eax
f010021a:	88 c2                	mov    %al,%dl
		shift &= ~(shiftcode[data] | E0ESC);
f010021c:	0f b6 c2             	movzbl %dl,%eax
f010021f:	8a 80 60 19 10 f0    	mov    -0xfefe6a0(%eax),%al
f0100225:	83 c8 40             	or     $0x40,%eax
f0100228:	0f b6 c0             	movzbl %al,%eax
f010022b:	f7 d0                	not    %eax
f010022d:	21 c8                	and    %ecx,%eax
f010022f:	a3 00 13 11 f0       	mov    %eax,0xf0111300
		return 0;
f0100234:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100239:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010023a:	55                   	push   %ebp
f010023b:	89 e5                	mov    %esp,%ebp
f010023d:	53                   	push   %ebx
f010023e:	83 ec 04             	sub    $0x4,%esp
	} else if (data & 0x80) {
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
		shift &= ~(shiftcode[data] | E0ESC);
		return 0;
	} else if (shift & E0ESC) {
f0100241:	8b 0d 00 13 11 f0    	mov    0xf0111300,%ecx
f0100247:	f6 c1 40             	test   $0x40,%cl
f010024a:	74 0e                	je     f010025a <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010024c:	83 c8 80             	or     $0xffffff80,%eax
f010024f:	88 c2                	mov    %al,%dl
		shift &= ~E0ESC;
f0100251:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100254:	89 0d 00 13 11 f0    	mov    %ecx,0xf0111300
	}

	shift |= shiftcode[data];
f010025a:	0f b6 c2             	movzbl %dl,%eax
	shift ^= togglecode[data];
f010025d:	0f b6 90 60 19 10 f0 	movzbl -0xfefe6a0(%eax),%edx
f0100264:	0b 15 00 13 11 f0    	or     0xf0111300,%edx
f010026a:	0f b6 88 60 18 10 f0 	movzbl -0xfefe7a0(%eax),%ecx
f0100271:	31 ca                	xor    %ecx,%edx
f0100273:	89 15 00 13 11 f0    	mov    %edx,0xf0111300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100279:	89 d1                	mov    %edx,%ecx
f010027b:	83 e1 03             	and    $0x3,%ecx
f010027e:	8b 0c 8d 40 18 10 f0 	mov    -0xfefe7c0(,%ecx,4),%ecx
f0100285:	8a 04 01             	mov    (%ecx,%eax,1),%al
f0100288:	0f b6 d8             	movzbl %al,%ebx
	if (shift & CAPSLOCK) {
f010028b:	f6 c2 08             	test   $0x8,%dl
f010028e:	74 1a                	je     f01002aa <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f0100290:	89 d8                	mov    %ebx,%eax
f0100292:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100295:	83 f9 19             	cmp    $0x19,%ecx
f0100298:	77 05                	ja     f010029f <kbd_proc_data+0xc6>
			c += 'A' - 'a';
f010029a:	83 eb 20             	sub    $0x20,%ebx
f010029d:	eb 0b                	jmp    f01002aa <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f010029f:	83 e8 41             	sub    $0x41,%eax
f01002a2:	83 f8 19             	cmp    $0x19,%eax
f01002a5:	77 03                	ja     f01002aa <kbd_proc_data+0xd1>
			c += 'a' - 'A';
f01002a7:	83 c3 20             	add    $0x20,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002aa:	f7 d2                	not    %edx
f01002ac:	f6 c2 06             	test   $0x6,%dl
f01002af:	75 30                	jne    f01002e1 <kbd_proc_data+0x108>
f01002b1:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002b7:	75 2c                	jne    f01002e5 <kbd_proc_data+0x10c>
		cprintf("Rebooting!\n");
f01002b9:	83 ec 0c             	sub    $0xc,%esp
f01002bc:	68 04 18 10 f0       	push   $0xf0101804
f01002c1:	e8 e6 05 00 00       	call   f01008ac <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002c6:	ba 92 00 00 00       	mov    $0x92,%edx
f01002cb:	b0 03                	mov    $0x3,%al
f01002cd:	ee                   	out    %al,(%dx)
f01002ce:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002d1:	89 d8                	mov    %ebx,%eax
f01002d3:	eb 12                	jmp    f01002e7 <kbd_proc_data+0x10e>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01002d5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002da:	c3                   	ret    
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01002db:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002e0:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002e1:	89 d8                	mov    %ebx,%eax
f01002e3:	eb 02                	jmp    f01002e7 <kbd_proc_data+0x10e>
f01002e5:	89 d8                	mov    %ebx,%eax
}
f01002e7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002ea:	c9                   	leave  
f01002eb:	c3                   	ret    

f01002ec <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002ec:	55                   	push   %ebp
f01002ed:	89 e5                	mov    %esp,%ebp
f01002ef:	57                   	push   %edi
f01002f0:	56                   	push   %esi
f01002f1:	53                   	push   %ebx
f01002f2:	83 ec 1c             	sub    $0x1c,%esp
f01002f5:	89 c7                	mov    %eax,%edi
f01002f7:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002fc:	be fd 03 00 00       	mov    $0x3fd,%esi
f0100301:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100306:	eb 06                	jmp    f010030e <cons_putc+0x22>
f0100308:	89 ca                	mov    %ecx,%edx
f010030a:	ec                   	in     (%dx),%al
f010030b:	ec                   	in     (%dx),%al
f010030c:	ec                   	in     (%dx),%al
f010030d:	ec                   	in     (%dx),%al
f010030e:	89 f2                	mov    %esi,%edx
f0100310:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f0100311:	a8 20                	test   $0x20,%al
f0100313:	75 03                	jne    f0100318 <cons_putc+0x2c>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100315:	4b                   	dec    %ebx
f0100316:	75 f0                	jne    f0100308 <cons_putc+0x1c>
f0100318:	89 f8                	mov    %edi,%eax
f010031a:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010031d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100322:	ee                   	out    %al,(%dx)
f0100323:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100328:	be 79 03 00 00       	mov    $0x379,%esi
f010032d:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100332:	eb 06                	jmp    f010033a <cons_putc+0x4e>
f0100334:	89 ca                	mov    %ecx,%edx
f0100336:	ec                   	in     (%dx),%al
f0100337:	ec                   	in     (%dx),%al
f0100338:	ec                   	in     (%dx),%al
f0100339:	ec                   	in     (%dx),%al
f010033a:	89 f2                	mov    %esi,%edx
f010033c:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010033d:	84 c0                	test   %al,%al
f010033f:	78 03                	js     f0100344 <cons_putc+0x58>
f0100341:	4b                   	dec    %ebx
f0100342:	75 f0                	jne    f0100334 <cons_putc+0x48>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100344:	ba 78 03 00 00       	mov    $0x378,%edx
f0100349:	8a 45 e7             	mov    -0x19(%ebp),%al
f010034c:	ee                   	out    %al,(%dx)
f010034d:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100352:	b0 0d                	mov    $0xd,%al
f0100354:	ee                   	out    %al,(%dx)
f0100355:	b0 08                	mov    $0x8,%al
f0100357:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100358:	f7 c7 00 ff ff ff    	test   $0xffffff00,%edi
f010035e:	75 06                	jne    f0100366 <cons_putc+0x7a>
		c |= 0x0700;
f0100360:	81 cf 00 07 00 00    	or     $0x700,%edi

	switch (c & 0xff) {
f0100366:	89 f8                	mov    %edi,%eax
f0100368:	0f b6 c0             	movzbl %al,%eax
f010036b:	83 f8 09             	cmp    $0x9,%eax
f010036e:	74 75                	je     f01003e5 <cons_putc+0xf9>
f0100370:	83 f8 09             	cmp    $0x9,%eax
f0100373:	7f 0a                	jg     f010037f <cons_putc+0x93>
f0100375:	83 f8 08             	cmp    $0x8,%eax
f0100378:	74 14                	je     f010038e <cons_putc+0xa2>
f010037a:	e9 9a 00 00 00       	jmp    f0100419 <cons_putc+0x12d>
f010037f:	83 f8 0a             	cmp    $0xa,%eax
f0100382:	74 38                	je     f01003bc <cons_putc+0xd0>
f0100384:	83 f8 0d             	cmp    $0xd,%eax
f0100387:	74 3b                	je     f01003c4 <cons_putc+0xd8>
f0100389:	e9 8b 00 00 00       	jmp    f0100419 <cons_putc+0x12d>
	case '\b':
		if (crt_pos > 0) {
f010038e:	66 a1 28 15 11 f0    	mov    0xf0111528,%ax
f0100394:	66 85 c0             	test   %ax,%ax
f0100397:	0f 84 e7 00 00 00    	je     f0100484 <cons_putc+0x198>
			crt_pos--;
f010039d:	48                   	dec    %eax
f010039e:	66 a3 28 15 11 f0    	mov    %ax,0xf0111528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003a4:	0f b7 c0             	movzwl %ax,%eax
f01003a7:	81 e7 00 ff ff ff    	and    $0xffffff00,%edi
f01003ad:	83 cf 20             	or     $0x20,%edi
f01003b0:	8b 15 2c 15 11 f0    	mov    0xf011152c,%edx
f01003b6:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003ba:	eb 7a                	jmp    f0100436 <cons_putc+0x14a>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003bc:	66 83 05 28 15 11 f0 	addw   $0x50,0xf0111528
f01003c3:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003c4:	66 8b 0d 28 15 11 f0 	mov    0xf0111528,%cx
f01003cb:	bb 50 00 00 00       	mov    $0x50,%ebx
f01003d0:	89 c8                	mov    %ecx,%eax
f01003d2:	ba 00 00 00 00       	mov    $0x0,%edx
f01003d7:	66 f7 f3             	div    %bx
f01003da:	29 d1                	sub    %edx,%ecx
f01003dc:	66 89 0d 28 15 11 f0 	mov    %cx,0xf0111528
f01003e3:	eb 51                	jmp    f0100436 <cons_putc+0x14a>
		break;
	case '\t':
		cons_putc(' ');
f01003e5:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ea:	e8 fd fe ff ff       	call   f01002ec <cons_putc>
		cons_putc(' ');
f01003ef:	b8 20 00 00 00       	mov    $0x20,%eax
f01003f4:	e8 f3 fe ff ff       	call   f01002ec <cons_putc>
		cons_putc(' ');
f01003f9:	b8 20 00 00 00       	mov    $0x20,%eax
f01003fe:	e8 e9 fe ff ff       	call   f01002ec <cons_putc>
		cons_putc(' ');
f0100403:	b8 20 00 00 00       	mov    $0x20,%eax
f0100408:	e8 df fe ff ff       	call   f01002ec <cons_putc>
		cons_putc(' ');
f010040d:	b8 20 00 00 00       	mov    $0x20,%eax
f0100412:	e8 d5 fe ff ff       	call   f01002ec <cons_putc>
f0100417:	eb 1d                	jmp    f0100436 <cons_putc+0x14a>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100419:	66 a1 28 15 11 f0    	mov    0xf0111528,%ax
f010041f:	8d 50 01             	lea    0x1(%eax),%edx
f0100422:	66 89 15 28 15 11 f0 	mov    %dx,0xf0111528
f0100429:	0f b7 c0             	movzwl %ax,%eax
f010042c:	8b 15 2c 15 11 f0    	mov    0xf011152c,%edx
f0100432:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100436:	66 81 3d 28 15 11 f0 	cmpw   $0x7cf,0xf0111528
f010043d:	cf 07 
f010043f:	76 43                	jbe    f0100484 <cons_putc+0x198>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100441:	a1 2c 15 11 f0       	mov    0xf011152c,%eax
f0100446:	83 ec 04             	sub    $0x4,%esp
f0100449:	68 00 0f 00 00       	push   $0xf00
f010044e:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100454:	52                   	push   %edx
f0100455:	50                   	push   %eax
f0100456:	e8 f5 0e 00 00       	call   f0101350 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010045b:	8b 15 2c 15 11 f0    	mov    0xf011152c,%edx
f0100461:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100467:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010046d:	83 c4 10             	add    $0x10,%esp
f0100470:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100475:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100478:	39 d0                	cmp    %edx,%eax
f010047a:	75 f4                	jne    f0100470 <cons_putc+0x184>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010047c:	66 83 2d 28 15 11 f0 	subw   $0x50,0xf0111528
f0100483:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100484:	8b 0d 30 15 11 f0    	mov    0xf0111530,%ecx
f010048a:	b0 0e                	mov    $0xe,%al
f010048c:	89 ca                	mov    %ecx,%edx
f010048e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010048f:	8d 59 01             	lea    0x1(%ecx),%ebx
f0100492:	66 a1 28 15 11 f0    	mov    0xf0111528,%ax
f0100498:	66 c1 e8 08          	shr    $0x8,%ax
f010049c:	89 da                	mov    %ebx,%edx
f010049e:	ee                   	out    %al,(%dx)
f010049f:	b0 0f                	mov    $0xf,%al
f01004a1:	89 ca                	mov    %ecx,%edx
f01004a3:	ee                   	out    %al,(%dx)
f01004a4:	a0 28 15 11 f0       	mov    0xf0111528,%al
f01004a9:	89 da                	mov    %ebx,%edx
f01004ab:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004ac:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004af:	5b                   	pop    %ebx
f01004b0:	5e                   	pop    %esi
f01004b1:	5f                   	pop    %edi
f01004b2:	5d                   	pop    %ebp
f01004b3:	c3                   	ret    

f01004b4 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004b4:	80 3d 34 15 11 f0 00 	cmpb   $0x0,0xf0111534
f01004bb:	74 11                	je     f01004ce <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004bd:	55                   	push   %ebp
f01004be:	89 e5                	mov    %esp,%ebp
f01004c0:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004c3:	b8 77 01 10 f0       	mov    $0xf0100177,%eax
f01004c8:	e8 c9 fc ff ff       	call   f0100196 <cons_intr>
}
f01004cd:	c9                   	leave  
f01004ce:	c3                   	ret    

f01004cf <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004cf:	55                   	push   %ebp
f01004d0:	89 e5                	mov    %esp,%ebp
f01004d2:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004d5:	b8 d9 01 10 f0       	mov    $0xf01001d9,%eax
f01004da:	e8 b7 fc ff ff       	call   f0100196 <cons_intr>
}
f01004df:	c9                   	leave  
f01004e0:	c3                   	ret    

f01004e1 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004e1:	55                   	push   %ebp
f01004e2:	89 e5                	mov    %esp,%ebp
f01004e4:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004e7:	e8 c8 ff ff ff       	call   f01004b4 <serial_intr>
	kbd_intr();
f01004ec:	e8 de ff ff ff       	call   f01004cf <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004f1:	a1 20 15 11 f0       	mov    0xf0111520,%eax
f01004f6:	3b 05 24 15 11 f0    	cmp    0xf0111524,%eax
f01004fc:	74 24                	je     f0100522 <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f01004fe:	8d 50 01             	lea    0x1(%eax),%edx
f0100501:	89 15 20 15 11 f0    	mov    %edx,0xf0111520
f0100507:	0f b6 80 20 13 11 f0 	movzbl -0xfeeece0(%eax),%eax
		if (cons.rpos == CONSBUFSIZE)
f010050e:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100514:	75 11                	jne    f0100527 <cons_getc+0x46>
			cons.rpos = 0;
f0100516:	c7 05 20 15 11 f0 00 	movl   $0x0,0xf0111520
f010051d:	00 00 00 
f0100520:	eb 05                	jmp    f0100527 <cons_getc+0x46>
		return c;
	}
	return 0;
f0100522:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100527:	c9                   	leave  
f0100528:	c3                   	ret    

f0100529 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100529:	55                   	push   %ebp
f010052a:	89 e5                	mov    %esp,%ebp
f010052c:	56                   	push   %esi
f010052d:	53                   	push   %ebx
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010052e:	66 8b 15 00 80 0b f0 	mov    0xf00b8000,%dx
	*cp = (uint16_t) 0xA55A;
f0100535:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010053c:	5a a5 
	if (*cp != 0xA55A) {
f010053e:	66 a1 00 80 0b f0    	mov    0xf00b8000,%ax
f0100544:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100548:	74 11                	je     f010055b <cons_init+0x32>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010054a:	c7 05 30 15 11 f0 b4 	movl   $0x3b4,0xf0111530
f0100551:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100554:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100559:	eb 16                	jmp    f0100571 <cons_init+0x48>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010055b:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100562:	c7 05 30 15 11 f0 d4 	movl   $0x3d4,0xf0111530
f0100569:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010056c:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
f0100571:	b0 0e                	mov    $0xe,%al
f0100573:	8b 15 30 15 11 f0    	mov    0xf0111530,%edx
f0100579:	ee                   	out    %al,(%dx)
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
f010057a:	8d 5a 01             	lea    0x1(%edx),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010057d:	89 da                	mov    %ebx,%edx
f010057f:	ec                   	in     (%dx),%al
f0100580:	0f b6 c8             	movzbl %al,%ecx
f0100583:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100586:	b0 0f                	mov    $0xf,%al
f0100588:	8b 15 30 15 11 f0    	mov    0xf0111530,%edx
f010058e:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010058f:	89 da                	mov    %ebx,%edx
f0100591:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100592:	89 35 2c 15 11 f0    	mov    %esi,0xf011152c
	crt_pos = pos;
f0100598:	0f b6 c0             	movzbl %al,%eax
f010059b:	09 c8                	or     %ecx,%eax
f010059d:	66 a3 28 15 11 f0    	mov    %ax,0xf0111528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005a3:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005a8:	b0 00                	mov    $0x0,%al
f01005aa:	89 f2                	mov    %esi,%edx
f01005ac:	ee                   	out    %al,(%dx)
f01005ad:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005b2:	b0 80                	mov    $0x80,%al
f01005b4:	ee                   	out    %al,(%dx)
f01005b5:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005ba:	b0 0c                	mov    $0xc,%al
f01005bc:	89 da                	mov    %ebx,%edx
f01005be:	ee                   	out    %al,(%dx)
f01005bf:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005c4:	b0 00                	mov    $0x0,%al
f01005c6:	ee                   	out    %al,(%dx)
f01005c7:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005cc:	b0 03                	mov    $0x3,%al
f01005ce:	ee                   	out    %al,(%dx)
f01005cf:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005d4:	b0 00                	mov    $0x0,%al
f01005d6:	ee                   	out    %al,(%dx)
f01005d7:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005dc:	b0 01                	mov    $0x1,%al
f01005de:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005df:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005e4:	ec                   	in     (%dx),%al
f01005e5:	88 c1                	mov    %al,%cl
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005e7:	3c ff                	cmp    $0xff,%al
f01005e9:	0f 95 05 34 15 11 f0 	setne  0xf0111534
f01005f0:	89 f2                	mov    %esi,%edx
f01005f2:	ec                   	in     (%dx),%al
f01005f3:	89 da                	mov    %ebx,%edx
f01005f5:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005f6:	80 f9 ff             	cmp    $0xff,%cl
f01005f9:	75 10                	jne    f010060b <cons_init+0xe2>
		cprintf("Serial port does not exist!\n");
f01005fb:	83 ec 0c             	sub    $0xc,%esp
f01005fe:	68 10 18 10 f0       	push   $0xf0101810
f0100603:	e8 a4 02 00 00       	call   f01008ac <cprintf>
f0100608:	83 c4 10             	add    $0x10,%esp
}
f010060b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010060e:	5b                   	pop    %ebx
f010060f:	5e                   	pop    %esi
f0100610:	5d                   	pop    %ebp
f0100611:	c3                   	ret    

f0100612 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100612:	55                   	push   %ebp
f0100613:	89 e5                	mov    %esp,%ebp
f0100615:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100618:	8b 45 08             	mov    0x8(%ebp),%eax
f010061b:	e8 cc fc ff ff       	call   f01002ec <cons_putc>
}
f0100620:	c9                   	leave  
f0100621:	c3                   	ret    

f0100622 <getchar>:

int
getchar(void)
{
f0100622:	55                   	push   %ebp
f0100623:	89 e5                	mov    %esp,%ebp
f0100625:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100628:	e8 b4 fe ff ff       	call   f01004e1 <cons_getc>
f010062d:	85 c0                	test   %eax,%eax
f010062f:	74 f7                	je     f0100628 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100631:	c9                   	leave  
f0100632:	c3                   	ret    

f0100633 <iscons>:

int
iscons(int fdnum)
{
f0100633:	55                   	push   %ebp
f0100634:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100636:	b8 01 00 00 00       	mov    $0x1,%eax
f010063b:	5d                   	pop    %ebp
f010063c:	c3                   	ret    

f010063d <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010063d:	55                   	push   %ebp
f010063e:	89 e5                	mov    %esp,%ebp
f0100640:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100643:	68 60 1a 10 f0       	push   $0xf0101a60
f0100648:	68 7e 1a 10 f0       	push   $0xf0101a7e
f010064d:	68 83 1a 10 f0       	push   $0xf0101a83
f0100652:	e8 55 02 00 00       	call   f01008ac <cprintf>
f0100657:	83 c4 0c             	add    $0xc,%esp
f010065a:	68 ec 1a 10 f0       	push   $0xf0101aec
f010065f:	68 8c 1a 10 f0       	push   $0xf0101a8c
f0100664:	68 83 1a 10 f0       	push   $0xf0101a83
f0100669:	e8 3e 02 00 00       	call   f01008ac <cprintf>
	return 0;
}
f010066e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100673:	c9                   	leave  
f0100674:	c3                   	ret    

f0100675 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100675:	55                   	push   %ebp
f0100676:	89 e5                	mov    %esp,%ebp
f0100678:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f010067b:	68 95 1a 10 f0       	push   $0xf0101a95
f0100680:	e8 27 02 00 00       	call   f01008ac <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100685:	83 c4 08             	add    $0x8,%esp
f0100688:	68 0c 00 10 00       	push   $0x10000c
f010068d:	68 14 1b 10 f0       	push   $0xf0101b14
f0100692:	e8 15 02 00 00       	call   f01008ac <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100697:	83 c4 0c             	add    $0xc,%esp
f010069a:	68 0c 00 10 00       	push   $0x10000c
f010069f:	68 0c 00 10 f0       	push   $0xf010000c
f01006a4:	68 3c 1b 10 f0       	push   $0xf0101b3c
f01006a9:	e8 fe 01 00 00       	call   f01008ac <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006ae:	83 c4 0c             	add    $0xc,%esp
f01006b1:	68 65 17 10 00       	push   $0x101765
f01006b6:	68 65 17 10 f0       	push   $0xf0101765
f01006bb:	68 60 1b 10 f0       	push   $0xf0101b60
f01006c0:	e8 e7 01 00 00       	call   f01008ac <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006c5:	83 c4 0c             	add    $0xc,%esp
f01006c8:	68 00 13 11 00       	push   $0x111300
f01006cd:	68 00 13 11 f0       	push   $0xf0111300
f01006d2:	68 84 1b 10 f0       	push   $0xf0101b84
f01006d7:	e8 d0 01 00 00       	call   f01008ac <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006dc:	83 c4 0c             	add    $0xc,%esp
f01006df:	68 44 19 11 00       	push   $0x111944
f01006e4:	68 44 19 11 f0       	push   $0xf0111944
f01006e9:	68 a8 1b 10 f0       	push   $0xf0101ba8
f01006ee:	e8 b9 01 00 00       	call   f01008ac <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006f3:	b8 43 1d 11 f0       	mov    $0xf0111d43,%eax
f01006f8:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006fd:	83 c4 08             	add    $0x8,%esp
f0100700:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100705:	89 c2                	mov    %eax,%edx
f0100707:	85 c0                	test   %eax,%eax
f0100709:	79 06                	jns    f0100711 <mon_kerninfo+0x9c>
f010070b:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100711:	c1 fa 0a             	sar    $0xa,%edx
f0100714:	52                   	push   %edx
f0100715:	68 cc 1b 10 f0       	push   $0xf0101bcc
f010071a:	e8 8d 01 00 00       	call   f01008ac <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010071f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100724:	c9                   	leave  
f0100725:	c3                   	ret    

f0100726 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100726:	55                   	push   %ebp
f0100727:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f0100729:	b8 00 00 00 00       	mov    $0x0,%eax
f010072e:	5d                   	pop    %ebp
f010072f:	c3                   	ret    

f0100730 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100730:	55                   	push   %ebp
f0100731:	89 e5                	mov    %esp,%ebp
f0100733:	57                   	push   %edi
f0100734:	56                   	push   %esi
f0100735:	53                   	push   %ebx
f0100736:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100739:	68 f8 1b 10 f0       	push   $0xf0101bf8
f010073e:	e8 69 01 00 00       	call   f01008ac <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100743:	c7 04 24 1c 1c 10 f0 	movl   $0xf0101c1c,(%esp)
f010074a:	e8 5d 01 00 00       	call   f01008ac <cprintf>
f010074f:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100752:	83 ec 0c             	sub    $0xc,%esp
f0100755:	68 ae 1a 10 f0       	push   $0xf0101aae
f010075a:	e8 57 09 00 00       	call   f01010b6 <readline>
f010075f:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100761:	83 c4 10             	add    $0x10,%esp
f0100764:	85 c0                	test   %eax,%eax
f0100766:	74 ea                	je     f0100752 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100768:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010076f:	be 00 00 00 00       	mov    $0x0,%esi
f0100774:	eb 0a                	jmp    f0100780 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100776:	c6 03 00             	movb   $0x0,(%ebx)
f0100779:	89 f7                	mov    %esi,%edi
f010077b:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010077e:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100780:	8a 03                	mov    (%ebx),%al
f0100782:	84 c0                	test   %al,%al
f0100784:	74 60                	je     f01007e6 <monitor+0xb6>
f0100786:	83 ec 08             	sub    $0x8,%esp
f0100789:	0f be c0             	movsbl %al,%eax
f010078c:	50                   	push   %eax
f010078d:	68 b2 1a 10 f0       	push   $0xf0101ab2
f0100792:	e8 37 0b 00 00       	call   f01012ce <strchr>
f0100797:	83 c4 10             	add    $0x10,%esp
f010079a:	85 c0                	test   %eax,%eax
f010079c:	75 d8                	jne    f0100776 <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f010079e:	80 3b 00             	cmpb   $0x0,(%ebx)
f01007a1:	74 43                	je     f01007e6 <monitor+0xb6>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01007a3:	83 fe 0f             	cmp    $0xf,%esi
f01007a6:	75 14                	jne    f01007bc <monitor+0x8c>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01007a8:	83 ec 08             	sub    $0x8,%esp
f01007ab:	6a 10                	push   $0x10
f01007ad:	68 b7 1a 10 f0       	push   $0xf0101ab7
f01007b2:	e8 f5 00 00 00       	call   f01008ac <cprintf>
f01007b7:	83 c4 10             	add    $0x10,%esp
f01007ba:	eb 96                	jmp    f0100752 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f01007bc:	8d 7e 01             	lea    0x1(%esi),%edi
f01007bf:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01007c3:	eb 01                	jmp    f01007c6 <monitor+0x96>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01007c5:	43                   	inc    %ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01007c6:	8a 03                	mov    (%ebx),%al
f01007c8:	84 c0                	test   %al,%al
f01007ca:	74 b2                	je     f010077e <monitor+0x4e>
f01007cc:	83 ec 08             	sub    $0x8,%esp
f01007cf:	0f be c0             	movsbl %al,%eax
f01007d2:	50                   	push   %eax
f01007d3:	68 b2 1a 10 f0       	push   $0xf0101ab2
f01007d8:	e8 f1 0a 00 00       	call   f01012ce <strchr>
f01007dd:	83 c4 10             	add    $0x10,%esp
f01007e0:	85 c0                	test   %eax,%eax
f01007e2:	74 e1                	je     f01007c5 <monitor+0x95>
f01007e4:	eb 98                	jmp    f010077e <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f01007e6:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01007ed:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01007ee:	85 f6                	test   %esi,%esi
f01007f0:	0f 84 5c ff ff ff    	je     f0100752 <monitor+0x22>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01007f6:	83 ec 08             	sub    $0x8,%esp
f01007f9:	68 7e 1a 10 f0       	push   $0xf0101a7e
f01007fe:	ff 75 a8             	pushl  -0x58(%ebp)
f0100801:	e8 74 0a 00 00       	call   f010127a <strcmp>
f0100806:	83 c4 10             	add    $0x10,%esp
f0100809:	85 c0                	test   %eax,%eax
f010080b:	74 1e                	je     f010082b <monitor+0xfb>
f010080d:	83 ec 08             	sub    $0x8,%esp
f0100810:	68 8c 1a 10 f0       	push   $0xf0101a8c
f0100815:	ff 75 a8             	pushl  -0x58(%ebp)
f0100818:	e8 5d 0a 00 00       	call   f010127a <strcmp>
f010081d:	83 c4 10             	add    $0x10,%esp
f0100820:	85 c0                	test   %eax,%eax
f0100822:	75 2f                	jne    f0100853 <monitor+0x123>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100824:	b8 01 00 00 00       	mov    $0x1,%eax
f0100829:	eb 05                	jmp    f0100830 <monitor+0x100>
		if (strcmp(argv[0], commands[i].name) == 0)
f010082b:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f0100830:	83 ec 04             	sub    $0x4,%esp
f0100833:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100836:	01 d0                	add    %edx,%eax
f0100838:	ff 75 08             	pushl  0x8(%ebp)
f010083b:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f010083e:	51                   	push   %ecx
f010083f:	56                   	push   %esi
f0100840:	ff 14 85 4c 1c 10 f0 	call   *-0xfefe3b4(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100847:	83 c4 10             	add    $0x10,%esp
f010084a:	85 c0                	test   %eax,%eax
f010084c:	78 1d                	js     f010086b <monitor+0x13b>
f010084e:	e9 ff fe ff ff       	jmp    f0100752 <monitor+0x22>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100853:	83 ec 08             	sub    $0x8,%esp
f0100856:	ff 75 a8             	pushl  -0x58(%ebp)
f0100859:	68 d4 1a 10 f0       	push   $0xf0101ad4
f010085e:	e8 49 00 00 00       	call   f01008ac <cprintf>
f0100863:	83 c4 10             	add    $0x10,%esp
f0100866:	e9 e7 fe ff ff       	jmp    f0100752 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f010086b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010086e:	5b                   	pop    %ebx
f010086f:	5e                   	pop    %esi
f0100870:	5f                   	pop    %edi
f0100871:	5d                   	pop    %ebp
f0100872:	c3                   	ret    

f0100873 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100873:	55                   	push   %ebp
f0100874:	89 e5                	mov    %esp,%ebp
f0100876:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0100879:	ff 75 08             	pushl  0x8(%ebp)
f010087c:	e8 91 fd ff ff       	call   f0100612 <cputchar>
	*cnt++;
}
f0100881:	83 c4 10             	add    $0x10,%esp
f0100884:	c9                   	leave  
f0100885:	c3                   	ret    

f0100886 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100886:	55                   	push   %ebp
f0100887:	89 e5                	mov    %esp,%ebp
f0100889:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010088c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100893:	ff 75 0c             	pushl  0xc(%ebp)
f0100896:	ff 75 08             	pushl  0x8(%ebp)
f0100899:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010089c:	50                   	push   %eax
f010089d:	68 73 08 10 f0       	push   $0xf0100873
f01008a2:	e8 14 04 00 00       	call   f0100cbb <vprintfmt>
	return cnt;
}
f01008a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01008aa:	c9                   	leave  
f01008ab:	c3                   	ret    

f01008ac <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01008ac:	55                   	push   %ebp
f01008ad:	89 e5                	mov    %esp,%ebp
f01008af:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01008b2:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01008b5:	50                   	push   %eax
f01008b6:	ff 75 08             	pushl  0x8(%ebp)
f01008b9:	e8 c8 ff ff ff       	call   f0100886 <vcprintf>
	va_end(ap);

	return cnt;
}
f01008be:	c9                   	leave  
f01008bf:	c3                   	ret    

f01008c0 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01008c0:	55                   	push   %ebp
f01008c1:	89 e5                	mov    %esp,%ebp
f01008c3:	57                   	push   %edi
f01008c4:	56                   	push   %esi
f01008c5:	53                   	push   %ebx
f01008c6:	83 ec 14             	sub    $0x14,%esp
f01008c9:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01008cc:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01008cf:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01008d2:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01008d5:	8b 1a                	mov    (%edx),%ebx
f01008d7:	8b 01                	mov    (%ecx),%eax
f01008d9:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01008dc:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01008e3:	eb 7e                	jmp    f0100963 <stab_binsearch+0xa3>
		int true_m = (l + r) / 2, m = true_m;
f01008e5:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01008e8:	01 d8                	add    %ebx,%eax
f01008ea:	89 c6                	mov    %eax,%esi
f01008ec:	c1 ee 1f             	shr    $0x1f,%esi
f01008ef:	01 c6                	add    %eax,%esi
f01008f1:	d1 fe                	sar    %esi
f01008f3:	8d 04 36             	lea    (%esi,%esi,1),%eax
f01008f6:	01 f0                	add    %esi,%eax
f01008f8:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01008fb:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f01008ff:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100901:	eb 01                	jmp    f0100904 <stab_binsearch+0x44>
			m--;
f0100903:	48                   	dec    %eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100904:	39 c3                	cmp    %eax,%ebx
f0100906:	7f 0c                	jg     f0100914 <stab_binsearch+0x54>
f0100908:	0f b6 0a             	movzbl (%edx),%ecx
f010090b:	83 ea 0c             	sub    $0xc,%edx
f010090e:	39 f9                	cmp    %edi,%ecx
f0100910:	75 f1                	jne    f0100903 <stab_binsearch+0x43>
f0100912:	eb 05                	jmp    f0100919 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100914:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0100917:	eb 4a                	jmp    f0100963 <stab_binsearch+0xa3>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100919:	8d 14 00             	lea    (%eax,%eax,1),%edx
f010091c:	01 c2                	add    %eax,%edx
f010091e:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100921:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100925:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100928:	76 11                	jbe    f010093b <stab_binsearch+0x7b>
			*region_left = m;
f010092a:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010092d:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010092f:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100932:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100939:	eb 28                	jmp    f0100963 <stab_binsearch+0xa3>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010093b:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010093e:	73 12                	jae    f0100952 <stab_binsearch+0x92>
			*region_right = m - 1;
f0100940:	48                   	dec    %eax
f0100941:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100944:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100947:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100949:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100950:	eb 11                	jmp    f0100963 <stab_binsearch+0xa3>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100952:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100955:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100957:	ff 45 0c             	incl   0xc(%ebp)
f010095a:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010095c:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100963:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100966:	0f 8e 79 ff ff ff    	jle    f01008e5 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010096c:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100970:	75 0d                	jne    f010097f <stab_binsearch+0xbf>
		*region_right = *region_left - 1;
f0100972:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100975:	8b 00                	mov    (%eax),%eax
f0100977:	48                   	dec    %eax
f0100978:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010097b:	89 07                	mov    %eax,(%edi)
f010097d:	eb 2c                	jmp    f01009ab <stab_binsearch+0xeb>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010097f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100982:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100984:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100987:	8b 0e                	mov    (%esi),%ecx
f0100989:	8d 14 00             	lea    (%eax,%eax,1),%edx
f010098c:	01 c2                	add    %eax,%edx
f010098e:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100991:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100995:	eb 01                	jmp    f0100998 <stab_binsearch+0xd8>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100997:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100998:	39 c8                	cmp    %ecx,%eax
f010099a:	7e 0a                	jle    f01009a6 <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
f010099c:	0f b6 1a             	movzbl (%edx),%ebx
f010099f:	83 ea 0c             	sub    $0xc,%edx
f01009a2:	39 df                	cmp    %ebx,%edi
f01009a4:	75 f1                	jne    f0100997 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01009a6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01009a9:	89 07                	mov    %eax,(%edi)
	}
}
f01009ab:	83 c4 14             	add    $0x14,%esp
f01009ae:	5b                   	pop    %ebx
f01009af:	5e                   	pop    %esi
f01009b0:	5f                   	pop    %edi
f01009b1:	5d                   	pop    %ebp
f01009b2:	c3                   	ret    

f01009b3 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01009b3:	55                   	push   %ebp
f01009b4:	89 e5                	mov    %esp,%ebp
f01009b6:	57                   	push   %edi
f01009b7:	56                   	push   %esi
f01009b8:	53                   	push   %ebx
f01009b9:	83 ec 1c             	sub    $0x1c,%esp
f01009bc:	8b 7d 08             	mov    0x8(%ebp),%edi
f01009bf:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01009c2:	c7 06 5c 1c 10 f0    	movl   $0xf0101c5c,(%esi)
	info->eip_line = 0;
f01009c8:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f01009cf:	c7 46 08 5c 1c 10 f0 	movl   $0xf0101c5c,0x8(%esi)
	info->eip_fn_namelen = 9;
f01009d6:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f01009dd:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f01009e0:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01009e7:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f01009ed:	76 11                	jbe    f0100a00 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01009ef:	b8 c6 6d 10 f0       	mov    $0xf0106dc6,%eax
f01009f4:	3d 3d 55 10 f0       	cmp    $0xf010553d,%eax
f01009f9:	77 19                	ja     f0100a14 <debuginfo_eip+0x61>
f01009fb:	e9 72 01 00 00       	jmp    f0100b72 <debuginfo_eip+0x1bf>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100a00:	83 ec 04             	sub    $0x4,%esp
f0100a03:	68 66 1c 10 f0       	push   $0xf0101c66
f0100a08:	6a 7f                	push   $0x7f
f0100a0a:	68 73 1c 10 f0       	push   $0xf0101c73
f0100a0f:	e8 d2 f6 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a14:	80 3d c5 6d 10 f0 00 	cmpb   $0x0,0xf0106dc5
f0100a1b:	0f 85 58 01 00 00    	jne    f0100b79 <debuginfo_eip+0x1c6>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100a21:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100a28:	b8 3c 55 10 f0       	mov    $0xf010553c,%eax
f0100a2d:	2d 94 1e 10 f0       	sub    $0xf0101e94,%eax
f0100a32:	c1 f8 02             	sar    $0x2,%eax
f0100a35:	8d 14 80             	lea    (%eax,%eax,4),%edx
f0100a38:	8d 14 90             	lea    (%eax,%edx,4),%edx
f0100a3b:	8d 0c 90             	lea    (%eax,%edx,4),%ecx
f0100a3e:	89 ca                	mov    %ecx,%edx
f0100a40:	c1 e2 08             	shl    $0x8,%edx
f0100a43:	01 d1                	add    %edx,%ecx
f0100a45:	89 ca                	mov    %ecx,%edx
f0100a47:	c1 e2 10             	shl    $0x10,%edx
f0100a4a:	01 ca                	add    %ecx,%edx
f0100a4c:	01 d2                	add    %edx,%edx
f0100a4e:	8d 44 10 ff          	lea    -0x1(%eax,%edx,1),%eax
f0100a52:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100a55:	83 ec 08             	sub    $0x8,%esp
f0100a58:	57                   	push   %edi
f0100a59:	6a 64                	push   $0x64
f0100a5b:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100a5e:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100a61:	b8 94 1e 10 f0       	mov    $0xf0101e94,%eax
f0100a66:	e8 55 fe ff ff       	call   f01008c0 <stab_binsearch>
	if (lfile == 0)
f0100a6b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a6e:	83 c4 10             	add    $0x10,%esp
f0100a71:	85 c0                	test   %eax,%eax
f0100a73:	0f 84 07 01 00 00    	je     f0100b80 <debuginfo_eip+0x1cd>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100a79:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100a7c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a7f:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100a82:	83 ec 08             	sub    $0x8,%esp
f0100a85:	57                   	push   %edi
f0100a86:	6a 24                	push   $0x24
f0100a88:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100a8b:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100a8e:	b8 94 1e 10 f0       	mov    $0xf0101e94,%eax
f0100a93:	e8 28 fe ff ff       	call   f01008c0 <stab_binsearch>

	if (lfun <= rfun) {
f0100a98:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100a9b:	83 c4 10             	add    $0x10,%esp
f0100a9e:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0100aa1:	7f 33                	jg     f0100ad6 <debuginfo_eip+0x123>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100aa3:	8d 04 1b             	lea    (%ebx,%ebx,1),%eax
f0100aa6:	01 d8                	add    %ebx,%eax
f0100aa8:	c1 e0 02             	shl    $0x2,%eax
f0100aab:	8d 90 94 1e 10 f0    	lea    -0xfefe16c(%eax),%edx
f0100ab1:	8b 88 94 1e 10 f0    	mov    -0xfefe16c(%eax),%ecx
f0100ab7:	b8 c6 6d 10 f0       	mov    $0xf0106dc6,%eax
f0100abc:	2d 3d 55 10 f0       	sub    $0xf010553d,%eax
f0100ac1:	39 c1                	cmp    %eax,%ecx
f0100ac3:	73 09                	jae    f0100ace <debuginfo_eip+0x11b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100ac5:	81 c1 3d 55 10 f0    	add    $0xf010553d,%ecx
f0100acb:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100ace:	8b 42 08             	mov    0x8(%edx),%eax
f0100ad1:	89 46 10             	mov    %eax,0x10(%esi)
f0100ad4:	eb 06                	jmp    f0100adc <debuginfo_eip+0x129>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100ad6:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0100ad9:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100adc:	83 ec 08             	sub    $0x8,%esp
f0100adf:	6a 3a                	push   $0x3a
f0100ae1:	ff 76 08             	pushl  0x8(%esi)
f0100ae4:	e8 02 08 00 00       	call   f01012eb <strfind>
f0100ae9:	2b 46 08             	sub    0x8(%esi),%eax
f0100aec:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100aef:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100af2:	8d 04 1b             	lea    (%ebx,%ebx,1),%eax
f0100af5:	01 d8                	add    %ebx,%eax
f0100af7:	8d 04 85 9c 1e 10 f0 	lea    -0xfefe164(,%eax,4),%eax
f0100afe:	83 c4 10             	add    $0x10,%esp
f0100b01:	eb 04                	jmp    f0100b07 <debuginfo_eip+0x154>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100b03:	4b                   	dec    %ebx
f0100b04:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b07:	39 fb                	cmp    %edi,%ebx
f0100b09:	7c 34                	jl     f0100b3f <debuginfo_eip+0x18c>
	       && stabs[lline].n_type != N_SOL
f0100b0b:	8a 50 fc             	mov    -0x4(%eax),%dl
f0100b0e:	80 fa 84             	cmp    $0x84,%dl
f0100b11:	74 0a                	je     f0100b1d <debuginfo_eip+0x16a>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100b13:	80 fa 64             	cmp    $0x64,%dl
f0100b16:	75 eb                	jne    f0100b03 <debuginfo_eip+0x150>
f0100b18:	83 38 00             	cmpl   $0x0,(%eax)
f0100b1b:	74 e6                	je     f0100b03 <debuginfo_eip+0x150>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100b1d:	8d 04 1b             	lea    (%ebx,%ebx,1),%eax
f0100b20:	01 c3                	add    %eax,%ebx
f0100b22:	8b 14 9d 94 1e 10 f0 	mov    -0xfefe16c(,%ebx,4),%edx
f0100b29:	b8 c6 6d 10 f0       	mov    $0xf0106dc6,%eax
f0100b2e:	2d 3d 55 10 f0       	sub    $0xf010553d,%eax
f0100b33:	39 c2                	cmp    %eax,%edx
f0100b35:	73 08                	jae    f0100b3f <debuginfo_eip+0x18c>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100b37:	81 c2 3d 55 10 f0    	add    $0xf010553d,%edx
f0100b3d:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100b3f:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100b42:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0100b45:	39 c8                	cmp    %ecx,%eax
f0100b47:	7d 3e                	jge    f0100b87 <debuginfo_eip+0x1d4>
		for (lline = lfun + 1;
f0100b49:	8d 50 01             	lea    0x1(%eax),%edx
f0100b4c:	8d 1c 00             	lea    (%eax,%eax,1),%ebx
f0100b4f:	01 d8                	add    %ebx,%eax
f0100b51:	8d 04 85 a4 1e 10 f0 	lea    -0xfefe15c(,%eax,4),%eax
f0100b58:	eb 04                	jmp    f0100b5e <debuginfo_eip+0x1ab>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100b5a:	ff 46 14             	incl   0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100b5d:	42                   	inc    %edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100b5e:	39 ca                	cmp    %ecx,%edx
f0100b60:	74 2c                	je     f0100b8e <debuginfo_eip+0x1db>
f0100b62:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100b65:	80 78 f4 a0          	cmpb   $0xa0,-0xc(%eax)
f0100b69:	74 ef                	je     f0100b5a <debuginfo_eip+0x1a7>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100b6b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b70:	eb 21                	jmp    f0100b93 <debuginfo_eip+0x1e0>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100b72:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100b77:	eb 1a                	jmp    f0100b93 <debuginfo_eip+0x1e0>
f0100b79:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100b7e:	eb 13                	jmp    f0100b93 <debuginfo_eip+0x1e0>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100b80:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100b85:	eb 0c                	jmp    f0100b93 <debuginfo_eip+0x1e0>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100b87:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b8c:	eb 05                	jmp    f0100b93 <debuginfo_eip+0x1e0>
f0100b8e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100b93:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100b96:	5b                   	pop    %ebx
f0100b97:	5e                   	pop    %esi
f0100b98:	5f                   	pop    %edi
f0100b99:	5d                   	pop    %ebp
f0100b9a:	c3                   	ret    

f0100b9b <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100b9b:	55                   	push   %ebp
f0100b9c:	89 e5                	mov    %esp,%ebp
f0100b9e:	57                   	push   %edi
f0100b9f:	56                   	push   %esi
f0100ba0:	53                   	push   %ebx
f0100ba1:	83 ec 1c             	sub    $0x1c,%esp
f0100ba4:	89 c7                	mov    %eax,%edi
f0100ba6:	89 d6                	mov    %edx,%esi
f0100ba8:	8b 45 08             	mov    0x8(%ebp),%eax
f0100bab:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100bae:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100bb1:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100bb4:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100bb7:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100bbc:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100bbf:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100bc2:	39 d3                	cmp    %edx,%ebx
f0100bc4:	72 05                	jb     f0100bcb <printnum+0x30>
f0100bc6:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100bc9:	77 45                	ja     f0100c10 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100bcb:	83 ec 0c             	sub    $0xc,%esp
f0100bce:	ff 75 18             	pushl  0x18(%ebp)
f0100bd1:	8b 45 14             	mov    0x14(%ebp),%eax
f0100bd4:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100bd7:	53                   	push   %ebx
f0100bd8:	ff 75 10             	pushl  0x10(%ebp)
f0100bdb:	83 ec 08             	sub    $0x8,%esp
f0100bde:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100be1:	ff 75 e0             	pushl  -0x20(%ebp)
f0100be4:	ff 75 dc             	pushl  -0x24(%ebp)
f0100be7:	ff 75 d8             	pushl  -0x28(%ebp)
f0100bea:	e8 15 09 00 00       	call   f0101504 <__udivdi3>
f0100bef:	83 c4 18             	add    $0x18,%esp
f0100bf2:	52                   	push   %edx
f0100bf3:	50                   	push   %eax
f0100bf4:	89 f2                	mov    %esi,%edx
f0100bf6:	89 f8                	mov    %edi,%eax
f0100bf8:	e8 9e ff ff ff       	call   f0100b9b <printnum>
f0100bfd:	83 c4 20             	add    $0x20,%esp
f0100c00:	eb 16                	jmp    f0100c18 <printnum+0x7d>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100c02:	83 ec 08             	sub    $0x8,%esp
f0100c05:	56                   	push   %esi
f0100c06:	ff 75 18             	pushl  0x18(%ebp)
f0100c09:	ff d7                	call   *%edi
f0100c0b:	83 c4 10             	add    $0x10,%esp
f0100c0e:	eb 03                	jmp    f0100c13 <printnum+0x78>
f0100c10:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100c13:	4b                   	dec    %ebx
f0100c14:	85 db                	test   %ebx,%ebx
f0100c16:	7f ea                	jg     f0100c02 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100c18:	83 ec 08             	sub    $0x8,%esp
f0100c1b:	56                   	push   %esi
f0100c1c:	83 ec 04             	sub    $0x4,%esp
f0100c1f:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100c22:	ff 75 e0             	pushl  -0x20(%ebp)
f0100c25:	ff 75 dc             	pushl  -0x24(%ebp)
f0100c28:	ff 75 d8             	pushl  -0x28(%ebp)
f0100c2b:	e8 e4 09 00 00       	call   f0101614 <__umoddi3>
f0100c30:	83 c4 14             	add    $0x14,%esp
f0100c33:	0f be 80 81 1c 10 f0 	movsbl -0xfefe37f(%eax),%eax
f0100c3a:	50                   	push   %eax
f0100c3b:	ff d7                	call   *%edi
}
f0100c3d:	83 c4 10             	add    $0x10,%esp
f0100c40:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c43:	5b                   	pop    %ebx
f0100c44:	5e                   	pop    %esi
f0100c45:	5f                   	pop    %edi
f0100c46:	5d                   	pop    %ebp
f0100c47:	c3                   	ret    

f0100c48 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100c48:	55                   	push   %ebp
f0100c49:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100c4b:	83 fa 01             	cmp    $0x1,%edx
f0100c4e:	7e 0e                	jle    f0100c5e <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100c50:	8b 10                	mov    (%eax),%edx
f0100c52:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100c55:	89 08                	mov    %ecx,(%eax)
f0100c57:	8b 02                	mov    (%edx),%eax
f0100c59:	8b 52 04             	mov    0x4(%edx),%edx
f0100c5c:	eb 22                	jmp    f0100c80 <getuint+0x38>
	else if (lflag)
f0100c5e:	85 d2                	test   %edx,%edx
f0100c60:	74 10                	je     f0100c72 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100c62:	8b 10                	mov    (%eax),%edx
f0100c64:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100c67:	89 08                	mov    %ecx,(%eax)
f0100c69:	8b 02                	mov    (%edx),%eax
f0100c6b:	ba 00 00 00 00       	mov    $0x0,%edx
f0100c70:	eb 0e                	jmp    f0100c80 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100c72:	8b 10                	mov    (%eax),%edx
f0100c74:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100c77:	89 08                	mov    %ecx,(%eax)
f0100c79:	8b 02                	mov    (%edx),%eax
f0100c7b:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100c80:	5d                   	pop    %ebp
f0100c81:	c3                   	ret    

f0100c82 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100c82:	55                   	push   %ebp
f0100c83:	89 e5                	mov    %esp,%ebp
f0100c85:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100c88:	ff 40 08             	incl   0x8(%eax)
	if (b->buf < b->ebuf)
f0100c8b:	8b 10                	mov    (%eax),%edx
f0100c8d:	3b 50 04             	cmp    0x4(%eax),%edx
f0100c90:	73 0a                	jae    f0100c9c <sprintputch+0x1a>
		*b->buf++ = ch;
f0100c92:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100c95:	89 08                	mov    %ecx,(%eax)
f0100c97:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c9a:	88 02                	mov    %al,(%edx)
}
f0100c9c:	5d                   	pop    %ebp
f0100c9d:	c3                   	ret    

f0100c9e <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100c9e:	55                   	push   %ebp
f0100c9f:	89 e5                	mov    %esp,%ebp
f0100ca1:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100ca4:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100ca7:	50                   	push   %eax
f0100ca8:	ff 75 10             	pushl  0x10(%ebp)
f0100cab:	ff 75 0c             	pushl  0xc(%ebp)
f0100cae:	ff 75 08             	pushl  0x8(%ebp)
f0100cb1:	e8 05 00 00 00       	call   f0100cbb <vprintfmt>
	va_end(ap);
}
f0100cb6:	83 c4 10             	add    $0x10,%esp
f0100cb9:	c9                   	leave  
f0100cba:	c3                   	ret    

f0100cbb <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100cbb:	55                   	push   %ebp
f0100cbc:	89 e5                	mov    %esp,%ebp
f0100cbe:	57                   	push   %edi
f0100cbf:	56                   	push   %esi
f0100cc0:	53                   	push   %ebx
f0100cc1:	83 ec 2c             	sub    $0x2c,%esp
f0100cc4:	8b 75 08             	mov    0x8(%ebp),%esi
f0100cc7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100cca:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100ccd:	eb 12                	jmp    f0100ce1 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100ccf:	85 c0                	test   %eax,%eax
f0100cd1:	0f 84 68 03 00 00    	je     f010103f <vprintfmt+0x384>
				return;
			putch(ch, putdat);
f0100cd7:	83 ec 08             	sub    $0x8,%esp
f0100cda:	53                   	push   %ebx
f0100cdb:	50                   	push   %eax
f0100cdc:	ff d6                	call   *%esi
f0100cde:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100ce1:	47                   	inc    %edi
f0100ce2:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100ce6:	83 f8 25             	cmp    $0x25,%eax
f0100ce9:	75 e4                	jne    f0100ccf <vprintfmt+0x14>
f0100ceb:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100cef:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100cf6:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100cfd:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0100d04:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d09:	eb 07                	jmp    f0100d12 <vprintfmt+0x57>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d0b:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100d0e:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d12:	8d 47 01             	lea    0x1(%edi),%eax
f0100d15:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d18:	0f b6 0f             	movzbl (%edi),%ecx
f0100d1b:	8a 07                	mov    (%edi),%al
f0100d1d:	83 e8 23             	sub    $0x23,%eax
f0100d20:	3c 55                	cmp    $0x55,%al
f0100d22:	0f 87 fe 02 00 00    	ja     f0101026 <vprintfmt+0x36b>
f0100d28:	0f b6 c0             	movzbl %al,%eax
f0100d2b:	ff 24 85 10 1d 10 f0 	jmp    *-0xfefe2f0(,%eax,4)
f0100d32:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100d35:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100d39:	eb d7                	jmp    f0100d12 <vprintfmt+0x57>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d3b:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100d3e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d43:	89 55 e0             	mov    %edx,-0x20(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100d46:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100d49:	01 c0                	add    %eax,%eax
f0100d4b:	8d 44 01 d0          	lea    -0x30(%ecx,%eax,1),%eax
				ch = *fmt;
f0100d4f:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0100d52:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0100d55:	83 fa 09             	cmp    $0x9,%edx
f0100d58:	77 34                	ja     f0100d8e <vprintfmt+0xd3>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100d5a:	47                   	inc    %edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100d5b:	eb e9                	jmp    f0100d46 <vprintfmt+0x8b>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100d5d:	8b 45 14             	mov    0x14(%ebp),%eax
f0100d60:	8d 48 04             	lea    0x4(%eax),%ecx
f0100d63:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100d66:	8b 00                	mov    (%eax),%eax
f0100d68:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d6b:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100d6e:	eb 24                	jmp    f0100d94 <vprintfmt+0xd9>
f0100d70:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100d74:	79 07                	jns    f0100d7d <vprintfmt+0xc2>
f0100d76:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d7d:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100d80:	eb 90                	jmp    f0100d12 <vprintfmt+0x57>
f0100d82:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100d85:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100d8c:	eb 84                	jmp    f0100d12 <vprintfmt+0x57>
f0100d8e:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100d91:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100d94:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100d98:	0f 89 74 ff ff ff    	jns    f0100d12 <vprintfmt+0x57>
				width = precision, precision = -1;
f0100d9e:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100da1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100da4:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100dab:	e9 62 ff ff ff       	jmp    f0100d12 <vprintfmt+0x57>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100db0:	42                   	inc    %edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100db1:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100db4:	e9 59 ff ff ff       	jmp    f0100d12 <vprintfmt+0x57>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100db9:	8b 45 14             	mov    0x14(%ebp),%eax
f0100dbc:	8d 50 04             	lea    0x4(%eax),%edx
f0100dbf:	89 55 14             	mov    %edx,0x14(%ebp)
f0100dc2:	83 ec 08             	sub    $0x8,%esp
f0100dc5:	53                   	push   %ebx
f0100dc6:	ff 30                	pushl  (%eax)
f0100dc8:	ff d6                	call   *%esi
			break;
f0100dca:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100dcd:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100dd0:	e9 0c ff ff ff       	jmp    f0100ce1 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100dd5:	8b 45 14             	mov    0x14(%ebp),%eax
f0100dd8:	8d 50 04             	lea    0x4(%eax),%edx
f0100ddb:	89 55 14             	mov    %edx,0x14(%ebp)
f0100dde:	8b 00                	mov    (%eax),%eax
f0100de0:	85 c0                	test   %eax,%eax
f0100de2:	79 02                	jns    f0100de6 <vprintfmt+0x12b>
f0100de4:	f7 d8                	neg    %eax
f0100de6:	89 c2                	mov    %eax,%edx
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100de8:	83 f8 06             	cmp    $0x6,%eax
f0100deb:	7f 0b                	jg     f0100df8 <vprintfmt+0x13d>
f0100ded:	8b 04 85 68 1e 10 f0 	mov    -0xfefe198(,%eax,4),%eax
f0100df4:	85 c0                	test   %eax,%eax
f0100df6:	75 18                	jne    f0100e10 <vprintfmt+0x155>
				printfmt(putch, putdat, "error %d", err);
f0100df8:	52                   	push   %edx
f0100df9:	68 99 1c 10 f0       	push   $0xf0101c99
f0100dfe:	53                   	push   %ebx
f0100dff:	56                   	push   %esi
f0100e00:	e8 99 fe ff ff       	call   f0100c9e <printfmt>
f0100e05:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e08:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100e0b:	e9 d1 fe ff ff       	jmp    f0100ce1 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0100e10:	50                   	push   %eax
f0100e11:	68 a2 1c 10 f0       	push   $0xf0101ca2
f0100e16:	53                   	push   %ebx
f0100e17:	56                   	push   %esi
f0100e18:	e8 81 fe ff ff       	call   f0100c9e <printfmt>
f0100e1d:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e20:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100e23:	e9 b9 fe ff ff       	jmp    f0100ce1 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100e28:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e2b:	8d 50 04             	lea    0x4(%eax),%edx
f0100e2e:	89 55 14             	mov    %edx,0x14(%ebp)
f0100e31:	8b 38                	mov    (%eax),%edi
f0100e33:	85 ff                	test   %edi,%edi
f0100e35:	75 05                	jne    f0100e3c <vprintfmt+0x181>
				p = "(null)";
f0100e37:	bf 92 1c 10 f0       	mov    $0xf0101c92,%edi
			if (width > 0 && padc != '-')
f0100e3c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100e40:	0f 8e 90 00 00 00    	jle    f0100ed6 <vprintfmt+0x21b>
f0100e46:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100e4a:	0f 84 8e 00 00 00    	je     f0100ede <vprintfmt+0x223>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100e50:	83 ec 08             	sub    $0x8,%esp
f0100e53:	ff 75 d0             	pushl  -0x30(%ebp)
f0100e56:	57                   	push   %edi
f0100e57:	e8 60 03 00 00       	call   f01011bc <strnlen>
f0100e5c:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100e5f:	29 c1                	sub    %eax,%ecx
f0100e61:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0100e64:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0100e67:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0100e6b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100e6e:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100e71:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100e73:	eb 0d                	jmp    f0100e82 <vprintfmt+0x1c7>
					putch(padc, putdat);
f0100e75:	83 ec 08             	sub    $0x8,%esp
f0100e78:	53                   	push   %ebx
f0100e79:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100e7c:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100e7e:	4f                   	dec    %edi
f0100e7f:	83 c4 10             	add    $0x10,%esp
f0100e82:	85 ff                	test   %edi,%edi
f0100e84:	7f ef                	jg     f0100e75 <vprintfmt+0x1ba>
f0100e86:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100e89:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0100e8c:	89 c8                	mov    %ecx,%eax
f0100e8e:	85 c9                	test   %ecx,%ecx
f0100e90:	79 05                	jns    f0100e97 <vprintfmt+0x1dc>
f0100e92:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e97:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0100e9a:	29 c1                	sub    %eax,%ecx
f0100e9c:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100e9f:	89 75 08             	mov    %esi,0x8(%ebp)
f0100ea2:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100ea5:	eb 3d                	jmp    f0100ee4 <vprintfmt+0x229>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100ea7:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100eab:	74 19                	je     f0100ec6 <vprintfmt+0x20b>
f0100ead:	0f be c0             	movsbl %al,%eax
f0100eb0:	83 e8 20             	sub    $0x20,%eax
f0100eb3:	83 f8 5e             	cmp    $0x5e,%eax
f0100eb6:	76 0e                	jbe    f0100ec6 <vprintfmt+0x20b>
					putch('?', putdat);
f0100eb8:	83 ec 08             	sub    $0x8,%esp
f0100ebb:	53                   	push   %ebx
f0100ebc:	6a 3f                	push   $0x3f
f0100ebe:	ff 55 08             	call   *0x8(%ebp)
f0100ec1:	83 c4 10             	add    $0x10,%esp
f0100ec4:	eb 0b                	jmp    f0100ed1 <vprintfmt+0x216>
				else
					putch(ch, putdat);
f0100ec6:	83 ec 08             	sub    $0x8,%esp
f0100ec9:	53                   	push   %ebx
f0100eca:	52                   	push   %edx
f0100ecb:	ff 55 08             	call   *0x8(%ebp)
f0100ece:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100ed1:	ff 4d e4             	decl   -0x1c(%ebp)
f0100ed4:	eb 0e                	jmp    f0100ee4 <vprintfmt+0x229>
f0100ed6:	89 75 08             	mov    %esi,0x8(%ebp)
f0100ed9:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100edc:	eb 06                	jmp    f0100ee4 <vprintfmt+0x229>
f0100ede:	89 75 08             	mov    %esi,0x8(%ebp)
f0100ee1:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100ee4:	47                   	inc    %edi
f0100ee5:	8a 47 ff             	mov    -0x1(%edi),%al
f0100ee8:	0f be d0             	movsbl %al,%edx
f0100eeb:	85 d2                	test   %edx,%edx
f0100eed:	74 1d                	je     f0100f0c <vprintfmt+0x251>
f0100eef:	85 f6                	test   %esi,%esi
f0100ef1:	78 b4                	js     f0100ea7 <vprintfmt+0x1ec>
f0100ef3:	4e                   	dec    %esi
f0100ef4:	79 b1                	jns    f0100ea7 <vprintfmt+0x1ec>
f0100ef6:	8b 75 08             	mov    0x8(%ebp),%esi
f0100ef9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100efc:	eb 14                	jmp    f0100f12 <vprintfmt+0x257>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0100efe:	83 ec 08             	sub    $0x8,%esp
f0100f01:	53                   	push   %ebx
f0100f02:	6a 20                	push   $0x20
f0100f04:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0100f06:	4f                   	dec    %edi
f0100f07:	83 c4 10             	add    $0x10,%esp
f0100f0a:	eb 06                	jmp    f0100f12 <vprintfmt+0x257>
f0100f0c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f0f:	8b 75 08             	mov    0x8(%ebp),%esi
f0100f12:	85 ff                	test   %edi,%edi
f0100f14:	7f e8                	jg     f0100efe <vprintfmt+0x243>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f16:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100f19:	e9 c3 fd ff ff       	jmp    f0100ce1 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0100f1e:	83 fa 01             	cmp    $0x1,%edx
f0100f21:	7e 16                	jle    f0100f39 <vprintfmt+0x27e>
		return va_arg(*ap, long long);
f0100f23:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f26:	8d 50 08             	lea    0x8(%eax),%edx
f0100f29:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f2c:	8b 50 04             	mov    0x4(%eax),%edx
f0100f2f:	8b 00                	mov    (%eax),%eax
f0100f31:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100f34:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100f37:	eb 32                	jmp    f0100f6b <vprintfmt+0x2b0>
	else if (lflag)
f0100f39:	85 d2                	test   %edx,%edx
f0100f3b:	74 18                	je     f0100f55 <vprintfmt+0x29a>
		return va_arg(*ap, long);
f0100f3d:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f40:	8d 50 04             	lea    0x4(%eax),%edx
f0100f43:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f46:	8b 00                	mov    (%eax),%eax
f0100f48:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100f4b:	89 c1                	mov    %eax,%ecx
f0100f4d:	c1 f9 1f             	sar    $0x1f,%ecx
f0100f50:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100f53:	eb 16                	jmp    f0100f6b <vprintfmt+0x2b0>
	else
		return va_arg(*ap, int);
f0100f55:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f58:	8d 50 04             	lea    0x4(%eax),%edx
f0100f5b:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f5e:	8b 00                	mov    (%eax),%eax
f0100f60:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100f63:	89 c1                	mov    %eax,%ecx
f0100f65:	c1 f9 1f             	sar    $0x1f,%ecx
f0100f68:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0100f6b:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100f6e:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
f0100f71:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100f75:	79 76                	jns    f0100fed <vprintfmt+0x332>
				putch('-', putdat);
f0100f77:	83 ec 08             	sub    $0x8,%esp
f0100f7a:	53                   	push   %ebx
f0100f7b:	6a 2d                	push   $0x2d
f0100f7d:	ff d6                	call   *%esi
				num = -(long long) num;
f0100f7f:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100f82:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100f85:	f7 d8                	neg    %eax
f0100f87:	83 d2 00             	adc    $0x0,%edx
f0100f8a:	f7 da                	neg    %edx
f0100f8c:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0100f8f:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0100f94:	eb 5c                	jmp    f0100ff2 <vprintfmt+0x337>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0100f96:	8d 45 14             	lea    0x14(%ebp),%eax
f0100f99:	e8 aa fc ff ff       	call   f0100c48 <getuint>
			base = 10;
f0100f9e:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0100fa3:	eb 4d                	jmp    f0100ff2 <vprintfmt+0x337>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
            num = getuint(&ap,lflag);
f0100fa5:	8d 45 14             	lea    0x14(%ebp),%eax
f0100fa8:	e8 9b fc ff ff       	call   f0100c48 <getuint>
            base = 8;
f0100fad:	b9 08 00 00 00       	mov    $0x8,%ecx
            goto number;
f0100fb2:	eb 3e                	jmp    f0100ff2 <vprintfmt+0x337>
			//putch('X', putdat);
			//break;

		// pointer
		case 'p':
			putch('0', putdat);
f0100fb4:	83 ec 08             	sub    $0x8,%esp
f0100fb7:	53                   	push   %ebx
f0100fb8:	6a 30                	push   $0x30
f0100fba:	ff d6                	call   *%esi
			putch('x', putdat);
f0100fbc:	83 c4 08             	add    $0x8,%esp
f0100fbf:	53                   	push   %ebx
f0100fc0:	6a 78                	push   $0x78
f0100fc2:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0100fc4:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fc7:	8d 50 04             	lea    0x4(%eax),%edx
f0100fca:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0100fcd:	8b 00                	mov    (%eax),%eax
f0100fcf:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0100fd4:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0100fd7:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0100fdc:	eb 14                	jmp    f0100ff2 <vprintfmt+0x337>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0100fde:	8d 45 14             	lea    0x14(%ebp),%eax
f0100fe1:	e8 62 fc ff ff       	call   f0100c48 <getuint>
			base = 16;
f0100fe6:	b9 10 00 00 00       	mov    $0x10,%ecx
f0100feb:	eb 05                	jmp    f0100ff2 <vprintfmt+0x337>
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0100fed:	b9 0a 00 00 00       	mov    $0xa,%ecx
		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
		number:
			printnum(putch, putdat, num, base, width, padc);
f0100ff2:	83 ec 0c             	sub    $0xc,%esp
f0100ff5:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0100ff9:	57                   	push   %edi
f0100ffa:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100ffd:	51                   	push   %ecx
f0100ffe:	52                   	push   %edx
f0100fff:	50                   	push   %eax
f0101000:	89 da                	mov    %ebx,%edx
f0101002:	89 f0                	mov    %esi,%eax
f0101004:	e8 92 fb ff ff       	call   f0100b9b <printnum>
			break;
f0101009:	83 c4 20             	add    $0x20,%esp
f010100c:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010100f:	e9 cd fc ff ff       	jmp    f0100ce1 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101014:	83 ec 08             	sub    $0x8,%esp
f0101017:	53                   	push   %ebx
f0101018:	51                   	push   %ecx
f0101019:	ff d6                	call   *%esi
			break;
f010101b:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010101e:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101021:	e9 bb fc ff ff       	jmp    f0100ce1 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101026:	83 ec 08             	sub    $0x8,%esp
f0101029:	53                   	push   %ebx
f010102a:	6a 25                	push   $0x25
f010102c:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f010102e:	83 c4 10             	add    $0x10,%esp
f0101031:	eb 01                	jmp    f0101034 <vprintfmt+0x379>
f0101033:	4f                   	dec    %edi
f0101034:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101038:	75 f9                	jne    f0101033 <vprintfmt+0x378>
f010103a:	e9 a2 fc ff ff       	jmp    f0100ce1 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f010103f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101042:	5b                   	pop    %ebx
f0101043:	5e                   	pop    %esi
f0101044:	5f                   	pop    %edi
f0101045:	5d                   	pop    %ebp
f0101046:	c3                   	ret    

f0101047 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101047:	55                   	push   %ebp
f0101048:	89 e5                	mov    %esp,%ebp
f010104a:	83 ec 18             	sub    $0x18,%esp
f010104d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101050:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101053:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101056:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010105a:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010105d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101064:	85 c0                	test   %eax,%eax
f0101066:	74 26                	je     f010108e <vsnprintf+0x47>
f0101068:	85 d2                	test   %edx,%edx
f010106a:	7e 29                	jle    f0101095 <vsnprintf+0x4e>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010106c:	ff 75 14             	pushl  0x14(%ebp)
f010106f:	ff 75 10             	pushl  0x10(%ebp)
f0101072:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101075:	50                   	push   %eax
f0101076:	68 82 0c 10 f0       	push   $0xf0100c82
f010107b:	e8 3b fc ff ff       	call   f0100cbb <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101080:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101083:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101086:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101089:	83 c4 10             	add    $0x10,%esp
f010108c:	eb 0c                	jmp    f010109a <vsnprintf+0x53>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f010108e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0101093:	eb 05                	jmp    f010109a <vsnprintf+0x53>
f0101095:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010109a:	c9                   	leave  
f010109b:	c3                   	ret    

f010109c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010109c:	55                   	push   %ebp
f010109d:	89 e5                	mov    %esp,%ebp
f010109f:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01010a2:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01010a5:	50                   	push   %eax
f01010a6:	ff 75 10             	pushl  0x10(%ebp)
f01010a9:	ff 75 0c             	pushl  0xc(%ebp)
f01010ac:	ff 75 08             	pushl  0x8(%ebp)
f01010af:	e8 93 ff ff ff       	call   f0101047 <vsnprintf>
	va_end(ap);

	return rc;
}
f01010b4:	c9                   	leave  
f01010b5:	c3                   	ret    

f01010b6 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01010b6:	55                   	push   %ebp
f01010b7:	89 e5                	mov    %esp,%ebp
f01010b9:	57                   	push   %edi
f01010ba:	56                   	push   %esi
f01010bb:	53                   	push   %ebx
f01010bc:	83 ec 0c             	sub    $0xc,%esp
f01010bf:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01010c2:	85 c0                	test   %eax,%eax
f01010c4:	74 11                	je     f01010d7 <readline+0x21>
		cprintf("%s", prompt);
f01010c6:	83 ec 08             	sub    $0x8,%esp
f01010c9:	50                   	push   %eax
f01010ca:	68 a2 1c 10 f0       	push   $0xf0101ca2
f01010cf:	e8 d8 f7 ff ff       	call   f01008ac <cprintf>
f01010d4:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01010d7:	83 ec 0c             	sub    $0xc,%esp
f01010da:	6a 00                	push   $0x0
f01010dc:	e8 52 f5 ff ff       	call   f0100633 <iscons>
f01010e1:	89 c7                	mov    %eax,%edi
f01010e3:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01010e6:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01010eb:	e8 32 f5 ff ff       	call   f0100622 <getchar>
f01010f0:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01010f2:	85 c0                	test   %eax,%eax
f01010f4:	79 1b                	jns    f0101111 <readline+0x5b>
			cprintf("read error: %e\n", c);
f01010f6:	83 ec 08             	sub    $0x8,%esp
f01010f9:	50                   	push   %eax
f01010fa:	68 84 1e 10 f0       	push   $0xf0101e84
f01010ff:	e8 a8 f7 ff ff       	call   f01008ac <cprintf>
			return NULL;
f0101104:	83 c4 10             	add    $0x10,%esp
f0101107:	b8 00 00 00 00       	mov    $0x0,%eax
f010110c:	e9 8d 00 00 00       	jmp    f010119e <readline+0xe8>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101111:	83 f8 08             	cmp    $0x8,%eax
f0101114:	74 72                	je     f0101188 <readline+0xd2>
f0101116:	83 f8 7f             	cmp    $0x7f,%eax
f0101119:	75 16                	jne    f0101131 <readline+0x7b>
f010111b:	eb 65                	jmp    f0101182 <readline+0xcc>
			if (echoing)
f010111d:	85 ff                	test   %edi,%edi
f010111f:	74 0d                	je     f010112e <readline+0x78>
				cputchar('\b');
f0101121:	83 ec 0c             	sub    $0xc,%esp
f0101124:	6a 08                	push   $0x8
f0101126:	e8 e7 f4 ff ff       	call   f0100612 <cputchar>
f010112b:	83 c4 10             	add    $0x10,%esp
			i--;
f010112e:	4e                   	dec    %esi
f010112f:	eb ba                	jmp    f01010eb <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101131:	83 f8 1f             	cmp    $0x1f,%eax
f0101134:	7e 23                	jle    f0101159 <readline+0xa3>
f0101136:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010113c:	7f 1b                	jg     f0101159 <readline+0xa3>
			if (echoing)
f010113e:	85 ff                	test   %edi,%edi
f0101140:	74 0c                	je     f010114e <readline+0x98>
				cputchar(c);
f0101142:	83 ec 0c             	sub    $0xc,%esp
f0101145:	53                   	push   %ebx
f0101146:	e8 c7 f4 ff ff       	call   f0100612 <cputchar>
f010114b:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f010114e:	88 9e 40 15 11 f0    	mov    %bl,-0xfeeeac0(%esi)
f0101154:	8d 76 01             	lea    0x1(%esi),%esi
f0101157:	eb 92                	jmp    f01010eb <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0101159:	83 fb 0a             	cmp    $0xa,%ebx
f010115c:	74 05                	je     f0101163 <readline+0xad>
f010115e:	83 fb 0d             	cmp    $0xd,%ebx
f0101161:	75 88                	jne    f01010eb <readline+0x35>
			if (echoing)
f0101163:	85 ff                	test   %edi,%edi
f0101165:	74 0d                	je     f0101174 <readline+0xbe>
				cputchar('\n');
f0101167:	83 ec 0c             	sub    $0xc,%esp
f010116a:	6a 0a                	push   $0xa
f010116c:	e8 a1 f4 ff ff       	call   f0100612 <cputchar>
f0101171:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0101174:	c6 86 40 15 11 f0 00 	movb   $0x0,-0xfeeeac0(%esi)
			return buf;
f010117b:	b8 40 15 11 f0       	mov    $0xf0111540,%eax
f0101180:	eb 1c                	jmp    f010119e <readline+0xe8>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
			return NULL;
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101182:	85 f6                	test   %esi,%esi
f0101184:	7f 97                	jg     f010111d <readline+0x67>
f0101186:	eb 09                	jmp    f0101191 <readline+0xdb>
f0101188:	85 f6                	test   %esi,%esi
f010118a:	7f 91                	jg     f010111d <readline+0x67>
f010118c:	e9 5a ff ff ff       	jmp    f01010eb <readline+0x35>
			if (echoing)
				cputchar('\b');
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101191:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101197:	7e a5                	jle    f010113e <readline+0x88>
f0101199:	e9 4d ff ff ff       	jmp    f01010eb <readline+0x35>
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f010119e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011a1:	5b                   	pop    %ebx
f01011a2:	5e                   	pop    %esi
f01011a3:	5f                   	pop    %edi
f01011a4:	5d                   	pop    %ebp
f01011a5:	c3                   	ret    

f01011a6 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01011a6:	55                   	push   %ebp
f01011a7:	89 e5                	mov    %esp,%ebp
f01011a9:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01011ac:	b8 00 00 00 00       	mov    $0x0,%eax
f01011b1:	eb 01                	jmp    f01011b4 <strlen+0xe>
		n++;
f01011b3:	40                   	inc    %eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01011b4:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01011b8:	75 f9                	jne    f01011b3 <strlen+0xd>
		n++;
	return n;
}
f01011ba:	5d                   	pop    %ebp
f01011bb:	c3                   	ret    

f01011bc <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01011bc:	55                   	push   %ebp
f01011bd:	89 e5                	mov    %esp,%ebp
f01011bf:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01011c2:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01011c5:	ba 00 00 00 00       	mov    $0x0,%edx
f01011ca:	eb 01                	jmp    f01011cd <strnlen+0x11>
		n++;
f01011cc:	42                   	inc    %edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01011cd:	39 c2                	cmp    %eax,%edx
f01011cf:	74 08                	je     f01011d9 <strnlen+0x1d>
f01011d1:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01011d5:	75 f5                	jne    f01011cc <strnlen+0x10>
f01011d7:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01011d9:	5d                   	pop    %ebp
f01011da:	c3                   	ret    

f01011db <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01011db:	55                   	push   %ebp
f01011dc:	89 e5                	mov    %esp,%ebp
f01011de:	53                   	push   %ebx
f01011df:	8b 45 08             	mov    0x8(%ebp),%eax
f01011e2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01011e5:	89 c2                	mov    %eax,%edx
f01011e7:	42                   	inc    %edx
f01011e8:	41                   	inc    %ecx
f01011e9:	8a 59 ff             	mov    -0x1(%ecx),%bl
f01011ec:	88 5a ff             	mov    %bl,-0x1(%edx)
f01011ef:	84 db                	test   %bl,%bl
f01011f1:	75 f4                	jne    f01011e7 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01011f3:	5b                   	pop    %ebx
f01011f4:	5d                   	pop    %ebp
f01011f5:	c3                   	ret    

f01011f6 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01011f6:	55                   	push   %ebp
f01011f7:	89 e5                	mov    %esp,%ebp
f01011f9:	53                   	push   %ebx
f01011fa:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01011fd:	53                   	push   %ebx
f01011fe:	e8 a3 ff ff ff       	call   f01011a6 <strlen>
f0101203:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101206:	ff 75 0c             	pushl  0xc(%ebp)
f0101209:	01 d8                	add    %ebx,%eax
f010120b:	50                   	push   %eax
f010120c:	e8 ca ff ff ff       	call   f01011db <strcpy>
	return dst;
}
f0101211:	89 d8                	mov    %ebx,%eax
f0101213:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101216:	c9                   	leave  
f0101217:	c3                   	ret    

f0101218 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101218:	55                   	push   %ebp
f0101219:	89 e5                	mov    %esp,%ebp
f010121b:	56                   	push   %esi
f010121c:	53                   	push   %ebx
f010121d:	8b 75 08             	mov    0x8(%ebp),%esi
f0101220:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101223:	89 f3                	mov    %esi,%ebx
f0101225:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101228:	89 f2                	mov    %esi,%edx
f010122a:	eb 0c                	jmp    f0101238 <strncpy+0x20>
		*dst++ = *src;
f010122c:	42                   	inc    %edx
f010122d:	8a 01                	mov    (%ecx),%al
f010122f:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101232:	80 39 01             	cmpb   $0x1,(%ecx)
f0101235:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101238:	39 da                	cmp    %ebx,%edx
f010123a:	75 f0                	jne    f010122c <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010123c:	89 f0                	mov    %esi,%eax
f010123e:	5b                   	pop    %ebx
f010123f:	5e                   	pop    %esi
f0101240:	5d                   	pop    %ebp
f0101241:	c3                   	ret    

f0101242 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101242:	55                   	push   %ebp
f0101243:	89 e5                	mov    %esp,%ebp
f0101245:	56                   	push   %esi
f0101246:	53                   	push   %ebx
f0101247:	8b 75 08             	mov    0x8(%ebp),%esi
f010124a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010124d:	8b 45 10             	mov    0x10(%ebp),%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101250:	85 c0                	test   %eax,%eax
f0101252:	74 1e                	je     f0101272 <strlcpy+0x30>
f0101254:	8d 44 06 ff          	lea    -0x1(%esi,%eax,1),%eax
f0101258:	89 f2                	mov    %esi,%edx
f010125a:	eb 05                	jmp    f0101261 <strlcpy+0x1f>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010125c:	42                   	inc    %edx
f010125d:	41                   	inc    %ecx
f010125e:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101261:	39 c2                	cmp    %eax,%edx
f0101263:	74 08                	je     f010126d <strlcpy+0x2b>
f0101265:	8a 19                	mov    (%ecx),%bl
f0101267:	84 db                	test   %bl,%bl
f0101269:	75 f1                	jne    f010125c <strlcpy+0x1a>
f010126b:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f010126d:	c6 00 00             	movb   $0x0,(%eax)
f0101270:	eb 02                	jmp    f0101274 <strlcpy+0x32>
f0101272:	89 f0                	mov    %esi,%eax
	}
	return dst - dst_in;
f0101274:	29 f0                	sub    %esi,%eax
}
f0101276:	5b                   	pop    %ebx
f0101277:	5e                   	pop    %esi
f0101278:	5d                   	pop    %ebp
f0101279:	c3                   	ret    

f010127a <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010127a:	55                   	push   %ebp
f010127b:	89 e5                	mov    %esp,%ebp
f010127d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101280:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101283:	eb 02                	jmp    f0101287 <strcmp+0xd>
		p++, q++;
f0101285:	41                   	inc    %ecx
f0101286:	42                   	inc    %edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101287:	8a 01                	mov    (%ecx),%al
f0101289:	84 c0                	test   %al,%al
f010128b:	74 04                	je     f0101291 <strcmp+0x17>
f010128d:	3a 02                	cmp    (%edx),%al
f010128f:	74 f4                	je     f0101285 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101291:	0f b6 c0             	movzbl %al,%eax
f0101294:	0f b6 12             	movzbl (%edx),%edx
f0101297:	29 d0                	sub    %edx,%eax
}
f0101299:	5d                   	pop    %ebp
f010129a:	c3                   	ret    

f010129b <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010129b:	55                   	push   %ebp
f010129c:	89 e5                	mov    %esp,%ebp
f010129e:	53                   	push   %ebx
f010129f:	8b 45 08             	mov    0x8(%ebp),%eax
f01012a2:	8b 55 0c             	mov    0xc(%ebp),%edx
f01012a5:	89 c3                	mov    %eax,%ebx
f01012a7:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01012aa:	eb 02                	jmp    f01012ae <strncmp+0x13>
		n--, p++, q++;
f01012ac:	40                   	inc    %eax
f01012ad:	42                   	inc    %edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01012ae:	39 d8                	cmp    %ebx,%eax
f01012b0:	74 14                	je     f01012c6 <strncmp+0x2b>
f01012b2:	8a 08                	mov    (%eax),%cl
f01012b4:	84 c9                	test   %cl,%cl
f01012b6:	74 04                	je     f01012bc <strncmp+0x21>
f01012b8:	3a 0a                	cmp    (%edx),%cl
f01012ba:	74 f0                	je     f01012ac <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01012bc:	0f b6 00             	movzbl (%eax),%eax
f01012bf:	0f b6 12             	movzbl (%edx),%edx
f01012c2:	29 d0                	sub    %edx,%eax
f01012c4:	eb 05                	jmp    f01012cb <strncmp+0x30>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01012c6:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01012cb:	5b                   	pop    %ebx
f01012cc:	5d                   	pop    %ebp
f01012cd:	c3                   	ret    

f01012ce <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01012ce:	55                   	push   %ebp
f01012cf:	89 e5                	mov    %esp,%ebp
f01012d1:	8b 45 08             	mov    0x8(%ebp),%eax
f01012d4:	8a 4d 0c             	mov    0xc(%ebp),%cl
	for (; *s; s++)
f01012d7:	eb 05                	jmp    f01012de <strchr+0x10>
		if (*s == c)
f01012d9:	38 ca                	cmp    %cl,%dl
f01012db:	74 0c                	je     f01012e9 <strchr+0x1b>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01012dd:	40                   	inc    %eax
f01012de:	8a 10                	mov    (%eax),%dl
f01012e0:	84 d2                	test   %dl,%dl
f01012e2:	75 f5                	jne    f01012d9 <strchr+0xb>
		if (*s == c)
			return (char *) s;
	return 0;
f01012e4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01012e9:	5d                   	pop    %ebp
f01012ea:	c3                   	ret    

f01012eb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01012eb:	55                   	push   %ebp
f01012ec:	89 e5                	mov    %esp,%ebp
f01012ee:	8b 45 08             	mov    0x8(%ebp),%eax
f01012f1:	8a 4d 0c             	mov    0xc(%ebp),%cl
	for (; *s; s++)
f01012f4:	eb 05                	jmp    f01012fb <strfind+0x10>
		if (*s == c)
f01012f6:	38 ca                	cmp    %cl,%dl
f01012f8:	74 07                	je     f0101301 <strfind+0x16>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f01012fa:	40                   	inc    %eax
f01012fb:	8a 10                	mov    (%eax),%dl
f01012fd:	84 d2                	test   %dl,%dl
f01012ff:	75 f5                	jne    f01012f6 <strfind+0xb>
		if (*s == c)
			break;
	return (char *) s;
}
f0101301:	5d                   	pop    %ebp
f0101302:	c3                   	ret    

f0101303 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101303:	55                   	push   %ebp
f0101304:	89 e5                	mov    %esp,%ebp
f0101306:	57                   	push   %edi
f0101307:	56                   	push   %esi
f0101308:	53                   	push   %ebx
f0101309:	8b 7d 08             	mov    0x8(%ebp),%edi
f010130c:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010130f:	85 c9                	test   %ecx,%ecx
f0101311:	74 36                	je     f0101349 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101313:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101319:	75 28                	jne    f0101343 <memset+0x40>
f010131b:	f6 c1 03             	test   $0x3,%cl
f010131e:	75 23                	jne    f0101343 <memset+0x40>
		c &= 0xFF;
f0101320:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101324:	89 d3                	mov    %edx,%ebx
f0101326:	c1 e3 08             	shl    $0x8,%ebx
f0101329:	89 d6                	mov    %edx,%esi
f010132b:	c1 e6 18             	shl    $0x18,%esi
f010132e:	89 d0                	mov    %edx,%eax
f0101330:	c1 e0 10             	shl    $0x10,%eax
f0101333:	09 f0                	or     %esi,%eax
f0101335:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0101337:	89 d8                	mov    %ebx,%eax
f0101339:	09 d0                	or     %edx,%eax
f010133b:	c1 e9 02             	shr    $0x2,%ecx
f010133e:	fc                   	cld    
f010133f:	f3 ab                	rep stos %eax,%es:(%edi)
f0101341:	eb 06                	jmp    f0101349 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101343:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101346:	fc                   	cld    
f0101347:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101349:	89 f8                	mov    %edi,%eax
f010134b:	5b                   	pop    %ebx
f010134c:	5e                   	pop    %esi
f010134d:	5f                   	pop    %edi
f010134e:	5d                   	pop    %ebp
f010134f:	c3                   	ret    

f0101350 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101350:	55                   	push   %ebp
f0101351:	89 e5                	mov    %esp,%ebp
f0101353:	57                   	push   %edi
f0101354:	56                   	push   %esi
f0101355:	8b 45 08             	mov    0x8(%ebp),%eax
f0101358:	8b 75 0c             	mov    0xc(%ebp),%esi
f010135b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010135e:	39 c6                	cmp    %eax,%esi
f0101360:	73 33                	jae    f0101395 <memmove+0x45>
f0101362:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101365:	39 d0                	cmp    %edx,%eax
f0101367:	73 2c                	jae    f0101395 <memmove+0x45>
		s += n;
		d += n;
f0101369:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010136c:	89 d6                	mov    %edx,%esi
f010136e:	09 fe                	or     %edi,%esi
f0101370:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101376:	75 13                	jne    f010138b <memmove+0x3b>
f0101378:	f6 c1 03             	test   $0x3,%cl
f010137b:	75 0e                	jne    f010138b <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f010137d:	83 ef 04             	sub    $0x4,%edi
f0101380:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101383:	c1 e9 02             	shr    $0x2,%ecx
f0101386:	fd                   	std    
f0101387:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101389:	eb 07                	jmp    f0101392 <memmove+0x42>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010138b:	4f                   	dec    %edi
f010138c:	8d 72 ff             	lea    -0x1(%edx),%esi
f010138f:	fd                   	std    
f0101390:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101392:	fc                   	cld    
f0101393:	eb 1d                	jmp    f01013b2 <memmove+0x62>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101395:	89 f2                	mov    %esi,%edx
f0101397:	09 c2                	or     %eax,%edx
f0101399:	f6 c2 03             	test   $0x3,%dl
f010139c:	75 0f                	jne    f01013ad <memmove+0x5d>
f010139e:	f6 c1 03             	test   $0x3,%cl
f01013a1:	75 0a                	jne    f01013ad <memmove+0x5d>
			asm volatile("cld; rep movsl\n"
f01013a3:	c1 e9 02             	shr    $0x2,%ecx
f01013a6:	89 c7                	mov    %eax,%edi
f01013a8:	fc                   	cld    
f01013a9:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01013ab:	eb 05                	jmp    f01013b2 <memmove+0x62>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01013ad:	89 c7                	mov    %eax,%edi
f01013af:	fc                   	cld    
f01013b0:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01013b2:	5e                   	pop    %esi
f01013b3:	5f                   	pop    %edi
f01013b4:	5d                   	pop    %ebp
f01013b5:	c3                   	ret    

f01013b6 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01013b6:	55                   	push   %ebp
f01013b7:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01013b9:	ff 75 10             	pushl  0x10(%ebp)
f01013bc:	ff 75 0c             	pushl  0xc(%ebp)
f01013bf:	ff 75 08             	pushl  0x8(%ebp)
f01013c2:	e8 89 ff ff ff       	call   f0101350 <memmove>
}
f01013c7:	c9                   	leave  
f01013c8:	c3                   	ret    

f01013c9 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01013c9:	55                   	push   %ebp
f01013ca:	89 e5                	mov    %esp,%ebp
f01013cc:	56                   	push   %esi
f01013cd:	53                   	push   %ebx
f01013ce:	8b 45 08             	mov    0x8(%ebp),%eax
f01013d1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01013d4:	89 c6                	mov    %eax,%esi
f01013d6:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01013d9:	eb 14                	jmp    f01013ef <memcmp+0x26>
		if (*s1 != *s2)
f01013db:	8a 08                	mov    (%eax),%cl
f01013dd:	8a 1a                	mov    (%edx),%bl
f01013df:	38 d9                	cmp    %bl,%cl
f01013e1:	74 0a                	je     f01013ed <memcmp+0x24>
			return (int) *s1 - (int) *s2;
f01013e3:	0f b6 c1             	movzbl %cl,%eax
f01013e6:	0f b6 db             	movzbl %bl,%ebx
f01013e9:	29 d8                	sub    %ebx,%eax
f01013eb:	eb 0b                	jmp    f01013f8 <memcmp+0x2f>
		s1++, s2++;
f01013ed:	40                   	inc    %eax
f01013ee:	42                   	inc    %edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01013ef:	39 f0                	cmp    %esi,%eax
f01013f1:	75 e8                	jne    f01013db <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01013f3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01013f8:	5b                   	pop    %ebx
f01013f9:	5e                   	pop    %esi
f01013fa:	5d                   	pop    %ebp
f01013fb:	c3                   	ret    

f01013fc <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01013fc:	55                   	push   %ebp
f01013fd:	89 e5                	mov    %esp,%ebp
f01013ff:	53                   	push   %ebx
f0101400:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0101403:	89 c1                	mov    %eax,%ecx
f0101405:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0101408:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010140c:	eb 08                	jmp    f0101416 <memfind+0x1a>
		if (*(const unsigned char *) s == (unsigned char) c)
f010140e:	0f b6 10             	movzbl (%eax),%edx
f0101411:	39 da                	cmp    %ebx,%edx
f0101413:	74 05                	je     f010141a <memfind+0x1e>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101415:	40                   	inc    %eax
f0101416:	39 c8                	cmp    %ecx,%eax
f0101418:	72 f4                	jb     f010140e <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010141a:	5b                   	pop    %ebx
f010141b:	5d                   	pop    %ebp
f010141c:	c3                   	ret    

f010141d <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010141d:	55                   	push   %ebp
f010141e:	89 e5                	mov    %esp,%ebp
f0101420:	57                   	push   %edi
f0101421:	56                   	push   %esi
f0101422:	53                   	push   %ebx
f0101423:	8b 4d 08             	mov    0x8(%ebp),%ecx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101426:	eb 01                	jmp    f0101429 <strtol+0xc>
		s++;
f0101428:	41                   	inc    %ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101429:	8a 01                	mov    (%ecx),%al
f010142b:	3c 20                	cmp    $0x20,%al
f010142d:	74 f9                	je     f0101428 <strtol+0xb>
f010142f:	3c 09                	cmp    $0x9,%al
f0101431:	74 f5                	je     f0101428 <strtol+0xb>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101433:	3c 2b                	cmp    $0x2b,%al
f0101435:	75 08                	jne    f010143f <strtol+0x22>
		s++;
f0101437:	41                   	inc    %ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101438:	bf 00 00 00 00       	mov    $0x0,%edi
f010143d:	eb 11                	jmp    f0101450 <strtol+0x33>
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010143f:	3c 2d                	cmp    $0x2d,%al
f0101441:	75 08                	jne    f010144b <strtol+0x2e>
		s++, neg = 1;
f0101443:	41                   	inc    %ecx
f0101444:	bf 01 00 00 00       	mov    $0x1,%edi
f0101449:	eb 05                	jmp    f0101450 <strtol+0x33>
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010144b:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101450:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101454:	0f 84 87 00 00 00    	je     f01014e1 <strtol+0xc4>
f010145a:	83 7d 10 10          	cmpl   $0x10,0x10(%ebp)
f010145e:	75 27                	jne    f0101487 <strtol+0x6a>
f0101460:	80 39 30             	cmpb   $0x30,(%ecx)
f0101463:	75 22                	jne    f0101487 <strtol+0x6a>
f0101465:	e9 88 00 00 00       	jmp    f01014f2 <strtol+0xd5>
		s += 2, base = 16;
f010146a:	83 c1 02             	add    $0x2,%ecx
f010146d:	c7 45 10 10 00 00 00 	movl   $0x10,0x10(%ebp)
f0101474:	eb 11                	jmp    f0101487 <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
		s++, base = 8;
f0101476:	41                   	inc    %ecx
f0101477:	c7 45 10 08 00 00 00 	movl   $0x8,0x10(%ebp)
f010147e:	eb 07                	jmp    f0101487 <strtol+0x6a>
	else if (base == 0)
		base = 10;
f0101480:	c7 45 10 0a 00 00 00 	movl   $0xa,0x10(%ebp)
f0101487:	b8 00 00 00 00       	mov    $0x0,%eax

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010148c:	8a 11                	mov    (%ecx),%dl
f010148e:	8d 5a d0             	lea    -0x30(%edx),%ebx
f0101491:	80 fb 09             	cmp    $0x9,%bl
f0101494:	77 08                	ja     f010149e <strtol+0x81>
			dig = *s - '0';
f0101496:	0f be d2             	movsbl %dl,%edx
f0101499:	83 ea 30             	sub    $0x30,%edx
f010149c:	eb 22                	jmp    f01014c0 <strtol+0xa3>
		else if (*s >= 'a' && *s <= 'z')
f010149e:	8d 72 9f             	lea    -0x61(%edx),%esi
f01014a1:	89 f3                	mov    %esi,%ebx
f01014a3:	80 fb 19             	cmp    $0x19,%bl
f01014a6:	77 08                	ja     f01014b0 <strtol+0x93>
			dig = *s - 'a' + 10;
f01014a8:	0f be d2             	movsbl %dl,%edx
f01014ab:	83 ea 57             	sub    $0x57,%edx
f01014ae:	eb 10                	jmp    f01014c0 <strtol+0xa3>
		else if (*s >= 'A' && *s <= 'Z')
f01014b0:	8d 72 bf             	lea    -0x41(%edx),%esi
f01014b3:	89 f3                	mov    %esi,%ebx
f01014b5:	80 fb 19             	cmp    $0x19,%bl
f01014b8:	77 14                	ja     f01014ce <strtol+0xb1>
			dig = *s - 'A' + 10;
f01014ba:	0f be d2             	movsbl %dl,%edx
f01014bd:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01014c0:	3b 55 10             	cmp    0x10(%ebp),%edx
f01014c3:	7d 09                	jge    f01014ce <strtol+0xb1>
			break;
		s++, val = (val * base) + dig;
f01014c5:	41                   	inc    %ecx
f01014c6:	0f af 45 10          	imul   0x10(%ebp),%eax
f01014ca:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01014cc:	eb be                	jmp    f010148c <strtol+0x6f>

	if (endptr)
f01014ce:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01014d2:	74 05                	je     f01014d9 <strtol+0xbc>
		*endptr = (char *) s;
f01014d4:	8b 75 0c             	mov    0xc(%ebp),%esi
f01014d7:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f01014d9:	85 ff                	test   %edi,%edi
f01014db:	74 21                	je     f01014fe <strtol+0xe1>
f01014dd:	f7 d8                	neg    %eax
f01014df:	eb 1d                	jmp    f01014fe <strtol+0xe1>
		s++;
	else if (*s == '-')
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01014e1:	80 39 30             	cmpb   $0x30,(%ecx)
f01014e4:	75 9a                	jne    f0101480 <strtol+0x63>
f01014e6:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01014ea:	0f 84 7a ff ff ff    	je     f010146a <strtol+0x4d>
f01014f0:	eb 84                	jmp    f0101476 <strtol+0x59>
f01014f2:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01014f6:	0f 84 6e ff ff ff    	je     f010146a <strtol+0x4d>
f01014fc:	eb 89                	jmp    f0101487 <strtol+0x6a>
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
}
f01014fe:	5b                   	pop    %ebx
f01014ff:	5e                   	pop    %esi
f0101500:	5f                   	pop    %edi
f0101501:	5d                   	pop    %ebp
f0101502:	c3                   	ret    
f0101503:	90                   	nop

f0101504 <__udivdi3>:
f0101504:	55                   	push   %ebp
f0101505:	57                   	push   %edi
f0101506:	56                   	push   %esi
f0101507:	53                   	push   %ebx
f0101508:	83 ec 1c             	sub    $0x1c,%esp
f010150b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010150f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0101513:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101517:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010151b:	89 ca                	mov    %ecx,%edx
f010151d:	89 f8                	mov    %edi,%eax
f010151f:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f0101523:	85 f6                	test   %esi,%esi
f0101525:	75 2d                	jne    f0101554 <__udivdi3+0x50>
f0101527:	39 cf                	cmp    %ecx,%edi
f0101529:	77 65                	ja     f0101590 <__udivdi3+0x8c>
f010152b:	89 fd                	mov    %edi,%ebp
f010152d:	85 ff                	test   %edi,%edi
f010152f:	75 0b                	jne    f010153c <__udivdi3+0x38>
f0101531:	b8 01 00 00 00       	mov    $0x1,%eax
f0101536:	31 d2                	xor    %edx,%edx
f0101538:	f7 f7                	div    %edi
f010153a:	89 c5                	mov    %eax,%ebp
f010153c:	31 d2                	xor    %edx,%edx
f010153e:	89 c8                	mov    %ecx,%eax
f0101540:	f7 f5                	div    %ebp
f0101542:	89 c1                	mov    %eax,%ecx
f0101544:	89 d8                	mov    %ebx,%eax
f0101546:	f7 f5                	div    %ebp
f0101548:	89 cf                	mov    %ecx,%edi
f010154a:	89 fa                	mov    %edi,%edx
f010154c:	83 c4 1c             	add    $0x1c,%esp
f010154f:	5b                   	pop    %ebx
f0101550:	5e                   	pop    %esi
f0101551:	5f                   	pop    %edi
f0101552:	5d                   	pop    %ebp
f0101553:	c3                   	ret    
f0101554:	39 ce                	cmp    %ecx,%esi
f0101556:	77 28                	ja     f0101580 <__udivdi3+0x7c>
f0101558:	0f bd fe             	bsr    %esi,%edi
f010155b:	83 f7 1f             	xor    $0x1f,%edi
f010155e:	75 40                	jne    f01015a0 <__udivdi3+0x9c>
f0101560:	39 ce                	cmp    %ecx,%esi
f0101562:	72 0a                	jb     f010156e <__udivdi3+0x6a>
f0101564:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0101568:	0f 87 9e 00 00 00    	ja     f010160c <__udivdi3+0x108>
f010156e:	b8 01 00 00 00       	mov    $0x1,%eax
f0101573:	89 fa                	mov    %edi,%edx
f0101575:	83 c4 1c             	add    $0x1c,%esp
f0101578:	5b                   	pop    %ebx
f0101579:	5e                   	pop    %esi
f010157a:	5f                   	pop    %edi
f010157b:	5d                   	pop    %ebp
f010157c:	c3                   	ret    
f010157d:	8d 76 00             	lea    0x0(%esi),%esi
f0101580:	31 ff                	xor    %edi,%edi
f0101582:	31 c0                	xor    %eax,%eax
f0101584:	89 fa                	mov    %edi,%edx
f0101586:	83 c4 1c             	add    $0x1c,%esp
f0101589:	5b                   	pop    %ebx
f010158a:	5e                   	pop    %esi
f010158b:	5f                   	pop    %edi
f010158c:	5d                   	pop    %ebp
f010158d:	c3                   	ret    
f010158e:	66 90                	xchg   %ax,%ax
f0101590:	89 d8                	mov    %ebx,%eax
f0101592:	f7 f7                	div    %edi
f0101594:	31 ff                	xor    %edi,%edi
f0101596:	89 fa                	mov    %edi,%edx
f0101598:	83 c4 1c             	add    $0x1c,%esp
f010159b:	5b                   	pop    %ebx
f010159c:	5e                   	pop    %esi
f010159d:	5f                   	pop    %edi
f010159e:	5d                   	pop    %ebp
f010159f:	c3                   	ret    
f01015a0:	bd 20 00 00 00       	mov    $0x20,%ebp
f01015a5:	89 eb                	mov    %ebp,%ebx
f01015a7:	29 fb                	sub    %edi,%ebx
f01015a9:	89 f9                	mov    %edi,%ecx
f01015ab:	d3 e6                	shl    %cl,%esi
f01015ad:	89 c5                	mov    %eax,%ebp
f01015af:	88 d9                	mov    %bl,%cl
f01015b1:	d3 ed                	shr    %cl,%ebp
f01015b3:	89 e9                	mov    %ebp,%ecx
f01015b5:	09 f1                	or     %esi,%ecx
f01015b7:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01015bb:	89 f9                	mov    %edi,%ecx
f01015bd:	d3 e0                	shl    %cl,%eax
f01015bf:	89 c5                	mov    %eax,%ebp
f01015c1:	89 d6                	mov    %edx,%esi
f01015c3:	88 d9                	mov    %bl,%cl
f01015c5:	d3 ee                	shr    %cl,%esi
f01015c7:	89 f9                	mov    %edi,%ecx
f01015c9:	d3 e2                	shl    %cl,%edx
f01015cb:	8b 44 24 08          	mov    0x8(%esp),%eax
f01015cf:	88 d9                	mov    %bl,%cl
f01015d1:	d3 e8                	shr    %cl,%eax
f01015d3:	09 c2                	or     %eax,%edx
f01015d5:	89 d0                	mov    %edx,%eax
f01015d7:	89 f2                	mov    %esi,%edx
f01015d9:	f7 74 24 0c          	divl   0xc(%esp)
f01015dd:	89 d6                	mov    %edx,%esi
f01015df:	89 c3                	mov    %eax,%ebx
f01015e1:	f7 e5                	mul    %ebp
f01015e3:	39 d6                	cmp    %edx,%esi
f01015e5:	72 19                	jb     f0101600 <__udivdi3+0xfc>
f01015e7:	74 0b                	je     f01015f4 <__udivdi3+0xf0>
f01015e9:	89 d8                	mov    %ebx,%eax
f01015eb:	31 ff                	xor    %edi,%edi
f01015ed:	e9 58 ff ff ff       	jmp    f010154a <__udivdi3+0x46>
f01015f2:	66 90                	xchg   %ax,%ax
f01015f4:	8b 54 24 08          	mov    0x8(%esp),%edx
f01015f8:	89 f9                	mov    %edi,%ecx
f01015fa:	d3 e2                	shl    %cl,%edx
f01015fc:	39 c2                	cmp    %eax,%edx
f01015fe:	73 e9                	jae    f01015e9 <__udivdi3+0xe5>
f0101600:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0101603:	31 ff                	xor    %edi,%edi
f0101605:	e9 40 ff ff ff       	jmp    f010154a <__udivdi3+0x46>
f010160a:	66 90                	xchg   %ax,%ax
f010160c:	31 c0                	xor    %eax,%eax
f010160e:	e9 37 ff ff ff       	jmp    f010154a <__udivdi3+0x46>
f0101613:	90                   	nop

f0101614 <__umoddi3>:
f0101614:	55                   	push   %ebp
f0101615:	57                   	push   %edi
f0101616:	56                   	push   %esi
f0101617:	53                   	push   %ebx
f0101618:	83 ec 1c             	sub    $0x1c,%esp
f010161b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010161f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101623:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101627:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f010162b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010162f:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101633:	89 f3                	mov    %esi,%ebx
f0101635:	89 fa                	mov    %edi,%edx
f0101637:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010163b:	89 34 24             	mov    %esi,(%esp)
f010163e:	85 c0                	test   %eax,%eax
f0101640:	75 1a                	jne    f010165c <__umoddi3+0x48>
f0101642:	39 f7                	cmp    %esi,%edi
f0101644:	0f 86 a2 00 00 00    	jbe    f01016ec <__umoddi3+0xd8>
f010164a:	89 c8                	mov    %ecx,%eax
f010164c:	89 f2                	mov    %esi,%edx
f010164e:	f7 f7                	div    %edi
f0101650:	89 d0                	mov    %edx,%eax
f0101652:	31 d2                	xor    %edx,%edx
f0101654:	83 c4 1c             	add    $0x1c,%esp
f0101657:	5b                   	pop    %ebx
f0101658:	5e                   	pop    %esi
f0101659:	5f                   	pop    %edi
f010165a:	5d                   	pop    %ebp
f010165b:	c3                   	ret    
f010165c:	39 f0                	cmp    %esi,%eax
f010165e:	0f 87 ac 00 00 00    	ja     f0101710 <__umoddi3+0xfc>
f0101664:	0f bd e8             	bsr    %eax,%ebp
f0101667:	83 f5 1f             	xor    $0x1f,%ebp
f010166a:	0f 84 ac 00 00 00    	je     f010171c <__umoddi3+0x108>
f0101670:	bf 20 00 00 00       	mov    $0x20,%edi
f0101675:	29 ef                	sub    %ebp,%edi
f0101677:	89 fe                	mov    %edi,%esi
f0101679:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010167d:	89 e9                	mov    %ebp,%ecx
f010167f:	d3 e0                	shl    %cl,%eax
f0101681:	89 d7                	mov    %edx,%edi
f0101683:	89 f1                	mov    %esi,%ecx
f0101685:	d3 ef                	shr    %cl,%edi
f0101687:	09 c7                	or     %eax,%edi
f0101689:	89 e9                	mov    %ebp,%ecx
f010168b:	d3 e2                	shl    %cl,%edx
f010168d:	89 14 24             	mov    %edx,(%esp)
f0101690:	89 d8                	mov    %ebx,%eax
f0101692:	d3 e0                	shl    %cl,%eax
f0101694:	89 c2                	mov    %eax,%edx
f0101696:	8b 44 24 08          	mov    0x8(%esp),%eax
f010169a:	d3 e0                	shl    %cl,%eax
f010169c:	89 44 24 04          	mov    %eax,0x4(%esp)
f01016a0:	8b 44 24 08          	mov    0x8(%esp),%eax
f01016a4:	89 f1                	mov    %esi,%ecx
f01016a6:	d3 e8                	shr    %cl,%eax
f01016a8:	09 d0                	or     %edx,%eax
f01016aa:	d3 eb                	shr    %cl,%ebx
f01016ac:	89 da                	mov    %ebx,%edx
f01016ae:	f7 f7                	div    %edi
f01016b0:	89 d3                	mov    %edx,%ebx
f01016b2:	f7 24 24             	mull   (%esp)
f01016b5:	89 c6                	mov    %eax,%esi
f01016b7:	89 d1                	mov    %edx,%ecx
f01016b9:	39 d3                	cmp    %edx,%ebx
f01016bb:	0f 82 87 00 00 00    	jb     f0101748 <__umoddi3+0x134>
f01016c1:	0f 84 91 00 00 00    	je     f0101758 <__umoddi3+0x144>
f01016c7:	8b 54 24 04          	mov    0x4(%esp),%edx
f01016cb:	29 f2                	sub    %esi,%edx
f01016cd:	19 cb                	sbb    %ecx,%ebx
f01016cf:	89 d8                	mov    %ebx,%eax
f01016d1:	8a 4c 24 0c          	mov    0xc(%esp),%cl
f01016d5:	d3 e0                	shl    %cl,%eax
f01016d7:	89 e9                	mov    %ebp,%ecx
f01016d9:	d3 ea                	shr    %cl,%edx
f01016db:	09 d0                	or     %edx,%eax
f01016dd:	89 e9                	mov    %ebp,%ecx
f01016df:	d3 eb                	shr    %cl,%ebx
f01016e1:	89 da                	mov    %ebx,%edx
f01016e3:	83 c4 1c             	add    $0x1c,%esp
f01016e6:	5b                   	pop    %ebx
f01016e7:	5e                   	pop    %esi
f01016e8:	5f                   	pop    %edi
f01016e9:	5d                   	pop    %ebp
f01016ea:	c3                   	ret    
f01016eb:	90                   	nop
f01016ec:	89 fd                	mov    %edi,%ebp
f01016ee:	85 ff                	test   %edi,%edi
f01016f0:	75 0b                	jne    f01016fd <__umoddi3+0xe9>
f01016f2:	b8 01 00 00 00       	mov    $0x1,%eax
f01016f7:	31 d2                	xor    %edx,%edx
f01016f9:	f7 f7                	div    %edi
f01016fb:	89 c5                	mov    %eax,%ebp
f01016fd:	89 f0                	mov    %esi,%eax
f01016ff:	31 d2                	xor    %edx,%edx
f0101701:	f7 f5                	div    %ebp
f0101703:	89 c8                	mov    %ecx,%eax
f0101705:	f7 f5                	div    %ebp
f0101707:	89 d0                	mov    %edx,%eax
f0101709:	e9 44 ff ff ff       	jmp    f0101652 <__umoddi3+0x3e>
f010170e:	66 90                	xchg   %ax,%ax
f0101710:	89 c8                	mov    %ecx,%eax
f0101712:	89 f2                	mov    %esi,%edx
f0101714:	83 c4 1c             	add    $0x1c,%esp
f0101717:	5b                   	pop    %ebx
f0101718:	5e                   	pop    %esi
f0101719:	5f                   	pop    %edi
f010171a:	5d                   	pop    %ebp
f010171b:	c3                   	ret    
f010171c:	3b 04 24             	cmp    (%esp),%eax
f010171f:	72 06                	jb     f0101727 <__umoddi3+0x113>
f0101721:	3b 7c 24 04          	cmp    0x4(%esp),%edi
f0101725:	77 0f                	ja     f0101736 <__umoddi3+0x122>
f0101727:	89 f2                	mov    %esi,%edx
f0101729:	29 f9                	sub    %edi,%ecx
f010172b:	1b 54 24 0c          	sbb    0xc(%esp),%edx
f010172f:	89 14 24             	mov    %edx,(%esp)
f0101732:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101736:	8b 44 24 04          	mov    0x4(%esp),%eax
f010173a:	8b 14 24             	mov    (%esp),%edx
f010173d:	83 c4 1c             	add    $0x1c,%esp
f0101740:	5b                   	pop    %ebx
f0101741:	5e                   	pop    %esi
f0101742:	5f                   	pop    %edi
f0101743:	5d                   	pop    %ebp
f0101744:	c3                   	ret    
f0101745:	8d 76 00             	lea    0x0(%esi),%esi
f0101748:	2b 04 24             	sub    (%esp),%eax
f010174b:	19 fa                	sbb    %edi,%edx
f010174d:	89 d1                	mov    %edx,%ecx
f010174f:	89 c6                	mov    %eax,%esi
f0101751:	e9 71 ff ff ff       	jmp    f01016c7 <__umoddi3+0xb3>
f0101756:	66 90                	xchg   %ax,%ax
f0101758:	39 44 24 04          	cmp    %eax,0x4(%esp)
f010175c:	72 ea                	jb     f0101748 <__umoddi3+0x134>
f010175e:	89 d9                	mov    %ebx,%ecx
f0101760:	e9 62 ff ff ff       	jmp    f01016c7 <__umoddi3+0xb3>
