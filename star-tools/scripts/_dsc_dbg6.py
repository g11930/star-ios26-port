#!/usr/bin/env python3
import sys
sys.path.insert(0, "/mnt/d/桌面/star26-deps/scripts")
from dscsym2 import R

m = R.read(0x1800EA000, 0x1000)
print("len:", len(m), "ncmds:", struct_nc := int.from_bytes(m[16:20], "little"))
o = 32
for _ in range(struct_nc):
    if o + 8 > len(m):
        print(f"  o={o:#x}: out of range")
        break
    cmd = int.from_bytes(m[o:o + 4], "little")
    size = int.from_bytes(m[o + 4:o + 8], "little")
    seg = m[o + 8:o + 24].split(b"\0")[0].decode("utf-8", "replace") \
        if cmd == 0x19 else ""
    print(f"  o={o:#x} cmd={cmd:#x} size={size:#x} {seg}")
    if size < 8 or o + size > len(m):
        print("  -> BAD SIZE, break")
        break
    o += size

# print segment vmaddrs for libobjc
m = R.read(0x1800EA000, 0x1000)
o = 32
for _ in range(26):
    cmd = int.from_bytes(m[o:o + 4], "little")
    size = int.from_bytes(m[o + 4:o + 8], "little")
    if cmd == 0x19:
        seg = m[o + 8:o + 24].split(b"\0")[0].decode()
        va = int.from_bytes(m[o + 16:o + 24], "little")
        vsz = int.from_bytes(m[o + 24:o + 32], "little")
        foff = int.from_bytes(m[o + 32:o + 40], "little")
        print(f"{seg}: vmaddr=0x{va:x} vmsize=0x{vsz:x} fileoff=0x{foff:x}")
    o += size
