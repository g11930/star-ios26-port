#!/usr/bin/env python3
import struct, sys, os, glob

def uuid_of(path):
    d = open(path, 'rb').read()
    magic = struct.unpack('<I', d[:4])[0]
    if magic != 0xfeedfacf:
        return None, 'not macho64 magic=%#x' % magic
    ncmds = struct.unpack('<I', d[16:20])[0]
    off = 32
    uid = None
    sig = False
    cputype, cpusub = struct.unpack('<ii', d[4:12])
    for _ in range(ncmds):
        cmd, cmdsize = struct.unpack('<II', d[off:off+8])
        if cmd == 0x1b:  # LC_UUID
            uid = d[off+8:off+24].hex()
            uid = '-'.join([uid[0:8], uid[8:12], uid[12:16], uid[16:20], uid[20:32]]).upper()
        elif cmd == 0x1d:
            sig = True
        off += cmdsize
    return uid, dict(sig=sig, cputype=cputype, cpusub=cpusub, ncmds=ncmds)

paths = sys.argv[1:]
for p in paths:
    u, info = uuid_of(p)
    print('%-45s uuid=%s  %s  size=%d' % (os.path.basename(p), u, info, os.path.getsize(p)))
