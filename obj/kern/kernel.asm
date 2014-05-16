
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

00100000 <_start-0xc>:
.long MULTIBOOT_HEADER_FLAGS
.long CHECKSUM

.globl		start,_start
start: _start:
	movw	$0x1234,0x472			# warm boot BIOS flag
  100000:	02 b0 ad 1b 03 00    	add    0x31bad(%eax),%dh
  100006:	00 00                	add    %al,(%eax)
  100008:	fb                   	sti    
  100009:	4f                   	dec    %edi
  10000a:	52                   	push   %edx
  10000b:	e4 66                	in     $0x66,%al

0010000c <_start>:
  10000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
  100013:	34 12 

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
  100015:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(cpu_boot+4096),%esp
  10001a:	bc 00 80 10 00       	mov    $0x108000,%esp

	# now to C code
	call	init
  10001f:	e8 76 00 00 00       	call   10009a <init>

00100024 <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
  100024:	eb fe                	jmp    100024 <spin>
  100026:	90                   	nop
  100027:	90                   	nop

00100028 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  100028:	55                   	push   %ebp
  100029:	89 e5                	mov    %esp,%ebp
  10002b:	53                   	push   %ebx
  10002c:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10002f:	89 e3                	mov    %esp,%ebx
  100031:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  100034:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  100037:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10003a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10003d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100042:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  100045:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100048:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  10004e:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  100053:	74 24                	je     100079 <cpu_cur+0x51>
  100055:	c7 44 24 0c 80 2f 10 	movl   $0x102f80,0xc(%esp)
  10005c:	00 
  10005d:	c7 44 24 08 96 2f 10 	movl   $0x102f96,0x8(%esp)
  100064:	00 
  100065:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  10006c:	00 
  10006d:	c7 04 24 ab 2f 10 00 	movl   $0x102fab,(%esp)
  100074:	e8 cb 02 00 00       	call   100344 <debug_panic>
	return c;
  100079:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  10007c:	83 c4 24             	add    $0x24,%esp
  10007f:	5b                   	pop    %ebx
  100080:	5d                   	pop    %ebp
  100081:	c3                   	ret    

00100082 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  100082:	55                   	push   %ebp
  100083:	89 e5                	mov    %esp,%ebp
  100085:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  100088:	e8 9b ff ff ff       	call   100028 <cpu_cur>
  10008d:	3d 00 70 10 00       	cmp    $0x107000,%eax
  100092:	0f 94 c0             	sete   %al
  100095:	0f b6 c0             	movzbl %al,%eax
}
  100098:	c9                   	leave  
  100099:	c3                   	ret    

0010009a <init>:
// Called first from entry.S on the bootstrap processor,
// and later from boot/bootother.S on all other processors.
// As a rule, "init" functions in PIOS are called once on EACH processor.
void
init(void)
{
  10009a:	55                   	push   %ebp
  10009b:	89 e5                	mov    %esp,%ebp
  10009d:	83 ec 18             	sub    $0x18,%esp
	extern char start[], edata[], end[];

	// Before anything else, complete the ELF loading process.
	// Clear all uninitialized global data (BSS) in our program,
	// ensuring that all static/global variables start out zero.
	if (cpu_onboot())
  1000a0:	e8 dd ff ff ff       	call   100082 <cpu_onboot>
  1000a5:	85 c0                	test   %eax,%eax
  1000a7:	74 28                	je     1000d1 <init+0x37>
		memset(edata, 0, end - edata);
  1000a9:	ba c4 9f 10 00       	mov    $0x109fc4,%edx
  1000ae:	b8 70 85 10 00       	mov    $0x108570,%eax
  1000b3:	89 d1                	mov    %edx,%ecx
  1000b5:	29 c1                	sub    %eax,%ecx
  1000b7:	89 c8                	mov    %ecx,%eax
  1000b9:	89 44 24 08          	mov    %eax,0x8(%esp)
  1000bd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1000c4:	00 
  1000c5:	c7 04 24 70 85 10 00 	movl   $0x108570,(%esp)
  1000cc:	e8 bc 29 00 00       	call   102a8d <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
  1000d1:	e8 fa 01 00 00       	call   1002d0 <cons_init>

	// Lab 1: test cprintf and debug_trace
	//int x = 1, y = 3, z = 4;
        cprintf("1234 decimal is %o octal!\n", 1234);
  1000d6:	c7 44 24 04 d2 04 00 	movl   $0x4d2,0x4(%esp)
  1000dd:	00 
  1000de:	c7 04 24 b8 2f 10 00 	movl   $0x102fb8,(%esp)
  1000e5:	e8 be 27 00 00       	call   1028a8 <cprintf>
        //cprintf("x %d, y %x, z %d\n", x, y, z);
//      unsigned int i = 0x00646c72;
//      cprintf("H%x Wo%s", 57616, &i);
//        cprintf("x=%d y=%d", 3);

	debug_check();
  1000ea:	e8 ee 04 00 00       	call   1005dd <debug_check>

	// Initialize and load the bootstrap CPU's GDT, TSS, and IDT.
	cpu_init();
  1000ef:	e8 5e 0e 00 00       	call   100f52 <cpu_init>
	trap_init();
  1000f4:	e8 df 11 00 00       	call   1012d8 <trap_init>
		ss : CPU_GDT_UDATA|3,
		eflags : FL_IOPL_3, //make the processor believe the tf be created in usermode
		eip : (uint32_t)user,
		esp : (uint32_t)&user_stack[PAGESIZE],
	};
	trap_return(&ttf);
  1000f9:	c7 04 24 00 60 10 00 	movl   $0x106000,(%esp)
  100100:	e8 9b 18 00 00       	call   1019a0 <trap_return>

