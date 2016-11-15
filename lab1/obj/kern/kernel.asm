
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
f010004b:	68 e0 18 10 f0       	push   $0xf01018e0
f0100050:	e8 1c 09 00 00       	call   f0100971 <cprintf>
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
f0100076:	e8 d5 06 00 00       	call   f0100750 <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 fc 18 10 f0       	push   $0xf01018fc
f0100087:	e8 e5 08 00 00       	call   f0100971 <cprintf>
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
f010009a:	b8 48 29 11 f0       	mov    $0xf0112948,%eax
f010009f:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 23 11 f0       	push   $0xf0112300
f01000ac:	e8 b3 13 00 00       	call   f0101464 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 86 04 00 00       	call   f010053c <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 17 19 10 f0       	push   $0xf0101917
f01000c3:	e8 a9 08 00 00       	call   f0100971 <cprintf>

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
f01000dc:	e8 fc 06 00 00       	call   f01007dd <monitor>
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
f01000ee:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f01000f5:	75 37                	jne    f010012e <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000f7:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

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
f010010b:	68 32 19 10 f0       	push   $0xf0101932
f0100110:	e8 5c 08 00 00       	call   f0100971 <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 2c 08 00 00       	call   f010094b <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 6e 19 10 f0 	movl   $0xf010196e,(%esp)
f0100126:	e8 46 08 00 00       	call   f0100971 <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 a5 06 00 00       	call   f01007dd <monitor>
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
f010014d:	68 4a 19 10 f0       	push   $0xf010194a
f0100152:	e8 1a 08 00 00       	call   f0100971 <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 e8 07 00 00       	call   f010094b <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 6e 19 10 f0 	movl   $0xf010196e,(%esp)
f010016a:	e8 02 08 00 00       	call   f0100971 <cprintf>
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
f01001a5:	8b 0d 24 25 11 f0    	mov    0xf0112524,%ecx
f01001ab:	8d 51 01             	lea    0x1(%ecx),%edx
f01001ae:	89 15 24 25 11 f0    	mov    %edx,0xf0112524
f01001b4:	88 81 20 23 11 f0    	mov    %al,-0xfeedce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01001ba:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001c0:	75 0a                	jne    f01001cc <cons_intr+0x36>
			cons.wpos = 0;
f01001c2:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
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
f01001fb:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f0100202:	b8 00 00 00 00       	mov    $0x0,%eax
f0100207:	c3                   	ret    
	} else if (data & 0x80) {
f0100208:	84 c0                	test   %al,%al
f010020a:	79 2e                	jns    f010023a <kbd_proc_data+0x61>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010020c:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100212:	f6 c1 40             	test   $0x40,%cl
f0100215:	75 05                	jne    f010021c <kbd_proc_data+0x43>
f0100217:	83 e0 7f             	and    $0x7f,%eax
f010021a:	88 c2                	mov    %al,%dl
		shift &= ~(shiftcode[data] | E0ESC);
f010021c:	0f b6 c2             	movzbl %dl,%eax
f010021f:	8a 80 c0 1a 10 f0    	mov    -0xfefe540(%eax),%al
f0100225:	83 c8 40             	or     $0x40,%eax
f0100228:	0f b6 c0             	movzbl %al,%eax
f010022b:	f7 d0                	not    %eax
f010022d:	21 c8                	and    %ecx,%eax
f010022f:	a3 00 23 11 f0       	mov    %eax,0xf0112300
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
f0100241:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100247:	f6 c1 40             	test   $0x40,%cl
f010024a:	74 0e                	je     f010025a <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010024c:	83 c8 80             	or     $0xffffff80,%eax
f010024f:	88 c2                	mov    %al,%dl
		shift &= ~E0ESC;
f0100251:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100254:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f010025a:	0f b6 c2             	movzbl %dl,%eax
	shift ^= togglecode[data];
f010025d:	0f b6 90 c0 1a 10 f0 	movzbl -0xfefe540(%eax),%edx
f0100264:	0b 15 00 23 11 f0    	or     0xf0112300,%edx
f010026a:	0f b6 88 c0 19 10 f0 	movzbl -0xfefe640(%eax),%ecx
f0100271:	31 ca                	xor    %ecx,%edx
f0100273:	89 15 00 23 11 f0    	mov    %edx,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100279:	89 d1                	mov    %edx,%ecx
f010027b:	83 e1 03             	and    $0x3,%ecx
f010027e:	8b 0c 8d a0 19 10 f0 	mov    -0xfefe660(,%ecx,4),%ecx
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
f01002bc:	68 64 19 10 f0       	push   $0xf0101964
f01002c1:	e8 ab 06 00 00       	call   f0100971 <cprintf>
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
    if (!ccolor) ccolor = 0x0700;
f0100358:	83 3d 44 29 11 f0 00 	cmpl   $0x0,0xf0112944
f010035f:	75 0a                	jne    f010036b <cons_putc+0x7f>
f0100361:	c7 05 44 29 11 f0 00 	movl   $0x700,0xf0112944
f0100368:	07 00 00 
	if (!(c & ~0xFF))
f010036b:	f7 c7 00 ff ff ff    	test   $0xffffff00,%edi
f0100371:	75 06                	jne    f0100379 <cons_putc+0x8d>
		c |= ccolor;
f0100373:	0b 3d 44 29 11 f0    	or     0xf0112944,%edi

	switch (c & 0xff) {
f0100379:	89 f8                	mov    %edi,%eax
f010037b:	0f b6 c0             	movzbl %al,%eax
f010037e:	83 f8 09             	cmp    $0x9,%eax
f0100381:	74 75                	je     f01003f8 <cons_putc+0x10c>
f0100383:	83 f8 09             	cmp    $0x9,%eax
f0100386:	7f 0a                	jg     f0100392 <cons_putc+0xa6>
f0100388:	83 f8 08             	cmp    $0x8,%eax
f010038b:	74 14                	je     f01003a1 <cons_putc+0xb5>
f010038d:	e9 9a 00 00 00       	jmp    f010042c <cons_putc+0x140>
f0100392:	83 f8 0a             	cmp    $0xa,%eax
f0100395:	74 38                	je     f01003cf <cons_putc+0xe3>
f0100397:	83 f8 0d             	cmp    $0xd,%eax
f010039a:	74 3b                	je     f01003d7 <cons_putc+0xeb>
f010039c:	e9 8b 00 00 00       	jmp    f010042c <cons_putc+0x140>
	case '\b':
		if (crt_pos > 0) {
f01003a1:	66 a1 28 25 11 f0    	mov    0xf0112528,%ax
f01003a7:	66 85 c0             	test   %ax,%ax
f01003aa:	0f 84 e7 00 00 00    	je     f0100497 <cons_putc+0x1ab>
			crt_pos--;
f01003b0:	48                   	dec    %eax
f01003b1:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003b7:	0f b7 c0             	movzwl %ax,%eax
f01003ba:	81 e7 00 ff ff ff    	and    $0xffffff00,%edi
f01003c0:	83 cf 20             	or     $0x20,%edi
f01003c3:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01003c9:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003cd:	eb 7a                	jmp    f0100449 <cons_putc+0x15d>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003cf:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f01003d6:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003d7:	66 8b 0d 28 25 11 f0 	mov    0xf0112528,%cx
f01003de:	bb 50 00 00 00       	mov    $0x50,%ebx
f01003e3:	89 c8                	mov    %ecx,%eax
f01003e5:	ba 00 00 00 00       	mov    $0x0,%edx
f01003ea:	66 f7 f3             	div    %bx
f01003ed:	29 d1                	sub    %edx,%ecx
f01003ef:	66 89 0d 28 25 11 f0 	mov    %cx,0xf0112528
f01003f6:	eb 51                	jmp    f0100449 <cons_putc+0x15d>
		break;
	case '\t':
		cons_putc(' ');
f01003f8:	b8 20 00 00 00       	mov    $0x20,%eax
f01003fd:	e8 ea fe ff ff       	call   f01002ec <cons_putc>
		cons_putc(' ');
f0100402:	b8 20 00 00 00       	mov    $0x20,%eax
f0100407:	e8 e0 fe ff ff       	call   f01002ec <cons_putc>
		cons_putc(' ');
f010040c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100411:	e8 d6 fe ff ff       	call   f01002ec <cons_putc>
		cons_putc(' ');
f0100416:	b8 20 00 00 00       	mov    $0x20,%eax
f010041b:	e8 cc fe ff ff       	call   f01002ec <cons_putc>
		cons_putc(' ');
f0100420:	b8 20 00 00 00       	mov    $0x20,%eax
f0100425:	e8 c2 fe ff ff       	call   f01002ec <cons_putc>
f010042a:	eb 1d                	jmp    f0100449 <cons_putc+0x15d>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010042c:	66 a1 28 25 11 f0    	mov    0xf0112528,%ax
f0100432:	8d 50 01             	lea    0x1(%eax),%edx
f0100435:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f010043c:	0f b7 c0             	movzwl %ax,%eax
f010043f:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100445:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100449:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f0100450:	cf 07 
f0100452:	76 43                	jbe    f0100497 <cons_putc+0x1ab>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100454:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f0100459:	83 ec 04             	sub    $0x4,%esp
f010045c:	68 00 0f 00 00       	push   $0xf00
f0100461:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100467:	52                   	push   %edx
f0100468:	50                   	push   %eax
f0100469:	e8 43 10 00 00       	call   f01014b1 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010046e:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100474:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010047a:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100480:	83 c4 10             	add    $0x10,%esp
f0100483:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100488:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010048b:	39 d0                	cmp    %edx,%eax
f010048d:	75 f4                	jne    f0100483 <cons_putc+0x197>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010048f:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f0100496:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100497:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f010049d:	b0 0e                	mov    $0xe,%al
f010049f:	89 ca                	mov    %ecx,%edx
f01004a1:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004a2:	8d 59 01             	lea    0x1(%ecx),%ebx
f01004a5:	66 a1 28 25 11 f0    	mov    0xf0112528,%ax
f01004ab:	66 c1 e8 08          	shr    $0x8,%ax
f01004af:	89 da                	mov    %ebx,%edx
f01004b1:	ee                   	out    %al,(%dx)
f01004b2:	b0 0f                	mov    $0xf,%al
f01004b4:	89 ca                	mov    %ecx,%edx
f01004b6:	ee                   	out    %al,(%dx)
f01004b7:	a0 28 25 11 f0       	mov    0xf0112528,%al
f01004bc:	89 da                	mov    %ebx,%edx
f01004be:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004bf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004c2:	5b                   	pop    %ebx
f01004c3:	5e                   	pop    %esi
f01004c4:	5f                   	pop    %edi
f01004c5:	5d                   	pop    %ebp
f01004c6:	c3                   	ret    

f01004c7 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004c7:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004ce:	74 11                	je     f01004e1 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004d0:	55                   	push   %ebp
f01004d1:	89 e5                	mov    %esp,%ebp
f01004d3:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004d6:	b8 77 01 10 f0       	mov    $0xf0100177,%eax
f01004db:	e8 b6 fc ff ff       	call   f0100196 <cons_intr>
}
f01004e0:	c9                   	leave  
f01004e1:	c3                   	ret    

f01004e2 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004e2:	55                   	push   %ebp
f01004e3:	89 e5                	mov    %esp,%ebp
f01004e5:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004e8:	b8 d9 01 10 f0       	mov    $0xf01001d9,%eax
f01004ed:	e8 a4 fc ff ff       	call   f0100196 <cons_intr>
}
f01004f2:	c9                   	leave  
f01004f3:	c3                   	ret    

f01004f4 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004f4:	55                   	push   %ebp
f01004f5:	89 e5                	mov    %esp,%ebp
f01004f7:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004fa:	e8 c8 ff ff ff       	call   f01004c7 <serial_intr>
	kbd_intr();
f01004ff:	e8 de ff ff ff       	call   f01004e2 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100504:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f0100509:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f010050f:	74 24                	je     f0100535 <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f0100511:	8d 50 01             	lea    0x1(%eax),%edx
f0100514:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f010051a:	0f b6 80 20 23 11 f0 	movzbl -0xfeedce0(%eax),%eax
		if (cons.rpos == CONSBUFSIZE)
f0100521:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100527:	75 11                	jne    f010053a <cons_getc+0x46>
			cons.rpos = 0;
f0100529:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100530:	00 00 00 
f0100533:	eb 05                	jmp    f010053a <cons_getc+0x46>
		return c;
	}
	return 0;
f0100535:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010053a:	c9                   	leave  
f010053b:	c3                   	ret    

f010053c <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010053c:	55                   	push   %ebp
f010053d:	89 e5                	mov    %esp,%ebp
f010053f:	56                   	push   %esi
f0100540:	53                   	push   %ebx
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100541:	66 8b 15 00 80 0b f0 	mov    0xf00b8000,%dx
	*cp = (uint16_t) 0xA55A;
f0100548:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010054f:	5a a5 
	if (*cp != 0xA55A) {
f0100551:	66 a1 00 80 0b f0    	mov    0xf00b8000,%ax
f0100557:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010055b:	74 11                	je     f010056e <cons_init+0x32>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010055d:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f0100564:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100567:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010056c:	eb 16                	jmp    f0100584 <cons_init+0x48>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010056e:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100575:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f010057c:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010057f:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
f0100584:	b0 0e                	mov    $0xe,%al
f0100586:	8b 15 30 25 11 f0    	mov    0xf0112530,%edx
f010058c:	ee                   	out    %al,(%dx)
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
f010058d:	8d 5a 01             	lea    0x1(%edx),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100590:	89 da                	mov    %ebx,%edx
f0100592:	ec                   	in     (%dx),%al
f0100593:	0f b6 c8             	movzbl %al,%ecx
f0100596:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100599:	b0 0f                	mov    $0xf,%al
f010059b:	8b 15 30 25 11 f0    	mov    0xf0112530,%edx
f01005a1:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005a2:	89 da                	mov    %ebx,%edx
f01005a4:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005a5:	89 35 2c 25 11 f0    	mov    %esi,0xf011252c
	crt_pos = pos;
f01005ab:	0f b6 c0             	movzbl %al,%eax
f01005ae:	09 c8                	or     %ecx,%eax
f01005b0:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005b6:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005bb:	b0 00                	mov    $0x0,%al
f01005bd:	89 f2                	mov    %esi,%edx
f01005bf:	ee                   	out    %al,(%dx)
f01005c0:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005c5:	b0 80                	mov    $0x80,%al
f01005c7:	ee                   	out    %al,(%dx)
f01005c8:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005cd:	b0 0c                	mov    $0xc,%al
f01005cf:	89 da                	mov    %ebx,%edx
f01005d1:	ee                   	out    %al,(%dx)
f01005d2:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005d7:	b0 00                	mov    $0x0,%al
f01005d9:	ee                   	out    %al,(%dx)
f01005da:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005df:	b0 03                	mov    $0x3,%al
f01005e1:	ee                   	out    %al,(%dx)
f01005e2:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005e7:	b0 00                	mov    $0x0,%al
f01005e9:	ee                   	out    %al,(%dx)
f01005ea:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005ef:	b0 01                	mov    $0x1,%al
f01005f1:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005f2:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005f7:	ec                   	in     (%dx),%al
f01005f8:	88 c1                	mov    %al,%cl
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005fa:	3c ff                	cmp    $0xff,%al
f01005fc:	0f 95 05 34 25 11 f0 	setne  0xf0112534
f0100603:	89 f2                	mov    %esi,%edx
f0100605:	ec                   	in     (%dx),%al
f0100606:	89 da                	mov    %ebx,%edx
f0100608:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100609:	80 f9 ff             	cmp    $0xff,%cl
f010060c:	75 10                	jne    f010061e <cons_init+0xe2>
		cprintf("Serial port does not exist!\n");
f010060e:	83 ec 0c             	sub    $0xc,%esp
f0100611:	68 70 19 10 f0       	push   $0xf0101970
f0100616:	e8 56 03 00 00       	call   f0100971 <cprintf>
f010061b:	83 c4 10             	add    $0x10,%esp
}
f010061e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100621:	5b                   	pop    %ebx
f0100622:	5e                   	pop    %esi
f0100623:	5d                   	pop    %ebp
f0100624:	c3                   	ret    

