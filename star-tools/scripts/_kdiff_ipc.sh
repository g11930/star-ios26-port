#!/bin/bash
# diff our kernel's IPC-critical files vs the ref2 warsaw v102 kernel tree
OURS=/root/star26/star-native
THEIRS=/root/ref2/warsaw-xnu-kernel-RedmiK90Ultra/xnu
for f in \
    osfmk/ipc/ipc_mqueue.c \
    osfmk/ipc/ipc_kmsg.c \
    osfmk/ipc/ipc_port.c \
    osfmk/ipc/ipc_pset.c \
    osfmk/ipc/ipc_space.c \
    osfmk/ipc/ipc_entry.c \
    osfmk/ipc/ipc_right.c \
    osfmk/kern/ipc_tt.c \
    osfmk/kern/turnstile.c \
    osfmk/kern/sched_prim.c \
    osfmk/kern/thread.c \
    osfmk/kern/waitq.c \
    osfmk/kern/semaphore.c \
    osfmk/kern/ipc_kobject.c \
    osfmk/kern/mach_port.c \
    osfmk/ipc/ipc_policy.c \
    ; do
    if [ -f "$THEIRS/$f" ]; then
        n=$(diff "$OURS/$f" "$THEIRS/$f" 2>/dev/null | grep -c '^[<>]')
        echo "$n  $f"
    else
        echo "MISSING-in-theirs  $f"
    fi
done | sort -rn
