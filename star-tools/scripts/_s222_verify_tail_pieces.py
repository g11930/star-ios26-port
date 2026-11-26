#!/usr/bin/env python3
"""Verify tail signature pieces decode correctly with the 0xff=raw rule, in memory only."""
import struct, os, subprocess

BASE = '/root/dsc26_fix/7zout'
TOOL = '/root/zbm_tool/zbm_tool'
CHUNK = 65536
# (name, first piece index that starts the signature region)
CASES = [
    ('dyld_shared_cache_arm64e.35.dyldlinkedit', 2868),
    ('dyld_shared_cache_arm64e.72.dyldlinkedit', 2794),
    ('dyld_shared_cache_arm64e.83.dyldlinkedit', 3466),
]
CSMAGIC_EMBEDDED_SIGNATURE = 0xfade0cc0
CSMAGIC_CODEDIRECTORY = 0xfade0c02

for name, first in CASES:
    rsrc = open(os.path.join(BASE, name + ':com.apple.ResourceFork'), 'rb').read()
    # rebuild offset table
    offsets = []
    pos = 0
    while pos + 4 <= len(rsrc):
        v = struct.unpack_from('<I', rsrc, pos)[0]
        if v > len(rsrc) or v < pos:
            break
        offsets.append(v)
        pos += 4
    # decode pieces from 'first' to end into a buffer
    buf = bytearray()
    for i in range(first, len(offsets) - 1):
        piece = rsrc[offsets[i]:offsets[i + 1]]
        if piece[:1] == b'\xff':
            buf += piece[1:]
            continue
        open('/root/zbm_tool/_p.zbm', 'wb').write(piece)
        r = subprocess.run([TOOL, '/root/zbm_tool/_p.zbm', '/root/zbm_tool/_p.out'], capture_output=True)
        if r.returncode == 0:
            buf += open('/root/zbm_tool/_p.out', 'rb').read()
        else:
            buf += b'\x00' * CHUNK
    print(f'=== {name}: decoded tail from piece {first}, {len(buf)} bytes ===')
    print(' head:', bytes(buf[:8]).hex())
    magic, _, count = struct.unpack_from('>III', buf, 0)
    print(f' sig magic={magic:#x} (want {CSMAGIC_EMBEDDED_SIGNATURE:#x}) count={count}')
    ok = magic == CSMAGIC_EMBEDDED_SIGNATURE
    if ok:
        for slot in range(count):
            _, at = struct.unpack_from('>II', buf, 12 + 8 * slot)
            m, length = struct.unpack_from('>II', buf, at)
            print(f'   slot {slot}: type={m:#x} len={length} {"CODEDIRECTORY" if m==CSMAGIC_CODEDIRECTORY else ""}')
    print(' RESULT:', 'PASS' if ok else 'FAIL')
