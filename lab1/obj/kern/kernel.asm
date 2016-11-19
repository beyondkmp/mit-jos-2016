
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
f0100050:	e8 21 09 00 00       	call   f0100976 <cprintf>
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
f0100076:	e8 c7 06 00 00       	call   f0100742 <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 fc 18 10 f0       	push   $0xf01018fc
f0100087:	e8 ea 08 00 00       	call   f0100976 <cprintf>
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
f01000ac:	e8 b8 13 00 00       	call   f0101469 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 86 04 00 00       	call   f010053c <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 17 19 10 f0       	push   $0xf0101917
f01000c3:	e8 ae 08 00 00       	call   f0100976 <cprintf>

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
f01000dc:	e8 ee 06 00 00       	call   f01007cf <monitor>
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
f0100110:	e8 61 08 00 00       	call   f0100976 <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 31 08 00 00       	call   f0100950 <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 6e 19 10 f0 	movl   $0xf010196e,(%esp)
f0100126:	e8 4b 08 00 00       	call   f0100976 <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 97 06 00 00       	call   f01007cf <monitor>
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
f0100152:	e8 1f 08 00 00       	call   f0100976 <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 ed 07 00 00       	call   f0100950 <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 6e 19 10 f0 	movl   $0xf010196e,(%esp)
f010016a:	e8 07 08 00 00       	call   f0100976 <cprintf>
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
f01002c1:	e8 b0 06 00 00       	call   f0100976 <cprintf>
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
f0100469:	e8 48 10 00 00       	call   f01014b6 <memmove>
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
f0100616:	e8 5b 03 00 00       	call   f0100976 <cprintf>
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

f0100650 <mon_quit>:
	return 0;
}

int
mon_quit(int argc, char **argv, struct Trapframe *tf)
{
f0100650:	55                   	push   %ebp
f0100651:	89 e5                	mov    %esp,%ebp
    return -1;
}
f0100653:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100658:	5d                   	pop    %ebp
f0100659:	c3                   	ret    

f010065a <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010065a:	55                   	push   %ebp
f010065b:	89 e5                	mov    %esp,%ebp
f010065d:	56                   	push   %esi
f010065e:	53                   	push   %ebx
f010065f:	bb a0 1e 10 f0       	mov    $0xf0101ea0,%ebx
f0100664:	be d0 1e 10 f0       	mov    $0xf0101ed0,%esi
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100669:	83 ec 04             	sub    $0x4,%esp
f010066c:	ff 73 04             	pushl  0x4(%ebx)
f010066f:	ff 33                	pushl  (%ebx)
f0100671:	68 c0 1b 10 f0       	push   $0xf0101bc0
f0100676:	e8 fb 02 00 00       	call   f0100976 <cprintf>
f010067b:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
f010067e:	83 c4 10             	add    $0x10,%esp
f0100681:	39 f3                	cmp    %esi,%ebx
f0100683:	75 e4                	jne    f0100669 <mon_help+0xf>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f0100685:	b8 00 00 00 00       	mov    $0x0,%eax
f010068a:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010068d:	5b                   	pop    %ebx
f010068e:	5e                   	pop    %esi
f010068f:	5d                   	pop    %ebp
f0100690:	c3                   	ret    

f0100691 <mon_kerninfo>:
    return -1;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100691:	55                   	push   %ebp
f0100692:	89 e5                	mov    %esp,%ebp
f0100694:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100697:	68 c9 1b 10 f0       	push   $0xf0101bc9
f010069c:	e8 d5 02 00 00       	call   f0100976 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006a1:	83 c4 08             	add    $0x8,%esp
f01006a4:	68 0c 00 10 00       	push   $0x10000c
f01006a9:	68 c4 1c 10 f0       	push   $0xf0101cc4
f01006ae:	e8 c3 02 00 00       	call   f0100976 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006b3:	83 c4 0c             	add    $0xc,%esp
f01006b6:	68 0c 00 10 00       	push   $0x10000c
f01006bb:	68 0c 00 10 f0       	push   $0xf010000c
f01006c0:	68 ec 1c 10 f0       	push   $0xf0101cec
f01006c5:	e8 ac 02 00 00       	call   f0100976 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006ca:	83 c4 0c             	add    $0xc,%esp
f01006cd:	68 cd 18 10 00       	push   $0x1018cd
f01006d2:	68 cd 18 10 f0       	push   $0xf01018cd
f01006d7:	68 10 1d 10 f0       	push   $0xf0101d10
f01006dc:	e8 95 02 00 00       	call   f0100976 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006e1:	83 c4 0c             	add    $0xc,%esp
f01006e4:	68 00 23 11 00       	push   $0x112300
f01006e9:	68 00 23 11 f0       	push   $0xf0112300
f01006ee:	68 34 1d 10 f0       	push   $0xf0101d34
f01006f3:	e8 7e 02 00 00       	call   f0100976 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006f8:	83 c4 0c             	add    $0xc,%esp
f01006fb:	68 48 29 11 00       	push   $0x112948
f0100700:	68 48 29 11 f0       	push   $0xf0112948
f0100705:	68 58 1d 10 f0       	push   $0xf0101d58
f010070a:	e8 67 02 00 00       	call   f0100976 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010070f:	b8 47 2d 11 f0       	mov    $0xf0112d47,%eax
f0100714:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100719:	83 c4 08             	add    $0x8,%esp
f010071c:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100721:	89 c2                	mov    %eax,%edx
f0100723:	85 c0                	test   %eax,%eax
f0100725:	79 06                	jns    f010072d <mon_kerninfo+0x9c>
f0100727:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010072d:	c1 fa 0a             	sar    $0xa,%edx
f0100730:	52                   	push   %edx
f0100731:	68 7c 1d 10 f0       	push   $0xf0101d7c
f0100736:	e8 3b 02 00 00       	call   f0100976 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010073b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100740:	c9                   	leave  
f0100741:	c3                   	ret    

f0100742 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf) 
{
f0100742:	55                   	push   %ebp
f0100743:	89 e5                	mov    %esp,%ebp
f0100745:	56                   	push   %esi
f0100746:	53                   	push   %ebx
f0100747:	83 ec 2c             	sub    $0x2c,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f010074a:	89 eb                	mov    %ebp,%ebx
	// Your code here.
    uint32_t *ebp = (uint32_t *)read_ebp();
    cprintf("Stack backtrace:\n");
f010074c:	68 e2 1b 10 f0       	push   $0xf0101be2
f0100751:	e8 20 02 00 00       	call   f0100976 <cprintf>
    struct Eipdebuginfo eipInfo;

    while(ebp){
f0100756:	83 c4 10             	add    $0x10,%esp
        cprintf("ebp %x eip %x args %08x %08x %08x %08x %08x\n",ebp,*(ebp+1),*(ebp+2),*(ebp+3),*(ebp+4),*(ebp+5),*(ebp+6));
        debuginfo_eip(*(ebp+1), &eipInfo);
f0100759:	8d 75 e0             	lea    -0x20(%ebp),%esi
	// Your code here.
    uint32_t *ebp = (uint32_t *)read_ebp();
    cprintf("Stack backtrace:\n");
    struct Eipdebuginfo eipInfo;

    while(ebp){
f010075c:	eb 61                	jmp    f01007bf <mon_backtrace+0x7d>
        cprintf("ebp %x eip %x args %08x %08x %08x %08x %08x\n",ebp,*(ebp+1),*(ebp+2),*(ebp+3),*(ebp+4),*(ebp+5),*(ebp+6));
f010075e:	ff 73 18             	pushl  0x18(%ebx)
f0100761:	ff 73 14             	pushl  0x14(%ebx)
f0100764:	ff 73 10             	pushl  0x10(%ebx)
f0100767:	ff 73 0c             	pushl  0xc(%ebx)
f010076a:	ff 73 08             	pushl  0x8(%ebx)
f010076d:	ff 73 04             	pushl  0x4(%ebx)
f0100770:	53                   	push   %ebx
f0100771:	68 a8 1d 10 f0       	push   $0xf0101da8
f0100776:	e8 fb 01 00 00       	call   f0100976 <cprintf>
        debuginfo_eip(*(ebp+1), &eipInfo);
f010077b:	83 c4 18             	add    $0x18,%esp
f010077e:	56                   	push   %esi
f010077f:	ff 73 04             	pushl  0x4(%ebx)
f0100782:	e8 f6 02 00 00       	call   f0100a7d <debuginfo_eip>
        cprintf("\t%x\t%x\n",*(ebp+1),eipInfo.eip_fn_addr);
f0100787:	83 c4 0c             	add    $0xc,%esp
f010078a:	ff 75 f0             	pushl  -0x10(%ebp)
f010078d:	ff 73 04             	pushl  0x4(%ebx)
f0100790:	68 f4 1b 10 f0       	push   $0xf0101bf4
f0100795:	e8 dc 01 00 00       	call   f0100976 <cprintf>
        cprintf("\t%s:%d: %.*s+%d\n",eipInfo.eip_file,eipInfo.eip_line,eipInfo.eip_fn_namelen, eipInfo.eip_fn_name,(*(ebp+1) - eipInfo.eip_fn_addr));
f010079a:	83 c4 08             	add    $0x8,%esp
f010079d:	8b 43 04             	mov    0x4(%ebx),%eax
f01007a0:	2b 45 f0             	sub    -0x10(%ebp),%eax
f01007a3:	50                   	push   %eax
f01007a4:	ff 75 e8             	pushl  -0x18(%ebp)
f01007a7:	ff 75 ec             	pushl  -0x14(%ebp)
f01007aa:	ff 75 e4             	pushl  -0x1c(%ebp)
f01007ad:	ff 75 e0             	pushl  -0x20(%ebp)
f01007b0:	68 fc 1b 10 f0       	push   $0xf0101bfc
f01007b5:	e8 bc 01 00 00       	call   f0100976 <cprintf>
        ebp = (uint32_t *)(*ebp);
f01007ba:	8b 1b                	mov    (%ebx),%ebx
f01007bc:	83 c4 20             	add    $0x20,%esp
	// Your code here.
    uint32_t *ebp = (uint32_t *)read_ebp();
    cprintf("Stack backtrace:\n");
    struct Eipdebuginfo eipInfo;

    while(ebp){
f01007bf:	85 db                	test   %ebx,%ebx
f01007c1:	75 9b                	jne    f010075e <mon_backtrace+0x1c>
        cprintf("\t%x\t%x\n",*(ebp+1),eipInfo.eip_fn_addr);
        cprintf("\t%s:%d: %.*s+%d\n",eipInfo.eip_file,eipInfo.eip_line,eipInfo.eip_fn_namelen, eipInfo.eip_fn_name,(*(ebp+1) - eipInfo.eip_fn_addr));
        ebp = (uint32_t *)(*ebp);
    }
	return 0;
}
f01007c3:	b8 00 00 00 00       	mov    $0x0,%eax
f01007c8:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01007cb:	5b                   	pop    %ebx
f01007cc:	5e                   	pop    %esi
f01007cd:	5d                   	pop    %ebp
f01007ce:	c3                   	ret    

f01007cf <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007cf:	55                   	push   %ebp
f01007d0:	89 e5                	mov    %esp,%ebp
f01007d2:	57                   	push   %edi
f01007d3:	56                   	push   %esi
f01007d4:	53                   	push   %ebx
f01007d5:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007d8:	68 d8 1d 10 f0       	push   $0xf0101dd8
f01007dd:	e8 94 01 00 00       	call   f0100976 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007e2:	c7 04 24 fc 1d 10 f0 	movl   $0xf0101dfc,(%esp)
f01007e9:	e8 88 01 00 00       	call   f0100976 <cprintf>
    cprintf("%m%s\n%m%s\n%m%s\n", 0x0100, "blue", 0x0200, "green", 0x0400, "red");
f01007ee:	83 c4 0c             	add    $0xc,%esp
f01007f1:	68 0d 1c 10 f0       	push   $0xf0101c0d
f01007f6:	68 00 04 00 00       	push   $0x400
f01007fb:	68 11 1c 10 f0       	push   $0xf0101c11
f0100800:	68 00 02 00 00       	push   $0x200
f0100805:	68 17 1c 10 f0       	push   $0xf0101c17
f010080a:	68 00 01 00 00       	push   $0x100
f010080f:	68 1c 1c 10 f0       	push   $0xf0101c1c
f0100814:	e8 5d 01 00 00       	call   f0100976 <cprintf>

    int x = 1, y = 3, z = 4;//inserted
    cprintf("x %d, y %x, z %d\n", x, y, z);//inserted
f0100819:	83 c4 20             	add    $0x20,%esp
f010081c:	6a 04                	push   $0x4
f010081e:	6a 03                	push   $0x3
f0100820:	6a 01                	push   $0x1
f0100822:	68 2c 1c 10 f0       	push   $0xf0101c2c
f0100827:	e8 4a 01 00 00       	call   f0100976 <cprintf>
f010082c:	83 c4 10             	add    $0x10,%esp



	while (1) {
		buf = readline("K> ");
f010082f:	83 ec 0c             	sub    $0xc,%esp
f0100832:	68 3e 1c 10 f0       	push   $0xf0101c3e
f0100837:	e8 e0 09 00 00       	call   f010121c <readline>
f010083c:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f010083e:	83 c4 10             	add    $0x10,%esp
f0100841:	85 c0                	test   %eax,%eax
f0100843:	74 ea                	je     f010082f <monitor+0x60>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100845:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010084c:	be 00 00 00 00       	mov    $0x0,%esi
f0100851:	eb 0a                	jmp    f010085d <monitor+0x8e>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100853:	c6 03 00             	movb   $0x0,(%ebx)
f0100856:	89 f7                	mov    %esi,%edi
f0100858:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010085b:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010085d:	8a 03                	mov    (%ebx),%al
f010085f:	84 c0                	test   %al,%al
f0100861:	74 60                	je     f01008c3 <monitor+0xf4>
f0100863:	83 ec 08             	sub    $0x8,%esp
f0100866:	0f be c0             	movsbl %al,%eax
f0100869:	50                   	push   %eax
f010086a:	68 42 1c 10 f0       	push   $0xf0101c42
f010086f:	e8 c0 0b 00 00       	call   f0101434 <strchr>
f0100874:	83 c4 10             	add    $0x10,%esp
f0100877:	85 c0                	test   %eax,%eax
f0100879:	75 d8                	jne    f0100853 <monitor+0x84>
			*buf++ = 0;
		if (*buf == 0)
f010087b:	80 3b 00             	cmpb   $0x0,(%ebx)
f010087e:	74 43                	je     f01008c3 <monitor+0xf4>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100880:	83 fe 0f             	cmp    $0xf,%esi
f0100883:	75 14                	jne    f0100899 <monitor+0xca>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100885:	83 ec 08             	sub    $0x8,%esp
f0100888:	6a 10                	push   $0x10
f010088a:	68 47 1c 10 f0       	push   $0xf0101c47
f010088f:	e8 e2 00 00 00       	call   f0100976 <cprintf>
f0100894:	83 c4 10             	add    $0x10,%esp
f0100897:	eb 96                	jmp    f010082f <monitor+0x60>
			return 0;
		}
		argv[argc++] = buf;
f0100899:	8d 7e 01             	lea    0x1(%esi),%edi
f010089c:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008a0:	eb 01                	jmp    f01008a3 <monitor+0xd4>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01008a2:	43                   	inc    %ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008a3:	8a 03                	mov    (%ebx),%al
f01008a5:	84 c0                	test   %al,%al
f01008a7:	74 b2                	je     f010085b <monitor+0x8c>
f01008a9:	83 ec 08             	sub    $0x8,%esp
f01008ac:	0f be c0             	movsbl %al,%eax
f01008af:	50                   	push   %eax
f01008b0:	68 42 1c 10 f0       	push   $0xf0101c42
f01008b5:	e8 7a 0b 00 00       	call   f0101434 <strchr>
f01008ba:	83 c4 10             	add    $0x10,%esp
f01008bd:	85 c0                	test   %eax,%eax
f01008bf:	74 e1                	je     f01008a2 <monitor+0xd3>
f01008c1:	eb 98                	jmp    f010085b <monitor+0x8c>
			buf++;
	}
	argv[argc] = 0;
f01008c3:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008ca:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008cb:	85 f6                	test   %esi,%esi
f01008cd:	0f 84 5c ff ff ff    	je     f010082f <monitor+0x60>
f01008d3:	bf a0 1e 10 f0       	mov    $0xf0101ea0,%edi
f01008d8:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008dd:	83 ec 08             	sub    $0x8,%esp
f01008e0:	ff 37                	pushl  (%edi)
f01008e2:	ff 75 a8             	pushl  -0x58(%ebp)
f01008e5:	e8 f6 0a 00 00       	call   f01013e0 <strcmp>
f01008ea:	83 c4 10             	add    $0x10,%esp
f01008ed:	85 c0                	test   %eax,%eax
f01008ef:	75 23                	jne    f0100914 <monitor+0x145>
			return commands[i].func(argc, argv, tf);
f01008f1:	83 ec 04             	sub    $0x4,%esp
f01008f4:	8d 04 1b             	lea    (%ebx,%ebx,1),%eax
f01008f7:	01 c3                	add    %eax,%ebx
f01008f9:	ff 75 08             	pushl  0x8(%ebp)
f01008fc:	8d 45 a8             	lea    -0x58(%ebp),%eax
f01008ff:	50                   	push   %eax
f0100900:	56                   	push   %esi
f0100901:	ff 14 9d a8 1e 10 f0 	call   *-0xfefe158(,%ebx,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100908:	83 c4 10             	add    $0x10,%esp
f010090b:	85 c0                	test   %eax,%eax
f010090d:	78 26                	js     f0100935 <monitor+0x166>
f010090f:	e9 1b ff ff ff       	jmp    f010082f <monitor+0x60>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100914:	43                   	inc    %ebx
f0100915:	83 c7 0c             	add    $0xc,%edi
f0100918:	83 fb 04             	cmp    $0x4,%ebx
f010091b:	75 c0                	jne    f01008dd <monitor+0x10e>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f010091d:	83 ec 08             	sub    $0x8,%esp
f0100920:	ff 75 a8             	pushl  -0x58(%ebp)
f0100923:	68 64 1c 10 f0       	push   $0xf0101c64
f0100928:	e8 49 00 00 00       	call   f0100976 <cprintf>
f010092d:	83 c4 10             	add    $0x10,%esp
f0100930:	e9 fa fe ff ff       	jmp    f010082f <monitor+0x60>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100935:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100938:	5b                   	pop    %ebx
f0100939:	5e                   	pop    %esi
f010093a:	5f                   	pop    %edi
f010093b:	5d                   	pop    %ebp
f010093c:	c3                   	ret    

f010093d <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010093d:	55                   	push   %ebp
f010093e:	89 e5                	mov    %esp,%ebp
f0100940:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0100943:	ff 75 08             	pushl  0x8(%ebp)
f0100946:	e8 da fc ff ff       	call   f0100625 <cputchar>
	*cnt++;
}
f010094b:	83 c4 10             	add    $0x10,%esp
f010094e:	c9                   	leave  
f010094f:	c3                   	ret    

f0100950 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100950:	55                   	push   %ebp
f0100951:	89 e5                	mov    %esp,%ebp
f0100953:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0100956:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010095d:	ff 75 0c             	pushl  0xc(%ebp)
f0100960:	ff 75 08             	pushl  0x8(%ebp)
f0100963:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100966:	50                   	push   %eax
f0100967:	68 3d 09 10 f0       	push   $0xf010093d
f010096c:	e8 6a 04 00 00       	call   f0100ddb <vprintfmt>
	return cnt;
}
f0100971:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100974:	c9                   	leave  
f0100975:	c3                   	ret    

