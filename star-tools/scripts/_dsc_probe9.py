#!/usr/bin/env python3
"""Dump full 32-byte image entries; find which field is the file offset
by checking for the Mach-O magic at candidate global offsets."""
import glob
import os
import struct

D = "/root/dsc26/System/Library/Caches/com.apple.dyld"
MAIN = D + "/dyld_shared_cache_arm64e"
files = sorted(glob.glob(D + "/dyld_shared_cache_arm64e*"),
    key=lambda p: (len(p), p))
ranges = []
acc = 0
for p in files:
    sz = os.path.getsize(p)
    ranges.append((acc, acc + sz, p))
    acc += sz

hdr = open(MAIN, "rb").read(0x98000)


def u32(b, o):
    return struct.unpack_from("<I", b, o)[0]


def u64(b, o):
    return struct.unpack_from("<Q", b, o)[0]


def read_at(goff, n):
    for a, b, p in ranges:
        if a <= goff < b:
            with open(p, "rb") as f:
                f.seek(goff - a)
                return f.read(n)
    return None


for i, o in enumerate(range(0x2b0, 0x2b0 + 32 * 6, 32)):
    po = u32(hdr, o)
    e = hdr.find(b"\0", po, po + 200)
    path = hdr[po:e].decode("utf-8", "replace")
    vals = [u32(hdr, o + 4 * k) for k in range(8)]
    print(f"{i} {path}")
    print("   u32:", " ".join(f"{v:#x}" for v in vals))
    for fooff in (4, 8, 12, 16, 20, 24, 28):
        fo = u64(hdr, o + fooff) & ((1 << 64) - 1)
        d = read_at(fo, 4) if fo < acc else None
        if d and d == b"\xcf\xfa\xed\xfe":
            print(f"   MACH-O at +{fooff} -> global 0x{fo:x}  ***")
