#!/usr/bin/env python3
import struct
import sys
sys.path.insert(0, "/mnt/d/桌面/star26-deps/scripts")
from dscsym2 import R

vm = 0x1BE041F18
blk = 0x40000
lo = max(0x180000000, vm - 0x2000000)
end = (vm | 0x3FFFF) + 1
start = vm & ~0x3FFFF
steps = 0
while start >= lo and steps < 40:
    blob = R.read(start, end - start)
    print(f"block 0x{start:x}-0x{end:x}: {len(blob) if blob else None} bytes, "
        f"magics={blob.count(b'\xcf\xfa\xed\xfe') if blob else '-'}")
    if blob:
        pos = len(blob) - 4
        while pos >= 0:
            pos = blob.rfind(b"\xcf\xfa\xed\xfe", 0, pos + 4)
            if pos < 0:
                break
            hvm = start + pos
            m = blob[pos:pos + 0x1000]
            if len(m) < 0x1000:
                extra = R.read(hvm + len(m), 0x1000 - len(m)) or b""
                m = (m + extra)[:0x1000]
            ncmds = struct.unpack_from("<I", m, 16)[0]
            o = 32
            tva = tsz = None
            name = None
            ok = True
            for _ in range(min(ncmds, 256)):
                if o + 8 > len(m):
                    ok = False
                    break
                cmd, size = struct.unpack_from("<II", m, o)
                if size < 8 or o + size > len(m):
                    ok = False
                    break
                if cmd == 0x19 and m[o + 8:o + 24].split(
                        b"\0")[0] == b"__TEXT":
                    tva = struct.unpack_from("<Q", m, o + 24)[0]
                    tsz = struct.unpack_from("<Q", m, o + 32)[0]
                elif cmd == 0xD:
                    noff = struct.unpack_from("<I", m, o + 8)[0]
                    e = m.find(b"\0", o + noff, min(o + size, len(m)))
                    name = m[o + noff:e].decode("utf-8", "replace")
                o += size
            contains = bool(tva and tva <= vm < tva + tsz)
            print(f"  cand 0x{hvm:x} name={name!r} tva=0x{tva if tva else 0:x} "
                f"tsz=0x{tsz if tsz else 0:x} ok={ok} contains={contains}")
            if contains:
                sys.exit(0)
            pos -= 1
    end = start
    start -= blk
    steps += 1
