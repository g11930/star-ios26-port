#!/usr/bin/env python3
"""Validate the vm->global-file mapping hypotheses."""
import glob
import os
import struct

D = "/root/dsc26/System/Library/Caches/com.apple.dyld"
files = sorted(glob.glob(D + "/dyld_shared_cache_arm64e*"),
    key=lambda p: (len(p), p))
ranges = []
acc = 0
for p in files:
    sz = os.path.getsize(p)
    ranges.append((acc, acc + sz, p))
    acc += sz


def read_at(goff, n):
    for a, b, p in ranges:
        if a <= goff < b:
            with open(p, "rb") as f:
                f.seek(goff - a)
                return f.read(n)
    return None


def vmfile(vm):
    # candidate A: global = 0x20000000 + (vm - 0x180000000)
    a = 0x20000000 + (vm - 0x180000000)
    # candidate B: global = vm - 0x180000000
    b = vm - 0x180000000
    # candidate C: global = vm
    return a, b, vm


# 1) libobjc vmaddr should show a Mach-O magic under one candidate
for cand, goff in zip("ABC", vmfile(0x1800ea000)):
    d = read_at(goff, 4)
    print(f"libobjc cand {cand}: global 0x{goff:x} -> {d.hex() if d else None}")

# 2) stub bytes at vm 0x1BD7B1CCC-8 (bbd T#0 mov x16,#-46; svc)
stub_vm = 0x180000000 + 0x3d7b1cc4
for cand, goff in zip("ABC", vmfile(stub_vm)):
    d = read_at(goff, 8)
    print(f"stub   cand {cand}: global 0x{goff:x} -> {d.hex() if d else None}")
print("expect: d0058092 d4001001 ->", "928005d0 d4001001".replace(" ", ""))
