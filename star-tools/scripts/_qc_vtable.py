#!/usr/bin/env python3
"""Find the CA::WindowServer::AppleCLCDDisplay vtable inside the iOS 26 QuartzCore image."""
import struct
import re

SUB = "/root/dsc26/System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64e.01"
BASE = 0x0180094000
IMG = 0x0183ed3000            # QuartzCore __TEXT vmaddr
IMG_OFF = 0x03e3f000          # offset of __TEXT inside .01
TEXT_SIZE = 0x003f0ec0

DATA = [
    ("__DATA_CONST", 0x01e61f0b00, 0x00019b90, 0x004e4b00),
    ("__AUTH_CONST", 0x01ee97ad40, 0x000423d0, 0x06c6ed40),
    ("__DATA", 0x01e9cc81e0, 0x00005b9c, 0x01fbc1e0),
    ("__DATA_DIRTY", 0x01ecd923a0, 0x000084d8, 0x050863a0),
]

data = open(SUB, "rb").read(0x6b68000)
print("subcache read", len(data))

# 1) locate the RTTI name string
pat = re.compile(rb"AppleCLCDDisplay")
seen = []
for m in pat.finditer(data, IMG_OFF, IMG_OFF + TEXT_SIZE):
    off = m.start()
    # show the whole mangled token around it
    s = data[off - 40:off + 60]
    toks = re.findall(rb"[ -~]{4,}", s)
    seen.append((off, toks))
    if len(seen) <= 12:
        print("string @file %#x  img %#x  ctx %s" % (off, IMG + (off - IMG_OFF), b" | ".join(toks)))

print("total occurrences:", len(seen))

# candidate string whose full NUL-terminated token starts with _Z (mangled typeinfo name)
cands = []
for off, toks in seen:
    # walk back to nearest 0x00 to get full string
    st = data.rfind(b"\x00", off - 80, off) + 1
    en = data.find(b"\x00", off)
    full = data[st:en]
    if full.startswith(b"_Z") or full.startswith(b"_ZN"):
        cands.append((st, en, full))
print("mangled candidates:")
for c in cands[:10]:
    print("   @%#x  %s" % (c[0], c[2]))

# 2) find pointers to any candidate string address inside the data segments
def addr_of(file_off):
    return BASE + file_off

ptrs = []
for st, en, full in cands:
    a = addr_of(st)
    for name, va, vsz, fo in DATA:
        blob = data[fo:fo + vsz]
        i = 0
        while True:
            i = blob.find(struct.pack("<Q", a), i)
            if i < 0:
                break
            ptrs.append((name, va + i, i, full))
            i += 8
print("pointers to mangled names:", len(ptrs))
for p in ptrs[:10]:
    print("   %s  %#x  -> %s" % (p[0], p[1], p[3]))
