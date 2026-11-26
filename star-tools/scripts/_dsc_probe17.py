#!/usr/bin/env python3
"""Compute true VMs of the stub-pattern hits via the per-file mapping table;
compare against thread_dump printed offsets."""
import glob
import os
import re
import struct

D = "/root/dsc26/System/Library/Caches/com.apple.dyld"
files = sorted(p for p in glob.glob(D + "/dyld_shared_cache_arm64e.*")
    if re.search(r"dyld_shared_cache_arm64e\.\d+$", p))


def u64(f, o):
    f.seek(o)
    return struct.unpack("<Q", f.read(8))[0]


table = []
for p in files:
    sz = os.path.getsize(p)
    if sz < 0x250:
        continue
    with open(p, "rb") as f:
        moff = u64(f, 0x10)
        mcnt = u64(f, 0x14) & 0xFFFFFFFF
        if moff == 0 or mcnt == 0 or mcnt > 16 or moff + mcnt * 24 + 8 > sz:
            moff, mcnt = 0x228, 1
        for i in range(mcnt):
            addr = u64(f, moff + i * 24)
            size = u64(f, moff + i * 24 + 8)
            foff = u64(f, moff + i * 24 + 16)
            if addr and size:
                table.append((addr, size, foff, p))

# forward: file-offset hit -> vm
acc = 0
file_ranges = []
for p in files:
    sz = os.path.getsize(p)
    file_ranges.append((acc, acc + sz, p))
    acc += sz


def hit_vm(goff):
    for a, b, p in file_ranges:
        if a <= goff < b:
            in_file = goff - a
            for addr, size, foff, mp in table:
                if mp == p and foff <= in_file < foff + size:
                    return addr + (in_file - foff), mp
            return None, p
    return None, None


for g, expect_printed in ((0x128cbc, None), (0x8e625ccc, 0x3d7b1cd4)):
    vm, p = hit_vm(g)
    s = f"hit g=0x{g:x} ({os.path.basename(p)}) -> vm 0x{vm:x}" if vm else \
        f"hit g=0x{g:x} -> NO MAPPING"
    if vm:
        s += f"  printed 0x{expect_printed:x}  delta=0x{vm - 0x180000000 - expect_printed:x}" \
            if expect_printed else ""
    print(s)
