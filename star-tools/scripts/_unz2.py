#!/usr/bin/env python3
import zlib, struct
d = open('/mnt/c/ios26/s200-boot.img','rb').read()
obj = zlib.decompressobj(31)
out = b''
data = d[2048:]
while True:
    chunk = obj.decompress(data)
    out += chunk
    if obj.eof:
        data = obj.unused_data
        if not data:
            break
        obj = zlib.decompressobj(31)
        continue
    break
print('total out', len(out))
print('first 16', out[:16].hex(' '))
idx = out.find(b'XNUP')
print('XNUP at', idx)
if idx >= 0:
    magic, size = struct.unpack('<II', out[idx:idx+8])
    print('payload size', size, 'total bytes', 8+size)
    # walk entries
    off = idx + 8; end = idx + 8 + size
    while off < end:
        name, esz, res = struct.unpack('<16sII', out[off:off+24]); off += 24
        if name == b'': break
        nm = name.split(b'\0')[0].decode()
        print(' ', nm, esz)
        off += esz + (-esz % 16)
