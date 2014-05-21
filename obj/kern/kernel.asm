
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
  100055:	c7 44 24 0c 00 31 10 	movl   $0x103100,0xc(%esp)
  10005c:	00 
  10005d:	c7 44 24 08 16 31 10 	movl   $0x103116,0x8(%esp)
  100064:	00 
  100065:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  10006c:	00 
  10006d:	c7 04 24 2b 31 10 00 	movl   $0x10312b,(%esp)
  100074:	e8 f7 02 00 00       	call   100370 <debug_panic>
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
  10009d:	83 ec 28             	sub    $0x28,%esp
	extern char start[], edata[], end[];

	// Before anything else, complete the ELF loading process.
	// Clear all uninitialized global data (BSS) in our program,
	// ensuring that all static/global variables start out zero.
	if (cpu_onboot())
  1000a0:	e8 dd ff ff ff       	call   100082 <cpu_onboot>
  1000a5:	85 c0                	test   %eax,%eax
  1000a7:	74 28                	je     1000d1 <init+0x37>
		memset(edata, 0, end - edata);
  1000a9:	ba ec 9f 30 00       	mov    $0x309fec,%edx
  1000ae:	b8 70 85 10 00       	mov    $0x108570,%eax
  1000b3:	89 d1                	mov    %edx,%ecx
  1000b5:	29 c1                	sub    %eax,%ecx
  1000b7:	89 c8                	mov    %ecx,%eax
  1000b9:	89 44 24 08          	mov    %eax,0x8(%esp)
  1000bd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1000c4:	00 
  1000c5:	c7 04 24 70 85 10 00 	movl   $0x108570,(%esp)
  1000cc:	e8 3c 2b 00 00       	call   102c0d <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
  1000d1:	e8 26 02 00 00       	call   1002fc <cons_init>

	// Lab 1: test cprintf and debug_trace
	int x = 1, y = 3, z = 4;
  1000d6:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
  1000dd:	c7 45 f4 03 00 00 00 	movl   $0x3,-0xc(%ebp)
  1000e4:	c7 45 f0 04 00 00 00 	movl   $0x4,-0x10(%ebp)
	cprintf("x's address is %x", &x);
  1000eb:	8d 45 ec             	lea    -0x14(%ebp),%eax
  1000ee:	89 44 24 04          	mov    %eax,0x4(%esp)
  1000f2:	c7 04 24 38 31 10 00 	movl   $0x103138,(%esp)
  1000f9:	e8 2a 29 00 00       	call   102a28 <cprintf>
    cprintf("1234 decimal is %o octal!\n", 1234);
  1000fe:	c7 44 24 04 d2 04 00 	movl   $0x4d2,0x4(%esp)
  100105:	00 
  100106:	c7 04 24 4a 31 10 00 	movl   $0x10314a,(%esp)
  10010d:	e8 16 29 00 00       	call   102a28 <cprintf>
    //cprintf("x %d, y %x, z %d\n", x, y, z);
//  unsigned int i = 0x00646c72;
//  cprintf("H%x Wo%s", 57616, &i);
//  cprintf("x=%d y=%d", 3);

	debug_check();
  100112:	e8 f2 04 00 00       	call   100609 <debug_check>

	// Initialize and load the bootstrap CPU's GDT, TSS, and IDT.
	cpu_init();
  100117:	e8 b2 0f 00 00       	call   1010ce <cpu_init>
	trap_init();
  10011c:	e8 33 13 00 00       	call   101454 <trap_init>

	// Physical memory detection/initialization.
	// Can't call mem_alloc until after we do this!
	mem_init();
  100121:	e8 a0 07 00 00       	call   1008c6 <mem_init>
		ss : CPU_GDT_UDATA|3,
		eflags : FL_IOPL_3, //make the processor believe the tf be created in usermode
		eip : (uint32_t)user,
		esp : (uint32_t)&user_stack[PAGESIZE],
	};
	trap_return(&ttf);
  100126:	c7 04 24 00 60 10 00 	movl   $0x106000,(%esp)
  10012d:	e8 ee 19 00 00       	call   101b20 <trap_return>

