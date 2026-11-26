#!/usr/bin/env python3
"""Probe a subcache file's header for the images table + path strings."""
import glob
import re
import struct

D = "/root/dsc26/System/Library/Caches/com.apple.dyld"
files = sorted(glob.glob(D + "/dyld_shared_cache_arm64e*"),
    key=lambda p: (len(p), p))
p = D + "/dyld_shared_cache_arm64e.01"
hdr = open(p, "rb").read(0x8000)
print("file:", os.path.basename(p) if (os := __import__("os")) else "")
print("magic:", hdr[:16])


def u32(b, o):
    return struct.unpack_from("<I", b, o)[0]


def u64(b, o):
    return struct.unpack_from("<Q", b, o)[0]


for o in range(0x10, 0x100, 8):
    print(f"0x{o:03x}: 0x{u64(hdr, o):016x}")

for m in list(re.finditer(rb"/System/Library", hdr))[:6]:
    s = hdr[m.start():m.start() + 70].split(b"\0")[0].decode()
    print(f"path str @0x{m.start():x}: {s}")
