#!/usr/bin/env python3
import struct

def fletcher64(block):
    words = struct.unpack_from(f'<{(len(block) - 8) // 4}I', block, 8)
    low = high = 0
    for word in words:
        low = (low + word) % 0xffffffff
        high = (high + low) % 0xffffffff
    check_low = 0xffffffff - (low + high) % 0xffffffff
    check_high = 0xffffffff - (high + check_low) % 0xffffffff
    return check_high << 32 | check_low

for path in ('/root/star26/ipsw/systemos.dmg', '/root/star26/ipsw/os.dmg'):
    f = open(path, 'rb')
    f.seek(0)
    b = f.read(4096)
    print(path.split('/')[-1], 'magic@32:', b[32:36], 'checksum:', hex(struct.unpack_from('<Q', b)[0]),
          'computed:', hex(fletcher64(b)), 'match:', struct.unpack_from('<Q', b)[0] == fletcher64(b))
    # scan checkpoint descriptor area for valid NXSB
    desc_blocks, = struct.unpack_from('<I', b, 0x68)
    desc_base, = struct.unpack_from('<Q', b, 0x70)
    print('  desc_blocks', desc_blocks, 'desc_base', desc_base)
    ok = 0
    for i in range(desc_blocks):
        f.seek((desc_base + i) * 4096)
        blk = f.read(4096)
        if blk[32:36] == b'NXSB':
            valid = struct.unpack_from('<Q', blk)[0] == fletcher64(blk)
            ok += valid
            if not valid and i < 4:
                print(f'  NXSB at desc {i}: checksum MISMATCH')
    print('  valid NXSB count:', ok)
    f.close()
