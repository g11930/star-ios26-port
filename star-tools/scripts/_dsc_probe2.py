#!/usr/bin/env python3
"""Find the images table in the cache header and derive the vm->file constant."""
import glob
import os
import struct
import sys

D = "/root/dsc26/System/Library/Caches/com.apple.dyld"
MAIN = D + "/dyld_shared_cache_arm64e"


def u32(b, o):
    return struct.unpack_from("<I", b, o)[0]


def u64(b, o):
    return struct.unpack_from("<Q", b, o)[0]


hdr = open(MAIN, "rb").read(0x4000)

# find the images table: runs of 16-byte entries {u32 pathOffset (points to
# a path string in the header), u32 fileOffset (< total), u32, u32}
files = sorted(glob.glob(D + "/dyld_shared_cache_arm64e*"),
    key=lambda p: (len(p), p))
total = sum(os.path.getsize(p) for p in files)
print("files:", len(files), "total:", total)

best = None
for start in range(0x20, 0x4000, 4):
    ok = 0
    for i in range(80):
        o = start + i * 16
        po = u32(hdr, o)
        fo = u32(hdr, o + 4)
        if 0x100 < po < 0x4000 and fo < total:
            e = hdr.find(b"\0", po, po + 200)
            if e > 0 and hdr[po:po + 6] == b"/Syste":
                ok += 1
    if ok > 60:
        best = start
        break

if best is None:
    print("no image table found in header")
    sys.exit(1)

n = 0
o = best
imgs = []
while True:
    po = u32(hdr, o)
    fo = u32(hdr, o + 4)
    if po >= 0x4000 or fo >= total:
        break
    e = hdr.find(b"\0", po, po + 200)
    path = hdr[po:e].decode("utf-8", "replace")
    imgs.append((fo, path))
    o += 16
    n += 1
print(f"images: {n} at 0x{best:x}")
for fo, path in imgs[:6]:
    print(f"  file@0x{fo:x}  {path}")

# derive K = vmaddr - fileoff from the first image's __TEXT
fo, path = imgs[0]
# find which physical file holds global offset fo
acc = 0
for p in files:
    sz = os.path.getsize(p)
    if acc <= fo < acc + sz:
        break
    acc += sz
with open(p, "rb") as f:
    f.seek(fo - acc)
    m = f.read(0x400)
assert m[:4] == b"\xcf\xfa\xed\xfe", m[:8].hex()
nc = u32(m, 16)
o = 32
vm = None
for _ in range(nc):
    cmd, sz = u32(m, o), u32(m, o + 4)
    if cmd == 0x19:  # LC_SEGMENT_64
        seg = m[o + 8:o + 24].split(b"\0")[0].decode()
        if seg == "__TEXT":
            vm = u64(m, o + 16)
    o += sz
print(f"first image {path}: __TEXT vmaddr=0x{vm:x} file=0x{fo:x} K=0x{vm - fo:x}")
