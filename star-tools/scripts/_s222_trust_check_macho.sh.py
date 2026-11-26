#!/usr/bin/env python3
import struct, hashlib
from pathlib import Path

def der_elem(blob, at):
    tag = blob[at]; at += 1
    b = blob[at]; at += 1
    if b < 0x80:
        length = b
    else:
        n = b & 0x7f
        length = int.from_bytes(blob[at:at+n], "big"); at += n
    return tag, blob[at:at+length], at + length

def im4p_payload(blob):
    tag, _, body = der_elem(blob, 0)
    t1, tv, at = der_elem(blob, body)
    t2, payload, _ = der_elem(blob, at)
    return bytes(tv), payload

def macho_cdhash(path):
    data = Path(path).read_bytes()
    ncmds = struct.unpack_from("<I", data, 16)[0]
    off = 32; sig = None
    for _ in range(ncmds):
        cmd, cs = struct.unpack_from("<II", data, off)
        if cmd == 0x1d:
            sig = struct.unpack_from("<I", data, off+8)[0]
        off += cs
    m, length, count = struct.unpack_from(">III", data, sig)
    d = dl = None
    for i in range(count):
        t, o = struct.unpack_from(">II", data, sig+12+8*i)
        bm, bl = struct.unpack_from(">II", data, sig+o)
        if bm == 0xfade0c02:
            d, dl = sig+o, bl
    h = hashlib.sha256(bytes(data[d:d+dl])).digest()
    return h[:20]

ts = {}
for p in ("/mnt/d/桌面/star26-deps/work/trust_static.im4p",
          "/mnt/d/桌面/star26-deps/work/trust_systemcrytex.im4p"):
    t, raw = im4p_payload(Path(p).read_bytes())
    n = struct.unpack_from("<I", raw, 20)[0]
    ts[p] = (t, {bytes(raw[24+24*k:44+24*k]) for k in range(n)})
    print(Path(p).name, "type", t.decode(), "entries", n)

for name, path in (("dyld", "/root/ul26/usr/dyld"),
                   ("launchd", "/root/ul26/usr/launchd")):
    hh = macho_cdhash(path)
    hit = [Path(p).name for p, (t, e) in ts.items() if hh in e]
    print(f"{name}: cdhash={hh.hex()} ->", ("HIT " + str(hit)) if hit else "MISS")
