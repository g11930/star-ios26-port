/*
 * star_msgprobe.c -- answer "who is backboardd / SpringBoard waiting for?"
 *
 * s55-s57 proved the UI processes are alive, stuck in mach_msg on their main
 * threads, but never learned WHICH port they wait on.  From the kernel we can
 * answer that: a thread blocked in the mach_msg trap still holds the syscall
 * arguments in its saved general registers (x0..x6 on arm64), and the
 * receive-port name (x4) can be translated in the owner's IPC space to the
 * port that holds the receive right -- which identifies the process or
 * kernel object that must come talk to us before anyone proceeds.
 *
 * This file is the bsd half: it walks the process list, samples threads via
 * the osfmk half (osfmk/kern/star_msgprobe_k.c -- see the struct access
 * rationale there), and prints the log.  Read-only survey, same discipline
 * as star_display_probe.c: never writes a device register, never modifies a
 * port or a thread, boot-arg gated:
 *
 *   star_msgprobe=1      enable (default off)
 *
 * A kernel thread does N passes, each pass walking the target processes and
 * printing at most STAR_MSGPROBE_MAXLINES lines per target.
 *
 * Diag-only races are accepted on purpose (a process may exit between the
 * snapshot and the port lookup); every step checks and bails instead of
 * panicking.
 */
#include <kern/clock.h>
#include <kern/locks.h>
#include <kern/thread.h>
#include <libkern/libkern.h>
#include <mach/mach_types.h>
#include <pexpert/pexpert.h>
#include <sys/param.h>
#include <sys/proc.h>
#include <sys/proc_internal.h>
#include <sys/proc_private.h>
#include <sys/queue.h>
#include <sys/systm.h>

extern void IOLog(const char *format, ...);

/* osfmk half (osfmk/kern/star_msgprobe_k.c) */
struct star_msgprobe_peer {
	int kind;            /* see star_msgprobe_lookup() */
	void *task;          /* valid when kind == 3 */
	unsigned iotype;     /* port's ipc_object_type_t, ~0u if unknown */
	unsigned long kobject;
	unsigned long queue_state; /* s68: low16=imq_msgcount, high16=imq_qlimit */
	unsigned int  kmsg_ids[8];  /* s69: msgh_id of queued kmsgs, 0 = empty slot */
	unsigned int  recv_name;    /* s70: port->ip_messages.imq_receiver_name */
};
extern int star_msgprobe_wait_regs(void *thread, uint64_t *regs);
extern int star_msgprobe_task_threads(void *task, void **out, int max);
extern void star_msgprobe_lookup(void *task, uint64_t name, int send,
	struct star_msgprobe_peer *out);
extern int star_msgprobe_waitq_owner(void *thread,
	struct star_msgprobe_peer *out);
extern int star_msgprobe_waitq_diag(void *thread, unsigned long *wq,
	unsigned long *zid);
extern int star_msgprobe_turnstile_owner(void *thread,
	struct star_msgprobe_peer *out);
extern int star_msgprobe_thread_diag(void *thread, uint64_t *out);
extern int star_msgprobe_syscall(void *task, uint64_t pc, int64_t *sc, uint32_t *raw);
extern int annibale_task_exec_image(void *task, char *name, uint32_t namelen);
extern void annibale_thread_dump(void *task, int pid, uint64_t exec_base,
    const char *exec_image);

/* s72b: the bsd-side <kern/thread.h> does not expose the osfmk TH_* bits
 * in this tree (build error: use of undeclared identifier 'TH_WAIT'), so
 * restate the one bit we need.  Value from osfmk/kern/thread.h:523. */
#define STAR_TH_WAIT 0x01

#define STAR_MSGPROBE_FIRST_DELAY   90   /* seconds after boot before pass 1 */
#define STAR_MSGPROBE_PERIOD        60   /* seconds between passes */
#define STAR_MSGPROBE_PASSES        15
#define STAR_MSGPROBE_MAXLINES      24   /* threads printed per target per pass */
#define STAR_MSGPROBE_MAXTHREADS    24   /* threads sampled per task */

