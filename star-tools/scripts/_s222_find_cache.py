#!/usr/bin/env python3
"""只读：遍历 APFS 镜像，找所有 dyld_shared_cache 文件的完整路径和大小。"""
import sys, os
sys.path.insert(0, '/root/star26/hackios-xnu-userland/tools/apfs')
import apfs
from apfs import Container, pick_volume, walk
try:
    ROOT = apfs.ROOT_DIR_INO_NUM
except AttributeError:
    from apfs_reader import ROOT_DIR_INO_NUM as ROOT

for image in ['/root/star26/ipsw/systemos.dmg', '/root/star26/ipsw/os.dmg', '/root/star26/ipsw/appos.dmg']:
    print('=====', os.path.basename(image), '=====', flush=True)
    try:
        c = Container(image)
        vols = c.volumes()
        print('  volumes:', len(vols), flush=True)
        for vi in range(len(vols)):
            v = pick_volume(c, str(vi))
            if v is None:
                continue
            try:
                vname = getattr(v, 'name', '?')
            except Exception:
                vname = '?'
            print('  volume[%d]: %s' % (vi, vname), flush=True)
            found = 0
            try:
                for p, name, fid, dt in walk(v, ROOT):
                    s = (p or '') + '/' + (name or '')
                    if 'dyld_shared_cache' in s.lower():
                        try:
                            ino = v.inode(fid)
                            size = ino.size() if ino else '?'
                        except Exception:
                            size = '?'
                        print('    FOUND: %s | size=%s' % (s, size), flush=True)
                        found += 1
            except Exception as e:
                print('    walk error:', e, flush=True)
            print('    (cache hits: %d)' % found, flush=True)
        c.close()
    except Exception as e:
        print('  container error:', e, flush=True)
    print(flush=True)
