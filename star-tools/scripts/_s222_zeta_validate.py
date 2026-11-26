#!/usr/bin/env python3
"""只读验证：用 zeta 的 Cache 类打开我们的 dsc26，确认结构兼容 + slide info v5。"""
import sys, time
sys.path.insert(0, '/root/dsc26_zeta_scripts')
import zeta_dyld_cache as dc

MAIN = '/root/dsc26/System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64e'
t0 = time.time()
print('opening cache...', flush=True)
cache = dc.Cache(MAIN)
print('files (main + subcaches):', len(cache.files), flush=True)
print('regions (mappings):', len(cache.regions), flush=True)
print('images:', len(cache.images), flush=True)
print('first 5 images:', flush=True)
for addr, path in cache.images[:5]:
    print('  0x%x %s' % (addr, path), flush=True)
print('executable regions:', len(cache.executable_regions()), flush=True)

print('\nchecking slide info version across all files...', flush=True)
import struct
bad = []
for i, cf in enumerate(cache.files):
    for addr, size, fileoff, infooff, infosize, flags, _, _ in cf.slid:
        if not infosize:
            continue
        ver = struct.unpack_from('<I', cf.data, infooff)[0]
        if ver != 5:
            bad.append((cf.path.name, ver))
print('slide info v5 files:', len(cache.files) - len(set(n for n,_ in bad)), flush=True)
print('non-v5 entries:', bad[:10], flush=True)

print('\ncomputing slide targets (slide info v5 parse)...', flush=True)
t1 = time.time()
targets = cache.slide_targets()
print('slide targets:', len(targets), 'in %.1fs' % (time.time()-t1), flush=True)
print('sample targets:', [hex(int(t)) for t in targets[:5]], flush=True)

print('\nTOTAL %.1fs' % (time.time()-t0), flush=True)
