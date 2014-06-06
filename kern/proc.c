/*
 * PIOS process management.
 *
 * Copyright (C) 2010 Yale University.
 * See section "MIT License" in the file LICENSES for licensing terms.
 *
 * Primary author: Bryan Ford
 */

#include <inc/string.h>
#include <inc/syscall.h>

#include <kern/cpu.h>
#include <kern/mem.h>
#include <kern/trap.h>
#include <kern/proc.h>
#include <kern/init.h>



proc proc_null;		// null process - just leave it initialized to 0

proc *proc_root;	// root process, once it's created in init()

// LAB 2: insert your scheduling data structure declarations here.

proc *proc_queue_head;
spinlock _queue_lock;

void
proc_init(void)
{
	if (!cpu_onboot())
	  return;
	spinlock_init(&_queue_lock);
	proc_queue_head = NULL;	
}

// Allocate and initialize a new proc as child 'cn' of parent 'p'.
// Returns NULL if no physical memory available.
proc *
proc_alloc(proc *p, uint32_t cn)
{
	pageinfo *pi = mem_alloc();
	if (!pi)
	  return NULL;
	mem_incref(pi);
	proc *cp = (proc*)mem_pi2ptr(pi);
	memset(cp, 0, sizeof(proc));
	spinlock_init(&cp->lock);
	cp->parent = p;
	cp->state = PROC_STOP;
	// Integer register state
	cp->sv.tf.ds = CPU_GDT_UDATA | 3;
	cp->sv.tf.es = CPU_GDT_UDATA | 3;
	cp->sv.tf.cs = CPU_GDT_UCODE | 3;
	cp->sv.tf.ss = CPU_GDT_UDATA | 3;
	//if the proc is root proc, return cp  directly
	if (p)
	  p->child[cn] = cp;
	return cp;
}

// Put process p in the ready state and add it to the ready queue.
void
proc_ready(proc *p)
{
        //when setting the proc info ,we should set proc->lock
	spinlock_acquire(&p->lock);
	p->state = PROC_READY;
	p->readynext = NULL;
	spinlock_release(&p->lock);
	//when setting the proc ready queue ,we shoule set queue_lock
	spinlock_acquire(&_queue_lock);
	proc *tmp = proc_queue_head;
	if(!tmp){//the ready queue is empty
	  proc_queue_head = p;
	  spinlock_release(&_queue_lock);
	  return ;
	}
	while(tmp->readynext){
	  //get the ready proc at the ready queue tail
	  tmp = tmp->readynext;
	}
	tmp->readynext = p;
	spinlock_release(&_queue_lock);
}

// Save the current process's state before switching to another process.
// Copies trapframe 'tf' into the proc struct,
// and saves any other relevant state such as FPU state.
// The 'entry' parameter is one of:
//	-1	if we entered the kernel via a trap before executing an insn
//	0	if we entered via a syscall and must abort/rollback the syscall
//	1	if we entered via a syscall and are completing the syscall
void
proc_save(proc *p, trapframe *tf, int entry)
{
	p->sv.tf = *tf;
	if(entry == 0)
	  p->sv.tf.eip -= 2;
	//the int instruction's length is 16 bits
	//such annns INT 21 ,the mechine code is 'cd 15' that needs 2 bytes
	//so when need to rollback ,sub 2 is nessesary
	//rollback the syscall, 
	//because the syscall pushes eip of the next instruction
}

// Go to sleep waiting for a given child process to finish running.
// Parent process 'p' must be running and locked on entry.
// The supplied trapframe represents p's register state on syscall entry.
void gcc_noreturn
proc_wait(proc *p, proc *cp, trapframe *tf)
{
        spinlock_acquire(&p->lock);
	p->state = PROC_WAIT;
	p->runcpu = NULL;
	p->waitchild = cp;
	proc_save(p, tf, 0);
	spinlock_release(&p->lock);
	proc_sched();
}

void gcc_noreturn
proc_sched(void)
{
	cpu *c = cpu_cur();
	for(;;){//spin
	  spinlock_acquire(&_queue_lock);
	  //we must get ready_queue lock, before accessing _queue_head
	  if(proc_queue_head){
	    proc *p = proc_queue_head;
	    proc_queue_head = p->readynext;
	    p->readynext = NULL;
	    spinlock_release(&_queue_lock);
	    spinlock_acquire(&p->lock);
	    proc_run(p);
	  }
	  else{
	    spinlock_release(&_queue_lock);
	    pause();
	  }
	}
}

// Switch to and run a specified process, which must already be locked.
void gcc_noreturn
proc_run(proc *p)
{
        assert(spinlock_holding(&p->lock));
  	p->state = PROC_RUN;
  	cpu *curr = cpu_cur();
  	curr->proc = p;
  	p->runcpu = curr;
  	spinlock_release(&p->lock);
  	trap_return(&p->sv.tf);
}

