#!/usr/bin/env python3
import zlib, struct
d = open('/mnt/c/ios26/s200-boot.img','rb').read()
obj = zlib.decompressobj(31)
out = obj.decompress(d[2048:])
print('out', len(out), 'eof', obj.eof, 'first', out[:16].hex(' '))
print('XNUP at', out.find(b'XNUP'))
print('tail', out[-32:].hex(' '))
