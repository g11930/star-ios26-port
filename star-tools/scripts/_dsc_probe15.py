#!/usr/bin/env python3
"""Read each subcache's own dyld_cache_mapping_info (@0x228) and build the
full VM -> (file, offset) map.  Validate the bbd stub location."""
import glob
import os
import re
import struct

D = "/root/dsc26/System/Library/Caches/com.apple.dyld"
BASE = 0x180000000
files = sorted(p for p in glob.glob(D + "/dyld_shared_cache_arm64e.*")
    if re.search(r"dyld_shared_cache_arm64e\.\d+$", p))


def u64(f, o):
    f.seek(o)
    return struct.unpack("<Q", f.read(8))[0]


table = []
for p in files:
    sz = os.path.getsize(p)
    with open(p, "rb") as f:
        addr = u64(f, 0x228)
        size = u64(f, 0x230)
        foff = u64(f, 0x238)
    table.append((addr, size, foff, p, sz))

table.sort()
for addr, size, foff, p, sz in table[:6]:
    print(f"{os.path.basename(p):30s} addr=0x{addr:x} size=0x{size:x} "
        f"fileOff=0x{foff:x} filesize=0x{sz:x}")
print("...")
# coverage of the whole space
prev_end = None
gaps = 0
for addr, size, foff, p, sz in table:
    if prev_end is not None and addr != prev_end:
        print(f"GAP: prev_end 0x{prev_end:x} != addr 0x{addr:x}")
        gaps += 1
    prev_end = addr + size
print(f"coverage: gaps={gaps} end=0x{prev_end:x}")


def vm_to_file(vm):
    for addr, size, foff, p, sz in table:
        if addr <= vm < addr + size:
            return p, foff + (vm - addr)
    return None, None


for name, vm in (("bbd stub pc-8", 0x1BD7B1CCC),
                 ("libobjc", 0x1800EA000),
                 ("ld214 sigsuspend caller", 0x1BD7B1CD8)):
    p, off = vm_to_file(vm)
    if p:
        with open(p, "rb") as f:
            f.seek(off)
            d = f.read(16)
        print(f"{name}: vm 0x{vm:x} -> {os.path.basename(p)}+0x{off:x}: "
            f"{d.hex()}")
    else:
        print(f"{name}: vm 0x{vm:x} UNMAPPED")
