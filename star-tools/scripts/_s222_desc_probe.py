#!/usr/bin/env python3
import struct, sys
sys.path.insert(0, '/root/dsc26_zeta_scripts')
import zeta_apfs_image as apfs

for path in sys.argv[1:]:
    f = open(path, 'rb')
    b0 = f.read(4096)
    desc_blocks, = struct.unpack_from('<I', b0, 0x68)
    desc_base, = struct.unpack_from('<Q', b0, 0x70)
    ok = nx = 0
    for i in range(desc_blocks):
        f.seek((desc_base + i) * 4096)
        blk = f.read(4096)
        stored = struct.unpack_from('<Q', blk)[0]
        if blk[32:36] == b'NXSB':
            nx += 1
            m = stored == apfs.fletcher64(blk)
            ok += m
            print(f'  NXSB desc {i}: checksum {"OK" if m else "MISMATCH"}')
        elif stored == apfs.fletcher64(blk):
            ok += 1
    print(f'{os.path.basename(path) if False else path.split("/")[-1]}: desc {desc_blocks} valid {ok} nxsb {nx}')
