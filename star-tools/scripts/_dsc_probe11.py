#!/usr/bin/env python3
"""Corrected validation: global = (vm - 0x180000000) + 0x4000 (past main's
0x94000-VM-span but 0x98000 file size), main file covers first 0x94000."""
import glob
import os

D = "/root/dsc26/System/Library/Caches/com.apple.dyld"
files = sorted(glob.glob(D + "/dyld_shared_cache_arm64e*"),
    key=lambda p: (len(p), p))
ranges = []
acc = 0
for p in files:
    sz = os.path.getsize(p)
    ranges.append((acc, acc + sz, p))
    acc += sz

BASE = 0x180000000


def read_at(goff, n):
    for a, b, p in ranges:
        if a <= goff < b:
            with open(p, "rb") as f:
                f.seek(goff - a)
                return f.read(n)
    return None


def global_off(vm):
    rel = vm - BASE
    return rel + (0x4000 if rel >= 0x94000 else 0)


# stub bytes: bbd T#0 mov x16,#-46 at vm pc-8
for off, expect in ((0x3d7b1ccc, "928005d0d4001001"),
                    (0x3d7b61dc, None), (0x3d7b1cbc, None)):
    vm = BASE + off
    g = global_off(vm)
    d = read_at(g, 8)
    print(f"vm 0x{vm:x} -> global 0x{g:x}: {d.hex() if d else None}",
          f"(expect {expect})" if expect else "")

# libobjc Mach-O magic
g = global_off(0x1800ea000)
print(f"libobjc vm 0x1800ea000 -> global 0x{g:x}: "
    f"{read_at(g, 4).hex() if read_at(g, 4) else None} (expect cffaedfe)")