f0100625 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100625:	55                   	push   %ebp
f0100626:	89 e5                	mov    %esp,%ebp
f0100628:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010062b:	8b 45 08             	mov    0x8(%ebp),%eax
f010062e:	e8 b9 fc ff ff       	call   f01002ec <cons_putc>
}
f0100633:	c9                   	leave  
f0100634:	c3                   	ret    

f0100635 <getchar>:

int
getchar(void)
{
f0100635:	55                   	push   %ebp
f0100636:	89 e5                	mov    %esp,%ebp
f0100638:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010063b:	e8 b4 fe ff ff       	call   f01004f4 <cons_getc>
f0100640:	85 c0                	test   %eax,%eax
f0100642:	74 f7                	je     f010063b <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100644:	c9                   	leave  
f0100645:	c3                   	ret    

f0100646 <iscons>:

int
iscons(int fdnum)
{
f0100646:	55                   	push   %ebp
f0100647:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100649:	b8 01 00 00 00       	mov    $0x1,%eax
f010064e:	5d                   	pop    %ebp
f010064f:	c3                   	ret    

f0100650 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100650:	55                   	push   %ebp
f0100651:	89 e5                	mov    %esp,%ebp
f0100653:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100656:	68 c0 1b 10 f0       	push   $0xf0101bc0
f010065b:	68 de 1b 10 f0       	push   $0xf0101bde
f0100660:	68 e3 1b 10 f0       	push   $0xf0101be3
f0100665:	e8 07 03 00 00       	call   f0100971 <cprintf>
f010066a:	83 c4 0c             	add    $0xc,%esp
f010066d:	68 a0 1c 10 f0       	push   $0xf0101ca0
f0100672:	68 ec 1b 10 f0       	push   $0xf0101bec
f0100677:	68 e3 1b 10 f0       	push   $0xf0101be3
f010067c:	e8 f0 02 00 00       	call   f0100971 <cprintf>
f0100681:	83 c4 0c             	add    $0xc,%esp
f0100684:	68 c8 1c 10 f0       	push   $0xf0101cc8
f0100689:	68 f5 1b 10 f0       	push   $0xf0101bf5
f010068e:	68 e3 1b 10 f0       	push   $0xf0101be3
f0100693:	e8 d9 02 00 00       	call   f0100971 <cprintf>
	return 0;
}
f0100698:	b8 00 00 00 00       	mov    $0x0,%eax
f010069d:	c9                   	leave  
f010069e:	c3                   	ret    

f010069f <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010069f:	55                   	push   %ebp
f01006a0:	89 e5                	mov    %esp,%ebp
f01006a2:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006a5:	68 ff 1b 10 f0       	push   $0xf0101bff
f01006aa:	e8 c2 02 00 00       	call   f0100971 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006af:	83 c4 08             	add    $0x8,%esp
f01006b2:	68 0c 00 10 00       	push   $0x10000c
f01006b7:	68 08 1d 10 f0       	push   $0xf0101d08
f01006bc:	e8 b0 02 00 00       	call   f0100971 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006c1:	83 c4 0c             	add    $0xc,%esp
f01006c4:	68 0c 00 10 00       	push   $0x10000c
f01006c9:	68 0c 00 10 f0       	push   $0xf010000c
f01006ce:	68 30 1d 10 f0       	push   $0xf0101d30
f01006d3:	e8 99 02 00 00       	call   f0100971 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006d8:	83 c4 0c             	add    $0xc,%esp
f01006db:	68 c5 18 10 00       	push   $0x1018c5
f01006e0:	68 c5 18 10 f0       	push   $0xf01018c5
f01006e5:	68 54 1d 10 f0       	push   $0xf0101d54
f01006ea:	e8 82 02 00 00       	call   f0100971 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ef:	83 c4 0c             	add    $0xc,%esp
f01006f2:	68 00 23 11 00       	push   $0x112300
f01006f7:	68 00 23 11 f0       	push   $0xf0112300
f01006fc:	68 78 1d 10 f0       	push   $0xf0101d78
f0100701:	e8 6b 02 00 00       	call   f0100971 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100706:	83 c4 0c             	add    $0xc,%esp
f0100709:	68 48 29 11 00       	push   $0x112948
f010070e:	68 48 29 11 f0       	push   $0xf0112948
f0100713:	68 9c 1d 10 f0       	push   $0xf0101d9c
f0100718:	e8 54 02 00 00       	call   f0100971 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010071d:	b8 47 2d 11 f0       	mov    $0xf0112d47,%eax
f0100722:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100727:	83 c4 08             	add    $0x8,%esp
f010072a:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f010072f:	89 c2                	mov    %eax,%edx
f0100731:	85 c0                	test   %eax,%eax
f0100733:	79 06                	jns    f010073b <mon_kerninfo+0x9c>
f0100735:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010073b:	c1 fa 0a             	sar    $0xa,%edx
f010073e:	52                   	push   %edx
f010073f:	68 c0 1d 10 f0       	push   $0xf0101dc0
f0100744:	e8 28 02 00 00       	call   f0100971 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100749:	b8 00 00 00 00       	mov    $0x0,%eax
f010074e:	c9                   	leave  
f010074f:	c3                   	ret    

f0100750 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf) 
{
f0100750:	55                   	push   %ebp
f0100751:	89 e5                	mov    %esp,%ebp
f0100753:	56                   	push   %esi
f0100754:	53                   	push   %ebx
f0100755:	83 ec 2c             	sub    $0x2c,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100758:	89 eb                	mov    %ebp,%ebx
	// Your code here.
    uint32_t *ebp = (uint32_t *)read_ebp();
    cprintf("Stack backtrace:\n");
f010075a:	68 18 1c 10 f0       	push   $0xf0101c18
f010075f:	e8 0d 02 00 00       	call   f0100971 <cprintf>
    struct Eipdebuginfo eipInfo;

    while(ebp){
f0100764:	83 c4 10             	add    $0x10,%esp
        cprintf("ebp %x eip %x args %08x %08x %08x %08x %08x\n",ebp,*(ebp+1),*(ebp+2),*(ebp+3),*(ebp+4),*(ebp+5),*(ebp+6));
        debuginfo_eip(*(ebp+1), &eipInfo);
f0100767:	8d 75 e0             	lea    -0x20(%ebp),%esi
	// Your code here.
    uint32_t *ebp = (uint32_t *)read_ebp();
    cprintf("Stack backtrace:\n");
    struct Eipdebuginfo eipInfo;

    while(ebp){
f010076a:	eb 61                	jmp    f01007cd <mon_backtrace+0x7d>
        cprintf("ebp %x eip %x args %08x %08x %08x %08x %08x\n",ebp,*(ebp+1),*(ebp+2),*(ebp+3),*(ebp+4),*(ebp+5),*(ebp+6));
f010076c:	ff 73 18             	pushl  0x18(%ebx)
f010076f:	ff 73 14             	pushl  0x14(%ebx)
f0100772:	ff 73 10             	pushl  0x10(%ebx)
f0100775:	ff 73 0c             	pushl  0xc(%ebx)
f0100778:	ff 73 08             	pushl  0x8(%ebx)
f010077b:	ff 73 04             	pushl  0x4(%ebx)
f010077e:	53                   	push   %ebx
f010077f:	68 ec 1d 10 f0       	push   $0xf0101dec
f0100784:	e8 e8 01 00 00       	call   f0100971 <cprintf>
        debuginfo_eip(*(ebp+1), &eipInfo);
f0100789:	83 c4 18             	add    $0x18,%esp
f010078c:	56                   	push   %esi
f010078d:	ff 73 04             	pushl  0x4(%ebx)
f0100790:	e8 e3 02 00 00       	call   f0100a78 <debuginfo_eip>
        cprintf("\t%x\t%x\n",*(ebp+1),eipInfo.eip_fn_addr);
f0100795:	83 c4 0c             	add    $0xc,%esp
f0100798:	ff 75 f0             	pushl  -0x10(%ebp)
f010079b:	ff 73 04             	pushl  0x4(%ebx)
f010079e:	68 2a 1c 10 f0       	push   $0xf0101c2a
f01007a3:	e8 c9 01 00 00       	call   f0100971 <cprintf>
        cprintf("\t%s:%d: %.*s+%d\n",eipInfo.eip_file,eipInfo.eip_line,eipInfo.eip_fn_namelen, eipInfo.eip_fn_name,(*(ebp+1) - eipInfo.eip_fn_addr));
f01007a8:	83 c4 08             	add    $0x8,%esp
f01007ab:	8b 43 04             	mov    0x4(%ebx),%eax
f01007ae:	2b 45 f0             	sub    -0x10(%ebp),%eax
f01007b1:	50                   	push   %eax
f01007b2:	ff 75 e8             	pushl  -0x18(%ebp)
f01007b5:	ff 75 ec             	pushl  -0x14(%ebp)
f01007b8:	ff 75 e4             	pushl  -0x1c(%ebp)
f01007bb:	ff 75 e0             	pushl  -0x20(%ebp)
f01007be:	68 32 1c 10 f0       	push   $0xf0101c32
f01007c3:	e8 a9 01 00 00       	call   f0100971 <cprintf>
        ebp = (uint32_t *)(*ebp);
f01007c8:	8b 1b                	mov    (%ebx),%ebx
f01007ca:	83 c4 20             	add    $0x20,%esp
	// Your code here.
    uint32_t *ebp = (uint32_t *)read_ebp();
    cprintf("Stack backtrace:\n");
    struct Eipdebuginfo eipInfo;

    while(ebp){
f01007cd:	85 db                	test   %ebx,%ebx
f01007cf:	75 9b                	jne    f010076c <mon_backtrace+0x1c>
        cprintf("\t%x\t%x\n",*(ebp+1),eipInfo.eip_fn_addr);
        cprintf("\t%s:%d: %.*s+%d\n",eipInfo.eip_file,eipInfo.eip_line,eipInfo.eip_fn_namelen, eipInfo.eip_fn_name,(*(ebp+1) - eipInfo.eip_fn_addr));
        ebp = (uint32_t *)(*ebp);
    }
	return 0;
}
f01007d1:	b8 00 00 00 00       	mov    $0x0,%eax
f01007d6:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01007d9:	5b                   	pop    %ebx
f01007da:	5e                   	pop    %esi
f01007db:	5d                   	pop    %ebp
f01007dc:	c3                   	ret    

f01007dd <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007dd:	55                   	push   %ebp
f01007de:	89 e5                	mov    %esp,%ebp
f01007e0:	57                   	push   %edi
f01007e1:	56                   	push   %esi
f01007e2:	53                   	push   %ebx
f01007e3:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007e6:	68 1c 1e 10 f0       	push   $0xf0101e1c
f01007eb:	e8 81 01 00 00       	call   f0100971 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007f0:	c7 04 24 40 1e 10 f0 	movl   $0xf0101e40,(%esp)
f01007f7:	e8 75 01 00 00       	call   f0100971 <cprintf>
    cprintf("%m%s\n%m%s\n%m%s\n", 0x0100, "blue", 0x0200, "green", 0x0400, "red");
f01007fc:	83 c4 0c             	add    $0xc,%esp
f01007ff:	68 43 1c 10 f0       	push   $0xf0101c43
f0100804:	68 00 04 00 00       	push   $0x400
f0100809:	68 47 1c 10 f0       	push   $0xf0101c47
f010080e:	68 00 02 00 00       	push   $0x200
f0100813:	68 4d 1c 10 f0       	push   $0xf0101c4d
f0100818:	68 00 01 00 00       	push   $0x100
f010081d:	68 52 1c 10 f0       	push   $0xf0101c52
f0100822:	e8 4a 01 00 00       	call   f0100971 <cprintf>
f0100827:	83 c4 20             	add    $0x20,%esp


	while (1) {
		buf = readline("K> ");
f010082a:	83 ec 0c             	sub    $0xc,%esp
f010082d:	68 62 1c 10 f0       	push   $0xf0101c62
f0100832:	e8 e0 09 00 00       	call   f0101217 <readline>
f0100837:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100839:	83 c4 10             	add    $0x10,%esp
f010083c:	85 c0                	test   %eax,%eax
f010083e:	74 ea                	je     f010082a <monitor+0x4d>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100840:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100847:	be 00 00 00 00       	mov    $0x0,%esi
f010084c:	eb 0a                	jmp    f0100858 <monitor+0x7b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010084e:	c6 03 00             	movb   $0x0,(%ebx)
f0100851:	89 f7                	mov    %esi,%edi
f0100853:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100856:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100858:	8a 03                	mov    (%ebx),%al
f010085a:	84 c0                	test   %al,%al
f010085c:	74 60                	je     f01008be <monitor+0xe1>
f010085e:	83 ec 08             	sub    $0x8,%esp
f0100861:	0f be c0             	movsbl %al,%eax
f0100864:	50                   	push   %eax
f0100865:	68 66 1c 10 f0       	push   $0xf0101c66
f010086a:	e8 c0 0b 00 00       	call   f010142f <strchr>
f010086f:	83 c4 10             	add    $0x10,%esp
f0100872:	85 c0                	test   %eax,%eax
f0100874:	75 d8                	jne    f010084e <monitor+0x71>
			*buf++ = 0;
		if (*buf == 0)
f0100876:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100879:	74 43                	je     f01008be <monitor+0xe1>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010087b:	83 fe 0f             	cmp    $0xf,%esi
f010087e:	75 14                	jne    f0100894 <monitor+0xb7>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100880:	83 ec 08             	sub    $0x8,%esp
f0100883:	6a 10                	push   $0x10
f0100885:	68 6b 1c 10 f0       	push   $0xf0101c6b
f010088a:	e8 e2 00 00 00       	call   f0100971 <cprintf>
f010088f:	83 c4 10             	add    $0x10,%esp
f0100892:	eb 96                	jmp    f010082a <monitor+0x4d>
			return 0;
		}
		argv[argc++] = buf;
f0100894:	8d 7e 01             	lea    0x1(%esi),%edi
f0100897:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010089b:	eb 01                	jmp    f010089e <monitor+0xc1>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010089d:	43                   	inc    %ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010089e:	8a 03                	mov    (%ebx),%al
f01008a0:	84 c0                	test   %al,%al
f01008a2:	74 b2                	je     f0100856 <monitor+0x79>
f01008a4:	83 ec 08             	sub    $0x8,%esp
f01008a7:	0f be c0             	movsbl %al,%eax
f01008aa:	50                   	push   %eax
f01008ab:	68 66 1c 10 f0       	push   $0xf0101c66
f01008b0:	e8 7a 0b 00 00       	call   f010142f <strchr>
f01008b5:	83 c4 10             	add    $0x10,%esp
f01008b8:	85 c0                	test   %eax,%eax
f01008ba:	74 e1                	je     f010089d <monitor+0xc0>
f01008bc:	eb 98                	jmp    f0100856 <monitor+0x79>
			buf++;
	}
	argv[argc] = 0;
f01008be:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008c5:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008c6:	85 f6                	test   %esi,%esi
f01008c8:	0f 84 5c ff ff ff    	je     f010082a <monitor+0x4d>
f01008ce:	bf 80 1e 10 f0       	mov    $0xf0101e80,%edi
f01008d3:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008d8:	83 ec 08             	sub    $0x8,%esp
f01008db:	ff 37                	pushl  (%edi)
f01008dd:	ff 75 a8             	pushl  -0x58(%ebp)
f01008e0:	e8 f6 0a 00 00       	call   f01013db <strcmp>
f01008e5:	83 c4 10             	add    $0x10,%esp
f01008e8:	85 c0                	test   %eax,%eax
f01008ea:	75 23                	jne    f010090f <monitor+0x132>
			return commands[i].func(argc, argv, tf);
f01008ec:	83 ec 04             	sub    $0x4,%esp
f01008ef:	8d 04 1b             	lea    (%ebx,%ebx,1),%eax
f01008f2:	01 c3                	add    %eax,%ebx
f01008f4:	ff 75 08             	pushl  0x8(%ebp)
f01008f7:	8d 45 a8             	lea    -0x58(%ebp),%eax
f01008fa:	50                   	push   %eax
f01008fb:	56                   	push   %esi
f01008fc:	ff 14 9d 88 1e 10 f0 	call   *-0xfefe178(,%ebx,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100903:	83 c4 10             	add    $0x10,%esp
f0100906:	85 c0                	test   %eax,%eax
f0100908:	78 26                	js     f0100930 <monitor+0x153>
f010090a:	e9 1b ff ff ff       	jmp    f010082a <monitor+0x4d>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f010090f:	43                   	inc    %ebx
f0100910:	83 c7 0c             	add    $0xc,%edi
f0100913:	83 fb 03             	cmp    $0x3,%ebx
f0100916:	75 c0                	jne    f01008d8 <monitor+0xfb>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100918:	83 ec 08             	sub    $0x8,%esp
f010091b:	ff 75 a8             	pushl  -0x58(%ebp)
f010091e:	68 88 1c 10 f0       	push   $0xf0101c88
f0100923:	e8 49 00 00 00       	call   f0100971 <cprintf>
f0100928:	83 c4 10             	add    $0x10,%esp
f010092b:	e9 fa fe ff ff       	jmp    f010082a <monitor+0x4d>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100930:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100933:	5b                   	pop    %ebx
f0100934:	5e                   	pop    %esi
f0100935:	5f                   	pop    %edi
f0100936:	5d                   	pop    %ebp
f0100937:	c3                   	ret    

f0100938 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100938:	55                   	push   %ebp
f0100939:	89 e5                	mov    %esp,%ebp
f010093b:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f010093e:	ff 75 08             	pushl  0x8(%ebp)
f0100941:	e8 df fc ff ff       	call   f0100625 <cputchar>
	*cnt++;
}
f0100946:	83 c4 10             	add    $0x10,%esp
f0100949:	c9                   	leave  
f010094a:	c3                   	ret    

f010094b <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010094b:	55                   	push   %ebp
f010094c:	89 e5                	mov    %esp,%ebp
f010094e:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0100951:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100958:	ff 75 0c             	pushl  0xc(%ebp)
f010095b:	ff 75 08             	pushl  0x8(%ebp)
f010095e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100961:	50                   	push   %eax
f0100962:	68 38 09 10 f0       	push   $0xf0100938
f0100967:	e8 6a 04 00 00       	call   f0100dd6 <vprintfmt>
	return cnt;
}
f010096c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010096f:	c9                   	leave  
f0100970:	c3                   	ret    

