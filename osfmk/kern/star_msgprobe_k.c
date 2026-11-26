/*
 * star_msgprobe_k.c -- osfmk half of the s61 mach_msg waiter survey.
 *
 * The bsd half (bsd/dev/star/star_msgprobe.c) walks the process list and
 * prints the log; it cannot see osfmk-private structs, and this file cannot
 * see struct proc.  So this TU exposes three narrow helpers that stay inside
 * the osfmk private scopes (struct thread/task, IPC ports), and the bsd TU
 * does everything user-visible.
 *
 * All helpers are read-only: thread states are sampled, ports are only
 * translated (locked/unlocked), nothing is modified.
 */
#include <kern/kern_types.h>
#include <kern/task.h>
#include <kern/thread.h>
#include <mach/mach_types.h>
#include <mach/message.h>
#include <mach/port.h>
#include <mach/arm/thread_status.h>
#include <ipc/ipc_object.h>
#include <ipc/ipc_port.h>
#include <ipc/ipc_space.h>
#include <kern/zalloc.h>
#include <kern/zalloc_internal.h>
#include <vm/vm_map.h>
#include <vm/vm_kern.h>
/* NB: do NOT include <libkern/libkern.h> here -- in this tree it resolves to
 * the bsd copy, whose printf/copyinstr prototypes conflict with osfmk's
 * misc_protos.h (CONFIG_NO_PRINTF_STRINGS).  osfmk TUs get everything they
 * need from the kern/mach headers below. */

/* Shared result record -- MUST stay field-for-field identical to the copy
 * in bsd/dev/star/star_msgprobe.c (declared there as extern interface). */
struct star_msgprobe_peer {
	int kind;            /* see star_msgprobe_lookup() */
	void *task;          /* valid when kind == 3 */
	unsigned iotype;     /* port's ipc_object_type_t, ~0u if unknown */
	unsigned long kobject;
	unsigned long queue_state; /* s68: low16=imq_msgcount, high16=imq_qlimit */
	unsigned int  kmsg_ids[8];  /* s69: msgh_id of queued kmsgs, 0 = empty slot */
	unsigned int  recv_name;    /* s70: port->ip_messages.imq_receiver_name */
};

/*
 * regs[0..4] = x0 (msg), x1 (option), x4 (rcv_name), pc, lr of a WAITING
 * thread.  Returns 0 on success, -1 if the thread is not waiting, -2 if the
 * state could not be fetched.
 */
int
star_msgprobe_wait_regs(void *vth, uint64_t *regs)
{
	thread_t th = (thread_t)vth;
	arm_thread_state64_t st;
	mach_msg_type_number_t cnt = ARM_THREAD_STATE64_COUNT;
	kern_return_t kr;

	thread_mtx_lock(th);
	if (!(th->state & TH_WAIT)) {
		thread_mtx_unlock(th);
		return -1;
	}
	kr = machine_thread_get_state(th, ARM_THREAD_STATE64,
	    (thread_state_t)&st, &cnt);
	thread_mtx_unlock(th);
	if (kr != KERN_SUCCESS) {
		return -2;
	}

	regs[0] = st.x[0];
	regs[1] = st.x[1];
	regs[2] = st.x[4];
	/* This tree builds without ptrauth_calls (software PAC emulation), so
	 * arm_thread_state64_t is the plain non-opaque variant: pc/lr are
	 * direct fields, and the accessor macros are __DARWIN_C_LEVEL-gated
	 * and absent in the kernel anyway. */
	regs[3] = st.pc;
	regs[4] = st.lr;
	return 0;
}

/* Snapshot up to max thread handles of a task (caller holds no task lock). */
int
star_msgprobe_task_threads(void *vtask, void **out, int max)
{
	task_t task = (task_t)vtask;
	thread_t th;
	int n = 0;

	if (task == NULL) {
		return 0;
	}
	task_lock(task);
	queue_iterate(&task->threads, th, thread_t, task_threads) {
		if (n >= max) {
			break;
		}
		out[n++] = th;
	}
	task_unlock(task);
	return n;
}

