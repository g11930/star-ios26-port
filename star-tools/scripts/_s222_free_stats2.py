#!/usr/bin/env python3
"""Free-space stats via checkpoint descriptor mapping (no omap needed)."""
import sys, struct, os

NXSB = b'NXSB'

def fletcher_ok(blk):
    s1 = s2 = 0
    for w in struct.unpack_from(f'<{(len(blk)-8)//4}I', blk, 8):
        s1 = (s1 + w) % 0xffffffff
        s2 = (s2 + s1) % 0xffffffff
    c1 = 0xffffffff - (s1 + s2) % 0xffffffff
    c2 = 0xffffffff - (s1 + c1) % 0xffffffff
    return struct.unpack_from('<Q', blk)[0] == (c2 << 32 | c1)

for path in sys.argv[1:]:
    f = open(path, 'rb')
    f.seek(0)
    b0 = f.read(4096)
    assert b0[32:36] == NXSB
    bs = struct.unpack_from('<I', b0, 36)[0]
    desc_blocks, = struct.unpack_from('<I', b0, 0x68)
    desc_base, = struct.unpack_from('<Q', b0, 0x70)
    # find newest valid NXSB
    newest = None
    for i in range(desc_blocks):
        f.seek((desc_base + i) * bs)
        blk = f.read(bs)
        if blk[32:36] == NXSB and fletcher_ok(blk):
            if newest is None or struct.unpack_from('<Q', blk, 16)[0] > struct.unpack_from('<Q', newest, 16)[0]:
                newest = blk
    xid = struct.unpack_from('<Q', newest, 16)[0]
    desc_index, desc_len = struct.unpack_from('<II', newest, 0x88)
    blocks = [desc_base + (desc_index + k) % desc_blocks for k in range(desc_len)]
    sm = None
    vols = []
    for bn in blocks[:-1]:
        f.seek(bn * bs)
        blk = f.read(bs)
        if not fletcher_ok(blk):
            continue
        for k in range(struct.unpack_from('<I', blk, 36)[0]):
            kind, flags, size, _, _, oid, paddr = struct.unpack_from('<IIIIQQQ', blk, 40 + 40 * k)
            kind &= 0xffff
            if kind == 5:  # spaceman
                f.seek(paddr * bs)
                sm = f.read(bs)
            if kind == 3:  # volume superblock
                f.seek(paddr * bs)
                apsb = f.read(bs)
                name = apsb[0x2c0:0x3c0].split(b'\0', 1)[0].decode(errors='replace')
                incompat = struct.unpack_from('<Q', apsb, 0x38)[0]
                fsflags = struct.unpack_from('<Q', apsb, 0x108)[0]
                vols.append((name, incompat, fsflags))
    print(f'== {os.path.basename(path)} == xid={xid} block_count={struct.unpack_from("<Q", newest, 0x28)[0]}')
    if sm:
        dev_blocks, dev_chunks, cibs, cabs, dev_free, addr_offset = struct.unpack_from('<QQIIQI', sm, 48)
        print(f'  spaceman: dev_blocks={dev_blocks} chunks={dev_chunks} free={dev_free} '
              f'({dev_free*bs/2**20:.1f} MiB) capacity={dev_blocks*bs/2**30:.3f} GiB')
    else:
        print('  spaceman: NOT FOUND in checkpoint')
    for name, inc, fs in vols:
        print(f'  volume: name={name!r} sealed={bool(inc & 0x20)} fsflags={fs:#x}')
