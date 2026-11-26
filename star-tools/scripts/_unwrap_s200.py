#!/usr/bin/env python3
import gzip, struct, os, io
img = '/mnt/c/ios26/s200-boot.img'
d = open(img, 'rb').read()
vals = struct.unpack('<10I', d[8:48])
ksz = vals[0]
blob = d[2048:2048+ksz]
payload = gzip.decompress(blob)
print('payload bytes', len(payload), payload[:8])
magic, size = struct.unpack('<II', payload[:8])
assert magic == 0x50554E58
outdir = '/root/star26/s111/parts200'
os.makedirs(outdir, exist_ok=True)
off = 8; end = 8 + size
while off < end:
    name, esz, res = struct.unpack('<16sII', payload[off:off+24]); off += 24
    if name == b'':
        break
    nm = name.split(b'\0')[0].decode()
    data = payload[off:off+esz]; off += esz + (-esz % 16)
    if nm in ('cmdline','memsize','identity'):
        print(nm, '=', data.decode('utf-8','replace'))
        open(os.path.join(outdir, nm + '.txt'), 'w').write(data.decode('utf-8','replace'))
    else:
        open(os.path.join(outdir, nm), 'wb').write(data)
        print(nm, len(data))
