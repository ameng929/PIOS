/*
 * Kernel initialization.
 *
 * Copyright (C) 1997 Massachusetts Institute of Technology
 * See section "MIT License" in the file LICENSES for licensing terms.
 *
 * Derived from the MIT Exokernel and JOS.
 * Adapted for PIOS by Bryan Ford at Yale University.
 */

#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/assert.h>
#include <inc/cdefs.h>

#include <kern/init.h>
#include <kern/cons.h>
#include <kern/debug.h>
#include <kern/mem.h>
#include <kern/cpu.h>
#include <kern/trap.h>
#include <kern/spinlock.h>
#include <kern/mp.h>
#include <kern/proc.h>

#include <dev/pic.h>
#include <dev/lapic.h>
#include <dev/ioapic.h>


// User-mode stack for user(), below, to run on.
static char gcc_aligned(16) user_stack[PAGESIZE];

#define ROOTEXE_START _binary_obj_user_sh_start

// Lab 3: ELF executable containing root process, linked into the kernel
#ifndef ROOTEXE_START
#endif
extern char ROOTEXE_START[];


// Called first from entry.S on the bootstrap processor,
// and later from boot/bootother.S on all other processors.
// As a rule, "init" functions in PIOS are called once on EACH processor.
void
init(void)
{
	extern char start[], edata[], end[];

	// Before anything else, complete the ELF loading process.
	// Clear all uninitialized global data (BSS) in our program,
	// ensuring that all static/global variables start out zero.
	if (cpu_onboot())
		memset(edata, 0, end - edata);

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();

	// Initialize and load the bootstrap CPU's GDT, TSS, and IDT.
	cpu_init();
	trap_init();

	// Physical memory detection/initialization.
	// Can't call mem_alloc until after we do this!
	mem_init();

	// Lab 2: check spinlock implementation
	if (cpu_onboot())
		spinlock_check();

	// Find and start other processors in a multiprocessor system
	mp_init();		// Find info about processors in system
	pic_init();		// setup the legacy PIC (mainly to disable it)
	ioapic_init();		// prepare to handle external device interrupts
	lapic_init();// setup this CPU's local APIC
	proc_init();// set the method before bootothers
	            // there is a situation that the cpu1 is fast than cpu0,
	            // so that cpu0 will reinit the proc_ready_queue 
	cpu_bootothers();	// Get other processors started
	cprintf("CPU %d (%s) has booted\n", cpu_cur()->id, cpu_onboot() ? "BP" : "AP");

	// Initialize the process management code.
	proc *root_proc;
	if(cpu_onboot()) {
		root_proc = proc_alloc(NULL,0);
		root_proc->sv.tf.esp = (uint32_t)&user_stack[PAGESIZE];
		root_proc->sv.tf.eip =  (uint32_t)user;
		root_proc->sv.tf.eflags = FL_IF;
		root_proc->sv.tf.gs = CPU_GDT_UDATA | 3;
		root_proc->sv.tf.fs = CPU_GDT_UDATA | 3;
		root_proc->sv.tf.es = CPU_GDT_UDATA | 3;
		root_proc->sv.tf.ds = CPU_GDT_UDATA | 3;
		root_proc->sv.tf.cs = CPU_GDT_UCODE | 3;
		root_proc->sv.tf.ss = CPU_GDT_UDATA | 3;
		proc_ready(root_proc);
	}
	proc_sched();
	user();

	// Lab 1: change this so it enters user() in user mode,
	// running on the user_stack declared above,
	// instead of just calling user() directly.
	// static trapframe ttf = {
	// 	//gs : 0x00,
	// 	//fs : 0x00,
	// 	gs : CPU_GDT_UDATA|3,
	// 	fs : CPU_GDT_UDATA|3,
	// 	es : CPU_GDT_UDATA|3,
	// 	ds : CPU_GDT_UDATA|3,
	// 	cs : CPU_GDT_UCODE|3,
	// 	ss : CPU_GDT_UDATA|3,
	// 	eflags : FL_IOPL_3, //make the processor believe the tf be created in usermode
	// 	eip : (uint32_t)user,
	// 	esp : (uint32_t)&user_stack[PAGESIZE],
	// };
	// trap_return(&ttf);
	//		user();

}

// This is the first function that gets run in user mode (ring 3).
// It acts as PIOS's "root process",
// of which all other processes are descendants.
void
user()
{
	cprintf("in user()\n");
	assert(read_esp() > (uint32_t) &user_stack[0]);
	assert(read_esp() < (uint32_t) &user_stack[sizeof(user_stack)]);

	// Check the system call and process scheduling code.
	proc_check();

	done();
}

// This is a function that we call when the kernel is "done" -
// it just puts the processor into an infinite loop.
// We make this a function so that we can set a breakpoints on it.
// Our grade scripts use this breakpoint to know when to stop QEMU.
void gcc_noreturn
done()
{
	while (1)
		;	// just spin
}

