#!/usr/bin/env python3
import zlib, struct
d = open('/mnt/c/ios26/s200-boot.img','rb').read()
out = zlib.decompressobj(31).decompress(d[2048:])
i = out.find(b'fb_diff')
print('fb_diff at', i)
print(repr(out[i-80:i+40]) if i>=0 else 'none')
j = out.find(b'touch_lat=1')
print('touch_lat at', j, repr(out[j-40:j+30]) if j>=0 else 'none')
# payload walk from XNUP
p = out.find(b'XNUP'); magic, size = struct.unpack('<II', out[p:p+8])
off = p + 8; end = p + 8 + size
while off < end:
    name, esz, res = struct.unpack('<16sII', out[off:off+24]); off += 24
    if name == b'': break
    nm = name.split(b'\0')[0].decode()
    print('entry', nm, esz, 'at', off)
    if nm in ('cmdline','memsize','identity'):
        print('   ', out[off:off+esz].decode('utf-8','replace')[-200:])
    off += esz + (-esz % 16)