f0100976 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100976:	55                   	push   %ebp
f0100977:	89 e5                	mov    %esp,%ebp
f0100979:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010097c:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010097f:	50                   	push   %eax
f0100980:	ff 75 08             	pushl  0x8(%ebp)
f0100983:	e8 c8 ff ff ff       	call   f0100950 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100988:	c9                   	leave  
f0100989:	c3                   	ret    

f010098a <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010098a:	55                   	push   %ebp
f010098b:	89 e5                	mov    %esp,%ebp
f010098d:	57                   	push   %edi
f010098e:	56                   	push   %esi
f010098f:	53                   	push   %ebx
f0100990:	83 ec 14             	sub    $0x14,%esp
f0100993:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100996:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100999:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010099c:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010099f:	8b 1a                	mov    (%edx),%ebx
f01009a1:	8b 01                	mov    (%ecx),%eax
f01009a3:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009a6:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01009ad:	eb 7e                	jmp    f0100a2d <stab_binsearch+0xa3>
		int true_m = (l + r) / 2, m = true_m;
f01009af:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01009b2:	01 d8                	add    %ebx,%eax
f01009b4:	89 c6                	mov    %eax,%esi
f01009b6:	c1 ee 1f             	shr    $0x1f,%esi
f01009b9:	01 c6                	add    %eax,%esi
f01009bb:	d1 fe                	sar    %esi
f01009bd:	8d 04 36             	lea    (%esi,%esi,1),%eax
f01009c0:	01 f0                	add    %esi,%eax
f01009c2:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01009c5:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f01009c9:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009cb:	eb 01                	jmp    f01009ce <stab_binsearch+0x44>
			m--;
f01009cd:	48                   	dec    %eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009ce:	39 c3                	cmp    %eax,%ebx
f01009d0:	7f 0c                	jg     f01009de <stab_binsearch+0x54>
f01009d2:	0f b6 0a             	movzbl (%edx),%ecx
f01009d5:	83 ea 0c             	sub    $0xc,%edx
f01009d8:	39 f9                	cmp    %edi,%ecx
f01009da:	75 f1                	jne    f01009cd <stab_binsearch+0x43>
f01009dc:	eb 05                	jmp    f01009e3 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01009de:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01009e1:	eb 4a                	jmp    f0100a2d <stab_binsearch+0xa3>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01009e3:	8d 14 00             	lea    (%eax,%eax,1),%edx
f01009e6:	01 c2                	add    %eax,%edx
f01009e8:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01009eb:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01009ef:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01009f2:	76 11                	jbe    f0100a05 <stab_binsearch+0x7b>
			*region_left = m;
f01009f4:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01009f7:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01009f9:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009fc:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a03:	eb 28                	jmp    f0100a2d <stab_binsearch+0xa3>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a05:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a08:	73 12                	jae    f0100a1c <stab_binsearch+0x92>
			*region_right = m - 1;
f0100a0a:	48                   	dec    %eax
f0100a0b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a0e:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a11:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a13:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a1a:	eb 11                	jmp    f0100a2d <stab_binsearch+0xa3>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a1c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a1f:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100a21:	ff 45 0c             	incl   0xc(%ebp)
f0100a24:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a26:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100a2d:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a30:	0f 8e 79 ff ff ff    	jle    f01009af <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a36:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100a3a:	75 0d                	jne    f0100a49 <stab_binsearch+0xbf>
		*region_right = *region_left - 1;
f0100a3c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a3f:	8b 00                	mov    (%eax),%eax
f0100a41:	48                   	dec    %eax
f0100a42:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100a45:	89 07                	mov    %eax,(%edi)
f0100a47:	eb 2c                	jmp    f0100a75 <stab_binsearch+0xeb>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a49:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a4c:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a4e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a51:	8b 0e                	mov    (%esi),%ecx
f0100a53:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100a56:	01 c2                	add    %eax,%edx
f0100a58:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100a5b:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a5f:	eb 01                	jmp    f0100a62 <stab_binsearch+0xd8>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a61:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a62:	39 c8                	cmp    %ecx,%eax
f0100a64:	7e 0a                	jle    f0100a70 <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
f0100a66:	0f b6 1a             	movzbl (%edx),%ebx
f0100a69:	83 ea 0c             	sub    $0xc,%edx
f0100a6c:	39 df                	cmp    %ebx,%edi
f0100a6e:	75 f1                	jne    f0100a61 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a70:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100a73:	89 07                	mov    %eax,(%edi)
	}
}
f0100a75:	83 c4 14             	add    $0x14,%esp
f0100a78:	5b                   	pop    %ebx
f0100a79:	5e                   	pop    %esi
f0100a7a:	5f                   	pop    %edi
f0100a7b:	5d                   	pop    %ebp
f0100a7c:	c3                   	ret    

f0100a7d <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a7d:	55                   	push   %ebp
f0100a7e:	89 e5                	mov    %esp,%ebp
f0100a80:	57                   	push   %edi
f0100a81:	56                   	push   %esi
f0100a82:	53                   	push   %ebx
f0100a83:	83 ec 3c             	sub    $0x3c,%esp
f0100a86:	8b 75 08             	mov    0x8(%ebp),%esi
f0100a89:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100a8c:	c7 03 d0 1e 10 f0    	movl   $0xf0101ed0,(%ebx)
	info->eip_line = 0;
f0100a92:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100a99:	c7 43 08 d0 1e 10 f0 	movl   $0xf0101ed0,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100aa0:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100aa7:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100aaa:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100ab1:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100ab7:	76 11                	jbe    f0100aca <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100ab9:	b8 ad 72 10 f0       	mov    $0xf01072ad,%eax
f0100abe:	3d cd 59 10 f0       	cmp    $0xf01059cd,%eax
f0100ac3:	77 19                	ja     f0100ade <debuginfo_eip+0x61>
f0100ac5:	e9 c8 01 00 00       	jmp    f0100c92 <debuginfo_eip+0x215>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100aca:	83 ec 04             	sub    $0x4,%esp
f0100acd:	68 da 1e 10 f0       	push   $0xf0101eda
f0100ad2:	6a 7f                	push   $0x7f
f0100ad4:	68 e7 1e 10 f0       	push   $0xf0101ee7
f0100ad9:	e8 08 f6 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100ade:	80 3d ac 72 10 f0 00 	cmpb   $0x0,0xf01072ac
f0100ae5:	0f 85 ae 01 00 00    	jne    f0100c99 <debuginfo_eip+0x21c>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100aeb:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100af2:	b8 cc 59 10 f0       	mov    $0xf01059cc,%eax
f0100af7:	2d 08 21 10 f0       	sub    $0xf0102108,%eax
f0100afc:	c1 f8 02             	sar    $0x2,%eax
f0100aff:	8d 14 80             	lea    (%eax,%eax,4),%edx
f0100b02:	8d 14 90             	lea    (%eax,%edx,4),%edx
f0100b05:	8d 0c 90             	lea    (%eax,%edx,4),%ecx
f0100b08:	89 ca                	mov    %ecx,%edx
f0100b0a:	c1 e2 08             	shl    $0x8,%edx
f0100b0d:	01 d1                	add    %edx,%ecx
f0100b0f:	89 ca                	mov    %ecx,%edx
f0100b11:	c1 e2 10             	shl    $0x10,%edx
f0100b14:	01 ca                	add    %ecx,%edx
f0100b16:	01 d2                	add    %edx,%edx
f0100b18:	8d 44 10 ff          	lea    -0x1(%eax,%edx,1),%eax
f0100b1c:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b1f:	83 ec 08             	sub    $0x8,%esp
f0100b22:	56                   	push   %esi
f0100b23:	6a 64                	push   $0x64
f0100b25:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b28:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b2b:	b8 08 21 10 f0       	mov    $0xf0102108,%eax
f0100b30:	e8 55 fe ff ff       	call   f010098a <stab_binsearch>
	if (lfile == 0)
