#!/usr/bin/env python3
import struct, zlib
d = open('/mnt/c/ios26/s200-boot.img','rb').read()
print(d[0:64].hex(' '))
print(d[2048:2064].hex(' '))
end = len(d)
# try decompressing from 2048 to end
for off in (2048, 2048+0):
    try:
        obj = zlib.decompressobj(31)
        out = obj.decompress(d[off:])
        print('off', off, 'out', len(out), 'first', out[:8])
        break
    except Exception as e:
        print('fail', off, e)
