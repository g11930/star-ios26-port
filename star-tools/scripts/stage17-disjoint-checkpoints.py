#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
stage17 -- remove the checkpoint-number collision that invalidated every
"checkpoint 14" conclusion on this line.

Two different files call loader_checkpoint(14):
  osfmk/arm/arm_init.c:517      after rtclock_early_init(), VERY early
  bsd/kern/bsd_init.c:1201      immediately before load_init_program()

loader_checkpoint() compares loader_stub_slot[2] against n and jumps on the
FIRST match.  So "--checkpoint 14" always stopped in arm_init.c and the kernel
never reached bsd_init.  That is why s10/s20/s21 all reported 0 bytes of
kernel log: at that point nothing had written a line yet (not a broken ring).

Fix: move every bsd_init.c checkpoint into the disjoint 100+ range:
    7,8,9,10,11,12,13,14,15 -> 107,108,109,110,111,112,113,114,115
arm_init.c keeps 1..50 and arm_vm_init.c keeps 1, star_gate keeps 200+.
No other behavioural change.  Idempotent; --check is read-only.
"""
import io
import re
import sys

P = "/root/star26/star-native/bsd/kern/bsd_init.c"
PAT = re.compile(r"loader_checkpoint\((\d+)\)")


def main():
    s = io.open(P, encoding="utf-8", errors="surrogateescape").read()
    nums = sorted({int(m.group(1)) for m in PAT.finditer(s)})
    print("bsd_init.c checkpoints:", nums)

    if "--check" in sys.argv:
        ok = all(100 <= n < 200 for n in nums)
        print("CHECK", "PASS" if ok else "FAIL (collision with arm_init range remains)")
        return 0 if ok else 1

    if all(100 <= n < 200 for n in nums):
        print("already disjoint, nothing to do")
        return 0

    def bump(m):
        n = int(m.group(1))
        return "loader_checkpoint(%d)" % (n if n >= 100 else 100 + n)

    out = PAT.sub(bump, s)
    io.open(P, "w", encoding="utf-8", errors="surrogateescape").write(out)
    after = sorted({int(m.group(1)) for m in PAT.finditer(out)})
    print("bsd_init.c checkpoints now:", after)
    assert all(100 <= n < 200 for n in after)
    return 0


if __name__ == "__main__":
    sys.exit(main())
