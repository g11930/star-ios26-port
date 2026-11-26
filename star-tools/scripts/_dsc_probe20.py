#!/usr/bin/env python3
"""Authoritative stub-VM computation and R derivation."""
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


entries = []       # (addr, size, foff, file, file_size)
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
            if addr and size and foff + size <= sz:
                entries.append((addr, size, foff, p, sz))
entries.sort()

# 1. byte-search for the stub pattern
PAT = bytes.fromhex("d0058092011000d4")
hits = []
for p in files:
    data = open(p, "rb").read()
    i = 0
    while True:
        i = data.find(PAT, i)
        if i < 0:
            break
        # which entry of this file contains file offset i?
        for addr, size, foff, pf, sz2 in entries:
            if pf == p and foff <= i < foff + size:
                vm = addr + (i - foff)
                hits.append((vm, p, i))
        i += 1

print("stub pattern VMs:")
for vm, p, i in hits:
    print(f"  vm 0x{vm:x}  ({os.path.basename(p)} file-off 0x{i:x})")

# 2. R candidates for the bbd fr0 = 0x3d7b1cd4 (pc = mov vm + 8)
fr = 0x3D7B1CD4
for vm, p, i in hits:
    R = vm + 8 - fr
    match = [a for a, s, f, pf, sz2 in entries if a == R]
    print(f"R = pc_vm-8+8-fr = 0x{R:x}  mapping-addr match: {bool(match)}"
        f"  (pc vm 0x{vm + 8:x})")
    # also test every bbd frame against this R
    frames = [0x3d7b522c, 0x3d7b5078, 0x5a4e9f18, 0x5a4df340, 0x5a4df90c,
        0x5a4de06c, 0x459e1664, 0x5a4ca010, 0x3d7b61e4, 0x7f33e438,
        0x7f33a8cc]
    vms = [R + f for f in frames]
    covered = 0
    for v in vms:
        for a, s, f2, pf, sz2 in entries:
            if a <= v < a + s:
                covered += 1
                break
    print(f"  other frames mapped under this R: {covered}/{len(frames)}")