00100105 <user>:
// This is the first function that gets run in user mode (ring 3).
// It acts as PIOS's "root process",
// of which all other processes are descendants.
void
user()
{
  100105:	55                   	push   %ebp
  100106:	89 e5                	mov    %esp,%ebp
  100108:	53                   	push   %ebx
  100109:	83 ec 24             	sub    $0x24,%esp
	cprintf("in user()\n");
  10010c:	c7 04 24 d3 2f 10 00 	movl   $0x102fd3,(%esp)
  100113:	e8 90 27 00 00       	call   1028a8 <cprintf>

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100118:	89 e3                	mov    %esp,%ebx
  10011a:	89 5d f4             	mov    %ebx,-0xc(%ebp)
        return esp;
  10011d:	8b 45 f4             	mov    -0xc(%ebp),%eax
	assert(read_esp() > (uint32_t) &user_stack[0]);
  100120:	89 c2                	mov    %eax,%edx
  100122:	b8 80 85 10 00       	mov    $0x108580,%eax
  100127:	39 c2                	cmp    %eax,%edx
  100129:	77 24                	ja     10014f <user+0x4a>
  10012b:	c7 44 24 0c e0 2f 10 	movl   $0x102fe0,0xc(%esp)
  100132:	00 
  100133:	c7 44 24 08 96 2f 10 	movl   $0x102f96,0x8(%esp)
  10013a:	00 
  10013b:	c7 44 24 04 62 00 00 	movl   $0x62,0x4(%esp)
  100142:	00 
  100143:	c7 04 24 07 30 10 00 	movl   $0x103007,(%esp)
  10014a:	e8 f5 01 00 00       	call   100344 <debug_panic>

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10014f:	89 e3                	mov    %esp,%ebx
  100151:	89 5d f0             	mov    %ebx,-0x10(%ebp)
        return esp;
  100154:	8b 45 f0             	mov    -0x10(%ebp),%eax
	assert(read_esp() < (uint32_t) &user_stack[sizeof(user_stack)]);
  100157:	89 c2                	mov    %eax,%edx
  100159:	b8 80 95 10 00       	mov    $0x109580,%eax
  10015e:	39 c2                	cmp    %eax,%edx
  100160:	72 24                	jb     100186 <user+0x81>
  100162:	c7 44 24 0c 14 30 10 	movl   $0x103014,0xc(%esp)
  100169:	00 
  10016a:	c7 44 24 08 96 2f 10 	movl   $0x102f96,0x8(%esp)
  100171:	00 
  100172:	c7 44 24 04 63 00 00 	movl   $0x63,0x4(%esp)
  100179:	00 
  10017a:	c7 04 24 07 30 10 00 	movl   $0x103007,(%esp)
  100181:	e8 be 01 00 00       	call   100344 <debug_panic>

	// Check that we're in user mode and can handle traps from there.
	trap_check_user();
  100186:	e8 7c 14 00 00       	call   101607 <trap_check_user>

	done();
  10018b:	e8 00 00 00 00       	call   100190 <done>

00100190 <done>:
// it just puts the processor into an infinite loop.
// We make this a function so that we can set a breakpoints on it.
// Our grade scripts use this breakpoint to know when to stop QEMU.
void gcc_noreturn
done()
{
  100190:	55                   	push   %ebp
  100191:	89 e5                	mov    %esp,%ebp
	while (1)
		;	// just spin
  100193:	eb fe                	jmp    100193 <done+0x3>
  100195:	90                   	nop
  100196:	90                   	nop
  100197:	90                   	nop

00100198 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  100198:	55                   	push   %ebp
  100199:	89 e5                	mov    %esp,%ebp
  10019b:	53                   	push   %ebx
  10019c:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10019f:	89 e3                	mov    %esp,%ebx
  1001a1:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  1001a4:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1001a7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1001aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1001ad:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1001b2:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  1001b5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1001b8:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  1001be:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1001c3:	74 24                	je     1001e9 <cpu_cur+0x51>
  1001c5:	c7 44 24 0c 4c 30 10 	movl   $0x10304c,0xc(%esp)
  1001cc:	00 
  1001cd:	c7 44 24 08 62 30 10 	movl   $0x103062,0x8(%esp)
  1001d4:	00 
  1001d5:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  1001dc:	00 
  1001dd:	c7 04 24 77 30 10 00 	movl   $0x103077,(%esp)
  1001e4:	e8 5b 01 00 00       	call   100344 <debug_panic>
	return c;
  1001e9:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  1001ec:	83 c4 24             	add    $0x24,%esp
  1001ef:	5b                   	pop    %ebx
  1001f0:	5d                   	pop    %ebp
  1001f1:	c3                   	ret    

001001f2 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  1001f2:	55                   	push   %ebp
  1001f3:	89 e5                	mov    %esp,%ebp
  1001f5:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  1001f8:	e8 9b ff ff ff       	call   100198 <cpu_cur>
  1001fd:	3d 00 70 10 00       	cmp    $0x107000,%eax
  100202:	0f 94 c0             	sete   %al
  100205:	0f b6 c0             	movzbl %al,%eax
}
  100208:	c9                   	leave  
  100209:	c3                   	ret    

0010020a <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
void
cons_intr(int (*proc)(void))
{
  10020a:	55                   	push   %ebp
  10020b:	89 e5                	mov    %esp,%ebp
  10020d:	83 ec 18             	sub    $0x18,%esp
	int c;

	while ((c = (*proc)()) != -1) {
  100210:	eb 35                	jmp    100247 <cons_intr+0x3d>
		if (c == 0)
  100212:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  100216:	74 2e                	je     100246 <cons_intr+0x3c>
			continue;
		cons.buf[cons.wpos++] = c;
  100218:	a1 84 97 10 00       	mov    0x109784,%eax
  10021d:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100220:	88 90 80 95 10 00    	mov    %dl,0x109580(%eax)
  100226:	83 c0 01             	add    $0x1,%eax
  100229:	a3 84 97 10 00       	mov    %eax,0x109784
		if (cons.wpos == CONSBUFSIZE)
  10022e:	a1 84 97 10 00       	mov    0x109784,%eax
  100233:	3d 00 02 00 00       	cmp    $0x200,%eax
  100238:	75 0d                	jne    100247 <cons_intr+0x3d>
			cons.wpos = 0;
  10023a:	c7 05 84 97 10 00 00 	movl   $0x0,0x109784
  100241:	00 00 00 
  100244:	eb 01                	jmp    100247 <cons_intr+0x3d>
{
	int c;

	while ((c = (*proc)()) != -1) {
		if (c == 0)
			continue;
  100246:	90                   	nop
void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
  100247:	8b 45 08             	mov    0x8(%ebp),%eax
  10024a:	ff d0                	call   *%eax
  10024c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10024f:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
  100253:	75 bd                	jne    100212 <cons_intr+0x8>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
  100255:	c9                   	leave  
  100256:	c3                   	ret    

00100257 <cons_getc>:

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
  100257:	55                   	push   %ebp
  100258:	89 e5                	mov    %esp,%ebp
  10025a:	83 ec 18             	sub    $0x18,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
  10025d:	e8 ac 1c 00 00       	call   101f0e <serial_intr>
	kbd_intr();
  100262:	e8 d3 1b 00 00       	call   101e3a <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
  100267:	8b 15 80 97 10 00    	mov    0x109780,%edx
  10026d:	a1 84 97 10 00       	mov    0x109784,%eax
  100272:	39 c2                	cmp    %eax,%edx
  100274:	74 35                	je     1002ab <cons_getc+0x54>
		c = cons.buf[cons.rpos++];
  100276:	a1 80 97 10 00       	mov    0x109780,%eax
  10027b:	0f b6 90 80 95 10 00 	movzbl 0x109580(%eax),%edx
  100282:	0f b6 d2             	movzbl %dl,%edx
  100285:	89 55 f4             	mov    %edx,-0xc(%ebp)
  100288:	83 c0 01             	add    $0x1,%eax
  10028b:	a3 80 97 10 00       	mov    %eax,0x109780
		if (cons.rpos == CONSBUFSIZE)
  100290:	a1 80 97 10 00       	mov    0x109780,%eax
  100295:	3d 00 02 00 00       	cmp    $0x200,%eax
  10029a:	75 0a                	jne    1002a6 <cons_getc+0x4f>
			cons.rpos = 0;
  10029c:	c7 05 80 97 10 00 00 	movl   $0x0,0x109780
  1002a3:	00 00 00 
		return c;
  1002a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1002a9:	eb 05                	jmp    1002b0 <cons_getc+0x59>
	}
	return 0;
  1002ab:	b8 00 00 00 00       	mov    $0x0,%eax
}
  1002b0:	c9                   	leave  
  1002b1:	c3                   	ret    

001002b2 <cons_putc>:

// output a character to the console
static void
cons_putc(int c)
{
  1002b2:	55                   	push   %ebp
  1002b3:	89 e5                	mov    %esp,%ebp
  1002b5:	83 ec 18             	sub    $0x18,%esp
	serial_putc(c);
  1002b8:	8b 45 08             	mov    0x8(%ebp),%eax
  1002bb:	89 04 24             	mov    %eax,(%esp)
  1002be:	e8 68 1c 00 00       	call   101f2b <serial_putc>
	video_putc(c);
  1002c3:	8b 45 08             	mov    0x8(%ebp),%eax
  1002c6:	89 04 24             	mov    %eax,(%esp)
  1002c9:	e8 bf 17 00 00       	call   101a8d <video_putc>
}
  1002ce:	c9                   	leave  
  1002cf:	c3                   	ret    

001002d0 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
  1002d0:	55                   	push   %ebp
  1002d1:	89 e5                	mov    %esp,%ebp
  1002d3:	83 ec 18             	sub    $0x18,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  1002d6:	e8 17 ff ff ff       	call   1001f2 <cpu_onboot>
  1002db:	85 c0                	test   %eax,%eax
  1002dd:	74 36                	je     100315 <cons_init+0x45>
		return;

	video_init();
  1002df:	e8 cc 16 00 00       	call   1019b0 <video_init>
	kbd_init();
  1002e4:	e8 65 1b 00 00       	call   101e4e <kbd_init>
	serial_init();
  1002e9:	e8 ad 1c 00 00       	call   101f9b <serial_init>

	if (!serial_exists)
  1002ee:	a1 c0 9f 10 00       	mov    0x109fc0,%eax
  1002f3:	85 c0                	test   %eax,%eax
  1002f5:	75 1f                	jne    100316 <cons_init+0x46>
		warn("Serial port does not exist!\n");
  1002f7:	c7 44 24 08 84 30 10 	movl   $0x103084,0x8(%esp)
  1002fe:	00 
  1002ff:	c7 44 24 04 69 00 00 	movl   $0x69,0x4(%esp)
  100306:	00 
  100307:	c7 04 24 a1 30 10 00 	movl   $0x1030a1,(%esp)
  10030e:	e8 f7 00 00 00       	call   10040a <debug_warn>
  100313:	eb 01                	jmp    100316 <cons_init+0x46>
// initialize the console devices
void
cons_init(void)
{
	if (!cpu_onboot())	// only do once, on the boot CPU
		return;
  100315:	90                   	nop
	kbd_init();
	serial_init();

	if (!serial_exists)
		warn("Serial port does not exist!\n");
}
  100316:	c9                   	leave  
  100317:	c3                   	ret    

00100318 <cputs>:


// `High'-level console I/O.  Used by readline and cprintf.
void
cputs(const char *str)
{
  100318:	55                   	push   %ebp
  100319:	89 e5                	mov    %esp,%ebp
  10031b:	83 ec 18             	sub    $0x18,%esp
	char ch;
	while (*str)
  10031e:	eb 15                	jmp    100335 <cputs+0x1d>
		cons_putc(*str++);
  100320:	8b 45 08             	mov    0x8(%ebp),%eax
  100323:	0f b6 00             	movzbl (%eax),%eax
  100326:	0f be c0             	movsbl %al,%eax
  100329:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10032d:	89 04 24             	mov    %eax,(%esp)
  100330:	e8 7d ff ff ff       	call   1002b2 <cons_putc>
// `High'-level console I/O.  Used by readline and cprintf.
void
cputs(const char *str)
{
	char ch;
	while (*str)
  100335:	8b 45 08             	mov    0x8(%ebp),%eax
  100338:	0f b6 00             	movzbl (%eax),%eax
  10033b:	84 c0                	test   %al,%al
  10033d:	75 e1                	jne    100320 <cputs+0x8>
		cons_putc(*str++);
}
  10033f:	c9                   	leave  
  100340:	c3                   	ret    
  100341:	90                   	nop
  100342:	90                   	nop
  100343:	90                   	nop

00100344 <debug_panic>:

// Panic is called on unresolvable fatal errors.
// It prints "panic: mesg", and then enters the kernel monitor.
void
debug_panic(const char *file, int line, const char *fmt,...)
{
  100344:	55                   	push   %ebp
  100345:	89 e5                	mov    %esp,%ebp
  100347:	53                   	push   %ebx
  100348:	83 ec 54             	sub    $0x54,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  10034b:	66 8c cb             	mov    %cs,%bx
  10034e:	66 89 5d ee          	mov    %bx,-0x12(%ebp)
        return cs;
  100352:	0f b7 45 ee          	movzwl -0x12(%ebp),%eax
	va_list ap;
	int i;

	// Avoid infinite recursion if we're panicking from kernel mode.
	if ((read_cs() & 3) == 0) {
  100356:	0f b7 c0             	movzwl %ax,%eax
  100359:	83 e0 03             	and    $0x3,%eax
  10035c:	85 c0                	test   %eax,%eax
  10035e:	75 15                	jne    100375 <debug_panic+0x31>
		if (panicstr)
  100360:	a1 88 97 10 00       	mov    0x109788,%eax
  100365:	85 c0                	test   %eax,%eax
  100367:	0f 85 97 00 00 00    	jne    100404 <debug_panic+0xc0>
			goto dead;
		panicstr = fmt;
  10036d:	8b 45 10             	mov    0x10(%ebp),%eax
  100370:	a3 88 97 10 00       	mov    %eax,0x109788
	}

	// First print the requested message
	va_start(ap, fmt);
  100375:	8d 45 10             	lea    0x10(%ebp),%eax
  100378:	83 c0 04             	add    $0x4,%eax
  10037b:	89 45 f0             	mov    %eax,-0x10(%ebp)
	cprintf("kernel panic at %s:%d: ", file, line);
  10037e:	8b 45 0c             	mov    0xc(%ebp),%eax
  100381:	89 44 24 08          	mov    %eax,0x8(%esp)
  100385:	8b 45 08             	mov    0x8(%ebp),%eax
  100388:	89 44 24 04          	mov    %eax,0x4(%esp)
  10038c:	c7 04 24 b0 30 10 00 	movl   $0x1030b0,(%esp)
  100393:	e8 10 25 00 00       	call   1028a8 <cprintf>
	vcprintf(fmt, ap);
  100398:	8b 45 10             	mov    0x10(%ebp),%eax
  10039b:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10039e:	89 54 24 04          	mov    %edx,0x4(%esp)
  1003a2:	89 04 24             	mov    %eax,(%esp)
  1003a5:	e8 96 24 00 00       	call   102840 <vcprintf>
	cprintf("\n");
  1003aa:	c7 04 24 c8 30 10 00 	movl   $0x1030c8,(%esp)
  1003b1:	e8 f2 24 00 00       	call   1028a8 <cprintf>

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  1003b6:	89 eb                	mov    %ebp,%ebx
  1003b8:	89 5d e8             	mov    %ebx,-0x18(%ebp)
        return ebp;
  1003bb:	8b 45 e8             	mov    -0x18(%ebp),%eax
	va_end(ap);

	// Then print a backtrace of the kernel call chain
	uint32_t eips[DEBUG_TRACEFRAMES];
	debug_trace(read_ebp(), eips);
  1003be:	8d 55 c0             	lea    -0x40(%ebp),%edx
  1003c1:	89 54 24 04          	mov    %edx,0x4(%esp)
  1003c5:	89 04 24             	mov    %eax,(%esp)
  1003c8:	e8 86 00 00 00       	call   100453 <debug_trace>
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
  1003cd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  1003d4:	eb 1b                	jmp    1003f1 <debug_panic+0xad>
		cprintf("  from %08x\n", eips[i]);
  1003d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1003d9:	8b 44 85 c0          	mov    -0x40(%ebp,%eax,4),%eax
  1003dd:	89 44 24 04          	mov    %eax,0x4(%esp)
  1003e1:	c7 04 24 ca 30 10 00 	movl   $0x1030ca,(%esp)
  1003e8:	e8 bb 24 00 00       	call   1028a8 <cprintf>
	va_end(ap);

	// Then print a backtrace of the kernel call chain
	uint32_t eips[DEBUG_TRACEFRAMES];
	debug_trace(read_ebp(), eips);
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
  1003ed:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  1003f1:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  1003f5:	7f 0e                	jg     100405 <debug_panic+0xc1>
  1003f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1003fa:	8b 44 85 c0          	mov    -0x40(%ebp,%eax,4),%eax
  1003fe:	85 c0                	test   %eax,%eax
  100400:	75 d4                	jne    1003d6 <debug_panic+0x92>
  100402:	eb 01                	jmp    100405 <debug_panic+0xc1>
	int i;

	// Avoid infinite recursion if we're panicking from kernel mode.
	if ((read_cs() & 3) == 0) {
		if (panicstr)
			goto dead;
  100404:	90                   	nop
	debug_trace(read_ebp(), eips);
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
		cprintf("  from %08x\n", eips[i]);

dead:
	done();		// enter infinite loop (see kern/init.c)
  100405:	e8 86 fd ff ff       	call   100190 <done>

0010040a <debug_warn>:
}

/* like panic, but don't */
void
debug_warn(const char *file, int line, const char *fmt,...)
{
  10040a:	55                   	push   %ebp
  10040b:	89 e5                	mov    %esp,%ebp
  10040d:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
  100410:	8d 45 10             	lea    0x10(%ebp),%eax
  100413:	83 c0 04             	add    $0x4,%eax
  100416:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("kernel warning at %s:%d: ", file, line);
  100419:	8b 45 0c             	mov    0xc(%ebp),%eax
  10041c:	89 44 24 08          	mov    %eax,0x8(%esp)
  100420:	8b 45 08             	mov    0x8(%ebp),%eax
  100423:	89 44 24 04          	mov    %eax,0x4(%esp)
  100427:	c7 04 24 d7 30 10 00 	movl   $0x1030d7,(%esp)
  10042e:	e8 75 24 00 00       	call   1028a8 <cprintf>
	vcprintf(fmt, ap);
  100433:	8b 45 10             	mov    0x10(%ebp),%eax
  100436:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100439:	89 54 24 04          	mov    %edx,0x4(%esp)
  10043d:	89 04 24             	mov    %eax,(%esp)
  100440:	e8 fb 23 00 00       	call   102840 <vcprintf>
	cprintf("\n");
  100445:	c7 04 24 c8 30 10 00 	movl   $0x1030c8,(%esp)
  10044c:	e8 57 24 00 00       	call   1028a8 <cprintf>
	va_end(ap);
}
  100451:	c9                   	leave  
  100452:	c3                   	ret    

00100453 <debug_trace>:

// Record the current call stack in eips[] by following the %ebp chain.
void gcc_noinline
debug_trace(uint32_t ebp, uint32_t eips[DEBUG_TRACEFRAMES])
{
  100453:	55                   	push   %ebp
  100454:	89 e5                	mov    %esp,%ebp
  100456:	56                   	push   %esi
  100457:	53                   	push   %ebx
  100458:	83 ec 30             	sub    $0x30,%esp
	uint32_t *trace = (uint32_t *) ebp;
  10045b:	8b 45 08             	mov    0x8(%ebp),%eax
  10045e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  	int i;

  	//cprintf("Stack backtrace:\n");
  	for (i = 0; i < DEBUG_TRACEFRAMES && trace; i++) {
  100461:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  100468:	e9 a4 00 00 00       	jmp    100511 <debug_trace+0xbe>
    		cprintf("ebp %08x  ", trace[0]);
  10046d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100470:	8b 00                	mov    (%eax),%eax
  100472:	89 44 24 04          	mov    %eax,0x4(%esp)
  100476:	c7 04 24 f1 30 10 00 	movl   $0x1030f1,(%esp)
  10047d:	e8 26 24 00 00       	call   1028a8 <cprintf>
    		cprintf("eip %08x  ", trace[1]);
  100482:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100485:	83 c0 04             	add    $0x4,%eax
  100488:	8b 00                	mov    (%eax),%eax
  10048a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10048e:	c7 04 24 fc 30 10 00 	movl   $0x1030fc,(%esp)
  100495:	e8 0e 24 00 00       	call   1028a8 <cprintf>
    		cprintf("args %08x %08x %08x %08x %08x ", trace[2], trace[3], trace[4], trace[5], trace[6]);
  10049a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10049d:	83 c0 18             	add    $0x18,%eax
  1004a0:	8b 30                	mov    (%eax),%esi
  1004a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1004a5:	83 c0 14             	add    $0x14,%eax
  1004a8:	8b 18                	mov    (%eax),%ebx
  1004aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1004ad:	83 c0 10             	add    $0x10,%eax
  1004b0:	8b 08                	mov    (%eax),%ecx
  1004b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1004b5:	83 c0 0c             	add    $0xc,%eax
  1004b8:	8b 10                	mov    (%eax),%edx
  1004ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1004bd:	83 c0 08             	add    $0x8,%eax
  1004c0:	8b 00                	mov    (%eax),%eax
  1004c2:	89 74 24 14          	mov    %esi,0x14(%esp)
  1004c6:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  1004ca:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  1004ce:	89 54 24 08          	mov    %edx,0x8(%esp)
  1004d2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1004d6:	c7 04 24 08 31 10 00 	movl   $0x103108,(%esp)
  1004dd:	e8 c6 23 00 00       	call   1028a8 <cprintf>
    		cprintf("\n"); 
  1004e2:	c7 04 24 c8 30 10 00 	movl   $0x1030c8,(%esp)
  1004e9:	e8 ba 23 00 00       	call   1028a8 <cprintf>
		//save eips
    		eips[i] = trace[1];
  1004ee:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1004f1:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  1004f8:	8b 45 0c             	mov    0xc(%ebp),%eax
  1004fb:	01 c2                	add    %eax,%edx
  1004fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100500:	8b 40 04             	mov    0x4(%eax),%eax
  100503:	89 02                	mov    %eax,(%edx)

    		//traceback the call stack using old ebp
    		trace = (uint32_t*)trace[0];  // prev ebp saved at ebp 0
  100505:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100508:	8b 00                	mov    (%eax),%eax
  10050a:	89 45 f4             	mov    %eax,-0xc(%ebp)
{
	uint32_t *trace = (uint32_t *) ebp;
  	int i;

  	//cprintf("Stack backtrace:\n");
  	for (i = 0; i < DEBUG_TRACEFRAMES && trace; i++) {
  10050d:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  100511:	83 7d f0 09          	cmpl   $0x9,-0x10(%ebp)
  100515:	7f 25                	jg     10053c <debug_trace+0xe9>
  100517:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  10051b:	0f 85 4c ff ff ff    	jne    10046d <debug_trace+0x1a>
    		//traceback the call stack using old ebp
    		trace = (uint32_t*)trace[0];  // prev ebp saved at ebp 0
  	}

  	// set rest eips as 0
  	for (i; i < DEBUG_TRACEFRAMES; i++) {
  100521:	eb 19                	jmp    10053c <debug_trace+0xe9>
    		eips[i] = 0; 
  100523:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100526:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  10052d:	8b 45 0c             	mov    0xc(%ebp),%eax
  100530:	01 d0                	add    %edx,%eax
  100532:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    		//traceback the call stack using old ebp
    		trace = (uint32_t*)trace[0];  // prev ebp saved at ebp 0
  	}

  	// set rest eips as 0
  	for (i; i < DEBUG_TRACEFRAMES; i++) {
  100538:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  10053c:	83 7d f0 09          	cmpl   $0x9,-0x10(%ebp)
  100540:	7e e1                	jle    100523 <debug_trace+0xd0>
    		eips[i] = 0; 
  	}
	//panic("debug_trace not implemented");
}
  100542:	83 c4 30             	add    $0x30,%esp
  100545:	5b                   	pop    %ebx
  100546:	5e                   	pop    %esi
  100547:	5d                   	pop    %ebp
  100548:	c3                   	ret    

00100549 <f3>:


static void gcc_noinline f3(int r, uint32_t *e) { debug_trace(read_ebp(), e); }
  100549:	55                   	push   %ebp
  10054a:	89 e5                	mov    %esp,%ebp
  10054c:	53                   	push   %ebx
  10054d:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  100550:	89 eb                	mov    %ebp,%ebx
  100552:	89 5d f4             	mov    %ebx,-0xc(%ebp)
        return ebp;
  100555:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100558:	8b 55 0c             	mov    0xc(%ebp),%edx
  10055b:	89 54 24 04          	mov    %edx,0x4(%esp)
  10055f:	89 04 24             	mov    %eax,(%esp)
  100562:	e8 ec fe ff ff       	call   100453 <debug_trace>
  100567:	83 c4 24             	add    $0x24,%esp
  10056a:	5b                   	pop    %ebx
  10056b:	5d                   	pop    %ebp
  10056c:	c3                   	ret    

0010056d <f2>:
static void gcc_noinline f2(int r, uint32_t *e) { r & 2 ? f3(r,e) : f3(r,e); }
  10056d:	55                   	push   %ebp
  10056e:	89 e5                	mov    %esp,%ebp
  100570:	83 ec 18             	sub    $0x18,%esp
  100573:	8b 45 08             	mov    0x8(%ebp),%eax
  100576:	83 e0 02             	and    $0x2,%eax
  100579:	85 c0                	test   %eax,%eax
  10057b:	74 14                	je     100591 <f2+0x24>
  10057d:	8b 45 0c             	mov    0xc(%ebp),%eax
  100580:	89 44 24 04          	mov    %eax,0x4(%esp)
  100584:	8b 45 08             	mov    0x8(%ebp),%eax
  100587:	89 04 24             	mov    %eax,(%esp)
  10058a:	e8 ba ff ff ff       	call   100549 <f3>
  10058f:	eb 12                	jmp    1005a3 <f2+0x36>
  100591:	8b 45 0c             	mov    0xc(%ebp),%eax
  100594:	89 44 24 04          	mov    %eax,0x4(%esp)
  100598:	8b 45 08             	mov    0x8(%ebp),%eax
  10059b:	89 04 24             	mov    %eax,(%esp)
  10059e:	e8 a6 ff ff ff       	call   100549 <f3>
  1005a3:	c9                   	leave  
  1005a4:	c3                   	ret    

001005a5 <f1>:
static void gcc_noinline f1(int r, uint32_t *e) { r & 1 ? f2(r,e) : f2(r,e); }
  1005a5:	55                   	push   %ebp
  1005a6:	89 e5                	mov    %esp,%ebp
  1005a8:	83 ec 18             	sub    $0x18,%esp
  1005ab:	8b 45 08             	mov    0x8(%ebp),%eax
  1005ae:	83 e0 01             	and    $0x1,%eax
  1005b1:	85 c0                	test   %eax,%eax
  1005b3:	74 14                	je     1005c9 <f1+0x24>
  1005b5:	8b 45 0c             	mov    0xc(%ebp),%eax
  1005b8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1005bc:	8b 45 08             	mov    0x8(%ebp),%eax
  1005bf:	89 04 24             	mov    %eax,(%esp)
  1005c2:	e8 a6 ff ff ff       	call   10056d <f2>
  1005c7:	eb 12                	jmp    1005db <f1+0x36>
  1005c9:	8b 45 0c             	mov    0xc(%ebp),%eax
  1005cc:	89 44 24 04          	mov    %eax,0x4(%esp)
  1005d0:	8b 45 08             	mov    0x8(%ebp),%eax
  1005d3:	89 04 24             	mov    %eax,(%esp)
  1005d6:	e8 92 ff ff ff       	call   10056d <f2>
  1005db:	c9                   	leave  
  1005dc:	c3                   	ret    

001005dd <debug_check>:

// Test the backtrace implementation for correct operation
void
debug_check(void)
{
  1005dd:	55                   	push   %ebp
  1005de:	89 e5                	mov    %esp,%ebp
  1005e0:	81 ec c8 00 00 00    	sub    $0xc8,%esp
	uint32_t eips[4][DEBUG_TRACEFRAMES];
	int r, i;

	// produce several related backtraces...
	for (i = 0; i < 4; i++)
  1005e6:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  1005ed:	eb 28                	jmp    100617 <debug_check+0x3a>
		f1(i, eips[i]);
  1005ef:	8d 8d 50 ff ff ff    	lea    -0xb0(%ebp),%ecx
  1005f5:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1005f8:	89 d0                	mov    %edx,%eax
  1005fa:	c1 e0 02             	shl    $0x2,%eax
  1005fd:	01 d0                	add    %edx,%eax
  1005ff:	c1 e0 03             	shl    $0x3,%eax
  100602:	01 c8                	add    %ecx,%eax
  100604:	89 44 24 04          	mov    %eax,0x4(%esp)
  100608:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10060b:	89 04 24             	mov    %eax,(%esp)
  10060e:	e8 92 ff ff ff       	call   1005a5 <f1>
{
	uint32_t eips[4][DEBUG_TRACEFRAMES];
	int r, i;

	// produce several related backtraces...
	for (i = 0; i < 4; i++)
  100613:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  100617:	83 7d f0 03          	cmpl   $0x3,-0x10(%ebp)
  10061b:	7e d2                	jle    1005ef <debug_check+0x12>
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
  10061d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  100624:	e9 bc 00 00 00       	jmp    1006e5 <debug_check+0x108>
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
  100629:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  100630:	e9 a2 00 00 00       	jmp    1006d7 <debug_check+0xfa>
			assert((eips[r][i] != 0) == (i < 5));
  100635:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100638:	89 d0                	mov    %edx,%eax
  10063a:	c1 e0 02             	shl    $0x2,%eax
  10063d:	01 d0                	add    %edx,%eax
  10063f:	01 c0                	add    %eax,%eax
  100641:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100644:	01 d0                	add    %edx,%eax
  100646:	8b 84 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%eax
  10064d:	85 c0                	test   %eax,%eax
  10064f:	0f 95 c2             	setne  %dl
  100652:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
  100656:	0f 9e c0             	setle  %al
  100659:	31 d0                	xor    %edx,%eax
  10065b:	84 c0                	test   %al,%al
  10065d:	74 24                	je     100683 <debug_check+0xa6>
  10065f:	c7 44 24 0c 27 31 10 	movl   $0x103127,0xc(%esp)
  100666:	00 
  100667:	c7 44 24 08 44 31 10 	movl   $0x103144,0x8(%esp)
  10066e:	00 
  10066f:	c7 44 24 04 74 00 00 	movl   $0x74,0x4(%esp)
  100676:	00 
  100677:	c7 04 24 59 31 10 00 	movl   $0x103159,(%esp)
  10067e:	e8 c1 fc ff ff       	call   100344 <debug_panic>
			if (i >= 2)
  100683:	83 7d f0 01          	cmpl   $0x1,-0x10(%ebp)
  100687:	7e 4a                	jle    1006d3 <debug_check+0xf6>
				assert(eips[r][i] == eips[0][i]);
  100689:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10068c:	89 d0                	mov    %edx,%eax
  10068e:	c1 e0 02             	shl    $0x2,%eax
  100691:	01 d0                	add    %edx,%eax
  100693:	01 c0                	add    %eax,%eax
  100695:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100698:	01 d0                	add    %edx,%eax
  10069a:	8b 94 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%edx
  1006a1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1006a4:	8b 84 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%eax
  1006ab:	39 c2                	cmp    %eax,%edx
  1006ad:	74 24                	je     1006d3 <debug_check+0xf6>
  1006af:	c7 44 24 0c 66 31 10 	movl   $0x103166,0xc(%esp)
  1006b6:	00 
  1006b7:	c7 44 24 08 44 31 10 	movl   $0x103144,0x8(%esp)
  1006be:	00 
  1006bf:	c7 44 24 04 76 00 00 	movl   $0x76,0x4(%esp)
  1006c6:	00 
  1006c7:	c7 04 24 59 31 10 00 	movl   $0x103159,(%esp)
  1006ce:	e8 71 fc ff ff       	call   100344 <debug_panic>
	for (i = 0; i < 4; i++)
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
  1006d3:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  1006d7:	83 7d f0 09          	cmpl   $0x9,-0x10(%ebp)
  1006db:	0f 8e 54 ff ff ff    	jle    100635 <debug_check+0x58>
	// produce several related backtraces...
	for (i = 0; i < 4; i++)
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
  1006e1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  1006e5:	83 7d f4 03          	cmpl   $0x3,-0xc(%ebp)
  1006e9:	0f 8e 3a ff ff ff    	jle    100629 <debug_check+0x4c>
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
			assert((eips[r][i] != 0) == (i < 5));
			if (i >= 2)
				assert(eips[r][i] == eips[0][i]);
		}
	assert(eips[0][0] == eips[1][0]);
  1006ef:	8b 95 50 ff ff ff    	mov    -0xb0(%ebp),%edx
  1006f5:	8b 85 78 ff ff ff    	mov    -0x88(%ebp),%eax
  1006fb:	39 c2                	cmp    %eax,%edx
  1006fd:	74 24                	je     100723 <debug_check+0x146>
  1006ff:	c7 44 24 0c 7f 31 10 	movl   $0x10317f,0xc(%esp)
  100706:	00 
  100707:	c7 44 24 08 44 31 10 	movl   $0x103144,0x8(%esp)
  10070e:	00 
  10070f:	c7 44 24 04 78 00 00 	movl   $0x78,0x4(%esp)
  100716:	00 
  100717:	c7 04 24 59 31 10 00 	movl   $0x103159,(%esp)
  10071e:	e8 21 fc ff ff       	call   100344 <debug_panic>
	assert(eips[2][0] == eips[3][0]);
  100723:	8b 55 a0             	mov    -0x60(%ebp),%edx
  100726:	8b 45 c8             	mov    -0x38(%ebp),%eax
  100729:	39 c2                	cmp    %eax,%edx
  10072b:	74 24                	je     100751 <debug_check+0x174>
  10072d:	c7 44 24 0c 98 31 10 	movl   $0x103198,0xc(%esp)
  100734:	00 
  100735:	c7 44 24 08 44 31 10 	movl   $0x103144,0x8(%esp)
  10073c:	00 
  10073d:	c7 44 24 04 79 00 00 	movl   $0x79,0x4(%esp)
  100744:	00 
  100745:	c7 04 24 59 31 10 00 	movl   $0x103159,(%esp)
  10074c:	e8 f3 fb ff ff       	call   100344 <debug_panic>
	assert(eips[1][0] != eips[2][0]);
  100751:	8b 95 78 ff ff ff    	mov    -0x88(%ebp),%edx
  100757:	8b 45 a0             	mov    -0x60(%ebp),%eax
  10075a:	39 c2                	cmp    %eax,%edx
  10075c:	75 24                	jne    100782 <debug_check+0x1a5>
  10075e:	c7 44 24 0c b1 31 10 	movl   $0x1031b1,0xc(%esp)
  100765:	00 
  100766:	c7 44 24 08 44 31 10 	movl   $0x103144,0x8(%esp)
  10076d:	00 
  10076e:	c7 44 24 04 7a 00 00 	movl   $0x7a,0x4(%esp)
  100775:	00 
  100776:	c7 04 24 59 31 10 00 	movl   $0x103159,(%esp)
  10077d:	e8 c2 fb ff ff       	call   100344 <debug_panic>
	assert(eips[0][1] == eips[2][1]);
  100782:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  100788:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  10078b:	39 c2                	cmp    %eax,%edx
  10078d:	74 24                	je     1007b3 <debug_check+0x1d6>
  10078f:	c7 44 24 0c ca 31 10 	movl   $0x1031ca,0xc(%esp)
  100796:	00 
  100797:	c7 44 24 08 44 31 10 	movl   $0x103144,0x8(%esp)
  10079e:	00 
  10079f:	c7 44 24 04 7b 00 00 	movl   $0x7b,0x4(%esp)
  1007a6:	00 
  1007a7:	c7 04 24 59 31 10 00 	movl   $0x103159,(%esp)
  1007ae:	e8 91 fb ff ff       	call   100344 <debug_panic>
	assert(eips[1][1] == eips[3][1]);
  1007b3:	8b 95 7c ff ff ff    	mov    -0x84(%ebp),%edx
  1007b9:	8b 45 cc             	mov    -0x34(%ebp),%eax
  1007bc:	39 c2                	cmp    %eax,%edx
  1007be:	74 24                	je     1007e4 <debug_check+0x207>
  1007c0:	c7 44 24 0c e3 31 10 	movl   $0x1031e3,0xc(%esp)
  1007c7:	00 
  1007c8:	c7 44 24 08 44 31 10 	movl   $0x103144,0x8(%esp)
  1007cf:	00 
  1007d0:	c7 44 24 04 7c 00 00 	movl   $0x7c,0x4(%esp)
  1007d7:	00 
  1007d8:	c7 04 24 59 31 10 00 	movl   $0x103159,(%esp)
  1007df:	e8 60 fb ff ff       	call   100344 <debug_panic>
	assert(eips[0][1] != eips[1][1]);
  1007e4:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  1007ea:	8b 85 7c ff ff ff    	mov    -0x84(%ebp),%eax
  1007f0:	39 c2                	cmp    %eax,%edx
  1007f2:	75 24                	jne    100818 <debug_check+0x23b>
  1007f4:	c7 44 24 0c fc 31 10 	movl   $0x1031fc,0xc(%esp)
  1007fb:	00 
  1007fc:	c7 44 24 08 44 31 10 	movl   $0x103144,0x8(%esp)
  100803:	00 
  100804:	c7 44 24 04 7d 00 00 	movl   $0x7d,0x4(%esp)
  10080b:	00 
  10080c:	c7 04 24 59 31 10 00 	movl   $0x103159,(%esp)
  100813:	e8 2c fb ff ff       	call   100344 <debug_panic>

	cprintf("debug_check() succeeded!\n");
  100818:	c7 04 24 15 32 10 00 	movl   $0x103215,(%esp)
  10081f:	e8 84 20 00 00       	call   1028a8 <cprintf>
//	while(1);
}
  100824:	c9                   	leave  
  100825:	c3                   	ret    
  100826:	90                   	nop
  100827:	90                   	nop

00100828 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  100828:	55                   	push   %ebp
  100829:	89 e5                	mov    %esp,%ebp
  10082b:	53                   	push   %ebx
  10082c:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10082f:	89 e3                	mov    %esp,%ebx
  100831:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  100834:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  100837:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10083a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10083d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100842:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  100845:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100848:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  10084e:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  100853:	74 24                	je     100879 <cpu_cur+0x51>
  100855:	c7 44 24 0c 30 32 10 	movl   $0x103230,0xc(%esp)
  10085c:	00 
  10085d:	c7 44 24 08 46 32 10 	movl   $0x103246,0x8(%esp)
  100864:	00 
  100865:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  10086c:	00 
  10086d:	c7 04 24 5b 32 10 00 	movl   $0x10325b,(%esp)
  100874:	e8 cb fa ff ff       	call   100344 <debug_panic>
	return c;
  100879:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  10087c:	83 c4 24             	add    $0x24,%esp
  10087f:	5b                   	pop    %ebx
  100880:	5d                   	pop    %ebp
  100881:	c3                   	ret    

00100882 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  100882:	55                   	push   %ebp
  100883:	89 e5                	mov    %esp,%ebp
  100885:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  100888:	e8 9b ff ff ff       	call   100828 <cpu_cur>
  10088d:	3d 00 70 10 00       	cmp    $0x107000,%eax
  100892:	0f 94 c0             	sete   %al
  100895:	0f b6 c0             	movzbl %al,%eax
}
  100898:	c9                   	leave  
  100899:	c3                   	ret    

0010089a <mem_init>:

void mem_check(void);

void
mem_init(void)
{
  10089a:	55                   	push   %ebp
  10089b:	89 e5                	mov    %esp,%ebp
  10089d:	83 ec 38             	sub    $0x38,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  1008a0:	e8 dd ff ff ff       	call   100882 <cpu_onboot>
  1008a5:	85 c0                	test   %eax,%eax
  1008a7:	0f 84 2c 01 00 00    	je     1009d9 <mem_init+0x13f>
	// is available in the system (in bytes),
	// by reading the PC's BIOS-managed nonvolatile RAM (NVRAM).
	// The NVRAM tells us how many kilobytes there are.
	// Since the count is 16 bits, this gives us up to 64MB of RAM;
	// additional RAM beyond that would have to be detected another way.
	size_t basemem = ROUNDDOWN(nvram_read16(NVRAM_BASELO)*1024, PAGESIZE);
  1008ad:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
  1008b4:	e8 09 18 00 00       	call   1020c2 <nvram_read16>
  1008b9:	c1 e0 0a             	shl    $0xa,%eax
  1008bc:	89 45 ec             	mov    %eax,-0x14(%ebp)
  1008bf:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1008c2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1008c7:	89 45 e8             	mov    %eax,-0x18(%ebp)
	size_t extmem = ROUNDDOWN(nvram_read16(NVRAM_EXTLO)*1024, PAGESIZE);
  1008ca:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
  1008d1:	e8 ec 17 00 00       	call   1020c2 <nvram_read16>
  1008d6:	c1 e0 0a             	shl    $0xa,%eax
  1008d9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  1008dc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1008df:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1008e4:	89 45 e0             	mov    %eax,-0x20(%ebp)

	warn("Assuming we have 1GB of memory!");
  1008e7:	c7 44 24 08 68 32 10 	movl   $0x103268,0x8(%esp)
  1008ee:	00 
  1008ef:	c7 44 24 04 2f 00 00 	movl   $0x2f,0x4(%esp)
  1008f6:	00 
  1008f7:	c7 04 24 88 32 10 00 	movl   $0x103288,(%esp)
  1008fe:	e8 07 fb ff ff       	call   10040a <debug_warn>
	extmem = 1024*1024*1024 - MEM_EXT;	// assume 1GB total memory
  100903:	c7 45 e0 00 00 f0 3f 	movl   $0x3ff00000,-0x20(%ebp)

	// The maximum physical address is the top of extended memory.
	mem_max = MEM_EXT + extmem;
  10090a:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10090d:	05 00 00 10 00       	add    $0x100000,%eax
  100912:	a3 b8 9f 10 00       	mov    %eax,0x109fb8

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;
  100917:	a1 b8 9f 10 00       	mov    0x109fb8,%eax
  10091c:	c1 e8 0c             	shr    $0xc,%eax
  10091f:	a3 b4 9f 10 00       	mov    %eax,0x109fb4

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
  100924:	a1 b8 9f 10 00       	mov    0x109fb8,%eax
  100929:	c1 e8 0a             	shr    $0xa,%eax
  10092c:	89 44 24 04          	mov    %eax,0x4(%esp)
  100930:	c7 04 24 94 32 10 00 	movl   $0x103294,(%esp)
  100937:	e8 6c 1f 00 00       	call   1028a8 <cprintf>
	cprintf("base = %dK, extended = %dK\n",
		(int)(basemem/1024), (int)(extmem/1024));
  10093c:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10093f:	c1 e8 0a             	shr    $0xa,%eax

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
	cprintf("base = %dK, extended = %dK\n",
  100942:	89 c2                	mov    %eax,%edx
		(int)(basemem/1024), (int)(extmem/1024));
  100944:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100947:	c1 e8 0a             	shr    $0xa,%eax

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
	cprintf("base = %dK, extended = %dK\n",
  10094a:	89 54 24 08          	mov    %edx,0x8(%esp)
  10094e:	89 44 24 04          	mov    %eax,0x4(%esp)
  100952:	c7 04 24 b5 32 10 00 	movl   $0x1032b5,(%esp)
  100959:	e8 4a 1f 00 00       	call   1028a8 <cprintf>
	//     but YOU decide where to place the pageinfo array.
	// Change the code to reflect this.
	//pageinfo *mem_pageinfo;
	//memset(mem_pageinfo, 0, sizeof(pageinfo)*mem_npage);

	pageinfo **freetail = &mem_freelist;
  10095e:	c7 45 f4 b0 9f 10 00 	movl   $0x109fb0,-0xc(%ebp)
	int i;
	for (i = 0; i < mem_npage; i++) {
  100965:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  10096c:	eb 3a                	jmp    1009a8 <mem_init+0x10e>
		// A free page has no references to it.
		mem_pageinfo[i].refcount = 0;
  10096e:	a1 bc 9f 10 00       	mov    0x109fbc,%eax
  100973:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100976:	c1 e2 03             	shl    $0x3,%edx
  100979:	01 d0                	add    %edx,%eax
  10097b:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)

		// Add the page to the end of the free list.
		*freetail = &mem_pageinfo[i];
  100982:	a1 bc 9f 10 00       	mov    0x109fbc,%eax
  100987:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10098a:	c1 e2 03             	shl    $0x3,%edx
  10098d:	01 c2                	add    %eax,%edx
  10098f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100992:	89 10                	mov    %edx,(%eax)
		freetail = &mem_pageinfo[i].free_next;
  100994:	a1 bc 9f 10 00       	mov    0x109fbc,%eax
  100999:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10099c:	c1 e2 03             	shl    $0x3,%edx
  10099f:	01 d0                	add    %edx,%eax
  1009a1:	89 45 f4             	mov    %eax,-0xc(%ebp)
	//pageinfo *mem_pageinfo;
	//memset(mem_pageinfo, 0, sizeof(pageinfo)*mem_npage);

	pageinfo **freetail = &mem_freelist;
	int i;
	for (i = 0; i < mem_npage; i++) {
  1009a4:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  1009a8:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1009ab:	a1 b4 9f 10 00       	mov    0x109fb4,%eax
  1009b0:	39 c2                	cmp    %eax,%edx
  1009b2:	72 ba                	jb     10096e <mem_init+0xd4>

		// Add the page to the end of the free list.
		*freetail = &mem_pageinfo[i];
		freetail = &mem_pageinfo[i].free_next;
	}
	*freetail = NULL;	// null-terminate the freelist
  1009b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1009b7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	// ...and remove this when you're ready.
	panic("mem_init() not implemented");
  1009bd:	c7 44 24 08 d1 32 10 	movl   $0x1032d1,0x8(%esp)
  1009c4:	00 
  1009c5:	c7 44 24 04 62 00 00 	movl   $0x62,0x4(%esp)
  1009cc:	00 
  1009cd:	c7 04 24 88 32 10 00 	movl   $0x103288,(%esp)
  1009d4:	e8 6b f9 ff ff       	call   100344 <debug_panic>

void
mem_init(void)
{
	if (!cpu_onboot())	// only do once, on the boot CPU
		return;
  1009d9:	90                   	nop
	// ...and remove this when you're ready.
	panic("mem_init() not implemented");

	// Check to make sure the page allocator seems to work correctly.
	mem_check();
}
  1009da:	c9                   	leave  
  1009db:	c3                   	ret    

001009dc <mem_alloc>:
//
// Hint: pi->refs should not be incremented 
// Hint: be sure to use proper mutual exclusion for multiprocessor operation.
pageinfo *
mem_alloc(void)
{
  1009dc:	55                   	push   %ebp
  1009dd:	89 e5                	mov    %esp,%ebp
  1009df:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in
	// Fill this function in.
	panic("mem_alloc not implemented.");
  1009e2:	c7 44 24 08 ec 32 10 	movl   $0x1032ec,0x8(%esp)
  1009e9:	00 
  1009ea:	c7 44 24 04 78 00 00 	movl   $0x78,0x4(%esp)
  1009f1:	00 
  1009f2:	c7 04 24 88 32 10 00 	movl   $0x103288,(%esp)
  1009f9:	e8 46 f9 ff ff       	call   100344 <debug_panic>

001009fe <mem_free>:
// Return a page to the free list, given its pageinfo pointer.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
mem_free(pageinfo *pi)
{
  1009fe:	55                   	push   %ebp
  1009ff:	89 e5                	mov    %esp,%ebp
  100a01:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in.
	panic("mem_free not implemented.");
  100a04:	c7 44 24 08 07 33 10 	movl   $0x103307,0x8(%esp)
  100a0b:	00 
  100a0c:	c7 44 24 04 83 00 00 	movl   $0x83,0x4(%esp)
  100a13:	00 
  100a14:	c7 04 24 88 32 10 00 	movl   $0x103288,(%esp)
  100a1b:	e8 24 f9 ff ff       	call   100344 <debug_panic>

00100a20 <mem_check>:
// Check the physical page allocator (mem_alloc(), mem_free())
// for correct operation after initialization via mem_init().
//
void
mem_check()
{
  100a20:	55                   	push   %ebp
  100a21:	89 e5                	mov    %esp,%ebp
  100a23:	83 ec 38             	sub    $0x38,%esp
	int i;

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
  100a26:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
  100a2d:	a1 b0 9f 10 00       	mov    0x109fb0,%eax
  100a32:	89 45 f4             	mov    %eax,-0xc(%ebp)
  100a35:	eb 38                	jmp    100a6f <mem_check+0x4f>
		memset(mem_pi2ptr(pp), 0x97, 128);
  100a37:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100a3a:	a1 bc 9f 10 00       	mov    0x109fbc,%eax
  100a3f:	89 d1                	mov    %edx,%ecx
  100a41:	29 c1                	sub    %eax,%ecx
  100a43:	89 c8                	mov    %ecx,%eax
  100a45:	c1 f8 03             	sar    $0x3,%eax
  100a48:	c1 e0 0c             	shl    $0xc,%eax
  100a4b:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
  100a52:	00 
  100a53:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
  100a5a:	00 
  100a5b:	89 04 24             	mov    %eax,(%esp)
  100a5e:	e8 2a 20 00 00       	call   102a8d <memset>
		freepages++;
  100a63:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
  100a67:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100a6a:	8b 00                	mov    (%eax),%eax
  100a6c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  100a6f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  100a73:	75 c2                	jne    100a37 <mem_check+0x17>
		memset(mem_pi2ptr(pp), 0x97, 128);
		freepages++;
	}
	cprintf("mem_check: %d free pages\n", freepages);
  100a75:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100a78:	89 44 24 04          	mov    %eax,0x4(%esp)
  100a7c:	c7 04 24 21 33 10 00 	movl   $0x103321,(%esp)
  100a83:	e8 20 1e 00 00       	call   1028a8 <cprintf>
	assert(freepages < mem_npage);	// can't have more free than total!
  100a88:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100a8b:	a1 b4 9f 10 00       	mov    0x109fb4,%eax
  100a90:	39 c2                	cmp    %eax,%edx
  100a92:	72 24                	jb     100ab8 <mem_check+0x98>
  100a94:	c7 44 24 0c 3b 33 10 	movl   $0x10333b,0xc(%esp)
  100a9b:	00 
  100a9c:	c7 44 24 08 46 32 10 	movl   $0x103246,0x8(%esp)
  100aa3:	00 
  100aa4:	c7 44 24 04 9a 00 00 	movl   $0x9a,0x4(%esp)
  100aab:	00 
  100aac:	c7 04 24 88 32 10 00 	movl   $0x103288,(%esp)
  100ab3:	e8 8c f8 ff ff       	call   100344 <debug_panic>
	assert(freepages > 16000);	// make sure it's in the right ballpark
  100ab8:	81 7d f0 80 3e 00 00 	cmpl   $0x3e80,-0x10(%ebp)
  100abf:	7f 24                	jg     100ae5 <mem_check+0xc5>
  100ac1:	c7 44 24 0c 51 33 10 	movl   $0x103351,0xc(%esp)
  100ac8:	00 
  100ac9:	c7 44 24 08 46 32 10 	movl   $0x103246,0x8(%esp)
  100ad0:	00 
  100ad1:	c7 44 24 04 9b 00 00 	movl   $0x9b,0x4(%esp)
  100ad8:	00 
  100ad9:	c7 04 24 88 32 10 00 	movl   $0x103288,(%esp)
  100ae0:	e8 5f f8 ff ff       	call   100344 <debug_panic>

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
  100ae5:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  100aec:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100aef:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100af2:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100af5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  100af8:	e8 df fe ff ff       	call   1009dc <mem_alloc>
  100afd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100b00:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100b04:	75 24                	jne    100b2a <mem_check+0x10a>
  100b06:	c7 44 24 0c 63 33 10 	movl   $0x103363,0xc(%esp)
  100b0d:	00 
  100b0e:	c7 44 24 08 46 32 10 	movl   $0x103246,0x8(%esp)
  100b15:	00 
  100b16:	c7 44 24 04 9f 00 00 	movl   $0x9f,0x4(%esp)
  100b1d:	00 
  100b1e:	c7 04 24 88 32 10 00 	movl   $0x103288,(%esp)
  100b25:	e8 1a f8 ff ff       	call   100344 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100b2a:	e8 ad fe ff ff       	call   1009dc <mem_alloc>
  100b2f:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100b32:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100b36:	75 24                	jne    100b5c <mem_check+0x13c>
  100b38:	c7 44 24 0c 6c 33 10 	movl   $0x10336c,0xc(%esp)
  100b3f:	00 
  100b40:	c7 44 24 08 46 32 10 	movl   $0x103246,0x8(%esp)
  100b47:	00 
  100b48:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  100b4f:	00 
  100b50:	c7 04 24 88 32 10 00 	movl   $0x103288,(%esp)
  100b57:	e8 e8 f7 ff ff       	call   100344 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100b5c:	e8 7b fe ff ff       	call   1009dc <mem_alloc>
  100b61:	89 45 ec             	mov    %eax,-0x14(%ebp)
  100b64:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  100b68:	75 24                	jne    100b8e <mem_check+0x16e>
  100b6a:	c7 44 24 0c 75 33 10 	movl   $0x103375,0xc(%esp)
  100b71:	00 
  100b72:	c7 44 24 08 46 32 10 	movl   $0x103246,0x8(%esp)
  100b79:	00 
  100b7a:	c7 44 24 04 a1 00 00 	movl   $0xa1,0x4(%esp)
  100b81:	00 
  100b82:	c7 04 24 88 32 10 00 	movl   $0x103288,(%esp)
  100b89:	e8 b6 f7 ff ff       	call   100344 <debug_panic>

	assert(pp0);
  100b8e:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100b92:	75 24                	jne    100bb8 <mem_check+0x198>
  100b94:	c7 44 24 0c 7e 33 10 	movl   $0x10337e,0xc(%esp)
  100b9b:	00 
  100b9c:	c7 44 24 08 46 32 10 	movl   $0x103246,0x8(%esp)
  100ba3:	00 
  100ba4:	c7 44 24 04 a3 00 00 	movl   $0xa3,0x4(%esp)
  100bab:	00 
  100bac:	c7 04 24 88 32 10 00 	movl   $0x103288,(%esp)
  100bb3:	e8 8c f7 ff ff       	call   100344 <debug_panic>
	assert(pp1 && pp1 != pp0);
  100bb8:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100bbc:	74 08                	je     100bc6 <mem_check+0x1a6>
  100bbe:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100bc1:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  100bc4:	75 24                	jne    100bea <mem_check+0x1ca>
  100bc6:	c7 44 24 0c 82 33 10 	movl   $0x103382,0xc(%esp)
  100bcd:	00 
  100bce:	c7 44 24 08 46 32 10 	movl   $0x103246,0x8(%esp)
  100bd5:	00 
  100bd6:	c7 44 24 04 a4 00 00 	movl   $0xa4,0x4(%esp)
  100bdd:	00 
  100bde:	c7 04 24 88 32 10 00 	movl   $0x103288,(%esp)
  100be5:	e8 5a f7 ff ff       	call   100344 <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  100bea:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  100bee:	74 10                	je     100c00 <mem_check+0x1e0>
  100bf0:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100bf3:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  100bf6:	74 08                	je     100c00 <mem_check+0x1e0>
  100bf8:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100bfb:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  100bfe:	75 24                	jne    100c24 <mem_check+0x204>
  100c00:	c7 44 24 0c 94 33 10 	movl   $0x103394,0xc(%esp)
  100c07:	00 
  100c08:	c7 44 24 08 46 32 10 	movl   $0x103246,0x8(%esp)
  100c0f:	00 
  100c10:	c7 44 24 04 a5 00 00 	movl   $0xa5,0x4(%esp)
  100c17:	00 
  100c18:	c7 04 24 88 32 10 00 	movl   $0x103288,(%esp)
  100c1f:	e8 20 f7 ff ff       	call   100344 <debug_panic>
        assert(mem_pi2phys(pp0) < mem_npage*PAGESIZE);
  100c24:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  100c27:	a1 bc 9f 10 00       	mov    0x109fbc,%eax
  100c2c:	89 d1                	mov    %edx,%ecx
  100c2e:	29 c1                	sub    %eax,%ecx
  100c30:	89 c8                	mov    %ecx,%eax
  100c32:	c1 f8 03             	sar    $0x3,%eax
  100c35:	c1 e0 0c             	shl    $0xc,%eax
  100c38:	8b 15 b4 9f 10 00    	mov    0x109fb4,%edx
  100c3e:	c1 e2 0c             	shl    $0xc,%edx
  100c41:	39 d0                	cmp    %edx,%eax
  100c43:	72 24                	jb     100c69 <mem_check+0x249>
  100c45:	c7 44 24 0c b4 33 10 	movl   $0x1033b4,0xc(%esp)
  100c4c:	00 
  100c4d:	c7 44 24 08 46 32 10 	movl   $0x103246,0x8(%esp)
  100c54:	00 
  100c55:	c7 44 24 04 a6 00 00 	movl   $0xa6,0x4(%esp)
  100c5c:	00 
  100c5d:	c7 04 24 88 32 10 00 	movl   $0x103288,(%esp)
  100c64:	e8 db f6 ff ff       	call   100344 <debug_panic>
        assert(mem_pi2phys(pp1) < mem_npage*PAGESIZE);
  100c69:	8b 55 e8             	mov    -0x18(%ebp),%edx
  100c6c:	a1 bc 9f 10 00       	mov    0x109fbc,%eax
  100c71:	89 d1                	mov    %edx,%ecx
  100c73:	29 c1                	sub    %eax,%ecx
  100c75:	89 c8                	mov    %ecx,%eax
  100c77:	c1 f8 03             	sar    $0x3,%eax
  100c7a:	c1 e0 0c             	shl    $0xc,%eax
  100c7d:	8b 15 b4 9f 10 00    	mov    0x109fb4,%edx
  100c83:	c1 e2 0c             	shl    $0xc,%edx
  100c86:	39 d0                	cmp    %edx,%eax
  100c88:	72 24                	jb     100cae <mem_check+0x28e>
  100c8a:	c7 44 24 0c dc 33 10 	movl   $0x1033dc,0xc(%esp)
  100c91:	00 
  100c92:	c7 44 24 08 46 32 10 	movl   $0x103246,0x8(%esp)
  100c99:	00 
  100c9a:	c7 44 24 04 a7 00 00 	movl   $0xa7,0x4(%esp)
  100ca1:	00 
  100ca2:	c7 04 24 88 32 10 00 	movl   $0x103288,(%esp)
  100ca9:	e8 96 f6 ff ff       	call   100344 <debug_panic>
        assert(mem_pi2phys(pp2) < mem_npage*PAGESIZE);
  100cae:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100cb1:	a1 bc 9f 10 00       	mov    0x109fbc,%eax
  100cb6:	89 d1                	mov    %edx,%ecx
  100cb8:	29 c1                	sub    %eax,%ecx
  100cba:	89 c8                	mov    %ecx,%eax
  100cbc:	c1 f8 03             	sar    $0x3,%eax
  100cbf:	c1 e0 0c             	shl    $0xc,%eax
  100cc2:	8b 15 b4 9f 10 00    	mov    0x109fb4,%edx
  100cc8:	c1 e2 0c             	shl    $0xc,%edx
  100ccb:	39 d0                	cmp    %edx,%eax
  100ccd:	72 24                	jb     100cf3 <mem_check+0x2d3>
  100ccf:	c7 44 24 0c 04 34 10 	movl   $0x103404,0xc(%esp)
  100cd6:	00 
  100cd7:	c7 44 24 08 46 32 10 	movl   $0x103246,0x8(%esp)
  100cde:	00 
  100cdf:	c7 44 24 04 a8 00 00 	movl   $0xa8,0x4(%esp)
  100ce6:	00 
  100ce7:	c7 04 24 88 32 10 00 	movl   $0x103288,(%esp)
  100cee:	e8 51 f6 ff ff       	call   100344 <debug_panic>

	// temporarily steal the rest of the free pages
	fl = mem_freelist;
  100cf3:	a1 b0 9f 10 00       	mov    0x109fb0,%eax
  100cf8:	89 45 e0             	mov    %eax,-0x20(%ebp)
	mem_freelist = 0;
  100cfb:	c7 05 b0 9f 10 00 00 	movl   $0x0,0x109fb0
  100d02:	00 00 00 

	// should be no free memory
	assert(mem_alloc() == 0);
  100d05:	e8 d2 fc ff ff       	call   1009dc <mem_alloc>
  100d0a:	85 c0                	test   %eax,%eax
  100d0c:	74 24                	je     100d32 <mem_check+0x312>
  100d0e:	c7 44 24 0c 2a 34 10 	movl   $0x10342a,0xc(%esp)
  100d15:	00 
  100d16:	c7 44 24 08 46 32 10 	movl   $0x103246,0x8(%esp)
  100d1d:	00 
  100d1e:	c7 44 24 04 af 00 00 	movl   $0xaf,0x4(%esp)
  100d25:	00 
  100d26:	c7 04 24 88 32 10 00 	movl   $0x103288,(%esp)
  100d2d:	e8 12 f6 ff ff       	call   100344 <debug_panic>

        // free and re-allocate?
        mem_free(pp0);
  100d32:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100d35:	89 04 24             	mov    %eax,(%esp)
  100d38:	e8 c1 fc ff ff       	call   1009fe <mem_free>
        mem_free(pp1);
  100d3d:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100d40:	89 04 24             	mov    %eax,(%esp)
  100d43:	e8 b6 fc ff ff       	call   1009fe <mem_free>
        mem_free(pp2);
  100d48:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100d4b:	89 04 24             	mov    %eax,(%esp)
  100d4e:	e8 ab fc ff ff       	call   1009fe <mem_free>
	pp0 = pp1 = pp2 = 0;
  100d53:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  100d5a:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100d5d:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100d60:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100d63:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  100d66:	e8 71 fc ff ff       	call   1009dc <mem_alloc>
  100d6b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100d6e:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100d72:	75 24                	jne    100d98 <mem_check+0x378>
  100d74:	c7 44 24 0c 63 33 10 	movl   $0x103363,0xc(%esp)
  100d7b:	00 
  100d7c:	c7 44 24 08 46 32 10 	movl   $0x103246,0x8(%esp)
  100d83:	00 
  100d84:	c7 44 24 04 b6 00 00 	movl   $0xb6,0x4(%esp)
  100d8b:	00 
  100d8c:	c7 04 24 88 32 10 00 	movl   $0x103288,(%esp)
  100d93:	e8 ac f5 ff ff       	call   100344 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100d98:	e8 3f fc ff ff       	call   1009dc <mem_alloc>
  100d9d:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100da0:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100da4:	75 24                	jne    100dca <mem_check+0x3aa>
  100da6:	c7 44 24 0c 6c 33 10 	movl   $0x10336c,0xc(%esp)
  100dad:	00 
  100dae:	c7 44 24 08 46 32 10 	movl   $0x103246,0x8(%esp)
  100db5:	00 
  100db6:	c7 44 24 04 b7 00 00 	movl   $0xb7,0x4(%esp)
  100dbd:	00 
  100dbe:	c7 04 24 88 32 10 00 	movl   $0x103288,(%esp)
  100dc5:	e8 7a f5 ff ff       	call   100344 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100dca:	e8 0d fc ff ff       	call   1009dc <mem_alloc>
  100dcf:	89 45 ec             	mov    %eax,-0x14(%ebp)
  100dd2:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  100dd6:	75 24                	jne    100dfc <mem_check+0x3dc>
  100dd8:	c7 44 24 0c 75 33 10 	movl   $0x103375,0xc(%esp)
  100ddf:	00 
  100de0:	c7 44 24 08 46 32 10 	movl   $0x103246,0x8(%esp)
  100de7:	00 
  100de8:	c7 44 24 04 b8 00 00 	movl   $0xb8,0x4(%esp)
  100def:	00 
  100df0:	c7 04 24 88 32 10 00 	movl   $0x103288,(%esp)
  100df7:	e8 48 f5 ff ff       	call   100344 <debug_panic>
	assert(pp0);
  100dfc:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100e00:	75 24                	jne    100e26 <mem_check+0x406>
  100e02:	c7 44 24 0c 7e 33 10 	movl   $0x10337e,0xc(%esp)
  100e09:	00 
  100e0a:	c7 44 24 08 46 32 10 	movl   $0x103246,0x8(%esp)
  100e11:	00 
  100e12:	c7 44 24 04 b9 00 00 	movl   $0xb9,0x4(%esp)
  100e19:	00 
  100e1a:	c7 04 24 88 32 10 00 	movl   $0x103288,(%esp)
  100e21:	e8 1e f5 ff ff       	call   100344 <debug_panic>
	assert(pp1 && pp1 != pp0);
  100e26:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100e2a:	74 08                	je     100e34 <mem_check+0x414>
  100e2c:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100e2f:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  100e32:	75 24                	jne    100e58 <mem_check+0x438>
  100e34:	c7 44 24 0c 82 33 10 	movl   $0x103382,0xc(%esp)
  100e3b:	00 
  100e3c:	c7 44 24 08 46 32 10 	movl   $0x103246,0x8(%esp)
  100e43:	00 
  100e44:	c7 44 24 04 ba 00 00 	movl   $0xba,0x4(%esp)
  100e4b:	00 
  100e4c:	c7 04 24 88 32 10 00 	movl   $0x103288,(%esp)
  100e53:	e8 ec f4 ff ff       	call   100344 <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  100e58:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  100e5c:	74 10                	je     100e6e <mem_check+0x44e>
  100e5e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100e61:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  100e64:	74 08                	je     100e6e <mem_check+0x44e>
  100e66:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100e69:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  100e6c:	75 24                	jne    100e92 <mem_check+0x472>
  100e6e:	c7 44 24 0c 94 33 10 	movl   $0x103394,0xc(%esp)
  100e75:	00 
  100e76:	c7 44 24 08 46 32 10 	movl   $0x103246,0x8(%esp)
  100e7d:	00 
  100e7e:	c7 44 24 04 bb 00 00 	movl   $0xbb,0x4(%esp)
  100e85:	00 
  100e86:	c7 04 24 88 32 10 00 	movl   $0x103288,(%esp)
  100e8d:	e8 b2 f4 ff ff       	call   100344 <debug_panic>
	assert(mem_alloc() == 0);
  100e92:	e8 45 fb ff ff       	call   1009dc <mem_alloc>
  100e97:	85 c0                	test   %eax,%eax
  100e99:	74 24                	je     100ebf <mem_check+0x49f>
  100e9b:	c7 44 24 0c 2a 34 10 	movl   $0x10342a,0xc(%esp)
  100ea2:	00 
  100ea3:	c7 44 24 08 46 32 10 	movl   $0x103246,0x8(%esp)
  100eaa:	00 
  100eab:	c7 44 24 04 bc 00 00 	movl   $0xbc,0x4(%esp)
  100eb2:	00 
  100eb3:	c7 04 24 88 32 10 00 	movl   $0x103288,(%esp)
  100eba:	e8 85 f4 ff ff       	call   100344 <debug_panic>

	// give free list back
	mem_freelist = fl;
  100ebf:	8b 45 e0             	mov    -0x20(%ebp),%eax
  100ec2:	a3 b0 9f 10 00       	mov    %eax,0x109fb0

	// free the pages we took
	mem_free(pp0);
  100ec7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100eca:	89 04 24             	mov    %eax,(%esp)
  100ecd:	e8 2c fb ff ff       	call   1009fe <mem_free>
	mem_free(pp1);
  100ed2:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100ed5:	89 04 24             	mov    %eax,(%esp)
  100ed8:	e8 21 fb ff ff       	call   1009fe <mem_free>
	mem_free(pp2);
  100edd:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100ee0:	89 04 24             	mov    %eax,(%esp)
  100ee3:	e8 16 fb ff ff       	call   1009fe <mem_free>

	cprintf("mem_check() succeeded!\n");
  100ee8:	c7 04 24 3b 34 10 00 	movl   $0x10343b,(%esp)
  100eef:	e8 b4 19 00 00       	call   1028a8 <cprintf>
}
  100ef4:	c9                   	leave  
  100ef5:	c3                   	ret    
  100ef6:	90                   	nop
  100ef7:	90                   	nop

00100ef8 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  100ef8:	55                   	push   %ebp
  100ef9:	89 e5                	mov    %esp,%ebp
  100efb:	53                   	push   %ebx
  100efc:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100eff:	89 e3                	mov    %esp,%ebx
  100f01:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  100f04:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  100f07:	89 45 f4             	mov    %eax,-0xc(%ebp)
  100f0a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100f0d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100f12:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  100f15:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100f18:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  100f1e:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  100f23:	74 24                	je     100f49 <cpu_cur+0x51>
  100f25:	c7 44 24 0c 53 34 10 	movl   $0x103453,0xc(%esp)
  100f2c:	00 
  100f2d:	c7 44 24 08 69 34 10 	movl   $0x103469,0x8(%esp)
  100f34:	00 
  100f35:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  100f3c:	00 
  100f3d:	c7 04 24 7e 34 10 00 	movl   $0x10347e,(%esp)
  100f44:	e8 fb f3 ff ff       	call   100344 <debug_panic>
	return c;
  100f49:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  100f4c:	83 c4 24             	add    $0x24,%esp
  100f4f:	5b                   	pop    %ebx
  100f50:	5d                   	pop    %ebp
  100f51:	c3                   	ret    

00100f52 <cpu_init>:
	magic: CPU_MAGIC
};


void cpu_init()
{
  100f52:	55                   	push   %ebp
  100f53:	89 e5                	mov    %esp,%ebp
  100f55:	53                   	push   %ebx
  100f56:	83 ec 14             	sub    $0x14,%esp
	cpu *c = cpu_cur();
  100f59:	e8 9a ff ff ff       	call   100ef8 <cpu_cur>
  100f5e:	89 45 f4             	mov    %eax,-0xc(%ebp)

	c->gdt[CPU_GDT_TSS >> 3] = SEGDESC16(0, STS_T32A, (uint32_t)(&c->tss), sizeof(c->tss)-1, 0);
  100f61:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100f64:	83 c0 38             	add    $0x38,%eax
  100f67:	89 c3                	mov    %eax,%ebx
  100f69:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100f6c:	83 c0 38             	add    $0x38,%eax
  100f6f:	c1 e8 10             	shr    $0x10,%eax
  100f72:	89 c1                	mov    %eax,%ecx
  100f74:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100f77:	83 c0 38             	add    $0x38,%eax
  100f7a:	c1 e8 18             	shr    $0x18,%eax
  100f7d:	89 c2                	mov    %eax,%edx
  100f7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100f82:	66 c7 40 30 67 00    	movw   $0x67,0x30(%eax)
  100f88:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100f8b:	66 89 58 32          	mov    %bx,0x32(%eax)
  100f8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100f92:	88 48 34             	mov    %cl,0x34(%eax)
  100f95:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100f98:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  100f9c:	83 e1 f0             	and    $0xfffffff0,%ecx
  100f9f:	83 c9 09             	or     $0x9,%ecx
  100fa2:	88 48 35             	mov    %cl,0x35(%eax)
  100fa5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100fa8:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  100fac:	83 e1 ef             	and    $0xffffffef,%ecx
  100faf:	88 48 35             	mov    %cl,0x35(%eax)
  100fb2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100fb5:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  100fb9:	83 e1 9f             	and    $0xffffff9f,%ecx
  100fbc:	88 48 35             	mov    %cl,0x35(%eax)
  100fbf:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100fc2:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  100fc6:	83 c9 80             	or     $0xffffff80,%ecx
  100fc9:	88 48 35             	mov    %cl,0x35(%eax)
  100fcc:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100fcf:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  100fd3:	83 e1 f0             	and    $0xfffffff0,%ecx
  100fd6:	88 48 36             	mov    %cl,0x36(%eax)
  100fd9:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100fdc:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  100fe0:	83 e1 ef             	and    $0xffffffef,%ecx
  100fe3:	88 48 36             	mov    %cl,0x36(%eax)
  100fe6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100fe9:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  100fed:	83 e1 df             	and    $0xffffffdf,%ecx
  100ff0:	88 48 36             	mov    %cl,0x36(%eax)
  100ff3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100ff6:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  100ffa:	83 c9 40             	or     $0x40,%ecx
  100ffd:	88 48 36             	mov    %cl,0x36(%eax)
  101000:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101003:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  101007:	83 e1 7f             	and    $0x7f,%ecx
  10100a:	88 48 36             	mov    %cl,0x36(%eax)
  10100d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101010:	88 50 37             	mov    %dl,0x37(%eax)
	c->tss.ts_esp0 = (uint32_t)c->kstackhi;
  101013:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101016:	05 00 10 00 00       	add    $0x1000,%eax
  10101b:	89 c2                	mov    %eax,%edx
  10101d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101020:	89 50 3c             	mov    %edx,0x3c(%eax)
	c->tss.ts_ss0 = CPU_GDT_KDATA;
  101023:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101026:	66 c7 40 40 10 00    	movw   $0x10,0x40(%eax)

	// Load the GDT
	struct pseudodesc gdt_pd = {
  10102c:	66 c7 45 ec 37 00    	movw   $0x37,-0x14(%ebp)
		sizeof(c->gdt) - 1, (uint32_t) c->gdt };
  101032:	8b 45 f4             	mov    -0xc(%ebp),%eax
	c->gdt[CPU_GDT_TSS >> 3] = SEGDESC16(0, STS_T32A, (uint32_t)(&c->tss), sizeof(c->tss)-1, 0);
	c->tss.ts_esp0 = (uint32_t)c->kstackhi;
	c->tss.ts_ss0 = CPU_GDT_KDATA;

	// Load the GDT
	struct pseudodesc gdt_pd = {
  101035:	89 45 ee             	mov    %eax,-0x12(%ebp)
		sizeof(c->gdt) - 1, (uint32_t) c->gdt };
	asm volatile("lgdt %0" : : "m" (gdt_pd));
  101038:	0f 01 55 ec          	lgdtl  -0x14(%ebp)

	// Reload all segment registers.
	asm volatile("movw %%ax,%%gs" :: "a" (CPU_GDT_UDATA|3));
  10103c:	b8 23 00 00 00       	mov    $0x23,%eax
  101041:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (CPU_GDT_UDATA|3));
  101043:	b8 23 00 00 00       	mov    $0x23,%eax
  101048:	8e e0                	mov    %eax,%fs
	asm volatile("movw %%ax,%%es" :: "a" (CPU_GDT_KDATA));
  10104a:	b8 10 00 00 00       	mov    $0x10,%eax
  10104f:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (CPU_GDT_KDATA));
  101051:	b8 10 00 00 00       	mov    $0x10,%eax
  101056:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (CPU_GDT_KDATA));
  101058:	b8 10 00 00 00       	mov    $0x10,%eax
  10105d:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (CPU_GDT_KCODE)); // reload CS
  10105f:	ea 66 10 10 00 08 00 	ljmp   $0x8,$0x101066

	// We don't need an LDT.
	asm volatile("lldt %%ax" :: "a" (0));
  101066:	b8 00 00 00 00       	mov    $0x0,%eax
  10106b:	0f 00 d0             	lldt   %ax
  10106e:	66 c7 45 f2 30 00    	movw   $0x30,-0xe(%ebp)
}

static gcc_inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
  101074:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
  101078:	0f 00 d8             	ltr    %ax

	ltr(CPU_GDT_TSS);
}
  10107b:	83 c4 14             	add    $0x14,%esp
  10107e:	5b                   	pop    %ebx
  10107f:	5d                   	pop    %ebp
  101080:	c3                   	ret    
  101081:	90                   	nop
  101082:	90                   	nop
  101083:	90                   	nop

00101084 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  101084:	55                   	push   %ebp
  101085:	89 e5                	mov    %esp,%ebp
  101087:	53                   	push   %ebx
  101088:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10108b:	89 e3                	mov    %esp,%ebx
  10108d:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  101090:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  101093:	89 45 f4             	mov    %eax,-0xc(%ebp)
  101096:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101099:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10109e:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  1010a1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1010a4:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  1010aa:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1010af:	74 24                	je     1010d5 <cpu_cur+0x51>
  1010b1:	c7 44 24 0c a0 34 10 	movl   $0x1034a0,0xc(%esp)
  1010b8:	00 
  1010b9:	c7 44 24 08 b6 34 10 	movl   $0x1034b6,0x8(%esp)
  1010c0:	00 
  1010c1:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  1010c8:	00 
  1010c9:	c7 04 24 cb 34 10 00 	movl   $0x1034cb,(%esp)
  1010d0:	e8 6f f2 ff ff       	call   100344 <debug_panic>
	return c;
  1010d5:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  1010d8:	83 c4 24             	add    $0x24,%esp
  1010db:	5b                   	pop    %ebx
  1010dc:	5d                   	pop    %ebp
  1010dd:	c3                   	ret    

001010de <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  1010de:	55                   	push   %ebp
  1010df:	89 e5                	mov    %esp,%ebp
  1010e1:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  1010e4:	e8 9b ff ff ff       	call   101084 <cpu_cur>
  1010e9:	3d 00 70 10 00       	cmp    $0x107000,%eax
  1010ee:	0f 94 c0             	sete   %al
  1010f1:	0f b6 c0             	movzbl %al,%eax
}
  1010f4:	c9                   	leave  
  1010f5:	c3                   	ret    

001010f6 <trap_init_idt>:
extern int vectors[];


static void
trap_init_idt(void)
{
  1010f6:	55                   	push   %ebp
  1010f7:	89 e5                	mov    %esp,%ebp
  1010f9:	83 ec 10             	sub    $0x10,%esp
	extern segdesc gdt[];

	//panic("trap_init() not implemented.");

	int i;
	for (i=0; i<256; i++) {
  1010fc:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  101103:	e9 c3 00 00 00       	jmp    1011cb <trap_init_idt+0xd5>
		SETGATE(idt[i], 0, CPU_GDT_KCODE, vectors[i], 0); //CPU_GDT_KCODE is 0x08
  101108:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10110b:	8b 04 85 08 80 10 00 	mov    0x108008(,%eax,4),%eax
  101112:	89 c2                	mov    %eax,%edx
  101114:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101117:	66 89 14 c5 a0 97 10 	mov    %dx,0x1097a0(,%eax,8)
  10111e:	00 
  10111f:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101122:	66 c7 04 c5 a2 97 10 	movw   $0x8,0x1097a2(,%eax,8)
  101129:	00 08 00 
  10112c:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10112f:	0f b6 14 c5 a4 97 10 	movzbl 0x1097a4(,%eax,8),%edx
  101136:	00 
  101137:	83 e2 e0             	and    $0xffffffe0,%edx
  10113a:	88 14 c5 a4 97 10 00 	mov    %dl,0x1097a4(,%eax,8)
  101141:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101144:	0f b6 14 c5 a4 97 10 	movzbl 0x1097a4(,%eax,8),%edx
  10114b:	00 
  10114c:	83 e2 1f             	and    $0x1f,%edx
  10114f:	88 14 c5 a4 97 10 00 	mov    %dl,0x1097a4(,%eax,8)
  101156:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101159:	0f b6 14 c5 a5 97 10 	movzbl 0x1097a5(,%eax,8),%edx
  101160:	00 
  101161:	83 e2 f0             	and    $0xfffffff0,%edx
  101164:	83 ca 0e             	or     $0xe,%edx
  101167:	88 14 c5 a5 97 10 00 	mov    %dl,0x1097a5(,%eax,8)
  10116e:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101171:	0f b6 14 c5 a5 97 10 	movzbl 0x1097a5(,%eax,8),%edx
  101178:	00 
  101179:	83 e2 ef             	and    $0xffffffef,%edx
  10117c:	88 14 c5 a5 97 10 00 	mov    %dl,0x1097a5(,%eax,8)
  101183:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101186:	0f b6 14 c5 a5 97 10 	movzbl 0x1097a5(,%eax,8),%edx
  10118d:	00 
  10118e:	83 e2 9f             	and    $0xffffff9f,%edx
  101191:	88 14 c5 a5 97 10 00 	mov    %dl,0x1097a5(,%eax,8)
  101198:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10119b:	0f b6 14 c5 a5 97 10 	movzbl 0x1097a5(,%eax,8),%edx
  1011a2:	00 
  1011a3:	83 ca 80             	or     $0xffffff80,%edx
  1011a6:	88 14 c5 a5 97 10 00 	mov    %dl,0x1097a5(,%eax,8)
  1011ad:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1011b0:	8b 04 85 08 80 10 00 	mov    0x108008(,%eax,4),%eax
  1011b7:	c1 e8 10             	shr    $0x10,%eax
  1011ba:	89 c2                	mov    %eax,%edx
  1011bc:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1011bf:	66 89 14 c5 a6 97 10 	mov    %dx,0x1097a6(,%eax,8)
  1011c6:	00 
	extern segdesc gdt[];

	//panic("trap_init() not implemented.");

	int i;
	for (i=0; i<256; i++) {
  1011c7:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  1011cb:	81 7d fc ff 00 00 00 	cmpl   $0xff,-0x4(%ebp)
  1011d2:	0f 8e 30 ff ff ff    	jle    101108 <trap_init_idt+0x12>
		SETGATE(idt[i], 0, CPU_GDT_KCODE, vectors[i], 0); //CPU_GDT_KCODE is 0x08
	}
	SETGATE(idt[3], 0, CPU_GDT_KCODE, vectors[3], 3); //T_BRKPT
  1011d8:	a1 14 80 10 00       	mov    0x108014,%eax
  1011dd:	66 a3 b8 97 10 00    	mov    %ax,0x1097b8
  1011e3:	66 c7 05 ba 97 10 00 	movw   $0x8,0x1097ba
  1011ea:	08 00 
  1011ec:	0f b6 05 bc 97 10 00 	movzbl 0x1097bc,%eax
  1011f3:	83 e0 e0             	and    $0xffffffe0,%eax
  1011f6:	a2 bc 97 10 00       	mov    %al,0x1097bc
  1011fb:	0f b6 05 bc 97 10 00 	movzbl 0x1097bc,%eax
  101202:	83 e0 1f             	and    $0x1f,%eax
  101205:	a2 bc 97 10 00       	mov    %al,0x1097bc
  10120a:	0f b6 05 bd 97 10 00 	movzbl 0x1097bd,%eax
  101211:	83 e0 f0             	and    $0xfffffff0,%eax
  101214:	83 c8 0e             	or     $0xe,%eax
  101217:	a2 bd 97 10 00       	mov    %al,0x1097bd
  10121c:	0f b6 05 bd 97 10 00 	movzbl 0x1097bd,%eax
  101223:	83 e0 ef             	and    $0xffffffef,%eax
  101226:	a2 bd 97 10 00       	mov    %al,0x1097bd
  10122b:	0f b6 05 bd 97 10 00 	movzbl 0x1097bd,%eax
  101232:	83 c8 60             	or     $0x60,%eax
  101235:	a2 bd 97 10 00       	mov    %al,0x1097bd
  10123a:	0f b6 05 bd 97 10 00 	movzbl 0x1097bd,%eax
  101241:	83 c8 80             	or     $0xffffff80,%eax
  101244:	a2 bd 97 10 00       	mov    %al,0x1097bd
  101249:	a1 14 80 10 00       	mov    0x108014,%eax
  10124e:	c1 e8 10             	shr    $0x10,%eax
  101251:	66 a3 be 97 10 00    	mov    %ax,0x1097be
	SETGATE(idt[4], 0, CPU_GDT_KCODE, vectors[4], 3); //T_OFLOW
  101257:	a1 18 80 10 00       	mov    0x108018,%eax
  10125c:	66 a3 c0 97 10 00    	mov    %ax,0x1097c0
  101262:	66 c7 05 c2 97 10 00 	movw   $0x8,0x1097c2
  101269:	08 00 
  10126b:	0f b6 05 c4 97 10 00 	movzbl 0x1097c4,%eax
  101272:	83 e0 e0             	and    $0xffffffe0,%eax
  101275:	a2 c4 97 10 00       	mov    %al,0x1097c4
  10127a:	0f b6 05 c4 97 10 00 	movzbl 0x1097c4,%eax
  101281:	83 e0 1f             	and    $0x1f,%eax
  101284:	a2 c4 97 10 00       	mov    %al,0x1097c4
  101289:	0f b6 05 c5 97 10 00 	movzbl 0x1097c5,%eax
  101290:	83 e0 f0             	and    $0xfffffff0,%eax
  101293:	83 c8 0e             	or     $0xe,%eax
  101296:	a2 c5 97 10 00       	mov    %al,0x1097c5
  10129b:	0f b6 05 c5 97 10 00 	movzbl 0x1097c5,%eax
  1012a2:	83 e0 ef             	and    $0xffffffef,%eax
  1012a5:	a2 c5 97 10 00       	mov    %al,0x1097c5
  1012aa:	0f b6 05 c5 97 10 00 	movzbl 0x1097c5,%eax
  1012b1:	83 c8 60             	or     $0x60,%eax
  1012b4:	a2 c5 97 10 00       	mov    %al,0x1097c5
  1012b9:	0f b6 05 c5 97 10 00 	movzbl 0x1097c5,%eax
  1012c0:	83 c8 80             	or     $0xffffff80,%eax
  1012c3:	a2 c5 97 10 00       	mov    %al,0x1097c5
  1012c8:	a1 18 80 10 00       	mov    0x108018,%eax
  1012cd:	c1 e8 10             	shr    $0x10,%eax
  1012d0:	66 a3 c6 97 10 00    	mov    %ax,0x1097c6

}
  1012d6:	c9                   	leave  
  1012d7:	c3                   	ret    

001012d8 <trap_init>:

void
trap_init(void)
{
  1012d8:	55                   	push   %ebp
  1012d9:	89 e5                	mov    %esp,%ebp
  1012db:	83 ec 08             	sub    $0x8,%esp
	// The first time we get called on the bootstrap processor,
	// initialize the IDT.  Other CPUs will share the same IDT.
	if (cpu_onboot())
  1012de:	e8 fb fd ff ff       	call   1010de <cpu_onboot>
  1012e3:	85 c0                	test   %eax,%eax
  1012e5:	74 05                	je     1012ec <trap_init+0x14>
		trap_init_idt();
  1012e7:	e8 0a fe ff ff       	call   1010f6 <trap_init_idt>

	// Load the IDT into this processor's IDT register.
	asm volatile("lidt %0" : : "m" (idt_pd));
  1012ec:	0f 01 1d 00 80 10 00 	lidtl  0x108000

	// Check for the correct IDT and trap handler operation.
	if (cpu_onboot())
  1012f3:	e8 e6 fd ff ff       	call   1010de <cpu_onboot>
  1012f8:	85 c0                	test   %eax,%eax
  1012fa:	74 05                	je     101301 <trap_init+0x29>
		trap_check_kernel();
  1012fc:	e8 82 02 00 00       	call   101583 <trap_check_kernel>
}
  101301:	c9                   	leave  
  101302:	c3                   	ret    

00101303 <trap_name>:

const char *trap_name(int trapno)
{
  101303:	55                   	push   %ebp
  101304:	89 e5                	mov    %esp,%ebp
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
  101306:	8b 45 08             	mov    0x8(%ebp),%eax
  101309:	83 f8 13             	cmp    $0x13,%eax
  10130c:	77 0c                	ja     10131a <trap_name+0x17>
		return excnames[trapno];
  10130e:	8b 45 08             	mov    0x8(%ebp),%eax
  101311:	8b 04 85 a0 38 10 00 	mov    0x1038a0(,%eax,4),%eax
  101318:	eb 25                	jmp    10133f <trap_name+0x3c>
	if (trapno == T_SYSCALL)
  10131a:	83 7d 08 30          	cmpl   $0x30,0x8(%ebp)
  10131e:	75 07                	jne    101327 <trap_name+0x24>
		return "System call";
  101320:	b8 d8 34 10 00       	mov    $0x1034d8,%eax
  101325:	eb 18                	jmp    10133f <trap_name+0x3c>
	if (trapno >= T_IRQ0 && trapno < T_IRQ0 + 16)
  101327:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
  10132b:	7e 0d                	jle    10133a <trap_name+0x37>
  10132d:	83 7d 08 2f          	cmpl   $0x2f,0x8(%ebp)
  101331:	7f 07                	jg     10133a <trap_name+0x37>
		return "Hardware Interrupt";
  101333:	b8 e4 34 10 00       	mov    $0x1034e4,%eax
  101338:	eb 05                	jmp    10133f <trap_name+0x3c>
	return "(unknown trap)";
  10133a:	b8 f7 34 10 00       	mov    $0x1034f7,%eax
}
  10133f:	5d                   	pop    %ebp
  101340:	c3                   	ret    

00101341 <trap_print_regs>:

void
trap_print_regs(pushregs *regs)
{
  101341:	55                   	push   %ebp
  101342:	89 e5                	mov    %esp,%ebp
  101344:	83 ec 18             	sub    $0x18,%esp
	cprintf("  edi  0x%08x\n", regs->edi);
  101347:	8b 45 08             	mov    0x8(%ebp),%eax
  10134a:	8b 00                	mov    (%eax),%eax
  10134c:	89 44 24 04          	mov    %eax,0x4(%esp)
  101350:	c7 04 24 06 35 10 00 	movl   $0x103506,(%esp)
  101357:	e8 4c 15 00 00       	call   1028a8 <cprintf>
	cprintf("  esi  0x%08x\n", regs->esi);
  10135c:	8b 45 08             	mov    0x8(%ebp),%eax
  10135f:	8b 40 04             	mov    0x4(%eax),%eax
  101362:	89 44 24 04          	mov    %eax,0x4(%esp)
  101366:	c7 04 24 15 35 10 00 	movl   $0x103515,(%esp)
  10136d:	e8 36 15 00 00       	call   1028a8 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->ebp);
  101372:	8b 45 08             	mov    0x8(%ebp),%eax
  101375:	8b 40 08             	mov    0x8(%eax),%eax
  101378:	89 44 24 04          	mov    %eax,0x4(%esp)
  10137c:	c7 04 24 24 35 10 00 	movl   $0x103524,(%esp)
  101383:	e8 20 15 00 00       	call   1028a8 <cprintf>
//	cprintf("  oesp 0x%08x\n", regs->oesp);	don't print - useless
	cprintf("  ebx  0x%08x\n", regs->ebx);
  101388:	8b 45 08             	mov    0x8(%ebp),%eax
  10138b:	8b 40 10             	mov    0x10(%eax),%eax
  10138e:	89 44 24 04          	mov    %eax,0x4(%esp)
  101392:	c7 04 24 33 35 10 00 	movl   $0x103533,(%esp)
  101399:	e8 0a 15 00 00       	call   1028a8 <cprintf>
	cprintf("  edx  0x%08x\n", regs->edx);
  10139e:	8b 45 08             	mov    0x8(%ebp),%eax
  1013a1:	8b 40 14             	mov    0x14(%eax),%eax
  1013a4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1013a8:	c7 04 24 42 35 10 00 	movl   $0x103542,(%esp)
  1013af:	e8 f4 14 00 00       	call   1028a8 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->ecx);
  1013b4:	8b 45 08             	mov    0x8(%ebp),%eax
  1013b7:	8b 40 18             	mov    0x18(%eax),%eax
  1013ba:	89 44 24 04          	mov    %eax,0x4(%esp)
  1013be:	c7 04 24 51 35 10 00 	movl   $0x103551,(%esp)
  1013c5:	e8 de 14 00 00       	call   1028a8 <cprintf>
	cprintf("  eax  0x%08x\n", regs->eax);
  1013ca:	8b 45 08             	mov    0x8(%ebp),%eax
  1013cd:	8b 40 1c             	mov    0x1c(%eax),%eax
  1013d0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1013d4:	c7 04 24 60 35 10 00 	movl   $0x103560,(%esp)
  1013db:	e8 c8 14 00 00       	call   1028a8 <cprintf>
}
  1013e0:	c9                   	leave  
  1013e1:	c3                   	ret    

001013e2 <trap_print>:

void
trap_print(trapframe *tf)
{
  1013e2:	55                   	push   %ebp
  1013e3:	89 e5                	mov    %esp,%ebp
  1013e5:	83 ec 18             	sub    $0x18,%esp
	cprintf("TRAP frame at %p\n", tf);
  1013e8:	8b 45 08             	mov    0x8(%ebp),%eax
  1013eb:	89 44 24 04          	mov    %eax,0x4(%esp)
  1013ef:	c7 04 24 6f 35 10 00 	movl   $0x10356f,(%esp)
  1013f6:	e8 ad 14 00 00       	call   1028a8 <cprintf>
	trap_print_regs(&tf->regs);
  1013fb:	8b 45 08             	mov    0x8(%ebp),%eax
  1013fe:	89 04 24             	mov    %eax,(%esp)
  101401:	e8 3b ff ff ff       	call   101341 <trap_print_regs>
	cprintf("  es   0x----%04x\n", tf->es);
  101406:	8b 45 08             	mov    0x8(%ebp),%eax
  101409:	0f b7 40 28          	movzwl 0x28(%eax),%eax
  10140d:	0f b7 c0             	movzwl %ax,%eax
  101410:	89 44 24 04          	mov    %eax,0x4(%esp)
  101414:	c7 04 24 81 35 10 00 	movl   $0x103581,(%esp)
  10141b:	e8 88 14 00 00       	call   1028a8 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->ds);
  101420:	8b 45 08             	mov    0x8(%ebp),%eax
  101423:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  101427:	0f b7 c0             	movzwl %ax,%eax
  10142a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10142e:	c7 04 24 94 35 10 00 	movl   $0x103594,(%esp)
  101435:	e8 6e 14 00 00       	call   1028a8 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->trapno, trap_name(tf->trapno));
  10143a:	8b 45 08             	mov    0x8(%ebp),%eax
  10143d:	8b 40 30             	mov    0x30(%eax),%eax
  101440:	89 04 24             	mov    %eax,(%esp)
  101443:	e8 bb fe ff ff       	call   101303 <trap_name>
  101448:	8b 55 08             	mov    0x8(%ebp),%edx
  10144b:	8b 52 30             	mov    0x30(%edx),%edx
  10144e:	89 44 24 08          	mov    %eax,0x8(%esp)
  101452:	89 54 24 04          	mov    %edx,0x4(%esp)
  101456:	c7 04 24 a7 35 10 00 	movl   $0x1035a7,(%esp)
  10145d:	e8 46 14 00 00       	call   1028a8 <cprintf>
	cprintf("  err  0x%08x\n", tf->err);
  101462:	8b 45 08             	mov    0x8(%ebp),%eax
  101465:	8b 40 34             	mov    0x34(%eax),%eax
  101468:	89 44 24 04          	mov    %eax,0x4(%esp)
  10146c:	c7 04 24 b9 35 10 00 	movl   $0x1035b9,(%esp)
  101473:	e8 30 14 00 00       	call   1028a8 <cprintf>
	cprintf("  eip  0x%08x\n", tf->eip);
  101478:	8b 45 08             	mov    0x8(%ebp),%eax
  10147b:	8b 40 38             	mov    0x38(%eax),%eax
  10147e:	89 44 24 04          	mov    %eax,0x4(%esp)
  101482:	c7 04 24 c8 35 10 00 	movl   $0x1035c8,(%esp)
  101489:	e8 1a 14 00 00       	call   1028a8 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->cs);
  10148e:	8b 45 08             	mov    0x8(%ebp),%eax
  101491:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  101495:	0f b7 c0             	movzwl %ax,%eax
  101498:	89 44 24 04          	mov    %eax,0x4(%esp)
  10149c:	c7 04 24 d7 35 10 00 	movl   $0x1035d7,(%esp)
  1014a3:	e8 00 14 00 00       	call   1028a8 <cprintf>
	cprintf("  flag 0x%08x\n", tf->eflags);
  1014a8:	8b 45 08             	mov    0x8(%ebp),%eax
  1014ab:	8b 40 40             	mov    0x40(%eax),%eax
  1014ae:	89 44 24 04          	mov    %eax,0x4(%esp)
  1014b2:	c7 04 24 ea 35 10 00 	movl   $0x1035ea,(%esp)
  1014b9:	e8 ea 13 00 00       	call   1028a8 <cprintf>
	cprintf("  esp  0x%08x\n", tf->esp);
  1014be:	8b 45 08             	mov    0x8(%ebp),%eax
  1014c1:	8b 40 44             	mov    0x44(%eax),%eax
  1014c4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1014c8:	c7 04 24 f9 35 10 00 	movl   $0x1035f9,(%esp)
  1014cf:	e8 d4 13 00 00       	call   1028a8 <cprintf>
	cprintf("  ss   0x----%04x\n", tf->ss);
  1014d4:	8b 45 08             	mov    0x8(%ebp),%eax
  1014d7:	0f b7 40 48          	movzwl 0x48(%eax),%eax
  1014db:	0f b7 c0             	movzwl %ax,%eax
  1014de:	89 44 24 04          	mov    %eax,0x4(%esp)
  1014e2:	c7 04 24 08 36 10 00 	movl   $0x103608,(%esp)
  1014e9:	e8 ba 13 00 00       	call   1028a8 <cprintf>
}
  1014ee:	c9                   	leave  
  1014ef:	c3                   	ret    

