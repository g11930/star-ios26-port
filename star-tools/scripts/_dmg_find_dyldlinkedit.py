#!/usr/bin/env python3
"""只读：在 systemos.dmg / os.dmg 里找 dyld_shared_cache 分片文件。"""
import sys, os
sys.path.insert(0, '/root/star26/hackios-xnu-userland/tools/apfs')
import apfs
from apfs import Container, pick_volume, walk
try:
    ROOT = apfs.ROOT_DIR_INO_NUM
except AttributeError:
    from apfs_reader import ROOT_DIR_INO_NUM as ROOT

for image in ['/root/star26/ipsw/systemos.dmg', '/root/star26/ipsw/os.dmg']:
    print('=====', os.path.basename(image), '=====', flush=True)
    c = Container(image)
    try:
        v = pick_volume(c, None)
        found = []
        for p, name, fid, dt in walk(v, ROOT):
            s = (p or '') + '/' + (name or '')
            low = s.lower()
            if 'dyld_shared_cache' in low or 'dyldlinkedit' in low:
                try:
                    ino = v.inode(fid)
                    size = ino.size() if ino else '?'
                except Exception:
                    size = '?'
                found.append((s, size))
        print('  dyld cache files found:', len(found), flush=True)
        for s, size in found[:20]:
            print('   ', s, 'size=', size, flush=True)
    except Exception as e:
        print('  error:', e, flush=True)
    c.close()
    print(flush=True)
