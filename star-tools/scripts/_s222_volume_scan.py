#!/usr/bin/env python3
"""Scan the first N blocks for APSB volume superblocks; print name/flags."""
import struct, sys

def fletcher_ok(blk):
    s1 = s2 = 0
    for w in struct.unpack_from(f'<{(len(blk)-8)//4}I', blk, 8):
        s1 = (s1 + w) % 0xffffffff
        s2 = (s2 + s1) % 0xffffffff
    c1 = 0xffffffff - (s1 + s2) % 0xffffffff
    c2 = 0xffffffff - (s1 + c1) % 0xffffffff
    return struct.unpack_from('<Q', blk)[0] == (c2 << 32 | c1)

path = sys.argv[1]
n = int(sys.argv[2]) if len(sys.argv) > 2 else 400
f = open(path, 'rb')
for i in range(n):
    f.seek(i * 4096)
    b = f.read(4096)
    if len(b) < 4096:
        break
    if b[32:36] == b'APSB' and fletcher_ok(b):
        name = b[0x2c0:0x3c0].split(b'\0', 1)[0].decode(errors='replace')
        incompat = struct.unpack_from('<Q', b, 0x38)[0]
        fsflags = struct.unpack_from('<Q', b, 0x108)[0]
        xid = struct.unpack_from('<Q', b, 16)[0]
        print(f'block {i}: volume {name!r} xid={xid} incompat={incompat:#x} sealed={bool(incompat & 0x20)} fsflags={fsflags:#x}')