f0100b35:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b38:	83 c4 10             	add    $0x10,%esp
f0100b3b:	85 c0                	test   %eax,%eax
f0100b3d:	0f 84 5d 01 00 00    	je     f0100ca0 <debuginfo_eip+0x223>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b43:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b46:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b49:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b4c:	83 ec 08             	sub    $0x8,%esp
f0100b4f:	56                   	push   %esi
f0100b50:	6a 24                	push   $0x24
f0100b52:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b55:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b58:	b8 08 21 10 f0       	mov    $0xf0102108,%eax
f0100b5d:	e8 28 fe ff ff       	call   f010098a <stab_binsearch>

	if (lfun <= rfun) {
f0100b62:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100b65:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100b68:	83 c4 10             	add    $0x10,%esp
f0100b6b:	39 d0                	cmp    %edx,%eax
f0100b6d:	7f 42                	jg     f0100bb1 <debuginfo_eip+0x134>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b6f:	8d 0c 00             	lea    (%eax,%eax,1),%ecx
f0100b72:	01 c1                	add    %eax,%ecx
f0100b74:	c1 e1 02             	shl    $0x2,%ecx
f0100b77:	8d b9 08 21 10 f0    	lea    -0xfefdef8(%ecx),%edi
f0100b7d:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100b80:	8b 89 08 21 10 f0    	mov    -0xfefdef8(%ecx),%ecx
f0100b86:	bf ad 72 10 f0       	mov    $0xf01072ad,%edi
f0100b8b:	81 ef cd 59 10 f0    	sub    $0xf01059cd,%edi
f0100b91:	39 f9                	cmp    %edi,%ecx
f0100b93:	73 09                	jae    f0100b9e <debuginfo_eip+0x121>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b95:	81 c1 cd 59 10 f0    	add    $0xf01059cd,%ecx
f0100b9b:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100b9e:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100ba1:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100ba4:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100ba7:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100ba9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100bac:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100baf:	eb 0f                	jmp    f0100bc0 <debuginfo_eip+0x143>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100bb1:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100bb4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bb7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100bba:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bbd:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100bc0:	83 ec 08             	sub    $0x8,%esp
f0100bc3:	6a 3a                	push   $0x3a
f0100bc5:	ff 73 08             	pushl  0x8(%ebx)
f0100bc8:	e8 84 08 00 00       	call   f0101451 <strfind>
f0100bcd:	2b 43 08             	sub    0x8(%ebx),%eax
f0100bd0:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
    stab_binsearch(stabs,&lline,&rline,N_SLINE,addr);
f0100bd3:	83 c4 08             	add    $0x8,%esp
f0100bd6:	56                   	push   %esi
f0100bd7:	6a 44                	push   $0x44
f0100bd9:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100bdc:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100bdf:	b8 08 21 10 f0       	mov    $0xf0102108,%eax
f0100be4:	e8 a1 fd ff ff       	call   f010098a <stab_binsearch>
    if (lline <= rline){
f0100be9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100bec:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0100bef:	83 c4 10             	add    $0x10,%esp
f0100bf2:	39 d0                	cmp    %edx,%eax
f0100bf4:	7f 12                	jg     f0100c08 <debuginfo_eip+0x18b>
        info->eip_line = stabs[rline].n_desc;
f0100bf6:	8d 0c 12             	lea    (%edx,%edx,1),%ecx
f0100bf9:	01 ca                	add    %ecx,%edx
f0100bfb:	0f b7 14 95 0e 21 10 	movzwl -0xfefdef2(,%edx,4),%edx
f0100c02:	f0 
f0100c03:	89 53 04             	mov    %edx,0x4(%ebx)
f0100c06:	eb 07                	jmp    f0100c0f <debuginfo_eip+0x192>
    } else{
        info->eip_line = -1;
f0100c08:	c7 43 04 ff ff ff ff 	movl   $0xffffffff,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c0f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100c12:	89 c2                	mov    %eax,%edx
f0100c14:	8d 0c 00             	lea    (%eax,%eax,1),%ecx
f0100c17:	01 c8                	add    %ecx,%eax
f0100c19:	8d 04 85 10 21 10 f0 	lea    -0xfefdef0(,%eax,4),%eax
f0100c20:	eb 04                	jmp    f0100c26 <debuginfo_eip+0x1a9>
f0100c22:	4a                   	dec    %edx
f0100c23:	83 e8 0c             	sub    $0xc,%eax
f0100c26:	39 d7                	cmp    %edx,%edi
f0100c28:	7f 34                	jg     f0100c5e <debuginfo_eip+0x1e1>
	       && stabs[lline].n_type != N_SOL
f0100c2a:	8a 48 fc             	mov    -0x4(%eax),%cl
f0100c2d:	80 f9 84             	cmp    $0x84,%cl
f0100c30:	74 0a                	je     f0100c3c <debuginfo_eip+0x1bf>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c32:	80 f9 64             	cmp    $0x64,%cl
f0100c35:	75 eb                	jne    f0100c22 <debuginfo_eip+0x1a5>
f0100c37:	83 38 00             	cmpl   $0x0,(%eax)
f0100c3a:	74 e6                	je     f0100c22 <debuginfo_eip+0x1a5>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c3c:	8d 04 12             	lea    (%edx,%edx,1),%eax
f0100c3f:	01 c2                	add    %eax,%edx
f0100c41:	8b 14 95 08 21 10 f0 	mov    -0xfefdef8(,%edx,4),%edx
f0100c48:	b8 ad 72 10 f0       	mov    $0xf01072ad,%eax
f0100c4d:	2d cd 59 10 f0       	sub    $0xf01059cd,%eax
f0100c52:	39 c2                	cmp    %eax,%edx
f0100c54:	73 08                	jae    f0100c5e <debuginfo_eip+0x1e1>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c56:	81 c2 cd 59 10 f0    	add    $0xf01059cd,%edx
f0100c5c:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c5e:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c61:	8b 75 d8             	mov    -0x28(%ebp),%esi
f0100c64:	39 f2                	cmp    %esi,%edx
f0100c66:	7d 3f                	jge    f0100ca7 <debuginfo_eip+0x22a>
		for (lline = lfun + 1;
f0100c68:	42                   	inc    %edx
f0100c69:	89 d0                	mov    %edx,%eax
f0100c6b:	8d 0c 12             	lea    (%edx,%edx,1),%ecx
f0100c6e:	01 ca                	add    %ecx,%edx
f0100c70:	8d 14 95 0c 21 10 f0 	lea    -0xfefdef4(,%edx,4),%edx
f0100c77:	eb 03                	jmp    f0100c7c <debuginfo_eip+0x1ff>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100c79:	ff 43 14             	incl   0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c7c:	39 c6                	cmp    %eax,%esi
f0100c7e:	7e 2e                	jle    f0100cae <debuginfo_eip+0x231>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c80:	8a 0a                	mov    (%edx),%cl
f0100c82:	40                   	inc    %eax
f0100c83:	83 c2 0c             	add    $0xc,%edx
f0100c86:	80 f9 a0             	cmp    $0xa0,%cl
f0100c89:	74 ee                	je     f0100c79 <debuginfo_eip+0x1fc>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c8b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c90:	eb 21                	jmp    f0100cb3 <debuginfo_eip+0x236>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100c92:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c97:	eb 1a                	jmp    f0100cb3 <debuginfo_eip+0x236>
f0100c99:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c9e:	eb 13                	jmp    f0100cb3 <debuginfo_eip+0x236>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100ca0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ca5:	eb 0c                	jmp    f0100cb3 <debuginfo_eip+0x236>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100ca7:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cac:	eb 05                	jmp    f0100cb3 <debuginfo_eip+0x236>
f0100cae:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100cb3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100cb6:	5b                   	pop    %ebx
f0100cb7:	5e                   	pop    %esi
f0100cb8:	5f                   	pop    %edi
f0100cb9:	5d                   	pop    %ebp
f0100cba:	c3                   	ret    

f0100cbb <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100cbb:	55                   	push   %ebp
f0100cbc:	89 e5                	mov    %esp,%ebp
f0100cbe:	57                   	push   %edi
f0100cbf:	56                   	push   %esi
f0100cc0:	53                   	push   %ebx
f0100cc1:	83 ec 1c             	sub    $0x1c,%esp
f0100cc4:	89 c7                	mov    %eax,%edi
f0100cc6:	89 d6                	mov    %edx,%esi
f0100cc8:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ccb:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100cce:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100cd1:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100cd4:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100cd7:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100cdc:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100cdf:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100ce2:	39 d3                	cmp    %edx,%ebx
f0100ce4:	72 05                	jb     f0100ceb <printnum+0x30>
f0100ce6:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100ce9:	77 45                	ja     f0100d30 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100ceb:	83 ec 0c             	sub    $0xc,%esp
f0100cee:	ff 75 18             	pushl  0x18(%ebp)
f0100cf1:	8b 45 14             	mov    0x14(%ebp),%eax
f0100cf4:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100cf7:	53                   	push   %ebx
f0100cf8:	ff 75 10             	pushl  0x10(%ebp)
f0100cfb:	83 ec 08             	sub    $0x8,%esp
f0100cfe:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d01:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d04:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d07:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d0a:	e8 5d 09 00 00       	call   f010166c <__udivdi3>
f0100d0f:	83 c4 18             	add    $0x18,%esp
f0100d12:	52                   	push   %edx
f0100d13:	50                   	push   %eax
f0100d14:	89 f2                	mov    %esi,%edx
f0100d16:	89 f8                	mov    %edi,%eax
f0100d18:	e8 9e ff ff ff       	call   f0100cbb <printnum>
f0100d1d:	83 c4 20             	add    $0x20,%esp
f0100d20:	eb 16                	jmp    f0100d38 <printnum+0x7d>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d22:	83 ec 08             	sub    $0x8,%esp
f0100d25:	56                   	push   %esi
f0100d26:	ff 75 18             	pushl  0x18(%ebp)
f0100d29:	ff d7                	call   *%edi
f0100d2b:	83 c4 10             	add    $0x10,%esp
f0100d2e:	eb 03                	jmp    f0100d33 <printnum+0x78>
f0100d30:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d33:	4b                   	dec    %ebx
f0100d34:	85 db                	test   %ebx,%ebx
f0100d36:	7f ea                	jg     f0100d22 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d38:	83 ec 08             	sub    $0x8,%esp
f0100d3b:	56                   	push   %esi
f0100d3c:	83 ec 04             	sub    $0x4,%esp
f0100d3f:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d42:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d45:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d48:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d4b:	e8 2c 0a 00 00       	call   f010177c <__umoddi3>
f0100d50:	83 c4 14             	add    $0x14,%esp
f0100d53:	0f be 80 f5 1e 10 f0 	movsbl -0xfefe10b(%eax),%eax
f0100d5a:	50                   	push   %eax
f0100d5b:	ff d7                	call   *%edi
}
f0100d5d:	83 c4 10             	add    $0x10,%esp
f0100d60:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d63:	5b                   	pop    %ebx
f0100d64:	5e                   	pop    %esi
f0100d65:	5f                   	pop    %edi
f0100d66:	5d                   	pop    %ebp
f0100d67:	c3                   	ret    

f0100d68 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100d68:	55                   	push   %ebp
f0100d69:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100d6b:	83 fa 01             	cmp    $0x1,%edx
f0100d6e:	7e 0e                	jle    f0100d7e <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100d70:	8b 10                	mov    (%eax),%edx
f0100d72:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100d75:	89 08                	mov    %ecx,(%eax)
f0100d77:	8b 02                	mov    (%edx),%eax
f0100d79:	8b 52 04             	mov    0x4(%edx),%edx
f0100d7c:	eb 22                	jmp    f0100da0 <getuint+0x38>
	else if (lflag)
f0100d7e:	85 d2                	test   %edx,%edx
f0100d80:	74 10                	je     f0100d92 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100d82:	8b 10                	mov    (%eax),%edx
f0100d84:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d87:	89 08                	mov    %ecx,(%eax)
f0100d89:	8b 02                	mov    (%edx),%eax
f0100d8b:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d90:	eb 0e                	jmp    f0100da0 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100d92:	8b 10                	mov    (%eax),%edx
f0100d94:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d97:	89 08                	mov    %ecx,(%eax)
f0100d99:	8b 02                	mov    (%edx),%eax
f0100d9b:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100da0:	5d                   	pop    %ebp
f0100da1:	c3                   	ret    

f0100da2 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100da2:	55                   	push   %ebp
f0100da3:	89 e5                	mov    %esp,%ebp
f0100da5:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100da8:	ff 40 08             	incl   0x8(%eax)
	if (b->buf < b->ebuf)
f0100dab:	8b 10                	mov    (%eax),%edx
f0100dad:	3b 50 04             	cmp    0x4(%eax),%edx
f0100db0:	73 0a                	jae    f0100dbc <sprintputch+0x1a>
		*b->buf++ = ch;
f0100db2:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100db5:	89 08                	mov    %ecx,(%eax)
f0100db7:	8b 45 08             	mov    0x8(%ebp),%eax
f0100dba:	88 02                	mov    %al,(%edx)
}
f0100dbc:	5d                   	pop    %ebp
f0100dbd:	c3                   	ret    

f0100dbe <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100dbe:	55                   	push   %ebp
f0100dbf:	89 e5                	mov    %esp,%ebp
f0100dc1:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100dc4:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100dc7:	50                   	push   %eax
f0100dc8:	ff 75 10             	pushl  0x10(%ebp)
f0100dcb:	ff 75 0c             	pushl  0xc(%ebp)
f0100dce:	ff 75 08             	pushl  0x8(%ebp)
f0100dd1:	e8 05 00 00 00       	call   f0100ddb <vprintfmt>
	va_end(ap);
}
f0100dd6:	83 c4 10             	add    $0x10,%esp
f0100dd9:	c9                   	leave  
f0100dda:	c3                   	ret    

