#!/usr/bin/env python3
import struct, sys, os
src = '/mnt/c/ios26/s200-boot.img'
outdir = '/root/star26/s111/parts200'
os.makedirs(outdir, exist_ok=True)
d = open(src, 'rb').read()
magic, size = struct.unpack('<II', d[:8])
assert magic == 0x50554E58, hex(magic)
off = 8
end = 8 + size
while off < end:
    name, esz, res = struct.unpack('<16sII', d[off:off+24])
    off += 24
    if name == b'':
        break
    nm = name.split(b'\0')[0].decode()
    data = d[off:off+esz]
    payload = d[off:off+esz]
    off += esz + (-esz % 16)
    if nm in ('cmdline', 'memsize', 'identity'):
        print(nm, repr(payload[:400].decode('utf-8', 'replace')))
        open(os.path.join(outdir, nm), 'w').write(payload.decode('utf-8', 'replace'))
    else:
        open(os.path.join(outdir, nm), 'wb').write(payload)
        print(nm, len(payload))
print('total', len(d))
