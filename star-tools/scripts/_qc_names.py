#!/usr/bin/env python3
"""List the display / renderer class names that iOS 26 QuartzCore actually carries."""
import re
import struct

SUB = "/root/dsc26/System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64e.01"
IMG_OFF = 0x03e3f000
TEXT_SIZE = 0x003f0ec0

data = open(SUB, "rb").read(IMG_OFF + TEXT_SIZE)
text = data[IMG_OFF:IMG_OFF + TEXT_SIZE]

def names(pattern):
    out = []
    for m in re.finditer(pattern, text):
        st = text.rfind(b"\x00", max(0, m.start() - 120), m.start()) + 1
        en = text.find(b"\x00", m.end())
        s = text[st:en]
        if 3 < len(s) < 200:
            out.append(s.decode("latin1", "replace"))
    return sorted(set(out))

for label, pat in [
    ("Display*", rb"[A-Za-z_]*Display[A-Za-z_]*"),
    ("*Server*", rb"[A-Za-z_]*Server[A-Za-z_]*"),
    ("*Renderer*", rb"[A-Za-z_]*Renderer[A-Za-z_]*"),
]:
    got = names(pat)
    print("=== %s (%d) ===" % (label, len(got)))
    for g in got[:40]:
        print("   ", g)

print()
print("=== OpenGL ES leftovers ===")
for kw in (b"EAGL", b"GLES", b"glrenderer", b"OpenGL"):
    n = text.count(kw)
    print("  %-10s %d" % (kw.decode(), n))

print()
print("=== Metal mentions ===")
for kw in (b"MTLDevice", b"MetalPlugin", b"MTLTexture", b"Metal"):
    n = text.count(kw)
    print("  %-12s %d" % (kw.decode(), n))
