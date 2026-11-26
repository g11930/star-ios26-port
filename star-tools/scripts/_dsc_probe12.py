#!/usr/bin/env python3
"""Search all cache files for the mov x16,#-46; svc stub pattern and report
the vm addresses (with the +0x4000 main-file correction)."""
import glob
import os

D = "/root/dsc26/System/Library/Caches/com.apple.dyld"
files = sorted(glob.glob(D + "/dyld_shared_cache_arm64e*"),
    key=lambda p: (len(p), p))
BASE = 0x180000000
PAT = bytes.fromhex("d0058092011000d4")  # mov x16,#-46 ; svc #0x80

acc = 0
hits = []
for p in files:
    sz = os.path.getsize(p)
    if sz > 200 * 1024 * 1024:
        with open(p, "rb") as f:
            data = f.read()
        i = 0
        while True:
            i = data.find(PAT, i)
            if i < 0:
                break
            hits.append((acc + i, p))
            i += 1
    acc += sz

print(f"pattern hits: {len(hits)}")
for g, p in hits[:10]:
    vm = BASE + (g - 0x4000 if g >= 0x98000 else g)
    print(f"  global 0x{g:x} ({os.path.basename(p)}) -> vm 0x{vm:x}")