f0100ddb <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100ddb:	55                   	push   %ebp
f0100ddc:	89 e5                	mov    %esp,%ebp
f0100dde:	57                   	push   %edi
f0100ddf:	56                   	push   %esi
f0100de0:	53                   	push   %ebx
f0100de1:	83 ec 2c             	sub    $0x2c,%esp
f0100de4:	8b 75 08             	mov    0x8(%ebp),%esi
f0100de7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100dea:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100ded:	eb 1d                	jmp    f0100e0c <vprintfmt+0x31>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0'){
f0100def:	85 c0                	test   %eax,%eax
f0100df1:	75 0f                	jne    f0100e02 <vprintfmt+0x27>
                ccolor = 0x0700;
f0100df3:	c7 05 44 29 11 f0 00 	movl   $0x700,0xf0112944
f0100dfa:	07 00 00 
				return;
f0100dfd:	e9 a3 03 00 00       	jmp    f01011a5 <vprintfmt+0x3ca>
            }
			putch(ch, putdat);
f0100e02:	83 ec 08             	sub    $0x8,%esp
f0100e05:	53                   	push   %ebx
f0100e06:	50                   	push   %eax
f0100e07:	ff d6                	call   *%esi
f0100e09:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100e0c:	47                   	inc    %edi
f0100e0d:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100e11:	83 f8 25             	cmp    $0x25,%eax
f0100e14:	75 d9                	jne    f0100def <vprintfmt+0x14>
f0100e16:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100e1a:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100e21:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100e28:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100e2f:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e34:	eb 07                	jmp    f0100e3d <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e36:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100e39:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e3d:	8d 47 01             	lea    0x1(%edi),%eax
f0100e40:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100e43:	0f b6 0f             	movzbl (%edi),%ecx
f0100e46:	8a 07                	mov    (%edi),%al
f0100e48:	83 e8 23             	sub    $0x23,%eax
f0100e4b:	3c 55                	cmp    $0x55,%al
f0100e4d:	0f 87 39 03 00 00    	ja     f010118c <vprintfmt+0x3b1>
f0100e53:	0f b6 c0             	movzbl %al,%eax
f0100e56:	ff 24 85 84 1f 10 f0 	jmp    *-0xfefe07c(,%eax,4)
f0100e5d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100e60:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100e64:	eb d7                	jmp    f0100e3d <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e66:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e69:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e6e:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100e71:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100e74:	01 c0                	add    %eax,%eax
f0100e76:	8d 44 01 d0          	lea    -0x30(%ecx,%eax,1),%eax
				ch = *fmt;
f0100e7a:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0100e7d:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0100e80:	83 fa 09             	cmp    $0x9,%edx
f0100e83:	77 34                	ja     f0100eb9 <vprintfmt+0xde>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e85:	47                   	inc    %edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100e86:	eb e9                	jmp    f0100e71 <vprintfmt+0x96>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100e88:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e8b:	8d 48 04             	lea    0x4(%eax),%ecx
f0100e8e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100e91:	8b 00                	mov    (%eax),%eax
f0100e93:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e96:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100e99:	eb 24                	jmp    f0100ebf <vprintfmt+0xe4>
f0100e9b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100e9f:	79 07                	jns    f0100ea8 <vprintfmt+0xcd>
f0100ea1:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ea8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100eab:	eb 90                	jmp    f0100e3d <vprintfmt+0x62>
f0100ead:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100eb0:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100eb7:	eb 84                	jmp    f0100e3d <vprintfmt+0x62>
f0100eb9:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100ebc:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100ebf:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100ec3:	0f 89 74 ff ff ff    	jns    f0100e3d <vprintfmt+0x62>
				width = precision, precision = -1;
f0100ec9:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100ecc:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100ecf:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100ed6:	e9 62 ff ff ff       	jmp    f0100e3d <vprintfmt+0x62>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100edb:	42                   	inc    %edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100edc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100edf:	e9 59 ff ff ff       	jmp    f0100e3d <vprintfmt+0x62>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100ee4:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ee7:	8d 50 04             	lea    0x4(%eax),%edx
f0100eea:	89 55 14             	mov    %edx,0x14(%ebp)
f0100eed:	83 ec 08             	sub    $0x8,%esp
f0100ef0:	53                   	push   %ebx
f0100ef1:	ff 30                	pushl  (%eax)
f0100ef3:	ff d6                	call   *%esi
			break;
f0100ef5:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ef8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100efb:	e9 0c ff ff ff       	jmp    f0100e0c <vprintfmt+0x31>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100f00:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f03:	8d 50 04             	lea    0x4(%eax),%edx
f0100f06:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f09:	8b 00                	mov    (%eax),%eax
f0100f0b:	85 c0                	test   %eax,%eax
f0100f0d:	79 02                	jns    f0100f11 <vprintfmt+0x136>
f0100f0f:	f7 d8                	neg    %eax
f0100f11:	89 c2                	mov    %eax,%edx
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f13:	83 f8 06             	cmp    $0x6,%eax
f0100f16:	7f 0b                	jg     f0100f23 <vprintfmt+0x148>
f0100f18:	8b 04 85 dc 20 10 f0 	mov    -0xfefdf24(,%eax,4),%eax
f0100f1f:	85 c0                	test   %eax,%eax
f0100f21:	75 18                	jne    f0100f3b <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0100f23:	52                   	push   %edx
f0100f24:	68 0d 1f 10 f0       	push   $0xf0101f0d
f0100f29:	53                   	push   %ebx
f0100f2a:	56                   	push   %esi
f0100f2b:	e8 8e fe ff ff       	call   f0100dbe <printfmt>
f0100f30:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f33:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100f36:	e9 d1 fe ff ff       	jmp    f0100e0c <vprintfmt+0x31>
			else
				printfmt(putch, putdat, "%s", p);
f0100f3b:	50                   	push   %eax
f0100f3c:	68 16 1f 10 f0       	push   $0xf0101f16
f0100f41:	53                   	push   %ebx
f0100f42:	56                   	push   %esi
f0100f43:	e8 76 fe ff ff       	call   f0100dbe <printfmt>
f0100f48:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f4b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f4e:	e9 b9 fe ff ff       	jmp    f0100e0c <vprintfmt+0x31>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f53:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f56:	8d 50 04             	lea    0x4(%eax),%edx
f0100f59:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f5c:	8b 38                	mov    (%eax),%edi
f0100f5e:	85 ff                	test   %edi,%edi
f0100f60:	75 05                	jne    f0100f67 <vprintfmt+0x18c>
				p = "(null)";
f0100f62:	bf 06 1f 10 f0       	mov    $0xf0101f06,%edi
			if (width > 0 && padc != '-')
f0100f67:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100f6b:	0f 8e 90 00 00 00    	jle    f0101001 <vprintfmt+0x226>
f0100f71:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100f75:	0f 84 8e 00 00 00    	je     f0101009 <vprintfmt+0x22e>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f7b:	83 ec 08             	sub    $0x8,%esp
f0100f7e:	ff 75 d0             	pushl  -0x30(%ebp)
f0100f81:	57                   	push   %edi
f0100f82:	e8 9b 03 00 00       	call   f0101322 <strnlen>
f0100f87:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100f8a:	29 c1                	sub    %eax,%ecx
f0100f8c:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0100f8f:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0100f92:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0100f96:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f99:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100f9c:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f9e:	eb 0d                	jmp    f0100fad <vprintfmt+0x1d2>
					putch(padc, putdat);
f0100fa0:	83 ec 08             	sub    $0x8,%esp
f0100fa3:	53                   	push   %ebx
f0100fa4:	ff 75 e0             	pushl  -0x20(%ebp)
f0100fa7:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fa9:	4f                   	dec    %edi
f0100faa:	83 c4 10             	add    $0x10,%esp
f0100fad:	85 ff                	test   %edi,%edi
f0100faf:	7f ef                	jg     f0100fa0 <vprintfmt+0x1c5>
f0100fb1:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100fb4:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0100fb7:	89 c8                	mov    %ecx,%eax
f0100fb9:	85 c9                	test   %ecx,%ecx
f0100fbb:	79 05                	jns    f0100fc2 <vprintfmt+0x1e7>
f0100fbd:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fc2:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0100fc5:	29 c1                	sub    %eax,%ecx
f0100fc7:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100fca:	89 75 08             	mov    %esi,0x8(%ebp)
f0100fcd:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100fd0:	eb 3d                	jmp    f010100f <vprintfmt+0x234>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100fd2:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100fd6:	74 19                	je     f0100ff1 <vprintfmt+0x216>
f0100fd8:	0f be c0             	movsbl %al,%eax
f0100fdb:	83 e8 20             	sub    $0x20,%eax
f0100fde:	83 f8 5e             	cmp    $0x5e,%eax
f0100fe1:	76 0e                	jbe    f0100ff1 <vprintfmt+0x216>
					putch('?', putdat);
f0100fe3:	83 ec 08             	sub    $0x8,%esp
f0100fe6:	53                   	push   %ebx
f0100fe7:	6a 3f                	push   $0x3f
f0100fe9:	ff 55 08             	call   *0x8(%ebp)
f0100fec:	83 c4 10             	add    $0x10,%esp
f0100fef:	eb 0b                	jmp    f0100ffc <vprintfmt+0x221>
				else
					putch(ch, putdat);
f0100ff1:	83 ec 08             	sub    $0x8,%esp
f0100ff4:	53                   	push   %ebx
f0100ff5:	52                   	push   %edx
f0100ff6:	ff 55 08             	call   *0x8(%ebp)
f0100ff9:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100ffc:	ff 4d e0             	decl   -0x20(%ebp)
f0100fff:	eb 0e                	jmp    f010100f <vprintfmt+0x234>
f0101001:	89 75 08             	mov    %esi,0x8(%ebp)
f0101004:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101007:	eb 06                	jmp    f010100f <vprintfmt+0x234>
f0101009:	89 75 08             	mov    %esi,0x8(%ebp)
f010100c:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010100f:	47                   	inc    %edi
f0101010:	8a 47 ff             	mov    -0x1(%edi),%al
f0101013:	0f be d0             	movsbl %al,%edx
f0101016:	85 d2                	test   %edx,%edx
f0101018:	74 1d                	je     f0101037 <vprintfmt+0x25c>
f010101a:	85 f6                	test   %esi,%esi
f010101c:	78 b4                	js     f0100fd2 <vprintfmt+0x1f7>
f010101e:	4e                   	dec    %esi
f010101f:	79 b1                	jns    f0100fd2 <vprintfmt+0x1f7>
f0101021:	8b 75 08             	mov    0x8(%ebp),%esi
f0101024:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101027:	eb 14                	jmp    f010103d <vprintfmt+0x262>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101029:	83 ec 08             	sub    $0x8,%esp
f010102c:	53                   	push   %ebx
f010102d:	6a 20                	push   $0x20
f010102f:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101031:	4f                   	dec    %edi
f0101032:	83 c4 10             	add    $0x10,%esp
f0101035:	eb 06                	jmp    f010103d <vprintfmt+0x262>
f0101037:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010103a:	8b 75 08             	mov    0x8(%ebp),%esi
f010103d:	85 ff                	test   %edi,%edi
f010103f:	7f e8                	jg     f0101029 <vprintfmt+0x24e>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101041:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101044:	e9 c3 fd ff ff       	jmp    f0100e0c <vprintfmt+0x31>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101049:	83 fa 01             	cmp    $0x1,%edx
f010104c:	7e 16                	jle    f0101064 <vprintfmt+0x289>
		return va_arg(*ap, long long);
