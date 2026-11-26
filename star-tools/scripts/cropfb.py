#!/usr/bin/env python3
"""cropfb.py <raw> <out.png> <x> <y> <w> <h> [step] [order]

Crop a region out of a raw 1440x3200 4-byte-per-pixel frame dump, scale by step
(1 = native), and write a PNG.
"""
import struct
import sys
import zlib

W, H = 1440, 3200
raw = open(sys.argv[1], "rb").read()
out, x0, y0, cw, ch = sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5]), int(sys.argv[6])
step = int(sys.argv[7]) if len(sys.argv) > 7 else 1
order = sys.argv[8] if len(sys.argv) > 8 else "bgra"

x0 = max(0, min(W - 1, x0))
y0 = max(0, min(H - 1, y0))
cw = max(1, min(W - x0, cw))
ch = max(1, min(H - y0, ch))

rows = []
for y in range(y0, y0 + ch, step):
    base = y * W * 4
    row = bytearray([0])
    for x in range(x0, x0 + cw, step):
        p = base + x * 4
        b, g, r = raw[p], raw[p + 1], raw[p + 2]
        if order == "rgba":
            r, g, b = b, g, b
        row += bytes((r, g, b))
    rows.append(bytes(row))

data = b"".join(rows)
w2, h2 = cw // step, ch // step


def chunk(tag, payload):
    return (struct.pack(">I", len(payload)) + tag + payload +
            struct.pack(">I", zlib.crc32(tag + payload) & 0xFFFFFFFF))


png = b"\x89PNG\r\n\x1a\n"
png += chunk(b"IHDR", struct.pack(">IIBBBBB", w2, h2, 8, 2, 0, 0, 0))
png += chunk(b"IDAT", zlib.compress(data, 9))
png += chunk(b"IEND", b"")
open(out, "wb").write(png)
print("wrote", out, w2, "x", h2, len(png), "bytes")
