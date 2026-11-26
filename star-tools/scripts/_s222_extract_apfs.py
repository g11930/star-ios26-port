#!/usr/bin/env python3
"""从 systemos.dmg 用 apfs_reader 的 decmpfs 支持提取 3 个稀疏 dyldlinkedit 分片。"""
import sys, os, time
sys.path.insert(0, '/root/star26/hackios-xnu-userland/tools/apfs')
from apfs import Container

DMG='/root/star26/ipsw/systemos.dmg'
OUT='/root/dsc26_fix'
os.makedirs(OUT, exist_ok=True)
names=[
 'dyld_shared_cache_arm64e.35.dyldlinkedit',
 'dyld_shared_cache_arm64e.72.dyldlinkedit',
 'dyld_shared_cache_arm64e.83.dyldlinkedit',
]
base='System/Library/Caches/com.apple.dyld/'
c=Container(DMG)
v=c.volumes()[0]
for name in names:
    p=base+name
    t0=time.time()
    print('===',name,'===',flush=True)
    hit=v.lookup(p)
    if hit is None:
        print('  NOT FOUND',flush=True); continue
    ino=v.inode(hit[0])
    print('  logical size:',ino.size(),'sparse:',ino.is_sparse(),'decmpfs:',ino.decmpfs is not None,flush=True)
    try:
        data=ino.contents()
        print('  contents len:',len(data),'in %.1fs'%(time.time()-t0),flush=True)
        out=os.path.join(OUT,name)
        with open(out,'wb') as f:
            f.write(data)
        print('  wrote',out,flush=True)
    except Exception as e:
        print('  ERROR:',type(e).__name__,str(e)[:200],flush=True)
c.close()
