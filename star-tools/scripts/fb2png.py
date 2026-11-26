#!/usr/bin/env python3
"""framebuffer -> PNG, no PIL: `oem screenshot` gives 1440x3200 BGRA of 0xEA600000."""
import struct
import sys
import zlib


def write_png(path, width, height, rows):
    raw = b"".join(b"\x00" + r for r in rows)

    def chunk(tag, data):
        c = struct.pack(">I", len(data)) + tag + data
        return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", ihdr))
        f.write(chunk(b"IDAT", zlib.compress(raw, 6)))
        f.write(chunk(b"IEND", b""))


def main():
    src, dst = sys.argv[1], sys.argv[2]
    step = int(sys.argv[3]) if len(sys.argv) > 3 else 1
    w, h = 1440, 3200
    d = open(src, "rb").read()
    need = w * h * 4
    if len(d) < need:
        print("short: %d < %d" % (len(d), need))
        return 1
    rows = []
    for y in range(0, h, step):
        base = y * w * 4
        row = bytearray()
        for x in range(0, w, step):
            i = base + x * 4
            row += bytes((d[i + 2], d[i + 1], d[i]))   # BGRA -> RGB
        rows.append(bytes(row))
    write_png(dst, len(rows[0]) // 3, len(rows), rows)
    print("%s  %dx%d (step %d)  %d bytes" % (dst, len(rows[0]) // 3, len(rows), step,
                                             __import__("os").path.getsize(dst)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
