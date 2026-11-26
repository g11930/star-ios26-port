#!/usr/bin/env python3
"""Which image in the iOS 26 cache holds the AppleCLCD display class?"""
import struct
import glob
import os

D = "/root/dsc26/System/Library/Caches/com.apple.dyld"
MAIN = D + "/dyld_shared_cache_arm64e"
files = sorted(glob.glob(D + "/dyld_shared_cache_arm64e*"))

with open(MAIN, "rb") as f:
    main = f.read()

def u32(b, o):
    return struct.unpack_from("<I", b, o)[0]

def u64(b, o):
    return struct.unpack_from("<Q", b, o)[0]

# ---- image info array: find contiguous 32-byte records ----
def rec_ok(o):
    if o + 32 > len(main):
        return None
    addr = u64(main, o)
    po = u32(main, o + 0x18)
    if not (0x180000000 <= addr < 0x200000000):
        return None
    if not (0x400 < po < len(main)):
        return None
    raw = main[po:po + 256].split(b"\x00")[0]
    if not raw.startswith(b"/") or len(raw) < 6:
        return None
    return (addr, raw.decode("latin1"))

# walk left from the known QuartzCore record
start = 0x438
while rec_ok(start - 32):
    start -= 32
print("array starts at %#x" % start)
imgs = []
o = start
while rec_ok(o):
    imgs.append((rec_ok(o)[0], rec_ok(o)[1]))
    o += 32
print("images:", len(imgs))

# ---- mappings: address -> file offset ----
maps = []
for p in files:
    with open(p, "rb") as f:
        h = f.read(0x400)
    if b"dyld_v1" not in h[:16]:
        continue
    mo = u32(h, 0x10)
    base = u64(h, mo)
    size = u64(h, mo + 8)
    maps.append((base, size, p))

def locate(addr):
    for base, size, p in maps:
        if base <= addr < base + size:
            return p, addr - base
    return None, None

# ---- find AppleCLCD string addresses in every file, then the owning image ----
targets = []
for p in files:
    size = os.path.getsize(p)
    with open(p, "rb") as f:
        d = f.read()
    i = d.find(b"AppleCLCD\x00")
    if i < 0:
        continue
    base = None
    for b, s, pp in maps:
        if pp == p:
            base = b
            break
    targets.append((p, i, base + i))
    print("%s: 'AppleCLCD' @file %#x addr %#012x" % (os.path.basename(p), i, base + i))

def text_range(addr):
    p, off = locate(addr)
    if p is None:
        return None
    with open(p, "rb") as f:
        f.seek(off)
        mh = f.read(0x40)
    if mh[:4] != b"\xcf\xfa\xed\xfe":
        return None
    ncmds = u32(mh, 0x10)
    f.seek(off + (0x20 if True else 0x1c))
    data = f.read(ncmds * 100 + 0x40)
    o = 0
    for _ in range(ncmds):
        cmd, csz = struct.unpack_from("<II", data, o)
        if cmd == 0x19:
            vmaddr, vmsize = struct.unpack_from("<QQ", data, o + 24)
            return vmaddr, vmsize
        o += csz
    return None

for p, i, a in targets:
    print("\nsearching owner of %#x" % a)
    best = None
    for addr, path in imgs:
        if addr <= a and (best is None or addr > best[0]):
            best = (addr, path)
    print("   nearest image: %#x %s" % best)
    tr = text_range(best[0])
    print("   its __TEXT: %s   contains=%s" % (tr, bool(tr and tr[0] <= a < tr[0] + tr[1])))