f010104e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101051:	8d 50 08             	lea    0x8(%eax),%edx
f0101054:	89 55 14             	mov    %edx,0x14(%ebp)
f0101057:	8b 50 04             	mov    0x4(%eax),%edx
f010105a:	8b 00                	mov    (%eax),%eax
f010105c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010105f:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101062:	eb 32                	jmp    f0101096 <vprintfmt+0x2bb>
	else if (lflag)
f0101064:	85 d2                	test   %edx,%edx
f0101066:	74 18                	je     f0101080 <vprintfmt+0x2a5>
		return va_arg(*ap, long);
f0101068:	8b 45 14             	mov    0x14(%ebp),%eax
f010106b:	8d 50 04             	lea    0x4(%eax),%edx
f010106e:	89 55 14             	mov    %edx,0x14(%ebp)
f0101071:	8b 00                	mov    (%eax),%eax
f0101073:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101076:	89 c1                	mov    %eax,%ecx
f0101078:	c1 f9 1f             	sar    $0x1f,%ecx
f010107b:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010107e:	eb 16                	jmp    f0101096 <vprintfmt+0x2bb>
	else
		return va_arg(*ap, int);
f0101080:	8b 45 14             	mov    0x14(%ebp),%eax
f0101083:	8d 50 04             	lea    0x4(%eax),%edx
f0101086:	89 55 14             	mov    %edx,0x14(%ebp)
f0101089:	8b 00                	mov    (%eax),%eax
f010108b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010108e:	89 c1                	mov    %eax,%ecx
f0101090:	c1 f9 1f             	sar    $0x1f,%ecx
f0101093:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101096:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101099:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
f010109c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01010a0:	79 76                	jns    f0101118 <vprintfmt+0x33d>
				putch('-', putdat);
f01010a2:	83 ec 08             	sub    $0x8,%esp
f01010a5:	53                   	push   %ebx
f01010a6:	6a 2d                	push   $0x2d
f01010a8:	ff d6                	call   *%esi
				num = -(long long) num;
f01010aa:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01010ad:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01010b0:	f7 d8                	neg    %eax
f01010b2:	83 d2 00             	adc    $0x0,%edx
f01010b5:	f7 da                	neg    %edx
f01010b7:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f01010ba:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01010bf:	eb 5c                	jmp    f010111d <vprintfmt+0x342>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01010c1:	8d 45 14             	lea    0x14(%ebp),%eax
f01010c4:	e8 9f fc ff ff       	call   f0100d68 <getuint>
			base = 10;
f01010c9:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01010ce:	eb 4d                	jmp    f010111d <vprintfmt+0x342>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
            num = getuint(&ap,lflag);
f01010d0:	8d 45 14             	lea    0x14(%ebp),%eax
f01010d3:	e8 90 fc ff ff       	call   f0100d68 <getuint>
            base = 8;
f01010d8:	b9 08 00 00 00       	mov    $0x8,%ecx
            goto number;
f01010dd:	eb 3e                	jmp    f010111d <vprintfmt+0x342>
			//putch('X', putdat);
			//break;

		// pointer
		case 'p':
			putch('0', putdat);
f01010df:	83 ec 08             	sub    $0x8,%esp
f01010e2:	53                   	push   %ebx
f01010e3:	6a 30                	push   $0x30
f01010e5:	ff d6                	call   *%esi
			putch('x', putdat);
f01010e7:	83 c4 08             	add    $0x8,%esp
f01010ea:	53                   	push   %ebx
f01010eb:	6a 78                	push   $0x78
f01010ed:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01010ef:	8b 45 14             	mov    0x14(%ebp),%eax
f01010f2:	8d 50 04             	lea    0x4(%eax),%edx
f01010f5:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01010f8:	8b 00                	mov    (%eax),%eax
f01010fa:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01010ff:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0101102:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101107:	eb 14                	jmp    f010111d <vprintfmt+0x342>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101109:	8d 45 14             	lea    0x14(%ebp),%eax
f010110c:	e8 57 fc ff ff       	call   f0100d68 <getuint>
			base = 16;
f0101111:	b9 10 00 00 00       	mov    $0x10,%ecx
f0101116:	eb 05                	jmp    f010111d <vprintfmt+0x342>
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101118:	b9 0a 00 00 00       	mov    $0xa,%ecx
			num = getuint(&ap, lflag);
			base = 16;


		number:
			printnum(putch, putdat, num, base, width, padc);
f010111d:	83 ec 0c             	sub    $0xc,%esp
f0101120:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101124:	57                   	push   %edi
f0101125:	ff 75 e0             	pushl  -0x20(%ebp)
f0101128:	51                   	push   %ecx
f0101129:	52                   	push   %edx
f010112a:	50                   	push   %eax
f010112b:	89 da                	mov    %ebx,%edx
f010112d:	89 f0                	mov    %esi,%eax
f010112f:	e8 87 fb ff ff       	call   f0100cbb <printnum>
			break;
f0101134:	83 c4 20             	add    $0x20,%esp
f0101137:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010113a:	e9 cd fc ff ff       	jmp    f0100e0c <vprintfmt+0x31>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010113f:	83 ec 08             	sub    $0x8,%esp
f0101142:	53                   	push   %ebx
f0101143:	51                   	push   %ecx
f0101144:	ff d6                	call   *%esi
			break;
f0101146:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101149:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f010114c:	e9 bb fc ff ff       	jmp    f0100e0c <vprintfmt+0x31>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101151:	83 fa 01             	cmp    $0x1,%edx
f0101154:	7e 0d                	jle    f0101163 <vprintfmt+0x388>
		return va_arg(*ap, long long);
f0101156:	8b 45 14             	mov    0x14(%ebp),%eax
f0101159:	8d 50 08             	lea    0x8(%eax),%edx
f010115c:	89 55 14             	mov    %edx,0x14(%ebp)
f010115f:	8b 00                	mov    (%eax),%eax
f0101161:	eb 1c                	jmp    f010117f <vprintfmt+0x3a4>
	else if (lflag)
f0101163:	85 d2                	test   %edx,%edx
f0101165:	74 0d                	je     f0101174 <vprintfmt+0x399>
		return va_arg(*ap, long);
f0101167:	8b 45 14             	mov    0x14(%ebp),%eax
f010116a:	8d 50 04             	lea    0x4(%eax),%edx
f010116d:	89 55 14             	mov    %edx,0x14(%ebp)
f0101170:	8b 00                	mov    (%eax),%eax
f0101172:	eb 0b                	jmp    f010117f <vprintfmt+0x3a4>
	else
		return va_arg(*ap, int);
f0101174:	8b 45 14             	mov    0x14(%ebp),%eax
f0101177:	8d 50 04             	lea    0x4(%eax),%edx
f010117a:	89 55 14             	mov    %edx,0x14(%ebp)
f010117d:	8b 00                	mov    (%eax),%eax
		case '%':
			putch(ch, putdat);
			break;

        case 'm':
            ccolor = getint(&ap,lflag);
f010117f:	a3 44 29 11 f0       	mov    %eax,0xf0112944
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101184:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			putch(ch, putdat);
			break;

        case 'm':
            ccolor = getint(&ap,lflag);
            break;
f0101187:	e9 80 fc ff ff       	jmp    f0100e0c <vprintfmt+0x31>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010118c:	83 ec 08             	sub    $0x8,%esp
f010118f:	53                   	push   %ebx
f0101190:	6a 25                	push   $0x25
f0101192:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101194:	83 c4 10             	add    $0x10,%esp
f0101197:	eb 01                	jmp    f010119a <vprintfmt+0x3bf>
f0101199:	4f                   	dec    %edi
f010119a:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f010119e:	75 f9                	jne    f0101199 <vprintfmt+0x3be>
f01011a0:	e9 67 fc ff ff       	jmp    f0100e0c <vprintfmt+0x31>
				/* do nothing */;
			break;
		}
	}
}
f01011a5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011a8:	5b                   	pop    %ebx
f01011a9:	5e                   	pop    %esi
f01011aa:	5f                   	pop    %edi
f01011ab:	5d                   	pop    %ebp
f01011ac:	c3                   	ret    

f01011ad <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01011ad:	55                   	push   %ebp
f01011ae:	89 e5                	mov    %esp,%ebp
f01011b0:	83 ec 18             	sub    $0x18,%esp
f01011b3:	8b 45 08             	mov    0x8(%ebp),%eax
f01011b6:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01011b9:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01011bc:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01011c0:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01011c3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01011ca:	85 c0                	test   %eax,%eax
f01011cc:	74 26                	je     f01011f4 <vsnprintf+0x47>
f01011ce:	85 d2                	test   %edx,%edx
f01011d0:	7e 29                	jle    f01011fb <vsnprintf+0x4e>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01011d2:	ff 75 14             	pushl  0x14(%ebp)
f01011d5:	ff 75 10             	pushl  0x10(%ebp)
f01011d8:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01011db:	50                   	push   %eax
f01011dc:	68 a2 0d 10 f0       	push   $0xf0100da2
f01011e1:	e8 f5 fb ff ff       	call   f0100ddb <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01011e6:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01011e9:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01011ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011ef:	83 c4 10             	add    $0x10,%esp
f01011f2:	eb 0c                	jmp    f0101200 <vsnprintf+0x53>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01011f4:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01011f9:	eb 05                	jmp    f0101200 <vsnprintf+0x53>
f01011fb:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101200:	c9                   	leave  
f0101201:	c3                   	ret    

f0101202 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101202:	55                   	push   %ebp
f0101203:	89 e5                	mov    %esp,%ebp
f0101205:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101208:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010120b:	50                   	push   %eax
f010120c:	ff 75 10             	pushl  0x10(%ebp)
f010120f:	ff 75 0c             	pushl  0xc(%ebp)
f0101212:	ff 75 08             	pushl  0x8(%ebp)
f0101215:	e8 93 ff ff ff       	call   f01011ad <vsnprintf>
	va_end(ap);

	return rc;
}
f010121a:	c9                   	leave  
f010121b:	c3                   	ret    

f010121c <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010121c:	55                   	push   %ebp
f010121d:	89 e5                	mov    %esp,%ebp
f010121f:	57                   	push   %edi
f0101220:	56                   	push   %esi
f0101221:	53                   	push   %ebx
f0101222:	83 ec 0c             	sub    $0xc,%esp
f0101225:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101228:	85 c0                	test   %eax,%eax
f010122a:	74 11                	je     f010123d <readline+0x21>
		cprintf("%s", prompt);
f010122c:	83 ec 08             	sub    $0x8,%esp
f010122f:	50                   	push   %eax
f0101230:	68 16 1f 10 f0       	push   $0xf0101f16
f0101235:	e8 3c f7 ff ff       	call   f0100976 <cprintf>
f010123a:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f010123d:	83 ec 0c             	sub    $0xc,%esp
f0101240:	6a 00                	push   $0x0
f0101242:	e8 ff f3 ff ff       	call   f0100646 <iscons>
f0101247:	89 c7                	mov    %eax,%edi
f0101249:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010124c:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101251:	e8 df f3 ff ff       	call   f0100635 <getchar>
f0101256:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0101258:	85 c0                	test   %eax,%eax
f010125a:	79 1b                	jns    f0101277 <readline+0x5b>
			cprintf("read error: %e\n", c);
f010125c:	83 ec 08             	sub    $0x8,%esp
f010125f:	50                   	push   %eax
f0101260:	68 f8 20 10 f0       	push   $0xf01020f8
f0101265:	e8 0c f7 ff ff       	call   f0100976 <cprintf>
			return NULL;
f010126a:	83 c4 10             	add    $0x10,%esp
f010126d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101272:	e9 8d 00 00 00       	jmp    f0101304 <readline+0xe8>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101277:	83 f8 08             	cmp    $0x8,%eax
f010127a:	74 72                	je     f01012ee <readline+0xd2>
f010127c:	83 f8 7f             	cmp    $0x7f,%eax
f010127f:	75 16                	jne    f0101297 <readline+0x7b>
f0101281:	eb 65                	jmp    f01012e8 <readline+0xcc>
			if (echoing)
f0101283:	85 ff                	test   %edi,%edi
f0101285:	74 0d                	je     f0101294 <readline+0x78>
				cputchar('\b');
f0101287:	83 ec 0c             	sub    $0xc,%esp
f010128a:	6a 08                	push   $0x8
f010128c:	e8 94 f3 ff ff       	call   f0100625 <cputchar>
f0101291:	83 c4 10             	add    $0x10,%esp
			i--;
f0101294:	4e                   	dec    %esi
f0101295:	eb ba                	jmp    f0101251 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101297:	83 f8 1f             	cmp    $0x1f,%eax
f010129a:	7e 23                	jle    f01012bf <readline+0xa3>
f010129c:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01012a2:	7f 1b                	jg     f01012bf <readline+0xa3>
			if (echoing)
f01012a4:	85 ff                	test   %edi,%edi
f01012a6:	74 0c                	je     f01012b4 <readline+0x98>
				cputchar(c);
