#!/usr/bin/env python3
"""Read the mappings region at the end of the main cache file."""
import struct

D = "/root/dsc26/System/Library/Caches/com.apple.dyld"
MAIN = D + "/dyld_shared_cache_arm64e"
with open(MAIN, "rb") as f:
    f.seek(0x94000)
    blob = f.read(0x4000)


def u32(b, o):
    return struct.unpack_from("<I", b, o)[0]


def u64(b, o):
    return struct.unpack_from("<Q", b, o)[0]


print("first 12 32-byte strides:")
for i in range(12):
    o = i * 32
    vals = [u32(blob, o + k * 4) for k in range(8)]
    print(f"  @{o:#05x}: " + " ".join(f"{v:#010x}" for v in vals))
