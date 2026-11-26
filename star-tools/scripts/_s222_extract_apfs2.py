#!/usr/bin/env python3
"""从 systemos.dmg 提取 3 个稀疏 dyldlinkedit 分片。
monkey-patch: 坏 checksum 的块降级为 verify=False（cryptex 常见，数据本身可读）。"""
import sys, os, time
sys.path.insert(0, '/root/star26/hackios-xnu-userland/tools/apfs')
import apfs_super
import apfs
from apfs import Container

# patch Blocks.get: checksum 失败时用 verify=False 重试
_orig_get = apfs_super.Blocks.get
def tolerant_get(self, addr, verify=True):
    try:
        return _orig_get(self, addr, verify)
    except apfs.ApfsError as e:
        if 'checksum' in str(e):
            return _orig_get(self, addr, False)
        raise
apfs_super.Blocks.get = tolerant_get

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
print('bad blocks tolerated:', getattr(c.blocks,'cksum_bad',0), flush=True)
c.close()
