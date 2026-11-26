#!/usr/bin/env python3
"""
s85: make the probe safe against non-port ipc objects and freed elements.

s82 crash: star_msgprobe_waitq_owner+0xa4, far 0x2a2a014400000a1d.  Cause:
backboardd's new wait is a KQUEUE wait (the runloop sources) -- the kqueue's
waitq maps to a KOBJECT (IKOT_UKQUEUE), but the probe treated every
ZONE_ID_IPC_PORT/IPC_PORT_SET element as a port: ip_object_to_port ->
ip_receiver deref on kqueue fields -> abort on the poisoned/garbage pointer.

Fix (both waitq_owner and turnstile_owner): after
ipc_object_lock_allow_invalid, read io_type and only touch the port fields
(ip_receiver / imq_* / push_to_logd info) for the real port types
(IOT_PORT_SET..IOT_WEAK_REPLY_PORT).  KOBJECT types are reported safely
(iotype + "not a port") with the lock dropped.  A freed element's garbage
type also fails the range check -> safe bail.
Read-only, log-only, idempotent, backup, strict anchors.
Usage: python3 apply-probe-safe.py [--check]
"""
import os
import shutil
import sys

K = "/root/star26/star-native/osfmk/kern/star_msgprobe_k.c"
CHECK = "--check" in sys.argv

OLD_W = '''		ipc_object_t io = io_from_waitq(wq.wq_q);
		ipc_port_t port;
		ipc_space_t rs;

		if (!ipc_object_lock_allow_invalid(io)) {
			return -3;              /* freed or uninitialized */
		}
		port = ip_object_to_port(io);
		out->iotype = (unsigned)io_type(io);
		if (!io_state_active(io->io_state)) {
			ipc_object_unlock(io);
			out->kind = 8;          /* inactive port */
			return 0;
		}
		rs = port->ip_receiver;'''
NEW_W = '''		ipc_object_t io = io_from_waitq(wq.wq_q);
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
		rs = port->ip_receiver;'''

OLD_T = '''	out->iotype = (unsigned)io_type(io);
	/* s68: snapshot the message queue while the port lock is held. */
	out->queue_state = ((unsigned long)port->ip_messages.imq_qlimit << 16) |
	    (unsigned long)port->ip_messages.imq_msgcount;'''
NEW_T = '''	out->iotype = (unsigned)io_type(io);
	/* s85: only real port types carry imq_* fields (see waitq_owner). */
	if (out->iotype > IOT_WEAK_REPLY_PORT) {
		out->kind = 9;          /* not a port */
		ipc_object_unlock(io);
		return 0;
	}
	/* s68: snapshot the message queue while the port lock is held. */
	out->queue_state = ((unsigned long)port->ip_messages.imq_qlimit << 16) |
	    (unsigned long)port->ip_messages.imq_msgcount;'''

PATCHES = [
    ("waitq-owner", OLD_W, NEW_W),
    ("turnstile-owner", OLD_T, NEW_T),
]


def main():
    print(f"mode={'CHECK' if CHECK else 'APPLY'}")
    with open(K, "r", encoding="utf-8") as f:
        data = f.read()
    if "s85: a KOBJECT" in data:
        print("[skip] already applied")
        return
    changed = False
    for label, old, new in PATCHES:
        cnt = data.count(old)
        if cnt != 1:
            print(f"[FAIL] {label}: anchor count={cnt} (need 1)")
            sys.exit(2)
        if CHECK:
            print(f"[check OK] {label}")
            continue
        data = data.replace(old, new, 1)
        changed = True
    if CHECK:
        print("done")
        return
    if changed:
        bak = K + ".s85.bak"
        if not os.path.exists(bak):
            shutil.copy2(K, bak)
            print(f"[backup] {bak}")
        with open(K, "w", encoding="utf-8") as f:
            f.write(data)
        print("[patched] star_msgprobe_k.c")
    print("done")


if __name__ == "__main__":
    main()