f01012a8:	83 ec 0c             	sub    $0xc,%esp
f01012ab:	53                   	push   %ebx
f01012ac:	e8 74 f3 ff ff       	call   f0100625 <cputchar>
f01012b1:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01012b4:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f01012ba:	8d 76 01             	lea    0x1(%esi),%esi
f01012bd:	eb 92                	jmp    f0101251 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01012bf:	83 fb 0a             	cmp    $0xa,%ebx
f01012c2:	74 05                	je     f01012c9 <readline+0xad>
f01012c4:	83 fb 0d             	cmp    $0xd,%ebx
f01012c7:	75 88                	jne    f0101251 <readline+0x35>
			if (echoing)
f01012c9:	85 ff                	test   %edi,%edi
f01012cb:	74 0d                	je     f01012da <readline+0xbe>
				cputchar('\n');
f01012cd:	83 ec 0c             	sub    $0xc,%esp
f01012d0:	6a 0a                	push   $0xa
f01012d2:	e8 4e f3 ff ff       	call   f0100625 <cputchar>
f01012d7:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01012da:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f01012e1:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
f01012e6:	eb 1c                	jmp    f0101304 <readline+0xe8>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
			return NULL;
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01012e8:	85 f6                	test   %esi,%esi
f01012ea:	7f 97                	jg     f0101283 <readline+0x67>
f01012ec:	eb 09                	jmp    f01012f7 <readline+0xdb>
f01012ee:	85 f6                	test   %esi,%esi
f01012f0:	7f 91                	jg     f0101283 <readline+0x67>
f01012f2:	e9 5a ff ff ff       	jmp    f0101251 <readline+0x35>
			if (echoing)
				cputchar('\b');
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
f01012f7:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01012fd:	7e a5                	jle    f01012a4 <readline+0x88>
f01012ff:	e9 4d ff ff ff       	jmp    f0101251 <readline+0x35>
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0101304:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101307:	5b                   	pop    %ebx
f0101308:	5e                   	pop    %esi
f0101309:	5f                   	pop    %edi
f010130a:	5d                   	pop    %ebp
f010130b:	c3                   	ret    

f010130c <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010130c:	55                   	push   %ebp
f010130d:	89 e5                	mov    %esp,%ebp
f010130f:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101312:	b8 00 00 00 00       	mov    $0x0,%eax
f0101317:	eb 01                	jmp    f010131a <strlen+0xe>
		n++;
f0101319:	40                   	inc    %eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f010131a:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010131e:	75 f9                	jne    f0101319 <strlen+0xd>
		n++;
	return n;
}
f0101320:	5d                   	pop    %ebp
f0101321:	c3                   	ret    

f0101322 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101322:	55                   	push   %ebp
f0101323:	89 e5                	mov    %esp,%ebp
f0101325:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101328:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010132b:	ba 00 00 00 00       	mov    $0x0,%edx
f0101330:	eb 01                	jmp    f0101333 <strnlen+0x11>
		n++;
f0101332:	42                   	inc    %edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101333:	39 c2                	cmp    %eax,%edx
f0101335:	74 08                	je     f010133f <strnlen+0x1d>
f0101337:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f010133b:	75 f5                	jne    f0101332 <strnlen+0x10>
f010133d:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f010133f:	5d                   	pop    %ebp
f0101340:	c3                   	ret    

f0101341 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101341:	55                   	push   %ebp
f0101342:	89 e5                	mov    %esp,%ebp
f0101344:	53                   	push   %ebx
f0101345:	8b 45 08             	mov    0x8(%ebp),%eax
f0101348:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010134b:	89 c2                	mov    %eax,%edx
f010134d:	42                   	inc    %edx
f010134e:	41                   	inc    %ecx
f010134f:	8a 59 ff             	mov    -0x1(%ecx),%bl
f0101352:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101355:	84 db                	test   %bl,%bl
f0101357:	75 f4                	jne    f010134d <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101359:	5b                   	pop    %ebx
f010135a:	5d                   	pop    %ebp
f010135b:	c3                   	ret    

f010135c <strcat>:

char *
strcat(char *dst, const char *src)
{
f010135c:	55                   	push   %ebp
f010135d:	89 e5                	mov    %esp,%ebp
f010135f:	53                   	push   %ebx
f0101360:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101363:	53                   	push   %ebx
f0101364:	e8 a3 ff ff ff       	call   f010130c <strlen>
f0101369:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010136c:	ff 75 0c             	pushl  0xc(%ebp)
f010136f:	01 d8                	add    %ebx,%eax
f0101371:	50                   	push   %eax
f0101372:	e8 ca ff ff ff       	call   f0101341 <strcpy>
	return dst;
}
f0101377:	89 d8                	mov    %ebx,%eax
f0101379:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010137c:	c9                   	leave  
f010137d:	c3                   	ret    

f010137e <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010137e:	55                   	push   %ebp
f010137f:	89 e5                	mov    %esp,%ebp
f0101381:	56                   	push   %esi
f0101382:	53                   	push   %ebx
f0101383:	8b 75 08             	mov    0x8(%ebp),%esi
f0101386:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101389:	89 f3                	mov    %esi,%ebx
f010138b:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010138e:	89 f2                	mov    %esi,%edx
f0101390:	eb 0c                	jmp    f010139e <strncpy+0x20>
		*dst++ = *src;
f0101392:	42                   	inc    %edx
f0101393:	8a 01                	mov    (%ecx),%al
f0101395:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101398:	80 39 01             	cmpb   $0x1,(%ecx)
f010139b:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010139e:	39 da                	cmp    %ebx,%edx
f01013a0:	75 f0                	jne    f0101392 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01013a2:	89 f0                	mov    %esi,%eax
f01013a4:	5b                   	pop    %ebx
f01013a5:	5e                   	pop    %esi
f01013a6:	5d                   	pop    %ebp
f01013a7:	c3                   	ret    

f01013a8 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01013a8:	55                   	push   %ebp
f01013a9:	89 e5                	mov    %esp,%ebp
f01013ab:	56                   	push   %esi
f01013ac:	53                   	push   %ebx
f01013ad:	8b 75 08             	mov    0x8(%ebp),%esi
f01013b0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01013b3:	8b 45 10             	mov    0x10(%ebp),%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01013b6:	85 c0                	test   %eax,%eax
f01013b8:	74 1e                	je     f01013d8 <strlcpy+0x30>
f01013ba:	8d 44 06 ff          	lea    -0x1(%esi,%eax,1),%eax
f01013be:	89 f2                	mov    %esi,%edx
f01013c0:	eb 05                	jmp    f01013c7 <strlcpy+0x1f>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01013c2:	42                   	inc    %edx
f01013c3:	41                   	inc    %ecx
f01013c4:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01013c7:	39 c2                	cmp    %eax,%edx
f01013c9:	74 08                	je     f01013d3 <strlcpy+0x2b>
f01013cb:	8a 19                	mov    (%ecx),%bl
f01013cd:	84 db                	test   %bl,%bl
f01013cf:	75 f1                	jne    f01013c2 <strlcpy+0x1a>
f01013d1:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01013d3:	c6 00 00             	movb   $0x0,(%eax)
f01013d6:	eb 02                	jmp    f01013da <strlcpy+0x32>
f01013d8:	89 f0                	mov    %esi,%eax
	}
	return dst - dst_in;
f01013da:	29 f0                	sub    %esi,%eax
}
f01013dc:	5b                   	pop    %ebx
f01013dd:	5e                   	pop    %esi
f01013de:	5d                   	pop    %ebp
f01013df:	c3                   	ret    

f01013e0 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01013e0:	55                   	push   %ebp
f01013e1:	89 e5                	mov    %esp,%ebp
f01013e3:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01013e6:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01013e9:	eb 02                	jmp    f01013ed <strcmp+0xd>
		p++, q++;
f01013eb:	41                   	inc    %ecx
f01013ec:	42                   	inc    %edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01013ed:	8a 01                	mov    (%ecx),%al
f01013ef:	84 c0                	test   %al,%al
f01013f1:	74 04                	je     f01013f7 <strcmp+0x17>
f01013f3:	3a 02                	cmp    (%edx),%al
f01013f5:	74 f4                	je     f01013eb <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01013f7:	0f b6 c0             	movzbl %al,%eax
f01013fa:	0f b6 12             	movzbl (%edx),%edx
f01013fd:	29 d0                	sub    %edx,%eax
}
f01013ff:	5d                   	pop    %ebp
f0101400:	c3                   	ret    

f0101401 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101401:	55                   	push   %ebp
f0101402:	89 e5                	mov    %esp,%ebp
f0101404:	53                   	push   %ebx
f0101405:	8b 45 08             	mov    0x8(%ebp),%eax
f0101408:	8b 55 0c             	mov    0xc(%ebp),%edx
f010140b:	89 c3                	mov    %eax,%ebx
f010140d:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101410:	eb 02                	jmp    f0101414 <strncmp+0x13>
		n--, p++, q++;
f0101412:	40                   	inc    %eax
f0101413:	42                   	inc    %edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101414:	39 d8                	cmp    %ebx,%eax
f0101416:	74 14                	je     f010142c <strncmp+0x2b>
f0101418:	8a 08                	mov    (%eax),%cl
f010141a:	84 c9                	test   %cl,%cl
f010141c:	74 04                	je     f0101422 <strncmp+0x21>
f010141e:	3a 0a                	cmp    (%edx),%cl
f0101420:	74 f0                	je     f0101412 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101422:	0f b6 00             	movzbl (%eax),%eax
f0101425:	0f b6 12             	movzbl (%edx),%edx
f0101428:	29 d0                	sub    %edx,%eax
f010142a:	eb 05                	jmp    f0101431 <strncmp+0x30>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010142c:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101431:	5b                   	pop    %ebx
f0101432:	5d                   	pop    %ebp
f0101433:	c3                   	ret    

f0101434 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101434:	55                   	push   %ebp
f0101435:	89 e5                	mov    %esp,%ebp
f0101437:	8b 45 08             	mov    0x8(%ebp),%eax
f010143a:	8a 4d 0c             	mov    0xc(%ebp),%cl
	for (; *s; s++)
f010143d:	eb 05                	jmp    f0101444 <strchr+0x10>
		if (*s == c)
f010143f:	38 ca                	cmp    %cl,%dl
f0101441:	74 0c                	je     f010144f <strchr+0x1b>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101443:	40                   	inc    %eax
f0101444:	8a 10                	mov    (%eax),%dl
f0101446:	84 d2                	test   %dl,%dl
f0101448:	75 f5                	jne    f010143f <strchr+0xb>
		if (*s == c)
			return (char *) s;
	return 0;
f010144a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010144f:	5d                   	pop    %ebp
f0101450:	c3                   	ret    

f0101451 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101451:	55                   	push   %ebp
f0101452:	89 e5                	mov    %esp,%ebp
f0101454:	8b 45 08             	mov    0x8(%ebp),%eax
f0101457:	8a 4d 0c             	mov    0xc(%ebp),%cl
	for (; *s; s++)
f010145a:	eb 05                	jmp    f0101461 <strfind+0x10>
		if (*s == c)
f010145c:	38 ca                	cmp    %cl,%dl
f010145e:	74 07                	je     f0101467 <strfind+0x16>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0101460:	40                   	inc    %eax
f0101461:	8a 10                	mov    (%eax),%dl
f0101463:	84 d2                	test   %dl,%dl
f0101465:	75 f5                	jne    f010145c <strfind+0xb>
		if (*s == c)
			break;
	return (char *) s;
}
f0101467:	5d                   	pop    %ebp
f0101468:	c3                   	ret    

f0101469 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101469:	55                   	push   %ebp
f010146a:	89 e5                	mov    %esp,%ebp
f010146c:	57                   	push   %edi
f010146d:	56                   	push   %esi
f010146e:	53                   	push   %ebx
f010146f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101472:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101475:	85 c9                	test   %ecx,%ecx
f0101477:	74 36                	je     f01014af <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101479:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010147f:	75 28                	jne    f01014a9 <memset+0x40>
f0101481:	f6 c1 03             	test   $0x3,%cl
f0101484:	75 23                	jne    f01014a9 <memset+0x40>
		c &= 0xFF;
f0101486:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010148a:	89 d3                	mov    %edx,%ebx
f010148c:	c1 e3 08             	shl    $0x8,%ebx
f010148f:	89 d6                	mov    %edx,%esi
f0101491:	c1 e6 18             	shl    $0x18,%esi
f0101494:	89 d0                	mov    %edx,%eax
f0101496:	c1 e0 10             	shl    $0x10,%eax
f0101499:	09 f0                	or     %esi,%eax
f010149b:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f010149d:	89 d8                	mov    %ebx,%eax
f010149f:	09 d0                	or     %edx,%eax
f01014a1:	c1 e9 02             	shr    $0x2,%ecx
f01014a4:	fc                   	cld    
f01014a5:	f3 ab                	rep stos %eax,%es:(%edi)
f01014a7:	eb 06                	jmp    f01014af <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01014a9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014ac:	fc                   	cld    
f01014ad:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01014af:	89 f8                	mov    %edi,%eax
f01014b1:	5b                   	pop    %ebx
f01014b2:	5e                   	pop    %esi
f01014b3:	5f                   	pop    %edi
f01014b4:	5d                   	pop    %ebp
f01014b5:	c3                   	ret    

