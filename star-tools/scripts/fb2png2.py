#!/usr/bin/env python3
"""Turn a raw 1440x3200 BGRA/RGBA frame dump into a downsampled PNG.

usage: fb2png2.py <raw> <out.png> [step] [order]
order: bgra (default) | rgba
"""
import struct
import sys
import zlib

W, H = 1440, 3200
raw = open(sys.argv[1], "rb").read()
out = sys.argv[2]
step = int(sys.argv[3]) if len(sys.argv) > 3 else 4
order = sys.argv[4] if len(sys.argv) > 4 else "bgra"

n = W * H * 4
if len(raw) < n:
    sys.exit("short: %d < %d" % (len(raw), n))
buf = raw[:n]

w2, h2 = W // step, H // step
rows = []
for y in range(0, H, step):
    base = y * W * 4
    row = bytearray()
    row.append(0)
    for x in range(0, W, step):
        p = base + x * 4
        b, g, r = buf[p], buf[p + 1], buf[p + 2]
        if order == "rgba":
            r, g, b = b, g, b
        row += bytes((r, g, b))
    rows.append(bytes(row))

data = b"".join(rows)

sample = set()
tot = 0
cnt = 0
for y in range(0, H, 16):
    base = y * W * 4
    for x in range(0, W, 16):
        p = base + x * 4
        sample.add((buf[p], buf[p + 1], buf[p + 2]))
        tot += buf[p] + buf[p + 1] + buf[p + 2]
        cnt += 3
print("distinct colours (sampled):", len(sample))
print("mean channel value:", round(tot / cnt, 1))
print("top colours:", sorted(sample, key=lambda c: -sum(c))[:5])


def chunk(tag, payload):
    return (struct.pack(">I", len(payload)) + tag + payload +
            struct.pack(">I", zlib.crc32(tag + payload) & 0xFFFFFFFF))


png = b"\x89PNG\r\n\x1a\n"
png += chunk(b"IHDR", struct.pack(">IIBBBBB", w2, h2, 8, 2, 0, 0, 0))
png += chunk(b"IDAT", zlib.compress(data, 6))
png += chunk(b"IEND", b"")
open(out, "wb").write(png)
print("wrote", out, w2, "x", h2, len(png), "bytes")
