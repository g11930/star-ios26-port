#!/usr/bin/env python3
"""只读验证 v2：打一个内存态补丁让 CacheFile 容忍 0 字节分片，
然后确认 zeta 解析器能打开我们的 cache、读到 images、解析 slide info v5。
不修改磁盘上的 cache 或脚本文件。"""
import sys, time, struct
sys.path.insert(0, '/root/dsc26_zeta_scripts')
import zeta_dyld_cache as dc

# 内存态补丁：mmap 空文件会失败，用 bytes 替代（空分片只影响 LINKEDIT 数据读取）
orig_init = dc.CacheFile.__init__
def patched_init(self, path):
    from pathlib import Path
    import mmap
    self.path = Path(path)
    self.handle = self.path.open('rb')
    if self.path.stat().st_size == 0:
        self.data = b''   # 空分片占位
    else:
        self.data = mmap.mmap(self.handle.fileno(), 0, access=mmap.ACCESS_READ)
    if len(self.data) >= 16:
        if not self.data[:16].startswith(b'dyld_v1') or not self.data[:16].rstrip(b'\0').endswith(b'arm64e'):
            raise ValueError(f'{self.path.name}: not arm64e')
    off, cnt = struct.unpack_from('<II', self.data, dc.HEADER_MAPPINGS) if len(self.data) >= dc.HEADER_MAPPINGS+8 else (0,0)
    self.mappings = [struct.unpack_from('<QQQII', self.data, off + 32*i) for i in range(cnt)]
    self.signature = struct.unpack_from('<QQ', self.data, dc.HEADER_SIGNATURE) if len(self.data) >= dc.HEADER_SIGNATURE+16 else (0,0)
    so, sc = struct.unpack_from('<II', self.data, dc.HEADER_MAPPING_SLIDE) if len(self.data) >= dc.HEADER_MAPPING_SLIDE+8 else (0,0)
    self.slid = [struct.unpack_from('<QQQQQQII', self.data, so + 56*i) for i in range(sc)]
dc.CacheFile.__init__ = patched_init

MAIN = '/root/dsc26/System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64e'
t0 = time.time()
print('opening cache...', flush=True)
cache = dc.Cache(MAIN)
print('files:', len(cache.files), 'regions:', len(cache.regions), 'images:', len(cache.images), flush=True)
print('executable regions:', len(cache.executable_regions()), flush=True)

print('\nslide info versions:', flush=True)
bad = []
for cf in cache.files:
    for addr, size, fileoff, infooff, infosize, flags, _, _ in cf.slid:
        if not infosize or len(cf.data) < infooff+4:
            continue
        ver = struct.unpack_from('<I', cf.data, infooff)[0]
        if ver != 5:
            bad.append((cf.path.name, ver))
print('  non-v5 count:', len(bad), bad[:10], flush=True)

print('\nslide targets...', flush=True)
t1=time.time()
try:
    targets = cache.slide_targets()
    print('  count:', len(targets), 'in %.1fs' % (time.time()-t1), flush=True)
    print('  sample:', [hex(int(t)) for t in targets[:5]], flush=True)
except Exception as e:
    print('  slide_targets ERROR:', type(e).__name__, str(e)[:200], flush=True)

print('\nimage header sanity (first 20):', flush=True)
ok=0; err=[]
for addr, path in cache.images[:20]:
    try:
        im = dc.Image(cache, addr, path)
        ok+=1
    except Exception as e:
        err.append((path, str(e)[:80]))
print('  parsed ok:', ok, '/20', flush=True)
print('  errors:', err[:5], flush=True)
print('\nTOTAL %.1fs' % (time.time()-t0), flush=True)
