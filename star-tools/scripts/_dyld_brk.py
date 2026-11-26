#!/usr/bin/env python3
"""Find brk #1 instructions in dyld whose file offset low-12 == 0x2a4."""
data = open("/root/dsc26/dyld/usr/lib/dyld", "rb").read()
pat = bytes.fromhex("200020d4")  # brk #1 (LE)
i = 0
hits = []
while True:
    i = data.find(pat, i)
    if i < 0:
        break
    if (i & 0xFFF) == 0x2A4:
        hits.append(i)
    i += 1
print("brk #1 at low12==0x2a4:", [hex(h) for h in hits])
