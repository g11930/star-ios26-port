#!/usr/bin/env python3
"""Read-only: systemos.dmg APFS container stats (size, volumes, free space)."""
import struct, sys
sys.path.insert(0, '/root/dsc26_zeta_scripts')
import zeta_apfs_image as apfs

path = sys.argv[1] if len(sys.argv) > 1 else '/root/star26/ipsw/systemos.dmg'
with open(path, 'rb') as h:
    size = h.seek(0, 2)
    h.seek(0)
    c = apfs.Container(h)
    sb = c.superblock
    nx_blocks = struct.unpack_from('<Q', sb, 0x28)[0]
    print(f'container: {path} file_size={size} bs={c.block_size} nx_blocks={nx_blocks} capacity={nx_blocks*c.block_size/2**30:.3f} GiB')
    for v in c.volumes():
        print(f'  volume: name={v.name!r} role={v.role} xid={v.xid} sealed={bool(v.incompatible & 0x20)} '
              f'fs_flags={v.fs_flags:#x}')
    # spaceman free
    # superblock: nx_spaceman_oid at 0x98
    sm_oid = struct.unpack_from('<Q', sb, 0x98)[0]
    desc_blocks, _, desc_base, _ = struct.unpack_from('<IIQQ', sb, 0x68)
    # find spaceman paddr via omap
    sm_paddr = c.omap_lookup(c.omap_root, sm_oid, c.xid(sb))
    sm = c.checked(sm_paddr)
    dev_blocks, dev_chunks, cibs, cabs, dev_free, addr_offset = struct.unpack_from('<QQIIQI', sm, 48)
    print(f'  spaceman: dev_blocks={dev_blocks} chunks={dev_chunks} free_blocks={dev_free} '
          f'free={dev_free*c.block_size/2**20:.1f} MiB')
