#!/usr/bin/env python3
"""
s74c: final fix for the syscall-stub decode window.

s75 evidence: backboardd T#0 (which provably blocks in mach_msg2 -- the
kernel can NOT queue a pid_for_task MIG request on a service port) decoded
as -46 (pid_for_task) instead of -47 (mach_msg2_trap).  The kernel table
has pid_for_task right BEFORE mach_msg2_trap, so the scan found the
NEIGHBORING stub: the saved user pc must point AT the svc instruction
(not svc+4), leaving the executed stub's mov outside the s75 window.

Fix: read the 16-byte window ENDING AT pc INCLUSIVE
([pc-12, pc-8, pc-4, pc]).  This resolves both pc conventions:
  pc == svc      -> w[3]=svc, w[2]=mov        (i=2 pair)
  pc == svc+4    -> w[3]=ret/b, w[2]=svc, w[1]=mov  (i=1 pair)
and the scan picks the true pair in both cases.  Also print the raw words
on EVERY decode (matched or not) so the stub layout is verifiable from the
log alone.  Read-only, idempotent, backups, strict anchors.
Usage: python3 apply-syscallprobe3.py [--check]
"""
import os
import shutil
import sys

K = "/root/star26/star-native/osfmk/kern/star_msgprobe_k.c"
B = "/root/star26/star-native/bsd/dev/star/star_msgprobe.c"
CHECK = "--check" in sys.argv

K_OLD = '''\tmap = get_task_map(task);
\taddr = (pc - 16) & ~3ull;
\tif ((addr & 0xFFF) > 0xFFC) {
\t\t/* 16 bytes would straddle two pages; use 8 */
\t\taddr = (pc - 8) & ~3ull;
\t\tlen = 8;
\t}
\tkr = vm_map_copyin(map, (vm_offset_t)addr, len, FALSE, &copy);'''

K_NEW = '''\tmap = get_task_map(task);
\t/* window [pc-12 .. pc] INCLUSIVE: the saved user pc points at the
\t * svc itself on this kernel (s75: mach_msg2 decoded as its neighbor
\t * pid_for_task with the old [pc-16, pc-4] window), so the word at pc
\t * must be part of the scan. */
\taddr = (pc - 12) & ~3ull;
\tlen = 16;
\tkr = vm_map_copyin(map, (vm_offset_t)addr, len, FALSE, &copy);'''

B_OLD = '''\t\t\t\tif (skr == 0) {
\t\t\t\t\tIOLog("StarMsgProbe:     sc=%lld",
\t\t\t\t\t    sc);
\t\t\t\t} else {
\t\t\t\t\tIOLog("StarMsgProbe:     sc=? kr=%d "
\t\t\t\t\t    "w=%x,%x,%x,%x",
\t\t\t\t\t    skr, raw[0], raw[1], raw[2],
\t\t\t\t\t    raw[3]);
\t\t\t\t}'''

B_NEW = '''\t\t\t\tIOLog("StarMsgProbe:     sc=%lld kr=%d "
\t\t\t\t    "w=%x,%x,%x,%x",
\t\t\t\t    sc, skr, raw[0], raw[1], raw[2],
\t\t\t\t    raw[3]);'''

PATCHES = [
    (K, "k-window", K_OLD, K_NEW),
    (B, "b-print",  B_OLD, B_NEW),
]

SKIP_TOKEN = {
    "k-window": "pc - 12",
    "b-print":  "sc=%lld kr=%d",
}


def main():
    print(f"mode={'CHECK' if CHECK else 'APPLY'}")
    for path, label, old, new in PATCHES:
        with open(path, "r", encoding="utf-8") as f:
            data = f.read()
        if SKIP_TOKEN[label] in data:
            print(f"[skip] {label}: already applied")
            continue
        cnt = data.count(old)
        if cnt != 1:
            print(f"[FAIL] {label}: anchor count={cnt} (need 1)")
            sys.exit(2)
        if CHECK:
            print(f"[check OK] {label}")
            continue
        bak = path + ".s74c.bak"
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