f0100971 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100971:	55                   	push   %ebp
f0100972:	89 e5                	mov    %esp,%ebp
f0100974:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100977:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010097a:	50                   	push   %eax
f010097b:	ff 75 08             	pushl  0x8(%ebp)
f010097e:	e8 c8 ff ff ff       	call   f010094b <vcprintf>
	va_end(ap);

	return cnt;
}
f0100983:	c9                   	leave  
f0100984:	c3                   	ret    

f0100985 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100985:	55                   	push   %ebp
f0100986:	89 e5                	mov    %esp,%ebp
f0100988:	57                   	push   %edi
f0100989:	56                   	push   %esi
f010098a:	53                   	push   %ebx
f010098b:	83 ec 14             	sub    $0x14,%esp
f010098e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100991:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100994:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100997:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010099a:	8b 1a                	mov    (%edx),%ebx
f010099c:	8b 01                	mov    (%ecx),%eax
f010099e:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009a1:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01009a8:	eb 7e                	jmp    f0100a28 <stab_binsearch+0xa3>
		int true_m = (l + r) / 2, m = true_m;
f01009aa:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01009ad:	01 d8                	add    %ebx,%eax
f01009af:	89 c6                	mov    %eax,%esi
f01009b1:	c1 ee 1f             	shr    $0x1f,%esi
f01009b4:	01 c6                	add    %eax,%esi
f01009b6:	d1 fe                	sar    %esi
f01009b8:	8d 04 36             	lea    (%esi,%esi,1),%eax
f01009bb:	01 f0                	add    %esi,%eax
f01009bd:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01009c0:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f01009c4:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009c6:	eb 01                	jmp    f01009c9 <stab_binsearch+0x44>
			m--;
f01009c8:	48                   	dec    %eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009c9:	39 c3                	cmp    %eax,%ebx
f01009cb:	7f 0c                	jg     f01009d9 <stab_binsearch+0x54>
f01009cd:	0f b6 0a             	movzbl (%edx),%ecx
f01009d0:	83 ea 0c             	sub    $0xc,%edx
f01009d3:	39 f9                	cmp    %edi,%ecx
f01009d5:	75 f1                	jne    f01009c8 <stab_binsearch+0x43>
f01009d7:	eb 05                	jmp    f01009de <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01009d9:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01009dc:	eb 4a                	jmp    f0100a28 <stab_binsearch+0xa3>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01009de:	8d 14 00             	lea    (%eax,%eax,1),%edx
f01009e1:	01 c2                	add    %eax,%edx
f01009e3:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01009e6:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01009ea:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01009ed:	76 11                	jbe    f0100a00 <stab_binsearch+0x7b>
			*region_left = m;
f01009ef:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01009f2:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01009f4:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009f7:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01009fe:	eb 28                	jmp    f0100a28 <stab_binsearch+0xa3>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a00:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a03:	73 12                	jae    f0100a17 <stab_binsearch+0x92>
			*region_right = m - 1;
f0100a05:	48                   	dec    %eax
f0100a06:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a09:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a0c:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a0e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a15:	eb 11                	jmp    f0100a28 <stab_binsearch+0xa3>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a17:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a1a:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100a1c:	ff 45 0c             	incl   0xc(%ebp)
f0100a1f:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a21:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100a28:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a2b:	0f 8e 79 ff ff ff    	jle    f01009aa <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a31:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100a35:	75 0d                	jne    f0100a44 <stab_binsearch+0xbf>
		*region_right = *region_left - 1;
f0100a37:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a3a:	8b 00                	mov    (%eax),%eax
f0100a3c:	48                   	dec    %eax
f0100a3d:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100a40:	89 07                	mov    %eax,(%edi)
f0100a42:	eb 2c                	jmp    f0100a70 <stab_binsearch+0xeb>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a44:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a47:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a49:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a4c:	8b 0e                	mov    (%esi),%ecx
f0100a4e:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100a51:	01 c2                	add    %eax,%edx
f0100a53:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100a56:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a5a:	eb 01                	jmp    f0100a5d <stab_binsearch+0xd8>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a5c:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a5d:	39 c8                	cmp    %ecx,%eax
f0100a5f:	7e 0a                	jle    f0100a6b <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
f0100a61:	0f b6 1a             	movzbl (%edx),%ebx
f0100a64:	83 ea 0c             	sub    $0xc,%edx
f0100a67:	39 df                	cmp    %ebx,%edi
f0100a69:	75 f1                	jne    f0100a5c <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a6b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100a6e:	89 07                	mov    %eax,(%edi)
	}
}
f0100a70:	83 c4 14             	add    $0x14,%esp
f0100a73:	5b                   	pop    %ebx
f0100a74:	5e                   	pop    %esi
f0100a75:	5f                   	pop    %edi
f0100a76:	5d                   	pop    %ebp
f0100a77:	c3                   	ret    

f0100a78 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a78:	55                   	push   %ebp
f0100a79:	89 e5                	mov    %esp,%ebp
f0100a7b:	57                   	push   %edi
f0100a7c:	56                   	push   %esi
f0100a7d:	53                   	push   %ebx
f0100a7e:	83 ec 3c             	sub    $0x3c,%esp
f0100a81:	8b 75 08             	mov    0x8(%ebp),%esi
f0100a84:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100a87:	c7 03 a4 1e 10 f0    	movl   $0xf0101ea4,(%ebx)
	info->eip_line = 0;
f0100a8d:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100a94:	c7 43 08 a4 1e 10 f0 	movl   $0xf0101ea4,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100a9b:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100aa2:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100aa5:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100aac:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100ab2:	76 11                	jbe    f0100ac5 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100ab4:	b8 11 72 10 f0       	mov    $0xf0107211,%eax
f0100ab9:	3d 41 59 10 f0       	cmp    $0xf0105941,%eax
f0100abe:	77 19                	ja     f0100ad9 <debuginfo_eip+0x61>
f0100ac0:	e9 c8 01 00 00       	jmp    f0100c8d <debuginfo_eip+0x215>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100ac5:	83 ec 04             	sub    $0x4,%esp
f0100ac8:	68 ae 1e 10 f0       	push   $0xf0101eae
f0100acd:	6a 7f                	push   $0x7f
f0100acf:	68 bb 1e 10 f0       	push   $0xf0101ebb
f0100ad4:	e8 0d f6 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100ad9:	80 3d 10 72 10 f0 00 	cmpb   $0x0,0xf0107210
f0100ae0:	0f 85 ae 01 00 00    	jne    f0100c94 <debuginfo_eip+0x21c>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100ae6:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100aed:	b8 40 59 10 f0       	mov    $0xf0105940,%eax
f0100af2:	2d dc 20 10 f0       	sub    $0xf01020dc,%eax
f0100af7:	c1 f8 02             	sar    $0x2,%eax
f0100afa:	8d 14 80             	lea    (%eax,%eax,4),%edx
f0100afd:	8d 14 90             	lea    (%eax,%edx,4),%edx
f0100b00:	8d 0c 90             	lea    (%eax,%edx,4),%ecx
f0100b03:	89 ca                	mov    %ecx,%edx
f0100b05:	c1 e2 08             	shl    $0x8,%edx
f0100b08:	01 d1                	add    %edx,%ecx
f0100b0a:	89 ca                	mov    %ecx,%edx
f0100b0c:	c1 e2 10             	shl    $0x10,%edx
f0100b0f:	01 ca                	add    %ecx,%edx
f0100b11:	01 d2                	add    %edx,%edx
f0100b13:	8d 44 10 ff          	lea    -0x1(%eax,%edx,1),%eax
f0100b17:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b1a:	83 ec 08             	sub    $0x8,%esp
f0100b1d:	56                   	push   %esi
f0100b1e:	6a 64                	push   $0x64
f0100b20:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b23:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b26:	b8 dc 20 10 f0       	mov    $0xf01020dc,%eax
f0100b2b:	e8 55 fe ff ff       	call   f0100985 <stab_binsearch>
	if (lfile == 0)
