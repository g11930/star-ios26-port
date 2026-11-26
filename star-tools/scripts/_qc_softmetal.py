#!/usr/bin/env python3
"""Does iOS 26 QuartzCore still carry a software rasteriser, or is it Metal-only?"""
import re

SUB = "/root/dsc26/System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64e.01"
IMG_OFF = 0x03e3f000
TEXT_SIZE = 0x003f0ec0

data = open(SUB, "rb").read(IMG_OFF + TEXT_SIZE)
text = data[IMG_OFF:IMG_OFF + TEXT_SIZE]

for kw in [b"Software", b"software", b"Metal", b"MTL", b"GLES", b"gles", b"OpenGL", b"SoftRaster", b"rasteris", b"Rasterize"]:
    print("%-10s %d" % (kw.decode(), text.count(kw)))

print("\n=== lines mentioning Software ===")
for m in re.finditer(rb"[ -~]{8,140}", text):
    s = m.group()
    if b"oftware" in s:
        print("   ", s.decode("latin1"))

print("\n=== lines mentioning Metal (first 25) ===")
n = 0
for m in re.finditer(rb"[ -~]{8,140}", text):
    s = m.group()
    if b"Metal" in s or b"MTL" in s:
        print("   ", s.decode("latin1"))
        n += 1
        if n >= 25:
            break
