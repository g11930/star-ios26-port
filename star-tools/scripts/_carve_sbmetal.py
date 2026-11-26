import sys
sys.path.insert(0, '/root/star-build/tools/apfs')
import apfs

data = open('/mnt/c/ios26/s150-boot.img', 'rb').read()
i = data.find(b'NXSB')
print('NXSB at', i, 'file', len(data))
start = i - 0x20
blob = data[start:start + 11542528]
open('/tmp/root19-s150.apfs', 'wb').write(blob)
print('carved', len(blob), 'bytes -> /tmp/root19-s150.apfs')

c = apfs.Container('/tmp/root19-s150.apfs')
v = c.volumes()[0]
ino = v.lookup('/lib/libannibale-sbmetal-experiment.dylib')
out = v.inode(ino).contents()
open('/tmp/sbmetal-old.dylib', 'wb').write(out)
print('dylib', len(out), 'bytes')