f0100b30:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b33:	83 c4 10             	add    $0x10,%esp
f0100b36:	85 c0                	test   %eax,%eax
f0100b38:	0f 84 5d 01 00 00    	je     f0100c9b <debuginfo_eip+0x223>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b3e:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b41:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b44:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b47:	83 ec 08             	sub    $0x8,%esp
f0100b4a:	56                   	push   %esi
f0100b4b:	6a 24                	push   $0x24
f0100b4d:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b50:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b53:	b8 dc 20 10 f0       	mov    $0xf01020dc,%eax
f0100b58:	e8 28 fe ff ff       	call   f0100985 <stab_binsearch>

	if (lfun <= rfun) {
f0100b5d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100b60:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100b63:	83 c4 10             	add    $0x10,%esp
f0100b66:	39 d0                	cmp    %edx,%eax
f0100b68:	7f 42                	jg     f0100bac <debuginfo_eip+0x134>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b6a:	8d 0c 00             	lea    (%eax,%eax,1),%ecx
f0100b6d:	01 c1                	add    %eax,%ecx
f0100b6f:	c1 e1 02             	shl    $0x2,%ecx
f0100b72:	8d b9 dc 20 10 f0    	lea    -0xfefdf24(%ecx),%edi
f0100b78:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100b7b:	8b 89 dc 20 10 f0    	mov    -0xfefdf24(%ecx),%ecx
f0100b81:	bf 11 72 10 f0       	mov    $0xf0107211,%edi
f0100b86:	81 ef 41 59 10 f0    	sub    $0xf0105941,%edi
f0100b8c:	39 f9                	cmp    %edi,%ecx
f0100b8e:	73 09                	jae    f0100b99 <debuginfo_eip+0x121>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b90:	81 c1 41 59 10 f0    	add    $0xf0105941,%ecx
f0100b96:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100b99:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100b9c:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100b9f:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100ba2:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100ba4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100ba7:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100baa:	eb 0f                	jmp    f0100bbb <debuginfo_eip+0x143>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100bac:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100baf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bb2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100bb5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bb8:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100bbb:	83 ec 08             	sub    $0x8,%esp
f0100bbe:	6a 3a                	push   $0x3a
f0100bc0:	ff 73 08             	pushl  0x8(%ebx)
f0100bc3:	e8 84 08 00 00       	call   f010144c <strfind>
f0100bc8:	2b 43 08             	sub    0x8(%ebx),%eax
f0100bcb:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
    stab_binsearch(stabs,&lline,&rline,N_SLINE,addr);
f0100bce:	83 c4 08             	add    $0x8,%esp
f0100bd1:	56                   	push   %esi
f0100bd2:	6a 44                	push   $0x44
f0100bd4:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100bd7:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100bda:	b8 dc 20 10 f0       	mov    $0xf01020dc,%eax
f0100bdf:	e8 a1 fd ff ff       	call   f0100985 <stab_binsearch>
    if (lline <= rline){
f0100be4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100be7:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0100bea:	83 c4 10             	add    $0x10,%esp
f0100bed:	39 d0                	cmp    %edx,%eax
f0100bef:	7f 12                	jg     f0100c03 <debuginfo_eip+0x18b>
        info->eip_line = stabs[rline].n_desc;
f0100bf1:	8d 0c 12             	lea    (%edx,%edx,1),%ecx
f0100bf4:	01 ca                	add    %ecx,%edx
f0100bf6:	0f b7 14 95 e2 20 10 	movzwl -0xfefdf1e(,%edx,4),%edx
f0100bfd:	f0 
f0100bfe:	89 53 04             	mov    %edx,0x4(%ebx)
f0100c01:	eb 07                	jmp    f0100c0a <debuginfo_eip+0x192>
    } else{
        info->eip_line = -1;
f0100c03:	c7 43 04 ff ff ff ff 	movl   $0xffffffff,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c0a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100c0d:	89 c2                	mov    %eax,%edx
f0100c0f:	8d 0c 00             	lea    (%eax,%eax,1),%ecx
f0100c12:	01 c8                	add    %ecx,%eax
f0100c14:	8d 04 85 e4 20 10 f0 	lea    -0xfefdf1c(,%eax,4),%eax
f0100c1b:	eb 04                	jmp    f0100c21 <debuginfo_eip+0x1a9>
f0100c1d:	4a                   	dec    %edx
f0100c1e:	83 e8 0c             	sub    $0xc,%eax
f0100c21:	39 d7                	cmp    %edx,%edi
f0100c23:	7f 34                	jg     f0100c59 <debuginfo_eip+0x1e1>
	       && stabs[lline].n_type != N_SOL
f0100c25:	8a 48 fc             	mov    -0x4(%eax),%cl
f0100c28:	80 f9 84             	cmp    $0x84,%cl
f0100c2b:	74 0a                	je     f0100c37 <debuginfo_eip+0x1bf>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c2d:	80 f9 64             	cmp    $0x64,%cl
f0100c30:	75 eb                	jne    f0100c1d <debuginfo_eip+0x1a5>
f0100c32:	83 38 00             	cmpl   $0x0,(%eax)
f0100c35:	74 e6                	je     f0100c1d <debuginfo_eip+0x1a5>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c37:	8d 04 12             	lea    (%edx,%edx,1),%eax
f0100c3a:	01 c2                	add    %eax,%edx
f0100c3c:	8b 14 95 dc 20 10 f0 	mov    -0xfefdf24(,%edx,4),%edx
f0100c43:	b8 11 72 10 f0       	mov    $0xf0107211,%eax
f0100c48:	2d 41 59 10 f0       	sub    $0xf0105941,%eax
f0100c4d:	39 c2                	cmp    %eax,%edx
f0100c4f:	73 08                	jae    f0100c59 <debuginfo_eip+0x1e1>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c51:	81 c2 41 59 10 f0    	add    $0xf0105941,%edx
f0100c57:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c59:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c5c:	8b 75 d8             	mov    -0x28(%ebp),%esi
f0100c5f:	39 f2                	cmp    %esi,%edx
f0100c61:	7d 3f                	jge    f0100ca2 <debuginfo_eip+0x22a>
		for (lline = lfun + 1;
f0100c63:	42                   	inc    %edx
f0100c64:	89 d0                	mov    %edx,%eax
f0100c66:	8d 0c 12             	lea    (%edx,%edx,1),%ecx
f0100c69:	01 ca                	add    %ecx,%edx
f0100c6b:	8d 14 95 e0 20 10 f0 	lea    -0xfefdf20(,%edx,4),%edx
f0100c72:	eb 03                	jmp    f0100c77 <debuginfo_eip+0x1ff>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100c74:	ff 43 14             	incl   0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c77:	39 c6                	cmp    %eax,%esi
f0100c79:	7e 2e                	jle    f0100ca9 <debuginfo_eip+0x231>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c7b:	8a 0a                	mov    (%edx),%cl
f0100c7d:	40                   	inc    %eax
f0100c7e:	83 c2 0c             	add    $0xc,%edx
f0100c81:	80 f9 a0             	cmp    $0xa0,%cl
f0100c84:	74 ee                	je     f0100c74 <debuginfo_eip+0x1fc>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c86:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c8b:	eb 21                	jmp    f0100cae <debuginfo_eip+0x236>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100c8d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c92:	eb 1a                	jmp    f0100cae <debuginfo_eip+0x236>
f0100c94:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c99:	eb 13                	jmp    f0100cae <debuginfo_eip+0x236>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100c9b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ca0:	eb 0c                	jmp    f0100cae <debuginfo_eip+0x236>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100ca2:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ca7:	eb 05                	jmp    f0100cae <debuginfo_eip+0x236>
f0100ca9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100cae:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100cb1:	5b                   	pop    %ebx
f0100cb2:	5e                   	pop    %esi
f0100cb3:	5f                   	pop    %edi
f0100cb4:	5d                   	pop    %ebp
f0100cb5:	c3                   	ret    

f0100cb6 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100cb6:	55                   	push   %ebp
f0100cb7:	89 e5                	mov    %esp,%ebp
f0100cb9:	57                   	push   %edi
f0100cba:	56                   	push   %esi
f0100cbb:	53                   	push   %ebx
f0100cbc:	83 ec 1c             	sub    $0x1c,%esp
f0100cbf:	89 c7                	mov    %eax,%edi
f0100cc1:	89 d6                	mov    %edx,%esi
f0100cc3:	8b 45 08             	mov    0x8(%ebp),%eax
f0100cc6:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100cc9:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100ccc:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100ccf:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100cd2:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100cd7:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100cda:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100cdd:	39 d3                	cmp    %edx,%ebx
f0100cdf:	72 05                	jb     f0100ce6 <printnum+0x30>
f0100ce1:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100ce4:	77 45                	ja     f0100d2b <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100ce6:	83 ec 0c             	sub    $0xc,%esp
f0100ce9:	ff 75 18             	pushl  0x18(%ebp)
f0100cec:	8b 45 14             	mov    0x14(%ebp),%eax
f0100cef:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100cf2:	53                   	push   %ebx
f0100cf3:	ff 75 10             	pushl  0x10(%ebp)
f0100cf6:	83 ec 08             	sub    $0x8,%esp
f0100cf9:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100cfc:	ff 75 e0             	pushl  -0x20(%ebp)
f0100cff:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d02:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d05:	e8 5a 09 00 00       	call   f0101664 <__udivdi3>
f0100d0a:	83 c4 18             	add    $0x18,%esp
f0100d0d:	52                   	push   %edx
f0100d0e:	50                   	push   %eax
f0100d0f:	89 f2                	mov    %esi,%edx
f0100d11:	89 f8                	mov    %edi,%eax
f0100d13:	e8 9e ff ff ff       	call   f0100cb6 <printnum>
f0100d18:	83 c4 20             	add    $0x20,%esp
f0100d1b:	eb 16                	jmp    f0100d33 <printnum+0x7d>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d1d:	83 ec 08             	sub    $0x8,%esp
f0100d20:	56                   	push   %esi
f0100d21:	ff 75 18             	pushl  0x18(%ebp)
f0100d24:	ff d7                	call   *%edi
f0100d26:	83 c4 10             	add    $0x10,%esp
f0100d29:	eb 03                	jmp    f0100d2e <printnum+0x78>
f0100d2b:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d2e:	4b                   	dec    %ebx
f0100d2f:	85 db                	test   %ebx,%ebx
f0100d31:	7f ea                	jg     f0100d1d <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d33:	83 ec 08             	sub    $0x8,%esp
f0100d36:	56                   	push   %esi
f0100d37:	83 ec 04             	sub    $0x4,%esp
f0100d3a:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d3d:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d40:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d43:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d46:	e8 29 0a 00 00       	call   f0101774 <__umoddi3>
f0100d4b:	83 c4 14             	add    $0x14,%esp
f0100d4e:	0f be 80 c9 1e 10 f0 	movsbl -0xfefe137(%eax),%eax
f0100d55:	50                   	push   %eax
f0100d56:	ff d7                	call   *%edi
}
f0100d58:	83 c4 10             	add    $0x10,%esp
f0100d5b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d5e:	5b                   	pop    %ebx
f0100d5f:	5e                   	pop    %esi
f0100d60:	5f                   	pop    %edi
f0100d61:	5d                   	pop    %ebp
f0100d62:	c3                   	ret    

f0100d63 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100d63:	55                   	push   %ebp
f0100d64:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100d66:	83 fa 01             	cmp    $0x1,%edx
f0100d69:	7e 0e                	jle    f0100d79 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100d6b:	8b 10                	mov    (%eax),%edx
f0100d6d:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100d70:	89 08                	mov    %ecx,(%eax)
f0100d72:	8b 02                	mov    (%edx),%eax
f0100d74:	8b 52 04             	mov    0x4(%edx),%edx
f0100d77:	eb 22                	jmp    f0100d9b <getuint+0x38>
	else if (lflag)
f0100d79:	85 d2                	test   %edx,%edx
f0100d7b:	74 10                	je     f0100d8d <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100d7d:	8b 10                	mov    (%eax),%edx
f0100d7f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d82:	89 08                	mov    %ecx,(%eax)
f0100d84:	8b 02                	mov    (%edx),%eax
f0100d86:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d8b:	eb 0e                	jmp    f0100d9b <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100d8d:	8b 10                	mov    (%eax),%edx
f0100d8f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d92:	89 08                	mov    %ecx,(%eax)
f0100d94:	8b 02                	mov    (%edx),%eax
f0100d96:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100d9b:	5d                   	pop    %ebp
f0100d9c:	c3                   	ret    

f0100d9d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100d9d:	55                   	push   %ebp
f0100d9e:	89 e5                	mov    %esp,%ebp
f0100da0:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100da3:	ff 40 08             	incl   0x8(%eax)
	if (b->buf < b->ebuf)
f0100da6:	8b 10                	mov    (%eax),%edx
f0100da8:	3b 50 04             	cmp    0x4(%eax),%edx
f0100dab:	73 0a                	jae    f0100db7 <sprintputch+0x1a>
		*b->buf++ = ch;
f0100dad:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100db0:	89 08                	mov    %ecx,(%eax)
f0100db2:	8b 45 08             	mov    0x8(%ebp),%eax
f0100db5:	88 02                	mov    %al,(%edx)
}
f0100db7:	5d                   	pop    %ebp
f0100db8:	c3                   	ret    

f0100db9 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100db9:	55                   	push   %ebp
f0100dba:	89 e5                	mov    %esp,%ebp
f0100dbc:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100dbf:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100dc2:	50                   	push   %eax
f0100dc3:	ff 75 10             	pushl  0x10(%ebp)
f0100dc6:	ff 75 0c             	pushl  0xc(%ebp)
f0100dc9:	ff 75 08             	pushl  0x8(%ebp)
f0100dcc:	e8 05 00 00 00       	call   f0100dd6 <vprintfmt>
	va_end(ap);
}
f0100dd1:	83 c4 10             	add    $0x10,%esp
f0100dd4:	c9                   	leave  
f0100dd5:	c3                   	ret    

f0100dd6 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100dd6:	55                   	push   %ebp
f0100dd7:	89 e5                	mov    %esp,%ebp
f0100dd9:	57                   	push   %edi
f0100dda:	56                   	push   %esi
f0100ddb:	53                   	push   %ebx
f0100ddc:	83 ec 2c             	sub    $0x2c,%esp
f0100ddf:	8b 75 08             	mov    0x8(%ebp),%esi
f0100de2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100de5:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100de8:	eb 1d                	jmp    f0100e07 <vprintfmt+0x31>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0'){
f0100dea:	85 c0                	test   %eax,%eax
f0100dec:	75 0f                	jne    f0100dfd <vprintfmt+0x27>
                ccolor = 0x0700;
f0100dee:	c7 05 44 29 11 f0 00 	movl   $0x700,0xf0112944
f0100df5:	07 00 00 
				return;
f0100df8:	e9 a3 03 00 00       	jmp    f01011a0 <vprintfmt+0x3ca>
            }
			putch(ch, putdat);
f0100dfd:	83 ec 08             	sub    $0x8,%esp
f0100e00:	53                   	push   %ebx
f0100e01:	50                   	push   %eax
f0100e02:	ff d6                	call   *%esi
f0100e04:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100e07:	47                   	inc    %edi
f0100e08:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100e0c:	83 f8 25             	cmp    $0x25,%eax
f0100e0f:	75 d9                	jne    f0100dea <vprintfmt+0x14>
f0100e11:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100e15:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100e1c:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100e23:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100e2a:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e2f:	eb 07                	jmp    f0100e38 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e31:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100e34:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e38:	8d 47 01             	lea    0x1(%edi),%eax
f0100e3b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100e3e:	0f b6 0f             	movzbl (%edi),%ecx
f0100e41:	8a 07                	mov    (%edi),%al
f0100e43:	83 e8 23             	sub    $0x23,%eax
f0100e46:	3c 55                	cmp    $0x55,%al
f0100e48:	0f 87 39 03 00 00    	ja     f0101187 <vprintfmt+0x3b1>
f0100e4e:	0f b6 c0             	movzbl %al,%eax
f0100e51:	ff 24 85 58 1f 10 f0 	jmp    *-0xfefe0a8(,%eax,4)
f0100e58:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100e5b:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100e5f:	eb d7                	jmp    f0100e38 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e61:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e64:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e69:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100e6c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100e6f:	01 c0                	add    %eax,%eax
f0100e71:	8d 44 01 d0          	lea    -0x30(%ecx,%eax,1),%eax
				ch = *fmt;
f0100e75:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0100e78:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0100e7b:	83 fa 09             	cmp    $0x9,%edx
f0100e7e:	77 34                	ja     f0100eb4 <vprintfmt+0xde>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e80:	47                   	inc    %edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100e81:	eb e9                	jmp    f0100e6c <vprintfmt+0x96>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100e83:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e86:	8d 48 04             	lea    0x4(%eax),%ecx
f0100e89:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100e8c:	8b 00                	mov    (%eax),%eax
f0100e8e:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e91:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100e94:	eb 24                	jmp    f0100eba <vprintfmt+0xe4>
f0100e96:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100e9a:	79 07                	jns    f0100ea3 <vprintfmt+0xcd>
f0100e9c:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ea3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100ea6:	eb 90                	jmp    f0100e38 <vprintfmt+0x62>
f0100ea8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100eab:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100eb2:	eb 84                	jmp    f0100e38 <vprintfmt+0x62>
f0100eb4:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100eb7:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100eba:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100ebe:	0f 89 74 ff ff ff    	jns    f0100e38 <vprintfmt+0x62>
				width = precision, precision = -1;
