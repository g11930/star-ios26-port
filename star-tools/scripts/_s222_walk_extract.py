#!/usr/bin/env python3
"""遍历 systemos.dmg 的目录树找 3 个 dyldlinkedit 文件并提取（容错坏 checksum）。"""
import sys, os, time
sys.path.insert(0, '/root/star26/hackios-xnu-userland/tools/apfs')
import apfs, apfs_super
from apfs import Container, walk
try:
    ROOT=apfs.ROOT_DIR_INO_NUM
except AttributeError:
    from apfs_reader import ROOT_DIR_INO_NUM as ROOT

_orig=apfs_super.Blocks.get
def tolerant(self, addr, verify=True):
    try:
        return _orig(self, addr, verify)
    except apfs.ApfsError as e:
        if 'checksum' in str(e):
            return _orig(self, addr, False)
        raise
apfs_super.Blocks.get=tolerant

DMG='/root/star26/ipsw/systemos.dmg'
OUT='/root/dsc26_fix'
os.makedirs(OUT,exist_ok=True)
targets={'dyld_shared_cache_arm64e.35.dyldlinkedit','dyld_shared_cache_arm64e.72.dyldlinkedit','dyld_shared_cache_arm64e.83.dyldlinkedit'}
c=Container(DMG)
v=c.volumes()[0]
found={}
count=0
for p,name,fid,dt in walk(v,ROOT):
    count+=1
    if name in targets:
        found[name]=(p,fid)
        print('FOUND:',p,'fid=',fid,flush=True)
print('walked',count,'entries; found',len(found),'targets',flush=True)

for name,(p,fid) in found.items():
    t0=time.time()
    try:
        ino=v.inode(fid)
        print('===',name,'size',ino.size(),'sparse',ino.is_sparse(),'decmpfs',ino.decmpfs is not None,flush=True)
        data=ino.contents()
        print('  contents',len(data),'in %.1fs'%(time.time()-t0),flush=True)
        with open(os.path.join(OUT,name),'wb') as f:
            f.write(data)
        print('  wrote',flush=True)
    except Exception as e:
        print('  ERROR',type(e).__name__,str(e)[:150],flush=True)
c.close()
