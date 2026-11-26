#!/usr/bin/env python3
"""
s69: extend the imq probe to dump the msgh_id of the messages stuck in the
full SERVICE_PORT queue.  s68 proved imq=6/6; now we see WHAT is stuck.

Adds 'kmsg_ids[8]' to struct star_msgprobe_peer in BOTH TUs, fills it by
walking port->ip_messages.imq_messages under the port lock via
ipc_kmsg_queue_first/next + ikm_header(), prints on bsd side.

Read-only, log-only, idempotent, backed up, strict anchors.
Usage: python3 apply-kmsg-dump.py [--check]
"""
import os
import shutil
import sys

K = "/root/star26/star-native/osfmk/kern/star_msgprobe_k.c"
B = "/root/star26/star-native/bsd/dev/star/star_msgprobe.c"
CHECK = "--check" in sys.argv

OLD_FIELD = "	unsigned long queue_state; /* s68: low16=imq_msgcount, high16=imq_qlimit */\n};"
NEW_FIELD = ("	unsigned long queue_state; /* s68: low16=imq_msgcount, high16=imq_qlimit */\n"
             "	unsigned int  kmsg_ids[8];  /* s69: msgh_id of queued kmsgs, 0 = empty slot */\n};")

OLD_INIT = "	out->queue_state = 0;\n"
NEW_INIT = "	out->queue_state = 0;\n	memset(out->kmsg_ids, 0, sizeof(out->kmsg_ids));\n"

OLD_READ = """	out->queue_state = ((unsigned long)port->ip_messages.imq_qlimit << 16) |
	    (unsigned long)port->ip_messages.imq_msgcount;
	if (!io_state_active(io->io_state)) {"""
NEW_READ = """	out->queue_state = ((unsigned long)port->ip_messages.imq_qlimit << 16) |
	    (unsigned long)port->ip_messages.imq_msgcount;
	/* s69: walk up to 8 queued messages, record msgh_id (port lock held). */
	{
		ipc_kmsg_t km = ipc_kmsg_queue_first(&port->ip_messages.imq_messages);
		int slot = 0;

		while (km != IKM_NULL && slot < 8) {
			out->kmsg_ids[slot++] = (unsigned int)ikm_header(km)->msgh_id;
			km = ipc_kmsg_queue_next(&port->ip_messages.imq_messages, km);
		}
	}
	if (!io_state_active(io->io_state)) {"""

OLD_PRINT = """						    star_msgprobe_iot_name(tpeer.iotype),
						    tpeer.queue_state & 0xfffful,
						    (tpeer.queue_state >> 16) & 0xfffful);
						star_msgprobe_peer(&tpeer);"""
NEW_PRINT = """						    star_msgprobe_iot_name(tpeer.iotype),
						    tpeer.queue_state & 0xfffful,
						    (tpeer.queue_state >> 16) & 0xfffful);
						IOLog("StarMsgProbe:     queued-ids=%u,%u,%u,%u,%u,%u",
						    tpeer.kmsg_ids[0], tpeer.kmsg_ids[1],
						    tpeer.kmsg_ids[2], tpeer.kmsg_ids[3],
						    tpeer.kmsg_ids[4], tpeer.kmsg_ids[5]);
						star_msgprobe_peer(&tpeer);"""

PATCHES = [
    (K, "k-field", OLD_FIELD, NEW_FIELD),
    (K, "k-init",  OLD_INIT,  NEW_INIT),
    (K, "k-read",  OLD_READ,  NEW_READ),
    (B, "b-field", OLD_FIELD, NEW_FIELD),
    (B, "b-print", OLD_PRINT, NEW_PRINT),
]


def main():
    print(f"mode={'CHECK' if CHECK else 'APPLY'}")
    for path, label, old, new in PATCHES:
        with open(path, "r", encoding="utf-8") as f:
            data = f.read()
        if "kmsg_ids" in data and label in ("k-field", "b-field"):
            print(f"[skip] {label}: already applied")
            continue
        cnt = data.count(old)
        if cnt != 1:
            print(f"[FAIL] {label}: anchor count={cnt} (need 1)")
            sys.exit(2)
        if CHECK:
            print(f"[check OK] {label}")
            continue
        bak = path + ".s69.bak"
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