// Yield the current CPU to another ready process.
// Called while handling a timer interrupt.
void gcc_noreturn
proc_yield(trapframe *tf)
{
	proc *curr = proc_cur();
  	proc_save(curr, tf, -1);
  	proc_ready(curr);
  	proc_sched();
}

// Put the current process to sleep by "returning" to its parent process.
// Used both when a process calls the SYS_RET system call explicitly,
// and when a process causes an unhandled trap in user mode.
// The 'entry' parameter is as in proc_save().
void gcc_noreturn
proc_ret(trapframe *tf, int entry)
{
	proc *cp = proc_cur();
  	proc *pp = cp->parent;
  	// Root process incurs trap...
  	if(pp == NULL) {
	  if(tf->trapno != T_SYSCALL) {
      		trap_print(tf);
      		panic("proc_ret: trap in root process\n");
	  }
	  done();
  	}
  	spinlock_acquire(&cp->lock);
  	cp->state = PROC_STOP;
  	proc_save(cp, tf, entry);
  	spinlock_release(&cp->lock);

  	spinlock_acquire(&pp->lock);
  	if(pp->waitchild == cp || pp->state == PROC_WAIT) {
	  pp->waitchild = NULL;
	  proc_run(pp);
 	}
  	spinlock_release(&pp->lock);
  	proc_sched();
}

// Helper functions for proc_check()
static void child(int n);
static void grandchild(int n);

static struct procstate child_state;
static char gcc_aligned(16) child_stack[4][PAGESIZE];

static volatile uint32_t pingpong = 0;
static void *recovargs;

void
proc_check(void)
{
	// Spawn 2 child processes, executing on statically allocated stacks.

	int i;
	for (i = 0; i < 4; i++) {
		// Setup register state for child
		uint32_t *esp = (uint32_t*) &child_stack[i][PAGESIZE];
		*--esp = i;	// push argument to child() function
		*--esp = 0;	// fake return address
		child_state.tf.eip = (uint32_t) child;
		child_state.tf.esp = (uint32_t) esp;

		// Use PUT syscall to create each child,
		// but only start the first 2 children for now.
		cprintf("spawning child %d\n", i);
		sys_put(SYS_REGS | (i < 2 ? SYS_START : 0), i, &child_state,
			NULL, NULL, 0);
	}

	// Wait for both children to complete.
	// This should complete without preemptive scheduling
	// when we're running on a 2-processor machine.
	for (i = 0; i < 2; i++) {
		cprintf("waiting for child %d\n", i);
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
	}
	cprintf("proc_check() 2-child test succeeded\n");

	// (Re)start all four children, and wait for them.
	// This will require preemptive scheduling to complete
	// if we have less than 4 CPUs.
	cprintf("proc_check: spawning 4 children\n");
	for (i = 0; i < 4; i++) {
		cprintf("spawning child %d\n", i);
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
	}

	// Wait for all 4 children to complete.
	for (i = 0; i < 4; i++)
		sys_get(0, i, NULL, NULL, NULL, 0);
	cprintf("proc_check() 4-child test succeeded\n");

	// Now do a trap handling test using all 4 children -
	// but they'll _think_ they're all child 0!
	// (We'll lose the register state of the other children.)
	i = 0;
	sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
		// get child 0's state
	assert(recovargs == NULL);
	do {
		sys_put(SYS_REGS | SYS_START, i, &child_state, NULL, NULL, 0);
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
		if (recovargs) {	// trap recovery needed
			trap_check_args *args = recovargs;
			cprintf("recover from trap %d\n",
				child_state.tf.trapno);
			child_state.tf.eip = (uint32_t) args->reip;
			args->trapno = child_state.tf.trapno;
		} else
			assert(child_state.tf.trapno == T_SYSCALL);
		i = (i+1) % 4;	// rotate to next child proc
	} while (child_state.tf.trapno != T_SYSCALL);
	assert(recovargs == NULL);

	cprintf("proc_check() trap reflection test succeeded\n");

	cprintf("proc_check() succeeded!\n");
}

static void child(int n)
{
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
		int i;
		for (i = 0; i < 10; i++) {
			cprintf("in child %d count %d\n", n, i);
			while (pingpong != n)
				pause();
			xchg(&pingpong, !pingpong);
		}
		sys_ret();
	}

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
		cprintf("in child %d count %d\n", n, i);
		while (pingpong != n)
			pause();
		xchg(&pingpong, (pingpong + 1) % 4);
	}
	sys_ret();

	// Only "child 0" (or the proc that thinks it's child 0), trap check...
	if (n == 0) {
		assert(recovargs == NULL);
		trap_check(&recovargs);
		assert(recovargs == NULL);
		sys_ret();
	}

	panic("child(): shouldn't have gotten here");
}

static void grandchild(int n)
{
	panic("grandchild(): shouldn't have gotten here");
}

