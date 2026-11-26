#!/usr/bin/env python3
"""
s68: extend the turnstile->port probe to dump the destination port's IPC
message-queue state (imq_msgcount / imq_qlimit).  backboardd is stuck in
waitq_assert_wait64(IPC_MQUEUE_FULL), so we must see whether the target port's
queue is actually full and what its qlimit is.

Read-only, log-only.  Adds one field 'queue_state' to struct
star_msgprobe_peer in BOTH TUs (must stay field-identical), fills it in the
osfmk helper while the port is locked, prints it on the bsd side.

  queue_state: bit 0-15 = imq_msgcount, bit 16-31 = imq_qlimit.

Idempotent, backed up, strict anchors.
Usage: python3 apply-imq-probe.py [--check]
"""
import os
import shutil
import sys

K = "/root/star26/star-native/osfmk/kern/star_msgprobe_k.c"
B = "/root/star26/star-native/bsd/dev/star/star_msgprobe.c"
CHECK = "--check" in sys.argv

# --- osfmk: struct field (both TUs) ---
K_STRUCT = """	unsigned iotype;     /* port's ipc_object_type_t, ~0u if unknown */
	unsigned long kobject;
};"""
K_STRUCT_NEW = """	unsigned iotype;     /* port's ipc_object_type_t, ~0u if unknown */
	unsigned long kobject;
	unsigned long queue_state; /* s68: low16=imq_msgcount, high16=imq_qlimit */
};"""

B_STRUCT = K_STRUCT
B_STRUCT_NEW = K_STRUCT_NEW

# --- osfmk: init field at helper top ---
K_INIT = """	out->iotype = ~0u;
	out->kobject = 0;

	thread_mtx_lock(th);
	waiting = (th->state & TH_WAIT) != 0;
	wq = th->waitq;
	thread_mtx_unlock(th);
	if (!waiting || wq.wq_q == NULL) {
		return -1;                      /* not waiting */
	}
	if (zone_id_for_element(wq.wq_q, sizeof(struct waitq)) !=
	    ZONE_ID_TURNSTILE) {"""
K_INIT_NEW = """	out->iotype = ~0u;
	out->kobject = 0;
	out->queue_state = 0;

	thread_mtx_lock(th);
	waiting = (th->state & TH_WAIT) != 0;
	wq = th->waitq;
	thread_mtx_unlock(th);
	if (!waiting || wq.wq_q == NULL) {
		return -1;                      /* not waiting */
	}
	if (zone_id_for_element(wq.wq_q, sizeof(struct waitq)) !=
	    ZONE_ID_TURNSTILE) {"""

# --- osfmk: read imq fields right after out->iotype while port locked ---
K_READ = """	out->iotype = (unsigned)io_type(io);
	if (!io_state_active(io->io_state)) {
		ipc_object_unlock(io);
		out->kind = 8;                  /* inactive port */
		return 0;
	}"""
K_READ_NEW = """	out->iotype = (unsigned)io_type(io);
	/* s68: snapshot the message queue while the port lock is held. */
	out->queue_state = ((unsigned long)port->ip_messages.imq_qlimit << 16) |
	    (unsigned long)port->ip_messages.imq_msgcount;
	if (!io_state_active(io->io_state)) {
		ipc_object_unlock(io);
		out->kind = 8;                  /* inactive port */
		return 0;
	}"""

# --- bsd: print queue_state in the TURNSTILE-PORT line ---
B_PRINT = """						IOLog("StarMsgProbe:   WAIT pc=%p "
						    "lr=%p TURNSTILE-PORT type=%s",
						    (void *)regs[3], (void *)regs[4],
						    star_msgprobe_iot_name(tpeer.iotype));
						star_msgprobe_peer(&tpeer);"""
B_PRINT_NEW = """						IOLog("StarMsgProbe:   WAIT pc=%p "
						    "lr=%p TURNSTILE-PORT type=%s "
						    "imq=%lu/%lu",
						    (void *)regs[3], (void *)regs[4],
						    star_msgprobe_iot_name(tpeer.iotype),
						    tpeer.queue_state & 0xfffful,
						    (tpeer.queue_state >> 16) & 0xfffful);
						star_msgprobe_peer(&tpeer);"""

PATCHES = [
    (K, "k-struct", K_STRUCT, K_STRUCT_NEW),
    (K, "k-init",   K_INIT,   K_INIT_NEW),
    (K, "k-read",   K_READ,   K_READ_NEW),
    (B, "b-struct", B_STRUCT, B_STRUCT_NEW),
    (B, "b-print",  B_PRINT,  B_PRINT_NEW),
]


def main():
    print(f"mode={'CHECK' if CHECK else 'APPLY'}")
    for path, label, old, new in PATCHES:
        with open(path, "r", encoding="utf-8") as f:
            data = f.read()
        if "s68" in data and label in ("k-struct", "b-struct"):
            print(f"[skip] {label}: already applied")
            continue
        cnt = data.count(old)
        if cnt != 1:
            print(f"[FAIL] {label}: anchor count={cnt} (need 1)")
            sys.exit(2)
        if CHECK:
            print(f"[check OK] {label}")
            continue
        bak = path + ".s68.bak"
        if not os.path.exists(bak):
            shutil.copy2(path, bak)
            print(f"[backup] {bak}")
        data = data.replace(old, new, 1)
        with open(path, "w", encoding="utf-8") as f:
            f.write(data)
        print(f"[patched] {label}")
    print("done")


if __name__ == "__main__":
    main()