/*
 * Translate the mach port name "name" in task's IPC space and describe who
 * holds the opposite right.  out->kind:
 *   0 lookup failed (kobject = kern_return_t)
 *   1 the waiter's own port
 *   2 kernel (IOKit/host); kobject = raw kobject if the port carries one
 *   3 another task (out->task, bsd side resolves pid/comm)
 *   4 MACH_PORT_DEAD name
 *   5 MACH_PORT_NULL name
 *   7 receiver space without a task
 * out->iotype is the port's ipc_object_type_t (the IOT_ or IKOT_ enum), or
 * ~0u.
 */
void
star_msgprobe_lookup(void *vtask, uint64_t name, int send,
    struct star_msgprobe_peer *out)
{
	task_t task = (task_t)vtask;
	ipc_port_t port = IP_NULL;
	ipc_space_t space;
	kern_return_t kr;

	out->kind = 0;
	out->task = NULL;
	out->iotype = ~0u;
	out->kobject = 0;

	if (task == NULL) {
		return;
	}
	if (name == (uint64_t)MACH_PORT_NULL) {
		out->kind = 5;
		return;
	}
	if (name == (uint64_t)MACH_PORT_DEAD) {
		out->kind = 4;
		return;
	}

	space = task->itk_space;
	kr = send
	    ? ipc_port_translate_send(space, (mach_port_name_t)name, &port)
	    : ipc_port_translate_receive(space, (mach_port_name_t)name, &port);
	if (kr != KERN_SUCCESS || port == IP_NULL) {
		out->kobject = (uint64_t)kr;
		return;
	}

	/* port is locked here (translate contract) */
	out->iotype = (unsigned)io_type((ipc_object_t)port);
	{
		ipc_space_t rs = port->ip_receiver;

		if (rs == space) {
			out->kind = 1;
		} else if (rs == ipc_space_kernel) {
			out->kind = 2;
			if (io_is_kobject((ipc_object_t)port)) {
				out->kobject = (uint64_t)port->ip_kobject;
			}
		} else if (rs != NULL && rs->is_task != NULL) {
			out->kind = 3;
			out->task = (void *)rs->is_task;
		} else {
			out->kind = 7;
		}
	}
	io_unlock((ipc_object_t)port);
}

/*
 * s63: diagnostic for why waitq_owner() failed on a thread.  Returns:
 *   -1 thread not in TH_WAIT, -2 waitq pointer NULL, 0 otherwise.
 * On 0, *wq / *zid describe the wait queue and the zone that backs it, so
 * the bsd half can tell an IPC-port wait from a semaphore/sched/turnstile
 * wait (the latter is why launchd's threads showed up as opaque before).
 * zone_id_for_element() is a read-only lookup and never derefs the element.
 */
int
star_msgprobe_waitq_diag(void *vth, unsigned long *wq, unsigned long *zid)
{
	thread_t th = (thread_t)vth;
	waitq_t wqlocal;
	int waiting;

	*wq = 0;
	*zid = ~0ul;
	thread_mtx_lock(th);
	waiting = (th->state & TH_WAIT) != 0;
	wqlocal = th->waitq;
	thread_mtx_unlock(th);
	if (!waiting) {
		return -1;
	}
	*wq = (unsigned long)wqlocal.wq_q;
	if (wqlocal.wq_q == NULL) {
		return -2;
	}
	*zid = (unsigned long)zone_id_for_element(wqlocal.wq_q,
	    sizeof(struct waitq));
	return 0;
}

/*
 * The reliable way to answer "which port is this thread blocked against":
 * a mach_msg-send or mach_msg-receive block always parks the thread on the
 * destination/receive port's wait queue, and xnu offers io_from_waitq() to
 * walk straight back to the ipc_object.  No syscall-ABI guessing needed.
 *
 * Safety, learned from the s61c data abort: the waitq address may be (a) a
 * non-IPC wait queue (semaphore, sched wait), (b) a freed/cleared IPC
 * element (zeroed io_bits then masquerades as IOT_PORT_SET), or (c) fine.
 * So: first zone_id_for_element() -- a read-only probe that never touches
 * the element's contents -- and only when the element genuinely lives in
 * the IPC port zones take the object lock via ipc_object_lock_allow_invalid
 * (which also handles freed/uninitialized elements by returning false).
 *
 * Returns 0 with out->kind filled in when the wait is on a live port;
 * negative when the thread is not waiting (-1), the wait queue is not an
 * IPC port's (-2), or the object is dead/uninitialized (-3).
 */