00100132 <user>:
// This is the first function that gets run in user mode (ring 3).
// It acts as PIOS's "root process",
// of which all other processes are descendants.
void
user()
{
  100132:	55                   	push   %ebp
  100133:	89 e5                	mov    %esp,%ebp
  100135:	53                   	push   %ebx
  100136:	83 ec 24             	sub    $0x24,%esp
	cprintf("in user()\n");
  100139:	c7 04 24 65 31 10 00 	movl   $0x103165,(%esp)
  100140:	e8 e3 28 00 00       	call   102a28 <cprintf>

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100145:	89 e3                	mov    %esp,%ebx
  100147:	89 5d f4             	mov    %ebx,-0xc(%ebp)
        return esp;
  10014a:	8b 45 f4             	mov    -0xc(%ebp),%eax
	assert(read_esp() > (uint32_t) &user_stack[0]);
  10014d:	89 c2                	mov    %eax,%edx
  10014f:	b8 80 85 10 00       	mov    $0x108580,%eax
  100154:	39 c2                	cmp    %eax,%edx
  100156:	77 24                	ja     10017c <user+0x4a>
  100158:	c7 44 24 0c 70 31 10 	movl   $0x103170,0xc(%esp)
  10015f:	00 
  100160:	c7 44 24 08 16 31 10 	movl   $0x103116,0x8(%esp)
  100167:	00 
  100168:	c7 44 24 04 63 00 00 	movl   $0x63,0x4(%esp)
  10016f:	00 
  100170:	c7 04 24 97 31 10 00 	movl   $0x103197,(%esp)
  100177:	e8 f4 01 00 00       	call   100370 <debug_panic>

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10017c:	89 e3                	mov    %esp,%ebx
  10017e:	89 5d f0             	mov    %ebx,-0x10(%ebp)
        return esp;
  100181:	8b 45 f0             	mov    -0x10(%ebp),%eax
	assert(read_esp() < (uint32_t) &user_stack[sizeof(user_stack)]);
  100184:	89 c2                	mov    %eax,%edx
  100186:	b8 80 95 10 00       	mov    $0x109580,%eax
  10018b:	39 c2                	cmp    %eax,%edx
  10018d:	72 24                	jb     1001b3 <user+0x81>
  10018f:	c7 44 24 0c a4 31 10 	movl   $0x1031a4,0xc(%esp)
  100196:	00 
  100197:	c7 44 24 08 16 31 10 	movl   $0x103116,0x8(%esp)
  10019e:	00 
  10019f:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  1001a6:	00 
  1001a7:	c7 04 24 97 31 10 00 	movl   $0x103197,(%esp)
  1001ae:	e8 bd 01 00 00       	call   100370 <debug_panic>

	// Check that we're in user mode and can handle traps from there.
	trap_check_user();
  1001b3:	e8 cb 15 00 00       	call   101783 <trap_check_user>

	done();
  1001b8:	e8 00 00 00 00       	call   1001bd <done>

001001bd <done>:
// it just puts the processor into an infinite loop.
// We make this a function so that we can set a breakpoints on it.
// Our grade scripts use this breakpoint to know when to stop QEMU.
void gcc_noreturn
done()
{
  1001bd:	55                   	push   %ebp
  1001be:	89 e5                	mov    %esp,%ebp
	while (1)
		;	// just spin
  1001c0:	eb fe                	jmp    1001c0 <done+0x3>
  1001c2:	90                   	nop
  1001c3:	90                   	nop

001001c4 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  1001c4:	55                   	push   %ebp
  1001c5:	89 e5                	mov    %esp,%ebp
  1001c7:	53                   	push   %ebx
  1001c8:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1001cb:	89 e3                	mov    %esp,%ebx
  1001cd:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  1001d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1001d3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1001d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1001d9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1001de:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  1001e1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1001e4:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  1001ea:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1001ef:	74 24                	je     100215 <cpu_cur+0x51>
  1001f1:	c7 44 24 0c dc 31 10 	movl   $0x1031dc,0xc(%esp)
  1001f8:	00 
  1001f9:	c7 44 24 08 f2 31 10 	movl   $0x1031f2,0x8(%esp)
  100200:	00 
  100201:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  100208:	00 
  100209:	c7 04 24 07 32 10 00 	movl   $0x103207,(%esp)
  100210:	e8 5b 01 00 00       	call   100370 <debug_panic>
	return c;
  100215:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  100218:	83 c4 24             	add    $0x24,%esp
  10021b:	5b                   	pop    %ebx
  10021c:	5d                   	pop    %ebp
  10021d:	c3                   	ret    

0010021e <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  10021e:	55                   	push   %ebp
  10021f:	89 e5                	mov    %esp,%ebp
  100221:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  100224:	e8 9b ff ff ff       	call   1001c4 <cpu_cur>
  100229:	3d 00 70 10 00       	cmp    $0x107000,%eax
  10022e:	0f 94 c0             	sete   %al
  100231:	0f b6 c0             	movzbl %al,%eax
}
  100234:	c9                   	leave  
  100235:	c3                   	ret    

00100236 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
void
cons_intr(int (*proc)(void))
{
  100236:	55                   	push   %ebp
  100237:	89 e5                	mov    %esp,%ebp
  100239:	83 ec 18             	sub    $0x18,%esp
	int c;

	while ((c = (*proc)()) != -1) {
  10023c:	eb 35                	jmp    100273 <cons_intr+0x3d>
		if (c == 0)
  10023e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  100242:	74 2e                	je     100272 <cons_intr+0x3c>
			continue;
		cons.buf[cons.wpos++] = c;
  100244:	a1 84 97 10 00       	mov    0x109784,%eax
  100249:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10024c:	88 90 80 95 10 00    	mov    %dl,0x109580(%eax)
  100252:	83 c0 01             	add    $0x1,%eax
  100255:	a3 84 97 10 00       	mov    %eax,0x109784
		if (cons.wpos == CONSBUFSIZE)
  10025a:	a1 84 97 10 00       	mov    0x109784,%eax
  10025f:	3d 00 02 00 00       	cmp    $0x200,%eax
  100264:	75 0d                	jne    100273 <cons_intr+0x3d>
			cons.wpos = 0;
  100266:	c7 05 84 97 10 00 00 	movl   $0x0,0x109784
  10026d:	00 00 00 
  100270:	eb 01                	jmp    100273 <cons_intr+0x3d>
{
	int c;

	while ((c = (*proc)()) != -1) {
		if (c == 0)
			continue;
  100272:	90                   	nop
void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
  100273:	8b 45 08             	mov    0x8(%ebp),%eax
  100276:	ff d0                	call   *%eax
  100278:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10027b:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
  10027f:	75 bd                	jne    10023e <cons_intr+0x8>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
  100281:	c9                   	leave  
  100282:	c3                   	ret    

00100283 <cons_getc>:

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
  100283:	55                   	push   %ebp
  100284:	89 e5                	mov    %esp,%ebp
  100286:	83 ec 18             	sub    $0x18,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
  100289:	e8 00 1e 00 00       	call   10208e <serial_intr>
	kbd_intr();
  10028e:	e8 27 1d 00 00       	call   101fba <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
  100293:	8b 15 80 97 10 00    	mov    0x109780,%edx
  100299:	a1 84 97 10 00       	mov    0x109784,%eax
  10029e:	39 c2                	cmp    %eax,%edx
  1002a0:	74 35                	je     1002d7 <cons_getc+0x54>
		c = cons.buf[cons.rpos++];
  1002a2:	a1 80 97 10 00       	mov    0x109780,%eax
  1002a7:	0f b6 90 80 95 10 00 	movzbl 0x109580(%eax),%edx
  1002ae:	0f b6 d2             	movzbl %dl,%edx
  1002b1:	89 55 f4             	mov    %edx,-0xc(%ebp)
  1002b4:	83 c0 01             	add    $0x1,%eax
  1002b7:	a3 80 97 10 00       	mov    %eax,0x109780
		if (cons.rpos == CONSBUFSIZE)
  1002bc:	a1 80 97 10 00       	mov    0x109780,%eax
  1002c1:	3d 00 02 00 00       	cmp    $0x200,%eax
  1002c6:	75 0a                	jne    1002d2 <cons_getc+0x4f>
			cons.rpos = 0;
  1002c8:	c7 05 80 97 10 00 00 	movl   $0x0,0x109780
  1002cf:	00 00 00 
		return c;
  1002d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1002d5:	eb 05                	jmp    1002dc <cons_getc+0x59>
	}
	return 0;
  1002d7:	b8 00 00 00 00       	mov    $0x0,%eax
}
  1002dc:	c9                   	leave  
  1002dd:	c3                   	ret    

001002de <cons_putc>:

// output a character to the console
static void
cons_putc(int c)
{
  1002de:	55                   	push   %ebp
  1002df:	89 e5                	mov    %esp,%ebp
  1002e1:	83 ec 18             	sub    $0x18,%esp
	serial_putc(c);
  1002e4:	8b 45 08             	mov    0x8(%ebp),%eax
  1002e7:	89 04 24             	mov    %eax,(%esp)
  1002ea:	e8 bc 1d 00 00       	call   1020ab <serial_putc>
	video_putc(c);
  1002ef:	8b 45 08             	mov    0x8(%ebp),%eax
  1002f2:	89 04 24             	mov    %eax,(%esp)
  1002f5:	e8 13 19 00 00       	call   101c0d <video_putc>
}
  1002fa:	c9                   	leave  
  1002fb:	c3                   	ret    

001002fc <cons_init>:

// initialize the console devices
void
cons_init(void)
{
  1002fc:	55                   	push   %ebp
  1002fd:	89 e5                	mov    %esp,%ebp
  1002ff:	83 ec 18             	sub    $0x18,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  100302:	e8 17 ff ff ff       	call   10021e <cpu_onboot>
  100307:	85 c0                	test   %eax,%eax
  100309:	74 36                	je     100341 <cons_init+0x45>
		return;

	video_init();
  10030b:	e8 20 18 00 00       	call   101b30 <video_init>
	kbd_init();
  100310:	e8 b9 1c 00 00       	call   101fce <kbd_init>
	serial_init();
  100315:	e8 01 1e 00 00       	call   10211b <serial_init>

	if (!serial_exists)
  10031a:	a1 e8 9f 30 00       	mov    0x309fe8,%eax
  10031f:	85 c0                	test   %eax,%eax
  100321:	75 1f                	jne    100342 <cons_init+0x46>
		warn("Serial port does not exist!\n");
  100323:	c7 44 24 08 14 32 10 	movl   $0x103214,0x8(%esp)
  10032a:	00 
  10032b:	c7 44 24 04 69 00 00 	movl   $0x69,0x4(%esp)
  100332:	00 
  100333:	c7 04 24 31 32 10 00 	movl   $0x103231,(%esp)
  10033a:	e8 f7 00 00 00       	call   100436 <debug_warn>
  10033f:	eb 01                	jmp    100342 <cons_init+0x46>
// initialize the console devices
void
cons_init(void)
{
	if (!cpu_onboot())	// only do once, on the boot CPU
		return;
  100341:	90                   	nop
	kbd_init();
	serial_init();

	if (!serial_exists)
		warn("Serial port does not exist!\n");
}
  100342:	c9                   	leave  
  100343:	c3                   	ret    

00100344 <cputs>:


// `High'-level console I/O.  Used by readline and cprintf.
void
cputs(const char *str)
{
  100344:	55                   	push   %ebp
  100345:	89 e5                	mov    %esp,%ebp
  100347:	83 ec 18             	sub    $0x18,%esp
	char ch;
	while (*str)
  10034a:	eb 15                	jmp    100361 <cputs+0x1d>
		cons_putc(*str++);
  10034c:	8b 45 08             	mov    0x8(%ebp),%eax
  10034f:	0f b6 00             	movzbl (%eax),%eax
  100352:	0f be c0             	movsbl %al,%eax
  100355:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  100359:	89 04 24             	mov    %eax,(%esp)
  10035c:	e8 7d ff ff ff       	call   1002de <cons_putc>
// `High'-level console I/O.  Used by readline and cprintf.
void
cputs(const char *str)
{
	char ch;
	while (*str)
  100361:	8b 45 08             	mov    0x8(%ebp),%eax
  100364:	0f b6 00             	movzbl (%eax),%eax
  100367:	84 c0                	test   %al,%al
  100369:	75 e1                	jne    10034c <cputs+0x8>
		cons_putc(*str++);
}
  10036b:	c9                   	leave  
  10036c:	c3                   	ret    
  10036d:	90                   	nop
  10036e:	90                   	nop
  10036f:	90                   	nop

00100370 <debug_panic>:

// Panic is called on unresolvable fatal errors.
// It prints "panic: mesg", and then enters the kernel monitor.
void
debug_panic(const char *file, int line, const char *fmt,...)
{
  100370:	55                   	push   %ebp
  100371:	89 e5                	mov    %esp,%ebp
  100373:	53                   	push   %ebx
  100374:	83 ec 54             	sub    $0x54,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  100377:	66 8c cb             	mov    %cs,%bx
  10037a:	66 89 5d ee          	mov    %bx,-0x12(%ebp)
        return cs;
  10037e:	0f b7 45 ee          	movzwl -0x12(%ebp),%eax
	va_list ap;
	int i;

	// Avoid infinite recursion if we're panicking from kernel mode.
	if ((read_cs() & 3) == 0) {
  100382:	0f b7 c0             	movzwl %ax,%eax
  100385:	83 e0 03             	and    $0x3,%eax
  100388:	85 c0                	test   %eax,%eax
  10038a:	75 15                	jne    1003a1 <debug_panic+0x31>
		if (panicstr)
  10038c:	a1 88 97 10 00       	mov    0x109788,%eax
  100391:	85 c0                	test   %eax,%eax
  100393:	0f 85 97 00 00 00    	jne    100430 <debug_panic+0xc0>
			goto dead;
		panicstr = fmt;
  100399:	8b 45 10             	mov    0x10(%ebp),%eax
  10039c:	a3 88 97 10 00       	mov    %eax,0x109788
	}

	// First print the requested message
	va_start(ap, fmt);
  1003a1:	8d 45 10             	lea    0x10(%ebp),%eax
  1003a4:	83 c0 04             	add    $0x4,%eax
  1003a7:	89 45 f0             	mov    %eax,-0x10(%ebp)
	cprintf("kernel panic at %s:%d: ", file, line);
  1003aa:	8b 45 0c             	mov    0xc(%ebp),%eax
  1003ad:	89 44 24 08          	mov    %eax,0x8(%esp)
  1003b1:	8b 45 08             	mov    0x8(%ebp),%eax
  1003b4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1003b8:	c7 04 24 40 32 10 00 	movl   $0x103240,(%esp)
  1003bf:	e8 64 26 00 00       	call   102a28 <cprintf>
	vcprintf(fmt, ap);
  1003c4:	8b 45 10             	mov    0x10(%ebp),%eax
  1003c7:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1003ca:	89 54 24 04          	mov    %edx,0x4(%esp)
  1003ce:	89 04 24             	mov    %eax,(%esp)
  1003d1:	e8 ea 25 00 00       	call   1029c0 <vcprintf>
	cprintf("\n");
  1003d6:	c7 04 24 58 32 10 00 	movl   $0x103258,(%esp)
  1003dd:	e8 46 26 00 00       	call   102a28 <cprintf>

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  1003e2:	89 eb                	mov    %ebp,%ebx
  1003e4:	89 5d e8             	mov    %ebx,-0x18(%ebp)
        return ebp;
  1003e7:	8b 45 e8             	mov    -0x18(%ebp),%eax
	va_end(ap);

	// Then print a backtrace of the kernel call chain
	uint32_t eips[DEBUG_TRACEFRAMES];
	debug_trace(read_ebp(), eips);
  1003ea:	8d 55 c0             	lea    -0x40(%ebp),%edx
  1003ed:	89 54 24 04          	mov    %edx,0x4(%esp)
  1003f1:	89 04 24             	mov    %eax,(%esp)
  1003f4:	e8 86 00 00 00       	call   10047f <debug_trace>
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
  1003f9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  100400:	eb 1b                	jmp    10041d <debug_panic+0xad>
		cprintf("  from %08x\n", eips[i]);
  100402:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100405:	8b 44 85 c0          	mov    -0x40(%ebp,%eax,4),%eax
  100409:	89 44 24 04          	mov    %eax,0x4(%esp)
  10040d:	c7 04 24 5a 32 10 00 	movl   $0x10325a,(%esp)
  100414:	e8 0f 26 00 00       	call   102a28 <cprintf>
	va_end(ap);

	// Then print a backtrace of the kernel call chain
	uint32_t eips[DEBUG_TRACEFRAMES];
	debug_trace(read_ebp(), eips);
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
  100419:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  10041d:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  100421:	7f 0e                	jg     100431 <debug_panic+0xc1>
  100423:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100426:	8b 44 85 c0          	mov    -0x40(%ebp,%eax,4),%eax
  10042a:	85 c0                	test   %eax,%eax
  10042c:	75 d4                	jne    100402 <debug_panic+0x92>
  10042e:	eb 01                	jmp    100431 <debug_panic+0xc1>
	int i;

	// Avoid infinite recursion if we're panicking from kernel mode.
	if ((read_cs() & 3) == 0) {
		if (panicstr)
			goto dead;
  100430:	90                   	nop
	debug_trace(read_ebp(), eips);
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
		cprintf("  from %08x\n", eips[i]);

dead:
	done();		// enter infinite loop (see kern/init.c)
  100431:	e8 87 fd ff ff       	call   1001bd <done>

00100436 <debug_warn>:
}

/* like panic, but don't */
void
debug_warn(const char *file, int line, const char *fmt,...)
{
  100436:	55                   	push   %ebp
  100437:	89 e5                	mov    %esp,%ebp
  100439:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
  10043c:	8d 45 10             	lea    0x10(%ebp),%eax
  10043f:	83 c0 04             	add    $0x4,%eax
  100442:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("kernel warning at %s:%d: ", file, line);
  100445:	8b 45 0c             	mov    0xc(%ebp),%eax
  100448:	89 44 24 08          	mov    %eax,0x8(%esp)
  10044c:	8b 45 08             	mov    0x8(%ebp),%eax
  10044f:	89 44 24 04          	mov    %eax,0x4(%esp)
  100453:	c7 04 24 67 32 10 00 	movl   $0x103267,(%esp)
  10045a:	e8 c9 25 00 00       	call   102a28 <cprintf>
	vcprintf(fmt, ap);
  10045f:	8b 45 10             	mov    0x10(%ebp),%eax
  100462:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100465:	89 54 24 04          	mov    %edx,0x4(%esp)
  100469:	89 04 24             	mov    %eax,(%esp)
  10046c:	e8 4f 25 00 00       	call   1029c0 <vcprintf>
	cprintf("\n");
  100471:	c7 04 24 58 32 10 00 	movl   $0x103258,(%esp)
  100478:	e8 ab 25 00 00       	call   102a28 <cprintf>
	va_end(ap);
}
  10047d:	c9                   	leave  
  10047e:	c3                   	ret    

0010047f <debug_trace>:

// Record the current call stack in eips[] by following the %ebp chain.
void gcc_noinline
debug_trace(uint32_t ebp, uint32_t eips[DEBUG_TRACEFRAMES])
{
  10047f:	55                   	push   %ebp
  100480:	89 e5                	mov    %esp,%ebp
  100482:	56                   	push   %esi
  100483:	53                   	push   %ebx
  100484:	83 ec 30             	sub    $0x30,%esp
	uint32_t *trace = (uint32_t *) ebp;
  100487:	8b 45 08             	mov    0x8(%ebp),%eax
  10048a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  	int i;

  	//cprintf("Stack backtrace:\n");
  	for (i = 0; i < DEBUG_TRACEFRAMES && trace; i++) {
  10048d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  100494:	e9 a4 00 00 00       	jmp    10053d <debug_trace+0xbe>
    		cprintf("ebp %08x  ", trace[0]);
  100499:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10049c:	8b 00                	mov    (%eax),%eax
  10049e:	89 44 24 04          	mov    %eax,0x4(%esp)
  1004a2:	c7 04 24 81 32 10 00 	movl   $0x103281,(%esp)
  1004a9:	e8 7a 25 00 00       	call   102a28 <cprintf>
    		cprintf("eip %08x  ", trace[1]);
  1004ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1004b1:	83 c0 04             	add    $0x4,%eax
  1004b4:	8b 00                	mov    (%eax),%eax
  1004b6:	89 44 24 04          	mov    %eax,0x4(%esp)
  1004ba:	c7 04 24 8c 32 10 00 	movl   $0x10328c,(%esp)
  1004c1:	e8 62 25 00 00       	call   102a28 <cprintf>
    		cprintf("args %08x %08x %08x %08x %08x ", trace[2], trace[3], trace[4], trace[5], trace[6]);
  1004c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1004c9:	83 c0 18             	add    $0x18,%eax
  1004cc:	8b 30                	mov    (%eax),%esi
  1004ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1004d1:	83 c0 14             	add    $0x14,%eax
  1004d4:	8b 18                	mov    (%eax),%ebx
  1004d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1004d9:	83 c0 10             	add    $0x10,%eax
  1004dc:	8b 08                	mov    (%eax),%ecx
  1004de:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1004e1:	83 c0 0c             	add    $0xc,%eax
  1004e4:	8b 10                	mov    (%eax),%edx
  1004e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1004e9:	83 c0 08             	add    $0x8,%eax
  1004ec:	8b 00                	mov    (%eax),%eax
  1004ee:	89 74 24 14          	mov    %esi,0x14(%esp)
  1004f2:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  1004f6:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  1004fa:	89 54 24 08          	mov    %edx,0x8(%esp)
  1004fe:	89 44 24 04          	mov    %eax,0x4(%esp)
  100502:	c7 04 24 98 32 10 00 	movl   $0x103298,(%esp)
  100509:	e8 1a 25 00 00       	call   102a28 <cprintf>
    		cprintf("\n"); 
  10050e:	c7 04 24 58 32 10 00 	movl   $0x103258,(%esp)
  100515:	e8 0e 25 00 00       	call   102a28 <cprintf>
		//save eips
    		eips[i] = trace[1];
  10051a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10051d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  100524:	8b 45 0c             	mov    0xc(%ebp),%eax
  100527:	01 c2                	add    %eax,%edx
  100529:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10052c:	8b 40 04             	mov    0x4(%eax),%eax
  10052f:	89 02                	mov    %eax,(%edx)

    		//traceback the call stack using old ebp
    		trace = (uint32_t*)trace[0];  // prev ebp saved at ebp 0
  100531:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100534:	8b 00                	mov    (%eax),%eax
  100536:	89 45 f4             	mov    %eax,-0xc(%ebp)
{
	uint32_t *trace = (uint32_t *) ebp;
  	int i;

  	//cprintf("Stack backtrace:\n");
  	for (i = 0; i < DEBUG_TRACEFRAMES && trace; i++) {
  100539:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  10053d:	83 7d f0 09          	cmpl   $0x9,-0x10(%ebp)
  100541:	7f 25                	jg     100568 <debug_trace+0xe9>
  100543:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  100547:	0f 85 4c ff ff ff    	jne    100499 <debug_trace+0x1a>
    		//traceback the call stack using old ebp
    		trace = (uint32_t*)trace[0];  // prev ebp saved at ebp 0
  	}

  	// set rest eips as 0
  	for (i; i < DEBUG_TRACEFRAMES; i++) {
  10054d:	eb 19                	jmp    100568 <debug_trace+0xe9>
    		eips[i] = 0; 
  10054f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100552:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  100559:	8b 45 0c             	mov    0xc(%ebp),%eax
  10055c:	01 d0                	add    %edx,%eax
  10055e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    		//traceback the call stack using old ebp
    		trace = (uint32_t*)trace[0];  // prev ebp saved at ebp 0
  	}

  	// set rest eips as 0
  	for (i; i < DEBUG_TRACEFRAMES; i++) {
  100564:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  100568:	83 7d f0 09          	cmpl   $0x9,-0x10(%ebp)
  10056c:	7e e1                	jle    10054f <debug_trace+0xd0>
    		eips[i] = 0; 
  	}
	//panic("debug_trace not implemented");
}
  10056e:	83 c4 30             	add    $0x30,%esp
  100571:	5b                   	pop    %ebx
  100572:	5e                   	pop    %esi
  100573:	5d                   	pop    %ebp
  100574:	c3                   	ret    

00100575 <f3>:


static void gcc_noinline f3(int r, uint32_t *e) { debug_trace(read_ebp(), e); }
  100575:	55                   	push   %ebp
  100576:	89 e5                	mov    %esp,%ebp
  100578:	53                   	push   %ebx
  100579:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  10057c:	89 eb                	mov    %ebp,%ebx
  10057e:	89 5d f4             	mov    %ebx,-0xc(%ebp)
        return ebp;
  100581:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100584:	8b 55 0c             	mov    0xc(%ebp),%edx
  100587:	89 54 24 04          	mov    %edx,0x4(%esp)
  10058b:	89 04 24             	mov    %eax,(%esp)
  10058e:	e8 ec fe ff ff       	call   10047f <debug_trace>
  100593:	83 c4 24             	add    $0x24,%esp
  100596:	5b                   	pop    %ebx
  100597:	5d                   	pop    %ebp
  100598:	c3                   	ret    

00100599 <f2>:
static void gcc_noinline f2(int r, uint32_t *e) { r & 2 ? f3(r,e) : f3(r,e); }
  100599:	55                   	push   %ebp
  10059a:	89 e5                	mov    %esp,%ebp
  10059c:	83 ec 18             	sub    $0x18,%esp
  10059f:	8b 45 08             	mov    0x8(%ebp),%eax
  1005a2:	83 e0 02             	and    $0x2,%eax
  1005a5:	85 c0                	test   %eax,%eax
  1005a7:	74 14                	je     1005bd <f2+0x24>
  1005a9:	8b 45 0c             	mov    0xc(%ebp),%eax
  1005ac:	89 44 24 04          	mov    %eax,0x4(%esp)
  1005b0:	8b 45 08             	mov    0x8(%ebp),%eax
  1005b3:	89 04 24             	mov    %eax,(%esp)
  1005b6:	e8 ba ff ff ff       	call   100575 <f3>
  1005bb:	eb 12                	jmp    1005cf <f2+0x36>
  1005bd:	8b 45 0c             	mov    0xc(%ebp),%eax
  1005c0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1005c4:	8b 45 08             	mov    0x8(%ebp),%eax
  1005c7:	89 04 24             	mov    %eax,(%esp)
  1005ca:	e8 a6 ff ff ff       	call   100575 <f3>
  1005cf:	c9                   	leave  
  1005d0:	c3                   	ret    

001005d1 <f1>:
static void gcc_noinline f1(int r, uint32_t *e) { r & 1 ? f2(r,e) : f2(r,e); }
  1005d1:	55                   	push   %ebp
  1005d2:	89 e5                	mov    %esp,%ebp
  1005d4:	83 ec 18             	sub    $0x18,%esp
  1005d7:	8b 45 08             	mov    0x8(%ebp),%eax
  1005da:	83 e0 01             	and    $0x1,%eax
  1005dd:	85 c0                	test   %eax,%eax
  1005df:	74 14                	je     1005f5 <f1+0x24>
  1005e1:	8b 45 0c             	mov    0xc(%ebp),%eax
  1005e4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1005e8:	8b 45 08             	mov    0x8(%ebp),%eax
  1005eb:	89 04 24             	mov    %eax,(%esp)
  1005ee:	e8 a6 ff ff ff       	call   100599 <f2>
  1005f3:	eb 12                	jmp    100607 <f1+0x36>
  1005f5:	8b 45 0c             	mov    0xc(%ebp),%eax
  1005f8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1005fc:	8b 45 08             	mov    0x8(%ebp),%eax
  1005ff:	89 04 24             	mov    %eax,(%esp)
  100602:	e8 92 ff ff ff       	call   100599 <f2>
  100607:	c9                   	leave  
  100608:	c3                   	ret    

00100609 <debug_check>:

// Test the backtrace implementation for correct operation
void
debug_check(void)
{
  100609:	55                   	push   %ebp
  10060a:	89 e5                	mov    %esp,%ebp
  10060c:	81 ec c8 00 00 00    	sub    $0xc8,%esp
	uint32_t eips[4][DEBUG_TRACEFRAMES];
	int r, i;

	// produce several related backtraces...
	for (i = 0; i < 4; i++)
  100612:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  100619:	eb 28                	jmp    100643 <debug_check+0x3a>
		f1(i, eips[i]);
  10061b:	8d 8d 50 ff ff ff    	lea    -0xb0(%ebp),%ecx
  100621:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100624:	89 d0                	mov    %edx,%eax
  100626:	c1 e0 02             	shl    $0x2,%eax
  100629:	01 d0                	add    %edx,%eax
  10062b:	c1 e0 03             	shl    $0x3,%eax
  10062e:	01 c8                	add    %ecx,%eax
  100630:	89 44 24 04          	mov    %eax,0x4(%esp)
  100634:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100637:	89 04 24             	mov    %eax,(%esp)
  10063a:	e8 92 ff ff ff       	call   1005d1 <f1>
{
	uint32_t eips[4][DEBUG_TRACEFRAMES];
	int r, i;

	// produce several related backtraces...
	for (i = 0; i < 4; i++)
  10063f:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  100643:	83 7d f0 03          	cmpl   $0x3,-0x10(%ebp)
  100647:	7e d2                	jle    10061b <debug_check+0x12>
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
  100649:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  100650:	e9 bc 00 00 00       	jmp    100711 <debug_check+0x108>
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
  100655:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  10065c:	e9 a2 00 00 00       	jmp    100703 <debug_check+0xfa>
			assert((eips[r][i] != 0) == (i < 5));
  100661:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100664:	89 d0                	mov    %edx,%eax
  100666:	c1 e0 02             	shl    $0x2,%eax
  100669:	01 d0                	add    %edx,%eax
  10066b:	01 c0                	add    %eax,%eax
  10066d:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100670:	01 d0                	add    %edx,%eax
  100672:	8b 84 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%eax
  100679:	85 c0                	test   %eax,%eax
  10067b:	0f 95 c2             	setne  %dl
  10067e:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
  100682:	0f 9e c0             	setle  %al
  100685:	31 d0                	xor    %edx,%eax
  100687:	84 c0                	test   %al,%al
  100689:	74 24                	je     1006af <debug_check+0xa6>
  10068b:	c7 44 24 0c b7 32 10 	movl   $0x1032b7,0xc(%esp)
  100692:	00 
  100693:	c7 44 24 08 d4 32 10 	movl   $0x1032d4,0x8(%esp)
  10069a:	00 
  10069b:	c7 44 24 04 74 00 00 	movl   $0x74,0x4(%esp)
  1006a2:	00 
  1006a3:	c7 04 24 e9 32 10 00 	movl   $0x1032e9,(%esp)
  1006aa:	e8 c1 fc ff ff       	call   100370 <debug_panic>
			if (i >= 2)
  1006af:	83 7d f0 01          	cmpl   $0x1,-0x10(%ebp)
  1006b3:	7e 4a                	jle    1006ff <debug_check+0xf6>
				assert(eips[r][i] == eips[0][i]);
  1006b5:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1006b8:	89 d0                	mov    %edx,%eax
  1006ba:	c1 e0 02             	shl    $0x2,%eax
  1006bd:	01 d0                	add    %edx,%eax
  1006bf:	01 c0                	add    %eax,%eax
  1006c1:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1006c4:	01 d0                	add    %edx,%eax
  1006c6:	8b 94 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%edx
  1006cd:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1006d0:	8b 84 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%eax
  1006d7:	39 c2                	cmp    %eax,%edx
  1006d9:	74 24                	je     1006ff <debug_check+0xf6>
  1006db:	c7 44 24 0c f6 32 10 	movl   $0x1032f6,0xc(%esp)
  1006e2:	00 
  1006e3:	c7 44 24 08 d4 32 10 	movl   $0x1032d4,0x8(%esp)
  1006ea:	00 
  1006eb:	c7 44 24 04 76 00 00 	movl   $0x76,0x4(%esp)
  1006f2:	00 
  1006f3:	c7 04 24 e9 32 10 00 	movl   $0x1032e9,(%esp)
  1006fa:	e8 71 fc ff ff       	call   100370 <debug_panic>
	for (i = 0; i < 4; i++)
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
  1006ff:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  100703:	83 7d f0 09          	cmpl   $0x9,-0x10(%ebp)
  100707:	0f 8e 54 ff ff ff    	jle    100661 <debug_check+0x58>
	// produce several related backtraces...
	for (i = 0; i < 4; i++)
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
  10070d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  100711:	83 7d f4 03          	cmpl   $0x3,-0xc(%ebp)
  100715:	0f 8e 3a ff ff ff    	jle    100655 <debug_check+0x4c>
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
			assert((eips[r][i] != 0) == (i < 5));
			if (i >= 2)
				assert(eips[r][i] == eips[0][i]);
		}
	assert(eips[0][0] == eips[1][0]);
  10071b:	8b 95 50 ff ff ff    	mov    -0xb0(%ebp),%edx
  100721:	8b 85 78 ff ff ff    	mov    -0x88(%ebp),%eax
  100727:	39 c2                	cmp    %eax,%edx
  100729:	74 24                	je     10074f <debug_check+0x146>
  10072b:	c7 44 24 0c 0f 33 10 	movl   $0x10330f,0xc(%esp)
  100732:	00 
  100733:	c7 44 24 08 d4 32 10 	movl   $0x1032d4,0x8(%esp)
  10073a:	00 
  10073b:	c7 44 24 04 78 00 00 	movl   $0x78,0x4(%esp)
  100742:	00 
  100743:	c7 04 24 e9 32 10 00 	movl   $0x1032e9,(%esp)
  10074a:	e8 21 fc ff ff       	call   100370 <debug_panic>
	assert(eips[2][0] == eips[3][0]);
  10074f:	8b 55 a0             	mov    -0x60(%ebp),%edx
  100752:	8b 45 c8             	mov    -0x38(%ebp),%eax
  100755:	39 c2                	cmp    %eax,%edx
  100757:	74 24                	je     10077d <debug_check+0x174>
  100759:	c7 44 24 0c 28 33 10 	movl   $0x103328,0xc(%esp)
  100760:	00 
  100761:	c7 44 24 08 d4 32 10 	movl   $0x1032d4,0x8(%esp)
  100768:	00 
  100769:	c7 44 24 04 79 00 00 	movl   $0x79,0x4(%esp)
  100770:	00 
  100771:	c7 04 24 e9 32 10 00 	movl   $0x1032e9,(%esp)
  100778:	e8 f3 fb ff ff       	call   100370 <debug_panic>
	assert(eips[1][0] != eips[2][0]);
  10077d:	8b 95 78 ff ff ff    	mov    -0x88(%ebp),%edx
  100783:	8b 45 a0             	mov    -0x60(%ebp),%eax
  100786:	39 c2                	cmp    %eax,%edx
  100788:	75 24                	jne    1007ae <debug_check+0x1a5>
  10078a:	c7 44 24 0c 41 33 10 	movl   $0x103341,0xc(%esp)
  100791:	00 
  100792:	c7 44 24 08 d4 32 10 	movl   $0x1032d4,0x8(%esp)
  100799:	00 
  10079a:	c7 44 24 04 7a 00 00 	movl   $0x7a,0x4(%esp)
  1007a1:	00 
  1007a2:	c7 04 24 e9 32 10 00 	movl   $0x1032e9,(%esp)
  1007a9:	e8 c2 fb ff ff       	call   100370 <debug_panic>
	assert(eips[0][1] == eips[2][1]);
  1007ae:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  1007b4:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  1007b7:	39 c2                	cmp    %eax,%edx
  1007b9:	74 24                	je     1007df <debug_check+0x1d6>
  1007bb:	c7 44 24 0c 5a 33 10 	movl   $0x10335a,0xc(%esp)
  1007c2:	00 
  1007c3:	c7 44 24 08 d4 32 10 	movl   $0x1032d4,0x8(%esp)
  1007ca:	00 
  1007cb:	c7 44 24 04 7b 00 00 	movl   $0x7b,0x4(%esp)
  1007d2:	00 
  1007d3:	c7 04 24 e9 32 10 00 	movl   $0x1032e9,(%esp)
  1007da:	e8 91 fb ff ff       	call   100370 <debug_panic>
	assert(eips[1][1] == eips[3][1]);
  1007df:	8b 95 7c ff ff ff    	mov    -0x84(%ebp),%edx
  1007e5:	8b 45 cc             	mov    -0x34(%ebp),%eax
  1007e8:	39 c2                	cmp    %eax,%edx
  1007ea:	74 24                	je     100810 <debug_check+0x207>
  1007ec:	c7 44 24 0c 73 33 10 	movl   $0x103373,0xc(%esp)
  1007f3:	00 
  1007f4:	c7 44 24 08 d4 32 10 	movl   $0x1032d4,0x8(%esp)
  1007fb:	00 
  1007fc:	c7 44 24 04 7c 00 00 	movl   $0x7c,0x4(%esp)
  100803:	00 
  100804:	c7 04 24 e9 32 10 00 	movl   $0x1032e9,(%esp)
  10080b:	e8 60 fb ff ff       	call   100370 <debug_panic>
	assert(eips[0][1] != eips[1][1]);
  100810:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  100816:	8b 85 7c ff ff ff    	mov    -0x84(%ebp),%eax
  10081c:	39 c2                	cmp    %eax,%edx
  10081e:	75 24                	jne    100844 <debug_check+0x23b>
  100820:	c7 44 24 0c 8c 33 10 	movl   $0x10338c,0xc(%esp)
  100827:	00 
  100828:	c7 44 24 08 d4 32 10 	movl   $0x1032d4,0x8(%esp)
  10082f:	00 
  100830:	c7 44 24 04 7d 00 00 	movl   $0x7d,0x4(%esp)
  100837:	00 
  100838:	c7 04 24 e9 32 10 00 	movl   $0x1032e9,(%esp)
  10083f:	e8 2c fb ff ff       	call   100370 <debug_panic>

	cprintf("debug_check() succeeded!\n");
  100844:	c7 04 24 a5 33 10 00 	movl   $0x1033a5,(%esp)
  10084b:	e8 d8 21 00 00       	call   102a28 <cprintf>
//	while(1);
}
  100850:	c9                   	leave  
  100851:	c3                   	ret    
  100852:	90                   	nop
  100853:	90                   	nop

00100854 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  100854:	55                   	push   %ebp
  100855:	89 e5                	mov    %esp,%ebp
  100857:	53                   	push   %ebx
  100858:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10085b:	89 e3                	mov    %esp,%ebx
  10085d:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  100860:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  100863:	89 45 f4             	mov    %eax,-0xc(%ebp)
  100866:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100869:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10086e:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  100871:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100874:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  10087a:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  10087f:	74 24                	je     1008a5 <cpu_cur+0x51>
  100881:	c7 44 24 0c c0 33 10 	movl   $0x1033c0,0xc(%esp)
  100888:	00 
  100889:	c7 44 24 08 d6 33 10 	movl   $0x1033d6,0x8(%esp)
  100890:	00 
  100891:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  100898:	00 
  100899:	c7 04 24 eb 33 10 00 	movl   $0x1033eb,(%esp)
  1008a0:	e8 cb fa ff ff       	call   100370 <debug_panic>
	return c;
  1008a5:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  1008a8:	83 c4 24             	add    $0x24,%esp
  1008ab:	5b                   	pop    %ebx
  1008ac:	5d                   	pop    %ebp
  1008ad:	c3                   	ret    

001008ae <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  1008ae:	55                   	push   %ebp
  1008af:	89 e5                	mov    %esp,%ebp
  1008b1:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  1008b4:	e8 9b ff ff ff       	call   100854 <cpu_cur>
  1008b9:	3d 00 70 10 00       	cmp    $0x107000,%eax
  1008be:	0f 94 c0             	sete   %al
  1008c1:	0f b6 c0             	movzbl %al,%eax
}
  1008c4:	c9                   	leave  
  1008c5:	c3                   	ret    

001008c6 <mem_init>:

void mem_check(void);

void
mem_init(void)
{
  1008c6:	55                   	push   %ebp
  1008c7:	89 e5                	mov    %esp,%ebp
  1008c9:	83 ec 38             	sub    $0x38,%esp
	extern char start[], edata[], end[];
	cprintf("start : 0x%x, 0x%x\n",start, &start[0]);
  1008cc:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
  1008d3:	00 
  1008d4:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
  1008db:	00 
  1008dc:	c7 04 24 f8 33 10 00 	movl   $0x1033f8,(%esp)
  1008e3:	e8 40 21 00 00       	call   102a28 <cprintf>
	cprintf("edata : 0x%x\n",edata);
  1008e8:	c7 44 24 04 70 85 10 	movl   $0x108570,0x4(%esp)
  1008ef:	00 
  1008f0:	c7 04 24 0c 34 10 00 	movl   $0x10340c,(%esp)
  1008f7:	e8 2c 21 00 00       	call   102a28 <cprintf>
	cprintf("end : 0x%x, 0x%x\n",end, &end[0]);
  1008fc:	c7 44 24 08 ec 9f 30 	movl   $0x309fec,0x8(%esp)
  100903:	00 
  100904:	c7 44 24 04 ec 9f 30 	movl   $0x309fec,0x4(%esp)
  10090b:	00 
  10090c:	c7 04 24 1a 34 10 00 	movl   $0x10341a,(%esp)
  100913:	e8 10 21 00 00       	call   102a28 <cprintf>
	cprintf("&mem_pageinfo : 0x%x\n",&mem_pageinfo);
  100918:	c7 44 24 04 e4 9f 30 	movl   $0x309fe4,0x4(%esp)
  10091f:	00 
  100920:	c7 04 24 2c 34 10 00 	movl   $0x10342c,(%esp)
  100927:	e8 fc 20 00 00       	call   102a28 <cprintf>
	cprintf("&mem_freelist : 0x%x\n",&mem_freelist);
  10092c:	c7 44 24 04 c0 9f 10 	movl   $0x109fc0,0x4(%esp)
  100933:	00 
  100934:	c7 04 24 42 34 10 00 	movl   $0x103442,(%esp)
  10093b:	e8 e8 20 00 00       	call   102a28 <cprintf>
	cprintf("&tmp_paginfo : 0x%x\n",&tmp_mem_pageinfo);
  100940:	c7 44 24 04 e0 9f 10 	movl   $0x109fe0,0x4(%esp)
  100947:	00 
  100948:	c7 04 24 58 34 10 00 	movl   $0x103458,(%esp)
  10094f:	e8 d4 20 00 00       	call   102a28 <cprintf>
	if (!cpu_onboot())	// only do once, on the boot CPU
  100954:	e8 55 ff ff ff       	call   1008ae <cpu_onboot>
  100959:	85 c0                	test   %eax,%eax
  10095b:	0f 84 c2 01 00 00    	je     100b23 <mem_init+0x25d>
	// is available in the system (in bytes),
	// by reading the PC's BIOS-managed nonvolatile RAM (NVRAM).
	// The NVRAM tells us how many kilobytes there are.
	// Since the count is 16 bits, this gives us up to 64MB of RAM;
	// additional RAM beyond that would have to be detected another way.
	size_t basemem = ROUNDDOWN(nvram_read16(NVRAM_BASELO)*1024, PAGESIZE);
  100961:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
  100968:	e8 d5 18 00 00       	call   102242 <nvram_read16>
  10096d:	c1 e0 0a             	shl    $0xa,%eax
  100970:	89 45 ec             	mov    %eax,-0x14(%ebp)
  100973:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100976:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10097b:	89 45 e8             	mov    %eax,-0x18(%ebp)
	size_t extmem = ROUNDDOWN(nvram_read16(NVRAM_EXTLO)*1024, PAGESIZE);
  10097e:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
  100985:	e8 b8 18 00 00       	call   102242 <nvram_read16>
  10098a:	c1 e0 0a             	shl    $0xa,%eax
  10098d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100990:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100993:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100998:	89 45 e0             	mov    %eax,-0x20(%ebp)
	cprintf("basemem : 0x%x\n", basemem);  // ->0xa0000 = 640K
  10099b:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10099e:	89 44 24 04          	mov    %eax,0x4(%esp)
  1009a2:	c7 04 24 6d 34 10 00 	movl   $0x10346d,(%esp)
  1009a9:	e8 7a 20 00 00       	call   102a28 <cprintf>
	cprintf("extmem : 0x%x\n", extmem);		// ->0xff000
  1009ae:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1009b1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1009b5:	c7 04 24 7d 34 10 00 	movl   $0x10347d,(%esp)
  1009bc:	e8 67 20 00 00       	call   102a28 <cprintf>
	warn("Assuming we have 1GB of memory!");
  1009c1:	c7 44 24 08 8c 34 10 	movl   $0x10348c,0x8(%esp)
  1009c8:	00 
  1009c9:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
  1009d0:	00 
  1009d1:	c7 04 24 ac 34 10 00 	movl   $0x1034ac,(%esp)
  1009d8:	e8 59 fa ff ff       	call   100436 <debug_warn>
	extmem = 1024*1024*1024 - MEM_EXT;	// assume 1GB total memory
  1009dd:	c7 45 e0 00 00 f0 3f 	movl   $0x3ff00000,-0x20(%ebp)

	// The maximum physical address is the top of extended memory.
	mem_max = MEM_EXT + extmem;
  1009e4:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1009e7:	05 00 00 10 00       	add    $0x100000,%eax
  1009ec:	a3 e0 9f 30 00       	mov    %eax,0x309fe0

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;
  1009f1:	a1 e0 9f 30 00       	mov    0x309fe0,%eax
  1009f6:	c1 e8 0c             	shr    $0xc,%eax
  1009f9:	a3 c4 9f 10 00       	mov    %eax,0x109fc4

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
  1009fe:	a1 e0 9f 30 00       	mov    0x309fe0,%eax
  100a03:	c1 e8 0a             	shr    $0xa,%eax
  100a06:	89 44 24 04          	mov    %eax,0x4(%esp)
  100a0a:	c7 04 24 b8 34 10 00 	movl   $0x1034b8,(%esp)
  100a11:	e8 12 20 00 00       	call   102a28 <cprintf>
	cprintf("base = %dK, extended = %dK\n",
		(int)(basemem/1024), (int)(extmem/1024));
  100a16:	8b 45 e0             	mov    -0x20(%ebp),%eax
  100a19:	c1 e8 0a             	shr    $0xa,%eax

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
	cprintf("base = %dK, extended = %dK\n",
  100a1c:	89 c2                	mov    %eax,%edx
		(int)(basemem/1024), (int)(extmem/1024));
  100a1e:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100a21:	c1 e8 0a             	shr    $0xa,%eax

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
	cprintf("base = %dK, extended = %dK\n",
  100a24:	89 54 24 08          	mov    %edx,0x8(%esp)
  100a28:	89 44 24 04          	mov    %eax,0x4(%esp)
  100a2c:	c7 04 24 d9 34 10 00 	movl   $0x1034d9,(%esp)
  100a33:	e8 f0 1f 00 00       	call   102a28 <cprintf>
	//     but YOU decide where to place the pageinfo array.
	// Change the code to reflect this.
	//pageinfo *mem_pageinfo;
	//memset(mem_pageinfo, 0, sizeof(pageinfo)*mem_npage);

	pageinfo **freetail = &mem_freelist;
  100a38:	c7 45 f4 c0 9f 10 00 	movl   $0x109fc0,-0xc(%ebp)
	int i;
	uint32_t page_start;
	mem_pageinfo = tmp_mem_pageinfo;
  100a3f:	c7 05 e4 9f 30 00 e0 	movl   $0x109fe0,0x309fe4
  100a46:	9f 10 00 
	memset(tmp_mem_pageinfo, 0, sizeof(pageinfo)*1024*1024*1024/PAGESIZE);
  100a49:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  100a50:	00 
  100a51:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  100a58:	00 
  100a59:	c7 04 24 e0 9f 10 00 	movl   $0x109fe0,(%esp)
  100a60:	e8 a8 21 00 00       	call   102c0d <memset>
	for (i = 0; i < mem_npage; i++) {
  100a65:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  100a6c:	e9 92 00 00 00       	jmp    100b03 <mem_init+0x23d>
		// A free page has no references to it.
		mem_pageinfo[i].refcount = 0;
  100a71:	a1 e4 9f 30 00       	mov    0x309fe4,%eax
  100a76:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100a79:	c1 e2 03             	shl    $0x3,%edx
  100a7c:	01 d0                	add    %edx,%eax
  100a7e:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)

		//search free page
		//reserve page 0 and 1
		if(i == 0 || i == 1)
  100a85:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  100a89:	74 6d                	je     100af8 <mem_init+0x232>
  100a8b:	83 7d f0 01          	cmpl   $0x1,-0x10(%ebp)
  100a8f:	74 67                	je     100af8 <mem_init+0x232>
			continue;
		page_start = mem_pi2phys(mem_pageinfo + i);// get physical page addresses with pageinfo
  100a91:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100a94:	c1 e0 03             	shl    $0x3,%eax
  100a97:	c1 f8 03             	sar    $0x3,%eax
  100a9a:	c1 e0 0c             	shl    $0xc,%eax
  100a9d:	89 45 dc             	mov    %eax,-0x24(%ebp)

		//ignore[MEM_IO, MEM_EXT]
		if(page_start + PAGESIZE >= MEM_IO && page_start < MEM_EXT)
  100aa0:	8b 45 dc             	mov    -0x24(%ebp),%eax
  100aa3:	05 00 10 00 00       	add    $0x1000,%eax
  100aa8:	3d ff ff 09 00       	cmp    $0x9ffff,%eax
  100aad:	76 09                	jbe    100ab8 <mem_init+0x1f2>
  100aaf:	81 7d dc ff ff 0f 00 	cmpl   $0xfffff,-0x24(%ebp)
  100ab6:	76 43                	jbe    100afb <mem_init+0x235>
			continue;

		//ignore[kernel]  -->([start,end])
		if(page_start + PAGESIZE >= (uint32_t)start && page_start < (uint32_t)end)
  100ab8:	8b 45 dc             	mov    -0x24(%ebp),%eax
  100abb:	8d 90 00 10 00 00    	lea    0x1000(%eax),%edx
  100ac1:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  100ac6:	39 c2                	cmp    %eax,%edx
  100ac8:	72 0a                	jb     100ad4 <mem_init+0x20e>
  100aca:	b8 ec 9f 30 00       	mov    $0x309fec,%eax
  100acf:	39 45 dc             	cmp    %eax,-0x24(%ebp)
  100ad2:	72 2a                	jb     100afe <mem_init+0x238>
			continue;

		// Add the page to the end of the free list.
		*freetail = &mem_pageinfo[i];
  100ad4:	a1 e4 9f 30 00       	mov    0x309fe4,%eax
  100ad9:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100adc:	c1 e2 03             	shl    $0x3,%edx
  100adf:	01 c2                	add    %eax,%edx
  100ae1:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100ae4:	89 10                	mov    %edx,(%eax)
		freetail = &mem_pageinfo[i].free_next;
  100ae6:	a1 e4 9f 30 00       	mov    0x309fe4,%eax
  100aeb:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100aee:	c1 e2 03             	shl    $0x3,%edx
  100af1:	01 d0                	add    %edx,%eax
  100af3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  100af6:	eb 07                	jmp    100aff <mem_init+0x239>
		mem_pageinfo[i].refcount = 0;

		//search free page
		//reserve page 0 and 1
		if(i == 0 || i == 1)
			continue;
  100af8:	90                   	nop
  100af9:	eb 04                	jmp    100aff <mem_init+0x239>
		page_start = mem_pi2phys(mem_pageinfo + i);// get physical page addresses with pageinfo

		//ignore[MEM_IO, MEM_EXT]
		if(page_start + PAGESIZE >= MEM_IO && page_start < MEM_EXT)
			continue;
  100afb:	90                   	nop
  100afc:	eb 01                	jmp    100aff <mem_init+0x239>

		//ignore[kernel]  -->([start,end])
		if(page_start + PAGESIZE >= (uint32_t)start && page_start < (uint32_t)end)
			continue;
  100afe:	90                   	nop
	pageinfo **freetail = &mem_freelist;
	int i;
	uint32_t page_start;
	mem_pageinfo = tmp_mem_pageinfo;
	memset(tmp_mem_pageinfo, 0, sizeof(pageinfo)*1024*1024*1024/PAGESIZE);
	for (i = 0; i < mem_npage; i++) {
  100aff:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  100b03:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100b06:	a1 c4 9f 10 00       	mov    0x109fc4,%eax
  100b0b:	39 c2                	cmp    %eax,%edx
  100b0d:	0f 82 5e ff ff ff    	jb     100a71 <mem_init+0x1ab>

		// Add the page to the end of the free list.
		*freetail = &mem_pageinfo[i];
		freetail = &mem_pageinfo[i].free_next;
	}
	*freetail = NULL;	// null-terminate the freelist
  100b13:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100b16:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	// ...and remove this when you're ready.
	//panic("mem_init() not implemented");

	// Check to make sure the page allocator seems to work correctly.
	mem_check();
  100b1c:	e8 7d 00 00 00       	call   100b9e <mem_check>
  100b21:	eb 01                	jmp    100b24 <mem_init+0x25e>
	cprintf("end : 0x%x, 0x%x\n",end, &end[0]);
	cprintf("&mem_pageinfo : 0x%x\n",&mem_pageinfo);
	cprintf("&mem_freelist : 0x%x\n",&mem_freelist);
	cprintf("&tmp_paginfo : 0x%x\n",&tmp_mem_pageinfo);
	if (!cpu_onboot())	// only do once, on the boot CPU
		return;
  100b23:	90                   	nop
	// ...and remove this when you're ready.
	//panic("mem_init() not implemented");

	// Check to make sure the page allocator seems to work correctly.
	mem_check();
}
  100b24:	c9                   	leave  
  100b25:	c3                   	ret    

00100b26 <mem_alloc>:
//
// Hint: pi->refs should not be incremented 
// Hint: be sure to use proper mutual exclusion for multiprocessor operation.
pageinfo *
mem_alloc(void)
{
  100b26:	55                   	push   %ebp
  100b27:	89 e5                	mov    %esp,%ebp
  100b29:	83 ec 10             	sub    $0x10,%esp
	// Fill this function in
	// Fill this function in.
	//panic("mem_alloc not implemented.");
	if(mem_freelist == NULL)
  100b2c:	a1 c0 9f 10 00       	mov    0x109fc0,%eax
  100b31:	85 c0                	test   %eax,%eax
  100b33:	75 07                	jne    100b3c <mem_alloc+0x16>
		return NULL;
  100b35:	b8 00 00 00 00       	mov    $0x0,%eax
  100b3a:	eb 17                	jmp    100b53 <mem_alloc+0x2d>
	pageinfo *result = mem_freelist;
  100b3c:	a1 c0 9f 10 00       	mov    0x109fc0,%eax
  100b41:	89 45 fc             	mov    %eax,-0x4(%ebp)
	mem_freelist = mem_freelist->free_next;
  100b44:	a1 c0 9f 10 00       	mov    0x109fc0,%eax
  100b49:	8b 00                	mov    (%eax),%eax
  100b4b:	a3 c0 9f 10 00       	mov    %eax,0x109fc0
	return result;
  100b50:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  100b53:	c9                   	leave  
  100b54:	c3                   	ret    

00100b55 <mem_free>:
// Return a page to the free list, given its pageinfo pointer.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
mem_free(pageinfo *pi)
{
  100b55:	55                   	push   %ebp
  100b56:	89 e5                	mov    %esp,%ebp
  100b58:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in.
	//panic("mem_free not implemented.");
	assert(pi->refcount == 0);
  100b5b:	8b 45 08             	mov    0x8(%ebp),%eax
  100b5e:	8b 40 04             	mov    0x4(%eax),%eax
  100b61:	85 c0                	test   %eax,%eax
  100b63:	74 24                	je     100b89 <mem_free+0x34>
  100b65:	c7 44 24 0c f5 34 10 	movl   $0x1034f5,0xc(%esp)
  100b6c:	00 
  100b6d:	c7 44 24 08 d6 33 10 	movl   $0x1033d6,0x8(%esp)
  100b74:	00 
  100b75:	c7 44 24 04 a3 00 00 	movl   $0xa3,0x4(%esp)
  100b7c:	00 
  100b7d:	c7 04 24 ac 34 10 00 	movl   $0x1034ac,(%esp)
  100b84:	e8 e7 f7 ff ff       	call   100370 <debug_panic>
	pi->free_next = mem_freelist;
  100b89:	8b 15 c0 9f 10 00    	mov    0x109fc0,%edx
  100b8f:	8b 45 08             	mov    0x8(%ebp),%eax
  100b92:	89 10                	mov    %edx,(%eax)
	mem_freelist = pi;
  100b94:	8b 45 08             	mov    0x8(%ebp),%eax
  100b97:	a3 c0 9f 10 00       	mov    %eax,0x109fc0
}
  100b9c:	c9                   	leave  
  100b9d:	c3                   	ret    

00100b9e <mem_check>:
// Check the physical page allocator (mem_alloc(), mem_free())
// for correct operation after initialization via mem_init().
//
void
mem_check()
{
  100b9e:	55                   	push   %ebp
  100b9f:	89 e5                	mov    %esp,%ebp
  100ba1:	83 ec 38             	sub    $0x38,%esp
	int i;

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
  100ba4:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
  100bab:	a1 c0 9f 10 00       	mov    0x109fc0,%eax
  100bb0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  100bb3:	eb 38                	jmp    100bed <mem_check+0x4f>
		memset(mem_pi2ptr(pp), 0x97, 128);
  100bb5:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100bb8:	a1 e4 9f 30 00       	mov    0x309fe4,%eax
  100bbd:	89 d1                	mov    %edx,%ecx
  100bbf:	29 c1                	sub    %eax,%ecx
  100bc1:	89 c8                	mov    %ecx,%eax
  100bc3:	c1 f8 03             	sar    $0x3,%eax
  100bc6:	c1 e0 0c             	shl    $0xc,%eax
  100bc9:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
  100bd0:	00 
  100bd1:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
  100bd8:	00 
  100bd9:	89 04 24             	mov    %eax,(%esp)
  100bdc:	e8 2c 20 00 00       	call   102c0d <memset>
		freepages++;
  100be1:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
  100be5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100be8:	8b 00                	mov    (%eax),%eax
  100bea:	89 45 f4             	mov    %eax,-0xc(%ebp)
  100bed:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  100bf1:	75 c2                	jne    100bb5 <mem_check+0x17>
		memset(mem_pi2ptr(pp), 0x97, 128);
		freepages++;
	}
	cprintf("mem_check: %d free pages\n", freepages);
  100bf3:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100bf6:	89 44 24 04          	mov    %eax,0x4(%esp)
  100bfa:	c7 04 24 07 35 10 00 	movl   $0x103507,(%esp)
  100c01:	e8 22 1e 00 00       	call   102a28 <cprintf>
	assert(freepages < mem_npage);	// can't have more free than total!
  100c06:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100c09:	a1 c4 9f 10 00       	mov    0x109fc4,%eax
  100c0e:	39 c2                	cmp    %eax,%edx
  100c10:	72 24                	jb     100c36 <mem_check+0x98>
  100c12:	c7 44 24 0c 21 35 10 	movl   $0x103521,0xc(%esp)
  100c19:	00 
  100c1a:	c7 44 24 08 d6 33 10 	movl   $0x1033d6,0x8(%esp)
  100c21:	00 
  100c22:	c7 44 24 04 bc 00 00 	movl   $0xbc,0x4(%esp)
  100c29:	00 
  100c2a:	c7 04 24 ac 34 10 00 	movl   $0x1034ac,(%esp)
  100c31:	e8 3a f7 ff ff       	call   100370 <debug_panic>
	assert(freepages > 16000);	// make sure it's in the right ballpark
  100c36:	81 7d f0 80 3e 00 00 	cmpl   $0x3e80,-0x10(%ebp)
  100c3d:	7f 24                	jg     100c63 <mem_check+0xc5>
  100c3f:	c7 44 24 0c 37 35 10 	movl   $0x103537,0xc(%esp)
  100c46:	00 
  100c47:	c7 44 24 08 d6 33 10 	movl   $0x1033d6,0x8(%esp)
  100c4e:	00 
  100c4f:	c7 44 24 04 bd 00 00 	movl   $0xbd,0x4(%esp)
  100c56:	00 
  100c57:	c7 04 24 ac 34 10 00 	movl   $0x1034ac,(%esp)
  100c5e:	e8 0d f7 ff ff       	call   100370 <debug_panic>

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
  100c63:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  100c6a:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100c6d:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100c70:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100c73:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  100c76:	e8 ab fe ff ff       	call   100b26 <mem_alloc>
  100c7b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100c7e:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100c82:	75 24                	jne    100ca8 <mem_check+0x10a>
  100c84:	c7 44 24 0c 49 35 10 	movl   $0x103549,0xc(%esp)
  100c8b:	00 
  100c8c:	c7 44 24 08 d6 33 10 	movl   $0x1033d6,0x8(%esp)
  100c93:	00 
  100c94:	c7 44 24 04 c1 00 00 	movl   $0xc1,0x4(%esp)
  100c9b:	00 
  100c9c:	c7 04 24 ac 34 10 00 	movl   $0x1034ac,(%esp)
  100ca3:	e8 c8 f6 ff ff       	call   100370 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100ca8:	e8 79 fe ff ff       	call   100b26 <mem_alloc>
  100cad:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100cb0:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100cb4:	75 24                	jne    100cda <mem_check+0x13c>
  100cb6:	c7 44 24 0c 52 35 10 	movl   $0x103552,0xc(%esp)
  100cbd:	00 
  100cbe:	c7 44 24 08 d6 33 10 	movl   $0x1033d6,0x8(%esp)
  100cc5:	00 
  100cc6:	c7 44 24 04 c2 00 00 	movl   $0xc2,0x4(%esp)
  100ccd:	00 
  100cce:	c7 04 24 ac 34 10 00 	movl   $0x1034ac,(%esp)
  100cd5:	e8 96 f6 ff ff       	call   100370 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100cda:	e8 47 fe ff ff       	call   100b26 <mem_alloc>
  100cdf:	89 45 ec             	mov    %eax,-0x14(%ebp)
  100ce2:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  100ce6:	75 24                	jne    100d0c <mem_check+0x16e>
  100ce8:	c7 44 24 0c 5b 35 10 	movl   $0x10355b,0xc(%esp)
  100cef:	00 
  100cf0:	c7 44 24 08 d6 33 10 	movl   $0x1033d6,0x8(%esp)
  100cf7:	00 
  100cf8:	c7 44 24 04 c3 00 00 	movl   $0xc3,0x4(%esp)
  100cff:	00 
  100d00:	c7 04 24 ac 34 10 00 	movl   $0x1034ac,(%esp)
  100d07:	e8 64 f6 ff ff       	call   100370 <debug_panic>

	assert(pp0);
  100d0c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100d10:	75 24                	jne    100d36 <mem_check+0x198>
  100d12:	c7 44 24 0c 64 35 10 	movl   $0x103564,0xc(%esp)
  100d19:	00 
  100d1a:	c7 44 24 08 d6 33 10 	movl   $0x1033d6,0x8(%esp)
  100d21:	00 
  100d22:	c7 44 24 04 c5 00 00 	movl   $0xc5,0x4(%esp)
  100d29:	00 
  100d2a:	c7 04 24 ac 34 10 00 	movl   $0x1034ac,(%esp)
  100d31:	e8 3a f6 ff ff       	call   100370 <debug_panic>
	assert(pp1 && pp1 != pp0);
  100d36:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100d3a:	74 08                	je     100d44 <mem_check+0x1a6>
  100d3c:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100d3f:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  100d42:	75 24                	jne    100d68 <mem_check+0x1ca>
  100d44:	c7 44 24 0c 68 35 10 	movl   $0x103568,0xc(%esp)
  100d4b:	00 
  100d4c:	c7 44 24 08 d6 33 10 	movl   $0x1033d6,0x8(%esp)
  100d53:	00 
  100d54:	c7 44 24 04 c6 00 00 	movl   $0xc6,0x4(%esp)
  100d5b:	00 
  100d5c:	c7 04 24 ac 34 10 00 	movl   $0x1034ac,(%esp)
  100d63:	e8 08 f6 ff ff       	call   100370 <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  100d68:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  100d6c:	74 10                	je     100d7e <mem_check+0x1e0>
  100d6e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100d71:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  100d74:	74 08                	je     100d7e <mem_check+0x1e0>
  100d76:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100d79:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  100d7c:	75 24                	jne    100da2 <mem_check+0x204>
  100d7e:	c7 44 24 0c 7c 35 10 	movl   $0x10357c,0xc(%esp)
  100d85:	00 
  100d86:	c7 44 24 08 d6 33 10 	movl   $0x1033d6,0x8(%esp)
  100d8d:	00 
  100d8e:	c7 44 24 04 c7 00 00 	movl   $0xc7,0x4(%esp)
  100d95:	00 
  100d96:	c7 04 24 ac 34 10 00 	movl   $0x1034ac,(%esp)
  100d9d:	e8 ce f5 ff ff       	call   100370 <debug_panic>
        assert(mem_pi2phys(pp0) < mem_npage*PAGESIZE);
  100da2:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  100da5:	a1 e4 9f 30 00       	mov    0x309fe4,%eax
  100daa:	89 d1                	mov    %edx,%ecx
  100dac:	29 c1                	sub    %eax,%ecx
  100dae:	89 c8                	mov    %ecx,%eax
  100db0:	c1 f8 03             	sar    $0x3,%eax
  100db3:	c1 e0 0c             	shl    $0xc,%eax
  100db6:	8b 15 c4 9f 10 00    	mov    0x109fc4,%edx
  100dbc:	c1 e2 0c             	shl    $0xc,%edx
  100dbf:	39 d0                	cmp    %edx,%eax
  100dc1:	72 24                	jb     100de7 <mem_check+0x249>
  100dc3:	c7 44 24 0c 9c 35 10 	movl   $0x10359c,0xc(%esp)
  100dca:	00 
  100dcb:	c7 44 24 08 d6 33 10 	movl   $0x1033d6,0x8(%esp)
  100dd2:	00 
  100dd3:	c7 44 24 04 c8 00 00 	movl   $0xc8,0x4(%esp)
  100dda:	00 
  100ddb:	c7 04 24 ac 34 10 00 	movl   $0x1034ac,(%esp)
  100de2:	e8 89 f5 ff ff       	call   100370 <debug_panic>
        assert(mem_pi2phys(pp1) < mem_npage*PAGESIZE);
  100de7:	8b 55 e8             	mov    -0x18(%ebp),%edx
  100dea:	a1 e4 9f 30 00       	mov    0x309fe4,%eax
  100def:	89 d1                	mov    %edx,%ecx
  100df1:	29 c1                	sub    %eax,%ecx
  100df3:	89 c8                	mov    %ecx,%eax
  100df5:	c1 f8 03             	sar    $0x3,%eax
  100df8:	c1 e0 0c             	shl    $0xc,%eax
  100dfb:	8b 15 c4 9f 10 00    	mov    0x109fc4,%edx
  100e01:	c1 e2 0c             	shl    $0xc,%edx
  100e04:	39 d0                	cmp    %edx,%eax
  100e06:	72 24                	jb     100e2c <mem_check+0x28e>
  100e08:	c7 44 24 0c c4 35 10 	movl   $0x1035c4,0xc(%esp)
  100e0f:	00 
  100e10:	c7 44 24 08 d6 33 10 	movl   $0x1033d6,0x8(%esp)
  100e17:	00 
  100e18:	c7 44 24 04 c9 00 00 	movl   $0xc9,0x4(%esp)
  100e1f:	00 
  100e20:	c7 04 24 ac 34 10 00 	movl   $0x1034ac,(%esp)
  100e27:	e8 44 f5 ff ff       	call   100370 <debug_panic>
        assert(mem_pi2phys(pp2) < mem_npage*PAGESIZE);
  100e2c:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100e2f:	a1 e4 9f 30 00       	mov    0x309fe4,%eax
  100e34:	89 d1                	mov    %edx,%ecx
  100e36:	29 c1                	sub    %eax,%ecx
  100e38:	89 c8                	mov    %ecx,%eax
  100e3a:	c1 f8 03             	sar    $0x3,%eax
  100e3d:	c1 e0 0c             	shl    $0xc,%eax
  100e40:	8b 15 c4 9f 10 00    	mov    0x109fc4,%edx
  100e46:	c1 e2 0c             	shl    $0xc,%edx
  100e49:	39 d0                	cmp    %edx,%eax
  100e4b:	72 24                	jb     100e71 <mem_check+0x2d3>
  100e4d:	c7 44 24 0c ec 35 10 	movl   $0x1035ec,0xc(%esp)
  100e54:	00 
  100e55:	c7 44 24 08 d6 33 10 	movl   $0x1033d6,0x8(%esp)
  100e5c:	00 
  100e5d:	c7 44 24 04 ca 00 00 	movl   $0xca,0x4(%esp)
  100e64:	00 
  100e65:	c7 04 24 ac 34 10 00 	movl   $0x1034ac,(%esp)
  100e6c:	e8 ff f4 ff ff       	call   100370 <debug_panic>

	// temporarily steal the rest of the free pages
	fl = mem_freelist;
  100e71:	a1 c0 9f 10 00       	mov    0x109fc0,%eax
  100e76:	89 45 e0             	mov    %eax,-0x20(%ebp)
	mem_freelist = 0;
  100e79:	c7 05 c0 9f 10 00 00 	movl   $0x0,0x109fc0
  100e80:	00 00 00 

	// should be no free memory
	assert(mem_alloc() == 0);
  100e83:	e8 9e fc ff ff       	call   100b26 <mem_alloc>
  100e88:	85 c0                	test   %eax,%eax
  100e8a:	74 24                	je     100eb0 <mem_check+0x312>
  100e8c:	c7 44 24 0c 12 36 10 	movl   $0x103612,0xc(%esp)
  100e93:	00 
  100e94:	c7 44 24 08 d6 33 10 	movl   $0x1033d6,0x8(%esp)
  100e9b:	00 
  100e9c:	c7 44 24 04 d1 00 00 	movl   $0xd1,0x4(%esp)
  100ea3:	00 
  100ea4:	c7 04 24 ac 34 10 00 	movl   $0x1034ac,(%esp)
  100eab:	e8 c0 f4 ff ff       	call   100370 <debug_panic>

        // free and re-allocate?
        mem_free(pp0);
  100eb0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100eb3:	89 04 24             	mov    %eax,(%esp)
  100eb6:	e8 9a fc ff ff       	call   100b55 <mem_free>
        mem_free(pp1);
  100ebb:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100ebe:	89 04 24             	mov    %eax,(%esp)
  100ec1:	e8 8f fc ff ff       	call   100b55 <mem_free>
        mem_free(pp2);
  100ec6:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100ec9:	89 04 24             	mov    %eax,(%esp)
  100ecc:	e8 84 fc ff ff       	call   100b55 <mem_free>
	pp0 = pp1 = pp2 = 0;
  100ed1:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  100ed8:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100edb:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100ede:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100ee1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  100ee4:	e8 3d fc ff ff       	call   100b26 <mem_alloc>
  100ee9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100eec:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100ef0:	75 24                	jne    100f16 <mem_check+0x378>
  100ef2:	c7 44 24 0c 49 35 10 	movl   $0x103549,0xc(%esp)
  100ef9:	00 
  100efa:	c7 44 24 08 d6 33 10 	movl   $0x1033d6,0x8(%esp)
  100f01:	00 
  100f02:	c7 44 24 04 d8 00 00 	movl   $0xd8,0x4(%esp)
  100f09:	00 
  100f0a:	c7 04 24 ac 34 10 00 	movl   $0x1034ac,(%esp)
  100f11:	e8 5a f4 ff ff       	call   100370 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100f16:	e8 0b fc ff ff       	call   100b26 <mem_alloc>
  100f1b:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100f1e:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100f22:	75 24                	jne    100f48 <mem_check+0x3aa>
  100f24:	c7 44 24 0c 52 35 10 	movl   $0x103552,0xc(%esp)
  100f2b:	00 
  100f2c:	c7 44 24 08 d6 33 10 	movl   $0x1033d6,0x8(%esp)
  100f33:	00 
  100f34:	c7 44 24 04 d9 00 00 	movl   $0xd9,0x4(%esp)
  100f3b:	00 
  100f3c:	c7 04 24 ac 34 10 00 	movl   $0x1034ac,(%esp)
  100f43:	e8 28 f4 ff ff       	call   100370 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100f48:	e8 d9 fb ff ff       	call   100b26 <mem_alloc>
  100f4d:	89 45 ec             	mov    %eax,-0x14(%ebp)
  100f50:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  100f54:	75 24                	jne    100f7a <mem_check+0x3dc>
  100f56:	c7 44 24 0c 5b 35 10 	movl   $0x10355b,0xc(%esp)
  100f5d:	00 
  100f5e:	c7 44 24 08 d6 33 10 	movl   $0x1033d6,0x8(%esp)
  100f65:	00 
  100f66:	c7 44 24 04 da 00 00 	movl   $0xda,0x4(%esp)
  100f6d:	00 
  100f6e:	c7 04 24 ac 34 10 00 	movl   $0x1034ac,(%esp)
  100f75:	e8 f6 f3 ff ff       	call   100370 <debug_panic>
	assert(pp0);
  100f7a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100f7e:	75 24                	jne    100fa4 <mem_check+0x406>
  100f80:	c7 44 24 0c 64 35 10 	movl   $0x103564,0xc(%esp)
  100f87:	00 
  100f88:	c7 44 24 08 d6 33 10 	movl   $0x1033d6,0x8(%esp)
  100f8f:	00 
  100f90:	c7 44 24 04 db 00 00 	movl   $0xdb,0x4(%esp)
  100f97:	00 
  100f98:	c7 04 24 ac 34 10 00 	movl   $0x1034ac,(%esp)
  100f9f:	e8 cc f3 ff ff       	call   100370 <debug_panic>
	assert(pp1 && pp1 != pp0);
  100fa4:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100fa8:	74 08                	je     100fb2 <mem_check+0x414>
  100faa:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100fad:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  100fb0:	75 24                	jne    100fd6 <mem_check+0x438>
  100fb2:	c7 44 24 0c 68 35 10 	movl   $0x103568,0xc(%esp)
  100fb9:	00 
  100fba:	c7 44 24 08 d6 33 10 	movl   $0x1033d6,0x8(%esp)
  100fc1:	00 
  100fc2:	c7 44 24 04 dc 00 00 	movl   $0xdc,0x4(%esp)
  100fc9:	00 
  100fca:	c7 04 24 ac 34 10 00 	movl   $0x1034ac,(%esp)
  100fd1:	e8 9a f3 ff ff       	call   100370 <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  100fd6:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  100fda:	74 10                	je     100fec <mem_check+0x44e>
  100fdc:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100fdf:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  100fe2:	74 08                	je     100fec <mem_check+0x44e>
  100fe4:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100fe7:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  100fea:	75 24                	jne    101010 <mem_check+0x472>
  100fec:	c7 44 24 0c 7c 35 10 	movl   $0x10357c,0xc(%esp)
  100ff3:	00 
  100ff4:	c7 44 24 08 d6 33 10 	movl   $0x1033d6,0x8(%esp)
  100ffb:	00 
  100ffc:	c7 44 24 04 dd 00 00 	movl   $0xdd,0x4(%esp)
  101003:	00 
  101004:	c7 04 24 ac 34 10 00 	movl   $0x1034ac,(%esp)
  10100b:	e8 60 f3 ff ff       	call   100370 <debug_panic>
	assert(mem_alloc() == 0);
  101010:	e8 11 fb ff ff       	call   100b26 <mem_alloc>
  101015:	85 c0                	test   %eax,%eax
  101017:	74 24                	je     10103d <mem_check+0x49f>
  101019:	c7 44 24 0c 12 36 10 	movl   $0x103612,0xc(%esp)
  101020:	00 
  101021:	c7 44 24 08 d6 33 10 	movl   $0x1033d6,0x8(%esp)
  101028:	00 
  101029:	c7 44 24 04 de 00 00 	movl   $0xde,0x4(%esp)
  101030:	00 
  101031:	c7 04 24 ac 34 10 00 	movl   $0x1034ac,(%esp)
  101038:	e8 33 f3 ff ff       	call   100370 <debug_panic>

	// give free list back
	mem_freelist = fl;
  10103d:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101040:	a3 c0 9f 10 00       	mov    %eax,0x109fc0

	// free the pages we took
	mem_free(pp0);
  101045:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  101048:	89 04 24             	mov    %eax,(%esp)
  10104b:	e8 05 fb ff ff       	call   100b55 <mem_free>
	mem_free(pp1);
  101050:	8b 45 e8             	mov    -0x18(%ebp),%eax
  101053:	89 04 24             	mov    %eax,(%esp)
  101056:	e8 fa fa ff ff       	call   100b55 <mem_free>
	mem_free(pp2);
  10105b:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10105e:	89 04 24             	mov    %eax,(%esp)
  101061:	e8 ef fa ff ff       	call   100b55 <mem_free>

	cprintf("mem_check() succeeded!\n");
  101066:	c7 04 24 23 36 10 00 	movl   $0x103623,(%esp)
  10106d:	e8 b6 19 00 00       	call   102a28 <cprintf>
}
  101072:	c9                   	leave  
  101073:	c3                   	ret    

00101074 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  101074:	55                   	push   %ebp
  101075:	89 e5                	mov    %esp,%ebp
  101077:	53                   	push   %ebx
  101078:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10107b:	89 e3                	mov    %esp,%ebx
  10107d:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  101080:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  101083:	89 45 f4             	mov    %eax,-0xc(%ebp)
  101086:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101089:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10108e:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  101091:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101094:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  10109a:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  10109f:	74 24                	je     1010c5 <cpu_cur+0x51>
  1010a1:	c7 44 24 0c 3b 36 10 	movl   $0x10363b,0xc(%esp)
  1010a8:	00 
  1010a9:	c7 44 24 08 51 36 10 	movl   $0x103651,0x8(%esp)
  1010b0:	00 
  1010b1:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  1010b8:	00 
  1010b9:	c7 04 24 66 36 10 00 	movl   $0x103666,(%esp)
  1010c0:	e8 ab f2 ff ff       	call   100370 <debug_panic>
	return c;
  1010c5:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  1010c8:	83 c4 24             	add    $0x24,%esp
  1010cb:	5b                   	pop    %ebx
  1010cc:	5d                   	pop    %ebp
  1010cd:	c3                   	ret    

001010ce <cpu_init>:
	magic: CPU_MAGIC
};


void cpu_init()
{
  1010ce:	55                   	push   %ebp
  1010cf:	89 e5                	mov    %esp,%ebp
  1010d1:	53                   	push   %ebx
  1010d2:	83 ec 14             	sub    $0x14,%esp
	cpu *c = cpu_cur();
  1010d5:	e8 9a ff ff ff       	call   101074 <cpu_cur>
  1010da:	89 45 f4             	mov    %eax,-0xc(%ebp)

	c->gdt[CPU_GDT_TSS >> 3] = SEGDESC16(0, STS_T32A, (uint32_t)(&c->tss), sizeof(c->tss)-1, 0);
  1010dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1010e0:	83 c0 38             	add    $0x38,%eax
  1010e3:	89 c3                	mov    %eax,%ebx
  1010e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1010e8:	83 c0 38             	add    $0x38,%eax
  1010eb:	c1 e8 10             	shr    $0x10,%eax
  1010ee:	89 c1                	mov    %eax,%ecx
  1010f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1010f3:	83 c0 38             	add    $0x38,%eax
  1010f6:	c1 e8 18             	shr    $0x18,%eax
  1010f9:	89 c2                	mov    %eax,%edx
  1010fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1010fe:	66 c7 40 30 67 00    	movw   $0x67,0x30(%eax)
  101104:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101107:	66 89 58 32          	mov    %bx,0x32(%eax)
  10110b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10110e:	88 48 34             	mov    %cl,0x34(%eax)
  101111:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101114:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  101118:	83 e1 f0             	and    $0xfffffff0,%ecx
  10111b:	83 c9 09             	or     $0x9,%ecx
  10111e:	88 48 35             	mov    %cl,0x35(%eax)
  101121:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101124:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  101128:	83 e1 ef             	and    $0xffffffef,%ecx
  10112b:	88 48 35             	mov    %cl,0x35(%eax)
  10112e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101131:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  101135:	83 e1 9f             	and    $0xffffff9f,%ecx
  101138:	88 48 35             	mov    %cl,0x35(%eax)
  10113b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10113e:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  101142:	83 c9 80             	or     $0xffffff80,%ecx
  101145:	88 48 35             	mov    %cl,0x35(%eax)
  101148:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10114b:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  10114f:	83 e1 f0             	and    $0xfffffff0,%ecx
  101152:	88 48 36             	mov    %cl,0x36(%eax)
  101155:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101158:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  10115c:	83 e1 ef             	and    $0xffffffef,%ecx
  10115f:	88 48 36             	mov    %cl,0x36(%eax)
  101162:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101165:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  101169:	83 e1 df             	and    $0xffffffdf,%ecx
  10116c:	88 48 36             	mov    %cl,0x36(%eax)
  10116f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101172:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  101176:	83 c9 40             	or     $0x40,%ecx
  101179:	88 48 36             	mov    %cl,0x36(%eax)
  10117c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10117f:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  101183:	83 e1 7f             	and    $0x7f,%ecx
  101186:	88 48 36             	mov    %cl,0x36(%eax)
  101189:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10118c:	88 50 37             	mov    %dl,0x37(%eax)
	c->tss.ts_esp0 = (uint32_t)c->kstackhi;
  10118f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101192:	05 00 10 00 00       	add    $0x1000,%eax
  101197:	89 c2                	mov    %eax,%edx
  101199:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10119c:	89 50 3c             	mov    %edx,0x3c(%eax)
	c->tss.ts_ss0 = CPU_GDT_KDATA;
  10119f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1011a2:	66 c7 40 40 10 00    	movw   $0x10,0x40(%eax)

	// Load the GDT
	struct pseudodesc gdt_pd = {
  1011a8:	66 c7 45 ec 37 00    	movw   $0x37,-0x14(%ebp)
		sizeof(c->gdt) - 1, (uint32_t) c->gdt };
  1011ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
	c->gdt[CPU_GDT_TSS >> 3] = SEGDESC16(0, STS_T32A, (uint32_t)(&c->tss), sizeof(c->tss)-1, 0);
	c->tss.ts_esp0 = (uint32_t)c->kstackhi;
	c->tss.ts_ss0 = CPU_GDT_KDATA;

	// Load the GDT
	struct pseudodesc gdt_pd = {
  1011b1:	89 45 ee             	mov    %eax,-0x12(%ebp)
		sizeof(c->gdt) - 1, (uint32_t) c->gdt };
	asm volatile("lgdt %0" : : "m" (gdt_pd));
  1011b4:	0f 01 55 ec          	lgdtl  -0x14(%ebp)

	// Reload all segment registers.
	asm volatile("movw %%ax,%%gs" :: "a" (CPU_GDT_UDATA|3));
  1011b8:	b8 23 00 00 00       	mov    $0x23,%eax
  1011bd:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (CPU_GDT_UDATA|3));
  1011bf:	b8 23 00 00 00       	mov    $0x23,%eax
  1011c4:	8e e0                	mov    %eax,%fs
	asm volatile("movw %%ax,%%es" :: "a" (CPU_GDT_KDATA));
  1011c6:	b8 10 00 00 00       	mov    $0x10,%eax
  1011cb:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (CPU_GDT_KDATA));
  1011cd:	b8 10 00 00 00       	mov    $0x10,%eax
  1011d2:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (CPU_GDT_KDATA));
  1011d4:	b8 10 00 00 00       	mov    $0x10,%eax
  1011d9:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (CPU_GDT_KCODE)); // reload CS
  1011db:	ea e2 11 10 00 08 00 	ljmp   $0x8,$0x1011e2

	// We don't need an LDT.
	asm volatile("lldt %%ax" :: "a" (0));
  1011e2:	b8 00 00 00 00       	mov    $0x0,%eax
  1011e7:	0f 00 d0             	lldt   %ax
  1011ea:	66 c7 45 f2 30 00    	movw   $0x30,-0xe(%ebp)
}

static gcc_inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
  1011f0:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
  1011f4:	0f 00 d8             	ltr    %ax

	ltr(CPU_GDT_TSS);
}
  1011f7:	83 c4 14             	add    $0x14,%esp
  1011fa:	5b                   	pop    %ebx
  1011fb:	5d                   	pop    %ebp
  1011fc:	c3                   	ret    
  1011fd:	90                   	nop
  1011fe:	90                   	nop
  1011ff:	90                   	nop

00101200 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  101200:	55                   	push   %ebp
  101201:	89 e5                	mov    %esp,%ebp
  101203:	53                   	push   %ebx
  101204:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  101207:	89 e3                	mov    %esp,%ebx
  101209:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  10120c:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  10120f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  101212:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101215:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10121a:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  10121d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101220:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  101226:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  10122b:	74 24                	je     101251 <cpu_cur+0x51>
  10122d:	c7 44 24 0c 80 36 10 	movl   $0x103680,0xc(%esp)
  101234:	00 
  101235:	c7 44 24 08 96 36 10 	movl   $0x103696,0x8(%esp)
  10123c:	00 
  10123d:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  101244:	00 
  101245:	c7 04 24 ab 36 10 00 	movl   $0x1036ab,(%esp)
  10124c:	e8 1f f1 ff ff       	call   100370 <debug_panic>
	return c;
  101251:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  101254:	83 c4 24             	add    $0x24,%esp
  101257:	5b                   	pop    %ebx
  101258:	5d                   	pop    %ebp
  101259:	c3                   	ret    

0010125a <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  10125a:	55                   	push   %ebp
  10125b:	89 e5                	mov    %esp,%ebp
  10125d:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  101260:	e8 9b ff ff ff       	call   101200 <cpu_cur>
  101265:	3d 00 70 10 00       	cmp    $0x107000,%eax
  10126a:	0f 94 c0             	sete   %al
  10126d:	0f b6 c0             	movzbl %al,%eax
}
  101270:	c9                   	leave  
  101271:	c3                   	ret    

00101272 <trap_init_idt>:
extern int vectors[];


static void
trap_init_idt(void)
{
  101272:	55                   	push   %ebp
  101273:	89 e5                	mov    %esp,%ebp
  101275:	83 ec 10             	sub    $0x10,%esp
	extern segdesc gdt[];

	//panic("trap_init() not implemented.");

	int i;
	for (i=0; i<256; i++) {
  101278:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  10127f:	e9 c3 00 00 00       	jmp    101347 <trap_init_idt+0xd5>
		SETGATE(idt[i], 0, CPU_GDT_KCODE, vectors[i], 0); //CPU_GDT_KCODE is 0x08
  101284:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101287:	8b 04 85 08 80 10 00 	mov    0x108008(,%eax,4),%eax
  10128e:	89 c2                	mov    %eax,%edx
  101290:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101293:	66 89 14 c5 a0 97 10 	mov    %dx,0x1097a0(,%eax,8)
  10129a:	00 
  10129b:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10129e:	66 c7 04 c5 a2 97 10 	movw   $0x8,0x1097a2(,%eax,8)
  1012a5:	00 08 00 
  1012a8:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1012ab:	0f b6 14 c5 a4 97 10 	movzbl 0x1097a4(,%eax,8),%edx
  1012b2:	00 
  1012b3:	83 e2 e0             	and    $0xffffffe0,%edx
  1012b6:	88 14 c5 a4 97 10 00 	mov    %dl,0x1097a4(,%eax,8)
  1012bd:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1012c0:	0f b6 14 c5 a4 97 10 	movzbl 0x1097a4(,%eax,8),%edx
  1012c7:	00 
  1012c8:	83 e2 1f             	and    $0x1f,%edx
  1012cb:	88 14 c5 a4 97 10 00 	mov    %dl,0x1097a4(,%eax,8)
  1012d2:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1012d5:	0f b6 14 c5 a5 97 10 	movzbl 0x1097a5(,%eax,8),%edx
  1012dc:	00 
  1012dd:	83 e2 f0             	and    $0xfffffff0,%edx
  1012e0:	83 ca 0e             	or     $0xe,%edx
  1012e3:	88 14 c5 a5 97 10 00 	mov    %dl,0x1097a5(,%eax,8)
  1012ea:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1012ed:	0f b6 14 c5 a5 97 10 	movzbl 0x1097a5(,%eax,8),%edx
  1012f4:	00 
  1012f5:	83 e2 ef             	and    $0xffffffef,%edx
  1012f8:	88 14 c5 a5 97 10 00 	mov    %dl,0x1097a5(,%eax,8)
  1012ff:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101302:	0f b6 14 c5 a5 97 10 	movzbl 0x1097a5(,%eax,8),%edx
  101309:	00 
  10130a:	83 e2 9f             	and    $0xffffff9f,%edx
  10130d:	88 14 c5 a5 97 10 00 	mov    %dl,0x1097a5(,%eax,8)
  101314:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101317:	0f b6 14 c5 a5 97 10 	movzbl 0x1097a5(,%eax,8),%edx
  10131e:	00 
  10131f:	83 ca 80             	or     $0xffffff80,%edx
  101322:	88 14 c5 a5 97 10 00 	mov    %dl,0x1097a5(,%eax,8)
  101329:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10132c:	8b 04 85 08 80 10 00 	mov    0x108008(,%eax,4),%eax
  101333:	c1 e8 10             	shr    $0x10,%eax
  101336:	89 c2                	mov    %eax,%edx
  101338:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10133b:	66 89 14 c5 a6 97 10 	mov    %dx,0x1097a6(,%eax,8)
  101342:	00 
	extern segdesc gdt[];

	//panic("trap_init() not implemented.");

	int i;
	for (i=0; i<256; i++) {
  101343:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  101347:	81 7d fc ff 00 00 00 	cmpl   $0xff,-0x4(%ebp)
  10134e:	0f 8e 30 ff ff ff    	jle    101284 <trap_init_idt+0x12>
		SETGATE(idt[i], 0, CPU_GDT_KCODE, vectors[i], 0); //CPU_GDT_KCODE is 0x08
	}
	SETGATE(idt[3], 0, CPU_GDT_KCODE, vectors[3], 3); //T_BRKPT
  101354:	a1 14 80 10 00       	mov    0x108014,%eax
  101359:	66 a3 b8 97 10 00    	mov    %ax,0x1097b8
  10135f:	66 c7 05 ba 97 10 00 	movw   $0x8,0x1097ba
  101366:	08 00 
  101368:	0f b6 05 bc 97 10 00 	movzbl 0x1097bc,%eax
  10136f:	83 e0 e0             	and    $0xffffffe0,%eax
  101372:	a2 bc 97 10 00       	mov    %al,0x1097bc
  101377:	0f b6 05 bc 97 10 00 	movzbl 0x1097bc,%eax
  10137e:	83 e0 1f             	and    $0x1f,%eax
  101381:	a2 bc 97 10 00       	mov    %al,0x1097bc
  101386:	0f b6 05 bd 97 10 00 	movzbl 0x1097bd,%eax
  10138d:	83 e0 f0             	and    $0xfffffff0,%eax
  101390:	83 c8 0e             	or     $0xe,%eax
  101393:	a2 bd 97 10 00       	mov    %al,0x1097bd
  101398:	0f b6 05 bd 97 10 00 	movzbl 0x1097bd,%eax
  10139f:	83 e0 ef             	and    $0xffffffef,%eax
  1013a2:	a2 bd 97 10 00       	mov    %al,0x1097bd
  1013a7:	0f b6 05 bd 97 10 00 	movzbl 0x1097bd,%eax
  1013ae:	83 c8 60             	or     $0x60,%eax
  1013b1:	a2 bd 97 10 00       	mov    %al,0x1097bd
  1013b6:	0f b6 05 bd 97 10 00 	movzbl 0x1097bd,%eax
  1013bd:	83 c8 80             	or     $0xffffff80,%eax
  1013c0:	a2 bd 97 10 00       	mov    %al,0x1097bd
  1013c5:	a1 14 80 10 00       	mov    0x108014,%eax
  1013ca:	c1 e8 10             	shr    $0x10,%eax
  1013cd:	66 a3 be 97 10 00    	mov    %ax,0x1097be
	SETGATE(idt[4], 0, CPU_GDT_KCODE, vectors[4], 3); //T_OFLOW
  1013d3:	a1 18 80 10 00       	mov    0x108018,%eax
  1013d8:	66 a3 c0 97 10 00    	mov    %ax,0x1097c0
  1013de:	66 c7 05 c2 97 10 00 	movw   $0x8,0x1097c2
  1013e5:	08 00 
  1013e7:	0f b6 05 c4 97 10 00 	movzbl 0x1097c4,%eax
  1013ee:	83 e0 e0             	and    $0xffffffe0,%eax
  1013f1:	a2 c4 97 10 00       	mov    %al,0x1097c4
  1013f6:	0f b6 05 c4 97 10 00 	movzbl 0x1097c4,%eax
  1013fd:	83 e0 1f             	and    $0x1f,%eax
  101400:	a2 c4 97 10 00       	mov    %al,0x1097c4
  101405:	0f b6 05 c5 97 10 00 	movzbl 0x1097c5,%eax
  10140c:	83 e0 f0             	and    $0xfffffff0,%eax
  10140f:	83 c8 0e             	or     $0xe,%eax
  101412:	a2 c5 97 10 00       	mov    %al,0x1097c5
  101417:	0f b6 05 c5 97 10 00 	movzbl 0x1097c5,%eax
  10141e:	83 e0 ef             	and    $0xffffffef,%eax
  101421:	a2 c5 97 10 00       	mov    %al,0x1097c5
  101426:	0f b6 05 c5 97 10 00 	movzbl 0x1097c5,%eax
  10142d:	83 c8 60             	or     $0x60,%eax
  101430:	a2 c5 97 10 00       	mov    %al,0x1097c5
  101435:	0f b6 05 c5 97 10 00 	movzbl 0x1097c5,%eax
  10143c:	83 c8 80             	or     $0xffffff80,%eax
  10143f:	a2 c5 97 10 00       	mov    %al,0x1097c5
  101444:	a1 18 80 10 00       	mov    0x108018,%eax
  101449:	c1 e8 10             	shr    $0x10,%eax
  10144c:	66 a3 c6 97 10 00    	mov    %ax,0x1097c6

}
  101452:	c9                   	leave  
  101453:	c3                   	ret    

00101454 <trap_init>:

void
trap_init(void)
{
  101454:	55                   	push   %ebp
  101455:	89 e5                	mov    %esp,%ebp
  101457:	83 ec 08             	sub    $0x8,%esp
	// The first time we get called on the bootstrap processor,
	// initialize the IDT.  Other CPUs will share the same IDT.
	if (cpu_onboot())
  10145a:	e8 fb fd ff ff       	call   10125a <cpu_onboot>
  10145f:	85 c0                	test   %eax,%eax
  101461:	74 05                	je     101468 <trap_init+0x14>
		trap_init_idt();
  101463:	e8 0a fe ff ff       	call   101272 <trap_init_idt>

	// Load the IDT into this processor's IDT register.
	asm volatile("lidt %0" : : "m" (idt_pd));
  101468:	0f 01 1d 00 80 10 00 	lidtl  0x108000

	// Check for the correct IDT and trap handler operation.
	if (cpu_onboot())
  10146f:	e8 e6 fd ff ff       	call   10125a <cpu_onboot>
  101474:	85 c0                	test   %eax,%eax
  101476:	74 05                	je     10147d <trap_init+0x29>
		trap_check_kernel();
  101478:	e8 82 02 00 00       	call   1016ff <trap_check_kernel>
}
  10147d:	c9                   	leave  
  10147e:	c3                   	ret    

0010147f <trap_name>:

const char *trap_name(int trapno)
{
  10147f:	55                   	push   %ebp
  101480:	89 e5                	mov    %esp,%ebp
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
  101482:	8b 45 08             	mov    0x8(%ebp),%eax
  101485:	83 f8 13             	cmp    $0x13,%eax
  101488:	77 0c                	ja     101496 <trap_name+0x17>
		return excnames[trapno];
  10148a:	8b 45 08             	mov    0x8(%ebp),%eax
  10148d:	8b 04 85 80 3a 10 00 	mov    0x103a80(,%eax,4),%eax
  101494:	eb 25                	jmp    1014bb <trap_name+0x3c>
	if (trapno == T_SYSCALL)
  101496:	83 7d 08 30          	cmpl   $0x30,0x8(%ebp)
  10149a:	75 07                	jne    1014a3 <trap_name+0x24>
		return "System call";
  10149c:	b8 b8 36 10 00       	mov    $0x1036b8,%eax
  1014a1:	eb 18                	jmp    1014bb <trap_name+0x3c>
	if (trapno >= T_IRQ0 && trapno < T_IRQ0 + 16)
  1014a3:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
  1014a7:	7e 0d                	jle    1014b6 <trap_name+0x37>
  1014a9:	83 7d 08 2f          	cmpl   $0x2f,0x8(%ebp)
  1014ad:	7f 07                	jg     1014b6 <trap_name+0x37>
		return "Hardware Interrupt";
  1014af:	b8 c4 36 10 00       	mov    $0x1036c4,%eax
  1014b4:	eb 05                	jmp    1014bb <trap_name+0x3c>
	return "(unknown trap)";
  1014b6:	b8 d7 36 10 00       	mov    $0x1036d7,%eax
}
  1014bb:	5d                   	pop    %ebp
  1014bc:	c3                   	ret    

001014bd <trap_print_regs>:

void
trap_print_regs(pushregs *regs)
{
  1014bd:	55                   	push   %ebp
  1014be:	89 e5                	mov    %esp,%ebp
  1014c0:	83 ec 18             	sub    $0x18,%esp
	cprintf("  edi  0x%08x\n", regs->edi);
  1014c3:	8b 45 08             	mov    0x8(%ebp),%eax
  1014c6:	8b 00                	mov    (%eax),%eax
  1014c8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1014cc:	c7 04 24 e6 36 10 00 	movl   $0x1036e6,(%esp)
  1014d3:	e8 50 15 00 00       	call   102a28 <cprintf>
	cprintf("  esi  0x%08x\n", regs->esi);
  1014d8:	8b 45 08             	mov    0x8(%ebp),%eax
  1014db:	8b 40 04             	mov    0x4(%eax),%eax
  1014de:	89 44 24 04          	mov    %eax,0x4(%esp)
  1014e2:	c7 04 24 f5 36 10 00 	movl   $0x1036f5,(%esp)
  1014e9:	e8 3a 15 00 00       	call   102a28 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->ebp);
  1014ee:	8b 45 08             	mov    0x8(%ebp),%eax
  1014f1:	8b 40 08             	mov    0x8(%eax),%eax
  1014f4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1014f8:	c7 04 24 04 37 10 00 	movl   $0x103704,(%esp)
  1014ff:	e8 24 15 00 00       	call   102a28 <cprintf>
//	cprintf("  oesp 0x%08x\n", regs->oesp);	don't print - useless
	cprintf("  ebx  0x%08x\n", regs->ebx);
  101504:	8b 45 08             	mov    0x8(%ebp),%eax
  101507:	8b 40 10             	mov    0x10(%eax),%eax
  10150a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10150e:	c7 04 24 13 37 10 00 	movl   $0x103713,(%esp)
  101515:	e8 0e 15 00 00       	call   102a28 <cprintf>
	cprintf("  edx  0x%08x\n", regs->edx);
  10151a:	8b 45 08             	mov    0x8(%ebp),%eax
  10151d:	8b 40 14             	mov    0x14(%eax),%eax
  101520:	89 44 24 04          	mov    %eax,0x4(%esp)
  101524:	c7 04 24 22 37 10 00 	movl   $0x103722,(%esp)
  10152b:	e8 f8 14 00 00       	call   102a28 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->ecx);
  101530:	8b 45 08             	mov    0x8(%ebp),%eax
  101533:	8b 40 18             	mov    0x18(%eax),%eax
  101536:	89 44 24 04          	mov    %eax,0x4(%esp)
  10153a:	c7 04 24 31 37 10 00 	movl   $0x103731,(%esp)
  101541:	e8 e2 14 00 00       	call   102a28 <cprintf>
	cprintf("  eax  0x%08x\n", regs->eax);
  101546:	8b 45 08             	mov    0x8(%ebp),%eax
  101549:	8b 40 1c             	mov    0x1c(%eax),%eax
  10154c:	89 44 24 04          	mov    %eax,0x4(%esp)
  101550:	c7 04 24 40 37 10 00 	movl   $0x103740,(%esp)
  101557:	e8 cc 14 00 00       	call   102a28 <cprintf>
}
  10155c:	c9                   	leave  
  10155d:	c3                   	ret    

