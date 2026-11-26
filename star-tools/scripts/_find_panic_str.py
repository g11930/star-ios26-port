#!/usr/bin/env python3
import zlib
d = open('/mnt/c/ios26/s200-boot.img','rb').read()
out = zlib.decompressobj(31).decompress(d[2048:])
for s in (b'boot task is not a platform binary', b'mount-phase', b'platform binary (mount'):
    i = out.find(s)
    print(s[:30], '->', i)