f0100ec4:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100ec7:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100eca:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100ed1:	e9 62 ff ff ff       	jmp    f0100e38 <vprintfmt+0x62>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100ed6:	42                   	inc    %edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ed7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100eda:	e9 59 ff ff ff       	jmp    f0100e38 <vprintfmt+0x62>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100edf:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ee2:	8d 50 04             	lea    0x4(%eax),%edx
f0100ee5:	89 55 14             	mov    %edx,0x14(%ebp)
f0100ee8:	83 ec 08             	sub    $0x8,%esp
f0100eeb:	53                   	push   %ebx
f0100eec:	ff 30                	pushl  (%eax)
f0100eee:	ff d6                	call   *%esi
			break;
f0100ef0:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ef3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100ef6:	e9 0c ff ff ff       	jmp    f0100e07 <vprintfmt+0x31>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100efb:	8b 45 14             	mov    0x14(%ebp),%eax
f0100efe:	8d 50 04             	lea    0x4(%eax),%edx
f0100f01:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f04:	8b 00                	mov    (%eax),%eax
f0100f06:	85 c0                	test   %eax,%eax
f0100f08:	79 02                	jns    f0100f0c <vprintfmt+0x136>
f0100f0a:	f7 d8                	neg    %eax
f0100f0c:	89 c2                	mov    %eax,%edx
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f0e:	83 f8 06             	cmp    $0x6,%eax
f0100f11:	7f 0b                	jg     f0100f1e <vprintfmt+0x148>
f0100f13:	8b 04 85 b0 20 10 f0 	mov    -0xfefdf50(,%eax,4),%eax
f0100f1a:	85 c0                	test   %eax,%eax
f0100f1c:	75 18                	jne    f0100f36 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0100f1e:	52                   	push   %edx
f0100f1f:	68 e1 1e 10 f0       	push   $0xf0101ee1
f0100f24:	53                   	push   %ebx
f0100f25:	56                   	push   %esi
f0100f26:	e8 8e fe ff ff       	call   f0100db9 <printfmt>
f0100f2b:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f2e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100f31:	e9 d1 fe ff ff       	jmp    f0100e07 <vprintfmt+0x31>
			else
				printfmt(putch, putdat, "%s", p);
f0100f36:	50                   	push   %eax
f0100f37:	68 ea 1e 10 f0       	push   $0xf0101eea
f0100f3c:	53                   	push   %ebx
f0100f3d:	56                   	push   %esi
f0100f3e:	e8 76 fe ff ff       	call   f0100db9 <printfmt>
f0100f43:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f46:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f49:	e9 b9 fe ff ff       	jmp    f0100e07 <vprintfmt+0x31>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f4e:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f51:	8d 50 04             	lea    0x4(%eax),%edx
f0100f54:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f57:	8b 38                	mov    (%eax),%edi
f0100f59:	85 ff                	test   %edi,%edi
f0100f5b:	75 05                	jne    f0100f62 <vprintfmt+0x18c>
				p = "(null)";
f0100f5d:	bf da 1e 10 f0       	mov    $0xf0101eda,%edi
			if (width > 0 && padc != '-')
f0100f62:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100f66:	0f 8e 90 00 00 00    	jle    f0100ffc <vprintfmt+0x226>
f0100f6c:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100f70:	0f 84 8e 00 00 00    	je     f0101004 <vprintfmt+0x22e>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f76:	83 ec 08             	sub    $0x8,%esp
f0100f79:	ff 75 d0             	pushl  -0x30(%ebp)
f0100f7c:	57                   	push   %edi
f0100f7d:	e8 9b 03 00 00       	call   f010131d <strnlen>
f0100f82:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100f85:	29 c1                	sub    %eax,%ecx
f0100f87:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0100f8a:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0100f8d:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0100f91:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f94:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100f97:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f99:	eb 0d                	jmp    f0100fa8 <vprintfmt+0x1d2>
					putch(padc, putdat);
f0100f9b:	83 ec 08             	sub    $0x8,%esp
f0100f9e:	53                   	push   %ebx
f0100f9f:	ff 75 e0             	pushl  -0x20(%ebp)
f0100fa2:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fa4:	4f                   	dec    %edi
f0100fa5:	83 c4 10             	add    $0x10,%esp
f0100fa8:	85 ff                	test   %edi,%edi
f0100faa:	7f ef                	jg     f0100f9b <vprintfmt+0x1c5>
f0100fac:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100faf:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0100fb2:	89 c8                	mov    %ecx,%eax
f0100fb4:	85 c9                	test   %ecx,%ecx
f0100fb6:	79 05                	jns    f0100fbd <vprintfmt+0x1e7>
f0100fb8:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fbd:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0100fc0:	29 c1                	sub    %eax,%ecx
f0100fc2:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100fc5:	89 75 08             	mov    %esi,0x8(%ebp)
f0100fc8:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100fcb:	eb 3d                	jmp    f010100a <vprintfmt+0x234>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100fcd:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100fd1:	74 19                	je     f0100fec <vprintfmt+0x216>
f0100fd3:	0f be c0             	movsbl %al,%eax
f0100fd6:	83 e8 20             	sub    $0x20,%eax
f0100fd9:	83 f8 5e             	cmp    $0x5e,%eax
f0100fdc:	76 0e                	jbe    f0100fec <vprintfmt+0x216>
					putch('?', putdat);
f0100fde:	83 ec 08             	sub    $0x8,%esp
f0100fe1:	53                   	push   %ebx
f0100fe2:	6a 3f                	push   $0x3f
f0100fe4:	ff 55 08             	call   *0x8(%ebp)
f0100fe7:	83 c4 10             	add    $0x10,%esp
f0100fea:	eb 0b                	jmp    f0100ff7 <vprintfmt+0x221>
				else
					putch(ch, putdat);
f0100fec:	83 ec 08             	sub    $0x8,%esp
f0100fef:	53                   	push   %ebx
f0100ff0:	52                   	push   %edx
f0100ff1:	ff 55 08             	call   *0x8(%ebp)
f0100ff4:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100ff7:	ff 4d e0             	decl   -0x20(%ebp)
f0100ffa:	eb 0e                	jmp    f010100a <vprintfmt+0x234>
f0100ffc:	89 75 08             	mov    %esi,0x8(%ebp)
f0100fff:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101002:	eb 06                	jmp    f010100a <vprintfmt+0x234>
f0101004:	89 75 08             	mov    %esi,0x8(%ebp)
f0101007:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010100a:	47                   	inc    %edi
f010100b:	8a 47 ff             	mov    -0x1(%edi),%al
f010100e:	0f be d0             	movsbl %al,%edx
f0101011:	85 d2                	test   %edx,%edx
f0101013:	74 1d                	je     f0101032 <vprintfmt+0x25c>
f0101015:	85 f6                	test   %esi,%esi
f0101017:	78 b4                	js     f0100fcd <vprintfmt+0x1f7>
f0101019:	4e                   	dec    %esi
f010101a:	79 b1                	jns    f0100fcd <vprintfmt+0x1f7>
f010101c:	8b 75 08             	mov    0x8(%ebp),%esi
f010101f:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101022:	eb 14                	jmp    f0101038 <vprintfmt+0x262>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101024:	83 ec 08             	sub    $0x8,%esp
f0101027:	53                   	push   %ebx
f0101028:	6a 20                	push   $0x20
f010102a:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010102c:	4f                   	dec    %edi
f010102d:	83 c4 10             	add    $0x10,%esp
f0101030:	eb 06                	jmp    f0101038 <vprintfmt+0x262>
f0101032:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101035:	8b 75 08             	mov    0x8(%ebp),%esi
f0101038:	85 ff                	test   %edi,%edi
f010103a:	7f e8                	jg     f0101024 <vprintfmt+0x24e>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010103c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010103f:	e9 c3 fd ff ff       	jmp    f0100e07 <vprintfmt+0x31>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101044:	83 fa 01             	cmp    $0x1,%edx
f0101047:	7e 16                	jle    f010105f <vprintfmt+0x289>
		return va_arg(*ap, long long);
f0101049:	8b 45 14             	mov    0x14(%ebp),%eax
f010104c:	8d 50 08             	lea    0x8(%eax),%edx
f010104f:	89 55 14             	mov    %edx,0x14(%ebp)
f0101052:	8b 50 04             	mov    0x4(%eax),%edx
f0101055:	8b 00                	mov    (%eax),%eax
f0101057:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010105a:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010105d:	eb 32                	jmp    f0101091 <vprintfmt+0x2bb>
	else if (lflag)
f010105f:	85 d2                	test   %edx,%edx
f0101061:	74 18                	je     f010107b <vprintfmt+0x2a5>
		return va_arg(*ap, long);
f0101063:	8b 45 14             	mov    0x14(%ebp),%eax
f0101066:	8d 50 04             	lea    0x4(%eax),%edx
f0101069:	89 55 14             	mov    %edx,0x14(%ebp)
f010106c:	8b 00                	mov    (%eax),%eax
f010106e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101071:	89 c1                	mov    %eax,%ecx
f0101073:	c1 f9 1f             	sar    $0x1f,%ecx
f0101076:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101079:	eb 16                	jmp    f0101091 <vprintfmt+0x2bb>
	else
		return va_arg(*ap, int);
f010107b:	8b 45 14             	mov    0x14(%ebp),%eax
f010107e:	8d 50 04             	lea    0x4(%eax),%edx
f0101081:	89 55 14             	mov    %edx,0x14(%ebp)
f0101084:	8b 00                	mov    (%eax),%eax
f0101086:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101089:	89 c1                	mov    %eax,%ecx
f010108b:	c1 f9 1f             	sar    $0x1f,%ecx
f010108e:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101091:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101094:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
f0101097:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010109b:	79 76                	jns    f0101113 <vprintfmt+0x33d>
				putch('-', putdat);
f010109d:	83 ec 08             	sub    $0x8,%esp
f01010a0:	53                   	push   %ebx
f01010a1:	6a 2d                	push   $0x2d
f01010a3:	ff d6                	call   *%esi
				num = -(long long) num;
f01010a5:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01010a8:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01010ab:	f7 d8                	neg    %eax
f01010ad:	83 d2 00             	adc    $0x0,%edx
f01010b0:	f7 da                	neg    %edx
f01010b2:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f01010b5:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01010ba:	eb 5c                	jmp    f0101118 <vprintfmt+0x342>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01010bc:	8d 45 14             	lea    0x14(%ebp),%eax
f01010bf:	e8 9f fc ff ff       	call   f0100d63 <getuint>
			base = 10;
f01010c4:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01010c9:	eb 4d                	jmp    f0101118 <vprintfmt+0x342>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
            num = getuint(&ap,lflag);
f01010cb:	8d 45 14             	lea    0x14(%ebp),%eax
f01010ce:	e8 90 fc ff ff       	call   f0100d63 <getuint>
            base = 8;
f01010d3:	b9 08 00 00 00       	mov    $0x8,%ecx
            goto number;
f01010d8:	eb 3e                	jmp    f0101118 <vprintfmt+0x342>
			//putch('X', putdat);
			//break;

		// pointer
		case 'p':
			putch('0', putdat);
f01010da:	83 ec 08             	sub    $0x8,%esp
f01010dd:	53                   	push   %ebx
f01010de:	6a 30                	push   $0x30
f01010e0:	ff d6                	call   *%esi
			putch('x', putdat);
f01010e2:	83 c4 08             	add    $0x8,%esp
f01010e5:	53                   	push   %ebx
f01010e6:	6a 78                	push   $0x78
f01010e8:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01010ea:	8b 45 14             	mov    0x14(%ebp),%eax
f01010ed:	8d 50 04             	lea    0x4(%eax),%edx
f01010f0:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01010f3:	8b 00                	mov    (%eax),%eax
f01010f5:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01010fa:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01010fd:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101102:	eb 14                	jmp    f0101118 <vprintfmt+0x342>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101104:	8d 45 14             	lea    0x14(%ebp),%eax
f0101107:	e8 57 fc ff ff       	call   f0100d63 <getuint>
			base = 16;
f010110c:	b9 10 00 00 00       	mov    $0x10,%ecx
f0101111:	eb 05                	jmp    f0101118 <vprintfmt+0x342>
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101113:	b9 0a 00 00 00       	mov    $0xa,%ecx
			num = getuint(&ap, lflag);
			base = 16;


		number:
			printnum(putch, putdat, num, base, width, padc);
f0101118:	83 ec 0c             	sub    $0xc,%esp
f010111b:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f010111f:	57                   	push   %edi
f0101120:	ff 75 e0             	pushl  -0x20(%ebp)
f0101123:	51                   	push   %ecx
f0101124:	52                   	push   %edx
f0101125:	50                   	push   %eax
f0101126:	89 da                	mov    %ebx,%edx
f0101128:	89 f0                	mov    %esi,%eax
f010112a:	e8 87 fb ff ff       	call   f0100cb6 <printnum>
			break;
f010112f:	83 c4 20             	add    $0x20,%esp
f0101132:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101135:	e9 cd fc ff ff       	jmp    f0100e07 <vprintfmt+0x31>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010113a:	83 ec 08             	sub    $0x8,%esp
f010113d:	53                   	push   %ebx
f010113e:	51                   	push   %ecx
f010113f:	ff d6                	call   *%esi
			break;
f0101141:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101144:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101147:	e9 bb fc ff ff       	jmp    f0100e07 <vprintfmt+0x31>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010114c:	83 fa 01             	cmp    $0x1,%edx
f010114f:	7e 0d                	jle    f010115e <vprintfmt+0x388>
		return va_arg(*ap, long long);
f0101151:	8b 45 14             	mov    0x14(%ebp),%eax
f0101154:	8d 50 08             	lea    0x8(%eax),%edx
f0101157:	89 55 14             	mov    %edx,0x14(%ebp)
f010115a:	8b 00                	mov    (%eax),%eax
f010115c:	eb 1c                	jmp    f010117a <vprintfmt+0x3a4>
	else if (lflag)
f010115e:	85 d2                	test   %edx,%edx
f0101160:	74 0d                	je     f010116f <vprintfmt+0x399>
		return va_arg(*ap, long);
f0101162:	8b 45 14             	mov    0x14(%ebp),%eax
f0101165:	8d 50 04             	lea    0x4(%eax),%edx
f0101168:	89 55 14             	mov    %edx,0x14(%ebp)
f010116b:	8b 00                	mov    (%eax),%eax
f010116d:	eb 0b                	jmp    f010117a <vprintfmt+0x3a4>
	else
		return va_arg(*ap, int);
f010116f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101172:	8d 50 04             	lea    0x4(%eax),%edx
f0101175:	89 55 14             	mov    %edx,0x14(%ebp)
f0101178:	8b 00                	mov    (%eax),%eax
		case '%':
			putch(ch, putdat);
			break;

        case 'm':
            ccolor = getint(&ap,lflag);
f010117a:	a3 44 29 11 f0       	mov    %eax,0xf0112944
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010117f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			putch(ch, putdat);
			break;

        case 'm':
            ccolor = getint(&ap,lflag);
            break;
