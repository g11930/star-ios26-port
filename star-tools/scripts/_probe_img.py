#!/usr/bin/env python3
import struct
for f in ('/mnt/c/ios26/s200-boot.img', '/mnt/c/ios26/s211-boot.img'):
    d = open(f, 'rb').read()
    print(f, len(d), d[:16].hex(' '), repr(d[:16]))
    idx = d.find(b'XNUP')
    print('  XNUP at', idx)
    if idx > 0:
        magic, size = struct.unpack('<II', d[idx:idx+8])
        print('  payload size', size, 'ends', idx + 8 + size)