int
star_msgprobe_waitq_owner(void *vth, struct star_msgprobe_peer *out)
{
	thread_t th = (thread_t)vth;
	waitq_t wq;
	int waiting;

	out->kind = 0;
	out->task = NULL;
	out->iotype = ~0u;
	out->kobject = 0;

	thread_mtx_lock(th);
	waiting = (th->state & TH_WAIT) != 0;
	wq = th->waitq;
	thread_mtx_unlock(th);
	if (!waiting || wq.wq_q == NULL) {
		return -1;
	}

	{
		zone_id_t zid = zone_id_for_element(wq.wq_q,
		    sizeof(struct waitq));

		if (zid != ZONE_ID_IPC_PORT && zid != ZONE_ID_IPC_PORT_SET) {
			return -2;
		}
	}

	{
		ipc_object_t io = io_from_waitq(wq.wq_q);
		ipc_port_t port;
		ipc_space_t rs;

		if (!ipc_object_lock_allow_invalid(io)) {
			return -3;              /* freed or uninitialized */
		}
		out->iotype = (unsigned)io_type(io);
		/* s85: a KOBJECT (kqueue, host, ...) behind a waitq is not a port;
		 * reading ip_receiver on it aborts (s82: far 0x2a2a014400000a1d).
		 * Port types are IOT_PORT_SET..IOT_WEAK_REPLY_PORT; anything else
		 * (or a freed element's garbage type) is reported and bailed. */
		if (out->iotype > IOT_WEAK_REPLY_PORT) {
			out->kind = 9;          /* not a port */
			ipc_object_unlock(io);
			return 0;
		}
		port = ip_object_to_port(io);
		if (!io_state_active(io->io_state)) {
			ipc_object_unlock(io);
			out->kind = 8;          /* inactive port */
			return 0;
		}
		rs = port->ip_receiver;
		if (rs == NULL) {
			out->kind = 7;
		} else if (rs == ipc_space_kernel) {
			out->kind = 2;
			if (io_is_kobject(io)) {
				out->kobject = (uint64_t)port->ip_kobject;
			}
		} else {
			task_t rt = rs->is_task;

			if (rt != NULL) {
				out->kind = 3;
				out->task = (void *)rt;
			} else {
				out->kind = 7;
			}
		}
		ipc_object_unlock(io);
	}
	return 0;
}


/*
 * s65: turnstile -> port reverse lookup.
 *
 * xnu12377 parks a synchronous mach_msg SEND/RECV waiter on the destination
 * port's *turnstile* waitq (zone ZONE_ID_TURNSTILE), not on the port's own
 * waitq.  That is why star_msgprobe_waitq_owner() (IPC_PORT zones only) always
 * returned -2/zid=27 for backboardd.  A TURNSTILE_SYNC_IPC turnstile stores
 * its proprietor as the ipc_port_t it guards (cf. turnstile.c
 * turnstile_is_send_turnstile()).  Recover that port and report its receiver:
 * the task that must answer the blocked SEND.
 *
 * Safety (avoids the s61c data abort): confirm the element really is a
 * turnstile (zone), confirm its type is TURNSTILE_SYNC_IPC before treating
 * ts_proprietor as a port, and take the object lock via
 * ipc_object_lock_allow_invalid() so a freed/uninitialized port bails cleanly.
 * Negative returns are diagnostics, never derefs.
 */
