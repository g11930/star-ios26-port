#!/usr/bin/env python3
import struct, sys, random

def words_of(block):
    return struct.unpack_from(f'<{(len(block) - 8) // 4}I', block, 8)

def sums(block):
    s1 = s2 = 0
    for w in words_of(block):
        s1 = (s1 + w) % 0xffffffff
        s2 = (s2 + s1) % 0xffffffff
    return s1, s2

def hyp(block):  # (sum2 << 32) | (0xffffffff - (sum1+sum2))
    s1, s2 = sums(block)
    return ((s2 << 32) | (0xffffffff - (s1 + s2) % 0xffffffff)) & 0xffffffffffffffff

for path in sys.argv[1:]:
    size = __import__('os').path.getsize(path)
    f = open(path, 'rb')
    total = size // 4096
    random.seed(42)
    samples = [0] + [100160 + 1, 100160 + 3] + random.sample(range(total), 60)
    ok = bad = 0
    for i in samples:
        f.seek(i * 4096)
        b = f.read(4096)
        if len(b) < 4096 or b[8:12] == b'\0' * 4 and b[:8] == b'\0' * 8:
            pass
        stored = struct.unpack_from('<Q', b)[0]
        if stored == hyp(b):
            ok += 1
        else:
            bad += 1
    print(f'{path.split("/")[-1]}: hyp match {ok}/{ok+bad}')
