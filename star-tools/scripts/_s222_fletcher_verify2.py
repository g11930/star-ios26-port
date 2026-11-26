#!/usr/bin/env python3
import struct, sys, random, os

def f64(block):
    s1 = s2 = 0
    for w in struct.unpack_from(f'<{(len(block) - 8) // 4}I', block, 8):
        s1 = (s1 + w) % 0xffffffff
        s2 = (s2 + s1) % 0xffffffff
    return ((s2 << 32) | (0xffffffff - (s1 + s2) % 0xffffffff)) & 0xffffffffffffffff

for path in sys.argv[1:]:
    total = os.path.getsize(path) // 4096
    f = open(path, 'rb')
    random.seed(7)
    ok = bad = 0
    for i in random.sample(range(total), 400):
        f.seek(i * 4096)
        b = f.read(4096)
        if len(b) < 4096:
            continue
        stored = struct.unpack_from('<Q', b)[0]
        if stored == 0 or not any(b[8:64]):
            continue  # skip zero/unallocated
        if stored == f64(b):
            ok += 1
        else:
            bad += 1
    print(f'{os.path.basename(path)}: non-zero blocks hyp match {ok}/{ok+bad}')
