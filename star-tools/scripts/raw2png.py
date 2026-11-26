#!/usr/bin/env python3
"""Turn a staged panel frame (1440x3200 BGRA, 5760 bytes a row) into PNGs."""
import sys

from PIL import Image

W, H, STRIDE = 1440, 3200, 5760

src = sys.argv[1] if len(sys.argv) > 1 else "/c/ios26/frame-p33.raw"
raw = open(src, "rb").read()
print("bytes", len(raw), "expected", STRIDE * H)
H = min(H, len(raw) // STRIDE)
img = Image.frombytes("RGBA", (W, H), raw[:STRIDE * H], "raw", "BGRA", STRIDE).convert("RGB")

colors = {}
notblack = 0
sampled = 0
for y in range(0, H, 8):
    for x in range(0, W, 8):
        p = img.getpixel((x, y))
        sampled += 1
        if max(p) > 12:
            notblack += 1
        colors[p] = colors.get(p, 0) + 1
print("sampled %d, not black %d (%.2f%%)" % (sampled, notblack, 100.0 * notblack / sampled))
for c, n in sorted(colors.items(), key=lambda kv: -kv[1])[:8]:
    print("  ", c, n)

out = src.rsplit(".", 1)[0]
img.save(out + ".png")
img.resize((W // 3, H // 3)).save(out + "-small.png")
print("saved", out + ".png")