f01014b6 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01014b6:	55                   	push   %ebp
f01014b7:	89 e5                	mov    %esp,%ebp
f01014b9:	57                   	push   %edi
f01014ba:	56                   	push   %esi
f01014bb:	8b 45 08             	mov    0x8(%ebp),%eax
f01014be:	8b 75 0c             	mov    0xc(%ebp),%esi
f01014c1:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01014c4:	39 c6                	cmp    %eax,%esi
f01014c6:	73 33                	jae    f01014fb <memmove+0x45>
f01014c8:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01014cb:	39 d0                	cmp    %edx,%eax
f01014cd:	73 2c                	jae    f01014fb <memmove+0x45>
		s += n;
		d += n;
f01014cf:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014d2:	89 d6                	mov    %edx,%esi
f01014d4:	09 fe                	or     %edi,%esi
f01014d6:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01014dc:	75 13                	jne    f01014f1 <memmove+0x3b>
f01014de:	f6 c1 03             	test   $0x3,%cl
f01014e1:	75 0e                	jne    f01014f1 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01014e3:	83 ef 04             	sub    $0x4,%edi
f01014e6:	8d 72 fc             	lea    -0x4(%edx),%esi
f01014e9:	c1 e9 02             	shr    $0x2,%ecx
f01014ec:	fd                   	std    
f01014ed:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01014ef:	eb 07                	jmp    f01014f8 <memmove+0x42>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01014f1:	4f                   	dec    %edi
f01014f2:	8d 72 ff             	lea    -0x1(%edx),%esi
f01014f5:	fd                   	std    
f01014f6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01014f8:	fc                   	cld    
f01014f9:	eb 1d                	jmp    f0101518 <memmove+0x62>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014fb:	89 f2                	mov    %esi,%edx
f01014fd:	09 c2                	or     %eax,%edx
f01014ff:	f6 c2 03             	test   $0x3,%dl
f0101502:	75 0f                	jne    f0101513 <memmove+0x5d>
f0101504:	f6 c1 03             	test   $0x3,%cl
f0101507:	75 0a                	jne    f0101513 <memmove+0x5d>
			asm volatile("cld; rep movsl\n"
f0101509:	c1 e9 02             	shr    $0x2,%ecx
f010150c:	89 c7                	mov    %eax,%edi
f010150e:	fc                   	cld    
f010150f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101511:	eb 05                	jmp    f0101518 <memmove+0x62>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101513:	89 c7                	mov    %eax,%edi
f0101515:	fc                   	cld    
f0101516:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101518:	5e                   	pop    %esi
f0101519:	5f                   	pop    %edi
f010151a:	5d                   	pop    %ebp
f010151b:	c3                   	ret    

f010151c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010151c:	55                   	push   %ebp
f010151d:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010151f:	ff 75 10             	pushl  0x10(%ebp)
f0101522:	ff 75 0c             	pushl  0xc(%ebp)
f0101525:	ff 75 08             	pushl  0x8(%ebp)
f0101528:	e8 89 ff ff ff       	call   f01014b6 <memmove>
}
f010152d:	c9                   	leave  
f010152e:	c3                   	ret    

f010152f <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010152f:	55                   	push   %ebp
f0101530:	89 e5                	mov    %esp,%ebp
f0101532:	56                   	push   %esi
f0101533:	53                   	push   %ebx
f0101534:	8b 45 08             	mov    0x8(%ebp),%eax
f0101537:	8b 55 0c             	mov    0xc(%ebp),%edx
f010153a:	89 c6                	mov    %eax,%esi
f010153c:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010153f:	eb 14                	jmp    f0101555 <memcmp+0x26>
		if (*s1 != *s2)
f0101541:	8a 08                	mov    (%eax),%cl
f0101543:	8a 1a                	mov    (%edx),%bl
f0101545:	38 d9                	cmp    %bl,%cl
f0101547:	74 0a                	je     f0101553 <memcmp+0x24>
			return (int) *s1 - (int) *s2;
f0101549:	0f b6 c1             	movzbl %cl,%eax
f010154c:	0f b6 db             	movzbl %bl,%ebx
f010154f:	29 d8                	sub    %ebx,%eax
f0101551:	eb 0b                	jmp    f010155e <memcmp+0x2f>
		s1++, s2++;
f0101553:	40                   	inc    %eax
f0101554:	42                   	inc    %edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101555:	39 f0                	cmp    %esi,%eax
f0101557:	75 e8                	jne    f0101541 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101559:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010155e:	5b                   	pop    %ebx
f010155f:	5e                   	pop    %esi
f0101560:	5d                   	pop    %ebp
f0101561:	c3                   	ret    

f0101562 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101562:	55                   	push   %ebp
f0101563:	89 e5                	mov    %esp,%ebp
f0101565:	53                   	push   %ebx
f0101566:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0101569:	89 c1                	mov    %eax,%ecx
f010156b:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f010156e:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101572:	eb 08                	jmp    f010157c <memfind+0x1a>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101574:	0f b6 10             	movzbl (%eax),%edx
f0101577:	39 da                	cmp    %ebx,%edx
f0101579:	74 05                	je     f0101580 <memfind+0x1e>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010157b:	40                   	inc    %eax
f010157c:	39 c8                	cmp    %ecx,%eax
f010157e:	72 f4                	jb     f0101574 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101580:	5b                   	pop    %ebx
f0101581:	5d                   	pop    %ebp
f0101582:	c3                   	ret    

f0101583 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101583:	55                   	push   %ebp
f0101584:	89 e5                	mov    %esp,%ebp
f0101586:	57                   	push   %edi
f0101587:	56                   	push   %esi
f0101588:	53                   	push   %ebx
f0101589:	8b 4d 08             	mov    0x8(%ebp),%ecx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010158c:	eb 01                	jmp    f010158f <strtol+0xc>
		s++;
f010158e:	41                   	inc    %ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010158f:	8a 01                	mov    (%ecx),%al
f0101591:	3c 20                	cmp    $0x20,%al
f0101593:	74 f9                	je     f010158e <strtol+0xb>
f0101595:	3c 09                	cmp    $0x9,%al
f0101597:	74 f5                	je     f010158e <strtol+0xb>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101599:	3c 2b                	cmp    $0x2b,%al
f010159b:	75 08                	jne    f01015a5 <strtol+0x22>
		s++;
f010159d:	41                   	inc    %ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010159e:	bf 00 00 00 00       	mov    $0x0,%edi
f01015a3:	eb 11                	jmp    f01015b6 <strtol+0x33>
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01015a5:	3c 2d                	cmp    $0x2d,%al
f01015a7:	75 08                	jne    f01015b1 <strtol+0x2e>
		s++, neg = 1;
f01015a9:	41                   	inc    %ecx
f01015aa:	bf 01 00 00 00       	mov    $0x1,%edi
f01015af:	eb 05                	jmp    f01015b6 <strtol+0x33>
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01015b1:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01015b6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01015ba:	0f 84 87 00 00 00    	je     f0101647 <strtol+0xc4>
f01015c0:	83 7d 10 10          	cmpl   $0x10,0x10(%ebp)
f01015c4:	75 27                	jne    f01015ed <strtol+0x6a>
f01015c6:	80 39 30             	cmpb   $0x30,(%ecx)
f01015c9:	75 22                	jne    f01015ed <strtol+0x6a>
f01015cb:	e9 88 00 00 00       	jmp    f0101658 <strtol+0xd5>
		s += 2, base = 16;
f01015d0:	83 c1 02             	add    $0x2,%ecx
f01015d3:	c7 45 10 10 00 00 00 	movl   $0x10,0x10(%ebp)
f01015da:	eb 11                	jmp    f01015ed <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
		s++, base = 8;
f01015dc:	41                   	inc    %ecx
f01015dd:	c7 45 10 08 00 00 00 	movl   $0x8,0x10(%ebp)
f01015e4:	eb 07                	jmp    f01015ed <strtol+0x6a>
	else if (base == 0)
		base = 10;
f01015e6:	c7 45 10 0a 00 00 00 	movl   $0xa,0x10(%ebp)
f01015ed:	b8 00 00 00 00       	mov    $0x0,%eax

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01015f2:	8a 11                	mov    (%ecx),%dl
f01015f4:	8d 5a d0             	lea    -0x30(%edx),%ebx
f01015f7:	80 fb 09             	cmp    $0x9,%bl
f01015fa:	77 08                	ja     f0101604 <strtol+0x81>
			dig = *s - '0';
f01015fc:	0f be d2             	movsbl %dl,%edx
f01015ff:	83 ea 30             	sub    $0x30,%edx
f0101602:	eb 22                	jmp    f0101626 <strtol+0xa3>
		else if (*s >= 'a' && *s <= 'z')
f0101604:	8d 72 9f             	lea    -0x61(%edx),%esi
f0101607:	89 f3                	mov    %esi,%ebx
f0101609:	80 fb 19             	cmp    $0x19,%bl
f010160c:	77 08                	ja     f0101616 <strtol+0x93>
			dig = *s - 'a' + 10;
f010160e:	0f be d2             	movsbl %dl,%edx
f0101611:	83 ea 57             	sub    $0x57,%edx
f0101614:	eb 10                	jmp    f0101626 <strtol+0xa3>
		else if (*s >= 'A' && *s <= 'Z')
f0101616:	8d 72 bf             	lea    -0x41(%edx),%esi
f0101619:	89 f3                	mov    %esi,%ebx
f010161b:	80 fb 19             	cmp    $0x19,%bl
f010161e:	77 14                	ja     f0101634 <strtol+0xb1>
			dig = *s - 'A' + 10;
f0101620:	0f be d2             	movsbl %dl,%edx
f0101623:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0101626:	3b 55 10             	cmp    0x10(%ebp),%edx
f0101629:	7d 09                	jge    f0101634 <strtol+0xb1>
			break;
		s++, val = (val * base) + dig;
f010162b:	41                   	inc    %ecx
f010162c:	0f af 45 10          	imul   0x10(%ebp),%eax
f0101630:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0101632:	eb be                	jmp    f01015f2 <strtol+0x6f>

	if (endptr)
f0101634:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101638:	74 05                	je     f010163f <strtol+0xbc>
		*endptr = (char *) s;
f010163a:	8b 75 0c             	mov    0xc(%ebp),%esi
f010163d:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f010163f:	85 ff                	test   %edi,%edi
f0101641:	74 21                	je     f0101664 <strtol+0xe1>
f0101643:	f7 d8                	neg    %eax
f0101645:	eb 1d                	jmp    f0101664 <strtol+0xe1>
		s++;
	else if (*s == '-')
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101647:	80 39 30             	cmpb   $0x30,(%ecx)
f010164a:	75 9a                	jne    f01015e6 <strtol+0x63>
f010164c:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0101650:	0f 84 7a ff ff ff    	je     f01015d0 <strtol+0x4d>
f0101656:	eb 84                	jmp    f01015dc <strtol+0x59>
f0101658:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010165c:	0f 84 6e ff ff ff    	je     f01015d0 <strtol+0x4d>
f0101662:	eb 89                	jmp    f01015ed <strtol+0x6a>
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
}
f0101664:	5b                   	pop    %ebx
f0101665:	5e                   	pop    %esi
f0101666:	5f                   	pop    %edi
f0101667:	5d                   	pop    %ebp
f0101668:	c3                   	ret    
f0101669:	66 90                	xchg   %ax,%ax
f010166b:	90                   	nop

