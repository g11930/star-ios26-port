#!/usr/bin/env python3
"""Find the images table: try strides 16/24/32 with u32 or u64 file offsets."""
import glob
import os
import struct
import sys

D = "/root/dsc26/System/Library/Caches/com.apple.dyld"
MAIN = D + "/dyld_shared_cache_arm64e"

hdr = open(MAIN, "rb").read(0x10000)
files = sorted(glob.glob(D + "/dyld_shared_cache_arm64e*"),
    key=lambda p: (len(p), p))
total = sum(os.path.getsize(p) for p in files)


def u32(b, o):
    if o + 4 > len(b):
        return 0
    return struct.unpack_from("<I", b, o)[0]


def u64(b, o):
    if o + 8 > len(b):
        return 0
    return struct.unpack_from("<Q", b, o)[0]


def getpath(po):
    if not 0x100 < po < len(hdr) - 8:
        return None
    e = hdr.find(b"\0", po, po + 200)
    if e <= po:
        return None
    s = hdr[po:e]
    return s.decode("utf-8", "replace") if s.startswith(b"/") else None


for stride in (16, 24, 32, 20):
    for fooff in (4, 8):
        for start in range(0x20, 0x3000, 8):
            ok = 0
            for i in range(60):
                o = start + i * stride
                po = u32(hdr, o)
                path = getpath(po)
                if path is None:
                    break
                fo = u32(hdr, o + fooff) if fooff == 4 else u64(hdr, o + fooff)
                if fo >= total:
                    break
                ok += 1
            if ok > 50:
                print(f"FOUND stride={stride} fo@+{fooff} start=0x{start:x} "
                    f"count={ok}")
                o = start
                for i in range(3):
                    po = u32(hdr, o)
                    fo = (u32(hdr, o + fooff) if fooff == 4
                        else u64(hdr, o + fooff))
                    print(f"   {getpath(po)}  file@0x{fo:x}")
                    o += stride
                sys.exit(0)
print("none found")
