#!/usr/bin/env python3
import sys, struct
sys.path.insert(0, '/root/apfs16')
import apfs as A

for p in ('/root/star26/ipsw/systemos.dmg', '/root/star26/ipsw/os.dmg'):
    c = A.Container(p)
    print(p.split('/')[-1], 'volumes:')
    for v in c.volumes():
        raw = c.blocks.get(v.addr)
        name = raw[0x2c0:0x3c0].split(b'\0', 1)[0].decode(errors='replace')
        incompat = struct.unpack_from('<Q', raw, 56)[0]
        fsflags = struct.unpack_from('<Q', raw, 0x108)[0]
        print(f'  {name!r} incompat={incompat:#x} sealed={bool(incompat & 0x20)} fsflags={fsflags:#x}')
