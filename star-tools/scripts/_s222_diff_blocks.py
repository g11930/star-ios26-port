#!/usr/bin/env python3
"""Find changed 4KiB blocks between original os.dmg and the modified copy."""
import os, struct

A = '/root/star26/ipsw/os.dmg'
B = '/root/os26_new.dmg'
BLOCK = 4096
total = os.path.getsize(A)
assert total == os.path.getsize(B)
n = total // BLOCK
fa, fb = open(A, 'rb'), open(B, 'rb')
changed = []
for i in range(n):
    fa.seek(i * BLOCK)
    fb.seek(i * BLOCK)
    if fa.read(BLOCK) != fb.read(BLOCK):
        changed.append(i)
print(f'changed blocks: {len(changed)} of {n} ({len(changed)*BLOCK/1024:.0f} KiB)')
if changed:
    runs = []
    start = prev = changed[0]
    for i in changed[1:]:
        if i == prev + 1:
            prev = i
        else:
            runs.append((start, prev))
            start = prev = i
    runs.append((start, prev))
    print(f'{len(runs)} runs:')
    for s, e in runs:
        print(f'  blocks {s}..{e} ({e-s+1} blocks, LBA offset from darwin base: {s}..{e})')
