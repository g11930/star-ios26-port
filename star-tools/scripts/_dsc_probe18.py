#!/usr/bin/env python3
"""Dump image-table entries around libsystem_kernel; sanity-check vmaddr."""
import struct

D = "/root/dsc26/System/Library/Caches/com.apple.dyld"
hdr = open(D + "/dyld_shared_cache_arm64e", "rb").read(0x98000)


def u32(b, o):
    return struct.unpack_from("<I", b, o)[0]


def u64(b, o):
    return struct.unpack_from("<Q", b, o)[0]


o = 0x2B0
for i in range(0x228):
    po = u32(hdr, o)
    vm = u64(hdr, o + 8)
    if po:
        e = hdr.find(b"\0", po, po + 250)
        path = hdr[po:e].decode("utf-8", "replace")
        if "libsystem_kernel" in path or "libsystem_c.dylib" in path \
                or "libdispatch" in path or "libxpc" in path \
                or i < 3 or i > 549:
            print(f"{i:3d} vm=0x{vm:x}  {path}")
    o += 32
