#!/usr/bin/env python3
import sys, struct
sys.path.insert(0, '/root/dsc26_zeta_scripts')
import zeta_apfs_image as apfs

with open('/root/star26/ipsw/os.dmg', 'rb') as h:
    c = apfs.Container(h)
    print('container OK, block_size', c.block_size)
    vols = list(c.volumes())
    print('volumes:', [v.name for v in vols])
    for v in vols:
        if v.name == 'LuckG23G90.V57OS':
            for path in ('/usr/lib/dyld', '/sbin/launchd'):
                ino = v.lookup(path)
                x = v.xattrs(ino)
                magic, kind, size = struct.unpack_from('<4sIQ', x['com.apple.decmpfs'][1])
                fork_size, extents = v.resource_fork(ino)
                print(f'{path}: inode={ino} decmpfs magic={magic} kind={kind} logical={size} '
                      f'fork={fork_size}B extents={len(extents)}')
