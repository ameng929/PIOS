/*
 * System call handling.
 *
 * Copyright (C) 1997 Massachusetts Institute of Technology
 * See section "MIT License" in the file LICENSES for licensing terms.
 *
 * Derived from the xv6 instructional operating system from MIT.
 * Adapted for PIOS by Bryan Ford at Yale University.
 */

#include <inc/x86.h>
#include <inc/string.h>
#include <inc/assert.h>
#include <inc/trap.h>
#include <inc/syscall.h>

#include <kern/cpu.h>
#include <kern/trap.h>
#include <kern/proc.h>
#include <kern/syscall.h>





// This bit mask defines the eflags bits user code is allowed to set.
#define FL_USER		(FL_CF|FL_PF|FL_AF|FL_ZF|FL_SF|FL_DF|FL_OF)


// During a system call, generate a specific processor trap -
// as if the user code's INT 0x30 instruction had caused it -
// and reflect the trap to the parent process as with other traps.
static void gcc_noreturn
systrap(trapframe *utf, int trapno, int err)
{
       utf->trapno = trapno;
       utf->err = err;
       proc_ret(utf, 0);
}

// Recover from a trap that occurs during a copyin or copyout,
// by aborting the system call and reflecting the trap to the parent process,
// behaving as if the user program's INT instruction had caused the trap.
// This uses the 'recover' pointer in the current cpu struct,
// and invokes systrap() above to blame the trap on the user process.
//
// Notes:
// - Be sure the parent gets the correct trapno, err, and eip values.
// - Be sure to release any spinlocks you were holding during the copyin/out.
//
static void gcc_noreturn
sysrecover(trapframe *ktf, void *recoverdata)
{
  trapframe *utf = (trapframe*)recoverdata;
  cpu *c = cpu_cur();
  assert(c->recover == sysrecover);
  c->recover = NULL;
  systrap(utf, ktf->trapno, ktf->err);
}

// Check a user virtual address block for validity:
// i.e., make sure the complete area specified lies in
// the user address space between VM_USERLO and VM_USERHI.
// If not, abort the syscall by sending a T_GPFLT to the parent,
// again as if the user program's INT instruction was to blame.
//
// Note: Be careful that your arithmetic works correctly
// even if size is very large, e.g., if uva+size wraps around!
//
static void checkva(trapframe *utf, uint32_t uva, size_t size)
{
        panic("checkva() not implemented.");
}

// Copy data to/from user space,
// using checkva() above to validate the address range
// and using sysrecover() to recover from any traps during the copy.
void usercopy(trapframe *utf, bool copyout,
			void *kva, uint32_t uva, size_t size)
{
	panic("syscall_usercopy() not implemented.");
}

static void
do_cputs(trapframe *tf, uint32_t cmd)
{
	// Print the string supplied by the user: pointer in EBX
	cprintf("%s", (char*)tf->regs.ebx);
	trap_return(tf);	// syscall completed
}

// Common function to handle all system calls -
// decode the system call type and call an appropriate handler function.
// Be sure to handle undefined system calls appropriately.

static void
do_put(trapframe *tf, uint32_t cmd)
{
  //need to rethink setting lock
  proc *curr = proc_cur();
  procstate *cstate = (procstate*)tf->regs.ebx;//"b"(save)
  spinlock_acquire(&curr->lock);
  uint32_t child_index = tf->regs.edx;
  //"d"(child)
  //EDX: bits 7-0:Child proess number to get/put
  uint8_t cn = child_index & 0xff;//the last 8 bits for child number
  proc *child = curr->child[cn];
  spinlock_release(&curr->lock);
  //shall the child->lock be catch, before accessing the child ?
  if(!child){
    child = proc_alloc(curr, cn);
  }
  if(child->state != PROC_STOP){
    proc_wait(curr, child, tf);
  }
  

  //if the child is not in the stopped state,
  //the kernel puts the parent process to sleep waiting for the child to stop
  //the parents goes into the PROC_WAIT state and sits there
  //until the child enters the PROC_STOP,
  //at which point the parent wakes up and restarts its PUT system call .
  
  if(cmd & SYS_REGS){//#define SYS_REGS 0x00001000
    memmove(&(child->sv.tf.regs), &(cstate->tf.regs), sizeof(pushregs));
    child->sv.tf.ds = CPU_GDT_UDATA | 3;
    child->sv.tf.es = CPU_GDT_UDATA | 3;
    child->sv.tf.cs = CPU_GDT_UCODE | 3;
    child->sv.tf.ss = CPU_GDT_UDATA | 3;
    child->sv.tf.eip =  cstate->tf.eip;
    child->sv.tf.esp =  cstate->tf.esp;
    child->sv.tf.eflags &= FL_USER;
    child->sv.tf.eflags |= FL_IF;
  }
  if(cmd & SYS_START)
    proc_ready(child);
  trap_return(tf);
}

static void 
do_get(trapframe *tf, uint32_t cmd)
{
  //need to rethink setting lock
  proc *curr = proc_cur();
  procstate *cstate = (procstate*)tf->regs.ebx;
  spinlock_acquire(&curr->lock);
  int child_index = tf->regs.edx;
  uint32_t cn = child_index & 0xff;
  proc *child = curr->child[cn];
  spinlock_release(&curr->lock);
  assert(child != NULL);
  if(child->state != PROC_STOP){
    proc_wait(curr, child, tf);
  }
  if(cmd & SYS_REGS)
    memmove(&(cstate->tf), &(child->sv.tf),sizeof(trapframe));
  trap_return(tf);
}

static void
do_ret(trapframe *tf)
{
  proc_ret(tf, 1);
}

// the convention in inc/syscall.h
// Register conventions on GET/PUT system call entry:
//	EAX:	System call command/flags (SYS_*)
//	EDX:	bits 7-0: Child process number to get/put
//	EBX:	Get/put CPU state pointer for SYS_REGS and/or SYS_FPU)
//	ECX:	Get/put memory region size
//	ESI:	Get/put local memory region start
//	EDI:	Get/put child memory region start
//	EBP:	reserved

void
syscall(trapframe *tf)
{
	// EAX register holds system call command/flags
	uint32_t cmd = tf->regs.eax;
	switch (cmd & SYS_TYPE) {
	case SYS_CPUTS:	return do_cputs(tf, cmd);
	// Your implementations of SYS_PUT, SYS_GET, SYS_RET here...
	case SYS_PUT: 
	  return do_put(tf, cmd);
	case SYS_GET:
	  return do_get(tf, cmd);
	case SYS_RET:
	  return do_ret(tf);
	default:	return;		// handle as a regular trap
	}
}

