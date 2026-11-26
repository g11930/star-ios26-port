#!/usr/bin/env python3
from pathlib import Path

orig = {f.name: f.stat().st_size for f in Path('/root/dsc26/System/Library/Caches/com.apple.dyld').iterdir() if f.is_file() and f.name.startswith('dyld_shared_cache_arm64e')}
new = {f.name: f.stat().st_size for f in Path('/root/dsc26_rewritten').iterdir() if f.is_file()}
print('orig cache files:', len(orig), 'new:', len(new))
names = sorted(set(orig) | set(new))
grow = 0
for n in names:
    o, w = orig.get(n), new.get(n)
    d = (w or 0) - (o or 0)
    grow += d
    if d != 0:
        print(f'  {n}: {o} -> {w} ({d:+d})')
print('TOTAL delta:', grow)
# also list non-cache extras in orig dir
extra = [f.name for f in Path('/root/dsc26/System/Library/Caches/com.apple.dyld').iterdir() if f.is_file() and not f.name.startswith('dyld_shared_cache_arm64e')]
print('extras in orig dir:', extra)