001014f0 <trap>:

void gcc_noreturn
trap(trapframe *tf)
{
  1014f0:	55                   	push   %ebp
  1014f1:	89 e5                	mov    %esp,%ebp
  1014f3:	83 ec 28             	sub    $0x28,%esp
	// The user-level environment may have set the DF flag,
	// and some versions of GCC rely on DF being clear.
	asm volatile("cld" ::: "cc");
  1014f6:	fc                   	cld    

	// If this trap was anticipated, just use the designated handler.
	cpu *c = cpu_cur();
  1014f7:	e8 88 fb ff ff       	call   101084 <cpu_cur>
  1014fc:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (c->recover)
  1014ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101502:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  101508:	85 c0                	test   %eax,%eax
  10150a:	74 1e                	je     10152a <trap+0x3a>
		c->recover(tf, c->recoverdata);
  10150c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10150f:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  101515:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101518:	8b 92 a4 00 00 00    	mov    0xa4(%edx),%edx
  10151e:	89 54 24 04          	mov    %edx,0x4(%esp)
  101522:	8b 55 08             	mov    0x8(%ebp),%edx
  101525:	89 14 24             	mov    %edx,(%esp)
  101528:	ff d0                	call   *%eax

	trap_print(tf);
  10152a:	8b 45 08             	mov    0x8(%ebp),%eax
  10152d:	89 04 24             	mov    %eax,(%esp)
  101530:	e8 ad fe ff ff       	call   1013e2 <trap_print>
	panic("unhandled trap");
  101535:	c7 44 24 08 1b 36 10 	movl   $0x10361b,0x8(%esp)
  10153c:	00 
  10153d:	c7 44 24 04 8e 00 00 	movl   $0x8e,0x4(%esp)
  101544:	00 
  101545:	c7 04 24 2a 36 10 00 	movl   $0x10362a,(%esp)
  10154c:	e8 f3 ed ff ff       	call   100344 <debug_panic>

00101551 <trap_check_recover>:

// Helper function for trap_check_recover(), below:
// handles "anticipated" traps by simply resuming at a new EIP.
static void gcc_noreturn
trap_check_recover(trapframe *tf, void *recoverdata)
{
  101551:	55                   	push   %ebp
  101552:	89 e5                	mov    %esp,%ebp
  101554:	83 ec 28             	sub    $0x28,%esp
	trap_check_args *args = recoverdata;
  101557:	8b 45 0c             	mov    0xc(%ebp),%eax
  10155a:	89 45 f4             	mov    %eax,-0xc(%ebp)
	tf->eip = (uint32_t) args->reip;	// Use recovery EIP on return
  10155d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101560:	8b 00                	mov    (%eax),%eax
  101562:	89 c2                	mov    %eax,%edx
  101564:	8b 45 08             	mov    0x8(%ebp),%eax
  101567:	89 50 38             	mov    %edx,0x38(%eax)
	args->trapno = tf->trapno;		// Return trap number
  10156a:	8b 45 08             	mov    0x8(%ebp),%eax
  10156d:	8b 40 30             	mov    0x30(%eax),%eax
  101570:	89 c2                	mov    %eax,%edx
  101572:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101575:	89 50 04             	mov    %edx,0x4(%eax)
	trap_return(tf);
  101578:	8b 45 08             	mov    0x8(%ebp),%eax
  10157b:	89 04 24             	mov    %eax,(%esp)
  10157e:	e8 1d 04 00 00       	call   1019a0 <trap_return>

00101583 <trap_check_kernel>:

// Check for correct handling of traps from kernel mode.
// Called on the boot CPU after trap_init() and trap_setup().
void
trap_check_kernel(void)
{
  101583:	55                   	push   %ebp
  101584:	89 e5                	mov    %esp,%ebp
  101586:	53                   	push   %ebx
  101587:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  10158a:	66 8c cb             	mov    %cs,%bx
  10158d:	66 89 5d f2          	mov    %bx,-0xe(%ebp)
        return cs;
  101591:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
	assert((read_cs() & 3) == 0);	// better be in kernel mode!
  101595:	0f b7 c0             	movzwl %ax,%eax
  101598:	83 e0 03             	and    $0x3,%eax
  10159b:	85 c0                	test   %eax,%eax
  10159d:	74 24                	je     1015c3 <trap_check_kernel+0x40>
  10159f:	c7 44 24 0c 36 36 10 	movl   $0x103636,0xc(%esp)
  1015a6:	00 
  1015a7:	c7 44 24 08 b6 34 10 	movl   $0x1034b6,0x8(%esp)
  1015ae:	00 
  1015af:	c7 44 24 04 a2 00 00 	movl   $0xa2,0x4(%esp)
  1015b6:	00 
  1015b7:	c7 04 24 2a 36 10 00 	movl   $0x10362a,(%esp)
  1015be:	e8 81 ed ff ff       	call   100344 <debug_panic>

	cpu *c = cpu_cur();
  1015c3:	e8 bc fa ff ff       	call   101084 <cpu_cur>
  1015c8:	89 45 f4             	mov    %eax,-0xc(%ebp)
	c->recover = trap_check_recover;
  1015cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1015ce:	c7 80 a0 00 00 00 51 	movl   $0x101551,0xa0(%eax)
  1015d5:	15 10 00 
	trap_check(&c->recoverdata);
  1015d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1015db:	05 a4 00 00 00       	add    $0xa4,%eax
  1015e0:	89 04 24             	mov    %eax,(%esp)
  1015e3:	e8 a3 00 00 00       	call   10168b <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  1015e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1015eb:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  1015f2:	00 00 00 

	cprintf("trap_check_kernel() succeeded!\n");
  1015f5:	c7 04 24 4c 36 10 00 	movl   $0x10364c,(%esp)
  1015fc:	e8 a7 12 00 00       	call   1028a8 <cprintf>
}
  101601:	83 c4 24             	add    $0x24,%esp
  101604:	5b                   	pop    %ebx
  101605:	5d                   	pop    %ebp
  101606:	c3                   	ret    

00101607 <trap_check_user>:
// Called from user() in kern/init.c, only in lab 1.
// We assume the "current cpu" is always the boot cpu;
// this true only because lab 1 doesn't start any other CPUs.
void
trap_check_user(void)
{
  101607:	55                   	push   %ebp
  101608:	89 e5                	mov    %esp,%ebp
  10160a:	53                   	push   %ebx
  10160b:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  10160e:	66 8c cb             	mov    %cs,%bx
  101611:	66 89 5d f2          	mov    %bx,-0xe(%ebp)
        return cs;
  101615:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
	assert((read_cs() & 3) == 3);	// better be in user mode!
  101619:	0f b7 c0             	movzwl %ax,%eax
  10161c:	83 e0 03             	and    $0x3,%eax
  10161f:	83 f8 03             	cmp    $0x3,%eax
  101622:	74 24                	je     101648 <trap_check_user+0x41>
  101624:	c7 44 24 0c 6c 36 10 	movl   $0x10366c,0xc(%esp)
  10162b:	00 
  10162c:	c7 44 24 08 b6 34 10 	movl   $0x1034b6,0x8(%esp)
  101633:	00 
  101634:	c7 44 24 04 b3 00 00 	movl   $0xb3,0x4(%esp)
  10163b:	00 
  10163c:	c7 04 24 2a 36 10 00 	movl   $0x10362a,(%esp)
  101643:	e8 fc ec ff ff       	call   100344 <debug_panic>

	cpu *c = &cpu_boot;	// cpu_cur doesn't work from user mode!
  101648:	c7 45 f4 00 70 10 00 	movl   $0x107000,-0xc(%ebp)
	c->recover = trap_check_recover;
  10164f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101652:	c7 80 a0 00 00 00 51 	movl   $0x101551,0xa0(%eax)
  101659:	15 10 00 
	trap_check(&c->recoverdata);
  10165c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10165f:	05 a4 00 00 00       	add    $0xa4,%eax
  101664:	89 04 24             	mov    %eax,(%esp)
  101667:	e8 1f 00 00 00       	call   10168b <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  10166c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10166f:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  101676:	00 00 00 

	cprintf("trap_check_user() succeeded!\n");
  101679:	c7 04 24 81 36 10 00 	movl   $0x103681,(%esp)
  101680:	e8 23 12 00 00       	call   1028a8 <cprintf>
}
  101685:	83 c4 24             	add    $0x24,%esp
  101688:	5b                   	pop    %ebx
  101689:	5d                   	pop    %ebp
  10168a:	c3                   	ret    

0010168b <trap_check>:
void after_priv();

// Multi-purpose trap checking function.
void
trap_check(void **argsp)
{
  10168b:	55                   	push   %ebp
  10168c:	89 e5                	mov    %esp,%ebp
  10168e:	57                   	push   %edi
  10168f:	56                   	push   %esi
  101690:	53                   	push   %ebx
  101691:	83 ec 3c             	sub    $0x3c,%esp
	volatile int cookie = 0xfeedface;
  101694:	c7 45 e0 ce fa ed fe 	movl   $0xfeedface,-0x20(%ebp)
	volatile trap_check_args args;
	*argsp = (void*)&args;	// provide args needed for trap recovery
  10169b:	8b 45 08             	mov    0x8(%ebp),%eax
  10169e:	8d 55 d8             	lea    -0x28(%ebp),%edx
  1016a1:	89 10                	mov    %edx,(%eax)

	// Try a divide by zero trap.
	// Be careful when using && to take the address of a label:
	// some versions of GCC (4.4.2 at least) will incorrectly try to
	// eliminate code it thinks is _only_ reachable via such a pointer.
	args.reip = after_div0;
  1016a3:	c7 45 d8 b1 16 10 00 	movl   $0x1016b1,-0x28(%ebp)
	asm volatile("div %0,%0; after_div0:" : : "r" (0));
  1016aa:	b8 00 00 00 00       	mov    $0x0,%eax
  1016af:	f7 f0                	div    %eax

001016b1 <after_div0>:
	assert(args.trapno == T_DIVIDE);
  1016b1:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1016b4:	85 c0                	test   %eax,%eax
  1016b6:	74 24                	je     1016dc <after_div0+0x2b>
  1016b8:	c7 44 24 0c 9f 36 10 	movl   $0x10369f,0xc(%esp)
  1016bf:	00 
  1016c0:	c7 44 24 08 b6 34 10 	movl   $0x1034b6,0x8(%esp)
  1016c7:	00 
  1016c8:	c7 44 24 04 d3 00 00 	movl   $0xd3,0x4(%esp)
  1016cf:	00 
  1016d0:	c7 04 24 2a 36 10 00 	movl   $0x10362a,(%esp)
  1016d7:	e8 68 ec ff ff       	call   100344 <debug_panic>

	// Make sure we got our correct stack back with us.
	// The asm ensures gcc uses ebp/esp to get the cookie.
	asm volatile("" : : : "eax","ebx","ecx","edx","esi","edi");
	assert(cookie == 0xfeedface);
  1016dc:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1016df:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  1016e4:	74 24                	je     10170a <after_div0+0x59>
  1016e6:	c7 44 24 0c b7 36 10 	movl   $0x1036b7,0xc(%esp)
  1016ed:	00 
  1016ee:	c7 44 24 08 b6 34 10 	movl   $0x1034b6,0x8(%esp)
  1016f5:	00 
  1016f6:	c7 44 24 04 d8 00 00 	movl   $0xd8,0x4(%esp)
  1016fd:	00 
  1016fe:	c7 04 24 2a 36 10 00 	movl   $0x10362a,(%esp)
  101705:	e8 3a ec ff ff       	call   100344 <debug_panic>

	// Breakpoint trap
	args.reip = after_breakpoint;
  10170a:	c7 45 d8 12 17 10 00 	movl   $0x101712,-0x28(%ebp)
	asm volatile("int3; after_breakpoint:");
  101711:	cc                   	int3   

00101712 <after_breakpoint>:
	assert(args.trapno == T_BRKPT);
  101712:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101715:	83 f8 03             	cmp    $0x3,%eax
  101718:	74 24                	je     10173e <after_breakpoint+0x2c>
  10171a:	c7 44 24 0c cc 36 10 	movl   $0x1036cc,0xc(%esp)
  101721:	00 
  101722:	c7 44 24 08 b6 34 10 	movl   $0x1034b6,0x8(%esp)
  101729:	00 
  10172a:	c7 44 24 04 dd 00 00 	movl   $0xdd,0x4(%esp)
  101731:	00 
  101732:	c7 04 24 2a 36 10 00 	movl   $0x10362a,(%esp)
  101739:	e8 06 ec ff ff       	call   100344 <debug_panic>

	// Overflow trap
	args.reip = after_overflow;
  10173e:	c7 45 d8 4d 17 10 00 	movl   $0x10174d,-0x28(%ebp)
	asm volatile("addl %0,%0; into; after_overflow:" : : "r" (0x70000000));
  101745:	b8 00 00 00 70       	mov    $0x70000000,%eax
  10174a:	01 c0                	add    %eax,%eax
  10174c:	ce                   	into   

0010174d <after_overflow>:
	assert(args.trapno == T_OFLOW);
  10174d:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101750:	83 f8 04             	cmp    $0x4,%eax
  101753:	74 24                	je     101779 <after_overflow+0x2c>
  101755:	c7 44 24 0c e3 36 10 	movl   $0x1036e3,0xc(%esp)
  10175c:	00 
  10175d:	c7 44 24 08 b6 34 10 	movl   $0x1034b6,0x8(%esp)
  101764:	00 
  101765:	c7 44 24 04 e2 00 00 	movl   $0xe2,0x4(%esp)
  10176c:	00 
  10176d:	c7 04 24 2a 36 10 00 	movl   $0x10362a,(%esp)
  101774:	e8 cb eb ff ff       	call   100344 <debug_panic>

	// Bounds trap
	args.reip = after_bound;
  101779:	c7 45 d8 96 17 10 00 	movl   $0x101796,-0x28(%ebp)
	int bounds[2] = { 1, 3 };
  101780:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
  101787:	c7 45 d4 03 00 00 00 	movl   $0x3,-0x2c(%ebp)
	asm volatile("boundl %0,%1; after_bound:" : : "r" (0), "m" (bounds[0]));
  10178e:	b8 00 00 00 00       	mov    $0x0,%eax
  101793:	62 45 d0             	bound  %eax,-0x30(%ebp)

00101796 <after_bound>:
	assert(args.trapno == T_BOUND);
  101796:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101799:	83 f8 05             	cmp    $0x5,%eax
  10179c:	74 24                	je     1017c2 <after_bound+0x2c>
  10179e:	c7 44 24 0c fa 36 10 	movl   $0x1036fa,0xc(%esp)
  1017a5:	00 
  1017a6:	c7 44 24 08 b6 34 10 	movl   $0x1034b6,0x8(%esp)
  1017ad:	00 
  1017ae:	c7 44 24 04 e8 00 00 	movl   $0xe8,0x4(%esp)
  1017b5:	00 
  1017b6:	c7 04 24 2a 36 10 00 	movl   $0x10362a,(%esp)
  1017bd:	e8 82 eb ff ff       	call   100344 <debug_panic>

	// Illegal instruction trap
	args.reip = after_illegal;
  1017c2:	c7 45 d8 cb 17 10 00 	movl   $0x1017cb,-0x28(%ebp)
	asm volatile("ud2; after_illegal:");	// guaranteed to be undefined
  1017c9:	0f 0b                	ud2    

001017cb <after_illegal>:
	assert(args.trapno == T_ILLOP);
  1017cb:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1017ce:	83 f8 06             	cmp    $0x6,%eax
  1017d1:	74 24                	je     1017f7 <after_illegal+0x2c>
  1017d3:	c7 44 24 0c 11 37 10 	movl   $0x103711,0xc(%esp)
  1017da:	00 
  1017db:	c7 44 24 08 b6 34 10 	movl   $0x1034b6,0x8(%esp)
  1017e2:	00 
  1017e3:	c7 44 24 04 ed 00 00 	movl   $0xed,0x4(%esp)
  1017ea:	00 
  1017eb:	c7 04 24 2a 36 10 00 	movl   $0x10362a,(%esp)
  1017f2:	e8 4d eb ff ff       	call   100344 <debug_panic>

	// General protection fault due to invalid segment load
	args.reip = after_gpfault;
  1017f7:	c7 45 d8 05 18 10 00 	movl   $0x101805,-0x28(%ebp)
	asm volatile("movl %0,%%fs; after_gpfault:" : : "r" (-1));
  1017fe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  101803:	8e e0                	mov    %eax,%fs

00101805 <after_gpfault>:
	assert(args.trapno == T_GPFLT);
  101805:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101808:	83 f8 0d             	cmp    $0xd,%eax
  10180b:	74 24                	je     101831 <after_gpfault+0x2c>
  10180d:	c7 44 24 0c 28 37 10 	movl   $0x103728,0xc(%esp)
  101814:	00 
  101815:	c7 44 24 08 b6 34 10 	movl   $0x1034b6,0x8(%esp)
  10181c:	00 
  10181d:	c7 44 24 04 f2 00 00 	movl   $0xf2,0x4(%esp)
  101824:	00 
  101825:	c7 04 24 2a 36 10 00 	movl   $0x10362a,(%esp)
  10182c:	e8 13 eb ff ff       	call   100344 <debug_panic>

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  101831:	66 8c cb             	mov    %cs,%bx
  101834:	66 89 5d e6          	mov    %bx,-0x1a(%ebp)
        return cs;
  101838:	0f b7 45 e6          	movzwl -0x1a(%ebp),%eax

	// General protection fault due to privilege violation
	if (read_cs() & 3) {
  10183c:	0f b7 c0             	movzwl %ax,%eax
  10183f:	83 e0 03             	and    $0x3,%eax
  101842:	85 c0                	test   %eax,%eax
  101844:	74 3a                	je     101880 <after_priv+0x2c>
		args.reip = after_priv;
  101846:	c7 45 d8 54 18 10 00 	movl   $0x101854,-0x28(%ebp)
		asm volatile("lidt %0; after_priv:" : : "m" (idt_pd));
  10184d:	0f 01 1d 00 80 10 00 	lidtl  0x108000

00101854 <after_priv>:
		assert(args.trapno == T_GPFLT);
  101854:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101857:	83 f8 0d             	cmp    $0xd,%eax
  10185a:	74 24                	je     101880 <after_priv+0x2c>
  10185c:	c7 44 24 0c 28 37 10 	movl   $0x103728,0xc(%esp)
  101863:	00 
  101864:	c7 44 24 08 b6 34 10 	movl   $0x1034b6,0x8(%esp)
  10186b:	00 
  10186c:	c7 44 24 04 f8 00 00 	movl   $0xf8,0x4(%esp)
  101873:	00 
  101874:	c7 04 24 2a 36 10 00 	movl   $0x10362a,(%esp)
  10187b:	e8 c4 ea ff ff       	call   100344 <debug_panic>
	}

	// Make sure our stack cookie is still with us
	assert(cookie == 0xfeedface);
  101880:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101883:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  101888:	74 24                	je     1018ae <after_priv+0x5a>
  10188a:	c7 44 24 0c b7 36 10 	movl   $0x1036b7,0xc(%esp)
  101891:	00 
  101892:	c7 44 24 08 b6 34 10 	movl   $0x1034b6,0x8(%esp)
  101899:	00 
  10189a:	c7 44 24 04 fc 00 00 	movl   $0xfc,0x4(%esp)
  1018a1:	00 
  1018a2:	c7 04 24 2a 36 10 00 	movl   $0x10362a,(%esp)
  1018a9:	e8 96 ea ff ff       	call   100344 <debug_panic>

	*argsp = NULL;	// recovery mechanism not needed anymore
  1018ae:	8b 45 08             	mov    0x8(%ebp),%eax
  1018b1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
  1018b7:	83 c4 3c             	add    $0x3c,%esp
  1018ba:	5b                   	pop    %ebx
  1018bb:	5e                   	pop    %esi
  1018bc:	5f                   	pop    %edi
  1018bd:	5d                   	pop    %ebp
  1018be:	c3                   	ret    
  1018bf:	90                   	nop

001018c0 <vector0>:
//TRAPHANDLER_NOEC(trap_ltimer,  T_LTIMER)
//TRAPHANDLER_NOEC(trap_lerror,  T_LERROR)
//TRAPHANDLER	(trap_default, T_DEFAULT)
//TRAPHANDLER	(trap_icnt,    T_ICNT)

TRAPHANDLER_NOEC(vector0,0)		// divide error
  1018c0:	6a 00                	push   $0x0
  1018c2:	6a 00                	push   $0x0
  1018c4:	e9 b7 00 00 00       	jmp    101980 <_alltraps>
  1018c9:	90                   	nop

001018ca <vector1>:
TRAPHANDLER_NOEC(vector1,1)		// debug exception
  1018ca:	6a 00                	push   $0x0
  1018cc:	6a 01                	push   $0x1
  1018ce:	e9 ad 00 00 00       	jmp    101980 <_alltraps>
  1018d3:	90                   	nop

001018d4 <vector2>:
TRAPHANDLER_NOEC(vector2,2)		// non-maskable interrupt
  1018d4:	6a 00                	push   $0x0
  1018d6:	6a 02                	push   $0x2
  1018d8:	e9 a3 00 00 00       	jmp    101980 <_alltraps>
  1018dd:	90                   	nop

001018de <vector3>:
TRAPHANDLER_NOEC(vector3,3)		// breakpoint
  1018de:	6a 00                	push   $0x0
  1018e0:	6a 03                	push   $0x3
  1018e2:	e9 99 00 00 00       	jmp    101980 <_alltraps>
  1018e7:	90                   	nop

001018e8 <vector4>:
TRAPHANDLER_NOEC(vector4,4)		// overflow
  1018e8:	6a 00                	push   $0x0
  1018ea:	6a 04                	push   $0x4
  1018ec:	e9 8f 00 00 00       	jmp    101980 <_alltraps>
  1018f1:	90                   	nop

001018f2 <vector5>:
TRAPHANDLER_NOEC(vector5,5)		// bounds check
  1018f2:	6a 00                	push   $0x0
  1018f4:	6a 05                	push   $0x5
  1018f6:	e9 85 00 00 00       	jmp    101980 <_alltraps>
  1018fb:	90                   	nop

001018fc <vector6>:
TRAPHANDLER_NOEC(vector6,6)		// illegal opcode
  1018fc:	6a 00                	push   $0x0
  1018fe:	6a 06                	push   $0x6
  101900:	e9 7b 00 00 00       	jmp    101980 <_alltraps>
  101905:	90                   	nop

00101906 <vector7>:
TRAPHANDLER_NOEC(vector7,7)		// device not available 
  101906:	6a 00                	push   $0x0
  101908:	6a 07                	push   $0x7
  10190a:	e9 71 00 00 00       	jmp    101980 <_alltraps>
  10190f:	90                   	nop

00101910 <vector8>:
TRAPHANDLER(vector8,8)			// double fault
  101910:	6a 08                	push   $0x8
  101912:	e9 69 00 00 00       	jmp    101980 <_alltraps>
  101917:	90                   	nop

00101918 <vector9>:
TRAPHANDLER_NOEC(vector9,9)		// reserved (not generated by recent processors)
  101918:	6a 00                	push   $0x0
  10191a:	6a 09                	push   $0x9
  10191c:	e9 5f 00 00 00       	jmp    101980 <_alltraps>
  101921:	90                   	nop

00101922 <vector10>:
TRAPHANDLER(vector10,10)		// invalid task switch segment
  101922:	6a 0a                	push   $0xa
  101924:	e9 57 00 00 00       	jmp    101980 <_alltraps>
  101929:	90                   	nop

0010192a <vector11>:
TRAPHANDLER(vector11,11)		// segment not present
  10192a:	6a 0b                	push   $0xb
  10192c:	e9 4f 00 00 00       	jmp    101980 <_alltraps>
  101931:	90                   	nop

00101932 <vector12>:
TRAPHANDLER(vector12,12)		// stack exception
  101932:	6a 0c                	push   $0xc
  101934:	e9 47 00 00 00       	jmp    101980 <_alltraps>
  101939:	90                   	nop

0010193a <vector13>:
TRAPHANDLER(vector13,13)		// general protection fault
  10193a:	6a 0d                	push   $0xd
  10193c:	e9 3f 00 00 00       	jmp    101980 <_alltraps>
  101941:	90                   	nop

00101942 <vector14>:
TRAPHANDLER(vector14,14)		// page fault
  101942:	6a 0e                	push   $0xe
  101944:	e9 37 00 00 00       	jmp    101980 <_alltraps>
  101949:	90                   	nop

0010194a <vector15>:
TRAPHANDLER_NOEC(vector15,15)		// reserved
  10194a:	6a 00                	push   $0x0
  10194c:	6a 0f                	push   $0xf
  10194e:	e9 2d 00 00 00       	jmp    101980 <_alltraps>
  101953:	90                   	nop

00101954 <vector16>:
TRAPHANDLER_NOEC(vector16,16)		// floating point error
  101954:	6a 00                	push   $0x0
  101956:	6a 10                	push   $0x10
  101958:	e9 23 00 00 00       	jmp    101980 <_alltraps>
  10195d:	90                   	nop

0010195e <vector17>:
TRAPHANDLER(vector17,17)		// alignment check
  10195e:	6a 11                	push   $0x11
  101960:	e9 1b 00 00 00       	jmp    101980 <_alltraps>
  101965:	90                   	nop

00101966 <vector18>:
TRAPHANDLER_NOEC(vector18,18)		// machine check
  101966:	6a 00                	push   $0x0
  101968:	6a 12                	push   $0x12
  10196a:	e9 11 00 00 00       	jmp    101980 <_alltraps>
  10196f:	90                   	nop

00101970 <vector19>:
TRAPHANDLER_NOEC(vector19,19)		// SIMD floating point error
  101970:	6a 00                	push   $0x0
  101972:	6a 13                	push   $0x13
  101974:	e9 07 00 00 00       	jmp    101980 <_alltraps>
  101979:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00101980 <_alltraps>:
 */
.globl	_alltraps
.type	_alltraps,@function
.p2align 4, 0x90
_alltraps:
	pushl %ds
  101980:	1e                   	push   %ds
	pushl %es
  101981:	06                   	push   %es
	pushl %fs
  101982:	0f a0                	push   %fs
	pushl %gs
  101984:	0f a8                	push   %gs
	pushal
  101986:	60                   	pusha  

	movw $CPU_GDT_KDATA, %ax
  101987:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
  10198b:	8e d8                	mov    %eax,%ds
	movw %ax, %es
  10198d:	8e c0                	mov    %eax,%es
	//there is no SEG_KCPU in PIOS ,
	//so do not need to reset %fs , %gs

	pushl %esp //oesp
  10198f:	54                   	push   %esp
	call trap
  101990:	e8 5b fb ff ff       	call   1014f0 <trap>
  101995:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  101999:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

001019a0 <trap_return>:
.p2align 4, 0x90		/* 16-byte alignment, nop filled */
trap_return:
/*
 * Lab 1: Your code here for trap_return
 */ //1: jmp 1b // just spin
	movl 4(%esp), %esp
  1019a0:	8b 64 24 04          	mov    0x4(%esp),%esp
	//this step has been done in _alltrap
	//popl %esp
	popal 
  1019a4:	61                   	popa   
	popl %gs
  1019a5:	0f a9                	pop    %gs
	popl %fs
  1019a7:	0f a1                	pop    %fs
	popl %es
  1019a9:	07                   	pop    %es
	popl %ds
  1019aa:	1f                   	pop    %ds
	addl $8, %esp
  1019ab:	83 c4 08             	add    $0x8,%esp
	iret
  1019ae:	cf                   	iret   
  1019af:	90                   	nop

001019b0 <video_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

void
video_init(void)
{
  1019b0:	55                   	push   %ebp
  1019b1:	89 e5                	mov    %esp,%ebp
  1019b3:	53                   	push   %ebx
  1019b4:	83 ec 34             	sub    $0x34,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	/* Get a pointer to the memory-mapped text display buffer. */
	cp = (uint16_t*) mem_ptr(CGA_BUF);
  1019b7:	c7 45 f8 00 80 0b 00 	movl   $0xb8000,-0x8(%ebp)
	was = *cp;
  1019be:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1019c1:	0f b7 00             	movzwl (%eax),%eax
  1019c4:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
	*cp = (uint16_t) 0xA55A;
  1019c8:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1019cb:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
  1019d0:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1019d3:	0f b7 00             	movzwl (%eax),%eax
  1019d6:	66 3d 5a a5          	cmp    $0xa55a,%ax
  1019da:	74 13                	je     1019ef <video_init+0x3f>
		cp = (uint16_t*) mem_ptr(MONO_BUF);
  1019dc:	c7 45 f8 00 00 0b 00 	movl   $0xb0000,-0x8(%ebp)
		addr_6845 = MONO_BASE;
  1019e3:	c7 05 a0 9f 10 00 b4 	movl   $0x3b4,0x109fa0
  1019ea:	03 00 00 
  1019ed:	eb 14                	jmp    101a03 <video_init+0x53>
	} else {
		*cp = was;
  1019ef:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1019f2:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
  1019f6:	66 89 10             	mov    %dx,(%eax)
		addr_6845 = CGA_BASE;
  1019f9:	c7 05 a0 9f 10 00 d4 	movl   $0x3d4,0x109fa0
  101a00:	03 00 00 
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
  101a03:	a1 a0 9f 10 00       	mov    0x109fa0,%eax
  101a08:	89 45 ec             	mov    %eax,-0x14(%ebp)
  101a0b:	c6 45 eb 0e          	movb   $0xe,-0x15(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101a0f:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  101a13:	8b 55 ec             	mov    -0x14(%ebp),%edx
  101a16:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
  101a17:	a1 a0 9f 10 00       	mov    0x109fa0,%eax
  101a1c:	83 c0 01             	add    $0x1,%eax
  101a1f:	89 45 e4             	mov    %eax,-0x1c(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101a22:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  101a25:	89 55 c8             	mov    %edx,-0x38(%ebp)
  101a28:	8b 55 c8             	mov    -0x38(%ebp),%edx
  101a2b:	ec                   	in     (%dx),%al
  101a2c:	89 c3                	mov    %eax,%ebx
  101a2e:	88 5d e3             	mov    %bl,-0x1d(%ebp)
	return data;
  101a31:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101a35:	0f b6 c0             	movzbl %al,%eax
  101a38:	c1 e0 08             	shl    $0x8,%eax
  101a3b:	89 45 f0             	mov    %eax,-0x10(%ebp)
	outb(addr_6845, 15);
  101a3e:	a1 a0 9f 10 00       	mov    0x109fa0,%eax
  101a43:	89 45 dc             	mov    %eax,-0x24(%ebp)
  101a46:	c6 45 db 0f          	movb   $0xf,-0x25(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101a4a:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  101a4e:	8b 55 dc             	mov    -0x24(%ebp),%edx
  101a51:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
  101a52:	a1 a0 9f 10 00       	mov    0x109fa0,%eax
  101a57:	83 c0 01             	add    $0x1,%eax
  101a5a:	89 45 d4             	mov    %eax,-0x2c(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101a5d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  101a60:	89 55 c8             	mov    %edx,-0x38(%ebp)
  101a63:	8b 55 c8             	mov    -0x38(%ebp),%edx
  101a66:	ec                   	in     (%dx),%al
  101a67:	89 c3                	mov    %eax,%ebx
  101a69:	88 5d d3             	mov    %bl,-0x2d(%ebp)
	return data;
  101a6c:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
  101a70:	0f b6 c0             	movzbl %al,%eax
  101a73:	09 45 f0             	or     %eax,-0x10(%ebp)

	crt_buf = (uint16_t*) cp;
  101a76:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101a79:	a3 a4 9f 10 00       	mov    %eax,0x109fa4
	crt_pos = pos;
  101a7e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101a81:	66 a3 a8 9f 10 00    	mov    %ax,0x109fa8
}
  101a87:	83 c4 34             	add    $0x34,%esp
  101a8a:	5b                   	pop    %ebx
  101a8b:	5d                   	pop    %ebp
  101a8c:	c3                   	ret    

00101a8d <video_putc>:



void
video_putc(int c)
{
  101a8d:	55                   	push   %ebp
  101a8e:	89 e5                	mov    %esp,%ebp
  101a90:	53                   	push   %ebx
  101a91:	83 ec 44             	sub    $0x44,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
  101a94:	8b 45 08             	mov    0x8(%ebp),%eax
  101a97:	b0 00                	mov    $0x0,%al
  101a99:	85 c0                	test   %eax,%eax
  101a9b:	75 07                	jne    101aa4 <video_putc+0x17>
		c |= 0x0700;
  101a9d:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)

	switch (c & 0xff) {
  101aa4:	8b 45 08             	mov    0x8(%ebp),%eax
  101aa7:	25 ff 00 00 00       	and    $0xff,%eax
  101aac:	83 f8 09             	cmp    $0x9,%eax
  101aaf:	0f 84 ab 00 00 00    	je     101b60 <video_putc+0xd3>
  101ab5:	83 f8 09             	cmp    $0x9,%eax
  101ab8:	7f 0a                	jg     101ac4 <video_putc+0x37>
  101aba:	83 f8 08             	cmp    $0x8,%eax
  101abd:	74 14                	je     101ad3 <video_putc+0x46>
  101abf:	e9 da 00 00 00       	jmp    101b9e <video_putc+0x111>
  101ac4:	83 f8 0a             	cmp    $0xa,%eax
  101ac7:	74 4d                	je     101b16 <video_putc+0x89>
  101ac9:	83 f8 0d             	cmp    $0xd,%eax
  101acc:	74 58                	je     101b26 <video_putc+0x99>
  101ace:	e9 cb 00 00 00       	jmp    101b9e <video_putc+0x111>
	case '\b':
		if (crt_pos > 0) {
  101ad3:	0f b7 05 a8 9f 10 00 	movzwl 0x109fa8,%eax
  101ada:	66 85 c0             	test   %ax,%ax
  101add:	0f 84 e0 00 00 00    	je     101bc3 <video_putc+0x136>
			crt_pos--;
  101ae3:	0f b7 05 a8 9f 10 00 	movzwl 0x109fa8,%eax
  101aea:	83 e8 01             	sub    $0x1,%eax
  101aed:	66 a3 a8 9f 10 00    	mov    %ax,0x109fa8
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
  101af3:	a1 a4 9f 10 00       	mov    0x109fa4,%eax
  101af8:	0f b7 15 a8 9f 10 00 	movzwl 0x109fa8,%edx
  101aff:	0f b7 d2             	movzwl %dx,%edx
  101b02:	01 d2                	add    %edx,%edx
  101b04:	01 c2                	add    %eax,%edx
  101b06:	8b 45 08             	mov    0x8(%ebp),%eax
  101b09:	b0 00                	mov    $0x0,%al
  101b0b:	83 c8 20             	or     $0x20,%eax
  101b0e:	66 89 02             	mov    %ax,(%edx)
		}
		break;
  101b11:	e9 ad 00 00 00       	jmp    101bc3 <video_putc+0x136>
	case '\n':
		crt_pos += CRT_COLS;
  101b16:	0f b7 05 a8 9f 10 00 	movzwl 0x109fa8,%eax
  101b1d:	83 c0 50             	add    $0x50,%eax
  101b20:	66 a3 a8 9f 10 00    	mov    %ax,0x109fa8
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
  101b26:	0f b7 1d a8 9f 10 00 	movzwl 0x109fa8,%ebx
  101b2d:	0f b7 0d a8 9f 10 00 	movzwl 0x109fa8,%ecx
  101b34:	0f b7 c1             	movzwl %cx,%eax
  101b37:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
  101b3d:	c1 e8 10             	shr    $0x10,%eax
  101b40:	89 c2                	mov    %eax,%edx
  101b42:	66 c1 ea 06          	shr    $0x6,%dx
  101b46:	89 d0                	mov    %edx,%eax
  101b48:	c1 e0 02             	shl    $0x2,%eax
  101b4b:	01 d0                	add    %edx,%eax
  101b4d:	c1 e0 04             	shl    $0x4,%eax
  101b50:	89 ca                	mov    %ecx,%edx
  101b52:	29 c2                	sub    %eax,%edx
  101b54:	89 d8                	mov    %ebx,%eax
  101b56:	29 d0                	sub    %edx,%eax
  101b58:	66 a3 a8 9f 10 00    	mov    %ax,0x109fa8
		break;
  101b5e:	eb 64                	jmp    101bc4 <video_putc+0x137>
	case '\t':
		video_putc(' ');
  101b60:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  101b67:	e8 21 ff ff ff       	call   101a8d <video_putc>
		video_putc(' ');
  101b6c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  101b73:	e8 15 ff ff ff       	call   101a8d <video_putc>
		video_putc(' ');
  101b78:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  101b7f:	e8 09 ff ff ff       	call   101a8d <video_putc>
		video_putc(' ');
  101b84:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  101b8b:	e8 fd fe ff ff       	call   101a8d <video_putc>
		video_putc(' ');
  101b90:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  101b97:	e8 f1 fe ff ff       	call   101a8d <video_putc>
		break;
  101b9c:	eb 26                	jmp    101bc4 <video_putc+0x137>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
  101b9e:	8b 15 a4 9f 10 00    	mov    0x109fa4,%edx
  101ba4:	0f b7 05 a8 9f 10 00 	movzwl 0x109fa8,%eax
  101bab:	0f b7 c8             	movzwl %ax,%ecx
  101bae:	01 c9                	add    %ecx,%ecx
  101bb0:	01 d1                	add    %edx,%ecx
  101bb2:	8b 55 08             	mov    0x8(%ebp),%edx
  101bb5:	66 89 11             	mov    %dx,(%ecx)
  101bb8:	83 c0 01             	add    $0x1,%eax
  101bbb:	66 a3 a8 9f 10 00    	mov    %ax,0x109fa8
		break;
  101bc1:	eb 01                	jmp    101bc4 <video_putc+0x137>
	case '\b':
		if (crt_pos > 0) {
			crt_pos--;
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
		}
		break;
  101bc3:	90                   	nop
		crt_buf[crt_pos++] = c;		/* write the character */
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
  101bc4:	0f b7 05 a8 9f 10 00 	movzwl 0x109fa8,%eax
  101bcb:	66 3d cf 07          	cmp    $0x7cf,%ax
  101bcf:	76 5b                	jbe    101c2c <video_putc+0x19f>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
  101bd1:	a1 a4 9f 10 00       	mov    0x109fa4,%eax
  101bd6:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
  101bdc:	a1 a4 9f 10 00       	mov    0x109fa4,%eax
  101be1:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
  101be8:	00 
  101be9:	89 54 24 04          	mov    %edx,0x4(%esp)
  101bed:	89 04 24             	mov    %eax,(%esp)
  101bf0:	e8 06 0f 00 00       	call   102afb <memmove>
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  101bf5:	c7 45 f4 80 07 00 00 	movl   $0x780,-0xc(%ebp)
  101bfc:	eb 15                	jmp    101c13 <video_putc+0x186>
			crt_buf[i] = 0x0700 | ' ';
  101bfe:	a1 a4 9f 10 00       	mov    0x109fa4,%eax
  101c03:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101c06:	01 d2                	add    %edx,%edx
  101c08:	01 d0                	add    %edx,%eax
  101c0a:	66 c7 00 20 07       	movw   $0x720,(%eax)
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  101c0f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  101c13:	81 7d f4 cf 07 00 00 	cmpl   $0x7cf,-0xc(%ebp)
  101c1a:	7e e2                	jle    101bfe <video_putc+0x171>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
  101c1c:	0f b7 05 a8 9f 10 00 	movzwl 0x109fa8,%eax
  101c23:	83 e8 50             	sub    $0x50,%eax
  101c26:	66 a3 a8 9f 10 00    	mov    %ax,0x109fa8
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
  101c2c:	a1 a0 9f 10 00       	mov    0x109fa0,%eax
  101c31:	89 45 f0             	mov    %eax,-0x10(%ebp)
  101c34:	c6 45 ef 0e          	movb   $0xe,-0x11(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101c38:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
  101c3c:	8b 55 f0             	mov    -0x10(%ebp),%edx
  101c3f:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
  101c40:	0f b7 05 a8 9f 10 00 	movzwl 0x109fa8,%eax
  101c47:	66 c1 e8 08          	shr    $0x8,%ax
  101c4b:	0f b6 c0             	movzbl %al,%eax
  101c4e:	8b 15 a0 9f 10 00    	mov    0x109fa0,%edx
  101c54:	83 c2 01             	add    $0x1,%edx
  101c57:	89 55 e8             	mov    %edx,-0x18(%ebp)
  101c5a:	88 45 e7             	mov    %al,-0x19(%ebp)
  101c5d:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  101c61:	8b 55 e8             	mov    -0x18(%ebp),%edx
  101c64:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
  101c65:	a1 a0 9f 10 00       	mov    0x109fa0,%eax
  101c6a:	89 45 e0             	mov    %eax,-0x20(%ebp)
  101c6d:	c6 45 df 0f          	movb   $0xf,-0x21(%ebp)
  101c71:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
  101c75:	8b 55 e0             	mov    -0x20(%ebp),%edx
  101c78:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
  101c79:	0f b7 05 a8 9f 10 00 	movzwl 0x109fa8,%eax
  101c80:	0f b6 c0             	movzbl %al,%eax
  101c83:	8b 15 a0 9f 10 00    	mov    0x109fa0,%edx
  101c89:	83 c2 01             	add    $0x1,%edx
  101c8c:	89 55 d8             	mov    %edx,-0x28(%ebp)
  101c8f:	88 45 d7             	mov    %al,-0x29(%ebp)
  101c92:	0f b6 45 d7          	movzbl -0x29(%ebp),%eax
  101c96:	8b 55 d8             	mov    -0x28(%ebp),%edx
  101c99:	ee                   	out    %al,(%dx)
}
  101c9a:	83 c4 44             	add    $0x44,%esp
  101c9d:	5b                   	pop    %ebx
  101c9e:	5d                   	pop    %ebp
  101c9f:	c3                   	ret    

00101ca0 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
  101ca0:	55                   	push   %ebp
  101ca1:	89 e5                	mov    %esp,%ebp
  101ca3:	53                   	push   %ebx
  101ca4:	83 ec 44             	sub    $0x44,%esp
  101ca7:	c7 45 ec 64 00 00 00 	movl   $0x64,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101cae:	8b 55 ec             	mov    -0x14(%ebp),%edx
  101cb1:	89 55 d4             	mov    %edx,-0x2c(%ebp)
  101cb4:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  101cb7:	ec                   	in     (%dx),%al
  101cb8:	89 c3                	mov    %eax,%ebx
  101cba:	88 5d eb             	mov    %bl,-0x15(%ebp)
	return data;
  101cbd:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
  101cc1:	0f b6 c0             	movzbl %al,%eax
  101cc4:	83 e0 01             	and    $0x1,%eax
  101cc7:	85 c0                	test   %eax,%eax
  101cc9:	75 0a                	jne    101cd5 <kbd_proc_data+0x35>
		return -1;
  101ccb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  101cd0:	e9 5f 01 00 00       	jmp    101e34 <kbd_proc_data+0x194>
  101cd5:	c7 45 e4 60 00 00 00 	movl   $0x60,-0x1c(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101cdc:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  101cdf:	89 55 d4             	mov    %edx,-0x2c(%ebp)
  101ce2:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  101ce5:	ec                   	in     (%dx),%al
  101ce6:	89 c3                	mov    %eax,%ebx
  101ce8:	88 5d e3             	mov    %bl,-0x1d(%ebp)
	return data;
  101ceb:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax

	data = inb(KBDATAP);
  101cef:	88 45 f3             	mov    %al,-0xd(%ebp)

	if (data == 0xE0) {
  101cf2:	80 7d f3 e0          	cmpb   $0xe0,-0xd(%ebp)
  101cf6:	75 17                	jne    101d0f <kbd_proc_data+0x6f>
		// E0 escape character
		shift |= E0ESC;
  101cf8:	a1 ac 9f 10 00       	mov    0x109fac,%eax
  101cfd:	83 c8 40             	or     $0x40,%eax
  101d00:	a3 ac 9f 10 00       	mov    %eax,0x109fac
		return 0;
  101d05:	b8 00 00 00 00       	mov    $0x0,%eax
  101d0a:	e9 25 01 00 00       	jmp    101e34 <kbd_proc_data+0x194>
	} else if (data & 0x80) {
  101d0f:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101d13:	84 c0                	test   %al,%al
  101d15:	79 47                	jns    101d5e <kbd_proc_data+0xbe>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
  101d17:	a1 ac 9f 10 00       	mov    0x109fac,%eax
  101d1c:	83 e0 40             	and    $0x40,%eax
  101d1f:	85 c0                	test   %eax,%eax
  101d21:	75 09                	jne    101d2c <kbd_proc_data+0x8c>
  101d23:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101d27:	83 e0 7f             	and    $0x7f,%eax
  101d2a:	eb 04                	jmp    101d30 <kbd_proc_data+0x90>
  101d2c:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101d30:	88 45 f3             	mov    %al,-0xd(%ebp)
		shift &= ~(shiftcode[data] | E0ESC);
  101d33:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101d37:	0f b6 80 60 80 10 00 	movzbl 0x108060(%eax),%eax
  101d3e:	83 c8 40             	or     $0x40,%eax
  101d41:	0f b6 c0             	movzbl %al,%eax
  101d44:	f7 d0                	not    %eax
  101d46:	89 c2                	mov    %eax,%edx
  101d48:	a1 ac 9f 10 00       	mov    0x109fac,%eax
  101d4d:	21 d0                	and    %edx,%eax
  101d4f:	a3 ac 9f 10 00       	mov    %eax,0x109fac
		return 0;
  101d54:	b8 00 00 00 00       	mov    $0x0,%eax
  101d59:	e9 d6 00 00 00       	jmp    101e34 <kbd_proc_data+0x194>
	} else if (shift & E0ESC) {
  101d5e:	a1 ac 9f 10 00       	mov    0x109fac,%eax
  101d63:	83 e0 40             	and    $0x40,%eax
  101d66:	85 c0                	test   %eax,%eax
  101d68:	74 11                	je     101d7b <kbd_proc_data+0xdb>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
  101d6a:	80 4d f3 80          	orb    $0x80,-0xd(%ebp)
		shift &= ~E0ESC;
  101d6e:	a1 ac 9f 10 00       	mov    0x109fac,%eax
  101d73:	83 e0 bf             	and    $0xffffffbf,%eax
  101d76:	a3 ac 9f 10 00       	mov    %eax,0x109fac
	}

	shift |= shiftcode[data];
  101d7b:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101d7f:	0f b6 80 60 80 10 00 	movzbl 0x108060(%eax),%eax
  101d86:	0f b6 d0             	movzbl %al,%edx
  101d89:	a1 ac 9f 10 00       	mov    0x109fac,%eax
  101d8e:	09 d0                	or     %edx,%eax
  101d90:	a3 ac 9f 10 00       	mov    %eax,0x109fac
	shift ^= togglecode[data];
  101d95:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101d99:	0f b6 80 60 81 10 00 	movzbl 0x108160(%eax),%eax
  101da0:	0f b6 d0             	movzbl %al,%edx
  101da3:	a1 ac 9f 10 00       	mov    0x109fac,%eax
  101da8:	31 d0                	xor    %edx,%eax
  101daa:	a3 ac 9f 10 00       	mov    %eax,0x109fac

	c = charcode[shift & (CTL | SHIFT)][data];
  101daf:	a1 ac 9f 10 00       	mov    0x109fac,%eax
  101db4:	83 e0 03             	and    $0x3,%eax
  101db7:	8b 14 85 60 85 10 00 	mov    0x108560(,%eax,4),%edx
  101dbe:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101dc2:	01 d0                	add    %edx,%eax
  101dc4:	0f b6 00             	movzbl (%eax),%eax
  101dc7:	0f b6 c0             	movzbl %al,%eax
  101dca:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (shift & CAPSLOCK) {
  101dcd:	a1 ac 9f 10 00       	mov    0x109fac,%eax
  101dd2:	83 e0 08             	and    $0x8,%eax
  101dd5:	85 c0                	test   %eax,%eax
  101dd7:	74 22                	je     101dfb <kbd_proc_data+0x15b>
		if ('a' <= c && c <= 'z')
  101dd9:	83 7d f4 60          	cmpl   $0x60,-0xc(%ebp)
  101ddd:	7e 0c                	jle    101deb <kbd_proc_data+0x14b>
  101ddf:	83 7d f4 7a          	cmpl   $0x7a,-0xc(%ebp)
  101de3:	7f 06                	jg     101deb <kbd_proc_data+0x14b>
			c += 'A' - 'a';
  101de5:	83 6d f4 20          	subl   $0x20,-0xc(%ebp)
  101de9:	eb 10                	jmp    101dfb <kbd_proc_data+0x15b>
		else if ('A' <= c && c <= 'Z')
  101deb:	83 7d f4 40          	cmpl   $0x40,-0xc(%ebp)
  101def:	7e 0a                	jle    101dfb <kbd_proc_data+0x15b>
  101df1:	83 7d f4 5a          	cmpl   $0x5a,-0xc(%ebp)
  101df5:	7f 04                	jg     101dfb <kbd_proc_data+0x15b>
			c += 'a' - 'A';
  101df7:	83 45 f4 20          	addl   $0x20,-0xc(%ebp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
  101dfb:	a1 ac 9f 10 00       	mov    0x109fac,%eax
  101e00:	f7 d0                	not    %eax
  101e02:	83 e0 06             	and    $0x6,%eax
  101e05:	85 c0                	test   %eax,%eax
  101e07:	75 28                	jne    101e31 <kbd_proc_data+0x191>
  101e09:	81 7d f4 e9 00 00 00 	cmpl   $0xe9,-0xc(%ebp)
  101e10:	75 1f                	jne    101e31 <kbd_proc_data+0x191>
		cprintf("Rebooting!\n");
  101e12:	c7 04 24 f0 38 10 00 	movl   $0x1038f0,(%esp)
  101e19:	e8 8a 0a 00 00       	call   1028a8 <cprintf>
  101e1e:	c7 45 dc 92 00 00 00 	movl   $0x92,-0x24(%ebp)
  101e25:	c6 45 db 03          	movb   $0x3,-0x25(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101e29:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  101e2d:	8b 55 dc             	mov    -0x24(%ebp),%edx
  101e30:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
  101e31:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  101e34:	83 c4 44             	add    $0x44,%esp
  101e37:	5b                   	pop    %ebx
  101e38:	5d                   	pop    %ebp
  101e39:	c3                   	ret    

00101e3a <kbd_intr>:

void
kbd_intr(void)
{
  101e3a:	55                   	push   %ebp
  101e3b:	89 e5                	mov    %esp,%ebp
  101e3d:	83 ec 18             	sub    $0x18,%esp
	cons_intr(kbd_proc_data);
  101e40:	c7 04 24 a0 1c 10 00 	movl   $0x101ca0,(%esp)
  101e47:	e8 be e3 ff ff       	call   10020a <cons_intr>
}
  101e4c:	c9                   	leave  
  101e4d:	c3                   	ret    

00101e4e <kbd_init>:

void
kbd_init(void)
{
  101e4e:	55                   	push   %ebp
  101e4f:	89 e5                	mov    %esp,%ebp
}
  101e51:	5d                   	pop    %ebp
  101e52:	c3                   	ret    
  101e53:	90                   	nop

00101e54 <delay>:


// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
  101e54:	55                   	push   %ebp
  101e55:	89 e5                	mov    %esp,%ebp
  101e57:	53                   	push   %ebx
  101e58:	83 ec 24             	sub    $0x24,%esp
  101e5b:	c7 45 f8 84 00 00 00 	movl   $0x84,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101e62:	8b 55 f8             	mov    -0x8(%ebp),%edx
  101e65:	89 55 d8             	mov    %edx,-0x28(%ebp)
  101e68:	8b 55 d8             	mov    -0x28(%ebp),%edx
  101e6b:	ec                   	in     (%dx),%al
  101e6c:	89 c3                	mov    %eax,%ebx
  101e6e:	88 5d f7             	mov    %bl,-0x9(%ebp)
  101e71:	c7 45 f0 84 00 00 00 	movl   $0x84,-0x10(%ebp)
  101e78:	8b 55 f0             	mov    -0x10(%ebp),%edx
  101e7b:	89 55 d8             	mov    %edx,-0x28(%ebp)
  101e7e:	8b 55 d8             	mov    -0x28(%ebp),%edx
  101e81:	ec                   	in     (%dx),%al
  101e82:	89 c3                	mov    %eax,%ebx
  101e84:	88 5d ef             	mov    %bl,-0x11(%ebp)
  101e87:	c7 45 e8 84 00 00 00 	movl   $0x84,-0x18(%ebp)
  101e8e:	8b 55 e8             	mov    -0x18(%ebp),%edx
  101e91:	89 55 d8             	mov    %edx,-0x28(%ebp)
  101e94:	8b 55 d8             	mov    -0x28(%ebp),%edx
  101e97:	ec                   	in     (%dx),%al
  101e98:	89 c3                	mov    %eax,%ebx
  101e9a:	88 5d e7             	mov    %bl,-0x19(%ebp)
  101e9d:	c7 45 e0 84 00 00 00 	movl   $0x84,-0x20(%ebp)
  101ea4:	8b 55 e0             	mov    -0x20(%ebp),%edx
  101ea7:	89 55 d8             	mov    %edx,-0x28(%ebp)
  101eaa:	8b 55 d8             	mov    -0x28(%ebp),%edx
  101ead:	ec                   	in     (%dx),%al
  101eae:	89 c3                	mov    %eax,%ebx
  101eb0:	88 5d df             	mov    %bl,-0x21(%ebp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
  101eb3:	83 c4 24             	add    $0x24,%esp
  101eb6:	5b                   	pop    %ebx
  101eb7:	5d                   	pop    %ebp
  101eb8:	c3                   	ret    

00101eb9 <serial_proc_data>:

static int
serial_proc_data(void)
{
  101eb9:	55                   	push   %ebp
  101eba:	89 e5                	mov    %esp,%ebp
  101ebc:	53                   	push   %ebx
  101ebd:	83 ec 14             	sub    $0x14,%esp
  101ec0:	c7 45 f8 fd 03 00 00 	movl   $0x3fd,-0x8(%ebp)
  101ec7:	8b 55 f8             	mov    -0x8(%ebp),%edx
  101eca:	89 55 e8             	mov    %edx,-0x18(%ebp)
  101ecd:	8b 55 e8             	mov    -0x18(%ebp),%edx
  101ed0:	ec                   	in     (%dx),%al
  101ed1:	89 c3                	mov    %eax,%ebx
  101ed3:	88 5d f7             	mov    %bl,-0x9(%ebp)
	return data;
  101ed6:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
  101eda:	0f b6 c0             	movzbl %al,%eax
  101edd:	83 e0 01             	and    $0x1,%eax
  101ee0:	85 c0                	test   %eax,%eax
  101ee2:	75 07                	jne    101eeb <serial_proc_data+0x32>
		return -1;
  101ee4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  101ee9:	eb 1d                	jmp    101f08 <serial_proc_data+0x4f>
  101eeb:	c7 45 f0 f8 03 00 00 	movl   $0x3f8,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101ef2:	8b 55 f0             	mov    -0x10(%ebp),%edx
  101ef5:	89 55 e8             	mov    %edx,-0x18(%ebp)
  101ef8:	8b 55 e8             	mov    -0x18(%ebp),%edx
  101efb:	ec                   	in     (%dx),%al
  101efc:	89 c3                	mov    %eax,%ebx
  101efe:	88 5d ef             	mov    %bl,-0x11(%ebp)
	return data;
  101f01:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
	return inb(COM1+COM_RX);
  101f05:	0f b6 c0             	movzbl %al,%eax
}
  101f08:	83 c4 14             	add    $0x14,%esp
  101f0b:	5b                   	pop    %ebx
  101f0c:	5d                   	pop    %ebp
  101f0d:	c3                   	ret    

00101f0e <serial_intr>:

void
serial_intr(void)
{
  101f0e:	55                   	push   %ebp
  101f0f:	89 e5                	mov    %esp,%ebp
  101f11:	83 ec 18             	sub    $0x18,%esp
	if (serial_exists)
  101f14:	a1 c0 9f 10 00       	mov    0x109fc0,%eax
  101f19:	85 c0                	test   %eax,%eax
  101f1b:	74 0c                	je     101f29 <serial_intr+0x1b>
		cons_intr(serial_proc_data);
  101f1d:	c7 04 24 b9 1e 10 00 	movl   $0x101eb9,(%esp)
  101f24:	e8 e1 e2 ff ff       	call   10020a <cons_intr>
}
  101f29:	c9                   	leave  
  101f2a:	c3                   	ret    

00101f2b <serial_putc>:

void
serial_putc(int c)
{
  101f2b:	55                   	push   %ebp
  101f2c:	89 e5                	mov    %esp,%ebp
  101f2e:	53                   	push   %ebx
  101f2f:	83 ec 24             	sub    $0x24,%esp
	if (!serial_exists)
  101f32:	a1 c0 9f 10 00       	mov    0x109fc0,%eax
  101f37:	85 c0                	test   %eax,%eax
  101f39:	74 59                	je     101f94 <serial_putc+0x69>
		return;

	int i;
	for (i = 0;
  101f3b:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  101f42:	eb 09                	jmp    101f4d <serial_putc+0x22>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
  101f44:	e8 0b ff ff ff       	call   101e54 <delay>
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
  101f49:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  101f4d:	c7 45 f4 fd 03 00 00 	movl   $0x3fd,-0xc(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101f54:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101f57:	89 55 d8             	mov    %edx,-0x28(%ebp)
  101f5a:	8b 55 d8             	mov    -0x28(%ebp),%edx
  101f5d:	ec                   	in     (%dx),%al
  101f5e:	89 c3                	mov    %eax,%ebx
  101f60:	88 5d f3             	mov    %bl,-0xd(%ebp)
	return data;
  101f63:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  101f67:	0f b6 c0             	movzbl %al,%eax
  101f6a:	83 e0 20             	and    $0x20,%eax
{
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
  101f6d:	85 c0                	test   %eax,%eax
  101f6f:	75 09                	jne    101f7a <serial_putc+0x4f>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  101f71:	81 7d f8 ff 31 00 00 	cmpl   $0x31ff,-0x8(%ebp)
  101f78:	7e ca                	jle    101f44 <serial_putc+0x19>
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
  101f7a:	8b 45 08             	mov    0x8(%ebp),%eax
  101f7d:	0f b6 c0             	movzbl %al,%eax
  101f80:	c7 45 ec f8 03 00 00 	movl   $0x3f8,-0x14(%ebp)
  101f87:	88 45 eb             	mov    %al,-0x15(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101f8a:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  101f8e:	8b 55 ec             	mov    -0x14(%ebp),%edx
  101f91:	ee                   	out    %al,(%dx)
  101f92:	eb 01                	jmp    101f95 <serial_putc+0x6a>

void
serial_putc(int c)
{
	if (!serial_exists)
		return;
  101f94:	90                   	nop
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
}
  101f95:	83 c4 24             	add    $0x24,%esp
  101f98:	5b                   	pop    %ebx
  101f99:	5d                   	pop    %ebp
  101f9a:	c3                   	ret    

00101f9b <serial_init>:

void
serial_init(void)
{
  101f9b:	55                   	push   %ebp
  101f9c:	89 e5                	mov    %esp,%ebp
  101f9e:	53                   	push   %ebx
  101f9f:	83 ec 54             	sub    $0x54,%esp
  101fa2:	c7 45 f8 fa 03 00 00 	movl   $0x3fa,-0x8(%ebp)
  101fa9:	c6 45 f7 00          	movb   $0x0,-0x9(%ebp)
  101fad:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
  101fb1:	8b 55 f8             	mov    -0x8(%ebp),%edx
  101fb4:	ee                   	out    %al,(%dx)
  101fb5:	c7 45 f0 fb 03 00 00 	movl   $0x3fb,-0x10(%ebp)
  101fbc:	c6 45 ef 80          	movb   $0x80,-0x11(%ebp)
  101fc0:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
  101fc4:	8b 55 f0             	mov    -0x10(%ebp),%edx
  101fc7:	ee                   	out    %al,(%dx)
  101fc8:	c7 45 e8 f8 03 00 00 	movl   $0x3f8,-0x18(%ebp)
  101fcf:	c6 45 e7 0c          	movb   $0xc,-0x19(%ebp)
  101fd3:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  101fd7:	8b 55 e8             	mov    -0x18(%ebp),%edx
  101fda:	ee                   	out    %al,(%dx)
  101fdb:	c7 45 e0 f9 03 00 00 	movl   $0x3f9,-0x20(%ebp)
  101fe2:	c6 45 df 00          	movb   $0x0,-0x21(%ebp)
  101fe6:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
  101fea:	8b 55 e0             	mov    -0x20(%ebp),%edx
  101fed:	ee                   	out    %al,(%dx)
  101fee:	c7 45 d8 fb 03 00 00 	movl   $0x3fb,-0x28(%ebp)
  101ff5:	c6 45 d7 03          	movb   $0x3,-0x29(%ebp)
  101ff9:	0f b6 45 d7          	movzbl -0x29(%ebp),%eax
  101ffd:	8b 55 d8             	mov    -0x28(%ebp),%edx
  102000:	ee                   	out    %al,(%dx)
  102001:	c7 45 d0 fc 03 00 00 	movl   $0x3fc,-0x30(%ebp)
  102008:	c6 45 cf 00          	movb   $0x0,-0x31(%ebp)
  10200c:	0f b6 45 cf          	movzbl -0x31(%ebp),%eax
  102010:	8b 55 d0             	mov    -0x30(%ebp),%edx
  102013:	ee                   	out    %al,(%dx)
  102014:	c7 45 c8 f9 03 00 00 	movl   $0x3f9,-0x38(%ebp)
  10201b:	c6 45 c7 01          	movb   $0x1,-0x39(%ebp)
  10201f:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
  102023:	8b 55 c8             	mov    -0x38(%ebp),%edx
  102026:	ee                   	out    %al,(%dx)
  102027:	c7 45 c0 fd 03 00 00 	movl   $0x3fd,-0x40(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10202e:	8b 55 c0             	mov    -0x40(%ebp),%edx
  102031:	89 55 a8             	mov    %edx,-0x58(%ebp)
  102034:	8b 55 a8             	mov    -0x58(%ebp),%edx
  102037:	ec                   	in     (%dx),%al
  102038:	89 c3                	mov    %eax,%ebx
  10203a:	88 5d bf             	mov    %bl,-0x41(%ebp)
	return data;
  10203d:	0f b6 45 bf          	movzbl -0x41(%ebp),%eax
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
  102041:	3c ff                	cmp    $0xff,%al
  102043:	0f 95 c0             	setne  %al
  102046:	0f b6 c0             	movzbl %al,%eax
  102049:	a3 c0 9f 10 00       	mov    %eax,0x109fc0
  10204e:	c7 45 b8 fa 03 00 00 	movl   $0x3fa,-0x48(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  102055:	8b 55 b8             	mov    -0x48(%ebp),%edx
  102058:	89 55 a8             	mov    %edx,-0x58(%ebp)
  10205b:	8b 55 a8             	mov    -0x58(%ebp),%edx
  10205e:	ec                   	in     (%dx),%al
  10205f:	89 c3                	mov    %eax,%ebx
  102061:	88 5d b7             	mov    %bl,-0x49(%ebp)
  102064:	c7 45 b0 f8 03 00 00 	movl   $0x3f8,-0x50(%ebp)
  10206b:	8b 55 b0             	mov    -0x50(%ebp),%edx
  10206e:	89 55 a8             	mov    %edx,-0x58(%ebp)
  102071:	8b 55 a8             	mov    -0x58(%ebp),%edx
  102074:	ec                   	in     (%dx),%al
  102075:	89 c3                	mov    %eax,%ebx
  102077:	88 5d af             	mov    %bl,-0x51(%ebp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);
}
  10207a:	83 c4 54             	add    $0x54,%esp
  10207d:	5b                   	pop    %ebx
  10207e:	5d                   	pop    %ebp
  10207f:	c3                   	ret    

00102080 <nvram_read>:
#include <dev/nvram.h>


unsigned
nvram_read(unsigned reg)
{
  102080:	55                   	push   %ebp
  102081:	89 e5                	mov    %esp,%ebp
  102083:	53                   	push   %ebx
  102084:	83 ec 14             	sub    $0x14,%esp
	outb(IO_RTC, reg);
  102087:	8b 45 08             	mov    0x8(%ebp),%eax
  10208a:	0f b6 c0             	movzbl %al,%eax
  10208d:	c7 45 f8 70 00 00 00 	movl   $0x70,-0x8(%ebp)
  102094:	88 45 f7             	mov    %al,-0x9(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  102097:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
  10209b:	8b 55 f8             	mov    -0x8(%ebp),%edx
  10209e:	ee                   	out    %al,(%dx)
  10209f:	c7 45 f0 71 00 00 00 	movl   $0x71,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1020a6:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1020a9:	89 55 e8             	mov    %edx,-0x18(%ebp)
  1020ac:	8b 55 e8             	mov    -0x18(%ebp),%edx
  1020af:	ec                   	in     (%dx),%al
  1020b0:	89 c3                	mov    %eax,%ebx
  1020b2:	88 5d ef             	mov    %bl,-0x11(%ebp)
	return data;
  1020b5:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
	return inb(IO_RTC+1);
  1020b9:	0f b6 c0             	movzbl %al,%eax
}
  1020bc:	83 c4 14             	add    $0x14,%esp
  1020bf:	5b                   	pop    %ebx
  1020c0:	5d                   	pop    %ebp
  1020c1:	c3                   	ret    

001020c2 <nvram_read16>:

unsigned
nvram_read16(unsigned r)
{
  1020c2:	55                   	push   %ebp
  1020c3:	89 e5                	mov    %esp,%ebp
  1020c5:	53                   	push   %ebx
  1020c6:	83 ec 04             	sub    $0x4,%esp
	return nvram_read(r) | (nvram_read(r + 1) << 8);
  1020c9:	8b 45 08             	mov    0x8(%ebp),%eax
  1020cc:	89 04 24             	mov    %eax,(%esp)
  1020cf:	e8 ac ff ff ff       	call   102080 <nvram_read>
  1020d4:	89 c3                	mov    %eax,%ebx
  1020d6:	8b 45 08             	mov    0x8(%ebp),%eax
  1020d9:	83 c0 01             	add    $0x1,%eax
  1020dc:	89 04 24             	mov    %eax,(%esp)
  1020df:	e8 9c ff ff ff       	call   102080 <nvram_read>
  1020e4:	c1 e0 08             	shl    $0x8,%eax
  1020e7:	09 d8                	or     %ebx,%eax
}
  1020e9:	83 c4 04             	add    $0x4,%esp
  1020ec:	5b                   	pop    %ebx
  1020ed:	5d                   	pop    %ebp
  1020ee:	c3                   	ret    

001020ef <nvram_write>:

void
nvram_write(unsigned reg, unsigned datum)
{
  1020ef:	55                   	push   %ebp
  1020f0:	89 e5                	mov    %esp,%ebp
  1020f2:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  1020f5:	8b 45 08             	mov    0x8(%ebp),%eax
  1020f8:	0f b6 c0             	movzbl %al,%eax
  1020fb:	c7 45 fc 70 00 00 00 	movl   $0x70,-0x4(%ebp)
  102102:	88 45 fb             	mov    %al,-0x5(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  102105:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  102109:	8b 55 fc             	mov    -0x4(%ebp),%edx
  10210c:	ee                   	out    %al,(%dx)
	outb(IO_RTC+1, datum);
  10210d:	8b 45 0c             	mov    0xc(%ebp),%eax
  102110:	0f b6 c0             	movzbl %al,%eax
  102113:	c7 45 f4 71 00 00 00 	movl   $0x71,-0xc(%ebp)
  10211a:	88 45 f3             	mov    %al,-0xd(%ebp)
  10211d:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  102121:	8b 55 f4             	mov    -0xc(%ebp),%edx
  102124:	ee                   	out    %al,(%dx)
}
  102125:	c9                   	leave  
  102126:	c3                   	ret    
  102127:	90                   	nop

00102128 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static uintmax_t
getuint(printstate *st, va_list *ap)
{
  102128:	55                   	push   %ebp
  102129:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  10212b:	8b 45 08             	mov    0x8(%ebp),%eax
  10212e:	8b 40 18             	mov    0x18(%eax),%eax
  102131:	83 e0 02             	and    $0x2,%eax
  102134:	85 c0                	test   %eax,%eax
  102136:	74 1c                	je     102154 <getuint+0x2c>
		return va_arg(*ap, unsigned long long);
  102138:	8b 45 0c             	mov    0xc(%ebp),%eax
  10213b:	8b 00                	mov    (%eax),%eax
  10213d:	8d 50 08             	lea    0x8(%eax),%edx
  102140:	8b 45 0c             	mov    0xc(%ebp),%eax
  102143:	89 10                	mov    %edx,(%eax)
  102145:	8b 45 0c             	mov    0xc(%ebp),%eax
  102148:	8b 00                	mov    (%eax),%eax
  10214a:	83 e8 08             	sub    $0x8,%eax
  10214d:	8b 50 04             	mov    0x4(%eax),%edx
  102150:	8b 00                	mov    (%eax),%eax
  102152:	eb 47                	jmp    10219b <getuint+0x73>
	else if (st->flags & F_L)
  102154:	8b 45 08             	mov    0x8(%ebp),%eax
  102157:	8b 40 18             	mov    0x18(%eax),%eax
  10215a:	83 e0 01             	and    $0x1,%eax
  10215d:	85 c0                	test   %eax,%eax
  10215f:	74 1e                	je     10217f <getuint+0x57>
		return va_arg(*ap, unsigned long);
  102161:	8b 45 0c             	mov    0xc(%ebp),%eax
  102164:	8b 00                	mov    (%eax),%eax
  102166:	8d 50 04             	lea    0x4(%eax),%edx
  102169:	8b 45 0c             	mov    0xc(%ebp),%eax
  10216c:	89 10                	mov    %edx,(%eax)
  10216e:	8b 45 0c             	mov    0xc(%ebp),%eax
  102171:	8b 00                	mov    (%eax),%eax
  102173:	83 e8 04             	sub    $0x4,%eax
  102176:	8b 00                	mov    (%eax),%eax
  102178:	ba 00 00 00 00       	mov    $0x0,%edx
  10217d:	eb 1c                	jmp    10219b <getuint+0x73>
	else
		return va_arg(*ap, unsigned int);
  10217f:	8b 45 0c             	mov    0xc(%ebp),%eax
  102182:	8b 00                	mov    (%eax),%eax
  102184:	8d 50 04             	lea    0x4(%eax),%edx
  102187:	8b 45 0c             	mov    0xc(%ebp),%eax
  10218a:	89 10                	mov    %edx,(%eax)
  10218c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10218f:	8b 00                	mov    (%eax),%eax
  102191:	83 e8 04             	sub    $0x4,%eax
  102194:	8b 00                	mov    (%eax),%eax
  102196:	ba 00 00 00 00       	mov    $0x0,%edx
}
  10219b:	5d                   	pop    %ebp
  10219c:	c3                   	ret    

0010219d <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static intmax_t
getint(printstate *st, va_list *ap)
{
  10219d:	55                   	push   %ebp
  10219e:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  1021a0:	8b 45 08             	mov    0x8(%ebp),%eax
  1021a3:	8b 40 18             	mov    0x18(%eax),%eax
  1021a6:	83 e0 02             	and    $0x2,%eax
  1021a9:	85 c0                	test   %eax,%eax
  1021ab:	74 1c                	je     1021c9 <getint+0x2c>
		return va_arg(*ap, long long);
  1021ad:	8b 45 0c             	mov    0xc(%ebp),%eax
  1021b0:	8b 00                	mov    (%eax),%eax
  1021b2:	8d 50 08             	lea    0x8(%eax),%edx
  1021b5:	8b 45 0c             	mov    0xc(%ebp),%eax
  1021b8:	89 10                	mov    %edx,(%eax)
  1021ba:	8b 45 0c             	mov    0xc(%ebp),%eax
  1021bd:	8b 00                	mov    (%eax),%eax
  1021bf:	83 e8 08             	sub    $0x8,%eax
  1021c2:	8b 50 04             	mov    0x4(%eax),%edx
  1021c5:	8b 00                	mov    (%eax),%eax
  1021c7:	eb 47                	jmp    102210 <getint+0x73>
	else if (st->flags & F_L)
  1021c9:	8b 45 08             	mov    0x8(%ebp),%eax
  1021cc:	8b 40 18             	mov    0x18(%eax),%eax
  1021cf:	83 e0 01             	and    $0x1,%eax
  1021d2:	85 c0                	test   %eax,%eax
  1021d4:	74 1e                	je     1021f4 <getint+0x57>
		return va_arg(*ap, long);
  1021d6:	8b 45 0c             	mov    0xc(%ebp),%eax
  1021d9:	8b 00                	mov    (%eax),%eax
  1021db:	8d 50 04             	lea    0x4(%eax),%edx
  1021de:	8b 45 0c             	mov    0xc(%ebp),%eax
  1021e1:	89 10                	mov    %edx,(%eax)
  1021e3:	8b 45 0c             	mov    0xc(%ebp),%eax
  1021e6:	8b 00                	mov    (%eax),%eax
  1021e8:	83 e8 04             	sub    $0x4,%eax
  1021eb:	8b 00                	mov    (%eax),%eax
  1021ed:	89 c2                	mov    %eax,%edx
  1021ef:	c1 fa 1f             	sar    $0x1f,%edx
  1021f2:	eb 1c                	jmp    102210 <getint+0x73>
	else
		return va_arg(*ap, int);
  1021f4:	8b 45 0c             	mov    0xc(%ebp),%eax
  1021f7:	8b 00                	mov    (%eax),%eax
  1021f9:	8d 50 04             	lea    0x4(%eax),%edx
  1021fc:	8b 45 0c             	mov    0xc(%ebp),%eax
  1021ff:	89 10                	mov    %edx,(%eax)
  102201:	8b 45 0c             	mov    0xc(%ebp),%eax
  102204:	8b 00                	mov    (%eax),%eax
  102206:	83 e8 04             	sub    $0x4,%eax
  102209:	8b 00                	mov    (%eax),%eax
  10220b:	89 c2                	mov    %eax,%edx
  10220d:	c1 fa 1f             	sar    $0x1f,%edx
}
  102210:	5d                   	pop    %ebp
  102211:	c3                   	ret    

00102212 <putpad>:

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
  102212:	55                   	push   %ebp
  102213:	89 e5                	mov    %esp,%ebp
  102215:	83 ec 18             	sub    $0x18,%esp
	while (--st->width >= 0)
  102218:	eb 1a                	jmp    102234 <putpad+0x22>
		st->putch(st->padc, st->putdat);
  10221a:	8b 45 08             	mov    0x8(%ebp),%eax
  10221d:	8b 00                	mov    (%eax),%eax
  10221f:	8b 55 08             	mov    0x8(%ebp),%edx
  102222:	8b 4a 04             	mov    0x4(%edx),%ecx
  102225:	8b 55 08             	mov    0x8(%ebp),%edx
  102228:	8b 52 08             	mov    0x8(%edx),%edx
  10222b:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  10222f:	89 14 24             	mov    %edx,(%esp)
  102232:	ff d0                	call   *%eax

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
	while (--st->width >= 0)
  102234:	8b 45 08             	mov    0x8(%ebp),%eax
  102237:	8b 40 0c             	mov    0xc(%eax),%eax
  10223a:	8d 50 ff             	lea    -0x1(%eax),%edx
  10223d:	8b 45 08             	mov    0x8(%ebp),%eax
  102240:	89 50 0c             	mov    %edx,0xc(%eax)
  102243:	8b 45 08             	mov    0x8(%ebp),%eax
  102246:	8b 40 0c             	mov    0xc(%eax),%eax
  102249:	85 c0                	test   %eax,%eax
  10224b:	79 cd                	jns    10221a <putpad+0x8>
		st->putch(st->padc, st->putdat);
}
  10224d:	c9                   	leave  
  10224e:	c3                   	ret    

0010224f <putstr>:

// Print a string with a specified maximum length (-1=unlimited),
// with any appropriate left or right field padding.
static void
putstr(printstate *st, const char *str, int maxlen)
{
  10224f:	55                   	push   %ebp
  102250:	89 e5                	mov    %esp,%ebp
  102252:	53                   	push   %ebx
  102253:	83 ec 24             	sub    $0x24,%esp
	const char *lim;		// find where the string actually ends
	if (maxlen < 0)
  102256:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10225a:	79 18                	jns    102274 <putstr+0x25>
		lim = strchr(str, 0);	// find the terminating null
  10225c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  102263:	00 
  102264:	8b 45 0c             	mov    0xc(%ebp),%eax
  102267:	89 04 24             	mov    %eax,(%esp)
  10226a:	e8 e6 07 00 00       	call   102a55 <strchr>
  10226f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  102272:	eb 2e                	jmp    1022a2 <putstr+0x53>
	else if ((lim = memchr(str, 0, maxlen)) == NULL)
  102274:	8b 45 10             	mov    0x10(%ebp),%eax
  102277:	89 44 24 08          	mov    %eax,0x8(%esp)
  10227b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  102282:	00 
  102283:	8b 45 0c             	mov    0xc(%ebp),%eax
  102286:	89 04 24             	mov    %eax,(%esp)
  102289:	e8 c4 09 00 00       	call   102c52 <memchr>
  10228e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  102291:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  102295:	75 0b                	jne    1022a2 <putstr+0x53>
		lim = str + maxlen;
  102297:	8b 55 10             	mov    0x10(%ebp),%edx
  10229a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10229d:	01 d0                	add    %edx,%eax
  10229f:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->width -= (lim-str);		// deduct string length from field width
  1022a2:	8b 45 08             	mov    0x8(%ebp),%eax
  1022a5:	8b 40 0c             	mov    0xc(%eax),%eax
  1022a8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  1022ab:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1022ae:	89 cb                	mov    %ecx,%ebx
  1022b0:	29 d3                	sub    %edx,%ebx
  1022b2:	89 da                	mov    %ebx,%edx
  1022b4:	01 c2                	add    %eax,%edx
  1022b6:	8b 45 08             	mov    0x8(%ebp),%eax
  1022b9:	89 50 0c             	mov    %edx,0xc(%eax)

	if (!(st->flags & F_RPAD))	// print left-side padding
  1022bc:	8b 45 08             	mov    0x8(%ebp),%eax
  1022bf:	8b 40 18             	mov    0x18(%eax),%eax
  1022c2:	83 e0 10             	and    $0x10,%eax
  1022c5:	85 c0                	test   %eax,%eax
  1022c7:	75 32                	jne    1022fb <putstr+0xac>
		putpad(st);		// (also leaves st->width == 0)
  1022c9:	8b 45 08             	mov    0x8(%ebp),%eax
  1022cc:	89 04 24             	mov    %eax,(%esp)
  1022cf:	e8 3e ff ff ff       	call   102212 <putpad>
	while (str < lim) {
  1022d4:	eb 25                	jmp    1022fb <putstr+0xac>
		char ch = *str++;
  1022d6:	8b 45 0c             	mov    0xc(%ebp),%eax
  1022d9:	0f b6 00             	movzbl (%eax),%eax
  1022dc:	88 45 f3             	mov    %al,-0xd(%ebp)
  1022df:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
			st->putch(ch, st->putdat);
  1022e3:	8b 45 08             	mov    0x8(%ebp),%eax
  1022e6:	8b 00                	mov    (%eax),%eax
  1022e8:	8b 55 08             	mov    0x8(%ebp),%edx
  1022eb:	8b 4a 04             	mov    0x4(%edx),%ecx
  1022ee:	0f be 55 f3          	movsbl -0xd(%ebp),%edx
  1022f2:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  1022f6:	89 14 24             	mov    %edx,(%esp)
  1022f9:	ff d0                	call   *%eax
		lim = str + maxlen;
	st->width -= (lim-str);		// deduct string length from field width

	if (!(st->flags & F_RPAD))	// print left-side padding
		putpad(st);		// (also leaves st->width == 0)
	while (str < lim) {
  1022fb:	8b 45 0c             	mov    0xc(%ebp),%eax
  1022fe:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  102301:	72 d3                	jb     1022d6 <putstr+0x87>
		char ch = *str++;
			st->putch(ch, st->putdat);
	}
	putpad(st);			// print right-side padding
  102303:	8b 45 08             	mov    0x8(%ebp),%eax
  102306:	89 04 24             	mov    %eax,(%esp)
  102309:	e8 04 ff ff ff       	call   102212 <putpad>
}
  10230e:	83 c4 24             	add    $0x24,%esp
  102311:	5b                   	pop    %ebx
  102312:	5d                   	pop    %ebp
  102313:	c3                   	ret    

00102314 <genint>:

// Generate a number (base <= 16) in reverse order into a string buffer.
static char *
genint(printstate *st, char *p, uintmax_t num)
{
  102314:	55                   	push   %ebp
  102315:	89 e5                	mov    %esp,%ebp
  102317:	53                   	push   %ebx
  102318:	83 ec 24             	sub    $0x24,%esp
  10231b:	8b 45 10             	mov    0x10(%ebp),%eax
  10231e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  102321:	8b 45 14             	mov    0x14(%ebp),%eax
  102324:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= st->base)
  102327:	8b 45 08             	mov    0x8(%ebp),%eax
  10232a:	8b 40 1c             	mov    0x1c(%eax),%eax
  10232d:	89 c2                	mov    %eax,%edx
  10232f:	c1 fa 1f             	sar    $0x1f,%edx
  102332:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  102335:	77 4e                	ja     102385 <genint+0x71>
  102337:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  10233a:	72 05                	jb     102341 <genint+0x2d>
  10233c:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  10233f:	77 44                	ja     102385 <genint+0x71>
		p = genint(st, p, num / st->base);	// output higher digits
  102341:	8b 45 08             	mov    0x8(%ebp),%eax
  102344:	8b 40 1c             	mov    0x1c(%eax),%eax
  102347:	89 c2                	mov    %eax,%edx
  102349:	c1 fa 1f             	sar    $0x1f,%edx
  10234c:	89 44 24 08          	mov    %eax,0x8(%esp)
  102350:	89 54 24 0c          	mov    %edx,0xc(%esp)
  102354:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102357:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10235a:	89 04 24             	mov    %eax,(%esp)
  10235d:	89 54 24 04          	mov    %edx,0x4(%esp)
  102361:	e8 2a 09 00 00       	call   102c90 <__udivdi3>
  102366:	89 44 24 08          	mov    %eax,0x8(%esp)
  10236a:	89 54 24 0c          	mov    %edx,0xc(%esp)
  10236e:	8b 45 0c             	mov    0xc(%ebp),%eax
  102371:	89 44 24 04          	mov    %eax,0x4(%esp)
  102375:	8b 45 08             	mov    0x8(%ebp),%eax
  102378:	89 04 24             	mov    %eax,(%esp)
  10237b:	e8 94 ff ff ff       	call   102314 <genint>
  102380:	89 45 0c             	mov    %eax,0xc(%ebp)
  102383:	eb 1b                	jmp    1023a0 <genint+0x8c>
	else if (st->signc >= 0)
  102385:	8b 45 08             	mov    0x8(%ebp),%eax
  102388:	8b 40 14             	mov    0x14(%eax),%eax
  10238b:	85 c0                	test   %eax,%eax
  10238d:	78 11                	js     1023a0 <genint+0x8c>
		*p++ = st->signc;			// output leading sign
  10238f:	8b 45 08             	mov    0x8(%ebp),%eax
  102392:	8b 40 14             	mov    0x14(%eax),%eax
  102395:	89 c2                	mov    %eax,%edx
  102397:	8b 45 0c             	mov    0xc(%ebp),%eax
  10239a:	88 10                	mov    %dl,(%eax)
  10239c:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	*p++ = "0123456789abcdef"[num % st->base];	// output this digit
  1023a0:	8b 45 08             	mov    0x8(%ebp),%eax
  1023a3:	8b 40 1c             	mov    0x1c(%eax),%eax
  1023a6:	89 c1                	mov    %eax,%ecx
  1023a8:	89 c3                	mov    %eax,%ebx
  1023aa:	c1 fb 1f             	sar    $0x1f,%ebx
  1023ad:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1023b0:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1023b3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  1023b7:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  1023bb:	89 04 24             	mov    %eax,(%esp)
  1023be:	89 54 24 04          	mov    %edx,0x4(%esp)
  1023c2:	e8 29 0a 00 00       	call   102df0 <__umoddi3>
  1023c7:	05 fc 38 10 00       	add    $0x1038fc,%eax
  1023cc:	0f b6 10             	movzbl (%eax),%edx
  1023cf:	8b 45 0c             	mov    0xc(%ebp),%eax
  1023d2:	88 10                	mov    %dl,(%eax)
  1023d4:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	return p;
  1023d8:	8b 45 0c             	mov    0xc(%ebp),%eax
}
  1023db:	83 c4 24             	add    $0x24,%esp
  1023de:	5b                   	pop    %ebx
  1023df:	5d                   	pop    %ebp
  1023e0:	c3                   	ret    

001023e1 <putint>:

// Print an integer with any appropriate field padding.
static void
putint(printstate *st, uintmax_t num, int base)
{
  1023e1:	55                   	push   %ebp
  1023e2:	89 e5                	mov    %esp,%ebp
  1023e4:	83 ec 58             	sub    $0x58,%esp
  1023e7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1023ea:	89 45 c0             	mov    %eax,-0x40(%ebp)
  1023ed:	8b 45 10             	mov    0x10(%ebp),%eax
  1023f0:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	char buf[30], *p = buf;		// big enough for any 64-bit int in octal
  1023f3:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  1023f6:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->base = base;		// select base for genint
  1023f9:	8b 45 08             	mov    0x8(%ebp),%eax
  1023fc:	8b 55 14             	mov    0x14(%ebp),%edx
  1023ff:	89 50 1c             	mov    %edx,0x1c(%eax)
	p = genint(st, p, num);		// output to the string buffer
  102402:	8b 45 c0             	mov    -0x40(%ebp),%eax
  102405:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  102408:	89 44 24 08          	mov    %eax,0x8(%esp)
  10240c:	89 54 24 0c          	mov    %edx,0xc(%esp)
  102410:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102413:	89 44 24 04          	mov    %eax,0x4(%esp)
  102417:	8b 45 08             	mov    0x8(%ebp),%eax
  10241a:	89 04 24             	mov    %eax,(%esp)
  10241d:	e8 f2 fe ff ff       	call   102314 <genint>
  102422:	89 45 f4             	mov    %eax,-0xc(%ebp)
	putstr(st, buf, p-buf);		// print it with left/right padding
  102425:	8b 55 f4             	mov    -0xc(%ebp),%edx
  102428:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  10242b:	89 d1                	mov    %edx,%ecx
  10242d:	29 c1                	sub    %eax,%ecx
  10242f:	89 c8                	mov    %ecx,%eax
  102431:	89 44 24 08          	mov    %eax,0x8(%esp)
  102435:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  102438:	89 44 24 04          	mov    %eax,0x4(%esp)
  10243c:	8b 45 08             	mov    0x8(%ebp),%eax
  10243f:	89 04 24             	mov    %eax,(%esp)
  102442:	e8 08 fe ff ff       	call   10224f <putstr>
}
  102447:	c9                   	leave  
  102448:	c3                   	ret    

00102449 <vprintfmt>:
#endif	// ! PIOS_KERNEL

// Main function to format and print a string.
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  102449:	55                   	push   %ebp
  10244a:	89 e5                	mov    %esp,%ebp
  10244c:	53                   	push   %ebx
  10244d:	83 ec 44             	sub    $0x44,%esp
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
  102450:	8d 55 cc             	lea    -0x34(%ebp),%edx
  102453:	b9 00 00 00 00       	mov    $0x0,%ecx
  102458:	b8 20 00 00 00       	mov    $0x20,%eax
  10245d:	89 c3                	mov    %eax,%ebx
  10245f:	83 e3 fc             	and    $0xfffffffc,%ebx
  102462:	b8 00 00 00 00       	mov    $0x0,%eax
  102467:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
  10246a:	83 c0 04             	add    $0x4,%eax
  10246d:	39 d8                	cmp    %ebx,%eax
  10246f:	72 f6                	jb     102467 <vprintfmt+0x1e>
  102471:	01 c2                	add    %eax,%edx
  102473:	8b 45 08             	mov    0x8(%ebp),%eax
  102476:	89 45 cc             	mov    %eax,-0x34(%ebp)
  102479:	8b 45 0c             	mov    0xc(%ebp),%eax
  10247c:	89 45 d0             	mov    %eax,-0x30(%ebp)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  10247f:	eb 17                	jmp    102498 <vprintfmt+0x4f>
			if (ch == '\0')
  102481:	85 db                	test   %ebx,%ebx
  102483:	0f 84 50 03 00 00    	je     1027d9 <vprintfmt+0x390>
				return;
			putch(ch, putdat);
  102489:	8b 45 0c             	mov    0xc(%ebp),%eax
  10248c:	89 44 24 04          	mov    %eax,0x4(%esp)
  102490:	89 1c 24             	mov    %ebx,(%esp)
  102493:	8b 45 08             	mov    0x8(%ebp),%eax
  102496:	ff d0                	call   *%eax
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  102498:	8b 45 10             	mov    0x10(%ebp),%eax
  10249b:	0f b6 00             	movzbl (%eax),%eax
  10249e:	0f b6 d8             	movzbl %al,%ebx
  1024a1:	83 fb 25             	cmp    $0x25,%ebx
  1024a4:	0f 95 c0             	setne  %al
  1024a7:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  1024ab:	84 c0                	test   %al,%al
  1024ad:	75 d2                	jne    102481 <vprintfmt+0x38>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		st.padc = ' ';
  1024af:	c7 45 d4 20 00 00 00 	movl   $0x20,-0x2c(%ebp)
		st.width = -1;
  1024b6:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		st.prec = -1;
  1024bd:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		st.signc = -1;
  1024c4:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		st.flags = 0;
  1024cb:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		st.base = 10;
  1024d2:	c7 45 e8 0a 00 00 00 	movl   $0xa,-0x18(%ebp)
  1024d9:	eb 04                	jmp    1024df <vprintfmt+0x96>
			goto reswitch;

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
				st.signc = ' ';
			goto reswitch;
  1024db:	90                   	nop
  1024dc:	eb 01                	jmp    1024df <vprintfmt+0x96>
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
				st.width = st.prec;	// then it's a field width
				st.prec = -1;
			}
			goto reswitch;
  1024de:	90                   	nop
		st.signc = -1;
		st.flags = 0;
		st.base = 10;
		uintmax_t num;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  1024df:	8b 45 10             	mov    0x10(%ebp),%eax
  1024e2:	0f b6 00             	movzbl (%eax),%eax
  1024e5:	0f b6 d8             	movzbl %al,%ebx
  1024e8:	89 d8                	mov    %ebx,%eax
  1024ea:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  1024ee:	83 e8 20             	sub    $0x20,%eax
  1024f1:	83 f8 58             	cmp    $0x58,%eax
  1024f4:	0f 87 ae 02 00 00    	ja     1027a8 <vprintfmt+0x35f>
  1024fa:	8b 04 85 14 39 10 00 	mov    0x103914(,%eax,4),%eax
  102501:	ff e0                	jmp    *%eax

		// modifier flags
		case '-': // pad on the right instead of the left
			st.flags |= F_RPAD;
  102503:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  102506:	83 c8 10             	or     $0x10,%eax
  102509:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
  10250c:	eb d1                	jmp    1024df <vprintfmt+0x96>

		case '+': // prefix positive numeric values with a '+' sign
			st.signc = '+';
  10250e:	c7 45 e0 2b 00 00 00 	movl   $0x2b,-0x20(%ebp)
			goto reswitch;
  102515:	eb c8                	jmp    1024df <vprintfmt+0x96>

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
  102517:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10251a:	85 c0                	test   %eax,%eax
  10251c:	79 bd                	jns    1024db <vprintfmt+0x92>
				st.signc = ' ';
  10251e:	c7 45 e0 20 00 00 00 	movl   $0x20,-0x20(%ebp)
			goto reswitch;
  102525:	eb b4                	jmp    1024db <vprintfmt+0x92>

		// width or precision field
		case '0':
			if (!(st.flags & F_DOT))
  102527:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10252a:	83 e0 08             	and    $0x8,%eax
  10252d:	85 c0                	test   %eax,%eax
  10252f:	75 07                	jne    102538 <vprintfmt+0xef>
				st.padc = '0'; // pad with 0's instead of spaces
  102531:	c7 45 d4 30 00 00 00 	movl   $0x30,-0x2c(%ebp)
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  102538:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
				st.prec = st.prec * 10 + ch - '0';
  10253f:	8b 55 dc             	mov    -0x24(%ebp),%edx
  102542:	89 d0                	mov    %edx,%eax
  102544:	c1 e0 02             	shl    $0x2,%eax
  102547:	01 d0                	add    %edx,%eax
  102549:	01 c0                	add    %eax,%eax
  10254b:	01 d8                	add    %ebx,%eax
  10254d:	83 e8 30             	sub    $0x30,%eax
  102550:	89 45 dc             	mov    %eax,-0x24(%ebp)
				ch = *fmt;
  102553:	8b 45 10             	mov    0x10(%ebp),%eax
  102556:	0f b6 00             	movzbl (%eax),%eax
  102559:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
  10255c:	83 fb 2f             	cmp    $0x2f,%ebx
  10255f:	7e 21                	jle    102582 <vprintfmt+0x139>
  102561:	83 fb 39             	cmp    $0x39,%ebx
  102564:	7f 1c                	jg     102582 <vprintfmt+0x139>
		case '0':
			if (!(st.flags & F_DOT))
				st.padc = '0'; // pad with 0's instead of spaces
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  102566:	83 45 10 01          	addl   $0x1,0x10(%ebp)
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  10256a:	eb d3                	jmp    10253f <vprintfmt+0xf6>
			goto gotprec;

		case '*':
			st.prec = va_arg(ap, int);
  10256c:	8b 45 14             	mov    0x14(%ebp),%eax
  10256f:	83 c0 04             	add    $0x4,%eax
  102572:	89 45 14             	mov    %eax,0x14(%ebp)
  102575:	8b 45 14             	mov    0x14(%ebp),%eax
  102578:	83 e8 04             	sub    $0x4,%eax
  10257b:	8b 00                	mov    (%eax),%eax
  10257d:	89 45 dc             	mov    %eax,-0x24(%ebp)
  102580:	eb 01                	jmp    102583 <vprintfmt+0x13a>
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto gotprec;
  102582:	90                   	nop

		case '*':
			st.prec = va_arg(ap, int);
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
  102583:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  102586:	83 e0 08             	and    $0x8,%eax
  102589:	85 c0                	test   %eax,%eax
  10258b:	0f 85 4d ff ff ff    	jne    1024de <vprintfmt+0x95>
				st.width = st.prec;	// then it's a field width
  102591:	8b 45 dc             	mov    -0x24(%ebp),%eax
  102594:	89 45 d8             	mov    %eax,-0x28(%ebp)
				st.prec = -1;
  102597:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
			}
			goto reswitch;
  10259e:	e9 3b ff ff ff       	jmp    1024de <vprintfmt+0x95>

		case '.':
			st.flags |= F_DOT;
  1025a3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1025a6:	83 c8 08             	or     $0x8,%eax
  1025a9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
  1025ac:	e9 2e ff ff ff       	jmp    1024df <vprintfmt+0x96>

		case '#':
			st.flags |= F_ALT;
  1025b1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1025b4:	83 c8 04             	or     $0x4,%eax
  1025b7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
  1025ba:	e9 20 ff ff ff       	jmp    1024df <vprintfmt+0x96>

		// long flag (doubled for long long)
		case 'l':
			st.flags |= (st.flags & F_L) ? F_LL : F_L;
  1025bf:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  1025c2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1025c5:	83 e0 01             	and    $0x1,%eax
  1025c8:	85 c0                	test   %eax,%eax
  1025ca:	74 07                	je     1025d3 <vprintfmt+0x18a>
  1025cc:	b8 02 00 00 00       	mov    $0x2,%eax
  1025d1:	eb 05                	jmp    1025d8 <vprintfmt+0x18f>
  1025d3:	b8 01 00 00 00       	mov    $0x1,%eax
  1025d8:	09 d0                	or     %edx,%eax
  1025da:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
  1025dd:	e9 fd fe ff ff       	jmp    1024df <vprintfmt+0x96>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  1025e2:	8b 45 14             	mov    0x14(%ebp),%eax
  1025e5:	83 c0 04             	add    $0x4,%eax
  1025e8:	89 45 14             	mov    %eax,0x14(%ebp)
  1025eb:	8b 45 14             	mov    0x14(%ebp),%eax
  1025ee:	83 e8 04             	sub    $0x4,%eax
  1025f1:	8b 00                	mov    (%eax),%eax
  1025f3:	8b 55 0c             	mov    0xc(%ebp),%edx
  1025f6:	89 54 24 04          	mov    %edx,0x4(%esp)
  1025fa:	89 04 24             	mov    %eax,(%esp)
  1025fd:	8b 45 08             	mov    0x8(%ebp),%eax
  102600:	ff d0                	call   *%eax
			break;
  102602:	e9 cc 01 00 00       	jmp    1027d3 <vprintfmt+0x38a>

		// string
		case 's': {
			const char *s;
			if ((s = va_arg(ap, char *)) == NULL)
  102607:	8b 45 14             	mov    0x14(%ebp),%eax
  10260a:	83 c0 04             	add    $0x4,%eax
  10260d:	89 45 14             	mov    %eax,0x14(%ebp)
  102610:	8b 45 14             	mov    0x14(%ebp),%eax
  102613:	83 e8 04             	sub    $0x4,%eax
  102616:	8b 00                	mov    (%eax),%eax
  102618:	89 45 ec             	mov    %eax,-0x14(%ebp)
  10261b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  10261f:	75 07                	jne    102628 <vprintfmt+0x1df>
				s = "(null)";
  102621:	c7 45 ec 0d 39 10 00 	movl   $0x10390d,-0x14(%ebp)
			putstr(&st, s, st.prec);
  102628:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10262b:	89 44 24 08          	mov    %eax,0x8(%esp)
  10262f:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102632:	89 44 24 04          	mov    %eax,0x4(%esp)
  102636:	8d 45 cc             	lea    -0x34(%ebp),%eax
  102639:	89 04 24             	mov    %eax,(%esp)
  10263c:	e8 0e fc ff ff       	call   10224f <putstr>
			break;
  102641:	e9 8d 01 00 00       	jmp    1027d3 <vprintfmt+0x38a>
		    }

		// (signed) decimal
		case 'd':
			num = getint(&st, &ap);
  102646:	8d 45 14             	lea    0x14(%ebp),%eax
  102649:	89 44 24 04          	mov    %eax,0x4(%esp)
  10264d:	8d 45 cc             	lea    -0x34(%ebp),%eax
  102650:	89 04 24             	mov    %eax,(%esp)
  102653:	e8 45 fb ff ff       	call   10219d <getint>
  102658:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10265b:	89 55 f4             	mov    %edx,-0xc(%ebp)
			if ((intmax_t) num < 0) {
  10265e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102661:	8b 55 f4             	mov    -0xc(%ebp),%edx
  102664:	85 d2                	test   %edx,%edx
  102666:	79 1a                	jns    102682 <vprintfmt+0x239>
				num = -(intmax_t) num;
  102668:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10266b:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10266e:	f7 d8                	neg    %eax
  102670:	83 d2 00             	adc    $0x0,%edx
  102673:	f7 da                	neg    %edx
  102675:	89 45 f0             	mov    %eax,-0x10(%ebp)
  102678:	89 55 f4             	mov    %edx,-0xc(%ebp)
				st.signc = '-';
  10267b:	c7 45 e0 2d 00 00 00 	movl   $0x2d,-0x20(%ebp)
			}
			putint(&st, num, 10);
  102682:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  102689:	00 
  10268a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10268d:	8b 55 f4             	mov    -0xc(%ebp),%edx
  102690:	89 44 24 04          	mov    %eax,0x4(%esp)
  102694:	89 54 24 08          	mov    %edx,0x8(%esp)
  102698:	8d 45 cc             	lea    -0x34(%ebp),%eax
  10269b:	89 04 24             	mov    %eax,(%esp)
  10269e:	e8 3e fd ff ff       	call   1023e1 <putint>
			break;
  1026a3:	e9 2b 01 00 00       	jmp    1027d3 <vprintfmt+0x38a>

		// unsigned decimal
		case 'u':
			putint(&st, getuint(&st, &ap), 10);
  1026a8:	8d 45 14             	lea    0x14(%ebp),%eax
  1026ab:	89 44 24 04          	mov    %eax,0x4(%esp)
  1026af:	8d 45 cc             	lea    -0x34(%ebp),%eax
  1026b2:	89 04 24             	mov    %eax,(%esp)
  1026b5:	e8 6e fa ff ff       	call   102128 <getuint>
  1026ba:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  1026c1:	00 
  1026c2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1026c6:	89 54 24 08          	mov    %edx,0x8(%esp)
  1026ca:	8d 45 cc             	lea    -0x34(%ebp),%eax
  1026cd:	89 04 24             	mov    %eax,(%esp)
  1026d0:	e8 0c fd ff ff       	call   1023e1 <putint>
			break;
  1026d5:	e9 f9 00 00 00       	jmp    1027d3 <vprintfmt+0x38a>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putint(&st, getuint(&st, &ap), 8);
  1026da:	8d 45 14             	lea    0x14(%ebp),%eax
  1026dd:	89 44 24 04          	mov    %eax,0x4(%esp)
  1026e1:	8d 45 cc             	lea    -0x34(%ebp),%eax
  1026e4:	89 04 24             	mov    %eax,(%esp)
  1026e7:	e8 3c fa ff ff       	call   102128 <getuint>
  1026ec:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  1026f3:	00 
  1026f4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1026f8:	89 54 24 08          	mov    %edx,0x8(%esp)
  1026fc:	8d 45 cc             	lea    -0x34(%ebp),%eax
  1026ff:	89 04 24             	mov    %eax,(%esp)
  102702:	e8 da fc ff ff       	call   1023e1 <putint>
			break;
  102707:	e9 c7 00 00 00       	jmp    1027d3 <vprintfmt+0x38a>

		// (unsigned) hexadecimal
		case 'x':
			putint(&st, getuint(&st, &ap), 16);
  10270c:	8d 45 14             	lea    0x14(%ebp),%eax
  10270f:	89 44 24 04          	mov    %eax,0x4(%esp)
  102713:	8d 45 cc             	lea    -0x34(%ebp),%eax
  102716:	89 04 24             	mov    %eax,(%esp)
  102719:	e8 0a fa ff ff       	call   102128 <getuint>
  10271e:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  102725:	00 
  102726:	89 44 24 04          	mov    %eax,0x4(%esp)
  10272a:	89 54 24 08          	mov    %edx,0x8(%esp)
  10272e:	8d 45 cc             	lea    -0x34(%ebp),%eax
  102731:	89 04 24             	mov    %eax,(%esp)
  102734:	e8 a8 fc ff ff       	call   1023e1 <putint>
			break;
  102739:	e9 95 00 00 00       	jmp    1027d3 <vprintfmt+0x38a>

		// pointer
		case 'p':
			putch('0', putdat);
  10273e:	8b 45 0c             	mov    0xc(%ebp),%eax
  102741:	89 44 24 04          	mov    %eax,0x4(%esp)
  102745:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  10274c:	8b 45 08             	mov    0x8(%ebp),%eax
  10274f:	ff d0                	call   *%eax
			putch('x', putdat);
  102751:	8b 45 0c             	mov    0xc(%ebp),%eax
  102754:	89 44 24 04          	mov    %eax,0x4(%esp)
  102758:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  10275f:	8b 45 08             	mov    0x8(%ebp),%eax
  102762:	ff d0                	call   *%eax
			putint(&st, (uintptr_t) va_arg(ap, void *), 16);
  102764:	8b 45 14             	mov    0x14(%ebp),%eax
  102767:	83 c0 04             	add    $0x4,%eax
  10276a:	89 45 14             	mov    %eax,0x14(%ebp)
  10276d:	8b 45 14             	mov    0x14(%ebp),%eax
  102770:	83 e8 04             	sub    $0x4,%eax
  102773:	8b 00                	mov    (%eax),%eax
  102775:	ba 00 00 00 00       	mov    $0x0,%edx
  10277a:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  102781:	00 
  102782:	89 44 24 04          	mov    %eax,0x4(%esp)
  102786:	89 54 24 08          	mov    %edx,0x8(%esp)
  10278a:	8d 45 cc             	lea    -0x34(%ebp),%eax
  10278d:	89 04 24             	mov    %eax,(%esp)
  102790:	e8 4c fc ff ff       	call   1023e1 <putint>
			break;
  102795:	eb 3c                	jmp    1027d3 <vprintfmt+0x38a>
		    }
#endif	// ! PIOS_KERNEL

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  102797:	8b 45 0c             	mov    0xc(%ebp),%eax
  10279a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10279e:	89 1c 24             	mov    %ebx,(%esp)
  1027a1:	8b 45 08             	mov    0x8(%ebp),%eax
  1027a4:	ff d0                	call   *%eax
			break;
  1027a6:	eb 2b                	jmp    1027d3 <vprintfmt+0x38a>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  1027a8:	8b 45 0c             	mov    0xc(%ebp),%eax
  1027ab:	89 44 24 04          	mov    %eax,0x4(%esp)
  1027af:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  1027b6:	8b 45 08             	mov    0x8(%ebp),%eax
  1027b9:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
  1027bb:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  1027bf:	eb 04                	jmp    1027c5 <vprintfmt+0x37c>
  1027c1:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  1027c5:	8b 45 10             	mov    0x10(%ebp),%eax
  1027c8:	83 e8 01             	sub    $0x1,%eax
  1027cb:	0f b6 00             	movzbl (%eax),%eax
  1027ce:	3c 25                	cmp    $0x25,%al
  1027d0:	75 ef                	jne    1027c1 <vprintfmt+0x378>
				/* do nothing */;
			break;
  1027d2:	90                   	nop
		}
	}
  1027d3:	90                   	nop
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  1027d4:	e9 bf fc ff ff       	jmp    102498 <vprintfmt+0x4f>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
  1027d9:	83 c4 44             	add    $0x44,%esp
  1027dc:	5b                   	pop    %ebx
  1027dd:	5d                   	pop    %ebp
  1027de:	c3                   	ret    
  1027df:	90                   	nop

001027e0 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  1027e0:	55                   	push   %ebp
  1027e1:	89 e5                	mov    %esp,%ebp
  1027e3:	83 ec 18             	sub    $0x18,%esp
	b->buf[b->idx++] = ch;
  1027e6:	8b 45 0c             	mov    0xc(%ebp),%eax
  1027e9:	8b 00                	mov    (%eax),%eax
  1027eb:	8b 55 08             	mov    0x8(%ebp),%edx
  1027ee:	89 d1                	mov    %edx,%ecx
  1027f0:	8b 55 0c             	mov    0xc(%ebp),%edx
  1027f3:	88 4c 02 08          	mov    %cl,0x8(%edx,%eax,1)
  1027f7:	8d 50 01             	lea    0x1(%eax),%edx
  1027fa:	8b 45 0c             	mov    0xc(%ebp),%eax
  1027fd:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
  1027ff:	8b 45 0c             	mov    0xc(%ebp),%eax
  102802:	8b 00                	mov    (%eax),%eax
  102804:	3d ff 00 00 00       	cmp    $0xff,%eax
  102809:	75 24                	jne    10282f <putch+0x4f>
		b->buf[b->idx] = 0;
  10280b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10280e:	8b 00                	mov    (%eax),%eax
  102810:	8b 55 0c             	mov    0xc(%ebp),%edx
  102813:	c6 44 02 08 00       	movb   $0x0,0x8(%edx,%eax,1)
		cputs(b->buf);
  102818:	8b 45 0c             	mov    0xc(%ebp),%eax
  10281b:	83 c0 08             	add    $0x8,%eax
  10281e:	89 04 24             	mov    %eax,(%esp)
  102821:	e8 f2 da ff ff       	call   100318 <cputs>
		b->idx = 0;
  102826:	8b 45 0c             	mov    0xc(%ebp),%eax
  102829:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
  10282f:	8b 45 0c             	mov    0xc(%ebp),%eax
  102832:	8b 40 04             	mov    0x4(%eax),%eax
  102835:	8d 50 01             	lea    0x1(%eax),%edx
  102838:	8b 45 0c             	mov    0xc(%ebp),%eax
  10283b:	89 50 04             	mov    %edx,0x4(%eax)
}
  10283e:	c9                   	leave  
  10283f:	c3                   	ret    

00102840 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  102840:	55                   	push   %ebp
  102841:	89 e5                	mov    %esp,%ebp
  102843:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  102849:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  102850:	00 00 00 
	b.cnt = 0;
  102853:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  10285a:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  10285d:	8b 45 0c             	mov    0xc(%ebp),%eax
  102860:	89 44 24 0c          	mov    %eax,0xc(%esp)
  102864:	8b 45 08             	mov    0x8(%ebp),%eax
  102867:	89 44 24 08          	mov    %eax,0x8(%esp)
  10286b:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  102871:	89 44 24 04          	mov    %eax,0x4(%esp)
  102875:	c7 04 24 e0 27 10 00 	movl   $0x1027e0,(%esp)
  10287c:	e8 c8 fb ff ff       	call   102449 <vprintfmt>

	b.buf[b.idx] = 0;
  102881:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  102887:	c6 84 05 f8 fe ff ff 	movb   $0x0,-0x108(%ebp,%eax,1)
  10288e:	00 
	cputs(b.buf);
  10288f:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  102895:	83 c0 08             	add    $0x8,%eax
  102898:	89 04 24             	mov    %eax,(%esp)
  10289b:	e8 78 da ff ff       	call   100318 <cputs>

	return b.cnt;
  1028a0:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
}
  1028a6:	c9                   	leave  
  1028a7:	c3                   	ret    

001028a8 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  1028a8:	55                   	push   %ebp
  1028a9:	89 e5                	mov    %esp,%ebp
  1028ab:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  1028ae:	8d 45 0c             	lea    0xc(%ebp),%eax
  1028b1:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cnt = vcprintf(fmt, ap);
  1028b4:	8b 45 08             	mov    0x8(%ebp),%eax
  1028b7:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1028ba:	89 54 24 04          	mov    %edx,0x4(%esp)
  1028be:	89 04 24             	mov    %eax,(%esp)
  1028c1:	e8 7a ff ff ff       	call   102840 <vcprintf>
  1028c6:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return cnt;
  1028c9:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  1028cc:	c9                   	leave  
  1028cd:	c3                   	ret    
  1028ce:	90                   	nop
  1028cf:	90                   	nop

001028d0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  1028d0:	55                   	push   %ebp
  1028d1:	89 e5                	mov    %esp,%ebp
  1028d3:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
  1028d6:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  1028dd:	eb 08                	jmp    1028e7 <strlen+0x17>
		n++;
  1028df:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  1028e3:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1028e7:	8b 45 08             	mov    0x8(%ebp),%eax
  1028ea:	0f b6 00             	movzbl (%eax),%eax
  1028ed:	84 c0                	test   %al,%al
  1028ef:	75 ee                	jne    1028df <strlen+0xf>
		n++;
	return n;
  1028f1:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  1028f4:	c9                   	leave  
  1028f5:	c3                   	ret    

001028f6 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  1028f6:	55                   	push   %ebp
  1028f7:	89 e5                	mov    %esp,%ebp
  1028f9:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
  1028fc:	8b 45 08             	mov    0x8(%ebp),%eax
  1028ff:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
  102902:	90                   	nop
  102903:	8b 45 0c             	mov    0xc(%ebp),%eax
  102906:	0f b6 10             	movzbl (%eax),%edx
  102909:	8b 45 08             	mov    0x8(%ebp),%eax
  10290c:	88 10                	mov    %dl,(%eax)
  10290e:	8b 45 08             	mov    0x8(%ebp),%eax
  102911:	0f b6 00             	movzbl (%eax),%eax
  102914:	84 c0                	test   %al,%al
  102916:	0f 95 c0             	setne  %al
  102919:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10291d:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  102921:	84 c0                	test   %al,%al
  102923:	75 de                	jne    102903 <strcpy+0xd>
		/* do nothing */;
	return ret;
  102925:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  102928:	c9                   	leave  
  102929:	c3                   	ret    

0010292a <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
  10292a:	55                   	push   %ebp
  10292b:	89 e5                	mov    %esp,%ebp
  10292d:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
  102930:	8b 45 08             	mov    0x8(%ebp),%eax
  102933:	89 45 f8             	mov    %eax,-0x8(%ebp)
	for (i = 0; i < size; i++) {
  102936:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  10293d:	eb 21                	jmp    102960 <strncpy+0x36>
		*dst++ = *src;
  10293f:	8b 45 0c             	mov    0xc(%ebp),%eax
  102942:	0f b6 10             	movzbl (%eax),%edx
  102945:	8b 45 08             	mov    0x8(%ebp),%eax
  102948:	88 10                	mov    %dl,(%eax)
  10294a:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
  10294e:	8b 45 0c             	mov    0xc(%ebp),%eax
  102951:	0f b6 00             	movzbl (%eax),%eax
  102954:	84 c0                	test   %al,%al
  102956:	74 04                	je     10295c <strncpy+0x32>
			src++;
  102958:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  10295c:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  102960:	8b 45 fc             	mov    -0x4(%ebp),%eax
  102963:	3b 45 10             	cmp    0x10(%ebp),%eax
  102966:	72 d7                	jb     10293f <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
  102968:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
  10296b:	c9                   	leave  
  10296c:	c3                   	ret    

0010296d <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  10296d:	55                   	push   %ebp
  10296e:	89 e5                	mov    %esp,%ebp
  102970:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
  102973:	8b 45 08             	mov    0x8(%ebp),%eax
  102976:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
  102979:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10297d:	74 2f                	je     1029ae <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
  10297f:	eb 13                	jmp    102994 <strlcpy+0x27>
			*dst++ = *src++;
  102981:	8b 45 0c             	mov    0xc(%ebp),%eax
  102984:	0f b6 10             	movzbl (%eax),%edx
  102987:	8b 45 08             	mov    0x8(%ebp),%eax
  10298a:	88 10                	mov    %dl,(%eax)
  10298c:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  102990:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  102994:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  102998:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10299c:	74 0a                	je     1029a8 <strlcpy+0x3b>
  10299e:	8b 45 0c             	mov    0xc(%ebp),%eax
  1029a1:	0f b6 00             	movzbl (%eax),%eax
  1029a4:	84 c0                	test   %al,%al
  1029a6:	75 d9                	jne    102981 <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
  1029a8:	8b 45 08             	mov    0x8(%ebp),%eax
  1029ab:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  1029ae:	8b 55 08             	mov    0x8(%ebp),%edx
  1029b1:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1029b4:	89 d1                	mov    %edx,%ecx
  1029b6:	29 c1                	sub    %eax,%ecx
  1029b8:	89 c8                	mov    %ecx,%eax
}
  1029ba:	c9                   	leave  
  1029bb:	c3                   	ret    

001029bc <strcmp>:

int
strcmp(const char *p, const char *q)
{
  1029bc:	55                   	push   %ebp
  1029bd:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
  1029bf:	eb 08                	jmp    1029c9 <strcmp+0xd>
		p++, q++;
  1029c1:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1029c5:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  1029c9:	8b 45 08             	mov    0x8(%ebp),%eax
  1029cc:	0f b6 00             	movzbl (%eax),%eax
  1029cf:	84 c0                	test   %al,%al
  1029d1:	74 10                	je     1029e3 <strcmp+0x27>
  1029d3:	8b 45 08             	mov    0x8(%ebp),%eax
  1029d6:	0f b6 10             	movzbl (%eax),%edx
  1029d9:	8b 45 0c             	mov    0xc(%ebp),%eax
  1029dc:	0f b6 00             	movzbl (%eax),%eax
  1029df:	38 c2                	cmp    %al,%dl
  1029e1:	74 de                	je     1029c1 <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  1029e3:	8b 45 08             	mov    0x8(%ebp),%eax
  1029e6:	0f b6 00             	movzbl (%eax),%eax
  1029e9:	0f b6 d0             	movzbl %al,%edx
  1029ec:	8b 45 0c             	mov    0xc(%ebp),%eax
  1029ef:	0f b6 00             	movzbl (%eax),%eax
  1029f2:	0f b6 c0             	movzbl %al,%eax
  1029f5:	89 d1                	mov    %edx,%ecx
  1029f7:	29 c1                	sub    %eax,%ecx
  1029f9:	89 c8                	mov    %ecx,%eax
}
  1029fb:	5d                   	pop    %ebp
  1029fc:	c3                   	ret    

001029fd <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  1029fd:	55                   	push   %ebp
  1029fe:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
  102a00:	eb 0c                	jmp    102a0e <strncmp+0x11>
		n--, p++, q++;
  102a02:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  102a06:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  102a0a:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  102a0e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  102a12:	74 1a                	je     102a2e <strncmp+0x31>
  102a14:	8b 45 08             	mov    0x8(%ebp),%eax
  102a17:	0f b6 00             	movzbl (%eax),%eax
  102a1a:	84 c0                	test   %al,%al
  102a1c:	74 10                	je     102a2e <strncmp+0x31>
  102a1e:	8b 45 08             	mov    0x8(%ebp),%eax
  102a21:	0f b6 10             	movzbl (%eax),%edx
  102a24:	8b 45 0c             	mov    0xc(%ebp),%eax
  102a27:	0f b6 00             	movzbl (%eax),%eax
  102a2a:	38 c2                	cmp    %al,%dl
  102a2c:	74 d4                	je     102a02 <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
  102a2e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  102a32:	75 07                	jne    102a3b <strncmp+0x3e>
		return 0;
  102a34:	b8 00 00 00 00       	mov    $0x0,%eax
  102a39:	eb 18                	jmp    102a53 <strncmp+0x56>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  102a3b:	8b 45 08             	mov    0x8(%ebp),%eax
  102a3e:	0f b6 00             	movzbl (%eax),%eax
  102a41:	0f b6 d0             	movzbl %al,%edx
  102a44:	8b 45 0c             	mov    0xc(%ebp),%eax
  102a47:	0f b6 00             	movzbl (%eax),%eax
  102a4a:	0f b6 c0             	movzbl %al,%eax
  102a4d:	89 d1                	mov    %edx,%ecx
  102a4f:	29 c1                	sub    %eax,%ecx
  102a51:	89 c8                	mov    %ecx,%eax
}
  102a53:	5d                   	pop    %ebp
  102a54:	c3                   	ret    

00102a55 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  102a55:	55                   	push   %ebp
  102a56:	89 e5                	mov    %esp,%ebp
  102a58:	83 ec 04             	sub    $0x4,%esp
  102a5b:	8b 45 0c             	mov    0xc(%ebp),%eax
  102a5e:	88 45 fc             	mov    %al,-0x4(%ebp)
	while (*s != c)
  102a61:	eb 1a                	jmp    102a7d <strchr+0x28>
		if (*s++ == 0)
  102a63:	8b 45 08             	mov    0x8(%ebp),%eax
  102a66:	0f b6 00             	movzbl (%eax),%eax
  102a69:	84 c0                	test   %al,%al
  102a6b:	0f 94 c0             	sete   %al
  102a6e:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  102a72:	84 c0                	test   %al,%al
  102a74:	74 07                	je     102a7d <strchr+0x28>
			return NULL;
  102a76:	b8 00 00 00 00       	mov    $0x0,%eax
  102a7b:	eb 0e                	jmp    102a8b <strchr+0x36>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	while (*s != c)
  102a7d:	8b 45 08             	mov    0x8(%ebp),%eax
  102a80:	0f b6 00             	movzbl (%eax),%eax
  102a83:	3a 45 fc             	cmp    -0x4(%ebp),%al
  102a86:	75 db                	jne    102a63 <strchr+0xe>
		if (*s++ == 0)
			return NULL;
	return (char *) s;
  102a88:	8b 45 08             	mov    0x8(%ebp),%eax
}
  102a8b:	c9                   	leave  
  102a8c:	c3                   	ret    

00102a8d <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  102a8d:	55                   	push   %ebp
  102a8e:	89 e5                	mov    %esp,%ebp
  102a90:	57                   	push   %edi
	char *p;

	if (n == 0)
  102a91:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  102a95:	75 05                	jne    102a9c <memset+0xf>
		return v;
  102a97:	8b 45 08             	mov    0x8(%ebp),%eax
  102a9a:	eb 5c                	jmp    102af8 <memset+0x6b>
	if ((int)v%4 == 0 && n%4 == 0) {
  102a9c:	8b 45 08             	mov    0x8(%ebp),%eax
  102a9f:	83 e0 03             	and    $0x3,%eax
  102aa2:	85 c0                	test   %eax,%eax
  102aa4:	75 41                	jne    102ae7 <memset+0x5a>
  102aa6:	8b 45 10             	mov    0x10(%ebp),%eax
  102aa9:	83 e0 03             	and    $0x3,%eax
  102aac:	85 c0                	test   %eax,%eax
  102aae:	75 37                	jne    102ae7 <memset+0x5a>
		c &= 0xFF;
  102ab0:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
  102ab7:	8b 45 0c             	mov    0xc(%ebp),%eax
  102aba:	89 c2                	mov    %eax,%edx
  102abc:	c1 e2 18             	shl    $0x18,%edx
  102abf:	8b 45 0c             	mov    0xc(%ebp),%eax
  102ac2:	c1 e0 10             	shl    $0x10,%eax
  102ac5:	09 c2                	or     %eax,%edx
  102ac7:	8b 45 0c             	mov    0xc(%ebp),%eax
  102aca:	c1 e0 08             	shl    $0x8,%eax
  102acd:	09 d0                	or     %edx,%eax
  102acf:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  102ad2:	8b 45 10             	mov    0x10(%ebp),%eax
  102ad5:	89 c1                	mov    %eax,%ecx
  102ad7:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  102ada:	8b 55 08             	mov    0x8(%ebp),%edx
  102add:	8b 45 0c             	mov    0xc(%ebp),%eax
  102ae0:	89 d7                	mov    %edx,%edi
  102ae2:	fc                   	cld    
  102ae3:	f3 ab                	rep stos %eax,%es:(%edi)
  102ae5:	eb 0e                	jmp    102af5 <memset+0x68>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  102ae7:	8b 55 08             	mov    0x8(%ebp),%edx
  102aea:	8b 45 0c             	mov    0xc(%ebp),%eax
  102aed:	8b 4d 10             	mov    0x10(%ebp),%ecx
  102af0:	89 d7                	mov    %edx,%edi
  102af2:	fc                   	cld    
  102af3:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
  102af5:	8b 45 08             	mov    0x8(%ebp),%eax
}
  102af8:	5f                   	pop    %edi
  102af9:	5d                   	pop    %ebp
  102afa:	c3                   	ret    

00102afb <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  102afb:	55                   	push   %ebp
  102afc:	89 e5                	mov    %esp,%ebp
  102afe:	57                   	push   %edi
  102aff:	56                   	push   %esi
  102b00:	53                   	push   %ebx
  102b01:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
  102b04:	8b 45 0c             	mov    0xc(%ebp),%eax
  102b07:	89 45 f0             	mov    %eax,-0x10(%ebp)
	d = dst;
  102b0a:	8b 45 08             	mov    0x8(%ebp),%eax
  102b0d:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (s < d && s + n > d) {
  102b10:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102b13:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  102b16:	73 6d                	jae    102b85 <memmove+0x8a>
  102b18:	8b 45 10             	mov    0x10(%ebp),%eax
  102b1b:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102b1e:	01 d0                	add    %edx,%eax
  102b20:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  102b23:	76 60                	jbe    102b85 <memmove+0x8a>
		s += n;
  102b25:	8b 45 10             	mov    0x10(%ebp),%eax
  102b28:	01 45 f0             	add    %eax,-0x10(%ebp)
		d += n;
  102b2b:	8b 45 10             	mov    0x10(%ebp),%eax
  102b2e:	01 45 ec             	add    %eax,-0x14(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  102b31:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102b34:	83 e0 03             	and    $0x3,%eax
  102b37:	85 c0                	test   %eax,%eax
  102b39:	75 2f                	jne    102b6a <memmove+0x6f>
  102b3b:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102b3e:	83 e0 03             	and    $0x3,%eax
  102b41:	85 c0                	test   %eax,%eax
  102b43:	75 25                	jne    102b6a <memmove+0x6f>
  102b45:	8b 45 10             	mov    0x10(%ebp),%eax
  102b48:	83 e0 03             	and    $0x3,%eax
  102b4b:	85 c0                	test   %eax,%eax
  102b4d:	75 1b                	jne    102b6a <memmove+0x6f>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  102b4f:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102b52:	83 e8 04             	sub    $0x4,%eax
  102b55:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102b58:	83 ea 04             	sub    $0x4,%edx
  102b5b:	8b 4d 10             	mov    0x10(%ebp),%ecx
  102b5e:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  102b61:	89 c7                	mov    %eax,%edi
  102b63:	89 d6                	mov    %edx,%esi
  102b65:	fd                   	std    
  102b66:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  102b68:	eb 18                	jmp    102b82 <memmove+0x87>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  102b6a:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102b6d:	8d 50 ff             	lea    -0x1(%eax),%edx
  102b70:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102b73:	8d 58 ff             	lea    -0x1(%eax),%ebx
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  102b76:	8b 45 10             	mov    0x10(%ebp),%eax
  102b79:	89 d7                	mov    %edx,%edi
  102b7b:	89 de                	mov    %ebx,%esi
  102b7d:	89 c1                	mov    %eax,%ecx
  102b7f:	fd                   	std    
  102b80:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  102b82:	fc                   	cld    
  102b83:	eb 45                	jmp    102bca <memmove+0xcf>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  102b85:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102b88:	83 e0 03             	and    $0x3,%eax
  102b8b:	85 c0                	test   %eax,%eax
  102b8d:	75 2b                	jne    102bba <memmove+0xbf>
  102b8f:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102b92:	83 e0 03             	and    $0x3,%eax
  102b95:	85 c0                	test   %eax,%eax
  102b97:	75 21                	jne    102bba <memmove+0xbf>
  102b99:	8b 45 10             	mov    0x10(%ebp),%eax
  102b9c:	83 e0 03             	and    $0x3,%eax
  102b9f:	85 c0                	test   %eax,%eax
  102ba1:	75 17                	jne    102bba <memmove+0xbf>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  102ba3:	8b 45 10             	mov    0x10(%ebp),%eax
  102ba6:	89 c1                	mov    %eax,%ecx
  102ba8:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  102bab:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102bae:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102bb1:	89 c7                	mov    %eax,%edi
  102bb3:	89 d6                	mov    %edx,%esi
  102bb5:	fc                   	cld    
  102bb6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  102bb8:	eb 10                	jmp    102bca <memmove+0xcf>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  102bba:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102bbd:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102bc0:	8b 4d 10             	mov    0x10(%ebp),%ecx
  102bc3:	89 c7                	mov    %eax,%edi
  102bc5:	89 d6                	mov    %edx,%esi
  102bc7:	fc                   	cld    
  102bc8:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
  102bca:	8b 45 08             	mov    0x8(%ebp),%eax
}
  102bcd:	83 c4 10             	add    $0x10,%esp
  102bd0:	5b                   	pop    %ebx
  102bd1:	5e                   	pop    %esi
  102bd2:	5f                   	pop    %edi
  102bd3:	5d                   	pop    %ebp
  102bd4:	c3                   	ret    

00102bd5 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  102bd5:	55                   	push   %ebp
  102bd6:	89 e5                	mov    %esp,%ebp
  102bd8:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  102bdb:	8b 45 10             	mov    0x10(%ebp),%eax
  102bde:	89 44 24 08          	mov    %eax,0x8(%esp)
  102be2:	8b 45 0c             	mov    0xc(%ebp),%eax
  102be5:	89 44 24 04          	mov    %eax,0x4(%esp)
  102be9:	8b 45 08             	mov    0x8(%ebp),%eax
  102bec:	89 04 24             	mov    %eax,(%esp)
  102bef:	e8 07 ff ff ff       	call   102afb <memmove>
}
  102bf4:	c9                   	leave  
  102bf5:	c3                   	ret    

00102bf6 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  102bf6:	55                   	push   %ebp
  102bf7:	89 e5                	mov    %esp,%ebp
  102bf9:	83 ec 10             	sub    $0x10,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
  102bfc:	8b 45 08             	mov    0x8(%ebp),%eax
  102bff:	89 45 fc             	mov    %eax,-0x4(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
  102c02:	8b 45 0c             	mov    0xc(%ebp),%eax
  102c05:	89 45 f8             	mov    %eax,-0x8(%ebp)

	while (n-- > 0) {
  102c08:	eb 32                	jmp    102c3c <memcmp+0x46>
		if (*s1 != *s2)
  102c0a:	8b 45 fc             	mov    -0x4(%ebp),%eax
  102c0d:	0f b6 10             	movzbl (%eax),%edx
  102c10:	8b 45 f8             	mov    -0x8(%ebp),%eax
  102c13:	0f b6 00             	movzbl (%eax),%eax
  102c16:	38 c2                	cmp    %al,%dl
  102c18:	74 1a                	je     102c34 <memcmp+0x3e>
			return (int) *s1 - (int) *s2;
  102c1a:	8b 45 fc             	mov    -0x4(%ebp),%eax
  102c1d:	0f b6 00             	movzbl (%eax),%eax
  102c20:	0f b6 d0             	movzbl %al,%edx
  102c23:	8b 45 f8             	mov    -0x8(%ebp),%eax
  102c26:	0f b6 00             	movzbl (%eax),%eax
  102c29:	0f b6 c0             	movzbl %al,%eax
  102c2c:	89 d1                	mov    %edx,%ecx
  102c2e:	29 c1                	sub    %eax,%ecx
  102c30:	89 c8                	mov    %ecx,%eax
  102c32:	eb 1c                	jmp    102c50 <memcmp+0x5a>
		s1++, s2++;
  102c34:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  102c38:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  102c3c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  102c40:	0f 95 c0             	setne  %al
  102c43:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  102c47:	84 c0                	test   %al,%al
  102c49:	75 bf                	jne    102c0a <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  102c4b:	b8 00 00 00 00       	mov    $0x0,%eax
}
  102c50:	c9                   	leave  
  102c51:	c3                   	ret    

00102c52 <memchr>:

void *
memchr(const void *s, int c, size_t n)
{
  102c52:	55                   	push   %ebp
  102c53:	89 e5                	mov    %esp,%ebp
  102c55:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
  102c58:	8b 45 10             	mov    0x10(%ebp),%eax
  102c5b:	8b 55 08             	mov    0x8(%ebp),%edx
  102c5e:	01 d0                	add    %edx,%eax
  102c60:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
  102c63:	eb 16                	jmp    102c7b <memchr+0x29>
		if (*(const unsigned char *) s == (unsigned char) c)
  102c65:	8b 45 08             	mov    0x8(%ebp),%eax
  102c68:	0f b6 10             	movzbl (%eax),%edx
  102c6b:	8b 45 0c             	mov    0xc(%ebp),%eax
  102c6e:	38 c2                	cmp    %al,%dl
  102c70:	75 05                	jne    102c77 <memchr+0x25>
			return (void *) s;
  102c72:	8b 45 08             	mov    0x8(%ebp),%eax
  102c75:	eb 11                	jmp    102c88 <memchr+0x36>

void *
memchr(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  102c77:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  102c7b:	8b 45 08             	mov    0x8(%ebp),%eax
  102c7e:	3b 45 fc             	cmp    -0x4(%ebp),%eax
  102c81:	72 e2                	jb     102c65 <memchr+0x13>
		if (*(const unsigned char *) s == (unsigned char) c)
			return (void *) s;
	return NULL;
  102c83:	b8 00 00 00 00       	mov    $0x0,%eax
}
  102c88:	c9                   	leave  
  102c89:	c3                   	ret    
  102c8a:	90                   	nop
  102c8b:	90                   	nop
  102c8c:	90                   	nop
  102c8d:	90                   	nop
  102c8e:	90                   	nop
  102c8f:	90                   	nop

00102c90 <__udivdi3>:
  102c90:	83 ec 1c             	sub    $0x1c,%esp
  102c93:	8b 44 24 2c          	mov    0x2c(%esp),%eax
  102c97:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  102c9b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  102c9f:	8b 6c 24 20          	mov    0x20(%esp),%ebp
  102ca3:	89 74 24 10          	mov    %esi,0x10(%esp)
  102ca7:	8b 74 24 24          	mov    0x24(%esp),%esi
  102cab:	85 c0                	test   %eax,%eax
  102cad:	89 7c 24 14          	mov    %edi,0x14(%esp)
  102cb1:	89 cf                	mov    %ecx,%edi
  102cb3:	89 6c 24 04          	mov    %ebp,0x4(%esp)
  102cb7:	75 37                	jne    102cf0 <__udivdi3+0x60>
  102cb9:	39 f1                	cmp    %esi,%ecx
  102cbb:	77 73                	ja     102d30 <__udivdi3+0xa0>
  102cbd:	85 c9                	test   %ecx,%ecx
  102cbf:	75 0b                	jne    102ccc <__udivdi3+0x3c>
  102cc1:	b8 01 00 00 00       	mov    $0x1,%eax
  102cc6:	31 d2                	xor    %edx,%edx
  102cc8:	f7 f1                	div    %ecx
  102cca:	89 c1                	mov    %eax,%ecx
  102ccc:	89 f0                	mov    %esi,%eax
  102cce:	31 d2                	xor    %edx,%edx
  102cd0:	f7 f1                	div    %ecx
  102cd2:	89 c6                	mov    %eax,%esi
  102cd4:	89 e8                	mov    %ebp,%eax
  102cd6:	f7 f1                	div    %ecx
  102cd8:	89 f2                	mov    %esi,%edx
  102cda:	8b 74 24 10          	mov    0x10(%esp),%esi
  102cde:	8b 7c 24 14          	mov    0x14(%esp),%edi
  102ce2:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  102ce6:	83 c4 1c             	add    $0x1c,%esp
  102ce9:	c3                   	ret    
  102cea:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  102cf0:	39 f0                	cmp    %esi,%eax
  102cf2:	77 24                	ja     102d18 <__udivdi3+0x88>
  102cf4:	0f bd e8             	bsr    %eax,%ebp
  102cf7:	83 f5 1f             	xor    $0x1f,%ebp
  102cfa:	75 4c                	jne    102d48 <__udivdi3+0xb8>
  102cfc:	31 d2                	xor    %edx,%edx
  102cfe:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
  102d02:	0f 86 b0 00 00 00    	jbe    102db8 <__udivdi3+0x128>
  102d08:	39 f0                	cmp    %esi,%eax
  102d0a:	0f 82 a8 00 00 00    	jb     102db8 <__udivdi3+0x128>
  102d10:	31 c0                	xor    %eax,%eax
  102d12:	eb c6                	jmp    102cda <__udivdi3+0x4a>
  102d14:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102d18:	31 d2                	xor    %edx,%edx
  102d1a:	31 c0                	xor    %eax,%eax
  102d1c:	8b 74 24 10          	mov    0x10(%esp),%esi
  102d20:	8b 7c 24 14          	mov    0x14(%esp),%edi
  102d24:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  102d28:	83 c4 1c             	add    $0x1c,%esp
  102d2b:	c3                   	ret    
  102d2c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102d30:	89 e8                	mov    %ebp,%eax
  102d32:	89 f2                	mov    %esi,%edx
  102d34:	f7 f1                	div    %ecx
  102d36:	31 d2                	xor    %edx,%edx
  102d38:	8b 74 24 10          	mov    0x10(%esp),%esi
  102d3c:	8b 7c 24 14          	mov    0x14(%esp),%edi
  102d40:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  102d44:	83 c4 1c             	add    $0x1c,%esp
  102d47:	c3                   	ret    
  102d48:	89 e9                	mov    %ebp,%ecx
  102d4a:	89 fa                	mov    %edi,%edx
  102d4c:	d3 e0                	shl    %cl,%eax
  102d4e:	89 44 24 08          	mov    %eax,0x8(%esp)
  102d52:	b8 20 00 00 00       	mov    $0x20,%eax
  102d57:	29 e8                	sub    %ebp,%eax
  102d59:	89 c1                	mov    %eax,%ecx
  102d5b:	d3 ea                	shr    %cl,%edx
  102d5d:	8b 4c 24 08          	mov    0x8(%esp),%ecx
  102d61:	09 ca                	or     %ecx,%edx
  102d63:	89 e9                	mov    %ebp,%ecx
  102d65:	d3 e7                	shl    %cl,%edi
  102d67:	89 c1                	mov    %eax,%ecx
  102d69:	89 54 24 0c          	mov    %edx,0xc(%esp)
  102d6d:	89 f2                	mov    %esi,%edx
  102d6f:	d3 ea                	shr    %cl,%edx
  102d71:	89 e9                	mov    %ebp,%ecx
  102d73:	89 14 24             	mov    %edx,(%esp)
  102d76:	8b 54 24 04          	mov    0x4(%esp),%edx
  102d7a:	d3 e6                	shl    %cl,%esi
  102d7c:	89 c1                	mov    %eax,%ecx
  102d7e:	d3 ea                	shr    %cl,%edx
  102d80:	89 d0                	mov    %edx,%eax
  102d82:	09 f0                	or     %esi,%eax
  102d84:	8b 34 24             	mov    (%esp),%esi
  102d87:	89 f2                	mov    %esi,%edx
  102d89:	f7 74 24 0c          	divl   0xc(%esp)
  102d8d:	89 d6                	mov    %edx,%esi
  102d8f:	89 44 24 08          	mov    %eax,0x8(%esp)
  102d93:	f7 e7                	mul    %edi
  102d95:	39 d6                	cmp    %edx,%esi
  102d97:	72 2f                	jb     102dc8 <__udivdi3+0x138>
  102d99:	8b 7c 24 04          	mov    0x4(%esp),%edi
  102d9d:	89 e9                	mov    %ebp,%ecx
  102d9f:	d3 e7                	shl    %cl,%edi
  102da1:	39 c7                	cmp    %eax,%edi
  102da3:	73 04                	jae    102da9 <__udivdi3+0x119>
  102da5:	39 d6                	cmp    %edx,%esi
  102da7:	74 1f                	je     102dc8 <__udivdi3+0x138>
  102da9:	8b 44 24 08          	mov    0x8(%esp),%eax
  102dad:	31 d2                	xor    %edx,%edx
  102daf:	e9 26 ff ff ff       	jmp    102cda <__udivdi3+0x4a>
  102db4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102db8:	b8 01 00 00 00       	mov    $0x1,%eax
  102dbd:	e9 18 ff ff ff       	jmp    102cda <__udivdi3+0x4a>
  102dc2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  102dc8:	8b 44 24 08          	mov    0x8(%esp),%eax
  102dcc:	31 d2                	xor    %edx,%edx
  102dce:	83 e8 01             	sub    $0x1,%eax
  102dd1:	8b 74 24 10          	mov    0x10(%esp),%esi
  102dd5:	8b 7c 24 14          	mov    0x14(%esp),%edi
  102dd9:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  102ddd:	83 c4 1c             	add    $0x1c,%esp
  102de0:	c3                   	ret    
  102de1:	90                   	nop
  102de2:	90                   	nop
  102de3:	90                   	nop
  102de4:	90                   	nop
  102de5:	90                   	nop
  102de6:	90                   	nop
  102de7:	90                   	nop
  102de8:	90                   	nop
  102de9:	90                   	nop
  102dea:	90                   	nop
  102deb:	90                   	nop
  102dec:	90                   	nop
  102ded:	90                   	nop
  102dee:	90                   	nop
  102def:	90                   	nop

00102df0 <__umoddi3>:
  102df0:	83 ec 1c             	sub    $0x1c,%esp
  102df3:	8b 54 24 2c          	mov    0x2c(%esp),%edx
  102df7:	8b 44 24 20          	mov    0x20(%esp),%eax
  102dfb:	89 74 24 10          	mov    %esi,0x10(%esp)
  102dff:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  102e03:	8b 74 24 24          	mov    0x24(%esp),%esi
  102e07:	85 d2                	test   %edx,%edx
  102e09:	89 7c 24 14          	mov    %edi,0x14(%esp)
  102e0d:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  102e11:	89 cf                	mov    %ecx,%edi
  102e13:	89 c5                	mov    %eax,%ebp
  102e15:	89 44 24 08          	mov    %eax,0x8(%esp)
  102e19:	89 34 24             	mov    %esi,(%esp)
  102e1c:	75 22                	jne    102e40 <__umoddi3+0x50>
  102e1e:	39 f1                	cmp    %esi,%ecx
  102e20:	76 56                	jbe    102e78 <__umoddi3+0x88>
  102e22:	89 f2                	mov    %esi,%edx
  102e24:	f7 f1                	div    %ecx
  102e26:	89 d0                	mov    %edx,%eax
  102e28:	31 d2                	xor    %edx,%edx
  102e2a:	8b 74 24 10          	mov    0x10(%esp),%esi
  102e2e:	8b 7c 24 14          	mov    0x14(%esp),%edi
  102e32:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  102e36:	83 c4 1c             	add    $0x1c,%esp
  102e39:	c3                   	ret    
  102e3a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  102e40:	39 f2                	cmp    %esi,%edx
  102e42:	77 54                	ja     102e98 <__umoddi3+0xa8>
  102e44:	0f bd c2             	bsr    %edx,%eax
  102e47:	83 f0 1f             	xor    $0x1f,%eax
  102e4a:	89 44 24 04          	mov    %eax,0x4(%esp)
  102e4e:	75 60                	jne    102eb0 <__umoddi3+0xc0>
  102e50:	39 e9                	cmp    %ebp,%ecx
  102e52:	0f 87 08 01 00 00    	ja     102f60 <__umoddi3+0x170>
  102e58:	29 cd                	sub    %ecx,%ebp
  102e5a:	19 d6                	sbb    %edx,%esi
  102e5c:	89 34 24             	mov    %esi,(%esp)
  102e5f:	8b 14 24             	mov    (%esp),%edx
  102e62:	89 e8                	mov    %ebp,%eax
  102e64:	8b 74 24 10          	mov    0x10(%esp),%esi
  102e68:	8b 7c 24 14          	mov    0x14(%esp),%edi
  102e6c:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  102e70:	83 c4 1c             	add    $0x1c,%esp
  102e73:	c3                   	ret    
  102e74:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102e78:	85 c9                	test   %ecx,%ecx
  102e7a:	75 0b                	jne    102e87 <__umoddi3+0x97>
  102e7c:	b8 01 00 00 00       	mov    $0x1,%eax
  102e81:	31 d2                	xor    %edx,%edx
  102e83:	f7 f1                	div    %ecx
  102e85:	89 c1                	mov    %eax,%ecx
  102e87:	89 f0                	mov    %esi,%eax
  102e89:	31 d2                	xor    %edx,%edx
  102e8b:	f7 f1                	div    %ecx
  102e8d:	89 e8                	mov    %ebp,%eax
  102e8f:	f7 f1                	div    %ecx
  102e91:	eb 93                	jmp    102e26 <__umoddi3+0x36>
  102e93:	90                   	nop
  102e94:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102e98:	89 f2                	mov    %esi,%edx
  102e9a:	8b 74 24 10          	mov    0x10(%esp),%esi
  102e9e:	8b 7c 24 14          	mov    0x14(%esp),%edi
  102ea2:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  102ea6:	83 c4 1c             	add    $0x1c,%esp
  102ea9:	c3                   	ret    
  102eaa:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  102eb0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  102eb5:	bd 20 00 00 00       	mov    $0x20,%ebp
  102eba:	89 f8                	mov    %edi,%eax
  102ebc:	2b 6c 24 04          	sub    0x4(%esp),%ebp
  102ec0:	d3 e2                	shl    %cl,%edx
  102ec2:	89 e9                	mov    %ebp,%ecx
  102ec4:	d3 e8                	shr    %cl,%eax
  102ec6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  102ecb:	09 d0                	or     %edx,%eax
  102ecd:	89 f2                	mov    %esi,%edx
  102ecf:	89 04 24             	mov    %eax,(%esp)
  102ed2:	8b 44 24 08          	mov    0x8(%esp),%eax
  102ed6:	d3 e7                	shl    %cl,%edi
  102ed8:	89 e9                	mov    %ebp,%ecx
  102eda:	d3 ea                	shr    %cl,%edx
  102edc:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  102ee1:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  102ee5:	d3 e6                	shl    %cl,%esi
  102ee7:	89 e9                	mov    %ebp,%ecx
  102ee9:	d3 e8                	shr    %cl,%eax
  102eeb:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  102ef0:	09 f0                	or     %esi,%eax
  102ef2:	8b 74 24 08          	mov    0x8(%esp),%esi
  102ef6:	f7 34 24             	divl   (%esp)
  102ef9:	d3 e6                	shl    %cl,%esi
  102efb:	89 74 24 08          	mov    %esi,0x8(%esp)
  102eff:	89 d6                	mov    %edx,%esi
  102f01:	f7 e7                	mul    %edi
  102f03:	39 d6                	cmp    %edx,%esi
  102f05:	89 c7                	mov    %eax,%edi
  102f07:	89 d1                	mov    %edx,%ecx
  102f09:	72 41                	jb     102f4c <__umoddi3+0x15c>
  102f0b:	39 44 24 08          	cmp    %eax,0x8(%esp)
  102f0f:	72 37                	jb     102f48 <__umoddi3+0x158>
  102f11:	8b 44 24 08          	mov    0x8(%esp),%eax
  102f15:	29 f8                	sub    %edi,%eax
  102f17:	19 ce                	sbb    %ecx,%esi
  102f19:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  102f1e:	89 f2                	mov    %esi,%edx
  102f20:	d3 e8                	shr    %cl,%eax
  102f22:	89 e9                	mov    %ebp,%ecx
  102f24:	d3 e2                	shl    %cl,%edx
  102f26:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  102f2b:	09 d0                	or     %edx,%eax
  102f2d:	89 f2                	mov    %esi,%edx
  102f2f:	d3 ea                	shr    %cl,%edx
  102f31:	8b 74 24 10          	mov    0x10(%esp),%esi
  102f35:	8b 7c 24 14          	mov    0x14(%esp),%edi
  102f39:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  102f3d:	83 c4 1c             	add    $0x1c,%esp
  102f40:	c3                   	ret    
  102f41:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  102f48:	39 d6                	cmp    %edx,%esi
  102f4a:	75 c5                	jne    102f11 <__umoddi3+0x121>
  102f4c:	89 d1                	mov    %edx,%ecx
  102f4e:	89 c7                	mov    %eax,%edi
  102f50:	2b 7c 24 0c          	sub    0xc(%esp),%edi
  102f54:	1b 0c 24             	sbb    (%esp),%ecx
  102f57:	eb b8                	jmp    102f11 <__umoddi3+0x121>
  102f59:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  102f60:	39 f2                	cmp    %esi,%edx
  102f62:	0f 82 f0 fe ff ff    	jb     102e58 <__umoddi3+0x68>
  102f68:	e9 f2 fe ff ff       	jmp    102e5f <__umoddi3+0x6f>
