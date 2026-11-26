#!/usr/bin/env python3
"""
s70: print the full port's imq_receiver_name so we can compare it against
launchd's receive-loop rcv name (d5a00000000).  If equal -> launchd IS
receiving this port yet messages are not consumed (receive-path issue); if
different -> the full port is not in launchd's receive set.

Adds 'recv_name' to struct star_msgprobe_peer in BOTH TUs, fills it under the
port lock, prints it in the TURNSTILE-PORT line.
Read-only, log-only, idempotent, backed up, strict anchors.
Usage: python3 apply-recvname-probe.py [--check]
"""
import os
import shutil
import sys

K = "/root/star26/star-native/osfmk/kern/star_msgprobe_k.c"
B = "/root/star26/star-native/bsd/dev/star/star_msgprobe.c"
CHECK = "--check" in sys.argv

OLD_FIELD = "	unsigned int  kmsg_ids[8];  /* s69: msgh_id of queued kmsgs, 0 = empty slot */\n};"
NEW_FIELD = ("	unsigned int  kmsg_ids[8];  /* s69: msgh_id of queued kmsgs, 0 = empty slot */\n"
             "	unsigned int  recv_name;    /* s70: port->ip_messages.imq_receiver_name */\n};")

OLD_READ = """	out->queue_state = ((unsigned long)port->ip_messages.imq_qlimit << 16) |
	    (unsigned long)port->ip_messages.imq_msgcount;
	/* s69:"""
NEW_READ = """	out->queue_state = ((unsigned long)port->ip_messages.imq_qlimit << 16) |
	    (unsigned long)port->ip_messages.imq_msgcount;
	out->recv_name = (unsigned int)port->ip_messages.imq_receiver_name;
	/* s69:"""

OLD_PRINT = """						    tpeer.queue_state & 0xfffful,
						    (tpeer.queue_state >> 16) & 0xfffful);
						IOLog("StarMsgProbe:     queued-ids=%u,%u,%u,%u,%u,%u","""
NEW_PRINT = """						    tpeer.queue_state & 0xfffful,
						    (tpeer.queue_state >> 16) & 0xfffful);
						IOLog("StarMsgProbe:     recv_name=0x%x",
						    tpeer.recv_name);
						IOLog("StarMsgProbe:     queued-ids=%u,%u,%u,%u,%u,%u","""

PATCHES = [
    (K, "k-field", OLD_FIELD, NEW_FIELD),
    (K, "k-read",  OLD_READ,  NEW_READ),
    (B, "b-field", OLD_FIELD, NEW_FIELD),
    (B, "b-print", OLD_PRINT, NEW_PRINT),
]


def main():
    print(f"mode={'CHECK' if CHECK else 'APPLY'}")
    for path, label, old, new in PATCHES:
        with open(path, "r", encoding="utf-8") as f:
            data = f.read()
        if "recv_name" in data and label in ("k-field", "b-field"):
            print(f"[skip] {label}: already applied")
            continue
        cnt = data.count(old)
        if cnt != 1:
            print(f"[FAIL] {label}: anchor count={cnt} (need 1)")
            sys.exit(2)
        if CHECK:
            print(f"[check OK] {label}")
            continue
        bak = path + ".s70.bak"
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
