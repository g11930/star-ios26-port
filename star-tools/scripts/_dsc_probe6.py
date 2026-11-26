#!/usr/bin/env python3
"""Probe subcache .01's tail mappings region for images/paths."""
import re
import struct

p = ("/root/dsc26/System/Library/Caches/com.apple.dyld/"
     "dyld_shared_cache_arm64e.01")
size = 0x6b30000
with open(p, "rb") as f:
    f.seek(size)
    blob = f.read(0x38000)

print("head 64 bytes:")
print(blob[:64].hex())

paths = list(re.finditer(rb"/System/Library", blob))
print(f"path strings: {len(paths)}")
for m in paths[:5]:
    s = blob[m.start():m.start() + 70].split(b"\0")[0].decode()
    print(f"  @0x{m.start():x}: {s}")
