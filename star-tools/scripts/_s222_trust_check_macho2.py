#!/usr/bin/env python3
import struct, hashlib
from pathlib import Path

def im4p_payload(blob):
    def element(at):
        tag, length = blob[at], blob[at + 1]
        at += 2
        if length & 0x80:
            count = length & 0x7f
            length, at = int.from_bytes(blob[at:at + count], 'big'), at + count
        return tag, at, length
    tag, at, length = element(0)
    assert tag == 0x30, 'IM4P is not a DER sequence'
    items, end = [], at + length
    while at < end:
        tag, start, length = element(at)
        items.append((tag, blob[start:start + length]))
        at = start + length
    assert len(items) >= 4 and items[0][1] == b'IM4P', 'not an IM4P'
    return items[1][1].decode(), items[3][1]

def trust_cache_entries(raw):
    version, count = struct.unpack_from('<I', raw)[0], struct.unpack_from('<I', raw, 20)[0]
    assert version == 2 and len(raw) == 24 + 24 * count, 'not a version 2 trust cache'
    return {raw[24 + 24 * i:44 + 24 * i]: raw[44 + 24 * i:48 + 24 * i] for i in range(count)}

def macho_cdhash(path):
    data = Path(path).read_bytes()
    ncmds = struct.unpack_from('<I', data, 16)[0]
    off = 32; sig = None
    for _ in range(ncmds):
        cmd, cs = struct.unpack_from('<II', data, off)
        if cmd == 0x1d:
            sig = struct.unpack_from('<I', data, off+8)[0]
        off += cs
    m, length, count = struct.unpack_from('>III', data, sig)
    d = dl = None
    for i in range(count):
        t, o = struct.unpack_from('>II', data, sig+12+8*i)
        bm, bl = struct.unpack_from('>II', data, sig+o)
        if bm == 0xfade0c02:
            d, dl = sig+o, bl
    assert d is not None, 'no CodeDirectory'
    h = hashlib.sha256(bytes(data[d:d+dl])).digest()
    return h[:20]

ts = {}
for p in ("/mnt/d/桌面/star26-deps/work/trust_static.im4p",
          "/mnt/d/桌面/star26-deps/work/trust_systemcrytex.im4p"):
    t, raw = im4p_payload(Path(p).read_bytes())
    entries = trust_cache_entries(raw)
    ts[p] = (t, entries)
    print(Path(p).name, "type", t, "entries", len(entries))

for name, path in (("dyld", "/root/ul26/usr/dyld"),
                   ("launchd", "/root/ul26/usr/launchd")):
    hh = macho_cdhash(path)
    hit = [Path(p).name for p, (t, e) in ts.items() if hh in e]
    print(f"{name}: cdhash={hh.hex()} ->", ("HIT " + str(hit)) if hit else "MISS")
