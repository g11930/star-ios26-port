#!/usr/bin/env python3
"""Compare the P34 kernel with the kernel inside the P33 payload that runs."""
import struct, sys

def entries(path):
    b = open(path, 'rb').read()
    assert b[:4] == b'XNUP', b[:8]
    off = 8
    out = {}
    while off + 24 <= len(b):
        name = b[off:off + 16].split(b'\0', 1)[0].decode('ascii', 'replace')
        size, _ = struct.unpack_from('<II', b, off + 16)
        data = b[off + 24:off + 24 + size]
        if not name:
            break
        out[name] = data
        off += 24 + ((size + 15) // 16) * 16
        if size == 0 and name == '':
            break
    return out

a = entries('/mnt/c/ios26/p33-payload.bin')
b = entries('/mnt/c/ios26/p34-payload.bin')
print('P33 entries:', {k: len(v) for k, v in a.items()})
print('P34 entries:', {k: len(v) for k, v in b.items()})

k33, k34 = a['kernel'], b['kernel']
print('kernel sizes', len(k33), len(k34))
n = min(len(k33), len(k34))
ranges = []
start = None
for i in range(n):
    if k33[i] != k34[i]:
        if start is None:
            start = i
    else:
        if start is not None:
            ranges.append((start, i))
            start = None
if start is not None:
    ranges.append((start, n))
print('diff ranges:', len(ranges))
for s, e in ranges[:40]:
    print('  %#010x..%#010x  (%d bytes)' % (s, e, e - s))
