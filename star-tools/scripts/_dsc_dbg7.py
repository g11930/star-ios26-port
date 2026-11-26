#!/usr/bin/env python3
import struct
import sys
sys.path.insert(0, "/mnt/d/桌面/star26-deps/scripts")
from dscsym2 import R, mappings

VM = 0x1BE041F18
print("covering mapping:")
for addr, size, foff, p in mappings:
    if addr <= VM < addr + size:
        print(f"  addr=0x{addr:x} size=0x{size:x} foff=0x{foff:x} "
            f"{p.split('/')[-1]} (file-off 0x{VM - addr + foff:x})")

d = R.read(VM, 16)
print("read at VM:", d.hex() if d else None)

# scan down for magics; print parse results
page = (VM - 0x400000) & ~0xFFF
while page < VM:
    blob = R.read(page, 0x40000) or b""
    i = 0
    while True:
        i = blob.find(b"\xcf\xfa\xed\xfe", i)
        if i < 0:
            break
        hvm = page + i
        m = R.read(hvm, 0x1000) or b""
        if len(m) >= 0x40:
            ncmds = struct.unpack_from("<I", m, 16)[0]
            o = 32
            tva = tsz = None
            name = None
            for _ in range(min(ncmds, 64)):
                if o + 8 > len(m):
                    break
                cmd, size = struct.unpack_from("<II", m, o)
                if size < 8 or o + size > len(m):
                    break
                if cmd == 0x19 and m[o + 8:o + 24].split(
                        b"\0")[0] == b"__TEXT":
                    tva = struct.unpack_from("<Q", m, o + 24)[0]
                    tsz = struct.unpack_from("<Q", m, o + 32)[0]
                elif cmd == 0xD:
                    noff = struct.unpack_from("<I", m, o + 8)[0]
                    e = m.find(b"\0", o + noff, min(o + size, len(m)))
                    name = m[o + noff:e].decode("utf-8", "replace")
                o += size
            contains = bool(tva and tva <= VM < tva + tsz)
            print(f"  magic 0x{hvm:x}: name={name!r} tva=0x{tva if tva else 0:x}"
                f" tsz=0x{tsz if tsz else 0:x} contains={contains}")
        i += 1
    page += 0x40000
