#!/usr/bin/env python3
import os
from pathlib import Path

def dir_files(p):
    p = Path(p)
    files = sorted(f for f in p.rglob('*') if f.is_file())
    total = sum(f.stat().st_size for f in files)
    return len(files), total

for label, path in (('original', '/root/dsc26/System/Library/Caches/com.apple.dyld'),
                    ('rewritten', '/root/dsc26_rewritten')):
    n, t = dir_files(path)
    print(f'{label}: {n} files, {t} bytes ({t/2**30:.3f} GiB)')
