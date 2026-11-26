#!/usr/bin/env python3
import struct

f = open('/root/star26/ipsw/systemos.dmg', 'rb')
f.seek((100160 + 1) * 4096)  # desc NXSB at desc 1
block = f.read(4096)
stored = struct.unpack_from('<Q', block)[0]
print('stored:', hex(stored))

words = struct.unpack_from(f'<{(len(block) - 8) // 4}I', block, 8)

# V1: per-step mod, checkA=-(s1+s2), checkB=-(s2+checkA)  (mine, wrong high)
s1 = s2 = 0
for w in words:
    s1 = (s1 + w) % 0xffffffff
    s2 = (s2 + s1) % 0xffffffff
cA = 0xffffffff - (s1 + s2) % 0xffffffff
cB = 0xffffffff - (s2 + cA) % 0xffffffff
print('V1:', hex(cB << 32 | cA), 'match', (cB << 32 | cA) == stored)

# V2: no intermediate mod, stored = ~(s1 + s2<<32) (bitwise)
s1 = s2 = 0
for w in words:
    s1 = (s1 + w) & 0xffffffffffffffff
    s2 = (s2 + s1) & 0xffffffffffffffff
s1 %= 0xffffffff
s2 %= 0xffffffff
v2 = (0xffffffffffffffff - (s1 + (s2 << 32))) & 0xffffffffffffffff
print('V2:', hex(v2), 'match', v2 == stored)

# V3: init 0xffffffff, no intermediate mod, final mod, then ~(s1 + s2<<32)
s1 = s2 = 0xffffffff
for w in words:
    s1 = (s1 + w) & 0xffffffffffffffff
    s2 = (s2 + s1) & 0xffffffffffffffff
s1 %= 0xffffffff
s2 %= 0xffffffff
v3 = (0xffffffffffffffff - (s1 + (s2 << 32))) & 0xffffffffffffffff
print('V3:', hex(v3), 'match', v3 == stored)

# V4: per-step mod, stored = (~s1) | (~s2)<<32
s1 = s2 = 0
for w in words:
    s1 = (s1 + w) % 0xffffffff
    s2 = (s2 + s1) % 0xffffffff
v4 = ((0xffffffff - s1) & 0xffffffff) | ((0xffffffff - s2) << 32)
print('V4:', hex(v4), 'match', v4 == stored)
