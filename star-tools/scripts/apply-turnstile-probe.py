#!/usr/bin/env python3
"""
s65: add a turnstile->port reverse-lookup probe to the existing star mach_msg
survey.  In xnu12377 a synchronous mach_msg SEND parks the thread on the
*turnstile* waitq (zid 27 = ZONE_ID_TURNSTILE), so waitq_owner() -- which only
accepts IPC_PORT/IPC_PORT_SET zones -- always fails for backboardd.  A
TURNSTILE_SYNC_IPC turnstile binds ts_proprietor == the destination ipc_port_t;
recovering it tells us WHO should be receiving (and not answering).

Read-only, log-only.  Two files, idempotent, backed up, strict anchors.

Usage: python3 apply-turnstile-probe.py [--check]
"""
import os
import shutil
import sys

OSFMK = "/root/star26/star-native/osfmk/kern/star_msgprobe_k.c"
BSD = "/root/star26/star-native/bsd/dev/star/star_msgprobe.c"
TAG = "s65turnstile"
CHECK = "--check" in sys.argv

# ---- anchor 1: osfmk helper appended after star_msgprobe_waitq_owner ----
# unique tail of waitq_owner(): the ipc_object_unlock + inactive-port return
OSFMK_ANCHOR = """		ipc_object_unlock(io);
	}
	return 0;
}
"""

OSFMK_ADD = r'''

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
'''

# ---- anchor 2: bsd extern declaration ----
BSD_DECL_ANCHOR = """extern int star_msgprobe_waitq_diag(void *thread, unsigned long *wq,
	unsigned long *zid);
"""
BSD_DECL_ADD = BSD_DECL_ANCHOR + """extern int star_msgprobe_turnstile_owner(void *thread,
	struct star_msgprobe_peer *out);
"""

# ---- anchor 3: bsd call site, right after the waitq-diag print block ----
BSD_CALL_ANCHOR = """					IOLog("StarMsgProbe:   WAIT pc=%p lr=%p "
					    "waitq-diag kr=%d/%d wq=%p zid=%lu",
					    (void *)regs[3], (void *)regs[4],
					    wqkr, d, (void *)wqa, zid);
				}
			}
"""
BSD_CALL_ADD = """					IOLog("StarMsgProbe:   WAIT pc=%p lr=%p "
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
						    "lr=%p TURNSTILE-PORT type=%s",
						    (void *)regs[3], (void *)regs[4],
						    star_msgprobe_iot_name(tpeer.iotype));
						star_msgprobe_peer(&tpeer);
					} else {
						IOLog("StarMsgProbe:   WAIT pc=%p "
						    "lr=%p turnstile-lookup kr=%d",
						    (void *)regs[3], (void *)regs[4], tkr);
					}
				}
			}
"""


def patch(path, anchor, add, label):
    with open(path, "r", encoding="utf-8") as f:
        data = f.read()
    if "star_msgprobe_turnstile_owner" in data and label != "osfmk":
        # bsd file: marker present means already applied (decl added)
        if TAG in data or "turnstile-lookup kr=" in data:
            print(f"[skip] {label}: already applied")
            return False
    cnt = data.count(anchor)
    if cnt != 1:
        print(f"[FAIL] {label}: anchor count={cnt} (need exactly 1)")
        sys.exit(2)
    if CHECK:
        print(f"[check OK] {label}: anchor found once")
        return True
    bak = path + "." + TAG + ".bak"
    if not os.path.exists(bak):
        shutil.copy2(path, bak)
        print(f"[backup] {bak}")
    data = data.replace(anchor, add, 1)
    with open(path, "w", encoding="utf-8") as f:
        f.write(data)
    print(f"[patched] {label}")
    return True


def main():
    print(f"mode={'CHECK' if CHECK else 'APPLY'} tag={TAG}")
    # osfmk: append helper at end of file (anchor is the final return/brace)
    with open(OSFMK, "r", encoding="utf-8") as f:
        odata = f.read()
    if "star_msgprobe_turnstile_owner" in odata:
        print("[skip] osfmk: already applied")
    else:
        patch(OSFMK, OSFMK_ANCHOR, OSFMK_ANCHOR + OSFMK_ADD, "osfmk")
    patch(BSD, BSD_DECL_ANCHOR, BSD_DECL_ADD, "bsd-decl")
    patch(BSD, BSD_CALL_ANCHOR, BSD_CALL_ADD, "bsd-call")
    print("done")


if __name__ == "__main__":
    main()
