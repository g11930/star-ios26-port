#!/usr/bin/env python3
"""Full per-file mapping parse (mappingCount at 0x14, entries at 0x228)."""
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
        if moff == 0 or mcnt == 0 or mcnt > 16 or \
                moff + mcnt * 24 + 8 > sz:
            moff, mcnt = 0x228, 1
        for i in range(mcnt):
            addr = u64(f, moff + i * 24)
            size = u64(f, moff + i * 24 + 8)
            foff = u64(f, moff + i * 24 + 16)
            if addr and size:
                table.append((addr, size, foff, p))

table.sort()
prev = None
gaps = []
for addr, size, foff, p in table:
    if prev is not None and addr != prev:
        gaps.append((prev, addr))
    prev = addr + size
print(f"mappings: {len(table)}  gaps: {len(gaps)}")
for a, b in gaps:
    print(f"  gap 0x{a:x} .. 0x{b:x} ({b - a} bytes)")
print(f"end: 0x{prev:x}")


def vm_to_file(vm):
    for addr, size, foff, p in table:
        if addr <= vm < addr + size:
            return p, foff + (vm - addr)
    return None, None


for name, vm, expect in (
        ("libobjc", 0x1800EA000, "cffaedfe"),
        ("bbd stub pc-8", 0x1BD7B1CCC, "928005d0d4001001"),
        ("ld214 caller", 0x1BD7B1CD8, None),
        ("ld398 fr2-ish", 0x1BD7B1CD4, None)):
    p, off = vm_to_file(vm)
    if p:
        with open(p, "rb") as f:
            f.seek(off)
            d = f.read(16)
        mark = " ***" if expect and d[:4].hex() == expect else ""
        print(f"{name}: vm 0x{vm:x} -> {os.path.basename(p)}+0x{off:x}: "
            f"{d.hex()}{mark}")
    else:
        print(f"{name}: vm 0x{vm:x} UNMAPPED (gap)")
