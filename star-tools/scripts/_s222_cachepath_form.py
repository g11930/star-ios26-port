#!/usr/bin/env python3
"""Check /System/Library/Caches/com.apple.dyld form in os.dmg + list empty dirs."""
import sys, struct
sys.path.insert(0, '/root/dsc26_zeta_scripts')
import zeta_apfs_image as apfs

with open('/root/star26/ipsw/os.dmg', 'rb') as h:
    c = apfs.Container(h)
    v = [x for x in c.volumes() if x.name == 'LuckG23G90.V57OS'][0]
    ino = v.lookup('/System/Library/Caches/com.apple.dyld')
    # inode type: read the inode record
    recs = v.records(ino, apfs.TYPE_INODE)
    for k, val in recs:
        # apfs inode: parent(8) + private_id(8) + create_time(8) + mod(8) + chg(8) + nchildren... + mode(2) at offset 60?
        # In apfs_format: mode is at offset 88 within j_inode_t? print raw to identify
        parent, pid = struct.unpack_from('<QQ', val, 0)
        mode = struct.unpack_from('<H', val, 84)[0]
        import stat as S
        print(f'com.apple.dyld inode: parent={parent} id={pid} mode={oct(mode)} type={(mode >> 12):o}')
        break
    # also check what the cryptex mount point looks like: /System/Volumes or /private/preboot
    for p in ('/System/Library/Caches', '/System/Volumes'):
        try:
            i2 = v.lookup(p)
            r2 = list(v.records(i2, apfs.TYPE_INODE))
            if r2:
                m = struct.unpack_from('<H', r2[0][1], 84)[0]
                print(f'{p}: mode={oct(m)}')
        except ValueError as e:
            print(f'{p}: {e}')
