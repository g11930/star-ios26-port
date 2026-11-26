#!/usr/bin/env python3
import struct
F='/root/dsc26_fix/7zout/dyld_shared_cache_arm64e.35.dyldlinkedit:com.apple.ResourceFork'
d=open(F,'rb').read(128)
print('first 64 bytes hex:')
for i in range(0,64,16):
    print('  %04x: %s'%(i, d[i:i+16].hex()))
print('BE u32[0:8]:', [hex(x) for x in struct.unpack_from('>8I',d,0)])
print('LE u32[0:8]:', [hex(x) for x in struct.unpack_from('<8I',d,0)])
print('BE u64[0:4]:', [hex(x) for x in struct.unpack_from('>4Q',d,0)])