f0101182:	e9 80 fc ff ff       	jmp    f0100e07 <vprintfmt+0x31>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101187:	83 ec 08             	sub    $0x8,%esp
f010118a:	53                   	push   %ebx
f010118b:	6a 25                	push   $0x25
f010118d:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f010118f:	83 c4 10             	add    $0x10,%esp
f0101192:	eb 01                	jmp    f0101195 <vprintfmt+0x3bf>
f0101194:	4f                   	dec    %edi
f0101195:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101199:	75 f9                	jne    f0101194 <vprintfmt+0x3be>
f010119b:	e9 67 fc ff ff       	jmp    f0100e07 <vprintfmt+0x31>
				/* do nothing */;
			break;
		}
	}
}
f01011a0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011a3:	5b                   	pop    %ebx
f01011a4:	5e                   	pop    %esi
f01011a5:	5f                   	pop    %edi
f01011a6:	5d                   	pop    %ebp
f01011a7:	c3                   	ret    

f01011a8 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01011a8:	55                   	push   %ebp
f01011a9:	89 e5                	mov    %esp,%ebp
f01011ab:	83 ec 18             	sub    $0x18,%esp
f01011ae:	8b 45 08             	mov    0x8(%ebp),%eax
f01011b1:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01011b4:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01011b7:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01011bb:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01011be:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01011c5:	85 c0                	test   %eax,%eax
f01011c7:	74 26                	je     f01011ef <vsnprintf+0x47>
f01011c9:	85 d2                	test   %edx,%edx
f01011cb:	7e 29                	jle    f01011f6 <vsnprintf+0x4e>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01011cd:	ff 75 14             	pushl  0x14(%ebp)
f01011d0:	ff 75 10             	pushl  0x10(%ebp)
f01011d3:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01011d6:	50                   	push   %eax
f01011d7:	68 9d 0d 10 f0       	push   $0xf0100d9d
f01011dc:	e8 f5 fb ff ff       	call   f0100dd6 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01011e1:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01011e4:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01011e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011ea:	83 c4 10             	add    $0x10,%esp
f01011ed:	eb 0c                	jmp    f01011fb <vsnprintf+0x53>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01011ef:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01011f4:	eb 05                	jmp    f01011fb <vsnprintf+0x53>
f01011f6:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01011fb:	c9                   	leave  
f01011fc:	c3                   	ret    

f01011fd <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01011fd:	55                   	push   %ebp
f01011fe:	89 e5                	mov    %esp,%ebp
f0101200:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101203:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101206:	50                   	push   %eax
f0101207:	ff 75 10             	pushl  0x10(%ebp)
f010120a:	ff 75 0c             	pushl  0xc(%ebp)
f010120d:	ff 75 08             	pushl  0x8(%ebp)
f0101210:	e8 93 ff ff ff       	call   f01011a8 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101215:	c9                   	leave  
f0101216:	c3                   	ret    

f0101217 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101217:	55                   	push   %ebp
f0101218:	89 e5                	mov    %esp,%ebp
f010121a:	57                   	push   %edi
f010121b:	56                   	push   %esi
f010121c:	53                   	push   %ebx
f010121d:	83 ec 0c             	sub    $0xc,%esp
f0101220:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101223:	85 c0                	test   %eax,%eax
f0101225:	74 11                	je     f0101238 <readline+0x21>
		cprintf("%s", prompt);
f0101227:	83 ec 08             	sub    $0x8,%esp
f010122a:	50                   	push   %eax
f010122b:	68 ea 1e 10 f0       	push   $0xf0101eea
f0101230:	e8 3c f7 ff ff       	call   f0100971 <cprintf>
f0101235:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101238:	83 ec 0c             	sub    $0xc,%esp
f010123b:	6a 00                	push   $0x0
f010123d:	e8 04 f4 ff ff       	call   f0100646 <iscons>
f0101242:	89 c7                	mov    %eax,%edi
f0101244:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0101247:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f010124c:	e8 e4 f3 ff ff       	call   f0100635 <getchar>
f0101251:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0101253:	85 c0                	test   %eax,%eax
f0101255:	79 1b                	jns    f0101272 <readline+0x5b>
			cprintf("read error: %e\n", c);
f0101257:	83 ec 08             	sub    $0x8,%esp
f010125a:	50                   	push   %eax
f010125b:	68 cc 20 10 f0       	push   $0xf01020cc
f0101260:	e8 0c f7 ff ff       	call   f0100971 <cprintf>
			return NULL;
f0101265:	83 c4 10             	add    $0x10,%esp
f0101268:	b8 00 00 00 00       	mov    $0x0,%eax
f010126d:	e9 8d 00 00 00       	jmp    f01012ff <readline+0xe8>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101272:	83 f8 08             	cmp    $0x8,%eax
f0101275:	74 72                	je     f01012e9 <readline+0xd2>
f0101277:	83 f8 7f             	cmp    $0x7f,%eax
f010127a:	75 16                	jne    f0101292 <readline+0x7b>
f010127c:	eb 65                	jmp    f01012e3 <readline+0xcc>
			if (echoing)
f010127e:	85 ff                	test   %edi,%edi
f0101280:	74 0d                	je     f010128f <readline+0x78>
				cputchar('\b');
f0101282:	83 ec 0c             	sub    $0xc,%esp
f0101285:	6a 08                	push   $0x8
f0101287:	e8 99 f3 ff ff       	call   f0100625 <cputchar>
f010128c:	83 c4 10             	add    $0x10,%esp
			i--;
f010128f:	4e                   	dec    %esi
f0101290:	eb ba                	jmp    f010124c <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101292:	83 f8 1f             	cmp    $0x1f,%eax
f0101295:	7e 23                	jle    f01012ba <readline+0xa3>
f0101297:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010129d:	7f 1b                	jg     f01012ba <readline+0xa3>
			if (echoing)
f010129f:	85 ff                	test   %edi,%edi
f01012a1:	74 0c                	je     f01012af <readline+0x98>
				cputchar(c);
f01012a3:	83 ec 0c             	sub    $0xc,%esp
f01012a6:	53                   	push   %ebx
f01012a7:	e8 79 f3 ff ff       	call   f0100625 <cputchar>
f01012ac:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01012af:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f01012b5:	8d 76 01             	lea    0x1(%esi),%esi
f01012b8:	eb 92                	jmp    f010124c <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01012ba:	83 fb 0a             	cmp    $0xa,%ebx
f01012bd:	74 05                	je     f01012c4 <readline+0xad>
f01012bf:	83 fb 0d             	cmp    $0xd,%ebx
f01012c2:	75 88                	jne    f010124c <readline+0x35>
			if (echoing)
f01012c4:	85 ff                	test   %edi,%edi
f01012c6:	74 0d                	je     f01012d5 <readline+0xbe>
				cputchar('\n');
f01012c8:	83 ec 0c             	sub    $0xc,%esp
f01012cb:	6a 0a                	push   $0xa
f01012cd:	e8 53 f3 ff ff       	call   f0100625 <cputchar>
f01012d2:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01012d5:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f01012dc:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
f01012e1:	eb 1c                	jmp    f01012ff <readline+0xe8>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
			return NULL;
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01012e3:	85 f6                	test   %esi,%esi
f01012e5:	7f 97                	jg     f010127e <readline+0x67>
f01012e7:	eb 09                	jmp    f01012f2 <readline+0xdb>
f01012e9:	85 f6                	test   %esi,%esi
f01012eb:	7f 91                	jg     f010127e <readline+0x67>
f01012ed:	e9 5a ff ff ff       	jmp    f010124c <readline+0x35>
			if (echoing)
				cputchar('\b');
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
f01012f2:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01012f8:	7e a5                	jle    f010129f <readline+0x88>
f01012fa:	e9 4d ff ff ff       	jmp    f010124c <readline+0x35>
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f01012ff:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101302:	5b                   	pop    %ebx
f0101303:	5e                   	pop    %esi
f0101304:	5f                   	pop    %edi
f0101305:	5d                   	pop    %ebp
f0101306:	c3                   	ret    

f0101307 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101307:	55                   	push   %ebp
f0101308:	89 e5                	mov    %esp,%ebp
f010130a:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010130d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101312:	eb 01                	jmp    f0101315 <strlen+0xe>
		n++;
f0101314:	40                   	inc    %eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101315:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101319:	75 f9                	jne    f0101314 <strlen+0xd>
		n++;
	return n;
}
f010131b:	5d                   	pop    %ebp
f010131c:	c3                   	ret    

f010131d <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010131d:	55                   	push   %ebp
f010131e:	89 e5                	mov    %esp,%ebp
f0101320:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101323:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101326:	ba 00 00 00 00       	mov    $0x0,%edx
f010132b:	eb 01                	jmp    f010132e <strnlen+0x11>
		n++;
f010132d:	42                   	inc    %edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010132e:	39 c2                	cmp    %eax,%edx
f0101330:	74 08                	je     f010133a <strnlen+0x1d>
f0101332:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0101336:	75 f5                	jne    f010132d <strnlen+0x10>
f0101338:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f010133a:	5d                   	pop    %ebp
f010133b:	c3                   	ret    

f010133c <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010133c:	55                   	push   %ebp
f010133d:	89 e5                	mov    %esp,%ebp
f010133f:	53                   	push   %ebx
f0101340:	8b 45 08             	mov    0x8(%ebp),%eax
f0101343:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101346:	89 c2                	mov    %eax,%edx
f0101348:	42                   	inc    %edx
f0101349:	41                   	inc    %ecx
f010134a:	8a 59 ff             	mov    -0x1(%ecx),%bl
f010134d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101350:	84 db                	test   %bl,%bl
f0101352:	75 f4                	jne    f0101348 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101354:	5b                   	pop    %ebx
f0101355:	5d                   	pop    %ebp
f0101356:	c3                   	ret    

f0101357 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101357:	55                   	push   %ebp
f0101358:	89 e5                	mov    %esp,%ebp
f010135a:	53                   	push   %ebx
f010135b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010135e:	53                   	push   %ebx
f010135f:	e8 a3 ff ff ff       	call   f0101307 <strlen>
f0101364:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101367:	ff 75 0c             	pushl  0xc(%ebp)
f010136a:	01 d8                	add    %ebx,%eax
f010136c:	50                   	push   %eax
f010136d:	e8 ca ff ff ff       	call   f010133c <strcpy>
	return dst;
}
f0101372:	89 d8                	mov    %ebx,%eax
f0101374:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101377:	c9                   	leave  
f0101378:	c3                   	ret    

f0101379 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101379:	55                   	push   %ebp
f010137a:	89 e5                	mov    %esp,%ebp
f010137c:	56                   	push   %esi
f010137d:	53                   	push   %ebx
f010137e:	8b 75 08             	mov    0x8(%ebp),%esi
f0101381:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101384:	89 f3                	mov    %esi,%ebx
f0101386:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101389:	89 f2                	mov    %esi,%edx
f010138b:	eb 0c                	jmp    f0101399 <strncpy+0x20>
		*dst++ = *src;
f010138d:	42                   	inc    %edx
f010138e:	8a 01                	mov    (%ecx),%al
f0101390:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101393:	80 39 01             	cmpb   $0x1,(%ecx)
f0101396:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101399:	39 da                	cmp    %ebx,%edx
f010139b:	75 f0                	jne    f010138d <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010139d:	89 f0                	mov    %esi,%eax
f010139f:	5b                   	pop    %ebx
f01013a0:	5e                   	pop    %esi
f01013a1:	5d                   	pop    %ebp
f01013a2:	c3                   	ret    

f01013a3 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01013a3:	55                   	push   %ebp
f01013a4:	89 e5                	mov    %esp,%ebp
f01013a6:	56                   	push   %esi
f01013a7:	53                   	push   %ebx
f01013a8:	8b 75 08             	mov    0x8(%ebp),%esi
f01013ab:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01013ae:	8b 45 10             	mov    0x10(%ebp),%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01013b1:	85 c0                	test   %eax,%eax
f01013b3:	74 1e                	je     f01013d3 <strlcpy+0x30>
f01013b5:	8d 44 06 ff          	lea    -0x1(%esi,%eax,1),%eax
f01013b9:	89 f2                	mov    %esi,%edx
f01013bb:	eb 05                	jmp    f01013c2 <strlcpy+0x1f>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01013bd:	42                   	inc    %edx
f01013be:	41                   	inc    %ecx
f01013bf:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01013c2:	39 c2                	cmp    %eax,%edx
f01013c4:	74 08                	je     f01013ce <strlcpy+0x2b>
f01013c6:	8a 19                	mov    (%ecx),%bl
f01013c8:	84 db                	test   %bl,%bl
f01013ca:	75 f1                	jne    f01013bd <strlcpy+0x1a>
f01013cc:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01013ce:	c6 00 00             	movb   $0x0,(%eax)
f01013d1:	eb 02                	jmp    f01013d5 <strlcpy+0x32>
f01013d3:	89 f0                	mov    %esi,%eax
	}
	return dst - dst_in;
f01013d5:	29 f0                	sub    %esi,%eax
}
f01013d7:	5b                   	pop    %ebx
f01013d8:	5e                   	pop    %esi
f01013d9:	5d                   	pop    %ebp
f01013da:	c3                   	ret    

f01013db <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01013db:	55                   	push   %ebp
f01013dc:	89 e5                	mov    %esp,%ebp
f01013de:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01013e1:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01013e4:	eb 02                	jmp    f01013e8 <strcmp+0xd>
		p++, q++;
f01013e6:	41                   	inc    %ecx
f01013e7:	42                   	inc    %edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01013e8:	8a 01                	mov    (%ecx),%al
f01013ea:	84 c0                	test   %al,%al
f01013ec:	74 04                	je     f01013f2 <strcmp+0x17>
f01013ee:	3a 02                	cmp    (%edx),%al
f01013f0:	74 f4                	je     f01013e6 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01013f2:	0f b6 c0             	movzbl %al,%eax
f01013f5:	0f b6 12             	movzbl (%edx),%edx
f01013f8:	29 d0                	sub    %edx,%eax
}
f01013fa:	5d                   	pop    %ebp
f01013fb:	c3                   	ret    

f01013fc <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01013fc:	55                   	push   %ebp
f01013fd:	89 e5                	mov    %esp,%ebp
f01013ff:	53                   	push   %ebx
f0101400:	8b 45 08             	mov    0x8(%ebp),%eax
f0101403:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101406:	89 c3                	mov    %eax,%ebx
f0101408:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010140b:	eb 02                	jmp    f010140f <strncmp+0x13>
		n--, p++, q++;
f010140d:	40                   	inc    %eax
f010140e:	42                   	inc    %edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010140f:	39 d8                	cmp    %ebx,%eax
f0101411:	74 14                	je     f0101427 <strncmp+0x2b>
f0101413:	8a 08                	mov    (%eax),%cl
f0101415:	84 c9                	test   %cl,%cl
f0101417:	74 04                	je     f010141d <strncmp+0x21>
f0101419:	3a 0a                	cmp    (%edx),%cl
f010141b:	74 f0                	je     f010140d <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010141d:	0f b6 00             	movzbl (%eax),%eax
f0101420:	0f b6 12             	movzbl (%edx),%edx
f0101423:	29 d0                	sub    %edx,%eax
f0101425:	eb 05                	jmp    f010142c <strncmp+0x30>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101427:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010142c:	5b                   	pop    %ebx
f010142d:	5d                   	pop    %ebp
f010142e:	c3                   	ret    

