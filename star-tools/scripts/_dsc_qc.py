#!/usr/bin/env python3
"""Find QuartzCore's image info in the dyld shared cache and write out its Mach-O."""
import struct
import glob
import os
import sys

D = "/root/dsc26/System/Library/Caches/com.apple.dyld"
MAIN = D + "/dyld_shared_cache_arm64e"
NEEDLE = b"/System/Library/Frameworks/QuartzCore.framework/QuartzCore\x00"

files = sorted(glob.glob(D + "/dyld_shared_cache_arm64e*"))


def u32(b, o):
    return struct.unpack_from("<I", b, o)[0]


def u64(b, o):
    return struct.unpack_from("<Q", b, o)[0]


# 1) which file holds the path string, at what offset
hits = []
for p in files:
    with open(p, "rb") as f:
        data = f.read()
    i = data.find(NEEDLE)
    if i >= 0:
        hits.append((p, i, data[i:i + len(NEEDLE) - 1].decode()))

print("path string hits:")
for h in hits:
    print("   %s @ %#x  %s" % (os.path.basename(h[0]), h[1], h[2]))

if not hits:
    sys.exit("no path string")

# 2) image infos live in the main file; scan for records whose pathFileOffset == hit offset
with open(MAIN, "rb") as f:
    main_data = f.read()

img = None
for hit_off in {h[1] for h in hits}:
    for o in range(0x400, len(main_data) - 32, 8):
        addr = u64(main_data, o)
        po = u32(main_data, o + 0x18)
        if po == hit_off and 0x180000000 <= addr < 0x200000000:
            img = (addr, o)
            print("image info: addr=%#012x record@%#x" % (addr, o))
            break
    if img:
        break

if not img:
    sys.exit("no image info record found")

addr = img[0]

# 3) map address -> (file, offset)
seg = None
for p in files:
    with open(p, "rb") as f:
        h = f.read(0x400)
    mo = u32(h, 0x10)
    base = u64(h, mo)
    size = u64(h, mo + 8)
    if base <= addr < base + size:
        seg = (p, addr - base, base, size)
        break

if not seg:
    sys.exit("address not in any mapping")

p, off, base, size = seg
print("mapped: %s + %#x (base %#012x)" % (os.path.basename(p), off, base))

with open(p, "rb") as f:
    f.seek(off)
    mh = f.read(0x40)

print("mach-o magic:", mh[:8].hex())
magic = struct.unpack_from("<I", mh, 0)[0]
print("magic32=%#x ncmds=%d sizeofcmds=%#x" % (magic, u32(mh, 0x10), u32(mh, 0x14)))

# 4) walk load commands for segments
ncmds = u32(mh, 0x10)
with open(p, "rb") as f:
    f.seek(off)
    full = f.read(size - off)
cmds = 0x20 if magic == 0xfeedfacf else 0x1C
segs = []
o = cmds
for _ in range(ncmds):
    cmd, csz = struct.unpack_from("<II", full, o)
    if cmd == 0x19:  # LC_SEGMENT_64
        name = full[o + 8:o + 8 + 16].rstrip(b"\x00").decode()
        vmaddr, vmsize, fileoff, filesize = struct.unpack_from("<QQQQ", full, o + 24)
        segs.append((name, vmaddr, vmsize, fileoff, filesize))
    o += csz

print("segments:")
for s in segs:
    print("   %-16s vmaddr=%#012x vmsize=%#010x fileoff=%#010x filesize=%#010x" % s)

with open("/root/qc26.bin", "wb") as f:
    f.write(full)
print("wrote /root/qc26.bin (%d bytes)" % len(full))
print("image base %#x" % addr)
