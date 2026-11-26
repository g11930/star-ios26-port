#!/usr/bin/env python3
"""v2: decode ctype-14 decmpfs ResourceFork. Handles BOTH ZBM-compressed pieces
(magic ZBM\\x09 -> zbm_tool) and raw pieces (leading 0xff -> next 65536 bytes are
the literal block). The previous v1 zero-filled the raw pieces, destroying the
code signature at the tail of .35/.72/.83.
"""
import struct, os, subprocess, time, sys

BASE = '/root/dsc26_fix/7zout'
OUT = '/root/dsc26_fix'
TOOL = '/root/zbm_tool/zbm_tool'
CHUNK = 65536
names = [
    'dyld_shared_cache_arm64e.35.dyldlinkedit',
    'dyld_shared_cache_arm64e.72.dyldlinkedit',
    'dyld_shared_cache_arm64e.83.dyldlinkedit',
]
only = sys.argv[1] if len(sys.argv) > 1 else None

for name in names:
    if only and only not in name:
        continue
    print('===', name, '===', flush=True)
    hdr = open(os.path.join(BASE, name + ':com.apple.decmpfs'), 'rb').read()
    magic, ctype, usize = struct.unpack_from('<IIQ', hdr, 0)
    rsrc = open(os.path.join(BASE, name + ':com.apple.ResourceFork'), 'rb').read()
    nblocks = (usize + CHUNK - 1) // CHUNK
    offsets = []
    pos = 0
    while pos + 4 <= len(rsrc):
        v = struct.unpack_from('<I', rsrc, pos)[0]
        if v > len(rsrc) or v < pos:
            break
        offsets.append(v)
        pos += 4
    print('  ctype=%d usize=%d blocks=%d offsets=%d' % (ctype, usize, nblocks, len(offsets)), flush=True)
    if len(offsets) != nblocks + 1:
        print('  MISMATCH, skip', flush=True)
        continue
    t0 = time.time()
    out = bytearray()
    bad = raw = zbm = 0
    tmpin = '/root/zbm_tool/_piece.zbm'
    tmpout = '/root/zbm_tool/_piece.out'
    for i in range(nblocks):
        start, end = offsets[i], offsets[i + 1]
        piece = rsrc[start:end]
        want = min(CHUNK, usize - len(out))
        if piece[:1] == b'\xff':
            # raw (uncompressed) block: 0xff marker + literal bytes
            raw += 1
            block = piece[1:1 + want]
            out += block + b'\x00' * (want - len(block))
            continue
        # ZBM compressed block
        with open(tmpin, 'wb') as f:
            f.write(piece)
        r = subprocess.run([TOOL, tmpin, tmpout], capture_output=True)
        if r.returncode != 0:
            bad += 1
            if bad <= 5:
                print('    piece %d FAIL: %s' % (i, r.stderr.decode()[:120]), flush=True)
            out += b'\x00' * want
            continue
        with open(tmpout, 'rb') as f:
            d = f.read()
        zbm += 1
        out += d[:want] + b'\x00' * (want - len(d))
        if (i + 1) % 500 == 0:
            print('    %d/%d (%.0fs)' % (i + 1, nblocks, time.time() - t0), flush=True)
    print('  done: len=%d want=%d zbm=%d raw=%d bad=%d in %.1fs' % (
        len(out), usize, zbm, raw, bad, time.time() - t0), flush=True)
    with open(os.path.join(OUT, name), 'wb') as f:
        f.write(out)
    print('  wrote', os.path.join(OUT, name), flush=True)
