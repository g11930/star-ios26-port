#!/usr/bin/env python3
"""Find brk #1 instructions in logd whose file offset low-12 == 0x2a4."""
data = open("/root/dsc26/dyld/usr/libexec/logd", "rb").read()
pat = bytes.fromhex("200020d4")  # brk #1 (LE)
i = 0
hits = []
while True:
    i = data.find(pat, i)
    if i < 0:
        break
    hits.append(i)
    i += 1
print("all brk #1 offsets:", [hex(h) for h in hits])
print("with low12==0x2a4:", [hex(h) for h in hits if (h & 0xFFF) == 0x2A4])
