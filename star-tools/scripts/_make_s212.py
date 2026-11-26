#!/usr/bin/env python3
import zlib, gzip, io, struct, hashlib, shutil

SRC = '/mnt/c/ios26/s200-boot.img'
DST = '/mnt/c/ios26/s212-boot.img'
d = bytearray(open(SRC, 'rb').read())
hdr = struct.unpack('<10I', d[8:48])
ksz, kaddr, rsz, raddr, ssz, saddr, tags, page, hv, osv = hdr
assert page == 2048 and hv == 1

blob = bytes(d[page:page + ksz])
out = zlib.decompressobj(31).decompress(blob)
assert len(out) == 30027600

pos = out.rfind(b'fb_diff=1')
assert pos > 0
print('patch at', pos, repr(out[pos-40:pos+20]))
out = out[:pos] + b'fb_diff=0' + out[pos+len(b'fb_diff=1'):]
assert len(out) == 30027600

buf = io.BytesIO()
with gzip.GzipFile(fileobj=buf, mode='wb', compresslevel=9, mtime=0) as f:
    f.write(out)
newgz = buf.getvalue()
print('gz', len(blob), '->', len(newgz))

ramdisk = bytes(d[page + ((ksz + page - 1)//page)*page: page + ((ksz + page - 1)//page)*page + rsz])
second = b''
idhash = hashlib.sha1()
idhash.update(newgz); idhash.update(ramdisk); idhash.update(second)
for v in (len(newgz), kaddr, rsz, raddr, ssz, saddr, tags, page, hv, osv):
    idhash.update(struct.pack('<I', v))
digest = idhash.digest()

body = bytearray()
body += b'ANDROID!' + struct.pack('<10I', len(newgz), kaddr, rsz, raddr, ssz, saddr, tags, page, hv, osv) + digest
assert len(body) == 68, len(body)
body += b'\0' * (page - len(body))
body += newgz
body += b'\0' * (-len(newgz) % page)
body += ramdisk
body += b'\0' * (-len(ramdisk) % page)
open(DST, 'wb').write(body)
print('wrote', DST, len(body), 'ramdisk', rsz)
print('sha256', hashlib.sha256(open(DST,'rb').read()).hexdigest())
