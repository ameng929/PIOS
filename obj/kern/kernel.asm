
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
  10001a:	bc 00 a0 10 00       	mov    $0x10a000,%esp

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
  100055:	c7 44 24 0c e0 52 10 	movl   $0x1052e0,0xc(%esp)
  10005c:	00 
  10005d:	c7 44 24 08 f6 52 10 	movl   $0x1052f6,0x8(%esp)
  100064:	00 
  100065:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  10006c:	00 
  10006d:	c7 04 24 0b 53 10 00 	movl   $0x10530b,(%esp)
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
  10008d:	3d 00 90 10 00       	cmp    $0x109000,%eax
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
  1000aa:	ba 90 0a 31 00       	mov    $0x310a90,%edx
  1000af:	b8 fe a5 10 00       	mov    $0x10a5fe,%eax
  1000b4:	89 d1                	mov    %edx,%ecx
  1000b6:	29 c1                	sub    %eax,%ecx
  1000b8:	89 c8                	mov    %ecx,%eax
  1000ba:	89 44 24 08          	mov    %eax,0x8(%esp)
  1000be:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1000c5:	00 
  1000c6:	c7 04 24 fe a5 10 00 	movl   $0x10a5fe,(%esp)
  1000cd:	e8 17 4d 00 00       	call   104de9 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
  1000d2:	e8 f9 02 00 00       	call   1003d0 <cons_init>

	// Initialize and load the bootstrap CPU's GDT, TSS, and IDT.
	cpu_init();
  1000d7:	e8 f7 10 00 00       	call   1011d3 <cpu_init>
	trap_init();
  1000dc:	e8 e7 15 00 00       	call   1016c8 <trap_init>

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
  1000ef:	e8 0b 24 00 00       	call   1024ff <spinlock_check>

	// Find and start other processors in a multiprocessor system
	mp_init();		// Find info about processors in system
  1000f4:	e8 84 20 00 00       	call   10217d <mp_init>
	pic_init();		// setup the legacy PIC (mainly to disable it)
  1000f9:	e8 de 3b 00 00       	call   103cdc <pic_init>
	ioapic_init();		// prepare to handle external device interrupts
  1000fe:	e8 22 42 00 00       	call   104325 <ioapic_init>
	lapic_init();		// setup this CPU's local APIC
  100103:	e8 cb 3e 00 00       	call   103fd3 <lapic_init>
	cpu_bootothers();	// Get other processors started
  100108:	e8 a3 12 00 00       	call   1013b0 <cpu_bootothers>
	cprintf("CPU %d (%s) has booted\n", cpu_cur()->id, cpu_onboot() ? "BP" : "AP");
  10010d:	e8 70 ff ff ff       	call   100082 <cpu_onboot>
  100112:	85 c0                	test   %eax,%eax
  100114:	74 07                	je     10011d <init+0x83>
  100116:	bb 18 53 10 00       	mov    $0x105318,%ebx
  10011b:	eb 05                	jmp    100122 <init+0x88>
  10011d:	bb 1b 53 10 00       	mov    $0x10531b,%ebx
  100122:	e8 01 ff ff ff       	call   100028 <cpu_cur>
  100127:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  10012e:	0f b6 c0             	movzbl %al,%eax
  100131:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  100135:	89 44 24 04          	mov    %eax,0x4(%esp)
  100139:	c7 04 24 1e 53 10 00 	movl   $0x10531e,(%esp)
  100140:	e8 bf 4a 00 00       	call   104c04 <cprintf>

	// Initialize the process management code.
	proc_init();
  100145:	e8 31 29 00 00       	call   102a7b <proc_init>
	//if(!cpu_onboot())
	//	proc_sched();

	proc *user_proc;

	if(cpu_onboot()) {
  10014a:	e8 33 ff ff ff       	call   100082 <cpu_onboot>
  10014f:	85 c0                	test   %eax,%eax
  100151:	0f 84 93 00 00 00    	je     1001ea <init+0x150>

		user_proc = proc_alloc(NULL,0);
  100157:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10015e:	00 
  10015f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  100166:	e8 4a 29 00 00       	call   102ab5 <proc_alloc>
  10016b:	89 45 f4             	mov    %eax,-0xc(%ebp)
		user_proc->sv.tf.esp = (uint32_t)&user_stack[PAGESIZE];
  10016e:	ba 00 b6 10 00       	mov    $0x10b600,%edx
  100173:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100176:	89 90 94 04 00 00    	mov    %edx,0x494(%eax)
		user_proc->sv.tf.eip =  (uint32_t)user;
  10017c:	ba ef 01 10 00       	mov    $0x1001ef,%edx
  100181:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100184:	89 90 88 04 00 00    	mov    %edx,0x488(%eax)
		user_proc->sv.tf.eflags = FL_IF;
  10018a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10018d:	c7 80 90 04 00 00 00 	movl   $0x200,0x490(%eax)
  100194:	02 00 00 
		user_proc->sv.tf.gs = CPU_GDT_UDATA | 3;
  100197:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10019a:	66 c7 80 70 04 00 00 	movw   $0x23,0x470(%eax)
  1001a1:	23 00 
		user_proc->sv.tf.fs = CPU_GDT_UDATA | 3;
  1001a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1001a6:	66 c7 80 74 04 00 00 	movw   $0x23,0x474(%eax)
  1001ad:	23 00 
		user_proc->sv.tf.es = CPU_GDT_UDATA | 3;
  1001af:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1001b2:	66 c7 80 78 04 00 00 	movw   $0x23,0x478(%eax)
  1001b9:	23 00 
		user_proc->sv.tf.ds = CPU_GDT_UDATA | 3;
  1001bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1001be:	66 c7 80 7c 04 00 00 	movw   $0x23,0x47c(%eax)
  1001c5:	23 00 
		user_proc->sv.tf.cs = CPU_GDT_UCODE | 3;
  1001c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1001ca:	66 c7 80 8c 04 00 00 	movw   $0x1b,0x48c(%eax)
  1001d1:	1b 00 
		user_proc->sv.tf.ss = CPU_GDT_UDATA | 3;
  1001d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1001d6:	66 c7 80 98 04 00 00 	movw   $0x23,0x498(%eax)
  1001dd:	23 00 
		proc_ready(user_proc);
  1001df:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1001e2:	89 04 24             	mov    %eax,(%esp)
  1001e5:	e8 4b 2a 00 00       	call   102c35 <proc_ready>
	}
	proc_sched();
  1001ea:	e8 63 2b 00 00       	call   102d52 <proc_sched>

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
  1001f6:	c7 04 24 36 53 10 00 	movl   $0x105336,(%esp)
  1001fd:	e8 02 4a 00 00       	call   104c04 <cprintf>

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
  10020c:	b8 00 a6 10 00       	mov    $0x10a600,%eax
  100211:	39 c2                	cmp    %eax,%edx
  100213:	77 24                	ja     100239 <user+0x4a>
  100215:	c7 44 24 0c 44 53 10 	movl   $0x105344,0xc(%esp)
  10021c:	00 
  10021d:	c7 44 24 08 f6 52 10 	movl   $0x1052f6,0x8(%esp)
  100224:	00 
  100225:	c7 44 24 04 8a 00 00 	movl   $0x8a,0x4(%esp)
  10022c:	00 
  10022d:	c7 04 24 6b 53 10 00 	movl   $0x10536b,(%esp)
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
  100243:	b8 00 b6 10 00       	mov    $0x10b600,%eax
  100248:	39 c2                	cmp    %eax,%edx
  10024a:	72 24                	jb     100270 <user+0x81>
  10024c:	c7 44 24 0c 78 53 10 	movl   $0x105378,0xc(%esp)
  100253:	00 
  100254:	c7 44 24 08 f6 52 10 	movl   $0x1052f6,0x8(%esp)
  10025b:	00 
  10025c:	c7 44 24 04 8b 00 00 	movl   $0x8b,0x4(%esp)
  100263:	00 
  100264:	c7 04 24 6b 53 10 00 	movl   $0x10536b,(%esp)
  10026b:	e8 54 02 00 00       	call   1004c4 <debug_panic>

	// Check the system call and process scheduling code.
	proc_check();
  100270:	e8 a3 2c 00 00       	call   102f18 <proc_check>

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
  1002ad:	c7 44 24 0c b0 53 10 	movl   $0x1053b0,0xc(%esp)
  1002b4:	00 
  1002b5:	c7 44 24 08 c6 53 10 	movl   $0x1053c6,0x8(%esp)
  1002bc:	00 
  1002bd:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1002c4:	00 
  1002c5:	c7 04 24 db 53 10 00 	movl   $0x1053db,(%esp)
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
  1002e5:	3d 00 90 10 00       	cmp    $0x109000,%eax
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
  1002f8:	c7 04 24 a0 02 11 00 	movl   $0x1102a0,(%esp)
  1002ff:	e8 b8 20 00 00       	call   1023bc <spinlock_acquire>
	while ((c = (*proc)()) != -1) {
  100304:	eb 35                	jmp    10033b <cons_intr+0x49>
		if (c == 0)
  100306:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  10030a:	74 2e                	je     10033a <cons_intr+0x48>
			continue;
		cons.buf[cons.wpos++] = c;
  10030c:	a1 04 b8 10 00       	mov    0x10b804,%eax
  100311:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100314:	88 90 00 b6 10 00    	mov    %dl,0x10b600(%eax)
  10031a:	83 c0 01             	add    $0x1,%eax
  10031d:	a3 04 b8 10 00       	mov    %eax,0x10b804
		if (cons.wpos == CONSBUFSIZE)
  100322:	a1 04 b8 10 00       	mov    0x10b804,%eax
  100327:	3d 00 02 00 00       	cmp    $0x200,%eax
  10032c:	75 0d                	jne    10033b <cons_intr+0x49>
			cons.wpos = 0;
  10032e:	c7 05 04 b8 10 00 00 	movl   $0x0,0x10b804
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
  100349:	c7 04 24 a0 02 11 00 	movl   $0x1102a0,(%esp)
  100350:	e8 e3 20 00 00       	call   102438 <spinlock_release>

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
  10035d:	e8 08 38 00 00       	call   103b6a <serial_intr>
	kbd_intr();
  100362:	e8 2f 37 00 00       	call   103a96 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
  100367:	8b 15 00 b8 10 00    	mov    0x10b800,%edx
  10036d:	a1 04 b8 10 00       	mov    0x10b804,%eax
  100372:	39 c2                	cmp    %eax,%edx
  100374:	74 35                	je     1003ab <cons_getc+0x54>
		c = cons.buf[cons.rpos++];
  100376:	a1 00 b8 10 00       	mov    0x10b800,%eax
  10037b:	0f b6 90 00 b6 10 00 	movzbl 0x10b600(%eax),%edx
  100382:	0f b6 d2             	movzbl %dl,%edx
  100385:	89 55 f4             	mov    %edx,-0xc(%ebp)
  100388:	83 c0 01             	add    $0x1,%eax
  10038b:	a3 00 b8 10 00       	mov    %eax,0x10b800
		if (cons.rpos == CONSBUFSIZE)
  100390:	a1 00 b8 10 00       	mov    0x10b800,%eax
  100395:	3d 00 02 00 00       	cmp    $0x200,%eax
  10039a:	75 0a                	jne    1003a6 <cons_getc+0x4f>
			cons.rpos = 0;
  10039c:	c7 05 00 b8 10 00 00 	movl   $0x0,0x10b800
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
  1003be:	e8 c4 37 00 00       	call   103b87 <serial_putc>
	video_putc(c);
  1003c3:	8b 45 08             	mov    0x8(%ebp),%eax
  1003c6:	89 04 24             	mov    %eax,(%esp)
  1003c9:	e8 1b 33 00 00       	call   1036e9 <video_putc>
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
  1003e7:	c7 44 24 04 e8 53 10 	movl   $0x1053e8,0x4(%esp)
  1003ee:	00 
  1003ef:	c7 04 24 a0 02 11 00 	movl   $0x1102a0,(%esp)
  1003f6:	e8 97 1f 00 00       	call   102392 <spinlock_init_>
	video_init();
  1003fb:	e8 0c 32 00 00       	call   10360c <video_init>
	kbd_init();
  100400:	e8 a5 36 00 00       	call   103aaa <kbd_init>
	serial_init();
  100405:	e8 ed 37 00 00       	call   103bf7 <serial_init>

	if (!serial_exists)
  10040a:	a1 88 0a 31 00       	mov    0x310a88,%eax
  10040f:	85 c0                	test   %eax,%eax
  100411:	75 1f                	jne    100432 <cons_init+0x62>
		warn("Serial port does not exist!\n");
  100413:	c7 44 24 08 f4 53 10 	movl   $0x1053f4,0x8(%esp)
  10041a:	00 
  10041b:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
  100422:	00 
  100423:	c7 04 24 e8 53 10 00 	movl   $0x1053e8,(%esp)
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
  100464:	c7 04 24 a0 02 11 00 	movl   $0x1102a0,(%esp)
  10046b:	e8 22 20 00 00       	call   102492 <spinlock_holding>
  100470:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (!already)
  100473:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  100477:	75 25                	jne    10049e <cputs+0x6a>
		spinlock_acquire(&cons_lock);
  100479:	c7 04 24 a0 02 11 00 	movl   $0x1102a0,(%esp)
  100480:	e8 37 1f 00 00       	call   1023bc <spinlock_acquire>

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
  1004af:	c7 04 24 a0 02 11 00 	movl   $0x1102a0,(%esp)
  1004b6:	e8 7d 1f 00 00       	call   102438 <spinlock_release>
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
  1004e0:	a1 08 b8 10 00       	mov    0x10b808,%eax
  1004e5:	85 c0                	test   %eax,%eax
  1004e7:	0f 85 97 00 00 00    	jne    100584 <debug_panic+0xc0>
			goto dead;
		panicstr = fmt;
  1004ed:	8b 45 10             	mov    0x10(%ebp),%eax
  1004f0:	a3 08 b8 10 00       	mov    %eax,0x10b808
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
  10050c:	c7 04 24 11 54 10 00 	movl   $0x105411,(%esp)
  100513:	e8 ec 46 00 00       	call   104c04 <cprintf>
	vcprintf(fmt, ap);
  100518:	8b 45 10             	mov    0x10(%ebp),%eax
  10051b:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10051e:	89 54 24 04          	mov    %edx,0x4(%esp)
  100522:	89 04 24             	mov    %eax,(%esp)
  100525:	e8 72 46 00 00       	call   104b9c <vcprintf>
	cprintf("\n");
  10052a:	c7 04 24 29 54 10 00 	movl   $0x105429,(%esp)
  100531:	e8 ce 46 00 00       	call   104c04 <cprintf>

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
  100561:	c7 04 24 2b 54 10 00 	movl   $0x10542b,(%esp)
  100568:	e8 97 46 00 00       	call   104c04 <cprintf>
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
  1005a7:	c7 04 24 38 54 10 00 	movl   $0x105438,(%esp)
  1005ae:	e8 51 46 00 00       	call   104c04 <cprintf>
	vcprintf(fmt, ap);
  1005b3:	8b 45 10             	mov    0x10(%ebp),%eax
  1005b6:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1005b9:	89 54 24 04          	mov    %edx,0x4(%esp)
  1005bd:	89 04 24             	mov    %eax,(%esp)
  1005c0:	e8 d7 45 00 00       	call   104b9c <vcprintf>
	cprintf("\n");
  1005c5:	c7 04 24 29 54 10 00 	movl   $0x105429,(%esp)
  1005cc:	e8 33 46 00 00       	call   104c04 <cprintf>
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
  100750:	c7 44 24 0c 52 54 10 	movl   $0x105452,0xc(%esp)
  100757:	00 
  100758:	c7 44 24 08 6f 54 10 	movl   $0x10546f,0x8(%esp)
  10075f:	00 
  100760:	c7 44 24 04 75 00 00 	movl   $0x75,0x4(%esp)
  100767:	00 
  100768:	c7 04 24 84 54 10 00 	movl   $0x105484,(%esp)
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
  1007a0:	c7 44 24 0c 91 54 10 	movl   $0x105491,0xc(%esp)
  1007a7:	00 
  1007a8:	c7 44 24 08 6f 54 10 	movl   $0x10546f,0x8(%esp)
  1007af:	00 
  1007b0:	c7 44 24 04 77 00 00 	movl   $0x77,0x4(%esp)
  1007b7:	00 
  1007b8:	c7 04 24 84 54 10 00 	movl   $0x105484,(%esp)
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
  1007f0:	c7 44 24 0c aa 54 10 	movl   $0x1054aa,0xc(%esp)
  1007f7:	00 
  1007f8:	c7 44 24 08 6f 54 10 	movl   $0x10546f,0x8(%esp)
  1007ff:	00 
  100800:	c7 44 24 04 79 00 00 	movl   $0x79,0x4(%esp)
  100807:	00 
  100808:	c7 04 24 84 54 10 00 	movl   $0x105484,(%esp)
  10080f:	e8 b0 fc ff ff       	call   1004c4 <debug_panic>
	assert(eips[2][0] == eips[3][0]);
  100814:	8b 55 a0             	mov    -0x60(%ebp),%edx
  100817:	8b 45 c8             	mov    -0x38(%ebp),%eax
  10081a:	39 c2                	cmp    %eax,%edx
  10081c:	74 24                	je     100842 <debug_check+0x174>
  10081e:	c7 44 24 0c c3 54 10 	movl   $0x1054c3,0xc(%esp)
  100825:	00 
  100826:	c7 44 24 08 6f 54 10 	movl   $0x10546f,0x8(%esp)
  10082d:	00 
  10082e:	c7 44 24 04 7a 00 00 	movl   $0x7a,0x4(%esp)
  100835:	00 
  100836:	c7 04 24 84 54 10 00 	movl   $0x105484,(%esp)
  10083d:	e8 82 fc ff ff       	call   1004c4 <debug_panic>
	assert(eips[1][0] != eips[2][0]);
  100842:	8b 95 78 ff ff ff    	mov    -0x88(%ebp),%edx
  100848:	8b 45 a0             	mov    -0x60(%ebp),%eax
  10084b:	39 c2                	cmp    %eax,%edx
  10084d:	75 24                	jne    100873 <debug_check+0x1a5>
  10084f:	c7 44 24 0c dc 54 10 	movl   $0x1054dc,0xc(%esp)
  100856:	00 
  100857:	c7 44 24 08 6f 54 10 	movl   $0x10546f,0x8(%esp)
  10085e:	00 
  10085f:	c7 44 24 04 7b 00 00 	movl   $0x7b,0x4(%esp)
  100866:	00 
  100867:	c7 04 24 84 54 10 00 	movl   $0x105484,(%esp)
  10086e:	e8 51 fc ff ff       	call   1004c4 <debug_panic>
	assert(eips[0][1] == eips[2][1]);
  100873:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  100879:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  10087c:	39 c2                	cmp    %eax,%edx
  10087e:	74 24                	je     1008a4 <debug_check+0x1d6>
  100880:	c7 44 24 0c f5 54 10 	movl   $0x1054f5,0xc(%esp)
  100887:	00 
  100888:	c7 44 24 08 6f 54 10 	movl   $0x10546f,0x8(%esp)
  10088f:	00 
  100890:	c7 44 24 04 7c 00 00 	movl   $0x7c,0x4(%esp)
  100897:	00 
  100898:	c7 04 24 84 54 10 00 	movl   $0x105484,(%esp)
  10089f:	e8 20 fc ff ff       	call   1004c4 <debug_panic>
	assert(eips[1][1] == eips[3][1]);
  1008a4:	8b 95 7c ff ff ff    	mov    -0x84(%ebp),%edx
  1008aa:	8b 45 cc             	mov    -0x34(%ebp),%eax
  1008ad:	39 c2                	cmp    %eax,%edx
  1008af:	74 24                	je     1008d5 <debug_check+0x207>
  1008b1:	c7 44 24 0c 0e 55 10 	movl   $0x10550e,0xc(%esp)
  1008b8:	00 
  1008b9:	c7 44 24 08 6f 54 10 	movl   $0x10546f,0x8(%esp)
  1008c0:	00 
  1008c1:	c7 44 24 04 7d 00 00 	movl   $0x7d,0x4(%esp)
  1008c8:	00 
  1008c9:	c7 04 24 84 54 10 00 	movl   $0x105484,(%esp)
  1008d0:	e8 ef fb ff ff       	call   1004c4 <debug_panic>
	assert(eips[0][1] != eips[1][1]);
  1008d5:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  1008db:	8b 85 7c ff ff ff    	mov    -0x84(%ebp),%eax
  1008e1:	39 c2                	cmp    %eax,%edx
  1008e3:	75 24                	jne    100909 <debug_check+0x23b>
  1008e5:	c7 44 24 0c 27 55 10 	movl   $0x105527,0xc(%esp)
  1008ec:	00 
  1008ed:	c7 44 24 08 6f 54 10 	movl   $0x10546f,0x8(%esp)
  1008f4:	00 
  1008f5:	c7 44 24 04 7e 00 00 	movl   $0x7e,0x4(%esp)
  1008fc:	00 
  1008fd:	c7 04 24 84 54 10 00 	movl   $0x105484,(%esp)
  100904:	e8 bb fb ff ff       	call   1004c4 <debug_panic>

	cprintf("debug_check() succeeded!\n");
  100909:	c7 04 24 40 55 10 00 	movl   $0x105540,(%esp)
  100910:	e8 ef 42 00 00       	call   104c04 <cprintf>
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
  100945:	c7 44 24 0c 5c 55 10 	movl   $0x10555c,0xc(%esp)
  10094c:	00 
  10094d:	c7 44 24 08 72 55 10 	movl   $0x105572,0x8(%esp)
  100954:	00 
  100955:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  10095c:	00 
  10095d:	c7 04 24 87 55 10 00 	movl   $0x105587,(%esp)
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
  10097d:	3d 00 90 10 00       	cmp    $0x109000,%eax
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
  1009a0:	c7 04 24 94 55 10 00 	movl   $0x105594,(%esp)
  1009a7:	e8 58 42 00 00       	call   104c04 <cprintf>
	cprintf("edata : 0x%x\n",edata);
  1009ac:	c7 44 24 04 fe a5 10 	movl   $0x10a5fe,0x4(%esp)
  1009b3:	00 
  1009b4:	c7 04 24 a8 55 10 00 	movl   $0x1055a8,(%esp)
  1009bb:	e8 44 42 00 00       	call   104c04 <cprintf>
	cprintf("end : 0x%x, 0x%x\n",end, &end[0]);
  1009c0:	c7 44 24 08 90 0a 31 	movl   $0x310a90,0x8(%esp)
  1009c7:	00 
  1009c8:	c7 44 24 04 90 0a 31 	movl   $0x310a90,0x4(%esp)
  1009cf:	00 
  1009d0:	c7 04 24 b6 55 10 00 	movl   $0x1055b6,(%esp)
  1009d7:	e8 28 42 00 00       	call   104c04 <cprintf>
	cprintf("&mem_pageinfo : 0x%x\n",&mem_pageinfo);
  1009dc:	c7 44 24 04 84 03 31 	movl   $0x310384,0x4(%esp)
  1009e3:	00 
  1009e4:	c7 04 24 c8 55 10 00 	movl   $0x1055c8,(%esp)
  1009eb:	e8 14 42 00 00       	call   104c04 <cprintf>
	cprintf("&mem_freelist : 0x%x\n",&mem_freelist);
  1009f0:	c7 44 24 04 e0 02 11 	movl   $0x1102e0,0x4(%esp)
  1009f7:	00 
  1009f8:	c7 04 24 de 55 10 00 	movl   $0x1055de,(%esp)
  1009ff:	e8 00 42 00 00       	call   104c04 <cprintf>
	cprintf("&tmp_paginfo : 0x%x\n",&tmp_mem_pageinfo);
  100a04:	c7 44 24 04 80 03 11 	movl   $0x110380,0x4(%esp)
  100a0b:	00 
  100a0c:	c7 04 24 f4 55 10 00 	movl   $0x1055f4,(%esp)
  100a13:	e8 ec 41 00 00       	call   104c04 <cprintf>
	if (!cpu_onboot())	// only do once, on the boot CPU
  100a18:	e8 55 ff ff ff       	call   100972 <cpu_onboot>
  100a1d:	85 c0                	test   %eax,%eax
  100a1f:	0f 84 c2 01 00 00    	je     100be7 <mem_init+0x25d>
	// is available in the system (in bytes),
	// by reading the PC's BIOS-managed nonvolatile RAM (NVRAM).
	// The NVRAM tells us how many kilobytes there are.
	// Since the count is 16 bits, this gives us up to 64MB of RAM;
	// additional RAM beyond that would have to be detected another way.
	size_t basemem = ROUNDDOWN(nvram_read16(NVRAM_BASELO)*1024, PAGESIZE);
  100a25:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
  100a2c:	e8 c1 34 00 00       	call   103ef2 <nvram_read16>
  100a31:	c1 e0 0a             	shl    $0xa,%eax
  100a34:	89 45 ec             	mov    %eax,-0x14(%ebp)
  100a37:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100a3a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100a3f:	89 45 e8             	mov    %eax,-0x18(%ebp)
	size_t extmem = ROUNDDOWN(nvram_read16(NVRAM_EXTLO)*1024, PAGESIZE);
  100a42:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
  100a49:	e8 a4 34 00 00       	call   103ef2 <nvram_read16>
  100a4e:	c1 e0 0a             	shl    $0xa,%eax
  100a51:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100a54:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100a57:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100a5c:	89 45 e0             	mov    %eax,-0x20(%ebp)
	cprintf("basemem : 0x%x\n", basemem);  // ->0xa0000 = 640K
  100a5f:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100a62:	89 44 24 04          	mov    %eax,0x4(%esp)
  100a66:	c7 04 24 09 56 10 00 	movl   $0x105609,(%esp)
  100a6d:	e8 92 41 00 00       	call   104c04 <cprintf>
	cprintf("extmem : 0x%x\n", extmem);		// ->0xff000
  100a72:	8b 45 e0             	mov    -0x20(%ebp),%eax
  100a75:	89 44 24 04          	mov    %eax,0x4(%esp)
  100a79:	c7 04 24 19 56 10 00 	movl   $0x105619,(%esp)
  100a80:	e8 7f 41 00 00       	call   104c04 <cprintf>
	warn("Assuming we have 1GB of memory!");
  100a85:	c7 44 24 08 28 56 10 	movl   $0x105628,0x8(%esp)
  100a8c:	00 
  100a8d:	c7 44 24 04 3c 00 00 	movl   $0x3c,0x4(%esp)
  100a94:	00 
  100a95:	c7 04 24 48 56 10 00 	movl   $0x105648,(%esp)
  100a9c:	e8 e9 fa ff ff       	call   10058a <debug_warn>
	extmem = 1024*1024*1024 - MEM_EXT;	// assume 1GB total memory
  100aa1:	c7 45 e0 00 00 f0 3f 	movl   $0x3ff00000,-0x20(%ebp)

	// The maximum physical address is the top of extended memory.
	mem_max = MEM_EXT + extmem;
  100aa8:	8b 45 e0             	mov    -0x20(%ebp),%eax
  100aab:	05 00 00 10 00       	add    $0x100000,%eax
  100ab0:	a3 80 03 31 00       	mov    %eax,0x310380

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;
  100ab5:	a1 80 03 31 00       	mov    0x310380,%eax
  100aba:	c1 e8 0c             	shr    $0xc,%eax
  100abd:	a3 38 03 11 00       	mov    %eax,0x110338

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
  100ac2:	a1 80 03 31 00       	mov    0x310380,%eax
  100ac7:	c1 e8 0a             	shr    $0xa,%eax
  100aca:	89 44 24 04          	mov    %eax,0x4(%esp)
  100ace:	c7 04 24 54 56 10 00 	movl   $0x105654,(%esp)
  100ad5:	e8 2a 41 00 00       	call   104c04 <cprintf>
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
  100af0:	c7 04 24 75 56 10 00 	movl   $0x105675,(%esp)
  100af7:	e8 08 41 00 00       	call   104c04 <cprintf>
	//     but YOU decide where to place the pageinfo array.
	// Change the code to reflect this.
	//pageinfo *mem_pageinfo;
	//memset(mem_pageinfo, 0, sizeof(pageinfo)*mem_npage);

	pageinfo **freetail = &mem_freelist;
  100afc:	c7 45 f4 e0 02 11 00 	movl   $0x1102e0,-0xc(%ebp)
	int i;
	uint32_t page_start;
	mem_pageinfo = tmp_mem_pageinfo;
  100b03:	c7 05 84 03 31 00 80 	movl   $0x110380,0x310384
  100b0a:	03 11 00 
	memset(tmp_mem_pageinfo, 0, sizeof(pageinfo)*1024*1024*1024/PAGESIZE);
  100b0d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  100b14:	00 
  100b15:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  100b1c:	00 
  100b1d:	c7 04 24 80 03 11 00 	movl   $0x110380,(%esp)
  100b24:	e8 c0 42 00 00       	call   104de9 <memset>
	for (i = 0; i < mem_npage; i++) {
  100b29:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  100b30:	e9 92 00 00 00       	jmp    100bc7 <mem_init+0x23d>
		// A free page has no references to it.
		mem_pageinfo[i].refcount = 0;
  100b35:	a1 84 03 31 00       	mov    0x310384,%eax
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
  100b8e:	b8 90 0a 31 00       	mov    $0x310a90,%eax
  100b93:	39 45 dc             	cmp    %eax,-0x24(%ebp)
  100b96:	72 2a                	jb     100bc2 <mem_init+0x238>
			continue;

		// Add the page to the end of the free list.
		*freetail = &mem_pageinfo[i];
  100b98:	a1 84 03 31 00       	mov    0x310384,%eax
  100b9d:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100ba0:	c1 e2 03             	shl    $0x3,%edx
  100ba3:	01 c2                	add    %eax,%edx
  100ba5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100ba8:	89 10                	mov    %edx,(%eax)
		freetail = &mem_pageinfo[i].free_next;
  100baa:	a1 84 03 31 00       	mov    0x310384,%eax
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
  100bca:	a1 38 03 11 00       	mov    0x110338,%eax
  100bcf:	39 c2                	cmp    %eax,%edx
  100bd1:	0f 82 5e ff ff ff    	jb     100b35 <mem_init+0x1ab>

		// Add the page to the end of the free list.
		*freetail = &mem_pageinfo[i];
		freetail = &mem_pageinfo[i].free_next;
	}
	*freetail = NULL;	// null-terminate the freelist
  100bd7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100bda:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	// ...and remove this when you're ready.
	//panic("mem_init() not implemented");

	// Check to make sure the page allocator seems to work correctly.
	mem_check();
  100be0:	e8 7f 00 00 00       	call   100c64 <mem_check>
  100be5:	eb 01                	jmp    100be8 <mem_init+0x25e>
	cprintf("end : 0x%x, 0x%x\n",end, &end[0]);
	cprintf("&mem_pageinfo : 0x%x\n",&mem_pageinfo);
	cprintf("&mem_freelist : 0x%x\n",&mem_freelist);
	cprintf("&tmp_paginfo : 0x%x\n",&tmp_mem_pageinfo);
	if (!cpu_onboot())	// only do once, on the boot CPU
		return;
  100be7:	90                   	nop
	// ...and remove this when you're ready.
	//panic("mem_init() not implemented");

	// Check to make sure the page allocator seems to work correctly.
	mem_check();
}
  100be8:	c9                   	leave  
  100be9:	c3                   	ret    

00100bea <mem_alloc>:
//
// Hint: pi->refs should not be incremented 
// Hint: be sure to use proper mutual exclusion for multiprocessor operation.
pageinfo *
mem_alloc(void)
{
  100bea:	55                   	push   %ebp
  100beb:	89 e5                	mov    %esp,%ebp
  100bed:	83 ec 28             	sub    $0x28,%esp
	// Fill this function in
	// Fill this function in.
	//panic("mem_alloc not implemented.");
	if(!spinlock_holding(&_freelist_lock));
  100bf0:	c7 04 24 40 03 11 00 	movl   $0x110340,(%esp)
  100bf7:	e8 96 18 00 00       	call   102492 <spinlock_holding>
	spinlock_acquire(&_freelist_lock);
  100bfc:	c7 04 24 40 03 11 00 	movl   $0x110340,(%esp)
  100c03:	e8 b4 17 00 00       	call   1023bc <spinlock_acquire>
	pageinfo *p = mem_freelist;
  100c08:	a1 e0 02 11 00       	mov    0x1102e0,%eax
  100c0d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if(p != NULL)
  100c10:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  100c14:	74 0a                	je     100c20 <mem_alloc+0x36>
		mem_freelist = p->free_next;
  100c16:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100c19:	8b 00                	mov    (%eax),%eax
  100c1b:	a3 e0 02 11 00       	mov    %eax,0x1102e0
	spinlock_release(&_freelist_lock);
  100c20:	c7 04 24 40 03 11 00 	movl   $0x110340,(%esp)
  100c27:	e8 0c 18 00 00       	call   102438 <spinlock_release>
	return p;
  100c2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  100c2f:	c9                   	leave  
  100c30:	c3                   	ret    

00100c31 <mem_free>:
// Return a page to the free list, given its pageinfo pointer.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
mem_free(pageinfo *pi)
{
  100c31:	55                   	push   %ebp
  100c32:	89 e5                	mov    %esp,%ebp
  100c34:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in.
	//panic("mem_free not implemented.");
	spinlock_acquire(&_freelist_lock);
  100c37:	c7 04 24 40 03 11 00 	movl   $0x110340,(%esp)
  100c3e:	e8 79 17 00 00       	call   1023bc <spinlock_acquire>
	//assert(pi->refcount == 0);
	pi->free_next = mem_freelist;
  100c43:	8b 15 e0 02 11 00    	mov    0x1102e0,%edx
  100c49:	8b 45 08             	mov    0x8(%ebp),%eax
  100c4c:	89 10                	mov    %edx,(%eax)
	mem_freelist = pi;
  100c4e:	8b 45 08             	mov    0x8(%ebp),%eax
  100c51:	a3 e0 02 11 00       	mov    %eax,0x1102e0
	spinlock_release(&_freelist_lock);
  100c56:	c7 04 24 40 03 11 00 	movl   $0x110340,(%esp)
  100c5d:	e8 d6 17 00 00       	call   102438 <spinlock_release>
}
  100c62:	c9                   	leave  
  100c63:	c3                   	ret    

00100c64 <mem_check>:
// Check the physical page allocator (mem_alloc(), mem_free())
// for correct operation after initialization via mem_init().
//
void
mem_check()
{
  100c64:	55                   	push   %ebp
  100c65:	89 e5                	mov    %esp,%ebp
  100c67:	83 ec 38             	sub    $0x38,%esp
	int i;

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
  100c6a:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
  100c71:	a1 e0 02 11 00       	mov    0x1102e0,%eax
  100c76:	89 45 f4             	mov    %eax,-0xc(%ebp)
  100c79:	eb 38                	jmp    100cb3 <mem_check+0x4f>
		memset(mem_pi2ptr(pp), 0x97, 128);
  100c7b:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100c7e:	a1 84 03 31 00       	mov    0x310384,%eax
  100c83:	89 d1                	mov    %edx,%ecx
  100c85:	29 c1                	sub    %eax,%ecx
  100c87:	89 c8                	mov    %ecx,%eax
  100c89:	c1 f8 03             	sar    $0x3,%eax
  100c8c:	c1 e0 0c             	shl    $0xc,%eax
  100c8f:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
  100c96:	00 
  100c97:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
  100c9e:	00 
  100c9f:	89 04 24             	mov    %eax,(%esp)
  100ca2:	e8 42 41 00 00       	call   104de9 <memset>
		freepages++;
  100ca7:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
  100cab:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100cae:	8b 00                	mov    (%eax),%eax
  100cb0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  100cb3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  100cb7:	75 c2                	jne    100c7b <mem_check+0x17>
		memset(mem_pi2ptr(pp), 0x97, 128);
		freepages++;
	}
	cprintf("mem_check: %d free pages\n", freepages);
  100cb9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100cbc:	89 44 24 04          	mov    %eax,0x4(%esp)
  100cc0:	c7 04 24 91 56 10 00 	movl   $0x105691,(%esp)
  100cc7:	e8 38 3f 00 00       	call   104c04 <cprintf>
	assert(freepages < mem_npage);	// can't have more free than total!
  100ccc:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100ccf:	a1 38 03 11 00       	mov    0x110338,%eax
  100cd4:	39 c2                	cmp    %eax,%edx
  100cd6:	72 24                	jb     100cfc <mem_check+0x98>
  100cd8:	c7 44 24 0c ab 56 10 	movl   $0x1056ab,0xc(%esp)
  100cdf:	00 
  100ce0:	c7 44 24 08 72 55 10 	movl   $0x105572,0x8(%esp)
  100ce7:	00 
  100ce8:	c7 44 24 04 c4 00 00 	movl   $0xc4,0x4(%esp)
  100cef:	00 
  100cf0:	c7 04 24 48 56 10 00 	movl   $0x105648,(%esp)
  100cf7:	e8 c8 f7 ff ff       	call   1004c4 <debug_panic>
	assert(freepages > 16000);	// make sure it's in the right ballpark
  100cfc:	81 7d f0 80 3e 00 00 	cmpl   $0x3e80,-0x10(%ebp)
  100d03:	7f 24                	jg     100d29 <mem_check+0xc5>
  100d05:	c7 44 24 0c c1 56 10 	movl   $0x1056c1,0xc(%esp)
  100d0c:	00 
  100d0d:	c7 44 24 08 72 55 10 	movl   $0x105572,0x8(%esp)
  100d14:	00 
  100d15:	c7 44 24 04 c5 00 00 	movl   $0xc5,0x4(%esp)
  100d1c:	00 
  100d1d:	c7 04 24 48 56 10 00 	movl   $0x105648,(%esp)
  100d24:	e8 9b f7 ff ff       	call   1004c4 <debug_panic>

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
  100d29:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  100d30:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100d33:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100d36:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100d39:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  100d3c:	e8 a9 fe ff ff       	call   100bea <mem_alloc>
  100d41:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100d44:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100d48:	75 24                	jne    100d6e <mem_check+0x10a>
  100d4a:	c7 44 24 0c d3 56 10 	movl   $0x1056d3,0xc(%esp)
  100d51:	00 
  100d52:	c7 44 24 08 72 55 10 	movl   $0x105572,0x8(%esp)
  100d59:	00 
  100d5a:	c7 44 24 04 c9 00 00 	movl   $0xc9,0x4(%esp)
  100d61:	00 
  100d62:	c7 04 24 48 56 10 00 	movl   $0x105648,(%esp)
  100d69:	e8 56 f7 ff ff       	call   1004c4 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100d6e:	e8 77 fe ff ff       	call   100bea <mem_alloc>
  100d73:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100d76:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100d7a:	75 24                	jne    100da0 <mem_check+0x13c>
  100d7c:	c7 44 24 0c dc 56 10 	movl   $0x1056dc,0xc(%esp)
  100d83:	00 
  100d84:	c7 44 24 08 72 55 10 	movl   $0x105572,0x8(%esp)
  100d8b:	00 
  100d8c:	c7 44 24 04 ca 00 00 	movl   $0xca,0x4(%esp)
  100d93:	00 
  100d94:	c7 04 24 48 56 10 00 	movl   $0x105648,(%esp)
  100d9b:	e8 24 f7 ff ff       	call   1004c4 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100da0:	e8 45 fe ff ff       	call   100bea <mem_alloc>
  100da5:	89 45 ec             	mov    %eax,-0x14(%ebp)
  100da8:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  100dac:	75 24                	jne    100dd2 <mem_check+0x16e>
  100dae:	c7 44 24 0c e5 56 10 	movl   $0x1056e5,0xc(%esp)
  100db5:	00 
  100db6:	c7 44 24 08 72 55 10 	movl   $0x105572,0x8(%esp)
  100dbd:	00 
  100dbe:	c7 44 24 04 cb 00 00 	movl   $0xcb,0x4(%esp)
  100dc5:	00 
  100dc6:	c7 04 24 48 56 10 00 	movl   $0x105648,(%esp)
  100dcd:	e8 f2 f6 ff ff       	call   1004c4 <debug_panic>

	assert(pp0);
  100dd2:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100dd6:	75 24                	jne    100dfc <mem_check+0x198>
  100dd8:	c7 44 24 0c ee 56 10 	movl   $0x1056ee,0xc(%esp)
  100ddf:	00 
  100de0:	c7 44 24 08 72 55 10 	movl   $0x105572,0x8(%esp)
  100de7:	00 
  100de8:	c7 44 24 04 cd 00 00 	movl   $0xcd,0x4(%esp)
  100def:	00 
  100df0:	c7 04 24 48 56 10 00 	movl   $0x105648,(%esp)
  100df7:	e8 c8 f6 ff ff       	call   1004c4 <debug_panic>
	assert(pp1 && pp1 != pp0);
  100dfc:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100e00:	74 08                	je     100e0a <mem_check+0x1a6>
  100e02:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100e05:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  100e08:	75 24                	jne    100e2e <mem_check+0x1ca>
  100e0a:	c7 44 24 0c f2 56 10 	movl   $0x1056f2,0xc(%esp)
  100e11:	00 
  100e12:	c7 44 24 08 72 55 10 	movl   $0x105572,0x8(%esp)
  100e19:	00 
  100e1a:	c7 44 24 04 ce 00 00 	movl   $0xce,0x4(%esp)
  100e21:	00 
  100e22:	c7 04 24 48 56 10 00 	movl   $0x105648,(%esp)
  100e29:	e8 96 f6 ff ff       	call   1004c4 <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  100e2e:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  100e32:	74 10                	je     100e44 <mem_check+0x1e0>
  100e34:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100e37:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  100e3a:	74 08                	je     100e44 <mem_check+0x1e0>
  100e3c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100e3f:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  100e42:	75 24                	jne    100e68 <mem_check+0x204>
  100e44:	c7 44 24 0c 04 57 10 	movl   $0x105704,0xc(%esp)
  100e4b:	00 
  100e4c:	c7 44 24 08 72 55 10 	movl   $0x105572,0x8(%esp)
  100e53:	00 
  100e54:	c7 44 24 04 cf 00 00 	movl   $0xcf,0x4(%esp)
  100e5b:	00 
  100e5c:	c7 04 24 48 56 10 00 	movl   $0x105648,(%esp)
  100e63:	e8 5c f6 ff ff       	call   1004c4 <debug_panic>
        assert(mem_pi2phys(pp0) < mem_npage*PAGESIZE);
  100e68:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  100e6b:	a1 84 03 31 00       	mov    0x310384,%eax
  100e70:	89 d1                	mov    %edx,%ecx
  100e72:	29 c1                	sub    %eax,%ecx
  100e74:	89 c8                	mov    %ecx,%eax
  100e76:	c1 f8 03             	sar    $0x3,%eax
  100e79:	c1 e0 0c             	shl    $0xc,%eax
  100e7c:	8b 15 38 03 11 00    	mov    0x110338,%edx
  100e82:	c1 e2 0c             	shl    $0xc,%edx
  100e85:	39 d0                	cmp    %edx,%eax
  100e87:	72 24                	jb     100ead <mem_check+0x249>
  100e89:	c7 44 24 0c 24 57 10 	movl   $0x105724,0xc(%esp)
  100e90:	00 
  100e91:	c7 44 24 08 72 55 10 	movl   $0x105572,0x8(%esp)
  100e98:	00 
  100e99:	c7 44 24 04 d0 00 00 	movl   $0xd0,0x4(%esp)
  100ea0:	00 
  100ea1:	c7 04 24 48 56 10 00 	movl   $0x105648,(%esp)
  100ea8:	e8 17 f6 ff ff       	call   1004c4 <debug_panic>
        assert(mem_pi2phys(pp1) < mem_npage*PAGESIZE);
  100ead:	8b 55 e8             	mov    -0x18(%ebp),%edx
  100eb0:	a1 84 03 31 00       	mov    0x310384,%eax
  100eb5:	89 d1                	mov    %edx,%ecx
  100eb7:	29 c1                	sub    %eax,%ecx
  100eb9:	89 c8                	mov    %ecx,%eax
  100ebb:	c1 f8 03             	sar    $0x3,%eax
  100ebe:	c1 e0 0c             	shl    $0xc,%eax
  100ec1:	8b 15 38 03 11 00    	mov    0x110338,%edx
  100ec7:	c1 e2 0c             	shl    $0xc,%edx
  100eca:	39 d0                	cmp    %edx,%eax
  100ecc:	72 24                	jb     100ef2 <mem_check+0x28e>
  100ece:	c7 44 24 0c 4c 57 10 	movl   $0x10574c,0xc(%esp)
  100ed5:	00 
  100ed6:	c7 44 24 08 72 55 10 	movl   $0x105572,0x8(%esp)
  100edd:	00 
  100ede:	c7 44 24 04 d1 00 00 	movl   $0xd1,0x4(%esp)
  100ee5:	00 
  100ee6:	c7 04 24 48 56 10 00 	movl   $0x105648,(%esp)
  100eed:	e8 d2 f5 ff ff       	call   1004c4 <debug_panic>
        assert(mem_pi2phys(pp2) < mem_npage*PAGESIZE);
  100ef2:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100ef5:	a1 84 03 31 00       	mov    0x310384,%eax
  100efa:	89 d1                	mov    %edx,%ecx
  100efc:	29 c1                	sub    %eax,%ecx
  100efe:	89 c8                	mov    %ecx,%eax
  100f00:	c1 f8 03             	sar    $0x3,%eax
  100f03:	c1 e0 0c             	shl    $0xc,%eax
  100f06:	8b 15 38 03 11 00    	mov    0x110338,%edx
  100f0c:	c1 e2 0c             	shl    $0xc,%edx
  100f0f:	39 d0                	cmp    %edx,%eax
  100f11:	72 24                	jb     100f37 <mem_check+0x2d3>
  100f13:	c7 44 24 0c 74 57 10 	movl   $0x105774,0xc(%esp)
  100f1a:	00 
  100f1b:	c7 44 24 08 72 55 10 	movl   $0x105572,0x8(%esp)
  100f22:	00 
  100f23:	c7 44 24 04 d2 00 00 	movl   $0xd2,0x4(%esp)
  100f2a:	00 
  100f2b:	c7 04 24 48 56 10 00 	movl   $0x105648,(%esp)
  100f32:	e8 8d f5 ff ff       	call   1004c4 <debug_panic>

	// temporarily steal the rest of the free pages
	fl = mem_freelist;
  100f37:	a1 e0 02 11 00       	mov    0x1102e0,%eax
  100f3c:	89 45 e0             	mov    %eax,-0x20(%ebp)
	mem_freelist = 0;
  100f3f:	c7 05 e0 02 11 00 00 	movl   $0x0,0x1102e0
  100f46:	00 00 00 

	// should be no free memory
	assert(mem_alloc() == 0);
  100f49:	e8 9c fc ff ff       	call   100bea <mem_alloc>
  100f4e:	85 c0                	test   %eax,%eax
  100f50:	74 24                	je     100f76 <mem_check+0x312>
  100f52:	c7 44 24 0c 9a 57 10 	movl   $0x10579a,0xc(%esp)
  100f59:	00 
  100f5a:	c7 44 24 08 72 55 10 	movl   $0x105572,0x8(%esp)
  100f61:	00 
  100f62:	c7 44 24 04 d9 00 00 	movl   $0xd9,0x4(%esp)
  100f69:	00 
  100f6a:	c7 04 24 48 56 10 00 	movl   $0x105648,(%esp)
  100f71:	e8 4e f5 ff ff       	call   1004c4 <debug_panic>

        // free and re-allocate?
        mem_free(pp0);
  100f76:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100f79:	89 04 24             	mov    %eax,(%esp)
  100f7c:	e8 b0 fc ff ff       	call   100c31 <mem_free>
        mem_free(pp1);
  100f81:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100f84:	89 04 24             	mov    %eax,(%esp)
  100f87:	e8 a5 fc ff ff       	call   100c31 <mem_free>
        mem_free(pp2);
  100f8c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100f8f:	89 04 24             	mov    %eax,(%esp)
  100f92:	e8 9a fc ff ff       	call   100c31 <mem_free>
	pp0 = pp1 = pp2 = 0;
  100f97:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  100f9e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100fa1:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100fa4:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100fa7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  100faa:	e8 3b fc ff ff       	call   100bea <mem_alloc>
  100faf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100fb2:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100fb6:	75 24                	jne    100fdc <mem_check+0x378>
  100fb8:	c7 44 24 0c d3 56 10 	movl   $0x1056d3,0xc(%esp)
  100fbf:	00 
  100fc0:	c7 44 24 08 72 55 10 	movl   $0x105572,0x8(%esp)
  100fc7:	00 
  100fc8:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
  100fcf:	00 
  100fd0:	c7 04 24 48 56 10 00 	movl   $0x105648,(%esp)
  100fd7:	e8 e8 f4 ff ff       	call   1004c4 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100fdc:	e8 09 fc ff ff       	call   100bea <mem_alloc>
  100fe1:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100fe4:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100fe8:	75 24                	jne    10100e <mem_check+0x3aa>
  100fea:	c7 44 24 0c dc 56 10 	movl   $0x1056dc,0xc(%esp)
  100ff1:	00 
  100ff2:	c7 44 24 08 72 55 10 	movl   $0x105572,0x8(%esp)
  100ff9:	00 
  100ffa:	c7 44 24 04 e1 00 00 	movl   $0xe1,0x4(%esp)
  101001:	00 
  101002:	c7 04 24 48 56 10 00 	movl   $0x105648,(%esp)
  101009:	e8 b6 f4 ff ff       	call   1004c4 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  10100e:	e8 d7 fb ff ff       	call   100bea <mem_alloc>
  101013:	89 45 ec             	mov    %eax,-0x14(%ebp)
  101016:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  10101a:	75 24                	jne    101040 <mem_check+0x3dc>
  10101c:	c7 44 24 0c e5 56 10 	movl   $0x1056e5,0xc(%esp)
  101023:	00 
  101024:	c7 44 24 08 72 55 10 	movl   $0x105572,0x8(%esp)
  10102b:	00 
  10102c:	c7 44 24 04 e2 00 00 	movl   $0xe2,0x4(%esp)
  101033:	00 
  101034:	c7 04 24 48 56 10 00 	movl   $0x105648,(%esp)
  10103b:	e8 84 f4 ff ff       	call   1004c4 <debug_panic>
	assert(pp0);
  101040:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  101044:	75 24                	jne    10106a <mem_check+0x406>
  101046:	c7 44 24 0c ee 56 10 	movl   $0x1056ee,0xc(%esp)
  10104d:	00 
  10104e:	c7 44 24 08 72 55 10 	movl   $0x105572,0x8(%esp)
  101055:	00 
  101056:	c7 44 24 04 e3 00 00 	movl   $0xe3,0x4(%esp)
  10105d:	00 
  10105e:	c7 04 24 48 56 10 00 	movl   $0x105648,(%esp)
  101065:	e8 5a f4 ff ff       	call   1004c4 <debug_panic>
	assert(pp1 && pp1 != pp0);
  10106a:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  10106e:	74 08                	je     101078 <mem_check+0x414>
  101070:	8b 45 e8             	mov    -0x18(%ebp),%eax
  101073:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  101076:	75 24                	jne    10109c <mem_check+0x438>
  101078:	c7 44 24 0c f2 56 10 	movl   $0x1056f2,0xc(%esp)
  10107f:	00 
  101080:	c7 44 24 08 72 55 10 	movl   $0x105572,0x8(%esp)
  101087:	00 
  101088:	c7 44 24 04 e4 00 00 	movl   $0xe4,0x4(%esp)
  10108f:	00 
  101090:	c7 04 24 48 56 10 00 	movl   $0x105648,(%esp)
  101097:	e8 28 f4 ff ff       	call   1004c4 <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  10109c:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  1010a0:	74 10                	je     1010b2 <mem_check+0x44e>
  1010a2:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1010a5:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  1010a8:	74 08                	je     1010b2 <mem_check+0x44e>
  1010aa:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1010ad:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  1010b0:	75 24                	jne    1010d6 <mem_check+0x472>
  1010b2:	c7 44 24 0c 04 57 10 	movl   $0x105704,0xc(%esp)
  1010b9:	00 
  1010ba:	c7 44 24 08 72 55 10 	movl   $0x105572,0x8(%esp)
  1010c1:	00 
  1010c2:	c7 44 24 04 e5 00 00 	movl   $0xe5,0x4(%esp)
  1010c9:	00 
  1010ca:	c7 04 24 48 56 10 00 	movl   $0x105648,(%esp)
  1010d1:	e8 ee f3 ff ff       	call   1004c4 <debug_panic>
	assert(mem_alloc() == 0);
  1010d6:	e8 0f fb ff ff       	call   100bea <mem_alloc>
  1010db:	85 c0                	test   %eax,%eax
  1010dd:	74 24                	je     101103 <mem_check+0x49f>
  1010df:	c7 44 24 0c 9a 57 10 	movl   $0x10579a,0xc(%esp)
  1010e6:	00 
  1010e7:	c7 44 24 08 72 55 10 	movl   $0x105572,0x8(%esp)
  1010ee:	00 
  1010ef:	c7 44 24 04 e6 00 00 	movl   $0xe6,0x4(%esp)
  1010f6:	00 
  1010f7:	c7 04 24 48 56 10 00 	movl   $0x105648,(%esp)
  1010fe:	e8 c1 f3 ff ff       	call   1004c4 <debug_panic>

	// give free list back
	mem_freelist = fl;
  101103:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101106:	a3 e0 02 11 00       	mov    %eax,0x1102e0

	// free the pages we took
	mem_free(pp0);
  10110b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10110e:	89 04 24             	mov    %eax,(%esp)
  101111:	e8 1b fb ff ff       	call   100c31 <mem_free>
	mem_free(pp1);
  101116:	8b 45 e8             	mov    -0x18(%ebp),%eax
  101119:	89 04 24             	mov    %eax,(%esp)
  10111c:	e8 10 fb ff ff       	call   100c31 <mem_free>
	mem_free(pp2);
  101121:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101124:	89 04 24             	mov    %eax,(%esp)
  101127:	e8 05 fb ff ff       	call   100c31 <mem_free>

	cprintf("mem_check() succeeded!\n");
  10112c:	c7 04 24 ab 57 10 00 	movl   $0x1057ab,(%esp)
  101133:	e8 cc 3a 00 00       	call   104c04 <cprintf>
}
  101138:	c9                   	leave  
  101139:	c3                   	ret    
  10113a:	90                   	nop
  10113b:	90                   	nop

0010113c <xchg>:
}

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  10113c:	55                   	push   %ebp
  10113d:	89 e5                	mov    %esp,%ebp
  10113f:	53                   	push   %ebx
  101140:	83 ec 10             	sub    $0x10,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
	       "+m" (*addr), "=a" (result) :
  101143:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  101146:	8b 45 0c             	mov    0xc(%ebp),%eax
	       "+m" (*addr), "=a" (result) :
  101149:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  10114c:	89 c3                	mov    %eax,%ebx
  10114e:	89 d8                	mov    %ebx,%eax
  101150:	f0 87 02             	lock xchg %eax,(%edx)
  101153:	89 c3                	mov    %eax,%ebx
  101155:	89 5d f8             	mov    %ebx,-0x8(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  101158:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
  10115b:	83 c4 10             	add    $0x10,%esp
  10115e:	5b                   	pop    %ebx
  10115f:	5d                   	pop    %ebp
  101160:	c3                   	ret    

00101161 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  101161:	55                   	push   %ebp
  101162:	89 e5                	mov    %esp,%ebp
  101164:	53                   	push   %ebx
  101165:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  101168:	89 e3                	mov    %esp,%ebx
  10116a:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  10116d:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  101170:	89 45 f4             	mov    %eax,-0xc(%ebp)
  101173:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101176:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10117b:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  10117e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101181:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  101187:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  10118c:	74 24                	je     1011b2 <cpu_cur+0x51>
  10118e:	c7 44 24 0c c3 57 10 	movl   $0x1057c3,0xc(%esp)
  101195:	00 
  101196:	c7 44 24 08 d9 57 10 	movl   $0x1057d9,0x8(%esp)
  10119d:	00 
  10119e:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1011a5:	00 
  1011a6:	c7 04 24 ee 57 10 00 	movl   $0x1057ee,(%esp)
  1011ad:	e8 12 f3 ff ff       	call   1004c4 <debug_panic>
	return c;
  1011b2:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  1011b5:	83 c4 24             	add    $0x24,%esp
  1011b8:	5b                   	pop    %ebx
  1011b9:	5d                   	pop    %ebp
  1011ba:	c3                   	ret    

001011bb <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  1011bb:	55                   	push   %ebp
  1011bc:	89 e5                	mov    %esp,%ebp
  1011be:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  1011c1:	e8 9b ff ff ff       	call   101161 <cpu_cur>
  1011c6:	3d 00 90 10 00       	cmp    $0x109000,%eax
  1011cb:	0f 94 c0             	sete   %al
  1011ce:	0f b6 c0             	movzbl %al,%eax
}
  1011d1:	c9                   	leave  
  1011d2:	c3                   	ret    

001011d3 <cpu_init>:
	magic: CPU_MAGIC
};


void cpu_init()
{
  1011d3:	55                   	push   %ebp
  1011d4:	89 e5                	mov    %esp,%ebp
  1011d6:	53                   	push   %ebx
  1011d7:	83 ec 14             	sub    $0x14,%esp
	cpu *c = cpu_cur();
  1011da:	e8 82 ff ff ff       	call   101161 <cpu_cur>
  1011df:	89 45 f4             	mov    %eax,-0xc(%ebp)

	c->gdt[CPU_GDT_TSS >> 3] = SEGDESC16(0, STS_T32A, (uint32_t)(&c->tss), sizeof(c->tss)-1, 0);
  1011e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1011e5:	83 c0 38             	add    $0x38,%eax
  1011e8:	89 c3                	mov    %eax,%ebx
  1011ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1011ed:	83 c0 38             	add    $0x38,%eax
  1011f0:	c1 e8 10             	shr    $0x10,%eax
  1011f3:	89 c1                	mov    %eax,%ecx
  1011f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1011f8:	83 c0 38             	add    $0x38,%eax
  1011fb:	c1 e8 18             	shr    $0x18,%eax
  1011fe:	89 c2                	mov    %eax,%edx
  101200:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101203:	66 c7 40 30 67 00    	movw   $0x67,0x30(%eax)
  101209:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10120c:	66 89 58 32          	mov    %bx,0x32(%eax)
  101210:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101213:	88 48 34             	mov    %cl,0x34(%eax)
  101216:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101219:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  10121d:	83 e1 f0             	and    $0xfffffff0,%ecx
  101220:	83 c9 09             	or     $0x9,%ecx
  101223:	88 48 35             	mov    %cl,0x35(%eax)
  101226:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101229:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  10122d:	83 e1 ef             	and    $0xffffffef,%ecx
  101230:	88 48 35             	mov    %cl,0x35(%eax)
  101233:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101236:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  10123a:	83 e1 9f             	and    $0xffffff9f,%ecx
  10123d:	88 48 35             	mov    %cl,0x35(%eax)
  101240:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101243:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  101247:	83 c9 80             	or     $0xffffff80,%ecx
  10124a:	88 48 35             	mov    %cl,0x35(%eax)
  10124d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101250:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  101254:	83 e1 f0             	and    $0xfffffff0,%ecx
  101257:	88 48 36             	mov    %cl,0x36(%eax)
  10125a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10125d:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  101261:	83 e1 ef             	and    $0xffffffef,%ecx
  101264:	88 48 36             	mov    %cl,0x36(%eax)
  101267:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10126a:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  10126e:	83 e1 df             	and    $0xffffffdf,%ecx
  101271:	88 48 36             	mov    %cl,0x36(%eax)
  101274:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101277:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  10127b:	83 c9 40             	or     $0x40,%ecx
  10127e:	88 48 36             	mov    %cl,0x36(%eax)
  101281:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101284:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  101288:	83 e1 7f             	and    $0x7f,%ecx
  10128b:	88 48 36             	mov    %cl,0x36(%eax)
  10128e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101291:	88 50 37             	mov    %dl,0x37(%eax)
	c->tss.ts_esp0 = (uint32_t)c->kstackhi;
  101294:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101297:	05 00 10 00 00       	add    $0x1000,%eax
  10129c:	89 c2                	mov    %eax,%edx
  10129e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1012a1:	89 50 3c             	mov    %edx,0x3c(%eax)
	c->tss.ts_ss0 = CPU_GDT_KDATA;
  1012a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1012a7:	66 c7 40 40 10 00    	movw   $0x10,0x40(%eax)

	// Load the GDT
	struct pseudodesc gdt_pd = {
  1012ad:	66 c7 45 ec 37 00    	movw   $0x37,-0x14(%ebp)
		sizeof(c->gdt) - 1, (uint32_t) c->gdt };
  1012b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
	c->gdt[CPU_GDT_TSS >> 3] = SEGDESC16(0, STS_T32A, (uint32_t)(&c->tss), sizeof(c->tss)-1, 0);
	c->tss.ts_esp0 = (uint32_t)c->kstackhi;
	c->tss.ts_ss0 = CPU_GDT_KDATA;

	// Load the GDT
	struct pseudodesc gdt_pd = {
  1012b6:	89 45 ee             	mov    %eax,-0x12(%ebp)
		sizeof(c->gdt) - 1, (uint32_t) c->gdt };
	asm volatile("lgdt %0" : : "m" (gdt_pd));
  1012b9:	0f 01 55 ec          	lgdtl  -0x14(%ebp)

	// Reload all segment registers.
	asm volatile("movw %%ax,%%gs" :: "a" (CPU_GDT_UDATA|3));
  1012bd:	b8 23 00 00 00       	mov    $0x23,%eax
  1012c2:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (CPU_GDT_UDATA|3));
  1012c4:	b8 23 00 00 00       	mov    $0x23,%eax
  1012c9:	8e e0                	mov    %eax,%fs
	asm volatile("movw %%ax,%%es" :: "a" (CPU_GDT_KDATA));
  1012cb:	b8 10 00 00 00       	mov    $0x10,%eax
  1012d0:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (CPU_GDT_KDATA));
  1012d2:	b8 10 00 00 00       	mov    $0x10,%eax
  1012d7:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (CPU_GDT_KDATA));
  1012d9:	b8 10 00 00 00       	mov    $0x10,%eax
  1012de:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (CPU_GDT_KCODE)); // reload CS
  1012e0:	ea e7 12 10 00 08 00 	ljmp   $0x8,$0x1012e7

	// We don't need an LDT.
	asm volatile("lldt %%ax" :: "a" (0));
  1012e7:	b8 00 00 00 00       	mov    $0x0,%eax
  1012ec:	0f 00 d0             	lldt   %ax
  1012ef:	66 c7 45 f2 30 00    	movw   $0x30,-0xe(%ebp)
}

static gcc_inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
  1012f5:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
  1012f9:	0f 00 d8             	ltr    %ax

	ltr(CPU_GDT_TSS);
}
  1012fc:	83 c4 14             	add    $0x14,%esp
  1012ff:	5b                   	pop    %ebx
  101300:	5d                   	pop    %ebp
  101301:	c3                   	ret    

00101302 <cpu_alloc>:

// Allocate an additional cpu struct representing a non-bootstrap processor.
cpu *
cpu_alloc(void)
{
  101302:	55                   	push   %ebp
  101303:	89 e5                	mov    %esp,%ebp
  101305:	83 ec 28             	sub    $0x28,%esp
	// Pointer to the cpu.next pointer of the last CPU on the list,
	// for chaining on new CPUs in cpu_alloc().  Note: static.
	static cpu **cpu_tail = &cpu_boot.next;

	pageinfo *pi = mem_alloc();
  101308:	e8 dd f8 ff ff       	call   100bea <mem_alloc>
  10130d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	assert(pi != 0);	// shouldn't be out of memory just yet!
  101310:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  101314:	75 24                	jne    10133a <cpu_alloc+0x38>
  101316:	c7 44 24 0c fb 57 10 	movl   $0x1057fb,0xc(%esp)
  10131d:	00 
  10131e:	c7 44 24 08 d9 57 10 	movl   $0x1057d9,0x8(%esp)
  101325:	00 
  101326:	c7 44 24 04 5b 00 00 	movl   $0x5b,0x4(%esp)
  10132d:	00 
  10132e:	c7 04 24 03 58 10 00 	movl   $0x105803,(%esp)
  101335:	e8 8a f1 ff ff       	call   1004c4 <debug_panic>

	cpu *c = (cpu*) mem_pi2ptr(pi);
  10133a:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10133d:	a1 84 03 31 00       	mov    0x310384,%eax
  101342:	89 d1                	mov    %edx,%ecx
  101344:	29 c1                	sub    %eax,%ecx
  101346:	89 c8                	mov    %ecx,%eax
  101348:	c1 f8 03             	sar    $0x3,%eax
  10134b:	c1 e0 0c             	shl    $0xc,%eax
  10134e:	89 45 f0             	mov    %eax,-0x10(%ebp)

	// Clear the whole page for good measure: cpu struct and kernel stack
	memset(c, 0, PAGESIZE);
  101351:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  101358:	00 
  101359:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  101360:	00 
  101361:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101364:	89 04 24             	mov    %eax,(%esp)
  101367:	e8 7d 3a 00 00       	call   104de9 <memset>
	// when it starts up and calls cpu_init().

	// Initialize the new cpu's GDT by copying from the cpu_boot.
	// The TSS descriptor will be filled in later by cpu_init().
	assert(sizeof(c->gdt) == sizeof(segdesc) * CPU_GDT_NDESC);
	memmove(c->gdt, cpu_boot.gdt, sizeof(c->gdt));
  10136c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10136f:	c7 44 24 08 38 00 00 	movl   $0x38,0x8(%esp)
  101376:	00 
  101377:	c7 44 24 04 00 90 10 	movl   $0x109000,0x4(%esp)
  10137e:	00 
  10137f:	89 04 24             	mov    %eax,(%esp)
  101382:	e8 d0 3a 00 00       	call   104e57 <memmove>

	// Magic verification tag for stack overflow/cpu corruption checking
	c->magic = CPU_MAGIC;
  101387:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10138a:	c7 80 b8 00 00 00 32 	movl   $0x98765432,0xb8(%eax)
  101391:	54 76 98 

	// Chain the new CPU onto the tail of the list.
	*cpu_tail = c;
  101394:	a1 00 a0 10 00       	mov    0x10a000,%eax
  101399:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10139c:	89 10                	mov    %edx,(%eax)
	cpu_tail = &c->next;
  10139e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1013a1:	05 a8 00 00 00       	add    $0xa8,%eax
  1013a6:	a3 00 a0 10 00       	mov    %eax,0x10a000

	return c;
  1013ab:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  1013ae:	c9                   	leave  
  1013af:	c3                   	ret    

001013b0 <cpu_bootothers>:

void
cpu_bootothers(void)
{
  1013b0:	55                   	push   %ebp
  1013b1:	89 e5                	mov    %esp,%ebp
  1013b3:	83 ec 28             	sub    $0x28,%esp
	extern uint8_t _binary_obj_boot_bootother_start[],
			_binary_obj_boot_bootother_size[];

	if (!cpu_onboot()) {
  1013b6:	e8 00 fe ff ff       	call   1011bb <cpu_onboot>
  1013bb:	85 c0                	test   %eax,%eax
  1013bd:	75 1f                	jne    1013de <cpu_bootothers+0x2e>
		// Just inform the boot cpu we've booted.
		xchg(&cpu_cur()->booted, 1);
  1013bf:	e8 9d fd ff ff       	call   101161 <cpu_cur>
  1013c4:	05 b0 00 00 00       	add    $0xb0,%eax
  1013c9:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1013d0:	00 
  1013d1:	89 04 24             	mov    %eax,(%esp)
  1013d4:	e8 63 fd ff ff       	call   10113c <xchg>
		return;
  1013d9:	e9 92 00 00 00       	jmp    101470 <cpu_bootothers+0xc0>
	}

	// Write bootstrap code to unused memory at 0x1000.
	uint8_t *code = (uint8_t*)0x1000;
  1013de:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
	memmove(code, _binary_obj_boot_bootother_start,
  1013e5:	b8 6a 00 00 00       	mov    $0x6a,%eax
  1013ea:	89 44 24 08          	mov    %eax,0x8(%esp)
  1013ee:	c7 44 24 04 94 a5 10 	movl   $0x10a594,0x4(%esp)
  1013f5:	00 
  1013f6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1013f9:	89 04 24             	mov    %eax,(%esp)
  1013fc:	e8 56 3a 00 00       	call   104e57 <memmove>
		(uint32_t)_binary_obj_boot_bootother_size);

	cpu *c;
	for(c = &cpu_boot; c; c = c->next){
  101401:	c7 45 f4 00 90 10 00 	movl   $0x109000,-0xc(%ebp)
  101408:	eb 60                	jmp    10146a <cpu_bootothers+0xba>
		if(c == cpu_cur())  // We''ve started already.
  10140a:	e8 52 fd ff ff       	call   101161 <cpu_cur>
  10140f:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  101412:	74 49                	je     10145d <cpu_bootothers+0xad>
			continue;

		// Fill in %esp, %eip and start code on cpu.
		*(void**)(code-4) = c->kstackhi;
  101414:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101417:	83 e8 04             	sub    $0x4,%eax
  10141a:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10141d:	81 c2 00 10 00 00    	add    $0x1000,%edx
  101423:	89 10                	mov    %edx,(%eax)
		*(void**)(code-8) = init;
  101425:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101428:	83 e8 08             	sub    $0x8,%eax
  10142b:	c7 00 9a 00 10 00    	movl   $0x10009a,(%eax)
		lapic_startcpu(c->id, (uint32_t)code);
  101431:	8b 55 f0             	mov    -0x10(%ebp),%edx
  101434:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101437:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  10143e:	0f b6 c0             	movzbl %al,%eax
  101441:	89 54 24 04          	mov    %edx,0x4(%esp)
  101445:	89 04 24             	mov    %eax,(%esp)
  101448:	e8 ae 2d 00 00       	call   1041fb <lapic_startcpu>

		// Wait for cpu to get through bootstrap.
		while(c->booted == 0)
  10144d:	90                   	nop
  10144e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101451:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
  101457:	85 c0                	test   %eax,%eax
  101459:	74 f3                	je     10144e <cpu_bootothers+0x9e>
  10145b:	eb 01                	jmp    10145e <cpu_bootothers+0xae>
		(uint32_t)_binary_obj_boot_bootother_size);

	cpu *c;
	for(c = &cpu_boot; c; c = c->next){
		if(c == cpu_cur())  // We''ve started already.
			continue;
  10145d:	90                   	nop
	uint8_t *code = (uint8_t*)0x1000;
	memmove(code, _binary_obj_boot_bootother_start,
		(uint32_t)_binary_obj_boot_bootother_size);

	cpu *c;
	for(c = &cpu_boot; c; c = c->next){
  10145e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101461:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  101467:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10146a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  10146e:	75 9a                	jne    10140a <cpu_bootothers+0x5a>

		// Wait for cpu to get through bootstrap.
		while(c->booted == 0)
			;
	}
}
  101470:	c9                   	leave  
  101471:	c3                   	ret    
  101472:	90                   	nop
  101473:	90                   	nop

00101474 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  101474:	55                   	push   %ebp
  101475:	89 e5                	mov    %esp,%ebp
  101477:	53                   	push   %ebx
  101478:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10147b:	89 e3                	mov    %esp,%ebx
  10147d:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  101480:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  101483:	89 45 f4             	mov    %eax,-0xc(%ebp)
  101486:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101489:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10148e:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  101491:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101494:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  10149a:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  10149f:	74 24                	je     1014c5 <cpu_cur+0x51>
  1014a1:	c7 44 24 0c 20 58 10 	movl   $0x105820,0xc(%esp)
  1014a8:	00 
  1014a9:	c7 44 24 08 36 58 10 	movl   $0x105836,0x8(%esp)
  1014b0:	00 
  1014b1:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1014b8:	00 
  1014b9:	c7 04 24 4b 58 10 00 	movl   $0x10584b,(%esp)
  1014c0:	e8 ff ef ff ff       	call   1004c4 <debug_panic>
	return c;
  1014c5:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  1014c8:	83 c4 24             	add    $0x24,%esp
  1014cb:	5b                   	pop    %ebx
  1014cc:	5d                   	pop    %ebp
  1014cd:	c3                   	ret    

001014ce <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  1014ce:	55                   	push   %ebp
  1014cf:	89 e5                	mov    %esp,%ebp
  1014d1:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  1014d4:	e8 9b ff ff ff       	call   101474 <cpu_cur>
  1014d9:	3d 00 90 10 00       	cmp    $0x109000,%eax
  1014de:	0f 94 c0             	sete   %al
  1014e1:	0f b6 c0             	movzbl %al,%eax
}
  1014e4:	c9                   	leave  
  1014e5:	c3                   	ret    

001014e6 <trap_init_idt>:
extern int vectors[];


static void
trap_init_idt(void)
{
  1014e6:	55                   	push   %ebp
  1014e7:	89 e5                	mov    %esp,%ebp
  1014e9:	83 ec 10             	sub    $0x10,%esp
	extern segdesc gdt[];

	//panic("trap_init() not implemented.");

	int i;
	for (i=0; i<256; i++) {
  1014ec:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  1014f3:	e9 c3 00 00 00       	jmp    1015bb <trap_init_idt+0xd5>
		SETGATE(idt[i], 0, CPU_GDT_KCODE, vectors[i], 0); //CPU_GDT_KCODE is 0x08
  1014f8:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1014fb:	8b 04 85 0c a0 10 00 	mov    0x10a00c(,%eax,4),%eax
  101502:	89 c2                	mov    %eax,%edx
  101504:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101507:	66 89 14 c5 20 b8 10 	mov    %dx,0x10b820(,%eax,8)
  10150e:	00 
  10150f:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101512:	66 c7 04 c5 22 b8 10 	movw   $0x8,0x10b822(,%eax,8)
  101519:	00 08 00 
  10151c:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10151f:	0f b6 14 c5 24 b8 10 	movzbl 0x10b824(,%eax,8),%edx
  101526:	00 
  101527:	83 e2 e0             	and    $0xffffffe0,%edx
  10152a:	88 14 c5 24 b8 10 00 	mov    %dl,0x10b824(,%eax,8)
  101531:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101534:	0f b6 14 c5 24 b8 10 	movzbl 0x10b824(,%eax,8),%edx
  10153b:	00 
  10153c:	83 e2 1f             	and    $0x1f,%edx
  10153f:	88 14 c5 24 b8 10 00 	mov    %dl,0x10b824(,%eax,8)
  101546:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101549:	0f b6 14 c5 25 b8 10 	movzbl 0x10b825(,%eax,8),%edx
  101550:	00 
  101551:	83 e2 f0             	and    $0xfffffff0,%edx
  101554:	83 ca 0e             	or     $0xe,%edx
  101557:	88 14 c5 25 b8 10 00 	mov    %dl,0x10b825(,%eax,8)
  10155e:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101561:	0f b6 14 c5 25 b8 10 	movzbl 0x10b825(,%eax,8),%edx
  101568:	00 
  101569:	83 e2 ef             	and    $0xffffffef,%edx
  10156c:	88 14 c5 25 b8 10 00 	mov    %dl,0x10b825(,%eax,8)
  101573:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101576:	0f b6 14 c5 25 b8 10 	movzbl 0x10b825(,%eax,8),%edx
  10157d:	00 
  10157e:	83 e2 9f             	and    $0xffffff9f,%edx
  101581:	88 14 c5 25 b8 10 00 	mov    %dl,0x10b825(,%eax,8)
  101588:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10158b:	0f b6 14 c5 25 b8 10 	movzbl 0x10b825(,%eax,8),%edx
  101592:	00 
  101593:	83 ca 80             	or     $0xffffff80,%edx
  101596:	88 14 c5 25 b8 10 00 	mov    %dl,0x10b825(,%eax,8)
  10159d:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1015a0:	8b 04 85 0c a0 10 00 	mov    0x10a00c(,%eax,4),%eax
  1015a7:	c1 e8 10             	shr    $0x10,%eax
  1015aa:	89 c2                	mov    %eax,%edx
  1015ac:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1015af:	66 89 14 c5 26 b8 10 	mov    %dx,0x10b826(,%eax,8)
  1015b6:	00 
	extern segdesc gdt[];

	//panic("trap_init() not implemented.");

	int i;
	for (i=0; i<256; i++) {
  1015b7:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  1015bb:	81 7d fc ff 00 00 00 	cmpl   $0xff,-0x4(%ebp)
  1015c2:	0f 8e 30 ff ff ff    	jle    1014f8 <trap_init_idt+0x12>
		SETGATE(idt[i], 0, CPU_GDT_KCODE, vectors[i], 0); //CPU_GDT_KCODE is 0x08
	}
	SETGATE(idt[3], 0, CPU_GDT_KCODE, vectors[3], 3); //T_BRKPT
  1015c8:	a1 18 a0 10 00       	mov    0x10a018,%eax
  1015cd:	66 a3 38 b8 10 00    	mov    %ax,0x10b838
  1015d3:	66 c7 05 3a b8 10 00 	movw   $0x8,0x10b83a
  1015da:	08 00 
  1015dc:	0f b6 05 3c b8 10 00 	movzbl 0x10b83c,%eax
  1015e3:	83 e0 e0             	and    $0xffffffe0,%eax
  1015e6:	a2 3c b8 10 00       	mov    %al,0x10b83c
  1015eb:	0f b6 05 3c b8 10 00 	movzbl 0x10b83c,%eax
  1015f2:	83 e0 1f             	and    $0x1f,%eax
  1015f5:	a2 3c b8 10 00       	mov    %al,0x10b83c
  1015fa:	0f b6 05 3d b8 10 00 	movzbl 0x10b83d,%eax
  101601:	83 e0 f0             	and    $0xfffffff0,%eax
  101604:	83 c8 0e             	or     $0xe,%eax
  101607:	a2 3d b8 10 00       	mov    %al,0x10b83d
  10160c:	0f b6 05 3d b8 10 00 	movzbl 0x10b83d,%eax
  101613:	83 e0 ef             	and    $0xffffffef,%eax
  101616:	a2 3d b8 10 00       	mov    %al,0x10b83d
  10161b:	0f b6 05 3d b8 10 00 	movzbl 0x10b83d,%eax
  101622:	83 c8 60             	or     $0x60,%eax
  101625:	a2 3d b8 10 00       	mov    %al,0x10b83d
  10162a:	0f b6 05 3d b8 10 00 	movzbl 0x10b83d,%eax
  101631:	83 c8 80             	or     $0xffffff80,%eax
  101634:	a2 3d b8 10 00       	mov    %al,0x10b83d
  101639:	a1 18 a0 10 00       	mov    0x10a018,%eax
  10163e:	c1 e8 10             	shr    $0x10,%eax
  101641:	66 a3 3e b8 10 00    	mov    %ax,0x10b83e
	SETGATE(idt[4], 0, CPU_GDT_KCODE, vectors[4], 3); //T_OFLOW
  101647:	a1 1c a0 10 00       	mov    0x10a01c,%eax
  10164c:	66 a3 40 b8 10 00    	mov    %ax,0x10b840
  101652:	66 c7 05 42 b8 10 00 	movw   $0x8,0x10b842
  101659:	08 00 
  10165b:	0f b6 05 44 b8 10 00 	movzbl 0x10b844,%eax
  101662:	83 e0 e0             	and    $0xffffffe0,%eax
  101665:	a2 44 b8 10 00       	mov    %al,0x10b844
  10166a:	0f b6 05 44 b8 10 00 	movzbl 0x10b844,%eax
  101671:	83 e0 1f             	and    $0x1f,%eax
  101674:	a2 44 b8 10 00       	mov    %al,0x10b844
  101679:	0f b6 05 45 b8 10 00 	movzbl 0x10b845,%eax
  101680:	83 e0 f0             	and    $0xfffffff0,%eax
  101683:	83 c8 0e             	or     $0xe,%eax
  101686:	a2 45 b8 10 00       	mov    %al,0x10b845
  10168b:	0f b6 05 45 b8 10 00 	movzbl 0x10b845,%eax
  101692:	83 e0 ef             	and    $0xffffffef,%eax
  101695:	a2 45 b8 10 00       	mov    %al,0x10b845
  10169a:	0f b6 05 45 b8 10 00 	movzbl 0x10b845,%eax
  1016a1:	83 c8 60             	or     $0x60,%eax
  1016a4:	a2 45 b8 10 00       	mov    %al,0x10b845
  1016a9:	0f b6 05 45 b8 10 00 	movzbl 0x10b845,%eax
  1016b0:	83 c8 80             	or     $0xffffff80,%eax
  1016b3:	a2 45 b8 10 00       	mov    %al,0x10b845
  1016b8:	a1 1c a0 10 00       	mov    0x10a01c,%eax
  1016bd:	c1 e8 10             	shr    $0x10,%eax
  1016c0:	66 a3 46 b8 10 00    	mov    %ax,0x10b846

}
  1016c6:	c9                   	leave  
  1016c7:	c3                   	ret    

001016c8 <trap_init>:

void
trap_init(void)
{
  1016c8:	55                   	push   %ebp
  1016c9:	89 e5                	mov    %esp,%ebp
  1016cb:	83 ec 08             	sub    $0x8,%esp
	// The first time we get called on the bootstrap processor,
	// initialize the IDT.  Other CPUs will share the same IDT.
	if (cpu_onboot())
  1016ce:	e8 fb fd ff ff       	call   1014ce <cpu_onboot>
  1016d3:	85 c0                	test   %eax,%eax
  1016d5:	74 05                	je     1016dc <trap_init+0x14>
		trap_init_idt();
  1016d7:	e8 0a fe ff ff       	call   1014e6 <trap_init_idt>

	// Load the IDT into this processor's IDT register.
	asm volatile("lidt %0" : : "m" (idt_pd));
  1016dc:	0f 01 1d 04 a0 10 00 	lidtl  0x10a004

	// Check for the correct IDT and trap handler operation.
	if (cpu_onboot())
  1016e3:	e8 e6 fd ff ff       	call   1014ce <cpu_onboot>
  1016e8:	85 c0                	test   %eax,%eax
  1016ea:	74 05                	je     1016f1 <trap_init+0x29>
		trap_check_kernel();
  1016ec:	e8 d5 03 00 00       	call   101ac6 <trap_check_kernel>
}
  1016f1:	c9                   	leave  
  1016f2:	c3                   	ret    

001016f3 <trap_name>:

const char *trap_name(int trapno)
{
  1016f3:	55                   	push   %ebp
  1016f4:	89 e5                	mov    %esp,%ebp
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
  1016f6:	8b 45 08             	mov    0x8(%ebp),%eax
  1016f9:	83 f8 13             	cmp    $0x13,%eax
  1016fc:	77 0c                	ja     10170a <trap_name+0x17>
		return excnames[trapno];
  1016fe:	8b 45 08             	mov    0x8(%ebp),%eax
  101701:	8b 04 85 20 5d 10 00 	mov    0x105d20(,%eax,4),%eax
  101708:	eb 25                	jmp    10172f <trap_name+0x3c>
	if (trapno == T_SYSCALL)
  10170a:	83 7d 08 30          	cmpl   $0x30,0x8(%ebp)
  10170e:	75 07                	jne    101717 <trap_name+0x24>
		return "System call";
  101710:	b8 58 58 10 00       	mov    $0x105858,%eax
  101715:	eb 18                	jmp    10172f <trap_name+0x3c>
	if (trapno >= T_IRQ0 && trapno < T_IRQ0 + 16)
  101717:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
  10171b:	7e 0d                	jle    10172a <trap_name+0x37>
  10171d:	83 7d 08 2f          	cmpl   $0x2f,0x8(%ebp)
  101721:	7f 07                	jg     10172a <trap_name+0x37>
		return "Hardware Interrupt";
  101723:	b8 64 58 10 00       	mov    $0x105864,%eax
  101728:	eb 05                	jmp    10172f <trap_name+0x3c>
	return "(unknown trap)";
  10172a:	b8 77 58 10 00       	mov    $0x105877,%eax
}
  10172f:	5d                   	pop    %ebp
  101730:	c3                   	ret    

00101731 <trap_print_regs>:

void
trap_print_regs(pushregs *regs)
{
  101731:	55                   	push   %ebp
  101732:	89 e5                	mov    %esp,%ebp
  101734:	83 ec 18             	sub    $0x18,%esp
	cprintf("  edi  0x%08x\n", regs->edi);
  101737:	8b 45 08             	mov    0x8(%ebp),%eax
  10173a:	8b 00                	mov    (%eax),%eax
  10173c:	89 44 24 04          	mov    %eax,0x4(%esp)
  101740:	c7 04 24 86 58 10 00 	movl   $0x105886,(%esp)
  101747:	e8 b8 34 00 00       	call   104c04 <cprintf>
	cprintf("  esi  0x%08x\n", regs->esi);
  10174c:	8b 45 08             	mov    0x8(%ebp),%eax
  10174f:	8b 40 04             	mov    0x4(%eax),%eax
  101752:	89 44 24 04          	mov    %eax,0x4(%esp)
  101756:	c7 04 24 95 58 10 00 	movl   $0x105895,(%esp)
  10175d:	e8 a2 34 00 00       	call   104c04 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->ebp);
  101762:	8b 45 08             	mov    0x8(%ebp),%eax
  101765:	8b 40 08             	mov    0x8(%eax),%eax
  101768:	89 44 24 04          	mov    %eax,0x4(%esp)
  10176c:	c7 04 24 a4 58 10 00 	movl   $0x1058a4,(%esp)
  101773:	e8 8c 34 00 00       	call   104c04 <cprintf>
//	cprintf("  oesp 0x%08x\n", regs->oesp);	don't print - useless
	cprintf("  ebx  0x%08x\n", regs->ebx);
  101778:	8b 45 08             	mov    0x8(%ebp),%eax
  10177b:	8b 40 10             	mov    0x10(%eax),%eax
  10177e:	89 44 24 04          	mov    %eax,0x4(%esp)
  101782:	c7 04 24 b3 58 10 00 	movl   $0x1058b3,(%esp)
  101789:	e8 76 34 00 00       	call   104c04 <cprintf>
	cprintf("  edx  0x%08x\n", regs->edx);
  10178e:	8b 45 08             	mov    0x8(%ebp),%eax
  101791:	8b 40 14             	mov    0x14(%eax),%eax
  101794:	89 44 24 04          	mov    %eax,0x4(%esp)
  101798:	c7 04 24 c2 58 10 00 	movl   $0x1058c2,(%esp)
  10179f:	e8 60 34 00 00       	call   104c04 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->ecx);
  1017a4:	8b 45 08             	mov    0x8(%ebp),%eax
  1017a7:	8b 40 18             	mov    0x18(%eax),%eax
  1017aa:	89 44 24 04          	mov    %eax,0x4(%esp)
  1017ae:	c7 04 24 d1 58 10 00 	movl   $0x1058d1,(%esp)
  1017b5:	e8 4a 34 00 00       	call   104c04 <cprintf>
	cprintf("  eax  0x%08x\n", regs->eax);
  1017ba:	8b 45 08             	mov    0x8(%ebp),%eax
  1017bd:	8b 40 1c             	mov    0x1c(%eax),%eax
  1017c0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1017c4:	c7 04 24 e0 58 10 00 	movl   $0x1058e0,(%esp)
  1017cb:	e8 34 34 00 00       	call   104c04 <cprintf>
}
  1017d0:	c9                   	leave  
  1017d1:	c3                   	ret    

001017d2 <trap_print>:

void
trap_print(trapframe *tf)
{
  1017d2:	55                   	push   %ebp
  1017d3:	89 e5                	mov    %esp,%ebp
  1017d5:	83 ec 18             	sub    $0x18,%esp
	cprintf("TRAP frame at %p\n", tf);
  1017d8:	8b 45 08             	mov    0x8(%ebp),%eax
  1017db:	89 44 24 04          	mov    %eax,0x4(%esp)
  1017df:	c7 04 24 ef 58 10 00 	movl   $0x1058ef,(%esp)
  1017e6:	e8 19 34 00 00       	call   104c04 <cprintf>
	trap_print_regs(&tf->regs);
  1017eb:	8b 45 08             	mov    0x8(%ebp),%eax
  1017ee:	89 04 24             	mov    %eax,(%esp)
  1017f1:	e8 3b ff ff ff       	call   101731 <trap_print_regs>
	cprintf("  es   0x----%04x\n", tf->es);
  1017f6:	8b 45 08             	mov    0x8(%ebp),%eax
  1017f9:	0f b7 40 28          	movzwl 0x28(%eax),%eax
  1017fd:	0f b7 c0             	movzwl %ax,%eax
  101800:	89 44 24 04          	mov    %eax,0x4(%esp)
  101804:	c7 04 24 01 59 10 00 	movl   $0x105901,(%esp)
  10180b:	e8 f4 33 00 00       	call   104c04 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->ds);
  101810:	8b 45 08             	mov    0x8(%ebp),%eax
  101813:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  101817:	0f b7 c0             	movzwl %ax,%eax
  10181a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10181e:	c7 04 24 14 59 10 00 	movl   $0x105914,(%esp)
  101825:	e8 da 33 00 00       	call   104c04 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->trapno, trap_name(tf->trapno));
  10182a:	8b 45 08             	mov    0x8(%ebp),%eax
  10182d:	8b 40 30             	mov    0x30(%eax),%eax
  101830:	89 04 24             	mov    %eax,(%esp)
  101833:	e8 bb fe ff ff       	call   1016f3 <trap_name>
  101838:	8b 55 08             	mov    0x8(%ebp),%edx
  10183b:	8b 52 30             	mov    0x30(%edx),%edx
  10183e:	89 44 24 08          	mov    %eax,0x8(%esp)
  101842:	89 54 24 04          	mov    %edx,0x4(%esp)
  101846:	c7 04 24 27 59 10 00 	movl   $0x105927,(%esp)
  10184d:	e8 b2 33 00 00       	call   104c04 <cprintf>
	cprintf("  err  0x%08x\n", tf->err);
  101852:	8b 45 08             	mov    0x8(%ebp),%eax
  101855:	8b 40 34             	mov    0x34(%eax),%eax
  101858:	89 44 24 04          	mov    %eax,0x4(%esp)
  10185c:	c7 04 24 39 59 10 00 	movl   $0x105939,(%esp)
  101863:	e8 9c 33 00 00       	call   104c04 <cprintf>
	cprintf("  eip  0x%08x\n", tf->eip);
  101868:	8b 45 08             	mov    0x8(%ebp),%eax
  10186b:	8b 40 38             	mov    0x38(%eax),%eax
  10186e:	89 44 24 04          	mov    %eax,0x4(%esp)
  101872:	c7 04 24 48 59 10 00 	movl   $0x105948,(%esp)
  101879:	e8 86 33 00 00       	call   104c04 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->cs);
  10187e:	8b 45 08             	mov    0x8(%ebp),%eax
  101881:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  101885:	0f b7 c0             	movzwl %ax,%eax
  101888:	89 44 24 04          	mov    %eax,0x4(%esp)
  10188c:	c7 04 24 57 59 10 00 	movl   $0x105957,(%esp)
  101893:	e8 6c 33 00 00       	call   104c04 <cprintf>
	cprintf("  flag 0x%08x\n", tf->eflags);
  101898:	8b 45 08             	mov    0x8(%ebp),%eax
  10189b:	8b 40 40             	mov    0x40(%eax),%eax
  10189e:	89 44 24 04          	mov    %eax,0x4(%esp)
  1018a2:	c7 04 24 6a 59 10 00 	movl   $0x10596a,(%esp)
  1018a9:	e8 56 33 00 00       	call   104c04 <cprintf>
	cprintf("  esp  0x%08x\n", tf->esp);
  1018ae:	8b 45 08             	mov    0x8(%ebp),%eax
  1018b1:	8b 40 44             	mov    0x44(%eax),%eax
  1018b4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1018b8:	c7 04 24 79 59 10 00 	movl   $0x105979,(%esp)
  1018bf:	e8 40 33 00 00       	call   104c04 <cprintf>
	cprintf("  ss   0x----%04x\n", tf->ss);
  1018c4:	8b 45 08             	mov    0x8(%ebp),%eax
  1018c7:	0f b7 40 48          	movzwl 0x48(%eax),%eax
  1018cb:	0f b7 c0             	movzwl %ax,%eax
  1018ce:	89 44 24 04          	mov    %eax,0x4(%esp)
  1018d2:	c7 04 24 88 59 10 00 	movl   $0x105988,(%esp)
  1018d9:	e8 26 33 00 00       	call   104c04 <cprintf>
}
  1018de:	c9                   	leave  
  1018df:	c3                   	ret    

001018e0 <trap>:

void gcc_noreturn
trap(trapframe *tf)
{
  1018e0:	55                   	push   %ebp
  1018e1:	89 e5                	mov    %esp,%ebp
  1018e3:	83 ec 28             	sub    $0x28,%esp
	// The user-level environment may have set the DF flag,
	// and some versions of GCC rely on DF being clear.
	asm volatile("cld" ::: "cc");
  1018e6:	fc                   	cld    

	// If this trap was anticipated, just use the designated handler.
	cpu *c = cpu_cur();
  1018e7:	e8 88 fb ff ff       	call   101474 <cpu_cur>
  1018ec:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (c->recover)
  1018ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1018f2:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  1018f8:	85 c0                	test   %eax,%eax
  1018fa:	74 1e                	je     10191a <trap+0x3a>
		c->recover(tf, c->recoverdata);
  1018fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1018ff:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  101905:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101908:	8b 92 a4 00 00 00    	mov    0xa4(%edx),%edx
  10190e:	89 54 24 04          	mov    %edx,0x4(%esp)
  101912:	8b 55 08             	mov    0x8(%ebp),%edx
  101915:	89 14 24             	mov    %edx,(%esp)
  101918:	ff d0                	call   *%eax

	// Lab 2: your trap handling code here!
	switch (tf->trapno) {
  10191a:	8b 45 08             	mov    0x8(%ebp),%eax
  10191d:	8b 40 30             	mov    0x30(%eax),%eax
  101920:	83 f8 32             	cmp    $0x32,%eax
  101923:	0f 87 28 01 00 00    	ja     101a51 <trap+0x171>
  101929:	8b 04 85 f8 59 10 00 	mov    0x1059f8(,%eax,4),%eax
  101930:	ff e0                	jmp    *%eax
  		case T_SYSCALL:
    		assert(tf->cs & 3);
  101932:	8b 45 08             	mov    0x8(%ebp),%eax
  101935:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  101939:	0f b7 c0             	movzwl %ax,%eax
  10193c:	83 e0 03             	and    $0x3,%eax
  10193f:	85 c0                	test   %eax,%eax
  101941:	75 24                	jne    101967 <trap+0x87>
  101943:	c7 44 24 0c 9b 59 10 	movl   $0x10599b,0xc(%esp)
  10194a:	00 
  10194b:	c7 44 24 08 36 58 10 	movl   $0x105836,0x8(%esp)
  101952:	00 
  101953:	c7 44 24 04 94 00 00 	movl   $0x94,0x4(%esp)
  10195a:	00 
  10195b:	c7 04 24 a6 59 10 00 	movl   $0x1059a6,(%esp)
  101962:	e8 5d eb ff ff       	call   1004c4 <debug_panic>
    		syscall(tf);
  101967:	8b 45 08             	mov    0x8(%ebp),%eax
  10196a:	89 04 24             	mov    %eax,(%esp)
  10196d:	e8 6a 1c 00 00       	call   1035dc <syscall>
    		break;
  101972:	e9 da 00 00 00       	jmp    101a51 <trap+0x171>
	  	case T_FPERR:
	  	case T_ALIGN:
	  	case T_MCHK:
	  	case T_SIMD:
	  	case T_SECEV:
	  		cprintf("the trapno is %x",tf->trapno);
  101977:	8b 45 08             	mov    0x8(%ebp),%eax
  10197a:	8b 40 30             	mov    0x30(%eax),%eax
  10197d:	89 44 24 04          	mov    %eax,0x4(%esp)
  101981:	c7 04 24 b2 59 10 00 	movl   $0x1059b2,(%esp)
  101988:	e8 77 32 00 00       	call   104c04 <cprintf>
	    	assert(tf->cs & 3);
  10198d:	8b 45 08             	mov    0x8(%ebp),%eax
  101990:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  101994:	0f b7 c0             	movzwl %ax,%eax
  101997:	83 e0 03             	and    $0x3,%eax
  10199a:	85 c0                	test   %eax,%eax
  10199c:	75 24                	jne    1019c2 <trap+0xe2>
  10199e:	c7 44 24 0c 9b 59 10 	movl   $0x10599b,0xc(%esp)
  1019a5:	00 
  1019a6:	c7 44 24 08 36 58 10 	movl   $0x105836,0x8(%esp)
  1019ad:	00 
  1019ae:	c7 44 24 04 ab 00 00 	movl   $0xab,0x4(%esp)
  1019b5:	00 
  1019b6:	c7 04 24 a6 59 10 00 	movl   $0x1059a6,(%esp)
  1019bd:	e8 02 eb ff ff       	call   1004c4 <debug_panic>
	    	proc_ret(tf, 1);
  1019c2:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1019c9:	00 
  1019ca:	8b 45 08             	mov    0x8(%ebp),%eax
  1019cd:	89 04 24             	mov    %eax,(%esp)
  1019d0:	e8 88 14 00 00       	call   102e5d <proc_ret>
	    	break;
	  	case T_LTIMER:
	    	lapic_eoi();
  1019d5:	e8 92 27 00 00       	call   10416c <lapic_eoi>
	    	if (tf->cs & 3)
  1019da:	8b 45 08             	mov    0x8(%ebp),%eax
  1019dd:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  1019e1:	0f b7 c0             	movzwl %ax,%eax
  1019e4:	83 e0 03             	and    $0x3,%eax
  1019e7:	85 c0                	test   %eax,%eax
  1019e9:	74 0b                	je     1019f6 <trap+0x116>
	      	proc_yield(tf);
  1019eb:	8b 45 08             	mov    0x8(%ebp),%eax
  1019ee:	89 04 24             	mov    %eax,(%esp)
  1019f1:	e8 29 14 00 00       	call   102e1f <proc_yield>
		    trap_return(tf);
  1019f6:	8b 45 08             	mov    0x8(%ebp),%eax
  1019f9:	89 04 24             	mov    %eax,(%esp)
  1019fc:	e8 ff 04 00 00       	call   101f00 <trap_return>
	    	break;
	  	case T_LERROR:
	    	lapic_errintr();
  101a01:	e8 8b 27 00 00       	call   104191 <lapic_errintr>
	    	trap_return(tf);
  101a06:	8b 45 08             	mov    0x8(%ebp),%eax
  101a09:	89 04 24             	mov    %eax,(%esp)
  101a0c:	e8 ef 04 00 00       	call   101f00 <trap_return>
	  	case T_IRQ0 + IRQ_SPURIOUS:
	    	cprintf("cpu%d: spurious interrupt at %x:%x\n",
	        c->id, tf->cs, tf->eip);
  101a11:	8b 45 08             	mov    0x8(%ebp),%eax
	    	break;
	  	case T_LERROR:
	    	lapic_errintr();
	    	trap_return(tf);
	  	case T_IRQ0 + IRQ_SPURIOUS:
	    	cprintf("cpu%d: spurious interrupt at %x:%x\n",
  101a14:	8b 48 38             	mov    0x38(%eax),%ecx
	        c->id, tf->cs, tf->eip);
  101a17:	8b 45 08             	mov    0x8(%ebp),%eax
  101a1a:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
	    	break;
	  	case T_LERROR:
	    	lapic_errintr();
	    	trap_return(tf);
	  	case T_IRQ0 + IRQ_SPURIOUS:
	    	cprintf("cpu%d: spurious interrupt at %x:%x\n",
  101a1e:	0f b7 d0             	movzwl %ax,%edx
	        c->id, tf->cs, tf->eip);
  101a21:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101a24:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
	    	break;
	  	case T_LERROR:
	    	lapic_errintr();
	    	trap_return(tf);
	  	case T_IRQ0 + IRQ_SPURIOUS:
	    	cprintf("cpu%d: spurious interrupt at %x:%x\n",
  101a2b:	0f b6 c0             	movzbl %al,%eax
  101a2e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  101a32:	89 54 24 08          	mov    %edx,0x8(%esp)
  101a36:	89 44 24 04          	mov    %eax,0x4(%esp)
  101a3a:	c7 04 24 c4 59 10 00 	movl   $0x1059c4,(%esp)
  101a41:	e8 be 31 00 00       	call   104c04 <cprintf>
	        c->id, tf->cs, tf->eip);
	    	trap_return(tf); // Note: no EOI (see Local APIC manual)
  101a46:	8b 45 08             	mov    0x8(%ebp),%eax
  101a49:	89 04 24             	mov    %eax,(%esp)
  101a4c:	e8 af 04 00 00       	call   101f00 <trap_return>
	    	break;
	}    	
	
	// If we panic while holding the console lock,
	// release it so we don't get into a recursive panic that way.
	if (spinlock_holding(&cons_lock))
  101a51:	c7 04 24 a0 02 11 00 	movl   $0x1102a0,(%esp)
  101a58:	e8 35 0a 00 00       	call   102492 <spinlock_holding>
  101a5d:	85 c0                	test   %eax,%eax
  101a5f:	74 0c                	je     101a6d <trap+0x18d>
		spinlock_release(&cons_lock);
  101a61:	c7 04 24 a0 02 11 00 	movl   $0x1102a0,(%esp)
  101a68:	e8 cb 09 00 00       	call   102438 <spinlock_release>
	trap_print(tf);
  101a6d:	8b 45 08             	mov    0x8(%ebp),%eax
  101a70:	89 04 24             	mov    %eax,(%esp)
  101a73:	e8 5a fd ff ff       	call   1017d2 <trap_print>
	panic("unhandled trap");
  101a78:	c7 44 24 08 e8 59 10 	movl   $0x1059e8,0x8(%esp)
  101a7f:	00 
  101a80:	c7 44 24 04 c3 00 00 	movl   $0xc3,0x4(%esp)
  101a87:	00 
  101a88:	c7 04 24 a6 59 10 00 	movl   $0x1059a6,(%esp)
  101a8f:	e8 30 ea ff ff       	call   1004c4 <debug_panic>

00101a94 <trap_check_recover>:

// Helper function for trap_check_recover(), below:
// handles "anticipated" traps by simply resuming at a new EIP.
static void gcc_noreturn
trap_check_recover(trapframe *tf, void *recoverdata)
{
  101a94:	55                   	push   %ebp
  101a95:	89 e5                	mov    %esp,%ebp
  101a97:	83 ec 28             	sub    $0x28,%esp
	trap_check_args *args = recoverdata;
  101a9a:	8b 45 0c             	mov    0xc(%ebp),%eax
  101a9d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	tf->eip = (uint32_t) args->reip;	// Use recovery EIP on return
  101aa0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101aa3:	8b 00                	mov    (%eax),%eax
  101aa5:	89 c2                	mov    %eax,%edx
  101aa7:	8b 45 08             	mov    0x8(%ebp),%eax
  101aaa:	89 50 38             	mov    %edx,0x38(%eax)
	args->trapno = tf->trapno;		// Return trap number
  101aad:	8b 45 08             	mov    0x8(%ebp),%eax
  101ab0:	8b 40 30             	mov    0x30(%eax),%eax
  101ab3:	89 c2                	mov    %eax,%edx
  101ab5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101ab8:	89 50 04             	mov    %edx,0x4(%eax)
	trap_return(tf);
  101abb:	8b 45 08             	mov    0x8(%ebp),%eax
  101abe:	89 04 24             	mov    %eax,(%esp)
  101ac1:	e8 3a 04 00 00       	call   101f00 <trap_return>

00101ac6 <trap_check_kernel>:

// Check for correct handling of traps from kernel mode.
// Called on the boot CPU after trap_init() and trap_setup().
void
trap_check_kernel(void)
{
  101ac6:	55                   	push   %ebp
  101ac7:	89 e5                	mov    %esp,%ebp
  101ac9:	53                   	push   %ebx
  101aca:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  101acd:	66 8c cb             	mov    %cs,%bx
  101ad0:	66 89 5d f2          	mov    %bx,-0xe(%ebp)
        return cs;
  101ad4:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
	assert((read_cs() & 3) == 0);	// better be in kernel mode!
  101ad8:	0f b7 c0             	movzwl %ax,%eax
  101adb:	83 e0 03             	and    $0x3,%eax
  101ade:	85 c0                	test   %eax,%eax
  101ae0:	74 24                	je     101b06 <trap_check_kernel+0x40>
  101ae2:	c7 44 24 0c c4 5a 10 	movl   $0x105ac4,0xc(%esp)
  101ae9:	00 
  101aea:	c7 44 24 08 36 58 10 	movl   $0x105836,0x8(%esp)
  101af1:	00 
  101af2:	c7 44 24 04 d7 00 00 	movl   $0xd7,0x4(%esp)
  101af9:	00 
  101afa:	c7 04 24 a6 59 10 00 	movl   $0x1059a6,(%esp)
  101b01:	e8 be e9 ff ff       	call   1004c4 <debug_panic>

	cpu *c = cpu_cur();
  101b06:	e8 69 f9 ff ff       	call   101474 <cpu_cur>
  101b0b:	89 45 f4             	mov    %eax,-0xc(%ebp)
	c->recover = trap_check_recover;
  101b0e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101b11:	c7 80 a0 00 00 00 94 	movl   $0x101a94,0xa0(%eax)
  101b18:	1a 10 00 
	trap_check(&c->recoverdata);
  101b1b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101b1e:	05 a4 00 00 00       	add    $0xa4,%eax
  101b23:	89 04 24             	mov    %eax,(%esp)
  101b26:	e8 a3 00 00 00       	call   101bce <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  101b2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101b2e:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  101b35:	00 00 00 

	cprintf("trap_check_kernel() succeeded!\n");
  101b38:	c7 04 24 dc 5a 10 00 	movl   $0x105adc,(%esp)
  101b3f:	e8 c0 30 00 00       	call   104c04 <cprintf>
}
  101b44:	83 c4 24             	add    $0x24,%esp
  101b47:	5b                   	pop    %ebx
  101b48:	5d                   	pop    %ebp
  101b49:	c3                   	ret    

00101b4a <trap_check_user>:
// Called from user() in kern/init.c, only in lab 1.
// We assume the "current cpu" is always the boot cpu;
// this true only because lab 1 doesn't start any other CPUs.
void
trap_check_user(void)
{
  101b4a:	55                   	push   %ebp
  101b4b:	89 e5                	mov    %esp,%ebp
  101b4d:	53                   	push   %ebx
  101b4e:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  101b51:	66 8c cb             	mov    %cs,%bx
  101b54:	66 89 5d f2          	mov    %bx,-0xe(%ebp)
        return cs;
  101b58:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
	assert((read_cs() & 3) == 3);	// better be in user mode!
  101b5c:	0f b7 c0             	movzwl %ax,%eax
  101b5f:	83 e0 03             	and    $0x3,%eax
  101b62:	83 f8 03             	cmp    $0x3,%eax
  101b65:	74 24                	je     101b8b <trap_check_user+0x41>
  101b67:	c7 44 24 0c fc 5a 10 	movl   $0x105afc,0xc(%esp)
  101b6e:	00 
  101b6f:	c7 44 24 08 36 58 10 	movl   $0x105836,0x8(%esp)
  101b76:	00 
  101b77:	c7 44 24 04 e8 00 00 	movl   $0xe8,0x4(%esp)
  101b7e:	00 
  101b7f:	c7 04 24 a6 59 10 00 	movl   $0x1059a6,(%esp)
  101b86:	e8 39 e9 ff ff       	call   1004c4 <debug_panic>

	cpu *c = &cpu_boot;	// cpu_cur doesn't work from user mode!
  101b8b:	c7 45 f4 00 90 10 00 	movl   $0x109000,-0xc(%ebp)
	c->recover = trap_check_recover;
  101b92:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101b95:	c7 80 a0 00 00 00 94 	movl   $0x101a94,0xa0(%eax)
  101b9c:	1a 10 00 
	trap_check(&c->recoverdata);
  101b9f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101ba2:	05 a4 00 00 00       	add    $0xa4,%eax
  101ba7:	89 04 24             	mov    %eax,(%esp)
  101baa:	e8 1f 00 00 00       	call   101bce <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  101baf:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101bb2:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  101bb9:	00 00 00 

	cprintf("trap_check_user() succeeded!\n");
  101bbc:	c7 04 24 11 5b 10 00 	movl   $0x105b11,(%esp)
  101bc3:	e8 3c 30 00 00       	call   104c04 <cprintf>
}
  101bc8:	83 c4 24             	add    $0x24,%esp
  101bcb:	5b                   	pop    %ebx
  101bcc:	5d                   	pop    %ebp
  101bcd:	c3                   	ret    

00101bce <trap_check>:
void after_priv();

// Multi-purpose trap checking function.
void
trap_check(void **argsp)
{
  101bce:	55                   	push   %ebp
  101bcf:	89 e5                	mov    %esp,%ebp
  101bd1:	57                   	push   %edi
  101bd2:	56                   	push   %esi
  101bd3:	53                   	push   %ebx
  101bd4:	83 ec 3c             	sub    $0x3c,%esp
	volatile int cookie = 0xfeedface;
  101bd7:	c7 45 e0 ce fa ed fe 	movl   $0xfeedface,-0x20(%ebp)
	volatile trap_check_args args;
	*argsp = (void*)&args;	// provide args needed for trap recovery
  101bde:	8b 45 08             	mov    0x8(%ebp),%eax
  101be1:	8d 55 d8             	lea    -0x28(%ebp),%edx
  101be4:	89 10                	mov    %edx,(%eax)

	// Try a divide by zero trap.
	// Be careful when using && to take the address of a label:
	// some versions of GCC (4.4.2 at least) will incorrectly try to
	// eliminate code it thinks is _only_ reachable via such a pointer.
	args.reip = after_div0;
  101be6:	c7 45 d8 f4 1b 10 00 	movl   $0x101bf4,-0x28(%ebp)
	asm volatile("div %0,%0; after_div0:" : : "r" (0));
  101bed:	b8 00 00 00 00       	mov    $0x0,%eax
  101bf2:	f7 f0                	div    %eax

00101bf4 <after_div0>:
	assert(args.trapno == T_DIVIDE);
  101bf4:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101bf7:	85 c0                	test   %eax,%eax
  101bf9:	74 24                	je     101c1f <after_div0+0x2b>
  101bfb:	c7 44 24 0c 2f 5b 10 	movl   $0x105b2f,0xc(%esp)
  101c02:	00 
  101c03:	c7 44 24 08 36 58 10 	movl   $0x105836,0x8(%esp)
  101c0a:	00 
  101c0b:	c7 44 24 04 08 01 00 	movl   $0x108,0x4(%esp)
  101c12:	00 
  101c13:	c7 04 24 a6 59 10 00 	movl   $0x1059a6,(%esp)
  101c1a:	e8 a5 e8 ff ff       	call   1004c4 <debug_panic>

	// Make sure we got our correct stack back with us.
	// The asm ensures gcc uses ebp/esp to get the cookie.
	asm volatile("" : : : "eax","ebx","ecx","edx","esi","edi");
	assert(cookie == 0xfeedface);
  101c1f:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101c22:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  101c27:	74 24                	je     101c4d <after_div0+0x59>
  101c29:	c7 44 24 0c 47 5b 10 	movl   $0x105b47,0xc(%esp)
  101c30:	00 
  101c31:	c7 44 24 08 36 58 10 	movl   $0x105836,0x8(%esp)
  101c38:	00 
  101c39:	c7 44 24 04 0d 01 00 	movl   $0x10d,0x4(%esp)
  101c40:	00 
  101c41:	c7 04 24 a6 59 10 00 	movl   $0x1059a6,(%esp)
  101c48:	e8 77 e8 ff ff       	call   1004c4 <debug_panic>

	// Breakpoint trap
	args.reip = after_breakpoint;
  101c4d:	c7 45 d8 55 1c 10 00 	movl   $0x101c55,-0x28(%ebp)
	asm volatile("int3; after_breakpoint:");
  101c54:	cc                   	int3   

00101c55 <after_breakpoint>:
	assert(args.trapno == T_BRKPT);
  101c55:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101c58:	83 f8 03             	cmp    $0x3,%eax
  101c5b:	74 24                	je     101c81 <after_breakpoint+0x2c>
  101c5d:	c7 44 24 0c 5c 5b 10 	movl   $0x105b5c,0xc(%esp)
  101c64:	00 
  101c65:	c7 44 24 08 36 58 10 	movl   $0x105836,0x8(%esp)
  101c6c:	00 
  101c6d:	c7 44 24 04 12 01 00 	movl   $0x112,0x4(%esp)
  101c74:	00 
  101c75:	c7 04 24 a6 59 10 00 	movl   $0x1059a6,(%esp)
  101c7c:	e8 43 e8 ff ff       	call   1004c4 <debug_panic>

	// Overflow trap
	args.reip = after_overflow;
  101c81:	c7 45 d8 90 1c 10 00 	movl   $0x101c90,-0x28(%ebp)
	asm volatile("addl %0,%0; into; after_overflow:" : : "r" (0x70000000));
  101c88:	b8 00 00 00 70       	mov    $0x70000000,%eax
  101c8d:	01 c0                	add    %eax,%eax
  101c8f:	ce                   	into   

00101c90 <after_overflow>:
	assert(args.trapno == T_OFLOW);
  101c90:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101c93:	83 f8 04             	cmp    $0x4,%eax
  101c96:	74 24                	je     101cbc <after_overflow+0x2c>
  101c98:	c7 44 24 0c 73 5b 10 	movl   $0x105b73,0xc(%esp)
  101c9f:	00 
  101ca0:	c7 44 24 08 36 58 10 	movl   $0x105836,0x8(%esp)
  101ca7:	00 
  101ca8:	c7 44 24 04 17 01 00 	movl   $0x117,0x4(%esp)
  101caf:	00 
  101cb0:	c7 04 24 a6 59 10 00 	movl   $0x1059a6,(%esp)
  101cb7:	e8 08 e8 ff ff       	call   1004c4 <debug_panic>

	// Bounds trap
	args.reip = after_bound;
  101cbc:	c7 45 d8 d9 1c 10 00 	movl   $0x101cd9,-0x28(%ebp)
	int bounds[2] = { 1, 3 };
  101cc3:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
  101cca:	c7 45 d4 03 00 00 00 	movl   $0x3,-0x2c(%ebp)
	asm volatile("boundl %0,%1; after_bound:" : : "r" (0), "m" (bounds[0]));
  101cd1:	b8 00 00 00 00       	mov    $0x0,%eax
  101cd6:	62 45 d0             	bound  %eax,-0x30(%ebp)

00101cd9 <after_bound>:
	assert(args.trapno == T_BOUND);
  101cd9:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101cdc:	83 f8 05             	cmp    $0x5,%eax
  101cdf:	74 24                	je     101d05 <after_bound+0x2c>
  101ce1:	c7 44 24 0c 8a 5b 10 	movl   $0x105b8a,0xc(%esp)
  101ce8:	00 
  101ce9:	c7 44 24 08 36 58 10 	movl   $0x105836,0x8(%esp)
  101cf0:	00 
  101cf1:	c7 44 24 04 1d 01 00 	movl   $0x11d,0x4(%esp)
  101cf8:	00 
  101cf9:	c7 04 24 a6 59 10 00 	movl   $0x1059a6,(%esp)
  101d00:	e8 bf e7 ff ff       	call   1004c4 <debug_panic>

	// Illegal instruction trap
	args.reip = after_illegal;
  101d05:	c7 45 d8 0e 1d 10 00 	movl   $0x101d0e,-0x28(%ebp)
	asm volatile("ud2; after_illegal:");	// guaranteed to be undefined
  101d0c:	0f 0b                	ud2    

00101d0e <after_illegal>:
	assert(args.trapno == T_ILLOP);
  101d0e:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101d11:	83 f8 06             	cmp    $0x6,%eax
  101d14:	74 24                	je     101d3a <after_illegal+0x2c>
  101d16:	c7 44 24 0c a1 5b 10 	movl   $0x105ba1,0xc(%esp)
  101d1d:	00 
  101d1e:	c7 44 24 08 36 58 10 	movl   $0x105836,0x8(%esp)
  101d25:	00 
  101d26:	c7 44 24 04 22 01 00 	movl   $0x122,0x4(%esp)
  101d2d:	00 
  101d2e:	c7 04 24 a6 59 10 00 	movl   $0x1059a6,(%esp)
  101d35:	e8 8a e7 ff ff       	call   1004c4 <debug_panic>

	// General protection fault due to invalid segment load
	args.reip = after_gpfault;
  101d3a:	c7 45 d8 48 1d 10 00 	movl   $0x101d48,-0x28(%ebp)
	asm volatile("movl %0,%%fs; after_gpfault:" : : "r" (-1));
  101d41:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  101d46:	8e e0                	mov    %eax,%fs

00101d48 <after_gpfault>:
	assert(args.trapno == T_GPFLT);
  101d48:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101d4b:	83 f8 0d             	cmp    $0xd,%eax
  101d4e:	74 24                	je     101d74 <after_gpfault+0x2c>
  101d50:	c7 44 24 0c b8 5b 10 	movl   $0x105bb8,0xc(%esp)
  101d57:	00 
  101d58:	c7 44 24 08 36 58 10 	movl   $0x105836,0x8(%esp)
  101d5f:	00 
  101d60:	c7 44 24 04 27 01 00 	movl   $0x127,0x4(%esp)
  101d67:	00 
  101d68:	c7 04 24 a6 59 10 00 	movl   $0x1059a6,(%esp)
  101d6f:	e8 50 e7 ff ff       	call   1004c4 <debug_panic>

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  101d74:	66 8c cb             	mov    %cs,%bx
  101d77:	66 89 5d e6          	mov    %bx,-0x1a(%ebp)
        return cs;
  101d7b:	0f b7 45 e6          	movzwl -0x1a(%ebp),%eax

	// General protection fault due to privilege violation
	if (read_cs() & 3) {
  101d7f:	0f b7 c0             	movzwl %ax,%eax
  101d82:	83 e0 03             	and    $0x3,%eax
  101d85:	85 c0                	test   %eax,%eax
  101d87:	74 3a                	je     101dc3 <after_priv+0x2c>
		args.reip = after_priv;
  101d89:	c7 45 d8 97 1d 10 00 	movl   $0x101d97,-0x28(%ebp)
		asm volatile("lidt %0; after_priv:" : : "m" (idt_pd));
  101d90:	0f 01 1d 04 a0 10 00 	lidtl  0x10a004

00101d97 <after_priv>:
		assert(args.trapno == T_GPFLT);
  101d97:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101d9a:	83 f8 0d             	cmp    $0xd,%eax
  101d9d:	74 24                	je     101dc3 <after_priv+0x2c>
  101d9f:	c7 44 24 0c b8 5b 10 	movl   $0x105bb8,0xc(%esp)
  101da6:	00 
  101da7:	c7 44 24 08 36 58 10 	movl   $0x105836,0x8(%esp)
  101dae:	00 
  101daf:	c7 44 24 04 2d 01 00 	movl   $0x12d,0x4(%esp)
  101db6:	00 
  101db7:	c7 04 24 a6 59 10 00 	movl   $0x1059a6,(%esp)
  101dbe:	e8 01 e7 ff ff       	call   1004c4 <debug_panic>
	}

	// Make sure our stack cookie is still with us
	assert(cookie == 0xfeedface);
  101dc3:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101dc6:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  101dcb:	74 24                	je     101df1 <after_priv+0x5a>
  101dcd:	c7 44 24 0c 47 5b 10 	movl   $0x105b47,0xc(%esp)
  101dd4:	00 
  101dd5:	c7 44 24 08 36 58 10 	movl   $0x105836,0x8(%esp)
  101ddc:	00 
  101ddd:	c7 44 24 04 31 01 00 	movl   $0x131,0x4(%esp)
  101de4:	00 
  101de5:	c7 04 24 a6 59 10 00 	movl   $0x1059a6,(%esp)
  101dec:	e8 d3 e6 ff ff       	call   1004c4 <debug_panic>

	*argsp = NULL;	// recovery mechanism not needed anymore
  101df1:	8b 45 08             	mov    0x8(%ebp),%eax
  101df4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
  101dfa:	83 c4 3c             	add    $0x3c,%esp
  101dfd:	5b                   	pop    %ebx
  101dfe:	5e                   	pop    %esi
  101dff:	5f                   	pop    %edi
  101e00:	5d                   	pop    %ebp
  101e01:	c3                   	ret    
  101e02:	90                   	nop
  101e03:	90                   	nop
  101e04:	90                   	nop
  101e05:	90                   	nop
  101e06:	90                   	nop
  101e07:	90                   	nop
  101e08:	90                   	nop
  101e09:	90                   	nop
  101e0a:	90                   	nop
  101e0b:	90                   	nop
  101e0c:	90                   	nop
  101e0d:	90                   	nop
  101e0e:	90                   	nop
  101e0f:	90                   	nop

00101e10 <vector0>:
//TRAPHANDLER_NOEC(trap_ltimer,  T_LTIMER)
//TRAPHANDLER_NOEC(trap_lerror,  T_LERROR)
//TRAPHANDLER	(trap_default, T_DEFAULT)
//TRAPHANDLER	(trap_icnt,    T_ICNT)

TRAPHANDLER_NOEC(vector0,0)		// divide error
  101e10:	6a 00                	push   $0x0
  101e12:	6a 00                	push   $0x0
  101e14:	e9 c7 00 00 00       	jmp    101ee0 <_alltraps>
  101e19:	90                   	nop

00101e1a <vector1>:
TRAPHANDLER_NOEC(vector1,1)		// debug exception
  101e1a:	6a 00                	push   $0x0
  101e1c:	6a 01                	push   $0x1
  101e1e:	e9 bd 00 00 00       	jmp    101ee0 <_alltraps>
  101e23:	90                   	nop

00101e24 <vector2>:
TRAPHANDLER_NOEC(vector2,2)		// non-maskable interrupt
  101e24:	6a 00                	push   $0x0
  101e26:	6a 02                	push   $0x2
  101e28:	e9 b3 00 00 00       	jmp    101ee0 <_alltraps>
  101e2d:	90                   	nop

00101e2e <vector3>:
TRAPHANDLER_NOEC(vector3,3)		// breakpoint
  101e2e:	6a 00                	push   $0x0
  101e30:	6a 03                	push   $0x3
  101e32:	e9 a9 00 00 00       	jmp    101ee0 <_alltraps>
  101e37:	90                   	nop

00101e38 <vector4>:
TRAPHANDLER_NOEC(vector4,4)		// overflow
  101e38:	6a 00                	push   $0x0
  101e3a:	6a 04                	push   $0x4
  101e3c:	e9 9f 00 00 00       	jmp    101ee0 <_alltraps>
  101e41:	90                   	nop

00101e42 <vector5>:
TRAPHANDLER_NOEC(vector5,5)		// bounds check
  101e42:	6a 00                	push   $0x0
  101e44:	6a 05                	push   $0x5
  101e46:	e9 95 00 00 00       	jmp    101ee0 <_alltraps>
  101e4b:	90                   	nop

00101e4c <vector6>:
TRAPHANDLER_NOEC(vector6,6)		// illegal opcode
  101e4c:	6a 00                	push   $0x0
  101e4e:	6a 06                	push   $0x6
  101e50:	e9 8b 00 00 00       	jmp    101ee0 <_alltraps>
  101e55:	90                   	nop

00101e56 <vector7>:
TRAPHANDLER_NOEC(vector7,7)		// device not available 
  101e56:	6a 00                	push   $0x0
  101e58:	6a 07                	push   $0x7
  101e5a:	e9 81 00 00 00       	jmp    101ee0 <_alltraps>
  101e5f:	90                   	nop

00101e60 <vector8>:
TRAPHANDLER(vector8,8)			// double fault
  101e60:	6a 08                	push   $0x8
  101e62:	e9 79 00 00 00       	jmp    101ee0 <_alltraps>
  101e67:	90                   	nop

00101e68 <vector9>:
TRAPHANDLER_NOEC(vector9,9)		// reserved (not generated by recent processors)
  101e68:	6a 00                	push   $0x0
  101e6a:	6a 09                	push   $0x9
  101e6c:	e9 6f 00 00 00       	jmp    101ee0 <_alltraps>
  101e71:	90                   	nop

00101e72 <vector10>:
TRAPHANDLER(vector10,10)		// invalid task switch segment
  101e72:	6a 0a                	push   $0xa
  101e74:	e9 67 00 00 00       	jmp    101ee0 <_alltraps>
  101e79:	90                   	nop

00101e7a <vector11>:
TRAPHANDLER(vector11,11)		// segment not present
  101e7a:	6a 0b                	push   $0xb
  101e7c:	e9 5f 00 00 00       	jmp    101ee0 <_alltraps>
  101e81:	90                   	nop

00101e82 <vector12>:
TRAPHANDLER(vector12,12)		// stack exception
  101e82:	6a 0c                	push   $0xc
  101e84:	e9 57 00 00 00       	jmp    101ee0 <_alltraps>
  101e89:	90                   	nop

00101e8a <vector13>:
TRAPHANDLER(vector13,13)		// general protection fault
  101e8a:	6a 0d                	push   $0xd
  101e8c:	e9 4f 00 00 00       	jmp    101ee0 <_alltraps>
  101e91:	90                   	nop

00101e92 <vector14>:
TRAPHANDLER(vector14,14)		// page fault
  101e92:	6a 0e                	push   $0xe
  101e94:	e9 47 00 00 00       	jmp    101ee0 <_alltraps>
  101e99:	90                   	nop

00101e9a <vector15>:
TRAPHANDLER_NOEC(vector15,15)		// reserved
  101e9a:	6a 00                	push   $0x0
  101e9c:	6a 0f                	push   $0xf
  101e9e:	e9 3d 00 00 00       	jmp    101ee0 <_alltraps>
  101ea3:	90                   	nop

00101ea4 <vector16>:
TRAPHANDLER_NOEC(vector16,16)		// floating point error
  101ea4:	6a 00                	push   $0x0
  101ea6:	6a 10                	push   $0x10
  101ea8:	e9 33 00 00 00       	jmp    101ee0 <_alltraps>
  101ead:	90                   	nop

00101eae <vector17>:
TRAPHANDLER(vector17,17)		// alignment check
  101eae:	6a 11                	push   $0x11
  101eb0:	e9 2b 00 00 00       	jmp    101ee0 <_alltraps>
  101eb5:	90                   	nop

00101eb6 <vector18>:
TRAPHANDLER_NOEC(vector18,18)		// machine check
  101eb6:	6a 00                	push   $0x0
  101eb8:	6a 12                	push   $0x12
  101eba:	e9 21 00 00 00       	jmp    101ee0 <_alltraps>
  101ebf:	90                   	nop

00101ec0 <vector19>:
TRAPHANDLER_NOEC(vector19,19)		// SIMD floating point error
  101ec0:	6a 00                	push   $0x0
  101ec2:	6a 13                	push   $0x13
  101ec4:	e9 17 00 00 00       	jmp    101ee0 <_alltraps>
  101ec9:	90                   	nop

00101eca <vector30>:
TRAPHANDLER(vector30,30)		// 
  101eca:	6a 1e                	push   $0x1e
  101ecc:	e9 0f 00 00 00       	jmp    101ee0 <_alltraps>
  101ed1:	90                   	nop

00101ed2 <vector48>:
TRAPHANDLER_NOEC(vector48,48)
  101ed2:	6a 00                	push   $0x0
  101ed4:	6a 30                	push   $0x30
  101ed6:	e9 05 00 00 00       	jmp    101ee0 <_alltraps>
  101edb:	90                   	nop
  101edc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

00101ee0 <_alltraps>:
 */
.globl	_alltraps
.type	_alltraps,@function
.p2align 4, 0x90
_alltraps:
	pushl %ds
  101ee0:	1e                   	push   %ds
	pushl %es
  101ee1:	06                   	push   %es
	pushl %fs
  101ee2:	0f a0                	push   %fs
	pushl %gs
  101ee4:	0f a8                	push   %gs
	pushal
  101ee6:	60                   	pusha  

	movw $CPU_GDT_KDATA, %ax
  101ee7:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
  101eeb:	8e d8                	mov    %eax,%ds
	movw %ax, %es
  101eed:	8e c0                	mov    %eax,%es
	//there is no SEG_KCPU in PIOS ,
	//so do not need to reset %fs , %gs

	pushl %esp //oesp
  101eef:	54                   	push   %esp
	call trap
  101ef0:	e8 eb f9 ff ff       	call   1018e0 <trap>
  101ef5:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  101ef9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00101f00 <trap_return>:
.p2align 4, 0x90		/* 16-byte alignment, nop filled */
trap_return:
/*
 * Lab 1: Your code here for trap_return
 */ //1: jmp 1b // just spin
	movl 4(%esp), %esp
  101f00:	8b 64 24 04          	mov    0x4(%esp),%esp
	//this step has been done in _alltrap
	//popl %esp
	popal 
  101f04:	61                   	popa   
	popl %gs
  101f05:	0f a9                	pop    %gs
	popl %fs
  101f07:	0f a1                	pop    %fs
	popl %es
  101f09:	07                   	pop    %es
	popl %ds
  101f0a:	1f                   	pop    %ds
	addl $8, %esp
  101f0b:	83 c4 08             	add    $0x8,%esp
	iret
  101f0e:	cf                   	iret   
  101f0f:	90                   	nop

00101f10 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  101f10:	55                   	push   %ebp
  101f11:	89 e5                	mov    %esp,%ebp
  101f13:	53                   	push   %ebx
  101f14:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  101f17:	89 e3                	mov    %esp,%ebx
  101f19:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  101f1c:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  101f1f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  101f22:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101f25:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  101f2a:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  101f2d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101f30:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  101f36:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  101f3b:	74 24                	je     101f61 <cpu_cur+0x51>
  101f3d:	c7 44 24 0c 70 5d 10 	movl   $0x105d70,0xc(%esp)
  101f44:	00 
  101f45:	c7 44 24 08 86 5d 10 	movl   $0x105d86,0x8(%esp)
  101f4c:	00 
  101f4d:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  101f54:	00 
  101f55:	c7 04 24 9b 5d 10 00 	movl   $0x105d9b,(%esp)
  101f5c:	e8 63 e5 ff ff       	call   1004c4 <debug_panic>
	return c;
  101f61:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  101f64:	83 c4 24             	add    $0x24,%esp
  101f67:	5b                   	pop    %ebx
  101f68:	5d                   	pop    %ebp
  101f69:	c3                   	ret    

00101f6a <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  101f6a:	55                   	push   %ebp
  101f6b:	89 e5                	mov    %esp,%ebp
  101f6d:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  101f70:	e8 9b ff ff ff       	call   101f10 <cpu_cur>
  101f75:	3d 00 90 10 00       	cmp    $0x109000,%eax
  101f7a:	0f 94 c0             	sete   %al
  101f7d:	0f b6 c0             	movzbl %al,%eax
}
  101f80:	c9                   	leave  
  101f81:	c3                   	ret    

00101f82 <sum>:
volatile struct ioapic *ioapic;


static uint8_t
sum(uint8_t * addr, int len)
{
  101f82:	55                   	push   %ebp
  101f83:	89 e5                	mov    %esp,%ebp
  101f85:	83 ec 10             	sub    $0x10,%esp
	int i, sum;

	sum = 0;
  101f88:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
	for (i = 0; i < len; i++)
  101f8f:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  101f96:	eb 15                	jmp    101fad <sum+0x2b>
		sum += addr[i];
  101f98:	8b 55 fc             	mov    -0x4(%ebp),%edx
  101f9b:	8b 45 08             	mov    0x8(%ebp),%eax
  101f9e:	01 d0                	add    %edx,%eax
  101fa0:	0f b6 00             	movzbl (%eax),%eax
  101fa3:	0f b6 c0             	movzbl %al,%eax
  101fa6:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uint8_t * addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
  101fa9:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  101fad:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101fb0:	3b 45 0c             	cmp    0xc(%ebp),%eax
  101fb3:	7c e3                	jl     101f98 <sum+0x16>
		sum += addr[i];
	return sum;
  101fb5:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
  101fb8:	c9                   	leave  
  101fb9:	c3                   	ret    

00101fba <mpsearch1>:

//Look for an MP structure in the len bytes at addr.
static struct mp *
mpsearch1(uint8_t * addr, int len)
{
  101fba:	55                   	push   %ebp
  101fbb:	89 e5                	mov    %esp,%ebp
  101fbd:	83 ec 28             	sub    $0x28,%esp
	uint8_t *e, *p;

	e = addr + len;
  101fc0:	8b 55 0c             	mov    0xc(%ebp),%edx
  101fc3:	8b 45 08             	mov    0x8(%ebp),%eax
  101fc6:	01 d0                	add    %edx,%eax
  101fc8:	89 45 f0             	mov    %eax,-0x10(%ebp)
	for (p = addr; p < e; p += sizeof(struct mp))
  101fcb:	8b 45 08             	mov    0x8(%ebp),%eax
  101fce:	89 45 f4             	mov    %eax,-0xc(%ebp)
  101fd1:	eb 3f                	jmp    102012 <mpsearch1+0x58>
		if (memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
  101fd3:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  101fda:	00 
  101fdb:	c7 44 24 04 a8 5d 10 	movl   $0x105da8,0x4(%esp)
  101fe2:	00 
  101fe3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101fe6:	89 04 24             	mov    %eax,(%esp)
  101fe9:	e8 64 2f 00 00       	call   104f52 <memcmp>
  101fee:	85 c0                	test   %eax,%eax
  101ff0:	75 1c                	jne    10200e <mpsearch1+0x54>
  101ff2:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
  101ff9:	00 
  101ffa:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101ffd:	89 04 24             	mov    %eax,(%esp)
  102000:	e8 7d ff ff ff       	call   101f82 <sum>
  102005:	84 c0                	test   %al,%al
  102007:	75 05                	jne    10200e <mpsearch1+0x54>
			return (struct mp *) p;
  102009:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10200c:	eb 11                	jmp    10201f <mpsearch1+0x65>
mpsearch1(uint8_t * addr, int len)
{
	uint8_t *e, *p;

	e = addr + len;
	for (p = addr; p < e; p += sizeof(struct mp))
  10200e:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
  102012:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102015:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  102018:	72 b9                	jb     101fd3 <mpsearch1+0x19>
		if (memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
			return (struct mp *) p;
	return 0;
  10201a:	b8 00 00 00 00       	mov    $0x0,%eax
}
  10201f:	c9                   	leave  
  102020:	c3                   	ret    

00102021 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp *
mpsearch(void)
{
  102021:	55                   	push   %ebp
  102022:	89 e5                	mov    %esp,%ebp
  102024:	83 ec 28             	sub    $0x28,%esp
	uint8_t          *bda;
	uint32_t            p;
	struct mp      *mp;

	bda = (uint8_t *) 0x400;
  102027:	c7 45 f4 00 04 00 00 	movl   $0x400,-0xc(%ebp)
	if ((p = ((bda[0x0F] << 8) | bda[0x0E]) << 4)) {
  10202e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102031:	83 c0 0f             	add    $0xf,%eax
  102034:	0f b6 00             	movzbl (%eax),%eax
  102037:	0f b6 c0             	movzbl %al,%eax
  10203a:	89 c2                	mov    %eax,%edx
  10203c:	c1 e2 08             	shl    $0x8,%edx
  10203f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102042:	83 c0 0e             	add    $0xe,%eax
  102045:	0f b6 00             	movzbl (%eax),%eax
  102048:	0f b6 c0             	movzbl %al,%eax
  10204b:	09 d0                	or     %edx,%eax
  10204d:	c1 e0 04             	shl    $0x4,%eax
  102050:	89 45 f0             	mov    %eax,-0x10(%ebp)
  102053:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  102057:	74 21                	je     10207a <mpsearch+0x59>
		if ((mp = mpsearch1((uint8_t *) p, 1024)))
  102059:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10205c:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
  102063:	00 
  102064:	89 04 24             	mov    %eax,(%esp)
  102067:	e8 4e ff ff ff       	call   101fba <mpsearch1>
  10206c:	89 45 ec             	mov    %eax,-0x14(%ebp)
  10206f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  102073:	74 50                	je     1020c5 <mpsearch+0xa4>
			return mp;
  102075:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102078:	eb 5f                	jmp    1020d9 <mpsearch+0xb8>
	} else {
		p = ((bda[0x14] << 8) | bda[0x13]) * 1024;
  10207a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10207d:	83 c0 14             	add    $0x14,%eax
  102080:	0f b6 00             	movzbl (%eax),%eax
  102083:	0f b6 c0             	movzbl %al,%eax
  102086:	89 c2                	mov    %eax,%edx
  102088:	c1 e2 08             	shl    $0x8,%edx
  10208b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10208e:	83 c0 13             	add    $0x13,%eax
  102091:	0f b6 00             	movzbl (%eax),%eax
  102094:	0f b6 c0             	movzbl %al,%eax
  102097:	09 d0                	or     %edx,%eax
  102099:	c1 e0 0a             	shl    $0xa,%eax
  10209c:	89 45 f0             	mov    %eax,-0x10(%ebp)
		if ((mp = mpsearch1((uint8_t *) p - 1024, 1024)))
  10209f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1020a2:	2d 00 04 00 00       	sub    $0x400,%eax
  1020a7:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
  1020ae:	00 
  1020af:	89 04 24             	mov    %eax,(%esp)
  1020b2:	e8 03 ff ff ff       	call   101fba <mpsearch1>
  1020b7:	89 45 ec             	mov    %eax,-0x14(%ebp)
  1020ba:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  1020be:	74 05                	je     1020c5 <mpsearch+0xa4>
			return mp;
  1020c0:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1020c3:	eb 14                	jmp    1020d9 <mpsearch+0xb8>
	}
	return mpsearch1((uint8_t *) 0xF0000, 0x10000);
  1020c5:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  1020cc:	00 
  1020cd:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
  1020d4:	e8 e1 fe ff ff       	call   101fba <mpsearch1>
}
  1020d9:	c9                   	leave  
  1020da:	c3                   	ret    

001020db <mpconfig>:
// don 't accept the default configurations (physaddr == 0).
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf *
mpconfig(struct mp **pmp) {
  1020db:	55                   	push   %ebp
  1020dc:	89 e5                	mov    %esp,%ebp
  1020de:	83 ec 28             	sub    $0x28,%esp
	struct mpconf  *conf;
	struct mp      *mp;

	if ((mp = mpsearch()) == 0 || mp->physaddr == 0)
  1020e1:	e8 3b ff ff ff       	call   102021 <mpsearch>
  1020e6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1020e9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1020ed:	74 0a                	je     1020f9 <mpconfig+0x1e>
  1020ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1020f2:	8b 40 04             	mov    0x4(%eax),%eax
  1020f5:	85 c0                	test   %eax,%eax
  1020f7:	75 07                	jne    102100 <mpconfig+0x25>
		return 0;
  1020f9:	b8 00 00 00 00       	mov    $0x0,%eax
  1020fe:	eb 7b                	jmp    10217b <mpconfig+0xa0>
	conf = (struct mpconf *) mp->physaddr;
  102100:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102103:	8b 40 04             	mov    0x4(%eax),%eax
  102106:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (memcmp(conf, "PCMP", 4) != 0)
  102109:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  102110:	00 
  102111:	c7 44 24 04 ad 5d 10 	movl   $0x105dad,0x4(%esp)
  102118:	00 
  102119:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10211c:	89 04 24             	mov    %eax,(%esp)
  10211f:	e8 2e 2e 00 00       	call   104f52 <memcmp>
  102124:	85 c0                	test   %eax,%eax
  102126:	74 07                	je     10212f <mpconfig+0x54>
		return 0;
  102128:	b8 00 00 00 00       	mov    $0x0,%eax
  10212d:	eb 4c                	jmp    10217b <mpconfig+0xa0>
	if (conf->version != 1 && conf->version != 4)
  10212f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102132:	0f b6 40 06          	movzbl 0x6(%eax),%eax
  102136:	3c 01                	cmp    $0x1,%al
  102138:	74 12                	je     10214c <mpconfig+0x71>
  10213a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10213d:	0f b6 40 06          	movzbl 0x6(%eax),%eax
  102141:	3c 04                	cmp    $0x4,%al
  102143:	74 07                	je     10214c <mpconfig+0x71>
		return 0;
  102145:	b8 00 00 00 00       	mov    $0x0,%eax
  10214a:	eb 2f                	jmp    10217b <mpconfig+0xa0>
	if (sum((uint8_t *) conf, conf->length) != 0)
  10214c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10214f:	0f b7 40 04          	movzwl 0x4(%eax),%eax
  102153:	0f b7 c0             	movzwl %ax,%eax
  102156:	89 44 24 04          	mov    %eax,0x4(%esp)
  10215a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10215d:	89 04 24             	mov    %eax,(%esp)
  102160:	e8 1d fe ff ff       	call   101f82 <sum>
  102165:	84 c0                	test   %al,%al
  102167:	74 07                	je     102170 <mpconfig+0x95>
		return 0;
  102169:	b8 00 00 00 00       	mov    $0x0,%eax
  10216e:	eb 0b                	jmp    10217b <mpconfig+0xa0>
       *pmp = mp;
  102170:	8b 45 08             	mov    0x8(%ebp),%eax
  102173:	8b 55 f4             	mov    -0xc(%ebp),%edx
  102176:	89 10                	mov    %edx,(%eax)
	return conf;
  102178:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  10217b:	c9                   	leave  
  10217c:	c3                   	ret    

0010217d <mp_init>:

void
mp_init(void)
{
  10217d:	55                   	push   %ebp
  10217e:	89 e5                	mov    %esp,%ebp
  102180:	53                   	push   %ebx
  102181:	83 ec 64             	sub    $0x64,%esp
	struct mp      *mp;
	struct mpconf  *conf;
	struct mpproc  *proc;
	struct mpioapic *mpio;

	if (!cpu_onboot())	// only do once, on the boot CPU
  102184:	e8 e1 fd ff ff       	call   101f6a <cpu_onboot>
  102189:	85 c0                	test   %eax,%eax
  10218b:	0f 84 75 01 00 00    	je     102306 <mp_init+0x189>
		return;

	if ((conf = mpconfig(&mp)) == 0)
  102191:	8d 45 c4             	lea    -0x3c(%ebp),%eax
  102194:	89 04 24             	mov    %eax,(%esp)
  102197:	e8 3f ff ff ff       	call   1020db <mpconfig>
  10219c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10219f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  1021a3:	0f 84 5d 01 00 00    	je     102306 <mp_init+0x189>
		return; // Not a multiprocessor machine - just use boot CPU.

	ismp = 1;
  1021a9:	c7 05 90 03 31 00 01 	movl   $0x1,0x310390
  1021b0:	00 00 00 
	lapic = (uint32_t *) conf->lapicaddr;
  1021b3:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1021b6:	8b 40 24             	mov    0x24(%eax),%eax
  1021b9:	a3 8c 0a 31 00       	mov    %eax,0x310a8c
	for (p = (uint8_t *) (conf + 1), e = (uint8_t *) conf + conf->length;
  1021be:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1021c1:	83 c0 2c             	add    $0x2c,%eax
  1021c4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1021c7:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1021ca:	0f b7 40 04          	movzwl 0x4(%eax),%eax
  1021ce:	0f b7 d0             	movzwl %ax,%edx
  1021d1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1021d4:	01 d0                	add    %edx,%eax
  1021d6:	89 45 ec             	mov    %eax,-0x14(%ebp)
  1021d9:	e9 cc 00 00 00       	jmp    1022aa <mp_init+0x12d>
			p < e;) {
		switch (*p) {
  1021de:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1021e1:	0f b6 00             	movzbl (%eax),%eax
  1021e4:	0f b6 c0             	movzbl %al,%eax
  1021e7:	83 f8 04             	cmp    $0x4,%eax
  1021ea:	0f 87 90 00 00 00    	ja     102280 <mp_init+0x103>
  1021f0:	8b 04 85 e0 5d 10 00 	mov    0x105de0(,%eax,4),%eax
  1021f7:	ff e0                	jmp    *%eax
		case MPPROC:
			proc = (struct mpproc *) p;
  1021f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1021fc:	89 45 e8             	mov    %eax,-0x18(%ebp)
			p += sizeof(struct mpproc);
  1021ff:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
			if (!(proc->flags & MPENAB))
  102203:	8b 45 e8             	mov    -0x18(%ebp),%eax
  102206:	0f b6 40 03          	movzbl 0x3(%eax),%eax
  10220a:	0f b6 c0             	movzbl %al,%eax
  10220d:	83 e0 01             	and    $0x1,%eax
  102210:	85 c0                	test   %eax,%eax
  102212:	0f 84 91 00 00 00    	je     1022a9 <mp_init+0x12c>
				continue;	// processor disabled

			// Get a cpu struct and kernel stack for this CPU.
			cpu *c = (proc->flags & MPBOOT)
  102218:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10221b:	0f b6 40 03          	movzbl 0x3(%eax),%eax
  10221f:	0f b6 c0             	movzbl %al,%eax
  102222:	83 e0 02             	and    $0x2,%eax
					? &cpu_boot : cpu_alloc();
  102225:	85 c0                	test   %eax,%eax
  102227:	75 07                	jne    102230 <mp_init+0xb3>
  102229:	e8 d4 f0 ff ff       	call   101302 <cpu_alloc>
  10222e:	eb 05                	jmp    102235 <mp_init+0xb8>
  102230:	b8 00 90 10 00       	mov    $0x109000,%eax
			p += sizeof(struct mpproc);
			if (!(proc->flags & MPENAB))
				continue;	// processor disabled

			// Get a cpu struct and kernel stack for this CPU.
			cpu *c = (proc->flags & MPBOOT)
  102235:	89 45 e4             	mov    %eax,-0x1c(%ebp)
					? &cpu_boot : cpu_alloc();
			c->id = proc->apicid;
  102238:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10223b:	0f b6 50 01          	movzbl 0x1(%eax),%edx
  10223f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  102242:	88 90 ac 00 00 00    	mov    %dl,0xac(%eax)
			ncpu++;
  102248:	a1 94 03 31 00       	mov    0x310394,%eax
  10224d:	83 c0 01             	add    $0x1,%eax
  102250:	a3 94 03 31 00       	mov    %eax,0x310394
			continue;
  102255:	eb 53                	jmp    1022aa <mp_init+0x12d>
		case MPIOAPIC:
			mpio = (struct mpioapic *) p;
  102257:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10225a:	89 45 e0             	mov    %eax,-0x20(%ebp)
			p += sizeof(struct mpioapic);
  10225d:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
			ioapicid = mpio->apicno;
  102261:	8b 45 e0             	mov    -0x20(%ebp),%eax
  102264:	0f b6 40 01          	movzbl 0x1(%eax),%eax
  102268:	a2 88 03 31 00       	mov    %al,0x310388
			ioapic = (struct ioapic *) mpio->addr;
  10226d:	8b 45 e0             	mov    -0x20(%ebp),%eax
  102270:	8b 40 04             	mov    0x4(%eax),%eax
  102273:	a3 8c 03 31 00       	mov    %eax,0x31038c
			continue;
  102278:	eb 30                	jmp    1022aa <mp_init+0x12d>
		case MPBUS:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
  10227a:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
			continue;
  10227e:	eb 2a                	jmp    1022aa <mp_init+0x12d>
		default:
			panic("mpinit: unknown config type %x\n", *p);
  102280:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102283:	0f b6 00             	movzbl (%eax),%eax
  102286:	0f b6 c0             	movzbl %al,%eax
  102289:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10228d:	c7 44 24 08 b4 5d 10 	movl   $0x105db4,0x8(%esp)
  102294:	00 
  102295:	c7 44 24 04 92 00 00 	movl   $0x92,0x4(%esp)
  10229c:	00 
  10229d:	c7 04 24 d4 5d 10 00 	movl   $0x105dd4,(%esp)
  1022a4:	e8 1b e2 ff ff       	call   1004c4 <debug_panic>
		switch (*p) {
		case MPPROC:
			proc = (struct mpproc *) p;
			p += sizeof(struct mpproc);
			if (!(proc->flags & MPENAB))
				continue;	// processor disabled
  1022a9:	90                   	nop
	if ((conf = mpconfig(&mp)) == 0)
		return; // Not a multiprocessor machine - just use boot CPU.

	ismp = 1;
	lapic = (uint32_t *) conf->lapicaddr;
	for (p = (uint8_t *) (conf + 1), e = (uint8_t *) conf + conf->length;
  1022aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1022ad:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  1022b0:	0f 82 28 ff ff ff    	jb     1021de <mp_init+0x61>
			continue;
		default:
			panic("mpinit: unknown config type %x\n", *p);
		}
	}
	if (mp->imcrp) {
  1022b6:	8b 45 c4             	mov    -0x3c(%ebp),%eax
  1022b9:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
  1022bd:	84 c0                	test   %al,%al
  1022bf:	74 45                	je     102306 <mp_init+0x189>
  1022c1:	c7 45 dc 22 00 00 00 	movl   $0x22,-0x24(%ebp)
  1022c8:	c6 45 db 70          	movb   $0x70,-0x25(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1022cc:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  1022d0:	8b 55 dc             	mov    -0x24(%ebp),%edx
  1022d3:	ee                   	out    %al,(%dx)
  1022d4:	c7 45 d4 23 00 00 00 	movl   $0x23,-0x2c(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1022db:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  1022de:	89 55 b4             	mov    %edx,-0x4c(%ebp)
  1022e1:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  1022e4:	ec                   	in     (%dx),%al
  1022e5:	89 c3                	mov    %eax,%ebx
  1022e7:	88 5d d3             	mov    %bl,-0x2d(%ebp)
	return data;
  1022ea:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
		// Bochs doesn 't support IMCR, so this doesn' t run on Bochs.
		// But it would on real hardware.
		outb(0x22, 0x70);		// Select IMCR
		outb(0x23, inb(0x23) | 1);	// Mask external interrupts.
  1022ee:	83 c8 01             	or     $0x1,%eax
  1022f1:	0f b6 c0             	movzbl %al,%eax
  1022f4:	c7 45 cc 23 00 00 00 	movl   $0x23,-0x34(%ebp)
  1022fb:	88 45 cb             	mov    %al,-0x35(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1022fe:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
  102302:	8b 55 cc             	mov    -0x34(%ebp),%edx
  102305:	ee                   	out    %al,(%dx)
	}
}
  102306:	83 c4 64             	add    $0x64,%esp
  102309:	5b                   	pop    %ebx
  10230a:	5d                   	pop    %ebp
  10230b:	c3                   	ret    

0010230c <xchg>:
}

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  10230c:	55                   	push   %ebp
  10230d:	89 e5                	mov    %esp,%ebp
  10230f:	53                   	push   %ebx
  102310:	83 ec 10             	sub    $0x10,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
	       "+m" (*addr), "=a" (result) :
  102313:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  102316:	8b 45 0c             	mov    0xc(%ebp),%eax
	       "+m" (*addr), "=a" (result) :
  102319:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  10231c:	89 c3                	mov    %eax,%ebx
  10231e:	89 d8                	mov    %ebx,%eax
  102320:	f0 87 02             	lock xchg %eax,(%edx)
  102323:	89 c3                	mov    %eax,%ebx
  102325:	89 5d f8             	mov    %ebx,-0x8(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  102328:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
  10232b:	83 c4 10             	add    $0x10,%esp
  10232e:	5b                   	pop    %ebx
  10232f:	5d                   	pop    %ebp
  102330:	c3                   	ret    

00102331 <pause>:
	return result;
}

static inline void
pause(void)
{
  102331:	55                   	push   %ebp
  102332:	89 e5                	mov    %esp,%ebp
	asm volatile("pause" : : : "memory");
  102334:	f3 90                	pause  
}
  102336:	5d                   	pop    %ebp
  102337:	c3                   	ret    

00102338 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  102338:	55                   	push   %ebp
  102339:	89 e5                	mov    %esp,%ebp
  10233b:	53                   	push   %ebx
  10233c:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10233f:	89 e3                	mov    %esp,%ebx
  102341:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  102344:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  102347:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10234a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10234d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  102352:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  102355:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102358:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  10235e:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  102363:	74 24                	je     102389 <cpu_cur+0x51>
  102365:	c7 44 24 0c f4 5d 10 	movl   $0x105df4,0xc(%esp)
  10236c:	00 
  10236d:	c7 44 24 08 0a 5e 10 	movl   $0x105e0a,0x8(%esp)
  102374:	00 
  102375:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  10237c:	00 
  10237d:	c7 04 24 1f 5e 10 00 	movl   $0x105e1f,(%esp)
  102384:	e8 3b e1 ff ff       	call   1004c4 <debug_panic>
	return c;
  102389:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  10238c:	83 c4 24             	add    $0x24,%esp
  10238f:	5b                   	pop    %ebx
  102390:	5d                   	pop    %ebp
  102391:	c3                   	ret    

00102392 <spinlock_init_>:
#include <kern/cons.h>


void
spinlock_init_(struct spinlock *lk, const char *file, int line)
{
  102392:	55                   	push   %ebp
  102393:	89 e5                	mov    %esp,%ebp
	lk->file = file;
  102395:	8b 45 08             	mov    0x8(%ebp),%eax
  102398:	8b 55 0c             	mov    0xc(%ebp),%edx
  10239b:	89 50 04             	mov    %edx,0x4(%eax)
	lk->line = line;
  10239e:	8b 45 08             	mov    0x8(%ebp),%eax
  1023a1:	8b 55 10             	mov    0x10(%ebp),%edx
  1023a4:	89 50 08             	mov    %edx,0x8(%eax)
	lk->locked = 0;
  1023a7:	8b 45 08             	mov    0x8(%ebp),%eax
  1023aa:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	lk->cpu = NULL;
  1023b0:	8b 45 08             	mov    0x8(%ebp),%eax
  1023b3:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
}
  1023ba:	5d                   	pop    %ebp
  1023bb:	c3                   	ret    

001023bc <spinlock_acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spinlock_acquire(struct spinlock *lk)
{
  1023bc:	55                   	push   %ebp
  1023bd:	89 e5                	mov    %esp,%ebp
  1023bf:	53                   	push   %ebx
  1023c0:	83 ec 24             	sub    $0x24,%esp
	if(spinlock_holding(lk))
  1023c3:	8b 45 08             	mov    0x8(%ebp),%eax
  1023c6:	89 04 24             	mov    %eax,(%esp)
  1023c9:	e8 c4 00 00 00       	call   102492 <spinlock_holding>
  1023ce:	85 c0                	test   %eax,%eax
  1023d0:	74 23                	je     1023f5 <spinlock_acquire+0x39>
        panic("Already holding lock.");
  1023d2:	c7 44 24 08 2c 5e 10 	movl   $0x105e2c,0x8(%esp)
  1023d9:	00 
  1023da:	c7 44 24 04 24 00 00 	movl   $0x24,0x4(%esp)
  1023e1:	00 
  1023e2:	c7 04 24 42 5e 10 00 	movl   $0x105e42,(%esp)
  1023e9:	e8 d6 e0 ff ff       	call   1004c4 <debug_panic>
    while(xchg(&(lk->locked), 1) != 0)
        pause();
  1023ee:	e8 3e ff ff ff       	call   102331 <pause>
  1023f3:	eb 01                	jmp    1023f6 <spinlock_acquire+0x3a>
void
spinlock_acquire(struct spinlock *lk)
{
	if(spinlock_holding(lk))
        panic("Already holding lock.");
    while(xchg(&(lk->locked), 1) != 0)
  1023f5:	90                   	nop
  1023f6:	8b 45 08             	mov    0x8(%ebp),%eax
  1023f9:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  102400:	00 
  102401:	89 04 24             	mov    %eax,(%esp)
  102404:	e8 03 ff ff ff       	call   10230c <xchg>
  102409:	85 c0                	test   %eax,%eax
  10240b:	75 e1                	jne    1023ee <spinlock_acquire+0x32>
        pause();
    lk->cpu = cpu_cur();
  10240d:	e8 26 ff ff ff       	call   102338 <cpu_cur>
  102412:	8b 55 08             	mov    0x8(%ebp),%edx
  102415:	89 42 0c             	mov    %eax,0xc(%edx)
    debug_trace(read_ebp(), lk->eips);
  102418:	8b 45 08             	mov    0x8(%ebp),%eax
  10241b:	8d 50 10             	lea    0x10(%eax),%edx

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  10241e:	89 eb                	mov    %ebp,%ebx
  102420:	89 5d f4             	mov    %ebx,-0xc(%ebp)
        return ebp;
  102423:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102426:	89 54 24 04          	mov    %edx,0x4(%esp)
  10242a:	89 04 24             	mov    %eax,(%esp)
  10242d:	e8 a1 e1 ff ff       	call   1005d3 <debug_trace>
}
  102432:	83 c4 24             	add    $0x24,%esp
  102435:	5b                   	pop    %ebx
  102436:	5d                   	pop    %ebp
  102437:	c3                   	ret    

00102438 <spinlock_release>:

// Release the lock.
void
spinlock_release(struct spinlock *lk)
{
  102438:	55                   	push   %ebp
  102439:	89 e5                	mov    %esp,%ebp
  10243b:	83 ec 18             	sub    $0x18,%esp
	if(!spinlock_holding(lk))
  10243e:	8b 45 08             	mov    0x8(%ebp),%eax
  102441:	89 04 24             	mov    %eax,(%esp)
  102444:	e8 49 00 00 00       	call   102492 <spinlock_holding>
  102449:	85 c0                	test   %eax,%eax
  10244b:	75 1c                	jne    102469 <spinlock_release+0x31>
        panic("Not holding lock");
  10244d:	c7 44 24 08 52 5e 10 	movl   $0x105e52,0x8(%esp)
  102454:	00 
  102455:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
  10245c:	00 
  10245d:	c7 04 24 42 5e 10 00 	movl   $0x105e42,(%esp)
  102464:	e8 5b e0 ff ff       	call   1004c4 <debug_panic>
    lk->cpu = 0;
  102469:	8b 45 08             	mov    0x8(%ebp),%eax
  10246c:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    lk->eips[0] = 0;
  102473:	8b 45 08             	mov    0x8(%ebp),%eax
  102476:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
    xchg(&(lk->locked), 0);
  10247d:	8b 45 08             	mov    0x8(%ebp),%eax
  102480:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  102487:	00 
  102488:	89 04 24             	mov    %eax,(%esp)
  10248b:	e8 7c fe ff ff       	call   10230c <xchg>
}
  102490:	c9                   	leave  
  102491:	c3                   	ret    

00102492 <spinlock_holding>:

// Check whether this cpu is holding the lock.
int
spinlock_holding(spinlock *lock)
{
  102492:	55                   	push   %ebp
  102493:	89 e5                	mov    %esp,%ebp
  102495:	53                   	push   %ebx
  102496:	83 ec 04             	sub    $0x4,%esp
	//panic("spinlock_holding() not implemented");
	return (lock->locked) && (lock->cpu == cpu_cur());
  102499:	8b 45 08             	mov    0x8(%ebp),%eax
  10249c:	8b 00                	mov    (%eax),%eax
  10249e:	85 c0                	test   %eax,%eax
  1024a0:	74 16                	je     1024b8 <spinlock_holding+0x26>
  1024a2:	8b 45 08             	mov    0x8(%ebp),%eax
  1024a5:	8b 58 0c             	mov    0xc(%eax),%ebx
  1024a8:	e8 8b fe ff ff       	call   102338 <cpu_cur>
  1024ad:	39 c3                	cmp    %eax,%ebx
  1024af:	75 07                	jne    1024b8 <spinlock_holding+0x26>
  1024b1:	b8 01 00 00 00       	mov    $0x1,%eax
  1024b6:	eb 05                	jmp    1024bd <spinlock_holding+0x2b>
  1024b8:	b8 00 00 00 00       	mov    $0x0,%eax
}
  1024bd:	83 c4 04             	add    $0x4,%esp
  1024c0:	5b                   	pop    %ebx
  1024c1:	5d                   	pop    %ebp
  1024c2:	c3                   	ret    

001024c3 <spinlock_godeep>:
// Function that simply recurses to a specified depth.
// The useless return value and volatile parameter are
// so GCC doesn't collapse it via tail-call elimination.
int gcc_noinline
spinlock_godeep(volatile int depth, spinlock* lk)
{
  1024c3:	55                   	push   %ebp
  1024c4:	89 e5                	mov    %esp,%ebp
  1024c6:	83 ec 18             	sub    $0x18,%esp
	if (depth==0) { spinlock_acquire(lk); return 1; }
  1024c9:	8b 45 08             	mov    0x8(%ebp),%eax
  1024cc:	85 c0                	test   %eax,%eax
  1024ce:	75 12                	jne    1024e2 <spinlock_godeep+0x1f>
  1024d0:	8b 45 0c             	mov    0xc(%ebp),%eax
  1024d3:	89 04 24             	mov    %eax,(%esp)
  1024d6:	e8 e1 fe ff ff       	call   1023bc <spinlock_acquire>
  1024db:	b8 01 00 00 00       	mov    $0x1,%eax
  1024e0:	eb 1b                	jmp    1024fd <spinlock_godeep+0x3a>
	else return spinlock_godeep(depth-1, lk) * depth;
  1024e2:	8b 45 08             	mov    0x8(%ebp),%eax
  1024e5:	8d 50 ff             	lea    -0x1(%eax),%edx
  1024e8:	8b 45 0c             	mov    0xc(%ebp),%eax
  1024eb:	89 44 24 04          	mov    %eax,0x4(%esp)
  1024ef:	89 14 24             	mov    %edx,(%esp)
  1024f2:	e8 cc ff ff ff       	call   1024c3 <spinlock_godeep>
  1024f7:	8b 55 08             	mov    0x8(%ebp),%edx
  1024fa:	0f af c2             	imul   %edx,%eax
}
  1024fd:	c9                   	leave  
  1024fe:	c3                   	ret    

001024ff <spinlock_check>:

void spinlock_check()
{
  1024ff:	55                   	push   %ebp
  102500:	89 e5                	mov    %esp,%ebp
  102502:	56                   	push   %esi
  102503:	53                   	push   %ebx
  102504:	83 ec 40             	sub    $0x40,%esp
  102507:	89 e0                	mov    %esp,%eax
  102509:	89 c3                	mov    %eax,%ebx
	const int NUMLOCKS=10;
  10250b:	c7 45 e8 0a 00 00 00 	movl   $0xa,-0x18(%ebp)
	const int NUMRUNS=5;
  102512:	c7 45 e4 05 00 00 00 	movl   $0x5,-0x1c(%ebp)
	int i,j,run;
	const char* file = "spinlock_check";
  102519:	c7 45 e0 63 5e 10 00 	movl   $0x105e63,-0x20(%ebp)
	spinlock locks[NUMLOCKS];
  102520:	8b 45 e8             	mov    -0x18(%ebp),%eax
  102523:	83 e8 01             	sub    $0x1,%eax
  102526:	89 45 dc             	mov    %eax,-0x24(%ebp)
  102529:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10252c:	ba 00 00 00 00       	mov    $0x0,%edx
  102531:	69 f2 c0 01 00 00    	imul   $0x1c0,%edx,%esi
  102537:	6b c8 00             	imul   $0x0,%eax,%ecx
  10253a:	01 ce                	add    %ecx,%esi
  10253c:	b9 c0 01 00 00       	mov    $0x1c0,%ecx
  102541:	f7 e1                	mul    %ecx
  102543:	8d 0c 16             	lea    (%esi,%edx,1),%ecx
  102546:	89 ca                	mov    %ecx,%edx
  102548:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10254b:	c1 e0 03             	shl    $0x3,%eax
  10254e:	8b 45 e8             	mov    -0x18(%ebp),%eax
  102551:	ba 00 00 00 00       	mov    $0x0,%edx
  102556:	69 f2 c0 01 00 00    	imul   $0x1c0,%edx,%esi
  10255c:	6b c8 00             	imul   $0x0,%eax,%ecx
  10255f:	01 ce                	add    %ecx,%esi
  102561:	b9 c0 01 00 00       	mov    $0x1c0,%ecx
  102566:	f7 e1                	mul    %ecx
  102568:	8d 0c 16             	lea    (%esi,%edx,1),%ecx
  10256b:	89 ca                	mov    %ecx,%edx
  10256d:	8b 45 e8             	mov    -0x18(%ebp),%eax
  102570:	c1 e0 03             	shl    $0x3,%eax
  102573:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  10257a:	89 d1                	mov    %edx,%ecx
  10257c:	29 c1                	sub    %eax,%ecx
  10257e:	89 c8                	mov    %ecx,%eax
  102580:	8d 50 03             	lea    0x3(%eax),%edx
  102583:	b8 10 00 00 00       	mov    $0x10,%eax
  102588:	83 e8 01             	sub    $0x1,%eax
  10258b:	01 d0                	add    %edx,%eax
  10258d:	c7 45 d4 10 00 00 00 	movl   $0x10,-0x2c(%ebp)
  102594:	ba 00 00 00 00       	mov    $0x0,%edx
  102599:	f7 75 d4             	divl   -0x2c(%ebp)
  10259c:	6b c0 10             	imul   $0x10,%eax,%eax
  10259f:	29 c4                	sub    %eax,%esp
  1025a1:	8d 44 24 10          	lea    0x10(%esp),%eax
  1025a5:	83 c0 03             	add    $0x3,%eax
  1025a8:	c1 e8 02             	shr    $0x2,%eax
  1025ab:	c1 e0 02             	shl    $0x2,%eax
  1025ae:	89 45 d8             	mov    %eax,-0x28(%ebp)

	// Initialize the locks
	for(i=0;i<NUMLOCKS;i++) spinlock_init_(&locks[i], file, 0);
  1025b1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  1025b8:	eb 2f                	jmp    1025e9 <spinlock_check+0xea>
  1025ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1025bd:	c1 e0 03             	shl    $0x3,%eax
  1025c0:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1025c7:	29 c2                	sub    %eax,%edx
  1025c9:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1025cc:	01 c2                	add    %eax,%edx
  1025ce:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1025d5:	00 
  1025d6:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1025d9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1025dd:	89 14 24             	mov    %edx,(%esp)
  1025e0:	e8 ad fd ff ff       	call   102392 <spinlock_init_>
  1025e5:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  1025e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1025ec:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  1025ef:	7c c9                	jl     1025ba <spinlock_check+0xbb>
	// Make sure that all locks have CPU set to NULL initially
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu==NULL);
  1025f1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  1025f8:	eb 46                	jmp    102640 <spinlock_check+0x141>
  1025fa:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  1025fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102600:	c1 e0 03             	shl    $0x3,%eax
  102603:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  10260a:	29 c2                	sub    %eax,%edx
  10260c:	8d 04 11             	lea    (%ecx,%edx,1),%eax
  10260f:	83 c0 0c             	add    $0xc,%eax
  102612:	8b 00                	mov    (%eax),%eax
  102614:	85 c0                	test   %eax,%eax
  102616:	74 24                	je     10263c <spinlock_check+0x13d>
  102618:	c7 44 24 0c 72 5e 10 	movl   $0x105e72,0xc(%esp)
  10261f:	00 
  102620:	c7 44 24 08 0a 5e 10 	movl   $0x105e0a,0x8(%esp)
  102627:	00 
  102628:	c7 44 24 04 53 00 00 	movl   $0x53,0x4(%esp)
  10262f:	00 
  102630:	c7 04 24 42 5e 10 00 	movl   $0x105e42,(%esp)
  102637:	e8 88 de ff ff       	call   1004c4 <debug_panic>
  10263c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  102640:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102643:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  102646:	7c b2                	jl     1025fa <spinlock_check+0xfb>
	// Make sure that all locks have the correct debug info.
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].file==file);
  102648:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  10264f:	eb 47                	jmp    102698 <spinlock_check+0x199>
  102651:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  102654:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102657:	c1 e0 03             	shl    $0x3,%eax
  10265a:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102661:	29 c2                	sub    %eax,%edx
  102663:	8d 04 11             	lea    (%ecx,%edx,1),%eax
  102666:	83 c0 04             	add    $0x4,%eax
  102669:	8b 00                	mov    (%eax),%eax
  10266b:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  10266e:	74 24                	je     102694 <spinlock_check+0x195>
  102670:	c7 44 24 0c 85 5e 10 	movl   $0x105e85,0xc(%esp)
  102677:	00 
  102678:	c7 44 24 08 0a 5e 10 	movl   $0x105e0a,0x8(%esp)
  10267f:	00 
  102680:	c7 44 24 04 55 00 00 	movl   $0x55,0x4(%esp)
  102687:	00 
  102688:	c7 04 24 42 5e 10 00 	movl   $0x105e42,(%esp)
  10268f:	e8 30 de ff ff       	call   1004c4 <debug_panic>
  102694:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  102698:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10269b:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  10269e:	7c b1                	jl     102651 <spinlock_check+0x152>

	for (run=0;run<NUMRUNS;run++) 
  1026a0:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  1026a7:	e9 fc 02 00 00       	jmp    1029a8 <spinlock_check+0x4a9>
	{
		// Lock all locks
		for(i=0;i<NUMLOCKS;i++)
  1026ac:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  1026b3:	eb 27                	jmp    1026dc <spinlock_check+0x1dd>
			spinlock_godeep(i, &locks[i]);
  1026b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1026b8:	c1 e0 03             	shl    $0x3,%eax
  1026bb:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1026c2:	29 c2                	sub    %eax,%edx
  1026c4:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1026c7:	01 d0                	add    %edx,%eax
  1026c9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1026cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1026d0:	89 04 24             	mov    %eax,(%esp)
  1026d3:	e8 eb fd ff ff       	call   1024c3 <spinlock_godeep>
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].file==file);

	for (run=0;run<NUMRUNS;run++) 
	{
		// Lock all locks
		for(i=0;i<NUMLOCKS;i++)
  1026d8:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  1026dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1026df:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  1026e2:	7c d1                	jl     1026b5 <spinlock_check+0x1b6>
			spinlock_godeep(i, &locks[i]);

		// Make sure that all locks have the right CPU
		for(i=0;i<NUMLOCKS;i++)
  1026e4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  1026eb:	eb 4b                	jmp    102738 <spinlock_check+0x239>
			assert(locks[i].cpu == cpu_cur());
  1026ed:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  1026f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1026f3:	c1 e0 03             	shl    $0x3,%eax
  1026f6:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1026fd:	29 c2                	sub    %eax,%edx
  1026ff:	8d 04 11             	lea    (%ecx,%edx,1),%eax
  102702:	83 c0 0c             	add    $0xc,%eax
  102705:	8b 30                	mov    (%eax),%esi
  102707:	e8 2c fc ff ff       	call   102338 <cpu_cur>
  10270c:	39 c6                	cmp    %eax,%esi
  10270e:	74 24                	je     102734 <spinlock_check+0x235>
  102710:	c7 44 24 0c 99 5e 10 	movl   $0x105e99,0xc(%esp)
  102717:	00 
  102718:	c7 44 24 08 0a 5e 10 	movl   $0x105e0a,0x8(%esp)
  10271f:	00 
  102720:	c7 44 24 04 5f 00 00 	movl   $0x5f,0x4(%esp)
  102727:	00 
  102728:	c7 04 24 42 5e 10 00 	movl   $0x105e42,(%esp)
  10272f:	e8 90 dd ff ff       	call   1004c4 <debug_panic>
		// Lock all locks
		for(i=0;i<NUMLOCKS;i++)
			spinlock_godeep(i, &locks[i]);

		// Make sure that all locks have the right CPU
		for(i=0;i<NUMLOCKS;i++)
  102734:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  102738:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10273b:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  10273e:	7c ad                	jl     1026ed <spinlock_check+0x1ee>
			assert(locks[i].cpu == cpu_cur());
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++)
  102740:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  102747:	eb 48                	jmp    102791 <spinlock_check+0x292>
			assert(spinlock_holding(&locks[i]) != 0);
  102749:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10274c:	c1 e0 03             	shl    $0x3,%eax
  10274f:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102756:	29 c2                	sub    %eax,%edx
  102758:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10275b:	01 d0                	add    %edx,%eax
  10275d:	89 04 24             	mov    %eax,(%esp)
  102760:	e8 2d fd ff ff       	call   102492 <spinlock_holding>
  102765:	85 c0                	test   %eax,%eax
  102767:	75 24                	jne    10278d <spinlock_check+0x28e>
  102769:	c7 44 24 0c b4 5e 10 	movl   $0x105eb4,0xc(%esp)
  102770:	00 
  102771:	c7 44 24 08 0a 5e 10 	movl   $0x105e0a,0x8(%esp)
  102778:	00 
  102779:	c7 44 24 04 62 00 00 	movl   $0x62,0x4(%esp)
  102780:	00 
  102781:	c7 04 24 42 5e 10 00 	movl   $0x105e42,(%esp)
  102788:	e8 37 dd ff ff       	call   1004c4 <debug_panic>

		// Make sure that all locks have the right CPU
		for(i=0;i<NUMLOCKS;i++)
			assert(locks[i].cpu == cpu_cur());
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++)
  10278d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  102791:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102794:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  102797:	7c b0                	jl     102749 <spinlock_check+0x24a>
			assert(spinlock_holding(&locks[i]) != 0);
		// Make sure that top i frames are somewhere in godeep.
		for(i=0;i<NUMLOCKS;i++) 
  102799:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  1027a0:	e9 bb 00 00 00       	jmp    102860 <spinlock_check+0x361>
		{
			for(j=0; j<=i && j < DEBUG_TRACEFRAMES ; j++) 
  1027a5:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  1027ac:	e9 99 00 00 00       	jmp    10284a <spinlock_check+0x34b>
			{
				assert(locks[i].eips[j] >=
  1027b1:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  1027b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1027b7:	01 c0                	add    %eax,%eax
  1027b9:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1027c0:	29 c2                	sub    %eax,%edx
  1027c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1027c5:	01 d0                	add    %edx,%eax
  1027c7:	83 c0 04             	add    $0x4,%eax
  1027ca:	8b 14 81             	mov    (%ecx,%eax,4),%edx
  1027cd:	b8 c3 24 10 00       	mov    $0x1024c3,%eax
  1027d2:	39 c2                	cmp    %eax,%edx
  1027d4:	73 24                	jae    1027fa <spinlock_check+0x2fb>
  1027d6:	c7 44 24 0c d8 5e 10 	movl   $0x105ed8,0xc(%esp)
  1027dd:	00 
  1027de:	c7 44 24 08 0a 5e 10 	movl   $0x105e0a,0x8(%esp)
  1027e5:	00 
  1027e6:	c7 44 24 04 69 00 00 	movl   $0x69,0x4(%esp)
  1027ed:	00 
  1027ee:	c7 04 24 42 5e 10 00 	movl   $0x105e42,(%esp)
  1027f5:	e8 ca dc ff ff       	call   1004c4 <debug_panic>
					(uint32_t)spinlock_godeep);
				assert(locks[i].eips[j] <
  1027fa:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  1027fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102800:	01 c0                	add    %eax,%eax
  102802:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102809:	29 c2                	sub    %eax,%edx
  10280b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10280e:	01 d0                	add    %edx,%eax
  102810:	83 c0 04             	add    $0x4,%eax
  102813:	8b 04 81             	mov    (%ecx,%eax,4),%eax
  102816:	ba c3 24 10 00       	mov    $0x1024c3,%edx
  10281b:	83 c2 64             	add    $0x64,%edx
  10281e:	39 d0                	cmp    %edx,%eax
  102820:	72 24                	jb     102846 <spinlock_check+0x347>
  102822:	c7 44 24 0c 08 5f 10 	movl   $0x105f08,0xc(%esp)
  102829:	00 
  10282a:	c7 44 24 08 0a 5e 10 	movl   $0x105e0a,0x8(%esp)
  102831:	00 
  102832:	c7 44 24 04 6b 00 00 	movl   $0x6b,0x4(%esp)
  102839:	00 
  10283a:	c7 04 24 42 5e 10 00 	movl   $0x105e42,(%esp)
  102841:	e8 7e dc ff ff       	call   1004c4 <debug_panic>
		for(i=0;i<NUMLOCKS;i++)
			assert(spinlock_holding(&locks[i]) != 0);
		// Make sure that top i frames are somewhere in godeep.
		for(i=0;i<NUMLOCKS;i++) 
		{
			for(j=0; j<=i && j < DEBUG_TRACEFRAMES ; j++) 
  102846:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  10284a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10284d:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  102850:	7f 0a                	jg     10285c <spinlock_check+0x35d>
  102852:	83 7d f0 09          	cmpl   $0x9,-0x10(%ebp)
  102856:	0f 8e 55 ff ff ff    	jle    1027b1 <spinlock_check+0x2b2>
			assert(locks[i].cpu == cpu_cur());
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++)
			assert(spinlock_holding(&locks[i]) != 0);
		// Make sure that top i frames are somewhere in godeep.
		for(i=0;i<NUMLOCKS;i++) 
  10285c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  102860:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102863:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  102866:	0f 8c 39 ff ff ff    	jl     1027a5 <spinlock_check+0x2a6>
					(uint32_t)spinlock_godeep+100);
			}
		}

		// Release all locks
		for(i=0;i<NUMLOCKS;i++) spinlock_release(&locks[i]);
  10286c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  102873:	eb 20                	jmp    102895 <spinlock_check+0x396>
  102875:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102878:	c1 e0 03             	shl    $0x3,%eax
  10287b:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102882:	29 c2                	sub    %eax,%edx
  102884:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102887:	01 d0                	add    %edx,%eax
  102889:	89 04 24             	mov    %eax,(%esp)
  10288c:	e8 a7 fb ff ff       	call   102438 <spinlock_release>
  102891:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  102895:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102898:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  10289b:	7c d8                	jl     102875 <spinlock_check+0x376>
		// Make sure that the CPU has been cleared
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu == NULL);
  10289d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  1028a4:	eb 46                	jmp    1028ec <spinlock_check+0x3ed>
  1028a6:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  1028a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1028ac:	c1 e0 03             	shl    $0x3,%eax
  1028af:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1028b6:	29 c2                	sub    %eax,%edx
  1028b8:	8d 04 11             	lea    (%ecx,%edx,1),%eax
  1028bb:	83 c0 0c             	add    $0xc,%eax
  1028be:	8b 00                	mov    (%eax),%eax
  1028c0:	85 c0                	test   %eax,%eax
  1028c2:	74 24                	je     1028e8 <spinlock_check+0x3e9>
  1028c4:	c7 44 24 0c 39 5f 10 	movl   $0x105f39,0xc(%esp)
  1028cb:	00 
  1028cc:	c7 44 24 08 0a 5e 10 	movl   $0x105e0a,0x8(%esp)
  1028d3:	00 
  1028d4:	c7 44 24 04 72 00 00 	movl   $0x72,0x4(%esp)
  1028db:	00 
  1028dc:	c7 04 24 42 5e 10 00 	movl   $0x105e42,(%esp)
  1028e3:	e8 dc db ff ff       	call   1004c4 <debug_panic>
  1028e8:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  1028ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1028ef:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  1028f2:	7c b2                	jl     1028a6 <spinlock_check+0x3a7>
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].eips[0]==0);
  1028f4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  1028fb:	eb 46                	jmp    102943 <spinlock_check+0x444>
  1028fd:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  102900:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102903:	c1 e0 03             	shl    $0x3,%eax
  102906:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  10290d:	29 c2                	sub    %eax,%edx
  10290f:	8d 04 11             	lea    (%ecx,%edx,1),%eax
  102912:	83 c0 10             	add    $0x10,%eax
  102915:	8b 00                	mov    (%eax),%eax
  102917:	85 c0                	test   %eax,%eax
  102919:	74 24                	je     10293f <spinlock_check+0x440>
  10291b:	c7 44 24 0c 4e 5f 10 	movl   $0x105f4e,0xc(%esp)
  102922:	00 
  102923:	c7 44 24 08 0a 5e 10 	movl   $0x105e0a,0x8(%esp)
  10292a:	00 
  10292b:	c7 44 24 04 73 00 00 	movl   $0x73,0x4(%esp)
  102932:	00 
  102933:	c7 04 24 42 5e 10 00 	movl   $0x105e42,(%esp)
  10293a:	e8 85 db ff ff       	call   1004c4 <debug_panic>
  10293f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  102943:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102946:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  102949:	7c b2                	jl     1028fd <spinlock_check+0x3fe>
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++) assert(spinlock_holding(&locks[i]) == 0);
  10294b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  102952:	eb 48                	jmp    10299c <spinlock_check+0x49d>
  102954:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102957:	c1 e0 03             	shl    $0x3,%eax
  10295a:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102961:	29 c2                	sub    %eax,%edx
  102963:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102966:	01 d0                	add    %edx,%eax
  102968:	89 04 24             	mov    %eax,(%esp)
  10296b:	e8 22 fb ff ff       	call   102492 <spinlock_holding>
  102970:	85 c0                	test   %eax,%eax
  102972:	74 24                	je     102998 <spinlock_check+0x499>
  102974:	c7 44 24 0c 64 5f 10 	movl   $0x105f64,0xc(%esp)
  10297b:	00 
  10297c:	c7 44 24 08 0a 5e 10 	movl   $0x105e0a,0x8(%esp)
  102983:	00 
  102984:	c7 44 24 04 75 00 00 	movl   $0x75,0x4(%esp)
  10298b:	00 
  10298c:	c7 04 24 42 5e 10 00 	movl   $0x105e42,(%esp)
  102993:	e8 2c db ff ff       	call   1004c4 <debug_panic>
  102998:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  10299c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10299f:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  1029a2:	7c b0                	jl     102954 <spinlock_check+0x455>
	// Make sure that all locks have CPU set to NULL initially
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu==NULL);
	// Make sure that all locks have the correct debug info.
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].file==file);

	for (run=0;run<NUMRUNS;run++) 
  1029a4:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  1029a8:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1029ab:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  1029ae:	0f 8c f8 fc ff ff    	jl     1026ac <spinlock_check+0x1ad>
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu == NULL);
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].eips[0]==0);
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++) assert(spinlock_holding(&locks[i]) == 0);
	}
	cprintf("spinlock_check() succeeded!\n");
  1029b4:	c7 04 24 85 5f 10 00 	movl   $0x105f85,(%esp)
  1029bb:	e8 44 22 00 00       	call   104c04 <cprintf>
  1029c0:	89 dc                	mov    %ebx,%esp
}
  1029c2:	8d 65 f8             	lea    -0x8(%ebp),%esp
  1029c5:	5b                   	pop    %ebx
  1029c6:	5e                   	pop    %esi
  1029c7:	5d                   	pop    %ebp
  1029c8:	c3                   	ret    
  1029c9:	90                   	nop
  1029ca:	90                   	nop
  1029cb:	90                   	nop

001029cc <xchg>:
}

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  1029cc:	55                   	push   %ebp
  1029cd:	89 e5                	mov    %esp,%ebp
  1029cf:	53                   	push   %ebx
  1029d0:	83 ec 10             	sub    $0x10,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
	       "+m" (*addr), "=a" (result) :
  1029d3:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  1029d6:	8b 45 0c             	mov    0xc(%ebp),%eax
	       "+m" (*addr), "=a" (result) :
  1029d9:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  1029dc:	89 c3                	mov    %eax,%ebx
  1029de:	89 d8                	mov    %ebx,%eax
  1029e0:	f0 87 02             	lock xchg %eax,(%edx)
  1029e3:	89 c3                	mov    %eax,%ebx
  1029e5:	89 5d f8             	mov    %ebx,-0x8(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  1029e8:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
  1029eb:	83 c4 10             	add    $0x10,%esp
  1029ee:	5b                   	pop    %ebx
  1029ef:	5d                   	pop    %ebp
  1029f0:	c3                   	ret    

001029f1 <lockadd>:

// Atomically add incr to *addr.
static inline void
lockadd(volatile int32_t *addr, int32_t incr)
{
  1029f1:	55                   	push   %ebp
  1029f2:	89 e5                	mov    %esp,%ebp
	asm volatile("lock; addl %1,%0" : "+m" (*addr) : "r" (incr) : "cc");
  1029f4:	8b 45 08             	mov    0x8(%ebp),%eax
  1029f7:	8b 55 0c             	mov    0xc(%ebp),%edx
  1029fa:	8b 4d 08             	mov    0x8(%ebp),%ecx
  1029fd:	f0 01 10             	lock add %edx,(%eax)
}
  102a00:	5d                   	pop    %ebp
  102a01:	c3                   	ret    

00102a02 <pause>:
	return result;
}

static inline void
pause(void)
{
  102a02:	55                   	push   %ebp
  102a03:	89 e5                	mov    %esp,%ebp
	asm volatile("pause" : : : "memory");
  102a05:	f3 90                	pause  
}
  102a07:	5d                   	pop    %ebp
  102a08:	c3                   	ret    

00102a09 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  102a09:	55                   	push   %ebp
  102a0a:	89 e5                	mov    %esp,%ebp
  102a0c:	53                   	push   %ebx
  102a0d:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  102a10:	89 e3                	mov    %esp,%ebx
  102a12:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  102a15:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  102a18:	89 45 f4             	mov    %eax,-0xc(%ebp)
  102a1b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102a1e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  102a23:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  102a26:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102a29:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  102a2f:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  102a34:	74 24                	je     102a5a <cpu_cur+0x51>
  102a36:	c7 44 24 0c a4 5f 10 	movl   $0x105fa4,0xc(%esp)
  102a3d:	00 
  102a3e:	c7 44 24 08 ba 5f 10 	movl   $0x105fba,0x8(%esp)
  102a45:	00 
  102a46:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  102a4d:	00 
  102a4e:	c7 04 24 cf 5f 10 00 	movl   $0x105fcf,(%esp)
  102a55:	e8 6a da ff ff       	call   1004c4 <debug_panic>
	return c;
  102a5a:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  102a5d:	83 c4 24             	add    $0x24,%esp
  102a60:	5b                   	pop    %ebx
  102a61:	5d                   	pop    %ebp
  102a62:	c3                   	ret    

00102a63 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  102a63:	55                   	push   %ebp
  102a64:	89 e5                	mov    %esp,%ebp
  102a66:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  102a69:	e8 9b ff ff ff       	call   102a09 <cpu_cur>
  102a6e:	3d 00 90 10 00       	cmp    $0x109000,%eax
  102a73:	0f 94 c0             	sete   %al
  102a76:	0f b6 c0             	movzbl %al,%eax
}
  102a79:	c9                   	leave  
  102a7a:	c3                   	ret    

00102a7b <proc_init>:
proc *proc_queue_head;
spinlock _queue_lock;

void
proc_init(void)
{
  102a7b:	55                   	push   %ebp
  102a7c:	89 e5                	mov    %esp,%ebp
  102a7e:	83 ec 18             	sub    $0x18,%esp
	if (!cpu_onboot())
  102a81:	e8 dd ff ff ff       	call   102a63 <cpu_onboot>
  102a86:	85 c0                	test   %eax,%eax
  102a88:	74 28                	je     102ab2 <proc_init+0x37>
		return;

	// your module initialization code here
	spinlock_init(&_queue_lock);
  102a8a:	c7 44 24 08 25 00 00 	movl   $0x25,0x8(%esp)
  102a91:	00 
  102a92:	c7 44 24 04 dc 5f 10 	movl   $0x105fdc,0x4(%esp)
  102a99:	00 
  102a9a:	c7 04 24 a0 03 31 00 	movl   $0x3103a0,(%esp)
  102aa1:	e8 ec f8 ff ff       	call   102392 <spinlock_init_>
	proc_queue_head = NULL;	
  102aa6:	c7 05 84 0a 31 00 00 	movl   $0x0,0x310a84
  102aad:	00 00 00 
  102ab0:	eb 01                	jmp    102ab3 <proc_init+0x38>

void
proc_init(void)
{
	if (!cpu_onboot())
		return;
  102ab2:	90                   	nop

	// your module initialization code here
	spinlock_init(&_queue_lock);
	proc_queue_head = NULL;	
}
  102ab3:	c9                   	leave  
  102ab4:	c3                   	ret    

00102ab5 <proc_alloc>:

// Allocate and initialize a new proc as child 'cn' of parent 'p'.
// Returns NULL if no physical memory available.
proc *
proc_alloc(proc *p, uint32_t cn)
{
  102ab5:	55                   	push   %ebp
  102ab6:	89 e5                	mov    %esp,%ebp
  102ab8:	83 ec 28             	sub    $0x28,%esp
	pageinfo *pi = mem_alloc();
  102abb:	e8 2a e1 ff ff       	call   100bea <mem_alloc>
  102ac0:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (!pi)
  102ac3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  102ac7:	75 0a                	jne    102ad3 <proc_alloc+0x1e>
		return NULL;
  102ac9:	b8 00 00 00 00       	mov    $0x0,%eax
  102ace:	e9 60 01 00 00       	jmp    102c33 <proc_alloc+0x17e>
  102ad3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102ad6:	89 45 ec             	mov    %eax,-0x14(%ebp)

// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  102ad9:	a1 84 03 31 00       	mov    0x310384,%eax
  102ade:	83 c0 08             	add    $0x8,%eax
  102ae1:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  102ae4:	76 15                	jbe    102afb <proc_alloc+0x46>
  102ae6:	a1 84 03 31 00       	mov    0x310384,%eax
  102aeb:	8b 15 38 03 11 00    	mov    0x110338,%edx
  102af1:	c1 e2 03             	shl    $0x3,%edx
  102af4:	01 d0                	add    %edx,%eax
  102af6:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  102af9:	72 24                	jb     102b1f <proc_alloc+0x6a>
  102afb:	c7 44 24 0c e8 5f 10 	movl   $0x105fe8,0xc(%esp)
  102b02:	00 
  102b03:	c7 44 24 08 ba 5f 10 	movl   $0x105fba,0x8(%esp)
  102b0a:	00 
  102b0b:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
  102b12:	00 
  102b13:	c7 04 24 1f 60 10 00 	movl   $0x10601f,(%esp)
  102b1a:	e8 a5 d9 ff ff       	call   1004c4 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  102b1f:	a1 84 03 31 00       	mov    0x310384,%eax
  102b24:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  102b29:	c1 ea 0c             	shr    $0xc,%edx
  102b2c:	c1 e2 03             	shl    $0x3,%edx
  102b2f:	01 d0                	add    %edx,%eax
  102b31:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  102b34:	72 3b                	jb     102b71 <proc_alloc+0xbc>
  102b36:	a1 84 03 31 00       	mov    0x310384,%eax
  102b3b:	ba 8f 0a 31 00       	mov    $0x310a8f,%edx
  102b40:	c1 ea 0c             	shr    $0xc,%edx
  102b43:	c1 e2 03             	shl    $0x3,%edx
  102b46:	01 d0                	add    %edx,%eax
  102b48:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  102b4b:	77 24                	ja     102b71 <proc_alloc+0xbc>
  102b4d:	c7 44 24 0c 2c 60 10 	movl   $0x10602c,0xc(%esp)
  102b54:	00 
  102b55:	c7 44 24 08 ba 5f 10 	movl   $0x105fba,0x8(%esp)
  102b5c:	00 
  102b5d:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  102b64:	00 
  102b65:	c7 04 24 1f 60 10 00 	movl   $0x10601f,(%esp)
  102b6c:	e8 53 d9 ff ff       	call   1004c4 <debug_panic>

	lockadd(&pi->refcount, 1);
  102b71:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102b74:	83 c0 04             	add    $0x4,%eax
  102b77:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  102b7e:	00 
  102b7f:	89 04 24             	mov    %eax,(%esp)
  102b82:	e8 6a fe ff ff       	call   1029f1 <lockadd>
	mem_incref(pi);

	proc *cp = (proc*)mem_pi2ptr(pi);
  102b87:	8b 55 f4             	mov    -0xc(%ebp),%edx
  102b8a:	a1 84 03 31 00       	mov    0x310384,%eax
  102b8f:	89 d1                	mov    %edx,%ecx
  102b91:	29 c1                	sub    %eax,%ecx
  102b93:	89 c8                	mov    %ecx,%eax
  102b95:	c1 f8 03             	sar    $0x3,%eax
  102b98:	c1 e0 0c             	shl    $0xc,%eax
  102b9b:	89 45 f0             	mov    %eax,-0x10(%ebp)
	memset(cp, 0, sizeof(proc));
  102b9e:	c7 44 24 08 a0 06 00 	movl   $0x6a0,0x8(%esp)
  102ba5:	00 
  102ba6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  102bad:	00 
  102bae:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102bb1:	89 04 24             	mov    %eax,(%esp)
  102bb4:	e8 30 22 00 00       	call   104de9 <memset>
	spinlock_init(&cp->lock);
  102bb9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102bbc:	c7 44 24 08 35 00 00 	movl   $0x35,0x8(%esp)
  102bc3:	00 
  102bc4:	c7 44 24 04 dc 5f 10 	movl   $0x105fdc,0x4(%esp)
  102bcb:	00 
  102bcc:	89 04 24             	mov    %eax,(%esp)
  102bcf:	e8 be f7 ff ff       	call   102392 <spinlock_init_>
	cp->parent = p;
  102bd4:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102bd7:	8b 55 08             	mov    0x8(%ebp),%edx
  102bda:	89 50 38             	mov    %edx,0x38(%eax)
	cp->state = PROC_STOP;
  102bdd:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102be0:	c7 80 3c 04 00 00 00 	movl   $0x0,0x43c(%eax)
  102be7:	00 00 00 

	// Integer register state
	cp->sv.tf.ds = CPU_GDT_UDATA | 3;
  102bea:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102bed:	66 c7 80 7c 04 00 00 	movw   $0x23,0x47c(%eax)
  102bf4:	23 00 
	cp->sv.tf.es = CPU_GDT_UDATA | 3;
  102bf6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102bf9:	66 c7 80 78 04 00 00 	movw   $0x23,0x478(%eax)
  102c00:	23 00 
	cp->sv.tf.cs = CPU_GDT_UCODE | 3;
  102c02:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102c05:	66 c7 80 8c 04 00 00 	movw   $0x1b,0x48c(%eax)
  102c0c:	1b 00 
	cp->sv.tf.ss = CPU_GDT_UDATA | 3;
  102c0e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102c11:	66 c7 80 98 04 00 00 	movw   $0x23,0x498(%eax)
  102c18:	23 00 


	if (p)
  102c1a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  102c1e:	74 10                	je     102c30 <proc_alloc+0x17b>
		p->child[cn] = cp;
  102c20:	8b 45 08             	mov    0x8(%ebp),%eax
  102c23:	8b 55 0c             	mov    0xc(%ebp),%edx
  102c26:	8d 4a 0c             	lea    0xc(%edx),%ecx
  102c29:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102c2c:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
	return cp;
  102c30:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  102c33:	c9                   	leave  
  102c34:	c3                   	ret    

00102c35 <proc_ready>:

// Put process p in the ready state and add it to the ready queue.
void
proc_ready(proc *p)
{
  102c35:	55                   	push   %ebp
  102c36:	89 e5                	mov    %esp,%ebp
  102c38:	83 ec 28             	sub    $0x28,%esp
	//panic("proc_ready not implemented");
	spinlock_acquire(&_queue_lock);
  102c3b:	c7 04 24 a0 03 31 00 	movl   $0x3103a0,(%esp)
  102c42:	e8 75 f7 ff ff       	call   1023bc <spinlock_acquire>
	p->state = PROC_READY;
  102c47:	8b 45 08             	mov    0x8(%ebp),%eax
  102c4a:	c7 80 3c 04 00 00 01 	movl   $0x1,0x43c(%eax)
  102c51:	00 00 00 
	p->readynext = NULL;
  102c54:	8b 45 08             	mov    0x8(%ebp),%eax
  102c57:	c7 80 40 04 00 00 00 	movl   $0x0,0x440(%eax)
  102c5e:	00 00 00 
	proc *tmp = proc_queue_head;
  102c61:	a1 84 0a 31 00       	mov    0x310a84,%eax
  102c66:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if(!tmp){//the ready queue is empty
  102c69:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  102c6d:	75 24                	jne    102c93 <proc_ready+0x5e>
		proc_queue_head = p;
  102c6f:	8b 45 08             	mov    0x8(%ebp),%eax
  102c72:	a3 84 0a 31 00       	mov    %eax,0x310a84
		spinlock_release(&_queue_lock);
  102c77:	c7 04 24 a0 03 31 00 	movl   $0x3103a0,(%esp)
  102c7e:	e8 b5 f7 ff ff       	call   102438 <spinlock_release>
		return ;
  102c83:	eb 34                	jmp    102cb9 <proc_ready+0x84>
	}
	while(tmp->readynext)
		tmp = tmp->readynext;//get the ready proc at the ready queue taill
  102c85:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102c88:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  102c8e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  102c91:	eb 01                	jmp    102c94 <proc_ready+0x5f>
	if(!tmp){//the ready queue is empty
		proc_queue_head = p;
		spinlock_release(&_queue_lock);
		return ;
	}
	while(tmp->readynext)
  102c93:	90                   	nop
  102c94:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102c97:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  102c9d:	85 c0                	test   %eax,%eax
  102c9f:	75 e4                	jne    102c85 <proc_ready+0x50>
		tmp = tmp->readynext;//get the ready proc at the ready queue taill

	tmp->readynext = p;
  102ca1:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102ca4:	8b 55 08             	mov    0x8(%ebp),%edx
  102ca7:	89 90 40 04 00 00    	mov    %edx,0x440(%eax)
	spinlock_release(&_queue_lock);
  102cad:	c7 04 24 a0 03 31 00 	movl   $0x3103a0,(%esp)
  102cb4:	e8 7f f7 ff ff       	call   102438 <spinlock_release>
}
  102cb9:	c9                   	leave  
  102cba:	c3                   	ret    

00102cbb <proc_save>:
//	-1	if we entered the kernel via a trap before executing an insn
//	0	if we entered via a syscall and must abort/rollback the syscall
//	1	if we entered via a syscall and are completing the syscall
void
proc_save(proc *p, trapframe *tf, int entry)
{
  102cbb:	55                   	push   %ebp
  102cbc:	89 e5                	mov    %esp,%ebp
  102cbe:	57                   	push   %edi
  102cbf:	56                   	push   %esi
  102cc0:	53                   	push   %ebx
	p->sv.tf = *tf;
  102cc1:	8b 55 08             	mov    0x8(%ebp),%edx
  102cc4:	8b 45 0c             	mov    0xc(%ebp),%eax
  102cc7:	8d 9a 50 04 00 00    	lea    0x450(%edx),%ebx
  102ccd:	89 c2                	mov    %eax,%edx
  102ccf:	b8 13 00 00 00       	mov    $0x13,%eax
  102cd4:	89 df                	mov    %ebx,%edi
  102cd6:	89 d6                	mov    %edx,%esi
  102cd8:	89 c1                	mov    %eax,%ecx
  102cda:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	if(entry == 0)
  102cdc:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  102ce0:	75 15                	jne    102cf7 <proc_save+0x3c>
		p->sv.tf.eip -= 2;
  102ce2:	8b 45 08             	mov    0x8(%ebp),%eax
  102ce5:	8b 80 88 04 00 00    	mov    0x488(%eax),%eax
  102ceb:	8d 50 fe             	lea    -0x2(%eax),%edx
  102cee:	8b 45 08             	mov    0x8(%ebp),%eax
  102cf1:	89 90 88 04 00 00    	mov    %edx,0x488(%eax)
	//rollback the syscall, 
	//because the syscall pushes eip of the next instruction
}
  102cf7:	5b                   	pop    %ebx
  102cf8:	5e                   	pop    %esi
  102cf9:	5f                   	pop    %edi
  102cfa:	5d                   	pop    %ebp
  102cfb:	c3                   	ret    

00102cfc <proc_wait>:
// Go to sleep waiting for a given child process to finish running.
// Parent process 'p' must be running and locked on entry.
// The supplied trapframe represents p's register state on syscall entry.
void gcc_noreturn
proc_wait(proc *p, proc *cp, trapframe *tf)
{
  102cfc:	55                   	push   %ebp
  102cfd:	89 e5                	mov    %esp,%ebp
  102cff:	83 ec 18             	sub    $0x18,%esp
	//panic("proc_wait not implemented");
	p->state =	PROC_WAIT;
  102d02:	8b 45 08             	mov    0x8(%ebp),%eax
  102d05:	c7 80 3c 04 00 00 03 	movl   $0x3,0x43c(%eax)
  102d0c:	00 00 00 
	p->runcpu = NULL;
  102d0f:	8b 45 08             	mov    0x8(%ebp),%eax
  102d12:	c7 80 44 04 00 00 00 	movl   $0x0,0x444(%eax)
  102d19:	00 00 00 
	p->waitchild = cp;
  102d1c:	8b 45 08             	mov    0x8(%ebp),%eax
  102d1f:	8b 55 0c             	mov    0xc(%ebp),%edx
  102d22:	89 90 48 04 00 00    	mov    %edx,0x448(%eax)
	proc_save(p, tf, 0);
  102d28:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  102d2f:	00 
  102d30:	8b 45 10             	mov    0x10(%ebp),%eax
  102d33:	89 44 24 04          	mov    %eax,0x4(%esp)
  102d37:	8b 45 08             	mov    0x8(%ebp),%eax
  102d3a:	89 04 24             	mov    %eax,(%esp)
  102d3d:	e8 79 ff ff ff       	call   102cbb <proc_save>
	spinlock_release(&p->lock);
  102d42:	8b 45 08             	mov    0x8(%ebp),%eax
  102d45:	89 04 24             	mov    %eax,(%esp)
  102d48:	e8 eb f6 ff ff       	call   102438 <spinlock_release>
	proc_sched();
  102d4d:	e8 00 00 00 00       	call   102d52 <proc_sched>

00102d52 <proc_sched>:
}

void gcc_noreturn
proc_sched(void)
{
  102d52:	55                   	push   %ebp
  102d53:	89 e5                	mov    %esp,%ebp
  102d55:	83 ec 28             	sub    $0x28,%esp
	//panic("proc_sched not implemented");
	spinlock_acquire(&_queue_lock);
  102d58:	c7 04 24 a0 03 31 00 	movl   $0x3103a0,(%esp)
  102d5f:	e8 58 f6 ff ff       	call   1023bc <spinlock_acquire>
	while(!proc_queue_head){
  102d64:	eb 2a                	jmp    102d90 <proc_sched+0x3e>
		spinlock_release(&_queue_lock);
  102d66:	c7 04 24 a0 03 31 00 	movl   $0x3103a0,(%esp)
  102d6d:	e8 c6 f6 ff ff       	call   102438 <spinlock_release>
		while(!proc_queue_head){
  102d72:	eb 07                	jmp    102d7b <proc_sched+0x29>

// Enable external device interrupts.
static gcc_inline void
sti(void)
{
	asm volatile("sti");
  102d74:	fb                   	sti    
			sti();
			pause();
  102d75:	e8 88 fc ff ff       	call   102a02 <pause>

// Disable external device interrupts.
static gcc_inline void
cli(void)
{
	asm volatile("cli");
  102d7a:	fa                   	cli    
{
	//panic("proc_sched not implemented");
	spinlock_acquire(&_queue_lock);
	while(!proc_queue_head){
		spinlock_release(&_queue_lock);
		while(!proc_queue_head){
  102d7b:	a1 84 0a 31 00       	mov    0x310a84,%eax
  102d80:	85 c0                	test   %eax,%eax
  102d82:	74 f0                	je     102d74 <proc_sched+0x22>
			sti();
			pause();
			cli();
		}
		spinlock_acquire(&_queue_lock);
  102d84:	c7 04 24 a0 03 31 00 	movl   $0x3103a0,(%esp)
  102d8b:	e8 2c f6 ff ff       	call   1023bc <spinlock_acquire>
void gcc_noreturn
proc_sched(void)
{
	//panic("proc_sched not implemented");
	spinlock_acquire(&_queue_lock);
	while(!proc_queue_head){
  102d90:	a1 84 0a 31 00       	mov    0x310a84,%eax
  102d95:	85 c0                	test   %eax,%eax
  102d97:	74 cd                	je     102d66 <proc_sched+0x14>
			cli();
		}
		spinlock_acquire(&_queue_lock);
	}

	proc *p = proc_queue_head;
  102d99:	a1 84 0a 31 00       	mov    0x310a84,%eax
  102d9e:	89 45 f4             	mov    %eax,-0xc(%ebp)
	proc_queue_head = p->readynext;
  102da1:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102da4:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  102daa:	a3 84 0a 31 00       	mov    %eax,0x310a84
	spinlock_acquire(&p->lock);
  102daf:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102db2:	89 04 24             	mov    %eax,(%esp)
  102db5:	e8 02 f6 ff ff       	call   1023bc <spinlock_acquire>
	spinlock_release(&_queue_lock);
  102dba:	c7 04 24 a0 03 31 00 	movl   $0x3103a0,(%esp)
  102dc1:	e8 72 f6 ff ff       	call   102438 <spinlock_release>
	proc_run(p);
  102dc6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102dc9:	89 04 24             	mov    %eax,(%esp)
  102dcc:	e8 00 00 00 00       	call   102dd1 <proc_run>

00102dd1 <proc_run>:
}

// Switch to and run a specified process, which must already be locked.
void gcc_noreturn
proc_run(proc *p)
{
  102dd1:	55                   	push   %ebp
  102dd2:	89 e5                	mov    %esp,%ebp
  102dd4:	83 ec 28             	sub    $0x28,%esp
	//panic("proc_run not implemented");
  	p->state = PROC_RUN;
  102dd7:	8b 45 08             	mov    0x8(%ebp),%eax
  102dda:	c7 80 3c 04 00 00 02 	movl   $0x2,0x43c(%eax)
  102de1:	00 00 00 
  	cpu *curr = cpu_cur();
  102de4:	e8 20 fc ff ff       	call   102a09 <cpu_cur>
  102de9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  	curr->proc = p;
  102dec:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102def:	8b 55 08             	mov    0x8(%ebp),%edx
  102df2:	89 90 b4 00 00 00    	mov    %edx,0xb4(%eax)
  	p->runcpu = curr;
  102df8:	8b 45 08             	mov    0x8(%ebp),%eax
  102dfb:	8b 55 f4             	mov    -0xc(%ebp),%edx
  102dfe:	89 90 44 04 00 00    	mov    %edx,0x444(%eax)
  	spinlock_release(&p->lock);
  102e04:	8b 45 08             	mov    0x8(%ebp),%eax
  102e07:	89 04 24             	mov    %eax,(%esp)
  102e0a:	e8 29 f6 ff ff       	call   102438 <spinlock_release>
	//lcr3(mem_phys(p->pdir));
  	trap_return(&p->sv.tf);
  102e0f:	8b 45 08             	mov    0x8(%ebp),%eax
  102e12:	05 50 04 00 00       	add    $0x450,%eax
  102e17:	89 04 24             	mov    %eax,(%esp)
  102e1a:	e8 e1 f0 ff ff       	call   101f00 <trap_return>

00102e1f <proc_yield>:

// Yield the current CPU to another ready process.
// Called while handling a timer interrupt.
void gcc_noreturn
proc_yield(trapframe *tf)
{
  102e1f:	55                   	push   %ebp
  102e20:	89 e5                	mov    %esp,%ebp
  102e22:	83 ec 28             	sub    $0x28,%esp
	//panic("proc_yield not implemented");
	proc *curr = proc_cur();
  102e25:	e8 df fb ff ff       	call   102a09 <cpu_cur>
  102e2a:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  102e30:	89 45 f4             	mov    %eax,-0xc(%ebp)
  	proc_save(curr, tf, -1);
  102e33:	c7 44 24 08 ff ff ff 	movl   $0xffffffff,0x8(%esp)
  102e3a:	ff 
  102e3b:	8b 45 08             	mov    0x8(%ebp),%eax
  102e3e:	89 44 24 04          	mov    %eax,0x4(%esp)
  102e42:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102e45:	89 04 24             	mov    %eax,(%esp)
  102e48:	e8 6e fe ff ff       	call   102cbb <proc_save>
  	proc_ready(curr);
  102e4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102e50:	89 04 24             	mov    %eax,(%esp)
  102e53:	e8 dd fd ff ff       	call   102c35 <proc_ready>
  	proc_sched();
  102e58:	e8 f5 fe ff ff       	call   102d52 <proc_sched>

00102e5d <proc_ret>:
// Used both when a process calls the SYS_RET system call explicitly,
// and when a process causes an unhandled trap in user mode.
// The 'entry' parameter is as in proc_save().
void gcc_noreturn
proc_ret(trapframe *tf, int entry)
{
  102e5d:	55                   	push   %ebp
  102e5e:	89 e5                	mov    %esp,%ebp
  102e60:	83 ec 28             	sub    $0x28,%esp
	//panic("proc_ret not implemented");
	proc *cp = proc_cur();
  102e63:	e8 a1 fb ff ff       	call   102a09 <cpu_cur>
  102e68:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  102e6e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  	proc *pp = cp->parent;
  102e71:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102e74:	8b 40 38             	mov    0x38(%eax),%eax
  102e77:	89 45 f0             	mov    %eax,-0x10(%ebp)
  	// Root process incurs trap...
  	if(pp == NULL) {
  102e7a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  102e7e:	75 1b                	jne    102e9b <proc_ret+0x3e>
    	if(tf->trapno != T_SYSCALL) {
  102e80:	8b 45 08             	mov    0x8(%ebp),%eax
  102e83:	8b 40 30             	mov    0x30(%eax),%eax
  102e86:	83 f8 30             	cmp    $0x30,%eax
  102e89:	74 0b                	je     102e96 <proc_ret+0x39>
      		trap_print(tf);
  102e8b:	8b 45 08             	mov    0x8(%ebp),%eax
  102e8e:	89 04 24             	mov    %eax,(%esp)
  102e91:	e8 3c e9 ff ff       	call   1017d2 <trap_print>
      		//panic("proc_ret: trap in root process\n");
    	}
    	done();
  102e96:	e8 df d3 ff ff       	call   10027a <done>
  	}
  	spinlock_acquire(&cp->lock);
  102e9b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102e9e:	89 04 24             	mov    %eax,(%esp)
  102ea1:	e8 16 f5 ff ff       	call   1023bc <spinlock_acquire>
  	cp->state = PROC_STOP;
  102ea6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102ea9:	c7 80 3c 04 00 00 00 	movl   $0x0,0x43c(%eax)
  102eb0:	00 00 00 
  	proc_save(cp, tf, entry);
  102eb3:	8b 45 0c             	mov    0xc(%ebp),%eax
  102eb6:	89 44 24 08          	mov    %eax,0x8(%esp)
  102eba:	8b 45 08             	mov    0x8(%ebp),%eax
  102ebd:	89 44 24 04          	mov    %eax,0x4(%esp)
  102ec1:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102ec4:	89 04 24             	mov    %eax,(%esp)
  102ec7:	e8 ef fd ff ff       	call   102cbb <proc_save>
  	spinlock_release(&cp->lock);
  102ecc:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102ecf:	89 04 24             	mov    %eax,(%esp)
  102ed2:	e8 61 f5 ff ff       	call   102438 <spinlock_release>
  	spinlock_acquire(&pp->lock);
  102ed7:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102eda:	89 04 24             	mov    %eax,(%esp)
  102edd:	e8 da f4 ff ff       	call   1023bc <spinlock_acquire>

  	if(pp->waitchild == cp) {
  102ee2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102ee5:	8b 80 48 04 00 00    	mov    0x448(%eax),%eax
  102eeb:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  102eee:	75 18                	jne    102f08 <proc_ret+0xab>
    	pp->waitchild = NULL;
  102ef0:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102ef3:	c7 80 48 04 00 00 00 	movl   $0x0,0x448(%eax)
  102efa:	00 00 00 
    	proc_run(pp);
  102efd:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102f00:	89 04 24             	mov    %eax,(%esp)
  102f03:	e8 c9 fe ff ff       	call   102dd1 <proc_run>
 	}
  	spinlock_release(&pp->lock);
  102f08:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102f0b:	89 04 24             	mov    %eax,(%esp)
  102f0e:	e8 25 f5 ff ff       	call   102438 <spinlock_release>
  	// On to the next one
  	proc_sched();
  102f13:	e8 3a fe ff ff       	call   102d52 <proc_sched>

00102f18 <proc_check>:
static volatile uint32_t pingpong = 0;
static void *recovargs;

void
proc_check(void)
{
  102f18:	55                   	push   %ebp
  102f19:	89 e5                	mov    %esp,%ebp
  102f1b:	57                   	push   %edi
  102f1c:	56                   	push   %esi
  102f1d:	53                   	push   %ebx
  102f1e:	81 ec dc 00 00 00    	sub    $0xdc,%esp
	// Spawn 2 child processes, executing on statically allocated stacks.

	int i;
	for (i = 0; i < 4; i++) {
  102f24:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
  102f2b:	e9 a6 00 00 00       	jmp    102fd6 <proc_check+0xbe>
		// Setup register state for child
		uint32_t *esp = (uint32_t*) &child_stack[i][PAGESIZE];
  102f30:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  102f33:	83 c0 01             	add    $0x1,%eax
  102f36:	c1 e0 0c             	shl    $0xc,%eax
  102f39:	05 70 c2 10 00       	add    $0x10c270,%eax
  102f3e:	89 45 e0             	mov    %eax,-0x20(%ebp)
		*--esp = i;	// push argument to child() function
  102f41:	83 6d e0 04          	subl   $0x4,-0x20(%ebp)
  102f45:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  102f48:	8b 45 e0             	mov    -0x20(%ebp),%eax
  102f4b:	89 10                	mov    %edx,(%eax)
		*--esp = 0;	// fake return address
  102f4d:	83 6d e0 04          	subl   $0x4,-0x20(%ebp)
  102f51:	8b 45 e0             	mov    -0x20(%ebp),%eax
  102f54:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		child_state.tf.eip = (uint32_t) child;
  102f5a:	b8 8e 33 10 00       	mov    $0x10338e,%eax
  102f5f:	a3 58 c0 10 00       	mov    %eax,0x10c058
		child_state.tf.esp = (uint32_t) esp;
  102f64:	8b 45 e0             	mov    -0x20(%ebp),%eax
  102f67:	a3 64 c0 10 00       	mov    %eax,0x10c064

		// Use PUT syscall to create each child,
		// but only start the first 2 children for now.
		cprintf("spawning child %d\n", i);
  102f6c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  102f6f:	89 44 24 04          	mov    %eax,0x4(%esp)
  102f73:	c7 04 24 5d 60 10 00 	movl   $0x10605d,(%esp)
  102f7a:	e8 85 1c 00 00       	call   104c04 <cprintf>
		sys_put(SYS_REGS | (i < 2 ? SYS_START : 0), i, &child_state,
  102f7f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  102f82:	0f b7 d0             	movzwl %ax,%edx
  102f85:	83 7d e4 01          	cmpl   $0x1,-0x1c(%ebp)
  102f89:	7f 07                	jg     102f92 <proc_check+0x7a>
  102f8b:	b8 10 10 00 00       	mov    $0x1010,%eax
  102f90:	eb 05                	jmp    102f97 <proc_check+0x7f>
  102f92:	b8 00 10 00 00       	mov    $0x1000,%eax
  102f97:	89 45 d8             	mov    %eax,-0x28(%ebp)
  102f9a:	66 89 55 d6          	mov    %dx,-0x2a(%ebp)
  102f9e:	c7 45 d0 20 c0 10 00 	movl   $0x10c020,-0x30(%ebp)
  102fa5:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
  102fac:	c7 45 c8 00 00 00 00 	movl   $0x0,-0x38(%ebp)
  102fb3:	c7 45 c4 00 00 00 00 	movl   $0x0,-0x3c(%ebp)
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  102fba:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102fbd:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  102fc0:	8b 5d d0             	mov    -0x30(%ebp),%ebx
  102fc3:	0f b7 55 d6          	movzwl -0x2a(%ebp),%edx
  102fc7:	8b 75 cc             	mov    -0x34(%ebp),%esi
  102fca:	8b 7d c8             	mov    -0x38(%ebp),%edi
  102fcd:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
  102fd0:	cd 30                	int    $0x30
proc_check(void)
{
	// Spawn 2 child processes, executing on statically allocated stacks.

	int i;
	for (i = 0; i < 4; i++) {
  102fd2:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
  102fd6:	83 7d e4 03          	cmpl   $0x3,-0x1c(%ebp)
  102fda:	0f 8e 50 ff ff ff    	jle    102f30 <proc_check+0x18>
	}

	// Wait for both children to complete.
	// This should complete without preemptive scheduling
	// when we're running on a 2-processor machine.
	for (i = 0; i < 2; i++) {
  102fe0:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
  102fe7:	eb 5c                	jmp    103045 <proc_check+0x12d>
		cprintf("waiting for child %d\n", i);
  102fe9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  102fec:	89 44 24 04          	mov    %eax,0x4(%esp)
  102ff0:	c7 04 24 70 60 10 00 	movl   $0x106070,(%esp)
  102ff7:	e8 08 1c 00 00       	call   104c04 <cprintf>
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  102ffc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  102fff:	0f b7 c0             	movzwl %ax,%eax
  103002:	c7 45 c0 00 10 00 00 	movl   $0x1000,-0x40(%ebp)
  103009:	66 89 45 be          	mov    %ax,-0x42(%ebp)
  10300d:	c7 45 b8 20 c0 10 00 	movl   $0x10c020,-0x48(%ebp)
  103014:	c7 45 b4 00 00 00 00 	movl   $0x0,-0x4c(%ebp)
  10301b:	c7 45 b0 00 00 00 00 	movl   $0x0,-0x50(%ebp)
  103022:	c7 45 ac 00 00 00 00 	movl   $0x0,-0x54(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  103029:	8b 45 c0             	mov    -0x40(%ebp),%eax
  10302c:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  10302f:	8b 5d b8             	mov    -0x48(%ebp),%ebx
  103032:	0f b7 55 be          	movzwl -0x42(%ebp),%edx
  103036:	8b 75 b4             	mov    -0x4c(%ebp),%esi
  103039:	8b 7d b0             	mov    -0x50(%ebp),%edi
  10303c:	8b 4d ac             	mov    -0x54(%ebp),%ecx
  10303f:	cd 30                	int    $0x30
	}

	// Wait for both children to complete.
	// This should complete without preemptive scheduling
	// when we're running on a 2-processor machine.
	for (i = 0; i < 2; i++) {
  103041:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
  103045:	83 7d e4 01          	cmpl   $0x1,-0x1c(%ebp)
  103049:	7e 9e                	jle    102fe9 <proc_check+0xd1>
		cprintf("waiting for child %d\n", i);
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
	}
	cprintf("proc_check() 2-child test succeeded\n");
  10304b:	c7 04 24 88 60 10 00 	movl   $0x106088,(%esp)
  103052:	e8 ad 1b 00 00       	call   104c04 <cprintf>

	// (Re)start all four children, and wait for them.
	// This will require preemptive scheduling to complete
	// if we have less than 4 CPUs.
	cprintf("proc_check: spawning 4 children\n");
  103057:	c7 04 24 b0 60 10 00 	movl   $0x1060b0,(%esp)
  10305e:	e8 a1 1b 00 00       	call   104c04 <cprintf>
	for (i = 0; i < 4; i++) {
  103063:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
  10306a:	eb 5c                	jmp    1030c8 <proc_check+0x1b0>
		cprintf("spawning child %d\n", i);
  10306c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10306f:	89 44 24 04          	mov    %eax,0x4(%esp)
  103073:	c7 04 24 5d 60 10 00 	movl   $0x10605d,(%esp)
  10307a:	e8 85 1b 00 00       	call   104c04 <cprintf>
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
  10307f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103082:	0f b7 c0             	movzwl %ax,%eax
  103085:	c7 45 a8 10 00 00 00 	movl   $0x10,-0x58(%ebp)
  10308c:	66 89 45 a6          	mov    %ax,-0x5a(%ebp)
  103090:	c7 45 a0 00 00 00 00 	movl   $0x0,-0x60(%ebp)
  103097:	c7 45 9c 00 00 00 00 	movl   $0x0,-0x64(%ebp)
  10309e:	c7 45 98 00 00 00 00 	movl   $0x0,-0x68(%ebp)
  1030a5:	c7 45 94 00 00 00 00 	movl   $0x0,-0x6c(%ebp)
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  1030ac:	8b 45 a8             	mov    -0x58(%ebp),%eax
  1030af:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  1030b2:	8b 5d a0             	mov    -0x60(%ebp),%ebx
  1030b5:	0f b7 55 a6          	movzwl -0x5a(%ebp),%edx
  1030b9:	8b 75 9c             	mov    -0x64(%ebp),%esi
  1030bc:	8b 7d 98             	mov    -0x68(%ebp),%edi
  1030bf:	8b 4d 94             	mov    -0x6c(%ebp),%ecx
  1030c2:	cd 30                	int    $0x30

	// (Re)start all four children, and wait for them.
	// This will require preemptive scheduling to complete
	// if we have less than 4 CPUs.
	cprintf("proc_check: spawning 4 children\n");
	for (i = 0; i < 4; i++) {
  1030c4:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
  1030c8:	83 7d e4 03          	cmpl   $0x3,-0x1c(%ebp)
  1030cc:	7e 9e                	jle    10306c <proc_check+0x154>
		cprintf("spawning child %d\n", i);
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
	}

	// Wait for all 4 children to complete.
	for (i = 0; i < 4; i++)
  1030ce:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
  1030d5:	eb 4f                	jmp    103126 <proc_check+0x20e>
		sys_get(0, i, NULL, NULL, NULL, 0);
  1030d7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1030da:	0f b7 c0             	movzwl %ax,%eax
  1030dd:	c7 45 90 00 00 00 00 	movl   $0x0,-0x70(%ebp)
  1030e4:	66 89 45 8e          	mov    %ax,-0x72(%ebp)
  1030e8:	c7 45 88 00 00 00 00 	movl   $0x0,-0x78(%ebp)
  1030ef:	c7 45 84 00 00 00 00 	movl   $0x0,-0x7c(%ebp)
  1030f6:	c7 45 80 00 00 00 00 	movl   $0x0,-0x80(%ebp)
  1030fd:	c7 85 7c ff ff ff 00 	movl   $0x0,-0x84(%ebp)
  103104:	00 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  103107:	8b 45 90             	mov    -0x70(%ebp),%eax
  10310a:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  10310d:	8b 5d 88             	mov    -0x78(%ebp),%ebx
  103110:	0f b7 55 8e          	movzwl -0x72(%ebp),%edx
  103114:	8b 75 84             	mov    -0x7c(%ebp),%esi
  103117:	8b 7d 80             	mov    -0x80(%ebp),%edi
  10311a:	8b 8d 7c ff ff ff    	mov    -0x84(%ebp),%ecx
  103120:	cd 30                	int    $0x30
		cprintf("spawning child %d\n", i);
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
	}

	// Wait for all 4 children to complete.
	for (i = 0; i < 4; i++)
  103122:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
  103126:	83 7d e4 03          	cmpl   $0x3,-0x1c(%ebp)
  10312a:	7e ab                	jle    1030d7 <proc_check+0x1bf>
		sys_get(0, i, NULL, NULL, NULL, 0);
	cprintf("proc_check() 4-child test succeeded\n");
  10312c:	c7 04 24 d4 60 10 00 	movl   $0x1060d4,(%esp)
  103133:	e8 cc 1a 00 00       	call   104c04 <cprintf>

	// Now do a trap handling test using all 4 children -
	// but they'll _think_ they're all child 0!
	// (We'll lose the register state of the other children.)
	i = 0;
  103138:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  10313f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103142:	0f b7 c0             	movzwl %ax,%eax
  103145:	c7 85 78 ff ff ff 00 	movl   $0x1000,-0x88(%ebp)
  10314c:	10 00 00 
  10314f:	66 89 85 76 ff ff ff 	mov    %ax,-0x8a(%ebp)
  103156:	c7 85 70 ff ff ff 20 	movl   $0x10c020,-0x90(%ebp)
  10315d:	c0 10 00 
  103160:	c7 85 6c ff ff ff 00 	movl   $0x0,-0x94(%ebp)
  103167:	00 00 00 
  10316a:	c7 85 68 ff ff ff 00 	movl   $0x0,-0x98(%ebp)
  103171:	00 00 00 
  103174:	c7 85 64 ff ff ff 00 	movl   $0x0,-0x9c(%ebp)
  10317b:	00 00 00 
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  10317e:	8b 85 78 ff ff ff    	mov    -0x88(%ebp),%eax
  103184:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  103187:	8b 9d 70 ff ff ff    	mov    -0x90(%ebp),%ebx
  10318d:	0f b7 95 76 ff ff ff 	movzwl -0x8a(%ebp),%edx
  103194:	8b b5 6c ff ff ff    	mov    -0x94(%ebp),%esi
  10319a:	8b bd 68 ff ff ff    	mov    -0x98(%ebp),%edi
  1031a0:	8b 8d 64 ff ff ff    	mov    -0x9c(%ebp),%ecx
  1031a6:	cd 30                	int    $0x30
		// get child 0's state
	assert(recovargs == NULL);
  1031a8:	a1 74 02 11 00       	mov    0x110274,%eax
  1031ad:	85 c0                	test   %eax,%eax
  1031af:	74 24                	je     1031d5 <proc_check+0x2bd>
  1031b1:	c7 44 24 0c f9 60 10 	movl   $0x1060f9,0xc(%esp)
  1031b8:	00 
  1031b9:	c7 44 24 08 ba 5f 10 	movl   $0x105fba,0x8(%esp)
  1031c0:	00 
  1031c1:	c7 44 24 04 07 01 00 	movl   $0x107,0x4(%esp)
  1031c8:	00 
  1031c9:	c7 04 24 dc 5f 10 00 	movl   $0x105fdc,(%esp)
  1031d0:	e8 ef d2 ff ff       	call   1004c4 <debug_panic>
	do {
		sys_put(SYS_REGS | SYS_START, i, &child_state, NULL, NULL, 0);
  1031d5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1031d8:	0f b7 c0             	movzwl %ax,%eax
  1031db:	c7 85 60 ff ff ff 10 	movl   $0x1010,-0xa0(%ebp)
  1031e2:	10 00 00 
  1031e5:	66 89 85 5e ff ff ff 	mov    %ax,-0xa2(%ebp)
  1031ec:	c7 85 58 ff ff ff 20 	movl   $0x10c020,-0xa8(%ebp)
  1031f3:	c0 10 00 
  1031f6:	c7 85 54 ff ff ff 00 	movl   $0x0,-0xac(%ebp)
  1031fd:	00 00 00 
  103200:	c7 85 50 ff ff ff 00 	movl   $0x0,-0xb0(%ebp)
  103207:	00 00 00 
  10320a:	c7 85 4c ff ff ff 00 	movl   $0x0,-0xb4(%ebp)
  103211:	00 00 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  103214:	8b 85 60 ff ff ff    	mov    -0xa0(%ebp),%eax
  10321a:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  10321d:	8b 9d 58 ff ff ff    	mov    -0xa8(%ebp),%ebx
  103223:	0f b7 95 5e ff ff ff 	movzwl -0xa2(%ebp),%edx
  10322a:	8b b5 54 ff ff ff    	mov    -0xac(%ebp),%esi
  103230:	8b bd 50 ff ff ff    	mov    -0xb0(%ebp),%edi
  103236:	8b 8d 4c ff ff ff    	mov    -0xb4(%ebp),%ecx
  10323c:	cd 30                	int    $0x30
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  10323e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103241:	0f b7 c0             	movzwl %ax,%eax
  103244:	c7 85 48 ff ff ff 00 	movl   $0x1000,-0xb8(%ebp)
  10324b:	10 00 00 
  10324e:	66 89 85 46 ff ff ff 	mov    %ax,-0xba(%ebp)
  103255:	c7 85 40 ff ff ff 20 	movl   $0x10c020,-0xc0(%ebp)
  10325c:	c0 10 00 
  10325f:	c7 85 3c ff ff ff 00 	movl   $0x0,-0xc4(%ebp)
  103266:	00 00 00 
  103269:	c7 85 38 ff ff ff 00 	movl   $0x0,-0xc8(%ebp)
  103270:	00 00 00 
  103273:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  10327a:	00 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  10327d:	8b 85 48 ff ff ff    	mov    -0xb8(%ebp),%eax
  103283:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  103286:	8b 9d 40 ff ff ff    	mov    -0xc0(%ebp),%ebx
  10328c:	0f b7 95 46 ff ff ff 	movzwl -0xba(%ebp),%edx
  103293:	8b b5 3c ff ff ff    	mov    -0xc4(%ebp),%esi
  103299:	8b bd 38 ff ff ff    	mov    -0xc8(%ebp),%edi
  10329f:	8b 8d 34 ff ff ff    	mov    -0xcc(%ebp),%ecx
  1032a5:	cd 30                	int    $0x30
		if (recovargs) {	// trap recovery needed
  1032a7:	a1 74 02 11 00       	mov    0x110274,%eax
  1032ac:	85 c0                	test   %eax,%eax
  1032ae:	74 36                	je     1032e6 <proc_check+0x3ce>
			trap_check_args *args = recovargs;
  1032b0:	a1 74 02 11 00       	mov    0x110274,%eax
  1032b5:	89 45 dc             	mov    %eax,-0x24(%ebp)
			cprintf("recover from trap %d\n",
  1032b8:	a1 50 c0 10 00       	mov    0x10c050,%eax
  1032bd:	89 44 24 04          	mov    %eax,0x4(%esp)
  1032c1:	c7 04 24 0b 61 10 00 	movl   $0x10610b,(%esp)
  1032c8:	e8 37 19 00 00       	call   104c04 <cprintf>
				child_state.tf.trapno);
			child_state.tf.eip = (uint32_t) args->reip;
  1032cd:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1032d0:	8b 00                	mov    (%eax),%eax
  1032d2:	a3 58 c0 10 00       	mov    %eax,0x10c058
			args->trapno = child_state.tf.trapno;
  1032d7:	a1 50 c0 10 00       	mov    0x10c050,%eax
  1032dc:	89 c2                	mov    %eax,%edx
  1032de:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1032e1:	89 50 04             	mov    %edx,0x4(%eax)
  1032e4:	eb 2e                	jmp    103314 <proc_check+0x3fc>
		} else
			assert(child_state.tf.trapno == T_SYSCALL);
  1032e6:	a1 50 c0 10 00       	mov    0x10c050,%eax
  1032eb:	83 f8 30             	cmp    $0x30,%eax
  1032ee:	74 24                	je     103314 <proc_check+0x3fc>
  1032f0:	c7 44 24 0c 24 61 10 	movl   $0x106124,0xc(%esp)
  1032f7:	00 
  1032f8:	c7 44 24 08 ba 5f 10 	movl   $0x105fba,0x8(%esp)
  1032ff:	00 
  103300:	c7 44 24 04 12 01 00 	movl   $0x112,0x4(%esp)
  103307:	00 
  103308:	c7 04 24 dc 5f 10 00 	movl   $0x105fdc,(%esp)
  10330f:	e8 b0 d1 ff ff       	call   1004c4 <debug_panic>
		i = (i+1) % 4;	// rotate to next child proc
  103314:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103317:	8d 50 01             	lea    0x1(%eax),%edx
  10331a:	89 d0                	mov    %edx,%eax
  10331c:	c1 f8 1f             	sar    $0x1f,%eax
  10331f:	c1 e8 1e             	shr    $0x1e,%eax
  103322:	01 c2                	add    %eax,%edx
  103324:	83 e2 03             	and    $0x3,%edx
  103327:	89 d1                	mov    %edx,%ecx
  103329:	29 c1                	sub    %eax,%ecx
  10332b:	89 c8                	mov    %ecx,%eax
  10332d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	} while (child_state.tf.trapno != T_SYSCALL);
  103330:	a1 50 c0 10 00       	mov    0x10c050,%eax
  103335:	83 f8 30             	cmp    $0x30,%eax
  103338:	0f 85 97 fe ff ff    	jne    1031d5 <proc_check+0x2bd>
	assert(recovargs == NULL);
  10333e:	a1 74 02 11 00       	mov    0x110274,%eax
  103343:	85 c0                	test   %eax,%eax
  103345:	74 24                	je     10336b <proc_check+0x453>
  103347:	c7 44 24 0c f9 60 10 	movl   $0x1060f9,0xc(%esp)
  10334e:	00 
  10334f:	c7 44 24 08 ba 5f 10 	movl   $0x105fba,0x8(%esp)
  103356:	00 
  103357:	c7 44 24 04 15 01 00 	movl   $0x115,0x4(%esp)
  10335e:	00 
  10335f:	c7 04 24 dc 5f 10 00 	movl   $0x105fdc,(%esp)
  103366:	e8 59 d1 ff ff       	call   1004c4 <debug_panic>

	cprintf("proc_check() trap reflection test succeeded\n");
  10336b:	c7 04 24 48 61 10 00 	movl   $0x106148,(%esp)
  103372:	e8 8d 18 00 00       	call   104c04 <cprintf>

	cprintf("proc_check() succeeded!\n");
  103377:	c7 04 24 75 61 10 00 	movl   $0x106175,(%esp)
  10337e:	e8 81 18 00 00       	call   104c04 <cprintf>
}
  103383:	81 c4 dc 00 00 00    	add    $0xdc,%esp
  103389:	5b                   	pop    %ebx
  10338a:	5e                   	pop    %esi
  10338b:	5f                   	pop    %edi
  10338c:	5d                   	pop    %ebp
  10338d:	c3                   	ret    

0010338e <child>:

static void child(int n)
{
  10338e:	55                   	push   %ebp
  10338f:	89 e5                	mov    %esp,%ebp
  103391:	83 ec 28             	sub    $0x28,%esp
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
  103394:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
  103398:	7f 64                	jg     1033fe <child+0x70>
		int i;
		for (i = 0; i < 10; i++) {
  10339a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  1033a1:	eb 4e                	jmp    1033f1 <child+0x63>
			cprintf("in child %d count %d\n", n, i);
  1033a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1033a6:	89 44 24 08          	mov    %eax,0x8(%esp)
  1033aa:	8b 45 08             	mov    0x8(%ebp),%eax
  1033ad:	89 44 24 04          	mov    %eax,0x4(%esp)
  1033b1:	c7 04 24 8e 61 10 00 	movl   $0x10618e,(%esp)
  1033b8:	e8 47 18 00 00       	call   104c04 <cprintf>
			while (pingpong != n)
  1033bd:	eb 05                	jmp    1033c4 <child+0x36>
				pause();
  1033bf:	e8 3e f6 ff ff       	call   102a02 <pause>
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
		int i;
		for (i = 0; i < 10; i++) {
			cprintf("in child %d count %d\n", n, i);
			while (pingpong != n)
  1033c4:	8b 55 08             	mov    0x8(%ebp),%edx
  1033c7:	a1 70 02 11 00       	mov    0x110270,%eax
  1033cc:	39 c2                	cmp    %eax,%edx
  1033ce:	75 ef                	jne    1033bf <child+0x31>
				pause();
			xchg(&pingpong, !pingpong);
  1033d0:	a1 70 02 11 00       	mov    0x110270,%eax
  1033d5:	85 c0                	test   %eax,%eax
  1033d7:	0f 94 c0             	sete   %al
  1033da:	0f b6 c0             	movzbl %al,%eax
  1033dd:	89 44 24 04          	mov    %eax,0x4(%esp)
  1033e1:	c7 04 24 70 02 11 00 	movl   $0x110270,(%esp)
  1033e8:	e8 df f5 ff ff       	call   1029cc <xchg>
static void child(int n)
{
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
		int i;
		for (i = 0; i < 10; i++) {
  1033ed:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  1033f1:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  1033f5:	7e ac                	jle    1033a3 <child+0x15>
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
  1033f7:	b8 03 00 00 00       	mov    $0x3,%eax
  1033fc:	cd 30                	int    $0x30
		sys_ret();
	}

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
  1033fe:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  103405:	eb 4c                	jmp    103453 <child+0xc5>
		cprintf("in child %d count %d\n", n, i);
  103407:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10340a:	89 44 24 08          	mov    %eax,0x8(%esp)
  10340e:	8b 45 08             	mov    0x8(%ebp),%eax
  103411:	89 44 24 04          	mov    %eax,0x4(%esp)
  103415:	c7 04 24 8e 61 10 00 	movl   $0x10618e,(%esp)
  10341c:	e8 e3 17 00 00       	call   104c04 <cprintf>
		while (pingpong != n)
  103421:	eb 05                	jmp    103428 <child+0x9a>
			pause();
  103423:	e8 da f5 ff ff       	call   102a02 <pause>

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
		cprintf("in child %d count %d\n", n, i);
		while (pingpong != n)
  103428:	8b 55 08             	mov    0x8(%ebp),%edx
  10342b:	a1 70 02 11 00       	mov    0x110270,%eax
  103430:	39 c2                	cmp    %eax,%edx
  103432:	75 ef                	jne    103423 <child+0x95>
			pause();
		xchg(&pingpong, (pingpong + 1) % 4);
  103434:	a1 70 02 11 00       	mov    0x110270,%eax
  103439:	83 c0 01             	add    $0x1,%eax
  10343c:	83 e0 03             	and    $0x3,%eax
  10343f:	89 44 24 04          	mov    %eax,0x4(%esp)
  103443:	c7 04 24 70 02 11 00 	movl   $0x110270,(%esp)
  10344a:	e8 7d f5 ff ff       	call   1029cc <xchg>
		sys_ret();
	}

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
  10344f:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  103453:	83 7d f0 09          	cmpl   $0x9,-0x10(%ebp)
  103457:	7e ae                	jle    103407 <child+0x79>
  103459:	b8 03 00 00 00       	mov    $0x3,%eax
  10345e:	cd 30                	int    $0x30
		xchg(&pingpong, (pingpong + 1) % 4);
	}
	sys_ret();

	// Only "child 0" (or the proc that thinks it's child 0), trap check...
	if (n == 0) {
  103460:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  103464:	75 6d                	jne    1034d3 <child+0x145>
		assert(recovargs == NULL);
  103466:	a1 74 02 11 00       	mov    0x110274,%eax
  10346b:	85 c0                	test   %eax,%eax
  10346d:	74 24                	je     103493 <child+0x105>
  10346f:	c7 44 24 0c f9 60 10 	movl   $0x1060f9,0xc(%esp)
  103476:	00 
  103477:	c7 44 24 08 ba 5f 10 	movl   $0x105fba,0x8(%esp)
  10347e:	00 
  10347f:	c7 44 24 04 36 01 00 	movl   $0x136,0x4(%esp)
  103486:	00 
  103487:	c7 04 24 dc 5f 10 00 	movl   $0x105fdc,(%esp)
  10348e:	e8 31 d0 ff ff       	call   1004c4 <debug_panic>
		trap_check(&recovargs);
  103493:	c7 04 24 74 02 11 00 	movl   $0x110274,(%esp)
  10349a:	e8 2f e7 ff ff       	call   101bce <trap_check>
		assert(recovargs == NULL);
  10349f:	a1 74 02 11 00       	mov    0x110274,%eax
  1034a4:	85 c0                	test   %eax,%eax
  1034a6:	74 24                	je     1034cc <child+0x13e>
  1034a8:	c7 44 24 0c f9 60 10 	movl   $0x1060f9,0xc(%esp)
  1034af:	00 
  1034b0:	c7 44 24 08 ba 5f 10 	movl   $0x105fba,0x8(%esp)
  1034b7:	00 
  1034b8:	c7 44 24 04 38 01 00 	movl   $0x138,0x4(%esp)
  1034bf:	00 
  1034c0:	c7 04 24 dc 5f 10 00 	movl   $0x105fdc,(%esp)
  1034c7:	e8 f8 cf ff ff       	call   1004c4 <debug_panic>
  1034cc:	b8 03 00 00 00       	mov    $0x3,%eax
  1034d1:	cd 30                	int    $0x30
		sys_ret();
	}

	panic("child(): shouldn't have gotten here");
  1034d3:	c7 44 24 08 a4 61 10 	movl   $0x1061a4,0x8(%esp)
  1034da:	00 
  1034db:	c7 44 24 04 3c 01 00 	movl   $0x13c,0x4(%esp)
  1034e2:	00 
  1034e3:	c7 04 24 dc 5f 10 00 	movl   $0x105fdc,(%esp)
  1034ea:	e8 d5 cf ff ff       	call   1004c4 <debug_panic>

001034ef <grandchild>:
}

static void grandchild(int n)
{
  1034ef:	55                   	push   %ebp
  1034f0:	89 e5                	mov    %esp,%ebp
  1034f2:	83 ec 18             	sub    $0x18,%esp
	panic("grandchild(): shouldn't have gotten here");
  1034f5:	c7 44 24 08 c8 61 10 	movl   $0x1061c8,0x8(%esp)
  1034fc:	00 
  1034fd:	c7 44 24 04 41 01 00 	movl   $0x141,0x4(%esp)
  103504:	00 
  103505:	c7 04 24 dc 5f 10 00 	movl   $0x105fdc,(%esp)
  10350c:	e8 b3 cf ff ff       	call   1004c4 <debug_panic>
  103511:	90                   	nop
  103512:	90                   	nop
  103513:	90                   	nop

00103514 <systrap>:
// During a system call, generate a specific processor trap -
// as if the user code's INT 0x30 instruction had caused it -
// and reflect the trap to the parent process as with other traps.
static void gcc_noreturn
systrap(trapframe *utf, int trapno, int err)
{
  103514:	55                   	push   %ebp
  103515:	89 e5                	mov    %esp,%ebp
  103517:	83 ec 18             	sub    $0x18,%esp
	panic("systrap() not implemented.");
  10351a:	c7 44 24 08 f4 61 10 	movl   $0x1061f4,0x8(%esp)
  103521:	00 
  103522:	c7 44 24 04 24 00 00 	movl   $0x24,0x4(%esp)
  103529:	00 
  10352a:	c7 04 24 0f 62 10 00 	movl   $0x10620f,(%esp)
  103531:	e8 8e cf ff ff       	call   1004c4 <debug_panic>

00103536 <sysrecover>:
// - Be sure the parent gets the correct trapno, err, and eip values.
// - Be sure to release any spinlocks you were holding during the copyin/out.
//
static void gcc_noreturn
sysrecover(trapframe *ktf, void *recoverdata)
{
  103536:	55                   	push   %ebp
  103537:	89 e5                	mov    %esp,%ebp
  103539:	83 ec 18             	sub    $0x18,%esp
	panic("sysrecover() not implemented.");
  10353c:	c7 44 24 08 1e 62 10 	movl   $0x10621e,0x8(%esp)
  103543:	00 
  103544:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
  10354b:	00 
  10354c:	c7 04 24 0f 62 10 00 	movl   $0x10620f,(%esp)
  103553:	e8 6c cf ff ff       	call   1004c4 <debug_panic>

00103558 <checkva>:
//
// Note: Be careful that your arithmetic works correctly
// even if size is very large, e.g., if uva+size wraps around!
//
static void checkva(trapframe *utf, uint32_t uva, size_t size)
{
  103558:	55                   	push   %ebp
  103559:	89 e5                	mov    %esp,%ebp
  10355b:	83 ec 18             	sub    $0x18,%esp
	panic("checkva() not implemented.");
  10355e:	c7 44 24 08 3c 62 10 	movl   $0x10623c,0x8(%esp)
  103565:	00 
  103566:	c7 44 24 04 42 00 00 	movl   $0x42,0x4(%esp)
  10356d:	00 
  10356e:	c7 04 24 0f 62 10 00 	movl   $0x10620f,(%esp)
  103575:	e8 4a cf ff ff       	call   1004c4 <debug_panic>

0010357a <usercopy>:
// Copy data to/from user space,
// using checkva() above to validate the address range
// and using sysrecover() to recover from any traps during the copy.
void usercopy(trapframe *utf, bool copyout,
			void *kva, uint32_t uva, size_t size)
{
  10357a:	55                   	push   %ebp
  10357b:	89 e5                	mov    %esp,%ebp
  10357d:	83 ec 18             	sub    $0x18,%esp
	checkva(utf, uva, size);
  103580:	8b 45 18             	mov    0x18(%ebp),%eax
  103583:	89 44 24 08          	mov    %eax,0x8(%esp)
  103587:	8b 45 14             	mov    0x14(%ebp),%eax
  10358a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10358e:	8b 45 08             	mov    0x8(%ebp),%eax
  103591:	89 04 24             	mov    %eax,(%esp)
  103594:	e8 bf ff ff ff       	call   103558 <checkva>

	// Now do the copy, but recover from page faults.
	panic("syscall_usercopy() not implemented.");
  103599:	c7 44 24 08 58 62 10 	movl   $0x106258,0x8(%esp)
  1035a0:	00 
  1035a1:	c7 44 24 04 4e 00 00 	movl   $0x4e,0x4(%esp)
  1035a8:	00 
  1035a9:	c7 04 24 0f 62 10 00 	movl   $0x10620f,(%esp)
  1035b0:	e8 0f cf ff ff       	call   1004c4 <debug_panic>

001035b5 <do_cputs>:
}

static void
do_cputs(trapframe *tf, uint32_t cmd)
{
  1035b5:	55                   	push   %ebp
  1035b6:	89 e5                	mov    %esp,%ebp
  1035b8:	83 ec 18             	sub    $0x18,%esp
	// Print the string supplied by the user: pointer in EBX
	cprintf("%s", (char*)tf->regs.ebx);
  1035bb:	8b 45 08             	mov    0x8(%ebp),%eax
  1035be:	8b 40 10             	mov    0x10(%eax),%eax
  1035c1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1035c5:	c7 04 24 7c 62 10 00 	movl   $0x10627c,(%esp)
  1035cc:	e8 33 16 00 00       	call   104c04 <cprintf>

	trap_return(tf);	// syscall completed
  1035d1:	8b 45 08             	mov    0x8(%ebp),%eax
  1035d4:	89 04 24             	mov    %eax,(%esp)
  1035d7:	e8 24 e9 ff ff       	call   101f00 <trap_return>

001035dc <syscall>:
// Common function to handle all system calls -
// decode the system call type and call an appropriate handler function.
// Be sure to handle undefined system calls appropriately.
void
syscall(trapframe *tf)
{
  1035dc:	55                   	push   %ebp
  1035dd:	89 e5                	mov    %esp,%ebp
  1035df:	83 ec 28             	sub    $0x28,%esp
	// EAX register holds system call command/flags
	uint32_t cmd = tf->regs.eax;
  1035e2:	8b 45 08             	mov    0x8(%ebp),%eax
  1035e5:	8b 40 1c             	mov    0x1c(%eax),%eax
  1035e8:	89 45 f4             	mov    %eax,-0xc(%ebp)
	switch (cmd & SYS_TYPE) {
  1035eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1035ee:	83 e0 0f             	and    $0xf,%eax
  1035f1:	85 c0                	test   %eax,%eax
  1035f3:	75 14                	jne    103609 <syscall+0x2d>
	case SYS_CPUTS:	return do_cputs(tf, cmd);
  1035f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1035f8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1035fc:	8b 45 08             	mov    0x8(%ebp),%eax
  1035ff:	89 04 24             	mov    %eax,(%esp)
  103602:	e8 ae ff ff ff       	call   1035b5 <do_cputs>
  103607:	eb 01                	jmp    10360a <syscall+0x2e>
	// Your implementations of SYS_PUT, SYS_GET, SYS_RET here...
	default:	return;		// handle as a regular trap
  103609:	90                   	nop
	}
}
  10360a:	c9                   	leave  
  10360b:	c3                   	ret    

0010360c <video_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

void
video_init(void)
{
  10360c:	55                   	push   %ebp
  10360d:	89 e5                	mov    %esp,%ebp
  10360f:	53                   	push   %ebx
  103610:	83 ec 34             	sub    $0x34,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	/* Get a pointer to the memory-mapped text display buffer. */
	cp = (uint16_t*) mem_ptr(CGA_BUF);
  103613:	c7 45 f8 00 80 0b 00 	movl   $0xb8000,-0x8(%ebp)
	was = *cp;
  10361a:	8b 45 f8             	mov    -0x8(%ebp),%eax
  10361d:	0f b7 00             	movzwl (%eax),%eax
  103620:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
	*cp = (uint16_t) 0xA55A;
  103624:	8b 45 f8             	mov    -0x8(%ebp),%eax
  103627:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
  10362c:	8b 45 f8             	mov    -0x8(%ebp),%eax
  10362f:	0f b7 00             	movzwl (%eax),%eax
  103632:	66 3d 5a a5          	cmp    $0xa55a,%ax
  103636:	74 13                	je     10364b <video_init+0x3f>
		cp = (uint16_t*) mem_ptr(MONO_BUF);
  103638:	c7 45 f8 00 00 0b 00 	movl   $0xb0000,-0x8(%ebp)
		addr_6845 = MONO_BASE;
  10363f:	c7 05 78 02 11 00 b4 	movl   $0x3b4,0x110278
  103646:	03 00 00 
  103649:	eb 14                	jmp    10365f <video_init+0x53>
	} else {
		*cp = was;
  10364b:	8b 45 f8             	mov    -0x8(%ebp),%eax
  10364e:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
  103652:	66 89 10             	mov    %dx,(%eax)
		addr_6845 = CGA_BASE;
  103655:	c7 05 78 02 11 00 d4 	movl   $0x3d4,0x110278
  10365c:	03 00 00 
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
  10365f:	a1 78 02 11 00       	mov    0x110278,%eax
  103664:	89 45 ec             	mov    %eax,-0x14(%ebp)
  103667:	c6 45 eb 0e          	movb   $0xe,-0x15(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10366b:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  10366f:	8b 55 ec             	mov    -0x14(%ebp),%edx
  103672:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
  103673:	a1 78 02 11 00       	mov    0x110278,%eax
  103678:	83 c0 01             	add    $0x1,%eax
  10367b:	89 45 e4             	mov    %eax,-0x1c(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10367e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  103681:	89 55 c8             	mov    %edx,-0x38(%ebp)
  103684:	8b 55 c8             	mov    -0x38(%ebp),%edx
  103687:	ec                   	in     (%dx),%al
  103688:	89 c3                	mov    %eax,%ebx
  10368a:	88 5d e3             	mov    %bl,-0x1d(%ebp)
	return data;
  10368d:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  103691:	0f b6 c0             	movzbl %al,%eax
  103694:	c1 e0 08             	shl    $0x8,%eax
  103697:	89 45 f0             	mov    %eax,-0x10(%ebp)
	outb(addr_6845, 15);
  10369a:	a1 78 02 11 00       	mov    0x110278,%eax
  10369f:	89 45 dc             	mov    %eax,-0x24(%ebp)
  1036a2:	c6 45 db 0f          	movb   $0xf,-0x25(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1036a6:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  1036aa:	8b 55 dc             	mov    -0x24(%ebp),%edx
  1036ad:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
  1036ae:	a1 78 02 11 00       	mov    0x110278,%eax
  1036b3:	83 c0 01             	add    $0x1,%eax
  1036b6:	89 45 d4             	mov    %eax,-0x2c(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1036b9:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  1036bc:	89 55 c8             	mov    %edx,-0x38(%ebp)
  1036bf:	8b 55 c8             	mov    -0x38(%ebp),%edx
  1036c2:	ec                   	in     (%dx),%al
  1036c3:	89 c3                	mov    %eax,%ebx
  1036c5:	88 5d d3             	mov    %bl,-0x2d(%ebp)
	return data;
  1036c8:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
  1036cc:	0f b6 c0             	movzbl %al,%eax
  1036cf:	09 45 f0             	or     %eax,-0x10(%ebp)

	crt_buf = (uint16_t*) cp;
  1036d2:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1036d5:	a3 7c 02 11 00       	mov    %eax,0x11027c
	crt_pos = pos;
  1036da:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1036dd:	66 a3 80 02 11 00    	mov    %ax,0x110280
}
  1036e3:	83 c4 34             	add    $0x34,%esp
  1036e6:	5b                   	pop    %ebx
  1036e7:	5d                   	pop    %ebp
  1036e8:	c3                   	ret    

001036e9 <video_putc>:



void
video_putc(int c)
{
  1036e9:	55                   	push   %ebp
  1036ea:	89 e5                	mov    %esp,%ebp
  1036ec:	53                   	push   %ebx
  1036ed:	83 ec 44             	sub    $0x44,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
  1036f0:	8b 45 08             	mov    0x8(%ebp),%eax
  1036f3:	b0 00                	mov    $0x0,%al
  1036f5:	85 c0                	test   %eax,%eax
  1036f7:	75 07                	jne    103700 <video_putc+0x17>
		c |= 0x0700;
  1036f9:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)

	switch (c & 0xff) {
  103700:	8b 45 08             	mov    0x8(%ebp),%eax
  103703:	25 ff 00 00 00       	and    $0xff,%eax
  103708:	83 f8 09             	cmp    $0x9,%eax
  10370b:	0f 84 ab 00 00 00    	je     1037bc <video_putc+0xd3>
  103711:	83 f8 09             	cmp    $0x9,%eax
  103714:	7f 0a                	jg     103720 <video_putc+0x37>
  103716:	83 f8 08             	cmp    $0x8,%eax
  103719:	74 14                	je     10372f <video_putc+0x46>
  10371b:	e9 da 00 00 00       	jmp    1037fa <video_putc+0x111>
  103720:	83 f8 0a             	cmp    $0xa,%eax
  103723:	74 4d                	je     103772 <video_putc+0x89>
  103725:	83 f8 0d             	cmp    $0xd,%eax
  103728:	74 58                	je     103782 <video_putc+0x99>
  10372a:	e9 cb 00 00 00       	jmp    1037fa <video_putc+0x111>
	case '\b':
		if (crt_pos > 0) {
  10372f:	0f b7 05 80 02 11 00 	movzwl 0x110280,%eax
  103736:	66 85 c0             	test   %ax,%ax
  103739:	0f 84 e0 00 00 00    	je     10381f <video_putc+0x136>
			crt_pos--;
  10373f:	0f b7 05 80 02 11 00 	movzwl 0x110280,%eax
  103746:	83 e8 01             	sub    $0x1,%eax
  103749:	66 a3 80 02 11 00    	mov    %ax,0x110280
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
  10374f:	a1 7c 02 11 00       	mov    0x11027c,%eax
  103754:	0f b7 15 80 02 11 00 	movzwl 0x110280,%edx
  10375b:	0f b7 d2             	movzwl %dx,%edx
  10375e:	01 d2                	add    %edx,%edx
  103760:	01 c2                	add    %eax,%edx
  103762:	8b 45 08             	mov    0x8(%ebp),%eax
  103765:	b0 00                	mov    $0x0,%al
  103767:	83 c8 20             	or     $0x20,%eax
  10376a:	66 89 02             	mov    %ax,(%edx)
		}
		break;
  10376d:	e9 ad 00 00 00       	jmp    10381f <video_putc+0x136>
	case '\n':
		crt_pos += CRT_COLS;
  103772:	0f b7 05 80 02 11 00 	movzwl 0x110280,%eax
  103779:	83 c0 50             	add    $0x50,%eax
  10377c:	66 a3 80 02 11 00    	mov    %ax,0x110280
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
  103782:	0f b7 1d 80 02 11 00 	movzwl 0x110280,%ebx
  103789:	0f b7 0d 80 02 11 00 	movzwl 0x110280,%ecx
  103790:	0f b7 c1             	movzwl %cx,%eax
  103793:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
  103799:	c1 e8 10             	shr    $0x10,%eax
  10379c:	89 c2                	mov    %eax,%edx
  10379e:	66 c1 ea 06          	shr    $0x6,%dx
  1037a2:	89 d0                	mov    %edx,%eax
  1037a4:	c1 e0 02             	shl    $0x2,%eax
  1037a7:	01 d0                	add    %edx,%eax
  1037a9:	c1 e0 04             	shl    $0x4,%eax
  1037ac:	89 ca                	mov    %ecx,%edx
  1037ae:	29 c2                	sub    %eax,%edx
  1037b0:	89 d8                	mov    %ebx,%eax
  1037b2:	29 d0                	sub    %edx,%eax
  1037b4:	66 a3 80 02 11 00    	mov    %ax,0x110280
		break;
  1037ba:	eb 64                	jmp    103820 <video_putc+0x137>
	case '\t':
		video_putc(' ');
  1037bc:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1037c3:	e8 21 ff ff ff       	call   1036e9 <video_putc>
		video_putc(' ');
  1037c8:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1037cf:	e8 15 ff ff ff       	call   1036e9 <video_putc>
		video_putc(' ');
  1037d4:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1037db:	e8 09 ff ff ff       	call   1036e9 <video_putc>
		video_putc(' ');
  1037e0:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1037e7:	e8 fd fe ff ff       	call   1036e9 <video_putc>
		video_putc(' ');
  1037ec:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1037f3:	e8 f1 fe ff ff       	call   1036e9 <video_putc>
		break;
  1037f8:	eb 26                	jmp    103820 <video_putc+0x137>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
  1037fa:	8b 15 7c 02 11 00    	mov    0x11027c,%edx
  103800:	0f b7 05 80 02 11 00 	movzwl 0x110280,%eax
  103807:	0f b7 c8             	movzwl %ax,%ecx
  10380a:	01 c9                	add    %ecx,%ecx
  10380c:	01 d1                	add    %edx,%ecx
  10380e:	8b 55 08             	mov    0x8(%ebp),%edx
  103811:	66 89 11             	mov    %dx,(%ecx)
  103814:	83 c0 01             	add    $0x1,%eax
  103817:	66 a3 80 02 11 00    	mov    %ax,0x110280
		break;
  10381d:	eb 01                	jmp    103820 <video_putc+0x137>
	case '\b':
		if (crt_pos > 0) {
			crt_pos--;
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
		}
		break;
  10381f:	90                   	nop
		crt_buf[crt_pos++] = c;		/* write the character */
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
  103820:	0f b7 05 80 02 11 00 	movzwl 0x110280,%eax
  103827:	66 3d cf 07          	cmp    $0x7cf,%ax
  10382b:	76 5b                	jbe    103888 <video_putc+0x19f>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
  10382d:	a1 7c 02 11 00       	mov    0x11027c,%eax
  103832:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
  103838:	a1 7c 02 11 00       	mov    0x11027c,%eax
  10383d:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
  103844:	00 
  103845:	89 54 24 04          	mov    %edx,0x4(%esp)
  103849:	89 04 24             	mov    %eax,(%esp)
  10384c:	e8 06 16 00 00       	call   104e57 <memmove>
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  103851:	c7 45 f4 80 07 00 00 	movl   $0x780,-0xc(%ebp)
  103858:	eb 15                	jmp    10386f <video_putc+0x186>
			crt_buf[i] = 0x0700 | ' ';
  10385a:	a1 7c 02 11 00       	mov    0x11027c,%eax
  10385f:	8b 55 f4             	mov    -0xc(%ebp),%edx
  103862:	01 d2                	add    %edx,%edx
  103864:	01 d0                	add    %edx,%eax
  103866:	66 c7 00 20 07       	movw   $0x720,(%eax)
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  10386b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  10386f:	81 7d f4 cf 07 00 00 	cmpl   $0x7cf,-0xc(%ebp)
  103876:	7e e2                	jle    10385a <video_putc+0x171>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
  103878:	0f b7 05 80 02 11 00 	movzwl 0x110280,%eax
  10387f:	83 e8 50             	sub    $0x50,%eax
  103882:	66 a3 80 02 11 00    	mov    %ax,0x110280
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
  103888:	a1 78 02 11 00       	mov    0x110278,%eax
  10388d:	89 45 f0             	mov    %eax,-0x10(%ebp)
  103890:	c6 45 ef 0e          	movb   $0xe,-0x11(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  103894:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
  103898:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10389b:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
  10389c:	0f b7 05 80 02 11 00 	movzwl 0x110280,%eax
  1038a3:	66 c1 e8 08          	shr    $0x8,%ax
  1038a7:	0f b6 c0             	movzbl %al,%eax
  1038aa:	8b 15 78 02 11 00    	mov    0x110278,%edx
  1038b0:	83 c2 01             	add    $0x1,%edx
  1038b3:	89 55 e8             	mov    %edx,-0x18(%ebp)
  1038b6:	88 45 e7             	mov    %al,-0x19(%ebp)
  1038b9:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  1038bd:	8b 55 e8             	mov    -0x18(%ebp),%edx
  1038c0:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
  1038c1:	a1 78 02 11 00       	mov    0x110278,%eax
  1038c6:	89 45 e0             	mov    %eax,-0x20(%ebp)
  1038c9:	c6 45 df 0f          	movb   $0xf,-0x21(%ebp)
  1038cd:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
  1038d1:	8b 55 e0             	mov    -0x20(%ebp),%edx
  1038d4:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
  1038d5:	0f b7 05 80 02 11 00 	movzwl 0x110280,%eax
  1038dc:	0f b6 c0             	movzbl %al,%eax
  1038df:	8b 15 78 02 11 00    	mov    0x110278,%edx
  1038e5:	83 c2 01             	add    $0x1,%edx
  1038e8:	89 55 d8             	mov    %edx,-0x28(%ebp)
  1038eb:	88 45 d7             	mov    %al,-0x29(%ebp)
  1038ee:	0f b6 45 d7          	movzbl -0x29(%ebp),%eax
  1038f2:	8b 55 d8             	mov    -0x28(%ebp),%edx
  1038f5:	ee                   	out    %al,(%dx)
}
  1038f6:	83 c4 44             	add    $0x44,%esp
  1038f9:	5b                   	pop    %ebx
  1038fa:	5d                   	pop    %ebp
  1038fb:	c3                   	ret    

001038fc <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
  1038fc:	55                   	push   %ebp
  1038fd:	89 e5                	mov    %esp,%ebp
  1038ff:	53                   	push   %ebx
  103900:	83 ec 44             	sub    $0x44,%esp
  103903:	c7 45 ec 64 00 00 00 	movl   $0x64,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10390a:	8b 55 ec             	mov    -0x14(%ebp),%edx
  10390d:	89 55 d4             	mov    %edx,-0x2c(%ebp)
  103910:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  103913:	ec                   	in     (%dx),%al
  103914:	89 c3                	mov    %eax,%ebx
  103916:	88 5d eb             	mov    %bl,-0x15(%ebp)
	return data;
  103919:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
  10391d:	0f b6 c0             	movzbl %al,%eax
  103920:	83 e0 01             	and    $0x1,%eax
  103923:	85 c0                	test   %eax,%eax
  103925:	75 0a                	jne    103931 <kbd_proc_data+0x35>
		return -1;
  103927:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  10392c:	e9 5f 01 00 00       	jmp    103a90 <kbd_proc_data+0x194>
  103931:	c7 45 e4 60 00 00 00 	movl   $0x60,-0x1c(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103938:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  10393b:	89 55 d4             	mov    %edx,-0x2c(%ebp)
  10393e:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  103941:	ec                   	in     (%dx),%al
  103942:	89 c3                	mov    %eax,%ebx
  103944:	88 5d e3             	mov    %bl,-0x1d(%ebp)
	return data;
  103947:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax

	data = inb(KBDATAP);
  10394b:	88 45 f3             	mov    %al,-0xd(%ebp)

	if (data == 0xE0) {
  10394e:	80 7d f3 e0          	cmpb   $0xe0,-0xd(%ebp)
  103952:	75 17                	jne    10396b <kbd_proc_data+0x6f>
		// E0 escape character
		shift |= E0ESC;
  103954:	a1 84 02 11 00       	mov    0x110284,%eax
  103959:	83 c8 40             	or     $0x40,%eax
  10395c:	a3 84 02 11 00       	mov    %eax,0x110284
		return 0;
  103961:	b8 00 00 00 00       	mov    $0x0,%eax
  103966:	e9 25 01 00 00       	jmp    103a90 <kbd_proc_data+0x194>
	} else if (data & 0x80) {
  10396b:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  10396f:	84 c0                	test   %al,%al
  103971:	79 47                	jns    1039ba <kbd_proc_data+0xbe>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
  103973:	a1 84 02 11 00       	mov    0x110284,%eax
  103978:	83 e0 40             	and    $0x40,%eax
  10397b:	85 c0                	test   %eax,%eax
  10397d:	75 09                	jne    103988 <kbd_proc_data+0x8c>
  10397f:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  103983:	83 e0 7f             	and    $0x7f,%eax
  103986:	eb 04                	jmp    10398c <kbd_proc_data+0x90>
  103988:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  10398c:	88 45 f3             	mov    %al,-0xd(%ebp)
		shift &= ~(shiftcode[data] | E0ESC);
  10398f:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  103993:	0f b6 80 80 a0 10 00 	movzbl 0x10a080(%eax),%eax
  10399a:	83 c8 40             	or     $0x40,%eax
  10399d:	0f b6 c0             	movzbl %al,%eax
  1039a0:	f7 d0                	not    %eax
  1039a2:	89 c2                	mov    %eax,%edx
  1039a4:	a1 84 02 11 00       	mov    0x110284,%eax
  1039a9:	21 d0                	and    %edx,%eax
  1039ab:	a3 84 02 11 00       	mov    %eax,0x110284
		return 0;
  1039b0:	b8 00 00 00 00       	mov    $0x0,%eax
  1039b5:	e9 d6 00 00 00       	jmp    103a90 <kbd_proc_data+0x194>
	} else if (shift & E0ESC) {
  1039ba:	a1 84 02 11 00       	mov    0x110284,%eax
  1039bf:	83 e0 40             	and    $0x40,%eax
  1039c2:	85 c0                	test   %eax,%eax
  1039c4:	74 11                	je     1039d7 <kbd_proc_data+0xdb>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
  1039c6:	80 4d f3 80          	orb    $0x80,-0xd(%ebp)
		shift &= ~E0ESC;
  1039ca:	a1 84 02 11 00       	mov    0x110284,%eax
  1039cf:	83 e0 bf             	and    $0xffffffbf,%eax
  1039d2:	a3 84 02 11 00       	mov    %eax,0x110284
	}

	shift |= shiftcode[data];
  1039d7:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1039db:	0f b6 80 80 a0 10 00 	movzbl 0x10a080(%eax),%eax
  1039e2:	0f b6 d0             	movzbl %al,%edx
  1039e5:	a1 84 02 11 00       	mov    0x110284,%eax
  1039ea:	09 d0                	or     %edx,%eax
  1039ec:	a3 84 02 11 00       	mov    %eax,0x110284
	shift ^= togglecode[data];
  1039f1:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1039f5:	0f b6 80 80 a1 10 00 	movzbl 0x10a180(%eax),%eax
  1039fc:	0f b6 d0             	movzbl %al,%edx
  1039ff:	a1 84 02 11 00       	mov    0x110284,%eax
  103a04:	31 d0                	xor    %edx,%eax
  103a06:	a3 84 02 11 00       	mov    %eax,0x110284

	c = charcode[shift & (CTL | SHIFT)][data];
  103a0b:	a1 84 02 11 00       	mov    0x110284,%eax
  103a10:	83 e0 03             	and    $0x3,%eax
  103a13:	8b 14 85 80 a5 10 00 	mov    0x10a580(,%eax,4),%edx
  103a1a:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  103a1e:	01 d0                	add    %edx,%eax
  103a20:	0f b6 00             	movzbl (%eax),%eax
  103a23:	0f b6 c0             	movzbl %al,%eax
  103a26:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (shift & CAPSLOCK) {
  103a29:	a1 84 02 11 00       	mov    0x110284,%eax
  103a2e:	83 e0 08             	and    $0x8,%eax
  103a31:	85 c0                	test   %eax,%eax
  103a33:	74 22                	je     103a57 <kbd_proc_data+0x15b>
		if ('a' <= c && c <= 'z')
  103a35:	83 7d f4 60          	cmpl   $0x60,-0xc(%ebp)
  103a39:	7e 0c                	jle    103a47 <kbd_proc_data+0x14b>
  103a3b:	83 7d f4 7a          	cmpl   $0x7a,-0xc(%ebp)
  103a3f:	7f 06                	jg     103a47 <kbd_proc_data+0x14b>
			c += 'A' - 'a';
  103a41:	83 6d f4 20          	subl   $0x20,-0xc(%ebp)
  103a45:	eb 10                	jmp    103a57 <kbd_proc_data+0x15b>
		else if ('A' <= c && c <= 'Z')
  103a47:	83 7d f4 40          	cmpl   $0x40,-0xc(%ebp)
  103a4b:	7e 0a                	jle    103a57 <kbd_proc_data+0x15b>
  103a4d:	83 7d f4 5a          	cmpl   $0x5a,-0xc(%ebp)
  103a51:	7f 04                	jg     103a57 <kbd_proc_data+0x15b>
			c += 'a' - 'A';
  103a53:	83 45 f4 20          	addl   $0x20,-0xc(%ebp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
  103a57:	a1 84 02 11 00       	mov    0x110284,%eax
  103a5c:	f7 d0                	not    %eax
  103a5e:	83 e0 06             	and    $0x6,%eax
  103a61:	85 c0                	test   %eax,%eax
  103a63:	75 28                	jne    103a8d <kbd_proc_data+0x191>
  103a65:	81 7d f4 e9 00 00 00 	cmpl   $0xe9,-0xc(%ebp)
  103a6c:	75 1f                	jne    103a8d <kbd_proc_data+0x191>
		cprintf("Rebooting!\n");
  103a6e:	c7 04 24 7f 62 10 00 	movl   $0x10627f,(%esp)
  103a75:	e8 8a 11 00 00       	call   104c04 <cprintf>
  103a7a:	c7 45 dc 92 00 00 00 	movl   $0x92,-0x24(%ebp)
  103a81:	c6 45 db 03          	movb   $0x3,-0x25(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  103a85:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  103a89:	8b 55 dc             	mov    -0x24(%ebp),%edx
  103a8c:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
  103a8d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  103a90:	83 c4 44             	add    $0x44,%esp
  103a93:	5b                   	pop    %ebx
  103a94:	5d                   	pop    %ebp
  103a95:	c3                   	ret    

00103a96 <kbd_intr>:

void
kbd_intr(void)
{
  103a96:	55                   	push   %ebp
  103a97:	89 e5                	mov    %esp,%ebp
  103a99:	83 ec 18             	sub    $0x18,%esp
	cons_intr(kbd_proc_data);
  103a9c:	c7 04 24 fc 38 10 00 	movl   $0x1038fc,(%esp)
  103aa3:	e8 4a c8 ff ff       	call   1002f2 <cons_intr>
}
  103aa8:	c9                   	leave  
  103aa9:	c3                   	ret    

00103aaa <kbd_init>:

void
kbd_init(void)
{
  103aaa:	55                   	push   %ebp
  103aab:	89 e5                	mov    %esp,%ebp
}
  103aad:	5d                   	pop    %ebp
  103aae:	c3                   	ret    
  103aaf:	90                   	nop

00103ab0 <delay>:


// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
  103ab0:	55                   	push   %ebp
  103ab1:	89 e5                	mov    %esp,%ebp
  103ab3:	53                   	push   %ebx
  103ab4:	83 ec 24             	sub    $0x24,%esp
  103ab7:	c7 45 f8 84 00 00 00 	movl   $0x84,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103abe:	8b 55 f8             	mov    -0x8(%ebp),%edx
  103ac1:	89 55 d8             	mov    %edx,-0x28(%ebp)
  103ac4:	8b 55 d8             	mov    -0x28(%ebp),%edx
  103ac7:	ec                   	in     (%dx),%al
  103ac8:	89 c3                	mov    %eax,%ebx
  103aca:	88 5d f7             	mov    %bl,-0x9(%ebp)
  103acd:	c7 45 f0 84 00 00 00 	movl   $0x84,-0x10(%ebp)
  103ad4:	8b 55 f0             	mov    -0x10(%ebp),%edx
  103ad7:	89 55 d8             	mov    %edx,-0x28(%ebp)
  103ada:	8b 55 d8             	mov    -0x28(%ebp),%edx
  103add:	ec                   	in     (%dx),%al
  103ade:	89 c3                	mov    %eax,%ebx
  103ae0:	88 5d ef             	mov    %bl,-0x11(%ebp)
  103ae3:	c7 45 e8 84 00 00 00 	movl   $0x84,-0x18(%ebp)
  103aea:	8b 55 e8             	mov    -0x18(%ebp),%edx
  103aed:	89 55 d8             	mov    %edx,-0x28(%ebp)
  103af0:	8b 55 d8             	mov    -0x28(%ebp),%edx
  103af3:	ec                   	in     (%dx),%al
  103af4:	89 c3                	mov    %eax,%ebx
  103af6:	88 5d e7             	mov    %bl,-0x19(%ebp)
  103af9:	c7 45 e0 84 00 00 00 	movl   $0x84,-0x20(%ebp)
  103b00:	8b 55 e0             	mov    -0x20(%ebp),%edx
  103b03:	89 55 d8             	mov    %edx,-0x28(%ebp)
  103b06:	8b 55 d8             	mov    -0x28(%ebp),%edx
  103b09:	ec                   	in     (%dx),%al
  103b0a:	89 c3                	mov    %eax,%ebx
  103b0c:	88 5d df             	mov    %bl,-0x21(%ebp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
  103b0f:	83 c4 24             	add    $0x24,%esp
  103b12:	5b                   	pop    %ebx
  103b13:	5d                   	pop    %ebp
  103b14:	c3                   	ret    

00103b15 <serial_proc_data>:

static int
serial_proc_data(void)
{
  103b15:	55                   	push   %ebp
  103b16:	89 e5                	mov    %esp,%ebp
  103b18:	53                   	push   %ebx
  103b19:	83 ec 14             	sub    $0x14,%esp
  103b1c:	c7 45 f8 fd 03 00 00 	movl   $0x3fd,-0x8(%ebp)
  103b23:	8b 55 f8             	mov    -0x8(%ebp),%edx
  103b26:	89 55 e8             	mov    %edx,-0x18(%ebp)
  103b29:	8b 55 e8             	mov    -0x18(%ebp),%edx
  103b2c:	ec                   	in     (%dx),%al
  103b2d:	89 c3                	mov    %eax,%ebx
  103b2f:	88 5d f7             	mov    %bl,-0x9(%ebp)
	return data;
  103b32:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
  103b36:	0f b6 c0             	movzbl %al,%eax
  103b39:	83 e0 01             	and    $0x1,%eax
  103b3c:	85 c0                	test   %eax,%eax
  103b3e:	75 07                	jne    103b47 <serial_proc_data+0x32>
		return -1;
  103b40:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  103b45:	eb 1d                	jmp    103b64 <serial_proc_data+0x4f>
  103b47:	c7 45 f0 f8 03 00 00 	movl   $0x3f8,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103b4e:	8b 55 f0             	mov    -0x10(%ebp),%edx
  103b51:	89 55 e8             	mov    %edx,-0x18(%ebp)
  103b54:	8b 55 e8             	mov    -0x18(%ebp),%edx
  103b57:	ec                   	in     (%dx),%al
  103b58:	89 c3                	mov    %eax,%ebx
  103b5a:	88 5d ef             	mov    %bl,-0x11(%ebp)
	return data;
  103b5d:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
	return inb(COM1+COM_RX);
  103b61:	0f b6 c0             	movzbl %al,%eax
}
  103b64:	83 c4 14             	add    $0x14,%esp
  103b67:	5b                   	pop    %ebx
  103b68:	5d                   	pop    %ebp
  103b69:	c3                   	ret    

00103b6a <serial_intr>:

void
serial_intr(void)
{
  103b6a:	55                   	push   %ebp
  103b6b:	89 e5                	mov    %esp,%ebp
  103b6d:	83 ec 18             	sub    $0x18,%esp
	if (serial_exists)
  103b70:	a1 88 0a 31 00       	mov    0x310a88,%eax
  103b75:	85 c0                	test   %eax,%eax
  103b77:	74 0c                	je     103b85 <serial_intr+0x1b>
		cons_intr(serial_proc_data);
  103b79:	c7 04 24 15 3b 10 00 	movl   $0x103b15,(%esp)
  103b80:	e8 6d c7 ff ff       	call   1002f2 <cons_intr>
}
  103b85:	c9                   	leave  
  103b86:	c3                   	ret    

00103b87 <serial_putc>:

void
serial_putc(int c)
{
  103b87:	55                   	push   %ebp
  103b88:	89 e5                	mov    %esp,%ebp
  103b8a:	53                   	push   %ebx
  103b8b:	83 ec 24             	sub    $0x24,%esp
	if (!serial_exists)
  103b8e:	a1 88 0a 31 00       	mov    0x310a88,%eax
  103b93:	85 c0                	test   %eax,%eax
  103b95:	74 59                	je     103bf0 <serial_putc+0x69>
		return;

	int i;
	for (i = 0;
  103b97:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  103b9e:	eb 09                	jmp    103ba9 <serial_putc+0x22>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
  103ba0:	e8 0b ff ff ff       	call   103ab0 <delay>
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
  103ba5:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  103ba9:	c7 45 f4 fd 03 00 00 	movl   $0x3fd,-0xc(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103bb0:	8b 55 f4             	mov    -0xc(%ebp),%edx
  103bb3:	89 55 d8             	mov    %edx,-0x28(%ebp)
  103bb6:	8b 55 d8             	mov    -0x28(%ebp),%edx
  103bb9:	ec                   	in     (%dx),%al
  103bba:	89 c3                	mov    %eax,%ebx
  103bbc:	88 5d f3             	mov    %bl,-0xd(%ebp)
	return data;
  103bbf:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  103bc3:	0f b6 c0             	movzbl %al,%eax
  103bc6:	83 e0 20             	and    $0x20,%eax
{
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
  103bc9:	85 c0                	test   %eax,%eax
  103bcb:	75 09                	jne    103bd6 <serial_putc+0x4f>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  103bcd:	81 7d f8 ff 31 00 00 	cmpl   $0x31ff,-0x8(%ebp)
  103bd4:	7e ca                	jle    103ba0 <serial_putc+0x19>
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
  103bd6:	8b 45 08             	mov    0x8(%ebp),%eax
  103bd9:	0f b6 c0             	movzbl %al,%eax
  103bdc:	c7 45 ec f8 03 00 00 	movl   $0x3f8,-0x14(%ebp)
  103be3:	88 45 eb             	mov    %al,-0x15(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  103be6:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  103bea:	8b 55 ec             	mov    -0x14(%ebp),%edx
  103bed:	ee                   	out    %al,(%dx)
  103bee:	eb 01                	jmp    103bf1 <serial_putc+0x6a>

void
serial_putc(int c)
{
	if (!serial_exists)
		return;
  103bf0:	90                   	nop
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
}
  103bf1:	83 c4 24             	add    $0x24,%esp
  103bf4:	5b                   	pop    %ebx
  103bf5:	5d                   	pop    %ebp
  103bf6:	c3                   	ret    

00103bf7 <serial_init>:

void
serial_init(void)
{
  103bf7:	55                   	push   %ebp
  103bf8:	89 e5                	mov    %esp,%ebp
  103bfa:	53                   	push   %ebx
  103bfb:	83 ec 54             	sub    $0x54,%esp
  103bfe:	c7 45 f8 fa 03 00 00 	movl   $0x3fa,-0x8(%ebp)
  103c05:	c6 45 f7 00          	movb   $0x0,-0x9(%ebp)
  103c09:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
  103c0d:	8b 55 f8             	mov    -0x8(%ebp),%edx
  103c10:	ee                   	out    %al,(%dx)
  103c11:	c7 45 f0 fb 03 00 00 	movl   $0x3fb,-0x10(%ebp)
  103c18:	c6 45 ef 80          	movb   $0x80,-0x11(%ebp)
  103c1c:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
  103c20:	8b 55 f0             	mov    -0x10(%ebp),%edx
  103c23:	ee                   	out    %al,(%dx)
  103c24:	c7 45 e8 f8 03 00 00 	movl   $0x3f8,-0x18(%ebp)
  103c2b:	c6 45 e7 0c          	movb   $0xc,-0x19(%ebp)
  103c2f:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  103c33:	8b 55 e8             	mov    -0x18(%ebp),%edx
  103c36:	ee                   	out    %al,(%dx)
  103c37:	c7 45 e0 f9 03 00 00 	movl   $0x3f9,-0x20(%ebp)
  103c3e:	c6 45 df 00          	movb   $0x0,-0x21(%ebp)
  103c42:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
  103c46:	8b 55 e0             	mov    -0x20(%ebp),%edx
  103c49:	ee                   	out    %al,(%dx)
  103c4a:	c7 45 d8 fb 03 00 00 	movl   $0x3fb,-0x28(%ebp)
  103c51:	c6 45 d7 03          	movb   $0x3,-0x29(%ebp)
  103c55:	0f b6 45 d7          	movzbl -0x29(%ebp),%eax
  103c59:	8b 55 d8             	mov    -0x28(%ebp),%edx
  103c5c:	ee                   	out    %al,(%dx)
  103c5d:	c7 45 d0 fc 03 00 00 	movl   $0x3fc,-0x30(%ebp)
  103c64:	c6 45 cf 00          	movb   $0x0,-0x31(%ebp)
  103c68:	0f b6 45 cf          	movzbl -0x31(%ebp),%eax
  103c6c:	8b 55 d0             	mov    -0x30(%ebp),%edx
  103c6f:	ee                   	out    %al,(%dx)
  103c70:	c7 45 c8 f9 03 00 00 	movl   $0x3f9,-0x38(%ebp)
  103c77:	c6 45 c7 01          	movb   $0x1,-0x39(%ebp)
  103c7b:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
  103c7f:	8b 55 c8             	mov    -0x38(%ebp),%edx
  103c82:	ee                   	out    %al,(%dx)
  103c83:	c7 45 c0 fd 03 00 00 	movl   $0x3fd,-0x40(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103c8a:	8b 55 c0             	mov    -0x40(%ebp),%edx
  103c8d:	89 55 a8             	mov    %edx,-0x58(%ebp)
  103c90:	8b 55 a8             	mov    -0x58(%ebp),%edx
  103c93:	ec                   	in     (%dx),%al
  103c94:	89 c3                	mov    %eax,%ebx
  103c96:	88 5d bf             	mov    %bl,-0x41(%ebp)
	return data;
  103c99:	0f b6 45 bf          	movzbl -0x41(%ebp),%eax
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
  103c9d:	3c ff                	cmp    $0xff,%al
  103c9f:	0f 95 c0             	setne  %al
  103ca2:	0f b6 c0             	movzbl %al,%eax
  103ca5:	a3 88 0a 31 00       	mov    %eax,0x310a88
  103caa:	c7 45 b8 fa 03 00 00 	movl   $0x3fa,-0x48(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103cb1:	8b 55 b8             	mov    -0x48(%ebp),%edx
  103cb4:	89 55 a8             	mov    %edx,-0x58(%ebp)
  103cb7:	8b 55 a8             	mov    -0x58(%ebp),%edx
  103cba:	ec                   	in     (%dx),%al
  103cbb:	89 c3                	mov    %eax,%ebx
  103cbd:	88 5d b7             	mov    %bl,-0x49(%ebp)
  103cc0:	c7 45 b0 f8 03 00 00 	movl   $0x3f8,-0x50(%ebp)
  103cc7:	8b 55 b0             	mov    -0x50(%ebp),%edx
  103cca:	89 55 a8             	mov    %edx,-0x58(%ebp)
  103ccd:	8b 55 a8             	mov    -0x58(%ebp),%edx
  103cd0:	ec                   	in     (%dx),%al
  103cd1:	89 c3                	mov    %eax,%ebx
  103cd3:	88 5d af             	mov    %bl,-0x51(%ebp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);
}
  103cd6:	83 c4 54             	add    $0x54,%esp
  103cd9:	5b                   	pop    %ebx
  103cda:	5d                   	pop    %ebp
  103cdb:	c3                   	ret    

00103cdc <pic_init>:
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
  103cdc:	55                   	push   %ebp
  103cdd:	89 e5                	mov    %esp,%ebp
  103cdf:	81 ec 88 00 00 00    	sub    $0x88,%esp
	if (didinit)		// only do once on bootstrap CPU
  103ce5:	a1 88 02 11 00       	mov    0x110288,%eax
  103cea:	85 c0                	test   %eax,%eax
  103cec:	0f 85 35 01 00 00    	jne    103e27 <pic_init+0x14b>
		return;
	didinit = 1;
  103cf2:	c7 05 88 02 11 00 01 	movl   $0x1,0x110288
  103cf9:	00 00 00 
  103cfc:	c7 45 f4 21 00 00 00 	movl   $0x21,-0xc(%ebp)
  103d03:	c6 45 f3 ff          	movb   $0xff,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  103d07:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  103d0b:	8b 55 f4             	mov    -0xc(%ebp),%edx
  103d0e:	ee                   	out    %al,(%dx)
  103d0f:	c7 45 ec a1 00 00 00 	movl   $0xa1,-0x14(%ebp)
  103d16:	c6 45 eb ff          	movb   $0xff,-0x15(%ebp)
  103d1a:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  103d1e:	8b 55 ec             	mov    -0x14(%ebp),%edx
  103d21:	ee                   	out    %al,(%dx)
  103d22:	c7 45 e4 20 00 00 00 	movl   $0x20,-0x1c(%ebp)
  103d29:	c6 45 e3 11          	movb   $0x11,-0x1d(%ebp)
  103d2d:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  103d31:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  103d34:	ee                   	out    %al,(%dx)
  103d35:	c7 45 dc 21 00 00 00 	movl   $0x21,-0x24(%ebp)
  103d3c:	c6 45 db 20          	movb   $0x20,-0x25(%ebp)
  103d40:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  103d44:	8b 55 dc             	mov    -0x24(%ebp),%edx
  103d47:	ee                   	out    %al,(%dx)
  103d48:	c7 45 d4 21 00 00 00 	movl   $0x21,-0x2c(%ebp)
  103d4f:	c6 45 d3 04          	movb   $0x4,-0x2d(%ebp)
  103d53:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
  103d57:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  103d5a:	ee                   	out    %al,(%dx)
  103d5b:	c7 45 cc 21 00 00 00 	movl   $0x21,-0x34(%ebp)
  103d62:	c6 45 cb 03          	movb   $0x3,-0x35(%ebp)
  103d66:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
  103d6a:	8b 55 cc             	mov    -0x34(%ebp),%edx
  103d6d:	ee                   	out    %al,(%dx)
  103d6e:	c7 45 c4 a0 00 00 00 	movl   $0xa0,-0x3c(%ebp)
  103d75:	c6 45 c3 11          	movb   $0x11,-0x3d(%ebp)
  103d79:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
  103d7d:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  103d80:	ee                   	out    %al,(%dx)
  103d81:	c7 45 bc a1 00 00 00 	movl   $0xa1,-0x44(%ebp)
  103d88:	c6 45 bb 28          	movb   $0x28,-0x45(%ebp)
  103d8c:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
  103d90:	8b 55 bc             	mov    -0x44(%ebp),%edx
  103d93:	ee                   	out    %al,(%dx)
  103d94:	c7 45 b4 a1 00 00 00 	movl   $0xa1,-0x4c(%ebp)
  103d9b:	c6 45 b3 02          	movb   $0x2,-0x4d(%ebp)
  103d9f:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
  103da3:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  103da6:	ee                   	out    %al,(%dx)
  103da7:	c7 45 ac a1 00 00 00 	movl   $0xa1,-0x54(%ebp)
  103dae:	c6 45 ab 01          	movb   $0x1,-0x55(%ebp)
  103db2:	0f b6 45 ab          	movzbl -0x55(%ebp),%eax
  103db6:	8b 55 ac             	mov    -0x54(%ebp),%edx
  103db9:	ee                   	out    %al,(%dx)
  103dba:	c7 45 a4 20 00 00 00 	movl   $0x20,-0x5c(%ebp)
  103dc1:	c6 45 a3 68          	movb   $0x68,-0x5d(%ebp)
  103dc5:	0f b6 45 a3          	movzbl -0x5d(%ebp),%eax
  103dc9:	8b 55 a4             	mov    -0x5c(%ebp),%edx
  103dcc:	ee                   	out    %al,(%dx)
  103dcd:	c7 45 9c 20 00 00 00 	movl   $0x20,-0x64(%ebp)
  103dd4:	c6 45 9b 0a          	movb   $0xa,-0x65(%ebp)
  103dd8:	0f b6 45 9b          	movzbl -0x65(%ebp),%eax
  103ddc:	8b 55 9c             	mov    -0x64(%ebp),%edx
  103ddf:	ee                   	out    %al,(%dx)
  103de0:	c7 45 94 a0 00 00 00 	movl   $0xa0,-0x6c(%ebp)
  103de7:	c6 45 93 68          	movb   $0x68,-0x6d(%ebp)
  103deb:	0f b6 45 93          	movzbl -0x6d(%ebp),%eax
  103def:	8b 55 94             	mov    -0x6c(%ebp),%edx
  103df2:	ee                   	out    %al,(%dx)
  103df3:	c7 45 8c a0 00 00 00 	movl   $0xa0,-0x74(%ebp)
  103dfa:	c6 45 8b 0a          	movb   $0xa,-0x75(%ebp)
  103dfe:	0f b6 45 8b          	movzbl -0x75(%ebp),%eax
  103e02:	8b 55 8c             	mov    -0x74(%ebp),%edx
  103e05:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irqmask != 0xFFFF)
  103e06:	0f b7 05 90 a5 10 00 	movzwl 0x10a590,%eax
  103e0d:	66 83 f8 ff          	cmp    $0xffff,%ax
  103e11:	74 15                	je     103e28 <pic_init+0x14c>
		pic_setmask(irqmask);
  103e13:	0f b7 05 90 a5 10 00 	movzwl 0x10a590,%eax
  103e1a:	0f b7 c0             	movzwl %ax,%eax
  103e1d:	89 04 24             	mov    %eax,(%esp)
  103e20:	e8 05 00 00 00       	call   103e2a <pic_setmask>
  103e25:	eb 01                	jmp    103e28 <pic_init+0x14c>
/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	if (didinit)		// only do once on bootstrap CPU
		return;
  103e27:	90                   	nop
	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irqmask != 0xFFFF)
		pic_setmask(irqmask);
}
  103e28:	c9                   	leave  
  103e29:	c3                   	ret    

00103e2a <pic_setmask>:

void
pic_setmask(uint16_t mask)
{
  103e2a:	55                   	push   %ebp
  103e2b:	89 e5                	mov    %esp,%ebp
  103e2d:	83 ec 14             	sub    $0x14,%esp
  103e30:	8b 45 08             	mov    0x8(%ebp),%eax
  103e33:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
	irqmask = mask;
  103e37:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  103e3b:	66 a3 90 a5 10 00    	mov    %ax,0x10a590
	outb(IO_PIC1+1, (char)mask);
  103e41:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  103e45:	0f b6 c0             	movzbl %al,%eax
  103e48:	c7 45 fc 21 00 00 00 	movl   $0x21,-0x4(%ebp)
  103e4f:	88 45 fb             	mov    %al,-0x5(%ebp)
  103e52:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  103e56:	8b 55 fc             	mov    -0x4(%ebp),%edx
  103e59:	ee                   	out    %al,(%dx)
	outb(IO_PIC2+1, (char)(mask >> 8));
  103e5a:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  103e5e:	66 c1 e8 08          	shr    $0x8,%ax
  103e62:	0f b6 c0             	movzbl %al,%eax
  103e65:	c7 45 f4 a1 00 00 00 	movl   $0xa1,-0xc(%ebp)
  103e6c:	88 45 f3             	mov    %al,-0xd(%ebp)
  103e6f:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  103e73:	8b 55 f4             	mov    -0xc(%ebp),%edx
  103e76:	ee                   	out    %al,(%dx)
}
  103e77:	c9                   	leave  
  103e78:	c3                   	ret    

00103e79 <pic_enable>:

void
pic_enable(int irq)
{
  103e79:	55                   	push   %ebp
  103e7a:	89 e5                	mov    %esp,%ebp
  103e7c:	53                   	push   %ebx
  103e7d:	83 ec 04             	sub    $0x4,%esp
	pic_setmask(irqmask & ~(1 << irq));
  103e80:	8b 45 08             	mov    0x8(%ebp),%eax
  103e83:	ba 01 00 00 00       	mov    $0x1,%edx
  103e88:	89 d3                	mov    %edx,%ebx
  103e8a:	89 c1                	mov    %eax,%ecx
  103e8c:	d3 e3                	shl    %cl,%ebx
  103e8e:	89 d8                	mov    %ebx,%eax
  103e90:	89 c2                	mov    %eax,%edx
  103e92:	f7 d2                	not    %edx
  103e94:	0f b7 05 90 a5 10 00 	movzwl 0x10a590,%eax
  103e9b:	21 d0                	and    %edx,%eax
  103e9d:	0f b7 c0             	movzwl %ax,%eax
  103ea0:	89 04 24             	mov    %eax,(%esp)
  103ea3:	e8 82 ff ff ff       	call   103e2a <pic_setmask>
}
  103ea8:	83 c4 04             	add    $0x4,%esp
  103eab:	5b                   	pop    %ebx
  103eac:	5d                   	pop    %ebp
  103ead:	c3                   	ret    
  103eae:	90                   	nop
  103eaf:	90                   	nop

00103eb0 <nvram_read>:
#include <dev/nvram.h>


unsigned
nvram_read(unsigned reg)
{
  103eb0:	55                   	push   %ebp
  103eb1:	89 e5                	mov    %esp,%ebp
  103eb3:	53                   	push   %ebx
  103eb4:	83 ec 14             	sub    $0x14,%esp
	outb(IO_RTC, reg);
  103eb7:	8b 45 08             	mov    0x8(%ebp),%eax
  103eba:	0f b6 c0             	movzbl %al,%eax
  103ebd:	c7 45 f8 70 00 00 00 	movl   $0x70,-0x8(%ebp)
  103ec4:	88 45 f7             	mov    %al,-0x9(%ebp)
  103ec7:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
  103ecb:	8b 55 f8             	mov    -0x8(%ebp),%edx
  103ece:	ee                   	out    %al,(%dx)
  103ecf:	c7 45 f0 71 00 00 00 	movl   $0x71,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103ed6:	8b 55 f0             	mov    -0x10(%ebp),%edx
  103ed9:	89 55 e8             	mov    %edx,-0x18(%ebp)
  103edc:	8b 55 e8             	mov    -0x18(%ebp),%edx
  103edf:	ec                   	in     (%dx),%al
  103ee0:	89 c3                	mov    %eax,%ebx
  103ee2:	88 5d ef             	mov    %bl,-0x11(%ebp)
	return data;
  103ee5:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
	return inb(IO_RTC+1);
  103ee9:	0f b6 c0             	movzbl %al,%eax
}
  103eec:	83 c4 14             	add    $0x14,%esp
  103eef:	5b                   	pop    %ebx
  103ef0:	5d                   	pop    %ebp
  103ef1:	c3                   	ret    

00103ef2 <nvram_read16>:

unsigned
nvram_read16(unsigned r)
{
  103ef2:	55                   	push   %ebp
  103ef3:	89 e5                	mov    %esp,%ebp
  103ef5:	53                   	push   %ebx
  103ef6:	83 ec 04             	sub    $0x4,%esp
	return nvram_read(r) | (nvram_read(r + 1) << 8);
  103ef9:	8b 45 08             	mov    0x8(%ebp),%eax
  103efc:	89 04 24             	mov    %eax,(%esp)
  103eff:	e8 ac ff ff ff       	call   103eb0 <nvram_read>
  103f04:	89 c3                	mov    %eax,%ebx
  103f06:	8b 45 08             	mov    0x8(%ebp),%eax
  103f09:	83 c0 01             	add    $0x1,%eax
  103f0c:	89 04 24             	mov    %eax,(%esp)
  103f0f:	e8 9c ff ff ff       	call   103eb0 <nvram_read>
  103f14:	c1 e0 08             	shl    $0x8,%eax
  103f17:	09 d8                	or     %ebx,%eax
}
  103f19:	83 c4 04             	add    $0x4,%esp
  103f1c:	5b                   	pop    %ebx
  103f1d:	5d                   	pop    %ebp
  103f1e:	c3                   	ret    

00103f1f <nvram_write>:

void
nvram_write(unsigned reg, unsigned datum)
{
  103f1f:	55                   	push   %ebp
  103f20:	89 e5                	mov    %esp,%ebp
  103f22:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  103f25:	8b 45 08             	mov    0x8(%ebp),%eax
  103f28:	0f b6 c0             	movzbl %al,%eax
  103f2b:	c7 45 fc 70 00 00 00 	movl   $0x70,-0x4(%ebp)
  103f32:	88 45 fb             	mov    %al,-0x5(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  103f35:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  103f39:	8b 55 fc             	mov    -0x4(%ebp),%edx
  103f3c:	ee                   	out    %al,(%dx)
	outb(IO_RTC+1, datum);
  103f3d:	8b 45 0c             	mov    0xc(%ebp),%eax
  103f40:	0f b6 c0             	movzbl %al,%eax
  103f43:	c7 45 f4 71 00 00 00 	movl   $0x71,-0xc(%ebp)
  103f4a:	88 45 f3             	mov    %al,-0xd(%ebp)
  103f4d:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  103f51:	8b 55 f4             	mov    -0xc(%ebp),%edx
  103f54:	ee                   	out    %al,(%dx)
}
  103f55:	c9                   	leave  
  103f56:	c3                   	ret    
  103f57:	90                   	nop

00103f58 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  103f58:	55                   	push   %ebp
  103f59:	89 e5                	mov    %esp,%ebp
  103f5b:	53                   	push   %ebx
  103f5c:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  103f5f:	89 e3                	mov    %esp,%ebx
  103f61:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  103f64:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  103f67:	89 45 f4             	mov    %eax,-0xc(%ebp)
  103f6a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103f6d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  103f72:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  103f75:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103f78:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  103f7e:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  103f83:	74 24                	je     103fa9 <cpu_cur+0x51>
  103f85:	c7 44 24 0c 8b 62 10 	movl   $0x10628b,0xc(%esp)
  103f8c:	00 
  103f8d:	c7 44 24 08 a1 62 10 	movl   $0x1062a1,0x8(%esp)
  103f94:	00 
  103f95:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  103f9c:	00 
  103f9d:	c7 04 24 b6 62 10 00 	movl   $0x1062b6,(%esp)
  103fa4:	e8 1b c5 ff ff       	call   1004c4 <debug_panic>
	return c;
  103fa9:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  103fac:	83 c4 24             	add    $0x24,%esp
  103faf:	5b                   	pop    %ebx
  103fb0:	5d                   	pop    %ebp
  103fb1:	c3                   	ret    

00103fb2 <lapicw>:
volatile uint32_t *lapic;  // Initialized in mp.c


static void
lapicw(int index, int value)
{
  103fb2:	55                   	push   %ebp
  103fb3:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
  103fb5:	a1 8c 0a 31 00       	mov    0x310a8c,%eax
  103fba:	8b 55 08             	mov    0x8(%ebp),%edx
  103fbd:	c1 e2 02             	shl    $0x2,%edx
  103fc0:	01 c2                	add    %eax,%edx
  103fc2:	8b 45 0c             	mov    0xc(%ebp),%eax
  103fc5:	89 02                	mov    %eax,(%edx)
	lapic[ID];  // wait for write to finish, by reading
  103fc7:	a1 8c 0a 31 00       	mov    0x310a8c,%eax
  103fcc:	83 c0 20             	add    $0x20,%eax
  103fcf:	8b 00                	mov    (%eax),%eax
}
  103fd1:	5d                   	pop    %ebp
  103fd2:	c3                   	ret    

00103fd3 <lapic_init>:

void
lapic_init()
{
  103fd3:	55                   	push   %ebp
  103fd4:	89 e5                	mov    %esp,%ebp
  103fd6:	83 ec 08             	sub    $0x8,%esp
	if (!lapic) 
  103fd9:	a1 8c 0a 31 00       	mov    0x310a8c,%eax
  103fde:	85 c0                	test   %eax,%eax
  103fe0:	0f 84 83 01 00 00    	je     104169 <lapic_init+0x196>
		return;

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
  103fe6:	c7 44 24 04 27 01 00 	movl   $0x127,0x4(%esp)
  103fed:	00 
  103fee:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
  103ff5:	e8 b8 ff ff ff       	call   103fb2 <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	lapicw(TDCR, X1);
  103ffa:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
  104001:	00 
  104002:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
  104009:	e8 a4 ff ff ff       	call   103fb2 <lapicw>
	lapicw(TIMER, PERIODIC | T_LTIMER);
  10400e:	c7 44 24 04 31 00 02 	movl   $0x20031,0x4(%esp)
  104015:	00 
  104016:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  10401d:	e8 90 ff ff ff       	call   103fb2 <lapicw>

	// If we cared more about precise timekeeping,
	// we would calibrate TICR with another time source such as the PIT.
	lapicw(TICR, 10000000);
  104022:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
  104029:	00 
  10402a:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
  104031:	e8 7c ff ff ff       	call   103fb2 <lapicw>

	// Disable logical interrupt lines.
	lapicw(LINT0, MASKED);
  104036:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  10403d:	00 
  10403e:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
  104045:	e8 68 ff ff ff       	call   103fb2 <lapicw>
	lapicw(LINT1, MASKED);
  10404a:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  104051:	00 
  104052:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
  104059:	e8 54 ff ff ff       	call   103fb2 <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
  10405e:	a1 8c 0a 31 00       	mov    0x310a8c,%eax
  104063:	83 c0 30             	add    $0x30,%eax
  104066:	8b 00                	mov    (%eax),%eax
  104068:	c1 e8 10             	shr    $0x10,%eax
  10406b:	25 ff 00 00 00       	and    $0xff,%eax
  104070:	83 f8 03             	cmp    $0x3,%eax
  104073:	76 14                	jbe    104089 <lapic_init+0xb6>
		lapicw(PCINT, MASKED);
  104075:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  10407c:	00 
  10407d:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
  104084:	e8 29 ff ff ff       	call   103fb2 <lapicw>

	// Map other interrupts to appropriate vectors.
	lapicw(ERROR, T_LERROR);
  104089:	c7 44 24 04 32 00 00 	movl   $0x32,0x4(%esp)
  104090:	00 
  104091:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
  104098:	e8 15 ff ff ff       	call   103fb2 <lapicw>

	// Set up to lowest-priority, "anycast" interrupts
	lapicw(LDR, 0xff << 24);	// Accept all interrupts
  10409d:	c7 44 24 04 00 00 00 	movl   $0xff000000,0x4(%esp)
  1040a4:	ff 
  1040a5:	c7 04 24 34 00 00 00 	movl   $0x34,(%esp)
  1040ac:	e8 01 ff ff ff       	call   103fb2 <lapicw>
	lapicw(DFR, 0xf << 28);		// Flat model
  1040b1:	c7 44 24 04 00 00 00 	movl   $0xf0000000,0x4(%esp)
  1040b8:	f0 
  1040b9:	c7 04 24 38 00 00 00 	movl   $0x38,(%esp)
  1040c0:	e8 ed fe ff ff       	call   103fb2 <lapicw>
	lapicw(TPR, 0x00);		// Task priority 0, no intrs masked
  1040c5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1040cc:	00 
  1040cd:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1040d4:	e8 d9 fe ff ff       	call   103fb2 <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
  1040d9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1040e0:	00 
  1040e1:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  1040e8:	e8 c5 fe ff ff       	call   103fb2 <lapicw>
	lapicw(ESR, 0);
  1040ed:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1040f4:	00 
  1040f5:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  1040fc:	e8 b1 fe ff ff       	call   103fb2 <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
  104101:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104108:	00 
  104109:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
  104110:	e8 9d fe ff ff       	call   103fb2 <lapicw>

	// Send an Init Level De-Assert to synchronise arbitration ID's.
	lapicw(ICRHI, 0);
  104115:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10411c:	00 
  10411d:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  104124:	e8 89 fe ff ff       	call   103fb2 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
  104129:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
  104130:	00 
  104131:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  104138:	e8 75 fe ff ff       	call   103fb2 <lapicw>
	while(lapic[ICRLO] & DELIVS)
  10413d:	90                   	nop
  10413e:	a1 8c 0a 31 00       	mov    0x310a8c,%eax
  104143:	05 00 03 00 00       	add    $0x300,%eax
  104148:	8b 00                	mov    (%eax),%eax
  10414a:	25 00 10 00 00       	and    $0x1000,%eax
  10414f:	85 c0                	test   %eax,%eax
  104151:	75 eb                	jne    10413e <lapic_init+0x16b>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
  104153:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10415a:	00 
  10415b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  104162:	e8 4b fe ff ff       	call   103fb2 <lapicw>
  104167:	eb 01                	jmp    10416a <lapic_init+0x197>

void
lapic_init()
{
	if (!lapic) 
		return;
  104169:	90                   	nop
	while(lapic[ICRLO] & DELIVS)
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
}
  10416a:	c9                   	leave  
  10416b:	c3                   	ret    

0010416c <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
  10416c:	55                   	push   %ebp
  10416d:	89 e5                	mov    %esp,%ebp
  10416f:	83 ec 08             	sub    $0x8,%esp
	if (lapic)
  104172:	a1 8c 0a 31 00       	mov    0x310a8c,%eax
  104177:	85 c0                	test   %eax,%eax
  104179:	74 14                	je     10418f <lapic_eoi+0x23>
		lapicw(EOI, 0);
  10417b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104182:	00 
  104183:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
  10418a:	e8 23 fe ff ff       	call   103fb2 <lapicw>
}
  10418f:	c9                   	leave  
  104190:	c3                   	ret    

00104191 <lapic_errintr>:

void lapic_errintr(void)
{
  104191:	55                   	push   %ebp
  104192:	89 e5                	mov    %esp,%ebp
  104194:	53                   	push   %ebx
  104195:	83 ec 24             	sub    $0x24,%esp
	lapic_eoi();	// Acknowledge interrupt
  104198:	e8 cf ff ff ff       	call   10416c <lapic_eoi>
	lapicw(ESR, 0);	// Trigger update of ESR by writing anything
  10419d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1041a4:	00 
  1041a5:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  1041ac:	e8 01 fe ff ff       	call   103fb2 <lapicw>
	warn("CPU%d LAPIC error: ESR %x", cpu_cur()->id, lapic[ESR]);
  1041b1:	a1 8c 0a 31 00       	mov    0x310a8c,%eax
  1041b6:	05 80 02 00 00       	add    $0x280,%eax
  1041bb:	8b 18                	mov    (%eax),%ebx
  1041bd:	e8 96 fd ff ff       	call   103f58 <cpu_cur>
  1041c2:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  1041c9:	0f b6 c0             	movzbl %al,%eax
  1041cc:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  1041d0:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1041d4:	c7 44 24 08 c3 62 10 	movl   $0x1062c3,0x8(%esp)
  1041db:	00 
  1041dc:	c7 44 24 04 60 00 00 	movl   $0x60,0x4(%esp)
  1041e3:	00 
  1041e4:	c7 04 24 dd 62 10 00 	movl   $0x1062dd,(%esp)
  1041eb:	e8 9a c3 ff ff       	call   10058a <debug_warn>
}
  1041f0:	83 c4 24             	add    $0x24,%esp
  1041f3:	5b                   	pop    %ebx
  1041f4:	5d                   	pop    %ebp
  1041f5:	c3                   	ret    

001041f6 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
  1041f6:	55                   	push   %ebp
  1041f7:	89 e5                	mov    %esp,%ebp
}
  1041f9:	5d                   	pop    %ebp
  1041fa:	c3                   	ret    

001041fb <lapic_startcpu>:

// Start additional processor running bootstrap code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startcpu(uint8_t apicid, uint32_t addr)
{
  1041fb:	55                   	push   %ebp
  1041fc:	89 e5                	mov    %esp,%ebp
  1041fe:	83 ec 2c             	sub    $0x2c,%esp
  104201:	8b 45 08             	mov    0x8(%ebp),%eax
  104204:	88 45 dc             	mov    %al,-0x24(%ebp)
  104207:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  10420e:	c6 45 f3 0f          	movb   $0xf,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  104212:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  104216:	8b 55 f4             	mov    -0xc(%ebp),%edx
  104219:	ee                   	out    %al,(%dx)
  10421a:	c7 45 ec 71 00 00 00 	movl   $0x71,-0x14(%ebp)
  104221:	c6 45 eb 0a          	movb   $0xa,-0x15(%ebp)
  104225:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  104229:	8b 55 ec             	mov    -0x14(%ebp),%edx
  10422c:	ee                   	out    %al,(%dx)
	// "The BSP must initialize CMOS shutdown code to 0AH
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t*)(0x40<<4 | 0x67);  // Warm reset vector
  10422d:	c7 45 f8 67 04 00 00 	movl   $0x467,-0x8(%ebp)
	wrv[0] = 0;
  104234:	8b 45 f8             	mov    -0x8(%ebp),%eax
  104237:	66 c7 00 00 00       	movw   $0x0,(%eax)
	wrv[1] = addr >> 4;
  10423c:	8b 45 f8             	mov    -0x8(%ebp),%eax
  10423f:	8d 50 02             	lea    0x2(%eax),%edx
  104242:	8b 45 0c             	mov    0xc(%ebp),%eax
  104245:	c1 e8 04             	shr    $0x4,%eax
  104248:	66 89 02             	mov    %ax,(%edx)

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid<<24);
  10424b:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
  10424f:	c1 e0 18             	shl    $0x18,%eax
  104252:	89 44 24 04          	mov    %eax,0x4(%esp)
  104256:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  10425d:	e8 50 fd ff ff       	call   103fb2 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
  104262:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
  104269:	00 
  10426a:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  104271:	e8 3c fd ff ff       	call   103fb2 <lapicw>
	microdelay(200);
  104276:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  10427d:	e8 74 ff ff ff       	call   1041f6 <microdelay>
	lapicw(ICRLO, INIT | LEVEL);
  104282:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
  104289:	00 
  10428a:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  104291:	e8 1c fd ff ff       	call   103fb2 <lapicw>
	microdelay(100);    // should be 10ms, but too slow in Bochs!
  104296:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
  10429d:	e8 54 ff ff ff       	call   1041f6 <microdelay>
	// Send startup IPI (twice!) to enter bootstrap code.
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for(i = 0; i < 2; i++){
  1042a2:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  1042a9:	eb 40                	jmp    1042eb <lapic_startcpu+0xf0>
		lapicw(ICRHI, apicid<<24);
  1042ab:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
  1042af:	c1 e0 18             	shl    $0x18,%eax
  1042b2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1042b6:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  1042bd:	e8 f0 fc ff ff       	call   103fb2 <lapicw>
		lapicw(ICRLO, STARTUP | (addr>>12));
  1042c2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1042c5:	c1 e8 0c             	shr    $0xc,%eax
  1042c8:	80 cc 06             	or     $0x6,%ah
  1042cb:	89 44 24 04          	mov    %eax,0x4(%esp)
  1042cf:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  1042d6:	e8 d7 fc ff ff       	call   103fb2 <lapicw>
		microdelay(200);
  1042db:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  1042e2:	e8 0f ff ff ff       	call   1041f6 <microdelay>
	// Send startup IPI (twice!) to enter bootstrap code.
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for(i = 0; i < 2; i++){
  1042e7:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  1042eb:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
  1042ef:	7e ba                	jle    1042ab <lapic_startcpu+0xb0>
		lapicw(ICRHI, apicid<<24);
		lapicw(ICRLO, STARTUP | (addr>>12));
		microdelay(200);
	}
}
  1042f1:	c9                   	leave  
  1042f2:	c3                   	ret    
  1042f3:	90                   	nop

001042f4 <ioapic_read>:
	uint32_t data;
};

static uint32_t
ioapic_read(int reg)
{
  1042f4:	55                   	push   %ebp
  1042f5:	89 e5                	mov    %esp,%ebp
	ioapic->reg = reg;
  1042f7:	a1 8c 03 31 00       	mov    0x31038c,%eax
  1042fc:	8b 55 08             	mov    0x8(%ebp),%edx
  1042ff:	89 10                	mov    %edx,(%eax)
	return ioapic->data;
  104301:	a1 8c 03 31 00       	mov    0x31038c,%eax
  104306:	8b 40 10             	mov    0x10(%eax),%eax
}
  104309:	5d                   	pop    %ebp
  10430a:	c3                   	ret    

0010430b <ioapic_write>:

static void
ioapic_write(int reg, uint32_t data)
{
  10430b:	55                   	push   %ebp
  10430c:	89 e5                	mov    %esp,%ebp
	ioapic->reg = reg;
  10430e:	a1 8c 03 31 00       	mov    0x31038c,%eax
  104313:	8b 55 08             	mov    0x8(%ebp),%edx
  104316:	89 10                	mov    %edx,(%eax)
	ioapic->data = data;
  104318:	a1 8c 03 31 00       	mov    0x31038c,%eax
  10431d:	8b 55 0c             	mov    0xc(%ebp),%edx
  104320:	89 50 10             	mov    %edx,0x10(%eax)
}
  104323:	5d                   	pop    %ebp
  104324:	c3                   	ret    

00104325 <ioapic_init>:

void
ioapic_init(void)
{
  104325:	55                   	push   %ebp
  104326:	89 e5                	mov    %esp,%ebp
  104328:	83 ec 38             	sub    $0x38,%esp
	int i, id, maxintr;

	if(!ismp)
  10432b:	a1 90 03 31 00       	mov    0x310390,%eax
  104330:	85 c0                	test   %eax,%eax
  104332:	0f 84 fd 00 00 00    	je     104435 <ioapic_init+0x110>
		return;

	if (ioapic == NULL)
  104338:	a1 8c 03 31 00       	mov    0x31038c,%eax
  10433d:	85 c0                	test   %eax,%eax
  10433f:	75 0a                	jne    10434b <ioapic_init+0x26>
		ioapic = mem_ptr(IOAPIC);	// assume default address
  104341:	c7 05 8c 03 31 00 00 	movl   $0xfec00000,0x31038c
  104348:	00 c0 fe 

	maxintr = (ioapic_read(REG_VER) >> 16) & 0xFF;
  10434b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104352:	e8 9d ff ff ff       	call   1042f4 <ioapic_read>
  104357:	c1 e8 10             	shr    $0x10,%eax
  10435a:	25 ff 00 00 00       	and    $0xff,%eax
  10435f:	89 45 ec             	mov    %eax,-0x14(%ebp)
	id = ioapic_read(REG_ID) >> 24;
  104362:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  104369:	e8 86 ff ff ff       	call   1042f4 <ioapic_read>
  10436e:	c1 e8 18             	shr    $0x18,%eax
  104371:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (id == 0) {
  104374:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  104378:	75 2a                	jne    1043a4 <ioapic_init+0x7f>
		// I/O APIC ID not initialized yet - have to do it ourselves.
		ioapic_write(REG_ID, ioapicid << 24);
  10437a:	0f b6 05 88 03 31 00 	movzbl 0x310388,%eax
  104381:	0f b6 c0             	movzbl %al,%eax
  104384:	c1 e0 18             	shl    $0x18,%eax
  104387:	89 44 24 04          	mov    %eax,0x4(%esp)
  10438b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  104392:	e8 74 ff ff ff       	call   10430b <ioapic_write>
		id = ioapicid;
  104397:	0f b6 05 88 03 31 00 	movzbl 0x310388,%eax
  10439e:	0f b6 c0             	movzbl %al,%eax
  1043a1:	89 45 f0             	mov    %eax,-0x10(%ebp)
	}
	if (id != ioapicid)
  1043a4:	0f b6 05 88 03 31 00 	movzbl 0x310388,%eax
  1043ab:	0f b6 c0             	movzbl %al,%eax
  1043ae:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  1043b1:	74 31                	je     1043e4 <ioapic_init+0xbf>
		warn("ioapicinit: id %d != ioapicid %d", id, ioapicid);
  1043b3:	0f b6 05 88 03 31 00 	movzbl 0x310388,%eax
  1043ba:	0f b6 c0             	movzbl %al,%eax
  1043bd:	89 44 24 10          	mov    %eax,0x10(%esp)
  1043c1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1043c4:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1043c8:	c7 44 24 08 ec 62 10 	movl   $0x1062ec,0x8(%esp)
  1043cf:	00 
  1043d0:	c7 44 24 04 53 00 00 	movl   $0x53,0x4(%esp)
  1043d7:	00 
  1043d8:	c7 04 24 0d 63 10 00 	movl   $0x10630d,(%esp)
  1043df:	e8 a6 c1 ff ff       	call   10058a <debug_warn>

	// Mark all interrupts edge-triggered, active high, disabled,
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
  1043e4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  1043eb:	eb 3e                	jmp    10442b <ioapic_init+0x106>
		ioapic_write(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
  1043ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1043f0:	83 c0 20             	add    $0x20,%eax
  1043f3:	0d 00 00 01 00       	or     $0x10000,%eax
  1043f8:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1043fb:	83 c2 08             	add    $0x8,%edx
  1043fe:	01 d2                	add    %edx,%edx
  104400:	89 44 24 04          	mov    %eax,0x4(%esp)
  104404:	89 14 24             	mov    %edx,(%esp)
  104407:	e8 ff fe ff ff       	call   10430b <ioapic_write>
		ioapic_write(REG_TABLE+2*i+1, 0);
  10440c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10440f:	83 c0 08             	add    $0x8,%eax
  104412:	01 c0                	add    %eax,%eax
  104414:	83 c0 01             	add    $0x1,%eax
  104417:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10441e:	00 
  10441f:	89 04 24             	mov    %eax,(%esp)
  104422:	e8 e4 fe ff ff       	call   10430b <ioapic_write>
	if (id != ioapicid)
		warn("ioapicinit: id %d != ioapicid %d", id, ioapicid);

	// Mark all interrupts edge-triggered, active high, disabled,
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
  104427:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  10442b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10442e:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  104431:	7e ba                	jle    1043ed <ioapic_init+0xc8>
  104433:	eb 01                	jmp    104436 <ioapic_init+0x111>
ioapic_init(void)
{
	int i, id, maxintr;

	if(!ismp)
		return;
  104435:	90                   	nop
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
		ioapic_write(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
		ioapic_write(REG_TABLE+2*i+1, 0);
	}
}
  104436:	c9                   	leave  
  104437:	c3                   	ret    

00104438 <ioapic_enable>:

void
ioapic_enable(int irq)
{
  104438:	55                   	push   %ebp
  104439:	89 e5                	mov    %esp,%ebp
  10443b:	83 ec 08             	sub    $0x8,%esp
	if (!ismp)
  10443e:	a1 90 03 31 00       	mov    0x310390,%eax
  104443:	85 c0                	test   %eax,%eax
  104445:	74 3a                	je     104481 <ioapic_enable+0x49>
		return;

	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
  104447:	8b 45 08             	mov    0x8(%ebp),%eax
  10444a:	83 c0 20             	add    $0x20,%eax
  10444d:	80 cc 09             	or     $0x9,%ah
	if (!ismp)
		return;

	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
  104450:	8b 55 08             	mov    0x8(%ebp),%edx
  104453:	83 c2 08             	add    $0x8,%edx
  104456:	01 d2                	add    %edx,%edx
  104458:	89 44 24 04          	mov    %eax,0x4(%esp)
  10445c:	89 14 24             	mov    %edx,(%esp)
  10445f:	e8 a7 fe ff ff       	call   10430b <ioapic_write>
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
	ioapic_write(REG_TABLE+2*irq+1, 0xff << 24);
  104464:	8b 45 08             	mov    0x8(%ebp),%eax
  104467:	83 c0 08             	add    $0x8,%eax
  10446a:	01 c0                	add    %eax,%eax
  10446c:	83 c0 01             	add    $0x1,%eax
  10446f:	c7 44 24 04 00 00 00 	movl   $0xff000000,0x4(%esp)
  104476:	ff 
  104477:	89 04 24             	mov    %eax,(%esp)
  10447a:	e8 8c fe ff ff       	call   10430b <ioapic_write>
  10447f:	eb 01                	jmp    104482 <ioapic_enable+0x4a>

void
ioapic_enable(int irq)
{
	if (!ismp)
		return;
  104481:	90                   	nop
	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
	ioapic_write(REG_TABLE+2*irq+1, 0xff << 24);
}
  104482:	c9                   	leave  
  104483:	c3                   	ret    

00104484 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static uintmax_t
getuint(printstate *st, va_list *ap)
{
  104484:	55                   	push   %ebp
  104485:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  104487:	8b 45 08             	mov    0x8(%ebp),%eax
  10448a:	8b 40 18             	mov    0x18(%eax),%eax
  10448d:	83 e0 02             	and    $0x2,%eax
  104490:	85 c0                	test   %eax,%eax
  104492:	74 1c                	je     1044b0 <getuint+0x2c>
		return va_arg(*ap, unsigned long long);
  104494:	8b 45 0c             	mov    0xc(%ebp),%eax
  104497:	8b 00                	mov    (%eax),%eax
  104499:	8d 50 08             	lea    0x8(%eax),%edx
  10449c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10449f:	89 10                	mov    %edx,(%eax)
  1044a1:	8b 45 0c             	mov    0xc(%ebp),%eax
  1044a4:	8b 00                	mov    (%eax),%eax
  1044a6:	83 e8 08             	sub    $0x8,%eax
  1044a9:	8b 50 04             	mov    0x4(%eax),%edx
  1044ac:	8b 00                	mov    (%eax),%eax
  1044ae:	eb 47                	jmp    1044f7 <getuint+0x73>
	else if (st->flags & F_L)
  1044b0:	8b 45 08             	mov    0x8(%ebp),%eax
  1044b3:	8b 40 18             	mov    0x18(%eax),%eax
  1044b6:	83 e0 01             	and    $0x1,%eax
  1044b9:	85 c0                	test   %eax,%eax
  1044bb:	74 1e                	je     1044db <getuint+0x57>
		return va_arg(*ap, unsigned long);
  1044bd:	8b 45 0c             	mov    0xc(%ebp),%eax
  1044c0:	8b 00                	mov    (%eax),%eax
  1044c2:	8d 50 04             	lea    0x4(%eax),%edx
  1044c5:	8b 45 0c             	mov    0xc(%ebp),%eax
  1044c8:	89 10                	mov    %edx,(%eax)
  1044ca:	8b 45 0c             	mov    0xc(%ebp),%eax
  1044cd:	8b 00                	mov    (%eax),%eax
  1044cf:	83 e8 04             	sub    $0x4,%eax
  1044d2:	8b 00                	mov    (%eax),%eax
  1044d4:	ba 00 00 00 00       	mov    $0x0,%edx
  1044d9:	eb 1c                	jmp    1044f7 <getuint+0x73>
	else
		return va_arg(*ap, unsigned int);
  1044db:	8b 45 0c             	mov    0xc(%ebp),%eax
  1044de:	8b 00                	mov    (%eax),%eax
  1044e0:	8d 50 04             	lea    0x4(%eax),%edx
  1044e3:	8b 45 0c             	mov    0xc(%ebp),%eax
  1044e6:	89 10                	mov    %edx,(%eax)
  1044e8:	8b 45 0c             	mov    0xc(%ebp),%eax
  1044eb:	8b 00                	mov    (%eax),%eax
  1044ed:	83 e8 04             	sub    $0x4,%eax
  1044f0:	8b 00                	mov    (%eax),%eax
  1044f2:	ba 00 00 00 00       	mov    $0x0,%edx
}
  1044f7:	5d                   	pop    %ebp
  1044f8:	c3                   	ret    

001044f9 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static intmax_t
getint(printstate *st, va_list *ap)
{
  1044f9:	55                   	push   %ebp
  1044fa:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  1044fc:	8b 45 08             	mov    0x8(%ebp),%eax
  1044ff:	8b 40 18             	mov    0x18(%eax),%eax
  104502:	83 e0 02             	and    $0x2,%eax
  104505:	85 c0                	test   %eax,%eax
  104507:	74 1c                	je     104525 <getint+0x2c>
		return va_arg(*ap, long long);
  104509:	8b 45 0c             	mov    0xc(%ebp),%eax
  10450c:	8b 00                	mov    (%eax),%eax
  10450e:	8d 50 08             	lea    0x8(%eax),%edx
  104511:	8b 45 0c             	mov    0xc(%ebp),%eax
  104514:	89 10                	mov    %edx,(%eax)
  104516:	8b 45 0c             	mov    0xc(%ebp),%eax
  104519:	8b 00                	mov    (%eax),%eax
  10451b:	83 e8 08             	sub    $0x8,%eax
  10451e:	8b 50 04             	mov    0x4(%eax),%edx
  104521:	8b 00                	mov    (%eax),%eax
  104523:	eb 47                	jmp    10456c <getint+0x73>
	else if (st->flags & F_L)
  104525:	8b 45 08             	mov    0x8(%ebp),%eax
  104528:	8b 40 18             	mov    0x18(%eax),%eax
  10452b:	83 e0 01             	and    $0x1,%eax
  10452e:	85 c0                	test   %eax,%eax
  104530:	74 1e                	je     104550 <getint+0x57>
		return va_arg(*ap, long);
  104532:	8b 45 0c             	mov    0xc(%ebp),%eax
  104535:	8b 00                	mov    (%eax),%eax
  104537:	8d 50 04             	lea    0x4(%eax),%edx
  10453a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10453d:	89 10                	mov    %edx,(%eax)
  10453f:	8b 45 0c             	mov    0xc(%ebp),%eax
  104542:	8b 00                	mov    (%eax),%eax
  104544:	83 e8 04             	sub    $0x4,%eax
  104547:	8b 00                	mov    (%eax),%eax
  104549:	89 c2                	mov    %eax,%edx
  10454b:	c1 fa 1f             	sar    $0x1f,%edx
  10454e:	eb 1c                	jmp    10456c <getint+0x73>
	else
		return va_arg(*ap, int);
  104550:	8b 45 0c             	mov    0xc(%ebp),%eax
  104553:	8b 00                	mov    (%eax),%eax
  104555:	8d 50 04             	lea    0x4(%eax),%edx
  104558:	8b 45 0c             	mov    0xc(%ebp),%eax
  10455b:	89 10                	mov    %edx,(%eax)
  10455d:	8b 45 0c             	mov    0xc(%ebp),%eax
  104560:	8b 00                	mov    (%eax),%eax
  104562:	83 e8 04             	sub    $0x4,%eax
  104565:	8b 00                	mov    (%eax),%eax
  104567:	89 c2                	mov    %eax,%edx
  104569:	c1 fa 1f             	sar    $0x1f,%edx
}
  10456c:	5d                   	pop    %ebp
  10456d:	c3                   	ret    

0010456e <putpad>:

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
  10456e:	55                   	push   %ebp
  10456f:	89 e5                	mov    %esp,%ebp
  104571:	83 ec 18             	sub    $0x18,%esp
	while (--st->width >= 0)
  104574:	eb 1a                	jmp    104590 <putpad+0x22>
		st->putch(st->padc, st->putdat);
  104576:	8b 45 08             	mov    0x8(%ebp),%eax
  104579:	8b 00                	mov    (%eax),%eax
  10457b:	8b 55 08             	mov    0x8(%ebp),%edx
  10457e:	8b 4a 04             	mov    0x4(%edx),%ecx
  104581:	8b 55 08             	mov    0x8(%ebp),%edx
  104584:	8b 52 08             	mov    0x8(%edx),%edx
  104587:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  10458b:	89 14 24             	mov    %edx,(%esp)
  10458e:	ff d0                	call   *%eax

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
	while (--st->width >= 0)
  104590:	8b 45 08             	mov    0x8(%ebp),%eax
  104593:	8b 40 0c             	mov    0xc(%eax),%eax
  104596:	8d 50 ff             	lea    -0x1(%eax),%edx
  104599:	8b 45 08             	mov    0x8(%ebp),%eax
  10459c:	89 50 0c             	mov    %edx,0xc(%eax)
  10459f:	8b 45 08             	mov    0x8(%ebp),%eax
  1045a2:	8b 40 0c             	mov    0xc(%eax),%eax
  1045a5:	85 c0                	test   %eax,%eax
  1045a7:	79 cd                	jns    104576 <putpad+0x8>
		st->putch(st->padc, st->putdat);
}
  1045a9:	c9                   	leave  
  1045aa:	c3                   	ret    

001045ab <putstr>:

// Print a string with a specified maximum length (-1=unlimited),
// with any appropriate left or right field padding.
static void
putstr(printstate *st, const char *str, int maxlen)
{
  1045ab:	55                   	push   %ebp
  1045ac:	89 e5                	mov    %esp,%ebp
  1045ae:	53                   	push   %ebx
  1045af:	83 ec 24             	sub    $0x24,%esp
	const char *lim;		// find where the string actually ends
	if (maxlen < 0)
  1045b2:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1045b6:	79 18                	jns    1045d0 <putstr+0x25>
		lim = strchr(str, 0);	// find the terminating null
  1045b8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1045bf:	00 
  1045c0:	8b 45 0c             	mov    0xc(%ebp),%eax
  1045c3:	89 04 24             	mov    %eax,(%esp)
  1045c6:	e8 e6 07 00 00       	call   104db1 <strchr>
  1045cb:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1045ce:	eb 2e                	jmp    1045fe <putstr+0x53>
	else if ((lim = memchr(str, 0, maxlen)) == NULL)
  1045d0:	8b 45 10             	mov    0x10(%ebp),%eax
  1045d3:	89 44 24 08          	mov    %eax,0x8(%esp)
  1045d7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1045de:	00 
  1045df:	8b 45 0c             	mov    0xc(%ebp),%eax
  1045e2:	89 04 24             	mov    %eax,(%esp)
  1045e5:	e8 c4 09 00 00       	call   104fae <memchr>
  1045ea:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1045ed:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1045f1:	75 0b                	jne    1045fe <putstr+0x53>
		lim = str + maxlen;
  1045f3:	8b 55 10             	mov    0x10(%ebp),%edx
  1045f6:	8b 45 0c             	mov    0xc(%ebp),%eax
  1045f9:	01 d0                	add    %edx,%eax
  1045fb:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->width -= (lim-str);		// deduct string length from field width
  1045fe:	8b 45 08             	mov    0x8(%ebp),%eax
  104601:	8b 40 0c             	mov    0xc(%eax),%eax
  104604:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  104607:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10460a:	89 cb                	mov    %ecx,%ebx
  10460c:	29 d3                	sub    %edx,%ebx
  10460e:	89 da                	mov    %ebx,%edx
  104610:	01 c2                	add    %eax,%edx
  104612:	8b 45 08             	mov    0x8(%ebp),%eax
  104615:	89 50 0c             	mov    %edx,0xc(%eax)

	if (!(st->flags & F_RPAD))	// print left-side padding
  104618:	8b 45 08             	mov    0x8(%ebp),%eax
  10461b:	8b 40 18             	mov    0x18(%eax),%eax
  10461e:	83 e0 10             	and    $0x10,%eax
  104621:	85 c0                	test   %eax,%eax
  104623:	75 32                	jne    104657 <putstr+0xac>
		putpad(st);		// (also leaves st->width == 0)
  104625:	8b 45 08             	mov    0x8(%ebp),%eax
  104628:	89 04 24             	mov    %eax,(%esp)
  10462b:	e8 3e ff ff ff       	call   10456e <putpad>
	while (str < lim) {
  104630:	eb 25                	jmp    104657 <putstr+0xac>
		char ch = *str++;
  104632:	8b 45 0c             	mov    0xc(%ebp),%eax
  104635:	0f b6 00             	movzbl (%eax),%eax
  104638:	88 45 f3             	mov    %al,-0xd(%ebp)
  10463b:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
			st->putch(ch, st->putdat);
  10463f:	8b 45 08             	mov    0x8(%ebp),%eax
  104642:	8b 00                	mov    (%eax),%eax
  104644:	8b 55 08             	mov    0x8(%ebp),%edx
  104647:	8b 4a 04             	mov    0x4(%edx),%ecx
  10464a:	0f be 55 f3          	movsbl -0xd(%ebp),%edx
  10464e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  104652:	89 14 24             	mov    %edx,(%esp)
  104655:	ff d0                	call   *%eax
		lim = str + maxlen;
	st->width -= (lim-str);		// deduct string length from field width

	if (!(st->flags & F_RPAD))	// print left-side padding
		putpad(st);		// (also leaves st->width == 0)
	while (str < lim) {
  104657:	8b 45 0c             	mov    0xc(%ebp),%eax
  10465a:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  10465d:	72 d3                	jb     104632 <putstr+0x87>
		char ch = *str++;
			st->putch(ch, st->putdat);
	}
	putpad(st);			// print right-side padding
  10465f:	8b 45 08             	mov    0x8(%ebp),%eax
  104662:	89 04 24             	mov    %eax,(%esp)
  104665:	e8 04 ff ff ff       	call   10456e <putpad>
}
  10466a:	83 c4 24             	add    $0x24,%esp
  10466d:	5b                   	pop    %ebx
  10466e:	5d                   	pop    %ebp
  10466f:	c3                   	ret    

00104670 <genint>:

// Generate a number (base <= 16) in reverse order into a string buffer.
static char *
genint(printstate *st, char *p, uintmax_t num)
{
  104670:	55                   	push   %ebp
  104671:	89 e5                	mov    %esp,%ebp
  104673:	53                   	push   %ebx
  104674:	83 ec 24             	sub    $0x24,%esp
  104677:	8b 45 10             	mov    0x10(%ebp),%eax
  10467a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10467d:	8b 45 14             	mov    0x14(%ebp),%eax
  104680:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= st->base)
  104683:	8b 45 08             	mov    0x8(%ebp),%eax
  104686:	8b 40 1c             	mov    0x1c(%eax),%eax
  104689:	89 c2                	mov    %eax,%edx
  10468b:	c1 fa 1f             	sar    $0x1f,%edx
  10468e:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  104691:	77 4e                	ja     1046e1 <genint+0x71>
  104693:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  104696:	72 05                	jb     10469d <genint+0x2d>
  104698:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  10469b:	77 44                	ja     1046e1 <genint+0x71>
		p = genint(st, p, num / st->base);	// output higher digits
  10469d:	8b 45 08             	mov    0x8(%ebp),%eax
  1046a0:	8b 40 1c             	mov    0x1c(%eax),%eax
  1046a3:	89 c2                	mov    %eax,%edx
  1046a5:	c1 fa 1f             	sar    $0x1f,%edx
  1046a8:	89 44 24 08          	mov    %eax,0x8(%esp)
  1046ac:	89 54 24 0c          	mov    %edx,0xc(%esp)
  1046b0:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1046b3:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1046b6:	89 04 24             	mov    %eax,(%esp)
  1046b9:	89 54 24 04          	mov    %edx,0x4(%esp)
  1046bd:	e8 2e 09 00 00       	call   104ff0 <__udivdi3>
  1046c2:	89 44 24 08          	mov    %eax,0x8(%esp)
  1046c6:	89 54 24 0c          	mov    %edx,0xc(%esp)
  1046ca:	8b 45 0c             	mov    0xc(%ebp),%eax
  1046cd:	89 44 24 04          	mov    %eax,0x4(%esp)
  1046d1:	8b 45 08             	mov    0x8(%ebp),%eax
  1046d4:	89 04 24             	mov    %eax,(%esp)
  1046d7:	e8 94 ff ff ff       	call   104670 <genint>
  1046dc:	89 45 0c             	mov    %eax,0xc(%ebp)
  1046df:	eb 1b                	jmp    1046fc <genint+0x8c>
	else if (st->signc >= 0)
  1046e1:	8b 45 08             	mov    0x8(%ebp),%eax
  1046e4:	8b 40 14             	mov    0x14(%eax),%eax
  1046e7:	85 c0                	test   %eax,%eax
  1046e9:	78 11                	js     1046fc <genint+0x8c>
		*p++ = st->signc;			// output leading sign
  1046eb:	8b 45 08             	mov    0x8(%ebp),%eax
  1046ee:	8b 40 14             	mov    0x14(%eax),%eax
  1046f1:	89 c2                	mov    %eax,%edx
  1046f3:	8b 45 0c             	mov    0xc(%ebp),%eax
  1046f6:	88 10                	mov    %dl,(%eax)
  1046f8:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	*p++ = "0123456789abcdef"[num % st->base];	// output this digit
  1046fc:	8b 45 08             	mov    0x8(%ebp),%eax
  1046ff:	8b 40 1c             	mov    0x1c(%eax),%eax
  104702:	89 c1                	mov    %eax,%ecx
  104704:	89 c3                	mov    %eax,%ebx
  104706:	c1 fb 1f             	sar    $0x1f,%ebx
  104709:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10470c:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10470f:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  104713:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  104717:	89 04 24             	mov    %eax,(%esp)
  10471a:	89 54 24 04          	mov    %edx,0x4(%esp)
  10471e:	e8 2d 0a 00 00       	call   105150 <__umoddi3>
  104723:	05 1c 63 10 00       	add    $0x10631c,%eax
  104728:	0f b6 10             	movzbl (%eax),%edx
  10472b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10472e:	88 10                	mov    %dl,(%eax)
  104730:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	return p;
  104734:	8b 45 0c             	mov    0xc(%ebp),%eax
}
  104737:	83 c4 24             	add    $0x24,%esp
  10473a:	5b                   	pop    %ebx
  10473b:	5d                   	pop    %ebp
  10473c:	c3                   	ret    

0010473d <putint>:

// Print an integer with any appropriate field padding.
static void
putint(printstate *st, uintmax_t num, int base)
{
  10473d:	55                   	push   %ebp
  10473e:	89 e5                	mov    %esp,%ebp
  104740:	83 ec 58             	sub    $0x58,%esp
  104743:	8b 45 0c             	mov    0xc(%ebp),%eax
  104746:	89 45 c0             	mov    %eax,-0x40(%ebp)
  104749:	8b 45 10             	mov    0x10(%ebp),%eax
  10474c:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	char buf[30], *p = buf;		// big enough for any 64-bit int in octal
  10474f:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  104752:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->base = base;		// select base for genint
  104755:	8b 45 08             	mov    0x8(%ebp),%eax
  104758:	8b 55 14             	mov    0x14(%ebp),%edx
  10475b:	89 50 1c             	mov    %edx,0x1c(%eax)
	p = genint(st, p, num);		// output to the string buffer
  10475e:	8b 45 c0             	mov    -0x40(%ebp),%eax
  104761:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  104764:	89 44 24 08          	mov    %eax,0x8(%esp)
  104768:	89 54 24 0c          	mov    %edx,0xc(%esp)
  10476c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10476f:	89 44 24 04          	mov    %eax,0x4(%esp)
  104773:	8b 45 08             	mov    0x8(%ebp),%eax
  104776:	89 04 24             	mov    %eax,(%esp)
  104779:	e8 f2 fe ff ff       	call   104670 <genint>
  10477e:	89 45 f4             	mov    %eax,-0xc(%ebp)
	putstr(st, buf, p-buf);		// print it with left/right padding
  104781:	8b 55 f4             	mov    -0xc(%ebp),%edx
  104784:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  104787:	89 d1                	mov    %edx,%ecx
  104789:	29 c1                	sub    %eax,%ecx
  10478b:	89 c8                	mov    %ecx,%eax
  10478d:	89 44 24 08          	mov    %eax,0x8(%esp)
  104791:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  104794:	89 44 24 04          	mov    %eax,0x4(%esp)
  104798:	8b 45 08             	mov    0x8(%ebp),%eax
  10479b:	89 04 24             	mov    %eax,(%esp)
  10479e:	e8 08 fe ff ff       	call   1045ab <putstr>
}
  1047a3:	c9                   	leave  
  1047a4:	c3                   	ret    

001047a5 <vprintfmt>:
#endif	// ! PIOS_KERNEL

// Main function to format and print a string.
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  1047a5:	55                   	push   %ebp
  1047a6:	89 e5                	mov    %esp,%ebp
  1047a8:	53                   	push   %ebx
  1047a9:	83 ec 44             	sub    $0x44,%esp
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
  1047ac:	8d 55 cc             	lea    -0x34(%ebp),%edx
  1047af:	b9 00 00 00 00       	mov    $0x0,%ecx
  1047b4:	b8 20 00 00 00       	mov    $0x20,%eax
  1047b9:	89 c3                	mov    %eax,%ebx
  1047bb:	83 e3 fc             	and    $0xfffffffc,%ebx
  1047be:	b8 00 00 00 00       	mov    $0x0,%eax
  1047c3:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
  1047c6:	83 c0 04             	add    $0x4,%eax
  1047c9:	39 d8                	cmp    %ebx,%eax
  1047cb:	72 f6                	jb     1047c3 <vprintfmt+0x1e>
  1047cd:	01 c2                	add    %eax,%edx
  1047cf:	8b 45 08             	mov    0x8(%ebp),%eax
  1047d2:	89 45 cc             	mov    %eax,-0x34(%ebp)
  1047d5:	8b 45 0c             	mov    0xc(%ebp),%eax
  1047d8:	89 45 d0             	mov    %eax,-0x30(%ebp)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  1047db:	eb 17                	jmp    1047f4 <vprintfmt+0x4f>
			if (ch == '\0')
  1047dd:	85 db                	test   %ebx,%ebx
  1047df:	0f 84 50 03 00 00    	je     104b35 <vprintfmt+0x390>
				return;
			putch(ch, putdat);
  1047e5:	8b 45 0c             	mov    0xc(%ebp),%eax
  1047e8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1047ec:	89 1c 24             	mov    %ebx,(%esp)
  1047ef:	8b 45 08             	mov    0x8(%ebp),%eax
  1047f2:	ff d0                	call   *%eax
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  1047f4:	8b 45 10             	mov    0x10(%ebp),%eax
  1047f7:	0f b6 00             	movzbl (%eax),%eax
  1047fa:	0f b6 d8             	movzbl %al,%ebx
  1047fd:	83 fb 25             	cmp    $0x25,%ebx
  104800:	0f 95 c0             	setne  %al
  104803:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  104807:	84 c0                	test   %al,%al
  104809:	75 d2                	jne    1047dd <vprintfmt+0x38>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		st.padc = ' ';
  10480b:	c7 45 d4 20 00 00 00 	movl   $0x20,-0x2c(%ebp)
		st.width = -1;
  104812:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		st.prec = -1;
  104819:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		st.signc = -1;
  104820:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		st.flags = 0;
  104827:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		st.base = 10;
  10482e:	c7 45 e8 0a 00 00 00 	movl   $0xa,-0x18(%ebp)
  104835:	eb 04                	jmp    10483b <vprintfmt+0x96>
			goto reswitch;

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
				st.signc = ' ';
			goto reswitch;
  104837:	90                   	nop
  104838:	eb 01                	jmp    10483b <vprintfmt+0x96>
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
				st.width = st.prec;	// then it's a field width
				st.prec = -1;
			}
			goto reswitch;
  10483a:	90                   	nop
		st.signc = -1;
		st.flags = 0;
		st.base = 10;
		uintmax_t num;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  10483b:	8b 45 10             	mov    0x10(%ebp),%eax
  10483e:	0f b6 00             	movzbl (%eax),%eax
  104841:	0f b6 d8             	movzbl %al,%ebx
  104844:	89 d8                	mov    %ebx,%eax
  104846:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  10484a:	83 e8 20             	sub    $0x20,%eax
  10484d:	83 f8 58             	cmp    $0x58,%eax
  104850:	0f 87 ae 02 00 00    	ja     104b04 <vprintfmt+0x35f>
  104856:	8b 04 85 34 63 10 00 	mov    0x106334(,%eax,4),%eax
  10485d:	ff e0                	jmp    *%eax

		// modifier flags
		case '-': // pad on the right instead of the left
			st.flags |= F_RPAD;
  10485f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104862:	83 c8 10             	or     $0x10,%eax
  104865:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
  104868:	eb d1                	jmp    10483b <vprintfmt+0x96>

		case '+': // prefix positive numeric values with a '+' sign
			st.signc = '+';
  10486a:	c7 45 e0 2b 00 00 00 	movl   $0x2b,-0x20(%ebp)
			goto reswitch;
  104871:	eb c8                	jmp    10483b <vprintfmt+0x96>

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
  104873:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104876:	85 c0                	test   %eax,%eax
  104878:	79 bd                	jns    104837 <vprintfmt+0x92>
				st.signc = ' ';
  10487a:	c7 45 e0 20 00 00 00 	movl   $0x20,-0x20(%ebp)
			goto reswitch;
  104881:	eb b4                	jmp    104837 <vprintfmt+0x92>

		// width or precision field
		case '0':
			if (!(st.flags & F_DOT))
  104883:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104886:	83 e0 08             	and    $0x8,%eax
  104889:	85 c0                	test   %eax,%eax
  10488b:	75 07                	jne    104894 <vprintfmt+0xef>
				st.padc = '0'; // pad with 0's instead of spaces
  10488d:	c7 45 d4 30 00 00 00 	movl   $0x30,-0x2c(%ebp)
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  104894:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
				st.prec = st.prec * 10 + ch - '0';
  10489b:	8b 55 dc             	mov    -0x24(%ebp),%edx
  10489e:	89 d0                	mov    %edx,%eax
  1048a0:	c1 e0 02             	shl    $0x2,%eax
  1048a3:	01 d0                	add    %edx,%eax
  1048a5:	01 c0                	add    %eax,%eax
  1048a7:	01 d8                	add    %ebx,%eax
  1048a9:	83 e8 30             	sub    $0x30,%eax
  1048ac:	89 45 dc             	mov    %eax,-0x24(%ebp)
				ch = *fmt;
  1048af:	8b 45 10             	mov    0x10(%ebp),%eax
  1048b2:	0f b6 00             	movzbl (%eax),%eax
  1048b5:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
  1048b8:	83 fb 2f             	cmp    $0x2f,%ebx
  1048bb:	7e 21                	jle    1048de <vprintfmt+0x139>
  1048bd:	83 fb 39             	cmp    $0x39,%ebx
  1048c0:	7f 1c                	jg     1048de <vprintfmt+0x139>
		case '0':
			if (!(st.flags & F_DOT))
				st.padc = '0'; // pad with 0's instead of spaces
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  1048c2:	83 45 10 01          	addl   $0x1,0x10(%ebp)
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  1048c6:	eb d3                	jmp    10489b <vprintfmt+0xf6>
			goto gotprec;

		case '*':
			st.prec = va_arg(ap, int);
  1048c8:	8b 45 14             	mov    0x14(%ebp),%eax
  1048cb:	83 c0 04             	add    $0x4,%eax
  1048ce:	89 45 14             	mov    %eax,0x14(%ebp)
  1048d1:	8b 45 14             	mov    0x14(%ebp),%eax
  1048d4:	83 e8 04             	sub    $0x4,%eax
  1048d7:	8b 00                	mov    (%eax),%eax
  1048d9:	89 45 dc             	mov    %eax,-0x24(%ebp)
  1048dc:	eb 01                	jmp    1048df <vprintfmt+0x13a>
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto gotprec;
  1048de:	90                   	nop

		case '*':
			st.prec = va_arg(ap, int);
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
  1048df:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1048e2:	83 e0 08             	and    $0x8,%eax
  1048e5:	85 c0                	test   %eax,%eax
  1048e7:	0f 85 4d ff ff ff    	jne    10483a <vprintfmt+0x95>
				st.width = st.prec;	// then it's a field width
  1048ed:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1048f0:	89 45 d8             	mov    %eax,-0x28(%ebp)
				st.prec = -1;
  1048f3:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
			}
			goto reswitch;
  1048fa:	e9 3b ff ff ff       	jmp    10483a <vprintfmt+0x95>

		case '.':
			st.flags |= F_DOT;
  1048ff:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104902:	83 c8 08             	or     $0x8,%eax
  104905:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
  104908:	e9 2e ff ff ff       	jmp    10483b <vprintfmt+0x96>

		case '#':
			st.flags |= F_ALT;
  10490d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104910:	83 c8 04             	or     $0x4,%eax
  104913:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
  104916:	e9 20 ff ff ff       	jmp    10483b <vprintfmt+0x96>

		// long flag (doubled for long long)
		case 'l':
			st.flags |= (st.flags & F_L) ? F_LL : F_L;
  10491b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  10491e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104921:	83 e0 01             	and    $0x1,%eax
  104924:	85 c0                	test   %eax,%eax
  104926:	74 07                	je     10492f <vprintfmt+0x18a>
  104928:	b8 02 00 00 00       	mov    $0x2,%eax
  10492d:	eb 05                	jmp    104934 <vprintfmt+0x18f>
  10492f:	b8 01 00 00 00       	mov    $0x1,%eax
  104934:	09 d0                	or     %edx,%eax
  104936:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
  104939:	e9 fd fe ff ff       	jmp    10483b <vprintfmt+0x96>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  10493e:	8b 45 14             	mov    0x14(%ebp),%eax
  104941:	83 c0 04             	add    $0x4,%eax
  104944:	89 45 14             	mov    %eax,0x14(%ebp)
  104947:	8b 45 14             	mov    0x14(%ebp),%eax
  10494a:	83 e8 04             	sub    $0x4,%eax
  10494d:	8b 00                	mov    (%eax),%eax
  10494f:	8b 55 0c             	mov    0xc(%ebp),%edx
  104952:	89 54 24 04          	mov    %edx,0x4(%esp)
  104956:	89 04 24             	mov    %eax,(%esp)
  104959:	8b 45 08             	mov    0x8(%ebp),%eax
  10495c:	ff d0                	call   *%eax
			break;
  10495e:	e9 cc 01 00 00       	jmp    104b2f <vprintfmt+0x38a>

		// string
		case 's': {
			const char *s;
			if ((s = va_arg(ap, char *)) == NULL)
  104963:	8b 45 14             	mov    0x14(%ebp),%eax
  104966:	83 c0 04             	add    $0x4,%eax
  104969:	89 45 14             	mov    %eax,0x14(%ebp)
  10496c:	8b 45 14             	mov    0x14(%ebp),%eax
  10496f:	83 e8 04             	sub    $0x4,%eax
  104972:	8b 00                	mov    (%eax),%eax
  104974:	89 45 ec             	mov    %eax,-0x14(%ebp)
  104977:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  10497b:	75 07                	jne    104984 <vprintfmt+0x1df>
				s = "(null)";
  10497d:	c7 45 ec 2d 63 10 00 	movl   $0x10632d,-0x14(%ebp)
			putstr(&st, s, st.prec);
  104984:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104987:	89 44 24 08          	mov    %eax,0x8(%esp)
  10498b:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10498e:	89 44 24 04          	mov    %eax,0x4(%esp)
  104992:	8d 45 cc             	lea    -0x34(%ebp),%eax
  104995:	89 04 24             	mov    %eax,(%esp)
  104998:	e8 0e fc ff ff       	call   1045ab <putstr>
			break;
  10499d:	e9 8d 01 00 00       	jmp    104b2f <vprintfmt+0x38a>
		    }

		// (signed) decimal
		case 'd':
			num = getint(&st, &ap);
  1049a2:	8d 45 14             	lea    0x14(%ebp),%eax
  1049a5:	89 44 24 04          	mov    %eax,0x4(%esp)
  1049a9:	8d 45 cc             	lea    -0x34(%ebp),%eax
  1049ac:	89 04 24             	mov    %eax,(%esp)
  1049af:	e8 45 fb ff ff       	call   1044f9 <getint>
  1049b4:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1049b7:	89 55 f4             	mov    %edx,-0xc(%ebp)
			if ((intmax_t) num < 0) {
  1049ba:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1049bd:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1049c0:	85 d2                	test   %edx,%edx
  1049c2:	79 1a                	jns    1049de <vprintfmt+0x239>
				num = -(intmax_t) num;
  1049c4:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1049c7:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1049ca:	f7 d8                	neg    %eax
  1049cc:	83 d2 00             	adc    $0x0,%edx
  1049cf:	f7 da                	neg    %edx
  1049d1:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1049d4:	89 55 f4             	mov    %edx,-0xc(%ebp)
				st.signc = '-';
  1049d7:	c7 45 e0 2d 00 00 00 	movl   $0x2d,-0x20(%ebp)
			}
			putint(&st, num, 10);
  1049de:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  1049e5:	00 
  1049e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1049e9:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1049ec:	89 44 24 04          	mov    %eax,0x4(%esp)
  1049f0:	89 54 24 08          	mov    %edx,0x8(%esp)
  1049f4:	8d 45 cc             	lea    -0x34(%ebp),%eax
  1049f7:	89 04 24             	mov    %eax,(%esp)
  1049fa:	e8 3e fd ff ff       	call   10473d <putint>
			break;
  1049ff:	e9 2b 01 00 00       	jmp    104b2f <vprintfmt+0x38a>

		// unsigned decimal
		case 'u':
			putint(&st, getuint(&st, &ap), 10);
  104a04:	8d 45 14             	lea    0x14(%ebp),%eax
  104a07:	89 44 24 04          	mov    %eax,0x4(%esp)
  104a0b:	8d 45 cc             	lea    -0x34(%ebp),%eax
  104a0e:	89 04 24             	mov    %eax,(%esp)
  104a11:	e8 6e fa ff ff       	call   104484 <getuint>
  104a16:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  104a1d:	00 
  104a1e:	89 44 24 04          	mov    %eax,0x4(%esp)
  104a22:	89 54 24 08          	mov    %edx,0x8(%esp)
  104a26:	8d 45 cc             	lea    -0x34(%ebp),%eax
  104a29:	89 04 24             	mov    %eax,(%esp)
  104a2c:	e8 0c fd ff ff       	call   10473d <putint>
			break;
  104a31:	e9 f9 00 00 00       	jmp    104b2f <vprintfmt+0x38a>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putint(&st, getuint(&st, &ap), 8);
  104a36:	8d 45 14             	lea    0x14(%ebp),%eax
  104a39:	89 44 24 04          	mov    %eax,0x4(%esp)
  104a3d:	8d 45 cc             	lea    -0x34(%ebp),%eax
  104a40:	89 04 24             	mov    %eax,(%esp)
  104a43:	e8 3c fa ff ff       	call   104484 <getuint>
  104a48:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  104a4f:	00 
  104a50:	89 44 24 04          	mov    %eax,0x4(%esp)
  104a54:	89 54 24 08          	mov    %edx,0x8(%esp)
  104a58:	8d 45 cc             	lea    -0x34(%ebp),%eax
  104a5b:	89 04 24             	mov    %eax,(%esp)
  104a5e:	e8 da fc ff ff       	call   10473d <putint>
			break;
  104a63:	e9 c7 00 00 00       	jmp    104b2f <vprintfmt+0x38a>

		// (unsigned) hexadecimal
		case 'x':
			putint(&st, getuint(&st, &ap), 16);
  104a68:	8d 45 14             	lea    0x14(%ebp),%eax
  104a6b:	89 44 24 04          	mov    %eax,0x4(%esp)
  104a6f:	8d 45 cc             	lea    -0x34(%ebp),%eax
  104a72:	89 04 24             	mov    %eax,(%esp)
  104a75:	e8 0a fa ff ff       	call   104484 <getuint>
  104a7a:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  104a81:	00 
  104a82:	89 44 24 04          	mov    %eax,0x4(%esp)
  104a86:	89 54 24 08          	mov    %edx,0x8(%esp)
  104a8a:	8d 45 cc             	lea    -0x34(%ebp),%eax
  104a8d:	89 04 24             	mov    %eax,(%esp)
  104a90:	e8 a8 fc ff ff       	call   10473d <putint>
			break;
  104a95:	e9 95 00 00 00       	jmp    104b2f <vprintfmt+0x38a>

		// pointer
		case 'p':
			putch('0', putdat);
  104a9a:	8b 45 0c             	mov    0xc(%ebp),%eax
  104a9d:	89 44 24 04          	mov    %eax,0x4(%esp)
  104aa1:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  104aa8:	8b 45 08             	mov    0x8(%ebp),%eax
  104aab:	ff d0                	call   *%eax
			putch('x', putdat);
  104aad:	8b 45 0c             	mov    0xc(%ebp),%eax
  104ab0:	89 44 24 04          	mov    %eax,0x4(%esp)
  104ab4:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  104abb:	8b 45 08             	mov    0x8(%ebp),%eax
  104abe:	ff d0                	call   *%eax
			putint(&st, (uintptr_t) va_arg(ap, void *), 16);
  104ac0:	8b 45 14             	mov    0x14(%ebp),%eax
  104ac3:	83 c0 04             	add    $0x4,%eax
  104ac6:	89 45 14             	mov    %eax,0x14(%ebp)
  104ac9:	8b 45 14             	mov    0x14(%ebp),%eax
  104acc:	83 e8 04             	sub    $0x4,%eax
  104acf:	8b 00                	mov    (%eax),%eax
  104ad1:	ba 00 00 00 00       	mov    $0x0,%edx
  104ad6:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  104add:	00 
  104ade:	89 44 24 04          	mov    %eax,0x4(%esp)
  104ae2:	89 54 24 08          	mov    %edx,0x8(%esp)
  104ae6:	8d 45 cc             	lea    -0x34(%ebp),%eax
  104ae9:	89 04 24             	mov    %eax,(%esp)
  104aec:	e8 4c fc ff ff       	call   10473d <putint>
			break;
  104af1:	eb 3c                	jmp    104b2f <vprintfmt+0x38a>
		    }
#endif	// ! PIOS_KERNEL

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  104af3:	8b 45 0c             	mov    0xc(%ebp),%eax
  104af6:	89 44 24 04          	mov    %eax,0x4(%esp)
  104afa:	89 1c 24             	mov    %ebx,(%esp)
  104afd:	8b 45 08             	mov    0x8(%ebp),%eax
  104b00:	ff d0                	call   *%eax
			break;
  104b02:	eb 2b                	jmp    104b2f <vprintfmt+0x38a>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  104b04:	8b 45 0c             	mov    0xc(%ebp),%eax
  104b07:	89 44 24 04          	mov    %eax,0x4(%esp)
  104b0b:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  104b12:	8b 45 08             	mov    0x8(%ebp),%eax
  104b15:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
  104b17:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  104b1b:	eb 04                	jmp    104b21 <vprintfmt+0x37c>
  104b1d:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  104b21:	8b 45 10             	mov    0x10(%ebp),%eax
  104b24:	83 e8 01             	sub    $0x1,%eax
  104b27:	0f b6 00             	movzbl (%eax),%eax
  104b2a:	3c 25                	cmp    $0x25,%al
  104b2c:	75 ef                	jne    104b1d <vprintfmt+0x378>
				/* do nothing */;
			break;
  104b2e:	90                   	nop
		}
	}
  104b2f:	90                   	nop
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  104b30:	e9 bf fc ff ff       	jmp    1047f4 <vprintfmt+0x4f>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
  104b35:	83 c4 44             	add    $0x44,%esp
  104b38:	5b                   	pop    %ebx
  104b39:	5d                   	pop    %ebp
  104b3a:	c3                   	ret    
  104b3b:	90                   	nop

00104b3c <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  104b3c:	55                   	push   %ebp
  104b3d:	89 e5                	mov    %esp,%ebp
  104b3f:	83 ec 18             	sub    $0x18,%esp
	b->buf[b->idx++] = ch;
  104b42:	8b 45 0c             	mov    0xc(%ebp),%eax
  104b45:	8b 00                	mov    (%eax),%eax
  104b47:	8b 55 08             	mov    0x8(%ebp),%edx
  104b4a:	89 d1                	mov    %edx,%ecx
  104b4c:	8b 55 0c             	mov    0xc(%ebp),%edx
  104b4f:	88 4c 02 08          	mov    %cl,0x8(%edx,%eax,1)
  104b53:	8d 50 01             	lea    0x1(%eax),%edx
  104b56:	8b 45 0c             	mov    0xc(%ebp),%eax
  104b59:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
  104b5b:	8b 45 0c             	mov    0xc(%ebp),%eax
  104b5e:	8b 00                	mov    (%eax),%eax
  104b60:	3d ff 00 00 00       	cmp    $0xff,%eax
  104b65:	75 24                	jne    104b8b <putch+0x4f>
		b->buf[b->idx] = 0;
  104b67:	8b 45 0c             	mov    0xc(%ebp),%eax
  104b6a:	8b 00                	mov    (%eax),%eax
  104b6c:	8b 55 0c             	mov    0xc(%ebp),%edx
  104b6f:	c6 44 02 08 00       	movb   $0x0,0x8(%edx,%eax,1)
		cputs(b->buf);
  104b74:	8b 45 0c             	mov    0xc(%ebp),%eax
  104b77:	83 c0 08             	add    $0x8,%eax
  104b7a:	89 04 24             	mov    %eax,(%esp)
  104b7d:	e8 b2 b8 ff ff       	call   100434 <cputs>
		b->idx = 0;
  104b82:	8b 45 0c             	mov    0xc(%ebp),%eax
  104b85:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
  104b8b:	8b 45 0c             	mov    0xc(%ebp),%eax
  104b8e:	8b 40 04             	mov    0x4(%eax),%eax
  104b91:	8d 50 01             	lea    0x1(%eax),%edx
  104b94:	8b 45 0c             	mov    0xc(%ebp),%eax
  104b97:	89 50 04             	mov    %edx,0x4(%eax)
}
  104b9a:	c9                   	leave  
  104b9b:	c3                   	ret    

00104b9c <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  104b9c:	55                   	push   %ebp
  104b9d:	89 e5                	mov    %esp,%ebp
  104b9f:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  104ba5:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  104bac:	00 00 00 
	b.cnt = 0;
  104baf:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  104bb6:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  104bb9:	8b 45 0c             	mov    0xc(%ebp),%eax
  104bbc:	89 44 24 0c          	mov    %eax,0xc(%esp)
  104bc0:	8b 45 08             	mov    0x8(%ebp),%eax
  104bc3:	89 44 24 08          	mov    %eax,0x8(%esp)
  104bc7:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  104bcd:	89 44 24 04          	mov    %eax,0x4(%esp)
  104bd1:	c7 04 24 3c 4b 10 00 	movl   $0x104b3c,(%esp)
  104bd8:	e8 c8 fb ff ff       	call   1047a5 <vprintfmt>

	b.buf[b.idx] = 0;
  104bdd:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  104be3:	c6 84 05 f8 fe ff ff 	movb   $0x0,-0x108(%ebp,%eax,1)
  104bea:	00 
	cputs(b.buf);
  104beb:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  104bf1:	83 c0 08             	add    $0x8,%eax
  104bf4:	89 04 24             	mov    %eax,(%esp)
  104bf7:	e8 38 b8 ff ff       	call   100434 <cputs>

	return b.cnt;
  104bfc:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
}
  104c02:	c9                   	leave  
  104c03:	c3                   	ret    

00104c04 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  104c04:	55                   	push   %ebp
  104c05:	89 e5                	mov    %esp,%ebp
  104c07:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  104c0a:	8d 45 0c             	lea    0xc(%ebp),%eax
  104c0d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cnt = vcprintf(fmt, ap);
  104c10:	8b 45 08             	mov    0x8(%ebp),%eax
  104c13:	8b 55 f4             	mov    -0xc(%ebp),%edx
  104c16:	89 54 24 04          	mov    %edx,0x4(%esp)
  104c1a:	89 04 24             	mov    %eax,(%esp)
  104c1d:	e8 7a ff ff ff       	call   104b9c <vcprintf>
  104c22:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return cnt;
  104c25:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  104c28:	c9                   	leave  
  104c29:	c3                   	ret    
  104c2a:	90                   	nop
  104c2b:	90                   	nop

00104c2c <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  104c2c:	55                   	push   %ebp
  104c2d:	89 e5                	mov    %esp,%ebp
  104c2f:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
  104c32:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  104c39:	eb 08                	jmp    104c43 <strlen+0x17>
		n++;
  104c3b:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  104c3f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  104c43:	8b 45 08             	mov    0x8(%ebp),%eax
  104c46:	0f b6 00             	movzbl (%eax),%eax
  104c49:	84 c0                	test   %al,%al
  104c4b:	75 ee                	jne    104c3b <strlen+0xf>
		n++;
	return n;
  104c4d:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  104c50:	c9                   	leave  
  104c51:	c3                   	ret    

00104c52 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  104c52:	55                   	push   %ebp
  104c53:	89 e5                	mov    %esp,%ebp
  104c55:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
  104c58:	8b 45 08             	mov    0x8(%ebp),%eax
  104c5b:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
  104c5e:	90                   	nop
  104c5f:	8b 45 0c             	mov    0xc(%ebp),%eax
  104c62:	0f b6 10             	movzbl (%eax),%edx
  104c65:	8b 45 08             	mov    0x8(%ebp),%eax
  104c68:	88 10                	mov    %dl,(%eax)
  104c6a:	8b 45 08             	mov    0x8(%ebp),%eax
  104c6d:	0f b6 00             	movzbl (%eax),%eax
  104c70:	84 c0                	test   %al,%al
  104c72:	0f 95 c0             	setne  %al
  104c75:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  104c79:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  104c7d:	84 c0                	test   %al,%al
  104c7f:	75 de                	jne    104c5f <strcpy+0xd>
		/* do nothing */;
	return ret;
  104c81:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  104c84:	c9                   	leave  
  104c85:	c3                   	ret    

00104c86 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
  104c86:	55                   	push   %ebp
  104c87:	89 e5                	mov    %esp,%ebp
  104c89:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
  104c8c:	8b 45 08             	mov    0x8(%ebp),%eax
  104c8f:	89 45 f8             	mov    %eax,-0x8(%ebp)
	for (i = 0; i < size; i++) {
  104c92:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  104c99:	eb 21                	jmp    104cbc <strncpy+0x36>
		*dst++ = *src;
  104c9b:	8b 45 0c             	mov    0xc(%ebp),%eax
  104c9e:	0f b6 10             	movzbl (%eax),%edx
  104ca1:	8b 45 08             	mov    0x8(%ebp),%eax
  104ca4:	88 10                	mov    %dl,(%eax)
  104ca6:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
  104caa:	8b 45 0c             	mov    0xc(%ebp),%eax
  104cad:	0f b6 00             	movzbl (%eax),%eax
  104cb0:	84 c0                	test   %al,%al
  104cb2:	74 04                	je     104cb8 <strncpy+0x32>
			src++;
  104cb4:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  104cb8:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  104cbc:	8b 45 fc             	mov    -0x4(%ebp),%eax
  104cbf:	3b 45 10             	cmp    0x10(%ebp),%eax
  104cc2:	72 d7                	jb     104c9b <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
  104cc4:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
  104cc7:	c9                   	leave  
  104cc8:	c3                   	ret    

00104cc9 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  104cc9:	55                   	push   %ebp
  104cca:	89 e5                	mov    %esp,%ebp
  104ccc:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
  104ccf:	8b 45 08             	mov    0x8(%ebp),%eax
  104cd2:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
  104cd5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  104cd9:	74 2f                	je     104d0a <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
  104cdb:	eb 13                	jmp    104cf0 <strlcpy+0x27>
			*dst++ = *src++;
  104cdd:	8b 45 0c             	mov    0xc(%ebp),%eax
  104ce0:	0f b6 10             	movzbl (%eax),%edx
  104ce3:	8b 45 08             	mov    0x8(%ebp),%eax
  104ce6:	88 10                	mov    %dl,(%eax)
  104ce8:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  104cec:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  104cf0:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  104cf4:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  104cf8:	74 0a                	je     104d04 <strlcpy+0x3b>
  104cfa:	8b 45 0c             	mov    0xc(%ebp),%eax
  104cfd:	0f b6 00             	movzbl (%eax),%eax
  104d00:	84 c0                	test   %al,%al
  104d02:	75 d9                	jne    104cdd <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
  104d04:	8b 45 08             	mov    0x8(%ebp),%eax
  104d07:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  104d0a:	8b 55 08             	mov    0x8(%ebp),%edx
  104d0d:	8b 45 fc             	mov    -0x4(%ebp),%eax
  104d10:	89 d1                	mov    %edx,%ecx
  104d12:	29 c1                	sub    %eax,%ecx
  104d14:	89 c8                	mov    %ecx,%eax
}
  104d16:	c9                   	leave  
  104d17:	c3                   	ret    

00104d18 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  104d18:	55                   	push   %ebp
  104d19:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
  104d1b:	eb 08                	jmp    104d25 <strcmp+0xd>
		p++, q++;
  104d1d:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  104d21:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  104d25:	8b 45 08             	mov    0x8(%ebp),%eax
  104d28:	0f b6 00             	movzbl (%eax),%eax
  104d2b:	84 c0                	test   %al,%al
  104d2d:	74 10                	je     104d3f <strcmp+0x27>
  104d2f:	8b 45 08             	mov    0x8(%ebp),%eax
  104d32:	0f b6 10             	movzbl (%eax),%edx
  104d35:	8b 45 0c             	mov    0xc(%ebp),%eax
  104d38:	0f b6 00             	movzbl (%eax),%eax
  104d3b:	38 c2                	cmp    %al,%dl
  104d3d:	74 de                	je     104d1d <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  104d3f:	8b 45 08             	mov    0x8(%ebp),%eax
  104d42:	0f b6 00             	movzbl (%eax),%eax
  104d45:	0f b6 d0             	movzbl %al,%edx
  104d48:	8b 45 0c             	mov    0xc(%ebp),%eax
  104d4b:	0f b6 00             	movzbl (%eax),%eax
  104d4e:	0f b6 c0             	movzbl %al,%eax
  104d51:	89 d1                	mov    %edx,%ecx
  104d53:	29 c1                	sub    %eax,%ecx
  104d55:	89 c8                	mov    %ecx,%eax
}
  104d57:	5d                   	pop    %ebp
  104d58:	c3                   	ret    

00104d59 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  104d59:	55                   	push   %ebp
  104d5a:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
  104d5c:	eb 0c                	jmp    104d6a <strncmp+0x11>
		n--, p++, q++;
  104d5e:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  104d62:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  104d66:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  104d6a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  104d6e:	74 1a                	je     104d8a <strncmp+0x31>
  104d70:	8b 45 08             	mov    0x8(%ebp),%eax
  104d73:	0f b6 00             	movzbl (%eax),%eax
  104d76:	84 c0                	test   %al,%al
  104d78:	74 10                	je     104d8a <strncmp+0x31>
  104d7a:	8b 45 08             	mov    0x8(%ebp),%eax
  104d7d:	0f b6 10             	movzbl (%eax),%edx
  104d80:	8b 45 0c             	mov    0xc(%ebp),%eax
  104d83:	0f b6 00             	movzbl (%eax),%eax
  104d86:	38 c2                	cmp    %al,%dl
  104d88:	74 d4                	je     104d5e <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
  104d8a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  104d8e:	75 07                	jne    104d97 <strncmp+0x3e>
		return 0;
  104d90:	b8 00 00 00 00       	mov    $0x0,%eax
  104d95:	eb 18                	jmp    104daf <strncmp+0x56>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  104d97:	8b 45 08             	mov    0x8(%ebp),%eax
  104d9a:	0f b6 00             	movzbl (%eax),%eax
  104d9d:	0f b6 d0             	movzbl %al,%edx
  104da0:	8b 45 0c             	mov    0xc(%ebp),%eax
  104da3:	0f b6 00             	movzbl (%eax),%eax
  104da6:	0f b6 c0             	movzbl %al,%eax
  104da9:	89 d1                	mov    %edx,%ecx
  104dab:	29 c1                	sub    %eax,%ecx
  104dad:	89 c8                	mov    %ecx,%eax
}
  104daf:	5d                   	pop    %ebp
  104db0:	c3                   	ret    

00104db1 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  104db1:	55                   	push   %ebp
  104db2:	89 e5                	mov    %esp,%ebp
  104db4:	83 ec 04             	sub    $0x4,%esp
  104db7:	8b 45 0c             	mov    0xc(%ebp),%eax
  104dba:	88 45 fc             	mov    %al,-0x4(%ebp)
	while (*s != c)
  104dbd:	eb 1a                	jmp    104dd9 <strchr+0x28>
		if (*s++ == 0)
  104dbf:	8b 45 08             	mov    0x8(%ebp),%eax
  104dc2:	0f b6 00             	movzbl (%eax),%eax
  104dc5:	84 c0                	test   %al,%al
  104dc7:	0f 94 c0             	sete   %al
  104dca:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  104dce:	84 c0                	test   %al,%al
  104dd0:	74 07                	je     104dd9 <strchr+0x28>
			return NULL;
  104dd2:	b8 00 00 00 00       	mov    $0x0,%eax
  104dd7:	eb 0e                	jmp    104de7 <strchr+0x36>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	while (*s != c)
  104dd9:	8b 45 08             	mov    0x8(%ebp),%eax
  104ddc:	0f b6 00             	movzbl (%eax),%eax
  104ddf:	3a 45 fc             	cmp    -0x4(%ebp),%al
  104de2:	75 db                	jne    104dbf <strchr+0xe>
		if (*s++ == 0)
			return NULL;
	return (char *) s;
  104de4:	8b 45 08             	mov    0x8(%ebp),%eax
}
  104de7:	c9                   	leave  
  104de8:	c3                   	ret    

00104de9 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  104de9:	55                   	push   %ebp
  104dea:	89 e5                	mov    %esp,%ebp
  104dec:	57                   	push   %edi
	char *p;

	if (n == 0)
  104ded:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  104df1:	75 05                	jne    104df8 <memset+0xf>
		return v;
  104df3:	8b 45 08             	mov    0x8(%ebp),%eax
  104df6:	eb 5c                	jmp    104e54 <memset+0x6b>
	if ((int)v%4 == 0 && n%4 == 0) {
  104df8:	8b 45 08             	mov    0x8(%ebp),%eax
  104dfb:	83 e0 03             	and    $0x3,%eax
  104dfe:	85 c0                	test   %eax,%eax
  104e00:	75 41                	jne    104e43 <memset+0x5a>
  104e02:	8b 45 10             	mov    0x10(%ebp),%eax
  104e05:	83 e0 03             	and    $0x3,%eax
  104e08:	85 c0                	test   %eax,%eax
  104e0a:	75 37                	jne    104e43 <memset+0x5a>
		c &= 0xFF;
  104e0c:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
  104e13:	8b 45 0c             	mov    0xc(%ebp),%eax
  104e16:	89 c2                	mov    %eax,%edx
  104e18:	c1 e2 18             	shl    $0x18,%edx
  104e1b:	8b 45 0c             	mov    0xc(%ebp),%eax
  104e1e:	c1 e0 10             	shl    $0x10,%eax
  104e21:	09 c2                	or     %eax,%edx
  104e23:	8b 45 0c             	mov    0xc(%ebp),%eax
  104e26:	c1 e0 08             	shl    $0x8,%eax
  104e29:	09 d0                	or     %edx,%eax
  104e2b:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  104e2e:	8b 45 10             	mov    0x10(%ebp),%eax
  104e31:	89 c1                	mov    %eax,%ecx
  104e33:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  104e36:	8b 55 08             	mov    0x8(%ebp),%edx
  104e39:	8b 45 0c             	mov    0xc(%ebp),%eax
  104e3c:	89 d7                	mov    %edx,%edi
  104e3e:	fc                   	cld    
  104e3f:	f3 ab                	rep stos %eax,%es:(%edi)
  104e41:	eb 0e                	jmp    104e51 <memset+0x68>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  104e43:	8b 55 08             	mov    0x8(%ebp),%edx
  104e46:	8b 45 0c             	mov    0xc(%ebp),%eax
  104e49:	8b 4d 10             	mov    0x10(%ebp),%ecx
  104e4c:	89 d7                	mov    %edx,%edi
  104e4e:	fc                   	cld    
  104e4f:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
  104e51:	8b 45 08             	mov    0x8(%ebp),%eax
}
  104e54:	5f                   	pop    %edi
  104e55:	5d                   	pop    %ebp
  104e56:	c3                   	ret    

00104e57 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  104e57:	55                   	push   %ebp
  104e58:	89 e5                	mov    %esp,%ebp
  104e5a:	57                   	push   %edi
  104e5b:	56                   	push   %esi
  104e5c:	53                   	push   %ebx
  104e5d:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
  104e60:	8b 45 0c             	mov    0xc(%ebp),%eax
  104e63:	89 45 f0             	mov    %eax,-0x10(%ebp)
	d = dst;
  104e66:	8b 45 08             	mov    0x8(%ebp),%eax
  104e69:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (s < d && s + n > d) {
  104e6c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104e6f:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  104e72:	73 6d                	jae    104ee1 <memmove+0x8a>
  104e74:	8b 45 10             	mov    0x10(%ebp),%eax
  104e77:	8b 55 f0             	mov    -0x10(%ebp),%edx
  104e7a:	01 d0                	add    %edx,%eax
  104e7c:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  104e7f:	76 60                	jbe    104ee1 <memmove+0x8a>
		s += n;
  104e81:	8b 45 10             	mov    0x10(%ebp),%eax
  104e84:	01 45 f0             	add    %eax,-0x10(%ebp)
		d += n;
  104e87:	8b 45 10             	mov    0x10(%ebp),%eax
  104e8a:	01 45 ec             	add    %eax,-0x14(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  104e8d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104e90:	83 e0 03             	and    $0x3,%eax
  104e93:	85 c0                	test   %eax,%eax
  104e95:	75 2f                	jne    104ec6 <memmove+0x6f>
  104e97:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104e9a:	83 e0 03             	and    $0x3,%eax
  104e9d:	85 c0                	test   %eax,%eax
  104e9f:	75 25                	jne    104ec6 <memmove+0x6f>
  104ea1:	8b 45 10             	mov    0x10(%ebp),%eax
  104ea4:	83 e0 03             	and    $0x3,%eax
  104ea7:	85 c0                	test   %eax,%eax
  104ea9:	75 1b                	jne    104ec6 <memmove+0x6f>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  104eab:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104eae:	83 e8 04             	sub    $0x4,%eax
  104eb1:	8b 55 f0             	mov    -0x10(%ebp),%edx
  104eb4:	83 ea 04             	sub    $0x4,%edx
  104eb7:	8b 4d 10             	mov    0x10(%ebp),%ecx
  104eba:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  104ebd:	89 c7                	mov    %eax,%edi
  104ebf:	89 d6                	mov    %edx,%esi
  104ec1:	fd                   	std    
  104ec2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  104ec4:	eb 18                	jmp    104ede <memmove+0x87>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  104ec6:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104ec9:	8d 50 ff             	lea    -0x1(%eax),%edx
  104ecc:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104ecf:	8d 58 ff             	lea    -0x1(%eax),%ebx
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  104ed2:	8b 45 10             	mov    0x10(%ebp),%eax
  104ed5:	89 d7                	mov    %edx,%edi
  104ed7:	89 de                	mov    %ebx,%esi
  104ed9:	89 c1                	mov    %eax,%ecx
  104edb:	fd                   	std    
  104edc:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  104ede:	fc                   	cld    
  104edf:	eb 45                	jmp    104f26 <memmove+0xcf>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  104ee1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104ee4:	83 e0 03             	and    $0x3,%eax
  104ee7:	85 c0                	test   %eax,%eax
  104ee9:	75 2b                	jne    104f16 <memmove+0xbf>
  104eeb:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104eee:	83 e0 03             	and    $0x3,%eax
  104ef1:	85 c0                	test   %eax,%eax
  104ef3:	75 21                	jne    104f16 <memmove+0xbf>
  104ef5:	8b 45 10             	mov    0x10(%ebp),%eax
  104ef8:	83 e0 03             	and    $0x3,%eax
  104efb:	85 c0                	test   %eax,%eax
  104efd:	75 17                	jne    104f16 <memmove+0xbf>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  104eff:	8b 45 10             	mov    0x10(%ebp),%eax
  104f02:	89 c1                	mov    %eax,%ecx
  104f04:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  104f07:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104f0a:	8b 55 f0             	mov    -0x10(%ebp),%edx
  104f0d:	89 c7                	mov    %eax,%edi
  104f0f:	89 d6                	mov    %edx,%esi
  104f11:	fc                   	cld    
  104f12:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  104f14:	eb 10                	jmp    104f26 <memmove+0xcf>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  104f16:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104f19:	8b 55 f0             	mov    -0x10(%ebp),%edx
  104f1c:	8b 4d 10             	mov    0x10(%ebp),%ecx
  104f1f:	89 c7                	mov    %eax,%edi
  104f21:	89 d6                	mov    %edx,%esi
  104f23:	fc                   	cld    
  104f24:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
  104f26:	8b 45 08             	mov    0x8(%ebp),%eax
}
  104f29:	83 c4 10             	add    $0x10,%esp
  104f2c:	5b                   	pop    %ebx
  104f2d:	5e                   	pop    %esi
  104f2e:	5f                   	pop    %edi
  104f2f:	5d                   	pop    %ebp
  104f30:	c3                   	ret    

00104f31 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  104f31:	55                   	push   %ebp
  104f32:	89 e5                	mov    %esp,%ebp
  104f34:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  104f37:	8b 45 10             	mov    0x10(%ebp),%eax
  104f3a:	89 44 24 08          	mov    %eax,0x8(%esp)
  104f3e:	8b 45 0c             	mov    0xc(%ebp),%eax
  104f41:	89 44 24 04          	mov    %eax,0x4(%esp)
  104f45:	8b 45 08             	mov    0x8(%ebp),%eax
  104f48:	89 04 24             	mov    %eax,(%esp)
  104f4b:	e8 07 ff ff ff       	call   104e57 <memmove>
}
  104f50:	c9                   	leave  
  104f51:	c3                   	ret    

00104f52 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  104f52:	55                   	push   %ebp
  104f53:	89 e5                	mov    %esp,%ebp
  104f55:	83 ec 10             	sub    $0x10,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
  104f58:	8b 45 08             	mov    0x8(%ebp),%eax
  104f5b:	89 45 fc             	mov    %eax,-0x4(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
  104f5e:	8b 45 0c             	mov    0xc(%ebp),%eax
  104f61:	89 45 f8             	mov    %eax,-0x8(%ebp)

	while (n-- > 0) {
  104f64:	eb 32                	jmp    104f98 <memcmp+0x46>
		if (*s1 != *s2)
  104f66:	8b 45 fc             	mov    -0x4(%ebp),%eax
  104f69:	0f b6 10             	movzbl (%eax),%edx
  104f6c:	8b 45 f8             	mov    -0x8(%ebp),%eax
  104f6f:	0f b6 00             	movzbl (%eax),%eax
  104f72:	38 c2                	cmp    %al,%dl
  104f74:	74 1a                	je     104f90 <memcmp+0x3e>
			return (int) *s1 - (int) *s2;
  104f76:	8b 45 fc             	mov    -0x4(%ebp),%eax
  104f79:	0f b6 00             	movzbl (%eax),%eax
  104f7c:	0f b6 d0             	movzbl %al,%edx
  104f7f:	8b 45 f8             	mov    -0x8(%ebp),%eax
  104f82:	0f b6 00             	movzbl (%eax),%eax
  104f85:	0f b6 c0             	movzbl %al,%eax
  104f88:	89 d1                	mov    %edx,%ecx
  104f8a:	29 c1                	sub    %eax,%ecx
  104f8c:	89 c8                	mov    %ecx,%eax
  104f8e:	eb 1c                	jmp    104fac <memcmp+0x5a>
		s1++, s2++;
  104f90:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  104f94:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  104f98:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  104f9c:	0f 95 c0             	setne  %al
  104f9f:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  104fa3:	84 c0                	test   %al,%al
  104fa5:	75 bf                	jne    104f66 <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  104fa7:	b8 00 00 00 00       	mov    $0x0,%eax
}
  104fac:	c9                   	leave  
  104fad:	c3                   	ret    

00104fae <memchr>:

void *
memchr(const void *s, int c, size_t n)
{
  104fae:	55                   	push   %ebp
  104faf:	89 e5                	mov    %esp,%ebp
  104fb1:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
  104fb4:	8b 45 10             	mov    0x10(%ebp),%eax
  104fb7:	8b 55 08             	mov    0x8(%ebp),%edx
  104fba:	01 d0                	add    %edx,%eax
  104fbc:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
  104fbf:	eb 16                	jmp    104fd7 <memchr+0x29>
		if (*(const unsigned char *) s == (unsigned char) c)
  104fc1:	8b 45 08             	mov    0x8(%ebp),%eax
  104fc4:	0f b6 10             	movzbl (%eax),%edx
  104fc7:	8b 45 0c             	mov    0xc(%ebp),%eax
  104fca:	38 c2                	cmp    %al,%dl
  104fcc:	75 05                	jne    104fd3 <memchr+0x25>
			return (void *) s;
  104fce:	8b 45 08             	mov    0x8(%ebp),%eax
  104fd1:	eb 11                	jmp    104fe4 <memchr+0x36>

void *
memchr(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  104fd3:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  104fd7:	8b 45 08             	mov    0x8(%ebp),%eax
  104fda:	3b 45 fc             	cmp    -0x4(%ebp),%eax
  104fdd:	72 e2                	jb     104fc1 <memchr+0x13>
		if (*(const unsigned char *) s == (unsigned char) c)
			return (void *) s;
	return NULL;
  104fdf:	b8 00 00 00 00       	mov    $0x0,%eax
}
  104fe4:	c9                   	leave  
  104fe5:	c3                   	ret    
  104fe6:	90                   	nop
  104fe7:	90                   	nop
  104fe8:	90                   	nop
  104fe9:	90                   	nop
  104fea:	90                   	nop
  104feb:	90                   	nop
  104fec:	90                   	nop
  104fed:	90                   	nop
  104fee:	90                   	nop
  104fef:	90                   	nop

00104ff0 <__udivdi3>:
  104ff0:	83 ec 1c             	sub    $0x1c,%esp
  104ff3:	8b 44 24 2c          	mov    0x2c(%esp),%eax
  104ff7:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  104ffb:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  104fff:	8b 6c 24 20          	mov    0x20(%esp),%ebp
  105003:	89 74 24 10          	mov    %esi,0x10(%esp)
  105007:	8b 74 24 24          	mov    0x24(%esp),%esi
  10500b:	85 c0                	test   %eax,%eax
  10500d:	89 7c 24 14          	mov    %edi,0x14(%esp)
  105011:	89 cf                	mov    %ecx,%edi
  105013:	89 6c 24 04          	mov    %ebp,0x4(%esp)
  105017:	75 37                	jne    105050 <__udivdi3+0x60>
  105019:	39 f1                	cmp    %esi,%ecx
  10501b:	77 73                	ja     105090 <__udivdi3+0xa0>
  10501d:	85 c9                	test   %ecx,%ecx
  10501f:	75 0b                	jne    10502c <__udivdi3+0x3c>
  105021:	b8 01 00 00 00       	mov    $0x1,%eax
  105026:	31 d2                	xor    %edx,%edx
  105028:	f7 f1                	div    %ecx
  10502a:	89 c1                	mov    %eax,%ecx
  10502c:	89 f0                	mov    %esi,%eax
  10502e:	31 d2                	xor    %edx,%edx
  105030:	f7 f1                	div    %ecx
  105032:	89 c6                	mov    %eax,%esi
  105034:	89 e8                	mov    %ebp,%eax
  105036:	f7 f1                	div    %ecx
  105038:	89 f2                	mov    %esi,%edx
  10503a:	8b 74 24 10          	mov    0x10(%esp),%esi
  10503e:	8b 7c 24 14          	mov    0x14(%esp),%edi
  105042:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  105046:	83 c4 1c             	add    $0x1c,%esp
  105049:	c3                   	ret    
  10504a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  105050:	39 f0                	cmp    %esi,%eax
  105052:	77 24                	ja     105078 <__udivdi3+0x88>
  105054:	0f bd e8             	bsr    %eax,%ebp
  105057:	83 f5 1f             	xor    $0x1f,%ebp
  10505a:	75 4c                	jne    1050a8 <__udivdi3+0xb8>
  10505c:	31 d2                	xor    %edx,%edx
  10505e:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
  105062:	0f 86 b0 00 00 00    	jbe    105118 <__udivdi3+0x128>
  105068:	39 f0                	cmp    %esi,%eax
  10506a:	0f 82 a8 00 00 00    	jb     105118 <__udivdi3+0x128>
  105070:	31 c0                	xor    %eax,%eax
  105072:	eb c6                	jmp    10503a <__udivdi3+0x4a>
  105074:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  105078:	31 d2                	xor    %edx,%edx
  10507a:	31 c0                	xor    %eax,%eax
  10507c:	8b 74 24 10          	mov    0x10(%esp),%esi
  105080:	8b 7c 24 14          	mov    0x14(%esp),%edi
  105084:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  105088:	83 c4 1c             	add    $0x1c,%esp
  10508b:	c3                   	ret    
  10508c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  105090:	89 e8                	mov    %ebp,%eax
  105092:	89 f2                	mov    %esi,%edx
  105094:	f7 f1                	div    %ecx
  105096:	31 d2                	xor    %edx,%edx
  105098:	8b 74 24 10          	mov    0x10(%esp),%esi
  10509c:	8b 7c 24 14          	mov    0x14(%esp),%edi
  1050a0:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  1050a4:	83 c4 1c             	add    $0x1c,%esp
  1050a7:	c3                   	ret    
  1050a8:	89 e9                	mov    %ebp,%ecx
  1050aa:	89 fa                	mov    %edi,%edx
  1050ac:	d3 e0                	shl    %cl,%eax
  1050ae:	89 44 24 08          	mov    %eax,0x8(%esp)
  1050b2:	b8 20 00 00 00       	mov    $0x20,%eax
  1050b7:	29 e8                	sub    %ebp,%eax
  1050b9:	89 c1                	mov    %eax,%ecx
  1050bb:	d3 ea                	shr    %cl,%edx
  1050bd:	8b 4c 24 08          	mov    0x8(%esp),%ecx
  1050c1:	09 ca                	or     %ecx,%edx
  1050c3:	89 e9                	mov    %ebp,%ecx
  1050c5:	d3 e7                	shl    %cl,%edi
  1050c7:	89 c1                	mov    %eax,%ecx
  1050c9:	89 54 24 0c          	mov    %edx,0xc(%esp)
  1050cd:	89 f2                	mov    %esi,%edx
  1050cf:	d3 ea                	shr    %cl,%edx
  1050d1:	89 e9                	mov    %ebp,%ecx
  1050d3:	89 14 24             	mov    %edx,(%esp)
  1050d6:	8b 54 24 04          	mov    0x4(%esp),%edx
  1050da:	d3 e6                	shl    %cl,%esi
  1050dc:	89 c1                	mov    %eax,%ecx
  1050de:	d3 ea                	shr    %cl,%edx
  1050e0:	89 d0                	mov    %edx,%eax
  1050e2:	09 f0                	or     %esi,%eax
  1050e4:	8b 34 24             	mov    (%esp),%esi
  1050e7:	89 f2                	mov    %esi,%edx
  1050e9:	f7 74 24 0c          	divl   0xc(%esp)
  1050ed:	89 d6                	mov    %edx,%esi
  1050ef:	89 44 24 08          	mov    %eax,0x8(%esp)
  1050f3:	f7 e7                	mul    %edi
  1050f5:	39 d6                	cmp    %edx,%esi
  1050f7:	72 2f                	jb     105128 <__udivdi3+0x138>
  1050f9:	8b 7c 24 04          	mov    0x4(%esp),%edi
  1050fd:	89 e9                	mov    %ebp,%ecx
  1050ff:	d3 e7                	shl    %cl,%edi
  105101:	39 c7                	cmp    %eax,%edi
  105103:	73 04                	jae    105109 <__udivdi3+0x119>
  105105:	39 d6                	cmp    %edx,%esi
  105107:	74 1f                	je     105128 <__udivdi3+0x138>
  105109:	8b 44 24 08          	mov    0x8(%esp),%eax
  10510d:	31 d2                	xor    %edx,%edx
  10510f:	e9 26 ff ff ff       	jmp    10503a <__udivdi3+0x4a>
  105114:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  105118:	b8 01 00 00 00       	mov    $0x1,%eax
  10511d:	e9 18 ff ff ff       	jmp    10503a <__udivdi3+0x4a>
  105122:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  105128:	8b 44 24 08          	mov    0x8(%esp),%eax
  10512c:	31 d2                	xor    %edx,%edx
  10512e:	83 e8 01             	sub    $0x1,%eax
  105131:	8b 74 24 10          	mov    0x10(%esp),%esi
  105135:	8b 7c 24 14          	mov    0x14(%esp),%edi
  105139:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  10513d:	83 c4 1c             	add    $0x1c,%esp
  105140:	c3                   	ret    
  105141:	90                   	nop
  105142:	90                   	nop
  105143:	90                   	nop
  105144:	90                   	nop
  105145:	90                   	nop
  105146:	90                   	nop
  105147:	90                   	nop
  105148:	90                   	nop
  105149:	90                   	nop
  10514a:	90                   	nop
  10514b:	90                   	nop
  10514c:	90                   	nop
  10514d:	90                   	nop
  10514e:	90                   	nop
  10514f:	90                   	nop

00105150 <__umoddi3>:
  105150:	83 ec 1c             	sub    $0x1c,%esp
  105153:	8b 54 24 2c          	mov    0x2c(%esp),%edx
  105157:	8b 44 24 20          	mov    0x20(%esp),%eax
  10515b:	89 74 24 10          	mov    %esi,0x10(%esp)
  10515f:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  105163:	8b 74 24 24          	mov    0x24(%esp),%esi
  105167:	85 d2                	test   %edx,%edx
  105169:	89 7c 24 14          	mov    %edi,0x14(%esp)
  10516d:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  105171:	89 cf                	mov    %ecx,%edi
  105173:	89 c5                	mov    %eax,%ebp
  105175:	89 44 24 08          	mov    %eax,0x8(%esp)
  105179:	89 34 24             	mov    %esi,(%esp)
  10517c:	75 22                	jne    1051a0 <__umoddi3+0x50>
  10517e:	39 f1                	cmp    %esi,%ecx
  105180:	76 56                	jbe    1051d8 <__umoddi3+0x88>
  105182:	89 f2                	mov    %esi,%edx
  105184:	f7 f1                	div    %ecx
  105186:	89 d0                	mov    %edx,%eax
  105188:	31 d2                	xor    %edx,%edx
  10518a:	8b 74 24 10          	mov    0x10(%esp),%esi
  10518e:	8b 7c 24 14          	mov    0x14(%esp),%edi
  105192:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  105196:	83 c4 1c             	add    $0x1c,%esp
  105199:	c3                   	ret    
  10519a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  1051a0:	39 f2                	cmp    %esi,%edx
  1051a2:	77 54                	ja     1051f8 <__umoddi3+0xa8>
  1051a4:	0f bd c2             	bsr    %edx,%eax
  1051a7:	83 f0 1f             	xor    $0x1f,%eax
  1051aa:	89 44 24 04          	mov    %eax,0x4(%esp)
  1051ae:	75 60                	jne    105210 <__umoddi3+0xc0>
  1051b0:	39 e9                	cmp    %ebp,%ecx
  1051b2:	0f 87 08 01 00 00    	ja     1052c0 <__umoddi3+0x170>
  1051b8:	29 cd                	sub    %ecx,%ebp
  1051ba:	19 d6                	sbb    %edx,%esi
  1051bc:	89 34 24             	mov    %esi,(%esp)
  1051bf:	8b 14 24             	mov    (%esp),%edx
  1051c2:	89 e8                	mov    %ebp,%eax
  1051c4:	8b 74 24 10          	mov    0x10(%esp),%esi
  1051c8:	8b 7c 24 14          	mov    0x14(%esp),%edi
  1051cc:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  1051d0:	83 c4 1c             	add    $0x1c,%esp
  1051d3:	c3                   	ret    
  1051d4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  1051d8:	85 c9                	test   %ecx,%ecx
  1051da:	75 0b                	jne    1051e7 <__umoddi3+0x97>
  1051dc:	b8 01 00 00 00       	mov    $0x1,%eax
  1051e1:	31 d2                	xor    %edx,%edx
  1051e3:	f7 f1                	div    %ecx
  1051e5:	89 c1                	mov    %eax,%ecx
  1051e7:	89 f0                	mov    %esi,%eax
  1051e9:	31 d2                	xor    %edx,%edx
  1051eb:	f7 f1                	div    %ecx
  1051ed:	89 e8                	mov    %ebp,%eax
  1051ef:	f7 f1                	div    %ecx
  1051f1:	eb 93                	jmp    105186 <__umoddi3+0x36>
  1051f3:	90                   	nop
  1051f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  1051f8:	89 f2                	mov    %esi,%edx
  1051fa:	8b 74 24 10          	mov    0x10(%esp),%esi
  1051fe:	8b 7c 24 14          	mov    0x14(%esp),%edi
  105202:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  105206:	83 c4 1c             	add    $0x1c,%esp
  105209:	c3                   	ret    
  10520a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  105210:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  105215:	bd 20 00 00 00       	mov    $0x20,%ebp
  10521a:	89 f8                	mov    %edi,%eax
  10521c:	2b 6c 24 04          	sub    0x4(%esp),%ebp
  105220:	d3 e2                	shl    %cl,%edx
  105222:	89 e9                	mov    %ebp,%ecx
  105224:	d3 e8                	shr    %cl,%eax
  105226:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  10522b:	09 d0                	or     %edx,%eax
  10522d:	89 f2                	mov    %esi,%edx
  10522f:	89 04 24             	mov    %eax,(%esp)
  105232:	8b 44 24 08          	mov    0x8(%esp),%eax
  105236:	d3 e7                	shl    %cl,%edi
  105238:	89 e9                	mov    %ebp,%ecx
  10523a:	d3 ea                	shr    %cl,%edx
  10523c:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  105241:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  105245:	d3 e6                	shl    %cl,%esi
  105247:	89 e9                	mov    %ebp,%ecx
  105249:	d3 e8                	shr    %cl,%eax
  10524b:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  105250:	09 f0                	or     %esi,%eax
  105252:	8b 74 24 08          	mov    0x8(%esp),%esi
  105256:	f7 34 24             	divl   (%esp)
  105259:	d3 e6                	shl    %cl,%esi
  10525b:	89 74 24 08          	mov    %esi,0x8(%esp)
  10525f:	89 d6                	mov    %edx,%esi
  105261:	f7 e7                	mul    %edi
  105263:	39 d6                	cmp    %edx,%esi
  105265:	89 c7                	mov    %eax,%edi
  105267:	89 d1                	mov    %edx,%ecx
  105269:	72 41                	jb     1052ac <__umoddi3+0x15c>
  10526b:	39 44 24 08          	cmp    %eax,0x8(%esp)
  10526f:	72 37                	jb     1052a8 <__umoddi3+0x158>
  105271:	8b 44 24 08          	mov    0x8(%esp),%eax
  105275:	29 f8                	sub    %edi,%eax
  105277:	19 ce                	sbb    %ecx,%esi
  105279:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  10527e:	89 f2                	mov    %esi,%edx
  105280:	d3 e8                	shr    %cl,%eax
  105282:	89 e9                	mov    %ebp,%ecx
  105284:	d3 e2                	shl    %cl,%edx
  105286:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  10528b:	09 d0                	or     %edx,%eax
  10528d:	89 f2                	mov    %esi,%edx
  10528f:	d3 ea                	shr    %cl,%edx
  105291:	8b 74 24 10          	mov    0x10(%esp),%esi
  105295:	8b 7c 24 14          	mov    0x14(%esp),%edi
  105299:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  10529d:	83 c4 1c             	add    $0x1c,%esp
  1052a0:	c3                   	ret    
  1052a1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  1052a8:	39 d6                	cmp    %edx,%esi
  1052aa:	75 c5                	jne    105271 <__umoddi3+0x121>
  1052ac:	89 d1                	mov    %edx,%ecx
  1052ae:	89 c7                	mov    %eax,%edi
  1052b0:	2b 7c 24 0c          	sub    0xc(%esp),%edi
  1052b4:	1b 0c 24             	sbb    (%esp),%ecx
  1052b7:	eb b8                	jmp    105271 <__umoddi3+0x121>
  1052b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  1052c0:	39 f2                	cmp    %esi,%edx
  1052c2:	0f 82 f0 fe ff ff    	jb     1051b8 <__umoddi3+0x68>
  1052c8:	e9 f2 fe ff ff       	jmp    1051bf <__umoddi3+0x6f>
