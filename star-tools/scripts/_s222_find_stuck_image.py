#!/usr/bin/env python3
"""Find images with no npz result — the stuck one is among them."""
import sys, importlib.util
from pathlib import Path
SCRIPTS = Path('/root/dsc26_zeta_scripts')
def load(name):
    spec = importlib.util.spec_from_file_location(name, SCRIPTS / f'{name}.py')
    mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod); return mod
dc = load('zeta_dyld_cache')
prove = load('prove-zeta-dyld-cache')
cache = dc.Cache('/root/dsc26/System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64e')
work = Path('/root/dsc26_proof')
missing = []
for address, path in cache.images:
    name = prove.result_name(path)
    if not (work / f'{name}.npz').exists():
        image = dc.Image(cache, address, path)
        secs = image.instruction_sections()
        tot = sum(s['size'] for s in secs)
        missing.append((tot, path, len(secs)))
missing.sort(reverse=True)
print(f'missing npz: {len(missing)} of {len(cache.images)}')
print('largest missing (size, path, nsec):')
for tot, path, nsec in missing[:20]:
    print(f'  {tot:>12,}  nsec={nsec:<3} {path}')
