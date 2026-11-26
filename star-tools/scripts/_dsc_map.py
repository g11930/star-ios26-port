#!/usr/bin/env python3
"""Locate the QuartzCore image inside the iOS 26 dyld shared cache (main + subcaches)."""
import struct
import glob
import os

D = "/root/dsc26/System/Library/Caches/com.apple.dyld"
files = sorted(glob.glob(D + "/dyld_shared_cache_arm64e*"))
print("files:", len(files))

def u32(b, o):
    return struct.unpack_from("<I", b, o)[0]

def u64(b, o):
    return struct.unpack_from("<Q", b, o)[0]

for p in files:
    size = os.path.getsize(p)
    with open(p, "rb") as f:
        h = f.read(0x800)
    if b"dyld_v1" not in h[:16]:
        print(p, "no magic", h[:16])
        continue
    mo = u32(h, 0x10)
    mc = u32(h, 0x14)
    print("\n%s  size=%#x magic=%r mappingOff=%#x mappingCount=%d" % (os.path.basename(p), size, h[:16].decode("latin1"), mo, mc))
    for i in range(mc):
        o = mo + i * 32
        sa, sz, fo, msz, mxp, ip = struct.unpack_from("<QQQQII", h, o)
        print("   map%d addr=%#012x size=%#010x fileOff=%#010x maxprot=%d initprot=%d" % (i, sa, sz, fo, mxp, ip))
