#!/usr/bin/env python3
import sys
p = "/root/star26/s41/work/root/lib/libannibale.dylib"
data = open(p, "rb").read()
offs = [0x6a40,0x6a50,0x6b10,0x6a30,0x6980,0x7100,0x7124,0x712f,0x713d,0x7146,
        0x7155,0x7157,0x71b0,0x71b7,0x71b9,0x6bf0,0x6c20,0x6c40,0x6be0,0x6b80,0x69a0]
for o in offs:
    seg = data[o:o+120].split(b"\x00")[0]
    try:
        print("%#07x | %s" % (o, seg.decode("ascii")))
    except Exception:
        print("%#07x | <bin> %r" % (o, seg[:40]))