f010142f <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010142f:	55                   	push   %ebp
f0101430:	89 e5                	mov    %esp,%ebp
f0101432:	8b 45 08             	mov    0x8(%ebp),%eax
f0101435:	8a 4d 0c             	mov    0xc(%ebp),%cl
	for (; *s; s++)
f0101438:	eb 05                	jmp    f010143f <strchr+0x10>
		if (*s == c)
f010143a:	38 ca                	cmp    %cl,%dl
f010143c:	74 0c                	je     f010144a <strchr+0x1b>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010143e:	40                   	inc    %eax
f010143f:	8a 10                	mov    (%eax),%dl
f0101441:	84 d2                	test   %dl,%dl
f0101443:	75 f5                	jne    f010143a <strchr+0xb>
		if (*s == c)
			return (char *) s;
	return 0;
f0101445:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010144a:	5d                   	pop    %ebp
f010144b:	c3                   	ret    

f010144c <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010144c:	55                   	push   %ebp
f010144d:	89 e5                	mov    %esp,%ebp
f010144f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101452:	8a 4d 0c             	mov    0xc(%ebp),%cl
	for (; *s; s++)
f0101455:	eb 05                	jmp    f010145c <strfind+0x10>
		if (*s == c)
f0101457:	38 ca                	cmp    %cl,%dl
f0101459:	74 07                	je     f0101462 <strfind+0x16>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010145b:	40                   	inc    %eax
f010145c:	8a 10                	mov    (%eax),%dl
f010145e:	84 d2                	test   %dl,%dl
f0101460:	75 f5                	jne    f0101457 <strfind+0xb>
		if (*s == c)
			break;
	return (char *) s;
}
f0101462:	5d                   	pop    %ebp
f0101463:	c3                   	ret    

f0101464 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101464:	55                   	push   %ebp
f0101465:	89 e5                	mov    %esp,%ebp
f0101467:	57                   	push   %edi
f0101468:	56                   	push   %esi
f0101469:	53                   	push   %ebx
f010146a:	8b 7d 08             	mov    0x8(%ebp),%edi
f010146d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101470:	85 c9                	test   %ecx,%ecx
f0101472:	74 36                	je     f01014aa <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101474:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010147a:	75 28                	jne    f01014a4 <memset+0x40>
f010147c:	f6 c1 03             	test   $0x3,%cl
f010147f:	75 23                	jne    f01014a4 <memset+0x40>
		c &= 0xFF;
f0101481:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101485:	89 d3                	mov    %edx,%ebx
f0101487:	c1 e3 08             	shl    $0x8,%ebx
f010148a:	89 d6                	mov    %edx,%esi
f010148c:	c1 e6 18             	shl    $0x18,%esi
f010148f:	89 d0                	mov    %edx,%eax
f0101491:	c1 e0 10             	shl    $0x10,%eax
f0101494:	09 f0                	or     %esi,%eax
f0101496:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0101498:	89 d8                	mov    %ebx,%eax
f010149a:	09 d0                	or     %edx,%eax
f010149c:	c1 e9 02             	shr    $0x2,%ecx
f010149f:	fc                   	cld    
f01014a0:	f3 ab                	rep stos %eax,%es:(%edi)
f01014a2:	eb 06                	jmp    f01014aa <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01014a4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014a7:	fc                   	cld    
f01014a8:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01014aa:	89 f8                	mov    %edi,%eax
f01014ac:	5b                   	pop    %ebx
f01014ad:	5e                   	pop    %esi
f01014ae:	5f                   	pop    %edi
f01014af:	5d                   	pop    %ebp
f01014b0:	c3                   	ret    

f01014b1 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01014b1:	55                   	push   %ebp
f01014b2:	89 e5                	mov    %esp,%ebp
f01014b4:	57                   	push   %edi
f01014b5:	56                   	push   %esi
f01014b6:	8b 45 08             	mov    0x8(%ebp),%eax
f01014b9:	8b 75 0c             	mov    0xc(%ebp),%esi
f01014bc:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01014bf:	39 c6                	cmp    %eax,%esi
f01014c1:	73 33                	jae    f01014f6 <memmove+0x45>
f01014c3:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01014c6:	39 d0                	cmp    %edx,%eax
f01014c8:	73 2c                	jae    f01014f6 <memmove+0x45>
		s += n;
		d += n;
f01014ca:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014cd:	89 d6                	mov    %edx,%esi
f01014cf:	09 fe                	or     %edi,%esi
f01014d1:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01014d7:	75 13                	jne    f01014ec <memmove+0x3b>
f01014d9:	f6 c1 03             	test   $0x3,%cl
f01014dc:	75 0e                	jne    f01014ec <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01014de:	83 ef 04             	sub    $0x4,%edi
f01014e1:	8d 72 fc             	lea    -0x4(%edx),%esi
f01014e4:	c1 e9 02             	shr    $0x2,%ecx
f01014e7:	fd                   	std    
f01014e8:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01014ea:	eb 07                	jmp    f01014f3 <memmove+0x42>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01014ec:	4f                   	dec    %edi
f01014ed:	8d 72 ff             	lea    -0x1(%edx),%esi
f01014f0:	fd                   	std    
f01014f1:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01014f3:	fc                   	cld    
f01014f4:	eb 1d                	jmp    f0101513 <memmove+0x62>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014f6:	89 f2                	mov    %esi,%edx
f01014f8:	09 c2                	or     %eax,%edx
f01014fa:	f6 c2 03             	test   $0x3,%dl
f01014fd:	75 0f                	jne    f010150e <memmove+0x5d>
f01014ff:	f6 c1 03             	test   $0x3,%cl
f0101502:	75 0a                	jne    f010150e <memmove+0x5d>
			asm volatile("cld; rep movsl\n"
f0101504:	c1 e9 02             	shr    $0x2,%ecx
f0101507:	89 c7                	mov    %eax,%edi
f0101509:	fc                   	cld    
f010150a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010150c:	eb 05                	jmp    f0101513 <memmove+0x62>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010150e:	89 c7                	mov    %eax,%edi
f0101510:	fc                   	cld    
f0101511:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101513:	5e                   	pop    %esi
f0101514:	5f                   	pop    %edi
f0101515:	5d                   	pop    %ebp
f0101516:	c3                   	ret    

f0101517 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101517:	55                   	push   %ebp
f0101518:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010151a:	ff 75 10             	pushl  0x10(%ebp)
f010151d:	ff 75 0c             	pushl  0xc(%ebp)
f0101520:	ff 75 08             	pushl  0x8(%ebp)
f0101523:	e8 89 ff ff ff       	call   f01014b1 <memmove>
}
f0101528:	c9                   	leave  
f0101529:	c3                   	ret    

f010152a <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010152a:	55                   	push   %ebp
f010152b:	89 e5                	mov    %esp,%ebp
f010152d:	56                   	push   %esi
f010152e:	53                   	push   %ebx
f010152f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101532:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101535:	89 c6                	mov    %eax,%esi
f0101537:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010153a:	eb 14                	jmp    f0101550 <memcmp+0x26>
		if (*s1 != *s2)
f010153c:	8a 08                	mov    (%eax),%cl
f010153e:	8a 1a                	mov    (%edx),%bl
f0101540:	38 d9                	cmp    %bl,%cl
f0101542:	74 0a                	je     f010154e <memcmp+0x24>
			return (int) *s1 - (int) *s2;
f0101544:	0f b6 c1             	movzbl %cl,%eax
f0101547:	0f b6 db             	movzbl %bl,%ebx
f010154a:	29 d8                	sub    %ebx,%eax
f010154c:	eb 0b                	jmp    f0101559 <memcmp+0x2f>
		s1++, s2++;
f010154e:	40                   	inc    %eax
f010154f:	42                   	inc    %edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101550:	39 f0                	cmp    %esi,%eax
f0101552:	75 e8                	jne    f010153c <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101554:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101559:	5b                   	pop    %ebx
f010155a:	5e                   	pop    %esi
f010155b:	5d                   	pop    %ebp
f010155c:	c3                   	ret    

f010155d <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010155d:	55                   	push   %ebp
f010155e:	89 e5                	mov    %esp,%ebp
f0101560:	53                   	push   %ebx
f0101561:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0101564:	89 c1                	mov    %eax,%ecx
f0101566:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0101569:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010156d:	eb 08                	jmp    f0101577 <memfind+0x1a>
		if (*(const unsigned char *) s == (unsigned char) c)
f010156f:	0f b6 10             	movzbl (%eax),%edx
f0101572:	39 da                	cmp    %ebx,%edx
f0101574:	74 05                	je     f010157b <memfind+0x1e>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101576:	40                   	inc    %eax
f0101577:	39 c8                	cmp    %ecx,%eax
f0101579:	72 f4                	jb     f010156f <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010157b:	5b                   	pop    %ebx
f010157c:	5d                   	pop    %ebp
f010157d:	c3                   	ret    

f010157e <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010157e:	55                   	push   %ebp
f010157f:	89 e5                	mov    %esp,%ebp
f0101581:	57                   	push   %edi
f0101582:	56                   	push   %esi
f0101583:	53                   	push   %ebx
f0101584:	8b 4d 08             	mov    0x8(%ebp),%ecx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101587:	eb 01                	jmp    f010158a <strtol+0xc>
		s++;
f0101589:	41                   	inc    %ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010158a:	8a 01                	mov    (%ecx),%al
f010158c:	3c 20                	cmp    $0x20,%al
f010158e:	74 f9                	je     f0101589 <strtol+0xb>
f0101590:	3c 09                	cmp    $0x9,%al
f0101592:	74 f5                	je     f0101589 <strtol+0xb>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101594:	3c 2b                	cmp    $0x2b,%al
f0101596:	75 08                	jne    f01015a0 <strtol+0x22>
		s++;
f0101598:	41                   	inc    %ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101599:	bf 00 00 00 00       	mov    $0x0,%edi
f010159e:	eb 11                	jmp    f01015b1 <strtol+0x33>
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01015a0:	3c 2d                	cmp    $0x2d,%al
f01015a2:	75 08                	jne    f01015ac <strtol+0x2e>
		s++, neg = 1;
f01015a4:	41                   	inc    %ecx
f01015a5:	bf 01 00 00 00       	mov    $0x1,%edi
f01015aa:	eb 05                	jmp    f01015b1 <strtol+0x33>
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01015ac:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01015b1:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01015b5:	0f 84 87 00 00 00    	je     f0101642 <strtol+0xc4>
f01015bb:	83 7d 10 10          	cmpl   $0x10,0x10(%ebp)
f01015bf:	75 27                	jne    f01015e8 <strtol+0x6a>
f01015c1:	80 39 30             	cmpb   $0x30,(%ecx)
f01015c4:	75 22                	jne    f01015e8 <strtol+0x6a>
f01015c6:	e9 88 00 00 00       	jmp    f0101653 <strtol+0xd5>
		s += 2, base = 16;
f01015cb:	83 c1 02             	add    $0x2,%ecx
f01015ce:	c7 45 10 10 00 00 00 	movl   $0x10,0x10(%ebp)
f01015d5:	eb 11                	jmp    f01015e8 <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
		s++, base = 8;
f01015d7:	41                   	inc    %ecx
f01015d8:	c7 45 10 08 00 00 00 	movl   $0x8,0x10(%ebp)
f01015df:	eb 07                	jmp    f01015e8 <strtol+0x6a>
	else if (base == 0)
		base = 10;
f01015e1:	c7 45 10 0a 00 00 00 	movl   $0xa,0x10(%ebp)
f01015e8:	b8 00 00 00 00       	mov    $0x0,%eax

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01015ed:	8a 11                	mov    (%ecx),%dl
f01015ef:	8d 5a d0             	lea    -0x30(%edx),%ebx
f01015f2:	80 fb 09             	cmp    $0x9,%bl
f01015f5:	77 08                	ja     f01015ff <strtol+0x81>
			dig = *s - '0';
f01015f7:	0f be d2             	movsbl %dl,%edx
f01015fa:	83 ea 30             	sub    $0x30,%edx
f01015fd:	eb 22                	jmp    f0101621 <strtol+0xa3>
		else if (*s >= 'a' && *s <= 'z')
f01015ff:	8d 72 9f             	lea    -0x61(%edx),%esi
f0101602:	89 f3                	mov    %esi,%ebx
f0101604:	80 fb 19             	cmp    $0x19,%bl
f0101607:	77 08                	ja     f0101611 <strtol+0x93>
			dig = *s - 'a' + 10;
f0101609:	0f be d2             	movsbl %dl,%edx
f010160c:	83 ea 57             	sub    $0x57,%edx
f010160f:	eb 10                	jmp    f0101621 <strtol+0xa3>
		else if (*s >= 'A' && *s <= 'Z')
f0101611:	8d 72 bf             	lea    -0x41(%edx),%esi
f0101614:	89 f3                	mov    %esi,%ebx
f0101616:	80 fb 19             	cmp    $0x19,%bl
f0101619:	77 14                	ja     f010162f <strtol+0xb1>
			dig = *s - 'A' + 10;
f010161b:	0f be d2             	movsbl %dl,%edx
f010161e:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0101621:	3b 55 10             	cmp    0x10(%ebp),%edx
f0101624:	7d 09                	jge    f010162f <strtol+0xb1>
			break;
		s++, val = (val * base) + dig;
f0101626:	41                   	inc    %ecx
f0101627:	0f af 45 10          	imul   0x10(%ebp),%eax
f010162b:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f010162d:	eb be                	jmp    f01015ed <strtol+0x6f>

	if (endptr)
f010162f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101633:	74 05                	je     f010163a <strtol+0xbc>
		*endptr = (char *) s;
f0101635:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101638:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f010163a:	85 ff                	test   %edi,%edi
f010163c:	74 21                	je     f010165f <strtol+0xe1>
f010163e:	f7 d8                	neg    %eax
f0101640:	eb 1d                	jmp    f010165f <strtol+0xe1>
		s++;
	else if (*s == '-')
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101642:	80 39 30             	cmpb   $0x30,(%ecx)
f0101645:	75 9a                	jne    f01015e1 <strtol+0x63>
f0101647:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010164b:	0f 84 7a ff ff ff    	je     f01015cb <strtol+0x4d>
f0101651:	eb 84                	jmp    f01015d7 <strtol+0x59>
f0101653:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0101657:	0f 84 6e ff ff ff    	je     f01015cb <strtol+0x4d>
f010165d:	eb 89                	jmp    f01015e8 <strtol+0x6a>
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
}
f010165f:	5b                   	pop    %ebx
f0101660:	5e                   	pop    %esi
f0101661:	5f                   	pop    %edi
f0101662:	5d                   	pop    %ebp
f0101663:	c3                   	ret    