/* s98: tdump-only mode -- run annibale_thread_dump for each target and skip
 * the waitq/turnstile surveys (whose zid=22 dereference panicked in s82). */
static int star_tdump_only = 0;

static const char *const star_msgprobe_targets[] = {
	"backboardd",
	"SpringBoard",
	"launchd",
};

/* <osfmk/ipc/ipc_types.h> ipc_object_type_t: the port-set / generic / service
 * prefix of the enum, mapped to short names for the log. */
static const char *
star_msgprobe_iot_name(unsigned t)
{
	static const char *const names[] = {
		"IOT_PORT_SET", "IOT_PORT", "IOT_SERVICE_PORT", "IOT_BOOTSTRAP_PORT",
		"IOT_WEAK_SERVICE_PORT", "IOT_CONNECTION_PORT", "IOT_CONN_PORT_ARRAY",
		"IOT_NOTIFICATION_PORT", "IOT_EXCEPTION_PORT", "IOT_TIMER_PORT",
		"IOT_REPLY_PORT", "IOT_SPECIAL_REPLY_PORT", "IOT_WEAK_REPLY_PORT",
	};
	static char buf[16];

	if (t < sizeof(names) / sizeof(names[0])) {
		return names[t];
	}
	snprintf(buf, sizeof(buf), "IKOT_%u", t);
	return buf;
}

static void
star_msgprobe_peer(const struct star_msgprobe_peer *pp)
{
	switch (pp->kind) {
	case 1:
		IOLog("StarMsgProbe:     peer=self (own port) type=%s",
		    star_msgprobe_iot_name(pp->iotype));
		return;
	case 2:
		IOLog("StarMsgProbe:     peer=kernel type=%s kobject=%p",
		    star_msgprobe_iot_name(pp->iotype), (void *)pp->kobject);
		return;
	case 3: {
		proc_t rp = (proc_t)task_get_proc_raw((task_t)pp->task);

		if (rp != NULL) {
			IOLog("StarMsgProbe:     peer=%s(%d) type=%s",
			    rp->p_comm, rp->p_pid,
			    star_msgprobe_iot_name(pp->iotype));
		} else {
			IOLog("StarMsgProbe:     peer=task(no proc) type=%s",
			    star_msgprobe_iot_name(pp->iotype));
		}
		return;
	}
	case 4:
		IOLog("StarMsgProbe:     peer=port-dead");
		return;
	case 5:
		IOLog("StarMsgProbe:     peer=port-null (pure timeout sleep)");
		return;
	case 7:
		IOLog("StarMsgProbe:     peer=space w/o task");
		return;
	case 8:
		IOLog("StarMsgProbe:     peer=inactive port");
		return;
	default:
		IOLog("StarMsgProbe:     peer=lookup-failed kr=%lu",
		    pp->kobject);
		return;
	}
}

