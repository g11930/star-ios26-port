#!/usr/bin/env python3
import struct
import sys
sys.path.insert(0, "/mnt/d/桌面/star26-deps/scripts")
from dscsym2 import R, mappings

# where is the stub in file terms?
for addr, size, foff, p in mappings:
    if addr <= 0x232FA1CCC < addr + size:
        X = 0x232FA1CCC - addr + foff
        print(f"stub vm=0x{0x22C8A8000 + (0x232FA1CCC - addr):x}? "
            f"file {p.split('/')[-1]} off=0x{X:x} (mapping addr 0x{addr:x})")

# candidates below the pc
vm = 0x232FA1CD4
page = vm & ~0xFFF
for _ in range(400):
    m = R.read(page, 0x400)
    if m and m[:4] == b"\xcf\xfa\xed\xfe":
        ncmds = u32 = struct.unpack_from("<I", m, 16)[0]
        o = 32
        tva = tsz = name = None
        for _ in range(ncmds):
            cmd, size = struct.unpack_from("<II", m, o)
            if cmd == 0x19 and size >= 72:
                seg = m[o + 8:o + 24].split(b"\0")[0].decode()
                if seg == "__TEXT":
                    tva = struct.unpack_from("<Q", m, o + 16)[0]
                    tsz = struct.unpack_from("<Q", m, o + 24)[0]
            elif cmd == 0xD:
                noff = struct.unpack_from("<I", m, o + 8)[0]
                e = m.find(b"\0", o + noff, o + size)
                name = m[o + noff:e].decode("utf-8", "replace")
            o += size
        print(f"image @0x{page:x}: name={name!r} __TEXT vm=0x{tva:x} "
            f"size=0x{tsz:x} contains_pc={bool(tva and tva <= vm < tva + tsz)}")
    page -= 0x1000
    if page < 0x22C8A8000:
        break