0010155e <trap_print>:

void
trap_print(trapframe *tf)
{
  10155e:	55                   	push   %ebp
  10155f:	89 e5                	mov    %esp,%ebp
  101561:	83 ec 18             	sub    $0x18,%esp
	cprintf("TRAP frame at %p\n", tf);
  101564:	8b 45 08             	mov    0x8(%ebp),%eax
  101567:	89 44 24 04          	mov    %eax,0x4(%esp)
  10156b:	c7 04 24 4f 37 10 00 	movl   $0x10374f,(%esp)
  101572:	e8 b1 14 00 00       	call   102a28 <cprintf>
	trap_print_regs(&tf->regs);
  101577:	8b 45 08             	mov    0x8(%ebp),%eax
  10157a:	89 04 24             	mov    %eax,(%esp)
  10157d:	e8 3b ff ff ff       	call   1014bd <trap_print_regs>
	cprintf("  es   0x----%04x\n", tf->es);
  101582:	8b 45 08             	mov    0x8(%ebp),%eax
  101585:	0f b7 40 28          	movzwl 0x28(%eax),%eax
  101589:	0f b7 c0             	movzwl %ax,%eax
  10158c:	89 44 24 04          	mov    %eax,0x4(%esp)
  101590:	c7 04 24 61 37 10 00 	movl   $0x103761,(%esp)
  101597:	e8 8c 14 00 00       	call   102a28 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->ds);
  10159c:	8b 45 08             	mov    0x8(%ebp),%eax
  10159f:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  1015a3:	0f b7 c0             	movzwl %ax,%eax
  1015a6:	89 44 24 04          	mov    %eax,0x4(%esp)
  1015aa:	c7 04 24 74 37 10 00 	movl   $0x103774,(%esp)
  1015b1:	e8 72 14 00 00       	call   102a28 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->trapno, trap_name(tf->trapno));
  1015b6:	8b 45 08             	mov    0x8(%ebp),%eax
  1015b9:	8b 40 30             	mov    0x30(%eax),%eax
  1015bc:	89 04 24             	mov    %eax,(%esp)
  1015bf:	e8 bb fe ff ff       	call   10147f <trap_name>
  1015c4:	8b 55 08             	mov    0x8(%ebp),%edx
  1015c7:	8b 52 30             	mov    0x30(%edx),%edx
  1015ca:	89 44 24 08          	mov    %eax,0x8(%esp)
  1015ce:	89 54 24 04          	mov    %edx,0x4(%esp)
  1015d2:	c7 04 24 87 37 10 00 	movl   $0x103787,(%esp)
  1015d9:	e8 4a 14 00 00       	call   102a28 <cprintf>
	cprintf("  err  0x%08x\n", tf->err);
  1015de:	8b 45 08             	mov    0x8(%ebp),%eax
  1015e1:	8b 40 34             	mov    0x34(%eax),%eax
  1015e4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1015e8:	c7 04 24 99 37 10 00 	movl   $0x103799,(%esp)
  1015ef:	e8 34 14 00 00       	call   102a28 <cprintf>
	cprintf("  eip  0x%08x\n", tf->eip);
  1015f4:	8b 45 08             	mov    0x8(%ebp),%eax
  1015f7:	8b 40 38             	mov    0x38(%eax),%eax
  1015fa:	89 44 24 04          	mov    %eax,0x4(%esp)
  1015fe:	c7 04 24 a8 37 10 00 	movl   $0x1037a8,(%esp)
  101605:	e8 1e 14 00 00       	call   102a28 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->cs);
  10160a:	8b 45 08             	mov    0x8(%ebp),%eax
  10160d:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  101611:	0f b7 c0             	movzwl %ax,%eax
  101614:	89 44 24 04          	mov    %eax,0x4(%esp)
  101618:	c7 04 24 b7 37 10 00 	movl   $0x1037b7,(%esp)
  10161f:	e8 04 14 00 00       	call   102a28 <cprintf>
	cprintf("  flag 0x%08x\n", tf->eflags);
  101624:	8b 45 08             	mov    0x8(%ebp),%eax
  101627:	8b 40 40             	mov    0x40(%eax),%eax
  10162a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10162e:	c7 04 24 ca 37 10 00 	movl   $0x1037ca,(%esp)
  101635:	e8 ee 13 00 00       	call   102a28 <cprintf>
	cprintf("  esp  0x%08x\n", tf->esp);
  10163a:	8b 45 08             	mov    0x8(%ebp),%eax
  10163d:	8b 40 44             	mov    0x44(%eax),%eax
  101640:	89 44 24 04          	mov    %eax,0x4(%esp)
  101644:	c7 04 24 d9 37 10 00 	movl   $0x1037d9,(%esp)
  10164b:	e8 d8 13 00 00       	call   102a28 <cprintf>
	cprintf("  ss   0x----%04x\n", tf->ss);
  101650:	8b 45 08             	mov    0x8(%ebp),%eax
  101653:	0f b7 40 48          	movzwl 0x48(%eax),%eax
  101657:	0f b7 c0             	movzwl %ax,%eax
  10165a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10165e:	c7 04 24 e8 37 10 00 	movl   $0x1037e8,(%esp)
  101665:	e8 be 13 00 00       	call   102a28 <cprintf>
}
  10166a:	c9                   	leave  
  10166b:	c3                   	ret    

