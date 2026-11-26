#!/usr/bin/env python3
"""Which Mach-O image of the iOS 26 cache contains an address, and what is its path?"""
import struct
import glob
import os
import sys

D = "/root/dsc26/System/Library/Caches/com.apple.dyld"
MAIN = D + "/dyld_shared_cache_arm64e"
files = sorted(glob.glob(D + "/dyld_shared_cache_arm64e*"))
ADDR = int(sys.argv[1], 0) if len(sys.argv) > 1 else 0x01906a6250

def u32(b, o):
    return struct.unpack_from("<I", b, o)[0]

def u64(b, o):
    return struct.unpack_from("<Q", b, o)[0]

# mapping tables
maps = []
for p in files:
    with open(p, "rb") as f:
        h = f.read(0x400)
    if b"dyld_v1" not in h[:16]:
        continue
    mo = u32(h, 0x10)
    maps.append((u64(h, mo), u64(h, mo + 8), p))

owner = None
for base, size, p in maps:
    if base <= ADDR < base + size:
        owner = (p, ADDR - base)
print("owner file:", os.path.basename(owner[0]), "offset %#x" % owner[1])

data = open(owner[0], "rb").read()

best = None
i = data.find(b"\xcf\xfa\xed\xfe")
while i >= 0:
    if i + 0x40 <= len(data):
        ncmds = u32(data, i + 0x10)
        o = i + 0x20
        vmaddr = vmsize = None
        for _ in range(min(ncmds, 64)):
            cmd, csz = struct.unpack_from("<II", data, o)
            if cmd == 0x19:
                sa, ss = struct.unpack_from("<QQ", data, o + 24)
                if sa <= ADDR < sa + ss and i <= owner[1]:
                    vmaddr, vmsize = sa, ss
                    break
            if csz == 0:
                break
            o += csz
        if vmaddr is not None and i <= owner[1]:
            if best is None or vmaddr >= best[0]:
                best = (vmaddr, vmsize, i)
    i = data.find(b"\xcf\xfa\xed\xfe", i + 4)

print("containing image: vmaddr=%#x vmsize=%#x headerfile=%#x" % best)

# find its path in the main image-info array
main = open(MAIN, "rb").read()
needle = struct.pack("<Q", best[0])
pos = 0
paths = []
while True:
    pos = main.find(needle, pos)
    if pos < 0:
        break
    po = u32(main, pos + 0x18)
    if 0x400 < po < len(main):
        raw = main[po:po + 300].split(b"\x00")[0]
        if raw.startswith(b"/"):
            paths.append(raw.decode("latin1"))
    pos += 8
print("paths:", paths[:5])