f010166c <__udivdi3>:
f010166c:	55                   	push   %ebp
f010166d:	57                   	push   %edi
f010166e:	56                   	push   %esi
f010166f:	53                   	push   %ebx
f0101670:	83 ec 1c             	sub    $0x1c,%esp
f0101673:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f0101677:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f010167b:	8b 7c 24 38          	mov    0x38(%esp),%edi
f010167f:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101683:	89 ca                	mov    %ecx,%edx
f0101685:	89 f8                	mov    %edi,%eax
f0101687:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010168b:	85 f6                	test   %esi,%esi
f010168d:	75 2d                	jne    f01016bc <__udivdi3+0x50>
f010168f:	39 cf                	cmp    %ecx,%edi
f0101691:	77 65                	ja     f01016f8 <__udivdi3+0x8c>
f0101693:	89 fd                	mov    %edi,%ebp
f0101695:	85 ff                	test   %edi,%edi
f0101697:	75 0b                	jne    f01016a4 <__udivdi3+0x38>
f0101699:	b8 01 00 00 00       	mov    $0x1,%eax
f010169e:	31 d2                	xor    %edx,%edx
f01016a0:	f7 f7                	div    %edi
f01016a2:	89 c5                	mov    %eax,%ebp
f01016a4:	31 d2                	xor    %edx,%edx
f01016a6:	89 c8                	mov    %ecx,%eax
f01016a8:	f7 f5                	div    %ebp
f01016aa:	89 c1                	mov    %eax,%ecx
f01016ac:	89 d8                	mov    %ebx,%eax
f01016ae:	f7 f5                	div    %ebp
f01016b0:	89 cf                	mov    %ecx,%edi
f01016b2:	89 fa                	mov    %edi,%edx
f01016b4:	83 c4 1c             	add    $0x1c,%esp
f01016b7:	5b                   	pop    %ebx
f01016b8:	5e                   	pop    %esi
f01016b9:	5f                   	pop    %edi
f01016ba:	5d                   	pop    %ebp
f01016bb:	c3                   	ret    
f01016bc:	39 ce                	cmp    %ecx,%esi
f01016be:	77 28                	ja     f01016e8 <__udivdi3+0x7c>
f01016c0:	0f bd fe             	bsr    %esi,%edi
f01016c3:	83 f7 1f             	xor    $0x1f,%edi
f01016c6:	75 40                	jne    f0101708 <__udivdi3+0x9c>
f01016c8:	39 ce                	cmp    %ecx,%esi
f01016ca:	72 0a                	jb     f01016d6 <__udivdi3+0x6a>
f01016cc:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01016d0:	0f 87 9e 00 00 00    	ja     f0101774 <__udivdi3+0x108>
f01016d6:	b8 01 00 00 00       	mov    $0x1,%eax
f01016db:	89 fa                	mov    %edi,%edx
f01016dd:	83 c4 1c             	add    $0x1c,%esp
f01016e0:	5b                   	pop    %ebx
f01016e1:	5e                   	pop    %esi
f01016e2:	5f                   	pop    %edi
f01016e3:	5d                   	pop    %ebp
f01016e4:	c3                   	ret    
f01016e5:	8d 76 00             	lea    0x0(%esi),%esi
f01016e8:	31 ff                	xor    %edi,%edi
f01016ea:	31 c0                	xor    %eax,%eax
f01016ec:	89 fa                	mov    %edi,%edx
f01016ee:	83 c4 1c             	add    $0x1c,%esp
f01016f1:	5b                   	pop    %ebx
f01016f2:	5e                   	pop    %esi
f01016f3:	5f                   	pop    %edi
f01016f4:	5d                   	pop    %ebp
f01016f5:	c3                   	ret    
f01016f6:	66 90                	xchg   %ax,%ax
f01016f8:	89 d8                	mov    %ebx,%eax
f01016fa:	f7 f7                	div    %edi
f01016fc:	31 ff                	xor    %edi,%edi
f01016fe:	89 fa                	mov    %edi,%edx
f0101700:	83 c4 1c             	add    $0x1c,%esp
f0101703:	5b                   	pop    %ebx
f0101704:	5e                   	pop    %esi
f0101705:	5f                   	pop    %edi
f0101706:	5d                   	pop    %ebp
f0101707:	c3                   	ret    
f0101708:	bd 20 00 00 00       	mov    $0x20,%ebp
f010170d:	89 eb                	mov    %ebp,%ebx
f010170f:	29 fb                	sub    %edi,%ebx
f0101711:	89 f9                	mov    %edi,%ecx
f0101713:	d3 e6                	shl    %cl,%esi
f0101715:	89 c5                	mov    %eax,%ebp
f0101717:	88 d9                	mov    %bl,%cl
f0101719:	d3 ed                	shr    %cl,%ebp
f010171b:	89 e9                	mov    %ebp,%ecx
f010171d:	09 f1                	or     %esi,%ecx
f010171f:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0101723:	89 f9                	mov    %edi,%ecx
f0101725:	d3 e0                	shl    %cl,%eax
f0101727:	89 c5                	mov    %eax,%ebp
f0101729:	89 d6                	mov    %edx,%esi
f010172b:	88 d9                	mov    %bl,%cl
f010172d:	d3 ee                	shr    %cl,%esi
f010172f:	89 f9                	mov    %edi,%ecx
f0101731:	d3 e2                	shl    %cl,%edx
f0101733:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101737:	88 d9                	mov    %bl,%cl
f0101739:	d3 e8                	shr    %cl,%eax
f010173b:	09 c2                	or     %eax,%edx
f010173d:	89 d0                	mov    %edx,%eax
f010173f:	89 f2                	mov    %esi,%edx
f0101741:	f7 74 24 0c          	divl   0xc(%esp)
f0101745:	89 d6                	mov    %edx,%esi
f0101747:	89 c3                	mov    %eax,%ebx
f0101749:	f7 e5                	mul    %ebp
f010174b:	39 d6                	cmp    %edx,%esi
f010174d:	72 19                	jb     f0101768 <__udivdi3+0xfc>
f010174f:	74 0b                	je     f010175c <__udivdi3+0xf0>
f0101751:	89 d8                	mov    %ebx,%eax
f0101753:	31 ff                	xor    %edi,%edi
f0101755:	e9 58 ff ff ff       	jmp    f01016b2 <__udivdi3+0x46>
f010175a:	66 90                	xchg   %ax,%ax
f010175c:	8b 54 24 08          	mov    0x8(%esp),%edx
f0101760:	89 f9                	mov    %edi,%ecx
f0101762:	d3 e2                	shl    %cl,%edx
f0101764:	39 c2                	cmp    %eax,%edx
f0101766:	73 e9                	jae    f0101751 <__udivdi3+0xe5>
f0101768:	8d 43 ff             	lea    -0x1(%ebx),%eax
f010176b:	31 ff                	xor    %edi,%edi
f010176d:	e9 40 ff ff ff       	jmp    f01016b2 <__udivdi3+0x46>
f0101772:	66 90                	xchg   %ax,%ax
f0101774:	31 c0                	xor    %eax,%eax
f0101776:	e9 37 ff ff ff       	jmp    f01016b2 <__udivdi3+0x46>
f010177b:	90                   	nop

f010177c <__umoddi3>:
f010177c:	55                   	push   %ebp
f010177d:	57                   	push   %edi
f010177e:	56                   	push   %esi
f010177f:	53                   	push   %ebx
f0101780:	83 ec 1c             	sub    $0x1c,%esp
f0101783:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0101787:	8b 74 24 34          	mov    0x34(%esp),%esi
f010178b:	8b 7c 24 38          	mov    0x38(%esp),%edi
f010178f:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f0101793:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101797:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010179b:	89 f3                	mov    %esi,%ebx
f010179d:	89 fa                	mov    %edi,%edx
f010179f:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01017a3:	89 34 24             	mov    %esi,(%esp)
f01017a6:	85 c0                	test   %eax,%eax
f01017a8:	75 1a                	jne    f01017c4 <__umoddi3+0x48>
f01017aa:	39 f7                	cmp    %esi,%edi
f01017ac:	0f 86 a2 00 00 00    	jbe    f0101854 <__umoddi3+0xd8>
f01017b2:	89 c8                	mov    %ecx,%eax
f01017b4:	89 f2                	mov    %esi,%edx
f01017b6:	f7 f7                	div    %edi
f01017b8:	89 d0                	mov    %edx,%eax
f01017ba:	31 d2                	xor    %edx,%edx
f01017bc:	83 c4 1c             	add    $0x1c,%esp
f01017bf:	5b                   	pop    %ebx
f01017c0:	5e                   	pop    %esi
f01017c1:	5f                   	pop    %edi
f01017c2:	5d                   	pop    %ebp
f01017c3:	c3                   	ret    
f01017c4:	39 f0                	cmp    %esi,%eax
f01017c6:	0f 87 ac 00 00 00    	ja     f0101878 <__umoddi3+0xfc>
f01017cc:	0f bd e8             	bsr    %eax,%ebp
f01017cf:	83 f5 1f             	xor    $0x1f,%ebp
f01017d2:	0f 84 ac 00 00 00    	je     f0101884 <__umoddi3+0x108>
f01017d8:	bf 20 00 00 00       	mov    $0x20,%edi
f01017dd:	29 ef                	sub    %ebp,%edi
f01017df:	89 fe                	mov    %edi,%esi
f01017e1:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01017e5:	89 e9                	mov    %ebp,%ecx
f01017e7:	d3 e0                	shl    %cl,%eax
f01017e9:	89 d7                	mov    %edx,%edi
f01017eb:	89 f1                	mov    %esi,%ecx
f01017ed:	d3 ef                	shr    %cl,%edi
f01017ef:	09 c7                	or     %eax,%edi
f01017f1:	89 e9                	mov    %ebp,%ecx
f01017f3:	d3 e2                	shl    %cl,%edx
f01017f5:	89 14 24             	mov    %edx,(%esp)
f01017f8:	89 d8                	mov    %ebx,%eax
f01017fa:	d3 e0                	shl    %cl,%eax
f01017fc:	89 c2                	mov    %eax,%edx
f01017fe:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101802:	d3 e0                	shl    %cl,%eax
f0101804:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101808:	8b 44 24 08          	mov    0x8(%esp),%eax
f010180c:	89 f1                	mov    %esi,%ecx
f010180e:	d3 e8                	shr    %cl,%eax
f0101810:	09 d0                	or     %edx,%eax
f0101812:	d3 eb                	shr    %cl,%ebx
f0101814:	89 da                	mov    %ebx,%edx
f0101816:	f7 f7                	div    %edi
f0101818:	89 d3                	mov    %edx,%ebx
f010181a:	f7 24 24             	mull   (%esp)
f010181d:	89 c6                	mov    %eax,%esi
f010181f:	89 d1                	mov    %edx,%ecx
f0101821:	39 d3                	cmp    %edx,%ebx
f0101823:	0f 82 87 00 00 00    	jb     f01018b0 <__umoddi3+0x134>
f0101829:	0f 84 91 00 00 00    	je     f01018c0 <__umoddi3+0x144>
f010182f:	8b 54 24 04          	mov    0x4(%esp),%edx
f0101833:	29 f2                	sub    %esi,%edx
f0101835:	19 cb                	sbb    %ecx,%ebx
f0101837:	89 d8                	mov    %ebx,%eax
f0101839:	8a 4c 24 0c          	mov    0xc(%esp),%cl
f010183d:	d3 e0                	shl    %cl,%eax
f010183f:	89 e9                	mov    %ebp,%ecx
f0101841:	d3 ea                	shr    %cl,%edx
f0101843:	09 d0                	or     %edx,%eax
f0101845:	89 e9                	mov    %ebp,%ecx
f0101847:	d3 eb                	shr    %cl,%ebx
f0101849:	89 da                	mov    %ebx,%edx
f010184b:	83 c4 1c             	add    $0x1c,%esp
f010184e:	5b                   	pop    %ebx
f010184f:	5e                   	pop    %esi
f0101850:	5f                   	pop    %edi
f0101851:	5d                   	pop    %ebp
f0101852:	c3                   	ret    
f0101853:	90                   	nop
f0101854:	89 fd                	mov    %edi,%ebp
f0101856:	85 ff                	test   %edi,%edi
f0101858:	75 0b                	jne    f0101865 <__umoddi3+0xe9>
f010185a:	b8 01 00 00 00       	mov    $0x1,%eax
f010185f:	31 d2                	xor    %edx,%edx
f0101861:	f7 f7                	div    %edi
f0101863:	89 c5                	mov    %eax,%ebp
f0101865:	89 f0                	mov    %esi,%eax
f0101867:	31 d2                	xor    %edx,%edx
f0101869:	f7 f5                	div    %ebp
f010186b:	89 c8                	mov    %ecx,%eax
f010186d:	f7 f5                	div    %ebp
f010186f:	89 d0                	mov    %edx,%eax
f0101871:	e9 44 ff ff ff       	jmp    f01017ba <__umoddi3+0x3e>
f0101876:	66 90                	xchg   %ax,%ax
f0101878:	89 c8                	mov    %ecx,%eax
f010187a:	89 f2                	mov    %esi,%edx
f010187c:	83 c4 1c             	add    $0x1c,%esp
f010187f:	5b                   	pop    %ebx
f0101880:	5e                   	pop    %esi
f0101881:	5f                   	pop    %edi
f0101882:	5d                   	pop    %ebp
f0101883:	c3                   	ret    
f0101884:	3b 04 24             	cmp    (%esp),%eax
f0101887:	72 06                	jb     f010188f <__umoddi3+0x113>
f0101889:	3b 7c 24 04          	cmp    0x4(%esp),%edi
f010188d:	77 0f                	ja     f010189e <__umoddi3+0x122>
f010188f:	89 f2                	mov    %esi,%edx
f0101891:	29 f9                	sub    %edi,%ecx
f0101893:	1b 54 24 0c          	sbb    0xc(%esp),%edx
f0101897:	89 14 24             	mov    %edx,(%esp)
f010189a:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010189e:	8b 44 24 04          	mov    0x4(%esp),%eax
f01018a2:	8b 14 24             	mov    (%esp),%edx
f01018a5:	83 c4 1c             	add    $0x1c,%esp
f01018a8:	5b                   	pop    %ebx
f01018a9:	5e                   	pop    %esi
f01018aa:	5f                   	pop    %edi
f01018ab:	5d                   	pop    %ebp
f01018ac:	c3                   	ret    
f01018ad:	8d 76 00             	lea    0x0(%esi),%esi
f01018b0:	2b 04 24             	sub    (%esp),%eax
f01018b3:	19 fa                	sbb    %edi,%edx
f01018b5:	89 d1                	mov    %edx,%ecx
f01018b7:	89 c6                	mov    %eax,%esi
f01018b9:	e9 71 ff ff ff       	jmp    f010182f <__umoddi3+0xb3>
f01018be:	66 90                	xchg   %ax,%ax
f01018c0:	39 44 24 04          	cmp    %eax,0x4(%esp)
f01018c4:	72 ea                	jb     f01018b0 <__umoddi3+0x134>
f01018c6:	89 d9                	mov    %ebx,%ecx
f01018c8:	e9 62 ff ff ff       	jmp    f010182f <__umoddi3+0xb3>
