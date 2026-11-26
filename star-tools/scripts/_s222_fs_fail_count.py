#!/usr/bin/env python3
"""只读：统计有多少 image 的 function_starts 因空分片读取失败。"""
import sys, struct
sys.path.insert(0, '/root/dsc26_zeta_scripts')
import zeta_dyld_cache as dc

# 容错空分片
def patched(self, path):
    from pathlib import Path
    import mmap
    self.path = Path(path); self.handle = self.path.open('rb')
    if self.path.stat().st_size == 0:
        self.data=b''; self.mappings=[]; self.signature=(0,0); self.slid=[]; return
    self.data=mmap.mmap(self.handle.fileno(),0,access=mmap.ACCESS_READ)
    if not self.data[:16].startswith(b'dyld_v1') or not self.data[:16].rstrip(b'\0').endswith(b'arm64e'):
        raise ValueError('not arm64e')
    off,cnt=struct.unpack_from('<II',self.data,dc.HEADER_MAPPINGS)
    self.mappings=[struct.unpack_from('<QQQII',self.data,off+32*i) for i in range(cnt)]
    self.signature=struct.unpack_from('<QQ',self.data,dc.HEADER_SIGNATURE)
    so,sc=struct.unpack_from('<II',self.data,dc.HEADER_MAPPING_SLIDE)
    self.slid=[struct.unpack_from('<QQQQQQII',self.data,so+56*i) for i in range(sc)]
dc.CacheFile.__init__=patched

MAIN='/root/dsc26/System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64e'
cache=dc.Cache(MAIN)
fail=0; ok=0; no_fs=0; fail_paths=[]
for addr,path in cache.images:
    try:
        im=dc.Image(cache,addr,path)
        fs=im.function_starts()
        if im.function_starts_command and im.function_starts_command[1]:
            if fs: ok+=1
            else: no_fs+=1
    except Exception as e:
        fail+=1
        if len(fail_paths)<15: fail_paths.append((path,str(e)[:60]))
print('function_starts OK:',ok,'empty:',no_fs,'FAIL:',fail, flush=True)
print('fail sample:',flush=True)
for p,e in fail_paths:
    print('  ',p,'|',e,flush=True)