f0101664 <__udivdi3>:
f0101664:	55                   	push   %ebp
f0101665:	57                   	push   %edi
f0101666:	56                   	push   %esi
f0101667:	53                   	push   %ebx
f0101668:	83 ec 1c             	sub    $0x1c,%esp
f010166b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010166f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0101673:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101677:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010167b:	89 ca                	mov    %ecx,%edx
f010167d:	89 f8                	mov    %edi,%eax
f010167f:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f0101683:	85 f6                	test   %esi,%esi
f0101685:	75 2d                	jne    f01016b4 <__udivdi3+0x50>
f0101687:	39 cf                	cmp    %ecx,%edi
f0101689:	77 65                	ja     f01016f0 <__udivdi3+0x8c>
f010168b:	89 fd                	mov    %edi,%ebp
f010168d:	85 ff                	test   %edi,%edi
f010168f:	75 0b                	jne    f010169c <__udivdi3+0x38>
f0101691:	b8 01 00 00 00       	mov    $0x1,%eax
f0101696:	31 d2                	xor    %edx,%edx
f0101698:	f7 f7                	div    %edi
f010169a:	89 c5                	mov    %eax,%ebp
f010169c:	31 d2                	xor    %edx,%edx
f010169e:	89 c8                	mov    %ecx,%eax
f01016a0:	f7 f5                	div    %ebp
f01016a2:	89 c1                	mov    %eax,%ecx
f01016a4:	89 d8                	mov    %ebx,%eax
f01016a6:	f7 f5                	div    %ebp
f01016a8:	89 cf                	mov    %ecx,%edi
f01016aa:	89 fa                	mov    %edi,%edx
f01016ac:	83 c4 1c             	add    $0x1c,%esp
f01016af:	5b                   	pop    %ebx
f01016b0:	5e                   	pop    %esi
f01016b1:	5f                   	pop    %edi
f01016b2:	5d                   	pop    %ebp
f01016b3:	c3                   	ret    
f01016b4:	39 ce                	cmp    %ecx,%esi
f01016b6:	77 28                	ja     f01016e0 <__udivdi3+0x7c>
f01016b8:	0f bd fe             	bsr    %esi,%edi
f01016bb:	83 f7 1f             	xor    $0x1f,%edi
f01016be:	75 40                	jne    f0101700 <__udivdi3+0x9c>
f01016c0:	39 ce                	cmp    %ecx,%esi
f01016c2:	72 0a                	jb     f01016ce <__udivdi3+0x6a>
f01016c4:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01016c8:	0f 87 9e 00 00 00    	ja     f010176c <__udivdi3+0x108>
f01016ce:	b8 01 00 00 00       	mov    $0x1,%eax
f01016d3:	89 fa                	mov    %edi,%edx
f01016d5:	83 c4 1c             	add    $0x1c,%esp
f01016d8:	5b                   	pop    %ebx
f01016d9:	5e                   	pop    %esi
f01016da:	5f                   	pop    %edi
f01016db:	5d                   	pop    %ebp
f01016dc:	c3                   	ret    
f01016dd:	8d 76 00             	lea    0x0(%esi),%esi
f01016e0:	31 ff                	xor    %edi,%edi
f01016e2:	31 c0                	xor    %eax,%eax
f01016e4:	89 fa                	mov    %edi,%edx
f01016e6:	83 c4 1c             	add    $0x1c,%esp
f01016e9:	5b                   	pop    %ebx
f01016ea:	5e                   	pop    %esi
f01016eb:	5f                   	pop    %edi
f01016ec:	5d                   	pop    %ebp
f01016ed:	c3                   	ret    
f01016ee:	66 90                	xchg   %ax,%ax
f01016f0:	89 d8                	mov    %ebx,%eax
f01016f2:	f7 f7                	div    %edi
f01016f4:	31 ff                	xor    %edi,%edi
f01016f6:	89 fa                	mov    %edi,%edx
f01016f8:	83 c4 1c             	add    $0x1c,%esp
f01016fb:	5b                   	pop    %ebx
f01016fc:	5e                   	pop    %esi
f01016fd:	5f                   	pop    %edi
f01016fe:	5d                   	pop    %ebp
f01016ff:	c3                   	ret    
f0101700:	bd 20 00 00 00       	mov    $0x20,%ebp
f0101705:	89 eb                	mov    %ebp,%ebx
f0101707:	29 fb                	sub    %edi,%ebx
f0101709:	89 f9                	mov    %edi,%ecx
f010170b:	d3 e6                	shl    %cl,%esi
f010170d:	89 c5                	mov    %eax,%ebp
f010170f:	88 d9                	mov    %bl,%cl
f0101711:	d3 ed                	shr    %cl,%ebp
f0101713:	89 e9                	mov    %ebp,%ecx
f0101715:	09 f1                	or     %esi,%ecx
f0101717:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010171b:	89 f9                	mov    %edi,%ecx
f010171d:	d3 e0                	shl    %cl,%eax
f010171f:	89 c5                	mov    %eax,%ebp
f0101721:	89 d6                	mov    %edx,%esi
f0101723:	88 d9                	mov    %bl,%cl
f0101725:	d3 ee                	shr    %cl,%esi
f0101727:	89 f9                	mov    %edi,%ecx
f0101729:	d3 e2                	shl    %cl,%edx
f010172b:	8b 44 24 08          	mov    0x8(%esp),%eax
f010172f:	88 d9                	mov    %bl,%cl
f0101731:	d3 e8                	shr    %cl,%eax
f0101733:	09 c2                	or     %eax,%edx
f0101735:	89 d0                	mov    %edx,%eax
f0101737:	89 f2                	mov    %esi,%edx
f0101739:	f7 74 24 0c          	divl   0xc(%esp)
f010173d:	89 d6                	mov    %edx,%esi
f010173f:	89 c3                	mov    %eax,%ebx
f0101741:	f7 e5                	mul    %ebp
f0101743:	39 d6                	cmp    %edx,%esi
f0101745:	72 19                	jb     f0101760 <__udivdi3+0xfc>
f0101747:	74 0b                	je     f0101754 <__udivdi3+0xf0>
f0101749:	89 d8                	mov    %ebx,%eax
f010174b:	31 ff                	xor    %edi,%edi
f010174d:	e9 58 ff ff ff       	jmp    f01016aa <__udivdi3+0x46>
f0101752:	66 90                	xchg   %ax,%ax
f0101754:	8b 54 24 08          	mov    0x8(%esp),%edx
f0101758:	89 f9                	mov    %edi,%ecx
f010175a:	d3 e2                	shl    %cl,%edx
f010175c:	39 c2                	cmp    %eax,%edx
f010175e:	73 e9                	jae    f0101749 <__udivdi3+0xe5>
f0101760:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0101763:	31 ff                	xor    %edi,%edi
f0101765:	e9 40 ff ff ff       	jmp    f01016aa <__udivdi3+0x46>
f010176a:	66 90                	xchg   %ax,%ax
f010176c:	31 c0                	xor    %eax,%eax
f010176e:	e9 37 ff ff ff       	jmp    f01016aa <__udivdi3+0x46>
f0101773:	90                   	nop

f0101774 <__umoddi3>:
f0101774:	55                   	push   %ebp
f0101775:	57                   	push   %edi
f0101776:	56                   	push   %esi
f0101777:	53                   	push   %ebx
f0101778:	83 ec 1c             	sub    $0x1c,%esp
f010177b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010177f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101783:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101787:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f010178b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010178f:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101793:	89 f3                	mov    %esi,%ebx
f0101795:	89 fa                	mov    %edi,%edx
f0101797:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010179b:	89 34 24             	mov    %esi,(%esp)
f010179e:	85 c0                	test   %eax,%eax
f01017a0:	75 1a                	jne    f01017bc <__umoddi3+0x48>
f01017a2:	39 f7                	cmp    %esi,%edi
f01017a4:	0f 86 a2 00 00 00    	jbe    f010184c <__umoddi3+0xd8>
f01017aa:	89 c8                	mov    %ecx,%eax
f01017ac:	89 f2                	mov    %esi,%edx
f01017ae:	f7 f7                	div    %edi
f01017b0:	89 d0                	mov    %edx,%eax
f01017b2:	31 d2                	xor    %edx,%edx
f01017b4:	83 c4 1c             	add    $0x1c,%esp
f01017b7:	5b                   	pop    %ebx
f01017b8:	5e                   	pop    %esi
f01017b9:	5f                   	pop    %edi
f01017ba:	5d                   	pop    %ebp
f01017bb:	c3                   	ret    
f01017bc:	39 f0                	cmp    %esi,%eax
f01017be:	0f 87 ac 00 00 00    	ja     f0101870 <__umoddi3+0xfc>
f01017c4:	0f bd e8             	bsr    %eax,%ebp
f01017c7:	83 f5 1f             	xor    $0x1f,%ebp
f01017ca:	0f 84 ac 00 00 00    	je     f010187c <__umoddi3+0x108>
f01017d0:	bf 20 00 00 00       	mov    $0x20,%edi
f01017d5:	29 ef                	sub    %ebp,%edi
f01017d7:	89 fe                	mov    %edi,%esi
f01017d9:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01017dd:	89 e9                	mov    %ebp,%ecx
f01017df:	d3 e0                	shl    %cl,%eax
f01017e1:	89 d7                	mov    %edx,%edi
f01017e3:	89 f1                	mov    %esi,%ecx
f01017e5:	d3 ef                	shr    %cl,%edi
f01017e7:	09 c7                	or     %eax,%edi
f01017e9:	89 e9                	mov    %ebp,%ecx
f01017eb:	d3 e2                	shl    %cl,%edx
f01017ed:	89 14 24             	mov    %edx,(%esp)
f01017f0:	89 d8                	mov    %ebx,%eax
f01017f2:	d3 e0                	shl    %cl,%eax
f01017f4:	89 c2                	mov    %eax,%edx
f01017f6:	8b 44 24 08          	mov    0x8(%esp),%eax
f01017fa:	d3 e0                	shl    %cl,%eax
f01017fc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101800:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101804:	89 f1                	mov    %esi,%ecx
f0101806:	d3 e8                	shr    %cl,%eax
f0101808:	09 d0                	or     %edx,%eax
f010180a:	d3 eb                	shr    %cl,%ebx
f010180c:	89 da                	mov    %ebx,%edx
f010180e:	f7 f7                	div    %edi
f0101810:	89 d3                	mov    %edx,%ebx
f0101812:	f7 24 24             	mull   (%esp)
f0101815:	89 c6                	mov    %eax,%esi
f0101817:	89 d1                	mov    %edx,%ecx
f0101819:	39 d3                	cmp    %edx,%ebx
f010181b:	0f 82 87 00 00 00    	jb     f01018a8 <__umoddi3+0x134>
f0101821:	0f 84 91 00 00 00    	je     f01018b8 <__umoddi3+0x144>
f0101827:	8b 54 24 04          	mov    0x4(%esp),%edx
f010182b:	29 f2                	sub    %esi,%edx
f010182d:	19 cb                	sbb    %ecx,%ebx
f010182f:	89 d8                	mov    %ebx,%eax
f0101831:	8a 4c 24 0c          	mov    0xc(%esp),%cl
f0101835:	d3 e0                	shl    %cl,%eax
f0101837:	89 e9                	mov    %ebp,%ecx
f0101839:	d3 ea                	shr    %cl,%edx
f010183b:	09 d0                	or     %edx,%eax
f010183d:	89 e9                	mov    %ebp,%ecx
f010183f:	d3 eb                	shr    %cl,%ebx
f0101841:	89 da                	mov    %ebx,%edx
f0101843:	83 c4 1c             	add    $0x1c,%esp
f0101846:	5b                   	pop    %ebx
f0101847:	5e                   	pop    %esi
f0101848:	5f                   	pop    %edi
f0101849:	5d                   	pop    %ebp
f010184a:	c3                   	ret    
f010184b:	90                   	nop
f010184c:	89 fd                	mov    %edi,%ebp
f010184e:	85 ff                	test   %edi,%edi
f0101850:	75 0b                	jne    f010185d <__umoddi3+0xe9>
f0101852:	b8 01 00 00 00       	mov    $0x1,%eax
f0101857:	31 d2                	xor    %edx,%edx
f0101859:	f7 f7                	div    %edi
f010185b:	89 c5                	mov    %eax,%ebp
f010185d:	89 f0                	mov    %esi,%eax
f010185f:	31 d2                	xor    %edx,%edx
f0101861:	f7 f5                	div    %ebp
f0101863:	89 c8                	mov    %ecx,%eax
f0101865:	f7 f5                	div    %ebp
f0101867:	89 d0                	mov    %edx,%eax
f0101869:	e9 44 ff ff ff       	jmp    f01017b2 <__umoddi3+0x3e>
f010186e:	66 90                	xchg   %ax,%ax
f0101870:	89 c8                	mov    %ecx,%eax
f0101872:	89 f2                	mov    %esi,%edx
f0101874:	83 c4 1c             	add    $0x1c,%esp
f0101877:	5b                   	pop    %ebx
f0101878:	5e                   	pop    %esi
f0101879:	5f                   	pop    %edi
f010187a:	5d                   	pop    %ebp
f010187b:	c3                   	ret    
f010187c:	3b 04 24             	cmp    (%esp),%eax
f010187f:	72 06                	jb     f0101887 <__umoddi3+0x113>
f0101881:	3b 7c 24 04          	cmp    0x4(%esp),%edi
f0101885:	77 0f                	ja     f0101896 <__umoddi3+0x122>
f0101887:	89 f2                	mov    %esi,%edx
f0101889:	29 f9                	sub    %edi,%ecx
f010188b:	1b 54 24 0c          	sbb    0xc(%esp),%edx
f010188f:	89 14 24             	mov    %edx,(%esp)
f0101892:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101896:	8b 44 24 04          	mov    0x4(%esp),%eax
f010189a:	8b 14 24             	mov    (%esp),%edx
f010189d:	83 c4 1c             	add    $0x1c,%esp
f01018a0:	5b                   	pop    %ebx
f01018a1:	5e                   	pop    %esi
f01018a2:	5f                   	pop    %edi
f01018a3:	5d                   	pop    %ebp
f01018a4:	c3                   	ret    
f01018a5:	8d 76 00             	lea    0x0(%esi),%esi
f01018a8:	2b 04 24             	sub    (%esp),%eax
f01018ab:	19 fa                	sbb    %edi,%edx
f01018ad:	89 d1                	mov    %edx,%ecx
f01018af:	89 c6                	mov    %eax,%esi
f01018b1:	e9 71 ff ff ff       	jmp    f0101827 <__umoddi3+0xb3>
f01018b6:	66 90                	xchg   %ax,%ax
f01018b8:	39 44 24 04          	cmp    %eax,0x4(%esp)
f01018bc:	72 ea                	jb     f01018a8 <__umoddi3+0x134>
f01018be:	89 d9                	mov    %ebx,%ecx
f01018c0:	e9 62 ff ff ff       	jmp    f0101827 <__umoddi3+0xb3>
