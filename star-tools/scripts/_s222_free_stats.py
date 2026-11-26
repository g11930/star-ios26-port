#!/usr/bin/env python3
"""Free-space stats for the iOS26 images, via the proven iOS16 apfs.py reader."""
import sys, struct
sys.path.insert(0, '/root/apfs16')
import apfs as A

for path in sys.argv[1:]:
    c = A.Container(path)
    nx = c.nx
    print(f'== {path.split("/")[-1]} ==')
    print(f'  block_count={nx["block_count"]} capacity={nx["block_count"]*c.block_size/2**30:.3f} GiB')
    sm_oid = nx['spaceman_oid']
    sm_paddr = c.omap.lookup(sm_oid, nx['xid'])
    sm = c.blocks.get(sm_paddr)
    dev_blocks, dev_chunks, cibs, cabs, dev_free, addr_offset = struct.unpack_from('<QQIIQI', sm, 48)
    print(f'  spaceman: dev_blocks={dev_blocks} chunks={dev_chunks} free={dev_free} '
          f'({dev_free*c.block_size/2**20:.1f} MiB free)')
    # volumes
    for i, oid in enumerate(nx['fs_oid']):
        if not oid:
            continue
        paddr = c.omap.lookup(oid, nx['xid'])
        apsb = c.blocks.get(paddr)
        name = apsb[0x2c0:0x3c0].split(b'\0', 1)[0].decode(errors='replace')
        incompat = struct.unpack_from('<Q', apsb, 0x38)[0]
        fsflags = struct.unpack_from('<Q', apsb, 0x108)[0]
        print(f'  volume[{i}]: oid={oid:#x} name={name!r} sealed={bool(incompat & 0x20)} fsflags={fsflags:#x}')