0010166c <trap>:

void gcc_noreturn
trap(trapframe *tf)
{
  10166c:	55                   	push   %ebp
  10166d:	89 e5                	mov    %esp,%ebp
  10166f:	83 ec 28             	sub    $0x28,%esp
	// The user-level environment may have set the DF flag,
	// and some versions of GCC rely on DF being clear.
	asm volatile("cld" ::: "cc");
  101672:	fc                   	cld    

	// If this trap was anticipated, just use the designated handler.
	cpu *c = cpu_cur();
  101673:	e8 88 fb ff ff       	call   101200 <cpu_cur>
  101678:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (c->recover)
  10167b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10167e:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  101684:	85 c0                	test   %eax,%eax
  101686:	74 1e                	je     1016a6 <trap+0x3a>
		c->recover(tf, c->recoverdata);
  101688:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10168b:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  101691:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101694:	8b 92 a4 00 00 00    	mov    0xa4(%edx),%edx
  10169a:	89 54 24 04          	mov    %edx,0x4(%esp)
  10169e:	8b 55 08             	mov    0x8(%ebp),%edx
  1016a1:	89 14 24             	mov    %edx,(%esp)
  1016a4:	ff d0                	call   *%eax

	trap_print(tf);
  1016a6:	8b 45 08             	mov    0x8(%ebp),%eax
  1016a9:	89 04 24             	mov    %eax,(%esp)
  1016ac:	e8 ad fe ff ff       	call   10155e <trap_print>
	panic("unhandled trap");
  1016b1:	c7 44 24 08 fb 37 10 	movl   $0x1037fb,0x8(%esp)
  1016b8:	00 
  1016b9:	c7 44 24 04 8e 00 00 	movl   $0x8e,0x4(%esp)
  1016c0:	00 
  1016c1:	c7 04 24 0a 38 10 00 	movl   $0x10380a,(%esp)
  1016c8:	e8 a3 ec ff ff       	call   100370 <debug_panic>

001016cd <trap_check_recover>:

// Helper function for trap_check_recover(), below:
// handles "anticipated" traps by simply resuming at a new EIP.
static void gcc_noreturn
trap_check_recover(trapframe *tf, void *recoverdata)
{
  1016cd:	55                   	push   %ebp
  1016ce:	89 e5                	mov    %esp,%ebp
  1016d0:	83 ec 28             	sub    $0x28,%esp
	trap_check_args *args = recoverdata;
  1016d3:	8b 45 0c             	mov    0xc(%ebp),%eax
  1016d6:	89 45 f4             	mov    %eax,-0xc(%ebp)
	tf->eip = (uint32_t) args->reip;	// Use recovery EIP on return
  1016d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1016dc:	8b 00                	mov    (%eax),%eax
  1016de:	89 c2                	mov    %eax,%edx
  1016e0:	8b 45 08             	mov    0x8(%ebp),%eax
  1016e3:	89 50 38             	mov    %edx,0x38(%eax)
	args->trapno = tf->trapno;		// Return trap number
  1016e6:	8b 45 08             	mov    0x8(%ebp),%eax
  1016e9:	8b 40 30             	mov    0x30(%eax),%eax
  1016ec:	89 c2                	mov    %eax,%edx
  1016ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1016f1:	89 50 04             	mov    %edx,0x4(%eax)
	trap_return(tf);
  1016f4:	8b 45 08             	mov    0x8(%ebp),%eax
  1016f7:	89 04 24             	mov    %eax,(%esp)
  1016fa:	e8 21 04 00 00       	call   101b20 <trap_return>

001016ff <trap_check_kernel>:

// Check for correct handling of traps from kernel mode.
// Called on the boot CPU after trap_init() and trap_setup().
void
trap_check_kernel(void)
{
  1016ff:	55                   	push   %ebp
  101700:	89 e5                	mov    %esp,%ebp
  101702:	53                   	push   %ebx
  101703:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  101706:	66 8c cb             	mov    %cs,%bx
  101709:	66 89 5d f2          	mov    %bx,-0xe(%ebp)
        return cs;
  10170d:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
	assert((read_cs() & 3) == 0);	// better be in kernel mode!
  101711:	0f b7 c0             	movzwl %ax,%eax
  101714:	83 e0 03             	and    $0x3,%eax
  101717:	85 c0                	test   %eax,%eax
  101719:	74 24                	je     10173f <trap_check_kernel+0x40>
  10171b:	c7 44 24 0c 16 38 10 	movl   $0x103816,0xc(%esp)
  101722:	00 
  101723:	c7 44 24 08 96 36 10 	movl   $0x103696,0x8(%esp)
  10172a:	00 
  10172b:	c7 44 24 04 a2 00 00 	movl   $0xa2,0x4(%esp)
  101732:	00 
  101733:	c7 04 24 0a 38 10 00 	movl   $0x10380a,(%esp)
  10173a:	e8 31 ec ff ff       	call   100370 <debug_panic>

	cpu *c = cpu_cur();
  10173f:	e8 bc fa ff ff       	call   101200 <cpu_cur>
  101744:	89 45 f4             	mov    %eax,-0xc(%ebp)
	c->recover = trap_check_recover;
  101747:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10174a:	c7 80 a0 00 00 00 cd 	movl   $0x1016cd,0xa0(%eax)
  101751:	16 10 00 
	trap_check(&c->recoverdata);
  101754:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101757:	05 a4 00 00 00       	add    $0xa4,%eax
  10175c:	89 04 24             	mov    %eax,(%esp)
  10175f:	e8 a3 00 00 00       	call   101807 <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  101764:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101767:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  10176e:	00 00 00 

	cprintf("trap_check_kernel() succeeded!\n");
  101771:	c7 04 24 2c 38 10 00 	movl   $0x10382c,(%esp)
  101778:	e8 ab 12 00 00       	call   102a28 <cprintf>
}
  10177d:	83 c4 24             	add    $0x24,%esp
  101780:	5b                   	pop    %ebx
  101781:	5d                   	pop    %ebp
  101782:	c3                   	ret    

00101783 <trap_check_user>:
// Called from user() in kern/init.c, only in lab 1.
// We assume the "current cpu" is always the boot cpu;
// this true only because lab 1 doesn't start any other CPUs.
void
trap_check_user(void)
{
  101783:	55                   	push   %ebp
  101784:	89 e5                	mov    %esp,%ebp
  101786:	53                   	push   %ebx
  101787:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  10178a:	66 8c cb             	mov    %cs,%bx
  10178d:	66 89 5d f2          	mov    %bx,-0xe(%ebp)
        return cs;
  101791:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
	assert((read_cs() & 3) == 3);	// better be in user mode!
  101795:	0f b7 c0             	movzwl %ax,%eax
  101798:	83 e0 03             	and    $0x3,%eax
  10179b:	83 f8 03             	cmp    $0x3,%eax
  10179e:	74 24                	je     1017c4 <trap_check_user+0x41>
  1017a0:	c7 44 24 0c 4c 38 10 	movl   $0x10384c,0xc(%esp)
  1017a7:	00 
  1017a8:	c7 44 24 08 96 36 10 	movl   $0x103696,0x8(%esp)
  1017af:	00 
  1017b0:	c7 44 24 04 b3 00 00 	movl   $0xb3,0x4(%esp)
  1017b7:	00 
  1017b8:	c7 04 24 0a 38 10 00 	movl   $0x10380a,(%esp)
  1017bf:	e8 ac eb ff ff       	call   100370 <debug_panic>

	cpu *c = &cpu_boot;	// cpu_cur doesn't work from user mode!
  1017c4:	c7 45 f4 00 70 10 00 	movl   $0x107000,-0xc(%ebp)
	c->recover = trap_check_recover;
  1017cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1017ce:	c7 80 a0 00 00 00 cd 	movl   $0x1016cd,0xa0(%eax)
  1017d5:	16 10 00 
	trap_check(&c->recoverdata);
  1017d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1017db:	05 a4 00 00 00       	add    $0xa4,%eax
  1017e0:	89 04 24             	mov    %eax,(%esp)
  1017e3:	e8 1f 00 00 00       	call   101807 <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  1017e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1017eb:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  1017f2:	00 00 00 

	cprintf("trap_check_user() succeeded!\n");
  1017f5:	c7 04 24 61 38 10 00 	movl   $0x103861,(%esp)
  1017fc:	e8 27 12 00 00       	call   102a28 <cprintf>
}
  101801:	83 c4 24             	add    $0x24,%esp
  101804:	5b                   	pop    %ebx
  101805:	5d                   	pop    %ebp
  101806:	c3                   	ret    

00101807 <trap_check>:
void after_priv();

// Multi-purpose trap checking function.
void
trap_check(void **argsp)
{
  101807:	55                   	push   %ebp
  101808:	89 e5                	mov    %esp,%ebp
  10180a:	57                   	push   %edi
  10180b:	56                   	push   %esi
  10180c:	53                   	push   %ebx
  10180d:	83 ec 3c             	sub    $0x3c,%esp
	volatile int cookie = 0xfeedface;
  101810:	c7 45 e0 ce fa ed fe 	movl   $0xfeedface,-0x20(%ebp)
	volatile trap_check_args args;
	*argsp = (void*)&args;	// provide args needed for trap recovery
  101817:	8b 45 08             	mov    0x8(%ebp),%eax
  10181a:	8d 55 d8             	lea    -0x28(%ebp),%edx
  10181d:	89 10                	mov    %edx,(%eax)

	// Try a divide by zero trap.
	// Be careful when using && to take the address of a label:
	// some versions of GCC (4.4.2 at least) will incorrectly try to
	// eliminate code it thinks is _only_ reachable via such a pointer.
	args.reip = after_div0;
  10181f:	c7 45 d8 2d 18 10 00 	movl   $0x10182d,-0x28(%ebp)
	asm volatile("div %0,%0; after_div0:" : : "r" (0));
  101826:	b8 00 00 00 00       	mov    $0x0,%eax
  10182b:	f7 f0                	div    %eax

0010182d <after_div0>:
	assert(args.trapno == T_DIVIDE);
  10182d:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101830:	85 c0                	test   %eax,%eax
  101832:	74 24                	je     101858 <after_div0+0x2b>
  101834:	c7 44 24 0c 7f 38 10 	movl   $0x10387f,0xc(%esp)
  10183b:	00 
  10183c:	c7 44 24 08 96 36 10 	movl   $0x103696,0x8(%esp)
  101843:	00 
  101844:	c7 44 24 04 d3 00 00 	movl   $0xd3,0x4(%esp)
  10184b:	00 
  10184c:	c7 04 24 0a 38 10 00 	movl   $0x10380a,(%esp)
  101853:	e8 18 eb ff ff       	call   100370 <debug_panic>

	// Make sure we got our correct stack back with us.
	// The asm ensures gcc uses ebp/esp to get the cookie.
	asm volatile("" : : : "eax","ebx","ecx","edx","esi","edi");
	assert(cookie == 0xfeedface);
  101858:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10185b:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  101860:	74 24                	je     101886 <after_div0+0x59>
  101862:	c7 44 24 0c 97 38 10 	movl   $0x103897,0xc(%esp)
  101869:	00 
  10186a:	c7 44 24 08 96 36 10 	movl   $0x103696,0x8(%esp)
  101871:	00 
  101872:	c7 44 24 04 d8 00 00 	movl   $0xd8,0x4(%esp)
  101879:	00 
  10187a:	c7 04 24 0a 38 10 00 	movl   $0x10380a,(%esp)
  101881:	e8 ea ea ff ff       	call   100370 <debug_panic>

	// Breakpoint trap
	args.reip = after_breakpoint;
  101886:	c7 45 d8 8e 18 10 00 	movl   $0x10188e,-0x28(%ebp)
	asm volatile("int3; after_breakpoint:");
  10188d:	cc                   	int3   

0010188e <after_breakpoint>:
	assert(args.trapno == T_BRKPT);
  10188e:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101891:	83 f8 03             	cmp    $0x3,%eax
  101894:	74 24                	je     1018ba <after_breakpoint+0x2c>
  101896:	c7 44 24 0c ac 38 10 	movl   $0x1038ac,0xc(%esp)
  10189d:	00 
  10189e:	c7 44 24 08 96 36 10 	movl   $0x103696,0x8(%esp)
  1018a5:	00 
  1018a6:	c7 44 24 04 dd 00 00 	movl   $0xdd,0x4(%esp)
  1018ad:	00 
  1018ae:	c7 04 24 0a 38 10 00 	movl   $0x10380a,(%esp)
  1018b5:	e8 b6 ea ff ff       	call   100370 <debug_panic>

	// Overflow trap
	args.reip = after_overflow;
  1018ba:	c7 45 d8 c9 18 10 00 	movl   $0x1018c9,-0x28(%ebp)
	asm volatile("addl %0,%0; into; after_overflow:" : : "r" (0x70000000));
  1018c1:	b8 00 00 00 70       	mov    $0x70000000,%eax
  1018c6:	01 c0                	add    %eax,%eax
  1018c8:	ce                   	into   

001018c9 <after_overflow>:
	assert(args.trapno == T_OFLOW);
  1018c9:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1018cc:	83 f8 04             	cmp    $0x4,%eax
  1018cf:	74 24                	je     1018f5 <after_overflow+0x2c>
  1018d1:	c7 44 24 0c c3 38 10 	movl   $0x1038c3,0xc(%esp)
  1018d8:	00 
  1018d9:	c7 44 24 08 96 36 10 	movl   $0x103696,0x8(%esp)
  1018e0:	00 
  1018e1:	c7 44 24 04 e2 00 00 	movl   $0xe2,0x4(%esp)
  1018e8:	00 
  1018e9:	c7 04 24 0a 38 10 00 	movl   $0x10380a,(%esp)
  1018f0:	e8 7b ea ff ff       	call   100370 <debug_panic>

	// Bounds trap
	args.reip = after_bound;
  1018f5:	c7 45 d8 12 19 10 00 	movl   $0x101912,-0x28(%ebp)
	int bounds[2] = { 1, 3 };
  1018fc:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
  101903:	c7 45 d4 03 00 00 00 	movl   $0x3,-0x2c(%ebp)
	asm volatile("boundl %0,%1; after_bound:" : : "r" (0), "m" (bounds[0]));
  10190a:	b8 00 00 00 00       	mov    $0x0,%eax
  10190f:	62 45 d0             	bound  %eax,-0x30(%ebp)

00101912 <after_bound>:
	assert(args.trapno == T_BOUND);
  101912:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101915:	83 f8 05             	cmp    $0x5,%eax
  101918:	74 24                	je     10193e <after_bound+0x2c>
  10191a:	c7 44 24 0c da 38 10 	movl   $0x1038da,0xc(%esp)
  101921:	00 
  101922:	c7 44 24 08 96 36 10 	movl   $0x103696,0x8(%esp)
  101929:	00 
  10192a:	c7 44 24 04 e8 00 00 	movl   $0xe8,0x4(%esp)
  101931:	00 
  101932:	c7 04 24 0a 38 10 00 	movl   $0x10380a,(%esp)
  101939:	e8 32 ea ff ff       	call   100370 <debug_panic>

	// Illegal instruction trap
	args.reip = after_illegal;
  10193e:	c7 45 d8 47 19 10 00 	movl   $0x101947,-0x28(%ebp)
	asm volatile("ud2; after_illegal:");	// guaranteed to be undefined
  101945:	0f 0b                	ud2    

00101947 <after_illegal>:
	assert(args.trapno == T_ILLOP);
  101947:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10194a:	83 f8 06             	cmp    $0x6,%eax
  10194d:	74 24                	je     101973 <after_illegal+0x2c>
  10194f:	c7 44 24 0c f1 38 10 	movl   $0x1038f1,0xc(%esp)
  101956:	00 
  101957:	c7 44 24 08 96 36 10 	movl   $0x103696,0x8(%esp)
  10195e:	00 
  10195f:	c7 44 24 04 ed 00 00 	movl   $0xed,0x4(%esp)
  101966:	00 
  101967:	c7 04 24 0a 38 10 00 	movl   $0x10380a,(%esp)
  10196e:	e8 fd e9 ff ff       	call   100370 <debug_panic>

	// General protection fault due to invalid segment load
	args.reip = after_gpfault;
  101973:	c7 45 d8 81 19 10 00 	movl   $0x101981,-0x28(%ebp)
	asm volatile("movl %0,%%fs; after_gpfault:" : : "r" (-1));
  10197a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  10197f:	8e e0                	mov    %eax,%fs

00101981 <after_gpfault>:
	assert(args.trapno == T_GPFLT);
  101981:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101984:	83 f8 0d             	cmp    $0xd,%eax
  101987:	74 24                	je     1019ad <after_gpfault+0x2c>
  101989:	c7 44 24 0c 08 39 10 	movl   $0x103908,0xc(%esp)
  101990:	00 
  101991:	c7 44 24 08 96 36 10 	movl   $0x103696,0x8(%esp)
  101998:	00 
  101999:	c7 44 24 04 f2 00 00 	movl   $0xf2,0x4(%esp)
  1019a0:	00 
  1019a1:	c7 04 24 0a 38 10 00 	movl   $0x10380a,(%esp)
  1019a8:	e8 c3 e9 ff ff       	call   100370 <debug_panic>

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  1019ad:	66 8c cb             	mov    %cs,%bx
  1019b0:	66 89 5d e6          	mov    %bx,-0x1a(%ebp)
        return cs;
  1019b4:	0f b7 45 e6          	movzwl -0x1a(%ebp),%eax

	// General protection fault due to privilege violation
	if (read_cs() & 3) {
  1019b8:	0f b7 c0             	movzwl %ax,%eax
  1019bb:	83 e0 03             	and    $0x3,%eax
  1019be:	85 c0                	test   %eax,%eax
  1019c0:	74 3a                	je     1019fc <after_priv+0x2c>
		args.reip = after_priv;
  1019c2:	c7 45 d8 d0 19 10 00 	movl   $0x1019d0,-0x28(%ebp)
		asm volatile("lidt %0; after_priv:" : : "m" (idt_pd));
  1019c9:	0f 01 1d 00 80 10 00 	lidtl  0x108000

001019d0 <after_priv>:
		assert(args.trapno == T_GPFLT);
  1019d0:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1019d3:	83 f8 0d             	cmp    $0xd,%eax
  1019d6:	74 24                	je     1019fc <after_priv+0x2c>
  1019d8:	c7 44 24 0c 08 39 10 	movl   $0x103908,0xc(%esp)
  1019df:	00 
  1019e0:	c7 44 24 08 96 36 10 	movl   $0x103696,0x8(%esp)
  1019e7:	00 
  1019e8:	c7 44 24 04 f8 00 00 	movl   $0xf8,0x4(%esp)
  1019ef:	00 
  1019f0:	c7 04 24 0a 38 10 00 	movl   $0x10380a,(%esp)
  1019f7:	e8 74 e9 ff ff       	call   100370 <debug_panic>
	}

	// Make sure our stack cookie is still with us
	assert(cookie == 0xfeedface);
  1019fc:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1019ff:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  101a04:	74 24                	je     101a2a <after_priv+0x5a>
  101a06:	c7 44 24 0c 97 38 10 	movl   $0x103897,0xc(%esp)
  101a0d:	00 
  101a0e:	c7 44 24 08 96 36 10 	movl   $0x103696,0x8(%esp)
  101a15:	00 
  101a16:	c7 44 24 04 fc 00 00 	movl   $0xfc,0x4(%esp)
  101a1d:	00 
  101a1e:	c7 04 24 0a 38 10 00 	movl   $0x10380a,(%esp)
  101a25:	e8 46 e9 ff ff       	call   100370 <debug_panic>

	*argsp = NULL;	// recovery mechanism not needed anymore
  101a2a:	8b 45 08             	mov    0x8(%ebp),%eax
  101a2d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
  101a33:	83 c4 3c             	add    $0x3c,%esp
  101a36:	5b                   	pop    %ebx
  101a37:	5e                   	pop    %esi
  101a38:	5f                   	pop    %edi
  101a39:	5d                   	pop    %ebp
  101a3a:	c3                   	ret    
  101a3b:	90                   	nop
  101a3c:	90                   	nop
  101a3d:	90                   	nop
  101a3e:	90                   	nop
  101a3f:	90                   	nop

00101a40 <vector0>:
//TRAPHANDLER_NOEC(trap_ltimer,  T_LTIMER)
//TRAPHANDLER_NOEC(trap_lerror,  T_LERROR)
//TRAPHANDLER	(trap_default, T_DEFAULT)
//TRAPHANDLER	(trap_icnt,    T_ICNT)

TRAPHANDLER_NOEC(vector0,0)		// divide error
  101a40:	6a 00                	push   $0x0
  101a42:	6a 00                	push   $0x0
  101a44:	e9 b7 00 00 00       	jmp    101b00 <_alltraps>
  101a49:	90                   	nop

00101a4a <vector1>:
TRAPHANDLER_NOEC(vector1,1)		// debug exception
  101a4a:	6a 00                	push   $0x0
  101a4c:	6a 01                	push   $0x1
  101a4e:	e9 ad 00 00 00       	jmp    101b00 <_alltraps>
  101a53:	90                   	nop

00101a54 <vector2>:
TRAPHANDLER_NOEC(vector2,2)		// non-maskable interrupt
  101a54:	6a 00                	push   $0x0
  101a56:	6a 02                	push   $0x2
  101a58:	e9 a3 00 00 00       	jmp    101b00 <_alltraps>
  101a5d:	90                   	nop

00101a5e <vector3>:
TRAPHANDLER_NOEC(vector3,3)		// breakpoint
  101a5e:	6a 00                	push   $0x0
  101a60:	6a 03                	push   $0x3
  101a62:	e9 99 00 00 00       	jmp    101b00 <_alltraps>
  101a67:	90                   	nop

00101a68 <vector4>:
TRAPHANDLER_NOEC(vector4,4)		// overflow
  101a68:	6a 00                	push   $0x0
  101a6a:	6a 04                	push   $0x4
  101a6c:	e9 8f 00 00 00       	jmp    101b00 <_alltraps>
  101a71:	90                   	nop

00101a72 <vector5>:
TRAPHANDLER_NOEC(vector5,5)		// bounds check
  101a72:	6a 00                	push   $0x0
  101a74:	6a 05                	push   $0x5
  101a76:	e9 85 00 00 00       	jmp    101b00 <_alltraps>
  101a7b:	90                   	nop

00101a7c <vector6>:
TRAPHANDLER_NOEC(vector6,6)		// illegal opcode
  101a7c:	6a 00                	push   $0x0
  101a7e:	6a 06                	push   $0x6
  101a80:	e9 7b 00 00 00       	jmp    101b00 <_alltraps>
  101a85:	90                   	nop

00101a86 <vector7>:
TRAPHANDLER_NOEC(vector7,7)		// device not available 
  101a86:	6a 00                	push   $0x0
  101a88:	6a 07                	push   $0x7
  101a8a:	e9 71 00 00 00       	jmp    101b00 <_alltraps>
  101a8f:	90                   	nop

00101a90 <vector8>:
TRAPHANDLER(vector8,8)			// double fault
  101a90:	6a 08                	push   $0x8
  101a92:	e9 69 00 00 00       	jmp    101b00 <_alltraps>
  101a97:	90                   	nop

00101a98 <vector9>:
TRAPHANDLER_NOEC(vector9,9)		// reserved (not generated by recent processors)
  101a98:	6a 00                	push   $0x0
  101a9a:	6a 09                	push   $0x9
  101a9c:	e9 5f 00 00 00       	jmp    101b00 <_alltraps>
  101aa1:	90                   	nop

00101aa2 <vector10>:
TRAPHANDLER(vector10,10)		// invalid task switch segment
  101aa2:	6a 0a                	push   $0xa
  101aa4:	e9 57 00 00 00       	jmp    101b00 <_alltraps>
  101aa9:	90                   	nop

00101aaa <vector11>:
TRAPHANDLER(vector11,11)		// segment not present
  101aaa:	6a 0b                	push   $0xb
  101aac:	e9 4f 00 00 00       	jmp    101b00 <_alltraps>
  101ab1:	90                   	nop

00101ab2 <vector12>:
TRAPHANDLER(vector12,12)		// stack exception
  101ab2:	6a 0c                	push   $0xc
  101ab4:	e9 47 00 00 00       	jmp    101b00 <_alltraps>
  101ab9:	90                   	nop

00101aba <vector13>:
TRAPHANDLER(vector13,13)		// general protection fault
  101aba:	6a 0d                	push   $0xd
  101abc:	e9 3f 00 00 00       	jmp    101b00 <_alltraps>
  101ac1:	90                   	nop

00101ac2 <vector14>:
TRAPHANDLER(vector14,14)		// page fault
  101ac2:	6a 0e                	push   $0xe
  101ac4:	e9 37 00 00 00       	jmp    101b00 <_alltraps>
  101ac9:	90                   	nop

00101aca <vector15>:
TRAPHANDLER_NOEC(vector15,15)		// reserved
  101aca:	6a 00                	push   $0x0
  101acc:	6a 0f                	push   $0xf
  101ace:	e9 2d 00 00 00       	jmp    101b00 <_alltraps>
  101ad3:	90                   	nop

00101ad4 <vector16>:
TRAPHANDLER_NOEC(vector16,16)		// floating point error
  101ad4:	6a 00                	push   $0x0
  101ad6:	6a 10                	push   $0x10
  101ad8:	e9 23 00 00 00       	jmp    101b00 <_alltraps>
  101add:	90                   	nop

00101ade <vector17>:
TRAPHANDLER(vector17,17)		// alignment check
  101ade:	6a 11                	push   $0x11
  101ae0:	e9 1b 00 00 00       	jmp    101b00 <_alltraps>
  101ae5:	90                   	nop

00101ae6 <vector18>:
TRAPHANDLER_NOEC(vector18,18)		// machine check
  101ae6:	6a 00                	push   $0x0
  101ae8:	6a 12                	push   $0x12
  101aea:	e9 11 00 00 00       	jmp    101b00 <_alltraps>
  101aef:	90                   	nop

00101af0 <vector19>:
TRAPHANDLER_NOEC(vector19,19)		// SIMD floating point error
  101af0:	6a 00                	push   $0x0
  101af2:	6a 13                	push   $0x13
  101af4:	e9 07 00 00 00       	jmp    101b00 <_alltraps>
  101af9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00101b00 <_alltraps>:
 */
.globl	_alltraps
.type	_alltraps,@function
.p2align 4, 0x90
_alltraps:
	pushl %ds
  101b00:	1e                   	push   %ds
	pushl %es
  101b01:	06                   	push   %es
	pushl %fs
  101b02:	0f a0                	push   %fs
	pushl %gs
  101b04:	0f a8                	push   %gs
	pushal
  101b06:	60                   	pusha  

	movw $CPU_GDT_KDATA, %ax
  101b07:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
  101b0b:	8e d8                	mov    %eax,%ds
	movw %ax, %es
  101b0d:	8e c0                	mov    %eax,%es
	//there is no SEG_KCPU in PIOS ,
	//so do not need to reset %fs , %gs

	pushl %esp //oesp
  101b0f:	54                   	push   %esp
	call trap
  101b10:	e8 57 fb ff ff       	call   10166c <trap>
  101b15:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  101b19:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00101b20 <trap_return>:
.p2align 4, 0x90		/* 16-byte alignment, nop filled */
trap_return:
/*
 * Lab 1: Your code here for trap_return
 */ //1: jmp 1b // just spin
	movl 4(%esp), %esp
  101b20:	8b 64 24 04          	mov    0x4(%esp),%esp
	//this step has been done in _alltrap
	//popl %esp
	popal 
  101b24:	61                   	popa   
	popl %gs
  101b25:	0f a9                	pop    %gs
	popl %fs
  101b27:	0f a1                	pop    %fs
	popl %es
  101b29:	07                   	pop    %es
	popl %ds
  101b2a:	1f                   	pop    %ds
	addl $8, %esp
  101b2b:	83 c4 08             	add    $0x8,%esp
	iret
  101b2e:	cf                   	iret   
  101b2f:	90                   	nop

00101b30 <video_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

void
video_init(void)
{
  101b30:	55                   	push   %ebp
  101b31:	89 e5                	mov    %esp,%ebp
  101b33:	53                   	push   %ebx
  101b34:	83 ec 34             	sub    $0x34,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	/* Get a pointer to the memory-mapped text display buffer. */
	cp = (uint16_t*) mem_ptr(CGA_BUF);
  101b37:	c7 45 f8 00 80 0b 00 	movl   $0xb8000,-0x8(%ebp)
	was = *cp;
  101b3e:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101b41:	0f b7 00             	movzwl (%eax),%eax
  101b44:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
	*cp = (uint16_t) 0xA55A;
  101b48:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101b4b:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
  101b50:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101b53:	0f b7 00             	movzwl (%eax),%eax
  101b56:	66 3d 5a a5          	cmp    $0xa55a,%ax
  101b5a:	74 13                	je     101b6f <video_init+0x3f>
		cp = (uint16_t*) mem_ptr(MONO_BUF);
  101b5c:	c7 45 f8 00 00 0b 00 	movl   $0xb0000,-0x8(%ebp)
		addr_6845 = MONO_BASE;
  101b63:	c7 05 a0 9f 10 00 b4 	movl   $0x3b4,0x109fa0
  101b6a:	03 00 00 
  101b6d:	eb 14                	jmp    101b83 <video_init+0x53>
	} else {
		*cp = was;
  101b6f:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101b72:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
  101b76:	66 89 10             	mov    %dx,(%eax)
		addr_6845 = CGA_BASE;
  101b79:	c7 05 a0 9f 10 00 d4 	movl   $0x3d4,0x109fa0
  101b80:	03 00 00 
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
  101b83:	a1 a0 9f 10 00       	mov    0x109fa0,%eax
  101b88:	89 45 ec             	mov    %eax,-0x14(%ebp)
  101b8b:	c6 45 eb 0e          	movb   $0xe,-0x15(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101b8f:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  101b93:	8b 55 ec             	mov    -0x14(%ebp),%edx
  101b96:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
  101b97:	a1 a0 9f 10 00       	mov    0x109fa0,%eax
  101b9c:	83 c0 01             	add    $0x1,%eax
  101b9f:	89 45 e4             	mov    %eax,-0x1c(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101ba2:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  101ba5:	89 55 c8             	mov    %edx,-0x38(%ebp)
  101ba8:	8b 55 c8             	mov    -0x38(%ebp),%edx
  101bab:	ec                   	in     (%dx),%al
  101bac:	89 c3                	mov    %eax,%ebx
  101bae:	88 5d e3             	mov    %bl,-0x1d(%ebp)
	return data;
  101bb1:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101bb5:	0f b6 c0             	movzbl %al,%eax
  101bb8:	c1 e0 08             	shl    $0x8,%eax
  101bbb:	89 45 f0             	mov    %eax,-0x10(%ebp)
	outb(addr_6845, 15);
  101bbe:	a1 a0 9f 10 00       	mov    0x109fa0,%eax
  101bc3:	89 45 dc             	mov    %eax,-0x24(%ebp)
  101bc6:	c6 45 db 0f          	movb   $0xf,-0x25(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101bca:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  101bce:	8b 55 dc             	mov    -0x24(%ebp),%edx
  101bd1:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
  101bd2:	a1 a0 9f 10 00       	mov    0x109fa0,%eax
  101bd7:	83 c0 01             	add    $0x1,%eax
  101bda:	89 45 d4             	mov    %eax,-0x2c(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101bdd:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  101be0:	89 55 c8             	mov    %edx,-0x38(%ebp)
  101be3:	8b 55 c8             	mov    -0x38(%ebp),%edx
  101be6:	ec                   	in     (%dx),%al
  101be7:	89 c3                	mov    %eax,%ebx
  101be9:	88 5d d3             	mov    %bl,-0x2d(%ebp)
	return data;
  101bec:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
  101bf0:	0f b6 c0             	movzbl %al,%eax
  101bf3:	09 45 f0             	or     %eax,-0x10(%ebp)

	crt_buf = (uint16_t*) cp;
  101bf6:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101bf9:	a3 a4 9f 10 00       	mov    %eax,0x109fa4
	crt_pos = pos;
  101bfe:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101c01:	66 a3 a8 9f 10 00    	mov    %ax,0x109fa8
}
  101c07:	83 c4 34             	add    $0x34,%esp
  101c0a:	5b                   	pop    %ebx
  101c0b:	5d                   	pop    %ebp
  101c0c:	c3                   	ret    

00101c0d <video_putc>:



void
video_putc(int c)
{
  101c0d:	55                   	push   %ebp
  101c0e:	89 e5                	mov    %esp,%ebp
  101c10:	53                   	push   %ebx
  101c11:	83 ec 44             	sub    $0x44,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
  101c14:	8b 45 08             	mov    0x8(%ebp),%eax
  101c17:	b0 00                	mov    $0x0,%al
  101c19:	85 c0                	test   %eax,%eax
  101c1b:	75 07                	jne    101c24 <video_putc+0x17>
		c |= 0x0700;
  101c1d:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)

	switch (c & 0xff) {
  101c24:	8b 45 08             	mov    0x8(%ebp),%eax
  101c27:	25 ff 00 00 00       	and    $0xff,%eax
  101c2c:	83 f8 09             	cmp    $0x9,%eax
  101c2f:	0f 84 ab 00 00 00    	je     101ce0 <video_putc+0xd3>
  101c35:	83 f8 09             	cmp    $0x9,%eax
  101c38:	7f 0a                	jg     101c44 <video_putc+0x37>
  101c3a:	83 f8 08             	cmp    $0x8,%eax
  101c3d:	74 14                	je     101c53 <video_putc+0x46>
  101c3f:	e9 da 00 00 00       	jmp    101d1e <video_putc+0x111>
  101c44:	83 f8 0a             	cmp    $0xa,%eax
  101c47:	74 4d                	je     101c96 <video_putc+0x89>
  101c49:	83 f8 0d             	cmp    $0xd,%eax
  101c4c:	74 58                	je     101ca6 <video_putc+0x99>
  101c4e:	e9 cb 00 00 00       	jmp    101d1e <video_putc+0x111>
	case '\b':
		if (crt_pos > 0) {
  101c53:	0f b7 05 a8 9f 10 00 	movzwl 0x109fa8,%eax
  101c5a:	66 85 c0             	test   %ax,%ax
  101c5d:	0f 84 e0 00 00 00    	je     101d43 <video_putc+0x136>
			crt_pos--;
  101c63:	0f b7 05 a8 9f 10 00 	movzwl 0x109fa8,%eax
  101c6a:	83 e8 01             	sub    $0x1,%eax
  101c6d:	66 a3 a8 9f 10 00    	mov    %ax,0x109fa8
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
  101c73:	a1 a4 9f 10 00       	mov    0x109fa4,%eax
  101c78:	0f b7 15 a8 9f 10 00 	movzwl 0x109fa8,%edx
  101c7f:	0f b7 d2             	movzwl %dx,%edx
  101c82:	01 d2                	add    %edx,%edx
  101c84:	01 c2                	add    %eax,%edx
  101c86:	8b 45 08             	mov    0x8(%ebp),%eax
  101c89:	b0 00                	mov    $0x0,%al
  101c8b:	83 c8 20             	or     $0x20,%eax
  101c8e:	66 89 02             	mov    %ax,(%edx)
		}
		break;
  101c91:	e9 ad 00 00 00       	jmp    101d43 <video_putc+0x136>
	case '\n':
		crt_pos += CRT_COLS;
  101c96:	0f b7 05 a8 9f 10 00 	movzwl 0x109fa8,%eax
  101c9d:	83 c0 50             	add    $0x50,%eax
  101ca0:	66 a3 a8 9f 10 00    	mov    %ax,0x109fa8
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
  101ca6:	0f b7 1d a8 9f 10 00 	movzwl 0x109fa8,%ebx
  101cad:	0f b7 0d a8 9f 10 00 	movzwl 0x109fa8,%ecx
  101cb4:	0f b7 c1             	movzwl %cx,%eax
  101cb7:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
  101cbd:	c1 e8 10             	shr    $0x10,%eax
  101cc0:	89 c2                	mov    %eax,%edx
  101cc2:	66 c1 ea 06          	shr    $0x6,%dx
  101cc6:	89 d0                	mov    %edx,%eax
  101cc8:	c1 e0 02             	shl    $0x2,%eax
  101ccb:	01 d0                	add    %edx,%eax
  101ccd:	c1 e0 04             	shl    $0x4,%eax
  101cd0:	89 ca                	mov    %ecx,%edx
  101cd2:	29 c2                	sub    %eax,%edx
  101cd4:	89 d8                	mov    %ebx,%eax
  101cd6:	29 d0                	sub    %edx,%eax
  101cd8:	66 a3 a8 9f 10 00    	mov    %ax,0x109fa8
		break;
  101cde:	eb 64                	jmp    101d44 <video_putc+0x137>
	case '\t':
		video_putc(' ');
  101ce0:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  101ce7:	e8 21 ff ff ff       	call   101c0d <video_putc>
		video_putc(' ');
  101cec:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  101cf3:	e8 15 ff ff ff       	call   101c0d <video_putc>
		video_putc(' ');
  101cf8:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  101cff:	e8 09 ff ff ff       	call   101c0d <video_putc>
		video_putc(' ');
  101d04:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  101d0b:	e8 fd fe ff ff       	call   101c0d <video_putc>
		video_putc(' ');
  101d10:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  101d17:	e8 f1 fe ff ff       	call   101c0d <video_putc>
		break;
  101d1c:	eb 26                	jmp    101d44 <video_putc+0x137>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
  101d1e:	8b 15 a4 9f 10 00    	mov    0x109fa4,%edx
  101d24:	0f b7 05 a8 9f 10 00 	movzwl 0x109fa8,%eax
  101d2b:	0f b7 c8             	movzwl %ax,%ecx
  101d2e:	01 c9                	add    %ecx,%ecx
  101d30:	01 d1                	add    %edx,%ecx
  101d32:	8b 55 08             	mov    0x8(%ebp),%edx
  101d35:	66 89 11             	mov    %dx,(%ecx)
  101d38:	83 c0 01             	add    $0x1,%eax
  101d3b:	66 a3 a8 9f 10 00    	mov    %ax,0x109fa8
		break;
  101d41:	eb 01                	jmp    101d44 <video_putc+0x137>
	case '\b':
		if (crt_pos > 0) {
			crt_pos--;
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
		}
		break;
  101d43:	90                   	nop
		crt_buf[crt_pos++] = c;		/* write the character */
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
  101d44:	0f b7 05 a8 9f 10 00 	movzwl 0x109fa8,%eax
  101d4b:	66 3d cf 07          	cmp    $0x7cf,%ax
  101d4f:	76 5b                	jbe    101dac <video_putc+0x19f>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
  101d51:	a1 a4 9f 10 00       	mov    0x109fa4,%eax
  101d56:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
  101d5c:	a1 a4 9f 10 00       	mov    0x109fa4,%eax
  101d61:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
  101d68:	00 
  101d69:	89 54 24 04          	mov    %edx,0x4(%esp)
  101d6d:	89 04 24             	mov    %eax,(%esp)
  101d70:	e8 06 0f 00 00       	call   102c7b <memmove>
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  101d75:	c7 45 f4 80 07 00 00 	movl   $0x780,-0xc(%ebp)
  101d7c:	eb 15                	jmp    101d93 <video_putc+0x186>
			crt_buf[i] = 0x0700 | ' ';
  101d7e:	a1 a4 9f 10 00       	mov    0x109fa4,%eax
  101d83:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101d86:	01 d2                	add    %edx,%edx
  101d88:	01 d0                	add    %edx,%eax
  101d8a:	66 c7 00 20 07       	movw   $0x720,(%eax)
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  101d8f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  101d93:	81 7d f4 cf 07 00 00 	cmpl   $0x7cf,-0xc(%ebp)
  101d9a:	7e e2                	jle    101d7e <video_putc+0x171>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
  101d9c:	0f b7 05 a8 9f 10 00 	movzwl 0x109fa8,%eax
  101da3:	83 e8 50             	sub    $0x50,%eax
  101da6:	66 a3 a8 9f 10 00    	mov    %ax,0x109fa8
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
  101dac:	a1 a0 9f 10 00       	mov    0x109fa0,%eax
  101db1:	89 45 f0             	mov    %eax,-0x10(%ebp)
  101db4:	c6 45 ef 0e          	movb   $0xe,-0x11(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101db8:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
  101dbc:	8b 55 f0             	mov    -0x10(%ebp),%edx
  101dbf:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
  101dc0:	0f b7 05 a8 9f 10 00 	movzwl 0x109fa8,%eax
  101dc7:	66 c1 e8 08          	shr    $0x8,%ax
  101dcb:	0f b6 c0             	movzbl %al,%eax
  101dce:	8b 15 a0 9f 10 00    	mov    0x109fa0,%edx
  101dd4:	83 c2 01             	add    $0x1,%edx
  101dd7:	89 55 e8             	mov    %edx,-0x18(%ebp)
  101dda:	88 45 e7             	mov    %al,-0x19(%ebp)
  101ddd:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  101de1:	8b 55 e8             	mov    -0x18(%ebp),%edx
  101de4:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
  101de5:	a1 a0 9f 10 00       	mov    0x109fa0,%eax
  101dea:	89 45 e0             	mov    %eax,-0x20(%ebp)
  101ded:	c6 45 df 0f          	movb   $0xf,-0x21(%ebp)
  101df1:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
  101df5:	8b 55 e0             	mov    -0x20(%ebp),%edx
  101df8:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
  101df9:	0f b7 05 a8 9f 10 00 	movzwl 0x109fa8,%eax
  101e00:	0f b6 c0             	movzbl %al,%eax
  101e03:	8b 15 a0 9f 10 00    	mov    0x109fa0,%edx
  101e09:	83 c2 01             	add    $0x1,%edx
  101e0c:	89 55 d8             	mov    %edx,-0x28(%ebp)
  101e0f:	88 45 d7             	mov    %al,-0x29(%ebp)
  101e12:	0f b6 45 d7          	movzbl -0x29(%ebp),%eax
  101e16:	8b 55 d8             	mov    -0x28(%ebp),%edx
  101e19:	ee                   	out    %al,(%dx)
}
  101e1a:	83 c4 44             	add    $0x44,%esp
  101e1d:	5b                   	pop    %ebx
  101e1e:	5d                   	pop    %ebp
  101e1f:	c3                   	ret    

00101e20 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
  101e20:	55                   	push   %ebp
  101e21:	89 e5                	mov    %esp,%ebp
  101e23:	53                   	push   %ebx
  101e24:	83 ec 44             	sub    $0x44,%esp
  101e27:	c7 45 ec 64 00 00 00 	movl   $0x64,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101e2e:	8b 55 ec             	mov    -0x14(%ebp),%edx
  101e31:	89 55 d4             	mov    %edx,-0x2c(%ebp)
  101e34:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  101e37:	ec                   	in     (%dx),%al
  101e38:	89 c3                	mov    %eax,%ebx
  101e3a:	88 5d eb             	mov    %bl,-0x15(%ebp)
	return data;
  101e3d:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
  101e41:	0f b6 c0             	movzbl %al,%eax
  101e44:	83 e0 01             	and    $0x1,%eax
  101e47:	85 c0                	test   %eax,%eax
  101e49:	75 0a                	jne    101e55 <kbd_proc_data+0x35>
		return -1;
  101e4b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  101e50:	e9 5f 01 00 00       	jmp    101fb4 <kbd_proc_data+0x194>
  101e55:	c7 45 e4 60 00 00 00 	movl   $0x60,-0x1c(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101e5c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  101e5f:	89 55 d4             	mov    %edx,-0x2c(%ebp)
  101e62:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  101e65:	ec                   	in     (%dx),%al
  101e66:	89 c3                	mov    %eax,%ebx
  101e68:	88 5d e3             	mov    %bl,-0x1d(%ebp)
	return data;
  101e6b:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax

	data = inb(KBDATAP);
  101e6f:	88 45 f3             	mov    %al,-0xd(%ebp)

	if (data == 0xE0) {
  101e72:	80 7d f3 e0          	cmpb   $0xe0,-0xd(%ebp)
  101e76:	75 17                	jne    101e8f <kbd_proc_data+0x6f>
		// E0 escape character
		shift |= E0ESC;
  101e78:	a1 ac 9f 10 00       	mov    0x109fac,%eax
  101e7d:	83 c8 40             	or     $0x40,%eax
  101e80:	a3 ac 9f 10 00       	mov    %eax,0x109fac
		return 0;
  101e85:	b8 00 00 00 00       	mov    $0x0,%eax
  101e8a:	e9 25 01 00 00       	jmp    101fb4 <kbd_proc_data+0x194>
	} else if (data & 0x80) {
  101e8f:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101e93:	84 c0                	test   %al,%al
  101e95:	79 47                	jns    101ede <kbd_proc_data+0xbe>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
  101e97:	a1 ac 9f 10 00       	mov    0x109fac,%eax
  101e9c:	83 e0 40             	and    $0x40,%eax
  101e9f:	85 c0                	test   %eax,%eax
  101ea1:	75 09                	jne    101eac <kbd_proc_data+0x8c>
  101ea3:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101ea7:	83 e0 7f             	and    $0x7f,%eax
  101eaa:	eb 04                	jmp    101eb0 <kbd_proc_data+0x90>
  101eac:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101eb0:	88 45 f3             	mov    %al,-0xd(%ebp)
		shift &= ~(shiftcode[data] | E0ESC);
  101eb3:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101eb7:	0f b6 80 60 80 10 00 	movzbl 0x108060(%eax),%eax
  101ebe:	83 c8 40             	or     $0x40,%eax
  101ec1:	0f b6 c0             	movzbl %al,%eax
  101ec4:	f7 d0                	not    %eax
  101ec6:	89 c2                	mov    %eax,%edx
  101ec8:	a1 ac 9f 10 00       	mov    0x109fac,%eax
  101ecd:	21 d0                	and    %edx,%eax
  101ecf:	a3 ac 9f 10 00       	mov    %eax,0x109fac
		return 0;
  101ed4:	b8 00 00 00 00       	mov    $0x0,%eax
  101ed9:	e9 d6 00 00 00       	jmp    101fb4 <kbd_proc_data+0x194>
	} else if (shift & E0ESC) {
  101ede:	a1 ac 9f 10 00       	mov    0x109fac,%eax
  101ee3:	83 e0 40             	and    $0x40,%eax
  101ee6:	85 c0                	test   %eax,%eax
  101ee8:	74 11                	je     101efb <kbd_proc_data+0xdb>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
  101eea:	80 4d f3 80          	orb    $0x80,-0xd(%ebp)
		shift &= ~E0ESC;
  101eee:	a1 ac 9f 10 00       	mov    0x109fac,%eax
  101ef3:	83 e0 bf             	and    $0xffffffbf,%eax
  101ef6:	a3 ac 9f 10 00       	mov    %eax,0x109fac
	}

	shift |= shiftcode[data];
  101efb:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101eff:	0f b6 80 60 80 10 00 	movzbl 0x108060(%eax),%eax
  101f06:	0f b6 d0             	movzbl %al,%edx
  101f09:	a1 ac 9f 10 00       	mov    0x109fac,%eax
  101f0e:	09 d0                	or     %edx,%eax
  101f10:	a3 ac 9f 10 00       	mov    %eax,0x109fac
	shift ^= togglecode[data];
  101f15:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101f19:	0f b6 80 60 81 10 00 	movzbl 0x108160(%eax),%eax
  101f20:	0f b6 d0             	movzbl %al,%edx
  101f23:	a1 ac 9f 10 00       	mov    0x109fac,%eax
  101f28:	31 d0                	xor    %edx,%eax
  101f2a:	a3 ac 9f 10 00       	mov    %eax,0x109fac

	c = charcode[shift & (CTL | SHIFT)][data];
  101f2f:	a1 ac 9f 10 00       	mov    0x109fac,%eax
  101f34:	83 e0 03             	and    $0x3,%eax
  101f37:	8b 14 85 60 85 10 00 	mov    0x108560(,%eax,4),%edx
  101f3e:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101f42:	01 d0                	add    %edx,%eax
  101f44:	0f b6 00             	movzbl (%eax),%eax
  101f47:	0f b6 c0             	movzbl %al,%eax
  101f4a:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (shift & CAPSLOCK) {
  101f4d:	a1 ac 9f 10 00       	mov    0x109fac,%eax
  101f52:	83 e0 08             	and    $0x8,%eax
  101f55:	85 c0                	test   %eax,%eax
  101f57:	74 22                	je     101f7b <kbd_proc_data+0x15b>
		if ('a' <= c && c <= 'z')
  101f59:	83 7d f4 60          	cmpl   $0x60,-0xc(%ebp)
  101f5d:	7e 0c                	jle    101f6b <kbd_proc_data+0x14b>
  101f5f:	83 7d f4 7a          	cmpl   $0x7a,-0xc(%ebp)
  101f63:	7f 06                	jg     101f6b <kbd_proc_data+0x14b>
			c += 'A' - 'a';
  101f65:	83 6d f4 20          	subl   $0x20,-0xc(%ebp)
  101f69:	eb 10                	jmp    101f7b <kbd_proc_data+0x15b>
		else if ('A' <= c && c <= 'Z')
  101f6b:	83 7d f4 40          	cmpl   $0x40,-0xc(%ebp)
  101f6f:	7e 0a                	jle    101f7b <kbd_proc_data+0x15b>
  101f71:	83 7d f4 5a          	cmpl   $0x5a,-0xc(%ebp)
  101f75:	7f 04                	jg     101f7b <kbd_proc_data+0x15b>
			c += 'a' - 'A';
  101f77:	83 45 f4 20          	addl   $0x20,-0xc(%ebp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
  101f7b:	a1 ac 9f 10 00       	mov    0x109fac,%eax
  101f80:	f7 d0                	not    %eax
  101f82:	83 e0 06             	and    $0x6,%eax
  101f85:	85 c0                	test   %eax,%eax
  101f87:	75 28                	jne    101fb1 <kbd_proc_data+0x191>
  101f89:	81 7d f4 e9 00 00 00 	cmpl   $0xe9,-0xc(%ebp)
  101f90:	75 1f                	jne    101fb1 <kbd_proc_data+0x191>
		cprintf("Rebooting!\n");
  101f92:	c7 04 24 d0 3a 10 00 	movl   $0x103ad0,(%esp)
  101f99:	e8 8a 0a 00 00       	call   102a28 <cprintf>
  101f9e:	c7 45 dc 92 00 00 00 	movl   $0x92,-0x24(%ebp)
  101fa5:	c6 45 db 03          	movb   $0x3,-0x25(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101fa9:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  101fad:	8b 55 dc             	mov    -0x24(%ebp),%edx
  101fb0:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
  101fb1:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  101fb4:	83 c4 44             	add    $0x44,%esp
  101fb7:	5b                   	pop    %ebx
  101fb8:	5d                   	pop    %ebp
  101fb9:	c3                   	ret    

00101fba <kbd_intr>:

void
kbd_intr(void)
{
  101fba:	55                   	push   %ebp
  101fbb:	89 e5                	mov    %esp,%ebp
  101fbd:	83 ec 18             	sub    $0x18,%esp
	cons_intr(kbd_proc_data);
  101fc0:	c7 04 24 20 1e 10 00 	movl   $0x101e20,(%esp)
  101fc7:	e8 6a e2 ff ff       	call   100236 <cons_intr>
}
  101fcc:	c9                   	leave  
  101fcd:	c3                   	ret    

00101fce <kbd_init>:

void
kbd_init(void)
{
  101fce:	55                   	push   %ebp
  101fcf:	89 e5                	mov    %esp,%ebp
}
  101fd1:	5d                   	pop    %ebp
  101fd2:	c3                   	ret    
  101fd3:	90                   	nop

00101fd4 <delay>:


// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
  101fd4:	55                   	push   %ebp
  101fd5:	89 e5                	mov    %esp,%ebp
  101fd7:	53                   	push   %ebx
  101fd8:	83 ec 24             	sub    $0x24,%esp
  101fdb:	c7 45 f8 84 00 00 00 	movl   $0x84,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101fe2:	8b 55 f8             	mov    -0x8(%ebp),%edx
  101fe5:	89 55 d8             	mov    %edx,-0x28(%ebp)
  101fe8:	8b 55 d8             	mov    -0x28(%ebp),%edx
  101feb:	ec                   	in     (%dx),%al
  101fec:	89 c3                	mov    %eax,%ebx
  101fee:	88 5d f7             	mov    %bl,-0x9(%ebp)
  101ff1:	c7 45 f0 84 00 00 00 	movl   $0x84,-0x10(%ebp)
  101ff8:	8b 55 f0             	mov    -0x10(%ebp),%edx
  101ffb:	89 55 d8             	mov    %edx,-0x28(%ebp)
  101ffe:	8b 55 d8             	mov    -0x28(%ebp),%edx
  102001:	ec                   	in     (%dx),%al
  102002:	89 c3                	mov    %eax,%ebx
  102004:	88 5d ef             	mov    %bl,-0x11(%ebp)
  102007:	c7 45 e8 84 00 00 00 	movl   $0x84,-0x18(%ebp)
  10200e:	8b 55 e8             	mov    -0x18(%ebp),%edx
  102011:	89 55 d8             	mov    %edx,-0x28(%ebp)
  102014:	8b 55 d8             	mov    -0x28(%ebp),%edx
  102017:	ec                   	in     (%dx),%al
  102018:	89 c3                	mov    %eax,%ebx
  10201a:	88 5d e7             	mov    %bl,-0x19(%ebp)
  10201d:	c7 45 e0 84 00 00 00 	movl   $0x84,-0x20(%ebp)
  102024:	8b 55 e0             	mov    -0x20(%ebp),%edx
  102027:	89 55 d8             	mov    %edx,-0x28(%ebp)
  10202a:	8b 55 d8             	mov    -0x28(%ebp),%edx
  10202d:	ec                   	in     (%dx),%al
  10202e:	89 c3                	mov    %eax,%ebx
  102030:	88 5d df             	mov    %bl,-0x21(%ebp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
  102033:	83 c4 24             	add    $0x24,%esp
  102036:	5b                   	pop    %ebx
  102037:	5d                   	pop    %ebp
  102038:	c3                   	ret    

00102039 <serial_proc_data>:

static int
serial_proc_data(void)
{
  102039:	55                   	push   %ebp
  10203a:	89 e5                	mov    %esp,%ebp
  10203c:	53                   	push   %ebx
  10203d:	83 ec 14             	sub    $0x14,%esp
  102040:	c7 45 f8 fd 03 00 00 	movl   $0x3fd,-0x8(%ebp)
  102047:	8b 55 f8             	mov    -0x8(%ebp),%edx
  10204a:	89 55 e8             	mov    %edx,-0x18(%ebp)
  10204d:	8b 55 e8             	mov    -0x18(%ebp),%edx
  102050:	ec                   	in     (%dx),%al
  102051:	89 c3                	mov    %eax,%ebx
  102053:	88 5d f7             	mov    %bl,-0x9(%ebp)
	return data;
  102056:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
  10205a:	0f b6 c0             	movzbl %al,%eax
  10205d:	83 e0 01             	and    $0x1,%eax
  102060:	85 c0                	test   %eax,%eax
  102062:	75 07                	jne    10206b <serial_proc_data+0x32>
		return -1;
  102064:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  102069:	eb 1d                	jmp    102088 <serial_proc_data+0x4f>
  10206b:	c7 45 f0 f8 03 00 00 	movl   $0x3f8,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  102072:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102075:	89 55 e8             	mov    %edx,-0x18(%ebp)
  102078:	8b 55 e8             	mov    -0x18(%ebp),%edx
  10207b:	ec                   	in     (%dx),%al
  10207c:	89 c3                	mov    %eax,%ebx
  10207e:	88 5d ef             	mov    %bl,-0x11(%ebp)
	return data;
  102081:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
	return inb(COM1+COM_RX);
  102085:	0f b6 c0             	movzbl %al,%eax
}
  102088:	83 c4 14             	add    $0x14,%esp
  10208b:	5b                   	pop    %ebx
  10208c:	5d                   	pop    %ebp
  10208d:	c3                   	ret    

0010208e <serial_intr>:

void
serial_intr(void)
{
  10208e:	55                   	push   %ebp
  10208f:	89 e5                	mov    %esp,%ebp
  102091:	83 ec 18             	sub    $0x18,%esp
	if (serial_exists)
  102094:	a1 e8 9f 30 00       	mov    0x309fe8,%eax
  102099:	85 c0                	test   %eax,%eax
  10209b:	74 0c                	je     1020a9 <serial_intr+0x1b>
		cons_intr(serial_proc_data);
  10209d:	c7 04 24 39 20 10 00 	movl   $0x102039,(%esp)
  1020a4:	e8 8d e1 ff ff       	call   100236 <cons_intr>
}
  1020a9:	c9                   	leave  
  1020aa:	c3                   	ret    

001020ab <serial_putc>:

void
serial_putc(int c)
{
  1020ab:	55                   	push   %ebp
  1020ac:	89 e5                	mov    %esp,%ebp
  1020ae:	53                   	push   %ebx
  1020af:	83 ec 24             	sub    $0x24,%esp
	if (!serial_exists)
  1020b2:	a1 e8 9f 30 00       	mov    0x309fe8,%eax
  1020b7:	85 c0                	test   %eax,%eax
  1020b9:	74 59                	je     102114 <serial_putc+0x69>
		return;

	int i;
	for (i = 0;
  1020bb:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  1020c2:	eb 09                	jmp    1020cd <serial_putc+0x22>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
  1020c4:	e8 0b ff ff ff       	call   101fd4 <delay>
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
  1020c9:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  1020cd:	c7 45 f4 fd 03 00 00 	movl   $0x3fd,-0xc(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1020d4:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1020d7:	89 55 d8             	mov    %edx,-0x28(%ebp)
  1020da:	8b 55 d8             	mov    -0x28(%ebp),%edx
  1020dd:	ec                   	in     (%dx),%al
  1020de:	89 c3                	mov    %eax,%ebx
  1020e0:	88 5d f3             	mov    %bl,-0xd(%ebp)
	return data;
  1020e3:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  1020e7:	0f b6 c0             	movzbl %al,%eax
  1020ea:	83 e0 20             	and    $0x20,%eax
{
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
  1020ed:	85 c0                	test   %eax,%eax
  1020ef:	75 09                	jne    1020fa <serial_putc+0x4f>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  1020f1:	81 7d f8 ff 31 00 00 	cmpl   $0x31ff,-0x8(%ebp)
  1020f8:	7e ca                	jle    1020c4 <serial_putc+0x19>
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
  1020fa:	8b 45 08             	mov    0x8(%ebp),%eax
  1020fd:	0f b6 c0             	movzbl %al,%eax
  102100:	c7 45 ec f8 03 00 00 	movl   $0x3f8,-0x14(%ebp)
  102107:	88 45 eb             	mov    %al,-0x15(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10210a:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  10210e:	8b 55 ec             	mov    -0x14(%ebp),%edx
  102111:	ee                   	out    %al,(%dx)
  102112:	eb 01                	jmp    102115 <serial_putc+0x6a>

void
serial_putc(int c)
{
	if (!serial_exists)
		return;
  102114:	90                   	nop
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
}
  102115:	83 c4 24             	add    $0x24,%esp
  102118:	5b                   	pop    %ebx
  102119:	5d                   	pop    %ebp
  10211a:	c3                   	ret    

0010211b <serial_init>:

void
serial_init(void)
{
  10211b:	55                   	push   %ebp
  10211c:	89 e5                	mov    %esp,%ebp
  10211e:	53                   	push   %ebx
  10211f:	83 ec 54             	sub    $0x54,%esp
  102122:	c7 45 f8 fa 03 00 00 	movl   $0x3fa,-0x8(%ebp)
  102129:	c6 45 f7 00          	movb   $0x0,-0x9(%ebp)
  10212d:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
  102131:	8b 55 f8             	mov    -0x8(%ebp),%edx
  102134:	ee                   	out    %al,(%dx)
  102135:	c7 45 f0 fb 03 00 00 	movl   $0x3fb,-0x10(%ebp)
  10213c:	c6 45 ef 80          	movb   $0x80,-0x11(%ebp)
  102140:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
  102144:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102147:	ee                   	out    %al,(%dx)
  102148:	c7 45 e8 f8 03 00 00 	movl   $0x3f8,-0x18(%ebp)
  10214f:	c6 45 e7 0c          	movb   $0xc,-0x19(%ebp)
  102153:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  102157:	8b 55 e8             	mov    -0x18(%ebp),%edx
  10215a:	ee                   	out    %al,(%dx)
  10215b:	c7 45 e0 f9 03 00 00 	movl   $0x3f9,-0x20(%ebp)
  102162:	c6 45 df 00          	movb   $0x0,-0x21(%ebp)
  102166:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
  10216a:	8b 55 e0             	mov    -0x20(%ebp),%edx
  10216d:	ee                   	out    %al,(%dx)
  10216e:	c7 45 d8 fb 03 00 00 	movl   $0x3fb,-0x28(%ebp)
  102175:	c6 45 d7 03          	movb   $0x3,-0x29(%ebp)
  102179:	0f b6 45 d7          	movzbl -0x29(%ebp),%eax
  10217d:	8b 55 d8             	mov    -0x28(%ebp),%edx
  102180:	ee                   	out    %al,(%dx)
  102181:	c7 45 d0 fc 03 00 00 	movl   $0x3fc,-0x30(%ebp)
  102188:	c6 45 cf 00          	movb   $0x0,-0x31(%ebp)
  10218c:	0f b6 45 cf          	movzbl -0x31(%ebp),%eax
  102190:	8b 55 d0             	mov    -0x30(%ebp),%edx
  102193:	ee                   	out    %al,(%dx)
  102194:	c7 45 c8 f9 03 00 00 	movl   $0x3f9,-0x38(%ebp)
  10219b:	c6 45 c7 01          	movb   $0x1,-0x39(%ebp)
  10219f:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
  1021a3:	8b 55 c8             	mov    -0x38(%ebp),%edx
  1021a6:	ee                   	out    %al,(%dx)
  1021a7:	c7 45 c0 fd 03 00 00 	movl   $0x3fd,-0x40(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1021ae:	8b 55 c0             	mov    -0x40(%ebp),%edx
  1021b1:	89 55 a8             	mov    %edx,-0x58(%ebp)
  1021b4:	8b 55 a8             	mov    -0x58(%ebp),%edx
  1021b7:	ec                   	in     (%dx),%al
  1021b8:	89 c3                	mov    %eax,%ebx
  1021ba:	88 5d bf             	mov    %bl,-0x41(%ebp)
	return data;
  1021bd:	0f b6 45 bf          	movzbl -0x41(%ebp),%eax
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
  1021c1:	3c ff                	cmp    $0xff,%al
  1021c3:	0f 95 c0             	setne  %al
  1021c6:	0f b6 c0             	movzbl %al,%eax
  1021c9:	a3 e8 9f 30 00       	mov    %eax,0x309fe8
  1021ce:	c7 45 b8 fa 03 00 00 	movl   $0x3fa,-0x48(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1021d5:	8b 55 b8             	mov    -0x48(%ebp),%edx
  1021d8:	89 55 a8             	mov    %edx,-0x58(%ebp)
  1021db:	8b 55 a8             	mov    -0x58(%ebp),%edx
  1021de:	ec                   	in     (%dx),%al
  1021df:	89 c3                	mov    %eax,%ebx
  1021e1:	88 5d b7             	mov    %bl,-0x49(%ebp)
  1021e4:	c7 45 b0 f8 03 00 00 	movl   $0x3f8,-0x50(%ebp)
  1021eb:	8b 55 b0             	mov    -0x50(%ebp),%edx
  1021ee:	89 55 a8             	mov    %edx,-0x58(%ebp)
  1021f1:	8b 55 a8             	mov    -0x58(%ebp),%edx
  1021f4:	ec                   	in     (%dx),%al
  1021f5:	89 c3                	mov    %eax,%ebx
  1021f7:	88 5d af             	mov    %bl,-0x51(%ebp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);
}
  1021fa:	83 c4 54             	add    $0x54,%esp
  1021fd:	5b                   	pop    %ebx
  1021fe:	5d                   	pop    %ebp
  1021ff:	c3                   	ret    

00102200 <nvram_read>:
#include <dev/nvram.h>


unsigned
nvram_read(unsigned reg)
{
  102200:	55                   	push   %ebp
  102201:	89 e5                	mov    %esp,%ebp
  102203:	53                   	push   %ebx
  102204:	83 ec 14             	sub    $0x14,%esp
	outb(IO_RTC, reg);
  102207:	8b 45 08             	mov    0x8(%ebp),%eax
  10220a:	0f b6 c0             	movzbl %al,%eax
  10220d:	c7 45 f8 70 00 00 00 	movl   $0x70,-0x8(%ebp)
  102214:	88 45 f7             	mov    %al,-0x9(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  102217:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
  10221b:	8b 55 f8             	mov    -0x8(%ebp),%edx
  10221e:	ee                   	out    %al,(%dx)
  10221f:	c7 45 f0 71 00 00 00 	movl   $0x71,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  102226:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102229:	89 55 e8             	mov    %edx,-0x18(%ebp)
  10222c:	8b 55 e8             	mov    -0x18(%ebp),%edx
  10222f:	ec                   	in     (%dx),%al
  102230:	89 c3                	mov    %eax,%ebx
  102232:	88 5d ef             	mov    %bl,-0x11(%ebp)
	return data;
  102235:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
	return inb(IO_RTC+1);
  102239:	0f b6 c0             	movzbl %al,%eax
}
  10223c:	83 c4 14             	add    $0x14,%esp
  10223f:	5b                   	pop    %ebx
  102240:	5d                   	pop    %ebp
  102241:	c3                   	ret    

00102242 <nvram_read16>:

unsigned
nvram_read16(unsigned r)
{
  102242:	55                   	push   %ebp
  102243:	89 e5                	mov    %esp,%ebp
  102245:	53                   	push   %ebx
  102246:	83 ec 04             	sub    $0x4,%esp
	return nvram_read(r) | (nvram_read(r + 1) << 8);
  102249:	8b 45 08             	mov    0x8(%ebp),%eax
  10224c:	89 04 24             	mov    %eax,(%esp)
  10224f:	e8 ac ff ff ff       	call   102200 <nvram_read>
  102254:	89 c3                	mov    %eax,%ebx
  102256:	8b 45 08             	mov    0x8(%ebp),%eax
  102259:	83 c0 01             	add    $0x1,%eax
  10225c:	89 04 24             	mov    %eax,(%esp)
  10225f:	e8 9c ff ff ff       	call   102200 <nvram_read>
  102264:	c1 e0 08             	shl    $0x8,%eax
  102267:	09 d8                	or     %ebx,%eax
}
  102269:	83 c4 04             	add    $0x4,%esp
  10226c:	5b                   	pop    %ebx
  10226d:	5d                   	pop    %ebp
  10226e:	c3                   	ret    

0010226f <nvram_write>:

void
nvram_write(unsigned reg, unsigned datum)
{
  10226f:	55                   	push   %ebp
  102270:	89 e5                	mov    %esp,%ebp
  102272:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  102275:	8b 45 08             	mov    0x8(%ebp),%eax
  102278:	0f b6 c0             	movzbl %al,%eax
  10227b:	c7 45 fc 70 00 00 00 	movl   $0x70,-0x4(%ebp)
  102282:	88 45 fb             	mov    %al,-0x5(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  102285:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  102289:	8b 55 fc             	mov    -0x4(%ebp),%edx
  10228c:	ee                   	out    %al,(%dx)
	outb(IO_RTC+1, datum);
  10228d:	8b 45 0c             	mov    0xc(%ebp),%eax
  102290:	0f b6 c0             	movzbl %al,%eax
  102293:	c7 45 f4 71 00 00 00 	movl   $0x71,-0xc(%ebp)
  10229a:	88 45 f3             	mov    %al,-0xd(%ebp)
  10229d:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1022a1:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1022a4:	ee                   	out    %al,(%dx)
}
  1022a5:	c9                   	leave  
  1022a6:	c3                   	ret    
  1022a7:	90                   	nop

001022a8 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static uintmax_t
getuint(printstate *st, va_list *ap)
{
  1022a8:	55                   	push   %ebp
  1022a9:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  1022ab:	8b 45 08             	mov    0x8(%ebp),%eax
  1022ae:	8b 40 18             	mov    0x18(%eax),%eax
  1022b1:	83 e0 02             	and    $0x2,%eax
  1022b4:	85 c0                	test   %eax,%eax
  1022b6:	74 1c                	je     1022d4 <getuint+0x2c>
		return va_arg(*ap, unsigned long long);
  1022b8:	8b 45 0c             	mov    0xc(%ebp),%eax
  1022bb:	8b 00                	mov    (%eax),%eax
  1022bd:	8d 50 08             	lea    0x8(%eax),%edx
  1022c0:	8b 45 0c             	mov    0xc(%ebp),%eax
  1022c3:	89 10                	mov    %edx,(%eax)
  1022c5:	8b 45 0c             	mov    0xc(%ebp),%eax
  1022c8:	8b 00                	mov    (%eax),%eax
  1022ca:	83 e8 08             	sub    $0x8,%eax
  1022cd:	8b 50 04             	mov    0x4(%eax),%edx
  1022d0:	8b 00                	mov    (%eax),%eax
  1022d2:	eb 47                	jmp    10231b <getuint+0x73>
	else if (st->flags & F_L)
  1022d4:	8b 45 08             	mov    0x8(%ebp),%eax
  1022d7:	8b 40 18             	mov    0x18(%eax),%eax
  1022da:	83 e0 01             	and    $0x1,%eax
  1022dd:	85 c0                	test   %eax,%eax
  1022df:	74 1e                	je     1022ff <getuint+0x57>
		return va_arg(*ap, unsigned long);
  1022e1:	8b 45 0c             	mov    0xc(%ebp),%eax
  1022e4:	8b 00                	mov    (%eax),%eax
  1022e6:	8d 50 04             	lea    0x4(%eax),%edx
  1022e9:	8b 45 0c             	mov    0xc(%ebp),%eax
  1022ec:	89 10                	mov    %edx,(%eax)
  1022ee:	8b 45 0c             	mov    0xc(%ebp),%eax
  1022f1:	8b 00                	mov    (%eax),%eax
  1022f3:	83 e8 04             	sub    $0x4,%eax
  1022f6:	8b 00                	mov    (%eax),%eax
  1022f8:	ba 00 00 00 00       	mov    $0x0,%edx
  1022fd:	eb 1c                	jmp    10231b <getuint+0x73>
	else
		return va_arg(*ap, unsigned int);
  1022ff:	8b 45 0c             	mov    0xc(%ebp),%eax
  102302:	8b 00                	mov    (%eax),%eax
  102304:	8d 50 04             	lea    0x4(%eax),%edx
  102307:	8b 45 0c             	mov    0xc(%ebp),%eax
  10230a:	89 10                	mov    %edx,(%eax)
  10230c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10230f:	8b 00                	mov    (%eax),%eax
  102311:	83 e8 04             	sub    $0x4,%eax
  102314:	8b 00                	mov    (%eax),%eax
  102316:	ba 00 00 00 00       	mov    $0x0,%edx
}
  10231b:	5d                   	pop    %ebp
  10231c:	c3                   	ret    

0010231d <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static intmax_t
getint(printstate *st, va_list *ap)
{
  10231d:	55                   	push   %ebp
  10231e:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  102320:	8b 45 08             	mov    0x8(%ebp),%eax
  102323:	8b 40 18             	mov    0x18(%eax),%eax
  102326:	83 e0 02             	and    $0x2,%eax
  102329:	85 c0                	test   %eax,%eax
  10232b:	74 1c                	je     102349 <getint+0x2c>
		return va_arg(*ap, long long);
  10232d:	8b 45 0c             	mov    0xc(%ebp),%eax
  102330:	8b 00                	mov    (%eax),%eax
  102332:	8d 50 08             	lea    0x8(%eax),%edx
  102335:	8b 45 0c             	mov    0xc(%ebp),%eax
  102338:	89 10                	mov    %edx,(%eax)
  10233a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10233d:	8b 00                	mov    (%eax),%eax
  10233f:	83 e8 08             	sub    $0x8,%eax
  102342:	8b 50 04             	mov    0x4(%eax),%edx
  102345:	8b 00                	mov    (%eax),%eax
  102347:	eb 47                	jmp    102390 <getint+0x73>
	else if (st->flags & F_L)
  102349:	8b 45 08             	mov    0x8(%ebp),%eax
  10234c:	8b 40 18             	mov    0x18(%eax),%eax
  10234f:	83 e0 01             	and    $0x1,%eax
  102352:	85 c0                	test   %eax,%eax
  102354:	74 1e                	je     102374 <getint+0x57>
		return va_arg(*ap, long);
  102356:	8b 45 0c             	mov    0xc(%ebp),%eax
  102359:	8b 00                	mov    (%eax),%eax
  10235b:	8d 50 04             	lea    0x4(%eax),%edx
  10235e:	8b 45 0c             	mov    0xc(%ebp),%eax
  102361:	89 10                	mov    %edx,(%eax)
  102363:	8b 45 0c             	mov    0xc(%ebp),%eax
  102366:	8b 00                	mov    (%eax),%eax
  102368:	83 e8 04             	sub    $0x4,%eax
  10236b:	8b 00                	mov    (%eax),%eax
  10236d:	89 c2                	mov    %eax,%edx
  10236f:	c1 fa 1f             	sar    $0x1f,%edx
  102372:	eb 1c                	jmp    102390 <getint+0x73>
	else
		return va_arg(*ap, int);
  102374:	8b 45 0c             	mov    0xc(%ebp),%eax
  102377:	8b 00                	mov    (%eax),%eax
  102379:	8d 50 04             	lea    0x4(%eax),%edx
  10237c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10237f:	89 10                	mov    %edx,(%eax)
  102381:	8b 45 0c             	mov    0xc(%ebp),%eax
  102384:	8b 00                	mov    (%eax),%eax
  102386:	83 e8 04             	sub    $0x4,%eax
  102389:	8b 00                	mov    (%eax),%eax
  10238b:	89 c2                	mov    %eax,%edx
  10238d:	c1 fa 1f             	sar    $0x1f,%edx
}
  102390:	5d                   	pop    %ebp
  102391:	c3                   	ret    

00102392 <putpad>:

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
  102392:	55                   	push   %ebp
  102393:	89 e5                	mov    %esp,%ebp
  102395:	83 ec 18             	sub    $0x18,%esp
	while (--st->width >= 0)
  102398:	eb 1a                	jmp    1023b4 <putpad+0x22>
		st->putch(st->padc, st->putdat);
  10239a:	8b 45 08             	mov    0x8(%ebp),%eax
  10239d:	8b 00                	mov    (%eax),%eax
  10239f:	8b 55 08             	mov    0x8(%ebp),%edx
  1023a2:	8b 4a 04             	mov    0x4(%edx),%ecx
  1023a5:	8b 55 08             	mov    0x8(%ebp),%edx
  1023a8:	8b 52 08             	mov    0x8(%edx),%edx
  1023ab:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  1023af:	89 14 24             	mov    %edx,(%esp)
  1023b2:	ff d0                	call   *%eax

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
	while (--st->width >= 0)
  1023b4:	8b 45 08             	mov    0x8(%ebp),%eax
  1023b7:	8b 40 0c             	mov    0xc(%eax),%eax
  1023ba:	8d 50 ff             	lea    -0x1(%eax),%edx
  1023bd:	8b 45 08             	mov    0x8(%ebp),%eax
  1023c0:	89 50 0c             	mov    %edx,0xc(%eax)
  1023c3:	8b 45 08             	mov    0x8(%ebp),%eax
  1023c6:	8b 40 0c             	mov    0xc(%eax),%eax
  1023c9:	85 c0                	test   %eax,%eax
  1023cb:	79 cd                	jns    10239a <putpad+0x8>
		st->putch(st->padc, st->putdat);
}
  1023cd:	c9                   	leave  
  1023ce:	c3                   	ret    

001023cf <putstr>:

// Print a string with a specified maximum length (-1=unlimited),
// with any appropriate left or right field padding.
static void
putstr(printstate *st, const char *str, int maxlen)
{
  1023cf:	55                   	push   %ebp
  1023d0:	89 e5                	mov    %esp,%ebp
  1023d2:	53                   	push   %ebx
  1023d3:	83 ec 24             	sub    $0x24,%esp
	const char *lim;		// find where the string actually ends
	if (maxlen < 0)
  1023d6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1023da:	79 18                	jns    1023f4 <putstr+0x25>
		lim = strchr(str, 0);	// find the terminating null
  1023dc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1023e3:	00 
  1023e4:	8b 45 0c             	mov    0xc(%ebp),%eax
  1023e7:	89 04 24             	mov    %eax,(%esp)
  1023ea:	e8 e6 07 00 00       	call   102bd5 <strchr>
  1023ef:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1023f2:	eb 2e                	jmp    102422 <putstr+0x53>
	else if ((lim = memchr(str, 0, maxlen)) == NULL)
  1023f4:	8b 45 10             	mov    0x10(%ebp),%eax
  1023f7:	89 44 24 08          	mov    %eax,0x8(%esp)
  1023fb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  102402:	00 
  102403:	8b 45 0c             	mov    0xc(%ebp),%eax
  102406:	89 04 24             	mov    %eax,(%esp)
  102409:	e8 c4 09 00 00       	call   102dd2 <memchr>
  10240e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  102411:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  102415:	75 0b                	jne    102422 <putstr+0x53>
		lim = str + maxlen;
  102417:	8b 55 10             	mov    0x10(%ebp),%edx
  10241a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10241d:	01 d0                	add    %edx,%eax
  10241f:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->width -= (lim-str);		// deduct string length from field width
  102422:	8b 45 08             	mov    0x8(%ebp),%eax
  102425:	8b 40 0c             	mov    0xc(%eax),%eax
  102428:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  10242b:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10242e:	89 cb                	mov    %ecx,%ebx
  102430:	29 d3                	sub    %edx,%ebx
  102432:	89 da                	mov    %ebx,%edx
  102434:	01 c2                	add    %eax,%edx
  102436:	8b 45 08             	mov    0x8(%ebp),%eax
  102439:	89 50 0c             	mov    %edx,0xc(%eax)

	if (!(st->flags & F_RPAD))	// print left-side padding
  10243c:	8b 45 08             	mov    0x8(%ebp),%eax
  10243f:	8b 40 18             	mov    0x18(%eax),%eax
  102442:	83 e0 10             	and    $0x10,%eax
  102445:	85 c0                	test   %eax,%eax
  102447:	75 32                	jne    10247b <putstr+0xac>
		putpad(st);		// (also leaves st->width == 0)
  102449:	8b 45 08             	mov    0x8(%ebp),%eax
  10244c:	89 04 24             	mov    %eax,(%esp)
  10244f:	e8 3e ff ff ff       	call   102392 <putpad>
	while (str < lim) {
  102454:	eb 25                	jmp    10247b <putstr+0xac>
		char ch = *str++;
  102456:	8b 45 0c             	mov    0xc(%ebp),%eax
  102459:	0f b6 00             	movzbl (%eax),%eax
  10245c:	88 45 f3             	mov    %al,-0xd(%ebp)
  10245f:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
			st->putch(ch, st->putdat);
  102463:	8b 45 08             	mov    0x8(%ebp),%eax
  102466:	8b 00                	mov    (%eax),%eax
  102468:	8b 55 08             	mov    0x8(%ebp),%edx
  10246b:	8b 4a 04             	mov    0x4(%edx),%ecx
  10246e:	0f be 55 f3          	movsbl -0xd(%ebp),%edx
  102472:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  102476:	89 14 24             	mov    %edx,(%esp)
  102479:	ff d0                	call   *%eax
		lim = str + maxlen;
	st->width -= (lim-str);		// deduct string length from field width

	if (!(st->flags & F_RPAD))	// print left-side padding
		putpad(st);		// (also leaves st->width == 0)
	while (str < lim) {
  10247b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10247e:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  102481:	72 d3                	jb     102456 <putstr+0x87>
		char ch = *str++;
			st->putch(ch, st->putdat);
	}
	putpad(st);			// print right-side padding
  102483:	8b 45 08             	mov    0x8(%ebp),%eax
  102486:	89 04 24             	mov    %eax,(%esp)
  102489:	e8 04 ff ff ff       	call   102392 <putpad>
}
  10248e:	83 c4 24             	add    $0x24,%esp
  102491:	5b                   	pop    %ebx
  102492:	5d                   	pop    %ebp
  102493:	c3                   	ret    

00102494 <genint>:

// Generate a number (base <= 16) in reverse order into a string buffer.
static char *
genint(printstate *st, char *p, uintmax_t num)
{
  102494:	55                   	push   %ebp
  102495:	89 e5                	mov    %esp,%ebp
  102497:	53                   	push   %ebx
  102498:	83 ec 24             	sub    $0x24,%esp
  10249b:	8b 45 10             	mov    0x10(%ebp),%eax
  10249e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1024a1:	8b 45 14             	mov    0x14(%ebp),%eax
  1024a4:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= st->base)
  1024a7:	8b 45 08             	mov    0x8(%ebp),%eax
  1024aa:	8b 40 1c             	mov    0x1c(%eax),%eax
  1024ad:	89 c2                	mov    %eax,%edx
  1024af:	c1 fa 1f             	sar    $0x1f,%edx
  1024b2:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  1024b5:	77 4e                	ja     102505 <genint+0x71>
  1024b7:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  1024ba:	72 05                	jb     1024c1 <genint+0x2d>
  1024bc:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  1024bf:	77 44                	ja     102505 <genint+0x71>
		p = genint(st, p, num / st->base);	// output higher digits
  1024c1:	8b 45 08             	mov    0x8(%ebp),%eax
  1024c4:	8b 40 1c             	mov    0x1c(%eax),%eax
  1024c7:	89 c2                	mov    %eax,%edx
  1024c9:	c1 fa 1f             	sar    $0x1f,%edx
  1024cc:	89 44 24 08          	mov    %eax,0x8(%esp)
  1024d0:	89 54 24 0c          	mov    %edx,0xc(%esp)
  1024d4:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1024d7:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1024da:	89 04 24             	mov    %eax,(%esp)
  1024dd:	89 54 24 04          	mov    %edx,0x4(%esp)
  1024e1:	e8 2a 09 00 00       	call   102e10 <__udivdi3>
  1024e6:	89 44 24 08          	mov    %eax,0x8(%esp)
  1024ea:	89 54 24 0c          	mov    %edx,0xc(%esp)
  1024ee:	8b 45 0c             	mov    0xc(%ebp),%eax
  1024f1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1024f5:	8b 45 08             	mov    0x8(%ebp),%eax
  1024f8:	89 04 24             	mov    %eax,(%esp)
  1024fb:	e8 94 ff ff ff       	call   102494 <genint>
  102500:	89 45 0c             	mov    %eax,0xc(%ebp)
  102503:	eb 1b                	jmp    102520 <genint+0x8c>
	else if (st->signc >= 0)
  102505:	8b 45 08             	mov    0x8(%ebp),%eax
  102508:	8b 40 14             	mov    0x14(%eax),%eax
  10250b:	85 c0                	test   %eax,%eax
  10250d:	78 11                	js     102520 <genint+0x8c>
		*p++ = st->signc;			// output leading sign
  10250f:	8b 45 08             	mov    0x8(%ebp),%eax
  102512:	8b 40 14             	mov    0x14(%eax),%eax
  102515:	89 c2                	mov    %eax,%edx
  102517:	8b 45 0c             	mov    0xc(%ebp),%eax
  10251a:	88 10                	mov    %dl,(%eax)
  10251c:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	*p++ = "0123456789abcdef"[num % st->base];	// output this digit
  102520:	8b 45 08             	mov    0x8(%ebp),%eax
  102523:	8b 40 1c             	mov    0x1c(%eax),%eax
  102526:	89 c1                	mov    %eax,%ecx
  102528:	89 c3                	mov    %eax,%ebx
  10252a:	c1 fb 1f             	sar    $0x1f,%ebx
  10252d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102530:	8b 55 f4             	mov    -0xc(%ebp),%edx
  102533:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  102537:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  10253b:	89 04 24             	mov    %eax,(%esp)
  10253e:	89 54 24 04          	mov    %edx,0x4(%esp)
  102542:	e8 29 0a 00 00       	call   102f70 <__umoddi3>
  102547:	05 dc 3a 10 00       	add    $0x103adc,%eax
  10254c:	0f b6 10             	movzbl (%eax),%edx
  10254f:	8b 45 0c             	mov    0xc(%ebp),%eax
  102552:	88 10                	mov    %dl,(%eax)
  102554:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	return p;
  102558:	8b 45 0c             	mov    0xc(%ebp),%eax
}
  10255b:	83 c4 24             	add    $0x24,%esp
  10255e:	5b                   	pop    %ebx
  10255f:	5d                   	pop    %ebp
  102560:	c3                   	ret    

00102561 <putint>:

// Print an integer with any appropriate field padding.
static void
putint(printstate *st, uintmax_t num, int base)
{
  102561:	55                   	push   %ebp
  102562:	89 e5                	mov    %esp,%ebp
  102564:	83 ec 58             	sub    $0x58,%esp
  102567:	8b 45 0c             	mov    0xc(%ebp),%eax
  10256a:	89 45 c0             	mov    %eax,-0x40(%ebp)
  10256d:	8b 45 10             	mov    0x10(%ebp),%eax
  102570:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	char buf[30], *p = buf;		// big enough for any 64-bit int in octal
  102573:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  102576:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->base = base;		// select base for genint
  102579:	8b 45 08             	mov    0x8(%ebp),%eax
  10257c:	8b 55 14             	mov    0x14(%ebp),%edx
  10257f:	89 50 1c             	mov    %edx,0x1c(%eax)
	p = genint(st, p, num);		// output to the string buffer
  102582:	8b 45 c0             	mov    -0x40(%ebp),%eax
  102585:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  102588:	89 44 24 08          	mov    %eax,0x8(%esp)
  10258c:	89 54 24 0c          	mov    %edx,0xc(%esp)
  102590:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102593:	89 44 24 04          	mov    %eax,0x4(%esp)
  102597:	8b 45 08             	mov    0x8(%ebp),%eax
  10259a:	89 04 24             	mov    %eax,(%esp)
  10259d:	e8 f2 fe ff ff       	call   102494 <genint>
  1025a2:	89 45 f4             	mov    %eax,-0xc(%ebp)
	putstr(st, buf, p-buf);		// print it with left/right padding
  1025a5:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1025a8:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  1025ab:	89 d1                	mov    %edx,%ecx
  1025ad:	29 c1                	sub    %eax,%ecx
  1025af:	89 c8                	mov    %ecx,%eax
  1025b1:	89 44 24 08          	mov    %eax,0x8(%esp)
  1025b5:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  1025b8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1025bc:	8b 45 08             	mov    0x8(%ebp),%eax
  1025bf:	89 04 24             	mov    %eax,(%esp)
  1025c2:	e8 08 fe ff ff       	call   1023cf <putstr>
}
  1025c7:	c9                   	leave  
  1025c8:	c3                   	ret    

001025c9 <vprintfmt>:
#endif	// ! PIOS_KERNEL

// Main function to format and print a string.
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  1025c9:	55                   	push   %ebp
  1025ca:	89 e5                	mov    %esp,%ebp
  1025cc:	53                   	push   %ebx
  1025cd:	83 ec 44             	sub    $0x44,%esp
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
  1025d0:	8d 55 cc             	lea    -0x34(%ebp),%edx
  1025d3:	b9 00 00 00 00       	mov    $0x0,%ecx
  1025d8:	b8 20 00 00 00       	mov    $0x20,%eax
  1025dd:	89 c3                	mov    %eax,%ebx
  1025df:	83 e3 fc             	and    $0xfffffffc,%ebx
  1025e2:	b8 00 00 00 00       	mov    $0x0,%eax
  1025e7:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
  1025ea:	83 c0 04             	add    $0x4,%eax
  1025ed:	39 d8                	cmp    %ebx,%eax
  1025ef:	72 f6                	jb     1025e7 <vprintfmt+0x1e>
  1025f1:	01 c2                	add    %eax,%edx
  1025f3:	8b 45 08             	mov    0x8(%ebp),%eax
  1025f6:	89 45 cc             	mov    %eax,-0x34(%ebp)
  1025f9:	8b 45 0c             	mov    0xc(%ebp),%eax
  1025fc:	89 45 d0             	mov    %eax,-0x30(%ebp)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  1025ff:	eb 17                	jmp    102618 <vprintfmt+0x4f>
			if (ch == '\0')
  102601:	85 db                	test   %ebx,%ebx
  102603:	0f 84 50 03 00 00    	je     102959 <vprintfmt+0x390>
				return;
			putch(ch, putdat);
  102609:	8b 45 0c             	mov    0xc(%ebp),%eax
  10260c:	89 44 24 04          	mov    %eax,0x4(%esp)
  102610:	89 1c 24             	mov    %ebx,(%esp)
  102613:	8b 45 08             	mov    0x8(%ebp),%eax
  102616:	ff d0                	call   *%eax
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  102618:	8b 45 10             	mov    0x10(%ebp),%eax
  10261b:	0f b6 00             	movzbl (%eax),%eax
  10261e:	0f b6 d8             	movzbl %al,%ebx
  102621:	83 fb 25             	cmp    $0x25,%ebx
  102624:	0f 95 c0             	setne  %al
  102627:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  10262b:	84 c0                	test   %al,%al
  10262d:	75 d2                	jne    102601 <vprintfmt+0x38>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		st.padc = ' ';
  10262f:	c7 45 d4 20 00 00 00 	movl   $0x20,-0x2c(%ebp)
		st.width = -1;
  102636:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		st.prec = -1;
  10263d:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		st.signc = -1;
  102644:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		st.flags = 0;
  10264b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		st.base = 10;
  102652:	c7 45 e8 0a 00 00 00 	movl   $0xa,-0x18(%ebp)
  102659:	eb 04                	jmp    10265f <vprintfmt+0x96>
			goto reswitch;

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
				st.signc = ' ';
			goto reswitch;
  10265b:	90                   	nop
  10265c:	eb 01                	jmp    10265f <vprintfmt+0x96>
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
				st.width = st.prec;	// then it's a field width
				st.prec = -1;
			}
			goto reswitch;
  10265e:	90                   	nop
		st.signc = -1;
		st.flags = 0;
		st.base = 10;
		uintmax_t num;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  10265f:	8b 45 10             	mov    0x10(%ebp),%eax
  102662:	0f b6 00             	movzbl (%eax),%eax
  102665:	0f b6 d8             	movzbl %al,%ebx
  102668:	89 d8                	mov    %ebx,%eax
  10266a:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  10266e:	83 e8 20             	sub    $0x20,%eax
  102671:	83 f8 58             	cmp    $0x58,%eax
  102674:	0f 87 ae 02 00 00    	ja     102928 <vprintfmt+0x35f>
  10267a:	8b 04 85 f4 3a 10 00 	mov    0x103af4(,%eax,4),%eax
  102681:	ff e0                	jmp    *%eax

		// modifier flags
		case '-': // pad on the right instead of the left
			st.flags |= F_RPAD;
  102683:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  102686:	83 c8 10             	or     $0x10,%eax
  102689:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
  10268c:	eb d1                	jmp    10265f <vprintfmt+0x96>

		case '+': // prefix positive numeric values with a '+' sign
			st.signc = '+';
  10268e:	c7 45 e0 2b 00 00 00 	movl   $0x2b,-0x20(%ebp)
			goto reswitch;
  102695:	eb c8                	jmp    10265f <vprintfmt+0x96>

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
  102697:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10269a:	85 c0                	test   %eax,%eax
  10269c:	79 bd                	jns    10265b <vprintfmt+0x92>
				st.signc = ' ';
  10269e:	c7 45 e0 20 00 00 00 	movl   $0x20,-0x20(%ebp)
			goto reswitch;
  1026a5:	eb b4                	jmp    10265b <vprintfmt+0x92>

		// width or precision field
		case '0':
			if (!(st.flags & F_DOT))
  1026a7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1026aa:	83 e0 08             	and    $0x8,%eax
  1026ad:	85 c0                	test   %eax,%eax
  1026af:	75 07                	jne    1026b8 <vprintfmt+0xef>
				st.padc = '0'; // pad with 0's instead of spaces
  1026b1:	c7 45 d4 30 00 00 00 	movl   $0x30,-0x2c(%ebp)
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  1026b8:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
				st.prec = st.prec * 10 + ch - '0';
  1026bf:	8b 55 dc             	mov    -0x24(%ebp),%edx
  1026c2:	89 d0                	mov    %edx,%eax
  1026c4:	c1 e0 02             	shl    $0x2,%eax
  1026c7:	01 d0                	add    %edx,%eax
  1026c9:	01 c0                	add    %eax,%eax
  1026cb:	01 d8                	add    %ebx,%eax
  1026cd:	83 e8 30             	sub    $0x30,%eax
  1026d0:	89 45 dc             	mov    %eax,-0x24(%ebp)
				ch = *fmt;
  1026d3:	8b 45 10             	mov    0x10(%ebp),%eax
  1026d6:	0f b6 00             	movzbl (%eax),%eax
  1026d9:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
  1026dc:	83 fb 2f             	cmp    $0x2f,%ebx
  1026df:	7e 21                	jle    102702 <vprintfmt+0x139>
  1026e1:	83 fb 39             	cmp    $0x39,%ebx
  1026e4:	7f 1c                	jg     102702 <vprintfmt+0x139>
		case '0':
			if (!(st.flags & F_DOT))
				st.padc = '0'; // pad with 0's instead of spaces
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  1026e6:	83 45 10 01          	addl   $0x1,0x10(%ebp)
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  1026ea:	eb d3                	jmp    1026bf <vprintfmt+0xf6>
			goto gotprec;

		case '*':
			st.prec = va_arg(ap, int);
  1026ec:	8b 45 14             	mov    0x14(%ebp),%eax
  1026ef:	83 c0 04             	add    $0x4,%eax
  1026f2:	89 45 14             	mov    %eax,0x14(%ebp)
  1026f5:	8b 45 14             	mov    0x14(%ebp),%eax
  1026f8:	83 e8 04             	sub    $0x4,%eax
  1026fb:	8b 00                	mov    (%eax),%eax
  1026fd:	89 45 dc             	mov    %eax,-0x24(%ebp)
  102700:	eb 01                	jmp    102703 <vprintfmt+0x13a>
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto gotprec;
  102702:	90                   	nop

		case '*':
			st.prec = va_arg(ap, int);
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
  102703:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  102706:	83 e0 08             	and    $0x8,%eax
  102709:	85 c0                	test   %eax,%eax
  10270b:	0f 85 4d ff ff ff    	jne    10265e <vprintfmt+0x95>
				st.width = st.prec;	// then it's a field width
  102711:	8b 45 dc             	mov    -0x24(%ebp),%eax
  102714:	89 45 d8             	mov    %eax,-0x28(%ebp)
				st.prec = -1;
  102717:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
			}
			goto reswitch;
  10271e:	e9 3b ff ff ff       	jmp    10265e <vprintfmt+0x95>

		case '.':
			st.flags |= F_DOT;
  102723:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  102726:	83 c8 08             	or     $0x8,%eax
  102729:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
  10272c:	e9 2e ff ff ff       	jmp    10265f <vprintfmt+0x96>

		case '#':
			st.flags |= F_ALT;
  102731:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  102734:	83 c8 04             	or     $0x4,%eax
  102737:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
  10273a:	e9 20 ff ff ff       	jmp    10265f <vprintfmt+0x96>

		// long flag (doubled for long long)
		case 'l':
			st.flags |= (st.flags & F_L) ? F_LL : F_L;
  10273f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  102742:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  102745:	83 e0 01             	and    $0x1,%eax
  102748:	85 c0                	test   %eax,%eax
  10274a:	74 07                	je     102753 <vprintfmt+0x18a>
  10274c:	b8 02 00 00 00       	mov    $0x2,%eax
  102751:	eb 05                	jmp    102758 <vprintfmt+0x18f>
  102753:	b8 01 00 00 00       	mov    $0x1,%eax
  102758:	09 d0                	or     %edx,%eax
  10275a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
  10275d:	e9 fd fe ff ff       	jmp    10265f <vprintfmt+0x96>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  102762:	8b 45 14             	mov    0x14(%ebp),%eax
  102765:	83 c0 04             	add    $0x4,%eax
  102768:	89 45 14             	mov    %eax,0x14(%ebp)
  10276b:	8b 45 14             	mov    0x14(%ebp),%eax
  10276e:	83 e8 04             	sub    $0x4,%eax
  102771:	8b 00                	mov    (%eax),%eax
  102773:	8b 55 0c             	mov    0xc(%ebp),%edx
  102776:	89 54 24 04          	mov    %edx,0x4(%esp)
  10277a:	89 04 24             	mov    %eax,(%esp)
  10277d:	8b 45 08             	mov    0x8(%ebp),%eax
  102780:	ff d0                	call   *%eax
			break;
  102782:	e9 cc 01 00 00       	jmp    102953 <vprintfmt+0x38a>

		// string
		case 's': {
			const char *s;
			if ((s = va_arg(ap, char *)) == NULL)
  102787:	8b 45 14             	mov    0x14(%ebp),%eax
  10278a:	83 c0 04             	add    $0x4,%eax
  10278d:	89 45 14             	mov    %eax,0x14(%ebp)
  102790:	8b 45 14             	mov    0x14(%ebp),%eax
  102793:	83 e8 04             	sub    $0x4,%eax
  102796:	8b 00                	mov    (%eax),%eax
  102798:	89 45 ec             	mov    %eax,-0x14(%ebp)
  10279b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  10279f:	75 07                	jne    1027a8 <vprintfmt+0x1df>
				s = "(null)";
  1027a1:	c7 45 ec ed 3a 10 00 	movl   $0x103aed,-0x14(%ebp)
			putstr(&st, s, st.prec);
  1027a8:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1027ab:	89 44 24 08          	mov    %eax,0x8(%esp)
  1027af:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1027b2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1027b6:	8d 45 cc             	lea    -0x34(%ebp),%eax
  1027b9:	89 04 24             	mov    %eax,(%esp)
  1027bc:	e8 0e fc ff ff       	call   1023cf <putstr>
			break;
  1027c1:	e9 8d 01 00 00       	jmp    102953 <vprintfmt+0x38a>
		    }

		// (signed) decimal
		case 'd':
			num = getint(&st, &ap);
  1027c6:	8d 45 14             	lea    0x14(%ebp),%eax
  1027c9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1027cd:	8d 45 cc             	lea    -0x34(%ebp),%eax
  1027d0:	89 04 24             	mov    %eax,(%esp)
  1027d3:	e8 45 fb ff ff       	call   10231d <getint>
  1027d8:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1027db:	89 55 f4             	mov    %edx,-0xc(%ebp)
			if ((intmax_t) num < 0) {
  1027de:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1027e1:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1027e4:	85 d2                	test   %edx,%edx
  1027e6:	79 1a                	jns    102802 <vprintfmt+0x239>
				num = -(intmax_t) num;
  1027e8:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1027eb:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1027ee:	f7 d8                	neg    %eax
  1027f0:	83 d2 00             	adc    $0x0,%edx
  1027f3:	f7 da                	neg    %edx
  1027f5:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1027f8:	89 55 f4             	mov    %edx,-0xc(%ebp)
				st.signc = '-';
  1027fb:	c7 45 e0 2d 00 00 00 	movl   $0x2d,-0x20(%ebp)
			}
			putint(&st, num, 10);
  102802:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  102809:	00 
  10280a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10280d:	8b 55 f4             	mov    -0xc(%ebp),%edx
  102810:	89 44 24 04          	mov    %eax,0x4(%esp)
  102814:	89 54 24 08          	mov    %edx,0x8(%esp)
  102818:	8d 45 cc             	lea    -0x34(%ebp),%eax
  10281b:	89 04 24             	mov    %eax,(%esp)
  10281e:	e8 3e fd ff ff       	call   102561 <putint>
			break;
  102823:	e9 2b 01 00 00       	jmp    102953 <vprintfmt+0x38a>

		// unsigned decimal
		case 'u':
			putint(&st, getuint(&st, &ap), 10);
  102828:	8d 45 14             	lea    0x14(%ebp),%eax
  10282b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10282f:	8d 45 cc             	lea    -0x34(%ebp),%eax
  102832:	89 04 24             	mov    %eax,(%esp)
  102835:	e8 6e fa ff ff       	call   1022a8 <getuint>
  10283a:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  102841:	00 
  102842:	89 44 24 04          	mov    %eax,0x4(%esp)
  102846:	89 54 24 08          	mov    %edx,0x8(%esp)
  10284a:	8d 45 cc             	lea    -0x34(%ebp),%eax
  10284d:	89 04 24             	mov    %eax,(%esp)
  102850:	e8 0c fd ff ff       	call   102561 <putint>
			break;
  102855:	e9 f9 00 00 00       	jmp    102953 <vprintfmt+0x38a>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putint(&st, getuint(&st, &ap), 8);
  10285a:	8d 45 14             	lea    0x14(%ebp),%eax
  10285d:	89 44 24 04          	mov    %eax,0x4(%esp)
  102861:	8d 45 cc             	lea    -0x34(%ebp),%eax
  102864:	89 04 24             	mov    %eax,(%esp)
  102867:	e8 3c fa ff ff       	call   1022a8 <getuint>
  10286c:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  102873:	00 
  102874:	89 44 24 04          	mov    %eax,0x4(%esp)
  102878:	89 54 24 08          	mov    %edx,0x8(%esp)
  10287c:	8d 45 cc             	lea    -0x34(%ebp),%eax
  10287f:	89 04 24             	mov    %eax,(%esp)
  102882:	e8 da fc ff ff       	call   102561 <putint>
			break;
  102887:	e9 c7 00 00 00       	jmp    102953 <vprintfmt+0x38a>

		// (unsigned) hexadecimal
		case 'x':
			putint(&st, getuint(&st, &ap), 16);
  10288c:	8d 45 14             	lea    0x14(%ebp),%eax
  10288f:	89 44 24 04          	mov    %eax,0x4(%esp)
  102893:	8d 45 cc             	lea    -0x34(%ebp),%eax
  102896:	89 04 24             	mov    %eax,(%esp)
  102899:	e8 0a fa ff ff       	call   1022a8 <getuint>
  10289e:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  1028a5:	00 
  1028a6:	89 44 24 04          	mov    %eax,0x4(%esp)
  1028aa:	89 54 24 08          	mov    %edx,0x8(%esp)
  1028ae:	8d 45 cc             	lea    -0x34(%ebp),%eax
  1028b1:	89 04 24             	mov    %eax,(%esp)
  1028b4:	e8 a8 fc ff ff       	call   102561 <putint>
			break;
  1028b9:	e9 95 00 00 00       	jmp    102953 <vprintfmt+0x38a>

		// pointer
		case 'p':
			putch('0', putdat);
  1028be:	8b 45 0c             	mov    0xc(%ebp),%eax
  1028c1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1028c5:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  1028cc:	8b 45 08             	mov    0x8(%ebp),%eax
  1028cf:	ff d0                	call   *%eax
			putch('x', putdat);
  1028d1:	8b 45 0c             	mov    0xc(%ebp),%eax
  1028d4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1028d8:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  1028df:	8b 45 08             	mov    0x8(%ebp),%eax
  1028e2:	ff d0                	call   *%eax
			putint(&st, (uintptr_t) va_arg(ap, void *), 16);
  1028e4:	8b 45 14             	mov    0x14(%ebp),%eax
  1028e7:	83 c0 04             	add    $0x4,%eax
  1028ea:	89 45 14             	mov    %eax,0x14(%ebp)
  1028ed:	8b 45 14             	mov    0x14(%ebp),%eax
  1028f0:	83 e8 04             	sub    $0x4,%eax
  1028f3:	8b 00                	mov    (%eax),%eax
  1028f5:	ba 00 00 00 00       	mov    $0x0,%edx
  1028fa:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  102901:	00 
  102902:	89 44 24 04          	mov    %eax,0x4(%esp)
  102906:	89 54 24 08          	mov    %edx,0x8(%esp)
  10290a:	8d 45 cc             	lea    -0x34(%ebp),%eax
  10290d:	89 04 24             	mov    %eax,(%esp)
  102910:	e8 4c fc ff ff       	call   102561 <putint>
			break;
  102915:	eb 3c                	jmp    102953 <vprintfmt+0x38a>
		    }
#endif	// ! PIOS_KERNEL

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  102917:	8b 45 0c             	mov    0xc(%ebp),%eax
  10291a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10291e:	89 1c 24             	mov    %ebx,(%esp)
  102921:	8b 45 08             	mov    0x8(%ebp),%eax
  102924:	ff d0                	call   *%eax
			break;
  102926:	eb 2b                	jmp    102953 <vprintfmt+0x38a>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  102928:	8b 45 0c             	mov    0xc(%ebp),%eax
  10292b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10292f:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  102936:	8b 45 08             	mov    0x8(%ebp),%eax
  102939:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
  10293b:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10293f:	eb 04                	jmp    102945 <vprintfmt+0x37c>
  102941:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  102945:	8b 45 10             	mov    0x10(%ebp),%eax
  102948:	83 e8 01             	sub    $0x1,%eax
  10294b:	0f b6 00             	movzbl (%eax),%eax
  10294e:	3c 25                	cmp    $0x25,%al
  102950:	75 ef                	jne    102941 <vprintfmt+0x378>
				/* do nothing */;
			break;
  102952:	90                   	nop
		}
	}
  102953:	90                   	nop
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  102954:	e9 bf fc ff ff       	jmp    102618 <vprintfmt+0x4f>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
  102959:	83 c4 44             	add    $0x44,%esp
  10295c:	5b                   	pop    %ebx
  10295d:	5d                   	pop    %ebp
  10295e:	c3                   	ret    
  10295f:	90                   	nop

00102960 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  102960:	55                   	push   %ebp
  102961:	89 e5                	mov    %esp,%ebp
  102963:	83 ec 18             	sub    $0x18,%esp
	b->buf[b->idx++] = ch;
  102966:	8b 45 0c             	mov    0xc(%ebp),%eax
  102969:	8b 00                	mov    (%eax),%eax
  10296b:	8b 55 08             	mov    0x8(%ebp),%edx
  10296e:	89 d1                	mov    %edx,%ecx
  102970:	8b 55 0c             	mov    0xc(%ebp),%edx
  102973:	88 4c 02 08          	mov    %cl,0x8(%edx,%eax,1)
  102977:	8d 50 01             	lea    0x1(%eax),%edx
  10297a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10297d:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
  10297f:	8b 45 0c             	mov    0xc(%ebp),%eax
  102982:	8b 00                	mov    (%eax),%eax
  102984:	3d ff 00 00 00       	cmp    $0xff,%eax
  102989:	75 24                	jne    1029af <putch+0x4f>
		b->buf[b->idx] = 0;
  10298b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10298e:	8b 00                	mov    (%eax),%eax
  102990:	8b 55 0c             	mov    0xc(%ebp),%edx
  102993:	c6 44 02 08 00       	movb   $0x0,0x8(%edx,%eax,1)
		cputs(b->buf);
  102998:	8b 45 0c             	mov    0xc(%ebp),%eax
  10299b:	83 c0 08             	add    $0x8,%eax
  10299e:	89 04 24             	mov    %eax,(%esp)
  1029a1:	e8 9e d9 ff ff       	call   100344 <cputs>
		b->idx = 0;
  1029a6:	8b 45 0c             	mov    0xc(%ebp),%eax
  1029a9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
  1029af:	8b 45 0c             	mov    0xc(%ebp),%eax
  1029b2:	8b 40 04             	mov    0x4(%eax),%eax
  1029b5:	8d 50 01             	lea    0x1(%eax),%edx
  1029b8:	8b 45 0c             	mov    0xc(%ebp),%eax
  1029bb:	89 50 04             	mov    %edx,0x4(%eax)
}
  1029be:	c9                   	leave  
  1029bf:	c3                   	ret    

001029c0 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  1029c0:	55                   	push   %ebp
  1029c1:	89 e5                	mov    %esp,%ebp
  1029c3:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  1029c9:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  1029d0:	00 00 00 
	b.cnt = 0;
  1029d3:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  1029da:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  1029dd:	8b 45 0c             	mov    0xc(%ebp),%eax
  1029e0:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1029e4:	8b 45 08             	mov    0x8(%ebp),%eax
  1029e7:	89 44 24 08          	mov    %eax,0x8(%esp)
  1029eb:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  1029f1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1029f5:	c7 04 24 60 29 10 00 	movl   $0x102960,(%esp)
  1029fc:	e8 c8 fb ff ff       	call   1025c9 <vprintfmt>

	b.buf[b.idx] = 0;
  102a01:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  102a07:	c6 84 05 f8 fe ff ff 	movb   $0x0,-0x108(%ebp,%eax,1)
  102a0e:	00 
	cputs(b.buf);
  102a0f:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  102a15:	83 c0 08             	add    $0x8,%eax
  102a18:	89 04 24             	mov    %eax,(%esp)
  102a1b:	e8 24 d9 ff ff       	call   100344 <cputs>

	return b.cnt;
  102a20:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
}
  102a26:	c9                   	leave  
  102a27:	c3                   	ret    

00102a28 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  102a28:	55                   	push   %ebp
  102a29:	89 e5                	mov    %esp,%ebp
  102a2b:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  102a2e:	8d 45 0c             	lea    0xc(%ebp),%eax
  102a31:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cnt = vcprintf(fmt, ap);
  102a34:	8b 45 08             	mov    0x8(%ebp),%eax
  102a37:	8b 55 f4             	mov    -0xc(%ebp),%edx
  102a3a:	89 54 24 04          	mov    %edx,0x4(%esp)
  102a3e:	89 04 24             	mov    %eax,(%esp)
  102a41:	e8 7a ff ff ff       	call   1029c0 <vcprintf>
  102a46:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return cnt;
  102a49:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  102a4c:	c9                   	leave  
  102a4d:	c3                   	ret    
  102a4e:	90                   	nop
  102a4f:	90                   	nop

00102a50 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  102a50:	55                   	push   %ebp
  102a51:	89 e5                	mov    %esp,%ebp
  102a53:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
  102a56:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  102a5d:	eb 08                	jmp    102a67 <strlen+0x17>
		n++;
  102a5f:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  102a63:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  102a67:	8b 45 08             	mov    0x8(%ebp),%eax
  102a6a:	0f b6 00             	movzbl (%eax),%eax
  102a6d:	84 c0                	test   %al,%al
  102a6f:	75 ee                	jne    102a5f <strlen+0xf>
		n++;
	return n;
  102a71:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  102a74:	c9                   	leave  
  102a75:	c3                   	ret    

00102a76 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  102a76:	55                   	push   %ebp
  102a77:	89 e5                	mov    %esp,%ebp
  102a79:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
  102a7c:	8b 45 08             	mov    0x8(%ebp),%eax
  102a7f:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
  102a82:	90                   	nop
  102a83:	8b 45 0c             	mov    0xc(%ebp),%eax
  102a86:	0f b6 10             	movzbl (%eax),%edx
  102a89:	8b 45 08             	mov    0x8(%ebp),%eax
  102a8c:	88 10                	mov    %dl,(%eax)
  102a8e:	8b 45 08             	mov    0x8(%ebp),%eax
  102a91:	0f b6 00             	movzbl (%eax),%eax
  102a94:	84 c0                	test   %al,%al
  102a96:	0f 95 c0             	setne  %al
  102a99:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  102a9d:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  102aa1:	84 c0                	test   %al,%al
  102aa3:	75 de                	jne    102a83 <strcpy+0xd>
		/* do nothing */;
	return ret;
  102aa5:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  102aa8:	c9                   	leave  
  102aa9:	c3                   	ret    

00102aaa <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
  102aaa:	55                   	push   %ebp
  102aab:	89 e5                	mov    %esp,%ebp
  102aad:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
  102ab0:	8b 45 08             	mov    0x8(%ebp),%eax
  102ab3:	89 45 f8             	mov    %eax,-0x8(%ebp)
	for (i = 0; i < size; i++) {
  102ab6:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  102abd:	eb 21                	jmp    102ae0 <strncpy+0x36>
		*dst++ = *src;
  102abf:	8b 45 0c             	mov    0xc(%ebp),%eax
  102ac2:	0f b6 10             	movzbl (%eax),%edx
  102ac5:	8b 45 08             	mov    0x8(%ebp),%eax
  102ac8:	88 10                	mov    %dl,(%eax)
  102aca:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
  102ace:	8b 45 0c             	mov    0xc(%ebp),%eax
  102ad1:	0f b6 00             	movzbl (%eax),%eax
  102ad4:	84 c0                	test   %al,%al
  102ad6:	74 04                	je     102adc <strncpy+0x32>
			src++;
  102ad8:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  102adc:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  102ae0:	8b 45 fc             	mov    -0x4(%ebp),%eax
  102ae3:	3b 45 10             	cmp    0x10(%ebp),%eax
  102ae6:	72 d7                	jb     102abf <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
  102ae8:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
  102aeb:	c9                   	leave  
  102aec:	c3                   	ret    

00102aed <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  102aed:	55                   	push   %ebp
  102aee:	89 e5                	mov    %esp,%ebp
  102af0:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
  102af3:	8b 45 08             	mov    0x8(%ebp),%eax
  102af6:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
  102af9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  102afd:	74 2f                	je     102b2e <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
  102aff:	eb 13                	jmp    102b14 <strlcpy+0x27>
			*dst++ = *src++;
  102b01:	8b 45 0c             	mov    0xc(%ebp),%eax
  102b04:	0f b6 10             	movzbl (%eax),%edx
  102b07:	8b 45 08             	mov    0x8(%ebp),%eax
  102b0a:	88 10                	mov    %dl,(%eax)
  102b0c:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  102b10:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  102b14:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  102b18:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  102b1c:	74 0a                	je     102b28 <strlcpy+0x3b>
  102b1e:	8b 45 0c             	mov    0xc(%ebp),%eax
  102b21:	0f b6 00             	movzbl (%eax),%eax
  102b24:	84 c0                	test   %al,%al
  102b26:	75 d9                	jne    102b01 <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
  102b28:	8b 45 08             	mov    0x8(%ebp),%eax
  102b2b:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  102b2e:	8b 55 08             	mov    0x8(%ebp),%edx
  102b31:	8b 45 fc             	mov    -0x4(%ebp),%eax
  102b34:	89 d1                	mov    %edx,%ecx
  102b36:	29 c1                	sub    %eax,%ecx
  102b38:	89 c8                	mov    %ecx,%eax
}
  102b3a:	c9                   	leave  
  102b3b:	c3                   	ret    

00102b3c <strcmp>:

int
strcmp(const char *p, const char *q)
{
  102b3c:	55                   	push   %ebp
  102b3d:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
  102b3f:	eb 08                	jmp    102b49 <strcmp+0xd>
		p++, q++;
  102b41:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  102b45:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  102b49:	8b 45 08             	mov    0x8(%ebp),%eax
  102b4c:	0f b6 00             	movzbl (%eax),%eax
  102b4f:	84 c0                	test   %al,%al
  102b51:	74 10                	je     102b63 <strcmp+0x27>
  102b53:	8b 45 08             	mov    0x8(%ebp),%eax
  102b56:	0f b6 10             	movzbl (%eax),%edx
  102b59:	8b 45 0c             	mov    0xc(%ebp),%eax
  102b5c:	0f b6 00             	movzbl (%eax),%eax
  102b5f:	38 c2                	cmp    %al,%dl
  102b61:	74 de                	je     102b41 <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  102b63:	8b 45 08             	mov    0x8(%ebp),%eax
  102b66:	0f b6 00             	movzbl (%eax),%eax
  102b69:	0f b6 d0             	movzbl %al,%edx
  102b6c:	8b 45 0c             	mov    0xc(%ebp),%eax
  102b6f:	0f b6 00             	movzbl (%eax),%eax
  102b72:	0f b6 c0             	movzbl %al,%eax
  102b75:	89 d1                	mov    %edx,%ecx
  102b77:	29 c1                	sub    %eax,%ecx
  102b79:	89 c8                	mov    %ecx,%eax
}
  102b7b:	5d                   	pop    %ebp
  102b7c:	c3                   	ret    

00102b7d <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  102b7d:	55                   	push   %ebp
  102b7e:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
  102b80:	eb 0c                	jmp    102b8e <strncmp+0x11>
		n--, p++, q++;
  102b82:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  102b86:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  102b8a:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  102b8e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  102b92:	74 1a                	je     102bae <strncmp+0x31>
  102b94:	8b 45 08             	mov    0x8(%ebp),%eax
  102b97:	0f b6 00             	movzbl (%eax),%eax
  102b9a:	84 c0                	test   %al,%al
  102b9c:	74 10                	je     102bae <strncmp+0x31>
  102b9e:	8b 45 08             	mov    0x8(%ebp),%eax
  102ba1:	0f b6 10             	movzbl (%eax),%edx
  102ba4:	8b 45 0c             	mov    0xc(%ebp),%eax
  102ba7:	0f b6 00             	movzbl (%eax),%eax
  102baa:	38 c2                	cmp    %al,%dl
  102bac:	74 d4                	je     102b82 <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
  102bae:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  102bb2:	75 07                	jne    102bbb <strncmp+0x3e>
		return 0;
  102bb4:	b8 00 00 00 00       	mov    $0x0,%eax
  102bb9:	eb 18                	jmp    102bd3 <strncmp+0x56>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  102bbb:	8b 45 08             	mov    0x8(%ebp),%eax
  102bbe:	0f b6 00             	movzbl (%eax),%eax
  102bc1:	0f b6 d0             	movzbl %al,%edx
  102bc4:	8b 45 0c             	mov    0xc(%ebp),%eax
  102bc7:	0f b6 00             	movzbl (%eax),%eax
  102bca:	0f b6 c0             	movzbl %al,%eax
  102bcd:	89 d1                	mov    %edx,%ecx
  102bcf:	29 c1                	sub    %eax,%ecx
  102bd1:	89 c8                	mov    %ecx,%eax
}
  102bd3:	5d                   	pop    %ebp
  102bd4:	c3                   	ret    

00102bd5 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  102bd5:	55                   	push   %ebp
  102bd6:	89 e5                	mov    %esp,%ebp
  102bd8:	83 ec 04             	sub    $0x4,%esp
  102bdb:	8b 45 0c             	mov    0xc(%ebp),%eax
  102bde:	88 45 fc             	mov    %al,-0x4(%ebp)
	while (*s != c)
  102be1:	eb 1a                	jmp    102bfd <strchr+0x28>
		if (*s++ == 0)
  102be3:	8b 45 08             	mov    0x8(%ebp),%eax
  102be6:	0f b6 00             	movzbl (%eax),%eax
  102be9:	84 c0                	test   %al,%al
  102beb:	0f 94 c0             	sete   %al
  102bee:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  102bf2:	84 c0                	test   %al,%al
  102bf4:	74 07                	je     102bfd <strchr+0x28>
			return NULL;
  102bf6:	b8 00 00 00 00       	mov    $0x0,%eax
  102bfb:	eb 0e                	jmp    102c0b <strchr+0x36>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	while (*s != c)
  102bfd:	8b 45 08             	mov    0x8(%ebp),%eax
  102c00:	0f b6 00             	movzbl (%eax),%eax
  102c03:	3a 45 fc             	cmp    -0x4(%ebp),%al
  102c06:	75 db                	jne    102be3 <strchr+0xe>
		if (*s++ == 0)
			return NULL;
	return (char *) s;
  102c08:	8b 45 08             	mov    0x8(%ebp),%eax
}
  102c0b:	c9                   	leave  
  102c0c:	c3                   	ret    

00102c0d <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  102c0d:	55                   	push   %ebp
  102c0e:	89 e5                	mov    %esp,%ebp
  102c10:	57                   	push   %edi
	char *p;

	if (n == 0)
  102c11:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  102c15:	75 05                	jne    102c1c <memset+0xf>
		return v;
  102c17:	8b 45 08             	mov    0x8(%ebp),%eax
  102c1a:	eb 5c                	jmp    102c78 <memset+0x6b>
	if ((int)v%4 == 0 && n%4 == 0) {
  102c1c:	8b 45 08             	mov    0x8(%ebp),%eax
  102c1f:	83 e0 03             	and    $0x3,%eax
  102c22:	85 c0                	test   %eax,%eax
  102c24:	75 41                	jne    102c67 <memset+0x5a>
  102c26:	8b 45 10             	mov    0x10(%ebp),%eax
  102c29:	83 e0 03             	and    $0x3,%eax
  102c2c:	85 c0                	test   %eax,%eax
  102c2e:	75 37                	jne    102c67 <memset+0x5a>
		c &= 0xFF;
  102c30:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
  102c37:	8b 45 0c             	mov    0xc(%ebp),%eax
  102c3a:	89 c2                	mov    %eax,%edx
  102c3c:	c1 e2 18             	shl    $0x18,%edx
  102c3f:	8b 45 0c             	mov    0xc(%ebp),%eax
  102c42:	c1 e0 10             	shl    $0x10,%eax
  102c45:	09 c2                	or     %eax,%edx
  102c47:	8b 45 0c             	mov    0xc(%ebp),%eax
  102c4a:	c1 e0 08             	shl    $0x8,%eax
  102c4d:	09 d0                	or     %edx,%eax
  102c4f:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  102c52:	8b 45 10             	mov    0x10(%ebp),%eax
  102c55:	89 c1                	mov    %eax,%ecx
  102c57:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  102c5a:	8b 55 08             	mov    0x8(%ebp),%edx
  102c5d:	8b 45 0c             	mov    0xc(%ebp),%eax
  102c60:	89 d7                	mov    %edx,%edi
  102c62:	fc                   	cld    
  102c63:	f3 ab                	rep stos %eax,%es:(%edi)
  102c65:	eb 0e                	jmp    102c75 <memset+0x68>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  102c67:	8b 55 08             	mov    0x8(%ebp),%edx
  102c6a:	8b 45 0c             	mov    0xc(%ebp),%eax
  102c6d:	8b 4d 10             	mov    0x10(%ebp),%ecx
  102c70:	89 d7                	mov    %edx,%edi
  102c72:	fc                   	cld    
  102c73:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
  102c75:	8b 45 08             	mov    0x8(%ebp),%eax
}
  102c78:	5f                   	pop    %edi
  102c79:	5d                   	pop    %ebp
  102c7a:	c3                   	ret    

00102c7b <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  102c7b:	55                   	push   %ebp
  102c7c:	89 e5                	mov    %esp,%ebp
  102c7e:	57                   	push   %edi
  102c7f:	56                   	push   %esi
  102c80:	53                   	push   %ebx
  102c81:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
  102c84:	8b 45 0c             	mov    0xc(%ebp),%eax
  102c87:	89 45 f0             	mov    %eax,-0x10(%ebp)
	d = dst;
  102c8a:	8b 45 08             	mov    0x8(%ebp),%eax
  102c8d:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (s < d && s + n > d) {
  102c90:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102c93:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  102c96:	73 6d                	jae    102d05 <memmove+0x8a>
  102c98:	8b 45 10             	mov    0x10(%ebp),%eax
  102c9b:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102c9e:	01 d0                	add    %edx,%eax
  102ca0:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  102ca3:	76 60                	jbe    102d05 <memmove+0x8a>
		s += n;
  102ca5:	8b 45 10             	mov    0x10(%ebp),%eax
  102ca8:	01 45 f0             	add    %eax,-0x10(%ebp)
		d += n;
  102cab:	8b 45 10             	mov    0x10(%ebp),%eax
  102cae:	01 45 ec             	add    %eax,-0x14(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  102cb1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102cb4:	83 e0 03             	and    $0x3,%eax
  102cb7:	85 c0                	test   %eax,%eax
  102cb9:	75 2f                	jne    102cea <memmove+0x6f>
  102cbb:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102cbe:	83 e0 03             	and    $0x3,%eax
  102cc1:	85 c0                	test   %eax,%eax
  102cc3:	75 25                	jne    102cea <memmove+0x6f>
  102cc5:	8b 45 10             	mov    0x10(%ebp),%eax
  102cc8:	83 e0 03             	and    $0x3,%eax
  102ccb:	85 c0                	test   %eax,%eax
  102ccd:	75 1b                	jne    102cea <memmove+0x6f>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  102ccf:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102cd2:	83 e8 04             	sub    $0x4,%eax
  102cd5:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102cd8:	83 ea 04             	sub    $0x4,%edx
  102cdb:	8b 4d 10             	mov    0x10(%ebp),%ecx
  102cde:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  102ce1:	89 c7                	mov    %eax,%edi
  102ce3:	89 d6                	mov    %edx,%esi
  102ce5:	fd                   	std    
  102ce6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  102ce8:	eb 18                	jmp    102d02 <memmove+0x87>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  102cea:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102ced:	8d 50 ff             	lea    -0x1(%eax),%edx
  102cf0:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102cf3:	8d 58 ff             	lea    -0x1(%eax),%ebx
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  102cf6:	8b 45 10             	mov    0x10(%ebp),%eax
  102cf9:	89 d7                	mov    %edx,%edi
  102cfb:	89 de                	mov    %ebx,%esi
  102cfd:	89 c1                	mov    %eax,%ecx
  102cff:	fd                   	std    
  102d00:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  102d02:	fc                   	cld    
  102d03:	eb 45                	jmp    102d4a <memmove+0xcf>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  102d05:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102d08:	83 e0 03             	and    $0x3,%eax
  102d0b:	85 c0                	test   %eax,%eax
  102d0d:	75 2b                	jne    102d3a <memmove+0xbf>
  102d0f:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102d12:	83 e0 03             	and    $0x3,%eax
  102d15:	85 c0                	test   %eax,%eax
  102d17:	75 21                	jne    102d3a <memmove+0xbf>
  102d19:	8b 45 10             	mov    0x10(%ebp),%eax
  102d1c:	83 e0 03             	and    $0x3,%eax
  102d1f:	85 c0                	test   %eax,%eax
  102d21:	75 17                	jne    102d3a <memmove+0xbf>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  102d23:	8b 45 10             	mov    0x10(%ebp),%eax
  102d26:	89 c1                	mov    %eax,%ecx
  102d28:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  102d2b:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102d2e:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102d31:	89 c7                	mov    %eax,%edi
  102d33:	89 d6                	mov    %edx,%esi
  102d35:	fc                   	cld    
  102d36:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  102d38:	eb 10                	jmp    102d4a <memmove+0xcf>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  102d3a:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102d3d:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102d40:	8b 4d 10             	mov    0x10(%ebp),%ecx
  102d43:	89 c7                	mov    %eax,%edi
  102d45:	89 d6                	mov    %edx,%esi
  102d47:	fc                   	cld    
  102d48:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
  102d4a:	8b 45 08             	mov    0x8(%ebp),%eax
}
  102d4d:	83 c4 10             	add    $0x10,%esp
  102d50:	5b                   	pop    %ebx
  102d51:	5e                   	pop    %esi
  102d52:	5f                   	pop    %edi
  102d53:	5d                   	pop    %ebp
  102d54:	c3                   	ret    

00102d55 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  102d55:	55                   	push   %ebp
  102d56:	89 e5                	mov    %esp,%ebp
  102d58:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  102d5b:	8b 45 10             	mov    0x10(%ebp),%eax
  102d5e:	89 44 24 08          	mov    %eax,0x8(%esp)
  102d62:	8b 45 0c             	mov    0xc(%ebp),%eax
  102d65:	89 44 24 04          	mov    %eax,0x4(%esp)
  102d69:	8b 45 08             	mov    0x8(%ebp),%eax
  102d6c:	89 04 24             	mov    %eax,(%esp)
  102d6f:	e8 07 ff ff ff       	call   102c7b <memmove>
}
  102d74:	c9                   	leave  
  102d75:	c3                   	ret    

00102d76 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  102d76:	55                   	push   %ebp
  102d77:	89 e5                	mov    %esp,%ebp
  102d79:	83 ec 10             	sub    $0x10,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
  102d7c:	8b 45 08             	mov    0x8(%ebp),%eax
  102d7f:	89 45 fc             	mov    %eax,-0x4(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
  102d82:	8b 45 0c             	mov    0xc(%ebp),%eax
  102d85:	89 45 f8             	mov    %eax,-0x8(%ebp)

	while (n-- > 0) {
  102d88:	eb 32                	jmp    102dbc <memcmp+0x46>
		if (*s1 != *s2)
  102d8a:	8b 45 fc             	mov    -0x4(%ebp),%eax
  102d8d:	0f b6 10             	movzbl (%eax),%edx
  102d90:	8b 45 f8             	mov    -0x8(%ebp),%eax
  102d93:	0f b6 00             	movzbl (%eax),%eax
  102d96:	38 c2                	cmp    %al,%dl
  102d98:	74 1a                	je     102db4 <memcmp+0x3e>
			return (int) *s1 - (int) *s2;
  102d9a:	8b 45 fc             	mov    -0x4(%ebp),%eax
  102d9d:	0f b6 00             	movzbl (%eax),%eax
  102da0:	0f b6 d0             	movzbl %al,%edx
  102da3:	8b 45 f8             	mov    -0x8(%ebp),%eax
  102da6:	0f b6 00             	movzbl (%eax),%eax
  102da9:	0f b6 c0             	movzbl %al,%eax
  102dac:	89 d1                	mov    %edx,%ecx
  102dae:	29 c1                	sub    %eax,%ecx
  102db0:	89 c8                	mov    %ecx,%eax
  102db2:	eb 1c                	jmp    102dd0 <memcmp+0x5a>
		s1++, s2++;
  102db4:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  102db8:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  102dbc:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  102dc0:	0f 95 c0             	setne  %al
  102dc3:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  102dc7:	84 c0                	test   %al,%al
  102dc9:	75 bf                	jne    102d8a <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  102dcb:	b8 00 00 00 00       	mov    $0x0,%eax
}
  102dd0:	c9                   	leave  
  102dd1:	c3                   	ret    

00102dd2 <memchr>:

void *
memchr(const void *s, int c, size_t n)
{
  102dd2:	55                   	push   %ebp
  102dd3:	89 e5                	mov    %esp,%ebp
  102dd5:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
  102dd8:	8b 45 10             	mov    0x10(%ebp),%eax
  102ddb:	8b 55 08             	mov    0x8(%ebp),%edx
  102dde:	01 d0                	add    %edx,%eax
  102de0:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
  102de3:	eb 16                	jmp    102dfb <memchr+0x29>
		if (*(const unsigned char *) s == (unsigned char) c)
  102de5:	8b 45 08             	mov    0x8(%ebp),%eax
  102de8:	0f b6 10             	movzbl (%eax),%edx
  102deb:	8b 45 0c             	mov    0xc(%ebp),%eax
  102dee:	38 c2                	cmp    %al,%dl
  102df0:	75 05                	jne    102df7 <memchr+0x25>
			return (void *) s;
  102df2:	8b 45 08             	mov    0x8(%ebp),%eax
  102df5:	eb 11                	jmp    102e08 <memchr+0x36>

void *
memchr(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  102df7:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  102dfb:	8b 45 08             	mov    0x8(%ebp),%eax
  102dfe:	3b 45 fc             	cmp    -0x4(%ebp),%eax
  102e01:	72 e2                	jb     102de5 <memchr+0x13>
		if (*(const unsigned char *) s == (unsigned char) c)
			return (void *) s;
	return NULL;
  102e03:	b8 00 00 00 00       	mov    $0x0,%eax
}
  102e08:	c9                   	leave  
  102e09:	c3                   	ret    
  102e0a:	90                   	nop
  102e0b:	90                   	nop
  102e0c:	90                   	nop
  102e0d:	90                   	nop
  102e0e:	90                   	nop
  102e0f:	90                   	nop

00102e10 <__udivdi3>:
  102e10:	83 ec 1c             	sub    $0x1c,%esp
  102e13:	8b 44 24 2c          	mov    0x2c(%esp),%eax
  102e17:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  102e1b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  102e1f:	8b 6c 24 20          	mov    0x20(%esp),%ebp
  102e23:	89 74 24 10          	mov    %esi,0x10(%esp)
  102e27:	8b 74 24 24          	mov    0x24(%esp),%esi
  102e2b:	85 c0                	test   %eax,%eax
  102e2d:	89 7c 24 14          	mov    %edi,0x14(%esp)
  102e31:	89 cf                	mov    %ecx,%edi
  102e33:	89 6c 24 04          	mov    %ebp,0x4(%esp)
  102e37:	75 37                	jne    102e70 <__udivdi3+0x60>
  102e39:	39 f1                	cmp    %esi,%ecx
  102e3b:	77 73                	ja     102eb0 <__udivdi3+0xa0>
  102e3d:	85 c9                	test   %ecx,%ecx
  102e3f:	75 0b                	jne    102e4c <__udivdi3+0x3c>
  102e41:	b8 01 00 00 00       	mov    $0x1,%eax
  102e46:	31 d2                	xor    %edx,%edx
  102e48:	f7 f1                	div    %ecx
  102e4a:	89 c1                	mov    %eax,%ecx
  102e4c:	89 f0                	mov    %esi,%eax
  102e4e:	31 d2                	xor    %edx,%edx
  102e50:	f7 f1                	div    %ecx
  102e52:	89 c6                	mov    %eax,%esi
  102e54:	89 e8                	mov    %ebp,%eax
  102e56:	f7 f1                	div    %ecx
  102e58:	89 f2                	mov    %esi,%edx
  102e5a:	8b 74 24 10          	mov    0x10(%esp),%esi
  102e5e:	8b 7c 24 14          	mov    0x14(%esp),%edi
  102e62:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  102e66:	83 c4 1c             	add    $0x1c,%esp
  102e69:	c3                   	ret    
  102e6a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  102e70:	39 f0                	cmp    %esi,%eax
  102e72:	77 24                	ja     102e98 <__udivdi3+0x88>
  102e74:	0f bd e8             	bsr    %eax,%ebp
  102e77:	83 f5 1f             	xor    $0x1f,%ebp
  102e7a:	75 4c                	jne    102ec8 <__udivdi3+0xb8>
  102e7c:	31 d2                	xor    %edx,%edx
  102e7e:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
  102e82:	0f 86 b0 00 00 00    	jbe    102f38 <__udivdi3+0x128>
  102e88:	39 f0                	cmp    %esi,%eax
  102e8a:	0f 82 a8 00 00 00    	jb     102f38 <__udivdi3+0x128>
  102e90:	31 c0                	xor    %eax,%eax
  102e92:	eb c6                	jmp    102e5a <__udivdi3+0x4a>
  102e94:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102e98:	31 d2                	xor    %edx,%edx
  102e9a:	31 c0                	xor    %eax,%eax
  102e9c:	8b 74 24 10          	mov    0x10(%esp),%esi
  102ea0:	8b 7c 24 14          	mov    0x14(%esp),%edi
  102ea4:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  102ea8:	83 c4 1c             	add    $0x1c,%esp
  102eab:	c3                   	ret    
  102eac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102eb0:	89 e8                	mov    %ebp,%eax
  102eb2:	89 f2                	mov    %esi,%edx
  102eb4:	f7 f1                	div    %ecx
  102eb6:	31 d2                	xor    %edx,%edx
  102eb8:	8b 74 24 10          	mov    0x10(%esp),%esi
  102ebc:	8b 7c 24 14          	mov    0x14(%esp),%edi
  102ec0:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  102ec4:	83 c4 1c             	add    $0x1c,%esp
  102ec7:	c3                   	ret    
  102ec8:	89 e9                	mov    %ebp,%ecx
  102eca:	89 fa                	mov    %edi,%edx
  102ecc:	d3 e0                	shl    %cl,%eax
  102ece:	89 44 24 08          	mov    %eax,0x8(%esp)
  102ed2:	b8 20 00 00 00       	mov    $0x20,%eax
  102ed7:	29 e8                	sub    %ebp,%eax
  102ed9:	89 c1                	mov    %eax,%ecx
  102edb:	d3 ea                	shr    %cl,%edx
  102edd:	8b 4c 24 08          	mov    0x8(%esp),%ecx
  102ee1:	09 ca                	or     %ecx,%edx
  102ee3:	89 e9                	mov    %ebp,%ecx
  102ee5:	d3 e7                	shl    %cl,%edi
  102ee7:	89 c1                	mov    %eax,%ecx
  102ee9:	89 54 24 0c          	mov    %edx,0xc(%esp)
  102eed:	89 f2                	mov    %esi,%edx
  102eef:	d3 ea                	shr    %cl,%edx
  102ef1:	89 e9                	mov    %ebp,%ecx
  102ef3:	89 14 24             	mov    %edx,(%esp)
  102ef6:	8b 54 24 04          	mov    0x4(%esp),%edx
  102efa:	d3 e6                	shl    %cl,%esi
  102efc:	89 c1                	mov    %eax,%ecx
  102efe:	d3 ea                	shr    %cl,%edx
  102f00:	89 d0                	mov    %edx,%eax
  102f02:	09 f0                	or     %esi,%eax
  102f04:	8b 34 24             	mov    (%esp),%esi
  102f07:	89 f2                	mov    %esi,%edx
  102f09:	f7 74 24 0c          	divl   0xc(%esp)
  102f0d:	89 d6                	mov    %edx,%esi
  102f0f:	89 44 24 08          	mov    %eax,0x8(%esp)
  102f13:	f7 e7                	mul    %edi
  102f15:	39 d6                	cmp    %edx,%esi
  102f17:	72 2f                	jb     102f48 <__udivdi3+0x138>
  102f19:	8b 7c 24 04          	mov    0x4(%esp),%edi
  102f1d:	89 e9                	mov    %ebp,%ecx
  102f1f:	d3 e7                	shl    %cl,%edi
  102f21:	39 c7                	cmp    %eax,%edi
  102f23:	73 04                	jae    102f29 <__udivdi3+0x119>
  102f25:	39 d6                	cmp    %edx,%esi
  102f27:	74 1f                	je     102f48 <__udivdi3+0x138>
  102f29:	8b 44 24 08          	mov    0x8(%esp),%eax
  102f2d:	31 d2                	xor    %edx,%edx
  102f2f:	e9 26 ff ff ff       	jmp    102e5a <__udivdi3+0x4a>
  102f34:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102f38:	b8 01 00 00 00       	mov    $0x1,%eax
  102f3d:	e9 18 ff ff ff       	jmp    102e5a <__udivdi3+0x4a>
  102f42:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  102f48:	8b 44 24 08          	mov    0x8(%esp),%eax
  102f4c:	31 d2                	xor    %edx,%edx
  102f4e:	83 e8 01             	sub    $0x1,%eax
  102f51:	8b 74 24 10          	mov    0x10(%esp),%esi
  102f55:	8b 7c 24 14          	mov    0x14(%esp),%edi
  102f59:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  102f5d:	83 c4 1c             	add    $0x1c,%esp
  102f60:	c3                   	ret    
  102f61:	90                   	nop
  102f62:	90                   	nop
  102f63:	90                   	nop
  102f64:	90                   	nop
  102f65:	90                   	nop
  102f66:	90                   	nop
  102f67:	90                   	nop
  102f68:	90                   	nop
  102f69:	90                   	nop
  102f6a:	90                   	nop
  102f6b:	90                   	nop
  102f6c:	90                   	nop
  102f6d:	90                   	nop
  102f6e:	90                   	nop
  102f6f:	90                   	nop

00102f70 <__umoddi3>:
  102f70:	83 ec 1c             	sub    $0x1c,%esp
  102f73:	8b 54 24 2c          	mov    0x2c(%esp),%edx
  102f77:	8b 44 24 20          	mov    0x20(%esp),%eax
  102f7b:	89 74 24 10          	mov    %esi,0x10(%esp)
  102f7f:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  102f83:	8b 74 24 24          	mov    0x24(%esp),%esi
  102f87:	85 d2                	test   %edx,%edx
  102f89:	89 7c 24 14          	mov    %edi,0x14(%esp)
  102f8d:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  102f91:	89 cf                	mov    %ecx,%edi
  102f93:	89 c5                	mov    %eax,%ebp
  102f95:	89 44 24 08          	mov    %eax,0x8(%esp)
  102f99:	89 34 24             	mov    %esi,(%esp)
  102f9c:	75 22                	jne    102fc0 <__umoddi3+0x50>
  102f9e:	39 f1                	cmp    %esi,%ecx
  102fa0:	76 56                	jbe    102ff8 <__umoddi3+0x88>
  102fa2:	89 f2                	mov    %esi,%edx
  102fa4:	f7 f1                	div    %ecx
  102fa6:	89 d0                	mov    %edx,%eax
  102fa8:	31 d2                	xor    %edx,%edx
  102faa:	8b 74 24 10          	mov    0x10(%esp),%esi
  102fae:	8b 7c 24 14          	mov    0x14(%esp),%edi
  102fb2:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  102fb6:	83 c4 1c             	add    $0x1c,%esp
  102fb9:	c3                   	ret    
  102fba:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  102fc0:	39 f2                	cmp    %esi,%edx
  102fc2:	77 54                	ja     103018 <__umoddi3+0xa8>
  102fc4:	0f bd c2             	bsr    %edx,%eax
  102fc7:	83 f0 1f             	xor    $0x1f,%eax
  102fca:	89 44 24 04          	mov    %eax,0x4(%esp)
  102fce:	75 60                	jne    103030 <__umoddi3+0xc0>
  102fd0:	39 e9                	cmp    %ebp,%ecx
  102fd2:	0f 87 08 01 00 00    	ja     1030e0 <__umoddi3+0x170>
  102fd8:	29 cd                	sub    %ecx,%ebp
  102fda:	19 d6                	sbb    %edx,%esi
  102fdc:	89 34 24             	mov    %esi,(%esp)
  102fdf:	8b 14 24             	mov    (%esp),%edx
  102fe2:	89 e8                	mov    %ebp,%eax
  102fe4:	8b 74 24 10          	mov    0x10(%esp),%esi
  102fe8:	8b 7c 24 14          	mov    0x14(%esp),%edi
  102fec:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  102ff0:	83 c4 1c             	add    $0x1c,%esp
  102ff3:	c3                   	ret    
  102ff4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102ff8:	85 c9                	test   %ecx,%ecx
  102ffa:	75 0b                	jne    103007 <__umoddi3+0x97>
  102ffc:	b8 01 00 00 00       	mov    $0x1,%eax
  103001:	31 d2                	xor    %edx,%edx
  103003:	f7 f1                	div    %ecx
  103005:	89 c1                	mov    %eax,%ecx
  103007:	89 f0                	mov    %esi,%eax
  103009:	31 d2                	xor    %edx,%edx
  10300b:	f7 f1                	div    %ecx
  10300d:	89 e8                	mov    %ebp,%eax
  10300f:	f7 f1                	div    %ecx
  103011:	eb 93                	jmp    102fa6 <__umoddi3+0x36>
  103013:	90                   	nop
  103014:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  103018:	89 f2                	mov    %esi,%edx
  10301a:	8b 74 24 10          	mov    0x10(%esp),%esi
  10301e:	8b 7c 24 14          	mov    0x14(%esp),%edi
  103022:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  103026:	83 c4 1c             	add    $0x1c,%esp
  103029:	c3                   	ret    
  10302a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  103030:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  103035:	bd 20 00 00 00       	mov    $0x20,%ebp
  10303a:	89 f8                	mov    %edi,%eax
  10303c:	2b 6c 24 04          	sub    0x4(%esp),%ebp
  103040:	d3 e2                	shl    %cl,%edx
  103042:	89 e9                	mov    %ebp,%ecx
  103044:	d3 e8                	shr    %cl,%eax
  103046:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  10304b:	09 d0                	or     %edx,%eax
  10304d:	89 f2                	mov    %esi,%edx
  10304f:	89 04 24             	mov    %eax,(%esp)
  103052:	8b 44 24 08          	mov    0x8(%esp),%eax
  103056:	d3 e7                	shl    %cl,%edi
  103058:	89 e9                	mov    %ebp,%ecx
  10305a:	d3 ea                	shr    %cl,%edx
  10305c:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  103061:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  103065:	d3 e6                	shl    %cl,%esi
  103067:	89 e9                	mov    %ebp,%ecx
  103069:	d3 e8                	shr    %cl,%eax
  10306b:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  103070:	09 f0                	or     %esi,%eax
  103072:	8b 74 24 08          	mov    0x8(%esp),%esi
  103076:	f7 34 24             	divl   (%esp)
  103079:	d3 e6                	shl    %cl,%esi
  10307b:	89 74 24 08          	mov    %esi,0x8(%esp)
  10307f:	89 d6                	mov    %edx,%esi
  103081:	f7 e7                	mul    %edi
  103083:	39 d6                	cmp    %edx,%esi
  103085:	89 c7                	mov    %eax,%edi
  103087:	89 d1                	mov    %edx,%ecx
  103089:	72 41                	jb     1030cc <__umoddi3+0x15c>
  10308b:	39 44 24 08          	cmp    %eax,0x8(%esp)
  10308f:	72 37                	jb     1030c8 <__umoddi3+0x158>
  103091:	8b 44 24 08          	mov    0x8(%esp),%eax
  103095:	29 f8                	sub    %edi,%eax
  103097:	19 ce                	sbb    %ecx,%esi
  103099:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  10309e:	89 f2                	mov    %esi,%edx
  1030a0:	d3 e8                	shr    %cl,%eax
  1030a2:	89 e9                	mov    %ebp,%ecx
  1030a4:	d3 e2                	shl    %cl,%edx
  1030a6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  1030ab:	09 d0                	or     %edx,%eax
  1030ad:	89 f2                	mov    %esi,%edx
  1030af:	d3 ea                	shr    %cl,%edx
  1030b1:	8b 74 24 10          	mov    0x10(%esp),%esi
  1030b5:	8b 7c 24 14          	mov    0x14(%esp),%edi
  1030b9:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  1030bd:	83 c4 1c             	add    $0x1c,%esp
  1030c0:	c3                   	ret    
  1030c1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  1030c8:	39 d6                	cmp    %edx,%esi
  1030ca:	75 c5                	jne    103091 <__umoddi3+0x121>
  1030cc:	89 d1                	mov    %edx,%ecx
  1030ce:	89 c7                	mov    %eax,%edi
  1030d0:	2b 7c 24 0c          	sub    0xc(%esp),%edi
  1030d4:	1b 0c 24             	sbb    (%esp),%ecx
  1030d7:	eb b8                	jmp    103091 <__umoddi3+0x121>
  1030d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  1030e0:	39 f2                	cmp    %esi,%edx
  1030e2:	0f 82 f0 fe ff ff    	jb     102fd8 <__umoddi3+0x68>
  1030e8:	e9 f2 fe ff ff       	jmp    102fdf <__umoddi3+0x6f>