int
star_msgprobe_turnstile_owner(void *vth, struct star_msgprobe_peer *out)
{
	thread_t th = (thread_t)vth;
	waitq_t wq;
	struct turnstile *ts;
	uint32_t tv;
	ipc_port_t port;
	ipc_object_t io;
	ipc_space_t rs;
	int waiting;

	out->kind = 0;
	out->task = NULL;
	out->iotype = ~0u;
	out->kobject = 0;
	out->queue_state = 0;
	memset(out->kmsg_ids, 0, sizeof(out->kmsg_ids));

	thread_mtx_lock(th);
	waiting = (th->state & TH_WAIT) != 0;
	wq = th->waitq;
	thread_mtx_unlock(th);
	if (!waiting || wq.wq_q == NULL) {
		return -1;                      /* not waiting */
	}
	if (zone_id_for_element(wq.wq_q, sizeof(struct waitq)) !=
	    ZONE_ID_TURNSTILE) {
		return -2;                      /* not a turnstile waitq */
	}

	ts = waitq_to_turnstile(wq.wq_q);
	/* turnstile_type_t is one byte; the type is the low byte of the atomic
	 * ts_type_gencount (union turnstile_type_gencount in turnstile.c). */
	tv = (uint32_t)ts->ts_type_gencount;
	if ((tv & 0xffu) != (uint32_t)TURNSTILE_SYNC_IPC) {
		out->kobject = tv & 0xffu;      /* report the real type */
		return -3;                      /* turnstile, but not IPC */
	}

	port = (ipc_port_t)ts->ts_proprietor;
	if (port == IP_NULL) {
		return -4;                      /* no proprietor */
	}
	io = (ipc_object_t)port;
	if (!ipc_object_lock_allow_invalid(io)) {
		return -5;                      /* freed / uninitialized */
	}
	out->iotype = (unsigned)io_type(io);
	/* s85: only real port types carry imq_* fields (see waitq_owner). */
	if (out->iotype > IOT_WEAK_REPLY_PORT) {
		out->kind = 9;          /* not a port */
		ipc_object_unlock(io);
		return 0;
	}
	/* s68: snapshot the message queue while the port lock is held. */
	out->queue_state = ((unsigned long)port->ip_messages.imq_qlimit << 16) |
	    (unsigned long)port->ip_messages.imq_msgcount;
	out->recv_name = (unsigned int)port->ip_messages.imq_receiver_name;
	/* s69: walk up to 8 queued messages, record msgh_id (port lock held). */
	{
		ipc_kmsg_t km = ipc_kmsg_queue_first(&port->ip_messages.imq_messages);
		int slot = 0;

		while (km != IKM_NULL && slot < 8) {
			out->kmsg_ids[slot++] = (unsigned int)ikm_header(km)->msgh_id;
			km = ipc_kmsg_queue_next(&port->ip_messages.imq_messages, km);
		}
	}
	if (!io_state_active(io->io_state)) {
		ipc_object_unlock(io);
		out->kind = 8;                  /* inactive port */
		return 0;
	}
	rs = port->ip_receiver;
	if (rs == NULL) {
		out->kind = 7;
	} else if (rs == ipc_space_kernel) {
		out->kind = 2;
		if (io_is_kobject(io)) {
			out->kobject = (uint64_t)port->ip_kobject;
		}
	} else {
		task_t rt = rs->is_task;

		if (rt != NULL) {
			out->kind = 3;
			out->task = (void *)rt;
		} else {
			out->kind = 7;
		}
	}
	ipc_object_unlock(io);
	return 0;
}

/*
 * s72: kernel-side per-thread state snapshot.  The s70 register reads
 * (machine_thread_get_state) returned garbage for launchd (x1=0xffff...,
 * rcv=0xd5a00000000), so the honest answer comes from the kernel fields
 * themselves, read under thread_mtx:
 *
 *   out[0] = th->state (raw TH_* bits: 1=WAIT 2=SUSP 4=RUN 8=UNINT)
 *   out[1] = th->wait_event (64-bit event last asserted)
 *   out[2] = th->wait_result
 *   out[3] = raw waitq address (0 = none)
 *   out[4] = zone id backing the waitq; ZONE_ID_INVALID (-2 on the 16-bit
 *            zone_id_t = 65534) means NOT zone-backed: one of the static
 *            global_waitqs[] -- a bare-event sleep, not an IPC wait.
 *   out[5] = th->suspend_count
 *
 * Returns 0, or -1 for a NULL thread.
 */
