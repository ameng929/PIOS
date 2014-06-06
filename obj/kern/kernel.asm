
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
  10001a:	bc 00 90 10 00       	mov    $0x109000,%esp

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
  100048:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  10004e:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  100053:	74 24                	je     100079 <cpu_cur+0x51>
  100055:	c7 44 24 0c a0 58 10 	movl   $0x1058a0,0xc(%esp)
  10005c:	00 
  10005d:	c7 44 24 08 b6 58 10 	movl   $0x1058b6,0x8(%esp)
  100064:	00 
  100065:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  10006c:	00 
  10006d:	c7 04 24 cb 58 10 00 	movl   $0x1058cb,(%esp)
  100074:	e8 4b 04 00 00       	call   1004c4 <debug_panic>
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
  10008d:	3d 00 80 10 00       	cmp    $0x108000,%eax
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
  10009d:	53                   	push   %ebx
  10009e:	83 ec 24             	sub    $0x24,%esp
	extern char start[], edata[], end[];

	// Before anything else, complete the ELF loading process.
	// Clear all uninitialized global data (BSS) in our program,
	// ensuring that all static/global variables start out zero.
	if (cpu_onboot())
  1000a1:	e8 dc ff ff ff       	call   100082 <cpu_onboot>
  1000a6:	85 c0                	test   %eax,%eax
  1000a8:	74 28                	je     1000d2 <init+0x38>
		memset(edata, 0, end - edata);
  1000aa:	ba f0 fa 30 00       	mov    $0x30faf0,%edx
  1000af:	b8 5e 96 10 00       	mov    $0x10965e,%eax
  1000b4:	89 d1                	mov    %edx,%ecx
  1000b6:	29 c1                	sub    %eax,%ecx
  1000b8:	89 c8                	mov    %ecx,%eax
  1000ba:	89 44 24 08          	mov    %eax,0x8(%esp)
  1000be:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1000c5:	00 
  1000c6:	c7 04 24 5e 96 10 00 	movl   $0x10965e,(%esp)
  1000cd:	e8 ef 52 00 00       	call   1053c1 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
  1000d2:	e8 f9 02 00 00       	call   1003d0 <cons_init>

	// Initialize and load the bootstrap CPU's GDT, TSS, and IDT.
	cpu_init();
  1000d7:	e8 f3 10 00 00       	call   1011cf <cpu_init>
	trap_init();
  1000dc:	e8 62 16 00 00       	call   101743 <trap_init>

	// Physical memory detection/initialization.
	// Can't call mem_alloc until after we do this!
	mem_init();
  1000e1:	e8 a4 08 00 00       	call   10098a <mem_init>

	// Lab 2: check spinlock implementation
	if (cpu_onboot())
  1000e6:	e8 97 ff ff ff       	call   100082 <cpu_onboot>
  1000eb:	85 c0                	test   %eax,%eax
  1000ed:	74 05                	je     1000f4 <init+0x5a>
		spinlock_check();
  1000ef:	e8 2b 26 00 00       	call   10271f <spinlock_check>

	// Find and start other processors in a multiprocessor system
	mp_init();		// Find info about processors in system
  1000f4:	e8 a4 22 00 00       	call   10239d <mp_init>
	pic_init();		// setup the legacy PIC (mainly to disable it)
  1000f9:	e8 b6 41 00 00       	call   1042b4 <pic_init>
	ioapic_init();		// prepare to handle external device interrupts
  1000fe:	e8 fa 47 00 00       	call   1048fd <ioapic_init>
	lapic_init();// setup this CPU's local APIC
  100103:	e8 a3 44 00 00       	call   1045ab <lapic_init>
	proc_init();// set the method before bootothers
  100108:	e8 8e 2b 00 00       	call   102c9b <proc_init>
	            // there is a situation that the cpu1 is fast than cpu0,
	            // so that cpu0 will reinit the proc_ready_queue 
	cpu_bootothers();	// Get other processors started
  10010d:	e8 9a 12 00 00       	call   1013ac <cpu_bootothers>
	cprintf("CPU %d (%s) has booted\n", cpu_cur()->id, cpu_onboot() ? "BP" : "AP");
  100112:	e8 6b ff ff ff       	call   100082 <cpu_onboot>
  100117:	85 c0                	test   %eax,%eax
  100119:	74 07                	je     100122 <init+0x88>
  10011b:	bb d8 58 10 00       	mov    $0x1058d8,%ebx
  100120:	eb 05                	jmp    100127 <init+0x8d>
  100122:	bb db 58 10 00       	mov    $0x1058db,%ebx
  100127:	e8 fc fe ff ff       	call   100028 <cpu_cur>
  10012c:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  100133:	0f b6 c0             	movzbl %al,%eax
  100136:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  10013a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10013e:	c7 04 24 de 58 10 00 	movl   $0x1058de,(%esp)
  100145:	e8 92 50 00 00       	call   1051dc <cprintf>

	// Initialize the process management code.
	proc *root_proc;
	if(cpu_onboot()) {
  10014a:	e8 33 ff ff ff       	call   100082 <cpu_onboot>
  10014f:	85 c0                	test   %eax,%eax
  100151:	0f 84 93 00 00 00    	je     1001ea <init+0x150>
		root_proc = proc_alloc(NULL,0);
  100157:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10015e:	00 
  10015f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  100166:	e8 6a 2b 00 00       	call   102cd5 <proc_alloc>
  10016b:	89 45 f4             	mov    %eax,-0xc(%ebp)
		root_proc->sv.tf.esp = (uint32_t)&user_stack[PAGESIZE];
  10016e:	ba 60 a6 10 00       	mov    $0x10a660,%edx
  100173:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100176:	89 90 94 04 00 00    	mov    %edx,0x494(%eax)
		root_proc->sv.tf.eip =  (uint32_t)user;
  10017c:	ba ef 01 10 00       	mov    $0x1001ef,%edx
  100181:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100184:	89 90 88 04 00 00    	mov    %edx,0x488(%eax)
		root_proc->sv.tf.eflags = FL_IF;
  10018a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10018d:	c7 80 90 04 00 00 00 	movl   $0x200,0x490(%eax)
  100194:	02 00 00 
		root_proc->sv.tf.gs = CPU_GDT_UDATA | 3;
  100197:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10019a:	66 c7 80 70 04 00 00 	movw   $0x23,0x470(%eax)
  1001a1:	23 00 
		root_proc->sv.tf.fs = CPU_GDT_UDATA | 3;
  1001a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1001a6:	66 c7 80 74 04 00 00 	movw   $0x23,0x474(%eax)
  1001ad:	23 00 
		root_proc->sv.tf.es = CPU_GDT_UDATA | 3;
  1001af:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1001b2:	66 c7 80 78 04 00 00 	movw   $0x23,0x478(%eax)
  1001b9:	23 00 
		root_proc->sv.tf.ds = CPU_GDT_UDATA | 3;
  1001bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1001be:	66 c7 80 7c 04 00 00 	movw   $0x23,0x47c(%eax)
  1001c5:	23 00 
		root_proc->sv.tf.cs = CPU_GDT_UCODE | 3;
  1001c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1001ca:	66 c7 80 8c 04 00 00 	movw   $0x1b,0x48c(%eax)
  1001d1:	1b 00 
		root_proc->sv.tf.ss = CPU_GDT_UDATA | 3;
  1001d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1001d6:	66 c7 80 98 04 00 00 	movw   $0x23,0x498(%eax)
  1001dd:	23 00 
		proc_ready(root_proc);
  1001df:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1001e2:	89 04 24             	mov    %eax,(%esp)
  1001e5:	e8 6b 2c 00 00       	call   102e55 <proc_ready>
	}
	proc_sched();
  1001ea:	e8 a4 2d 00 00       	call   102f93 <proc_sched>

001001ef <user>:
// This is the first function that gets run in user mode (ring 3).
// It acts as PIOS's "root process",
// of which all other processes are descendants.
void
user()
{
  1001ef:	55                   	push   %ebp
  1001f0:	89 e5                	mov    %esp,%ebp
  1001f2:	53                   	push   %ebx
  1001f3:	83 ec 24             	sub    $0x24,%esp
	cprintf("in user()\n");
  1001f6:	c7 04 24 f6 58 10 00 	movl   $0x1058f6,(%esp)
  1001fd:	e8 da 4f 00 00       	call   1051dc <cprintf>

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100202:	89 e3                	mov    %esp,%ebx
  100204:	89 5d f4             	mov    %ebx,-0xc(%ebp)
        return esp;
  100207:	8b 45 f4             	mov    -0xc(%ebp),%eax
	assert(read_esp() > (uint32_t) &user_stack[0]);
  10020a:	89 c2                	mov    %eax,%edx
  10020c:	b8 60 96 10 00       	mov    $0x109660,%eax
  100211:	39 c2                	cmp    %eax,%edx
  100213:	77 24                	ja     100239 <user+0x4a>
  100215:	c7 44 24 0c 04 59 10 	movl   $0x105904,0xc(%esp)
  10021c:	00 
  10021d:	c7 44 24 08 b6 58 10 	movl   $0x1058b6,0x8(%esp)
  100224:	00 
  100225:	c7 44 24 04 81 00 00 	movl   $0x81,0x4(%esp)
  10022c:	00 
  10022d:	c7 04 24 2b 59 10 00 	movl   $0x10592b,(%esp)
  100234:	e8 8b 02 00 00       	call   1004c4 <debug_panic>

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100239:	89 e3                	mov    %esp,%ebx
  10023b:	89 5d f0             	mov    %ebx,-0x10(%ebp)
        return esp;
  10023e:	8b 45 f0             	mov    -0x10(%ebp),%eax
	assert(read_esp() < (uint32_t) &user_stack[sizeof(user_stack)]);
  100241:	89 c2                	mov    %eax,%edx
  100243:	b8 60 a6 10 00       	mov    $0x10a660,%eax
  100248:	39 c2                	cmp    %eax,%edx
  10024a:	72 24                	jb     100270 <user+0x81>
  10024c:	c7 44 24 0c 38 59 10 	movl   $0x105938,0xc(%esp)
  100253:	00 
  100254:	c7 44 24 08 b6 58 10 	movl   $0x1058b6,0x8(%esp)
  10025b:	00 
  10025c:	c7 44 24 04 82 00 00 	movl   $0x82,0x4(%esp)
  100263:	00 
  100264:	c7 04 24 2b 59 10 00 	movl   $0x10592b,(%esp)
  10026b:	e8 54 02 00 00       	call   1004c4 <debug_panic>

	// Check the system call and process scheduling code.
	proc_check();
  100270:	e8 3d 2f 00 00       	call   1031b2 <proc_check>

	done();
  100275:	e8 00 00 00 00       	call   10027a <done>

0010027a <done>:
// it just puts the processor into an infinite loop.
// We make this a function so that we can set a breakpoints on it.
// Our grade scripts use this breakpoint to know when to stop QEMU.
void gcc_noreturn
done()
{
  10027a:	55                   	push   %ebp
  10027b:	89 e5                	mov    %esp,%ebp
	while (1)
		;	// just spin
  10027d:	eb fe                	jmp    10027d <done+0x3>
  10027f:	90                   	nop

00100280 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  100280:	55                   	push   %ebp
  100281:	89 e5                	mov    %esp,%ebp
  100283:	53                   	push   %ebx
  100284:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100287:	89 e3                	mov    %esp,%ebx
  100289:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  10028c:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  10028f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  100292:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100295:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10029a:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  10029d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1002a0:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  1002a6:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1002ab:	74 24                	je     1002d1 <cpu_cur+0x51>
  1002ad:	c7 44 24 0c 70 59 10 	movl   $0x105970,0xc(%esp)
  1002b4:	00 
  1002b5:	c7 44 24 08 86 59 10 	movl   $0x105986,0x8(%esp)
  1002bc:	00 
  1002bd:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1002c4:	00 
  1002c5:	c7 04 24 9b 59 10 00 	movl   $0x10599b,(%esp)
  1002cc:	e8 f3 01 00 00       	call   1004c4 <debug_panic>
	return c;
  1002d1:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  1002d4:	83 c4 24             	add    $0x24,%esp
  1002d7:	5b                   	pop    %ebx
  1002d8:	5d                   	pop    %ebp
  1002d9:	c3                   	ret    

001002da <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  1002da:	55                   	push   %ebp
  1002db:	89 e5                	mov    %esp,%ebp
  1002dd:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  1002e0:	e8 9b ff ff ff       	call   100280 <cpu_cur>
  1002e5:	3d 00 80 10 00       	cmp    $0x108000,%eax
  1002ea:	0f 94 c0             	sete   %al
  1002ed:	0f b6 c0             	movzbl %al,%eax
}
  1002f0:	c9                   	leave  
  1002f1:	c3                   	ret    

001002f2 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
void
cons_intr(int (*proc)(void))
{
  1002f2:	55                   	push   %ebp
  1002f3:	89 e5                	mov    %esp,%ebp
  1002f5:	83 ec 28             	sub    $0x28,%esp
	int c;

	spinlock_acquire(&cons_lock);
  1002f8:	c7 04 24 00 f3 10 00 	movl   $0x10f300,(%esp)
  1002ff:	e8 d8 22 00 00       	call   1025dc <spinlock_acquire>
	while ((c = (*proc)()) != -1) {
  100304:	eb 35                	jmp    10033b <cons_intr+0x49>
		if (c == 0)
  100306:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  10030a:	74 2e                	je     10033a <cons_intr+0x48>
			continue;
		cons.buf[cons.wpos++] = c;
  10030c:	a1 64 a8 10 00       	mov    0x10a864,%eax
  100311:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100314:	88 90 60 a6 10 00    	mov    %dl,0x10a660(%eax)
  10031a:	83 c0 01             	add    $0x1,%eax
  10031d:	a3 64 a8 10 00       	mov    %eax,0x10a864
		if (cons.wpos == CONSBUFSIZE)
  100322:	a1 64 a8 10 00       	mov    0x10a864,%eax
  100327:	3d 00 02 00 00       	cmp    $0x200,%eax
  10032c:	75 0d                	jne    10033b <cons_intr+0x49>
			cons.wpos = 0;
  10032e:	c7 05 64 a8 10 00 00 	movl   $0x0,0x10a864
  100335:	00 00 00 
  100338:	eb 01                	jmp    10033b <cons_intr+0x49>
	int c;

	spinlock_acquire(&cons_lock);
	while ((c = (*proc)()) != -1) {
		if (c == 0)
			continue;
  10033a:	90                   	nop
cons_intr(int (*proc)(void))
{
	int c;

	spinlock_acquire(&cons_lock);
	while ((c = (*proc)()) != -1) {
  10033b:	8b 45 08             	mov    0x8(%ebp),%eax
  10033e:	ff d0                	call   *%eax
  100340:	89 45 f4             	mov    %eax,-0xc(%ebp)
  100343:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
  100347:	75 bd                	jne    100306 <cons_intr+0x14>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
	spinlock_release(&cons_lock);
  100349:	c7 04 24 00 f3 10 00 	movl   $0x10f300,(%esp)
  100350:	e8 03 23 00 00       	call   102658 <spinlock_release>

}
  100355:	c9                   	leave  
  100356:	c3                   	ret    

00100357 <cons_getc>:

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
  100357:	55                   	push   %ebp
  100358:	89 e5                	mov    %esp,%ebp
  10035a:	83 ec 18             	sub    $0x18,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
  10035d:	e8 e0 3d 00 00       	call   104142 <serial_intr>
	kbd_intr();
  100362:	e8 07 3d 00 00       	call   10406e <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
  100367:	8b 15 60 a8 10 00    	mov    0x10a860,%edx
  10036d:	a1 64 a8 10 00       	mov    0x10a864,%eax
  100372:	39 c2                	cmp    %eax,%edx
  100374:	74 35                	je     1003ab <cons_getc+0x54>
		c = cons.buf[cons.rpos++];
  100376:	a1 60 a8 10 00       	mov    0x10a860,%eax
  10037b:	0f b6 90 60 a6 10 00 	movzbl 0x10a660(%eax),%edx
  100382:	0f b6 d2             	movzbl %dl,%edx
  100385:	89 55 f4             	mov    %edx,-0xc(%ebp)
  100388:	83 c0 01             	add    $0x1,%eax
  10038b:	a3 60 a8 10 00       	mov    %eax,0x10a860
		if (cons.rpos == CONSBUFSIZE)
  100390:	a1 60 a8 10 00       	mov    0x10a860,%eax
  100395:	3d 00 02 00 00       	cmp    $0x200,%eax
  10039a:	75 0a                	jne    1003a6 <cons_getc+0x4f>
			cons.rpos = 0;
  10039c:	c7 05 60 a8 10 00 00 	movl   $0x0,0x10a860
  1003a3:	00 00 00 
		return c;
  1003a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1003a9:	eb 05                	jmp    1003b0 <cons_getc+0x59>
	}
	return 0;
  1003ab:	b8 00 00 00 00       	mov    $0x0,%eax
}
  1003b0:	c9                   	leave  
  1003b1:	c3                   	ret    

001003b2 <cons_putc>:

// output a character to the console
static void
cons_putc(int c)
{
  1003b2:	55                   	push   %ebp
  1003b3:	89 e5                	mov    %esp,%ebp
  1003b5:	83 ec 18             	sub    $0x18,%esp
	serial_putc(c);
  1003b8:	8b 45 08             	mov    0x8(%ebp),%eax
  1003bb:	89 04 24             	mov    %eax,(%esp)
  1003be:	e8 9c 3d 00 00       	call   10415f <serial_putc>
	video_putc(c);
  1003c3:	8b 45 08             	mov    0x8(%ebp),%eax
  1003c6:	89 04 24             	mov    %eax,(%esp)
  1003c9:	e8 f3 38 00 00       	call   103cc1 <video_putc>
}
  1003ce:	c9                   	leave  
  1003cf:	c3                   	ret    

001003d0 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
  1003d0:	55                   	push   %ebp
  1003d1:	89 e5                	mov    %esp,%ebp
  1003d3:	83 ec 18             	sub    $0x18,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  1003d6:	e8 ff fe ff ff       	call   1002da <cpu_onboot>
  1003db:	85 c0                	test   %eax,%eax
  1003dd:	74 52                	je     100431 <cons_init+0x61>
		return;

	spinlock_init(&cons_lock);
  1003df:	c7 44 24 08 6a 00 00 	movl   $0x6a,0x8(%esp)
  1003e6:	00 
  1003e7:	c7 44 24 04 a8 59 10 	movl   $0x1059a8,0x4(%esp)
  1003ee:	00 
  1003ef:	c7 04 24 00 f3 10 00 	movl   $0x10f300,(%esp)
  1003f6:	e8 b7 21 00 00       	call   1025b2 <spinlock_init_>
	video_init();
  1003fb:	e8 e4 37 00 00       	call   103be4 <video_init>
	kbd_init();
  100400:	e8 7d 3c 00 00       	call   104082 <kbd_init>
	serial_init();
  100405:	e8 c5 3d 00 00       	call   1041cf <serial_init>

	if (!serial_exists)
  10040a:	a1 e8 fa 30 00       	mov    0x30fae8,%eax
  10040f:	85 c0                	test   %eax,%eax
  100411:	75 1f                	jne    100432 <cons_init+0x62>
		warn("Serial port does not exist!\n");
  100413:	c7 44 24 08 b4 59 10 	movl   $0x1059b4,0x8(%esp)
  10041a:	00 
  10041b:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
  100422:	00 
  100423:	c7 04 24 a8 59 10 00 	movl   $0x1059a8,(%esp)
  10042a:	e8 5b 01 00 00       	call   10058a <debug_warn>
  10042f:	eb 01                	jmp    100432 <cons_init+0x62>
// initialize the console devices
void
cons_init(void)
{
	if (!cpu_onboot())	// only do once, on the boot CPU
		return;
  100431:	90                   	nop
	kbd_init();
	serial_init();

	if (!serial_exists)
		warn("Serial port does not exist!\n");
}
  100432:	c9                   	leave  
  100433:	c3                   	ret    

00100434 <cputs>:


// `High'-level console I/O.  Used by readline and cprintf.
void
cputs(const char *str)
{
  100434:	55                   	push   %ebp
  100435:	89 e5                	mov    %esp,%ebp
  100437:	53                   	push   %ebx
  100438:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  10043b:	66 8c cb             	mov    %cs,%bx
  10043e:	66 89 5d f2          	mov    %bx,-0xe(%ebp)
        return cs;
  100442:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
	if (read_cs() & 3)
  100446:	0f b7 c0             	movzwl %ax,%eax
  100449:	83 e0 03             	and    $0x3,%eax
  10044c:	85 c0                	test   %eax,%eax
  10044e:	74 14                	je     100464 <cputs+0x30>
  100450:	8b 45 08             	mov    0x8(%ebp),%eax
  100453:	89 45 ec             	mov    %eax,-0x14(%ebp)
	// 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
  100456:	b8 00 00 00 00       	mov    $0x0,%eax
  10045b:	8b 55 ec             	mov    -0x14(%ebp),%edx
  10045e:	89 d3                	mov    %edx,%ebx
  100460:	cd 30                	int    $0x30
		return sys_cputs(str);	// use syscall from user mode
  100462:	eb 57                	jmp    1004bb <cputs+0x87>

	// Hold the console spinlock while printing the entire string,
	// so that the output of different cputs calls won't get mixed.
	// Implement ad hoc recursive locking for debugging convenience.
	bool already = spinlock_holding(&cons_lock);
  100464:	c7 04 24 00 f3 10 00 	movl   $0x10f300,(%esp)
  10046b:	e8 42 22 00 00       	call   1026b2 <spinlock_holding>
  100470:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (!already)
  100473:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  100477:	75 25                	jne    10049e <cputs+0x6a>
		spinlock_acquire(&cons_lock);
  100479:	c7 04 24 00 f3 10 00 	movl   $0x10f300,(%esp)
  100480:	e8 57 21 00 00       	call   1025dc <spinlock_acquire>

	char ch;
	while (*str)
  100485:	eb 17                	jmp    10049e <cputs+0x6a>
		cons_putc(*str++);
  100487:	8b 45 08             	mov    0x8(%ebp),%eax
  10048a:	0f b6 00             	movzbl (%eax),%eax
  10048d:	0f be c0             	movsbl %al,%eax
  100490:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  100494:	89 04 24             	mov    %eax,(%esp)
  100497:	e8 16 ff ff ff       	call   1003b2 <cons_putc>
  10049c:	eb 01                	jmp    10049f <cputs+0x6b>
	bool already = spinlock_holding(&cons_lock);
	if (!already)
		spinlock_acquire(&cons_lock);

	char ch;
	while (*str)
  10049e:	90                   	nop
  10049f:	8b 45 08             	mov    0x8(%ebp),%eax
  1004a2:	0f b6 00             	movzbl (%eax),%eax
  1004a5:	84 c0                	test   %al,%al
  1004a7:	75 de                	jne    100487 <cputs+0x53>
		cons_putc(*str++);

	if (!already)
  1004a9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1004ad:	75 0c                	jne    1004bb <cputs+0x87>
		spinlock_release(&cons_lock);
  1004af:	c7 04 24 00 f3 10 00 	movl   $0x10f300,(%esp)
  1004b6:	e8 9d 21 00 00       	call   102658 <spinlock_release>
}
  1004bb:	83 c4 24             	add    $0x24,%esp
  1004be:	5b                   	pop    %ebx
  1004bf:	5d                   	pop    %ebp
  1004c0:	c3                   	ret    
  1004c1:	90                   	nop
  1004c2:	90                   	nop
  1004c3:	90                   	nop

001004c4 <debug_panic>:

// Panic is called on unresolvable fatal errors.
// It prints "panic: mesg", and then enters the kernel monitor.
void
debug_panic(const char *file, int line, const char *fmt,...)
{
  1004c4:	55                   	push   %ebp
  1004c5:	89 e5                	mov    %esp,%ebp
  1004c7:	53                   	push   %ebx
  1004c8:	83 ec 54             	sub    $0x54,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  1004cb:	66 8c cb             	mov    %cs,%bx
  1004ce:	66 89 5d ee          	mov    %bx,-0x12(%ebp)
        return cs;
  1004d2:	0f b7 45 ee          	movzwl -0x12(%ebp),%eax
	va_list ap;
	int i;

	// Avoid infinite recursion if we're panicking from kernel mode.
	if ((read_cs() & 3) == 0) {
  1004d6:	0f b7 c0             	movzwl %ax,%eax
  1004d9:	83 e0 03             	and    $0x3,%eax
  1004dc:	85 c0                	test   %eax,%eax
  1004de:	75 15                	jne    1004f5 <debug_panic+0x31>
		if (panicstr)
  1004e0:	a1 68 a8 10 00       	mov    0x10a868,%eax
  1004e5:	85 c0                	test   %eax,%eax
  1004e7:	0f 85 97 00 00 00    	jne    100584 <debug_panic+0xc0>
			goto dead;
		panicstr = fmt;
  1004ed:	8b 45 10             	mov    0x10(%ebp),%eax
  1004f0:	a3 68 a8 10 00       	mov    %eax,0x10a868
	}

	// First print the requested message
	va_start(ap, fmt);
  1004f5:	8d 45 10             	lea    0x10(%ebp),%eax
  1004f8:	83 c0 04             	add    $0x4,%eax
  1004fb:	89 45 f0             	mov    %eax,-0x10(%ebp)
	cprintf("kernel panic at %s:%d: ", file, line);
  1004fe:	8b 45 0c             	mov    0xc(%ebp),%eax
  100501:	89 44 24 08          	mov    %eax,0x8(%esp)
  100505:	8b 45 08             	mov    0x8(%ebp),%eax
  100508:	89 44 24 04          	mov    %eax,0x4(%esp)
  10050c:	c7 04 24 d1 59 10 00 	movl   $0x1059d1,(%esp)
  100513:	e8 c4 4c 00 00       	call   1051dc <cprintf>
	vcprintf(fmt, ap);
  100518:	8b 45 10             	mov    0x10(%ebp),%eax
  10051b:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10051e:	89 54 24 04          	mov    %edx,0x4(%esp)
  100522:	89 04 24             	mov    %eax,(%esp)
  100525:	e8 4a 4c 00 00       	call   105174 <vcprintf>
	cprintf("\n");
  10052a:	c7 04 24 e9 59 10 00 	movl   $0x1059e9,(%esp)
  100531:	e8 a6 4c 00 00       	call   1051dc <cprintf>

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  100536:	89 eb                	mov    %ebp,%ebx
  100538:	89 5d e8             	mov    %ebx,-0x18(%ebp)
        return ebp;
  10053b:	8b 45 e8             	mov    -0x18(%ebp),%eax
	va_end(ap);

	// Then print a backtrace of the kernel call chain
	uint32_t eips[DEBUG_TRACEFRAMES];
	debug_trace(read_ebp(), eips);
  10053e:	8d 55 c0             	lea    -0x40(%ebp),%edx
  100541:	89 54 24 04          	mov    %edx,0x4(%esp)
  100545:	89 04 24             	mov    %eax,(%esp)
  100548:	e8 86 00 00 00       	call   1005d3 <debug_trace>
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
  10054d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  100554:	eb 1b                	jmp    100571 <debug_panic+0xad>
		cprintf("  from %08x\n", eips[i]);
  100556:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100559:	8b 44 85 c0          	mov    -0x40(%ebp,%eax,4),%eax
  10055d:	89 44 24 04          	mov    %eax,0x4(%esp)
  100561:	c7 04 24 eb 59 10 00 	movl   $0x1059eb,(%esp)
  100568:	e8 6f 4c 00 00       	call   1051dc <cprintf>
	va_end(ap);

	// Then print a backtrace of the kernel call chain
	uint32_t eips[DEBUG_TRACEFRAMES];
	debug_trace(read_ebp(), eips);
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
  10056d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  100571:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  100575:	7f 0e                	jg     100585 <debug_panic+0xc1>
  100577:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10057a:	8b 44 85 c0          	mov    -0x40(%ebp,%eax,4),%eax
  10057e:	85 c0                	test   %eax,%eax
  100580:	75 d4                	jne    100556 <debug_panic+0x92>
  100582:	eb 01                	jmp    100585 <debug_panic+0xc1>
	int i;

	// Avoid infinite recursion if we're panicking from kernel mode.
	if ((read_cs() & 3) == 0) {
		if (panicstr)
			goto dead;
  100584:	90                   	nop
	debug_trace(read_ebp(), eips);
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
		cprintf("  from %08x\n", eips[i]);

dead:
	done();		// enter infinite loop (see kern/init.c)
  100585:	e8 f0 fc ff ff       	call   10027a <done>

0010058a <debug_warn>:
}

/* like panic, but don't */
void
debug_warn(const char *file, int line, const char *fmt,...)
{
  10058a:	55                   	push   %ebp
  10058b:	89 e5                	mov    %esp,%ebp
  10058d:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
  100590:	8d 45 10             	lea    0x10(%ebp),%eax
  100593:	83 c0 04             	add    $0x4,%eax
  100596:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("kernel warning at %s:%d: ", file, line);
  100599:	8b 45 0c             	mov    0xc(%ebp),%eax
  10059c:	89 44 24 08          	mov    %eax,0x8(%esp)
  1005a0:	8b 45 08             	mov    0x8(%ebp),%eax
  1005a3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1005a7:	c7 04 24 f8 59 10 00 	movl   $0x1059f8,(%esp)
  1005ae:	e8 29 4c 00 00       	call   1051dc <cprintf>
	vcprintf(fmt, ap);
  1005b3:	8b 45 10             	mov    0x10(%ebp),%eax
  1005b6:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1005b9:	89 54 24 04          	mov    %edx,0x4(%esp)
  1005bd:	89 04 24             	mov    %eax,(%esp)
  1005c0:	e8 af 4b 00 00       	call   105174 <vcprintf>
	cprintf("\n");
  1005c5:	c7 04 24 e9 59 10 00 	movl   $0x1059e9,(%esp)
  1005cc:	e8 0b 4c 00 00       	call   1051dc <cprintf>
	va_end(ap);
}
  1005d1:	c9                   	leave  
  1005d2:	c3                   	ret    

001005d3 <debug_trace>:

// Record the current call stack in eips[] by following the %ebp chain.
void gcc_noinline
debug_trace(uint32_t ebp, uint32_t eips[DEBUG_TRACEFRAMES])
{
  1005d3:	55                   	push   %ebp
  1005d4:	89 e5                	mov    %esp,%ebp
  1005d6:	83 ec 10             	sub    $0x10,%esp
	uint32_t *trace = (uint32_t *) ebp;
  1005d9:	8b 45 08             	mov    0x8(%ebp),%eax
  1005dc:	89 45 fc             	mov    %eax,-0x4(%ebp)
  	int i;

  	//cprintf("Stack backtrace:\n");
  	for (i = 0; i < DEBUG_TRACEFRAMES && trace; i++) {
  1005df:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  1005e6:	eb 23                	jmp    10060b <debug_trace+0x38>
    		//cprintf("ebp %08x  ", trace[0]);
    		//cprintf("eip %08x  ", trace[1]);
    		//cprintf("args %08x %08x %08x %08x %08x ", trace[2], trace[3], trace[4], trace[5], trace[6]);
    		//cprintf("\n"); 
		//save eips
    		eips[i] = trace[1];
  1005e8:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1005eb:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  1005f2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1005f5:	01 c2                	add    %eax,%edx
  1005f7:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1005fa:	8b 40 04             	mov    0x4(%eax),%eax
  1005fd:	89 02                	mov    %eax,(%edx)

    		//traceback the call stack using old ebp
    		trace = (uint32_t*)trace[0];  // prev ebp saved at ebp 0
  1005ff:	8b 45 fc             	mov    -0x4(%ebp),%eax
  100602:	8b 00                	mov    (%eax),%eax
  100604:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
	uint32_t *trace = (uint32_t *) ebp;
  	int i;

  	//cprintf("Stack backtrace:\n");
  	for (i = 0; i < DEBUG_TRACEFRAMES && trace; i++) {
  100607:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  10060b:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
  10060f:	7f 21                	jg     100632 <debug_trace+0x5f>
  100611:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
  100615:	75 d1                	jne    1005e8 <debug_trace+0x15>
    		//traceback the call stack using old ebp
    		trace = (uint32_t*)trace[0];  // prev ebp saved at ebp 0
  	}

  	// set rest eips as 0
  	for (i; i < DEBUG_TRACEFRAMES; i++) {
  100617:	eb 19                	jmp    100632 <debug_trace+0x5f>
    		eips[i] = 0; 
  100619:	8b 45 f8             	mov    -0x8(%ebp),%eax
  10061c:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  100623:	8b 45 0c             	mov    0xc(%ebp),%eax
  100626:	01 d0                	add    %edx,%eax
  100628:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    		//traceback the call stack using old ebp
    		trace = (uint32_t*)trace[0];  // prev ebp saved at ebp 0
  	}

  	// set rest eips as 0
  	for (i; i < DEBUG_TRACEFRAMES; i++) {
  10062e:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  100632:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
  100636:	7e e1                	jle    100619 <debug_trace+0x46>
    		eips[i] = 0; 
  	}
	//panic("debug_trace not implemented");
}
  100638:	c9                   	leave  
  100639:	c3                   	ret    

0010063a <f3>:


static void gcc_noinline f3(int r, uint32_t *e) { debug_trace(read_ebp(), e); }
  10063a:	55                   	push   %ebp
  10063b:	89 e5                	mov    %esp,%ebp
  10063d:	53                   	push   %ebx
  10063e:	83 ec 18             	sub    $0x18,%esp

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  100641:	89 eb                	mov    %ebp,%ebx
  100643:	89 5d f8             	mov    %ebx,-0x8(%ebp)
        return ebp;
  100646:	8b 45 f8             	mov    -0x8(%ebp),%eax
  100649:	8b 55 0c             	mov    0xc(%ebp),%edx
  10064c:	89 54 24 04          	mov    %edx,0x4(%esp)
  100650:	89 04 24             	mov    %eax,(%esp)
  100653:	e8 7b ff ff ff       	call   1005d3 <debug_trace>
  100658:	83 c4 18             	add    $0x18,%esp
  10065b:	5b                   	pop    %ebx
  10065c:	5d                   	pop    %ebp
  10065d:	c3                   	ret    

0010065e <f2>:
static void gcc_noinline f2(int r, uint32_t *e) { r & 2 ? f3(r,e) : f3(r,e); }
  10065e:	55                   	push   %ebp
  10065f:	89 e5                	mov    %esp,%ebp
  100661:	83 ec 08             	sub    $0x8,%esp
  100664:	8b 45 08             	mov    0x8(%ebp),%eax
  100667:	83 e0 02             	and    $0x2,%eax
  10066a:	85 c0                	test   %eax,%eax
  10066c:	74 14                	je     100682 <f2+0x24>
  10066e:	8b 45 0c             	mov    0xc(%ebp),%eax
  100671:	89 44 24 04          	mov    %eax,0x4(%esp)
  100675:	8b 45 08             	mov    0x8(%ebp),%eax
  100678:	89 04 24             	mov    %eax,(%esp)
  10067b:	e8 ba ff ff ff       	call   10063a <f3>
  100680:	eb 12                	jmp    100694 <f2+0x36>
  100682:	8b 45 0c             	mov    0xc(%ebp),%eax
  100685:	89 44 24 04          	mov    %eax,0x4(%esp)
  100689:	8b 45 08             	mov    0x8(%ebp),%eax
  10068c:	89 04 24             	mov    %eax,(%esp)
  10068f:	e8 a6 ff ff ff       	call   10063a <f3>
  100694:	c9                   	leave  
  100695:	c3                   	ret    

00100696 <f1>:
static void gcc_noinline f1(int r, uint32_t *e) { r & 1 ? f2(r,e) : f2(r,e); }
  100696:	55                   	push   %ebp
  100697:	89 e5                	mov    %esp,%ebp
  100699:	83 ec 08             	sub    $0x8,%esp
  10069c:	8b 45 08             	mov    0x8(%ebp),%eax
  10069f:	83 e0 01             	and    $0x1,%eax
  1006a2:	85 c0                	test   %eax,%eax
  1006a4:	74 14                	je     1006ba <f1+0x24>
  1006a6:	8b 45 0c             	mov    0xc(%ebp),%eax
  1006a9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1006ad:	8b 45 08             	mov    0x8(%ebp),%eax
  1006b0:	89 04 24             	mov    %eax,(%esp)
  1006b3:	e8 a6 ff ff ff       	call   10065e <f2>
  1006b8:	eb 12                	jmp    1006cc <f1+0x36>
  1006ba:	8b 45 0c             	mov    0xc(%ebp),%eax
  1006bd:	89 44 24 04          	mov    %eax,0x4(%esp)
  1006c1:	8b 45 08             	mov    0x8(%ebp),%eax
  1006c4:	89 04 24             	mov    %eax,(%esp)
  1006c7:	e8 92 ff ff ff       	call   10065e <f2>
  1006cc:	c9                   	leave  
  1006cd:	c3                   	ret    

001006ce <debug_check>:

// Test the backtrace implementation for correct operation
void
debug_check(void)
{
  1006ce:	55                   	push   %ebp
  1006cf:	89 e5                	mov    %esp,%ebp
  1006d1:	81 ec c8 00 00 00    	sub    $0xc8,%esp
	uint32_t eips[4][DEBUG_TRACEFRAMES];
	int r, i;

	// produce several related backtraces...
	for (i = 0; i < 4; i++)
  1006d7:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  1006de:	eb 28                	jmp    100708 <debug_check+0x3a>
		f1(i, eips[i]);
  1006e0:	8d 8d 50 ff ff ff    	lea    -0xb0(%ebp),%ecx
  1006e6:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1006e9:	89 d0                	mov    %edx,%eax
  1006eb:	c1 e0 02             	shl    $0x2,%eax
  1006ee:	01 d0                	add    %edx,%eax
  1006f0:	c1 e0 03             	shl    $0x3,%eax
  1006f3:	01 c8                	add    %ecx,%eax
  1006f5:	89 44 24 04          	mov    %eax,0x4(%esp)
  1006f9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1006fc:	89 04 24             	mov    %eax,(%esp)
  1006ff:	e8 92 ff ff ff       	call   100696 <f1>
{
	uint32_t eips[4][DEBUG_TRACEFRAMES];
	int r, i;

	// produce several related backtraces...
	for (i = 0; i < 4; i++)
  100704:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  100708:	83 7d f0 03          	cmpl   $0x3,-0x10(%ebp)
  10070c:	7e d2                	jle    1006e0 <debug_check+0x12>
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
  10070e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  100715:	e9 bc 00 00 00       	jmp    1007d6 <debug_check+0x108>
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
  10071a:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  100721:	e9 a2 00 00 00       	jmp    1007c8 <debug_check+0xfa>
			assert((eips[r][i] != 0) == (i < 5));
  100726:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100729:	89 d0                	mov    %edx,%eax
  10072b:	c1 e0 02             	shl    $0x2,%eax
  10072e:	01 d0                	add    %edx,%eax
  100730:	01 c0                	add    %eax,%eax
  100732:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100735:	01 d0                	add    %edx,%eax
  100737:	8b 84 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%eax
  10073e:	85 c0                	test   %eax,%eax
  100740:	0f 95 c2             	setne  %dl
  100743:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
  100747:	0f 9e c0             	setle  %al
  10074a:	31 d0                	xor    %edx,%eax
  10074c:	84 c0                	test   %al,%al
  10074e:	74 24                	je     100774 <debug_check+0xa6>
  100750:	c7 44 24 0c 12 5a 10 	movl   $0x105a12,0xc(%esp)
  100757:	00 
  100758:	c7 44 24 08 2f 5a 10 	movl   $0x105a2f,0x8(%esp)
  10075f:	00 
  100760:	c7 44 24 04 75 00 00 	movl   $0x75,0x4(%esp)
  100767:	00 
  100768:	c7 04 24 44 5a 10 00 	movl   $0x105a44,(%esp)
  10076f:	e8 50 fd ff ff       	call   1004c4 <debug_panic>
			if (i >= 2)
  100774:	83 7d f0 01          	cmpl   $0x1,-0x10(%ebp)
  100778:	7e 4a                	jle    1007c4 <debug_check+0xf6>
				assert(eips[r][i] == eips[0][i]);
  10077a:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10077d:	89 d0                	mov    %edx,%eax
  10077f:	c1 e0 02             	shl    $0x2,%eax
  100782:	01 d0                	add    %edx,%eax
  100784:	01 c0                	add    %eax,%eax
  100786:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100789:	01 d0                	add    %edx,%eax
  10078b:	8b 94 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%edx
  100792:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100795:	8b 84 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%eax
  10079c:	39 c2                	cmp    %eax,%edx
  10079e:	74 24                	je     1007c4 <debug_check+0xf6>
  1007a0:	c7 44 24 0c 51 5a 10 	movl   $0x105a51,0xc(%esp)
  1007a7:	00 
  1007a8:	c7 44 24 08 2f 5a 10 	movl   $0x105a2f,0x8(%esp)
  1007af:	00 
  1007b0:	c7 44 24 04 77 00 00 	movl   $0x77,0x4(%esp)
  1007b7:	00 
  1007b8:	c7 04 24 44 5a 10 00 	movl   $0x105a44,(%esp)
  1007bf:	e8 00 fd ff ff       	call   1004c4 <debug_panic>
	for (i = 0; i < 4; i++)
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
  1007c4:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  1007c8:	83 7d f0 09          	cmpl   $0x9,-0x10(%ebp)
  1007cc:	0f 8e 54 ff ff ff    	jle    100726 <debug_check+0x58>
	// produce several related backtraces...
	for (i = 0; i < 4; i++)
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
  1007d2:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  1007d6:	83 7d f4 03          	cmpl   $0x3,-0xc(%ebp)
  1007da:	0f 8e 3a ff ff ff    	jle    10071a <debug_check+0x4c>
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
			assert((eips[r][i] != 0) == (i < 5));
			if (i >= 2)
				assert(eips[r][i] == eips[0][i]);
		}
	assert(eips[0][0] == eips[1][0]);
  1007e0:	8b 95 50 ff ff ff    	mov    -0xb0(%ebp),%edx
  1007e6:	8b 85 78 ff ff ff    	mov    -0x88(%ebp),%eax
  1007ec:	39 c2                	cmp    %eax,%edx
  1007ee:	74 24                	je     100814 <debug_check+0x146>
  1007f0:	c7 44 24 0c 6a 5a 10 	movl   $0x105a6a,0xc(%esp)
  1007f7:	00 
  1007f8:	c7 44 24 08 2f 5a 10 	movl   $0x105a2f,0x8(%esp)
  1007ff:	00 
  100800:	c7 44 24 04 79 00 00 	movl   $0x79,0x4(%esp)
  100807:	00 
  100808:	c7 04 24 44 5a 10 00 	movl   $0x105a44,(%esp)
  10080f:	e8 b0 fc ff ff       	call   1004c4 <debug_panic>
	assert(eips[2][0] == eips[3][0]);
  100814:	8b 55 a0             	mov    -0x60(%ebp),%edx
  100817:	8b 45 c8             	mov    -0x38(%ebp),%eax
  10081a:	39 c2                	cmp    %eax,%edx
  10081c:	74 24                	je     100842 <debug_check+0x174>
  10081e:	c7 44 24 0c 83 5a 10 	movl   $0x105a83,0xc(%esp)
  100825:	00 
  100826:	c7 44 24 08 2f 5a 10 	movl   $0x105a2f,0x8(%esp)
  10082d:	00 
  10082e:	c7 44 24 04 7a 00 00 	movl   $0x7a,0x4(%esp)
  100835:	00 
  100836:	c7 04 24 44 5a 10 00 	movl   $0x105a44,(%esp)
  10083d:	e8 82 fc ff ff       	call   1004c4 <debug_panic>
	assert(eips[1][0] != eips[2][0]);
  100842:	8b 95 78 ff ff ff    	mov    -0x88(%ebp),%edx
  100848:	8b 45 a0             	mov    -0x60(%ebp),%eax
  10084b:	39 c2                	cmp    %eax,%edx
  10084d:	75 24                	jne    100873 <debug_check+0x1a5>
  10084f:	c7 44 24 0c 9c 5a 10 	movl   $0x105a9c,0xc(%esp)
  100856:	00 
  100857:	c7 44 24 08 2f 5a 10 	movl   $0x105a2f,0x8(%esp)
  10085e:	00 
  10085f:	c7 44 24 04 7b 00 00 	movl   $0x7b,0x4(%esp)
  100866:	00 
  100867:	c7 04 24 44 5a 10 00 	movl   $0x105a44,(%esp)
  10086e:	e8 51 fc ff ff       	call   1004c4 <debug_panic>
	assert(eips[0][1] == eips[2][1]);
  100873:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  100879:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  10087c:	39 c2                	cmp    %eax,%edx
  10087e:	74 24                	je     1008a4 <debug_check+0x1d6>
  100880:	c7 44 24 0c b5 5a 10 	movl   $0x105ab5,0xc(%esp)
  100887:	00 
  100888:	c7 44 24 08 2f 5a 10 	movl   $0x105a2f,0x8(%esp)
  10088f:	00 
  100890:	c7 44 24 04 7c 00 00 	movl   $0x7c,0x4(%esp)
  100897:	00 
  100898:	c7 04 24 44 5a 10 00 	movl   $0x105a44,(%esp)
  10089f:	e8 20 fc ff ff       	call   1004c4 <debug_panic>
	assert(eips[1][1] == eips[3][1]);
  1008a4:	8b 95 7c ff ff ff    	mov    -0x84(%ebp),%edx
  1008aa:	8b 45 cc             	mov    -0x34(%ebp),%eax
  1008ad:	39 c2                	cmp    %eax,%edx
  1008af:	74 24                	je     1008d5 <debug_check+0x207>
  1008b1:	c7 44 24 0c ce 5a 10 	movl   $0x105ace,0xc(%esp)
  1008b8:	00 
  1008b9:	c7 44 24 08 2f 5a 10 	movl   $0x105a2f,0x8(%esp)
  1008c0:	00 
  1008c1:	c7 44 24 04 7d 00 00 	movl   $0x7d,0x4(%esp)
  1008c8:	00 
  1008c9:	c7 04 24 44 5a 10 00 	movl   $0x105a44,(%esp)
  1008d0:	e8 ef fb ff ff       	call   1004c4 <debug_panic>
	assert(eips[0][1] != eips[1][1]);
  1008d5:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  1008db:	8b 85 7c ff ff ff    	mov    -0x84(%ebp),%eax
  1008e1:	39 c2                	cmp    %eax,%edx
  1008e3:	75 24                	jne    100909 <debug_check+0x23b>
  1008e5:	c7 44 24 0c e7 5a 10 	movl   $0x105ae7,0xc(%esp)
  1008ec:	00 
  1008ed:	c7 44 24 08 2f 5a 10 	movl   $0x105a2f,0x8(%esp)
  1008f4:	00 
  1008f5:	c7 44 24 04 7e 00 00 	movl   $0x7e,0x4(%esp)
  1008fc:	00 
  1008fd:	c7 04 24 44 5a 10 00 	movl   $0x105a44,(%esp)
  100904:	e8 bb fb ff ff       	call   1004c4 <debug_panic>

	cprintf("debug_check() succeeded!\n");
  100909:	c7 04 24 00 5b 10 00 	movl   $0x105b00,(%esp)
  100910:	e8 c7 48 00 00       	call   1051dc <cprintf>
//	while(1);
}
  100915:	c9                   	leave  
  100916:	c3                   	ret    
  100917:	90                   	nop

00100918 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  100918:	55                   	push   %ebp
  100919:	89 e5                	mov    %esp,%ebp
  10091b:	53                   	push   %ebx
  10091c:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10091f:	89 e3                	mov    %esp,%ebx
  100921:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  100924:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  100927:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10092a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10092d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100932:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  100935:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100938:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  10093e:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  100943:	74 24                	je     100969 <cpu_cur+0x51>
  100945:	c7 44 24 0c 1c 5b 10 	movl   $0x105b1c,0xc(%esp)
  10094c:	00 
  10094d:	c7 44 24 08 32 5b 10 	movl   $0x105b32,0x8(%esp)
  100954:	00 
  100955:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  10095c:	00 
  10095d:	c7 04 24 47 5b 10 00 	movl   $0x105b47,(%esp)
  100964:	e8 5b fb ff ff       	call   1004c4 <debug_panic>
	return c;
  100969:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  10096c:	83 c4 24             	add    $0x24,%esp
  10096f:	5b                   	pop    %ebx
  100970:	5d                   	pop    %ebp
  100971:	c3                   	ret    

00100972 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  100972:	55                   	push   %ebp
  100973:	89 e5                	mov    %esp,%ebp
  100975:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  100978:	e8 9b ff ff ff       	call   100918 <cpu_cur>
  10097d:	3d 00 80 10 00       	cmp    $0x108000,%eax
  100982:	0f 94 c0             	sete   %al
  100985:	0f b6 c0             	movzbl %al,%eax
}
  100988:	c9                   	leave  
  100989:	c3                   	ret    

0010098a <mem_init>:

void mem_check(void);

void
mem_init(void)
{
  10098a:	55                   	push   %ebp
  10098b:	89 e5                	mov    %esp,%ebp
  10098d:	83 ec 38             	sub    $0x38,%esp
	extern char start[], edata[], end[];
	cprintf("start : 0x%x, 0x%x\n",start, &start[0]);
  100990:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
  100997:	00 
  100998:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
  10099f:	00 
  1009a0:	c7 04 24 54 5b 10 00 	movl   $0x105b54,(%esp)
  1009a7:	e8 30 48 00 00       	call   1051dc <cprintf>
	cprintf("edata : 0x%x\n",edata);
  1009ac:	c7 44 24 04 5e 96 10 	movl   $0x10965e,0x4(%esp)
  1009b3:	00 
  1009b4:	c7 04 24 68 5b 10 00 	movl   $0x105b68,(%esp)
  1009bb:	e8 1c 48 00 00       	call   1051dc <cprintf>
	cprintf("end : 0x%x, 0x%x\n",end, &end[0]);
  1009c0:	c7 44 24 08 f0 fa 30 	movl   $0x30faf0,0x8(%esp)
  1009c7:	00 
  1009c8:	c7 44 24 04 f0 fa 30 	movl   $0x30faf0,0x4(%esp)
  1009cf:	00 
  1009d0:	c7 04 24 76 5b 10 00 	movl   $0x105b76,(%esp)
  1009d7:	e8 00 48 00 00       	call   1051dc <cprintf>
	cprintf("&mem_pageinfo : 0x%x\n",&mem_pageinfo);
  1009dc:	c7 44 24 04 e4 f3 30 	movl   $0x30f3e4,0x4(%esp)
  1009e3:	00 
  1009e4:	c7 04 24 88 5b 10 00 	movl   $0x105b88,(%esp)
  1009eb:	e8 ec 47 00 00       	call   1051dc <cprintf>
	cprintf("&mem_freelist : 0x%x\n",&mem_freelist);
  1009f0:	c7 44 24 04 40 f3 10 	movl   $0x10f340,0x4(%esp)
  1009f7:	00 
  1009f8:	c7 04 24 9e 5b 10 00 	movl   $0x105b9e,(%esp)
  1009ff:	e8 d8 47 00 00       	call   1051dc <cprintf>
	cprintf("&tmp_paginfo : 0x%x\n",&tmp_mem_pageinfo);
  100a04:	c7 44 24 04 e0 f3 10 	movl   $0x10f3e0,0x4(%esp)
  100a0b:	00 
  100a0c:	c7 04 24 b4 5b 10 00 	movl   $0x105bb4,(%esp)
  100a13:	e8 c4 47 00 00       	call   1051dc <cprintf>
	if (!cpu_onboot())	// only do once, on the boot CPU
  100a18:	e8 55 ff ff ff       	call   100972 <cpu_onboot>
  100a1d:	85 c0                	test   %eax,%eax
  100a1f:	0f 84 bd 01 00 00    	je     100be2 <mem_init+0x258>
	// is available in the system (in bytes),
	// by reading the PC's BIOS-managed nonvolatile RAM (NVRAM).
	// The NVRAM tells us how many kilobytes there are.
	// Since the count is 16 bits, this gives us up to 64MB of RAM;
	// additional RAM beyond that would have to be detected another way.
	size_t basemem = ROUNDDOWN(nvram_read16(NVRAM_BASELO)*1024, PAGESIZE);
  100a25:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
  100a2c:	e8 99 3a 00 00       	call   1044ca <nvram_read16>
  100a31:	c1 e0 0a             	shl    $0xa,%eax
  100a34:	89 45 ec             	mov    %eax,-0x14(%ebp)
  100a37:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100a3a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100a3f:	89 45 e8             	mov    %eax,-0x18(%ebp)
	size_t extmem = ROUNDDOWN(nvram_read16(NVRAM_EXTLO)*1024, PAGESIZE);
  100a42:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
  100a49:	e8 7c 3a 00 00       	call   1044ca <nvram_read16>
  100a4e:	c1 e0 0a             	shl    $0xa,%eax
  100a51:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100a54:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100a57:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100a5c:	89 45 e0             	mov    %eax,-0x20(%ebp)
	cprintf("basemem : 0x%x\n", basemem);  // ->0xa0000 = 640K
  100a5f:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100a62:	89 44 24 04          	mov    %eax,0x4(%esp)
  100a66:	c7 04 24 c9 5b 10 00 	movl   $0x105bc9,(%esp)
  100a6d:	e8 6a 47 00 00       	call   1051dc <cprintf>
	cprintf("extmem : 0x%x\n", extmem);		// ->0xff000
  100a72:	8b 45 e0             	mov    -0x20(%ebp),%eax
  100a75:	89 44 24 04          	mov    %eax,0x4(%esp)
  100a79:	c7 04 24 d9 5b 10 00 	movl   $0x105bd9,(%esp)
  100a80:	e8 57 47 00 00       	call   1051dc <cprintf>
	warn("Assuming we have 1GB of memory!");
  100a85:	c7 44 24 08 e8 5b 10 	movl   $0x105be8,0x8(%esp)
  100a8c:	00 
  100a8d:	c7 44 24 04 3c 00 00 	movl   $0x3c,0x4(%esp)
  100a94:	00 
  100a95:	c7 04 24 08 5c 10 00 	movl   $0x105c08,(%esp)
  100a9c:	e8 e9 fa ff ff       	call   10058a <debug_warn>
	extmem = 1024*1024*1024 - MEM_EXT;	// assume 1GB total memory
  100aa1:	c7 45 e0 00 00 f0 3f 	movl   $0x3ff00000,-0x20(%ebp)

	// The maximum physical address is the top of extended memory.
	mem_max = MEM_EXT + extmem;
  100aa8:	8b 45 e0             	mov    -0x20(%ebp),%eax
  100aab:	05 00 00 10 00       	add    $0x100000,%eax
  100ab0:	a3 e0 f3 30 00       	mov    %eax,0x30f3e0

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;
  100ab5:	a1 e0 f3 30 00       	mov    0x30f3e0,%eax
  100aba:	c1 e8 0c             	shr    $0xc,%eax
  100abd:	a3 98 f3 10 00       	mov    %eax,0x10f398

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
  100ac2:	a1 e0 f3 30 00       	mov    0x30f3e0,%eax
  100ac7:	c1 e8 0a             	shr    $0xa,%eax
  100aca:	89 44 24 04          	mov    %eax,0x4(%esp)
  100ace:	c7 04 24 14 5c 10 00 	movl   $0x105c14,(%esp)
  100ad5:	e8 02 47 00 00       	call   1051dc <cprintf>
	cprintf("base = %dK, extended = %dK\n",
		(int)(basemem/1024), (int)(extmem/1024));
  100ada:	8b 45 e0             	mov    -0x20(%ebp),%eax
  100add:	c1 e8 0a             	shr    $0xa,%eax

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
	cprintf("base = %dK, extended = %dK\n",
  100ae0:	89 c2                	mov    %eax,%edx
		(int)(basemem/1024), (int)(extmem/1024));
  100ae2:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100ae5:	c1 e8 0a             	shr    $0xa,%eax

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
	cprintf("base = %dK, extended = %dK\n",
  100ae8:	89 54 24 08          	mov    %edx,0x8(%esp)
  100aec:	89 44 24 04          	mov    %eax,0x4(%esp)
  100af0:	c7 04 24 35 5c 10 00 	movl   $0x105c35,(%esp)
  100af7:	e8 e0 46 00 00       	call   1051dc <cprintf>
	//     but YOU decide where to place the pageinfo array.
	// Change the code to reflect this.
	//pageinfo *mem_pageinfo;
	//memset(mem_pageinfo, 0, sizeof(pageinfo)*mem_npage);

	pageinfo **freetail = &mem_freelist;
  100afc:	c7 45 f4 40 f3 10 00 	movl   $0x10f340,-0xc(%ebp)
	int i;
	uint32_t page_start;
	mem_pageinfo = tmp_mem_pageinfo;
  100b03:	c7 05 e4 f3 30 00 e0 	movl   $0x10f3e0,0x30f3e4
  100b0a:	f3 10 00 
	memset(tmp_mem_pageinfo, 0, sizeof(pageinfo)*1024*1024*1024/PAGESIZE);
  100b0d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  100b14:	00 
  100b15:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  100b1c:	00 
  100b1d:	c7 04 24 e0 f3 10 00 	movl   $0x10f3e0,(%esp)
  100b24:	e8 98 48 00 00       	call   1053c1 <memset>
	for (i = 0; i < mem_npage; i++) {
  100b29:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  100b30:	e9 92 00 00 00       	jmp    100bc7 <mem_init+0x23d>
		// A free page has no references to it.
		mem_pageinfo[i].refcount = 0;
  100b35:	a1 e4 f3 30 00       	mov    0x30f3e4,%eax
  100b3a:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100b3d:	c1 e2 03             	shl    $0x3,%edx
  100b40:	01 d0                	add    %edx,%eax
  100b42:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)

		//search free page
		//reserve page 0 and 1
		if(i == 0 || i == 1)
  100b49:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  100b4d:	74 6d                	je     100bbc <mem_init+0x232>
  100b4f:	83 7d f0 01          	cmpl   $0x1,-0x10(%ebp)
  100b53:	74 67                	je     100bbc <mem_init+0x232>
			continue;
		page_start = mem_pi2phys(mem_pageinfo + i);// get physical page addresses with pageinfo
  100b55:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100b58:	c1 e0 03             	shl    $0x3,%eax
  100b5b:	c1 f8 03             	sar    $0x3,%eax
  100b5e:	c1 e0 0c             	shl    $0xc,%eax
  100b61:	89 45 dc             	mov    %eax,-0x24(%ebp)

		//ignore[MEM_IO, MEM_EXT]
		if(page_start + PAGESIZE >= MEM_IO && page_start < MEM_EXT)
  100b64:	8b 45 dc             	mov    -0x24(%ebp),%eax
  100b67:	05 00 10 00 00       	add    $0x1000,%eax
  100b6c:	3d ff ff 09 00       	cmp    $0x9ffff,%eax
  100b71:	76 09                	jbe    100b7c <mem_init+0x1f2>
  100b73:	81 7d dc ff ff 0f 00 	cmpl   $0xfffff,-0x24(%ebp)
  100b7a:	76 43                	jbe    100bbf <mem_init+0x235>
			continue;

		//ignore[kernel]  -->([start,end])
		if(page_start + PAGESIZE >= (uint32_t)start && page_start < (uint32_t)end)
  100b7c:	8b 45 dc             	mov    -0x24(%ebp),%eax
  100b7f:	8d 90 00 10 00 00    	lea    0x1000(%eax),%edx
  100b85:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  100b8a:	39 c2                	cmp    %eax,%edx
  100b8c:	72 0a                	jb     100b98 <mem_init+0x20e>
  100b8e:	b8 f0 fa 30 00       	mov    $0x30faf0,%eax
  100b93:	39 45 dc             	cmp    %eax,-0x24(%ebp)
  100b96:	72 2a                	jb     100bc2 <mem_init+0x238>
			continue;

		// Add the page to the end of the free list.
		*freetail = &mem_pageinfo[i];
  100b98:	a1 e4 f3 30 00       	mov    0x30f3e4,%eax
  100b9d:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100ba0:	c1 e2 03             	shl    $0x3,%edx
  100ba3:	01 c2                	add    %eax,%edx
  100ba5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100ba8:	89 10                	mov    %edx,(%eax)
		freetail = &mem_pageinfo[i].free_next;
  100baa:	a1 e4 f3 30 00       	mov    0x30f3e4,%eax
  100baf:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100bb2:	c1 e2 03             	shl    $0x3,%edx
  100bb5:	01 d0                	add    %edx,%eax
  100bb7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  100bba:	eb 07                	jmp    100bc3 <mem_init+0x239>
		mem_pageinfo[i].refcount = 0;

		//search free page
		//reserve page 0 and 1
		if(i == 0 || i == 1)
			continue;
  100bbc:	90                   	nop
  100bbd:	eb 04                	jmp    100bc3 <mem_init+0x239>
		page_start = mem_pi2phys(mem_pageinfo + i);// get physical page addresses with pageinfo

		//ignore[MEM_IO, MEM_EXT]
		if(page_start + PAGESIZE >= MEM_IO && page_start < MEM_EXT)
			continue;
  100bbf:	90                   	nop
  100bc0:	eb 01                	jmp    100bc3 <mem_init+0x239>

		//ignore[kernel]  -->([start,end])
		if(page_start + PAGESIZE >= (uint32_t)start && page_start < (uint32_t)end)
			continue;
  100bc2:	90                   	nop
	pageinfo **freetail = &mem_freelist;
	int i;
	uint32_t page_start;
	mem_pageinfo = tmp_mem_pageinfo;
	memset(tmp_mem_pageinfo, 0, sizeof(pageinfo)*1024*1024*1024/PAGESIZE);
	for (i = 0; i < mem_npage; i++) {
  100bc3:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  100bc7:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100bca:	a1 98 f3 10 00       	mov    0x10f398,%eax
  100bcf:	39 c2                	cmp    %eax,%edx
  100bd1:	0f 82 5e ff ff ff    	jb     100b35 <mem_init+0x1ab>

		// Add the page to the end of the free list.
		*freetail = &mem_pageinfo[i];
		freetail = &mem_pageinfo[i].free_next;
	}
	*freetail = NULL;	// null-terminate the freelist
  100bd7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100bda:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  100be0:	eb 01                	jmp    100be3 <mem_init+0x259>
	cprintf("end : 0x%x, 0x%x\n",end, &end[0]);
	cprintf("&mem_pageinfo : 0x%x\n",&mem_pageinfo);
	cprintf("&mem_freelist : 0x%x\n",&mem_freelist);
	cprintf("&tmp_paginfo : 0x%x\n",&tmp_mem_pageinfo);
	if (!cpu_onboot())	// only do once, on the boot CPU
		return;
  100be2:	90                   	nop
	//panic("mem_init() not implemented");

	// Check to make sure the page allocator seems to work correctly.
	//mem_check();
	
}
  100be3:	c9                   	leave  
  100be4:	c3                   	ret    

00100be5 <mem_alloc>:
//
// Hint: pi->refs should not be incremented 
// Hint: be sure to use proper mutual exclusion for multiprocessor operation.
pageinfo *
mem_alloc(void)
{
  100be5:	55                   	push   %ebp
  100be6:	89 e5                	mov    %esp,%ebp
  100be8:	83 ec 28             	sub    $0x28,%esp
	//panic("mem_alloc not implemented.");
	if(!spinlock_holding(&_freelist_lock));
  100beb:	c7 04 24 a0 f3 10 00 	movl   $0x10f3a0,(%esp)
  100bf2:	e8 bb 1a 00 00       	call   1026b2 <spinlock_holding>
	spinlock_acquire(&_freelist_lock);
  100bf7:	c7 04 24 a0 f3 10 00 	movl   $0x10f3a0,(%esp)
  100bfe:	e8 d9 19 00 00       	call   1025dc <spinlock_acquire>
	pageinfo *p = mem_freelist;
  100c03:	a1 40 f3 10 00       	mov    0x10f340,%eax
  100c08:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if(p != NULL)
  100c0b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  100c0f:	74 0a                	je     100c1b <mem_alloc+0x36>
		mem_freelist = p->free_next;
  100c11:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100c14:	8b 00                	mov    (%eax),%eax
  100c16:	a3 40 f3 10 00       	mov    %eax,0x10f340
	spinlock_release(&_freelist_lock);
  100c1b:	c7 04 24 a0 f3 10 00 	movl   $0x10f3a0,(%esp)
  100c22:	e8 31 1a 00 00       	call   102658 <spinlock_release>
	return p;
  100c27:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  100c2a:	c9                   	leave  
  100c2b:	c3                   	ret    

00100c2c <mem_free>:
// Return a page to the free list, given its pageinfo pointer.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
mem_free(pageinfo *pi)
{
  100c2c:	55                   	push   %ebp
  100c2d:	89 e5                	mov    %esp,%ebp
  100c2f:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in.
	//panic("mem_free not implemented.");
	spinlock_acquire(&_freelist_lock);
  100c32:	c7 04 24 a0 f3 10 00 	movl   $0x10f3a0,(%esp)
  100c39:	e8 9e 19 00 00       	call   1025dc <spinlock_acquire>
	//assert(pi->refcount == 0);
	pi->free_next = mem_freelist;
  100c3e:	8b 15 40 f3 10 00    	mov    0x10f340,%edx
  100c44:	8b 45 08             	mov    0x8(%ebp),%eax
  100c47:	89 10                	mov    %edx,(%eax)
	mem_freelist = pi;
  100c49:	8b 45 08             	mov    0x8(%ebp),%eax
  100c4c:	a3 40 f3 10 00       	mov    %eax,0x10f340
	spinlock_release(&_freelist_lock);
  100c51:	c7 04 24 a0 f3 10 00 	movl   $0x10f3a0,(%esp)
  100c58:	e8 fb 19 00 00       	call   102658 <spinlock_release>
}
  100c5d:	c9                   	leave  
  100c5e:	c3                   	ret    

00100c5f <mem_check>:
// Check the physical page allocator (mem_alloc(), mem_free())
// for correct operation after initialization via mem_init().
//
void
mem_check()
{
  100c5f:	55                   	push   %ebp
  100c60:	89 e5                	mov    %esp,%ebp
  100c62:	83 ec 38             	sub    $0x38,%esp
	int i;

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
  100c65:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
  100c6c:	a1 40 f3 10 00       	mov    0x10f340,%eax
  100c71:	89 45 f4             	mov    %eax,-0xc(%ebp)
  100c74:	eb 38                	jmp    100cae <mem_check+0x4f>
		memset(mem_pi2ptr(pp), 0x97, 128);
  100c76:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100c79:	a1 e4 f3 30 00       	mov    0x30f3e4,%eax
  100c7e:	89 d1                	mov    %edx,%ecx
  100c80:	29 c1                	sub    %eax,%ecx
  100c82:	89 c8                	mov    %ecx,%eax
  100c84:	c1 f8 03             	sar    $0x3,%eax
  100c87:	c1 e0 0c             	shl    $0xc,%eax
  100c8a:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
  100c91:	00 
  100c92:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
  100c99:	00 
  100c9a:	89 04 24             	mov    %eax,(%esp)
  100c9d:	e8 1f 47 00 00       	call   1053c1 <memset>
		freepages++;
  100ca2:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
  100ca6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100ca9:	8b 00                	mov    (%eax),%eax
  100cab:	89 45 f4             	mov    %eax,-0xc(%ebp)
  100cae:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  100cb2:	75 c2                	jne    100c76 <mem_check+0x17>
		memset(mem_pi2ptr(pp), 0x97, 128);
		freepages++;
	}
	cprintf("mem_check: %d free pages\n", freepages);
  100cb4:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100cb7:	89 44 24 04          	mov    %eax,0x4(%esp)
  100cbb:	c7 04 24 51 5c 10 00 	movl   $0x105c51,(%esp)
  100cc2:	e8 15 45 00 00       	call   1051dc <cprintf>
	assert(freepages < mem_npage);	// can't have more free than total!
  100cc7:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100cca:	a1 98 f3 10 00       	mov    0x10f398,%eax
  100ccf:	39 c2                	cmp    %eax,%edx
  100cd1:	72 24                	jb     100cf7 <mem_check+0x98>
  100cd3:	c7 44 24 0c 6b 5c 10 	movl   $0x105c6b,0xc(%esp)
  100cda:	00 
  100cdb:	c7 44 24 08 32 5b 10 	movl   $0x105b32,0x8(%esp)
  100ce2:	00 
  100ce3:	c7 44 24 04 c3 00 00 	movl   $0xc3,0x4(%esp)
  100cea:	00 
  100ceb:	c7 04 24 08 5c 10 00 	movl   $0x105c08,(%esp)
  100cf2:	e8 cd f7 ff ff       	call   1004c4 <debug_panic>
	assert(freepages > 16000);	// make sure it's in the right ballpark
  100cf7:	81 7d f0 80 3e 00 00 	cmpl   $0x3e80,-0x10(%ebp)
  100cfe:	7f 24                	jg     100d24 <mem_check+0xc5>
  100d00:	c7 44 24 0c 81 5c 10 	movl   $0x105c81,0xc(%esp)
  100d07:	00 
  100d08:	c7 44 24 08 32 5b 10 	movl   $0x105b32,0x8(%esp)
  100d0f:	00 
  100d10:	c7 44 24 04 c4 00 00 	movl   $0xc4,0x4(%esp)
  100d17:	00 
  100d18:	c7 04 24 08 5c 10 00 	movl   $0x105c08,(%esp)
  100d1f:	e8 a0 f7 ff ff       	call   1004c4 <debug_panic>

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
  100d24:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  100d2b:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100d2e:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100d31:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100d34:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  100d37:	e8 a9 fe ff ff       	call   100be5 <mem_alloc>
  100d3c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100d3f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100d43:	75 24                	jne    100d69 <mem_check+0x10a>
  100d45:	c7 44 24 0c 93 5c 10 	movl   $0x105c93,0xc(%esp)
  100d4c:	00 
  100d4d:	c7 44 24 08 32 5b 10 	movl   $0x105b32,0x8(%esp)
  100d54:	00 
  100d55:	c7 44 24 04 c8 00 00 	movl   $0xc8,0x4(%esp)
  100d5c:	00 
  100d5d:	c7 04 24 08 5c 10 00 	movl   $0x105c08,(%esp)
  100d64:	e8 5b f7 ff ff       	call   1004c4 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100d69:	e8 77 fe ff ff       	call   100be5 <mem_alloc>
  100d6e:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100d71:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100d75:	75 24                	jne    100d9b <mem_check+0x13c>
  100d77:	c7 44 24 0c 9c 5c 10 	movl   $0x105c9c,0xc(%esp)
  100d7e:	00 
  100d7f:	c7 44 24 08 32 5b 10 	movl   $0x105b32,0x8(%esp)
  100d86:	00 
  100d87:	c7 44 24 04 c9 00 00 	movl   $0xc9,0x4(%esp)
  100d8e:	00 
  100d8f:	c7 04 24 08 5c 10 00 	movl   $0x105c08,(%esp)
  100d96:	e8 29 f7 ff ff       	call   1004c4 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100d9b:	e8 45 fe ff ff       	call   100be5 <mem_alloc>
  100da0:	89 45 ec             	mov    %eax,-0x14(%ebp)
  100da3:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  100da7:	75 24                	jne    100dcd <mem_check+0x16e>
  100da9:	c7 44 24 0c a5 5c 10 	movl   $0x105ca5,0xc(%esp)
  100db0:	00 
  100db1:	c7 44 24 08 32 5b 10 	movl   $0x105b32,0x8(%esp)
  100db8:	00 
  100db9:	c7 44 24 04 ca 00 00 	movl   $0xca,0x4(%esp)
  100dc0:	00 
  100dc1:	c7 04 24 08 5c 10 00 	movl   $0x105c08,(%esp)
  100dc8:	e8 f7 f6 ff ff       	call   1004c4 <debug_panic>

	assert(pp0);
  100dcd:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100dd1:	75 24                	jne    100df7 <mem_check+0x198>
  100dd3:	c7 44 24 0c ae 5c 10 	movl   $0x105cae,0xc(%esp)
  100dda:	00 
  100ddb:	c7 44 24 08 32 5b 10 	movl   $0x105b32,0x8(%esp)
  100de2:	00 
  100de3:	c7 44 24 04 cc 00 00 	movl   $0xcc,0x4(%esp)
  100dea:	00 
  100deb:	c7 04 24 08 5c 10 00 	movl   $0x105c08,(%esp)
  100df2:	e8 cd f6 ff ff       	call   1004c4 <debug_panic>
	assert(pp1 && pp1 != pp0);
  100df7:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100dfb:	74 08                	je     100e05 <mem_check+0x1a6>
  100dfd:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100e00:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  100e03:	75 24                	jne    100e29 <mem_check+0x1ca>
  100e05:	c7 44 24 0c b2 5c 10 	movl   $0x105cb2,0xc(%esp)
  100e0c:	00 
  100e0d:	c7 44 24 08 32 5b 10 	movl   $0x105b32,0x8(%esp)
  100e14:	00 
  100e15:	c7 44 24 04 cd 00 00 	movl   $0xcd,0x4(%esp)
  100e1c:	00 
  100e1d:	c7 04 24 08 5c 10 00 	movl   $0x105c08,(%esp)
  100e24:	e8 9b f6 ff ff       	call   1004c4 <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  100e29:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  100e2d:	74 10                	je     100e3f <mem_check+0x1e0>
  100e2f:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100e32:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  100e35:	74 08                	je     100e3f <mem_check+0x1e0>
  100e37:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100e3a:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  100e3d:	75 24                	jne    100e63 <mem_check+0x204>
  100e3f:	c7 44 24 0c c4 5c 10 	movl   $0x105cc4,0xc(%esp)
  100e46:	00 
  100e47:	c7 44 24 08 32 5b 10 	movl   $0x105b32,0x8(%esp)
  100e4e:	00 
  100e4f:	c7 44 24 04 ce 00 00 	movl   $0xce,0x4(%esp)
  100e56:	00 
  100e57:	c7 04 24 08 5c 10 00 	movl   $0x105c08,(%esp)
  100e5e:	e8 61 f6 ff ff       	call   1004c4 <debug_panic>
        assert(mem_pi2phys(pp0) < mem_npage*PAGESIZE);
  100e63:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  100e66:	a1 e4 f3 30 00       	mov    0x30f3e4,%eax
  100e6b:	89 d1                	mov    %edx,%ecx
  100e6d:	29 c1                	sub    %eax,%ecx
  100e6f:	89 c8                	mov    %ecx,%eax
  100e71:	c1 f8 03             	sar    $0x3,%eax
  100e74:	c1 e0 0c             	shl    $0xc,%eax
  100e77:	8b 15 98 f3 10 00    	mov    0x10f398,%edx
  100e7d:	c1 e2 0c             	shl    $0xc,%edx
  100e80:	39 d0                	cmp    %edx,%eax
  100e82:	72 24                	jb     100ea8 <mem_check+0x249>
  100e84:	c7 44 24 0c e4 5c 10 	movl   $0x105ce4,0xc(%esp)
  100e8b:	00 
  100e8c:	c7 44 24 08 32 5b 10 	movl   $0x105b32,0x8(%esp)
  100e93:	00 
  100e94:	c7 44 24 04 cf 00 00 	movl   $0xcf,0x4(%esp)
  100e9b:	00 
  100e9c:	c7 04 24 08 5c 10 00 	movl   $0x105c08,(%esp)
  100ea3:	e8 1c f6 ff ff       	call   1004c4 <debug_panic>
        assert(mem_pi2phys(pp1) < mem_npage*PAGESIZE);
  100ea8:	8b 55 e8             	mov    -0x18(%ebp),%edx
  100eab:	a1 e4 f3 30 00       	mov    0x30f3e4,%eax
  100eb0:	89 d1                	mov    %edx,%ecx
  100eb2:	29 c1                	sub    %eax,%ecx
  100eb4:	89 c8                	mov    %ecx,%eax
  100eb6:	c1 f8 03             	sar    $0x3,%eax
  100eb9:	c1 e0 0c             	shl    $0xc,%eax
  100ebc:	8b 15 98 f3 10 00    	mov    0x10f398,%edx
  100ec2:	c1 e2 0c             	shl    $0xc,%edx
  100ec5:	39 d0                	cmp    %edx,%eax
  100ec7:	72 24                	jb     100eed <mem_check+0x28e>
  100ec9:	c7 44 24 0c 0c 5d 10 	movl   $0x105d0c,0xc(%esp)
  100ed0:	00 
  100ed1:	c7 44 24 08 32 5b 10 	movl   $0x105b32,0x8(%esp)
  100ed8:	00 
  100ed9:	c7 44 24 04 d0 00 00 	movl   $0xd0,0x4(%esp)
  100ee0:	00 
  100ee1:	c7 04 24 08 5c 10 00 	movl   $0x105c08,(%esp)
  100ee8:	e8 d7 f5 ff ff       	call   1004c4 <debug_panic>
        assert(mem_pi2phys(pp2) < mem_npage*PAGESIZE);
  100eed:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100ef0:	a1 e4 f3 30 00       	mov    0x30f3e4,%eax
  100ef5:	89 d1                	mov    %edx,%ecx
  100ef7:	29 c1                	sub    %eax,%ecx
  100ef9:	89 c8                	mov    %ecx,%eax
  100efb:	c1 f8 03             	sar    $0x3,%eax
  100efe:	c1 e0 0c             	shl    $0xc,%eax
  100f01:	8b 15 98 f3 10 00    	mov    0x10f398,%edx
  100f07:	c1 e2 0c             	shl    $0xc,%edx
  100f0a:	39 d0                	cmp    %edx,%eax
  100f0c:	72 24                	jb     100f32 <mem_check+0x2d3>
  100f0e:	c7 44 24 0c 34 5d 10 	movl   $0x105d34,0xc(%esp)
  100f15:	00 
  100f16:	c7 44 24 08 32 5b 10 	movl   $0x105b32,0x8(%esp)
  100f1d:	00 
  100f1e:	c7 44 24 04 d1 00 00 	movl   $0xd1,0x4(%esp)
  100f25:	00 
  100f26:	c7 04 24 08 5c 10 00 	movl   $0x105c08,(%esp)
  100f2d:	e8 92 f5 ff ff       	call   1004c4 <debug_panic>

	// temporarily steal the rest of the free pages
	fl = mem_freelist;
  100f32:	a1 40 f3 10 00       	mov    0x10f340,%eax
  100f37:	89 45 e0             	mov    %eax,-0x20(%ebp)
	mem_freelist = 0;
  100f3a:	c7 05 40 f3 10 00 00 	movl   $0x0,0x10f340
  100f41:	00 00 00 

	// should be no free memory
	assert(mem_alloc() == 0);
  100f44:	e8 9c fc ff ff       	call   100be5 <mem_alloc>
  100f49:	85 c0                	test   %eax,%eax
  100f4b:	74 24                	je     100f71 <mem_check+0x312>
  100f4d:	c7 44 24 0c 5a 5d 10 	movl   $0x105d5a,0xc(%esp)
  100f54:	00 
  100f55:	c7 44 24 08 32 5b 10 	movl   $0x105b32,0x8(%esp)
  100f5c:	00 
  100f5d:	c7 44 24 04 d8 00 00 	movl   $0xd8,0x4(%esp)
  100f64:	00 
  100f65:	c7 04 24 08 5c 10 00 	movl   $0x105c08,(%esp)
  100f6c:	e8 53 f5 ff ff       	call   1004c4 <debug_panic>

        // free and re-allocate?
        mem_free(pp0);
  100f71:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100f74:	89 04 24             	mov    %eax,(%esp)
  100f77:	e8 b0 fc ff ff       	call   100c2c <mem_free>
        mem_free(pp1);
  100f7c:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100f7f:	89 04 24             	mov    %eax,(%esp)
  100f82:	e8 a5 fc ff ff       	call   100c2c <mem_free>
        mem_free(pp2);
  100f87:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100f8a:	89 04 24             	mov    %eax,(%esp)
  100f8d:	e8 9a fc ff ff       	call   100c2c <mem_free>
	pp0 = pp1 = pp2 = 0;
  100f92:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  100f99:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100f9c:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100f9f:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100fa2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  100fa5:	e8 3b fc ff ff       	call   100be5 <mem_alloc>
  100faa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100fad:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100fb1:	75 24                	jne    100fd7 <mem_check+0x378>
  100fb3:	c7 44 24 0c 93 5c 10 	movl   $0x105c93,0xc(%esp)
  100fba:	00 
  100fbb:	c7 44 24 08 32 5b 10 	movl   $0x105b32,0x8(%esp)
  100fc2:	00 
  100fc3:	c7 44 24 04 df 00 00 	movl   $0xdf,0x4(%esp)
  100fca:	00 
  100fcb:	c7 04 24 08 5c 10 00 	movl   $0x105c08,(%esp)
  100fd2:	e8 ed f4 ff ff       	call   1004c4 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100fd7:	e8 09 fc ff ff       	call   100be5 <mem_alloc>
  100fdc:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100fdf:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100fe3:	75 24                	jne    101009 <mem_check+0x3aa>
  100fe5:	c7 44 24 0c 9c 5c 10 	movl   $0x105c9c,0xc(%esp)
  100fec:	00 
  100fed:	c7 44 24 08 32 5b 10 	movl   $0x105b32,0x8(%esp)
  100ff4:	00 
  100ff5:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
  100ffc:	00 
  100ffd:	c7 04 24 08 5c 10 00 	movl   $0x105c08,(%esp)
  101004:	e8 bb f4 ff ff       	call   1004c4 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  101009:	e8 d7 fb ff ff       	call   100be5 <mem_alloc>
  10100e:	89 45 ec             	mov    %eax,-0x14(%ebp)
  101011:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  101015:	75 24                	jne    10103b <mem_check+0x3dc>
  101017:	c7 44 24 0c a5 5c 10 	movl   $0x105ca5,0xc(%esp)
  10101e:	00 
  10101f:	c7 44 24 08 32 5b 10 	movl   $0x105b32,0x8(%esp)
  101026:	00 
  101027:	c7 44 24 04 e1 00 00 	movl   $0xe1,0x4(%esp)
  10102e:	00 
  10102f:	c7 04 24 08 5c 10 00 	movl   $0x105c08,(%esp)
  101036:	e8 89 f4 ff ff       	call   1004c4 <debug_panic>
	assert(pp0);
  10103b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  10103f:	75 24                	jne    101065 <mem_check+0x406>
  101041:	c7 44 24 0c ae 5c 10 	movl   $0x105cae,0xc(%esp)
  101048:	00 
  101049:	c7 44 24 08 32 5b 10 	movl   $0x105b32,0x8(%esp)
  101050:	00 
  101051:	c7 44 24 04 e2 00 00 	movl   $0xe2,0x4(%esp)
  101058:	00 
  101059:	c7 04 24 08 5c 10 00 	movl   $0x105c08,(%esp)
  101060:	e8 5f f4 ff ff       	call   1004c4 <debug_panic>
	assert(pp1 && pp1 != pp0);
  101065:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  101069:	74 08                	je     101073 <mem_check+0x414>
  10106b:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10106e:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  101071:	75 24                	jne    101097 <mem_check+0x438>
  101073:	c7 44 24 0c b2 5c 10 	movl   $0x105cb2,0xc(%esp)
  10107a:	00 
  10107b:	c7 44 24 08 32 5b 10 	movl   $0x105b32,0x8(%esp)
  101082:	00 
  101083:	c7 44 24 04 e3 00 00 	movl   $0xe3,0x4(%esp)
  10108a:	00 
  10108b:	c7 04 24 08 5c 10 00 	movl   $0x105c08,(%esp)
  101092:	e8 2d f4 ff ff       	call   1004c4 <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  101097:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  10109b:	74 10                	je     1010ad <mem_check+0x44e>
  10109d:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1010a0:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  1010a3:	74 08                	je     1010ad <mem_check+0x44e>
  1010a5:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1010a8:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  1010ab:	75 24                	jne    1010d1 <mem_check+0x472>
  1010ad:	c7 44 24 0c c4 5c 10 	movl   $0x105cc4,0xc(%esp)
  1010b4:	00 
  1010b5:	c7 44 24 08 32 5b 10 	movl   $0x105b32,0x8(%esp)
  1010bc:	00 
  1010bd:	c7 44 24 04 e4 00 00 	movl   $0xe4,0x4(%esp)
  1010c4:	00 
  1010c5:	c7 04 24 08 5c 10 00 	movl   $0x105c08,(%esp)
  1010cc:	e8 f3 f3 ff ff       	call   1004c4 <debug_panic>
	assert(mem_alloc() == 0);
  1010d1:	e8 0f fb ff ff       	call   100be5 <mem_alloc>
  1010d6:	85 c0                	test   %eax,%eax
  1010d8:	74 24                	je     1010fe <mem_check+0x49f>
  1010da:	c7 44 24 0c 5a 5d 10 	movl   $0x105d5a,0xc(%esp)
  1010e1:	00 
  1010e2:	c7 44 24 08 32 5b 10 	movl   $0x105b32,0x8(%esp)
  1010e9:	00 
  1010ea:	c7 44 24 04 e5 00 00 	movl   $0xe5,0x4(%esp)
  1010f1:	00 
  1010f2:	c7 04 24 08 5c 10 00 	movl   $0x105c08,(%esp)
  1010f9:	e8 c6 f3 ff ff       	call   1004c4 <debug_panic>

	// give free list back
	mem_freelist = fl;
  1010fe:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101101:	a3 40 f3 10 00       	mov    %eax,0x10f340

	// free the pages we took
	mem_free(pp0);
  101106:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  101109:	89 04 24             	mov    %eax,(%esp)
  10110c:	e8 1b fb ff ff       	call   100c2c <mem_free>
	mem_free(pp1);
  101111:	8b 45 e8             	mov    -0x18(%ebp),%eax
  101114:	89 04 24             	mov    %eax,(%esp)
  101117:	e8 10 fb ff ff       	call   100c2c <mem_free>
	mem_free(pp2);
  10111c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10111f:	89 04 24             	mov    %eax,(%esp)
  101122:	e8 05 fb ff ff       	call   100c2c <mem_free>

	cprintf("mem_check() succeeded!\n");
  101127:	c7 04 24 6b 5d 10 00 	movl   $0x105d6b,(%esp)
  10112e:	e8 a9 40 00 00       	call   1051dc <cprintf>
}
  101133:	c9                   	leave  
  101134:	c3                   	ret    
  101135:	90                   	nop
  101136:	90                   	nop
  101137:	90                   	nop

00101138 <xchg>:
}

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  101138:	55                   	push   %ebp
  101139:	89 e5                	mov    %esp,%ebp
  10113b:	53                   	push   %ebx
  10113c:	83 ec 10             	sub    $0x10,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
	       "+m" (*addr), "=a" (result) :
  10113f:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  101142:	8b 45 0c             	mov    0xc(%ebp),%eax
	       "+m" (*addr), "=a" (result) :
  101145:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  101148:	89 c3                	mov    %eax,%ebx
  10114a:	89 d8                	mov    %ebx,%eax
  10114c:	f0 87 02             	lock xchg %eax,(%edx)
  10114f:	89 c3                	mov    %eax,%ebx
  101151:	89 5d f8             	mov    %ebx,-0x8(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  101154:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
  101157:	83 c4 10             	add    $0x10,%esp
  10115a:	5b                   	pop    %ebx
  10115b:	5d                   	pop    %ebp
  10115c:	c3                   	ret    

0010115d <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  10115d:	55                   	push   %ebp
  10115e:	89 e5                	mov    %esp,%ebp
  101160:	53                   	push   %ebx
  101161:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  101164:	89 e3                	mov    %esp,%ebx
  101166:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  101169:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  10116c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10116f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101172:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  101177:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  10117a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10117d:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  101183:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  101188:	74 24                	je     1011ae <cpu_cur+0x51>
  10118a:	c7 44 24 0c 83 5d 10 	movl   $0x105d83,0xc(%esp)
  101191:	00 
  101192:	c7 44 24 08 99 5d 10 	movl   $0x105d99,0x8(%esp)
  101199:	00 
  10119a:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1011a1:	00 
  1011a2:	c7 04 24 ae 5d 10 00 	movl   $0x105dae,(%esp)
  1011a9:	e8 16 f3 ff ff       	call   1004c4 <debug_panic>
	return c;
  1011ae:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  1011b1:	83 c4 24             	add    $0x24,%esp
  1011b4:	5b                   	pop    %ebx
  1011b5:	5d                   	pop    %ebp
  1011b6:	c3                   	ret    

001011b7 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  1011b7:	55                   	push   %ebp
  1011b8:	89 e5                	mov    %esp,%ebp
  1011ba:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  1011bd:	e8 9b ff ff ff       	call   10115d <cpu_cur>
  1011c2:	3d 00 80 10 00       	cmp    $0x108000,%eax
  1011c7:	0f 94 c0             	sete   %al
  1011ca:	0f b6 c0             	movzbl %al,%eax
}
  1011cd:	c9                   	leave  
  1011ce:	c3                   	ret    

001011cf <cpu_init>:
	magic: CPU_MAGIC
};


void cpu_init()
{
  1011cf:	55                   	push   %ebp
  1011d0:	89 e5                	mov    %esp,%ebp
  1011d2:	53                   	push   %ebx
  1011d3:	83 ec 14             	sub    $0x14,%esp
	cpu *c = cpu_cur();
  1011d6:	e8 82 ff ff ff       	call   10115d <cpu_cur>
  1011db:	89 45 f4             	mov    %eax,-0xc(%ebp)

	c->gdt[CPU_GDT_TSS >> 3] = SEGDESC16(0, STS_T32A, (uint32_t)(&c->tss), sizeof(c->tss)-1, 0);
  1011de:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1011e1:	83 c0 38             	add    $0x38,%eax
  1011e4:	89 c3                	mov    %eax,%ebx
  1011e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1011e9:	83 c0 38             	add    $0x38,%eax
  1011ec:	c1 e8 10             	shr    $0x10,%eax
  1011ef:	89 c1                	mov    %eax,%ecx
  1011f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1011f4:	83 c0 38             	add    $0x38,%eax
  1011f7:	c1 e8 18             	shr    $0x18,%eax
  1011fa:	89 c2                	mov    %eax,%edx
  1011fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1011ff:	66 c7 40 30 67 00    	movw   $0x67,0x30(%eax)
  101205:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101208:	66 89 58 32          	mov    %bx,0x32(%eax)
  10120c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10120f:	88 48 34             	mov    %cl,0x34(%eax)
  101212:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101215:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  101219:	83 e1 f0             	and    $0xfffffff0,%ecx
  10121c:	83 c9 09             	or     $0x9,%ecx
  10121f:	88 48 35             	mov    %cl,0x35(%eax)
  101222:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101225:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  101229:	83 e1 ef             	and    $0xffffffef,%ecx
  10122c:	88 48 35             	mov    %cl,0x35(%eax)
  10122f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101232:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  101236:	83 e1 9f             	and    $0xffffff9f,%ecx
  101239:	88 48 35             	mov    %cl,0x35(%eax)
  10123c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10123f:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  101243:	83 c9 80             	or     $0xffffff80,%ecx
  101246:	88 48 35             	mov    %cl,0x35(%eax)
  101249:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10124c:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  101250:	83 e1 f0             	and    $0xfffffff0,%ecx
  101253:	88 48 36             	mov    %cl,0x36(%eax)
  101256:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101259:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  10125d:	83 e1 ef             	and    $0xffffffef,%ecx
  101260:	88 48 36             	mov    %cl,0x36(%eax)
  101263:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101266:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  10126a:	83 e1 df             	and    $0xffffffdf,%ecx
  10126d:	88 48 36             	mov    %cl,0x36(%eax)
  101270:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101273:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  101277:	83 c9 40             	or     $0x40,%ecx
  10127a:	88 48 36             	mov    %cl,0x36(%eax)
  10127d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101280:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  101284:	83 e1 7f             	and    $0x7f,%ecx
  101287:	88 48 36             	mov    %cl,0x36(%eax)
  10128a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10128d:	88 50 37             	mov    %dl,0x37(%eax)
	c->tss.ts_esp0 = (uint32_t)c->kstackhi;
  101290:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101293:	05 00 10 00 00       	add    $0x1000,%eax
  101298:	89 c2                	mov    %eax,%edx
  10129a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10129d:	89 50 3c             	mov    %edx,0x3c(%eax)
	c->tss.ts_ss0 = CPU_GDT_KDATA;
  1012a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1012a3:	66 c7 40 40 10 00    	movw   $0x10,0x40(%eax)

	// Load the GDT
	struct pseudodesc gdt_pd = {
  1012a9:	66 c7 45 ec 37 00    	movw   $0x37,-0x14(%ebp)
		sizeof(c->gdt) - 1, (uint32_t) c->gdt };
  1012af:	8b 45 f4             	mov    -0xc(%ebp),%eax
	c->gdt[CPU_GDT_TSS >> 3] = SEGDESC16(0, STS_T32A, (uint32_t)(&c->tss), sizeof(c->tss)-1, 0);
	c->tss.ts_esp0 = (uint32_t)c->kstackhi;
	c->tss.ts_ss0 = CPU_GDT_KDATA;

	// Load the GDT
	struct pseudodesc gdt_pd = {
  1012b2:	89 45 ee             	mov    %eax,-0x12(%ebp)
		sizeof(c->gdt) - 1, (uint32_t) c->gdt };
	asm volatile("lgdt %0" : : "m" (gdt_pd));
  1012b5:	0f 01 55 ec          	lgdtl  -0x14(%ebp)

	// Reload all segment registers.
	asm volatile("movw %%ax,%%gs" :: "a" (CPU_GDT_UDATA|3));
  1012b9:	b8 23 00 00 00       	mov    $0x23,%eax
  1012be:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (CPU_GDT_UDATA|3));
  1012c0:	b8 23 00 00 00       	mov    $0x23,%eax
  1012c5:	8e e0                	mov    %eax,%fs
	asm volatile("movw %%ax,%%es" :: "a" (CPU_GDT_KDATA));
  1012c7:	b8 10 00 00 00       	mov    $0x10,%eax
  1012cc:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (CPU_GDT_KDATA));
  1012ce:	b8 10 00 00 00       	mov    $0x10,%eax
  1012d3:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (CPU_GDT_KDATA));
  1012d5:	b8 10 00 00 00       	mov    $0x10,%eax
  1012da:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (CPU_GDT_KCODE)); // reload CS
  1012dc:	ea e3 12 10 00 08 00 	ljmp   $0x8,$0x1012e3

	// We don't need an LDT.
	asm volatile("lldt %%ax" :: "a" (0));
  1012e3:	b8 00 00 00 00       	mov    $0x0,%eax
  1012e8:	0f 00 d0             	lldt   %ax
  1012eb:	66 c7 45 f2 30 00    	movw   $0x30,-0xe(%ebp)
}

static gcc_inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
  1012f1:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
  1012f5:	0f 00 d8             	ltr    %ax

	ltr(CPU_GDT_TSS);
}
  1012f8:	83 c4 14             	add    $0x14,%esp
  1012fb:	5b                   	pop    %ebx
  1012fc:	5d                   	pop    %ebp
  1012fd:	c3                   	ret    

001012fe <cpu_alloc>:

// Allocate an additional cpu struct representing a non-bootstrap processor.
cpu *
cpu_alloc(void)
{
  1012fe:	55                   	push   %ebp
  1012ff:	89 e5                	mov    %esp,%ebp
  101301:	83 ec 28             	sub    $0x28,%esp
	// Pointer to the cpu.next pointer of the last CPU on the list,
	// for chaining on new CPUs in cpu_alloc().  Note: static.
	static cpu **cpu_tail = &cpu_boot.next;

	pageinfo *pi = mem_alloc();
  101304:	e8 dc f8 ff ff       	call   100be5 <mem_alloc>
  101309:	89 45 f4             	mov    %eax,-0xc(%ebp)
	assert(pi != 0);	// shouldn't be out of memory just yet!
  10130c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  101310:	75 24                	jne    101336 <cpu_alloc+0x38>
  101312:	c7 44 24 0c bb 5d 10 	movl   $0x105dbb,0xc(%esp)
  101319:	00 
  10131a:	c7 44 24 08 99 5d 10 	movl   $0x105d99,0x8(%esp)
  101321:	00 
  101322:	c7 44 24 04 5b 00 00 	movl   $0x5b,0x4(%esp)
  101329:	00 
  10132a:	c7 04 24 c3 5d 10 00 	movl   $0x105dc3,(%esp)
  101331:	e8 8e f1 ff ff       	call   1004c4 <debug_panic>

	cpu *c = (cpu*) mem_pi2ptr(pi);
  101336:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101339:	a1 e4 f3 30 00       	mov    0x30f3e4,%eax
  10133e:	89 d1                	mov    %edx,%ecx
  101340:	29 c1                	sub    %eax,%ecx
  101342:	89 c8                	mov    %ecx,%eax
  101344:	c1 f8 03             	sar    $0x3,%eax
  101347:	c1 e0 0c             	shl    $0xc,%eax
  10134a:	89 45 f0             	mov    %eax,-0x10(%ebp)

	// Clear the whole page for good measure: cpu struct and kernel stack
	memset(c, 0, PAGESIZE);
  10134d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  101354:	00 
  101355:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10135c:	00 
  10135d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101360:	89 04 24             	mov    %eax,(%esp)
  101363:	e8 59 40 00 00       	call   1053c1 <memset>
	// when it starts up and calls cpu_init().

	// Initialize the new cpu's GDT by copying from the cpu_boot.
	// The TSS descriptor will be filled in later by cpu_init().
	assert(sizeof(c->gdt) == sizeof(segdesc) * CPU_GDT_NDESC);
	memmove(c->gdt, cpu_boot.gdt, sizeof(c->gdt));
  101368:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10136b:	c7 44 24 08 38 00 00 	movl   $0x38,0x8(%esp)
  101372:	00 
  101373:	c7 44 24 04 00 80 10 	movl   $0x108000,0x4(%esp)
  10137a:	00 
  10137b:	89 04 24             	mov    %eax,(%esp)
  10137e:	e8 ac 40 00 00       	call   10542f <memmove>

	// Magic verification tag for stack overflow/cpu corruption checking
	c->magic = CPU_MAGIC;
  101383:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101386:	c7 80 b8 00 00 00 32 	movl   $0x98765432,0xb8(%eax)
  10138d:	54 76 98 

	// Chain the new CPU onto the tail of the list.
	*cpu_tail = c;
  101390:	a1 00 90 10 00       	mov    0x109000,%eax
  101395:	8b 55 f0             	mov    -0x10(%ebp),%edx
  101398:	89 10                	mov    %edx,(%eax)
	cpu_tail = &c->next;
  10139a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10139d:	05 a8 00 00 00       	add    $0xa8,%eax
  1013a2:	a3 00 90 10 00       	mov    %eax,0x109000

	return c;
  1013a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  1013aa:	c9                   	leave  
  1013ab:	c3                   	ret    

001013ac <cpu_bootothers>:

void
cpu_bootothers(void)
{
  1013ac:	55                   	push   %ebp
  1013ad:	89 e5                	mov    %esp,%ebp
  1013af:	83 ec 28             	sub    $0x28,%esp
	extern uint8_t _binary_obj_boot_bootother_start[],
			_binary_obj_boot_bootother_size[];

	if (!cpu_onboot()) {
  1013b2:	e8 00 fe ff ff       	call   1011b7 <cpu_onboot>
  1013b7:	85 c0                	test   %eax,%eax
  1013b9:	75 1f                	jne    1013da <cpu_bootothers+0x2e>
		// Just inform the boot cpu we've booted.
		xchg(&cpu_cur()->booted, 1);
  1013bb:	e8 9d fd ff ff       	call   10115d <cpu_cur>
  1013c0:	05 b0 00 00 00       	add    $0xb0,%eax
  1013c5:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1013cc:	00 
  1013cd:	89 04 24             	mov    %eax,(%esp)
  1013d0:	e8 63 fd ff ff       	call   101138 <xchg>
		return;
  1013d5:	e9 92 00 00 00       	jmp    10146c <cpu_bootothers+0xc0>
	}

	// Write bootstrap code to unused memory at 0x1000.
	uint8_t *code = (uint8_t*)0x1000;
  1013da:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
	memmove(code, _binary_obj_boot_bootother_start,
  1013e1:	b8 6a 00 00 00       	mov    $0x6a,%eax
  1013e6:	89 44 24 08          	mov    %eax,0x8(%esp)
  1013ea:	c7 44 24 04 f4 95 10 	movl   $0x1095f4,0x4(%esp)
  1013f1:	00 
  1013f2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1013f5:	89 04 24             	mov    %eax,(%esp)
  1013f8:	e8 32 40 00 00       	call   10542f <memmove>
		(uint32_t)_binary_obj_boot_bootother_size);

	cpu *c;
	for(c = &cpu_boot; c; c = c->next){
  1013fd:	c7 45 f4 00 80 10 00 	movl   $0x108000,-0xc(%ebp)
  101404:	eb 60                	jmp    101466 <cpu_bootothers+0xba>
		if(c == cpu_cur())  // We''ve started already.
  101406:	e8 52 fd ff ff       	call   10115d <cpu_cur>
  10140b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  10140e:	74 49                	je     101459 <cpu_bootothers+0xad>
			continue;

		// Fill in %esp, %eip and start code on cpu.
		*(void**)(code-4) = c->kstackhi;
  101410:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101413:	83 e8 04             	sub    $0x4,%eax
  101416:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101419:	81 c2 00 10 00 00    	add    $0x1000,%edx
  10141f:	89 10                	mov    %edx,(%eax)
		*(void**)(code-8) = init;
  101421:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101424:	83 e8 08             	sub    $0x8,%eax
  101427:	c7 00 9a 00 10 00    	movl   $0x10009a,(%eax)
		lapic_startcpu(c->id, (uint32_t)code);
  10142d:	8b 55 f0             	mov    -0x10(%ebp),%edx
  101430:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101433:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  10143a:	0f b6 c0             	movzbl %al,%eax
  10143d:	89 54 24 04          	mov    %edx,0x4(%esp)
  101441:	89 04 24             	mov    %eax,(%esp)
  101444:	e8 8a 33 00 00       	call   1047d3 <lapic_startcpu>

		// Wait for cpu to get through bootstrap.
		while(c->booted == 0)
  101449:	90                   	nop
  10144a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10144d:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
  101453:	85 c0                	test   %eax,%eax
  101455:	74 f3                	je     10144a <cpu_bootothers+0x9e>
  101457:	eb 01                	jmp    10145a <cpu_bootothers+0xae>
		(uint32_t)_binary_obj_boot_bootother_size);

	cpu *c;
	for(c = &cpu_boot; c; c = c->next){
		if(c == cpu_cur())  // We''ve started already.
			continue;
  101459:	90                   	nop
	uint8_t *code = (uint8_t*)0x1000;
	memmove(code, _binary_obj_boot_bootother_start,
		(uint32_t)_binary_obj_boot_bootother_size);

	cpu *c;
	for(c = &cpu_boot; c; c = c->next){
  10145a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10145d:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  101463:	89 45 f4             	mov    %eax,-0xc(%ebp)
  101466:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  10146a:	75 9a                	jne    101406 <cpu_bootothers+0x5a>

		// Wait for cpu to get through bootstrap.
		while(c->booted == 0)
			;
	}
}
  10146c:	c9                   	leave  
  10146d:	c3                   	ret    
  10146e:	90                   	nop
  10146f:	90                   	nop

00101470 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  101470:	55                   	push   %ebp
  101471:	89 e5                	mov    %esp,%ebp
  101473:	53                   	push   %ebx
  101474:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  101477:	89 e3                	mov    %esp,%ebx
  101479:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  10147c:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  10147f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  101482:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101485:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10148a:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  10148d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101490:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  101496:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  10149b:	74 24                	je     1014c1 <cpu_cur+0x51>
  10149d:	c7 44 24 0c e0 5d 10 	movl   $0x105de0,0xc(%esp)
  1014a4:	00 
  1014a5:	c7 44 24 08 f6 5d 10 	movl   $0x105df6,0x8(%esp)
  1014ac:	00 
  1014ad:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1014b4:	00 
  1014b5:	c7 04 24 0b 5e 10 00 	movl   $0x105e0b,(%esp)
  1014bc:	e8 03 f0 ff ff       	call   1004c4 <debug_panic>
	return c;
  1014c1:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  1014c4:	83 c4 24             	add    $0x24,%esp
  1014c7:	5b                   	pop    %ebx
  1014c8:	5d                   	pop    %ebp
  1014c9:	c3                   	ret    

001014ca <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  1014ca:	55                   	push   %ebp
  1014cb:	89 e5                	mov    %esp,%ebp
  1014cd:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  1014d0:	e8 9b ff ff ff       	call   101470 <cpu_cur>
  1014d5:	3d 00 80 10 00       	cmp    $0x108000,%eax
  1014da:	0f 94 c0             	sete   %al
  1014dd:	0f b6 c0             	movzbl %al,%eax
}
  1014e0:	c9                   	leave  
  1014e1:	c3                   	ret    

001014e2 <trap_init_idt>:
extern int vectors[];


static void
trap_init_idt(void)
{
  1014e2:	55                   	push   %ebp
  1014e3:	89 e5                	mov    %esp,%ebp
  1014e5:	83 ec 10             	sub    $0x10,%esp
	extern segdesc gdt[];

	//panic("trap_init() not implemented.");

	int i;
	for (i=0; i<501; i++) {
  1014e8:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  1014ef:	e9 c3 00 00 00       	jmp    1015b7 <trap_init_idt+0xd5>
		SETGATE(idt[i], 0, CPU_GDT_KCODE, vectors[i], 0); //CPU_GDT_KCODE is 0x08
  1014f4:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1014f7:	8b 04 85 0c 90 10 00 	mov    0x10900c(,%eax,4),%eax
  1014fe:	89 c2                	mov    %eax,%edx
  101500:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101503:	66 89 14 c5 80 a8 10 	mov    %dx,0x10a880(,%eax,8)
  10150a:	00 
  10150b:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10150e:	66 c7 04 c5 82 a8 10 	movw   $0x8,0x10a882(,%eax,8)
  101515:	00 08 00 
  101518:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10151b:	0f b6 14 c5 84 a8 10 	movzbl 0x10a884(,%eax,8),%edx
  101522:	00 
  101523:	83 e2 e0             	and    $0xffffffe0,%edx
  101526:	88 14 c5 84 a8 10 00 	mov    %dl,0x10a884(,%eax,8)
  10152d:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101530:	0f b6 14 c5 84 a8 10 	movzbl 0x10a884(,%eax,8),%edx
  101537:	00 
  101538:	83 e2 1f             	and    $0x1f,%edx
  10153b:	88 14 c5 84 a8 10 00 	mov    %dl,0x10a884(,%eax,8)
  101542:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101545:	0f b6 14 c5 85 a8 10 	movzbl 0x10a885(,%eax,8),%edx
  10154c:	00 
  10154d:	83 e2 f0             	and    $0xfffffff0,%edx
  101550:	83 ca 0e             	or     $0xe,%edx
  101553:	88 14 c5 85 a8 10 00 	mov    %dl,0x10a885(,%eax,8)
  10155a:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10155d:	0f b6 14 c5 85 a8 10 	movzbl 0x10a885(,%eax,8),%edx
  101564:	00 
  101565:	83 e2 ef             	and    $0xffffffef,%edx
  101568:	88 14 c5 85 a8 10 00 	mov    %dl,0x10a885(,%eax,8)
  10156f:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101572:	0f b6 14 c5 85 a8 10 	movzbl 0x10a885(,%eax,8),%edx
  101579:	00 
  10157a:	83 e2 9f             	and    $0xffffff9f,%edx
  10157d:	88 14 c5 85 a8 10 00 	mov    %dl,0x10a885(,%eax,8)
  101584:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101587:	0f b6 14 c5 85 a8 10 	movzbl 0x10a885(,%eax,8),%edx
  10158e:	00 
  10158f:	83 ca 80             	or     $0xffffff80,%edx
  101592:	88 14 c5 85 a8 10 00 	mov    %dl,0x10a885(,%eax,8)
  101599:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10159c:	8b 04 85 0c 90 10 00 	mov    0x10900c(,%eax,4),%eax
  1015a3:	c1 e8 10             	shr    $0x10,%eax
  1015a6:	89 c2                	mov    %eax,%edx
  1015a8:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1015ab:	66 89 14 c5 86 a8 10 	mov    %dx,0x10a886(,%eax,8)
  1015b2:	00 
	extern segdesc gdt[];

	//panic("trap_init() not implemented.");

	int i;
	for (i=0; i<501; i++) {
  1015b3:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  1015b7:	81 7d fc f4 01 00 00 	cmpl   $0x1f4,-0x4(%ebp)
  1015be:	0f 8e 30 ff ff ff    	jle    1014f4 <trap_init_idt+0x12>
		SETGATE(idt[i], 0, CPU_GDT_KCODE, vectors[i], 0); //CPU_GDT_KCODE is 0x08
	}
	SETGATE(idt[T_BRKPT], 0, CPU_GDT_KCODE, vectors[3], 3); //T_BRKPT
  1015c4:	a1 18 90 10 00       	mov    0x109018,%eax
  1015c9:	66 a3 98 a8 10 00    	mov    %ax,0x10a898
  1015cf:	66 c7 05 9a a8 10 00 	movw   $0x8,0x10a89a
  1015d6:	08 00 
  1015d8:	0f b6 05 9c a8 10 00 	movzbl 0x10a89c,%eax
  1015df:	83 e0 e0             	and    $0xffffffe0,%eax
  1015e2:	a2 9c a8 10 00       	mov    %al,0x10a89c
  1015e7:	0f b6 05 9c a8 10 00 	movzbl 0x10a89c,%eax
  1015ee:	83 e0 1f             	and    $0x1f,%eax
  1015f1:	a2 9c a8 10 00       	mov    %al,0x10a89c
  1015f6:	0f b6 05 9d a8 10 00 	movzbl 0x10a89d,%eax
  1015fd:	83 e0 f0             	and    $0xfffffff0,%eax
  101600:	83 c8 0e             	or     $0xe,%eax
  101603:	a2 9d a8 10 00       	mov    %al,0x10a89d
  101608:	0f b6 05 9d a8 10 00 	movzbl 0x10a89d,%eax
  10160f:	83 e0 ef             	and    $0xffffffef,%eax
  101612:	a2 9d a8 10 00       	mov    %al,0x10a89d
  101617:	0f b6 05 9d a8 10 00 	movzbl 0x10a89d,%eax
  10161e:	83 c8 60             	or     $0x60,%eax
  101621:	a2 9d a8 10 00       	mov    %al,0x10a89d
  101626:	0f b6 05 9d a8 10 00 	movzbl 0x10a89d,%eax
  10162d:	83 c8 80             	or     $0xffffff80,%eax
  101630:	a2 9d a8 10 00       	mov    %al,0x10a89d
  101635:	a1 18 90 10 00       	mov    0x109018,%eax
  10163a:	c1 e8 10             	shr    $0x10,%eax
  10163d:	66 a3 9e a8 10 00    	mov    %ax,0x10a89e
	SETGATE(idt[T_OFLOW], 0, CPU_GDT_KCODE, vectors[4], 3); //T_OFLOW
  101643:	a1 1c 90 10 00       	mov    0x10901c,%eax
  101648:	66 a3 a0 a8 10 00    	mov    %ax,0x10a8a0
  10164e:	66 c7 05 a2 a8 10 00 	movw   $0x8,0x10a8a2
  101655:	08 00 
  101657:	0f b6 05 a4 a8 10 00 	movzbl 0x10a8a4,%eax
  10165e:	83 e0 e0             	and    $0xffffffe0,%eax
  101661:	a2 a4 a8 10 00       	mov    %al,0x10a8a4
  101666:	0f b6 05 a4 a8 10 00 	movzbl 0x10a8a4,%eax
  10166d:	83 e0 1f             	and    $0x1f,%eax
  101670:	a2 a4 a8 10 00       	mov    %al,0x10a8a4
  101675:	0f b6 05 a5 a8 10 00 	movzbl 0x10a8a5,%eax
  10167c:	83 e0 f0             	and    $0xfffffff0,%eax
  10167f:	83 c8 0e             	or     $0xe,%eax
  101682:	a2 a5 a8 10 00       	mov    %al,0x10a8a5
  101687:	0f b6 05 a5 a8 10 00 	movzbl 0x10a8a5,%eax
  10168e:	83 e0 ef             	and    $0xffffffef,%eax
  101691:	a2 a5 a8 10 00       	mov    %al,0x10a8a5
  101696:	0f b6 05 a5 a8 10 00 	movzbl 0x10a8a5,%eax
  10169d:	83 c8 60             	or     $0x60,%eax
  1016a0:	a2 a5 a8 10 00       	mov    %al,0x10a8a5
  1016a5:	0f b6 05 a5 a8 10 00 	movzbl 0x10a8a5,%eax
  1016ac:	83 c8 80             	or     $0xffffff80,%eax
  1016af:	a2 a5 a8 10 00       	mov    %al,0x10a8a5
  1016b4:	a1 1c 90 10 00       	mov    0x10901c,%eax
  1016b9:	c1 e8 10             	shr    $0x10,%eax
  1016bc:	66 a3 a6 a8 10 00    	mov    %ax,0x10a8a6
	SETGATE(idt[T_SYSCALL], 0, CPU_GDT_KCODE, vectors[48], 3); //T_SYSCALL 
  1016c2:	a1 cc 90 10 00       	mov    0x1090cc,%eax
  1016c7:	66 a3 00 aa 10 00    	mov    %ax,0x10aa00
  1016cd:	66 c7 05 02 aa 10 00 	movw   $0x8,0x10aa02
  1016d4:	08 00 
  1016d6:	0f b6 05 04 aa 10 00 	movzbl 0x10aa04,%eax
  1016dd:	83 e0 e0             	and    $0xffffffe0,%eax
  1016e0:	a2 04 aa 10 00       	mov    %al,0x10aa04
  1016e5:	0f b6 05 04 aa 10 00 	movzbl 0x10aa04,%eax
  1016ec:	83 e0 1f             	and    $0x1f,%eax
  1016ef:	a2 04 aa 10 00       	mov    %al,0x10aa04
  1016f4:	0f b6 05 05 aa 10 00 	movzbl 0x10aa05,%eax
  1016fb:	83 e0 f0             	and    $0xfffffff0,%eax
  1016fe:	83 c8 0e             	or     $0xe,%eax
  101701:	a2 05 aa 10 00       	mov    %al,0x10aa05
  101706:	0f b6 05 05 aa 10 00 	movzbl 0x10aa05,%eax
  10170d:	83 e0 ef             	and    $0xffffffef,%eax
  101710:	a2 05 aa 10 00       	mov    %al,0x10aa05
  101715:	0f b6 05 05 aa 10 00 	movzbl 0x10aa05,%eax
  10171c:	83 c8 60             	or     $0x60,%eax
  10171f:	a2 05 aa 10 00       	mov    %al,0x10aa05
  101724:	0f b6 05 05 aa 10 00 	movzbl 0x10aa05,%eax
  10172b:	83 c8 80             	or     $0xffffff80,%eax
  10172e:	a2 05 aa 10 00       	mov    %al,0x10aa05
  101733:	a1 cc 90 10 00       	mov    0x1090cc,%eax
  101738:	c1 e8 10             	shr    $0x10,%eax
  10173b:	66 a3 06 aa 10 00    	mov    %ax,0x10aa06
	
}
  101741:	c9                   	leave  
  101742:	c3                   	ret    

00101743 <trap_init>:

void
trap_init(void)
{
  101743:	55                   	push   %ebp
  101744:	89 e5                	mov    %esp,%ebp
  101746:	83 ec 08             	sub    $0x8,%esp
	// The first time we get called on the bootstrap processor,
	// initialize the IDT.  Other CPUs will share the same IDT.
	if (cpu_onboot())
  101749:	e8 7c fd ff ff       	call   1014ca <cpu_onboot>
  10174e:	85 c0                	test   %eax,%eax
  101750:	74 05                	je     101757 <trap_init+0x14>
		trap_init_idt();
  101752:	e8 8b fd ff ff       	call   1014e2 <trap_init_idt>

	// Load the IDT into this processor's IDT register.
	asm volatile("lidt %0" : : "m" (idt_pd));
  101757:	0f 01 1d 04 90 10 00 	lidtl  0x109004

	// Check for the correct IDT and trap handler operation.
	if (cpu_onboot())
  10175e:	e8 67 fd ff ff       	call   1014ca <cpu_onboot>
  101763:	85 c0                	test   %eax,%eax
  101765:	74 05                	je     10176c <trap_init+0x29>
		trap_check_kernel();
  101767:	e8 4e 04 00 00       	call   101bba <trap_check_kernel>
}
  10176c:	c9                   	leave  
  10176d:	c3                   	ret    

0010176e <trap_name>:

const char *trap_name(int trapno)
{
  10176e:	55                   	push   %ebp
  10176f:	89 e5                	mov    %esp,%ebp
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
  101771:	8b 45 08             	mov    0x8(%ebp),%eax
  101774:	83 f8 13             	cmp    $0x13,%eax
  101777:	77 0c                	ja     101785 <trap_name+0x17>
		return excnames[trapno];
  101779:	8b 45 08             	mov    0x8(%ebp),%eax
  10177c:	8b 04 85 e0 62 10 00 	mov    0x1062e0(,%eax,4),%eax
  101783:	eb 25                	jmp    1017aa <trap_name+0x3c>
	if (trapno == T_SYSCALL)
  101785:	83 7d 08 30          	cmpl   $0x30,0x8(%ebp)
  101789:	75 07                	jne    101792 <trap_name+0x24>
		return "System call";
  10178b:	b8 18 5e 10 00       	mov    $0x105e18,%eax
  101790:	eb 18                	jmp    1017aa <trap_name+0x3c>
	if (trapno >= T_IRQ0 && trapno < T_IRQ0 + 16)
  101792:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
  101796:	7e 0d                	jle    1017a5 <trap_name+0x37>
  101798:	83 7d 08 2f          	cmpl   $0x2f,0x8(%ebp)
  10179c:	7f 07                	jg     1017a5 <trap_name+0x37>
		return "Hardware Interrupt";
  10179e:	b8 24 5e 10 00       	mov    $0x105e24,%eax
  1017a3:	eb 05                	jmp    1017aa <trap_name+0x3c>
	return "(unknown trap)";
  1017a5:	b8 37 5e 10 00       	mov    $0x105e37,%eax
}
  1017aa:	5d                   	pop    %ebp
  1017ab:	c3                   	ret    

001017ac <trap_print_regs>:

void
trap_print_regs(pushregs *regs)
{
  1017ac:	55                   	push   %ebp
  1017ad:	89 e5                	mov    %esp,%ebp
  1017af:	83 ec 18             	sub    $0x18,%esp
	cprintf("  edi  0x%08x\n", regs->edi);
  1017b2:	8b 45 08             	mov    0x8(%ebp),%eax
  1017b5:	8b 00                	mov    (%eax),%eax
  1017b7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1017bb:	c7 04 24 46 5e 10 00 	movl   $0x105e46,(%esp)
  1017c2:	e8 15 3a 00 00       	call   1051dc <cprintf>
	cprintf("  esi  0x%08x\n", regs->esi);
  1017c7:	8b 45 08             	mov    0x8(%ebp),%eax
  1017ca:	8b 40 04             	mov    0x4(%eax),%eax
  1017cd:	89 44 24 04          	mov    %eax,0x4(%esp)
  1017d1:	c7 04 24 55 5e 10 00 	movl   $0x105e55,(%esp)
  1017d8:	e8 ff 39 00 00       	call   1051dc <cprintf>
	cprintf("  ebp  0x%08x\n", regs->ebp);
  1017dd:	8b 45 08             	mov    0x8(%ebp),%eax
  1017e0:	8b 40 08             	mov    0x8(%eax),%eax
  1017e3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1017e7:	c7 04 24 64 5e 10 00 	movl   $0x105e64,(%esp)
  1017ee:	e8 e9 39 00 00       	call   1051dc <cprintf>
//	cprintf("  oesp 0x%08x\n", regs->oesp);	don't print - useless
	cprintf("  ebx  0x%08x\n", regs->ebx);
  1017f3:	8b 45 08             	mov    0x8(%ebp),%eax
  1017f6:	8b 40 10             	mov    0x10(%eax),%eax
  1017f9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1017fd:	c7 04 24 73 5e 10 00 	movl   $0x105e73,(%esp)
  101804:	e8 d3 39 00 00       	call   1051dc <cprintf>
	cprintf("  edx  0x%08x\n", regs->edx);
  101809:	8b 45 08             	mov    0x8(%ebp),%eax
  10180c:	8b 40 14             	mov    0x14(%eax),%eax
  10180f:	89 44 24 04          	mov    %eax,0x4(%esp)
  101813:	c7 04 24 82 5e 10 00 	movl   $0x105e82,(%esp)
  10181a:	e8 bd 39 00 00       	call   1051dc <cprintf>
	cprintf("  ecx  0x%08x\n", regs->ecx);
  10181f:	8b 45 08             	mov    0x8(%ebp),%eax
  101822:	8b 40 18             	mov    0x18(%eax),%eax
  101825:	89 44 24 04          	mov    %eax,0x4(%esp)
  101829:	c7 04 24 91 5e 10 00 	movl   $0x105e91,(%esp)
  101830:	e8 a7 39 00 00       	call   1051dc <cprintf>
	cprintf("  eax  0x%08x\n", regs->eax);
  101835:	8b 45 08             	mov    0x8(%ebp),%eax
  101838:	8b 40 1c             	mov    0x1c(%eax),%eax
  10183b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10183f:	c7 04 24 a0 5e 10 00 	movl   $0x105ea0,(%esp)
  101846:	e8 91 39 00 00       	call   1051dc <cprintf>
}
  10184b:	c9                   	leave  
  10184c:	c3                   	ret    

0010184d <trap_print>:

void
trap_print(trapframe *tf)
{
  10184d:	55                   	push   %ebp
  10184e:	89 e5                	mov    %esp,%ebp
  101850:	83 ec 18             	sub    $0x18,%esp
	cprintf("TRAP frame at %p\n", tf);
  101853:	8b 45 08             	mov    0x8(%ebp),%eax
  101856:	89 44 24 04          	mov    %eax,0x4(%esp)
  10185a:	c7 04 24 af 5e 10 00 	movl   $0x105eaf,(%esp)
  101861:	e8 76 39 00 00       	call   1051dc <cprintf>
	trap_print_regs(&tf->regs);
  101866:	8b 45 08             	mov    0x8(%ebp),%eax
  101869:	89 04 24             	mov    %eax,(%esp)
  10186c:	e8 3b ff ff ff       	call   1017ac <trap_print_regs>
	cprintf("  es   0x----%04x\n", tf->es);
  101871:	8b 45 08             	mov    0x8(%ebp),%eax
  101874:	0f b7 40 28          	movzwl 0x28(%eax),%eax
  101878:	0f b7 c0             	movzwl %ax,%eax
  10187b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10187f:	c7 04 24 c1 5e 10 00 	movl   $0x105ec1,(%esp)
  101886:	e8 51 39 00 00       	call   1051dc <cprintf>
	cprintf("  ds   0x----%04x\n", tf->ds);
  10188b:	8b 45 08             	mov    0x8(%ebp),%eax
  10188e:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  101892:	0f b7 c0             	movzwl %ax,%eax
  101895:	89 44 24 04          	mov    %eax,0x4(%esp)
  101899:	c7 04 24 d4 5e 10 00 	movl   $0x105ed4,(%esp)
  1018a0:	e8 37 39 00 00       	call   1051dc <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->trapno, trap_name(tf->trapno));
  1018a5:	8b 45 08             	mov    0x8(%ebp),%eax
  1018a8:	8b 40 30             	mov    0x30(%eax),%eax
  1018ab:	89 04 24             	mov    %eax,(%esp)
  1018ae:	e8 bb fe ff ff       	call   10176e <trap_name>
  1018b3:	8b 55 08             	mov    0x8(%ebp),%edx
  1018b6:	8b 52 30             	mov    0x30(%edx),%edx
  1018b9:	89 44 24 08          	mov    %eax,0x8(%esp)
  1018bd:	89 54 24 04          	mov    %edx,0x4(%esp)
  1018c1:	c7 04 24 e7 5e 10 00 	movl   $0x105ee7,(%esp)
  1018c8:	e8 0f 39 00 00       	call   1051dc <cprintf>
	cprintf("  err  0x%08x\n", tf->err);
  1018cd:	8b 45 08             	mov    0x8(%ebp),%eax
  1018d0:	8b 40 34             	mov    0x34(%eax),%eax
  1018d3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1018d7:	c7 04 24 f9 5e 10 00 	movl   $0x105ef9,(%esp)
  1018de:	e8 f9 38 00 00       	call   1051dc <cprintf>
	cprintf("  eip  0x%08x\n", tf->eip);
  1018e3:	8b 45 08             	mov    0x8(%ebp),%eax
  1018e6:	8b 40 38             	mov    0x38(%eax),%eax
  1018e9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1018ed:	c7 04 24 08 5f 10 00 	movl   $0x105f08,(%esp)
  1018f4:	e8 e3 38 00 00       	call   1051dc <cprintf>
	cprintf("  cs   0x----%04x\n", tf->cs);
  1018f9:	8b 45 08             	mov    0x8(%ebp),%eax
  1018fc:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  101900:	0f b7 c0             	movzwl %ax,%eax
  101903:	89 44 24 04          	mov    %eax,0x4(%esp)
  101907:	c7 04 24 17 5f 10 00 	movl   $0x105f17,(%esp)
  10190e:	e8 c9 38 00 00       	call   1051dc <cprintf>
	cprintf("  flag 0x%08x\n", tf->eflags);
  101913:	8b 45 08             	mov    0x8(%ebp),%eax
  101916:	8b 40 40             	mov    0x40(%eax),%eax
  101919:	89 44 24 04          	mov    %eax,0x4(%esp)
  10191d:	c7 04 24 2a 5f 10 00 	movl   $0x105f2a,(%esp)
  101924:	e8 b3 38 00 00       	call   1051dc <cprintf>
	cprintf("  esp  0x%08x\n", tf->esp);
  101929:	8b 45 08             	mov    0x8(%ebp),%eax
  10192c:	8b 40 44             	mov    0x44(%eax),%eax
  10192f:	89 44 24 04          	mov    %eax,0x4(%esp)
  101933:	c7 04 24 39 5f 10 00 	movl   $0x105f39,(%esp)
  10193a:	e8 9d 38 00 00       	call   1051dc <cprintf>
	cprintf("  ss   0x----%04x\n", tf->ss);
  10193f:	8b 45 08             	mov    0x8(%ebp),%eax
  101942:	0f b7 40 48          	movzwl 0x48(%eax),%eax
  101946:	0f b7 c0             	movzwl %ax,%eax
  101949:	89 44 24 04          	mov    %eax,0x4(%esp)
  10194d:	c7 04 24 48 5f 10 00 	movl   $0x105f48,(%esp)
  101954:	e8 83 38 00 00       	call   1051dc <cprintf>
}
  101959:	c9                   	leave  
  10195a:	c3                   	ret    

0010195b <trap>:

void gcc_noreturn
trap(trapframe *tf)
{
  10195b:	55                   	push   %ebp
  10195c:	89 e5                	mov    %esp,%ebp
  10195e:	53                   	push   %ebx
  10195f:	83 ec 24             	sub    $0x24,%esp
	// The user-level environment may have set the DF flag,
	// and some versions of GCC rely on DF being clear.
	asm volatile("cld" ::: "cc");
  101962:	fc                   	cld    

// Disable external device interrupts.
static gcc_inline void
cli(void)
{
	asm volatile("cli");
  101963:	fa                   	cli    

       	cli();//the interrupt must be close until trap_return 

	// If this trap was anticipated, just use the designated handler.
	cpu *c = cpu_cur();
  101964:	e8 07 fb ff ff       	call   101470 <cpu_cur>
  101969:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (c->recover)
  10196c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10196f:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  101975:	85 c0                	test   %eax,%eax
  101977:	74 1e                	je     101997 <trap+0x3c>
		c->recover(tf, c->recoverdata);
  101979:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10197c:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  101982:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101985:	8b 92 a4 00 00 00    	mov    0xa4(%edx),%edx
  10198b:	89 54 24 04          	mov    %edx,0x4(%esp)
  10198f:	8b 55 08             	mov    0x8(%ebp),%edx
  101992:	89 14 24             	mov    %edx,(%esp)
  101995:	ff d0                	call   *%eax

	// Lab 2: your trap handling code here!
	switch (tf->trapno) {
  101997:	8b 45 08             	mov    0x8(%ebp),%eax
  10199a:	8b 40 30             	mov    0x30(%eax),%eax
  10199d:	83 e8 1e             	sub    $0x1e,%eax
  1019a0:	83 f8 14             	cmp    $0x14,%eax
  1019a3:	0f 87 65 01 00 00    	ja     101b0e <trap+0x1b3>
  1019a9:	8b 04 85 34 60 10 00 	mov    0x106034(,%eax,4),%eax
  1019b0:	ff e0                	jmp    *%eax
  		case T_SYSCALL:
		  //syscalls only come from user space
		  assert(tf->cs & 3);
  1019b2:	8b 45 08             	mov    0x8(%ebp),%eax
  1019b5:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  1019b9:	0f b7 c0             	movzwl %ax,%eax
  1019bc:	83 e0 03             	and    $0x3,%eax
  1019bf:	85 c0                	test   %eax,%eax
  1019c1:	75 24                	jne    1019e7 <trap+0x8c>
  1019c3:	c7 44 24 0c 5b 5f 10 	movl   $0x105f5b,0xc(%esp)
  1019ca:	00 
  1019cb:	c7 44 24 08 f6 5d 10 	movl   $0x105df6,0x8(%esp)
  1019d2:	00 
  1019d3:	c7 44 24 04 98 00 00 	movl   $0x98,0x4(%esp)
  1019da:	00 
  1019db:	c7 04 24 66 5f 10 00 	movl   $0x105f66,(%esp)
  1019e2:	e8 dd ea ff ff       	call   1004c4 <debug_panic>
		  syscall(tf);
  1019e7:	8b 45 08             	mov    0x8(%ebp),%eax
  1019ea:	89 04 24             	mov    %eax,(%esp)
  1019ed:	e8 7b 21 00 00       	call   103b6d <syscall>
		  break;
  1019f2:	90                   	nop
	      
	}    	
	
	// If we panic while holding the console lock,
	// release it so we don't get into a recursive panic that way.
	if (spinlock_holding(&cons_lock))
  1019f3:	c7 04 24 00 f3 10 00 	movl   $0x10f300,(%esp)
  1019fa:	e8 b3 0c 00 00       	call   1026b2 <spinlock_holding>
  1019ff:	85 c0                	test   %eax,%eax
  101a01:	0f 84 5a 01 00 00    	je     101b61 <trap+0x206>
  101a07:	e9 49 01 00 00       	jmp    101b55 <trap+0x1fa>
		  //syscalls only come from user space
		  assert(tf->cs & 3);
		  syscall(tf);
		  break;
	  	case T_SECEV:
		  cprintf("T_SECEV interrupt occured on CPU %d\n",cpu_cur()->id);
  101a0c:	e8 5f fa ff ff       	call   101470 <cpu_cur>
  101a11:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  101a18:	0f b6 c0             	movzbl %al,%eax
  101a1b:	89 44 24 04          	mov    %eax,0x4(%esp)
  101a1f:	c7 04 24 74 5f 10 00 	movl   $0x105f74,(%esp)
  101a26:	e8 b1 37 00 00       	call   1051dc <cprintf>
		  assert(tf->cs & 3);
  101a2b:	8b 45 08             	mov    0x8(%ebp),%eax
  101a2e:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  101a32:	0f b7 c0             	movzwl %ax,%eax
  101a35:	83 e0 03             	and    $0x3,%eax
  101a38:	85 c0                	test   %eax,%eax
  101a3a:	75 24                	jne    101a60 <trap+0x105>
  101a3c:	c7 44 24 0c 5b 5f 10 	movl   $0x105f5b,0xc(%esp)
  101a43:	00 
  101a44:	c7 44 24 08 f6 5d 10 	movl   $0x105df6,0x8(%esp)
  101a4b:	00 
  101a4c:	c7 44 24 04 9d 00 00 	movl   $0x9d,0x4(%esp)
  101a53:	00 
  101a54:	c7 04 24 66 5f 10 00 	movl   $0x105f66,(%esp)
  101a5b:	e8 64 ea ff ff       	call   1004c4 <debug_panic>
		  proc_ret(tf, -1);
  101a60:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  101a67:	ff 
  101a68:	8b 45 08             	mov    0x8(%ebp),%eax
  101a6b:	89 04 24             	mov    %eax,(%esp)
  101a6e:	e8 5a 16 00 00       	call   1030cd <proc_ret>
		  break;
	  	case T_LTIMER:
		  lapic_eoi();
  101a73:	e8 cc 2c 00 00       	call   104744 <lapic_eoi>
		  if (tf->cs & 3)
  101a78:	8b 45 08             	mov    0x8(%ebp),%eax
  101a7b:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  101a7f:	0f b7 c0             	movzwl %ax,%eax
  101a82:	83 e0 03             	and    $0x3,%eax
  101a85:	85 c0                	test   %eax,%eax
  101a87:	74 0b                	je     101a94 <trap+0x139>
		    proc_yield(tf);
  101a89:	8b 45 08             	mov    0x8(%ebp),%eax
  101a8c:	89 04 24             	mov    %eax,(%esp)
  101a8f:	e8 fb 15 00 00       	call   10308f <proc_yield>
		  trap_return(tf);
  101a94:	8b 45 08             	mov    0x8(%ebp),%eax
  101a97:	89 04 24             	mov    %eax,(%esp)
  101a9a:	e8 81 06 00 00       	call   102120 <trap_return>
		  break;
	  	case T_LERROR:
		  cprintf("T_LERROR interrupt occured on CPU %d\n", cpu_cur()->id);
  101a9f:	e8 cc f9 ff ff       	call   101470 <cpu_cur>
  101aa4:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  101aab:	0f b6 c0             	movzbl %al,%eax
  101aae:	89 44 24 04          	mov    %eax,0x4(%esp)
  101ab2:	c7 04 24 9c 5f 10 00 	movl   $0x105f9c,(%esp)
  101ab9:	e8 1e 37 00 00       	call   1051dc <cprintf>
		  lapic_errintr();
  101abe:	e8 a6 2c 00 00       	call   104769 <lapic_errintr>
		  trap_return(tf);
  101ac3:	8b 45 08             	mov    0x8(%ebp),%eax
  101ac6:	89 04 24             	mov    %eax,(%esp)
  101ac9:	e8 52 06 00 00       	call   102120 <trap_return>
	  	case T_IRQ0 + IRQ_SPURIOUS:
		  cprintf("cpu%d: spurious interrupt at %x:%x\n",
			  c->id, tf->cs, tf->eip);
  101ace:	8b 45 08             	mov    0x8(%ebp),%eax
	  	case T_LERROR:
		  cprintf("T_LERROR interrupt occured on CPU %d\n", cpu_cur()->id);
		  lapic_errintr();
		  trap_return(tf);
	  	case T_IRQ0 + IRQ_SPURIOUS:
		  cprintf("cpu%d: spurious interrupt at %x:%x\n",
  101ad1:	8b 48 38             	mov    0x38(%eax),%ecx
			  c->id, tf->cs, tf->eip);
  101ad4:	8b 45 08             	mov    0x8(%ebp),%eax
  101ad7:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
	  	case T_LERROR:
		  cprintf("T_LERROR interrupt occured on CPU %d\n", cpu_cur()->id);
		  lapic_errintr();
		  trap_return(tf);
	  	case T_IRQ0 + IRQ_SPURIOUS:
		  cprintf("cpu%d: spurious interrupt at %x:%x\n",
  101adb:	0f b7 d0             	movzwl %ax,%edx
			  c->id, tf->cs, tf->eip);
  101ade:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101ae1:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
	  	case T_LERROR:
		  cprintf("T_LERROR interrupt occured on CPU %d\n", cpu_cur()->id);
		  lapic_errintr();
		  trap_return(tf);
	  	case T_IRQ0 + IRQ_SPURIOUS:
		  cprintf("cpu%d: spurious interrupt at %x:%x\n",
  101ae8:	0f b6 c0             	movzbl %al,%eax
  101aeb:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  101aef:	89 54 24 08          	mov    %edx,0x8(%esp)
  101af3:	89 44 24 04          	mov    %eax,0x4(%esp)
  101af7:	c7 04 24 c4 5f 10 00 	movl   $0x105fc4,(%esp)
  101afe:	e8 d9 36 00 00       	call   1051dc <cprintf>
			  c->id, tf->cs, tf->eip);
		  trap_return(tf); // Note: no EOI (see Local APIC manual)
  101b03:	8b 45 08             	mov    0x8(%ebp),%eax
  101b06:	89 04 24             	mov    %eax,(%esp)
  101b09:	e8 12 06 00 00       	call   102120 <trap_return>
		  break;
	        default:
		  cprintf("Unhandled interrupt occured on cpu %d: the trapno is %d!\n", 
		  cpu_cur()->id, tf->trapno);
  101b0e:	8b 45 08             	mov    0x8(%ebp),%eax
		  cprintf("cpu%d: spurious interrupt at %x:%x\n",
			  c->id, tf->cs, tf->eip);
		  trap_return(tf); // Note: no EOI (see Local APIC manual)
		  break;
	        default:
		  cprintf("Unhandled interrupt occured on cpu %d: the trapno is %d!\n", 
  101b11:	8b 58 30             	mov    0x30(%eax),%ebx
		  cpu_cur()->id, tf->trapno);
  101b14:	e8 57 f9 ff ff       	call   101470 <cpu_cur>
  101b19:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
		  cprintf("cpu%d: spurious interrupt at %x:%x\n",
			  c->id, tf->cs, tf->eip);
		  trap_return(tf); // Note: no EOI (see Local APIC manual)
		  break;
	        default:
		  cprintf("Unhandled interrupt occured on cpu %d: the trapno is %d!\n", 
  101b20:	0f b6 c0             	movzbl %al,%eax
  101b23:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  101b27:	89 44 24 04          	mov    %eax,0x4(%esp)
  101b2b:	c7 04 24 e8 5f 10 00 	movl   $0x105fe8,(%esp)
  101b32:	e8 a5 36 00 00       	call   1051dc <cprintf>
		  cpu_cur()->id, tf->trapno);
		  trap_print(tf);
  101b37:	8b 45 08             	mov    0x8(%ebp),%eax
  101b3a:	89 04 24             	mov    %eax,(%esp)
  101b3d:	e8 0b fd ff ff       	call   10184d <trap_print>
		  proc_ret(tf, -1);
  101b42:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  101b49:	ff 
  101b4a:	8b 45 08             	mov    0x8(%ebp),%eax
  101b4d:	89 04 24             	mov    %eax,(%esp)
  101b50:	e8 78 15 00 00       	call   1030cd <proc_ret>
	}    	
	
	// If we panic while holding the console lock,
	// release it so we don't get into a recursive panic that way.
	if (spinlock_holding(&cons_lock))
		spinlock_release(&cons_lock);
  101b55:	c7 04 24 00 f3 10 00 	movl   $0x10f300,(%esp)
  101b5c:	e8 f7 0a 00 00       	call   102658 <spinlock_release>
	trap_print(tf);
  101b61:	8b 45 08             	mov    0x8(%ebp),%eax
  101b64:	89 04 24             	mov    %eax,(%esp)
  101b67:	e8 e1 fc ff ff       	call   10184d <trap_print>
	panic("unhandled trap");
  101b6c:	c7 44 24 08 22 60 10 	movl   $0x106022,0x8(%esp)
  101b73:	00 
  101b74:	c7 44 24 04 bc 00 00 	movl   $0xbc,0x4(%esp)
  101b7b:	00 
  101b7c:	c7 04 24 66 5f 10 00 	movl   $0x105f66,(%esp)
  101b83:	e8 3c e9 ff ff       	call   1004c4 <debug_panic>

00101b88 <trap_check_recover>:

// Helper function for trap_check_recover(), below:
// handles "anticipated" traps by simply resuming at a new EIP.
static void gcc_noreturn
trap_check_recover(trapframe *tf, void *recoverdata)
{
  101b88:	55                   	push   %ebp
  101b89:	89 e5                	mov    %esp,%ebp
  101b8b:	83 ec 28             	sub    $0x28,%esp
	trap_check_args *args = recoverdata;
  101b8e:	8b 45 0c             	mov    0xc(%ebp),%eax
  101b91:	89 45 f4             	mov    %eax,-0xc(%ebp)
	tf->eip = (uint32_t) args->reip;	// Use recovery EIP on return
  101b94:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101b97:	8b 00                	mov    (%eax),%eax
  101b99:	89 c2                	mov    %eax,%edx
  101b9b:	8b 45 08             	mov    0x8(%ebp),%eax
  101b9e:	89 50 38             	mov    %edx,0x38(%eax)
	args->trapno = tf->trapno;		// Return trap number
  101ba1:	8b 45 08             	mov    0x8(%ebp),%eax
  101ba4:	8b 40 30             	mov    0x30(%eax),%eax
  101ba7:	89 c2                	mov    %eax,%edx
  101ba9:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101bac:	89 50 04             	mov    %edx,0x4(%eax)
	trap_return(tf);
  101baf:	8b 45 08             	mov    0x8(%ebp),%eax
  101bb2:	89 04 24             	mov    %eax,(%esp)
  101bb5:	e8 66 05 00 00       	call   102120 <trap_return>

00101bba <trap_check_kernel>:

// Check for correct handling of traps from kernel mode.
// Called on the boot CPU after trap_init() and trap_setup().
void
trap_check_kernel(void)
{
  101bba:	55                   	push   %ebp
  101bbb:	89 e5                	mov    %esp,%ebp
  101bbd:	53                   	push   %ebx
  101bbe:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  101bc1:	66 8c cb             	mov    %cs,%bx
  101bc4:	66 89 5d f2          	mov    %bx,-0xe(%ebp)
        return cs;
  101bc8:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
	assert((read_cs() & 3) == 0);	// better be in kernel mode!
  101bcc:	0f b7 c0             	movzwl %ax,%eax
  101bcf:	83 e0 03             	and    $0x3,%eax
  101bd2:	85 c0                	test   %eax,%eax
  101bd4:	74 24                	je     101bfa <trap_check_kernel+0x40>
  101bd6:	c7 44 24 0c 88 60 10 	movl   $0x106088,0xc(%esp)
  101bdd:	00 
  101bde:	c7 44 24 08 f6 5d 10 	movl   $0x105df6,0x8(%esp)
  101be5:	00 
  101be6:	c7 44 24 04 d1 00 00 	movl   $0xd1,0x4(%esp)
  101bed:	00 
  101bee:	c7 04 24 66 5f 10 00 	movl   $0x105f66,(%esp)
  101bf5:	e8 ca e8 ff ff       	call   1004c4 <debug_panic>

	cpu *c = cpu_cur();
  101bfa:	e8 71 f8 ff ff       	call   101470 <cpu_cur>
  101bff:	89 45 f4             	mov    %eax,-0xc(%ebp)
	c->recover = trap_check_recover;
  101c02:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101c05:	c7 80 a0 00 00 00 88 	movl   $0x101b88,0xa0(%eax)
  101c0c:	1b 10 00 
	trap_check(&c->recoverdata);
  101c0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101c12:	05 a4 00 00 00       	add    $0xa4,%eax
  101c17:	89 04 24             	mov    %eax,(%esp)
  101c1a:	e8 a3 00 00 00       	call   101cc2 <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  101c1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101c22:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  101c29:	00 00 00 

	cprintf("trap_check_kernel() succeeded!\n");
  101c2c:	c7 04 24 a0 60 10 00 	movl   $0x1060a0,(%esp)
  101c33:	e8 a4 35 00 00       	call   1051dc <cprintf>
}
  101c38:	83 c4 24             	add    $0x24,%esp
  101c3b:	5b                   	pop    %ebx
  101c3c:	5d                   	pop    %ebp
  101c3d:	c3                   	ret    

00101c3e <trap_check_user>:
// Called from user() in kern/init.c, only in lab 1.
// We assume the "current cpu" is always the boot cpu;
// this true only because lab 1 doesn't start any other CPUs.
void
trap_check_user(void)
{
  101c3e:	55                   	push   %ebp
  101c3f:	89 e5                	mov    %esp,%ebp
  101c41:	53                   	push   %ebx
  101c42:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  101c45:	66 8c cb             	mov    %cs,%bx
  101c48:	66 89 5d f2          	mov    %bx,-0xe(%ebp)
        return cs;
  101c4c:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
	assert((read_cs() & 3) == 3);	// better be in user mode!
  101c50:	0f b7 c0             	movzwl %ax,%eax
  101c53:	83 e0 03             	and    $0x3,%eax
  101c56:	83 f8 03             	cmp    $0x3,%eax
  101c59:	74 24                	je     101c7f <trap_check_user+0x41>
  101c5b:	c7 44 24 0c c0 60 10 	movl   $0x1060c0,0xc(%esp)
  101c62:	00 
  101c63:	c7 44 24 08 f6 5d 10 	movl   $0x105df6,0x8(%esp)
  101c6a:	00 
  101c6b:	c7 44 24 04 e2 00 00 	movl   $0xe2,0x4(%esp)
  101c72:	00 
  101c73:	c7 04 24 66 5f 10 00 	movl   $0x105f66,(%esp)
  101c7a:	e8 45 e8 ff ff       	call   1004c4 <debug_panic>

	cpu *c = &cpu_boot;	// cpu_cur doesn't work from user mode!
  101c7f:	c7 45 f4 00 80 10 00 	movl   $0x108000,-0xc(%ebp)
	c->recover = trap_check_recover;
  101c86:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101c89:	c7 80 a0 00 00 00 88 	movl   $0x101b88,0xa0(%eax)
  101c90:	1b 10 00 
	trap_check(&c->recoverdata);
  101c93:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101c96:	05 a4 00 00 00       	add    $0xa4,%eax
  101c9b:	89 04 24             	mov    %eax,(%esp)
  101c9e:	e8 1f 00 00 00       	call   101cc2 <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  101ca3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101ca6:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  101cad:	00 00 00 

	cprintf("trap_check_user() succeeded!\n");
  101cb0:	c7 04 24 d5 60 10 00 	movl   $0x1060d5,(%esp)
  101cb7:	e8 20 35 00 00       	call   1051dc <cprintf>
}
  101cbc:	83 c4 24             	add    $0x24,%esp
  101cbf:	5b                   	pop    %ebx
  101cc0:	5d                   	pop    %ebp
  101cc1:	c3                   	ret    

00101cc2 <trap_check>:
void after_priv();

// Multi-purpose trap checking function.
void
trap_check(void **argsp)
{
  101cc2:	55                   	push   %ebp
  101cc3:	89 e5                	mov    %esp,%ebp
  101cc5:	57                   	push   %edi
  101cc6:	56                   	push   %esi
  101cc7:	53                   	push   %ebx
  101cc8:	83 ec 3c             	sub    $0x3c,%esp
	volatile int cookie = 0xfeedface;
  101ccb:	c7 45 e0 ce fa ed fe 	movl   $0xfeedface,-0x20(%ebp)
	volatile trap_check_args args;
	*argsp = (void*)&args;	// provide args needed for trap recovery
  101cd2:	8b 45 08             	mov    0x8(%ebp),%eax
  101cd5:	8d 55 d8             	lea    -0x28(%ebp),%edx
  101cd8:	89 10                	mov    %edx,(%eax)

	// Try a divide by zero trap.
	// Be careful when using && to take the address of a label:
	// some versions of GCC (4.4.2 at least) will incorrectly try to
	// eliminate code it thinks is _only_ reachable via such a pointer.
	args.reip = after_div0;
  101cda:	c7 45 d8 e8 1c 10 00 	movl   $0x101ce8,-0x28(%ebp)
	asm volatile("div %0,%0; after_div0:" : : "r" (0));
  101ce1:	b8 00 00 00 00       	mov    $0x0,%eax
  101ce6:	f7 f0                	div    %eax

00101ce8 <after_div0>:
	assert(args.trapno == T_DIVIDE);
  101ce8:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101ceb:	85 c0                	test   %eax,%eax
  101ced:	74 24                	je     101d13 <after_div0+0x2b>
  101cef:	c7 44 24 0c f3 60 10 	movl   $0x1060f3,0xc(%esp)
  101cf6:	00 
  101cf7:	c7 44 24 08 f6 5d 10 	movl   $0x105df6,0x8(%esp)
  101cfe:	00 
  101cff:	c7 44 24 04 02 01 00 	movl   $0x102,0x4(%esp)
  101d06:	00 
  101d07:	c7 04 24 66 5f 10 00 	movl   $0x105f66,(%esp)
  101d0e:	e8 b1 e7 ff ff       	call   1004c4 <debug_panic>

	// Make sure we got our correct stack back with us.
	// The asm ensures gcc uses ebp/esp to get the cookie.
	asm volatile("" : : : "eax","ebx","ecx","edx","esi","edi");
	assert(cookie == 0xfeedface);
  101d13:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101d16:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  101d1b:	74 24                	je     101d41 <after_div0+0x59>
  101d1d:	c7 44 24 0c 0b 61 10 	movl   $0x10610b,0xc(%esp)
  101d24:	00 
  101d25:	c7 44 24 08 f6 5d 10 	movl   $0x105df6,0x8(%esp)
  101d2c:	00 
  101d2d:	c7 44 24 04 07 01 00 	movl   $0x107,0x4(%esp)
  101d34:	00 
  101d35:	c7 04 24 66 5f 10 00 	movl   $0x105f66,(%esp)
  101d3c:	e8 83 e7 ff ff       	call   1004c4 <debug_panic>

	// Breakpoint trap
	args.reip = after_breakpoint;
  101d41:	c7 45 d8 49 1d 10 00 	movl   $0x101d49,-0x28(%ebp)
	asm volatile("int3; after_breakpoint:");
  101d48:	cc                   	int3   

00101d49 <after_breakpoint>:
	assert(args.trapno == T_BRKPT);
  101d49:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101d4c:	83 f8 03             	cmp    $0x3,%eax
  101d4f:	74 24                	je     101d75 <after_breakpoint+0x2c>
  101d51:	c7 44 24 0c 20 61 10 	movl   $0x106120,0xc(%esp)
  101d58:	00 
  101d59:	c7 44 24 08 f6 5d 10 	movl   $0x105df6,0x8(%esp)
  101d60:	00 
  101d61:	c7 44 24 04 0c 01 00 	movl   $0x10c,0x4(%esp)
  101d68:	00 
  101d69:	c7 04 24 66 5f 10 00 	movl   $0x105f66,(%esp)
  101d70:	e8 4f e7 ff ff       	call   1004c4 <debug_panic>

	// Overflow trap
	args.reip = after_overflow;
  101d75:	c7 45 d8 84 1d 10 00 	movl   $0x101d84,-0x28(%ebp)
	asm volatile("addl %0,%0; into; after_overflow:" : : "r" (0x70000000));
  101d7c:	b8 00 00 00 70       	mov    $0x70000000,%eax
  101d81:	01 c0                	add    %eax,%eax
  101d83:	ce                   	into   

00101d84 <after_overflow>:
	assert(args.trapno == T_OFLOW);
  101d84:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101d87:	83 f8 04             	cmp    $0x4,%eax
  101d8a:	74 24                	je     101db0 <after_overflow+0x2c>
  101d8c:	c7 44 24 0c 37 61 10 	movl   $0x106137,0xc(%esp)
  101d93:	00 
  101d94:	c7 44 24 08 f6 5d 10 	movl   $0x105df6,0x8(%esp)
  101d9b:	00 
  101d9c:	c7 44 24 04 11 01 00 	movl   $0x111,0x4(%esp)
  101da3:	00 
  101da4:	c7 04 24 66 5f 10 00 	movl   $0x105f66,(%esp)
  101dab:	e8 14 e7 ff ff       	call   1004c4 <debug_panic>

	// Bounds trap
	args.reip = after_bound;
  101db0:	c7 45 d8 cd 1d 10 00 	movl   $0x101dcd,-0x28(%ebp)
	int bounds[2] = { 1, 3 };
  101db7:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
  101dbe:	c7 45 d4 03 00 00 00 	movl   $0x3,-0x2c(%ebp)
	asm volatile("boundl %0,%1; after_bound:" : : "r" (0), "m" (bounds[0]));
  101dc5:	b8 00 00 00 00       	mov    $0x0,%eax
  101dca:	62 45 d0             	bound  %eax,-0x30(%ebp)

00101dcd <after_bound>:
	assert(args.trapno == T_BOUND);
  101dcd:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101dd0:	83 f8 05             	cmp    $0x5,%eax
  101dd3:	74 24                	je     101df9 <after_bound+0x2c>
  101dd5:	c7 44 24 0c 4e 61 10 	movl   $0x10614e,0xc(%esp)
  101ddc:	00 
  101ddd:	c7 44 24 08 f6 5d 10 	movl   $0x105df6,0x8(%esp)
  101de4:	00 
  101de5:	c7 44 24 04 17 01 00 	movl   $0x117,0x4(%esp)
  101dec:	00 
  101ded:	c7 04 24 66 5f 10 00 	movl   $0x105f66,(%esp)
  101df4:	e8 cb e6 ff ff       	call   1004c4 <debug_panic>

	// Illegal instruction trap
	args.reip = after_illegal;
  101df9:	c7 45 d8 02 1e 10 00 	movl   $0x101e02,-0x28(%ebp)
	asm volatile("ud2; after_illegal:");	// guaranteed to be undefined
  101e00:	0f 0b                	ud2    

00101e02 <after_illegal>:
	assert(args.trapno == T_ILLOP);
  101e02:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101e05:	83 f8 06             	cmp    $0x6,%eax
  101e08:	74 24                	je     101e2e <after_illegal+0x2c>
  101e0a:	c7 44 24 0c 65 61 10 	movl   $0x106165,0xc(%esp)
  101e11:	00 
  101e12:	c7 44 24 08 f6 5d 10 	movl   $0x105df6,0x8(%esp)
  101e19:	00 
  101e1a:	c7 44 24 04 1c 01 00 	movl   $0x11c,0x4(%esp)
  101e21:	00 
  101e22:	c7 04 24 66 5f 10 00 	movl   $0x105f66,(%esp)
  101e29:	e8 96 e6 ff ff       	call   1004c4 <debug_panic>

	// General protection fault due to invalid segment load
	args.reip = after_gpfault;
  101e2e:	c7 45 d8 3c 1e 10 00 	movl   $0x101e3c,-0x28(%ebp)
	asm volatile("movl %0,%%fs; after_gpfault:" : : "r" (-1));
  101e35:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  101e3a:	8e e0                	mov    %eax,%fs

00101e3c <after_gpfault>:
	assert(args.trapno == T_GPFLT);
  101e3c:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101e3f:	83 f8 0d             	cmp    $0xd,%eax
  101e42:	74 24                	je     101e68 <after_gpfault+0x2c>
  101e44:	c7 44 24 0c 7c 61 10 	movl   $0x10617c,0xc(%esp)
  101e4b:	00 
  101e4c:	c7 44 24 08 f6 5d 10 	movl   $0x105df6,0x8(%esp)
  101e53:	00 
  101e54:	c7 44 24 04 21 01 00 	movl   $0x121,0x4(%esp)
  101e5b:	00 
  101e5c:	c7 04 24 66 5f 10 00 	movl   $0x105f66,(%esp)
  101e63:	e8 5c e6 ff ff       	call   1004c4 <debug_panic>

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  101e68:	66 8c cb             	mov    %cs,%bx
  101e6b:	66 89 5d e6          	mov    %bx,-0x1a(%ebp)
        return cs;
  101e6f:	0f b7 45 e6          	movzwl -0x1a(%ebp),%eax

	// General protection fault due to privilege violation
	if (read_cs() & 3) {
  101e73:	0f b7 c0             	movzwl %ax,%eax
  101e76:	83 e0 03             	and    $0x3,%eax
  101e79:	85 c0                	test   %eax,%eax
  101e7b:	74 3a                	je     101eb7 <after_priv+0x2c>
		args.reip = after_priv;
  101e7d:	c7 45 d8 8b 1e 10 00 	movl   $0x101e8b,-0x28(%ebp)
		asm volatile("lidt %0; after_priv:" : : "m" (idt_pd));
  101e84:	0f 01 1d 04 90 10 00 	lidtl  0x109004

00101e8b <after_priv>:
		assert(args.trapno == T_GPFLT);
  101e8b:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101e8e:	83 f8 0d             	cmp    $0xd,%eax
  101e91:	74 24                	je     101eb7 <after_priv+0x2c>
  101e93:	c7 44 24 0c 7c 61 10 	movl   $0x10617c,0xc(%esp)
  101e9a:	00 
  101e9b:	c7 44 24 08 f6 5d 10 	movl   $0x105df6,0x8(%esp)
  101ea2:	00 
  101ea3:	c7 44 24 04 27 01 00 	movl   $0x127,0x4(%esp)
  101eaa:	00 
  101eab:	c7 04 24 66 5f 10 00 	movl   $0x105f66,(%esp)
  101eb2:	e8 0d e6 ff ff       	call   1004c4 <debug_panic>
	}

	// Make sure our stack cookie is still with us
	assert(cookie == 0xfeedface);
  101eb7:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101eba:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  101ebf:	74 24                	je     101ee5 <after_priv+0x5a>
  101ec1:	c7 44 24 0c 0b 61 10 	movl   $0x10610b,0xc(%esp)
  101ec8:	00 
  101ec9:	c7 44 24 08 f6 5d 10 	movl   $0x105df6,0x8(%esp)
  101ed0:	00 
  101ed1:	c7 44 24 04 2b 01 00 	movl   $0x12b,0x4(%esp)
  101ed8:	00 
  101ed9:	c7 04 24 66 5f 10 00 	movl   $0x105f66,(%esp)
  101ee0:	e8 df e5 ff ff       	call   1004c4 <debug_panic>

	*argsp = NULL;	// recovery mechanism not needed anymore
  101ee5:	8b 45 08             	mov    0x8(%ebp),%eax
  101ee8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
  101eee:	83 c4 3c             	add    $0x3c,%esp
  101ef1:	5b                   	pop    %ebx
  101ef2:	5e                   	pop    %esi
  101ef3:	5f                   	pop    %edi
  101ef4:	5d                   	pop    %ebp
  101ef5:	c3                   	ret    
  101ef6:	90                   	nop
  101ef7:	90                   	nop
  101ef8:	90                   	nop
  101ef9:	90                   	nop
  101efa:	90                   	nop
  101efb:	90                   	nop
  101efc:	90                   	nop
  101efd:	90                   	nop
  101efe:	90                   	nop
  101eff:	90                   	nop

00101f00 <vector0>:
.text

/*
 * Lab 1: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(vector0,0)		// divide error
  101f00:	6a 00                	push   $0x0
  101f02:	6a 00                	push   $0x0
  101f04:	e9 f7 01 00 00       	jmp    102100 <_alltraps>
  101f09:	90                   	nop

00101f0a <vector1>:
TRAPHANDLER_NOEC(vector1,1)		// debug exception
  101f0a:	6a 00                	push   $0x0
  101f0c:	6a 01                	push   $0x1
  101f0e:	e9 ed 01 00 00       	jmp    102100 <_alltraps>
  101f13:	90                   	nop

00101f14 <vector2>:
TRAPHANDLER_NOEC(vector2,2)		// non-maskable interrupt
  101f14:	6a 00                	push   $0x0
  101f16:	6a 02                	push   $0x2
  101f18:	e9 e3 01 00 00       	jmp    102100 <_alltraps>
  101f1d:	90                   	nop

00101f1e <vector3>:
TRAPHANDLER_NOEC(vector3,3)		// breakpoint
  101f1e:	6a 00                	push   $0x0
  101f20:	6a 03                	push   $0x3
  101f22:	e9 d9 01 00 00       	jmp    102100 <_alltraps>
  101f27:	90                   	nop

00101f28 <vector4>:
TRAPHANDLER_NOEC(vector4,4)		// overflow
  101f28:	6a 00                	push   $0x0
  101f2a:	6a 04                	push   $0x4
  101f2c:	e9 cf 01 00 00       	jmp    102100 <_alltraps>
  101f31:	90                   	nop

00101f32 <vector5>:
TRAPHANDLER_NOEC(vector5,5)		// bounds check
  101f32:	6a 00                	push   $0x0
  101f34:	6a 05                	push   $0x5
  101f36:	e9 c5 01 00 00       	jmp    102100 <_alltraps>
  101f3b:	90                   	nop

00101f3c <vector6>:
TRAPHANDLER_NOEC(vector6,6)		// illegal opcode
  101f3c:	6a 00                	push   $0x0
  101f3e:	6a 06                	push   $0x6
  101f40:	e9 bb 01 00 00       	jmp    102100 <_alltraps>
  101f45:	90                   	nop

00101f46 <vector7>:
TRAPHANDLER_NOEC(vector7,7)		// device not available 
  101f46:	6a 00                	push   $0x0
  101f48:	6a 07                	push   $0x7
  101f4a:	e9 b1 01 00 00       	jmp    102100 <_alltraps>
  101f4f:	90                   	nop

00101f50 <vector8>:
TRAPHANDLER(vector8,8)			// double fault
  101f50:	6a 08                	push   $0x8
  101f52:	e9 a9 01 00 00       	jmp    102100 <_alltraps>
  101f57:	90                   	nop

00101f58 <vector9>:
TRAPHANDLER_NOEC(vector9,9)		// reserved (not generated by recent processors)
  101f58:	6a 00                	push   $0x0
  101f5a:	6a 09                	push   $0x9
  101f5c:	e9 9f 01 00 00       	jmp    102100 <_alltraps>
  101f61:	90                   	nop

00101f62 <vector10>:
TRAPHANDLER(vector10,10)		// invalid task switch segment
  101f62:	6a 0a                	push   $0xa
  101f64:	e9 97 01 00 00       	jmp    102100 <_alltraps>
  101f69:	90                   	nop

00101f6a <vector11>:
TRAPHANDLER(vector11,11)		// segment not present
  101f6a:	6a 0b                	push   $0xb
  101f6c:	e9 8f 01 00 00       	jmp    102100 <_alltraps>
  101f71:	90                   	nop

00101f72 <vector12>:
TRAPHANDLER(vector12,12)		// stack exception
  101f72:	6a 0c                	push   $0xc
  101f74:	e9 87 01 00 00       	jmp    102100 <_alltraps>
  101f79:	90                   	nop

00101f7a <vector13>:
TRAPHANDLER(vector13,13)		// general protection fault
  101f7a:	6a 0d                	push   $0xd
  101f7c:	e9 7f 01 00 00       	jmp    102100 <_alltraps>
  101f81:	90                   	nop

00101f82 <vector14>:
TRAPHANDLER(vector14,14)		// page fault
  101f82:	6a 0e                	push   $0xe
  101f84:	e9 77 01 00 00       	jmp    102100 <_alltraps>
  101f89:	90                   	nop

00101f8a <vector15>:
TRAPHANDLER_NOEC(vector15,15)		// reserved
  101f8a:	6a 00                	push   $0x0
  101f8c:	6a 0f                	push   $0xf
  101f8e:	e9 6d 01 00 00       	jmp    102100 <_alltraps>
  101f93:	90                   	nop

00101f94 <vector16>:
TRAPHANDLER_NOEC(vector16,16)		// floating point error
  101f94:	6a 00                	push   $0x0
  101f96:	6a 10                	push   $0x10
  101f98:	e9 63 01 00 00       	jmp    102100 <_alltraps>
  101f9d:	90                   	nop

00101f9e <vector17>:
TRAPHANDLER(vector17,17)		// alignment check
  101f9e:	6a 11                	push   $0x11
  101fa0:	e9 5b 01 00 00       	jmp    102100 <_alltraps>
  101fa5:	90                   	nop

00101fa6 <vector18>:
TRAPHANDLER_NOEC(vector18,18)		// machine check
  101fa6:	6a 00                	push   $0x0
  101fa8:	6a 12                	push   $0x12
  101faa:	e9 51 01 00 00       	jmp    102100 <_alltraps>
  101faf:	90                   	nop

00101fb0 <vector19>:
TRAPHANDLER_NOEC(vector19,19)		// SIMD floating point error
  101fb0:	6a 00                	push   $0x0
  101fb2:	6a 13                	push   $0x13
  101fb4:	e9 47 01 00 00       	jmp    102100 <_alltraps>
  101fb9:	90                   	nop

00101fba <vector20>:
TRAPHANDLER_NOEC(vector20,20)
  101fba:	6a 00                	push   $0x0
  101fbc:	6a 14                	push   $0x14
  101fbe:	e9 3d 01 00 00       	jmp    102100 <_alltraps>
  101fc3:	90                   	nop

00101fc4 <vector21>:
TRAPHANDLER_NOEC(vector21,21)
  101fc4:	6a 00                	push   $0x0
  101fc6:	6a 15                	push   $0x15
  101fc8:	e9 33 01 00 00       	jmp    102100 <_alltraps>
  101fcd:	90                   	nop

00101fce <vector22>:
TRAPHANDLER_NOEC(vector22,22)
  101fce:	6a 00                	push   $0x0
  101fd0:	6a 16                	push   $0x16
  101fd2:	e9 29 01 00 00       	jmp    102100 <_alltraps>
  101fd7:	90                   	nop

00101fd8 <vector23>:
TRAPHANDLER_NOEC(vector23,23)
  101fd8:	6a 00                	push   $0x0
  101fda:	6a 17                	push   $0x17
  101fdc:	e9 1f 01 00 00       	jmp    102100 <_alltraps>
  101fe1:	90                   	nop

00101fe2 <vector24>:
TRAPHANDLER_NOEC(vector24,24)
  101fe2:	6a 00                	push   $0x0
  101fe4:	6a 18                	push   $0x18
  101fe6:	e9 15 01 00 00       	jmp    102100 <_alltraps>
  101feb:	90                   	nop

00101fec <vector25>:
TRAPHANDLER_NOEC(vector25,25)
  101fec:	6a 00                	push   $0x0
  101fee:	6a 19                	push   $0x19
  101ff0:	e9 0b 01 00 00       	jmp    102100 <_alltraps>
  101ff5:	90                   	nop

00101ff6 <vector26>:
TRAPHANDLER_NOEC(vector26,26)
  101ff6:	6a 00                	push   $0x0
  101ff8:	6a 1a                	push   $0x1a
  101ffa:	e9 01 01 00 00       	jmp    102100 <_alltraps>
  101fff:	90                   	nop

00102000 <vector27>:
TRAPHANDLER_NOEC(vector27,27)
  102000:	6a 00                	push   $0x0
  102002:	6a 1b                	push   $0x1b
  102004:	e9 f7 00 00 00       	jmp    102100 <_alltraps>
  102009:	90                   	nop

0010200a <vector28>:
TRAPHANDLER_NOEC(vector28,28)
  10200a:	6a 00                	push   $0x0
  10200c:	6a 1c                	push   $0x1c
  10200e:	e9 ed 00 00 00       	jmp    102100 <_alltraps>
  102013:	90                   	nop

00102014 <vector29>:
TRAPHANDLER_NOEC(vector29,29)
  102014:	6a 00                	push   $0x0
  102016:	6a 1d                	push   $0x1d
  102018:	e9 e3 00 00 00       	jmp    102100 <_alltraps>
  10201d:	90                   	nop

0010201e <vector30>:
TRAPHANDLER(vector30,30)
  10201e:	6a 1e                	push   $0x1e
  102020:	e9 db 00 00 00       	jmp    102100 <_alltraps>
  102025:	90                   	nop

00102026 <vector31>:
TRAPHANDLER_NOEC(vector31,31)
  102026:	6a 00                	push   $0x0
  102028:	6a 1f                	push   $0x1f
  10202a:	e9 d1 00 00 00       	jmp    102100 <_alltraps>
  10202f:	90                   	nop

00102030 <vector32>:
TRAPHANDLER_NOEC(vector32,32)
  102030:	6a 00                	push   $0x0
  102032:	6a 20                	push   $0x20
  102034:	e9 c7 00 00 00       	jmp    102100 <_alltraps>
  102039:	90                   	nop

0010203a <vector33>:
TRAPHANDLER_NOEC(vector33,33)
  10203a:	6a 00                	push   $0x0
  10203c:	6a 21                	push   $0x21
  10203e:	e9 bd 00 00 00       	jmp    102100 <_alltraps>
  102043:	90                   	nop

00102044 <vector34>:
TRAPHANDLER_NOEC(vector34,34)
  102044:	6a 00                	push   $0x0
  102046:	6a 22                	push   $0x22
  102048:	e9 b3 00 00 00       	jmp    102100 <_alltraps>
  10204d:	90                   	nop

0010204e <vector35>:
TRAPHANDLER_NOEC(vector35,35)
  10204e:	6a 00                	push   $0x0
  102050:	6a 23                	push   $0x23
  102052:	e9 a9 00 00 00       	jmp    102100 <_alltraps>
  102057:	90                   	nop

00102058 <vector36>:
TRAPHANDLER_NOEC(vector36,36)
  102058:	6a 00                	push   $0x0
  10205a:	6a 24                	push   $0x24
  10205c:	e9 9f 00 00 00       	jmp    102100 <_alltraps>
  102061:	90                   	nop

00102062 <vector37>:
TRAPHANDLER_NOEC(vector37,37)
  102062:	6a 00                	push   $0x0
  102064:	6a 25                	push   $0x25
  102066:	e9 95 00 00 00       	jmp    102100 <_alltraps>
  10206b:	90                   	nop

0010206c <vector38>:
TRAPHANDLER_NOEC(vector38,38)
  10206c:	6a 00                	push   $0x0
  10206e:	6a 26                	push   $0x26
  102070:	e9 8b 00 00 00       	jmp    102100 <_alltraps>
  102075:	90                   	nop

00102076 <vector39>:
TRAPHANDLER_NOEC(vector39,39)
  102076:	6a 00                	push   $0x0
  102078:	6a 27                	push   $0x27
  10207a:	e9 81 00 00 00       	jmp    102100 <_alltraps>
  10207f:	90                   	nop

00102080 <vector40>:
TRAPHANDLER_NOEC(vector40,40)
  102080:	6a 00                	push   $0x0
  102082:	6a 28                	push   $0x28
  102084:	e9 77 00 00 00       	jmp    102100 <_alltraps>
  102089:	90                   	nop

0010208a <vector41>:
TRAPHANDLER_NOEC(vector41,41)
  10208a:	6a 00                	push   $0x0
  10208c:	6a 29                	push   $0x29
  10208e:	e9 6d 00 00 00       	jmp    102100 <_alltraps>
  102093:	90                   	nop

00102094 <vector42>:
TRAPHANDLER_NOEC(vector42,42)
  102094:	6a 00                	push   $0x0
  102096:	6a 2a                	push   $0x2a
  102098:	e9 63 00 00 00       	jmp    102100 <_alltraps>
  10209d:	90                   	nop

0010209e <vector43>:
TRAPHANDLER_NOEC(vector43,43)
  10209e:	6a 00                	push   $0x0
  1020a0:	6a 2b                	push   $0x2b
  1020a2:	e9 59 00 00 00       	jmp    102100 <_alltraps>
  1020a7:	90                   	nop

001020a8 <vector44>:
TRAPHANDLER_NOEC(vector44,44)
  1020a8:	6a 00                	push   $0x0
  1020aa:	6a 2c                	push   $0x2c
  1020ac:	e9 4f 00 00 00       	jmp    102100 <_alltraps>
  1020b1:	90                   	nop

001020b2 <vector45>:
TRAPHANDLER_NOEC(vector45,45)
  1020b2:	6a 00                	push   $0x0
  1020b4:	6a 2d                	push   $0x2d
  1020b6:	e9 45 00 00 00       	jmp    102100 <_alltraps>
  1020bb:	90                   	nop

001020bc <vector46>:
TRAPHANDLER_NOEC(vector46,46)
  1020bc:	6a 00                	push   $0x0
  1020be:	6a 2e                	push   $0x2e
  1020c0:	e9 3b 00 00 00       	jmp    102100 <_alltraps>
  1020c5:	90                   	nop

001020c6 <vector47>:
TRAPHANDLER_NOEC(vector47,47)
  1020c6:	6a 00                	push   $0x0
  1020c8:	6a 2f                	push   $0x2f
  1020ca:	e9 31 00 00 00       	jmp    102100 <_alltraps>
  1020cf:	90                   	nop

001020d0 <vector48>:
TRAPHANDLER_NOEC(vector48,48)
  1020d0:	6a 00                	push   $0x0
  1020d2:	6a 30                	push   $0x30
  1020d4:	e9 27 00 00 00       	jmp    102100 <_alltraps>
  1020d9:	90                   	nop

001020da <vector49>:
TRAPHANDLER_NOEC(vector49,49)
  1020da:	6a 00                	push   $0x0
  1020dc:	6a 31                	push   $0x31
  1020de:	e9 1d 00 00 00       	jmp    102100 <_alltraps>
  1020e3:	90                   	nop

001020e4 <vector50>:
TRAPHANDLER_NOEC(vector50,50)
  1020e4:	6a 00                	push   $0x0
  1020e6:	6a 32                	push   $0x32
  1020e8:	e9 13 00 00 00       	jmp    102100 <_alltraps>
  1020ed:	90                   	nop

001020ee <vector51>:
TRAPHANDLER_NOEC(vector51,51)
  1020ee:	6a 00                	push   $0x0
  1020f0:	6a 33                	push   $0x33
  1020f2:	e9 09 00 00 00       	jmp    102100 <_alltraps>
  1020f7:	89 f6                	mov    %esi,%esi
  1020f9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00102100 <_alltraps>:
 */
.globl	_alltraps
.type	_alltraps,@function
.p2align 4, 0x90
_alltraps:
	pushl %ds
  102100:	1e                   	push   %ds
	pushl %es
  102101:	06                   	push   %es
	pushl %fs
  102102:	0f a0                	push   %fs
	pushl %gs
  102104:	0f a8                	push   %gs
	pushal
  102106:	60                   	pusha  

	movw $CPU_GDT_KDATA, %ax
  102107:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
  10210b:	8e d8                	mov    %eax,%ds
	movw %ax, %es
  10210d:	8e c0                	mov    %eax,%es
	//there is no SEG_KCPU in PIOS ,
	//so do not need to reset %fs , %gs

	pushl %esp //oesp
  10210f:	54                   	push   %esp
	call trap
  102110:	e8 46 f8 ff ff       	call   10195b <trap>
	addl $4, %esp 
  102115:	83 c4 04             	add    $0x4,%esp
  102118:	90                   	nop
  102119:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00102120 <trap_return>:
.p2align 4, 0x90		/* 16-byte alignment, nop filled */
trap_return:
/*
 * Lab 1: Your code here for trap_return
 */ //1: jmp 1b // just spin
	movl 4(%esp), %esp
  102120:	8b 64 24 04          	mov    0x4(%esp),%esp
	popal 
  102124:	61                   	popa   
	popl %gs
  102125:	0f a9                	pop    %gs
	popl %fs
  102127:	0f a1                	pop    %fs
	popl %es
  102129:	07                   	pop    %es
	popl %ds
  10212a:	1f                   	pop    %ds
	addl $8, %esp
  10212b:	83 c4 08             	add    $0x8,%esp
	sti
  10212e:	fb                   	sti    
	iret
  10212f:	cf                   	iret   

00102130 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  102130:	55                   	push   %ebp
  102131:	89 e5                	mov    %esp,%ebp
  102133:	53                   	push   %ebx
  102134:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  102137:	89 e3                	mov    %esp,%ebx
  102139:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  10213c:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  10213f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  102142:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102145:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10214a:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  10214d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102150:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  102156:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  10215b:	74 24                	je     102181 <cpu_cur+0x51>
  10215d:	c7 44 24 0c 30 63 10 	movl   $0x106330,0xc(%esp)
  102164:	00 
  102165:	c7 44 24 08 46 63 10 	movl   $0x106346,0x8(%esp)
  10216c:	00 
  10216d:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  102174:	00 
  102175:	c7 04 24 5b 63 10 00 	movl   $0x10635b,(%esp)
  10217c:	e8 43 e3 ff ff       	call   1004c4 <debug_panic>
	return c;
  102181:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  102184:	83 c4 24             	add    $0x24,%esp
  102187:	5b                   	pop    %ebx
  102188:	5d                   	pop    %ebp
  102189:	c3                   	ret    

0010218a <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  10218a:	55                   	push   %ebp
  10218b:	89 e5                	mov    %esp,%ebp
  10218d:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  102190:	e8 9b ff ff ff       	call   102130 <cpu_cur>
  102195:	3d 00 80 10 00       	cmp    $0x108000,%eax
  10219a:	0f 94 c0             	sete   %al
  10219d:	0f b6 c0             	movzbl %al,%eax
}
  1021a0:	c9                   	leave  
  1021a1:	c3                   	ret    

001021a2 <sum>:
volatile struct ioapic *ioapic;


static uint8_t
sum(uint8_t * addr, int len)
{
  1021a2:	55                   	push   %ebp
  1021a3:	89 e5                	mov    %esp,%ebp
  1021a5:	83 ec 10             	sub    $0x10,%esp
	int i, sum;

	sum = 0;
  1021a8:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
	for (i = 0; i < len; i++)
  1021af:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  1021b6:	eb 15                	jmp    1021cd <sum+0x2b>
		sum += addr[i];
  1021b8:	8b 55 fc             	mov    -0x4(%ebp),%edx
  1021bb:	8b 45 08             	mov    0x8(%ebp),%eax
  1021be:	01 d0                	add    %edx,%eax
  1021c0:	0f b6 00             	movzbl (%eax),%eax
  1021c3:	0f b6 c0             	movzbl %al,%eax
  1021c6:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uint8_t * addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
  1021c9:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  1021cd:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1021d0:	3b 45 0c             	cmp    0xc(%ebp),%eax
  1021d3:	7c e3                	jl     1021b8 <sum+0x16>
		sum += addr[i];
	return sum;
  1021d5:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
  1021d8:	c9                   	leave  
  1021d9:	c3                   	ret    

001021da <mpsearch1>:

//Look for an MP structure in the len bytes at addr.
static struct mp *
mpsearch1(uint8_t * addr, int len)
{
  1021da:	55                   	push   %ebp
  1021db:	89 e5                	mov    %esp,%ebp
  1021dd:	83 ec 28             	sub    $0x28,%esp
	uint8_t *e, *p;

	e = addr + len;
  1021e0:	8b 55 0c             	mov    0xc(%ebp),%edx
  1021e3:	8b 45 08             	mov    0x8(%ebp),%eax
  1021e6:	01 d0                	add    %edx,%eax
  1021e8:	89 45 f0             	mov    %eax,-0x10(%ebp)
	for (p = addr; p < e; p += sizeof(struct mp))
  1021eb:	8b 45 08             	mov    0x8(%ebp),%eax
  1021ee:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1021f1:	eb 3f                	jmp    102232 <mpsearch1+0x58>
		if (memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
  1021f3:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  1021fa:	00 
  1021fb:	c7 44 24 04 68 63 10 	movl   $0x106368,0x4(%esp)
  102202:	00 
  102203:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102206:	89 04 24             	mov    %eax,(%esp)
  102209:	e8 1c 33 00 00       	call   10552a <memcmp>
  10220e:	85 c0                	test   %eax,%eax
  102210:	75 1c                	jne    10222e <mpsearch1+0x54>
  102212:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
  102219:	00 
  10221a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10221d:	89 04 24             	mov    %eax,(%esp)
  102220:	e8 7d ff ff ff       	call   1021a2 <sum>
  102225:	84 c0                	test   %al,%al
  102227:	75 05                	jne    10222e <mpsearch1+0x54>
			return (struct mp *) p;
  102229:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10222c:	eb 11                	jmp    10223f <mpsearch1+0x65>
mpsearch1(uint8_t * addr, int len)
{
	uint8_t *e, *p;

	e = addr + len;
	for (p = addr; p < e; p += sizeof(struct mp))
  10222e:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
  102232:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102235:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  102238:	72 b9                	jb     1021f3 <mpsearch1+0x19>
		if (memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
			return (struct mp *) p;
	return 0;
  10223a:	b8 00 00 00 00       	mov    $0x0,%eax
}
  10223f:	c9                   	leave  
  102240:	c3                   	ret    

00102241 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp *
mpsearch(void)
{
  102241:	55                   	push   %ebp
  102242:	89 e5                	mov    %esp,%ebp
  102244:	83 ec 28             	sub    $0x28,%esp
	uint8_t          *bda;
	uint32_t            p;
	struct mp      *mp;

	bda = (uint8_t *) 0x400;
  102247:	c7 45 f4 00 04 00 00 	movl   $0x400,-0xc(%ebp)
	if ((p = ((bda[0x0F] << 8) | bda[0x0E]) << 4)) {
  10224e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102251:	83 c0 0f             	add    $0xf,%eax
  102254:	0f b6 00             	movzbl (%eax),%eax
  102257:	0f b6 c0             	movzbl %al,%eax
  10225a:	89 c2                	mov    %eax,%edx
  10225c:	c1 e2 08             	shl    $0x8,%edx
  10225f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102262:	83 c0 0e             	add    $0xe,%eax
  102265:	0f b6 00             	movzbl (%eax),%eax
  102268:	0f b6 c0             	movzbl %al,%eax
  10226b:	09 d0                	or     %edx,%eax
  10226d:	c1 e0 04             	shl    $0x4,%eax
  102270:	89 45 f0             	mov    %eax,-0x10(%ebp)
  102273:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  102277:	74 21                	je     10229a <mpsearch+0x59>
		if ((mp = mpsearch1((uint8_t *) p, 1024)))
  102279:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10227c:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
  102283:	00 
  102284:	89 04 24             	mov    %eax,(%esp)
  102287:	e8 4e ff ff ff       	call   1021da <mpsearch1>
  10228c:	89 45 ec             	mov    %eax,-0x14(%ebp)
  10228f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  102293:	74 50                	je     1022e5 <mpsearch+0xa4>
			return mp;
  102295:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102298:	eb 5f                	jmp    1022f9 <mpsearch+0xb8>
	} else {
		p = ((bda[0x14] << 8) | bda[0x13]) * 1024;
  10229a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10229d:	83 c0 14             	add    $0x14,%eax
  1022a0:	0f b6 00             	movzbl (%eax),%eax
  1022a3:	0f b6 c0             	movzbl %al,%eax
  1022a6:	89 c2                	mov    %eax,%edx
  1022a8:	c1 e2 08             	shl    $0x8,%edx
  1022ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1022ae:	83 c0 13             	add    $0x13,%eax
  1022b1:	0f b6 00             	movzbl (%eax),%eax
  1022b4:	0f b6 c0             	movzbl %al,%eax
  1022b7:	09 d0                	or     %edx,%eax
  1022b9:	c1 e0 0a             	shl    $0xa,%eax
  1022bc:	89 45 f0             	mov    %eax,-0x10(%ebp)
		if ((mp = mpsearch1((uint8_t *) p - 1024, 1024)))
  1022bf:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1022c2:	2d 00 04 00 00       	sub    $0x400,%eax
  1022c7:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
  1022ce:	00 
  1022cf:	89 04 24             	mov    %eax,(%esp)
  1022d2:	e8 03 ff ff ff       	call   1021da <mpsearch1>
  1022d7:	89 45 ec             	mov    %eax,-0x14(%ebp)
  1022da:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  1022de:	74 05                	je     1022e5 <mpsearch+0xa4>
			return mp;
  1022e0:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1022e3:	eb 14                	jmp    1022f9 <mpsearch+0xb8>
	}
	return mpsearch1((uint8_t *) 0xF0000, 0x10000);
  1022e5:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  1022ec:	00 
  1022ed:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
  1022f4:	e8 e1 fe ff ff       	call   1021da <mpsearch1>
}
  1022f9:	c9                   	leave  
  1022fa:	c3                   	ret    

001022fb <mpconfig>:
// don 't accept the default configurations (physaddr == 0).
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf *
mpconfig(struct mp **pmp) {
  1022fb:	55                   	push   %ebp
  1022fc:	89 e5                	mov    %esp,%ebp
  1022fe:	83 ec 28             	sub    $0x28,%esp
	struct mpconf  *conf;
	struct mp      *mp;

	if ((mp = mpsearch()) == 0 || mp->physaddr == 0)
  102301:	e8 3b ff ff ff       	call   102241 <mpsearch>
  102306:	89 45 f4             	mov    %eax,-0xc(%ebp)
  102309:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  10230d:	74 0a                	je     102319 <mpconfig+0x1e>
  10230f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102312:	8b 40 04             	mov    0x4(%eax),%eax
  102315:	85 c0                	test   %eax,%eax
  102317:	75 07                	jne    102320 <mpconfig+0x25>
		return 0;
  102319:	b8 00 00 00 00       	mov    $0x0,%eax
  10231e:	eb 7b                	jmp    10239b <mpconfig+0xa0>
	conf = (struct mpconf *) mp->physaddr;
  102320:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102323:	8b 40 04             	mov    0x4(%eax),%eax
  102326:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (memcmp(conf, "PCMP", 4) != 0)
  102329:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  102330:	00 
  102331:	c7 44 24 04 6d 63 10 	movl   $0x10636d,0x4(%esp)
  102338:	00 
  102339:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10233c:	89 04 24             	mov    %eax,(%esp)
  10233f:	e8 e6 31 00 00       	call   10552a <memcmp>
  102344:	85 c0                	test   %eax,%eax
  102346:	74 07                	je     10234f <mpconfig+0x54>
		return 0;
  102348:	b8 00 00 00 00       	mov    $0x0,%eax
  10234d:	eb 4c                	jmp    10239b <mpconfig+0xa0>
	if (conf->version != 1 && conf->version != 4)
  10234f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102352:	0f b6 40 06          	movzbl 0x6(%eax),%eax
  102356:	3c 01                	cmp    $0x1,%al
  102358:	74 12                	je     10236c <mpconfig+0x71>
  10235a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10235d:	0f b6 40 06          	movzbl 0x6(%eax),%eax
  102361:	3c 04                	cmp    $0x4,%al
  102363:	74 07                	je     10236c <mpconfig+0x71>
		return 0;
  102365:	b8 00 00 00 00       	mov    $0x0,%eax
  10236a:	eb 2f                	jmp    10239b <mpconfig+0xa0>
	if (sum((uint8_t *) conf, conf->length) != 0)
  10236c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10236f:	0f b7 40 04          	movzwl 0x4(%eax),%eax
  102373:	0f b7 c0             	movzwl %ax,%eax
  102376:	89 44 24 04          	mov    %eax,0x4(%esp)
  10237a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10237d:	89 04 24             	mov    %eax,(%esp)
  102380:	e8 1d fe ff ff       	call   1021a2 <sum>
  102385:	84 c0                	test   %al,%al
  102387:	74 07                	je     102390 <mpconfig+0x95>
		return 0;
  102389:	b8 00 00 00 00       	mov    $0x0,%eax
  10238e:	eb 0b                	jmp    10239b <mpconfig+0xa0>
       *pmp = mp;
  102390:	8b 45 08             	mov    0x8(%ebp),%eax
  102393:	8b 55 f4             	mov    -0xc(%ebp),%edx
  102396:	89 10                	mov    %edx,(%eax)
	return conf;
  102398:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  10239b:	c9                   	leave  
  10239c:	c3                   	ret    

0010239d <mp_init>:

void
mp_init(void)
{
  10239d:	55                   	push   %ebp
  10239e:	89 e5                	mov    %esp,%ebp
  1023a0:	53                   	push   %ebx
  1023a1:	83 ec 64             	sub    $0x64,%esp
	struct mp      *mp;
	struct mpconf  *conf;
	struct mpproc  *proc;
	struct mpioapic *mpio;

	if (!cpu_onboot())	// only do once, on the boot CPU
  1023a4:	e8 e1 fd ff ff       	call   10218a <cpu_onboot>
  1023a9:	85 c0                	test   %eax,%eax
  1023ab:	0f 84 75 01 00 00    	je     102526 <mp_init+0x189>
		return;

	if ((conf = mpconfig(&mp)) == 0)
  1023b1:	8d 45 c4             	lea    -0x3c(%ebp),%eax
  1023b4:	89 04 24             	mov    %eax,(%esp)
  1023b7:	e8 3f ff ff ff       	call   1022fb <mpconfig>
  1023bc:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1023bf:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  1023c3:	0f 84 5d 01 00 00    	je     102526 <mp_init+0x189>
		return; // Not a multiprocessor machine - just use boot CPU.

	ismp = 1;
  1023c9:	c7 05 f0 f3 30 00 01 	movl   $0x1,0x30f3f0
  1023d0:	00 00 00 
	lapic = (uint32_t *) conf->lapicaddr;
  1023d3:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1023d6:	8b 40 24             	mov    0x24(%eax),%eax
  1023d9:	a3 ec fa 30 00       	mov    %eax,0x30faec
	for (p = (uint8_t *) (conf + 1), e = (uint8_t *) conf + conf->length;
  1023de:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1023e1:	83 c0 2c             	add    $0x2c,%eax
  1023e4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1023e7:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1023ea:	0f b7 40 04          	movzwl 0x4(%eax),%eax
  1023ee:	0f b7 d0             	movzwl %ax,%edx
  1023f1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1023f4:	01 d0                	add    %edx,%eax
  1023f6:	89 45 ec             	mov    %eax,-0x14(%ebp)
  1023f9:	e9 cc 00 00 00       	jmp    1024ca <mp_init+0x12d>
			p < e;) {
		switch (*p) {
  1023fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102401:	0f b6 00             	movzbl (%eax),%eax
  102404:	0f b6 c0             	movzbl %al,%eax
  102407:	83 f8 04             	cmp    $0x4,%eax
  10240a:	0f 87 90 00 00 00    	ja     1024a0 <mp_init+0x103>
  102410:	8b 04 85 a0 63 10 00 	mov    0x1063a0(,%eax,4),%eax
  102417:	ff e0                	jmp    *%eax
		case MPPROC:
			proc = (struct mpproc *) p;
  102419:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10241c:	89 45 e8             	mov    %eax,-0x18(%ebp)
			p += sizeof(struct mpproc);
  10241f:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
			if (!(proc->flags & MPENAB))
  102423:	8b 45 e8             	mov    -0x18(%ebp),%eax
  102426:	0f b6 40 03          	movzbl 0x3(%eax),%eax
  10242a:	0f b6 c0             	movzbl %al,%eax
  10242d:	83 e0 01             	and    $0x1,%eax
  102430:	85 c0                	test   %eax,%eax
  102432:	0f 84 91 00 00 00    	je     1024c9 <mp_init+0x12c>
				continue;	// processor disabled

			// Get a cpu struct and kernel stack for this CPU.
			cpu *c = (proc->flags & MPBOOT)
  102438:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10243b:	0f b6 40 03          	movzbl 0x3(%eax),%eax
  10243f:	0f b6 c0             	movzbl %al,%eax
  102442:	83 e0 02             	and    $0x2,%eax
					? &cpu_boot : cpu_alloc();
  102445:	85 c0                	test   %eax,%eax
  102447:	75 07                	jne    102450 <mp_init+0xb3>
  102449:	e8 b0 ee ff ff       	call   1012fe <cpu_alloc>
  10244e:	eb 05                	jmp    102455 <mp_init+0xb8>
  102450:	b8 00 80 10 00       	mov    $0x108000,%eax
			p += sizeof(struct mpproc);
			if (!(proc->flags & MPENAB))
				continue;	// processor disabled

			// Get a cpu struct and kernel stack for this CPU.
			cpu *c = (proc->flags & MPBOOT)
  102455:	89 45 e4             	mov    %eax,-0x1c(%ebp)
					? &cpu_boot : cpu_alloc();
			c->id = proc->apicid;
  102458:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10245b:	0f b6 50 01          	movzbl 0x1(%eax),%edx
  10245f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  102462:	88 90 ac 00 00 00    	mov    %dl,0xac(%eax)
			ncpu++;
  102468:	a1 f4 f3 30 00       	mov    0x30f3f4,%eax
  10246d:	83 c0 01             	add    $0x1,%eax
  102470:	a3 f4 f3 30 00       	mov    %eax,0x30f3f4
			continue;
  102475:	eb 53                	jmp    1024ca <mp_init+0x12d>
		case MPIOAPIC:
			mpio = (struct mpioapic *) p;
  102477:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10247a:	89 45 e0             	mov    %eax,-0x20(%ebp)
			p += sizeof(struct mpioapic);
  10247d:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
			ioapicid = mpio->apicno;
  102481:	8b 45 e0             	mov    -0x20(%ebp),%eax
  102484:	0f b6 40 01          	movzbl 0x1(%eax),%eax
  102488:	a2 e8 f3 30 00       	mov    %al,0x30f3e8
			ioapic = (struct ioapic *) mpio->addr;
  10248d:	8b 45 e0             	mov    -0x20(%ebp),%eax
  102490:	8b 40 04             	mov    0x4(%eax),%eax
  102493:	a3 ec f3 30 00       	mov    %eax,0x30f3ec
			continue;
  102498:	eb 30                	jmp    1024ca <mp_init+0x12d>
		case MPBUS:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
  10249a:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
			continue;
  10249e:	eb 2a                	jmp    1024ca <mp_init+0x12d>
		default:
			panic("mpinit: unknown config type %x\n", *p);
  1024a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1024a3:	0f b6 00             	movzbl (%eax),%eax
  1024a6:	0f b6 c0             	movzbl %al,%eax
  1024a9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1024ad:	c7 44 24 08 74 63 10 	movl   $0x106374,0x8(%esp)
  1024b4:	00 
  1024b5:	c7 44 24 04 92 00 00 	movl   $0x92,0x4(%esp)
  1024bc:	00 
  1024bd:	c7 04 24 94 63 10 00 	movl   $0x106394,(%esp)
  1024c4:	e8 fb df ff ff       	call   1004c4 <debug_panic>
		switch (*p) {
		case MPPROC:
			proc = (struct mpproc *) p;
			p += sizeof(struct mpproc);
			if (!(proc->flags & MPENAB))
				continue;	// processor disabled
  1024c9:	90                   	nop
	if ((conf = mpconfig(&mp)) == 0)
		return; // Not a multiprocessor machine - just use boot CPU.

	ismp = 1;
	lapic = (uint32_t *) conf->lapicaddr;
	for (p = (uint8_t *) (conf + 1), e = (uint8_t *) conf + conf->length;
  1024ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1024cd:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  1024d0:	0f 82 28 ff ff ff    	jb     1023fe <mp_init+0x61>
			continue;
		default:
			panic("mpinit: unknown config type %x\n", *p);
		}
	}
	if (mp->imcrp) {
  1024d6:	8b 45 c4             	mov    -0x3c(%ebp),%eax
  1024d9:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
  1024dd:	84 c0                	test   %al,%al
  1024df:	74 45                	je     102526 <mp_init+0x189>
  1024e1:	c7 45 dc 22 00 00 00 	movl   $0x22,-0x24(%ebp)
  1024e8:	c6 45 db 70          	movb   $0x70,-0x25(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1024ec:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  1024f0:	8b 55 dc             	mov    -0x24(%ebp),%edx
  1024f3:	ee                   	out    %al,(%dx)
  1024f4:	c7 45 d4 23 00 00 00 	movl   $0x23,-0x2c(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1024fb:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  1024fe:	89 55 b4             	mov    %edx,-0x4c(%ebp)
  102501:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  102504:	ec                   	in     (%dx),%al
  102505:	89 c3                	mov    %eax,%ebx
  102507:	88 5d d3             	mov    %bl,-0x2d(%ebp)
	return data;
  10250a:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
		// Bochs doesn 't support IMCR, so this doesn' t run on Bochs.
		// But it would on real hardware.
		outb(0x22, 0x70);		// Select IMCR
		outb(0x23, inb(0x23) | 1);	// Mask external interrupts.
  10250e:	83 c8 01             	or     $0x1,%eax
  102511:	0f b6 c0             	movzbl %al,%eax
  102514:	c7 45 cc 23 00 00 00 	movl   $0x23,-0x34(%ebp)
  10251b:	88 45 cb             	mov    %al,-0x35(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10251e:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
  102522:	8b 55 cc             	mov    -0x34(%ebp),%edx
  102525:	ee                   	out    %al,(%dx)
	}
}
  102526:	83 c4 64             	add    $0x64,%esp
  102529:	5b                   	pop    %ebx
  10252a:	5d                   	pop    %ebp
  10252b:	c3                   	ret    

0010252c <xchg>:
}

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  10252c:	55                   	push   %ebp
  10252d:	89 e5                	mov    %esp,%ebp
  10252f:	53                   	push   %ebx
  102530:	83 ec 10             	sub    $0x10,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
	       "+m" (*addr), "=a" (result) :
  102533:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  102536:	8b 45 0c             	mov    0xc(%ebp),%eax
	       "+m" (*addr), "=a" (result) :
  102539:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  10253c:	89 c3                	mov    %eax,%ebx
  10253e:	89 d8                	mov    %ebx,%eax
  102540:	f0 87 02             	lock xchg %eax,(%edx)
  102543:	89 c3                	mov    %eax,%ebx
  102545:	89 5d f8             	mov    %ebx,-0x8(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  102548:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
  10254b:	83 c4 10             	add    $0x10,%esp
  10254e:	5b                   	pop    %ebx
  10254f:	5d                   	pop    %ebp
  102550:	c3                   	ret    

00102551 <pause>:
	return result;
}

static inline void
pause(void)
{
  102551:	55                   	push   %ebp
  102552:	89 e5                	mov    %esp,%ebp
	asm volatile("pause" : : : "memory");
  102554:	f3 90                	pause  
}
  102556:	5d                   	pop    %ebp
  102557:	c3                   	ret    

00102558 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  102558:	55                   	push   %ebp
  102559:	89 e5                	mov    %esp,%ebp
  10255b:	53                   	push   %ebx
  10255c:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10255f:	89 e3                	mov    %esp,%ebx
  102561:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  102564:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  102567:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10256a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10256d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  102572:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  102575:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102578:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  10257e:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  102583:	74 24                	je     1025a9 <cpu_cur+0x51>
  102585:	c7 44 24 0c b4 63 10 	movl   $0x1063b4,0xc(%esp)
  10258c:	00 
  10258d:	c7 44 24 08 ca 63 10 	movl   $0x1063ca,0x8(%esp)
  102594:	00 
  102595:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  10259c:	00 
  10259d:	c7 04 24 df 63 10 00 	movl   $0x1063df,(%esp)
  1025a4:	e8 1b df ff ff       	call   1004c4 <debug_panic>
	return c;
  1025a9:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  1025ac:	83 c4 24             	add    $0x24,%esp
  1025af:	5b                   	pop    %ebx
  1025b0:	5d                   	pop    %ebp
  1025b1:	c3                   	ret    

001025b2 <spinlock_init_>:
#include <kern/cons.h>


void
spinlock_init_(struct spinlock *lk, const char *file, int line)
{
  1025b2:	55                   	push   %ebp
  1025b3:	89 e5                	mov    %esp,%ebp
	lk->file = file;
  1025b5:	8b 45 08             	mov    0x8(%ebp),%eax
  1025b8:	8b 55 0c             	mov    0xc(%ebp),%edx
  1025bb:	89 50 04             	mov    %edx,0x4(%eax)
	lk->line = line;
  1025be:	8b 45 08             	mov    0x8(%ebp),%eax
  1025c1:	8b 55 10             	mov    0x10(%ebp),%edx
  1025c4:	89 50 08             	mov    %edx,0x8(%eax)
	lk->locked = 0;
  1025c7:	8b 45 08             	mov    0x8(%ebp),%eax
  1025ca:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	lk->cpu = NULL;
  1025d0:	8b 45 08             	mov    0x8(%ebp),%eax
  1025d3:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
}
  1025da:	5d                   	pop    %ebp
  1025db:	c3                   	ret    

001025dc <spinlock_acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spinlock_acquire(struct spinlock *lk)
{
  1025dc:	55                   	push   %ebp
  1025dd:	89 e5                	mov    %esp,%ebp
  1025df:	53                   	push   %ebx
  1025e0:	83 ec 24             	sub    $0x24,%esp
	if(spinlock_holding(lk))
  1025e3:	8b 45 08             	mov    0x8(%ebp),%eax
  1025e6:	89 04 24             	mov    %eax,(%esp)
  1025e9:	e8 c4 00 00 00       	call   1026b2 <spinlock_holding>
  1025ee:	85 c0                	test   %eax,%eax
  1025f0:	74 23                	je     102615 <spinlock_acquire+0x39>
        panic("Already holding lock.");
  1025f2:	c7 44 24 08 ec 63 10 	movl   $0x1063ec,0x8(%esp)
  1025f9:	00 
  1025fa:	c7 44 24 04 24 00 00 	movl   $0x24,0x4(%esp)
  102601:	00 
  102602:	c7 04 24 02 64 10 00 	movl   $0x106402,(%esp)
  102609:	e8 b6 de ff ff       	call   1004c4 <debug_panic>
	while(xchg(&(lk->locked), 1) != 0)
	  pause();
  10260e:	e8 3e ff ff ff       	call   102551 <pause>
  102613:	eb 01                	jmp    102616 <spinlock_acquire+0x3a>
void
spinlock_acquire(struct spinlock *lk)
{
	if(spinlock_holding(lk))
        panic("Already holding lock.");
	while(xchg(&(lk->locked), 1) != 0)
  102615:	90                   	nop
  102616:	8b 45 08             	mov    0x8(%ebp),%eax
  102619:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  102620:	00 
  102621:	89 04 24             	mov    %eax,(%esp)
  102624:	e8 03 ff ff ff       	call   10252c <xchg>
  102629:	85 c0                	test   %eax,%eax
  10262b:	75 e1                	jne    10260e <spinlock_acquire+0x32>
	  pause();
	lk->cpu = cpu_cur();
  10262d:	e8 26 ff ff ff       	call   102558 <cpu_cur>
  102632:	8b 55 08             	mov    0x8(%ebp),%edx
  102635:	89 42 0c             	mov    %eax,0xc(%edx)
	debug_trace(read_ebp(), lk->eips);
  102638:	8b 45 08             	mov    0x8(%ebp),%eax
  10263b:	8d 50 10             	lea    0x10(%eax),%edx

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  10263e:	89 eb                	mov    %ebp,%ebx
  102640:	89 5d f4             	mov    %ebx,-0xc(%ebp)
        return ebp;
  102643:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102646:	89 54 24 04          	mov    %edx,0x4(%esp)
  10264a:	89 04 24             	mov    %eax,(%esp)
  10264d:	e8 81 df ff ff       	call   1005d3 <debug_trace>
}
  102652:	83 c4 24             	add    $0x24,%esp
  102655:	5b                   	pop    %ebx
  102656:	5d                   	pop    %ebp
  102657:	c3                   	ret    

00102658 <spinlock_release>:

// Release the lock.
void
spinlock_release(struct spinlock *lk)
{
  102658:	55                   	push   %ebp
  102659:	89 e5                	mov    %esp,%ebp
  10265b:	83 ec 18             	sub    $0x18,%esp
	if(!spinlock_holding(lk))
  10265e:	8b 45 08             	mov    0x8(%ebp),%eax
  102661:	89 04 24             	mov    %eax,(%esp)
  102664:	e8 49 00 00 00       	call   1026b2 <spinlock_holding>
  102669:	85 c0                	test   %eax,%eax
  10266b:	75 1c                	jne    102689 <spinlock_release+0x31>
        panic("Not holding lock");
  10266d:	c7 44 24 08 12 64 10 	movl   $0x106412,0x8(%esp)
  102674:	00 
  102675:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
  10267c:	00 
  10267d:	c7 04 24 02 64 10 00 	movl   $0x106402,(%esp)
  102684:	e8 3b de ff ff       	call   1004c4 <debug_panic>
	lk->cpu = 0;
  102689:	8b 45 08             	mov    0x8(%ebp),%eax
  10268c:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
	lk->eips[0] = 0;
  102693:	8b 45 08             	mov    0x8(%ebp),%eax
  102696:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
	xchg(&(lk->locked), 0);
  10269d:	8b 45 08             	mov    0x8(%ebp),%eax
  1026a0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1026a7:	00 
  1026a8:	89 04 24             	mov    %eax,(%esp)
  1026ab:	e8 7c fe ff ff       	call   10252c <xchg>
}
  1026b0:	c9                   	leave  
  1026b1:	c3                   	ret    

001026b2 <spinlock_holding>:

// Check whether this cpu is holding the lock.
int
spinlock_holding(spinlock *lock)
{
  1026b2:	55                   	push   %ebp
  1026b3:	89 e5                	mov    %esp,%ebp
  1026b5:	53                   	push   %ebx
  1026b6:	83 ec 04             	sub    $0x4,%esp
	return (lock->locked) && (lock->cpu == cpu_cur());
  1026b9:	8b 45 08             	mov    0x8(%ebp),%eax
  1026bc:	8b 00                	mov    (%eax),%eax
  1026be:	85 c0                	test   %eax,%eax
  1026c0:	74 16                	je     1026d8 <spinlock_holding+0x26>
  1026c2:	8b 45 08             	mov    0x8(%ebp),%eax
  1026c5:	8b 58 0c             	mov    0xc(%eax),%ebx
  1026c8:	e8 8b fe ff ff       	call   102558 <cpu_cur>
  1026cd:	39 c3                	cmp    %eax,%ebx
  1026cf:	75 07                	jne    1026d8 <spinlock_holding+0x26>
  1026d1:	b8 01 00 00 00       	mov    $0x1,%eax
  1026d6:	eb 05                	jmp    1026dd <spinlock_holding+0x2b>
  1026d8:	b8 00 00 00 00       	mov    $0x0,%eax
}
  1026dd:	83 c4 04             	add    $0x4,%esp
  1026e0:	5b                   	pop    %ebx
  1026e1:	5d                   	pop    %ebp
  1026e2:	c3                   	ret    

001026e3 <spinlock_godeep>:
// Function that simply recurses to a specified depth.
// The useless return value and volatile parameter are
// so GCC doesn't collapse it via tail-call elimination.
int gcc_noinline
spinlock_godeep(volatile int depth, spinlock* lk)
{
  1026e3:	55                   	push   %ebp
  1026e4:	89 e5                	mov    %esp,%ebp
  1026e6:	83 ec 18             	sub    $0x18,%esp
	if (depth==0) { spinlock_acquire(lk); return 1; }
  1026e9:	8b 45 08             	mov    0x8(%ebp),%eax
  1026ec:	85 c0                	test   %eax,%eax
  1026ee:	75 12                	jne    102702 <spinlock_godeep+0x1f>
  1026f0:	8b 45 0c             	mov    0xc(%ebp),%eax
  1026f3:	89 04 24             	mov    %eax,(%esp)
  1026f6:	e8 e1 fe ff ff       	call   1025dc <spinlock_acquire>
  1026fb:	b8 01 00 00 00       	mov    $0x1,%eax
  102700:	eb 1b                	jmp    10271d <spinlock_godeep+0x3a>
	else return spinlock_godeep(depth-1, lk) * depth;
  102702:	8b 45 08             	mov    0x8(%ebp),%eax
  102705:	8d 50 ff             	lea    -0x1(%eax),%edx
  102708:	8b 45 0c             	mov    0xc(%ebp),%eax
  10270b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10270f:	89 14 24             	mov    %edx,(%esp)
  102712:	e8 cc ff ff ff       	call   1026e3 <spinlock_godeep>
  102717:	8b 55 08             	mov    0x8(%ebp),%edx
  10271a:	0f af c2             	imul   %edx,%eax
}
  10271d:	c9                   	leave  
  10271e:	c3                   	ret    

0010271f <spinlock_check>:

void spinlock_check()
{
  10271f:	55                   	push   %ebp
  102720:	89 e5                	mov    %esp,%ebp
  102722:	56                   	push   %esi
  102723:	53                   	push   %ebx
  102724:	83 ec 40             	sub    $0x40,%esp
  102727:	89 e0                	mov    %esp,%eax
  102729:	89 c3                	mov    %eax,%ebx
	const int NUMLOCKS=10;
  10272b:	c7 45 e8 0a 00 00 00 	movl   $0xa,-0x18(%ebp)
	const int NUMRUNS=5;
  102732:	c7 45 e4 05 00 00 00 	movl   $0x5,-0x1c(%ebp)
	int i,j,run;
	const char* file = "spinlock_check";
  102739:	c7 45 e0 23 64 10 00 	movl   $0x106423,-0x20(%ebp)
	spinlock locks[NUMLOCKS];
  102740:	8b 45 e8             	mov    -0x18(%ebp),%eax
  102743:	83 e8 01             	sub    $0x1,%eax
  102746:	89 45 dc             	mov    %eax,-0x24(%ebp)
  102749:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10274c:	ba 00 00 00 00       	mov    $0x0,%edx
  102751:	69 f2 c0 01 00 00    	imul   $0x1c0,%edx,%esi
  102757:	6b c8 00             	imul   $0x0,%eax,%ecx
  10275a:	01 ce                	add    %ecx,%esi
  10275c:	b9 c0 01 00 00       	mov    $0x1c0,%ecx
  102761:	f7 e1                	mul    %ecx
  102763:	8d 0c 16             	lea    (%esi,%edx,1),%ecx
  102766:	89 ca                	mov    %ecx,%edx
  102768:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10276b:	c1 e0 03             	shl    $0x3,%eax
  10276e:	8b 45 e8             	mov    -0x18(%ebp),%eax
  102771:	ba 00 00 00 00       	mov    $0x0,%edx
  102776:	69 f2 c0 01 00 00    	imul   $0x1c0,%edx,%esi
  10277c:	6b c8 00             	imul   $0x0,%eax,%ecx
  10277f:	01 ce                	add    %ecx,%esi
  102781:	b9 c0 01 00 00       	mov    $0x1c0,%ecx
  102786:	f7 e1                	mul    %ecx
  102788:	8d 0c 16             	lea    (%esi,%edx,1),%ecx
  10278b:	89 ca                	mov    %ecx,%edx
  10278d:	8b 45 e8             	mov    -0x18(%ebp),%eax
  102790:	c1 e0 03             	shl    $0x3,%eax
  102793:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  10279a:	89 d1                	mov    %edx,%ecx
  10279c:	29 c1                	sub    %eax,%ecx
  10279e:	89 c8                	mov    %ecx,%eax
  1027a0:	8d 50 03             	lea    0x3(%eax),%edx
  1027a3:	b8 10 00 00 00       	mov    $0x10,%eax
  1027a8:	83 e8 01             	sub    $0x1,%eax
  1027ab:	01 d0                	add    %edx,%eax
  1027ad:	c7 45 d4 10 00 00 00 	movl   $0x10,-0x2c(%ebp)
  1027b4:	ba 00 00 00 00       	mov    $0x0,%edx
  1027b9:	f7 75 d4             	divl   -0x2c(%ebp)
  1027bc:	6b c0 10             	imul   $0x10,%eax,%eax
  1027bf:	29 c4                	sub    %eax,%esp
  1027c1:	8d 44 24 10          	lea    0x10(%esp),%eax
  1027c5:	83 c0 03             	add    $0x3,%eax
  1027c8:	c1 e8 02             	shr    $0x2,%eax
  1027cb:	c1 e0 02             	shl    $0x2,%eax
  1027ce:	89 45 d8             	mov    %eax,-0x28(%ebp)

	// Initialize the locks
	for(i=0;i<NUMLOCKS;i++) spinlock_init_(&locks[i], file, 0);
  1027d1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  1027d8:	eb 2f                	jmp    102809 <spinlock_check+0xea>
  1027da:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1027dd:	c1 e0 03             	shl    $0x3,%eax
  1027e0:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1027e7:	29 c2                	sub    %eax,%edx
  1027e9:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1027ec:	01 c2                	add    %eax,%edx
  1027ee:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1027f5:	00 
  1027f6:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1027f9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1027fd:	89 14 24             	mov    %edx,(%esp)
  102800:	e8 ad fd ff ff       	call   1025b2 <spinlock_init_>
  102805:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  102809:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10280c:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  10280f:	7c c9                	jl     1027da <spinlock_check+0xbb>
	// Make sure that all locks have CPU set to NULL initially
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu==NULL);
  102811:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  102818:	eb 46                	jmp    102860 <spinlock_check+0x141>
  10281a:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  10281d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102820:	c1 e0 03             	shl    $0x3,%eax
  102823:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  10282a:	29 c2                	sub    %eax,%edx
  10282c:	8d 04 11             	lea    (%ecx,%edx,1),%eax
  10282f:	83 c0 0c             	add    $0xc,%eax
  102832:	8b 00                	mov    (%eax),%eax
  102834:	85 c0                	test   %eax,%eax
  102836:	74 24                	je     10285c <spinlock_check+0x13d>
  102838:	c7 44 24 0c 32 64 10 	movl   $0x106432,0xc(%esp)
  10283f:	00 
  102840:	c7 44 24 08 ca 63 10 	movl   $0x1063ca,0x8(%esp)
  102847:	00 
  102848:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
  10284f:	00 
  102850:	c7 04 24 02 64 10 00 	movl   $0x106402,(%esp)
  102857:	e8 68 dc ff ff       	call   1004c4 <debug_panic>
  10285c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  102860:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102863:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  102866:	7c b2                	jl     10281a <spinlock_check+0xfb>
	// Make sure that all locks have the correct debug info.
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].file==file);
  102868:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  10286f:	eb 47                	jmp    1028b8 <spinlock_check+0x199>
  102871:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  102874:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102877:	c1 e0 03             	shl    $0x3,%eax
  10287a:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102881:	29 c2                	sub    %eax,%edx
  102883:	8d 04 11             	lea    (%ecx,%edx,1),%eax
  102886:	83 c0 04             	add    $0x4,%eax
  102889:	8b 00                	mov    (%eax),%eax
  10288b:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  10288e:	74 24                	je     1028b4 <spinlock_check+0x195>
  102890:	c7 44 24 0c 45 64 10 	movl   $0x106445,0xc(%esp)
  102897:	00 
  102898:	c7 44 24 08 ca 63 10 	movl   $0x1063ca,0x8(%esp)
  10289f:	00 
  1028a0:	c7 44 24 04 54 00 00 	movl   $0x54,0x4(%esp)
  1028a7:	00 
  1028a8:	c7 04 24 02 64 10 00 	movl   $0x106402,(%esp)
  1028af:	e8 10 dc ff ff       	call   1004c4 <debug_panic>
  1028b4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  1028b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1028bb:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  1028be:	7c b1                	jl     102871 <spinlock_check+0x152>

	for (run=0;run<NUMRUNS;run++) 
  1028c0:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  1028c7:	e9 fc 02 00 00       	jmp    102bc8 <spinlock_check+0x4a9>
	{
		// Lock all locks
		for(i=0;i<NUMLOCKS;i++)
  1028cc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  1028d3:	eb 27                	jmp    1028fc <spinlock_check+0x1dd>
			spinlock_godeep(i, &locks[i]);
  1028d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1028d8:	c1 e0 03             	shl    $0x3,%eax
  1028db:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1028e2:	29 c2                	sub    %eax,%edx
  1028e4:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1028e7:	01 d0                	add    %edx,%eax
  1028e9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1028ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1028f0:	89 04 24             	mov    %eax,(%esp)
  1028f3:	e8 eb fd ff ff       	call   1026e3 <spinlock_godeep>
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].file==file);

	for (run=0;run<NUMRUNS;run++) 
	{
		// Lock all locks
		for(i=0;i<NUMLOCKS;i++)
  1028f8:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  1028fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1028ff:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  102902:	7c d1                	jl     1028d5 <spinlock_check+0x1b6>
			spinlock_godeep(i, &locks[i]);

		// Make sure that all locks have the right CPU
		for(i=0;i<NUMLOCKS;i++)
  102904:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  10290b:	eb 4b                	jmp    102958 <spinlock_check+0x239>
			assert(locks[i].cpu == cpu_cur());
  10290d:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  102910:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102913:	c1 e0 03             	shl    $0x3,%eax
  102916:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  10291d:	29 c2                	sub    %eax,%edx
  10291f:	8d 04 11             	lea    (%ecx,%edx,1),%eax
  102922:	83 c0 0c             	add    $0xc,%eax
  102925:	8b 30                	mov    (%eax),%esi
  102927:	e8 2c fc ff ff       	call   102558 <cpu_cur>
  10292c:	39 c6                	cmp    %eax,%esi
  10292e:	74 24                	je     102954 <spinlock_check+0x235>
  102930:	c7 44 24 0c 59 64 10 	movl   $0x106459,0xc(%esp)
  102937:	00 
  102938:	c7 44 24 08 ca 63 10 	movl   $0x1063ca,0x8(%esp)
  10293f:	00 
  102940:	c7 44 24 04 5e 00 00 	movl   $0x5e,0x4(%esp)
  102947:	00 
  102948:	c7 04 24 02 64 10 00 	movl   $0x106402,(%esp)
  10294f:	e8 70 db ff ff       	call   1004c4 <debug_panic>
		// Lock all locks
		for(i=0;i<NUMLOCKS;i++)
			spinlock_godeep(i, &locks[i]);

		// Make sure that all locks have the right CPU
		for(i=0;i<NUMLOCKS;i++)
  102954:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  102958:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10295b:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  10295e:	7c ad                	jl     10290d <spinlock_check+0x1ee>
			assert(locks[i].cpu == cpu_cur());
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++)
  102960:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  102967:	eb 48                	jmp    1029b1 <spinlock_check+0x292>
			assert(spinlock_holding(&locks[i]) != 0);
  102969:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10296c:	c1 e0 03             	shl    $0x3,%eax
  10296f:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102976:	29 c2                	sub    %eax,%edx
  102978:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10297b:	01 d0                	add    %edx,%eax
  10297d:	89 04 24             	mov    %eax,(%esp)
  102980:	e8 2d fd ff ff       	call   1026b2 <spinlock_holding>
  102985:	85 c0                	test   %eax,%eax
  102987:	75 24                	jne    1029ad <spinlock_check+0x28e>
  102989:	c7 44 24 0c 74 64 10 	movl   $0x106474,0xc(%esp)
  102990:	00 
  102991:	c7 44 24 08 ca 63 10 	movl   $0x1063ca,0x8(%esp)
  102998:	00 
  102999:	c7 44 24 04 61 00 00 	movl   $0x61,0x4(%esp)
  1029a0:	00 
  1029a1:	c7 04 24 02 64 10 00 	movl   $0x106402,(%esp)
  1029a8:	e8 17 db ff ff       	call   1004c4 <debug_panic>

		// Make sure that all locks have the right CPU
		for(i=0;i<NUMLOCKS;i++)
			assert(locks[i].cpu == cpu_cur());
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++)
  1029ad:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  1029b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1029b4:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  1029b7:	7c b0                	jl     102969 <spinlock_check+0x24a>
			assert(spinlock_holding(&locks[i]) != 0);
		// Make sure that top i frames are somewhere in godeep.
		for(i=0;i<NUMLOCKS;i++) 
  1029b9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  1029c0:	e9 bb 00 00 00       	jmp    102a80 <spinlock_check+0x361>
		{
			for(j=0; j<=i && j < DEBUG_TRACEFRAMES ; j++) 
  1029c5:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  1029cc:	e9 99 00 00 00       	jmp    102a6a <spinlock_check+0x34b>
			{
				assert(locks[i].eips[j] >=
  1029d1:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  1029d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1029d7:	01 c0                	add    %eax,%eax
  1029d9:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1029e0:	29 c2                	sub    %eax,%edx
  1029e2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1029e5:	01 d0                	add    %edx,%eax
  1029e7:	83 c0 04             	add    $0x4,%eax
  1029ea:	8b 14 81             	mov    (%ecx,%eax,4),%edx
  1029ed:	b8 e3 26 10 00       	mov    $0x1026e3,%eax
  1029f2:	39 c2                	cmp    %eax,%edx
  1029f4:	73 24                	jae    102a1a <spinlock_check+0x2fb>
  1029f6:	c7 44 24 0c 98 64 10 	movl   $0x106498,0xc(%esp)
  1029fd:	00 
  1029fe:	c7 44 24 08 ca 63 10 	movl   $0x1063ca,0x8(%esp)
  102a05:	00 
  102a06:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
  102a0d:	00 
  102a0e:	c7 04 24 02 64 10 00 	movl   $0x106402,(%esp)
  102a15:	e8 aa da ff ff       	call   1004c4 <debug_panic>
					(uint32_t)spinlock_godeep);
				assert(locks[i].eips[j] <
  102a1a:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  102a1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102a20:	01 c0                	add    %eax,%eax
  102a22:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102a29:	29 c2                	sub    %eax,%edx
  102a2b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102a2e:	01 d0                	add    %edx,%eax
  102a30:	83 c0 04             	add    $0x4,%eax
  102a33:	8b 04 81             	mov    (%ecx,%eax,4),%eax
  102a36:	ba e3 26 10 00       	mov    $0x1026e3,%edx
  102a3b:	83 c2 64             	add    $0x64,%edx
  102a3e:	39 d0                	cmp    %edx,%eax
  102a40:	72 24                	jb     102a66 <spinlock_check+0x347>
  102a42:	c7 44 24 0c c8 64 10 	movl   $0x1064c8,0xc(%esp)
  102a49:	00 
  102a4a:	c7 44 24 08 ca 63 10 	movl   $0x1063ca,0x8(%esp)
  102a51:	00 
  102a52:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  102a59:	00 
  102a5a:	c7 04 24 02 64 10 00 	movl   $0x106402,(%esp)
  102a61:	e8 5e da ff ff       	call   1004c4 <debug_panic>
		for(i=0;i<NUMLOCKS;i++)
			assert(spinlock_holding(&locks[i]) != 0);
		// Make sure that top i frames are somewhere in godeep.
		for(i=0;i<NUMLOCKS;i++) 
		{
			for(j=0; j<=i && j < DEBUG_TRACEFRAMES ; j++) 
  102a66:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  102a6a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102a6d:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  102a70:	7f 0a                	jg     102a7c <spinlock_check+0x35d>
  102a72:	83 7d f0 09          	cmpl   $0x9,-0x10(%ebp)
  102a76:	0f 8e 55 ff ff ff    	jle    1029d1 <spinlock_check+0x2b2>
			assert(locks[i].cpu == cpu_cur());
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++)
			assert(spinlock_holding(&locks[i]) != 0);
		// Make sure that top i frames are somewhere in godeep.
		for(i=0;i<NUMLOCKS;i++) 
  102a7c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  102a80:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102a83:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  102a86:	0f 8c 39 ff ff ff    	jl     1029c5 <spinlock_check+0x2a6>
					(uint32_t)spinlock_godeep+100);
			}
		}

		// Release all locks
		for(i=0;i<NUMLOCKS;i++) spinlock_release(&locks[i]);
  102a8c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  102a93:	eb 20                	jmp    102ab5 <spinlock_check+0x396>
  102a95:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102a98:	c1 e0 03             	shl    $0x3,%eax
  102a9b:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102aa2:	29 c2                	sub    %eax,%edx
  102aa4:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102aa7:	01 d0                	add    %edx,%eax
  102aa9:	89 04 24             	mov    %eax,(%esp)
  102aac:	e8 a7 fb ff ff       	call   102658 <spinlock_release>
  102ab1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  102ab5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102ab8:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  102abb:	7c d8                	jl     102a95 <spinlock_check+0x376>
		// Make sure that the CPU has been cleared
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu == NULL);
  102abd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  102ac4:	eb 46                	jmp    102b0c <spinlock_check+0x3ed>
  102ac6:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  102ac9:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102acc:	c1 e0 03             	shl    $0x3,%eax
  102acf:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102ad6:	29 c2                	sub    %eax,%edx
  102ad8:	8d 04 11             	lea    (%ecx,%edx,1),%eax
  102adb:	83 c0 0c             	add    $0xc,%eax
  102ade:	8b 00                	mov    (%eax),%eax
  102ae0:	85 c0                	test   %eax,%eax
  102ae2:	74 24                	je     102b08 <spinlock_check+0x3e9>
  102ae4:	c7 44 24 0c f9 64 10 	movl   $0x1064f9,0xc(%esp)
  102aeb:	00 
  102aec:	c7 44 24 08 ca 63 10 	movl   $0x1063ca,0x8(%esp)
  102af3:	00 
  102af4:	c7 44 24 04 71 00 00 	movl   $0x71,0x4(%esp)
  102afb:	00 
  102afc:	c7 04 24 02 64 10 00 	movl   $0x106402,(%esp)
  102b03:	e8 bc d9 ff ff       	call   1004c4 <debug_panic>
  102b08:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  102b0c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102b0f:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  102b12:	7c b2                	jl     102ac6 <spinlock_check+0x3a7>
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].eips[0]==0);
  102b14:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  102b1b:	eb 46                	jmp    102b63 <spinlock_check+0x444>
  102b1d:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  102b20:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102b23:	c1 e0 03             	shl    $0x3,%eax
  102b26:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102b2d:	29 c2                	sub    %eax,%edx
  102b2f:	8d 04 11             	lea    (%ecx,%edx,1),%eax
  102b32:	83 c0 10             	add    $0x10,%eax
  102b35:	8b 00                	mov    (%eax),%eax
  102b37:	85 c0                	test   %eax,%eax
  102b39:	74 24                	je     102b5f <spinlock_check+0x440>
  102b3b:	c7 44 24 0c 0e 65 10 	movl   $0x10650e,0xc(%esp)
  102b42:	00 
  102b43:	c7 44 24 08 ca 63 10 	movl   $0x1063ca,0x8(%esp)
  102b4a:	00 
  102b4b:	c7 44 24 04 72 00 00 	movl   $0x72,0x4(%esp)
  102b52:	00 
  102b53:	c7 04 24 02 64 10 00 	movl   $0x106402,(%esp)
  102b5a:	e8 65 d9 ff ff       	call   1004c4 <debug_panic>
  102b5f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  102b63:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102b66:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  102b69:	7c b2                	jl     102b1d <spinlock_check+0x3fe>
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++) assert(spinlock_holding(&locks[i]) == 0);
  102b6b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  102b72:	eb 48                	jmp    102bbc <spinlock_check+0x49d>
  102b74:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102b77:	c1 e0 03             	shl    $0x3,%eax
  102b7a:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102b81:	29 c2                	sub    %eax,%edx
  102b83:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102b86:	01 d0                	add    %edx,%eax
  102b88:	89 04 24             	mov    %eax,(%esp)
  102b8b:	e8 22 fb ff ff       	call   1026b2 <spinlock_holding>
  102b90:	85 c0                	test   %eax,%eax
  102b92:	74 24                	je     102bb8 <spinlock_check+0x499>
  102b94:	c7 44 24 0c 24 65 10 	movl   $0x106524,0xc(%esp)
  102b9b:	00 
  102b9c:	c7 44 24 08 ca 63 10 	movl   $0x1063ca,0x8(%esp)
  102ba3:	00 
  102ba4:	c7 44 24 04 74 00 00 	movl   $0x74,0x4(%esp)
  102bab:	00 
  102bac:	c7 04 24 02 64 10 00 	movl   $0x106402,(%esp)
  102bb3:	e8 0c d9 ff ff       	call   1004c4 <debug_panic>
  102bb8:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  102bbc:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102bbf:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  102bc2:	7c b0                	jl     102b74 <spinlock_check+0x455>
	// Make sure that all locks have CPU set to NULL initially
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu==NULL);
	// Make sure that all locks have the correct debug info.
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].file==file);

	for (run=0;run<NUMRUNS;run++) 
  102bc4:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  102bc8:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102bcb:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  102bce:	0f 8c f8 fc ff ff    	jl     1028cc <spinlock_check+0x1ad>
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu == NULL);
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].eips[0]==0);
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++) assert(spinlock_holding(&locks[i]) == 0);
	}
	cprintf("spinlock_check() succeeded!\n");
  102bd4:	c7 04 24 45 65 10 00 	movl   $0x106545,(%esp)
  102bdb:	e8 fc 25 00 00       	call   1051dc <cprintf>
  102be0:	89 dc                	mov    %ebx,%esp
}
  102be2:	8d 65 f8             	lea    -0x8(%ebp),%esp
  102be5:	5b                   	pop    %ebx
  102be6:	5e                   	pop    %esi
  102be7:	5d                   	pop    %ebp
  102be8:	c3                   	ret    
  102be9:	90                   	nop
  102bea:	90                   	nop
  102beb:	90                   	nop

00102bec <xchg>:
}

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  102bec:	55                   	push   %ebp
  102bed:	89 e5                	mov    %esp,%ebp
  102bef:	53                   	push   %ebx
  102bf0:	83 ec 10             	sub    $0x10,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
	       "+m" (*addr), "=a" (result) :
  102bf3:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  102bf6:	8b 45 0c             	mov    0xc(%ebp),%eax
	       "+m" (*addr), "=a" (result) :
  102bf9:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  102bfc:	89 c3                	mov    %eax,%ebx
  102bfe:	89 d8                	mov    %ebx,%eax
  102c00:	f0 87 02             	lock xchg %eax,(%edx)
  102c03:	89 c3                	mov    %eax,%ebx
  102c05:	89 5d f8             	mov    %ebx,-0x8(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  102c08:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
  102c0b:	83 c4 10             	add    $0x10,%esp
  102c0e:	5b                   	pop    %ebx
  102c0f:	5d                   	pop    %ebp
  102c10:	c3                   	ret    

00102c11 <lockadd>:

// Atomically add incr to *addr.
static inline void
lockadd(volatile int32_t *addr, int32_t incr)
{
  102c11:	55                   	push   %ebp
  102c12:	89 e5                	mov    %esp,%ebp
	asm volatile("lock; addl %1,%0" : "+m" (*addr) : "r" (incr) : "cc");
  102c14:	8b 45 08             	mov    0x8(%ebp),%eax
  102c17:	8b 55 0c             	mov    0xc(%ebp),%edx
  102c1a:	8b 4d 08             	mov    0x8(%ebp),%ecx
  102c1d:	f0 01 10             	lock add %edx,(%eax)
}
  102c20:	5d                   	pop    %ebp
  102c21:	c3                   	ret    

00102c22 <pause>:
	return result;
}

static inline void
pause(void)
{
  102c22:	55                   	push   %ebp
  102c23:	89 e5                	mov    %esp,%ebp
	asm volatile("pause" : : : "memory");
  102c25:	f3 90                	pause  
}
  102c27:	5d                   	pop    %ebp
  102c28:	c3                   	ret    

00102c29 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  102c29:	55                   	push   %ebp
  102c2a:	89 e5                	mov    %esp,%ebp
  102c2c:	53                   	push   %ebx
  102c2d:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  102c30:	89 e3                	mov    %esp,%ebx
  102c32:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  102c35:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  102c38:	89 45 f4             	mov    %eax,-0xc(%ebp)
  102c3b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102c3e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  102c43:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  102c46:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102c49:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  102c4f:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  102c54:	74 24                	je     102c7a <cpu_cur+0x51>
  102c56:	c7 44 24 0c 64 65 10 	movl   $0x106564,0xc(%esp)
  102c5d:	00 
  102c5e:	c7 44 24 08 7a 65 10 	movl   $0x10657a,0x8(%esp)
  102c65:	00 
  102c66:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  102c6d:	00 
  102c6e:	c7 04 24 8f 65 10 00 	movl   $0x10658f,(%esp)
  102c75:	e8 4a d8 ff ff       	call   1004c4 <debug_panic>
	return c;
  102c7a:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  102c7d:	83 c4 24             	add    $0x24,%esp
  102c80:	5b                   	pop    %ebx
  102c81:	5d                   	pop    %ebp
  102c82:	c3                   	ret    

00102c83 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  102c83:	55                   	push   %ebp
  102c84:	89 e5                	mov    %esp,%ebp
  102c86:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  102c89:	e8 9b ff ff ff       	call   102c29 <cpu_cur>
  102c8e:	3d 00 80 10 00       	cmp    $0x108000,%eax
  102c93:	0f 94 c0             	sete   %al
  102c96:	0f b6 c0             	movzbl %al,%eax
}
  102c99:	c9                   	leave  
  102c9a:	c3                   	ret    

00102c9b <proc_init>:
proc *proc_queue_head;
spinlock _queue_lock;

void
proc_init(void)
{
  102c9b:	55                   	push   %ebp
  102c9c:	89 e5                	mov    %esp,%ebp
  102c9e:	83 ec 18             	sub    $0x18,%esp
	if (!cpu_onboot())
  102ca1:	e8 dd ff ff ff       	call   102c83 <cpu_onboot>
  102ca6:	85 c0                	test   %eax,%eax
  102ca8:	74 28                	je     102cd2 <proc_init+0x37>
	  return;
	spinlock_init(&_queue_lock);
  102caa:	c7 44 24 08 23 00 00 	movl   $0x23,0x8(%esp)
  102cb1:	00 
  102cb2:	c7 44 24 04 9c 65 10 	movl   $0x10659c,0x4(%esp)
  102cb9:	00 
  102cba:	c7 04 24 00 f4 30 00 	movl   $0x30f400,(%esp)
  102cc1:	e8 ec f8 ff ff       	call   1025b2 <spinlock_init_>
	proc_queue_head = NULL;	
  102cc6:	c7 05 e4 fa 30 00 00 	movl   $0x0,0x30fae4
  102ccd:	00 00 00 
  102cd0:	eb 01                	jmp    102cd3 <proc_init+0x38>

void
proc_init(void)
{
	if (!cpu_onboot())
	  return;
  102cd2:	90                   	nop
	spinlock_init(&_queue_lock);
	proc_queue_head = NULL;	
}
  102cd3:	c9                   	leave  
  102cd4:	c3                   	ret    

00102cd5 <proc_alloc>:

// Allocate and initialize a new proc as child 'cn' of parent 'p'.
// Returns NULL if no physical memory available.
proc *
proc_alloc(proc *p, uint32_t cn)
{
  102cd5:	55                   	push   %ebp
  102cd6:	89 e5                	mov    %esp,%ebp
  102cd8:	83 ec 28             	sub    $0x28,%esp
	pageinfo *pi = mem_alloc();
  102cdb:	e8 05 df ff ff       	call   100be5 <mem_alloc>
  102ce0:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (!pi)
  102ce3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  102ce7:	75 0a                	jne    102cf3 <proc_alloc+0x1e>
	  return NULL;
  102ce9:	b8 00 00 00 00       	mov    $0x0,%eax
  102cee:	e9 60 01 00 00       	jmp    102e53 <proc_alloc+0x17e>
  102cf3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102cf6:	89 45 ec             	mov    %eax,-0x14(%ebp)

// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  102cf9:	a1 e4 f3 30 00       	mov    0x30f3e4,%eax
  102cfe:	83 c0 08             	add    $0x8,%eax
  102d01:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  102d04:	76 15                	jbe    102d1b <proc_alloc+0x46>
  102d06:	a1 e4 f3 30 00       	mov    0x30f3e4,%eax
  102d0b:	8b 15 98 f3 10 00    	mov    0x10f398,%edx
  102d11:	c1 e2 03             	shl    $0x3,%edx
  102d14:	01 d0                	add    %edx,%eax
  102d16:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  102d19:	72 24                	jb     102d3f <proc_alloc+0x6a>
  102d1b:	c7 44 24 0c a8 65 10 	movl   $0x1065a8,0xc(%esp)
  102d22:	00 
  102d23:	c7 44 24 08 7a 65 10 	movl   $0x10657a,0x8(%esp)
  102d2a:	00 
  102d2b:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
  102d32:	00 
  102d33:	c7 04 24 df 65 10 00 	movl   $0x1065df,(%esp)
  102d3a:	e8 85 d7 ff ff       	call   1004c4 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  102d3f:	a1 e4 f3 30 00       	mov    0x30f3e4,%eax
  102d44:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  102d49:	c1 ea 0c             	shr    $0xc,%edx
  102d4c:	c1 e2 03             	shl    $0x3,%edx
  102d4f:	01 d0                	add    %edx,%eax
  102d51:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  102d54:	72 3b                	jb     102d91 <proc_alloc+0xbc>
  102d56:	a1 e4 f3 30 00       	mov    0x30f3e4,%eax
  102d5b:	ba ef fa 30 00       	mov    $0x30faef,%edx
  102d60:	c1 ea 0c             	shr    $0xc,%edx
  102d63:	c1 e2 03             	shl    $0x3,%edx
  102d66:	01 d0                	add    %edx,%eax
  102d68:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  102d6b:	77 24                	ja     102d91 <proc_alloc+0xbc>
  102d6d:	c7 44 24 0c ec 65 10 	movl   $0x1065ec,0xc(%esp)
  102d74:	00 
  102d75:	c7 44 24 08 7a 65 10 	movl   $0x10657a,0x8(%esp)
  102d7c:	00 
  102d7d:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  102d84:	00 
  102d85:	c7 04 24 df 65 10 00 	movl   $0x1065df,(%esp)
  102d8c:	e8 33 d7 ff ff       	call   1004c4 <debug_panic>

	lockadd(&pi->refcount, 1);
  102d91:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102d94:	83 c0 04             	add    $0x4,%eax
  102d97:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  102d9e:	00 
  102d9f:	89 04 24             	mov    %eax,(%esp)
  102da2:	e8 6a fe ff ff       	call   102c11 <lockadd>
	mem_incref(pi);
	proc *cp = (proc*)mem_pi2ptr(pi);
  102da7:	8b 55 f4             	mov    -0xc(%ebp),%edx
  102daa:	a1 e4 f3 30 00       	mov    0x30f3e4,%eax
  102daf:	89 d1                	mov    %edx,%ecx
  102db1:	29 c1                	sub    %eax,%ecx
  102db3:	89 c8                	mov    %ecx,%eax
  102db5:	c1 f8 03             	sar    $0x3,%eax
  102db8:	c1 e0 0c             	shl    $0xc,%eax
  102dbb:	89 45 f0             	mov    %eax,-0x10(%ebp)
	memset(cp, 0, sizeof(proc));
  102dbe:	c7 44 24 08 a0 06 00 	movl   $0x6a0,0x8(%esp)
  102dc5:	00 
  102dc6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  102dcd:	00 
  102dce:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102dd1:	89 04 24             	mov    %eax,(%esp)
  102dd4:	e8 e8 25 00 00       	call   1053c1 <memset>
	spinlock_init(&cp->lock);
  102dd9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102ddc:	c7 44 24 08 32 00 00 	movl   $0x32,0x8(%esp)
  102de3:	00 
  102de4:	c7 44 24 04 9c 65 10 	movl   $0x10659c,0x4(%esp)
  102deb:	00 
  102dec:	89 04 24             	mov    %eax,(%esp)
  102def:	e8 be f7 ff ff       	call   1025b2 <spinlock_init_>
	cp->parent = p;
  102df4:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102df7:	8b 55 08             	mov    0x8(%ebp),%edx
  102dfa:	89 50 38             	mov    %edx,0x38(%eax)
	cp->state = PROC_STOP;
  102dfd:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102e00:	c7 80 3c 04 00 00 00 	movl   $0x0,0x43c(%eax)
  102e07:	00 00 00 
	// Integer register state
	cp->sv.tf.ds = CPU_GDT_UDATA | 3;
  102e0a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102e0d:	66 c7 80 7c 04 00 00 	movw   $0x23,0x47c(%eax)
  102e14:	23 00 
	cp->sv.tf.es = CPU_GDT_UDATA | 3;
  102e16:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102e19:	66 c7 80 78 04 00 00 	movw   $0x23,0x478(%eax)
  102e20:	23 00 
	cp->sv.tf.cs = CPU_GDT_UCODE | 3;
  102e22:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102e25:	66 c7 80 8c 04 00 00 	movw   $0x1b,0x48c(%eax)
  102e2c:	1b 00 
	cp->sv.tf.ss = CPU_GDT_UDATA | 3;
  102e2e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102e31:	66 c7 80 98 04 00 00 	movw   $0x23,0x498(%eax)
  102e38:	23 00 
	//if the proc is root proc, return cp  directly
	if (p)
  102e3a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  102e3e:	74 10                	je     102e50 <proc_alloc+0x17b>
	  p->child[cn] = cp;
  102e40:	8b 45 08             	mov    0x8(%ebp),%eax
  102e43:	8b 55 0c             	mov    0xc(%ebp),%edx
  102e46:	8d 4a 0c             	lea    0xc(%edx),%ecx
  102e49:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102e4c:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
	return cp;
  102e50:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  102e53:	c9                   	leave  
  102e54:	c3                   	ret    

00102e55 <proc_ready>:

// Put process p in the ready state and add it to the ready queue.
void
proc_ready(proc *p)
{
  102e55:	55                   	push   %ebp
  102e56:	89 e5                	mov    %esp,%ebp
  102e58:	83 ec 28             	sub    $0x28,%esp
        //when setting the proc info ,we should set proc->lock
	spinlock_acquire(&p->lock);
  102e5b:	8b 45 08             	mov    0x8(%ebp),%eax
  102e5e:	89 04 24             	mov    %eax,(%esp)
  102e61:	e8 76 f7 ff ff       	call   1025dc <spinlock_acquire>
	p->state = PROC_READY;
  102e66:	8b 45 08             	mov    0x8(%ebp),%eax
  102e69:	c7 80 3c 04 00 00 01 	movl   $0x1,0x43c(%eax)
  102e70:	00 00 00 
	p->readynext = NULL;
  102e73:	8b 45 08             	mov    0x8(%ebp),%eax
  102e76:	c7 80 40 04 00 00 00 	movl   $0x0,0x440(%eax)
  102e7d:	00 00 00 
	spinlock_release(&p->lock);
  102e80:	8b 45 08             	mov    0x8(%ebp),%eax
  102e83:	89 04 24             	mov    %eax,(%esp)
  102e86:	e8 cd f7 ff ff       	call   102658 <spinlock_release>
	//when setting the proc ready queue ,we shoule set queue_lock
	spinlock_acquire(&_queue_lock);
  102e8b:	c7 04 24 00 f4 30 00 	movl   $0x30f400,(%esp)
  102e92:	e8 45 f7 ff ff       	call   1025dc <spinlock_acquire>
	proc *tmp = proc_queue_head;
  102e97:	a1 e4 fa 30 00       	mov    0x30fae4,%eax
  102e9c:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if(!tmp){//the ready queue is empty
  102e9f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  102ea3:	75 24                	jne    102ec9 <proc_ready+0x74>
	  proc_queue_head = p;
  102ea5:	8b 45 08             	mov    0x8(%ebp),%eax
  102ea8:	a3 e4 fa 30 00       	mov    %eax,0x30fae4
	  spinlock_release(&_queue_lock);
  102ead:	c7 04 24 00 f4 30 00 	movl   $0x30f400,(%esp)
  102eb4:	e8 9f f7 ff ff       	call   102658 <spinlock_release>
	  return ;
  102eb9:	eb 34                	jmp    102eef <proc_ready+0x9a>
	}
	while(tmp->readynext){
	  //get the ready proc at the ready queue tail
	  tmp = tmp->readynext;
  102ebb:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102ebe:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  102ec4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  102ec7:	eb 01                	jmp    102eca <proc_ready+0x75>
	if(!tmp){//the ready queue is empty
	  proc_queue_head = p;
	  spinlock_release(&_queue_lock);
	  return ;
	}
	while(tmp->readynext){
  102ec9:	90                   	nop
  102eca:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102ecd:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  102ed3:	85 c0                	test   %eax,%eax
  102ed5:	75 e4                	jne    102ebb <proc_ready+0x66>
	  //get the ready proc at the ready queue tail
	  tmp = tmp->readynext;
	}
	tmp->readynext = p;
  102ed7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102eda:	8b 55 08             	mov    0x8(%ebp),%edx
  102edd:	89 90 40 04 00 00    	mov    %edx,0x440(%eax)
	spinlock_release(&_queue_lock);
  102ee3:	c7 04 24 00 f4 30 00 	movl   $0x30f400,(%esp)
  102eea:	e8 69 f7 ff ff       	call   102658 <spinlock_release>
}
  102eef:	c9                   	leave  
  102ef0:	c3                   	ret    

00102ef1 <proc_save>:
//	-1	if we entered the kernel via a trap before executing an insn
//	0	if we entered via a syscall and must abort/rollback the syscall
//	1	if we entered via a syscall and are completing the syscall
void
proc_save(proc *p, trapframe *tf, int entry)
{
  102ef1:	55                   	push   %ebp
  102ef2:	89 e5                	mov    %esp,%ebp
  102ef4:	57                   	push   %edi
  102ef5:	56                   	push   %esi
  102ef6:	53                   	push   %ebx
	p->sv.tf = *tf;
  102ef7:	8b 55 08             	mov    0x8(%ebp),%edx
  102efa:	8b 45 0c             	mov    0xc(%ebp),%eax
  102efd:	8d 9a 50 04 00 00    	lea    0x450(%edx),%ebx
  102f03:	89 c2                	mov    %eax,%edx
  102f05:	b8 13 00 00 00       	mov    $0x13,%eax
  102f0a:	89 df                	mov    %ebx,%edi
  102f0c:	89 d6                	mov    %edx,%esi
  102f0e:	89 c1                	mov    %eax,%ecx
  102f10:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	if(entry == 0)
  102f12:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  102f16:	75 15                	jne    102f2d <proc_save+0x3c>
	  p->sv.tf.eip -= 2;
  102f18:	8b 45 08             	mov    0x8(%ebp),%eax
  102f1b:	8b 80 88 04 00 00    	mov    0x488(%eax),%eax
  102f21:	8d 50 fe             	lea    -0x2(%eax),%edx
  102f24:	8b 45 08             	mov    0x8(%ebp),%eax
  102f27:	89 90 88 04 00 00    	mov    %edx,0x488(%eax)
	//the int instruction's length is 16 bits
	//such annns INT 21 ,the mechine code is 'cd 15' that needs 2 bytes
	//so when need to rollback ,sub 2 is nessesary
	//rollback the syscall, 
	//because the syscall pushes eip of the next instruction
}
  102f2d:	5b                   	pop    %ebx
  102f2e:	5e                   	pop    %esi
  102f2f:	5f                   	pop    %edi
  102f30:	5d                   	pop    %ebp
  102f31:	c3                   	ret    

00102f32 <proc_wait>:
// Go to sleep waiting for a given child process to finish running.
// Parent process 'p' must be running and locked on entry.
// The supplied trapframe represents p's register state on syscall entry.
void gcc_noreturn
proc_wait(proc *p, proc *cp, trapframe *tf)
{
  102f32:	55                   	push   %ebp
  102f33:	89 e5                	mov    %esp,%ebp
  102f35:	83 ec 18             	sub    $0x18,%esp
        spinlock_acquire(&p->lock);
  102f38:	8b 45 08             	mov    0x8(%ebp),%eax
  102f3b:	89 04 24             	mov    %eax,(%esp)
  102f3e:	e8 99 f6 ff ff       	call   1025dc <spinlock_acquire>
	p->state = PROC_WAIT;
  102f43:	8b 45 08             	mov    0x8(%ebp),%eax
  102f46:	c7 80 3c 04 00 00 03 	movl   $0x3,0x43c(%eax)
  102f4d:	00 00 00 
	p->runcpu = NULL;
  102f50:	8b 45 08             	mov    0x8(%ebp),%eax
  102f53:	c7 80 44 04 00 00 00 	movl   $0x0,0x444(%eax)
  102f5a:	00 00 00 
	p->waitchild = cp;
  102f5d:	8b 45 08             	mov    0x8(%ebp),%eax
  102f60:	8b 55 0c             	mov    0xc(%ebp),%edx
  102f63:	89 90 48 04 00 00    	mov    %edx,0x448(%eax)
	proc_save(p, tf, 0);
  102f69:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  102f70:	00 
  102f71:	8b 45 10             	mov    0x10(%ebp),%eax
  102f74:	89 44 24 04          	mov    %eax,0x4(%esp)
  102f78:	8b 45 08             	mov    0x8(%ebp),%eax
  102f7b:	89 04 24             	mov    %eax,(%esp)
  102f7e:	e8 6e ff ff ff       	call   102ef1 <proc_save>
	spinlock_release(&p->lock);
  102f83:	8b 45 08             	mov    0x8(%ebp),%eax
  102f86:	89 04 24             	mov    %eax,(%esp)
  102f89:	e8 ca f6 ff ff       	call   102658 <spinlock_release>
	proc_sched();
  102f8e:	e8 00 00 00 00       	call   102f93 <proc_sched>

00102f93 <proc_sched>:
}

void gcc_noreturn
proc_sched(void)
{
  102f93:	55                   	push   %ebp
  102f94:	89 e5                	mov    %esp,%ebp
  102f96:	83 ec 28             	sub    $0x28,%esp
	cpu *c = cpu_cur();
  102f99:	e8 8b fc ff ff       	call   102c29 <cpu_cur>
  102f9e:	89 45 f4             	mov    %eax,-0xc(%ebp)
	for(;;){//spin
	  spinlock_acquire(&_queue_lock);
  102fa1:	c7 04 24 00 f4 30 00 	movl   $0x30f400,(%esp)
  102fa8:	e8 2f f6 ff ff       	call   1025dc <spinlock_acquire>
	  //we must get ready_queue lock, before accessing _queue_head
	  if(proc_queue_head){
  102fad:	a1 e4 fa 30 00       	mov    0x30fae4,%eax
  102fb2:	85 c0                	test   %eax,%eax
  102fb4:	74 45                	je     102ffb <proc_sched+0x68>
	    proc *p = proc_queue_head;
  102fb6:	a1 e4 fa 30 00       	mov    0x30fae4,%eax
  102fbb:	89 45 f0             	mov    %eax,-0x10(%ebp)
	    proc_queue_head = p->readynext;
  102fbe:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102fc1:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  102fc7:	a3 e4 fa 30 00       	mov    %eax,0x30fae4
	    p->readynext = NULL;
  102fcc:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102fcf:	c7 80 40 04 00 00 00 	movl   $0x0,0x440(%eax)
  102fd6:	00 00 00 
	    spinlock_release(&_queue_lock);
  102fd9:	c7 04 24 00 f4 30 00 	movl   $0x30f400,(%esp)
  102fe0:	e8 73 f6 ff ff       	call   102658 <spinlock_release>
	    spinlock_acquire(&p->lock);
  102fe5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102fe8:	89 04 24             	mov    %eax,(%esp)
  102feb:	e8 ec f5 ff ff       	call   1025dc <spinlock_acquire>
	    proc_run(p);
  102ff0:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102ff3:	89 04 24             	mov    %eax,(%esp)
  102ff6:	e8 13 00 00 00       	call   10300e <proc_run>
	  }
	  else{
	    spinlock_release(&_queue_lock);
  102ffb:	c7 04 24 00 f4 30 00 	movl   $0x30f400,(%esp)
  103002:	e8 51 f6 ff ff       	call   102658 <spinlock_release>
	    pause();
  103007:	e8 16 fc ff ff       	call   102c22 <pause>
	  }
	}
  10300c:	eb 93                	jmp    102fa1 <proc_sched+0xe>

0010300e <proc_run>:
}

// Switch to and run a specified process, which must already be locked.
void gcc_noreturn
proc_run(proc *p)
{
  10300e:	55                   	push   %ebp
  10300f:	89 e5                	mov    %esp,%ebp
  103011:	83 ec 28             	sub    $0x28,%esp
        assert(spinlock_holding(&p->lock));
  103014:	8b 45 08             	mov    0x8(%ebp),%eax
  103017:	89 04 24             	mov    %eax,(%esp)
  10301a:	e8 93 f6 ff ff       	call   1026b2 <spinlock_holding>
  10301f:	85 c0                	test   %eax,%eax
  103021:	75 24                	jne    103047 <proc_run+0x39>
  103023:	c7 44 24 0c 1d 66 10 	movl   $0x10661d,0xc(%esp)
  10302a:	00 
  10302b:	c7 44 24 08 7a 65 10 	movl   $0x10657a,0x8(%esp)
  103032:	00 
  103033:	c7 44 24 04 96 00 00 	movl   $0x96,0x4(%esp)
  10303a:	00 
  10303b:	c7 04 24 9c 65 10 00 	movl   $0x10659c,(%esp)
  103042:	e8 7d d4 ff ff       	call   1004c4 <debug_panic>
  	p->state = PROC_RUN;
  103047:	8b 45 08             	mov    0x8(%ebp),%eax
  10304a:	c7 80 3c 04 00 00 02 	movl   $0x2,0x43c(%eax)
  103051:	00 00 00 
  	cpu *curr = cpu_cur();
  103054:	e8 d0 fb ff ff       	call   102c29 <cpu_cur>
  103059:	89 45 f4             	mov    %eax,-0xc(%ebp)
  	curr->proc = p;
  10305c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10305f:	8b 55 08             	mov    0x8(%ebp),%edx
  103062:	89 90 b4 00 00 00    	mov    %edx,0xb4(%eax)
  	p->runcpu = curr;
  103068:	8b 45 08             	mov    0x8(%ebp),%eax
  10306b:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10306e:	89 90 44 04 00 00    	mov    %edx,0x444(%eax)
  	spinlock_release(&p->lock);
  103074:	8b 45 08             	mov    0x8(%ebp),%eax
  103077:	89 04 24             	mov    %eax,(%esp)
  10307a:	e8 d9 f5 ff ff       	call   102658 <spinlock_release>
  	trap_return(&p->sv.tf);
  10307f:	8b 45 08             	mov    0x8(%ebp),%eax
  103082:	05 50 04 00 00       	add    $0x450,%eax
  103087:	89 04 24             	mov    %eax,(%esp)
  10308a:	e8 91 f0 ff ff       	call   102120 <trap_return>

0010308f <proc_yield>:

// Yield the current CPU to another ready process.
// Called while handling a timer interrupt.
void gcc_noreturn
proc_yield(trapframe *tf)
{
  10308f:	55                   	push   %ebp
  103090:	89 e5                	mov    %esp,%ebp
  103092:	83 ec 28             	sub    $0x28,%esp
	proc *curr = proc_cur();
  103095:	e8 8f fb ff ff       	call   102c29 <cpu_cur>
  10309a:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  1030a0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  	proc_save(curr, tf, -1);
  1030a3:	c7 44 24 08 ff ff ff 	movl   $0xffffffff,0x8(%esp)
  1030aa:	ff 
  1030ab:	8b 45 08             	mov    0x8(%ebp),%eax
  1030ae:	89 44 24 04          	mov    %eax,0x4(%esp)
  1030b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1030b5:	89 04 24             	mov    %eax,(%esp)
  1030b8:	e8 34 fe ff ff       	call   102ef1 <proc_save>
  	proc_ready(curr);
  1030bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1030c0:	89 04 24             	mov    %eax,(%esp)
  1030c3:	e8 8d fd ff ff       	call   102e55 <proc_ready>
  	proc_sched();
  1030c8:	e8 c6 fe ff ff       	call   102f93 <proc_sched>

001030cd <proc_ret>:
// Used both when a process calls the SYS_RET system call explicitly,
// and when a process causes an unhandled trap in user mode.
// The 'entry' parameter is as in proc_save().
void gcc_noreturn
proc_ret(trapframe *tf, int entry)
{
  1030cd:	55                   	push   %ebp
  1030ce:	89 e5                	mov    %esp,%ebp
  1030d0:	83 ec 28             	sub    $0x28,%esp
	proc *cp = proc_cur();
  1030d3:	e8 51 fb ff ff       	call   102c29 <cpu_cur>
  1030d8:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  1030de:	89 45 f4             	mov    %eax,-0xc(%ebp)
  	proc *pp = cp->parent;
  1030e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1030e4:	8b 40 38             	mov    0x38(%eax),%eax
  1030e7:	89 45 f0             	mov    %eax,-0x10(%ebp)
  	// Root process incurs trap...
  	if(pp == NULL) {
  1030ea:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  1030ee:	75 37                	jne    103127 <proc_ret+0x5a>
	  if(tf->trapno != T_SYSCALL) {
  1030f0:	8b 45 08             	mov    0x8(%ebp),%eax
  1030f3:	8b 40 30             	mov    0x30(%eax),%eax
  1030f6:	83 f8 30             	cmp    $0x30,%eax
  1030f9:	74 27                	je     103122 <proc_ret+0x55>
      		trap_print(tf);
  1030fb:	8b 45 08             	mov    0x8(%ebp),%eax
  1030fe:	89 04 24             	mov    %eax,(%esp)
  103101:	e8 47 e7 ff ff       	call   10184d <trap_print>
      		panic("proc_ret: trap in root process\n");
  103106:	c7 44 24 08 38 66 10 	movl   $0x106638,0x8(%esp)
  10310d:	00 
  10310e:	c7 44 24 04 b7 00 00 	movl   $0xb7,0x4(%esp)
  103115:	00 
  103116:	c7 04 24 9c 65 10 00 	movl   $0x10659c,(%esp)
  10311d:	e8 a2 d3 ff ff       	call   1004c4 <debug_panic>
	  }
	  done();
  103122:	e8 53 d1 ff ff       	call   10027a <done>
  	}
  	spinlock_acquire(&cp->lock);
  103127:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10312a:	89 04 24             	mov    %eax,(%esp)
  10312d:	e8 aa f4 ff ff       	call   1025dc <spinlock_acquire>
  	cp->state = PROC_STOP;
  103132:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103135:	c7 80 3c 04 00 00 00 	movl   $0x0,0x43c(%eax)
  10313c:	00 00 00 
  	proc_save(cp, tf, entry);
  10313f:	8b 45 0c             	mov    0xc(%ebp),%eax
  103142:	89 44 24 08          	mov    %eax,0x8(%esp)
  103146:	8b 45 08             	mov    0x8(%ebp),%eax
  103149:	89 44 24 04          	mov    %eax,0x4(%esp)
  10314d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103150:	89 04 24             	mov    %eax,(%esp)
  103153:	e8 99 fd ff ff       	call   102ef1 <proc_save>
  	spinlock_release(&cp->lock);
  103158:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10315b:	89 04 24             	mov    %eax,(%esp)
  10315e:	e8 f5 f4 ff ff       	call   102658 <spinlock_release>

  	spinlock_acquire(&pp->lock);
  103163:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103166:	89 04 24             	mov    %eax,(%esp)
  103169:	e8 6e f4 ff ff       	call   1025dc <spinlock_acquire>
  	if(pp->waitchild == cp || pp->state == PROC_WAIT) {
  10316e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103171:	8b 80 48 04 00 00    	mov    0x448(%eax),%eax
  103177:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  10317a:	74 0e                	je     10318a <proc_ret+0xbd>
  10317c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10317f:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  103185:	83 f8 03             	cmp    $0x3,%eax
  103188:	75 18                	jne    1031a2 <proc_ret+0xd5>
	  pp->waitchild = NULL;
  10318a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10318d:	c7 80 48 04 00 00 00 	movl   $0x0,0x448(%eax)
  103194:	00 00 00 
	  proc_run(pp);
  103197:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10319a:	89 04 24             	mov    %eax,(%esp)
  10319d:	e8 6c fe ff ff       	call   10300e <proc_run>
 	}
  	spinlock_release(&pp->lock);
  1031a2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1031a5:	89 04 24             	mov    %eax,(%esp)
  1031a8:	e8 ab f4 ff ff       	call   102658 <spinlock_release>
  	proc_sched();
  1031ad:	e8 e1 fd ff ff       	call   102f93 <proc_sched>

001031b2 <proc_check>:
static volatile uint32_t pingpong = 0;
static void *recovargs;

void
proc_check(void)
{
  1031b2:	55                   	push   %ebp
  1031b3:	89 e5                	mov    %esp,%ebp
  1031b5:	57                   	push   %edi
  1031b6:	56                   	push   %esi
  1031b7:	53                   	push   %ebx
  1031b8:	81 ec dc 00 00 00    	sub    $0xdc,%esp
	// Spawn 2 child processes, executing on statically allocated stacks.

	int i;
	for (i = 0; i < 4; i++) {
  1031be:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
  1031c5:	e9 a6 00 00 00       	jmp    103270 <proc_check+0xbe>
		// Setup register state for child
		uint32_t *esp = (uint32_t*) &child_stack[i][PAGESIZE];
  1031ca:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1031cd:	83 c0 01             	add    $0x1,%eax
  1031d0:	c1 e0 0c             	shl    $0xc,%eax
  1031d3:	05 d0 b2 10 00       	add    $0x10b2d0,%eax
  1031d8:	89 45 e0             	mov    %eax,-0x20(%ebp)
		*--esp = i;	// push argument to child() function
  1031db:	83 6d e0 04          	subl   $0x4,-0x20(%ebp)
  1031df:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  1031e2:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1031e5:	89 10                	mov    %edx,(%eax)
		*--esp = 0;	// fake return address
  1031e7:	83 6d e0 04          	subl   $0x4,-0x20(%ebp)
  1031eb:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1031ee:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		child_state.tf.eip = (uint32_t) child;
  1031f4:	b8 28 36 10 00       	mov    $0x103628,%eax
  1031f9:	a3 b8 b0 10 00       	mov    %eax,0x10b0b8
		child_state.tf.esp = (uint32_t) esp;
  1031fe:	8b 45 e0             	mov    -0x20(%ebp),%eax
  103201:	a3 c4 b0 10 00       	mov    %eax,0x10b0c4

		// Use PUT syscall to create each child,
		// but only start the first 2 children for now.
		cprintf("spawning child %d\n", i);
  103206:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103209:	89 44 24 04          	mov    %eax,0x4(%esp)
  10320d:	c7 04 24 58 66 10 00 	movl   $0x106658,(%esp)
  103214:	e8 c3 1f 00 00       	call   1051dc <cprintf>
		sys_put(SYS_REGS | (i < 2 ? SYS_START : 0), i, &child_state,
  103219:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10321c:	0f b7 d0             	movzwl %ax,%edx
  10321f:	83 7d e4 01          	cmpl   $0x1,-0x1c(%ebp)
  103223:	7f 07                	jg     10322c <proc_check+0x7a>
  103225:	b8 10 10 00 00       	mov    $0x1010,%eax
  10322a:	eb 05                	jmp    103231 <proc_check+0x7f>
  10322c:	b8 00 10 00 00       	mov    $0x1000,%eax
  103231:	89 45 d8             	mov    %eax,-0x28(%ebp)
  103234:	66 89 55 d6          	mov    %dx,-0x2a(%ebp)
  103238:	c7 45 d0 80 b0 10 00 	movl   $0x10b080,-0x30(%ebp)
  10323f:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
  103246:	c7 45 c8 00 00 00 00 	movl   $0x0,-0x38(%ebp)
  10324d:	c7 45 c4 00 00 00 00 	movl   $0x0,-0x3c(%ebp)
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  103254:	8b 45 d8             	mov    -0x28(%ebp),%eax
  103257:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  10325a:	8b 5d d0             	mov    -0x30(%ebp),%ebx
  10325d:	0f b7 55 d6          	movzwl -0x2a(%ebp),%edx
  103261:	8b 75 cc             	mov    -0x34(%ebp),%esi
  103264:	8b 7d c8             	mov    -0x38(%ebp),%edi
  103267:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
  10326a:	cd 30                	int    $0x30
proc_check(void)
{
	// Spawn 2 child processes, executing on statically allocated stacks.

	int i;
	for (i = 0; i < 4; i++) {
  10326c:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
  103270:	83 7d e4 03          	cmpl   $0x3,-0x1c(%ebp)
  103274:	0f 8e 50 ff ff ff    	jle    1031ca <proc_check+0x18>
	}

	// Wait for both children to complete.
	// This should complete without preemptive scheduling
	// when we're running on a 2-processor machine.
	for (i = 0; i < 2; i++) {
  10327a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
  103281:	eb 5c                	jmp    1032df <proc_check+0x12d>
		cprintf("waiting for child %d\n", i);
  103283:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103286:	89 44 24 04          	mov    %eax,0x4(%esp)
  10328a:	c7 04 24 6b 66 10 00 	movl   $0x10666b,(%esp)
  103291:	e8 46 1f 00 00       	call   1051dc <cprintf>
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  103296:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103299:	0f b7 c0             	movzwl %ax,%eax
  10329c:	c7 45 c0 00 10 00 00 	movl   $0x1000,-0x40(%ebp)
  1032a3:	66 89 45 be          	mov    %ax,-0x42(%ebp)
  1032a7:	c7 45 b8 80 b0 10 00 	movl   $0x10b080,-0x48(%ebp)
  1032ae:	c7 45 b4 00 00 00 00 	movl   $0x0,-0x4c(%ebp)
  1032b5:	c7 45 b0 00 00 00 00 	movl   $0x0,-0x50(%ebp)
  1032bc:	c7 45 ac 00 00 00 00 	movl   $0x0,-0x54(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  1032c3:	8b 45 c0             	mov    -0x40(%ebp),%eax
  1032c6:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  1032c9:	8b 5d b8             	mov    -0x48(%ebp),%ebx
  1032cc:	0f b7 55 be          	movzwl -0x42(%ebp),%edx
  1032d0:	8b 75 b4             	mov    -0x4c(%ebp),%esi
  1032d3:	8b 7d b0             	mov    -0x50(%ebp),%edi
  1032d6:	8b 4d ac             	mov    -0x54(%ebp),%ecx
  1032d9:	cd 30                	int    $0x30
	}

	// Wait for both children to complete.
	// This should complete without preemptive scheduling
	// when we're running on a 2-processor machine.
	for (i = 0; i < 2; i++) {
  1032db:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
  1032df:	83 7d e4 01          	cmpl   $0x1,-0x1c(%ebp)
  1032e3:	7e 9e                	jle    103283 <proc_check+0xd1>
		cprintf("waiting for child %d\n", i);
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
	}
	cprintf("proc_check() 2-child test succeeded\n");
  1032e5:	c7 04 24 84 66 10 00 	movl   $0x106684,(%esp)
  1032ec:	e8 eb 1e 00 00       	call   1051dc <cprintf>

	// (Re)start all four children, and wait for them.
	// This will require preemptive scheduling to complete
	// if we have less than 4 CPUs.
	cprintf("proc_check: spawning 4 children\n");
  1032f1:	c7 04 24 ac 66 10 00 	movl   $0x1066ac,(%esp)
  1032f8:	e8 df 1e 00 00       	call   1051dc <cprintf>
	for (i = 0; i < 4; i++) {
  1032fd:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
  103304:	eb 5c                	jmp    103362 <proc_check+0x1b0>
		cprintf("spawning child %d\n", i);
  103306:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103309:	89 44 24 04          	mov    %eax,0x4(%esp)
  10330d:	c7 04 24 58 66 10 00 	movl   $0x106658,(%esp)
  103314:	e8 c3 1e 00 00       	call   1051dc <cprintf>
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
  103319:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10331c:	0f b7 c0             	movzwl %ax,%eax
  10331f:	c7 45 a8 10 00 00 00 	movl   $0x10,-0x58(%ebp)
  103326:	66 89 45 a6          	mov    %ax,-0x5a(%ebp)
  10332a:	c7 45 a0 00 00 00 00 	movl   $0x0,-0x60(%ebp)
  103331:	c7 45 9c 00 00 00 00 	movl   $0x0,-0x64(%ebp)
  103338:	c7 45 98 00 00 00 00 	movl   $0x0,-0x68(%ebp)
  10333f:	c7 45 94 00 00 00 00 	movl   $0x0,-0x6c(%ebp)
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  103346:	8b 45 a8             	mov    -0x58(%ebp),%eax
  103349:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  10334c:	8b 5d a0             	mov    -0x60(%ebp),%ebx
  10334f:	0f b7 55 a6          	movzwl -0x5a(%ebp),%edx
  103353:	8b 75 9c             	mov    -0x64(%ebp),%esi
  103356:	8b 7d 98             	mov    -0x68(%ebp),%edi
  103359:	8b 4d 94             	mov    -0x6c(%ebp),%ecx
  10335c:	cd 30                	int    $0x30

	// (Re)start all four children, and wait for them.
	// This will require preemptive scheduling to complete
	// if we have less than 4 CPUs.
	cprintf("proc_check: spawning 4 children\n");
	for (i = 0; i < 4; i++) {
  10335e:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
  103362:	83 7d e4 03          	cmpl   $0x3,-0x1c(%ebp)
  103366:	7e 9e                	jle    103306 <proc_check+0x154>
		cprintf("spawning child %d\n", i);
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
	}

	// Wait for all 4 children to complete.
	for (i = 0; i < 4; i++)
  103368:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
  10336f:	eb 4f                	jmp    1033c0 <proc_check+0x20e>
		sys_get(0, i, NULL, NULL, NULL, 0);
  103371:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103374:	0f b7 c0             	movzwl %ax,%eax
  103377:	c7 45 90 00 00 00 00 	movl   $0x0,-0x70(%ebp)
  10337e:	66 89 45 8e          	mov    %ax,-0x72(%ebp)
  103382:	c7 45 88 00 00 00 00 	movl   $0x0,-0x78(%ebp)
  103389:	c7 45 84 00 00 00 00 	movl   $0x0,-0x7c(%ebp)
  103390:	c7 45 80 00 00 00 00 	movl   $0x0,-0x80(%ebp)
  103397:	c7 85 7c ff ff ff 00 	movl   $0x0,-0x84(%ebp)
  10339e:	00 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  1033a1:	8b 45 90             	mov    -0x70(%ebp),%eax
  1033a4:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  1033a7:	8b 5d 88             	mov    -0x78(%ebp),%ebx
  1033aa:	0f b7 55 8e          	movzwl -0x72(%ebp),%edx
  1033ae:	8b 75 84             	mov    -0x7c(%ebp),%esi
  1033b1:	8b 7d 80             	mov    -0x80(%ebp),%edi
  1033b4:	8b 8d 7c ff ff ff    	mov    -0x84(%ebp),%ecx
  1033ba:	cd 30                	int    $0x30
		cprintf("spawning child %d\n", i);
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
	}

	// Wait for all 4 children to complete.
	for (i = 0; i < 4; i++)
  1033bc:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
  1033c0:	83 7d e4 03          	cmpl   $0x3,-0x1c(%ebp)
  1033c4:	7e ab                	jle    103371 <proc_check+0x1bf>
		sys_get(0, i, NULL, NULL, NULL, 0);
	cprintf("proc_check() 4-child test succeeded\n");
  1033c6:	c7 04 24 d0 66 10 00 	movl   $0x1066d0,(%esp)
  1033cd:	e8 0a 1e 00 00       	call   1051dc <cprintf>

	// Now do a trap handling test using all 4 children -
	// but they'll _think_ they're all child 0!
	// (We'll lose the register state of the other children.)
	i = 0;
  1033d2:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  1033d9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1033dc:	0f b7 c0             	movzwl %ax,%eax
  1033df:	c7 85 78 ff ff ff 00 	movl   $0x1000,-0x88(%ebp)
  1033e6:	10 00 00 
  1033e9:	66 89 85 76 ff ff ff 	mov    %ax,-0x8a(%ebp)
  1033f0:	c7 85 70 ff ff ff 80 	movl   $0x10b080,-0x90(%ebp)
  1033f7:	b0 10 00 
  1033fa:	c7 85 6c ff ff ff 00 	movl   $0x0,-0x94(%ebp)
  103401:	00 00 00 
  103404:	c7 85 68 ff ff ff 00 	movl   $0x0,-0x98(%ebp)
  10340b:	00 00 00 
  10340e:	c7 85 64 ff ff ff 00 	movl   $0x0,-0x9c(%ebp)
  103415:	00 00 00 
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  103418:	8b 85 78 ff ff ff    	mov    -0x88(%ebp),%eax
  10341e:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  103421:	8b 9d 70 ff ff ff    	mov    -0x90(%ebp),%ebx
  103427:	0f b7 95 76 ff ff ff 	movzwl -0x8a(%ebp),%edx
  10342e:	8b b5 6c ff ff ff    	mov    -0x94(%ebp),%esi
  103434:	8b bd 68 ff ff ff    	mov    -0x98(%ebp),%edi
  10343a:	8b 8d 64 ff ff ff    	mov    -0x9c(%ebp),%ecx
  103440:	cd 30                	int    $0x30
		// get child 0's state
	assert(recovargs == NULL);
  103442:	a1 d4 f2 10 00       	mov    0x10f2d4,%eax
  103447:	85 c0                	test   %eax,%eax
  103449:	74 24                	je     10346f <proc_check+0x2bd>
  10344b:	c7 44 24 0c f5 66 10 	movl   $0x1066f5,0xc(%esp)
  103452:	00 
  103453:	c7 44 24 08 7a 65 10 	movl   $0x10657a,0x8(%esp)
  10345a:	00 
  10345b:	c7 44 24 04 05 01 00 	movl   $0x105,0x4(%esp)
  103462:	00 
  103463:	c7 04 24 9c 65 10 00 	movl   $0x10659c,(%esp)
  10346a:	e8 55 d0 ff ff       	call   1004c4 <debug_panic>
	do {
		sys_put(SYS_REGS | SYS_START, i, &child_state, NULL, NULL, 0);
  10346f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103472:	0f b7 c0             	movzwl %ax,%eax
  103475:	c7 85 60 ff ff ff 10 	movl   $0x1010,-0xa0(%ebp)
  10347c:	10 00 00 
  10347f:	66 89 85 5e ff ff ff 	mov    %ax,-0xa2(%ebp)
  103486:	c7 85 58 ff ff ff 80 	movl   $0x10b080,-0xa8(%ebp)
  10348d:	b0 10 00 
  103490:	c7 85 54 ff ff ff 00 	movl   $0x0,-0xac(%ebp)
  103497:	00 00 00 
  10349a:	c7 85 50 ff ff ff 00 	movl   $0x0,-0xb0(%ebp)
  1034a1:	00 00 00 
  1034a4:	c7 85 4c ff ff ff 00 	movl   $0x0,-0xb4(%ebp)
  1034ab:	00 00 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  1034ae:	8b 85 60 ff ff ff    	mov    -0xa0(%ebp),%eax
  1034b4:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  1034b7:	8b 9d 58 ff ff ff    	mov    -0xa8(%ebp),%ebx
  1034bd:	0f b7 95 5e ff ff ff 	movzwl -0xa2(%ebp),%edx
  1034c4:	8b b5 54 ff ff ff    	mov    -0xac(%ebp),%esi
  1034ca:	8b bd 50 ff ff ff    	mov    -0xb0(%ebp),%edi
  1034d0:	8b 8d 4c ff ff ff    	mov    -0xb4(%ebp),%ecx
  1034d6:	cd 30                	int    $0x30
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  1034d8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1034db:	0f b7 c0             	movzwl %ax,%eax
  1034de:	c7 85 48 ff ff ff 00 	movl   $0x1000,-0xb8(%ebp)
  1034e5:	10 00 00 
  1034e8:	66 89 85 46 ff ff ff 	mov    %ax,-0xba(%ebp)
  1034ef:	c7 85 40 ff ff ff 80 	movl   $0x10b080,-0xc0(%ebp)
  1034f6:	b0 10 00 
  1034f9:	c7 85 3c ff ff ff 00 	movl   $0x0,-0xc4(%ebp)
  103500:	00 00 00 
  103503:	c7 85 38 ff ff ff 00 	movl   $0x0,-0xc8(%ebp)
  10350a:	00 00 00 
  10350d:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  103514:	00 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  103517:	8b 85 48 ff ff ff    	mov    -0xb8(%ebp),%eax
  10351d:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  103520:	8b 9d 40 ff ff ff    	mov    -0xc0(%ebp),%ebx
  103526:	0f b7 95 46 ff ff ff 	movzwl -0xba(%ebp),%edx
  10352d:	8b b5 3c ff ff ff    	mov    -0xc4(%ebp),%esi
  103533:	8b bd 38 ff ff ff    	mov    -0xc8(%ebp),%edi
  103539:	8b 8d 34 ff ff ff    	mov    -0xcc(%ebp),%ecx
  10353f:	cd 30                	int    $0x30
		if (recovargs) {	// trap recovery needed
  103541:	a1 d4 f2 10 00       	mov    0x10f2d4,%eax
  103546:	85 c0                	test   %eax,%eax
  103548:	74 36                	je     103580 <proc_check+0x3ce>
			trap_check_args *args = recovargs;
  10354a:	a1 d4 f2 10 00       	mov    0x10f2d4,%eax
  10354f:	89 45 dc             	mov    %eax,-0x24(%ebp)
			cprintf("recover from trap %d\n",
  103552:	a1 b0 b0 10 00       	mov    0x10b0b0,%eax
  103557:	89 44 24 04          	mov    %eax,0x4(%esp)
  10355b:	c7 04 24 07 67 10 00 	movl   $0x106707,(%esp)
  103562:	e8 75 1c 00 00       	call   1051dc <cprintf>
				child_state.tf.trapno);
			child_state.tf.eip = (uint32_t) args->reip;
  103567:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10356a:	8b 00                	mov    (%eax),%eax
  10356c:	a3 b8 b0 10 00       	mov    %eax,0x10b0b8
			args->trapno = child_state.tf.trapno;
  103571:	a1 b0 b0 10 00       	mov    0x10b0b0,%eax
  103576:	89 c2                	mov    %eax,%edx
  103578:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10357b:	89 50 04             	mov    %edx,0x4(%eax)
  10357e:	eb 2e                	jmp    1035ae <proc_check+0x3fc>
		} else
			assert(child_state.tf.trapno == T_SYSCALL);
  103580:	a1 b0 b0 10 00       	mov    0x10b0b0,%eax
  103585:	83 f8 30             	cmp    $0x30,%eax
  103588:	74 24                	je     1035ae <proc_check+0x3fc>
  10358a:	c7 44 24 0c 20 67 10 	movl   $0x106720,0xc(%esp)
  103591:	00 
  103592:	c7 44 24 08 7a 65 10 	movl   $0x10657a,0x8(%esp)
  103599:	00 
  10359a:	c7 44 24 04 10 01 00 	movl   $0x110,0x4(%esp)
  1035a1:	00 
  1035a2:	c7 04 24 9c 65 10 00 	movl   $0x10659c,(%esp)
  1035a9:	e8 16 cf ff ff       	call   1004c4 <debug_panic>
		i = (i+1) % 4;	// rotate to next child proc
  1035ae:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1035b1:	8d 50 01             	lea    0x1(%eax),%edx
  1035b4:	89 d0                	mov    %edx,%eax
  1035b6:	c1 f8 1f             	sar    $0x1f,%eax
  1035b9:	c1 e8 1e             	shr    $0x1e,%eax
  1035bc:	01 c2                	add    %eax,%edx
  1035be:	83 e2 03             	and    $0x3,%edx
  1035c1:	89 d1                	mov    %edx,%ecx
  1035c3:	29 c1                	sub    %eax,%ecx
  1035c5:	89 c8                	mov    %ecx,%eax
  1035c7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	} while (child_state.tf.trapno != T_SYSCALL);
  1035ca:	a1 b0 b0 10 00       	mov    0x10b0b0,%eax
  1035cf:	83 f8 30             	cmp    $0x30,%eax
  1035d2:	0f 85 97 fe ff ff    	jne    10346f <proc_check+0x2bd>
	assert(recovargs == NULL);
  1035d8:	a1 d4 f2 10 00       	mov    0x10f2d4,%eax
  1035dd:	85 c0                	test   %eax,%eax
  1035df:	74 24                	je     103605 <proc_check+0x453>
  1035e1:	c7 44 24 0c f5 66 10 	movl   $0x1066f5,0xc(%esp)
  1035e8:	00 
  1035e9:	c7 44 24 08 7a 65 10 	movl   $0x10657a,0x8(%esp)
  1035f0:	00 
  1035f1:	c7 44 24 04 13 01 00 	movl   $0x113,0x4(%esp)
  1035f8:	00 
  1035f9:	c7 04 24 9c 65 10 00 	movl   $0x10659c,(%esp)
  103600:	e8 bf ce ff ff       	call   1004c4 <debug_panic>

	cprintf("proc_check() trap reflection test succeeded\n");
  103605:	c7 04 24 44 67 10 00 	movl   $0x106744,(%esp)
  10360c:	e8 cb 1b 00 00       	call   1051dc <cprintf>

	cprintf("proc_check() succeeded!\n");
  103611:	c7 04 24 71 67 10 00 	movl   $0x106771,(%esp)
  103618:	e8 bf 1b 00 00       	call   1051dc <cprintf>
}
  10361d:	81 c4 dc 00 00 00    	add    $0xdc,%esp
  103623:	5b                   	pop    %ebx
  103624:	5e                   	pop    %esi
  103625:	5f                   	pop    %edi
  103626:	5d                   	pop    %ebp
  103627:	c3                   	ret    

00103628 <child>:

static void child(int n)
{
  103628:	55                   	push   %ebp
  103629:	89 e5                	mov    %esp,%ebp
  10362b:	83 ec 28             	sub    $0x28,%esp
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
  10362e:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
  103632:	7f 64                	jg     103698 <child+0x70>
		int i;
		for (i = 0; i < 10; i++) {
  103634:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  10363b:	eb 4e                	jmp    10368b <child+0x63>
			cprintf("in child %d count %d\n", n, i);
  10363d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103640:	89 44 24 08          	mov    %eax,0x8(%esp)
  103644:	8b 45 08             	mov    0x8(%ebp),%eax
  103647:	89 44 24 04          	mov    %eax,0x4(%esp)
  10364b:	c7 04 24 8a 67 10 00 	movl   $0x10678a,(%esp)
  103652:	e8 85 1b 00 00       	call   1051dc <cprintf>
			while (pingpong != n)
  103657:	eb 05                	jmp    10365e <child+0x36>
				pause();
  103659:	e8 c4 f5 ff ff       	call   102c22 <pause>
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
		int i;
		for (i = 0; i < 10; i++) {
			cprintf("in child %d count %d\n", n, i);
			while (pingpong != n)
  10365e:	8b 55 08             	mov    0x8(%ebp),%edx
  103661:	a1 d0 f2 10 00       	mov    0x10f2d0,%eax
  103666:	39 c2                	cmp    %eax,%edx
  103668:	75 ef                	jne    103659 <child+0x31>
				pause();
			xchg(&pingpong, !pingpong);
  10366a:	a1 d0 f2 10 00       	mov    0x10f2d0,%eax
  10366f:	85 c0                	test   %eax,%eax
  103671:	0f 94 c0             	sete   %al
  103674:	0f b6 c0             	movzbl %al,%eax
  103677:	89 44 24 04          	mov    %eax,0x4(%esp)
  10367b:	c7 04 24 d0 f2 10 00 	movl   $0x10f2d0,(%esp)
  103682:	e8 65 f5 ff ff       	call   102bec <xchg>
static void child(int n)
{
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
		int i;
		for (i = 0; i < 10; i++) {
  103687:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  10368b:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  10368f:	7e ac                	jle    10363d <child+0x15>
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
  103691:	b8 03 00 00 00       	mov    $0x3,%eax
  103696:	cd 30                	int    $0x30
		sys_ret();
	}

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
  103698:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  10369f:	eb 4c                	jmp    1036ed <child+0xc5>
		cprintf("in child %d count %d\n", n, i);
  1036a1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1036a4:	89 44 24 08          	mov    %eax,0x8(%esp)
  1036a8:	8b 45 08             	mov    0x8(%ebp),%eax
  1036ab:	89 44 24 04          	mov    %eax,0x4(%esp)
  1036af:	c7 04 24 8a 67 10 00 	movl   $0x10678a,(%esp)
  1036b6:	e8 21 1b 00 00       	call   1051dc <cprintf>
		while (pingpong != n)
  1036bb:	eb 05                	jmp    1036c2 <child+0x9a>
			pause();
  1036bd:	e8 60 f5 ff ff       	call   102c22 <pause>

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
		cprintf("in child %d count %d\n", n, i);
		while (pingpong != n)
  1036c2:	8b 55 08             	mov    0x8(%ebp),%edx
  1036c5:	a1 d0 f2 10 00       	mov    0x10f2d0,%eax
  1036ca:	39 c2                	cmp    %eax,%edx
  1036cc:	75 ef                	jne    1036bd <child+0x95>
			pause();
		xchg(&pingpong, (pingpong + 1) % 4);
  1036ce:	a1 d0 f2 10 00       	mov    0x10f2d0,%eax
  1036d3:	83 c0 01             	add    $0x1,%eax
  1036d6:	83 e0 03             	and    $0x3,%eax
  1036d9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1036dd:	c7 04 24 d0 f2 10 00 	movl   $0x10f2d0,(%esp)
  1036e4:	e8 03 f5 ff ff       	call   102bec <xchg>
		sys_ret();
	}

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
  1036e9:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  1036ed:	83 7d f0 09          	cmpl   $0x9,-0x10(%ebp)
  1036f1:	7e ae                	jle    1036a1 <child+0x79>
  1036f3:	b8 03 00 00 00       	mov    $0x3,%eax
  1036f8:	cd 30                	int    $0x30
		xchg(&pingpong, (pingpong + 1) % 4);
	}
	sys_ret();

	// Only "child 0" (or the proc that thinks it's child 0), trap check...
	if (n == 0) {
  1036fa:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  1036fe:	75 6d                	jne    10376d <child+0x145>
		assert(recovargs == NULL);
  103700:	a1 d4 f2 10 00       	mov    0x10f2d4,%eax
  103705:	85 c0                	test   %eax,%eax
  103707:	74 24                	je     10372d <child+0x105>
  103709:	c7 44 24 0c f5 66 10 	movl   $0x1066f5,0xc(%esp)
  103710:	00 
  103711:	c7 44 24 08 7a 65 10 	movl   $0x10657a,0x8(%esp)
  103718:	00 
  103719:	c7 44 24 04 34 01 00 	movl   $0x134,0x4(%esp)
  103720:	00 
  103721:	c7 04 24 9c 65 10 00 	movl   $0x10659c,(%esp)
  103728:	e8 97 cd ff ff       	call   1004c4 <debug_panic>
		trap_check(&recovargs);
  10372d:	c7 04 24 d4 f2 10 00 	movl   $0x10f2d4,(%esp)
  103734:	e8 89 e5 ff ff       	call   101cc2 <trap_check>
		assert(recovargs == NULL);
  103739:	a1 d4 f2 10 00       	mov    0x10f2d4,%eax
  10373e:	85 c0                	test   %eax,%eax
  103740:	74 24                	je     103766 <child+0x13e>
  103742:	c7 44 24 0c f5 66 10 	movl   $0x1066f5,0xc(%esp)
  103749:	00 
  10374a:	c7 44 24 08 7a 65 10 	movl   $0x10657a,0x8(%esp)
  103751:	00 
  103752:	c7 44 24 04 36 01 00 	movl   $0x136,0x4(%esp)
  103759:	00 
  10375a:	c7 04 24 9c 65 10 00 	movl   $0x10659c,(%esp)
  103761:	e8 5e cd ff ff       	call   1004c4 <debug_panic>
  103766:	b8 03 00 00 00       	mov    $0x3,%eax
  10376b:	cd 30                	int    $0x30
		sys_ret();
	}

	panic("child(): shouldn't have gotten here");
  10376d:	c7 44 24 08 a0 67 10 	movl   $0x1067a0,0x8(%esp)
  103774:	00 
  103775:	c7 44 24 04 3a 01 00 	movl   $0x13a,0x4(%esp)
  10377c:	00 
  10377d:	c7 04 24 9c 65 10 00 	movl   $0x10659c,(%esp)
  103784:	e8 3b cd ff ff       	call   1004c4 <debug_panic>

00103789 <grandchild>:
}

static void grandchild(int n)
{
  103789:	55                   	push   %ebp
  10378a:	89 e5                	mov    %esp,%ebp
  10378c:	83 ec 18             	sub    $0x18,%esp
	panic("grandchild(): shouldn't have gotten here");
  10378f:	c7 44 24 08 c4 67 10 	movl   $0x1067c4,0x8(%esp)
  103796:	00 
  103797:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
  10379e:	00 
  10379f:	c7 04 24 9c 65 10 00 	movl   $0x10659c,(%esp)
  1037a6:	e8 19 cd ff ff       	call   1004c4 <debug_panic>
  1037ab:	90                   	nop

001037ac <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  1037ac:	55                   	push   %ebp
  1037ad:	89 e5                	mov    %esp,%ebp
  1037af:	53                   	push   %ebx
  1037b0:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1037b3:	89 e3                	mov    %esp,%ebx
  1037b5:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  1037b8:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1037bb:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1037be:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1037c1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1037c6:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  1037c9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1037cc:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  1037d2:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1037d7:	74 24                	je     1037fd <cpu_cur+0x51>
  1037d9:	c7 44 24 0c f0 67 10 	movl   $0x1067f0,0xc(%esp)
  1037e0:	00 
  1037e1:	c7 44 24 08 06 68 10 	movl   $0x106806,0x8(%esp)
  1037e8:	00 
  1037e9:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1037f0:	00 
  1037f1:	c7 04 24 1b 68 10 00 	movl   $0x10681b,(%esp)
  1037f8:	e8 c7 cc ff ff       	call   1004c4 <debug_panic>
	return c;
  1037fd:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  103800:	83 c4 24             	add    $0x24,%esp
  103803:	5b                   	pop    %ebx
  103804:	5d                   	pop    %ebp
  103805:	c3                   	ret    

00103806 <systrap>:
// During a system call, generate a specific processor trap -
// as if the user code's INT 0x30 instruction had caused it -
// and reflect the trap to the parent process as with other traps.
static void gcc_noreturn
systrap(trapframe *utf, int trapno, int err)
{
  103806:	55                   	push   %ebp
  103807:	89 e5                	mov    %esp,%ebp
  103809:	83 ec 18             	sub    $0x18,%esp
       utf->trapno = trapno;
  10380c:	8b 55 0c             	mov    0xc(%ebp),%edx
  10380f:	8b 45 08             	mov    0x8(%ebp),%eax
  103812:	89 50 30             	mov    %edx,0x30(%eax)
       utf->err = err;
  103815:	8b 55 10             	mov    0x10(%ebp),%edx
  103818:	8b 45 08             	mov    0x8(%ebp),%eax
  10381b:	89 50 34             	mov    %edx,0x34(%eax)
       proc_ret(utf, 0);
  10381e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  103825:	00 
  103826:	8b 45 08             	mov    0x8(%ebp),%eax
  103829:	89 04 24             	mov    %eax,(%esp)
  10382c:	e8 9c f8 ff ff       	call   1030cd <proc_ret>

00103831 <sysrecover>:
// - Be sure the parent gets the correct trapno, err, and eip values.
// - Be sure to release any spinlocks you were holding during the copyin/out.
//
static void gcc_noreturn
sysrecover(trapframe *ktf, void *recoverdata)
{
  103831:	55                   	push   %ebp
  103832:	89 e5                	mov    %esp,%ebp
  103834:	83 ec 28             	sub    $0x28,%esp
  trapframe *utf = (trapframe*)recoverdata;
  103837:	8b 45 0c             	mov    0xc(%ebp),%eax
  10383a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  cpu *c = cpu_cur();
  10383d:	e8 6a ff ff ff       	call   1037ac <cpu_cur>
  103842:	89 45 f0             	mov    %eax,-0x10(%ebp)
  assert(c->recover == sysrecover);
  103845:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103848:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  10384e:	3d 31 38 10 00       	cmp    $0x103831,%eax
  103853:	74 24                	je     103879 <sysrecover+0x48>
  103855:	c7 44 24 0c 28 68 10 	movl   $0x106828,0xc(%esp)
  10385c:	00 
  10385d:	c7 44 24 08 06 68 10 	movl   $0x106806,0x8(%esp)
  103864:	00 
  103865:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
  10386c:	00 
  10386d:	c7 04 24 41 68 10 00 	movl   $0x106841,(%esp)
  103874:	e8 4b cc ff ff       	call   1004c4 <debug_panic>
  c->recover = NULL;
  103879:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10387c:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  103883:	00 00 00 
  systrap(utf, ktf->trapno, ktf->err);
  103886:	8b 45 08             	mov    0x8(%ebp),%eax
  103889:	8b 40 34             	mov    0x34(%eax),%eax
  10388c:	89 c2                	mov    %eax,%edx
  10388e:	8b 45 08             	mov    0x8(%ebp),%eax
  103891:	8b 40 30             	mov    0x30(%eax),%eax
  103894:	89 54 24 08          	mov    %edx,0x8(%esp)
  103898:	89 44 24 04          	mov    %eax,0x4(%esp)
  10389c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10389f:	89 04 24             	mov    %eax,(%esp)
  1038a2:	e8 5f ff ff ff       	call   103806 <systrap>

001038a7 <checkva>:
//
// Note: Be careful that your arithmetic works correctly
// even if size is very large, e.g., if uva+size wraps around!
//
static void checkva(trapframe *utf, uint32_t uva, size_t size)
{
  1038a7:	55                   	push   %ebp
  1038a8:	89 e5                	mov    %esp,%ebp
  1038aa:	83 ec 18             	sub    $0x18,%esp
        panic("checkva() not implemented.");
  1038ad:	c7 44 24 08 50 68 10 	movl   $0x106850,0x8(%esp)
  1038b4:	00 
  1038b5:	c7 44 24 04 48 00 00 	movl   $0x48,0x4(%esp)
  1038bc:	00 
  1038bd:	c7 04 24 41 68 10 00 	movl   $0x106841,(%esp)
  1038c4:	e8 fb cb ff ff       	call   1004c4 <debug_panic>

001038c9 <usercopy>:
// Copy data to/from user space,
// using checkva() above to validate the address range
// and using sysrecover() to recover from any traps during the copy.
void usercopy(trapframe *utf, bool copyout,
			void *kva, uint32_t uva, size_t size)
{
  1038c9:	55                   	push   %ebp
  1038ca:	89 e5                	mov    %esp,%ebp
  1038cc:	83 ec 18             	sub    $0x18,%esp
	panic("syscall_usercopy() not implemented.");
  1038cf:	c7 44 24 08 6c 68 10 	movl   $0x10686c,0x8(%esp)
  1038d6:	00 
  1038d7:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
  1038de:	00 
  1038df:	c7 04 24 41 68 10 00 	movl   $0x106841,(%esp)
  1038e6:	e8 d9 cb ff ff       	call   1004c4 <debug_panic>

001038eb <do_cputs>:
}

static void
do_cputs(trapframe *tf, uint32_t cmd)
{
  1038eb:	55                   	push   %ebp
  1038ec:	89 e5                	mov    %esp,%ebp
  1038ee:	83 ec 18             	sub    $0x18,%esp
	// Print the string supplied by the user: pointer in EBX
	cprintf("%s", (char*)tf->regs.ebx);
  1038f1:	8b 45 08             	mov    0x8(%ebp),%eax
  1038f4:	8b 40 10             	mov    0x10(%eax),%eax
  1038f7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1038fb:	c7 04 24 90 68 10 00 	movl   $0x106890,(%esp)
  103902:	e8 d5 18 00 00       	call   1051dc <cprintf>
	trap_return(tf);	// syscall completed
  103907:	8b 45 08             	mov    0x8(%ebp),%eax
  10390a:	89 04 24             	mov    %eax,(%esp)
  10390d:	e8 0e e8 ff ff       	call   102120 <trap_return>

00103912 <do_put>:
// decode the system call type and call an appropriate handler function.
// Be sure to handle undefined system calls appropriately.

static void
do_put(trapframe *tf, uint32_t cmd)
{
  103912:	55                   	push   %ebp
  103913:	89 e5                	mov    %esp,%ebp
  103915:	83 ec 38             	sub    $0x38,%esp
  //need to rethink setting lock
  proc *curr = proc_cur();
  103918:	e8 8f fe ff ff       	call   1037ac <cpu_cur>
  10391d:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  103923:	89 45 f0             	mov    %eax,-0x10(%ebp)
  procstate *cstate = (procstate*)tf->regs.ebx;//"b"(save)
  103926:	8b 45 08             	mov    0x8(%ebp),%eax
  103929:	8b 40 10             	mov    0x10(%eax),%eax
  10392c:	89 45 ec             	mov    %eax,-0x14(%ebp)
  spinlock_acquire(&curr->lock);
  10392f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103932:	89 04 24             	mov    %eax,(%esp)
  103935:	e8 a2 ec ff ff       	call   1025dc <spinlock_acquire>
  uint32_t child_index = tf->regs.edx;
  10393a:	8b 45 08             	mov    0x8(%ebp),%eax
  10393d:	8b 40 14             	mov    0x14(%eax),%eax
  103940:	89 45 e8             	mov    %eax,-0x18(%ebp)
  //"d"(child)
  //EDX: bits 7-0:Child proess number to get/put
  uint8_t cn = child_index & 0xff;//the last 8 bits for child number
  103943:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103946:	88 45 e7             	mov    %al,-0x19(%ebp)
  proc *child = curr->child[cn];
  103949:	0f b6 55 e7          	movzbl -0x19(%ebp),%edx
  10394d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103950:	83 c2 0c             	add    $0xc,%edx
  103953:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
  103957:	89 45 f4             	mov    %eax,-0xc(%ebp)
  spinlock_release(&curr->lock);
  10395a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10395d:	89 04 24             	mov    %eax,(%esp)
  103960:	e8 f3 ec ff ff       	call   102658 <spinlock_release>
  //shall the child->lock be catch, before accessing the child ?
  if(!child){
  103965:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  103969:	75 16                	jne    103981 <do_put+0x6f>
    child = proc_alloc(curr, cn);
  10396b:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  10396f:	89 44 24 04          	mov    %eax,0x4(%esp)
  103973:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103976:	89 04 24             	mov    %eax,(%esp)
  103979:	e8 57 f3 ff ff       	call   102cd5 <proc_alloc>
  10397e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  }
  if(child->state != PROC_STOP){
  103981:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103984:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  10398a:	85 c0                	test   %eax,%eax
  10398c:	74 19                	je     1039a7 <do_put+0x95>
    proc_wait(curr, child, tf);
  10398e:	8b 45 08             	mov    0x8(%ebp),%eax
  103991:	89 44 24 08          	mov    %eax,0x8(%esp)
  103995:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103998:	89 44 24 04          	mov    %eax,0x4(%esp)
  10399c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10399f:	89 04 24             	mov    %eax,(%esp)
  1039a2:	e8 8b f5 ff ff       	call   102f32 <proc_wait>
  //the kernel puts the parent process to sleep waiting for the child to stop
  //the parents goes into the PROC_WAIT state and sits there
  //until the child enters the PROC_STOP,
  //at which point the parent wakes up and restarts its PUT system call .
  
  if(cmd & SYS_REGS){//#define SYS_REGS 0x00001000
  1039a7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1039aa:	25 00 10 00 00       	and    $0x1000,%eax
  1039af:	85 c0                	test   %eax,%eax
  1039b1:	0f 84 9f 00 00 00    	je     103a56 <do_put+0x144>
    memmove(&(child->sv.tf.regs), &(cstate->tf.regs), sizeof(pushregs));
  1039b7:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1039ba:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1039bd:	81 c2 50 04 00 00    	add    $0x450,%edx
  1039c3:	c7 44 24 08 20 00 00 	movl   $0x20,0x8(%esp)
  1039ca:	00 
  1039cb:	89 44 24 04          	mov    %eax,0x4(%esp)
  1039cf:	89 14 24             	mov    %edx,(%esp)
  1039d2:	e8 58 1a 00 00       	call   10542f <memmove>
    child->sv.tf.ds = CPU_GDT_UDATA | 3;
  1039d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1039da:	66 c7 80 7c 04 00 00 	movw   $0x23,0x47c(%eax)
  1039e1:	23 00 
    child->sv.tf.es = CPU_GDT_UDATA | 3;
  1039e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1039e6:	66 c7 80 78 04 00 00 	movw   $0x23,0x478(%eax)
  1039ed:	23 00 
    child->sv.tf.cs = CPU_GDT_UCODE | 3;
  1039ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1039f2:	66 c7 80 8c 04 00 00 	movw   $0x1b,0x48c(%eax)
  1039f9:	1b 00 
    child->sv.tf.ss = CPU_GDT_UDATA | 3;
  1039fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1039fe:	66 c7 80 98 04 00 00 	movw   $0x23,0x498(%eax)
  103a05:	23 00 
    child->sv.tf.eip =  cstate->tf.eip;
  103a07:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103a0a:	8b 50 38             	mov    0x38(%eax),%edx
  103a0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a10:	89 90 88 04 00 00    	mov    %edx,0x488(%eax)
    child->sv.tf.esp =  cstate->tf.esp;
  103a16:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103a19:	8b 50 44             	mov    0x44(%eax),%edx
  103a1c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a1f:	89 90 94 04 00 00    	mov    %edx,0x494(%eax)
    child->sv.tf.eflags &= FL_USER;
  103a25:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a28:	8b 80 90 04 00 00    	mov    0x490(%eax),%eax
  103a2e:	89 c2                	mov    %eax,%edx
  103a30:	81 e2 d5 0c 00 00    	and    $0xcd5,%edx
  103a36:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a39:	89 90 90 04 00 00    	mov    %edx,0x490(%eax)
    child->sv.tf.eflags |= FL_IF;
  103a3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a42:	8b 80 90 04 00 00    	mov    0x490(%eax),%eax
  103a48:	89 c2                	mov    %eax,%edx
  103a4a:	80 ce 02             	or     $0x2,%dh
  103a4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a50:	89 90 90 04 00 00    	mov    %edx,0x490(%eax)
  }
  if(cmd & SYS_START)
  103a56:	8b 45 0c             	mov    0xc(%ebp),%eax
  103a59:	83 e0 10             	and    $0x10,%eax
  103a5c:	85 c0                	test   %eax,%eax
  103a5e:	74 0b                	je     103a6b <do_put+0x159>
    proc_ready(child);
  103a60:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a63:	89 04 24             	mov    %eax,(%esp)
  103a66:	e8 ea f3 ff ff       	call   102e55 <proc_ready>
  trap_return(tf);
  103a6b:	8b 45 08             	mov    0x8(%ebp),%eax
  103a6e:	89 04 24             	mov    %eax,(%esp)
  103a71:	e8 aa e6 ff ff       	call   102120 <trap_return>

00103a76 <do_get>:
}

static void 
do_get(trapframe *tf, uint32_t cmd)
{
  103a76:	55                   	push   %ebp
  103a77:	89 e5                	mov    %esp,%ebp
  103a79:	83 ec 38             	sub    $0x38,%esp
  //need to rethink setting lock
  proc *curr = proc_cur();
  103a7c:	e8 2b fd ff ff       	call   1037ac <cpu_cur>
  103a81:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  103a87:	89 45 f4             	mov    %eax,-0xc(%ebp)
  procstate *cstate = (procstate*)tf->regs.ebx;
  103a8a:	8b 45 08             	mov    0x8(%ebp),%eax
  103a8d:	8b 40 10             	mov    0x10(%eax),%eax
  103a90:	89 45 f0             	mov    %eax,-0x10(%ebp)
  spinlock_acquire(&curr->lock);
  103a93:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a96:	89 04 24             	mov    %eax,(%esp)
  103a99:	e8 3e eb ff ff       	call   1025dc <spinlock_acquire>
  int child_index = tf->regs.edx;
  103a9e:	8b 45 08             	mov    0x8(%ebp),%eax
  103aa1:	8b 40 14             	mov    0x14(%eax),%eax
  103aa4:	89 45 ec             	mov    %eax,-0x14(%ebp)
  uint32_t cn = child_index & 0xff;
  103aa7:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103aaa:	25 ff 00 00 00       	and    $0xff,%eax
  103aaf:	89 45 e8             	mov    %eax,-0x18(%ebp)
  proc *child = curr->child[cn];
  103ab2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103ab5:	8b 55 e8             	mov    -0x18(%ebp),%edx
  103ab8:	83 c2 0c             	add    $0xc,%edx
  103abb:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
  103abf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  spinlock_release(&curr->lock);
  103ac2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103ac5:	89 04 24             	mov    %eax,(%esp)
  103ac8:	e8 8b eb ff ff       	call   102658 <spinlock_release>
  assert(child != NULL);
  103acd:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  103ad1:	75 24                	jne    103af7 <do_get+0x81>
  103ad3:	c7 44 24 0c 93 68 10 	movl   $0x106893,0xc(%esp)
  103ada:	00 
  103adb:	c7 44 24 08 06 68 10 	movl   $0x106806,0x8(%esp)
  103ae2:	00 
  103ae3:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
  103aea:	00 
  103aeb:	c7 04 24 41 68 10 00 	movl   $0x106841,(%esp)
  103af2:	e8 cd c9 ff ff       	call   1004c4 <debug_panic>
  if(child->state != PROC_STOP){
  103af7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103afa:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  103b00:	85 c0                	test   %eax,%eax
  103b02:	74 19                	je     103b1d <do_get+0xa7>
    proc_wait(curr, child, tf);
  103b04:	8b 45 08             	mov    0x8(%ebp),%eax
  103b07:	89 44 24 08          	mov    %eax,0x8(%esp)
  103b0b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103b0e:	89 44 24 04          	mov    %eax,0x4(%esp)
  103b12:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103b15:	89 04 24             	mov    %eax,(%esp)
  103b18:	e8 15 f4 ff ff       	call   102f32 <proc_wait>
  }
  if(cmd & SYS_REGS)
  103b1d:	8b 45 0c             	mov    0xc(%ebp),%eax
  103b20:	25 00 10 00 00       	and    $0x1000,%eax
  103b25:	85 c0                	test   %eax,%eax
  103b27:	74 20                	je     103b49 <do_get+0xd3>
    memmove(&(cstate->tf), &(child->sv.tf),sizeof(trapframe));
  103b29:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103b2c:	8d 90 50 04 00 00    	lea    0x450(%eax),%edx
  103b32:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103b35:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
  103b3c:	00 
  103b3d:	89 54 24 04          	mov    %edx,0x4(%esp)
  103b41:	89 04 24             	mov    %eax,(%esp)
  103b44:	e8 e6 18 00 00       	call   10542f <memmove>
  trap_return(tf);
  103b49:	8b 45 08             	mov    0x8(%ebp),%eax
  103b4c:	89 04 24             	mov    %eax,(%esp)
  103b4f:	e8 cc e5 ff ff       	call   102120 <trap_return>

00103b54 <do_ret>:
}

static void
do_ret(trapframe *tf)
{
  103b54:	55                   	push   %ebp
  103b55:	89 e5                	mov    %esp,%ebp
  103b57:	83 ec 18             	sub    $0x18,%esp
  proc_ret(tf, 1);
  103b5a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  103b61:	00 
  103b62:	8b 45 08             	mov    0x8(%ebp),%eax
  103b65:	89 04 24             	mov    %eax,(%esp)
  103b68:	e8 60 f5 ff ff       	call   1030cd <proc_ret>

00103b6d <syscall>:
//	EDI:	Get/put child memory region start
//	EBP:	reserved

void
syscall(trapframe *tf)
{
  103b6d:	55                   	push   %ebp
  103b6e:	89 e5                	mov    %esp,%ebp
  103b70:	83 ec 28             	sub    $0x28,%esp
	// EAX register holds system call command/flags
	uint32_t cmd = tf->regs.eax;
  103b73:	8b 45 08             	mov    0x8(%ebp),%eax
  103b76:	8b 40 1c             	mov    0x1c(%eax),%eax
  103b79:	89 45 f4             	mov    %eax,-0xc(%ebp)
	switch (cmd & SYS_TYPE) {
  103b7c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103b7f:	83 e0 0f             	and    $0xf,%eax
  103b82:	83 f8 01             	cmp    $0x1,%eax
  103b85:	74 25                	je     103bac <syscall+0x3f>
  103b87:	83 f8 01             	cmp    $0x1,%eax
  103b8a:	72 0c                	jb     103b98 <syscall+0x2b>
  103b8c:	83 f8 02             	cmp    $0x2,%eax
  103b8f:	74 2f                	je     103bc0 <syscall+0x53>
  103b91:	83 f8 03             	cmp    $0x3,%eax
  103b94:	74 3e                	je     103bd4 <syscall+0x67>
  103b96:	eb 49                	jmp    103be1 <syscall+0x74>
	case SYS_CPUTS:	return do_cputs(tf, cmd);
  103b98:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103b9b:	89 44 24 04          	mov    %eax,0x4(%esp)
  103b9f:	8b 45 08             	mov    0x8(%ebp),%eax
  103ba2:	89 04 24             	mov    %eax,(%esp)
  103ba5:	e8 41 fd ff ff       	call   1038eb <do_cputs>
  103baa:	eb 36                	jmp    103be2 <syscall+0x75>
	// Your implementations of SYS_PUT, SYS_GET, SYS_RET here...
	case SYS_PUT: 
	  return do_put(tf, cmd);
  103bac:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103baf:	89 44 24 04          	mov    %eax,0x4(%esp)
  103bb3:	8b 45 08             	mov    0x8(%ebp),%eax
  103bb6:	89 04 24             	mov    %eax,(%esp)
  103bb9:	e8 54 fd ff ff       	call   103912 <do_put>
  103bbe:	eb 22                	jmp    103be2 <syscall+0x75>
	case SYS_GET:
	  return do_get(tf, cmd);
  103bc0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103bc3:	89 44 24 04          	mov    %eax,0x4(%esp)
  103bc7:	8b 45 08             	mov    0x8(%ebp),%eax
  103bca:	89 04 24             	mov    %eax,(%esp)
  103bcd:	e8 a4 fe ff ff       	call   103a76 <do_get>
  103bd2:	eb 0e                	jmp    103be2 <syscall+0x75>
	case SYS_RET:
	  return do_ret(tf);
  103bd4:	8b 45 08             	mov    0x8(%ebp),%eax
  103bd7:	89 04 24             	mov    %eax,(%esp)
  103bda:	e8 75 ff ff ff       	call   103b54 <do_ret>
  103bdf:	eb 01                	jmp    103be2 <syscall+0x75>
	default:	return;		// handle as a regular trap
  103be1:	90                   	nop
	}
}
  103be2:	c9                   	leave  
  103be3:	c3                   	ret    

00103be4 <video_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

void
video_init(void)
{
  103be4:	55                   	push   %ebp
  103be5:	89 e5                	mov    %esp,%ebp
  103be7:	53                   	push   %ebx
  103be8:	83 ec 34             	sub    $0x34,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	/* Get a pointer to the memory-mapped text display buffer. */
	cp = (uint16_t*) mem_ptr(CGA_BUF);
  103beb:	c7 45 f8 00 80 0b 00 	movl   $0xb8000,-0x8(%ebp)
	was = *cp;
  103bf2:	8b 45 f8             	mov    -0x8(%ebp),%eax
  103bf5:	0f b7 00             	movzwl (%eax),%eax
  103bf8:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
	*cp = (uint16_t) 0xA55A;
  103bfc:	8b 45 f8             	mov    -0x8(%ebp),%eax
  103bff:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
  103c04:	8b 45 f8             	mov    -0x8(%ebp),%eax
  103c07:	0f b7 00             	movzwl (%eax),%eax
  103c0a:	66 3d 5a a5          	cmp    $0xa55a,%ax
  103c0e:	74 13                	je     103c23 <video_init+0x3f>
		cp = (uint16_t*) mem_ptr(MONO_BUF);
  103c10:	c7 45 f8 00 00 0b 00 	movl   $0xb0000,-0x8(%ebp)
		addr_6845 = MONO_BASE;
  103c17:	c7 05 d8 f2 10 00 b4 	movl   $0x3b4,0x10f2d8
  103c1e:	03 00 00 
  103c21:	eb 14                	jmp    103c37 <video_init+0x53>
	} else {
		*cp = was;
  103c23:	8b 45 f8             	mov    -0x8(%ebp),%eax
  103c26:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
  103c2a:	66 89 10             	mov    %dx,(%eax)
		addr_6845 = CGA_BASE;
  103c2d:	c7 05 d8 f2 10 00 d4 	movl   $0x3d4,0x10f2d8
  103c34:	03 00 00 
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
  103c37:	a1 d8 f2 10 00       	mov    0x10f2d8,%eax
  103c3c:	89 45 ec             	mov    %eax,-0x14(%ebp)
  103c3f:	c6 45 eb 0e          	movb   $0xe,-0x15(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  103c43:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  103c47:	8b 55 ec             	mov    -0x14(%ebp),%edx
  103c4a:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
  103c4b:	a1 d8 f2 10 00       	mov    0x10f2d8,%eax
  103c50:	83 c0 01             	add    $0x1,%eax
  103c53:	89 45 e4             	mov    %eax,-0x1c(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103c56:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  103c59:	89 55 c8             	mov    %edx,-0x38(%ebp)
  103c5c:	8b 55 c8             	mov    -0x38(%ebp),%edx
  103c5f:	ec                   	in     (%dx),%al
  103c60:	89 c3                	mov    %eax,%ebx
  103c62:	88 5d e3             	mov    %bl,-0x1d(%ebp)
	return data;
  103c65:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  103c69:	0f b6 c0             	movzbl %al,%eax
  103c6c:	c1 e0 08             	shl    $0x8,%eax
  103c6f:	89 45 f0             	mov    %eax,-0x10(%ebp)
	outb(addr_6845, 15);
  103c72:	a1 d8 f2 10 00       	mov    0x10f2d8,%eax
  103c77:	89 45 dc             	mov    %eax,-0x24(%ebp)
  103c7a:	c6 45 db 0f          	movb   $0xf,-0x25(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  103c7e:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  103c82:	8b 55 dc             	mov    -0x24(%ebp),%edx
  103c85:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
  103c86:	a1 d8 f2 10 00       	mov    0x10f2d8,%eax
  103c8b:	83 c0 01             	add    $0x1,%eax
  103c8e:	89 45 d4             	mov    %eax,-0x2c(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103c91:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  103c94:	89 55 c8             	mov    %edx,-0x38(%ebp)
  103c97:	8b 55 c8             	mov    -0x38(%ebp),%edx
  103c9a:	ec                   	in     (%dx),%al
  103c9b:	89 c3                	mov    %eax,%ebx
  103c9d:	88 5d d3             	mov    %bl,-0x2d(%ebp)
	return data;
  103ca0:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
  103ca4:	0f b6 c0             	movzbl %al,%eax
  103ca7:	09 45 f0             	or     %eax,-0x10(%ebp)

	crt_buf = (uint16_t*) cp;
  103caa:	8b 45 f8             	mov    -0x8(%ebp),%eax
  103cad:	a3 dc f2 10 00       	mov    %eax,0x10f2dc
	crt_pos = pos;
  103cb2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103cb5:	66 a3 e0 f2 10 00    	mov    %ax,0x10f2e0
}
  103cbb:	83 c4 34             	add    $0x34,%esp
  103cbe:	5b                   	pop    %ebx
  103cbf:	5d                   	pop    %ebp
  103cc0:	c3                   	ret    

00103cc1 <video_putc>:



void
video_putc(int c)
{
  103cc1:	55                   	push   %ebp
  103cc2:	89 e5                	mov    %esp,%ebp
  103cc4:	53                   	push   %ebx
  103cc5:	83 ec 44             	sub    $0x44,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
  103cc8:	8b 45 08             	mov    0x8(%ebp),%eax
  103ccb:	b0 00                	mov    $0x0,%al
  103ccd:	85 c0                	test   %eax,%eax
  103ccf:	75 07                	jne    103cd8 <video_putc+0x17>
		c |= 0x0700;
  103cd1:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)

	switch (c & 0xff) {
  103cd8:	8b 45 08             	mov    0x8(%ebp),%eax
  103cdb:	25 ff 00 00 00       	and    $0xff,%eax
  103ce0:	83 f8 09             	cmp    $0x9,%eax
  103ce3:	0f 84 ab 00 00 00    	je     103d94 <video_putc+0xd3>
  103ce9:	83 f8 09             	cmp    $0x9,%eax
  103cec:	7f 0a                	jg     103cf8 <video_putc+0x37>
  103cee:	83 f8 08             	cmp    $0x8,%eax
  103cf1:	74 14                	je     103d07 <video_putc+0x46>
  103cf3:	e9 da 00 00 00       	jmp    103dd2 <video_putc+0x111>
  103cf8:	83 f8 0a             	cmp    $0xa,%eax
  103cfb:	74 4d                	je     103d4a <video_putc+0x89>
  103cfd:	83 f8 0d             	cmp    $0xd,%eax
  103d00:	74 58                	je     103d5a <video_putc+0x99>
  103d02:	e9 cb 00 00 00       	jmp    103dd2 <video_putc+0x111>
	case '\b':
		if (crt_pos > 0) {
  103d07:	0f b7 05 e0 f2 10 00 	movzwl 0x10f2e0,%eax
  103d0e:	66 85 c0             	test   %ax,%ax
  103d11:	0f 84 e0 00 00 00    	je     103df7 <video_putc+0x136>
			crt_pos--;
  103d17:	0f b7 05 e0 f2 10 00 	movzwl 0x10f2e0,%eax
  103d1e:	83 e8 01             	sub    $0x1,%eax
  103d21:	66 a3 e0 f2 10 00    	mov    %ax,0x10f2e0
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
  103d27:	a1 dc f2 10 00       	mov    0x10f2dc,%eax
  103d2c:	0f b7 15 e0 f2 10 00 	movzwl 0x10f2e0,%edx
  103d33:	0f b7 d2             	movzwl %dx,%edx
  103d36:	01 d2                	add    %edx,%edx
  103d38:	01 c2                	add    %eax,%edx
  103d3a:	8b 45 08             	mov    0x8(%ebp),%eax
  103d3d:	b0 00                	mov    $0x0,%al
  103d3f:	83 c8 20             	or     $0x20,%eax
  103d42:	66 89 02             	mov    %ax,(%edx)
		}
		break;
  103d45:	e9 ad 00 00 00       	jmp    103df7 <video_putc+0x136>
	case '\n':
		crt_pos += CRT_COLS;
  103d4a:	0f b7 05 e0 f2 10 00 	movzwl 0x10f2e0,%eax
  103d51:	83 c0 50             	add    $0x50,%eax
  103d54:	66 a3 e0 f2 10 00    	mov    %ax,0x10f2e0
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
  103d5a:	0f b7 1d e0 f2 10 00 	movzwl 0x10f2e0,%ebx
  103d61:	0f b7 0d e0 f2 10 00 	movzwl 0x10f2e0,%ecx
  103d68:	0f b7 c1             	movzwl %cx,%eax
  103d6b:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
  103d71:	c1 e8 10             	shr    $0x10,%eax
  103d74:	89 c2                	mov    %eax,%edx
  103d76:	66 c1 ea 06          	shr    $0x6,%dx
  103d7a:	89 d0                	mov    %edx,%eax
  103d7c:	c1 e0 02             	shl    $0x2,%eax
  103d7f:	01 d0                	add    %edx,%eax
  103d81:	c1 e0 04             	shl    $0x4,%eax
  103d84:	89 ca                	mov    %ecx,%edx
  103d86:	29 c2                	sub    %eax,%edx
  103d88:	89 d8                	mov    %ebx,%eax
  103d8a:	29 d0                	sub    %edx,%eax
  103d8c:	66 a3 e0 f2 10 00    	mov    %ax,0x10f2e0
		break;
  103d92:	eb 64                	jmp    103df8 <video_putc+0x137>
	case '\t':
		video_putc(' ');
  103d94:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  103d9b:	e8 21 ff ff ff       	call   103cc1 <video_putc>
		video_putc(' ');
  103da0:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  103da7:	e8 15 ff ff ff       	call   103cc1 <video_putc>
		video_putc(' ');
  103dac:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  103db3:	e8 09 ff ff ff       	call   103cc1 <video_putc>
		video_putc(' ');
  103db8:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  103dbf:	e8 fd fe ff ff       	call   103cc1 <video_putc>
		video_putc(' ');
  103dc4:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  103dcb:	e8 f1 fe ff ff       	call   103cc1 <video_putc>
		break;
  103dd0:	eb 26                	jmp    103df8 <video_putc+0x137>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
  103dd2:	8b 15 dc f2 10 00    	mov    0x10f2dc,%edx
  103dd8:	0f b7 05 e0 f2 10 00 	movzwl 0x10f2e0,%eax
  103ddf:	0f b7 c8             	movzwl %ax,%ecx
  103de2:	01 c9                	add    %ecx,%ecx
  103de4:	01 d1                	add    %edx,%ecx
  103de6:	8b 55 08             	mov    0x8(%ebp),%edx
  103de9:	66 89 11             	mov    %dx,(%ecx)
  103dec:	83 c0 01             	add    $0x1,%eax
  103def:	66 a3 e0 f2 10 00    	mov    %ax,0x10f2e0
		break;
  103df5:	eb 01                	jmp    103df8 <video_putc+0x137>
	case '\b':
		if (crt_pos > 0) {
			crt_pos--;
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
		}
		break;
  103df7:	90                   	nop
		crt_buf[crt_pos++] = c;		/* write the character */
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
  103df8:	0f b7 05 e0 f2 10 00 	movzwl 0x10f2e0,%eax
  103dff:	66 3d cf 07          	cmp    $0x7cf,%ax
  103e03:	76 5b                	jbe    103e60 <video_putc+0x19f>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
  103e05:	a1 dc f2 10 00       	mov    0x10f2dc,%eax
  103e0a:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
  103e10:	a1 dc f2 10 00       	mov    0x10f2dc,%eax
  103e15:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
  103e1c:	00 
  103e1d:	89 54 24 04          	mov    %edx,0x4(%esp)
  103e21:	89 04 24             	mov    %eax,(%esp)
  103e24:	e8 06 16 00 00       	call   10542f <memmove>
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  103e29:	c7 45 f4 80 07 00 00 	movl   $0x780,-0xc(%ebp)
  103e30:	eb 15                	jmp    103e47 <video_putc+0x186>
			crt_buf[i] = 0x0700 | ' ';
  103e32:	a1 dc f2 10 00       	mov    0x10f2dc,%eax
  103e37:	8b 55 f4             	mov    -0xc(%ebp),%edx
  103e3a:	01 d2                	add    %edx,%edx
  103e3c:	01 d0                	add    %edx,%eax
  103e3e:	66 c7 00 20 07       	movw   $0x720,(%eax)
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  103e43:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  103e47:	81 7d f4 cf 07 00 00 	cmpl   $0x7cf,-0xc(%ebp)
  103e4e:	7e e2                	jle    103e32 <video_putc+0x171>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
  103e50:	0f b7 05 e0 f2 10 00 	movzwl 0x10f2e0,%eax
  103e57:	83 e8 50             	sub    $0x50,%eax
  103e5a:	66 a3 e0 f2 10 00    	mov    %ax,0x10f2e0
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
  103e60:	a1 d8 f2 10 00       	mov    0x10f2d8,%eax
  103e65:	89 45 f0             	mov    %eax,-0x10(%ebp)
  103e68:	c6 45 ef 0e          	movb   $0xe,-0x11(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  103e6c:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
  103e70:	8b 55 f0             	mov    -0x10(%ebp),%edx
  103e73:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
  103e74:	0f b7 05 e0 f2 10 00 	movzwl 0x10f2e0,%eax
  103e7b:	66 c1 e8 08          	shr    $0x8,%ax
  103e7f:	0f b6 c0             	movzbl %al,%eax
  103e82:	8b 15 d8 f2 10 00    	mov    0x10f2d8,%edx
  103e88:	83 c2 01             	add    $0x1,%edx
  103e8b:	89 55 e8             	mov    %edx,-0x18(%ebp)
  103e8e:	88 45 e7             	mov    %al,-0x19(%ebp)
  103e91:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  103e95:	8b 55 e8             	mov    -0x18(%ebp),%edx
  103e98:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
  103e99:	a1 d8 f2 10 00       	mov    0x10f2d8,%eax
  103e9e:	89 45 e0             	mov    %eax,-0x20(%ebp)
  103ea1:	c6 45 df 0f          	movb   $0xf,-0x21(%ebp)
  103ea5:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
  103ea9:	8b 55 e0             	mov    -0x20(%ebp),%edx
  103eac:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
  103ead:	0f b7 05 e0 f2 10 00 	movzwl 0x10f2e0,%eax
  103eb4:	0f b6 c0             	movzbl %al,%eax
  103eb7:	8b 15 d8 f2 10 00    	mov    0x10f2d8,%edx
  103ebd:	83 c2 01             	add    $0x1,%edx
  103ec0:	89 55 d8             	mov    %edx,-0x28(%ebp)
  103ec3:	88 45 d7             	mov    %al,-0x29(%ebp)
  103ec6:	0f b6 45 d7          	movzbl -0x29(%ebp),%eax
  103eca:	8b 55 d8             	mov    -0x28(%ebp),%edx
  103ecd:	ee                   	out    %al,(%dx)
}
  103ece:	83 c4 44             	add    $0x44,%esp
  103ed1:	5b                   	pop    %ebx
  103ed2:	5d                   	pop    %ebp
  103ed3:	c3                   	ret    

00103ed4 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
  103ed4:	55                   	push   %ebp
  103ed5:	89 e5                	mov    %esp,%ebp
  103ed7:	53                   	push   %ebx
  103ed8:	83 ec 44             	sub    $0x44,%esp
  103edb:	c7 45 ec 64 00 00 00 	movl   $0x64,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103ee2:	8b 55 ec             	mov    -0x14(%ebp),%edx
  103ee5:	89 55 d4             	mov    %edx,-0x2c(%ebp)
  103ee8:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  103eeb:	ec                   	in     (%dx),%al
  103eec:	89 c3                	mov    %eax,%ebx
  103eee:	88 5d eb             	mov    %bl,-0x15(%ebp)
	return data;
  103ef1:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
  103ef5:	0f b6 c0             	movzbl %al,%eax
  103ef8:	83 e0 01             	and    $0x1,%eax
  103efb:	85 c0                	test   %eax,%eax
  103efd:	75 0a                	jne    103f09 <kbd_proc_data+0x35>
		return -1;
  103eff:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  103f04:	e9 5f 01 00 00       	jmp    104068 <kbd_proc_data+0x194>
  103f09:	c7 45 e4 60 00 00 00 	movl   $0x60,-0x1c(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103f10:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  103f13:	89 55 d4             	mov    %edx,-0x2c(%ebp)
  103f16:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  103f19:	ec                   	in     (%dx),%al
  103f1a:	89 c3                	mov    %eax,%ebx
  103f1c:	88 5d e3             	mov    %bl,-0x1d(%ebp)
	return data;
  103f1f:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax

	data = inb(KBDATAP);
  103f23:	88 45 f3             	mov    %al,-0xd(%ebp)

	if (data == 0xE0) {
  103f26:	80 7d f3 e0          	cmpb   $0xe0,-0xd(%ebp)
  103f2a:	75 17                	jne    103f43 <kbd_proc_data+0x6f>
		// E0 escape character
		shift |= E0ESC;
  103f2c:	a1 e4 f2 10 00       	mov    0x10f2e4,%eax
  103f31:	83 c8 40             	or     $0x40,%eax
  103f34:	a3 e4 f2 10 00       	mov    %eax,0x10f2e4
		return 0;
  103f39:	b8 00 00 00 00       	mov    $0x0,%eax
  103f3e:	e9 25 01 00 00       	jmp    104068 <kbd_proc_data+0x194>
	} else if (data & 0x80) {
  103f43:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  103f47:	84 c0                	test   %al,%al
  103f49:	79 47                	jns    103f92 <kbd_proc_data+0xbe>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
  103f4b:	a1 e4 f2 10 00       	mov    0x10f2e4,%eax
  103f50:	83 e0 40             	and    $0x40,%eax
  103f53:	85 c0                	test   %eax,%eax
  103f55:	75 09                	jne    103f60 <kbd_proc_data+0x8c>
  103f57:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  103f5b:	83 e0 7f             	and    $0x7f,%eax
  103f5e:	eb 04                	jmp    103f64 <kbd_proc_data+0x90>
  103f60:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  103f64:	88 45 f3             	mov    %al,-0xd(%ebp)
		shift &= ~(shiftcode[data] | E0ESC);
  103f67:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  103f6b:	0f b6 80 e0 90 10 00 	movzbl 0x1090e0(%eax),%eax
  103f72:	83 c8 40             	or     $0x40,%eax
  103f75:	0f b6 c0             	movzbl %al,%eax
  103f78:	f7 d0                	not    %eax
  103f7a:	89 c2                	mov    %eax,%edx
  103f7c:	a1 e4 f2 10 00       	mov    0x10f2e4,%eax
  103f81:	21 d0                	and    %edx,%eax
  103f83:	a3 e4 f2 10 00       	mov    %eax,0x10f2e4
		return 0;
  103f88:	b8 00 00 00 00       	mov    $0x0,%eax
  103f8d:	e9 d6 00 00 00       	jmp    104068 <kbd_proc_data+0x194>
	} else if (shift & E0ESC) {
  103f92:	a1 e4 f2 10 00       	mov    0x10f2e4,%eax
  103f97:	83 e0 40             	and    $0x40,%eax
  103f9a:	85 c0                	test   %eax,%eax
  103f9c:	74 11                	je     103faf <kbd_proc_data+0xdb>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
  103f9e:	80 4d f3 80          	orb    $0x80,-0xd(%ebp)
		shift &= ~E0ESC;
  103fa2:	a1 e4 f2 10 00       	mov    0x10f2e4,%eax
  103fa7:	83 e0 bf             	and    $0xffffffbf,%eax
  103faa:	a3 e4 f2 10 00       	mov    %eax,0x10f2e4
	}

	shift |= shiftcode[data];
  103faf:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  103fb3:	0f b6 80 e0 90 10 00 	movzbl 0x1090e0(%eax),%eax
  103fba:	0f b6 d0             	movzbl %al,%edx
  103fbd:	a1 e4 f2 10 00       	mov    0x10f2e4,%eax
  103fc2:	09 d0                	or     %edx,%eax
  103fc4:	a3 e4 f2 10 00       	mov    %eax,0x10f2e4
	shift ^= togglecode[data];
  103fc9:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  103fcd:	0f b6 80 e0 91 10 00 	movzbl 0x1091e0(%eax),%eax
  103fd4:	0f b6 d0             	movzbl %al,%edx
  103fd7:	a1 e4 f2 10 00       	mov    0x10f2e4,%eax
  103fdc:	31 d0                	xor    %edx,%eax
  103fde:	a3 e4 f2 10 00       	mov    %eax,0x10f2e4

	c = charcode[shift & (CTL | SHIFT)][data];
  103fe3:	a1 e4 f2 10 00       	mov    0x10f2e4,%eax
  103fe8:	83 e0 03             	and    $0x3,%eax
  103feb:	8b 14 85 e0 95 10 00 	mov    0x1095e0(,%eax,4),%edx
  103ff2:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  103ff6:	01 d0                	add    %edx,%eax
  103ff8:	0f b6 00             	movzbl (%eax),%eax
  103ffb:	0f b6 c0             	movzbl %al,%eax
  103ffe:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (shift & CAPSLOCK) {
  104001:	a1 e4 f2 10 00       	mov    0x10f2e4,%eax
  104006:	83 e0 08             	and    $0x8,%eax
  104009:	85 c0                	test   %eax,%eax
  10400b:	74 22                	je     10402f <kbd_proc_data+0x15b>
		if ('a' <= c && c <= 'z')
  10400d:	83 7d f4 60          	cmpl   $0x60,-0xc(%ebp)
  104011:	7e 0c                	jle    10401f <kbd_proc_data+0x14b>
  104013:	83 7d f4 7a          	cmpl   $0x7a,-0xc(%ebp)
  104017:	7f 06                	jg     10401f <kbd_proc_data+0x14b>
			c += 'A' - 'a';
  104019:	83 6d f4 20          	subl   $0x20,-0xc(%ebp)
  10401d:	eb 10                	jmp    10402f <kbd_proc_data+0x15b>
		else if ('A' <= c && c <= 'Z')
  10401f:	83 7d f4 40          	cmpl   $0x40,-0xc(%ebp)
  104023:	7e 0a                	jle    10402f <kbd_proc_data+0x15b>
  104025:	83 7d f4 5a          	cmpl   $0x5a,-0xc(%ebp)
  104029:	7f 04                	jg     10402f <kbd_proc_data+0x15b>
			c += 'a' - 'A';
  10402b:	83 45 f4 20          	addl   $0x20,-0xc(%ebp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
  10402f:	a1 e4 f2 10 00       	mov    0x10f2e4,%eax
  104034:	f7 d0                	not    %eax
  104036:	83 e0 06             	and    $0x6,%eax
  104039:	85 c0                	test   %eax,%eax
  10403b:	75 28                	jne    104065 <kbd_proc_data+0x191>
  10403d:	81 7d f4 e9 00 00 00 	cmpl   $0xe9,-0xc(%ebp)
  104044:	75 1f                	jne    104065 <kbd_proc_data+0x191>
		cprintf("Rebooting!\n");
  104046:	c7 04 24 a1 68 10 00 	movl   $0x1068a1,(%esp)
  10404d:	e8 8a 11 00 00       	call   1051dc <cprintf>
  104052:	c7 45 dc 92 00 00 00 	movl   $0x92,-0x24(%ebp)
  104059:	c6 45 db 03          	movb   $0x3,-0x25(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10405d:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  104061:	8b 55 dc             	mov    -0x24(%ebp),%edx
  104064:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
  104065:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  104068:	83 c4 44             	add    $0x44,%esp
  10406b:	5b                   	pop    %ebx
  10406c:	5d                   	pop    %ebp
  10406d:	c3                   	ret    

0010406e <kbd_intr>:

void
kbd_intr(void)
{
  10406e:	55                   	push   %ebp
  10406f:	89 e5                	mov    %esp,%ebp
  104071:	83 ec 18             	sub    $0x18,%esp
	cons_intr(kbd_proc_data);
  104074:	c7 04 24 d4 3e 10 00 	movl   $0x103ed4,(%esp)
  10407b:	e8 72 c2 ff ff       	call   1002f2 <cons_intr>
}
  104080:	c9                   	leave  
  104081:	c3                   	ret    

00104082 <kbd_init>:

void
kbd_init(void)
{
  104082:	55                   	push   %ebp
  104083:	89 e5                	mov    %esp,%ebp
}
  104085:	5d                   	pop    %ebp
  104086:	c3                   	ret    
  104087:	90                   	nop

00104088 <delay>:


// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
  104088:	55                   	push   %ebp
  104089:	89 e5                	mov    %esp,%ebp
  10408b:	53                   	push   %ebx
  10408c:	83 ec 24             	sub    $0x24,%esp
  10408f:	c7 45 f8 84 00 00 00 	movl   $0x84,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  104096:	8b 55 f8             	mov    -0x8(%ebp),%edx
  104099:	89 55 d8             	mov    %edx,-0x28(%ebp)
  10409c:	8b 55 d8             	mov    -0x28(%ebp),%edx
  10409f:	ec                   	in     (%dx),%al
  1040a0:	89 c3                	mov    %eax,%ebx
  1040a2:	88 5d f7             	mov    %bl,-0x9(%ebp)
  1040a5:	c7 45 f0 84 00 00 00 	movl   $0x84,-0x10(%ebp)
  1040ac:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1040af:	89 55 d8             	mov    %edx,-0x28(%ebp)
  1040b2:	8b 55 d8             	mov    -0x28(%ebp),%edx
  1040b5:	ec                   	in     (%dx),%al
  1040b6:	89 c3                	mov    %eax,%ebx
  1040b8:	88 5d ef             	mov    %bl,-0x11(%ebp)
  1040bb:	c7 45 e8 84 00 00 00 	movl   $0x84,-0x18(%ebp)
  1040c2:	8b 55 e8             	mov    -0x18(%ebp),%edx
  1040c5:	89 55 d8             	mov    %edx,-0x28(%ebp)
  1040c8:	8b 55 d8             	mov    -0x28(%ebp),%edx
  1040cb:	ec                   	in     (%dx),%al
  1040cc:	89 c3                	mov    %eax,%ebx
  1040ce:	88 5d e7             	mov    %bl,-0x19(%ebp)
  1040d1:	c7 45 e0 84 00 00 00 	movl   $0x84,-0x20(%ebp)
  1040d8:	8b 55 e0             	mov    -0x20(%ebp),%edx
  1040db:	89 55 d8             	mov    %edx,-0x28(%ebp)
  1040de:	8b 55 d8             	mov    -0x28(%ebp),%edx
  1040e1:	ec                   	in     (%dx),%al
  1040e2:	89 c3                	mov    %eax,%ebx
  1040e4:	88 5d df             	mov    %bl,-0x21(%ebp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
  1040e7:	83 c4 24             	add    $0x24,%esp
  1040ea:	5b                   	pop    %ebx
  1040eb:	5d                   	pop    %ebp
  1040ec:	c3                   	ret    

001040ed <serial_proc_data>:

static int
serial_proc_data(void)
{
  1040ed:	55                   	push   %ebp
  1040ee:	89 e5                	mov    %esp,%ebp
  1040f0:	53                   	push   %ebx
  1040f1:	83 ec 14             	sub    $0x14,%esp
  1040f4:	c7 45 f8 fd 03 00 00 	movl   $0x3fd,-0x8(%ebp)
  1040fb:	8b 55 f8             	mov    -0x8(%ebp),%edx
  1040fe:	89 55 e8             	mov    %edx,-0x18(%ebp)
  104101:	8b 55 e8             	mov    -0x18(%ebp),%edx
  104104:	ec                   	in     (%dx),%al
  104105:	89 c3                	mov    %eax,%ebx
  104107:	88 5d f7             	mov    %bl,-0x9(%ebp)
	return data;
  10410a:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
  10410e:	0f b6 c0             	movzbl %al,%eax
  104111:	83 e0 01             	and    $0x1,%eax
  104114:	85 c0                	test   %eax,%eax
  104116:	75 07                	jne    10411f <serial_proc_data+0x32>
		return -1;
  104118:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  10411d:	eb 1d                	jmp    10413c <serial_proc_data+0x4f>
  10411f:	c7 45 f0 f8 03 00 00 	movl   $0x3f8,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  104126:	8b 55 f0             	mov    -0x10(%ebp),%edx
  104129:	89 55 e8             	mov    %edx,-0x18(%ebp)
  10412c:	8b 55 e8             	mov    -0x18(%ebp),%edx
  10412f:	ec                   	in     (%dx),%al
  104130:	89 c3                	mov    %eax,%ebx
  104132:	88 5d ef             	mov    %bl,-0x11(%ebp)
	return data;
  104135:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
	return inb(COM1+COM_RX);
  104139:	0f b6 c0             	movzbl %al,%eax
}
  10413c:	83 c4 14             	add    $0x14,%esp
  10413f:	5b                   	pop    %ebx
  104140:	5d                   	pop    %ebp
  104141:	c3                   	ret    

00104142 <serial_intr>:

void
serial_intr(void)
{
  104142:	55                   	push   %ebp
  104143:	89 e5                	mov    %esp,%ebp
  104145:	83 ec 18             	sub    $0x18,%esp
	if (serial_exists)
  104148:	a1 e8 fa 30 00       	mov    0x30fae8,%eax
  10414d:	85 c0                	test   %eax,%eax
  10414f:	74 0c                	je     10415d <serial_intr+0x1b>
		cons_intr(serial_proc_data);
  104151:	c7 04 24 ed 40 10 00 	movl   $0x1040ed,(%esp)
  104158:	e8 95 c1 ff ff       	call   1002f2 <cons_intr>
}
  10415d:	c9                   	leave  
  10415e:	c3                   	ret    

0010415f <serial_putc>:

void
serial_putc(int c)
{
  10415f:	55                   	push   %ebp
  104160:	89 e5                	mov    %esp,%ebp
  104162:	53                   	push   %ebx
  104163:	83 ec 24             	sub    $0x24,%esp
	if (!serial_exists)
  104166:	a1 e8 fa 30 00       	mov    0x30fae8,%eax
  10416b:	85 c0                	test   %eax,%eax
  10416d:	74 59                	je     1041c8 <serial_putc+0x69>
		return;

	int i;
	for (i = 0;
  10416f:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  104176:	eb 09                	jmp    104181 <serial_putc+0x22>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
  104178:	e8 0b ff ff ff       	call   104088 <delay>
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
  10417d:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  104181:	c7 45 f4 fd 03 00 00 	movl   $0x3fd,-0xc(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  104188:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10418b:	89 55 d8             	mov    %edx,-0x28(%ebp)
  10418e:	8b 55 d8             	mov    -0x28(%ebp),%edx
  104191:	ec                   	in     (%dx),%al
  104192:	89 c3                	mov    %eax,%ebx
  104194:	88 5d f3             	mov    %bl,-0xd(%ebp)
	return data;
  104197:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  10419b:	0f b6 c0             	movzbl %al,%eax
  10419e:	83 e0 20             	and    $0x20,%eax
{
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
  1041a1:	85 c0                	test   %eax,%eax
  1041a3:	75 09                	jne    1041ae <serial_putc+0x4f>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  1041a5:	81 7d f8 ff 31 00 00 	cmpl   $0x31ff,-0x8(%ebp)
  1041ac:	7e ca                	jle    104178 <serial_putc+0x19>
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
  1041ae:	8b 45 08             	mov    0x8(%ebp),%eax
  1041b1:	0f b6 c0             	movzbl %al,%eax
  1041b4:	c7 45 ec f8 03 00 00 	movl   $0x3f8,-0x14(%ebp)
  1041bb:	88 45 eb             	mov    %al,-0x15(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1041be:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  1041c2:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1041c5:	ee                   	out    %al,(%dx)
  1041c6:	eb 01                	jmp    1041c9 <serial_putc+0x6a>

void
serial_putc(int c)
{
	if (!serial_exists)
		return;
  1041c8:	90                   	nop
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
}
  1041c9:	83 c4 24             	add    $0x24,%esp
  1041cc:	5b                   	pop    %ebx
  1041cd:	5d                   	pop    %ebp
  1041ce:	c3                   	ret    

001041cf <serial_init>:

void
serial_init(void)
{
  1041cf:	55                   	push   %ebp
  1041d0:	89 e5                	mov    %esp,%ebp
  1041d2:	53                   	push   %ebx
  1041d3:	83 ec 54             	sub    $0x54,%esp
  1041d6:	c7 45 f8 fa 03 00 00 	movl   $0x3fa,-0x8(%ebp)
  1041dd:	c6 45 f7 00          	movb   $0x0,-0x9(%ebp)
  1041e1:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
  1041e5:	8b 55 f8             	mov    -0x8(%ebp),%edx
  1041e8:	ee                   	out    %al,(%dx)
  1041e9:	c7 45 f0 fb 03 00 00 	movl   $0x3fb,-0x10(%ebp)
  1041f0:	c6 45 ef 80          	movb   $0x80,-0x11(%ebp)
  1041f4:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
  1041f8:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1041fb:	ee                   	out    %al,(%dx)
  1041fc:	c7 45 e8 f8 03 00 00 	movl   $0x3f8,-0x18(%ebp)
  104203:	c6 45 e7 0c          	movb   $0xc,-0x19(%ebp)
  104207:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  10420b:	8b 55 e8             	mov    -0x18(%ebp),%edx
  10420e:	ee                   	out    %al,(%dx)
  10420f:	c7 45 e0 f9 03 00 00 	movl   $0x3f9,-0x20(%ebp)
  104216:	c6 45 df 00          	movb   $0x0,-0x21(%ebp)
  10421a:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
  10421e:	8b 55 e0             	mov    -0x20(%ebp),%edx
  104221:	ee                   	out    %al,(%dx)
  104222:	c7 45 d8 fb 03 00 00 	movl   $0x3fb,-0x28(%ebp)
  104229:	c6 45 d7 03          	movb   $0x3,-0x29(%ebp)
  10422d:	0f b6 45 d7          	movzbl -0x29(%ebp),%eax
  104231:	8b 55 d8             	mov    -0x28(%ebp),%edx
  104234:	ee                   	out    %al,(%dx)
  104235:	c7 45 d0 fc 03 00 00 	movl   $0x3fc,-0x30(%ebp)
  10423c:	c6 45 cf 00          	movb   $0x0,-0x31(%ebp)
  104240:	0f b6 45 cf          	movzbl -0x31(%ebp),%eax
  104244:	8b 55 d0             	mov    -0x30(%ebp),%edx
  104247:	ee                   	out    %al,(%dx)
  104248:	c7 45 c8 f9 03 00 00 	movl   $0x3f9,-0x38(%ebp)
  10424f:	c6 45 c7 01          	movb   $0x1,-0x39(%ebp)
  104253:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
  104257:	8b 55 c8             	mov    -0x38(%ebp),%edx
  10425a:	ee                   	out    %al,(%dx)
  10425b:	c7 45 c0 fd 03 00 00 	movl   $0x3fd,-0x40(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  104262:	8b 55 c0             	mov    -0x40(%ebp),%edx
  104265:	89 55 a8             	mov    %edx,-0x58(%ebp)
  104268:	8b 55 a8             	mov    -0x58(%ebp),%edx
  10426b:	ec                   	in     (%dx),%al
  10426c:	89 c3                	mov    %eax,%ebx
  10426e:	88 5d bf             	mov    %bl,-0x41(%ebp)
	return data;
  104271:	0f b6 45 bf          	movzbl -0x41(%ebp),%eax
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
  104275:	3c ff                	cmp    $0xff,%al
  104277:	0f 95 c0             	setne  %al
  10427a:	0f b6 c0             	movzbl %al,%eax
  10427d:	a3 e8 fa 30 00       	mov    %eax,0x30fae8
  104282:	c7 45 b8 fa 03 00 00 	movl   $0x3fa,-0x48(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  104289:	8b 55 b8             	mov    -0x48(%ebp),%edx
  10428c:	89 55 a8             	mov    %edx,-0x58(%ebp)
  10428f:	8b 55 a8             	mov    -0x58(%ebp),%edx
  104292:	ec                   	in     (%dx),%al
  104293:	89 c3                	mov    %eax,%ebx
  104295:	88 5d b7             	mov    %bl,-0x49(%ebp)
  104298:	c7 45 b0 f8 03 00 00 	movl   $0x3f8,-0x50(%ebp)
  10429f:	8b 55 b0             	mov    -0x50(%ebp),%edx
  1042a2:	89 55 a8             	mov    %edx,-0x58(%ebp)
  1042a5:	8b 55 a8             	mov    -0x58(%ebp),%edx
  1042a8:	ec                   	in     (%dx),%al
  1042a9:	89 c3                	mov    %eax,%ebx
  1042ab:	88 5d af             	mov    %bl,-0x51(%ebp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);
}
  1042ae:	83 c4 54             	add    $0x54,%esp
  1042b1:	5b                   	pop    %ebx
  1042b2:	5d                   	pop    %ebp
  1042b3:	c3                   	ret    

001042b4 <pic_init>:
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
  1042b4:	55                   	push   %ebp
  1042b5:	89 e5                	mov    %esp,%ebp
  1042b7:	81 ec 88 00 00 00    	sub    $0x88,%esp
	if (didinit)		// only do once on bootstrap CPU
  1042bd:	a1 e8 f2 10 00       	mov    0x10f2e8,%eax
  1042c2:	85 c0                	test   %eax,%eax
  1042c4:	0f 85 35 01 00 00    	jne    1043ff <pic_init+0x14b>
		return;
	didinit = 1;
  1042ca:	c7 05 e8 f2 10 00 01 	movl   $0x1,0x10f2e8
  1042d1:	00 00 00 
  1042d4:	c7 45 f4 21 00 00 00 	movl   $0x21,-0xc(%ebp)
  1042db:	c6 45 f3 ff          	movb   $0xff,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1042df:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1042e3:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1042e6:	ee                   	out    %al,(%dx)
  1042e7:	c7 45 ec a1 00 00 00 	movl   $0xa1,-0x14(%ebp)
  1042ee:	c6 45 eb ff          	movb   $0xff,-0x15(%ebp)
  1042f2:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  1042f6:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1042f9:	ee                   	out    %al,(%dx)
  1042fa:	c7 45 e4 20 00 00 00 	movl   $0x20,-0x1c(%ebp)
  104301:	c6 45 e3 11          	movb   $0x11,-0x1d(%ebp)
  104305:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  104309:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  10430c:	ee                   	out    %al,(%dx)
  10430d:	c7 45 dc 21 00 00 00 	movl   $0x21,-0x24(%ebp)
  104314:	c6 45 db 20          	movb   $0x20,-0x25(%ebp)
  104318:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  10431c:	8b 55 dc             	mov    -0x24(%ebp),%edx
  10431f:	ee                   	out    %al,(%dx)
  104320:	c7 45 d4 21 00 00 00 	movl   $0x21,-0x2c(%ebp)
  104327:	c6 45 d3 04          	movb   $0x4,-0x2d(%ebp)
  10432b:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
  10432f:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  104332:	ee                   	out    %al,(%dx)
  104333:	c7 45 cc 21 00 00 00 	movl   $0x21,-0x34(%ebp)
  10433a:	c6 45 cb 03          	movb   $0x3,-0x35(%ebp)
  10433e:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
  104342:	8b 55 cc             	mov    -0x34(%ebp),%edx
  104345:	ee                   	out    %al,(%dx)
  104346:	c7 45 c4 a0 00 00 00 	movl   $0xa0,-0x3c(%ebp)
  10434d:	c6 45 c3 11          	movb   $0x11,-0x3d(%ebp)
  104351:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
  104355:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  104358:	ee                   	out    %al,(%dx)
  104359:	c7 45 bc a1 00 00 00 	movl   $0xa1,-0x44(%ebp)
  104360:	c6 45 bb 28          	movb   $0x28,-0x45(%ebp)
  104364:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
  104368:	8b 55 bc             	mov    -0x44(%ebp),%edx
  10436b:	ee                   	out    %al,(%dx)
  10436c:	c7 45 b4 a1 00 00 00 	movl   $0xa1,-0x4c(%ebp)
  104373:	c6 45 b3 02          	movb   $0x2,-0x4d(%ebp)
  104377:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
  10437b:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  10437e:	ee                   	out    %al,(%dx)
  10437f:	c7 45 ac a1 00 00 00 	movl   $0xa1,-0x54(%ebp)
  104386:	c6 45 ab 01          	movb   $0x1,-0x55(%ebp)
  10438a:	0f b6 45 ab          	movzbl -0x55(%ebp),%eax
  10438e:	8b 55 ac             	mov    -0x54(%ebp),%edx
  104391:	ee                   	out    %al,(%dx)
  104392:	c7 45 a4 20 00 00 00 	movl   $0x20,-0x5c(%ebp)
  104399:	c6 45 a3 68          	movb   $0x68,-0x5d(%ebp)
  10439d:	0f b6 45 a3          	movzbl -0x5d(%ebp),%eax
  1043a1:	8b 55 a4             	mov    -0x5c(%ebp),%edx
  1043a4:	ee                   	out    %al,(%dx)
  1043a5:	c7 45 9c 20 00 00 00 	movl   $0x20,-0x64(%ebp)
  1043ac:	c6 45 9b 0a          	movb   $0xa,-0x65(%ebp)
  1043b0:	0f b6 45 9b          	movzbl -0x65(%ebp),%eax
  1043b4:	8b 55 9c             	mov    -0x64(%ebp),%edx
  1043b7:	ee                   	out    %al,(%dx)
  1043b8:	c7 45 94 a0 00 00 00 	movl   $0xa0,-0x6c(%ebp)
  1043bf:	c6 45 93 68          	movb   $0x68,-0x6d(%ebp)
  1043c3:	0f b6 45 93          	movzbl -0x6d(%ebp),%eax
  1043c7:	8b 55 94             	mov    -0x6c(%ebp),%edx
  1043ca:	ee                   	out    %al,(%dx)
  1043cb:	c7 45 8c a0 00 00 00 	movl   $0xa0,-0x74(%ebp)
  1043d2:	c6 45 8b 0a          	movb   $0xa,-0x75(%ebp)
  1043d6:	0f b6 45 8b          	movzbl -0x75(%ebp),%eax
  1043da:	8b 55 8c             	mov    -0x74(%ebp),%edx
  1043dd:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irqmask != 0xFFFF)
  1043de:	0f b7 05 f0 95 10 00 	movzwl 0x1095f0,%eax
  1043e5:	66 83 f8 ff          	cmp    $0xffff,%ax
  1043e9:	74 15                	je     104400 <pic_init+0x14c>
		pic_setmask(irqmask);
  1043eb:	0f b7 05 f0 95 10 00 	movzwl 0x1095f0,%eax
  1043f2:	0f b7 c0             	movzwl %ax,%eax
  1043f5:	89 04 24             	mov    %eax,(%esp)
  1043f8:	e8 05 00 00 00       	call   104402 <pic_setmask>
  1043fd:	eb 01                	jmp    104400 <pic_init+0x14c>
/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	if (didinit)		// only do once on bootstrap CPU
		return;
  1043ff:	90                   	nop
	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irqmask != 0xFFFF)
		pic_setmask(irqmask);
}
  104400:	c9                   	leave  
  104401:	c3                   	ret    

00104402 <pic_setmask>:

void
pic_setmask(uint16_t mask)
{
  104402:	55                   	push   %ebp
  104403:	89 e5                	mov    %esp,%ebp
  104405:	83 ec 14             	sub    $0x14,%esp
  104408:	8b 45 08             	mov    0x8(%ebp),%eax
  10440b:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
	irqmask = mask;
  10440f:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  104413:	66 a3 f0 95 10 00    	mov    %ax,0x1095f0
	outb(IO_PIC1+1, (char)mask);
  104419:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  10441d:	0f b6 c0             	movzbl %al,%eax
  104420:	c7 45 fc 21 00 00 00 	movl   $0x21,-0x4(%ebp)
  104427:	88 45 fb             	mov    %al,-0x5(%ebp)
  10442a:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  10442e:	8b 55 fc             	mov    -0x4(%ebp),%edx
  104431:	ee                   	out    %al,(%dx)
	outb(IO_PIC2+1, (char)(mask >> 8));
  104432:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  104436:	66 c1 e8 08          	shr    $0x8,%ax
  10443a:	0f b6 c0             	movzbl %al,%eax
  10443d:	c7 45 f4 a1 00 00 00 	movl   $0xa1,-0xc(%ebp)
  104444:	88 45 f3             	mov    %al,-0xd(%ebp)
  104447:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  10444b:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10444e:	ee                   	out    %al,(%dx)
}
  10444f:	c9                   	leave  
  104450:	c3                   	ret    

00104451 <pic_enable>:

void
pic_enable(int irq)
{
  104451:	55                   	push   %ebp
  104452:	89 e5                	mov    %esp,%ebp
  104454:	53                   	push   %ebx
  104455:	83 ec 04             	sub    $0x4,%esp
	pic_setmask(irqmask & ~(1 << irq));
  104458:	8b 45 08             	mov    0x8(%ebp),%eax
  10445b:	ba 01 00 00 00       	mov    $0x1,%edx
  104460:	89 d3                	mov    %edx,%ebx
  104462:	89 c1                	mov    %eax,%ecx
  104464:	d3 e3                	shl    %cl,%ebx
  104466:	89 d8                	mov    %ebx,%eax
  104468:	89 c2                	mov    %eax,%edx
  10446a:	f7 d2                	not    %edx
  10446c:	0f b7 05 f0 95 10 00 	movzwl 0x1095f0,%eax
  104473:	21 d0                	and    %edx,%eax
  104475:	0f b7 c0             	movzwl %ax,%eax
  104478:	89 04 24             	mov    %eax,(%esp)
  10447b:	e8 82 ff ff ff       	call   104402 <pic_setmask>
}
  104480:	83 c4 04             	add    $0x4,%esp
  104483:	5b                   	pop    %ebx
  104484:	5d                   	pop    %ebp
  104485:	c3                   	ret    
  104486:	90                   	nop
  104487:	90                   	nop

00104488 <nvram_read>:
#include <dev/nvram.h>


unsigned
nvram_read(unsigned reg)
{
  104488:	55                   	push   %ebp
  104489:	89 e5                	mov    %esp,%ebp
  10448b:	53                   	push   %ebx
  10448c:	83 ec 14             	sub    $0x14,%esp
	outb(IO_RTC, reg);
  10448f:	8b 45 08             	mov    0x8(%ebp),%eax
  104492:	0f b6 c0             	movzbl %al,%eax
  104495:	c7 45 f8 70 00 00 00 	movl   $0x70,-0x8(%ebp)
  10449c:	88 45 f7             	mov    %al,-0x9(%ebp)
  10449f:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
  1044a3:	8b 55 f8             	mov    -0x8(%ebp),%edx
  1044a6:	ee                   	out    %al,(%dx)
  1044a7:	c7 45 f0 71 00 00 00 	movl   $0x71,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1044ae:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1044b1:	89 55 e8             	mov    %edx,-0x18(%ebp)
  1044b4:	8b 55 e8             	mov    -0x18(%ebp),%edx
  1044b7:	ec                   	in     (%dx),%al
  1044b8:	89 c3                	mov    %eax,%ebx
  1044ba:	88 5d ef             	mov    %bl,-0x11(%ebp)
	return data;
  1044bd:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
	return inb(IO_RTC+1);
  1044c1:	0f b6 c0             	movzbl %al,%eax
}
  1044c4:	83 c4 14             	add    $0x14,%esp
  1044c7:	5b                   	pop    %ebx
  1044c8:	5d                   	pop    %ebp
  1044c9:	c3                   	ret    

001044ca <nvram_read16>:

unsigned
nvram_read16(unsigned r)
{
  1044ca:	55                   	push   %ebp
  1044cb:	89 e5                	mov    %esp,%ebp
  1044cd:	53                   	push   %ebx
  1044ce:	83 ec 04             	sub    $0x4,%esp
	return nvram_read(r) | (nvram_read(r + 1) << 8);
  1044d1:	8b 45 08             	mov    0x8(%ebp),%eax
  1044d4:	89 04 24             	mov    %eax,(%esp)
  1044d7:	e8 ac ff ff ff       	call   104488 <nvram_read>
  1044dc:	89 c3                	mov    %eax,%ebx
  1044de:	8b 45 08             	mov    0x8(%ebp),%eax
  1044e1:	83 c0 01             	add    $0x1,%eax
  1044e4:	89 04 24             	mov    %eax,(%esp)
  1044e7:	e8 9c ff ff ff       	call   104488 <nvram_read>
  1044ec:	c1 e0 08             	shl    $0x8,%eax
  1044ef:	09 d8                	or     %ebx,%eax
}
  1044f1:	83 c4 04             	add    $0x4,%esp
  1044f4:	5b                   	pop    %ebx
  1044f5:	5d                   	pop    %ebp
  1044f6:	c3                   	ret    

001044f7 <nvram_write>:

void
nvram_write(unsigned reg, unsigned datum)
{
  1044f7:	55                   	push   %ebp
  1044f8:	89 e5                	mov    %esp,%ebp
  1044fa:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  1044fd:	8b 45 08             	mov    0x8(%ebp),%eax
  104500:	0f b6 c0             	movzbl %al,%eax
  104503:	c7 45 fc 70 00 00 00 	movl   $0x70,-0x4(%ebp)
  10450a:	88 45 fb             	mov    %al,-0x5(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10450d:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  104511:	8b 55 fc             	mov    -0x4(%ebp),%edx
  104514:	ee                   	out    %al,(%dx)
	outb(IO_RTC+1, datum);
  104515:	8b 45 0c             	mov    0xc(%ebp),%eax
  104518:	0f b6 c0             	movzbl %al,%eax
  10451b:	c7 45 f4 71 00 00 00 	movl   $0x71,-0xc(%ebp)
  104522:	88 45 f3             	mov    %al,-0xd(%ebp)
  104525:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  104529:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10452c:	ee                   	out    %al,(%dx)
}
  10452d:	c9                   	leave  
  10452e:	c3                   	ret    
  10452f:	90                   	nop

00104530 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  104530:	55                   	push   %ebp
  104531:	89 e5                	mov    %esp,%ebp
  104533:	53                   	push   %ebx
  104534:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  104537:	89 e3                	mov    %esp,%ebx
  104539:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  10453c:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  10453f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  104542:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104545:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10454a:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  10454d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104550:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  104556:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  10455b:	74 24                	je     104581 <cpu_cur+0x51>
  10455d:	c7 44 24 0c ad 68 10 	movl   $0x1068ad,0xc(%esp)
  104564:	00 
  104565:	c7 44 24 08 c3 68 10 	movl   $0x1068c3,0x8(%esp)
  10456c:	00 
  10456d:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  104574:	00 
  104575:	c7 04 24 d8 68 10 00 	movl   $0x1068d8,(%esp)
  10457c:	e8 43 bf ff ff       	call   1004c4 <debug_panic>
	return c;
  104581:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  104584:	83 c4 24             	add    $0x24,%esp
  104587:	5b                   	pop    %ebx
  104588:	5d                   	pop    %ebp
  104589:	c3                   	ret    

0010458a <lapicw>:
volatile uint32_t *lapic;  // Initialized in mp.c


static void
lapicw(int index, int value)
{
  10458a:	55                   	push   %ebp
  10458b:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
  10458d:	a1 ec fa 30 00       	mov    0x30faec,%eax
  104592:	8b 55 08             	mov    0x8(%ebp),%edx
  104595:	c1 e2 02             	shl    $0x2,%edx
  104598:	01 c2                	add    %eax,%edx
  10459a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10459d:	89 02                	mov    %eax,(%edx)
	lapic[ID];  // wait for write to finish, by reading
  10459f:	a1 ec fa 30 00       	mov    0x30faec,%eax
  1045a4:	83 c0 20             	add    $0x20,%eax
  1045a7:	8b 00                	mov    (%eax),%eax
}
  1045a9:	5d                   	pop    %ebp
  1045aa:	c3                   	ret    

001045ab <lapic_init>:

void
lapic_init()
{
  1045ab:	55                   	push   %ebp
  1045ac:	89 e5                	mov    %esp,%ebp
  1045ae:	83 ec 08             	sub    $0x8,%esp
	if (!lapic) 
  1045b1:	a1 ec fa 30 00       	mov    0x30faec,%eax
  1045b6:	85 c0                	test   %eax,%eax
  1045b8:	0f 84 83 01 00 00    	je     104741 <lapic_init+0x196>
		return;

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
  1045be:	c7 44 24 04 27 01 00 	movl   $0x127,0x4(%esp)
  1045c5:	00 
  1045c6:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
  1045cd:	e8 b8 ff ff ff       	call   10458a <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	lapicw(TDCR, X1);
  1045d2:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
  1045d9:	00 
  1045da:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
  1045e1:	e8 a4 ff ff ff       	call   10458a <lapicw>
	lapicw(TIMER, PERIODIC | T_LTIMER);
  1045e6:	c7 44 24 04 31 00 02 	movl   $0x20031,0x4(%esp)
  1045ed:	00 
  1045ee:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  1045f5:	e8 90 ff ff ff       	call   10458a <lapicw>

	// If we cared more about precise timekeeping,
	// we would calibrate TICR with another time source such as the PIT.
	lapicw(TICR, 10000000);
  1045fa:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
  104601:	00 
  104602:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
  104609:	e8 7c ff ff ff       	call   10458a <lapicw>

	// Disable logical interrupt lines.
	lapicw(LINT0, MASKED);
  10460e:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  104615:	00 
  104616:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
  10461d:	e8 68 ff ff ff       	call   10458a <lapicw>
	lapicw(LINT1, MASKED);
  104622:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  104629:	00 
  10462a:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
  104631:	e8 54 ff ff ff       	call   10458a <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
  104636:	a1 ec fa 30 00       	mov    0x30faec,%eax
  10463b:	83 c0 30             	add    $0x30,%eax
  10463e:	8b 00                	mov    (%eax),%eax
  104640:	c1 e8 10             	shr    $0x10,%eax
  104643:	25 ff 00 00 00       	and    $0xff,%eax
  104648:	83 f8 03             	cmp    $0x3,%eax
  10464b:	76 14                	jbe    104661 <lapic_init+0xb6>
		lapicw(PCINT, MASKED);
  10464d:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  104654:	00 
  104655:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
  10465c:	e8 29 ff ff ff       	call   10458a <lapicw>

	// Map other interrupts to appropriate vectors.
	lapicw(ERROR, T_LERROR);
  104661:	c7 44 24 04 32 00 00 	movl   $0x32,0x4(%esp)
  104668:	00 
  104669:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
  104670:	e8 15 ff ff ff       	call   10458a <lapicw>

	// Set up to lowest-priority, "anycast" interrupts
	lapicw(LDR, 0xff << 24);	// Accept all interrupts
  104675:	c7 44 24 04 00 00 00 	movl   $0xff000000,0x4(%esp)
  10467c:	ff 
  10467d:	c7 04 24 34 00 00 00 	movl   $0x34,(%esp)
  104684:	e8 01 ff ff ff       	call   10458a <lapicw>
	lapicw(DFR, 0xf << 28);		// Flat model
  104689:	c7 44 24 04 00 00 00 	movl   $0xf0000000,0x4(%esp)
  104690:	f0 
  104691:	c7 04 24 38 00 00 00 	movl   $0x38,(%esp)
  104698:	e8 ed fe ff ff       	call   10458a <lapicw>
	lapicw(TPR, 0x00);		// Task priority 0, no intrs masked
  10469d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1046a4:	00 
  1046a5:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1046ac:	e8 d9 fe ff ff       	call   10458a <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
  1046b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1046b8:	00 
  1046b9:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  1046c0:	e8 c5 fe ff ff       	call   10458a <lapicw>
	lapicw(ESR, 0);
  1046c5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1046cc:	00 
  1046cd:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  1046d4:	e8 b1 fe ff ff       	call   10458a <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
  1046d9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1046e0:	00 
  1046e1:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
  1046e8:	e8 9d fe ff ff       	call   10458a <lapicw>

	// Send an Init Level De-Assert to synchronise arbitration ID's.
	lapicw(ICRHI, 0);
  1046ed:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1046f4:	00 
  1046f5:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  1046fc:	e8 89 fe ff ff       	call   10458a <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
  104701:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
  104708:	00 
  104709:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  104710:	e8 75 fe ff ff       	call   10458a <lapicw>
	while(lapic[ICRLO] & DELIVS)
  104715:	90                   	nop
  104716:	a1 ec fa 30 00       	mov    0x30faec,%eax
  10471b:	05 00 03 00 00       	add    $0x300,%eax
  104720:	8b 00                	mov    (%eax),%eax
  104722:	25 00 10 00 00       	and    $0x1000,%eax
  104727:	85 c0                	test   %eax,%eax
  104729:	75 eb                	jne    104716 <lapic_init+0x16b>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
  10472b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104732:	00 
  104733:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10473a:	e8 4b fe ff ff       	call   10458a <lapicw>
  10473f:	eb 01                	jmp    104742 <lapic_init+0x197>

void
lapic_init()
{
	if (!lapic) 
		return;
  104741:	90                   	nop
	while(lapic[ICRLO] & DELIVS)
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
}
  104742:	c9                   	leave  
  104743:	c3                   	ret    

00104744 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
  104744:	55                   	push   %ebp
  104745:	89 e5                	mov    %esp,%ebp
  104747:	83 ec 08             	sub    $0x8,%esp
	if (lapic)
  10474a:	a1 ec fa 30 00       	mov    0x30faec,%eax
  10474f:	85 c0                	test   %eax,%eax
  104751:	74 14                	je     104767 <lapic_eoi+0x23>
		lapicw(EOI, 0);
  104753:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10475a:	00 
  10475b:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
  104762:	e8 23 fe ff ff       	call   10458a <lapicw>
}
  104767:	c9                   	leave  
  104768:	c3                   	ret    

00104769 <lapic_errintr>:

void lapic_errintr(void)
{
  104769:	55                   	push   %ebp
  10476a:	89 e5                	mov    %esp,%ebp
  10476c:	53                   	push   %ebx
  10476d:	83 ec 24             	sub    $0x24,%esp
	lapic_eoi();	// Acknowledge interrupt
  104770:	e8 cf ff ff ff       	call   104744 <lapic_eoi>
	lapicw(ESR, 0);	// Trigger update of ESR by writing anything
  104775:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10477c:	00 
  10477d:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  104784:	e8 01 fe ff ff       	call   10458a <lapicw>
	warn("CPU%d LAPIC error: ESR %x", cpu_cur()->id, lapic[ESR]);
  104789:	a1 ec fa 30 00       	mov    0x30faec,%eax
  10478e:	05 80 02 00 00       	add    $0x280,%eax
  104793:	8b 18                	mov    (%eax),%ebx
  104795:	e8 96 fd ff ff       	call   104530 <cpu_cur>
  10479a:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  1047a1:	0f b6 c0             	movzbl %al,%eax
  1047a4:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  1047a8:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1047ac:	c7 44 24 08 e5 68 10 	movl   $0x1068e5,0x8(%esp)
  1047b3:	00 
  1047b4:	c7 44 24 04 60 00 00 	movl   $0x60,0x4(%esp)
  1047bb:	00 
  1047bc:	c7 04 24 ff 68 10 00 	movl   $0x1068ff,(%esp)
  1047c3:	e8 c2 bd ff ff       	call   10058a <debug_warn>
}
  1047c8:	83 c4 24             	add    $0x24,%esp
  1047cb:	5b                   	pop    %ebx
  1047cc:	5d                   	pop    %ebp
  1047cd:	c3                   	ret    

001047ce <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
  1047ce:	55                   	push   %ebp
  1047cf:	89 e5                	mov    %esp,%ebp
}
  1047d1:	5d                   	pop    %ebp
  1047d2:	c3                   	ret    

001047d3 <lapic_startcpu>:

// Start additional processor running bootstrap code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startcpu(uint8_t apicid, uint32_t addr)
{
  1047d3:	55                   	push   %ebp
  1047d4:	89 e5                	mov    %esp,%ebp
  1047d6:	83 ec 2c             	sub    $0x2c,%esp
  1047d9:	8b 45 08             	mov    0x8(%ebp),%eax
  1047dc:	88 45 dc             	mov    %al,-0x24(%ebp)
  1047df:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  1047e6:	c6 45 f3 0f          	movb   $0xf,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1047ea:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1047ee:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1047f1:	ee                   	out    %al,(%dx)
  1047f2:	c7 45 ec 71 00 00 00 	movl   $0x71,-0x14(%ebp)
  1047f9:	c6 45 eb 0a          	movb   $0xa,-0x15(%ebp)
  1047fd:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  104801:	8b 55 ec             	mov    -0x14(%ebp),%edx
  104804:	ee                   	out    %al,(%dx)
	// "The BSP must initialize CMOS shutdown code to 0AH
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t*)(0x40<<4 | 0x67);  // Warm reset vector
  104805:	c7 45 f8 67 04 00 00 	movl   $0x467,-0x8(%ebp)
	wrv[0] = 0;
  10480c:	8b 45 f8             	mov    -0x8(%ebp),%eax
  10480f:	66 c7 00 00 00       	movw   $0x0,(%eax)
	wrv[1] = addr >> 4;
  104814:	8b 45 f8             	mov    -0x8(%ebp),%eax
  104817:	8d 50 02             	lea    0x2(%eax),%edx
  10481a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10481d:	c1 e8 04             	shr    $0x4,%eax
  104820:	66 89 02             	mov    %ax,(%edx)

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid<<24);
  104823:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
  104827:	c1 e0 18             	shl    $0x18,%eax
  10482a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10482e:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  104835:	e8 50 fd ff ff       	call   10458a <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
  10483a:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
  104841:	00 
  104842:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  104849:	e8 3c fd ff ff       	call   10458a <lapicw>
	microdelay(200);
  10484e:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  104855:	e8 74 ff ff ff       	call   1047ce <microdelay>
	lapicw(ICRLO, INIT | LEVEL);
  10485a:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
  104861:	00 
  104862:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  104869:	e8 1c fd ff ff       	call   10458a <lapicw>
	microdelay(100);    // should be 10ms, but too slow in Bochs!
  10486e:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
  104875:	e8 54 ff ff ff       	call   1047ce <microdelay>
	// Send startup IPI (twice!) to enter bootstrap code.
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for(i = 0; i < 2; i++){
  10487a:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  104881:	eb 40                	jmp    1048c3 <lapic_startcpu+0xf0>
		lapicw(ICRHI, apicid<<24);
  104883:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
  104887:	c1 e0 18             	shl    $0x18,%eax
  10488a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10488e:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  104895:	e8 f0 fc ff ff       	call   10458a <lapicw>
		lapicw(ICRLO, STARTUP | (addr>>12));
  10489a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10489d:	c1 e8 0c             	shr    $0xc,%eax
  1048a0:	80 cc 06             	or     $0x6,%ah
  1048a3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1048a7:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  1048ae:	e8 d7 fc ff ff       	call   10458a <lapicw>
		microdelay(200);
  1048b3:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  1048ba:	e8 0f ff ff ff       	call   1047ce <microdelay>
	// Send startup IPI (twice!) to enter bootstrap code.
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for(i = 0; i < 2; i++){
  1048bf:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  1048c3:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
  1048c7:	7e ba                	jle    104883 <lapic_startcpu+0xb0>
		lapicw(ICRHI, apicid<<24);
		lapicw(ICRLO, STARTUP | (addr>>12));
		microdelay(200);
	}
}
  1048c9:	c9                   	leave  
  1048ca:	c3                   	ret    
  1048cb:	90                   	nop

001048cc <ioapic_read>:
	uint32_t data;
};

static uint32_t
ioapic_read(int reg)
{
  1048cc:	55                   	push   %ebp
  1048cd:	89 e5                	mov    %esp,%ebp
	ioapic->reg = reg;
  1048cf:	a1 ec f3 30 00       	mov    0x30f3ec,%eax
  1048d4:	8b 55 08             	mov    0x8(%ebp),%edx
  1048d7:	89 10                	mov    %edx,(%eax)
	return ioapic->data;
  1048d9:	a1 ec f3 30 00       	mov    0x30f3ec,%eax
  1048de:	8b 40 10             	mov    0x10(%eax),%eax
}
  1048e1:	5d                   	pop    %ebp
  1048e2:	c3                   	ret    

001048e3 <ioapic_write>:

static void
ioapic_write(int reg, uint32_t data)
{
  1048e3:	55                   	push   %ebp
  1048e4:	89 e5                	mov    %esp,%ebp
	ioapic->reg = reg;
  1048e6:	a1 ec f3 30 00       	mov    0x30f3ec,%eax
  1048eb:	8b 55 08             	mov    0x8(%ebp),%edx
  1048ee:	89 10                	mov    %edx,(%eax)
	ioapic->data = data;
  1048f0:	a1 ec f3 30 00       	mov    0x30f3ec,%eax
  1048f5:	8b 55 0c             	mov    0xc(%ebp),%edx
  1048f8:	89 50 10             	mov    %edx,0x10(%eax)
}
  1048fb:	5d                   	pop    %ebp
  1048fc:	c3                   	ret    

001048fd <ioapic_init>:

void
ioapic_init(void)
{
  1048fd:	55                   	push   %ebp
  1048fe:	89 e5                	mov    %esp,%ebp
  104900:	83 ec 38             	sub    $0x38,%esp
	int i, id, maxintr;

	if(!ismp)
  104903:	a1 f0 f3 30 00       	mov    0x30f3f0,%eax
  104908:	85 c0                	test   %eax,%eax
  10490a:	0f 84 fd 00 00 00    	je     104a0d <ioapic_init+0x110>
		return;

	if (ioapic == NULL)
  104910:	a1 ec f3 30 00       	mov    0x30f3ec,%eax
  104915:	85 c0                	test   %eax,%eax
  104917:	75 0a                	jne    104923 <ioapic_init+0x26>
		ioapic = mem_ptr(IOAPIC);	// assume default address
  104919:	c7 05 ec f3 30 00 00 	movl   $0xfec00000,0x30f3ec
  104920:	00 c0 fe 

	maxintr = (ioapic_read(REG_VER) >> 16) & 0xFF;
  104923:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  10492a:	e8 9d ff ff ff       	call   1048cc <ioapic_read>
  10492f:	c1 e8 10             	shr    $0x10,%eax
  104932:	25 ff 00 00 00       	and    $0xff,%eax
  104937:	89 45 ec             	mov    %eax,-0x14(%ebp)
	id = ioapic_read(REG_ID) >> 24;
  10493a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  104941:	e8 86 ff ff ff       	call   1048cc <ioapic_read>
  104946:	c1 e8 18             	shr    $0x18,%eax
  104949:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (id == 0) {
  10494c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  104950:	75 2a                	jne    10497c <ioapic_init+0x7f>
		// I/O APIC ID not initialized yet - have to do it ourselves.
		ioapic_write(REG_ID, ioapicid << 24);
  104952:	0f b6 05 e8 f3 30 00 	movzbl 0x30f3e8,%eax
  104959:	0f b6 c0             	movzbl %al,%eax
  10495c:	c1 e0 18             	shl    $0x18,%eax
  10495f:	89 44 24 04          	mov    %eax,0x4(%esp)
  104963:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  10496a:	e8 74 ff ff ff       	call   1048e3 <ioapic_write>
		id = ioapicid;
  10496f:	0f b6 05 e8 f3 30 00 	movzbl 0x30f3e8,%eax
  104976:	0f b6 c0             	movzbl %al,%eax
  104979:	89 45 f0             	mov    %eax,-0x10(%ebp)
	}
	if (id != ioapicid)
  10497c:	0f b6 05 e8 f3 30 00 	movzbl 0x30f3e8,%eax
  104983:	0f b6 c0             	movzbl %al,%eax
  104986:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  104989:	74 31                	je     1049bc <ioapic_init+0xbf>
		warn("ioapicinit: id %d != ioapicid %d", id, ioapicid);
  10498b:	0f b6 05 e8 f3 30 00 	movzbl 0x30f3e8,%eax
  104992:	0f b6 c0             	movzbl %al,%eax
  104995:	89 44 24 10          	mov    %eax,0x10(%esp)
  104999:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10499c:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1049a0:	c7 44 24 08 0c 69 10 	movl   $0x10690c,0x8(%esp)
  1049a7:	00 
  1049a8:	c7 44 24 04 53 00 00 	movl   $0x53,0x4(%esp)
  1049af:	00 
  1049b0:	c7 04 24 2d 69 10 00 	movl   $0x10692d,(%esp)
  1049b7:	e8 ce bb ff ff       	call   10058a <debug_warn>

	// Mark all interrupts edge-triggered, active high, disabled,
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
  1049bc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  1049c3:	eb 3e                	jmp    104a03 <ioapic_init+0x106>
		ioapic_write(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
  1049c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1049c8:	83 c0 20             	add    $0x20,%eax
  1049cb:	0d 00 00 01 00       	or     $0x10000,%eax
  1049d0:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1049d3:	83 c2 08             	add    $0x8,%edx
  1049d6:	01 d2                	add    %edx,%edx
  1049d8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1049dc:	89 14 24             	mov    %edx,(%esp)
  1049df:	e8 ff fe ff ff       	call   1048e3 <ioapic_write>
		ioapic_write(REG_TABLE+2*i+1, 0);
  1049e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1049e7:	83 c0 08             	add    $0x8,%eax
  1049ea:	01 c0                	add    %eax,%eax
  1049ec:	83 c0 01             	add    $0x1,%eax
  1049ef:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1049f6:	00 
  1049f7:	89 04 24             	mov    %eax,(%esp)
  1049fa:	e8 e4 fe ff ff       	call   1048e3 <ioapic_write>
	if (id != ioapicid)
		warn("ioapicinit: id %d != ioapicid %d", id, ioapicid);

	// Mark all interrupts edge-triggered, active high, disabled,
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
  1049ff:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  104a03:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104a06:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  104a09:	7e ba                	jle    1049c5 <ioapic_init+0xc8>
  104a0b:	eb 01                	jmp    104a0e <ioapic_init+0x111>
ioapic_init(void)
{
	int i, id, maxintr;

	if(!ismp)
		return;
  104a0d:	90                   	nop
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
		ioapic_write(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
		ioapic_write(REG_TABLE+2*i+1, 0);
	}
}
  104a0e:	c9                   	leave  
  104a0f:	c3                   	ret    

00104a10 <ioapic_enable>:

void
ioapic_enable(int irq)
{
  104a10:	55                   	push   %ebp
  104a11:	89 e5                	mov    %esp,%ebp
  104a13:	83 ec 08             	sub    $0x8,%esp
	if (!ismp)
  104a16:	a1 f0 f3 30 00       	mov    0x30f3f0,%eax
  104a1b:	85 c0                	test   %eax,%eax
  104a1d:	74 3a                	je     104a59 <ioapic_enable+0x49>
		return;

	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
  104a1f:	8b 45 08             	mov    0x8(%ebp),%eax
  104a22:	83 c0 20             	add    $0x20,%eax
  104a25:	80 cc 09             	or     $0x9,%ah
	if (!ismp)
		return;

	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
  104a28:	8b 55 08             	mov    0x8(%ebp),%edx
  104a2b:	83 c2 08             	add    $0x8,%edx
  104a2e:	01 d2                	add    %edx,%edx
  104a30:	89 44 24 04          	mov    %eax,0x4(%esp)
  104a34:	89 14 24             	mov    %edx,(%esp)
  104a37:	e8 a7 fe ff ff       	call   1048e3 <ioapic_write>
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
	ioapic_write(REG_TABLE+2*irq+1, 0xff << 24);
  104a3c:	8b 45 08             	mov    0x8(%ebp),%eax
  104a3f:	83 c0 08             	add    $0x8,%eax
  104a42:	01 c0                	add    %eax,%eax
  104a44:	83 c0 01             	add    $0x1,%eax
  104a47:	c7 44 24 04 00 00 00 	movl   $0xff000000,0x4(%esp)
  104a4e:	ff 
  104a4f:	89 04 24             	mov    %eax,(%esp)
  104a52:	e8 8c fe ff ff       	call   1048e3 <ioapic_write>
  104a57:	eb 01                	jmp    104a5a <ioapic_enable+0x4a>

void
ioapic_enable(int irq)
{
	if (!ismp)
		return;
  104a59:	90                   	nop
	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
	ioapic_write(REG_TABLE+2*irq+1, 0xff << 24);
}
  104a5a:	c9                   	leave  
  104a5b:	c3                   	ret    

00104a5c <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static uintmax_t
getuint(printstate *st, va_list *ap)
{
  104a5c:	55                   	push   %ebp
  104a5d:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  104a5f:	8b 45 08             	mov    0x8(%ebp),%eax
  104a62:	8b 40 18             	mov    0x18(%eax),%eax
  104a65:	83 e0 02             	and    $0x2,%eax
  104a68:	85 c0                	test   %eax,%eax
  104a6a:	74 1c                	je     104a88 <getuint+0x2c>
		return va_arg(*ap, unsigned long long);
  104a6c:	8b 45 0c             	mov    0xc(%ebp),%eax
  104a6f:	8b 00                	mov    (%eax),%eax
  104a71:	8d 50 08             	lea    0x8(%eax),%edx
  104a74:	8b 45 0c             	mov    0xc(%ebp),%eax
  104a77:	89 10                	mov    %edx,(%eax)
  104a79:	8b 45 0c             	mov    0xc(%ebp),%eax
  104a7c:	8b 00                	mov    (%eax),%eax
  104a7e:	83 e8 08             	sub    $0x8,%eax
  104a81:	8b 50 04             	mov    0x4(%eax),%edx
  104a84:	8b 00                	mov    (%eax),%eax
  104a86:	eb 47                	jmp    104acf <getuint+0x73>
	else if (st->flags & F_L)
  104a88:	8b 45 08             	mov    0x8(%ebp),%eax
  104a8b:	8b 40 18             	mov    0x18(%eax),%eax
  104a8e:	83 e0 01             	and    $0x1,%eax
  104a91:	85 c0                	test   %eax,%eax
  104a93:	74 1e                	je     104ab3 <getuint+0x57>
		return va_arg(*ap, unsigned long);
  104a95:	8b 45 0c             	mov    0xc(%ebp),%eax
  104a98:	8b 00                	mov    (%eax),%eax
  104a9a:	8d 50 04             	lea    0x4(%eax),%edx
  104a9d:	8b 45 0c             	mov    0xc(%ebp),%eax
  104aa0:	89 10                	mov    %edx,(%eax)
  104aa2:	8b 45 0c             	mov    0xc(%ebp),%eax
  104aa5:	8b 00                	mov    (%eax),%eax
  104aa7:	83 e8 04             	sub    $0x4,%eax
  104aaa:	8b 00                	mov    (%eax),%eax
  104aac:	ba 00 00 00 00       	mov    $0x0,%edx
  104ab1:	eb 1c                	jmp    104acf <getuint+0x73>
	else
		return va_arg(*ap, unsigned int);
  104ab3:	8b 45 0c             	mov    0xc(%ebp),%eax
  104ab6:	8b 00                	mov    (%eax),%eax
  104ab8:	8d 50 04             	lea    0x4(%eax),%edx
  104abb:	8b 45 0c             	mov    0xc(%ebp),%eax
  104abe:	89 10                	mov    %edx,(%eax)
  104ac0:	8b 45 0c             	mov    0xc(%ebp),%eax
  104ac3:	8b 00                	mov    (%eax),%eax
  104ac5:	83 e8 04             	sub    $0x4,%eax
  104ac8:	8b 00                	mov    (%eax),%eax
  104aca:	ba 00 00 00 00       	mov    $0x0,%edx
}
  104acf:	5d                   	pop    %ebp
  104ad0:	c3                   	ret    

00104ad1 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static intmax_t
getint(printstate *st, va_list *ap)
{
  104ad1:	55                   	push   %ebp
  104ad2:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  104ad4:	8b 45 08             	mov    0x8(%ebp),%eax
  104ad7:	8b 40 18             	mov    0x18(%eax),%eax
  104ada:	83 e0 02             	and    $0x2,%eax
  104add:	85 c0                	test   %eax,%eax
  104adf:	74 1c                	je     104afd <getint+0x2c>
		return va_arg(*ap, long long);
  104ae1:	8b 45 0c             	mov    0xc(%ebp),%eax
  104ae4:	8b 00                	mov    (%eax),%eax
  104ae6:	8d 50 08             	lea    0x8(%eax),%edx
  104ae9:	8b 45 0c             	mov    0xc(%ebp),%eax
  104aec:	89 10                	mov    %edx,(%eax)
  104aee:	8b 45 0c             	mov    0xc(%ebp),%eax
  104af1:	8b 00                	mov    (%eax),%eax
  104af3:	83 e8 08             	sub    $0x8,%eax
  104af6:	8b 50 04             	mov    0x4(%eax),%edx
  104af9:	8b 00                	mov    (%eax),%eax
  104afb:	eb 47                	jmp    104b44 <getint+0x73>
	else if (st->flags & F_L)
  104afd:	8b 45 08             	mov    0x8(%ebp),%eax
  104b00:	8b 40 18             	mov    0x18(%eax),%eax
  104b03:	83 e0 01             	and    $0x1,%eax
  104b06:	85 c0                	test   %eax,%eax
  104b08:	74 1e                	je     104b28 <getint+0x57>
		return va_arg(*ap, long);
  104b0a:	8b 45 0c             	mov    0xc(%ebp),%eax
  104b0d:	8b 00                	mov    (%eax),%eax
  104b0f:	8d 50 04             	lea    0x4(%eax),%edx
  104b12:	8b 45 0c             	mov    0xc(%ebp),%eax
  104b15:	89 10                	mov    %edx,(%eax)
  104b17:	8b 45 0c             	mov    0xc(%ebp),%eax
  104b1a:	8b 00                	mov    (%eax),%eax
  104b1c:	83 e8 04             	sub    $0x4,%eax
  104b1f:	8b 00                	mov    (%eax),%eax
  104b21:	89 c2                	mov    %eax,%edx
  104b23:	c1 fa 1f             	sar    $0x1f,%edx
  104b26:	eb 1c                	jmp    104b44 <getint+0x73>
	else
		return va_arg(*ap, int);
  104b28:	8b 45 0c             	mov    0xc(%ebp),%eax
  104b2b:	8b 00                	mov    (%eax),%eax
  104b2d:	8d 50 04             	lea    0x4(%eax),%edx
  104b30:	8b 45 0c             	mov    0xc(%ebp),%eax
  104b33:	89 10                	mov    %edx,(%eax)
  104b35:	8b 45 0c             	mov    0xc(%ebp),%eax
  104b38:	8b 00                	mov    (%eax),%eax
  104b3a:	83 e8 04             	sub    $0x4,%eax
  104b3d:	8b 00                	mov    (%eax),%eax
  104b3f:	89 c2                	mov    %eax,%edx
  104b41:	c1 fa 1f             	sar    $0x1f,%edx
}
  104b44:	5d                   	pop    %ebp
  104b45:	c3                   	ret    

00104b46 <putpad>:

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
  104b46:	55                   	push   %ebp
  104b47:	89 e5                	mov    %esp,%ebp
  104b49:	83 ec 18             	sub    $0x18,%esp
	while (--st->width >= 0)
  104b4c:	eb 1a                	jmp    104b68 <putpad+0x22>
		st->putch(st->padc, st->putdat);
  104b4e:	8b 45 08             	mov    0x8(%ebp),%eax
  104b51:	8b 00                	mov    (%eax),%eax
  104b53:	8b 55 08             	mov    0x8(%ebp),%edx
  104b56:	8b 4a 04             	mov    0x4(%edx),%ecx
  104b59:	8b 55 08             	mov    0x8(%ebp),%edx
  104b5c:	8b 52 08             	mov    0x8(%edx),%edx
  104b5f:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  104b63:	89 14 24             	mov    %edx,(%esp)
  104b66:	ff d0                	call   *%eax

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
	while (--st->width >= 0)
  104b68:	8b 45 08             	mov    0x8(%ebp),%eax
  104b6b:	8b 40 0c             	mov    0xc(%eax),%eax
  104b6e:	8d 50 ff             	lea    -0x1(%eax),%edx
  104b71:	8b 45 08             	mov    0x8(%ebp),%eax
  104b74:	89 50 0c             	mov    %edx,0xc(%eax)
  104b77:	8b 45 08             	mov    0x8(%ebp),%eax
  104b7a:	8b 40 0c             	mov    0xc(%eax),%eax
  104b7d:	85 c0                	test   %eax,%eax
  104b7f:	79 cd                	jns    104b4e <putpad+0x8>
		st->putch(st->padc, st->putdat);
}
  104b81:	c9                   	leave  
  104b82:	c3                   	ret    

00104b83 <putstr>:

// Print a string with a specified maximum length (-1=unlimited),
// with any appropriate left or right field padding.
static void
putstr(printstate *st, const char *str, int maxlen)
{
  104b83:	55                   	push   %ebp
  104b84:	89 e5                	mov    %esp,%ebp
  104b86:	53                   	push   %ebx
  104b87:	83 ec 24             	sub    $0x24,%esp
	const char *lim;		// find where the string actually ends
	if (maxlen < 0)
  104b8a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  104b8e:	79 18                	jns    104ba8 <putstr+0x25>
		lim = strchr(str, 0);	// find the terminating null
  104b90:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104b97:	00 
  104b98:	8b 45 0c             	mov    0xc(%ebp),%eax
  104b9b:	89 04 24             	mov    %eax,(%esp)
  104b9e:	e8 e6 07 00 00       	call   105389 <strchr>
  104ba3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  104ba6:	eb 2e                	jmp    104bd6 <putstr+0x53>
	else if ((lim = memchr(str, 0, maxlen)) == NULL)
  104ba8:	8b 45 10             	mov    0x10(%ebp),%eax
  104bab:	89 44 24 08          	mov    %eax,0x8(%esp)
  104baf:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104bb6:	00 
  104bb7:	8b 45 0c             	mov    0xc(%ebp),%eax
  104bba:	89 04 24             	mov    %eax,(%esp)
  104bbd:	e8 c4 09 00 00       	call   105586 <memchr>
  104bc2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  104bc5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  104bc9:	75 0b                	jne    104bd6 <putstr+0x53>
		lim = str + maxlen;
  104bcb:	8b 55 10             	mov    0x10(%ebp),%edx
  104bce:	8b 45 0c             	mov    0xc(%ebp),%eax
  104bd1:	01 d0                	add    %edx,%eax
  104bd3:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->width -= (lim-str);		// deduct string length from field width
  104bd6:	8b 45 08             	mov    0x8(%ebp),%eax
  104bd9:	8b 40 0c             	mov    0xc(%eax),%eax
  104bdc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  104bdf:	8b 55 f4             	mov    -0xc(%ebp),%edx
  104be2:	89 cb                	mov    %ecx,%ebx
  104be4:	29 d3                	sub    %edx,%ebx
  104be6:	89 da                	mov    %ebx,%edx
  104be8:	01 c2                	add    %eax,%edx
  104bea:	8b 45 08             	mov    0x8(%ebp),%eax
  104bed:	89 50 0c             	mov    %edx,0xc(%eax)

	if (!(st->flags & F_RPAD))	// print left-side padding
  104bf0:	8b 45 08             	mov    0x8(%ebp),%eax
  104bf3:	8b 40 18             	mov    0x18(%eax),%eax
  104bf6:	83 e0 10             	and    $0x10,%eax
  104bf9:	85 c0                	test   %eax,%eax
  104bfb:	75 32                	jne    104c2f <putstr+0xac>
		putpad(st);		// (also leaves st->width == 0)
  104bfd:	8b 45 08             	mov    0x8(%ebp),%eax
  104c00:	89 04 24             	mov    %eax,(%esp)
  104c03:	e8 3e ff ff ff       	call   104b46 <putpad>
	while (str < lim) {
  104c08:	eb 25                	jmp    104c2f <putstr+0xac>
		char ch = *str++;
  104c0a:	8b 45 0c             	mov    0xc(%ebp),%eax
  104c0d:	0f b6 00             	movzbl (%eax),%eax
  104c10:	88 45 f3             	mov    %al,-0xd(%ebp)
  104c13:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
			st->putch(ch, st->putdat);
  104c17:	8b 45 08             	mov    0x8(%ebp),%eax
  104c1a:	8b 00                	mov    (%eax),%eax
  104c1c:	8b 55 08             	mov    0x8(%ebp),%edx
  104c1f:	8b 4a 04             	mov    0x4(%edx),%ecx
  104c22:	0f be 55 f3          	movsbl -0xd(%ebp),%edx
  104c26:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  104c2a:	89 14 24             	mov    %edx,(%esp)
  104c2d:	ff d0                	call   *%eax
		lim = str + maxlen;
	st->width -= (lim-str);		// deduct string length from field width

	if (!(st->flags & F_RPAD))	// print left-side padding
		putpad(st);		// (also leaves st->width == 0)
	while (str < lim) {
  104c2f:	8b 45 0c             	mov    0xc(%ebp),%eax
  104c32:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  104c35:	72 d3                	jb     104c0a <putstr+0x87>
		char ch = *str++;
			st->putch(ch, st->putdat);
	}
	putpad(st);			// print right-side padding
  104c37:	8b 45 08             	mov    0x8(%ebp),%eax
  104c3a:	89 04 24             	mov    %eax,(%esp)
  104c3d:	e8 04 ff ff ff       	call   104b46 <putpad>
}
  104c42:	83 c4 24             	add    $0x24,%esp
  104c45:	5b                   	pop    %ebx
  104c46:	5d                   	pop    %ebp
  104c47:	c3                   	ret    

00104c48 <genint>:

// Generate a number (base <= 16) in reverse order into a string buffer.
static char *
genint(printstate *st, char *p, uintmax_t num)
{
  104c48:	55                   	push   %ebp
  104c49:	89 e5                	mov    %esp,%ebp
  104c4b:	53                   	push   %ebx
  104c4c:	83 ec 24             	sub    $0x24,%esp
  104c4f:	8b 45 10             	mov    0x10(%ebp),%eax
  104c52:	89 45 f0             	mov    %eax,-0x10(%ebp)
  104c55:	8b 45 14             	mov    0x14(%ebp),%eax
  104c58:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= st->base)
  104c5b:	8b 45 08             	mov    0x8(%ebp),%eax
  104c5e:	8b 40 1c             	mov    0x1c(%eax),%eax
  104c61:	89 c2                	mov    %eax,%edx
  104c63:	c1 fa 1f             	sar    $0x1f,%edx
  104c66:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  104c69:	77 4e                	ja     104cb9 <genint+0x71>
  104c6b:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  104c6e:	72 05                	jb     104c75 <genint+0x2d>
  104c70:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  104c73:	77 44                	ja     104cb9 <genint+0x71>
		p = genint(st, p, num / st->base);	// output higher digits
  104c75:	8b 45 08             	mov    0x8(%ebp),%eax
  104c78:	8b 40 1c             	mov    0x1c(%eax),%eax
  104c7b:	89 c2                	mov    %eax,%edx
  104c7d:	c1 fa 1f             	sar    $0x1f,%edx
  104c80:	89 44 24 08          	mov    %eax,0x8(%esp)
  104c84:	89 54 24 0c          	mov    %edx,0xc(%esp)
  104c88:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104c8b:	8b 55 f4             	mov    -0xc(%ebp),%edx
  104c8e:	89 04 24             	mov    %eax,(%esp)
  104c91:	89 54 24 04          	mov    %edx,0x4(%esp)
  104c95:	e8 26 09 00 00       	call   1055c0 <__udivdi3>
  104c9a:	89 44 24 08          	mov    %eax,0x8(%esp)
  104c9e:	89 54 24 0c          	mov    %edx,0xc(%esp)
  104ca2:	8b 45 0c             	mov    0xc(%ebp),%eax
  104ca5:	89 44 24 04          	mov    %eax,0x4(%esp)
  104ca9:	8b 45 08             	mov    0x8(%ebp),%eax
  104cac:	89 04 24             	mov    %eax,(%esp)
  104caf:	e8 94 ff ff ff       	call   104c48 <genint>
  104cb4:	89 45 0c             	mov    %eax,0xc(%ebp)
  104cb7:	eb 1b                	jmp    104cd4 <genint+0x8c>
	else if (st->signc >= 0)
  104cb9:	8b 45 08             	mov    0x8(%ebp),%eax
  104cbc:	8b 40 14             	mov    0x14(%eax),%eax
  104cbf:	85 c0                	test   %eax,%eax
  104cc1:	78 11                	js     104cd4 <genint+0x8c>
		*p++ = st->signc;			// output leading sign
  104cc3:	8b 45 08             	mov    0x8(%ebp),%eax
  104cc6:	8b 40 14             	mov    0x14(%eax),%eax
  104cc9:	89 c2                	mov    %eax,%edx
  104ccb:	8b 45 0c             	mov    0xc(%ebp),%eax
  104cce:	88 10                	mov    %dl,(%eax)
  104cd0:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	*p++ = "0123456789abcdef"[num % st->base];	// output this digit
  104cd4:	8b 45 08             	mov    0x8(%ebp),%eax
  104cd7:	8b 40 1c             	mov    0x1c(%eax),%eax
  104cda:	89 c1                	mov    %eax,%ecx
  104cdc:	89 c3                	mov    %eax,%ebx
  104cde:	c1 fb 1f             	sar    $0x1f,%ebx
  104ce1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104ce4:	8b 55 f4             	mov    -0xc(%ebp),%edx
  104ce7:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  104ceb:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  104cef:	89 04 24             	mov    %eax,(%esp)
  104cf2:	89 54 24 04          	mov    %edx,0x4(%esp)
  104cf6:	e8 25 0a 00 00       	call   105720 <__umoddi3>
  104cfb:	05 3c 69 10 00       	add    $0x10693c,%eax
  104d00:	0f b6 10             	movzbl (%eax),%edx
  104d03:	8b 45 0c             	mov    0xc(%ebp),%eax
  104d06:	88 10                	mov    %dl,(%eax)
  104d08:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	return p;
  104d0c:	8b 45 0c             	mov    0xc(%ebp),%eax
}
  104d0f:	83 c4 24             	add    $0x24,%esp
  104d12:	5b                   	pop    %ebx
  104d13:	5d                   	pop    %ebp
  104d14:	c3                   	ret    

00104d15 <putint>:

// Print an integer with any appropriate field padding.
static void
putint(printstate *st, uintmax_t num, int base)
{
  104d15:	55                   	push   %ebp
  104d16:	89 e5                	mov    %esp,%ebp
  104d18:	83 ec 58             	sub    $0x58,%esp
  104d1b:	8b 45 0c             	mov    0xc(%ebp),%eax
  104d1e:	89 45 c0             	mov    %eax,-0x40(%ebp)
  104d21:	8b 45 10             	mov    0x10(%ebp),%eax
  104d24:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	char buf[30], *p = buf;		// big enough for any 64-bit int in octal
  104d27:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  104d2a:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->base = base;		// select base for genint
  104d2d:	8b 45 08             	mov    0x8(%ebp),%eax
  104d30:	8b 55 14             	mov    0x14(%ebp),%edx
  104d33:	89 50 1c             	mov    %edx,0x1c(%eax)
	p = genint(st, p, num);		// output to the string buffer
  104d36:	8b 45 c0             	mov    -0x40(%ebp),%eax
  104d39:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  104d3c:	89 44 24 08          	mov    %eax,0x8(%esp)
  104d40:	89 54 24 0c          	mov    %edx,0xc(%esp)
  104d44:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104d47:	89 44 24 04          	mov    %eax,0x4(%esp)
  104d4b:	8b 45 08             	mov    0x8(%ebp),%eax
  104d4e:	89 04 24             	mov    %eax,(%esp)
  104d51:	e8 f2 fe ff ff       	call   104c48 <genint>
  104d56:	89 45 f4             	mov    %eax,-0xc(%ebp)
	putstr(st, buf, p-buf);		// print it with left/right padding
  104d59:	8b 55 f4             	mov    -0xc(%ebp),%edx
  104d5c:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  104d5f:	89 d1                	mov    %edx,%ecx
  104d61:	29 c1                	sub    %eax,%ecx
  104d63:	89 c8                	mov    %ecx,%eax
  104d65:	89 44 24 08          	mov    %eax,0x8(%esp)
  104d69:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  104d6c:	89 44 24 04          	mov    %eax,0x4(%esp)
  104d70:	8b 45 08             	mov    0x8(%ebp),%eax
  104d73:	89 04 24             	mov    %eax,(%esp)
  104d76:	e8 08 fe ff ff       	call   104b83 <putstr>
}
  104d7b:	c9                   	leave  
  104d7c:	c3                   	ret    

00104d7d <vprintfmt>:
#endif	// ! PIOS_KERNEL

// Main function to format and print a string.
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  104d7d:	55                   	push   %ebp
  104d7e:	89 e5                	mov    %esp,%ebp
  104d80:	53                   	push   %ebx
  104d81:	83 ec 44             	sub    $0x44,%esp
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
  104d84:	8d 55 cc             	lea    -0x34(%ebp),%edx
  104d87:	b9 00 00 00 00       	mov    $0x0,%ecx
  104d8c:	b8 20 00 00 00       	mov    $0x20,%eax
  104d91:	89 c3                	mov    %eax,%ebx
  104d93:	83 e3 fc             	and    $0xfffffffc,%ebx
  104d96:	b8 00 00 00 00       	mov    $0x0,%eax
  104d9b:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
  104d9e:	83 c0 04             	add    $0x4,%eax
  104da1:	39 d8                	cmp    %ebx,%eax
  104da3:	72 f6                	jb     104d9b <vprintfmt+0x1e>
  104da5:	01 c2                	add    %eax,%edx
  104da7:	8b 45 08             	mov    0x8(%ebp),%eax
  104daa:	89 45 cc             	mov    %eax,-0x34(%ebp)
  104dad:	8b 45 0c             	mov    0xc(%ebp),%eax
  104db0:	89 45 d0             	mov    %eax,-0x30(%ebp)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  104db3:	eb 17                	jmp    104dcc <vprintfmt+0x4f>
			if (ch == '\0')
  104db5:	85 db                	test   %ebx,%ebx
  104db7:	0f 84 50 03 00 00    	je     10510d <vprintfmt+0x390>
				return;
			putch(ch, putdat);
  104dbd:	8b 45 0c             	mov    0xc(%ebp),%eax
  104dc0:	89 44 24 04          	mov    %eax,0x4(%esp)
  104dc4:	89 1c 24             	mov    %ebx,(%esp)
  104dc7:	8b 45 08             	mov    0x8(%ebp),%eax
  104dca:	ff d0                	call   *%eax
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  104dcc:	8b 45 10             	mov    0x10(%ebp),%eax
  104dcf:	0f b6 00             	movzbl (%eax),%eax
  104dd2:	0f b6 d8             	movzbl %al,%ebx
  104dd5:	83 fb 25             	cmp    $0x25,%ebx
  104dd8:	0f 95 c0             	setne  %al
  104ddb:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  104ddf:	84 c0                	test   %al,%al
  104de1:	75 d2                	jne    104db5 <vprintfmt+0x38>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		st.padc = ' ';
  104de3:	c7 45 d4 20 00 00 00 	movl   $0x20,-0x2c(%ebp)
		st.width = -1;
  104dea:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		st.prec = -1;
  104df1:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		st.signc = -1;
  104df8:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		st.flags = 0;
  104dff:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		st.base = 10;
  104e06:	c7 45 e8 0a 00 00 00 	movl   $0xa,-0x18(%ebp)
  104e0d:	eb 04                	jmp    104e13 <vprintfmt+0x96>
			goto reswitch;

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
				st.signc = ' ';
			goto reswitch;
  104e0f:	90                   	nop
  104e10:	eb 01                	jmp    104e13 <vprintfmt+0x96>
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
				st.width = st.prec;	// then it's a field width
				st.prec = -1;
			}
			goto reswitch;
  104e12:	90                   	nop
		st.signc = -1;
		st.flags = 0;
		st.base = 10;
		uintmax_t num;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  104e13:	8b 45 10             	mov    0x10(%ebp),%eax
  104e16:	0f b6 00             	movzbl (%eax),%eax
  104e19:	0f b6 d8             	movzbl %al,%ebx
  104e1c:	89 d8                	mov    %ebx,%eax
  104e1e:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  104e22:	83 e8 20             	sub    $0x20,%eax
  104e25:	83 f8 58             	cmp    $0x58,%eax
  104e28:	0f 87 ae 02 00 00    	ja     1050dc <vprintfmt+0x35f>
  104e2e:	8b 04 85 54 69 10 00 	mov    0x106954(,%eax,4),%eax
  104e35:	ff e0                	jmp    *%eax

		// modifier flags
		case '-': // pad on the right instead of the left
			st.flags |= F_RPAD;
  104e37:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104e3a:	83 c8 10             	or     $0x10,%eax
  104e3d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
  104e40:	eb d1                	jmp    104e13 <vprintfmt+0x96>

		case '+': // prefix positive numeric values with a '+' sign
			st.signc = '+';
  104e42:	c7 45 e0 2b 00 00 00 	movl   $0x2b,-0x20(%ebp)
			goto reswitch;
  104e49:	eb c8                	jmp    104e13 <vprintfmt+0x96>

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
  104e4b:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104e4e:	85 c0                	test   %eax,%eax
  104e50:	79 bd                	jns    104e0f <vprintfmt+0x92>
				st.signc = ' ';
  104e52:	c7 45 e0 20 00 00 00 	movl   $0x20,-0x20(%ebp)
			goto reswitch;
  104e59:	eb b4                	jmp    104e0f <vprintfmt+0x92>

		// width or precision field
		case '0':
			if (!(st.flags & F_DOT))
  104e5b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104e5e:	83 e0 08             	and    $0x8,%eax
  104e61:	85 c0                	test   %eax,%eax
  104e63:	75 07                	jne    104e6c <vprintfmt+0xef>
				st.padc = '0'; // pad with 0's instead of spaces
  104e65:	c7 45 d4 30 00 00 00 	movl   $0x30,-0x2c(%ebp)
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  104e6c:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
				st.prec = st.prec * 10 + ch - '0';
  104e73:	8b 55 dc             	mov    -0x24(%ebp),%edx
  104e76:	89 d0                	mov    %edx,%eax
  104e78:	c1 e0 02             	shl    $0x2,%eax
  104e7b:	01 d0                	add    %edx,%eax
  104e7d:	01 c0                	add    %eax,%eax
  104e7f:	01 d8                	add    %ebx,%eax
  104e81:	83 e8 30             	sub    $0x30,%eax
  104e84:	89 45 dc             	mov    %eax,-0x24(%ebp)
				ch = *fmt;
  104e87:	8b 45 10             	mov    0x10(%ebp),%eax
  104e8a:	0f b6 00             	movzbl (%eax),%eax
  104e8d:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
  104e90:	83 fb 2f             	cmp    $0x2f,%ebx
  104e93:	7e 21                	jle    104eb6 <vprintfmt+0x139>
  104e95:	83 fb 39             	cmp    $0x39,%ebx
  104e98:	7f 1c                	jg     104eb6 <vprintfmt+0x139>
		case '0':
			if (!(st.flags & F_DOT))
				st.padc = '0'; // pad with 0's instead of spaces
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  104e9a:	83 45 10 01          	addl   $0x1,0x10(%ebp)
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  104e9e:	eb d3                	jmp    104e73 <vprintfmt+0xf6>
			goto gotprec;

		case '*':
			st.prec = va_arg(ap, int);
  104ea0:	8b 45 14             	mov    0x14(%ebp),%eax
  104ea3:	83 c0 04             	add    $0x4,%eax
  104ea6:	89 45 14             	mov    %eax,0x14(%ebp)
  104ea9:	8b 45 14             	mov    0x14(%ebp),%eax
  104eac:	83 e8 04             	sub    $0x4,%eax
  104eaf:	8b 00                	mov    (%eax),%eax
  104eb1:	89 45 dc             	mov    %eax,-0x24(%ebp)
  104eb4:	eb 01                	jmp    104eb7 <vprintfmt+0x13a>
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto gotprec;
  104eb6:	90                   	nop

		case '*':
			st.prec = va_arg(ap, int);
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
  104eb7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104eba:	83 e0 08             	and    $0x8,%eax
  104ebd:	85 c0                	test   %eax,%eax
  104ebf:	0f 85 4d ff ff ff    	jne    104e12 <vprintfmt+0x95>
				st.width = st.prec;	// then it's a field width
  104ec5:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104ec8:	89 45 d8             	mov    %eax,-0x28(%ebp)
				st.prec = -1;
  104ecb:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
			}
			goto reswitch;
  104ed2:	e9 3b ff ff ff       	jmp    104e12 <vprintfmt+0x95>

		case '.':
			st.flags |= F_DOT;
  104ed7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104eda:	83 c8 08             	or     $0x8,%eax
  104edd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
  104ee0:	e9 2e ff ff ff       	jmp    104e13 <vprintfmt+0x96>

		case '#':
			st.flags |= F_ALT;
  104ee5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104ee8:	83 c8 04             	or     $0x4,%eax
  104eeb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
  104eee:	e9 20 ff ff ff       	jmp    104e13 <vprintfmt+0x96>

		// long flag (doubled for long long)
		case 'l':
			st.flags |= (st.flags & F_L) ? F_LL : F_L;
  104ef3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  104ef6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104ef9:	83 e0 01             	and    $0x1,%eax
  104efc:	85 c0                	test   %eax,%eax
  104efe:	74 07                	je     104f07 <vprintfmt+0x18a>
  104f00:	b8 02 00 00 00       	mov    $0x2,%eax
  104f05:	eb 05                	jmp    104f0c <vprintfmt+0x18f>
  104f07:	b8 01 00 00 00       	mov    $0x1,%eax
  104f0c:	09 d0                	or     %edx,%eax
  104f0e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
  104f11:	e9 fd fe ff ff       	jmp    104e13 <vprintfmt+0x96>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  104f16:	8b 45 14             	mov    0x14(%ebp),%eax
  104f19:	83 c0 04             	add    $0x4,%eax
  104f1c:	89 45 14             	mov    %eax,0x14(%ebp)
  104f1f:	8b 45 14             	mov    0x14(%ebp),%eax
  104f22:	83 e8 04             	sub    $0x4,%eax
  104f25:	8b 00                	mov    (%eax),%eax
  104f27:	8b 55 0c             	mov    0xc(%ebp),%edx
  104f2a:	89 54 24 04          	mov    %edx,0x4(%esp)
  104f2e:	89 04 24             	mov    %eax,(%esp)
  104f31:	8b 45 08             	mov    0x8(%ebp),%eax
  104f34:	ff d0                	call   *%eax
			break;
  104f36:	e9 cc 01 00 00       	jmp    105107 <vprintfmt+0x38a>

		// string
		case 's': {
			const char *s;
			if ((s = va_arg(ap, char *)) == NULL)
  104f3b:	8b 45 14             	mov    0x14(%ebp),%eax
  104f3e:	83 c0 04             	add    $0x4,%eax
  104f41:	89 45 14             	mov    %eax,0x14(%ebp)
  104f44:	8b 45 14             	mov    0x14(%ebp),%eax
  104f47:	83 e8 04             	sub    $0x4,%eax
  104f4a:	8b 00                	mov    (%eax),%eax
  104f4c:	89 45 ec             	mov    %eax,-0x14(%ebp)
  104f4f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  104f53:	75 07                	jne    104f5c <vprintfmt+0x1df>
				s = "(null)";
  104f55:	c7 45 ec 4d 69 10 00 	movl   $0x10694d,-0x14(%ebp)
			putstr(&st, s, st.prec);
  104f5c:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104f5f:	89 44 24 08          	mov    %eax,0x8(%esp)
  104f63:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104f66:	89 44 24 04          	mov    %eax,0x4(%esp)
  104f6a:	8d 45 cc             	lea    -0x34(%ebp),%eax
  104f6d:	89 04 24             	mov    %eax,(%esp)
  104f70:	e8 0e fc ff ff       	call   104b83 <putstr>
			break;
  104f75:	e9 8d 01 00 00       	jmp    105107 <vprintfmt+0x38a>
		    }

		// (signed) decimal
		case 'd':
			num = getint(&st, &ap);
  104f7a:	8d 45 14             	lea    0x14(%ebp),%eax
  104f7d:	89 44 24 04          	mov    %eax,0x4(%esp)
  104f81:	8d 45 cc             	lea    -0x34(%ebp),%eax
  104f84:	89 04 24             	mov    %eax,(%esp)
  104f87:	e8 45 fb ff ff       	call   104ad1 <getint>
  104f8c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  104f8f:	89 55 f4             	mov    %edx,-0xc(%ebp)
			if ((intmax_t) num < 0) {
  104f92:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104f95:	8b 55 f4             	mov    -0xc(%ebp),%edx
  104f98:	85 d2                	test   %edx,%edx
  104f9a:	79 1a                	jns    104fb6 <vprintfmt+0x239>
				num = -(intmax_t) num;
  104f9c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104f9f:	8b 55 f4             	mov    -0xc(%ebp),%edx
  104fa2:	f7 d8                	neg    %eax
  104fa4:	83 d2 00             	adc    $0x0,%edx
  104fa7:	f7 da                	neg    %edx
  104fa9:	89 45 f0             	mov    %eax,-0x10(%ebp)
  104fac:	89 55 f4             	mov    %edx,-0xc(%ebp)
				st.signc = '-';
  104faf:	c7 45 e0 2d 00 00 00 	movl   $0x2d,-0x20(%ebp)
			}
			putint(&st, num, 10);
  104fb6:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  104fbd:	00 
  104fbe:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104fc1:	8b 55 f4             	mov    -0xc(%ebp),%edx
  104fc4:	89 44 24 04          	mov    %eax,0x4(%esp)
  104fc8:	89 54 24 08          	mov    %edx,0x8(%esp)
  104fcc:	8d 45 cc             	lea    -0x34(%ebp),%eax
  104fcf:	89 04 24             	mov    %eax,(%esp)
  104fd2:	e8 3e fd ff ff       	call   104d15 <putint>
			break;
  104fd7:	e9 2b 01 00 00       	jmp    105107 <vprintfmt+0x38a>

		// unsigned decimal
		case 'u':
			putint(&st, getuint(&st, &ap), 10);
  104fdc:	8d 45 14             	lea    0x14(%ebp),%eax
  104fdf:	89 44 24 04          	mov    %eax,0x4(%esp)
  104fe3:	8d 45 cc             	lea    -0x34(%ebp),%eax
  104fe6:	89 04 24             	mov    %eax,(%esp)
  104fe9:	e8 6e fa ff ff       	call   104a5c <getuint>
  104fee:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  104ff5:	00 
  104ff6:	89 44 24 04          	mov    %eax,0x4(%esp)
  104ffa:	89 54 24 08          	mov    %edx,0x8(%esp)
  104ffe:	8d 45 cc             	lea    -0x34(%ebp),%eax
  105001:	89 04 24             	mov    %eax,(%esp)
  105004:	e8 0c fd ff ff       	call   104d15 <putint>
			break;
  105009:	e9 f9 00 00 00       	jmp    105107 <vprintfmt+0x38a>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putint(&st, getuint(&st, &ap), 8);
  10500e:	8d 45 14             	lea    0x14(%ebp),%eax
  105011:	89 44 24 04          	mov    %eax,0x4(%esp)
  105015:	8d 45 cc             	lea    -0x34(%ebp),%eax
  105018:	89 04 24             	mov    %eax,(%esp)
  10501b:	e8 3c fa ff ff       	call   104a5c <getuint>
  105020:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  105027:	00 
  105028:	89 44 24 04          	mov    %eax,0x4(%esp)
  10502c:	89 54 24 08          	mov    %edx,0x8(%esp)
  105030:	8d 45 cc             	lea    -0x34(%ebp),%eax
  105033:	89 04 24             	mov    %eax,(%esp)
  105036:	e8 da fc ff ff       	call   104d15 <putint>
			break;
  10503b:	e9 c7 00 00 00       	jmp    105107 <vprintfmt+0x38a>

		// (unsigned) hexadecimal
		case 'x':
			putint(&st, getuint(&st, &ap), 16);
  105040:	8d 45 14             	lea    0x14(%ebp),%eax
  105043:	89 44 24 04          	mov    %eax,0x4(%esp)
  105047:	8d 45 cc             	lea    -0x34(%ebp),%eax
  10504a:	89 04 24             	mov    %eax,(%esp)
  10504d:	e8 0a fa ff ff       	call   104a5c <getuint>
  105052:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  105059:	00 
  10505a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10505e:	89 54 24 08          	mov    %edx,0x8(%esp)
  105062:	8d 45 cc             	lea    -0x34(%ebp),%eax
  105065:	89 04 24             	mov    %eax,(%esp)
  105068:	e8 a8 fc ff ff       	call   104d15 <putint>
			break;
  10506d:	e9 95 00 00 00       	jmp    105107 <vprintfmt+0x38a>

		// pointer
		case 'p':
			putch('0', putdat);
  105072:	8b 45 0c             	mov    0xc(%ebp),%eax
  105075:	89 44 24 04          	mov    %eax,0x4(%esp)
  105079:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  105080:	8b 45 08             	mov    0x8(%ebp),%eax
  105083:	ff d0                	call   *%eax
			putch('x', putdat);
  105085:	8b 45 0c             	mov    0xc(%ebp),%eax
  105088:	89 44 24 04          	mov    %eax,0x4(%esp)
  10508c:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  105093:	8b 45 08             	mov    0x8(%ebp),%eax
  105096:	ff d0                	call   *%eax
			putint(&st, (uintptr_t) va_arg(ap, void *), 16);
  105098:	8b 45 14             	mov    0x14(%ebp),%eax
  10509b:	83 c0 04             	add    $0x4,%eax
  10509e:	89 45 14             	mov    %eax,0x14(%ebp)
  1050a1:	8b 45 14             	mov    0x14(%ebp),%eax
  1050a4:	83 e8 04             	sub    $0x4,%eax
  1050a7:	8b 00                	mov    (%eax),%eax
  1050a9:	ba 00 00 00 00       	mov    $0x0,%edx
  1050ae:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  1050b5:	00 
  1050b6:	89 44 24 04          	mov    %eax,0x4(%esp)
  1050ba:	89 54 24 08          	mov    %edx,0x8(%esp)
  1050be:	8d 45 cc             	lea    -0x34(%ebp),%eax
  1050c1:	89 04 24             	mov    %eax,(%esp)
  1050c4:	e8 4c fc ff ff       	call   104d15 <putint>
			break;
  1050c9:	eb 3c                	jmp    105107 <vprintfmt+0x38a>
		    }
#endif	// ! PIOS_KERNEL

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  1050cb:	8b 45 0c             	mov    0xc(%ebp),%eax
  1050ce:	89 44 24 04          	mov    %eax,0x4(%esp)
  1050d2:	89 1c 24             	mov    %ebx,(%esp)
  1050d5:	8b 45 08             	mov    0x8(%ebp),%eax
  1050d8:	ff d0                	call   *%eax
			break;
  1050da:	eb 2b                	jmp    105107 <vprintfmt+0x38a>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  1050dc:	8b 45 0c             	mov    0xc(%ebp),%eax
  1050df:	89 44 24 04          	mov    %eax,0x4(%esp)
  1050e3:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  1050ea:	8b 45 08             	mov    0x8(%ebp),%eax
  1050ed:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
  1050ef:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  1050f3:	eb 04                	jmp    1050f9 <vprintfmt+0x37c>
  1050f5:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  1050f9:	8b 45 10             	mov    0x10(%ebp),%eax
  1050fc:	83 e8 01             	sub    $0x1,%eax
  1050ff:	0f b6 00             	movzbl (%eax),%eax
  105102:	3c 25                	cmp    $0x25,%al
  105104:	75 ef                	jne    1050f5 <vprintfmt+0x378>
				/* do nothing */;
			break;
  105106:	90                   	nop
		}
	}
  105107:	90                   	nop
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  105108:	e9 bf fc ff ff       	jmp    104dcc <vprintfmt+0x4f>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
  10510d:	83 c4 44             	add    $0x44,%esp
  105110:	5b                   	pop    %ebx
  105111:	5d                   	pop    %ebp
  105112:	c3                   	ret    
  105113:	90                   	nop

00105114 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  105114:	55                   	push   %ebp
  105115:	89 e5                	mov    %esp,%ebp
  105117:	83 ec 18             	sub    $0x18,%esp
	b->buf[b->idx++] = ch;
  10511a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10511d:	8b 00                	mov    (%eax),%eax
  10511f:	8b 55 08             	mov    0x8(%ebp),%edx
  105122:	89 d1                	mov    %edx,%ecx
  105124:	8b 55 0c             	mov    0xc(%ebp),%edx
  105127:	88 4c 02 08          	mov    %cl,0x8(%edx,%eax,1)
  10512b:	8d 50 01             	lea    0x1(%eax),%edx
  10512e:	8b 45 0c             	mov    0xc(%ebp),%eax
  105131:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
  105133:	8b 45 0c             	mov    0xc(%ebp),%eax
  105136:	8b 00                	mov    (%eax),%eax
  105138:	3d ff 00 00 00       	cmp    $0xff,%eax
  10513d:	75 24                	jne    105163 <putch+0x4f>
		b->buf[b->idx] = 0;
  10513f:	8b 45 0c             	mov    0xc(%ebp),%eax
  105142:	8b 00                	mov    (%eax),%eax
  105144:	8b 55 0c             	mov    0xc(%ebp),%edx
  105147:	c6 44 02 08 00       	movb   $0x0,0x8(%edx,%eax,1)
		cputs(b->buf);
  10514c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10514f:	83 c0 08             	add    $0x8,%eax
  105152:	89 04 24             	mov    %eax,(%esp)
  105155:	e8 da b2 ff ff       	call   100434 <cputs>
		b->idx = 0;
  10515a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10515d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
  105163:	8b 45 0c             	mov    0xc(%ebp),%eax
  105166:	8b 40 04             	mov    0x4(%eax),%eax
  105169:	8d 50 01             	lea    0x1(%eax),%edx
  10516c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10516f:	89 50 04             	mov    %edx,0x4(%eax)
}
  105172:	c9                   	leave  
  105173:	c3                   	ret    

00105174 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  105174:	55                   	push   %ebp
  105175:	89 e5                	mov    %esp,%ebp
  105177:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  10517d:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  105184:	00 00 00 
	b.cnt = 0;
  105187:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  10518e:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  105191:	8b 45 0c             	mov    0xc(%ebp),%eax
  105194:	89 44 24 0c          	mov    %eax,0xc(%esp)
  105198:	8b 45 08             	mov    0x8(%ebp),%eax
  10519b:	89 44 24 08          	mov    %eax,0x8(%esp)
  10519f:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  1051a5:	89 44 24 04          	mov    %eax,0x4(%esp)
  1051a9:	c7 04 24 14 51 10 00 	movl   $0x105114,(%esp)
  1051b0:	e8 c8 fb ff ff       	call   104d7d <vprintfmt>

	b.buf[b.idx] = 0;
  1051b5:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  1051bb:	c6 84 05 f8 fe ff ff 	movb   $0x0,-0x108(%ebp,%eax,1)
  1051c2:	00 
	cputs(b.buf);
  1051c3:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  1051c9:	83 c0 08             	add    $0x8,%eax
  1051cc:	89 04 24             	mov    %eax,(%esp)
  1051cf:	e8 60 b2 ff ff       	call   100434 <cputs>

	return b.cnt;
  1051d4:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
}
  1051da:	c9                   	leave  
  1051db:	c3                   	ret    

001051dc <cprintf>:

int
cprintf(const char *fmt, ...)
{
  1051dc:	55                   	push   %ebp
  1051dd:	89 e5                	mov    %esp,%ebp
  1051df:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  1051e2:	8d 45 0c             	lea    0xc(%ebp),%eax
  1051e5:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cnt = vcprintf(fmt, ap);
  1051e8:	8b 45 08             	mov    0x8(%ebp),%eax
  1051eb:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1051ee:	89 54 24 04          	mov    %edx,0x4(%esp)
  1051f2:	89 04 24             	mov    %eax,(%esp)
  1051f5:	e8 7a ff ff ff       	call   105174 <vcprintf>
  1051fa:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return cnt;
  1051fd:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  105200:	c9                   	leave  
  105201:	c3                   	ret    
  105202:	90                   	nop
  105203:	90                   	nop

00105204 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  105204:	55                   	push   %ebp
  105205:	89 e5                	mov    %esp,%ebp
  105207:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
  10520a:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  105211:	eb 08                	jmp    10521b <strlen+0x17>
		n++;
  105213:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  105217:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10521b:	8b 45 08             	mov    0x8(%ebp),%eax
  10521e:	0f b6 00             	movzbl (%eax),%eax
  105221:	84 c0                	test   %al,%al
  105223:	75 ee                	jne    105213 <strlen+0xf>
		n++;
	return n;
  105225:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  105228:	c9                   	leave  
  105229:	c3                   	ret    

0010522a <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  10522a:	55                   	push   %ebp
  10522b:	89 e5                	mov    %esp,%ebp
  10522d:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
  105230:	8b 45 08             	mov    0x8(%ebp),%eax
  105233:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
  105236:	90                   	nop
  105237:	8b 45 0c             	mov    0xc(%ebp),%eax
  10523a:	0f b6 10             	movzbl (%eax),%edx
  10523d:	8b 45 08             	mov    0x8(%ebp),%eax
  105240:	88 10                	mov    %dl,(%eax)
  105242:	8b 45 08             	mov    0x8(%ebp),%eax
  105245:	0f b6 00             	movzbl (%eax),%eax
  105248:	84 c0                	test   %al,%al
  10524a:	0f 95 c0             	setne  %al
  10524d:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  105251:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  105255:	84 c0                	test   %al,%al
  105257:	75 de                	jne    105237 <strcpy+0xd>
		/* do nothing */;
	return ret;
  105259:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  10525c:	c9                   	leave  
  10525d:	c3                   	ret    

0010525e <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
  10525e:	55                   	push   %ebp
  10525f:	89 e5                	mov    %esp,%ebp
  105261:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
  105264:	8b 45 08             	mov    0x8(%ebp),%eax
  105267:	89 45 f8             	mov    %eax,-0x8(%ebp)
	for (i = 0; i < size; i++) {
  10526a:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  105271:	eb 21                	jmp    105294 <strncpy+0x36>
		*dst++ = *src;
  105273:	8b 45 0c             	mov    0xc(%ebp),%eax
  105276:	0f b6 10             	movzbl (%eax),%edx
  105279:	8b 45 08             	mov    0x8(%ebp),%eax
  10527c:	88 10                	mov    %dl,(%eax)
  10527e:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
  105282:	8b 45 0c             	mov    0xc(%ebp),%eax
  105285:	0f b6 00             	movzbl (%eax),%eax
  105288:	84 c0                	test   %al,%al
  10528a:	74 04                	je     105290 <strncpy+0x32>
			src++;
  10528c:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  105290:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  105294:	8b 45 fc             	mov    -0x4(%ebp),%eax
  105297:	3b 45 10             	cmp    0x10(%ebp),%eax
  10529a:	72 d7                	jb     105273 <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
  10529c:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
  10529f:	c9                   	leave  
  1052a0:	c3                   	ret    

001052a1 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  1052a1:	55                   	push   %ebp
  1052a2:	89 e5                	mov    %esp,%ebp
  1052a4:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
  1052a7:	8b 45 08             	mov    0x8(%ebp),%eax
  1052aa:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
  1052ad:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1052b1:	74 2f                	je     1052e2 <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
  1052b3:	eb 13                	jmp    1052c8 <strlcpy+0x27>
			*dst++ = *src++;
  1052b5:	8b 45 0c             	mov    0xc(%ebp),%eax
  1052b8:	0f b6 10             	movzbl (%eax),%edx
  1052bb:	8b 45 08             	mov    0x8(%ebp),%eax
  1052be:	88 10                	mov    %dl,(%eax)
  1052c0:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1052c4:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  1052c8:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  1052cc:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1052d0:	74 0a                	je     1052dc <strlcpy+0x3b>
  1052d2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1052d5:	0f b6 00             	movzbl (%eax),%eax
  1052d8:	84 c0                	test   %al,%al
  1052da:	75 d9                	jne    1052b5 <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
  1052dc:	8b 45 08             	mov    0x8(%ebp),%eax
  1052df:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  1052e2:	8b 55 08             	mov    0x8(%ebp),%edx
  1052e5:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1052e8:	89 d1                	mov    %edx,%ecx
  1052ea:	29 c1                	sub    %eax,%ecx
  1052ec:	89 c8                	mov    %ecx,%eax
}
  1052ee:	c9                   	leave  
  1052ef:	c3                   	ret    

001052f0 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  1052f0:	55                   	push   %ebp
  1052f1:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
  1052f3:	eb 08                	jmp    1052fd <strcmp+0xd>
		p++, q++;
  1052f5:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1052f9:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  1052fd:	8b 45 08             	mov    0x8(%ebp),%eax
  105300:	0f b6 00             	movzbl (%eax),%eax
  105303:	84 c0                	test   %al,%al
  105305:	74 10                	je     105317 <strcmp+0x27>
  105307:	8b 45 08             	mov    0x8(%ebp),%eax
  10530a:	0f b6 10             	movzbl (%eax),%edx
  10530d:	8b 45 0c             	mov    0xc(%ebp),%eax
  105310:	0f b6 00             	movzbl (%eax),%eax
  105313:	38 c2                	cmp    %al,%dl
  105315:	74 de                	je     1052f5 <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  105317:	8b 45 08             	mov    0x8(%ebp),%eax
  10531a:	0f b6 00             	movzbl (%eax),%eax
  10531d:	0f b6 d0             	movzbl %al,%edx
  105320:	8b 45 0c             	mov    0xc(%ebp),%eax
  105323:	0f b6 00             	movzbl (%eax),%eax
  105326:	0f b6 c0             	movzbl %al,%eax
  105329:	89 d1                	mov    %edx,%ecx
  10532b:	29 c1                	sub    %eax,%ecx
  10532d:	89 c8                	mov    %ecx,%eax
}
  10532f:	5d                   	pop    %ebp
  105330:	c3                   	ret    

00105331 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  105331:	55                   	push   %ebp
  105332:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
  105334:	eb 0c                	jmp    105342 <strncmp+0x11>
		n--, p++, q++;
  105336:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10533a:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10533e:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  105342:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  105346:	74 1a                	je     105362 <strncmp+0x31>
  105348:	8b 45 08             	mov    0x8(%ebp),%eax
  10534b:	0f b6 00             	movzbl (%eax),%eax
  10534e:	84 c0                	test   %al,%al
  105350:	74 10                	je     105362 <strncmp+0x31>
  105352:	8b 45 08             	mov    0x8(%ebp),%eax
  105355:	0f b6 10             	movzbl (%eax),%edx
  105358:	8b 45 0c             	mov    0xc(%ebp),%eax
  10535b:	0f b6 00             	movzbl (%eax),%eax
  10535e:	38 c2                	cmp    %al,%dl
  105360:	74 d4                	je     105336 <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
  105362:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  105366:	75 07                	jne    10536f <strncmp+0x3e>
		return 0;
  105368:	b8 00 00 00 00       	mov    $0x0,%eax
  10536d:	eb 18                	jmp    105387 <strncmp+0x56>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  10536f:	8b 45 08             	mov    0x8(%ebp),%eax
  105372:	0f b6 00             	movzbl (%eax),%eax
  105375:	0f b6 d0             	movzbl %al,%edx
  105378:	8b 45 0c             	mov    0xc(%ebp),%eax
  10537b:	0f b6 00             	movzbl (%eax),%eax
  10537e:	0f b6 c0             	movzbl %al,%eax
  105381:	89 d1                	mov    %edx,%ecx
  105383:	29 c1                	sub    %eax,%ecx
  105385:	89 c8                	mov    %ecx,%eax
}
  105387:	5d                   	pop    %ebp
  105388:	c3                   	ret    

00105389 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  105389:	55                   	push   %ebp
  10538a:	89 e5                	mov    %esp,%ebp
  10538c:	83 ec 04             	sub    $0x4,%esp
  10538f:	8b 45 0c             	mov    0xc(%ebp),%eax
  105392:	88 45 fc             	mov    %al,-0x4(%ebp)
	while (*s != c)
  105395:	eb 1a                	jmp    1053b1 <strchr+0x28>
		if (*s++ == 0)
  105397:	8b 45 08             	mov    0x8(%ebp),%eax
  10539a:	0f b6 00             	movzbl (%eax),%eax
  10539d:	84 c0                	test   %al,%al
  10539f:	0f 94 c0             	sete   %al
  1053a2:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1053a6:	84 c0                	test   %al,%al
  1053a8:	74 07                	je     1053b1 <strchr+0x28>
			return NULL;
  1053aa:	b8 00 00 00 00       	mov    $0x0,%eax
  1053af:	eb 0e                	jmp    1053bf <strchr+0x36>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	while (*s != c)
  1053b1:	8b 45 08             	mov    0x8(%ebp),%eax
  1053b4:	0f b6 00             	movzbl (%eax),%eax
  1053b7:	3a 45 fc             	cmp    -0x4(%ebp),%al
  1053ba:	75 db                	jne    105397 <strchr+0xe>
		if (*s++ == 0)
			return NULL;
	return (char *) s;
  1053bc:	8b 45 08             	mov    0x8(%ebp),%eax
}
  1053bf:	c9                   	leave  
  1053c0:	c3                   	ret    

001053c1 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  1053c1:	55                   	push   %ebp
  1053c2:	89 e5                	mov    %esp,%ebp
  1053c4:	57                   	push   %edi
	char *p;

	if (n == 0)
  1053c5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1053c9:	75 05                	jne    1053d0 <memset+0xf>
		return v;
  1053cb:	8b 45 08             	mov    0x8(%ebp),%eax
  1053ce:	eb 5c                	jmp    10542c <memset+0x6b>
	if ((int)v%4 == 0 && n%4 == 0) {
  1053d0:	8b 45 08             	mov    0x8(%ebp),%eax
  1053d3:	83 e0 03             	and    $0x3,%eax
  1053d6:	85 c0                	test   %eax,%eax
  1053d8:	75 41                	jne    10541b <memset+0x5a>
  1053da:	8b 45 10             	mov    0x10(%ebp),%eax
  1053dd:	83 e0 03             	and    $0x3,%eax
  1053e0:	85 c0                	test   %eax,%eax
  1053e2:	75 37                	jne    10541b <memset+0x5a>
		c &= 0xFF;
  1053e4:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
  1053eb:	8b 45 0c             	mov    0xc(%ebp),%eax
  1053ee:	89 c2                	mov    %eax,%edx
  1053f0:	c1 e2 18             	shl    $0x18,%edx
  1053f3:	8b 45 0c             	mov    0xc(%ebp),%eax
  1053f6:	c1 e0 10             	shl    $0x10,%eax
  1053f9:	09 c2                	or     %eax,%edx
  1053fb:	8b 45 0c             	mov    0xc(%ebp),%eax
  1053fe:	c1 e0 08             	shl    $0x8,%eax
  105401:	09 d0                	or     %edx,%eax
  105403:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  105406:	8b 45 10             	mov    0x10(%ebp),%eax
  105409:	89 c1                	mov    %eax,%ecx
  10540b:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  10540e:	8b 55 08             	mov    0x8(%ebp),%edx
  105411:	8b 45 0c             	mov    0xc(%ebp),%eax
  105414:	89 d7                	mov    %edx,%edi
  105416:	fc                   	cld    
  105417:	f3 ab                	rep stos %eax,%es:(%edi)
  105419:	eb 0e                	jmp    105429 <memset+0x68>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  10541b:	8b 55 08             	mov    0x8(%ebp),%edx
  10541e:	8b 45 0c             	mov    0xc(%ebp),%eax
  105421:	8b 4d 10             	mov    0x10(%ebp),%ecx
  105424:	89 d7                	mov    %edx,%edi
  105426:	fc                   	cld    
  105427:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
  105429:	8b 45 08             	mov    0x8(%ebp),%eax
}
  10542c:	5f                   	pop    %edi
  10542d:	5d                   	pop    %ebp
  10542e:	c3                   	ret    

0010542f <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  10542f:	55                   	push   %ebp
  105430:	89 e5                	mov    %esp,%ebp
  105432:	57                   	push   %edi
  105433:	56                   	push   %esi
  105434:	53                   	push   %ebx
  105435:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
  105438:	8b 45 0c             	mov    0xc(%ebp),%eax
  10543b:	89 45 f0             	mov    %eax,-0x10(%ebp)
	d = dst;
  10543e:	8b 45 08             	mov    0x8(%ebp),%eax
  105441:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (s < d && s + n > d) {
  105444:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105447:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  10544a:	73 6d                	jae    1054b9 <memmove+0x8a>
  10544c:	8b 45 10             	mov    0x10(%ebp),%eax
  10544f:	8b 55 f0             	mov    -0x10(%ebp),%edx
  105452:	01 d0                	add    %edx,%eax
  105454:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  105457:	76 60                	jbe    1054b9 <memmove+0x8a>
		s += n;
  105459:	8b 45 10             	mov    0x10(%ebp),%eax
  10545c:	01 45 f0             	add    %eax,-0x10(%ebp)
		d += n;
  10545f:	8b 45 10             	mov    0x10(%ebp),%eax
  105462:	01 45 ec             	add    %eax,-0x14(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  105465:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105468:	83 e0 03             	and    $0x3,%eax
  10546b:	85 c0                	test   %eax,%eax
  10546d:	75 2f                	jne    10549e <memmove+0x6f>
  10546f:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105472:	83 e0 03             	and    $0x3,%eax
  105475:	85 c0                	test   %eax,%eax
  105477:	75 25                	jne    10549e <memmove+0x6f>
  105479:	8b 45 10             	mov    0x10(%ebp),%eax
  10547c:	83 e0 03             	and    $0x3,%eax
  10547f:	85 c0                	test   %eax,%eax
  105481:	75 1b                	jne    10549e <memmove+0x6f>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  105483:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105486:	83 e8 04             	sub    $0x4,%eax
  105489:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10548c:	83 ea 04             	sub    $0x4,%edx
  10548f:	8b 4d 10             	mov    0x10(%ebp),%ecx
  105492:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  105495:	89 c7                	mov    %eax,%edi
  105497:	89 d6                	mov    %edx,%esi
  105499:	fd                   	std    
  10549a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  10549c:	eb 18                	jmp    1054b6 <memmove+0x87>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  10549e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1054a1:	8d 50 ff             	lea    -0x1(%eax),%edx
  1054a4:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1054a7:	8d 58 ff             	lea    -0x1(%eax),%ebx
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  1054aa:	8b 45 10             	mov    0x10(%ebp),%eax
  1054ad:	89 d7                	mov    %edx,%edi
  1054af:	89 de                	mov    %ebx,%esi
  1054b1:	89 c1                	mov    %eax,%ecx
  1054b3:	fd                   	std    
  1054b4:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  1054b6:	fc                   	cld    
  1054b7:	eb 45                	jmp    1054fe <memmove+0xcf>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  1054b9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1054bc:	83 e0 03             	and    $0x3,%eax
  1054bf:	85 c0                	test   %eax,%eax
  1054c1:	75 2b                	jne    1054ee <memmove+0xbf>
  1054c3:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1054c6:	83 e0 03             	and    $0x3,%eax
  1054c9:	85 c0                	test   %eax,%eax
  1054cb:	75 21                	jne    1054ee <memmove+0xbf>
  1054cd:	8b 45 10             	mov    0x10(%ebp),%eax
  1054d0:	83 e0 03             	and    $0x3,%eax
  1054d3:	85 c0                	test   %eax,%eax
  1054d5:	75 17                	jne    1054ee <memmove+0xbf>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  1054d7:	8b 45 10             	mov    0x10(%ebp),%eax
  1054da:	89 c1                	mov    %eax,%ecx
  1054dc:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  1054df:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1054e2:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1054e5:	89 c7                	mov    %eax,%edi
  1054e7:	89 d6                	mov    %edx,%esi
  1054e9:	fc                   	cld    
  1054ea:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  1054ec:	eb 10                	jmp    1054fe <memmove+0xcf>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  1054ee:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1054f1:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1054f4:	8b 4d 10             	mov    0x10(%ebp),%ecx
  1054f7:	89 c7                	mov    %eax,%edi
  1054f9:	89 d6                	mov    %edx,%esi
  1054fb:	fc                   	cld    
  1054fc:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
  1054fe:	8b 45 08             	mov    0x8(%ebp),%eax
}
  105501:	83 c4 10             	add    $0x10,%esp
  105504:	5b                   	pop    %ebx
  105505:	5e                   	pop    %esi
  105506:	5f                   	pop    %edi
  105507:	5d                   	pop    %ebp
  105508:	c3                   	ret    

00105509 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  105509:	55                   	push   %ebp
  10550a:	89 e5                	mov    %esp,%ebp
  10550c:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  10550f:	8b 45 10             	mov    0x10(%ebp),%eax
  105512:	89 44 24 08          	mov    %eax,0x8(%esp)
  105516:	8b 45 0c             	mov    0xc(%ebp),%eax
  105519:	89 44 24 04          	mov    %eax,0x4(%esp)
  10551d:	8b 45 08             	mov    0x8(%ebp),%eax
  105520:	89 04 24             	mov    %eax,(%esp)
  105523:	e8 07 ff ff ff       	call   10542f <memmove>
}
  105528:	c9                   	leave  
  105529:	c3                   	ret    

0010552a <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  10552a:	55                   	push   %ebp
  10552b:	89 e5                	mov    %esp,%ebp
  10552d:	83 ec 10             	sub    $0x10,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
  105530:	8b 45 08             	mov    0x8(%ebp),%eax
  105533:	89 45 fc             	mov    %eax,-0x4(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
  105536:	8b 45 0c             	mov    0xc(%ebp),%eax
  105539:	89 45 f8             	mov    %eax,-0x8(%ebp)

	while (n-- > 0) {
  10553c:	eb 32                	jmp    105570 <memcmp+0x46>
		if (*s1 != *s2)
  10553e:	8b 45 fc             	mov    -0x4(%ebp),%eax
  105541:	0f b6 10             	movzbl (%eax),%edx
  105544:	8b 45 f8             	mov    -0x8(%ebp),%eax
  105547:	0f b6 00             	movzbl (%eax),%eax
  10554a:	38 c2                	cmp    %al,%dl
  10554c:	74 1a                	je     105568 <memcmp+0x3e>
			return (int) *s1 - (int) *s2;
  10554e:	8b 45 fc             	mov    -0x4(%ebp),%eax
  105551:	0f b6 00             	movzbl (%eax),%eax
  105554:	0f b6 d0             	movzbl %al,%edx
  105557:	8b 45 f8             	mov    -0x8(%ebp),%eax
  10555a:	0f b6 00             	movzbl (%eax),%eax
  10555d:	0f b6 c0             	movzbl %al,%eax
  105560:	89 d1                	mov    %edx,%ecx
  105562:	29 c1                	sub    %eax,%ecx
  105564:	89 c8                	mov    %ecx,%eax
  105566:	eb 1c                	jmp    105584 <memcmp+0x5a>
		s1++, s2++;
  105568:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  10556c:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  105570:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  105574:	0f 95 c0             	setne  %al
  105577:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10557b:	84 c0                	test   %al,%al
  10557d:	75 bf                	jne    10553e <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  10557f:	b8 00 00 00 00       	mov    $0x0,%eax
}
  105584:	c9                   	leave  
  105585:	c3                   	ret    

00105586 <memchr>:

void *
memchr(const void *s, int c, size_t n)
{
  105586:	55                   	push   %ebp
  105587:	89 e5                	mov    %esp,%ebp
  105589:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
  10558c:	8b 45 10             	mov    0x10(%ebp),%eax
  10558f:	8b 55 08             	mov    0x8(%ebp),%edx
  105592:	01 d0                	add    %edx,%eax
  105594:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
  105597:	eb 16                	jmp    1055af <memchr+0x29>
		if (*(const unsigned char *) s == (unsigned char) c)
  105599:	8b 45 08             	mov    0x8(%ebp),%eax
  10559c:	0f b6 10             	movzbl (%eax),%edx
  10559f:	8b 45 0c             	mov    0xc(%ebp),%eax
  1055a2:	38 c2                	cmp    %al,%dl
  1055a4:	75 05                	jne    1055ab <memchr+0x25>
			return (void *) s;
  1055a6:	8b 45 08             	mov    0x8(%ebp),%eax
  1055a9:	eb 11                	jmp    1055bc <memchr+0x36>

void *
memchr(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  1055ab:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1055af:	8b 45 08             	mov    0x8(%ebp),%eax
  1055b2:	3b 45 fc             	cmp    -0x4(%ebp),%eax
  1055b5:	72 e2                	jb     105599 <memchr+0x13>
		if (*(const unsigned char *) s == (unsigned char) c)
			return (void *) s;
	return NULL;
  1055b7:	b8 00 00 00 00       	mov    $0x0,%eax
}
  1055bc:	c9                   	leave  
  1055bd:	c3                   	ret    
  1055be:	90                   	nop
  1055bf:	90                   	nop

001055c0 <__udivdi3>:
  1055c0:	83 ec 1c             	sub    $0x1c,%esp
  1055c3:	8b 44 24 2c          	mov    0x2c(%esp),%eax
  1055c7:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  1055cb:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  1055cf:	8b 6c 24 20          	mov    0x20(%esp),%ebp
  1055d3:	89 74 24 10          	mov    %esi,0x10(%esp)
  1055d7:	8b 74 24 24          	mov    0x24(%esp),%esi
  1055db:	85 c0                	test   %eax,%eax
  1055dd:	89 7c 24 14          	mov    %edi,0x14(%esp)
  1055e1:	89 cf                	mov    %ecx,%edi
  1055e3:	89 6c 24 04          	mov    %ebp,0x4(%esp)
  1055e7:	75 37                	jne    105620 <__udivdi3+0x60>
  1055e9:	39 f1                	cmp    %esi,%ecx
  1055eb:	77 73                	ja     105660 <__udivdi3+0xa0>
  1055ed:	85 c9                	test   %ecx,%ecx
  1055ef:	75 0b                	jne    1055fc <__udivdi3+0x3c>
  1055f1:	b8 01 00 00 00       	mov    $0x1,%eax
  1055f6:	31 d2                	xor    %edx,%edx
  1055f8:	f7 f1                	div    %ecx
  1055fa:	89 c1                	mov    %eax,%ecx
  1055fc:	89 f0                	mov    %esi,%eax
  1055fe:	31 d2                	xor    %edx,%edx
  105600:	f7 f1                	div    %ecx
  105602:	89 c6                	mov    %eax,%esi
  105604:	89 e8                	mov    %ebp,%eax
  105606:	f7 f1                	div    %ecx
  105608:	89 f2                	mov    %esi,%edx
  10560a:	8b 74 24 10          	mov    0x10(%esp),%esi
  10560e:	8b 7c 24 14          	mov    0x14(%esp),%edi
  105612:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  105616:	83 c4 1c             	add    $0x1c,%esp
  105619:	c3                   	ret    
  10561a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  105620:	39 f0                	cmp    %esi,%eax
  105622:	77 24                	ja     105648 <__udivdi3+0x88>
  105624:	0f bd e8             	bsr    %eax,%ebp
  105627:	83 f5 1f             	xor    $0x1f,%ebp
  10562a:	75 4c                	jne    105678 <__udivdi3+0xb8>
  10562c:	31 d2                	xor    %edx,%edx
  10562e:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
  105632:	0f 86 b0 00 00 00    	jbe    1056e8 <__udivdi3+0x128>
  105638:	39 f0                	cmp    %esi,%eax
  10563a:	0f 82 a8 00 00 00    	jb     1056e8 <__udivdi3+0x128>
  105640:	31 c0                	xor    %eax,%eax
  105642:	eb c6                	jmp    10560a <__udivdi3+0x4a>
  105644:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  105648:	31 d2                	xor    %edx,%edx
  10564a:	31 c0                	xor    %eax,%eax
  10564c:	8b 74 24 10          	mov    0x10(%esp),%esi
  105650:	8b 7c 24 14          	mov    0x14(%esp),%edi
  105654:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  105658:	83 c4 1c             	add    $0x1c,%esp
  10565b:	c3                   	ret    
  10565c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  105660:	89 e8                	mov    %ebp,%eax
  105662:	89 f2                	mov    %esi,%edx
  105664:	f7 f1                	div    %ecx
  105666:	31 d2                	xor    %edx,%edx
  105668:	8b 74 24 10          	mov    0x10(%esp),%esi
  10566c:	8b 7c 24 14          	mov    0x14(%esp),%edi
  105670:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  105674:	83 c4 1c             	add    $0x1c,%esp
  105677:	c3                   	ret    
  105678:	89 e9                	mov    %ebp,%ecx
  10567a:	89 fa                	mov    %edi,%edx
  10567c:	d3 e0                	shl    %cl,%eax
  10567e:	89 44 24 08          	mov    %eax,0x8(%esp)
  105682:	b8 20 00 00 00       	mov    $0x20,%eax
  105687:	29 e8                	sub    %ebp,%eax
  105689:	89 c1                	mov    %eax,%ecx
  10568b:	d3 ea                	shr    %cl,%edx
  10568d:	8b 4c 24 08          	mov    0x8(%esp),%ecx
  105691:	09 ca                	or     %ecx,%edx
  105693:	89 e9                	mov    %ebp,%ecx
  105695:	d3 e7                	shl    %cl,%edi
  105697:	89 c1                	mov    %eax,%ecx
  105699:	89 54 24 0c          	mov    %edx,0xc(%esp)
  10569d:	89 f2                	mov    %esi,%edx
  10569f:	d3 ea                	shr    %cl,%edx
  1056a1:	89 e9                	mov    %ebp,%ecx
  1056a3:	89 14 24             	mov    %edx,(%esp)
  1056a6:	8b 54 24 04          	mov    0x4(%esp),%edx
  1056aa:	d3 e6                	shl    %cl,%esi
  1056ac:	89 c1                	mov    %eax,%ecx
  1056ae:	d3 ea                	shr    %cl,%edx
  1056b0:	89 d0                	mov    %edx,%eax
  1056b2:	09 f0                	or     %esi,%eax
  1056b4:	8b 34 24             	mov    (%esp),%esi
  1056b7:	89 f2                	mov    %esi,%edx
  1056b9:	f7 74 24 0c          	divl   0xc(%esp)
  1056bd:	89 d6                	mov    %edx,%esi
  1056bf:	89 44 24 08          	mov    %eax,0x8(%esp)
  1056c3:	f7 e7                	mul    %edi
  1056c5:	39 d6                	cmp    %edx,%esi
  1056c7:	72 2f                	jb     1056f8 <__udivdi3+0x138>
  1056c9:	8b 7c 24 04          	mov    0x4(%esp),%edi
  1056cd:	89 e9                	mov    %ebp,%ecx
  1056cf:	d3 e7                	shl    %cl,%edi
  1056d1:	39 c7                	cmp    %eax,%edi
  1056d3:	73 04                	jae    1056d9 <__udivdi3+0x119>
  1056d5:	39 d6                	cmp    %edx,%esi
  1056d7:	74 1f                	je     1056f8 <__udivdi3+0x138>
  1056d9:	8b 44 24 08          	mov    0x8(%esp),%eax
  1056dd:	31 d2                	xor    %edx,%edx
  1056df:	e9 26 ff ff ff       	jmp    10560a <__udivdi3+0x4a>
  1056e4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  1056e8:	b8 01 00 00 00       	mov    $0x1,%eax
  1056ed:	e9 18 ff ff ff       	jmp    10560a <__udivdi3+0x4a>
  1056f2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  1056f8:	8b 44 24 08          	mov    0x8(%esp),%eax
  1056fc:	31 d2                	xor    %edx,%edx
  1056fe:	83 e8 01             	sub    $0x1,%eax
  105701:	8b 74 24 10          	mov    0x10(%esp),%esi
  105705:	8b 7c 24 14          	mov    0x14(%esp),%edi
  105709:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  10570d:	83 c4 1c             	add    $0x1c,%esp
  105710:	c3                   	ret    
  105711:	90                   	nop
  105712:	90                   	nop
  105713:	90                   	nop
  105714:	90                   	nop
  105715:	90                   	nop
  105716:	90                   	nop
  105717:	90                   	nop
  105718:	90                   	nop
  105719:	90                   	nop
  10571a:	90                   	nop
  10571b:	90                   	nop
  10571c:	90                   	nop
  10571d:	90                   	nop
  10571e:	90                   	nop
  10571f:	90                   	nop

00105720 <__umoddi3>:
  105720:	83 ec 1c             	sub    $0x1c,%esp
  105723:	8b 54 24 2c          	mov    0x2c(%esp),%edx
  105727:	8b 44 24 20          	mov    0x20(%esp),%eax
  10572b:	89 74 24 10          	mov    %esi,0x10(%esp)
  10572f:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  105733:	8b 74 24 24          	mov    0x24(%esp),%esi
  105737:	85 d2                	test   %edx,%edx
  105739:	89 7c 24 14          	mov    %edi,0x14(%esp)
  10573d:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  105741:	89 cf                	mov    %ecx,%edi
  105743:	89 c5                	mov    %eax,%ebp
  105745:	89 44 24 08          	mov    %eax,0x8(%esp)
  105749:	89 34 24             	mov    %esi,(%esp)
  10574c:	75 22                	jne    105770 <__umoddi3+0x50>
  10574e:	39 f1                	cmp    %esi,%ecx
  105750:	76 56                	jbe    1057a8 <__umoddi3+0x88>
  105752:	89 f2                	mov    %esi,%edx
  105754:	f7 f1                	div    %ecx
  105756:	89 d0                	mov    %edx,%eax
  105758:	31 d2                	xor    %edx,%edx
  10575a:	8b 74 24 10          	mov    0x10(%esp),%esi
  10575e:	8b 7c 24 14          	mov    0x14(%esp),%edi
  105762:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  105766:	83 c4 1c             	add    $0x1c,%esp
  105769:	c3                   	ret    
  10576a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  105770:	39 f2                	cmp    %esi,%edx
  105772:	77 54                	ja     1057c8 <__umoddi3+0xa8>
  105774:	0f bd c2             	bsr    %edx,%eax
  105777:	83 f0 1f             	xor    $0x1f,%eax
  10577a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10577e:	75 60                	jne    1057e0 <__umoddi3+0xc0>
  105780:	39 e9                	cmp    %ebp,%ecx
  105782:	0f 87 08 01 00 00    	ja     105890 <__umoddi3+0x170>
  105788:	29 cd                	sub    %ecx,%ebp
  10578a:	19 d6                	sbb    %edx,%esi
  10578c:	89 34 24             	mov    %esi,(%esp)
  10578f:	8b 14 24             	mov    (%esp),%edx
  105792:	89 e8                	mov    %ebp,%eax
  105794:	8b 74 24 10          	mov    0x10(%esp),%esi
  105798:	8b 7c 24 14          	mov    0x14(%esp),%edi
  10579c:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  1057a0:	83 c4 1c             	add    $0x1c,%esp
  1057a3:	c3                   	ret    
  1057a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  1057a8:	85 c9                	test   %ecx,%ecx
  1057aa:	75 0b                	jne    1057b7 <__umoddi3+0x97>
  1057ac:	b8 01 00 00 00       	mov    $0x1,%eax
  1057b1:	31 d2                	xor    %edx,%edx
  1057b3:	f7 f1                	div    %ecx
  1057b5:	89 c1                	mov    %eax,%ecx
  1057b7:	89 f0                	mov    %esi,%eax
  1057b9:	31 d2                	xor    %edx,%edx
  1057bb:	f7 f1                	div    %ecx
  1057bd:	89 e8                	mov    %ebp,%eax
  1057bf:	f7 f1                	div    %ecx
  1057c1:	eb 93                	jmp    105756 <__umoddi3+0x36>
  1057c3:	90                   	nop
  1057c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  1057c8:	89 f2                	mov    %esi,%edx
  1057ca:	8b 74 24 10          	mov    0x10(%esp),%esi
  1057ce:	8b 7c 24 14          	mov    0x14(%esp),%edi
  1057d2:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  1057d6:	83 c4 1c             	add    $0x1c,%esp
  1057d9:	c3                   	ret    
  1057da:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  1057e0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  1057e5:	bd 20 00 00 00       	mov    $0x20,%ebp
  1057ea:	89 f8                	mov    %edi,%eax
  1057ec:	2b 6c 24 04          	sub    0x4(%esp),%ebp
  1057f0:	d3 e2                	shl    %cl,%edx
  1057f2:	89 e9                	mov    %ebp,%ecx
  1057f4:	d3 e8                	shr    %cl,%eax
  1057f6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  1057fb:	09 d0                	or     %edx,%eax
  1057fd:	89 f2                	mov    %esi,%edx
  1057ff:	89 04 24             	mov    %eax,(%esp)
  105802:	8b 44 24 08          	mov    0x8(%esp),%eax
  105806:	d3 e7                	shl    %cl,%edi
  105808:	89 e9                	mov    %ebp,%ecx
  10580a:	d3 ea                	shr    %cl,%edx
  10580c:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  105811:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  105815:	d3 e6                	shl    %cl,%esi
  105817:	89 e9                	mov    %ebp,%ecx
  105819:	d3 e8                	shr    %cl,%eax
  10581b:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  105820:	09 f0                	or     %esi,%eax
  105822:	8b 74 24 08          	mov    0x8(%esp),%esi
  105826:	f7 34 24             	divl   (%esp)
  105829:	d3 e6                	shl    %cl,%esi
  10582b:	89 74 24 08          	mov    %esi,0x8(%esp)
  10582f:	89 d6                	mov    %edx,%esi
  105831:	f7 e7                	mul    %edi
  105833:	39 d6                	cmp    %edx,%esi
  105835:	89 c7                	mov    %eax,%edi
  105837:	89 d1                	mov    %edx,%ecx
  105839:	72 41                	jb     10587c <__umoddi3+0x15c>
  10583b:	39 44 24 08          	cmp    %eax,0x8(%esp)
  10583f:	72 37                	jb     105878 <__umoddi3+0x158>
  105841:	8b 44 24 08          	mov    0x8(%esp),%eax
  105845:	29 f8                	sub    %edi,%eax
  105847:	19 ce                	sbb    %ecx,%esi
  105849:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  10584e:	89 f2                	mov    %esi,%edx
  105850:	d3 e8                	shr    %cl,%eax
  105852:	89 e9                	mov    %ebp,%ecx
  105854:	d3 e2                	shl    %cl,%edx
  105856:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  10585b:	09 d0                	or     %edx,%eax
  10585d:	89 f2                	mov    %esi,%edx
  10585f:	d3 ea                	shr    %cl,%edx
  105861:	8b 74 24 10          	mov    0x10(%esp),%esi
  105865:	8b 7c 24 14          	mov    0x14(%esp),%edi
  105869:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  10586d:	83 c4 1c             	add    $0x1c,%esp
  105870:	c3                   	ret    
  105871:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  105878:	39 d6                	cmp    %edx,%esi
  10587a:	75 c5                	jne    105841 <__umoddi3+0x121>
  10587c:	89 d1                	mov    %edx,%ecx
  10587e:	89 c7                	mov    %eax,%edi
  105880:	2b 7c 24 0c          	sub    0xc(%esp),%edi
  105884:	1b 0c 24             	sbb    (%esp),%ecx
  105887:	eb b8                	jmp    105841 <__umoddi3+0x121>
  105889:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  105890:	39 f2                	cmp    %esi,%edx
  105892:	0f 82 f0 fe ff ff    	jb     105788 <__umoddi3+0x68>
  105898:	e9 f2 fe ff ff       	jmp    10578f <__umoddi3+0x6f>
