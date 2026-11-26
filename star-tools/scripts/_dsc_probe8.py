#!/usr/bin/env python3
"""Find the images entry table in the main header region [0x4000, 0x94000)."""
import struct

MAIN = "/root/dsc26/System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64e"
with open(MAIN, "rb") as f:
    hdr = f.read(0x98000)


def u32(b, o):
    return struct.unpack_from("<I", b, o)[0]


def u64(b, o):
    if o + 8 > len(b):
        return 0
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
for stride in (16, 24, 32, 20, 28):
    for fooff in (4, 8, 12, 16):
        for start in range(0x40, 0x40000, 8):
            ok = 0
            for i in range(120):
                o = start + i * stride
                p = path_at(u32(hdr, o))
                if p is None:
                    break
                fo = (u32(hdr, o + fooff) if fooff in (4, 12)
                    else u64(hdr, o + fooff))
                if fo > 5013223353:
                    break
                ok += 1
            if ok > 100 and (best is None or ok > best[0]):
                best = (ok, stride, fooff, start)
print("best:", best)
if best:
    ok, stride, fooff, start = best
    o = start
    for i in range(6):
        po = u32(hdr, o)
        fo = u32(hdr, o + fooff) if fooff in (4, 12) else u64(hdr, o + fooff)
        print(f"  entry@0x{o:x}: path={path_at(po)!r} file@0x{fo:x}")
        o += stride
