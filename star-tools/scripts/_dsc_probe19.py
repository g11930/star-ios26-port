#!/usr/bin/env python3
"""Scan the main header for dyld_cache_image_text_info entries
{uuid[16], loadAddress u64, textSize u32, pathOffset u32} (36 bytes)."""
import struct

D = "/root/dsc26/System/Library/Caches/com.apple.dyld"
MAIN = D + "/dyld_shared_cache_arm64e"
hdr = open(MAIN, "rb").read(0x98000)


def u32(b, o):
    return struct.unpack_from("<I", b, o)[0]


def u64(b, o):
    return struct.unpack_from("<Q", b, o)[0]


def path_at(po):
    if not 0x40000 <= po < 0x98000:
        return None
    e = hdr.find(b"\0", po, po + 250)
    if e <= po:
        return None
    s = hdr[po:e]
    return s.decode("utf-8", "replace") if s.startswith(b"/") else None


best = None
for stride in (36, 40, 32, 44, 48):
    for start in range(0x20, 0x30000, 4):
        ok = 0
        for i in range(80):
            o = start + i * stride
            if o + stride > len(hdr):
                break
            la = u64(hdr, o + 16)
            ts = u32(hdr, o + 24)
            p = path_at(u32(hdr, o + 28))
            if 0x180000000 <= la < 0x2C4000000 and 0 < ts < 0x2000000 \
                    and p is not None:
                ok += 1
        if ok > 300 and (best is None or ok > best[0]):
            best = (ok, stride, start)

if best:
    ok, stride, start = best
    print(f"FOUND stride={stride} start=0x{start:x} count~{ok}")
    for i in range(3):
        o = start + i * stride
        la = u64(hdr, o + 16)
        ts = u32(hdr, o + 24)
        p = path_at(u32(hdr, o + 28))
        print(f"  la=0x{la:x} ts=0x{ts:x} {p}")
else:
    print("no image_text_info table found")
