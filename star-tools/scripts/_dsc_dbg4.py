#!/usr/bin/env python3
import sys
sys.path.insert(0, "/mnt/d/桌面/star26-deps/scripts")
from dscsym2 import R, mappings

print("mappings covering 0x1800EA000:")
for addr, size, foff, p in mappings:
    if addr <= 0x1800EA000 < addr + size:
        print(f"  addr=0x{addr:x} size=0x{size:x} foff=0x{foff:x} "
            f"{p.split('/')[-1]} file-off=0x{0x1800EA000 - addr + foff:x}")

d = R.read(0x1800EA000, 16)
print("read at libobjc header:", d.hex() if d else None)
d = R.read(0x1800C0000, 0x40000)
print("read block 0x1800C0000 len:", len(d) if d else None,
    "magics:", d.count(b"\xcf\xfa\xed\xfe") if d else 0)
