#!/usr/bin/env python3
"""Search the whole main-file header region for image path strings."""
import re

MAIN = "/root/dsc26/System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64e"
with open(MAIN, "rb") as f:
    blob = f.read(0x98000)

hits = list(re.finditer(rb"/System/Library", blob))
print(f"path strings in main file [0..0x98000): {len(hits)}")
for m in hits[:8]:
    s = blob[m.start():m.start() + 80].split(b"\0")[0].decode()
    print(f"  @0x{m.start():x}: {s}")
