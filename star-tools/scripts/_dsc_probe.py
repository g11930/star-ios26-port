#!/usr/bin/env python3
"""Probe the iOS 26 dyld shared cache header layout (main file + one subcache)."""
import struct
import sys

D = "/root/dsc26/System/Library/Caches/com.apple.dyld"
MAIN = D + "/dyld_shared_cache_arm64e"


def u32(b, o):
    return struct.unpack_from("<I", b, o)[0]


def u64(b, o):
    return struct.unpack_from("<Q", b, o)[0]


with open(MAIN, "rb") as f:
    h = f.read(0x1000)

print("magic:", h[:16])
print("words at 0x10..0x80:")
for o in range(0x10, 0x80, 8):
    print(f"  0x{o:03x}: 0x{u64(h, o):016x}  (u32 {u32(h, o):#x} / {u32(h, o + 4):#x})")

# scan for plausible dyld_cache_mapping_info triplets:
# {uint64 address (0x180000000-ish), uint64 size (GB-ish), uint64 fileOffset}
print("\nplausible mapping infos (addr in [0x100000000,0x800000000), size>=1MB):")
seen = set()
for o in range(0x20, 0x400 - 24, 8):
    a = u64(h, o)
    s = u64(h, o + 8)
    fo = u64(h, o + 16)
    if 0x100000000 <= a < 0x800000000 and s >= 0x100000:
        key = (a, s, fo)
        if key in seen:
            continue
        seen.add(key)
        print(f"  @0x{o:03x}: addr=0x{a:x} size=0x{s:x} fileOffset=0x{fo:x}")

# the header also lists subcache file names (subCacheFileNames offset)
print("\nstrings found in first 0x1000:")
for m in re.finditer(rb"dyld_shared_cache_arm64e[\w.]*", h):
    print(f"  @0x{m.start():03x}: {m.group().decode()}")