int
star_msgprobe_thread_diag(void *vth, uint64_t *out)
{
	thread_t th = (thread_t)vth;
	waitq_t wqlocal;

	if (th == NULL) {
		return -1;
	}
	thread_mtx_lock(th);
	out[0] = (uint64_t)th->state;
	out[1] = (uint64_t)th->wait_event;
	out[2] = (uint64_t)th->wait_result;
	wqlocal = th->waitq;
	out[5] = (uint64_t)(int)th->suspend_count;
	thread_mtx_unlock(th);

	out[3] = (uint64_t)(unsigned long)wqlocal.wq_q;
	if (wqlocal.wq_q == NULL) {
		out[4] = ~0ull;
	} else {
		out[4] = (uint64_t)zone_id_for_element(wqlocal.wq_q,
		    sizeof(struct waitq));
	}
	return 0;
}

/*
 * s74: decode the syscall a blocked thread is sitting in.  A thread that
 * entered a syscall has its saved user pc right after the "svc #0x80" of
 * the libsystem_kernel stub ("mov x16, #num; svc #0x80"), so read the two
 * words before pc from the task's address space and extract the stub
 * number.  Read-only; the page is already resident (the thread executed
 * it), so no pager interaction is expected.
 *
 * Returns 0 with *sc = stub number (BSD syscalls positive, mach traps
 * negative -- cf. bsd_arm64.c: assert(call_number < 0); table index =
 * -call_number), -1 on copy failure/bad input, -2 on pattern mismatch.
 */
int
star_msgprobe_syscall(void *vtask, uint64_t pc, int64_t *sc, uint32_t *raw)
{
	task_t task = (task_t)vtask;
	vm_map_t map;
	vm_map_copy_t copy;
	vm_offset_t kaddr = 0;
	uint64_t addr;
	uint32_t words[4];
	uint32_t len = 16;
	kern_return_t kr;
	int i;

	*sc = 0;
	raw[0] = raw[1] = raw[2] = raw[3] = 0;
	if (task == NULL || pc < 16 || (pc & 3) != 0) {
		return -1;
	}
	map = get_task_map(task);
	/* window [pc-12 .. pc] INCLUSIVE: the saved user pc points at the
	 * svc itself on this kernel (s75: mach_msg2 decoded as its neighbor
	 * pid_for_task with the old [pc-16, pc-4] window), so the word at pc
	 * must be part of the scan. */
	addr = (pc - 12) & ~3ull;
	len = 16;
	kr = vm_map_copyin(map, (vm_offset_t)addr, len, FALSE, &copy);
	if (kr != KERN_SUCCESS) {
		return -1;
	}
	kr = vm_map_copyout(kernel_map, &kaddr, copy);
	if (kr != KERN_SUCCESS) {
		vm_map_copy_discard(copy);
		return -1;
	}
	memcpy(words, (const void *)(uintptr_t)kaddr, len);
	kmem_free(kernel_map, kaddr, PAGE_SIZE_64);
	raw[0] = words[0];
	raw[1] = words[1];
	raw[2] = words[2];
	raw[3] = words[3];

	/* scan for [mov x/w16] followed by [svc #0x80]; the saved user pc
	 * sits right after the svc of the stub. */
	for (i = (int)(len / 4) - 2; i >= 0; i--) {
		uint32_t mv = words[i];
		uint32_t sv = words[i + 1];
		int64_t imm;

		if (sv != 0xD4001001u || (mv & 0x1Fu) != 16) {
			continue;
		}
		switch (mv & 0xFFE00000u) {
		case 0xD2800000u:           /* movz x16, #imm */
		case 0x52800000u:           /* movz w16, #imm */
			imm = (int64_t)((mv >> 5) & 0xFFFFu);
			*sc = imm;
			return 0;
		case 0x92800000u:           /* movn x16, #imm */
		case 0x12800000u:           /* movn w16, #imm */
			imm = (int64_t)((mv >> 5) & 0xFFFFu);
			*sc = -imm;
			return 0;
		}
	}
	return -2;
}