static void
star_msgprobe_pass(void)
{
	proc_t p;
	struct {
		const char *comm;
		void *task;
	} found[3];
	int nfound = 0;

	/* Snapshot comm + task under the list lock, do the heavy work after. */
	proc_list_lock();
	LIST_FOREACH(p, &allproc, p_list) {
		for (unsigned i = 0; i < sizeof(star_msgprobe_targets) /
		    sizeof(star_msgprobe_targets[0]); i++) {
			if (nfound >= (int)(sizeof(found) / sizeof(found[0]))) {
				break;
			}
			if (strncmp(p->p_comm, star_msgprobe_targets[i],
			    MAXCOMLEN) == 0) {
				found[nfound].comm = star_msgprobe_targets[i];
				found[nfound].task = proc_task(p);
				nfound++;
			}
		}
	}
	proc_list_unlock();

	for (int i = 0; i < nfound; i++) {
		void *thr[STAR_MSGPROBE_MAXTHREADS];
		int n, printed = 0;

		n = star_msgprobe_task_threads(found[i].task, thr,
		    STAR_MSGPROBE_MAXTHREADS);
		IOLog("StarMsgProbe: === %s === nthreads=%d", found[i].comm, n);
		/* s77: full per-thread user backtraces (annibale thread_dump).
		 * One dump per target, before the per-thread lines: the bt frames
		 * name the exact user-mode function each thread is parked in. */
		{
			proc_t pp = (proc_t)task_get_proc_raw(
			    (task_t)found[i].task);

			if (pp != NULL) {
				char exec_image[64];
				uint64_t exec_base =
				    annibale_task_exec_image(
				    (task_t)found[i].task, exec_image,
				    sizeof(exec_image));

				annibale_thread_dump(
				    (task_t)found[i].task, pp->p_pid,
				    exec_base, exec_image);
			}
		}
		if (star_tdump_only) {
			continue;
		}
		for (int t = 0; t < n && printed < STAR_MSGPROBE_MAXLINES; t++) {
			uint64_t dg[6];
			uint64_t regs[5];
			uint64_t x1, x4;

			/* s72: kernel-side state line for EVERY thread -- TH_RUN
			 * threads were invisible before (wait_regs skipped
			 * non-waiters), and launchd's saved user registers were
			 * garbage, so this line is the trustworthy record. */
			if (star_msgprobe_thread_diag(thr[t], dg) != 0) {
				continue;
			}
			IOLog("StarMsgProbe:   T#%d st=%llx we=%llx wr=%lu "
			    "wq=%p zid=%lu susp=%lu",
			    t, (unsigned long long)dg[0],
			    (unsigned long long)dg[1],
			    (unsigned long)dg[2],
			    (void *)(unsigned long)dg[3],
			    (unsigned long)dg[4],
			    (unsigned long)dg[5]);
			if (dg[3] != 0 && dg[4] == 65534ul) {
				IOLog("StarMsgProbe:     -> GLOBAL-WQ "
				    "(bare-event sleep, no IPC object)");
			}
			if (!(dg[0] & STAR_TH_WAIT)) {
				printed++;
				continue;
			}
			if (star_msgprobe_wait_regs(thr[t], regs) != 0) {
				regs[3] = 0;
				regs[4] = 0;
			}
			x1 = regs[1];
			x4 = regs[2];

			/* s74: name the syscall this waiting thread is parked
			 * in by decoding the stub before its saved user pc. */
			{
				int64_t sc = 0;
				uint32_t raw[4];
				int skr = star_msgprobe_syscall(
				    found[i].task, regs[3], &sc, raw);

				IOLog("StarMsgProbe:     sc=%lld kr=%d "
				    "w=%x,%x,%x,%x",
				    sc, skr, raw[0], raw[1], raw[2],
				    raw[3]);
			}

			/* Preferred path: the thread's own wait queue names
			 * the port it is parked on (works for both send and
			 * receive waits, no syscall-ABI guessing). */
			{
				struct star_msgprobe_peer wpeer;
				int wqkr = star_msgprobe_waitq_owner(thr[t],
				    &wpeer);

				if (wqkr == 0 && wpeer.kind != 0) {
					IOLog("StarMsgProbe:   WAIT pc=%p lr=%p "
					    "port-wait type=%s",
					    (void *)regs[3], (void *)regs[4],
					    star_msgprobe_iot_name(wpeer.iotype));
					star_msgprobe_peer(&wpeer);
					printed++;
					continue;
				}
				/* s63: the waitq exists but is not an IPC port --
				 * say which zone it really is, so a launchd thread
				 * parked on a semaphore/turnstile/sched wait is no
				 * longer indistinguishable from "not mach_msg".
				 * Print this AND fall through to the register-based
				 * classification below (both are useful). */
				{
					unsigned long wqa = 0, zid = ~0ul;
					int d = star_msgprobe_waitq_diag(thr[t],
					    &wqa, &zid);

					IOLog("StarMsgProbe:   WAIT pc=%p lr=%p "
					    "waitq-diag kr=%d/%d wq=%p zid=%lu",
					    (void *)regs[3], (void *)regs[4],
					    wqkr, d, (void *)wqa, zid);
				}
				/* s65: for turnstile-backed waits, recover the
				 * proprietor port and print who should receive. */
				{
					struct star_msgprobe_peer tpeer;
					int tkr = star_msgprobe_turnstile_owner(
					    thr[t], &tpeer);

					if (tkr == 0 && tpeer.kind != 0) {
						IOLog("StarMsgProbe:   WAIT pc=%p "
						    "lr=%p TURNSTILE-PORT type=%s "
						    "imq=%lu/%lu",
						    (void *)regs[3], (void *)regs[4],
						    star_msgprobe_iot_name(tpeer.iotype),
						    tpeer.queue_state & 0xfffful,
						    (tpeer.queue_state >> 16) & 0xfffful);
						IOLog("StarMsgProbe:     recv_name=0x%x",
						    tpeer.recv_name);
						IOLog("StarMsgProbe:     queued-ids=%u,%u,%u,%u,%u,%u",
						    tpeer.kmsg_ids[0], tpeer.kmsg_ids[1],
						    tpeer.kmsg_ids[2], tpeer.kmsg_ids[3],
						    tpeer.kmsg_ids[4], tpeer.kmsg_ids[5]);
						star_msgprobe_peer(&tpeer);
					} else {
						IOLog("StarMsgProbe:   WAIT pc=%p "
						    "lr=%p turnstile-lookup kr=%d",
						    (void *)regs[3], (void *)regs[4], tkr);
					}
				}
			}

			/* mach_msg2 options carry SYNC bits in the high half
			 * (MACH_SEND_SYNC=0x1_00000000, MACH_RCV_SYNC=0x2_...),
			 * so the sanity ceiling must cover those; anything above
			 * ~0x7_ffffffff is a kernel pointer, not an option. */
			if ((x1 & (MACH_SEND_MSG | MACH_RCV_MSG)) != 0 &&
			    x1 <= 0x7fffffffffull && (x1 & MACH_RCV_MSG)) {
				struct star_msgprobe_peer peer;

				IOLog("StarMsgProbe:   WAIT pc=%p lr=%p "
				    "mach_msg opt=0x%llx rcv=%llx",
				    (void *)regs[3], (void *)regs[4],
				    (unsigned long long)x1,
				    (unsigned long long)x4);
				star_msgprobe_lookup(found[i].task,
				    x4, 0, &peer);
				star_msgprobe_peer(&peer);
			} else if ((x1 & (MACH_SEND_MSG | MACH_RCV_MSG)) != 0 &&
			    x1 <= 0x7fffffffffull) {
				IOLog("StarMsgProbe:   WAIT pc=%p lr=%p "
				    "mach_msg opt=0x%llx (send-phase, "
				    "header not read)",
				    (void *)regs[3], (void *)regs[4],
				    (unsigned long long)x1);
			} else {
				IOLog("StarMsgProbe:   WAIT pc=%p lr=%p "
				    "(not mach_msg-looking) "
				    "x0=%llx x1=%llx x4=%llx",
				    (void *)regs[3], (void *)regs[4],
				    (unsigned long long)regs[0],
				    (unsigned long long)x1,
				    (unsigned long long)x4);
			}
			printed++;
		}
	}
	if (nfound == 0) {
		IOLog("StarMsgProbe: no target process found this pass");
	}
}

static void
star_msgprobe_thread(void *arg, wait_result_t wres)
{
#pragma unused(arg, wres)
	static char token;

	for (int pass = 0; pass < STAR_MSGPROBE_PASSES; pass++) {
		struct timespec ts = {
			pass == 0 ? STAR_MSGPROBE_FIRST_DELAY : STAR_MSGPROBE_PERIOD, 0
		};

		(void)msleep(&token, NULL, PRIBIO, "starmsgprobe", &ts);
		IOLog("StarMsgProbe: pass %d", pass + 1);
		star_msgprobe_pass();
	}
	IOLog("StarMsgProbe: done (%d passes)", STAR_MSGPROBE_PASSES);
	thread_terminate(current_thread());
}

void
star_msgprobe_start(void)
{
	uint32_t ask = 0;
	thread_t th;

	if (!PE_parse_boot_argn("star_msgprobe", &ask, sizeof(ask)) || ask == 0) {
		return;
	}
	(void)PE_parse_boot_argn("star_tdump", &star_tdump_only,
	    sizeof(star_tdump_only));
	if (kernel_thread_start(star_msgprobe_thread, NULL, &th) == KERN_SUCCESS) {
		thread_deallocate(th);
	}
}
