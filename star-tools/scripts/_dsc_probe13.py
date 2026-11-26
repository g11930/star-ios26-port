#!/usr/bin/env python3
"""Search ALL cache files for the stub pattern (no size filter)."""
import glob
import os

D = "/root/dsc26/System/Library/Caches/com.apple.dyld"
files = sorted(glob.glob(D + "/dyld_shared_cache_arm64e*"),
    key=lambda p: (len(p), p))
PAT = bytes.fromhex("d0058092011000d4")

acc = 0
hits = []
for p in files:
    sz = os.path.getsize(p)
    with open(p, "rb") as f:
        data = f.read()
    i = 0
    while True:
        i = data.find(PAT, i)
        if i < 0:
            break
        hits.append((acc + i, os.path.basename(p)))
        i += 1
    acc += sz

print(f"pattern hits: {len(hits)}  (concat total 0x{acc:x})")
for g, p in hits[:16]:
    rel = g - 0x98000 if g >= 0x98000 else g
    vm = 0x180000000 + rel
    print(f"  global 0x{g:x} ({p}) -> vm 0x{vm:x}")
